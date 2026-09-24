(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The queue of "was this station worked?" questions the band map windows hand
  to the log check thread. }

unit tCheckQueue;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uLogCheckQueue;

type
  TLogCheckQueueTest = class(TTestCase)
  private
    Q : TLogCheckQueue;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure PopsInArrivalOrder;
    procedure SameStationIsQueuedOnce;
    procedure DifferentBandIsAnotherQuestion;
    procedure CanBeAskedAgainOncePopped;
    procedure ClearEmptiesIt;
    procedure MembershipIsAnotherKindOfQuestion;
  end;

implementation

procedure TLogCheckQueueTest.SetUp;
begin
  Q := TLogCheckQueue.Create
end;

procedure TLogCheckQueueTest.TearDown;
begin
  Q.Free
end;

procedure TLogCheckQueueTest.PopsInArrivalOrder;
var
  R : TLogCheckRequest;
begin
  Q.Push('OK1AA', '20M', 'CW');
  Q.Push('OK1BB', '20M', 'CW');
  AssertEquals(2, Q.Count);
  AssertTrue(Q.Pop(R));
  AssertEquals('OK1AA', R.Call);
  AssertEquals('20M', R.Band);
  AssertEquals('CW', R.Mode);
  AssertTrue(Q.Pop(R));
  AssertEquals('OK1BB', R.Call);
  AssertFalse(Q.Pop(R));
  AssertEquals(0, Q.Count)
end;

procedure TLogCheckQueueTest.SameStationIsQueuedOnce;
begin
  //four windows ask about the same spot within one tick
  Q.Push('OK1AA', '20M', 'CW');
  Q.Push('ok1aa', '20M', 'CW');
  AssertEquals(1, Q.Count)
end;

procedure TLogCheckQueueTest.DifferentBandIsAnotherQuestion;
begin
  Q.Push('OK1AA', '20M', 'CW');
  Q.Push('OK1AA', '40M', 'CW');
  Q.Push('OK1AA', '40M', 'SSB');
  AssertEquals(3, Q.Count)
end;

procedure TLogCheckQueueTest.CanBeAskedAgainOncePopped;
var
  R : TLogCheckRequest;
begin
  Q.Push('OK1AA', '20M', 'CW');
  Q.Pop(R);
  Q.Push('OK1AA', '20M', 'CW');
  AssertEquals(1, Q.Count)
end;

procedure TLogCheckQueueTest.ClearEmptiesIt;
var
  R : TLogCheckRequest;
begin
  Q.Push('OK1AA', '20M', 'CW');
  Q.Clear;
  AssertEquals(0, Q.Count);
  AssertFalse(Q.Pop(R));
  Q.Push('OK1AA', '20M', 'CW');
  AssertEquals(1, Q.Count)
end;

procedure TLogCheckQueueTest.MembershipIsAnotherKindOfQuestion;
var
  R : TLogCheckRequest;
begin
  Q.Push('OK1AA', '20M', 'CW');
  Q.PushMembership('OK1AA', '2026-09-23');
  Q.PushMembership('OK1AA', '2026-09-23');   //queued once
  AssertEquals(2, Q.Count);
  AssertTrue(Q.Pop(R));
  AssertTrue(R.Kind = lckWorked);
  AssertTrue(Q.Pop(R));
  AssertTrue(R.Kind = lckMembership);
  AssertEquals('OK1AA', R.Call);
  AssertEquals('2026-09-23', R.Date);
  AssertFalse(Q.Pop(R))
end;

initialization
  RegisterTest(TLogCheckQueueTest);

end.
