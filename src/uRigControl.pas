unit uRigControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, ExtCtrls, lNetComponents, lnet, Forms, strutils;

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
    fPowerON	 : boolean;
    fGetVfo      : boolean;
    fCompoundPoll: Boolean;
    fVoice       : Boolean;
    fIsNewHamlib : Boolean;

    AllowCommand        : integer; //for command priority
    ErrorRigctldConnect : Boolean;
    ConnectionDone      : Boolean;
    PowerOffIssued      : Boolean;

    function  RigConnected   : Boolean;
    function  StartRigctld   : Boolean;
    function  Explode(const cSeparator, vString: String): TExplodeArray;


    procedure OnReceivedRigctldConnect(aSocket: TLSocket);
    procedure OnConnectRigctldConnect(aSocket: TLSocket);
    procedure OnErrorRigctldConnect(const msg: string; aSocket: TLSocket);
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
    property Voice      : Boolean read fVoice;
    //can rig launch voice memories
    property IsNewHamlib: Boolean read fIsNewHamlib;
    //Is Hamlib version date higer than 2023-06-01
    //not used internally, but can give info out
    property Power      : Boolean read fPower;
    //can rig switch power
    property PowerON      : Boolean write fPowerON;
    //may rig switch power on at start
    property CanGetVfo  : Boolean read fGetVfo;
    //can rig show vfo (many Icoms can not)
    property LastError   : String  read fLastError;
    //last error during operation

    //RX offset for transvertor in MHz
    property RXOffset : Double read fRXOffset write fRXOffset;

    //TX offset for transvertor in MHz
    property TXOffset : Double read fTXOffset write fTXOffset;
    //Char to use between compound commands. Default is space, can be also LineEnding that breaks compound
    property CompoundPoll : Boolean read fCompoundPoll  write  fCompoundPoll;

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
    procedure SendVoice(VMem:String);
    procedure StopVoice;
    procedure UsrCmd(cmd:String);
end;

implementation

constructor TRigControl.Create;
begin
  RigCommand := TStringList.Create;
  RigCommand.Sorted:=False;
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
  fPowerON     := true;  //we do this via rigctld startup parameter autopower_on
  fGetVfo      := true;   //defaut these true
  fMorse       := true;
  fVoice       := false;
  fIsNewHamlib := false;
  PowerOffIssued := false;
  fCompoundPoll:=True;
  if DebugMode then Writeln('All objects created');
  tmrRigPoll.OnTimer       := @OnRigPollTimer;
  RigctldConnect.OnReceive := @OnReceivedRigctldConnect;
  RigctldConnect.OnConnect := @OnConnectRigctldConnect;
  RigctldConnect.OnError   := @OnErrorRigctldConnect;
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
  if pos('AUTO_POWER',UpperCase(RigCtldArgs))=0 then
   if (RigId>10) then  //only true rigs can do auto_power_on
    begin
    if fPowerON then RigCtldArgs:= RigCtldArgs+' -C auto_power_on=1';
          //2023-08-02 auto_power on is not any more default "1" and it should stay so (by W9MDB)
          //so we need just set it "1" if user wants, otherwise no parameter added. This should help old Hamlibs
          //that claim auto_power is wrong parameter and refuse to start.
          //If there are Hamlibs that defaut to "1" user must set "Extra command line parameters" as
          //-C auto_power_on=0
      //else RigCtldArgs:= RigCtldArgs+' -C auto_power_on=0';
    end;
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
var
  RetryCount : integer;

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
  RetryCount          := 1;
  ErrorRigctldConnect := False;
  ConnectionDone      := False;

  if RigctldConnect.Connect(fRigCtldHost,fRigCtldPort) then//this does not work as connection indicator, is always true!!
   Begin
     repeat
     begin
        //if fDebugMode then
                      Writeln('Waiting for rigctld ',RetryCount,' @ ',fRigCtldHost,':',fRigCtldPort);
        if  ErrorRigctldConnect then
            Begin
              ErrorRigctldConnect := False;
              RigctldConnect.Connect(fRigCtldHost,fRigCtldPort);
            end;
        inc(RetryCount);
        sleep(1000);
        Application.ProcessMessages;
      end;
     until (ConnectionDone or (Retrycount > 10)) ;

   if ConnectionDone then
    result := True
   else
    begin
     if fDebugMode then Writeln('RETRY ERROR: *NOT* connected to rigctld @ ',fRigCtldHost,':',fRigCtldPort);
     fLastError := ERR_MSG;
     Result     := False
    end
  end
  else
   begin
    if fDebugMode then Writeln('SETTINGS ERROR: *NOT* connected to rigctld @ ',fRigCtldHost,':',fRigCtldPort);
    fLastError := ERR_MSG;
    Result     := False
   end
end;

procedure TRigControl.SetCurrVFO(vfo : TVFO);
begin
  case vfo of
    VFOA : Begin
                RigCommand.Add('+\set_vfo VFOA');//sendCommand.SendMessage('V VFOA'+LineEnding);
           end;
    VFOB : Begin
                RigCommand.Add('+\set_vfo VFOB');//sendCommand.SendMessage('V VFOB'+LineEnding);
           end;
  end; //case
  AllowCommand:=1; //call queue
end;

procedure TRigControl.SetModePass(mode : TRigMode);
begin
  if (mode.mode='CW') and fRigSendCWR then
    mode.mode := 'CWR';
  RigCommand.Add('+\set_mode'+VfoStr+' '+mode.mode+' '+IntToStr(mode.pass));
  AllowCommand:=1; //call queue
end;

procedure TRigControl.SetFreqKHz(freq : Double);
begin
  RigCommand.Add('+\set_freq'+VfoStr+' '+FloatToStr(freq*1000-TXOffset*1000000));
  AllowCommand:=1; //call queue
end;
procedure TRigControl.ClearRit;
begin
  RigCommand.Add('+\set_rig'+VfoStr+' 0');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.DisableRit;
Begin
  RigCommand.Add('+\set_func'+VfoStr+' RIT 0');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.SetSplit(up:integer);
Begin
  RigCommand.Add('+\set_xit'+VfoStr+' '+IntToStr(up));
  RigCommand.Add('+\set_func'+VfoStr+' XIT 1');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.ClearXit;
begin
  RigCommand.Add('+\set_xit'+VfoStr+' 0');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.DisableSplit;
Begin
  RigCommand.Add('+\set_func'+VfoStr+' XIT 0');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.PttOn;
begin
  RigCommand.Add('+\set_ptt'+VfoStr+' 1');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.PttOff;
begin
  RigCommand.Add('+\set_ptt'+VfoStr+' 0');
  AllowCommand:=1; //call queue
end;
procedure TRigControl.SendVoice(Vmem:String);
begin
  RigCommand.Add('+\send_voice_mem '+Vmem);
  AllowCommand:=1; //call queue
end;
procedure TRigControl.StopVoice;
begin
  RigCommand.Add('+\stop_voice_mem');
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
  PowerOffIssued:=true;
end;
procedure TRigControl.PwrStBy;
begin
  RigCommand.Add('+\set_powerstat 2');
  AllowCommand:=1; //call queue
  PowerOffIssued:=true;
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
  Hit : boolean;
begin
  msg:='';
  while ( aSocket.GetMessage(msg) > 0 ) do
  begin
    msg := StringReplace(upcase(trim(msg)),#$09,' ',[rfReplaceAll]); //note the char case upper for now on! Remove TABs

    if DebugMode then
         Writeln('Msg from rig:',StringReplace(msg,LineEnding,'|',[rfReplaceAll]));

    a := Explode(LineEnding,msg);
    for i:=0 to Length(a)-1 do     //this handles received message line by line
    begin
      Hit:=false;
      //Writeln('a[i]:',a[i]);
      if a[i]='' then Continue;

      //we send all commands with '+' prefix that makes receiving sort lot easier
      b:= Explode(' ', a[i]);

      if (b[0]='FREQUENCY:')then
       Begin
         if TryStrToFloat(b[1],f) then
           Begin
             fFReq := f;
           end
          else
           fFReq := 0;
          Hit:=true;
          AllowCommand:=1; //check pending commands
       end;

      if ( (b[0]='TX') and (b[1]='MODE:') ) then   //WFview false rigctld emulating says "TX MODE:"
        Begin
          b[0]:=b[1];
          b[1]:=b[2];
        end;

      if (b[0]='MODE:') then
       Begin
         fMode.raw  := b[1];
         fMode.mode :=  fMode.raw;
         if (fMode.mode = 'USB') or (fMode.mode = 'LSB') then
           fMode.mode := 'SSB';
         if fMode.mode = 'CWR' then
           fMode.mode := 'CW';
         Hit:=true;
         AllowCommand:=1;
        end;

      //FT-920 returned VFO as MEM
      //Some rigs report VFO as Main,MainA,MainB or Sub,SubA,SubB
      //Hamlib dummy has also "None" could it be in some real rigs too?
      if (b[0]='VFO:') then
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
         Hit:=true;
         AllowCommand:=1;
        end;


       if b[0]='CHKVFO:' then //Hamlib 4.3
        Begin
         ParmVfoChkd:=true;
         if b[1]='1' then
                        ParmHasVfo := 1;
         if DebugMode then Writeln('"--vfo" checked:',ParmHasVfo);
         if ParmHasVfo > 0 then VfoStr:=' currVFO';  //note set leading one space to string!
         Hit:=true;
         AllowCommand:=9; //next dump caps
        end;

       if b[0]='CHKVFO' then //Hamlib 3.1
        Begin
         ParmVfoChkd:=true;
         if b[1]='1' then
                        ParmHasVfo := 2;
         if DebugMode then Writeln('"--vfo" checked:',ParmHasVfo);
         if ParmHasVfo > 0 then VfoStr:=' currVFO';  //note set leading one space to string!
         Hit:=true;
         AllowCommand:=9; //next dump caps
        end;

      //these come from\dump_caps
       if pos('HAMLIB VERSION:',a[i])>0 then
             Begin                   //Old hamlib does not have this line, new has.
               fIsNewHamlib:= true; //this is enough now to now it exist. Later version number and date can be used if needed
             end;

       if pos('CAN SET POWER STAT:',a[i])>0 then
       Begin
         fPower:= b[4]='Y';
       end;

      if pos('CAN GET VFO:',a[i])>0 then
       Begin
         fGetVfo:= b[3]='Y';
       end;

      if pos('CAN SEND MORSE:',a[i])>0 then
       Begin
         fMorse:= b[3]='Y';
       end;

       if pos('CAN SEND VOICE:',a[i])>0 then
       Begin
         fVoice:= b[3]='Y';
         RigCommand.Clear;
         Hit:=true;
         if ((fRigId<10) and fPowerON and fPower) then
               AllowCommand:=8 // if rigctld is remote it can not make auto_power_on as startup paramater
                               // then we should send set_powerstat 1 if power up is asked and rig can do it
           else
               AllowCommand:=1; //check pending commands (should not be any)
         if DebugMode then
                   Begin
                      Writeln(LineEnding,'This is New Hamlib: ',fIsNewHamlib);
                      Writeln('Cqrlog can switch power: ',fPower);
                      Writeln('Cqrlog can get VFO: ',fGetVfo);
                      Writeln('Cqrlog can send Morse: ',fMorse);
                      Writeln('Cqrlog can launch voice memories: ',fVoice,LineEnding);
                   end;
         Break;  //break searching from \dump_caps reply
       end;
      //\dump_caps end

       if pos('SET_POWERSTAT:',a[i])>0 then
       Begin
         Hit:=true;
         if pos('1',a[i])>0 then //line may have 'STAT: 1' or 'STAT: CURRVFO 1'
          Begin
            if DebugMode then Writeln('Power on, start polling');
            AllowCommand:=92; //check pending commands via delay Assume rig needs time to start
            PowerOffIssued:=false;
          end
         else
          Begin
            if DebugMode then Writeln('Power off, stop polling (0)');
            AllowCommand:=-1;
          end;
       end;


       if (b[0]='RPRT') then
       Begin
         //if none of above hits what to expect we accept just report received to be the one
         if not Hit then AllowCommand:=1;
         if DebugMode then
         case b[1] of
                        '-1': Writeln('Invalid parameter');
                        '-2': Writeln('Invalid configuration (serial,..)');
                        '-3': Writeln('Memory shortage');
                        '-4': Writeln('Function not implemented, but will be');
                        '-5': Writeln('Communication timed out');
                        '-6': Writeln('IO error, including open failed');
                        '-7': Writeln('Internal Hamlib error, huh!');
                        '-8': Writeln('Protocol error');
                        '-9': Writeln('Command rejected by the rig');
                        '-10': Writeln('Command performed, but arg truncated');
                        '-11': Writeln('Function not available');
                        '-12': Writeln('VFO not targetable');
                        '-13': Writeln('Error talking on the bus');
                        '-14': Writeln('Collision on the bus');
                        '-15': Writeln('NULL RIG handle or any invalid pointer parameter in get arg');
                        '-16': Writeln('Invalid VFO');
                        '-17': Writeln('Argument out of domain of func');
                        '-18':Writeln('Function deprecated');
                        '-19':Writeln('Security error password not provided or crypto failure');
                        '-20':Writeln('Rig is not powered on');

           end;
       end;

   end;  //line by line loop
  end; //while msg

end;
procedure TRigControl.OnRigPollTimer(Sender: TObject);
var
  cmd     : String;
  i       : Integer;
//-----------------------------------------------------------
procedure DoRigPoll;
var
   f:integer;
   s:array[1..3] of string=('','','');

begin
 if PowerOffIssued then exit;
 if  ParmHasVfo=2 then
   begin
     if fGetVfo then
        begin
          s[1]:='+f'+VfoStr;
          s[2]:='+m'+VfoStr;
          s[3]:='+v'+VfoStr;
          //cmd := '+f'+VfoStr+' +m'+VfoStr+' +v'+VfoStr+LineEnding //chk this with rigctld v3.1
        end
      else
        begin
          s[1]:='+f'+VfoStr;
          s[2]:='+m'+VfoStr;
          //cmd := '+f'+VfoStr+' +m'+VfoStr+LineEnding //do not ask vfo if rig can't
        end

   end
  else
   begin
     if fGetVfo then
        begin
          s[1]:='+f'+VfoStr;
          s[2]:='+m'+VfoStr;
          s[3]:='+v';
          //cmd := '+f'+VfoStr+' +m'+VfoStr+' +v'+LineEnding
        end
      else
      begin
          s[1]:='+f'+VfoStr;
          s[2]:='+m'+VfoStr;
          //cmd := '+f'+VfoStr+' +m'+VfoStr+LineEnding //do not ask vfo if rig can't
        end
   end;


 if fCompoundPoll then
       Begin
        if DebugMode then
           Write(LineEnding+'Poll Sending:'+s[1]+' '+s[2]+' '+s[3]+LineEnding);
        RigctldConnect.SendMessage(s[1]+' '+s[2]+' '+s[3]+LineEnding);
       end
      else
        Begin
          for f:=1 to 3 do
            Begin
              if DebugMode and (s[f]<>'') then
                 Write(LineEnding+'Poll Sending:'+s[f]+LineEnding);
              if s[f]<>'' then
                          RigctldConnect.SendMessage(s[f]+LineEnding);
              sleep(2);
            end;
        end;
 AllowCommand:=-1; //waiting for reply
end;

//-----------------------------------------------------------
begin
 if DebugMode then
               Writeln('Polling - allowcommand:',AllowCommand);
 case AllowCommand of
     -1:  Exit;   //no sending allowed

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
                     Write(LineEnding+'Sending: '+cmd);
               RigctldConnect.SendMessage(cmd);
               AllowCommand:=-1; //waiting for reply
          end;
      9:  Begin
               cmd:='+\dump_caps'+LineEnding;
                if DebugMode then
                     Write(LineEnding+'Sending: '+cmd);
               RigctldConnect.SendMessage(cmd);
               AllowCommand:=-1; //waiting for reply
          end;
      8:  Begin
               cmd:= '+\set_powerstat 1'+LineEnding;
               if DebugMode then
                     Write(LineEnding+'Sending: '+cmd);
               RigctldConnect.SendMessage(cmd);
               AllowCommand:=-1; //waiting for reply
          end;

      //lower priority commands queue handled here
      1:  Begin
            if (RigCommand.Text<>'') then
              begin
                if DebugMode then
                     write('Queue in:'+LineEnding,RigCommand.Text);
                 cmd := Trim(RigCommand.Strings[0])+LineEnding;
                  if DebugMode then
                          Write(LineEnding+'Queue Sending[0]:',cmd);
                 for i:=0 to RigCommand.Count-2 do
                    RigCommand.Exchange(i,i+1);
                  RigCommand.Delete(RigCommand.Count-1);
                  if DebugMode then
                     write('Queue out:'+LineEnding,RigCommand.Text);
                  RigctldConnect.SendMessage(cmd);
                  AllowCommand:=-1; //wait answer
               end
              else
               DoRigPOll;
          end;

       //polling has lowest prority, do if there is nothing else to do
       0:  DoRigPoll;

 end;//case
end;
procedure TRigControl.OnConnectRigctldConnect(aSocket: TLSocket);
Begin
    if DebugMode then
                   Writeln('Connected to rigctld');
    ConnectionDone:=true;
    ParmHasVfo:=0;   //default: "--vfo" is not used as start parameter
    AllowCommand:=10;  //start with chk_vfo
    RigCommand.Clear;
    tmrRigPoll.Interval := fRigPoll;
    tmrRigPoll.Enabled  := True;


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

end;
procedure TRigControl.OnErrorRigctldConnect(const msg: string; aSocket: TLSocket);

begin
  ErrorRigctldConnect:= True;
  if DebugMode then
                   writeln(msg);
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

