(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Argentina, which is the hardest shape in the whole table.

  Argentine regions are encoded in the *fourth character* of the callsign, not
  in a prefix: LU1FAA is Santa Fe, LU1HAA is Cordoba, LU1AAA is Buenos Aires.
  When an operator transmits from somewhere else they append a single letter,
  so LU1AAA becomes LU1AAA/Z -- and dDXCC.CoVyhodnocovat (dDXCC.pas:517-529,
  the branch commented "nesmime zapomenout na chudaky Argentince") turns that
  into a lookup key by overwriting character 4:

      LU1AAA + /Z  ->  LU1ZAA

  which is what actually reaches this parser.

  The stakes are higher than a wrong region name: LU#Z is not an Argentine
  province at all, it is *Antarctica* -- a separate DXCC entity.  Resolving
  LU1AAA/Z as Buenos Aires would put a QSO in the wrong country, and a wrong
  country changes the DXCC standings.

  These tests exercise the parser with the keys that layer produces.  The
  transformation itself still lives in dDXCC and is not covered here. }

unit tArgentina;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uDxccTableIntf, uDxccTestBase;

type
  TArgentinaTests = class(TDxccTableTestCase)
  private
    FTable: IDxccTable;
    function CountryOf(const Callsign: string): string;
    function PatternOf(const Callsign: string): string;
    procedure AssertCountry(const Callsign, Expected: string);
    procedure AssertPattern(const Callsign, Expected: string);
    procedure AssertCountryContains(const Callsign, Fragment: string);
  protected
    procedure SetUp; override;
  published
    procedure HomeRegionComesFromTheFourthCharacter;
    procedure BuenosAiresCityAndProvinceAreDifferent;
    procedure RegionLettersSplitByRange;
    procedure SantaCruzAndTierraDelFuegoSplitByRange;
    procedure LwPrefixResolvesLikeLu;

    { The point of the whole unit. }
    procedure SlashZKeyResolvesToAntarcticaNotBuenosAires;
    procedure AntarcticBasesBeatThePlainZRegion;
    procedure ExactEntryStopsWinningOnceItsWindowCloses;
    procedure SlashFormsStoredAsExactEntriesNeedNoSplitting;
    procedure EveryRegionLetterResolvesToArgentinaOrAntarctica;
    procedure AllRegionKeysAreDistinctWhereExpected;
  end;

  TLegacyArgentinaTests = class(TArgentinaTests)
  protected
    function NewTable(const FileName: string): IDxccTable; override;
  end;

  TModernArgentinaTests = class(TArgentinaTests)
  protected
    function NewTable(const FileName: string): IDxccTable; override;
  end;

implementation

uses
  uLegacyTable, uModernTable, uTestData;

function TLegacyArgentinaTests.NewTable(const FileName: string): IDxccTable;
begin
  Result := TLegacyTable.Create(FileName);
end;

function TModernArgentinaTests.NewTable(const FileName: string): IDxccTable;
begin
  Result := TModernTable.Create(FileName);
end;

procedure TArgentinaTests.SetUp;
begin
  inherited SetUp;
  FTable := NewTable(CanonicalTable);
end;

function TArgentinaTests.CountryOf(const Callsign: string): string;
var
  Found: Integer;
begin
  Found := FTable.Find(Callsign, '2020/01/01', mmPrefix);
  if Found < 0 then
    Result := '<no match>'
  else
    Result := FTable.Field(Found, fldCountry);
end;

function TArgentinaTests.PatternOf(const Callsign: string): string;
var
  Found: Integer;
begin
  Found := FTable.Find(Callsign, '2020/01/01', mmPrefix);
  if Found < 0 then
    Result := '<no match>'
  else
    Result := FTable.Pattern(Found);
end;

procedure TArgentinaTests.AssertCountry(const Callsign, Expected: string);
begin
  AssertEquals('resolving ' + Callsign, Expected, CountryOf(Callsign));
end;

procedure TArgentinaTests.AssertPattern(const Callsign, Expected: string);
begin
  AssertEquals('pattern matched for ' + Callsign, Expected, PatternOf(Callsign));
end;

{ The CallResolution descriptions for Antarctic bases are long prose, so match
  on a distinctive fragment rather than pinning the whole sentence. }
procedure TArgentinaTests.AssertCountryContains(const Callsign, Fragment: string);
var
  Country: string;
begin
  Country := CountryOf(Callsign);
  AssertTrue(Format('resolving %s: expected something containing "%s", got "%s"',
    [Callsign, Fragment, Country]), Pos(Fragment, Country) > 0);
end;

procedure TArgentinaTests.HomeRegionComesFromTheFourthCharacter;
begin
  { Same operator prefix, different fourth character, different province. }
  AssertCountry('LU1FAA', 'Argentina, Santa Fe (SF)');
  AssertCountry('LU1HAA', 'Argentina, Cordoba (CD)');
  AssertCountry('LU1JAA', 'Argentina, Entre Rios (ER)');
  AssertCountry('LU1MAA', 'Argentina, Mendoza (MZ)');
  AssertCountry('LU1WAA', 'Argentina, Chubut (CH)');
  AssertCountry('LU1YAA', 'Argentina, Neuquen (NQ)');
end;

procedure TArgentinaTests.BuenosAiresCityAndProvinceAreDifferent;
begin
  { LU#[A-C] is the federal capital, LU#[D-E] the surrounding province. }
  AssertCountry('LU1AAA', 'Argentina, Buenos Aires (CF)');
  AssertCountry('LU1CAA', 'Argentina, Buenos Aires (CF)');
  AssertCountry('LU1DAA', 'Argentina, Buenos Aires Province (BA)');
  AssertCountry('LU1EAA', 'Argentina, Buenos Aires Province (BA)');
end;

procedure TArgentinaTests.RegionLettersSplitByRange;
begin
  { LU#G is split in two by the fifth character. }
  AssertCountry('LU1GAA', 'Argentina, Chaco (CC)');
  AssertCountry('LU1GOA', 'Argentina, Chaco (CC)');
  AssertCountry('LU1GPA', 'Argentina, Formosa (FO)');
  AssertCountry('LU1GZA', 'Argentina, Formosa (FO)');
end;

procedure TArgentinaTests.SantaCruzAndTierraDelFuegoSplitByRange;
begin
  { LU[1-9]X[A-O] versus LU[1-9]X[P-Z]. }
  AssertCountry('LU1XAA', 'Argentina, Santa Cruz (SC)');
  AssertCountry('LU9XOA', 'Argentina, Santa Cruz (SC)');
  AssertCountry('LU1XPA', 'Argentina, Tierra del Fuego (TF)');
  AssertCountry('LU9XZA', 'Argentina, Tierra del Fuego (TF)');
end;

procedure TArgentinaTests.LwPrefixResolvesLikeLu;
begin
  { Every LU pattern has an LW twin on the same line, sharing the
    description. }
  AssertCountry('LW1FAA', 'Argentina, Santa Fe (SF)');
  AssertCountry('LW1AAA', 'Argentina, Buenos Aires (CF)');
  AssertCountry('LW1XPA', 'Argentina, Tierra del Fuego (TF)');
end;

procedure TArgentinaTests.SlashZKeyResolvesToAntarcticaNotBuenosAires;
begin
  { LU1AAA at home. }
  AssertCountry('LU1AAA', 'Argentina, Buenos Aires (CF)');
  { LU1AAA/Z, after dDXCC rewrites character 4, is a different DXCC entity
    entirely -- not a different Argentine province. }
  AssertCountry('LU1ZAA', 'Antarctica');
  AssertTrue('LU1AAA and LU1AAA/Z must not resolve to the same entity',
    CountryOf('LU1AAA') <> CountryOf('LU1ZAA'));
end;

procedure TArgentinaTests.AntarcticBasesBeatThePlainZRegion;
begin
  { Named bases are '=' exact entries in CallResolution.tbl, and an exact
    entry wins outright over any pattern -- so these beat both LU#Z from
    AreaOK1RR.tbl and the LU#ZAB area pattern. }
  AssertPattern('LU1ZAB', '=LU1ZAB');
  AssertCountryContains('LU1ZAB', 'Matienzo');

  AssertPattern('LU1ZD', '=LU1ZD');
  AssertCountryContains('LU1ZD', 'San Martin');

  { ...but a Z with nothing special after it falls through to the area
    pattern, which is plain Antarctica. }
  AssertPattern('LU1ZAA', 'LU#Z');
  AssertCountry('LU1ZAA', 'Antarctica');
end;

procedure TArgentinaTests.ExactEntryStopsWinningOnceItsWindowCloses;
var
  Found: Integer;
begin
  { =LU1ZBM is a real operation that ran only during 2004.  Inside that window
    the exact entry wins; outside it the area pattern LU#ZB takes over.  So
    the same callsign legitimately resolves to two different places depending
    on the QSO date -- which is the entire reason lookups carry a date. }
  Found := FTable.Find('LU1ZBM', '2004/06/15', mmPrefix);
  AssertTrue('LU1ZBM should resolve in 2004', Found >= 0);
  AssertEquals('inside its window the exact entry wins',
    '=LU1ZBM', FTable.Pattern(Found));
  AssertTrue('expected the Marambio base description, got ' +
    FTable.Field(Found, fldCountry),
    Pos('Marambio', FTable.Field(Found, fldCountry)) > 0);

  AssertPattern('LU1ZBM', 'LU#ZB');
  AssertTrue('outside the window it must not resolve to Marambio',
    Pos('Marambio', CountryOf('LU1ZBM')) = 0);
end;

procedure TArgentinaTests.SlashFormsStoredAsExactEntriesNeedNoSplitting;
begin
  { Some Argentine portable calls are listed verbatim, slash and all, so
    dDXCC.CoVyhodnocovat's first move -- try the whole string as an exact
    match (dDXCC.pas:463) -- resolves them without any rewriting. }
  AssertPattern('LU2ERA/Z', '=LU2ERA/Z');
  AssertCountryContains('LU2ERA/Z', 'Orcadas');
  AssertPattern('LU8DBS/Z', '=LU8DBS/Z');
  AssertCountryContains('LU8DBS/Z', 'Esperanza');
end;

procedure TArgentinaTests.EveryRegionLetterResolvesToArgentinaOrAntarctica;
var
  C: AnsiChar;
  Country: string;
  Wrong: string;
begin
  { Whatever letter the operator appends, the resulting key must land on an
    Argentine or Antarctic entity -- never on some unrelated country that
    happens to own that letter as a prefix. }
  Wrong := '';
  for C := 'A' to 'Z' do
  begin
    Country := CountryOf('LU1' + C + 'AA');
    if (Pos('Argent', Country) = 0) and (Pos('Antarctica', Country) = 0) then
      Wrong := Wrong + Format('LU1%sAA=%s ', [C, Country]);
  end;
  AssertEquals('region keys landing outside Argentina/Antarctica', '', Wrong);
end;

procedure TArgentinaTests.AllRegionKeysAreDistinctWhereExpected;
var
  Seen: TStringList;
  C: AnsiChar;
  Country: string;
begin
  { Sanity check that the fourth character really is doing the work: the 26
    possible keys must produce a good spread of entities, not one answer. }
  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;
    for C := 'A' to 'Z' do
    begin
      Country := CountryOf('LU1' + C + 'AA');
      if Country <> '<no match>' then
        Seen.Add(Country);
    end;
    AssertTrue(Format('expected many distinct entities across the region ' +
      'letters, got %d', [Seen.Count]), Seen.Count >= 18);
  finally
    Seen.Free;
  end;
end;

initialization
  RegisterTest(TLegacyArgentinaTests);
  RegisterTest(TModernArgentinaTests);

end.
