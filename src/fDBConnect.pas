unit fDBConnect;

{$mode objfpc}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, DBGrids, LCLType, Menus, IniFiles, uDbUtils, uConnectionInfo,
  strutils;

type

  { TfrmDBConnect }

  TfrmDBConnect = class(TForm)
    btnConnect: TButton;
    btnDisconnect: TButton;
    btnNewLog: TButton;
    btnEditLog: TButton;
    btnDeleteLog: TButton;
    btnOpenLog: TButton;
    btnCancel: TButton;
    btnUtils: TButton;
    chkAutoOpen: TCheckBox;
    chkSaveToLocal: TCheckBox;
    chkAutoConn: TCheckBox;
    chkSavePass: TCheckBox;
    dbgrdLogs: TDBGrid;
    edtPass: TEdit;
    edtUser: TEdit;
    edtPort: TEdit;
    edtServer: TEdit;
    grbLogin: TGroupBox;
    lblServerName: TLabel;
    lblPort: TLabel;
    lblUserName: TLabel;
    lblPassword: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    mnuRepair : TMenuItem;
    MenuItem5 : TMenuItem;
    mnuClearLog: TMenuItem;
    mnuImport: TMenuItem;
    mnuExport: TMenuItem;
    dlgOpen: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    popUtils: TPopupMenu;
    dlgSave: TSaveDialog;
    tmrAutoConnect: TTimer;
    procedure btnCancelClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDeleteLogClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnEditLogClick(Sender: TObject);
    procedure btnNewLogClick(Sender: TObject);
    procedure btnOpenLogClick(Sender: TObject);
    procedure btnUtilsClick(Sender: TObject);
    procedure chkSavePassChange(Sender: TObject);
    procedure chkSaveToLocalClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure mnuClearLogClick(Sender: TObject);
    procedure mnuExportClick(Sender: TObject);
    procedure mnuImportClick(Sender: TObject);
    procedure mnuRepairClick(Sender : TObject);
    procedure tmrAutoConnectTimer(Sender: TObject);
  private
    RemoteMySQL : Boolean;
    AskForDB    : Boolean;
    procedure SaveLogin;
    procedure LoadLogin;
    procedure UpdateGridFields;
    procedure EnableButtons;
    procedure DisableButtons;
    procedure OpenDefaultLog;
  public
    OpenFromMenu : Boolean;
  end; 

var
  frmDBConnect: TfrmDBConnect;


implementation
{$R *.lfm}

uses dData, dUtils, fNewLog, fDbSqlSel;

{ TfrmDBConnect }

procedure TfrmDBConnect.EnableButtons;
begin
  btnOpenLog.Enabled   := True;
  btnNewLog.Enabled    := True;
  btnEditLog.Enabled   := True;
  btnDeleteLog.Enabled := True;
  btnUtils.Enabled     := True
end;

procedure TfrmDBConnect.DisableButtons;
begin
  btnOpenLog.Enabled   := False;
  btnNewLog.Enabled    := False;
  btnEditLog.Enabled   := False;
  btnDeleteLog.Enabled := False;
  btnUtils.Enabled     := False
end;

procedure TfrmDBConnect.UpdateGridFields;
begin
  //dbgrdLogs.Columns[0].Visible     := False;
  dbgrdLogs.Columns[0].Width       := 50;
  dbgrdLogs.Columns[1].Width       := 180;
  //dbgrdLogs.Columns[2].Visible     := False;
  dbgrdLogs.Columns[0].DisplayName := 'Log nr';
  dbgrdLogs.Columns[1].DisplayName := 'Log name'
end;

procedure TfrmDBConnect.SaveLogin;
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(GetAppConfigDir(False)+'cqrlog_login.cfg');
  try
    if not chkSaveToLocal.Checked then
    begin
      ini.WriteBool('Login','SaveToLocal',False);
      ini.WriteString('Login','Server',edtServer.Text);
      ini.WriteString('Login','Port',edtPort.Text);
      ini.WriteString('Login','User',edtUser.Text);

      if chkSavePass.Checked then
        ini.WriteString('Login','Pass',edtPass.Text)
      else
        ini.WriteString('Login','Pass','');

      ini.WriteBool('Login','SavePass',chkSavePass.Checked);
      ini.WriteBool('Login','AutoConnect',chkAutoConn.Checked)
    end
    else
      ini.WriteBool('Login','SaveToLocal',True)
  finally
    ini.Free
  end
end;

procedure TfrmDBConnect.LoadLogin;
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(GetAppConfigDir(False)+'cqrlog_login.cfg');
  try
    if ini.ReadBool('Login','SaveTolocal',True) then
    begin
      edtServer.Text         := '127.0.0.1';
      edtPort.Text           := '64000';
      edtUser.Text           := 'cqrlog';
      edtPass.Text           := 'cqrlog';
      tmrAutoConnect.Enabled := True;
      chkAutoConn.Checked    := True;
      chkSaveToLocal.Checked := True;
      chkSaveToLocalClick(nil);
      RemoteMySQL  := False
    end
    else begin
      chkSaveToLocal.Checked := False;
      grbLogin.Visible     := True;
      edtServer.Text       := ini.ReadString('Login','Server','127.0.0.1');
      edtPort.Text         := ini.ReadString('Login','Port','3306');
      edtUser.Text         := ini.ReadString('Login','User','');
      chkSavePass.Checked  := ini.ReadBool('Login','SavePass',False);

      if chkSavePass.Checked then
        edtPass.Text := ini.ReadString('Login','Pass','')
      else
        edtPass.Text := '';

        chkAutoConn.Checked := ini.ReadBool('Login','AutoConnect',False);
      chkSavePassChange(nil);
      if (chkAutoConn.Checked) and (chkAutoConn.Enabled) then
        tmrAutoConnect.Enabled := True;
      RemoteMySQL  := True
    end;
    chkAutoOpen.Checked := ini.ReadBool('Login','AutoOpen',False);
  finally
    ini.Free
  end
end;

procedure TfrmDBConnect.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
var
  ini : TIniFile;
begin
  SaveLogin;
  ini := TIniFile.Create(GetAppConfigDir(False)+'cqrlog_login.cfg');
  try
    if WindowState = wsMaximized then
      ini.WriteBool(Name,'Max',True)
    else begin
      ini.WriteInteger(Name,'Height',Height);
      ini.WriteInteger(Name,'Width',Width);
      ini.WriteInteger(Name,'Top',Top);
      ini.WriteInteger(Name,'Left',Left);
      ini.WriteBool(Name,'Max',False)
    end
  finally
    ini.Free
  end
end;

procedure TfrmDBConnect.FormCreate(Sender: TObject);
var
  ini : TIniFile;
begin
  OpenFromMenu := False;
  ini := TIniFile.Create(GetAppConfigDir(False)+'cqrlog_login.cfg');
  try
    AskForDB := not ini.ValueExists('Login','SaveToLocal')
  finally
    ini.Free
  end
end;

procedure TfrmDBConnect.btnConnectClick(Sender: TObject);
begin
  SaveLogin;
  if dmData.OpenConnections(edtServer.Text,edtPort.Text,edtUser.Text,edtPass.Text) then
  begin
    UpdateConnectionInfoRecord(edtServer.Text, edtPort.Text, edtUser.Text, edtPass.Text, '');
    dmData.CheckForDatabases;
    UpdateGridFields;
    EnableButtons;
    OpenDefaultLog;
  end
end;

procedure TfrmDBConnect.btnDeleteLogClick(Sender: TObject);
var
  ConnectionInfo : TConnectionInfo;
  ActiveLog : String;
begin
  if dmData.qLogList.Fields[0].AsInteger = 1 then
  begin
    Application.MessageBox('You can not delete the first log!','Info ...',mb_ok + mb_IconInformation);
    exit
  end;

  ConnectionInfo := GetConnectionInfo();
  ActiveLog := 'cqrlog' + AddChar('0',IntToStr(dmData.qLogList.Fields[0].AsInteger), 3);
  if (ConnectionInfo.DatabaseName = ActiveLog) then
  begin
    Application.MessageBox('You can not delete current active log!','Info ...',mb_ok + mb_IconInformation);
    exit;
  end;

  if Application.MessageBox('Do you really want to delete this log?','Question ...', mb_YesNo + mb_IconQuestion + mb_DefButton2) in [idNo, idCancel] then
  begin
    exit;
  end;

  if Application.MessageBox('LOG WILL BE _DELETED_. Are you sure?','Question ...', mb_YesNo + mb_IconQuestion + mb_DefButton2) in [idNo, idCancel] then
  begin
    exit;
  end;

  dmData.DeleteLogDatabase(dmData.qLogList.Fields[0].AsInteger);
  UpdateGridFields;
end;

procedure TfrmDBConnect.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel
end;

procedure TfrmDBConnect.btnDisconnectClick(Sender: TObject);
begin
  {if (dmData.MySQLVersion < 5.5) then
  begin
    if dmData.MainCon51.Connected then
      dmData.MainCon51.Connected := False
  end
  else begin
    if dmData.MainCon55.Connected then
      dmData.MainCon55.Connected := False
  end;
  }
  if dmData.MainCon.Connected then
    dmData.MainCon.Connected := False;
  DisableButtons
end;

procedure TfrmDBConnect.btnEditLogClick(Sender: TObject);
begin
  frmNewLog := TfrmNewLog.Create(nil);
  try
    frmNewLog.Caption := 'Edit existing log ...';
    frmNewLog.edtLogNR.Text   := dmData.qLogList.Fields[0].AsString;
    frmNewLog.edtLogName.Text := dmData.qLogList.Fields[1].AsString;
    frmNewLog.edtLogNR.Enabled := False;
    frmNewLog.ShowModal;
    if frmNewLog.ModalResult = mrOK then
    begin
      dmData.EditDatabaseName(StrToInt(frmNewLog.edtLogNR.Text),
                            frmNewLog.edtLogName.Text);
      UpdateGridFields
    end
  finally
    frmNewLog.Free
  end
end;

procedure TfrmDBConnect.btnNewLogClick(Sender: TObject);
var
  db          :string;
  cnr,nr      :integer;
  l           :TStringList;
begin
  frmNewLog := TfrmNewLog.Create(nil);
  try
    frmNewLog.Caption := 'New log ...';
    frmNewLog.ShowModal;
    if frmNewLog.ModalResult = mrOK then
    begin
      dmData.CreateDatabase(StrToInt(frmNewLog.edtLogNR.Text),frmNewLog.edtLogName.Text);
      UpdateGridFields;
      if frmNewLog.edtLogCpyNR.Text<>'' then
       Begin
          cnr:=StrToInt(frmNewLog.edtLogCpyNR.Text); //this nr log exists and strtoint works: tested in "newlog"
          db := dmData.GetProperDBName(cnr);
          if dmData.DBName<>'' then
            dmData.SaveConfigFile;
          dmData.Q.Close;
          if dmData.trQ.Active then dmData.trQ.Rollback;
          dmData.Q.SQL.Text := 'select config_file from '+db+'.cqrlog_config';
          dmData.trQ.StartTransaction;
          l := TStringList.Create;
          try  try
            dmData.Q.Open;
            l.Text := dmData.Q.Fields[0].AsString;
            nr:=StrToInt(frmNewLog.edtLogNR.Text);  //this nr log just created strtoint works: tested in "newlog"
            db := dmData.GetProperDBName(nr);
            dmData.Q.Close;
            if dmData.trQ.Active then dmData.trQ.Rollback;
            dmData.Q.SQL.Text := 'update '+db+'.cqrlog_config set config_file =:config_file';
            dmData.trQ.StartTransaction;
            dmData.Q.Params[0].AsString := l.Text;
            dmData.Q.ExecSQL
            except
              dmData.trQ.Rollback
            end;
            dmData.trQ.Commit;
            ShowMessage('Config copied successfully')
            finally
              dmData.Q.Close;
              l.Free
            end;

       end;
      end;
  finally
    frmNewLog.Free
  end;
end;

procedure TfrmDBConnect.btnOpenLogClick(Sender: TObject);
var
  ini : TIniFile;
begin
  ini := TIniFile.Create(GetAppConfigDir(False)+'cqrlog_login.cfg');
  try
    ini.WriteBool('Login','AutoOpen',chkAutoOpen.Checked);
    ini.WriteInteger('Login','LastLog',dmData.qLogList.Fields[0].AsInteger);
    if chkAutoOpen.Checked then
      ini.WriteInteger('Login','LastLog',dmData.qLogList.Fields[0].AsInteger)
    else
      ini.WriteInteger('Login','LastOpenedLog',dmData.qLogList.Fields[0].AsInteger)
  finally
    ini.Free
  end;

  UpdateConnectionInfoDatabaseName(dmData.qLogList.Fields[0].AsInteger);

  if not OpenFromMenu then
  begin
    dmData.LogName := dmData.qLogList.Fields[1].AsString;
    dmData.OpenDatabase(dmData.qLogList.Fields[0].AsInteger)
  end;
  ModalResult    := mrOK
end;

procedure TfrmDBConnect.btnUtilsClick(Sender: TObject);
var
  p : TPoint;
begin
  p.x := 10;
  p.y := 10;
  p := btnUtils.ClientToScreen(p);
  popUtils.PopUp(p.x, p.y)
end;

procedure TfrmDBConnect.chkSavePassChange(Sender: TObject);
begin
  if chkSavePass.Checked then
    chkAutoConn.Enabled := True
  else
    chkAutoConn.Enabled := False
end;

procedure TfrmDBConnect.chkSaveToLocalClick(Sender: TObject);
begin
  if chkSaveToLocal.Checked then
  begin
    if RemoteMySQL then
    begin
      if Application.MessageBox('Local database is not running. Dou you want to start it?','Question',mb_YesNo+mb_IconQuestion) = idYes then
      begin
        dmData.StartMysqldProcess;
        Sleep(3000);
        btnConnectClick(nil)
      end
      else begin
        chkSaveToLocal.Checked := False;
        grbLogin.Visible       := True;
        exit
      end
    end;
    grbLogin.Visible := False
  end
  else  begin
    grbLogin.Visible := True
  end
end;

procedure TfrmDBConnect.FormShow(Sender: TObject);
var
  ini : TIniFile;
  StartMysql : Boolean;
begin
  ini := TIniFile.Create(GetAppConfigDir(False)+'cqrlog_login.cfg');
  try
    if ini.ReadBool(Name,'Max',False) then
      WindowState := wsMaximized
    else begin
      Height := ini.ReadInteger(Name,'Height',Height);
      Width  := ini.ReadInteger(Name,'Width',Width);
      Top    := ini.ReadInteger(Name,'Top',20);
      Left   := ini.ReadInteger(Name,'Left',20);
    end;
    StartMysql := ini.ReadBool('Login','SaveTolocal',False)
  finally
    ini.Free
  end;
  dbgrdLogs.DataSource := dmData.dsrLogList;

  LoadLogin;
  if OpenFromMenu then
  begin
    UpdateGridFields;
    EnableButtons
  end
  else begin
    if StartMysql then
      dmData.StartMysqldProcess
  end;
  dlgOpen.InitialDir := dmData.HomeDir;
  dlgSave.InitialDir := dmData.HomeDir
end;

procedure TfrmDBConnect.mnuClearLogClick(Sender: TObject);
var
  s : PChar;
begin
  s := 'YOUR ENTIRE LOG WILL BE DELETED!'+LineEnding+LineEnding+
       'Do you want to CANCEL this operation?';
  if Application.MessageBox(s,'Question ...', mb_YesNo + mb_IconQuestion + mb_DefButton1) in [idNo, idCancel] then
  begin
    dmData.TruncateTables(dmData.qLogList.Fields[0].AsInteger);
    ShowMessage('Log is empty')
  end
end;

procedure TfrmDBConnect.mnuExportClick(Sender: TObject);
var
  db : String;
  l  : TStringList;
  n  : String;
begin
  if dlgSave.Execute then
  begin
    db := dmData.GetProperDBName(dmData.qLogList.Fields[0].AsInteger);
    if dmData.DBName<>'' then
      dmData.SaveConfigFile;
    dmData.Q.Close;
    if dmData.trQ.Active then dmData.trQ.Rollback;
    dmData.Q.SQL.Text := 'select config_file from '+db+'.cqrlog_config';
    dmData.trQ.StartTransaction;
    l := TStringList.Create;
    try
      dmData.Q.Open;
      l.Text := dmData.Q.Fields[0].AsString;
      n:= dlgSave.FileName;
      if pos('.INI',UpperCase(n))=0 then
          n:=n+'.ini';
      l.SaveToFile(n);
      ShowMessage('Config file saved to '+n
      +#10+#13+#10+#13+'Warning !'+#10+#13+'File may contain passwords'+#10+#13+'in plain text format')
    finally
      dmData.Q.Close;
      dmData.trQ.Rollback;
      l.Free
    end
  end
end;

procedure TfrmDBConnect.mnuImportClick(Sender: TObject);
var
  db : String;
  l  : TStringList;
begin
  if dlgOpen.Execute then
   begin
     if FileExists(dlgOpen.FileName) then  //with QT5 opendialog user can enter filename that may not exist
      begin
        db := dmData.GetProperDBName(dmData.qLogList.Fields[0].AsInteger);
        dmData.Q.Close;
        if dmData.trQ.Active then dmData.trQ.Rollback;
        dmData.Q.SQL.Text := 'update '+db+'.cqrlog_config set config_file =:config_file';
        dmData.trQ.StartTransaction;
        l := TStringList.Create;
        try try
          l.LoadFromFile(dlgOpen.FileName);
          dmData.Q.Params[0].AsString := l.Text;
          if dmData.DebugLevel >=1 then Writeln(dmData.Q.SQL.Text);
          dmData.Q.ExecSQL
        except
          dmData.trQ.Rollback
        end;
        dmData.trQ.Commit;
        ShowMessage('Config file imported successfully')
        finally
          dmData.Q.Close;
          l.Free
        end
      end
        else
              ShowMessage('File not found!');
   end
end;

procedure TfrmDBConnect.mnuRepairClick(Sender : TObject);
begin
  dmData.RepairTables(dmData.qLogList.Fields[0].AsInteger);
  ShowMessage('Done, tables fixed')
end;

procedure TfrmDBConnect.tmrAutoConnectTimer(Sender: TObject);
var
  Connect : Boolean = True;
begin
  tmrAutoConnect.Enabled := False;

  if AskForDB then
  begin
      if (frmDbSqlSel = nil) then  Application.CreateForm(TfrmDbSqlSel, frmDbSqlSel);
      frmDbSqlSel.Show;

      repeat   //wait for user to make selection on other window
       Begin
        sleep(100);
        Application.ProcessMessages;
       end;
        until frmDbSqlSel.rdy;

      if frmDbSqlSel.loc then
       begin
        dmData.StartMysqldProcess;
        Sleep(3000)
       end
      else
       begin
        Connect     := True;
        RemoteMySQL := True;

        edtUser.Text:=frmDbSqlSel.user;
        edtPass.Text:=frmDbSqlSel.pass;
        edtPort.Text:=frmDbSqlSel.port;
        edtServer.Text:=frmDbSqlSel.ip;
        chkAutoConn.Checked:= frmDbSqlSel.Acon;
        chkSavePass.Checked:= frmDbSqlSel.Rmbr;

        chkSaveToLocal.Checked := False;
        chkSaveToLocalClick(nil);
       end;

      FreeAndNil(frmDbSqlSel);

  end;
  if (not OpenFromMenu) and Connect then
                                        btnConnect.Click;
  if btnOpenLog.Enabled then
                            btnOpenLog.SetFocus
end;

procedure TfrmDBConnect.OpenDefaultLog;
var
  ini    : TIniFile;
  AutoLog  : Integer;
  AutoOpen : Boolean;
  LastLog  : Integer;
begin
  ini := TIniFile.Create(GetAppConfigDir(False)+'cqrlog_login.cfg');
  try
    AutoOpen := ini.ReadBool('Login','AutoOpen',False);
    AutoLog  := ini.ReadInteger('Login','LastLog',0);
    LastLog  := ini.ReadInteger('Login','LastOpenedLog',0)
  finally
    ini.Free
  end;
  if AutoOpen then
  begin
    if dmData.qLogList.Locate('log_nr',AutoLog,[]) then
      btnOpenLog.Click
  end
  else begin
    dmData.qLogList.Locate('log_nr',LastLog,[])
  end
end;

end.

