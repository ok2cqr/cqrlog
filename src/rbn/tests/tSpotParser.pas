(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ One definition of what an RBN spot line is.  CQRLOG had three parsers that
  did not agree (fRbnMonitor, fGrayline, dDXCluster.GetSplitSpot); all of them
  split on spaces and indexed the pieces without checking how many there were. }

unit tSpotParser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uRbnSpotParser;

type
  TSpotParserTest = class(TTestCase)
  published
    procedure TypicalCwSpot;
    procedure SkimmerSuffixAndSsidAreCutFromSpotter;
    procedure SpotterWithoutSuffix;
    procedure VhfSpotHasNoSpaceAfterColon;
    procedure NegativeSignal;
    procedure FrequencyIgnoresLocaleDecimalSeparator;
    procedure LongCallsignIsNotTruncated;
    procedure DxDeIsCaseInsensitive;
    procedure LeadingSpacesAreAccepted;
    procedure DxDeInTheMiddleOfALineIsNotASpot;
    procedure GreetingAndPromptAreNotSpots;
    procedure NoPrefixOfASpotRaises;
    procedure SpotCutBeforeSignalIsRejected;
    procedure FrequencyThatIsNotANumberIsRejected;
    procedure OutputIsClearedOnFailure;
  end;

implementation

const
  CW_SPOT = 'DX de DK9IP-#:   7016.00  IZ4IYK         CW    10 dB  28 WPM  CQ      1845Z';

procedure TSpotParserTest.TypicalCwSpot;
var
  S : TRbnSpotLine;
begin
  AssertTrue(ParseRbnSpot(CW_SPOT, S));
  AssertEquals('DK9IP', S.Spotter);
  AssertEquals('IZ4IYK', S.Dx);
  AssertEquals('7016.00', S.FreqText);
  AssertEquals(7016.0, S.FreqKHz, 0.001);
  AssertEquals('CW', S.Mode);
  AssertEquals(10, S.SignalDb);
  //whatever stands between dB and the time, single spaced
  AssertEquals('28 WPM CQ', S.Info);
  AssertEquals('1845Z', S.TimeUtc)
end;

procedure TSpotParserTest.SkimmerSuffixAndSsidAreCutFromSpotter;
var
  S : TRbnSpotLine;
begin
  AssertTrue(ParseRbnSpot('DX de W3LPL-2-#: 14025.10  OK1AA  CW  22 dB  30 WPM  CQ  0001Z', S));
  AssertEquals('W3LPL', S.Spotter)
end;

procedure TSpotParserTest.SpotterWithoutSuffix;
var
  S : TRbnSpotLine;
begin
  AssertTrue(ParseRbnSpot('DX de OK1AA:  14025.10  OK2BB  CW  22 dB  30 WPM  CQ  0001Z', S));
  AssertEquals('OK1AA', S.Spotter)
end;

procedure TSpotParserTest.VhfSpotHasNoSpaceAfterColon;
var
  S : TRbnSpotLine;
begin
  //recorded 2026-09-21: a six digit frequency fills the column up to the colon
  AssertTrue(ParseRbnSpot('DX de HA1VHF-#:144433.50  9A0BVH         CW    15 dB  13 WPM  DX      1850Z', S));
  AssertEquals('HA1VHF', S.Spotter);
  AssertEquals(144433.5, S.FreqKHz, 0.001);
  AssertEquals('9A0BVH', S.Dx)
end;

procedure TSpotParserTest.NegativeSignal;
var
  S : TRbnSpotLine;
begin
  AssertTrue(ParseRbnSpot('DX de KM3T-#:  14074.00  K1ABC  FT8  -12 dB  CQ  1845Z', S));
  AssertEquals(-12, S.SignalDb);
  AssertEquals('FT8', S.Mode);
  AssertEquals('CQ', S.Info)
end;

procedure TSpotParserTest.FrequencyIgnoresLocaleDecimalSeparator;
var
  S   : TRbnSpotLine;
  Old : Char;
begin
  Old := DefaultFormatSettings.DecimalSeparator;
  DefaultFormatSettings.DecimalSeparator := ',';
  try
    AssertTrue(ParseRbnSpot(CW_SPOT, S));
    AssertEquals(7016.0, S.FreqKHz, 0.001)
  finally
    DefaultFormatSettings.DecimalSeparator := Old
  end
end;

procedure TSpotParserTest.LongCallsignIsNotTruncated;
var
  S : TRbnSpotLine;
begin
  //the old record had String[20] fields
  AssertTrue(ParseRbnSpot('DX de OK1AA-#:  7016.00  VP2V/SP9FIH/QRPP/MM/ABCDEF  CW  10 dB  28 WPM  CQ  1845Z', S));
  AssertEquals('VP2V/SP9FIH/QRPP/MM/ABCDEF', S.Dx)
end;

procedure TSpotParserTest.DxDeIsCaseInsensitive;
var
  S : TRbnSpotLine;
begin
  AssertTrue(ParseRbnSpot('dx DE OK1AA-#:  7016.00  OK2BB  CW  10 dB  28 WPM  CQ  1845Z', S))
end;

procedure TSpotParserTest.LeadingSpacesAreAccepted;
var
  S : TRbnSpotLine;
begin
  AssertTrue(ParseRbnSpot('  ' + CW_SPOT, S));
  AssertEquals('DK9IP', S.Spotter)
end;

procedure TSpotParserTest.DxDeInTheMiddleOfALineIsNotASpot;
var
  S : TRbnSpotLine;
begin
  AssertFalse(ParseRbnSpot('To ALL de OK1AA: see DX de DK9IP-#: 7016.00 IZ4IYK CW 10 dB 28 WPM CQ 1845Z', S))
end;

procedure TSpotParserTest.GreetingAndPromptAreNotSpots;
var
  S : TRbnSpotLine;
begin
  AssertFalse(ParseRbnSpot('', S));
  AssertFalse(ParseRbnSpot('Hello, OK2CQR! Connected.', S));
  AssertFalse(ParseRbnSpot('Spot rate: 6/s (21,857/h)', S));
  AssertFalse(ParseRbnSpot('OK2CQR de RELAY 21-Sep-2026 18:45Z >', S));
  AssertFalse(ParseRbnSpot('Please enter your call: ', S))
end;

procedure TSpotParserTest.NoPrefixOfASpotRaises;
var
  S : TRbnSpotLine;
  i : Integer;
begin
  //what a framer bug or a dropped connection would feed in
  for i := 0 to Length(CW_SPOT) do
    ParseRbnSpot(Copy(CW_SPOT, 1, i), S)
end;

procedure TSpotParserTest.SpotCutBeforeSignalIsRejected;
var
  S : TRbnSpotLine;
begin
  AssertFalse(ParseRbnSpot('DX de DK9IP-#:   7016.00  IZ4IYK         CW', S));
  AssertFalse(ParseRbnSpot('DX de DK9IP-#:   7016.00  IZ4IYK', S));
  AssertFalse(ParseRbnSpot('DX de DK9IP-#:', S))
end;

procedure TSpotParserTest.FrequencyThatIsNotANumberIsRejected;
var
  S : TRbnSpotLine;
begin
  AssertFalse(ParseRbnSpot('DX de DK9IP-#:   70x6.00  IZ4IYK  CW  10 dB  28 WPM  CQ  1845Z', S))
end;

procedure TSpotParserTest.OutputIsClearedOnFailure;
var
  S : TRbnSpotLine;
begin
  AssertTrue(ParseRbnSpot(CW_SPOT, S));
  AssertFalse(ParseRbnSpot('garbage', S));
  AssertEquals('', S.Dx);
  AssertEquals(0.0, S.FreqKHz, 0.001)
end;

initialization
  RegisterTest(TSpotParserTest);
end.
