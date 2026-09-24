unit fGrayline;

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,LResources,Forms,Controls,Graphics,Dialogs,gline2,
  ExtCtrls,Buttons,FileUtil,Menus,ActnList,ComCtrls,
  lclType, LazFileUtils, DateUtils, Math,
  uRbnSpotParser, uRbnConnection, dSqlRef;

type
  TRBNList = record
    spotter  : String[20];
    band     : String[8];
    lat      : Double;
    long     : Double;
    strengt  : Integer;
    time     : TDateTime;
  end;

const
  //slots for spotters. It grows when needed; 300 was a fixed limit that a
  //contest evening can pass, and a full list threw the spot away
  INITIAL_ITEMS = 300;


type

  { TfrmGrayline }

  TfrmGrayline = class(TForm)
    acGrayLine : TActionList;
    acConnect : TAction;
    acShowStatusBar : TAction;
    acLinkToRbnMonitor: TAction;
    pumShowBeamPath: TMenuItem;
    pumShowLongPath: TMenuItem;
    pumShowShortPath: TMenuItem;
    pumMnuLine2: TMenuItem;
    pumClearAllSpots: TMenuItem;
    pumWatchFor: TMenuItem;
    pumRbnSource: TMenuItem;
    pumConnect : TMenuItem;
    pumMnuLine1 : TMenuItem;
    pumShowStatusbar : TMenuItem;
    pumLinkToRBNMonitor: TMenuItem;
    popGrayLine : TPopupMenu;
    sbGrayLine : TStatusBar;
    sbtnGrayLine : TSpeedButton;
    tmrAutoConnect : TTimer;
    tmrGrayLine: TTimer;
    tmrSpotDots: TTimer;
    procedure acConnectExecute(Sender : TObject);
    procedure acLinkToRbnMonitorExecute(Sender: TObject);
    procedure acShowStatusBarExecute(Sender : TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormPaint(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure popGrayLinePopup(Sender: TObject);
    procedure pumClearAllSpotsClick(Sender: TObject);
    procedure pumShowBeamPathClick(Sender: TObject);
    procedure pumShowLongPathClick(Sender: TObject);
    procedure pumShowShortPathClick(Sender: TObject);
    procedure pumWatchForClick(Sender: TObject);
    procedure pumRbnSourceItemClick(Sender: TObject);
    procedure pumRbnManageSourcesClick(Sender: TObject);
    procedure sbtnGrayLineClick(Sender : TObject);
    procedure tmrAutoConnectTimer(Sender : TObject);
    procedure tmrGrayLineTimer(Sender: TObject);
    procedure tmrSpotDotsTimer(Sender: TObject);
  private
    //shared mode listens to the main connection (the RBN control window's);
    //"Connect to RBN" makes a connection of its own to the preset chosen in
    //the popup ([RBN] GraylineSourceId), or to [RBN] Server/login when none is
    FOwnConn   : TRbnConnection;
    FListening : TRbnConnection;  //the one AddSpotToList is subscribed to, or nil
    FOwnName   : String;          //the preset FOwnConn was last connected to
    csRBN : TRTLCriticalSection;
    delAfter : integer;
    watchFor : String;
    LocalDbg : boolean;
    GC_lock  : boolean;

    procedure Listen(Conn : TRbnConnection);
    function  OwnSource(out Source : TRbnSource) : Boolean;
    procedure FillSourceMenu;
    procedure OnRbnSpot(const Line : String; const Spot : TRbnSpotLine);
    procedure OnRbnState(Sender : TObject);

    procedure SetRbnLink(Linked : Boolean);
    procedure CalculateBearing(lat0, long0, lat1, long1: extended; var bearing: extended);
  public
    RBNSpotList : array of TRBNList;  //1-based, index 0 unused
    band   : String;
    ob  : Pgrayline;
    s,d : String;
    pfx : String;
    rbn_status  : String;
    procedure kresli;
    procedure PlotGreatCircleArcLine(longitude1,latitude1,longitude2,latitude2:extended; LongP:integer);
    procedure CalculateLatLonOfNewPoint(BaseLon,BaseLat:extended;dist,bearing:integer;var lon2,lat2:extended);
    procedure SavePosition;
    procedure SynRBN;
    function  GetEmptyPos : Word;
    function  SpotterExists(spotter : String) : Word;
    procedure RemoveOldSpots(RemoveAfter:integer);
    procedure AddSpotToList(const Parsed : TRbnSpotLine);
    procedure LoadSettings();
  end;

var
  frmGrayline : TfrmGrayline;
implementation
{$R *.lfm}

{ TfrmGrayline }

uses dUtils, dData, uMyIni, dDXCluster, fNewQSO, fRotControl, fRbnSources;

//Subscribes to one connection at a time: the main one in shared mode, the own
//one otherwise. Every spot of it, before any filter of the monitor
procedure TfrmGrayline.Listen(Conn : TRbnConnection);
begin
  if FListening = Conn then
    exit;
  if Assigned(FListening) then
  begin
    FListening.UnsubscribeSpots(@OnRbnSpot);
    FListening.UnsubscribeState(@OnRbnState)
  end;
  FListening := Conn;
  if Assigned(FListening) then
  begin
    FListening.SubscribeSpots(@OnRbnSpot);
    FListening.SubscribeState(@OnRbnState)
  end;
  OnRbnState(nil)
end;

procedure TfrmGrayline.OnRbnSpot(const Line : String; const Spot : TRbnSpotLine);
begin
  if LocalDbg then Writeln('  RBN:',Line);
  AddSpotToList(Spot)
end;

procedure TfrmGrayline.OnRbnState(Sender : TObject);
begin
  if FListening = nil then
    rbn_status := 'Disconnected'
  else if FListening = FOwnConn then
    //the source is named: a server that filters its stream shows fewer dots
    rbn_status := FOwnName + ': ' + FOwnConn.Status
  else
    rbn_status := 'Linked to main RBN connection: ' + FListening.Status
end;

function TfrmGrayline.GetEmptyPos : Word;
var
  i : Integer;
begin
  Result := 0;
  for i:= 1 to High(RBNSpotList) do
  begin
    if RBNSpotList[i].band='' then
    begin
      Result := i;
      break
    end
  end;
  if Result = 0 then
  begin
    //full: grow by half. Old slots are freed by RemoveOldSpots anyway
    Result := Length(RBNSpotList);
    SetLength(RBNSpotList, Length(RBNSpotList) + Length(RBNSpotList) div 2)
  end
end;

function TfrmGrayline.SpotterExists(spotter : String) : Word;
var
  i : Integer;
begin
  Result := 0;
  for i:= 1 to High(RBNSpotList) do
  begin
    if RBNSpotList[i].spotter=spotter then
    begin
      Result := i;
      break
    end
  end
end;

procedure TfrmGrayline.acShowStatusBarExecute(Sender : TObject);
begin
  if acShowStatusBar.Checked then
  begin
    sbGrayLine.Visible      := False;
    acShowStatusBar.Checked := False
  end
  else begin
    sbGrayLine.Visible      := True;
    acShowStatusBar.Checked := True
  end
end;


{ The preset "Connect to RBN" uses: the one chosen in the popup, else the
  legacy [RBN] Server/login pair as a preset of its own. False when there is
  nothing to connect to (no login). }
function TfrmGrayline.OwnSource(out Source : TRbnSource) : Boolean;
var
  List : TRbnSourceList;
  i, Id : Integer;
  tmp  : String;
begin
  Source := Default(TRbnSource);
  Id := cqrini.ReadInteger('RBN','GraylineSourceId',0);
  if Id > 0 then
  begin
    List := dmSqlRef.LoadRbnSources;
    for i := 0 to High(List) do
      if List[i].Id = Id then
      begin
        Source := List[i];
        exit(Source.UserName <> '')
      end
  end;
  //no preset chosen (or a deleted one): what Preferences > RBN support says
  tmp := cqrini.ReadString('RBN','Server','telnet.reversebeacon.net:7000');
  Source.Description := 'Preferences > RBN support';
  Source.Address     := copy(tmp,1,Pos(':',tmp)-1);
  if not TryStrToInt(copy(tmp,Pos(':',tmp)+1,5),Source.Port) then
    Source.Port := 7000;
  Source.UserName := cqrini.ReadString('RBN','login','');
  Result := Source.UserName <> ''
end;

procedure TfrmGrayline.acConnectExecute(Sender : TObject);
var
  Src : TRbnSource;
begin
  if (FListening = FOwnConn) and (FOwnConn.State <> rcsDisconnected) then
  begin
    FOwnConn.Disconnect;
    exit
  end;
  if not OwnSource(Src) then
  begin
    Application.MessageBox('Login to RBN server is not set. Choose an RBN source in this menu or set Preferences -> RBN support','Information ...',mb_OK+mb_IconInformation);
    exit
  end;
  //a connection of its own; it may differ from the main source and it does
  //not touch it
  SetRbnLink(False);
  if LocalDbg then Writeln('Server:',Src.Address,' Port:',Src.Port);
  FOwnName := Src.Description;
  Listen(FOwnConn);
  FOwnConn.Connect(Src.Address, Src.Port, Src.UserName)
end;

{ the popup's "RBN source" submenu: every preset, the chosen one checked,
  and a way to the presets dialog. Rebuilt on every popup, the list is short }
procedure TfrmGrayline.FillSourceMenu;
var
  List : TRbnSourceList;
  i, Id : Integer;
  m : TMenuItem;
begin
  pumRbnSource.Clear;
  Id := cqrini.ReadInteger('RBN','GraylineSourceId',0);
  List := dmSqlRef.LoadRbnSources;
  for i := 0 to High(List) do
  begin
    m := TMenuItem.Create(pumRbnSource);
    m.Caption   := RbnSourceCaption(List[i]);
    m.Tag       := List[i].Id;
    m.RadioItem := True;
    m.Checked   := List[i].Id = Id;
    m.OnClick   := @pumRbnSourceItemClick;
    pumRbnSource.Add(m)
  end;
  m := TMenuItem.Create(pumRbnSource);
  m.Caption   := 'Preferences > RBN support (server and login there)';
  m.Tag       := 0;
  m.RadioItem := True;
  m.Checked   := Id = 0;
  m.OnClick   := @pumRbnSourceItemClick;
  pumRbnSource.Add(m);
  m := TMenuItem.Create(pumRbnSource);
  m.Caption := '-';
  pumRbnSource.Add(m);
  m := TMenuItem.Create(pumRbnSource);
  m.Caption := 'Edit RBN sources...';
  m.OnClick := @pumRbnManageSourcesClick;
  pumRbnSource.Add(m)
end;

procedure TfrmGrayline.pumRbnSourceItemClick(Sender: TObject);
begin
  //stored only; a running own connection keeps its server until the user
  //reconnects, the same as the RBN control window does with the main source
  cqrini.WriteInteger('RBN','GraylineSourceId',TMenuItem(Sender).Tag)
end;

procedure TfrmGrayline.pumRbnManageSourcesClick(Sender: TObject);
begin
  with TfrmRbnSources.Create(self) do
  try
    SelectedId := cqrini.ReadInteger('RBN','GraylineSourceId',0);
    ShowModal
  finally
    Free
  end
end;

procedure TfrmGrayline.acLinkToRbnMonitorExecute(Sender: TObject);
begin
    //only the user toggles and stores the link, see tmrAutoConnectTimer
    SetRbnLink(not acLinkToRbnMonitor.Checked);
    cqrini.WriteBool('RBN','AutoLink',acLinkToRbnMonitor.Checked)
end;

procedure TfrmGrayline.SetRbnLink(Linked : Boolean);
begin
    acLinkToRbnMonitor.Checked := Linked;
    pumConnect.Enabled:=not Linked;
    if Linked then
    begin
      //shared mode: the main connection, every spot before the monitor's filter,
      //whether or not the monitor window is open. The own connection is dropped
      if FOwnConn.State <> rcsDisconnected then
        FOwnConn.Disconnect;
      Listen(RbnMainConnection)
    end
    else
      Listen(nil)
end;

procedure TfrmGrayline.FormCreate(Sender: TObject);
var
  ImageFile : String;
  i : Integer;
begin
  InitCriticalSection(csRBN);
  FOwnConn := TRbnConnection.Create(self);
  SetLength(RBNSpotList, INITIAL_ITEMS + 1);
  tmrSpotDots.Enabled:=false;
  for i:=1 to High(RBNSpotList) do
   begin
    RBNSpotList[i].band    := '';
    RBNSpotList[i].spotter := '';
    RBNSpotList[i].time    := DateTimeToUnix(now);
    RBNSpotList[i].strengt := 0;
    RBNSpotList[i].lat  := 0;
    RBNSpotList[i].long := 0;
   end;
  GC_lock:=false;
  ImageFile := dmData.HomeDir+'images'+PathDelim+'grayline.bmp';
  if not FileExists(ImageFile) then
    ImageFile := ExpandFileNameUTF8('..'+PathDelim+'share'+PathDelim+'cqrlog'+
                 PathDelim+'images'+PathDelim+'grayline.bmp');
  ob:=new(Pgrayline,init(ImageFile));

  //set debug rules for this form
  // bit 5, %10000,  ---> -16 for routines in this form
  LocalDbg := dmData.DebugLevel >= 1 ;
  if dmData.DebugLevel < 0 then
      LocalDbg :=  LocalDbg or ((abs(dmData.DebugLevel) and 16) = 16 );

end;

procedure TfrmGrayline.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmGrayline);
  LoadSettings();
  acShowStatusBar.Checked   := sbGrayLine.Visible;
  rbn_status                :='Disconnected';
  sbGrayLine.SimpleText     := rbn_status;
  tmrGrayLine.Enabled       := True;
  tmrGrayLineTimer(nil);
  tmrAutoConnect.Enabled    := True;
  tmrSpotDots.Interval      :=1000;  //remove Spots(DOts) timer will always run 1 sec period.
  tmrSpotDots.Enabled       :=true;
  ob^.GC_line_clear;
end;

procedure TfrmGrayline.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  tmrGrayLine.Enabled := False;
  tmrAutoConnect.Enabled:=False;
  tmrSpotDots.Enabled:=False;
  //closing the window ends its own connection, as it always did; the shared
  //one is not the window's
  if FOwnConn.State <> rcsDisconnected then
    FOwnConn.Disconnect;
  Listen(nil);
  RemoveOldSpots(0);
end;

procedure TfrmGrayline.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  cqrini.WriteBool('Grayline','Statusbar',sbGrayLine.Visible);
  dmUtils.SaveWindowPos(frmGrayline)
end;

procedure TfrmGrayline.FormDestroy(Sender: TObject);
begin
  if LocalDbg then Writeln('Closing GrayLine window');
  Listen(nil);
  dispose(ob,done);
  DoneCriticalsection(csRBN)
end;

procedure TfrmGrayline.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if not (Shift = [ssCtrl,ssAlt]) then
    key := 0;
end;

procedure TfrmGrayline.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key= VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0
  end
end;

procedure TfrmGrayline.FormPaint(Sender: TObject);
var
  r:Trect;
begin
  r.left:=0;r.right:=width-1;
  r.top:=0;r.bottom:=width*obvy div obsi-1;
  if dmUtils.SysUTC then
    ob^.VypocitejSunClock(dmUtils.GetDateTime(0) - (dmUtils.GrayLineOffset/24))//-dmUtils.GetLocalUTCDelta)
  else
    ob^.VypocitejSunClock(now - (dmUtils.GrayLineOffset/24));
  ob^.kresli(r,Canvas)
end;


procedure TfrmGrayline.popGrayLinePopup(Sender: TObject);
begin
   watchFor := cqrini.ReadString('RBN','watch','');
   pumWatchFor.Caption:='Watch for: '+watchFor;
   FillSourceMenu
end;

procedure TfrmGrayline.pumClearAllSpotsClick(Sender: TObject);
begin
  tmrSpotDots.Enabled:=False;
  RemoveOldSpots(0);
  delAfter := cqrini.ReadInteger('RBN','deleteAfter',60);
  tmrSpotDots.Enabled:=true;
end;

procedure TfrmGrayline.pumShowBeamPathClick(Sender: TObject);
begin
  pumShowBeamPath.Checked:= not pumShowBeamPath.Checked;
  cqrini.WriteBool('Grayline','BeamPath',pumShowBeamPath.Checked);
  if  pumShowBeamPath.Checked then
                               frmRotControl.BeamDir:=-1
                              else
                               ob^.GC_line_clear(2);
end;

procedure TfrmGrayline.pumShowLongPathClick(Sender: TObject);
begin
  pumShowLongPath.Checked:= not pumShowLongPath.Checked;
  cqrini.WriteBool('Grayline','LongPath',pumShowLongPath.Checked);
end;

procedure TfrmGrayline.pumShowShortPathClick(Sender: TObject);
begin
  pumShowShortPath.Checked:= not pumShowShortPath.Checked;
  cqrini.WriteBool('Grayline','ShortPath',pumShowShortPath.Checked);
end;

procedure TfrmGrayline.pumWatchForClick(Sender: TObject);
var inpWF:string;
begin
   inpWF := cqrini.ReadString('RBN','watch','');
   if InputQuery('Watch for:','Enter up- or lowcase callsign or prefix and asterisk like OK2* ', false, inpWF) then
     Begin
          EnterCriticalsection(csRBN);
           watchFor:= uppercase(inpWF);
           pumWatchFor.Caption:='Watch for: '+watchFor;
           cqrini.WriteString('RBN','watch',watchFor);
          LeaveCriticalsection(csRBN);
          RemoveOldSpots(0);
     end;
end;

procedure TfrmGrayline.sbtnGrayLineClick(Sender : TObject);
var
  p : TPoint;
begin
  p.x := 10;
  p.y := 10;
  p := sbtnGrayLine.ClientToScreen(p);
  popGrayLine.PopUp(p.x, p.y)
end;

procedure TfrmGrayline.tmrAutoConnectTimer(Sender : TObject);
var
  Src : TRbnSource;
begin
    tmrAutoConnect.Enabled:=False; //runs once, FormShow starts it again
    if Assigned(FListening) then exit;
    //set, not toggled. The action keeps its Checked state while the window is
    //closed, so toggling here switched the link off on the second FormShow and
    //stored AutoLink=False. Also follows a change made in Preferences
    SetRbnLink(cqrini.ReadBool('RBN','AutoLink',false));
    if acLinkToRbnMonitor.Checked then
      exit;
    //the chosen preset carries its own user name, [RBN] login may be empty
    if cqrini.ReadBool('RBN','AutoConnect',False) and OwnSource(Src) then
      acConnect.Execute
end;

procedure TfrmGrayline.tmrGrayLineTimer(Sender: TObject);
begin
  Refresh
end;

procedure TfrmGrayline.tmrSpotDotsTimer(Sender: TObject);
begin
   tmrSpotDots.Enabled:=false;

   dec(delAfter);
   if delAfter < 1 then
     Begin
      delAfter := cqrini.ReadInteger('RBN','deleteAfter',60);
      RemoveOldSpots(delAfter);
     end;
    
  sbGrayLine.SimpleText := rbn_status;
  if (FListening = FOwnConn) and (FOwnConn.State <> rcsDisconnected) then
   Begin
    acConnect.Caption := 'Disconnect';
    pumLinkToRBNMonitor.Enabled:=false;
   end
  else
   Begin
     acConnect.Caption := 'Connect to RBN';
     pumLinkToRBNMonitor.Enabled:=True;
   end;

   SynRBN;

   tmrSpotDots.Enabled:=true;
end;

procedure TfrmGrayline.kresli;
var
  lat,long : Currency;
  lat1,long1 : Currency;
  my_loc : String;
begin
    my_loc := frmNewQSO.CurrentMyLoc;   //cqrini.ReadString('Station','LOC','JO70GG');
  if (s='') or (d='') then
    dmUtils.GetCoordinate(pfx,lat1,long1)
  else begin
    if s[Length(s)] = 'S' then  //if S is there, the data must be negative
      s := '-' +s ;
    s := copy(s,1,Length(s)-1);
    if pos('.',s) > 0 then
      s[pos('.',s)] := FormatSettings.DecimalSeparator;
    if not TryStrToCurr(s,lat1) then
      lat1 := 0;

    if d[Length(d)] = 'W' then  //  if there is a W it must be negative
      d := '-' + d ;
    d := copy(d,1,Length(d)-1);
    if pos('.',d) > 0 then
      d[pos('.',d)] := FormatSettings.DecimalSeparator;
    if not TryStrToCurr(d,long1) then
      long1 := 0
  end;
  s := '';
  d := '';
  dmUtils.CoordinateFromLocator(dmUtils.CompleteLoc(my_loc),lat,long);
  if pumShowShortPath.Checked or pumShowLongPath.Checked  then
    Begin
      if pumShowShortPath.Checked then
                                      PlotGreatCircleArcLine(long,lat,long1,lat1,0);
      if pumShowLongPath.Checked then
                                      PlotGreatCircleArcLine(long,lat,long1,lat1,1);
    end
   else
    ob^.jachcucaru(true,long,lat*-1,long1,lat1*-1);
  Refresh
end;

procedure TfrmGrayline.CalculateBearing(lat0, long0, lat1, long1: extended; var bearing: extended);
    var
     x, y: extended;
    begin
      // bearing
      y := Sin(long1 - long0) * Cos(lat1);
      x := Cos(lat0) * Sin(lat1) - Sin(lat0) * Cos(lat1) * Cos(long1 - long0);
      bearing := ArcTan2(y, x);
    end;

procedure TfrmGrayline.CalculateLatLonOfNewPoint(BaseLon,BaseLat:extended;dist,bearing:integer;var lon2,lat2:extended);
var R,B,
    lon1,
    lat1 :extended;
    distCount,
    stp,f:integer;

Begin

     R:=6378.15;     (* Radius of the earth *)
  if LocalDbg then
   begin
      write('Lat:',FormatFloat('0.00;;',BaseLat));
      write(' Lon:',FormatFloat('0.00;;',BaseLon));
      write('     ',FormatFloat('0.00;;',bearing),'      ');
   end;
stp:=10;
lon1 := degToRad(BaseLon);
lat1 := degToRad(BaseLat);
B    := degToRad(Bearing);
dist := dist+stp; //div results always at least 1
distcount:=dist div stp; //we need to calculate in small steps. Otherwise precision errors become too visible

for f:=1 to distcount do
  Begin
     lat2 := arcsin(sin(lat1) * cos(stp/R) + cos(lat1) * sin(stp/R) * cos(B));
     lon2 := lon1 +arctan2( sin(B) * sin(stp/R) * cos(lat1),
                                    cos(stp/R) - sin(lat1) * sin(lat2)
                                    );

     if (lat2>87*pi/180) then break;   //calculation fails on polar crossing with big beam lengths
     if (lat2<-87*pi/180) then break;

     lat1:=lat2;
     lon1:=lon2;
   if LocalDbg then
     begin
      write('Lat>',FormatFloat('0.00;;',RadToDeg(lat1)));
      writeln(' Lon>',FormatFloat('0.00;;',RadToDeg(lon1)));
     end;
  end;

  lat2:=RadToDeg(lat2);
  lon2:=RadToDeg(lon2);

  if LocalDbg then
   begin
      write('Lat:',FormatFloat('0.00;;',lat2));
      writeln(' Lon:',FormatFloat('0.00;;',lon2));
   end;
end;

procedure TfrmGrayline.PlotGreatCircleArcLine(longitude1,latitude1,longitude2,latitude2:extended; LongP:integer);
 { Ref: https://www.movable-type.co.uk/scripts/latlong.html }

Const
  MEC       = 170  *pi/180;       // Map image horizontal Edge Crossing "no print" limit in degrees (converted to radians)

var
  latFrom,lonFrom,
  BaseStep,step,                  // degree steps (converted to radians) for path line
  PolarStep,                      // steps in polar regions where distances/degrees are smaller
  bearing, oldbearing : extended;
  CountLimit,
  LP                  : integer;  //LongPath instead of ShortPath

Begin
while GC_lock do
      sleep(1);
GC_lock:=true;
BaseStep  := cqrini.ReadFloat('Program', 'GraylineGCstep',15E-001) * pi/180;
PolarStep := Basestep/cqrini.ReadInteger('Program', 'GraylineGCstep',10);
LoadSettings();

if LocalDbg then
      begin
        writeln ('-------------------------------------------------------------------');
        writeln ('Start:',round(latitude1),' ',round(longitude1),' ',round(latitude2),' ',round(longitude2));
      end;

step := BaseStep;

case LongP of
        2    :  LP:=0;     //beam
        1    :  LP:=1;     //long path
        0    :  LP:=0;     //short path
end;
ob^.GC_line_clear(LongP);
longitude1 := degToRad(longitude1);
latitude1 := degToRad(latitude1);
longitude2 := degToRad(longitude2);
latitude2 := degToRad(latitude2);

CalculateBearing(latitude1, longitude1, latitude2, longitude2, bearing);
bearing:=bearing+LP*pi;
oldbearing:=bearing;
CountLimit:=ob^.GC_Points_Max;

if LocalDbg then
         writeln ('Bearing:',round(radTodeg(bearing)));
while (CountLimit > 0) do
 Begin
  latFrom:=latitude1;
  lonFrom:=longitude1;
  dec(CountLimit);

  if abs(latFrom) > 1.45 then
     step:=PolarStep
    else
     step:=BaseStep;

 if LocalDbg then
         writeln (LineEnding,'FROM (',Round(RadToDeg(latFrom)),' ',Round(RadToDeg(lonFrom)),')','  To: ',Round(RadToDeg(latitude2)),' ',Round(RadToDeg(longitude2)));

  CalculateBearing(latFrom, lonFrom, latitude2, longitude2,bearing);
  bearing:=bearing+LP*pi; //makes LongPath if LP=1 counting plot points in "wrong direction"

  if abs(oldbearing -bearing) > (pi/2) then
         Begin
         if LocalDbg then
                           Begin
                             writeln('Obe:',round(radtodeg(oldbearing)));
                             writeln('Nbe:',round(radtodeg(bearing)));
                           end;
          if LP = 1 then
           begin
            if LocalDbg then
                             writeln ('Release LP value in count round ',CountLimit);
            LP:=0;  //we are on globe's opposite side of target. Release LP and now on calculate rest via ShortPath
            CalculateBearing(latFrom, lonFrom, latitude2, longitude2, bearing);
           end
          else
           begin
           if LocalDbg then
                              writeln ('Stop counting in round ',CountLimit);
            CountLimit:=0;
           end;
         end;
  if LocalDbg then
    writeln ('Bearing:',round(radTodeg(bearing)));

  longitude1 := longitude1 + (sin(bearing) * step) / cos(latitude1);
  latitude1 :=  latitude1 + (cos(bearing) * step);

  //swap on horizontal or veritcal edges
  if longitude1 < -Pi  then longitude1 :=  2*Pi+longitude1;
  if longitude1 >  Pi  then longitude1 := -2*Pi+longitude1;

  if latitude1 > Pi/2 then latitude1:= Pi/2 - (latitude1-Pi/2);
  if latitude1 < -Pi/2 then latitude1:= -Pi/2 - (latitude1+Pi/2);

  if LocalDbg then
    writeln ('From (',Round(RadToDeg(latFrom)),' ',Round(RadToDeg(lonFrom)),')','  To: ',Round(RadToDeg(latitude1)),' ',Round(RadToDeg(longitude1)));

  //map image horizontal edge crossing check. Allow plot if we are not in edge of image.
  if not (((lonFrom >  MEC) and (longitude1 < -MEC))  //right crossing
     or   ((lonFrom < -MEC) and (longitude1 >  MEC))  //left crossing
     ) then
      begin
       if LongP=0 then
         ob^.GC_line_part(RadToDeg(lonFrom),RadToDeg(latFrom)*-1,RadToDeg(longitude1),RadToDeg(latitude1)*-1);
       if LongP=1 then
         ob^.GC_Lline_part(RadToDeg(lonFrom),RadToDeg(latFrom)*-1,RadToDeg(longitude1),RadToDeg(latitude1)*-1);
       if (LongP=2) and (LP=0) then
         ob^.GC_Bline_part(RadToDeg(lonFrom),RadToDeg(latFrom)*-1,RadToDeg(longitude1),RadToDeg(latitude1)*-1);
      end;

  oldbearing:=bearing;
 end;
 GC_lock:=false;
end;

procedure TfrmGrayline.SavePosition;
begin
  cqrini.WriteInteger('Grayline','Height',Height);
  cqrini.WriteInteger('Grayline','Width',Width);
  cqrini.WriteInteger('Grayline','Top',Top);
  cqrini.WriteInteger('Grayline','Left',Left);
end;

procedure TfrmGrayline.SynRBN;
var
  i : Integer;
  c : TColor;
  CqrBand:String;

begin
  ob^.body_smaz;
  CqrBand := dmUtils.GetBandFromFreq(frmNewQSO.cmbFreq.Text);

  for i:=1 to High(RBNSpotList) do
  begin

   if (RBNSpotList[i].band='') then  //skip empty
      Continue;

    if (CqrBand = '') or (CqrBand<>RBNSpotList[i].band) then //skip if no cqrlog band or it differs from spot band
        Continue;

    if LocalDbg then
    begin
      writeln('Cqr:band:   ',cqrband);
      Writeln('Syn:spotter:',RBNSpotList[i].spotter);
      Writeln('Syn:stren:  ',RBNSpotList[i].strengt);
      Writeln('Syn:band:   ',RBNSpotList[i].band);
      Writeln('Syn:lat:    ',RBNSpotList[i].lat);
      Writeln('Syn:long:   ',RBNSpotList[i].long);
    end;
    case RBNSpotList[i].strengt of
      11..20  : c := cqrini.ReadInteger('RBN','20db',clPurple);
      21..30  : c := cqrini.ReadInteger('RBN','30db',clMaroon);
      31..100 : c := cqrini.ReadInteger('RBN','over30db',clRed)
      else
        c := cqrini.ReadInteger('RBN','10db',clWhite)
    end; //case
    ob^.body_add(3,RBNSpotList[i].long,RBNSpotList[i].lat*-1,RBNSpotList[i].long,RBNSpotList[i].lat*-1,RBNSpotList[i].spotter,c,1);
  end;
  Refresh
end;

procedure  TfrmGrayline.RemoveOldSpots(RemoveAfter:integer); //setting RemoveAfter:=0 removes all Spots
var
  i        : Integer;
  time     : int64;

begin
  time := DateTimeToUnix(now);
  EnterCriticalsection(csRBN);
  for i:=1 to High(RBNSpotList) do
   begin
     if ((time - RBNSpotList[i].time) > RemoveAfter) then
         RBNSpotList[i].band :='';
   end;
  SynRBN;
  LeaveCriticalsection(csRBN);

end;
procedure TfrmGrayline.AddSpotToList(const Parsed : TRbnSpotLine);

var
  spotter : String;
  call    : String;
  stren   : String;
  freq    : String;
  lat     : String;
  long    : String;
  index   : Word;
  tmp     : Integer;
  wCall   : String;
  latitude, longitude: Currency;
begin
  watchFor   := cqrini.ReadString('RBN','watch','');
  spotter := Parsed.Spotter;
  call    := Parsed.Dx;
  freq    := Parsed.FreqText;
  stren   := IntToStr(Parsed.SignalDb);

  if watchFor<>'' then
  begin
    if Pos('*',watchFor) > 0 then   //ZL*
    begin
      wCall := copy(watchFor,1,Pos('*',watchFor)-1);
      if (Pos(wCall,call) <> 1) then    //all callsign started with ZL
        exit
    end
    else begin
      if (call <> watchFor) then exit;
    end
  end;

  if LocalDbg then
  begin
    Writeln('Spotter:',spotter,'*');
    Writeln('Signal: ',stren,'*');
    Writeln('*Freq:  ',freq,'*')
  end;

  dmDXCluster.id_country(spotter,lat,long);

  index := SpotterExists(spotter);
  if index = 0 then //spotter doesn't exist, we need new position
    index := GetEmptyPos;

  band := dmDXCluster.GetBandFromFreq(freq,True);

  frmGrayline.RBNSpotList[index].band    := band;
  frmGrayline.RBNSpotList[index].spotter := spotter;
  frmGrayline.RBNSpotList[index].time    := DateTimeToUnix(now);
  if TryStrToInt(stren,tmp) then
    frmGrayline.RBNSpotList[index].strengt := tmp
  else
    frmGrayline.RBNSpotList[index].strengt := 0;

  //was a verbatim nested copy of TdmUtils.GetRealCoordinate
  dmUtils.GetRealCoordinate(lat,long,latitude, longitude);
  frmGrayline.RBNSpotList[index].lat  := latitude;
  frmGrayline.RBNSpotList[index].long := longitude;
  if  LocalDbg then
   begin
    Write('Add call:   ',call);
    Write('Add spotter:',spotter);
    Write('Add stren:  ',stren);
    Write('Add freq:   ',freq);
    Write('Add band:   ',band);
    Write('Add Lat:    ',lat);
    Write('Add Long:   ',long);
    //the copy that used to live here printed the parsed pair under LocalDbg
    Write(' -> Lat:    ',latitude);
    Writeln(' Long:   ',longitude)
   end;
end;

procedure TfrmGrayline.LoadSettings();
begin
  sbGrayLine.Visible        := cqrini.ReadBool('Grayline','Statusbar',True);
  pumShowShortPath.Checked  := cqrini.ReadBool('Grayline','ShortPath',False);
  pumShowLongPath.Checked   := cqrini.ReadBool('Grayline','LongPath',False);
  pumShowBeamPath.Checked   := cqrini.ReadBool('Grayline','BeamPath',False);
  delAfter                  := cqrini.ReadInteger('RBN','deleteAfter',60);

  ob^.GC_LWidth := cqrini.ReadInteger('Program', 'GraylineGCLineWidth',2);
  ob^.GB_LWidth := cqrini.ReadInteger('Program', 'GraylineGBeamLineWidth',2);
  ob^.GC_SP_Color:=StringToColor(cqrini.ReadString('Program', 'GraylineGCLineSPColor', 'clYellow' ));
  ob^.GC_LP_Color:=StringToColor(cqrini.ReadString('Program', 'GraylineGCLineLPColor', 'clFuchsia' ));
  ob^.GC_BE_Color:=StringToColor(cqrini.ReadString('Program', 'GraylineGCLineBEColor', 'clRed' ));
end;

end.

