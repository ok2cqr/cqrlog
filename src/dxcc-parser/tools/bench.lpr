(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Times the legacy and the new DXCC engine over the same callsigns.

  logdiff answers "do the two engines agree"; this answers "which one is
  faster, and by how much".  Both engines run the whole dDXCC.id_country path:

    key := CoVyhodnocovat / EffectiveCallsign        -- the splitter
    look the key up in country_del.tab, then country.tab, prefix mode
    read country / continent / utc / lat / long / itu / waz / adif

  Three layers are timed separately so a regression can be placed:

    load      constructing both tables from disk (once per engine)
    split     the splitter only
    find      table lookup only, on the split key, both tables
    full      everything id_country does, splitter + lookups + fields

  The callsign corpus is whatever is richest: every CALL in the ADIF files
  given with --adif, plus the corpus the differential test derives from the
  tables (one concrete callsign per pattern).  Each callsign is resolved at
  its QSO date when it has one, otherwise at today's date.

  Usage:  tools/bench [--tables <dir>] [--adif <file>]... [--rounds <n>]
                      [--corpus adif|derived|all] }

program bench;

{$mode objfpc}{$H+}

uses
  BaseUnix, Unix, Classes, SysUtils,
  uDxccTableIntf, uDxccTable, uDxccEntry, uDxccResolver, uDxccSuffixRules,
  uLegacyTable, uLegacySplitter, uCorpus, uTestData;

type
  TSample = record
    Call: string;
    Date: string;   { YYYY/MM/DD }
  end;

  { One engine's answer, the fields id_country copies out of the table. }
  TAnswer = record
    Key: string;
    Country, Continent, UtcOffset, Latitude, Longitude, Itu, Waz, Adif: string;
    Found: Boolean;
  end;

var
  OptTables: string = '';
  OptRounds: Integer = 5;
  OptCorpus: string = 'all';
  AdifFiles: TStringList;

  Samples: array of TSample;

  Rules: TDxccSuffixRules;
  LegacyValid, LegacyDeleted: IDxccTable;
  LegacySplitter: TLegacySplitter;
  ModernValid, ModernDeleted: TDxccTable;
  Resolver: TDxccResolver;

  ValidFile, DeletedFile, ExceptionsFile, AmbiguousFile: string;

{ ------------------------------------------------------------------ clock }

function NowMicros: Int64;
var
  TV: TTimeVal;
begin
  fpgettimeofday(@TV, nil);
  Result := Int64(TV.tv_sec) * 1000000 + TV.tv_usec;
end;

{ ---------------------------------------------------------------- options }

procedure Fail(const Message: string);
begin
  WriteLn(StdErr, 'bench: ', Message);
  Halt(2);
end;

procedure Usage;
begin
  WriteLn('bench -- times the legacy and the new DXCC engine over the same callsigns');
  WriteLn;
  WriteLn('  --tables <dir>     directory holding the DXCC tables');
  WriteLn('                     (default: ~/.config/cqrlog/dxcc_data if present,');
  WriteLn('                      otherwise the generated test fixtures)');
  WriteLn('  --adif <file>      add every CALL/QSO_DATE from this ADIF; repeatable');
  WriteLn('  --rounds <n>       passes over the corpus per measurement (default 5)');
  WriteLn('  --corpus adif|derived|all');
  WriteLn('                     which callsigns to time (default all)');
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
    else if Arg = '--tables' then
      OptTables := NextArg(I, '--tables')
    else if Arg = '--adif' then
      AdifFiles.Add(NextArg(I, '--adif'))
    else if Arg = '--rounds' then
      OptRounds := StrToIntDef(NextArg(I, '--rounds'), 5)
    else if Arg = '--corpus' then
      OptCorpus := LowerCase(NextArg(I, '--corpus'))
    else
      Fail('unknown option ' + Arg);
    Inc(I);
  end;
  if OptRounds < 1 then
    Fail('--rounds must be at least 1');
  if (OptCorpus <> 'adif') and (OptCorpus <> 'derived') and (OptCorpus <> 'all') then
    Fail('--corpus must be adif, derived or all');
  if (OptCorpus = 'adif') and (AdifFiles.Count = 0) then
    Fail('--corpus adif needs at least one --adif');
end;

procedure ResolveTableFiles;
var
  Dir: string;
begin
  if OptTables <> '' then
    Dir := IncludeTrailingPathDelimiter(ExpandFileName(OptTables))
  else
  begin
    Dir := IncludeTrailingPathDelimiter(GetEnvironmentVariable('HOME')) +
           '.config' + PathDelim + 'cqrlog' + PathDelim + 'dxcc_data' + PathDelim;
    if not FileExists(Dir + 'country.tab') then
      try
        Dir := GeneratedDir;
      except
        on E: Exception do
          Fail('cannot find the generated fixtures (' + E.Message + '); pass --tables');
      end;
  end;

  if FileExists(Dir + 'country.tab') then
    ValidFile := Dir + 'country.tab'
  else
    ValidFile := Dir + 'country-expanded.tab';
  DeletedFile    := Dir + 'country_del.tab';
  ExceptionsFile := Dir + 'exceptions.tab';
  AmbiguousFile  := Dir + 'ambiguous.tab';

  if not FileExists(ValidFile) then
    Fail('missing ' + ValidFile);
  if not FileExists(DeletedFile) then
    Fail('missing ' + DeletedFile);
  WriteLn('tables:  ', Dir);
end;

{ ----------------------------------------------------------------- corpus }

procedure AddSample(const Call, Date: string);
begin
  SetLength(Samples, Length(Samples) + 1);
  Samples[High(Samples)].Call := Call;
  Samples[High(Samples)].Date := Date;
end;

{ Minimal ADIF reader: enough to pull CALL and QSO_DATE out of each record.
  Field names are case-insensitive; QSO_DATE is YYYYMMDD. }
procedure LoadAdifFile(const FileName: string; const Today: string);
var
  Stream: TStringStream;
  Text, Name, Value, Call, Date: string;
  P, Colon, Close, Len: Integer;
  Count: Integer;
begin
  Stream := TStringStream.Create('');
  try
    Stream.LoadFromFile(FileName);
    Text := Stream.DataString;
  finally
    Stream.Free;
  end;

  Count := 0;
  Call := '';
  Date := Today;
  P := 1;
  while P <= Length(Text) do
  begin
    if Text[P] <> '<' then
    begin
      Inc(P);
      Continue;
    end;
    Close := Pos('>', Text, P);
    if Close = 0 then
      Break;
    Name := Copy(Text, P + 1, Close - P - 1);
    Colon := Pos(':', Name);
    if Colon > 0 then
    begin
      Len := StrToIntDef(Copy(Name, Colon + 1, MaxInt), 0);
      { a type suffix, <CALL:6:S>, would hide in Len; strip it }
      if Pos(':', Copy(Name, Colon + 1, MaxInt)) > 0 then
        Len := StrToIntDef(Copy(Name, Colon + 1, Pos(':', Copy(Name, Colon + 1, MaxInt)) - 1), 0);
      Name := UpperCase(Copy(Name, 1, Colon - 1));
      Value := Copy(Text, Close + 1, Len);
      if Name = 'CALL' then
        Call := UpperCase(Trim(Value))
      else if (Name = 'QSO_DATE') and (Length(Value) = 8) then
        Date := Copy(Value, 1, 4) + '/' + Copy(Value, 5, 2) + '/' + Copy(Value, 7, 2);
      P := Close + 1 + Len;
    end
    else
    begin
      if UpperCase(Name) = 'EOR' then
      begin
        if Call <> '' then
        begin
          AddSample(Call, Date);
          Inc(Count);
        end;
        Call := '';
        Date := Today;
      end;
      P := Close + 1;
    end;
  end;
  WriteLn('adif:    ', Count:6, ' QSO  ', FileName);
end;

procedure BuildCorpus;
var
  Today: string;
  List: TStringList;
  I, AdifCount: Integer;
begin
  Today := FormatDateTime('yyyy"/"mm"/"dd', Now);
  SetLength(Samples, 0);

  if OptCorpus <> 'derived' then
    for I := 0 to AdifFiles.Count - 1 do
      LoadAdifFile(AdifFiles[I], Today);
  AdifCount := Length(Samples);

  if OptCorpus <> 'adif' then
  begin
    List := DerivedCallsigns(LegacyValid);
    try
      for I := 0 to List.Count - 1 do
        AddSample(List[I], Today);
      WriteLn('derived: ', List.Count:6, ' callsigns, one per pattern in ', ExtractFileName(ValidFile));
    finally
      List.Free;
    end;
  end;

  if Length(Samples) = 0 then
    Fail('empty corpus');
  WriteLn('corpus:  ', Length(Samples):6, ' (callsign, date) pairs, ',
          AdifCount, ' from ADIF');
end;

{ ---------------------------------------------------------------- engines }

procedure LoadEngines;
var
  T0: Int64;
  LegacyLoad, ModernLoad: Int64;
begin
  Rules := TDxccSuffixRules.Create;
  Rules.LoadExceptions(ExceptionsFile);
  Rules.LoadAmbiguous(AmbiguousFile);

  T0 := NowMicros;
  LegacyValid   := TLegacyTable.Create(ValidFile);
  LegacyDeleted := TLegacyTable.Create(DeletedFile);
  LegacyLoad := NowMicros - T0;
  LegacySplitter := TLegacySplitter.Create(LegacyValid, LegacyDeleted, Rules);

  T0 := NowMicros;
  ModernValid := TDxccTable.Create;
  ModernValid.LoadFromFile(ValidFile);
  ModernDeleted := TDxccTable.Create;
  ModernDeleted.LoadFromFile(DeletedFile);
  ModernLoad := NowMicros - T0;
  Resolver := TDxccResolver.Create(ModernValid, ModernDeleted, Rules);

  WriteLn;
  WriteLn('load (country.tab + country_del.tab, ', LegacyValid.Count, ' marks)');
  WriteLn('  legacy  ', LegacyLoad / 1000:8:1, ' ms');
  WriteLn('  modern  ', ModernLoad / 1000:8:1, ' ms');
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

{ The id_country path, legacy engine.  Mirrors dDXCC.id_country: split, look
  up in deleted then valid, copy the eight fields out. }
function LegacyFull(const S: TSample): TAnswer;
var
  UzNasel: Boolean;
  Adif, Index: Integer;
  Table: IDxccTable;
begin
  UzNasel := False;
  Adif := 0;
  Result.Found := False;
  Result.Key := LegacySplitter.CoVyhodnocovat(S.Call, S.Date, UzNasel, Adif);

  Table := LegacyDeleted;
  Index := Table.Find(Result.Key, S.Date, mmPrefix);
  if Index = -1 then
  begin
    Table := LegacyValid;
    Index := Table.Find(Result.Key, S.Date, mmPrefix);
  end;
  if Index = -1 then
    Exit;

  Result.Found     := True;
  Result.Country   := Table.Field(Index, fldCountry);
  Result.Itu       := Table.Field(Index, fldItu);
  Result.Waz       := Table.Field(Index, fldWaz);
  Result.UtcOffset := Table.Field(Index, fldUtcOffset);
  Result.Latitude  := Table.Field(Index, fldLatitude);
  Result.Longitude := Table.Field(Index, fldLongitude);
  Result.Adif      := Table.Field(Index, fldAdif);
  Result.Continent := UpperCase(Table.Field(Index, fldContinent));
end;

function ModernFull(const S: TSample): TAnswer;
var
  AlreadyResolved: Boolean;
  Adif, Index: Integer;
  Table: TDxccTable;
  E: TDxccEntry;
begin
  AlreadyResolved := False;
  Adif := 0;
  Result.Found := False;
  Result.Key := Resolver.EffectiveCallsign(S.Call, S.Date, AlreadyResolved, Adif);

  Table := ModernDeleted;
  Index := Table.Find(Result.Key, S.Date, dmPrefix);
  if Index = -1 then
  begin
    Table := ModernValid;
    Index := Table.Find(Result.Key, S.Date, dmPrefix);
  end;
  if Index = -1 then
    Exit;

  E := Table.Entry(Index);
  Result.Found     := True;
  Result.Country   := E.Country;
  Result.Itu       := E.Itu;
  Result.Waz       := E.Waz;
  Result.UtcOffset := E.UtcOffset;
  Result.Latitude  := E.Latitude;
  Result.Longitude := E.Longitude;
  Result.Adif      := E.Adif;
  Result.Continent := UpperCase(E.Continent);
end;

{ ----------------------------------------------------------------- timing }

type
  TLayer = (lySplit, lyFind, lyFull);
  TEngine = (enLegacy, enModern);

const
  LayerName: array[TLayer] of string = ('split', 'find', 'full');
  EngineName: array[TEngine] of string = ('legacy', 'modern');

var
  { The split keys, computed once so the find layer times lookups only. }
  Keys: array of string;
  Sink: Integer = 0;   { so the optimiser cannot drop a measured call }

procedure RunLayer(Engine: TEngine; Layer: TLayer; out Micros: Int64);
var
  R, I: Integer;
  T0: Int64;
  UzNasel: Boolean;
  Adif: Integer;
  Key: string;
  A: TAnswer;
begin
  T0 := NowMicros;
  for R := 1 to OptRounds do
    for I := 0 to High(Samples) do
      case Layer of
        lySplit:
          begin
            UzNasel := False;
            Adif := 0;
            if Engine = enLegacy then
              Key := LegacySplitter.CoVyhodnocovat(Samples[I].Call, Samples[I].Date, UzNasel, Adif)
            else
              Key := Resolver.EffectiveCallsign(Samples[I].Call, Samples[I].Date, UzNasel, Adif);
            Inc(Sink, Length(Key));
          end;
        lyFind:
          if Engine = enLegacy then
          begin
            Adif := LegacyDeleted.Find(Keys[I], Samples[I].Date, mmPrefix);
            if Adif = -1 then
              Adif := LegacyValid.Find(Keys[I], Samples[I].Date, mmPrefix);
            Inc(Sink, Adif);
          end
          else
          begin
            Adif := ModernDeleted.Find(Keys[I], Samples[I].Date, dmPrefix);
            if Adif = -1 then
              Adif := ModernValid.Find(Keys[I], Samples[I].Date, dmPrefix);
            Inc(Sink, Adif);
          end;
        lyFull:
          begin
            if Engine = enLegacy then
              A := LegacyFull(Samples[I])
            else
              A := ModernFull(Samples[I]);
            Inc(Sink, Length(A.Country));
          end;
      end;
  Micros := NowMicros - T0;
end;

{ Both engines must produce the same answer, otherwise the timing compares
  different work.  logdiff is the tool for explaining a difference; here it
  is only counted. }
function CountDisagreements: Integer;
var
  I: Integer;
  L, M: TAnswer;
begin
  Result := 0;
  for I := 0 to High(Samples) do
  begin
    L := LegacyFull(Samples[I]);
    M := ModernFull(Samples[I]);
    if (L.Found <> M.Found) or (L.Adif <> M.Adif) or (L.Country <> M.Country) then
    begin
      Inc(Result);
      if Result <= 10 then
        WriteLn('  differs: ', Samples[I].Call, ' @ ', Samples[I].Date,
                '  legacy=', L.Key, '/', L.Adif, '/', L.Country,
                '  modern=', M.Key, '/', M.Adif, '/', M.Country);
    end;
  end;
end;

procedure Report;
var
  Layer: TLayer;
  Engine: TEngine;
  Micros: array[TEngine, TLayer] of Int64;
  Calls: Int64;
  I: Integer;
  UzNasel: Boolean;
  Adif: Integer;
begin
  { warm-up: page in both tables' memory before anything is timed }
  for I := 0 to High(Samples) do
  begin
    LegacyFull(Samples[I]);
    ModernFull(Samples[I]);
  end;

  SetLength(Keys, Length(Samples));
  for I := 0 to High(Samples) do
  begin
    UzNasel := False;
    Adif := 0;
    Keys[I] := Resolver.EffectiveCallsign(Samples[I].Call, Samples[I].Date, UzNasel, Adif);
  end;

  Calls := Int64(OptRounds) * Length(Samples);
  WriteLn;
  WriteLn('lookups: ', Length(Samples), ' x ', OptRounds, ' rounds = ', Calls, ' per cell');
  WriteLn;
  WriteLn('layer    engine      total ms    us/call    calls/s');
  for Layer := Low(TLayer) to High(TLayer) do
  begin
    for Engine := Low(TEngine) to High(TEngine) do
    begin
      RunLayer(Engine, Layer, Micros[Engine, Layer]);
      WriteLn(LayerName[Layer]:5, '    ', EngineName[Engine]:6, '  ',
              Micros[Engine, Layer] / 1000:11:1, '  ',
              Micros[Engine, Layer] / Calls:9:2, '  ',
              Round(Calls * 1000000.0 / Micros[Engine, Layer]):9);
    end;
    WriteLn('         modern/legacy = ',
            Micros[enModern, Layer] / Micros[enLegacy, Layer]:0:2, 'x');
  end;

  WriteLn;
  I := CountDisagreements;
  WriteLn('disagreements (found/adif/country): ', I, ' of ', Length(Samples));
  if I > 0 then
    WriteLn('  -> run tools/logdiff to see which; timings above compare unequal work');
  if Sink = 0 then
    WriteLn('sink=0');
end;

begin
  AdifFiles := TStringList.Create;
  try
    ParseCommandLine;
    ResolveTableFiles;
    LoadEngines;
    try
      BuildCorpus;
      Report;
    finally
      FreeEngines;
    end;
  finally
    AdifFiles.Free;
  end;
end.
