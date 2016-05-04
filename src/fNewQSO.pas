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
  uCWKeying, ipc, baseunix, dLogUpload, blcksock, dateutils;

const
  cRefCall = 'Ref. call (to change press CTRL+R)   ';
  cMyLoc   = 'My grid (to change press CTRL+L) ';

type
  TRemoteModeType = (rmtFldigi, rmtWsjt);


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
    acLogUploadStatus: TAction;
    acHotkeys: TAction;
    acRefreshTime: TAction;
    acRBNMonitor: TAction;
    acRemoteWsjt: TAction;
    acCommentToCallsign : TAction;
    acUploadToAll: TAction;
    acUploadToHrdLog: TAction;
    acUploadToClubLog: TAction;
    acUploadToHamQTH: TAction;
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
    MenuItem52: TMenuItem;
    MenuItem53: TMenuItem;
    MenuItem56: TMenuItem;
    MenuItem57: TMenuItem;
    MenuItem58: TMenuItem;
    MenuItem86: TMenuItem;
    MenuItem87: TMenuItem;
    MenuItem88: TMenuItem;
    MenuItem89: TMenuItem;
    MenuItem90: TMenuItem;
    MenuItem91: TMenuItem;
    MenuItem92 : TMenuItem;
    MenuItem93 : TMenuItem;
    mnuRemoteModeWsjt: TMenuItem;
    mnuOnlineLog: TMenuItem;
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
    sbtnRefreshTime: TSpeedButton;
    tmrWsjtx: TTimer;
    tmrUploadAll: TTimer;
    tmrFldigi: TTimer;
    tmrESC: TTimer;
    tmrRadio: TTimer;
    tmrRotor: TTimer;
    tmrEnd: TTimer;
    tmrStart: TTimer;
    procedure acBigSquareExecute(Sender: TObject);
    procedure acCommentToCallsignExecute(Sender : TObject);
    procedure acCWFKeyExecute(Sender: TObject);
    procedure acHotkeysExecute(Sender: TObject);
    procedure acLogUploadStatusExecute(Sender: TObject);
    procedure acOpenLogExecute(Sender: TObject);
    procedure acPropExecute(Sender: TObject);
    procedure acQSOListExecute(Sender: TObject);
    procedure acRBNMonitorExecute(Sender: TObject);
    procedure acRefreshTimeExecute(Sender: TObject);
    procedure acRefreshTRXExecute(Sender: TObject);
    procedure acReloadCWExecute(Sender: TObject);
    procedure acRemoteWsjtExecute(Sender: TObject);
    procedure acRotControlExecute(Sender: TObject);
    procedure acSCPExecute(Sender : TObject);
    procedure acSendSpotExecute(Sender : TObject);
    procedure acShowStatBarExecute(Sender: TObject);
    procedure acTuneExecute(Sender : TObject);
    procedure acUploadToAllExecute(Sender: TObject);
    procedure acUploadToClubLogExecute(Sender: TObject);
    procedure acUploadToHamQTHExecute(Sender: TObject);
    procedure acUploadToHrdLogExecute(Sender: TObject);
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
    procedure FormWindowStateChange(Sender: TObject);
    procedure lblAziChangeBounds(Sender: TObject);
    procedure lblQRAChangeBounds(Sender: TObject);
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
    procedure edtNameExit(Sender: TObject);
    procedure edtNameKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure edtPWRKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtQSL_VIAKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
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
    procedure tmrUploadAllTimer(Sender: TObject);
    procedure tmrWsjtxTimer(Sender: TObject);
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
    old_time   : String;
    old_rsts   : String;
    old_rstr   : String;
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
    WhatUpNext : TWhereToUpload;
    UploadAll  : Boolean;

    WsjtxSock             : TUDPBlockSocket;
    WsjtxMode             : String;
    WsjtxBand             : String;
    WsjtxRememberAutoMode : Boolean;

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
    procedure CreateAutoBackup();
    procedure RefreshInfoLabels;
    procedure FillDateTimeFields;
    procedure GoToRemoteMode(RemoteType : TRemoteModeType);
    procedure DisableRemoteMode;
    procedure CloseAllWindows;
    procedure onExcept(Sender: TObject; E: Exception);
    procedure DisplayCoordinates(latitude, Longitude : Currency);
    procedure DrawGrayline;

    function CheckFreq(freq : String) : String;
  public
    QTHfromCb   : Boolean;
    FromDXC     : Boolean;
    UseSpaceBar : Boolean;
    CWint       : TCWDevice;
    ShowWin     : Boolean;

    ClearAfterFreqChange : Boolean;
    ChangeFreqLimit : Double;

    property EditQSO : Boolean read fEditQSO write fEditQSO default False;
    property ViewQSO : Boolean read fViewQSO write fViewQSO default False;

    procedure OnBandMapClick(Sender:TObject;Call,Mode : String;Freq:Currency);
    procedure AppIdle(Sender: TObject; var Handled: Boolean);
    procedure ShowQSO;
    procedure NewQSO;
    procedure ClearAll;
    procedure SavePosition;
    procedure NewQSOFromSpot(call,freq,mode : String;FromRbn : Boolean = False);
    procedure SetEditLabel;
    procedure UnsetEditLabel;
    procedure StoreClubInfo(where,StoreText : String);
    procedure SynCallBook;
    procedure SynDXCCTab;
    procedure SynQSLTab;
    procedure CalculateLocalSunRiseSunSet;
    procedure UploadAllQSOOnline;
    procedure ReturnToNewQSO;
    procedure InitializeCW;
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
  c_waz       : String;
  c_itu       : String;
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
     fQSLViewer, fCWKeys, uMyIni, fDBConnect, fAbout, uVersion, fChangelog,
     fBigSquareStat, fSCP, fRotControl, fLogUploadStatus, fRbnMonitor, fException, fCommentToCall;

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
    c_waz      := '';
    c_itu      := '';

    FreeOnTerminate:= True;
    c_SyncText := 'Working ...';
    Synchronize(@frmNewQSO.SynCallBook);
    dmUtils.GetCallBookData(c_callsign,c_nick,c_qth,c_address,c_zip,c_grid,c_state,c_county,c_qsl,c_iota,c_waz,c_itu,c_ErrMsg);
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
  waz, itu        : String;
begin
  sName    := '';
  QTH      := '';
  loc      := '';
  county   := '';
  qsl_via  := '';
  award    := '';
  state    := '';
  qslrdate := '';
  waz      := '';
  itu      := '';
  
  if dmData.qQSOBefore.RecordCount > 0 then
  begin
    try
      dmData.qQSOBefore.DisableControls;
      dmData.qQSOBefore.Last;
      while (not dmData.qQSOBefore.bof) do
      begin
        if (sName = '') then
          sName := dmData.qQSOBefore.FieldByName('name').AsString;
        if (qth = '') and (dmData.qQSOBefore.FieldByName('callsign').AsString=edtCall.Text) then
          qth := dmData.qQSOBefore.FieldByName('qth').AsString;
        if (loc = '') and (dmData.qQSOBefore.FieldByName('callsign').AsString=edtCall.Text) then
          loc := dmData.qQSOBefore.FieldByName('loc').AsString;
        if (county = '') and (dmData.qQSOBefore.FieldByName('callsign').AsString=edtCall.Text) then
          county := dmData.qQSOBefore.FieldByName('county').AsString;
        if (qsl_via = '') and (dmData.qQSOBefore.FieldByName('callsign').AsString=edtCall.Text) then
          qsl_via := dmData.qQSOBefore.FieldByName('qsl_via').AsString;
        if (award = '') then
          award := dmData.qQSOBefore.FieldByName('award').AsString;
        if (state = '') and (dmData.qQSOBefore.FieldByName('callsign').AsString=edtCall.Text) then
          state := dmData.qQSOBefore.FieldByName('state').AsString;
        if (qslrdate = '') and (not dmData.qQSOBefore.FieldByName('qslr_date').IsNull) then
          lblQSLRcvdDate.Caption := 'QSL rcvd on '+dmData.qQSOBefore.FieldByName('qslr_date').AsString;
        if (waz = '') and (dmData.qQSOBefore.FieldByName('callsign').AsString=edtCall.Text) then
          waz := dmData.qQSOBefore.FieldByName('waz').AsString;
        if (itu = '') and (dmData.qQSOBefore.FieldByName('callsign').AsString=edtCall.Text) then
          itu := dmData.qQSOBefore.FieldByName('itu').AsString;
        dmData.qQSOBefore.Prior
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
      edtState.Text := state;
    if (waz <> '') then
      edtWAZ.Text := waz;
    if (itu <> '') then
      edtITU.Text := itu
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
    adif := dmDXCC.id_country(edtCall.Text,edtState.Text,date,pfx, cont, country, WAZ, posun, ITU, lat, long);
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
  old_time := '';
  old_rstr := '';
  old_rsts := '';
  lblCfmLoTW.Visible := False;
  lblQSLRcvdDate.Visible := False;
  lblQSLRcvdDate.Caption := '';
  lblCountryInfo.Caption := '';
  Mask  := '';
  lblQSONr.Caption := '0';
  mCallBook.Clear;
  dmData.qQSOBefore.Close;
  lblIOTA.Font.Color := clDefault;
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
    cmbProfiles.Text := dmData.GetProfileText(old_prof)
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
  frmGrayline.Refresh;
  if (not mnuRemoteMode.Checked) and (not mnuRemoteModeWsjt.Checked) then
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

  InitializeCW;

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

  if cqrini.ReadBool('Window','Details',True) then
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

  if cqrini.ReadBool('Window','LogUploadStatus', False) then
    acLogUploadStatus.Execute;

  if cqrini.ReadBool('Window','CWType',False) then
    acCWType.Execute;

  if cqrini.ReadBool('Window','RBNMonitor',False) then
    acRBNMonitor.Execute;

  if cqrini.ReadBool('Program','CheckDXCCTabs',True) then
  begin
    Tab := TDXCCTabThread.Create(True);
    Tab.FreeOnTerminate := True;
    Tab.Start
  end;

  if cqrini.ReadBool('Program','CheckQSLTabs',True) then
  begin
    thqsl := TQSLTabThread.Create(True);
    thqsl.FreeOnTerminate := True;
    thqsl.Start
  end;

  dmUtils.InsertQSL_S(cmbQSL_S);
  dmUtils.InsertQSL_R(cmbQSL_R);

  frmBandMap.LoadSettings;
  frmBandMap.LoadFonts;

  if cqrini.ReadBool('BandMap', 'Save', False) then
    frmBandMap.LoadBandMapItemsFromFile(dmData.HomeDir+'bandmap.csv');

  ClearAfterFreqChange := False;//cqrini.ReadBool('NewQSO','ClearAfterFreqChange',False);
  ChangeFreqLimit      := cqrini.ReadFloat('NewQSO','FreqChange',0.010);

  CalculateLocalSunRiseSunSet;
  tmrRadio.Enabled := True;
  dmData.InsertProfiles(cmbProfiles,False);
  cmbProfiles.Text := dmData.GetDefaultProfileText;
  ChangeCallBookCaption;
  BringToFront
end;

procedure TfrmNewQSO.CloseAllWindows;
begin
  //SaveGrid;
  tmrRadio.Enabled := False;
  tmrEnd.Enabled   := False;
  tmrStart.Enabled := False;

  if Assigned(cqrini) then
  begin
    cqrini.WriteBool('Window','CWKeys',frmCWKeys.Showing);

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
    else begin
      cqrini.WriteBool('Window','TRX',False)
    end;
    frmTRXControl.CloseRigs;

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

    if frmLogUploadStatus.Showing then
    begin
      cqrini.WriteBool('Window','LogUploadStatus', True);
      frmLogUploadStatus.Close
    end
    else
      cqrini.WriteBool('Window','LogUploadStatus', False);

    if frmCWType.Showing then
    begin
      cqrini.WriteBool('Window','CWType',True);
      frmCWType.Close
    end
    else
      cqrini.WriteBool('Window','CWType',False);

    if frmRBNMonitor.Showing then
    begin
      cqrini.WriteBool('Window','RBNMonitor',True);
      frmRBNMonitor.Close
    end
    else
      cqrini.WriteBool('Window','RBNMonitor',False)
  end
end;

procedure TfrmNewQSO.SaveSettings;
begin
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
    begin
      Application.Terminate;
      exit
    end
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

  frmBandMap.OnBandMapClick := @OnBandMapClick;

  old_ccall := '';
  old_cmode := '';
  old_cfreq := '';

  Running      := False;
  EscFirstTime := False;
  ChangeDXCC   := False;

  ClearAll;
  edtCall.SetFocus;
  tmrRadio.Enabled := True;
  tmrStart.Enabled := True;
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
  data  : String = '';
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

    data := LowerCase(buf.mtext);
    case cqrini.ReadInteger('fldigi','freq',0) of
      0 : begin
            if frmTRXControl.GetModeFreqNewQSO(mode,mhz) then
            begin
              cmbFreq.Text := mhz
              //cmbMode.Text := mode
            end
          end;

      1 : begin
            i := Pos('mhz',data);
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
            i := Pos('mode',data);
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

    i := Pos('call',data);
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
    i := Pos('time',data);
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
    i := Pos('endtime',data);
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
    i := Pos('name',data);
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
    i := Pos('qth',data);
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
    i := Pos('locator',data);
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
            i := Pos('rx',data);
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
            i := Pos('tx',data);
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
    i := Pos('state',data);
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
    i := Pos('notes',data);
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
      if (cbOffline.Checked and (not mnuRemoteMode.Checked) and (not mnuRemoteModeWsjt.Checked)) then
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
begin
  if not cbOffline.Checked then
  begin
    FillDateTimeFields
  end
end;

procedure TfrmNewQSO.tmrUploadAllTimer(Sender: TObject);
begin
  if (not frmLogUploadStatus.thRunning) then
  begin
    case WhatUpNext of
      upHamQTH :  begin
                    if UploadAll then
                      frmLogUploadStatus.UploadDataToHamQTH(UploadAll)
                    else begin
                      if cqrini.ReadBool('OnlineLog','HaUpOnline',False) then
                        frmLogUploadStatus.UploadDataToHamQTH
                    end;
                    WhatUpNext := upClubLog
                  end;
      upClubLog : begin
                    if UploadAll then
                      frmLogUploadStatus.UploadDataToClubLog(UploadAll)
                    else begin
                      if cqrini.ReadBool('OnlineLog','ClUpOnline',False) then
                        frmLogUploadStatus.UploadDataToClubLog
                    end;
                    WhatUpNext := upHrdLog
                  end;
      upHrdLog  : begin
                    if UploadAll then
                      frmLogUploadStatus.UploadDataToHrdLog(UploadAll)
                    else begin
                      if cqrini.ReadBool('OnlineLog','HrUpOnline',False) then
                        frmLogUploadStatus.UploadDataToHrdLog
                    end;
                    tmrUploadAll.Enabled := False;
                    UploadAll            := False;
                    WhatUpNext           := upHamQTH
                  end
    end //case
  end
end;

procedure TfrmNewQSO.tmrWsjtxTimer(Sender: TObject);
var
  Buf      : String;
  Fdes     : String;
  ParStr   : String;
  TimeLine : String;
  Repbuf   : String;
  index    : Integer;
  ParNum   : Integer;
  MsgType  : Integer;
  Min      : Integer;
  Hour     : Integer;
  RepStart : integer;
  ParDou   : Double;
  Dtim     : TDateTime;
  new      : Boolean;
  TXEna    : Boolean;
  TXOn     : Boolean;
  i        : word;
  TXmode   : String;

  call  : String;
  time1 : String;
  time2 : String;
  sname : String;
  qth   : String;
  loc   : String;
  mhz   : String;
  mode  : String;
  pwr   : String;
  rstS  : String;
  rstR  : String;
  state : String;
  note  : String;
  date  : TDateTime;
  sDate : String='';
  Mask  : String='';

  function UiFBuf(var index:integer):uint32;
  begin
    Result := $01000000*ord(Buf[index])
              + $00010000*ord(Buf[index+1])
              + $00000100*ord(Buf[index+2])
              + ord(Buf[index+3]);         // 32-bit unsigned int BigEndian
    index := index+4                        //point to next element
  end;

  function StFBuf(var index:integer):String;
  var
    P : uint32;
  begin
    P := UiFBuf(index);                 //string length;
    if P = $FFFFFFFF then               //exeption: empty Qstring len: $FFFF FFFF content: empty
    begin
      Result := ''
    end
    else begin
      Result := copy(Buf,index,P);        //string content
      index := index + P                 //point to next element
    end
  end;

 function DUiFBuf(var index:integer):uint64;
 var
    lo,hi    :uint32;
 begin
    hi :=  UiFBuf(index);
    lo :=  UiFBuf(index);
    Result := $100000000 * hi + lo
 end;

  function DouFBuf(var index:integer):Double;  //this does not work!!
  var
    b8: QWord;              //8 bytes integer
    d8: Double absolute b8; //8 bytes double
    buffer : array [0 .. 7] of byte;
    i : Integer;
  Begin
    for i:=0 to 7 do
      buffer[i]:=ord(buf[index+i]);
    index:= index+8;
    b8 := BEtoN(PQWord(@buffer[0])^);
    Result := b8
  end;

  function DiFBuf(var index:integer):int64;
  begin
     REsult := DUiFBuf(index)
  end;

  function IFBuf(var index:integer):int32;
  begin
    Result := UiFBuf(index)
  end;

  function BFBuf(var index:integer):uint8;
  begin
    Result := ord(Buf[index]);
    inc(index)
  end;

  function BoolBuf(var index:integer):Boolean;
  begin
    Result := ord(Buf[index]) = 1;
    inc(index)
  end;

begin
  Buf := Wsjtxsock.RecvPacket(100);
  if WsjtxSock.lasterror=0 then
  begin
    index := pos(#$ad+#$bc+#$cb+#$da,Buf); //QTheader: magic number 0xadbccbda
    RepStart := index; //for possibly reply creation
    if dmData.DebugLevel>=1 then Write('Header position:',index);
    index:=index+4;  // skip QT header

    ParNum :=  UiFBuf(index);
    if dmData.DebugLevel>=1 then Write(' Schema number:',ParNum);

    MsgType :=  UiFBuf(index);
    if dmData.DebugLevel>=1 then Write(' Message type:', MsgType,' ');
    lblCall.Caption       := 'Wsjt-x remote #'+intToStr(MsgType);   //changed to see last received msgtype
    case MsgType of


    0 : begin //Heartbeat
          ParStr := StFBuf(index);
          if dmData.DebugLevel>=1 then Writeln('HeartBeat Id:', ParStr);

          if lblCall.Font.Color = clRed then
            lblCall.Font.Color    := clFuchsia
          else
            lblCall.Font.Color    := clRed;

          if WsjtxMode = '' then
          begin
            Repbuf := copy(Buf,RepStart,length(Buf));  //Reply is copy of heartbeat
            if (length(RepBuf) > 11 ) and (RepBuf[12] = #$00) then //we should have proper reply
            begin
              RepBuf[12] := #$07;    //quick hack: change message type from 0 to 7
              if dmData.DebugLevel>=1 then Writeln('Changed message type from 0 to 7. Sending...')
            end;
            Wsjtxsock.SendString(RepBuf)
          end
        end; // Heartbeat

    1 : begin //Status
          new := false;
          ParStr := StFBuf(index);
          if dmData.DebugLevel>=1 then Writeln('Status Id:', ParStr);
          //----------------------------------------------------
          mhz := IntToStr(DUiFBuf(index));
          case cqrini.ReadInteger('wsjt','freq',0) of
            0 : begin
                  if not frmTRXControl.GetModeFreqNewQSO(mode,mhz) then
                    mhz := ''
                end;
            1 : begin
                  Fdes := copy(mhz,length(mhz)-5,3); //decimal part of MHz
                  mhz := copy(mhz,1,length(mhz)-6); //integer part here
                  mhz := mhz+'.'+Fdes;
                  if dmData.DebugLevel>=1 then Writeln('Qrg :', mhz);
                  mhz := Trim(mhz)
                end;
            2 : mhz := cqrini.ReadString('wsjt','deffreq','3.600')
          end;

          ParStr := dmUtils.GetBandFromFreq(mhz);
          if ParStr<>WsjtxBand then
          begin
            new := true;
            WsjtxBand := ParStr
          end;
          if dmData.DebugLevel>=1 then Writeln('Band :', WsjtxBand);
          //----------------------------------------------------
          ParStr := StFBuf(index);
          if ParStr<>WsjtxMode then
          begin
            new :=true;
            WsjtxMode := ParStr
          end;
          if dmData.DebugLevel>=1 then Writeln('Mode:', WsjtxMode);
           //----------------------------------------------------
          call := trim(StFBuf(index)); //to be sure...
          if dmData.DebugLevel>=1 then Writeln('Call :', call);
         //----------------------------------------------------
          ParStr := StFBuf(index);    //report
          if dmData.DebugLevel>=1 then Writeln('Report: ',ParStr);
          //----------------------------------------------------
          case cqrini.ReadInteger('fldigi','TXmode',1) of
            0 : begin
                  if not frmTRXControl.GetModeFreqNewQSO(TXmode,mhz) then
                    TXmode :='';
                end;
            1 : TXmode:= trim(StFBuf(index));
            2 : TXmode := cqrini.ReadString('fldigi','defmode','RTTY')
          end;
          if dmData.DebugLevel>=1 then Writeln('TXmode: ',Txmode);
          //----------------------------------------------------
          TXEna := BoolBuf(index);
          if dmData.DebugLevel>=1 then Writeln('TXEnabled: ',TXEna);
          //----------------------------------------------------
          TXOn := BoolBuf(index);
          if dmData.DebugLevel>=1 then Writeln('Transmitting: ',TXOn);
          //----------------------------------------------------
          if TXEna and TXOn then
          begin
            edtCall.Text := '';//clean grid like double ESC does
            old_ccall := '';
            old_cfreq := '';
            old_cmode := '';
            if dmUtils.GetBandFromFreq(mhz) <> '' then   //then add new values from status msg
              cmbFreq.Text := mhz;
            cmbMode.Text := TXmode;
            edtCall.Text := call;
            edtCallExit(nil)
          end;
          //----------------------------------------------------
          if new then
          begin
            edtCall.Text := '';//clean grid like double ESC does
            old_ccall := '';
            old_cfreq := '';
            old_cmode := '';
            //frmMonWsjtx.NewBandMode(WsjtxBand,WsjtxMode)
          end
        end; //Status


    2 : begin //Decode
          ParStr := StFBuf(index);
          if dmData.DebugLevel>=1 then Writeln('Decode Id:', ParStr);
          Repbuf := copy(Buf,RepStart,index-RepStart);  //Reply str head part
          new:= BoolBuf(index);
          RepStart := index;     //Reply new/old skip. Str tail start
          if new then
          begin
            if dmData.DebugLevel>=1 then Writeln('New')
          end
          else begin
            if dmData.DebugLevel>=1 then Writeln('Old')
          end;

          //----------------------------------------------------
          ParNum := UiFBuf(index);
          Min := ParNum div 60000;  //minutes from 00:00    UTC
          Hour := Min div 60;
          Min := Min - Hour * 60;
          TimeLine :='';
          if length(intToStr(Hour)) = 1 then
            TimeLine := TimeLine + '0'+ intToStr(Hour) +':'
          else
            TimeLine :=TimeLine + intToStr(Hour) +':';
          if length(intToStr(Min)) = 1 then
            TimeLine := TimeLine + '0' + intToStr(Min) +' '
          else
            TimeLine := TimeLine + intToStr(Min);
          if dmData.DebugLevel>=1 then Writeln(TimeLine);
          //----------------------------------------------------
          ParNum :=  IFBuf(index);
          if dmData.DebugLevel>=1 then Writeln('snr:',ParNum );
          //----------------------------------------------------
          ParDou := DouFBuf(index);
          if dmData.DebugLevel>=1 then Writeln('delta time:',ParDou);
          //----------------------------------------------------
          ParNum :=  UiFBuf(index);
          if dmData.DebugLevel>=1 then Writeln('DeltaFreq:', ParNum);
          //----------------------------------------------------
          mode := StFBuf(index);    //mode as letter: # @
          if dmData.DebugLevel>=1 then Writeln(mode);
          //----------------------------------------------------
          ParStr := StFBuf(index);    //message
          if dmData.DebugLevel>=1 then Writeln(ParStr);
          //----------------------------------------------------
          Repbuf := Repbuf+copy(Buf,RepStart,index-RepStart);  //Reply str tail part
          if dmData.DebugLevel>=1 then Writeln('Orig:',length(Buf),' Re:',length(RepBuf)); //should be 1 less
          if new and (WsjtxBand <>'')  and (WsjtxMode <>'')  and ((pos('CQ ',UpperCase(ParStr))=1) or
            (pos(UpperCase(cqrini.ReadString('Station', 'Call', '')),UpperCase(ParStr))=1)) {and (mnuMoniWsjtx.Visible)} then
            //frmMonWsjtx.AddDecodedMessage(Timeline+' '+mode+' '+ParStr,WsjtxBand,Repbuf);
         //----------------------------------------------------
       end; //Decode

    3 : begin //Clear
          ParStr := StFBuf(index);
          if dmData.DebugLevel>=1 then Writeln('Clear Id:', ParStr);
          //frmMonWsjtx.WsjtxMemo.lines.Clear
        end; //Clear

    5 : begin
          ParStr := StFBuf(index);
          if dmData.DebugLevel>=1 then Writeln('Qso Logged Id:', ParStr);
          //----------------------------------------------------
          ClearAll;
          cbOffline.Checked := True;
          call  := '';
          time1 := '';
          time2 := '';
          sname := '';
          qth   := '';
          loc   := '';
          mhz   := '';
          mode  := '';
          rstS  := '';
          rstR  := '';
          state := '';
          note  := '';
          pwr   := '';

          date := dmUtils.GetDateTime(0);
          edtDate.Clear;
          dmUtils.DateInRightFormat(date,Mask,sDate);
          edtDate.Text:=sDate;

          //----------------------------------------------------
           if TryJulianDateToDateTime(DiFBuf(index),DTim)  then  //date (not used in cqrlog)
             if dmData.DebugLevel>=1 then Writeln('Date :',FormatDateTime('YYYY-MM-DD',DTim));
          //----------------------------------------------------
           ParNum := UiFBuf(index);          //time
           Min  := ParNum div 60000;  //minutes from 00:00    UTC
           Hour := Min div 60;
           Min  := Min - Hour * 60;
           TimeLine :='';
           if length(intToStr(Hour)) = 1 then
             TimeLine := TimeLine + '0'+ intToStr(Hour) +':'
           else
             TimeLine :=TimeLine + intToStr(Hour) +':';
           if length(intToStr(Min)) = 1 then
             TimeLine := TimeLine + '0' + intToStr(Min)
           else
             TimeLine := TimeLine + intToStr(Min);
           if dmData.DebugLevel>=1 then Writeln('Time: ',TimeLine);
           edtStartTime.Text := TimeLine;
           edtEndTime.Text := TimeLine;
           //----------------------------------------------------
           ParNum := BFBuf(index);  //timespec local/utc   (not used in cqrlog)
           if dmData.DebugLevel>=1 then Writeln('timespec: ', ParNum);
           //----------------------------------------------------
           if ParNum = 2 then  // time offset  (not used in cqrlog)
           begin
             ParNum := IFBuf(index);
             if dmData.DebugLevel>=1 then Writeln('offset :', IFBuf(index))
           end;
          //----------------------------------------------------
          call:= trim(StFBuf(index)); //to be sure...
          if dmData.DebugLevel>=1 then Writeln('Call :', call);
          edtCall.Text := call;
          edtCallExit(nil);
          //----------------------------------------------------
          loc:= trim(StFBuf(index));
          if dmData.DebugLevel>=1 then Writeln('Grid :', loc);
          if dmUtils.IsLocOK(loc) then
            edtGrid.Text := loc;
          //----------------------------------------------------
          mhz := IntToStr(DUiFBuf(index));   // in Hz here from wsjtx
          case cqrini.ReadInteger('wsjt','freq',0) of
            0 : begin
                  if  frmTRXControl.GetModeFreqNewQSO(mode,mhz) then
                    cmbFreq.Text := mhz
                end;
            1 : begin
                  Fdes := copy(mhz,length(mhz)-5,3); //decimal part of MHz
                  mhz := copy(mhz,1,length(mhz)-6); //integer part here
                  mhz := mhz+'.'+Fdes;
                  if dmData.DebugLevel>=1 then Writeln('Qrg :', mhz);
                  mhz := Trim(mhz);
                  if dmUtils.GetBandFromFreq(mhz) <> '' then
                    cmbFreq.Text := mhz
                end;
            2 : cmbFreq.Text := cqrini.ReadString('wsjt','deffreq','3.600')
          end;

          ParStr := dmUtils.GetBandFromFreq(mhz);
          if ParStr<>WsjtxBand then
          begin
            new := true;
            WsjtxBand := ParStr
          end;
          if dmData.DebugLevel>=1 then Writeln('Band :', WsjtxBand);
          //----------------------------------------------------
          case cqrini.ReadInteger('wsjt','mode',1) of
            0 : begin
                  if frmTRXControl.GetModeFreqNewQSO(mode,mhz) then
                    cmbMode.Text := mode
                end;
            1 : begin
                  mode:= trim(StFBuf(index));
                  if dmData.DebugLevel>=1 then Writeln('Mode :', mode);
                  cmbMode.Text := mode
                end;
            2 : cmbMode.Text := cqrini.ReadString('wsjt','defmode','RTTY')
           end;
           //----------------------------------------------------
           rstS:= trim(StFBuf(index));
           if dmData.DebugLevel>=1 then Writeln('RSTs :', rstS);
           edtHisRST.Text := rstS;
           //----------------------------------------------------
           rstR:= trim(StFBuf(index));
           if dmData.DebugLevel>=1 then Writeln('RSTr :', rstR);
           edtMyRST.Text := rstR;
           //----------------------------------------------------
           pwr:= trim(StFBuf(index));
           if dmData.DebugLevel>=1 then Writeln('Pwr :', pwr);
           edtPWR.Text := pwr;
           //----------------------------------------------------
           note:= trim(StFBuf(index));
           if dmData.DebugLevel>=1 then Writeln('Comments :', note);
           edtRemQSO.Text := note;
           //--------------------------------------------------
           if dmData.DebugLevel>=1 then Writeln('Name :', sname);
           sname:= trim(StFBuf(index));
           if dmData.DebugLevel>=1 then Writeln('Name :', sname);
           if dmData.DebugLevel>=1 then Writeln('edtName :',edtName.Text );
           if sname <>'' then  //if user does not give name edtName stays what qrz.com may have found
             edtName.Text := sname;
           edtNameExit(nil);
           //----------------------------------------------------
           btnSave.Click;
           writeln('end loging');
         end; //QSO logged in

     6 : begin //Close
           ParStr := StFBuf(index);
           if dmData.DebugLevel>=1 then Writeln('Close Id:', ParStr);
           //wsjtx closed maybe need to disable remote mode  ?
           DisableRemoteMode
         end //Close
    end //case
  end  //if WsjtxSock.lasterror=0 then
end;

procedure TfrmNewQSO.FormCreate(Sender: TObject);
begin
  CWint := nil;
  tmrRadio.Enabled := False;
  fViewQSO := False;
  fEditQSO := False;
  FromDXC  := False;
  ShowWin  := False;
  old_t_band := '';
  old_t_mode := '';
  old_prof   := -1;
  WhatUpNext := upHamQTH;
  UploadAll  := False
end;

procedure TfrmNewQSO.btnSaveClick(Sender: TObject);
var
  tmp    : Integer;
  myloc  : String;
  id     : LongInt;
  Delete : Boolean = False;
  ShowMain : Boolean = False;
  date     : TDate;
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

  if edtITU.Text = '' then
    edtITU.Text := '0';
  if edtWAZ.Text = '' then
    edtWAZ.Text := '0';

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

  //SaveGrid;
  dmData.SaveComment(edtCall.Text,mComment.Text);

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
                   id);
    if (old_call<>edtCall.Text) or (old_mode<>cmbMode.Text) or (StrToFloat(old_freq)<>StrToFloat(cmbFreq.Text)) or
       (old_date<>StrToDate(edtDate.Text)) or (old_time<>edtStartTime.Text) or (old_rsts<>edtHisRST.Text) or
       (old_rstr<>edtMyRST.Text) then
    begin
      dmData.RemoveeQSLUploadedFlag(id);
      dmData.RemoveLoTWUploadedFlag(id)
    end
  end
  else begin
    if (not mnuRemoteMode.Checked) and (not mnuRemoteModeWsjt.Checked) then
      if edtCall.Focused then
      begin
        edtCallExit(nil)
      end;

    old_prof := dmData.GetNRFromProfile(cmbProfiles.Text);
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
    if not cbOffline.Checked then
    begin
      if cqrini.ReadBool('BandMap','AddAfterQSO',False) then
        acAddToBandMap.Execute;
      if Delete then
        frmBandMap.DeleteFromBandMap(edtCall.Text,cmbMode.Text,dmUtils.GetBandFromFreq(cmbFreq.Text))
    end;
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
  if (not mnuRemoteMode.Checked) and (not mnuRemoteModeWsjt.Checked) then
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
    if (not mnuRemoteMode.Checked) and (not mnuRemoteModeWsjt.Checked) then
     edtCall.SetFocus;
  UploadAllQSOOnline
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
      DrawGrayline
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
    edtAward.SetFocus;
    key := 0
  end;
  if (key = 38) then //up arrow
  begin
    edtState.SetFocus;
    key := 0
  end
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
    key := 0
  end;
  if (key = 38) then //up arrow
  begin
    edtCounty.SetFocus;
    key := 0
  end
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
  CalculateDistanceEtc
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
  frmQSODetails.itu := edtITU.Text
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

procedure TfrmNewQSO.edtQTHExit(Sender: TObject);
var
  tmp : String;
begin
  if (edtQTH.Text <> '') and cqrini.ReadBool('NewQSO','CapFirstQTHLetter',True) then
  begin
    tmp := edtQTH.Text;
    tmp[1] := UpCase(tmp[1]);
    edtQTH.Text := tmp
  end;
  CheckQTHClub
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
  if cqrini.ReadBool('Backup','Enable',False) then
  begin
    if cqrini.ReadBool('Backup','AskFirst',False) then
    begin
      case Application.MessageBox('Do you want to backup your data?','Question ...',mb_YesNoCancel+mb_IconQuestion) of
        idCancel : begin
                     CloseAction := caNone;
                     exit
                   end;
        idYes : CreateAutoBackup()
      end //case
    end
    else
      CreateAutoBackup()
  end;
  CloseAllWindows;
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
    edtState.SetFocus;
    key := 0
  end;
  if (key = 38) then //up arrow
  begin
    edtWAZ.SetFocus;
    key := 0
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    edtState.SetFocus;
    key := 0
  end
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
    frmSelectDXCC.pgDXCC.PageIndex := 0;
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
        lblIOTA.Font.Color := clDefault
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
  if (dmData.qQSOBefore.RecordCount > 0) and (not mnuRemoteMode.Checked) and (not mnuRemoteModeWsjt.Checked)  then
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
    if dmData.trLongNote.Active then dmData.trLongNote.Rollback;
    dmData.qLongNote.SQL.Text := 'SELECT id_long_note, note FROM long_note';
    dmData.trLongNote.StartTransaction;
    try
      dmData.qLongNote.Open();
      if dmData.qLongNote.Fields[0].IsNull then
        new := True;
      mNote.Lines.Text := dmData.qLongNote.Fields[1].AsString;
    finally
      dmData.qLongNote.Close();
      dmData.trLongNote.Rollback
    end;
    ShowModal;
    if ModalResult = mrOK then
    begin
      if new then
        dmData.qLongNote.SQL.Text := 'insert into long_note(id_long_note,note) values (1,:note)'
      else
        dmData.qLongNote.SQL.Text := 'UPDATE long_note set note = :note where id_long_note = 1';
      try try
        dmData.qLongNote.Params[0].AsString := mNote.Text;
        dmData.trLongNote.StartTransaction;
        dmData.qLongNote.ExecSQL;
      dmData.trLongNote.Commit;
      dmData.qLongNote.Close();
      except
        dmData.trLongNote.Rollback
      end
      finally
        if dmData.trLongNote.Active then
          dmData.trLongNote.Commit;
        dmData.qLongNote.Close()
      end
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
    DisableRemoteMode
  else
    GoToRemoteMode(rmtFldigi)
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
  lat, lng : Currency;
begin
  f := frmTRXControl.GetFreqMHz;
  if f = 0.0 then
    f := StrToFloat(cmbFreq.Text);
  dmUtils.GetRealCoordinate(lblLat.Caption,lblLong.Caption,lat,lng);
  frmBandMap.AddToBandMap(f*1000,edtCall.Text,cmbMode.Text,dmUtils.GetBandFromFreq(cmbFreq.Text),'',lat,
                          lng,clBlack,clWhite,True,sbtnLoTW.Visible,sbtneQSL.Visible)
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
  if Assigned(CWint) then
  begin
    frmCWType.edtSpeed.Value:= CWint.GetSpeed;
    frmCWType.Show
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

procedure TfrmNewQSO.acRBNMonitorExecute(Sender: TObject);
begin
  frmRBNMonitor.Show
end;

procedure TfrmNewQSO.acRefreshTimeExecute(Sender: TObject);
begin
  FillDateTimeFields
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

procedure TfrmNewQSO.acRemoteWsjtExecute(Sender: TObject);
begin
  if mnuRemoteModeWsjt.Checked then
    DisableRemoteMode
  else
    GoToRemoteMode(rmtWsjt)
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
  if Assigned(CWint) then
  begin
    CWint.TuneStart;
    ShowMessage('Tunning started .... '+LineEnding+LineEnding+'OK to abort');
    CWint.TuneStop
  end
end;

procedure TfrmNewQSO.acUploadToAllExecute(Sender: TObject);
begin
  if not tmrUploadAll.Enabled then
  begin
    UploadAll            := True;
    tmrUploadAll.Enabled := True
  end
end;

procedure TfrmNewQSO.acUploadToClubLogExecute(Sender: TObject);
begin
  frmLogUploadStatus.UploadDataToClubLog
end;

procedure TfrmNewQSO.acUploadToHamQTHExecute(Sender: TObject);
begin
  frmLogUploadStatus.UploadDataToHamQTH
end;

procedure TfrmNewQSO.acUploadToHrdLogExecute(Sender: TObject);
begin
  frmLogUploadStatus.UploadDataToHrdLog
end;

procedure TfrmNewQSO.acCWFKeyExecute(Sender: TObject);
begin
  UpdateFKeyLabels;
  frmCWKeys.Show
end;

procedure TfrmNewQSO.acHotkeysExecute(Sender: TObject);
begin
  dmUtils.OpenInApp(dmData.HelpDir+'h20.html')
end;

procedure TfrmNewQSO.acLogUploadStatusExecute(Sender: TObject);
begin
  frmLogUploadStatus.Show
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

procedure TfrmNewQSO.acCommentToCallsignExecute(Sender : TObject);
begin
  frmCommentToCall := TfrmCommentToCall.Create(frmNewQSO);
  try
    frmCommentToCall.ShowModal
  finally
    frmCommentToCall.Free
  end
end;

procedure TfrmNewQSO.acOpenLogExecute(Sender: TObject);
var
  old : String;
  LogId   : Integer;
  LogName : String;
begin
  with TfrmDBConnect.Create(self) do
  try
    old := dmData.LogName;
    OpenFromMenu := True;
    ShowModal;
    if ModalResult = mrOK then
    begin
      if old = dmData.qLogList.Fields[1].AsString then exit;

      LogId   := dmData.qLogList.Fields[0].AsInteger;
      LogName := dmData.qLogList.Fields[1].AsString;

      frmDXCluster.StopAllConnections;
      SaveSettings;
      dmData.CloseDatabases;

      dmData.OpenDatabase(LogId);
      dmData.RefreshLogList(LogId);

      dmData.LogName := LogName;

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
      MinDXCluster := True
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

procedure TfrmNewQSO.lblAziChangeBounds(Sender: TObject);
begin
  RefreshInfoLabels
end;

procedure TfrmNewQSO.lblQRAChangeBounds(Sender: TObject);
begin
  RefreshInfoLabels
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
begin
  dmUtils.ShowQRZInBrowser(dmData.qQSOBefore.Fields[4].AsString)
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
    if dmData.DebugLevel>=1 then Writeln('Command line: ',AProcess.CommandLine);
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
      if frmRbnMonitor.Showing then
        dmUtils.LoadFontSettings(frmRbnMonitor)
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
  if (dmData.qQSOBefore.RecordCount > 0) and (not mnuRemoteMode.Checked) and (not mnuRemoteModeWsjt.Checked) then
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
  cmbFreq.Text := CheckFreq(cmbFreq.Text);
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
  CheckAwardClub
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
  if (not (fViewQSO or fEditQSO)) then
  begin
    InsertNameQTH;
    cmbQSL_S.Text := dmData.SendQSL(edtCall.Text,cmbMode.Text,cmbFreq.Text,adif)
  end;


  if ChangeDXCC then
    ShowDXCCInfo(adif)
  else
    ShowDXCCInfo();

  ShowCountryInfo;
  ChangeReports;
  ShowStatistic(adif);
  CalculateDistanceEtc;
  mComment.Text := dmData.GetComment(edtCall.Text);
  if (lblDXCC.Caption <> '!') and (lblDXCC.Caption <> '#') then
  begin
    if frmGrayline.Showing then
    begin
      DrawGrayline
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
    lblIOTA.Font.Color := clDefault;
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
        QRZ.FreeOnTerminate := True;
        QRZ.Start
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
        //SaveGrid;
        if edtCall.Text = '' then
        begin
          if edtCall.Enabled then
            edtCall.SetFocus
        end
        else
          edtCall.Text := ''; // OnChange calls ClearAll;
        EscFirstTime := False;
        old_ccall := '';
        old_cfreq := '';
        old_cmode := ''
      end
      else begin
        if Assigned(CWint) then
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
    ClearAll;
    key := 0
  end;

  if (Key >= VK_F1) and (Key <= VK_F10) and (Shift = []) then
  begin
    if (cmbMode.Text='SSB') then
      RunVK(dmUtils.GetDescKeyFromCode(Key))
    else
      if Assigned(CWint) then
        CWint.SendText(dmUtils.GetCWMessage(dmUtils.GetDescKeyFromCode(Key),edtCall.Text,edtHisRST.Text,edtName.Text,lblGreeting.Caption,''));
    key := 0
  end;

  if (key = 33) and (not dbgrdQSOBefore.Focused) then//pgup
  begin
    if Assigned(CWint) then
    begin
      speed := CWint.GetSpeed+2;
      CWint.SetSpeed(speed);
      sbNewQSO.Panels[2].Text := IntToStr(speed)+'WPM'
    end
  end;

  if (key = 34) and (not dbgrdQSOBefore.Focused) then//pgup
  begin
    if Assigned(CWint) then
    begin
      speed := CWint.GetSpeed-2;
      CWint.SetSpeed(speed);
      sbNewQSO.Panels[2].Text := IntToStr(speed)+'WPM'
    end
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
      QRZ.FreeOnTerminate := True;
      QRZ.Start
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
    acSendSpot.Execute;

  if ((Shift = [ssAlt]) and (key = VK_V)) then
    frmTRXControl.btnMemDwn.Click;
  if ((Shift = [ssAlt]) and (key = VK_B)) then
    frmTRXControl.btnMemUp.Click
end;

procedure TfrmNewQSO.FormKeyPress(Sender: TObject; var Key: char);
begin
  case key of
    #13 : begin                     //enter
            btnSave.Click;
            //SaveGrid;
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
            if cqrini.ReadBool('BandMap','PlusToBandMap',False) then
            begin
              acAddToBandMap.Execute;
              key := #0
            end
          end
  end; //case
end;

procedure TfrmNewQSO.edtStartTimeKeyPress(Sender: TObject; var Key: char);
begin
  if not ((key in ['0'..'9']) or (key = ':') or (key=#40) or (key=#38) or (key = #32) or (key=#8)) then
    key := #0
end;

procedure TfrmNewQSO.edtStateExit(Sender: TObject);
begin
  ShowDXCCInfo();
  ShowCountryInfo;
  ShowStatistic(adif);
  CalculateDistanceEtc;
  if frmGrayline.Showing then
    DrawGrayline;
  CheckStateClub
end;

procedure TfrmNewQSO.edtStateKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key = 40) then  //down arrow
  begin
    edtCounty.SetFocus;
    key := 0
  end;
  if (key = 38) then //up arrow
  begin
    cmbIOTA.SetFocus;
    key := 0
  end;
  if ((key = VK_SPACE) and UseSpaceBar) then
  begin
    edtCounty.SetFocus;
    key := 0
  end
end;

procedure TfrmNewQSO.edtWAZExit(Sender: TObject);
begin
  frmQSODetails.waz := edtWAZ.Text
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
var
  aColumns : array of TVisibleColumn;
  i : Integer;
  y : Integer;

  fQsoGr  : String;
  fqSize  : Integer;
  isAdded : Boolean = False;
  fDefault : Boolean;
  ColExists : Boolean = False;
begin
  dbgrdQSOBefore.DataSource := dmData.dsrQSOBefore;
  dbgrdQSOBefore.ResetColWidths;
  LoadGrid;
  SetLength(aColumns,38);
  dmUtils.LoadVisibleColumnsConfiguration(aColumns);

  fQsoGr   := cqrini.ReadString('Fonts','QGrids','Sans 10');
  fqSize   := cqrini.ReadInteger('Fonts','qSize',10);
  fDefault := cqrini.ReadBool('Fonts','UseDefault',True);

  try
    //it's strange but disable grid browsing speed up this much more
    //then code refactoring before
    dbgrdQSOBefore.DataSource.DataSet.DisableControls;

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

      if (UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = 'FREQ') then
      begin
        dbgrdQSOBefore.Columns[i].Alignment       := taRightJustify;
        dbgrdQSOBefore.Columns[i].DisplayFormat   := '###,##0.0000;;';
        dbgrdQSOBefore.Columns[i].Title.Alignment := taCenter
      end;

      for y:=0 to Length(aColumns)-1 do
      begin
        if UpperCase(dbgrdQSOBefore.Columns[i].DisplayName) = aColumns[y].FieldName then
        begin
          dbgrdQSOBefore.Columns[i].Visible := aColumns[y].Visible;
          aColumns[y].Exists := True;
          if aColumns[y].Visible and (dbgrdQSOBefore.Columns[i].Width = 0) then
            dbgrdQSOBefore.Columns[i].Width := 60
        end
      end;

      if fDefault then
      begin
        dbgrdQSOBefore.Columns[i].Title.Font.Name := 'default';
        dbgrdQSOBefore.Columns[i].Title.Font.Size := 0
      end
      else begin
        dbgrdQSOBefore.Columns[i].Title.Font.Name := fQsoGr;
        dbgrdQSOBefore.Columns[i].Title.Font.Size := fqSize
      end
    end;

    for i:=0 to Length(aColumns) do
    begin
      if (aColumns[i].Visible) and (not aColumns[i].Exists) then
      begin
        dbgrdQSOBefore.Columns.Add;
        dbgrdQSOBefore.Columns[dbgrdQSOBefore.Columns.Count-1].FieldName   := aColumns[i].FieldName;
        dbgrdQSOBefore.Columns[dbgrdQSOBefore.Columns.Count-1].DisplayName := aColumns[i].FieldName;
        dbgrdQSOBefore.Columns[dbgrdQSOBefore.Columns.Count-1].Width       := 60
      end
    end
  finally
    dbgrdQSOBefore.DataSource.DataSet.EnableControls
  end
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
  space: String;
begin
  if old_stat_adif = ref_adif then
    exit;
  old_stat_adif := ref_adif;
  sgrdStatistic.ColCount  := cMaxBandsCount;
  ClearStatGrid;

  space := ' ';
  if cqrini.ReadBool('Fonts','GridDotsInsteadSpaces',False) = True then
  begin
    space := '.';
  end;

  for i:=0 to cMaxBandsCount-1 do
  begin
    if dmUtils.MyBands[i][0]='' then
    begin
      sgrdStatistic.ColCount  := i+1;
      break
    end;
    sgrdStatistic.Cells[i+1,0] := dmUtils.MyBands[i][1];
    sgrdStatistic.Cells[i+1,1] := space+space+space;
    sgrdStatistic.Cells[i+1,2] := space+space+space;
    sgrdStatistic.Cells[i+1,3] := space+space+space;
  end;

  if dmData.trQ.Active then
    dmData.trQ.RollBack;
  dmData.Q.Close;

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
  dmData.trQ.StartTransaction;
  dmData.Q.Open;
  while not dmData.Q.Eof do
  begin
    i    := dmUtils.GetBandPos(dmData.Q.Fields[0].AsString)+1;
    mode := dmData.Q.Fields[1].AsString;
    QSLR := dmData.Q.Fields[2].AsString;
    LoTW := dmData.Q.Fields[3].AsString;
    eQSL := dmData.Q.Fields[4].AsString;
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
          if(sgrdStatistic.Cells[i,1] = space+space+space) then sgrdStatistic.Cells[i,1] := ' X ';
        if ((mode = 'CW') or (mode = 'CWR')) then
          if (sgrdStatistic.Cells[i,2] = space+space+space) then sgrdStatistic.Cells[i,2] := ' X ';
        if ((mode <> 'SSB') and (mode <>'FM') and (mode <> 'AM') and (mode <> 'CW') and (mode <> 'CWR')) then
          if (sgrdStatistic.Cells[i,3] = space+space+space) then sgrdStatistic.Cells[i,3] := ' X '
      end;
      dmData.Q.Next;
  end;
  dmData.Q.Close;
  dmData.trQ.Rollback
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

    DisplayCoordinates(lat,long);
    DrawGrayline;

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
    if cqrini.ReadBool('Program','ShowMiles',False) then
      lblQRA.Caption := FloatToStr(dmUtils.KmToMiles(StrToFloat(qra))) + ' miles'
    else
      lblQRA.Caption := qra + ' km';
    lblAzi.Caption := azim;
    Azimuth := azim
  end;
  RefreshInfoLabels;
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
    old_call := dmData.qQSOBefore.FieldByName('callsign').AsString;
    old_time := dmData.qQSOBefore.FieldByName('time_on').AsString;
    old_rsts := dmData.qQSOBefore.FieldByName('rst_s').AsString;
    old_rstr := dmData.qQSOBefore.FieldByName('rst_r').AsString
  end
  else begin
    old_date := dmUtils.MyStrToDate(dmData.qCQRLOG.FieldByName('qsodate').AsString);
    old_freq := dmData.qCQRLOG.FieldByName('freq').AsString;
    old_mode := dmData.qCQRLOG.FieldByName('mode').AsString;
    old_adif := dmDXCC.AdifFromPfx(dmData.qCQRLOG.FieldByName('dxcc_ref').AsString);
    old_qslr := dmData.qCQRLOG.FieldByName('qsl_r').AsString;
    old_call := dmData.qCQRLOG.FieldByName('callsign').AsString;
    old_time := dmData.qCQRLOG.FieldByName('time_on').AsString;
    old_rsts := dmData.qCQRLOG.FieldByName('rst_s').AsString;
    old_rstr := dmData.qCQRLOG.FieldByName('rst_r').AsString
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
  cqrini.SaveToDisk
end;

procedure TfrmNewQSO.SynCallBook;
var
  County  : String = '';
  StoreTo : String = '';
  IgnoreQRZ : Boolean = False;
  MvToRem   : Boolean = False;
  AlwaysReplace : Boolean;
  ReplaceZonesEtc : Boolean;
  tmp : String;
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

    IgnoreQRZ     := cqrini.ReadBool('NewQSO','IgnoreQRZ',False);
    MvToRem       := cqrini.ReadBool('NewQSO','MvToRem',True);
    AlwaysReplace := cqrini.ReadBool('NewQSO','UseCallBookData',False);
    ReplaceZonesEtc := cqrini.ReadBool('NewQSO','UseCallbookZonesEtc',True);


    if (not IgnoreQRZ) and (c_qsl<>'') then
    begin
      if (edtQSL_VIA.Text = '') then
      begin
        tmp := dmUtils.GetQSLVia(c_qsl);
        if dmUtils.IsQSLViaValid(dmUtils.CallTrim(tmp)) then
          edtQSL_VIA.Text := dmUtils.CallTrim(tmp)
      end;
      if MvToRem then
      begin
        if (Pos(LowerCase(c_qsl),LowerCase(edtRemQSO.Text))=0) then
        begin
          if edtRemQSO.Text= '' then
            edtRemQSO.Text := c_qsl
          else
            edtRemQSO.Text := edtRemQSO.Text + ', '+c_qsl
        end
      end
    end;

    if (edtName.Text = '') or AlwaysReplace then
      edtName.Text := c_nick; //operator's name
    if ((edtQTH.Text = '') or AlwaysReplace) and (c_callsign = edtCall.Text) then
      edtQTH.Text := c_qth;  //qth

    if ((edtGrid.Text='') or AlwaysReplace) and dmUtils.IsLocOK(c_grid) and (c_callsign = edtCall.Text) then
    begin
      edtGrid.Text := c_grid;
      edtGridExit(nil)
    end;  //grid

    if (cmbIOTA.Text='') or AlwaysReplace then
    begin
      cmbIOTA.Text := c_iota;
      cmbIOTAExit(nil)
    end;

    if ((c_state <> '') and (edtState.Text = '') or AlwaysReplace or ReplaceZonesEtc) and (c_callsign = edtCall.Text) then
    begin
      edtState.Text := c_state;
      if ((c_county <> '') and (edtCounty.Text='')) or AlwaysReplace or ReplaceZonesEtc then
      begin
        if (edtState.Text<>'') then
          edtCounty.Text := edtState.Text+','+c_county
        else
          edtCounty.Text := c_county
      end
    end;  //county

    if ((c_itu<>'') or ReplaceZonesEtc) and (c_callsign = edtCall.Text) then
    begin
      edtITU.Text    := c_itu;
      lblITU.Caption := c_itu
    end;

    if ((c_waz<>'') or ReplaceZonesEtc) and (c_callsign = edtCall.Text) then
    begin
      edtWAZ.Text    := c_waz;
      lblWAZ.Caption := c_waz
    end;

    if (edtGrid.Text <> '') then
    begin
      CalculateDistanceEtc
    end;

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
  if edtState.Text<>'' then
    edtStateExit(nil);
  CheckAwardClub;
  CheckQTHClub;
  CheckCountyClub;
  CheckStateClub
end;

procedure TfrmNewQSO.AppIdle(Sender: TObject; var Handled: Boolean);
begin
  Handled := True
end;

procedure TfrmNewQSO.NewQSOFromSpot(call,freq,mode : String;FromRbn : Boolean = False);
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
    if not FromRbn then
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
  lblCall.Font.Color := clDefault;
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
  if (where = 'award') and (Pos(LowerCase(StoreText),LowerCase(edtAward.text))=0) then
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
  if (where = 'comm. for QSO') and (Pos(LowerCase(StoreText),LowerCase(edtRemQSO.text))=0) then
  begin
    if edtRemQSO.Text <> ''  then
      edtRemQSO.Text := edtRemQSO.Text + ' ' + StoreText
    else
      edtRemQSO.Text := StoreText;
  end;
  if (where = 'name') and (Pos(LowerCase(StoreText),LowerCase(edtName.text))=0) then
  begin
    if edtName.Text <> '' then
      edtName.Text := edtName.Text + ' ' + StoreText
    else
      edtName.Text := StoreText;
  end;
  if (where = 'county') and (Pos(LowerCase(StoreText),LowerCase(edtCounty.text))=0) and (edtCounty.Text <> '') then
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
  frmCWKeys.fraCWKeys.UpdateFKeyLabels
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
  if dmUtils.IsLocOK(myloc) then
  begin
    dmUtils.CoordinateFromLocator(myloc,lat,long);
    dmUtils.CalcSunRiseSunSet(lat,long,SunRise,SunSet);
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
    AProcess.CommandLine := 'bash ' + dmData.HomeDir + cVoiceKeyer  +' '+ key_pressed;
    if dmData.DebugLevel>=1 then Writeln('Command line: ',AProcess.CommandLine);
    AProcess.Execute
  finally
    AProcess.Free
  end
end;

procedure TfrmNewQSO.InitializeCW;
var
  KeyType: TKeyType;
begin
  if Assigned(CWint) then
    FreeAndNil(CWint);

  if dmData.DebugLevel>=1 then Writeln('CW init');
  case  cqrini.ReadInteger('CW','Type',0) of
    1 : begin
          CWint := TCWWinKeyerUSB.Create;
          CWint.Port    := cqrini.ReadString('CW','wk_port','');
          CWint.Device  := cqrini.ReadString('CW','wk_port','');
          CWint.PortSpeed := 1200;
          CWint.Open;
          CWint.SetSpeed(cqrini.ReadInteger('CW','wk_speed',30));
          CWint.DebugMode := dmData.DebugLevel>=1;
          sbNewQSO.Panels[2].Text := IntToStr(cqrini.ReadInteger('CW','wk_speed',30)) + 'WPM'
        end;
    2 : begin
          CWint    := TCWDaemon.Create;
          CWint.Port    := cqrini.ReadString('CW','cw_port','');
          CWint.Device  := cqrini.ReadString('CW','cw_address','');
          CWint.PortSpeed := 0;
          CWint.Open;
          CWint.SetSpeed(cqrini.ReadInteger('CW','cw_speed',30));
          CWint.DebugMode := dmData.DebugLevel>=1;
          sbNewQSO.Panels[2].Text := IntToStr(cqrini.ReadInteger('CW','cw_speed',30)) + 'WPM'
        end;
    3 : begin
          CWint := TCWK3NG.Create;
          CWint.Port    := cqrini.ReadString('CW','K3NGPort','');
          CWint.Device  := cqrini.ReadString('CW','K3NGPort','');
          CWint.PortSpeed := cqrini.ReadInteger('CW','K3NGSerSpeed',115200);
          CWint.Open;
          CWint.SetSpeed(cqrini.ReadInteger('CW','K3NGSpeed',30));
          CWint.DebugMode := dmData.DebugLevel>=1;
          sbNewQSO.Panels[2].Text := IntToStr(cqrini.ReadInteger('CW','K3NGSpeed',30)) + 'WPM'
        end;
    4 : begin
          CWint        := TCWHamLib.Create;
          CWint.Port   := cqrini.ReadString('TRX1','RigCtldPort','4532');
          CWint.Device := cqrini.ReadString('TRX1','host','localhost');
          CWint.Open;
          CWint.SetSpeed(cqrini.ReadInteger('CW','HamLibSpeed',30));
          CWint.DebugMode := dmData.DebugLevel>=1;
          sbNewQSO.Panels[2].Text := IntToStr(cqrini.ReadInteger('CW','HamLibSpeed',30)) + 'WPM'
        end
  end //case
end;

procedure TfrmNewQSO.OnBandMapClick(Sender:TObject;Call,Mode: String;Freq:Currency);
begin
  NewQSOFromSpot(Call,FloatToStr(Freq),Mode)
end;

procedure TfrmNewQSO.CreateAutoBackup();
var
  path1, path2 : String;
begin
  path1 := cqrini.ReadString('Backup','Path',dmData.DataDir);
  path2 := cqrini.ReadString('Backup','Path1','');

  if not DirectoryExists(path1) then
    exit;

  if (path2<>'') and (not DirectoryExists(path2)) then
    exit;

  with TfrmExportProgress.Create(self) do
  try
    AutoBackup       := True;
    SecondBackupPath := Path2;

    FileName         := Path1 + cqrini.ReadString('Station', 'Call', '');
    if cqrini.ReadInteger('Backup', 'BackupType', 0) > 0 then
      FileName := FileName + '_backup.adi'
    else
      FileName := FileName + '_'+FormatDateTime('yyyy-mm-dd_hh-mm-ss',now)+'.adi';
    ExportType := 2;

    ShowModal
  finally
    Free
  end
end;

procedure TfrmNewQSO.UploadAllQSOOnline;
begin
  if not tmrUploadAll.Enabled then
  begin
    UploadAll            := False;
    tmrUploadAll.Enabled := True
  end
end;

function TfrmNewQSO.CheckFreq(freq : String) : String;
begin
  if (Pos(',',cmbFreq.Text) > 0) then
  begin
    freq := cmbFreq.Text;
    freq[Pos(',',cmbFreq.Text)] := FormatSettings.DecimalSeparator;
    Result := freq
  end;
  Result := freq
end;

procedure TfrmNewQSO.ReturnToNewQSO;
begin
  if edtCall.Enabled then
    edtCall.SetFocus
end;

procedure TfrmNewQSO.RefreshInfoLabels;
begin
  lblHisTime.Refresh;
  lblGreeting.Refresh;
  lblTarSunRise.Refresh;
  lblTarSunSet.Refresh;
  lblHisTime.Refresh
end;

procedure TfrmNewQSO.FillDateTimeFields;
var
  Date : TDateTime;
  sDate : String='';
  Mask  : String='';
begin
  date := dmUtils.GetDateTime(0);
  StartTime := date;
  edtDate.Clear;
  dmUtils.DateInRightFormat(date,Mask,sDate);
  edtDate.Text      := sDate;
  edtStartTime.Text := FormatDateTime('hh:mm',date);
  edtEndTime.Text   := FormatDateTime('hh:mm',date)
end;

procedure TfrmNewQSO.GoToRemoteMode(RemoteType : TRemoteModeType);
var
  run  : Boolean = False;
  path : String = '';
begin
  case RemoteType of
    rmtFldigi : begin
                  mnuRemoteMode.Checked := True;
                  lblCall.Caption       := 'Remote mode!';
                  tmrFldigi.Interval    := cqrini.ReadInteger('fldigi','interval',2)*1000;
                  run                   := cqrini.ReadBool('fldigi','run',False);
                  path                  := cqrini.ReadString('fldigi','path','');
                  tmrFldigi.Enabled     := True
                end;
    rmtWsjt   : begin
                  mnuRemoteModeWsjt.Checked := True;
                  lblCall.Caption           := 'Wsjtx remote';
                  path                      := cqrini.ReadString('wsjt','path','');
                  run                       := cqrini.ReadBool('wsjt','run',False);

                  WsjtxMode := '';    //will be set by type1 'status'-message
                  WsjtxBand := '';

                  //Timer fetches only 1 UDP packet at time.
                  tmrWsjtx.Interval := 1000;
                  tmrWsjtx.Enabled  := True;

                  // start UDP server
                  WsjtxSock := TUDPBlockSocket.Create;
                  {if dmData.DebugLevel>=1 then} Writeln('Socket created!');
                  try
                    WsjtxSock.bind('127.0.0.1',cqrini.ReadString('wsjt','port','2237'));
                    {if dmData.DebugLevel>=1 then }Writeln('Bind issued '+cqrini.ReadString('wsjt','port','2237'))
                  except
                      {if dmData.DebugLevel>=1 then} Writeln('Could not bind socket for wsjtx!');
                     DisableRemoteMode;
                     exit
                  end;
                  WsjtxRememberAutoMode := chkAutoMode.Checked;
                  chkAutoMode.Checked   := False;
                  //acMonitorWsjtxExecute(nil)
                end
  end;

  ClearAll;
  lblCall.Font.Color    := clRed;
  edtCall.Enabled       := False;
  cbOffline.Checked     := True;
  if run and FileExists(path) then
    dmUtils.RunOnBackgroud(path)
end;

procedure TfrmNewQSO.DisableRemoteMode;
begin
  tmrFldigi.Enabled         := False;
  tmrWsjtx.Enabled          := False;
  mnuRemoteMode.Checked     := False;
  mnuRemoteModeWsjt.Checked := False;
  lblCall.Caption           := 'Call:';
  lblCall.Font.Color        := clDefault;
  edtCall.Enabled           := True;
  cbOffline.Checked         := False;
  edtCall.SetFocus;

  if Assigned(WsjtxSock) then
  begin
    FreeAndNil(WsjtxSock)
  end
end;

procedure TfrmNewQSO.onExcept(Sender: TObject; E: Exception);
begin
  with TfrmException.Create(self) do
  try
    memErrorMessage.Lines.Add('Error in ' + E.UnitName);
    memErrorMessage.Lines.Add(E.Message);
    ShowModal
  finally
    Free
  end
end;

procedure TfrmNewQSO.DisplayCoordinates(latitude, Longitude : Currency);
var
  lat,long : String;
begin
  dmUtils.GetShorterCoordinates(latitude,longitude,lat,long);

  lblLat.Caption  := lat;
  lblLong.Caption := long
end;

procedure TfrmNewQSO.DrawGrayLine;
begin
  frmGrayline.s   := lblLat.Caption;
  frmGrayline.d   := lblLong.Caption;
  frmGrayline.pfx := lblDXCC.Caption;
  frmGrayline.kresli
end;

initialization
  {$I fNewQSO.lrs}
  
end.

