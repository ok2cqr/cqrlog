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
  response parsing for the callbook lookup and the DX cluster spots.

  The HTTP calls stay in TdmUtils.GetHamQTHInfo and TWebThread (fDXCluster),
  this unit only turns JSON into the strings CQRLOG has always used, so the
  callers did not change when the v1 xml.php and dxc_csv.php were replaced.
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

//body of POST login
function HamQTHLoginRequest(const Callsign, Password : String) : String;
//token from the login response, False if there is none
function ParseHamQTHLogin(const Json : String; out Token : String) : Boolean;
//message for a failed request: detail of the problem response, or (code):reason
function HamQTHErrorText(ResultCode : Integer; const Reason, Json : String) : String;
function ParseHamQTHCallbook(const Json : String; out Info : THamQTHCallbook) : Boolean;
function ParseHamQTHSpots(const Json : String; out Spots : THamQTHSpots) : Boolean;

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
  o : TJSONObject;
begin
  o := ParseObject(Json);
  try
    Result := StrAt(o, 'detail');
    if Result = '' then
      Result := StrAt(o, 'title')
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

end.
