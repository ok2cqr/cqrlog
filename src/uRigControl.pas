unit uRigControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, ExtCtrls, lNetComponents, lnet;

type TRigMode =  record
    mode : String[10];
    pass : word;
end;

type TVFO = (VFOA,VFOB);


type
  TExplodeArray = Array of String;

type TRigControl = class
    rcvdFreqMode : TLTCPComponent;
    rigProcess   : TProcess;
    tmrRigPoll   : TTimer;
  private
    fRigCtldPath : String;
    fRigCtldArgs : String;
    fRunRigCtld  : Boolean;
    fMode        : TRigMode;
    fFreq        : Double;
    fKeySpd      : Integer;
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

    function  RigConnected   : Boolean;
    function  StartRigctld   : Boolean;
    function  Explode(const cSeparator, vString: String): TExplodeArray;

    procedure OnReceivedRcvdFreqMode(aSocket: TLSocket);
    procedure OnRigPollTimer(Sender: TObject);
  public


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
    //poll rate in miliseconds
    property RigSendCWR  : Boolean read fRigSendCWR    write fRigSendCWR;
    //send CWR instead of CW
    property LastError   : String  read fLastError;
    //last error during operation


    function  GetCurrVFO  : TVFO;
    function  GetModePass : TRigMode;
    function  GetModeOnly : String;
    function  GetFreqHz   : Double;
    function  GetFreqKHz  : Double;
    function  GetFreqMHz  : Double;
    function  GetKeySpd   : Integer;
    function  GetModePass(vfo : TVFO) : TRigMode;  overload;
    function  GetModeOnly(vfo : TVFO) : String; overload;
    function  GetFreqHz(vfo : TVFO)   : Double; overload;
    function  GetFreqKHz(vfo : TVFO)  : Double; overload;
    function  GetFreqMHz(vfo : TVFO)  : Double; overload;

    procedure SetCurrVFO(vfo : TVFO);
    procedure SetModePass(mode : TRigMode);
    procedure SetFreqKHz(freq : Double);
    procedure SendMorse( morse : String );
    procedure SetWPM( wpm : Integer );
    procedure ClearRit;
    procedure Restart;
end;

implementation

constructor TRigControl.Create;
begin
  RigCommand := TStringList.Create;
  fDebugMode   := DebugMode;
  if DebugMode then Writeln('In create');
  fRigCtldHost := 'localhost';
  fRigCtldPort := 4532;
  fRigPoll     := 500;
  fRunRigCtld  := True;
  rcvdFreqMode := TLTCPComponent.Create(nil);
  rigProcess   := TProcess.Create(nil);
  tmrRigPoll   := TTimer.Create(nil);
  tmrRigPoll.Enabled := False;
  if DebugMode then Writeln('All objects created');
  tmrRigPoll.OnTimer     := @OnRigPollTimer;
  rcvdFreqMode.OnReceive := @OnReceivedRcvdFreqMode
end;

function TRigControl.StartRigctld : Boolean;
var
  cmd : String;
begin

  cmd := fRigCtldPath + ' ' +RigCtldArgs;
  {
  cmd := StringReplace(cmd,'%m',IntToStr(fRigId),[rfReplaceAll, rfIgnoreCase]);
  cmd := StringReplace(cmd,'%r',fRigDevice,[rfReplaceAll, rfIgnoreCase]);
  cmd := StringReplace(cmd,'%t',IntToStr(fRigCtldPort),[rfReplaceAll, rfIgnoreCase]);
  }
  if DebugMode then Writeln('Starting RigCtld ...');
  if fDebugMode then Writeln(cmd);
  rigProcess.CommandLine := cmd;

  try
    rigProcess.Execute;
    sleep(1000)
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
  tmrRigPoll.Interval := fRigPoll;
  tmrRigPoll.Enabled  := True;

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
    Writeln('RigId:      ',RigId);
    Writeln('')
  end;

  if fRunRigCtld then
  begin
    if not StartRigctld then
    begin
      if fDebugMode then Writeln('rigctld failed to start!');
      Result := False;
      exit
    end
  end;

  if fDebugMode then Writeln('rigctld started!');

  rcvdFreqMode.Host := fRigCtldHost;
  rcvdFreqMode.Port := fRigCtldPort;

  //rcvdFreqMode.Connect(fRigCtldHost,fRigCtldPort);
  if rcvdFreqMode.Connect(fRigCtldHost,fRigCtldPort) then
  begin
    if fDebugMode then Writeln('Connected to ',fRigCtldHost,':',fRigCtldPort);
    result := True;
    tmrRigPoll.Interval := fRigPoll;
    tmrRigPoll.Enabled  := True
  end
  else begin
    if fDebugMode then Writeln('NOT connected to ',fRigCtldHost,':',fRigCtldPort);
    fLastError := ERR_MSG;
    Result     := False
  end
end;

procedure TRigControl.SetCurrVFO(vfo : TVFO);
begin
  case vfo of
    VFOA : RigCommand.Add('V VFOA');//sendCommand.SendMessage('V VFOA'+LineEnding);
    VFOB : RigCommand.Add('V VFOB')//sendCommand.SendMessage('V VFOB'+LineEnding);
  end //case
end;

procedure TRigControl.SetModePass(mode : TRigMode);
begin
  if (mode.mode='CW') and fRigSendCWR then
    mode.mode := 'CWR';
  RigCommand.Add('M '+mode.mode+' '+IntToStr(mode.pass))
end;

procedure TRigControl.SetFreqKHz(freq : Double);
begin
  RigCommand.Add('F '+FloatToStr(freq*1000))
end;

procedure TRigControl.SendMorse(morse : String);
begin
  RigCommand.Add('b '+morse)
end;

procedure TRigControl.SetWPM( wpm : Integer );
begin
  RigCommand.Add('L KEYSPD '+IntToStr(wpm));
end;

procedure TRigControl.ClearRit;
begin
  RigCommand.Add('J 0')
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

function TRigControl.GetFreqHz   : Double;
begin
  result := fFreq
end;

function TRigControl.GetFreqKHz  : Double;
begin
  result := fFreq / 1000
end;

function TRigControl.GetFreqMHz  : Double;
begin
  result := fFreq / 1000000
end;

function TRigControl.GetKeySpd : Integer;
begin
  result := fKeySpd;
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

procedure TRigControl.OnReceivedRcvdFreqMode(aSocket: TLSocket);
var
  msg : String;
  a   : TExplodeArray;
  i   : Integer;
  f   : Double;
begin
  if aSocket.GetMessage(msg) > 0 then
  begin
    //Writeln('Whole MSG:|',msg,'|');
    msg := trim(msg);
    a := Explode(LineEnding,msg);
    for i:=0 to Length(a)-1 do
    begin
      //Writeln('a[i]:',a[i]);
      if a[i]='' then Continue;

      if TryStrToFloat(a[i],f) then
      begin
        if f>20000 then
          fFReq := f
        else
          begin
          if f<60 then
             fKeySpd := StrToInt(a[i])
          else
             fMode.pass := round(f)
          end;
        Continue
      end;

      //if (a[i][1] in ['A'..'Z']) and (a[i][1] <> 'V' ) then //receiving mode info
      //FT-920 returned VFO as MEM
      if (a[i][1] in ['A'..'Z']) and (a[i][1] <> 'V' ) and (a[i]<>'MEM') then//receiving mode info
      begin
        if Pos('RPRT',a[i]) = 0 then
        begin
          fMode.mode := a[i];
          if (fMode.mode = 'USB') or (fMode.mode = 'LSB') then
            fMode.mode := 'SSB';
          if fMode.mode = 'CWR' then
            fMode.mode := 'CW';
        end
      end;
      if (a[i][1] = 'V') then
      begin
        if Pos('VFOB',msg) > 0 then
          fVFO := VFOB
        else
          fVFO := VFOA
      end
    end;
    {

    if (Length(a)<4) then
    begin
      for i:=0 to Length(a)-1 do
        Writeln('a[',i,']:',a[i]);
      if (msg[1] = 'V') then
      begin
        if Pos('VFOB',msg) > 0 then
          fVFO := VFOB
        else
          fVFO := VFOA
      end;

      if (msg[1] in ['A'..'Z']) and (msg[1] <> 'V' ) then //receiving mode info
      begin
        if Pos('RPRT',msg) = 0 then
        begin
          tmp := copy(msg,1,Pos(LineEnding,msg)-1);
          fMode.mode := trim(tmp);
          if (fMode.mode = 'USB') or (fMode.mode = 'LSB') then
            fMode.mode := 'SSB';

          tmp := trim(copy(msg,Pos(LineEnding,msg)+1,5));
          if not TryStrToInt(tmp,wdt) then
          begin
            fMode.pass := 0;
            fLastError := 'Could not get mode width from radio';
            if fDebugMode then Writeln(fLastError,':',msg,'*')
          end
          else
            fMode.pass := wdt
        end
      end
      else begin
        if (msg[1] <> 'V' ) then
        begin
          tmp := trim(msg);
          if not TryStrToFloat(tmp,fFreq) then
          begin
            fFreq      := 0;
            fLastError := 'Could not get freq from radio';
            if fDebugMode then Writeln(fLastError,':',msg,'*')
          end
        end
      end
    end
    else begin
      if not TryStrToFloat(a[0],fFreq) then
      begin
        fFreq      := 0;
        fLastError := 'Could not get freq from radio';
        if fDebugMode then Writeln(fLastError,':',msg,'*',a[0],'*')
      end;

      if Pos('RPRT',a[1]) = 0 then
      begin
        fMode.mode := trim(a[1]);
        if (fMode.mode = 'USB') or (fMode.mode = 'LSB') then
          fMode.mode := 'SSB';
        if fMode.mode = 'CWR' then
          fMode.mode := 'CW';

        tmp := a[2];
        if not TryStrToInt(tmp,wdt) then
        begin
          fMode.pass := 0;
          fLastError := 'Could not get mode width from radio';
          if fDebugMode then Writeln(fLastError,':',msg,'*')
        end
        else
          fMode.pass := wdt
      end;
      if Pos('VFOB',a[3]) > 0 then
        fVFO := VFOB
      else
        fVFO := VFOA
    end;}
{    Writeln('-----');
    Writeln('VFO      :',fVFO);
    Writeln('FREQ     :',fFreq);
    Writeln('Mode     :',fMode.mode);
    Writeln('Bandwidth:',fMode.pass);
    Writeln('-----')}
  end
end;

procedure TRigControl.OnRigPollTimer(Sender: TObject);
var
  cmd : String;
  i   : Integer;
begin
  if (RigCommand.Text<>'') then
  begin
    for i:=0 to RigCommand.Count-1 do
    begin
      sleep(100);
      cmd := RigCommand.Strings[i]+LineEnding;
      rcvdFreqMode.SendMessage(cmd);
      if DebugMode then Writeln('Sending: '+cmd)
    end;
    RigCommand.Clear
  end
  else begin
    rcvdFreqMode.SendMessage('fmvl KEYSPD'+LineEnding)
  end
end;

procedure TRigControl.Restart;
var
  excode : Integer = 0;
begin
  rigProcess.Terminate(excode);
  tmrRigPoll.Enabled := False;
  rcvdFreqMode.Disconnect();
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


destructor TRigControl.Destroy;
var
  excode : Integer=0;
begin
  inherited;
  if DebugMode then Writeln(1);
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
  rcvdFreqMode.Disconnect();
  if DebugMode then Writeln(4);
  FreeAndNil(rcvdFreqMode);
  if DebugMode then Writeln(5);
  FreeAndNil(rigProcess);
  FreeAndNil(RigCommand);
  if DebugMode then Writeln(6)
end;


end.

