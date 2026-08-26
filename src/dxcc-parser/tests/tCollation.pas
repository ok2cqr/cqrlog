(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Characterisation of odbec, the custom collation the table index is sorted by.

  This is not a cosmetic ordering.  najdis_s2 finds patterns whose second
  character is a metacharacter by scanning the single range
  firstchar+'[' .. firstchar+'?' (znacmech.pas:947-950).  That works only
  because '[' ']' '%' '#' '?' occupy five consecutive ranks, above every
  alphanumeric -- which is exactly what odbec.pas:40 arranges, with the comment
  "specialni reg. znaky. je treba mit pohromade".

  Change this ordering and DXCC resolution silently changes with it, so the
  whole 256-byte mapping is pinned here byte for byte. }

unit tCollation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry;

type
  TCollationTests = class(TTestCase)
  private
    function Rank(C: AnsiChar): Integer;
    function SortKey(const S: string): string;
  published
    procedure WholeMappingIsUnchanged;
    procedure PrintableCharactersAreInTheExpectedOrder;

    procedure MetacharactersAreContiguous;
    procedure MetacharactersOutrankEveryAlphanumeric;
    procedure DigitsSortBelowLetters;
    procedure LowercaseOutranksUppercase;

    procedure SortKeyStripsALeadingEquals;
    procedure SortKeyOfEmptyStringIsEmpty;
    procedure SortKeyOfLoneEqualsIsEmpty;
    procedure SortKeyPreservesLength;
    procedure SortKeyOrdersLikeTheRanks;

    procedure HighBytesCollapseOntoOneRank;
  end;

implementation

uses
  odbec;

const
  { chr2bec for bytes 0..255, produced by tools/dumpcollation --hex. }
  ExpectedMapping =
    '000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F' +
    '2021227D237C2425262728292A2B792C2D2E2F303132333435363738393A3B7E' +
    '3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455567A577B5859' +
    '5A5B5C5D5E5F606162636465666768696A6B6C6D6E6F7071727374757677787F' +
    '808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9F' +
    'A0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF' +
    'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDF' +
    'E0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFE';

  { All printable characters, lowest rank first. }
  ExpectedOrder =
    ' !"$&' + #39 + '()*+,-/0123456789:;<=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
    '\^_`abcdefghijklmnopqrstuvwxyz{|}~.[]%#?';

function TCollationTests.Rank(C: AnsiChar): Integer;
begin
  Result := Ord(chr2bec(C));
end;

function TCollationTests.SortKey(const S: string): string;
var
  Short: ShortString;
begin
  { string2bec takes a var shortstring, so the value needs a typed local. }
  Short := S;
  Result := string2bec(Short);
end;

procedure TCollationTests.WholeMappingIsUnchanged;
var
  I: Integer;
  Actual: string;
begin
  Actual := '';
  for I := 0 to 255 do
    Actual := Actual + IntToHex(Rank(Chr(I)), 2);
  AssertEquals('the collation mapping must not drift', ExpectedMapping, Actual);
end;

procedure TCollationTests.PrintableCharactersAreInTheExpectedOrder;
var
  I: Integer;
  Sorted: string;
  C: AnsiChar;
  Best: Integer;
  Used: array[32..126] of Boolean;
  J, BestIdx: Integer;
begin
  { Selection-sort the printable range by rank, then compare with the
    documented order. }
  FillChar(Used, SizeOf(Used), 0);
  Sorted := '';
  for I := 32 to 126 do
  begin
    Best := MaxInt;
    BestIdx := -1;
    for J := 32 to 126 do
      if (not Used[J]) and (Rank(Chr(J)) < Best) then
      begin
        Best := Rank(Chr(J));
        BestIdx := J;
      end;
    Used[BestIdx] := True;
    C := Chr(BestIdx);
    Sorted := Sorted + C;
  end;
  AssertEquals(ExpectedOrder, Sorted);
end;

procedure TCollationTests.MetacharactersAreContiguous;
begin
  { The five characters najdis_s2's second scan depends on. }
  AssertEquals('[', 122, Rank('['));
  AssertEquals(']', 123, Rank(']'));
  AssertEquals('%', 124, Rank('%'));
  AssertEquals('#', 125, Rank('#'));
  AssertEquals('?', 126, Rank('?'));
end;

procedure TCollationTests.MetacharactersOutrankEveryAlphanumeric;
var
  C: AnsiChar;
begin
  for C := '0' to '9' do
    AssertTrue(C + ' must rank below [', Rank(C) < Rank('['));
  for C := 'A' to 'Z' do
    AssertTrue(C + ' must rank below [', Rank(C) < Rank('['));
  for C := 'a' to 'z' do
    AssertTrue(C + ' must rank below [', Rank(C) < Rank('['));
end;

procedure TCollationTests.DigitsSortBelowLetters;
begin
  AssertTrue(Rank('9') < Rank('A'));
end;

procedure TCollationTests.LowercaseOutranksUppercase;
begin
  { Why a lowercase callsign is the shape most likely to run the search index
    off the end of the table; see tRobustness. }
  AssertTrue(Rank('Z') < Rank('a'));
end;

procedure TCollationTests.SortKeyStripsALeadingEquals;
begin
  { Exact-match entries must sort next to the patterns they compete with, so
    the '=' marker is dropped before the key is built. }
  AssertEquals(SortKey('OK1ABC'), SortKey('=OK1ABC'));
end;

procedure TCollationTests.SortKeyOfEmptyStringIsEmpty;
begin
  AssertEquals(0, Length(SortKey('')));
end;

procedure TCollationTests.SortKeyOfLoneEqualsIsEmpty;
begin
  AssertEquals(0, Length(SortKey('=')));
end;

procedure TCollationTests.SortKeyPreservesLength;
begin
  AssertEquals(6, Length(SortKey('OK1ABC')));
  AssertEquals('the = is dropped, so the key is one shorter',
    6, Length(SortKey('=OK1ABC')));
end;

procedure TCollationTests.SortKeyOrdersLikeTheRanks;
begin
  AssertTrue('OK sorts before O[',   SortKey('OK') < SortKey('O['));
  AssertTrue('O[ sorts before O?',   SortKey('O[') < SortKey('O?'));
  AssertTrue('OZ sorts before Oa',   SortKey('OZ') < SortKey('Oa'));
  AssertTrue('O9 sorts before OA',   SortKey('O9') < SortKey('OA'));
end;

procedure TCollationTests.HighBytesCollapseOntoOneRank;
begin
  { pripravbec scans with 'x < 254' where 255 was meant (odbec.pas:68), so the
    last two bytes end up sharing rank 254.  Harmless for the ASCII data the
    tables actually contain, but it is behaviour, so it is pinned. }
  AssertEquals(254, Rank(#254));
  AssertEquals(254, Rank(#255));
  AssertEquals('the two highest bytes are indistinguishable after collation',
    Rank(#254), Rank(#255));
end;

initialization
  RegisterTest(TCollationTests);

end.
