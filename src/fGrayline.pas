unit fGrayline;

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,LResources,Forms,Controls,Graphics,Dialogs,gline2,
  ExtCtrls,Buttons,inifiles,FileUtil,Menus,ActnList,ComCtrls,lNetComponents,
  lnet, lclType, LazFileUtils, StrUtils, DateUtils, Math;

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
  MAX_ITEMS = 300;


type

  { TfrmGrayline }

  TfrmGrayline = class(TForm)
    acGrayLine : TActionList;
    acConnect : TAction;
    acShowStatusBar : TAction;
    acLinkToRbnMonitor: TAction;
    pumShowLongPath: TMenuItem;
    pumShowShortPath: TMenuItem;
    pumMnuLine2: TMenuItem;
    pumClearAllSpots: TMenuItem;
    pumWatchFor: TMenuItem;
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
    procedure pumShowLongPathClick(Sender: TObject);
    procedure pumShowShortPathClick(Sender: TObject);
    procedure pumWatchForClick(Sender: TObject);
    procedure sbtnGrayLineClick(Sender : TObject);
    procedure tmrAutoConnectTimer(Sender : TObject);
    procedure tmrGrayLineTimer(Sender: TObject);
    procedure tmrSpotDotsTimer(Sender: TObject);
  private
    lTelnet    : TLTelnetClientComponent;
    csRBN : TRTLCriticalSection;
    login      : String;
    delAfter : integer;
    watchFor : String;
    LocalDbg : boolean;

    procedure lConnect(aSocket: TLSocket);
    procedure lDisconnect(aSocket: TLSocket);
    procedure lReceive(aSocket: TLSocket);

    function  ConnectToRBN : Boolean;
    procedure CalculateBearing(lat0, long0, lat1, long1: extended; var bearing: extended);
  public
    RBNSpotList : array[1..MAX_ITEMS] of TRBNList;
    band   : String;
    ob  : Pgrayline;
    s,d : String;
    pfx : String;
    rbn_status  : String;
    procedure kresli;
    procedure PlotGreatCircleArcLine(longitude1,latitude1,longitude2,latitude2:extended; LongP:boolean);
    procedure SavePosition;
    procedure SynRBN;
    function  GetEmptyPos : Word;
    function  SpotterExists(spotter : String) : Word;
    procedure RemoveOldSpots(RemoveAfter:integer);
    procedure AddSpotToList(spot : String);
  end;

var
  frmGrayline : TfrmGrayline;
implementation
{$R *.lfm}

{ TfrmGrayline }

uses dUtils, dData, uMyIni, dDXCluster, fNewQSO;

procedure TfrmGrayline.lConnect(aSocket: TLSocket);
begin
  rbn_status := 'Connected';
end;

procedure TfrmGrayline.lDisconnect(aSocket: TLSocket);
begin
  rbn_status := 'Disconnected';
end;

procedure TfrmGrayline.lReceive(aSocket: TLSocket);
const
  CR = #13;
  LF = #10;
var
  sStart, sStop: Integer;
  tmp : String;
  itmp : Integer;
  buffer : String;
  f : Double;
begin
  if lTelnet.GetMessage(buffer) = 0 then
    exit;
  sStart := 1;
  sStop := Pos(CR, Buffer);
  if sStop = 0 then
    sStop := Length(Buffer) + 1;
  while sStart <= Length(Buffer) do
  begin
    tmp  := Copy(Buffer, sStart, sStop - sStart);
    tmp  := trim(tmp);
    if LocalDbg then Writeln('Rcvd:',tmp);
    itmp := Pos('DX DE',UpperCase(tmp));
    if (itmp > 0) or TryStrToFloat(copy(tmp,1,Pos(' ',tmp)-1),f)  then
    begin
     if LocalDbg then Writeln('  RBN:',tmp);
      AddSpotToList(tmp);
    end
    else begin
      if (Pos('LOGIN',UpperCase(tmp)) > 0) and (cqrini.ReadString('RBN','login','') <> '') then
        lTelnet.SendMessage(cqrini.ReadString('RBN','login','')+#13+#10);
      if (Pos('please enter your call',LowerCase(tmp)) > 0) and (cqrini.ReadString('RBN','login','') <> '') then
        lTelnet.SendMessage(cqrini.ReadString('RBN','login','')+#13+#10);
      if LocalDbg then Writeln('RBN:',tmp)
    end;
    sStart := sStop + 1;
    if sStart > Length(Buffer) then
      Break;
    if Buffer[sStart] = LF then
      sStart := sStart + 1;
    sStop := sStart;
    while (Buffer[sStop] <> CR) and (sStop <= Length(Buffer)) do
      sStop := sStop + 1
  end;
  lTelnet.CallAction
end;

function TfrmGrayline.GetEmptyPos : Word;
var
  i : Integer;
begin
  Result := 0;
  for i:= 1 to MAX_ITEMS do
  begin
    if RBNSpotList[i].band='' then
    begin
      Result := i;
      break
    end
  end
end;

function TfrmGrayline.SpotterExists(spotter : String) : Word;
var
  i : Integer;
begin
  Result := 0;
  for i:= 1 to MAX_ITEMS do
  begin
    if RBNSpotList[i].spotter=spotter then
    begin
      Result := i;
      break
    end
  end
end;

function TfrmGrayline.ConnectToRBN : Boolean;
var
  server : String;
  port   : Integer;
  tmp    : String;
begin
  Result := True;
  lTelnet := TLTelnetClientComponent.Create(nil);
  try
    tmp    := cqrini.ReadString('RBN','Server','telnet.reversebeacon.net:7000');
    server := copy(tmp,1,Pos(':',tmp)-1);
    tmp    := copy(tmp,Pos(':',tmp)+1,5);
    if not TryStrToInt(tmp,port) then
      port := 7000; //default value

    if LocalDbg then Writeln('Server:',server,' Port:',port);

    lTelnet.OnConnect    := @lConnect;
    lTelnet.OnDisconnect := @lDisconnect;
    lTelnet.OnReceive    := @lReceive;
    lTelnet.Host := server;
    lTelnet.Port := port;
    lTelnet.Connect;
    lTelnet.CallAction
  except
    on E : Exception do
    begin
      Result := False;
      if LocalDbg then Writeln('Can not connect to RBN! ',E.Message)
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


procedure TfrmGrayline.acConnectExecute(Sender : TObject);
begin
  if (cqrini.ReadString('RBN','login','')='') then
    Application.MessageBox('Login to RBN server is not set. Go to Preferences -> RBN support and do the basic settings','Information ...',mb_OK+mb_IconInformation)
  else begin
    if acConnect.Caption = 'Disconnect' then
    begin
      if ltelnet <> nil then
       Begin
         lTelnet.Disconnect;
         sleep(100);
         FreeAndNil(lTelnet);
         rbn_status := 'Disconnected';
       end;
    end
    else begin
      acLinkToRbnMonitor.Checked :=false;
      ConnectToRBN;
    end
  end
end;

procedure TfrmGrayline.acLinkToRbnMonitorExecute(Sender: TObject);
begin
    acLinkToRbnMonitor.Checked := not acLinkToRbnMonitor.Checked;
    cqrini.WriteBool('RBN','AutoLink',acLinkToRbnMonitor.Checked);
    pumConnect.Enabled:=not acLinkToRbnMonitor.Checked;
    if acLinkToRbnMonitor.Checked then
     rbn_status := 'Linked to RBNMonitor'
    else
     rbn_status := 'Disconnected';
end;

procedure TfrmGrayline.FormCreate(Sender: TObject);
var
  ImageFile : String;
  i : Integer;
begin
  InitCriticalSection(csRBN);
  tmrSpotDots.Enabled:=false;
  for i:=1 to MAX_ITEMS do
   begin
    RBNSpotList[i].band    := '';
    RBNSpotList[i].spotter := '';
    RBNSpotList[i].time    := DateTimeToUnix(now);
    RBNSpotList[i].strengt := 0;
    RBNSpotList[i].lat  := 0;
    RBNSpotList[i].long := 0;
   end;
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
  sbGrayLine.Visible        := cqrini.ReadBool('Grayline','Statusbar',True);
  pumShowShortPath.Checked  := cqrini.ReadBool('Grayline','ShortPath',False);
  pumShowLongPath.Checked   := cqrini.ReadBool('Grayline','LongPath',False);
  acShowStatusBar.Checked   := sbGrayLine.Visible;
  rbn_status                :='Disconnected';
  sbGrayLine.SimpleText     := rbn_status;
  tmrGrayLine.Enabled       := True;
  tmrGrayLineTimer(nil);
  tmrAutoConnect.Enabled    := True;
  delAfter                  := cqrini.ReadInteger('RBN','deleteAfter',60);
  tmrSpotDots.Interval      :=1000;  //remove Spots(DOts) timer will always run 1 sec period.
  tmrSpotDots.Enabled       :=true;
end;

procedure TfrmGrayline.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  tmrGrayLine.Enabled := False;
  tmrAutoConnect.Enabled:=False;
  tmrSpotDots.Enabled:=False;
  if ltelnet <> nil then
       Begin
         lTelnet.Disconnect;
         sleep(100);
         FreeAndNil(lTelnet);
       end;
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
end;

procedure TfrmGrayline.pumClearAllSpotsClick(Sender: TObject);
begin
  tmrSpotDots.Enabled:=False;
  RemoveOldSpots(0);
  delAfter := cqrini.ReadInteger('RBN','deleteAfter',60);
  tmrSpotDots.Enabled:=true;
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
begin
    if (rbn_status='Connected') or (rbn_status='Linked to RBNMonitor' ) then exit;
    if cqrini.ReadBool('RBN','AutoLink',false) then
        Begin
         acLinkToRbnMonitorExecute(nil);
         exit;
        end;
    if cqrini.ReadBool('RBN','AutoConnect',False) and (cqrini.ReadString('RBN','login','') <> '')
       and (lTelnet = nil) then  acConnect.Execute;

    tmrAutoConnect.Enabled:=False; //job is done, nex initiate when FormShow run
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
  if rbn_status='Connected' then
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
  if pumShowShortPath.Checked or pumShowLongPath.Checked then
    Begin
      if pumShowShortPath.Checked then
                                      PlotGreatCircleArcLine(long,lat,long1,lat1,false);
      if pumShowLongPath.Checked then
                                      PlotGreatCircleArcLine(long,lat,long1,lat1,true);
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

procedure TfrmGrayline.PlotGreatCircleArcLine(longitude1,latitude1,longitude2,latitude2:extended; LongP:boolean);
 { Ref: http://www.movable-type.co.uk/scripts/latlong.html }

Const
  MEC       = 170  *pi/180;       // Map image horizontal Edge Crossing "no print" limit in degrees (converted to radians)

var
  lat1,lat2,lon1,lon2,
  latFrom,lonFrom,
  BaseStep,step,                  // degree steps (converted to radians) for path line
  PolarStep,                      // steps in polar regions where distances/degrees are smaller
  bearing, oldbearing : extended;
  CountLimit,
  LP                  : integer;  //LongPath instead of ShortPath

Begin
BaseStep  := cqrini.ReadFloat('Program', 'GraylineGCstep',15E-001) * pi/180;
PolarStep := Basestep/cqrini.ReadInteger('Program', 'GraylineGCstep',10);
ob^.GC_LWidth := cqrini.ReadInteger('Program', 'GraylineGCLineWidth',2);
ob^.GC_SP_Color:=StringToColor(cqrini.ReadString('Program', 'GraylineGCLineSPColor', 'clYellow' ));
ob^.GC_LP_Color:=StringToColor(cqrini.ReadString('Program', 'GraylineGCLineLPColor', 'clFuchsia' ));

if LocalDbg then
      begin
        writeln ('-------------------------------------------------------------------');
        writeln ('Start:',round(latitude1),' ',round(longitude1),' ',round(latitude2),' ',round(longitude2));
      end;

step := BaseStep;

if LongP then
               LP:=1
         else
               LP:=0;
ob^.GC_line_clear(LP);
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
       if not LongP then
         ob^.GC_line_part(RadToDeg(lonFrom),RadToDeg(latFrom)*-1,RadToDeg(longitude1),RadToDeg(latitude1)*-1)
        else
         ob^.GC_Lline_part(RadToDeg(lonFrom),RadToDeg(latFrom)*-1,RadToDeg(longitude1),RadToDeg(latitude1)*-1)
      end;

  oldbearing:=bearing;
 end;
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

  for i:=1 to MAX_ITEMS do
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
  time,
  SpotTime: int64;

begin
  time := DateTimeToUnix(now);
  EnterCriticalsection(csRBN);
  for i:=1 to MAX_ITEMS do
   begin
     if ((time - RBNSpotList[i].time) > RemoveAfter) then
         RBNSpotList[i].band :='';
   end;
  SynRBN;
  LeaveCriticalsection(csRBN);

end;
procedure TfrmGrayline.AddSpotToList(spot : String);

  procedure GetRealCoordinate(lat,long : String; var latitude, longitude: Currency);
  var
    s,d : String;
  begin
    s := lat;
    d := long;
    if ((Length(s)=0) or (Length(d)=0)) then
    begin
      longitude := 0;
      latitude  := 0;
      exit
    end;

    if s[Length(s)] = 'S' then
      s := '-' +s ;
    s := copy(s,1,Length(s)-1);
    if pos('.',s) > 0 then
      s[pos('.',s)] := FormatSettings.DecimalSeparator;
    if not TryStrToCurr(s,latitude) then
      latitude := 0;

    if d[Length(d)] = 'W' then
      d := '-' + d ;
    d := copy(d,1,Length(d)-1);
    if pos('.',d) > 0 then
      d[pos('.',d)] := FormatSettings.DecimalSeparator;
    if not TryStrToCurr(d,longitude) then
      longitude := 0;
    if LocalDbg then
    begin
      Writeln('Lat:  ',latitude);
      Writeln('Long: ',longitude);
    end;
  end;

  procedure ParseSpot(spot : String; var spotter, dxstn, freq, mode, stren : String);
  var
     i: integer;
  begin
    spotter := ExtractWord(3,spot,[' ']);
     i := pos('-', spotter);
    if i > 0 then
      spotter := copy(spotter, 1, i-1);
    dxstn := ExtractWord(5,spot,[' ']);
    freq  := ExtractWord(4,spot,[' ']);
    mode  := ExtractWord(6,spot,[' ']);
    stren := ExtractWord(7,spot,[' ']);
  end;

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
  mode    : String;
  latitude, longitude: Currency;
begin
  if pos('DX DE',UpperCase(spot) )<> 1 then exit;
  watchFor   := cqrini.ReadString('RBN','watch','');
  ParseSpot(spot, spotter, call, freq, mode, stren);

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

  if index = 0 then
  begin
    Writeln('CRITICAL ERROR! THIS SHOULD NOT HAPPEN, RBN LIST IS FULL');
    exit
  end;
  band := dmDXCluster.GetBandFromFreq(freq,True);

  frmGrayline.RBNSpotList[index].band    := band;
  frmGrayline.RBNSpotList[index].spotter := spotter;
  frmGrayline.RBNSpotList[index].time    := DateTimeToUnix(now);
  if TryStrToInt(stren,tmp) then
    frmGrayline.RBNSpotList[index].strengt := tmp
  else
    frmGrayline.RBNSpotList[index].strengt := 0;

  GetRealCoordinate(lat,long,latitude, longitude);
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
    Writeln('Add Long:   ',long)
   end;
end;


end.

