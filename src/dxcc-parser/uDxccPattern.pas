(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Matching a callsign against a DXCC table pattern.  Replaces the private
  helpers pasuje / uznejregex2 / delkaznacky / presnejsivyznam in znacmech.

  Pattern syntax, as the country files use it:

    literal   matches itself
    #         one digit
    %  ?      any one character
    [ABC]     one of the listed characters
    [A-C]     one character in the range; ranges and literals may be mixed,
              e.g. [A-LRSTYZ], and a '-' with nothing usable before it is
              simply a literal '-'
    =...      the rest must equal the whole callsign, not merely prefix it

  A pattern shorter than the callsign still matches -- that is what makes
  prefix resolution work.  A pattern longer than the callsign never does.

  Everything here is a pure function over its arguments, so it is inherently
  reentrant and safe to call from several threads at once. }

unit uDxccPattern;

{$mode objfpc}{$H+}

interface

const
  ExactMarker = '=';
  Metacharacters = ['[', ']', '#', '%', '?'];

{ Does Callsign satisfy Pattern? }
function PatternMatches(const Pattern, Callsign: string): Boolean;

{ Does C satisfy the character class that starts at Pattern[ClassStart]
  (which must be the '[')? }
function MatchesCharClass(const Pattern: string; ClassStart: Integer;
  C: AnsiChar): Boolean;

{ How many callsign characters Pattern consumes: a whole [...] class counts
  as one, and a leading '=' as none.  This is the length two candidate
  patterns are ranked by. }
function PatternLength(const Pattern: string): Integer;

{ Is NewPattern a more specific description than OldPattern?  Only used to
  break a tie between two patterns of equal PatternLength. }
function IsMoreSpecific(const NewPattern, OldPattern: string): Boolean;

implementation

function MatchesCharClass(const Pattern: string; ClassStart: Integer;
  C: AnsiChar): Boolean;
var
  I, Len: Integer;
  Previous: AnsiChar;
begin
  Result := False;
  Len := Length(Pattern);
  { Start just past the '['; the bracket itself is not part of the set. }
  I := ClassStart + 1;
  { Nothing has been seen yet, so a leading '-' has no lower bound to pair
    with.  #255 makes that comparison fail rather than match everything. }
  Previous := #255;
  while (not Result) and (I <= Len) and (Pattern[I] <> ']') do
  begin
    if Pattern[I] = '-' then
    begin
      { A range: the character before the '-' is the lower bound, the one
        after it the upper. }
      Inc(I);
      if I > Len then
        Break;
      if (C >= Previous) and (C <= Pattern[I]) then
        Result := True;
    end
    else if C = Pattern[I] then
      Result := True;
    Previous := Pattern[I];
    Inc(I);
  end;
end;

function PatternMatches(const Pattern, Callsign: string): Boolean;
var
  P, C, PatLen, CallLen: Integer;
begin
  PatLen  := Length(Pattern);
  CallLen := Length(Callsign);

  { '=' means equality, not prefix. }
  if (PatLen > 0) and (Pattern[1] = ExactMarker) then
    Exit(Copy(Pattern, 2, PatLen) = Callsign);

  P := 1;
  C := 1;
  while P <= PatLen do
  begin
    { The pattern still has characters to place but the callsign has run
      out. }
    if C > CallLen then
      Exit(False);

    case Pattern[P] of
      '#':
        if not (Callsign[C] in ['0'..'9']) then
          Exit(False);
      '%', '?':
        ;  { any single character }
      '[':
        if not MatchesCharClass(Pattern, P, Callsign[C]) then
          Exit(False)
        else
          { skip to the closing bracket }
          while (P < PatLen) and (Pattern[P] <> ']') do
            Inc(P);
    else
      if Pattern[P] <> Callsign[C] then
        Exit(False);
    end;

    Inc(P);
    Inc(C);
  end;

  { The pattern is exhausted; whatever is left of the callsign is free. }
  Result := True;
end;

function PatternLength(const Pattern: string): Integer;
var
  P, Len: Integer;
begin
  Result := 0;
  Len := Length(Pattern);
  P := 1;
  if (Len > 0) and (Pattern[1] = ExactMarker) then
    Inc(P);
  while P <= Len do
  begin
    if Pattern[P] = '[' then
      while (P <= Len) and (Pattern[P] <> ']') do
        Inc(P);
    Inc(P);
    Inc(Result);
  end;
end;

{ Compares one position of two patterns: a literal is more specific than a
  metacharacter, and two metacharacters are not ranked against each other.
  Returns +1 if the first is the more specific, -1 if the second is, 0 if
  neither. }
function CompareSpecificity(A, B: AnsiChar): Integer;
var
  AMeta, BMeta: Boolean;
begin
  AMeta := A in Metacharacters;
  BMeta := B in Metacharacters;
  if AMeta and (not BMeta) then
    Result := -1
  else if (not AMeta) and BMeta then
    Result := 1
  else
    Result := 0;
end;

{ Reads a pattern the way the legacy code indexed a shortstring, where
  position 0 is the length byte rather than a character.  IsMoreSpecific
  starts its walk at 0, so the first thing it compares is the two patterns'
  lengths reinterpreted as characters.  See the note in IsMoreSpecific. }
function LegacyCharAt(const S: string; Index: Integer): AnsiChar;
begin
  if Index = 0 then
    Result := Chr(Length(S))
  else
    Result := S[Index];
end;

function IsMoreSpecific(const NewPattern, OldPattern: string): Boolean;
var
  N, O, NewLen, OldLen, Verdict: Integer;
begin
  if (Length(NewPattern) > 0) and (NewPattern[1] = ExactMarker) and
     ((Length(OldPattern) = 0) or (OldPattern[1] <> ExactMarker)) then
    Exit(True);

  Verdict := 0;
  NewLen := Length(NewPattern);
  OldLen := Length(OldPattern);

  { Two deliberate oddities, both inherited from znacmech.pas:853-866 and both
    preserved because they can change which country a callsign resolves to:

      - the walk starts at index 0, so the first comparison is between the
        two length bytes reinterpreted as characters.  A pattern of length 35
        therefore looks like '#' and one of length 37 like '%'.  Both are
        metacharacters, so the effect is limited to length pairs where exactly
        one side lands on 35, 37, 63, 91 or 93 -- but it is not nothing.

      - the loop stops at Length-1, so the final character of either pattern
        is never examined.

    Fixing either would be a behaviour change, which belongs in its own commit
    with its own evidence, not in a refactoring. }
  N := 0;
  O := 0;
  while (Verdict = 0) and (N < NewLen) and (O < OldLen) do
  begin
    Verdict := CompareSpecificity(LegacyCharAt(NewPattern, N),
                                  LegacyCharAt(OldPattern, O));
    if LegacyCharAt(NewPattern, N) = '[' then
      while (N < NewLen) and (LegacyCharAt(NewPattern, N) <> ']') do
        Inc(N);
    if LegacyCharAt(OldPattern, O) = '[' then
      while (O < OldLen) and (LegacyCharAt(OldPattern, O) <> ']') do
        Inc(O);
    Inc(N);
    Inc(O);
  end;

  Result := Verdict = 1;
end;

end.
