(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ HamQTH API v2 (https://www.hamqth.com/developers): request bodies and
  response parsing for the callbook lookup, the DX cluster spots, the
  real-time log upload and the rig status report.

  The HTTP calls stay in TdmUtils (GetHamQTHInfo, HamQTHRequest),
  TWebThread (fDXCluster), TdmLogUpload and uHamQTHRigReport, this unit only turns JSON into
  the strings CQRLOG has always used, so the callers did not change when the
  v1 xml.php, dxc_csv.php and qso_realtime.php were replaced.
  The token and logging in again after a 401 are kept by TdmUtils
  (fHamQTHSession, GetHamQTHSession).
  No LCL, no globals; see tests/tHamQTHApi.pas. }

unit uHamQTHApi;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpjson, jsonparser;

const
  C_HAMQTH_API = 'https://www.hamqth.com/api/v2/';

  //rig status: "send every ~30 s and on every frequency or mode change,
  //at most once per 5 s"
  C_RIG_MIN_INTERVAL = 5000;   //ms
  C_RIG_REPEAT       = 30000;
  C_RIG_SHORT_PAUSE  = 60000;  //server not reached or not working
  C_RIG_LONG_PAUSE   = 600000; //wrong password, invalid data, switched off in the profile

type
  THamQTHCallbook = record
    nick, qth, address, zip, grid, state, county, qsl, iota, waz, itu, dok : String;
  end;

  THamQTHSpot = record
    spotter : String;
    freq    : String; //kHz, one decimal, e.g. 14025.3
    dxcall  : String;
    comment : String;
    time    : String; //HHMM UTC
  end;
  THamQTHSpots = array of THamQTHSpot;

  //when to send the next rig status report, times in ms (GetTickCount64)
  THamQTHRigSchedule = class
  private
    fFreq       : Int64; //0.1 kHz, the resolution the server keeps
    fMode       : String;
    fLastSent   : QWord;
    fSentOnce   : Boolean;
    fPauseUntil : QWord;
    fPauseUntilChange : Boolean;
  public
    //frequency or mode changed, or the last report is 30 s old;
    //never sooner than 5 s after the last one nor during a pause
    function  Due(FreqKHz : Double; const Mode : String; Now : QWord) : Boolean;
    procedure Sent(FreqKHz : Double; const Mode : String; Now : QWord);
    //UntilChange: the pause ends sooner when the frequency or mode changes
    procedure Pause(Now, Ms : QWord; UntilChange : Boolean = False);
    procedure Resume;
  end;

//body of POST login
function HamQTHLoginRequest(const Callsign, Password : String) : String;
//token from the login response, False if there is none
function ParseHamQTHLogin(const Json : String; out Token : String) : Boolean;
//message for a failed request: detail of the problem response, or (code):reason
function HamQTHErrorText(ResultCode : Integer; const Reason, Json : String) : String;
function ParseHamQTHCallbook(const Json : String; out Info : THamQTHCallbook) : Boolean;
function ParseHamQTHSpots(const Json : String; out Spots : THamQTHSpots) : Boolean;
//ADIF record (<CALL:6>OK2CQR...<EOR>) to the body of POST log/qso,
//{"qso":{"call":"OK2CQR",...}} with lower-case ADIF names
function HamQTHQsoRequest(const Adif : String) : String;
//query string of DELETE log/qso
function HamQTHQsoKeyQuery(const Call, QsoDate, TimeOn, Band, Mode : String) : String;
//result of a log/qso request as TdmLogUpload.GetResultMessage reports it:
//ErrorCode 0 = done, 1 = stop the upload, 2 = QSO rejected, go on with the next one
function HamQTHQsoResult(ResultCode : Integer; const Json : String; out ErrorCode : Integer) : String;
//body of POST rig; Mode and Callsign are left out when empty
function HamQTHRigRequest(FreqKHz : Double; const Mode, Callsign : String) : String;
//'' when the report was stored, otherwise why not; PauseMs = how long to wait
//before the next report, UntilChange = unless the frequency or mode changes
function HamQTHRigResult(ResultCode : Integer; const Json : String; out PauseMs : Cardinal;
  out UntilChange : Boolean) : String;

implementation

//nil if Json is not a JSON object
function ParseObject(const Json : String) : TJSONObject;
var
  d : TJSONData;
begin
  Result := nil;
  try
    d := GetJSON(Json)
  except
    exit //not JSON, e.g. an HTML error page from a proxy
  end;
  if d is TJSONObject then
    Result := TJSONObject(d)
  else
    d.Free
end;

//'' for a missing value, null, object or array
function StrAt(Data : TJSONData; const Path : String) : String;
var
  d : TJSONData;
begin
  Result := '';
  if Data = nil then exit;
  d := Data.FindPath(Path);
  if d = nil then exit;
  case d.JSONType of
    jtString, jtBoolean : Result := d.AsString;
    jtNumber            : if d is TJSONFloatNumber then
                            Result := FloatToStr(d.AsFloat, DefaultFormatSettings)
                          else
                            Result := IntToStr(d.AsInt64)
  end
end;

function HamQTHLoginRequest(const Callsign, Password : String) : String;
var
  o : TJSONObject;
begin
  o := TJSONObject.Create(['callsign', Callsign, 'password', Password]);
  try
    Result := o.AsJSON
  finally
    o.Free
  end
end;

function ParseHamQTHLogin(const Json : String; out Token : String) : Boolean;
var
  o : TJSONObject;
begin
  Token := '';
  o := ParseObject(Json);
  try
    Token := StrAt(o, 'token')
  finally
    o.Free
  end;
  Result := Token <> ''
end;

function HamQTHErrorText(ResultCode : Integer; const Reason, Json : String) : String;
var
  o          : TJSONObject;
  violations : TJSONData;
  i          : Integer;
  s          : String;
begin
  o := ParseObject(Json);
  try
    Result := StrAt(o, 'detail');
    if Result = '' then
      Result := StrAt(o, 'title');
    //422: which parameters were wrong
    violations := nil;
    if o <> nil then
      violations := o.FindPath('violations');
    if (violations is TJSONArray) and (violations.Count > 0) then
    begin
      s := '';
      for i := 0 to violations.Count - 1 do
      begin
        if s <> '' then
          s := s + '; ';
        s := s + StrAt(violations.Items[i], 'propertyPath') + ': ' +
          StrAt(violations.Items[i], 'title')
      end;
      Result := Trim(Result + ' (' + s + ')')
    end
  finally
    o.Free
  end;
  if Result = '' then
    Result := '(' + IntToStr(ResultCode) + '):' + Reason
end;

//DOK can be 'H24', 'h 24' or 'H-24', only letters and figures are left,
//upper case, at most 12 characters (the size of the dok field)
function CleanDok(const Dok : String) : String;
var
  c : Char;
begin
  Result := '';
  for c in UpperCase(Dok) do
    if c in ['A'..'Z', '0'..'9'] then
      Result := Result + c;
  Result := Copy(Result, 1, 12)
end;

function ParseHamQTHCallbook(const Json : String; out Info : THamQTHCallbook) : Boolean;
var
  o      : TJSONObject;
  street : TJSONData;
  i      : Integer;
  s      : String;
begin
  Info := Default(THamQTHCallbook);
  o := ParseObject(Json);
  Result := o <> nil;
  if not Result then exit;
  try
    //first name only, capitalized
    Info.nick := Trim(StrAt(o, 'nick'));
    if Pos(' ', Info.nick) > 0 then
      Info.nick := Copy(Info.nick, 1, Pos(' ', Info.nick) - 1);
    if Info.nick <> '' then
    begin
      Info.nick := LowerCase(Info.nick);
      Info.nick[1] := UpCase(Info.nick[1])
    end;

    Info.qth    := StrAt(o, 'qth');
    Info.state  := StrAt(o, 'region.usState');
    Info.county := StrAt(o, 'region.usCounty');
    Info.zip    := StrAt(o, 'address.zip');

    //name and the first street line always, further street lines when not empty
    street := o.FindPath('address.street');
    s := '';
    if (street is TJSONArray) and (street.Count > 0) then
      s := StrAt(street.Items[0], '');
    Info.address := StrAt(o, 'address.name') + LineEnding + s + LineEnding;
    if street is TJSONArray then
      for i := 1 to street.Count - 1 do
      begin
        s := StrAt(street.Items[i], '');
        if s <> '' then
          Info.address := Info.address + s + LineEnding
      end;
    Info.address := Info.address + StrAt(o, 'address.city');
    if Info.state <> '' then
      Info.address := Info.address + ', ' + Info.state;
    Info.address := Info.address + ' ' + Info.zip;

    Info.grid := UpperCase(StrAt(o, 'location.grid'));
    Info.qsl  := StrAt(o, 'qsl.via');
    Info.iota := StrAt(o, 'iota');
    Info.waz  := StrAt(o, 'cq');
    Info.itu  := StrAt(o, 'itu');
    Info.dok  := CleanDok(StrAt(o, 'region.dok'))
  finally
    o.Free
  end
end;

function ParseHamQTHSpots(const Json : String; out Spots : THamQTHSpots) : Boolean;
var
  o    : TJSONObject;
  list : TJSONData;
  spot : TJSONData;
  fs   : TFormatSettings;
  i, n : Integer;
  t    : String;
begin
  SetLength(Spots, 0);
  o := ParseObject(Json);
  try
    list := nil;
    if o <> nil then
      list := o.FindPath('spots');
    Result := list is TJSONArray;
    if not Result then exit;

    fs := DefaultFormatSettings;
    fs.DecimalSeparator := '.';
    SetLength(Spots, list.Count);
    n := 0;
    for i := 0 to list.Count - 1 do
    begin
      spot := list.Items[i];
      if not (spot is TJSONObject) then
        Continue;
      Spots[n].spotter := StrAt(spot, 'spotter');
      Spots[n].dxcall  := StrAt(spot, 'dxcall');
      Spots[n].comment := StrAt(spot, 'comment');
      if spot.FindPath('freq') is TJSONNumber then
        Spots[n].freq := FormatFloat('0.0', spot.FindPath('freq').AsFloat, fs)
      else
        Spots[n].freq := '';
      t := StrAt(spot, 'time'); //2026-10-03T07:58:00Z
      Spots[n].time := Copy(t, 12, 2) + Copy(t, 15, 2);
      Inc(n)
    end;
    SetLength(Spots, n)
  finally
    o.Free
  end
end;

function HamQTHQsoRequest(const Adif : String) : String;
var
  req, qso : TJSONObject;
  p, e, len : Integer;
  tag, name : String;
begin
  qso := TJSONObject.Create;
  req := TJSONObject.Create(['qso', qso]);
  try
    p := Pos('<', Adif);
    while p > 0 do
    begin
      e := Pos('>', Adif, p);
      if e = 0 then
        Break;
      tag := Copy(Adif, p + 1, e - p - 1); //CALL:6 or QSO_DATE:8:D
      if UpperCase(tag) = 'EOR' then
        Break;
      len := -1;
      if Pos(':', tag) > 0 then
      begin
        name := LowerCase(Copy(tag, 1, Pos(':', tag) - 1));
        Delete(tag, 1, Pos(':', tag));
        if Pos(':', tag) > 0 then
          tag := Copy(tag, 1, Pos(':', tag) - 1);
        len := StrToIntDef(tag, -1)
      end;
      if (len > 0) and (name <> '') then
      begin
        //the length is in bytes, the way GetAdifValue counts it
        qso.Strings[name] := Copy(Adif, e + 1, len);
        p := Pos('<', Adif, e + 1 + len)
      end
      else
        p := Pos('<', Adif, e + 1)
    end;
    Result := req.AsJSON
  finally
    req.Free
  end
end;

function UrlEncode(const s : String) : String;
var
  c : Char;
begin
  Result := '';
  for c in s do
    if c in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~'] then
      Result := Result + c
    else
      Result := Result + '%' + IntToHex(Ord(c), 2)
end;

function HamQTHQsoKeyQuery(const Call, QsoDate, TimeOn, Band, Mode : String) : String;
begin
  Result := 'call=' + UrlEncode(Call) + '&qso_date=' + UrlEncode(QsoDate) +
    '&time_on=' + UrlEncode(TimeOn) + '&band=' + UrlEncode(Band) +
    '&mode=' + UrlEncode(Mode)
end;

function HamQTHQsoResult(ResultCode : Integer; const Json : String; out ErrorCode : Integer) : String;
begin
  ErrorCode := 0;
  case ResultCode of
    200, 201, 204 : Result := 'OK';
    409           : Result := 'Already exists';
    //deleting a QSO which is not there, nothing to do
    404           : Result := HamQTHErrorText(ResultCode, 'QSO not found in the log', Json);
    422           : begin
                      Result    := HamQTHErrorText(ResultCode, 'QSO rejected', Json);
                      ErrorCode := 2
                    end
    else begin
      //401/403 login, 429 too many requests, 503 DXCC service down, server errors
      Result    := HamQTHErrorText(ResultCode, 'Unexpected response from HamQTH', Json);
      ErrorCode := 1
    end
  end
end;

function HamQTHRigRequest(FreqKHz : Double; const Mode, Callsign : String) : String;
var
  o    : TJSONObject;
  fs   : TFormatSettings;
  freq : String;
begin
  //fpjson writes floats as 1.4025299999999999E+004, the frequency is put
  //in by hand with the one decimal the server keeps
  fs := DefaultFormatSettings;
  fs.DecimalSeparator := '.';
  freq := '"freq" : ' + FormatFloat('0.0', FreqKHz, fs);
  o := TJSONObject.Create;
  try
    if Mode <> '' then
      o.Add('mode', Mode);
    if Callsign <> '' then
      o.Add('callsign', Callsign);
    if o.Count = 0 then
      Result := '{ ' + freq + ' }'
    else
      Result := '{ ' + freq + ', ' + Copy(o.AsJSON, 3, MaxInt) //o.AsJSON = { "mode" : ... }
  finally
    o.Free
  end
end;

function HamQTHRigResult(ResultCode : Integer; const Json : String; out PauseMs : Cardinal;
  out UntilChange : Boolean) : String;
var
  o : TJSONObject;
begin
  Result      := '';
  PauseMs     := 0;
  UntilChange := False;
  case ResultCode of
    200 : begin
            o := ParseObject(Json);
            try
              if (o <> nil) and (o.Find('stored') is TJSONBoolean) and not o.Booleans['stored'] then
              begin
                Result  := 'rig status is switched off in the HamQTH profile of ' + StrAt(o, 'callsign');
                PauseMs := C_RIG_LONG_PAUSE
              end
            finally
              o.Free
            end
          end;
    429 : Result := HamQTHErrorText(ResultCode, 'Too many reports', Json); //the schedule waits 5 s anyway
    //login; uHamQTHRigReport ends the pause when the login settings change
    401, 403 :
          begin
            Result  := HamQTHErrorText(ResultCode, 'Access denied', Json);
            PauseMs := C_RIG_LONG_PAUSE
          end;
    //frequency out of the bands, unknown mode, ...
    422 : begin
            Result      := HamQTHErrorText(ResultCode, 'Report rejected', Json);
            PauseMs     := C_RIG_LONG_PAUSE;
            UntilChange := True
          end
    else begin
      Result  := HamQTHErrorText(ResultCode, 'Unexpected response from HamQTH', Json);
      PauseMs := C_RIG_SHORT_PAUSE
    end
  end
end;

function THamQTHRigSchedule.Due(FreqKHz : Double; const Mode : String; Now : QWord) : Boolean;
var
  Changed : Boolean;
begin
  Changed := (Round(FreqKHz * 10) <> fFreq) or (Mode <> fMode);
  if (Now < fPauseUntil) and not (fPauseUntilChange and Changed) then
    Result := False
  else if not fSentOnce then
    Result := True
  else if Now - fLastSent < C_RIG_MIN_INTERVAL then
    Result := False
  else
    Result := Changed or (Now - fLastSent >= C_RIG_REPEAT)
end;

procedure THamQTHRigSchedule.Sent(FreqKHz : Double; const Mode : String; Now : QWord);
begin
  fFreq     := Round(FreqKHz * 10);
  fMode     := Mode;
  fLastSent := Now;
  fSentOnce := True
end;

procedure THamQTHRigSchedule.Pause(Now, Ms : QWord; UntilChange : Boolean = False);
begin
  fPauseUntil       := Now + Ms;
  fPauseUntilChange := UntilChange
end;

procedure THamQTHRigSchedule.Resume;
begin
  fPauseUntil := 0
end;

end.
