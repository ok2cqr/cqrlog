(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ WinKeyer USB on a serial port.

  Moved here from uCWKeying (TCWWinKeyerUSB) without the LCL and the settings:
  the two things it asked the application for are virtual methods now.
  - PotSpeedEnabled: True when the speed comes from the keyer's pot, so
    SetSpeed must not override it.  Asked on every SetSpeed, the setting
    belongs to the radio in use and that can change without a new keyer.
  - HexError: an invalid "send hex commands" input.
  uCWKeying.TCWWinKeyerUSB answers them from the ini file and with a message
  box.  The bytes themselves come from uWinKeyerProtocol. }

unit uCWWinKeyer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, synaser, uCWDevice, uWinKeyerProtocol;

type
  TCWWinKeyer = class(TCWDevice)
    private
      fActive : Boolean;
      fSpeed  : Word;
      ser     : TBlockSerial;

    protected
      function  PotSpeedEnabled : Boolean; virtual;
      procedure HexError(const Msg : String); virtual;

    public
      constructor Create; override;
      destructor  Destroy; override;

      function GetSpeed  : Word; override;
      function GetStatus : TKeyStatus; override;

      procedure Open; override;
      procedure Close; override;
      procedure SetSpeed(speed : Word); override;
      procedure SendText(text : String); override;
      procedure SendHex(text:String);  override;
      procedure StopSending; override;
      procedure DelLastChar; override;
      procedure SetMixManSpeed(min,max : Word); override;
      procedure TuneStart; override;
      procedure TuneStop; override;
  end;

implementation

constructor TCWWinKeyer.Create;
begin
  fActive       := False;
  fDebugMode    := False;
  ser           := TBlockserial.Create;
  ser.LinuxLock := False;
  fMinSpeed     := 5;
  fMaxSpeed     := 60;
  fIsNewHamlib  :=false;
end;

function TCWWinKeyer.PotSpeedEnabled : Boolean;
begin
  Result := False
end;

procedure TCWWinKeyer.HexError(const Msg : String);
begin
  if fDebugMode then Writeln(Msg)
end;

procedure TCWWinKeyer.Open;
var
  rec : byte;
begin
  if fActive then
                 Begin
                   Close();
                   sleep (200);
                 end;
  if fDebugMode then Writeln('Device: ',fDevice);
  ser.RaiseExcept := False;
  ser.Connect(fDevice);
  ser.Config(1200,8,'N',2,false,false);
  ser.DTR:=True;
  ser.RTS:=False;
  fLastErrNr := ser.LastError;
  fLastErrSt := ser.LastErrorDesc;
  if fDebugMode then
  begin
    Writeln('Last error nr:  ',fLastErrNr);
    Writeln('Last error desc:',fLastErrSt)
  end;
  if LastErrNr > 0 then
    exit;
  ser.SendByte(WK_NULL);
  ser.SendByte(WK_NULL);  //sending null commands
  ser.SendByte(WK_NULL);
  sleep(300);
  if fDebugMode then Writeln('After sending null command');
  ser.SendByte(WK_ADMIN);
  ser.SendByte(WK_ADMIN_ECHO);  //send echo command
  ser.SendByte(20);
  sleep(300);
  while ser.CanReadex(10) do
  begin
    rec := (ser.recvByte(0))
  end;
  if fDebugMode then Writeln('After sending echo command: ',rec);
  if rec = 20 then
    fActive := True
  else begin
    fLastErrNr := 1000;
    fLastErrSt := 'WinKeyer USB inicialization failed';
    if fDebugMode then Writeln(fLastErrSt);
    exit
  end;
  ser.SendByte(WK_ADMIN);
  ser.SendByte(WK_ADMIN_OPEN); //enable communication
  sleep(50);
  while ser.CanReadex(10) do
  begin
    rec := (ser.recvByte(0))
  end;
  if fDebugMode then Writeln('Firmware version: ',rec);
  fActive := True;

  SetSpeed(fSpeed)
end;

procedure TCWWinKeyer.SetSpeed(speed : Word);
begin
  if fDebugMode then Writeln('Speed: ',speed);
  if PotSpeedEnabled then exit;
  fSpeed := speed;
  ser.Flush;
  ser.SendByte(WK_SET_SPEED);
  ser.SendByte(speed);
  sleep(50)
end;

function TCWWinKeyer.GetSpeed  : Word;
begin
  Result := fSpeed
end;

function TCWWinKeyer.GetStatus : TKeyStatus;
begin
  Result := ksBusy //not implemented, default value
end;

procedure TCWWinKeyer.DelLastChar;
begin
  ser.SendByte(WK_BACKSPACE)
end;

procedure TCWWinKeyer.SetMixManSpeed(min,max : Word);
begin
  ser.SendByte(WK_SET_MIN_MAX_SPEED);
  ser.SendByte(min);
  ser.SendByte(max)
end;

procedure TCWWinKeyer.TuneStart;
begin
  ser.SendByte(WK_KEY_IMMEDIATE);
  ser.SendByte(1)
end;

procedure TCWWinKeyer.TuneStop;
begin
  ser.SendByte(WK_KEY_IMMEDIATE);
  ser.SendByte(0)
end;

procedure TCWWinKeyer.StopSending;
begin
  ser.SendByte(WK_CLEAR_BUFFER)
end;

procedure TCWWinKeyer.SendText(text : String);
begin
  if not fActive then
    Begin
     if fDebugMode then Writeln('Winkeyer is not active. Can not send: ',text);
     exit
    end;
  text := UpperCase(text);
  if fDebugMode then Writeln('Sending text: ',text);
  ser.SendString(WinKeyerEncodeText(text, fSpeed, fMinSpeed, fMaxSpeed))
end;

procedure TCWWinKeyer.SendHex(text : String);
var
  Bytes, Err : String;
  i : Integer;
begin
  if not WinKeyerParseHex(text, Bytes, Err) then
  begin
    HexError(Err);
    exit
  end;
  for i:=1 to Length(Bytes) do
  begin
    if fDebugMode then Writeln('Sending value: ',IntToHex(Ord(Bytes[i]),2),'=',Ord(Bytes[i]));
    ser.SendByte(Ord(Bytes[i]))
  end
end;

procedure TCWWinKeyer.Close;
begin
  ser.SendByte(WK_ADMIN);
  ser.SendByte(WK_ADMIN_CLOSE); // close keyer
  if fDebugMode then Writeln('WinKeyer closed');
  ser.CloseSocket;
  fActive := False
end;

destructor TCWWinKeyer.Destroy;
begin
  if fActive then
    Close();
  FreeAndNil(ser)
end;

end.
