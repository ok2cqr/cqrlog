(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ What the current log says about a callsign or a DXCC entity, fetched once
  and reused: "worked on this band and mode after a moment" and the DXCC
  status (new one / new band / new mode / QSL needed / confirmed).

  The fetches are callbacks, so the cache knows nothing of SQL and is tested
  with a fake log.  Entries expire after TtlSeconds (QSOs can be edited outside
  the application) and are dropped explicitly when a QSO is saved
  (InvalidateCall), deleted (InvalidateLog) or the log is switched
  (InvalidateAll).  Bounded: when full the oldest entries go.

  Club membership of a heard station lives here too (key M|call|date): one
  fetch per call and day for every window, negative answers included, dropped
  when a club table is re-imported, the club selection changes
  (InvalidateMembership) or the log is switched, never by a QSO.  MembershipGeneration moves with every change, so
  the windows know when to repaint without walking the cache.

  Thread safe: the callbacks are called outside the lock, so a slow fetch does
  not hold the other threads; two threads asking the same thing at once may
  both fetch, which is harmless.  See tests/tLogCache.pas. }

unit uRbnLogCache;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs;

type
  //the moment of the last QSO with the call on the band and mode, as the log
  //stores it: 'YYYY-MM-DD HH:NN' (UTC); '' when there is none
  TLastQsoFunc     = function(const Call, Band, Mode : String) : String of object;
  TDxccStatusFunc  = function(Adif : Word; const Band, Mode : String) : Integer of object;
  //the short names of the clubs the call is a member of on the day
  //('YYYY-MM-DD'), 'EPC, SOTA'; '' when none
  TMembershipFunc  = function(const Call, Date : String) : String of object;

  TRbnLogCache = class
  private
    FCrit     : TRTLCriticalSection;
    FMap      : TFPHashList;    //key -> PEntry
    FCapacity : Integer;
    FClock    : Int64;          //insertion order, for eviction
    FMemberGen : Integer;
    function  Get(const Key : String; out Value : Integer; out Text : String) : Boolean;
    procedure Put(const Key, Call : String; Value : Integer; const Text : String = '');
    procedure ClearAll;
    procedure Drop(Index : Integer);
  public
    OnLastQso     : TLastQsoFunc;
    OnDxccStatus  : TDxccStatusFunc;
    OnMembership  : TMembershipFunc;
    TtlSeconds    : Integer;
    constructor Create(ACapacity : Integer);
    destructor Destroy; override;
    //was there a QSO after LastDate LastTime? Answered from the cached last
    //QSO, so a boundary that moves with the clock costs no new fetch
    function  WorkedAfter(const Call, Band, Mode, LastDate, LastTime : String) : Boolean;
    //the same answer from the cache alone: False when the station has not
    //been looked up yet, so the caller can ration the round trips
    function  TryWorkedAfter(const Call, Band, Mode, LastDate, LastTime : String;
                             out Worked : Boolean) : Boolean;
    //the index of TdmData.RbnMonDXCCInfo: 0 confirmed/unknown, 1 new country,
    //2 new band, 3 new mode, 4 QSL needed
    function  DxccStatus(Adif : Word; const Band, Mode : String) : Integer;
    //club membership label of the call on the day, fetched on a miss
    function  Membership(const Call, Date : String) : String;
    //the same from the cache alone: False when not looked up yet
    function  TryMembership(const Call, Date : String; out ALabel : String) : Boolean;
    procedure InvalidateAll;                  //log switched, DXCC tables reloaded
    //a QSO with it was saved: its entries and every DXCC status go, as the
    //entity of the QSO is not at hand
    procedure InvalidateCall(const Call : String);
    //a QSO was deleted: all the log says goes, the membership stays
    procedure InvalidateLog;
    //a club table was re-imported or the selected clubs changed
    procedure InvalidateMembership;
    //moves whenever a membership answer arrives or is dropped
    function  MembershipGeneration : Integer;
    function  Count : Integer;
  end;

implementation

type
  PEntry = ^TEntry;
  TEntry = record
    Value : Integer;
    Text  : String;   //the last QSO moment for W entries
    Stamp : TDateTime;
    Order : Int64;
    Call  : String;   //'' for DXCC entries
  end;

constructor TRbnLogCache.Create(ACapacity : Integer);
begin
  inherited Create;
  if ACapacity < 1 then
    ACapacity := 1;
  FCapacity := ACapacity;
  FMap := TFPHashList.Create;
  TtlSeconds := 600;
  InitCriticalSection(FCrit)
end;

destructor TRbnLogCache.Destroy;
begin
  ClearAll;
  FMap.Free;
  DoneCriticalsection(FCrit);
  inherited Destroy
end;

procedure TRbnLogCache.ClearAll;
var
  i : Integer;
begin
  for i := 0 to FMap.Count-1 do
    Dispose(PEntry(FMap[i]));
  FMap.Clear
end;

procedure TRbnLogCache.Drop(Index : Integer);
begin
  Dispose(PEntry(FMap[Index]));
  FMap.Delete(Index)
end;

function TRbnLogCache.Get(const Key : String; out Value : Integer; out Text : String) : Boolean;
var
  E : PEntry;
begin
  Value := 0;
  Text  := '';
  EnterCriticalsection(FCrit);
  try
    E := PEntry(FMap.Find(Key));
    Result := (E <> nil) and ((Now - E^.Stamp) * 86400 < TtlSeconds);
    if Result then
    begin
      Value := E^.Value;
      Text  := E^.Text
    end
  finally
    LeaveCriticalsection(FCrit)
  end
end;

procedure TRbnLogCache.Put(const Key, Call : String; Value : Integer; const Text : String);
var
  E      : PEntry;
  i, old : Integer;
  oldest : Int64;
begin
  EnterCriticalsection(FCrit);
  try
    E := PEntry(FMap.Find(Key));
    if E = nil then
    begin
      if FMap.Count >= FCapacity then
      begin
        //the oldest goes. A scan, but Count is small and this is a miss anyway
        old := 0;
        oldest := High(Int64);
        for i := 0 to FMap.Count-1 do
          if PEntry(FMap[i])^.Order < oldest then
          begin
            oldest := PEntry(FMap[i])^.Order;
            old := i
          end;
        Drop(old)
      end;
      New(E);
      E^.Call := Call;
      FMap.Add(Key, E)
    end;
    E^.Value := Value;
    E^.Text  := Text;
    E^.Stamp := Now;
    Inc(FClock);
    E^.Order := FClock
  finally
    LeaveCriticalsection(FCrit)
  end
end;

function TRbnLogCache.WorkedAfter(const Call, Band, Mode, LastDate, LastTime : String) : Boolean;
var
  Key  : String;
  v    : Integer;
  Last : String;
begin
  Key := 'W|' + UpperCase(Call) + '|' + Band + '|' + Mode;
  if not Get(Key, v, Last) then
  begin
    Last := OnLastQso(Call, Band, Mode);
    Put(Key, UpperCase(Call), 0, Last)
  end;
  //both are 'YYYY-MM-DD HH:NN', so text order is time order
  Result := (Last <> '') and (Last > LastDate + ' ' + LastTime)
end;

function TRbnLogCache.TryWorkedAfter(const Call, Band, Mode, LastDate, LastTime : String;
                                     out Worked : Boolean) : Boolean;
var
  v    : Integer;
  Last : String;
begin
  Worked := False;
  Result := Get('W|' + UpperCase(Call) + '|' + Band + '|' + Mode, v, Last);
  if Result then
    Worked := (Last <> '') and (Last > LastDate + ' ' + LastTime)
end;

function TRbnLogCache.DxccStatus(Adif : Word; const Band, Mode : String) : Integer;
var
  Key : String;
  t   : String;
begin
  Key := 'D|' + IntToStr(Adif) + '|' + Band + '|' + Mode;
  if Get(Key, Result, t) then
    exit;
  Result := OnDxccStatus(Adif, Band, Mode);
  Put(Key, '', Result, '')
end;

function TRbnLogCache.Membership(const Call, Date : String) : String;
var
  Key : String;
  v   : Integer;
begin
  Key := 'M|' + UpperCase(Call) + '|' + Date;
  if Get(Key, v, Result) then
    exit;
  Result := OnMembership(Call, Date);
  //Call stays '' on purpose: a saved QSO (InvalidateCall) changes no membership
  Put(Key, '', 0, Result);
  InterlockedIncrement(FMemberGen)
end;

function TRbnLogCache.TryMembership(const Call, Date : String; out ALabel : String) : Boolean;
var
  v : Integer;
begin
  Result := Get('M|' + UpperCase(Call) + '|' + Date, v, ALabel)
end;

procedure TRbnLogCache.InvalidateMembership;
var
  i : Integer;
begin
  EnterCriticalsection(FCrit);
  try
    for i := FMap.Count-1 downto 0 do
      if Copy(FMap.NameOfIndex(i), 1, 2) = 'M|' then
        Drop(i)
  finally
    LeaveCriticalsection(FCrit)
  end;
  InterlockedIncrement(FMemberGen)
end;

function TRbnLogCache.MembershipGeneration : Integer;
begin
  Result := FMemberGen
end;

procedure TRbnLogCache.InvalidateAll;
begin
  EnterCriticalsection(FCrit);
  try
    ClearAll
  finally
    LeaveCriticalsection(FCrit)
  end;
  InterlockedIncrement(FMemberGen)
end;

procedure TRbnLogCache.InvalidateCall(const Call : String);
var
  i : Integer;
  c : String;
begin
  c := UpperCase(Call);
  EnterCriticalsection(FCrit);
  try
    for i := FMap.Count-1 downto 0 do
      if (PEntry(FMap[i])^.Call = c) or (Copy(FMap.NameOfIndex(i), 1, 2) = 'D|') then
        Drop(i)
  finally
    LeaveCriticalsection(FCrit)
  end
end;

procedure TRbnLogCache.InvalidateLog;
var
  i : Integer;
begin
  EnterCriticalsection(FCrit);
  try
    for i := FMap.Count-1 downto 0 do
      if Copy(FMap.NameOfIndex(i), 1, 2) <> 'M|' then
        Drop(i)
  finally
    LeaveCriticalsection(FCrit)
  end
end;

function TRbnLogCache.Count : Integer;
begin
  EnterCriticalsection(FCrit);
  try
    Result := FMap.Count
  finally
    LeaveCriticalsection(FCrit)
  end
end;

end.
