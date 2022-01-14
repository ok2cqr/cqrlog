unit fGrayline;

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,LResources,Forms,Controls,Graphics,Dialogs,gline2,TAGraph,
  ExtCtrls,Buttons,inifiles,FileUtil,Menus,ActnList,ComCtrls,lNetComponents,
  lnet, lclType, LazFileUtils, StrUtils, DateUtils;

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

  public
    RBNSpotList : array[1..MAX_ITEMS] of TRBNList;
    band   : String;
    ob  : Pgrayline;
    s,d : String;
    pfx : String;
    rbn_status  : String;
    procedure kresli;
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
<<<<<<< HEAD
  frmGrayline.rbn_status := 'Connected';
  Synchronize(@frmGrayline.SynRBN);
||||||| fcb37e8
  frmGrayline.rbn_status := 'Connected';
  Synchronize(@frmGrayline.SynRBN)
=======
  rbn_status := 'Connected';
>>>>>>> gray_spots
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
    if frmGrayline.RBNSpotList[i].band='' then
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
    if frmGrayline.RBNSpotList[i].spotter=spotter then
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

<<<<<<< HEAD
procedure TRBNThread.Execute;
begin
  if not ConnectToRBN then
  begin
    if dmData.DebugLevel>=1 then Writeln('Can not connect to RBN!');
    FreeAndNil(lTelnet);
    exit
  end;

  InitCriticalSection(cs);
  while not Terminated do
  begin
    EnterCriticalsection(cs);
    try
      login      := cqrini.ReadString('RBN','login','');
      watchFor   := cqrini.ReadString('RBN','watch','');
      delAfter   := cqrini.ReadInteger('RBN','deleteAfter',60)
    finally
      LeaveCriticalsection(cs)
    end;
    //RemoveOldSpots;    done now by tmrRemoveDots
    Synchronize(@frmGrayline.SynRBN);
    sleep(1000)
  end;
  lTelnet.Disconnect(true);
  DoneCriticalsection(cs)
end;

procedure TfrmGrayline.FormCreate(Sender: TObject);
var
  ImageFile : String;
  i : Integer;
begin
  InitCriticalSection(csRBN);
  RBNThread := nil;
  for i:=1 to MAX_ITEMS do
    RBNSpotList[i].band := '';
  ImageFile := dmData.HomeDir+'images'+PathDelim+'grayline.bmp';
  if not FileExists(ImageFile) then
    ImageFile := ExpandFileNameUTF8('..'+PathDelim+'share'+PathDelim+'cqrlog'+
                 PathDelim+'images'+PathDelim+'grayline.bmp');
  ob:=new(Pgrayline,init(ImageFile));

   tmrRemoveDots.Interval:= cqrini.ReadInteger('RBN','deleteAfter',60)*1000;
   tmrRemoveDots.Enabled:=true;

end;

procedure TfrmGrayline.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if RBNThread<>nil then
   Begin
    RBNThread.Terminate;
   end;
  cqrini.WriteBool('Grayline','Statusbar',sbGrayLine.Visible);
  dmUtils.SaveWindowPos(frmGrayline);
end;

||||||| fcb37e8
procedure TRBNThread.Execute;
begin
  if not ConnectToRBN then
  begin
    if dmData.DebugLevel>=1 then Writeln('Can not connect to RBN!');
    FreeAndNil(lTelnet);
    exit
  end;

  InitCriticalSection(cs);
  while not Terminated do
  begin
    EnterCriticalsection(cs);
    try
      login      := cqrini.ReadString('RBN','login','');
      watchFor   := cqrini.ReadString('RBN','watch','');
      delAfter   := cqrini.ReadInteger('RBN','deleteAfter',60)
    finally
      LeaveCriticalsection(cs)
    end;
    //RemoveOldSpots;    done now by tmrRemoveDots
    Synchronize(@frmGrayline.SynRBN);
    sleep(1000)
  end;
  lTelnet.Disconnect(true);
  DoneCriticalsection(cs)
end;

procedure TfrmGrayline.FormCreate(Sender: TObject);
var
  ImageFile : String;
  i : Integer;
begin
  InitCriticalSection(csRBN);
  RBNThread := nil;
  for i:=1 to MAX_ITEMS do
    RBNSpotList[i].band := '';
  ImageFile := dmData.HomeDir+'images'+PathDelim+'grayline.bmp';
  if not FileExists(ImageFile) then
    ImageFile := ExpandFileNameUTF8('..'+PathDelim+'share'+PathDelim+'cqrlog'+
                 PathDelim+'images'+PathDelim+'grayline.bmp');
  ob:=new(Pgrayline,init(ImageFile));

   tmrRemoveDots.Interval:= cqrini.ReadInteger('RBN','deleteAfter',60)*1000;
   tmrRemoveDots.Enabled:=true;

end;

procedure TfrmGrayline.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if RBNThread<>nil then RBNThread.Terminate;
  cqrini.WriteBool('Grayline','Statusbar',sbGrayLine.Visible);
  dmUtils.SaveWindowPos(frmGrayline)
end;

=======
>>>>>>> gray_spots
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
    RBNSpotList[i].band := '';
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
  sbGrayLine.Visible      := cqrini.ReadBool('Grayline','Statusbar',True);
  acShowStatusBar.Checked := sbGrayLine.Visible;
  rbn_status              :='Disconnected';
  sbGrayLine.SimpleText   := rbn_status;
  tmrGrayLine.Enabled     := True;
  tmrGrayLineTimer(nil);
  tmrAutoConnect.Enabled  := True;
  delAfter := cqrini.ReadInteger('RBN','deleteAfter',60);
  tmrSpotDots.Interval:=1000;  //remove Spots(DOts) timer will always run 1 sec period.
  tmrSpotDots.Enabled:=true;
end;

procedure TfrmGrayline.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  tmrGrayLine.Enabled := False;
  tmrAutoConnect.Enabled:=False;
<<<<<<< HEAD
  tmrRemoveDots.Enabled:=False;
  sleep(100);
||||||| fcb37e8
  tmrRemoveDots.Enabled:=False;
  sleep(100)
=======
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
>>>>>>> gray_spots
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
  Refresh;
end;

procedure TfrmGrayline.tmrSpotDotsTimer(Sender: TObject);
begin
<<<<<<< HEAD
  RemoveOldSpots;
||||||| fcb37e8
  RemoveOldSpots
=======
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
>>>>>>> gray_spots
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
    if s[Length(s)] = 'S' then  //pokud je tam S musi byt udaj zaporny
      s := '-' +s ;
    s := copy(s,1,Length(s)-1);
    if pos('.',s) > 0 then
      s[pos('.',s)] := FormatSettings.DecimalSeparator;
    if not TryStrToCurr(s,lat1) then
      lat1 := 0;

    if d[Length(d)] = 'W' then  //pokud je tam W musi byt udaj zaporny
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
  lat := lat*-1;
  lat1 := lat1*-1;
  ob^.jachcucaru(true,long,lat,long1,lat1);
  Refresh
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
begin

  ob^.body_smaz;
  for i:=1 to MAX_ITEMS do
  begin
    if (RBNSpotList[i].band='') then
      Continue;

    if (band <> '') then
    begin
      if band<>RBNSpotList[i].band then
        Continue
    end;
    if LocalDbg then
    begin
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
    //procedure body_add(typ:byte;x1,y1,x2,y2:extended;popis:string;barva:tcolor;vel_bodu:longint);
    ob^.body_add(3,RBNSpotList[i].long,RBNSpotList[i].lat*-1,RBNSpotList[i].long,RBNSpotList[i].lat*-1,RBNSpotList[i].spotter,c,1);
  end;
  Refresh
end;

procedure  TfrmGrayline.RemoveOldSpots(RemoveAfter:integer); //setting RemoveAfter:=0 removes all Spots
var
  i       : Integer;
  time    : int64;

begin
  time := DateTimeToUnix(now);
  EnterCriticalsection(csRBN);
  for i:=1 to MAX_ITEMS do
  begin
     if (time - DateTimeToUnix(frmGrayline.RBNSpotList[i].time)) > RemoveAfter then
        with RBNSpotList[i] do
            Begin
                spotter  :='';
                band     :='';
                lat      :=0;
                long     :=0;
                strengt  :=0;
                time     :=0;
            end;
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
  frmGrayline.RBNSpotList[index].time    := now;
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
    Write('Add band:   ',dmDXCluster.GetBandFromFreq(freq,True));
    Write('Add Lat:    ',lat);
    Writeln('Add Long:   ',long)
   end;
end;


end.

