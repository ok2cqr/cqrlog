(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Base class for tests that must run against BOTH engines.

  Descendants override NewTable to say which implementation they exercise, so
  the published test methods are written once and inherited by a legacy and a
  modern concrete class.  fpcunit picks up inherited published methods, so
  registering the descendant runs the whole inherited suite against it. }

unit uDxccTestBase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, uDxccTableIntf;

type
  TDxccTableTestCase = class(TTestCase)
  protected
    { The one thing descendants must supply. }
    function NewTable(const FileName: string): IDxccTable; virtual; abstract;

    { Builds a throwaway table from literal lines.  The engines load from a
      file, so this writes one, loads it, and removes it again.

      A sentinel entry is appended -- see SentinelMark below. }
    function BuildTable(const Lines: array of string): IDxccTable;

    { Convenience: a table holding exactly one entry with the given mark(s).
      The description is fixed so tests only have to think about the pattern. }
    function SinglePattern(const Marks: string): IDxccTable;

    { True when Callsign resolves to something in a single-pattern table. }
    function Matches(const Marks, Callsign: string): Boolean;
    function MatchesMode(const Marks, Callsign: string; Mode: TMatchMode): Boolean;

    procedure AssertMatches(const Marks, Callsign: string);
    procedure AssertNoMatch(const Marks, Callsign: string);
  end;

const
  { A complete, valid description line -- everything after the marks. }
  StockDescription = '|Test Land|EU|-1|50.00N|14.00E|28|15||R|=100';

  { Every table built here gets this extra entry appended.

    Tseznam.znacka_najdikam_s (znacmech.pas:529) can leave its search index one
    past the last entry when the probe key sorts above everything in the table;
    znacky is a zero-filled fixed array, so the next dereference hits nil and
    the process dies.  najdis_s2 probes with first-char + '[', and '[' outranks
    every alphanumeric in odbec's collation, so ANY table whose marks are all
    alphanumeric triggers this -- which is every hand-written fixture.

    The real tables escape it only because they contain '%'-leading marks that
    sort above the probe key (see tRobustness).  '~' outranks every
    alphanumeric too, so this sentinel reproduces that protection.  It is a
    plain literal, so it never matches a test callsign.

    The new implementation must not need this crutch; tModern asserts that
    directly. }
  SentinelMark = '~~~~';

implementation

uses
  uTestData;

function TDxccTableTestCase.BuildTable(const Lines: array of string): IDxccTable;
var
  L: TStringList;
  FileName: string;
  I: Integer;
begin
  FileName := GetTempDir(False) + 'dxcctest-' + IntToStr(GetProcessID) + '-' +
              IntToStr(Random(1000000)) + '.tab';
  L := TStringList.Create;
  try
    for I := Low(Lines) to High(Lines) do
      L.Add(Lines[I]);
    L.Add(SentinelMark + StockDescription);
    L.SaveToFile(FileName);
  finally
    L.Free;
  end;
  try
    Result := NewTable(FileName);
  finally
    DeleteFile(FileName);
  end;
end;

function TDxccTableTestCase.SinglePattern(const Marks: string): IDxccTable;
begin
  Result := BuildTable([Marks + StockDescription]);
end;

function TDxccTableTestCase.MatchesMode(const Marks, Callsign: string;
  Mode: TMatchMode): Boolean;
begin
  Result := SinglePattern(Marks).Find(Callsign, '*', Mode) >= 0;
end;

function TDxccTableTestCase.Matches(const Marks, Callsign: string): Boolean;
begin
  Result := MatchesMode(Marks, Callsign, mmPrefix);
end;

procedure TDxccTableTestCase.AssertMatches(const Marks, Callsign: string);
begin
  AssertTrue(Format('pattern %s should match %s', [Marks, Callsign]),
    Matches(Marks, Callsign));
end;

procedure TDxccTableTestCase.AssertNoMatch(const Marks, Callsign: string);
begin
  AssertFalse(Format('pattern %s should not match %s', [Marks, Callsign]),
    Matches(Marks, Callsign));
end;

end.
