(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The queue between the socket (main thread) and the worker that filters spots.
  It used to be a TStringList that grew without a limit: on 2026-09-06 it
  reached 1586 lines, five minutes behind the band. }

unit tSpotQueue;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uRbnSpotQueue;

type
  TSpotQueueTest = class(TTestCase)
  private
    Q : TRbnSpotQueue;
  protected
    procedure TearDown; override;
  published
    procedure PopOnEmptyQueueReturnsFalse;
    procedure LinesComeOutInTheOrderTheyWentIn;
    procedure FullQueueDropsTheOldestLine;
    procedure DroppedCountsEveryLostLine;
    procedure CountNeverExceedsCapacity;
    procedure ClearEmptiesTheQueueAndKeepsTheDropCounter;
    procedure OrderSurvivesWrapAround;
    procedure ProducerAndConsumerThreadsLoseNothingBelowCapacity;
  end;

implementation

type
  TProducer = class(TThread)
  public
    Q : TRbnSpotQueue;
    N : Integer;
    procedure Execute; override;
  end;

procedure TProducer.Execute;
var
  i : Integer;
begin
  for i := 1 to N do
    Q.Push(IntToStr(i))
end;

procedure TSpotQueueTest.TearDown;
begin
  FreeAndNil(Q)
end;

procedure TSpotQueueTest.PopOnEmptyQueueReturnsFalse;
var
  s : String;
begin
  Q := TRbnSpotQueue.Create(4);
  AssertFalse(Q.Pop(s));
  AssertEquals('', s)
end;

procedure TSpotQueueTest.LinesComeOutInTheOrderTheyWentIn;
var
  s : String;
begin
  Q := TRbnSpotQueue.Create(4);
  Q.Push('a'); Q.Push('b'); Q.Push('c');
  AssertTrue(Q.Pop(s)); AssertEquals('a', s);
  AssertTrue(Q.Pop(s)); AssertEquals('b', s);
  AssertTrue(Q.Pop(s)); AssertEquals('c', s);
  AssertFalse(Q.Pop(s))
end;

procedure TSpotQueueTest.FullQueueDropsTheOldestLine;
var
  s : String;
begin
  //a spot that has waited the longest is worth the least on a live display
  Q := TRbnSpotQueue.Create(3);
  Q.Push('1'); Q.Push('2'); Q.Push('3'); Q.Push('4');
  AssertTrue(Q.Pop(s)); AssertEquals('2', s);
  AssertTrue(Q.Pop(s)); AssertEquals('3', s);
  AssertTrue(Q.Pop(s)); AssertEquals('4', s)
end;

procedure TSpotQueueTest.DroppedCountsEveryLostLine;
var
  i : Integer;
begin
  Q := TRbnSpotQueue.Create(3);
  AssertEquals(0, Q.Dropped);
  for i := 1 to 10 do
    Q.Push(IntToStr(i));
  AssertEquals(7, Q.Dropped)
end;

procedure TSpotQueueTest.CountNeverExceedsCapacity;
var
  i : Integer;
begin
  Q := TRbnSpotQueue.Create(5);
  for i := 1 to 100 do
  begin
    Q.Push('x');
    AssertTrue(Q.Count <= 5)
  end;
  AssertEquals(5, Q.Count)
end;

procedure TSpotQueueTest.ClearEmptiesTheQueueAndKeepsTheDropCounter;
var
  s : String;
begin
  Q := TRbnSpotQueue.Create(2);
  Q.Push('1'); Q.Push('2'); Q.Push('3');
  Q.Clear;
  AssertEquals(0, Q.Count);
  AssertFalse(Q.Pop(s));
  AssertEquals('Clear is not a loss', 1, Q.Dropped)
end;

procedure TSpotQueueTest.OrderSurvivesWrapAround;
var
  s    : String;
  i, n : Integer;
begin
  Q := TRbnSpotQueue.Create(3);
  n := 0;
  for i := 1 to 20 do
  begin
    Q.Push(IntToStr(i));
    if Odd(i) then
    begin
      AssertTrue(Q.Pop(s));
      AssertTrue('out of order: ' + s, StrToInt(s) > n);
      n := StrToInt(s)
    end
  end
end;

procedure TSpotQueueTest.ProducerAndConsumerThreadsLoseNothingBelowCapacity;
var
  P    : TProducer;
  s    : String;
  Got  : Integer;
  Last : Integer;
  Idle : Integer;
begin
  Q := TRbnSpotQueue.Create(20000);
  P := TProducer.Create(True);
  P.Q := Q;
  P.N := 10000;
  P.Start;
  Got := 0; Last := 0; Idle := 0;
  while (Got < 10000) and (Idle < 2000) do
    if Q.Pop(s) then
    begin
      AssertEquals(Last+1, StrToInt(s));
      Last := StrToInt(s);
      Inc(Got);
      Idle := 0
    end
    else begin
      Sleep(1);
      Inc(Idle)
    end;
  P.WaitFor;
  P.Free;
  AssertEquals(10000, Got);
  AssertEquals(0, Q.Dropped)
end;

initialization
  RegisterTest(TSpotQueueTest);
end.
