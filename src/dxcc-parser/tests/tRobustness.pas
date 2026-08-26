(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Sweeps the real tables with every plausible callsign shape and asserts that
  nothing raises.

  This is not paranoia.  Tseznam.znacka_najdikam_s (znacmech.pas:529) walks a
  binary search and can leave its index one past the last entry; znacky is a
  zero-filled fixed array, so the next dereference hits nil.  Whether that
  happens depends entirely on whether the table contains a mark that sorts
  above the probe key -- which is a property of the data, not of the code.

  The real tables survive today.  These tests pin that down so a future
  country-file update, or a change to the collation order, cannot break it
  quietly. }

unit tRobustness;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uDxccTableIntf, uDxccTestBase;

type
  TRobustnessTests = class(TDxccTableTestCase)
  private
    function SweepPrefixes(const TableFile: string; Len: Integer): string;
  published
    procedure PlainTableSurvivesOneCharPrefixes;
    procedure PlainTableSurvivesTwoCharPrefixes;
    procedure ExpandedTableSurvivesTwoCharPrefixes;
    procedure DeletedTableSurvivesTwoCharPrefixes;
    procedure EmptyCallsignDoesNotCrash;
    procedure OverlongCallsignDoesNotCrash;
    procedure LowercaseCallsignDoesNotCrash;
    procedure PunctuationCallsignDoesNotCrash;
  end;

  TLegacyRobustnessTests = class(TRobustnessTests)
  protected
    function NewTable(const FileName: string): IDxccTable; override;
  end;

  TModernRobustnessTests = class(TRobustnessTests)
  protected
    function NewTable(const FileName: string): IDxccTable; override;
  end;

implementation

uses
  uLegacyTable, uModernTable, uTestData;

const
  Alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

function TLegacyRobustnessTests.NewTable(const FileName: string): IDxccTable;
begin
  Result := TLegacyTable.Create(FileName);
end;

function TModernRobustnessTests.NewTable(const FileName: string): IDxccTable;
begin
  Result := TModernTable.Create(FileName);
end;

{ Returns a space-separated list of the prefixes that raised, or '' if none. }
function TRobustnessTests.SweepPrefixes(const TableFile: string; Len: Integer): string;
var
  T: IDxccTable;
  I, J: Integer;
  Prefix: string;
  Mode: TMatchMode;
begin
  Result := '';
  T := NewTable(TableFile);
  for I := 1 to Length(Alphabet) do
    for J := 1 to Length(Alphabet) do
    begin
      if Len = 1 then
        Prefix := Alphabet[I]
      else
        Prefix := Alphabet[I] + Alphabet[J];
      for Mode := Low(TMatchMode) to High(TMatchMode) do
        try
          T.Find(Prefix + '9ZZ', '2020/01/01', Mode);
        except
          on E: Exception do
          begin
            Result := Result + Prefix + '(' + E.ClassName + ') ';
            Exit;   { one example is enough; keep the message readable }
          end;
        end;
      if Len = 1 then Break;
    end;
end;

procedure TRobustnessTests.PlainTableSurvivesOneCharPrefixes;
begin
  AssertEquals('prefixes that raised', '', SweepPrefixes(PlainTable, 1));
end;

procedure TRobustnessTests.PlainTableSurvivesTwoCharPrefixes;
begin
  AssertEquals('prefixes that raised', '', SweepPrefixes(PlainTable, 2));
end;

procedure TRobustnessTests.ExpandedTableSurvivesTwoCharPrefixes;
begin
  AssertEquals('prefixes that raised', '', SweepPrefixes(ExpandedTable, 2));
end;

procedure TRobustnessTests.DeletedTableSurvivesTwoCharPrefixes;
begin
  { Only 63 entries, so this is the table most exposed to the overrun. }
  AssertEquals('prefixes that raised', '', SweepPrefixes(DeletedTable, 2));
end;

procedure TRobustnessTests.EmptyCallsignDoesNotCrash;
var
  T: IDxccTable;
begin
  T := NewTable(PlainTable);
  AssertEquals('an empty callsign resolves to nothing', -1,
    T.Find('', '2020/01/01', mmPrefix));
end;

procedure TRobustnessTests.OverlongCallsignDoesNotCrash;
var
  T: IDxccTable;
begin
  { Longer than max_delka_znacky (40); the legacy engine truncates silently
    when the value is assigned to its string[40] parameter. }
  T := NewTable(PlainTable);
  T.Find(StringOfChar('O', 60), '2020/01/01', mmPrefix);
  T.Find('OK1ABC' + StringOfChar('X', 50), '2020/01/01', mmPrefix);
end;

procedure TRobustnessTests.LowercaseCallsignDoesNotCrash;
var
  T: IDxccTable;
begin
  { Lowercase sorts above every uppercase mark, so this is the shape most
    likely to run the search index off the end. }
  T := NewTable(PlainTable);
  T.Find('ok1abc', '2020/01/01', mmPrefix);
  T.Find('zz9zz', '2020/01/01', mmPrefix);
end;

procedure TRobustnessTests.PunctuationCallsignDoesNotCrash;
var
  T: IDxccTable;
begin
  T := NewTable(PlainTable);
  T.Find('/', '2020/01/01', mmPrefix);
  T.Find('OK1/', '2020/01/01', mmPrefix);
  T.Find('-', '2020/01/01', mmPrefix);
  T.Find('?', '2020/01/01', mmPrefix);
end;

initialization
  RegisterTest(TLegacyRobustnessTests);
  RegisterTest(TModernRobustnessTests);

end.
