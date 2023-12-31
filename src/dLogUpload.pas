unit dLogUpload;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, FileUtil, LResources,
  dynlibs, lcltype, ExtCtrls, sqlscript, process, mysql51dyn, ssl_openssl_lib,
  mysql55dyn, mysql55conn, mysql51conn, db, httpsend, blcksock, synautil, Forms,
  Graphics, mysql56conn, mysql56dyn, mysql57dyn, mysql57conn,
  lNet, lNetComponents, laz2_DOM, laz2_XMLWrite, md5;

const
  C_HAMQTH       = 'HamQTH';
  C_CLUBLOG      = 'ClubLog';
  C_HRDLOG       = 'HRDLog';
  C_UDPLOG       = 'UDPLog';
  C_ALLDONE      = 'ALLDONE';
  C_CLUBLOG_API  = '21507885dece41ca049fec7fe02a813f2105aff2';
type
  TWhereToUpload = (upHamQTH, upClubLog, upHrdLog, upUDPLog);

type

  { TdmLogUpload }

  TdmLogUpload = class(TDataModule)
    Q: TSQLQuery;
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
    function  EncodeBandForUDPLog(band : String) : String;
    function  ParseHrdLogOutput(Output : String; var Response : String) : Integer;
    procedure AddQSOKeyValue(id_cqrlog_main : Integer; data : TStringList);
  public
    csLogUpload  : TRTLCriticalSection;

    function  UploadLogData(where : TWhereToUpload; cmd: String; data : TStringList; var Response : String; var ResultCode : Integer) : Boolean;
    function  UploadLogDataHTTP(Url : String; data : TStringList; var Response : String; var ResultCode : Integer) : Boolean;
    function  UploadLogDataUDP(cmd : String; data : TStringList; var Response : String; var ResultCode : Integer) : Boolean;
    function  CheckUserUploadSettings(where : TWhereToUpload) : String;
    function  GetLogUploadColor(where : TWhereToUpload) : Integer;
    function  GetUploadUrl(where : TWhereToUpload; cmd : String) : String;
    function  GetResultMessage(where : TWhereToUpload; Response : String; ResultCode : Integer; var ErrorCode : Integer) : String;
    function  LogUploadEnabled : Boolean;

    procedure MarkAsUploadedToAllOnlineLogs;
    procedure MarkAsUploaded(LogName : String);
    procedure PrepareUserInfoHeader(where : TWhereToUpload; data : TStringList);
    procedure PrepareInsertHeader(where : TWhereToUpload; id_log_changes,id_cqrlog_main : Integer; data : TStringList);
    procedure PrepareDeleteHeader(where : TWhereToUpload; id_log_changes,id_cqrlog_main : Integer; data : TStringList);
    procedure MarkAsUploaded(LogName : String; id_log_changes : Integer);
    procedure MarkAsUpDeleted(id_log_upload : Integer);
    procedure DisableOnlineLogSupport;
    procedure EnableOnlineLogSupport(RemoveOldChanges : Boolean = True);
  end;

var
  dmLogUpload: TdmLogUpload;

implementation
  {$R *.lfm}

uses dData, dDXCluster, uMyIni;

procedure TdmLogUpload.DataModuleCreate(Sender: TObject);
var
  i : Integer;
begin
  InitCriticalSection(csLogUpload);

  dmData.LogUploadCon.KeepConnection := True;
  for i:=0 to ComponentCount-1 do
  begin
    if Components[i] is TSQLQuery then
      (Components[i] as TSQLQuery).DataBase := dmData.LogUploadCon;
    if Components[i] is TSQLTransaction then
      (Components[i] as TSQLTransaction).DataBase := dmData.LogUploadCon
  end
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

function TdmLogUpload.UploadLogData(where : TWhereToUpload; cmd: String; data : TStringList; var Response : String; var ResultCode : Integer) : Boolean;
begin
  case where of
    upUDPLog  : Result := UploadLogDataUDP(cmd,data,Response,ResultCode)
  else
    Result := UploadLogDataHTTP(dmLogUpload.GetUploadUrl(where,cmd), data, Response, ResultCode);
  end; // case
end;

function TdmLogUpload.UploadLogDataHTTP(Url : String; data : TStringList; var Response : String; var ResultCode : Integer) : Boolean;
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
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');

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

function TdmLogUpload.UploadLogDataUDP(cmd : String; data : TStringList; var Response : String; var ResultCode : Integer) : Boolean;
var
  i       : Integer;
  Key     : String;
  Value   : String;
  Address : String;
  udp     : TLUDPComponent;
  n       : Integer;
  Doc     : TXMLDocument;
  RootNode,ItemNode,TextNode: TDOMNode;
  msg     : TStringStream;
  msg_len : Integer;
  sent    : Integer;
begin
  Result := False;
  sent := 0;
  Address := '';

  try
    Doc := TXMLDocument.Create;
    if (cmd='DELETE') then
      RootNode := Doc.CreateElement('contactdelete')
    else if (cmd='UPDATE') then
      RootNode := Doc.CreateElement('contactreplace')
    else // INSERT
      RootNode := Doc.CreateElement('contactinfo');
    Doc.Appendchild(RootNode);
    RootNode := Doc.DocumentElement;

    for i:=0 to data.Count-1 do
    begin
      Key   := copy(data.Strings[i],1,Pos('=',data.Strings[i])-1);
      Value := copy(data.Strings[i],Pos('=',data.Strings[i])+1,Length(data.Strings[i])-Pos('=',data.Strings[i])+1);
      case Key of
        'Address' : Address := Value;
      else
        ItemNode := Doc.CreateElement(Key);
        TextNode := Doc.CreateTextNode(Value);
        ItemNode.AppendChild(TextNode);
        RootNode.AppendChild(ItemNode)
      end; // case
    end;

    if (Address='') then
    begin
      ResultCode := 500;
      Response   := 'Address not set; check config';
      Result := True;
      exit
    end;

    try
      msg := TStringStream.Create('', TEncoding.UTF8);
      WriteXMLFile(Doc, msg);
    except
      FreeAndNil(msg);
      raise;
    end;
  finally
    FreeAndNil(Doc);
  end;
  msg_len := Length(msg.DataString);

  try
    udp := TLUDPComponent.Create(nil);
    n := Pos(':', Address);
    if n > 0 then
    begin
      udp.Host := Copy(Address, 1, n-1);
      udp.Port := StrToInt(Copy(Address, n+1, Length(Address)));
    end
    else
    begin
      udp.Host := Address;
      udp.Port := 5444;
    end;

    if udp.Connect then sent := udp.SendMessage(msg.DataString, Address);
  finally
    if udp.Connected then udp.Disconnect;
    FreeAndNil(udp);
    FreeAndNil(msg);
  end;

  if (sent = msg_len) then
  begin
    ResultCode := 200;
    Response := 'Success';
    Result := True;
  end
  else
  begin
    ResultCode := 400;
    Response := 'Failed. Only sent ' + IntToStr(sent) + ' of ' + IntToStr(msg_len) + ' bytes to ' + Address;
    Result := False
  end;

end;


procedure TdmLogUpload.MarkAsUploadedToAllOnlineLogs;
var
  err : Boolean = False;
  max : Integer;
begin
  EnterCriticalsection(csLogUpload);
  try try
    Q.Close;
    if trQ.Active then trQ.RollBack;
    trQ.StartTransaction;
    Q.SQL.Text := 'insert into log_changes (cmd) values('+QuotedStr(C_ALLDONE)+')';
    if dmData.DebugLevel >= 1 then Writeln(Q.SQL.Text);
    Q.ExecSQL;

    Q.SQL.Text := 'select max(id) from log_changes';
    Q.Open;
    max := Q.Fields[0].AsInteger;
    Q.Close;

    Q.SQL.Text := 'update upload_status set id_log_changes='+IntToStr(max);
    if dmData.DebugLevel >= 1 then Writeln(Q.SQL.Text);
    Q.ExecSQL;

    Q.SQL.Text := 'delete from log_changes where id < '+IntToStr(max);
    if dmData.DebugLevel >= 1 then Writeln(Q.SQL.Text);
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
    Q.Close;
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
    Q.Close;
    if trQ.Active then trQ.RollBack;
    trQ.StartTransaction;
    Q.SQL.Text := 'insert into log_changes (cmd) values('+QuotedStr(LogName+'DONE')+')';
    if dmData.DebugLevel >= 1 then Writeln(Q.SQL.Text);
    Q.ExecSQL;

    Q.SQL.Text := 'select max(id) from log_changes';
    Q.Open;
    max := Q.Fields[0].AsInteger;

    Q.Close;
    Q.SQL.Text := 'update upload_status set id_log_changes='+IntToStr(max);
    if dmData.DebugLevel >= 1 then Writeln(Q.SQL.Text);
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
    Q.Close;
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
  Q1.Close;
  if trQ1.Active then trQ1.Rollback;

  trQ1.StartTransaction;
  try
    Q1.SQL.Text := 'select * from cqrlog_main where id_cqrlog_main = '+IntToStr(id_cqrlog_main);
    Q1.Open;

    if Q1.Fields[0].IsNull then
    begin  //this shouldn't happen
      if dmData.DebugLevel>=1 then Writeln('GetQSOInAdif: QSO not found in the log. ID:', id_cqrlog_main);
      Result := '<EOR>';
      exit
    end;
    {
    data   := DateToStr(Q1.Fields[1].AsDateTime);
    data   := copy(data,1,4) + copy(data,6,2) + copy(data,9,2);
    data   := GetAdifValue('QSO_DATE',data);
    Result := data;

    data   := Q1.Fields[2].AsString;
    data   := copy(data,1,2) + copy(data,4,2);
    data   := GetAdifValue('TIME_ON',data);
    Result := Result + data;
    }

    data   := Q1.Fields[3].AsString;
    data   := copy(data,1,2) + copy(data,4,2);
    data   := GetAdifValue('TIME_OFF',data);
    Result := Result + data;

    {
    data   := RemoveSpaces(Q1.Fields[4].AsString);
    data   := GetAdifValue('CALL',data);
    Result := Result + data;

    Result := Result + GetAdifValue('FREQ',CurrToStr(Q1.Fields[5].AsCurrency));
    Result := Result + GetAdifValue('BAND',Q1.FieldByName('band').AsString);
    Result := Result + GetAdifValue('MODE',Q1.Fields[6].AsString);
    }

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
      Result := Result + band[i]
  end
end;

function TdmLogUpload.EncodeBandForUDPLog(band : String) : String;
var
  i : Integer;
begin
  case band of
    '160M'   : Result := '1.8';
    '80M'    : Result := '3.5';
    '60M'    : Result := '5';
    '40M'    : Result := '7';
    '30M'    : Result := '10';
    '20M'    : Result := '14';
    '17M'    : Result := '18';
    '15M'    : Result := '21';
    '12M'    : Result := '24';
    '10M'    : Result := '28';
    '6M'     : Result := '50';
    '4M'     : Result := '70';
    '2M'     : Result := '144';
    '1.25M'  : Result := '222';
    '70CM'   : Result := '420';
    '33CM'   : Result := '902';
    '23CM'   : Result := '1240';
    '13CM'   : Result := '2300';
    '9CM'    : Result := '3300';
    '6CM'    : Result := '5650';
    '3CM'    : Result := '10000';
    '1.25CM' : Result := '24000';
    '6MM'    : Result := '47000';
    '4MM'    : Result := '76000';
    '2MM'    : Result := '142000';
    '1MM'    : Result := '241000';
  else
    Result := '';
  end;
end;

function TdmLogUpload.ParseHrdLogOutput(Output : String; var Response : String) : Integer;
var
  msg    : String = '';
  ErrPos : Integer;
begin
  Result := 200;
  // 200 OK, 500 Internal error, 400 QSO rejected, 403 Forbidden, 404 QSO not found
  ErrPos := Pos('<error>',Output);
  if ( ErrPos > 0) then
  begin
    Response := copy(Output,ErrPos+7,Pos('</error>',Output)-ErrPos-7);

    if (LowerCase(msg)='unknown user') then
      Result := 403
    else if (LowerCase(msg)='unable to find qso') then
      Result := 404
    else
      Result := 500
  end
end;

procedure TdmLogUpload.AddQSOKeyValue(id_cqrlog_main : Integer; data : TStringList);
begin
  Q1.Close;
  if trQ1.Active then trQ1.Rollback;

  trQ1.StartTransaction;
  try
    Q1.SQL.Text := 'select * from cqrlog_main where id_cqrlog_main = '+IntToStr(id_cqrlog_main);
    Q1.Open;

    if Q1.Fields[0].IsNull then
    begin  //this should not happen
      if dmData.DebugLevel>=1 then Writeln('AddQsoKeyValue: QSO not found in the log. ID:', id_cqrlog_main);
      exit
    end;

    data.Add('snt='+Q1.FieldByName('rst_s').AsString);
    data.Add('rcv='+Q1.FieldByName('rst_r').AsString);
    data.Add('name='+Q1.FieldByName('name').AsString);
    data.Add('qth='+Q1.FieldByName('qth').AsString);
    data.Add('gridsquare='+Q1.FieldByName('loc').AsString);
    data.Add('continent='+Q1.FieldByName('cont').AsString);
    data.Add('zone='+Q1.FieldByName('waz').AsString);
    {
      data.Add('zone='+Q1.FieldByName('itu').AsString);
    }
    data.Add('power='+Q1.FieldByName('pwr').AsString);
    data.Add('contestname='+Q1.FieldByName('contestname').AsString);
    data.Add('operator='+Q1.FieldByName('operator').AsString);
    if cqrini.ReadBool('OnlineLog','UdIncExch',True) then
    begin
      data.Add('sntnr='+Q1.FieldByName('stx').AsString);
      data.Add('rcvnr='+Q1.FieldByName('srx').AsString);
      data.Add('exchange1='+Q1.FieldByName('stx_string').AsString+' '+Q1.FieldByName('srx_string').AsString)
    end
    else
    begin
      data.Add('sntnr=');
      data.Add('rcvnr=');
      data.Add('exchange1=');
    end;

  finally
    Q1.Close;
    trQ1.Rollback
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
                end;
    upUDPLog :  begin
                  if (cqrini.ReadString('OnlineLog','UdAddress','')='') then
                    Result := C_UDPLOG + ' ' + Format(C_IS_NOT_SET,['Address'])
                end
  end //case
end;

function TdmLogUpload.GetLogUploadColor(where : TWhereToUpload) : Integer;
begin
  Result := clBlack;
  case where of
    upHamQTH  : Result := cqrini.ReadInteger('OnlineLog','HaColor',clBlue);
    upClubLog : Result := cqrini.ReadInteger('OnlineLog','ClColor',clRed);
    upHrdLog  : Result := cqrini.ReadInteger('OnlineLog','HrColor',clPurple);
    upUDPLog  : Result := cqrini.ReadInteger('OnlineLog','UdColor',clGreen)
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
    upUDPLog  :  begin
                   data.Add('Address='+cqrini.ReadString('OnlineLog','UdAddress',''));
                   data.Add('mycall='+cqrini.ReadString('Station', 'Call', ''));
                   data.Add('app=CQRLOG')
                 end;
  end //case
end;

procedure TdmLogUpload.PrepareInsertHeader(where : TWhereToUpload; id_log_changes,id_cqrlog_main : Integer; data : TStringList);
const
  C_SEL_LOG_CHANGES = 'select * from log_changes where id = %d';
var
  adif    : String;
  qsodate : String;
  time_on : String;
begin
  Q2.Close;
  if trQ2.Active then trQ2.RollBack;
  try
    Q2.SQL.Text := Format(C_SEL_LOG_CHANGES,[id_log_changes]);
    Q2.Open;
    if Q2.Fields[0].IsNull then exit; //this shouldn't happen

    qsodate := Q2.FieldByName('qsodate').AsString;
    qsodate := copy(qsodate,1,4) + copy(qsodate,6,2) + copy(qsodate,9,2);
    time_on := Q2.FieldByName('time_on').AsString;
    time_on := copy(time_on,1,2) + copy(time_on,4,2);

    //2022-05-05 OH1KH I do not know (I can not test) are mode+submode pairs needed with log uploads
    // or is the CqrMode ok here ???????
    //If mode+submode needed then  use dmUtils.ModeFromCqr to get mode and submode at this point
    // (look sample from fLoTWExport.pas line 453-460)
    adif := GetAdifValue('QSO_DATE',qsodate)+GetAdifValue('TIME_ON',time_on)+
            GetAdifValue('CALL',Q2.FieldByName('callsign').AsString)+
            GetAdifValue('BAND',Q2.FieldByName('band').AsString)+
            GetAdifValue('MODE',Q2.FieldByName('mode').AsString)+
            GetAdifValue('FREQ',CurrToStr(Q2.FieldByName('freq').AsCurrency));

    if (id_cqrlog_main>0) then
      adif := adif + GetQSOInAdif(id_cqrlog_main)
    else
      adif := adif+'<EOR>';

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
                   end;
      upUDPLog  :  begin
                     data.Add('IsOriginal=True');
                     data.Add('timestamp='+Q2.FieldByName('qsodate').AsString+' '+Q2.FieldByName('time_on').AsString+':00');
                     data.Add('call='+Q2.FieldByName('callsign').AsString);
                     data.Add('band='+EncodeBandForUDPLog(Q2.FieldByName('band').AsString));
                     data.Add('mode='+Q2.FieldByName('mode').AsString);
                     data.Add('rxfreq='+IntToStr(round(Q2.FieldByName('freq').AsFloat*100000)));
                     data.Add('txfreq='+IntToStr(round(Q2.FieldByName('freq').AsFloat*100000)));
                     if (id_cqrlog_main>0) then
                     begin
                        AddQSOKeyValue(id_cqrlog_main, data);
                        data.Add('ID='+MD5Print(MD5String(cqrini.ReadString('Station', 'Call', '') + ':' + IntToStr(id_cqrlog_main))));
                     end;
                     if (Q2.FieldByName('old_qsodate').AsString <> '') then
                     begin
                       data.Add('oldtimestamp='+Q2.FieldByName('old_qsodate').AsString+' '+Q2.FieldByName('old_time_on').AsString+':00');
                       data.Add('oldcall='+Q2.FieldByName('old_callsign').AsString);
                     end
                   end
    end //case
  finally
    Q2.Close;
    trQ2.RollBack
  end
end;

procedure TdmLogUpload.PrepareDeleteHeader(where : TWhereToUpload; id_log_changes,id_cqrlog_main : Integer; data : TStringList);
const
  C_SEL_LOG_CHANGES = 'select * from log_changes where id = %d';
var
  adif    : String;
  time_on : String;
  qsodate : String;
begin
  Q2.Close;
  if trQ2.Active then trQ2.RollBack;
  try
    Q2.SQL.Text := Format(C_SEL_LOG_CHANGES,[id_log_changes]);
    Q2.Open;
    if Q2.Fields[0].IsNull then exit; //this shouldn't happen

    qsodate := Q2.FieldByName('old_qsodate').AsString;
    qsodate := copy(qsodate,1,4) + copy(qsodate,6,2) + copy(qsodate,9,2);
    time_on := Q2.FieldByName('old_time_on').AsString;
    time_on := copy(time_on,1,2) + copy(time_on,4,2);

    case where of
      upHamQTH  :  begin
                     adif := GetAdifValue('OLD_QSO_DATE',qsodate)+GetAdifValue('OLD_TIME_ON',time_on)+
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
                    adif := '<qso_date:8:d>'+qsodate+'<time_on:6>'+time_on+'00'+
                            GetAdifValue('CALL',Q2.FieldByName('old_callsign').AsString);
                    data.Add('ADIFKey='+adif);
                    data.Add('Cmd=DELETE')
                   end;
      upUDPLog  :  begin
                     data.Add('timestamp='+Q2.FieldByName('old_qsodate').AsString+' '+Q2.FieldByName('old_time_on').AsString+':00');
                     data.Add('call='+Q2.FieldByName('old_callsign').AsString);
                     data.Add('band='+EncodeBandForUDPLog(Q2.FieldByName('old_band').AsString));
                     data.Add('mode='+Q2.FieldByName('old_mode').AsString);
                     data.Add('rxfreq='+IntToStr(round(Q2.FieldByName('old_freq').AsFloat*100000)));
                     data.Add('txfreq='+IntToStr(round(Q2.FieldByName('old_freq').AsFloat*100000)));
                     if (id_cqrlog_main>0) then
                     begin
                        data.Add('ID='+MD5Print(MD5String(cqrini.ReadString('Station', 'Call', '') + ':' + IntToStr(id_cqrlog_main))));
                     end
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
    upHamQTH  : Result := cqrini.ReadString('OnlineLog','HaUrl','http://www.hamqth.com/qso_realtime.php');
    upClubLog : begin
                  if (cmd='DELETE') then
                    Result := cqrini.ReadString('OnlineLog','ClUrlDel','https://clublog.org/delete.php')
                  else
                    Result := cqrini.ReadString('OnlineLog','ClUrl','https://clublog.org/realtime.php');
                end;
    upHrdLog  : Result := cqrini.ReadString('OnlineLog','HrUrl','http://robot.hrdlog.net/NewEntry.aspx');
  end //case
end;

function TdmLogUpload.GetResultMessage(where : TWhereToUpload; Response : String; ResultCode : Integer; var ErrorCode : Integer) : String;
begin
  Result     := '';
  ErrorCode  := 0;
  Response   := Trim(Response);

  case where of
    upHamQTH  : begin
                  case ResultCode of
                    200 : Result := 'OK';
                    500 : begin
                            Result     := Response;
                            ErrorCode  := 1;
                          end;//something wrong with HamQTH server
                    400 : begin
                            Result := Response;
                            if (Response = 'QSO already exists in the log')  then
                              Result := 'Already exists'
                            else if (Response = 'QSO not found in the log!') then
                              ErrorCode := 0
                            else begin
                              ErrorCode  := 2; //QSO rejected; continue with next one
                              Result     := Response
                            end
                          end;
                    403 : begin
                            Result     := 'Access denied';
                            Errorcode := 1
                          end
                    else begin
                      Result     := Response;
                      ErrorCode  := 1
                    end
                  end
                end;
    upClubLog : begin
                  case ResultCode of
                    200 : Result := 'OK';
                    400 : begin
                            Result     := Response;
                            if (Pos('skipping qso',LowerCase(Response))=0) then //consider skiping QSO as non fatal error, the app can live with it :)
                              ErrorCode := 2
                          end;
                    403 : begin
                            Result := 'Access denied';
                            ErrorCode := 1
                          end;
                    500 : begin
                            Result := 'Internal error';
                            ErrorCode := 2
                          end;
                    404 : begin
                            Result     := Response;
                            if (Response = 'QSO Details Not Matched') then
                            begin
                                ErrorCode := 2;
                            end
                            else
                            begin
                                ErrorCode := 1;
                            end;
                          end
                  end //case
                end;
    upHrdLog  : begin
                  case ParseHrdLogOutput(Response,Result) of
                    200 : Result := 'OK';
                    400 : ErrorCode := 2;
                    403 : ErrorCode := 2;
                    500 : ErrorCode := 1;
                    404 : ErrorCode := 2
                  end //case
                end;
    upUDPLog  : begin
                  case ResultCode of
                    200 : Result := 'OK';
                    400 : begin
                            Result     := Response;
                            ErrorCode := 2
                          end;
                    500 : begin
                            Result     := Response;
                            ErrorCode := 1
                          end
                  end //case
                end
  end //case
end;

procedure TdmLogUpload.MarkAsUploaded(LogName : String; id_log_changes : Integer);
const
  C_UPD = 'update upload_status set id_log_changes = %d where logname = %s';
var
  err : Boolean = False;
begin
  Q2.Close;
  if trQ2.Active then trQ2.RollBack;
  try try
    Q2.SQL.Text := Format(C_UPD,[id_log_changes,QuotedStr(LogName)]);
    if dmData.DebugLevel >= 1 then Writeln(Q2.SQL.Text);
    Q2.ExecSQL
  except
    on E : Exception do
    begin
      err := True;
      Writeln(E.Message)
    end
  end
  finally
    Q2.Close;
    if err then
      trQ2.Rollback
    else
      trQ2.Commit
  end
end;

procedure TdmLogUpload.MarkAsUpDeleted(id_log_upload : Integer);
const
  C_UPD = 'update log_changes set upddeleted=0 where id = %d';
var
  err : Boolean = False;
begin
  Q2.Close;
  if trQ2.Active then trQ2.RollBack;
  try try
    Q2.SQL.Text := Format(C_UPD,[id_log_upload]);
    if dmData.DebugLevel >= 1 then Writeln(Q2.SQL.Text);
    Q2.ExecSQL
  except
    on E : Exception do
    begin
      err := True;
      Writeln(E.Message)
    end
  end
  finally
    Q2.Close;
    if err then
      trQ2.Rollback
    else
      trQ2.Commit
  end
end;

function TdmLogUpload.LogUploadEnabled : Boolean;
begin
  Result := cqrini.ReadBool('OnlineLog','HaUp',False) or
            cqrini.ReadBool('OnlineLog','ClUp',False) or
            cqrini.ReadBool('OnlineLog','HrUp',False) or
            cqrini.ReadBool('OnlineLog','UdUp',False)
end;

procedure TdmLogUpload.DisableOnlineLogSupport;
const
  C_DROP = 'DROP TRIGGER IF EXISTS %s';
var
  t  : TSQLQuery;
  tr : TSQLTransaction;
  i  : Integer;
begin
  t := TSQLQuery.Create(nil);
  tr := TSQLTransaction.Create(nil);
  try
    t.Transaction := tr;
    tr.DataBase   := dmData.MainCon;
    t.DataBase    := dmData.MainCon;

    try
      t.SQL.Text := Format(C_DROP,['cqrlog_main_bd']);
      if dmData.DebugLevel>=1 then Writeln(t.SQL.Text);
      t.ExecSQL;

      t.SQL.Text := Format(C_DROP,['cqrlog_main_ai']);
      if dmData.DebugLevel>=1 then Writeln(t.SQL.Text);
      t.ExecSQL;

      t.SQL.Text := Format(C_DROP,['cqrlog_main_bu']);
      if dmData.DebugLevel>=1 then Writeln(t.SQL.Text);
      t.ExecSQL;

      tr.Commit
    except
      tr.Rollback
    end
  finally
    t.Close;
    FreeAndNil(t);
    FreeAndNil(tr)
  end
end;

procedure TdmLogUpload.EnableOnlineLogSupport(RemoveOldChanges : Boolean = True);
const
  C_DEL = 'DELETE FROM %s';
var
  t  : TSQLQuery;
  tr : TSQLTransaction;
  i  : Integer;
begin
  t := TSQLQuery.Create(nil);
  tr := TSQLTransaction.Create(nil);
  try
    t.Transaction := tr;
    tr.DataBase   := dmData.MainCon;
    t.DataBase    := dmData.MainCon;
    if RemoveOldChanges then
    begin
      try
        tr.StartTransaction;
        t.SQL.Text := Format(C_DEL,['upload_status']);
        if dmData.DebugLevel>=1 then Writeln(t.SQL.Text);
        t.ExecSQL;

        t.SQL.Text := Format(C_DEL,['log_changes']);
        if dmData.DebugLevel>=1 then Writeln(t.SQL.Text);
        t.ExecSQL;

        tr.Commit
      except
        on E : Exception do
        begin
          Writeln('EnableOnlineLogSupport:',E.Message);
          tr.Rollback;
          exit
        end
      end
    end;

    try
      tr.StartTransaction;
      t.SQL.Text := '';
      for i:=0 to dmData.scOnlineLogTriggers.Script.Count-1 do
      begin
        if Pos(';', dmData.scOnlineLogTriggers.Script.Strings[i]) = 0 then
          t.SQL.Add(dmData.scOnlineLogTriggers.Script.Strings[i])
        else begin
          t.SQL.Add(dmData.scOnlineLogTriggers.Script.Strings[i]);
          if dmData.DebugLevel>=1 then Writeln(t.SQL.Text);
          t.ExecSQL;
          t.SQL.Text := ''
        end
      end;

      if RemoveOldChanges then
        dmData.PrepareEmptyLogUploadStatusTables(t,tr)

    except
      on E : Exception do
      begin
        Writeln('EnableOnlineLogSupport:',E.Message);
        tr.Rollback
      end
    end
  finally
    t.Close;
    FreeAndNil(t);
    FreeAndNil(tr)
  end
end;


end.

