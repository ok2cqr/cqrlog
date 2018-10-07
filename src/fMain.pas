(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, Menus,
  ActnList, ExtCtrls, StdCtrls, ComCtrls, DBGrids, Buttons, LCLType, IniFiles, process,
  Grids, DBCtrls, dLogUpload;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    acNewQSO:    TAction;
    acEditQSO:   TAction;
    acDeleteQSO: TAction;
    acCreateFilter: TAction;
    acCancelFilter: TAction;

    acClose:    TAction;
    acPreferences: TAction;
    acSort:     TAction;
    acQSL_S:    TAction;
    acQSL_R:    TAction;
    acImportADIF: TAction;
    acGrayline: TAction;
    acCallBook: TAction;
    acAbout:    TAction;
    acSearch:   TAction;
    acRegenDXCCStat: TAction;
    acExADIF:   TAction;
    acExHTML:   TAction;
    acDXCluster: TAction;
    acShowToolBar: TAction;
    acButtons:  TAction;
    acRefresh:  TAction;
    acQSLMgr:   TAction;
    acDatabaseUpdate: TAction;
    acLabelsExport: TAction;
    acMarkQSL:  TAction;
    acDXCCCfm:  TAction;
    acITUCfm:   TAction;
    acImportLoTWADIF: TAction;
    acDownloadDataFromLoTW: TAction;
    acExportToLocalFile: TAction;
    acGroupEdit: TAction;
    acSelRecord: TAction;
    acSelAll:   TAction;
    acCustomStat: TAction;
    acImpQslMgrs: TAction;
    acAddQSLMgrs: TAction;
    acPnlDetails: TAction;
    acSQL: TAction;
    acAttach: TAction;
    acEditDetails: TAction;
    acQSLImage: TAction;
    acQRZ: TAction;
    acRebuildMembStat: TAction;
    acBigSquares: TAction;
    acHamQTH : TAction;
    aceQSLUp : TAction;
    aceQSLDwn : TAction;
    acSOTAExport : TAction;
    acRemoveDupes: TAction;
    acMarkAllClubLog: TAction;
    acMarkAllHrdLog: TAction;
    acMarkAll: TAction;
    acMarkAlleQSL: TAction;
    acUploadAllToLoTW: TAction;
    acUploadToAll: TAction;
    acUploadToHrdLog: TAction;
    acUploadToClubLog: TAction;
    acUploadToHamQTH: TAction;
    acMarkAllHamQTH: TAction;
    acWASCfm:   TAction;
    acWACCfm:   TAction;
    acUnselAll: TAction;
    acUnselRecord: TAction;
    acUploadQSOToLoTWWeb: TAction;
    acWAZCfm:   TAction;
    acTRXControl: TAction;
    acView:     TAction;
    ActionList1: TActionList;
    btnNewQSO:  TBitBtn;
    btnViewQSO:    TBitBtn;
    btnClose:    TBitBtn;
    btnDeleteQSO:    TBitBtn;
    BitBtn5:    TBitBtn;
    btnSort:    TBitBtn;
    dbgrdMain:  TDBGrid;
    dbtComment: TDBText;
    dbtAward:   TDBText;
    dbtQSLRDate: TDBText;
    dbtLoTWQSLR: TDBText;
    dbtQSLSDate: TDBText;
    dbtLoTWQSLS: TDBText;
    Image1:     TImage;
    imgMain:    TImageList;
    imgMain1:   TImageList;
    lblQSOInLog:     TLabel;
    lblDXCCWorked:     TLabel;
    lblCommentForQSO:    TLabel;
    lblAward:    TLabel;
    lblQSLSDate:    TLabel;
    lblQSLRDate:    TLabel;
    lblLoTWQSLSDate: TLabel;
    lblLoTWQSLRDate: TLabel;
    lblDXCCConfirmed:     TLabel;
    lblDXCCCmf: TLabel;
    lblDXCC:    TLabel;
    lblQSOCount: TLabel;
    MenuItem1:  TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem100: TMenuItem;
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
    MenuItem32: TMenuItem;
    MenuItem33: TMenuItem;
    MenuItem34: TMenuItem;
    MenuItem35: TMenuItem;
    MenuItem36: TMenuItem;
    MenuItem37: TMenuItem;
    MenuItem38: TMenuItem;
    MenuItem40: TMenuItem;
    MenuItem41: TMenuItem;
    MenuItem42: TMenuItem;
    MenuItem43: TMenuItem;
    MenuItem44: TMenuItem;
    MenuItem45: TMenuItem;
    MenuItem46: TMenuItem;
    MenuItem47 : TMenuItem;
    MenuItem48 : TMenuItem;
    MenuItem49: TMenuItem;
    MenuItem50: TMenuItem;
    MenuItem51: TMenuItem;
    MenuItem52: TMenuItem;
    MenuItem53: TMenuItem;
    MenuItem54: TMenuItem;
    MenuItem68: TMenuItem;
    MenuItem69: TMenuItem;
    MenuItem70: TMenuItem;
    MenuItem73: TMenuItem;
    MenuItem74: TMenuItem;
    MenuItem75: TMenuItem;
    MenuItem94: TMenuItem;
    MenuItem95: TMenuItem;
    MenuItem96: TMenuItem;
    MenuItem97: TMenuItem;
    MenuItem98: TMenuItem;
    MenuItem99: TMenuItem;
    mnuOQRS : TMenuItem;
    MenuItem55: TMenuItem;
    MenuItem56: TMenuItem;
    MenuItem57: TMenuItem;
    MenuItem58: TMenuItem;
    MenuItem59: TMenuItem;
    MenuItem60: TMenuItem;
    MenuItem61: TMenuItem;
    MenuItem62: TMenuItem;
    MenuItem63: TMenuItem;
    MenuItem64: TMenuItem;
    MenuItem65: TMenuItem;
    MenuItem66: TMenuItem;
    MenuItem67: TMenuItem;
    MenuItem71: TMenuItem;
    MenuItem72: TMenuItem;
    MenuItem76: TMenuItem;
    MenuItem77: TMenuItem;
    MenuItem78: TMenuItem;
    MenuItem79: TMenuItem;
    MenuItem80: TMenuItem;
    MenuItem81: TMenuItem;
    MenuItem82: TMenuItem;
    MenuItem83: TMenuItem;
    MenuItem84: TMenuItem;
    MenuItem85: TMenuItem;
    MenuItem86: TMenuItem;
    MenuItem87: TMenuItem;
    MenuItem88 : TMenuItem;
    MenuItem89 : TMenuItem;
    MenuItem90 : TMenuItem;
    MenuItem91 : TMenuItem;
    MenuItem92 : TMenuItem;
    MenuItem93 : TMenuItem;
    mnuIK3AQR:  TMenuItem;
    mnuQRZ:     TMenuItem;
    mnuHelpIndex: TMenuItem;
    mnuWAZStat: TMenuItem;
    mnuITUStat: TMenuItem;
    MenuItem39: TMenuItem;
    mnuIOTAStat: TMenuItem;
    mnuShowButtons: TMenuItem;
    mnuShowToolBar: TMenuItem;
    mnuAbout:   TMenuItem;
    mnuHelp:    TMenuItem;
    mnuCallBook: TMenuItem;
    mnuSCE:     TMenuItem;
    mnuSMB:     TMenuItem;
    mnuSMD:     TMenuItem;
    mnuSM:      TMenuItem;
    mnuSE:      TMenuItem;
    mnuSB:      TMenuItem;
    mnuSD:      TMenuItem;
    mnuMB:      TMenuItem;
    mnuCE:      TMenuItem;
    mnuManagerDirect: TMenuItem;
    mnuDoNotSend: TMenuItem;
    mnuManager: TMenuItem;
    mnuEQSL:    TMenuItem;
    mnuBuro:    TMenuItem;
    mnuDirect:  TMenuItem;
    mnuDXCCData: TMenuItem;
    mnuQSL_R:   TMenuItem;
    mnuQSL_S:   TMenuItem;
    mnuQSL:     TMenuItem;
    MenuItem3:  TMenuItem;
    MenuItem4:  TMenuItem;
    MenuItem5:  TMenuItem;
    MenuItem6:  TMenuItem;
    MenuItem7:  TMenuItem;
    MenuItem8:  TMenuItem;
    MenuItem9:  TMenuItem;
    mnuMain:    TMainMenu;
    mnuClose:   TMenuItem;
    MenuItem2:  TMenuItem;
    mnuCreateFilter: TMenuItem;
    mnuCancelFilter: TMenuItem;
    mnuFile:    TMenuItem;
    dlgOpen:    TOpenDialog;
    Panel1:     TPanel;
    Panel3: TPanel;
    pnlDetails: TPanel;
    pnlButtons: TPanel;
    Panel2:     TPanel;
    dlgSave:    TSaveDialog;
    popWebSearch: TPopupMenu;
    sbMain:     TStatusBar;
    Timer1:     TTimer;
    tmrTime:    TTimer;
    tmrUploadAll: TTimer;
    ToolButton18: TToolButton;
    ToolButton19: TToolButton;
    ToolButton20: TToolButton;
    ToolButton21: TToolButton;
    ToolButton22: TToolButton;
    ToolButton23: TToolButton;
    ToolButton24: TToolButton;
    ToolButton25: TToolButton;
    ToolButton26: TToolButton;
    ToolButton27: TToolButton;
    ToolButton28: TToolButton;
    ToolButton29: TToolButton;
    ToolButton30: TToolButton;
    ToolButton31: TToolButton;
    ToolButton32: TToolButton;
    ToolButton33 : TToolButton;
    ToolButton34 : TToolButton;
    ToolButton35 : TToolButton;
    ToolButton36 : TToolButton;
    toolMain:   TToolBar;
    ToolButton1: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton13: TToolButton;
    ToolButton14: TToolButton;
    ToolButton15: TToolButton;
    ToolButton16: TToolButton;
    ToolButton17: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    procedure acAttachExecute(Sender: TObject);
    procedure acBigSquaresExecute(Sender: TObject);
    procedure acEditDetailsExecute(Sender: TObject);
    procedure aceQSLDwnExecute(Sender : TObject);
    procedure aceQSLUpExecute(Sender : TObject);
    procedure acHamQTHExecute(Sender : TObject);
    procedure acMarkAllClubLogExecute(Sender: TObject);
    procedure acMarkAlleQSLExecute(Sender: TObject);
    procedure acMarkAllExecute(Sender: TObject);
    procedure acMarkAllHamQTHExecute(Sender: TObject);
    procedure acMarkAllHrdLogExecute(Sender: TObject);
    procedure acPnlDetailsExecute(Sender: TObject);
    procedure acQRZExecute(Sender: TObject);
    procedure acQSLImageExecute(Sender: TObject);
    procedure acRebuildMembStatExecute(Sender: TObject);
    procedure acRemoveDupesExecute(Sender: TObject);
    procedure acSOTAExportExecute(Sender : TObject);
    procedure acSQLExecute(Sender: TObject);
    procedure acUploadAllToLoTWExecute(Sender: TObject);
    procedure acUploadToAllExecute(Sender: TObject);
    procedure acUploadToClubLogExecute(Sender: TObject);
    procedure acUploadToHamQTHExecute(Sender: TObject);
    procedure acUploadToHrdLogExecute(Sender: TObject);
    procedure dbgrdMainColumnMoved(Sender: TObject; FromIndex, ToIndex: Integer
      );
    procedure dbgrdMainColumnSized(Sender: TObject);
    procedure dbgrdMainDrawColumnCell(Sender : TObject; const Rect : TRect;
      DataCol : Integer; Column : TColumn; State : TGridDrawState);
    procedure dbgrdMainEnter(Sender: TObject);
    procedure dbgrdMainKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure acAddQSLMgrsExecute(Sender: TObject);
    procedure acCustomStatExecute(Sender: TObject);
    procedure acDXCCCfmExecute(Sender: TObject);
    procedure acDatabaseUpdateExecute(Sender: TObject);
    procedure acDownloadDataFromLoTWExecute(Sender: TObject);
    procedure acExportToLocalFileExecute(Sender: TObject);
    procedure acGroupEditExecute(Sender: TObject);
    procedure acITUCfmExecute(Sender: TObject);
    procedure acITULoTWCfmExecute(Sender: TObject);
    procedure acITULoTWExecute(Sender: TObject);
    procedure acImpQslMgrsExecute(Sender: TObject);
    procedure acImportLoTWADIFExecute(Sender: TObject);
    procedure acLabelsExportExecute(Sender: TObject);
    procedure acMarkQSLExecute(Sender: TObject);
    procedure acSelAllExecute(Sender: TObject);
    procedure acSelRecordExecute(Sender: TObject);
    procedure acUnselAllExecute(Sender: TObject);
    procedure acUnselRecordExecute(Sender: TObject);
    procedure acUploadQSOToLoTWWebExecute(Sender: TObject);
    procedure acWACCfmExecute(Sender: TObject);
    procedure acWASCfmExecute(Sender: TObject);
    procedure acWAZCfmExecute(Sender: TObject);
    procedure mnuIK3AQRClick(Sender: TObject);
    procedure mnuHelpIndexClick(Sender: TObject);
    procedure mnuIOTAStatClick(Sender: TObject);
    procedure acButtonsExecute(Sender: TObject);
    procedure acQSLMgrExecute(Sender: TObject);
    procedure acRefreshExecute(Sender: TObject);
    procedure acShowToolBarExecute(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure mnuOQRSClick(Sender : TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure acAboutExecute(Sender: TObject);
    procedure acCallBookExecute(Sender: TObject);
    procedure acCancelFilterExecute(Sender: TObject);
    procedure acCloseExecute(Sender: TObject);
    procedure acCreateFilterExecute(Sender: TObject);
    procedure acDXClusterExecute(Sender: TObject);
    procedure acExADIFExecute(Sender: TObject);
    procedure acExHTMLExecute(Sender: TObject);
    procedure acGraylineExecute(Sender: TObject);
    procedure acImportADIFExecute(Sender: TObject);
    procedure acQSL_RExecute(Sender: TObject);
    procedure acQSL_SExecute(Sender: TObject);
    procedure acRegenDXCCStatExecute(Sender: TObject);
    procedure acSearchExecute(Sender: TObject);
    procedure acSortExecute(Sender: TObject);
    procedure acTRXControlExecute(Sender: TObject);
    procedure acViewExecute(Sender: TObject);
    procedure acDeleteQSOExecute(Sender: TObject);
    procedure acEditQSOExecute(Sender: TObject);
    procedure acNewQSOExecute(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure acPreferencesExecute(Sender: TObject);
    procedure dbgrdMainCellClick(Column: TColumn);
    procedure lblQSOCountClick(Sender: TObject);
    procedure mnuCEClick(Sender: TObject);
    procedure mnuDXCCDataClick(Sender: TObject);
    procedure mnuDirectClick(Sender: TObject);
    procedure mnuDoNotSendClick(Sender: TObject);
    procedure mnuEQSLClick(Sender: TObject);
    procedure mnuMBClick(Sender: TObject);
    procedure mnuManagerClick(Sender: TObject);
    procedure mnuManagerDirectClick(Sender: TObject);
    procedure mnuSBClick(Sender: TObject);
    procedure mnuSCEClick(Sender: TObject);
    procedure mnuSDClick(Sender: TObject);
    procedure mnuSEClick(Sender: TObject);
    procedure mnuSMBClick(Sender: TObject);
    procedure mnuSMClick(Sender: TObject);
    procedure mnuSMDClick(Sender: TObject);
    procedure pnlButtonsClick(Sender: TObject);
    procedure tmrTimeTimer(Sender: TObject);
    procedure tmrUploadAllTimer(Sender: TObject);
  private
    InRefresh  : Boolean;
    WhatUpNext : TWhereToUpload;

    procedure ChechkSelRecords;
    { private declarations }
  public
    procedure RefreshQSODXCCCount;
    procedure MarkQSLSend(symbol: string);
    procedure ShowFields;
    procedure ReloadGrid;
    procedure CheckAttachment;

    { public declarations }
  end;

var
  frmMain: TfrmMain;

implementation
{$R *.lfm}

{ TfrmMain }
uses fNewQSO, fPreferences, dUtils, dData, dDXCC, dDXCluster, fMarkQSL, fDXCCStat,
  fSort, fFilter, fImportProgress, fGrayline, fCallbook, fTRXControl,
  fAdifImport, fSplash, fSearch, fExportProgress, fDXCluster, fQSLMgr,
  fQSODetails, fWAZITUStat, fIOTAStat, fDatabaseUpdate, fExLabelPrint,
  fImportLoTWWeb, fLoTWExport, fGroupEdit, fCustomStat, fSQLConsole, fCallAttachment,
  fEditDetails, fQSLViewer, uMyIni, fRebuildMembStat, fAbout, fBigSquareStat,
  feQSLUpload, feQSLDownload, fSOTAExport, fRotControl, fLogUploadStatus, fExportPref;

procedure TfrmMain.ReloadGrid;
begin
  ShowFields;
  RefreshQSODXCCCount
end;

procedure TfrmMain.RefreshQSODXCCCount;
begin
  lblQSOCount.Caption := IntToStr(dmData.GetQSOCount);
  lblDXCC.Caption     := IntToStr(dmDXCC.DXCCCount);
  lblDXCCCmf.Caption  := IntToStr(dmDXCC.DXCCCmfCount)
end;

procedure TfrmMain.acPreferencesExecute(Sender: TObject);
begin
  cqrini.WriteInteger('Pref', 'ActPageIdx', 3);  //set visible colums tab active. Number may change if preferences page change
  with TfrmPreferences.Create(self) do
  try
    ShowModal;
    if ModalResult = mrOk then
    begin
      ShowFields;
      if frmNewQSO.Showing then
        dmUtils.LoadFontSettings(frmNewQSO);
      dmUtils.LoadFontSettings(frmMain);
      if frmTRXControl.Showing then
        dmUtils.LoadFontSettings(frmTRXControl);
      if frmRotControl.Showing then
        dmUtils.LoadFontSettings(frmRotControl);
      if frmQSODetails.Showing then
        frmQSODetails.LoadFonts;

      dmData.LoadQSODateColorSettings
    end
  finally
    Free
  end
end;

procedure TfrmMain.dbgrdMainCellClick(Column: TColumn);
begin
  ChechkSelRecords;
  CheckAttachment
end;

procedure TfrmMain.lblQSOCountClick(Sender: TObject);
begin
  if dmData.DebugLevel >= 1 then
    ShowMessage(IntToStr(dbgrdMain.SelectedRows.Count));
end;

procedure TfrmMain.mnuCEClick(Sender: TObject);
begin
  MarkQSLSend('CE');
end;

procedure TfrmMain.mnuDXCCDataClick(Sender: TObject);
begin
  dlgOpen.Filter     := 'dxcc tables|*.tbl';
  dlgOpen.DefaultExt := '.tbl';
  if dlgOpen.Execute then
  begin
    with TfrmImportProgress.Create(self) do
    try
      lblComment.Caption := 'Importing DXCC data ...';
      Directory  := ExtractFilePath(dlgOpen.FileName);
      ImportType := imptImportDXCCTables;
      ShowModal
    finally
      Free
    end;
    dmDXCC.ReloadDXCCTables;
    dmDXCluster.ReloadDXCCTables
  end
  else
    BringToFront
end;

procedure TfrmMain.mnuDirectClick(Sender: TObject);
begin
  MarkQSLSend('D');
end;

procedure TfrmMain.mnuDoNotSendClick(Sender: TObject);
begin
  MarkQSLSend('N');
end;

procedure TfrmMain.mnuEQSLClick(Sender: TObject);
begin
  MarkQSLSend('E');
end;

procedure TfrmMain.mnuMBClick(Sender: TObject);
begin
  MarkQSLSend('MB');
end;

procedure TfrmMain.mnuManagerClick(Sender: TObject);
begin
  MarkQSLSend('M');
end;

procedure TfrmMain.mnuManagerDirectClick(Sender: TObject);
begin
  MarkQSLSend('MD');
end;

procedure TfrmMain.mnuSBClick(Sender: TObject);
begin
  MarkQSLSend('SB');
end;

procedure TfrmMain.mnuSCEClick(Sender: TObject);
begin
  MarkQSLSend('SCE');
end;

procedure TfrmMain.mnuSDClick(Sender: TObject);
begin
  MarkQSLSend('SD');
end;

procedure TfrmMain.mnuSEClick(Sender: TObject);
begin
  MarkQSLSend('SE');
end;

procedure TfrmMain.mnuSMBClick(Sender: TObject);
begin
  MarkQSLSend('SMB');
end;

procedure TfrmMain.mnuSMClick(Sender: TObject);
begin
  MarkQSLSend('SM');
end;

procedure TfrmMain.mnuSMDClick(Sender: TObject);
begin
  MarkQSLSend('SMD');
end;

procedure TfrmMain.pnlButtonsClick(Sender: TObject);
begin
  Writeln(dbgrdMain.SelectedRows.Count);
end;

procedure TfrmMain.tmrTimeTimer(Sender: TObject);
var
  sDate, tmp: string;
begin
  tmp   := '';
  sDate := '';
  dmUtils.DateInRightFormat(now, tmp, sDate);
  sbMain.Panels[0].Text := sDate;
end;

procedure TfrmMain.tmrUploadAllTimer(Sender: TObject);
begin
  if (not frmLogUploadStatus.thRunning) then
  begin
    case WhatUpNext of
      upHamQTH :  begin
                    frmLogUploadStatus.UploadDataToHamQTH;
                    WhatUpNext := upClubLog
                  end;
      upClubLog : begin
                    frmLogUploadStatus.UploadDataToClubLog;
                    WhatUpNext := upHrdLog
                  end;
      upHrdLog  : begin
                    frmLogUploadStatus.UploadDataToHrdLog;
                    tmrUploadAll.Enabled := False
                  end;
    end //case
  end
end;

procedure TfrmMain.acNewQSOExecute(Sender: TObject);
begin
  frmNewQSO.Caption := dmUtils.GetNewQSOCaption('New QSO');
  frmNewQSO.UnsetEditLabel;
  frmNewQSO.BringToFront;
  frmNewQSO.ClearAll;
end;

procedure TfrmMain.acEditQSOExecute(Sender: TObject);
begin
  if dmData.qCQRLOG.RecordCount > 0 then
  begin
    if (frmNewQSO.mnuRemoteMode.Checked) or (frmNewQSO.mnuRemoteModeWsjt.Checked) then
    begin
      Application.MessageBox('Log is in remote mode, please disable it.','Info ...',mb_ok + mb_IconInformation);
      exit
    end;
    if dbgrdMain.SelectedRows.Count < 2 then
    begin
      frmNewQSO.Caption := dmUtils.GetNewQSOCaption('Edit QSO');
      frmNewQSO.ClearAll;
      frmNewQSO.EditQSO := True;
      frmNewQSO.ShowWin := True;
      frmNewQSO.BringToFront;
      frmNewQSO.ViewQSO := False;
      frmNewQSO.SetEditLabel;
      frmNewQSO.ShowQSO;
    end
    else
      acGroupEdit.Execute;
  end;
end;

procedure TfrmMain.acDeleteQSOExecute(Sender: TObject);
var
  id:    integer;
  i:     integer;

  procedure DeleteRec(idx: longint);
  begin
    if dmData.trQ.Active then
      dmData.trQ.RollBack;
    dmData.Q.SQL.Text := 'DELETE FROM cqrlog_main WHERE id_cqrlog_main = ' + IntToStr(idx);
    WriteLn(dmData.Q.SQL.Text);
    dmData.trQ.StartTransaction;
    dmData.Q.ExecSQL;
    dmData.trQ.Commit
  end;

begin
  if dmData.qCQRLOG.RecordCount > 0 then
  begin
    if dbgrdMain.SelectedRows.Count < 1 then
    begin
      if Application.MessageBox('Do you really want to delete this QSO?',
        'Question ...', MB_ICONQUESTION + MB_YESNO) = idNo then
        exit;
      dmData.qCQRLOG.DisableControls;
      try
        id := dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger;
        dmData.qCQRLOG.Next;
        if id = dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger then
        begin
          dmData.qCQRLOG.Prior;
          id := dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger;
          dmData.qCQRLOG.Next;
        end else
        begin
          id := dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger;
          dmData.qCQRLOG.Prior;
        end;
        DeleteRec(dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger);
      finally
        dmData.qCQRLOG.EnableControls
      end;
      frmNewQSO.UploadAllQSOOnline;
      dmData.RefreshMainDatabase(id)
    end
    else
    begin
      if Application.MessageBox('Do you really want to delete selected QSOs?',
        'Question ...', MB_ICONQUESTION + MB_YESNO) = idNo then
        exit;
      dmData.qCQRLOG.DisableControls;
      try
        for i := 0 to dbgrdMain.SelectedRows.Count - 1 do
        begin
          dmData.qCQRLOG.GotoBookmark(Pointer(dbgrdMain.SelectedRows.Items[i]));
          DeleteRec(dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger)
        end;
        acUnselAll.Execute
      finally
        dmData.qCQRLOG.EnableControls
      end;
      dmData.RefreshMainDatabase()
    end;
    ReloadGrid
  end
end;

procedure TfrmMain.acViewExecute(Sender: TObject);
begin
  if dmData.qCQRLOG.RecordCount = 0 then
    exit;
  if (frmNewQSO.mnuRemoteMode.Checked) or (frmNewQSO.mnuRemoteModeWsjt.Checked) then
  begin
      Application.MessageBox('Log is in remote mode, please disable it.','Info ...',mb_ok + mb_IconInformation);
    exit
  end;
  frmNewQSO.ClearAll;
  frmNewQSO.ViewQSO := True;
  frmNewQSO.Caption := dmUtils.GetNewQSOCaption('View QSO');
  frmNewQSO.ShowWin := True;
  frmNewQSO.BringToFront;
  frmNewQSO.EditQSO := False;
  frmNewQSO.ShowQSO;
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if key = VK_F2 then  //why hotkeys doesn't work?
    acNewQSO.Execute;
  if key = VK_F6 then
    acCallBook.Execute;
  if (Shift = [ssAlt]) and (key = VK_F) then
  begin
    dmUtils.EnterFreq;
    key := 0;
  end;
  if (Shift = [ssCTRL]) and (Key = VK_N) then
  begin
    mnuDoNotSendClick(nil);
    key := 0
  end
end;

procedure TfrmMain.mnuOQRSClick(Sender : TObject);
begin
  MarkQSLSend('OQRS')
end;

procedure TfrmMain.Timer1Timer(Sender: TObject);
var
  sDate: string;
  Date:  TDateTime;
  tmp:   string;
begin
  tmp   := '';
  sDate := '';
  Date  := dmUtils.GetDateTime(0);
  dmUtils.DateInRightFormat(date, tmp, sDate);
  sbMain.Panels[4].Text := sDate + '  ' + TimeToStr(Date)
end;

procedure TfrmMain.acAboutExecute(Sender: TObject);
begin
  with TfrmAbout.Create(Application) do
  try
    ShowModal
  finally
    Free
  end
end;

procedure TfrmMain.acCallBookExecute(Sender: TObject);
begin
  frmCallbook.edtCall.Text := dmData.qCQRLOG.FieldByName('callsign').AsString;
  frmCallbook.ShowModal
end;

procedure TfrmMain.FormActivate(Sender: TObject);
begin
  dbgrdMain.SetFocus;
end;

procedure TfrmMain.acShowToolBarExecute(Sender: TObject);
begin
  if toolMain.Visible then
  begin
    toolMain.Visible := False;
    mnuShowToolBar.Checked := False;
  end
  else
  begin
    toolMain.Visible := True;
    mnuShowToolBar.Checked := True;
  end;
end;

procedure TfrmMain.acButtonsExecute(Sender: TObject);
begin
  if pnlButtons.Visible then
  begin
    pnlButtons.Visible     := False;
    mnuShowButtons.Checked := False;
  end
  else
  begin
    pnlButtons.Visible     := True;
    mnuShowButtons.Checked := True;
  end;
end;

procedure TfrmMain.acQSLMgrExecute(Sender: TObject);
begin
  frmQSLMgr := TfrmQSLMgr.Create(self);
  try
    dmData.qQSLMgr.Close;
    dmData.qQSLMgr.SQL.Text := 'select callsign,qsl_via,fromdate from cqrlog_common.qslmgr order by callsign,fromDate';
    if dmData.trQSLMgr.Active then
      dmData.trQSLMgr.Rollback;
    dmData.trQSLMgr.StartTransaction;
    dmData.qQSLMgr.Open;
    frmQSLMgr.btnApply.Caption := 'OK';
    frmQSLMgr.ShowModal;
  finally
    dmData.qQSLMgr.Close;
    if dmData.trQSLMgr.Active then dmData.trQSLMgr.Rollback;
    frmQSLMgr.Free
  end;
end;

procedure TfrmMain.acRefreshExecute(Sender: TObject);
var
  idx: integer;
begin
  if InRefresh then
    exit;
  try
    InRefresh := True;
    //if user push refresh data very quickly again and again, program may crash
    idx := dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger;
    dmData.qCQRLOG.Close;
    dmData.RefreshMainDatabase(idx);
    RefreshQSODXCCCount
  finally
    InRefresh := False
  end
end;

procedure TfrmMain.acDXCCCfmExecute(Sender: TObject);
begin
  with TfrmDXCCStat.Create(self) do
  try
    ShowModal
  finally
    Free
  end
end;

procedure TfrmMain.acDatabaseUpdateExecute(Sender: TObject);
var
  lastid: integer;
  prenames : Boolean = False;
begin
  if Application.MessageBox('Do you really want to run database update?',
    'Question ...', mb_YesNo + mb_IconQuestion) = idNo then
    exit;
  lastid := cqrini.ReadInteger('CallBook', 'LastId', -1);
  if lastid > -1 then
  begin
    if Application.MessageBox(
      'It looks like last update were canceled. Do you want to continue from last position?',
      'Question ...', mb_YesNo + mb_IconQuestion) = idNo then
      lastid := dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger;
    cqrini.WriteInteger('CallBook', 'LastId', -1)
  end
  else
    lastid := dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger;

  if Application.MessageBox('Update names from previous QSOs?','Question ...',mb_YesNo + mb_IconQuestion) = idYes then
    prenames := True;

  frmDatabaseUpdate := TfrmDatabaseUpdate.Create(self);
  try
    frmDatabaseUpdate.id_cqrlog_main   := lastid;
    frmDatabaseUpdate.NameFromLog := prenames;
    dmData.QCallBook.SQL.Clear;
    dmData.QCallBook.SQL.Text     := dmData.qCQRLOG.SQL.Text;
    frmDatabaseUpdate.ShowModal
  finally
    frmDatabaseUpdate.Free
  end
end;

procedure TfrmMain.acDownloadDataFromLoTWExecute(Sender: TObject);
begin
  with TfrmImportLoTWWeb.Create(self) do
  try
    ShowModal
  finally
    Free;
    acRefreshExecute(nil)
  end
end;

procedure TfrmMain.acExportToLocalFileExecute(Sender: TObject);
begin
  with TfrmLoTWExport.Create(self) do
  try
    pgLoTWExport.ActivePage := tabLocalFile;
    ShowModal
  finally
    Free;
    acRefreshExecute(nil)
  end
end;

procedure TfrmMain.acGroupEditExecute(Sender: TObject);
begin
  with TfrmGroupEdit.Create(self) do
  try
    Selected := dbgrdMain.SelectedRows.Count > 1;
    ShowModal
  finally
    Free
  end
end;

procedure TfrmMain.acITUCfmExecute(Sender: TObject);
begin
  with TfrmWAZITUStat.Create(self) do
  try
    StatType := tsITU;
    ShowModal
  finally
    Free
  end
end;

procedure TfrmMain.acITULoTWCfmExecute(Sender: TObject);
begin
  with TfrmWAZITUStat.Create(self) do
  try
    StatType := tsITU;
    ShowModal
  finally
    Free
  end
end;

procedure TfrmMain.acITULoTWExecute(Sender: TObject);
begin
  with TfrmWAZITUStat.Create(self) do
  try
    StatType := tsITU;
    ShowModal
  finally
    Free
  end
end;

procedure TfrmMain.acImpQslMgrsExecute(Sender: TObject);
begin
  dlgOpen.Filter     := 'QSL manages|*.csv';
  dlgOpen.DefaultExt := '.csv';
  if dlgOpen.Execute then
  begin
    with TfrmImportProgress.Create(self) do
    try
      lblComment.Caption := 'Importing QSL mangers ...';
      Directory  := ExtractFilePath(dlgOpen.FileName);
      FileName   := dlgOpen.FileName;
      ImportType := imptImportQSLMgrs;
      ShowModal
    finally
      Free
    end
  end
  else
    BringToFront
end;

procedure TfrmMain.acImportLoTWADIFExecute(Sender: TObject);
begin
  if dlgOpen.Execute then
  begin
    with TfrmImportProgress.Create(self) do
    try
      FileName   := dlgOpen.FileName;
      ImportType := imptImportLoTWAdif;
      ShowModal
    finally
      Free;
      acRefreshExecute(nil)
    end
  end
end;

procedure TfrmMain.acLabelsExportExecute(Sender: TObject);
var
  msg : String;
begin
  if not dmData.IsFilter then
  begin
    msg := 'You do not have filter activated!' + LineEnding+
           'This could cause that you won''t have more callsigns on one label and ' +
           'only last 500 QSO will be printed.'+LineEnding+LineEnding+
           'Do you want to continue?';
    if Application.MessageBox(PChar(msg),'Warning ...',mb_YesNo + mb_IconWarning) = idNo then
      exit
  end;
  with TfrmExLabelPrint.Create(self) do
  try
    ShowModal
  finally
    Free
  end
end;

procedure TfrmMain.acMarkQSLExecute(Sender: TObject);
begin
  if dmData.IsFilter then
  begin
    if Pos('JOIN', UpperCase(dmData.qCQRLOG.SQL.Text)) > 0 then
    begin
      Application.MessageBox(
        'This option is supported only for filtered QSOs (without membership)!',
        'Information ...', mb_ok + mb_IconInformation);
      exit
    end
  end;
  with TfrmMarkQSL.Create(self) do
  try
    ShowModal
  finally
    Free;
    acRefresh.Execute
  end
end;

procedure TfrmMain.acSelAllExecute(Sender: TObject);
begin
  if application.MessageBox('Do you really want to select all records?',
    'Question ...', mb_ok + mb_YesNo) = idNo then
    exit;
  try
    dbgrdMain.SelectedRows.Clear;
    dbgrdMain.DataSource.Dataset.DisableControls;
    dmData.qCQRLOG.First;
    while not dbgrdMain.DataSource.DataSet.EOF do
    begin
      dbgrdMain.SelectedRows.CurrentRowSelected := True;
      dbgrdMain.DataSource.DataSet.Next
    end
  finally
    dbgrdMain.DataSource.Dataset.EnableControls;
    ChechkSelRecords
  end
end;

procedure TfrmMain.acSelRecordExecute(Sender: TObject);
begin
  dbgrdMain.SelectedRows.CurrentRowSelected := True;
  ChechkSelRecords
end;

procedure TfrmMain.acUnselAllExecute(Sender: TObject);
begin
  dbgrdMain.SelectedRows.Clear;
  ChechkSelRecords
end;

procedure TfrmMain.acUnselRecordExecute(Sender: TObject);
begin
  if dbgrdMain.SelectedRows.CurrentRowSelected then
    dbgrdMain.SelectedRows.CurrentRowSelected := False;
  ChechkSelRecords;
end;

procedure TfrmMain.acUploadQSOToLoTWWebExecute(Sender: TObject);
begin
  with TfrmLoTWExport.Create(self) do
  try
    pgLoTWExport.ActivePage := tabUpload;
    ShowModal
  finally
    Free;
    acRefreshExecute(nil)
  end
end;

procedure TfrmMain.acWACCfmExecute(Sender: TObject);
begin
  with TfrmWAZITUStat.Create(self) do
  try
    StatType := tsWAC;
    ShowModal
  finally
    Free
  end
end;


procedure TfrmMain.acWASCfmExecute(Sender: TObject);
begin
  with TfrmWAZITUStat.Create(self) do
  try
    StatType := tsWAS;
    ShowModal
  finally
    Free
  end
end;


procedure TfrmMain.acWAZCfmExecute(Sender: TObject);
begin
  with TfrmWAZITUStat.Create(self) do
  try
    StatType := tsWAZ;
    ShowModal
  finally
    Free
  end
end;

procedure TfrmMain.mnuIK3AQRClick(Sender: TObject);
var
  AProcess: TProcess;
begin
  AProcess := TProcess.Create(nil);
  try
    AProcess.CommandLine := cqrini.ReadString('Program', 'WebBrowser', 'firefox') +
      ' http://www.ik3qar.it/manager/man_result.php?call=' +
      dmData.qCQRLOG.Fields[4].AsString;
    Writeln('Command line: ', AProcess.CommandLine);
    AProcess.Execute
  finally
    AProcess.Free
  end
end;

procedure TfrmMain.mnuHelpIndexClick(Sender: TObject);
begin
  ShowHelp
end;

procedure TfrmMain.mnuIOTAStatClick(Sender: TObject);
begin
  with TfrmIOTAStat.Create(self) do
  try
    ShowModal
  finally
    Free
  end
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  minimalize    := False;
  MinDXCluster  := False;
  MinGrayLine   := False;
  MinTRXControl := False;
  MinNewQSO     := False;
  MinQSODetails := False;
  WhatUpNext    := upHamQTH
end;

procedure TfrmMain.acPnlDetailsExecute(Sender: TObject);
begin
  if pnlDetails.Visible then
  begin
    pnlDetails.Visible   := False;
    acPnlDetails.Checked := False;
  end
  else
  begin
    pnlDetails.Visible   := True;
    acPnlDetails.Checked := True;
  end;
end;

procedure TfrmMain.acQRZExecute(Sender: TObject);
begin
  dmUtils.ShowQRZInBrowser(dmData.qCQRLOG.Fields[4].AsString)
end;

procedure TfrmMain.acQSLImageExecute(Sender: TObject);
begin
  if not cqrini.ReadBool('ExtView','QSL',True) then
    dmUtils.ShowQSLWithExtViewer(dmData.qCQRLOG.Fields[4].AsString)
  else begin
    frmQSLViewer := TfrmQSLViewer.Create(self);
    try
      frmQSLViewer.Call := dmData.qCQRLOG.Fields[4].AsString;
      frmQSLViewer.ShowModal
    finally
      frmQSLViewer.Free
    end
  end
end;

procedure TfrmMain.acRebuildMembStatExecute(Sender: TObject);
begin
  frmRebuildMembStat := TfrmRebuildMembStat.Create(frmMain);
  try
    frmRebuildMembStat.ShowModal
  finally
    frmRebuildMembStat.Free
  end
end;

procedure TfrmMain.acRemoveDupesExecute(Sender: TObject);
begin
  if Application.MessageBox('PLEASE MAKE A BACKUP FIRST! THIS FUNCTION MAY DELETE QSO FROM YOUR LOG!'+LineEnding+LineEnding+
       'Do you really want to remove dupes from database?','Question ...',mb_YesNo+mb_IconQuestion) = idYes then
  begin
    if cqrini.ReadBool('OnlineLog','HaUP',False)  or cqrini.ReadBool('OnlineLog','ClUP',False) or cqrini.ReadBool('OnlineLog','HrUP',False) then
    begin
      if Application.MessageBox('It seems you are using online log upload. First, please go to Online log menu and click to  "Mark all QSO as uploaded to all logs".'+
                              LineEnding + LineEnding + 'Do you want to continue?','Question...', mb_YesNo+mb_IconQuestion) = idNo then
        exit
    end;
    with TfrmImportProgress.Create(self) do
    try
      ImportType := imptRemoveDupes;
      ShowModal
    finally
      Free
    end;
    acRefresh.Execute
  end
end;

procedure TfrmMain.acSOTAExportExecute(Sender : TObject);
begin
  frmSOTAExport := TfrmSOTAExport.Create(frmMain);
  try
    frmSOTAExport.ShowModal
  finally
    frmSOTAExport.Free
  end
end;

procedure TfrmMain.acAttachExecute(Sender: TObject);
begin
  frmCallAttachment := TfrmCallAttachment.Create(self);
  try
    frmCallAttachment.flAttach.Directory := dmUtils.GetCallAttachDir(dmData.qCQRLOG.Fields[4].AsString);
    frmCallAttachment.ShowModal
  finally
    frmCallAttachment.Free
  end
end;

procedure TfrmMain.acBigSquaresExecute(Sender: TObject);
begin
  frmBigSquareStat := TfrmBigSquareStat.Create(frmNewQSO);
  try
    frmBigSquareStat.ShowModal
  finally
    FreeAndNil(frmBigSquareStat)
  end
end;

procedure TfrmMain.acEditDetailsExecute(Sender: TObject);
begin
  frmEditDetails := TfrmEditDetails.Create(self);
  try
    frmEditDetails.ShowModal;
    if frmEditDetails.ModalResult = mrOK then
      acRefresh.Execute
  finally
    frmEditDetails.Free
  end
end;

procedure TfrmMain.aceQSLDwnExecute(Sender : TObject);
begin
  frmeQSLDownload := TfrmeQSLDownload.Create(nil);
  try
    frmeQSLDownload.ShowModal
  finally
    FreeAndNil(frmeQSLDownload);
    acRefresh.Execute
  end
end;

procedure TfrmMain.aceQSLUpExecute(Sender : TObject);
begin
  frmeQSLUpload := TfrmeQSLUpload.Create(frmMain);
  try
    frmeQSLUpload.ShowModal
  finally
    FreeAndNil(frmeQSLUpload);
    acRefresh.Execute
  end
end;

procedure TfrmMain.acHamQTHExecute(Sender : TObject);
begin
  dmUtils.ShowHamQTHInBrowser(dmData.qCQRLOG.Fields[4].AsString)
end;

procedure TfrmMain.acMarkAllClubLogExecute(Sender: TObject);
begin
  dmLogUpload.MarkAsUploaded(C_CLUBLOG)
end;

procedure TfrmMain.acMarkAlleQSLExecute(Sender: TObject);
begin
  if Application.MessageBox('Do you really want to mark all QSO as uploaded to eQSL?','Question ...',mb_YesNo + mb_IconQuestion) = idYes then
  begin
    dmData.MarkAllAsUploadedToeQSL;
    acRefresh.Execute
  end
end;

procedure TfrmMain.acMarkAllExecute(Sender: TObject);
begin
  dmLogUpload.MarkAsUploadedToAllOnlineLogs;
  Application.MessageBox('Done, now all QSO are marked as uploaded.','Info ...',mb_Ok + mb_IconInformation)
end;

procedure TfrmMain.acMarkAllHamQTHExecute(Sender: TObject);
begin
  dmLogUpload.MarkAsUploaded(C_HAMQTH)
end;

procedure TfrmMain.acMarkAllHrdLogExecute(Sender: TObject);
begin
  dmLogUpload.MarkAsUploaded(C_HRDLOG)
end;

procedure TfrmMain.acSQLExecute(Sender: TObject);
begin
  frmSQLConsole := TfrmSQLConsole.Create(self);
  try
    frmSQLConsole.ShowModal
  finally
    frmSQLConsole.Free
  end
end;

procedure TfrmMain.acUploadAllToLoTWExecute(Sender: TObject);
begin
  if Application.MessageBox('Do you really want to mark all QSO as uploaded to LoTW?','Question ...',mb_YesNo + mb_IconQuestion) = idYes then
  begin
    dmData.MarkAllAsUploadedToLoTW;
    acRefresh.Execute
  end
end;

procedure TfrmMain.acUploadToAllExecute(Sender: TObject);
begin
  frmNewQSO.acUploadToAll.Execute
end;

procedure TfrmMain.acUploadToClubLogExecute(Sender: TObject);
begin
  frmLogUploadStatus.UploadDataToClubLog
end;

procedure TfrmMain.acUploadToHamQTHExecute(Sender: TObject);
begin
  frmLogUploadStatus.UploadDataToHamQTH
end;

procedure TfrmMain.acUploadToHrdLogExecute(Sender: TObject);
begin
  frmLogUploadStatus.UploadDataToHrdLog
end;

procedure TfrmMain.dbgrdMainColumnMoved(Sender: TObject; FromIndex,
  ToIndex: Integer);
begin
  dmUtils.SaveForm(frmMain)
end;

procedure TfrmMain.dbgrdMainColumnSized(Sender: TObject);
begin
  dmUtils.SaveForm(frmMain)
end;

procedure TfrmMain.dbgrdMainDrawColumnCell(Sender : TObject;
  const Rect : TRect; DataCol : Integer; Column : TColumn;
  State : TGridDrawState);
begin
  if dmData.UseQSOColor then
  begin
    if dmData.qCQRLOG.FieldByName('qsodate').AsDateTime < dmData.QSOColorDate then
      dbgrdMain.Canvas.Font.Color := dmData.QSOColor
  end;

  dbgrdMain.DefaultDrawColumnCell(Rect,DataCol,Column,State)
end;

procedure TfrmMain.dbgrdMainEnter(Sender: TObject);
begin
  CheckAttachment
end;

procedure TfrmMain.dbgrdMainKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  id      : Integer = 0;
  qsodate : TDateTime;
  time    : String = '';
  id1     : Integer = 0;
  call    : String = '';
begin
  if ((key = VK_END) and (Shift = [ssCtrl])) and (not dmData.IsFilter) then
  begin
    if StrToInt(lblQSOCount.Caption) = 0 then
      exit;
    try
      dmData.qCQRLOG.DisableControls;
      dmData.trCQRLOG.Rollback;
      dmData.qCQRLOG.Close;
      if dmData.SortType = stDate then
        dmData.qCQRLOG.SQL.Text := 'select * from (select * from view_cqrlog_main_by_qsodate order by qsodate, time_on LIMIT '+IntToStr(cDB_LIMIT)+
                      ') as foo order by qsodate DESC,time_on DESC'
      else
        dmData.qCQRLOG.SQL.Text := 'select * from (select * from view_cqrlog_main_by_callsign order by callsign DESC LIMIT '+IntToStr(cDB_LIMIT)+') as foo order by callsign';
      dmData.trCQRLOG.StartTransaction;
      dmData.qCQRLOG.Open;
      dmData.qCQRLOG.Last
    finally
      dmData.qCQRLOG.EnableControls
    end
  end;
  if ((key = VK_HOME) and (Shift = [ssCtrl])) and (not dmData.IsFilter) then
  begin
    if StrToInt(lblQSOCount.Caption) = 0 then
      exit;
    try
      dmData.qCQRLOG.DisableControls;
      dmData.trCQRLOG.Rollback;
      dmData.qCQRLOG.Close;
      if dmData.SortType =  stDate then
        dmData.qCQRLOG.SQL.Text := 'select * from view_cqrlog_main_by_qsodate LIMIT '+IntToStr(cDB_LIMIT)
      else
        dmData.qCQRLOG.SQL.Text := 'select * from view_cqrlog_main_by_callsign LIMIT '+IntToStr(cDB_LIMIT);
      dmData.trCQRLOG.StartTransaction;
      dmData.qCQRLOG.Open
    finally
      dmData.qCQRLOG.EnableControls
    end
  end;
  if (((key = VK_UP) or (key = 33)) and dmData.qCQRLOG.BOF) and (not dmData.IsFilter) then
  begin
    if StrToInt(lblQSOCount.Caption) = 0 then
      exit;
    try
      dmData.qCQRLOG.DisableControls;
      id      := dmData.qCQRLOG.Fields[0].AsInteger;
      time    := dmData.qCQRLOG.Fields[2].AsString;
      qsodate := dmData.qCQRLOG.Fields[1].AsDateTime;
      call    := dmData.qCQRLOG.Fields[4].AsString;
      ///////
      if dmData.SortType =  stDate then
        dmData.Q1.SQL.Text := 'select id_cqrlog_main from view_cqrlog_main_by_qsodate LIMIT 1'
      else
        dmData.Q1.SQL.Text := 'select id_cqrlog_main from view_cqrlog_main_by_callsign LIMIT 1';
      dmData.trQ1.StartTransaction;
      dmData.Q1.Open;
      id1 := dmData.Q1.Fields[0].AsInteger;
      dmData.trQ1.Rollback;
      dmData.Q1.Close;
      ///////
      if id1=id then //we are on the begining of dataset
        exit;
      dmData.qCQRLOG.Close;
      dmData.trCQRLOG.Rollback;
      dmData.trCQRLOG.StartTransaction;
      if dmData.SortType =  stDate then
        dmData.qCQRLOG.SQL.Text := 'select count(*) from (select * from cqrlog_main where (qsodate = '+QuotedStr(DateToStr(qsodate))+
                      'and time_on >= '+QuotedStr(time)+') or qsodate > '+QuotedStr(DateToStr(qsodate))+
                      ' order by qsodate, time_on LIMIT '+IntToStr(cDB_LIMIT)+') as foo order by qsodate DESC,time_on DESC'
      else
        dmData.qCQRLOG.SQL.Text := 'select count(*) from (select * from cqrlog_main where callsign <= ' +QuotedStr(call)+
                      ' order by callsign DESC LIMIT '+IntToStr(cDB_LIMIT)+') as foo order by callsign';
      dmData.qCQRLOG.Open;
      if dmData.qCQRLOG.Fields[0].AsInteger < cDB_LIMIT then
      begin
        dmData.qCQRLOG.Close;
        if dmData.SortType =  stDate then
          dmData.qCQRLOG.SQL.Text := 'select * from view_cqrlog_main_by_qsodate LIMIT '+IntToStr(cDB_LIMIT)
        else
          dmData.qCQRLOG.SQL.Text := 'select * from view_cqrlog_main_by_callsign LIMIT '+IntToStr(cDB_LIMIT)
      end
      else begin
        dmData.qCQRLOG.Close;
        if dmData.SortType =  stDate then
          dmData.qCQRLOG.SQL.Text := 'select * from (select * from view_cqrlog_main_by_qsodate where (qsodate = '+QuotedStr(DateToStr(qsodate))+
                        'and time_on >= '+QuotedStr(time)+') or qsodate > '+QuotedStr(DateToStr(qsodate))+
                        ' order by qsodate, time_on LIMIT '+IntToStr(cDB_LIMIT)+') as foo order by qsodate DESC,time_on DESC'
        else
          dmData.qCQRLOG.SQL.Text := 'select * from (select * from view_cqrlog_main_by_callsign where callsign <= '+QuotedStr(call) +
                        ' order by callsign DESC LIMIT ' + IntToStr(cDB_LIMIT) + ') as foo order by callsign'
      end;
      dmData.qCQRLOG.Open;
      dmData.QueryLocate(dmData.qCQRLOG,'id_cqrlog_main',id,False)
    finally
      dmData.qCQRLOG.EnableControls
    end
  end;

  if (((key = VK_DOWN) or (key = 34)) and dmData.qCQRLOG.EOF) and (not dmData.IsFilter) then
  begin
    if StrToInt(lblQSOCount.Caption) = 0 then
      exit;
    try
      dmData.qCQRLOG.DisableControls;
      id      := dmData.qCQRLOG.Fields[0].AsInteger;
      time    := dmData.qCQRLOG.Fields[2].AsString;
      qsodate := dmData.qCQRLOG.Fields[1].AsDateTime;
      call    := dmData.qCQRLOG.Fields[4].AsString;
      ///////
      if dmData.SortType =  stDate then
        dmData.Q1.SQL.Text := 'select id_cqrlog_main from cqrlog_main order by qsodate,time_on LIMIT 1'
      else
        dmData.Q1.SQL.Text := 'select id_cqrlog_main from cqrlog_main order by callsign DESC LIMIT 1';
      dmData.trQ1.StartTransaction;
      dmData.Q1.Open;
      id1 := dmData.Q1.Fields[0].AsInteger;
      dmData.Q1.Close;
      dmData.trQ1.Rollback;
      ///////
      if id1=id then //we are on the end of dataset
        exit;
      dmData.qCQRLOG.Close;
      if dmData.SortType =  stDate then
        dmData.qCQRLOG.SQL.Text := 'select count(*) from cqrlog_main where (qsodate = '+QuotedStr(DateToStr(qsodate))+
                      'and time_on <= '+QuotedStr(time)+') or qsodate < '+QuotedStr(DateToStr(qsodate))+
                      ' order by qsodate DESC, time_on DESC LIMIT '+IntToStr(cDB_LIMIT)
      else
        dmData.qCQRLOG.SQL.Text := 'select count(*) from cqrlog_main where callsign >= '+QuotedStr(call)+
                      ' order by callsign LIMIT '+IntToStr(cDB_LIMIT);
      dmData.qCQRLOG.Open;
      if dmData.qCQRLOG.Fields[0].AsInteger < cDB_LIMIT then
      begin
        dmData.qCQRLOG.Close;
        if dmData.SortType =  stDate then
          dmData.qCQRLOG.SQL.Text := 'select * from (select * from view_cqrlog_main_by_qsodate order by qsodate, time_on LIMIT '+
                         IntToStr(cDB_LIMIT)+') as foo order by qsodate DESC,time_on DESC'
        else
          dmData.qCQRLOG.SQL.Text := 'select * from (select * from view_cqrlog_main_by_callsign order by callsign DESC LIMIT '+
                        IntToStr(cDB_LIMIT)+') as foo order by callsign'
      end
      else begin
        dmData.qCQRLOG.Close;
        if dmData.SortType =  stDate then
          dmData.qCQRLOG.SQL.Text := 'select * from view_cqrlog_main_by_qsodate where (qsodate = '+QuotedStr(DateToStr(qsodate))+
                        'and time_on <= '+QuotedStr(time)+') or qsodate < '+QuotedStr(DateToStr(qsodate))+
                        ' LIMIT '+IntToStr(cDB_LIMIT)
        else
          dmData.qCQRLOG.SQL.Text := 'select * from view_cqrlog_main_by_callsign where (callsign >= '+QuotedStr(call)+
                        ') LIMIT '+IntToStr(cDB_LIMIT)
      end;
      dmData.qCQRLOG.Open;
      dmData.QueryLocate(dmData.qCQRLOG,'id_cqrlog_main',id,False)
    finally
      dmData.qCQRLOG.EnableControls
    end
  end;
  CheckAttachment
end;

procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  dmData.IsFilter  := False;
  dmData.IsSFilter := False
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  dmUtils.SaveForm(frmMain);
  dmUtils.SaveWindowPos(frmMain);

  cqrini.WriteBool('Main', 'Toolbar', toolMain.Visible);
  cqrini.WriteBool('Main', 'Buttons', pnlButtons.Visible);
  cqrini.WriteBool('Main', 'Details', pnlDetails.Visible);
  cqrini.SaveToDisk;
  if dmData.DebugLevel>=1 then Writeln('Closing QSO list window')
end;

procedure TfrmMain.acAddQSLMgrsExecute(Sender: TObject);
begin
  if Application.MessageBox('Do you really want to find qsl managers for these QSOs?',
    'Question ...', mb_YesNo + mb_IconQuestion) = idNo then
    exit;

  with TfrmImportProgress.Create(self) do
  try
    ImportType := imptInsertQSLManagers;
    ShowModal
  finally
    acRefresh.Execute;
    Free
  end
end;


procedure TfrmMain.acCustomStatExecute(Sender: TObject);
begin
  with TfrmCustomStat.Create(self) do
  try
    ShowModal
  finally
    Free
  end
end;

procedure TfrmMain.acCancelFilterExecute(Sender: TObject);
begin
  sbMain.Panels[2].Text := '';
  dmData.qCQRLOG.DisableControls;
  try
    dmData.qCQRLOG.Close;
    dmData.trCQRLOG.Rollback;
    dmData.qCQRLOG.SQL.Text := 'select * from view_cqrlog_main_by_qsodate LIMIT '+IntToStr(cDB_LIMIT);
    dmData.trCQRLOG.StartTransaction;
    dmData.qCQRLOG.Open
  finally
    dmData.qCQRLOG.EnableControls
  end;
  dmData.IsFilter  := False;
  dmData.IsSFilter := False;
  RefreshQSODXCCCount
end;

procedure TfrmMain.acCloseExecute(Sender: TObject);
begin
  Close
end;

procedure TfrmMain.acCreateFilterExecute(Sender: TObject);
begin
  with TfrmFilter.Create(self) do
  try
    ShowModal;
    if (ModalResult = mrOk) then
      if (tmp <> '') then
      begin
        dmData.IsFilter := True;
        sbMain.Panels[2].Text := 'Filter is ACTIVE!';
        RefreshQSODXCCCount;
        ShowFields
      end
  finally
    Free
  end
end;

procedure TfrmMain.acDXClusterExecute(Sender: TObject);
begin
  if frmDXCluster.Showing then
    frmDXCluster.BringToFront
  else
    frmDXCluster.Show
end;

procedure TfrmMain.acExADIFExecute(Sender: TObject);
begin
  dlgSave.DefaultExt := '.adi';
  dlgSave.Filter     := 'ADIF|*.adi;*.ADI';
  if dlgSave.Execute then
  begin

    frmExportPref := TfrmExportPref.Create(frmMain);
    try
      if frmExportPref.ShowModal = mrCancel then
        exit
    finally
      FreeAndNil(frmExportPref)
    end;

    with TfrmExportProgress.Create(self) do
    try
      FileName   := dlgSave.FileName;
      ExportType := 0;
      ShowModal
    finally
      Free
    end
  end
  else
    BringToFront
end;

procedure TfrmMain.acExHTMLExecute(Sender: TObject);
begin
  dlgSave.DefaultExt := '.html';
  dlgSave.Filter     := 'html|*.html;*.HTML';

  if dlgSave.Execute then
  begin

    frmExportPref := TfrmExportPref.Create(frmMain);
    try
      if frmExportPref.ShowModal = mrCancel then
        exit
    finally
      FreeAndNil(frmExportPref)
    end;

    with TfrmExportProgress.Create(self) do
    try
      FileName   := dlgSave.FileName;
      ExportType := 1;
      ShowModal
    finally
      Free
    end
  end
  else
    BringToFront
end;

procedure TfrmMain.acGraylineExecute(Sender: TObject);
begin
  if frmGrayline.Showing then
    frmGrayline.BringToFront
  else
    frmGrayline.Show
end;

procedure TfrmMain.acImportADIFExecute(Sender: TObject);
begin
  dlgOpen.Filter     := 'ADIF|*.adi;*.ADI;*.adif;*.ADIF';
  dlgOpen.DefaultExt := '.adi';
  if dlgOpen.Execute then
  begin
    with TfrmAdifImport.Create(self) do
    try
      Caption := 'Importing ADIF file ...';
      lblFileName.Caption := dlgOpen.FileName;
      lblErrors.Caption := '0';
      lblCount.Caption := '0';
      ShowModal
    finally
      Free
    end;
    acRefreshExecute(nil)
  end
  else
    BringToFront
end;

procedure TfrmMain.acQSL_RExecute(Sender: TObject);
var
  idx : integer = 0;
  i: integer = 0;

  procedure MarkRec;
  begin
    idx := dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger;
    dmData.Q.SQL.Text := 'UPDATE cqrlog_main SET qsl_r = ' + QuotedStr('Q') +
    ', qslr_date = '+ QuotedStr(dmUtils.DateInRightFormat(dmUtils.GetDateTime(0))) +
    ' WHERE id_cqrlog_main = ' + IntToStr(idx);
    if dmData.DebugLevel >= 1 then
      Writeln(dmData.Q.SQL.Text);
    dmData.Q.ExecSQL;
  end;

begin
  dmData.Q.Close;
  dmData.trQ.StartTransaction;
  if dbgrdMain.SelectedRows.Count < 2 then
  begin
    MarkRec
  end
  else
  begin
    for i := 0 to dbgrdMain.SelectedRows.Count - 1 do
    begin
      dbgrdMain.DataSource.DataSet.GotoBookmark(
        Pointer(dbgrdMain.SelectedRows.Items[i]));
      MarkRec
    end
  end;
  dmData.trQ.Commit;
  dmData.qCQRLOG.Close;
  dmData.RefreshMainDatabase(idx);
  dbgrdMain.SelectedRows.Clear;
  RefreshQSODXCCCount
end;

procedure TfrmMain.acQSL_SExecute(Sender: TObject);
var
  tmp: string;
begin
  tmp := dmData.qCQRLOG.FieldByName('qsl_s').AsString;
  if Pos('S', tmp) > 0 then
    tmp := copy(tmp, 2, Length(tmp) - 1)
  else
    tmp := 'B';
  MarkQSLSend(tmp)
end;

procedure TfrmMain.acRegenDXCCStatExecute(Sender: TObject);
begin
  if Application.MessageBox('Do you really want to rebuild DXCC statistics?'#13'It may take a long time.', 'Question',
    mb_YesNo + MB_ICONQUESTION) = mrNo then
  begin
    exit
  end;
  with TfrmImportProgress.Create(self) do
  try
    ImportType := imptRegenerateDXCC;
    ShowModal
  finally
    Free
  end;
  acRefresh.Execute
end;

procedure TfrmMain.acSearchExecute(Sender: TObject);
begin
  with TfrmSearch.Create(self) do
  try
    ShowModal
  finally
    Free
  end
end;

procedure TfrmMain.acSortExecute(Sender: TObject);
begin
  with TfrmSort.Create(self) do
  try
    ShowModal
  finally
    Free
  end
end;

procedure TfrmMain.acTRXControlExecute(Sender: TObject);
begin
  if frmTRXControl.Showing then
    frmTRXControl.BringToFront
  else
    frmTRXControl.Show;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  dlgOpen.InitialDir := dmData.HomeDir;
  dlgSave.InitialDir := dmData.HomeDir;
  dmUtils.LoadFontSettings(frmMain);
  InRefresh      := False;
  sbMain.Visible := False;  //without this workaround statusbar was hidden
  sbMain.Visible := True;   // and after resize windows was visible again

  dmData.qCQRLOG.Close;
  dmData.qCQRLOG.SQL.Text := 'select * from view_cqrlog_main_by_qsodate LIMIT '+IntToStr(cDB_LIMIT)+' OFFSET 0';
  dmData.qCQRLOG.Open;

  sbMain.Panels[2].Text := '';
  dmData.IsFilter       := False;
  dmData.IsSFilter      := False;


  dbgrdMain.DataSource   := dmData.dsrMain;
  dbtComment.DataSource  := dmData.dsrMain;
  dbtLoTWQSLS.DataSource := dmData.dsrMain;
  dbtLoTWQSLR.DataSource := dmData.dsrMain;
  dbtAward.DataSource    := dmData.dsrMain;
  dbtQSLSDate.DataSource := dmData.dsrMain;
  dbtQSLRDate.DataSource := dmData.dsrMain;
  dbtComment.DataField   := 'remarks';
  dbtLoTWQSLS.DataField  := 'lotw_qslsdate';
  dbtLoTWQSLR.DataField  := 'lotw_qslrdate';
  dbtAward.DataField     := 'award';
  dbtQSLSDate.DataField  := 'qsls_date';
  dbtQSLRDate.DataField  := 'qslr_date';

  sbMain.Panels[1].Text := 'Ver. ' + dmData.VersionString;
  sbMain.Panels[1].Width := 140;
  tmrTime.Enabled := True;

  ShowFields;

  {
  if dmData.Ascening then
    dmData.qCQRLOG.Last
  else
    dmData.qCQRLOG.First;
  }
  RefreshQSODXCCCount;

  Repaint;
  sbMain.Visible := False;  //without this workaround statusbar was hidden
  sbMain.Visible := True;   // and after resize windows was visible again

  toolMain.Visible   := cqrini.ReadBool('Main', 'Toolbar', True);
  pnlButtons.Visible := cqrini.ReadBool('Main', 'Buttons', True);
  pnlDetails.Visible := cqrini.ReadBool('Main', 'Details', True);

  dmUtils.LoadWindowPos(frmMain);

  CheckAttachment;
  mnuShowButtons.Checked := pnlButtons.Visible;
  mnuShowToolBar.Checked := toolMain.Visible
end;

procedure TfrmMain.ShowFields;

  procedure ChangeVis(Column: string; IfShow: boolean);
  var
    i       : integer;
    isAdded : Boolean = False;
  begin
    for i := 0 to dbgrdMain.Columns.Count - 1 do
    begin
      if UpperCase(dbgrdMain.Columns[i].DisplayName) = 'BAND' then
        dbgrdMain.Columns[i].Visible := False;
      if UpperCase(dbgrdMain.Columns[i].DisplayName) = 'QSO_DXCC' then
        dbgrdMain.Columns[i].Visible := False;
      if UpperCase(dbgrdMain.Columns[i].DisplayName) = 'PROFILE' then
        dbgrdMain.Columns[i].Visible := False;
      if UpperCase(dbgrdMain.Columns[i].DisplayName) = 'ID_CQRLOG_MAIN' then
        dbgrdMain.Columns[i].Visible := False;
      if UpperCase(dbgrdMain.Columns[i].DisplayName) = 'IDCALL' then
        dbgrdMain.Columns[i].Visible := False;
      if UpperCase(dbgrdMain.Columns[i].DisplayName) = 'CLUB_NR1' then
        dbgrdMain.Columns[i].Visible := False;
      if UpperCase(dbgrdMain.Columns[i].DisplayName) = 'CLUB_NR2' then
        dbgrdMain.Columns[i].Visible := False;
      if UpperCase(dbgrdMain.Columns[i].DisplayName) = 'CLUB_NR3' then
        dbgrdMain.Columns[i].Visible := False;
      if UpperCase(dbgrdMain.Columns[i].DisplayName) = 'CLUB_NR4' then
        dbgrdMain.Columns[i].Visible := False;
      if UpperCase(dbgrdMain.Columns[i].DisplayName) = 'CLUB_NR5' then
        dbgrdMain.Columns[i].Visible := False;

      //Writeln('dbgrdMain.Columns[i].DisplayName:',dbgrdMain.Columns[i].DisplayName);
      if UpperCase(dbgrdMain.Columns[i].DisplayName) = Column then
      begin
        //Writeln('Column:',column,':',IfShow);
        dbgrdMain.Columns[i].Visible := IfShow;
        if IfShow and (dbgrdMain.Columns[i].Width = 0) then
          dbgrdMain.Columns[i].Width := 60;
        isAdded := True
      end;

      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'TIME_ON') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
      end;

      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'TIME_OFF') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
      end;

      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'MODE') then
      begin
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
        dbgrdMain.Columns[i].Alignment := taCenter;
      end;
      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'QSL_S') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
      end;
      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'QSL_R') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
      end;
      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'DXCC_REF') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
      end;
      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'IOTA') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
      end;
      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'LOC') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
      end;
      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'MY_LOC') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
      end;
      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'WAZ') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
      end;
      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'ITU') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
      end;
      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'FREQ') then
      begin
        dbgrdMain.Columns[i].Alignment       := taRightJustify;
        dbgrdMain.Columns[i].DisplayFormat   := '###,##0.0000;;';
        dbgrdMain.Columns[i].Title.Alignment := taCenter
      end;
      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'STATE') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
      end;
      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'LOTW_QSLS') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
      end;
      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'LOTW_QSLR') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
      end;
      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'EQSL_QSL_SENT') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
      end;
      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'EQSL_QSL_RCVD') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter;
      end;
      if (UpperCase(dbgrdMain.Columns[i].DisplayName) = 'QSLR') then
      begin
        dbgrdMain.Columns[i].Alignment := taCenter;
        dbgrdMain.Columns[i].Title.Alignment := taCenter
      end
    end;
    if (not isAdded) and IfShow then
    begin
      //Writeln('Adding ',Column);
      dbgrdMain.Columns.Add;
      dbgrdMain.Columns[dbgrdMain.Columns.Count-1].FieldName   := LowerCase(Column);
      dbgrdMain.Columns[dbgrdMain.Columns.Count-1].DisplayName := LowerCase(Column);
      dbgrdMain.Columns[dbgrdMain.Columns.Count-1].Width       := 60
    end
  end;

begin
  dbgrdMain.DataSource := dmData.dsrMain;
  dbgrdMain.ResetColWidths;
  dmUtils.LoadForm(frmMain);
  ChangeVis('QSODATE', cqrini.ReadBool('Columns', 'Date', True));
  ChangeVis('TIME_ON', cqrini.ReadBool('Columns', 'time_on', True));
  ChangeVis('TIME_OFF', cqrini.ReadBool('Columns', 'time_off', False));
  ChangeVis('CALLSIGN', cqrini.ReadBool('Columns', 'CallSign', True));
  ChangeVis('MODE', cqrini.ReadBool('Columns', 'Mode', True));
  ChangeVis('FREQ', cqrini.ReadBool('Columns', 'Freq', True));
  ChangeVis('RST_S', cqrini.ReadBool('Columns', 'RST_S', True));
  ChangeVis('RST_R', cqrini.ReadBool('Columns', 'RST_R', True));
  ChangeVis('NAME', cqrini.ReadBool('Columns', 'Name', True));
  ChangeVis('QTH', cqrini.ReadBool('Columns', 'QTH', True));
  ChangeVis('QSL_S', cqrini.ReadBool('Columns', 'QSL_S', True));
  ChangeVis('QSL_R', cqrini.ReadBool('Columns', 'QSL_R', True));
  ChangeVis('QSL_VIA', cqrini.ReadBool('Columns', 'QSL_VIA', False));
  ChangeVis('LOC', cqrini.ReadBool('Columns', 'Locator', False));
  ChangeVis('MY_LOC', cqrini.ReadBool('Columns', 'MyLoc', False));
  ChangeVis('IOTA', cqrini.ReadBool('Columns', 'IOTA', False));
  ChangeVis('AWARD', cqrini.ReadBool('Columns', 'Award', False));
  ChangeVis('COUNTY', cqrini.ReadBool('Columns', 'County', False));
  ChangeVis('PWR', cqrini.ReadBool('Columns', 'Power', False));
  ChangeVis('DXCC_REF', cqrini.ReadBool('Columns', 'DXCC', False));
  ChangeVis('REMARKS', cqrini.ReadBool('Columns', 'Remarks', False));
  ChangeVis('WAZ', cqrini.ReadBool('Columns', 'WAZ', False));
  ChangeVis('ITU', cqrini.ReadBool('Columns', 'ITU', False));
  ChangeVis('STATE', cqrini.ReadBool('Columns', 'State', False));
  ChangeVis('LOTW_QSLSDATE', cqrini.ReadBool('Columns', 'LoTWQSLSDate', False));
  ChangeVis('LOTW_QSLRDATE', cqrini.ReadBool('Columns', 'LoTWQSLRDate', False));
  ChangeVis('LOTW_QSLS', cqrini.ReadBool('Columns', 'LoTWQSLS', False));
  ChangeVis('LOTW_QSLR', cqrini.ReadBool('Columns', 'LOTWQSLR', False));
  ChangeVis('CONT', cqrini.ReadBool('Columns', 'Cont', False));
  ChangeVis('QSLS_DATE',cqrini.ReadBool('Columns','QSLSDate',False));
  ChangeVis('QSLR_DATE',cqrini.ReadBool('Columns','QSLRDate',False));
  ChangeVis('EQSL_QSL_SENT',cqrini.ReadBool('Columns','eQSLQSLS',False));
  ChangeVis('EQSL_QSLSDATE',cqrini.ReadBool('Columns','eQSLQSLSDate',False));
  ChangeVis('EQSL_QSL_RCVD',cqrini.ReadBool('Columns','eQSLQSLR',False));
  ChangeVis('EQSL_QSLRDATE',cqrini.ReadBool('Columns','eQSLQSLRDate',False));
  ChangeVis('QSLR',cqrini.ReadBool('Columns','QSLRAll',False));
  ChangeVis('COUNTRY',cqrini.ReadBool('Columns','Country',False));
  ChangeVis('PROP_MODE', cqrini.ReadBool('Columns', 'Propagation', False));
  ChangeVis('RXFREQ', cqrini.ReadBool('Columns', 'RXFreq', False));
  ChangeVis('SATELLITE', cqrini.ReadBool('Columns', 'SatelliteName', False))
end;

procedure TfrmMain.MarkQSLSend(symbol: string);
var
  idx:    integer = 0;
  qsls:   string = '';
  qslvia: string = '';
  i:      integer = 0;
  qsl:    string = '';

  procedure MarkRec;
  begin
    idx    := dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger;
    qsls   := dmData.qCQRLOG.FieldByName('QSL_S').AsString;
    qslvia := dmData.qCQRLOG.FieldByName('QSL_VIA').AsString;
    qsl    := symbol;
    if qsls = '' then
    begin
      if ((qslvia <> '') and (symbol = 'SB') and (Pos('HOME', UpperCase(qslvia)) = 0)) then
        qsl := 'SMB'
    end
    else begin
      if ((symbol = 'B') and (symbol[1] = 'S')) then
        qsl := copy(qsls, 2, Length(qsls) - 1);
      if ((symbol = 'B') and (qslvia <> '')) then
        qsl := 'MB'
    end;

    dmData.Q.Close;
    dmData.Q.SQL.Text := 'UPDATE cqrlog_main SET qsl_s = ' + QuotedStr(qsl) +
      ', qsls_date = '+ QuotedStr(dmUtils.DateInRightFormat(dmUtils.GetDateTime(0))) +
      ' WHERE id_cqrlog_main = ' + IntToStr(idx);
    dmData.Q.ExecSQL
  end;

begin
  dmData.Q.Close;
  if dmData.trQ.Active then
    dmData.trQ.Rollback;
  dmData.trQ.StartTransaction;
  if dbgrdMain.SelectedRows.Count = 0 then
  begin
    MarkRec
  end
  else begin
    for i := 0 to dbgrdMain.SelectedRows.Count - 1 do
    begin
      dbgrdMain.DataSource.DataSet.GotoBookmark(
        Pointer(dbgrdMain.SelectedRows.Items[i]));
      MarkRec
    end
  end;
  dmData.trQ.Commit;

  dmData.qCQRLOG.Close;
  dbgrdMain.SelectedRows.Clear;
  dmData.RefreshMainDatabase(idx)
end;

procedure TfrmMain.ChechkSelRecords;
begin
  if dbgrdMain.SelectedRows.Count > 1 then
    sbMain.Panels[3].Text := IntToStr(dbgrdMain.SelectedRows.Count) + ' records selected'
  else
    sbMain.Panels[3].Text := '';
end;

procedure TfrmMain.CheckAttachment;
begin
  if not dmData.qCQRLOG.Active then
    exit;
  if dmData.qCQRLOG.RecordCount = 0 then
  begin
    acAttach.Enabled   := False;
    acQSLImage.Enabled := False
  end
  else begin
    if DirectoryExists(dmUtils.GetCallAttachDir(dmData.qCQRLOG.Fields[4].AsString)) then
      acAttach.Enabled := True
    else
      acAttach.Enabled := False;
    if dmUtils.QSLFrontImageExists(dmUtils.GetCallForAttach(dmData.qCQRLOG.Fields[4].AsString)) <> '' then
      acQSLImage.Enabled := True
    else
      acQSLImage.Enabled := False
  end
end;

end.


