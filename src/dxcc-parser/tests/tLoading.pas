(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ How the table file is turned into entries: mark splitting, trimming,
  truncation, and the difference between the two country.tab variants CQRLOG
  builds. }

unit tLoading;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uDxccTableIntf, uDxccTestBase;

type
  TLoadingTests = class(TDxccTableTestCase)
  private
    function PatternFor(Table: IDxccTable; const Callsign: string): string;
  published
    procedure SeveralMarksOnOneLineBecomeSeveralEntries;
    procedure MarksOnOneLineShareTheDescription;
    procedure LeadingAndTrailingSpacesAreTrimmed;
    procedure RunsOfSpacesDoNotCreateEmptyEntries;
    procedure OverlongMarkIsTruncated;
    procedure MissingFileYieldsAnEmptyTable;
    procedure EmptyFileYieldsAnEmptyTable;
    procedure LineWithoutDescriptionIsIgnored;
    procedure CarriageReturnsAreStripped;

    procedure PlainAndExpandedDifferOnGuestOperatorCalls;
    procedure ExpandedTableResolvesLeadingPercentPattern;
  end;

  TLegacyLoadingTests = class(TLoadingTests)
  protected
    function NewTable(const FileName: string): IDxccTable; override;
  end;

  TModernLoadingTests = class(TLoadingTests)
  protected
    function NewTable(const FileName: string): IDxccTable; override;
  end;

implementation

uses
  uLegacyTable, uModernTable, uTestData, uDxccLimits;

function TLegacyLoadingTests.NewTable(const FileName: string): IDxccTable;
begin
  Result := TLegacyTable.Create(FileName);
end;

function TModernLoadingTests.NewTable(const FileName: string): IDxccTable;
begin
  Result := TModernTable.Create(FileName);
end;

function TLoadingTests.PatternFor(Table: IDxccTable; const Callsign: string): string;
var
  Found: Integer;
begin
  Found := Table.Find(Callsign, '2020/01/01', mmPrefix);
  if Found < 0 then
    Result := '<none>'
  else
    Result := Table.Pattern(Found);
end;

procedure TLoadingTests.SeveralMarksOnOneLineBecomeSeveralEntries;
var
  T: IDxccTable;
begin
  T := BuildTable(['AA AB AC' + StockDescription]);
  { three marks, plus the sentinel BuildTable appends }
  AssertEquals(4, T.Count);
  AssertTrue(T.Find('AA', '*', mmPrefix) >= 0);
  AssertTrue(T.Find('AB', '*', mmPrefix) >= 0);
  AssertTrue(T.Find('AC', '*', mmPrefix) >= 0);
end;

procedure TLoadingTests.MarksOnOneLineShareTheDescription;
var
  T: IDxccTable;
  A, B: Integer;
begin
  T := BuildTable(['AA AB|Shared Land|EU|-1|50.00N|14.00E|28|15||R|=100']);
  A := T.Find('AA', '*', mmPrefix);
  B := T.Find('AB', '*', mmPrefix);
  AssertTrue(A >= 0);
  AssertTrue(B >= 0);
  AssertEquals('Shared Land', T.Field(A, fldCountry));
  AssertEquals('Shared Land', T.Field(B, fldCountry));
  AssertEquals(T.Field(A, fldAdif), T.Field(B, fldAdif));
end;

procedure TLoadingTests.LeadingAndTrailingSpacesAreTrimmed;
var
  T: IDxccTable;
  Found: Integer;
begin
  T := BuildTable(['  AA  ' + StockDescription]);
  Found := T.Find('AA', '*', mmPrefix);
  AssertTrue('the trimmed mark should resolve', Found >= 0);
  AssertEquals('AA', T.Pattern(Found));
end;

procedure TLoadingTests.RunsOfSpacesDoNotCreateEmptyEntries;
var
  T: IDxccTable;
begin
  T := BuildTable(['AA   AB' + StockDescription]);
  AssertEquals('two marks plus the sentinel', 3, T.Count);
end;

procedure TLoadingTests.OverlongMarkIsTruncated;
var
  T: IDxccTable;
  Long, Truncated: string;
  Found: Integer;
begin
  { The current CallResolution.tbl really does contain a 42-character token,
    so this path is live. }
  Long      := StringOfChar('Q', MaxMarkLength + 5);
  Truncated := StringOfChar('Q', MaxMarkLength);
  T := BuildTable([Long + StockDescription]);
  Found := T.Find(Truncated, '*', mmPrefix);
  AssertTrue('the truncated mark should resolve', Found >= 0);
  AssertEquals('the stored mark is cut to the limit',
    MaxMarkLength, Length(T.Pattern(Found)));
end;

procedure TLoadingTests.MissingFileYieldsAnEmptyTable;
var
  T: IDxccTable;
begin
  { The legacy constructor reports E01 and marks itself dead rather than
    raising, so callers see an empty table. }
  T := NewTable(DataDir + 'definitely-not-here.tab');
  AssertEquals(0, T.Count);
  AssertEquals(-1, T.Find('OK1ABC', '*', mmPrefix));
end;

procedure TLoadingTests.EmptyFileYieldsAnEmptyTable;
var
  FileName: string;
  T: IDxccTable;
  L: TStringList;
begin
  FileName := GetTempDir(False) + 'dxcctest-empty.tab';
  L := TStringList.Create;
  try
    L.SaveToFile(FileName);
  finally
    L.Free;
  end;
  try
    T := NewTable(FileName);
    AssertEquals(0, T.Count);
  finally
    DeleteFile(FileName);
  end;
end;

procedure TLoadingTests.LineWithoutDescriptionIsIgnored;
var
  T: IDxccTable;
begin
  { No '|' means nothing to describe, so the marks are dropped. }
  T := BuildTable(['JUNKLINE', 'AA' + StockDescription]);
  AssertEquals('only the real mark and the sentinel survive', 2, T.Count);
  AssertEquals(-1, T.Find('JUNKLINE', '*', mmExact));
end;

procedure TLoadingTests.CarriageReturnsAreStripped;
var
  FileName: string;
  T: IDxccTable;
  F: TextFile;
  Found: Integer;
begin
  { CountryDel.tab ships with CRLF endings; the loader drops every byte below
    32, so the CR never reaches a field. }
  FileName := GetTempDir(False) + 'dxcctest-crlf.tab';
  AssignFile(F, FileName);
  Rewrite(F);
  Write(F, 'AA' + StockDescription + #13#10);
  Write(F, SentinelMark + StockDescription + #13#10);
  CloseFile(F);
  try
    T := NewTable(FileName);
    Found := T.Find('AA', '*', mmPrefix);
    AssertTrue('the mark should resolve', Found >= 0);
    AssertEquals('100', T.Field(Found, fldAdif));
  finally
    DeleteFile(FileName);
  end;
end;

{ --- the two country.tab variants -------------------------------------- }

procedure TLoadingTests.PlainAndExpandedDifferOnGuestOperatorCalls;
var
  Plain, Expanded: IDxccTable;
  Call, P, E: string;
begin
  { Every '%'-leading line in the data is a guest-operator pattern of the
    shape %%%%/B[A-LRSTYZ]0[A-F]%.  In country-plain.tab those sort under '%',
    above every alphanumeric, so no scan keyed on the callsign's first
    character can reach them.  fImportProgress expands them; PrepareDXCCData
    does not.  Same callsign, two different answers. }
  Call     := 'OK1A/BA0AX';
  Plain    := NewTable(PlainTable);
  Expanded := NewTable(ExpandedTable);
  P := PatternFor(Plain, Call);
  E := PatternFor(Expanded, Call);
  AssertTrue(Format(
    'the two country.tab variants should resolve %s differently, ' +
    'but both gave %s', [Call, P]), P <> E);
end;

procedure TLoadingTests.ExpandedTableResolvesLeadingPercentPattern;
var
  Expanded: IDxccTable;
  Found: Integer;
begin
  Expanded := NewTable(ExpandedTable);
  Found := Expanded.Find('OK1A/BA0AX', '2020/01/01', mmPrefix);
  AssertTrue('the expanded copy should be reachable', Found >= 0);
  AssertEquals('China, Xin Jiang (Urumqi City), Guest Operators',
    Expanded.Field(Found, fldCountry));
end;

initialization
  RegisterTest(TLegacyLoadingTests);
  RegisterTest(TModernLoadingTests);

end.
