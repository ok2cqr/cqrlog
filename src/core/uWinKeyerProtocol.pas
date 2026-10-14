(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ What goes over the wire to a WinKeyer, without the serial port.

  WinKeyerEncodeText turns the text to send into keyer bytes.  Text with no
  '+' or '-' goes as is.  Otherwise every '+'/'-' becomes a buffered speed change
  (5 WPM up/down, kept within MinSpeed..MaxSpeed), punctuation becomes a merged
  prosign and a "cancel buffered speed change" ends the text.

  WinKeyerParseHex reads the comma separated hex bytes from the "send hex
  commands" menu ("0xff", "xff" or "ff").  Nothing is sent unless every item
  is valid.

  Moved here from TCWWinKeyerUSB (SendText, SendHex) to be testable without
  LCL and a keyer.  No LCL, no globals; see tests/tWinKeyerProtocol.pas. }

unit uWinKeyerProtocol;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils;

const
  WK_ADMIN               = $00; //followed by an admin command byte
  WK_ADMIN_CLOSE         = $03;
  WK_ADMIN_OPEN          = $02;
  WK_ADMIN_ECHO          = $04;
  WK_SET_SPEED           = $02;
  WK_SET_MIN_MAX_SPEED   = $05;
  WK_BACKSPACE           = $08;
  WK_CLEAR_BUFFER        = $0A;
  WK_KEY_IMMEDIATE       = $0B; //tune: followed by 1 (key down) or 0 (key up)
  WK_NULL                = $13;
  WK_BUFFERED_MERGE      = $1B; //followed by two letters sent as one prosign
  WK_BUFFERED_SPEED      = $1C;
  WK_CANCEL_BUFFERED_SPEED = $1F;

function WinKeyerEncodeText(const Text : String; Speed, MinSpeed, MaxSpeed : Integer) : String;
//False if any item is not a hex byte; Bytes is then empty and ErrorMsg says
//which item failed
function WinKeyerParseHex(const Text : String; out Bytes : String; out ErrorMsg : String) : Boolean;

implementation

function WinKeyerEncodeText(const Text : String; Speed, MinSpeed, MaxSpeed : Integer) : String;
var
  i   : Integer;
  spd : Integer;

  procedure Merge(const Letters : String);
  begin
    Result := Result + Chr(WK_BUFFERED_MERGE) + Letters
  end;

begin
  if (Pos('+',Text) = 0) and (Pos('-',Text) = 0) then
    exit(Text);
  Result := '';
  spd := Speed;
  for i:=1 to Length(Text) do
  begin
    if Text[i] = '+' then
    begin
      spd := spd+5;
      if spd>MaxSpeed then spd:=MaxSpeed;
      Result := Result + Chr(WK_BUFFERED_SPEED) + Chr(Byte(spd));
      Continue
    end
    else begin
      if Text[i] = '-' then
      begin
        spd := spd-5;
        if spd<MinSpeed then spd:=MinSpeed;
        Result := Result + Chr(WK_BUFFERED_SPEED) + Chr(Byte(spd));
        Continue
      end
    end;
    case Text[i] of
      '/' : Merge('DN');
      '?' : Merge('UD');
      '=' : Merge('BT');
      '.' : Merge('ZM');
      ':' : Merge('KN');
      ';' : Merge('AA');
      '<' : Merge('AR');
      '>' : Merge('SK');
      '(' : Merge('KN');
      ')' : Merge('KK');
      '@' : Merge('AC');
      //'ß' SZ, 'Ü' IM, 'Ö' OE, 'Ä' AA were never enabled
      else
        Result := Result + Text[i]
    end //case
  end;
  Result := Result + Chr(WK_CANCEL_BUFFERED_SPEED)
end;

function WinKeyerParseHex(const Text : String; out Bytes : String; out ErrorMsg : String) : Boolean;
var
  H         : String;
  p         : Integer;
  index     : Integer;
  paramList : TStringList;
begin
  Result   := True;
  Bytes    := '';
  ErrorMsg := '';
  paramList := TStringList.Create;
  try
    paramList.Delimiter := ',';
    paramList.DelimitedText := Text;
    for index:=0 to paramList.Count-1 do
    begin
      try
        if Pos('X', paramList[index])>0 then
          H:=copy(paramList[index],Pos('X', paramList[index])+1,2)
        else
          H:= paramList[index];
        p:=Hex2Dec(H);
      except
        on E: Exception do
        begin
          ErrorMsg := ' Hex error: '+paramList[index]+' '+ E.ClassName + #13#10 + E.Message;
          Bytes  := '';
          exit(False)
        end
      end;
      if p>255 then
      begin
        ErrorMsg := ' Hex error: '+paramList[index]+' Value too big';
        Bytes  := '';
        exit(False)
      end;
      Bytes := Bytes + Chr(p)
    end
  finally
    paramList.Free
  end
end;

end.
