(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit dData;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Dialogs, DB, FileUtil,
  memds, mysql51conn, sqldb, inifiles, stdctrls, RegExpr,
  dynlibs, lcltype, ExtCtrls, sqlscript, process, mysql51dyn, ssl_openssl_lib,
  mysql55dyn, mysql55conn, CustApp, mysql56dyn, mysql56conn, grids, LazFileUtils,
  mysql57dyn, mysql57conn, uMyFindFile, Graphics;

const
  cDB_LIMIT = 500;
  cDB_MAIN_VER = 19;
  cDB_COMN_VER = 6;
  cDB_PING_INT = 300;  //ping interval for database connection in seconds
                       //program crashed after long time of inactivity
                       //so now after cDB_PING_INT will be run simple sql query
                       //which refresh connection

Type TMode = (tmRun,tmSP);
Type TCurPos = (cpBegin,cpEnd);
type TSortType = (stDate,stCall);

type
  TExpProfile = record
    ProfNr : Word;
    text   : String;
end;

type
  TZipCode  = record
    Name       : String;
    LongName   : String;
    StoreField : String;
    ZipPos     : Integer;
    DXCC       : String;
  end;

type

  { TdmData }

  TdmData = class(TDataModule)
    dsrFreqs: TDataSource;
    dsrSQLConsole: TDatasource;
    dsrLogList: TDatasource;
    dsrmQ: TDatasource;
    mQ: TSQLQuery;
    Q2: TSQLQuery;
    CQ: TSQLQuery;
    qFreqMemGrid: TSQLQuery;
    qFreqs: TSQLQuery;
    trFreqMemGrid: TSQLTransaction;
    trFreqs: TSQLTransaction;
    trQ2: TSQLTransaction;
    qSQLConsole: TSQLQuery;
    scCommon: TSQLScript;
    scLog: TSQLScript;
    qLogList: TSQLQuery;
    qQSLMgr: TSQLQuery;
    qCallBook: TSQLQuery;
    qLongNote: TSQLQuery;
    qProfiles: TSQLQuery;
    qIOTAList: TSQLQuery;
    qBands: TSQLQuery;
    qWorkedContests: TSQLQuery;
    qDXClusters: TSQLQuery;
    qComment: TSQLQuery;
    qException: TSQLQuery;
    qQSOBefore: TSQLQuery;
    Q1: TSQLQuery;
    Q: TSQLQuery;
    qCQRLOG: TSQLQuery;
    scOnlineLogTriggers: TSQLScript;
    scViews: TSQLScript;
    scQSLExport : TSQLScript;
    scMySQLConfig: TSQLScript;
    qBandMapFil: TSQLQuery;
    qRbnMon: TSQLQuery;
    qFreqMem: TSQLQuery;
    trCQ: TSQLTransaction;
    trW: TSQLTransaction;
    trWorkedContests: TSQLTransaction;
    W1: TSQLQuery;
    trW1: TSQLTransaction;
    W: TSQLQuery;
    trFreqMem: TSQLTransaction;
    trRbnMon: TSQLTransaction;
    trBandMapFil: TSQLTransaction;
    tmrDBPing: TTimer;
    trCQRLOG: TSQLTransaction;
    trQ: TSQLTransaction;
    trQ1: TSQLTransaction;
    trQSOBefore: TSQLTransaction;
    trException: TSQLTransaction;
    trComment: TSQLTransaction;
    trDXClusters: TSQLTransaction;
    trBands: TSQLTransaction;
    trIOTAList: TSQLTransaction;
    trProfiles: TSQLTransaction;
    trLongNote: TSQLTransaction;
    trCallBook: TSQLTransaction;
    trQSLMgr: TSQLTransaction;
    trSQLConsole: TSQLTransaction;
    trLogList: TSQLTransaction;
    trmQ: TSQLTransaction;
    dsrQSLMgr: TDatasource;
    dsrDXCluster: TDatasource;
    dsrProfiles: TDatasource;
    dsrBands: TDatasource;
    dsrWorkedContests: TDatasource;
    dsrImport: TDatasource;
    dsrQSOBefore: TDatasource;
    dsrMain: TDatasource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure Q1BeforeOpen(DataSet: TDataSet);
    procedure Q2BeforeOpen(DataSet: TDataSet);
    procedure qBandsBeforeOpen(DataSet: TDataSet);
    procedure QBeforeOpen(DataSet: TDataSet);
    procedure mQBeforeOpen(DataSet: TDataSet);
    procedure qCQRLOGBeforeOpen(DataSet: TDataSet);
    procedure qLogListBeforeOpen(DataSet: TDataSet);
    procedure qLongNoteBeforeOpen(DataSet: TDataSet);
    procedure scLogException(Sender: TObject; Statement: TStrings;
      TheException: Exception; var Continue: boolean);
    procedure scViewsException(Sender: TObject; Statement: TStrings;
      TheException: Exception; var Continue: boolean);
    procedure tmrDBPingTimer(Sender: TObject);
    procedure W1BeforeOpen(DataSet: TDataSet);
    procedure WBeforeOpen(DataSet: TDataSet);
  private
    fDBName  : String;
    fHomeDir : String;
    fDataDir : String;
    fMembersDir : String;
    fGlobalMembersDir : String;
    fDebugLevel : Integer;
    fOrderBy : String;
    fVersionString : String;
    fHelpDir  : String;
    fCWStopped : Boolean;
    fZipCodeDir : String;
    fSortType   : TSortType;
    fDLLSSLName  : String;
    fDLLUtilName : String;
    fLogName     : String;
    fUsrHomeDir  : String;
    fShareDir    : String;
    fFirstMemId  : Integer;
    fLastMemId   : Integer;
    aProf : Array of TExpProfile;
    aSCP  : Array of String[20];
    MySQLProcess : TProcess;
    csPreviousQSO : TRTLCriticalSection;
    fMySQLVersion : Currency;
    FreqMemCount  : integer;

    function  FindLib(const Path,LibName : String) : String;
    function  GetMysqldPath : String;
    function  TableExists(TableName : String) : Boolean;
    function  GetDebugLevel : Integer;
    function  FieldExists(TableName, FieldName : String) : Boolean;
    function ConstraintExists(TableName, ConstraintName : String) : Boolean;

    procedure CreateDBConnections;
    procedure CreateViews;
    procedure PrepareBandDatabase;
    procedure PrepareDXClusterDatabase;
    procedure DeleteMySQLPidFile;
    procedure PrepareDirectories;
    procedure PrepareCtyData;
    procedure PrepareDXCCData;
    procedure PrepareXplanetDir;
    procedure PrepareVoice_keyerDir;
    procedure KillMySQL(const OnStart : Boolean = True);
    procedure UpgradeMainDatabase(old_version : Integer);
    procedure UpgradeCommonDatabase(old_version : Integer);
    procedure PrepareMysqlConfigFile;
    procedure DeleteOldConfigFiles;
    procedure GetCurrentFreqFromMem(var freq : Double; var mode : String; var bandwidth : Integer; var info : String);
  public
    MainCon      : TSQLConnection;
    BandMapCon   : TSQLConnection;
    RbnMonCon    : TSQLConnection;
    LogUploadCon : TSQLConnection;
    dbDXC        : TSQLConnection;

    eQSLUsers : Array of ShortString;
    CallArray : Array of String[20];
    IsFilterSQL : String; //String that is created with Filter settings. Isvalid if isfilter is valid, no cleanups.
    IsFilter  : Boolean;
    IsSFilter : Boolean; //Search filter
    //search function uses filter function but user doesn't need to know about it
    //if he wants to use export, program use the same functions for filter enabled

    Ascening  : Boolean;

    Zip1  : TZipCode;
    Zip2  : TZipCode;
    Zip3  : TZipCode;

    UseQSOColor  : Boolean;
    QSOColor     : TColor;
    QSOColorDate : TDateTime;

    property DBName  : String read fDbName;
    property HomeDir : String read fHomeDir write fHomeDir; //~/.config/cqrlog
    property OrderBy : String read fOrderBy write fOrderBy;  //default value is qsodate,time_on
    property DataDir : String read fDataDir write fDataDir;
    property ShareDir   : String read fShareDir write fShareDir;
    property MembersDir : String read fMembersDir;
    property GlobalMembersDir : string read fGlobalMembersDir;
    property ZipCodeDir : String read fZipCodeDir;
    property UsrHomeDir : String read fUsrHomeDir;
    property DebugLevel : Integer read fDebugLevel write fDebugLevel;
    //^ 0 - nothing, 1 - SQL queries 2 - Transactions, etc.
    property VersionString : String read fVersionString write fVersionString;
    property HelpDir : String read fHelpDir write fHelpDir;

    property CWStopped   : Boolean read fCWStopped write fCWStopped;
    property SortType    : TSortType read fSortType write fSortType;

    property cDLLSSLName  : String read fDLLSSLName;
    property cDLLUtilName : String read fDLLUtilName;

    property LogName : String read fLogName write fLogName;

    property MySQLVersion : Currency read fMySQLVersion write fMySQLVersion;

    function  GetComment(call : String) : String;
    function  GetProfileText(nr : Integer) : String;
    function  GetCompleteProfileText(nr : Integer) : String;
    function  GetExportProfileText(nr : Integer) : String;
    function  GetNRFromProfile(text : String) : Integer;
    function  GetDefaultProfileText : String;
    function  QSLMgrFound(call,date : String; var qsl_via : String) : Boolean;
    function  GetWAZInfoIndex(waz,freq : String) : Integer;
    function  GetWAZInfoString(Index : Integer) : String;
    function  GetITUInfoIndex(itu,freq : String) : Integer;
    function  GetITUInfoString(Index : Integer) : String;
    function  GetIOTAInfoIndex(iota : String) : Integer;
    function  GetIOTAInfoString(Index : Integer) : String;
    function  GetIOTAName(iota : String) : String;
    function  GetIOTAForDXCC(call,pref : String;cmbIOTA : TComboBox; date : TDateTime) : Boolean;
    function  FindCounty1(qth,pfx : String; var StoreTo : String) : String;
    function  FindCounty2(qth,pfx : String; var StoreTo : String) : String;
    function  FindCounty3(qth,pfx : String; var StoreTo : String) : String;
    function  GetMyLocFromProfile(profile : String) : String;
    function  SendQSL(call,mode,freq : String; adif : Word) : String;
    function  GetSCPCalls(call : String) : String;
    function  UsesLotw(call : String) : Boolean;
    function  OpenConnections(host,port,user,pass : String) : Boolean;
    function  LogExists(nr : Word) : Boolean;
    function  GetProperDBName(nr : Word) : String;
    function  GetQSOCount : Integer;
    procedure GetQSODistanceSum(var SumDist:int64;var LongestDist:integer;var MainLocCount:Integer);
    function  UseseQSL(call : String) : Boolean;
    function  QueryLocate(qry : TSQLQuery; Column : String; Value : Variant; DisableGrid : Boolean; exatly : Boolean = True) : Boolean;
    function  BandModFromFreq(freq : String;var mode,band : String) : Boolean;
    function  TriggersExistsOnCqrlog_main : Boolean;
    function  GetLastAllertCallId(const callsign,band,mode : String) : Integer;
    function  CallExistsInLog(callsign,band,mode,LastDate,LastTime : String) : Boolean;
    function  RbnMonDXCCInfo(adif : Word; band, mode : String;DxccWithLoTW:Boolean;  var index : integer) : String;
    function  RbnCallExistsInLog(callsign,band,mode,LastDate,LastTime : String) : Boolean;
    function  CallNoteExists(Callsign : String) : Boolean;
    function  GetNewLogNumber : Integer;
    function  getNewMySQLConnectionObject : TMySQL57Connection;

    procedure SaveQSO(date : TDateTime; time_on,time_off,call : String; freq : Currency;mode,rst_s,
                      rst_r, stn_name,qth,qsl_s,qsl_r,qsl_via,iota,pwr : String; itu,waz : Integer;
                      loc, my_loc,county,award,remarks : String; adif : Integer;
                      idcall,state,dok,cont : String; qso_dxcc : Boolean; profile : Integer;
                      nclub1,nclub2,nclub3,nclub4,nclub5, PropMode, Satellite : String;
                      RxFreq : Currency;srx : String;stx : String;srx_string : String;stx_string : String;
                      contestname : String; Op : String);

    procedure EditQSO(date : TDateTime; time_on,time_off,call : String; freq : Currency;mode,rst_s,
                      rst_r, stn_name,qth,qsl_s,qsl_r,qsl_via,iota,pwr : String; itu,waz : Integer;
                      loc, my_loc,county,award,remarks : String; adif : Word; idcall,state,dok,cont : String;
                      qso_dxcc : Boolean; profile : Integer; PropMode, Satellite : String;
                      RxFreq : Currency; idx : LongInt;srx : String;stx : String;srx_string : String;stx_string : String;
                      contestname : String; Op : String);
    procedure SaveComment(call,text : String);
    procedure DeleteComment(id : Integer);
    procedure PrepareImport;
    procedure DoAfterImport;
    procedure InsertProfiles(cmbProfile : TComboBox; ShowAll : Boolean);
    procedure InsertProfiles(cmbProfile : TComboBox; ShowAll,loc,qth,rig : Boolean); overload;
    procedure RefreshMainDatabase(id : Integer = 0);
    procedure LoadClubsSettings;
    procedure LoadZipSettings;
    procedure CheckForDatabases;
    procedure CreateDatabase(nr : Word; log_name : String);
    procedure EditDatabaseName(nr : Word; log_name : String);
    procedure RefreshLogList(nr : Word = 0);
    procedure DeleteLogDatabase(nr : Word);
    procedure OpenDatabase(nr : Word);
    procedure SaveConfigFile;
    procedure CloseDatabases;
    procedure TruncateTables(nr : Word);
    procedure PrepareProfileExport;
    procedure CloseProfileExport;
    procedure LoadLoTWCalls;
    procedure LoadeQSLCalls;
    procedure LoadMasterSCP;
    procedure RepairTables(nr : Word);
    procedure CreateQSLTmpTable;
    procedure DropQSLTmpTable;
    procedure StartMysqldProcess;
    procedure DeleteCallAlert(const id : Integer);
    procedure AddCallAlert(const callsign, band, mode : String);
    procedure EditCallAlert(const id : Integer; const callsign, band, mode : String);
    procedure MarkAllAsUploadedToeQSL;
    procedure MarkAllAsUploadedToLoTW;
    procedure RemoveeQSLUploadedFlag(id : Integer);
    procedure RemoveLoTWUploadedFlag(id : Integer);
    procedure StoreFreqMemories(grid : TStringGrid);
    procedure LoadFreqMemories(grid : TStringGrid);
    procedure GetPreviousFreqFromMem(var freq : Double; var mode : String; var bandwidth : Integer; var info : String);
    procedure GetNextFreqFromMem(var freq : Double; var mode : String; var bandwidth : Integer; var info : String);
    procedure OpenFreqMemories(mode : String);
    procedure SaveBandChanges(band : String; BandBegin, BandEnd, BandCW, BandRTTY, BandSSB, RXOffset, TXOffset : Currency);
    procedure GetRXTXOffset(Freq : Currency; var RXOffset,TXOffset : Currency);
    procedure LoadQSODateColorSettings;
    procedure PrepareEmptyLogUploadStatusTables(lQ : TSQLQuery;lTr : TSQLTransaction);
  end;

var
  dmData : TdmData;
  handle : THandle;
  reg    : TRegExpr;
  MemNR  : array of integer;

implementation

  {$R *.lfm}

uses dUtils, dDXCC, fMain, fWorking, fUpgrade, fImportProgress, fNewQSO, dDXCluster, uMyIni,
     fTRXControl, fRotControl, uVersion, dLogUpload, fDbError, dMembership;

procedure TdmData.CheckForDatabases;
var
  Exists : Boolean = False;
begin
  if trmQ.Active then
    trmQ.Rollback;
  mQ.SQL.Clear;
  mQ.SQL.Text := 'select * from tables where table_schema = '+
                  QuotedStr('cqrlog_common');
  trmQ.StartTransaction;
  mQ.Open;
  if mQ.RecordCount > 0 then
    Exists := True;
  mQ.Close;
  trmQ.Rollback;
  if not Exists then
  begin
    trmQ.StartTransaction;
    if fDebugLevel>=1 then Writeln(scCommon.Script.Text);
    scCommon.ExecuteScript;
    trmQ.Commit;


    trmQ.StartTransaction;
    mQ.Close;
    mQ.SQL.Text := 'insert into db_version (nr) values('+IntToStr(cDB_COMN_VER)+')';
    mQ.ExecSQL;
    trmQ.Commit;

    PrepareBandDatabase;
    PrepareDXClusterDatabase;

    CreateDatabase(1,'Log 001');

    //we must incialize dxcc tables, first
    with TfrmImportProgress.Create(self) do
    try
      lblComment.Caption := 'Importing DXCC data ...';
      Directory  := dmData.fHomeDir + 'ctyfiles' + PathDelim;
      ImportType := imptImportDXCCTables;
      ShowModal
    finally
      Free
    end;

    with TfrmImportProgress.Create(self) do
    try
      lblComment.Caption := 'Importing QSL data ...';
      Directory     := dmData.fHomeDir + 'ctyfiles' + PathDelim;
      FileName      := Directory+'qslmgr.csv';
      ImportType    := imptImportQSLMgrs;
      CloseAfImport := True;
      ShowModal
    finally
      Free
    end
  end;
  mQ.SQL.Clear;
  qLogList.Close;
  if trLogList.Active then
    trLogList.Rollback;
  qLogList.SQL.Text := 'SELECT log_nr,log_name FROM cqrlog_common.log_list order by log_nr';
  trLogList.StartTransaction;
  qLogList.Open;
end;

procedure TdmData.CreateViews;
var
  i : Integer;
begin
  if trmQ.Active then trmQ.Rollback;
  trmQ.StartTransaction;
  mQ.SQL.Text := '';
  for i:=0 to scViews.Script.Count-1 do
  begin
    if Pos(';',scViews.Script.Strings[i]) = 0 then
      mQ.SQL.Add(scViews.Script.Strings[i])
    else begin
      mQ.SQL.Add(scViews.Script.Strings[i]);
      if fDebugLevel>=1 then Writeln(mQ.SQL.Text);
      mQ.ExecSQL;
      mQ.SQL.Text := ''
    end
  end;
  trmQ.Commit
end;

procedure TdmData.CreateDatabase(nr : Word; log_name : String);
var
  db : String;
  i  : Integer;
begin
  db := GetProperDBName(nr);

  mQ.Close;
  if trmQ.Active then
    trmQ.Rollback;

  mQ.SQL.Clear;
  mQ.SQL.Text := 'CREATE DATABASE IF NOT EXISTS '+db+' DEFAULT CHARACTER SET = '+
                 'utf8 DEFAULT COLLATE = utf8_bin;';
//"if not exists is" because bug in TSQLScript caused that database was created but without
//any table, so if user try to create new database which already exists but it is not in the
//log list, database will be created and added to the log list

  trmQ.StartTransaction;
  if fDebugLevel>=1 then Writeln(mQ.SQL.Text);
  mQ.ExecSQL;
  trmQ.Commit;

  mQ.SQL.Text := 'use '+db+';';
  if fDebugLevel>=1 then Writeln(mQ.SQL.Text);
  trmQ.StartTransaction;
  mQ.ExecSQL;
  trmQ.Commit;

  trmQ.StartTransaction;
  mQ.SQL.Text := '';
  for i:=0 to scLog.Script.Count-1 do
  begin
    if Pos(';',scLog.Script.Strings[i]) = 0 then
      mQ.SQL.Add(scLog.Script.Strings[i])
    else begin
      mQ.SQL.Add(scLog.Script.Strings[i]);
      if fDebugLevel>=1 then Writeln(mQ.SQL.Text);
      mQ.ExecSQL;
      mQ.SQL.Text := ''
    end
  end;
  trmQ.Commit;

//^^ because of bug in  TSQLSript. For the firt time cretreates the database,
//second database - no effect. My workaround works. Semicolon is a delimitter.

  CreateViews;

  trmQ.StartTransaction;
  mQ.SQL.Text := 'insert into db_version (nr) values('+IntToStr(cDB_MAIN_VER)+')';
  if fDebugLevel>=1 then Writeln(mQ.SQL.Text);
  mQ.ExecSQL;
  trmQ.Commit;

  mQ.SQL.Text := 'insert into cqrlog_common.log_list (log_nr,log_name) values '+
                 '('+IntToStr(nr)+','+QuotedStr(log_name)+')';
  trmQ.StartTransaction;
  if fDebugLevel>=1 then Writeln(mQ.SQL.Text);
  mQ.ExecSQL;
  trmQ.Commit;

  PrepareEmptyLogUploadStatusTables(mQ,trmQ);
  {
  trmQ.StartTransaction;
  mQ.SQL.Text := 'insert into log_changes (id,cmd) values(1,'+QuotedStr(C_ALLDONE)+')';
  if fDebugLevel>=1 then Writeln(mQ.SQL.Text);
  mQ.ExecSQL;

  mQ.SQL.Text := 'insert into upload_status (logname, id_log_changes) values ('+QuotedStr(C_HAMQTH)+',1)';
  if fDebugLevel>=1 then Writeln(mQ.SQL.Text);
  mQ.ExecSQL;

  mQ.SQL.Text := 'insert into upload_status (logname, id_log_changes) values ('+QuotedStr(C_CLUBLOG)+',1)';
  if fDebugLevel>=1 then Writeln(mQ.SQL.Text);
  mQ.ExecSQL;

  mQ.SQL.Text := 'insert into upload_status (logname, id_log_changes) values ('+QuotedStr(C_HRDLOG)+',1)';
  if fDebugLevel>=1 then Writeln(mQ.SQL.Text);
  mQ.ExecSQL;
  trmQ.Commit;
  }

  RefreshLogList(nr)
end;

function TdmData.OpenConnections(host,port,user,pass : String) : Boolean;
var
  sql : String;
begin
  Result := True;

  if MainCon.Connected then
    MainCon.Connected := False;
  if dbDXC.Connected then
    dbDXC.Connected := False;
  if LogUploadCon.Connected then
    LogUploadCon.Connected := False;
  if RbnMonCon.Connected then
    RbnMonCon.Connected := False;

  MainCon.CharSet:='UTF8';
  MainCon.HostName     := host;
  MainCon.Params.Text  := 'Port='+port;
  MainCon.UserName     := user;
  MainCon.Password     := pass;
  MainCon.DatabaseName := 'information_schema';

  BandMapCon.CharSet:='UTF8';
  BandMapCon.HostName     := host;
  BandMapCon.Params.Text  := 'Port='+port;
  BandMapCon.UserName     := user;
  BandMapCon.Password     := pass;
  BandMapCon.DatabaseName := 'information_schema';

  RbnMonCon.CharSet:='UTF8';
  RbnMonCon.HostName     := host;
  RbnMonCon.Params.Text  := 'Port='+port;
  RbnMonCon.UserName     := user;
  RbnMonCon.Password     := pass;
  RbnMonCon.DatabaseName := 'information_schema';

  dbDXC.CharSet:='UTF8';
  dbDXC.HostName     := host;
  dbDXC.Params.Text  := 'Port='+port;
  dbDXC.UserName     := user;
  dbDXC.Password     := pass;
  dbDXC.DatabaseName := 'information_schema';

  LogUploadCon.CharSet:='UTF8';
  LogUploadCon.HostName     := host;
  LogUploadCon.Params.Text  := 'Port='+port;
  LogUploadCon.UserName     := user;
  LogUploadCon.Password     := pass;
  LogUploadCon.DatabaseName := 'information_schema';

  try
    MainCon.Connected      := True;
    dbDXC.Connected        := True;
    LogUploadCon.Connected := True;
    BandMapCon.Connected   := True;
    RbnMonCon.Connected    := True;

    sql := 'SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'+QuotedStr('ONLY_FULL_GROUP_BY')+','+QuotedStr('')+'));';

    MainCon.ExecuteDirect(sql);
    dbDXC.ExecuteDirect(sql);
    LogUploadCon.ExecuteDirect(sql);
    BandMapCon.ExecuteDirect(sql);
    RbnMonCon.ExecuteDirect(sql)
  except
    on E : Exception do
    begin
      Application.MessageBox(PChar('Error during connection to database: '+E.Message),
                             'Error',mb_ok + mb_IconError);
      Result := False
    end
  end
end;

function TdmData.LogExists(nr : Word) : Boolean;
begin
  if trmQ.Active then
    trmQ.Rollback;
  mQ.SQL.Text := 'select log_nr from cqrlog_common.log_list where log_nr = '+
                 IntToStr(nr);
  trmQ.StartTransaction;
  mQ.Open;
  Result := mQ.RecordCount > 0;
  mQ.Close;
  trmQ.Rollback
end;

procedure TdmData.EditDatabaseName(nr : Word; log_name : String);
begin
  mQ.Close;
  if trmQ.Active then
    trmQ.Rollback;
  mQ.SQL.Text := 'UPDATE cqrlog_common.log_list SET log_name = '+
                 QuotedStr(log_name) + ' where log_nr = '+IntToStr(nr);
  trmQ.StartTransaction;
  mQ.ExecSQL;
  trmQ.Commit;
  RefreshLogList(nr)
end;

procedure TdmData.RefreshLogList(nr : Word = 0);
begin
  qLogList.Close;
  if trLogList.Active then
    trLogList.Rollback;
  qLogList.SQL.Text := 'SELECT log_nr,log_name FROM cqrlog_common.log_list order by log_nr';
  trLogList.StartTransaction;
  qLogList.Open;
  if nr > 0 then
    qLogList.Locate('log_nr',nr,[])
end;

procedure TdmData.DeleteLogDatabase(nr : Word);
var
  db : String;
begin
  db := GetProperDBName(nr);

  mQ.Close;
  if trmQ.Active then
    trmQ.Rollback;
  mQ.SQL.Text := 'DROP DATABASE '+db;
  trmQ.StartTransaction;
  mQ.ExecSQL;
  mQ.SQL.Text := 'DELETE FROM cqrlog_common.log_list WHERE log_nr = '+IntToStr(nr);
  mQ.ExecSQL;
  trmQ.Commit;
  RefreshLogList()
end;

function TdmData.GetProperDBName(nr : Word) : String;
begin
  if (nr < 10) then
    Result := '00'+IntToStr(nr)
  else if (nr < 100) then
    Result := '0'+IntToStr(nr)
  else
    Result := IntToStr(nr);
  Result := 'cqrlog'+Result
end;

procedure TdmData.OpenDatabase(nr : Word);
var
  l : TStringList;
begin
  DeleteFile(cqrini.IniFileName);
  FreeAndNil(cqrini);

  fDBName := GetProperDBName(nr);
  if trQ.Active then
    trQ.Rollback;
  Q.SQL.Text := 'use ' + fDBName;
  if fDebugLevel>=1 then Writeln(Q.SQL.Text);
  trQ.StartTransaction;
  Q.ExecSQL;
  trQ.Commit;

  if dmDXCluster.trQ.Active then
    dmDXCluster.trQ.Rollback;
  dmDXCluster.Q.Close;
  dmDXCluster.Q.SQL.Text := 'use ' + fDBName;
  if fDebugLevel>=1 then Writeln(dmDXCluster.Q.SQL.Text);
  dmDXCluster.trQ.StartTransaction;
  dmDXCluster.Q.ExecSQL;
  dmDXCluster.trQ.Commit;

  if dmLogUpload.trQ.Active then dmLogUpload.trQ.Rollback;
  dmLogUpload.Q.Close;
  dmLogUpload.Q.SQL.Text := 'use ' + fDBName;
  if fDebugLevel>=1 then Writeln(dmLogUpload.Q.SQL.Text);
  dmLogUpload.Q.ExecSQL;
  dmLogUpload.trQ.Commit;

  if trBandMapFil.Active then trBandMapFil.Rollback;
  qBandMapFil.Close;
  qBandMapFil.SQL.Text := 'use ' + fDBName;
  if fDebugLevel>=1 then Writeln(qBandMapFil.SQL.Text);
  qBandMapFil.ExecSQL;
  trBandMapFil.Commit;

  if trRbnMon.Active then trRbnMon.Rollback;
  qRbnMon.Close;
  qRbnMon.SQL.Text := 'use ' + fDBName;
  if (fDebugLevel>=1) then Writeln(qRbnMon.SQL.Text);
  trRbnMon.StartTransaction;
  qRbnMon.ExecSQL;
  trRbnMon.Commit;

  Q.SQL.Text := 'SELECT * FROM cqrlog_config';
  trQ.StartTransaction;
  l := TStringList.Create;
  Q.Open;
  try
    l.Text := Q.Fields[1].AsString;
    l.SaveToFile(fHomeDir+IntToStr(nr)+'cqrlog.cfg')
  finally
    Q.Close;
    trQ.Rollback;
    l.Free
  end;

  cqrini := TMyIni.Create(fHomeDir+IntToStr(nr)+'cqrlog.cfg',fHomeDir+IntToStr(nr)+'local.cfg');
  cqrini.LoadLocalSectionsList;

  trQ.StartTransaction;
  Q.SQL.Text := 'truncate table dxcc_id';
  Q.ExecSQL;
  Q.SQL.Text := 'insert into '+fDBName+'.dxcc_id select id_dxcc_ref,adif,pref,name from cqrlog_common.dxcc_ref';
  Q.ExecSQL;
  Q.SQL.Text := 'insert into '+fDBName+'.dxcc_id (adif,dxcc_ref,country) values (0,'+QuotedStr('!')+','+
                QuotedStr('Unknown country')+')';
  Q.ExecSQL;
  trQ.Commit;

  trQ.StartTransaction;
  try
    Q.SQL.Text := 'select * from db_version';
    Q.Open;
    UpgradeMainDatabase(Q.Fields[0].AsInteger)
  finally
    Q.Close();
    trQ.Rollback
  end;

  trQ.StartTransaction;
  try
    Q.SQL.Text := 'select * from cqrlog_common.db_version';
    Q.Open;
    UpgradeCommonDatabase(Q.Fields[0].AsInteger)
  finally
    Q.Close();
    trQ.Rollback
  end;

  dmUtils.TimeOffset     := cqrini.ReadFloat('Program','offset',0);
  dmUtils.GrayLineOffset := cqrini.ReadFloat('Program','GraylineOffset',0);
  dmUtils.SysUTC         := cqrini.ReadBool('Program','SysUTC',True);

  //qCQRLOG.SQL.Text := GetMainSQL;
  //qCQRLOG.Open;
  fSortType := stDate;

  dmDXCC.LoadDXCCRefArray;
  dmDXCC.LoadAmbiguousArray;
  dmDXCC.LoadExceptionArray;

  dmDXCluster.LoadDXCCRefArray;
  dmDXCluster.LoadExceptionArray;

  dmUtils.LoadBandsSettings;

  frmTRXControl.cmbRig.ItemIndex:=cqrini.ReadInteger('TRX', 'RigInUse', 1);
  frmTRXControl.cmbRigCloseUp(nil);
  frmTRXControl.InitializeRig;
  frmRotControl.rbRotor1.Checked:= cqrini.ReadBool('ROT','Use1',True);
  frmRotControl.rbRotor2.Checked:= not(cqrini.ReadBool('ROT','Use1',True));
  frmRotControl.InicializeRot;

  OpenFreqMemories('');

  LoadClubsSettings;
  LoadZipSettings;

  LoadQSODateColorSettings
end;

procedure TdmData.SaveConfigFile;
var
  l   : TStringList;
  ins : Boolean;
begin
  if trQ.Active then
    trQ.Rollback;
  Q.Close;
  cqrini.SaveToDisk;
  l := TStringList.Create;
  try
    l.LoadFromFile(cqrini.IniFileName);
    Q.SQL.Text := 'select count(*) from '+fDBName+'.cqrlog_config';
    Q.Open;
    ins := Q.Fields[0].AsInteger = 0;
    Q.Close;
    if ins then
      Q.SQL.Text := 'insert into '+fDBName+'.cqrlog_config (config_file) values(:cnf)'
    else
      Q.SQL.Text := 'update '+fDBName+'.cqrlog_config set config_file = :cnf';
    Q.Prepare;
    Q.Params[0].AsString := l.Text;
    Q.ExecSQL;
    trQ.Commit
  finally
    Q.Close;
    l.Free
  end;
  if fDebugLevel>=1 then Writeln('Saving ini file to database')
end;

procedure TdmData.CloseDatabases;
var
  i : Integer;
begin
  SaveConfigFile;
  for i := 0 to ComponentCount-1 do
  begin
    if (Components[i] is TSQLQuery) then
    begin
      if (Components[i] as TSQLQuery).Name <> 'qLogList' then
        (Components[i] as TSQLQuery).Close
    end;
    if (Components[i] is TSQLTransaction) then
    begin
      if (Components[i] as TSQLTransaction).Name <> 'trLogList' then
        (Components[i] as TSQLTransaction).Rollback
    end
  end;
  for i := 0 to dmDXCluster.ComponentCount-1 do
  begin
    if (dmDXCluster.Components[i] is TSQLQuery) then
    begin
      (dmDXCluster.Components[i] as TSQLQuery).Close
    end;
    if (dmDXCluster.Components[i] is TSQLTransaction) then
    begin
      (dmDXCluster.Components[i] as TSQLTransaction).Rollback
    end
  end
end;

procedure TdmData.DeleteMySQLPidFile;
var
  res       : Byte;
  SearchRec : TSearchRec;
begin
  res := FindFirst(fHomeDir+'database/' + '*.pid', faAnyFile, SearchRec);
  while Res = 0 do
  begin
    if FileExists(fHomeDir+'database/' + SearchRec.Name) then
      DeleteFileUTF8(fHomeDir+'database/' + SearchRec.Name);
    Res := FindNext(SearchRec)
  end;
  FindClose(SearchRec)
end;

procedure TdmData.KillMySQL(const OnStart : Boolean = True);
var
  res       : Byte;
  SearchRec : TSearchRec;
  f         : TextFile;
  pid       : String = '';
  pidfile   : String = '';
  p         : TProcess;
begin
  res := FindFirst(fDataDir + '*.pid', faAnyFile, SearchRec);
  while Res = 0 do
  begin
    if fDebugLevel>=1 then Writeln(fDataDir + SearchRec.Name);
    if FileExists(fDataDir + SearchRec.Name) then
    begin
      pidfile := fDataDir + SearchRec.Name;
      AssignFile(f,pidfile);
      Reset(f);
      ReadLn(f,pid); //get process id from <computer-name.pid>
      pid := Trim(pid);
      CloseFile(f);
      break
    end;
    Res := FindNext(SearchRec)
  end;
  FindClose(SearchRec);

  if pid <> '' then
  begin
    p := TProcess.Create(nil);
    try
      p.Executable := 'kill';
      p.Parameters.Add(pid);
      if (dmData.DebugLevel>=1) or (fDebugLevel>=1) then Writeln('p.Executable: ',p.Executable,' Parameters: ',p.Parameters.Text);
      p.Execute;
      if OnStart then
        Sleep(3000);
      DeleteFileUTF8(pidfile);
      DeleteFileUTF8(fDataDir+'sock')
    finally
      p.Free
    end
  end
end;

procedure TdmData.PrepareDirectories;
begin
  //creting directory in $HOME/.config
  chdir(ExtractFilePath(ParamStr(0)));

  if not DirectoryExistsUTF8(fHomeDir) then
    CreateDirUTF8(fHomeDir);

  if not DirectoryExistsUTF8(fHomeDir+'database') then
    CreateDir(fHomeDir+'database');

  if not DirectoryExistsUTF8(fHomeDir+'members') then
    CreateDirUTF8(fHomeDir+'members');
  fMembersDir := fHomeDir+'members'+PathDelim;
  fGlobalMembersDir := ExpandFileNameUTF8('..'+PathDelim+'share'+PathDelim+'cqrlog'+
                       PathDelim+'members'+PathDelim);

  if DirectoryExistsUTF8(fHomeDir+'zipcodes') then
    fZipCodeDir := fHomeDir+'zipcodes'+PathDelim
  else
    fZipCodeDir := ExpandFileNameUTF8('..'+PathDelim+'share'+PathDelim+'cqrlog')+
                   PathDelim+'zipcodes'+PathDelim;

  if not DirectoryExistsUTF8(fHomeDir+'images') then
    CreateDirUTF8(fHomeDir+'images');

  fHelpDir := ExpandFileNameUTF8('..'+PathDelim+'share'+PathDelim+'cqrlog'+
              PathDelim+'help'+PathDelim);

  fShareDir := ExpandFileNameUTF8('..'+PathDelim+'share'+PathDelim+'cqrlog'+
               PathDelim);

  if not DirectoryExistsUTF8(fHomeDir + 'lotw') then
    CreateDirUTF8(fHomeDir + 'lotw');
  if not DirectoryExistsUTF8(fHomeDir + 'eQSL') then
    CreateDirUTF8(fHomeDir + 'eQSL');
  if not DirectoryExistsUTF8(fHomeDir + 'call_data') then
    CreateDirUTF8(fHomeDir + 'call_data');
  if not DirectoryExistsUTF8(fHomeDir+'dxcc_data') then
    CreateDirUTF8(fHomeDir+'dxcc_data');
  if not DirectoryExistsUTF8(fHomeDir+'ctyfiles') then
    CreateDirUTF8(fHomeDir+'ctyfiles');
  if not DirectoryExistsUTF8(fHomeDir+'xplanet') then
    CreateDirUTF8(fHomeDir+'xplanet');
  if not DirectoryExistsUTF8(fHomeDir+'voice_keyer') then
    CreateDirUTF8(fHomeDir+'voice_keyer');
  if not DirectoryExistsUTF8(fHomeDir+'dok_data') then
    CreateDirUTF8(fHomeDir+'dok_data')
end;

procedure TdmData.PrepareCtyData;
var
  s,d : String;
begin
  s := ExpandFileNameUTF8('..'+PathDelim+'share'+PathDelim+'cqrlog'+PathDelim+'ctyfiles'+PathDelim);
  d := fHomeDir+'ctyfiles'+PathDelim;

  if not FileExistsUTF8(fHomeDir+'ctyfiles'+PathDelim+'AreaOK1RR.tbl') then
  begin
    if fDebugLevel>=1 then
    begin
      Writeln('');
      Writeln('Ctyfiles dir: ',ExpandFileNameUTF8(s));
      Writeln('Local ctyfiles dir: ',d)
    end;

    CopyFile(s+'AreaOK1RR.tbl',d+'AreaOK1RR.tbl',True);
    CopyFile(s+'CallResolution.tbl',d+'CallResolution.tbl',True);
    CopyFile(s+'Country.tab',d+'Country.tab',True);
    CopyFile(s+'CountryDel.tab',d+'CountryDel.tab',True);
    CopyFile(s+'Ambiguous.tbl',d+'Ambiguous.tbl',True);
    CopyFile(s+'Exceptions.tab',d+'Exceptions.tab',True);
    CopyFile(s+'iota.tbl',d+'iota.tbl',True);
    CopyFile(s+'qslmgr.csv',d+'qslmgr.csv',True)
  end;

  //us states
  if not FileExistsUTF8(d+'us_states.tab') then
    CopyFile(s+'us_states.tab',d+'us_states.tab');

  if not FileExistsUTF8(fHomeDir+'lotw1.txt') then
    CopyFile(s+'lotw1.txt',fHomeDir+'lotw1.txt',True);
  if not FileExistsUTF8(fHomeDir+'eqsl.txt') then
    CopyFile(s+'eqsl.txt',fHomeDir+'eqsl.txt',True);
  if not FileExistsUTF8(fHomeDir+'MASTER.SCP') then
    CopyFile(s+'MASTER.SCP',fHomeDir+'MASTER.SCP',True);

  if not FileExistsUTF8(fHomeDir+'sat_name.tab') then
    CopyFile(s+'sat_name.tab', fHomeDir+'sat_name.tab');
  if not FileExistsUTF8(fHomeDir+'prop_mode.tab') then
    CopyFile(s+'prop_mode.tab', fHomeDir+'prop_mode.tab')
end;

procedure TdmData.PrepareDXCCData;
var
  l,ll : TStringList;
begin
  if FileExistsUTF8(fHomeDir+'dxcc_data'+PathDelim+'country.tab') then
    exit;
  l  := TStringList.Create;
  ll := TStringList.Create;
  try
    l.Clear;
    ll.Clear;
    ll.LoadFromFile(fHomeDir+'ctyfiles'+PathDelim+'Country.tab');
    l.AddStrings(ll);
    ll.LoadFromFile(fHomeDir+'ctyfiles'+PathDelim+'CallResolution.tbl');
    l.AddStrings(ll);
    ll.LoadFromFile(fHomeDir+'ctyfiles'+PathDelim+'AreaOK1RR.tbl');
    l.AddStrings(ll);
    l.SaveToFile(fHomeDir+'dxcc_data'+PathDelim+'country.tab');
    CopyFile(fHomeDir+'ctyfiles'+PathDelim+'CountryDel.tab',
             fHomeDir+'dxcc_data'+PathDelim+'country_del.tab');
    CopyFile(fHomeDir+'ctyfiles'+PathDelim+'Exceptions.tab',
             fHomeDir+'dxcc_data'+PathDelim+'exceptions.tab');
    CopyFile(fHomeDir+'ctyfiles'+PathDelim+'Ambiguous.tbl',
             fHomeDir+'dxcc_data'+PathDelim+'ambiguous.tab')
  finally
    l.Free;
    ll.Free
  end
end;

procedure TdmData.PrepareXplanetDir;
var
  s,d : String;
begin
  s := ExpandFileNameUTF8('..'+PathDelim+'share'+PathDelim+'cqrlog'+PathDelim+'xplanet'+PathDelim);
  d := fHomeDir+'xplanet'+PathDelim;
  if not FileExistsUTF8(d+'geoconfig') then
    CopyFile(s+'geoconfig',d+'geoconfig')
end;

procedure TdmData.PrepareVoice_keyerDir;
var
  s,d : String;
begin
  s := ExpandFileNameUTF8('..'+PathDelim+'share'+PathDelim+'cqrlog'+PathDelim+'voice_keyer'+PathDelim);
  d := fHomeDir+'voice_keyer'+PathDelim;
  if not FileExistsUTF8(d+'voice_keyer.sh') then
    CopyFile(s+'voice_keyer.sh',d+'voice_keyer.sh')
end;

function TdmData.FindLib(const Path,LibName : String) : String;
var
  l : TStringList;
begin
  l:= FindAllFiles(Path, LibName, False);
  if (l.Count=0) then
  begin
    Result := ''
  end
  else begin
    Result := l.Strings[0]
  end;
  {
  res := FindFirst(Path + LibName, faAnyFile, SearchRec);
  try
    while Res = 0 do
    begin
      Writeln(Path + SearchRec.Name);
      if FileExistsUTF8(Path + SearchRec.Name) then
      begin
        Result := (Path + SearchRec.Name);
        Break
      end;
      Res := FindNext(SearchRec)
    end
  finally
    FindClose(SearchRec)
  end
 end; }
end;

procedure TdmData.DataModuleCreate(Sender: TObject);
var
  lib    : String;
  i      : Integer;
  c      : TConnectionName;
  MySQLVer : String;
  param    : String;
  AProcess: TProcess;
  AStringList: TStringList;

begin
  InitCriticalSection(csPreviousQSO);
  cqrini       := nil;
  IsSFilter    := False;
  fDLLSSLName  := '';
  fDLLUtilName := '';

  fDebugLevel := GetDebugLevel;

  Writeln('');
  Writeln('Cqrlog Ver:',cVERSION,' Date:',cBUILD_DATE);
  Writeln('**** DEBUG LEVEL ',fDebugLevel,' ****');
  if fDebugLevel=0 then
   Begin
    Writeln('**** CHANGE WITH --debug=NR PARAMETER ****');
    Writeln('*** Parameter -h or --help for details ***');
   end;
  Writeln('');

  Writeln('OS:');
  AProcess := TProcess.Create(nil);
  AStringList := TStringList.Create;
  Try
  AProcess.Executable := 'cat';
  AProcess.Parameters.Add('/proc/version');
  AProcess.Options := AProcess.Options + [poWaitOnExit, poUsePipes];
  AProcess.Execute;
  AStringList.LoadFromStream(AProcess.Output);
  for i:=0 to pred(AStringList.Count) do
    writeln(AStringList[i]);
  except
    writeln('Could not get Linux version! [tried: cat /proc/version]');
  end;
  AStringList.Free;
  AProcess.Free;

  if fDebugLevel>0 then
  begin
    Writeln('SSL libraries:');
    Writeln('   ',DLLSSLName);
    Writeln('   ',DLLUtilName)
  end;

  CreateDBConnections;

  MainCon.KeepConnection := True;
  MainCon.Transaction := trmQ;
  for i:=0 to ComponentCount-1 do
  begin
    if Components[i] is TSQLQuery then
      (Components[i] as TSQLQuery).DataBase := MainCon;
    if Components[i] is TSQLTransaction then
      (Components[i] as TSQLTransaction).DataBase := MainCon
  end;

  //special connection for band map thread
  BandMapCon.Transaction    := trBandMapFil;
  qBandMapFil.Transaction   := trBandMapFil;
  qBandMapFil.DataBase      := BandMapCon;
  trBandMapFil.DataBase     := BandMapCon;

  RbnMonCon.Transaction    := trRbnMon;
  qRbnMon.Transaction      := trRbnMon;
  qRbnMon.DataBase         := RbnMonCon;
  trRbnMon.DataBase        := RbnMonCon;

  FormatSettings.ShortDateFormat := 'yyyy-mm-dd';

  reg := TRegExpr.Create;
  fVersionString := cVERSION;
  fOrderBy := 'qsodate,time_on';

  fHomeDir    := GetAppConfigDir(False);
  fDataDir    := fHomeDir+'database/';
  fUsrHomeDir := copy(fHomeDir,1,Pos('.config',fHomeDir)-1);

  PrepareDirectories;
  PrepareCtyData;
  PrepareDXCCData;
  PrepareXplanetDir;
  PrepareVoice_keyerDir;
  LoadLoTWCalls;
  LoadeQSLCalls;
  LoadMasterSCP;

  cqrini := TMyIni.Create(fHomeDir+'cqrlog.cfg',fHomeDir+'local.cfg');

  //Mysql still may be running, so we must close it first
  KillMySQL;

  if fDebugLevel>=1 then
  begin
    Writeln('*');
    Writeln('User home directory:    ',fUsrHomeDir);
    Writeln('Program home directory: ',fHomeDir);
    Writeln('Data directory:         ',fDataDir);
    Writeln('Memebers directory:     ',fMembersDir);
    Writeln('ZIP code directory:     ',fZipCodeDir);
    Writeln('Binary dir:             ',ExtractFilePath(Paramstr(0)));
    Writeln('Share dir:              ',fShareDir);
    Writeln('*')
  end;

  tmrDBPing.Interval := CDB_PING_INT*1000;
  tmrDBPing.Enabled  := True;
end;

procedure TdmData.DataModuleDestroy(Sender: TObject);
begin
  DeleteOldConfigFiles;
  if dmData.DebugLevel>=1 then Writeln('Closing dData');
  qCQRLOG.Close;
  reg.Free;
  DeleteFile(dmData.HomeDir + 'xplanet'+PathDelim+'marker');
  BandMapCon.Connected := False;
  MainCon.Connected := False;
  DoneCriticalsection(csPreviousQSO);
  KillMySQL(False)
end;

procedure TdmData.Q1BeforeOpen(DataSet: TDataSet);
begin
  if fDebugLevel >=1 then Writeln(Q1.SQL.Text)
end;

procedure TdmData.Q2BeforeOpen(DataSet: TDataSet);
begin
   if fDebugLevel >=1 then Writeln(Q2.SQL.Text)
end;

procedure TdmData.qBandsBeforeOpen(DataSet: TDataSet);
begin
  if fDebugLevel>=1 then Writeln(qBands.SQL.Text)
end;

procedure TdmData.QBeforeOpen(DataSet: TDataSet);
begin
  if fDebugLevel >=1 then Writeln(Q.SQL.Text)
end;

procedure TdmData.mQBeforeOpen(DataSet: TDataSet);
begin
  if fDebugLevel>=1 then Writeln(mQ.SQL.Text)
end;

procedure TdmData.qCQRLOGBeforeOpen(DataSet: TDataSet);
begin
  if fDebugLevel>=1 then Writeln(qCQRLOG.SQL.Text)
end;

procedure TdmData.qLogListBeforeOpen(DataSet: TDataSet);
begin
  if fDebugLevel>=1 then Writeln(qLogList.SQL.Text)
end;

procedure TdmData.qLongNoteBeforeOpen(DataSet: TDataSet);
begin
  if fDebugLevel >=1 then Writeln(qLongNote.SQL.Text)
end;
procedure TdmData.W1BeforeOpen(DataSet: TDataSet);
begin
   if fDebugLevel >=1 then Writeln(W1.SQL.Text)
end;
procedure TdmData.WBeforeOpen(DataSet: TDataSet);
begin
   if fDebugLevel >=1 then Writeln(W.SQL.Text)
end;

procedure TdmData.scLogException(Sender: TObject; Statement: TStrings;
  TheException: Exception; var Continue: boolean);
begin
  {
  Writeln('Statement:',Statement.Text);
  Writeln('Exception:',TheException.Message);
  Continue := False
  }
end;

procedure TdmData.scViewsException(Sender: TObject; Statement: TStrings;
  TheException: Exception; var Continue: boolean);
begin
  {
  Writeln('Statement:',Statement.Text);
  Writeln('Exception:',TheException.Message);
  Continue := False
  }
end;

procedure TdmData.tmrDBPingTimer(Sender: TObject);
{
var
  pq : TSQLQuery;
  tq : TSQLTransaction;
}
begin
{
  pq := TSQLQuery.Create(nil);
  tq := TSQLTransaction.Create(nil);
  try
    if (MainCon.Connected) and (fDBName<>'') then
    begin
      pq.DataBase := MainCon;
      tq.DataBase := MainCon;
      pq.Transaction := tq;
      pq.SQL.Text := 'select * from '+fDBName+'.db_version';
      tq.StartTransaction;
      if fDebugLevel>=1 then Writeln('DBPing - ',pq.SQL.Text);
      pq.Open;
      pq.Close;
      tq.Rollback;
      pq.DataBase := dmDXCluster.dbDXC;
      tq.DataBase := dmDXCluster.dbDXC;
      pq.Transaction := tq;
      pq.SQL.Text := 'select * from '+fDBName+'.db_version';
      tq.StartTransaction;
      if fDebugLevel>=1 then Writeln('DBPing - ',pq.SQL.Text);
      pq.Open;
      pq.Close;
      tq.Rollback
    end
  finally
    pq.Free;
    tq.Free
  end
}
end;


procedure TdmData.SaveQSO(date : TDateTime; time_on,time_off,call : String; freq : Currency;mode,rst_s,
                 rst_r, stn_name,qth,qsl_s,qsl_r,qsl_via,iota,pwr : String; itu,waz : Integer;
                 loc, my_loc,county,award,remarks : String; adif : Integer;
                 idcall,state,dok,cont : String; qso_dxcc : Boolean; profile : Integer;
                 nclub1,nclub2,nclub3,nclub4,nclub5, PropMode, Satellite : String;
                 RxFreq : Currency;srx : String;stx : String;srx_string : String;stx_string : String;
                 contestname : String; Op : String);
var
  qsodate : String;
  band    : String;
  changed : Integer;
  sWAZ, sITU : String;
  rx_freq : String;
begin
  Q.Close;
  if dmData.trQ.Active then
    dmData.trQ.Rollback;
  band := dmUtils.GetBandFromFreq(CurrToStr(freq));
  if qso_dxcc then
    changed := 1
  else
    changed := 0;
  sWAZ := IntToStr(waz);
  sITU := IntToStr(itu);
  if waz = 0 then
    sWAZ := 'null';
  if itu = 0 then
    sITU := 'null';
  rx_freq := FloatToStr(RxFreq);
  if (rx_freq = '0') then
    rx_freq := 'null';
  qsl_via := copy(qsl_via,1,30);
  award   := copy(award,1,50);
  state   := copy(state,1,4);
  dok     := UpperCase(copy(dok,1,12));
  cont    := UpperCase(copy(cont,1,2));
  qth     := copy(qth,1,60);
  trQ.StartTransaction;
  qsodate := (FormatDateTime('YYYY-MM-DD',date));
  Q.SQL.Text :=  'insert into cqrlog_main (qsodate,time_on,time_off,callsign,freq,mode,'+
                 'rst_s,rst_r,name,qth,qsl_s,qsl_r,qsl_via,iota,pwr,itu,waz,loc,my_loc,'+
                 'county,award,remarks,adif,idcall,state,qso_dxcc,band,profile,cont,club_nr1,'+
                 'club_nr2,club_nr3,club_nr4,club_nr5, prop_mode, satellite, rxfreq, srx, stx,'+
                 'srx_string, stx_string, contestname, dok, operator) values('+QuotedStr(qsodate) +
                 ','+QuotedStr(time_on)+','+QuotedStr(time_off)+
                 ','+QuotedStr(call)+','+FloatToStr(freq)+
                 ','+QuotedStr(mode)+','+QuotedStr(rst_s)+
                 //','+QuotedStr(rst_r)+','+QuotedStr(dmUtils.MyTrim(stn_name))+
                 //','+QuotedStr(dmUtils.MyTrim(qth))+','+QuotedStr(qsl_s)+
                 ','+QuotedStr(rst_r)+','+QuotedStr(trim(stn_name))+
                 ','+QuotedStr(trim(qth))+','+QuotedStr(qsl_s)+
                 ','+QuotedStr(qsl_r)+','+QuotedStr(qsl_via)+
                 ','+QuotedStr(iota)+','+QuotedStr(pwr)+
                 ','+sITU+','+sWAZ+
                    //here we make final check that for now on locator writing format is by std in database
                 ','+QuotedStr(dmUtils.StdFormatLocator(loc))+','+QuotedStr(dmUtils.StdFormatLocator(my_loc))+
                 //','+QuotedStr(dmUtils.MyTrim(county))+',' + QuotedStr(dmUtils.MyTrim(award)) + ','+QuotedStr(dmUtils.MyTrim(remarks))+
                 ','+QuotedStr(trim(county))+',' + QuotedStr(trim(award)) + ','+QuotedStr(trim(remarks))+
                 ','+IntToStr(adif)+','+ QuotedStr(idcall) + ','+ QuotedStr(state) +','+IntToStr(changed)+
                 ','+QuotedStr(band)+','+ IntToStr(profile) +','+QuotedStr(cont)+
                 ','+QuotedStr(nclub1)+','+QuotedStr(nclub2)+','+QuotedStr(nclub3)+
                 ','+QuotedStr(nclub4)+','+QuotedStr(nclub5)+','+QuotedStr(PropMode)+','+QuotedStr(Satellite)+','+rx_freq+
                 ','+QuotedStr(srx)+','+QuotedStr(stx)+','+QuotedStr(srx_string)+','+QuotedStr(stx_string)+','+QuotedStr(contestname)+
                 ','+QuotedStr(dok);
  if (Op <> '') then
     Q.SQL.Text := Q.SQL.Text+','+QuotedStr(Op)+')'
  else
     Q.SQL.Text := Q.SQL.Text+', NULL)';
  if fDebugLevel >=1 then
    Writeln(Q.SQL.Text);
  Q.ExecSQL;
  trQ.Commit
end;

procedure TdmData.EditQSO(date : TDateTime; time_on,time_off,call : String; freq : Currency;mode,rst_s,
                 rst_r, stn_name,qth,qsl_s,qsl_r,qsl_via,iota,pwr : String; itu,waz : Integer;
                 loc, my_loc,county,award,remarks : String; adif : Word; idcall,state,dok,cont : String;
                 qso_dxcc : Boolean; profile : Integer; PropMode, Satellite : String;
                 RxFreq : Currency; idx : LongInt;srx : String;stx : String;srx_string : String;stx_string : String;
                 contestname : String; Op : String);
var
  qsodate : String;
  band    : String;
  changed : Integer;
  sWAZ, sITU : String;
  rx_freq : String;
begin
  Q.Close;
  if trQ.Active then trQ.Rollback;
  band  := dmUtils.GetBandFromFreq(CurrToStr(freq));
  state := copy(state,1,4);
  if qso_dxcc then
    changed := 1
  else
    changed := 0;
  sWAZ := IntToStr(waz);
  sITU := IntToStr(itu);
  if waz = 0 then
    sWAZ := 'null';
  if itu = 0 then
    sITU := 'null';
  rx_freq := FloatToStr(RxFreq);
  if (rx_freq = '0') then
    rx_freq := 'null';

  dok  := UpperCase(copy(dok,1,12));
  cont := UpperCase(copy(cont,1,2));
  qth  := copy(qth,1,60);
  qsodate := (FormatDateTime('YYYY-MM-DD',date));
  Q.SQL.Text := 'UPDATE cqrlog_main set qsodate = '+ QuotedStr(qsodate) +', time_on = '+QuotedStr(time_on) +
           ', time_off = ' + QuotedStr(time_off) + ', callsign = '+QuotedStr(call) +
           ', freq = ' + FloatToStr(freq) + ', mode = ' + QuotedStr(mode) +
           ', rst_s = ' + QuotedStr(rst_s) + ', rst_r = ' + QuotedStr(rst_r)+ ', qsl_s = '+QuotedStr(qsl_s)+
           ', qsl_r =' + QuotedStr(qsl_r) + ', qsl_via = ' + QuotedStr(qsl_via) + ', iota = ' + QuotedStr(iota)+
           ', pwr = ' + QuotedStr(pwr) + ', waz = ' + sWAZ +
           ', itu = ' + sITU + ', loc = ' + QuotedStr(loc) +
           ', my_loc = ' + QuotedStr(my_loc) + ', county = ' + QuotedStr(county) +
           ', remarks = ' + QuotedStr(Trim(remarks)) + ', adif = ' + IntToStr(adif) +
           ', qso_dxcc = '+ IntToStr(changed) + ', name = ' +QuotedStr(Trim(stn_name)) +
           ', qth = ' + QuotedStr(Trim(qth)) + ', award = ' + QuotedStr(award) +', band = ' + QuotedStr(band) +
           ', profile = ' + IntToStr(profile) + ', idcall = ' + QuotedStr(idcall) + ', state=' + QuotedStr(state) +
           ', cont = ' + QuotedStr(cont)+ ', prop_mode = ' + QuotedStr(PropMode) + ', satellite = ' + QuotedStr(Satellite)+
           ', rxfreq = ' + rx_freq + ', stx = ' + QuotedStr(stx)+ ', stx_string = ' + QuotedStr(stx_string) + ', srx = ' + QuotedStr(srx)+
           ', srx_string = ' + QuotedStr(srx_string) + ', contestname = ' + QuotedStr(contestname) + ', dok = ' + QuotedStr(dok);
  if (Op <> '') then
    Q.SQL.Text := Q.SQL.Text+', operator = ' + QuotedStr(Op)
  else
    Q.SQL.Text := Q.SQL.Text+', operator = NULL';
  Q.SQL.Text := Q.SQL.Text+' where id_cqrlog_main = ' + IntToStr(idx);
  if fDebugLevel >=1 then
    Writeln(Q.SQL.Text);
  trQ.StartTransaction;
  Q.ExecSQL;
  trQ.Commit;
  Q.Close;
end;

procedure TdmData.SaveComment(call,text : String);
const
  C_SEL = 'select id_notes from notes where callsign = %s limit 1';
  C_DEL = 'delete from notes where callsign = %s';
  C_INS = 'insert into notes (callsign, longremarks) values (%s, %s)';
  C_UPD = 'update notes set longremarks = %s where callsign = %s';
begin
  text := Trim(text);
  if fDebugLevel >=1 then Writeln('Note:',text);
  qComment.Close;
  if trComment.Active then trComment.Rollback;

  try try
    trComment.StartTransaction;
    qComment.SQL.Text := Format(C_SEL, [QuotedStr(call)]);
    qComment.Open;

    if (text = '') and (qComment.Fields[0].IsNull) then
      exit; //nothing to save

    if (text = '') and (not qComment.Fields[0].IsNull) then
    begin                //user deleted the note
      qComment.Close;
      qComment.SQL.Text := Format(C_DEL, [QuotedStr(call)]);
      qComment.ExecSQL;
      exit
    end;

    if qComment.Fields[0].IsNull then
    begin
      qComment.Close;
      qComment.SQL.Text := Format(C_INS, [QuotedStr(call), QuotedStr(text)]);
      qComment.ExecSQL
    end
    else begin
      qComment.Close;
      qComment.SQL.Text := Format(C_UPD, [QuotedStr(text), QuotedStr(call)]);
      qComment.ExecSQL
    end
  except
    on E : Exception do
    begin
      ShowMessage('Error saving comment to QSO.'+LineEnding+E.Message);
      trComment.Rollback
    end
  end
  finally
    if trComment.Active then
      trComment.Commit;
    qComment.Close
  end
end;

function TdmData.GetComment(call : String) : String;
begin
  qComment.Close;
  trComment.StartTransaction;
  qComment.SQL.Text := 'SELECT longremarks FROM notes WHERE callsign = ' + QuotedStr(call);
  qComment.Open;
  Result := qComment.Fields[0].AsString;
  qComment.Close;
  trComment.Rollback
end;

procedure TdmData.DeleteComment(id : Integer);
const
  C_DEL = 'delete from notes where id_notes = %d';

begin
  qComment.Close;
  if trComment.Active then
    trComment.Rollback;

  trComment.StartTransaction;
  try try
    qComment.SQL.Text := Format(C_DEL,[id]);
    qComment.ExecSQL
  except
    on E : Exception do
    begin
      Writeln(E.Message);
      trComment.Rollback
    end
  end
  finally
    if trComment.Active then
      trComment.Commit
  end
end;

function TdmData.CallNoteExists(Callsign : String) : Boolean;
const
  C_SEL = 'select id_notes from notes where callsign=%s';
begin
  Result := False;
  if dmData.trQ.Active then
    dmData.trQ.Rollback;
  dmData.trQ.StartTransaction;
  try
    dmData.Q.SQL.Text := Format(C_SEL,[QuotedStr(Callsign)]);
    dmData.Q.Open;
    Result := dmData.Q.RecordCount > 0
  finally
    dmData.Q.Close;
    dmData.trQ.Rollback
  end
end;

procedure TdmData.PrepareImport;
begin
  if dmData.trQ.Active then
    dmData.trQ.Rollback;
  dmData.trQ.StartTransaction;
  dmData.Q.SQL.Text := 'DROP INDEX main_index ON cqrlog_main';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'DROP INDEX callsign ON cqrlog_main;';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'DROP INDEX name ON cqrlog_main;';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'DROP INDEX qth ON cqrlog_main;';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'DROP INDEX adif ON cqrlog_main;';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'DROP INDEX idcall ON cqrlog_main';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'DROP INDEX band ON cqrlog_main';
  dmData.Q.ExecSQL;
  {
  dmData.Q.SQL.Text := 'DROP INDEX club_nr1 ON cqrlog_main';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'DROP INDEX club_nr2 ON cqrlog_main';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'DROP INDEX club_nr3 ON cqrlog_main';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'DROP INDEX club_nr4 ON cqrlog_main';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'DROP INDEX club_nr5 ON cqrlog_main';
  dmData.Q.ExecSQL;
  }
  dmData.trQ.Commit
end;

procedure TdmData.DoAfterImport;
begin
  if dmData.trQ.Active then
    dmData.trQ.Rollback;
  dmData.trQ.StartTransaction;
  dmData.Q.SQL.Text := 'CREATE INDEX main_index ON cqrlog_main(qsodate DESC,time_on DESC);';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'CREATE INDEX callsign ON cqrlog_main(callsign);';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'CREATE INDEX name ON cqrlog_main(name);';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'CREATE INDEX qth ON cqrlog_main(QTH);';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'CREATE INDEX adif ON cqrlog_main(adif);';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'CREATE INDEX idcall ON cqrlog_main(idcall);';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'CREATE INDEX band ON cqrlog_main(band);';
  dmData.Q.ExecSQL;
  {
  dmData.Q.SQL.Text := 'CREATE INDEX club_nr1 ON cqrlog_main(club_nr1);';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'CREATE INDEX club_nr2 ON cqrlog_main(club_nr2);';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'CREATE INDEX club_nr3 ON cqrlog_main(club_nr3);';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'CREATE INDEX club_nr4 ON cqrlog_main(club_nr4);';
  dmData.Q.ExecSQL;
  dmData.Q.SQL.Text := 'CREATE INDEX club_nr5 ON cqrlog_main(club_nr5);';
  dmData.Q.ExecSQL;
  }
  dmData.trQ.Commit
end;

procedure TdmData.PrepareBandDatabase;
begin
  trQ.StartTransaction;
  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                 QuotedStr('2190M')+',0.135,0.139,0.135,0.139,0.139)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                 QuotedStr('630M')+',0.472,0.480,0.472,0.472,0.480)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('160M')+',1.80,2.0,1.838,1.839,1.843)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('80M')+',3.5,3.8,3.580,3.580,3.620)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('60M')+',5.0,5.9,5.2,5.2,5.3)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('40M')+',7.0,7.200,7.035,7.035,7.043)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('30M')+',10.100,10.150,10.140,10.142,10.150)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('20M')+',14.000,14.350,14.070,14.070,14.112)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('17M')+',18.068,18.168,18.095,18.095,18.111)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('15M')+',21.000,21.450,21.070,21.070,21.120)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('12M')+',24.890,24.990,24.915,24.915,24.931)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('10M')+',28.000,30.000,28.070,28.070,28.300)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                         QuotedStr('8M')+',40.0000,45.0000,40.3000,40.3000,40.6800)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('6M')+',50.000,52.000,50.110,50.110,50.120)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                       QuotedStr('5M')+',54.0000,69.9000,59.5000,59.6000,59.6000)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('4M')+',70.000,71.000,70.150,70.150,70.150)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('2M')+',144.00,146.00,144.110,144.110,144.150)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('1.25M')+',219.00,225.00,221.0,221.0,222.0)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('70CM')+',430.000,440.000,432.100,432.100,433.600)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('33CM')+',902.000,928.000,903.000,903.000,910.000)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('23CM')+',1240.000,1300.000,1245.000,1250.000,1260.000)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('13CM')+',2300,2450,2310,2310,2320)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('9CM')+',3400,3475,3400,3400,3420)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('6CM')+',5650,5850,5670,5670,5675)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('3CM')+',10000,10500,10500,10500,10500)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('1.25CM')+',24000,24250,24240,24250,24250)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('6MM')+',47000,47200,47100,47100,47200)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('4MM')+',75500,81500,75500,81500,81500)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('2.5MM')+',122250,123000,122250,123000,123000)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('2MM')+',134000,141000,141000,141000,141000)';
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                QuotedStr('1MM')+',241000,248000,241000,248000,248000)';
  Q.ExecSQL;

  trQ.Commit;
  Q.Close
           //band,begin,end,cw,rtty,ssb - cw to, rtty from, ssb from
end;

function TdmData.QueryLocate(qry : TSQLQuery; Column : String; Value : Variant; DisableGrid : Boolean; exatly : Boolean = True) : Boolean;
//
// Workaround for bug http://mantis.freepascal.org/bug_view_page.php?bug_id=17624
//
begin
  Result := False;
  if DisableGrid then
    qry.DisableControls;
  qry.First;
  try
    while not qry.EOF do
    begin
      if exatly then
      begin
        if UpperCase(qry.FieldByName(Column).AsVariant) = UpperCase(Value) then
        begin
          Result := True;
          break
        end
        else
          qry.Next
      end
      else begin
        if Pos(UpperCase(Value),UpperCase(qry.FieldByName(Column).AsVariant))=1 then
        begin
          Result := True;
          break
        end
        else
          qry.Next
      end
    end
  finally
    if DisableGrid then
      qry.EnableControls
  end
end;


procedure TdmData.InsertProfiles(cmbProfile : TComboBox; ShowAll : Boolean);
var
  loc, qth, rig : Boolean;
begin
  loc := cqrini.ReadBool('Profiles','Locator',True);
  qth := cqrini.ReadBool('Profiles','QTH',True);
  rig := cqrini.ReadBool('Profiles','RIG',False);
  InsertProfiles(cmbProfile,ShowAll,loc,qth,rig)
end;

procedure TdmData.InsertProfiles(cmbProfile : TComboBox; ShowAll,loc,qth,rig : Boolean);
var
  tmp : String;
begin
  cmbProfile.Clear;
  cmbProfile.Items.Add('');
  qProfiles.Close;
  if ShowAll then
    qProfiles.SQL.Text := 'SELECT * FROM profiles ORDER BY nr'
  else
    qProfiles.SQL.Text := 'SELECT * FROM profiles WHERE visible > 0 ORDER BY nr';
  if fDebugLevel >= 1 then Writeln(qProfiles.SQL.Text);
  if trProfiles.Active then
    trProfiles.Rollback;
  trProfiles.StartTransaction;
  qProfiles.Open;
  qProfiles.First;
  while not dmData.qProfiles.EOF do
  begin
    tmp := IntToStr(qProfiles.Fields[1].AsInteger)+'-';
    if loc then
      tmp := tmp + trim(qProfiles.Fields[2].AsString)+';';
    if qth then
      tmp := tmp + trim(qProfiles.Fields[3].AsString)+';';
    if rig then
      tmp := tmp + trim(qProfiles.Fields[4].AsString)+';';
    cmbProfile.Items.Add(tmp);
    qProfiles.Next
  end
end;

function TdmData.GetProfileText(nr : Integer) : String;
var
  loc, qth, rig : Boolean;
  tmp : String;
begin
  Result := '';
  if nr = 0 then
    exit;

  loc := cqrini.ReadBool('Profiles','Locator',True);
  qth := cqrini.ReadBool('Profiles','QTH',True);
  rig := cqrini.ReadBool('Profiles','RIG',False);

  qProfiles.Close;
  qProfiles.SQL.Text := 'SELECT * FROM profiles WHERE nr = '+IntToStr(nr);
  if fDebugLevel >=1 then Writeln(qProfiles.SQL.Text);
  if trProfiles.Active then
    trProfiles.Rollback;
  trProfiles.StartTransaction;
  try
    qProfiles.Open;
    if qProfiles.RecordCount > 0 then
    begin
      tmp := IntToStr(qProfiles.Fields[1].AsInteger)+'-';
      if loc then
        tmp := tmp + trim(qProfiles.Fields[2].AsString)+';';
      if qth then
        tmp := tmp + trim(qProfiles.Fields[3].AsString)+';';
      if rig then
        tmp := tmp + trim(qProfiles.Fields[4].AsString)+';';
      Result := tmp
    end
    else
      Result := ''
  finally
    qProfiles.Close;
    trProfiles.Rollback
  end
end;

function TdmData.GetCompleteProfileText(nr : Integer) : String;
var
  tmp : String;
begin
  Result := '0|';
  if nr = 0 then
    exit;
  qProfiles.Close;
  qProfiles.SQL.Text := 'SELECT * FROM profiles WHERE nr = '+IntToStr(nr);
  if fDebugLevel >=1 then Writeln(qProfiles.SQL.Text);
  if trProfiles.Active then
    trProfiles.Rollback;
  trProfiles.StartTransaction;
  try
    qProfiles.Open;
    if qProfiles.RecordCount > 0 then
    begin
      tmp := IntToStr(qProfiles.Fields[1].AsInteger)+'|';
      tmp := tmp + trim(qProfiles.Fields[2].AsString)+'|';
      tmp := tmp + trim(qProfiles.Fields[3].AsString)+'|';
      tmp := tmp + trim(qProfiles.Fields[4].AsString)+'|';
      Result := tmp
    end
  finally
     qProfiles.Close;
     trProfiles.Rollback
  end
end;

function TdmData.GetNRFromProfile(text : String) : Integer;
var
  tmp : String;
begin
  if text = '' then
    Result := -1
  else
    tmp := copy(text,1,Pos('-',text)-1);
  if NOT TryStrToInt(tmp, Result) then
    Result := -1
end;

function TdmData.GetDefaultProfileText : String;
var
  p : Integer;
begin
  p := cqrini.ReadInteger('Profiles','Selected',0);
  Result := GetProfileText(p)
end;

procedure TdmData.PrepareDXClusterDatabase;
begin
  Q.Close;
  trQ.StartTransaction;
  Q.SQL.Text := 'INSERT INTO dxclusters (description,address,port) ' +
                'VALUES ('+QuotedStr('OK0DXH') + ',' + QuotedStr('194.213.40.187') +
                ','+QuotedStr('41112')+')';
  if fDebugLevel >=1 then
    Writeln(Q.SQL.Text);
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO dxclusters (description,address,port) ' +
                'VALUES ('+QuotedStr('OZ2DXC') + ',' + QuotedStr('80.198.77.12') +
                ','+QuotedStr('8000')+')';
  if fDebugLevel >=1 then
    Writeln(Q.SQL.Text);
  Q.ExecSQL;

  Q.SQL.Text := 'INSERT INTO dxclusters (description,address,port) ' +
                'VALUES ('+QuotedStr('HamQTH') + ',' + QuotedStr('hamqth.com') +
                ','+QuotedStr('7300')+')';
  if fDebugLevel >=1 then
    Writeln(Q.SQL.Text);
  Q.ExecSQL;

  trQ.Commit
end;

procedure TdmData.RefreshMainDatabase(id : Integer = 0);
begin
  with TfrmWorking.Create(frmMain) do
  try
    idx := id;
    ShowModal
  finally
    Free
  end
end;

function TdmData.QSLMgrFound(call,date : String; var qsl_via : String) : Boolean;
begin
   // dmData.QSLMgrFound() needs date. if not set causes mysterious
   // "'' is not valid date error" sometimes. (usually at first logged qso)
   // So cheking both exist is needed.
  if (call = '') or (date = '') then
   Begin
     Result := False;
     Exit;
   end;

  qsl_via := '';
  trQSLMgr.StartTransaction;
  qQSLMgr.SQL.Text := 'select * from cqrlog_common.qslmgr where (callsign = '+QuotedStr(call)+
                      ') and (fromDate <= '+QuotedStr(date)+') order by fromDate';
  if fDebugLevel >=1 then Writeln(qQSLMgr.SQL.Text);
  qQSLMgr.Open();
  qQSLMgr.Last;
  if trim(qQSLMgr.Fields[1].AsString) <> '' then
  begin
    Result  := True;
    qsl_via := Trim(qQSLMgr.Fields[2].AsString)
  end
  else
    Result := False;
  qQSLMgr.Close();
  if trQSLMgr.Active then
    trQSLMgr.RollBack
end;

function TdmData.GetWAZInfoIndex(waz,freq : String) : Integer;
var
  iwaz : Integer=0;
  band : String='';
begin
  Result := 0;
  if (waz = '') then
    exit;
  if not TryStrToInt(waz,iwaz) then
    exit;
  if not ((iwaz > 0) and (iwaz < 41)) then
    exit;
  band := dmUtils.GetBandFromFreq(freq);
  Q.Close();
  Q.SQL.Text := 'select id_cqrlog_main FROM cqrlog_main WHERE waz = ' + waz +
                ' AND band = ' + QuotedStr(band) +
                ' AND ( QSL_R = ' + QuotedStr('Q')+ ' OR lotw_qslr= ' + QuotedStr('L')+
                ' OR eqsl_qsl_rcvd= ' + QuotedStr('E')+
                ') LIMIT 1';
  trQ.StartTransaction;
  Q.Open();
  if Q.Fields[0].AsInteger > 0 then
    Result := 4 //waz already confirmed
  else begin
    Q.Close();
    Q.SQL.Text := 'select id_cqrlog_main FROM cqrlog_main WHERE waz = ' + waz +
                  ' AND band = ' + QuotedStr(band) + ' LIMIT 1';
    Q.Open();
    if Q.Fields[0].AsInteger > 0 then
      Result := 3 //qsl needed
    else begin
      Q.Close();
      Q.SQL.Text := 'select id_cqrlog_main FROM cqrlog_main WHERE waz = ' + waz+
                    ' LIMIT 1';
      Q.Open();
      if Q.Fields[0].AsInteger > 0 then
        Result := 2 //new band waz zone
      else
        Result := 1 //new zone
    end
  end;
  trQ.RollBack;
  Q.Close()
end;

function TdmData.GetWAZInfoString(Index : Integer) : String;
begin
  Result := '';
  case Index of
    1 : Result := 'New WAZ zone!';
    2 : Result := 'New band WAZ zone!';
    3 : Result := 'QSL needed for WAZ!';
    4 : Result := 'WAZ zone already confirmed'
  end
end;

function TdmData.GetITUInfoIndex(itu,freq : String) : Integer;
var
  iitu : Integer=0;
  band : String='';
begin
  Result := 0;
  if (itu = '') then
    exit;
  if not TryStrToInt(itu,iitu) then
    exit;
  if not ((iitu > 0) and (iitu < 76)) then
    exit;
  band := dmUtils.GetBandFromFreq(freq);
  Q.Close();
  Q.SQL.Text := 'select id_cqrlog_main FROM cqrlog_main WHERE itu = ' + itu +
                ' AND band = ' + QuotedStr(band) +
                ' AND ( QSL_R = ' + QuotedStr('Q')+ ' OR lotw_qslr= ' + QuotedStr('L')+
                ' ) LIMIT 1';
  trQ.StartTransaction;
  Q.Open();
  if Q.Fields[0].AsInteger > 0 then
    Result := 4 //itu already confirmed
  else begin
    Q.Close();
    Q.SQL.Text := 'select id_cqrlog_main FROM cqrlog_main WHERE itu = ' + itu +
                  ' AND band = ' + QuotedStr(band)+' LIMIT 1';
    Q.Open();
    if Q.Fields[0].AsInteger > 0 then
      Result := 3 //qsl needed
    else begin
      Q.Close();
      Q.SQL.Text := 'select id_cqrlog_main FROM cqrlog_main WHERE itu = ' + itu+
                    ' LIMIT 1';
      Q.Open();
      if Q.Fields[0].AsInteger > 0 then
        Result := 2 //new band itu zone
      else
        Result := 1 //new zone
    end
  end;
  trQ.RollBack;
  Q.Close()
end;

function TdmData.GetITUInfoString(Index : Integer) : String;
begin
  Result := '';
  case Index of
    1 : Result := 'New ITU zone!';
    2 : Result := 'New band ITU zone!';
    3 : Result := 'QSL needed for ITU!';
    4 : Result := 'ITU zone already confirmed';
  end
end;

function TdmData.GetIOTAInfoIndex(iota : String) : Integer;
begin
  Result := 0;
  if not dmUtils.IsIOTAOK(iota) then
    exit;
  Q.Close();
  Q.SQL.Text := 'SELECT MAX(id_cqrlog_main) FROM cqrlog_main WHERE iota = ' + QuotedStr(iota) +
                ' AND QSL_R = ' + QuotedStr('Q');
  if fDebugLevel >= 1 then Writeln(Q.SQL.Text);
  trQ.StartTransaction;
  Q.Open();
  if Q.Fields[0].AsInteger > 0 then
    Result := 3 //iota already confirmed
  else begin
    Q.Close();
    Q.SQL.Text := 'SELECT MAX(id_cqrlog_main) FROM cqrlog_main WHERE iota = ' +
                  QuotedStr(iota);
    if fDebugLevel >= 1 then Writeln(Q.SQL.Text);
    Q.Open();
    if Q.Fields[0].AsInteger > 0 then
      Result := 2 //qsl needed
    else
      Result := 1 //new iota
  end;
  trQ.RollBack;
  Q.Close()
end;

function TdmData.GetIOTAInfoString(Index : Integer) : String;
begin
  Result := '';
  case Index of
    1 : Result := 'New IOTA!';
    2 : Result := 'QSL needed for IOTA!';
    3 : Result := 'IOTA already confirmed';
  end
end;

function TdmData.GetIOTAName(iota : String) : String;
begin
  Result := '';
  if not dmUtils.IsIOTAOK(iota) then
    exit;
  Q.Close;
  Q.SQL.Text := 'SELECT island_name FROM cqrlog_common.iota_list WHERE iota_nr = ' +
                       QuotedStr(iota);
  trQ.StartTransaction;
  Q.Open();
  Result := Q.Fields[0].AsString;
  trQ.RollBack;
  Q.Close()
end;

function TdmData.GetIOTAForDXCC(call,pref : String;cmbIOTA : TComboBox; date : TDateTime) : Boolean;
var
  tmp  : String = '';
begin
  if fDebugLevel>=1 then Writeln('GetIOTAForDXCC');
  Result := False;
  tmp := cmbIOTA.Text;
  cmbIOTA.Items.Clear;
  if (pref = '') or (pref='!') or (pref='#') or (pref = '?') then
   exit;
  Q.Close();
  Q.SQL.Text := 'SELECT iota_nr,pref FROM cqrlog_common.iota_list WHERE dxcc_ref = ' + QuotedStr(pref) +
                ' ORDER BY iota_nr';
  trQ.StartTransaction;
  Q.Open();
  Q.First;
  while not Q.Eof do
  begin
    cmbIOTA.Items.Add(Q.Fields[0].AsString);
    if Q.Fields[1].AsString <> '' then
    begin
      reg.Expression  := Q.Fields[1].AsString;
      reg.InputString := call;
      if reg.ExecPos(1) then
      begin
        tmp := Q.Fields[0].AsString;
      end;
    end;
    Q.Next;
  end;
  trQ.RollBack;
  Q.Close();
  Result := cmbIOTA.Items.Count > 0;
  cmbIOTA.Text := tmp
end;

procedure TdmData.LoadClubsSettings;
begin
  dmMembership.LoadClubSettings(1, dmMembership.Club1);
  dmMembership.LoadClubSettings(2, dmMembership.Club2);
  dmMembership.LoadClubSettings(3, dmMembership.Club3);
  dmMembership.LoadClubSettings(4, dmMembership.Club4);
  dmMembership.LoadClubSettings(5, dmMembership.Club5);

  if dmMembership.Club1.MainFieled = 'call' then
    dmMembership.Club1.MainFieled := 'idcall';
  if dmMembership.Club2.MainFieled = 'call' then
    dmMembership.Club2.MainFieled := 'idcall';
  if dmMembership.Club3.MainFieled = 'call' then
    dmMembership.Club3.MainFieled := 'idcall';
  if dmMembership.Club4.MainFieled = 'call' then
    dmMembership.Club4.MainFieled := 'idcall';
  if dmMembership.Club5.MainFieled = 'call' then
    dmMembership.Club5.MainFieled := 'idcall'
end;

procedure TdmData.LoadZipSettings;
var
  tmp    : String;
begin
  tmp := cqrini.ReadString('ZipCode','First','');
  Zip1.Name       := copy(tmp,1,Pos(';',tmp)-1);
  Zip1.LongName   := copy(tmp,Pos(';',tmp)+1,Length(tmp)-Pos(';',tmp)+1);
  Zip1.StoreField := cqrini.ReadString('ZipCode','FirstSaveTo','');
  Zip1.ZipPos     := cqrini.ReadInteger('ZipCode','FirstPos',0);
  Zip1.DXCC       := cqrini.ReadString('ZipCode','FirstDXCC','')+';';

  tmp := cqrini.ReadString('ZipCode','Second','');
  Zip2.Name       := copy(tmp,1,Pos(';',tmp)-1);
  Zip2.LongName   := copy(tmp,Pos(';',tmp)+1,Length(tmp)-Pos(';',tmp)+1);
  Zip2.StoreField := cqrini.ReadString('ZipCode','SecondSaveTo','');
  Zip2.ZipPos     := cqrini.ReadInteger('ZipCode','SecondPos',0);
  Zip2.DXCC       := cqrini.ReadString('ZipCode','SecondDXCC','')+';';

  tmp := cqrini.ReadString('ZipCode','Third','');
  Zip3.Name       := copy(tmp,1,Pos(';',tmp)-1);
  Zip3.LongName   := copy(tmp,Pos(';',tmp)+1,Length(tmp)-Pos(';',tmp)+1);
  Zip3.StoreField := cqrini.ReadString('ZipCode','ThirdSaveTo','');
  Zip3.ZipPos     := cqrini.ReadInteger('ZipCode','ThirdPos',0);
  Zip3.DXCC       := cqrini.ReadString('ZipCode','ThirdDXCC','')+';';
end;

function TdmData.FindCounty1(qth,pfx : String; var StoreTo : String) : String;
var
  ZipCode : String;
begin
  Result := '';
  if (Zip1.StoreField <> '') and (Zip1.Name<>'') and (Pos(pfx+';',Zip1.DXCC) > 0) then
  begin
    ZipCode  := dmUtils.ExtractZipCode(qth,Zip1.ZipPos);
    if fDebugLevel>=1 then Writeln('ZipCode: ',ZipCode);
    if trQ.Active then trQ.Rollback;
    Q.Close;
    Q.SQL.Text := 'SELECT county from zipcode1 where zip = '+QuotedStr(ZipCode);
    trQ.StartTransaction;
    Q.Open();
    Result  := Trim(Q.Fields[0].AsString);
    StoreTo := Zip1.StoreField;
    trQ.RollBack;
    Q.Close
  end
end;

function TdmData.FindCounty2(qth,pfx : String; var StoreTo : String) : String;
var
  ZipCode : String;
begin
  Result := '';
  if (Zip2.StoreField <> '') and (Zip2.Name<>'') and (Pos(pfx+';',Zip2.DXCC) > 0) then
  begin
    ZipCode    := dmUtils.ExtractZipCode(qth,Zip2.ZipPos);
    if trQ.Active then trQ.Rollback;
    Q.Close;
    Q.SQL.Text := 'SELECT county from zipcode2 where zip = '+QuotedStr(ZipCode);
    trQ.StartTransaction;
    Q.Open();
    Result  := Trim(Q.Fields[0].AsString);
    StoreTo := Zip2.StoreField;
    trQ.RollBack;
    Q.Close
  end
end;

function TdmData.FindCounty3(qth,pfx : String; var StoreTo : String) : String;
var
  ZipCode : String;
begin
  Result := '';
  if (Zip3.StoreField <> '') and (Zip3.Name<>'') and (Pos(pfx+';',Zip3.DXCC) > 0) then
  begin
    ZipCode    := dmUtils.ExtractZipCode(qth,Zip3.ZipPos);
    if trQ.Active then trQ.Rollback;
    Q.Close;
    Q.SQL.Text := 'SELECT county from zipcode3 where zip = '+QuotedStr(ZipCode);
    trQ.StartTransaction;
    Q.Open();
    Result  := Trim(Q.Fields[0].AsString);
    StoreTo := Zip3.StoreField;
    trQ.RollBack;
    Q.Close
  end
end;

function TdmData.GetMyLocFromProfile(profile : String) : String;
var
  nr : Integer;
begin
  nr := GetNRFromProfile(Profile);
  Q.Close;
  Q.SQL.Text := 'select locator from profiles where nr = '+IntToStr(nr);
  if fDebugLevel >= 1 then Writeln(Q.SQL.Text);
  trQ.StartTransaction;
  Q.Open();
  Result := Q.Fields[0].AsString;
  trQ.RollBack;
  Q.Close()
end;

function TdmData.SendQSL(call,mode,freq : String; adif : Word) : String;
begin
  Result := '';
  if cqrini.ReadBool('NewQSO','AutoQSLS',True) and (cqrini.ReadString('NewQSO','QSL_S','') <> '') then
  begin
    Result := cqrini.ReadString('NewQSO','QSL_S','');

    if cqrini.ReadBool('NewQSO','AutoDQSLS',False) or cqrini.ReadBool('NewQSO','AutoQQSLS',False) then
    begin
      Q.Close();
      trQ.StartTransaction;
      try
        Q.SQL.Text := 'select id_cqrlog_main from cqrlog_main where adif = '+
                      IntToStr(adif)+' and mode='+QuotedStr(mode)+' and qsl_s<>'+QuotedStr('');
        if not cqrini.ReadBool('NewQSO','AutoDQSLS',False) then
          Q.SQL.Text := Q.SQL.Text +  ' and callsign='+QuotedStr(call);
        Q.SQL.Text := Q.SQL.Text + ' LIMIT 1';
        Q.Open();
        if Q.Fields[0].AsInteger = 0 then
          Result := cqrini.ReadString('NewQSO','QSL_S','')
        else
          Result := ''
      finally
        Q.Close();
        trQ.Rollback
      end
    end
  end
end;

procedure TdmData.LoadLoTWCalls;

  procedure GrowArray(NextIndex: integer);
  begin
    if NextIndex >= Length(CallArray) then
      SetLength(CallArray, Length(CallArray) * 2);
  end;

var
  i : Integer;
  f : TextFile;
  a : String;
begin
  SetLength(CallArray, 1);
  i := 0;
  if FileExists(fHomeDir+'lotw1.txt') then
  begin
    AssignFile(f,fHomeDir+'lotw1.txt');
    Reset(f);
    while not Eof(f) do
    begin
      GrowArray(i);
      Readln(f,a);
      CallArray[i] := a;
      inc(i)
    end;
    if fDebugLevel>=1 then Writeln('Loaded ',i,' LoTW users');
    CloseFile(f)
  end;
  SetLength(CallArray, i); //Shrink the array
end;

procedure TdmData.LoadMasterSCP;
var
  i   : LongInt=1;
  f   : TextFile;
  tmp : String;
begin
  if FileExists(fHomeDir+'MASTER.SCP') then
  begin
    SetLength(aSCP,80000);
    AssignFile(f,fHomeDir+'MASTER.SCP');
    Reset(f);
    while not eof(f) do
    begin
      Readln(f,tmp);
      tmp := trim(tmp);
      if tmp = '' then
        Continue;
      if tmp[1]='#' then //skip comments
        Continue;
      aSCP[i-1] := tmp;
      inc(i);
      if i>80000 then
        SetLength(aSCP,100000)
    end;
    CloseFile(f);
    SetLength(aSCP,i);
    if fDebugLevel>=1 then Writeln('Loaded ',i,' SCP calls')
  end
end;

function TdmData.GetSCPCalls(call : String) : String;
var
  s : String = '';
  i : LongInt;
begin
  if call = '' then
    exit;
  for i:=0 to Length(aSCP)-1 do
  begin
   if Pos(call,aSCP[i]) > 0 then
      s := s + ' ' + aSCP[i]
    {else if Pos(aSCP[i],call) > 0 then
      s := s + ' ' + aSCP[i]}
  end;
  Result := s
end;


function TdmData.UsesLotw(call : String) : Boolean;
var
  i : Integer;
  h : Integer;
begin
  Result := False;
  if call = '' then
    exit;
  call := dmUtils.GetIDCall(UpperCase(call));
  for i:=0 to High(CallArray) do
  begin
    if CallArray[i] = '' then
      Break;
    h := Ord(CallArray[i][1]);
    if h = Ord(Call[1]) then
    begin
      if CallArray[i] = call then
      begin
        if fDebugLevel>=1 then Writeln('Found - ' + CallArray[i]);
        Result := True;
        Break
      end
    end
    else begin
      if h > Ord(Call[1]) then
      begin
        if fDebugLevel>=1 then Writeln('NOT found - ' + CallArray[i]);
        Break
      end
    end
  end
end;

procedure TdmData.LoadeQSLCalls;
var
  i : Integer;
  f : TextFile;
  a : String;
begin
  SetLength(eQSLUsers,0);
  SetLength(eQSLUsers,1000000);
  if FileExists(fHomeDir+'eqsl.txt') then
  begin
    AssignFile(f,fHomeDir+'eqsl.txt');
    Reset(f);
    i := 0;
    while not Eof(f) do
    begin
      Readln(f,a);
      eQSLUsers[i] := UpperCase(Trim(a));
      inc(i)
    end;
    if fDebugLevel>=1 then Writeln('Loaded ',i,' eQSL users');
    SetLength(eQSLUsers,i+1);
    CloseFile(f);
    dmUtils.SortArray(0,i)
  end
end;


function TdmData.UseseQSL(call : String) : Boolean;
var
  l : Integer;
  r : Integer;
  i : Integer;
begin
  Result := False;
  l := 0;
  r := Length(eQSLUsers);
  repeat
    i := (l+r) div 2;
    if call < eQSLUsers[i] then
      r := i-1
    else
      l := i+1;
  until (call = eQSLUsers[i]) or (r<l);
  if call = eQSLUsers[i] then
    Result := True
end;
procedure TdmData.GetQSODistanceSum(var SumDist:int64; var LongestDist:integer;var MainLocCount:Integer);

var
   qrb,
   qrc,
   Myloc,
   loc :String;

  procedure HandleRecord;
   Begin
        Myloc := Q.Fields[0].AsString;
        if length(Myloc) = 4 then Myloc := Myloc +'LL';
        loc := Q.Fields[1].AsString;
        if length(loc) = 4 then loc := loc +'LL';
        dmUtils.DistanceFromLocator(dmUtils.CompleteLoc(Myloc),loc,qrb,qrc);
        if StrToIntDef(qrb,0) > LongestDist then  LongestDist := StrToIntDef(qrb,0);
        SumDist:= SumDist + StrToIntDef(qrb,0);
  end;

begin
  SumDist :=0;
  LongestDist :=0;
  MainLocCount := 0;

  Q.Close;
  if trQ.Active then
    trQ.RollBack;

  if IsFilter then
  begin
    Q.SQL.Text := StringReplace(dmData.qCQRLOG.SQL.Text,'*','my_loc,loc',[]);
    trQ.StartTransaction;
    try
      Q.Open;
      while not Q.Eof do
       begin
        HandleRecord;
        Q.Next;
       end
    finally
      Q.Close;
      trQ.RollBack
    end
  end
  else begin
    Q.SQL.Text := 'SELECT my_loc,loc FROM cqrlog_main';
    trQ.StartTransaction;
    try
      Q.Open;
      while not Q.Eof do
       begin
        HandleRecord;
        Q.Next;
       end
    finally
      Q.Close;
      trQ.RollBack
    end
  end;
  if pos('WHERE', Q.SQL.Text) > 0 then
       Q.SQL.Text := 'SELECT COUNT(DISTINCT(LEFT(loc,4))) FROM view_cqrlog_main_by_qsodate WHERE left(loc,4) <> "" AND '
      + copy(Q.SQL.Text, pos('WHERE', Q.SQL.Text)+5, length(Q.SQL.Text))
   else
    Q.SQL.Text := 'SELECT COUNT(DISTINCT(LEFT(loc,4))) FROM cqrlog_main WHERE left(loc,4) <> "" ';
   trQ.StartTransaction;
    try
      Q.Open;
      MainLocCount := Q.Fields[0].AsInteger
    finally
      Q.Close;
      trQ.RollBack
    end
end;
function TdmData.GetQSOCount : Integer;
begin
  Q.Close;
  if trQ.Active then
    trQ.RollBack;

  if IsFilter then
  begin
    Q.SQL.Text := dmData.qCQRLOG.SQL.Text;
    trQ.StartTransaction;
    try
      Q.Open;
      Q.Last;
      Result := dmData.Q.RecordCount
      //Q.First;
    finally
      Q.Close;
      trQ.RollBack
    end
  end
  else begin
    Q.SQL.Text := 'SELECT COUNT(*) FROM cqrlog_main';
    trQ.StartTransaction;
    try
      Q.Open;
      Result := Q.Fields[0].AsInteger
    finally
      Q.Close;
      trQ.RollBack
    end
  end
end;

procedure TdmData.TruncateTables(nr : Word);
var
  lQ  : TSQLQuery;
  lTr : TSQLTransaction;
begin
  Q.Close;
  lQ  := TSQLQuery.Create(nil);
  lTr := TSQLTransaction.Create(nil);
  try
    lQ.DataBase  := MainCon;
    lTr.DataBase := MainCon;
    lQ.Transaction := lTr;

    lQ.SQL.Text := 'use '+ GetProperDBName(nr);
    lQ.ExecSQL;
    lTr.Commit;

    lTr.StartTransaction;
    lQ.SQL.Text := 'TRUNCATE club1;';
    lQ.ExecSQL;
    lQ.SQL.Text := 'TRUNCATE club2;';
    lQ.ExecSQL;
    lQ.SQL.Text := 'TRUNCATE club3;';
    lQ.ExecSQL;
    lQ.SQL.Text := 'TRUNCATE club4;';
    lQ.ExecSQL;
    lQ.SQL.Text := 'TRUNCATE club5;';
    lQ.ExecSQL;
    lQ.SQL.Text := 'TRUNCATE cqrlog_config;';
    lQ.ExecSQL;
    lQ.SQL.Text := 'delete from cqrlog_main;';
    lQ.ExecSQL;
    lQ.SQL.Text := 'delete from upload_status';
    lQ.ExecSQL;
    lQ.SQL.Text := 'delete from log_changes';
    lQ.ExecSQL;
    lQ.SQL.Text := 'TRUNCATE dxcc_id;';
    lQ.ExecSQL;
    lQ.SQL.Text := 'TRUNCATE long_note;';
    lQ.ExecSQL;
    lQ.SQL.Text := 'TRUNCATE notes;';
    lQ.ExecSQL;
    lQ.SQL.Text := 'TRUNCATE profiles;';
    lQ.ExecSQL;
    lQ.SQL.Text := 'TRUNCATE version;';
    lQ.ExecSQL;
    lQ.SQL.Text := 'TRUNCATE zipcode1;';
    lQ.ExecSQL;
    lQ.SQL.Text := 'TRUNCATE zipcode2;';
    lQ.ExecSQL;
    lQ.SQL.Text := 'TRUNCATE zipcode3;';
    lQ.ExecSQL;
    lTr.Commit
  finally
    lQ.Close;
    FreeAndNil(lQ);
    FreeAndNil(lTr)
  end
end;

procedure TdmData.PrepareProfileExport;
var
  tmp : String;
begin
  SetLength(aProf,0);
  qProfiles.Close;
  qProfiles.SQL.Text := 'select * from profiles order by nr';
  if fDebugLevel >=1 then Writeln(qProfiles.SQL.Text);
  if trProfiles.Active then  trProfiles.Rollback;
  trProfiles.StartTransaction;
  try
    qProfiles.Open;
    if qProfiles.RecordCount = 0 then exit;
    qProfiles.Last;
    SetLength(aProf,qProfiles.Fields[1].AsInteger+1);
    qProfiles.First;
    while not qProfiles.Eof do
    begin
      aProf[qProfiles.Fields[1].AsInteger].ProfNr := qProfiles.Fields[1].AsInteger;
      tmp := IntToStr(qProfiles.Fields[1].AsInteger)+'|';
      tmp := tmp + trim(qProfiles.Fields[2].AsString)+'|';
      tmp := tmp + trim(qProfiles.Fields[3].AsString)+'|';
      tmp := tmp + trim(qProfiles.Fields[4].AsString)+'|';
      aProf[qProfiles.Fields[1].AsInteger].text := tmp;
      qProfiles.Next
    end
  finally
     qProfiles.Close;
     trProfiles.Rollback
  end
end;

function TdmData.GetExportProfileText(nr : Integer) : String;
begin
  if nr > Length(aProf) then
    Result := ''
  else
    Result := aProf[nr].text
end;

procedure TdmData.CloseProfileExport;
begin
  SetLength(aProf,0)
end;


procedure TdmData.UpgradeCommonDatabase(old_version : Integer);
var
  err : Boolean = False;
begin
  if old_version < cDB_COMN_VER then
  begin
    if trQ1.Active then trQ1.Rollback;
    trQ1.StartTransaction;
    try try
      if old_version < 3 then
      begin
        Q1.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                       QuotedStr('2190M')+',0.472,0.480,0.472,0.472,0.480)';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL
      end;

      if (old_version < 4) then
      begin
        Q1.SQL.Text := 'alter table cqrlog_common.bands add rx_offset numeric(10,4) default 0';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;

        Q1.SQL.Text := 'alter table cqrlog_common.bands add tx_offset numeric(10,4) default 0';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL
      end;

      if old_version < 5 then
      begin
        Q1.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                       QuotedStr('2.5MM')+',122250.0,123000.0,122251.0,122251.0,122251.0)';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        Q1.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                       QuotedStr('2MM')+',134000.0,141000.0,134930.0,134930.0,134930.0)';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        Q1.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                        QuotedStr('1MM')+',241000.0,250000.0,248000.0,248000.0,248000.0)';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
      end;

      if old_version < 6 then
      begin
        Q1.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                       QuotedStr('8M')+',40.0000,45.0000,40.3000,40.3000,40.6800)';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        Q1.SQL.Text := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
                       QuotedStr('5M')+',54.0000,69.9000,59.5000,59.6000,59.6000)';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
      end;

      Q1.SQL.Text := 'update cqrlog_common.db_version set nr='+IntToStr(cDB_COMN_VER);
      if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
      Q1.ExecSQL
    except
      on E : Exception do
      begin
        Application.MessageBox(PChar('Database upgrade crashed with this error:'+LineEnding+E.Message),'Error',mb_ok+mb_IconError);
      end
    end
    finally
      if err then
        trQ1.Rollback
      else
        trQ1.Commit
    end
  end
end;

procedure TdmData.UpgradeMainDatabase(old_version : Integer);
var
  err : Boolean = False;
  max : Integer;
begin
  if fDebugLevel>=1 then Writeln('[UpgradeMainDatabase] Old version: ', old_version,  '  cDB_MAIN_VER: ', cDB_MAIN_VER);

  if old_version < cDB_MAIN_VER then
  begin
    if trQ1.Active then trQ1.Rollback;
    try try
      if old_version < 2 then
      begin
        trQ1.StartTransaction;
        Q1.SQL.Text := 'alter table cqrlog_main add eqsl_qsl_sent varchar(1) null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        Q1.SQL.Text := 'alter table cqrlog_main add eqsl_qslsdate date null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        Q1.SQL.Text := 'alter table cqrlog_main add eqsl_qsl_rcvd varchar(1) null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        Q1.SQL.Text := 'alter table cqrlog_main add eqsl_qslrdate date null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit
      end;

      if old_version < 4 then
      begin
        trQ1.StartTransaction;
        Q1.SQL.Text := 'update cqrlog_main set eqsl_qsl_sent = '+QuotedStr('')+' where eqsl_qsl_sent is null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        Q1.SQL.Text := 'update cqrlog_main set eqsl_qsl_rcvd = '+QuotedStr('')+' where eqsl_qsl_rcvd is null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;

        Q1.SQL.Text := 'update cqrlog_main set qsl_s = '+QuotedStr('')+' where qsl_s is null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        Q1.SQL.Text := 'update cqrlog_main set qsl_r = '+QuotedStr('')+' where qsl_r is null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;

        Q1.SQL.Text := 'update cqrlog_main set lotw_qsls = '+QuotedStr('')+' where lotw_qsls is null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        Q1.SQL.Text := 'update cqrlog_main set lotw_qslr = '+QuotedStr('')+' where lotw_qslr is null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;

        Q1.SQL.Text := 'alter table cqrlog_main change qsl_s qsl_s varchar(3) default '+QuotedStr('')+ 'not null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        Q1.SQL.Text := 'alter table cqrlog_main change qsl_r qsl_r varchar(3) default '+QuotedStr('')+ 'not null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;

        Q1.SQL.Text := 'alter table cqrlog_main change lotw_qsls lotw_qsls varchar(1) default '+QuotedStr('')+ 'not null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        Q1.SQL.Text := 'alter table cqrlog_main change lotw_qslr lotw_qslr varchar(1) default '+QuotedStr('')+ 'not null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;

        Q1.SQL.Text := 'alter table cqrlog_main change eqsl_qsl_sent eqsl_qsl_sent varchar(1) default '+QuotedStr('')+ 'not null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        Q1.SQL.Text := 'alter table cqrlog_main change eqsl_qsl_rcvd eqsl_qsl_rcvd varchar(1) default '+QuotedStr('')+ 'not null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL ;
        trQ1.Commit
      end;

      if old_version < 5 then
      begin
        trQ1.StartTransaction;
        Q1.SQL.Text := 'alter table cqrlog_main change qsl_s qsl_s varchar(4) default '+QuotedStr('')+ ' not null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit
      end;

      if old_version < 6 then
      begin
        trQ1.StartTransaction;
        Q1.SQL.Text := 'alter table cqrlog_main change mode mode varchar(10) not null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit
      end;

      if old_version < 7 then
      begin
        if not TableExists('log_changes') then
        begin
          trQ1.StartTransaction;
          Q1.SQL.Clear;
          Q1.SQL.Add('CREATE TABLE log_changes (');
          Q1.SQL.Add('  id int NOT NULL AUTO_INCREMENT PRIMARY KEY,');
          Q1.SQL.Add('  id_cqrlog_main int NULL,');
          Q1.SQL.Add('  cmd varchar(10) NOT NULL,');
          Q1.SQL.Add('  qsodate date NULL,');
          Q1.SQL.Add('  time_on varchar(5) NULL,');
          Q1.SQL.Add('  callsign varchar(20) NULL,');
          Q1.SQL.Add('  mode varchar(10) NULL,');
          Q1.SQL.Add('  freq numeric(10,4) NULL,');
          Q1.SQL.Add('  band varchar(6) NULL,');
          Q1.SQL.Add('  old_qsodate date NULL,');
          Q1.SQL.Add('  old_time_on varchar(5) NULL,');
          Q1.SQL.Add('  old_callsign varchar(20) NULL,');
          Q1.SQL.Add('  old_mode varchar(10) NULL,');
          Q1.SQL.Add('  old_freq numeric(10,4) NULL,');
          Q1.SQL.Add('  old_band varchar(6) NULL');
          Q1.SQL.Add(') COLLATE '+QuotedStr('utf8_bin')+';');
          if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
          Q1.ExecSQL;
          trQ1.Commit;

          trQ1.StartTransaction;
          Q1.SQL.Clear;
          Q1.SQL.Add('ALTER TABLE log_changes');
          Q1.SQL.Add('ADD INDEX id_cqrlog_main (id_cqrlog_main);');
          if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
          Q1.ExecSQL;
          trQ1.Commit;

          { version older than 1.8.0 may have all tables in MyISAM engine
            new version has as default InnoDB. Creating Foreign key between
            tables in two different engines fail with error no 150.

            This happen only when user updates from old version where cqrlog_main was created in
            MyISAM engine. I hope this won't happen so often, cqrlog can live without
            this foreign key

          trQ1.StartTransaction;
          Q1.SQL.Clear;
          Q1.SQL.Add('ALTER TABLE log_changes');
          Q1.SQL.Add('ADD FOREIGN KEY (id_cqrlog_main) REFERENCES cqrlog_main (id_cqrlog_main) ON DELETE SET NULL ON UPDATE CASCADE;');
          if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
          Q1.ExecSQL;
          trQ1.Commit
          }
        end;

        if not TableExists('upload_status') then
        begin
          trQ1.StartTransaction;
          Q1.SQL.Clear;
          Q1.SQL.Add('CREATE TABLE upload_status (');
          Q1.SQL.Add('  id int NOT NULL AUTO_INCREMENT PRIMARY KEY,');
          Q1.SQL.Add('  logname varchar(30) NOT NULL,');
          Q1.SQL.Add('  id_log_changes int(11) NULL,');
          Q1.SQL.Add('  FOREIGN KEY (id_log_changes) REFERENCES log_changes (id) ON DELETE SET NULL');
          Q1.SQL.Add(') COLLATE '+QuotedStr('utf8_bin')+';');
          if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
          Q1.ExecSQL;
          trQ1.Commit
        end
      end;

      if old_version < 8 then
      begin
        PrepareEmptyLogUploadStatusTables(Q1,trQ1);
        {
        trQ1.StartTransaction;
        Q1.SQL.Text := 'insert into log_changes (id,cmd) values(1,'+QuotedStr(C_ALLDONE)+')';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;

        Q1.SQL.Text := 'insert into upload_status (logname, id_log_changes) values ('+QuotedStr(C_HAMQTH)+',1)';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;

        Q1.SQL.Text := 'insert into upload_status (logname, id_log_changes) values ('+QuotedStr(C_CLUBLOG)+',1)';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;

        Q1.SQL.Text := 'insert into upload_status (logname, id_log_changes) values ('+QuotedStr(C_HRDLOG)+',1)';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit}
      end;

      if old_version < 9 then
      begin
        trQ1.StartTransaction;
        Q1.SQL.Text := 'alter table log_changes add upddeleted int(1) default 0';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit
      end;

      if old_version < 10 then
      begin
        trQ1.StartTransaction;
        Q1.SQL.Clear;
        Q1.SQL.Add('CREATE TABLE call_alert (');
        Q1.SQL.Add('  id int NOT NULL AUTO_INCREMENT PRIMARY KEY,');
        Q1.SQL.Add('  callsign varchar(20) NOT NULL,');
        Q1.SQL.Add('  band varchar(6) NULL,');
        Q1.SQL.Add('  mode varchar(10) NULL');
        Q1.SQL.Add(') COLLATE '+QuotedStr('utf8_bin')+';');
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit;

        trQ1.StartTransaction;
        Q1.SQL.Text := 'ALTER TABLE call_alert ADD INDEX (id);';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;

        Q1.SQL.Text := 'ALTER TABLE call_alert ADD INDEX (callsign);';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit
      end;

      if old_version < 11 then
      begin
        trQ1.StartTransaction;
        Q1.SQL.Clear;
        Q1.SQL.Add('CREATE TABLE freqmem (');
        Q1.SQL.Add('  id int NOT NULL AUTO_INCREMENT PRIMARY KEY,');
        Q1.SQL.Add('  freq numeric(10,4) NOT NULL,');
        Q1.SQL.Add('  mode varchar(10) NOT NULL,');
        Q1.SQL.Add('  bandwidth int NOT NULL,');
        Q1.SQL.Add('  info varchar(25) NULL');      //null makes log backward compatible with old cqrlogs
        Q1.SQL.Add(') COLLATE '+QuotedStr('utf8_bin')+';');
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit
      end;

      if old_version < 12 then
      begin
        trQ1.StartTransaction;
        Q1.SQL.Text := 'alter table cqrlog_main change loc loc varchar(10) default ' + QuotedStr('');
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        Q1.SQL.Text := 'alter table cqrlog_main change my_loc my_loc varchar(10) default ' + QuotedStr('');
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit
      end;

      if old_version < 14 then
      begin
        trQ1.StartTransaction;
        Q1.SQL.Text := 'alter table cqrlog_main change mode mode varchar(12) not null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit;

        trQ1.StartTransaction;
        Q1.SQL.Text := 'alter table log_changes change mode mode varchar(12) null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit;

        trQ1.StartTransaction;
        Q1.SQL.Text := 'alter table log_changes change old_mode old_mode varchar(12) null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit;

        trQ1.StartTransaction;
        Q1.SQL.Text := 'alter table call_alert change mode mode varchar(12) null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit;

        trQ1.StartTransaction;
        Q1.SQL.Text := 'alter table freqmem change mode mode varchar(12) null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;

        trQ1.Commit
      end;

      if (old_version < 15) then
      begin
        trQ1.StartTransaction;
        Q1.SQL.Text := 'alter table cqrlog_main add rxfreq numeric(10,4) null';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit;

        trQ1.StartTransaction;
        Q1.SQL.Text := 'alter table cqrlog_main add satellite varchar(30) default '+QuotedStr('');
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit;

        trQ1.StartTransaction;
        Q1.SQL.Text := 'alter table cqrlog_main add prop_mode varchar(30) default '+QuotedStr('');
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit
      end;

      if (old_version < 16) then
      begin
        if (not FieldExists('cqrlog_main', 'stx')) then
        begin
          trQ1.StartTransaction;
          Q1.SQL.Text := 'alter table cqrlog_main add stx varchar(6) null';
          if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
          Q1.ExecSQL;
          trQ1.Commit;
        end;

        if (not FieldExists('cqrlog_main', 'srx')) then
        begin
          trQ1.StartTransaction;
          Q1.SQL.Text := 'alter table cqrlog_main add srx varchar(6) null';
          if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
          Q1.ExecSQL;
          trQ1.Commit;
        end;


        if (not FieldExists('cqrlog_main', 'stx_string')) then
        begin
          trQ1.StartTransaction;
          Q1.SQL.Text := 'alter table cqrlog_main add stx_string varchar(50) null';
          if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
          Q1.ExecSQL;
          trQ1.Commit;
        end;

        if (not FieldExists('cqrlog_main', 'srx_string')) then
        begin
          trQ1.StartTransaction;
          Q1.SQL.Text := 'alter table cqrlog_main add srx_string varchar(50) null';
          if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
          Q1.ExecSQL;
          trQ1.Commit;
        end;

        if (not FieldExists('cqrlog_main', 'contestname')) then
        begin
          trQ1.StartTransaction;
          Q1.SQL.Text := 'alter table cqrlog_main add contestname varchar(40) null';
          if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
          Q1.ExecSQL;
          trQ1.Commit;
        end;

        trQ1.StartTransaction;
        Q1.SQL.Text := 'alter table log_changes modify cmd varchar(20)';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit;

        if (not FieldExists('freqmem', 'info')) then
        begin
          trQ1.StartTransaction;
          Q1.SQL.Text := 'alter table freqmem add info varchar(25) null';
          Q1.ExecSQL;
          trQ1.Commit
        end;
      end;

      if (old_version < 17) then
            begin
              if (not FieldExists('cqrlog_main', 'dok')) then
              begin
                trQ1.StartTransaction;
                Q1.SQL.Text := 'alter table cqrlog_main add dok varchar(12) null';
                if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
                Q1.ExecSQL;
                trQ1.Commit;
              end;
      end;

      if (old_version < 18) then
            begin
              if (not FieldExists('cqrlog_main', 'operator')) then
              begin
                trQ1.StartTransaction;
                Q1.SQL.Text := 'alter table cqrlog_main add operator varchar(20) null';
                if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
                Q1.ExecSQL;
                trQ1.Commit;
              end;
      end;

      if (old_version < 19) then
            begin
              if (ConstraintExists('log_changes', 'log_changes_ibfk_1')) then
              begin
                trQ1.StartTransaction;
                Q1.SQL.Text := 'ALTER TABLE log_changes DROP FOREIGN KEY log_changes_ibfk_1';
                if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
                Q1.ExecSQL;
                trQ1.Commit;
              end;

              // PrepareEmptyLogUploadStatusTables() would have been called
              // for older versions
              if (old_version >= 8) then
              begin
                trQ1.StartTransaction;
                Q1.SQL.Text := 'select max(id) from log_changes';
                Q1.Open;
                max := Q1.Fields[0].AsInteger;
                Q1.Close;
                Q1.SQL.Text := 'insert into upload_status (logname, id_log_changes) values ('+QuotedStr(C_UDPLOG)+','+IntToStr(max)+')';
                if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
                Q1.ExecSQL;
                trQ1.Commit;
              end;
      end;

      if TableExists('view_cqrlog_main_by_callsign') then
      begin
        trQ1.StartTransaction;
        Q1.SQL.Text := 'drop view view_cqrlog_main_by_callsign';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit
      end;

      if TableExists('view_cqrlog_main_by_qsodate') then
      begin
        trQ1.StartTransaction;
        Q1.SQL.Text := 'drop view view_cqrlog_main_by_qsodate';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit
      end;

      if TableExists('view_cqrlog_main_by_qsodate_asc') then
      begin
        trQ1.StartTransaction;
        Q1.SQL.Text := 'drop view view_cqrlog_main_by_qsodate_asc';
        if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
        Q1.ExecSQL;
        trQ1.Commit
      end;

      CreateViews;

      trQ1.StartTransaction;
      Q1.SQL.Text := 'update db_version set nr='+IntToStr(cDB_MAIN_VER);
      if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
      Q1.ExecSQL;
      trQ1.Commit
    except
      on E : Exception do
      begin
        Application.MessageBox(PChar('Database upgrade crashed with this error:'+LineEnding+E.Message),'Error',mb_ok+mb_IconError);
      end
    end
    finally
      if trQ1.Active then
        trQ1.Rollback
    end
  end
end;

procedure TdmData.RepairTables(nr : Word);
var
  db : String;
begin
  db := GetProperDBName(nr);
  Q.Close;
  try
    if trQ.Active then trQ.RollBack;
    trQ.StartTransaction;
    Q.SQL.Text := 'select table_name from information_schema.tables where  table_schema='+QuotedStr(db)+' and table_type ='+ QuotedStr('BASE TABLE');
    Q.Open;
    while not Q.Eof do
    begin
      Q1.Close;
      if trQ1.Active then trQ1.Rollback;

      trQ1.StartTransaction;
      Q1.SQL.Text := 'REPAIR TABLE '+db+'.'+Q.Fields[0].AsString;
      if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
      Q1.ExecSQL;
      trQ1.Commit;

      Q.Next
    end
  finally
    dmData.Q1.Close;
    if trQ1.Active then trQ1.Rollback;
    dmData.Q.Close;
    if trQ.Active then trQ.RollBack
  end
end;

procedure TdmData.CreateQSLTmpTable;
var
  i : Integer;
begin
  Q.Close;
  if trQ.Active then
    trQ.Rollback;
  trQ.StartTransaction;
  try try
     Q.SQL.Text := '';
    for i:=0 to scQSLExport.Script.Count-1 do
    begin
      if Pos(';',scQSLExport.Script.Strings[i]) = 0 then
        Q.SQL.Add(scQSLExport.Script.Strings[i])
      else begin
        Q.SQL.Add(scQSLExport.Script.Strings[i]);
        if fDebugLevel>=1 then Writeln(Q.SQL.Text);
        Q.ExecSQL;
        Q.SQL.Text := ''
      end
    end
  except
    trQ.Rollback
  end
  finally
    if trQ.Active then trQ.Commit
  end
//^^ because of bug in  TSQLSript. For the firt time cretreates the database,
//second database - no effect. My workaround works. Semicolon is a delimitter.
end;

procedure TdmData.DropQSLTmpTable;
const
  C_SQL = 'DROP TABLE qslexport';
begin
  trQ.StartTransaction;
  Q.SQL.Text := C_SQL;
  Q.ExecSQL;
  trQ.Commit
end;

function TdmData.GetMysqldPath : String;
var
  l : TStringList;
  info : String;
begin
  Writeln(ExtractFilePath(Paramstr(0))  + 'mysqld');
  if FileExistsUTF8(ExtractFilePath(Paramstr(0))  + 'mysqld') then
    Result := ExtractFilePath(Paramstr(0))  + 'mysqld';
  if FileExistsUTF8('/usr/bin/mysqld') then
    Result := '/usr/bin/mysqld';
  if FileExistsUTF8('/usr/bin/mysqld_safe') then //Fedora
    Result := '/usr/bin/mysqld_safe';
  if FileExistsUTF8('/usr/sbin/mysqld') then //openSUSE
    Result := '/usr/sbin/mysqld';
  if Result = '' then  //don't know where mysqld is, so hopefully will be in  $PATH
    Result := 'mysqld'
end;

procedure TdmData.PrepareMysqlConfigFile;
var
  f : TextFile;
  l : TStringList;
  i : Integer;
begin
  if not FileExistsUTF8(fHomeDir+'database'+DirectorySeparator+'mysql.cnf') then
  begin
    AssignFile(f,fHomeDir+'database'+DirectorySeparator+'mysql.cnf');
    Rewrite(f);
    Writeln(f,scMySQLConfig.Script.Text);
    CloseFile(f)
  end
  else begin
    //innodb_additional_mem_pool_size is deprecated in MySQL >= 5.6.3
    //and MySQL in Ubuntu 16.04 doesn't start with this parameter
    //in mysql.cnf
    //it seems I can remove it in all versions of MySQL used by CQRLOG

    l := TStringList.Create;
    try try
      l.LoadFromFile(fHomeDir+'database'+DirectorySeparator+'mysql.cnf');
      i := l.IndexOf('innodb_additional_mem_pool_size=1M');
      if i > -1 then
      begin
        l.Strings[i] := '#innodb_additional_mem_pool_size=1M';
        l.SaveToFile(fHomeDir+'database'+DirectorySeparator+'mysql.cnf')
      end
    except
      on E : Exception do
        Writeln(E.Message)
    end
    finally
      FreeAndNil(l);
    end
  end
end;

procedure TdmData.StartMysqldProcess;
var
  mysqld    : String;
  Connected : Boolean = False;
  Tryies    : Word = 0;
  index     :integer;
  paramList :TStringList;

begin
  mysqld := GetMysqldPath;
  PrepareMysqlConfigFile;
  MySQLProcess := TProcess.Create(nil);
  MySQLProcess.Executable := mysqld;
  index:=0;
  paramList := TStringList.Create;
  paramList.Delimiter := ' ';
  paramList.DelimitedText := (' --defaults-file='+fHomeDir+'database/'+'mysql.cnf'+
                              ' --datadir='+fHomeDir+'database/'+
                              ' --socket='+fHomeDir+'database/sock'+
                              ' --port=64000');
  MySQLProcess.Parameters.Clear;
  while index < paramList.Count do
  begin
    MySQLProcess.Parameters.Add(paramList[index]);
    inc(index);
  end;
  paramList.Free;

  if dmData.DebugLevel>=1 then Writeln('MySQLProcess.Executable: ',MySQLProcess.Executable,' Parameters: ',MySQLProcess.Parameters.Text);
  MySQLProcess.Execute;

  if MainCon.Connected then
    MainCon.Connected := False;

  MainCon.HostName     := '127.0.0.1';
  MainCon.Params.Text  := 'Port=64000';
  MainCon.DatabaseName := 'information_schema';
  MainCon.UserName     := 'cqrlog';
  MainCon.Password     := 'cqrlog';

  while true do
  begin
    try try
      Connected := True;
      inc(Tryies);
      MainCon.Connected := True
    except
      on E : Exception do
      begin
        if fDebugLevel>=1 then Writeln('Trying to connect to database');
        Sleep(1000);
        Connected := False;
        if fDebugLevel>=1 then Writeln(E.Message);
        if fDebugLevel>=1 then Writeln('Trying:',Tryies);
	if (Tryies > 7) then
	  Break
	else
          Continue
      end
    end
    finally
      MainCon.Connected := False
    end;
    if Connected or (Tryies>5) then break
  end;
  MainCon.DatabaseName := '';
  if not Connected then
  begin
    with TfrmDbError.Create(nil) do
    try
      ShowModal
    finally
      Free
    end
  end
end;

function TdmData.BandModFromFreq(freq : String;var mode,band : String) : Boolean;
var
  tmp : Extended;
  cw, ssb : Extended;
begin
  Result := False;
  if (freq = '') then
    exit;
  if not TryStrToFloat(freq,tmp) then
    exit;
  tmp := tmp/1000;
  freq := FloatToStr(tmp);

  qBands.Close;
  qBands.SQL.Text := 'SELECT * FROM cqrlog_common.bands where (b_begin <='+freq+' AND b_end >='+
                      freq+') ORDER BY b_begin';
  if dmData.DebugLevel >= 1 then
    Writeln(qBands.SQL.Text);
  if trBands.Active then
    trBands.RollBack;
  trBands.StartTransaction;
  qBands.Open;
  qBands.Last;   //to get proper record count
  if dmData.DebugLevel>=1 then Writeln('qBands.RecorfdCount: ',qBands.RecordCount);
  if qBands.RecordCount = 0 then
    exit;
  qBands.First;
  band := qBands.Fields[1].AsString;
  cw   := qBands.Fields[4].AsFloat;
  ssb  := qBands.Fields[6].AsFloat;

  Result := True;
  if (tmp <= cw) then
    mode := 'CW'
  else begin
    if (tmp >= ssb) then
      mode := 'SSB'
    else
      mode := 'RTTY';
  end;
  if dmData.DebugLevel>=1 then Writeln('TdmData.BandModFromFreq:',Result,' cw ',FloatToStr(cw),' ssb ',FloatToStr(ssb))
end;

function TdmData.TriggersExistsOnCqrlog_main : Boolean;
const
  C_SEL = 'show triggers from %s';
begin
  Q.Close;
  if trQ.Active then trQ.Rollback;
  try
    Q.SQL.Text := Format(C_SEL,[fDBName]);
    Q.Open;
    Result := Q.RecordCount > 0
  finally
    Q.Close;
    trQ.RollBack
  end
end;

procedure TdmData.DeleteCallAlert(const id : Integer);
const
  C_DEL = 'delete from call_alert where id = %d';
begin
  Q1.Close;
  if trQ1.Active then trQ1.Rollback;
  try
    trQ1.StartTransaction;
    Q1.SQL.Text := Format(C_DEL,[id]);
    if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
    Q1.ExecSQL
  finally
    trQ1.Commit;
    Q1.Close
  end
end;

procedure TdmData.AddCallAlert(const callsign, band, mode : String);
const
  C_INS = 'insert into call_alert(callsign,mode,band) values (:callsign,:mode,:band)';
begin
  Q1.Close;
  if trQ1.Active then trQ1.Rollback;
  try
    trQ1.StartTransaction;
    Q1.SQL.Text := C_INS;
    if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
    Q1.Prepare;
    Q1.Params[0].AsString := callsign;
    Q1.Params[1].AsString := mode;
    Q1.Params[2].AsString := band;
    Q1.ExecSQL
  finally
    trQ1.Commit;
    Q1.Close
  end
end;

procedure TdmData.EditCallAlert(const id : Integer; const callsign, band, mode : String);
const
  C_UPD = 'update call_alert set callsign=:callsing,band =:band,mode =:mode where id=:id';
var
  i : Integer;
begin
  Q1.Close;
  if trQ1.Active then trQ1.Rollback;
  try
    trQ1.StartTransaction;
    Q1.SQL.Text := C_UPD;
    if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
    Q1.Prepare;
    Q1.Params[0].AsString  := callsign;
    Q1.Params[1].AsString  := band;
    Q1.Params[2].AsString  := mode;
    Q1.Params[3].AsInteger := id;
    if fDebugLevel>-1 then
    begin
      for i:=0 to Q1.Params.Count-1 do
        Writeln(Q1.Params[i].Name,':',Q1.Params[i].Value)
    end;
    Q1.ExecSQL
  finally
    trQ1.Commit;
    Q1.Close
  end
end;

function TdmData.GetLastAllertCallId(const callsign,band,mode : String) : Integer;
const
  C_SEL = 'select max(id) from call_alert where (callsign=%s) and (band=%s) and (mode=%s)';
begin
  Q1.Close;
  if trQ1.Active then trQ1.Rollback;
  try
    trQ1.StartTransaction;
    Q1.SQL.Text := Format(C_SEL,[QuotedStr(callsign),QuotedStr(band),QuotedStr(mode)]);
    if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
    Q1.Open;
    Result := Q1.Fields[0].AsInteger
  finally
    trQ1.Rollback;
    Q1.Close
  end
end;

procedure TdmData.DeleteOldConfigFiles;
var
  res: byte;
  SearchRec: TSearchRec;
begin
  res := FindFirst(fHomeDir + '*cqrlog.cfg', faAnyFile, SearchRec);
  while Res = 0 do
  begin
    if FileExists(fHomeDir + SearchRec.Name) then
      DeleteFile(fHomeDir + SearchRec.Name);
    if fDebugLevel>=1 then
      Writeln('Deleting config file: ',SearchRec.Name);
    Res := FindNext(SearchRec)
  end;
  FindClose(SearchRec)
end;

procedure TdmData.MarkAllAsUploadedToeQSL;
const
  C_UPD = 'update cqrlog_main set eqsl_qsl_sent = %s,eqsl_qslsdate=%s where (eqsl_qsl_sent="" and eqsl_qslsdate is NULL)';
begin
  Q1.Close;
  if trQ1.Active then
    trQ1.Active := False;
  try try
    Q1.SQL.Text := Format(C_UPD,[QuotedStr('Y'),QuotedStr(dmUtils.DateToSQLIteDate(now))]);
    Q1.ExecSQL
  except
    trQ1.Rollback
  end
  finally
    if trQ1.Active then
      trQ1.Commit;
    Q.Close
  end
end;
procedure TdmData.MarkAllAsUploadedToLoTW;
const
  C_UPD = 'update cqrlog_main set lotw_qsls = %s, lotw_qslsdate = %s where (lotw_qsls="" and lotw_qslsdate is NULL)';
begin
  Q1.Close;
  if trQ1.Active then
    trQ1.Active := False;
  try try
    Q1.SQL.Text := Format(C_UPD,[QuotedStr('Y'),QuotedStr(dmUtils.DateToSQLIteDate(now))]);
    Q1.ExecSQL
  except
    trQ1.Rollback
  end
  finally
    if trQ1.Active then
      trQ1.Commit;
    Q.Close
  end
end;

function TdmData.TableExists(TableName : String) : Boolean;
const
  C_SEL = 'select table_name from information_schema.tables where table_schema=%s and table_name=%s';
var
  t  : TSQLQuery;
  tr : TSQLTransaction;
begin
  Result := True;
  t := TSQLQuery.Create(nil);
  tr := TSQLTransaction.Create(nil);
  try
    t.Transaction := tr;
    tr.DataBase   := MainCon;
    t.DataBase    := MainCon;

    t.SQL.Text := Format(C_SEL,[QuotedStr(fDBName),QuotedStr(TableName)]);
    if fDebugLevel>=1 then Writeln(t.SQL.Text);
    t.Open;
    Result := t.RecordCount>0
  finally
    t.Close;
    tr.Rollback;
    FreeAndNil(t);
    FreeAndNil(tr)
  end
end;

function TdmData.FieldExists(TableName, FieldName : String) : Boolean;
const
  C_SEL = 'select column_name from information_schema.columns where table_schema=%s and table_name=%s and column_name=%s';
var
  t  : TSQLQuery;
  tr : TSQLTransaction;
begin
  Result := True;
  t := TSQLQuery.Create(nil);
  tr := TSQLTransaction.Create(nil);
  try
    t.Transaction := tr;
    tr.DataBase   := MainCon;
    t.DataBase    := MainCon;

    t.SQL.Text := Format(C_SEL,[QuotedStr(fDBName),QuotedStr(TableName), QuotedStr(FieldName)]);
    if fDebugLevel>=1 then Writeln(t.SQL.Text);
    t.Open;
    Result := t.RecordCount>0
  finally
    t.Close;
    tr.Rollback;
    FreeAndNil(t);
    FreeAndNil(tr)
  end
end;

function TdmData.ConstraintExists(TableName, ConstraintName : String) : Boolean;
const
  C_SEL = 'select constraint_name from information_schema.table_constraints where table_schema=%s and table_name=%s and constraint_name=%s';
var
  t  : TSQLQuery;
  tr : TSQLTransaction;
begin
  Result := True;
  t := TSQLQuery.Create(nil);
  tr := TSQLTransaction.Create(nil);
  try
    t.Transaction := tr;
    tr.DataBase   := MainCon;
    t.DataBase    := MainCon;

    t.SQL.Text := Format(C_SEL,[QuotedStr(fDBName),QuotedStr(TableName), QuotedStr(ConstraintName)]);
    if fDebugLevel>=1 then Writeln(t.SQL.Text);
    t.Open;
    Result := t.RecordCount>0
  finally
    t.Close;
    tr.Rollback;
    FreeAndNil(t);
    FreeAndNil(tr)
  end
end;


procedure TdmData.PrepareEmptyLogUploadStatusTables(lQ : TSQLQuery;lTr : TSQLTransaction);
var
  Commit : Boolean = False;
begin
  Commit := not lTr.Active;

  if Commit then
    lTr.StartTransaction;

  lQ.SQL.Text := 'insert into log_changes (id,cmd) values(1,'+QuotedStr(C_ALLDONE)+')';
  if fDebugLevel>=1 then Writeln(lQ.SQL.Text);
  lQ.ExecSQL;

  lQ.SQL.Text := 'insert into upload_status (logname, id_log_changes) values ('+QuotedStr(C_HAMQTH)+',1)';
  if fDebugLevel>=1 then Writeln(lQ.SQL.Text);
  lQ.ExecSQL;

  lQ.SQL.Text := 'insert into upload_status (logname, id_log_changes) values ('+QuotedStr(C_CLUBLOG)+',1)';
  if fDebugLevel>=1 then Writeln(lQ.SQL.Text);
  lQ.ExecSQL;

  lQ.SQL.Text := 'insert into upload_status (logname, id_log_changes) values ('+QuotedStr(C_HRDLOG)+',1)';
  if fDebugLevel>=1 then Writeln(lQ.SQL.Text);
  lQ.ExecSQL;

  lQ.SQL.Text := 'insert into upload_status (logname, id_log_changes) values ('+QuotedStr(C_UDPLOG)+',1)';
  if fDebugLevel>=1 then Writeln(lQ.SQL.Text);
  lQ.ExecSQL;

  if Commit then
    lTr.Commit
end;


{
eqsl_qsl_sent varchar(1) default '' not null,
eqsl_qslsdate date default null,
}
procedure TdmData.RemoveeQSLUploadedFlag(id : Integer);
const
  C_UPD = 'update cqrlog_main set eqsl_qsl_sent=%s,eqsl_qslsdate=NULL where id_cqrlog_main=%d';
var
  t  : TSQLQuery;
  tr : TSQLTransaction;
begin
  t := TSQLQuery.Create(nil);
  tr := TSQLTransaction.Create(nil);
  try try
    dmLogUpload.DisableOnlineLogSupport;

    t.Transaction := tr;
    tr.DataBase   := MainCon;
    t.DataBase    := MainCon;

    tr.StartTransaction;
    t.SQL.Text := Format(C_UPD,[QuotedStr(''),id]);
    if fDebugLevel>=1 then Writeln(t.SQL.Text);
    t.ExecSQL
  except
    on E : Exception do
    begin
      Writeln(E.Message);
      tr.Rollback
    end
  end;
  finally
    t.Close;
    if tr.Active then
      tr.Commit;

    if dmLogUpload.LogUploadEnabled then
      dmLogUpload.EnableOnlineLogSupport(False);

    FreeAndNil(t);
    FreeAndNil(tr)
  end
end;

{
lotw_qslsdate DATE default null,
lotw_qsls VARCHAR(3) DEFAULT '' not null,
}
procedure TdmData.RemoveLoTWUploadedFlag(id : Integer);
const
  C_UPD = 'update cqrlog_main set lotw_qsls=%s,lotw_qslsdate=NULL where id_cqrlog_main=%d';
var
  t  : TSQLQuery;
  tr : TSQLTransaction;
begin
  t := TSQLQuery.Create(nil);
  tr := TSQLTransaction.Create(nil);
  try try
    dmLogUpload.DisableOnlineLogSupport;

    t.Transaction := tr;
    tr.DataBase   := MainCon;
    t.DataBase    := MainCon;

    tr.StartTransaction;
    t.SQL.Text := Format(C_UPD,[QuotedStr(''),id]);
    if fDebugLevel>=1 then Writeln(t.SQL.Text);
    t.ExecSQL
  except
    on E : Exception do
    begin
      Writeln(E.Message);
      tr.Rollback
    end
  end;
  finally
    t.Close;
    if tr.Active then
      tr.Commit;

    if dmLogUpload.LogUploadEnabled then
      dmLogUpload.EnableOnlineLogSupport(False);

    FreeAndNil(t);
    FreeAndNil(tr)
  end
end;

function TdmData.CallExistsInLog(callsign,band,mode,LastDate,LastTime : String) : Boolean;
var
  sql : String;
begin
  EnterCriticalsection(csPreviousQSO);
  try
    Result := False;
    qBandMapFil.Close;

    //this ugly query is because I made a stupid mistake when stored qsodate and time_on as Varchar(), now it's probably
    //too late to rewrite it (Petr, OK2CQR)
    sql := 'select id_cqrlog_main from cqrlog_main where (callsign= '+QuotedStr(callsign)+') and (band = '+QuotedStr(band)+') '+
           'and (mode = '+QuotedStr(mode)+') and (str_to_date(concat(qsodate,'+QuotedStr(' ')+',time_on), '+
           QuotedStr('%Y-%m-%d %H:%i')+')) > str_to_date('+QuotedStr(LastDate+' '+LastTime)+', '+QuotedStr('%Y-%m-%d %H:%i')+')';
    qBandMapFil.SQL.Text := sql;
    if fDebugLevel>=1 then Writeln(qBandMapFil.SQL.Text);
    qBandMapFil.Open;
    Result := qBandMapFil.RecordCount > 0
  finally
    qBandMapFil.Close;
    trBandMapFil.RollBack;
    LeaveCriticalsection(csPreviousQSO)
  end
end;

function TdmData.RbnMonDXCCInfo(adif : Word; band, mode : String;DxccWithLoTW:Boolean; var index : integer) : String;
var
  sAdif : String = '';
begin
  // index : 0 - unknown country, no qsl needed
  // index : 1 - New country
  // index : 2 - New band country
  // index : 3 - New mode country
  // index : 4 - QSL needed
  if (adif = 0) then
  begin
    Result := 'Unknown country';
    index  := 0;
    exit
  end;
  index := 1;
  sAdif := IntToStr(adif);

  if trRbnMon.Active then
    trRbnMon.Rollback;

  try try
    if DxccWithLoTW then
      qRbnMon.SQL.Text := 'SELECT id_cqrlog_main FROM '+dmData.DBName+'.cqrlog_main WHERE adif='+
                    sAdif+' AND band='+QuotedStr(band)+' AND ((qsl_r='+
                    QuotedStr('Q')+') OR (lotw_qslr='+QuotedStr('L')+')) AND mode='+
                    QuotedStr(mode)+' LIMIT 1'
    else
      qRbnMon.SQL.Text := 'SELECT id_cqrlog_main FROM '+dmData.DBName+'.cqrlog_main WHERE adif='+
                     sAdif+' AND band='+QuotedStr(band)+' AND qsl_r='+
                     QuotedStr('Q')+ ' AND mode='+QuotedStr(mode)+' LIMIT 1';
    trRbnMon.StartTransaction;
    qRbnMon.Open;
    if qRbnMon.Fields[0].AsInteger > 0 then
    begin
      Result := 'Confirmed country!!';
      index  := 0
    end
    else begin
      qRbnMon.Close;
      qRbnMon.SQL.Text := 'SELECT id_cqrlog_main FROM '+dmData.DBName+'.cqrlog_main WHERE adif='+
                     sAdif+' AND band='+QuotedStr(band)+' AND mode='+
                     QuotedStr(mode)+' LIMIT 1';
      qRbnMon.Open;
      if qRbnMon.Fields[0].AsInteger > 0 then
      begin
        Result := 'QSL needed !!';
        index := 4
      end
      else begin
        qRbnMon.Close;
        qRbnMon.SQL.Text := 'SELECT id_cqrlog_main FROM '+dmData.DBName+'.cqrlog_main WHERE adif='+
                       sAdif+' AND band='+QuotedStr(band)+' LIMIT 1';
        qRbnMon.Open;
        if qRbnMon.Fields[0].AsInteger > 0 then
        begin
          Result := 'New mode country!!';
          index  := 3
        end
        else begin
          qRbnMon.Close;
          qRbnMon.SQL.Text := 'SELECT id_cqrlog_main FROM '+dmData.DBName+'.cqrlog_main WHERE adif='+
                         sAdif+' LIMIT 1';
          qRbnMon.Open;
          if qRbnMon.Fields[0].AsInteger>0 then
          begin
            Result := 'New band country!!';
            index  := 2
          end
          else begin
            Result := 'New country!!';
            index  := 1
          end
        end
      end
    end
  except
    on E : Exception do
      Writeln(E.Message)
  end
  finally
    qRbnMon.Close;
    trRbnMon.Rollback
  end
end;

function TdmData.RbnCallExistsInLog(callsign,band,mode,LastDate,LastTime : String) : Boolean;
var
  sql : String;
begin
  try
    Result := False;
    qRbnMon.Close;

    //this ugly query is because I made a stupid mistake when stored qsodate and time_on as Varchar(), now it's probably
    //too late to rewrite it (Petr, OK2CQR)
    qRbnMon.SQL.Text := 'select id_cqrlog_main from cqrlog_main where (callsign= :callsign) and (band = :band) '+
           'and (mode = :mode) and (str_to_date(concat(qsodate, '+QuotedStr(' ')+',time_on), '+
           QuotedStr('%Y-%m-%d %H:%i')+')) > str_to_date(:last_date_time, '+QuotedStr('%Y-%m-%d %H:%i')+')';

    qRbnMon.Prepare;
    qRbnMon.ParamByName('callsign').AsString := callsign;
    qRbnMon.ParamByName('band').AsString := band;
    qRbnMon.ParamByName('mode').AsString := mode;
    qRbnMon.ParamByName('last_date_time').AsString := LastDate + ' ' + LastTime;
    if fDebugLevel>=1 then Writeln(qRbnMon.SQL.Text);
    qRbnMon.Open;

    Result := qRbnMon.RecordCount > 0
  finally
    qRbnMon.Close;
    trRbnMon.RollBack
  end
end;

procedure TdmData.StoreFreqMemories(grid : TStringGrid);
const
  C_INS = 'insert into freqmem (freq,mode,bandwidth,info) values (:freq,:mode,:bandwidth,:info)';
  C_DEL = 'delete from freqmem';
var
  i : Integer;
begin
  try try
    dmData.qFreqMemGrid.Close;
    if dmData.trFreqMemGrid.Active then  dmData.trFreqMemGrid.Rollback;
    dmData.trFreqMemGrid.StartTransaction;
    dmData.qFreqMemGrid.SQL.Text := C_DEL;
    dmData.qFreqMemGrid.ExecSQL;
    dmData.trFreqMemGrid.Commit;

    dmData.trFreqMemGrid.StartTransaction;
    dmData.qFreqMemGrid.SQL.Text := C_INS;
    for i:= 1 to grid.RowCount-1 do
    begin
      qFreqMemGrid.Prepare;
      qFreqMemGrid.Params[0].AsFloat   := StrToFloat(grid.Cells[0,i]);
      qFreqMemGrid.Params[1].AsString  := grid.Cells[1,i];
      qFreqMemGrid.Params[2].AsInteger := StrToInt(grid.Cells[2,i]);
      qFreqMemGrid.Params[3].AsUTF8String  := grid.Cells[3,i];
      qFreqMemGrid.ExecSQL;
    end
  except
    dmData.trFreqMemGrid.Rollback
  end
  finally
    dmData.qFreqMemGrid.Close;
    if dmData.trFreqMemGrid.Active then
      dmData.trFreqMemGrid.Commit;
    OpenFreqMemories(frmTRXControl.GetRawMode)
  end
end;

procedure TdmData.LoadFreqMemories(grid : TStringGrid);
const
  C_SEL = 'select freq,mode,bandwidth,info from freqmem order by freq';
begin
  try
    grid.clear;
    grid.RowCount := 1;
    dmData.qFreqMemGrid.Close;
    if  dmData.trFreqMemGrid.Active then dmData.trFreqMemGrid.Rollback;
    dmData.trFreqMemGrid.StartTransaction;
    dmData.qFreqMemGrid.SQL.Text := C_SEL;
    dmData.qFreqMemGrid.Open;
    while not dmData.qFreqMemGrid.Eof do
    begin
      grid.RowCount := grid.RowCount + 1;
      grid.Cells[0,grid.RowCount-1] := FloatToStrF(qFreqMemGrid.Fields[0].AsFloat,ffFixed,15,3);
      grid.Cells[1,grid.RowCount-1] := qFreqMemGrid.Fields[1].AsString;
      grid.Cells[2,grid.RowCount-1] := IntToStr(qFreqMemGrid.Fields[2].AsInteger);
      grid.Cells[3,grid.RowCount-1] := qFreqMemGrid.Fields[3].AsUTF8String;
      qFreqMemGrid.Next
    end
  finally
    dmData.qFreqMemGrid.Close;
    dmData.trFreqMemGrid.Rollback
  end

end;

procedure TdmData.OpenFreqMemories(mode : String);
const
  C_SEL = 'select id,freq,mode,bandwidth,info from freqmem';
var
  c : integer;
begin
  qFreqMem.Close;
  if trFreqMem.Active then trFreqMem.Rollback;

  if not cqrini.ReadBool('TRX','MemModeRelated',False) then mode:='';   //use related settings!!

  if (mode='') then qFreqMem.SQL.Text := C_SEL + ' order by id'
  else
   begin
    case mode of
         'LSB','USB','FM','AM'     :qFreqMem.SQL.Text := C_SEL + ' where (mode = ' + QuotedStr('LSB') +') or ' +
                                                           '(mode = ' + QuotedStr('USB') + ') or (mode = ' + QuotedStr('FM') + ') or ' +
                                                           '(mode = ' + QuotedStr('AM')+ ') order by id';
         'RTTY','PKTLSB','PKTUSB',
         'PKTFM','DATA'            :qFreqMem.SQL.Text := C_SEL + ' where (mode = ' + QuotedStr('RTTY') +') or ' +
                                                           '(mode = ' + QuotedStr('PKTLSB') + ') or (mode = ' + QuotedStr('PKTUSB') + ') or ' +
                                                           '(mode = ' + QuotedStr('PKTFM') + ') or (mode = ' + QuotedStr('DATA')+ ') order by id';
     else
      qFreqMem.SQL.Text := C_SEL + ' where (mode = ' + QuotedStr(mode) +') order by id'
    end;
   end;
  if fDebugLevel>=1 then
                    Writeln('FreqmemSql:',qFreqMem.SQL.Text);
  trFreqMem.StartTransaction;
  qFreqMem.Open;
  qFreqMem.Last;  //to get proper record count
  FreqMemCount:=qFreqMem.RecordCount;
  setLength(MemNR,(FreqMemCount)+1);
  qFreqMem.First;
  qFreqMem.prior;
  fFirstMemId := qFreqMem.Fields[0].AsInteger;
  c:=-1;

  repeat
    begin
      inc(c);
       MemNR[c]:= qFreqMem.Fields[0].AsInteger;
       if fDebugLevel>=1 then
          Writeln('FreqmemNR:',c,'=',MemNR[c]);
       qFreqMem.Next;
    end;
   until qFreqMem.Eof;

  qFreqMem.Last;
  fLastMemId := qFreqMem.Fields[0].AsInteger;


  if fDebugLevel>=1 then
     Writeln('FreqmemFirst:',fFirstMemId,'  FreqmemLast:',fLastMemId);
end;

procedure TdmData.GetCurrentFreqFromMem(var freq : Double; var mode : String; var bandwidth : Integer; var info : String);
var
   c: integer;
begin
  if qFreqMem.Active and (FreqMemCount > 0) then
  begin
    freq      := qFreqMem.Fields[1].AsFloat;
    mode      := qFreqMem.Fields[2].AsString;
    bandwidth := qFreqMem.Fields[3].AsInteger;
    info      := qFreqMem.Fields[4].AsString;
    frmTRXControl.edtMemNr.Font.Color:= clDefault; // May be red if previous was "None"
    if info='' then
          begin
            for c:=0 to  FreqMemCount do
                if MemNR[c]= qFreqMem.Fields[0].AsInteger then break;
            frmTRXControl.edtMemNr.Text := IntToStr(c+1)+' of '+ IntToStr(FreqMemCount);
            end
               else frmTRXControl.edtMemNr.Text := info;
    frmTRXControl.infosetstage :=1;
  end
  else begin
     freq      := 0;
     mode      := 'CW';
     bandwidth := 0;
     frmTRXControl.edtMemNr.Font.Color:= clRed;
     frmTRXControl.edtMemNr.Text := 'None';
     frmTRXControl.infosetstage :=1;
  end;
  if fDebugLevel>=1 then Writeln('Freq:',freq,' mode:',mode,' bandwidth:',bandwidth);
end;

procedure TdmData.GetPreviousFreqFromMem(var freq : Double; var mode : String; var bandwidth : Integer; var info : String);
begin
  if not qFreqMem.Active then
  begin
    OpenFreqMemories(frmTRXControl.GetRawMode);
    qFreqMem.Last
  end
  else begin
    //if qFreqMem.Bof then  doesn't work because when it's on the first record, it has to call Prior again to be sure that
    //it's really first - that caused user has to click twice to get on the end of the table
    if fDebugLevel>=1 then writeln('-----------UP---', qFreqMem.Fields[0].AsInteger,' ',   fFirstMemId);
    if (fFirstMemId = qFreqMem.Fields[0].AsInteger) then
      qFreqMem.Last
    else
      qFreqMem.Prior
  end;
  GetCurrentFreqFromMem(freq,mode,bandwidth,info)
end;


procedure TdmData.GetNextFreqFromMem(var freq : Double; var mode : String; var bandwidth : Integer; var info : String);
begin
  if not qFreqMem.Active then
  begin
    OpenFreqMemories(frmTRXControl.GetRawMode);
    qFreqMem.First
  end
  else begin
    //if qFreqMem.Eof then the same problem like with Bof()
    if fDebugLevel>=1 then writeln('-----------DN---', qFreqMem.Fields[0].AsInteger,' ',   fLastMemId);
    if (fLastMemId = qFreqMem.Fields[0].AsInteger) then
      qFreqMem.First
    else
      qFreqMem.Next
  end;
  GetCurrentFreqFromMem(freq,mode,bandwidth,info)
end;


procedure TdmData.SaveBandChanges(band : String; BandBegin, BandEnd, BandCW, BandRTTY, BandSSB, RXOffset, TXOffset : Currency);
const
  C_UPD = 'update cqrlog_common.bands set b_begin = :b_begin, b_end = :b_end, cw = :cw, rtty = :rtty, '+
          'ssb = :ssb, rx_offset = :rx_offset, tx_offset = :tx_offset where band = :band';
begin
  qBands.Close;
  if trBands.Active then
    trBands.Rollback;

  trBands.StartTransaction;
  try try
    qBands.SQL.Text := C_UPD;
    qBands.Prepare;
    qBands.Params[0].AsCurrency := BandBegin;
    qBands.Params[1].AsCurrency := BandEnd;
    qBands.Params[2].AsCurrency := BandCW;
    qBands.Params[3].AsCurrency := BandRTTY;
    qBands.Params[4].AsCurrency := BandSSB;
    qBands.Params[5].AsCurrency := RXOffset;
    qBands.Params[6].AsCurrency := TXOffset;
    qBands.Params[7].AsString   := band;
    qBands.ExecSQL
  except
    on E : Exception do
    begin
      Writeln(E.Message);
      trBands.Rollback
    end
  end
  finally
    if trBands.Active then
      trBands.Commit
  end
end;

procedure TdmData.GetRXTXOffset(Freq : Currency; var RXOffset,TXOffset : Currency);
const
  C_SEL = 'select rx_offset, tx_offset from cqrlog_common.bands where b_begin <= :b_begin '+
          'and b_end >= :b_end';
begin
  RXOffset := 0;
  TXOffset := 0;

  qBands.Close;
  if trBands.Active then
    trBands.Rollback;

  trBands.StartTransaction;
  try try
    qBands.SQL.Text := C_SEL;
    qBands.Prepare;
    qBands.Params[0].AsCurrency := Freq;
    qBands.Params[1].AsCurrency := Freq;
    qBands.Open;

    if qBands.RecordCount > 0 then
    begin
      RXOffset := qBands.Fields[0].AsCurrency;
      TXOffset := qBands.Fields[1].AsCurrency
    end
  except
    on E : Exception do
      Writeln(E.Message)
  end
  finally
    qBands.Close;
    trBands.Rollback
  end
end;

procedure TdmData.CreateDBConnections;
begin
  MainCon      := getNewMySQLConnectionObject();
  BandMapCon   := getNewMySQLConnectionObject();
  RbnMonCon    := getNewMySQLConnectionObject();
  LogUploadCon := getNewMySQLConnectionObject();
  dbDXC        := getNewMySQLConnectionObject();
end;


function TdmData.GetDebugLevel : Integer;
var
  i : Integer;
begin
  Result := 0;
  Application.CaseSensitiveOptions:=False; // this is done at start but to be sure...
  if Application.HasOption('debug') then
     if TryStrToInt(Application.GetOptionValue('debug'),i) then
                                                               Result:=i;
end;

function TdmData.GetNewLogNumber : Integer;
const
  C_SEL = 'select log_nr from cqrlog_common.log_list order by log_nr';
var
  t  : TSQLQuery;
  tr : TSQLTransaction;
  i  : Integer = 1;
begin
  Result := 0;
  t := TSQLQuery.Create(nil);
  tr := TSQLTransaction.Create(nil);
  try
    t.Transaction := tr;
    tr.DataBase   := MainCon;
    t.DataBase    := MainCon;

    t.SQL.Text := C_SEL;
    if fDebugLevel>=1 then Writeln(t.SQL.Text);
    t.Open;

    t.First;
    while not t.EOF do
    begin
      if (i = t.Fields[0].AsInteger) then
      begin
        inc(i)
      end
      else begin
        break
      end;

      t.Next
    end;

    Result := i
  finally
    t.Close;
    tr.Rollback;
    FreeAndNil(t);
    FreeAndNil(tr)
  end
end;

procedure TdmData.LoadQSODateColorSettings;
begin
  UseQSOColor  := cqrini.ReadBool('Program', 'QSODiffColor', False);
  QSOColor     := cqrini.ReadInteger('Program', 'QSOColor', clBlack);

  if UseQSOColor then
  begin
    if dmUtils.IsDateOK(cqrini.ReadString('Program', 'QSOColorDate', '')) then
      QSOColorDate := dmUtils.StrToDateFormat(cqrini.ReadString('Program', 'QSOColorDate', ''))
    else
      QSOColorDate := dmUtils.StrToDateFormat('2050-12-31')
  end
  else
    QSOColorDate := now
end;

function TdmData.getNewMySQLConnectionObject : TMySQL57Connection;
var
  Connection : TMySQL57Connection;
begin
  Connection := TMySQL57Connection.Create(self);
  Connection.SkipLibraryVersionCheck := True;
  Connection.KeepConnection := True;

  result := Connection
end;

end.

