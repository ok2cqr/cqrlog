(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The one definition of an RBN spot line:

    DX de DK9IP-#:   7016.00  IZ4IYK         CW    10 dB  28 WPM  CQ      1845Z
    DX de HA1VHF-#:144433.50  9A0BVH         CW    15 dB  13 WPM  DX      1850Z

  The spotter ends at the colon, not at a space -- a six digit frequency fills
  the column and leaves no space.  Everything else is space separated.  A line
  that does not have all of spotter, frequency, call, mode and "<n> dB" is not a
  spot; nothing is indexed before it is known to be there.

  No LCL, no globals; safe to call from any thread.  See tests/tSpotParser.pas. }

unit uRbnSpotParser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TRbnSpotLine = record
    Spotter  : String;  //without the skimmer suffix and SSID: W3LPL-2-# -> W3LPL
    Dx       : String;
    FreqText : String;  //as sent, always with a dot
    FreqKHz  : Double;
    Mode     : String;
    SignalDb : Integer;
    Info     : String;  //between dB and the time, single spaced: 28 WPM CQ
    TimeUtc  : String;  //1845Z, empty when the line has none
  end;

function ParseRbnSpot(const Line : String; out Spot : TRbnSpotLine) : Boolean;

implementation

uses
  StrUtils;

const
  DX_DE = 'DX de ';
  TOK_FREQ   = 1;
  TOK_DX     = 2;
  TOK_MODE   = 3;
  TOK_SIGNAL = 4;
  TOK_DB     = 5;

var
  fsDot : TFormatSettings; //RBN sends a dot whatever the locale, read only after init

function IsTime(const s : String) : Boolean;
begin
  Result := (Length(s) = 5) and (s[5] in ['Z','z']) and
            (s[1] in ['0'..'9']) and (s[2] in ['0'..'9']) and
            (s[3] in ['0'..'9']) and (s[4] in ['0'..'9'])
end;

function ParseRbnSpot(const Line : String; out Spot : TRbnSpotLine) : Boolean;
var
  s     : String;
  Rest  : String;
  Colon : Integer;
  Dash  : Integer;
  n, i  : Integer;
  Last  : Integer;
begin
  Result := False;
  Spot := Default(TRbnSpotLine);

  s := TrimLeft(Line);
  if not AnsiStartsText(DX_DE, s) then
    exit;
  Colon := Pos(':', s);
  if Colon <= Length(DX_DE) then
    exit;

  Spot.Spotter := Trim(Copy(s, Length(DX_DE)+1, Colon-Length(DX_DE)-1));
  Dash := Pos('-', Spot.Spotter);
  if Dash > 0 then
    SetLength(Spot.Spotter, Dash-1);

  Rest := Copy(s, Colon+1, Length(s));
  n := WordCount(Rest, [' ']);
  if (Spot.Spotter = '') or (Pos(' ', Spot.Spotter) > 0) or (n < TOK_DB) or
     (not SameText(ExtractWord(TOK_DB, Rest, [' ']), 'dB')) then
  begin
    Spot := Default(TRbnSpotLine);
    exit
  end;

  Spot.FreqText := ExtractWord(TOK_FREQ, Rest, [' ']);
  Spot.Dx       := ExtractWord(TOK_DX, Rest, [' ']);
  Spot.Mode     := ExtractWord(TOK_MODE, Rest, [' ']);
  if (not TryStrToFloat(Spot.FreqText, Spot.FreqKHz, fsDot)) or (Spot.FreqKHz <= 0) or
     (not TryStrToInt(ExtractWord(TOK_SIGNAL, Rest, [' ']), Spot.SignalDb)) then
  begin
    Spot := Default(TRbnSpotLine);
    exit
  end;

  Last := n;
  if (n > TOK_DB) and IsTime(ExtractWord(n, Rest, [' '])) then
  begin
    Spot.TimeUtc := ExtractWord(n, Rest, [' ']);
    Dec(Last)
  end;
  for i := TOK_DB+1 to Last do
  begin
    if Spot.Info <> '' then
      Spot.Info := Spot.Info + ' ';
    Spot.Info := Spot.Info + ExtractWord(i, Rest, [' '])
  end;

  Result := True
end;

initialization
  fsDot := DefaultFormatSettings;
  fsDot.DecimalSeparator  := '.';
  fsDot.ThousandSeparator := #0;
end.
