unit feQSLUpload;

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,FileUtil,LResources,Forms,Controls,Graphics,Dialogs,StdCtrls,
  ExtCtrls, httpsend, blcksock, synautil, lcltype, dateutils, synacode;

type

  { TfrmeQSLUpload }

  TfrmeQSLUpload = class(TForm)
    btnPreferences : TButton;
    btnUpload : TButton;
    btnClose : TButton;
    edtQTH : TEdit;
    grbWebExport : TGroupBox;
    GroupBox1 : TGroupBox;
    GroupBox6 : TGroupBox;
    Label1 : TLabel;
    lblInfo : TLabel;
    mStat : TMemo;
    pnlUpload : TPanel;
    rbWebExportAll : TRadioButton;
    rbWebExportNotExported : TRadioButton;
    procedure btnPreferencesClick(Sender : TObject);
    procedure btnUploadClick(Sender : TObject);
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure FormShow(Sender : TObject);
  private
    FileSize     : Int64;
    QSOCount     : Integer;
    function  ExportData(const FileName : String) : Boolean;
    function  HttpPostFile(const URL, FieldName, FileName: string;
                const Data: TStream; const ResultData: TStrings; var err : String): Boolean;
    function  FormatOutput(ResultText : String) : String;

    procedure Upload(const FileName : String);
    procedure SockCallBack(Sender: TObject; Reason:  THookSocketReason; const  Value: string);
  public


end;


var
  frmeQSLUpload : TfrmeQSLUpload;

implementation
{$R *.lfm}

uses dUtils,dData,uMyIni, fPreferences, uVersion;

procedure TfrmeQSLUpload.SockCallBack(Sender: TObject; Reason:  THookSocketReason; const  Value: string);
begin
  if Reason = HR_WriteCount then
  begin
    FileSize := FileSize + StrToInt(Value);
    mStat.Lines.Strings[mStat.Lines.Count-2] := 'Size: '+ IntToStr(FileSize);
    mStat.Lines.Strings[mStat.Lines.Count-1] := 'After upload, please wait, eQSL will return some information!';
    Repaint;
    Application.ProcessMessages
  end
end;

function TfrmeQSLUpload.ExportData(const FileName : String) : Boolean;
var
  nr  : integer = 0;
  tmp : String = '';
  f   : TextFile;
begin
  QSOCount := 0;
  Result := True;
  dmData.Q.Close;
  if dmData.trQ.Active then dmData.trQ.Rollback;
  if rbWebExportNotExported.Checked then
    dmData.Q.SQL.Text := 'select id_cqrlog_main,qsodate,time_on,callsign,mode,band,freq,rst_s,rst_r,remarks '+
                         'from cqrlog_main where eqsl_qslsdate is null'
  else begin
    if dmData.IsFilter then
      dmData.Q.SQL.Text := dmData.qCQRLOG.SQL.Text
    else
      dmData.Q.SQL.Text := 'select id_cqrlog_main,qsodate,time_on,callsign,mode,band,freq,rst_s,rst_r,remarks '+
                           'from cqrlog_main'
  end;
  dmData.Q.Open;
  dmData.Q.First;
  if dmData.Q.RecordCount = 0 then
  begin
    Application.MessageBox('Nothing to export ... ','Info ...',mb_Ok+mb_IconInformation);
    dmData.Q.Close;
    dmData.trQ.Rollback;
    Result := False;
    exit
  end;
  mStat.Lines.Add('Please wait, exporting QSO for eQSL ...');
  mStat.Lines.Add('Filename: '+FileName);
  Application.ProcessMessages;

  AssignFile(f,FileName);
  try try
    Rewrite(f);
    Writeln(f, 'ADIF export from CQRLOG for Linux version '+dmData.VersionString);
    Writeln(f, 'Copyright (C) ',YearOf(now),' by Petr, OK7AN and Martin, OK1RR');
    Writeln(f);
    Writeln(f, 'Internet: http://www.cqrlog.com');
    Writeln(f, '<ADIF_VER:5>2.2.1');
    Writeln(f, '<PROGRAMID:6>CQRLOG');
    Writeln(f, '<PROGRAMVERSION:',Length(cVERSION),'>',cVERSION);
    Writeln(f);
    Writeln(f,'<EQSL_USER'+dmUtils.StringToADIF(cqrini.ReadString('LoTW','eQSLName','')));
    Writeln(f,'<EQSL_PSWD'+dmUtils.StringToADIF(EncodeURL(cqrini.ReadString('LoTW','eQSLPass',''))));
    Writeln(f,'<EOH>');
    while not dmData.Q.Eof do
    begin
      lblInfo.Caption := 'Exporting QSO nr. ' + IntToStr(Nr);
      tmp :=  dmData.Q.FieldByName('qsodate').AsString;
      tmp := copy(tmp,1,4) + copy(tmp,6,2) +copy(tmp,9,2);
      tmp := '<QSO_DATE'+ dmUtils.StringToADIF(tmp);
      Writeln(f, tmp);

      tmp := dmData.Q.FieldByName('time_on').AsString;
      tmp := copy(tmp,1,2) + copy(tmp,4,2);
      tmp := '<TIME_ON'+ dmUtils.StringToADIF(tmp);
      Writeln(f, tmp);

      tmp := '<CALL' + dmUtils.StringToADIF(dmUtils.RemoveSpaces(dmData.Q.FieldByName('callsign').AsString));
      Writeln(f,tmp);

      tmp := '<MODE' + dmUtils.StringToADIF(dmData.Q.FieldByName('mode').AsString);
      Writeln(f,tmp);

      tmp := '<BAND' + dmUtils.StringToADIF(dmData.Q.FieldByName('band').AsString);
      Writeln(f,tmp);

      tmp := '<FREQ' + dmUtils.StringToADIF(dmData.Q.FieldByName('freq').AsString);
      Writeln(f,tmp);

      tmp := '<RST_SENT' + dmUtils.StringToADIF(dmData.Q.FieldByName('rst_s').AsString);
      Writeln(f,tmp);

      tmp := '<RST_RCVD' + dmUtils.StringToADIF(dmData.Q.FieldByName('rst_r').AsString);
      Writeln(f,tmp);

      if (dmData.Q.FieldByName('remarks').AsString<>'') and cqrini.ReadBool('LoTW', 'ExpComment', True) then
      begin
        tmp := '<COMMENT' + dmUtils.StringToADIF(dmData.Q.FieldByName('remarks').AsString);
        Writeln(f,tmp);
        tmp := '<QSLMSG' + dmUtils.StringToADIF(dmData.Q.FieldByName('remarks').AsString);
        Writeln(f,tmp)
      end;

      tmp := '<APP_EQSL_QTH_NICKNAME'+dmUtils.StringToADIF(edtQTH.Text);
      Writeln(f,tmp);

      Writeln(f,'<EOR>');
      Writeln(f);
      if (nr mod 100 = 0) then
      begin
        lblInfo.Repaint;
        Application.ProcessMessages
      end;
      inc(nr);
      Inc(QSOCount);
      dmData.Q.Next
    end
  except
    on E : Exception do
    begin
      mStat.Lines.Add('Export to '+FileName+' failed!'+LineEnding+'Error:'+E.Message);
      Result := False
    end
  end
  finally
    lblInfo.Caption := 'Done ...';
    dmData.Q.Close;
    dmData.trQ.Rollback;
    CloseFile(f)
  end
end;

procedure TfrmeQSLUpload.FormShow(Sender : TObject);
begin
  dmUtils.LoadWindowPos(frmeQSLUpload);
  edtQTH.Text := cqrini.ReadString('eQSL','QTH','')
end;

procedure TfrmeQSLUpload.FormClose(Sender : TObject;
  var CloseAction : TCloseAction);
begin
  dmUtils.SaveWindowPos(frmeQSLUpload);
  cqrini.WriteString('eQSL','QTH',edtQTH.Text)
end;

procedure TfrmeQSLUpload.btnUploadClick(Sender : TObject);
var
  FileName : String;
begin
  mStat.Clear;
  edtQTH.Text := trim(edtQTH.Text);
  if (edtQTH.Text = '') then
  begin
    Application.MessageBox('QTH field is empty!','Error',mb_ok+mb_IconError);
    edtQTH.SetFocus;
    exit
  end;
  if (cqrini.ReadString('LoTW','eQSLName','') = '') or (cqrini.ReadString('LoTW','eQSLName','')='') then
  begin
    Application.MessageBox('Username or password is empty!','Error',mb_ok+mb_IconError);
    exit
  end;
  FileName := dmData.HomeDir+'eQSL'+PathDelim+FormatDateTime('yyyy-mm-dd_hh-mm-ss',now)+'.adi';
  try
    if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) then
      dmData.DisableOnlineLogSupport;

    if ExportData(FileName) then
    begin
      if (QSOCount > 1000) then
      begin
        if Application.MessageBox('It seems that you have a lot of QSO to upload. eQSL server can process about '+
                                  '1000 qso per minute, so maybe it will be better to log into eQSL website and '+
                                  'use background upload mode.'+LineEnding+LineEnding+'Do you want to continue?',
                                  'Question ...',mb_YesNo+mb_IconQuestion) = idYes then
          Upload(FileName)
        else
          Close()
      end
      else
        Upload(FileName)
    end

  finally
    if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) then
      dmData.EnableOnlineLogSupport(False)
  end
end;

procedure TfrmeQSLUpload.btnPreferencesClick(Sender : TObject);
begin
  with TfrmPreferences.Create(self) do
  try
    pgPreferences.ActivePage := tabLoTW;
    ShowModal
  finally
    Free
  end
end;

function TfrmeQSLUpload.HttpPostFile(const URL, FieldName, FileName: string;
  const Data: TStream; const ResultData: TStrings; var err : String): Boolean;
var
  HTTP: THTTPSend;
  Bound, s: string;
begin
  err := '';
  Bound := IntToHex(Random(MaxInt), 8) + '_Synapse_boundary';
  HTTP := THTTPSend.Create;
  try
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.ProxyUser := cqrini.ReadString('Program','User','');
    HTTP.ProxyPass := cqrini.ReadString('Program','Passwd','');
    HTTP.Sock.OnStatus := @SockCallBack;
    s := '--' + Bound + CRLF;
    s := s + 'content-disposition: form-data; name="' + FieldName + '";';
    s := s + ' filename="' + FileName +'"' + CRLF;
    s := s + 'Content-Type: Application/octet-string' + CRLF + CRLF;
    WriteStrToStream(HTTP.Document, s);
    HTTP.Document.CopyFrom(Data, 0);
    s := CRLF + '--' + Bound + '--' + CRLF;
    WriteStrToStream(HTTP.Document, s);
    HTTP.MimeType := 'multipart/form-data; boundary=' + Bound;
    //eQSL server can handle only 1000QSO per minute
    HTTP.Timeout := 100000*((QSOCount div 1000)+1);
    Writeln('Timeout:',HTTP.Timeout div 1000, 's');
    Writeln('QSO count:',QSOCount);
    Result := HTTP.HTTPMethod('POST', URL);
    if Result then
      ResultData.LoadFromStream(HTTP.Document)
    else
      err := IntToStr(HTTP.Sock.LastError)+' - '+HTTP.Sock.LastErrorDesc
  finally
    HTTP.Free
  end
end;


function TfrmeQSLUpload.FormatOutput(ResultText: String) : String;
begin
  ResultText := copy(ResultText,Pos('<BODY>',ResultText)+6,Length(ResultText));
  ResultText := copy(ResultText,1,Pos('</BODY>',ResultText)-1);
  ResultText := StringReplace(ResultText,'<BR>',LineEnding,[rfReplaceAll, rfIgnoreCase]);
  Result     := trim(dmUtils.StripHTML(ResultText))
end;

procedure TfrmeQSLUpload.Upload(const FileName : String);
const
  CR = #$0d;
  LF = #$0a;
  CRLF = CR + LF;
var
  m    : TMemoryStream;
  url : String = '';
  res  : Boolean;
  l    : TStringList;
  suc  : Boolean = False;
  err  : String;
  date : String;
begin
  lblInfo.Caption := '';
  Application.ProcessMessages;
  mStat.Lines.Add('');
  url  := 'http://www.eqsl.cc/qslcard/ImportADIF.cfm';
  mStat.Lines.Add('eQSL server can process about 1000 QSO per minute. If you have ');
  mStat.Lines.Add('a lot of QSO to upload, it will take long time. So please be patient.');
  mStat.Lines.Add('');
  mStat.Lines.Add('Uploading file ...');
  mStat.Lines.Add('Size: ');
  mStat.Lines.Add('After upload, please wait, eQSL will return some information!');
  m := TMemoryStream.Create;
  l := TStringList.Create;
  try
    m.LoadFromFile(FileName);
    lblInfo.Caption := 'Waiting for eQSL server ...';
    Res := HttpPostFile(url,'Filename',FileName,m,l,err);
    if Res then
    begin
      mStat.Lines.Add(FormatOutput(l.Text));
      if dmData.DebugLevel >= 1 then Writeln(l.Text);
      suc := Pos('ERROR',upcase(l.Text)) = 0
    end
    else begin
      mStat.Lines.Add('Error: '+err);
      suc := False
    end;
    mStat.Lines.Add('');
    mStat.Lines.Add('');
    mStat.Lines.Add('');
    Application.ProcessMessages;
    //mStat.VertScrollBar.Position := mStat.VertScrollBar.Range;
    mStat.SelStart := Length(mStat.Text)-1;
    if suc then
    begin
      date := FormatDateTime('yyyy-mm-dd',now);
      dmData.Q1.Close();
      if dmData.trQ1.Active then dmData.trQ1.Rollback;
      dmData.trQ1.StartTransaction;
      dmData.trQ.StartTransaction;
      try
        dmData.Q.Open;
        dmData.Q.First;
        while not dmData.Q.Eof do
        begin
          dmData.Q1.SQL.Text := 'update cqrlog_main set eqsl_qsl_sent = ' + QuotedStr('Y') +
                               ',eqsl_qslsdate = ' + QuotedStr(date) + 'where id_cqrlog_main = '+
                               dmData.Q.FieldByName('id_cqrlog_main').AsString;
          if dmData.DebugLevel>=1 then Writeln(dmData.Q1.SQL.Text);
          dmData.Q1.ExecSQL;
          dmData.Q.Next
        end
      finally
        dmData.Q.Close();
        dmData.trQ1.Commit;
        dmData.trQ.Rollback;
        lblInfo.Caption := 'Upload complete!'
      end
    end
  finally
    l.Free;
    m.Free
  end
end;

end.

