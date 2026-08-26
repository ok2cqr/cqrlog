(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The backward-compatibility proof.

  Runs the legacy engine and the new one side by side over a large corpus and
  asserts they agree.  This is the test the whole exercise exists for: the
  other suites say the new parser behaves sensibly, this one says it behaves
  *identically*, which is the only claim that matters when the thing being
  replaced decides what country every QSO in the log belongs to.

  What is compared is the resolved content, not the index.  An index is an
  artefact of how the table happens to be ordered; what dDXCC reads is the
  matched pattern and eight fields (dDXCC.pas:400-407), so that is what has to
  match -- plus the other four, for good measure.

  The reference input is the fImportProgress-expanded table; see
  uTestData.CanonicalTable. }

unit tDifferential;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uDxccTableIntf;

type
  TMatchModes = set of TMatchMode;

  TDifferentialTests = class(TTestCase)
  private
    FLegacy: IDxccTable;
    FModern: IDxccTable;
    FLoadedFrom: string;
    FComparisons: Int64;
    FMismatches: Integer;
    FReport: string;

    procedure Load(const TableFile: string);
    function Compare(const Callsign, ADate: string; Mode: TMatchMode): Boolean;
    { Step 1 walks the whole corpus; a larger step samples it.  Exhaustive
      mode (see Exhaustive) forces every step to 1. }
    procedure RunCorpus(Corpus: TStrings; const Dates: array of string;
      Modes: TMatchModes; Step: Integer = 1);
    procedure AssertNoMismatches(const What: string);
  protected
    procedure SetUp; override;
  published
    { Every pattern in the canonical table, reached deliberately. }
    procedure EveryPatternOnCanonicalTable;
    { A sample of the same corpus, but across every date and mode. }
    procedure DateMatrixOnCanonicalTable;
    { Every plausible short callsign shape, including ones nothing matches. }
    procedure SweptShapesOnCanonicalTable;
    { The other country.tab variant, which users who never ran the manual
      import still have. }
    procedure EveryPatternOnPlainTable;
    { Deleted entities live in their own, much smaller table. }
    procedure DeletedTable;
    { The small hand-written fixture, where the table is tiny enough that the
      index arithmetic behaves differently. }
    procedure MiniTableAgrees;
    { Shapes that should never reach the parser but sometimes do. }
    procedure EdgeCasesAgree;
  end;

implementation

uses
  uLegacyTable, uModernTable, uTestData, uCorpus;

const
  AllModes: TMatchModes = [mmPrefix, mmExact, mmExactNoEquals];

  { Spread across the range the tables describe: the two sentinels, a date
    before the default window opens, the early post-war period, the eras most
    deleted entities straddle, today, and a date past the default close. }
  MatrixDates: array[0..7] of string =
    ('*', '!', '1944/12/31', '1960/01/01', '1995/06/15', '2010/01/01',
     '2026/08/19', '2050/01/02');

  { The single date and mode that dominate real use: dDXCC resolves a QSO at
    its own date in prefix mode. }
  CommonDate: array[0..0] of string = ('2020/01/01');

  { How many mismatches get described before the report stops growing.  The
    count keeps accumulating either way, so the summary line stays honest. }
  MaxReported = 10;

  { The full corpus is around 100000 callsigns and the full matrix multiplies
    that by 24, which is some tens of millions of lookups across two engines --
    minutes, not seconds.  So the default run walks the whole corpus at the
    common date and mode, and samples it across the full matrix.  Set
    DXCC_DIFF_FULL=1 to force every sweep to be exhaustive; `make test-full`
    does that. }
  MatrixSampleStep = 17;

function Exhaustive: Boolean;
begin
  Result := GetEnvironmentVariable('DXCC_DIFF_FULL') = '1';
end;

procedure TDifferentialTests.SetUp;
begin
  inherited SetUp;
  FComparisons := 0;
  FMismatches := 0;
  FReport := '';
end;

procedure TDifferentialTests.Load(const TableFile: string);
begin
  if FLoadedFrom = TableFile then
    Exit;
  FLegacy := TLegacyTable.Create(TableFile);
  FModern := TModernTable.Create(TableFile);
  FLoadedFrom := TableFile;
  AssertEquals('the two engines must read the same number of marks from ' +
    ExtractFileName(TableFile), FLegacy.Count, FModern.Count);
end;

function TDifferentialTests.Compare(const Callsign, ADate: string;
  Mode: TMatchMode): Boolean;
var
  L, M, F: Integer;
  LegacyText, ModernText, ModeName: string;
begin
  Inc(FComparisons);
  L := FLegacy.Find(Callsign, ADate, Mode);
  M := FModern.Find(Callsign, ADate, Mode);

  if (L < 0) and (M < 0) then
    Exit(True);

  if (L < 0) or (M < 0) then
  begin
    LegacyText := '<no match>';
    ModernText := '<no match>';
    if L >= 0 then LegacyText := FLegacy.Pattern(L);
    if M >= 0 then ModernText := FModern.Pattern(M);
  end
  else
  begin
    { Compare what the callers actually read. }
    LegacyText := FLegacy.Pattern(L);
    ModernText := FModern.Pattern(M);
    for F := fldFirst to fldLast do
    begin
      LegacyText := LegacyText + '|' + FLegacy.Field(L, F);
      ModernText := ModernText + '|' + FModern.Field(M, F);
    end;
  end;

  Result := LegacyText = ModernText;
  if not Result then
  begin
    Inc(FMismatches);
    if FMismatches <= MaxReported then
    begin
      WriteStr(ModeName, Mode);
      FReport := FReport + LineEnding +
        Format('  call=%s date=%s mode=%s' + LineEnding +
               '    legacy: %s' + LineEnding +
               '    modern: %s',
               [Callsign, ADate, ModeName, LegacyText, ModernText]);
    end;
  end;
end;

procedure TDifferentialTests.RunCorpus(Corpus: TStrings;
  const Dates: array of string; Modes: TMatchModes; Step: Integer = 1);
var
  I, D: Integer;
  Mode: TMatchMode;
begin
  if Exhaustive then
    Step := 1;
  if Step < 1 then
    Step := 1;
  { Announce sampling on stdout rather than only in a failure message: a
    partial sweep that looks like a full one is how a regression slips
    through. }
  if Step > 1 then
    WriteLn(Format('    [differential] sampling every %dth of %d callsigns; '
      + 'set DXCC_DIFF_FULL=1 for all', [Step, Corpus.Count]));
  I := 0;
  while I < Corpus.Count do
  begin
    for D := Low(Dates) to High(Dates) do
      for Mode := Low(TMatchMode) to High(TMatchMode) do
        if Mode in Modes then
          Compare(Corpus[I], Dates[D], Mode);
    Inc(I, Step);
  end;
end;

procedure TDifferentialTests.AssertNoMismatches(const What: string);
begin
  AssertTrue(What + ': the corpus was empty, so nothing was compared',
    FComparisons > 0);
  AssertTrue(Format('%s: %d of %d lookups disagree%s',
    [What, FMismatches, FComparisons, FReport]), FMismatches = 0);
end;

procedure TDifferentialTests.EveryPatternOnCanonicalTable;
var
  Corpus: TStringList;
begin
  Load(CanonicalTable);
  Corpus := DerivedCallsigns(FLegacy);
  try
    AssertTrue('the derived corpus should cover the whole table',
      Corpus.Count > FLegacy.Count div 2);
    { The whole corpus, at the date and mode that dominate real use. }
    RunCorpus(Corpus, CommonDate, AllModes);
    AssertNoMismatches(Format('%d callsigns derived from %d patterns',
      [Corpus.Count, FLegacy.Count]));
  finally
    Corpus.Free;
  end;
end;

procedure TDifferentialTests.DateMatrixOnCanonicalTable;
var
  Corpus: TStringList;
begin
  Load(CanonicalTable);
  Corpus := DerivedCallsigns(FLegacy);
  try
    RunCorpus(Corpus, MatrixDates, AllModes, MatrixSampleStep);
    AssertNoMismatches('date/mode matrix over the derived corpus');
  finally
    Corpus.Free;
  end;
end;

procedure TDifferentialTests.SweptShapesOnCanonicalTable;
var
  Corpus: TStringList;
begin
  Load(CanonicalTable);
  Corpus := SweptCallsigns;
  try
    { Small enough to take the full matrix without sampling. }
    RunCorpus(Corpus, MatrixDates, AllModes);
    AssertNoMismatches(Format('%d swept callsign shapes', [Corpus.Count]));
  finally
    Corpus.Free;
  end;
end;

procedure TDifferentialTests.EveryPatternOnPlainTable;
var
  Corpus: TStringList;
begin
  { Users who never ran Import DXCC data are on this variant, so it has to
    agree too. }
  Load(PlainTable);
  Corpus := DerivedCallsigns(FLegacy);
  try
    RunCorpus(Corpus, CommonDate, AllModes);
    AssertNoMismatches('un-expanded country.tab');
  finally
    Corpus.Free;
  end;
end;

procedure TDifferentialTests.DeletedTable;
var
  Corpus: TStringList;
begin
  Load(uTestData.DeletedTable);
  Corpus := DerivedCallsigns(FLegacy);
  try
    RunCorpus(Corpus, MatrixDates, AllModes);
    AssertNoMismatches('deleted-entity table');
  finally
    Corpus.Free;
  end;
end;

procedure TDifferentialTests.MiniTableAgrees;
var
  Corpus: TStringList;
begin
  Load(MiniTable);
  Corpus := DerivedCallsigns(FLegacy);
  try
    RunCorpus(Corpus, MatrixDates, AllModes);
    AssertNoMismatches('mini.tab fixture');
  finally
    Corpus.Free;
  end;
end;

procedure TDifferentialTests.EdgeCasesAgree;
var
  Corpus: TStringList;
begin
  Load(CanonicalTable);
  Corpus := EdgeCaseCallsigns;
  try
    RunCorpus(Corpus, MatrixDates, AllModes);
    AssertNoMismatches('edge-case callsigns');
  finally
    Corpus.Free;
  end;
end;

initialization
  RegisterTest(TDifferentialTests);

end.
