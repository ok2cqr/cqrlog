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
  (InvalidateCall) or the log changes (InvalidateAll).  Bounded: when full the
  oldest entries go.

  Thread safe: the callbacks are called outside the lock, so a slow fetch does
  not hold the other threads; two threads asking the same thing at once may
  both fetch, which is harmless.  See tests/tLogCache.pas. }

unit uRbnLogCache;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs;

type
  TWorkedAfterFunc = function(const Call, Band, Mode, LastDate, LastTime : String) : Boolean of object;
  TDxccStatusFunc  = function(Adif : Word; const Band, Mode : String) : Integer of object;

  TRbnLogCache = class
  private
    FCrit     : TRTLCriticalSection;
    FMap      : TFPHashList;    //key -> PEntry
    FCapacity : Integer;
    FClock    : Int64;          //insertion order, for eviction
    function  Get(const Key : String; out Value : Integer) : Boolean;
    procedure Put(const Key, Call : String; Value : Integer);
    procedure ClearAll;
  public
    OnWorkedAfter : TWorkedAfterFunc;
    OnDxccStatus  : TDxccStatusFunc;
    TtlSeconds    : Integer;
    constructor Create(ACapacity : Integer);
    destructor Destroy; override;
    function  WorkedAfter(const Call, Band, Mode, LastDate, LastTime : String) : Boolean;
    //the index of TdmData.RbnMonDXCCInfo: 0 confirmed/unknown, 1 new country,
    //2 new band, 3 new mode, 4 QSL needed
    function  DxccStatus(Adif : Word; const Band, Mode : String) : Integer;
    procedure InvalidateAll;                  //log switched, DXCC tables reloaded
    procedure InvalidateCall(const Call : String);  //a QSO with it was saved or changed
    function  Count : Integer;
  end;

implementation

type
  PEntry = ^TEntry;
  TEntry = record
    Value : Integer;
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

function TRbnLogCache.Get(const Key : String; out Value : Integer) : Boolean;
var
  E : PEntry;
begin
  Value := 0;
  EnterCriticalsection(FCrit);
  try
    E := PEntry(FMap.Find(Key));
    Result := (E <> nil) and ((Now - E^.Stamp) * 86400 < TtlSeconds);
    if Result then
      Value := E^.Value
  finally
    LeaveCriticalsection(FCrit)
  end
end;

procedure TRbnLogCache.Put(const Key, Call : String; Value : Integer);
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
        Dispose(PEntry(FMap[old]));
        FMap.Delete(old)
      end;
      New(E);
      E^.Call := Call;
      FMap.Add(Key, E)
    end;
    E^.Value := Value;
    E^.Stamp := Now;
    Inc(FClock);
    E^.Order := FClock
  finally
    LeaveCriticalsection(FCrit)
  end
end;

function TRbnLogCache.WorkedAfter(const Call, Band, Mode, LastDate, LastTime : String) : Boolean;
var
  Key : String;
  v   : Integer;
begin
  Key := 'W|' + UpperCase(Call) + '|' + Band + '|' + Mode + '|' + LastDate + ' ' + LastTime;
  if Get(Key, v) then
    exit(v <> 0);
  Result := OnWorkedAfter(Call, Band, Mode, LastDate, LastTime);
  Put(Key, UpperCase(Call), Ord(Result))
end;

function TRbnLogCache.DxccStatus(Adif : Word; const Band, Mode : String) : Integer;
var
  Key : String;
begin
  Key := 'D|' + IntToStr(Adif) + '|' + Band + '|' + Mode;
  if Get(Key, Result) then
    exit;
  Result := OnDxccStatus(Adif, Band, Mode);
  Put(Key, '', Result)
end;

procedure TRbnLogCache.InvalidateAll;
begin
  EnterCriticalsection(FCrit);
  try
    ClearAll
  finally
    LeaveCriticalsection(FCrit)
  end
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
      if PEntry(FMap[i])^.Call = c then
      begin
        Dispose(PEntry(FMap[i]));
        FMap.Delete(i)
      end
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
