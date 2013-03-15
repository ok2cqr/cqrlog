(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fTestMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  DBGrids, StdCtrls, Buttons, ComCtrls, Grids, inifiles,
  LCLType, RTTICtrls, httpsend, Menus, ActnList, process,
  uCWKeying, ipc, baseunix, db;

type

  { TfrmTestMain }

  TfrmTestMain = class(TForm)
    acAbout:     TAction;
    acAddToBandMap: TAction;
    acClose:     TAction;
    acCWMessages: TAction;
    acCWType:    TAction;
    acDXCluster: TAction;
    acGrayline:  TAction;
    acPreferences: TAction;
    acShowBandMap: TAction;
    acImportDXCC: TAction;
    acProgram: TAction;
    acDeleteQSO: TAction;
    acShowDXCluster: TAction;
    acShowGrayline: TAction;
    acShowFKeys: TAction;
    acNewLog: TAction;
    acOpenLog: TAction;
    acProp: TAction;
    acContestPref: TAction;
    acSCP: TAction;
    acEditQSO: TAction;
    AcKeys: TAction;
    ActionList1: TActionList;
    acShowTRXControl: TAction;
    acXplanet:   TAction;
    cmbFreq: TComboBox;
    cmbMode: TComboBox;
    dbgrdMain: TDBGrid;
    edtCall: TEdit;
    edtExch: TEdit;
    GroupBox1: TGroupBox;
    imgMain1:    TImageList;
    Label10: TLabel;
    Label14: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lblCWSpeed: TLabel;
    lblRSTS: TLabel;
    lblRSTR: TLabel;
    lblTime: TLabel;
    lblAzi: TLabel;
    lblCont: TLabel;
    lblRadio: TLabel;
    lblDXCC: TLabel;
    lblGreeting: TLabel;
    lblHisTime: TLabel;
    lblITU: TLabel;
    lblLat: TLabel;
    lblLocSunRise: TLabel;
    lblLocSunSet: TLabel;
    lblLong: TLabel;
    lblMissMult: TLabel;
    lblQRA: TLabel;
    lblQSOMiss: TLabel;
    lblMissCall: TLabel;
    lblQSOMiss1: TLabel;
    lblScore: TLabel;
    lblRate: TLabel;
    lblTarSunRise: TLabel;
    lblTarSunSet: TLabel;
    lblWAZ: TLabel;
    MainMenu1:   TMainMenu;
    mCountry: TMemo;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem15: TMenuItem;
    MenuItem16:  TMenuItem;
    MenuItem17:  TMenuItem;
    MenuItem18: TMenuItem;
    MenuItem19: TMenuItem;
    MenuItem2:   TMenuItem;
    MenuItem20: TMenuItem;
    MenuItem21: TMenuItem;
    MenuItem22: TMenuItem;
    MenuItem23: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem30: TMenuItem;
    MenuItem31: TMenuItem;
    MenuItem32: TMenuItem;
    MenuItem33: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    mnuEditQSO: TMenuItem;
    mnuDelLastQSO: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem47:  TMenuItem;
    MenuItem48:  TMenuItem;
    MenuItem49:  TMenuItem;
    MenuItem9:   TMenuItem;
    mnuClose:    TMenuItem;
    mnuFile:     TMenuItem;
    mnuHelp:     TMenuItem;
    mnuPreferences: TMenuItem;
    dlgOpen: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    pnlProgramMode: TPanel;
    pnlQSONr: TPanel;
    pnlScore: TPanel;
    popGrd: TPopupMenu;
    sbNewTestQSO:    TStatusBar;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    strgrdMissingMult: TStringGrid;
    strgrdMissing: TStringGrid;
    strgrdSummary: TStringGrid;
    tmrTime: TTimer;
    tmrESC:      TTimer;
    tmrRadio:    TTimer;
    procedure acCloseExecute(Sender: TObject);
    procedure acContestPrefExecute(Sender: TObject);
    procedure acDeleteQSOExecute(Sender: TObject);
    procedure acEditQSOExecute(Sender: TObject);
    procedure AcKeysExecute(Sender: TObject);
    procedure acNewLogExecute(Sender: TObject);
    procedure acOpenLogExecute(Sender: TObject);
    procedure acProgramExecute(Sender: TObject);
    procedure acPropExecute(Sender: TObject);
    procedure acRefreshTRXExecute(Sender: TObject);
    procedure acSCPExecute(Sender: TObject);
    procedure acShowDXClusterExecute(Sender: TObject);
    procedure acShowFKeysExecute(Sender: TObject);
    procedure acShowGraylineExecute(Sender: TObject);
    procedure dbgrdMainColumnMoved(Sender: TObject; FromIndex, ToIndex: Integer
      );
    procedure dbgrdMainColumnSized(Sender: TObject);
    procedure edtCallChange(Sender: TObject);
    procedure edtCallExit(Sender: TObject);
    procedure edtCallKeyPress(Sender: TObject; var Key: char);
    procedure edtExchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure edtExchKeyPress(Sender: TObject; var Key: char);
    procedure edtExchKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormActivate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormWindowStateChange(Sender: TObject);
    procedure MenuItem17Click(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure acAddToBandMapExecute(Sender: TObject);
    procedure acCWMessagesExecute(Sender: TObject);
    procedure acCWTypeExecute(Sender: TObject);
    procedure acDetailsExecute(Sender: TObject);
    procedure acPreferencesExecute(Sender: TObject);
    procedure acShowBandMapExecute(Sender: TObject);
    procedure acShowTRXControlExecute(Sender: TObject);
    procedure acXplanetExecute(Sender: TObject);
    procedure edtCallKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure edtCallKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure btnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure edtStartTimeKeyPress(Sender: TObject; var Key: char);
    procedure tmrESCTimer(Sender: TObject);
    procedure tmrRadioTimer(Sender: TObject);
    procedure tmrTimeTimer(Sender: TObject);
  private
    fEditQSO:     boolean;
    fViewQSO:     boolean;
    //old_stat_pfx: string;
    old_cmode: string;
    old_ccall: string;
    old_cfreq: string;

    //old_prof:   integer;
    //old_pfx:    string;
    //old_date:   TDateTime;
    old_mode:   string;
    //old_freq:   string;
    //old_qslr:   string;
    posun:      string;
    old_call:   string;
    ChangeDXCC: boolean;
    //StartTime:  TDateTime;
    Running:    boolean;
    //idcall:     string;
    old_t_mode: string;
    old_t_band: string;
    //lotw_qslr:  string;
    //fromNewQSO: boolean;

    p160,p80,p40,p30,p20,p17,p15,p12,p10 : SmallInt;

    procedure ShowDXCCInfo(pfx: string = '');
    procedure ChangeReports;
    procedure CalculateDistanceEtc;
    procedure ShowWindows;
    procedure UpdateFKeyLabels;
    procedure SaveOpenedWindows;
    procedure LoadOpenedWindows;
    procedure SetStringGrids(grd : TStringGrid);
    procedure UpdateSumGrid;
    procedure LoadBandSettings;
    procedure CheckForQSO;
    procedure AfterOpenMainDatabase;
    procedure AfterSaveQSO;
    procedure SetQSONrPanel;
    procedure RefreshData;
    procedure ChangeBand(up,warc : Boolean);

    function  GetKeybCWMessage(KeyAction : String) : String;

  public
    QTHfromCb: boolean;
    FromDXC: boolean;
    UseSpaceBar: boolean;
    CWint:   TCWKeying;
    ShowWin: boolean;

    property EditQSO: boolean Read fEditQSO Write fEditQSO default False;
    property ViewQSO: boolean Read fViewQSO Write fViewQSO default False;

    procedure AppIdle(Sender: TObject; var Handled: boolean);
    procedure ClearAll;
    procedure SavePosition;
    procedure NewQSOFromSpot(call, freq, mode: string);
    procedure DisableAll;
    procedure EnableAll;
    procedure ShowFields;
    procedure LoadGrid;
    procedure SaveGrid;
    procedure ChangeMode(mode : String);

    { public declarations }
  end;

var
  frmTestMain: TfrmTestMain;
  is_running: boolean = False;
  EscFirstTime: boolean = True;
  CallBook:  string;
  callsign:  string;
  cname:     string;
  cqth:      string;
  cqsl_via:  string;
  cGrid:     string;
  cState:    string;
  cCounty:   string;
  minimalize: boolean;
  MinDXCluster: boolean;
  MinGrayLine: boolean;
  MinTRXControl: boolean;
  MinNewQSO: boolean;
  MinQSODetails: boolean;

implementation

{ TfrmTestMain }

uses dUtils, dDXCC, dData, fSelectDXCC, fGrayline,
  fTRXControl, fPreferences, fSplash, fDXCluster, fSendSpot,
  fQSODetails, fBandMap, fImportProgress,
  fKeyTexts, fCWType, fCWKeys, fLogList, fPropagation, fNewQSO, fNewTestLog,
  fSCP, fEditTestQSO, fKeysPref, uMyini;

procedure TfrmTestMain.ShowDXCCInfo(pfx: string = '');
var
  cont, country, WAZ, ITU: string;
  //Date:      TDateTime;
  lat, long: string;
begin
  cont    := '';
  country := '';
  waz     := '';
  posun   := '';
  itu     := '';
  lat     := '';
  long    := '';

  if pfx = '' then
  begin
    dmDXCC.id_country(edtCall.Text, now, pfx, cont, country, WAZ, posun, ITU, lat, long);
    dmUtils.ModifyWAZITU(waz, itu);
  end
  else begin
    dmDXCC.qDXCCRef.Close;
    dmDXCC.qDXCCRef.SQL.Text :=
      'SELECT * FROM dxcc_ref WHERE pref = ' + QuotedStr(pfx);
    dmDXCC.qDXCCRef.Open;
    if dmDXCC.qDXCCRef.RecordCount > 0 then
    begin
      cont    := dmDXCC.qDXCCRef.FieldByName('CONT').AsString;
      lat     := dmDXCC.qDXCCRef.FieldByName('LAT').AsString;
      long    := dmDXCC.qDXCCRef.FieldByName('longit').AsString;
      country := dmDXCC.qDXCCRef.FieldByName('name').AsString;
      waz := dmDXCC.qDXCCRef.FieldByName('WAZ').AsString;
      itu := dmDXCC.qDXCCRef.FieldByName('ITU').AsString;
    end;
    dmDXCC.qDXCCRef.Close;
  end;
  lblHisTime.Caption  := dmUtils.HisDateTime(pfx);
  lblGreeting.Caption := dmUtils.GetGreetings(lblHisTime.Caption);
  mCountry.Clear;
  mCountry.Lines.Add(country);
  mCountry.Repaint;
  lblWAZ.Caption := WAZ;
  lblITU.Caption := itu;
  lblDXCC.Caption := pfx;
  lblCont.Caption := cont;
  lblLat.Caption  := lat;
  lblLong.Caption := long;
end;

procedure TfrmTestMain.ClearAll;
var
  i:      integer;
  //lat, long: currency;
begin
  lblWAZ.Caption      := '';
  lblDXCC.Caption     := '';
  lblITU.Caption      := '';
  lblLat.Caption      := '';
  lblLong.Caption     := '';
  lblCont.Caption     := '';
  lblHisTime.Caption  := '';
  lblQRA.Caption      := '';
  lblAzi.Caption      := '';
  lblGreeting.Caption := '';
  lblTarSunRise.Caption := '';
  lblTarSunSet.Caption := '';
  lblMissCall.Caption := '';
  lblMissMult.Caption := '';
  mCountry.Clear;
  if frmQSODetails.Showing then
  begin
    frmQSODetails.ClearAll;
    frmQSODetails.ClearStat;
  end;

  for i:=0 to strgrdMissing.ColCount -1 do
    strgrdMissing.Cells[i,1] := '';

  for i:=0 to strgrdMissingMult.ColCount -1 do
    strgrdMissingMult.Cells[i,1] := '';


  for i := 0 to ComponentCount - 1 do
  begin
    if (frmTestMain.Components[i] is TEdit) then
      (frmTestMain.Components[i] as TEdit).Text := ''
  end;

 {$IFDEF CONTEST}
  if dmData.ContestDatabase.Connected and dmData.ContestMode then
  begin
    dmUtils.CoordinateFromLocator(dmData.tstini.ReadString('Basic','Gird',''), lat, long);
    lat := lat * -1;
    frmGrayLine.ob^.jachcucaru(True, long, lat, long, lat);
    frmGrayline.FormPaint(nil)
  end;
  if frmSCP.Showing then
    frmSCP.mSCP.Text := '';
  {$ENDIF}

  if edtCall.Enabled then
    edtCall.SetFocus;
  old_call := ''
end;

procedure TfrmTestMain.FormShow(Sender: TObject);
var
  i:     integer;
  //l:     TStringList;
  //dir:   string;
  myloc: string;
  Lat, Long: currency;
  SunRise, SunSet: TDateTime;
  delta: currency = 0;
  SunDelta: currency = 0;
  inUTC: boolean = False;
begin
  CWint := nil;
  Writeln('ab');
  if not (Sender = nil) then
  begin                 //first showing, I don'tneed this if I edit or show qso
    dmUtils.ModifyXplanetConf;
    dmUtils.LoadFontSettings(frmTestMain);
    dmUtils.LoadBandLabelSettins;
    sbNewTestQSO.Panels[0].Width := 180;
    sbNewTestQSO.Panels[1].Width := 350;

    sbNewTestQSO.Panels[2].Width := 70;

    sbNewTestQSO.Panels[3].Text  := 'Ver. ' + dmData.VersionString;
    sbNewTestQSO.Panels[3].Width := 30;

    dmUtils.LoadWindowPos(frmTestMain);

    UseSpaceBar := cqrini.ReadBool('NewQSO', 'UseSpaceBar', False);

    if frmTRXControl.Showing then
    begin
      if frmTRXControl.rbRadio1.Checked then
        tmrRadio.Interval := cqrini.ReadInteger('TRX', 'Poll1', 500)
      else
        tmrRadio.Interval := cqrini.ReadInteger('TRX', 'Poll2', 500);
    end
    else
    begin
      tmrRadio.Interval := cqrini.ReadInteger('TRX', 'Poll1', 500);
    end;

    if cqrini.ReadBool('xplanet', 'run', False) then
      dmUtils.RunXplanet;
    Writeln('bc');
    LoadOpenedWindows;
    i := cqrini.ReadInteger('CW', 'Type', 0);
    UpdateFKeyLabels;
    Writeln('bd');

    CWint := TCWKeying.Create;
    if dmData.DebugLevel >= 1 then
      CWint.DebugMode := True;
    if i > 0 then
    begin
      if i = 1 then
      begin
        CWint.KeyType := ktWinKeyer;
        CWint.Port    := cqrini.ReadString('CW', 'wk_port', '');
        CWint.Device  := cqrini.ReadString('CW', 'wk_port', '');
        CWint.Open;
        CWint.SetSpeed(cqrini.ReadInteger('CW', 'wk_speed', 30));
        lblCWSpeed.Caption := IntToStr(cqrini.ReadInteger('CW', 'wk_speed', 30));// + 'WPM'
      end
      else
      begin
        CWint.KeyType := ktCWdaemon;
        CWint.Port    := cqrini.ReadString('CW', 'cw_port', '');
        CWint.Device  := cqrini.ReadString('CW', 'cw_address', '');
        CWint.Open;
        CWint.SetSpeed(cqrini.ReadInteger('CW', 'cw_speed', 30));
        lblCWSpeed.Caption := IntToStr(cqrini.ReadInteger('CW', 'cw_speed', 30));// + 'WPM'
      end
    end
    else begin
      CWint.SetSpeed(30);
      lblCWSpeed.Caption := '30'
    end;

    myloc    := cqrini.ReadString('Station', 'LOC', '');
    delta    := cqrini.ReadFloat('Program', 'offset', 0);
    inUTC    := cqrini.ReadBool('Program', 'SunUTC', False);
    SunDelta := cqrini.ReadFloat('Program', 'SunOffset', 0);

    if dmUtils.IsLocOK(myloc) then
    begin
      dmUtils.CoordinateFromLocator(myloc, lat, long);
      dmUtils.CalcSunRiseSunSet(lat, long, SunRise, SunSet);
      if SunDelta <> 0 then
      begin
        SunRise := SunRise + (SunDelta / 24);
        SunSet  := SunSet + (SunDelta / 24)
      end;
      if inUTC then
      begin
        SunRise := SunRise - (delta / 24);
        SunSet  := SunSet - (delta / 24)
      end;
      lblLocSunRise.Caption := TimeToStr(SunRise);
      lblLocSunSet.Caption  := TimeToStr(SunSet)
    end
    else
    begin
      lblLocSunRise.Caption := '';
      lblLocSunSet.Caption  := ''
    end
  end; //if not sender=nil

  old_ccall := '';
  old_cmode := '';
  old_cfreq := '';

  Running      := False;
  EscFirstTime := False;
  ChangeDXCC   := False;
  Writeln('ab');
  acNewLog.Execute;

  strgrdSummary.Cells[0,1] := 'QSO';
  strgrdSummary.Cells[0,2] := 'PFX';
  UpdateSumGrid;
  ClearAll;
  if edtCall.Enabled then
    edtCall.SetFocus;
  tmrRadio.Enabled := True
end;

procedure TfrmTestMain.tmrRadioTimer(Sender: TObject);
var
  mode, freq, band: string;
begin
  mode := '';
  freq := '';
  if Running then
    exit;
  Running := True;
  try
    if (frmTRXControl.GetModeFreqNewQSO(mode, freq)) then
    begin
      if mode <> '' then
        cmbMode.Text := mode;
      if freq <> empty_freq then
        cmbFreq.Text := freq;
      if (mode <> '') and (freq <> empty_freq) then
      begin
        band := dmUtils.GetBandFromFreq(freq);
        if (mode <> old_t_mode) or (band <> old_t_band) then
        begin
          old_t_mode := mode;
          old_t_band := band;
        end
      end
    end
  finally
    Running := False
  end
end;

procedure TfrmTestMain.tmrTimeTimer(Sender: TObject);
var
  s : String = '';
begin
  DateTimeToString(s,'YYYY-MM-DD HH:MM:SS',dmUtils.GetDateTime(0));
  lblTime.Caption := s
end;

procedure TfrmTestMain.FormCreate(Sender: TObject);
begin
  tmrRadio.Enabled := False;
  //dmUtils.InsertModes(cmbMode);
  //dmUtils.InsertFreq(cmbFreq);
end;

procedure TfrmTestMain.btnCancelClick(Sender: TObject);
begin
  acClose.Execute
end;

procedure TfrmTestMain.edtCallKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
var
  tmp:  extended = 0;
  mode: string = '';
  //Skip: boolean = False;
begin
  if key = 9 then
  begin
    key := 0;
    if dmData.ProgramMode = tmRun then
    begin
      dmData.ProgramMode     := tmSP;
      pnlProgramMode.Caption := 'S&P'
    end
    else begin
      dmData.ProgramMode     := tmRun;
      pnlProgramMode.Caption := 'RUN'
    end;
    UpdateFKeyLabels
  end;

  if (key = VK_UP) or (key = VK_DOWN) then
  begin
    key := 0;
    edtExch.SetFocus
  end;

  if key = 13 then
  begin
    key := 0;
    if TryStrToFloat(edtCall.Text, tmp) then
    begin
      tmp  := tmp / 1000; //kHz to MHz
      mode := dmUtils.GetModeFromFreq(FloatToStr(tmp));
      tmp  := tmp * 1000000; //MHz to Hz
      frmTRXControl.SetModeFreq(mode, FloatToStr(tmp));
      key := 0;
      ClearAll;
      exit
    end
  end
end;


procedure TfrmTestMain.edtCallKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
{var
  exch : String;
  CurPos : TCurPos;}
begin
  {
  if (key = 13) and (edtCall.Text<>'') then
  begin
    if (edtCall.Text = 'CW') or (edtCall.Text = 'SSB') then
    begin
      ChangeMode(edtCall.Text);
      edtCall.Text := '';
      key := 0;
      exit
    end;
    if edtExch.Text <> '' then
      GetKeybCWMessage('NotEmptyExch')
    else
      GetKeybCWMessage('EmptyExch');
    dmData.GetLastExchange(edtCall.Text,exch,CurPos);

    edtExch.SetFocus;
    if exch <> '' then
    begin
      edtExch.Text := exch;
      case CurPos of
        cpBegin : begin
                    edtExch.SelStart  := 0;
                    edtExch.SelLength := 0
                  end;
        cpEnd   : begin
                    edtExch.SelStart  := Length(edtExch.Text);
                    edtExch.SelLength := 0
                  end
      end
    end;

    key := 0;
    exit
  end;

  if not ((chr(key) in AllowedCallChars)) then
    exit;

  if Length(edtCall.Text) < 3 then
    exit;
  //if frmSCP.Showing then
  //  frmSCP.mSCP.Text := dmData.GetSCPCalls(edtCall.Text);
  ShowDXCCInfo;
  CheckForQSO;
  CalculateDistanceEtc;
  if (lblDXCC.Caption <> '!') and (lblDXCC.Caption <> '#') then
  begin
    if frmGrayline.Showing then
    begin
      frmGrayline.s   := lblLat.Caption;
      frmGrayline.d   := lblLong.Caption;
      frmGrayline.pfx := lblDXCC.Caption;
      frmGrayline.kresli
    end
  end}
end;

procedure TfrmTestMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SaveOpenedWindows;
  if frmGrayline.Showing then //I have to close window manually because of
    frmGrayline.Close;        //bug in lazarus.
  if frmTRXControl.Showing then
    frmTRXControl.Close;
  if frmDXCluster.Showing then
    frmDXCluster.Close;
  if frmQSODetails.Showing then
    frmQSODetails.Close;
  if frmBandMap.Showing then
    frmBandMap.Close;
  if frmCWKeys.Showing then
    frmCWKeys.Close;
  if frmSCP.Showing then
    frmSCP.Close;

  cqrini.DeleteKey('TMPQSO', 'OFF');
  cqrini.DeleteKey('TMPQSO', 'FREQ');
  cqrini.DeleteKey('TMPQSO', 'Mode');
  cqrini.DeleteKey('TMPQSO', 'PWR');
  dmUtils.SaveWindowPos(frmTestMain);
  if Assigned(CWint) then
  begin
    CWint.Close;
    CWint.Free
  end
end;

procedure TfrmTestMain.acDetailsExecute(Sender: TObject);
begin
  frmQSODetails.Show;
  frmQSODetails.BringToFront;
end;

procedure TfrmTestMain.MenuItem9Click(Sender: TObject);
begin
  with TfrmSplash.Create(self) do
  try
    BorderStyle := bsDialog;
    Caption     := 'About CQRLOG ...';
    ShowModal
  finally
    Free
  end
end;

procedure TfrmTestMain.acAddToBandMapExecute(Sender: TObject);
begin
  frmBandMap.AddFromNewQSO(lblDXCC.Caption,'*'+edtCall.Text,StrToFloat(cmbFreq.Text),dmUtils.GetBandFromFreq(cmbFreq.Text)
  ,cmbMode.Text,lblLat.Caption,lblLong.Caption)
end;

procedure TfrmTestMain.acCWMessagesExecute(Sender: TObject);
begin
  frmKeyTexts := TfrmKeyTexts.Create(self);
  try
    frmKeyTexts.ShowModal;
    if frmKeyTexts.ModalResult = mrOK then
      UpdateFKeyLabels
  finally
    frmKeyTexts.Free
  end
end;

procedure TfrmTestMain.acCWTypeExecute(Sender: TObject);
begin
  with TfrmCWType.Create(self) do
  try
    edtSpeed.Value := CWint.GetSpeed;
    ShowModal
  finally
    Free
  end
end;

procedure TfrmTestMain.FormActivate(Sender: TObject);
begin
  if minimalize then
  begin
    minimalize := False;
    if MinTRXControl then
    begin
      frmTRXControl.BringToFront;
      MinTRXControl := False;
    end;
    if MinDXCluster then
    begin
      frmDXCluster.BringToFront;
      MinDXCluster := False;
    end;
    if MinGrayLine then
    begin
      frmGrayline.BringToFront;
      MinGrayLine := False;
    end;
    if MinQSODetails then
    begin
      frmQSODetails.BringToFront;
      MinQSODetails := False;
    end;
  end;
  if ShowWin then
  begin
    ShowWin := False;
    ShowWindows;
  end;
end;

procedure TfrmTestMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  Writeln('OnCloseQuery - TestMain');
end;

procedure TfrmTestMain.acCloseExecute(Sender: TObject);
begin
  Close;
  frmNewQSO.acCloseExecute(nil)
end;

procedure TfrmTestMain.acContestPrefExecute(Sender: TObject);
begin
  {$IFDEF CONTEST}
  with TfrmNewLog.Create(self) do
  try
    edtLogName.Text := dmData.tstini.ReadString('Contest','LogName','');
    cmbContest.Text := dmData.tstini.ReadString('Contest','Name','');

    edtCall.Text    := dmData.tstini.ReadString('Basic','Call','');
    edtCountry.Text := dmData.tstini.ReadString('Basic','Country','');
    edtGrid.Text    := dmData.tstini.ReadString('Basic','Gird','');
    edtName.Text    := dmData.tstini.ReadString('Basic','Name','');
    edtQTH.Text     := dmData.tstini.ReadString('Basic','QTH','');
    edtSection.Text := dmData.tstini.ReadString('Basic','Section','');
    edtState.Text   := dmData.tstini.ReadString('Basic','State','');
    edtZone.Text    := dmData.tstini.ReadString('Basic','Zone','');
    edtIOTA.Text    := dmData.tstini.ReadString('Basic','IOTA','');

    cmbExch1.Text   := dmData.tstini.ReadString('Details','Exch1','None');
    cmbExch2.Text   := dmData.tstini.ReadString('Details','Exch2','None');
    cmbMult1.Text   := dmData.tstini.ReadString('Details','Mult1','None');
    cmbMult1.Text   := dmData.tstini.ReadString('Details','Mult2','None');
    chkWARC.Checked := dmData.tstini.ReadBool('Details','WARC',False);

    chkDate.Checked     := dmData.tstini.ReadBool('Columns','Date',True);
    chkTimeOn.Checked   := dmData.tstini.ReadBool('Columns','time_on',True);
    chkCallSign.Checked := dmData.tstini.ReadBool('Columns','CallSign',True);
    chkMode.Checked     := dmData.tstini.ReadBool('Columns','Mode',True);
    chkFreq.Checked     := dmData.tstini.ReadBool('Columns','Freq',True);
    chkRST_S.Checked    := dmData.tstini.ReadBool('Columns','RST_S',False);
    chkRST_R.Checked    := dmData.tstini.ReadBool('Columns','RST_R',False);
    chkName.Checked     := dmData.tstini.ReadBool('Columns','Name',False);
    chkQTH.Checked      := dmData.tstini.ReadBool('Columns','QTH',False);
    chkIOTA.Checked     := dmData.tstini.ReadBool('Columns','IOTA',False);
    chkDXCC.Checked     := dmData.tstini.ReadBool('Columns','DXCC',True);
    chkWAZ.Checked      := dmData.tstini.ReadBool('Columns','WAZ',False);
    chkITU.Checked      := dmData.tstini.ReadBool('Columns','ITU',False);
    chkState.Checked    := dmData.tstini.ReadBool('Columns','State',False);
    chkCont.Checked     := dmData.tstini.ReadBool('Columns','Cont',False);
    chkQSONR.Checked    := dmData.tstini.ReadBool('Columns','QSONR',True);
    chkExch1.Checked    := dmData.tstini.ReadBool('Columns','Exch1',True);
    chkExch2.Checked    := dmData.tstini.ReadBool('Columns','Exch2',True);
    chkMult1.Checked    := dmData.tstini.ReadBool('Columns','Mult1',True);
    chkMult2.Checked    := dmData.tstini.ReadBool('Columns','Mult2',True); //points,band, prefix
    chkPoints.Checked   := dmData.tstini.ReadBool('Columns','Points',True);
    chkBand.Checked     := dmData.tstini.ReadBool('Columns','Band',True);
    chkWPX.Checked      := dmData.tstini.ReadBool('Columns','Prefix',False);
    chkPower.Checked    := dmData.tstini.ReadBool('Columns','Power',False);

    DlgType         := ctModifyRules;
    ShowModal;
    if ModalResult = mrOK then
    begin
      dmData.tstini.WriteString('Basic','Call',edtCall.Text);
      dmData.tstini.WriteString('Basic','Country',edtCountry.Text);
      dmData.tstini.WriteString('Basic','Gird',edtGrid.Text);
      dmData.tstini.WriteString('Basic','Name',edtName.Text);
      dmData.tstini.WriteString('Basic','QTH',edtQTH.Text);
      dmData.tstini.WriteString('Basic','Section',edtSection.Text);
      dmData.tstini.WriteString('Basic','State',edtState.Text);
      dmData.tstini.WriteString('Basic','Zone',edtZone.Text);
      dmData.tstini.WriteString('Basic','IOTA',edtIOTA.Text);

      dmData.tstini.WriteString('Details','Exch1',cmbExch1.Text);
      dmData.tstini.WriteString('Details','Exch2',cmbExch2.Text);
      dmData.tstini.WriteString('Details','Mult1',cmbMult1.Text);
      dmData.tstini.WriteString('Details','Mult2',cmbMult1.Text);
      dmData.tstini.WriteBool('Details','WARC',chkWARC.Checked);

      dmData.tstini.WriteBool('Columns','Date',chkDate.Checked);
      dmData.tstini.WriteBool('Columns','time_on',chkTimeOn.Checked);
      dmData.tstini.WriteBool('Columns','CallSign',chkCallSign.Checked);
      dmData.tstini.WriteBool('Columns','Mode',chkMode.Checked);
      dmData.tstini.WriteBool('Columns','Freq',chkFreq.Checked);
      dmData.tstini.WriteBool('Columns','RST_S',chkRST_S.Checked);
      dmData.tstini.WriteBool('Columns','RST_R',chkRST_R.Checked);
      dmData.tstini.WriteBool('Columns','Name',chkName.Checked);
      dmData.tstini.WriteBool('Columns','QTH',chkQTH.Checked);
      dmData.tstini.WriteBool('Columns','IOTA',chkIOTA.Checked);
      dmData.tstini.WriteBool('Columns','DXCC',chkDXCC.Checked);
      dmData.tstini.WriteBool('Columns','WAZ',chkWAZ.Checked);
      dmData.tstini.WriteBool('Columns','ITU',chkITU.Checked);
      dmData.tstini.WriteBool('Columns','State',chkState.Checked);
      dmData.tstini.WriteBool('Columns','Cont',chkCont.Checked);
      dmData.tstini.WriteBool('Columns','QSONR',chkQSONR.Checked);
      dmData.tstini.WriteBool('Columns','Exch1',chkExch1.Checked);
      dmData.tstini.WriteBool('Columns','Exch2',chkExch2.Checked);
      dmData.tstini.WriteBool('Columns','Mult1',chkMult1.Checked);
      dmData.tstini.WriteBool('Columns','Mult2',chkMult2.Checked); //points,band, prefix
      dmData.tstini.WriteBool('Columns','Points',chkPoints.Checked);
      dmData.tstini.WriteBool('Columns','Band',chkBand.Checked);
      dmData.tstini.WriteBool('Columns','Prefix',chkWPX.Checked);
      dmData.tstini.WriteBool('Columns','Power',chkPower.Checked);

      dmData.tstini.SaveToDisk;
      LoadBandSettings;
      UpdateSumGrid;
      ShowFields
    end
  finally
    Free
  end
  {$ENDIF}
end;

procedure TfrmTestMain.acDeleteQSOExecute(Sender: TObject);
begin
  //dmData.dsCQRTest.Last;
  //dmData.DeleteContestQSO(dmData.dsCQRTest.Fields[0].AsLongint);
  RefreshData;
  SetQSONrPanel;
  UpdateSumGrid
end;

procedure TfrmTestMain.acEditQSOExecute(Sender: TObject);
begin
      {
  frmEditTestQSO := TfrmEditTestQSO.Create(self);
  try
    frmEditTestQSO.edtDate.Text   := dmData.dsCQRTest.FieldByName('qsodate').AsString;
    frmEditTestQSO.edtTime.Text   := dmData.dsCQRTest.FieldByName('time_on').AsString;
    frmEditTestQSO.edtCall.Text   := dmData.dsCQRTest.FieldByName('call').AsString;
    frmEditTestQSO.edtFreq.Text   := dmData.dsCQRTest.FieldByName('freq').asString;
    frmEditTestQSO.edtMode.Text   := dmData.dsCQRTest.FieldByName('mode').AsString;
    frmEditTestQSO.edtRSTS.Text   := dmData.dsCQRTest.FieldByName('rst_s').AsString;
    frmEditTestQSO.edtRSTR.Text   := dmData.dsCQRTest.FieldByName('rst_r').AsString;
    frmEditTestQSO.edtEXCH1.Text  := dmData.dsCQRTest.FieldByName('exch1').AsString;
    frmEditTestQSO.edtEXCH2.Text  := dmData.dsCQRTest.FieldByName('exch2').AsString;
    frmEditTestQSO.edtName.Text   := dmData.dsCQRTest.FieldByName('name').AsString;
    frmEditTestQSO.edtQTH.Text    := dmData.dsCQRTest.FieldByName('qth').AsString;
    frmEditTestQSO.edtPoints.Text := IntToStr(dmData.dsCQRTest.FieldByName('points').AsInteger);
    frmEditTestQSO.edtPower.Text  := dmData.dsCQRTest.FieldByName('power').AsString;
    frmEditTestQSO.edtWAZ.Text    := dmData.dsCQRTest.FieldByName('waz').AsString;
    frmEditTestQSO.edtITU.Text    := dmData.dsCQRTest.FieldByName('itu').AsString;
    frmEditTestQSO.edtWPX.Text    := dmData.dsCQRTest.FieldByName('wpx').AsString;
    frmEditTestQSO.edtState.Text  := dmData.dsCQRTest.FieldByName('state').AsString;
    frmEditTestQSO.edtIota.Text   := dmData.dsCQRTest.FieldByName('iota').AsString;

    frmEditTestQSO.chkMult1.Checked := dmData.dsCQRTest.FieldByName('mult1').AsString='X';
    frmEditTestQSO.chkMult2.Checked := dmData.dsCQRTest.FieldByName('mult2').AsString='X';
    frmEditTestQSO.ShowModal;

    if frmEditTestQSO.ModalResult = mrOK then
      dmData.EditTestQSO(frmEditTestQSO.edtDate.Text,frmEditTestQSO.edtTime.Text,frmEditTestQSO.edtCall.Text,
                         frmEditTestQSO.edtFreq.Text,frmEditTestQSO.edtMode.Text,frmEditTestQSO.edtRSTS.Text,
                         frmEditTestQSO.edtRSTR.Text,frmEditTestQSO.edtEXCH1.Text,frmEditTestQSO.edtEXCH2.Text,
                         frmEditTestQSO.edtName.Text,frmEditTestQSO.edtQTH.Text,frmEditTestQSO.edtPower.Text,
                         frmEditTestQSO.edtWAZ.Text,frmEditTestQSO.edtITU.Text,frmEditTestQSO.edtWPX.Text,
                         frmEditTestQSO.edtState.Text,frmEditTestQSO.edtIota.Text,StrToInt(frmEditTestQSO.edtPoints.Text),
                         frmEditTestQSO.chkMult1.Checked,frmEditTestQSO.chkMult2.Checked,
                         dmData.dsCQRTest.Fields[0].AsLongInt)

  finally
    frmEditTestQSO.Close
  end  }
end;

procedure TfrmTestMain.AcKeysExecute(Sender: TObject);
begin
  frmKeysPref := TfrmKeysPref.Create(self);
  frmKeysPref.ShowModal;
  frmKeysPref.Free
end;

procedure TfrmTestMain.acNewLogExecute(Sender: TObject);
begin
  //if dmData.ContestDatabase.Connected then
  //  dmData.ContestDatabase.Connected := False;
  with TfrmLogList.Create(self) do
  try
    ShowModal;
    if ModalResult = mrOK then
    begin
      frmTestMain.Caption := 'CQRTest - '+lbFiles.Items.Strings[lbFiles.ItemIndex];
      AfterOpenMainDatabase;
      LoadBandSettings;
      //dmUtils.InsertContestFreq(cmbFreq,dmData.tstini.ReadBool('Details','WARC',False))
    end
  finally
    Free
  end
end;

procedure TfrmTestMain.acOpenLogExecute(Sender: TObject);
begin
  //if dmData.ContestDatabase.Connected then
  //  dmData.ContestDatabase.Connected := False;
  with TfrmLogList.Create(self) do
  try
    ShowModal;
    if ModalResult = mrOK then
    begin
      frmTestMain.Caption := 'CQRLOG - '+lbFiles.Items.Strings[lbFiles.ItemIndex];
      AfterOpenMainDatabase;
      LoadBandSettings;
      //dmUtils.InsertContestFreq(cmbFreq,dmData.tstini.ReadBool('Details','WARC',False))
    end
  finally
    Free
  end
end;

procedure TfrmTestMain.acProgramExecute(Sender: TObject);
begin
  with TfrmPreferences.Create(self) do
  try
    ShowModal;
    if ModalResult = mrOK then
    begin
      dmUtils.LoadFontSettings(frmTestMain);
      if frmTRXControl.Showing then
        dmUtils.LoadFontSettings(frmTRXControl);
      if frmBandMap.Showing then
        dmUtils.LoadFontSettings(frmBandMap);
      if frmDXCluster.Showing then
        dmUtils.LoadFontSettings(frmDXCluster);
      if frmCWKeys.Showing then
        dmUtils.LoadFontSettings(frmCWKeys)
    end
  finally
    Free
  end
end;

procedure TfrmTestMain.acPropExecute(Sender: TObject);
begin
  frmPropagation.Show
end;

procedure TfrmTestMain.acRefreshTRXExecute(Sender: TObject);
begin

  {
  EnterCriticalsection(frmTRXControl.RigRel);
  try
    frmTRXControl.LoadSettings;
    frmTRXControl.ReloadCfg := True
  finally
    LeaveCriticalsection(frmTRXControl.RigRel)
  end;
  tmrRadio.Enabled := True
  }
end;

procedure TfrmTestMain.acSCPExecute(Sender: TObject);
begin
  frmSCP.Show
end;

procedure TfrmTestMain.acShowDXClusterExecute(Sender: TObject);
begin
  if frmDXCluster.Showing then
    frmDXCluster.BringToFront
  else
    frmDXCluster.Show
end;

procedure TfrmTestMain.acShowFKeysExecute(Sender: TObject);
begin
  if frmCWKeys.Showing then
    frmCWKeys.BringToFront
  else
    frmCWKeys.Show
end;

procedure TfrmTestMain.acShowGraylineExecute(Sender: TObject);
begin
  if frmGrayline.Showing then
    frmGrayline.BringToFront
  else
    frmGrayline.Show
end;

procedure TfrmTestMain.dbgrdMainColumnMoved(Sender: TObject; FromIndex,
  ToIndex: Integer);
begin
  SaveGrid
end;

procedure TfrmTestMain.dbgrdMainColumnSized(Sender: TObject);
begin
  SaveGrid
end;

procedure TfrmTestMain.edtCallChange(Sender: TObject);
begin
  if Length(edtCall.Text) = 0 then
    ClearAll;
  if (Length(edtCall.Text) > 2) and frmSCP.Showing then
  //  frmSCP.mSCP.Text := dmData.GetSCPCalls(edtCall.Text)
end;

procedure TfrmTestMain.edtCallExit(Sender: TObject);
var
  mode, freq : String;
//  qsl_via    : String = '';
begin
  mode := '';
  freq := '';
  if edtCall.Text='' then
    exit;
  if old_call = '' then
  begin
    old_call := edtCall.Text;
    old_mode := cmbMode.Text
  end
  else begin
    if edtCall.Text = old_call then
      exit
  end;
  ShowDXCCInfo;
  ChangeReports;
  CalculateDistanceEtc;
  if frmGrayline.Showing then
  begin
    frmGrayline.s := lblLat.Caption;
    frmGrayline.d := lblLong.Caption;
    frmGrayline.pfx := lblDXCC.Caption;
    frmGrayline.kresli;
  end;
  if not FromDXC then
  begin
    if (frmTRXControl.GetModeFreqNewQSO(mode,freq)) then
    begin
      cmbMode.Text := mode;
      cmbFreq.Text := freq;
    end
  end
end;

procedure TfrmTestMain.edtCallKeyPress(Sender: TObject; var Key: char);
begin
  if key = '\' then
  begin
    GetKeybCWMessage('BackSlash');
    key := #0
  end
end;

procedure TfrmTestMain.edtExchKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
//var
//  s : Integer;
//  tmp : String;

begin
  if key = 9 then
  begin
    key := 0;
    if dmData.ProgramMode = tmRun then
    begin
      dmData.ProgramMode     := tmSP;
      pnlProgramMode.Caption := 'S&P'
    end
    else begin
      dmData.ProgramMode     := tmRun;
      pnlProgramMode.Caption := 'RUN'
    end;
    UpdateFKeyLabels
  end;

  if (key = VK_UP) or (key = VK_DOWN) then
  begin
    key := 0;
    edtCall.SetFocus
  end;

  {
  if (key = VK_UP) then
  begin
    s  := StrToInt(lblRSTR.Caption);
    if (s > 509) and (s < 599) then
      s := s + 10;
    if (s > 50) and (s < 59) then
      inc(s);
    lblRSTR.Caption := IntToStr(s);
    key := 0
  end;

  if (key = VK_DOWN) then
  begin
    s  := StrToInt(lblRSTR.Caption);
    if (s > 519) and (s < 600) then
      s := s - 10;
    if (s > 51) and (s < 60) then
      dec(s);
    lblRSTR.Caption := IntToStr(s);
    key := 0
  end
  }
end;

procedure TfrmTestMain.edtExchKeyPress(Sender: TObject; var Key: char);
begin
  if key = '\' then
  begin
    GetKeybCWMessage('BackSlash');
    key := #0
  end
end;

procedure TfrmTestMain.edtExchKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
//var
//  s : char;
//  tmp : String;
begin
  if (key = 13) then
  begin
    if old_call <> edtCall.Text then
      GetKeybCWMessage('CallChange');
    GetKeybCWMessage('NoCallChange');
    AfterSaveQSO;
    Key := 0
  end
end;

procedure TfrmTestMain.FormWindowStateChange(Sender: TObject);
begin
  if WindowState = wsMinimized then //because of bug in Lazarus, I have to do it myself
  begin
    minimalize := True;
    if frmDXCluster.Showing then
    begin
      frmDXCluster.SavePosition;
      MinDXCluster := True;
    end;
    if frmGrayline.Showing then
    begin
      dmUtils.SaveForm(frmGrayline);
      MinGrayLine := True;
    end;
    if frmTRXControl.Showing then
    begin
      frmTRXControl.SavePosition;
      MinTRXControl := True;
    end;
    if frmQSODetails.Showing then
    begin
      MinQSODetails := True;
    end;
  end;
end;

procedure TfrmTestMain.MenuItem17Click(Sender: TObject);
begin
  ShowHelp;
end;

procedure TfrmTestMain.acPreferencesExecute(Sender: TObject);
begin
  with TfrmPreferences.Create(self) do
  try
    ShowModal;
    if ModalResult = mrOk then
    begin
      dmUtils.LoadFontSettings(frmTestMain);
      if frmTRXControl.Showing then
        dmUtils.LoadFontSettings(frmTRXControl);
      if frmQSODetails.Showing then
        frmQSODetails.LoadFonts
    end
  finally
    Free
  end
end;

procedure TfrmTestMain.acShowBandMapExecute(Sender: TObject);
begin
  if frmBandMap.Showing then
    frmBandMap.BringToFront
  else
    frmBandMap.Show
end;

procedure TfrmTestMain.acShowTRXControlExecute(Sender: TObject);
begin
  if frmTRXControl.Showing then
    frmTRXControl.BringToFront
  else
    frmTRXControl.Show
end;

procedure TfrmTestMain.acXplanetExecute(Sender: TObject);
begin
  dmUtils.RunXplanet;
end;

procedure TfrmTestMain.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
var
//  tmp:   string;
  speed: integer = 0;
//  i:     integer = 0;
//  ShowMain: boolean = False;
begin
  if key = VK_ESCAPE then
  begin
    if EscFirstTime then
    begin
      if edtCall.Text = '' then
        edtCall.SetFocus
      else
        edtCall.Text := ''; // OnChange calls ClearAll;
      EscFirstTime   := False;
      old_ccall      := '';
      old_cfreq      := '';
      old_cmode      := '';
    end
    else
    begin
      CWint.StopSending;
      EscFirstTime   := True;
      tmrESC.Enabled := True;
    end;
  end
  else
    EscFirstTime := False;

  if key = VK_F1 then
  begin
    if not dmData.CWStopped then
      CWint.SendText(dmUtils.GetCWMessage('F1',edtCall.Text,lblRSTR.Caption,'','',pnlQSONR.Caption));
    key := 0
  end;
  if key = VK_F2 then
  begin
    if not dmData.CWStopped then
      CWint.SendText(dmUtils.GetCWMessage('F2',edtCall.Text,lblRSTR.Caption,'','',pnlQSONR.Caption));
    key := 0
  end;
  if key = VK_F3 then
  begin
    if not dmData.CWStopped then
      CWint.SendText(dmUtils.GetCWMessage('F3',edtCall.Text,lblRSTR.Caption,'','',pnlQSONR.Caption));
    key := 0
  end;
  if key = VK_F4 then
  begin
    if not dmData.CWStopped then
      CWint.SendText(dmUtils.GetCWMessage('F4',edtCall.Text,lblRSTR.Caption,'','',pnlQSONR.Caption));
    key := 0
  end;
  if key = VK_F5 then
  begin
    if not dmData.CWStopped then
      CWint.SendText(dmUtils.GetCWMessage('F5',edtCall.Text,lblRSTR.Caption,'','',pnlQSONR.Caption));
    key := 0
  end;
  if key = VK_F6 then
  begin
    if not dmData.CWStopped then
      CWint.SendText(dmUtils.GetCWMessage('F6',edtCall.Text,lblRSTR.Caption,'','',pnlQSONR.Caption));
    key := 0
  end;
  if key = VK_F7 then
  begin
    if not dmData.CWStopped then
      CWint.SendText(dmUtils.GetCWMessage('F7',edtCall.Text,lblRSTR.Caption,'','',pnlQSONR.Caption));
    key := 0
  end;
  if key = VK_F8 then
  begin
    if not dmData.CWStopped then
      CWint.SendText(dmUtils.GetCWMessage('F8',edtCall.Text,lblRSTR.Caption,'','',pnlQSONR.Caption));
    key := 0
  end;
  if key = VK_F9 then
  begin
    if not dmData.CWStopped then
      CWint.SendText(dmUtils.GetCWMessage('F9',edtCall.Text,lblRSTR.Caption,'','',pnlQSONR.Caption));
    key := 0
  end;
  if key = VK_F10 then
  begin
    if not dmData.CWStopped then
      CWint.SendText(dmUtils.GetCWMessage('F10',edtCall.Text,lblRSTR.Caption,'','',pnlQSONR.Caption));
    key := 0
  end;

  if (key = 33) then//pgup
  begin
    speed := CWint.GetSpeed + 2;
    CWint.SetSpeed(speed);
    lblCWSpeed.Caption := IntToStr(speed);// + 'WPM';
  end;

  if (key = 34) then//pgup
  begin
    speed := CWint.GetSpeed - 2;
    CWint.SetSpeed(speed);
    lblCWSpeed.Caption := IntToStr(speed);// + 'WPM';
  end;

  if (Shift = [ssAlt]) and (key = VK_F) then
  begin
    dmUtils.EnterFreq;
    key := 0;
  end;

  if (Shift = [ssCTRL]) and (key = VK_Y) then
    acDeleteQSO.Execute;

  if (Shift = [ssCTRL]) and (key = VK_E) then
    acEditQSO.Execute;

  if (Shift = [ssCtrl]) and (key = VK_Q) then
    //why all this didnt work directly in action?
  begin
    acClose.Execute;
    key := 0;
    exit;
  end;

  if (Shift = [ssCtrl]) and (key = VK_P) then
  begin
    acPreferences.Execute;
    key := 0;
  end;

  if (Shift = [ssCtrl]) and (key = VK_O) then
  begin
    key := 0;
  end;

  if (Shift = [ssCtrl]) and (key = VK_I) then
  begin
    key := 0;
  end;

  if ((Shift = [ssCtrl]) and (key = VK_R)) then
  begin
  end;
  if ((Shift = [ssCtrl]) and (key = VK_A)) then
  begin
    acAddToBandMap.Execute;
    key := 0;
  end;

  if ((Shift = [ssAlt]) and (key = VK_H)) then
  begin
    ShowHelp;
    key := 0;
  end;

  if ((Shift = [ssAlt]) and (key = VK_F2)) then
  begin
    key := 0;
  end;

  if ((Shift = [ssCTRL]) and (key = VK_1)) then
    frmTRXControl.rbRadio1.Checked := True;
  if ((Shift = [ssCTRL]) and (key = VK_2)) then
    frmTRXControl.rbRadio2.Checked := True;
  if ((Shift = [ssCTRL]) and (key = VK_0)) then
    frmTRXControl.DisableSplit;

  if ((Shift = [ssAlt]) and (key = VK_V)) then
  begin
    //ChangeBand(True,dmData.tstini.ReadBool('Details','WARC',False));
    key := 0
  end;

  if ((Shift = [ssAlt]) and (key = VK_B)) then
  begin
    //ChangeBand(False,dmData.tstini.ReadBool('Details','WARC',False));
    key := 0
  end;

  if ((Shift = [ssAlt]) and (key = VK_M)) then
  begin
    if cmbMode.Text = 'CW' then
      ChangeMode('SSB')
    else
      ChangeMode('CW');
    key := 0
  end;

  if ((Shift = [ssAlt]) and (key = VK_K)) then
  begin
    dmData.CWStopped := NOT dmData.CWStopped;
    ChangeMode(cmbMode.Text)
  end;

end;

procedure TfrmTestMain.FormKeyPress(Sender: TObject; var Key: char);
var
//  i:    integer;
  tmp:  string = '';
  f:    currency = 0;
  call: string = '';
  freq: string = '';
begin
  case key of
  {  #9 : begin
          if key = #9 then
          begin
            key := #0;
            if dmData.ProgramMode = tmRun then
            begin
              dmData.ProgramMode     := tmSP;
              pnlProgramMode.Caption := 'S&P'
            end
            else begin
              dmData.ProgramMode     := tmRun;
              pnlProgramMode.Caption := 'RUN'
            end;
            UpdateFKeyLabels
          end
         end;}
    #13:
      begin                     //enter
        key := #0;
      end;
    #12:
      begin                    // CTRL+L
      end;
    #96:
      begin
        if edtCall.Text <> '' then
        begin
          if TryStrToCurr(cmbFreq.Text, f) then
          begin
            f   := f * 1000;
            tmp := 'DX ' + FloatToStrF(f, ffFixed, 8, 1) + ' ' + edtCall.Text;
          end;
        end
        else
        begin
          dmData.Q.SQL.Text :=
            'SELECT FIRST(1) callsign,freq FROM cqrlog_main ORDER BY qsodate DESC, time_on DESC';
          dmData.trQ.StartTransaction;
          if dmData.DebugLevel >= 1 then
            Writeln(dmData.Q.SQL.Text);
          dmData.Q.Open();
          call := dmData.Q.Fields[0].AsString;
          freq := FloatToStrF(dmData.Q.Fields[1].AsCurrency * 1000, ffFixed, 8, 1);
          dmData.Q.Close();
          dmData.trQ.Rollback;
          tmp := 'DX ' + freq + ' ' + call
        end;
        if (call = '') and (edtCall.Text = '') then
          exit;
        with TfrmSendSpot.Create(self) do
          try
            edtSpot.Text := tmp + ' ';
            ShowModal;
            if ModalResult = mrOk then
            begin
              frmDXCluster.edtCommand.Text := trim(edtSpot.Text);
              if frmDXCluster.ConTelnet then
                frmDXCluster.SendCommand(frmDXCluster.edtCommand.Text);
              frmDXCluster.edtCommand.Clear;
            end;
          finally
            Free
          end;
        Key := #0;
      end;
    #43:
      begin  //+ key
        acAddToBandMap.Execute;
        key := #0;
      end;
    end; //case
end;

procedure TfrmTestMain.edtStartTimeKeyPress(Sender: TObject; var Key: char);
begin
  if not ((key in ['0'..'9']) or (key = ':') or (key = #40) or (key = #38) or
    (key = #32)) then
    key := #0;
end;

procedure TfrmTestMain.tmrESCTimer(Sender: TObject);
begin
  EscFirstTime   := False;
  tmrESC.Enabled := False;
end;

procedure TfrmTestMain.ChangeReports;
begin
end;

procedure TfrmTestMain.CalculateDistanceEtc;
var
  azim, qra, myloc: string;
  lat, long: currency;
  SunRise, SunSet: TDateTime;
  delta:     currency;
  inUTC:     boolean;
//  SunDelta:  currency = 0;
begin

  inUTC := cqrini.ReadBool('Program','SunUTC',False);
  delta := cqrini.ReadFloat('Program','offset',0);
  //SunDelta := cqrini.ReadFloat('Program','SunOffset',0);
  if lblDXCC.Caption = '!' then
  begin
    lblQRA.Caption := '';
    lblAzi.Caption := '';
    exit
  end;
  qra   := '';
  azim  := '';
  myloc := '';//dmData.tstini.ReadString('Basic','Gird','');
  if (lblLat.Caption <> '') and (lblLong.Caption <> '') then
  begin
    dmUtils.GetRealCoordinate(lblLat.Caption,lblLong.Caption,lat,long);
    dmUtils.CalcSunRiseSunSet(lat,long,SunRise,SunSet);
    if inUTC then
    begin
      SunRise := SunRise - (delta/24);
      SunSet  := SunSet - (delta/24)
    end;
    lblTarSunRise.Caption := TimeToStr(SunRise);
    lblTarSunSet.Caption  := TimeToStr(SunSet);
    dmUtils.DistanceFromCoordinate(myloc,lat,long,qra,azim)
  end
  else
    dmUtils.DistanceFromPrefixMyLoc(myloc,lblDXCC.Caption, qra, azim);
  {end;}
  if ((qra <>'') and (azim<>'')) then
  begin
    lblQRA.Caption := qra + ' km';
    lblAzi.Caption := azim
  end
end;

procedure TfrmTestMain.SavePosition;
begin
  dmUtils.SaveWindowPos(frmTestMain)
end;

procedure TfrmTestMain.AppIdle(Sender: TObject; var Handled: boolean);
begin
  Handled := True;
end;

procedure TfrmTestMain.NewQSOFromSpot(call, freq, mode: string);
var
  etmp : extended;
begin
  if (old_ccall <> call) or (old_cmode <> mode) or (old_cfreq <> freq) then
  begin
    old_ccall := call;
    old_cmode := mode;
    old_cfreq := freq;

    ClearAll;
    etmp    := dmUtils.MyStrToFloat(freq);
    etmp    := etmp / 1000;
    freq    := FloatToStrF(etmp, ffFixed, 8, 4);
    {
    Writeln('edtCall: ',edtCall.Text);
    Writeln('cmbFreq: ',cmbFreq.Text);
    Writeln('cmbMode: ',cmbMode.Text);
    Writeln('oldCall: ',old_ccall);
    Writeln('oldFreq: ',old_cfreq);
    Writeln('oldMode: ',old_cmode);
    Writeln('Call: ',call);
    Writeln('Freq: ',freq);
    Writeln('Mode: ',mode);
    }
    FromDXC := True;
    edtCall.Text := call;
    cmbFreq.Text := freq;
    cmbMode.Text := mode;
    etmp    := etmp * 1000000;
    freq    := FloatToStr(etmp);
    frmTRXControl.SetModeFreq(mode, freq);
    edtCallExit(nil);
    BringToFront;
    exit
  end
end;

procedure TfrmTestMain.ShowWindows;
begin
  if frmTRXControl.Showing then
    frmTRXControl.BringToFront;
  if frmBandMap.Showing then
    frmBandMap.BringToFront;
  if frmDXCluster.Showing then
    frmDXCluster.BringToFront;
  if frmQSODetails.Showing then
    frmQSODetails.BringToFront;
  frmTestMain.BringToFront;
end;

procedure TfrmTestMain.UpdateFKeyLabels;
begin
  {$IFDEF CONTEST}
  if not dmData.ContestDatabase.Connected then
    exit;
  if dmData.ProgramMode = tmRun then
  begin
    frmCWKeys.btnF1.Caption  := dmData.tstini.ReadString('CW','CapF1','CQ');
    frmCWKeys.btnF2.Caption  := dmData.tstini.ReadString('CW','CapF2','F2');
    frmCWKeys.btnF3.Caption  := dmData.tstini.ReadString('CW','CapF3','F3');
    frmCWKeys.btnF4.Caption  := dmData.tstini.ReadString('CW','CapF4','F4');
    frmCWKeys.btnF5.Caption  := dmData.tstini.ReadString('CW','CapF5','F5');
    frmCWKeys.btnF6.Caption  := dmData.tstini.ReadString('CW','CapF6','F6');
    frmCWKeys.btnF7.Caption  := dmData.tstini.ReadString('CW','CapF7','F7');
    frmCWKeys.btnF8.Caption  := dmData.tstini.ReadString('CW','CapF8','F8');
    frmCWKeys.btnF9.Caption  := dmData.tstini.ReadString('CW','CapF9','F9');
    frmCWKeys.btnF10.Caption := dmData.tstini.ReadString('CW','CapF10','F10')
  end
  else begin
    frmCWKeys.btnF1.Caption  := dmData.tstini.ReadString('CW','SPCapF1','CQ');
    frmCWKeys.btnF2.Caption  := dmData.tstini.ReadString('CW','SPCapF2','F2');
    frmCWKeys.btnF3.Caption  := dmData.tstini.ReadString('CW','SPCapF3','F3');
    frmCWKeys.btnF4.Caption  := dmData.tstini.ReadString('CW','SPCapF4','F4');
    frmCWKeys.btnF5.Caption  := dmData.tstini.ReadString('CW','SPCapF5','F5');
    frmCWKeys.btnF6.Caption  := dmData.tstini.ReadString('CW','SPCapF6','F6');
    frmCWKeys.btnF7.Caption  := dmData.tstini.ReadString('CW','SPCapF7','F7');
    frmCWKeys.btnF8.Caption  := dmData.tstini.ReadString('CW','SPCapF8','F8');
    frmCWKeys.btnF9.Caption  := dmData.tstini.ReadString('CW','SPCapF9','F9');
    frmCWKeys.btnF10.Caption := dmData.tstini.ReadString('CW','SPCapF10','F10')
  end
  {$ENDIF}
end;

procedure TfrmTestMain.SaveOpenedWindows;
begin
  cqrini.WriteBool('C_Windows','GrayLine',frmGrayline.Showing);
  cqrini.WriteBool('C_Windows','DXCluster',frmDXCluster.Showing);
  cqrini.WriteBool('C_Windows','BandMap',frmBandMap.Showing);
  cqrini.WriteBool('C_Windows','TRXControl',frmTRXControl.Showing);
  cqrini.WriteBool('C_Windows','Details',frmQSODetails.Showing);
  cqrini.WriteBool('C_Windows','CWKeys',frmCWKeys.Showing);
  cqrini.WriteBool('C_Windows','Prop',frmPropagation.Showing);
  cqrini.WriteBool('C_Windows','SCP',frmSCP.Showing)
end;

procedure TfrmTestMain.LoadOpenedWindows;
begin
  if cqrini.ReadBool('C_Windows','GrayLine',False) then
    frmGrayline.Show;
  if cqrini.ReadBool('C_Windows','DXCluster',False) then
    frmDXCluster.Show;
  if cqrini.ReadBool('C_Windows','BandMap',False) then
    frmBandMap.Show;
  if cqrini.ReadBool('C_Windows','TRXControl',False) then
    frmTRXControl.Show;
  if cqrini.ReadBool('C_Windows','Details',False) then
    frmQSODetails.Show;
  if cqrini.ReadBool('C_Windows','CWKeys',False) then
    frmCWKeys.Show;
  if cqrini.ReadBool('C_Windows','Prop',False) then
    frmPropagation.Show;
  if cqrini.ReadBool('C_Windows','SCP',False) then
    frmSCP.Show
end;

procedure TfrmTestMain.SetStringGrids(grd : TStringGrid);
var
  a : Array[1..9] of String;
  i : Integer;
begin
  a[1]  := '160m';
  a[2]  := '80m';
  a[3]  := '40m';
  a[4]  := '30m';
  a[5]  := '20m';
  a[6]  := '17m';
  a[7]  := '15m';
  a[8]  := '12m';
  a[9]  := '10m';
  for i:= 1 to 9 do
  begin
    grd.Cells[i,0] := a[i];
    grd.Columns[i].Alignment := taCenter
  end
end;

procedure TfrmTestMain.UpdateSumGrid;
{var
  i,y : Integer;
  tmp : String = '';
  band : Integer = 0;}
begin
  {
  for i:=1 to strgrdSummary.RowCount-3 do
    for y:=1 to strgrdSummary.ColCount-1 do
      strgrdSummary.Cells[y,i] := '0';
  LoadBandSettings;
  //if not dmData.ContestDatabase.Connected then
  //  exit;

  dmData.Qc.Close;
  dmData.Qc.SQL.Text := 'select band,count(*) from cqrtest group by band';
  if dmData.DebugLevel>=1 then Writeln(dmData.Qc.SQL.Text);
  dmData.trQc.StartTransaction;
  try
    dmData.Qc.Open();
    while not dmData.Qc.Eof do
    begin
      tmp  := copy(dmData.Qc.Fields.AsString[0],1,Length(dmData.Qc.Fields.AsString[0])-1);
      if not TryStrToInt(tmp,band) then
        band := 0;
      Writeln('bnd:',dmData.Qc.Fields.AsString[0]);
      Writeln('tmp:',tmp);

      case band of
        160 : strgrdSummary.Cells[p160,1] := IntToStr(dmData.Qc.Fields.AsInteger[1]);
        80  : strgrdSummary.Cells[p80,1]  := IntToStr(dmData.Qc.Fields.AsInteger[1]);
        40  : strgrdSummary.Cells[p40,1]  := IntToStr(dmData.Qc.Fields.AsInteger[1]);
        30  : if p30 > 0 then strgrdSummary.Cells[p30,1] := IntToStr(dmData.Qc.Fields.AsInteger[1]);
        20  : strgrdSummary.Cells[p20,1] := IntToStr(dmData.Qc.Fields.AsInteger[1]);
        17  : if p17 > 0 then strgrdSummary.Cells[p17,1] := IntToStr(dmData.Qc.Fields.AsInteger[1]);
        15  : strgrdSummary.Cells[p15,1] := IntToStr(dmData.Qc.Fields.AsInteger[1]);
        12  : if p12 > 0 then strgrdSummary.Cells[p12,1] := IntToStr(dmData.Qc.Fields.AsInteger[1]);
        10  : strgrdSummary.Cells[p10,1] := IntToStr(dmData.Qc.Fields.AsInteger[1])
      end;
      dmData.Qc.Next
    end
  finally
    dmData.Qc.Close;
    dmData.trQc.RollBack;
    dmData.Qc.SQL.Text := ''
  end
  }
end;

procedure TfrmTestMain.DisableAll;
begin
  edtCall.Enabled   := False;
  edtExch.Enabled   := False;
  acCWMessages.Enabled := False;
  acCWType.Enabled := False;
  acShowFKeys.Enabled := False
end;

procedure TfrmTestMain.EnableAll;
begin
  edtCall.Enabled   := True;
  edtExch.Enabled   := True;
  acCWMessages.Enabled := True;
  acCWType.Enabled := True;
  acShowFKeys.Enabled := True
end;

procedure TfrmTestMain.ShowFields;

  procedure ChangeVis(Column : String; IfShow : Boolean);
  var
    i : Integer;
  begin
    for i:=0 to dbgrdMain.Columns.Count-1 do
    begin
      if UpperCase(dbgrdMain.Columns[i].DisplayName) = UpperCase(Column) then
       dbgrdMain.Columns[i].Visible := IfShow
    end
  end;

begin
  {$IFDEF CONTEST}
  dbgrdMain.DataSource := dmData.dsrCQRTest;
  dbgrdMain.ResetColWidths;
  LoadGrid;
  if dmData.ContestDatabase.Connected then
  begin
    ChangeVis('QSODATE',dmData.tstini.ReadBool('Columns','Date',True));
    ChangeVis('TIMEW_ON',dmData.tstini.ReadBool('Columns','time_on',True));
    ChangeVis('CALL',dmData.tstini.ReadBool('Columns','CallSign',True));
    ChangeVis('MODE',dmData.tstini.ReadBool('Columns','Mode',True));
    ChangeVis('FREQ',dmData.tstini.ReadBool('Columns','Freq',True));
    ChangeVis('RST_S',dmData.tstini.ReadBool('Columns','RST_S',False));
    ChangeVis('RST_R',dmData.tstini.ReadBool('Columns','RST_R',False));
    ChangeVis('NAME',dmData.tstini.ReadBool('Columns','Name',False));
    ChangeVis('QTH',dmData.tstini.ReadBool('Columns','QTH',False));
    ChangeVis('IOTA',dmData.tstini.ReadBool('Columns','IOTA',False));
    ChangeVis('dxcc_ref',dmData.tstini.ReadBool('Columns','DXCC',True));
    ChangeVis('WAZ',dmData.tstini.ReadBool('Columns','WAZ',False));
    ChangeVis('ITU',dmData.tstini.ReadBool('Columns','ITU',False));
    ChangeVis('STATE',dmData.tstini.ReadBool('Columns','State',False));
    ChangeVis('CONT',dmData.tstini.ReadBool('Columns','Cont',False));
    ChangeVis('QSO_NR',dmData.tstini.ReadBool('Columns','QSONR',True));
    ChangeVis('EXCH1',dmData.tstini.ReadBool('Columns','Exch1',True));
    ChangeVis('EXCH2',dmData.tstini.ReadBool('Columns','Exch2',True));
    ChangeVis('MULT1',dmData.tstini.ReadBool('Columns','Mult1',True));
    ChangeVis('MULT2',dmData.tstini.ReadBool('Columns','Mult2',True));
    ChangeVis('POINTS',dmData.tstini.ReadBool('Columns','Points',True));
    ChangeVis('BAND',dmData.tstini.ReadBool('Columns','Band',True));
    ChangeVis('WPX',dmData.tstini.ReadBool('Columns','Prefix',False));
    ChangeVis('POWER',dmData.tstini.ReadBool('Columns','Power',False))
  end;
  ChangeVis('id_cqrtest',False);
  dbgrdMain.Repaint
  {$ENDIF}
end;

procedure TfrmTestMain.LoadGrid;
var
  Grid: TDBGrid;
  {Section, }Ident: string;
//  i, j: Integer;
  l   : TStringList;
  y : Integer;
  D : TDataSource;
begin
  l    := TStringList.Create;
  try
    Grid := dbgrdMain;
    //Section := Grid.Name;
    l.Clear;
    //dmData.tstini.ReadSection(Section,l);
    l.Text := Trim(l.Text);
    if l.Text='' then
      exit;
    D := Grid.DataSource;
    Grid.DataSource := nil;
    Grid.BeginUpdate;
    try
      Grid.Columns.Clear;
      for y := 0 to l.Count-1 do
      begin
        Ident := l[y];
        Grid.Columns.Add.DisplayName       := Ident;
        TColumn(Grid.Columns[y]).FieldName := Ident;
        //Grid.Columns[y].Width := dmData.tstini.ReadInteger(section,Ident,100)
      end
    finally
      Grid.DataSource := D;
      Grid.EndUpdate()
    end
  finally
    l.Free
  end
end;

procedure TfrmTestMain.SaveGrid;
{var
  Grid : TDBGrid;
  Ident: string;
  i,j,y : Integer;
  l : TStringList;}
begin
  {l   := TStringList.Create;
  try
    Grid:= dbgrdMain;
    Section:= Grid.Name;
    l.Clear;
    //dmData.tstini.ReadSection(Section,l);
    l.Text := Trim(l.Text);
    if l.Text<>'' then
    begin //delete old settings
      for y:=0 to l.Count-1 do
        //dmData.tstini.DeleteKey(Section,l[y])
    end;
    for j:= 0 to Grid.Columns.Count - 1 do
    begin
      Ident:= TColumn(Grid.Columns[j]).FieldName;
      //dmData.tstini.WriteString(Section, Ident, IntToStr(Grid.Columns[j].Width))
    end
  finally
    //dmData.tstini.SaveToDisk;
    l.Free
  end}
end;

procedure TfrmTestMain.LoadBandSettings;
var
  ShowWARC : Boolean = False;
//  i : Integer;
begin
  //if dmData.ContestDatabase.Connected then
    //ShowWARC := dmData.tstini.ReadBool('Details','WARC',False);

  if not ShowWARC then
  begin
    strgrdSummary.Columns[3].Visible := False;
    strgrdSummary.Columns[5].Visible := False;
    strgrdSummary.Columns[7].Visible := False;

    strgrdMissing.Columns[3].Visible := False;
    strgrdMissing.Columns[5].Visible := False;
    strgrdMissing.Columns[7].Visible := False;

    strgrdMissingMult.Columns[3].Visible := False;
    strgrdMissingMult.Columns[5].Visible := False;
    strgrdMissingMult.Columns[7].Visible := False;

    p160 := 1;
    p80  := 2;
    p40  := 3;
    p30  := -1;
    p20  := 4;
    p17  := -1;
    p15  := 5;
    p12  := -1;
    p10  := 6
  end
  else begin
    p160 := 1;
    p80  := 2;
    p40  := 3;
    p30  := 4;
    p20  := 5;
    p17  := 6;
    p15  := 7;
    p12  := 8;
    p10  := 9
  end
end;

procedure TfrmTestMain.SetQSONrPanel;
begin
  //dmData.dsCQRTest.Last;
  //pnlQSONr.Caption := IntToStr(dmData.dsCQRTest.Fields[3].AsInteger+1)
end;

procedure TfrmTestMain.AfterOpenMainDatabase;
begin
  ShowFields;
  SetQSONrPanel;
  UpdateFKeyLabels;
  EnableAll
end;

procedure TfrmTestMain.CheckForQSO;
{var
  i : Integer;
  band : Integer;
  tmp : String;}
begin
  {
  for i:=0 to strgrdMissing.ColCount -1 do
    strgrdMissing.Cells[i,1] := 'X';
  lblMissCall.Caption := edtCall.Text;
  dmData.Qc.Close;
  dmData.Qc.SQL.Text := 'SELECT  distinct band FROM cqrtest where call = '+QuotedStr(edtCall.Text);
  if dmData.DebugLevel>=1 then Writeln(dmData.Qc.SQL.Text);
  try
    dmData.trQc.StartTransaction;
    dmData.Qc.Open;
    tmp  := copy(dmData.Qc.Fields.AsString[0],1,Length(dmData.Qc.Fields.AsString[0])-1);
    if not TryStrToInt(tmp,band) then
      band := 0;
    case band of
      160 : strgrdMissing.Cells[p160,1] := '';
      80  : strgrdMissing.Cells[p80,1]  := '';
      40  : strgrdMissing.Cells[p40,1]  := '';
      30  : if p30 > 0 then strgrdMissing.Cells[p30,1] := '';
      20  : strgrdMissing.Cells[p20,1] := '';
      17  : if p17 > 0 then strgrdMissing.Cells[p17,1] := '';
      15  : strgrdMissing.Cells[p15,1] := '';
      12  : if p12 > 0 then strgrdMissing.Cells[p12,1] := '';
      10  : strgrdMissing.Cells[p10,1] := ''
    end
  finally
    dmData.Qc.Close(etmRollback)
  end}
end;

procedure TfrmTestMain.RefreshData;
begin
  {
  dmData.dsCQRTest.DisableControls;
  try
    dmData.dsCQRTest.Close;
    dmData.dsCQRTest.Open;
    dmData.dsCQRTest.Last
  finally
    dmData.dsCQRTest.EnableControls
  end
  }
end;

procedure TfrmTestMain.ChangeMode(mode : String);
begin
  Writeln('cmbMode.Text:',cmbMode.Text);
  if mode = 'CW' then
  begin
    if cmbMode.Text = 'SSB' then
      dmData.CWStopped := False;
    lblRSTS.Caption := '599';
    lblRSTR.Caption := '599';
    frmTRXControl.SetModeFreq('CW',cmbFreq.Text);
    if dmData.CWStopped then
      sbNewTestQSO.Panels[0].Text := 'CW sending stopped!!'
    else
      sbNewTestQSO.Panels[0].Text := ''
  end
  else begin
    lblRSTS.Caption := '59';
    lblRSTR.Caption := '59';
    frmTRXControl.SetModeFreq('SSB',cmbFreq.Text);
    sbNewTestQSO.Panels[0].Text := '';
    dmData.CWStopped := True
  end;
  //frmTRXControl.SetModeFreq(mode,FloatToStr(frmTRXControl.GetFreqHz));
  cmbMode.Text := mode
end;

procedure TfrmTestMain.AfterSaveQSO;
{var
  t : String;
  tmp : String;
  nr  : String;
  n   : Integer;
  a   : TExplodeArray;
  d   : String;
  exch1 : String = '';
  exch2 : String = '';
  ex1   : Boolean;
  ex2   : Boolean;
  rstr  : String;}
begin
{  ex1  := False; //UpperCase(trim(dmData.tstini.ReadString('Details','Exch2','None'))) <> 'NONE';
  ex2  := False; //UpperCase(trim(dmData.tstini.ReadString('Details','Exch2','None'))) <> 'NONE';
  rstr := lblRSTR.Caption;

  SetLength(a,0);
  a := dmUtils.Explode(' ',edtExch.Text);
  Writeln('Len:',Length(a));
  for n:=0 to Length(a)-1 do
    Writeln('a[',n,']=',a[n]);
  case Length(a) of
    1 : begin
          if ex1 then
          begin
            exch1 := a[0];
            exch2 := ''
          end
          else
            rstr := a[0]
        end;
    2 : begin
          if ex2 then
          begin
            exch1 := a[0];
            exch2 := a[1]
          end
          else begin
            exch1 := a[1];
            rstr  := a[0]
          end
        end;
    3 : begin
          rstr  := a[0];
          exch1 := a[1];
          exch2 := a[2]
        end
  end;


  t := copy(lblTime.Caption,Length(lblTime.Caption)-7,5);
  d := copy(lblTime.Caption,1,10);
  tmp := edtExch.Text;

  //SaveContestQSO(date : TDateTime;time_on,call,rst_s,rst_r,exch1,exch2,freq,mode,
  //               waz,itu,dxcc_ref : String);
  //dmData.SaveContestQSO(dmUtils.StrToDateFormat(d),t,edtCall.Text,lblRSTS.Caption,rstr,
  //                      exch1,exch2,cmbFreq.Text,cmbMode.Text,lblWAZ.Caption,
  //                      lblITU.Caption,lblDXCC.Caption);
  edtCall.Text := '';
  RefreshData;
  SetQSONrPanel;
  UpdateSumGrid}
end;

function TfrmTestMain.GetKeybCWMessage(KeyAction : String) : String;
var
  m    : String = '';
  i    : Integer = 0;
  //mess : String = '';
  fp   : String = '';
  sp   : String = '';
  chsp : Boolean = False;
  chfp : Boolean = False;
begin
  Result := '';
  if dmData.CWStopped then
    exit;

  if dmData.ProgramMode = tmRun then
    m := 'R'
  else
    m := 'S';
  if KeyAction = 'CallChange' then
  begin
    case cqrini.ReadInteger('KeysPref',m+KeyAction,0) of
      0 : Result := '';                   // send nothing
      1 : begin
            if (Length(edtCall.Text) > 4) and (Length(old_call) > 4) then
            begin
              fp := copy(edtCall.Text,1,3);
              sp := copy(edtCall.Text,4,Length(edtCall.Text)-3);
              Writeln('FP:',fp);
              Writeln('SP:',sp);
              Writeln('fp_old_call:',copy(old_call,1,3));
              Writeln('sp_old_call:',copy(old_call,4,Length(old_call)-3));
              if fp <> copy(old_call,1,3) then
              begin
                Result := fp;
                chfp   := True
              end;
              if sp <> copy(old_call,4,Length(old_call)-3) then
              begin
                Result := sp;
                chsp   := True
              end;
              if chfp and chsp then
                Result := edtCall.Text
            end;
            Result := Result + '   '
          end;
      2 : Result := edtCall.Text + '   ' // send whole call
    end; //case
  if dmData.DebugLevel>=1 then Writeln(m+KeyAction,':',Result);
    exit
  end;


  i := cqrini.ReadInteger('KeysPref',m+KeyAction,0);
  case i of
    0 : Result := '';
    1..10 : Result := dmUtils.GetCWMessage('F'+IntToStr(i),edtCall.Text,lblRSTS.Caption,
                                          '','',pnlQSONr.Caption);
    11 : Result := dmUtils.GetCWMessage('',edtCall.Text,lblRSTS.Caption,'',
                                       cqrini.ReadString('KeysPref',m+KeyAction+'C','TU'),
                                       pnlQSONr.Caption)
  end; //case
  if dmData.DebugLevel>=1 then Writeln(m+KeyAction,':',Result)
end;

procedure TfrmTestMain.ChangeBand(up,warc : Boolean);
{var
  band  : Word = 0;
  sband : String = '';
  freq  : Double = 0;
  mode  : String = '';
}
begin
  {$IFDEF CONTEST}
  band  := dmUtils.GetBandFromFreq(cmbFreq.Text);
  sband := IntToStr(band);
  mode  := cmbMode.Text;
  freq  := StrToFloat(cmbFreq.Text);

  dmData.tstini.WriteString('LastModeFreq',sband+mode,cmbFreq.Text);
  dmData.tstini.SaveToDisk;

  case band of
    160 : begin
            if up then
            begin
              if mode = 'CW' then
                freq := dmData.tstini.ReadFloat('LastModeFreq','80CW',3.50)*1000000
              else
                freq := dmData.tstini.ReadFloat('LastModeFreq','80SSB',3.70)*1000000
            end
            else begin
              if mode = 'CW' then
                freq := dmData.tstini.ReadFloat('LastModeFreq','10CW',28.0)*1000000
              else
                freq := dmData.tstini.ReadFloat('LastModeFreq','10SSB',28.50)*1000000
            end
          end;
    80  : begin
            if up then
            begin
              if mode = 'CW' then
                freq := dmData.tstini.ReadFloat('LastModeFreq','40CW',7.0)*1000000
              else
                freq := dmData.tstini.ReadFloat('LastModeFreq','40SSB',7.06)*1000000
            end
            else begin
              if mode = 'CW' then
                freq := dmData.tstini.ReadFloat('LastModeFreq','160CW',1.80)*1000000
              else
                freq := dmData.tstini.ReadFloat('LastModeFreq','160SSB',1.86)*1000000
            end
          end;
    40  : begin
            if up then
            begin
              if warc then
              begin
                if mode = 'CW' then
                  freq := dmData.tstini.ReadFloat('LastModeFreq','30CW',10.1)*1000000
                else
                  freq := dmData.tstini.ReadFloat('LastModeFreq','30SSB',10.12)*1000000
              end
              else begin
                if mode = 'CW' then
                  freq := dmData.tstini.ReadFloat('LastModeFreq','20CW',14.0)*1000000
                else
                  freq := dmData.tstini.ReadFloat('LastModeFreq','20SSB',14.20)*1000000
              end
            end
            else begin
              if mode = 'CW' then
                freq := dmData.tstini.ReadFloat('LastModeFreq','80CW',3.5)*1000000
              else
                freq := dmData.tstini.ReadFloat('LastModeFreq','80SSB',3.7)*1000000
            end
          end;
    30  : begin
            if up then
            begin
              if mode = 'CW' then
                freq := dmData.tstini.ReadFloat('LastModeFreq','20CW',14.0)*1000000
              else
                freq := dmData.tstini.ReadFloat('LastModeFreq','20SSB',14.2)*1000000
            end
            else begin
              if mode = 'CW' then
                freq := dmData.tstini.ReadFloat('LastModeFreq','40CW',7.00)*1000000
              else
                freq := dmData.tstini.ReadFloat('LastModeFreq','40SSB',7.06)*1000000
            end
          end;
    20  : begin
            if up then
            begin
              if warc then
              begin
                if mode = 'CW' then
                  freq := dmData.tstini.ReadFloat('LastModeFreq','17CW',18.068)*1000000
                else
                  freq := dmData.tstini.ReadFloat('LastModeFreq','17SSB',18.110)*1000000
              end
              else begin
                if mode = 'CW' then
                  freq := dmData.tstini.ReadFloat('LastModeFreq','15CW',21.0)*1000000
                else
                  freq := dmData.tstini.ReadFloat('LastModeFreq','15SSB',21.20)*1000000
              end
            end
            else begin
              if warc then
              begin
                if mode = 'CW' then
                  freq := dmData.tstini.ReadFloat('LastModeFreq','30CW',10.1)*1000000
                else
                  freq := dmData.tstini.ReadFloat('LastModeFreq','30SSB',10.12)*1000000
              end
              else begin
                if mode = 'CW' then
                  freq := dmData.tstini.ReadFloat('LastModeFreq','40CW',7.0)*1000000
                else
                  freq := dmData.tstini.ReadFloat('LastModeFreq','40SSB',7.06)*1000000
              end
            end
          end;
    17  : begin
            if up then
            begin
              if mode = 'CW' then
                freq := dmData.tstini.ReadFloat('LastModeFreq','15CW',21.0)*1000000
              else
                freq := dmData.tstini.ReadFloat('LastModeFreq','15SSB',21.2)*1000000
            end
            else begin
              if mode = 'CW' then
                freq := dmData.tstini.ReadFloat('LastModeFreq','20CW',14.00)*1000000
              else
                freq := dmData.tstini.ReadFloat('LastModeFreq','20SSB',14.2)*1000000
            end
          end;
    15  : begin
            if up then
            begin
              if warc then
              begin
                if mode = 'CW' then
                  freq := dmData.tstini.ReadFloat('LastModeFreq','12CW',24.890)*1000000
                else
                  freq := dmData.tstini.ReadFloat('LastModeFreq','12SSB',24.910)*1000000
              end
              else begin
                if mode = 'CW' then
                  freq := dmData.tstini.ReadFloat('LastModeFreq','10CW',28.0)*1000000
                else
                  freq := dmData.tstini.ReadFloat('LastModeFreq','10SSB',28.50)*1000000
              end
            end
            else begin
              if warc then
              begin
                if mode = 'CW' then
                  freq := dmData.tstini.ReadFloat('LastModeFreq','17CW',18.068)*1000000
                else
                  freq := dmData.tstini.ReadFloat('LastModeFreq','17SSB',18.110)*1000000
              end
              else begin
                if mode = 'CW' then
                  freq := dmData.tstini.ReadFloat('LastModeFreq','20CW',14.0)*1000000
                else
                  freq := dmData.tstini.ReadFloat('LastModeFreq','20SSB',14.2)*1000000
              end
            end
          end;
    12  : begin
            if up then
            begin
              if mode = 'CW' then
                freq := dmData.tstini.ReadFloat('LastModeFreq','10CW',28.0)*1000000
              else
                freq := dmData.tstini.ReadFloat('LastModeFreq','10SSB',28.5)*1000000
            end
            else begin
              if mode = 'CW' then
                freq := dmData.tstini.ReadFloat('LastModeFreq','15CW',21.00)*1000000
              else
                freq := dmData.tstini.ReadFloat('LastModeFreq','15SSB',21.2)*1000000
            end
          end;
    10  : begin
            if up then
            begin
              if mode = 'CW' then
                freq := dmData.tstini.ReadFloat('LastModeFreq','160CW',1.8)*1000000
              else
                freq := dmData.tstini.ReadFloat('LastModeFreq','160SSB',1.86)*1000000
            end
            else begin
              if warc then
              begin
                if mode = 'CW' then
                  freq := dmData.tstini.ReadFloat('LastModeFreq','12CW',24.890)*1000000
                else
                  freq := dmData.tstini.ReadFloat('LastModeFreq','12SSB',24.910)*1000000
              end
              else begin
                if mode = 'CW' then
                  freq := dmData.tstini.ReadFloat('LastModeFreq','15CW',21.00)*1000000
                else
                  freq := dmData.tstini.ReadFloat('LastModeFreq','15SSB',21.2)*1000000
              end
            end
          end
  end; //case
  frmTRXControl.SetModeFreq(mode,FloatToStr(freq));
  cmbFreq.Text := FormatFloat(empty_freq+';;',freq/1000000)
  {$ENDIF}
end;



initialization
  {$I fTestMain.lrs}

end.

