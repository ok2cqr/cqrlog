(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Runs both DXCC engines over a real log and reports where they disagree.

  tDifferential already compares the two table engines over a corpus derived
  from the tables' own patterns.  That corpus is exhaustive about the data but
  blind about traffic: it only contains shapes the tables describe, and it
  stops at the table layer.  A real log contains callsigns nothing in
  ctyfiles/ anticipated -- 4O8/9X0A/P, S5FF-0168, 03UA, OE/OK2PYA/P -- and it
  exercises the callsign-splitting layer, which is where the interesting
  disagreements would live.

  What is compared is the whole path dDXCC.id_country (dDXCC.pas:688) takes:

    key := CoVyhodnocovat(callsign, date, UzNasel, ADIF)   -- both discarded
    look up key in country_del.tab, then in country.tab, NotExactly
    read country / continent / utc / lat / long / itu / waz / adif

  The old side is the legacy Tseznam plus the CoVyhodnocovat transcription in
  tests/uLegacySplitter; the new side is TDxccTable plus TDxccResolver.

  Not compared, because neither is in this layer: DXCCRefArray[adif].pref,
  which comes from MySQL, and the US-state override at dDXCC.pas:727, which
  the new parser does not have yet and which needs a state column the input
  does not carry.

  A log only covers the dates its owner was on the air, which says nothing
  about the rest of the date axis -- and the tables carry 2277 distinct
  validity boundaries reaching back to 1939, most of them before any given
  log starts.  --dates boundaries therefore replays the log's callsigns at
  every boundary in the tables, and at the day either side of each, which is
  where date arithmetic goes wrong if it is going to.

  Input is CSV with a header and two columns, qsodate and callsign, as
  exported from cqrlog_main.  Usage:  tools/logdiff --help }

program logdiff;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  uDxccTableIntf, uDxccTable, uDxccEntry, uDxccResolver, uDxccSuffixRules,
  uLegacyTable, uLegacySplitter, uTestData;

type
  { What one engine made of one (callsign, date) pair. }
  TEvaluation = record
    Key: string;        { the effective callsign the splitter produced }
    Found: Boolean;
    Deleted: Boolean;   { matched in country_del.tab rather than country.tab }
    Pattern: string;
    Adif: Integer;      { after id_country's "> 0 or nothing" rule }
    Fields: string;     { country|cont|utc|lat|long|itu|waz, for comparison }
    Country: string;
  end;

  { How the two evaluations differed.  Ordered by how much it matters. }
  TDiffClass = (dcSame, dcPattern, dcKey, dcFields, dcDxcc);

const
  DiffClassName: array[TDiffClass] of string =
    ('same', 'pattern', 'key', 'fields', 'dxcc');

{ ------------------------------------------------------------------ groups }

type
  { One line of a grouped report: a label, how many rows carried it, and a few
    example callsigns. }
  TGroup = class
    Key: string;
    Count: Integer;
    Samples: TStringList;
    constructor Create(const AKey: string);
    destructor Destroy; override;
  end;

  TGroupList = class
  private
    FItems: TStringList;   { sorted; Objects are TGroup }
    FMaxSamples: Integer;
  public
    constructor Create(AMaxSamples: Integer);
    destructor Destroy; override;
    procedure Add(const AKey, ASample: string);
    { Groups by descending count, then by label. }
    function Ranked: TFPList;
    function Count: Integer;
  end;

constructor TGroup.Create(const AKey: string);
begin
  inherited Create;
  Key := AKey;
  Count := 0;
  Samples := TStringList.Create;
end;

destructor TGroup.Destroy;
begin
  Samples.Free;
  inherited Destroy;
end;

constructor TGroupList.Create(AMaxSamples: Integer);
begin
  inherited Create;
  FMaxSamples := AMaxSamples;
  FItems := TStringList.Create;
  FItems.Sorted := True;
  FItems.Duplicates := dupError;
  FItems.OwnsObjects := True;
end;

destructor TGroupList.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TGroupList.Add(const AKey, ASample: string);
var
  Index: Integer;
  Group: TGroup;
begin
  Index := FItems.IndexOf(AKey);
  if Index < 0 then
  begin
    Group := TGroup.Create(AKey);
    FItems.AddObject(AKey, Group);
  end
  else
    Group := TGroup(FItems.Objects[Index]);

  Inc(Group.Count);
  if (ASample <> '') and (Group.Samples.Count < FMaxSamples) and
     (Group.Samples.IndexOf(ASample) < 0) then
    Group.Samples.Add(ASample);
end;

function TGroupList.Count: Integer;
begin
  Result := FItems.Count;
end;

function TGroupList.Ranked: TFPList;
var
  I, J: Integer;
  A, B: TGroup;
begin
  Result := TFPList.Create;
  for I := 0 to FItems.Count - 1 do
    Result.Add(FItems.Objects[I]);

  { Insertion sort: these lists are report-sized, not data-sized. }
  for I := 1 to Result.Count - 1 do
  begin
    A := TGroup(Result[I]);
    J := I - 1;
    while J >= 0 do
    begin
      B := TGroup(Result[J]);
      if (B.Count > A.Count) or ((B.Count = A.Count) and (B.Key <= A.Key)) then
        Break;
      Result[J + 1] := Result[J];
      Dec(J);
    end;
    Result[J + 1] := A;
  end;
end;

{ ------------------------------------------------------------------- state }

var
  { --- options --- }
  OptCsv: string = '';
  OptTables: string = '';
  OptVariant: string = 'expanded';
  OptOut: string = '';
  OptSamples: Integer = 5;
  OptLimit: Integer = 0;
  OptShowKeys: Boolean = False;
  OptDates: string = 'log';
  OptCallStep: Integer = 1;
  OptExplain: Boolean = False;
  OptCall: string = '';
  OptCallDate: string = '';

  { --- engines --- }
  Rules: TDxccSuffixRules = nil;
  LegacyValid, LegacyDeleted: IDxccTable;
  LegacySplitter: TLegacySplitter = nil;
  ModernValid, ModernDeleted: TDxccTable;
  Resolver: TDxccResolver = nil;

  { --- resolved file names --- }
  ValidFile, DeletedFile, ExceptionsFile, AmbiguousFile: string;

  { --- counters --- }
  Rows: Int64 = 0;
  Skipped: Int64 = 0;
  Normalised: Int64 = 0;
  SweptCalls: Integer = 0;
  SweptDates: Integer = 0;
  { The log as read: one entry per row, plus the distinct callsigns. }
  LogDates: TStringList = nil;
  LogCalls: TStringList = nil;
  DistinctCalls: TStringList = nil;
  ClassCounts: array[TDiffClass] of Int64;
  MaritimeCount: Int64 = 0;

  { --- reports --- }
  DxccGroups, FieldGroups, KeyGroups, PatternGroups, UnresolvedGroups: TGroupList;
  OutFile: TextFile;
  OutOpen: Boolean = False;

{ ------------------------------------------------------------------ helpers }

procedure Fail(const Message: string);
begin
  WriteLn(StdErr, 'logdiff: ', Message);
  Halt(2);
end;

procedure Usage;
begin
  WriteLn('logdiff -- compares the legacy and the new DXCC engine over a real log');
  WriteLn;
  WriteLn('  --csv <file>          QSO export: header, then qsodate,callsign');
  WriteLn('  --call <callsign>     resolve a single callsign instead of a file');
  WriteLn('  --date <YYYY-MM-DD>   the date to resolve --call at (default: today)');
  WriteLn('  --explain             print what each engine made of every row, not');
  WriteLn('                        only the rows where they disagree');
  WriteLn('  --tables <dir>        directory holding the DXCC tables');
  WriteLn('                        (default: the generated test fixtures)');
  WriteLn('  --variant plain|expanded');
  WriteLn('                        which country-*.tab to use when the directory holds');
  WriteLn('                        the generated pair rather than a plain country.tab');
  WriteLn('                        (default: expanded, i.e. after Import DXCC data)');
  WriteLn('  --out <file>          write every differing row to this CSV');
  WriteLn('  --samples <n>         example callsigns per report group (default 5)');
  WriteLn('  --limit <n>           stop after n rows');
  WriteLn('  --keys                also report rows where only the effective callsign');
  WriteLn('                        differs and the resolved country does not');
  WriteLn('  --dates <spec>        which dates to evaluate at (default: log)');
  WriteLn('                          log         the date each QSO actually carries');
  WriteLn('                          boundaries  every validity boundary in the tables,');
  WriteLn('                                      plus the day before and after each,');
  WriteLn('                                      against the log''s distinct callsigns');
  WriteLn('                          a,b,c       an explicit YYYY/MM/DD list');
  WriteLn('  --callsign-step <n>   in a date sweep, use every n-th distinct callsign');
  WriteLn('                        (announced in the output; 1 = all of them)');
  WriteLn('  --help');
  Halt(0);
end;

function NextArg(var I: Integer; const Name: string): string;
begin
  Inc(I);
  if I > ParamCount then
    Fail(Name + ' needs a value');
  Result := ParamStr(I);
end;

procedure ParseCommandLine;
var
  I: Integer;
  Arg: string;
begin
  I := 1;
  while I <= ParamCount do
  begin
    Arg := ParamStr(I);
    if (Arg = '--help') or (Arg = '-h') then
      Usage
    else if Arg = '--csv' then
      OptCsv := NextArg(I, '--csv')
    else if Arg = '--call' then
      OptCall := UpperCase(Trim(NextArg(I, '--call')))
    else if Arg = '--date' then
      OptCallDate := Trim(NextArg(I, '--date'))
    else if Arg = '--explain' then
      OptExplain := True
    else if Arg = '--tables' then
      OptTables := NextArg(I, '--tables')
    else if Arg = '--variant' then
      OptVariant := LowerCase(NextArg(I, '--variant'))
    else if Arg = '--out' then
      OptOut := NextArg(I, '--out')
    else if Arg = '--samples' then
      OptSamples := StrToIntDef(NextArg(I, '--samples'), 5)
    else if Arg = '--limit' then
      OptLimit := StrToIntDef(NextArg(I, '--limit'), 0)
    else if Arg = '--keys' then
      OptShowKeys := True
    else if Arg = '--dates' then
      OptDates := NextArg(I, '--dates')
    else if Arg = '--callsign-step' then
      OptCallStep := StrToIntDef(NextArg(I, '--callsign-step'), 1)
    else
      Fail('unknown option ' + Arg);
    Inc(I);
  end;

  if (OptCsv = '') and (OptCall = '') then
    Fail('one of --csv or --call is required (see --help)');
  if (OptCsv <> '') and (OptCall <> '') then
    Fail('--csv and --call are alternatives, not a pair');
  if (OptCsv <> '') and not FileExists(OptCsv) then
    Fail('no such file: ' + OptCsv);
  if OptCall <> '' then
  begin
    OptExplain := True;
    if OptCallDate = '' then
      OptCallDate := FormatDateTime('yyyy"-"mm"-"dd', Now);
    if Length(OptCallDate) <> 10 then
      Fail('--date must be YYYY-MM-DD');
  end;
  if (OptVariant <> 'plain') and (OptVariant <> 'expanded') then
    Fail('--variant must be plain or expanded');
  if OptCallStep < 1 then
    Fail('--callsign-step must be at least 1');
end;

{ The tables directory can be either the generated fixtures, which hold both
  country.tab variants under distinct names, or a live dxcc_data directory,
  where the file is simply country.tab and the variant has already been
  decided by whichever builder produced it. }
procedure ResolveTableFiles;
var
  Dir: string;
begin
  if OptTables <> '' then
    Dir := IncludeTrailingPathDelimiter(ExpandFileName(OptTables))
  else
    try
      Dir := GeneratedDir;
    except
      on E: Exception do
        Fail('cannot find the generated fixtures (' + E.Message +
             '); pass --tables');
    end;

  if FileExists(Dir + 'country.tab') then
    ValidFile := Dir + 'country.tab'
  else if OptVariant = 'plain' then
    ValidFile := Dir + 'country-plain.tab'
  else
    ValidFile := Dir + 'country-expanded.tab';

  DeletedFile    := Dir + 'country_del.tab';
  ExceptionsFile := Dir + 'exceptions.tab';
  AmbiguousFile  := Dir + 'ambiguous.tab';

  if not FileExists(ValidFile) then
    Fail('missing ' + ValidFile + ' (run tools/mkdxccdata.sh, or pass --tables)');
  if not FileExists(DeletedFile) then
    Fail('missing ' + DeletedFile);
end;

procedure LoadEngines;
begin
  Rules := TDxccSuffixRules.Create;
  Rules.LoadExceptions(ExceptionsFile);
  Rules.LoadAmbiguous(AmbiguousFile);

  LegacyValid   := TLegacyTable.Create(ValidFile);
  LegacyDeleted := TLegacyTable.Create(DeletedFile);
  LegacySplitter := TLegacySplitter.Create(LegacyValid, LegacyDeleted, Rules);

  ModernValid := TDxccTable.Create;
  ModernValid.LoadFromFile(ValidFile);
  ModernDeleted := TDxccTable.Create;
  ModernDeleted.LoadFromFile(DeletedFile);
  Resolver := TDxccResolver.Create(ModernValid, ModernDeleted, Rules);
end;

procedure FreeEngines;
begin
  Resolver.Free;
  ModernDeleted.Free;
  ModernValid.Free;
  LegacySplitter.Free;
  LegacyDeleted := nil;
  LegacyValid := nil;
  Rules.Free;
end;

{ id_country keeps the ADIF only when it parses and is positive; anything else
  means "no country" (dDXCC.pas:723-746). }
function EffectiveAdif(const S: string): Integer;
begin
  if not TryStrToInt(S, Result) then
    Result := 0
  else if Result < 0 then
    Result := 0;
end;

{ --------------------------------------------------------------- the engines }

function EvaluateLegacy(const Callsign, ADate: string): TEvaluation;
var
  UzNasel: Boolean;
  Adif, Index: Integer;

  procedure Take(Table: IDxccTable; AIndex: Integer; ADeleted: Boolean);
  begin
    Result.Found   := True;
    Result.Deleted := ADeleted;
    Result.Pattern := Table.Pattern(AIndex);
    Result.Adif    := EffectiveAdif(Table.Field(AIndex, fldAdif));
    Result.Country := Table.Field(AIndex, fldCountry);
    Result.Fields  :=
      Table.Field(AIndex, fldCountry) + '|' +
      UpperCase(Table.Field(AIndex, fldContinent)) + '|' +
      Table.Field(AIndex, fldUtcOffset) + '|' +
      Table.Field(AIndex, fldLatitude) + '|' +
      Table.Field(AIndex, fldLongitude) + '|' +
      Table.Field(AIndex, fldItu) + '|' +
      Table.Field(AIndex, fldWaz);
  end;

begin
  Result.Found   := False;
  Result.Deleted := False;
  Result.Pattern := '';
  Result.Adif    := 0;
  Result.Fields  := '';
  Result.Country := '';

  UzNasel := False;
  Adif := 0;
  { id_country discards both of these and looks the key up itself. }
  Result.Key := LegacySplitter.CoVyhodnocovat(Callsign, ADate, UzNasel, Adif);

  Index := LegacyDeleted.Find(Result.Key, ADate, mmPrefix);
  if Index <> -1 then
  begin
    Take(LegacyDeleted, Index, True);
    Exit;
  end;

  Index := LegacyValid.Find(Result.Key, ADate, mmPrefix);
  if Index <> -1 then
    Take(LegacyValid, Index, False);
end;

function EvaluateModern(const Callsign, ADate: string): TEvaluation;
var
  AlreadyResolved: Boolean;
  Adif, Index: Integer;
  Entry: TDxccEntry;

  procedure Take(Table: TDxccTable; AIndex: Integer; ADeleted: Boolean);
  begin
    Entry := Table.Entry(AIndex);
    Result.Found   := True;
    Result.Deleted := ADeleted;
    Result.Pattern := Table.Pattern(AIndex);
    Result.Adif    := EffectiveAdif(Entry.Adif);
    Result.Country := Entry.Country;
    Result.Fields  :=
      Entry.Country + '|' + UpperCase(Entry.Continent) + '|' +
      Entry.UtcOffset + '|' + Entry.Latitude + '|' + Entry.Longitude + '|' +
      Entry.Itu + '|' + Entry.Waz;
  end;

begin
  Result.Found   := False;
  Result.Deleted := False;
  Result.Pattern := '';
  Result.Adif    := 0;
  Result.Fields  := '';
  Result.Country := '';

  Result.Key := Resolver.EffectiveCallsign(Callsign, ADate, AlreadyResolved, Adif);

  Index := ModernDeleted.Find(Result.Key, ADate, dmPrefix);
  if Index >= 0 then
  begin
    Take(ModernDeleted, Index, True);
    Exit;
  end;

  Index := ModernValid.Find(Result.Key, ADate, dmPrefix);
  if Index >= 0 then
    Take(ModernValid, Index, False);
end;

function Classify(const Old, New: TEvaluation): TDiffClass;
begin
  if Old.Adif <> New.Adif then
    Result := dcDxcc
  else if (Old.Fields <> New.Fields) or (Old.Found <> New.Found) or
          (Old.Deleted <> New.Deleted) then
    Result := dcFields
  else if Old.Key <> New.Key then
    Result := dcKey
  else if Old.Pattern <> New.Pattern then
    Result := dcPattern
  else
    Result := dcSame;
end;

{ ------------------------------------------------------------------ reading }

{ Removes a trailing CR and one layer of surrounding double quotes, and
  nothing else -- whitespace inside the quotes is left in place so the caller
  can notice it. }
function StripQuotes(const S: string): string;
begin
  Result := S;
  while (Length(Result) > 0) and (Result[Length(Result)] in [#13, #10]) do
    SetLength(Result, Length(Result) - 1);
  if (Length(Result) >= 2) and (Result[1] = '"') and
     (Result[Length(Result)] = '"') then
    Result := Copy(Result, 2, Length(Result) - 2);
end;

{ 'YYYY-MM-DD' as exported, to the 'YYYY/MM/DD' the engines expect --
  the same shape dDXCC.DateToDDXCCDate (dDXCC.pas:896) produces. }
function NormaliseDate(const S: string): string;
var
  I: Integer;
begin
  Result := S;
  for I := 1 to Length(Result) do
    if Result[I] = '-' then
      Result[I] := '/';
end;

function CsvField(const S: string): string;
begin
  { Country names contain commas, so everything is quoted. }
  Result := '"' + StringReplace(S, '"', '""', [rfReplaceAll]) + '"';
end;

procedure WriteDiffRow(const ADate, Callsign: string; Kind: TDiffClass;
  const Old, New: TEvaluation);
begin
  if not OutOpen then
    Exit;
  WriteLn(OutFile,
    CsvField(ADate), ',', CsvField(Callsign), ',', CsvField(DiffClassName[Kind]), ',',
    CsvField(Old.Key), ',', Old.Adif, ',', CsvField(Old.Country), ',', CsvField(Old.Pattern), ',',
    CsvField(New.Key), ',', New.Adif, ',', CsvField(New.Country), ',', CsvField(New.Pattern));
end;

{ One engine's answer, laid out the way id_country's callers read it. }
function ExplainSide(const E: TEvaluation): string;
begin
  if not E.Found then
    Result := Format('key=%-14s no match -- no country', [E.Key])
  else
  begin
    Result := Format('key=%-14s mark=%-18s adif=%-5d %s',
      [E.Key, E.Pattern, E.Adif, E.Country]);
    if E.Deleted then
      Result := Result + '   [deleted entity]';
  end;
end;

function Describe(const E: TEvaluation): string;
begin
  if not E.Found then
    Result := '<no match>'
  else
  begin
    Result := E.Country + ' [' + IntToStr(E.Adif) + ']';
    if E.Deleted then
      Result := Result + ' (deleted)';
  end;
end;

{ In a date sweep the callsign alone does not identify a case -- the date is
  half the story -- so it is carried into the report samples. }
function SampleFor(const ADate, Callsign: string): string;
begin
  if LowerCase(OptDates) = 'log' then
    Result := Callsign
  else
    Result := Callsign + '@' + ADate;
end;

procedure ProcessRow(const ADate, Callsign: string);
var
  Old, New: TEvaluation;
  Kind: TDiffClass;
  Sample: string;
begin
  Old := EvaluateLegacy(Callsign, ADate);
  New := EvaluateModern(Callsign, ADate);
  Kind := Classify(Old, New);
  Inc(ClassCounts[Kind]);

  if New.Key = '?' then
    Inc(MaritimeCount);

  if OptExplain then
  begin
    WriteLn;
    WriteLn(Callsign, '  on  ', ADate);
    WriteLn('  old  ', ExplainSide(Old));
    WriteLn('       ', Old.Fields);
    WriteLn('  new  ', ExplainSide(New));
    WriteLn('       ', New.Fields);
    if Kind = dcSame then
      WriteLn('  =>   both engines agree')
    else
      WriteLn('  =>   DIFFER (', DiffClassName[Kind], ')');
  end;

  if Kind <> dcSame then
  begin
    Sample := SampleFor(ADate, Callsign);
    case Kind of
      dcDxcc:    DxccGroups.Add(Describe(Old) + '  ->  ' + Describe(New), Sample);
      dcFields:  FieldGroups.Add(Describe(Old) + '  ->  ' + Describe(New), Sample);
      dcKey:     KeyGroups.Add('old key ' + Old.Key + '  ->  new key ' + New.Key, Sample);
      dcPattern: PatternGroups.Add(Old.Pattern + '  ->  ' + New.Pattern, Sample);
    end;
    WriteDiffRow(ADate, Callsign, Kind, Old, New);
  end;

  { Independent of any disagreement: what neither engine can place.  Only
    meaningful at the date the QSO actually happened -- in a boundary sweep a
    1939 callsign having no country is the expected answer, not a finding. }
  if (LowerCase(OptDates) = 'log') and (not Old.Found) and (not New.Found) and
     (New.Key <> '?') then
    UnresolvedGroups.Add(Callsign, ADate);
end;

{ 'YYYY/MM/DD' -> TDateTime.  False for anything that is not a real date;
  the tables do contain windows the calendar would reject. }
function TryParseDxccDate(const S: string; out Value: TDateTime): Boolean;
var
  Y, M, D: Integer;
begin
  Result := False;
  if Length(S) <> 10 then
    Exit;
  if not TryStrToInt(Copy(S, 1, 4), Y) then Exit;
  if not TryStrToInt(Copy(S, 6, 2), M) then Exit;
  if not TryStrToInt(Copy(S, 9, 2), D) then Exit;
  Result := TryEncodeDate(Y, M, D, Value);
end;

function FormatDxccDate(Value: TDateTime): string;
begin
  Result := FormatDateTime('yyyy"/"mm"/"dd', Value);
end;

{ Every ValidFrom and ValidTo in both tables, plus the day either side of each.

  The boundary itself catches an inclusive/exclusive mistake; the neighbours
  catch the off-by-one that an inclusive test would otherwise hide.  Entries
  the calendar rejects are counted and reported rather than dropped in
  silence. }
procedure BuildBoundaryDates(List: TStringList; out Rejected: Integer);
var
  Entry: TDxccEntry;

  procedure AddAround(const S: string);
  var
    Value: TDateTime;
  begin
    if not TryParseDxccDate(S, Value) then
    begin
      Inc(Rejected);
      Exit;
    end;
    List.Add(FormatDxccDate(Value - 1));
    List.Add(FormatDxccDate(Value));
    List.Add(FormatDxccDate(Value + 1));
  end;

  procedure Harvest(Table: TDxccTable);
  var
    J: Integer;
  begin
    for J := 0 to Table.Count - 1 do
    begin
      Entry := Table.Entry(J);
      AddAround(Entry.ValidFrom);
      AddAround(Entry.ValidTo);
    end;
  end;

begin
  Rejected := 0;
  List.Sorted := True;
  List.Duplicates := dupIgnore;
  Harvest(ModernValid);
  Harvest(ModernDeleted);
end;

procedure BuildExplicitDates(List: TStringList; const Spec: string);
var
  Parts: TStringList;
  I: Integer;
  Value: TDateTime;
begin
  Parts := TStringList.Create;
  try
    Parts.Delimiter := ',';
    Parts.StrictDelimiter := True;
    Parts.DelimitedText := Spec;
    for I := 0 to Parts.Count - 1 do
      if TryParseDxccDate(Trim(Parts[I]), Value) then
        List.Add(FormatDxccDate(Value))
      else
        Fail('--dates: not a YYYY/MM/DD date: ' + Parts[I]);
  finally
    Parts.Free;
  end;
end;

{ The log's distinct callsigns against every date in the sweep. }
procedure RunDateSweep;
var
  Dates: TStringList;
  D, C, Rejected: Integer;
  Total: Int64;
begin
  Dates := TStringList.Create;
  try
    if LowerCase(OptDates) = 'boundaries' then
    begin
      BuildBoundaryDates(Dates, Rejected);
      WriteLn(Format('  %d distinct dates from %d table entries%s',
        [Dates.Count, ModernValid.Count + ModernDeleted.Count,
         Format(' (%d unparseable window ends skipped)', [Rejected])]));
    end
    else
    begin
      BuildExplicitDates(Dates, OptDates);
      WriteLn(Format('  %d dates given explicitly', [Dates.Count]));
    end;

    if Dates.Count = 0 then
      Fail('--dates produced no usable dates');

    SweptDates := Dates.Count;
    SweptCalls := 0;
    C := 0;
    while C < DistinctCalls.Count do
    begin
      Inc(SweptCalls);
      Inc(C, OptCallStep);
    end;

    Total := Int64(SweptDates) * SweptCalls;
    WriteLn(Format('  %d callsigns x %d dates = %d comparisons',
      [SweptCalls, SweptDates, Total]));
    if OptCallStep > 1 then
      WriteLn(Format('  NOTE: sampling every %d-th of %d distinct callsigns',
        [OptCallStep, DistinctCalls.Count]));
    WriteLn;
    Flush(Output);   { stdout is block-buffered when piped; keep the progress
                       line on stderr from interleaving with the header }

    for D := 0 to Dates.Count - 1 do
    begin
      C := 0;
      while C < DistinctCalls.Count do
      begin
        Inc(Rows);
        ProcessRow(Dates[D], DistinctCalls[C]);
        Inc(C, OptCallStep);
      end;
      if (D mod 100 = 99) or (D = Dates.Count - 1) then
      begin
        Write(StdErr, Format(#13'  ... %d/%d dates, %d comparisons, %d differences  ',
          [D + 1, Dates.Count, Rows,
           ClassCounts[dcDxcc] + ClassCounts[dcFields] + ClassCounts[dcKey] +
           ClassCounts[dcPattern]]));
        Flush(StdErr);
      end;
    end;
    WriteLn(StdErr);
  finally
    Dates.Free;
  end;
end;

procedure ReadLog;
var
  Input: TextFile;
  Line, DatePart, CallPart, RawCall: string;
  Comma: Integer;
  First: Boolean;
begin
  AssignFile(Input, OptCsv);
  Reset(Input);
  try
    First := True;
    while not Eof(Input) do
    begin
      ReadLn(Input, Line);
      if Trim(Line) = '' then
        Continue;

      Comma := Pos(',', Line);
      if Comma = 0 then
      begin
        Inc(Skipped);
        Continue;
      end;

      DatePart := Trim(StripQuotes(Copy(Line, 1, Comma - 1)));
      RawCall  := StripQuotes(Copy(Line, Comma + 1, Length(Line)));
      CallPart := UpperCase(Trim(RawCall));

      if First then
      begin
        First := False;
        { Drop the header row, whatever its columns are called. }
        if (LowerCase(DatePart) = 'qsodate') or (LowerCase(CallPart) = 'CALLSIGN') then
          Continue;
      end;

      if (CallPart = '') or (Length(DatePart) <> 10) then
      begin
        Inc(Skipped);
        Continue;
      end;

      { A couple of rows in a real export carry a trailing space.  Trimming is
        right -- the engines would both choke on it identically -- but say so,
        rather than letting a silent fixup look like agreement. }
      if RawCall <> Trim(RawCall) then
        Inc(Normalised);

      LogDates.Add(NormaliseDate(DatePart));
      LogCalls.Add(CallPart);
      DistinctCalls.Add(CallPart);

      if (OptLimit > 0) and (LogCalls.Count >= OptLimit) then
        Break;
    end;
  finally
    CloseFile(Input);
  end;
end;

{ ------------------------------------------------------------------ reports }

{ Each QSO at the date it actually happened -- the default. }
procedure RunLogDates;
var
  I: Integer;
begin
  for I := 0 to LogCalls.Count - 1 do
  begin
    Inc(Rows);
    ProcessRow(LogDates[I], LogCalls[I]);
  end;
end;

procedure ReportGroups(const Title, Nothing: string; Groups: TGroupList);
var
  Ranked: TFPList;
  Group: TGroup;
  I: Integer;
begin
  WriteLn;
  WriteLn(Title);
  WriteLn(StringOfChar('-', Length(Title)));
  if Groups.Count = 0 then
  begin
    WriteLn('  ', Nothing);
    Exit;
  end;

  Ranked := Groups.Ranked;
  try
    for I := 0 to Ranked.Count - 1 do
    begin
      Group := TGroup(Ranked[I]);
      WriteLn(Format('  %6d  %s', [Group.Count, Group.Key]));
      if Group.Samples.Count > 0 then
        WriteLn('          e.g. ', StringReplace(Group.Samples.CommaText, ',', ', ',
          [rfReplaceAll]));
    end;
  finally
    Ranked.Free;
  end;
end;

procedure ReportUnresolved;
var
  Ranked: TFPList;
  Group: TGroup;
  I, Shown: Integer;
  Total: Int64;
begin
  WriteLn;
  WriteLn('Callsigns neither engine can place');
  WriteLn('----------------------------------');
  if UnresolvedGroups.Count = 0 then
  begin
    WriteLn('  none -- every callsign in the log resolved to a country');
    Exit;
  end;

  Total := 0;
  Ranked := UnresolvedGroups.Ranked;
  try
    for I := 0 to Ranked.Count - 1 do
      Inc(Total, TGroup(Ranked[I]).Count);
    WriteLn(Format('  %d distinct callsigns, %d QSO rows.  Both engines agree they',
      [UnresolvedGroups.Count, Total]));
    WriteLn('  have no country, so this is a gap in ctyfiles/ or a bad callsign,');
    WriteLn('  not a difference between the engines.');
    WriteLn;
    Shown := 0;
    for I := 0 to Ranked.Count - 1 do
    begin
      Group := TGroup(Ranked[I]);
      WriteLn(Format('  %6d  %s', [Group.Count, Group.Key]));
      Inc(Shown);
      if Shown >= 40 then
      begin
        WriteLn(Format('  ... and %d more (use --out to get them all)',
          [Ranked.Count - Shown]));
        Break;
      end;
    end;
  finally
    Ranked.Free;
  end;
end;

procedure Report;
begin
  WriteLn;
  WriteLn('Result');
  WriteLn('------');
  if SweptDates > 0 then
    WriteLn(Format('  sweep                    %d callsigns x %d dates',
      [SweptCalls, SweptDates]));
  WriteLn(Format('  rows compared            %d', [Rows]));
  if Skipped > 0 then
    WriteLn(Format('  rows skipped (malformed) %d', [Skipped]));
  if Normalised > 0 then
    WriteLn(Format('  rows needing a trim      %d', [Normalised]));
  WriteLn(Format('  identical                %d', [ClassCounts[dcSame]]));
  WriteLn(Format('  different DXCC entity    %d', [ClassCounts[dcDxcc]]));
  WriteLn(Format('  same entity, other field %d', [ClassCounts[dcFields]]));
  WriteLn(Format('  same result, other key   %d', [ClassCounts[dcKey]]));
  WriteLn(Format('  same result, other mark  %d', [ClassCounts[dcPattern]]));
  WriteLn(Format('  maritime/aeronautical    %d', [MaritimeCount]));

  ReportGroups('Different DXCC entity', 'none', DxccGroups);
  ReportGroups('Same entity, different field', 'none', FieldGroups);
  if OptShowKeys then
  begin
    ReportGroups('Same country, different effective callsign', 'none', KeyGroups);
    ReportGroups('Same result, different matched mark', 'none', PatternGroups);
  end;
  if SweptDates = 0 then
    ReportUnresolved;

  WriteLn;
  WriteLn(Format('SUMMARY rows=%d dxcc=%d fields=%d key=%d pattern=%d unresolved=%d',
    [Rows, ClassCounts[dcDxcc], ClassCounts[dcFields], ClassCounts[dcKey],
     ClassCounts[dcPattern], UnresolvedGroups.Count]));
end;

{ --------------------------------------------------------------------- main }

var
  Kind: TDiffClass;
begin
  ParseCommandLine;
  ResolveTableFiles;

  for Kind := Low(TDiffClass) to High(TDiffClass) do
    ClassCounts[Kind] := 0;

  LogDates         := TStringList.Create;
  LogCalls         := TStringList.Create;
  DistinctCalls    := TStringList.Create;
  DistinctCalls.Sorted := True;
  DistinctCalls.Duplicates := dupIgnore;
  DxccGroups       := TGroupList.Create(OptSamples);
  FieldGroups      := TGroupList.Create(OptSamples);
  KeyGroups        := TGroupList.Create(OptSamples);
  PatternGroups    := TGroupList.Create(OptSamples);
  UnresolvedGroups := TGroupList.Create(OptSamples);
  try
    WriteLn('Tables');
    WriteLn('------');
    WriteLn('  valid       ', ValidFile);
    WriteLn('  deleted     ', DeletedFile);
    WriteLn('  exceptions  ', ExceptionsFile);
    WriteLn('  ambiguous   ', AmbiguousFile);
    LoadEngines;
    WriteLn(Format('  marks       %d valid, %d deleted (legacy: %d / %d)',
      [ModernValid.Count, ModernDeleted.Count,
       LegacyValid.Count, LegacyDeleted.Count]));
    WriteLn('  suffix      ', Rules.Exceptions.Count, ' exceptions, ',
      Rules.Ambiguous.Count, ' ambiguous prefixes');
    WriteLn;
    WriteLn('Log');
    WriteLn('---');
    if OptCall <> '' then
      WriteLn('  single callsign: ', OptCall, ' on ', OptCallDate)
    else
      WriteLn('  ', OptCsv);
    WriteLn;
    if OptCall = '' then
    begin
      WriteLn('Not compared: DXCCRefArray prefix (comes from MySQL) and the US-state');
      WriteLn('override at dDXCC.pas:727 (needs a state column, and the new parser');
      WriteLn('does not implement it yet).');
    end;

    if OptOut <> '' then
    begin
      AssignFile(OutFile, OptOut);
      Rewrite(OutFile);
      OutOpen := True;
      WriteLn(OutFile, 'qsodate,callsign,class,old_key,old_adif,old_country,' +
        'old_pattern,new_key,new_adif,new_country,new_pattern');
    end;

    try
      if OptCall <> '' then
      begin
        LogDates.Add(NormaliseDate(OptCallDate));
        LogCalls.Add(OptCall);
        DistinctCalls.Add(OptCall);
      end
      else
        ReadLog;
      if OptCall = '' then
        WriteLn(Format('  %d rows, %d distinct callsigns',
          [LogCalls.Count, DistinctCalls.Count]));
      if LowerCase(OptDates) = 'log' then
      begin
        if OptCall = '' then
        begin
          WriteLn('  evaluated at the date each QSO carries');
          WriteLn;
        end;
        RunLogDates;
      end
      else
      begin
        WriteLn('  evaluated at a date sweep, not at the log''s own dates');
        RunDateSweep;
      end;
    finally
      if OutOpen then
        CloseFile(OutFile);
    end;

    { A single-callsign query wants the answer, not a report about a corpus
      of one. }
    if OptCall = '' then
      Report;
    if OptOut <> '' then
    begin
      WriteLn;
      WriteLn('Differing rows written to ', OptOut);
    end;

    FreeEngines;
  finally
    UnresolvedGroups.Free;
    PatternGroups.Free;
    KeyGroups.Free;
    FieldGroups.Free;
    DxccGroups.Free;
    DistinctCalls.Free;
    LogCalls.Free;
    LogDates.Free;
  end;
end.
