(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ CW macro expansion.  The expected results follow what
  TdmUtils.GetCWMessage returned before the expansion moved to uCWMacros. }

unit tCWMacroExpansion;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uCWMacros;

type
  TCWMacroTest = class(TTestCase)
  private
    Station : TCWMacroStation;
    Qso     : TCWMacroQso;
    function Expand(const Text : String) : String;
  protected
    procedure SetUp; override;
  published
    procedure NoMacros;
    procedure MyStation;
    procedure CallNameGreeting;
    procedure Report;
    procedure ReportShort;
    procedure SerialNumbers;
    procedure ExchangeMessages;
    procedure FullExchange;
    procedure FullExchangeWithoutSerial;
    procedure FullExchangeReportOnly;
    procedure MacrosAreCaseInsensitive;
    procedure EveryOccurrence;
    procedure UnknownMacroStays;
    procedure EmptyValues;
    procedure ValueIsExpandedByLaterMacro;
    procedure ShortNumbers;
  end;

implementation

procedure TCWMacroTest.SetUp;
begin
  Station.MyCall := 'OK2CQR';
  Station.MyLoc  := 'JN89HE';
  Station.MyName := 'PETR';
  Station.MyQth  := 'BRNO';
  Qso.Call    := 'DL1ABC';
  Qso.RstS    := '599';
  Qso.Stx     := '009';
  Qso.StxStr  := 'JN89';
  Qso.Srx     := '102';
  Qso.SrxStr  := 'JO62';
  Qso.HisName := 'HANS';
  Qso.Hello   := 'GE'
end;

function TCWMacroTest.Expand(const Text : String) : String;
begin
  Result := ExpandCWMacros(Text, Station, Qso)
end;

procedure TCWMacroTest.NoMacros;
begin
  AssertEquals('CQ CQ TEST', Expand('CQ CQ TEST'))
end;

procedure TCWMacroTest.MyStation;
begin
  AssertEquals('OK2CQR JN89HE PETR BRNO', Expand('%mc %ml %mn %mq'))
end;

procedure TCWMacroTest.CallNameGreeting;
begin
  AssertEquals('DL1ABC GE HANS', Expand('%c %h %n'))
end;

procedure TCWMacroTest.Report;
begin
  AssertEquals('UR 599', Expand('UR %r'))
end;

procedure TCWMacroTest.ReportShort;
begin
  AssertEquals('UR 5NN', Expand('UR %rs'))
end;

procedure TCWMacroTest.SerialNumbers;
begin
  AssertEquals('009 TTN 102 1T2', Expand('%xn %xns %xnr %xnrs'))
end;

procedure TCWMacroTest.ExchangeMessages;
begin
  AssertEquals('JN89 JO62', Expand('%xm %xmr'))
end;

procedure TCWMacroTest.FullExchange;
begin
  AssertEquals('5NN TTN JN89', Expand('%xrs'))
end;

procedure TCWMacroTest.FullExchangeWithoutSerial;
begin
  Qso.Stx := '';
  AssertEquals('5NN JN89', Expand('%xrs'))
end;

procedure TCWMacroTest.FullExchangeReportOnly;
begin
  Qso.Stx := '';
  Qso.StxStr := '';
  AssertEquals('5NN', Expand('%xrs'))
end;

procedure TCWMacroTest.MacrosAreCaseInsensitive;
begin
  AssertEquals('DL1ABC 5NN OK2CQR', Expand('%C %RS %Mc'))
end;

procedure TCWMacroTest.EveryOccurrence;
begin
  AssertEquals('DL1ABC DL1ABC DE OK2CQR', Expand('%c %c DE %mc'))
end;

procedure TCWMacroTest.UnknownMacroStays;
begin
  AssertEquals('%z 50%', Expand('%z 50%'))
end;

procedure TCWMacroTest.EmptyValues;
begin
  Qso.Call := '';
  Qso.HisName := '';
  AssertEquals(' TU ', Expand('%c TU %n'))
end;

procedure TCWMacroTest.ValueIsExpandedByLaterMacro;
begin
  //the macros are replaced one after another, so a value containing a macro
  //replaced later is expanded too.  Kept as it was.
  Qso.HisName := 'X%cX';
  AssertEquals('XDL1ABCX', Expand('%n'))
end;

procedure TCWMacroTest.ShortNumbers;
begin
  AssertEquals('5NN', CWShortNumbers('599'));
  AssertEquals('1TT', CWShortNumbers('100'));
  AssertEquals('AB', CWShortNumbers('AB'));
  AssertEquals('', CWShortNumbers(''))
end;

initialization
  RegisterTest(TCWMacroTest)
end.
