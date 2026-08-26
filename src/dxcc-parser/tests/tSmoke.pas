(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Phase 0: proves the harness can link against the legacy engine and load the
  real tables.  If this fails, nothing else in the suite is meaningful. }

unit tSmoke;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry;

type
  TSmokeTest = class(TTestCase)
  published
    procedure GeneratedTablesExist;
    procedure MiniTableLoads;
    procedure PlainTableLoads;
    procedure ExpandedTableIsLarger;
    procedure DeletedTableLoads;
    procedure MissingFileDoesNotCrash;
  end;

implementation

uses
  uDxccTableIntf, uLegacyTable, uTestData;

procedure TSmokeTest.GeneratedTablesExist;
begin
  AssertTrue('Generated tables missing -- run tools/mkdxccdata.sh first',
    HaveGeneratedTables);
end;

procedure TSmokeTest.MiniTableLoads;
var
  T: IDxccTable;
begin
  T := TLegacyTable.Create(MiniTable);
  { 30 lines, but several carry more than one mark. }
  AssertTrue('mini.tab should yield more than 30 marks, got ' + IntToStr(T.Count),
    T.Count > 30);
end;

procedure TSmokeTest.PlainTableLoads;
var
  T: IDxccTable;
begin
  T := TLegacyTable.Create(PlainTable);
  AssertEquals('mark count of country-plain.tab', 21560, T.Count);
end;

procedure TSmokeTest.ExpandedTableIsLarger;
var
  Plain, Expanded: IDxccTable;
begin
  Plain    := TLegacyTable.Create(PlainTable);
  Expanded := TLegacyTable.Create(ExpandedTable);
  AssertTrue('the %-expanded table must hold more marks',
    Expanded.Count > Plain.Count);
end;

procedure TSmokeTest.DeletedTableLoads;
var
  T: IDxccTable;
begin
  T := TLegacyTable.Create(DeletedTable);
  AssertTrue('country_del.tab should hold marks, got ' + IntToStr(T.Count),
    T.Count > 0);
end;

procedure TSmokeTest.MissingFileDoesNotCrash;
var
  T: IDxccTable;
begin
  { Tseznam.init reports E01 and sets ziju:=false; it does not raise. }
  T := TLegacyTable.Create(DataDir + 'no-such-file.tab');
  AssertEquals('a table that failed to load reports no marks', 0, T.Count);
end;

initialization
  RegisterTest(TSmokeTest);

end.
