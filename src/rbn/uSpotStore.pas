(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The shared store of spot candidates.

  Every spot from RBN, the DX cluster and the operator lands here, whether or
  not any band map window is open, and stays for DeleteAfterSec after it was
  last seen.  Nothing is filtered on the way in: a window asks with Select for
  its band and its own filter, and gets a sorted copy with each station once,
  at the frequency it was heard last.  So a changed filter, a
  newly opened window or a band switch shows what has already arrived, and a
  restart (SaveSnapshot/LoadSnapshot) brings back what is still valid with its
  original age.

  Candidates are kept per (origin, source, spotter, call, band, mode): the same
  station heard by two skimmers is two candidates, because the skimmers may be
  on different continents and the RBN source filter needs them apart.  A
  repeated spot refreshes LastSeen and counts a hit; LoadSnapshot never does.

  Bounded.  When full, the oldest RBN candidate goes first: an RBN flood must
  not push out a still valid cluster or manual spot, of which there are few.

  Thread safe, no LCL; see tests/tCandidateStore.pas. }

unit uSpotStore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  SPOT_SNAPSHOT_VERSION = 2;
  //how far apart two spots may be and still count as one station (kHz), and
  //how many characters their calls may differ in (edit distance)
  SIMILAR_CALL_KHZ      = 0.1;
  SIMILAR_CALL_DISTANCE = 2;

type
  TSpotOrigin  = (soRbn, soCluster, soManual);
  TSpotOrigins = set of TSpotOrigin;

  TSpotCandidate = record
    Origin    : TSpotOrigin;
    SourceId  : Integer;    //rbn_sources id for soRbn, 0 otherwise
    Spotter   : String;
    Call      : String;
    Band      : String;
    Mode      : String;
    FreqKHz   : Double;
    SplitInfo : String;
    Color     : LongInt;    //as the producer chose them (RBN colour, cluster colour)
    BgColor   : LongInt;
    IsLoTW    : Boolean;
    IsEQSL    : Boolean;
    LastSeen  : TDateTime;  //local time of the last live arrival
    Hits      : Integer;    //live arrivals so far, the same spotter repeating counts
  end;
  TSpotView = array of TSpotCandidate;

  //what a window applies on top of band and expiry
  TSpotFilter = record
    Mode       : String;    //'' = all
    OnlyLoTW   : Boolean;
    OnlyEQSL   : Boolean;
    Origins    : TSpotOrigins;
  end;

  //the window's QSO rule (global / own / none): True hides the spot. nil = none
  TWorkedRule = function(const Call, Band, Mode : String) : Boolean of object;

  TSpotStore = class
  private
    FCrit     : TRTLCriticalSection;
    FItems    : array of TSpotCandidate;
    FCount    : Integer;
    FCapacity : Integer;
    function  IndexOf(const C : TSpotCandidate) : Integer;
    procedure DeleteAt(i : Integer);
    procedure MakeRoom;
    function  Alive(const C : TSpotCandidate; ANow : TDateTime) : Boolean;
  public
    DeleteAfterSec : Integer;
    constructor Create(ACapacity : Integer);
    destructor Destroy; override;
    //a live arrival, or a restored one with its own LastSeen
    procedure Add(const Spot : TSpotCandidate);
    //DeleteAfterQSO: the station on this band and mode, whoever spotted it
    procedure Remove(const Call, Band, Mode : String);
    //the main RBN source was switched: its candidates are not the new source's
    procedure DropRbnSource(SourceId : Integer);
    procedure Expire(ANow : TDateTime);
    procedure Clear;
    //still valid candidates of Band ('' = all), sorted by frequency
    function  Select(const Band : String; ANow : TDateTime; const Filter : TSpotFilter;
                     Worked : TWorkedRule) : TSpotView;
    function  Count : Integer;
    procedure SaveSnapshot(Lines : TStrings);
    procedure LoadSnapshot(Lines : TStrings; ANow : TDateTime);
  end;

function DefaultSpotFilter : TSpotFilter;
function SpotFilterOrigin(O : TSpotOrigin) : TSpotFilter;

implementation

function DefaultSpotFilter : TSpotFilter;
begin
  Result := Default(TSpotFilter);
  Result.Origins := [soRbn, soCluster, soManual]
end;

function SpotFilterOrigin(O : TSpotOrigin) : TSpotFilter;
begin
  Result := DefaultSpotFilter;
  Result.Origins := [O]
end;

//edit distance of two calls, capped: a garbled skimmer decode is the real
//call with a character missing, added or wrong, one or two of them
function CallDistance(const A, B : String; Cap : Integer) : Integer;
var
  Prev, Cur : array of Integer;
  i, j, c   : Integer;
begin
  if Abs(Length(A) - Length(B)) > Cap then
    exit(Cap + 1);
  SetLength(Prev, Length(B) + 1);
  SetLength(Cur, Length(B) + 1);
  for j := 0 to Length(B) do
    Prev[j] := j;
  for i := 1 to Length(A) do
  begin
    Cur[0] := i;
    for j := 1 to Length(B) do
    begin
      if A[i] = B[j] then c := 0 else c := 1;
      Cur[j] := Prev[j-1] + c;
      if Prev[j] + 1 < Cur[j] then Cur[j] := Prev[j] + 1;
      if Cur[j-1] + 1 < Cur[j] then Cur[j] := Cur[j-1] + 1
    end;
    Prev := Copy(Cur)
  end;
  Result := Prev[Length(B)]
end;

//the call without its prefix or suffix (DL/OK2CQR, HB9BHW/P): the longest
//part between slashes. A garbled decode is judged on that, not on the /P
function BaseCall(const Call : String) : String;
var
  i, start : Integer;
begin
  Result := '';
  start := 1;
  for i := 1 to Length(Call) + 1 do
    if (i > Length(Call)) or (Call[i] = '/') then
    begin
      if i - start > Length(Result) then
        Result := Copy(Call, start, i - start);
      start := i + 1
    end
end;

constructor TSpotStore.Create(ACapacity : Integer);
begin
  inherited Create;
  if ACapacity < 1 then
    ACapacity := 1;
  FCapacity := ACapacity;
  SetLength(FItems, 64);
  DeleteAfterSec := 12 * 60;
  InitCriticalSection(FCrit)
end;

destructor TSpotStore.Destroy;
begin
  DoneCriticalsection(FCrit);
  inherited Destroy
end;

function TSpotStore.IndexOf(const C : TSpotCandidate) : Integer;
var
  i : Integer;
begin
  for i := 0 to FCount-1 do
    if (FItems[i].Origin = C.Origin) and (FItems[i].SourceId = C.SourceId) and
       (FItems[i].Call = C.Call) and (FItems[i].Band = C.Band) and
       (FItems[i].Mode = C.Mode) and (FItems[i].Spotter = C.Spotter) then
      exit(i);
  Result := -1
end;

procedure TSpotStore.DeleteAt(i : Integer);
begin
  if i < FCount-1 then
    FItems[i] := FItems[FCount-1];
  FItems[FCount-1] := Default(TSpotCandidate);
  Dec(FCount)
end;

procedure TSpotStore.MakeRoom;
var
  i, victim : Integer;
begin
  //the oldest RBN candidate first; only when there is none, the oldest of all
  victim := -1;
  for i := 0 to FCount-1 do
    if (FItems[i].Origin = soRbn) and ((victim < 0) or (FItems[i].LastSeen < FItems[victim].LastSeen)) then
      victim := i;
  if victim < 0 then
    for i := 0 to FCount-1 do
      if (victim < 0) or (FItems[i].LastSeen < FItems[victim].LastSeen) then
        victim := i;
  if victim >= 0 then
    DeleteAt(victim)
end;

function TSpotStore.Alive(const C : TSpotCandidate; ANow : TDateTime) : Boolean;
begin
  Result := (ANow - C.LastSeen) * 86400 <= DeleteAfterSec
end;

procedure TSpotStore.Add(const Spot : TSpotCandidate);
var
  i : Integer;
  C : TSpotCandidate;
begin
  C := Spot;
  C.Call    := UpperCase(Trim(C.Call));
  C.Spotter := UpperCase(Trim(C.Spotter));
  if (C.Call = '') or (C.Band = '') then
    exit;
  //a live arrival is one hit; a restored one brings its own count
  if C.Hits < 1 then
    C.Hits := 1;
  EnterCriticalsection(FCrit);
  try
    i := IndexOf(C);
    if i >= 0 then
    begin
      //keep the later of the two times: a snapshot must not turn the clock back
      if C.LastSeen < FItems[i].LastSeen then
        C.LastSeen := FItems[i].LastSeen;
      C.Hits := FItems[i].Hits + C.Hits;
      FItems[i] := C
    end
    else begin
      if FCount >= FCapacity then
        MakeRoom;
      if FCount = Length(FItems) then
        SetLength(FItems, Length(FItems) * 2);
      FItems[FCount] := C;
      Inc(FCount)
    end
  finally
    LeaveCriticalsection(FCrit)
  end
end;

procedure TSpotStore.Remove(const Call, Band, Mode : String);
var
  i : Integer;
  c : String;
begin
  c := UpperCase(Trim(Call));
  EnterCriticalsection(FCrit);
  try
    for i := FCount-1 downto 0 do
      if (FItems[i].Call = c) and (FItems[i].Band = Band) and (FItems[i].Mode = Mode) then
        DeleteAt(i)
  finally
    LeaveCriticalsection(FCrit)
  end
end;

procedure TSpotStore.DropRbnSource(SourceId : Integer);
var
  i : Integer;
begin
  EnterCriticalsection(FCrit);
  try
    for i := FCount-1 downto 0 do
      if (FItems[i].Origin = soRbn) and (FItems[i].SourceId = SourceId) then
        DeleteAt(i)
  finally
    LeaveCriticalsection(FCrit)
  end
end;

procedure TSpotStore.Expire(ANow : TDateTime);
var
  i : Integer;
begin
  EnterCriticalsection(FCrit);
  try
    for i := FCount-1 downto 0 do
      if not Alive(FItems[i], ANow) then
        DeleteAt(i)
  finally
    LeaveCriticalsection(FCrit)
  end
end;

procedure TSpotStore.Clear;
var
  i : Integer;
begin
  EnterCriticalsection(FCrit);
  try
    for i := 0 to FCount-1 do
      FItems[i] := Default(TSpotCandidate);
    FCount := 0
  finally
    LeaveCriticalsection(FCrit)
  end
end;

//is A the better of two look-alikes: more often heard, then longer, then later
function Outranks(const A, B : TSpotCandidate) : Boolean;
begin
  if A.Hits <> B.Hits then
    exit(A.Hits > B.Hits);
  if Length(BaseCall(A.Call)) <> Length(BaseCall(B.Call)) then
    exit(Length(BaseCall(A.Call)) > Length(BaseCall(B.Call)));
  Result := A.LastSeen > B.LastSeen
end;

function TSpotStore.Select(const Band : String; ANow : TDateTime; const Filter : TSpotFilter;
                           Worked : TWorkedRule) : TSpotView;
var
  i, j, n : Integer;
  h       : Integer;
  T       : TSpotCandidate;
begin
  Result := nil;
  n := 0;
  EnterCriticalsection(FCrit);
  try
    SetLength(Result, FCount);
    for i := 0 to FCount-1 do
    begin
      if not (FItems[i].Origin in Filter.Origins) then Continue;
      if (Band <> '') and (FItems[i].Band <> Band) then Continue;
      if (Filter.Mode <> '') and (FItems[i].Mode <> Filter.Mode) then Continue;
      if Filter.OnlyLoTW and not FItems[i].IsLoTW then Continue;
      if Filter.OnlyEQSL and not FItems[i].IsEQSL then Continue;
      if not Alive(FItems[i], ANow) then Continue;
      Result[n] := FItems[i];
      Inc(n)
    end
  finally
    LeaveCriticalsection(FCrit)
  end;
  SetLength(Result, n);
  //one station once per band and mode, where it was heard last: after a QSY
  //some skimmers still hold the old frequency for a while. The store keeps
  //every spotter (the source filter needs them apart), the view does not
  for i := 0 to n-1 do
    if Result[i].Call <> '' then
      for j := i+1 to n-1 do
        if (Result[j].Call = Result[i].Call) and (Result[j].Band = Result[i].Band) and
           (Result[j].Mode = Result[i].Mode) then
        begin
          h := Result[i].Hits + Result[j].Hits;
          if Result[j].LastSeen > Result[i].LastSeen then
            Result[i] := Result[j];
          Result[i].Hits := h;
          Result[j].Call := ''
        end;
  //a skimmer that garbles a decode reports a look-alike of the real call
  //(OK2CQ, OK2CQA for OK2CQR) on the same frequency. Of two look-alikes the
  //one spotted more often stays, on a tie the longer, then the later one
  for i := 0 to n-1 do
    if Result[i].Call <> '' then
      for j := 0 to n-1 do
        if (j <> i) and (Result[j].Call <> '') and
           (Result[j].Band = Result[i].Band) and (Result[j].Mode = Result[i].Mode) and
           (Abs(Result[j].FreqKHz - Result[i].FreqKHz) <= SIMILAR_CALL_KHZ + 1e-6) and
           (CallDistance(BaseCall(Result[i].Call), BaseCall(Result[j].Call), SIMILAR_CALL_DISTANCE) <= SIMILAR_CALL_DISTANCE) and
           Outranks(Result[j], Result[i]) then
        begin
          Result[i].Call := '';
          Break
        end;
  j := 0;
  for i := 0 to n-1 do
    if Result[i].Call <> '' then
    begin
      Result[j] := Result[i];
      Inc(j)
    end;
  SetLength(Result, j);
  n := j;
  //the QSO rule may cost a database round trip, so it runs outside the lock
  if Assigned(Worked) then
  begin
    j := 0;
    for i := 0 to n-1 do
      if not Worked(Result[i].Call, Result[i].Band, Result[i].Mode) then
      begin
        Result[j] := Result[i];
        Inc(j)
      end;
    SetLength(Result, j);
    n := j
  end;
  //insertion sort by frequency; the views are small
  for i := 1 to n-1 do
  begin
    T := Result[i];
    j := i-1;
    while (j >= 0) and (Result[j].FreqKHz > T.FreqKHz) do
    begin
      Result[j+1] := Result[j];
      Dec(j)
    end;
    Result[j+1] := T
  end
end;

function TSpotStore.Count : Integer;
begin
  EnterCriticalsection(FCrit);
  try
    Result := FCount
  finally
    LeaveCriticalsection(FCrit)
  end
end;

//one line per candidate, ';' separated. LastSeen is a TDateTime as text with a
//dot, whatever the locale, so the file moves between machines
var
  fsSnap : TFormatSettings;

function Esc(const s : String) : String;
begin
  Result := StringReplace(s, ';', ',', [rfReplaceAll])
end;

procedure TSpotStore.SaveSnapshot(Lines : TStrings);
var
  i : Integer;
begin
  Lines.Clear;
  Lines.Add('cqrlog spots ' + IntToStr(SPOT_SNAPSHOT_VERSION));
  EnterCriticalsection(FCrit);
  try
    for i := 0 to FCount-1 do
      with FItems[i] do
        Lines.Add(IntToStr(Ord(Origin)) + ';' + IntToStr(SourceId) + ';' + Esc(Spotter) + ';' +
                  Esc(Call) + ';' + Esc(Band) + ';' + Esc(Mode) + ';' +
                  FloatToStr(FreqKHz, fsSnap) + ';' + Esc(SplitInfo) + ';' +
                  IntToStr(Color) + ';' + IntToStr(BgColor) + ';' +
                  IntToStr(Ord(IsLoTW)) + IntToStr(Ord(IsEQSL)) + ';' +
                  FloatToStr(LastSeen, fsSnap) + ';' + IntToStr(Hits))
  finally
    LeaveCriticalsection(FCrit)
  end
end;

procedure TSpotStore.LoadSnapshot(Lines : TStrings; ANow : TDateTime);
var
  i      : Integer;
  P      : TStringList;
  C      : TSpotCandidate;
  o      : Integer;
begin
  if (Lines.Count = 0) or (Lines[0] <> 'cqrlog spots ' + IntToStr(SPOT_SNAPSHOT_VERSION)) then
    exit;
  P := TStringList.Create;
  try
    P.Delimiter := ';';
    P.StrictDelimiter := True;
    for i := 1 to Lines.Count-1 do
    begin
      P.DelimitedText := Lines[i];
      if P.Count <> 13 then Continue;
      C := Default(TSpotCandidate);
      if not TryStrToInt(P[0], o) or (o < 0) or (o > Ord(High(TSpotOrigin))) then Continue;
      C.Origin := TSpotOrigin(o);
      if not TryStrToInt(P[1], C.SourceId) then Continue;
      C.Spotter   := P[2];
      C.Call      := P[3];
      C.Band      := P[4];
      C.Mode      := P[5];
      if not TryStrToFloat(P[6], C.FreqKHz, fsSnap) or (C.FreqKHz <= 0) then Continue;
      C.SplitInfo := P[7];
      if not TryStrToInt(P[8], C.Color) then Continue;
      if not TryStrToInt(P[9], C.BgColor) then Continue;
      if Length(P[10]) <> 2 then Continue;
      C.IsLoTW := P[10][1] = '1';
      C.IsEQSL := P[10][2] = '1';
      if not TryStrToFloat(P[11], C.LastSeen, fsSnap) then Continue;
      if not TryStrToInt(P[12], C.Hits) or (C.Hits < 1) then Continue;
      //not from the future (a minute of tolerance: the text form of a
      //TDateTime is rounded, and clocks are not exact), not already dead
      if (C.LastSeen > ANow + 1/1440) or (not Alive(C, ANow)) then Continue;
      Add(C)
    end
  finally
    P.Free
  end
end;

initialization
  fsSnap := DefaultFormatSettings;
  fsSnap.DecimalSeparator  := '.';
  fsSnap.ThousandSeparator := #0;
end.
