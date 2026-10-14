(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Console test runner for LCL-free units extracted from forms and data modules.

  Usage:  ./coretests --format=plain --all  }

program coretests;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, consoletestrunner,
  uScpIndex, uWinKeyerProtocol, uCWDevice, uCWWinKeyer,
  tScpLookup, tWinKeyerProtocol;

type
  TCoreTestRunner = class(TTestRunner)
  end;

var
  App: TCoreTestRunner;

begin
  App := TCoreTestRunner.Create(nil);
  try
    App.Initialize;
    App.Title := 'CQRLOG shared core tests';
    App.Run;
  finally
    App.Free;
  end;
end.
