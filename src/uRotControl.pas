unit uRotControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, ExtCtrls, lNetComponents, lnet;

{type TRigMode =  record
    mode : String[10];
    pass : word;
end;

type TVFO = (VFOA,VFOB);


type
  TExplodeArray = Array of String;
}
type TRotControl = class
    rcvdAzimut   : TLTCPComponent;
    rotProcess   : TProcess;
    tmrRotPoll   : TTimer;
  private
    fRotCtldPath : String;
    fRotCtldArgs : String;
    fRunRotCtld  : Boolean;
//    fMode        : TRigMode;
    fAzimut        : Double;
    fRotPoll     : Word;
    fRotCtldPort : Word;
    fLastError   : String;
    fRotId       : Word;
    fRotDevice   : String;
    fDebugMode   : Boolean;
    fRotCtldHost : String;
//    fVFO         : TVFO;
    RotCommand   : TStringList;

    function  RotConnected   : Boolean;
    function  StartRotctld   : Boolean;
//    function  Explode(const cSeparator, vString: String): TExplodeArray;

    procedure OnReceivedRcvdAzimut(aSocket: TLSocket);
    procedure OnRotPollTimer(Sender: TObject);
  public


    constructor Create;
    destructor  Destroy; override;

    property DebugMode   : Boolean read fDebugMode write fDebugMode;

    property RotCtldPath : String  read fRotCtldPath write fRotCtldPath;
    //path to rotctld binary
    property RotCtldArgs : String  read fRotCtldArgs write fRotCtldArgs;
    //rotctld command line arguments
    property RunRotCtld  : Boolean read fRunRotCtld  write fRunRotCtld;
    //run rigctld command before connection
    property RotId       : Word    read fRotId       write fRotId;
    //hamlib rot id
    property RotDevice   : String  read fRotDevice   write fRotDevice;
    //port where is rot connected
    property RotCtldPort : Word    read fRotCtldPort write fRotCtldPort;
    // port where rotctld is listening to connecions, default 4533
    property RotCtldHost : String  read fRotCtldHost write fRotCtldHost;
    //host where is rotctld running
    property Connected   : Boolean read RotConnected;
    //connect rigctld
    property RotPoll     : Word    read fRotPoll     write fRotPoll;
    //poll rate in miliseconds
//    property RigSendCWR  : Boolean read fRigSendCWR    write fRigSendCWR;
    //send CWR instead of CW
    property LastError   : String  read fLastError;
    //last error during operation

{
    function  GetCurrVFO  : TVFO;
    function  GetModePass : TRigMode;
    function  GetModeOnly : String;}
    function  GetAzimut   : Double;
{    function  GetFreqKHz  : Double;
    function  GetFreqMHz  : Double;
    function  GetModePass(vfo : TVFO) : TRigMode;  overload;
    function  GetModeOnly(vfo : TVFO) : String; overload;
    function  GetFreqHz(vfo : TVFO)   : Double; overload;
    function  GetFreqKHz(vfo : TVFO)  : Double; overload;
    function  GetFreqMHz(vfo : TVFO)  : Double; overload;}
    function  GetLine1(const cSeparator, inString: String) : String;

{    procedure SetCurrVFO(vfo : TVFO);
    procedure SetModePass(mode : TRigMode); }
    procedure SetAzimuth(azim : String);

//    procedure ClearRit;
    procedure Restart;
end;

implementation

constructor TRotControl.Create;
begin
  RotCommand := TStringList.Create;
  fDebugMode   := DebugMode;
  if DebugMode then Writeln('In create');
  fRotCtldHost := 'localhost';
  fRotCtldPort := 4533;
  fRotPoll     := 500;
  fRunRotCtld  := True;
  rcvdAzimut   := TLTCPComponent.Create(nil);
  rotProcess   := TProcess.Create(nil);
  tmrRotPoll   := TTimer.Create(nil);
  tmrRotPoll.Enabled := False;
  if DebugMode then Writeln('All objects created');
  tmrRotPoll.OnTimer   := @OnRotPollTimer;
  rcvdAzimut.OnReceive := @OnReceivedRcvdAzimut
end;

function TRotControl.StartRotctld : Boolean;
var
  cmd : String;
begin

  cmd := fRotCtldPath + ' ' +RotCtldArgs;
  {
  cmd := StringReplace(cmd,'%m',IntToStr(fRigId),[rfReplaceAll, rfIgnoreCase]);
  cmd := StringReplace(cmd,'%r',fRigDevice,[rfReplaceAll, rfIgnoreCase]);
  cmd := StringReplace(cmd,'%t',IntToStr(fRigCtldPort),[rfReplaceAll, rfIgnoreCase]);
  }
  if DebugMode then Writeln('Starting RotCtld ...');
  if fDebugMode then Writeln(cmd);
  rotProcess.CommandLine := cmd;

  try
    rotProcess.Execute;
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
  tmrRotPoll.Interval := fRotPoll;
  tmrRotPoll.Enabled  := True;

  Result := True
end;

function TRotControl.RotConnected  : Boolean;
const
  ERR_MSG = 'Could not connect to rigctld';
begin
  if fDebugMode then
  begin
    Writeln('');
    Writeln('Settings:');
    Writeln('-----------------------------------------------------');
    Writeln('RotCtldPath:',RotCtldPath);
    Writeln('RotCtldArgs:',RotCtldArgs);
    Writeln('RunRotCtld: ',RunRotCtld);
    Writeln('RotDevice:  ',RotDevice);
    Writeln('RotCtldPort:',RotCtldPort);
    Writeln('RotCtldHost:',RotCtldHost);
    Writeln('RotPoll:    ',RotPoll);
//    Writeln('RotSendCWR: ',RigSendCWR);
    Writeln('RotId:      ',RotId);
    Writeln('')
  end;

  if fRunRotCtld then
  begin
    if not StartRotctld then
    begin
      if fDebugMode then Writeln('rotctld failed to start!');
      Result := False;
      exit
    end
  end;

  if fDebugMode then Writeln('rotctld started!');

  rcvdAzimut.Host := fRotCtldHost;
  rcvdAzimut.Port := fRotCtldPort;

  //rcvdAzimut.Connect(fRotCtldHost,fRotCtldPort);
  if rcvdAzimut.Connect(fRotCtldHost,fRotCtldPort) then
  begin
    if fDebugMode then Writeln('Connected to ',fRotCtldHost,':',fRotCtldPort);
    result := True;
    tmrRotPoll.Interval := fRotPoll;
    tmrRotPoll.Enabled  := True
  end
  else begin
    if fDebugMode then Writeln('NOT connected to ',fRotCtldHost,':',fRotCtldPort);
    fLastError := ERR_MSG;
    Result     := False
  end
end;
{
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
}

procedure TRotControl.SetAzimuth(azim : String);
begin
//  RotCommand.Add('P '+FloatToStr(azim))
    RotCommand.Add('P '+azim+' 0'+LineEnding )
end;
{
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
}
function TRotControl.GetAzimut   : Double;
begin
  result := fAzimut
end;
{
function TRigControl.GetFreqKHz  : Double;
begin
  result := fFreq / 1000
end;

function TRigControl.GetFreqMHz  : Double;
begin
  result := fFreq / 1000000
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
}
procedure TRotControl.OnReceivedRcvdAzimut(aSocket: TLSocket);
var
  msg : String;
  tmp : String;
  Az   : Double;
begin
  if aSocket.GetMessage(msg) > 0 then
  begin
//    Writeln('Whole MSG:|',msg,'|');
    tmp:= GetLine1(LineEnding,msg);
//    Writeln('Line 1:|',tmp,'|');
    if TryStrToFloat(tmp,Az) then
        fAzimut := Az;

    {msg := trim(msg);
    a := Explode(LineEnding,msg);
    for i:=0 to Length(a)-1 do
    begin
      //Writeln('a[i]:',a[i]);
      if a[i]='' then Continue;

      if TryStrToFloat(a[i],f) then
      begin
        if f>20000 then
          fAzimut := f
        else
          fMode.pass := round(f);
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
    Writeln('-----')} }
  end
end;

procedure TRotControl.OnRotPollTimer(Sender: TObject);
var
  cmd : String;
  i   : Integer;
begin
  if (RotCommand.Text<>'') then
  begin
    for i:=0 to RotCommand.Count-1 do
    begin
      sleep(100);
      cmd := RotCommand.Strings[i]+LineEnding;
      rcvdAzimut.SendMessage(cmd);
      if DebugMode then Writeln('Sending: '+cmd)
    end;
    RotCommand.Clear
  end
  else begin
    rcvdAzimut.SendMessage('p'+LineEnding)
  end
end;

procedure TRotControl.Restart;
var
  excode : Integer = 0;
begin
  rotProcess.Terminate(excode);
  tmrRotPoll.Enabled := False;
  rcvdAzimut.Disconnect();
  RotConnected
end;
{
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
 }

function TRotControl.GetLine1(const cSeparator, inString: String) : String;
begin
  result := Copy(inString, 1, Pos(cSeparator, inString)-1);
end;


destructor TRotControl.Destroy;
var
  excode : Integer=0;
begin
  if DebugMode then Writeln(1);
  if fRunRotCtld then
  begin
    if rotProcess.Running then
    begin
      if DebugMode then Writeln('1a');
      rotProcess.Terminate(excode)
    end
  end;
  sleep(500);
  if DebugMode then Writeln(2);
  tmrRotPoll.Enabled := False;
  if DebugMode then Writeln(3);
  rcvdAzimut.Disconnect();
  if DebugMode then Writeln(4);
  FreeAndNil(rcvdAzimut);
  if DebugMode then Writeln(5);
  FreeAndNil(rotProcess);
  FreeAndNil(RotCommand);
  if DebugMode then Writeln(6)
end;

end.

