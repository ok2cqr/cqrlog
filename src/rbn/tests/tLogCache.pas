(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The shared log cache: what the log says about a callsign or a DXCC entity
  (worked after a moment; new one / new band / new mode / QSL needed), fetched
  once and reused across spots and windows.  Stage 0 measured 2-5 round trips
  per spot, with the DXCC status queries scanning the whole table. }

unit tLogCache;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uRbnLogCache;

type
  TLogCacheTest = class(TTestCase)
  private
    C          : TRbnLogCache;
    FetchCount : Integer;
    LastQso    : String;     //what the fake log answers: 'YYYY-MM-DD HH:NN' or ''
    Status     : Integer;
    function FakeLastQso(const Call, Band, Mode : String) : String;
    function FakeStatus(Adif : Word; const Band, Mode : String) : Integer;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure FirstAskFetchesSecondDoesNot;
    procedure DifferentBandIsADifferentEntry;
    procedure DifferentBoundaryIsADifferentEntry;
    procedure NegativeAnswerIsCachedToo;
    procedure EntryExpires;
    procedure InvalidateAllForgetsEverything;
    procedure InvalidateCallForgetsThatCallOnly;
    procedure DxccStatusIsCachedByEntityBandMode;
    procedure InvalidateAllForgetsDxccStatusToo;
    procedure CacheIsBounded;
  end;

implementation

function TLogCacheTest.FakeLastQso(const Call, Band, Mode : String) : String;
begin
  Inc(FetchCount);
  Result := LastQso
end;

function TLogCacheTest.FakeStatus(Adif : Word; const Band, Mode : String) : Integer;
begin
  Inc(FetchCount);
  Result := Status
end;

procedure TLogCacheTest.SetUp;
begin
  C := TRbnLogCache.Create(1000);
  C.OnLastQso    := @FakeLastQso;
  C.OnDxccStatus := @FakeStatus;
  FetchCount := 0;
  LastQso := '2026-09-21 12:00';
  Status := 4
end;

procedure TLogCacheTest.TearDown;
begin
  FreeAndNil(C)
end;

procedure TLogCacheTest.FirstAskFetchesSecondDoesNot;
begin
  AssertTrue(C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-20', '10:00'));
  AssertTrue(C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-20', '10:00'));
  AssertEquals(1, FetchCount)
end;

procedure TLogCacheTest.DifferentBandIsADifferentEntry;
begin
  C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-20', '10:00');
  C.WorkedAfter('OK1AA', '40M', 'CW', '2026-09-20', '10:00');
  AssertEquals(2, FetchCount)
end;

procedure TLogCacheTest.DifferentBoundaryIsADifferentEntry;
begin
  //"worked in the last 48 h" moves with the clock, minute by minute; the
  //cached last QSO serves every boundary without another fetch
  AssertTrue(C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-20', '10:00'));
  AssertTrue(C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-21', '11:59'));
  AssertFalse(C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-21', '12:00'));
  AssertFalse(C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-22', '00:00'));
  AssertEquals(1, FetchCount)
end;

procedure TLogCacheTest.NegativeAnswerIsCachedToo;
begin
  LastQso := '';
  AssertFalse(C.WorkedAfter('ZZ9ZZZ', '20M', 'CW', '2026-09-20', '10:00'));
  AssertFalse(C.WorkedAfter('ZZ9ZZZ', '20M', 'CW', '2026-09-20', '10:00'));
  AssertEquals(1, FetchCount)
end;

procedure TLogCacheTest.EntryExpires;
begin
  C.TtlSeconds := 0;  //everything is stale at once
  C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-20', '10:00');
  C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-20', '10:00');
  AssertEquals(2, FetchCount)
end;

procedure TLogCacheTest.InvalidateAllForgetsEverything;
begin
  C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-20', '10:00');
  C.InvalidateAll;   //log switched
  C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-20', '10:00');
  AssertEquals(2, FetchCount)
end;

procedure TLogCacheTest.InvalidateCallForgetsThatCallOnly;
begin
  C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-20', '10:00');
  C.WorkedAfter('OK2BB', '20M', 'CW', '2026-09-20', '10:00');
  C.InvalidateCall('ok1aa');   //a QSO with OK1AA was saved
  C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-20', '10:00');
  C.WorkedAfter('OK2BB', '20M', 'CW', '2026-09-20', '10:00');
  AssertEquals(3, FetchCount)
end;

procedure TLogCacheTest.DxccStatusIsCachedByEntityBandMode;
begin
  AssertEquals(4, C.DxccStatus(503, '20M', 'CW'));
  AssertEquals(4, C.DxccStatus(503, '20M', 'CW'));
  C.DxccStatus(503, '40M', 'CW');
  C.DxccStatus(503, '20M', 'SSB');
  AssertEquals(3, FetchCount)
end;

procedure TLogCacheTest.InvalidateAllForgetsDxccStatusToo;
begin
  C.DxccStatus(503, '20M', 'CW');
  C.InvalidateAll;
  C.DxccStatus(503, '20M', 'CW');
  AssertEquals(2, FetchCount)
end;

procedure TLogCacheTest.CacheIsBounded;
var
  i : Integer;
begin
  FreeAndNil(C);
  C := TRbnLogCache.Create(10);
  C.OnLastQso := @FakeLastQso;
  for i := 1 to 100 do
    C.WorkedAfter('C' + IntToStr(i), '20M', 'CW', '2026-09-20', '10:00');
  AssertTrue('entries=' + IntToStr(C.Count), C.Count <= 10)
end;

initialization
  RegisterTest(TLogCacheTest);
end.
