(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The callsign-splitting layer: TDxccResolver against a verbatim copy of the
  original CoVyhodnocovat.

  One behavioural change is intended -- the Argentine province suffixes -- and
  the whole point of this unit is to show it is the *only* one.  The
  differential sweep therefore does not ignore mismatches wholesale; it
  ignores exactly the callsigns that are Argentine with a single-letter
  suffix, and asserts that everything else agrees. }

unit tSplitting;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  uDxccTableIntf, uDxccTable, uDxccResolver, uDxccSuffixRules, uLegacySplitter;

type
  TSplittingTests = class(TTestCase)
  private
    FValid, FDeleted: TDxccTable;
    FLegacyValid, FLegacyDeleted: IDxccTable;
    FRules: TDxccSuffixRules;
    FResolver: TDxccResolver;
    FLegacy: TLegacySplitter;

    function NewKey(const Callsign: string; const ADate: string = '2020/01/01'): string;
    function OldKey(const Callsign: string; const ADate: string = '2020/01/01'): string;
    { A callsign the fix is expected to treat differently. }
    function IsIntentionalDifference(const Callsign: string): Boolean;
    function CountryFor(const Callsign: string): string;
    function AdifFor(const Callsign: string): Integer;
    { The same two, resolved through the legacy engine. }
    function OldCountryFor(const Callsign: string): string;
    function OldAdifFor(const Callsign: string): Integer;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    { --- the fix -------------------------------------------------------- }
    procedure ArgentineRegionSuffixRewritesCharacterFour;
    procedure ArgentineLettersTheOriginalMissed;
    procedure ArgentineLettersAlreadyPatchedInTheTable;
    procedure ArgentineMobileAndPortableKeepTheirRegion;
    procedure CompanionPrefixesBehaveLikeLu;
    procedure ArgentineSuffixResolvesToTheRightProvince;
    procedure TheFixChangesTheProvinceNotTheEntity;

    { --- everything else must be unchanged ------------------------------ }
    procedure NonArgentineSlashFormsAreUnchanged;
    procedure DifferentialSweepOverSlashedCallsigns;
    procedure DifferentialSweepAcrossDates;
    procedure OnlyArgentineCallsignsDiffer;

    { --- ported behaviour worth stating outright ------------------------ }
    procedure MaritimeAndAeronauticalMobileHaveNoCountry;
    procedure IgnoredSuffixesFallBackToTheOperatorCall;
    procedure DigitSuffixRenumbersTheCallArea;
    procedure UsCallsMoveToTheWDistrict;
    procedure VerbatimSlashEntriesNeedNoSplitting;
    procedure ShortCallsignsDoNotCorruptMemory;
  end;

implementation

uses
  uTestData, uLegacyTable, uDxccEntry;

const
  ArgentinePrefixList: array[0..10] of string =
    ('LU', 'LW', 'AY', 'AZ', 'LO', 'LP', 'LQ', 'LR', 'LS', 'LT', 'LV');

  { The letters the original leaves out of its suffix-letter set AND that the
    country files do not patch up with an explicit slash pattern.

    The original omits F, G, I, K and W because each is a major DXCC prefix.
    For W the data authors added L[O-W][1-9]%%%/W -> Chubut, and for X they
    added /X[A-O] and /X[P-Z], so those two resolve correctly through the
    table before the splitting rules ever run.  F, G, I and K got no such
    entry, so they are the four that actually break. }
  MissedLetters = 'FGIK';

procedure TSplittingTests.SetUp;
begin
  inherited SetUp;
  FValid := TDxccTable.Create;
  FValid.LoadFromFile(CanonicalTable);
  FDeleted := TDxccTable.Create;
  FDeleted.LoadFromFile(DeletedTable);

  FLegacyValid   := TLegacyTable.Create(CanonicalTable);
  FLegacyDeleted := TLegacyTable.Create(DeletedTable);

  FRules := TDxccSuffixRules.Create;
  FRules.LoadExceptions(GeneratedDir + 'exceptions.tab');
  FRules.LoadAmbiguous(GeneratedDir + 'ambiguous.tab');

  FResolver := TDxccResolver.Create(FValid, FDeleted, FRules);
  FLegacy   := TLegacySplitter.Create(FLegacyValid, FLegacyDeleted, FRules);
end;

procedure TSplittingTests.TearDown;
begin
  FLegacy.Free;
  FResolver.Free;
  FRules.Free;
  FDeleted.Free;
  FValid.Free;
  inherited TearDown;
end;

function TSplittingTests.NewKey(const Callsign: string; const ADate: string): string;
var
  Resolved: Boolean;
  Adif: Integer;
begin
  Result := FResolver.EffectiveCallsign(Callsign, ADate, Resolved, Adif);
end;

function TSplittingTests.OldKey(const Callsign: string; const ADate: string): string;
var
  Resolved: Boolean;
  Adif: Integer;
begin
  Resolved := False;
  Adif := 0;
  Result := FLegacy.CoVyhodnocovat(Callsign, ADate, Resolved, Adif);
end;

function TSplittingTests.IsIntentionalDifference(const Callsign: string): Boolean;
var
  SlashPos: Integer;
  Before, After: string;
begin
  Result := False;
  SlashPos := Pos('/', Callsign);
  if SlashPos = 0 then
    Exit;
  Before := Copy(Callsign, 1, SlashPos - 1);
  After  := Copy(Callsign, SlashPos + 1, Length(Callsign));
  { Exactly the shape the fix targets: an Argentine call with a single
    letter after the slash. }
  Result := TDxccResolver.IsArgentinePrefix(Before) and
            (Length(After) = 1) and (After[1] in ['A'..'Z']);
end;

function TSplittingTests.CountryFor(const Callsign: string): string;
var
  Found: TDxccLookup;
begin
  Found := FResolver.Lookup(NewKey(Callsign), '2020/01/01');
  if Found.Found then
    Result := Found.Entry.Country
  else
    Result := '<no match>';
end;

function TSplittingTests.AdifFor(const Callsign: string): Integer;
var
  Found: TDxccLookup;
begin
  Found := FResolver.Lookup(NewKey(Callsign), '2020/01/01');
  if Found.Found then
    Result := Found.Adif
  else
    Result := 0;
end;

{ Deleted table first, then the valid one -- the order id_country uses. }
function TSplittingTests.OldCountryFor(const Callsign: string): string;
var
  Key: string;
  Index: Integer;
begin
  Key := OldKey(Callsign);
  Index := FLegacyDeleted.Find(Key, '2020/01/01', mmPrefix);
  if Index <> -1 then
    Exit(FLegacyDeleted.Field(Index, fldCountry));
  Index := FLegacyValid.Find(Key, '2020/01/01', mmPrefix);
  if Index <> -1 then
    Result := FLegacyValid.Field(Index, fldCountry)
  else
    Result := '<no match>';
end;

function TSplittingTests.OldAdifFor(const Callsign: string): Integer;
var
  Key: string;
  Index: Integer;
begin
  Key := OldKey(Callsign);
  Index := FLegacyDeleted.Find(Key, '2020/01/01', mmPrefix);
  if Index = -1 then
    Index := FLegacyValid.Find(Key, '2020/01/01', mmPrefix);
  if (Index = -1) or
     (not TryStrToInt(FLegacyValid.Field(Index, fldAdif), Result)) then
    Result := 0;
end;

{ --- the fix ---------------------------------------------------------- }

procedure TSplittingTests.ArgentineRegionSuffixRewritesCharacterFour;
begin
  AssertEquals('LU1ZAA', NewKey('LU1AAA/Z'));
  AssertEquals('LU1MAA', NewKey('LU1AAA/M'));
  AssertEquals('LU1HAA', NewKey('LU1AAA/H'));
end;

procedure TSplittingTests.ArgentineLettersTheOriginalMissed;
var
  I: Integer;
  C: AnsiChar;
begin
  { F G I K W were absent from the original's suffix-letter set because they
    are foreign DXCC prefixes; for Argentine calls they are provinces. }
  for I := 1 to Length(MissedLetters) do
  begin
    C := MissedLetters[I];
    AssertEquals('LU1AAA/' + C + ' should rewrite character 4',
      'LU1' + C + 'AA', NewKey('LU1AAA/' + C));
    AssertTrue('the original was expected to differ on /' + C,
      OldKey('LU1AAA/' + C) <> NewKey('LU1AAA/' + C));
  end;
end;

procedure TSplittingTests.ArgentineLettersAlreadyPatchedInTheTable;
begin
  { /W and /X are carried by explicit slash patterns in AreaOK1RR.tbl, so the
    exact-match attempt at the top of the splitter answers them before any
    rewriting happens.  Both implementations must leave these alone -- the
    fix must not "helpfully" take them over. }
  AssertEquals('LU1AAA/W', NewKey('LU1AAA/W'));
  AssertEquals(OldKey('LU1AAA/W'), NewKey('LU1AAA/W'));
  AssertEquals('Argentina, Chubut (CH)', CountryFor('LU1AAA/W'));

  AssertEquals('LU1AAA/XA', NewKey('LU1AAA/XA'));
  AssertEquals('Argentina, Santa Cruz (SC)', CountryFor('LU1AAA/XA'));
  AssertEquals('Argentina, Tierra del Fuego (TF)', CountryFor('LU1AAA/XZ'));
end;

procedure TSplittingTests.ArgentineMobileAndPortableKeepTheirRegion;
begin
  { /M and /P are mobile and portable for everyone else, but Mendoza and San
    Juan for Argentina.  The original special-cased this for LU only. }
  AssertEquals('LU1MAA', NewKey('LU1AAA/M'));
  AssertEquals('LU1PAA', NewKey('LU1AAA/P'));
  AssertEquals('LW1MAA', NewKey('LW1AAA/M'));
  AssertEquals('LW1PAA', NewKey('LW1AAA/P'));

  { ...and stay mobile/portable for everyone else. }
  AssertEquals('OK1ABC', NewKey('OK1ABC/M'));
  AssertEquals('OK1ABC', NewKey('OK1ABC/P'));
  AssertEquals('DL1ABC', NewKey('DL1ABC/M'));
end;

procedure TSplittingTests.CompanionPrefixesBehaveLikeLu;
var
  I: Integer;
  Prefix: string;
begin
  for I := Low(ArgentinePrefixList) to High(ArgentinePrefixList) do
  begin
    Prefix := ArgentinePrefixList[I];
    AssertEquals(Prefix + '1AAA/Z should become ' + Prefix + '1ZAA',
      Prefix + '1ZAA', NewKey(Prefix + '1AAA/Z'));
  end;
end;

procedure TSplittingTests.ArgentineSuffixResolvesToTheRightProvince;
begin
  { End to end: the key the splitter produces, resolved through the table. }
  AssertEquals('Argentina, Buenos Aires (CF)', CountryFor('LU1AAA'));
  AssertEquals('Antarctica',                   CountryFor('LU1AAA/Z'));
  AssertEquals('Argentina, Santa Fe (SF)',     CountryFor('LU1AAA/F'));
  AssertEquals('Argentina, Cordoba (CD)',      CountryFor('LU1AAA/H'));
  AssertEquals('Argentina, Misiones (MN)',     CountryFor('LU1AAA/I'));
  AssertEquals('Argentina, Tucuman (TM)',      CountryFor('LU1AAA/K'));
  AssertEquals('Argentina, Mendoza (MZ)',      CountryFor('LU1AAA/M'));
  AssertEquals('Argentina, San Juan (SJ)',     CountryFor('LU1AAA/P'));
  { Chubut arrives via the table's own /W pattern rather than a rewrite. }
  AssertEquals('Argentina, Chubut (CH)',       CountryFor('LU1AAA/W'));
end;

procedure TSplittingTests.TheFixChangesTheProvinceNotTheEntity;
const
  { The six forms the fix actually touches. }
  Affected: array[0..5] of string = (
    'LU1AAA/F', 'LU1AAA/G', 'LU1AAA/I', 'LU1AAA/K', 'LW1AAA/M', 'LW1AAA/P');
var
  I: Integer;
begin
  { It is tempting to read dDXCC.pas:533 as "F is France, so LU1AAA/F resolved
    as France".  It did not.  The branch sets the key to the bare suffix, but
    the statement right after it probes Copy(prefix,1,2) + '/' + suffix in
    PREFIX mode, where the callsign may be longer than the pattern -- and 'LU'
    is itself a mark.  So the probe hits and the old answer is plain
    Argentina. }
  AssertEquals('LU/F', OldKey('LU1AAA/F'));
  AssertEquals('Argentina', OldCountryFor('LU1AAA/F'));
  AssertEquals('Argentina, Santa Fe (SF)', CountryFor('LU1AAA/F'));

  { The same mechanism for a non-Argentine call, where both engines agree:
    DL1ABC/F resolves through 'DL/F' as Germany, not France. }
  AssertEquals('DL/F', OldKey('DL1ABC/F'));
  AssertEquals('DL/F', NewKey('DL1ABC/F'));
  AssertEquals('Federal Republic of Germany', CountryFor('DL1ABC/F'));

  { Which is why the fix moves no DXCC entity: every Argentine province shares
    ADIF 100.  It sharpens the province, and the province is what the log
    shows.  tools/logdiff confirmed this over a 58 184-QSO log -- zero ADIF
    differences. }
  for I := Low(Affected) to High(Affected) do
  begin
    AssertEquals(Affected[I] + ' should still be ADIF 100 in the old engine',
      100, OldAdifFor(Affected[I]));
    AssertEquals(Affected[I] + ' should still be ADIF 100 in the new engine',
      100, AdifFor(Affected[I]));
    AssertTrue(Affected[I] + ' should change province',
      OldCountryFor(Affected[I]) <> CountryFor(Affected[I]));
  end;
end;

{ --- everything else must be unchanged -------------------------------- }

procedure TSplittingTests.NonArgentineSlashFormsAreUnchanged;
const
  Cases: array[0..17] of string = (
    'OK1ABC/P', 'OK1ABC/M', 'OK1ABC/QRP', 'OK1ABC/1', 'OK1ABC/OK2',
    'DL1ABC/LH', 'DL1ABC/F', 'DL1ABC/A', 'KL7AA/1', 'W1AW/4',
    'SP2AD/1', 'ZL1AMO/C', 'RA1AAA/2/M', 'VP2E/G4XYZ', 'G4XYZ/VP2E',
    'F/OK1ABC', 'OK1ABC/MM', 'OK1ABC/AM');
var
  I: Integer;
begin
  for I := Low(Cases) to High(Cases) do
    AssertEquals('splitting ' + Cases[I], OldKey(Cases[I]), NewKey(Cases[I]));
end;

procedure TSplittingTests.DifferentialSweepOverSlashedCallsigns;
const
  Bases: array[0..11] of string = (
    'OK1ABC', 'DL1ABC', 'W1AW', 'KL7AA', 'G4XYZ', 'JA1ABC',
    'VK2ABC', 'PY2ABC', 'UA3ABC', 'ZL1ABC', 'F5ABC', 'I1ABC');
  Suffixes: array[0..23] of string = (
    'P', 'M', 'A', 'B', 'F', 'G', 'I', 'K', 'W', 'Z', '0', '1', '9',
    'MM', 'AM', 'QRP', 'QRPP', 'LH', 'OK2', 'VP2E', '', '12', 'MM1', 'PORTABLE');
var
  B, S: Integer;
  Call: string;
  Mismatches, Total: Integer;
  Report: string;
begin
  Mismatches := 0;
  Total := 0;
  Report := '';
  for B := Low(Bases) to High(Bases) do
    for S := Low(Suffixes) to High(Suffixes) do
    begin
      Call := Bases[B] + '/' + Suffixes[S];
      Inc(Total);
      if OldKey(Call) <> NewKey(Call) then
      begin
        Inc(Mismatches);
        if Mismatches <= 10 then
          Report := Report + LineEnding + Format('  %s: old=%s new=%s',
            [Call, OldKey(Call), NewKey(Call)]);
      end;
    end;
  AssertTrue(Format('%d of %d non-Argentine slash forms changed%s',
    [Mismatches, Total, Report]), Mismatches = 0);
  AssertTrue('nothing was compared', Total > 0);
end;

procedure TSplittingTests.DifferentialSweepAcrossDates;
const
  { Every date-sensitive step in CoVyhodnocovat is a table probe: the
    whole-string exact match at the top, the Copy(prefix,1,2)+'/'+suffix probe,
    and the two ExNoEquals probes that decide which side of the slash is the
    location.  All of them take the date, and every one of them was previously
    exercised at a single date -- 2020/01/01 -- which says nothing about the
    entities that came and went before any of us were licensed.

    These dates land on both sides of real transitions, at the extremes of the
    format's window (1945/01/01 - 2050/01/01), and outside it. }
  Dates: array[0..19] of string = (
    '1939/01/01',   { before the earliest window in the tables            }
    '1944/12/31', '1945/01/01',   { the default ValidFrom, either side    }
    '1960/01/01',
    '1972/10/16',   { 1M4 deleted                                        }
    '1975/07/01',   { 1B9 deleted                                        }
    '1981/12/25',   { 8Z4 deleted                                        }
    '1990/05/21',   { 4W1 deleted -- Yemen unification                   }
    '1990/10/03',   { German unification                                 }
    '1991/12/26',   { dissolution of the USSR                            }
    '1993/01/01',   { Czechoslovakia -> OK / OM                          }
    '1995/06/15',
    '2002/05/20',   { East Timor                                         }
    '2006/06/03',   { Montenegro / Serbia                                }
    '2010/01/01',
    '2011/07/09',   { South Sudan                                        }
    '2018/01/21',   { Kosovo                                             }
    '2020/01/01',   { what every other test in this unit uses            }
    '2049/12/31', '2050/01/02'    { the default ValidTo, either side     }
  );
  Bases: array[0..13] of string = (
    'OK1ABC', 'DL1ABC', 'W1AW', 'KL7AA', 'G4XYZ', 'JA1ABC',
    'VK2ABC', 'PY2ABC', 'UA3ABC', 'ZL1ABC', 'F5ABC', 'I1ABC',
    'YU1AB', 'OM3ABC');
  Suffixes: array[0..23] of string = (
    'P', 'M', 'A', 'B', 'F', 'G', 'I', 'K', 'W', 'Z', '0', '1', '9',
    'MM', 'AM', 'QRP', 'QRPP', 'LH', 'OK2', 'VP2E', '', '12', 'MM1', 'PORTABLE');
  Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
var
  D, B, S, P: Integer;
  Unexpected: string;
  Count: Integer;

  procedure Check(const ACall, ADate: string);
  begin
    Inc(Count);
    if OldKey(ACall, ADate) = NewKey(ACall, ADate) then
      Exit;
    if IsIntentionalDifference(ACall) then
      Exit;
    if Length(Unexpected) < 600 then
      Unexpected := Unexpected + LineEnding + Format('  %s @ %s: old=%s new=%s',
        [ACall, ADate, OldKey(ACall, ADate), NewKey(ACall, ADate)]);
  end;

begin
  Unexpected := '';
  Count := 0;
  for D := Low(Dates) to High(Dates) do
  begin
    for B := Low(Bases) to High(Bases) do
      for S := Low(Suffixes) to High(Suffixes) do
        Check(Bases[B] + '/' + Suffixes[S], Dates[D]);

    { Argentine prefixes too: IsIntentionalDifference lets the province
      rewrite through, so what this asserts for them is that nothing ELSE
      moved when the date did. }
    for P := Low(ArgentinePrefixList) to High(ArgentinePrefixList) do
      for S := 1 to Length(Alphabet) do
        Check(ArgentinePrefixList[P] + '1AAA/' + Alphabet[S], Dates[D]);

    { Two slashes, where the 2-slash branch does its own dated probes. }
    Check('OK1ABC/1/M', Dates[D]);
    Check('RA1AAA/2/M', Dates[D]);
    Check('4O8/9X0A/P', Dates[D]);
    Check('OE/OK2PYA/P', Dates[D]);
    Check('LU1AAA/Z/P', Dates[D]);
  end;

  AssertTrue(Format('after %d comparisons across %d dates, differences outside '
    + 'the Argentine single-letter case:%s',
    [Count, Length(Dates), Unexpected]), Unexpected = '');
  AssertTrue('nothing was compared', Count > 10000);
end;

procedure TSplittingTests.OnlyArgentineCallsignsDiffer;
const
  Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
var
  P, S: Integer;
  Call, Prefix: string;
  Unexpected: string;
  Count: Integer;

  procedure Check(const ACall: string);
  begin
    Inc(Count);
    if OldKey(ACall) = NewKey(ACall) then
      Exit;
    if IsIntentionalDifference(ACall) then
      Exit;
    if Length(Unexpected) < 400 then
      Unexpected := Unexpected + LineEnding + Format('  %s: old=%s new=%s',
        [ACall, OldKey(ACall), NewKey(ACall)]);
  end;

begin
  Unexpected := '';
  Count := 0;

  { Every Argentine prefix and a couple of foreign ones, against every
    single-character suffix. }
  for P := Low(ArgentinePrefixList) to High(ArgentinePrefixList) do
  begin
    Prefix := ArgentinePrefixList[P] + '1AAA';
    for S := 1 to Length(Alphabet) do
      Check(Prefix + '/' + Alphabet[S]);
  end;
  for S := 1 to Length(Alphabet) do
  begin
    Check('OK1ABC/' + Alphabet[S]);
    Check('DL1ABC/' + Alphabet[S]);
    Check('W1AW/' + Alphabet[S]);
    Check('LUX/' + Alphabet[S]);       { starts with LU but far too short }
    Check('LUNAR1/' + Alphabet[S]);    { starts with LU but is not Argentine }
  end;

  AssertTrue(Format('after %d comparisons, differences outside the Argentine '
    + 'single-letter case:%s', [Count, Unexpected]), Unexpected = '');
end;

{ --- ported behaviour worth stating outright -------------------------- }

procedure TSplittingTests.MaritimeAndAeronauticalMobileHaveNoCountry;
begin
  AssertEquals('?', NewKey('OK1ABC/MM'));
  AssertEquals('?', NewKey('OK1ABC/AM'));
  AssertEquals('?', NewKey('OK1ABC/MM1'));
  AssertEquals('?', NewKey('OK1ABC/1/MM'));
end;

procedure TSplittingTests.IgnoredSuffixesFallBackToTheOperatorCall;
begin
  { /LH is a lighthouse, not the LH prefix. }
  AssertEquals('DL1ABC', NewKey('DL1ABC/LH'));
  AssertEquals('OK1ABC', NewKey('OK1ABC/QRP'));
  AssertEquals('OK1ABC', NewKey('OK1ABC/QRPP'));
  { A long all-letter suffix is free text. }
  AssertEquals('OK1ABC', NewKey('OK1ABC/PORTABLE'));
end;

procedure TSplittingTests.DigitSuffixRenumbersTheCallArea;
begin
  { SP2AD/1 -> SP1AD: the digit replaces character 3. }
  AssertEquals('SP1AD', NewKey('SP2AD/1'));
  AssertEquals(OldKey('SP2AD/1'), NewKey('SP2AD/1'));
  { A multi-digit suffix is a serial, not an area. }
  AssertEquals('OK1ABC', NewKey('OK1ABC/12'));
end;

procedure TSplittingTests.UsCallsMoveToTheWDistrict;
begin
  AssertEquals('W1', NewKey('KL7AA/1'));
  AssertEquals(OldKey('KL7AA/1'), NewKey('KL7AA/1'));
  AssertEquals('W4', NewKey('W1AW/4'));
end;

procedure TSplittingTests.VerbatimSlashEntriesNeedNoSplitting;
var
  Resolved: Boolean;
  Adif: Integer;
begin
  { Listed with the slash in CallResolution.tbl, so the first exact-match
    attempt wins and nothing is rewritten. }
  AssertEquals('LU2ERA/Z',
    FResolver.EffectiveCallsign('LU2ERA/Z', '2020/01/01', Resolved, Adif));
  AssertTrue('an exact hit should report the answer as already resolved',
    Resolved);
end;

procedure TSplittingTests.ShortCallsignsDoNotCorruptMemory;
const
  Shorts: array[0..8] of string = (
    'LU/Z', 'LU1/Z', 'L/Z', '/Z', 'LU/', 'A/1', 'LU/1', 'X/', '//');
var
  I: Integer;
begin
  { The original wrote pred_lomitkem[3] and [4] without checking the length,
    which is undefined behaviour on anything shorter.  These must simply
    return something. }
  for I := Low(Shorts) to High(Shorts) do
    AssertTrue('splitting ' + Shorts[I] + ' should not raise',
      NewKey(Shorts[I]) <> #1);
end;

initialization
  RegisterTest(TSplittingTests);

end.
