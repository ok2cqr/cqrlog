(*
***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fNewQSO;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  DBGrids, StdCtrls, Buttons, ComCtrls, Grids, inifiles,
  LCLType, RTTICtrls, httpsend, Menus, ActnList, process, db,
  uCWKeying, ipc, baseunix;

const
  cRefCall = 'Ref. call (to change press CTRL+R)   ';
  cMyLoc   = 'My grid (to change press CTRL+L) ';
type

  { TfrmNewQSO }

  TfrmNewQSO = class(TForm)
    acAbout: TAction;
    acClose: TAction;
    acDXCluster: TAction;
    acGrayline: TAction;
    acPreferences: TAction;
    acShowToolBar: TAction;
    acDetails: TAction;
    acQSOperMode: TAction;
    acShowBandMap: TAction;
    acAddToBandMap: TAction;
    acLongNote: TAction;
    acDXCCCfm: TAction;
    acITUCfm: TAction;
    acEditQSO: TAction;
    acCWMessages: TAction;
    acCWType: TAction;
    acRemoteMode: TAction;
    acQSOBefore: TAction;
    acProp: TAction;
    acCWFKey: TAction;
    acShowStatBar: TAction;
    acShowQSOB4: TAction;
    acRefreshTRX: TAction;
    acOpenLog: TAction;
    acBigSquare: TAction;
    acSendSpot : TAction;
    acSCP : TAction;
    acQSOList: TAction;
    acRotControl: TAction;
    acReloadCW: TAction;
    acTune : TAction;
    chkAutoMode: TCheckBox;
    dbgrdQSOBefore: TDBGrid;
    lblQSLRcvdDate: TLabel;
    MenuItem32 : TMenuItem;
    MenuItem33 : TMenuItem;
    MenuItem34 : TMenuItem;
    MenuItem35 : TMenuItem;
    MenuItem36 : TMenuItem;
    MenuItem37: TMenuItem;
    MenuItem38: TMenuItem;
    MenuItem39: TMenuItem;
    MenuItem4 : TMenuItem;
    MenuItem40: TMenuItem;
    MenuItem51: TMenuItem;
    MenuItem54: TMenuItem;
    MenuItem55: TMenuItem;
    acWASCfm: TAction;
    acWACCfm: TAction;
    acViewQSO: TAction;
    acWAZCfm: TAction;
    acXplanet: TAction;
    ActionList1: TActionList;
    acTRXControl: TAction;
    btnCancel: TButton;
    btnDXCCRef: TButton;
    btnQSLMgr: TButton;
    btnSave: TButton;
    cbOffline: TCheckBox;
    cmbFreq: TComboBox;
    cmbIOTA: TComboBox;
    cmbMode: TComboBox;
    cmbProfiles: TComboBox;
    cmbQSL_R: TComboBox;
    cmbQSL_S: TComboBox;
    edtAward: TEdit;
    edtCall: TEdit;
    edtCounty: TEdit;
    edtDate: TEdit;
    edtDXCCRef: TEdit;
    edtEndTime: TEdit;
    edtGrid: TEdit;
    edtHisRST: TEdit;
    edtITU: TEdit;
    edtMyRST: TEdit;
    edtName: TEdit;
    edtPWR: TEdit;
    edtQSL_VIA: TEdit;
    edtQTH: TEdit;
    edtRemQSO: TEdit;
    edtStartTime: TEdit;
    edtState: TEdit;
    edtWAZ: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    grbCallBook: TGroupBox;
    imgMain: TImageList;
    imgMain1: TImageList;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    lblTarSunSet: TLabel;
    lblTarSunRise: TLabel;
    lblLocSunSet: TLabel;
    lblLocSunRise: TLabel;
    Label15: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label2: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Label3: TLabel;
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
    lblAmbiguous: TLabel;
    lblAzi: TLabel;
    lblCall: TLabel;
    lblCfmLoTW: TLabel;
    lblCont: TLabel;
    lblCountryInfo: TLabel;
    lblDXCC: TLabel;
    lblGreeting: TLabel;
    lblHisTime: TLabel;
    lblIOTA: TLabel;
    lblITU: TLabel;
    lblLat: TLabel;
    lblLong: TLabel;
    lblQRA: TLabel;
    lblQSLMgr: TLabel;
    lblQSLVia: TLabel;
    lblQSONr: TLabel;
    lblQSOTakes: TLabel;
    lblWAZ: TLabel;
    MainMenu1: TMainMenu;
    mCallBook: TMemo;
    mComment: TMemo;
    mCountry: TMemo;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem15: TMenuItem;
    MenuItem16: TMenuItem;
    MenuItem17: TMenuItem;
    MenuItem18: TMenuItem;
    MenuItem19: TMenuItem;
    MenuItem20: TMenuItem;
    MenuItem21: TMenuItem;
    MenuItem22: TMenuItem;
    MenuItem23: TMenuItem;
    MenuItem24: TMenuItem;
    MenuItem25: TMenuItem;
    MenuItem26: TMenuItem;
    MenuItem27: TMenuItem;
    MenuItem28: TMenuItem;
    MenuItem29: TMenuItem;
    MenuItem30: TMenuItem;
    MenuItem31: TMenuItem;
    MenuItem41: TMenuItem;
    MenuItem42: TMenuItem;
    MenuItem43: TMenuItem;
    MenuItem44: TMenuItem;
    MenuItem45: TMenuItem;
    MenuItem46: TMenuItem;
    MenuItem47: TMenuItem;
    MenuItem48: TMenuItem;
    MenuItem49: TMenuItem;
    MenuItem50: TMenuItem;
    MenuItem59: TMenuItem;
    MenuItem60: TMenuItem;
    MenuItem61: TMenuItem;
    MenuItem62: TMenuItem;
    MenuItem63: TMenuItem;
    MenuItem64: TMenuItem;
    MenuItem65: TMenuItem;
    MenuItem66: TMenuItem;
    MenuItem67: TMenuItem;
    MenuItem68: TMenuItem;
    MenuItem69: TMenuItem;
    MenuItem70: TMenuItem;
    MenuItem71: TMenuItem;
    MenuItem72: TMenuItem;
    MenuItem73: TMenuItem;
    MenuItem74: TMenuItem;
    MenuItem75: TMenuItem;
    MenuItem76: TMenuItem;
    MenuItem77: TMenuItem;
    MenuItem78: TMenuItem;
    MenuItem79: TMenuItem;
    MenuItem80: TMenuItem;
    MenuItem81: TMenuItem;
    MenuItem82: TMenuItem;
    MenuItem83: TMenuItem;
    MenuItem84 : TMenuItem;
    MenuItem85 : TMenuItem;
    mnuQSOBefore: TMenuItem;
    mnuRemoteMode: TMenuItem;
    mnuIOTA: TMenuItem;
    mnuQSOList: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    mnuHelp: TMenuItem;
    mnuClose: TMenuItem;
    mnuPreferences: TMenuItem;
    mnuNewQSO: TMenuItem;
    mnuFile: TMenuItem;
    mnuTRXControl: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel6: TPanel;
    pnlOffline: TPanel;
    popEditQSO: TPopupMenu;
    sbNewQSO: TStatusBar;
    sbtneQSL : TSpeedButton;
    sgrdStatistic: TStringGrid;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    sbtnAttach: TSpeedButton;
    sbtnQSL: TSpeedButton;
    sbtnQRZ: TSpeedButton;
    sbtnLoTW: TSpeedButton;
    sbtnHamQTH : TSpeedButton;
    tmrFldigi: TTimer;
    tmrESC: TTimer;
    tmrRadio: TTimer;
    tmrRotor: TTimer;
    tmrEnd: TTimer;
    tmrStart: TTimer;
    procedure acBigSquareExecute(Sender: TObject);
    procedure acCWFKeyExecute(Sender: TObject);
    procedure acOpenLogExecute(Sender: TObject);
    procedure acPropExecute(Sender: TObject);
    procedure acQSOListExecute(Sender: TObject);
    procedure acRefreshTRXExecute(Sender: TObject);
    procedure acReloadCWExecute(Sender: TObject);
    procedure acRotControlExecute(Sender: TObject);
    procedure acSCPExecute(Sender : TObject);
    procedure acSendSpotExecute(Sender : TObject);
    procedure acShowStatBarExecute(Sender: TObject);
    procedure acTuneExecute(Sender : TObject);
    procedure chkAutoModeChange(Sender: TObject);
    procedure cmbFreqExit(Sender: TObject);
    procedure cmbIOTAEnter(Sender: TObject);
    procedure cmbQSL_REnter(Sender: TObject);
    procedure cmbQSL_SEnter(Sender: TObject);
    procedure dbgrdQSOBeforeColumnSized(Sender: TObject);
    procedure edtAwardEnter(Sender: TObject);
    procedure edtCallChange(Sender: TObject);
    procedure edtDateEnter(Sender: TObject);
    procedure edtDXCCRefEnter(Sender: TObject);
    procedure edtEndTimeEnter(Sender: TObject);
    procedure edtGridEnter(Sender: TObject);
    procedure edtHisRSTExit(Sender: TObject);
    procedure edtITUEnter(Sender: TObject);
    procedure edtMyRSTExit(Sender: TObject);
    procedure edtNameEnter(Sender: TObject);
    procedure edtPWREnter(Sender: TObject);
    procedure edtQSL_VIAEnter(Sender: TObject);
    procedure edtQTHEnter(Sender: TObject);
    procedure edtRemQSOEnter(Sender: TObject);
    procedure edtStartTimeEnter(Sender: TObject);
    procedure edtStateEnter(Sender: TObject);
    procedure edtWAZEnter(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormWindowStateChange(Sender: TObject);
    procedure MenuItem11Click(Sender: TObject);
    procedure MenuItem12Click(Sender: TObject);
    procedure MenuItem17Click(Sender: TObject);
    procedure MenuItem45Click(Sender: TObject);
    procedure MenuItem46Click(Sender: TObject);
    procedure MenuItem84Click(Sender : TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure acRemoteModeExecute(Sender: TObject);
    procedure acWASCfmExecute(Sender: TObject);
    procedure acAddToBandMapExecute(Sender: TObject);
    procedure acCWMessagesExecute(Sender: TObject);
    procedure acCWTypeExecute(Sender: TObject);
    procedure acCloseExecute(Sender: TObject);
    procedure acDXCCCfmExecute(Sender: TObject);
    procedure acDXClusterExecute(Sender: TObject);
    procedure acDetailsExecute(Sender: TObject);
    procedure acEditQSOExecute(Sender: TObject);
    procedure acGraylineExecute(Sender: TObject);
    procedure acITUCfmExecute(Sender: TObject);
    procedure acLongNoteExecute(Sender: TObject);
    procedure acNewQSOExecute(Sender: TObject);
    procedure acPreferencesExecute(Sender: TObject);
    procedure acQSOperModeExecute(Sender: TObject);
    procedure acShowBandMapExecute(Sender: TObject);
    procedure acTRXControlExecute(Sender: TObject);
    procedure acViewQSOExecute(Sender: TObject);
    procedure acWACCfmExecute(Sender: TObject);
    procedure acWASLoTWExecute(Sender: TObject);
    procedure acWAZCfmExecute(Sender: TObject);
    procedure acXplanetExecute(Sender: TObject);
    procedure btnDXCCRefClick(Sender: TObject);
    procedure btnQSLMgrClick(Sender: TObject);
    procedure cbOfflineChange(Sender: TObject);
    procedure cmbFreqChange(Sender: TObject);
    procedure cmbFreqEnter(Sender: TObject);
    procedure cmbFreqKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure cmbIOTAChange(Sender: TObject);
    procedure cmbIOTAExit(Sender: TObject);
    procedure cmbIOTAKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure cmbModeChange(Sender: TObject);
    procedure cmbModeEnter(Sender: TObject);
    procedure cmbModeExit(Sender: TObject);
    procedure cmbModeKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure cmbProfilesChange(Sender: TObject);
    procedure cmbQSL_RKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure cmbQSL_SKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure dbgrdQSOBeforeDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure edtAwardExit(Sender: TObject);
    procedure edtCallEnter(Sender: TObject);
    procedure edtCallExit(Sender: TObject);
    procedure edtCallKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtCallKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtCountyEnter(Sender: TObject);
    procedure edtCountyExit(Sender: TObject);
    procedure edtCountyKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edtCQKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtDateExit(Sender: TObject);
    procedure edtDateKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure edtAwardKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edtDXCCRefExit(Sender: TObject);
    procedure edtDXCCRefKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edtDateKeyPress(Sender: TObject; var Key: char);
    procedure edtEndTimeExit(Sender: TObject);
    procedure edtEndTimeKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edtGridExit(Sender: TObject);
    procedure edtGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure edtHisRSTEnter(Sender: TObject);
    procedure edtHisRSTKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edtITUExit(Sender: TObject);
    procedure edtITUKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtMyRSTEnter(Sender: TObject);
    procedure edtMyRSTKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure edtNameChange(Sender: TObject);
    procedure edtNameExit(Sender: TObject);
    procedure edtNameKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure edtPWRKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtQSL_VIAKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edtQTHChange(Sender: TObject);
    procedure edtQTHExit(Sender: TObject);
    procedure edtQTHKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtRemQSOKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtStartTimeExit(Sender: TObject);
    procedure edtStartTimeKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCancelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure edtStartTimeKeyPress(Sender: TObject; var Key: char);
    procedure edtStateExit(Sender: TObject);
    procedure edtStateKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure edtWAZExit(Sender: TObject);
    procedure mCommentKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure mCommentKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure mnuIOTAClick(Sender: TObject);
    procedure mnuQSOBeforeClick(Sender: TObject);
    procedure mnuQSOListClick(Sender: TObject);
    procedure sbtnAttachClick(Sender: TObject);
    procedure sbtnQSLClick(Sender: TObject);
    procedure sbtnQRZClick(Sender: TObject);
    procedure sbtnHamQTHClick(Sender : TObject);
    procedure tmrESCTimer(Sender: TObject);
    procedure tmrEndStartTimer(Sender: TObject);
    procedure tmrEndTimer(Sender: TObject);
    procedure tmrFldigiTimer(Sender: TObject);
    procedure tmrRadioTimer(Sender: TObject);
    procedure tmrStartStartTimer(Sender: TObject);
    procedure tmrStartTimer(Sender: TObject);
  private
    fEditQSO : Boolean;
    fViewQSO : Boolean;
    old_stat_adif : Word;
    TabUsed : Boolean;
    old_cmode   : String;
    old_ccall   : String;
    old_cfreq   : String;

    old_prof   : Integer;
//    old_pfx    : String;
    old_adif   : Word;
    old_date   : TDateTime;
    old_mode   : String;
    old_freq   : String;
    old_qslr   : String;
    posun      : String;
    old_call   : String;
    ChangeDXCC : Boolean;
    StartTime  : TDateTime;
    Running    : Boolean;
    idcall     : String;
    old_t_mode : String;
    old_t_band : String;
    lotw_qslr  : String;
    fromNewQSO : Boolean;
    FreqBefChange : Double;
    adif : Word;

    procedure ShowDXCCInfo(ref_adif : Word = 0);
    procedure ShowFields;
    procedure ChangeReports;
    procedure ShowStatistic(ref_adif : Word);
    procedure CalculateDistanceEtc;
    procedure SetDateTime(EndTime : Boolean = True);
    procedure CheckCallsignClub;
    procedure CheckQTHClub;
    procedure CheckAwardClub;
    procedure CheckCountyClub;
    procedure CheckStateClub;
    procedure SaveGrid;
    procedure LoadGrid;
    procedure SetSplit(s : String);
    procedure ShowWindows;
    procedure CheckAttachment;
    procedure CheckQSLImage;
    procedure ShowCountryInfo;
    procedure InsertNameQTH;
    procedure UpdateFKeyLabels;
    procedure ClearStatGrid;
    procedure LoadSettings;
    procedure SaveSettings;
    procedure ChangeCallBookCaption;
    procedure SendSpot;
    procedure RunVK(key_pressed: String);
    procedure InitializeCW;
  public
    QTHfromCb   : Boolean;
    FromDXC     : Boolean;
    UseSpaceBar : Boolean;
    CWint       : TCWKeying;
    ShowWin     : Boolean;

    ClearAfterFreqChange : Boolean;
    ChangeFreqLimit : Double;

    property EditQSO : Boolean read fEditQSO write fEditQSO default False;
    property ViewQSO : Boolean read fViewQSO write fViewQSO default False;

    procedure AppIdle(Sender: TObject; var Handled: Boolean);
    procedure ShowQSO;
    procedure NewQSO;
    procedure ClearAll;
    procedure SavePosition;
    procedure NewQSOFromSpot(call,freq,mode : String);
    procedure SetEditLabel;
    procedure UnsetEditLabel;
    procedure StoreClubInfo(where,StoreText : String);
    procedure SynCallBook;
    procedure SynDXCCTab;
    procedure SynQSLTab;
    procedure CalculateLocalSunRiseSunSet;
  end;

  type
    TQRZThread = class(TThread)
    protected
      procedure Execute; override;
  end;

  type
    TDXCCTabThread = class(TThread)
    protected
      procedure Execute; override;
  end;

  type
    TQSLTabThread = class(TThread)
    protected
      procedure Execute; override;
  end;

var
  frmNewQSO    : TfrmNewQSO;

  EscFirstTime : Boolean = True;

  c_callsign  : String;
  c_nick      : String;
  c_qth       : String;
  c_address   : String;
  c_zip       : String;
  c_grid      : String;
  c_state     : String;
  c_county    : String;
  c_qsl       : String;
  c_iota      : String;
  c_ErrMsg    : String;
  c_SyncText  : String;
  c_running   : Boolean = False;
  Azimuth     : String;

  minimalize    : Boolean;
  MinDXCluster  : Boolean;
  MinGrayLine   : Boolean;
  MinTRXControl : Boolean;
  MinNewQSO     : Boolean;
  MinQSODetails : Boolean;
  
implementation

{ TfrmNewQSO }

uses dUtils, fChangeLocator, dDXCC, dDXCluster, dData, fMain, fSelectDXCC, fGrayline,
     fTRXControl, fPreferences, fSplash, fDXCluster, fDXCCStat,fQSLMgr, fSendSpot,
     fQSODetails, fWAZITUStat, fIOTAStat, fGraphStat, fImportProgress, fBandMap,
     fLongNote, fRefCall, fKeyTexts, fCWType, fExportProgress, fPropagation, fCallAttachment,
     fQSLViewer, fCWKeys,{ fTestMain,} uMyIni, fDBConnect, fAbout, uVersion, fChangelog,
     fBigSquareStat, fSCP, fRotControl;

procedure TQSLTabThread.Execute;
var
  HTTP   : THTTPSend;
  m      : TStringList;
  FileDate : TDateTime;
begin
  FreeOnTerminate := True;
  http   := THTTPSend.Create;
  m      := TStringList.Create;
  try
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');
    if HTTP.HTTPMethod('GET', 'http://www.ok2cqr.com/linux/cqrlog/qslmgr/ver.dat') then
    begin
      m.LoadFromStream(HTTP.Document);
      FileDate := dmUtils.MyStrToDate(trim(m.Text));
      if FileDate > dmUtils.GetLastQSLUpgradeDate then
      begin
        Synchronize(@frmNewQSO.SynQSLTab)
      end
    end
  finally
    http.Free;
    m.Free
  end
end;


procedure TDXCCTabThread.Execute;
var
  HTTP   : THTTPSend;
  m      : TStringList;
  FileDate : TDateTime;
begin
  FreeOnTerminate := True;
  http   := THTTPSend.Create;
  m      := TStringList.Create;
  try
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');
    if HTTP.HTTPMethod('GET', 'http://www.ok2cqr.com/linux/cqrlog/ctyfiles/ver.dat') then
    begin
      m.LoadFromStream(HTTP.Document);
      FileDate := dmUtils.MyStrToDate(trim(m.Text));
      if FileDate > dmUtils.GetLastUpgradeDate then
      begin
        Synchronize(@frmNewQSO.SynDXCCTab)
      end;
    end;
  finally
    http.Free;
    m.Free
  end
end;

procedure TfrmNewQSO.SynDXCCTab;
begin
  if Application.MessageBox('New DXCC tables are available. Do you want to download and install it?','Question ...',
                            mb_YesNo + mb_IconQuestion) = idYes then
  begin
    with TfrmImportProgress.Create(self) do
    try
      Caption            := 'Downloading DXCC data ...';
      lblComment.Caption := 'Downloading DXCC data ...';
      ImportType := 3;
      ShowModal;
    finally
      Free
    end;
    dmDXCC.ReloadDXCCTables;
    dmDXCluster.ReloadDXCCTables
  end
end;

procedure TfrmNewQSO.SynQSLTab;
begin
  if Application.MessageBox('New QSL managers database is available. Do you want to download and install it?','Question ...',
                            mb_YesNo + mb_IconQuestion) = idYes then
  begin
    with TfrmImportProgress.Create(self) do
    try
      Caption            := 'Downloading QSL managers ...';
      lblComment.Caption := 'Downloading QSL managers ...';
      ImportType := 6;
      ShowModal;
    finally
      Free
    end
  end
end;

procedure TQRZThread.Execute;
begin
  c_running := True;
  try
    c_nick     := '';
    c_qth      := '';
    c_address  := '';
    c_zip      := '';
    c_grid     := '';
    c_state    := '';
    c_county   := '';
    c_qsl      := '';
    c_iota     := '';
    c_ErrMsg   := '';
    FreeOnTerminate:= True;
    c_SyncText := 'Working ...';
    Synchronize(@frmNewQSO.SynCallBook);
    dmUtils.GetCallBookData(c_callsign,c_nick,c_qth,c_address,c_zip,c_grid,c_state,c_county,c_qsl,c_iota,c_ErrMsg);
    c_SyncText := '';
    Synchronize(@frmNewQSO.SynCallBook)
  finally
    c_running := False
  end
end;

procedure TfrmNewQSO.ClearStatGrid;
var
  i,y : Integer;
begin
  for i:= 0 to sgrdStatistic.ColCount-1 do
    for y := 0 to sgrdStatistic.RowCount-1 do
      sgrdStatistic.Cells[i,y] := '   ';
  with sgrdStatistic do
  begin
    Cells[0, 1] := 'SSB';
    Cells[0, 2] := 'CW';
    Cells[0, 3] := 'DIGI'
  end
end;

procedure TfrmNewQSO.SetDateTime(EndTime : Boolean =  True);
var
  date  : TDateTime;
  Mask  : String;
  sDate : String;
begin
  Mask  := '';
  sDate := '';
  date := dmUtils.GetDateTime(0);
  edtDate.Clear;
  dmUtils.DateInRightFormat(date,Mask,sDate);
  edtDate.Text      := sDate;
  edtStartTime.Text := FormatDateTime('hh:mm',date);
  if EndTime then
    edtEndTime.Text   := FormatDateTime('hh:mm',date);
end;

procedure TfrmNewQSO.InsertNameQTH;
var
  sName, QTH, loc : String;
  county, qsl_via : String;
  award,state     : String;
  qslrdate        : String;
begin
  sName    := '';
  QTH      := '';
  loc      := '';
  county   := '';
  qsl_via  := '';
  award    := '';
  state    := '';
  qslrdate := '';
  
  if dmData.qQSOBefore.RecordCount > 0 then
  begin
    try
      dmData.qQSOBefore.DisableControls;
      dmData.qQSOBefore.Last;
      while (not dmData.qQSOBefore.bof) do
      begin
        if (sName = '') then
          sName := dmData.qQSOBefore.FieldByName('name').AsString;
        if (qth = '') then
          qth := dmData.qQSOBefore.FieldByName('qth').AsString;
        if (loc = '') then
          loc := dmData.qQSOBefore.FieldByName('loc').AsString;
        if (county = '') then
          county := dmData.qQSOBefore.FieldByName('county').AsString;
        if (qsl_via = '') then
          qsl_via := dmData.qQSOBefore.FieldByName('qsl_via').AsString;
        if (award = '') then
          award := dmData.qQSOBefore.FieldByName('award').AsString;
        if (state = '') then
          state := dmData.qQSOBefore.FieldByName('state').AsString;
        if (qslrdate = '') and (not dmData.qQSOBefore.FieldByName('qslr_date').IsNull) then
          lblQSLRcvdDate.Caption := 'QSL rcvd on '+dmData.qQSOBefore.FieldByName('qslr_date').AsString;
        dmData.qQSOBefore.Prior;
      end;
      lblQSLRcvdDate.Visible := True
    finally
      dmData.qQSOBefore.Last;  //after this, dbgrid is not set to last record
      dmData.qQSOBefore.EnableControls;
      dmData.qQSOBefore.Last
    end;

    if (edtName.Text = '') then
      edtName.Text := sName;
    if (edtQTH.Text = '') then
      edtQTH.Text := qth;
    if (edtGrid.Text = '') then
      edtGrid.Text := loc;
    if (edtCounty.Text = '') then
      edtCounty.text := county;
    if (edtQSL_VIA.Text = '') then
      edtQSL_VIA.Text := qsl_via;
    if (edtAward.Text = '') then
      edtAward.Text := award;
    if (edtState.Text = '') then
      edtState.Text := state
  end
end;

Procedure TfrmNewQSO.ShowCountryInfo;
var
  index : Integer;
begin
  index := 0;
  lblCountryInfo.Caption := dmDXCC.DXCCInfo(adif,cmbFreq.Text,
                            cmbMode.Text,index)
end;

procedure TfrmNewQSO.ShowDXCCInfo(ref_adif : Word = 0);
var
  cont, country, WAZ, ITU, pfx : string;
  Date : TDateTime;
  lat, long : String;
  sDate : String = '';
  Delta : Currency;
  sDelta : String;
begin
  cont    := '';
  country := '';
  waz     := '';
  posun   := '';
  itu     := '';
  lat     := '';
  long    := '';
  if not dmUtils.IsDateOK(edtDate.Text) then
    exit;
    
  if ref_adif = 0 then
  begin
    Date := dmUtils.StrToDateFormat(edtDate.Text);
    adif := dmDXCC.id_country(edtCall.Text,date,pfx, cont, country, WAZ, posun, ITU, lat, long);
    dmUtils.ModifyWAZITU(waz,itu);
    sDelta := posun
  end
  else begin
     dmDXCC.qDXCCRef.Close;
     dmDXCC.qDXCCRef.SQL.Text := 'SELECT * FROM cqrlog_common.dxcc_ref WHERE adif = ' + IntToStr(adif);
     dmDXCC.qDXCCRef.Open;
     if dmDXCC.qDXCCRef.RecordCount > 0 then
     begin
       pfx     := dmDXCC.qDXCCRef.FieldByName('pref').AsString;
       cont    := dmDXCC.qDXCCRef.FieldByName('CONT').AsString;
       lat     := dmDXCC.qDXCCRef.FieldByName('LAT').AsString;
       long    := dmDXCC.qDXCCRef.FieldByName('longit').AsString;
       country := dmDXCC.qDXCCRef.FieldByName('name').AsString;;
       waz     := dmDXCC.qDXCCRef.FieldByName('WAZ').AsString;
       itu     := dmDXCC.qDXCCRef.FieldByName('ITU').AsString;
       sDelta  := dmDXCC.qDXCCRef.FieldByName('utc').AsString
     end;
     dmDXCC.qDXCCRef.Close
  end;
  if not TryStrToCurr(sDelta,Delta) then
    Delta := 0;
  Date := dmUtils.GetDateTime(Delta);
  dmUtils.DateInRightFormat(date,sDelta,sDate);
  lblHisTime.Caption := sDate + '  ' + TimeToStr(Date) + '     ';
  lblGreeting.Caption := dmUtils.GetGreetings(lblHisTime.Caption);
  mCountry.Clear;
  mCountry.Lines.Add(country);
  mCountry.Repaint;
  if not (fEditQSO or fViewQSO) then
  begin
    lblWAZ.Caption  := WAZ;
    lblITU.Caption  := itu;
    edtWAZ.Text     := WAZ;
    edtITU.Text     := ITU;
  end;
  lblDXCC.Caption := pfx;
  lblCont.Caption := cont;
  edtDXCCRef.Text := pfx;
  lblLat.Caption  := lat;
  lblLong.Caption := long
end;

procedure TfrmNewQSO.ClearAll;
var
  i : Integer;
  sDate, Mask : String;
  date : TDateTime;
  sTimeOn  : String = '';
  sTimeOff : String = '';
  ShowRecentQSOs : Boolean = False;
  RecentQSOCount : Integer = 0;
  since  : String;
  lat,long : Currency;
begin
  if fViewQSO then
  begin
    if (not (fViewQSO or fEditQSO or cbOffline.Checked)) then
      tmrRadio.Enabled := True;
    btnSave.Enabled  := True;
    for i:=0 to ComponentCount-1 do
    begin
      if (frmNewQSO.Components[i] is TEdit) then
         (frmNewQSO.Components[i] As TEdit).ReadOnly := False;
    end;
    edtDate.ReadOnly  := False;
    mComment.ReadOnly := False;
  end;
  sbtnQRZ.Visible    := False;
  sbtnLoTW.Visible   := False;
  sbtneQSL.Visible   := False;
  sbtnHamQTH.Visible := False;
  TabUsed    := False;
  fromNewQSO := False;
  FromDXC  := False;
  fEditQSO := False;
  fViewQSO := False;
  old_stat_adif := 0;
  old_adif := 0;
  lblQSOTakes.Visible := False;
  lblWAZ.Caption     := '';
  lblDXCC.Caption    := '';
  lblITU.Caption     := '';
  lblLat.Caption     := '';
  lblLong.Caption    := '';
  lblCont.Caption    := '';
  lblHisTime.Caption := '';
  lblQRA.Caption     := '';
  lblAzi.Caption     := '';
  lblGreeting.Caption := '';
  lblTarSunRise.Caption := '';
  lblTarSunSet.Caption  := '';
  mCountry.Clear;
  mComment.Clear;
  QTHfromCb := False;
  lblAmbiguous.Visible := False;
  old_call := '';
  lblCfmLoTW.Visible := False;
  lblQSLRcvdDate.Visible := False;
  lblQSLRcvdDate.Caption := '';
  lblCountryInfo.Caption := '';
  Mask  := '';
  lblQSONr.Caption := '0';
  mCallBook.Clear;
  dmData.qQSOBefore.Close;
  lblIOTA.Font.Color := clBlue;
  if frmQSODetails.Showing then
  begin
    frmQSODetails.ClearAll;
    frmQSODetails.ClearStat
  end;

  if cbOffline.Checked then
  begin
    sTimeOn  := edtStartTime.Text;
    sTimeOff := edtEndTime.Text;
    sDate    := edtDate.Text
  end;

  for i:=0 to ComponentCount-1 do
  begin
    if (frmNewQSO.Components[i] is TEdit) then
      (frmNewQSO.Components[i] As TEdit).Text := ''
    else
      if (frmNewQSO.Components[i] is TComboBox) then
        (frmNewQSO.Components[i] As TComboBox).Text := ''
  end;
  dmUtils.InsertModes(cmbMode);
  dmUtils.InsertFreq(cmbFreq);

  if cbOffline.Checked then
  begin
    edtStartTime.Text := sTimeOn;
    edtEndTime.Text   := sTimeOff;
    edtDate.Text      := sDate
  end;
  dmData.InsertProfiles(cmbProfiles,False);
  if old_prof = -1 then
    cmbProfiles.Text := dmData.GetDefaultProfileText
  else begin
    if old_prof <= cmbProfiles.Items.Count-1 then
      cmbProfiles.ItemIndex := old_prof
  end;
  if cmbProfiles.Text <> '' then
    cmbProfilesChange(nil);
  if sbNewQSO.Panels[0].Text = '' then
    sbNewQSO.Panels[0].Text := cMyLoc + cqrini.ReadString('Station','LOC','');

  cmbFreq.Text := cqrini.ReadString('TMPQSO','FREQ',cqrini.ReadString(
                  'NewQSO','FREQ','7.025'));
  cmbMode.Text := cqrini.ReadString('TMPQSO','Mode',cqrini.ReadString(
                  'NewQSO','Mode','CW'));
  edtPWR.Text  := cqrini.ReadString('TMPQSO','PWR',cqrini.ReadString(
                  'NewQSO','PWR','100'));

  edtRemQSO.Text := cqrini.ReadString('NewQSO','RemQSO','');

  cbOffline.Checked := cqrini.ReadBool('TMPQSO','OFF',False);
  cmbQSL_S.Text     := cqrini.ReadString('NewQSO','QSL_S','');

  ShowRecentQSOs := cqrini.ReadBool('NewQSO','ShowRecentQSOs',False);
  RecentQSOCount := cqrini.ReadInteger('NewQSO','RecQSOsNum',5);
  if NOT cbOffline.Checked then
  begin
    date := dmUtils.GetDateTime(0);
    edtDate.Clear;
    dmUtils.DateInRightFormat(date,Mask,sDate);
    edtDate.Text      := sDate;
    edtStartTime.Text := FormatDateTime('hh:mm',date);
    edtEndTime.Text   := FormatDateTime('hh:mm',date)
  end;
  tmrRadio.Enabled  := True;
  if ShowRecentQSOs then
  begin
    since := dmUtils.MyDateToStr(now - RecentQSOCount);
    dmData.qQSOBefore.Close;
    dmData.trQSOBefore.Rollback;
    dmData.qQSOBefore.SQL.Text := 'select * from view_cqrlog_main_by_qsodate where qsodate >= '+QuotedStr(since)+
                                   ' order by qsodate,time_on';
    if dmData.DebugLevel>=1 then Writeln(dmData.qQSOBefore.SQL.Text);
    dmData.trQSOBefore.StartTransaction;
    dmData.qQSOBefore.Open;
    ShowFields;
    dmData.qQSOBefore.DisableControls;
    dmData.qQSOBefore.Last;
    dmData.qQSOBefore.EnableControls;
  end;
  ChangeCallBookCaption;
  ClearStatGrid;
  dmUtils.CoordinateFromLocator(copy(sbNewQSO.Panels[0].Text,Length(cMyLoc)+1,6),lat,long);
  lat := lat*-1;
  frmGrayLine.ob^.jachcucaru(true,long,lat,long,lat);
  frmGrayline.FormPaint(nil);
  if not mnuRemoteMode.Checked then
    edtCall.SetFocus;
  if not (fEditQSO or fViewQSO or cbOffline.Checked) then
    tmrStart.Enabled := True;
  tmrEnd.Enabled := False;
  FromDXC := False;
  lblQSLMgr.Visible := False;
  sbNewQSO.Panels[1].Text := '';
  sbtnAttach.Visible := False;
  sbtnQSL.Visible    := False;
  ChangeDXCC := False;
  adif := 0;
  FreqBefChange := frmTRXControl.GetFreqMHz
end;

procedure TfrmNewQSO.LoadSettings;
var
  i     : Integer;
  Tab   : TDXCCTabThread;
  thqsl : TQSLTabThread;
begin
  dmUtils.ModifyXplanetConf;
  dmUtils.LoadFontSettings(frmNewQSO);
  dmUtils.LoadBandLabelSettins;
  sbNewQSO.Panels[0].Width := 280;
  sbNewQSO.Panels[1].Width := 310;

  sbNewQSO.Panels[2].Width := 70;

  sbNewQSO.Panels[3].Text  := 'Ver. '+ dmData.VersionString;
  sbNewQSO.Panels[3].Width := 60;

  Height      := cqrini.ReadInteger('NewQSO','Height',Height);
  Width       := cqrini.ReadInteger('NewQSO','Width',Width);
  Top         := cqrini.ReadInteger('NewQSO','Top',20);
  Left        := cqrini.ReadInteger('NewQSO','Left',20);
  UseSpaceBar := cqrini.ReadBool('NewQSO','UseSpaceBar',False);
  dbgrdQSOBefore.Visible := cqrini.ReadBool('NewQSO','ShowGrd',True);
  sbNewQSO.Visible := cqrini.ReadBool('NewQSO','StatBar',True);
  acShowStatBar.Checked := sbNewQSO.Visible;

  if dbgrdQSOBefore.Visible then
    mnuQSOBefore.Caption := 'Disable QSO before grid'
  else
    mnuQSOBefore.Caption := 'Enable QSO before grid';

  if cqrini.ReadBool('Window','Grayline',False) then
    frmGrayline.Show;

  if cqrini.ReadBool('Window','TRX',False) then
  begin
    frmTRXControl.Show;
    frmTRXControl.BringToFront
  end;

   if cqrini.ReadBool('Window','ROT',False) then
  begin
    frmRotControl.Show;
    frmRotControl.BringToFront
  end;

  if cqrini.ReadBool('Window','Dxcluster',False) then
  begin
    frmDXCluster.Show;
    frmDXCluster.BringToFront
  end;

  if frmTRXControl.Showing then
  begin
    if frmTRXControl.rbRadio1.Checked then
      tmrRadio.Interval := cqrini.ReadInteger('TRX1','Poll',500)
    else
      tmrRadio.Interval := cqrini.ReadInteger('TRX2','Poll',500)
  end
  else begin
    tmrRadio.Interval := cqrini.ReadInteger('TRX1','Poll',500)
  end;

  if frmRotControl.Showing then
  begin
    if frmRotControl.rbRotor1.Checked then
      tmrRotor.Interval := cqrini.ReadInteger('ROT1','Poll',500)
    else
      tmrRotor.Interval := cqrini.ReadInteger('ROT2','Poll',500)
  end
  else begin
    tmrRotor.Interval := cqrini.ReadInteger('ROT1','Poll',500)
  end;

  if cqrini.ReadBool('Window','Details',True) and (not dmData.ContestMode) then
  begin
    frmQSODetails.Show;
    frmQSODetails.BringToFront
  end;

  if cqrini.ReadBool('Window','BandMap',False) then
  begin
    frmBandMap.Show;
    frmBandMap.BringToFront
  end;

  if cqrini.ReadBool('Window','SCP',False) then
  begin
    frmSCP.Show;
    frmSCP.BringToFront
  end;

  if cqrini.ReadBool('xplanet','run',False) then
    dmUtils.RunXplanet;

  if cqrini.ReadBool('Window','Prop',False) then
    frmPropagation.Show;

  if cqrini.ReadBool('Window','CWKeys',False) then
    acCWFKey.Execute;

  if cqrini.ReadBool('Window','QSOList',False) then
    acQSOList.Execute;

  if cqrini.ReadBool('Program','CheckDXCCTabs',True) then
  begin
    Tab := TDXCCTabThread.Create(True);
    Tab.Resume
  end;


  if cqrini.ReadBool('Program','CheckQSLTabs',True) then
  begin
    thqsl := TQSLTabThread.Create(True);
    thqsl.Resume
  end;

  InitializeCW;

  ClearAfterFreqChange := False;//cqrini.ReadBool('NewQSO','ClearAfterFreqChange',False);
  ChangeFreqLimit      := cqrini.ReadFloat('NewQSO','FreqChange',0.010);

  CalculateLocalSunRiseSunSet;
  tmrRadio.Enabled := True;
  dmData.InsertProfiles(cmbProfiles,False);
  cmbProfiles.Text := dmData.GetDefaultProfileText;
  ChangeCallBookCaption;
  BringToFront
end;

procedure TfrmNewQSO.SaveSettings;
begin
  SaveGrid;
  tmrRadio.Enabled := False;
  tmrEnd.Enabled   := False;
  tmrStart.Enabled := False;

  if Assigned(cqrini) then
  begin
    cqrini.WriteBool('Windows','CWKeys',frmCWKeys.Showing);

    //I have to close window manually because of bug in lazarus.

    if frmGrayline.Showing then
    begin
      frmGrayline.Close;
      cqrini.WriteBool('Window','Grayline',True)
    end
    else
      cqrini.WriteBool('Window','Grayline',False);

    if frmTRXControl.Showing then
    begin
      frmTRXControl.Close;
      cqrini.WriteBool('Window','TRX',True)
    end
    else
      cqrini.WriteBool('Window','TRX',False);

    if frmRotControl.Showing then
    begin
      frmRotControl.Close;
      cqrini.WriteBool('Window','ROT',True)
    end
    else
      cqrini.WriteBool('Window','ROT',False);

    if frmDXCluster.Showing then
    begin
      frmDXCluster.Close;
      cqrini.WriteBool('Window','Dxcluster',True)
    end
    else
      cqrini.WriteBool('Window','Dxcluster',False);

    if frmQSODetails.Showing then
    begin
      frmQSODetails.Close;
      cqrini.WriteBool('Window','Details',True)
    end
    else
      cqrini.WriteBool('Window','Details',False);

    if frmBandMap.Showing then
    begin
      frmBandMap.Close;
      cqrini.WriteBool('Window','BandMap',True)
    end
    else
      cqrini.WriteBool('Window','BandMap',False);

    if frmPropagation.Showing then
    begin
      frmPropagation.Close;
      cqrini.WriteBool('Window','Prop',True)
    end
    else
      cqrini.WriteBool('Window','Prop',False);

    if frmCWKeys.Showing then
    begin
      frmCWKeys.Close;
      cqrini.WriteBool('Window','CWKeys',True)
    end
    else
      cqrini.WriteBool('Window','CWKeys',False);

    if frmSCP.Showing then
    begin
      cqrini.WriteBool('Window','SCP',True);
      frmSCP.Close
    end
    else
      cqrini.WriteBool('Window','SCP',False);

    if frmMain.Showing then
    begin
      cqrini.WriteBool('Window','QSOList',True);
      frmMain.Close
    end
    else
      cqrini.WriteBool('Window','QSOList',False);

    cqrini.DeleteKey('TMPQSO','OFF');
    cqrini.DeleteKey('TMPQSO','FREQ');
    cqrini.DeleteKey('TMPQSO','Mode');
    cqrini.DeleteKey('TMPQSO','PWR');
    cqrini.WriteBool('NewQSO','AutoMode',chkAutoMode.Checked);
    SavePosition;
    cqrini.WriteBool('NewQSO','ShowGrd',dbgrdQSOBefore.Visible);
    if cqrini.ReadBool('xplanet','close',False) then
      dmUtils.CloseXplanet;
    cqrini.SaveToDisk;
    dmData.SaveConfigFile;
    if cqrini.ReadBool('Backup','Enable',False) and
      (DirectoryExists(cqrini.ReadString('Backup','Path',dmData.DataDir))) and (Paramstr(1) = '') then
    begin
      with TfrmExportProgress.Create(self) do
      try
        AutoBackup := True;
        FileName := cqrini.ReadString('Backup','Path',dmData.DataDir) + cqrini.ReadString('Station','Call','');
        if cqrini.ReadInteger('Backup','BackupType',0) > 0 then
          FileName := FileName + '_backup.adi'
        else
          FileName := FileName + '_'+FormatDateTime('yyyy-mm-dd_hh-mm-ss',now)+'.adi';
        ExportType := 2;
        ShowModal
      finally
        Free
      end
    end
  end;
  if Assigned(CWint) then
  begin
    CWint.Close;
    FreeAndNil(CWint)
  end
end;

procedure TfrmNewQSO.FormShow(Sender: TObject);
var
  ini       : TIniFile;
  changelog : Boolean = False;
begin
  with TfrmDBConnect.Create(self) do
  try
    ShowModal;
    if ModalResult <> mrOK then
      Application.Terminate
    else
      frmNewQSO.Caption := dmUtils.GetNewQSOCaption('New QSO')
  finally
    Free
  end;

  ini := TIniFile.Create(GetAppConfigDir(False)+'cqrlog_login.cfg');
  try
    if ini.ReadString('Changelog','Version','') <> cVERSION then
    begin
      changelog := True;
      ini.WriteString('Changelog','Version',cVERSION)
    end
  finally
    ini.Free
  end;


  if changelog then
  begin
    with TfrmChangelog.Create(Application) do
    try
      ShowModal
    finally
      Free
    end
  end;

  if not (Sender = nil) then
    LoadSettings;

  old_ccall := '';
  old_cmode := '';
  old_cfreq := '';

  Running      := False;
  EscFirstTime := False;
  ChangeDXCC   := False;

  ClearAll;
  edtCall.SetFocus;
  tmrRadio.Enabled := True;
  tmrStart.Enabled := True
end;

procedure TfrmNewQSO.tmrEndStartTimer(Sender: TObject);
begin
  tmrEndTimer(nil)
end;

procedure TfrmNewQSO.tmrEndTimer(Sender: TObject);
var
  Date  : TDateTime;
  sDate : String='';
  Mask  : String='';
  Takes : TDateTime;
  h,m,s : Word;
  ms    : Word = 0;
begin
  h := 0;
  m := 0;
  s := 0;
  if not cbOffline.Checked then
  begin
    lblQSOTakes.Visible := True;

    if cqrini.ReadBool('Fonts','UseDefault',True) then
    begin
      lblQSOTakes.Font.Name := 'default';
      lblQSOTakes.Font.Size := 0
    end
    else begin
      lblQSOTakes.Font.Name := cqrini.ReadString('Fonts','Buttons','Sans 10');
      lblQSOTakes.Font.Size := cqrini.ReadInteger('Fonts','bSize',10)
    end;

    date := dmUtils.GetDateTime(0);
    dmUtils.DateInRightFormat(date,Mask,sDate);
    edtEndTime.Text   := FormatDateTime('hh:mm',date);
    Takes := StartTime - Date;
    DecodeTime(Takes,h,m,s,ms);
    lblQSOTakes.Caption := 'QSO takes ' + IntToStr(h) + ' hours, ' + IntToStr(m) +
                           ' minutes, ' + IntToStr(s) + ' seconds'
  end
end;

procedure TfrmNewQSO.tmrFldigiTimer(Sender: TObject);
    type
      PMyMsgBuf = ^TMyMsgBuf;
      TMyMsgBuf = record
        mtype : PtrInt;
        mtext : array[0..1024] of char;
      end;

    procedure DoError (Const Msg : string);
    begin
      Writeln (msg,' returned an error : ',fpgeterrno);
    end;

var
  ID  : longint;
  Buf : TMyMsgBuf;
  i : Integer;
  call : String;
  time1 : String;
  time2 : String;
  sname : String;
  qth   : String;
  loc   : String;
  mhz   : String;
  mode  : String;
  rst   : String;
  state : String;
  note  : String;
  date  : TDateTime;
  sDate : String='';
  Mask  : String='';
begin
  ID:=msgget(1238,IPC_CREAT or 438);
  If ID<0 then DoError('MsgGet');
  Buf.MType:=1024;
  while msgrcv(ID,PMSGBuf(@Buf),1024,0,0 or IPC_NOWAIT)<>-1 do
  begin
    ClearAll;
    cbOffline.Checked := True;
    call := '';
    time1 := '';
    time2 := '';
    sname := '';
    qth   := '';
    loc   := '';
    mhz   := '';
    mode  := '';
    rst   := '';
    state := '';
    note  := '';
    if dmData.DebugLevel>=1 then
      Writeln ('Type : ',buf.mtype,' Text : ',buf.mtext);

    date := dmUtils.GetDateTime(0);
    edtDate.Clear;
    dmUtils.DateInRightFormat(date,Mask,sDate);
    edtDate.Text:=sDate;

    case cqrini.ReadInteger('fldigi','freq',0) of
      0 : begin
            if frmTRXControl.GetModeFreqNewQSO(mode,mhz) then
            begin
              cmbFreq.Text := mhz
              //cmbMode.Text := mode
            end
          end;

      1 : begin
            i := Pos('mhz',buf.mtext);
            if i > 0 then
            begin
              i := i+3;
              while buf.mtext[i] <> chr(1) do
              begin
                mhz := mhz + buf.mtext[i];
                inc(i)
              end;
              if dmData.DebugLevel>=1 then Writeln('mhz:',mhz)
            end;
            mhz := Trim(mhz);
            if dmUtils.GetBandFromFreq(mhz) <> '' then
              cmbFreq.Text := mhz;
          end;
       2 : cmbFreq.Text := cqrini.ReadString('fldigi','deffreq','3.600')
    end;
    mode := '';
    case cqrini.ReadInteger('fldigi','mode',1) of
      0 : begin
            if frmTRXControl.GetModeFreqNewQSO(mode,mhz) then
            begin
              //cmbFreq.Text := mhz;
              cmbMode.Text := mode
            end
          end;
      1 : begin
            i := Pos('mode',buf.mtext);
            if i > 0 then
            begin
              i := i+4;
              while buf.mtext[i] <> chr(1) do
              begin
                mode := mode + buf.mtext[i];
                inc(i)
              end;
              if dmData.DebugLevel>=1 then Writeln('mode:',mode);
              cmbMode.Text := mode
            end
          end;
      2 : cmbMode.Text := cqrini.ReadString('fldigi','defmode','RTTY')
    end;

    i := Pos('call',buf.mtext);
    if i > 0 then
    begin
      i := i+4;
      while buf.mtext[i] <> chr(1) do
      begin
        call := call + buf.mtext[i];
        inc(i)
      end;
      if dmData.DebugLevel>=1 then Writeln('Call:',call);
      edtCall.Text := call;
      edtCallExit(nil)
    end;
    i := Pos('time',buf.mtext);
    if i > 0 then
    begin
      i := i+4;
      while buf.mtext[i] <> chr(1) do
      begin
        time1 := time1 + buf.mtext[i];
        inc(i)
      end;
      if dmData.DebugLevel>=1 then Writeln('Time on:',time1);
      if Length(time1) = 4 then
        edtStartTime.Text := time1[1]+time1[2]+':'+time1[3]+time1[4]
      else
        edtStartTime.Text := time1
    end;
    i := Pos('endtime',buf.mtext);
    if i > 0 then
    begin
      i := i+7;
      while buf.mtext[i] <> chr(1) do
      begin
        time2 := time2 + buf.mtext[i];
        inc(i)
      end;
      if dmData.DebugLevel>=1 then Writeln('Time off:',time2);
      if Length(time2) = 4 then
        edtEndTime.Text := time2[1]+time2[2]+':'+time2[3]+time2[4]
      else
        edtEndTime.Text := time2
    end;
    i := Pos('name',buf.mtext);
    if i > 0 then
    begin
      i := i+4;
      while buf.mtext[i] <> chr(1) do
      begin
        sname := sname + buf.mtext[i];
        inc(i)
      end;
      if dmData.DebugLevel>=1 then Writeln('Name:',sname);
      edtName.Text := sname;
      edtNameExit(nil)
    end;
    i := Pos('qth',buf.mtext);
    if i > 0 then
    begin
      i := i+3;
      while buf.mtext[i] <> chr(1) do
      begin
        qth := qth + buf.mtext[i];
        inc(i)
      end;
      if dmData.DebugLevel>=1 then Writeln('qth:',qth);
      edtQTH.Text := qth;
      edtQTHExit(nil)
    end;
    i := Pos('locator',buf.mtext);
    if i > 0 then
    begin
      i := i+7;
      while buf.mtext[i] <> chr(1) do
      begin
        loc := loc + buf.mtext[i];
        inc(i)
      end;
      if dmData.DebugLevel>=1 then Writeln('loc:',loc);
      if dmUtils.IsLocOK(loc) then
        edtGrid.Text := loc
    end;


    case cqrini.ReadInteger('fldigi','rst',0) of
      0 : begin
            i := Pos('rx',buf.mtext);
            if i > 0 then
            begin
              i := i+2;
              while buf.mtext[i] <> chr(1) do
              begin
                rst := rst + buf.mtext[i];
                inc(i)
              end;
              if dmData.DebugLevel>=1 then Writeln('rst_r:',rst);
              if rst = '' then
                rst := cqrini.ReadString('fldigi','defrst','599');
              edtMyRST.Text := rst
            end;
            rst := '';
            i := Pos('tx',buf.mtext);
            if i > 0 then
            begin
              i := i+2;
              while buf.mtext[i] <> chr(1) do
              begin
                rst := rst + buf.mtext[i];
                inc(i)
              end;
              if dmData.DebugLevel>=1 then Writeln('rst_r:',rst);
              if rst = '' then
                rst := cqrini.ReadString('fldigi','defrst','599');
              edtHisRST.Text := rst
            end
          end;
      1 : begin
            edtHisRST.Text := cqrini.ReadString('fldigi','defrst','599');
            edtMyRST.Text  := cqrini.ReadString('fldigi','defrst','599')
          end
    end;
    i := Pos('state',buf.mtext);
    if i > 0 then
    begin
      i := i+5;
      while buf.mtext[i] <> chr(1) do
      begin
        state := state + buf.mtext[i];
        inc(i)
      end;
      if dmData.DebugLevel>=1 then Writeln('state:',state);
      edtState.Text := state;
      edtStateExit(nil)
    end;
    i := Pos('notes',buf.mtext);
    if i > 0 then
    begin
      i := i+5;
      while buf.mtext[i] <> chr(1) do
      begin
        note := note + buf.mtext[i];
        inc(i)
      end;
      if dmData.DebugLevel>=1 then Writeln('note:',note);
      edtRemQSO.Text := note
    end;
    btnSave.Click
  end
end;

procedure TfrmNewQSO.tmrRadioTimer(Sender: TObject);
var
  mode, freq, band : String;
  dfreq : Double;
begin
  mode := '';
  freq := '';
  if Running then
    exit;
  Running := True;
  try
    if (not (fViewQSO or fEditQSO)) then
    begin
      if (cbOffline.Checked and (not mnuRemoteMode.Checked)) then
        exit;
      if (frmTRXControl.GetModeFreqNewQSO(mode,freq)) then
      begin
        if( mode <> '') and chkAutoMode.Checked then
          cmbMode.Text := mode;
        if (freq <> empty_freq) then
        begin
          cmbFreq.Text := freq;
          if ClearAfterFreqChange and sbtnHamQTH.Visible then
          begin
            dfreq := frmTRXControl.GetFreqMHz;
            if (FreqBefChange<>0) and ((dfreq < (FreqBefChange-ChangeFreqLimit)) or
               (dfreq > (FreqBefChange+ChangeFreqLimit))) then
               ClearAll
          end
          else
            FreqBefChange := frmTRXControl.GetFreqMHz
        end;
        if (mode <> '') and (freq <> empty_freq) then
        begin
          band := dmUtils.GetBandFromFreq(freq);
          if (mode <> old_t_mode) or (band <> old_t_band) then
          begin
            old_t_mode := mode;
            old_t_band := band
          end
        end
      end
    end
  finally
    Running := False
  end
end;

procedure TfrmNewQSO.tmrStartStartTimer(Sender: TObject);
begin
  tmrStartTimer(nil)
end;

procedure TfrmNewQSO.tmrStartTimer(Sender: TObject);
var
  Date : TDateTime;
  sDate : String='';
  Mask  : String='';
begin
  if not cbOffline.Checked then
  begin
    date := dmUtils.GetDateTime(0);
    StartTime := date;
    edtDate.Clear;
    dmUtils.DateInRightFormat(date,Mask,sDate);
    edtDate.Text      := sDate;
    edtStartTime.Text := FormatDateTime('hh:mm',date);
    edtEndTime.Text   := FormatDateTime('hh:mm',date)
  end
end;

procedure TfrmNewQSO.FormCreate(Sender: TObject);
begin
  CWint := nil;
  tmrRadio.Enabled := False;
  dmUtils.InsertQSL_S(cmbQSL_S);
  dmUtils.InsertQSL_R(cmbQSL_R);
  fViewQSO := False;
  fEditQSO := False;
  FromDXC  := False;
  ShowWin  := False;
  old_t_band := '';
  old_t_mode := '';
  old_prof   := -1
end;

procedure TfrmNewQSO.btnSaveClick(Sender: TObject);
var
  tmp    : Integer;
  myloc  : String;
  id     : LongInt;
  Delete : Boolean = False;
  ShowMain : Boolean = False;
  freq     : Double;
  ton,toff : Word;
  date     : Tdate;
  stmp     : String;
begin
  ShowMain := (fEditQSO or fViewQSO) and (not fromNewQSO);
  if not cbOffline.Checked then
  begin
    edtStartTimeExit(nil);
    edtEndTimeExit(nil)
  end;
  if fViewQSO then
    exit;
  if edtCall.Text = '' then
    exit;
  if not dmUtils.IsDateOK(edtDate.Text) then
  begin
    Application.MessageBox('You must enter correct date!', 'Error', mb_ok + mb_IconError);
    edtDate.SetFocus;
    exit
  end;

  if not dmUtils.IsTimeOK(edtStartTime.Text) then
  begin
    Application.MessageBox('You must enter correct time!', 'Error', mb_ok + mb_IconError);
    edtStartTime.SetFocus;
    exit
  end;

  if not dmUtils.IsTimeOK(edtEndTime.Text) then
  begin
    Application.MessageBox('You must enter correct time!', 'Error', mb_ok + mb_IconError);
    edtEndTime.SetFocus;
    exit
  end;

  tmp := 0;
  if NOT TryStrToInt(edtWAZ.Text,tmp) then
  begin
    Application.MessageBox('You must enter correct WAZ zone!','Error', MB_ICONERROR + MB_OK);
    edtWAZ.SetFocus;
    exit
  end;

  if NOT TryStrToInt(edtITU.Text,tmp) then
  begin
    Application.MessageBox('You must enter correct ITU zone!','Error', MB_ICONERROR + MB_OK);
    edtITU.SetFocus;
    exit
  end;

  SaveGrid;
  dmData.SaveComment(edtCall.Text,mComment.Text);
  if edtITU.Text = '' then
    edtITU.Text := '0';
  if edtWAZ.Text = '' then
    edtWAZ.Text := '0';

  myloc := sbNewQSO.Panels[0].Text;
  myloc := copy(sbNewQSO.Panels[0].Text,Length(cMyLoc)+1,6);
  if NOT dmUtils.IsLocOK(myloc) then
    myloc := '';

  //Writeln('OldCall:',old_call);
  //Writeln('OldPfx:',old_pfx);
  //Writeln('ChangeDXCC:',ChangeDXCC);

  if (old_call = edtCall.Text) and (old_adif <> adif) then
    ChangeDXCC := True; //if user chooses another country by direct enter to the edtDXCCref
                     //without clicking to btnDXCCRef

  old_prof := cmbProfiles.ItemIndex;

  if fEditQSO then
  begin
    if fromNewQSO then
      id := dmData.qQSOBefore.FieldByName('id_cqrlog_main').AsInteger
    else
      id := dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger;
    dmData.EditQSO(dmUtils.StrToDateFormat(edtDate.Text),
                   edtStartTime.Text,
                   edtEndTime.Text,
                   edtCall.Text,
                   StrToCurr(cmbFreq.Text),
                   cmbMode.Text,
                   edtHisRST.Text,
                   edtMyRST.Text,
                   edtName.Text,
                   edtQTH.Text,
                   cmbQSL_S.Text,
                   cmbQSL_R.Text,
                   edtQSL_VIA.Text,
                   cmbIOTA.Text,
                   edtPWR.Text,
                   StrToInt(edtITU.Text),
                   StrToInt(edtWAZ.Text),
                   edtGrid.Text,
                   myloc,
                   edtCounty.Text,
                   edtAward.Text,
                   edtRemQSO.Text,
                   adif,
                   idcall,
                   edtState.Text,
                   lblCont.Caption,
                   ChangeDXCC,
                   dmData.GetNRFromProfile(cmbProfiles.Text),
                   id)
  end
  else begin
    if not mnuRemoteMode.Checked then
      if edtCall.Focused then
      begin
        edtCallExit(nil)
      end;

    date := StrToDate(edtDate.Text);
    {
    if (not cbOffline.Checked) or (mnuRemoteMode.Checked) then
    begin
      stmp    := edtStartTime.Text;
      stmp[3] := char('');
      ton     := StrToInt(stmp);

      stmp    := edtEndTime.Text;
      stmp[3] := char('');
      toff    := StrToInt(stmp);

      if (ton > toff) then
        date := date-1
    end;
    }
    cqrini.WriteString('TMPQSO','FREQ',cmbFreq.Text);
    cqrini.WriteString('TMPQSO','Mode',cmbMode.Text);
    cqrini.WriteString('TMPQSO','PWR',edtPWR.Text);
    cqrini.WriteBool('TMPQSO','OFF',cbOffline.Checked);
    delete := cqrini.ReadBool('BandMap','DeleteAfterQSO',True);
    if edtITU.Text = '' then
      edtITU.Text := '0';
    if edtWAZ.Text = '' then
      edtWAZ.Text := '0';

    if Delete then
      frmBandMap.DeleteFromBandMap(edtCall.Text,dmUtils.GetBandFromFreq(cmbFreq.Text),cmbMode.Text);
    if cqrini.ReadBool('BandMap','AddAfterQSO',False) then
      acAddToBandMap.Execute;

    dmData.SaveQSO(date,
                   edtStartTime.Text,
                   edtEndTime.Text,
                   edtCall.Text,
                   StrToCurr(cmbFreq.Text),
                   cmbMode.Text,
                   edtHisRST.Text,
                   edtMyRST.Text,
                   edtName.Text,
                   edtQTH.Text,
                   cmbQSL_S.Text,
                   cmbQSL_R.Text,
                   edtQSL_VIA.Text,
                   cmbIOTA.Text,
                   edtPWR.Text,
                   StrToInt(edtITU.Text),
                   StrToInt(edtWAZ.Text),
                   edtGrid.Text,
                   myloc,
                   edtCounty.Text,
                   edtAward.Text,
                   edtRemQSO.Text,
                   adif,
                   idcall,
                   edtState.Text,
                   lblCont.Caption,
                   ChangeDXCC,
                   dmData.GetNRFromProfile(cmbProfiles.Text),
                   frmQSODetails.ClubNR1,
                   frmQSODetails.ClubNR2,
                   frmQSODetails.ClubNR3,
                   frmQSODetails.ClubNR4,
                   frmQSODetails.ClubNR5)
  end;
  if fEditQSO and (not fromNewQSO) then
  begin
    dmData.RefreshMainDatabase(id)
  end;
  if not mnuRemoteMode.Checked then
    UnsetEditLabel;
  dmData.qQSOBefore.Close;
  fEditQSO := False;
  edtCall.Text := ''; //calls Clear.All
  old_ccall := '';
  old_cfreq := '';
  old_cmode := '';

  if cqrini.ReadBool('NewQSO','ClearRIT',False) then
    frmTRXControl.ClearRIT;

  if (cqrini.ReadBool('NewQSO','RefreshAfterSave',False) and frmMain.Showing) then
    frmMain.acRefresh.Execute;

  if ShowMain and frmMain.Showing then
  begin
    frmMain.BringToFront;
    frmMain.BringToFront;
    frmMain.dbgrdMain.SetFocus
  end
  else
    if not mnuRemoteMode.Checked then
     edtCall.SetFocus
end;

procedure TfrmNewQSO.btnCancelClick(Sender: TObject);
begin
  acClose.Execute
end;

procedure TfrmNewQSO.edtCallKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  tmp  : Extended = 0;
  mode : String  = '';
  Skip : Boolean = False;
begin
  if ((key = 40) or ((key = VK_SPACE) and UseSpaceBar)) then  //down arrow
  begin
     skip :=  cqrini.ReadBool('NewQSO','SkipModeFreq',True);
    if (not skip) or fEditQSO or fViewQSO or cbOffline.Checked then
      cmbFreq.SetFocus
    else begin
      edtHisRST.SetFocus;
      edtHisRST.SelStart  := 1;
      edtHisRST.SelLength := 1;
    end;
    key := 0;
    exit
  end;
  if (key = 38) then //up arrow
  begin
    mComment.SetFocus;
    key := 0;
    exit
  end;
  if key = 13 then
  begin
    key := 0;
    if TryStrToFloat(edtCall.Text,tmp) then
    begin
      mode := dmUtils.GetModeFromFreq(FloatToStr(tmp/1000));
      frmTRXControl.SetModeFreq(mode,FloatToStr(tmp));
      key := 0;
      edtCall.Text := '';
      exit
    end
    else
      btnSave.Click
  end;
  if key = VK_TAB then
    TabUsed := True
end;


procedure TfrmNewQSO.edtCallKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if not ((chr(key) in AllowedCallChars)) then
    exit;
  if (edtCall.Text='') or (Length(edtCall.Text) < 2) then
  begin
    lblQSLMgr.Visible := False;
    edtQSL_VIA.Text   :=  '';
    frmSCP.mSCP.Clear;
    exit
  end;
  if (not (fViewQSO or fEditQSO or cbOffline.Checked or lblQSOTakes.Visible)) then
  begin
    SetDateTime();
    ShowDXCCInfo
  end
  else begin
    if ChangeDXCC then
      ShowDXCCInfo(adif)
    else
      ShowDXCCInfo
  end;
  if old_adif <> adif then
  begin
    old_adif := adif;
    ShowCountryInfo;
    ChangeReports;
    ShowStatistic(adif)
  end;

  CalculateDistanceEtc;
  if (lblDXCC.Caption <> '!') and (lblDXCC.Caption <> '#') then
  begin
    if frmGrayline.Showing then
    begin
      frmGrayline.s := lblLat.Caption;
      frmGrayline.d := lblLong.Caption;
      frmGrayline.pfx := lblDXCC.Caption;
      frmGrayline.kresli
    end
  end;
  if NOT (old_call = '') then
  begin
    if (old_call <> edtCall.Text) and (QTHfromCb) then
    begin
      edtName.Text := '';
      edtQTH.Text  := ''
    end
  end
end;

procedure TfrmNewQSO.edtCountyEnter(Sender: TObject);
begin
  if (dmUtils.IsIOTAOK(cmbIOTA.Text)) then
  begin
    frmQSODetails.iota := cmbIOTA.Text
  end;
  edtCounty.SelectAll
end;

procedure TfrmNewQSO.edtCountyExit(Sender: TObject);
begin
  CheckCountyClub
end;

procedure TfrmNewQSO.edtCountyKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtState.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    cmbIOTA.SetFocus;
    key := 0;
  end;
end;

procedure TfrmNewQSO.edtCQKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    cmbIOTA.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    edtITU.SetFocus;
    key := 0;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    cmbIOTA.SetFocus;
    key := 0
  end
end;

procedure TfrmNewQSO.edtDateExit(Sender: TObject);
var
  tmp : String;
begin
  if fViewQSO then
    exit;
  if Length(edtDate.Text)=8 then
  begin
    tmp := edtDate.Text;
    edtDate.Text := copy(tmp,1,4) + '-' + copy(tmp,5,2) + '-' + copy(tmp,7,2);
  end;
  if not dmUtils.IsDateOK(edtDate.Text) then
    exit;
  if not ChangeDXCC then
  begin
    ShowDXCCInfo;
    ShowCountryInfo;
  end;
  CheckCallsignClub;
  CheckQTHClub;
  CheckAwardClub;
  CheckCountyClub;
end;

procedure TfrmNewQSO.edtDateKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtStartTime.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    edtQSL_VIA.SetFocus;
    key := 0;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    edtStartTime.SetFocus;
    key := 0
  end
end;


procedure TfrmNewQSO.edtAwardKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtDXCCRef.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    edtState.SetFocus;
    key := 0;
  end;
end;

procedure TfrmNewQSO.edtDXCCRefExit(Sender: TObject);
begin
  if lblDXCC.Caption <> edtDXCCRef.Text then
  begin
    ShowCountryInfo;
    ShowCountryInfo;
  end;
end;

procedure TfrmNewQSO.edtDXCCRefKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtRemQSO.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    edtAward.SetFocus;
    key := 0;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    edtRemQSO.SetFocus;
    key := 0
  end
end;

procedure TfrmNewQSO.edtDateKeyPress(Sender: TObject; var Key: char);
begin
  if not ((key in ['0'..'9']) or (key = '-') or (key=#40) or (key=#38) or (key = #32) or (key=#8)) then
    key := #0
end;

procedure TfrmNewQSO.edtEndTimeExit(Sender: TObject);
begin
  if Length(edtEndTime.Text)=4 then
    edtEndTime.Text := copy(edtEndTime.Text,1,2) + ':' +
                       copy(edtEndTime.Text,3,2);
end;

procedure TfrmNewQSO.edtEndTimeKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    mComment.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    edtStartTime.SetFocus;
    key := 0;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    mComment.SetFocus;
    key := 0
  end;
end;

procedure TfrmNewQSO.edtGridExit(Sender: TObject);
begin
  CalculateDistanceEtc;
end;

procedure TfrmNewQSO.edtGridKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtPWR.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    edtQTH.SetFocus;
    key := 0;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    edtPWR.SetFocus;
    key := 0
  end
end;

procedure TfrmNewQSO.edtHisRSTEnter(Sender: TObject);
begin
  cmbModeChange(nil);
  if TabUsed then
  begin
    edtHisRST.SelectAll;
    TabUsed := False
  end
  else begin
    edtHisRST.SelStart  := 1;
    edtHisRST.SelLength := 1
  end
end;

procedure TfrmNewQSO.edtHisRSTKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtMyRST.SetFocus;
    //edtMyRST.SelStart  := 1;
    //edtMyRST.SelLength := 1;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    cmbMode.SetFocus;
    key := 0;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    edtMyRST.SetFocus;
    edtMyRST.SelStart  := 1;
    edtMyRST.SelLength := 1;
    key := 0;
  end;
  if key = VK_TAB then
    TabUsed := True
end;

procedure TfrmNewQSO.edtITUExit(Sender: TObject);
begin
  frmQSODetails.itu := edtITU.Text;
end;

procedure TfrmNewQSO.edtITUKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtWAZ.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    cmbQSL_R.SetFocus;
    key := 0;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    edtWAZ.SetFocus;
    key := 0
  end
end;

procedure TfrmNewQSO.edtMyRSTEnter(Sender: TObject);
begin
  if not (fViewQSO or fEditQSO or cbOffline.Checked or (edtCall.Text='') or lblQSOTakes.Visible ) then
  begin
    SetDateTime(False);
    tmrStart.Enabled := True;
    tmrStartTimer(nil);
    tmrEnd.Enabled   := False;
    tmrStart.Enabled := False;
    tmrEnd.Enabled := True;
    tmrEndTimer(nil);
  end;
  if TabUsed then
  begin
    edtMyRST.SelectAll;
    TabUsed := False
  end
  else begin
    edtMyRST.SelStart  := 1;
    edtMyRST.SelLength := 1
  end
end;

procedure TfrmNewQSO.edtMyRSTKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtName.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    key := 0;
    edtHisRST.SetFocus;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    edtName.SetFocus;
    key := 0;
  end;
end;

procedure TfrmNewQSO.edtNameChange(Sender: TObject);
begin
  QTHfromCb := False;
end;

procedure TfrmNewQSO.edtNameExit(Sender: TObject);
var
  tmp : String;
begin
  if edtName.Text <> '' then
  begin
    tmp := edtName.Text;
    tmp[1] := UpCase(tmp[1]);
    edtName.Text := tmp
  end
end;

procedure TfrmNewQSO.edtNameKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtQTH.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    edtMyRST.SetFocus;
    edtMyRST.SelStart  := 1;
    edtMyRST.SelLength := 1;
    key := 0;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    edtQTH.SetFocus;
    key := 0;
  end;
end;

procedure TfrmNewQSO.edtPWRKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    cmbQSL_S.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    edtGrid.SetFocus;
    key := 0;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    cmbQSL_S.SetFocus;
    key := 0
  end
end;

procedure TfrmNewQSO.edtQSL_VIAKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtDate.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    edtRemQSO.SetFocus;
    key := 0;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    edtDate.SetFocus;
    key := 0
  end
end;

procedure TfrmNewQSO.edtQTHChange(Sender: TObject);
begin
  QTHfromCb := False;
end;

procedure TfrmNewQSO.edtQTHExit(Sender: TObject);
var
  tmp : String;
begin
  if edtQTH.Text <> '' then
  begin
    tmp := edtQTH.Text;
    tmp[1] := UpCase(tmp[1]);
    edtQTH.Text := tmp
  end;
  CheckQTHClub;
end;

procedure TfrmNewQSO.edtQTHKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtGrid.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    edtName.SetFocus;
    key := 0;
  end;
end;

procedure TfrmNewQSO.edtRemQSOKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtQSL_VIA.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    edtDXCCRef.SetFocus;
    key := 0;
  end;
end;

procedure TfrmNewQSO.edtStartTimeExit(Sender: TObject);
begin
  if Length(edtStartTime.Text)=4 then
    edtStartTime.Text := copy(edtStartTime.Text,1,2) + ':' +
                         copy(edtStartTime.Text,3,2);
  if cbOffline.Checked then
    edtEndTime.Text := edtStartTime.Text;
end;

procedure TfrmNewQSO.edtStartTimeKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtEndTime.SetFocus;
    key := 0
  end;
  if (key = 38) then //up arrow
  begin
    edtDate.SetFocus;
    key := 0
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    edtEndTime.SetFocus;
    key := 0
  end
end;

procedure TfrmNewQSO.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SaveSettings;
  dmData.CloseDatabases
end;

procedure TfrmNewQSO.cmbFreqKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    cmbMode.SetFocus;
    key := 0
  end;
  if (key = 38) then //up arrow
  begin
    edtCall.SetFocus;
    key := 0
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    cmbMode.SetFocus;
    key := 0
  end;
  if key = VK_TAB then
  begin
    key := 0;
    cmbMode.SetFocus;
    TabUsed := True
  end;
end;

procedure TfrmNewQSO.cmbIOTAChange(Sender: TObject);
begin
  if (dmUtils.IsIOTAOK(cmbIOTA.Text)) then
  begin
    frmQSODetails.iota := cmbIOTA.Text;
  end;
end;

procedure TfrmNewQSO.cmbIOTAExit(Sender: TObject);
begin
  if (dmUtils.IsIOTAOK(cmbIOTA.Text)) then
  begin
    frmQSODetails.iota := cmbIOTA.Text
  end
end;

procedure TfrmNewQSO.cmbIOTAKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtCounty.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    edtWAZ.SetFocus;
    key := 0;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    edtCounty.SetFocus;
    key := 0;
  end;
end;

procedure TfrmNewQSO.cmbModeChange(Sender: TObject);
begin
  ShowCountryInfo;
  ChangeReports;
end;

procedure TfrmNewQSO.cmbModeEnter(Sender: TObject);
begin
  cmbMode.SelectAll
end;

procedure TfrmNewQSO.cmbModeExit(Sender: TObject);
begin
  if (not (fViewQSO or fEditQSO)) then
    cmbQSL_S.Text := dmData.SendQSL(edtCall.Text,cmbMode.Text,cmbFreq.Text,adif);

  if cmbMode.Text <> old_mode then
  begin
    ShowCountryInfo;
    ChangeReports;
    CheckCallsignClub
  end
end;

procedure TfrmNewQSO.cmbFreqEnter(Sender: TObject);
begin
  cmbFreq.SelectAll
end;

procedure TfrmNewQSO.btnDXCCRefClick(Sender: TObject);
var
  waz,itu,cont,lat,long,cname : String;
  old,new : String;
begin
  if fViewQSO then
    exit;
  frmSelectDXCC := TfrmSelectDXCC.Create(self);
  try
    frmSelectDXCC.edtPrefix.Text := edtDXCCRef.Text;
    old := edtDXCCRef.Text;
    frmSelectDXCC.ntbSelectDXCC.PageIndex := 0;
    frmSelectDXCC.ShowModal;
    if frmSelectDXCC.ModalResult = mrOK then
    begin
      if Pos('*',frmSelectDXCC.edtPrefix.Text) = 0 then
      begin
        new   := dmDXCC.qValid.Fields[1].AsString;
        cname := dmDXCC.qValid.Fields[2].AsString;
        cont  := dmDXCC.qValid.Fields[3].AsString;
        lat   := dmDXCC.qValid.Fields[5].AsString;
        long  := dmDXCC.qValid.Fields[6].AsString;
        itu   := dmDXCC.qValid.Fields[7].AsString;
        waz   := dmDXCC.qValid.Fields[8].AsString;
        adif  := dmDXCC.qValid.FieldByName('ADIF').AsInteger
      end
      else begin
        new   := dmDXCC.qDeleted.Fields[1].AsString;
        cname := dmDXCC.qDeleted.Fields[2].AsString;
        cont  := dmDXCC.qDeleted.Fields[3].AsString;
        lat   := dmDXCC.qDeleted.Fields[5].AsString;
        long  := dmDXCC.qDeleted.Fields[6].AsString;
        itu   := dmDXCC.qDeleted.Fields[7].AsString;
        waz   := dmDXCC.qDeleted.Fields[8].AsString;
        adif  := dmDXCC.qDeleted.FieldByName('ADIF').AsInteger
      end;
      if old = new then
        exit;
      ChangeDXCC         := True;
      edtDXCCRef.Text    := new;
      lblDXCC.Caption    := new;
      mCountry.Clear;
      mCountry.Text      := cname;
      lblWAZ.Caption     := waz;
      lblITU.Caption     := itu;
      lblCont.Caption    := cont;
      lblLat.Caption     := lat;
      lblLong.Caption    := long;
      dmUtils.ModifyWAZITU(waz,itu);
      edtWAZ.Text        := waz;
      edtITU.Text        := itu;
      lblHisTime.Caption := dmUtils.HisDateTime(edtDXCCRef.Text);
      ShowCountryInfo;
      ShowStatistic(adif);
      if dmData.GetIOTAForDXCC(edtCall.Text,lblDXCC.Caption,cmbIOTA,dmUtils.MyStrToDate(edtDate.Text)) then
        lblIOTA.Font.Color := clRed
      else
        lblIOTA.Font.Color := clBlue
    end
  finally
    frmSelectDXCC.Free
  end
end;

procedure TfrmNewQSO.btnQSLMgrClick(Sender: TObject);
begin
  frmQSLMgr := TfrmQSLMgr.Create(self);
  try
    dmData.qQSLMgr.SQL.Text := 'select callsign,qsl_via,fromdate from cqrlog_common.qslmgr order by callsign,fromDate';
    if dmData.trQSLMgr.Active then
      dmData.trQSLMgr.Rollback;
    dmData.trQSLMgr.StartTransaction;
    dmData.qQSLMgr.Open;
    frmQSLMgr.edtCallsign.Text := edtCall.Text;
    frmQSLMgr.btnFind.Click;
    frmQSLMgr.ShowModal;
    if frmQSLMgr.ModalResult = mrOK then
      edtQSL_VIA.Text := dmData.qQSLMgr.Fields[1].AsString
  finally
    dmData.qQSLMgr.Close;
    dmData.trQSLMgr.Rollback;
    frmQSLMgr.Free
  end
end;

procedure TfrmNewQSO.acCloseExecute(Sender: TObject);
begin
  Close
end;

procedure TfrmNewQSO.acDXCCCfmExecute(Sender: TObject);
begin
  with TfrmDXCCStat.Create(self) do
  try
    ShowModal
  finally
    Free
  end
end;

procedure TfrmNewQSO.acDXClusterExecute(Sender: TObject);
begin
  if frmDXCluster.Showing then
    frmDXCluster.BringToFront
  else
    frmDXCluster.Show;
end;

procedure TfrmNewQSO.acDetailsExecute(Sender: TObject);
begin
  frmQSODetails.Show;
  frmQSODetails.BringToFront;
end;

procedure TfrmNewQSO.acEditQSOExecute(Sender: TObject);
begin
  if (dmData.qQSOBefore.RecordCount > 0) and (not mnuRemoteMode.Checked) then
  begin
    Caption := dmUtils.GetNewQSOCaption('Edit QSO');
    EditQSO := True;
    ViewQSO := False;
    SetEditLabel;
    fromNewQSO := true;
    ShowQSO
  end
end;

procedure TfrmNewQSO.acGraylineExecute(Sender: TObject);
begin
  if frmGrayline.Showing then
    frmGrayline.BringToFront
  else
    frmGrayline.Show;
end;

procedure TfrmNewQSO.acITUCfmExecute(Sender: TObject);
begin
  with TfrmWAZITUStat.Create(self) do
  try
    StatType := tsITU;
    ShowModal
  finally
    Free
  end
end;

procedure TfrmNewQSO.acLongNoteExecute(Sender: TObject);
var
  new : Boolean = False;
begin
  with TfrmLongNote.Create(self) do
  try
    dmData.qLongNote.Close();
    dmData.qLongNote.SQL.Text := 'SELECT id_long_note, note FROM long_note';
    dmData.qLongNote.Open();
    if dmData.qLongNote.Fields[0].IsNull then
      new := True;
    mNote.Lines.Text := dmData.qLongNote.Fields[1].AsString;
    dmData.qLongNote.Close;
    ShowModal;
    if ModalResult = mrOK then
    begin
      if new then
        dmData.qLongNote.SQL.Text := 'insert into long_note(id_long_note,note) values (1,:note)'
      else
        dmData.qLongNote.SQL.Text := 'UPDATE long_note set note = :note where id_long_note = 1';
      dmData.qLongNote.Params[0].AsString := mNote.Text;
      dmData.trLongNote.StartTransaction;
      dmData.qLongNote.ExecSQL;
      dmData.trLongNote.Commit;
      dmData.qLongNote.Close()
    end
  finally
    Free
  end
end;

procedure TfrmNewQSO.MenuItem9Click(Sender: TObject);
begin
  with TfrmAbout.Create(Application) do
  try
    ShowModal
  finally
    Free
  end
end;

procedure TfrmNewQSO.acRemoteModeExecute(Sender: TObject);
var
  run    : Boolean = False;
  path   : String = '';
begin
  if mnuRemoteMode.Checked then
  begin
    tmrFldigi.Enabled     := False;
    mnuRemoteMode.Checked := False;
    lblCall.Caption       := 'Call:';
    lblCall.Font.Color    := clBlue;
    edtCall.Enabled       := True;
    cbOffline.Checked     := False;
    edtCall.SetFocus
  end
  else begin
    tmrFldigi.Interval := cqrini.ReadInteger('fldigi','interval',2)*1000;
    run                := cqrini.ReadBool('fldigi','run',False);
    path               := cqrini.ReadString('fldigi','path','');

    ClearAll;
    mnuRemoteMode.Checked := True;
    lblCall.Caption       := 'Remote mode!';
    lblCall.Font.Color    := clRed;
    edtCall.Enabled       := False;
    tmrFldigi.Enabled     := True;
    cbOffline.Checked     := True;
    if run and FileExists(path) then
      dmUtils.RunOnBackgroud(path)
  end
end;

procedure TfrmNewQSO.acWASCfmExecute(Sender: TObject);
begin
  with TfrmWAZITUStat.Create(self) do
  try
    StatType := tsWAS;
    ShowModal
  finally
    Free
  end
end;

procedure TfrmNewQSO.acAddToBandMapExecute(Sender: TObject);
var
  f : Double;
begin
  f := frmTRXControl.GetFreqMHz;
  if f = 0.0 then
    f := StrToFloat(cmbFreq.Text);
  frmBandMap.AddFromNewQSO(edtDXCCRef.Text,'*'+edtCall.Text,f,dmUtils.GetBandFromFreq(cmbFreq.Text)
  ,cmbMode.Text,lblLat.Caption,lblLong.Caption)
end;

procedure TfrmNewQSO.acCWMessagesExecute(Sender: TObject);
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

procedure TfrmNewQSO.acCWTypeExecute(Sender: TObject);
begin
  with TfrmCWType.Create(self) do
  try
    edtSpeed.Value := CWint.GetSpeed;
    ShowModal
  finally
    Free
  end
end;

procedure TfrmNewQSO.FormActivate(Sender: TObject);
begin
  if minimalize then
  begin
    minimalize := False;
    if MinTRXControl then
    begin
       frmTRXControl.BringToFront;
       MinTRXControl := False
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
    ShowWindows
  end
end;

procedure TfrmNewQSO.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  Writeln('OnCloseQuery - NewQSO')
end;

procedure TfrmNewQSO.edtCallChange(Sender: TObject);
begin
  if not EditQSO then
    if edtCall.Text = '' then
      ClearAll;
  if frmSCP.Showing and (Length(edtCall.Text)>2) then
    frmSCP.mSCP.Text := dmData.GetSCPCalls(edtCall.Text)
  else
    frmSCP.mSCP.Clear
end;

procedure TfrmNewQSO.edtDateEnter(Sender: TObject);
begin
  edtDate.SelectAll
end;

procedure TfrmNewQSO.edtDXCCRefEnter(Sender: TObject);
begin
  edtDXCCRef.SelectAll
end;

procedure TfrmNewQSO.edtEndTimeEnter(Sender: TObject);
begin
  edtEndTime.SelectAll
end;

procedure TfrmNewQSO.edtGridEnter(Sender: TObject);
begin
  edtGrid.SelectAll
end;

procedure TfrmNewQSO.acPropExecute(Sender: TObject);
begin
  frmPropagation.Show
end;

procedure TfrmNewQSO.acQSOListExecute(Sender: TObject);
begin
  frmMain.Show
end;

procedure TfrmNewQSO.acRefreshTRXExecute(Sender: TObject);
begin
  frmTRXControl.InicializeRig;
  tmrRadio.Enabled := True;
  frmRotControl.InicializeRot;
  tmrRotor.Enabled := True
end;

procedure TfrmNewQSO.acReloadCWExecute(Sender: TObject);
begin
  InitializeCW
end;

procedure TfrmNewQSO.acRotControlExecute(Sender: TObject);
begin
  frmRotControl.Show
end;

procedure TfrmNewQSO.acSCPExecute(Sender : TObject);
begin
  frmSCP.Show
end;

procedure TfrmNewQSO.acSendSpotExecute(Sender : TObject);
begin
  SendSpot
end;

procedure TfrmNewQSO.acShowStatBarExecute(Sender: TObject);
begin
  if sbNewQSO.Visible then
  begin
    sbNewQSO.Visible := False;
    acShowStatBar.Checked := False
  end
  else begin
    sbNewQSO.Visible := True;
    acShowStatBar.Checked := False
  end
end;

procedure TfrmNewQSO.acTuneExecute(Sender : TObject);
begin
  CWint.TuneStart;
  ShowMessage('Tunning started .... '+LineEnding+LineEnding+'OK to abort');
  CWint.TuneStop
end;

procedure TfrmNewQSO.acCWFKeyExecute(Sender: TObject);
begin
  UpdateFKeyLabels;
  frmCWKeys.Show
end;

procedure TfrmNewQSO.acBigSquareExecute(Sender: TObject);
begin
  frmBigSquareStat := TfrmBigSquareStat.Create(frmNewQSO);
  try
    frmBigSquareStat.ShowModal
  finally
    FreeAndNil(frmBigSquareStat)
  end
end;

procedure TfrmNewQSO.acOpenLogExecute(Sender: TObject);
var
  old : String;
begin
  with TfrmDBConnect.Create(self) do
  try
    old := dmData.LogName;
    OpenFromMenu := True;
    ShowModal;
    if ModalResult = mrOK then
    begin
      if old = dmData.qLogList.Fields[1].AsString then exit;
      frmDXCluster.StopAllConnections;
      SaveSettings;
      dmData.CloseDatabases;
      dmData.OpenDatabase(dmData.qLogList.Fields[0].AsInteger);
      dmData.LogName    := dmData.qLogList.Fields[1].AsString;
      frmNewQSO.Caption := dmUtils.GetNewQSOCaption('New QSO');
      LoadSettings;
      ShowFields
    end
  finally
    Free
  end
end;

procedure TfrmNewQSO.chkAutoModeChange(Sender: TObject);
begin
  frmTRXControl.AutoMode := chkAutoMode.Checked
end;

procedure TfrmNewQSO.cmbFreqExit(Sender: TObject);
begin
  if (not (fViewQSO or fEditQSO)) then
    cmbQSL_S.Text := dmData.SendQSL(edtCall.Text,cmbMode.Text,cmbFreq.Text,adif);
  CheckCallsignClub;
  CheckQTHClub;
  CheckAwardClub;
  CheckCountyClub;
  CheckStateClub
end;

procedure TfrmNewQSO.cmbIOTAEnter(Sender: TObject);
begin
  cmbIOTA.SelectAll
end;

procedure TfrmNewQSO.cmbQSL_REnter(Sender: TObject);
begin
  cmbQSL_R.SelectAll
end;

procedure TfrmNewQSO.cmbQSL_SEnter(Sender: TObject);
begin
  cmbQSL_S.SelectAll
end;

procedure TfrmNewQSO.dbgrdQSOBeforeColumnSized(Sender: TObject);
begin
  SaveGrid
end;

procedure TfrmNewQSO.edtAwardEnter(Sender: TObject);
begin
  edtAward.SelectAll
end;

procedure TfrmNewQSO.edtHisRSTExit(Sender: TObject);
begin
  edtHisRST.SelStart  := 0;
  edtHisRST.SelLength := 0
end;

procedure TfrmNewQSO.edtITUEnter(Sender: TObject);
begin
  edtITU.SelectAll
end;

procedure TfrmNewQSO.edtMyRSTExit(Sender: TObject);
begin
  edtMyRST.SelStart  := 0;
  edtMyRST.SelLength := 0
end;

procedure TfrmNewQSO.edtNameEnter(Sender: TObject);
var
  tmp : String;
begin
  if edtName.Text <> '' then
  begin
    tmp := edtName.Text;
    tmp[1] := UpCase(tmp[1]);
    edtName.Text := tmp
  end;
  edtName.SelectAll
end;

procedure TfrmNewQSO.edtPWREnter(Sender: TObject);
begin
  edtPWR.SelectAll
end;

procedure TfrmNewQSO.edtQSL_VIAEnter(Sender: TObject);
begin
  edtQSL_VIA.SelectAll
end;

procedure TfrmNewQSO.edtQTHEnter(Sender: TObject);
begin
  edtQTH.SelectAll
end;

procedure TfrmNewQSO.edtRemQSOEnter(Sender: TObject);
begin
  edtRemQSO.SelectAll
end;

procedure TfrmNewQSO.edtStartTimeEnter(Sender: TObject);
begin
  edtStartTime.SelectAll
end;

procedure TfrmNewQSO.edtStateEnter(Sender: TObject);
begin
  edtState.SelectAll
end;

procedure TfrmNewQSO.edtWAZEnter(Sender: TObject);
begin
  edtWAZ.SelectAll
end;

procedure TfrmNewQSO.FormWindowStateChange(Sender: TObject);
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
      frmGrayline.SavePosition;
      MinGrayLine := True;
    end;
    if frmTRXControl.Showing then
    begin
      frmTRXControl.SavePosition;
      MinTRXControl := True;
    end;
    if frmQSODetails.Showing then
    begin
      MinQSODetails := True
    end
  end
end;

procedure TfrmNewQSO.MenuItem11Click(Sender: TObject);
begin
  with TfrmWAZITUStat.Create(self) do
  try
    StatType := tsWAZ;
    ShowModal;
  finally
    Free
  end;
end;

procedure TfrmNewQSO.MenuItem12Click(Sender: TObject);
begin
  with TfrmWAZITUStat.Create(self) do
  try
    StatType := tsITU;
    ShowModal
  finally
    Free
  end;
end;

procedure TfrmNewQSO.MenuItem17Click(Sender: TObject);
begin
  ShowHelp
end;

procedure TfrmNewQSO.MenuItem45Click(Sender: TObject);
var
   AProcess: TProcess;
begin
  AProcess := TProcess.Create(nil);
  try
    AProcess.CommandLine := cqrini.ReadString('Program','WebBrowser','firefox')+
                            ' http://www.qrz.com/callsign/'+
                            dmData.qQSOBefore.Fields[4].AsString;
    Writeln('Command line: ',AProcess.CommandLine);
    AProcess.Execute
  finally
    AProcess.Free
  end
end;

procedure TfrmNewQSO.MenuItem46Click(Sender: TObject);
var
   AProcess: TProcess;
begin
  AProcess := TProcess.Create(nil);
  try
    AProcess.CommandLine := cqrini.ReadString('Program','WebBrowser','firefox')+
                            ' http://www.ik3qar.it/manager/man_result.php?call='+
                            dmData.qQSOBefore.Fields[4].AsString;
    Writeln('Command line: ',AProcess.CommandLine);
    AProcess.Execute
  finally
    AProcess.Free
  end
end;


procedure TfrmNewQSO.MenuItem84Click(Sender : TObject);
begin
  sbtnHamQTH.Click
end;

procedure TfrmNewQSO.acNewQSOExecute(Sender: TObject);
begin
  ClearAll;
end;

procedure TfrmNewQSO.acPreferencesExecute(Sender: TObject);
begin
  with TfrmPreferences.Create(self) do
  try
    ShowModal;
    if ModalResult = mrOK then
    begin
      if frmMain.Showing then
        dmUtils.LoadFontSettings(frmMain);
      dmUtils.LoadFontSettings(frmNewQSO);
      if frmTRXControl.Showing then
        dmUtils.LoadFontSettings(frmTRXControl);
      if frmQSODetails.Showing then
        frmQSODetails.LoadFonts;
    end;
    ChangeCallBookCaption
  finally
    Free
  end
end;

procedure TfrmNewQSO.acQSOperModeExecute(Sender: TObject);
begin
  with TfrmGraphStat.Create(self) do
  try
    chrtStat.Title.Text.Text := 'QSO per mode';
    chrtStat.Title.Alignment := taCenter;
    QSOperMode;
    ShowModal;
  finally
    Free
  end;
end;

procedure TfrmNewQSO.acShowBandMapExecute(Sender: TObject);
begin
  if frmBandMap.Showing then
    frmBandMap.BringToFront
  else
    frmBandMap.Show;
end;

procedure TfrmNewQSO.acTRXControlExecute(Sender: TObject);
begin
  if frmTRXControl.Showing then
    frmTRXControl.BringToFront
  else
    frmTRXControl.Show;
end;

procedure TfrmNewQSO.acViewQSOExecute(Sender: TObject);
begin
  if (dmData.qQSOBefore.RecordCount > 0) and (not mnuRemoteMode.Checked) then
  begin
    ViewQSO := True;
    Caption := dmUtils.GetNewQSOCaption('View QSO');
    BringToFront;
    EditQSO := False;
    fromNewQSO := True;
    ShowQSO
  end
end;

procedure TfrmNewQSO.acWACCfmExecute(Sender: TObject);
begin
  with TfrmWAZITUStat.Create(self) do
  try
    StatType := tsWAC;
    ShowModal
  finally
    Free
  end
end;


procedure TfrmNewQSO.acWASLoTWExecute(Sender: TObject);
begin
  with TfrmWAZITUStat.Create(self) do
  try
    StatType := tsWAS;
    ShowModal
  finally
    Free
  end
end;

procedure TfrmNewQSO.acWAZCfmExecute(Sender: TObject);
begin
  with TfrmWAZITUStat.Create(self) do
  try
    StatType := tsWAZ;
    ShowModal
  finally
    Free
  end
end;


procedure TfrmNewQSO.acXplanetExecute(Sender: TObject);
begin
  dmUtils.RunXplanet;
end;

procedure TfrmNewQSO.cbOfflineChange(Sender: TObject);
begin
  if not (fViewQSO or fEditQSO) then
    cqrini.WriteBool('TMPQSO','OFF',cbOffline.Checked);
  if cbOffline.Checked then
  begin
    pnlOffline.Color := clRed;
    lblQSOTakes.Visible := False
  end
  else begin
    SetDateTime();
    pnlOffline.Color := ColorToRGB(clBtnFace)
  end
end;

procedure TfrmNewQSO.cmbFreqChange(Sender: TObject);
begin
  ShowCountryInfo;
  ChangeReports
end;

procedure TfrmNewQSO.cmbModeKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    key := 0;
    edtHisRST.SetFocus;
    edtHisRST.SelStart  := 1;
    edtHisRST.SelLength := 1;
  end;
  if (key = 38) then //up arrow
  begin
    cmbFreq.SetFocus;
    key := 0;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    edtHisRST.SetFocus;
    edtHisRST.SelStart  := 1;
    edtHisRST.SelLength := 1;
    key := 0;
  end;
  if key = VK_TAB then
  begin
    key := 0;
    edtHisRST.SetFocus;
    TabUsed := True
  end
end;

procedure TfrmNewQSO.cmbProfilesChange(Sender: TObject);
var
  myloc : String;
begin
  myloc := dmData.GetMyLocFromProfile(cmbProfiles.Text);
  if myloc <> '' then
     sbNewQSO.Panels[0].Text := cMyLoc + myloc;
  if dmData.DebugLevel >=1 then Writeln(cmbProfiles.Text)
end;

procedure TfrmNewQSO.cmbQSL_RKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtItu.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    cmbQSL_S.SetFocus;
    key := 0;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    edtITU.SetFocus;
    key := 0
  end
end;

procedure TfrmNewQSO.cmbQSL_SKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    cmbQSL_R.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    edtPWR.SetFocus;
    key := 0;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    cmbQSL_R.SetFocus;
    key := 0
  end
end;


procedure TfrmNewQSO.dbgrdQSOBeforeDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  if dmData.qQSOBefore.FieldByName('QSL_R').AsString = 'Q' then
  begin
    dbgrdQSOBefore.Canvas.Font.Color := clRed
  end;
  dbgrdQSOBefore.DefaultDrawColumnCell(Rect,DataCol,Column,State)
end;

procedure TfrmNewQSO.edtAwardExit(Sender: TObject);
begin
  CheckAwardClub;
end;

procedure TfrmNewQSO.edtCallEnter(Sender: TObject);
begin
  if not EditQSO then
    old_call := edtCall.Text;
end;

procedure TfrmNewQSO.edtCallExit(Sender: TObject);
var
  mode, freq : String;
  QRZ        : TQRZThread;
  SearchQRZ  : Boolean = False;
  qsl_via    : String = '';
begin
  mode := '';
  freq := '';
  if edtCall.Text='' then
    exit;
  sbtnQRZ.Visible    := True;
  sbtnHamQTH.Visible := True;
  if cqrini.ReadBool('LoTW','ShowInfo',True) then
  begin
    sbtneQSL.Visible := dmData.UseseQSL(edtCall.Text);
    sbtnLoTW.Visible := dmData.UsesLotw(edtCall.Text)
  end;
  if old_adif = 0 then
    old_adif := adif;
  if (old_call = edtCall.Text) and (not fEditQSO) then
    exit;
  if not (fViewQSO or fEditQSO) then
  begin
    if old_call = '' then
    begin
      old_call := edtCall.Text;
      old_mode := cmbMode.Text
    end
    else begin
      if edtCall.Text = old_call then
        exit
    end;
    cqrini.WriteBool('TMPQSO','OFF',cbOffline.Checked);
    SearchQRZ := cqrini.ReadBool('NewQSO','AutoSearch',False)
  end;
  if ChangeDXCC then
    ShowDXCCInfo(adif)
  else
    ShowDXCCInfo();
  {
  if (not (fViewQSO or fEditQSO or cbOffline.Checked or lblQSOTakes.Visible)) or
     ((fEditQSO or fViewQSO) and (old_call <> edtCall.Text))  then
  begin
    if not fEditQSO then
      SetDateTime();
    ShowDXCCInfo
  end
  else begin
    if ChangeDXCC then
      ShowDXCCInfo(adif)
    else
      ShowDXCCInfo
  end;
  }

  if not fromNewQSO then
  begin
    dmData.qQSOBefore.Close;
    if cqrini.ReadBool('NewQSO','AllVariants',False) then
      dmData.qQSOBefore.SQL.Text := 'SELECT * FROM view_cqrlog_main_by_qsodate WHERE idcall = '+
                                    QuotedStr(dmUtils.GetIDCall(edtCall.Text))+' ORDER BY qsodate,time_on'
    else
      dmData.qQSOBefore.SQL.Text := 'SELECT * FROM view_cqrlog_main_by_qsodate WHERE callsign = '+
                                    QuotedStr(edtCall.Text)+' ORDER BY qsodate,time_on';

    if dmData.DebugLevel >=1 then Writeln(dmData.qQSOBefore.SQL.Text);
    if dmData.trQSOBefore.Active then
      dmData.trQSOBefore.Rollback;
    dmData.trQSOBefore.StartTransaction;
    dmData.qQSOBefore.Open;
    ShowFields;
    dmData.qQSOBefore.Last;
    dmUtils.LoadFontSettings(frmNewQSO)
  end;
  if fViewQSO or fEditQSO then
    lblQSONr.Caption := IntToStr(dmData.qQSOBefore.RecordCount)
  else
    lblQSONr.Caption := IntToStr(dmData.qQSOBefore.RecordCount+1);
  ShowCountryInfo;
  ChangeReports;
  ShowStatistic(adif);
  if (not (fViewQSO or fEditQSO)) then
  begin
    InsertNameQTH;
    cmbQSL_S.Text := dmData.SendQSL(edtCall.Text,cmbMode.Text,cmbFreq.Text,adif)
  end;
  CalculateDistanceEtc;
  mComment.Text := dmData.GetComment(edtCall.Text);
  if (lblDXCC.Caption <> '!') and (lblDXCC.Caption <> '#') then
  begin
    if frmGrayline.Showing then
    begin
      frmGrayline.s := lblLat.Caption;
      frmGrayline.d := lblLong.Caption;
      frmGrayline.pfx := lblDXCC.Caption;
      frmGrayline.kresli
    end
  end;
  if NOT (old_call = '') then
  begin
    if (old_call <> edtCall.Text) and (QTHfromCb) then
    begin
      edtName.Text := '';
      edtQTH.Text  := ''
    end
  end;
  if not FromDXC then
  begin
    if (not (fViewQSO or fEditQSO or cbOffline.Checked)) and (frmTRXControl.GetModeFreqNewQSO(mode,freq)) then
    begin
      if chkAutoMode.Checked then
        cmbMode.Text := mode;
      cmbFreq.Text := freq;
      edtHisRST.SetFocus;
      edtHisRST.SelStart  := 1;
      edtHisRST.SelLength := 1
    end
  end;
  lblAmbiguous.Visible := dmDXCC.IsAmbiguous(edtCall.Text);
  if dmData.QSLMgrFound(edtCall.Text,edtDate.Text,qsl_via) then
  begin
    lblQSLMgr.Visible := True;
    if (edtQSL_VIA.Text = '') then
      edtQSL_VIA.Text   := qsl_via
  end;
  frmQSODetails.iota := cmbIOTA.Text;
  if dmData.GetIOTAForDXCC(edtCall.Text,lblDXCC.Caption,cmbIOTA,dmUtils.MyStrToDate(edtDate.Text)) then
    lblIOTA.Font.Color := clRed
  else
    lblIOTA.Font.Color := clBlue;
  frmQSODetails.freq := cmbFreq.Text;
  frmQSODetails.waz  := edtWAZ.Text;
  frmQSODetails.itu  := edtITU.Text;
  frmQSODetails.iota := cmbIOTA.Text;

  if (not (fEditQSO or fViewQSO)) and (edtQSL_VIA.Text<>'') then
  begin
    if cmbQSL_S.Text = 'SB' then
      cmbQSL_S.Text := 'SMB';
    if cmbQSL_S.Text = 'B' then
      cmbQSL_S.Text := 'MD'
  end;
  if (not (fEditQSO or fViewQSO)) or (old_call<>edtCall.Text) then
  begin
    idcall := dmUtils.GetIDCall(edtCall.Text);
    sbNewQSO.Panels[1].Text := cRefCall + idcall
  end;
  if (not(fEditQSO or fViewQSO)) then
  begin
    if SearchQRZ then
    begin
      if NOT c_running then
      begin
        c_callsign := edtCall.Text;
        QRZ := TQRZThread.Create(True);
        QRZ.Resume
      end
    end
  end;

  if (not (fEditQSO or fViewQSO)) then
    FreqBefChange := frmTRXControl.GetFreqMHz;

  CheckCallsignClub;
  CheckAwardClub;
  CheckCountyClub;
  CheckQTHClub;
  CheckStateClub;
  CheckAttachment;
  CheckQSLImage
end;

procedure TfrmNewQSO.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  QRZ : TQRZThread;
  tmp : String;
  speed : Integer = 0;
  i     : Integer = 0;
  ShowMain : Boolean = False;
begin
  if key = VK_ESCAPE then
  begin
    if not (fViewQSO or fEditQSO) then
    begin
      if EscFirstTime then
      begin
        SaveGrid;
        if edtCall.Text = '' then
          edtCall.SetFocus
        else
          edtCall.Text := ''; // OnChange calls ClearAll;
        EscFirstTime := False;
        old_ccall := '';
        old_cfreq := '';
        old_cmode := ''
      end
      else begin
        CWint.StopSending;
        EscFirstTime   := True;
        tmrESC.Enabled := True
      end
    end
    else begin
      if fViewQSO then
      begin
        if (not (fViewQSO or fEditQSO or cbOffline.Checked)) then
        tmrRadio.Enabled := True;
        btnSave.Enabled  := True;
        for i:=0 to ComponentCount-1 do
        begin
          if (frmNewQSO.Components[i] is TEdit) then
             (frmNewQSO.Components[i] As TEdit).ReadOnly := False;
        end;
        edtDate.ReadOnly  := False;
        mComment.ReadOnly := False;
      end;
      ShowMain := (fEditQSO or fViewQSO) and (not fromNewQSO);
      ClearAll;
      UnsetEditLabel;

      if ShowMain then
      begin
        frmMain.BringToFront;
        frmMain.SetFocus
      end;
      Caption := dmUtils.GetNewQSOCaption('New QSO');
      fViewQSO := False;
      fEditQSO := False
    end
  end
  else
    EscFirstTime := False;

  if ((Shift = [ssCtrl]) and (key = VK_F2)) then
  begin
    Caption := dmUtils.GetNewQSOCaption('New QSO');
    fViewQSO := False;
    fEditQSO := False;
    NewQSO;
    key := 0
  end;

  if (key = VK_F1) and (Shift = []) then
  begin
    CWint.SendText(dmUtils.GetCWMessage('F1',edtCall.Text,edtHisRST.Text,edtName.Text,''));
    if (cmbMode.Text='SSB') then RunVK('F1');
    key := 0
  end;
  if (key = VK_F2) and (Shift = []) then     
  begin
    CWint.SendText(dmUtils.GetCWMessage('F2',edtCall.Text,edtHisRST.Text,edtName.Text,''));
    if (cmbMode.Text='SSB') then RunVK('F2');
    key := 0
  end;
  if (key = VK_F3) and (Shift = []) then
  begin
    CWint.SendText(dmUtils.GetCWMessage('F3',edtCall.Text,edtHisRST.Text,edtName.Text,''));
    if (cmbMode.Text='SSB') then RunVK('F3');
    key := 0
  end;
  if (key = VK_F4) and (Shift = []) then
  begin
    CWint.SendText(dmUtils.GetCWMessage('F4',edtCall.Text,edtHisRST.Text,edtName.Text,''));
    if (cmbMode.Text='SSB') then RunVK('F4');
    key := 0
  end;
  if (key = VK_F5) and (Shift = []) then
  begin
    CWint.SendText(dmUtils.GetCWMessage('F5',edtCall.Text,edtHisRST.Text,edtName.Text,''));
    if (cmbMode.Text='SSB') then RunVK('F5');
    key := 0
  end;
  if (key = VK_F6) and (Shift = []) then
  begin
    CWint.SendText(dmUtils.GetCWMessage('F6',edtCall.Text,edtHisRST.Text,edtName.Text,''));
    if (cmbMode.Text='SSB') then RunVK('F6');
    key := 0
  end;
  if (key = VK_F7) and (Shift = []) then
  begin
    CWint.SendText(dmUtils.GetCWMessage('F7',edtCall.Text,edtHisRST.Text,edtName.Text,''));
    if (cmbMode.Text='SSB') then RunVK('F7');
    key := 0
  end;
  if (key = VK_F8) and (Shift = []) then
  begin
    CWint.SendText(dmUtils.GetCWMessage('F8',edtCall.Text,edtHisRST.Text,edtName.Text,''));
    if (cmbMode.Text='SSB') then RunVK('F8');
    key := 0
  end;
  if (key = VK_F9) and (Shift = []) then
  begin
    CWint.SendText(dmUtils.GetCWMessage('F9',edtCall.Text,edtHisRST.Text,edtName.Text,''));
    if (cmbMode.Text='SSB') then RunVK('F9');
    key := 0
  end;
  if (key = VK_F10) and (Shift = []) then
  begin
    CWint.SendText(dmUtils.GetCWMessage('F10',edtCall.Text,edtHisRST.Text,edtName.Text,''));
    if (cmbMode.Text='SSB') then RunVK('F10');
    key := 0
  end;

  if (key = 33) and (not dbgrdQSOBefore.Focused) then//pgup
  begin
    speed := CWint.GetSpeed+2;
    CWint.SetSpeed(speed);
    sbNewQSO.Panels[2].Text := IntToStr(speed)+'WPM'
  end;

  if (key = 34) and (not dbgrdQSOBefore.Focused) then//pgup
  begin
    speed := CWint.GetSpeed-2;
    CWint.SetSpeed(speed);
    sbNewQSO.Panels[2].Text := IntToStr(speed)+'WPM'
  end;

  if (Shift = [ssCtrl]) and (Key = VK_F8) then
  begin     //F8
    if not (fEditQSO or fViewQSO) then
      edtCall.Text:= '';
    edtCall.SetFocus;
    key := 0
  end;
  if (Key = VK_F11) then
  begin
    if NOT c_running then
    begin
      c_callsign := edtCall.Text;
      mCallBook.Clear;
      QRZ := TQRZThread.Create(True);
      QRZ.Resume
    end
  end;
  if (Shift = [ssAlt]) and (key = VK_F) then
  begin
    dmUtils.EnterFreq;
    key := 0
  end;

  if (Shift = [ssCtrl]) and (key = VK_Q) then //why all this didnt work directly in action?
  begin
    acClose.Execute;
    key := 0;
    exit
  end;

  if (Shift = [ssCtrl]) and (key = VK_P) then
  begin
    acPreferences.Execute;
    key := 0;
  end;

  if (Shift = [ssCtrl]) and (key = VK_D) then
  begin
    acDXCCCfm.Execute;
    key := 0;
  end;

  if (Shift = [ssCtrl]) and (key = VK_O) then
  begin
    mnuQSOList.Click;
    key := 0;
  end;

  if (Shift = [ssCtrl]) and (key = VK_I) then
  begin
    acDetails.Execute;
    key := 0
  end;

  if ((Shift = [ssCtrl]) and (key = VK_R)) then
  begin
    if edtCall.Text <> '' then
    begin
      tmp := idcall;
      with TfrmRefCall.Create(self) do
      try
        edtIdCall.Text := idcall;
        ShowModal;
        if ModalResult = mrOK then
          idcall := edtIdCall.Text;
      finally
        Free;
        if tmp <> idcall then
          CheckCallsignClub;
      end;
      key := 0
    end;
  end;
  if ((Shift = [ssCtrl]) and (key = VK_A)) then
  begin
    acAddToBandMap.Execute;
    key := 0
  end;
  if ((Shift = [ssCtrl]) and (key = VK_N)) then
  begin
    acLongNote.Execute;
    key := 0
  end;
  
  if ((Shift = [ssCtrl]) and (key = VK_M)) then
  begin
    acRemoteMode.Execute;
    key := 0
  end;

  if ((Shift = [ssCtrl]) and (key = VK_H)) then
  begin
    acDetails.Execute;
    key := 0
  end;

  if ((Shift = [ssAlt]) and (key = VK_H)) then
  begin
    ShowHelp;
    key := 0
  end;

  if ((Shift = [ssAlt]) and (key = VK_F2)) then
  begin
    acNewQSOExecute(nil);
    key := 0
  end;

  if ((Shift = [ssCTRL]) and (key = VK_1)) then
    frmTRXControl.rbRadio1.Checked := True;
    //SetSplit('1');
  if ((Shift = [ssCTRL]) and (key = VK_2)) then
    frmTRXControl.rbRadio2.Checked := True;
    //SetSplit('2');
  if ((Shift = [ssCTRL]) and (key = VK_3)) then
    SetSplit('3');
  if ((Shift = [ssCTRL]) and (key = VK_4)) then
    SetSplit('4');
  if ((Shift = [ssCTRL]) and (key = VK_5)) then
    SetSplit('5');
  if ((Shift = [ssCTRL]) and (key = VK_6)) then
    SetSplit('6');
  if ((Shift = [ssCTRL]) and (key = VK_7)) then
    SetSplit('7');
  if ((Shift = [ssCTRL]) and (key = VK_8)) then
    SetSplit('8');
  if ((Shift = [ssCTRL]) and (key = VK_0)) then
    frmTRXControl.DisableSplit;
  if ((Shift = [ssCTRL]) and (key = VK_W)) then
    acSendSpot.Execute
end;

procedure TfrmNewQSO.FormKeyPress(Sender: TObject; var Key: char);
var
  tmp    : String = '';
  f      : Currency = 0;
  call   : String = '';
  freq   : String = '';
begin
  case key of
    #13 : begin                     //enter
            btnSave.Click;
            SaveGrid;
            key := #0;
          end;
    #12 : begin                    // CTRL+L
            with TfrmChangeLocator.Create(self) do
            try
              edtLocator.Text := copy(sbNewQSO.Panels[0].Text,Length(cMyLoc)+1,6);
              ShowModal;
              if ModalResult = mrOk then
              begin
                sbNewQSO.Panels[0].Text := cMyLoc + edtLocator.Text;
                cqrini.WriteString('Station','LOC',edtLocator.Text)
              end;
            finally
              Free;
            end;
            key := #0
          end;
    #96 : begin
            acSendSpot.Execute;
            Key := #0
          end;
    #43 : begin  //+ key
            acAddToBandMap.Execute;
            key := #0
          end;
  end; //case
end;

procedure TfrmNewQSO.edtStartTimeKeyPress(Sender: TObject; var Key: char);
begin
  if not ((key in ['0'..'9']) or (key = ':') or (key=#40) or (key=#38) or (key = #32) or (key=#8)) then
    key := #0
end;

procedure TfrmNewQSO.edtStateExit(Sender: TObject);
begin
  CheckStateClub;
end;

procedure TfrmNewQSO.edtStateKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtAward.SetFocus;
    key := 0;
  end;
  if (key = 38) then //up arrow
  begin
    edtCounty.SetFocus;
    key := 0;
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    edtAward.SetFocus;
    key := 0;
  end;
end;

procedure TfrmNewQSO.edtWAZExit(Sender: TObject);
begin
  frmQSODetails.waz := edtWAZ.Text;
end;

procedure TfrmNewQSO.mCommentKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = VK_TAB then
    edtCall.SetFocus;
end;

procedure TfrmNewQSO.mCommentKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = VK_UP then
  begin
    mComment.SelStart :=1;
    mComment.SelLength := 10;
    if (Pos(mComment.SelText,mComment.Lines.Strings[0]) > 0) or (mComment.Lines.Text = '') then
    begin
      mComment.SelLength := 0;
      key := 0;
      edtEndTime.SetFocus;
    end;
  end;
end;

procedure TfrmNewQSO.mnuIOTAClick(Sender: TObject);
begin
  with TfrmIOTAStat.Create(self) do
  try
    ShowModal;
  finally
    Free
  end;
end;

procedure TfrmNewQSO.mnuQSOBeforeClick(Sender: TObject);
begin
  dbgrdQSOBefore.Visible := not dbgrdQSOBefore.Visible;
  if dbgrdQSOBefore.Visible then
    mnuQSOBefore.Caption := 'Disable QSO before grid'
  else
    mnuQSOBefore.Caption := 'Enable QSO before grid'
end;

procedure TfrmNewQSO.mnuQSOListClick(Sender: TObject);
begin
  if frmMain.WindowState = wsMinimized then
    frmMain.WindowState := wsNormal;
  frmMain.Show;
  frmMain.BringToFront;
end;

procedure TfrmNewQSO.sbtnAttachClick(Sender: TObject);
begin
  frmCallAttachment := TfrmCallAttachment.Create(self);
  try
    frmCallAttachment.flAttach.Directory := dmUtils.GetCallAttachDir(edtCall.Text);
    frmCallAttachment.ShowModal
  finally
    frmCallAttachment.Free
  end
end;

procedure TfrmNewQSO.sbtnQSLClick(Sender: TObject);
begin
  if not cqrini.ReadBool('ExtView','QSL',True) then
    dmUtils.ShowQSLWithExtViewer(edtCall.Text)
  else begin
    frmQSLViewer := TfrmQSLViewer.Create(self);
    try
      frmQSLViewer.Call := edtCall.Text;
      frmQSLViewer.ShowModal
    finally
      frmQSLViewer.Free
    end
  end
end;

procedure TfrmNewQSO.sbtnQRZClick(Sender: TObject);
begin
  dmUtils.ShowQRZInBrowser(edtCall.Text)
end;

procedure TfrmNewQSO.sbtnHamQTHClick(Sender : TObject);
begin
  dmUtils.ShowHamQTHInBrowser(edtCall.Text)
end;

procedure TfrmNewQSO.tmrESCTimer(Sender: TObject);
begin
  EscFirstTime   := False;
  tmrESC.Enabled := False
end;

procedure TfrmNewQSO.ShowFields;

  procedure ChangeVis(Column : String; IfShow : Boolean);
  var
    i       : Integer;
    fQsoGr  : String;
    fqSize  : Integer;
    isAdded : Boolean = False;
  begin
    fQsoGr := cqrini.ReadString('Fonts','QGrids','Sans 10');
    fqSize := cqrini.ReadInteger('Fonts','qSize',10);

    for i:=0 to dbgrdQSOBefore.Columns.Count-1 do
    begin
      if UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'BAND' then
        dbgrdQSOBefore.Columns[i].Visible := False;
      if UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'QSO_DXCC' then
        dbgrdQSOBefore.Columns[i].Visible := False;
      if UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'PROFILE' then
        dbgrdQSOBefore.Columns[i].Visible := False;
      if UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'ID_CQRLOG_MAIN' then
        dbgrdQSOBefore.Columns[i].Visible := False;
      if UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'IDCALL' then
        dbgrdQSOBefore.Columns[i].Visible := False;
      if UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'CLUB_NR1' then
        dbgrdQSOBefore.Columns[i].Visible := False;
      if UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'CLUB_NR2' then
        dbgrdQSOBefore.Columns[i].Visible := False;
      if UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'CLUB_NR3' then
        dbgrdQSOBefore.Columns[i].Visible := False;
      if UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'CLUB_NR4' then
        dbgrdQSOBefore.Columns[i].Visible := False;
      if UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'CLUB_NR5' then
        dbgrdQSOBefore.Columns[i].Visible := False;
      if (UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'STATE') then
      begin
        dbgrdQSOBefore.Columns[i].Alignment := taCenter;
        dbgrdQSOBefore.Columns[i].Title.Alignment := taCenter
      end;
      if (UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'LOTW_QSLS') then
      begin
        dbgrdQSOBefore.Columns[i].Alignment := taCenter;
        dbgrdQSOBefore.Columns[i].Title.Alignment := taCenter
      end;
      if (UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'LOTW_QSLR') then
      begin
        dbgrdQSOBefore.Columns[i].Alignment := taCenter;
        dbgrdQSOBefore.Columns[i].Title.Alignment := taCenter
      end;

      if (UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'EQSL_QSL_SENT') then
      begin
        dbgrdQSOBefore.Columns[i].Alignment := taCenter;
        dbgrdQSOBefore.Columns[i].Title.Alignment := taCenter
      end;
      if (UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'EQSL_QSL_RCVD') then
      begin
        dbgrdQSOBefore.Columns[i].Alignment := taCenter;
        dbgrdQSOBefore.Columns[i].Title.Alignment := taCenter
      end;

      if (UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'QSLR') then
      begin
        dbgrdQSOBefore.Columns[i].Alignment := taCenter;
        dbgrdQSOBefore.Columns[i].Title.Alignment := taCenter
      end;

      if UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = UpperCase(Column) then
      begin
        dbgrdQSOBefore.Columns[i].Visible := IfShow;
        if IfShow and (dbgrdQSOBefore.Columns[i].Width = 0) then
          dbgrdQSOBefore.Columns[i].Width := 60;
        isAdded := True
      end;

      if cqrini.ReadBool('Fonts','UseDefault',True) then
      begin
        dbgrdQSOBefore.Columns[i].Title.Font.Name := 'default';
        dbgrdQSOBefore.Columns[i].Title.Font.Size := 0
      end
      else begin
        dbgrdQSOBefore.Columns[i].Title.Font.Name := fQsoGr;
        dbgrdQSOBefore.Columns[i].Title.Font.Size := fqSize
      end
    end;
    if (not isAdded) and IfShow then
    begin
      dbgrdQSOBefore.Columns.Add;
      dbgrdQSOBefore.Columns[dbgrdQSOBefore.Columns.Count-1].FieldName   := LowerCase(Column);
      dbgrdQSOBefore.Columns[dbgrdQSOBefore.Columns.Count-1].DisplayName := LowerCase(Column);
      dbgrdQSOBefore.Columns[dbgrdQSOBefore.Columns.Count-1].Width       := 60
    end
  end;

begin
  dbgrdQSOBefore.DataSource := dmData.dsrQSOBefore;
  dbgrdQSOBefore.ResetColWidths;
  LoadGrid;
  //dbgrdQSOBefore.Columns[0].Visible := False;
  ChangeVis('qsodate',cqrini.ReadBool('Columns','qsodate',True));
  ChangeVis('TIME_ON',cqrini.ReadBool('Columns','time_on',True));
  ChangeVis('TIME_OFF',cqrini.ReadBool('Columns','time_off',False));
  ChangeVis('CALLSIGN',cqrini.ReadBool('Columns','CallSign',True));
  ChangeVis('MODE',cqrini.ReadBool('Columns','Mode',True));
  ChangeVis('FREQ',cqrini.ReadBool('Columns','Freq',True));
  ChangeVis('RST_S',cqrini.ReadBool('Columns','RST_S',True));
  ChangeVis('RST_R',cqrini.ReadBool('Columns','RST_R',True));
  ChangeVis('NAME',cqrini.ReadBool('Columns','Name',True));
  ChangeVis('QTH',cqrini.ReadBool('Columns','QTH',True));
  ChangeVis('QSL_S',cqrini.ReadBool('Columns','QSL_S',True));
  ChangeVis('QSL_R',cqrini.ReadBool('Columns','QSL_R',True));
  ChangeVis('QSL_VIA',cqrini.ReadBool('Columns','QSL_VIA',False));
  ChangeVis('LOC',cqrini.ReadBool('Columns','Locator',False));
  ChangeVis('MY_LOC',cqrini.ReadBool('Columns','MyLoc',False));
  ChangeVis('IOTA',cqrini.ReadBool('Columns','IOTA',False));
  ChangeVis('AWARD',cqrini.ReadBool('Columns','Award',False));
  ChangeVis('COUNTY',cqrini.ReadBool('Columns','County',False));
  ChangeVis('PWR',cqrini.ReadBool('Columns','Power',False));
  ChangeVis('dxcc_ref',cqrini.ReadBool('Columns','DXCC',False));
  ChangeVis('REMARKS',cqrini.ReadBool('Columns','Remarks',False));
  ChangeVis('WAZ',cqrini.ReadBool('Columns','WAZ',False));
  ChangeVis('ITU',cqrini.ReadBool('Columns','ITU',False));
  ChangeVis('STATE',cqrini.ReadBool('Columns','State',False));
  ChangeVis('LOTW_QSLSDATE',cqrini.ReadBool('Columns','LoTWQSLSDate',False));
  ChangeVis('LOTW_QSLRDATE',cqrini.ReadBool('Columns','LoTWQSLRDate',False));
  ChangeVis('LOTW_QSLS',cqrini.ReadBool('Columns','LoTWQSLS',False));
  ChangeVis('LOTW_QSLR',cqrini.ReadBool('Columns','LOTWQSLR',False));
  ChangeVis('CONT',cqrini.ReadBool('Columns','Cont',False));
  ChangeVis('QSLS_DATE',cqrini.ReadBool('Columns','QSLSDate',False));
  ChangeVis('QSLR_DATE',cqrini.ReadBool('Columns','QSLRDate',False));
  ChangeVis('EQSL_QSL_SENT',cqrini.ReadBool('Columns','eQSLQSLS',False));
  ChangeVis('EQSL_QSLSDATE',cqrini.ReadBool('Columns','eQSLQSLSDate',False));
  ChangeVis('EQSL_QSL_RCVD',cqrini.ReadBool('Columns','eQSLQSLR',False));
  ChangeVis('EQSL_QSLRDATE',cqrini.ReadBool('Columns','eQSLQSLRDate',False));
  ChangeVis('QSLR',cqrini.ReadBool('Columns','QSLRAll',False));
  ChangeVis('COUNTRY',cqrini.ReadBool('Columns','Country',False))
end;

procedure TfrmNewQSO.ChangeReports;
var
  tmp : String;
begin
  if not chkAutoMode.Checked then
    exit;
  //if user set own mode by hand, he also can change report as he need
  if cmbMode.Text = 'SSB' then
    tmp := '59'
  else
    if cmbMode.Text = 'CW' then
      tmp := '599'
    else
      if cmbMode.Text = 'STTV' then
        tmp := '595'
      else
        tmp := '599';

  if edtHisRST.Text = '' then
    edtHisRST.Text := tmp;
  if edtMyRST.Text = '' then
    edtMyRST.Text := tmp;

  if (cmbMode.Text = 'SSB') or (cmbMode.Text = 'AM') or (cmbMode.Text = 'FM') then
  begin
    if Length(edtHisRST.Text) = 3 then
      edtHisRST.Text := copy(edtHisRST.Text,1,2);
    if Length(edtMyRST.Text) = 3 then
      edtMyRST.Text := copy(edtMyRST.Text,1,2);
  end
  else begin
    if Length(edtHisRST.Text) = 2 then
      edtHisRST.Text := edtHisRST.Text + '9';
    if Length(edtMyRST.Text) = 2 then
      edtMyRST.Text := edtMyRST.Text + '9'
  end;
end;

procedure TfrmNewQSO.ShowStatistic(ref_adif : Word);
var
  i : Integer;
  ShowLoTW : Boolean = False;
  mode : String;
  QSLR,LoTW,eQSL : String;
  tmps : String;
begin
  if old_stat_adif = ref_adif then
    exit;
  old_stat_adif := ref_adif;
  sgrdStatistic.ColCount  := cMaxBandsCount;
  ClearStatGrid;

  for i:=0 to cMaxBandsCount-1 do
  begin
    if dmUtils.MyBands[i][0]='' then
    begin
      sgrdStatistic.ColCount  := i+1;
      break
    end;
    sgrdStatistic.Cells[i+1,0] := dmUtils.MyBands[i][1];
    sgrdStatistic.Cells[i+1,1] := '   ';
    sgrdStatistic.Cells[i+1,2] := '   ';
    sgrdStatistic.Cells[i+1,3] := '   ';
  end;



  ShowLoTW := cqrini.ReadBool('LoTW','NewQSOLoTW',False);
  if ShowLoTW then
    dmData.Q.SQL.Text := 'select band,mode,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main where adif='+
                         IntToStr(ref_adif) + ' and ((qsl_r='+QuotedStr('Q')+') or '+
                         '(lotw_qslr = '+QuotedStr('L')+') or (eqsl_qsl_rcvd='+QuotedStr('E')+
                         ')) group by band,mode,qsl_r,lotw_qslr,eqsl_qsl_rcvd'
  else
    dmData.Q.SQL.Text := 'select band,mode,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main where adif='+
                         IntToStr(ref_adif) + ' and (qsl_r = '+QuotedStr('Q')+') '+
                         'group by band,mode,qsl_r,lotw_qslr,eqsl_qsl_rcvd';
  //dmData.trQ.StartTransaction;
  dmData.Q.Open;
  while not dmData.Q.Eof do
  begin
    i    := dmUtils.GetBandPos(dmData.Q.Fields[0].AsString)+1;
    mode := dmData.Q.Fields[1].AsString;
    QSLR := dmData.Q.Fields[2].AsString;
    LoTW := dmData.Q.Fields[3].AsString;
    eQSL := dmData.Q.Fields[4].AsString;
    //Writeln(dmData.Q.Fields[0].AsString,'|',mode,'|',QSLR,'|',LoTW,'|',eQSL);
    if i > 0 then
    begin
      if (Mode = 'SSB') or (Mode='FM') or (Mode='AM') then
      begin
        tmps := sgrdStatistic.Cells[i,1] ;
        if QSLR = 'Q' then
          tmps[1] := 'Q';
        if (LoTW = 'L') then
          tmps[2] := 'L';
        if (eQSL = 'E') then
          tmps[3] := 'E';
       sgrdStatistic.Cells[i,1] := tmps
      end
      else begin
        if (Mode='CW') or (Mode='CWQ') then
        begin
          tmps := sgrdStatistic.Cells[i,2] ;
          if QSLR = 'Q' then
            tmps[1] := 'Q';
          if (LoTW = 'L') then
            tmps[2] := 'L';
          if (eQSL = 'E') then
            tmps[3] := 'E';
          sgrdStatistic.Cells[i,2] := tmps
        end
        else begin
          tmps := sgrdStatistic.Cells[i,3] ;
          if QSLR = 'Q' then
            tmps[1] := 'Q';
          if (LoTW = 'L') then
            tmps[2] := 'L';
          if (eQSL = 'E') then
            tmps[3] := 'E';
          sgrdStatistic.Cells[i,3] := tmps
        end
      end;
    end;
    dmData.Q.Next
  end;
  dmData.trQ.Rollback;

  dmData.Q.Close;
  if dmData.trQ.Active then
    dmData.trQ.Rollback;
  dmData.Q.SQL.Text := 'select band,mode from cqrlog_main where adif='+
                       IntToStr(ref_adif) + ' group by band,mode';
  dmData.trQ.StartTransaction;
  dmData.Q.Open;
  while not dmData.Q.Eof do
  begin
    i    := dmUtils.GetBandPos(dmData.Q.Fields[0].AsString)+1;
    mode := dmData.Q.Fields[1].AsString;
    if i > 0 then
      begin
        if ((mode = 'SSB') or (mode = 'FM') or (mode = 'AM')) then
          if(sgrdStatistic.Cells[i,1] = '   ') then sgrdStatistic.Cells[i,1] := ' X ';
        if ((mode = 'CW') or (mode = 'CWR')) then
          if (sgrdStatistic.Cells[i,2] = '   ') then sgrdStatistic.Cells[i,2] := ' X ';
        if ((mode <> 'SSB') and (mode <>'FM') and (mode <> 'AM') and (mode <> 'CW') and (mode <> 'CWR')) then
          if (sgrdStatistic.Cells[i,3] = '   ') then sgrdStatistic.Cells[i,3] := ' X '
      end;
      dmData.Q.Next;
  end;
  dmData.Q.Close;

end;

procedure TfrmNewQSO.CalculateDistanceEtc;
var
  azim, qra, myloc : String;
  lat,long : Currency;
  SunRise,SunSet : TDateTime;
  //delta : Currency;
  inUTC : Boolean;
  SunDelta : Currency = 0;
begin
  inUTC := cqrini.ReadBool('Program','SunUTC',False);
  //delta := cqrini.ReadFloat('Program','offset',0);

  if dmUtils.SysUTC then
    SunDelta := dmUtils.GetLocalUTCDelta
  else
    SunDelta := cqrini.ReadFloat('Program','SunOffset',0);

  //SunDelta := cqrini.ReadFloat('Program','SunOffset',0);
  if lblDXCC.Caption = '!' then
  begin
    lblQRA.Caption := '';
    lblAzi.Caption := '';
    exit
  end;
  qra   := '';
  azim  := '';
  myloc := copy(sbNewQSO.Panels[0].Text,Length(cMyLoc)+1,6);
  if (dmUtils.IsLocOK(edtGrid.Text) and dmUtils.IsLocOK(myloc)) then
  begin
    dmUtils.DistanceFromLocator(myloc,edtGrid.Text, qra, azim);
    dmUtils.CoordinateFromLocator(edtGrid.Text,lat,long);
    dmUtils.CalcSunRiseSunSet(lat,long,SunRise,SunSet);
    if not inUTC then
    begin
      SunRise := SunRise + (SunDelta/24);
      SunSet  := SunSet + (SunDelta/24)
    end;
    {
    if SunDelta <> 0 then
    begin
      SunRise := SunRise + (SunDelta/24);
      SunSet  := SunSet + (SunDelta/24)
    end;
    if inUTC then
    begin
      SunRise := SunRise - (delta/24);
      SunSet  := SunSet - (delta/24)
    end;
    }
    lblTarSunRise.Caption := TimeToStr(SunRise);
    lblTarSunSet.Caption  := TimeToStr(SunSet)
  end
  else begin
    if (lblLat.Caption <> '') and (lblLong.Caption <> '') then
    begin
      dmUtils.GetRealCoordinate(lblLat.Caption,lblLong.Caption,lat,long);
      dmUtils.CalcSunRiseSunSet(lat,long,SunRise,SunSet);
      {
      if inUTC then
      begin
        SunRise := SunRise - (delta/24);
        SunSet  := SunSet - (delta/24)
      end;
      }
      if not inUTC then
      begin
        SunRise := SunRise + (SunDelta/24);
        SunSet  := SunSet + (SunDelta/24)
      end;
      lblTarSunRise.Caption := TimeToStr(SunRise);
      lblTarSunSet.Caption  := TimeToStr(SunSet);
      dmUtils.DistanceFromCoordinate(myloc,lat,long,qra,azim)
    end
    else
      dmUtils.DistanceFromPrefixMyLoc(myloc,edtDXCCRef.Text, qra, azim)
  end;
  if ((qra <>'') and (azim<>'')) then
  begin
    lblQRA.Caption := qra + ' km';
    lblAzi.Caption := azim;
    Azimuth := azim;
  end;
end;

procedure TfrmNewQSO.ShowQSO;
var
  i : Integer;
begin
  tmrRadio.Enabled := False;
  tmrEnd.Enabled   := False;
  tmrStart.Enabled := False;

  Running      := False;
  EscFirstTime := False;
  ChangeDXCC   := False;
  dmData.InsertProfiles(cmbProfiles,true);
  
  if fromNewQSO then
  begin
    cmbProfiles.Text  := dmData.GetProfileText(dmData.qQSOBefore.FieldByName('profile').AsInteger);
    edtDate.Text      := dmData.qQSOBefore.FieldByName('qsodate').AsString;
    edtStartTime.Text := dmData.qQSOBefore.FieldByName('time_on').AsString;
    edtEndTime.Text   := dmData.qQSOBefore.FieldByName('time_off').AsString;
    edtCall.Text      := dmData.qQSOBefore.FieldByName('callsign').AsString;
    cmbFreq.Text      := FloatToStrF(dmData.qQSOBefore.FieldByName('freq').AsFloat,ffFixed,8,4);
    cmbMode.Text      := dmData.qQSOBefore.FieldByName('mode').AsString;
    edtHisRST.Text    := dmData.qQSOBefore.FieldByName('rst_s').AsString;
    edtMyRST.Text     := dmData.qQSOBefore.FieldByName('rst_r').AsString;
    edtName.Text      := Trim(dmData.qQSOBefore.FieldByName('name').AsString);
    edtQTH.Text       := Trim(dmData.qQSOBefore.FieldByName('qth').AsString);
    cmbQSL_S.Text     := dmData.qQSOBefore.FieldByName('qsl_s').AsString;
    cmbQSL_R.Text     := dmData.qQSOBefore.FieldByName('qsl_r').AsString;
    edtQSL_VIA.Text   := dmData.qQSOBefore.FieldByName('qsl_via').AsString;
    cmbIOTA.Text      := dmData.qQSOBefore.FieldByName('iota').AsString;
    edtPWR.Text       := dmData.qQSOBefore.FieldByName('pwr').AsString;
    if NOT dmData.qQSOBefore.FieldByName('itu').IsNull then
      edtITU.Text     := IntToStr(dmData.qQSOBefore.FieldByName('itu').AsInteger);
    if NOT dmData.qQSOBefore.FieldByName('waz').IsNull then
      edtWAZ.Text     := IntToStr(dmData.qQSOBefore.FieldByName('waz').AsInteger);
    edtGrid.Text      := dmData.qQSOBefore.FieldByName('loc').AsString;
    sbNewQSO.Panels[0].Text := cMyLoc + dmData.qQSOBefore.FieldByName('my_loc').AsString;
    edtCounty.Text    := Trim(dmData.qQSOBefore.FieldByName('county').AsString);
    edtRemQSO.Text    := Trim(dmData.qQSOBefore.FieldByName('remarks').AsString);
    edtDXCCRef.Text   := dmData.qQSOBefore.FieldByName('dxcc_ref').AsString;
    ChangeDXCC        := dmData.qQSOBefore.FieldByName('qso_dxcc').AsInteger > 0;
    idcall            := dmData.qQSOBefore.FieldByName('idcall').AsString;
    edtAward.Text     := Trim(dmData.qQSOBefore.FieldByName('award').AsString);
    edtState.Text     := Trim(dmData.qQSOBefore.FieldByName('state').AsString);
    lotw_qslr         := dmData.qQSOBefore.FieldByName('lotw_qslr').AsString;
    if lotw_qslr = 'L' then
    begin
      lblCfmLoTW.Caption := 'QSO confirmed by LoTW ' + dmData.qQSOBefore.FieldByName('lotw_qslrdate').AsString;
      lblCfmLoTW.Visible := True
    end;
    if not dmData.qQSOBefore.FieldByName('qslr_date').IsNull then
    begin
      lblQSLRcvdDate.Caption := 'QSL rcvd on '+dmData.qQSOBefore.FieldByName('qslr_date').AsString;
      lblQSLRcvdDate.Visible := True
    end
  end
  else begin
    cmbProfiles.Text := dmData.GetProfileText(dmData.qCQRLOG.FieldByName('profile').AsInteger);
    edtDate.Text      := dmData.qCQRLOG.FieldByName('qsodate').AsString;
    edtStartTime.Text := dmData.qCQRLOG.FieldByName('time_on').AsString;
    edtEndTime.Text   := dmData.qCQRLOG.FieldByName('time_off').AsString;
    edtCall.Text      := dmData.qCQRLOG.FieldByName('callsign').AsString;
    cmbFreq.Text      := FloatToStrF(dmData.qCQRLOG.FieldByName('freq').AsFloat,ffFixed,8,4);
    cmbMode.Text      := dmData.qCQRLOG.FieldByName('mode').AsString;
    edtHisRST.Text    := dmData.qCQRLOG.FieldByName('rst_s').AsString;
    edtMyRST.Text     := dmData.qCQRLOG.FieldByName('rst_r').AsString;
    edtName.Text      := dmData.qCQRLOG.FieldByName('name').AsString;
    edtQTH.Text       := dmData.qCQRLOG.FieldByName('qth').AsString;
    cmbQSL_S.Text     := dmData.qCQRLOG.FieldByName('qsl_s').AsString;
    cmbQSL_R.Text     := dmData.qCQRLOG.FieldByName('qsl_r').AsString;
    edtQSL_VIA.Text   := dmData.qCQRLOG.FieldByName('qsl_via').AsString;
    cmbIOTA.Text      := dmData.qCQRLOG.FieldByName('iota').AsString;
    edtPWR.Text       := dmData.qCQRLOG.FieldByName('pwr').AsString;
    if NOT dmData.qCQRLOG.FieldByName('itu').IsNull then
      edtITU.Text     := IntToStr(dmData.qCQRLOG.FieldByName('itu').AsInteger);
    if NOT dmData.qCQRLOG.FieldByName('waz').IsNull then
      edtWAZ.Text     := IntToStr(dmData.qCQRLOG.FieldByName('waz').AsInteger);
    edtGrid.Text      := dmData.qCQRLOG.FieldByName('loc').AsString;
    sbNewQSO.Panels[0].Text := cMyLoc + dmData.qCQRLOG.FieldByName('my_loc').AsString;
    edtCounty.Text    := dmData.qCQRLOG.FieldByName('county').AsString;
    edtRemQSO.Text    := dmData.qCQRLOG.FieldByName('remarks').AsString;
    edtDXCCRef.Text   := dmData.qCQRLOG.FieldByName('dxcc_ref').AsString;
    ChangeDXCC        := dmData.qCQRLOG.FieldByName('qso_dxcc').AsInteger > 0;
    idcall            := dmData.qCQRLOG.FieldByName('idcall').AsString;
    edtAward.Text     := dmData.qCQRLOG.FieldByName('award').AsString;
    edtState.Text     := dmData.qCQRLOG.FieldByName('state').AsString;
    lotw_qslr         := dmData.qCQRLOG.FieldByName('lotw_qslr').AsString;
    if lotw_qslr = 'L' then
    begin
      lblCfmLoTW.Caption := 'QSO confirmed by LoTW ' + dmData.qCQRLOG.FieldByName('lotw_qslrdate').AsString;
      lblCfmLoTW.Visible := True
    end;
    if not dmData.qCQRLOG.FieldByName('qslr_date').IsNull then
    begin
      lblQSLRcvdDate.Caption := 'QSL rcvd on '+dmData.qCQRLOG.FieldByName('qslr_date').AsString;
      lblQSLRcvdDate.Visible := True
    end
  end;
  sbNewQSO.Panels[1].Text := cRefCall + idcall;
  adif := dmDXCC.AdifFromPfx(edtDXCCRef.Text);
  if fromNewQSO then
  begin
    old_date := dmUtils.MyStrToDate(dmData.qQSOBefore.FieldByName('qsodate').AsString);
    old_freq := dmData.qQSOBefore.FieldByName('freq').AsString;
    old_mode := dmData.qQSOBefore.FieldByName('mode').AsString;
    old_adif := dmDXCC.AdifFromPfx(dmData.qQSOBefore.FieldByName('dxcc_ref').AsString);
    old_qslr := dmData.qQSOBefore.FieldByName('qsl_r').AsString;
    old_call := dmData.qQSOBefore.FieldByName('callsign').AsString
  end
  else begin
    old_date := dmUtils.MyStrToDate(dmData.qCQRLOG.FieldByName('qsodate').AsString);
    old_freq := dmData.qCQRLOG.FieldByName('freq').AsString;
    old_mode := dmData.qCQRLOG.FieldByName('mode').AsString;
    old_adif := dmDXCC.AdifFromPfx(dmData.qCQRLOG.FieldByName('dxcc_ref').AsString);
    old_qslr := dmData.qCQRLOG.FieldByName('qsl_r').AsString;
    old_call := dmData.qCQRLOG.FieldByName('callsign').AsString
  end;
  if fViewQSO then
    old_call := '';
  edtCallExit(nil);
  lblWAZ.Caption := edtWAZ.Text;
  lblITU.Caption := edtITU.Text;
  btnSave.Enabled := not fViewQSO;
  for i:=0 to ComponentCount-1 do
  begin
    if (frmNewQSO.Components[i] is TEdit) then
      (frmNewQSO.Components[i] As TEdit).ReadOnly := fViewQSO
  end;
  edtDate.ReadOnly  := fViewQSO;
  mComment.ReadOnly := fViewQSO;
  edtCall.SetFocus
end;

procedure TfrmNewQSO.NewQSO;
begin
  edtCall.Text := '';
  UnsetEditLabel;
  ShowWin := True;
  ShowWindows
end;

procedure TfrmNewQSO.SavePosition;
begin
  cqrini.WriteInteger('NewQSO','Height',Height);
  cqrini.WriteInteger('NewQSO','Width',Width);
  cqrini.WriteInteger('NewQSO','Top',Top);
  cqrini.WriteInteger('NewQSO','Left',Left);
  cqrini.WriteBool('NewQSO','StatBar',sbNewQSO.Visible);
  cqrini.SaveToDisk;
  //if dmData.DebugLevel>0 then Writeln('Saving window size a position (height|width|top|left):',
  //height,'|',Width,'|',top,'|',left)
end;

procedure TfrmNewQSO.SynCallBook;
var
  tmp     : String = '';
  County  : String = '';
  StoreTo : String = '';
  IgnoreQRZ : Boolean = False;
  MvToRem   : Boolean = False;
  call  : String;
begin
  if c_ErrMsg <> '' then
  begin
    mCallBook.Text := c_ErrMsg;
    exit
  end;
  if c_SyncText = '' then //we should have data from callbook
  begin
    c_callsign := dmUtils.GetIDCall(c_callsign);
    mCallBook.Lines.Add(c_callsign);
    mCallBook.Lines.Add(c_address);
    mCallBook.SelStart := 1;

    IgnoreQRZ := cqrini.ReadBool('NewQSO','IgnoreQRZ',False);
    MvToRem   := cqrini.ReadBool('NewQSO','MvToRem',True);
    if (edtQSL_VIA.Text = '') and (not IgnoreQRZ) and (c_qsl<>'') then
    begin
      c_qsl := dmUtils.GetQSLVia(c_qsl);
      if dmUtils.IsQSLViaValid(dmUtils.CallTrim(c_qsl)) then
        edtQSL_VIA.Text := dmUtils.CallTrim(c_qsl)
    end
    else begin
      if MvToRem then
      begin
        if c_qsl <> '' then
        begin
          if edtRemQSO.Text= '' then
            edtRemQSO.Text := c_qsl
          else
            edtRemQSO.Text := edtRemQSO.Text + ', '+c_qsl
        end
      end
    end; //qsl manager

    if edtName.Text = '' then
      edtName.Text := c_nick; //operator's name
    if (edtQTH.Text = '') and (c_callsign = edtCall.Text) then
      edtQTH.Text := c_qth;  //qth

    if (edtGrid.Text='') and dmUtils.IsLocOK(c_grid) and (c_callsign = edtCall.Text) then
    begin
      edtGrid.Text := c_grid;
      edtGridExit(nil)
    end;  //grid

    if cmbIOTA.Text='' then
    begin
      cmbIOTA.Text := c_iota;
      cmbIOTAExit(nil)
    end;

    if (c_state <> '') and (edtState.Text = '') and (c_callsign = edtCall.Text) then
    begin
      edtState.Text := c_state;
      if (c_county <> '') and (edtCounty.Text='') then
      begin
        if (edtState.Text<>'') then
          edtCounty.Text := edtState.Text+','+c_county
        else
          edtCounty.Text := c_county
      end
    end;  //county

    if c_zip <> '' then
    begin
      County := dmData.FindCounty1(c_zip,lblDXCC.Caption,StoreTo);
      if County <> '' then
      begin
        if (StoreTo = 'county') and (edtCounty.Text='') then
          edtCounty.Text := County
        else if (StoreTo = 'QTH') and (edtQTH.Text='') then
          edtQTH.Text := County
        else if (StoreTo = 'award') and (edtAward.Text='') then
          edtAward.Text := County
        else if (StoreTo = 'state') and (edtState.Text='') then
          edtState.Text := County
      end;

      County := dmData.FindCounty2(c_zip,lblDXCC.Caption,StoreTo);
      if County <> '' then
      begin
        if (StoreTo = 'county') and (edtCounty.Text='') then
          edtCounty.Text := County
        else if (StoreTo = 'QTH') and (edtQTH.Text='') then
          edtQTH.Text := County
        else if (StoreTo = 'award') and (edtAward.Text='') then
          edtAward.Text := County
        else if (StoreTo = 'state') and (edtState.Text='') then
          edtState.Text := County
      end;
      County := dmData.FindCounty3(c_zip,lblDXCC.Caption,StoreTo);
      if County <> '' then
      begin
        if (StoreTo = 'county') and (edtCounty.Text='') then
          edtCounty.Text := County
        else if (StoreTo = 'QTH') and (edtQTH.Text='') then
          edtQTH.Text := County
        else if (StoreTo = 'award') and (edtAward.Text='') then
          edtAward.Text := County
        else if (StoreTo = 'state') and (edtState.Text='') then
          edtState.Text := County
      end
    end //zip code
  end;
  CheckAwardClub;
  CheckQTHClub;
  CheckCountyClub;
  CheckStateClub
end;

procedure TfrmNewQSO.AppIdle(Sender: TObject; var Handled: Boolean);
begin
  Handled := True
end;

procedure TfrmNewQSO.NewQSOFromSpot(call,freq,mode : String);
var
  etmp : Extended;
begin
  if (old_ccall <> call) or (old_cmode<>mode) or (old_cfreq<>freq) then
  begin
    old_ccall := call;
    old_cmode := mode;
    old_cfreq := freq;

    edtCall.Text := '';
    cbOffline.Checked := False;
    etmp := dmUtils.MyStrToFloat(freq);
    etmp := etmp/1000;
    freq := FloatToStrF(etmp,ffFixed,10,8);
    FromDXC      := True;
    edtCall.Text := call;
    cmbFreq.Text := freq;
    if chkAutoMode.Checked then
      cmbMode.Text := mode;
    freq := FloatToStr(etmp);
    mode := dmUtils.GetModeFromFreq(freq);
    etmp := etmp*1000;
    freq := FloatToStr(etmp);
    frmTRXControl.SetModeFreq(mode,freq);
    edtCallExit(nil);
    BringToFront
  end
end;

procedure TfrmNewQSO.SetEditLabel;
begin
  lblCall.Caption    := 'Call (edit mode):';
  lblCall.Font.Color := clRed;
  Caption := dmUtils.GetNewQSOCaption('Edit QSO')
end;

procedure TfrmNewQSO.UnsetEditLabel;
begin
  lblCall.Caption    := 'Call:';
  lblCall.Font.Color := clBlue;
  Caption := dmUtils.GetNewQSOCaption('New QSO')
end;

procedure TfrmNewQSO.CheckCallsignClub;
begin
  frmQSODetails.mode     := cmbMode.Text;
  frmQSODetails.freq     := cmbFreq.Text;
  frmQSODetails.ClubDate := edtDate.Text;
  if dmData.Club1.MainFieled = 'idcall' then
    frmQSODetails.ClubData1 := idcall;

  if dmData.Club2.MainFieled = 'idcall' then
    frmQSODetails.ClubData2 := idcall;

  if dmData.Club3.MainFieled = 'idcall' then
    frmQSODetails.ClubData3 := idcall;

  if dmData.Club4.MainFieled = 'idcall' then
    frmQSODetails.ClubData4 := idcall;

  if dmData.Club5.MainFieled = 'idcall' then
    frmQSODetails.ClubData5 := idcall;
end;

procedure TfrmNewQSO.CheckQTHClub;
begin
  frmQSODetails.mode     := cmbMode.Text;
  frmQSODetails.freq     := cmbFreq.Text;
  frmQSODetails.ClubDate := edtDate.Text;
  if dmData.Club1.MainFieled = 'qth' then
    frmQSODetails.ClubData1 := edtQTH.Text;

  if dmData.Club2.MainFieled = 'qth' then
    frmQSODetails.ClubData2 := edtQTH.Text;

  if dmData.Club3.MainFieled = 'qth' then
    frmQSODetails.ClubData3 := edtQTH.Text;

  if dmData.Club4.MainFieled = 'qth' then
    frmQSODetails.ClubData4 := edtQTH.Text;

  if dmData.Club5.MainFieled = 'qth' then
    frmQSODetails.ClubData5 := edtQTH.Text;
end;

procedure TfrmNewQSO.CheckAwardClub;
begin
  frmQSODetails.mode     := cmbMode.Text;
  frmQSODetails.freq     := cmbFreq.Text;
  frmQSODetails.ClubDate := edtDate.Text;
  if dmData.Club1.MainFieled = 'award' then
    frmQSODetails.ClubData1 := edtAward.Text;

  if dmData.Club2.MainFieled = 'award' then
    frmQSODetails.ClubData2 := edtAward.Text;

  if dmData.Club3.MainFieled = 'award' then
    frmQSODetails.ClubData3 := edtAward.Text;

  if dmData.Club4.MainFieled = 'award' then
    frmQSODetails.ClubData4 := edtAward.Text;

  if dmData.Club5.MainFieled = 'award' then
    frmQSODetails.ClubData5 := edtAward.Text;
end;

procedure TfrmNewQSO.CheckCountyClub;
begin
  frmQSODetails.mode     := cmbMode.Text;
  frmQSODetails.freq     := cmbFreq.Text;
  frmQSODetails.ClubDate := edtDate.Text;
  if dmData.Club1.MainFieled = 'county' then
    frmQSODetails.ClubData1 := edtCounty.Text;

  if dmData.Club2.MainFieled = 'county' then
    frmQSODetails.ClubData2 := edtCounty.Text;

  if dmData.Club3.MainFieled = 'county' then
    frmQSODetails.ClubData3 := edtCounty.Text;

  if dmData.Club4.MainFieled = 'county' then
    frmQSODetails.ClubData4 := edtCounty.Text;

  if dmData.Club5.MainFieled = 'county' then
    frmQSODetails.ClubData5 := edtCounty.Text;
end;

procedure TfrmNewQSO.StoreClubInfo(where,StoreText : String);
begin
  StoreText := trim(StoreText);
  if (where = 'award') and (Pos(StoreText,edtAward.text)=0) then
  begin
    if edtAward.Text <> '' then
      edtAward.Text := edtAward.Text + ' ' + StoreText
    else
      edtAward.Text := StoreText;
    edtAwardExit(nil);
  end;
  if (where = 'qth') and (Pos(UpperCase(StoreText),UpperCase(edtQTH.text))=0) then
  begin
    if edtQTH.Text <> ''then
      edtQTH.Text := edtQTH.Text + ' ' + StoreText
    else
      edtQTH.Text := StoreText;
    edtQTHExit(nil);
  end;
  if (where = 'comm. for QSO') and (Pos(StoreText,edtRemQSO.text)=0) then
  begin
    if edtRemQSO.Text <> ''  then
      edtRemQSO.Text := edtRemQSO.Text + ' ' + StoreText
    else
      edtRemQSO.Text := StoreText;
  end;
  if (where = 'name') and (Pos(StoreText,edtName.text)=0) then
  begin
    if edtName.Text <> '' then
      edtName.Text := edtName.Text + ' ' + StoreText
    else
      edtName.Text := StoreText;
  end;
  if (where = 'county') and (Pos(StoreText,edtCounty.text)=0) and (edtCounty.Text <> '') then
  begin
    edtCounty.Text := StoreText;
    edtCountyExit(nil);
  end;
  if (where = 'grid') and (edtGrid.Text='') then
    edtGrid.Text := StoreText;
  if (where = 'state') and (edtState.Text='') then
    edtState.Text := StoreText
end;


procedure TfrmNewQSO.CheckStateClub;
begin
  frmQSODetails.mode     := cmbMode.Text;
  frmQSODetails.freq     := cmbFreq.Text;
  frmQSODetails.ClubDate := edtDate.Text;
  if dmData.Club1.MainFieled = 'state' then
    frmQSODetails.ClubData1 := edtState.Text;

  if dmData.Club2.MainFieled = 'state' then
    frmQSODetails.ClubData2 := edtState.Text;

  if dmData.Club3.MainFieled = 'state' then
    frmQSODetails.ClubData3 := edtState.Text;

  if dmData.Club4.MainFieled = 'state' then
    frmQSODetails.ClubData4 := edtState.Text;

  if dmData.Club5.MainFieled = 'state' then
    frmQSODetails.ClubData5 := edtState.Text;
end;

procedure TfrmNewQSO.SaveGrid;
{var
  ini: TMemIniFile;
  Grid : TDBGrid;
  Section, Ident: string;
  i,j,y : Integer;
  l : TStringList;
  }
begin
  dmUtils.SaveForm(frmNewQSO)
  {
  l   := TStringList.Create;
  ini := TMemIniFile.Create(dmData.DataDir + 'grids.cfg');
  try
    Grid:= dbgrdQSOBefore;
    Section:= frmNewQSO.Name+'_'+Grid.Name;
    l.Clear;
    ini.ReadSection(Section,l);
    l.Text := Trim(l.Text);
    if l.Text<>'' then
    begin //delete old settings
      for y:=0 to l.Count-1 do
        ini.DeleteKey(Section,l[y])
    end;
    for j:= 0 to Grid.Columns.Count - 1 do
    begin
      Ident:= TColumn(Grid.Columns[j]).FieldName;
      ini.WriteString(Section, Ident, IntToStr(Grid.Columns[j].Width))
    end
  finally
    ini.UpdateFile;
    ini.Free
  end}
end;

procedure TfrmNewQSO.LoadGrid;
begin
  dmUtils.LoadForm(frmNewQSO)
end;

procedure TfrmNewQSO.SetSplit(s : String);
begin
  frmTRXControl.Split(cqrini.ReadInteger('Split',s,0))
end;

procedure TfrmNewQSO.ShowWindows;
begin
  if frmTRXControl.Showing then
    frmTRXControl.BringToFront;
  if frmBandMap.Showing then
    frmBandMap.BringToFront;
  if frmDXCluster.Showing then
    frmDXCluster.BringToFront;
  if frmQSODetails.Showing then
    frmQSODetails.BringToFront;
  frmNewQSO.BringToFront
end;

procedure TfrmNewQSO.CheckAttachment;
begin
  if DirectoryExists(dmUtils.GetCallAttachDir(edtCall.Text)) then
    sbtnAttach.Visible := True
  else
    sbtnAttach.Visible := False
end;

procedure TfrmNewQSO.CheckQSLImage;
begin
  if dmUtils.QSLFrontImageExists(dmUtils.GetCallForAttach(edtCall.Text)) <> '' then
    sbtnQSL.Visible := True
  else
    sbtnQSL.Visible := False
end;

procedure TfrmNewQSO.UpdateFKeyLabels;
begin
  frmCWKeys.btnF1.Caption  := cqrini.ReadString('CW','CapF1','CQ');
  frmCWKeys.btnF2.Caption  := cqrini.ReadString('CW','CapF2','F2');
  frmCWKeys.btnF3.Caption  := cqrini.ReadString('CW','CapF3','F3');
  frmCWKeys.btnF4.Caption  := cqrini.ReadString('CW','CapF4','F4');
  frmCWKeys.btnF5.Caption  := cqrini.ReadString('CW','CapF5','F5');
  frmCWKeys.btnF6.Caption  := cqrini.ReadString('CW','CapF6','F6');
  frmCWKeys.btnF7.Caption  := cqrini.ReadString('CW','CapF7','F7');
  frmCWKeys.btnF8.Caption  := cqrini.ReadString('CW','CapF8','F8');
  frmCWKeys.btnF9.Caption  := cqrini.ReadString('CW','CapF9','F9');
  frmCWKeys.btnF10.Caption  := cqrini.ReadString('CW','CapF10','F10')
end;

procedure TfrmNewQSO.ChangeCallBookCaption;
begin
  if cqrini.ReadBool('Callbook','HamQTH',True) then
    grbCallBook.Caption := 'Callbook (HamQTH.com)'
  else
    grbCallBook.Caption := 'Callbook (qrz.com)'
end;

procedure TfrmNewQSO.CalculateLocalSunRiseSunSet;
var
  myloc : String;
  Lat, Long : Currency;
  SunRise, SunSet : TDateTime;
  SunDelta : Currency = 0;
  inUTC : Boolean = False;
begin
  myloc := cqrini.ReadString('Station','LOC','');
  inUTC := cqrini.ReadBool('Program','SunUTC',False);
  if dmUtils.SysUTC then
    SunDelta := dmUtils.GetLocalUTCDelta
  else
    SunDelta := cqrini.ReadFloat('Program','SunOffset',0);
  chkAutoMode.Checked := cqrini.ReadBool('NewQSO','AutoMode',True);
  //Writeln('SunDelta:',SunDelta);
  if dmUtils.IsLocOK(myloc) then
  begin
    dmUtils.CoordinateFromLocator(myloc,lat,long);
    dmUtils.CalcSunRiseSunSet(lat,long,SunRise,SunSet);
    {
    if SunDelta <> 0 then
    begin
      SunRise := SunRise + (SunDelta/24);
      SunSet  := SunSet + (SunDelta/24)
    end;
    }
    if not inUTC then
    begin
      SunRise := SunRise + (SunDelta/24);
      SunSet  := SunSet + (SunDelta/24)
    end;
    lblLocSunRise.Caption := TimeToStr(SunRise);
    lblLocSunSet.Caption  := TimeToStr(SunSet)
  end
  else begin
    lblLocSunRise.Caption := '';
    lblLocSunSet.Caption  := ''
  end
end;

procedure TfrmNewQSO.SendSpot;
var
  call : String;
  tmp  : String;
  f    : Currency;
  freq : String;
begin
  if edtCall.Text <> '' then
  begin
    if TryStrToCurr(cmbFreq.Text,f) then
    begin
      f := f*1000;
      tmp := 'DX ' + FloatToStrF(f,ffFixed,8,1) + ' ' + edtCall.Text
    end;
  end
  else begin
    dmData.Q.Close;
    if dmData.trQ.Active then dmData.trQ.Rollback;
    dmData.Q.SQL.Text := 'SELECT callsign,freq FROM cqrlog_main ORDER BY qsodate DESC, time_on DESC LIMIT 1';
    dmData.trQ.StartTransaction;
    if dmData.DebugLevel >=1 then
      Writeln(dmData.Q.SQL.Text);
    dmData.Q.Open();
    call := dmData.Q.Fields[0].AsString;
    freq := FloatToStrF(dmData.Q.Fields[1].AsCurrency*1000,ffFixed,8,1);
    dmData.Q.Close();
    dmData.trQ.Rollback;
    tmp  := 'DX ' + freq + ' ' + call
  end;
  if (call = '') and (edtCall.Text = '') then
  exit;

  with TfrmSendSpot.Create(self) do
  try
    edtSpot.Text := tmp + ' ';
    ShowModal;
    if ModalResult = mrOK then
    begin
      frmDXCluster.edtCommand.Text := trim(edtSpot.Text);
      if frmDXCluster.ConTelnet then
        frmDXCluster.SendCommand(frmDXCluster.edtCommand.Text);
      frmDXCluster.edtCommand.Clear
    end
  finally
    Free
  end
end;

procedure TfrmNewQSO.RunVK(key_pressed: String);
const
  cVoiceKeyer = 'voice_keyer/voice_keyer.sh';
var
   AProcess: TProcess;
begin
  if not FileExists(dmData.HomeDir + cVoiceKeyer) then 
  exit;
  
  AProcess := TProcess.Create(nil);
  try
    AProcess.CommandLine := dmData.HomeDir + cVoiceKeyer  +' '+ key_pressed;
    Writeln('Command line: ',AProcess.CommandLine);
    AProcess.Execute
  finally
    AProcess.Free
  end
end;

procedure TfrmNewQSO.InitializeCW;
begin
  if Assigned(CWint) then
    FreeAndNil(CWint);

  Writeln('CW init');
  CWint := TCWKeying.Create;
  if dmData.DebugLevel>=1 then
    CWint.DebugMode := True;
  if cqrini.ReadInteger('CW','Type',0) > 0 then
  begin
    if cqrini.ReadInteger('CW','Type',0) = 1 then
    begin
      CWint.KeyType := ktWinKeyer;
      CWint.Port    := cqrini.ReadString('CW','wk_port','');
      CWint.Device  := cqrini.ReadString('CW','wk_port','');
      CWint.Open;
      CWint.SetSpeed(cqrini.ReadInteger('CW','wk_speed',30));
      sbNewQSO.Panels[2].Text := IntToStr(cqrini.ReadInteger('CW','wk_speed',30)) + 'WPM'
    end
    else begin
      CWint.KeyType := ktCWdaemon;
      CWint.Port    := cqrini.ReadString('CW','cw_port','');
      CWint.Device  := cqrini.ReadString('CW','cw_address','');
      CWint.Open;
      CWint.SetSpeed(cqrini.ReadInteger('CW','cw_speed',30));
      sbNewQSO.Panels[2].Text := IntToStr(cqrini.ReadInteger('CW','cw_speed',30)) + 'WPM'
    end
  end
end;

initialization
  {$I fNewQSO.lrs}
  
end.

