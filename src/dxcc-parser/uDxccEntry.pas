(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ One DXCC table description, parsed into named fields.

  This replaces znacka_popis_ex(Index, N), where callers had to know that 2 is
  the UTC offset and 11 is the ADIF number.  dDXCC reads eight of these
  (dDXCC.pas:400-407) with bare integers; here they have names.

  Source line format, uniform across all 11032 lines of the current files:

    mark[ mark...]|country|cont|utc|lat|long|itu|waz|adif|flag|window[=adif]

  The window is 'from-to'.  Either half may be empty and defaults in; the
  whole of it may be absent.  When the '=adif' suffix is missing -- 340 real
  lines -- it is synthesised from the adif column, so Adif is never empty. }

unit uDxccEntry;

{$mode objfpc}{$H+}

interface

type
  TDxccEntry = record
    Country: string;
    Continent: string;
    UtcOffset: string;
    Latitude: string;
    Longitude: string;
    Itu: string;
    Waz: string;
    { The adif column, i.e. the 9th field.  Usually agrees with Adif, but the
      '=' suffix wins when the two differ. }
    AdifColumn: string;
    { 'R', 'D' or empty. }
    Flag: string;
    ValidFrom: string;
    ValidTo: string;
    { The number dDXCC actually uses. }
    Adif: string;
    { The description exactly as it appeared, minus the marks. }
    Raw: string;
  end;

const
  DefaultValidFrom = '1945/01/01';
  DefaultValidTo   = '2050/01/01';

{ Empties every field.  Not FillChar: the record holds managed strings, and
  zeroing their pointers behind the compiler's back loses a reference. }
procedure ClearEntry(out Entry: TDxccEntry);

{ Splits a description -- everything after the first '|' of a source line.
  Never fails: a malformed line simply yields empty fields. }
procedure ParseDescription(const Description: string; out Entry: TDxccEntry);

{ Is Entry in force on ADate?  ADate is 'YYYY/MM/DD', or one of two sentinels:
  '*' always matches and '!' never does.  Comparison is lexicographic, which
  is correct for this date format and is also why a bare year sorts below any
  full date within it. }
function IsValidOn(const Entry: TDxccEntry; const ADate: string): Boolean;

implementation

uses
  SysUtils;

const
  AlwaysValid = '*';
  NeverValid  = '!';

procedure ClearEntry(out Entry: TDxccEntry);
begin
  Entry.Country    := '';
  Entry.Continent  := '';
  Entry.UtcOffset  := '';
  Entry.Latitude   := '';
  Entry.Longitude  := '';
  Entry.Itu        := '';
  Entry.Waz        := '';
  Entry.AdifColumn := '';
  Entry.Flag       := '';
  Entry.ValidFrom  := '';
  Entry.ValidTo    := '';
  Entry.Adif       := '';
  Entry.Raw        := '';
end;

procedure ParseDescription(const Description: string; out Entry: TDxccEntry);
var
  Segments: array[0..9] of string;
  Count, I, Start, DashPos, EqPos: Integer;
  Window: string;

  procedure Split;
  var
    P: Integer;
  begin
    Count := 0;
    Start := 1;
    for P := 1 to Length(Description) do
      if Description[P] = '|' then
      begin
        if Count <= High(Segments) then
          Segments[Count] := Copy(Description, Start, P - Start);
        Inc(Count);
        Start := P + 1;
      end;
    if Count <= High(Segments) then
      Segments[Count] := Copy(Description, Start, Length(Description) - Start + 1);
    Inc(Count);
  end;

begin
  for I := Low(Segments) to High(Segments) do
    Segments[I] := '';
  Split;

  Entry.Raw        := Description;
  Entry.Country    := Segments[0];
  Entry.Continent  := Segments[1];
  Entry.UtcOffset  := Segments[2];
  Entry.Latitude   := Segments[3];
  Entry.Longitude  := Segments[4];
  Entry.Itu        := Segments[5];
  Entry.Waz        := Segments[6];
  Entry.AdifColumn := Segments[7];
  Entry.Flag       := Segments[8];

  Window := Segments[9];
  { No explicit ADIF: take the one from the column. }
  if Pos('=', Window) = 0 then
    Window := Window + '=' + Entry.AdifColumn;

  EqPos := Pos('=', Window);

  { The first '-' before the '=' splits the two dates.  A window of the form
    '-to' therefore has an empty 'from', which then defaults. }
  DashPos := 0;
  for I := 1 to EqPos - 1 do
    if Window[I] = '-' then
    begin
      DashPos := I;
      Break;
    end;
  if DashPos = 0 then
    DashPos := EqPos;

  Entry.ValidFrom := Copy(Window, 1, DashPos - 1);
  Entry.ValidTo   := Copy(Window, DashPos + 1, EqPos - DashPos - 1);
  Entry.Adif      := Copy(Window, EqPos + 1, Length(Window));

  if Entry.ValidFrom = '' then Entry.ValidFrom := DefaultValidFrom;
  if Entry.ValidTo   = '' then Entry.ValidTo   := DefaultValidTo;
end;

function IsValidOn(const Entry: TDxccEntry; const ADate: string): Boolean;
begin
  if ADate = AlwaysValid then
    Result := True
  else if ADate = NeverValid then
    Result := False
  else
    Result := (Entry.ValidFrom <= ADate) and (Entry.ValidTo >= ADate);
end;

end.
