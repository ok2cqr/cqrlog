(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Console test runner for the DXCC parser.

  Built with -dnuse_ddata so that the legacy znacmech unit compiles without
  dData (its only outside dependency is dmData.DebugLevel, used in three
  debug Writeln calls guarded by {$ifndef nuse_ddata}).

  Usage:  ./dxcctests --format=plain --all  }

program dxcctests;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, consoletestrunner,
  uDxccTableIntf, uTestData, uLegacyTable, uModernTable, uCorpus,
  uDxccSuffixRules, uDxccResolver, uLegacySplitter,
  tSmoke, tPattern, tRobustness, tDates, tFields, tLoading, tCollation,
  tArgentina, tSplitting, tDifferential;

type
  TDxccTestRunner = class(TTestRunner)
  end;

var
  App: TDxccTestRunner;

begin
  App := TDxccTestRunner.Create(nil);
  try
    App.Initialize;
    App.Title := 'CQRLOG DXCC parser tests';
    App.Run;
  finally
    App.Free;
  end;
end.
