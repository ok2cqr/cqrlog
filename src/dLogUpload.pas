unit dLogUpload;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, FileUtil, LResources,
  dynlibs, lcltype, ExtCtrls, sqlscript, process, mysql51dyn, ssl_openssl_lib,
  mysql55dyn, mysql55conn, mysql51conn, db, httpsend, blcksock, synautil, Forms,
  Graphics;

const
  C_HAMQTH       = 'HamQTH';
  C_CLUBLOG      = 'ClubLog';
  C_HRDLOG       = 'HRDLog';
  C_ALLDONE      = 'ALLDONE';
  C_CLUBLOG_API  = '21507885dece41ca049fec7fe02a813f2105aff2';
type
  TWhereToUpload = (upHamQTH, upClubLog, upHrdLog);

type

  { TdmLogUpload }

  TdmLogUpload = class(TDataModule)
    Q: TSQLQuery;
    scOnlineLogTriggers: TSQLScript;
    Q1: TSQLQuery;
    Q2: TSQLQuery;
    trQ2: TSQLTransaction;
    trQ1: TSQLTransaction;
    trQ: TSQLTransaction;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure Q1BeforeOpen(DataSet: TDataSet);
    procedure Q2BeforeOpen(DataSet: TDataSet);
    procedure QBeforeOpen(DataSet: TDataSet);
  private
    function  GetAdifValue(Field,Value : String) : String;
    function  RemoveSpaces(s : String) : String;
    function  GetQSOInAdif(id_cqrlog_main : Integer) : String;
    function  EncodeBandForClubLog(band : String) : String;
  public
    LogUploadCon : TSQLConnection;
    csLogUpload  : TRTLCriticalSection;

    function  UploadLogData(Url : String; data : TStringList; var Response : String; var ResultCode : Integer) : Boolean;
    function  CheckUserUploadSettings(where : TWhereToUpload) : String;
    function  GetLogUploadColor(where : TWhereToUpload) : Integer;
    function  GetUploadUrl(where : TWhereToUpload; cmd : String) : String;

    procedure MarkAsUploadedToAllOnlineLogs;
    procedure MarkAsUploaded(LogName : String);
    procedure EnableOnlineLogSupport;
    procedure PrepareUserInfoHeader(where : TWhereToUpload; data : TStringList);
    procedure PrepareInsertHeader(where : TWhereToUpload; id_cqrlog_main : Integer; data : TStringList);
    procedure PrepareDeleteHeader(where : TWhereToUpload; id_log_changes : Integer; data : TStringList);
  end;

var
  dmLogUpload: TdmLogUpload;

implementation

uses dData, dDXCluster, uMyIni;

procedure TdmLogUpload.DataModuleCreate(Sender: TObject);
var
  i : Integer;
begin
  InitCriticalSection(csLogUpload);

  if dmData.MySQLVersion < 5.5 then
    LogUploadCon := TMySQL51Connection.Create(self)
  else
    LogUploadCon := TMySQL55Connection.Create(self);

  LogUploadCon.KeepConnection := True;
  for i:=0 to ComponentCount-1 do
  begin
    if Components[i] is TSQLQuery then
      (Components[i] as TSQLQuery).DataBase := LogUploadCon;
    if Components[i] is TSQLTransaction then
      (Components[i] as TSQLTransaction).DataBase := LogUploadCon
  end;
  scOnlineLogTriggers.DataBase := LogUploadCon
end;

procedure TdmLogUpload.DataModuleDestroy(Sender: TObject);
begin
  DoneCriticalSection(csLogUpload)
end;

procedure TdmLogUpload.Q1BeforeOpen(DataSet: TDataSet);
begin
  if dmData.DebugLevel >=1 then Writeln(Q1.SQL.Text)
end;

procedure TdmLogUpload.Q2BeforeOpen(DataSet: TDataSet);
begin
  if dmData.DebugLevel >=1 then Writeln(Q2.SQL.Text)
end;

procedure TdmLogUpload.QBeforeOpen(DataSet: TDataSet);
begin
  if dmData.DebugLevel >=1 then Writeln(Q.SQL.Text)
end;

procedure TdmLogUpload.EnableOnlineLogSupport;
var
  i : Integer;
begin
  trQ.StartTransaction;
  Q.SQL.Text := '';
  for i:=0 to scOnlineLogTriggers.Script.Count-1 do
  begin
    if Pos(';',scOnlineLogTriggers.Script.Strings[i]) = 0 then
      Q.SQL.Add(scOnlineLogTriggers.Script.Strings[i])
    else begin
      Q.SQL.Add(scOnlineLogTriggers.Script.Strings[i]);
      if dmData.DebugLevel>=1 then Writeln(Q.SQL.Text);
      Q.ExecSQL;
      Q.SQL.Text := ''
    end
  end;
  trQ.Commit
  //^^ because of bug in  TSQLSript. For SQL is applied,
  //second command - no effect. My workaround works. Semicolon is a delimitter.
end;



function TdmLogUpload.UploadLogData(Url : String; data : TStringList; var Response : String; var ResultCode : Integer) : Boolean;
var
  HTTP  : THTTPSend;
  Bound : string;
  i     : Integer;
  Key   : String;
  Value : String;
  l     : TStringList;
begin
  Bound := IntToHex(Random(MaxInt), 8) + '_Synapse_boundary';
  HTTP  := THTTPSend.Create;
  l     := TStringList.Create;
  try
    for i:=0 to data.Count-1 do
    begin
      Key   := copy(data.Strings[i],1,Pos('=',data.Strings[i])-1);
      Value := copy(data.Strings[i],Pos('=',data.Strings[i])+1,Length(data.Strings[i])-Pos('=',data.Strings[i])+1);

      WriteStrToStream(HTTP.Document,
        '--' + Bound + CRLF +
        'Content-Disposition: form-data; name=' + AnsiQuotedStr(Key, '"') + CRLF +
        'Content-Type: text/plain' + CRLF +
        CRLF);
      WriteStrToStream(HTTP.Document, Value);
      WriteStrToStream(HTTP.Document,CRLF)
    end;
    WriteStrToStream(HTTP.Document,'--' + Bound + '--' + CRLF);

    HTTP.MimeType := 'multipart/form-data; boundary=' + Bound;
    if HTTP.HTTPMethod('POST',Url) then
    begin
      l.LoadFromStream(HTTP.Document);
      ResultCode := http.ResultCode;
      Response   := l.Text;
      Result     := True
    end
    else begin
      ResultCode := http.ResultCode;
      Response   := '';
      Result     := False
    end
  finally
    FreeAndNil(HTTP);
    FreeAndNil(l)
  end
end;

procedure TdmLogUpload.MarkAsUploadedToAllOnlineLogs;
var
  err : Boolean = False;
  max : Integer;
begin
  EnterCriticalsection(csLogUpload);
  try try
    if trQ.Active then trQ.RollBack;
    trQ.StartTransaction;
    Q.SQL.Text := 'insert into log_changes (cmd) values('+QuotedStr(C_ALLDONE)+')';
    Q.ExecSQL;

    Q.SQL.Text := 'select max(id) from log_changes';
    Q.Open;
    max := Q.Fields[0].AsInteger;

    Q.SQL.Text := 'update table upload_status set id_log_changes='+IntToStr(max);
    Q.ExecSQL;

    Q.SQL.Text := 'delete from log_changes where id < '+IntToStr(max);
    Q.ExecSQL
  except
    on E : Exception do
    begin
      Application.MessageBox(PChar('Could not mark all QSO as uploaded:'+E.Message),'Error ...',mb_ok+mb_IconError);
      err := True
    end
  end
  finally
    if err then
      trQ.RollBack
    else
      trQ.Commit;
    LeaveCriticalsection(csLogUpload)
  end
end;


procedure TdmLogUpload.MarkAsUploaded(LogName : String);
var
  err : Boolean = False;
  max : Integer;
begin
  EnterCriticalsection(csLogUpload);
  try try
    if trQ.Active then trQ.RollBack;
    trQ.StartTransaction;
    Q.SQL.Text := 'insert into log_changes (cmd) values('+QuotedStr(LogName+'DONE')+')';
    Q.ExecSQL;

    Q.SQL.Text := 'select max(id) from log_changes';
    Q.Open;
    max := Q.Fields[0].AsInteger;

    Q.SQL.Text := 'update table upload_status set id_log_changes='+IntToStr(max);
    Q.ExecSQL
  except
    on E : Exception do
    begin
      Application.MessageBox(PChar('Could not mark QSO as uploaded:'+E.Message),'Error ...',mb_ok+mb_IconError);
      err := True
    end
  end
  finally
    if err then
      trQ.RollBack
    else
      trQ.Commit;
    LeaveCriticalsection(csLogUpload)
  end
end;

function TdmLogUpload.GetAdifValue(Field,Value : String) : String;
begin
  if (Length(Value)=0) then
    Result := ''
  else
    Result := '<'+UpperCase(Field)+':'+ IntToStr(Length(Value)) + '>'+ Value
end;

function TdmLogUpload.RemoveSpaces(s : String) : String;
var
  i : Integer;
begin
  Result := '';
  for i := 1 to Length(s) do
  begin
    if s[i] <> #10 then
      Result := Result + s[i]
  end
end;


function TdmLogUpload.GetQSOInAdif(id_cqrlog_main : Integer) : String;
var
  data : String;
begin
  Result := '';
  if trQ1.Active then trQ1.Rollback;

  trQ1.StartTransaction;
  try
    Q1.SQL.Text := 'select * from cqrlog_main where id_cqrlog_main = '+IntToStr(id_cqrlog_main);
    Q1.Open;

    if Q1.Fields[0].IsNull then
    begin  //this shouldn't happen
      if dmData.DebugLevel>=1 then Writeln('GetQSOInAdif: QSO not found in the log. ID:', id_cqrlog_main);
      exit
    end;

    data   := DateToStr(Q1.Fields[1].AsDateTime);
    data   := copy(data,1,4) + copy(data,6,2) + copy(data,9,2);
    data   := GetAdifValue('QSO_DATE',data);
    Result := data;

    data   := Q1.Fields[2].AsString;
    data   := copy(data,1,2) + copy(data,4,2);
    data   := GetAdifValue('TIME_ON',data);
    Result := Result + data;

    data   := Q1.Fields[3].AsString;
    data   := copy(data,1,2) + copy(data,4,2);
    data   := GetAdifValue('TIME_OFF',data);
    Result := Result + data;

    data   := RemoveSpaces(Q1.Fields[4].AsString);
    data   := GetAdifValue('CALL',data);
    Result := Result + data;

    Result := Result + GetAdifValue('FREQ',CurrToStr(Q1.Fields[5].AsCurrency));
    Result := Result + GetAdifValue('BAND',Q1.FieldByName('band').AsString);
    Result := Result + GetAdifValue('MODE',Q1.Fields[6].AsString);
    Result := Result + GetAdifValue('RST_SENT',Q1.FieldByName('rst_s').AsString);
    Result := Result + GetAdifValue('RST_RCVD',Q1.FieldByName('rst_r').AsString);
    Result := Result + GetAdifValue('NAME',Q1.FieldByName('name').AsString);
    Result := Result + GetAdifValue('QTH',Q1.FieldByName('qth').AsString);

    if Q1.FieldByName('qsl_s').AsString <> '' then
      data := GetAdifValue('QSL_SENT','Y')
    else
      data := GetAdifValue('QSL_SENT','N');
    Result := Result + data;

    if Q1.FieldByName('qsl_r').AsString <> '' then
      data := GetAdifValue('QSL_RCVD','Y')
    else
      data := GetAdifValue('QSL_RCVD','N');
    Result := Result + data;

    Result := Result + GetAdifValue('QSL_VIA',Q1.FieldByName('qsl_via').AsString);
    Result := Result + GetAdifValue('IOTA',Q1.FieldByName('iota').AsString);
    Result := Result + GetAdifValue('GRIDSQUARE',Q1.FieldByName('loc').AsString);
    Result := Result + GetAdifValue('MY_GRIDSQUARE',Q1.FieldByName('my_loc').AsString);
    Result := Result + GetAdifValue('AWARD',Q1.FieldByName('award').AsString);
    Result := Result + GetAdifValue('TX_PWR',Q1.FieldByName('pwr').AsString);
    Result := Result + GetAdifValue('COMMENT',Q1.FieldByName('remarks').AsString);
    Result := Result + GetAdifValue('ITUZ',Q1.FieldByName('itu').AsString);
    Result := Result + GetAdifValue('CQZ',Q1.FieldByName('waz').AsString);
    Result := Result + GetAdifValue('STATE',Q1.FieldByName('state').AsString);
    Result := Result + GetAdifValue('CNTY',Q1.FieldByName('county').AsString);

    if Q1.FieldByName('lotw_qsls').AsString<>'' then
    begin
      data   := Q1.FieldByName('lotw_qslsdate').AsString;
      data   := copy(data,1,4) + copy(data,6,2) + copy(data,9,2);
      Result := Result + GetAdifValue('LOTW_QSL_SENT','Y');
      Result := Result + GetAdifValue('LOTW_QSLSDATE',data)
    end
    else
      Result := Result + GetAdifValue('LOTW_QSL_SENT','N');

    if Q1.FieldByName('lotw_qslr').AsString<>'' then
    begin
      data   := Q1.FieldByName('lotw_qslrdate').AsString;
      data   := copy(data,1,4) + copy(data,6,2) + copy(data,9,2);
      Result := Result + GetAdifValue('LOTW_QSL_RCVD','Y');
      Result := Result + GetAdifValue('LOTW_QSLRDATE',data)
    end
    else
      Result := Result + GetAdifValue('LOTW_QSL_RCVD','N');

    Result := Result + GetAdifValue('CONT',Q1.FieldByName('cont').AsString);

    if (Q1.FieldByName('qsls_date').AsString<>'') then
    begin
      data   := Q1.FieldByName('qsls_date').AsString;
      data   := copy(data,1,4) + copy(data,6,2) + copy(data,9,2);
      Result := Result + GetAdifValue('QSLSDATE',data)
    end;

    if (Q1.FieldByName('qslr_date').AsString<>'') then
    begin
      data   := Q1.FieldByName('qslr_date').AsString;
      data   := copy(data,1,4) + copy(data,6,2) + copy(data,9,2);
      Result := Result + GetAdifValue('QSLRDATE',data)
    end;

    if (Q1.FieldByName('eqsl_qsl_sent').AsString='Y') then
    begin
      data   := Q1.FieldByName('eqsl_qslsdate').AsString;
      data   := copy(data,1,4) + copy(data,6,2) + copy(data,9,2);

      Result := Result + GetAdifValue('EQSL_QSL_SENT','Y');
      Result := Result + GetAdifValue('EQSL_QSLSDATE',data)
    end;

    if (Q1.FieldByName('eqsl_qsl_rcvd').AsString='E') then
    begin
      data   := Q1.FieldByName('eqsl_qslrdate').AsString;
      data   := copy(data,1,4) + copy(data,6,2) + copy(data,9,2);

      Result := Result + GetAdifValue('EQSL_QSL_RCVD','Y');
      Result := Result + GetAdifValue('EQSL_QSLRDATE',data)
    end;

    if (Result <> '') then
      Result := Result + '<EOR>'
  finally
    Q1.Close;
    trQ1.Rollback
  end
end;

function TdmLogUpload.EncodeBandForClubLog(band : String) : String;
var
  i : Integer;
begin
  Result := '';
  for i := 1 to Length(band) do
  begin
    if (band[i] in ['0'..'9']) then
      Result := Result + band
  end
end;

function TdmLogUpload.CheckUserUploadSettings(where : TWhereToUpload) : String;
const
  C_IS_NOT_SET   = '%s is not set! Go to Preferences and change settings.';
begin
  Result := '';
  case where of
    upHamQTH  : begin
                  if (cqrini.ReadString('OnlineLog','HaUserName','')='') then
                    Result := C_HAMQTH + ' ' + Format(C_IS_NOT_SET,['User name'])
                  else if (cqrini.ReadString('OnlineLog','HaPasswd','')='') then
                    Result := C_HAMQTH + ' ' + Format(C_IS_NOT_SET,['Password'])
                end;
    upClubLog : begin
                  if (cqrini.ReadString('OnlineLog','ClUserName','')='') then
                    Result := C_CLUBLOG + ' ' + Format(C_IS_NOT_SET,['Callsign'])
                  else if (cqrini.ReadString('OnlineLog','ClPasswd','')='') then
                    Result := C_CLUBLOG + ' ' + Format(C_IS_NOT_SET,['Password'])
                  else if (cqrini.ReadString('OnlineLog','ClEmail','')='') then
                    Result := C_CLUBLOG + ' ' + Format(C_IS_NOT_SET,['Email'])
                end;
    upHrdLog :  begin
                  if (cqrini.ReadString('OnlineLog','HrUserName','')='') then
                    Result := C_HRDLOG + ' ' + Format(C_IS_NOT_SET,['Callsign'])
                  else if (cqrini.ReadString('OnlineLog','HrCode','')='') then
                    Result := C_HRDLOG + ' ' + Format(C_IS_NOT_SET,['Code'])
                end
  end //case
end;

function TdmLogUpload.GetLogUploadColor(where : TWhereToUpload) : Integer;
begin
  Result := clBlack;
  case where of
    upHamQTH  : Result := cqrini.ReadInteger('OnlineLog','HaColor',clBlue);
    upClubLog : Result := cqrini.ReadInteger('OnlineLog','ClColor',clRed);
    upHrdLog  : Result := cqrini.ReadInteger('OnlineLog','HrColor',clPurple)
  end
end;

procedure TdmLogUpload.PrepareUserInfoHeader(where : TWhereToUpload; data : TStringList);
begin
  case where of
    upHamQTH  :  begin
                   data.Add('u='+cqrini.ReadString('OnlineLog','HaUserName',''));
                   data.Add('p='+cqrini.ReadString('OnlineLog','HaPasswd',''));
                   data.Add('prg=CQRLOG')
                 end;
    upClublog :  begin
                   data.Add('email='+cqrini.ReadString('OnlineLog','ClEmail',''));
                   data.Add('password='+cqrini.ReadString('OnlineLog','ClPasswd',''));
                   data.Add('callsign='+cqrini.ReadString('OnlineLog','ClUserName',''));
                   data.Add('api='+C_CLUBLOG_API)
                 end;
    upHrdLog  :  begin
                   data.Add('Callsign='+cqrini.ReadString('OnlineLog','HrUserName',''));
                   data.Add('Code='+cqrini.ReadString('OnlineLog','HrCode',''));
                   data.Add('App=CQRLOG')
                 end;
  end //case
end;

procedure TdmLogUpload.PrepareInsertHeader(where : TWhereToUpload; id_cqrlog_main : Integer; data : TStringList);
var
  adif : String;
begin
  adif := GetQSOInAdif(id_cqrlog_main);
  case where of
    upHamQTH  :  begin
                   data.Add('adif='+adif);
                   data.Add('cmd=INSERT')
                 end;
    upClublog :  begin
                   data.Add('adif='+adif)
                 end;
    upHrdLog  :  begin
                   data.Add('ADIFData='+adif)
                 end
  end //case
end;

procedure TdmLogUpload.PrepareDeleteHeader(where : TWhereToUpload; id_log_changes : Integer; data : TStringList);
const
  C_SEL_LOG_CHANGES = 'select * from log_changes whre id = %d';
var
  adif    : String;
  time_on : String;
  qsodate : String;
begin
  if trQ2.Active then trQ2.RollBack;
  try
    Q2.SQL.Text := Format(C_SEL_LOG_CHANGES,[id_log_changes]);
    Q2.Open;
    if Q2.Fields[0].IsNull then exit; //this shouldn't happen

    qsodate := Q2.FieldByName('old_qso_date').AsString;
    qsodate := copy(qsodate,1,4) + copy(qsodate,6,2) + copy(qsodate,9,2);
    time_on := Q2.FieldByName('old_time_on').AsString;
    time_on := copy(time_on,1,2) + copy(time_on,4,2);

    case where of
      upHamQTH  :  begin
                     adif := GetAdifValue('OLD_QSODATE',qsodate)+GetAdifValue('OLD_TIME_ON',time_on)+
                             GetAdifValue('OLD_CALL',Q2.FieldByName('old_callsign').AsString)+
                             GetAdifValue('OLD_BAND',Q2.FieldByName('old_band').AsString)+
                             GetAdifValue('OLD_MODE',Q2.FieldByName('old_mode').AsString);
                     data.Add('adif='+adif);
                     data.Add('cmd=DELETE')
                   end;
      upClublog :  begin
                     data.Add('dxcall='+Q2.FieldByName('old_callsign').AsString);
                     data.Add('datetime='+Q2.FieldByName('old_qsodate').AsString+' '+
                               Q2.FieldByName('old_time_on').AsString+':00');
                     data.Add('bandid='+EncodeBandForClubLog(Q2.FieldByName('old_band').AsString))
                   end;
      upHrdLog  :  begin
                    adif := GetAdifValue('QSODATE',qsodate)+GetAdifValue('TIME_ON',time_on)+
                            GetAdifValue('CALL',Q2.FieldByName('old_callsign').AsString);
                    data.Add('Cmd=DELETE')
                   end
    end //case
  finally
    Q2.Close;
    trQ2.RollBack
  end
end;

function TdmLogUpload.GetUploadUrl(where : TWhereToUpload; cmd : String) : String;
begin
  Result := '';
  case where of
    upHamQTH  : Result := 'http://hamqth.com/qso_realtime.php';
    upClubLog : begin
                  if (cmd='DELETE') then
                    Result := 'https://secure.clublog.org/delete.php'
                  else
                    Result := 'https://secure.clublog.org/realtime.php'
                end;
    upHrdLog  : Result := 'http://robot.hrdlog.net/NewEntrry.aspx'
  end //case
end;

initialization
  {$I dLogUpload.lrs}

end.

