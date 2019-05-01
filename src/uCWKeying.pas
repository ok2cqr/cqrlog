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
      fPortSpeed : Word;
    public
      property Port      : String read fPort write fPort;
      property Device    : String read fDevice write fDevice;
      property LastErrNr : Word read fLastErrNr;
      property LastErrSt : String read fLastErrSt;
      property DebugMode : Boolean read fDebugMode write fDebugMode;
      property MinSpeed  : Word read fMinSpeed;
      property MaxSpeed  : Word read fMaxSpeed;
      property PortSpeed : Word read fPortSpeed write fPortSpeed;

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

  TCWK3NG = class(TCWDevice)
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

  TCWHamLib = class(TCWDevice)
    private
      fActive : Boolean;
      fSpeed  : Word;
      tcp     : TLTCPComponent;
      Rmsg    : String;
      procedure OnReceived(aSocket: TLSocket);
      procedure OnHamLibConnect(aSocket: TLSocket);
      procedure OnHamLibError(const msg: AnsiString; aSocket: TLSocket);
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

uses fTRXControl;

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
  fSpeed := speed;
  ser.Flush;
  ser.SendByte(2);
  ser.SendByte(speed);
  sleep(50)
end;

function TCWWinKeyerUSB.GetSpeed  : Word;
begin
  Result := fSpeed
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

constructor TCWK3NG.Create;
begin
  fActive       := False;
  fDebugMode    := False;
  ser           := TBlockserial.Create;
  ser.LinuxLock := False;
  fMinSpeed     := 5;
  fMaxSpeed     := 60
end;

procedure TCWK3NG.Open;
var
  rec : byte;
begin
  if fActive then Close();

  if fDebugMode then Writeln('Device: ',fDevice);
  ser.RaiseExcept := False;
  ser.Connect(fDevice);
  ser.Config(fPortSpeed,8,'N',2,false,false);
  ser.DTR := False;
  ser.RTS := False;
  fLastErrNr := ser.LastError;
  fLastErrSt := ser.LastErrorDesc;
  if fDebugMode then
  begin
    Writeln('Last error nr:  ',fLastErrNr);
    Writeln('Last error desc:',fLastErrSt)
  end;
  if LastErrNr > 0 then
    exit;
  fActive := True;
  SetSpeed(fSpeed)
end;

procedure TCWK3NG.SetSpeed(speed : Word);
begin
  Writeln(Speed);
  fSpeed := speed;
  ser.SendByte($5C);
  ser.SendByte($57);
  ser.SendString(IntToStr(speed));
  ser.SendString(CR)
end;

function TCWK3NG.GetSpeed  : Word;
begin
  Result := fSpeed
end;

function TCWK3NG.GetStatus : TKeyStatus;
begin
  Result := ksBusy //not implemented, yet
end;

procedure TCWK3NG.DelLastChar;
begin
  //not implemented
end;

procedure TCWK3NG.SetMixManSpeed(min,max : Word);
begin
  //not supported
end;

procedure TCWK3NG.TuneStart;
begin
  ser.SendByte($5C);
  ser.SendByte($54)
end;

procedure TCWK3NG.TuneStop;
begin
  StopSending
end;

procedure TCWK3NG.StopSending;
begin
  if fActive then
  begin
    ser.SendByte($5C);
    ser.SendByte($5C)
  end
end;

procedure TCWK3NG.SendText(text : String);

  procedure ChangeSpeed(spd : Word);
  begin
    ser.SendByte($5C);
    ser.SendByte($57);
    ser.SendString(IntToStr(spd));
    ser.SendString(CR)
  end;

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
        ChangeSpeed(spd)
      end
      else begin
        if text[i] = '-' then
        begin
          spd := spd-5;
          ChangeSpeed(spd)
        end
        else
          ser.SendString(text[i])
      end
    end;
    ChangeSpeed(old_spd)
  end
  else
    ser.SendString(text)
end;

procedure TCWK3NG.Close;
begin
  if fDebugMode then Writeln('K3NG keyer closed');
  ser.CloseSocket;
  fActive := False
end;


destructor TCWK3NG.Destroy;
begin
  if fActive then
    Close();
  FreeAndNil(ser)
end;

constructor TCWHamLib.Create;
begin
  fActive       := False;
  fDebugMode    := False;
  tcp           := TLTCPComponent.Create(nil);
  tcp.ReuseAddress:= True;
  tcp.OnReceive := @OnReceived;
  tcp.OnConnect := @OnHamLibConnect;
  tcp.OnError   := @onHamLibError;
  fMinSpeed     := 5;
  fMaxSpeed     := 60
end;

procedure TCWHamLib.OnHamLibConnect(aSocket: TLSocket);
begin
  fActive := True;
  if DebugMode then
     Writeln('CWint connected to hamlib');

  tcp.SendMessage('fmv'+LineEnding);
  SetSpeed(fSpeed)
end;

procedure TCWHamLib.OnHamLibError(const msg: AnsiString; aSocket: TLSocket);
begin
  if DebugMode then
     Writeln('CWint connect to hamlib FAILED: '+msg);

  fActive := False
end;

procedure TCWHamLib.Open;
begin
  if fActive then Close();

  if fDebugMode then
  begin
    Writeln('address: ',fDevice);
    Writeln('port:    ',fPort)
  end;
  tcp.Host := fDevice;
  tcp.Port := StrToInt(fPort);
  tcp.Connect(fDevice,StrToInt(fPort));
end;

procedure TCWHamLib.OnReceived(aSocket: TLSocket);

begin
  if aSocket.GetMessage(Rmsg) > 0 then
    if DebugMode then
       Writeln('HLresp MSG:|',Rmsg,'|');

  //at this point no proper buffer overflow handling implemented.
  //RPRT -9 comes here too late and can not control sed loop
  //Now just tries stop CW so that operator knows he is sending too long text and resuld may be chaos
  if pos('RPRT -9',Rmsg)>0 then  StopSending;
end;


procedure TCWHamLib.SetSpeed(speed : Word);
begin
  fSpeed := speed;
  if fActive then
    tcp.SendMessage('L KEYSPD '+IntToStr(speed)+LineEnding);
  if fDebugMode then
    Writeln('CW speed changed to:',fSpeed)
end;

function TCWHamLib.GetSpeed  : Word;
begin
  Result := fSpeed
end;

function TCWHamLib.GetStatus : TKeyStatus;
begin
  Result := ksBusy //not implemented, yet
end;

procedure TCWHamLib.DelLastChar;
begin
  //not implemented
end;

procedure TCWHamLib.SetMixManSpeed(min,max : Word);
begin
  //not supported
end;

procedure TCWHamLib.TuneStart;
begin
  //supported via AM mode
  frmTRXControl.HLTune(true);
end;

procedure TCWHamLib.TuneStop;
begin
  //supported via AM mode
  frmTRXControl.HLTune(false);
end;

procedure TCWHamLib.StopSending;
begin
  //not implemented in hamlib command set
  //sending 0xFF as text works with Icom
  tcp.SendMessage('b'+#$0FF+LineEnding);
  //All chrs are spaces stops cw for kenwood. Empty chrs (max24) in buffer are filled with spaces.
  // (info by ts480 manual, not tested)
  tcp.SendMessage('b '+LineEnding);
end;

procedure TCWHamLib.SendText(text : String);
var c:integer;

begin
   if text<>'' then
       begin
        c:= length(text);
        if c>10 then
         Begin
        //different rigs support different length of b-command. 10chr should be safe for all
        repeat
          Begin
            Rmsg :='';
            tcp.SendMessage('b'+copy(text,1,10)+LineEnding);
            if fDebugMode then
               Begin
                 Writeln('Sending HL-block:',copy(text,1,10));
               end;
            text := copy(text,11,length(text));
            c:= length(text);
          end;
        until c=0;
        end
        else
         Begin
           tcp.SendMessage('b'+text+LineEnding);
           if fDebugMode then  Writeln('Sending HL-message:','b'+text+LineEnding);
         end;
       end
        else  if fDebugMode then  Writeln('Empty message!');
end;

procedure TCWHamLib.Close;
begin
  if tcp.Connected then
    tcp.Disconnect;
  fActive := False
end;

destructor TCWHamLib.Destroy;
begin
  if fActive then
    Close();
  FreeAndNil(tcp);
  if fDebugMode then
    Writeln('Keying over HamLib closed')
end;

end.
