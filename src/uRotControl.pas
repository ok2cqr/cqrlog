unit uRotControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, ExtCtrls, lNetComponents, lnet, strutils;

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
    //poll rate in milliseconds
    property LastError   : String  read fLastError;
    //last error during operation

    function  GetAzimut   : Double;

    procedure SetAzimuth(azim : String);

    procedure Restart;
end;

var
   AzMax,
   AzMin      :Double;

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
   index     : integer;
   paramList : TStringList;
begin
  if DebugMode then Writeln('Starting RotCtld ...');

  rotProcess.Executable := fRotCtldPath;
  index:=0;
  paramList := TStringList.Create;
  paramList.Delimiter := ' ';
  paramList.DelimitedText := RotCtldArgs;
  rotProcess.Parameters.Clear;
  while index < paramList.Count do
  begin
    rotProcess.Parameters.Add(paramList[index]);
    inc(index);
  end;
  paramList.Free;
  if DebugMode then Writeln('rotProcess.Executable: ',rotProcess.Executable,' Parameters: ',rotProcess.Parameters.Text);

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
    tmrRotPoll.Enabled  := True;
    RotCommand.Add('+\dump_state'+LineEnding)
  end
  else begin
    if fDebugMode then Writeln('NOT connected to ',fRotCtldHost,':',fRotCtldPort);
    fLastError := ERR_MSG;
    Result     := False
  end
end;

procedure TRotControl.SetAzimuth(azim : String);
var
  az: double;
begin
  if fDebugMode then writeln('Requested Az:',azim);
  if TryStrToFloat(azim,az) then
   Begin
    if az>360 then az:= az-360; // this should not happen by cqrlog
    if AzMin<0 then az:=az + AzMin; //this sets cqrlog 0deg to rotator's Min deg
    if AzMin>0 then if az<AzMin then az:=AzMin; //When Min is set over 0deg do not try drive under it
    if az>AzMax then az:=AzMax; //if direction is more than Max do not try to turn over limit;
    azim:=FloatToStr(az);
  end;
  if fDebugMode then writeln('Requested fixed Az:',azim);
  RotCommand.Add('P '+azim+' 0'+LineEnding )
end;

function TRotControl.GetAzimut   : Double;
begin
  result := fAzimut
end;

procedure TRotControl.OnReceivedRcvdAzimut(aSocket: TLSocket);
var
  msg  : String;
  tmp  : String;
  Resp : TStringList=nil;
  Az   : Double;
begin
  if aSocket.GetMessage(msg) > 0 then
  begin
    msg:=StringReplace(msg,#09,#32,[rfReplaceAll]); //convert TAB to SPACE
    msg:=StringReplace(DelSpace(msg),':','=',[rfReplaceAll]); //remove SPACES, convert : to =
    Resp := TStringList.create;
    Resp.Delimiter := LineEnding;
    Resp.DelimitedText:=msg;
    if Resp.IndexOf('get_pos=')>-1 then //position
       Begin
        if TryStrToFloat(Resp.Values['Azimuth'],Az) then fAzimut := Az;
        if fDebugMode then writeln('Az:',fAzimut);
        if AzMin<0 then fAzimut := fAzimut - AzMin; //case when rotator 0 (AzMin) is negative degrees
        if fDebugMode then writeln('Fixed Az:',fAzimut);
       end;
    if Resp.IndexOf('dump_state=')>-1 then //properties
       Begin
        if TryStrToFloat(Resp.Values['MinimumAzimuth'],Az) then AzMin := Az;
        if TryStrToFloat(Resp.Values['MaximumAzimuth'],Az) then AzMax := Az;
        if fDebugMode then writeln('AzMin:',AzMin,LineEnding,'AzMax:',AzMax);
       end;
  end;
    FreeAndNil(Resp);
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
    rcvdAzimut.SendMessage('+p'+LineEnding)
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

