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
    Clubs      : String;     //what the fake club tables answer
    function FakeMembership(const Call, Date : String) : String;
    function FakeLastQso(const Call, Band, Mode : String) : String;
    function FakeStatus(Adif : Word; const Band, Mode : String) : Integer;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure FirstAskFetchesSecondDoesNot;
    procedure TryAnswersFromTheCacheOnly;
    procedure DifferentBandIsADifferentEntry;
    procedure DifferentBoundaryIsADifferentEntry;
    procedure NegativeAnswerIsCachedToo;
    procedure EntryExpires;
    procedure InvalidateAllForgetsEverything;
    procedure InvalidateCallForgetsThatCallOnly;
    procedure DxccStatusIsCachedByEntityBandMode;
    procedure InvalidateAllForgetsDxccStatusToo;
    procedure CacheIsBounded;
    procedure MembershipIsFetchedOncePerCallAndDay;
    procedure TryMembershipAnswersFromTheCacheOnly;
    procedure NoMembershipIsCachedToo;
    procedure AnotherDayAsksAgain;
    procedure InvalidateMembershipKeepsTheLogEntries;
    procedure SavedQsoKeepsTheMembership;
    procedure GenerationMovesWithEveryMembershipChange;
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

function TLogCacheTest.FakeMembership(const Call, Date : String) : String;
begin
  Inc(FetchCount);
  Result := Clubs
end;

procedure TLogCacheTest.SetUp;
begin
  C := TRbnLogCache.Create(1000);
  C.OnLastQso     := @FakeLastQso;
  C.OnDxccStatus  := @FakeStatus;
  C.OnMembership  := @FakeMembership;
  Clubs := 'EPC, SOTA';
  FetchCount := 0;
  LastQso := '2026-09-21 12:00';
  Status := 4
end;

procedure TLogCacheTest.TearDown;
begin
  FreeAndNil(C)
end;

procedure TLogCacheTest.TryAnswersFromTheCacheOnly;
var
  worked : Boolean;
begin
  LastQso := '2026-09-20 10:00';
  //unknown station: no answer and, above all, no round trip to the log
  AssertFalse(C.TryWorkedAfter('OK1ABC', '20M', 'CW', '2026-09-19', '00:00', worked));
  AssertEquals(0, FetchCount);
  //once fetched the answer comes from the cache
  AssertTrue(C.WorkedAfter('OK1ABC', '20M', 'CW', '2026-09-19', '00:00'));
  AssertEquals(1, FetchCount);
  AssertTrue(C.TryWorkedAfter('OK1ABC', '20M', 'CW', '2026-09-19', '00:00', worked));
  AssertTrue(worked);
  AssertTrue(C.TryWorkedAfter('OK1ABC', '20M', 'CW', '2026-09-21', '00:00', worked));
  AssertFalse(worked);
  AssertEquals(1, FetchCount)
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

procedure TLogCacheTest.MembershipIsFetchedOncePerCallAndDay;
begin
  AssertEquals('EPC, SOTA', C.Membership('OK1AA', '2026-09-23'));
  AssertEquals('EPC, SOTA', C.Membership('ok1aa', '2026-09-23'));
  AssertEquals(1, FetchCount)
end;

procedure TLogCacheTest.TryMembershipAnswersFromTheCacheOnly;
var
  lbl : String;
begin
  //four windows draw the same spot: none of them may go to the club tables
  AssertFalse(C.TryMembership('OK1AA', '2026-09-23', lbl));
  AssertEquals(0, FetchCount);
  C.Membership('OK1AA', '2026-09-23');
  AssertTrue(C.TryMembership('OK1AA', '2026-09-23', lbl));
  AssertEquals('EPC, SOTA', lbl);
  AssertEquals(1, FetchCount)
end;

procedure TLogCacheTest.NoMembershipIsCachedToo;
var
  lbl : String;
begin
  //most stations are in no club; asking again for each spot would cost the
  //same round trips as a member
  Clubs := '';
  AssertEquals('', C.Membership('ZZ9ZZZ', '2026-09-23'));
  AssertTrue(C.TryMembership('ZZ9ZZZ', '2026-09-23', lbl));
  AssertEquals('', lbl);
  AssertEquals(1, FetchCount)
end;

procedure TLogCacheTest.AnotherDayAsksAgain;
begin
  //membership rows have fromdate/todate, so the answer belongs to the day
  C.Membership('OK1AA', '2026-09-23');
  C.Membership('OK1AA', '2026-09-24');
  AssertEquals(2, FetchCount)
end;

procedure TLogCacheTest.InvalidateMembershipKeepsTheLogEntries;
begin
  //a club table was re-imported: the log itself has not changed
  C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-20', '10:00');
  C.DxccStatus(503, '20M', 'CW');
  C.Membership('OK1AA', '2026-09-23');
  AssertEquals(3, FetchCount);
  C.InvalidateMembership;
  C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-20', '10:00');
  C.DxccStatus(503, '20M', 'CW');
  AssertEquals(3, FetchCount);
  C.Membership('OK1AA', '2026-09-23');
  AssertEquals(4, FetchCount)
end;

procedure TLogCacheTest.SavedQsoKeepsTheMembership;
begin
  C.Membership('OK1AA', '2026-09-23');
  C.InvalidateCall('OK1AA');
  C.Membership('OK1AA', '2026-09-23');
  AssertEquals(1, FetchCount);
  C.InvalidateAll;   //log switched: the clubs selected may differ
  C.Membership('OK1AA', '2026-09-23');
  AssertEquals(2, FetchCount)
end;

procedure TLogCacheTest.GenerationMovesWithEveryMembershipChange;
var
  g : Integer;
begin
  //the windows repaint when the generation moved, without polling the cache
  g := C.MembershipGeneration;
  C.WorkedAfter('OK1AA', '20M', 'CW', '2026-09-20', '10:00');
  AssertEquals(g, C.MembershipGeneration);
  C.Membership('OK1AA', '2026-09-23');
  AssertTrue(C.MembershipGeneration > g);
  g := C.MembershipGeneration;
  C.Membership('OK1AA', '2026-09-23');   //a hit changes nothing
  AssertEquals(g, C.MembershipGeneration);
  C.InvalidateMembership;
  AssertTrue(C.MembershipGeneration > g);
  g := C.MembershipGeneration;
  C.InvalidateAll;
  AssertTrue(C.MembershipGeneration > g)
end;

initialization
  RegisterTest(TLogCacheTest);
end.
