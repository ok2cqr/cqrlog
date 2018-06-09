unit fLoTWExport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ExtCtrls, lcltype, iniFiles, process, httpsend, ssl_openssl, synautil,
  blcksock, ssl_openssl_lib, dateutils, synacode;

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
    procedure tmrLoTWTimer(Sender: TObject);
  private
    FileName  : String;
    MarkAfter : Boolean;
    AProcess  : TProcess;
    FileSize : Int64;

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

uses dData, dUtils, uMyIni, dLogUpload;

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
begin
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

    url := Format(UPLOAD_URL,[cqrini.ReadString('LoTW','LoTWName',''),EncodeURL(cqrini.ReadString('LoTW','LoTWPass',''))]);
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
      dmData.Q1.Close();
      dmData.trQ1.Rollback;
      dmData.trQ1.StartTransaction;
      try
        if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) and dmLogUpload.LogUploadEnabled then
          dmLogUpload.DisableOnlineLogSupport;

        dmData.Q1.Open();
        dmData.Q1.First;
        dmData.Q.Close;
        if dmData.trQ.Active then
          dmData.trQ.RollBack;
        dmData.trQ.StartTransaction;
        while not dmData.Q1.Eof do
        begin
          dmData.Q.SQL.Text := 'update cqrlog_main set lotw_qsls = ' + QuotedStr('Y') +
                               ',lotw_qslsdate = ' + QuotedStr(date) + 'where id_cqrlog_main = '+
                               dmData.Q1.FieldByName('id_cqrlog_main').AsString;
          if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
          dmData.Q.ExecSQL;
          dmData.Q1.Next
        end;
      finally
        dmData.Q.Close();
        dmData.trQ.Commit;
        dmData.trQ1.Rollback;
        if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) and dmLogUpload.LogUploadEnabled then
          dmLogUpload.EnableOnlineLogSupport(False)
      end
    end
  finally
    http.Free;
    l.Free;
    m.Free
  end
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
  edtTqsl.Text := cqrini.ReadString('LoTWExp','cmd','/usr/bin/tqsl -d -l "your qth name" %f -x');
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
  cqrini.WriteString('LoTWExp','cmd',edtTqsl.Text);
  AProcess.Free;
  dmData.Q1.Close
end;

procedure TfrmLoTWExport.btnExportSignClick(Sender: TObject);
var
  tmp : String;
  res : Integer;
begin
  MarkAfter := False;
  mStat.Clear;
  FileName := dmData.HomeDir + 'lotw'+PathDelim+FormatDateTime('yyyy-mm-dd_hh-mm-ss',now)+'.adi';
  tmp := copy(edtTqsl.Text,1,Pos(' ',edtTqsl.Text)-1);
  if not FileExists(tmp) then
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

  AProcess.CommandLine := StringReplace(edtTqsl.Text,'%f',FileName,[]);
  AProcess.Options := [poUsePipes];
  if dmData.DebugLevel >=1 then Writeln(AProcess.CommandLine);
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
  f    : TextFile;
  tmp  : String  = '';
  nr   : Integer = 1;
  date : String;
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
  Writeln(f, '<ADIF_VER:5>2.2.1');
  Writeln(f, 'ADIF export from CQRLOG for Linux version '+dmData.VersionString);
  Writeln(f, 'Copyright (C) ',YearOf(now),' by Petr, OK7AN and Martin, OK1RR');
  Writeln(f);
  Writeln(f, 'Internet: http://www.cqrlog.com');
  Writeln(f);
  Writeln(f, '<EOH>');

  if dmData.trQ1.Active then
    dmData.trQ1.RollBack;
  dmData.Q1.Close;
  if (dmData.IsFilter and (rbWebExportAll.Checked or rbFileExportAll.Checked)) then
  begin
    dmData.Q1.SQL.Text := dmData.qCQRLOG.SQL.Text
  end
  else begin
     if rbWebExportAll.Checked then
       dmData.Q1.SQL.Text := 'select * from cqrlog_main'
     else
       dmData.Q1.SQL.Text := 'select * from cqrlog_main where lotw_qslsdate is null'
  end;
  dmData.trQ1.StartTransaction;
  if dmData.DebugLevel >= 1 then Writeln(dmData.Q1.SQL.Text);
  dmData.Q1.Open();
  if MarkAfter then
    dmData.trQ.StartTransaction;
  try
    dmData.Q1.First;
    while not dmData.Q1.EOF do
    begin
      lblInfo.Caption := 'Exporting QSO nr. ' + IntToStr(Nr);
      if not rbWebExportAll.Checked then
      begin
        if dmData.Q1.FieldByName('lotw_qsls').AsString <> '' then
        begin
          dmData.Q1.Next;
          Continue
        end
      end;
      tmp :=  dmData.Q1.FieldByName('qsodate').AsString;
      tmp := copy(tmp,1,4) + copy(tmp,6,2) +copy(tmp,9,2);
      tmp := '<QSO_DATE'+ dmUtils.StringToADIF(tmp);
      Writeln(f, tmp);

      tmp := dmData.Q1.FieldByName('time_on').AsString;
      tmp := copy(tmp,1,2) + copy(tmp,4,2);
      tmp := '<TIME_ON'+ dmUtils.StringToADIF(tmp);
      Writeln(f, tmp);

      tmp := '<CALL' + dmUtils.StringToADIF(dmUtils.RemoveSpaces(dmData.Q1.FieldByName('callsign').AsString));
      Writeln(f,tmp);

      tmp := '<MODE' + dmUtils.StringToADIF(dmData.Q1.FieldByName('mode').AsString);
      Writeln(f,tmp);

      tmp := '<BAND' + dmUtils.StringToADIF(dmData.Q1.FieldByName('band').AsString);
      Writeln(f,tmp);

      tmp := '<FREQ' + dmUtils.StringToADIF(dmData.Q1.FieldByName('freq').AsString);
      Writeln(f,tmp);

      tmp := '<RST_SENT' + dmUtils.StringToADIF(dmData.Q1.FieldByName('rst_s').AsString);
      Writeln(f,tmp);

      tmp := '<RST_RCVD' + dmUtils.StringToADIF(dmData.Q1.FieldByName('rst_r').AsString);
      Writeln(f,tmp);

      if (dmData.Q1.FieldByName('prop_mode').AsString <> '') then
        Writeln(f, '<PROP_MODE' + dmUtils.StringToADIF(dmData.Q1.FieldByName('prop_mode').AsString));

      if (dmData.Q1.FieldByName('satellite').AsString <> '') then
        Writeln(f, '<SAT_NAME' + dmUtils.StringToADIF(dmData.Q1.FieldByName('satellite').AsString));

      if (dmData.Q1.FieldByName('rxfreq').AsString <> '') then
        Writeln(f, '<FREQ_RX' + dmUtils.StringToADIF(dmData.Q1.FieldByName('rxfreq').AsString));

      Writeln(f,'<EOR>');
      Writeln(f);
      if (nr mod 100 = 0) then
      begin
        lblInfo.Repaint;
        Application.ProcessMessages
      end;
      inc(nr);
      if MarkAfter and (pgLoTWExport.ActivePageIndex = 0) then
      begin
        dmData.Q.SQL.Text := 'update cqrlog_main set lotw_qsls = ' + QuotedStr('Y') +
                             ',lotw_qslsdate = ' + QuotedStr(date) + ' where id_cqrlog_main = '+
                             dmData.Q1.FieldByName('id_cqrlog_main').AsString;
        dmData.Q.ExecSQL
      end;
      dmData.Q1.Next
    end;
    if nr=1 then
    begin
      mStat.Lines.Add('Nothing to export ...');
      Result := 1
    end
  finally
   if MarkAfter  and (pgLoTWExport.ActivePageIndex = 0)  then
      dmData.trQ.Commit;
    dmData.Q1.Close();
    dmData.trQ1.Rollback;
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

