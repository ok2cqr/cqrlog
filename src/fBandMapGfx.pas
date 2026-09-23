unit fBandMapGfx;

{ Graphical band map - a vertical frequency ruler with spots drawn at their
  true frequency, a live VFO cursor and click-to-QSY.

  There can be several of these windows at once: one that follows the VFO
  (Auto) and one per fixed band, all reading the same shared spot store
  (uSpotStore via uBandMapStore) through their own view. Which band a window
  shows, its zoom, viewport and filter are its own (uBandMapLayout), saved
  under BandMapGfx.<key>; BandMapWindows below creates, finds and restores
  the windows and is the only thing the rest of the application talks to.

  The text band map (fBandMap) is untouched and stays a singleton. Not
  implemented here on purpose: xplanet export and bandmap.csv persistence. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ExtCtrls, StdCtrls, Buttons,
  ComCtrls, Menus, Types, uBandMapStore, uBandMapLayout, uLogCheckQueue;

type
  { What was drawn where, rebuilt at the end of every paint. Call/Mode/Freq are
    copied BY VALUE - the poll timer can expire and re-sort the store between
    the paint that produced the layout and the double click that consumes it,
    and an index into the store would then address a different station. }
  TSpotHit = record
    R    : TRect;
    Call : String[30];
    Mode : String[10];
    Freq : Double
  end;

  { TfrmBandMapGfx }

  TfrmBandMapGfx = class(TForm)
    btnMenu: TSpeedButton;
    popMenu: TPopupMenu;
    pumMarkCq: TMenuItem;
    pumGotoCq: TMenuItem;
    pumClearCq: TMenuItem;
    pumSep1: TMenuItem;
    pumFilter: TMenuItem;
    pumClearMap: TMenuItem;
    pumSep2: TMenuItem;
    pumHelp: TMenuItem;
    pumBand: TMenuItem;
    pumOpenMap: TMenuItem;
    cmbSpan: TComboBox;
    pnlPlot: TPanel;
    pnlTop: TPanel;
    sbStatus: TStatusBar;
    tmrPoll: TTimer;
    procedure pumClearMapClick(Sender: TObject);
    procedure btnMenuClick(Sender: TObject);
    procedure pumMarkCqClick(Sender: TObject);
    procedure pumGotoCqClick(Sender: TObject);
    procedure pumClearCqClick(Sender: TObject);
    procedure pumFilterClick(Sender: TObject);
    procedure pumHelpClick(Sender: TObject);
    procedure pumBandChoiceClick(Sender: TObject);
    procedure pumOpenMapChoiceClick(Sender: TObject);
    procedure cmbSpanChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure tmrPollTimer(Sender: TObject);
  private
    FPaintBox  : TPaintBox;
    FHits      : array of TSpotHit;

    FView      : TBandMapStore;     //this window's view of the shared store
    FInst      : TBandMapInstance;  //choice, viewport and filter, as saved
    FTitleBand : String;            //band named in the caption right now
    FStandInFor: String;            //saved key this Auto window replaces ('' = none)

    FSpanIndex : Integer;
    FSpanKHz   : Integer;   //total visible span in kHz
    FCenterKHz : Double;    //sticky viewport centre
    FVfoKHz     : Double;   //0 = no frequency from anywhere
    FVfoBand    : String;
    FVfoMode    : String;
    FVfoFromQso : Boolean;  //frequency came from New QSO, not from the radio
    FCqKHz     : Double;    //0 = no CQ frequency marked; session only
    FCqMode    : String;
    FDirty     : Boolean;
    FLastMouse : TPoint;

    //dragging the map up and down. FManualPan stops the viewport chasing the
    //radio until the radio leaves the visible slice altogether.
    FDragArmed   : Boolean; //button is down, may still turn out to be a click
    FDragging    : Boolean; //moved past the threshold, this really is a drag
    FDragStartY  : Integer;
    FDragStartKHz: Double;
    FManualPan   : Boolean;

    //display filters, re-read from the ini by LoadSettings
    FOnlyCurrBand : Boolean;
    FOnlyCurrMode : Boolean;
    //[BandMap] ShowMembership: club labels after the call. FMembershipGen is
    //the cache generation the last paint saw; a new answer means a repaint
    FShowMembership : Boolean;
    FMembershipGen  : Integer;

    //per paint metrics
    FRowH      : Integer;
    FRulerW    : Integer;
    FPlotTop   : Integer;
    FPlotH     : Integer;
    FTopKHz    : Double;
    FPixPerKHz : Double;

    function  FreqToY(AFreq : Double) : Integer;
    function  YToFreq(AY : Integer) : Double;
    procedure ApplyVfo(const ABand : String; AFreqKHz : Double;
                       const AMode : String; AFromQso : Boolean);
    procedure UseNewQsoFreq;
    procedure EnsureCenter;
    function  BandLimits(AFreqKHz : Double; out ALoKHz, AHiKHz : Double) : Boolean;
    procedure ClampToBand;
    procedure SetSpanIndex(AIndex : Integer);
    procedure ParkFocus;
    function  HitTest(AX, AY : Integer; out AHit : TSpotHit) : Boolean;
    function  SpotVisible(const ASpot : TGfxSpot) : Boolean;
    function  IsWorked(const ACall, ABand, AMode, ALastDate, ALastTime : String) : Boolean;
    function  MembershipLabel(const ACall, ADate : String) : String;
    procedure UpdateFilterIndicator;
    function  GlobalRuleText : String;
    function  ShownBand : String;
    function  BandLimitsOf(const ABand : String; out ALoKHz, AHiKHz : Double) : Boolean;
    procedure UpdateTitle;

    procedure DrawOutOfBand(c : TCanvas);
    procedure DrawRuler(c : TCanvas);
    procedure DrawSpots(c : TCanvas);
    procedure DrawCqMarker(c : TCanvas);
    procedure DrawVfoCursor(c : TCanvas);

    procedure PaintBoxPaint(Sender: TObject);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
                                Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
                              Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxDblClick(Sender: TObject);
    procedure PaintBoxWheelUp(Sender: TObject; Shift: TShiftState;
                              MousePos: TPoint; var Handled: Boolean);
    procedure PaintBoxWheelDown(Sender: TObject; Shift: TShiftState;
                                MousePos: TPoint; var Handled: Boolean);
  public
    constructor CreateInstance(const AChoice : TBandMapChoice);
    destructor  Destroy; override;
    procedure LoadSettings;
    //viewport and filter to the ini; the window position goes with FormClose
    procedure SaveInstanceSettings;
    //fed from TfrmTRXControl.SynTRX, main thread, freq in kHz (txlo corrected)
    procedure SetVfo(const ABand : String; AFreqKHz : Double; const AMode : String);
    function  Choice : TBandMapChoice;
    //M > Band: this window shows another band from now on. Its ID follows
    //the choice, so the old settings are saved and the new ones read.
    procedure SetChoice(const AChoice : TBandMapChoice);
  end;

  PBandMapChoice = ^TBandMapChoice;

  { All open graphical band maps. Windows are created here and owned by
    nobody (Owner = nil) so that their streamed name cannot collide in
    Application; they free themselves on close and tell the manager. }
  TBandMapWindows = class
    private
      FList         : TList;
      FShuttingDown : Boolean;
      FOnChanged    : TNotifyEvent;
      FChecks       : TLogCheckQueue;
      FChecker      : TThread;      //answers FChecks into the log cache
      function  EnabledBands : TStringArray;
      procedure Changed;
    public
      constructor Create;
      destructor  Destroy; override;
      function  Count : Integer;
      function  Item(AIndex : Integer) : TfrmBandMapGfx;
      function  Find(const AChoice : TBandMapChoice) : TfrmBandMapGfx;
      //an open window is brought to the front, otherwise one is created
      function  Open(const AChoice : TBandMapChoice) : TfrmBandMapGfx;
      procedure Detach(AWindow : TfrmBandMapGfx);
      procedure SetVfo(const ABand : String; AFreqKHz : Double; const AMode : String);
      procedure ReloadSettings;
      procedure BringAllToFront;
      //[BandMapGfx] Open from what is open right now
      procedure SaveOpenList;
      //after the log is open: migrate the single old window, reopen the list
      procedure Restore;
      //application exit or log switch: the list first, then every window
      procedure CloseAll;
      { Fills AParent with "Auto (follow VFO)", a separator and every band
        enabled in Preferences > Bands; each item carries its choice key in
        Hint. With ACurrent = nil the open choices are checked (New QSO menu);
        otherwise ACurrent^ is checked and other open ones say so (M > Band). }
      procedure FillChoiceMenu(AParent : TMenuItem; AOnClick : TNotifyEvent;
                               ACurrent : PBandMapChoice);
      //a window met a station the log cache does not know: the thread looks
      //it up, the window shows the spot until then
      procedure RequestLogCheck(const ACall, ABand, AMode, ALastDate, ALastTime : String);
      //the same for the club membership of a heard station on a day
      procedure RequestMembership(const ACall, ADate : String);
      //a window opened or closed: menus showing the open choices redraw
      property OnChanged : TNotifyEvent read FOnChanged write FOnChanged;
  end;

var
  BandMapWindows : TBandMapWindows;

implementation
{$R *.lfm}

uses Math, LCLType, uColorMemo, dUtils, uMyIni, dData, fNewQSO, fTRXControl,
     fBandMapGfxFilter, uDebugLog;

type
  { One thread for all windows. Each question is one query through
    dmData.RbnLogCache, which serialises the database access itself (the RBN
    monitor thread uses the same path). A failed query (log being switched,
    connection dropped) is logged and skipped; the window asks again on a
    later tick if the station is still there. }
  TLogCheckThread = class(TThread)
    private
      FQueue : TLogCheckQueue;
    protected
      procedure Execute; override;
    public
      constructor Create(AQueue : TLogCheckQueue);
  end;

  { cqrini seen through the model's store interface }
  TCqrIniStore = class(TBandMapSettingsStore)
    function  ReadString(const Section, Key, Default : String; ALocal : Boolean = False) : String; override;
    procedure WriteString(const Section, Key, Value : String; ALocal : Boolean = False); override;
  end;

var
  IniStore : TCqrIniStore;

function TCqrIniStore.ReadString(const Section, Key, Default : String; ALocal : Boolean) : String;
begin
  Result := cqrini.ReadString(Section, Key, Default, ALocal)
end;

procedure TCqrIniStore.WriteString(const Section, Key, Value : String; ALocal : Boolean);
begin
  cqrini.WriteString(Section, Key, Value, ALocal)
end;

const
  //the wide steps are for bands a 200 kHz view cannot cover - 20 m is 350 kHz,
  //2 m is 2 MHz
  cSpans : array[0..15] of Integer = (2,5,10,20,40,50,60,70,80,90,
                                      100,200,300,400,500,600);
  cDefaultSpanIndex = 3; //20 kHz

  //ruler label steps in kHz, smallest first
  cRulerSteps : array[0..11] of Double = (0.1,0.2,0.5,1,2,5,10,20,50,100,200,500);

  //how far the viewport lets the VFO drift before it re-centres. 0.5 = the
  //central half of the span, so tuning in 10 Hz steps never moves the ruler.
  cDeadZoneFrac = 0.5;

  //give up displacing a label after this many rows and count it as overflow
  cMaxLeaderRows = 4;

  //how far past a band edge the ruler may reach. Beyond that there is nothing
  //to show, so the viewport slides back instead of wasting half the window.
  cBandEdgeMarginKHz = 5;

  //below this the press is a click (or half a double click), not a drag
  cDragThresholdPx = 4;

  //U+25BC, down pointing triangle, so the M button reads as a menu.
  //Spelled out as UTF-8 bytes rather than pasted in, so the caption cannot
  //depend on how the compiler treats this file's encoding.
  cMenuArrow = ' '#$E2#$96#$BC;

  //how far an aged spot is blended towards the background, per AgeStep
  cAgeBlend : array[0..2] of Byte = (0,40,70);


{ blends AFrom towards ATo by APct percent. Used instead of the text band map's
  IncColor, which lightens towards white and so makes old spots MORE prominent
  on a dark theme. }
function BlendColor(AFrom, ATo : TColor; APct : Byte) : TColor;
var
  rf,gf,bf,rt,gt,bt : Byte;
begin
  RedGreenBlue(ColorToRGB(AFrom),rf,gf,bf);
  RedGreenBlue(ColorToRGB(ATo),rt,gt,bt);
  Result := RGBToColor(rf+(Integer(rt)-rf)*APct div 100,
                       gf+(Integer(gt)-gf)*APct div 100,
                       bf+(Integer(bt)-bf)*APct div 100)
end;

function VfoAccent : TColor;
begin
  if dmUtils.DarkThemeActive then
    Result := RGBToColor(80,80,255)
  else
    Result := RGBToColor(0,0,208)
end;

function CqAccent : TColor;
begin
  if dmUtils.DarkThemeActive then
    Result := RGBToColor(96,255,96)
  else
    Result := RGBToColor(16,127,16)
end;

{ TfrmBandMapGfx }

constructor TfrmBandMapGfx.CreateInstance(const AChoice : TBandMapChoice);
begin
  FInst := Default(TBandMapInstance);
  FInst.Choice := AChoice;
  inherited Create(nil);
  //one name per choice, so a debug print or the LCL can tell them apart
  Name := InstanceComponentName(AChoice)
end;

destructor TfrmBandMapGfx.Destroy;
begin
  FreeAndNil(FView);
  inherited Destroy
end;

function TfrmBandMapGfx.Choice : TBandMapChoice;
begin
  Result := FInst.Choice
end;

procedure TfrmBandMapGfx.FormCreate(Sender: TObject);
var
  i : Integer;
begin
  FView := TBandMapStore.Create;
  //no cqrini/dmData access here - this runs from Application.CreateForm, before
  //the database (and therefore cqrini) exists. Settings live in LoadSettings.
  {$IFNDEF LCLCocoa}
  DoubleBuffered := True;
  {$ENDIF}

  FSpanIndex := cDefaultSpanIndex;
  FSpanKHz   := cSpans[FSpanIndex];
  FCenterKHz := 0;
  FVfoKHz    := 0;
  FCqKHz     := 0;
  FDirty     := True;

  cmbSpan.Items.BeginUpdate;
  try
    cmbSpan.Items.Clear;
    for i:=0 to High(cSpans) do
      cmbSpan.Items.Add(IntToStr(cSpans[i])+' kHz')
  finally
    cmbSpan.Items.EndUpdate
  end;
  cmbSpan.ItemIndex := FSpanIndex;

  //owned by pnlPlot, not by the form, so LoadFontSettings never reaches it
  FPaintBox        := TPaintBox.Create(pnlPlot);
  FPaintBox.Parent := pnlPlot;
  FPaintBox.Align  := alClient;
  FPaintBox.OnPaint          := @PaintBoxPaint;
  FPaintBox.OnMouseDown      := @PaintBoxMouseDown;
  FPaintBox.OnMouseMove      := @PaintBoxMouseMove;
  FPaintBox.OnMouseUp        := @PaintBoxMouseUp;
  FPaintBox.OnDblClick       := @PaintBoxDblClick;
  FPaintBox.OnMouseWheelUp   := @PaintBoxWheelUp;
  FPaintBox.OnMouseWheelDown := @PaintBoxWheelDown;

  tmrPoll.Interval := 500
end;

procedure TfrmBandMapGfx.LoadSettings;
var
  i,sp : Integer;
  f    : TFont;
begin
  dmUtils.LoadFontSettings(self);

  //aging is shared with the text band map on purpose - one place to tune it
  FView.FirstAgingSec  := cqrini.ReadInteger('BandMap','FirstAging',5)*60;
  FView.SecondAgingSec := cqrini.ReadInteger('BandMap','SecondAging',8)*60;
  FView.DeleteAfterSec := cqrini.ReadInteger('BandMap','Disep',12)*60;
  BandMapStoreDebug := dmData.DebugLevel >= 1;

  FInst := LoadInstance(IniStore, FInst.Choice, cSpans[cDefaultSpanIndex]);

  //"only the active band" is the text band map's option and only means
  //something while following the radio; a fixed window is its band
  FOnlyCurrBand := FInst.Choice.IsAuto and cqrini.ReadBool('BandMap','OnlyActiveBand',False);
  FShowMembership := cqrini.ReadBool('BandMap','ShowMembership',False);
  //a fixed window wants its band only; the Auto window keeps every band so
  //that following the radio across bands throws nothing away
  if FInst.Choice.IsAuto then
    FView.Band := ''
  else
    FView.Band := FInst.Choice.Band;
  FOnlyCurrMode := FInst.OnlyCurrMode;

  //one QSO rule, never two stacked: the shared [BandMapFilter] keys of the
  //text band map, this window's own copy, or none
  FView.DateFilter := bmdShowAll;
  case FInst.QsoRule of
    qrGlobal :
      begin
        if cqrini.ReadBool('BandMapFilter','NoWkdHour',False) then
          FView.DateFilter := bmdLastHours;
        if cqrini.ReadBool('BandMapFilter','NoWkdDate',False) then
          FView.DateFilter := bmdSinceDateTime;
        FView.LastHours := cqrini.ReadInteger('BandMapFilter','LastHours',48);
        FView.SinceDate := cqrini.ReadString('BandMapFilter','LastDate','');
        FView.SinceTime := cqrini.ReadString('BandMapFilter','LastTime','')
      end;
    qrCustom :
      begin
        if FInst.UseLastHours then
          FView.DateFilter := bmdLastHours
        else
          FView.DateFilter := bmdSinceDateTime;
        FView.LastHours := FInst.LastHours;
        FView.SinceDate := FInst.SinceDate;
        FView.SinceTime := FInst.SinceTime
      end
  end;
  FView.OnlyLoTW := FInst.OnlyLoTW;
  FView.OnlyEQSL := FInst.OnlyEQSL;
  FView.OnWorkedCheck := @IsWorked;

  UpdateFilterIndicator;

  sp := FInst.SpanKHz;
  FSpanIndex := cDefaultSpanIndex;
  for i:=0 to High(cSpans) do
  begin
    if cSpans[i] = sp then
      FSpanIndex := i
  end;
  FSpanKHz := cSpans[FSpanIndex];
  if cmbSpan.Items.Count > FSpanIndex then
    cmbSpan.ItemIndex := FSpanIndex;

  f := TFont.Create;
  try
    f.Name := cqrini.ReadString('BandMap',dmUtils.PlatformKey('BandFont'),cDefaultMonoFont);
    f.Size := cqrini.ReadInteger('BandMap',dmUtils.PlatformKey('FontSize'),8);
    //a config carried over from another platform can name a font that does not
    //exist here; the fallback keeps the text metrics (and the layout) sane
    if Screen.Fonts.IndexOf(f.Name) < 0 then
      f.Name := cDefaultMonoFont;
    FPaintBox.Font.Assign(f)
  finally
    f.Free
  end;

  //the saved viewport, once: later LoadSettings calls (filter changed) must
  //not yank the map back
  if (FCenterKHz <= 0) and (FInst.CenterKHz > 0) then
    FCenterKHz := FInst.CenterKHz;

  UpdateTitle;
  FDirty := True;
  FPaintBox.Invalidate
end;

procedure TfrmBandMapGfx.SaveInstanceSettings;
begin
  if dmData.DBName = '' then
    exit; //no log open, cqrini would write into nothing
  FInst.SpanKHz   := FSpanKHz;
  FInst.CenterKHz := FCenterKHz;
  SaveInstance(IniStore, FInst)
end;

procedure TfrmBandMapGfx.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPosAs(Self, InstanceSection(FInst.Choice), True);
  LoadSettings;
  FManualPan := False; //reopening always starts following the radio again
  if FVfoKHz <= 0 then
    UseNewQsoFreq; //open on the band the operator is actually on
  EnsureCenter;
  tmrPoll.Enabled      := True;
  FDirty := True;
  FPaintBox.Invalidate
end;

procedure TfrmBandMapGfx.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  tmrPoll.Enabled := False;
  dmUtils.SaveWindowPosAs(Self, InstanceSection(FInst.Choice));
  SaveInstanceSettings;
  //the shared store keeps collecting while no window is open, so opening one
  //again shows what arrived meanwhile
  CloseAction := caFree;
  if Assigned(BandMapWindows) then
    BandMapWindows.Detach(Self)
end;

procedure TfrmBandMapGfx.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    Key := 0
  end
end;

procedure TfrmBandMapGfx.tmrPollTimer(Sender: TObject);
var
  t0 : TDateTime;
  ms : Integer;
begin
  //With no rig model configured at all SynTRX never runs (its timer is only
  //enabled once a rig initialises), so nothing would ever call SetVfo. Keep
  //following the New QSO frequency from here as long as it is the source.
  if (FVfoKHz <= 0) or FVfoFromQso then
    UseNewQsoFreq;

  t0 := Now;
  if FView.Poll(Now, dmUtils.GetDateTime(0)) then
    FDirty := True;
  //a membership answer arrived (or the club tables changed): the labels differ
  if FShowMembership and (FMembershipGen <> dmData.RbnLogCache.MembershipGeneration) then
    FDirty := True;
  ms := Round((Now - t0) * 86400000);
  if ms > 200 then
    DbgLog('BMAP', Name + ': Poll took ' + IntToStr(ms) + ' ms, spots ' + IntToStr(FView.Count));
  if FDirty then
  begin
    FDirty := False;
    FPaintBox.Invalidate
  end
end;

procedure TfrmBandMapGfx.ApplyVfo(const ABand : String; AFreqKHz : Double;
                                  const AMode : String; AFromQso : Boolean);
var
  halfDead : Double;
  outside  : Boolean = False;
begin
  if (AFreqKHz = FVfoKHz) and (ABand = FVfoBand) and (AMode = FVfoMode)
     and (AFromQso = FVfoFromQso) then
    exit; //parked radio must not cost a single repaint

  //a fixed window shows its band whatever the radio does; the cursor still
  //follows so it can be drawn when the radio comes to this band
  if (AFreqKHz > 0) and (FInst.Choice.IsAuto or (ABand = FInst.Choice.Band)) then
  begin
    if FManualPan then
    begin
      //hands off while the operator is looking somewhere else, until the radio
      //tunes right out of the slice on screen
      if (FPixPerKHz > 0) then
        outside := (AFreqKHz < FTopKHz) or (AFreqKHz > FTopKHz+FSpanKHz)
      else
        outside := Abs(AFreqKHz-FCenterKHz) > FSpanKHz/2
    end
    else begin
      halfDead := FSpanKHz*cDeadZoneFrac/2;
      outside  := Abs(AFreqKHz-FCenterKHz) > halfDead
    end;

    if (FCenterKHz <= 0) or (ABand <> FVfoBand) or outside then
    begin
      FCenterKHz := AFreqKHz;
      FManualPan := False
    end
  end;

  FVfoKHz     := AFreqKHz;
  FVfoBand    := ABand;
  FVfoMode    := AMode;
  FVfoFromQso := AFromQso;
  UpdateTitle;
  FDirty      := True //no Invalidate here, the poll timer coalesces
end;

{ the band this window is on: its own for a fixed window, the radio's for Auto }
function TfrmBandMapGfx.ShownBand : String;
begin
  if FInst.Choice.IsAuto then
    Result := FVfoBand
  else
    Result := FInst.Choice.Band
end;

procedure TfrmBandMapGfx.UpdateTitle;
begin
  if (Caption <> '') and (FTitleBand = ShownBand) then
    exit;
  FTitleBand := ShownBand;
  Caption := ChoiceTitle(FInst.Choice, FTitleBand)
end;

{ Edges of the band named ABand (a code from the band table, '20M'), in kHz.
  False when the table does not have it, or has not been read yet. }
function TfrmBandMapGfx.BandLimitsOf(const ABand : String; out ALoKHz, AHiKHz : Double) : Boolean;
var
  i : Integer;
begin
  Result := False;
  ALoKHz := 0;
  AHiKHz := 0;
  for i:=0 to cMaxBandsCount-1 do
  begin
    if (dmUtils.BandFreq[i].b_end > 0) and (dmUtils.BandFreq[i].band = ABand) then
    begin
      ALoKHz := dmUtils.BandFreq[i].b_begin*1000;
      AHiKHz := dmUtils.BandFreq[i].b_end*1000;
      exit(True)
    end
  end
end;

{ Frequency typed into the New QSO window, used whenever the radio has none.
  Deliberately NOT gated on [BandMap] UseNewQSOFreqMode: for the text band map
  that option only decides whether the "you are here" marker moves, but here the
  frequency picks the whole visible part of the band - without it the window is
  stuck on whatever it happened to start at.
  MyStrToFloat, not TryStrToFloat, so a comma decimal separator cannot break it. }
procedure TfrmBandMapGfx.UseNewQsoFreq;
var
  f : Double = 0;
  s : String;
  i : Integer;
begin
  //Same idea as dmUtils.MyStrToFloat but without the exception - this runs
  //twice a second, also while a frequency is only half typed. Both separators
  //are normalised, so it copes with a comma typed under a dot locale too
  //(MyStrToFloat only handles the other direction).
  s := Trim(frmNewQSO.cmbFreq.Text);
  for i:=1 to Length(s) do
  begin
    if (s[i] = '.') or (s[i] = ',') then
      s[i] := FormatSettings.DecimalSeparator
  end;
  if not TryStrToFloat(s,f) then
    f := 0;
  f := f*1000;

  if f > 0 then
    ApplyVfo(dmUtils.GetBandFromFreq(frmNewQSO.cmbFreq.Text),f,frmNewQSO.cmbMode.Text,True)
  else
    ApplyVfo('',0,'',True)
end;

procedure TfrmBandMapGfx.SetVfo(const ABand : String; AFreqKHz : Double; const AMode : String);
begin
  //SynTRX reports 0 when no radio answers. Fall straight back to the New QSO
  //frequency instead of leaving the window parked on the wrong band.
  if AFreqKHz > 0 then
    ApplyVfo(ABand,AFreqKHz,AMode,False)
  else
    UseNewQsoFreq
end;

procedure TfrmBandMapGfx.EnsureCenter;
var
  lo,hi : Double;
begin
  if FCenterKHz > 0 then
    exit;
  if not FInst.Choice.IsAuto then
  begin
    //the fixed band, whatever the radio is doing: the saved centre if it is
    //still inside, otherwise the middle of the band
    if BandLimitsOf(FInst.Choice.Band,lo,hi) then
    begin
      if (FInst.CenterKHz >= lo) and (FInst.CenterKHz <= hi) then
        FCenterKHz := FInst.CenterKHz
      else
        FCenterKHz := (lo+hi)/2;
      exit
    end
  end;
  if FVfoKHz > 0 then
    FCenterKHz := FVfoKHz
  else
    FCenterKHz := 14020 //nothing to go by at all
end;

{ Edges of the band AFreqKHz falls into, in kHz. False when it is in no band at
  all, or before the band table has been read from the database. }
function TfrmBandMapGfx.BandLimits(AFreqKHz : Double; out ALoKHz, AHiKHz : Double) : Boolean;
var
  i : Integer;
  f : Currency;
begin
  Result := False;
  ALoKHz := 0;
  AHiKHz := 0;
  f      := AFreqKHz/1000; //the band table is in MHz

  for i:=0 to cMaxBandsCount-1 do
  begin
    //unused slots are all zero, hence the b_end test
    if (dmUtils.BandFreq[i].b_end > 0) and (f >= dmUtils.BandFreq[i].b_begin)
       and (f <= dmUtils.BandFreq[i].b_end) then
    begin
      ALoKHz := dmUtils.BandFreq[i].b_begin*1000;
      AHiKHz := dmUtils.BandFreq[i].b_end*1000;
      exit(True)
    end
  end
end;

{ Keeps the visible slice inside the band. Sitting on 1.800 with a wide span
  would otherwise fill the top half of the window with 1.7 MHz, where no
  station can ever appear. }
procedure TfrmBandMapGfx.ClampToBand;
var
  lo,hi,ref : Double;
begin
  if FInst.Choice.IsAuto then
  begin
    //anchor on the radio, not on the possibly dragged-away centre, so panning
    //cannot wander off into the next band
    ref := FVfoKHz;
    if ref <= 0 then
      ref := FCenterKHz;
    if not BandLimits(ref,lo,hi) then
      exit //outside every band, or no band table yet - leave the view alone
  end
  else begin
    if not BandLimitsOf(FInst.Choice.Band,lo,hi) then
      exit
  end;

  lo := lo - cBandEdgeMarginKHz;
  hi := hi + cBandEdgeMarginKHz;

  if hi-lo <= FSpanKHz then
    //zoomed out wider than the whole band, so centre the band instead
    FTopKHz := (lo+hi)/2 - FSpanKHz/2
  else begin
    if FTopKHz < lo then
      FTopKHz := lo;
    if FTopKHz+FSpanKHz > hi then
      FTopKHz := hi-FSpanKHz
  end
end;

function TfrmBandMapGfx.FreqToY(AFreq : Double) : Integer;
begin
  Result := FPlotTop + Round((AFreq-FTopKHz)*FPixPerKHz)
end;

function TfrmBandMapGfx.YToFreq(AY : Integer) : Double;
begin
  if FPixPerKHz <= 0 then
    Result := 0
  else
    Result := FTopKHz + (AY-FPlotTop)/FPixPerKHz
end;

procedure TfrmBandMapGfx.ParkFocus;
begin
  //keeps KeyPreview routing Esc to FormKeyUp, same as the text band map
  ActiveControl := nil
end;

procedure TfrmBandMapGfx.SetSpanIndex(AIndex : Integer);
begin
  if AIndex < 0 then
    AIndex := 0;
  if AIndex > High(cSpans) then
    AIndex := High(cSpans);
  if AIndex = FSpanIndex then
    exit;

  FSpanIndex := AIndex;
  FSpanKHz   := cSpans[FSpanIndex];
  if cmbSpan.ItemIndex <> FSpanIndex then
    cmbSpan.ItemIndex := FSpanIndex;
  //zoom around wherever the operator is looking, not back at the radio
  if (FVfoKHz > 0) and (not FManualPan) and (FInst.Choice.IsAuto or (FVfoBand = FInst.Choice.Band)) then
    FCenterKHz := FVfoKHz;

  SaveInstanceSettings;
  FDirty := True;
  FPaintBox.Invalidate;
  ParkFocus
end;

procedure TfrmBandMapGfx.cmbSpanChange(Sender: TObject);
begin
  SetSpanIndex(cmbSpan.ItemIndex)
end;

procedure TfrmBandMapGfx.btnMenuClick(Sender: TObject);
var
  p : TPoint;
begin
  //grey out what makes no sense right now instead of failing silently later
  pumMarkCq.Enabled  := FVfoKHz > 0;
  pumGotoCq.Enabled  := FCqKHz > 0;
  pumClearCq.Enabled := FCqKHz > 0;
  if FCqKHz > 0 then
  begin
    pumGotoCq.Caption  := 'Go back to my CQ frequency ('+FormatFloat('0.00',FCqKHz)+' kHz)';
    pumClearCq.Caption := 'Forget my CQ frequency ('+FormatFloat('0.00',FCqKHz)+' kHz)'
  end
  else begin
    pumGotoCq.Caption  := 'Go back to my CQ frequency';
    pumClearCq.Caption := 'Forget my CQ frequency'
  end;

  BandMapWindows.FillChoiceMenu(pumBand, @pumBandChoiceClick, @FInst.Choice);
  BandMapWindows.FillChoiceMenu(pumOpenMap, @pumOpenMapChoiceClick, nil);

  //drop the menu just below the button
  p := btnMenu.ClientToScreen(Point(0,btnMenu.Height));
  popMenu.PopUp(p.X,p.Y);
  ParkFocus
end;

procedure TfrmBandMapGfx.pumMarkCqClick(Sender: TObject);
begin
  if FVfoKHz <= 0 then
  begin
    sbStatus.Panels[0].Text := 'No radio frequency to mark';
    exit
  end;
  FCqKHz  := FVfoKHz;
  FCqMode := FVfoMode;
  FDirty  := True;
  FPaintBox.Invalidate;
  ParkFocus
end;

procedure TfrmBandMapGfx.pumGotoCqClick(Sender: TObject);
begin
  if FCqKHz <= 0 then
    exit;
  //QSY only - there is no call to load, the New QSO fields must be left alone
  if frmTRXControl.GetFreqMHz > 0 then
    frmTRXControl.SetModeFreq(FCqMode,FloatToStr(FCqKHz))
  else
    sbStatus.Panels[0].Text := 'No radio connected';
  ParkFocus
end;

procedure TfrmBandMapGfx.pumClearCqClick(Sender: TObject);
begin
  FCqKHz := 0;
  FDirty := True;
  FPaintBox.Invalidate;
  ParkFocus
end;

{ runs on the GUI thread from TBandMapStore.Poll, so it never queries the
  database: the shared cache answers or the log check thread is asked and the
  spot stays visible until the answer is in }
function TfrmBandMapGfx.IsWorked(const ACall, ABand, AMode,
                                 ALastDate, ALastTime : String) : Boolean;
begin
  if dmData.RbnLogCache.TryWorkedAfter(ACall,ABand,AMode,ALastDate,ALastTime,Result) then
    exit;
  BandMapWindows.RequestLogCheck(ACall,ABand,AMode,ALastDate,ALastTime);
  Result := False
end;

{ GUI thread, from DrawSpots: the cache answers or the log check thread is
  asked and the label appears on a later paint }
function TfrmBandMapGfx.MembershipLabel(const ACall, ADate : String) : String;
begin
  if dmData.RbnLogCache.TryMembership(ACall, ADate, Result) then
    exit;
  BandMapWindows.RequestMembership(ACall, ADate);
  Result := ''
end;

{ the shared [BandMapFilter] rule of the text band map, in a few words }
function TfrmBandMapGfx.GlobalRuleText : String;
begin
  if cqrini.ReadBool('BandMapFilter','NoWkdDate',False) then
    Result := 'worked after '+cqrini.ReadString('BandMapFilter','LastDate','')+' '+
              cqrini.ReadString('BandMapFilter','LastTime','')+' hidden'
  else if cqrini.ReadBool('BandMapFilter','NoWkdHour',False) then
    Result := 'worked in last '+IntToStr(cqrini.ReadInteger('BandMapFilter','LastHours',48))+' h hidden'
  else
    Result := 'worked stations shown'
end;

procedure TfrmBandMapGfx.UpdateFilterIndicator;
var
  filtered : Boolean;
  rule     : String;
begin
  filtered := FOnlyCurrBand or FOnlyCurrMode or FView.OnlyLoTW
              or FView.OnlyEQSL or (FView.DateFilter <> bmdShowAll);

  //the rule in force, in a few words, always visible; the details are in
  //the Filter dialog
  case FInst.QsoRule of
    qrGlobal : rule := 'QSO: global';
    qrNone   : rule := 'QSO: all';
    else       rule := 'QSO: own'
  end;
  case FView.DateFilter of
    bmdLastHours     : rule := rule+' '+IntToStr(FView.LastHours)+' h';
    bmdSinceDateTime : rule := rule+' since '+FView.SinceDate
  end;
  if FView.OnlyLoTW then rule := rule+' | LoTW';
  if FView.OnlyEQSL then rule := rule+' | eQSL';
  if FOnlyCurrMode then rule := rule+' | mode';
  if FOnlyCurrBand then rule := rule+' | band';
  sbStatus.Panels[1].Text := rule;

  //Spots disappearing for no visible reason is confusing, and the filter now
  //lives inside the menu where it cannot be seen. So the state has to show on
  //the button itself, otherwise it takes two clicks to find out.
  if filtered then
  begin
    btnMenu.Caption   := 'M*'+cMenuArrow;
    pumFilter.Caption := 'Filter settings... (filter is on)'
  end
  else begin
    btnMenu.Caption   := 'M'+cMenuArrow;
    pumFilter.Caption := 'Filter settings...'
  end
end;

procedure TfrmBandMapGfx.pumFilterClick(Sender: TObject);
var
  f : TfrmBandMapGfxFilter;
begin
  f := TfrmBandMapGfxFilter.Create(nil);
  try
    f.Instance       := FInst;
    f.GlobalRuleText := GlobalRuleText;
    f.RbnContinents  := cqrini.ReadString('RBNFilter','SrcCont','');
    if f.ShowModal = mrOK then
    begin
      FInst := f.Instance;
      SaveInstanceSettings;
      //re-read: the still valid candidates are shown under the new rule at once
      LoadSettings
    end
  finally
    FreeAndNil(f)
  end;
  ParkFocus
end;

procedure TfrmBandMapGfx.pumClearMapClick(Sender: TObject);
begin
  //one store for every window, so this empties all of them
  FView.Clear;
  FDirty := True;
  FPaintBox.Invalidate;
  ParkFocus
end;

procedure TfrmBandMapGfx.pumHelpClick(Sender: TObject);
begin
  ShowHelp;
  ParkFocus
end;

procedure TfrmBandMapGfx.pumBandChoiceClick(Sender: TObject);
var
  c : TBandMapChoice;
  w : TfrmBandMapGfx;
begin
  if not ParseChoiceKey(TMenuItem(Sender).Hint, c) then
    exit;
  if SameChoice(c, FInst.Choice) then
    exit;
  //one window per choice: an existing one comes to the front, this one stays
  w := BandMapWindows.Find(c);
  if w <> nil then
  begin
    w.BringToFront;
    exit
  end;
  SetChoice(c);
  ParkFocus
end;

procedure TfrmBandMapGfx.pumOpenMapChoiceClick(Sender: TObject);
var
  c : TBandMapChoice;
begin
  if ParseChoiceKey(TMenuItem(Sender).Hint, c) then
    BandMapWindows.Open(c)
end;

procedure TfrmBandMapGfx.SetChoice(const AChoice : TBandMapChoice);
begin
  if SameChoice(AChoice, FInst.Choice) then
    exit;
  //the settings so far belong to the old choice
  SaveInstanceSettings;
  dmUtils.SaveWindowPosAs(Self, InstanceSection(FInst.Choice));
  FInst.Choice := AChoice;
  Name := InstanceComponentName(AChoice);
  //this window no longer stands in for a disabled band
  FStandInFor := '';
  //the new choice's own viewport and filter; the window stays where it is
  FCenterKHz := 0;
  FManualPan := False;
  FTitleBand := #0; //the caption changes even when the band does not
  LoadSettings;
  //following the radio again means being where the radio is, not where the
  //Auto window was left last time
  if AChoice.IsAuto and (FVfoKHz > 0) then
    FCenterKHz := FVfoKHz;
  EnsureCenter;
  SaveInstanceSettings;
  BandMapWindows.SaveOpenList;
  BandMapWindows.Changed;
  FDirty := True;
  FPaintBox.Invalidate
end;

{ band and mode are display filters, applied here rather than on the way in, so
  that following the radio across bands does not throw spots away. Mode matching
  copies the text band map: the radio reports USB/LSB/CWR, spots carry SSB/CW. }
function TfrmBandMapGfx.SpotVisible(const ASpot : TGfxSpot) : Boolean;
begin
  Result := True;

  if not FInst.Choice.IsAuto then
  begin
    if ASpot.Band <> FInst.Choice.Band then
      exit(False)
  end
  else if FOnlyCurrBand and (FVfoBand <> '') then
  begin
    if ASpot.Band <> FVfoBand then
      exit(False)
  end;

  if FOnlyCurrMode and (FVfoMode <> '') then
  begin
    if (FVfoMode = 'LSB') or (FVfoMode = 'USB') then
    begin
      if ASpot.Mode <> 'SSB' then
        exit(False)
    end
    else begin
      if (FVfoMode = 'CW') or (FVfoMode = 'CWR') then
      begin
        if (ASpot.Mode <> 'CW') and (ASpot.Mode <> 'CWR') then
          exit(False)
      end
      else begin
        if ASpot.Mode <> FVfoMode then
          exit(False)
      end
    end
  end
end;

function TfrmBandMapGfx.HitTest(AX, AY : Integer; out AHit : TSpotHit) : Boolean;
var
  i : Integer;
  r : TRect;
begin
  Result := False;
  //backwards: the last one drawn is the one on top
  for i:=Length(FHits)-1 downto 0 do
  begin
    r := FHits[i].R;
    InflateRect(r,2,2);
    if PtInRect(r,Point(AX,AY)) then
    begin
      AHit := FHits[i];
      exit(True)
    end
  end
end;

procedure TfrmBandMapGfx.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  h : TSpotHit;
begin
  //TPaintBox.OnDblClick carries no coordinates, so remember them here
  FLastMouse := Point(X,Y);

  if Button = mbLeft then
  begin
    FDragArmed    := True;
    FDragging     := False;
    FDragStartY   := Y;
    FDragStartKHz := FCenterKHz
  end;

  if HitTest(X,Y,h) then
    sbStatus.Panels[0].Text := h.Call+'   '+FormatFloat('0.00',h.Freq)+' kHz   '+h.Mode
  else
    sbStatus.Panels[0].Text := FormatFloat('0.00',YToFreq(Y))+' kHz'
end;

procedure TfrmBandMapGfx.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if (not FDragArmed) or (FPixPerKHz <= 0) then
    exit;

  //a double click wobbles by a pixel or two; only past the threshold is it a drag
  if (not FDragging) and (Abs(Y-FDragStartY) < cDragThresholdPx) then
    exit;

  if not FDragging then
  begin
    FDragging          := True;
    FManualPan         := True;
    FPaintBox.Cursor   := crSizeNS
  end;

  //grab and drag the ruler: content follows the mouse, so pulling down shows
  //lower frequencies. ClampToBand still keeps it inside the band at paint time.
  FCenterKHz := FDragStartKHz - (Y-FDragStartY)/FPixPerKHz;
  FDirty     := False;
  FPaintBox.Invalidate //repaint now, waiting for the timer would feel sticky
end;

procedure TfrmBandMapGfx.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FDragging then
    FPaintBox.Cursor := crDefault;
  FDragArmed := False;
  FDragging  := False
end;

procedure TfrmBandMapGfx.PaintBoxDblClick(Sender: TObject);
var
  h : TSpotHit;
begin
  if HitTest(FLastMouse.X,FLastMouse.Y,h) then
  begin
    //loads the call into New QSO and QSYs the radio, exactly like the text band map
    frmNewQSO.NewQSOFromSpot(h.Call,FloatToStr(h.Freq),h.Mode);
    exit
  end;

  //nothing under the cursor: clicking the CQ line takes the radio back there.
  //QSY only - there is no call to load and the New QSO fields must be left alone.
  if (FCqKHz > 0) and (Abs(FLastMouse.Y-FreqToY(FCqKHz)) <= 4) then
  begin
    if frmTRXControl.GetFreqMHz > 0 then
      frmTRXControl.SetModeFreq(FCqMode,FloatToStr(FCqKHz))
    else
      sbStatus.Panels[0].Text := 'No radio connected'
  end
end;

procedure TfrmBandMapGfx.PaintBoxWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  Handled := True;
  SetSpanIndex(FSpanIndex-1)
end;

procedure TfrmBandMapGfx.PaintBoxWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  Handled := True;
  SetSpanIndex(FSpanIndex+1)
end;

procedure TfrmBandMapGfx.PaintBoxPaint(Sender: TObject);
var
  c : TCanvas;
begin
  c := FPaintBox.Canvas;
  c.Font.Assign(FPaintBox.Font);

  FRowH    := c.TextHeight('Wg')+2;
  FPlotTop := FRowH div 2 + 2;
  FPlotH   := FPaintBox.Height - 2*FPlotTop;
  FRulerW  := c.TextWidth('88888.8')+14;

  c.Brush.Style := bsSolid;
  c.Brush.Color := clWindow;
  c.FillRect(0,0,FPaintBox.Width,FPaintBox.Height);

  SetLength(FHits,0);

  if (FPlotH < 20) or (FSpanKHz < 1) then
    exit;

  EnsureCenter;
  if FCenterKHz <= 0 then
    exit;

  FTopKHz := FCenterKHz - FSpanKHz/2;
  ClampToBand;
  FPixPerKHz := FPlotH/FSpanKHz;

  //now that the actual frequencies are known, size the gutter to fit them -
  //144000.0 needs noticeably more room than 3500.0
  FRulerW := c.TextWidth(FormatFloat('0.0',FTopKHz+FSpanKHz))+14;

  DrawOutOfBand(c);
  DrawRuler(c);
  DrawSpots(c);
  DrawCqMarker(c);
  DrawVfoCursor(c)
end;


{ Shades the strip outside the band edges, so it is obvious why the ruler stops
  sliding there rather than looking like it got stuck. }
procedure TfrmBandMapGfx.DrawOutOfBand(c : TCanvas);
var
  lo,hi,ref : Double;
  y         : Integer;
begin
  if FInst.Choice.IsAuto then
  begin
    ref := FVfoKHz;
    if ref <= 0 then
      ref := FCenterKHz;
    if not BandLimits(ref,lo,hi) then
      exit
  end
  else begin
    //the fixed band's edges, whatever band the radio is on
    if not BandLimitsOf(FInst.Choice.Band,lo,hi) then
      exit
  end;

  c.Brush.Style := bsSolid;
  c.Brush.Color := BlendColor(clWindow,clWindowText,12);

  y := FreqToY(lo);
  if y > 0 then
    c.FillRect(FRulerW+1,0,FPaintBox.Width,y);

  y := FreqToY(hi);
  if y < FPaintBox.Height then
    c.FillRect(FRulerW+1,y,FPaintBox.Width,FPaintBox.Height)
end;

procedure TfrmBandMapGfx.DrawRuler(c : TCanvas);
var
  step,sub : Double;
  i,k,y,mp : Integer;
  fmt,s    : String;
  cTick    : TColor;
begin
  cTick := BlendColor(clWindowText,clWindow,45);

  c.Brush.Style := bsSolid;
  c.Brush.Color := clBtnFace;
  c.FillRect(0,0,FRulerW,FPaintBox.Height);

  //smallest step whose pixel pitch still fits a label - labels cannot collide
  mp   := c.TextHeight('0')+6;
  step := cRulerSteps[High(cRulerSteps)];
  for i:=0 to High(cRulerSteps) do
  begin
    if cRulerSteps[i]*FPixPerKHz >= mp then
    begin
      step := cRulerSteps[i];
      Break
    end
  end;

  c.Pen.Style := psSolid;
  c.Pen.Width := 1;

  sub := step/5;
  if sub*FPixPerKHz >= 4 then
  begin
    c.Pen.Color := BlendColor(clWindowText,clWindow,70);
    //iterate on an integer counter, never accumulate a float
    k := Ceil(FTopKHz/sub);
    while k*sub <= FTopKHz+FSpanKHz do
    begin
      y := FreqToY(k*sub);
      c.Line(FRulerW-5,y,FRulerW,y);
      Inc(k)
    end
  end;

  if step < 1 then
    fmt := '0.0'
  else
    fmt := '0';

  c.Pen.Color   := cTick;
  c.Brush.Style := bsClear;
  c.Font.Color  := clWindowText;
  k := Ceil(FTopKHz/step);
  while k*step <= FTopKHz+FSpanKHz do
  begin
    y := FreqToY(k*step);
    c.Line(FRulerW-9,y,FRulerW,y);
    s := FormatFloat(fmt,k*step);
    c.TextOut(FRulerW-11-c.TextWidth(s), y-c.TextHeight(s) div 2, s);
    Inc(k)
  end;

  c.Pen.Color := cTick;
  c.Line(FRulerW,0,FRulerW,FPaintBox.Height)
end;

procedure TfrmBandMapGfx.DrawSpots(c : TCanvas);
var
  i,n,TrueY,TextY,LastBottom,Overflow : Integer;
  TickX,LeadX,TextX : Integer;
  sp    : TGfxSpot;
  s,m   : String;
  today : String;
  r     : TRect;
  eff   : TColor;
  cLead : TColor;
begin
  //membership rows have fromdate/todate; the spots are minutes old, so the
  //day is today (UTC)
  today := FormatDateTime('yyyy-mm-dd', dmUtils.GetDateTime(0));
  if FShowMembership then
    FMembershipGen := dmData.RbnLogCache.MembershipGeneration;
  TickX      := FRulerW+2;
  LeadX      := FRulerW+12;
  TextX      := FRulerW+17;
  LastBottom := -MaxInt;
  Overflow   := 0;
  cLead      := BlendColor(clWindowText,clWindow,60);

  //the store is kept sorted by frequency, so this walks the plot top down
  for i:=0 to FView.Count-1 do
  begin
    sp := FView.Item(i);
    if (sp.Freq < FTopKHz-1) or (sp.Freq > FTopKHz+FSpanKHz+1) then
      Continue;
    if not SpotVisible(sp) then
      Continue;

    TrueY := FreqToY(sp.Freq);
    TextY := TrueY;
    //push the label down far enough to clear the one above; the marker and the
    //leader still point at the real frequency
    if TextY-FRowH div 2 < LastBottom then
      TextY := LastBottom + FRowH div 2;

    if (TextY-TrueY > cMaxLeaderRows*FRowH) or (TextY+FRowH div 2 > FPlotTop+FPlotH) then
    begin
      Inc(Overflow);
      Continue
    end;
    LastBottom := TextY + FRowH div 2;

    s := sp.Call;
    if sp.Source = gssManual then
      s := '*'+s;
    if sp.SplitInfo <> '' then
      s := s+' '+sp.SplitInfo;
    if FShowMembership then
    begin
      m := MembershipLabel(sp.Call, today);
      if m <> '' then
        s := s+' ('+m+')'
    end;

    r := Rect(TextX-2, TextY-FRowH div 2, TextX+c.TextWidth(s)+2, TextY+FRowH div 2);

    eff := clWindow;
    if ColorToRGB(sp.BgColor) <> ColorToRGB(clWindow) then
    begin
      eff := sp.BgColor;
      c.Brush.Style := bsSolid;
      c.Brush.Color := eff;
      c.FillRect(r)
    end;

    c.Brush.Style := bsSolid;
    c.Brush.Color := cLead;
    c.FillRect(TickX,TrueY-1,TickX+5,TrueY+2);

    c.Pen.Color := cLead;
    c.Pen.Style := psSolid;
    c.Pen.Width := 1;
    if TextY = TrueY then
      c.Line(TickX+5,TrueY,TextX-3,TrueY)
    else begin
      c.Line(TickX+5,TrueY,LeadX,TrueY);
      c.Line(LeadX,TrueY,TextX-3,TextY)
    end;

    c.Brush.Style := bsClear;
    c.Font.Color  := BlendColor(TcolorMemo.ReadableTextColor(sp.BaseColor,eff),
                                eff,cAgeBlend[sp.AgeStep]);
    c.TextOut(TextX, TextY-FRowH div 2+1, s);

    n := Length(FHits);
    SetLength(FHits,n+1);
    FHits[n].R    := r;
    FHits[n].Call := sp.Call;
    FHits[n].Mode := sp.Mode;
    FHits[n].Freq := sp.Freq
  end;

  //never silently hide spots - say how many did not fit
  if Overflow > 0 then
  begin
    s := '+'+IntToStr(Overflow);
    c.Brush.Style := bsSolid;
    c.Brush.Color := clWindow;
    c.Font.Color  := BlendColor(clWindowText,clWindow,50);
    c.TextOut(FPaintBox.Width-c.TextWidth(s)-4, FPaintBox.Height-FRowH-2, s)
  end
end;

procedure TfrmBandMapGfx.DrawCqMarker(c : TCanvas);
var
  y  : Integer;
  cc : TColor;
  s  : String;
begin
  if FCqKHz <= 0 then
    exit;

  cc := CqAccent;
  y  := FreqToY(FCqKHz);
  s  := FormatFloat('0.00',FCqKHz);

  c.Brush.Style := bsClear;
  c.Font.Color  := cc;

  if (y < FPlotTop) or (y > FPlotTop+FPlotH) then
  begin
    //out of view - show which way to tune back
    if y < FPlotTop then
      c.TextOut(FRulerW+4,FPlotTop,'^ CQ '+s)
    else
      c.TextOut(FRulerW+4,FPlotTop+FPlotH-FRowH,'v CQ '+s);
    exit
  end;

  c.Pen.Color := cc;
  c.Pen.Width := 1; //psDash renders solid with a wider pen on Cocoa
  c.Pen.Style := psDash;
  c.Line(FRulerW+1,y,FPaintBox.Width,y);
  c.Pen.Style := psSolid;
  c.TextOut(FRulerW+4,y-FRowH,'CQ')
end;

procedure TfrmBandMapGfx.DrawVfoCursor(c : TCanvas);
var
  y,th : Integer;
  cv   : TColor;
  s    : String;
begin
  //a fixed window draws the cursor only while the radio is on its band; the
  //"no frequency" note belongs to the window that follows the radio
  if (not FInst.Choice.IsAuto) and ((FVfoKHz <= 0) or (FVfoBand <> FInst.Choice.Band)) then
    exit;

  if FVfoKHz <= 0 then
  begin
    s := 'No rig frequency';
    c.Brush.Style := bsClear;
    c.Font.Color  := BlendColor(clWindowText,clWindow,50);
    c.TextOut((FRulerW+FPaintBox.Width-c.TextWidth(s)) div 2,
              FPlotTop+FPlotH div 2, s);
    exit
  end;

  y := FreqToY(FVfoKHz);
  if (y < FPlotTop-2) or (y > FPlotTop+FPlotH+2) then
    exit;

  cv := VfoAccent;
  s  := FormatFloat('0.00',FVfoKHz);
  th := c.TextHeight(s);

  c.Pen.Color := cv;
  c.Pen.Style := psSolid;
  c.Pen.Width := 1;
  c.Line(FRulerW,y,FPaintBox.Width,y);

  //frequency badge in the ruler gutter, plus a pointer at the axis
  c.Brush.Style := bsSolid;
  c.Brush.Color := cv;
  c.FillRect(0,y-th div 2-1,FRulerW,y+th div 2+1);
  c.Polygon([Point(FRulerW+1,y-5),Point(FRulerW+8,y),Point(FRulerW+1,y+5)]);

  c.Brush.Style := bsClear;
  c.Font.Color  := TcolorMemo.ReadableTextColor(clWindow,cv);
  c.TextOut(FRulerW-2-c.TextWidth(s),y-th div 2,s)
end;

{ TLogCheckThread }

constructor TLogCheckThread.Create(AQueue : TLogCheckQueue);
begin
  FQueue := AQueue;
  FreeOnTerminate := False;
  inherited Create(False)
end;

procedure TLogCheckThread.Execute;
var
  R : TLogCheckRequest;
begin
  while not Terminated do
  begin
    if not FQueue.Pop(R) then
    begin
      Sleep(100);
      Continue
    end;
    try
      if R.Kind = lckMembership then
        dmData.RbnLogCache.Membership(R.Call, R.LastDate)
      else
        dmData.RbnLogCache.WorkedAfter(R.Call, R.Band, R.Mode, R.LastDate, R.LastTime)
    except
      on E : Exception do
        DbgLogException('BMAP', 'log check ' + R.Call + ' ' + R.Band + ' ' + R.Mode, E)
    end
  end
end;

{ TBandMapWindows }

constructor TBandMapWindows.Create;
begin
  inherited Create;
  FList   := TList.Create;
  FChecks := TLogCheckQueue.Create
end;

destructor TBandMapWindows.Destroy;
var
  i : Integer;
begin
  FShuttingDown := True;
  if Assigned(FChecker) then
  begin
    FChecker.Terminate;
    FChecker.WaitFor;
    FreeAndNil(FChecker)
  end;
  for i := FList.Count-1 downto 0 do
    TfrmBandMapGfx(FList[i]).Free;
  FList.Free;
  FChecks.Free;
  inherited Destroy
end;

procedure TBandMapWindows.RequestLogCheck(const ACall, ABand, AMode, ALastDate, ALastTime : String);
begin
  //started on the first question, so a session without a QSO rule has no thread
  if FChecker = nil then
    FChecker := TLogCheckThread.Create(FChecks);
  FChecks.Push(ACall, ABand, AMode, ALastDate, ALastTime)
end;

procedure TBandMapWindows.RequestMembership(const ACall, ADate : String);
begin
  if FChecker = nil then
    FChecker := TLogCheckThread.Create(FChecks);
  FChecks.PushMembership(ACall, ADate)
end;

procedure TBandMapWindows.Changed;
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self)
end;

procedure TBandMapWindows.FillChoiceMenu(AParent : TMenuItem; AOnClick : TNotifyEvent;
                                         ACurrent : PBandMapChoice);
var
  bands : TStringArray;
  b     : String;

  procedure AddItem(const AChoice : TBandMapChoice; const ACaption : String);
  var
    m : TMenuItem;
    isOpen : Boolean;
  begin
    m := TMenuItem.Create(AParent);
    m.Hint    := ChoiceKey(AChoice);
    m.Caption := ACaption;
    m.OnClick := AOnClick;
    isOpen := Find(AChoice) <> nil;
    if ACurrent = nil then
      m.Checked := isOpen
    else begin
      m.Checked := SameChoice(AChoice, ACurrent^);
      if isOpen and not m.Checked then
        m.Caption := ACaption + ' (open)'
    end;
    AParent.Add(m)
  end;

begin
  AParent.Clear;
  AddItem(AutoChoice, 'Auto (follow VFO)');
  AParent.AddSeparator;
  bands := EnabledBands;
  for b in bands do
    AddItem(FixedChoice(b), BandLabel(b))
end;

function TBandMapWindows.Count : Integer;
begin
  Result := FList.Count
end;

function TBandMapWindows.Item(AIndex : Integer) : TfrmBandMapGfx;
begin
  Result := TfrmBandMapGfx(FList[AIndex])
end;

function TBandMapWindows.Find(const AChoice : TBandMapChoice) : TfrmBandMapGfx;
var
  i : Integer;
begin
  for i := 0 to FList.Count-1 do
    if SameChoice(Item(i).Choice, AChoice) then
      exit(Item(i));
  Result := nil
end;

function TBandMapWindows.Open(const AChoice : TBandMapChoice) : TfrmBandMapGfx;
begin
  Result := Find(AChoice);
  if Result = nil then
  begin
    Result := TfrmBandMapGfx.CreateInstance(AChoice);
    FList.Add(Result);
    //settings are read in FormShow, once cqrini exists
    Result.Show;
    if not FShuttingDown then
    begin
      SaveOpenList;
      Changed
    end
  end
  else begin
    Result.Show;
    Result.BringToFront
  end
end;

procedure TBandMapWindows.Detach(AWindow : TfrmBandMapGfx);
begin
  FList.Remove(AWindow);
  //closed by the user: it stays closed after a restart. Closed because the
  //program or the log is going down: the list was taken before that
  if not FShuttingDown then
  begin
    SaveOpenList;
    Changed
  end
end;

procedure TBandMapWindows.SetVfo(const ABand : String; AFreqKHz : Double; const AMode : String);
var
  i : Integer;
begin
  for i := 0 to FList.Count-1 do
    Item(i).SetVfo(ABand, AFreqKHz, AMode)
end;

procedure TBandMapWindows.ReloadSettings;
var
  i : Integer;
begin
  for i := 0 to FList.Count-1 do
    Item(i).LoadSettings
end;

procedure TBandMapWindows.BringAllToFront;
var
  i : Integer;
begin
  for i := 0 to FList.Count-1 do
    if Item(i).Showing then
      Item(i).BringToFront
end;

procedure TBandMapWindows.SaveOpenList;
var
  keys : TStringArray;
  i    : Integer;
begin
  if dmData.DBName = '' then
    exit;
  keys := nil;
  for i := 0 to FList.Count-1 do
  begin
    SetLength(keys, Length(keys)+1);
    //a window standing in for a disabled band keeps that band's key, so the
    //choice comes back once the band is enabled; closing the window drops it
    if Item(i).FStandInFor <> '' then
      keys[High(keys)] := Item(i).FStandInFor
    else
      keys[High(keys)] := ChoiceKey(Item(i).Choice)
  end;
  WriteOpenList(IniStore, keys)
end;

function TBandMapWindows.EnabledBands : TStringArray;
var
  i : Integer;
begin
  Result := nil;
  for i := 0 to cMaxBandsCount-1 do
  begin
    if dmUtils.MyBands[i][0] = '' then
      break;
    SetLength(Result, Length(Result)+1);
    Result[High(Result)] := dmUtils.MyBands[i][0]
  end
end;

procedure TBandMapWindows.Restore;
var
  keys : TStringArray;
  k    : String;
  c,e  : TBandMapChoice;
  w    : TfrmBandMapGfx;
begin
  MigrateLegacyLayout(IniStore, cqrini.LocalOnly('WindowSize'));
  keys := ReadOpenList(IniStore);
  for k in keys do
  begin
    if not ParseChoiceKey(k, c) then
      Continue;
    if ResolveChoice(c, EnabledBands, e) then
      Open(c)
    else begin
      //the band was disabled in Preferences > Bands since: show Auto instead
      //and say so, but keep the saved choice for when it is enabled again
      w := Find(e);
      if w = nil then
      begin
        w := Open(e);
        w.FStandInFor := k
      end;
      w.sbStatus.Panels[1].Text := BandLabel(c.Band)+' is disabled in Preferences > Bands, following the VFO instead'
    end
  end;
  //Open wrote the list before the stand-ins were known
  SaveOpenList
end;

procedure TBandMapWindows.CloseAll;
var
  i : Integer;
begin
  FShuttingDown := True;
  try
    SaveOpenList;
    //answers for the old log are of no use to the new one
    FChecks.Clear;
    for i := FList.Count-1 downto 0 do
      Item(i).Close //FormClose frees it and detaches it
  finally
    FShuttingDown := False
  end
end;

initialization
  IniStore       := TCqrIniStore.Create;
  BandMapWindows := TBandMapWindows.Create;

finalization
  FreeAndNil(BandMapWindows);
  FreeAndNil(IniStore);

end.
