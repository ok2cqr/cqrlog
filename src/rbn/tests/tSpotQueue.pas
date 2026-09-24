(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The queue between the socket (main thread) and the worker that filters spots,
  carrying each line with the spot parsed from it.
  It used to be a TStringList that grew without a limit: on 2026-09-06 it
  reached 1586 lines, five minutes behind the band. }

unit tSpotQueue;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uRbnSpotParser, uRbnSpotQueue;

type
  TSpotQueueTest = class(TTestCase)
  private
    Q : TRbnSpotQueue;
    procedure PushLine(const Line : String);
    function  PopLine(out Line : String) : Boolean;
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
    procedure TheParsedSpotTravelsWithItsLine;
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
    Q.Push(IntToStr(i), Default(TRbnSpotLine))
end;

procedure TSpotQueueTest.PushLine(const Line : String);
begin
  Q.Push(Line, Default(TRbnSpotLine))
end;

function TSpotQueueTest.PopLine(out Line : String) : Boolean;
var
  Spot : TRbnSpotLine;
begin
  Result := Q.Pop(Line, Spot)
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
  AssertFalse(PopLine(s));
  AssertEquals('', s)
end;

procedure TSpotQueueTest.LinesComeOutInTheOrderTheyWentIn;
var
  s : String;
begin
  Q := TRbnSpotQueue.Create(4);
  PushLine('a'); PushLine('b'); PushLine('c');
  AssertTrue(PopLine(s)); AssertEquals('a', s);
  AssertTrue(PopLine(s)); AssertEquals('b', s);
  AssertTrue(PopLine(s)); AssertEquals('c', s);
  AssertFalse(PopLine(s))
end;

procedure TSpotQueueTest.FullQueueDropsTheOldestLine;
var
  s : String;
begin
  //a spot that has waited the longest is worth the least on a live display
  Q := TRbnSpotQueue.Create(3);
  PushLine('1'); PushLine('2'); PushLine('3'); PushLine('4');
  AssertTrue(PopLine(s)); AssertEquals('2', s);
  AssertTrue(PopLine(s)); AssertEquals('3', s);
  AssertTrue(PopLine(s)); AssertEquals('4', s)
end;

procedure TSpotQueueTest.DroppedCountsEveryLostLine;
var
  i : Integer;
begin
  Q := TRbnSpotQueue.Create(3);
  AssertEquals(0, Q.Dropped);
  for i := 1 to 10 do
    PushLine(IntToStr(i));
  AssertEquals(7, Q.Dropped)
end;

procedure TSpotQueueTest.CountNeverExceedsCapacity;
var
  i : Integer;
begin
  Q := TRbnSpotQueue.Create(5);
  for i := 1 to 100 do
  begin
    PushLine('x');
    AssertTrue(Q.Count <= 5)
  end;
  AssertEquals(5, Q.Count)
end;

procedure TSpotQueueTest.ClearEmptiesTheQueueAndKeepsTheDropCounter;
var
  s : String;
begin
  Q := TRbnSpotQueue.Create(2);
  PushLine('1'); PushLine('2'); PushLine('3');
  Q.Clear;
  AssertEquals(0, Q.Count);
  AssertFalse(PopLine(s));
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
    PushLine(IntToStr(i));
    if Odd(i) then
    begin
      AssertTrue(PopLine(s));
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
    if PopLine(s) then
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

procedure TSpotQueueTest.TheParsedSpotTravelsWithItsLine;
var
  In_, Out_ : TRbnSpotLine;
  Line      : String;
begin
  //the connection parses every line once; the worker must not parse it again
  Q := TRbnSpotQueue.Create(4);
  In_ := Default(TRbnSpotLine);
  In_.Dx := 'OK1AA';
  In_.FreqKHz := 14025.1;
  Q.Push('DX de W3LPL-#: 14025.1 OK1AA', In_);
  AssertTrue(Q.Pop(Line, Out_));
  AssertEquals('DX de W3LPL-#: 14025.1 OK1AA', Line);
  AssertEquals('OK1AA', Out_.Dx);
  AssertEquals(14025.1, Out_.FreqKHz, 0.0001)
end;

initialization
  RegisterTest(TSpotQueueTest);
end.
