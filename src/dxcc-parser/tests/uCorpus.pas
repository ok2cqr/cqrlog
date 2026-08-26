(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Callsign corpora for the differential test.

  Everything here is derived from the DXCC tables themselves, or generated
  systematically.  Nothing is read from lotw1.txt, eqsl.txt or MASTER.SCP:
  those are LoTW/eQSL membership lists and play no part in resolving a
  callsign to a country, so they would only add bulk.

  Three sources, for three kinds of coverage:

    derived   one concrete callsign per pattern in the table, with the
              metacharacters filled in several ways.  This is the important
              one: it guarantees every single entry is exercised, including
              rare and deleted entities that real traffic may not touch for
              years.

    swept     every plausible short callsign shape, whether or not the table
              has an entry for it.  Catches disagreements about what should
              NOT match, which the derived corpus cannot see.

    edge      shapes that have no business reaching the parser but sometimes
              do -- empty, over-long, lowercase, punctuation. }

unit uCorpus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uDxccTableIntf;

{ Concrete callsigns covering every pattern in Table. }
function DerivedCallsigns(Table: IDxccTable): TStringList;

{ A systematic sweep of short callsign shapes. }
function SweptCallsigns: TStringList;

{ Shapes that must not behave differently between the two engines. }
function EdgeCaseCallsigns: TStringList;

{ Turns one pattern into a concrete callsign.  Variant selects which way each
  metacharacter is filled in; see the implementation for what each does. }
function ConcreteFromPattern(const Pattern: string; Variant: Integer): string;

const
  { How many ways each metacharacter is filled in.  Two already gives both
    ends of every range and both ends of the digit set; more mostly produces
    duplicates once the list is deduplicated, at real cost to run time. }
  PatternVariants = 2;

implementation

uses
  uDxccLimits;

{ Picks a character satisfying the class body Body (the text between the
  brackets), honouring ranges.  Variant 0 takes the first possibility,
  variant 1 the last, others something in between. }
function PickFromClass(const Body: string; Variant: Integer): AnsiChar;
var
  Members: string;
  I: Integer;
  C: AnsiChar;
begin
  Members := '';
  I := 1;
  while I <= Length(Body) do
  begin
    if (Body[I] = '-') and (I > 1) and (I < Length(Body)) then
    begin
      { A range: expand it, skipping the endpoints already recorded. }
      C := Body[I - 1];
      while C < Body[I + 1] do
      begin
        Inc(C);
        Members := Members + C;
      end;
      Inc(I, 2);
    end
    else
    begin
      if Body[I] <> '-' then
        Members := Members + Body[I];
      Inc(I);
    end;
  end;

  if Members = '' then
    Exit('A');

  case Variant of
    0: Result := Members[1];
    1: Result := Members[Length(Members)];
    2: Result := Members[(Length(Members) + 1) div 2];
  else
    Result := Members[1 + (Length(Members) - 1) * 2 div 3];
  end;
end;

function ConcreteFromPattern(const Pattern: string; Variant: Integer): string;
const
  Digits:   array[0..3] of AnsiChar = ('0', '9', '5', '1');
  AnyChars: array[0..3] of AnsiChar = ('A', 'Z', '0', 'Q');
var
  P, Len, ClassEnd: Integer;
begin
  Result := '';
  Len := Length(Pattern);

  { An '=' entry is already a literal callsign. }
  if (Len > 0) and (Pattern[1] = '=') then
    Exit(Copy(Pattern, 2, Len));

  P := 1;
  while P <= Len do
  begin
    case Pattern[P] of
      '#':
        Result := Result + Digits[Variant mod Length(Digits)];
      '%', '?':
        Result := Result + AnyChars[Variant mod Length(AnyChars)];
      '[':
        begin
          ClassEnd := P + 1;
          while (ClassEnd <= Len) and (Pattern[ClassEnd] <> ']') do
            Inc(ClassEnd);
          Result := Result +
            PickFromClass(Copy(Pattern, P + 1, ClassEnd - P - 1), Variant);
          P := ClassEnd;
        end;
      ']':
        { A stray closing bracket matches as a literal; 182 real patterns
          carry one, e.g. R[A-Z]]0A. }
        Result := Result + ']';
    else
      Result := Result + Pattern[P];
    end;
    Inc(P);
  end;
end;

function DerivedCallsigns(Table: IDxccTable): TStringList;
var
  I, V: Integer;
  Call: string;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
  Result.Duplicates := dupIgnore;
  for I := 0 to Table.Count - 1 do
    for V := 0 to PatternVariants - 1 do
    begin
      Call := ConcreteFromPattern(Table.Pattern(I), V);
      if Call = '' then
        Continue;
      Result.Add(Call);
      { One character longer, so prefix matching is exercised alongside
        exact-length matching. }
      if Length(Call) < MaxMarkLength then
        Result.Add(Call + 'X');
      { One character shorter, so "callsign too short for this pattern" is
        exercised too. }
      if Length(Call) > 1 then
        Result.Add(Copy(Call, 1, Length(Call) - 1));
    end;
end;

function SweptCallsigns: TStringList;
const
  Alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
var
  I, J: Integer;
  Prefix: string;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
  Result.Duplicates := dupIgnore;
  for I := 1 to Length(Alphabet) do
  begin
    { Every single character. }
    Result.Add(Alphabet[I]);
    for J := 1 to Length(Alphabet) do
    begin
      Prefix := Alphabet[I] + Alphabet[J];
      { Every two-character prefix, bare and in the two shapes a real
        callsign takes. }
      Result.Add(Prefix);
      Result.Add(Prefix + '1AA');
      Result.Add(Prefix + '9ZZ');
      Result.Add(Prefix + '1AA/P');
    end;
  end;
end;

function EdgeCaseCallsigns: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('');
  Result.Add(' ');
  Result.Add('/');
  Result.Add('//');
  Result.Add('-');
  Result.Add('=');
  Result.Add('?');
  Result.Add('#');
  Result.Add('%');
  Result.Add('[');
  Result.Add(']');
  Result.Add('[]');
  Result.Add('=OK1ABC');
  Result.Add('O');
  Result.Add('0');
  Result.Add('OK');
  Result.Add('ok1abc');
  Result.Add('OK1ABC');
  Result.Add('OK1ABC/P');
  Result.Add('OK1ABC/QRP');
  Result.Add('OK1ABC/1');
  Result.Add('OK1A/BA0AX');
  Result.Add('/OK1ABC');
  Result.Add('OK1ABC/');
  Result.Add('zz9zz');
  Result.Add(StringOfChar('O', MaxMarkLength - 1));
  Result.Add(StringOfChar('O', MaxMarkLength));
  Result.Add(StringOfChar('O', MaxMarkLength + 1));
  Result.Add(StringOfChar('O', MaxMarkLength + 20));
  Result.Add('OK1ABC' + StringOfChar('X', 60));
  Result.Add(#1#2#3);
end;

end.
