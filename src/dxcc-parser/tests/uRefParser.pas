(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ A second, independent implementation of the table file format, written
  straight from the file's own structure rather than from znacmech's code.

  Its only job is to disagree.  If this parser and the engine produce the same
  (mark, fields) multiset for all 21560 real entries, then the meaning of the
  twelve field indices is established rather than assumed -- which is the whole
  premise the new implementation is built on.

  Line format, confirmed uniform across all 11032 real lines (10 pipes each):

    mark[ mark...]|country|cont|utc|lat|long|itu|waz|adif|flag|window[=adif]

  The window is 'from-to', either half of which may be empty, and the whole of
  which may be absent.  When there is no '=', the engine appends one built from
  the adif column -- so field 11 always carries a number. }

unit uRefParser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uDxccTableIntf;

type
  TRefFields = array[fldFirst..fldLast] of string;

{ Splits one source line.  Returns False for a line the engine would skip. }
function ParseLine(const Line: string; out Marks: TStringList;
  out Fields: TRefFields): Boolean;

{ Every (mark, fields) tuple in the file, one flattened string per entry,
  sorted.  Directly comparable with the engine's own dump. }
function ReferenceEntries(const FileName: string): TStringList;

{ Same shape, taken from a loaded table. }
function EngineEntries(Table: IDxccTable): TStringList;

function FlattenFields(const Marks: string; const Fields: TRefFields): string;

implementation

uses
  uDxccLimits;

function FlattenFields(const Marks: string; const Fields: TRefFields): string;
var
  I: Integer;
begin
  Result := Marks;
  for I := fldFirst to fldLast do
    Result := Result + #9 + Fields[I];
end;

function ParseLine(const Line: string; out Marks: TStringList;
  out Fields: TRefFields): Boolean;
var
  Parts: TStringList;
  MarkPart, Window, AdifColumn: string;
  DashPos, EqPos, I: Integer;
  Raw: string;
begin
  Marks := nil;
  for I := fldFirst to fldLast do
    Fields[I] := '';
  Result := False;
  if Line = '' then
    Exit;

  I := Pos('|', Line);
  if I = 0 then
    Exit;
  MarkPart := Copy(Line, 1, I - 1);
  Raw      := Copy(Line, I + 1, Length(Line));

  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := '|';
    Parts.DelimitedText := Raw;
    if Parts.Count < 10 then
      Exit;

    { Segments 0..8 map one-to-one onto field indices 0..8. }
    for I := 0 to 8 do
      Fields[I] := Parts[I];

    AdifColumn := Parts[fldAdifCol];
    Window     := Parts[9];

    { No '=' in the window: the engine appends '=' + the adif column. }
    if Pos('=', Window) = 0 then
      Window := Window + '=' + AdifColumn;

    EqPos := Pos('=', Window);

    { The first '-' before the '=' separates the two dates.  A window that is
      just '-to' therefore yields an empty 'from'. }
    DashPos := 0;
    for I := 1 to EqPos - 1 do
      if Window[I] = '-' then
      begin
        DashPos := I;
        Break;
      end;
    if DashPos = 0 then
      DashPos := EqPos;

    Fields[fldValidFrom] := Copy(Window, 1, DashPos - 1);
    Fields[fldValidTo]   := Copy(Window, DashPos + 1, EqPos - DashPos - 1);
    Fields[fldAdif]      := Copy(Window, EqPos + 1, Length(Window));

    if Fields[fldValidFrom] = '' then Fields[fldValidFrom] := DefaultValidFrom;
    if Fields[fldValidTo]   = '' then Fields[fldValidTo]   := DefaultValidTo;

    { Marks are whitespace separated; the engine trims and drops empties, and
      truncates each one to the mark length limit. }
    Marks := TStringList.Create;
    Marks.Delimiter := ' ';
    Marks.StrictDelimiter := False;
    Marks.DelimitedText := Trim(MarkPart);
    for I := Marks.Count - 1 downto 0 do
      if Trim(Marks[I]) = '' then
        Marks.Delete(I)
      else
        Marks[I] := Copy(Trim(Marks[I]), 1, MaxMarkLength);

    Result := Marks.Count > 0;
  finally
    Parts.Free;
  end;
end;

function ReferenceEntries(const FileName: string): TStringList;
var
  Source: TStringList;
  Marks: TStringList;
  Fields: TRefFields;
  I, M: Integer;
begin
  Result := TStringList.Create;
  Source := TStringList.Create;
  try
    Source.LoadFromFile(FileName);
    for I := 0 to Source.Count - 1 do
    begin
      Marks := nil;
      try
        if ParseLine(Source[I], Marks, Fields) then
          for M := 0 to Marks.Count - 1 do
            Result.Add(FlattenFields(Marks[M], Fields));
      finally
        Marks.Free;
      end;
    end;
  finally
    Source.Free;
  end;
  Result.Sort;
end;

function EngineEntries(Table: IDxccTable): TStringList;
var
  I, F: Integer;
  Fields: TRefFields;
begin
  Result := TStringList.Create;
  for I := 0 to Table.Count - 1 do
  begin
    for F := fldFirst to fldLast do
      Fields[F] := Table.Field(I, F);
    Result.Add(FlattenFields(Table.Pattern(I), Fields));
  end;
  Result.Sort;
end;

end.
