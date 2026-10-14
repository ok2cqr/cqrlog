(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Bytes sent to the WinKeyer for text and for the "send hex commands" menu.
  The expected results follow what TCWWinKeyerUSB sent before the encoding
  moved to uWinKeyerProtocol. }

unit tWinKeyerProtocol;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uWinKeyerProtocol;

type
  TWinKeyerTextTest = class(TTestCase)
  published
    procedure PlainTextGoesAsIs;
    procedure PlainTextKeepsPunctuation;
    procedure EmptyText;
    procedure PlusRaisesSpeedByFive;
    procedure MinusLowersSpeedByFive;
    procedure SpeedChangesAccumulate;
    procedure SpeedIsClampedToMax;
    procedure SpeedIsClampedToMin;
    procedure ProsignsWhenSpeedChanges;
  end;

  TWinKeyerHexTest = class(TTestCase)
  published
    procedure PlainAndPrefixedBytes;
    procedure OnlyTwoDigitsAfterX;
    procedure SpaceAfterComma;
    procedure NotHex;
    procedure ValueTooBig;
    procedure ErrorInLaterItemSendsNothing;
    procedure EmptyText;
  end;

implementation

function B(const Bytes : array of Byte) : RawByteString;
var
  i : Integer;
begin
  SetLength(Result, Length(Bytes));
  for i := 0 to High(Bytes) do
    Result[i+1] := Chr(Bytes[i])
end;

procedure TWinKeyerTextTest.PlainTextGoesAsIs;
begin
  AssertEquals('CQ OK2CQR', WinKeyerEncodeText('CQ OK2CQR', 25, 5, 60))
end;

procedure TWinKeyerTextTest.PlainTextKeepsPunctuation;
begin
  //without + or - the prosign translation is skipped, the keyer gets the characters
  AssertEquals('OK2CQR/P ?', WinKeyerEncodeText('OK2CQR/P ?', 25, 5, 60))
end;

procedure TWinKeyerTextTest.EmptyText;
begin
  AssertEquals('', WinKeyerEncodeText('', 25, 5, 60))
end;

procedure TWinKeyerTextTest.PlusRaisesSpeedByFive;
begin
  AssertEquals('5NN '+B([$1C, 30])+'TU'+B([$1F]), WinKeyerEncodeText('5NN +TU', 25, 5, 60))
end;

procedure TWinKeyerTextTest.MinusLowersSpeedByFive;
begin
  AssertEquals(B([$1C, 20])+'OK2CQR'+B([$1F]), WinKeyerEncodeText('-OK2CQR', 25, 5, 60))
end;

procedure TWinKeyerTextTest.SpeedChangesAccumulate;
begin
  AssertEquals(B([$1C, 30, $1C, 35])+'A'+B([$1C, 30])+'B'+B([$1F]),
    WinKeyerEncodeText('++A-B', 25, 5, 60))
end;

procedure TWinKeyerTextTest.SpeedIsClampedToMax;
begin
  AssertEquals(B([$1C, 60, $1C, 60, $1F]), WinKeyerEncodeText('++', 58, 5, 60))
end;

procedure TWinKeyerTextTest.SpeedIsClampedToMin;
begin
  AssertEquals(B([$1C, 5, $1F]), WinKeyerEncodeText('-', 7, 5, 60))
end;

procedure TWinKeyerTextTest.ProsignsWhenSpeedChanges;
begin
  AssertEquals(B([$1C, 30])+
    B([$1B])+'DN'+B([$1B])+'UD'+B([$1B])+'BT'+B([$1B])+'ZM'+B([$1B])+'KN'+B([$1B])+'AA'+
    B([$1B])+'AR'+B([$1B])+'SK'+B([$1B])+'KN'+B([$1B])+'KK'+B([$1B])+'AC'+'X'+B([$1F]),
    WinKeyerEncodeText('+/?=.:;<>()@X', 25, 5, 60))
end;

procedure TWinKeyerHexTest.PlainAndPrefixedBytes;
var
  Bytes, Err : String;
begin
  AssertTrue(WinKeyerParseHex('0X1F,X0A,FF', Bytes, Err));
  AssertEquals(B([$1F, $0A, $FF]), Bytes);
  AssertEquals('', Err)
end;

procedure TWinKeyerHexTest.OnlyTwoDigitsAfterX;
var
  Bytes, Err : String;
begin
  AssertTrue(WinKeyerParseHex('X1FF', Bytes, Err));
  AssertEquals(B([$1F]), Bytes)
end;

procedure TWinKeyerHexTest.SpaceAfterComma;
var
  Bytes, Err : String;
begin
  AssertTrue(WinKeyerParseHex('0A, 0B', Bytes, Err));
  AssertEquals(B([$0A, $0B]), Bytes)
end;

procedure TWinKeyerHexTest.NotHex;
var
  Bytes, Err : String;
begin
  AssertFalse(WinKeyerParseHex('0A,ZZ', Bytes, Err));
  AssertEquals('', Bytes);
  AssertTrue(Err, Pos(' Hex error: ZZ EConvertError'#13#10, Err) = 1)
end;

procedure TWinKeyerHexTest.ValueTooBig;
var
  Bytes, Err : String;
begin
  AssertFalse(WinKeyerParseHex('100', Bytes, Err));
  AssertEquals(' Hex error: 100 Value too big', Err)
end;

procedure TWinKeyerHexTest.ErrorInLaterItemSendsNothing;
var
  Bytes, Err : String;
begin
  AssertFalse(WinKeyerParseHex('00,03,1FF', Bytes, Err));
  AssertEquals('', Bytes)
end;

procedure TWinKeyerHexTest.EmptyText;
var
  Bytes, Err : String;
begin
  AssertTrue(WinKeyerParseHex('', Bytes, Err));
  AssertEquals('', Bytes)
end;

initialization
  RegisterTest(TWinKeyerTextTest);
  RegisterTest(TWinKeyerHexTest)
end.
