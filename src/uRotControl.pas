unit uRotControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, ExtCtrls, lNetComponents, lnet, strutils, graphics;

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
    procedure StopRot;
    procedure LeftRot;
    procedure RightRot;
    procedure SetAzimuth(azim : String);

    procedure Restart;
end;

var
   //most used defaults
   AzMax  :Double = 360;
   AzMin  :Double = 0;
   UseState,
   WarnFix: boolean;

implementation

uses fRotControl, uMyIni;

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
  if DebugMode then Writeln('rotProcess.Executable: ',rotProcess.Executable,LineEnding,'Parameters:',LineEnding,rotProcess.Parameters.Text);

  try
    rotProcess.Execute;
    sleep(1000)
  except
    on E : Exception do
    begin
      if fDebugMode then
        Writeln('Starting rotctld E: ',E.Message);
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
    end else
     if fDebugMode then Writeln('rotctld started!');
  end else
     if fDebugMode then Writeln('Not started rotctld process. (Run is set FALSE)');


  rcvdAzimut.Host := fRotCtldHost;
  rcvdAzimut.Port := fRotCtldPort;

  //rcvdAzimut.Connect(fRotCtldHost,fRotCtldPort);
  if rcvdAzimut.Connect(fRotCtldHost,fRotCtldPort) then
  begin
    if fDebugMode then Writeln('Connected to rotctld @ ',fRotCtldHost,':',fRotCtldPort);
    AzMin:=0;    //default limits
    AzMax:=360;
    UseState:=False;
    WarnFix:=False;
    result := True;
    tmrRotPoll.Interval := fRotPoll;
    tmrRotPoll.Enabled  := True;

    UseState := ( (cqrini.ReadBool('ROT1', 'RotAzMinMax', False) and (frmRotControl.rbRotor1.Checked)) or
                  (cqrini.ReadBool('ROT2', 'RotAzMinMax', False) and (frmRotControl.rbRotor2.Checked)) );

    if UseState then RotCommand.Add('+\dump_state'+LineEnding); //user defined limits
                       //RotCommand.Add('+\dump_caps'+LineEnding);  //factory values

  end
  else begin
    if fDebugMode then Writeln('NOT connected to rotctld @ ',fRotCtldHost,':',fRotCtldPort);
    fLastError := ERR_MSG;
    Result     := False
  end
end;

procedure TRotControl.SetAzimuth(azim : String);
var
  az,
  azz: double;

begin
  if fDebugMode then writeln('Requested Az:',azim);
  if TryStrToFloat(azim,az) then
   Begin
    azz := az;
    if az>360 then az:= az-360; // this should not happen by cqrlog

    //if follow \dump_state and rotor type is -180 .. 180
    //west results negative -180 .. 0   East is positive 0 .. 180
    if (UseState and (AzMin<0 ) and (az>180)) then az := az-360;

    if az<AzMin then az:=AzMin; //user limted minimum value by config parameters
    if az>AzMax then az:=AzMax; //user limted maximum value by config parameters

    WarnFix := azz<>az ;//P command is fixed, warn about it

    azim:=FloatToStr(az);
  end;
  if fDebugMode then writeln('Requested fixed Az:',azim,'  (AzMin:',FloatToStr(AzMin),' AzMax:',FloatToStr(AzMax),')');
  RotCommand.Add('P '+azim+' 0'+LineEnding )
end;

function TRotControl.GetAzimut   : Double;
begin
  result := fAzimut
end;
procedure TRotControl.StopRot ;
begin
  rcvdAzimut.SendMessage('S'+LineEnding);
end;
procedure TRotControl.LeftRot ;
begin
  rcvdAzimut.SendMessage('M 8 -1'+LineEnding);
end;
procedure TRotControl.RightRot ;
begin
  rcvdAzimut.SendMessage('M 16 -1'+LineEnding);
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

    if pos('RPRT-',msg)>0 then
        frmRotControl.pnlBtns.Color:=clRed
      else
        if WarnFix then
         begin
          frmRotControl.pnlBtns.Color:=clYellow;
          WarnFix := False;
          if fDebugMode then writeln(copy(msg,pos('RPRT',msg),7));
         end
        else
         begin
          frmRotControl.pnlBtns.Color:=clDefault;
          if fDebugMode then writeln(copy(msg,pos('RPRT',msg),7));
         end;

    frmRotControl.pnlBtns.Repaint;
    Resp := TStringList.create;
    Resp.Delimiter := LineEnding;
    Resp.DelimitedText:=msg;
    if Resp.IndexOf('get_pos=')>-1 then //position
       Begin
        if TryStrToFloat(Resp.Values['Azimuth'],Az) then fAzimut := Az;
        if fDebugMode then writeln('Az:',FloatToStr(fAzimut));
        frmRotControl.UpdateAZdisp(fAzimut,AzMin,AzMax,UseState);
        if (UseState and (AzMin<0 ) and (fAzimut<0)) then fAzimut:=fAzimut+360;  //south stop -180..0..180 type rotor zero deg at AzMin -180
        if fAzimut>360 then fAzimut:= fAzimut-360;   //some rotators turn over 360 deg and -180..0.180 calculations may result, too
        if fDebugMode then writeln('Fixed Az(',UseState,'):',FloatToStr(fAzimut),'  (AzMin:',FloatToStr(AzMin),' AzMax:',FloatToStr(AzMax),')');
       end;
    if Resp.IndexOf('dump_state=')>-1 then //user limits
       Begin
        if TryStrToFloat(Resp.Values['MinimumAzimuth'],Az) then AzMin := Az;
        if TryStrToFloat(Resp.Values['MaximumAzimuth'],Az) then AzMax := Az;
        if fDebugMode then writeln('AzMin:',FloatToStr(AzMin),LineEnding,'AzMax:',FloatToStr(AzMax));
        frmRotControl.UpdateAZdisp(0,AzMin,AzMax,True);
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
      if DebugMode then Writeln('RotProcess terminating');
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

{
Hamlib 4.0-git known rotator factory limits 2020-03.10

[saku@hamtpad rotators]$ grep -r 'max_az =' * > /tmp/hi ;grep -r 'min_az =' * >> /tmp/hi;sort < /tmp/hi
amsat/if100.c:    .max_az =           360,
amsat/if100.c:    .min_az =           0,
ars/ars.c:    .max_az =     360,
ars/ars.c:    .max_az =     360,
ars/ars.c:    .min_az =     0,
ars/ars.c:    .min_az =     0,
celestron/celestron.c:    .max_az =     360.0,
celestron/celestron.c:    .min_az =     0.0,
cnctrk/cnctrk.c:    .max_az =     360,
cnctrk/cnctrk.c:    .min_az =     0,
easycomm/easycomm.c:    .max_az =     360.0,
easycomm/easycomm.c:    .max_az =     360.0,
easycomm/easycomm.c:    .max_az =     360.0,
easycomm/easycomm.c:    .min_az =     0.0,
easycomm/easycomm.c:    .min_az =     0.0,
easycomm/easycomm.c:    .min_az =     0.0,
ether6/ether6.c:    .max_az =     360,
ether6/ether6.c:    .min_az =     0.,
ether6/ether6.c:    rs->max_az = max_az;
ether6/ether6.c:    rs->min_az = min_az;
fodtrack/fodtrack.c:    .max_az =     450,
fodtrack/fodtrack.c:    .min_az =     0,
gs232a/gs232a.c:    .max_az =     450.0,  /* vary according to rotator type */
gs232a/gs232a.c:    .max_az =     450.0,  /* vary according to rotator type */
gs232a/gs232a.c:    .max_az =     450.0,  /* vary according to rotator type */
gs232a/gs232a.c:    .min_az =     -180.0,
gs232a/gs232a.c:    .min_az =     -180.0,
gs232a/gs232a.c:    .min_az =     -180.0,
gs232a/gs232b.c:    .max_az = 450.0,    /* vary according to rotator type */
gs232a/gs232b.c:    .min_az = -180.0,
gs232a/gs232.c:    .max_az =     360.0,  /* vary according to rotator type */
gs232a/gs232.c:    .max_az =     450.0,  /* vary according to rotator type */
gs232a/gs232.c:    .max_az =     450.0,  /* vary according to rotator type */
gs232a/gs232.c:    .max_az =     450.0,  /* vary according to rotator type */
gs232a/gs232.c:    .min_az =     -180.0,
gs232a/gs232.c:    .min_az =     -180.0,
gs232a/gs232.c:    .min_az =     -180.0,
gs232a/gs232.c:    .min_az =     -180.0,
heathkit/hd1780.c:    .max_az =             180,
heathkit/hd1780.c:    .min_az =             -180,
ioptron/rot_ioptron.c:    .max_az =     360.0,
ioptron/rot_ioptron.c:    .min_az =     0.0,
m2/rc2800.c:    .max_az =     360.0,
m2/rc2800.c:    .min_az =     0.0,
meade/meade.c:    .max_az =    360.,
meade/meade.c:    .min_az =      0.,
prosistel/prosistel.c:    .max_az =     360.0,
prosistel/prosistel.c:    .min_az =     0.0,
rotorez/rotorez.c:    .max_az =       359.9,
rotorez/rotorez.c:    .max_az =           360,
rotorez/rotorez.c:    .max_az =           360,
rotorez/rotorez.c:    .max_az =           360,
rotorez/rotorez.c:    .max_az =           360,
rotorez/rotorez.c:    .min_az =           0,
rotorez/rotorez.c:    .min_az =           0,
rotorez/rotorez.c:    .min_az =           0,
rotorez/rotorez.c:    .min_az =           0,
rotorez/rotorez.c:    .min_az =       0,
sartek/sartek.c:    .max_az =             360,
sartek/sartek.c:    .min_az =             0,
spid/spid.c:    .max_az =            540.0,
spid/spid.c:    .max_az =            540.0,
spid/spid.c:    .max_az =            540.0,
spid/spid.c:    .min_az =            -180.0,
spid/spid.c:    .min_az =            -180.0,
spid/spid.c:    .min_az =            -180.0,
ts7400/ts7400.c:    .max_az =     180.,
ts7400/ts7400.c:    .min_az =     -180.,


v4.0-git has parameter "-o" that user can use to set offset for rotor. Setting this affects also to Azmin,
Azmax shown by \dump_state (Azmin & Azmax shown by \dump_caps shows always factory limits).
That means that rotor zero degrees have to be recalculated to know antenna true heading that cqrlog needs.
It would be easy if offset just be the only way to change AzMin AzMax of \dump_state.
But user can also set random values for AzMin AzMax of \dump_state with --set-conf parameter if he needs to
limit turning. This may cause that rotor full turn is not 360 degrees, and we can not trust anything for
calculating antenna true heading for cqrlog.

Quite impossible situation.

And there is third parameter "south_zero" that makes rotor "upside down" and it is not making this any easier either.

At the moment, if AzMin(\dump_state) is negative we have just assume that it is -180 (south end) to make
conversion to 0..360 true heading.
}
