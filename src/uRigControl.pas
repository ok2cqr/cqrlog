unit uRigControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, ExtCtrls, lNetComponents, lnet,Forms;

type TRigMode =  record
    mode : String[10];
    pass : integer;   //this can not be word as rigctld uses "-1"="keep as is" IntToStr gives 65535 for word with -1
    raw  : String[10];
end;

type TVFO = (VFOA,VFOB);


type
  TExplodeArray = Array of String;

type TRigControl = class
    RigctldConnect : TLTCPComponent;
    rigProcess   : TProcess;
    tmrRigPoll   : TTimer;
  private
    fRigCtldPath : String;
    fRigCtldArgs : String;
    fRunRigCtld  : Boolean;
    fMode        : TRigMode;
    fFreq        : Double;
    fRigPoll     : Word;
    fRigCtldPort : Word;
    fLastError   : String;
    fRigId       : Word;
    fRigDevice   : String;
    fDebugMode   : Boolean;
    fRigCtldHost : String;
    fVFO         : TVFO;
    RigCommand   : TStringList;
    fRigSendCWR  : Boolean;
    fRigChkVfo : Boolean;
    fRXOffset    : Double;
    fTXOffset    : Double;
    fMorse       : boolean;
    fPower       : boolean;
    fGetVfo      : boolean;

    AllowCommand      : integer; //things to do before start polling

    function  RigConnected   : Boolean;
    function  StartRigctld   : Boolean;
    function  Explode(const cSeparator, vString: String): TExplodeArray;


    procedure OnReceivedRigctldConnect(aSocket: TLSocket);
    procedure OnConnectRigctldConnect(aSocket: TLSocket);
    procedure OnRigPollTimer(Sender: TObject);

public

    ParmVfoChkd : Boolean;
    ParmHasVfo  : integer;
    VfoStr      : String;

    constructor Create;
    destructor  Destroy; override;

    property DebugMode   : Boolean read fDebugMode write fDebugMode;

    property RigCtldPath : String  read fRigCtldPath write fRigCtldPath;
    //path to rigctld binary
    property RigCtldArgs : String  read fRigCtldArgs write fRigCtldArgs;
    //rigctld command line arguments
    property RunRigCtld  : Boolean read fRunRigCtld  write fRunRigCtld;
    //run rigctld command before connection
    property RigId       : Word    read fRigId       write fRigId;
    //hamlib rig id
    property RigDevice   : String  read fRigDevice   write fRigDevice;
    //port where is rig connected
    property RigCtldPort : Word    read fRigCtldPort write fRigCtldPort;
    // port where rigctld is listening to connecions, default 4532
    property RigCtldHost : String  read fRigCtldHost write fRigCtldHost;
    //host where is rigctld running
    property Connected   : Boolean read RigConnected;
    //connect rigctld
    property RigPoll     : Word    read fRigPoll     write fRigPoll;
    //poll rate in milliseconds
    property RigSendCWR  : Boolean read fRigSendCWR    write fRigSendCWR;
    //send CWR instead of CW
    property RigChkVfo  : Boolean read fRigChkVfo    write fRigChkVfo;
    //test if rigctld "--vfo" start parameter is used
    property Morse      : Boolean read fMorse;
    //can rig send CW
    property Power      : Boolean read fPower;
    //can rig switch power
    property CanGetVfo  : Boolean read fGetVfo;
    //can rig show vfo (many Icoms can not)
    property LastError   : String  read fLastError;
    //last error during operation

    //RX offset for transvertor in MHz
    property RXOffset : Double read fRXOffset write fRXOffset;

    //TX offset for transvertor in MHz
    property TXOffset : Double read fTXOffset write fTXOffset;

    function  GetCurrVFO  : TVFO;
    function  GetModePass : TRigMode;
    function  GetPassOnly : word;
    function  GetModeOnly : String;
    function  GetFreqHz   : Double;
    function  GetFreqKHz  : Double;
    function  GetFreqMHz  : Double;
    function  GetModePass(vfo : TVFO) : TRigMode;  overload;
    function  GetModeOnly(vfo : TVFO) : String; overload;
    function  GetFreqHz(vfo : TVFO)   : Double; overload;
    function  GetFreqKHz(vfo : TVFO)  : Double; overload;
    function  GetFreqMHz(vfo : TVFO)  : Double; overload;
    function  GetRawMode : String;

    procedure SetCurrVFO(vfo : TVFO);
    procedure SetModePass(mode : TRigMode);
    procedure SetFreqKHz(freq : Double);
    procedure SetSplit(up:integer);
    procedure DisableSplit;  //this is disable XIT
    procedure ClearXit;
    procedure ClearRit;
    procedure DisableRit;
    procedure Restart;
    procedure PwrOn;
    procedure PwrOff;
    procedure PwrStBy;
    procedure PttOn;
    procedure PttOff;
    procedure UsrCmd(cmd:String);
end;

implementation

constructor TRigControl.Create;
begin
  RigCommand := TStringList.Create;
  fDebugMode := False;
  if DebugMode then Writeln('In create');
  fRigCtldHost := 'localhost';
  fRigCtldPort := 4532;
  fRigPoll     := 500;
  fRunRigCtld  := True;
  RigctldConnect := TLTCPComponent.Create(nil);
  rigProcess   := TProcess.Create(nil);
  tmrRigPoll   := TTimer.Create(nil);
  tmrRigPoll.Enabled := False;
  VfoStr       := ''; //defaults to non-"--vfo" (legacy) mode
  if DebugMode then Writeln('All objects created');
  tmrRigPoll.OnTimer     := @OnRigPollTimer;
  RigctldConnect.OnReceive := @OnReceivedRigctldConnect;
  RigctldConnect.OnConnect := @OnConnectRigctldConnect;
end;

function TRigControl.StartRigctld : Boolean;
var
   index     : integer;
   paramList : TStringList;
begin

  if fDebugMode then Writeln('Starting RigCtld ...');

  rigProcess.Executable := fRigCtldPath;
  index:=0;
  paramList := TStringList.Create;
  paramList.Delimiter := ' ';
  paramList.DelimitedText := RigCtldArgs;
  rigProcess.Parameters.Clear;
  while index < paramList.Count do
  begin
    rigProcess.Parameters.Add(paramList[index]);
    inc(index);
  end;
  paramList.Free;
  if fDebugMode then Writeln('rigProcess.Executable: ',rigProcess.Executable,LineEnding,'Parameters:',LineEnding,rigProcess.Parameters.Text);

  try
    rigProcess.Execute;
    sleep(1500);
    if not rigProcess.Active then
    begin
      Result := False;
      exit
    end
  except
    on E : Exception do
    begin
      if fDebugMode then
        Writeln('Starting rigctld E: ',E.Message);
      fLastError := E.Message;
      Result     := False;
      exit
    end
  end;
  Result := True
end;

function TRigControl.RigConnected  : Boolean;
const
  ERR_MSG = 'Could not connect to rigctld';

begin
  if fDebugMode then
  begin
    Writeln('');
    Writeln('Settings:');
    Writeln('-----------------------------------------------------');
    Writeln('RigCtldPath:',RigCtldPath);
    Writeln('RigCtldArgs:',RigCtldArgs);
    Writeln('RunRigCtld: ',RunRigCtld);
    Writeln('RigDevice:  ',RigDevice);
    Writeln('RigCtldPort:',RigCtldPort);
    Writeln('RigCtldHost:',RigCtldHost);
    Writeln('RigPoll:    ',RigPoll);
    Writeln('RigSendCWR: ',RigSendCWR);
    Writeln('RigChkVfo   ',RigChkVfo);
    Writeln('RigId:      ',RigId);
    Writeln('')
  end;

  { Hamlib Dummy rig allowed helps testing and maybe some operations without CAT rig

  if (RigId = 1) then
  begin
    Result := False;
    exit
  end;
  }

  if fRunRigCtld then
   begin
    if not StartRigctld then
      begin
        if fDebugMode then Writeln('rigctld failed to start!');
        Result := False;
        exit
      end
     else
      if fDebugMode then Writeln('rigctld started!');
   end
  else
    if fDebugMode then Writeln('Not started rigctld process. (Run is set FALSE)');


  RigctldConnect.Host := fRigCtldHost;
  RigctldConnect.Port := fRigCtldPort;

  if RigctldConnect.Connect(fRigCtldHost,fRigCtldPort) then //this does not work as connection indicator, is always true!!
                                                            //even when it can not connect rigctld.
  begin
    if fDebugMode then Writeln('Waiting for rigctld @ ',fRigCtldHost,':',fRigCtldPort);
    result := True;
    AllowCommand:=-1;
    ParmHasVfo:=0;   //default: "--vfo" is not used as start parameter
    tmrRigPoll.Interval := fRigPoll;
    tmrRigPoll.Enabled  := True;
    RigCommand.Clear;
  end
  else begin
    if fDebugMode then Writeln('ERROR: *NOT* connected to rigctld @ ',fRigCtldHost,':',fRigCtldPort);
    fLastError := ERR_MSG;
    Result     := False
  end
end;

procedure TRigControl.SetCurrVFO(vfo : TVFO);
begin
  case vfo of
    VFOA : Begin
                RigCommand.Add('V VFOA');//sendCommand.SendMessage('V VFOA'+LineEnding);
           end;
    VFOB : Begin
                RigCommand.Add('V VFOB');//sendCommand.SendMessage('V VFOB'+LineEnding);
           end;
  end; //case
  AllowCommand:=1; //call queue
end;

procedure TRigControl.SetModePass(mode : TRigMode);
begin
  if (mode.mode='CW') and fRigSendCWR then
    mode.mode := 'CWR';
  RigCommand.Add('+M'+VfoStr+' '+mode.mode+' '+IntToStr(mode.pass));
  AllowCommand:=1; //call queue
end;

procedure TRigControl.SetFreqKHz(freq : Double);
begin
  RigCommand.Add('+F'+VfoStr+' '+FloatToStr(freq*1000-TXOffset*1000000));
  AllowCommand:=1; //call queue
end;
procedure TRigControl.ClearRit;
begin
  RigCommand.Add('+J'+VfoStr+' 0');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.DisableRit;
Begin
  RigCommand.Add('+U'+VfoStr+' RIT 0');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.SetSplit(up:integer);
Begin
  RigCommand.Add('+Z'+VfoStr+' '+IntToStr(up));
  RigCommand.Add('+U'+VfoStr+' XIT 1');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.ClearXit;
begin
  RigCommand.Add('+Z'+VfoStr+' 0');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.DisableSplit;
Begin
  RigCommand.Add('+U'+VfoStr+' XIT 0');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.PttOn;
begin
  RigCommand.Add('+T'+VfoStr+' 1');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.PttOff;
begin
  RigCommand.Add('+T'+VfoStr+' 0');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.PwrOn;
begin
  AllowCommand:=8; //high prority  passes -1 state
end;
procedure TRigControl.PwrOff;
begin
  RigCommand.Add('+\set_powerstat 0');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.PwrStBy;
begin
  RigCommand.Add('+\set_powerstat 2');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.UsrCmd(cmd:String);
begin
  RigCommand.Add(cmd);
  AllowCommand:=1; //call queue
end;
function TRigControl.GetCurrVFO  : TVFO;
begin
  result := fVFO
end;

function TRigControl.GetModePass : TRigMode;
begin
  result := fMode
end;

function TRigControl.GetModeOnly : String;
begin
  result := fMode.mode
end;
function TRigControl.GetPassOnly : word;
begin
  result := fMode.pass
end;

function TRigControl.GetFreqHz : Double;
begin
  result := fFreq + fRXOffset*1000000;
end;

function TRigControl.GetFreqKHz : Double;
begin
  result := (fFreq + fRXOffset*1000000) / 1000
end;

function TRigControl.GetFreqMHz : Double;
begin
  result := (fFreq + fRXOffset*1000000) / 1000000
end;

function TRigControl.GetModePass(vfo : TVFO) : TRigMode;
var
  old_vfo : TVFO;
begin
  if fVFO <> vfo then
  begin
    old_vfo := fVFO;
    SetCurrVFO(vfo);
    Sleep(fRigPoll*2);
    result := fMode;
    SetCurrVFO(old_vfo)
  end;
  result := fMode
end;

function TRigControl.GetModeOnly(vfo : TVFO) : String;
var
  old_vfo : TVFO;
begin
  if fVFO <> vfo then
  begin
    old_vfo := fVFO;
    SetCurrVFO(vfo);
    Sleep(fRigPoll*2);
    result := fMode.mode;
    SetCurrVFO(old_vfo)
  end;
  result := fMode.mode
end;

function TRigControl.GetFreqHz(vfo : TVFO)   : Double;
var
  old_vfo : TVFO;
begin
  if fVFO <> vfo then
  begin
    old_vfo := fVFO;
    SetCurrVFO(vfo);
    Sleep(fRigPoll*2);
    result := fFreq;
    SetCurrVFO(old_vfo)
  end;
  result := fFreq
end;

function TRigControl.GetFreqKHz(vfo : TVFO)  : Double;
var
  old_vfo : TVFO;
begin
  if fVFO <> vfo then
  begin
    old_vfo := fVFO;
    SetCurrVFO(vfo);
    Sleep(fRigPoll*2);
    result := fFreq/1000;
    SetCurrVFO(old_vfo)
  end;
  result := fFreq
end;

function TRigControl.GetFreqMHz(vfo : TVFO)  : Double;
var
  old_vfo : TVFO;
begin
  if fVFO <> vfo then
  begin
    old_vfo := fVFO;
    SetCurrVFO(vfo);
    Sleep(fRigPoll*2);
    result := fFreq/1000000;
    SetCurrVFO(old_vfo)
  end;
  result := fFreq
end;

procedure TRigControl.OnReceivedRigctldConnect(aSocket: TLSocket);
var
  msg : String;
  a,b : TExplodeArray;
  i   : Integer;
  f   : Double;
begin
  if aSocket.GetMessage(msg) > 0 then
  begin
    msg := StringReplace(upcase(trim(msg)),#$09,' ',[rfReplaceAll]); //note the char case upper for now on! Remove TABs

    if DebugMode then
         Writeln('Msg from rig:|',msg,'|'+LineEnding);

    a := Explode(LineEnding,msg);
    for i:=0 to Length(a)-1 do     //this handles received message line by line
    begin
      //Writeln('a[i]:',a[i]);
      if a[i]='' then Continue;

      //we send all commands with '+' prefix that makes receiving sort lot easier
      b:= Explode(' ', a[i]);

      if b[0]='FREQUENCY:' then
       Begin
         if TryStrToFloat(b[1],f) then
           Begin
             fFReq := f;
           end
          else
           fFReq := 0;
          AllowCommand:=1; //check pending commands
       end;

      if b[0]='MODE:' then
       Begin
         fMode.raw  := b[1];
         fMode.mode :=  fMode.raw;
         if (fMode.mode = 'USB') or (fMode.mode = 'LSB') then
           fMode.mode := 'SSB';
         if fMode.mode = 'CWR' then
           fMode.mode := 'CW';
         AllowCommand:=1;
        end;

      //FT-920 returned VFO as MEM
      //Some rigs report VFO as Main,MainA,MainB or Sub,SubA,SubB
      //Hamlib dummy has also "None" could it be in some real rigs too?
      if b[0]='VFO:' then
       Begin
         b:= Explode(' ', a[i]);
         case b[1] of
           'VFOA',
           'MAIN',
           'MAINA',
           'SUBA'    :fVFO := VFOA;

           'VFOB',
           'SUB',
           'MAINB',
           'SUBB'    :fVFO := VFOB;
          else
            fVFO := VFOA;
         end;
         AllowCommand:=1;
        end;


       if b[0]='CHKVFO:' then //Hamlib 4.3
        Begin
         ParmVfoChkd:=true;
         if b[1]='1' then
                        ParmHasVfo := 1;
         if DebugMode then Writeln('"--vfo" checked:',ParmHasVfo);
         if ParmHasVfo > 0 then VfoStr:=' currVFO';  //note set leading one space to string!
         AllowCommand:=9; //next dump caps
        end;

       if b[0]='CHKVFO' then //Hamlib 3.1
        Begin
         ParmVfoChkd:=true;
         if b[1]='1' then
                        ParmHasVfo := 2;
         if DebugMode then Writeln('"--vfo" checked:',ParmHasVfo);
         if ParmHasVfo > 0 then VfoStr:=' currVFO';  //note set leading one space to string!
         AllowCommand:=9; //next dump caps
        end;

      if pos('CAN SET POWER STAT:',a[i])>0 then
       Begin
         fPower:= b[4]='Y';
         if DebugMode then Writeln('Switch power: ',fPower);
       end;

      if pos('CAN GET VFO:',a[i])>0 then
       Begin
         fGetVfo:= b[3]='Y';
         if DebugMode then Writeln(LineEnding+'Get VFO: ',fGetVfo);
       end;

      if pos('CAN SEND MORSE:',a[i])>0 then
       Begin
         fMorse:= b[3]='Y';
         if DebugMode then Writeln('Send Morse: ',fMorse,LineEnding);
         if fPower then
            AllowCommand:=8 //issue power on
          else
            AllowCommand:=1 //check pending commands
       end;

       if pos('SET_POWERSTAT:',a[i])>0 then
       Begin
        if pos('1',a[i])>0 then //line may have 'STAT: 1' or 'STAT: CURRVFO 1'
          Begin
            if DebugMode then Writeln('Power on, start polling');
            AllowCommand:=93; //check pending commands via delay
          end
         else
          Begin
            if DebugMode then Writeln('Power off, stop polling');
            AllowCommand:=-1;
          end;
       end;
   end;
  end;


end;
procedure TRigControl.OnRigPollTimer(Sender: TObject);
var
  cmd : String;
  i   : Integer;
begin
 case AllowCommand of
     //delay up to 10 timer rounds with this selecting one of numbers
     99:  AllowCommand:=98;
     98:  AllowCommand:=97;
     97:  AllowCommand:=96;
     96:  AllowCommand:=95;
     95:  AllowCommand:=94;
     94:  AllowCommand:=93;
     93:  AllowCommand:=92;
     92:  AllowCommand:=91;
     91:  AllowCommand:=1;

     //high priority commands
     10:  Begin
               cmd:='+\chk_vfo'+LineEnding;
               if DebugMode then
                     Writeln('Sending: '+cmd);
               RigctldConnect.SendMessage(cmd);
               AllowCommand:=-1; //waiting for reply
          end;
      9:  Begin
               cmd:='+\dump_caps'+LineEnding;
                if DebugMode then
                     Writeln('Sending: '+cmd);
               RigctldConnect.SendMessage(cmd);
               AllowCommand:=-1; //waiting for reply
          end;
      8:  Begin
               cmd:= '+\set_powerstat 1'+LineEnding;
               if DebugMode then
                     Writeln('Sending: '+cmd);
               RigctldConnect.SendMessage(cmd);
               AllowCommand:=-1; //waiting for reply
          end;

      //lower priority commands queue handled here
      1:  Begin
            if (RigCommand.Text<>'') then
              begin
                 for i:=0 to RigCommand.Count-1 do
                   Begin
                     cmd := RigCommand.Strings[i]+LineEnding;
                     RigctldConnect.SendMessage(cmd);
                     if DebugMode then
                          Writeln('Queue Sending: [',i,'] '+cmd);
                   end
               end;
              RigCommand.Clear;
              AllowCommand:=0; //polling
          end;
       //polling has lowest prority, do if there is nothing else to do
       0:  begin
               if  ParmHasVfo=2 then
                 cmd := '+f'+VfoStr+' +m'+VfoStr+' +v'+VfoStr+LineEnding //chk this with rigctld v3.1
                else
                 cmd := '+f'+VfoStr+' +m'+VfoStr+' +v'+LineEnding;

               if DebugMode then
                   Writeln('Poll Sending: '+cmd);
               RigctldConnect.SendMessage(cmd);
               AllowCommand:=-1; //waiting for reply
             end;

          end;//case


end;
procedure TRigControl.OnConnectRigctldConnect(aSocket: TLSocket);
Begin
  if DebugMode then
                   Writeln('Connected to rigctld');
    if RigChkVfo then
      Begin
        AllowCommand:=10;  //start with chkvfo
        ParmVfoChkd:=false;
      end
     else
      Begin
        AllowCommand:=9;  //otherwise start with dump caps
        ParmVfoChkd:=false;
      end;
    RigCommand.Clear;
end;

procedure TRigControl.Restart;
var
  excode : Integer = 0;
begin
  rigProcess.Terminate(excode);
  tmrRigPoll.Enabled := False;
  RigctldConnect.Disconnect();
  RigConnected
end;

function TRigControl.Explode(const cSeparator, vString: String): TExplodeArray;
var
  i: Integer;
  S: String;
begin
  S := vString;
  SetLength(Result, 0);
  i := 0;
  while Pos(cSeparator, S) > 0 do begin
    SetLength(Result, Length(Result) +1);
    Result[i] := Copy(S, 1, Pos(cSeparator, S) -1);
    Inc(i);
    S := Copy(S, Pos(cSeparator, S) + Length(cSeparator), Length(S));
  end;
  SetLength(Result, Length(Result) +1);
  Result[i] := Copy(S, 1, Length(S))
end;

function TRigControl.GetRawMode : String;
begin
  Result := fMode.raw
end;

destructor TRigControl.Destroy;
var
  excode : Integer=0;
begin
  inherited;
  if DebugMode then Writeln('Destroy rigctld'+LineEnding+'1');
  if fRunRigCtld then
  begin
    if rigProcess.Running then
    begin
      if DebugMode then Writeln('1a');
      rigProcess.Terminate(excode)
    end
  end;
  if DebugMode then Writeln(2);
  tmrRigPoll.Enabled := False;
  if DebugMode then Writeln(3);
  RigctldConnect.Disconnect();
  if DebugMode then Writeln(4);
  FreeAndNil(RigctldConnect);
  if DebugMode then Writeln(5);
  FreeAndNil(rigProcess);
  FreeAndNil(RigCommand);
  if DebugMode then Writeln('6'+LineEnding+'Done!')
end;

end.

