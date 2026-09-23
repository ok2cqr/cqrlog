unit fRbnMonitor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ComCtrls, ActnList, StdCtrls, Grids, lclType, ExtCtrls,
  Menus, RegExpr, uRbnSpotParser, uRbnSpotQueue, uRbnConnection;

const
  C_MAX_ROWS = 1000; //max lines in the list of RBN spots
  //spot lines waiting for the worker. At about 5 spots/s through the filter it is
  //some 100 s of backlog; beyond that the oldest lines are dropped and counted
  C_RBN_QUEUE_SIZE = 500;


type
  TRbnSpot = record
    spotter : String[20];
    dxstn   : String[20];
    freq    : String[20];
    mode    : String[10];
    qsl     : String[2];
    dxinfo  : String[1];
    signal  : String[3];
  end;

type
  TOnShowSpotEvent = procedure(RbnSpot : TRbnSpot) of Object;

type
  TRbnThread = class(TThread)
  private
    cs  : TRTLCriticalSection;
    reg : TRegExpr;
    fRbnSpot : TRbnSpot;
    FOnShowSpot : TOnShowSpotEvent;
    function AllowedSpot(spotter, dxstn, freq, mode, LoTW, eQSL : String;
                         var dxinfo : String; var band, lat, long : String) : Boolean;

    procedure ShowSpot;
  protected
    procedure Execute; override;
  public
    DxccWithLoTW              : Boolean;
    fil_SrcCont               : String;
    fil_SrcCalls              : TStringList;
    fil_IgnWkdHour            : Boolean;
    fil_IgnHourValue          : Integer;
    fil_IgnDate               : Boolean;
    fil_IgnDateValue          : String;
    fil_IgnTimeValue          : String;
    fil_AllowAllCall          : Boolean;
    fil_AllowOnlyCall         : Boolean;
    fil_AllowOnlyCallValue    : String;
    fil_AllowOnlyCallReg      : Boolean;
    fil_AllowOnlyCallRegValue : String;
    fil_AllowCont             : String;
    fil_AllowBands            : String;
    fil_AllowModes            : String;
    fil_AllowCnty             : String;
    fil_NotCnty               : String;
    fil_LoTWOnly              : Boolean;
    fil_eQSLOnly              : Boolean;
    fil_NewDXCOnly            : Boolean;

    //band map config, pushed from the main thread by LoadConfigToThread.
    //bm_ prefix keeps it apart from the fil_ spot filter config above
    bm_ToBandMap              : Boolean;
    bm_SourceId               : Integer;  //rbn_sources id of the main connection
    bm_RbnColor               : LongInt;
    //same rule as the DX cluster: with [BandMap] UseDXCColors the spot takes
    //the colour of its DXCC status (new one / new band / new mode / QSL needed)
    bm_UseDxcColors           : Boolean;
    bm_NewCountryColor        : LongInt;
    bm_NewBandColor           : LongInt;
    bm_NewModeColor           : LongInt;
    bm_NeedQslColor           : LongInt;
    FDxccIndex                : Integer;  //of the spot AllowedSpot last accepted
    //LoTW/eQSL user background, the same [LoTW] settings the DX cluster window uses
    bm_UseLotwBgColor         : Boolean;
    bm_LotwBgColor            : LongInt;
    bm_UseEqslBgColor         : Boolean;
    bm_EqslBgColor            : LongInt;

    property OnShowSpot : TOnShowSpotEvent read FOnShowSpot write FOnShowSpot;
end;


type

  { TfrmRbnMonitor }

  TfrmRbnMonitor = class(TForm)
    acRbnMonitor: TActionList;
    acConnect: TAction;
    acDisconnect: TAction;
    acFontSettings: TAction;
    acFilter: TAction;
    acRbnServer: TAction;
    acScrollDown : TAction;
    acHelp : TAction;
    acClear: TAction;
    acLinkToBandMap: TAction;
    dlgFont: TFontDialog;
    imgRbnMonitor: TImageList;
    popRbnMonitor: TPopupMenu;
    pumToBandMap: TMenuItem;
    sbRbn: TStatusBar;
    sgRbn: TStringGrid;
    tmrUnfocus: TTimer;
    ToolBar1: TToolBar;
    tbtnConnect: TToolButton;
    ToolButton1 : TToolButton;
    tbtnHelp: TToolButton;
    ToolButton11: TToolButton;
    ToolButton2: TToolButton;
    tbtnServer: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    tbtnFilter: TToolButton;
    tbtnFont: TToolButton;
    ToolButton7: TToolButton;
    tbtnLastLine : TToolButton;
    tbtnClear: TToolButton;
    procedure acClearExecute(Sender: TObject);
    procedure acConnectExecute(Sender: TObject);
    procedure acDisconnectExecute(Sender: TObject);
    procedure acFilterExecute(Sender: TObject);
    procedure acFontSettingsExecute(Sender: TObject);
    procedure acHelpExecute(Sender : TObject);
    procedure acLinkToBandMapExecute(Sender: TObject);
    procedure acRbnServerExecute(Sender: TObject);
    procedure acScrollDownExecute(Sender : TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyUp(Sender : TObject; var Key : Word; Shift : TShiftState);
    procedure FormShow(Sender: TObject);
    procedure sgRbnDblClick(Sender: TObject);
    procedure sgRbnDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect;
      aState: TGridDrawState);
    procedure sgRbnEnter(Sender: TObject);
    procedure sgRbnExit(Sender: TObject);
    procedure sgRbnHeaderSized(Sender: TObject; IsColumn: Boolean;
      Index: Integer);
    procedure tmrUnfocusTimer(Sender: TObject);
    procedure ToolButton3Click(Sender: TObject);
  private
    RbnMonThread : TRbnThread;
    aRbnArchive  : Array of TRbnSpot;
    SrcCalls : TStringlist;


    function  GetModeFromFreq(freq: string): string;

    procedure ParkFocus;
    procedure StopRbnThread;
    procedure StartRbnThread;
    procedure OnRbnSpot(const Line : String; const Spot : TRbnSpotLine);
    procedure OnRbnState(Sender : TObject);

  public
    SpotQueue    : TRbnSpotQueue;  //main thread pushes, TRbnThread pops
    FConn        : TRbnConnection;  //the main RBN source, shared, not owned
    DeleteCount  : Integer;
    procedure SynRbnMonitor(RbnSpot : TRbnSpot);
    procedure LoadConfigToThread;
  end;

var
  frmRbnMonitor: TfrmRbnMonitor;

implementation
{$R *.lfm}

uses dUtils, uMyIni, dData, dSqlRef, fRbnControl, dDXCluster, fRbnFilter, fNewQSO,
     fBandMap, uBandMapStore, uDebugLog, sqldb;

{ TfrmRbnMonitor }

procedure TRBNThread.ShowSpot;
begin
  if Assigned(OnShowSpot) then
  begin
    FOnShowSpot(fRbnSpot)
  end;
end;

function TRBNThread.AllowedSpot(spotter, dxstn, freq, mode, LoTW, eQSL : String;
                                var dxinfo : String; var band, lat, long : String) : Boolean;
var
  SrcCont  : String;
  DestCont : String;
  Country  : String;
  waz,itu  : String;
  pfx      : String;
  LastDate : String;
  LastTime : String;
  Boundary : TDateTime;
  adif     : Word;
  index    : Integer;
  f        : Double;
  i        : integer;
  SpotterOk: Boolean;
begin
  Result := False;
  lat    := '';   //cleared here so the ~15 early exits below cannot leak
  long   := '';   //the coordinates of the previously accepted spot

  if (fil_SrcCalls.Count>0) then
   Begin
     SpotterOK:=false;
     for i:=0 to fil_SrcCalls.Count-1 do
      Begin
        if (pos(fil_SrcCalls.Strings[i], spotter)=1) then  //begins with definition
                                   begin
                                     SpotterOk := True;
                                     Break;
                                   end;
      end;
     if Not SpotterOK then
        Begin
          if dmData.DebugLevel>=2 then
                                  Writeln('RBNMonitor: ','Wrong source callsign - ',Spotter);
          Exit
        end;
    end;

  dmDXCluster.id_country(spotter,now,pfx,Country,waz,itu,SrcCont);
  if (Pos(SrcCont+',',fil_SrcCont+',') = 0) and (fil_SrcCont<>'') then
  begin
    if dmData.DebugLevel>=2 then Writeln('RBNMonitor: ','Wrong source continent - ',SrcCont);
    exit
  end;

  if fil_IgnWkdHour then
  begin
    //qsodate/time_on are stored in UTC, the boundary has to be in UTC as well
    Boundary := dmUtils.GetDateTime(fil_IgnHourValue);
    LastDate := FormatDateTime('YYYY-MM-DD',Boundary);
    LastTime := FormatDateTime('HH:NN',Boundary)
  end
  else begin
    LastDate := fil_IgnDateValue;
    LastTime := fil_IgnTimeValue
  end;

  Band := dmDXCluster.GetBandFromFreq(freq,True);
  if (Band='') then
  begin
    if dmData.DebugLevel>=2 then Writeln('RBNMonitor: ','Wrong band - ',Band);
    exit
  end;

  if dmData.RbnLogCache.WorkedAfter(dxstn,Band,mode,LastDate,LastTime) then
  begin
    if dmData.DebugLevel>=2 then Writeln('RBNMonitor: ','Station already exist in the log - ',dxstn);
    exit
  end;

  if fil_AllowOnlyCall then
  begin
    if Pos(dxstn+',',fil_AllowOnlyCallValue+',') = 0 then
    begin
      if dmData.DebugLevel>=2 then Writeln('RBNMonitor: ','Station is not between allowed callsigns - ',dxstn);
      exit
    end
  end;

  if fil_AllowOnlyCallReg then
   begin
   if (trim(fil_AllowOnlyCallRegValue)='') or (trim(dxstn)='') then
    begin    // do not allow empty regexp
      if dmData.DebugLevel>=2 then Writeln('RBNMonitor: ','Station or allowed callsigns - empty ');
      exit
    end;
    reg.Expression  := fil_AllowOnlyCallRegValue;
    reg.InputString := dxstn;
    if not reg.Exec(1) then
    begin
      if dmData.DebugLevel>=2 then Writeln('RBNMonitor: ','Station is not between allowed callsigns - ',dxstn);
      exit
    end
  end;

  if (Pos(band+',',fil_AllowBands+',')=0) and (fil_AllowBands<>'') then
  begin
    if dmData.DebugLevel>=2 then Writeln('RBNMonitor: ','This band is NOT allowed - ',band);
    exit
  end;

  if (Pos(mode+',',fil_AllowModes+',')=0) and (fil_AllowModes<>'') then
  begin
    if dmData.DebugLevel>=2 then Writeln('RBNMonitor: ','This mode is NOT allowed - ',mode);
    exit
  end;

  //9 arg overload, superset of the 7 arg one. It picks up lat/long for the band map
  //at the same lookup, so there is no extra DB round trip
  adif := dmDXCluster.id_country(dxstn,now,Pfx,Country,waz,itu,DestCont,lat,long);

  if (Pos(DestCont+',',fil_AllowCont+',') = 0) and (fil_AllowCont<>'') then
  begin
    if dmData.DebugLevel>=2 then Writeln('RBNMonitor: ','Wrong continent - ',DestCont);
    exit
  end;

  if ((fil_NotCnty<>'') and (Pos(pfx+',',fil_NotCnty+',')>0)) then
  begin
    if dmData.DebugLevel>=2 then Writeln('RBNMonitor: ','This country is not allowed - ',pfx);
    exit
  end;

  if ((fil_AllowCnty<>'') and (Pos(pfx+',',fil_AllowCnty+',')=0)) then
  begin
    if dmData.DebugLevel>=2 then Writeln('RBNMonitor: ','This country is not allowed - ',pfx);
    exit
  end;

  if fil_LoTWOnly and (LoTW<>'L') then
  begin
    if dmData.DebugLevel>=2 then Writeln('RBNMonitor: ','This station is not LoTW user - ',dxstn);
    exit
  end;

  if fil_eQSLOnly and (eQSL<>'E') then
  begin
    if dmData.DebugLevel>=2 then Writeln('RBNMonitor: ','This station is not eQSL user - ',dxstn);
    exit
  end;

  //DxccWithLoTW was never set anywhere, the LoTW variant of the query was dead
  index := dmData.RbnLogCache.DxccStatus(adif,band,mode);
  FDxccIndex := index;
  case index of
    1 : dxinfo := 'N';
    2 : dxinfo := 'B';
    3 : dxinfo := 'M';
    else
     Begin
      dxinfo := '';
      if fil_NewDXCOnly then
                        Begin
                          if dmData.DebugLevel>=2 then Writeln('RBNMonitor: ','Not new one, band or mode - ',dxstn);
                          exit;
                        end;
     end;
  end; //case

  Result := True
end;

procedure TRBNThread.Execute;

var
  spot    : String;
  spotter : String;
  freq    : String;
  stren   : String;
  mode    : String;
  dxstn   : String;
  LoTW    : String;
  eQSL    : String;
  dxinfo  : String;
  RbnSpot : TRbnSpot;
  index   : Integer;
  band    : String;
  lat     : String;
  long    : String;
  fkHz    : Double;
  cLat    : Currency;
  cLng    : Currency;
  bgColor : LongInt;
  spotColor : LongInt;
  fsRbn   : TFormatSettings;
  nSpots  : Int64 = 0;
  tBeat   : TDateTime;
  Parsed  : TRbnSpotLine;
begin
  DbgLog('RBN','thread started');
  tBeat := Now;
  spot := ''; spotter := ''; dxstn := ''; freq := ''; mode := '';
  reg := TRegExpr.Create;
  //RBN always sends the frequency with a literal dot. Parsing it with the locale
  //settings would silently drop every spot on a comma decimal locale
  fsRbn := DefaultFormatSettings;
  fsRbn.DecimalSeparator := '.';
  try
    while not Terminated do
    try
      if not frmRbnMonitor.SpotQueue.Pop(spot) then
        spot := '';
      //heartbeat, so the log distinguishes "thread died" from "no spots arrived"
      if (Now - tBeat) > (5/1440) then
      begin
        tBeat := Now;
        DbgLog('RBN','alive, spots processed=' + IntToStr(nSpots) +
                     ' queue=' + IntToStr(frmRbnMonitor.SpotQueue.Count) +
                     ' dropped=' + IntToStr(frmRbnMonitor.SpotQueue.Dropped) +
                     ' received10min=' + IntToStr(frmRbnMonitor.FConn.SpotsLastMinutes))
      end;

      if (spot='') then
      begin
        sleep(200);
        Continue
      end;
      Inc(nSpots);

      //lReceive queues only what parses, but the queue is a list of strings
      if not ParseRbnSpot(spot, Parsed) then
        Continue;
      spotter := Parsed.Spotter;
      dxstn   := Parsed.Dx;
      freq    := Parsed.FreqText;
      mode    := Parsed.Mode;
      stren   := IntToStr(Parsed.SignalDb);

      if dmData.UsesLotw(dxstn) then
        LoTW := 'L'
      else
        LoTW := '';

      if dmDXCluster.UseseQSL(dxstn) then
        eQSL := 'E'
      else
        eQSL := '';

      //same rule as TfrmDXCluster: when the station uses both, LoTW wins
      bgColor := clWindow;
      if bm_UseEqslBgColor and (eQSL='E') then
        bgColor := bm_EqslBgColor;
      if bm_UseLotwBgColor and (LoTW='L') then
        bgColor := bm_LotwBgColor;

      if AllowedSpot(spotter,dxstn,freq,mode,LoTW,eQSL,dxinfo,band,lat,long) then
      begin
        spotColor := bm_RbnColor;
        if bm_UseDxcColors then
          case FDxccIndex of
            1 : spotColor := bm_NewCountryColor;
            2 : spotColor := bm_NewBandColor;
            3 : spotColor := bm_NewModeColor;
            4 : spotColor := bm_NeedQslColor;
          end;
        fRbnSpot.spotter := spotter;
        fRbnSpot.dxstn   := dxstn;
        fRbnSpot.freq    := freq;
        fRbnSpot.mode    := mode;
        fRbnSpot.qsl     := LoTW+eQSL;
        fRbnSpot.dxinfo  := dxinfo;
        fRbnSpot.signal  := stren;

        //done here, on the worker, and not in SynRbnMonitor. AddToBandMap only appends
        //to an array under a critical section, so it must not be put behind the
        //Synchronize bottleneck nor behind the sgRbn.Focused grid stall
        if bm_ToBandMap and frmBandMap.Showing then
        begin
          if TryStrToFloat(freq,fkHz,fsRbn) then    //RBN freq is already in kHz
          begin
            dmDXCluster.GetRealCoordinate(lat,long,cLat,cLng);
            frmBandMap.AddToBandMap(fkHz,dxstn,mode,band,'',cLat,cLng,
                                    spotColor,bgColor,False,(LoTW='L'),(eQSL='E'))
          end
        end;

        //the shared spot store collects whether or not a band map window is
        //open; the text band map above keeps its own way
        if bm_ToBandMap and Assigned(BandMapStore) then
        begin
          if TryStrToFloat(freq,fkHz,fsRbn) then    //RBN freq is already in kHz
            BandMapStore.Add(fkHz,dxstn,mode,band,'',spotColor,bgColor,
                             gssRbn,(LoTW='L'),(eQSL='E'),spotter,bm_SourceId)
        end;

        Synchronize(@ShowSpot)
      end
      //no Sleep here any more: the 100 ms after every spot capped the worker at
      //10 spots/s minus the SQL time, below an ordinary evening's 6/s with peaks
      //of 24/s. The thread sleeps above, when the queue is empty
    except
      //per spot, not around the whole loop: the loop version ended the thread
      //on the first exception of any kind and RBN silently stopped updating
      //until restart. Seen with "Server has gone away" after the machine slept
      on E: ESQLDatabaseError do
      begin
        DbgLogException('RBN','spot=' + spot + ' dxstn=' + dxstn +
                              ' spotter=' + spotter + ' freq=' + freq +
                              ' mode=' + mode, E);
        //the spot is dropped; the connection is reopened for the next one. On
        //failure wait, so a server that is still down is not hammered per spot
        if not dmData.ReconnectRbnMon then
          Sleep(5000)
      end;
      on E: Exception do
      begin
        Writeln('*********',E.Message);
        DbgLogException('RBN','spot=' + spot + ' dxstn=' + dxstn +
                              ' spotter=' + spotter + ' freq=' + freq +
                              ' mode=' + mode, E)
      end
    end
  finally
    DbgLog('RBN','thread leaving Execute, Terminated=' + BoolToStr(Terminated,True));
    FreeAndNil(reg)
  end
end;

///////////////////////////////////////////////////////////////////////////////////////////////////////

//subscriber of the shared connection, main thread. The worker filters and
//needs a queue
procedure TfrmRbnMonitor.OnRbnSpot(const Line : String; const Spot : TRbnSpotLine);
begin
  //the Grayline is a subscriber of the same connection itself now
  if Assigned(RbnMonThread) then
    SpotQueue.Push(Line)
end;

procedure TfrmRbnMonitor.OnRbnState(Sender : TObject);
begin
  //the worker follows the connection, not the window: it is what feeds the
  //band maps, and they must fill whether or not the monitor is open
  if FConn.State = rcsDisconnected then
    StopRbnThread
  else
    StartRbnThread;
  sbRbn.Panels[0].Text := FConn.Status;
  //while waiting for a retry the button offers Disconnect: that is how to stop it
  if FConn.State = rcsDisconnected then
    tbtnConnect.Action := acConnect
  else
    tbtnConnect.Action := acDisconnect
end;

procedure TfrmRbnMonitor.StopRbnThread;
begin
  if not Assigned(RbnMonThread) then
    exit;
  //no more grid updates from now on. ShowSpot tests this on the main thread,
  //and TThread.WaitFor below keeps serving Synchronize while it waits
  RbnMonThread.OnShowSpot := nil;
  RbnMonThread.Terminate;
  FreeAndNil(RbnMonThread);  //Destroy waits for Execute to leave

  //whatever was still queued belongs to the connection that has just ended
  SpotQueue.Clear
end;

//The connection is the RBN control window's; the monitor only starts its own
//worker and asks the control to connect
procedure TfrmRbnMonitor.acConnectExecute(Sender: TObject);
begin
  StartRbnThread;
  if FConn.State = rcsDisconnected then
    frmRbnControl.ConnectMain;
  ParkFocus
end;

procedure TfrmRbnMonitor.StartRbnThread;
begin
  //the worker survives a socket drop (it still drains the queue), so connecting
  //again must reuse it. Creating a new one here used to leak the old thread
  if not Assigned(RbnMonThread) then
  begin
    //restored here, not in FormShow: the thread may start before the window
    //is ever opened, and LoadConfigToThread reads this action
    acLinkToBandMap.Checked := cqrini.ReadBool('RBNMonitor','ToBandMap',False);
    RbnMonThread := TRBNThread.Create(True);
    RbnMonThread.FreeOnTerminate :=  False;// True; I think this causes abrt in terminate (TfrmRbnMonitor.acDisconnectExecute) because procedure has freeAndNil (does free twice)
    RbnMonThread.OnShowSpot := @SynRbnMonitor; //shows up when RBN traffic is high like IARU HF contest and connect is tried to close or filter adjusted
    LoadConfigToThread;
    RbnMonThread.Start
  end
  else
    LoadConfigToThread
end;

procedure TfrmRbnMonitor.acClearExecute(Sender: TObject);
var l: integer;
begin
  for l:= sgRbn.rowcount - 1 downto 1 do
    sgRbn.DeleteRow(l);
end;

procedure TfrmRbnMonitor.acDisconnectExecute(Sender: TObject);
begin
  frmRbnControl.DisconnectMain;
  StopRbnThread
end;

procedure TfrmRbnMonitor.acFilterExecute(Sender: TObject);
begin
  with TfrmRbnFilter.Create(frmRbnMonitor) do
  try
    if ShowModal = mrOK then
      LoadConfigToThread
  finally
    Free
  end;
  ParkFocus
end;

procedure TfrmRbnMonitor.acLinkToBandMapExecute(Sender: TObject);
begin
  acLinkToBandMap.Checked := not acLinkToBandMap.Checked;
  cqrini.WriteBool('RBNMonitor','ToBandMap',acLinkToBandMap.Checked);
  //pushed straight to the worker so the toggle takes effect without a reconnect
  if Assigned(RbnMonThread) then
    RbnMonThread.bm_ToBandMap := acLinkToBandMap.Checked
end;

procedure TfrmRbnMonitor.acFontSettingsExecute(Sender: TObject);
begin
  dlgFont.Font := sgRbn.Font;
  if dlgFont.Execute then
  begin
    cqrini.WriteString('RBNMonitor','Font',dlgFont.Font.Name);
    cqrini.WriteInteger('RBNMonitor','FontSize',dlgFont.Font.Size);
    sgRbn.Font := dlgFont.Font
  end;
  ParkFocus
end;

procedure TfrmRbnMonitor.acHelpExecute(Sender : TObject);
begin
  dmUtils.OpenInApp(dmData.HelpDir+'h31.html')
end;

procedure TfrmRbnMonitor.acRbnServerExecute(Sender: TObject);
begin
  frmRbnControl.Show;
  frmRbnControl.BringToFront
end;

procedure TfrmRbnMonitor.acScrollDownExecute(Sender : TObject);
begin
  sgRbn.Row := sgRbn.RowCount;
  ParkFocus
end;

//Moves keyboard focus off any child control. With no ActiveControl set, LCL
//focuses the form window itself (see TCustomForm.SetWindowFocus), so KeyPreview
//keeps routing keys to FormKeyUp and Esc still returns to the NewQSO window.
//Leaving sgRbn focused would also keep the monitor in the PAUSED state, see sgRbnEnter.
procedure TfrmRbnMonitor.ParkFocus;
begin
  ActiveControl := nil
end;

procedure TfrmRbnMonitor.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
var
  i : Integer;
begin
  for i:=0 to sgRbn.ColCount-1 do
    cqrini.WriteInteger('WindowSize','RbnCol'+IntToStr(i),sgRbn.ColWidths[i]);
  //the connection and the worker are not the window's, both keep going
  dmUtils.SaveWindowPos(self);
end;

procedure TfrmRbnMonitor.FormCreate(Sender: TObject);
begin
  DeleteCount := 0;

  sgRbn.RowCount := 1;

  SpotQueue := TRbnSpotQueue.Create(C_RBN_QUEUE_SIZE);
  SrcCalls:= TStringList.Create;

  FConn := RbnMainConnection;
  FConn.SubscribeSpots(@OnRbnSpot);
  FConn.SubscribeState(@OnRbnState)
end;


procedure TfrmRbnMonitor.FormDestroy(Sender: TObject);
begin
  FConn.UnsubscribeSpots(@OnRbnSpot);
  FConn.UnsubscribeState(@OnRbnState);
  //the worker uses SpotQueue, it has to be gone before the queue is
  StopRbnThread;
  FreeAndNil(SrcCalls);
  FreeAndNil(SpotQueue)
end;

procedure TfrmRbnMonitor.FormKeyUp(Sender : TObject; var Key : Word;
  Shift : TShiftState);
begin
  if (key= VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0
  end
end;

procedure TfrmRbnMonitor.FormShow(Sender: TObject);
var
  i : Integer;
begin
  for i:=0 to sgRbn.ColCount-1 do
    sgRbn.ColWidths[i] := cqrini.ReadInteger('WindowSize','RbnCol'+IntToStr(i),70);

  dmUtils.LoadWindowPos(self);

  sgRbn.Options   := sgRbn.Options + [goColSizing] - [goRowSelect, goRangeSelect];
  sgRbn.Font.Name := cqrini.ReadString('RBNMonitor','Font',cDefaultMonoFont);
  sgRbn.Font.Size := cqrini.ReadInteger('RBNMonitor','FontSize',10);

  sgRbn.Cells[0,0] := 'Source';
  sgRbn.Cells[1,0] := 'Freq';
  sgRbn.Cells[2,0] := 'DX';
  sgRbn.Cells[3,0] := 'Mode';
  sgRbn.Cells[4,0] := 'dB';
  sgRbn.Cells[5,0] := 'Qsl';
  sgRbn.Cells[6,0] := 'DXCC';

  //restored in FormShow, not FormCreate, because cqrini is re-created on log switch.
  //must happen before acConnectExecute below, LoadConfigToThread reads this action
  acLinkToBandMap.Checked := cqrini.ReadBool('RBNMonitor','ToBandMap',False);

  if (FConn.State <> rcsDisconnected) or cqrini.ReadBool('RBN','AutoConnectM',False) then
     acConnectExecute(nil);
end;

procedure TfrmRbnMonitor.sgRbnDblClick(Sender: TObject);
var i:real;
    f:TFormatSettings;
begin
  //if (sgRbn.Cells[1,sgRbn.Row]<>'Freq') then  //easy way, but works only with header
  f.DecimalSeparator := '.';
  if TryStrToFloat( sgRbn.Cells[1,sgRbn.Row],i,f) then
    frmNewQSO.NewQSOFromSpot(sgRbn.Cells[2,sgRbn.Row],sgRbn.Cells[1,sgRbn.Row],sgRbn.Cells[3,sgRbn.Row],True)
end;

procedure TfrmRbnMonitor.sgRbnDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
begin
  {
  if (aRow>0) then
   begin
     if (Arow mod 2 > 0) then
       sgRbn.Canvas.Brush.Color:= clwhite
     else
       sgRbn.Canvas.Brush.Color:= $00E7FFEB;
     sgRbn.Canvas.FillRect(aRect);
     sgRbn.Canvas.TextOut(aRect.Left, aRect.top + 4, sgRbn.Cells[ACol, ARow])
   end }
end;

procedure TfrmRbnMonitor.sgRbnEnter(Sender: TObject);
begin
   frmRbnMonitor.Caption:= 'RBN Monitor  PAUSED!';
   ToolBar1.Repaint;
end;

procedure TfrmRbnMonitor.sgRbnExit(Sender: TObject);
begin
  frmRbnMonitor.Caption:= 'RBN Monitor';
  ToolBar1.Repaint;
end;

procedure TfrmRbnMonitor.sgRbnHeaderSized(Sender: TObject; IsColumn: Boolean;
  Index: Integer);
begin
  ParkFocus
end;

procedure TfrmRbnMonitor.FormDeactivate(Sender: TObject);
begin
   frmRbnMonitor.Caption:= 'RBN Monitor';
end;

//-------------------------------------------------
//if sgRbn cell is selected, then rbn monitor form looses focus and when it gets focus again
//another cell is randomly selected. There is no way to unselect column when from looses focus.
//(or then there is bug because it does not work in any way)
//ScrollDown releases focus but it cannot be called when
//form gets focus or it causes focus loop. Small delay fixes it and prevents loop.

procedure TfrmRbnMonitor.FormActivate(Sender: TObject);
begin
  tmrUnfocus.Enabled:=true;
end;

procedure TfrmRbnMonitor.tmrUnfocusTimer(Sender: TObject);
begin
  tmrUnfocus.Enabled:=false;
  acScrollDownExecute(nil);
end;

procedure TfrmRbnMonitor.ToolButton3Click(Sender: TObject);
begin
  popRbnMonitor.PopUp;
end;

//-------------------------------------------------
procedure TfrmRbnMonitor.LoadConfigToThread;

begin
  if Assigned(RbnMonThread) then
  begin
    RbnMonThread.fil_SrcCont := cqrini.ReadString('RBNFilter','SrcCont',C_RBN_CONT);

    SrcCalls.Clear;    //we need to do this via another TString list. Direct mods to fil_SrcCalls cause SIGSEGV
    SrcCalls.Delimiter:=',';
    SrcCalls.AddDelimitedtext(cqrini.ReadString('RBNFilter','SrcCall',''));
    RbnMonThread.fil_SrcCalls := SrcCalls;

    RbnMonThread.fil_IgnWkdHour    := cqrini.ReadBool('RBNFilter','IgnHour',True);
    RbnMonThread.fil_IgnHourValue  := cqrini.ReadInteger('RBNFilter','IgnHourValue',48);
    RbnMonThread.fil_IgnDate       := cqrini.ReadBool('RBNFilter','IgnDate',False);
    RbnMonThread.fil_IgnDateValue  := cqrini.ReadString('RBNFilter','IgnDateValue','');
    RbnMonThread.fil_IgnTimeValue  := cqrini.ReadString('RBNFilter','IgnTimeValue','');

    RbnMonThread.fil_AllowAllCall          := cqrini.ReadBool('RBNFilter','AllowAllCall',True);
    RbnMonThread.fil_AllowOnlyCall         := cqrini.ReadBool('RBNFilter','AllowOnlyCall',False);
    RbnMonThread.fil_AllowOnlyCallValue    := cqrini.ReadString('RBNFilter','AllowOnlyCallValue','');
    RbnMonThread.fil_AllowOnlyCallReg      := cqrini.ReadBool('RBNFilter','AllowOnlyCallReg',False);
    RbnMonThread.fil_AllowOnlyCallRegValue := cqrini.ReadString('RBNFilter','AllowOnlyCallRegValue','');

    RbnMonThread.fil_AllowCont  := cqrini.ReadString('RBNFilter','AllowCont',C_RBN_CONT);
    RbnMonThread.fil_AllowBands := cqrini.ReadString('RBNFilter','AllowBands',C_RBN_BANDS);
    RbnMonThread.fil_AllowModes := cqrini.ReadString('RBNFilter','AllowModes',C_RBN_MODES);
    RbnMonThread.fil_AllowCnty  := cqrini.ReadString('RBNFilter','AllowCnty','');
    RbnMonThread.fil_NotCnty    := cqrini.ReadString('RBNFilter','NotCnty','');

    RbnMonThread.fil_LoTWOnly := cqrini.ReadBool('RBNFilter','LoTWOnly',False);
    RbnMonThread.fil_eQSLOnly := cqrini.ReadBool('RBNFilter','eQSLOnly',False);

    RbnMonThread.fil_NewDXCOnly := cqrini.ReadBool('RBNFilter','NewDXCOnly',False);

    RbnMonThread.bm_ToBandMap := acLinkToBandMap.Checked;
    RbnMonThread.bm_SourceId  := frmRbnControl.MainSourceId;
    //resolved to a plain RGB here, on the main thread. The band map ages item colors
    //from its worker thread, so a system color like clWindowText would otherwise be
    //asked of the widgetset off the main thread on every aging tick
    RbnMonThread.bm_RbnColor  := ColorToRGB(cqrini.ReadInteger('BandMap','RbnColor',clWindowText));
    //the DX cluster's keys, so both feeds colour a new one the same way
    RbnMonThread.bm_UseDxcColors    := cqrini.ReadBool('BandMap','UseDXCColors',False);
    RbnMonThread.bm_NewCountryColor := ColorToRGB(cqrini.ReadInteger('DXCluster','NewCountry',clWindowText));
    RbnMonThread.bm_NewBandColor    := ColorToRGB(cqrini.ReadInteger('DXCluster','NewBand',clWindowText));
    RbnMonThread.bm_NewModeColor    := ColorToRGB(cqrini.ReadInteger('DXCluster','NewMode',clWindowText));
    RbnMonThread.bm_NeedQslColor    := ColorToRGB(cqrini.ReadInteger('DXCluster','NeedQSL',clWindowText));
    //same keys and defaults as TfrmDXCluster.ReloadSettings, so a spot gets the
    //same LoTW/eQSL background whichever window fed it to the band map
    RbnMonThread.bm_UseLotwBgColor := cqrini.ReadBool('LoTW','UseBackColor',True);
    RbnMonThread.bm_LotwBgColor    := ColorToRGB(cqrini.ReadInteger('LoTW','BckColor',clMoneyGreen));
    RbnMonThread.bm_UseEqslBgColor := cqrini.ReadBool('LoTW','eUseBackColor',True);
    RbnMonThread.bm_EqslBgColor    := ColorToRGB(cqrini.ReadInteger('LoTW','eBckColor',clSkyBlue))
  end;

end;

procedure TfrmRbnMonitor.SynRbnMonitor(RbnSpot : TRbnSpot);
var
  i : Integer;

  procedure AddRow;
  begin
    i := sgRbn.RowCount+1;
    sgRbn.RowCount := i;
    dec(i);

    sgRbn.Cells[0,i] := RbnSpot.spotter;
    sgRbn.Cells[1,i] := RbnSpot.freq;
    sgRbn.Cells[2,i] := RbnSpot.dxstn;
    sgRbn.Cells[3,i] := RbnSpot.mode;
    sgRbn.Cells[4,i] := RbnSpot.signal;
    sgRbn.Cells[5,i] := RbnSpot.qsl;
    sgRbn.Cells[6,i] := RbnSpot.dxinfo
  end;

begin
  if sgRbn.Focused then
  begin
    inc(DeleteCount);
    AddRow
  end
  else begin
    AddRow;
    if DeleteCount>0 then
    begin
      if (sgRbn.RowCount > C_MAX_ROWS) then
      begin
        for i:=1 to DeleteCount do
          sgRbn.DeleteRow(0)
      end;
      DeleteCount := 0
    end
    else begin
      if sgRbn.RowCount>C_MAX_ROWS then
        sgRbn.DeleteRow(0)
    end;

    sgRbn.Row := sgRbn.RowCount
  end
end;

function TfrmRbnMonitor.GetModeFromFreq(freq: string): string;
var
  Band: string;
  eFreq: Currency;
begin
  Result := '';
  if TryStrToCurr(freq,eFreq) then
    eFreq := eFreq/1000
  else
    exit;

  band := dmDXCluster.GetBandFromFreq(freq, True);
  dmData.qRbnMon.Close;
  dmData.qRbnMon.SQL.Text := dmSqlRef.SqlBand(band);
  if dmData.DebugLevel>=1 then Writeln(dmData.qRbnMon.SQL.Text);
  if dmData.trRbnMon.Active then
    dmData.trRbnMon.Rollback;
  dmData.trRbnMon.StartTransaction;
  try
    dmData.qRbnMon.Open;
    if dmData.qRbnMon.RecordCount > 0 then
    begin
      if ((eFreq >= dmData.qRbnMon.FieldByName('B_BEGIN').AsCurrency) and
        (eFreq <= dmData.qRbnMon.FieldByName('CW').AsCurrency)) then
        Result := 'CW'
      else
      begin
        if ((eFreq > dmData.qRbnMon.FieldByName('RTTY').AsCurrency) and
          (eFreq <= dmData.qRbnMon.FieldByName('SSB').AsCurrency)) then
          Result := 'RTTY'
        else begin
          Result := 'SSB'
        end
      end
    end
  finally
    dmData.qRbnMon.Close;
    dmData.trRbnMon.Rollback
  end
end;

end.

