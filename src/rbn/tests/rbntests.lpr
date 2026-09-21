(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Console test runner for the RBN receive path.

  Usage:  ./rbntests --format=plain --all  }

program rbntests;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, consoletestrunner,
  uRbnLineFramer, uRbnSpotParser, uRbnLogin, uRbnSpotQueue, uRbnReconnect, uRbnFixture,
  tLineFramer, tSpotParser, tLogin, tSpotQueue, tReconnect, tFixtures;

type
  TRbnTestRunner = class(TTestRunner)
  end;

var
  App: TRbnTestRunner;

begin
  App := TRbnTestRunner.Create(nil);
  try
    App.Initialize;
    App.Title := 'CQRLOG RBN receive path tests';
    App.Run;
  finally
    App.Free;
  end;
end.
