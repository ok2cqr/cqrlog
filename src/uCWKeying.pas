unit uCWKeying;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, synaser, synautil, lNet, lNetComponents, Forms, Dialogs, StrUtils;

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
      fHamlibBuffer : Boolean;
      fIsNewHamlib  : Boolean; //Hamlib version date higer than 2023-06-01
      fMinSpeed  : Word;
      fMaxSpeed  : Word;
      fPortSpeed : dWord;
    public
      property Port      : String read fPort write fPort;
      property Device    : String read fDevice write fDevice;
      property LastErrNr : Word read fLastErrNr;
      property LastErrSt : String read fLastErrSt;
      property DebugMode : Boolean read fDebugMode write fDebugMode;
      property MinSpeed  : Word read fMinSpeed;
      property MaxSpeed  : Word read fMaxSpeed;
      property PortSpeed : dWord read fPortSpeed write fPortSpeed;
      property HamlibBuffer : Boolean read  fHamlibBuffer write fHamlibBuffer;
      property IsNewHamlib : Boolean read  fIsNewHamlib; //used internally, but can give info out

      constructor Create; virtual; abstract;

      function GetSpeed  : Word; virtual; abstract;
      function GetStatus : TKeyStatus; virtual; abstract;

      procedure Open; virtual; abstract;
      procedure Close; virtual; abstract;
      procedure SetSpeed(speed : Word); virtual; abstract;
      procedure SendText(text : String); virtual; abstract;
      procedure SendHex(text:String);  virtual; abstract;
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
      procedure SendHex(text:String);  override;
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
      procedure SendHex(text:String);  override;
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
      procedure SendHex(text:String);  override;
      procedure StopSending; override;
      procedure DelLastChar; override;
      procedure SetMixManSpeed(min,max : Word); override;
      procedure TuneStart; override;
      procedure TuneStop; override;
  end;

  TCWHamLib = class(TCWDevice)
    private
      ParamChkVfo: boolean;
      WaitChkVfo: integer;
      WaitHamlib: boolean;
      VfoStr : String;
      AllowCW : Boolean;
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
      procedure WaitMorse;
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

uses fTRXControl, uMyIni;

constructor TCWWinKeyerUSB.Create;
begin
  fActive       := False;
  fDebugMode    := False;
  ser           := TBlockserial.Create;
  ser.LinuxLock := False;
  fMinSpeed     := 5;
  fMaxSpeed     := 60;
  fIsNewHamlib  :=false;
end;

procedure TCWWinKeyerUSB.Open;
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
  ser.SendByte($13);
  ser.SendByte($13);  //sending null commands
  ser.SendByte($13);
  sleep(300);
  if fDebugMode then Writeln('After sending null command');
  ser.SendByte(0);
  ser.SendByte(4);  //send echo command
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
  if cqrini.ReadBool('CW'+IntToStr(frmTRXControl.cmbRig.ItemIndex),'PotSpeed',False) then exit;
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
  if not fActive then
    Begin
     if fDebugMode then Writeln('Winkeyer is not active. Can not send: ',text);
     exit
    end;
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
        if spd>fMaxSpeed then spd:=fMaxSpeed;
        ser.SendByte($1C);
        ser.SendByte(spd);
        Continue
      end
      else begin
        if text[i] = '-' then
        begin
          spd := spd-5;
          if spd<fMinSpeed then spd:=fMinSpeed;
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
 {      'ß' : begin
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

procedure TCWWinKeyerUSB.SendHex(text : String);
var
  H       : String;
  p       : integer;
  index     :integer;
  paramList :TStringList;

function send(ok:boolean):boolean;
Begin
  Result:=true;
  try
    index:=0;
    paramList := TStringList.Create;
    paramList.Delimiter := ',';
    paramList.DelimitedText := text;
    while index < paramList.Count do
    begin
      try
       if Pos('X', paramList[index])>0 then
          H:=copy(paramList[index],Pos('X', paramList[index])+1,2)
        else
          H:= paramList[index];
       p:=Hex2Dec(H);
      except
       on E: Exception do
         Begin
           ShowMessage( ' Hex error: '+paramList[index]+' '+ E.ClassName + #13#10 + E.Message );
           Result:=false;
           exit;
         end;
      end;
      if p>255 then
         Begin
           ShowMessage( ' Hex error: '+paramList[index]+' Value too big' );
           Result:=false;
           exit;
         end;
      if fDebugMode and ok then Writeln('Sending value: ',paramList[index],'=',p);
      if ok then ser.SendByte(p);
      inc(index);
    end;

    paramList.Free;
   finally
     //Done all
   end;
end;

begin
  //test hex conversion
  if not send(false) then exit;
  //if passed do real send
  send(true);
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
        if spd>fMaxSpeed then spd:=fMaxSpeed;
        udp.SendMessage(Chr(27)+'2'+IntToStr(spd))
      end
      else begin
        if text[i] = '-' then
        begin
          spd := spd-5;
          if spd<fMinSpeed then spd:=fMinSpeed;
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
procedure TCWDaemon.SendHex(text : String);
Begin
  //not implemented
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
        if spd>fMaxSpeed then spd:=fMaxSpeed;
        ChangeSpeed(spd)
      end
      else begin
        if text[i] = '-' then
        begin
          spd := spd-5;
          if spd<fMinSpeed then spd:=fMinSpeed;
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
procedure TCWK3NG.SendHex(text : String);
  var
    H       : String;
    p       : integer;
    index     :integer;
    paramList :TStringList;

  function send(ok:boolean):boolean;
  Begin
    Result:=true;
    try
      index:=0;
      paramList := TStringList.Create;
      paramList.Delimiter := ',';
      paramList.DelimitedText := text;
      while index < paramList.Count do
      begin
        try
         if Pos('X', paramList[index])>0 then
            H:=copy(paramList[index],Pos('X', paramList[index])+1,2)
          else
            H:= paramList[index];
         p:=Hex2Dec(H);
        except
         on E: Exception do
           Begin
             ShowMessage( ' Hex error: '+paramList[index]+' '+ E.ClassName + #13#10 + E.Message );
             Result:=false;
             exit;
           end;
        end;
        if p>255 then
           Begin
             ShowMessage( ' Hex error: '+paramList[index]+' Value too big' );
             Result:=false;
             exit;
           end;
        if fDebugMode and ok then Writeln('Sending value: ',paramList[index],'=',p);
        if ok then ser.SendByte(p);
        inc(index);
      end;

      paramList.Free;
     finally
       //Done all
     end;
  end;

  begin
    //test hex conversion
    if not send(false) then exit;
    //if passed do real send
    send(true);
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
  fMaxSpeed     := 60;
  fHamlibBuffer := false;
end;

procedure TCWHamLib.OnHamLibConnect(aSocket: TLSocket);
begin
  fActive := True;
  if DebugMode then
     Writeln('CWint connected to hamlib');

  fIsNewHamlib  := false;
  WaitHamlib    := True;
  VfoStr := '';
  ParamChkVfo :=false;
  WaitChkVfo:=5; // wait max 5 rcvd blocks
  tcp.SendMessage('+\chk_vfo'+LineEnding);
  if DebugMode then
     Writeln('CW send +\chk_vfo');

end;

procedure TCWHamLib.OnReceived(aSocket: TLSocket);
begin
  if aSocket.GetMessage(Rmsg) > 0 then
   begin
     Rmsg := StringReplace(Rmsg,LineEnding,' ',[rfReplaceAll]);

     if (( not ParamChkVfo ) and (WaitChkVfo>0))then
       Begin
         dec(WaitChkVfo);
         if (pos('CHKVFO',Uppercase(Rmsg))>0) then
         Begin
           if (pos('1',Rmsg)>0) then
                                  VfoStr:=' currVFO';
           if DebugMode then
               Writeln('CW commands need parameter: ',VfoStr);
           WaitChkVfo:=0;
           tcp.SendMessage('+\dump_caps'+LineEnding);
           if DebugMode then
             Writeln('CW send +\dump_caps');
         end;
        ParamChkVfo:= WaitChkVfo < 1;
       end;

     if (pos('HAMLIB VERSION:',Uppercase(Rmsg))>0) and WaitHamlib then
         Begin
          fIsNewHamlib:=true;
          WaitHamlib:=False;
          if DebugMode then
               Writeln('Hamlib is new');
         end;
     if (pos('OVERALL BACKEND WARNINGS:',Uppercase(Rmsg))>0) then //+\dump_caps end
         Begin
          WaitHamlib:=False;
          if DebugMode then
               Writeln('End of +\dump_caps');
          SetSpeed(fSpeed);
         end;

     if DebugMode then
         Writeln('HLresp MSG:',Rmsg,':');
   end;
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

procedure TCWHamLib.WaitMorse;  //not used and not confirmed to exist via initialize rig/dump_caps
begin
  tcp.SendMessage('\wait_morse'+LineEnding);
  if DebugMode then
         Writeln('CW: \wait_morse');
end;

procedure TCWHamLib.SetSpeed(speed : Word);
var      tmp:String;
begin
  if Speed>fMaxSpeed then speed:= fMaxSpeed;
  if Speed<fMinSpeed then speed:= fMinSpeed;
  fSpeed := speed;
  tmp:= 'L'+VfoStr+' KEYSPD '+IntToStr(speed)+LineEnding;
  if fActive then
    tcp.SendMessage(tmp);
  if fDebugMode then
    Writeln('CW speed changed to:',fSpeed,'  ',tmp)
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
  AllowCW := false;
  if fIsNewHamlib then
   tcp.SendMessage('+\stop_morse'+LineEnding)
  //implemented in hamlib command set from 2023 (at least)
  else
   Begin
  //sending 0xFF as text works with Icom
    tcp.SendMessage('b'+#$0FF+LineEnding);
  //All chrs are spaces stops cw for kenwood. Empty chrs (max24) in buffer are filled with spaces.
  // (info by ts480 manual, not tested)
    tcp.SendMessage('b  '+LineEnding);
   end;
end;

procedure TCWHamLib.SendText(text : String);
const
     _REPEATS = 300; //times
     _TIMEOUT = 20; //x10-milliseconds
var
  c, i,
  tout,
  rpt : integer;
  Wcw : char;
  dSpd: integer;


            //-----------------------------------------------------------------------------------
            Procedure SendToHamlib(t:string);
            Begin
                        tout :=_TIMEOUT; //used away in sleep(10) blocks
                        rpt := _REPEATS;

                        while ((rpt > 0) and AllowCW) do
                          Begin
                            if fIsNewHamlib then
                                               t:=' '+t;
                            if fDebugMode then
                               Writeln('HLsend MSG: |','b'+t+'|');
                             Rmsg:='';
                             tcp.SendMessage('b'+t+LineEnding);
                             dec(rpt);
                              repeat
                                begin
                                  sleep(10);
                                  if fDebugMode then
                                    Writeln('Waiting RPRT');
                                  Application.ProcessMessages;
                                  dec(tout);
                                end;
                              until ((pos('RPRT',Rmsg)>0) or (tout < 1 ));
                              tout :=_TIMEOUT;
                               if fDebugMode then
                                  Begin
                                    Writeln('rcvd:',Rmsg);
                                    Writeln('     Ack timeout left: ',tout,'(/',_TIMEOUT,')x10 msec');
                                    Writeln('     Repeats left: ',rpt,'(/',_REPEATS,') times');
                                  end;
                              if pos('-9',Rmsg)>0 then
                                Begin
                                   if fDebugMode then
                                      Writeln('Waiting before repeat because of RPRT-9');
                                    dec(rpt);
                                    sleep(50);
                                end
                               else
                                rpt :=0;
                               if fDebugMode then
                                  Writeln('Ready for next');
                          end;

            end;
            //-----------------------------------------------------------------------------------
            Procedure ModSpeed(m:char);
            Begin
                if Wcw<>m then WaitMorse;
                //check if more m
                While ((text[i]=m) and (i<=length(text))) do
                  Begin
                    if m='+' then inc(dSpd) else dec(dSpd);
                    inc(i)
                  end;
                if (i<length(text)) then dec(i); //there is still text left
                SetSpeed(fSpeed+dSpd*5);
                if fDebugMode then  Writeln(m,' speed with ',dSpd*5);
                dSpd:=0;
            end;
            //-----------------------------------------------------------------------------------
begin
   if text<>'' then
     begin
       Wcw:=#0;
       dSpd:=0;
       AllowCW := true;
        //different rigs support different length of b-command. 10chr should be safe for all
        c:= length(text);
        if ((c>10) or (pos('+',text)>0) or (pos('-',text)>0))
         and (not fHamlibBuffer) then
         Begin
            i := 1;
            if fDebugMode then  Writeln('Ltr send: ');
            repeat
             Begin
               case text[i] of
                 '+','-'   : ModSpeed(text[i]);
                 else
                             Begin
                               if fDebugMode then  Writeln('send letter #',i,': ',text[i]);
                               SendToHamlib(text[i]);
                               Wcw:=#0;
                             end;
               end;
               inc(i);
             end;
            until (i > c) or (not AllowCW);
         end
        else
        Begin
         if fDebugMode then  Writeln('Word send: ');
         SendToHamlib(text);
        end;
      end
     else  if fDebugMode then  Writeln('Empty message!');
end;
procedure TCWHamLib.SendHex(text : String);
Begin
  //not implemented
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
