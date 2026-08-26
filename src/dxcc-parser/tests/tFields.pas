(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Pins down what the twelve field indices mean, by checking the engine against
  an independent parser (uRefParser) over every entry in the real tables. }

unit tFields;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uDxccTableIntf, uDxccTestBase;

type
  TFieldTests = class(TDxccTableTestCase)
  private
    procedure CompareWholeTable(const TableFile: string);
    function FieldOf(const Marks, Line: string; FieldNo: Integer): string;
  published
    procedure PlainTableMatchesReferenceParser;
    procedure ExpandedTableMatchesReferenceParser;
    procedure DeletedTableMatchesReferenceParser;

    procedure CountryIsFieldZero;
    procedure ContinentIsFieldOne;
    procedure UtcOffsetIsFieldTwo;
    procedure CoordinatesAreFieldsThreeAndFour;
    procedure ItuIsFieldFiveAndWazIsFieldSix;
    procedure AdifIsFieldEleven;
    procedure AdifColumnIsFieldSevenAndFlagIsFieldEight;

    procedure AdifIsSynthesisedWhenNoEqualsPresent;
    procedure ExplicitAdifOverridesTheColumn;
    procedure OutOfRangeIndexIsReported;
  end;

  TLegacyFieldTests = class(TFieldTests)
  protected
    function NewTable(const FileName: string): IDxccTable; override;
  end;

  TModernFieldTests = class(TFieldTests)
  protected
    function NewTable(const FileName: string): IDxccTable; override;
  end;

implementation

uses
  uLegacyTable, uModernTable, uTestData, uRefParser;

function TLegacyFieldTests.NewTable(const FileName: string): IDxccTable;
begin
  Result := TLegacyTable.Create(FileName);
end;

function TModernFieldTests.NewTable(const FileName: string): IDxccTable;
begin
  Result := TModernTable.Create(FileName);
end;

{ Reads one field of a one-line table. }
function TFieldTests.FieldOf(const Marks, Line: string; FieldNo: Integer): string;
var
  T: IDxccTable;
  Found: Integer;
begin
  T := BuildTable([Line]);
  Found := T.Find(Marks, '*', mmPrefix);
  AssertTrue('fixture line should resolve: ' + Line, Found >= 0);
  Result := T.Field(Found, FieldNo);
end;

procedure TFieldTests.CompareWholeTable(const TableFile: string);
var
  Expected, Actual: TStringList;
  I, Shown: Integer;
  Diff: string;
begin
  Expected := nil;
  Actual   := nil;
  try
    Expected := ReferenceEntries(TableFile);
    Actual   := EngineEntries(NewTable(TableFile));

    if not Expected.Equals(Actual) then
    begin
      Diff := '';
      Shown := 0;
      for I := 0 to Expected.Count - 1 do
      begin
        if I >= Actual.Count then
        begin
          Diff := Diff + LineEnding + 'missing: ' + Expected[I];
          Inc(Shown);
        end
        else if Expected[I] <> Actual[I] then
        begin
          Diff := Diff + LineEnding + 'expected: ' + Expected[I] +
                         LineEnding + 'actual:   ' + Actual[I];
          Inc(Shown);
        end;
        if Shown >= 5 then Break;
      end;
      Fail(Format('%s: reference parser and engine disagree ' +
        '(%d vs %d entries)%s',
        [ExtractFileName(TableFile), Expected.Count, Actual.Count, Diff]));
    end;

    AssertTrue('the table should not be empty', Expected.Count > 0);
  finally
    Expected.Free;
    Actual.Free;
  end;
end;

procedure TFieldTests.PlainTableMatchesReferenceParser;
begin
  CompareWholeTable(PlainTable);
end;

procedure TFieldTests.ExpandedTableMatchesReferenceParser;
begin
  CompareWholeTable(ExpandedTable);
end;

procedure TFieldTests.DeletedTableMatchesReferenceParser;
begin
  CompareWholeTable(DeletedTable);
end;

{ --- what each index actually holds ------------------------------------ }

const
  Sample = 'ZK1|Sample Land|OC|-11|21.20S|159.80W|62|32|191|R|1990/01/01-1999/12/31=234';

procedure TFieldTests.CountryIsFieldZero;
begin
  AssertEquals('Sample Land', FieldOf('ZK1', Sample, fldCountry));
end;

procedure TFieldTests.ContinentIsFieldOne;
begin
  AssertEquals('OC', FieldOf('ZK1', Sample, fldContinent));
end;

procedure TFieldTests.UtcOffsetIsFieldTwo;
begin
  AssertEquals('-11', FieldOf('ZK1', Sample, fldUtcOffset));
end;

procedure TFieldTests.CoordinatesAreFieldsThreeAndFour;
begin
  AssertEquals('21.20S',  FieldOf('ZK1', Sample, fldLatitude));
  AssertEquals('159.80W', FieldOf('ZK1', Sample, fldLongitude));
end;

procedure TFieldTests.ItuIsFieldFiveAndWazIsFieldSix;
begin
  AssertEquals('62', FieldOf('ZK1', Sample, fldItu));
  AssertEquals('32', FieldOf('ZK1', Sample, fldWaz));
end;

procedure TFieldTests.AdifIsFieldEleven;
begin
  { This is the one dDXCC reads (dDXCC.pas:406). }
  AssertEquals('234', FieldOf('ZK1', Sample, fldAdif));
end;

procedure TFieldTests.AdifColumnIsFieldSevenAndFlagIsFieldEight;
begin
  AssertEquals('191', FieldOf('ZK1', Sample, fldAdifCol));
  AssertEquals('R',   FieldOf('ZK1', Sample, fldFlag));
end;

{ --- the '=' synthesis ------------------------------------------------- }

procedure TFieldTests.AdifIsSynthesisedWhenNoEqualsPresent;
var
  Line: string;
begin
  { 340 real lines have no '=' at all.  The engine appends one built from the
    adif column, so field 11 is never empty. }
  Line := 'ZK2|No Equals Land|OC|-11|21.20S|159.80W|62|32|191||';
  AssertEquals('191', FieldOf('ZK2', Line, fldAdif));
  AssertEquals('the window is empty, so the defaults apply',
    DefaultValidFrom, FieldOf('ZK2', Line, fldValidFrom));
  AssertEquals(DefaultValidTo, FieldOf('ZK2', Line, fldValidTo));
end;

procedure TFieldTests.ExplicitAdifOverridesTheColumn;
begin
  { Column 9 says 191, the '=' says 234; field 11 follows the '='. }
  AssertEquals('234', FieldOf('ZK1', Sample, fldAdif));
  AssertEquals('191', FieldOf('ZK1', Sample, fldAdifCol));
end;

procedure TFieldTests.OutOfRangeIndexIsReported;
var
  T: IDxccTable;
begin
  T := BuildTable([Sample]);
  AssertEquals('reading past the last entry yields the marker',
    OutOfRangeMarker, T.Field(T.Count + 10, fldCountry));
end;

initialization
  RegisterTest(TLegacyFieldTests);
  RegisterTest(TModernFieldTests);

end.
