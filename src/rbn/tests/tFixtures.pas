(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Framer and parser together over real traffic (tests/data, recorded with
  tools/rbn-capture, callsign suffixes scrambled). }

unit tFixtures;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uRbnLineFramer, uRbnSpotParser, uRbnFixture;

type
  TFixtureTest = class(TTestCase)
  private
    function LinesOf(const Name : String) : TStringList;
  published
    procedure RecutReadsGiveTheSameLinesAsTheOriginal;
    procedure EveryDxDeLineOfTheBurstParses;
    procedure FirstReadLeavesTheLoginPromptPending;
    procedure RecordedVhfSpotParses;
  end;

implementation

function TFixtureTest.LinesOf(const Name : String) : TStringList;
var
  Reads : TStringList;
  F     : TRbnLineFramer;
  i     : Integer;
  Line  : String;
begin
  Result := TStringList.Create;
  Reads := LoadReads(Name);
  F := TRbnLineFramer.Create;
  try
    for i := 0 to Reads.Count-1 do
    begin
      F.Feed(Reads[i]);
      while F.NextLine(Line) do
        Result.Add(Line)
    end
  finally
    F.Free;
    Reads.Free
  end
end;

procedure TFixtureTest.RecutReadsGiveTheSameLinesAsTheOriginal;
var
  A, B : TStringList;
begin
  //the same bytes cut at 1..120 byte steps: inside callsigns, inside CRLF
  A := LinesOf('login-and-first-spots.jsonl');
  B := LinesOf('login-and-first-spots-recut.jsonl');
  try
    AssertTrue('fixture is empty', A.Count > 50);
    AssertEquals(A.Text, B.Text)
  finally
    A.Free;
    B.Free
  end
end;

procedure TFixtureTest.EveryDxDeLineOfTheBurstParses;
var
  L : TStringList;
  S : TRbnSpotLine;
  i, n : Integer;
begin
  L := LinesOf('burst-10s.jsonl');
  try
    n := 0;
    for i := 0 to L.Count-1 do
      if Pos('DX de ', L[i]) = 1 then
      begin
        AssertTrue('not parsed: ' + L[i], ParseRbnSpot(L[i], S));
        Inc(n)
      end;
    AssertTrue('burst should hold more than 100 spots, got ' + IntToStr(n), n > 100)
  finally
    L.Free
  end
end;

procedure TFixtureTest.FirstReadLeavesTheLoginPromptPending;
var
  Reads : TStringList;
  F     : TRbnLineFramer;
  Line  : String;
begin
  Reads := LoadReads('login-and-first-spots.jsonl');
  F := TRbnLineFramer.Create;
  try
    F.Feed(Reads[0]);
    AssertFalse(F.NextLine(Line));
    AssertEquals('Please enter your call: ', F.Pending)
  finally
    F.Free;
    Reads.Free
  end
end;

procedure TFixtureTest.RecordedVhfSpotParses;
var
  L : TStringList;
  S : TRbnSpotLine;
begin
  L := LinesOf('vhf-no-space-after-colon.jsonl');
  try
    AssertEquals(1, L.Count);
    AssertTrue(ParseRbnSpot(L[0], S));
    AssertEquals(144433.5, S.FreqKHz, 0.001)
  finally
    L.Free
  end
end;

initialization
  RegisterTest(TFixtureTest);
end.
