(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Reducing a callsign to something the table can be looked up with.

  Replaces TdmDXCC.CoVyhodnocovat (dDXCC.pas:449) and its NaselCountry helper
  (dDXCC.pas:377).  A callsign that went on the air rarely matches the tables
  directly: DL1ABC/P, OK1ABC/OK2, KL7AA/1, LU1AAA/Z all have to be reduced to
  a key first, and the rules for doing so are a pile of special cases
  accumulated over decades.  The port keeps them, with one deliberate
  exception documented under "Argentina" below.

  Lookup order matches the original: deleted entities first, then valid ones. }

unit uDxccResolver;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uDxccTable, uDxccEntry, uDxccSuffixRules;

type
  TDxccLookup = record
    Found: Boolean;
    Entry: TDxccEntry;
    Adif: Integer;
    Deleted: Boolean;
  end;

  TDxccResolver = class
  private
    FValid: TDxccTable;
    FDeleted: TDxccTable;
    FRules: TDxccSuffixRules;
  public
    { The resolver does not own any of these. }
    constructor Create(AValid, ADeleted: TDxccTable; ARules: TDxccSuffixRules);

    { The deleted-then-valid search the whole layer is built on. }
    function Lookup(const Callsign, ADate: string;
      Mode: TDxccMatchMode = dmPrefix): TDxccLookup;

    { Reduces Callsign to the key the tables should be searched with.

      AlreadyResolved reports the original's UzNasel: the reduction itself
      established the answer and the caller should not keep searching.
      Adif carries the side-effect ADIF the original produced along the way.

      A result of '?' means maritime or aeronautical mobile -- no country. }
    function EffectiveCallsign(const Callsign, ADate: string;
      out AlreadyResolved: Boolean; out Adif: Integer): string;

    { True for the prefixes that encode a province in character 4. }
    class function IsArgentinePrefix(const Prefix: string): Boolean;
  end;

implementation

const
  { Argentina and its companion prefixes.  All of them carry the province in
    the fourth character of the callsign. }
  ArgentinePrefixes: array[0..10] of string =
    ('LU', 'LW', 'AY', 'AZ', 'LO', 'LP', 'LQ', 'LR', 'LS', 'LT', 'LV');

  { Suffix letters the original treats as "operating from that place" rather
    than as a region marker.  F, G, I, K and W are absent from the original
    set because they are major DXCC prefixes in their own right -- F=France,
    G=England, I=Italy, W/K=United States -- so DL1ABC/F really does mean
    France.  See the Argentina note in EffectiveCallsign. }
  LocationSuffixLetters =
    ['A'..'D', 'E', 'H', 'J', 'L'..'V', 'X'..'Z'];

constructor TDxccResolver.Create(AValid, ADeleted: TDxccTable;
  ARules: TDxccSuffixRules);
begin
  inherited Create;
  FValid   := AValid;
  FDeleted := ADeleted;
  FRules   := ARules;
end;

class function TDxccResolver.IsArgentinePrefix(const Prefix: string): Boolean;
var
  I: Integer;
begin
  for I := Low(ArgentinePrefixes) to High(ArgentinePrefixes) do
    if Copy(Prefix, 1, Length(ArgentinePrefixes[I])) = ArgentinePrefixes[I] then
      Exit(True);
  Result := False;
end;

function TDxccResolver.Lookup(const Callsign, ADate: string;
  Mode: TDxccMatchMode): TDxccLookup;
var
  Index: Integer;
begin
  { Not FillChar -- TDxccEntry holds managed strings. }
  Result.Found   := False;
  Result.Deleted := False;
  Result.Adif    := 0;
  ClearEntry(Result.Entry);

  { Deleted entities are consulted first, exactly as in the original. }
  if FDeleted <> nil then
  begin
    Index := FDeleted.Find(Callsign, ADate, Mode);
    if Index >= 0 then
    begin
      Result.Found   := True;
      Result.Deleted := True;
      Result.Entry   := FDeleted.Entry(Index);
      if not TryStrToInt(Result.Entry.Adif, Result.Adif) then
        Result.Adif := 0;
      Exit;
    end;
  end;

  if FValid <> nil then
  begin
    Index := FValid.Find(Callsign, ADate, Mode);
    if Index >= 0 then
    begin
      Result.Found := True;
      Result.Entry := FValid.Entry(Index);
      if not TryStrToInt(Result.Entry.Adif, Result.Adif) then
        Result.Adif := 0;
    end;
  end;
end;

{ Splits on Separator the way dDXCC.Explode did. }
function Explode(const Separator, Value: string): TStringArray;
var
  Rest: string;
  P: Integer;
begin
  Result := nil;
  Rest := Value;
  P := Pos(Separator, Rest);
  while P > 0 do
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Copy(Rest, 1, P - 1);
    Rest := Copy(Rest, P + Length(Separator), Length(Rest));
    P := Pos(Separator, Rest);
  end;
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := Rest;
end;

{ TryStrToInt, except that a leading 'X' is not read as hexadecimal -- XE1 is
  a Mexican prefix, not a number (dDXCC.pas:162). }
function CallsignToInt(const S: string; out Value: Integer): Boolean;
var
  Upper: string;
begin
  Value := 0;
  Upper := UpperCase(S);
  if (Length(Upper) > 0) and (Upper[1] = 'X') then
    Exit(False);
  Result := TryStrToInt(Upper, Value);
end;

function CharAtOrNull(const S: string; Index: Integer): AnsiChar;
begin
  if (Index >= 1) and (Index <= Length(S)) then
    Result := S[Index]
  else
    Result := #0;
end;

{ Places the Argentine province letter in slot 4.  The original wrote
  Prefix[4] unconditionally, which corrupts memory for anything shorter than
  four characters; here a three-character prefix simply grows into the slot
  and anything shorter is left alone. }
function ApplyArgentineRegion(const Prefix: string; Region: AnsiChar;
  out Rewritten: string): Boolean;
begin
  Rewritten := Prefix;
  if Length(Prefix) >= 4 then
  begin
    Rewritten[4] := Region;
    Result := True;
  end
  else if Length(Prefix) = 3 then
  begin
    Rewritten := Prefix + Region;
    Result := True;
  end
  else
    Result := False;
end;

function TDxccResolver.EffectiveCallsign(const Callsign, ADate: string;
  out AlreadyResolved: Boolean; out Adif: Integer): string;
var
  Parts: TStringArray;
  SlashCount, Dummy: Integer;
  Before, Between, After: string;
  Rewritten: string;
  Found: TDxccLookup;
begin
  AlreadyResolved := False;
  Adif   := 0;
  Result := Callsign;

  if Pos('/', Callsign) = 0 then
    Exit;

  { A callsign listed verbatim, slash and all, needs no reduction.  Plenty of
    Antarctic and expedition calls are stored that way (=LU2ERA/Z). }
  Found := Lookup(Callsign, ADate, dmExact);
  if Found.Found then
  begin
    Adif := Found.Adif;
    AlreadyResolved := True;
    Exit(Callsign);
  end;

  Parts := Explode('/', Callsign);
  SlashCount := Length(Parts) - 1;

  case SlashCount of
    1:
      begin
        Before := Parts[0];
        After  := Parts[1];

        { A multi-digit suffix is a serial or year, not a location. }
        if CallsignToInt(After, Dummy) and (Length(After) > 1) then
          Exit(Before);

        if Length(Before) = 0 then
          Exit(After);
        if Length(After) = 0 then
          Exit(Before);

        { Maritime and aeronautical mobile belong to no country. }
        if (After = 'MM') or (After = 'MM1') or (After = 'MM2') or
           (After = 'MM3') or (After = 'AM') then
          Exit('?');

        if Length(After) = 1 then
        begin
          { --- Argentina -------------------------------------------------
            Argentine provinces live in character 4, so LU1AAA/Z means "the
            LU1AAA operator, transmitting from region Z" and the key is
            LU1ZAA.  LU#Z is Antarctica, a different DXCC entity, so getting
            this wrong moves the QSO to another country.

            This test comes first and covers the whole alphabet, which is the
            one deliberate departure from dDXCC.CoVyhodnocovat.  There the
            check sat below the /M and /P shortcut and used the narrower
            LocationSuffixLetters set, so:

              - LU1AAA/F, /G, /I and /K fell through to the generic branch
                and lost the province.  Not to France, England, Italy and the
                USA as the original's own reasoning suggests: the branch sets
                the key to the bare suffix, but then probes 'LU' + '/' + suffix
                in prefix mode, and 'LU' is itself a mark, so the answer came
                out as plain Argentina.  Same ADIF, wrong province.
              - the /M and /P shortcut tested only Pos('LU',...), so the ten
                companion prefixes lost Mendoza and San Juan -- LW1AAA/M
                resolved as plain Buenos Aires.

            /W and /X are NOT in that list: AreaOK1RR.tbl carries explicit
            L[O-W][1-9]%%%/W and /X[A-O] /X[P-Z] patterns, so the exact-match
            attempt above answers them before this code runs.  That is also
            why the rewrite must stay below that attempt -- the tables get
            the first say, and they express things a character swap cannot,
            such as the Santa Cruz / Tierra del Fuego split.

            For non-Argentine callsigns nothing changes. }
          if IsArgentinePrefix(Before) and (After[1] in ['A'..'Z']) then
            if ApplyArgentineRegion(Before, After[1], Rewritten) then
              Exit(Rewritten);

          { /M mobile and /P portable say nothing about location. }
          if (After[1] = 'M') or (After[1] = 'P') then
            Exit(Before);

          if After[1] in ['0'..'9'] then
          begin
            { A single digit renumbers the call area.  US calls move to the
              W district; everyone else keeps their prefix with the digit
              swapped in. }
            if ((CharAtOrNull(Before, 1) = 'A') and
                (CharAtOrNull(Before, 2) in ['A'..'L'])) or
               (CharAtOrNull(Before, 1) = 'K') or
               (CharAtOrNull(Before, 1) = 'W') or
               (CharAtOrNull(Before, 1) = 'N') then
              Result := 'W' + After
            else
            begin
              Rewritten := Before;
              if Length(Rewritten) >= 3 then
              begin
                Rewritten[3] := After[1];
                Result := Rewritten;
              end
              else
                Result := Before;
            end;
          end
          else
          begin
            if After[1] in LocationSuffixLetters then
              { Not Argentine, so leave the callsign as it stands. }
              Result := Callsign
            else
            begin
              AlreadyResolved := True;
              Result := After;
            end;

            { A prefix/suffix pair may itself be a table entry, e.g. VP2/E. }
            Found := Lookup(Copy(Before, 1, 2) + '/' + After, ADate);
            if Found.Found then
            begin
              Adif := Found.Adif;
              AlreadyResolved := True;
              Exit(Copy(Before, 1, 2) + '/' + After);
            end;
          end;
        end
        else
        begin
          { More than one character after the slash. }
          if FRules.IsIgnoredSuffix(After) then
            Result := Before
          else
          begin
            { Whichever side is not a recognisable prefix is the operator's
              own call; the other one says where they are. }
            if Length(After) >= Length(Before) then
            begin
              Found := Lookup(Before, ADate, dmExactNoEquals);
              if not Found.Found then
              begin
                AlreadyResolved := True;
                Exit(After);
              end
              else
              begin
                Adif := Found.Adif;
                Exit(Before);
              end;
            end
            else
            begin
              Found := Lookup(After, ADate, dmExactNoEquals);
              if not Found.Found then
              begin
                AlreadyResolved := True;
                Exit(Before);
              end
              else
              begin
                Adif := Found.Adif;
                AlreadyResolved := True;
                Exit(After);
              end;
            end;
          end;
        end;
      end;

    2:
      begin
        Before  := Parts[0];
        Between := Parts[1];
        After   := Parts[2];

        if Length(After) = 0 then
          Exit(Before);

        if ((CharAtOrNull(After, 1) = 'M') and (CharAtOrNull(After, 2) = 'M')) or
           (After = 'AM') then
          Exit('?');

        if (Length(Between) > 0) and (Between[1] in ['0'..'9']) then
        begin
          if ((CharAtOrNull(Before, 1) = 'A') and
              (CharAtOrNull(Before, 2) in ['A'..'L'])) or
             (CharAtOrNull(Before, 1) = 'K') or
             (CharAtOrNull(Before, 1) = 'W') then
            Result := 'W' + Between
          else
          begin
            Rewritten := Before;
            { RA1AAA/2/M renumbers position 2 when it already holds a digit,
              otherwise position 3. }
            if CharAtOrNull(Before, 2) in ['0'..'9'] then
            begin
              if Length(Rewritten) >= 2 then
                Rewritten[2] := Between[1];
            end
            else if Length(Rewritten) >= 3 then
              Rewritten[3] := Between[1];
            Exit(Rewritten);
          end;
        end;

        if (Length(After) = 1) and (After[1] in ['A'..'Z']) then
        begin
          Found := Lookup(Before + '/' + After, ADate);
          if Found.Found then
          begin
            Adif := Found.Adif;
            Result := Before + '/' + After;
            AlreadyResolved := True;
          end
          else
            Result := Before;
        end
        else if (Length(After) = 1) and (After[1] in ['0'..'9']) then
        begin
          Rewritten := Copy(Before, 1, 2) + After;
          Found := Lookup(Rewritten, ADate);
          if Found.Found then
          begin
            Adif := Found.Adif;
            Result := Rewritten;
            AlreadyResolved := True;
          end
          else
            Result := Before;
        end
        else
          Result := Before;
      end;
  end;
end;

end.
