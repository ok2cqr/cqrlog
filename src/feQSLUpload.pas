unit feQSLUpload;

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,FileUtil,LResources,Forms,Controls,Graphics,Dialogs,StdCtrls,
  ExtCtrls, httpsend, blcksock, synautil, lcltype, dateutils, synacode, db;

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
    procedure mStatChange(Sender: TObject);
  private
    FileSize     : Int64;
    QSOCount     : Integer;
    // The selection ExportData walked, so that the marking after the
    // upload walks the same rows.
    FEqslNotExported : Boolean;
    FEqslFilterSql   : String;
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

uses dUtils,dData,uMyIni, fPreferences, uVersion, dLogUpload, dSatellite, dSqlQsl;

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
  nr         : integer = 0;
  tmp        : String = '';
  ModeOut,
  SubmodeOut : String;
  f          : TextFile;
  rows       : TDataSet;

begin
  QSOCount := 0;
  Result := True;
  FEqslNotExported := rbWebExportNotExported.Checked;
  if dmData.IsFilter then
    FEqslFilterSql := dmData.qCQRLOG.SQL.Text
  else
    FEqslFilterSql := '';
  rows := dmSqlQsl.OpenQsosForEqslRows(FEqslNotExported, FEqslFilterSql);
  rows.First;
  if rows.RecordCount = 0 then
  begin
    Application.MessageBox('Nothing to export ... ','Info ...',mb_Ok+mb_IconInformation);
    dmSqlQsl.CloseRows;
    Result := False;
    exit
  end;
  mStat.Lines.Add('Please wait, exporting QSO for eQSL ...');
  mStat.Lines.Add('Filename: '+FileName);
  Application.ProcessMessages;

  AssignFile(f,FileName);
  try try
    Rewrite(f);
    Writeln(f);
    Writeln(f, 'ADIF export from CQRLOG for Linux version '+dmData.VersionString);
    Writeln(f, 'Copyright (C) ',YearOf(now),' by Petr, OK2CQR and Martin, OK1RR');
    Writeln(f);
    Writeln(f, 'Internet: https://www.cqrlog.com');
    Writeln(f, '<ADIF_VER:5>3.1.0');
    Writeln(f,'<CREATED_TIMESTAMP:15>',FormatDateTime('YYYYMMDD hhmmss',dmUtils.GetDateTime(0)));
    Writeln(f, '<PROGRAMID:6>CQRLOG');
    Writeln(f, '<PROGRAMVERSION:',Length(cVERSION),'>',cVERSION);
    Writeln(f);
    Writeln(f,dmUtils.StringToADIF('<EQSL_USER',cqrini.ReadString('LoTW','eQSLName','')));
    Writeln(f,dmUtils.StringToADIF('<EQSL_PSWD',cqrini.ReadString('LoTW','eQSLPass','')));
    Writeln(f,'<EOH>');
    while not rows.Eof do
    begin
      lblInfo.Caption := 'Exporting QSO nr. ' + IntToStr(Nr);
      tmp :=  rows.FieldByName('qsodate').AsString;
      tmp := copy(tmp,1,4) + copy(tmp,6,2) +copy(tmp,9,2);
      tmp := dmUtils.StringToADIF('<QSO_DATE',tmp);
      Writeln(f, tmp);

      tmp := rows.FieldByName('time_on').AsString;
      tmp := copy(tmp,1,2) + copy(tmp,4,2);
      tmp := dmUtils.StringToADIF('<TIME_ON',tmp);
      Writeln(f, tmp);

      tmp := dmUtils.StringToADIF('<CALL' ,dmUtils.RemoveSpaces(rows.FieldByName('callsign').AsString));
      Writeln(f,tmp);

      dmUtils.ModeFromCqr(rows.FieldByName('mode').AsString,ModeOut,SubmodeOut,dmData.DebugLevel >= 1);
      tmp := dmUtils.StringToADIF('<MODE',ModeOut);
      Writeln(f,tmp);
      if SubmodeOut<>'' then
                       Begin
                         tmp := dmUtils.StringToADIF('<SUBMODE',SubmodeOut);
                         Writeln(f,tmp);
                       end;

      tmp := dmUtils.StringToADIF('<BAND' ,rows.FieldByName('band').AsString);
      Writeln(f,tmp);

      tmp := dmUtils.StringToADIF( '<FREQ' ,rows.FieldByName('freq').AsString);
      Writeln(f,tmp);

      tmp := dmUtils.StringToADIF('<RST_SENT' , rows.FieldByName('rst_s').AsString);
      Writeln(f,tmp);

      tmp := dmUtils.StringToADIF('<RST_RCVD' ,rows.FieldByName('rst_r').AsString);
      Writeln(f,tmp);

      if (rows.FieldByName('prop_mode').AsString <> '') then
      begin
        Writeln(f, dmUtils.StringToADIF('<PROP_MODE' ,rows.FieldByName('prop_mode').AsString));
        if (rows.FieldByName('prop_mode').AsString = 'SAT') then
        begin
          tmp := dmSatellite.GetSatMode(rows.FieldByName('freq').AsString, rows.FieldByName('rxfreq').AsString);
          if (tmp <> '') then
            Writeln(f, dmUtils.StringToADIF('<SAT_MODE' , tmp));
        end;
      end;

      if (rows.FieldByName('satellite').AsString <> '') then
        Writeln(f, dmUtils.StringToADIF('<SAT_NAME' ,rows.FieldByName('satellite').AsString));

      if (rows.FieldByName('rxfreq').AsString <> '') then
        Writeln(f, dmUtils.StringToADIF('<FREQ_RX' ,rows.FieldByName('rxfreq').AsString));

      if (rows.FieldByName('remarks').AsString<>'') and cqrini.ReadBool('LoTW', 'ExpComment', True) then
      begin
        tmp := dmUtils.StringToADIF('<COMMENT' ,rows.FieldByName('remarks').AsString);
        Writeln(f,tmp);
        tmp := dmUtils.StringToADIF('<QSLMSG' ,rows.FieldByName('remarks').AsString);
        Writeln(f,tmp)
      end;

      tmp := dmUtils.StringToADIF('<APP_EQSL_QTH_NICKNAME',edtQTH.Text);
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
      rows.Next
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
    dmSqlQsl.CloseRows;
    CloseFile(f)
  end
end;

procedure TfrmeQSLUpload.FormShow(Sender : TObject);
begin
  dmUtils.LoadWindowPos(frmeQSLUpload);
  edtQTH.Text := cqrini.ReadString('eQSL','QTH','');
  if dmData.IsFilter then
    begin
      rbWebExportNotExported.Caption:='Export all QSOs which have never been uploaded (bypass filter results)';
      rbWebExportAll.Caption:='Export QSOs from filter result';
      rbWebExportAll.Checked:=true;
    end
   else
    begin
      rbWebExportNotExported.Caption:='Export only QSOs which have never been uploaded';
      rbWebExportAll.Caption:='Export all QSOs in log';
      rbWebExportNotExported.Checked:=true;
    end;

end;

procedure TfrmeQSLUpload.mStatChange(Sender: TObject);
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
      dmLogUpload.DisableOnlineLogSupport;

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
      dmLogUpload.EnableOnlineLogSupport(False)
  end
end;

procedure TfrmeQSLUpload.btnPreferencesClick(Sender : TObject);
begin
  cqrini.WriteInteger('Pref', 'ActPageIdx', 18);  //set lotw tab active. Number may change if preferences page change
  with TfrmPreferences.Create(self) do
  try
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
    if dmData.DebugLevel>=1 then
     begin
        Writeln('Timeout:',HTTP.Timeout div 1000, 's');
        Writeln('QSO count:',QSOCount);
     end;
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
  rows : TDataSet;
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
  url  := 'https://www.eqsl.cc/qslcard/ImportADIF.cfm';
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
      try
        rows := dmSqlQsl.OpenQsosForEqslRows(FEqslNotExported, FEqslFilterSql);
        rows.First;
        while not rows.Eof do
        begin
          dmSqlQsl.MarkEqslSent(date, rows.FieldByName('id_cqrlog_main').AsString);
          rows.Next
        end
      finally
        dmSqlQsl.CommitBatch;
        dmSqlQsl.CloseRows;
        lblInfo.Caption := 'Upload complete!'
      end
    end
  finally
    l.Free;
    m.Free
  end
end;

end.

