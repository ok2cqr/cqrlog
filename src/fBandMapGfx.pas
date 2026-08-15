unit fBandMapGfx;

{ Graphical band map - a vertical frequency ruler with spots drawn at their
  true frequency, a live VFO cursor and click-to-QSY.

  This is a second, additional band map window. It does not replace or touch
  fBandMap in any way: it keeps its own spot store (uBandMapStore), its own
  visibility gate and its own zoom setting, so the text band map can be used
  side by side as the reference.

  Filtering shares the classic band map's dialog and its ini keys, so both
  windows hide the same spots. Not implemented here on purpose (see the
  CHANGELOG entry): xplanet export and bandmap.csv persistence. Those stay with
  the text band map. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ExtCtrls, StdCtrls, Buttons,
  ComCtrls, Menus, Types, uBandMapStore;

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
    procedure cmbSpanChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure tmrPollTimer(Sender: TObject);
  private
    FPaintBox  : TPaintBox;
    FHits      : array of TSpotHit;

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
    procedure UpdateFilterIndicator;

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
    procedure LoadSettings;
    //fed from TfrmTRXControl.SynTRX, main thread, freq in kHz (txlo corrected)
    procedure SetVfo(const ABand : String; AFreqKHz : Double; const AMode : String);
  end;

var
  frmBandMapGfx: TfrmBandMapGfx;

implementation
{$R *.lfm}

uses Math, LCLType, uColorMemo, dUtils, uMyIni, dData, fNewQSO, fTRXControl,
     fBandMap, fBandMapFilter;

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

procedure TfrmBandMapGfx.FormCreate(Sender: TObject);
var
  i : Integer;
begin
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
  BandMapStore.FirstAgingSec  := cqrini.ReadInteger('BandMap','FirstAging',5)*60;
  BandMapStore.SecondAgingSec := cqrini.ReadInteger('BandMap','SecondAging',8)*60;
  BandMapStore.DeleteAfterSec := cqrini.ReadInteger('BandMap','Disep',12)*60;
  BandMapStoreDebug := dmData.DebugLevel >= 1;

  //the filter dialog is the very same one the classic band map uses, and so
  //are the ini keys - one filter, both windows behave alike
  FOnlyCurrBand := cqrini.ReadBool('BandMap','OnlyActiveBand',False);
  FOnlyCurrMode := cqrini.ReadBool('BandMap','OnlyActiveMode',False);

  BandMapStore.DateFilter := bmdShowAll;
  if cqrini.ReadBool('BandMapFilter','NoWkdHour',False) then
    BandMapStore.DateFilter := bmdLastHours;
  if cqrini.ReadBool('BandMapFilter','NoWkdDate',False) then
    BandMapStore.DateFilter := bmdSinceDateTime;

  BandMapStore.LastHours := cqrini.ReadInteger('BandMapFilter','LastHours',48);
  BandMapStore.SinceDate := cqrini.ReadString('BandMapFilter','LastDate','');
  BandMapStore.SinceTime := cqrini.ReadString('BandMapFilter','LastTime','');
  BandMapStore.OnlyLoTW  := cqrini.ReadBool('BandMapFilter','OnlyLoTW',False);
  BandMapStore.OnlyEQSL  := cqrini.ReadBool('BandMapFilter','OnlyeQSL',False);
  BandMapStore.OnWorkedCheck := @IsWorked;

  UpdateFilterIndicator;

  sp := cqrini.ReadInteger('BandMapGfx','SpanKHz',cSpans[cDefaultSpanIndex]);
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

  FDirty := True;
  FPaintBox.Invalidate
end;

procedure TfrmBandMapGfx.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmBandMapGfx);
  LoadSettings;
  FManualPan := False; //reopening always starts following the radio again
  if FVfoKHz <= 0 then
    UseNewQsoFreq; //open on the band the operator is actually on
  EnsureCenter;
  BandMapStore.Enabled := True;
  tmrPoll.Enabled      := True;
  FDirty := True;
  FPaintBox.Invalidate
end;

procedure TfrmBandMapGfx.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmBandMapGfx);
  cqrini.WriteInteger('BandMapGfx','SpanKHz',FSpanKHz);
  tmrPoll.Enabled      := False;
  //producers stop queueing immediately, so a hidden window costs nothing
  BandMapStore.Enabled := False
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
begin
  //With no rig model configured at all SynTRX never runs (its timer is only
  //enabled once a rig initialises), so nothing would ever call SetVfo. Keep
  //following the New QSO frequency from here as long as it is the source.
  if (FVfoKHz <= 0) or FVfoFromQso then
    UseNewQsoFreq;

  if BandMapStore.Poll(Now) then
    FDirty := True;
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

  if AFreqKHz > 0 then
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
  FDirty      := True //no Invalidate here, the poll timer coalesces
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
begin
  if FCenterKHz > 0 then
    exit;
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
  //anchor on the radio, not on the possibly dragged-away centre, so panning
  //cannot wander off into the next band
  ref := FVfoKHz;
  if ref <= 0 then
    ref := FCenterKHz;

  if not BandLimits(ref,lo,hi) then
    exit; //outside every band, or no band table yet - leave the view alone

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
  if (FVfoKHz > 0) and (not FManualPan) then
    FCenterKHz := FVfoKHz;

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

{ runs on the GUI thread from TBandMapStore.Poll, which is why Poll rations the
  number of calls per tick. dmData serialises access to the query object, so it
  is safe to call while the classic band map's thread is doing the same. }
function TfrmBandMapGfx.IsWorked(const ACall, ABand, AMode,
                                 ALastDate, ALastTime : String) : Boolean;
begin
  //a failing query (log being switched, connection dropped) must not turn into
  //an exception dialog every 500 ms - show the spot rather than nag
  try
    Result := dmData.CallExistsInLog(ACall,ABand,AMode,ALastDate,ALastTime)
  except
    on E : Exception do
    begin
      Result := False;
      if dmData.DebugLevel >= 1 then
        Writeln('BandMapGfx: log check failed - ',E.Message)
    end
  end
end;

procedure TfrmBandMapGfx.UpdateFilterIndicator;
var
  filtered : Boolean;
begin
  filtered := FOnlyCurrBand or FOnlyCurrMode or BandMapStore.OnlyLoTW
              or BandMapStore.OnlyEQSL or (BandMapStore.DateFilter <> bmdShowAll);

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
  f : TfrmBandMapFilter;
begin
  f := TfrmBandMapFilter.Create(nil);
  try
    if f.ShowModal = mrOK then
    begin
      LoadSettings;
      //the classic band map reads the very same keys, keep the two in step
      frmBandMap.LoadSettings
    end
  finally
    FreeAndNil(f)
  end;
  ParkFocus
end;

procedure TfrmBandMapGfx.pumClearMapClick(Sender: TObject);
begin
  BandMapStore.Clear;
  FDirty := True;
  FPaintBox.Invalidate;
  ParkFocus
end;

procedure TfrmBandMapGfx.pumHelpClick(Sender: TObject);
begin
  ShowHelp;
  ParkFocus
end;

{ band and mode are display filters, applied here rather than on the way in, so
  that following the radio across bands does not throw spots away. Mode matching
  copies the text band map: the radio reports USB/LSB/CWR, spots carry SSB/CW. }
function TfrmBandMapGfx.SpotVisible(const ASpot : TGfxSpot) : Boolean;
begin
  Result := True;

  if FOnlyCurrBand and (FVfoBand <> '') then
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
  ref := FVfoKHz;
  if ref <= 0 then
    ref := FCenterKHz;
  if not BandLimits(ref,lo,hi) then
    exit;

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
  s     : String;
  r     : TRect;
  eff   : TColor;
  cLead : TColor;
begin
  TickX      := FRulerW+2;
  LeadX      := FRulerW+12;
  TextX      := FRulerW+17;
  LastBottom := -MaxInt;
  Overflow   := 0;
  cLead      := BlendColor(clWindowText,clWindow,60);

  //the store is kept sorted by frequency, so this walks the plot top down
  for i:=0 to BandMapStore.Count-1 do
  begin
    sp := BandMapStore.Item(i);
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

end.
