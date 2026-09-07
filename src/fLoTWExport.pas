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
    // The selection ExportToAdif walked, so that the marking after a web
    // upload walks the same rows.
    FLotwAll       : Boolean;
    FLotwFilterSql : String;

    function ExportToAdif : Word;
    procedure SockCallBack (Sender: TObject; Reason:  THookSocketReason; const  Value: string);
  public
    Running : Integer;
    command : String;

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

procedure TfrmLoTWExport.btnUploadClick(Sender: TObject);
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
  rows : TDataSet;
begin
  btnUpload.Enabled:=false; //allow only one click
  mStat.Lines.Add('');
  Bound := IntToHex(Random(MaxInt), 8) + '_Synapse_boundary';
  FileName := ChangeFileExt(Filename,'.tq8');
  mStat.Lines.Add('Uploading file ...');
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
    if dmData.DebugLevel >= 1 then Writeln(url);

    Res := HTTP.HTTPMethod('POST', url);
    if Res then
    begin
      l.LoadFromStream(HTTP.Document);
      if Pos('<!-- .UPL.  accepted -->',l.Text) > 0 then
      begin
        mStat.Lines.Add('Uploading was successful');
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
      date := FormatDateTime('yyyy-mm-dd',now);
      try
        if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) and dmLogUpload.LogUploadEnabled then
          dmLogUpload.DisableOnlineLogSupport;

        rows := dmSqlQsl.OpenQsosForLotwRows(FLotwAll, FLotwFilterSql);
        rows.First;
        while not rows.Eof do
        begin
          dmSqlQsl.MarkLotwSent(date, rows.FieldByName('id_cqrlog_main').AsString);
          rows.Next
        end;
      finally
        dmSqlQsl.CommitBatch;
        dmSqlQsl.CloseRows;
        if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) and dmLogUpload.LogUploadEnabled then
          dmLogUpload.EnableOnlineLogSupport(False)
      end
    end
  finally
    http.Free;
    l.Free;
    m.Free
  end;
  btnUpload.Enabled:=true; //allow only one click
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

    if Aprocess.ExitCode = 0 then begin
      mStat.Lines.Add('Signed ...');
      mStat.Lines.Add('If you did not see any errors, you can send signed file to LoTW website by' +
                      ' pressing Upload button');
      btnUpload.Enabled := True;
    end;
    grbWebExport.Enabled := True;
    grbTqsl.Enabled      := True;
    pnlUpload.Enabled    := True;
    pnlClose.Enabled     := True;
    tmrLoTW.Enabled      := False;
  end
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
  ExportToAdif
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
    rbWebExportNotExported.SetFocus
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
var
  tmp : String;
  paramList :TStringList;
  res : Integer;
begin
  MarkAfter := False;
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
    exit
  end else
    if res = 1 then
      exit;
  lblInfo.Caption := '';
  mStat.Lines.Add('Export to the adif file completed.');
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
  AProcess.Execute;

  grbWebExport.Enabled := False;
  grbTqsl.Enabled      := False;
  pnlUpload.Enabled    := False;
  pnlClose.Enabled     := False;
  tmrLoTW.Enabled      := True
end;

procedure TfrmLoTWExport.FormCreate(Sender: TObject);
begin
  AProcess := TProcess.Create(nil)
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
begin
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
    FLotwFilterSql := dmData.qCQRLOG.SQL.Text
  else
    FLotwFilterSql := '';
  FLotwAll := rbWebExportAll.Checked;
  rows := dmSqlQsl.OpenQsosForLotwRows(FLotwAll, FLotwFilterSql);
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

