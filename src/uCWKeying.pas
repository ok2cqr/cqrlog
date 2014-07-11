unit uCWKeying;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, synaser, synautil, lNet, lNetComponents;

type TKeyType   = (ktCWdaemon, ktWinKeyer);
type TKeyStatus = (ksReady, ksBusy);

type
  TCWDevice = class
    protected
      fPort      : String;
      fLastErrNr : Word;
      fLastErrSt : String;
      fDevice    : String;
      fDebugMode : Boolean;
      fMinSpeed  : Word;
      fMaxSpeed  : Word;
    public
      property Port      : String read fPort write fPort;
      property Device    : String read fDevice write fDevice;
      property LastErrNr : Word read fLastErrNr;
      property LastErrSt : String read fLastErrSt;
      property DebugMode : Boolean read fDebugMode write fDebugMode;
      property MinSpeed  : Word read fMinSpeed;
      property MaxSpeed  : Word read fMaxSpeed;

      constructor Create; virtual; abstract;

      function GetSpeed  : Word; virtual; abstract;
      function GetStatus : TKeyStatus; virtual; abstract;

      procedure Open; virtual; abstract;
      procedure Close; virtual; abstract;
      procedure SetSpeed(speed : Word); virtual; abstract;
      procedure SendText(text : String); virtual; abstract;
      procedure StopSending; virtual; abstract;
      procedure DelLastChar; virtual; abstract;
      procedure SetMixManSpeed(min,max : Word); virtual; abstract;
      procedure TuneStart; virtual; abstract;
      procedure TuneStop; virtual; abstract;
  end;

  TCWWinKeyerUSB = class(TCWDevice)
    private
      fActive : Boolean;
      fSpeed  : Word;
      ser     : TBlockSerial;
    public
      constructor Create; override;
      destructor  Destroy; override;

      function GetSpeed  : Word; override;
      function GetStatus : TKeyStatus; override;

      procedure Open; override;
      procedure Close; override;
      procedure SetSpeed(speed : Word); override;
      procedure SendText(text : String); override;
      procedure StopSending; override;
      procedure DelLastChar; override;
      procedure SetMixManSpeed(min,max : Word); override;
      procedure TuneStart; override;
      procedure TuneStop; override;
  end;

  TCWDaemon = class(TCWDevice)
    private
      fActive : Boolean;
      fSpeed  : Word;
      udp     : TLUDPComponent;
    public
      constructor Create; override;
      destructor  Destroy; override;

      function GetSpeed  : Word; override;
      function GetStatus : TKeyStatus; override;

      procedure Open; override;
      procedure Close; override;
      procedure SetSpeed(speed : Word); override;
      procedure SendText(text : String); override;
      procedure StopSending; override;
      procedure DelLastChar; override;
      procedure SetMixManSpeed(min,max : Word); override;
      procedure TuneStart; override;
      procedure TuneStop; override;
  end;

implementation


constructor TCWWinKeyerUSB.Create;
begin
  fActive       := False;
  fDebugMode    := False;
  ser           := TBlockserial.Create;
  ser.LinuxLock := False;
  fMinSpeed     := 5;
  fMaxSpeed     := 60
end;

procedure TCWWinKeyerUSB.Open;
var
  rec : byte;
begin
  if fActive then Close();

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
  ser.SendByte($13);
  ser.SendByte($13);  //sending null commands
  ser.SendByte($13);
  sleep(50);
  if fDebugMode then Writeln('After sending null command');
  ser.SendByte(0);
  ser.SendByte(4);  //send echo command
  ser.SendByte(20);
  sleep(50);
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
    exit
  end;
  ser.SendByte(0);
  ser.SendByte(2); //enable communication
  sleep(50);
  while ser.CanReadex(10) do
  begin
    rec := (ser.recvByte(0))
  end;
  if fDebugMode then Writeln('Firmware version: ',rec);
  fActive := True;

  SetSpeed(fSpeed)
end;

procedure TCWWinKeyerUSB.SetSpeed(speed : Word);
begin
  if fDebugMode then Writeln('Speed: ',speed);
  ser.Flush;
  ser.SendByte(2);
  ser.SendByte(speed);
  sleep(50)
end;

function TCWWinKeyerUSB.GetSpeed  : Word;
var
  rec : Byte;
begin
  ser.SendByte(7); //enable communication
  sleep(50);
  while ser.CanReadex(10) do
  begin
    rec := (ser.recvByte(0))
  end;
  Result := fMinSpeed + rec
end;

function TCWWinKeyerUSB.GetStatus : TKeyStatus;
begin
  Result := ksBusy //not implemented, default value
end;

procedure TCWWinKeyerUSB.DelLastChar;
begin
  ser.SendByte($8)
end;

procedure TCWWinKeyerUSB.SetMixManSpeed(min,max : Word);
begin
  ser.SendByte(5);
  ser.SendByte(min);
  ser.SendByte(max)
end;

procedure TCWWinKeyerUSB.TuneStart;
begin
  ser.SendByte($0B);
  ser.SendByte(1)
end;

procedure TCWWinKeyerUSB.TuneStop;
begin
  ser.SendByte($0B);
  ser.SendByte(0)
end;

procedure TCWWinKeyerUSB.StopSending;
begin
  ser.SendByte($A)
end;

procedure TCWWinKeyerUSB.SendText(text : String);
var
  i : Integer;
  spd : Integer;
begin
  spd  := fSpeed;
  text := UpperCase(text);
  if fDebugMode then Writeln('Sending text: ',text);
  if (Pos('+',text) > 0) or (Pos('-',text) > 0) then
  begin
    for i:=1 to Length(text) do
    begin
      if text[i] = '+' then
      begin
        spd := spd+5;
        ser.SendByte($1C);
        ser.SendByte(spd);
        Continue
      end
      else begin
        if text[i] = '-' then
        begin
          spd := spd-5;
          ser.SendByte($1C);
          ser.SendByte(spd);
          Continue
        end
      end;
      case text[i] of
        '/' : begin
                ser.SendByte($1B);
                ser.SendString('D');
                ser.SendString('N');
              end;
        '?' : begin
                ser.SendByte($1B);
                ser.SendString('U');
                ser.SendString('D');
              end;
        '=' : begin
                ser.SendByte($1B);
                ser.SendString('B');
                ser.SendString('T');
              end;
        '.' : begin
                ser.SendByte($1B);
                ser.SendString('Z');
                ser.SendString('M');
              end;
        ':' : begin
                ser.SendByte($1B);
                ser.SendString('K');
                ser.SendString('N');
              end;
        ';' : begin
                ser.SendByte($1B);
                ser.SendString('A');
                ser.SendString('A');
              end;
        '<' : begin
                ser.SendByte($1B);
                ser.SendString('A');
                ser.SendString('R');
              end;
        '>' : begin
                ser.SendByte($1B);
                ser.SendString('S');
                ser.SendString('K');
              end;
        '(' : begin
                ser.SendByte($1B);
                ser.SendString('K');
                ser.SendString('N');
              end;
        ')' : begin
                ser.SendByte($1B);
                ser.SendString('K');
                ser.SendString('K');
              end;
        '@' : begin
                ser.SendByte($1B);
                ser.SendString('A');
                ser.SendString('C');
              end;
{        'ß' : begin
                ser.SendByte($1B);
                ser.SendString('S');
                ser.SendString('Z');
              end;
        'Ü' : begin
                ser.SendByte($1B);
                ser.SendString('I');
                ser.SendString('M');
              end;
        'Ö' : begin
                ser.SendByte($1B);
                ser.SendString('O');
                ser.SendString('E');
              end;
        'Ä' : begin
                ser.SendByte($1B);
                ser.SendString('A');
                ser.SendString('A');
              end
            }
        else
          Ser.SendString(text[i])
      end //case
    end;
    ser.SendByte($1F)
  end
  else
    ser.SendString(text)
end;

procedure TCWWinKeyerUSB.Close;
begin
  ser.SendByte(0);
  ser.SendByte(3); // close keyer
  if fDebugMode then Writeln('WinKeyer closed');
  ser.CloseSocket;
  fActive := False
end;

destructor TCWWinKeyerUSB.Destroy;
begin
  if fActive then
    Close();
  FreeAndNil(ser)
end;


constructor TCWDaemon.Create;
begin
  fActive       := False;
  fDebugMode    := False;
  udp           := TLUDPComponent.Create(nil);
  fMinSpeed     := 5;
  fMaxSpeed     := 60
end;

procedure TCWDaemon.Open;
begin
  if fDebugMode then
  begin
    Writeln('address: ',fDevice);
    Writeln('port:    ',fPort)
  end;
  udp.Host := fDevice;
  udp.Port := StrToInt(fPort);
  fActive  := udp.Connect;

  SetSpeed(fSpeed)
end;

procedure TCWDaemon.SetSpeed(speed : Word);
begin
  fSpeed := speed;
  if fActive then
    udp.SendMessage(Chr(27)+'2'+IntToStr(speed))
end;

function TCWDaemon.GetSpeed  : Word;
begin
  Result := fSpeed
end;

function TCWDaemon.GetStatus : TKeyStatus;
begin
  Result := ksBusy //not implemented, yet
end;

procedure TCWDaemon.DelLastChar;
begin
  //not implemented
end;

procedure TCWDaemon.SetMixManSpeed(min,max : Word);
begin
  //not supported in cwdaemon
end;

procedure TCWDaemon.TuneStart;
begin
  if fActive then
    udp.SendMessage(Chr(27)+'c10')
end;

procedure TCWDaemon.TuneStop;
begin
  if fActive then
    udp.SendMessage(Chr(27)+'c0')
end;

procedure TCWDaemon.StopSending;
begin
  if fActive then
    udp.SendMessage(Chr(27)+'4')
end;

procedure TCWDaemon.SendText(text : String);
var
  i   : Integer;
  spd : Word;
  old_spd : Word = 0;
begin
  if not fActive then
    exit;

  text := UpperCase(Trim(text));
  if text = '' then
    exit;
  spd     := fSpeed;
  old_spd := spd;
  if (Pos('+',text) > 0) or (Pos('-',text) > 0) then
  begin
    for i:=1 to Length(text) do
    begin
      if text[i] = '+' then
      begin
        spd := spd+5;
        udp.SendMessage(Chr(27)+'2'+IntToStr(spd))
      end
      else begin
        if text[i] = '-' then
        begin
          spd := spd-5;
          udp.SendMessage(Chr(27)+'2'+IntToStr(spd))
        end
        else
          udp.SendMessage(text[i])
      end
    end;
    udp.SendMessage(Chr(27)+'2'+IntToStr(old_spd))
  end
  else
    udp.SendMessage(text)
end;

procedure TCWDaemon.Close;
begin
  if udp.Connected then
    udp.Disconnect;
  fActive := False
end;

destructor TCWDaemon.Destroy;
begin
  if fActive then
    Close();
  FreeAndNil(udp)
end;

end.
