(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Characterisation of the pattern matcher (legacy: Tseznam.pasuje /
  uznejregex2 / delkaznacky / presnejsivyznam).

  Those helpers are private to znacmech, so everything here goes through the
  public Find, which is also the only surface dDXCC uses.  That is deliberate:
  the contract that must not change is the one the callers can see. }

unit tPattern;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uDxccTableIntf, uDxccTestBase;

type
  TPatternTests = class(TDxccTableTestCase)
  published
    { --- literals ------------------------------------------------------- }
    procedure LiteralExact;
    procedure LiteralIsAPrefixMatch;
    procedure CallsignShorterThanPatternDoesNotMatch;
    procedure LiteralMismatch;

    { --- '#' digit class ------------------------------------------------ }
    procedure HashMatchesDigit;
    procedure HashRejectsLetter;

    { --- '%' and '?' any-character -------------------------------------- }
    procedure PercentMatchesLetter;
    procedure PercentMatchesDigit;
    procedure QuestionMatchesLetter;
    procedure QuestionMatchesDigit;

    { --- '[...]' character classes -------------------------------------- }
    procedure RangeClassMatchesInside;
    procedure RangeClassRejectsOutside;
    procedure RangeClassMatchesBothBounds;
    procedure EnumClassMatches;
    procedure EnumClassRejectsOutside;
    procedure MixedClassMatchesRangeAndLiteral;
    procedure ReversedRangeMatchesNothingInBetween;
    procedure ClassCountsAsOneCharacter;

    { --- '=' exact-match entries ---------------------------------------- }
    procedure EqualsRequiresWholeCallsign;
    procedure EqualsRejectsLongerCallsign;
    procedure EqualsRejectsShorterCallsign;

    { --- match modes ---------------------------------------------------- }
    procedure PrefixModeAllowsLongerCallsign;
    procedure ExactModeRejectsLongerCallsign;
    procedure ExactModeAcceptsEqualEffectiveLength;
    procedure ExactNoEqualsIgnoresEqualsEntries;
    procedure ExactNoEqualsStillFindsPatterns;

    { --- winner selection ----------------------------------------------- }
    procedure LongerPatternWins;
    procedure ExactEntryBeatsPattern;
    procedure LiteralBeatsMetacharacter;
    procedure EarlierInCollationWinsTie;

    { --- reachability of the range scan ---------------------------------- }
    procedure WildcardInSecondPositionIsReachable;
  end;

  TLegacyPatternTests = class(TPatternTests)
  protected
    function NewTable(const FileName: string): IDxccTable; override;
  end;

  TModernPatternTests = class(TPatternTests)
  protected
    function NewTable(const FileName: string): IDxccTable; override;
  end;

implementation

uses
  uLegacyTable, uModernTable;

function TLegacyPatternTests.NewTable(const FileName: string): IDxccTable;
begin
  Result := TLegacyTable.Create(FileName);
end;

function TModernPatternTests.NewTable(const FileName: string): IDxccTable;
begin
  Result := TModernTable.Create(FileName);
end;

{ --- literals --------------------------------------------------------- }

procedure TPatternTests.LiteralExact;
begin
  AssertMatches('OK', 'OK');
end;

procedure TPatternTests.LiteralIsAPrefixMatch;
begin
  { A pattern may be shorter than the callsign; this is how prefixes work. }
  AssertMatches('OK', 'OK1ABC');
end;

procedure TPatternTests.CallsignShorterThanPatternDoesNotMatch;
begin
  AssertNoMatch('OK1', 'OK');
end;

procedure TPatternTests.LiteralMismatch;
begin
  AssertNoMatch('OK', 'DL');
end;

{ --- '#' digit class -------------------------------------------------- }

procedure TPatternTests.HashMatchesDigit;
begin
  AssertMatches('OK#', 'OK1');
end;

procedure TPatternTests.HashRejectsLetter;
begin
  AssertNoMatch('OK#', 'OKA');
end;

{ --- '%' and '?' any-character ---------------------------------------- }

procedure TPatternTests.PercentMatchesLetter;
begin
  AssertMatches('OK%', 'OKA');
end;

procedure TPatternTests.PercentMatchesDigit;
begin
  AssertMatches('OK%', 'OK1');
end;

procedure TPatternTests.QuestionMatchesLetter;
begin
  AssertMatches('OK?', 'OKA');
end;

procedure TPatternTests.QuestionMatchesDigit;
begin
  AssertMatches('OK?', 'OK1');
end;

{ --- '[...]' character classes ---------------------------------------- }

procedure TPatternTests.RangeClassMatchesInside;
begin
  AssertMatches('OK[A-C]', 'OKB');
end;

procedure TPatternTests.RangeClassRejectsOutside;
begin
  AssertNoMatch('OK[A-C]', 'OKD');
end;

procedure TPatternTests.RangeClassMatchesBothBounds;
begin
  AssertMatches('OK[A-C]', 'OKA');
  AssertMatches('OK[A-C]', 'OKC');
end;

procedure TPatternTests.EnumClassMatches;
begin
  AssertMatches('OK[XYZ]', 'OKY');
end;

procedure TPatternTests.EnumClassRejectsOutside;
begin
  AssertNoMatch('OK[XYZ]', 'OKW');
end;

procedure TPatternTests.MixedClassMatchesRangeAndLiteral;
begin
  { Real data uses this shape, e.g. B[A-LRSTYZ] in the China entries. }
  AssertMatches('OK[A-CXZ]', 'OKB');
  AssertMatches('OK[A-CXZ]', 'OKX');
  AssertMatches('OK[A-CXZ]', 'OKZ');
  AssertNoMatch('OK[A-CXZ]', 'OKY');
end;

procedure TPatternTests.ReversedRangeMatchesNothingInBetween;
begin
  { 'C-A' is an empty range; only the literal endpoints can still match. }
  AssertNoMatch('OK[C-A]', 'OKB');
end;

procedure TPatternTests.ClassCountsAsOneCharacter;
begin
  { A whole [..] class consumes exactly one callsign character, so this
    pattern has effective length 3 and matches a 3-character callsign in
    exact mode. }
  AssertTrue('[A-C] should count as one character',
    MatchesMode('OK[A-C]', 'OKB', mmExact));
end;

{ --- '=' exact-match entries ------------------------------------------ }

procedure TPatternTests.EqualsRequiresWholeCallsign;
begin
  AssertMatches('=OK1ABC', 'OK1ABC');
end;

procedure TPatternTests.EqualsRejectsLongerCallsign;
begin
  AssertNoMatch('=OK1ABC', 'OK1ABCD');
end;

procedure TPatternTests.EqualsRejectsShorterCallsign;
begin
  AssertNoMatch('=OK1ABC', 'OK1AB');
end;

{ --- match modes ------------------------------------------------------ }

procedure TPatternTests.PrefixModeAllowsLongerCallsign;
begin
  AssertTrue(MatchesMode('OK', 'OK1ABC', mmPrefix));
end;

procedure TPatternTests.ExactModeRejectsLongerCallsign;
begin
  AssertFalse(MatchesMode('OK', 'OK1ABC', mmExact));
end;

procedure TPatternTests.ExactModeAcceptsEqualEffectiveLength;
begin
  AssertTrue(MatchesMode('OK1', 'OK1', mmExact));
end;

procedure TPatternTests.ExactNoEqualsIgnoresEqualsEntries;
begin
  { This is the whole point of the third mode: skip '=' exact entries. }
  AssertTrue('=entry is found in exact mode',
    MatchesMode('=OK1ABC', 'OK1ABC', mmExact));
  AssertFalse('=entry must be skipped in exact-no-equals mode',
    MatchesMode('=OK1ABC', 'OK1ABC', mmExactNoEquals));
end;

procedure TPatternTests.ExactNoEqualsStillFindsPatterns;
begin
  AssertTrue(MatchesMode('OK1', 'OK1', mmExactNoEquals));
end;

{ --- winner selection ------------------------------------------------- }

procedure TPatternTests.LongerPatternWins;
var
  T: IDxccTable;
  Found: Integer;
begin
  T := BuildTable([
    'OK'   + StockDescription,
    'OK1'  + StockDescription
  ]);
  Found := T.Find('OK1ABC', '*', mmPrefix);
  AssertTrue('something should match', Found >= 0);
  AssertEquals('the longer pattern must win', 'OK1', T.Pattern(Found));
end;

procedure TPatternTests.ExactEntryBeatsPattern;
var
  T: IDxccTable;
  Found: Integer;
begin
  T := BuildTable([
    'OK1'      + StockDescription,
    '=OK1ABC'  + StockDescription
  ]);
  Found := T.Find('OK1ABC', '*', mmPrefix);
  AssertTrue('something should match', Found >= 0);
  AssertEquals('the = entry must win outright', '=OK1ABC', T.Pattern(Found));
end;

procedure TPatternTests.LiteralBeatsMetacharacter;
var
  T: IDxccTable;
  Found: Integer;
begin
  T := BuildTable([
    'OK%X' + StockDescription,
    'OK1X' + StockDescription
  ]);
  { Same effective length, so specificity decides: presnejsivyznam treats a
    literal as more specific than any metacharacter. }
  Found := T.Find('OK1X', '*', mmPrefix);
  AssertTrue('something should match', Found >= 0);
  AssertEquals('the literal must win', 'OK1X', T.Pattern(Found));
end;

procedure TPatternTests.EarlierInCollationWinsTie;
var
  T: IDxccTable;
  Found: Integer;
begin
  T := BuildTable([
    'OK#X' + StockDescription,
    'OK%X' + StockDescription
  ]);
  { '#' and '%' are equally specific -- presnejsivyznam lumps
    [ ] # % ? together as "metacharacter" and does not rank them against each
    other.  So neither can displace the other, and the one the scan reaches
    first wins.  The scan runs in collation order, where '%' (rank 124)
    precedes '#' (rank 125), regardless of the order in the source file. }
  Found := T.Find('OK1X', '*', mmPrefix);
  AssertTrue('something should match', Found >= 0);
  AssertEquals('the earlier pattern in collation order must win',
    'OK%X', T.Pattern(Found));
end;

{ --- reachability of the range scan ----------------------------------- }

procedure TPatternTests.WildcardInSecondPositionIsReachable;
begin
  { najdis_s2 runs a second range scan over first-char + [ .. first-char + ?
    precisely so that patterns whose second character is a metacharacter are
    still found.  This only works because odbec's collation keeps
    [ ] % # ? adjacent. }
  AssertMatches('O#1', 'O11');
  AssertMatches('O[A-C]1', 'OB1');
  AssertMatches('O%1', 'OX1');
end;

initialization
  RegisterTest(TLegacyPatternTests);
  RegisterTest(TModernPatternTests);

end.
