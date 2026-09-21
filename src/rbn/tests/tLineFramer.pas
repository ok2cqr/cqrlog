(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The telnet component hands over whatever bytes arrived, not lines: a spot may
  be cut anywhere, CR and LF may come in different reads, and one read may hold
  a dozen spots.  These tests pin down what the framer makes of that. }

unit tLineFramer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uRbnLineFramer;

type
  TLineFramerTest = class(TTestCase)
  private
    F : TRbnLineFramer;
    function Drain : String;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure NoLineUntilTerminatorArrives;
    procedure LineSplitAcrossTwoReadsComesOutWhole;
    procedure SeveralLinesInOneRead;
    procedure CrAndLfInDifferentReads;
    procedure BareLfTerminates;
    procedure EmptyLinesAreSkipped;
    procedure PendingShowsThePromptWithoutTerminator;
    procedure PendingIsEmptyAfterACompleteLine;
    procedure OverlongGarbageIsDroppedAndFramingRecovers;
    procedure ResetForgetsThePartialLine;
  end;

implementation

function TLineFramerTest.Drain : String;
var
  Line : String;
begin
  Result := '';
  while F.NextLine(Line) do
    Result := Result + '[' + Line + ']'
end;

procedure TLineFramerTest.SetUp;
begin
  F := TRbnLineFramer.Create
end;

procedure TLineFramerTest.TearDown;
begin
  FreeAndNil(F)
end;

procedure TLineFramerTest.NoLineUntilTerminatorArrives;
begin
  F.Feed('DX de OK1AA-#:  7016.0');
  AssertEquals('', Drain)
end;

procedure TLineFramerTest.LineSplitAcrossTwoReadsComesOutWhole;
begin
  F.Feed('DX de OK1AA-#:  7016.0');
  F.Feed('0  IZ4AA  CW'#13#10);
  AssertEquals('[DX de OK1AA-#:  7016.00  IZ4AA  CW]', Drain)
end;

procedure TLineFramerTest.SeveralLinesInOneRead;
begin
  F.Feed('one'#13#10'two'#13#10'thr');
  AssertEquals('[one][two]', Drain);
  F.Feed('ee'#13#10);
  AssertEquals('[three]', Drain)
end;

procedure TLineFramerTest.CrAndLfInDifferentReads;
begin
  F.Feed('one'#13);
  F.Feed(#10'two'#13#10);
  AssertEquals('[one][two]', Drain)
end;

procedure TLineFramerTest.BareLfTerminates;
begin
  F.Feed('one'#10'two'#10);
  AssertEquals('[one][two]', Drain)
end;

procedure TLineFramerTest.EmptyLinesAreSkipped;
begin
  F.Feed(#13#10#13#10'one'#13#10#13#10);
  AssertEquals('[one]', Drain)
end;

procedure TLineFramerTest.PendingShowsThePromptWithoutTerminator;
begin
  //the RBN relay asks for the call without ending the line
  F.Feed('Please enter your call: ');
  AssertEquals('', Drain);
  AssertEquals('Please enter your call: ', F.Pending)
end;

procedure TLineFramerTest.PendingIsEmptyAfterACompleteLine;
begin
  F.Feed('one'#13#10);
  Drain;
  AssertEquals('', F.Pending)
end;

procedure TLineFramerTest.OverlongGarbageIsDroppedAndFramingRecovers;
begin
  F.Feed(StringOfChar('x', MAX_RBN_LINE_LENGTH + 1));
  AssertEquals('buffer must not grow without a limit', '', F.Pending);
  //the rest of the garbage line goes too, the next one is fine again
  F.Feed('tail of garbage'#13#10'good'#13#10);
  AssertEquals('[good]', Drain)
end;

procedure TLineFramerTest.ResetForgetsThePartialLine;
begin
  F.Feed('half a li');
  F.Reset;
  F.Feed('new'#13#10);
  AssertEquals('[new]', Drain)
end;

initialization
  RegisterTest(TLineFramerTest);
end.
