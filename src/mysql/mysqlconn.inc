
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,bufdataset,sqldb,db,dynlibs,ctypes,
 {$IFDEF mysql55}
  mysql55dyn;
 {$ELSE}
{$IFDEF mysql51}
   mysql51dyn;
{$ELSE}  
  {$IfDef mysql50}
    mysql50dyn;
  {$ELSE}
    {$IfDef mysql41}
      mysql41dyn;
    {$ELSE}
      {$IFDEF mysql4} // temporary backwards compatibility for Lazarus
        mysql40dyn;
      {$ELSE}
        mysql40dyn;
      {$EndIf}
    {$EndIf}
  {$EndIf}
{$endif}
{$endif}

Const
{$IFDEF mysql55}
   MySQLVersion = '5.5';
{$else}
{$IFDEF mysql51}
    MySQLVersion = '5.1';
{$else}    
  {$IfDef mysql50}
    MySQLVersion = '5.0';
  {$ELSE}
    {$IfDef mysql41}
      MySQLVersion = '4.1';
    {$ELSE}
      {$IFDEF mysql4} // temporary backwards compatibility for Lazarus
        MySQLVersion = '4.0';
      {$ELSE}
        MySQLVersion = '4.0';
      {$EndIf}
    {$EndIf}
  {$EndIf}
{$endif}
{$endif}
Type
  TTransactionName = Class(TSQLHandle)
  protected
  end;

  { TCursorName }

  TCursorName = Class(TSQLCursor)
  protected
    FRes: PMYSQL_RES;                   { Record pointer }
    FNeedData : Boolean;
    FStatement : String;
    Row : MYSQL_ROW;
    Lengths : pculong;                  { Lengths of the columns of the current row }
    RowsAffected : QWord;
    LastInsertID : QWord;
    ParamBinding : TParamBinding;
    ParamReplaceString : String;
    MapDSRowToMSQLRow  : array of integer;
  end;

  { TConnectionName }

  TConnectionName = class (TSQLConnection)
  private
    FHostInfo: String;
    FServerInfo: String;
    FMySQL : PMySQL;
    function GetClientInfo: string;
    function GetServerStatus: String;
    procedure ConnectMySQL(var HMySQL : PMySQL;H,U,P : pchar);
    procedure ExecuteDirectMySQL(const query : string);
    function EscapeString(const Str : string) : string;
  protected
    function StrToStatementType(s : string) : TStatementType; override;
    Procedure ConnectToServer; virtual;
    Procedure SelectDatabase; virtual;
    function MySQLDataType(AField: PMYSQL_FIELD; var NewType: TFieldType; var NewSize: Integer): Boolean;
    function MySQLWriteData(AField: PMYSQL_FIELD; FieldDef: TFieldDef; Source, Dest: PChar; Len: integer; out CreateBlob : boolean): Boolean;
    // SQLConnection methods
    procedure DoInternalConnect; override;
    procedure DoInternalDisconnect; override;
    function GetHandle : pointer; override;

    function GetAsSQLText(Field : TField) : string; overload; override;
    function GetAsSQLText(Param : TParam) : string; overload; override;

    Function AllocateCursorHandle : TSQLCursor; override;
    Procedure DeAllocateCursorHandle(var cursor : TSQLCursor); override;
    Function AllocateTransactionHandle : TSQLHandle; override;

    procedure PrepareStatement(cursor: TSQLCursor;ATransaction : TSQLTransaction;buf : string; AParams : TParams); override;
    procedure UnPrepareStatement(cursor:TSQLCursor); override;
    procedure FreeFldBuffers(cursor : TSQLCursor); override;
    procedure Execute(cursor: TSQLCursor;atransaction:tSQLtransaction;AParams : TParams); override;
    procedure AddFieldDefs(cursor: TSQLCursor; FieldDefs : TfieldDefs); override;
    function Fetch(cursor : TSQLCursor) : boolean; override;
    function LoadField(cursor : TSQLCursor;FieldDef : TfieldDef;buffer : pointer; out CreateBlob : boolean) : boolean; override;
    procedure LoadBlobIntoBuffer(FieldDef: TFieldDef;ABlobBuf: PBufBlobField; cursor: TSQLCursor;ATransaction : TSQLTransaction); override;
    function GetTransactionHandle(trans : TSQLHandle): pointer; override;
    function Commit(trans : TSQLHandle) : boolean; override;
    function RollBack(trans : TSQLHandle) : boolean; override;
    function StartdbTransaction(trans : TSQLHandle; AParams : string) : boolean; override;
    procedure CommitRetaining(trans : TSQLHandle); override;
    procedure RollBackRetaining(trans : TSQLHandle); override;
    function GetSchemaInfoSQL(SchemaType : TSchemaType; SchemaObjectName, SchemaPattern : string) : string; override;
    procedure UpdateIndexDefs(IndexDefs : TIndexDefs;TableName : string); override;
    function RowsAffected(cursor: TSQLCursor): TRowsCount; override;
  Public
    constructor Create(AOwner : TComponent); override;
    procedure GetFieldNames(const TableName : string; List :  TStrings); override;
    procedure GetTableNames(List : TStrings; SystemTables : Boolean = false); override;
    procedure CreateDB; override;
    procedure DropDB; override;
    Property ServerInfo : String Read FServerInfo;
    Property HostInfo : String Read FHostInfo;
    property ClientInfo: string read GetClientInfo;
    property ServerStatus : String read GetServerStatus;
  published
    property DatabaseName;
    property HostName;
    property KeepConnection;
    property LoginPrompt;
    property Params;
    property Port stored false;
    property OnLogin;
  end;

  { TMySQLConnectionDef }

  TMySQLConnectionDef = Class(TConnectionDef)
    Class Function TypeName : String; override;
    Class Function ConnectionClass : TSQLConnectionClass; override;
    Class Function Description : String; override;
  end;


  EMySQLError = Class(Exception);
  {$ifdef mysql55}
    TMySQL55Connection = Class(TConnectionName);
    TMySQL55ConnectionDef = Class(TMySQLConnectionDef);
    TMySQL55Transaction = Class(TTransactionName);
    TMySQL55Cursor = Class(TCursorName);
  {$else}
    {$IfDef mysql51}
      TMySQL51Connection = Class(TConnectionName);
      TMySQL51ConnectionDef = Class(TMySQLConnectionDef);
      TMySQL51Transaction = Class(TTransactionName);
      TMySQL51Cursor = Class(TCursorName);
    {$ELSE}
      {$IfDef mysql50}
        TMySQL50Connection = Class(TConnectionName);
        TMySQL50ConnectionDef = Class(TMySQLConnectionDef);
        TMySQL50Transaction = Class(TTransactionName);
        TMySQL50Cursor = Class(TCursorName);
      {$ELSE}
        {$IfDef mysql41}
          TMySQL41Connection = Class(TConnectionName);
          TMySQL41ConnectionDef = Class(TMySQLConnectionDef);
          TMySQL41Transaction = Class(TTransactionName);
          TMySQL41Cursor = Class(TCursorName);
        {$ELSE}
          {$IFDEF mysql4} // temporary backwards compatibility for Lazarus
            TMySQLConnection = Class(TConnectionName);
            TMySQL40ConnectionDef = Class(TMySQLConnectionDef);
            TMySQLTransaction = Class(TTransactionName);
            TMySQLCursor = Class(TCursorName);
          {$ELSE}
            TMySQL40Connection = Class(TConnectionName);
            TMySQL40ConnectionDef = Class(TMySQLConnectionDef);
            TMySQL40Transaction = Class(TTransactionName);
            TMySQL40Cursor = Class(TCursorName);
          {$EndIf}
        {$EndIf}
      {$endif}
    {$EndIf}
  {$ENDIF}

implementation

uses
  dbconst,
  strutils,
  dateutils,
  FmtBCD;

const
  Mysql_Option_Names : array[mysql_option] of string = ('MYSQL_OPT_CONNECT_TIMEOUT','MYSQL_OPT_COMPRESS',
     'MYSQL_OPT_NAMED_PIPE','MYSQL_INIT_COMMAND',
     'MYSQL_READ_DEFAULT_FILE','MYSQL_READ_DEFAULT_GROUP',
     'MYSQL_SET_CHARSET_DIR','MYSQL_SET_CHARSET_NAME',
     'MYSQL_OPT_LOCAL_INFILE','MYSQL_OPT_PROTOCOL',
     'MYSQL_SHARED_MEMORY_BASE_NAME','MYSQL_OPT_READ_TIMEOUT',
     'MYSQL_OPT_WRITE_TIMEOUT','MYSQL_OPT_USE_RESULT',
     'MYSQL_OPT_USE_REMOTE_CONNECTION','MYSQL_OPT_USE_EMBEDDED_CONNECTION',
     'MYSQL_OPT_GUESS_CONNECTION','MYSQL_SET_CLIENT_IP',
     'MYSQL_SECURE_AUTH'
{$IFDEF MYSQL50_UP}
     ,'MYSQL_REPORT_DATA_TRUNCATION', 'MYSQL_OPT_RECONNECT'
{$IFDEF mysql51_UP}
         ,'MYSQL_OPT_SSL_VERIFY_SERVER_CERT'
{$IFDEF mysql55}
         ,'MYSQL_PLUGIN_DIR', 'MYSQL_DEFAULT_AUTH'
{$ENDIF}
{$ENDIF}
{$ENDIF}
     );

Resourcestring
  SErrServerConnectFailed = 'Server connect failed.';
  SErrDatabaseSelectFailed = 'failed to select database: %s';
  SErrDatabaseCreate = 'Failed to create database: %s';
  SErrDatabaseDrop = 'Failed to drop database: %s';
  SErrNoData = 'No data for record';
  SErrExecuting = 'Error executing query: %s';
  SErrFetchingdata = 'Error fetching row data: %s';
  SErrGettingResult = 'Error getting result set: %s';
  SErrNoQueryResult = 'No result from query.';
  SErrVersionMismatch = '%s can not work with the installed MySQL client version: Expected (%s), got (%s).';
  SErrSettingParameter = 'Error setting parameter "%s"';
{$if FPC_FULlVERSION<= 20600}
  SerrInvalidHourMinuteSecMsec = '%d:%d:%d.%d is not a valid time specification';

var
  FSQLFormatSettings : TFormatSettings;

function TryEncodeTimeInterval(Hour, Min, Sec, MSec: word; out Time: TDateTime): boolean;
begin
 Result:= (Min<60) and (Sec<60) and (MSec<1000);
 If Result then
   Time:=TDateTime(cardinal(Hour)*3600000+cardinal(Min)*60000+cardinal(Sec)*1000+MSec)/MSecsPerDay;
end;

function EncodeTimeInterval(Hour, Minute, Second, MilliSecond: word): TDateTime;
begin
   If not TryEncodeTimeInterval(Hour,Minute,Second,MilliSecond,Result) then
     Raise EConvertError.CreateFmt(SerrInvalidHourMinuteSecMsec,
                               [Hour,Minute,Second,MilliSecond]);
end;
{$endif}

Procedure MySQLError(R : PMySQL;Msg: String;Comp : TComponent);

Var
  MySQLMsg : String;

begin
 If (R<>Nil) then
   begin
   MySQLMsg:=Strpas(mysql_error(R));
   DatabaseErrorFmt(Msg,[MySQLMsg],Comp);
   end
 else
   DatabaseError(Msg,Comp);
end;

function MysqlOption(const OptionName: string; out AMysql_Option: mysql_option) : boolean;
var AMysql_Option_i: mysql_option;
begin
  result := false;
  for AMysql_Option_i:=low(AMysql_Option) to high(AMysql_Option) do
    if sametext(Mysql_Option_Names[AMysql_Option_i],OptionName) then
      begin
      result := true;
      AMysql_Option:=AMysql_Option_i;
      break;
      end;
end;

{ TConnectionName }

function TConnectionName.StrToStatementType(s : string) : TStatementType;

begin
  s:=Lowercase(s);
  if (s='analyze') or (s='check') or (s='checksum') or (s='optimize') or (s='repair') or (s='show') then
    exit(stSelect)
  else if s='call' then
    exit(stExecProcedure)
  else
    Result := inherited StrToStatementType(s);
end;


function TConnectionName.GetClientInfo: string;

begin
  // To make it possible to call this if there's no connection yet
  InitialiseMysql;
  Try  
    Result:=strpas(mysql_get_client_info());
  Finally  
    ReleaseMysql;
  end;  
end;

function TConnectionName.GetServerStatus: String;
begin
  CheckConnected;
  Result := mysql_stat(FMYSQL);
end;

procedure TConnectionName.ConnectMySQL(var HMySQL : PMySQL;H,U,P : pchar);

Var
  APort : Cardinal;
  i,e: integer;
  AMysql_Option: mysql_option;
  OptStr: string;
  OptInt: cuint;
  Opt: pointer;

begin
  HMySQL := mysql_init(HMySQL);
  APort:=Abs(StrToIntDef(Params.Values['Port'],0));

  for i := 0 to Params.Count-1 do
    begin
    if MysqlOption(params.Names[i],AMysql_Option) then
      begin
      OptStr:=params.ValueFromIndex[i];
      val(OptStr,OptInt,e);
      if e=0 then
        Opt := @OptInt
      else
        Opt := pchar(OptStr);
      if mysql_options(HMySQL,AMysql_Option,Opt) <> 0 then
          MySQLError(HMySQL,Format(SErrSettingParameter,[params.Names[i]]),Self);
      end;
    end;

  HMySQL:=mysql_real_connect(HMySQL,PChar(H),PChar(U),Pchar(P),Nil,APort,Nil,CLIENT_MULTI_RESULTS); //CLIENT_MULTI_RESULTS is required by CALL SQL statement(executes stored procedure), that produces result sets
  If (HMySQL=Nil) then
    MySQLError(Nil,SErrServerConnectFailed,Self);

  // MySQL _Server_ version 4.1 and later
  // major_version*10000 + minor_version *100 + sub_version
  if (trim(CharSet) <> '')  and (4*10000 + 1*100 <= mysql_get_server_version(HMySQL)) then
    begin
    // Only available for mysql 5.0.7 and later...
    // if (mysql_set_character_set(HMySQL, PChar(CharSet)) <> 0) then
    if mysql_query(FMySQL,PChar('SET CHARACTER SET ''' + EscapeString(CharSet) +''''))<>0 then
      MySQLError(HMySQL,SErrExecuting,Self);
    end;
end;

function TConnectionName.GetAsSQLText(Field : TField) : string;

var esc_str : pchar;

begin
  if (not assigned(field)) or field.IsNull then Result := 'Null'
  else if field.DataType = ftString then
    Result := '''' + EscapeString(field.AsString) + ''''
  else Result := inherited GetAsSqlText(field);
end;

function TConnectionName.GetAsSQLText(Param: TParam) : string;

var esc_str : pchar;

begin
  if (not assigned(param)) or param.IsNull then Result := 'Null'
  else if param.DataType in [ftString,ftFixedChar,ftBlob,ftMemo,ftBytes,ftVarBytes] then
    Result := '''' + EscapeString(Param.AsString) + ''''
  else Result := inherited GetAsSqlText(Param);
end;


procedure TConnectionName.ConnectToServer;

Var
  H,U,P : String;

begin
  H:=HostName;
  U:=UserName;
  P:=Password;
  ConnectMySQL(FMySQL,pchar(H),pchar(U),pchar(P));
  FServerInfo := strpas(mysql_get_server_info(FMYSQL));
  FHostInfo := strpas(mysql_get_host_info(FMYSQL));
end;

procedure TConnectionName.SelectDatabase;
begin
  if mysql_select_db(FMySQL,pchar(DatabaseName))<>0 then
    MySQLError(FMySQL,SErrDatabaseSelectFailed,Self);
end;


procedure TConnectionName.CreateDB;

begin
  ExecuteDirectMySQL('CREATE DATABASE ' +DatabaseName);
end;

procedure TConnectionName.DropDB;

begin
  ExecuteDirectMySQL('DROP DATABASE ' +DatabaseName);
end;

procedure TConnectionName.ExecuteDirectMySQL(const query : string);

var H,U,P       : String;
    AMySQL      : PMySQL;

begin
  CheckDisConnected;

  InitialiseMysql;

  try
    H:=HostName;
    U:=UserName;
    P:=Password;
    AMySQL := nil;
    ConnectMySQL(AMySQL,pchar(H),pchar(U),pchar(P));
    try
      if mysql_query(AMySQL,pchar(query))<>0 then
        MySQLError(AMySQL,SErrExecuting,Self);
    finally
      mysql_close(AMySQL);
    end;
  finally
    ReleaseMysql;
  end;
end;

function TConnectionName.EscapeString(const Str: string): string;

var Len : integer;

begin
  SetLength(result,length(str)*2+1);
  Len := mysql_real_escape_string(FMySQL,pchar(Result),pchar(Str),length(Str));
  SetLength(result,Len);
end;

procedure TConnectionName.DoInternalConnect;
var
  FullVersion, 
  ClientVerStr: string;
begin
  InitialiseMysql;
  Fullversion:=strpas(mysql_get_client_info());
  ClientVerStr := copy(FullVersion,1,3);
  //If (ClientVerStr<>MySQLVersion) then
  //  Raise EInOutError.CreateFmt(SErrVersionMisMatch,[ClassName,MySQLVersion,FullVersion]);
  inherited DoInternalConnect;
  ConnectToServer;
  SelectDatabase;
end;

procedure TConnectionName.DoInternalDisconnect;
begin
  inherited DoInternalDisconnect;
  mysql_close(FMySQL);
  FMySQL:=Nil;
  ReleaseMysql;
end;

function TConnectionName.GetHandle: pointer;
begin
  Result:=FMySQL;
end;

function TConnectionName.AllocateCursorHandle: TSQLCursor;
begin
  {$IfDef mysql55}
    Result:=TMySQL55Cursor.Create;
  {$ELSE}
    {$IfDef mysql51}
      Result:=TMySQL51Cursor.Create;
    {$ELSE}
      {$IfDef mysql50}
        Result:=TMySQL50Cursor.Create;
      {$ELSE}
        {$IfDef mysql41}
          Result:=TMySQL41Cursor.Create;
        {$ELSE}
          {$IFDEF mysql4} // temporary backwards compatibility for Lazarus
            Result:=TMySQLCursor.Create;
          {$ELSE}
            Result:=TMySQL40Cursor.Create;
          {$EndIf}
        {$EndIf}
      {$EndIf}
    {$EndIf}
  {$endif}
end;

Procedure TConnectionName.DeAllocateCursorHandle(var cursor : TSQLCursor);

begin
  FreeAndNil(cursor);
end;

function TConnectionName.AllocateTransactionHandle: TSQLHandle;
begin
//  Result:=TTransactionName.Create;
  Result := nil;
end;

procedure TConnectionName.PrepareStatement(cursor: TSQLCursor;
  ATransaction: TSQLTransaction; buf: string;AParams : TParams);
begin
//  if assigned(AParams) and (AParams.count > 0) then
//    DatabaseError('Parameters (not) yet supported for the MySQL SqlDB connection.',self);
  With Cursor as TCursorName do
    begin
    FStatement:=Buf;
    if assigned(AParams) and (AParams.count > 0) then
      FStatement := AParams.ParseSQL(FStatement,false,sqEscapeSlash in ConnOptions, sqEscapeRepeat in ConnOptions,psSimulated,paramBinding,ParamReplaceString);
    if FStatementType in [stSelect,stExecProcedure] then
      FNeedData:=True;
    end
end;

procedure TConnectionName.UnPrepareStatement(cursor: TSQLCursor);
Var
  C : TCursorName;

begin
  C:=Cursor as TCursorName;
  if assigned(C.FRes) then  //ExecSQL with dataset returned
    begin
    mysql_free_result(C.FRes);
    C.FRes:=nil;
    end;
end;

procedure TConnectionName.FreeFldBuffers(cursor: TSQLCursor);

Var
  C : TCursorName;

begin
  C:=Cursor as TCursorName;
  if c.FStatementType in [stSelect,stExecProcedure] then
    c.FNeedData:=False;
  if assigned(C.FRes) then
    begin
    mysql_free_result(C.FRes);
    C.FRes:=Nil;
    end;
  SetLength(c.MapDSRowToMSQLRow,0);
  inherited;
end;

procedure TConnectionName.Execute(cursor: TSQLCursor;
  atransaction: tSQLtransaction;AParams : TParams);

Var
  C : TCursorName;
  i : integer;
  ParamNames,ParamValues : array of string;
  Res: PMYSQL_RES;

begin
  C:=Cursor as TCursorName;
  If (C.FRes=Nil) then
    begin
    if Assigned(AParams) and (AParams.count > 0) then
      begin
      setlength(ParamNames,AParams.Count);
      setlength(ParamValues,AParams.Count);
      for i := 0 to AParams.count -1 do
        begin
        ParamNames[AParams.count-i-1] := C.ParamReplaceString+inttostr(AParams[i].Index+1);
        ParamValues[AParams.count-i-1] := GetAsSQLText(AParams[i]);
        end;
      // paramreplacestring kan een probleem geven bij postgres als hij niet meer gewoon $ is?
      C.FStatement := stringsreplace(C.FStatement,ParamNames,ParamValues,[rfReplaceAll]);
      end;
    if mysql_query(FMySQL,Pchar(C.FStatement))<>0 then
      MySQLError(FMYSQL,SErrExecuting,Self)
    else
      begin
      C.RowsAffected := mysql_affected_rows(FMYSQL);
      C.LastInsertID := mysql_insert_id(FMYSQL);
      if C.FNeedData then
        repeat
        Res:=mysql_store_result(FMySQL); //returns a null pointer if the statement didn't return a result set
        if Res<>nil then
          begin
          mysql_free_result(C.FRes);
          C.FRes:=Res;
          end;
        until mysql_next_result(FMySQL)<>0;
      end;
    end;
end;

function TConnectionName.MySQLDataType(AField: PMYSQL_FIELD; var NewType: TFieldType; var NewSize: Integer): Boolean;
var ASize, ADecimals: integer;
begin
  Result := True;
  ASize := AField^.length;
  NewSize := 0;
  case AField^.ftype of
    FIELD_TYPE_LONGLONG:
      begin
      NewType := ftLargeint;
      end;
    FIELD_TYPE_TINY, FIELD_TYPE_SHORT, FIELD_TYPE_YEAR:
      begin
      NewType := ftSmallint;
      end;
    FIELD_TYPE_LONG, FIELD_TYPE_INT24:
      begin
      if AField^.flags and AUTO_INCREMENT_FLAG <> 0 then
        NewType := ftAutoInc
      else
        NewType := ftInteger;
      end;
{$ifdef mysql50_up}
    FIELD_TYPE_NEWDECIMAL,
{$endif}
    FIELD_TYPE_DECIMAL: 
      begin
        ADecimals:=AField^.decimals;
        if (ADecimals < 5) and (ASize-2-ADecimals < 15) then //ASize is display size i.e. with sign and decimal point
          NewType := ftBCD
        else if (ADecimals = 0) and (ASize < 20) then
          NewType := ftLargeInt
        else
          NewType := ftFmtBCD;
        NewSize := ADecimals;
      end;
    FIELD_TYPE_FLOAT, FIELD_TYPE_DOUBLE:
      begin
      NewType := ftFloat;
      end;
    FIELD_TYPE_TIMESTAMP, FIELD_TYPE_DATETIME:
      begin
      NewType := ftDateTime;
      end;
    FIELD_TYPE_DATE:
      begin
      NewType := ftDate;
      end;
    FIELD_TYPE_TIME:
      begin
      NewType := ftTime;
      end;
    FIELD_TYPE_VAR_STRING, FIELD_TYPE_STRING, FIELD_TYPE_ENUM, FIELD_TYPE_SET:
      begin
      // Since mysql server version 5.0.3 string-fields with a length of more
      // then 256 characters are suported
      if ASize>dsMaxStringSize then
        NewType := ftMemo
      else
        begin
        if AField^.ftype = FIELD_TYPE_STRING then
          NewType := ftFixedChar
        else
          NewType := ftString;
{$IFDEF MYSQL50_UP}
        if AField^.charsetnr = 63 then //BINARY vs. CHAR, VARBINARY vs. VARCHAR
          if NewType = ftFixedChar then
            NewType := ftBytes
          else
            NewType := ftVarBytes;
{$ENDIF}
        NewSize := ASize;
        end;
      end;
    FIELD_TYPE_BLOB:
      begin
{$IFDEF MYSQL50_UP}
      if AField^.charsetnr = 63 then //character set is binary
        NewType := ftBlob
      else
        NewType := ftMemo;
{$ELSE}
      NewType := ftBlob;
{$ENDIF}
      end;
{$IFDEF MYSQL50_UP}
    FIELD_TYPE_BIT:
      NewType := ftLargeInt;
{$ENDIF}
  else
    Result := False;
  end;
end;

procedure TConnectionName.AddFieldDefs(cursor: TSQLCursor;
  FieldDefs: TfieldDefs);

var
  C : TCursorName;
  I, TF, FC: Integer;
  field: PMYSQL_FIELD;
  DFT: TFieldType;
  DFS: Integer;

begin
//  Writeln('MySQL: Adding fielddefs');
  C:=(Cursor as TCursorName);
  If (C.FRes=Nil) then
    begin
//    Writeln('res is nil');
    MySQLError(FMySQL,SErrNoQueryResult,Self);
    end;
//  Writeln('MySQL: have result');
  FC:=mysql_num_fields(C.FRes);
  SetLength(c.MapDSRowToMSQLRow,FC);

  TF := 1;
  For I:= 0 to FC-1 do
    begin
    field := mysql_fetch_field_direct(C.FRES, I);
//    Writeln('MySQL: creating fielddef ',I+1);

    if MySQLDataType(field, DFT, DFS) then
      begin
      TFieldDef.Create(FieldDefs, FieldDefs.MakeNameUnique(field^.name), DFT, DFS,
                       (field^.flags and (AUTO_INCREMENT_FLAG or NOT_NULL_FLAG {$IFDEF MYSQL50_UP}or NO_DEFAULT_VALUE_FLAG{$ENDIF})) = (NOT_NULL_FLAG {$IFDEF MYSQL50_UP}or NO_DEFAULT_VALUE_FLAG{$ENDIF}),
                       TF);
      c.MapDSRowToMSQLRow[TF-1] := I;
      inc(TF);
      end
    end;
//  Writeln('MySQL: Finished adding fielddefs');
end;

function TConnectionName.Fetch(cursor: TSQLCursor): boolean;

Var
  C : TCursorName;

begin
  C:=Cursor as TCursorName;
  C.Row:=MySQL_Fetch_row(C.FRes);
  Result:=(C.Row<>Nil);
  if Result then
    C.Lengths := mysql_fetch_lengths(C.FRes)
  else
    C.Lengths := nil;
end;

function TConnectionName.LoadField(cursor : TSQLCursor;
  FieldDef : TfieldDef;buffer : pointer; out CreateBlob : boolean) : boolean;

var
  field: PMYSQL_FIELD;
  C : TCursorName;
  i : integer;

begin
//  Writeln('LoadFieldsFromBuffer');
  C:=Cursor as TCursorName;
  if (C.Row=nil) or (C.Lengths=nil) then
     begin
  //   Writeln('LoadFieldsFromBuffer: row=nil');
     MySQLError(FMySQL,SErrFetchingData,Self);
     end;

  i := c.MapDSRowToMSQLRow[FieldDef.FieldNo-1];
  field := mysql_fetch_field_direct(C.FRES, i);

  Result := MySQLWriteData(field, FieldDef, C.Row[i], Buffer, C.Lengths[i], CreateBlob);
end;

procedure TConnectionName.LoadBlobIntoBuffer(FieldDef: TFieldDef;
  ABlobBuf: PBufBlobField; cursor: TSQLCursor; ATransaction: TSQLTransaction);
var
  C : TCursorName;
  i : integer;
  len : longint;
begin
  C:=Cursor as TCursorName;
  if (C.Row=nil) or (C.Lengths=nil) then
    MySQLError(FMySQL,SErrFetchingData,Self);

  i := c.MapDSRowToMSQLRow[FieldDef.FieldNo-1];
  len := C.Lengths[i];

  ReAllocMem(ABlobBuf^.BlobBuffer^.Buffer, len);
  Move(C.Row[i]^, ABlobBuf^.BlobBuffer^.Buffer^, len);
  ABlobBuf^.BlobBuffer^.Size := len;
end;

function InternalStrToFloat(S: string): Extended;

var
  I: Integer;
  Tmp: string;

begin
  Tmp := '';
  for I := 1 to Length(S) do
    begin
    if not (S[I] in ['0'..'9', '+', '-', 'E', 'e']) then
      Tmp := Tmp + DecimalSeparator
    else
      Tmp := Tmp + S[I];
    end;
  Result := StrToFloat(Tmp);
end;

function InternalStrToCurrency(S: string): Extended;

var
  I: Integer;
  Tmp: string;

begin
  Tmp := '';
  for I := 1 to Length(S) do
    begin
    if not (S[I] in ['0'..'9', '+', '-', 'E', 'e']) then
      Tmp := Tmp + DecimalSeparator
    else
      Tmp := Tmp + S[I];
    end;
  Result := StrToCurr(Tmp);
end;

function InternalStrToDate(S: string): TDateTime;

var
  EY, EM, ED: Word;

begin
  EY := StrToInt(Copy(S,1,4));
  EM := StrToInt(Copy(S,6,2));
  ED := StrToInt(Copy(S,9,2));
  if (EY = 0) or (EM = 0) or (ED = 0) then
    Result:=0
  else
    Result:=EncodeDate(EY, EM, ED);
end;

function InternalStrToDateTime(S: string): TDateTime;

var
  EY, EM, ED: Word;
  EH, EN, ES: Word;

begin
  EY := StrToInt(Copy(S, 1, 4));
  EM := StrToInt(Copy(S, 6, 2));
  ED := StrToInt(Copy(S, 9, 2));
  EH := StrToInt(Copy(S, 12, 2));
  EN := StrToInt(Copy(S, 15, 2));
  ES := StrToInt(Copy(S, 18, 2));
  if (EY = 0) or (EM = 0) or (ED = 0) then
    Result := 0
  else
    Result := EncodeDate(EY, EM, ED);
  Result := ComposeDateTime(Result,EncodeTime(EH, EN, ES, 0));
end;

function InternalStrToTime(S: string): TDateTime;

var
  EH, EM, ES: Word;
  p: integer;

begin
  p := 1;
  EH := StrToInt(ExtractSubstr(S, p, [':'])); //hours can be 2 or 3 digits
  EM := StrToInt(ExtractSubstr(S, p, [':']));
  ES := StrToInt(ExtractSubstr(S, p, ['.']));
  Result := EncodeTimeInterval(EH, EM, ES, 0);
end;

function InternalStrToTimeStamp(S: string): TDateTime;

var
  EY, EM, ED: Word;
  EH, EN, ES: Word;

begin
{$IFNDEF mysql40}
  EY := StrToInt(Copy(S, 1, 4));
  EM := StrToInt(Copy(S, 6, 2));
  ED := StrToInt(Copy(S, 9, 2));
  EH := StrToInt(Copy(S, 12, 2));
  EN := StrToInt(Copy(S, 15, 2));
  ES := StrToInt(Copy(S, 18, 2));
{$ELSE}
  EY := StrToInt(Copy(S, 1, 4));
  EM := StrToInt(Copy(S, 5, 2));
  ED := StrToInt(Copy(S, 7, 2));
  EH := StrToInt(Copy(S, 9, 2));
  EN := StrToInt(Copy(S, 11, 2));
  ES := StrToInt(Copy(S, 13, 2));
{$ENDIF}
  if (EY = 0) or (EM = 0) or (ED = 0) then
    Result := 0
  else
    Result := EncodeDate(EY, EM, ED);
  Result := Result + EncodeTime(EH, EN, ES, 0);
end;

function TConnectionName.MySQLWriteData(AField: PMYSQL_FIELD; FieldDef: TFieldDef; Source, Dest: PChar; Len: integer; out CreateBlob : boolean): Boolean;

var
  VI: Integer;
  VL: LargeInt;
  VS: Smallint;
  VF: Double;
  VC: Currency;
  VD: TDateTime;
  VB: TBCD;
  Src : String;

begin
  Result := False;
  CreateBlob := False;
  if Source = Nil then // If the pointer is NULL, the field is NULL
    exit;
  SetString(Src, Source, Len);
  case AField^.ftype of
    FIELD_TYPE_TINY, FIELD_TYPE_SHORT, FIELD_TYPE_YEAR:
      begin
      if (Src<>'') then
        VS := StrToInt(Src)
      else
        VS := 0;
      Move(VS, Dest^, SizeOf(smallint));
      end;
    FIELD_TYPE_LONG, FIELD_TYPE_INT24:
      begin
      if (Src<>'') then
        VI := StrToInt(Src)
      else
        VI := 0;
      Move(VI, Dest^, SizeOf(Integer));
      end;
    FIELD_TYPE_LONGLONG:
      begin
      if (Src<>'') then
        VL := StrToInt64(Src)
      else
        VL := 0;
      Move(VL, Dest^, SizeOf(LargeInt));
      end;
{$ifdef mysql50_up}
    FIELD_TYPE_NEWDECIMAL,
{$endif}      
    FIELD_TYPE_DECIMAL, FIELD_TYPE_FLOAT, FIELD_TYPE_DOUBLE:
      case FieldDef.DataType of
        ftBCD:
          begin
          VC := InternalStrToCurrency(Src);
          Move(VC, Dest^, SizeOf(Currency));
          end;
        ftFmtBCD:
          begin
          VB := StrToBCD(Src{, FSQLFormatSettings});
          Move(VB, Dest^, SizeOf(TBCD));
          end
        else
          begin
          if Src <> '' then
            VF := InternalStrToFloat(Src)
          else
            VF := 0;
          Move(VF, Dest^, SizeOf(Double));
          end;
      end;
    FIELD_TYPE_TIMESTAMP:
      begin
      if Src <> '' then
        VD := InternalStrToTimeStamp(Src)
      else
        VD := 0;
      Move(VD, Dest^, SizeOf(TDateTime));
      end;
    FIELD_TYPE_DATETIME:
      begin
      if Src <> '' then
        VD := InternalStrToDateTime(Src)
      else
        VD := 0;
      Move(VD, Dest^, SizeOf(TDateTime));
      end;
    FIELD_TYPE_DATE:
      begin
      if Src <> '' then
        VD := InternalStrToDate(Src)
      else
        VD := 0;
      Move(VD, Dest^, SizeOf(TDateTime));
      end;
    FIELD_TYPE_TIME:
      begin
      if Src <> '' then
        VD := InternalStrToTime(Src)
      else
        VD := 0;
      Move(VD, Dest^, SizeOf(TDateTime));
      end;
    FIELD_TYPE_VAR_STRING, FIELD_TYPE_STRING, FIELD_TYPE_ENUM, FIELD_TYPE_SET:
      begin
{      Write('Moving string of size ',asize,' : ');
      P:=Source;
      If (P<>nil) then
        While P[0]<>#0 do
          begin
          Write(p[0]);
          inc(p);
          end;
      Writeln;
}
      if Len > FieldDef.Size then
        Len := FieldDef.Size;
      case FieldDef.DataType of
        // String-fields which can contain more then dsMaxStringSize characters
        // are mapped to ftBlob fields, while their mysql-datatype is FIELD_TYPE_BLOB
        ftBlob, ftMemo:
          CreateBlob := True;
        ftVarBytes:
          begin
          PWord(Dest)^ := Len;
          Move(Source^, (Dest+sizeof(Word))^, Len);
          end;
        ftBytes:
          Move(Source^, Dest^, Len);
        else // ftString, ftFixedChar
          begin
          Move(Source^, Dest^, Len);
          (Dest+Len)^ := #0;
          end;
      end;
      end;
    FIELD_TYPE_BLOB:
      CreateBlob := True;
{$IFDEF MYSQL50_UP}
    FIELD_TYPE_BIT:
      begin
      VL := 0;
      for VI := 0 to Len-1 do
        VL := VL * 256 + PByte(Source+VI)^;
      move(VL, Dest^, sizeof(LargeInt));
      end;
{$ENDIF}
  end;
  Result := True;
end;

procedure TConnectionName.UpdateIndexDefs(IndexDefs : TIndexDefs;TableName : string);

var qry : TSQLQuery;

begin
  if not assigned(Transaction) then
    DatabaseError(SErrConnTransactionnSet);

  qry := tsqlquery.Create(nil);
  qry.transaction := Transaction;
  qry.database := Self;
  with qry do
    begin
    ParseSQL := False;
    sql.clear;
    sql.add('show index from ' +  TableName);
    open;
    end;
  while not qry.eof do with IndexDefs.AddIndexDef do
    begin
    Name := trim(qry.fieldbyname('Key_name').asstring);
    Fields := trim(qry.fieldbyname('Column_name').asstring);
    If Name = 'PRIMARY' then options := options + [ixPrimary];
    If qry.fieldbyname('Non_unique').asinteger = 0 then options := options + [ixUnique];
    qry.next;
    while (name = trim(qry.fieldbyname('Key_name').asstring)) and (not qry.eof) do
      begin
      Fields := Fields + ';' + trim(qry.fieldbyname('Column_name').asstring);
      qry.next;
      end;
    end;
  qry.close;
  qry.free;
end;

function TConnectionName.RowsAffected(cursor: TSQLCursor): TRowsCount;
begin
  if assigned(cursor) then
    // Compile this without range-checking. RowsAffected can be -1, although
    // it's an unsigned integer. (small joke from the mysql-guys)
    // Without range-checking this goes ok. If Range is turned on, this results
    // in range-check errors.
    Result := (cursor as TCursorName).RowsAffected
  else
    Result := -1;
end;

constructor TConnectionName.Create(AOwner: TComponent);
const SingleBackQoutes: TQuoteChars = ('`','`');
begin
  inherited Create(AOwner);
  FConnOptions := FConnOptions + [sqEscapeRepeat] + [sqEscapeSlash];
  FieldNameQuoteChars:=SingleBackQoutes;
  FMySQL := Nil;
end;

procedure TConnectionName.GetFieldNames(const TableName: string; List: TStrings);
begin
  GetDBInfo(stColumns,TableName,'field',List);
end;

procedure TConnectionName.GetTableNames(List: TStrings; SystemTables: Boolean);
begin
  GetDBInfo(stTables,'','tables_in_'+DatabaseName,List)
end;

function TConnectionName.GetTransactionHandle(trans: TSQLHandle): pointer;
begin
  Result:=Nil;
end;

function TConnectionName.Commit(trans: TSQLHandle): boolean;
begin
  // Do nothing.
end;

function TConnectionName.RollBack(trans: TSQLHandle): boolean;
begin
  // Do nothing
end;

function TConnectionName.StartdbTransaction(trans: TSQLHandle; AParams : string): boolean;
begin
  // Do nothing
end;

procedure TConnectionName.CommitRetaining(trans: TSQLHandle);
begin
  // Do nothing
end;

procedure TConnectionName.RollBackRetaining(trans: TSQLHandle);
begin
  // Do nothing
end;

function TConnectionName.GetSchemaInfoSQL(SchemaType: TSchemaType;
  SchemaObjectName, SchemaPattern: string): string;

begin
  case SchemaType of
    stTables     : result := 'show tables';
    stColumns    : result := 'show columns from ' + EscapeString(SchemaObjectName);
  else
    DatabaseError(SMetadataUnavailable)
  end; {case}
end;

{ TMySQLConnectionDef }

class function TMySQLConnectionDef.TypeName: String;
begin
  Result:='MySQL '+MySQLVersion;
end;

class function TMySQLConnectionDef.ConnectionClass: TSQLConnectionClass;
begin
  {$IfDef mysql55}
     Result:=TMySQL55Connection;
  {$ELSE}
    {$IfDef mysql51}
      Result:=TMySQL51Connection;
    {$ELSE}
      {$IfDef mysql50}
        Result:=TMySQL50Connection;
      {$ELSE}
        {$IfDef mysql41}
          Result:=TMySQL41Connection;
        {$ELSE}
          {$IFDEF mysql4} // temporary backwards compatibility for Lazarus
            Result:=TMySQLConnection;
          {$ELSE}
            Result:=TMySQL40Connection;
          {$EndIf}
        {$EndIf}
      {$EndIf}
    {$endif}
  {$endif}
end;

class function TMySQLConnectionDef.Description: String;
begin
  Result:='Connect to a MySQL '+MySQLVersion+'database directly via the client library';
end;

{$IfDef mysql55}
  initialization
    RegisterConnection(TMySQL55ConnectionDef);
  finalization
    UnRegisterConnection(TMySQL55ConnectionDef);
{$else}
  {$IfDef mysql51}
    initialization
      RegisterConnection(TMySQL51ConnectionDef);
    finalization
      UnRegisterConnection(TMySQL51ConnectionDef);
  {$ELSE}
    {$IfDef mysql50}
      initialization
        RegisterConnection(TMySQL50ConnectionDef);
      finalization
        UnRegisterConnection(TMySQL50ConnectionDef);
    {$ELSE}
      {$IfDef mysql41}
        initialization
          RegisterConnection(TMySQL41ConnectionDef);
        finalization
          UnRegisterConnection(TMySQL41ConnectionDef);
      {$ELSE}
        {$IFDEF mysql4} // temporary backwards compatibility for Lazarus
          initialization
            RegisterConnection(TMySQL40ConnectionDef);
          finalization
            UnRegisterConnection(TMySQL40ConnectionDef);
        {$ELSE}
          initialization
            RegisterConnection(TMySQL40ConnectionDef);
          finalization
            UnRegisterConnection(TMySQL40ConnectionDef);
        {$EndIf}
      {$EndIf}
    {$EndIf}
  {$ENDIF}
{$endif}

end.
