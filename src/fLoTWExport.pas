unit fLoTWExport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ExtCtrls, lcltype, iniFiles, process, httpsend, ssl_openssl, synautil,
  blcksock, ssl_openssl_lib, dateutils, synacode, db;

type

  { TfrmLoTWExport }

  TfrmLoTWExport = class(TForm)
    btnClose: TButton;
    btnFileBrowse: TButton;
    btnExportSign: TButton;
    btnFileExport : TButton;
    btnUpload: TButton;
    btnHelp: TButton;
    chkAutoExportAndSign: TCheckBox;
    chkFileMarkAfterExport: TCheckBox;
    edtTqsl: TEdit;
    edtFileName: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    grbWebExport: TGroupBox;
    grbTqsl: TGroupBox;
    GroupBox6: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    lblInfo: TLabel;
    mStat: TMemo;
    pgLoTWExport: TPageControl;
    pnlClose: TPanel;
    pnlUpload: TPanel;
    rbFileExportAll: TRadioButton;
    rbWebExportAll: TRadioButton;
    rbFileExportNotExported: TRadioButton;
    dlgSave: TSaveDialog;
    rbWebExportNotExported: TRadioButton;
    tabLocalFile: TTabSheet;
    tabUpload: TTabSheet;
    tmrLoTW: TTimer;
    procedure chkAutoExportAndSignChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnExportSignClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormShow(Sender: TObject);
    procedure btnFileExportClick(Sender: TObject);
    procedure btnFileBrowseClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure btnUploadClick(Sender: TObject);
    procedure mStatChange(Sender: TObject);
    procedure tmrLoTWTimer(Sender: TObject);
  private
    FileName  : String;
    MarkAfter : Boolean;
    AProcess  : TProcess;
    FileSize : Int64;
    // Number of QSOs written by the last ExportToAdif.
    FQsoCount : Integer;
    // id_cqrlog_main of the QSOs written by the last ExportToAdif. After a
    // successful signing they are saved next to the signed file, and exactly
    // these QSOs are marked as sent once the upload is accepted.
    FExportedIds   : TStringList;
    // Upload was clicked with chkAutoExportAndSign checked: the upload runs
    // after tqsl finishes signing successfully.
    FAutoUpload    : Boolean;

    function ExportToAdif : Word;
    procedure StartExportSign;
    procedure UploadSignedFile;
    procedure AutoExportSignFailed;
    procedure UpdateSignUploadButtons;
    function  PendingUploadFile : String;
    procedure ClearPendingUpload;
    procedure SockCallBack (Sender: TObject; Reason:  THookSocketReason; const  Value: string);
  public
    Running : Integer;
    command : String;

    destructor Destroy; override;

  end;

var
  frmLoTWExport: TfrmLoTWExport;

implementation
{$R *.lfm}

{ TfrmLoTWExport }

uses dData, dUtils, uMyIni, dLogUpload, dSqlQsl;

procedure TfrmLoTWExport.btnFileBrowseClick(Sender: TObject);
begin
  if dlgSave.Execute then
  begin
    edtFileName.Text := dlgSave.FileName
  end
end;

procedure TfrmLoTWExport.btnHelpClick(Sender: TObject);
begin
  ShowHelp
end;

destructor TfrmLoTWExport.Destroy;
begin
  FExportedIds.Free;
  inherited Destroy
end;

// A signed file whose upload has not been accepted by LoTW yet. tqsl refuses
// to sign the same QSOs again (duplicates), so this file has to be uploaded
// before anything new is signed. Kept in the log's local config so that it
// survives closing the window or the program.
function TfrmLoTWExport.PendingUploadFile : String;
begin
  Result := cqrini.ReadString('LoTWExp', 'PendingUpload', '', True);
  if (Result <> '') and not FileExists(Result) then
  begin
    ClearPendingUpload;
    Result := ''
  end
end;

procedure TfrmLoTWExport.ClearPendingUpload;
begin
  cqrini.DeleteKey('LoTWExp', 'PendingUpload', True)
end;

procedure TfrmLoTWExport.btnUploadClick(Sender: TObject);
begin
  if PendingUploadFile <> '' then
    UploadSignedFile
  else if chkAutoExportAndSign.Checked then
  begin
    FAutoUpload := True;
    StartExportSign
  end
  else
    UploadSignedFile
end;

procedure TfrmLoTWExport.UploadSignedFile;
const
  UPLOAD_URL = 'https://LoTW.arrl.org/lotwuser/upload?login=%s&password=%s';
  CR = #$0d;
  LF = #$0a;
  CRLF = CR + LF;
var
  http : THTTPSend;
  m    : TMemoryStream;
  Bound, s: string;
  res  : Boolean;
  l    : TStringList;
  suc  : Boolean = False;
  date : String = '';
  url  : String = '';
  ids  : TStringList;
  i    : Integer;
begin
  FileName := PendingUploadFile;
  if FileName = '' then
  begin
    UpdateSignUploadButtons;
    exit
  end;
  btnUpload.Enabled:=false; //allow only one click
  mStat.Lines.Add('');
  Bound := IntToHex(Random(MaxInt), 8) + '_Synapse_boundary';
  ids := TStringList.Create;
  if FileExists(ChangeFileExt(FileName, '.ids')) then
    ids.LoadFromFile(ChangeFileExt(FileName, '.ids'));
  FileSize := 0;
  mStat.Lines.Add('Uploading file with ' + IntToStr(ids.Count) + ' QSO(s) ...');
  mStat.Lines.Add(FileName);
  mStat.Lines.Add('Size: ');
  http := THTTPSend.Create;
  m    := TMemoryStream.Create;
  l    := TStringList.Create;
  try
    http.ProxyHost := cqrini.ReadString('Program','Proxy','');
    http.ProxyPort := cqrini.ReadString('Program','Port','');
    http.UserName  := cqrini.ReadString('Program','User','');
    http.Password  := cqrini.ReadString('Program','Passwd','');

    m.LoadFromFile(FileName);
    http.Sock.OnStatus := @SockCallBack;
    s := '--' + Bound + CRLF;
    s := s + 'content-disposition: form-data; name="upfile";';
    s := s + ' filename="' + FileName +'"' + CRLF;
    s := s + 'Content-Type: Application/octet-string' + CRLF + CRLF;
    WriteStrToStream(http.Document, s);
    http.Document.CopyFrom(m, 0);
    s := CRLF + '--' + Bound + '--' + CRLF;
    WriteStrToStream(http.Document, s);
    http.MimeType := 'multipart/form-data; boundary=' + Bound;

    url := Format(UPLOAD_URL,[cqrini.ReadString('LoTW','LoTWName',''),dmUtils.EncodeURLData(cqrini.ReadString('LoTW','LoTWPass',''))]);
    if dmData.DebugLevel >= 1 then Writeln(dmUtils.MaskURLPassword(url));

    Res := HTTP.HTTPMethod('POST', url);
    if Res then
    begin
      l.LoadFromStream(HTTP.Document);
      if Pos('<!-- .UPL.  accepted -->',l.Text) > 0 then
      begin
        mStat.Lines.Add('Uploading was successful, ' + IntToStr(ids.Count) + ' QSO(s) uploaded');
        suc := True
      end
      else begin
        mStat.Lines.Add('File was rejected with this error:');
        mStat.Lines.Add(l.Text)
      end;
      if dmData.DebugLevel >= 1 then Writeln(l.Text);
    end
    else begin
      mStat.Lines.Add('Error: '+IntToStr(http.Sock.LastError))
    end;
    if suc then
    begin
      ClearPendingUpload;
      date := FormatDateTime('yyyy-mm-dd',now);
      try
        if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) and dmLogUpload.LogUploadEnabled then
          dmLogUpload.DisableOnlineLogSupport;

        for i := 0 to ids.Count - 1 do
          dmSqlQsl.MarkLotwSent(date, ids[i]);
      finally
        dmSqlQsl.CommitBatch;
        if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) and dmLogUpload.LogUploadEnabled then
          dmLogUpload.EnableOnlineLogSupport(False)
      end
    end
    else begin
      mStat.Lines.Add('The signed file was kept, press Upload to send it again.');
      mStat.Lines.Add('Do not sign these QSOs again, tqsl would reject them as duplicates.')
    end
  finally
    http.Free;
    l.Free;
    m.Free;
    ids.Free
  end;
  UpdateSignUploadButtons
end;

procedure TfrmLoTWExport.mStatChange(Sender: TObject);
begin
   with mStat do
     begin
      //this does not always scroll to end (why?)
      SelStart := GetTextLen;
      SelLength := 0;
      ScrollBy(0, Lines.Count);
      Refresh;
      //added
      VertScrollBar.Position:=100000;
     end;
end;

procedure TfrmLoTWExport.tmrLoTWTimer(Sender: TObject);
var
  OutputLines: TStringList;
begin
  if not AProcess.Running then
  begin
    OutputLines := TStringList.Create;
    try
      OutputLines.LoadFromStream(Aprocess.Output);
      mStat.Lines.AddStrings(OutputLines);
      OutputLines.LoadFromStream(Aprocess.Stderr);
      mStat.Lines.AddStrings(OutputLines);
    finally
      OutputLines.Free;
    end;

    if Aprocess.ExitCode = 0 then
    begin
      FExportedIds.SaveToFile(ChangeFileExt(FileName, '.ids'));
      cqrini.WriteString('LoTWExp', 'PendingUpload', ChangeFileExt(FileName, '.tq8'), True)
    end;
    grbWebExport.Enabled := True;
    grbTqsl.Enabled      := True;
    pnlUpload.Enabled    := True;
    pnlClose.Enabled     := True;
    tmrLoTW.Enabled      := False;

    if Aprocess.ExitCode = 0 then
    begin
      mStat.Lines.Add('Signed ...');
      if FAutoUpload then
      begin
        FAutoUpload := False;
        UpdateSignUploadButtons;
        UploadSignedFile
      end
      else begin
        mStat.Lines.Add('If you did not see any errors, you can send signed file to LoTW website by' +
                        ' pressing Upload button');
        UpdateSignUploadButtons
      end
    end
    else begin
      mStat.Lines.Add('Signing failed, tqsl exit code: ' + IntToStr(Aprocess.ExitCode));
      AutoExportSignFailed;
      UpdateSignUploadButtons
    end
  end
end;

procedure TfrmLoTWExport.AutoExportSignFailed;
begin
  if not FAutoUpload then
    exit;
  FAutoUpload := False;
  //OnChange saves the unchecked state and enables the Export & sign button
  chkAutoExportAndSign.Checked := False
end;

procedure TfrmLoTWExport.UpdateSignUploadButtons;
begin
  btnExportSign.Enabled := not chkAutoExportAndSign.Checked;
  btnUpload.Enabled     := chkAutoExportAndSign.Checked or (PendingUploadFile <> '')
end;


procedure TfrmLoTWExport.btnFileExportClick(Sender: TObject);
begin
  if edtFileName.Text = '' then
  begin
    Application.MessageBox('Please select file to export!','Warning ...', mb_ok + mb_IconWarning);
    exit
  end;
  FileName  := edtFileName.Text;
  MarkAfter := chkFileMarkAfterExport.Checked;
  if ExportToAdif = 0 then
    lblInfo.Caption := 'Exported ' + IntToStr(FQsoCount) + ' QSO(s)'
end;

procedure TfrmLoTWExport.FormShow(Sender: TObject);
begin
  dlgSave.InitialDir := dmData.HomeDir;
  if not cqrini.ReadBool('LoTWExp','Max',False) then
  begin
    Height := cqrini.ReadInteger('LoTWExp','Height',Height);
    Width  := cqrini.ReadInteger('LoTWExp','Width',Width);
    Top    := cqrini.ReadInteger('LoTWExp','Top',top);
    Left   := cqrini.ReadInteger('LoTWExp','Left',left)
  end
  else begin
    WindowState := wsMaximized
  end;
  edtTqsl.Text := cqrini.ReadString('LoTWExp', dmUtils.PlatformKey('cmd'), dmUtils.DefaultToolPath('tqsl', '/usr/bin/tqsl') + ' -d -l "your qth name" %f -x');
  if pgLoTWExport.ActivePageIndex = 1 then
    rbWebExportNotExported.SetFocus;

  chkAutoExportAndSign.Checked := cqrini.ReadBool('LoTWExp', 'AutoExportAndSign', False);
  UpdateSignUploadButtons;
  if PendingUploadFile <> '' then
  begin
    mStat.Lines.Add('A signed file has not been uploaded to LoTW yet:');
    mStat.Lines.Add(PendingUploadFile);
    mStat.Lines.Add('Press Upload to send it.')
  end
end;

procedure TfrmLoTWExport.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  if AProcess.Running then
  begin
    CanClose := False;
    exit
  end;

  if not (WindowState = wsMaximized) then
  begin
    cqrini.WriteInteger('LoTWExp','Height',Height);
    cqrini.WriteInteger('LoTWExp','Width',Width);
    cqrini.WriteInteger('LoTWExp','Top',Top);
    cqrini.WriteInteger('LoTWExp','Left',Left);
    cqrini.WriteBool('LoTWExp','Max', False)
  end
  else begin
    cqrini.WriteBool('LoTWExp','Max', True)
  end;
  cqrini.WriteString('LoTWExp', dmUtils.PlatformKey('cmd'), edtTqsl.Text);
  AProcess.Free;
  dmSqlQsl.CloseRows
end;

procedure TfrmLoTWExport.btnExportSignClick(Sender: TObject);
begin
  if PendingUploadFile <> '' then
  begin
    if Application.MessageBox(PChar('A signed file has not been uploaded to LoTW yet:' + LineEnding +
                              PendingUploadFile + LineEnding + LineEnding +
                              'Signing its QSOs again will fail in tqsl (duplicates). ' +
                              'Discard it and sign again anyway?'),
                              'Question ...', mb_YesNo + mb_IconQuestion) <> idYes then
      exit;
    ClearPendingUpload
  end;
  FAutoUpload := False;
  StartExportSign
end;

procedure TfrmLoTWExport.StartExportSign;
var
  tmp : String;
  paramList :TStringList;
  res : Integer;
begin
  MarkAfter := False;
  UpdateSignUploadButtons;
  mStat.Clear;
  FileName := dmData.HomeDir + 'lotw'+PathDelim+FormatDateTime('yyyy-mm-dd_hh-mm-ss',now)+'.adi';
  tmp := copy(edtTqsl.Text,1,Pos(' ',edtTqsl.Text)-1);
  //Inside Flatpak tqsl is the user's host binary launched via flatpak-spawn,
  //so the sandbox cannot stat it; skip the local existence check there.
  if (not dmUtils.InFlatpak) and (not FileExists(tmp)) then
  begin
    mStat.Lines.Add('tqsl file not found!');
    mStat.Lines.Add(tmp);
    mStat.Lines.Add('Correct path to the tqsl binary or if you do not have tqsl installed, please install it from ' +
                     'software repository');
    AutoExportSignFailed;
    UpdateSignUploadButtons;
    exit
  end;
  mStat.Lines.Add('Starting export to adif ...');
  mStat.Repaint;
  res := ExportToAdif;
  if res > 1 then
  begin
    mStat.Lines.Add('Error creating adif file!');
    mStat.Lines.Add('File:');
    mStat.Lines.Add(FileName);
    lblInfo.Caption := '';
    AutoExportSignFailed;
    UpdateSignUploadButtons;
    exit
  end else
    if res = 1 then
    begin
      //nothing to export is not an error, keep the auto mode on
      FAutoUpload := False;
      exit
    end;
  lblInfo.Caption := '';
  mStat.Lines.Add('Export to the adif file completed, ' + IntToStr(FQsoCount) + ' QSO(s) exported.');
  mStat.Lines.Add('File:');
  mStat.Lines.Add(FileName);
  mStat.Lines.Add('Signing adif file ...');
  Application.ProcessMessages;

  paramList := TStringList.Create;
  paramList.Delimiter := ' ';
  paramList.DelimitedText := StringReplace(edtTqsl.Text,'%f',FileName,[]);
  dmUtils.SetupHostProcess(AProcess, paramList);
  paramList.Free;
  AProcess.Options := [poUsePipes];
  if dmData.DebugLevel>=1 then Writeln('AProcess.Executable: ',AProcess.Executable,' Parameters: ',AProcess.Parameters.Text);
  try
    AProcess.Execute
  except
    on E: Exception do
    begin
      mStat.Lines.Add('Cannot start tqsl: ' + E.Message);
      AutoExportSignFailed;
      UpdateSignUploadButtons;
      exit
    end
  end;

  grbWebExport.Enabled := False;
  grbTqsl.Enabled      := False;
  pnlUpload.Enabled    := False;
  pnlClose.Enabled     := False;
  tmrLoTW.Enabled      := True
end;

procedure TfrmLoTWExport.FormCreate(Sender: TObject);
begin
  AProcess := TProcess.Create(nil);
  FExportedIds := TStringList.Create
end;

procedure TfrmLoTWExport.chkAutoExportAndSignChange(Sender: TObject);
begin
  cqrini.WriteBool('LoTWExp', 'AutoExportAndSign', chkAutoExportAndSign.Checked);
  UpdateSignUploadButtons
end;

function TfrmLoTWExport.ExportToAdif : Word;
var
  f         : TextFile;
  tmp       : String  = '';
  nr        : Integer = 1;
  date,
  ModeOut,
  SubmodeOut: String;
  rows      : TDataSet;
  FilterSql : String;
begin
  FQsoCount := 0;
  FExportedIds.Clear;
  if FileExists(FileName) then
    DeleteFile(FileName);

  AssignFile(f,FileName);
  {$i-}
  Rewrite(f);
  {$i+}
  Result := IOResult;
  If IOresult<>0 then
  begin
    Application.MessageBox(PChar('Error opening file : ' + IntToStr(IOResult)),'Error ...',mb_ok + mb_IconError);
    exit
  end;

  date := FormatDateTime('yyyy-mm-dd',now);
  Writeln(f);
  Writeln(f, '<ADIF_VER:5>3.1.0');
  Writeln(f, '<CREATED_TIMESTAMP:15>',FormatDateTime('YYYYMMDD hhmmss',dmUtils.GetDateTime(0)));
  Writeln(f, 'ADIF export from CQRLOG for Linux version '+dmData.VersionString);
  Writeln(f, 'Copyright (C) ',YearOf(now),' by Petr, OK2CQR and Martin, OK1RR');
  Writeln(f);
  Writeln(f, 'Internet: https://www.cqrlog.com');
  Writeln(f);
  Writeln(f, '<EOH>');

  if (dmData.IsFilter and (rbWebExportAll.Checked or rbFileExportAll.Checked)) then
    FilterSql := dmData.qCQRLOG.SQL.Text
  else
    FilterSql := '';
  rows := dmSqlQsl.OpenQsosForLotwRows(rbWebExportAll.Checked, FilterSql);
  try
    rows.First;
    while not rows.EOF do
    begin
      lblInfo.Caption := 'Exporting QSO nr. ' + IntToStr(Nr);
      if not rbWebExportAll.Checked then
      begin
        if rows.FieldByName('lotw_qsls').AsString <> '' then
        begin
          rows.Next;
          Continue
        end
      end;

      //DL7OAP 2020-06-14: github.com/ok2cqr/cqrlog/issues/292
      //Propagation type RPT (repeater) should not be uploaded to LoTW
      //because repeater contacts don't count and do not match the LoTW rule
      if (uppercase(rows.FieldByName('prop_mode').AsString) = 'RPT') then
      begin
        rows.Next;
        Continue
      end;

      tmp :=  rows.FieldByName('qsodate').AsString;
      tmp := copy(tmp,1,4) + copy(tmp,6,2) +copy(tmp,9,2);
      tmp := dmUtils.StringToADIF('<QSO_DATE',tmp);
      Writeln(f, tmp);

      tmp := rows.FieldByName('time_on').AsString;
      tmp := copy(tmp,1,2) + copy(tmp,4,2);
      tmp := dmUtils.StringToADIF('<TIME_ON',tmp);
      Writeln(f, tmp);

      tmp := dmUtils.StringToADIF('<CALL',dmUtils.RemoveSpaces(rows.FieldByName('callsign').AsString));
      Writeln(f,tmp);

      dmUtils.ModeFromCqr(rows.FieldByName('mode').AsString,ModeOut,SubmodeOut,dmData.DebugLevel >= 1);
      tmp := dmUtils.StringToADIF('<MODE',ModeOut);
      Writeln(f,tmp);
      if SubmodeOut<>'' then
                        Begin
                          tmp := dmUtils.StringToADIF('<SUBMODE',SubmodeOut);
                          Writeln(f,tmp);
                        end;

      tmp :=dmUtils.StringToADIF( '<BAND' , rows.FieldByName('band').AsString);
      Writeln(f,tmp);

      tmp := dmUtils.StringToADIF('<FREQ' , rows.FieldByName('freq').AsString);
      Writeln(f,tmp);

      tmp := dmUtils.StringToADIF('<RST_SENT' , rows.FieldByName('rst_s').AsString);
      Writeln(f,tmp);

      tmp := dmUtils.StringToADIF('<RST_RCVD' ,rows.FieldByName('rst_r').AsString);
      Writeln(f,tmp);

      if (rows.FieldByName('prop_mode').AsString <> '') then
        Writeln(f, dmUtils.StringToADIF('<PROP_MODE' ,rows.FieldByName('prop_mode').AsString));

      if (rows.FieldByName('satellite').AsString <> '') then
        Writeln(f, dmUtils.StringToADIF('<SAT_NAME' ,rows.FieldByName('satellite').AsString));

      if (rows.FieldByName('rxfreq').AsString <> '') then
        Writeln(f, dmUtils.StringToADIF('<FREQ_RX' , rows.FieldByName('rxfreq').AsString));

      Writeln(f,'<EOR>');
      Writeln(f);
      if (nr mod 100 = 0) then
      begin
        lblInfo.Repaint;
        Application.ProcessMessages
      end;
      inc(nr);
      FQsoCount := nr - 1;
      FExportedIds.Add(rows.FieldByName('id_cqrlog_main').AsString);
      if MarkAfter and (pgLoTWExport.ActivePageIndex = 0) then
        dmSqlQsl.MarkLotwSent(date, rows.FieldByName('id_cqrlog_main').AsString);
      rows.Next
    end;
    if nr=1 then
    begin
      mStat.Lines.Add('Nothing to export ...');
      Result := 1
    end
  finally
    if MarkAfter and (pgLoTWExport.ActivePageIndex = 0) then
      dmSqlQsl.CommitBatch;
    dmSqlQsl.CloseRows;
    CloseFile(f)
  end
end;

procedure TfrmLoTWExport.SockCallBack (Sender: TObject; Reason:  THookSocketReason; const  Value: string);
begin
  if Reason = HR_WriteCount then
  begin
    FileSize := FileSize + StrToInt(Value);
    mStat.Lines.Strings[mStat.Lines.Count-1] := 'Size: '+ IntToStr(FileSize);
    Repaint;
    Application.ProcessMessages
  end
end;

end.

