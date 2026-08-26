(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Locates the test data files.  The generated tables are built by
  tools/mkdxccdata.sh and are not checked in. }

unit uTestData;

{$mode objfpc}{$H+}

interface

function DataDir: string;
function GeneratedDir: string;
function PlainTable: string;
function ExpandedTable: string;
function DeletedTable: string;
function MiniTable: string;
function HaveGeneratedTables: Boolean;

{ The table the new parser must be compatible with.

  CQRLOG builds country.tab in two places and they do not agree: dData.pas:1057
  concatenates the source files as they are, while fImportProgress.pas:344-351
  additionally expands every '%'-leading line into 26 copies, one per leading
  letter.  The expanded form is the richer of the two -- it resolves guest
  operator callsigns that the plain form cannot reach at all -- and it is what
  a user gets after running Import DXCC data.  So that is the reference. }
function CanonicalTable: string;

implementation

uses
  SysUtils;

var
  CachedDataDir: string = '';

function DataDir: string;
var
  Dir: string;
  I: Integer;
begin
  if CachedDataDir <> '' then
    Exit(CachedDataDir);
  { Walk up from the executable so the runner works whether it is started from
    src/dxcc-parser, from tests/, or from the repository root. }
  Dir := ExtractFilePath(ExpandFileName(ParamStr(0)));
  for I := 0 to 4 do
  begin
    if DirectoryExists(Dir + 'data') and FileExists(Dir + 'data' + PathDelim + 'mini.tab') then
    begin
      CachedDataDir := Dir + 'data' + PathDelim;
      Exit(CachedDataDir);
    end;
    if DirectoryExists(Dir + 'tests' + PathDelim + 'data') then
    begin
      CachedDataDir := Dir + 'tests' + PathDelim + 'data' + PathDelim;
      Exit(CachedDataDir);
    end;
    Dir := ExpandFileName(Dir + '..' + PathDelim);
  end;
  raise Exception.Create('uTestData: cannot locate tests/data directory');
end;

function GeneratedDir: string;
begin
  Result := DataDir + 'generated' + PathDelim;
end;

function PlainTable: string;
begin
  Result := GeneratedDir + 'country-plain.tab';
end;

function ExpandedTable: string;
begin
  Result := GeneratedDir + 'country-expanded.tab';
end;

function DeletedTable: string;
begin
  Result := GeneratedDir + 'country_del.tab';
end;

function MiniTable: string;
begin
  Result := DataDir + 'mini.tab';
end;

function HaveGeneratedTables: Boolean;
begin
  Result := FileExists(PlainTable) and FileExists(ExpandedTable) and FileExists(DeletedTable);
end;

function CanonicalTable: string;
begin
  Result := ExpandedTable;
end;

end.
