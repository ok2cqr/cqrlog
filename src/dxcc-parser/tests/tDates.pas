(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Characterisation of prefix validity over time (legacy:
  Tseznam.znacka_sedidatum, znacmech.pas:301).

  Dates are compared as plain strings in 'YYYY/MM/DD' form, which works only
  because that format sorts chronologically.  Two sentinel values short-circuit
  the comparison entirely: '*' always matches, '!' never does. }

unit tDates;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uDxccTableIntf, uDxccTestBase;

type
  TDateTests = class(TDxccTableTestCase)
  private
    { A table with one entry whose validity window is given literally, e.g.
      '1990/01/01-1999/12/31'.  Pass '' for an entry with no dates at all. }
    function TableWithWindow(const Window: string): IDxccTable;
    function ResolvesOn(const Window, ADate: string): Boolean;
  published
    procedure StarAlwaysMatches;
    procedure BangNeverMatches;
    procedure StarMatchesEvenOutsideWindow;
    procedure BangRejectsEvenInsideWindow;

    procedure InsideWindowMatches;
    procedure BeforeWindowDoesNotMatch;
    procedure AfterWindowDoesNotMatch;
    procedure WindowStartIsInclusive;
    procedure WindowEndIsInclusive;
    procedure DayBeforeStartDoesNotMatch;
    procedure DayAfterEndDoesNotMatch;

    procedure MissingDatesUseDefaults;
    procedure MissingDatesRejectBeforeDefaultStart;
    procedure MissingDatesRejectAfterDefaultEnd;

    procedure OpenEndedStartUsesDefaultEnd;
    procedure OpenEndedEndUsesDefaultStart;

    procedure YearOnlySortsBelowFullDate;

    procedure IsValidOnAgreesWithFind;
  end;

  TLegacyDateTests = class(TDateTests)
  protected
    function NewTable(const FileName: string): IDxccTable; override;
  end;

  TModernDateTests = class(TDateTests)
  protected
    function NewTable(const FileName: string): IDxccTable; override;
  end;

implementation

uses
  uLegacyTable, uModernTable;

function TLegacyDateTests.NewTable(const FileName: string): IDxccTable;
begin
  Result := TLegacyTable.Create(FileName);
end;

function TModernDateTests.NewTable(const FileName: string): IDxccTable;
begin
  Result := TModernTable.Create(FileName);
end;

function TDateTests.TableWithWindow(const Window: string): IDxccTable;
begin
  { Same shape as the real files: nine data columns, a flag, then the validity
    window and the ADIF number after '='. }
  Result := BuildTable(['OK1|Test Land|EU|-1|50.00N|14.00E|28|15||R|' + Window + '=100']);
end;

function TDateTests.ResolvesOn(const Window, ADate: string): Boolean;
begin
  Result := TableWithWindow(Window).Find('OK1', ADate, mmPrefix) >= 0;
end;

{ --- the two sentinel dates ------------------------------------------- }

procedure TDateTests.StarAlwaysMatches;
begin
  AssertTrue(ResolvesOn('1990/01/01-1999/12/31', '*'));
end;

procedure TDateTests.BangNeverMatches;
begin
  AssertFalse(ResolvesOn('1990/01/01-1999/12/31', '!'));
end;

procedure TDateTests.StarMatchesEvenOutsideWindow;
begin
  { '*' short-circuits before the window is looked at. }
  AssertTrue(ResolvesOn('1990/01/01-1990/01/02', '*'));
end;

procedure TDateTests.BangRejectsEvenInsideWindow;
begin
  AssertFalse(ResolvesOn('1945/01/01-2050/01/01', '!'));
end;

{ --- ordinary windows -------------------------------------------------- }

procedure TDateTests.InsideWindowMatches;
begin
  AssertTrue(ResolvesOn('1990/01/01-1999/12/31', '1995/06/15'));
end;

procedure TDateTests.BeforeWindowDoesNotMatch;
begin
  AssertFalse(ResolvesOn('1990/01/01-1999/12/31', '1980/06/15'));
end;

procedure TDateTests.AfterWindowDoesNotMatch;
begin
  AssertFalse(ResolvesOn('1990/01/01-1999/12/31', '2005/06/15'));
end;

procedure TDateTests.WindowStartIsInclusive;
begin
  AssertTrue(ResolvesOn('1990/01/01-1999/12/31', '1990/01/01'));
end;

procedure TDateTests.WindowEndIsInclusive;
begin
  AssertTrue(ResolvesOn('1990/01/01-1999/12/31', '1999/12/31'));
end;

procedure TDateTests.DayBeforeStartDoesNotMatch;
begin
  AssertFalse(ResolvesOn('1990/01/02-1999/12/31', '1990/01/01'));
end;

procedure TDateTests.DayAfterEndDoesNotMatch;
begin
  AssertFalse(ResolvesOn('1990/01/01-1999/12/30', '1999/12/31'));
end;

{ --- absent dates ------------------------------------------------------ }

procedure TDateTests.MissingDatesUseDefaults;
begin
  { An entry with an empty window is valid across the whole default range. }
  AssertTrue(ResolvesOn('', '1945/01/01'));
  AssertTrue(ResolvesOn('', '2020/06/15'));
  AssertTrue(ResolvesOn('', '2050/01/01'));
end;

procedure TDateTests.MissingDatesRejectBeforeDefaultStart;
begin
  AssertFalse('the default window starts at 1945/01/01',
    ResolvesOn('', '1944/12/31'));
end;

procedure TDateTests.MissingDatesRejectAfterDefaultEnd;
begin
  AssertFalse('the default window ends at 2050/01/01',
    ResolvesOn('', '2050/01/02'));
end;

{ --- half-open windows ------------------------------------------------- }

procedure TDateTests.OpenEndedStartUsesDefaultEnd;
begin
  { 'from' only, no '-': everything after the given date, up to the default
    end.  Real data uses this shape. }
  AssertFalse(ResolvesOn('2000/06/15', '2000/06/14'));
  AssertTrue (ResolvesOn('2000/06/15', '2000/06/15'));
  AssertTrue (ResolvesOn('2000/06/15', '2049/12/31'));
  AssertFalse(ResolvesOn('2000/06/15', '2050/01/02'));
end;

procedure TDateTests.OpenEndedEndUsesDefaultStart;
begin
  { '-to': everything from the default start up to the given date.  This is
    the shape CountryDel.tab uses for deleted entities. }
  AssertTrue (ResolvesOn('-1975/07/01', '1960/01/01'));
  AssertTrue (ResolvesOn('-1975/07/01', '1975/07/01'));
  AssertFalse(ResolvesOn('-1975/07/01', '1975/07/02'));
end;

{ --- string comparison artefacts --------------------------------------- }

procedure TDateTests.YearOnlySortsBelowFullDate;
begin
  { Comparison is lexicographic, so a bare year is smaller than any date in
    that same year.  '2006' < '2006/01/01' because the shorter string runs
    out first.  Entries in the wild rely on this. }
  AssertTrue ('bare year as window start behaves as the very start of it',
    ResolvesOn('2006-2006/12/31', '2006/01/01'));
  AssertFalse('a bare year as window END excludes the whole year',
    ResolvesOn('2000/01/01-2006', '2006/01/01'));
end;

{ --- consistency ------------------------------------------------------- }

procedure TDateTests.IsValidOnAgreesWithFind;
var
  T: IDxccTable;
  Found: Integer;
begin
  T := TableWithWindow('1990/01/01-1999/12/31');
  Found := T.Find('OK1', '*', mmPrefix);
  AssertTrue('the entry should exist', Found >= 0);
  AssertTrue (T.IsValidOn(Found, '1995/06/15'));
  AssertFalse(T.IsValidOn(Found, '1980/06/15'));
  AssertFalse(T.IsValidOn(Found, '2005/06/15'));
  AssertTrue (T.IsValidOn(Found, '*'));
  AssertFalse(T.IsValidOn(Found, '!'));
end;

initialization
  RegisterTest(TLegacyDateTests);
  RegisterTest(TModernDateTests);

end.
