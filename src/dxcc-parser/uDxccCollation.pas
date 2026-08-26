(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The collation the DXCC table index is sorted by.  Replaces odbec.pas.

  This is a load-bearing ordering, not a cosmetic one.  TDxccTable.Find locates
  patterns whose second character is a metacharacter by scanning the single
  range  firstchar + '['  ..  firstchar + '?'.  That one scan covers all five
  metacharacters only because '[' ']' '%' '#' '?' are given five consecutive
  ranks, placed above every alphanumeric.  Reorder them and DXCC resolution
  changes with no other symptom.

  The mapping is identical to odbec's, byte for byte, including the quirk
  noted at HighestScannedRank. }

unit uDxccCollation;

{$mode objfpc}{$H+}

interface

{ Collation rank of a single byte: its position in the sort alphabet. }
function CollationRank(C: AnsiChar): Byte;

{ The sort key for a mark.  A leading '=' -- the exact-match marker -- is
  dropped first, so '=OK1ABC' and 'OK1ABC' sort to the same place and compete
  with each other during a scan. }
function SortKey(const S: string): string;

implementation

const
  { Printable characters in sort order.  Everything below 32 and above 126
    keeps its own value.  Note where the five metacharacters live: at the very
    top, together, which is the entire point of this table. }
  PrintableOrder =
    ' !"$&' + #39 + '()*+,-/0123456789:;<=>@ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
    '\^_`abcdefghijklmnopqrstuvwxyz{|}~.[]%#?';

  FirstPrintable = 32;
  LastPrintable  = 126;

  { odbec.pas:68 scans with 'x < 254' where 255 was meant, so byte #255 never
    finds itself and falls out of the loop at 254 -- the same rank as #254.
    Reproduced deliberately: the tables are ASCII, so nothing observable
    depends on it, but "nothing observable" is a claim the tests get to make,
    not an assumption made here. }
  HighestScannedRank = 254;

var
  { Rank by byte value.  Built once at unit initialisation and read-only
    afterwards, so it is safe to share across threads. }
  RankOf: array[Byte] of Byte;

function CollationRank(C: AnsiChar): Byte;
begin
  Result := RankOf[Ord(C)];
end;

function SortKey(const S: string): string;
var
  I, First, Len: Integer;
begin
  First := 1;
  if (Length(S) > 0) and (S[1] = '=') then
    First := 2;
  Len := Length(S) - First + 1;
  SetLength(Result, Len);
  for I := 1 to Len do
    Result[I] := Chr(RankOf[Ord(S[First + I - 1])]);
end;

procedure BuildRankTable;
var
  Alphabet: array[Byte] of AnsiChar;
  Code, Rank: Integer;
begin
  { The sort alphabet: identity outside the printable range, PrintableOrder
    within it. }
  for Code := 0 to 255 do
    Alphabet[Code] := Chr(Code);
  for Rank := FirstPrintable to LastPrintable do
    Alphabet[Rank] := PrintableOrder[Rank - FirstPrintable + 1];

  { Invert it, with odbec's scan bound preserved. }
  for Code := 0 to 255 do
  begin
    Rank := 0;
    while (Alphabet[Rank] <> Chr(Code)) and (Rank < HighestScannedRank) do
      Inc(Rank);
    RankOf[Code] := Rank;
  end;
end;

initialization
  BuildRankTable;

end.
