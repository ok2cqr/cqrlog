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
  Classes, SysUtils, LResources, Forms, Controls, Dialogs, DB, FileUtil, Dbf,
  memds, mysql51conn, sqldb, inifiles, stdctrls, RegExpr,
  dynlibs, lcltype, ExtCtrls, sqlscript, process, mysql51dyn, ssl_openssl_lib,
  mysql55dyn, mysql55conn;

const
  MaxCall   = 100000;
  cDB_LIMIT = 500;
  cDB_MAIN_VER = 4;
  cDB_COMN_VER = 1;
  cDB_PING_INT = 480;  //ping interval for database connection in seconds
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
  TClub = record
    Name           : String;
    LongName       : String;
    NewInfo        : String;
    NewBandInfo    : String;
    NewModeInfo    : String;
    QSLNeededInfo  : String;
    AlreadyCfmInfo : String;
    ClubField      : String;
    MainFieled     : String;
    StoreField     : String;
    StoreText      : String;
    NewColor       : Integer;
    BandColor      : Integer;
    ModeColor      : Integer;
    QSLColor       : Integer;
    AlreadyColor   : Integer;
    DateFrom       : String;
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
    dsrSQLConsole: TDatasource;
    dsrLogList: TDatasource;
    dsrmQ: TDatasource;
    dbfBand: TDbf;
    mQ: TSQLQuery;
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
    qDXClusters: TSQLQuery;
    qComment: TSQLQuery;
    qException: TSQLQuery;
    qQSOBefore: TSQLQuery;
    Q1: TSQLQuery;
    Q: TSQLQuery;
    qCQRLOG: TSQLQuery;
    scViews: TSQLScript;
    scQSLExport : TSQLScript;
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
    tblImport: TDbf;
    dsrDXCluster: TDatasource;
    dsrProfiles: TDatasource;
    dsrBands: TDatasource;
    dsrImport: TDatasource;
    dsrQSOBefore: TDatasource;
    dsrMain: TDatasource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure Q1BeforeOpen(DataSet: TDataSet);
    procedure qBandsBeforeOpen(DataSet: TDataSet);
    procedure QBeforeOpen(DataSet: TDataSet);
    procedure qCQRLOGAfterOpen(DataSet: TDataSet);
    procedure dsQSOBeforeAfterOpen(DataSet: TDataSet);
    procedure mQBeforeOpen(DataSet: TDataSet);
    procedure qCQRLOGBeforeOpen(DataSet: TDataSet);
    procedure qLogListBeforeOpen(DataSet: TDataSet);
    procedure qLongNoteBeforeOpen(DataSet: TDataSet);
    procedure scLogException(Sender: TObject; Statement: TStrings;
      TheException: Exception; var Continue: boolean);
    procedure scViewsException(Sender: TObject; Statement: TStrings;
      TheException: Exception; var Continue: boolean);
    procedure tmrDBPingTimer(Sender: TObject);
  private
    fDBName  : String;
    fHomeDir : String;
    fDataDir : String;
    fMembersDir : String;
    fDebugLevel : Integer;
    fOrderBy : String;
    fVersionString : String;
    fHelpDir  : String;
    fContestMode : Boolean;
    fContestDataDir : String;
    fContestDataFile : String;
    fProgramMode : TMode;
    fCWStopped : Boolean;
    fZipCodeDir : String;
    fSortType   : TSortType;
    fDLLSSLName  : String;
    fDLLUtilName : String;
    fLogName     : String;
    fUsrHomeDir  : String;
    fShareDir    : String;
    aProf : Array of TExpProfile;
    aSCP  : Array of String[20];
    MySQLProcess : TProcess;

    fMySQLVersion : Currency;

    function  FindLib(const Path,LibName : String) : String;

    procedure CreateViews;
    procedure PrepareBandDatabase;
    procedure PrepareDXClusterDatabase;
    procedure DeleteMySQLPidFile;
    procedure PrepareDirectories;
    procedure PrepareCtyData;
    procedure PrepareDXCCData;
    procedure PrepareXplanetDir;
    procedure PrepareVoice_keyerDir;
    procedure PrepareBandMapDB;
    procedure KillMySQL(const OnStart : Boolean = True);
    procedure CloseBandMapDB;
    procedure UpdateDatabase(old_version : Integer);
  public
    {
    MainCon51 : TMySQL51Connection;
    MainCon55 : TMySQL55Connection;
    }
    MainCon   : TSQLConnection;
    eQSLUsers : Array of ShortString;
    CallArray : Array [0..MaxCall] of String[20];
    IsFilter  : Boolean;
    IsSFilter : Boolean; //Search filter
    //search function uses filter function but user doesn't need to know about it
    //if he wants to use export, program use the same functions for filter enabled

    Ascening  : Boolean;
    Club1     : TClub;
    Club2     : TClub;
    Club3     : TClub;
    Club4     : TClub;
    Club5     : TClub;

    Zip1  : TZipCode;
    Zip2  : TZipCode;
    Zip3  : TZipCode;

    //tstini : TMyIni;

    property DBName  : String read fDbName;
    property HomeDir : String read fHomeDir write fHomeDir; //~/.config/cqrlog
    property OrderBy : String read fOrderBy write fOrderBy;  //default value is qsodate,time_on
    property DataDir : String read fDataDir write fDataDir;
    property ShareDir   : String read fShareDir write fShareDir;
    property MembersDir : String read fMembersDir;
    property ZipCodeDir : String read fZipCodeDir;
    property UsrHomeDir : String read fUsrHomeDir;
    property DebugLevel : Integer read fDebugLevel write fDebugLevel;
    //^ 0 - nothing, 1 - SQL queries 2 - Transactions, etc.
    property VersionString : String read fVersionString write fVersionString;
    property HelpDir : String read fHelpDir write fHelpDir;

    property ContestMode : Boolean read fContestMode write fContestMode;
    property ContestDataDir : String read fContestDataDir write fContestDataDir;
    property ContestDataFile : String read fContestDataFile write fContestDataFile;

    property ProgramMode : TMode read fProgramMode write fProgramMode;
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
    function  ProfileExists(nr : string) : Boolean;
    function  ProfileInUse(nr : String) : Boolean;
    function  SendQSL(call,mode,freq : String; adif : Word) : String;
    {$IFDEF CONTEST}
    function  OpenContestDatabase(FileName : String) : Boolean;
    {$ENDIF}
    function  GetSCPCalls(call : String) : String;
    function  UsesLotw(call : String) : Boolean;
    function  OpenConnections(host,port,user,pass : String) : Boolean;
    function  LogExists(nr : Word) : Boolean;
    function  GetProperDBName(nr : Word) : String;
    function  GetQSOCount : Integer;
    function  UseseQSL(call : String) : Boolean;
    function  QueryLocate(qry : TSQLQuery; Column : String; Value : Variant; DisableGrid : Boolean; exatly : Boolean = True) : Boolean;

    procedure SaveQSO(date : TDateTime; time_on,time_off,call : String; freq : Currency;mode,rst_s,
                      rst_r, stn_name,qth,qsl_s,qsl_r,qsl_via,iota,pwr : String; itu,waz : Integer;
                      loc, my_loc,county,award,remarks : String; adif : Integer;
                      idcall,state,cont : String; qso_dxcc : Boolean; profile : Integer;
                      nclub1,nclub2,nclub3,nclub4,nclub5 : String);

    procedure EditQSO(date : TDateTime; time_on,time_off,call : String; freq : Currency;mode,rst_s,
                      rst_r, stn_name,qth,qsl_s,qsl_r,qsl_via,iota,pwr : String; itu,waz : Integer;
                      loc, my_loc,county,award,remarks : String; adif : Word; idcall,state,cont : String;
                      qso_dxcc : Boolean; profile : Integer; idx : LongInt);
    procedure SaveComment(call,text : String);
    procedure PrepareImport;
    procedure DoAfterImport;
    procedure InsertProfiles(cmbProfile : TComboBox; ShowAll : Boolean);
    procedure InsertProfiles(cmbProfile : TComboBox; ShowAll,loc,qth,rig : Boolean); overload;
    procedure RefreshMainDatabase(id : Integer = 0);
    procedure LoadClubsSettings;
    procedure LoadZipSettings;

    {$IFDEF CONTEST}
    procedure CreateContestDatabase(FileName : String);
    procedure DeleteContestQSO(id : LongInt);
    procedure SaveContestQSO(date : TDateTime;time_on,call,rst_s,rst_r,exch1,exch2,freq,mode,
                             waz,itu,dxcc_ref : String);
    procedure EditTestQSO(qsodate,time_on,call,freq,mode,rst_s,rst_r,exch1,exch2,sname,qth,power,
                          waz,itu,wpx,state,iota : String;points : Integer;mult1,mult2 : Boolean;
                          id : LongInt);
    procedure GetLastExchange(call : String; var exch : String; var CurPos : TCurPos);
    {$ENDIF}

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
  end;

var
  dmData : TdmData;
  handle : THandle;
  reg    : TRegExpr;


implementation

uses dUtils, dDXCC, fMain, fWorking, fUpgrade, fImportProgress, fNewQSO, dDXCluster, uMyIni,
     fTRXControl, fRotControl, uVersion;

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
      ImportType := 1;
      ShowModal
    finally
      Free
    end;

    with TfrmImportProgress.Create(self) do
    try
      lblComment.Caption := 'Importing QSL data ...';
      Directory     := dmData.fHomeDir + 'ctyfiles' + PathDelim;
      FileName      := Directory+'qslmgr.csv';
      ImportType    := 5;
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
  RefreshLogList(nr)
end;

function TdmData.OpenConnections(host,port,user,pass : String) : Boolean;
begin
  Result := True;

  if MainCon.Connected then
    MainCon.Connected := False;
  if dmDXCluster.dbDXC.Connected then
    dmDXCluster.dbDXC.Connected := False;

  if fMySQLVersion < 5.5 then
  begin
    (MainCon as TMySQL51Connection).HostName := host;
    (MainCon as TMySQL51Connection).Port     := StrToInt(port)
  end
  else begin
    (MainCon as TMySQL55Connection).HostName := host;
    (MainCon as TMySQL55Connection).Port     := StrToInt(port)
  end;
  MainCon.UserName     := user;
  MainCon.Password     := pass;
  MainCon.DatabaseName := 'information_schema';

  if fMySQLVersion < 5.5 then
  begin
    (dmDXCluster.dbDXC as TMySQL51Connection).HostName := host;
    (dmDXCluster.dbDXC as TMySQL51Connection).Port     := StrToInt(port)
  end
  else begin
    (dmDXCluster.dbDXC as TMySQL55Connection).HostName := host;
    (dmDXCluster.dbDXC as TMySQL55Connection).Port     := StrToInt(port)
  end;
  dmDXCluster.dbDXC.UserName     := user;
  dmDXCluster.dbDXC.Password     := pass;
  dmDXCluster.dbDXC.DatabaseName := 'information_schema';

  try
    MainCon.Connected := True;
    dmDXCluster.dbDXC.Connected := True
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
  v : Integer;
begin
  fDBName := GetProperDBName(nr);
  if trQ.Active then
    trQ.Rollback;
  Q.SQL.Text := 'use ' + fDBName;
  Writeln(Q.SQL.Text);
  trQ.StartTransaction;
  Q.ExecSQL;
  trQ.Commit;

  if dmDXCluster.trQ.Active then
    dmDXCluster.trQ.Rollback;
  dmDXCluster.Q.Close;
  dmDXCluster.Q.SQL.Text := 'use ' + fDBName;
  Writeln(dmDXCluster.Q.SQL.Text);
  dmDXCluster.trQ.StartTransaction;
  dmDXCluster.Q.ExecSQL;
  dmDXCluster.trQ.Commit;

  DeleteFile(fHomeDir+'cqrlog.cfg');
  Q.SQL.Text := 'SELECT * FROM cqrlog_config';
  trQ.StartTransaction;
  l := TStringList.Create;
  Q.Open;
  try
    l.Text := Q.Fields[1].AsString;
    l.SaveToFile(fHomeDir+'cqrlog.cfg')
  finally
    Q.Close;
    trQ.Rollback;
    l.Free
  end;

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
    UpdateDatabase(Q.Fields[0].AsInteger)
  finally
    Q.Close();
    trQ.Rollback
  end;

  if Assigned(cqrini) then
    cqrini.Free;

  cqrini := TMyIni.Create(fHomeDir+'cqrlog.cfg');

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

  frmTRXControl.InicializeRig;
  frmRotControl.InicializeRot;

  PrepareBandMapDB;
  LoadClubsSettings;
  LoadZipSettings
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
    l.LoadFromFile(fHomeDir+'cqrlog.cfg');
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
  Writeln('Saving ini file to database')
end;

procedure TdmData.CloseDatabases;
var
  i : Integer;
begin
  CloseBandMapDB;
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
  end;
  FreeAndNil(cqrini)
end;

procedure TdmData.CloseBandMapDB;
begin
  dbfBand.Close;
  if not cqrini.ReadBool('BandMap','Save',False) then
  begin
    DeleteFile(fHomeDir+'bandmap.dat');
    DeleteFile(fHomeDir+'bandmap.mdx')
  end
  else begin
    dbfBand.Exclusive := True;
    dbfBand.Open;
    dbfBand.PackTable;
    dbfBand.Close
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
    Writeln(fDataDir + SearchRec.Name);
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
      if dmData.DebugLevel>=1 then Writeln('Command: ',p.CommandLine);
      p.CommandLine := 'kill '+pid;
      if fDebugLevel>=1 then Writeln(p.CommandLine);
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

  if DirectoryExistsUTF8(fHomeDir+'members') then
    fMembersDir := fHomeDir+'members'+PathDelim
  else
    fMembersDir := ExpandFileNameUTF8('..'+PathDelim+'share'+PathDelim+'cqrlog'+
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
    CreateDirUTF8(fHomeDir+'voice_keyer')
end;

procedure TdmData.PrepareCtyData;
var
  s,d : String;
begin
  s := ExpandFileNameUTF8('..'+PathDelim+'share'+PathDelim+'cqrlog'+PathDelim+'ctyfiles'+PathDelim);
  d := fHomeDir+'ctyfiles'+PathDelim;

  if not FileExistsUTF8(fHomeDir+'ctyfiles'+PathDelim+'AreaOK1RR.tbl') then
  begin
    Writeln('');
    Writeln('Ctyfiles dir: ',ExpandFileNameUTF8(s));
    Writeln('Local ctyfiles dir: ',d);

    CopyFile(s+'AreaOK1RR.tbl',d+'AreaOK1RR.tbl',True);
    CopyFile(s+'CallResolution.tbl',d+'CallResolution.tbl',True);
    CopyFile(s+'Country.tab',d+'Country.tab',True);
    CopyFile(s+'CountryDel.tab',d+'CountryDel.tab',True);
    CopyFile(s+'Ambiguous.tbl',d+'Ambiguous.tbl',True);
    CopyFile(s+'Exceptions.tbl',d+'Exceptions.tbl',True);
    CopyFile(s+'iota.tbl',d+'iota.tbl',True);
    CopyFile(s+'qslmgr.csv',d+'qslmgr.csv',True)
  end;

  if not FileExistsUTF8(fHomeDir+'lotw1.txt') then
    CopyFile(s+'lotw1.txt',fHomeDir+'lotw1.txt',True);
  if not FileExistsUTF8(fHomeDir+'eqsl.txt') then
    CopyFile(s+'eqsl.txt',fHomeDir+'eqsl.txt',True);
  if not FileExistsUTF8(fHomeDir+'MASTER.SCP') then
    CopyFile(s+'MASTER.SCP',fHomeDir+'MASTER.SCP',True)
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
    CopyFile(fHomeDir+'ctyfiles'+PathDelim+'Exceptions.tbl',
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

procedure TdmData.PrepareBandMapDB;
begin
  dbfBand.FilePathFull := fHomeDir;
  dbfBand.TableName  := 'bandmap.dat';
  if not FileExists(fHomeDir+'bandmap.dat') then
  begin
    dbfBand.TableLevel := 7;
    dbfBand.Exclusive  := True;
    dbfBand.FieldDefs.Clear;
    With dbfBand.FieldDefs do begin
      Add('vfo_a', ftFloat);
      Add('Call', ftString, 20);
      Add('vfo_b', ftFloat);
      Add('split',ftBoolean);
      Add('color',ftLargeint);
      Add('mode',ftString,8);
      Add('band',ftString,6);
      Add('time',ftDateTime);
      Add('age', ftString,1);
      Add('pfx',ftString,10);
      Add('lat',ftString,10);
      Add('long',ftString,10);
      Add('id', ftAutoInc);
      Add('bckcolor',ftLargeint);
      Add('splitstr',ftString,13);
    end;
    dbfBand.CreateTable;
    dbfBand.Open;
    dbfBand.AddIndex('id','id', [ixPrimary, ixUnique]);
    dbfBand.AddIndex('vfo_a','vfo_a', []);
    dbfBand.Close;
    dbfBand.Exclusive := false;
    dbfBand.Open
  end
  else
    dbfBand.Open;
  dbfBand.IndexName := 'vfo_a';
end;

function TdmData.FindLib(const Path,LibName : String) : String;
var
  res       : Byte;
  SearchRec : TSearchRec;
begin
  Result := '';
  res := FindFirst(Path + LibName, faAnyFile, SearchRec);
  try
    while Res = 0 do
    begin
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
end;

procedure TdmData.DataModuleCreate(Sender: TObject);
var
  lib    : String;
  mysqld : String;
  l      : TStringList;
  info   : String = '';
  f      : TextFile;
  i      : Integer;
  c      : TConnectionName;
  MySQLVer : String;
begin
  cqrini       := nil;
  IsSFilter    := False;
  fDebugLevel  := 2;
  fDLLSSLName  := '';
  fDLLUtilName := '';


  lib :=  FindLib('/usr/lib64/','libssl.so*');
  if (lib = '') then
    lib := FindLib('/lib64/','libssl.so*');
  if (lib='') then
    lib := FindLib('/usr/lib/x86_64-linux-gnu/','libssl.so*');
  if (lib='') then
    lib := FindLib('/usr/lib/i386-linux-gnu/','libssl.so*');
  if (lib = '') then
    lib :=  FindLib('/usr/lib/','libssl.so*');
  if (lib = '') then
    lib := FindLib('/lib/','libssl.so*');

  if fDebugLevel>=1 then Writeln('Loading libssl: ',lib);
  if lib <> '' then
    fDLLSSLName := lib;

  lib := FindLib('/usr/lib64/','libcrypto.so*');
  if (lib = '') then
    lib := FindLib('/lib64/','libcrypto.so*');
  if (lib='') then
    lib := FindLib('/usr/lib/x86_64-linux-gnu/','libcrypto.so*');
  if (lib='') then
    lib := FindLib('/usr/lib/i386-linux-gnu/','libcrypto.so*');
  if (lib = '') then
    lib :=  FindLib('/usr/lib/','libcrypto.so*');
  if (lib = '') then
    lib := FindLib('/lib/','libcrypto.so*');

  if fDebugLevel>=1 then Writeln('Loading libcrypto: ',lib);
  if lib <> '' then
    fDLLUtilName := lib;

  lib := FindLib('/usr/lib64/','libmysqlclient.so*');
  if (lib = '') then
    lib := FindLib('/lib64/','libmysqlclient.so*');
  if (lib='') then
    lib := FindLib('/usr/lib/x86_64-linux-gnu/','libmysqlclient.so*');
  if (lib='') then
    lib := FindLib('/usr/lib/i386-linux-gnu/','libmysqlclient.so*');
  if (lib='') then
    lib := FindLib('/usr/lib64/mysql/','libmysqlclient.so*');
  if (lib = '') then
    lib :=  FindLib('/usr/lib/','libmysqlclient.so*');
  if (lib = '') then
    lib := FindLib('/lib/','libmysqlclient.so*');
  if (lib='') then
    lib := FindLib('/usr/lib/mysql/','libmysqlclient.so*');

  if fDebugLevel>=1 then Writeln('Loading libmysqlclient: ',lib);
  if lib <> '' then
    InitialiseMySQL(lib);

  try try
    c := TConnectionName.Create(nil);
    MySQLVer := copy(c.ClientInfo,1,3);
  except
    on E : Exception do
    begin
      Writeln('FATAL ERROR: Can not get MySQL client library version version!',LineEnding,
              'Setting to default version (5.1)');
      MySQLVer := '5.1'
    end
  end
  finally
    FreeAndNil(c)
  end;

  if not TryStrToCurr(MySQLVer,fMySQLVersion) then
    fMySQLVersion := 5.1;

  if fMySQLVersion < 5.5 then
    MainCon := TMySQL51Connection.Create(self)
  else
    MainCon := TMySQL55Connection.Create(self);

  MainCon.Transaction := trmQ;
  for i:=0 to ComponentCount-1 do
  begin
    if Components[i] is TSQLQuery then
      (Components[i] as TSQLQuery).DataBase := MainCon;
    if Components[i] is TSQLTransaction then
      (Components[i] as TSQLTransaction).DataBase := MainCon
  end;

  DLLSSLName  := dmData.cDLLSSLName;
  DLLUtilName := dmData.cDLLUtilName;

  //^^this ugly hack is because FreePascal doesn't have anything like
  // ./configure and I have to specify all dyn libs by hand

  ShortDateFormat := 'yyyy-mm-dd';

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

  if not FileExistsUTF8(fDataDir+'my.cnf') then
  begin
    Writeln(fDataDir+'my.cnf');
    AssignFile(f,fDataDir+'my.cnf');
    Rewrite(f);
    Writeln(f,' ');
    CloseFile(f)
  end;

  //Mysql still may be running, so we must close it first
  KillMySQL;

  Writeln('*');
  Writeln('User home directory:    ',fUsrHomeDir);
  Writeln('Program home directory: ',fHomeDir);
  Writeln('Data directory:         ',fDataDir);
  Writeln('Memebers directory:     ',fMembersDir);
  Writeln('ZIP code directory:     ',fZipCodeDir);
  Writeln('Binary dir:             ',ExtractFilePath(Paramstr(0)));
  Writeln('Share dir:              ',fShareDir);
  Writeln('TConnection to MySQL:   ',FloatToStr(fMySQLVersion));
  Writeln('*');

  if FileExistsUTF8('/usr/bin/mysqld') then
    mysqld := '/usr/bin/mysqld';
  if FileExistsUTF8('/usr/bin/mysqld_safe') then //Fedora
    mysqld := '/usr/bin/mysqld_safe';
  if FileExistsUTF8('/usr/sbin/mysqld') then //openSUSE
    mysqld := '/usr/sbin/mysqld';
  if mysqld = '' then  //don't know where mysqld is, so hopefully will be in  $PATH
    mysqld := 'mysqld';

  if FileExistsUTF8('/etc/apparmor.d/usr.sbin.mysqld') then
  begin
    l := TStringList.Create;
    try
      l.LoadFromFile('/etc/apparmor.d/usr.sbin.mysqld');
      l.Text := UpperCase(l.Text);
      if Pos(UpperCase('@{HOME}/.config/cqrlog/database/** rwk,'),l.Text) = 0 then
      begin
        info := 'It looks like apparmor is running in your system. CQRLOG needs to add this :'+
                LineEnding+
                '@{HOME}/.config/cqrlog/database/** rwk,'+
                LineEnding+
                'into /etc/apparmor.d/usr.sbin.mysqld'+
                LineEnding+
                LineEnding+
                'You can do that by running /usr/share/cqrlog/cqrlog-apparmor-fix or you can add the line '+
                'and restart apparmor manually.'+
                LineEnding+
                LineEnding+
                'Click OK to continue (program may not work correctly) or Cancel and modify the file '+
                'first.';
         if Application.MessageBox(PChar(info),'Information ...',mb_OKCancel+mb_IconInformation) = idCancel then
           Application.Terminate
      end
    finally
      l.Free
    end
  end;

  MySQLProcess := TProcess.Create(nil);
  MySQLProcess.CommandLine := mysqld+' --defaults-file='+fHomeDir+'database/'+'my.cnf'+
                              ' --default-storage-engine=MyISAM --datadir='+fHomeDir+'database/'+
                              ' --socket='+fHomeDir+'database/sock'+
                              ' --skip-grant-tables --port=64000 --key_buffer_size=32M'+
                              ' --key_buffer_size=4096K';
  WriteLn(MySQLProcess.CommandLine);
  MySQLProcess.Execute;
  fContestMode := False;

  tmrDBPing.Interval := CDB_PING_INT*1000;
  tmrDBPing.Enabled  := True;

  {$IFDEF CONTEST}
  if ParamStr(1) = '--contest-mode' then
  begin
    fContestMode := True;
  end;

  if not DirectoryExists(ExtractFilePath(Application.ExeName)+'contest_data') then
  begin
    CreateDir(ExtractFilePath(Application.ExeName)+'contest_data');
    CreateDir(ExtractFilePath(Application.ExeName)+'contest_data/logs');
    CreateDir(ExtractFilePath(Application.ExeName)+'contest_data/common');
  end;
  fContestDataDir := ExtractFilePath(Application.ExeName)+'contest_data/logs/';

  if fContestMode and FileExists(ExtractFilePath(Application.ExeName)+'contest_data/common/MASTER.SCP') then
  begin
    AssignFile(f,ExtractFilePath(Application.ExeName)+'contest_data/common/MASTER.SCP');
    Reset(f);
    Readln(f,tmp);
    Readln(f,tmp);
    Readln(f,tmp);
    //^^ skip header
    while not eof(f) do
    begin
      Readln(f,tmp);
      if tmp = '' then
        Continue;
      memSCP.Append;
      memSCP.Fields[0].AsString :=  tmp;
      memSCP.Post
    end;
    CloseFile(f)
  end;


  fProgramMode := tmRun;
  fCWStopped   := False;
  if not cqrini.SectionExists('KeysPref') then
  begin
    cqrini.WriteInteger('KeysPref','REmptyExch',6);
    cqrini.WriteInteger('KeysPref','RNotEmptyExch',0);
    cqrini.WriteInteger('KeysPref','RNoCallChange',11);
    cqrini.WriteInteger('KeysPref','RCallChange',1);
    cqrini.WriteInteger('KeysPref','RBackSlash',10);
    cqrini.WriteString('KeysPref','RBackSlashC','TU');
    cqrini.WriteInteger('KeysPref','SEmptyExch',1);
    cqrini.WriteInteger('KeysPref','SNotEmptyExch',0);
    cqrini.WriteInteger('KeysPref','SNoCallChange',7);
    cqrini.WriteInteger('KeysPref','SBackSlash',9);
    cqrini.WriteString('KeysPref','SBackSlashC','TU');
    cqrini.WriteString('KeysPref','RNoCallChangeC','TU %mc TEST');
    cqrini.WriteString('KeysPref','SNoCallChangeC','TU')
  end;
  {$ENDIF}
end;

procedure TdmData.DataModuleDestroy(Sender: TObject);
begin
  if dmData.DebugLevel>=1 then Writeln('Closing dData');
  qCQRLOG.Close;
  reg.Free;
  DeleteFile(dmData.HomeDir + 'xplanet'+PathDelim+'marker');
  MainCon.Connected := False;
  KillMySQL(False)
end;

procedure TdmData.Q1BeforeOpen(DataSet: TDataSet);
begin
  if fDebugLevel >=1 then Writeln(Q1.SQL.Text)
end;

procedure TdmData.qBandsBeforeOpen(DataSet: TDataSet);
begin
  if fDebugLevel>=1 then Writeln(qBands.SQL.Text)
end;

procedure TdmData.QBeforeOpen(DataSet: TDataSet);
begin
  if fDebugLevel >=1 then Writeln(Q.SQL.Text)
end;

procedure TdmData.qCQRLOGAfterOpen(DataSet: TDataSet);
begin
  TFloatField(qCQRLOG.Fields[5]).DisplayFormat:= '###,##0.0000;;'
end;

procedure TdmData.dsQSOBeforeAfterOpen(DataSet: TDataSet);
begin
  TFloatField(qQSOBefore.Fields[5]).DisplayFormat:= '###,##0.0000;;'
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
var
  pq : TSQLQuery;
  tq : TSQLTransaction;
begin
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
      Writeln('DBPing - ',pq.SQL.Text);
      pq.Open;
      pq.Close;
      tq.Rollback;

      pq.DataBase := dmDXCluster.dbDXC;
      tq.DataBase := dmDXCluster.dbDXC;
      pq.Transaction := tq;
      pq.SQL.Text := 'select * from '+fDBName+'.db_version';
      tq.StartTransaction;
      Writeln('DBPing - ',pq.SQL.Text);
      pq.Open;
      pq.Close;
      tq.Rollback
    end
  finally
    pq.Free;
    tq.Free
  end
end;

procedure TdmData.SaveQSO(date : TDateTime; time_on,time_off,call : String; freq : Currency;mode,rst_s,
                 rst_r, stn_name,qth,qsl_s,qsl_r,qsl_via,iota,pwr : String; itu,waz : Integer;
                 loc, my_loc,county,award,remarks : String; adif : Integer;
                 idcall,state,cont : String; qso_dxcc : Boolean; profile : Integer;
                 nclub1,nclub2,nclub3,nclub4,nclub5 : String);
var
  qsodate : String;
  band    : String;
  changed : Integer;
  sWAZ, sITU : String;
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
  qsl_via := copy(qsl_via,1,30);
  award   := copy(award,1,50);
  state   := copy(state,1,4);
  cont    := UpperCase(copy(cont,1,2));
  qth     := copy(qth,1,60);
  trQ.StartTransaction;
  qsodate := (FormatDateTime('YYYY-MM-DD',date));
  Q.SQL.Text :=  'insert into cqrlog_main (qsodate,time_on,time_off,callsign,freq,mode,'+
                 'rst_s,rst_r,name,qth,qsl_s,qsl_r,qsl_via,iota,pwr,itu,waz,loc,my_loc,'+
                 'county,award,remarks,adif,idcall,state,qso_dxcc,band,profile,cont,club_nr1,'+
                 'club_nr2,club_nr3,club_nr4,club_nr5) values('+QuotedStr(qsodate) +
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
                 ','+QuotedStr(loc)+','+QuotedStr(my_loc)+
                 //','+QuotedStr(dmUtils.MyTrim(county))+',' + QuotedStr(dmUtils.MyTrim(award)) + ','+QuotedStr(dmUtils.MyTrim(remarks))+
                 ','+QuotedStr(trim(county))+',' + QuotedStr(trim(award)) + ','+QuotedStr(trim(remarks))+
                 ','+IntToStr(adif)+','+ QuotedStr(idcall) + ','+ QuotedStr(state) +','+IntToStr(changed)+
                 ','+QuotedStr(band)+','+ IntToStr(profile) +','+QuotedStr(cont)+
                 ','+QuotedStr(nclub1)+','+QuotedStr(nclub2)+','+QuotedStr(nclub3)+
                 ','+QuotedStr(nclub4)+','+QuotedStr(nclub5)+')';
  if fDebugLevel >=1 then
    Writeln(Q.SQL.Text);
  Q.ExecSQL;
  trQ.Commit
end;
{
procedure TdmData.EditQSO(date: TDateTime; time_on, time_off, call: String;
  freq: Currency; mode, rst_s, rst_r, stn_name, qth, qsl_s, qsl_r, qsl_via,
  iota, pwr: String; itu, waz: Integer; loc, my_loc, county, award, remarks,
  dxcc_ref, idcall, state, cont: String; qso_dxcc: Boolean; profile: Integer;
  idx: LongInt);
begin

end;
}

procedure TdmData.EditQSO(date : TDateTime; time_on,time_off,call : String; freq : Currency;mode,rst_s,
                 rst_r, stn_name,qth,qsl_s,qsl_r,qsl_via,iota,pwr : String; itu,waz : Integer;
                 loc, my_loc,county,award,remarks : String; adif : Word; idcall,state,cont : String;
                  qso_dxcc : Boolean; profile : Integer; idx : LongInt);
var
  qsodate : String;
  band    : String;
  changed : Integer;
  sWAZ, sITU : String;
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
           ', cont = ' + QuotedStr(cont)+
           ' where id_cqrlog_main = ' + IntToStr(idx);
  if fDebugLevel >=1 then
    Writeln(Q.SQL.Text);
  trQ.StartTransaction;
  Q.ExecSQL;
  trQ.Commit;
  Q.Close;
end;

procedure TdmData.SaveComment(call,text : String);
begin
  text := Trim(text);
  if fDebugLevel >=1 then Writeln('Note:',text);
  if (text = '') then
    exit;
  qComment.Close;
  if trComment.Active then trComment.Rollback;
  trComment.StartTransaction;
  qComment.SQL.Text := 'SELECT id_notes FROM notes WHERE callsign = ' + QuotedStr(call) + ' LIMIT 1';
  qComment.Open;
  if qComment.Fields[0].IsNull then
  begin
    qComment.Close;
    qComment.SQL.Text := 'INSERT INTO notes (callsign,longremarks) VALUES (' + QuotedStr(call) +
                         ',' + QuotedStr(text) + ')';
    if fDebugLevel >=1 then  Writeln(qComment.SQL.Text);
    qComment.ExecSQL;
    trComment.Commit
  end
  else begin
    qComment.Close;
    qComment.SQL.Text := 'UPDATE notes SET longremarks = ' + QuotedStr(text) +
                         ' WHERE callsign = ' + QuotedStr(call);
    if fDebugLevel >=1 then writeln(qComment.SQL.Text);
    qComment.ExecSQL;
    trComment.Commit
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
                QuotedStr('6M')+',50.000,52.000,50.110,50.110,50.120)';
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
                QuotedStr('4MM')+',77500,84000,77500,81000,81000)';
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
    Result := 0
  else
    tmp := copy(text,1,Pos('-',text)-1);
  if NOT TryStrToInt(tmp, Result) then
    Result := 0
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
                ' AND band = ' + QuotedStr(band) + ' AND QSL_R = ' + QuotedStr('Q')+
                ' LIMIT 1';
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
                ' AND band = ' + QuotedStr(band) + ' AND QSL_R = ' + QuotedStr('Q')+
                ' LIMIT 1';
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
  Writeln('GetIOTAForDXCC');
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
var
  tmp    : String;
begin
  tmp := cqrini.ReadString('Clubs','First','');
  Club1.Name     := copy(tmp,1,Pos(';',tmp)-1);
  Club1.LongName := copy(tmp,Pos(';',tmp)+1,Length(tmp)-Pos(';',tmp)+1);
  Club1.NewInfo        := cqrini.ReadString('FirstClub','NewInfo','');
  Club1.NewBandInfo    := cqrini.ReadString('FirstClub','NewBandInfo','');
  Club1.NewModeInfo    := cqrini.ReadString('FirstClub','NewModeInfo','');
  Club1.QSLNeededInfo  := cqrini.ReadString('FirstClub','QSLNeededInfo','');
  Club1.AlreadyCfmInfo := cqrini.ReadString('FirstClub','AlreadyConfirmedInfo','');
  Club1.ClubField      := cqrini.ReadString('FirstClub','ClubFields','');
  Club1.MainFieled     := cqrini.ReadString('FirstClub','MainFields','');
  Club1.StoreField     := cqrini.ReadString('FirstClub','StoreFields','');
  Club1.StoreText      := cqrini.ReadString('FirstClub','StoreText','');
  Club1.NewColor       := cqrini.ReadInteger('FirstClub','NewColor',0);
  Club1.BandColor      := cqrini.ReadInteger('FirstClub','BandColor',0);
  Club1.ModeColor      := cqrini.ReadInteger('FirstClub','ModeColor',0);
  Club1.QSLColor       := cqrini.ReadInteger('FirstClub','QSLColor',0);
  Club1.AlreadyColor   := cqrini.ReadInteger('FirstClub','AlreadyColor',0);
  Club1.DateFrom       := cqrini.ReadString('FirstClub','DateFrom','1945-01-01');

  tmp := cqrini.ReadString('Clubs','Second','');
  Club2.Name     := copy(tmp,1,Pos(';',tmp)-1);
  Club2.LongName := copy(tmp,Pos(';',tmp)+1,Length(tmp)-Pos(';',tmp)+1);
  Club2.NewInfo        := cqrini.ReadString('SecondClub','NewInfo','');
  Club2.NewBandInfo    := cqrini.ReadString('SecondClub','NewBandInfo','');
  Club2.NewModeInfo    := cqrini.ReadString('SecondClub','NewModeInfo','');
  Club2.QSLNeededInfo  := cqrini.ReadString('SecondClub','QSLNeededInfo','');
  Club2.AlreadyCfmInfo := cqrini.ReadString('SecondClub','AlreadyConfirmedInfo','');
  Club2.ClubField      := cqrini.ReadString('SecondClub','ClubFields','');
  Club2.MainFieled     := cqrini.ReadString('SecondClub','MainFields','');
  Club2.StoreField     := cqrini.ReadString('SecondClub','StoreFields','');
  Club2.StoreText      := cqrini.ReadString('SecondClub','StoreText','');
  Club2.NewColor       := cqrini.ReadInteger('SecondClub','NewColor',0);
  Club2.BandColor      := cqrini.ReadInteger('SecondClub','BandColor',0);
  Club2.ModeColor      := cqrini.ReadInteger('SecondClub','ModeColor',0);
  Club2.QSLColor       := cqrini.ReadInteger('SecondClub','QSLColor',0);
  Club2.AlreadyColor   := cqrini.ReadInteger('SecondClub','AlreadyColor',0);
  Club2.DateFrom       := cqrini.ReadString('SecondClub','DateFrom','1945-01-01');

  tmp := cqrini.ReadString('Clubs','Third','');
  Club3.Name     := copy(tmp,1,Pos(';',tmp)-1);
  Club3.LongName := copy(tmp,Pos(';',tmp)+1,Length(tmp)-Pos(';',tmp)+1);
  Club3.NewInfo        := cqrini.ReadString('ThirdClub','NewInfo','');
  Club3.NewBandInfo    := cqrini.ReadString('ThirdClub','NewBandInfo','');
  Club3.NewModeInfo    := cqrini.ReadString('ThirdClub','NewModeInfo','');
  Club3.QSLNeededInfo  := cqrini.ReadString('ThirdClub','QSLNeededInfo','');
  Club3.AlreadyCfmInfo := cqrini.ReadString('ThirdClub','AlreadyConfirmedInfo','');
  Club3.ClubField      := cqrini.ReadString('ThirdClub','ClubFields','');
  Club3.MainFieled     := cqrini.ReadString('ThirdClub','MainFields','');
  Club3.StoreField     := cqrini.ReadString('ThirdClub','StoreFields','');
  Club3.StoreText      := cqrini.ReadString('ThirdClub','StoreText','');
  Club3.NewColor       := cqrini.ReadInteger('ThirdClub','NewColor',0);
  Club3.BandColor      := cqrini.ReadInteger('ThirdClub','BandColor',0);
  Club3.ModeColor      := cqrini.ReadInteger('ThirdClub','ModeColor',0);
  Club3.QSLColor       := cqrini.ReadInteger('ThirdClub','QSLColor',0);
  Club3.AlreadyColor   := cqrini.ReadInteger('ThirdClub','AlreadyColor',0);
  Club3.DateFrom       := cqrini.ReadString('ThirdClub','DateFrom','1945-01-01');

  tmp := cqrini.ReadString('Clubs','Fourth','');
  Club4.Name     := copy(tmp,1,Pos(';',tmp)-1);
  Club4.LongName := copy(tmp,Pos(';',tmp)+1,Length(tmp)-Pos(';',tmp)+1);
  Club4.NewInfo        := cqrini.ReadString('FourthClub','NewInfo','');
  Club4.NewBandInfo    := cqrini.ReadString('FourthClub','NewBandInfo','');
  Club4.NewModeInfo    := cqrini.ReadString('FourthClub','NewModeInfo','');
  Club4.QSLNeededInfo  := cqrini.ReadString('FourthClub','QSLNeededInfo','');
  Club4.AlreadyCfmInfo := cqrini.ReadString('FourthClub','AlreadyConfirmedInfo','');
  Club4.ClubField      := cqrini.ReadString('FourthClub','ClubFields','');
  Club4.MainFieled     := cqrini.ReadString('FourthClub','MainFields','');
  Club4.StoreField     := cqrini.ReadString('FourthClub','StoreFields','');
  Club4.StoreText      := cqrini.ReadString('FourthClub','StoreText','');
  Club4.NewColor       := cqrini.ReadInteger('FourthClub','NewColor',0);
  Club4.BandColor      := cqrini.ReadInteger('FourthClub','BandColor',0);
  Club4.ModeColor      := cqrini.ReadInteger('FourthClub','ModeColor',0);
  Club4.QSLColor       := cqrini.ReadInteger('FourthClub','QSLColor',0);
  Club4.AlreadyColor   := cqrini.ReadInteger('FourthClub','AlreadyColor',0);
  Club4.DateFrom       := cqrini.ReadString('FourthClub','DateFrom','1945-01-01');

  tmp := cqrini.ReadString('Clubs','Fifth','');
  Club5.Name     := copy(tmp,1,Pos(';',tmp)-1);
  Club5.LongName := copy(tmp,Pos(';',tmp)+1,Length(tmp)-Pos(';',tmp)+1);
  Club5.NewInfo        := cqrini.ReadString('FifthClub','NewInfo','');
  Club5.NewBandInfo    := cqrini.ReadString('FifthClub','NewBandInfo','');
  Club5.NewModeInfo    := cqrini.ReadString('FifthClub','NewModeInfo','');
  Club5.QSLNeededInfo  := cqrini.ReadString('FifthClub','QSLNeededInfo','');
  Club5.AlreadyCfmInfo := cqrini.ReadString('FifthClub','AlreadyConfirmedInfo','');
  Club5.ClubField      := cqrini.ReadString('FifthClub','ClubFields','');
  Club5.MainFieled     := cqrini.ReadString('FifthClub','MainFields','');
  Club5.StoreField     := cqrini.ReadString('FifthClub','StoreFields','');
  Club5.StoreText      := cqrini.ReadString('FifthClub','StoreText','');
  Club5.NewColor       := cqrini.ReadInteger('FifthClub','NewColor',0);
  Club5.BandColor      := cqrini.ReadInteger('FifthClub','BandColor',0);
  Club5.ModeColor      := cqrini.ReadInteger('FifthClub','ModeColor',0);
  Club5.QSLColor       := cqrini.ReadInteger('FifthClub','QSLColor',0);
  Club5.AlreadyColor   := cqrini.ReadInteger('FifthClub','AlreadyColor',0);
  Club5.DateFrom       := cqrini.ReadString('FifthClub','DateFrom','1945-01-01');

  if Club1.MainFieled = 'call' then
    Club1.MainFieled := 'idcall';
  if Club2.MainFieled = 'call' then
    Club2.MainFieled := 'idcall';
  if Club3.MainFieled = 'call' then
    Club3.MainFieled := 'idcall';
  if Club4.MainFieled = 'call' then
    Club4.MainFieled := 'idcall';
  if Club5.MainFieled = 'call' then
    Club5.MainFieled := 'idcall'
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
    Writeln('ZipCode: ',ZipCode);
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

function TdmData.ProfileExists(nr : string) : Boolean;
begin
  Q.Close();
  Q.SQL.Text := 'select nr from profiles where nr = '+nr;
  if fDebugLevel >= 1 then Writeln(Q.SQL.Text);
  if trQ.Active then
    trQ.RollBack;
  trQ.StartTransaction;
  Q.Open();
  Result := Q.Fields[0].AsInteger > 0;
  trQ.RollBack;
  Q.Close()
end;

function TdmData.ProfileInUse(nr : String) : Boolean;
begin
  Q.Close();
  Q.SQL.Text := 'select id_cqrlog_main from cqrlog_main where profile = '+nr+' LIMIT 1';
  if fDebugLevel >= 1 then Writeln(Q.SQL.Text);
  if trQ.Active then
    trQ.RollBack;
  trQ.StartTransaction;
  Q.Open();
  Result := Q.Fields[0].AsInteger > 0;
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

{$IFDEF CONTEST}

procedure TdmData.CreateContestDatabase(FileName : String);
begin
  fContestDataFile := FileName+'.fdb';
  ContestDatabase.DatabaseName := fContestDataFile;
  Writeln(ContestDatabase.DatabaseName);
  ContestDatabase.CreateDatabase();
  try
    ContestDataBase.Connected := True;
    dsCQRTest.SQL.Clear;
    trCQRTest.StartTransaction;
    dsCQRTest.SQL.Add('CREATE GENERATOR gid_main;');
    if fDebugLevel>=1 then  Writeln(dsCQRTest.SQL.Text);
    dsCQRTest.ExecSQL;
    trCQRTest.Commit;

    dsCQRTest.SQL.Clear;

    trCQRTest.StartTransaction;
    dsCQRTest.SQL.Add('CREATE TABLE cqrtest (');
    dsCQRTest.SQL.Add('             id_cqrtest INTEGER NOT NULL PRIMARY KEY,');
    dsCQRTest.SQL.Add('             qsodate  VARCHAR(10),');
    dsCQRTest.SQL.Add('             time_on  VARCHAR(5),');
    dsCQRTest.SQL.Add('             qso_nr   INTEGER,');
    dsCQRTest.SQL.Add('             call     VARCHAR(20),');
    dsCQRTest.SQL.Add('             freq     NUMERIC(10,4),');
    dsCQRTest.SQL.Add('             mode     VARCHAR(8),');
    dsCQRTest.SQL.Add('             rst_s    VARCHAR(20),');
    dsCQRTest.SQL.Add('             rst_r    VARCHAR(20),');
    dsCQRTest.SQL.Add('             exch1    VARCHAR(20),');
    dsCQRTest.SQL.Add('             exch2    VARCHAR(20),');
    dsCQRTest.SQL.Add('             mult1    VARCHAR(1),');
    dsCQRTest.SQL.Add('             mult2    VARCHAR(1),');
    dsCQRTest.SQL.Add('             name     VARCHAR(20),');
    dsCQRTest.SQL.Add('             qth      VARCHAR(20),');
    dsCQRTest.SQL.Add('             points   INTEGER,');
    dsCQRTest.SQL.Add('             power    VARCHAR(10),');
    dsCQRTest.SQL.Add('             waz      VARCHAR(2),');
    dsCQRTest.SQL.Add('             itu      VARCHAR(2),');
    dsCQRTest.SQL.Add('             band     VARCHAR(10),');
    dsCQRTest.SQL.Add('             wpx      VARCHAR(20),');
    dsCQRTest.SQL.Add('             state    VARCHAR(20),');
    dsCQRTest.SQL.Add('             iota     VARCHAR(6),');
    dsCQRTest.SQL.Add('             dxcc_ref VARCHAR(20)');
    dsCQRTest.SQL.Add(');');
    if fDebugLevel>=1 then  Writeln(dsCQRTest.SQL.Text);
    dsCQRTest.ExecSQL;
    dsCQRTest.SQL.Clear;

    dsCQRTest.SQL.Add('CREATE TABLE version (');
    dsCQRTest.SQL.Add('       major INTEGER DEFAULT ' + IntToStr(major));
    dsCQRTest.SQL.Add(');');
    if fDebugLevel>=1 then  Writeln(dsCQRTest.SQL.Text);
    dsCQRTest.ExecSQL;
    dsCQRTest.SQL.Clear;

    dsCQRTest.SQL.Add('CREATE INDEX dxcc_ref ON cqrtest (dxcc_ref);');
    if fDebugLevel>=1 then  Writeln(dsCQRTest.SQL.Text);
    dsCQRTest.ExecSQL;
    dsCQRTest.SQL.Clear;
    dsCQRTest.SQL.Add('CREATE INDEX qsodate ON cqrtest (qsodate);');
    if fDebugLevel>=1 then  Writeln(dsCQRTest.SQL.Text);
    dsCQRTest.ExecSQL;
    dsCQRTest.SQL.Clear;
    dsCQRTest.SQL.Add('CREATE INDEX call ON cqrtest (call);');
    if fDebugLevel>=1 then  Writeln(dsCQRTest.SQL.Text);
    dsCQRTest.ExecSQL;
    trCQRTest.Commit;
    dsCQRTest.SQL.Clear;

    trCQRTest.StartTransaction;
    dsCQRTest.SQL.Add('CREATE OR ALTER TRIGGER bi_cqrtest FOR cqrtest');
    dsCQRTest.SQL.Add('ACTIVE BEFORE INSERT');
    dsCQRTest.SQL.Add(' POSITION 0');
    dsCQRTest.SQL.Add('AS');
    dsCQRTest.SQL.Add('BEGIN');
    dsCQRTest.SQL.Add('  if ((new.id_cqrtest is null) or (new.id_cqrtest = 0)) then');
    dsCQRTest.SQL.Add('  BEGIN');
    dsCQRTest.SQL.Add('    new.id_cqrtest = gen_id( gid_main, 1 );');
    dsCQRTest.SQL.Add('  END');
    dsCQRTest.SQL.Add('END');
    if fDebugLevel>=1 then  Writeln(dsCQRTest.SQL.Text);
    dsCQRTest.ExecSQL;
    trCQRTest.Commit;
    dsCQRTest.SQL.Clear
  finally
    ContestDatabase.Connected := False
  end
end;

function TdmData.OpenContestDatabase(FileName : String) : Boolean;
begin
  Result := True;
  try
    fContestDataFile := FileName;
    ContestDatabase.DatabaseName := fContestDataDir + fContestDataFile;
    Writeln(ContestDatabase.DatabaseName);
    ContestDatabase.Connected    := True;
    dsCQRTest.Close;
    dsCQRTest.SQL.Text := 'SELECT * FROM cqrtest ORDER BY qsodate,time_on,id_cqrtest';
    if fDebugLevel>=1 then Writeln(dsCQRTest.SQL.Text);
    dsCQRTest.Open;
    dsCQRTest.Last
  except
    on E : Exception do
    begin
      Application.MessageBox(PChar('Cannot open database!'+#13+E.Message),'Error ...',mb_OK + mb_IconError);
      Result := False
    end
  end
end;

procedure TdmData.DeleteContestQSO(id : LongInt);
begin
  Qc.Close;
  Qc.SQL.Text := 'delete from cqrtest where id_cqrtest = ' + IntToStr(id);
  if fDebugLevel>=1 then Writeln(Qc.SQL.Text);
  trQc.StartTransaction;
  dmData.Qc.ExecSQL;
  trQc.Commit;
  Qc.SQL.Clear
end;
procedure TdmData.SaveContestQSO(date : TDateTime;time_on,call,rst_s,rst_r,exch1,exch2,freq,mode,
                             waz,itu,dxcc_ref : String);
var
  qsodate : String;
  nr : Integer;
  band : String;
  iota : String = '';
  sname : String = '';
  qth  : String = '';
  state : String = '';
  cexch1 : String = '';
  cexch2 : String = '';
begin
  dsCQRTest.Last;
  band := IntToStr(dmUtils.GetBandFromFreq(freq))+'M';
  if waz = '' then
    WAZ := 'null';
  if itu = '' then
    ITU := 'null';
  dsCQRTest.Last;
  nr := dsCQRTest.Fields[3].AsInteger + 1;

  cexch1 := UpperCase(trim(dmData.tstini.ReadString('Details','Exch1','None')));
  cexch2 := UpperCase(trim(dmData.tstini.ReadString('Details','Exch2','None')));

  if cexch1 = 'NONE' then
    exch1 := ''
  else if cexch1 = 'WAZ ZONE' then
    waz := exch1
  else if cexch1 = 'ITU ZONE' then
    itu := exch1
  else if cexch1 = 'IOTA' then
    iota := exch1
  else if cexch1 = 'NAME' then
    sname := exch1
  else if cexch1 = 'QTH' then
    qth := exch1
  else if cexch1 = 'STATE' then
    state := exch1;

  if cexch2 = 'NONE' then
    exch2 := ''
  else if cexch2 = 'WAZ ZONE' then
    waz := exch2
  else if cexch2 = 'ITU ZONE' then
    itu := exch2
  else if cexch2 = 'IOTA' then
    iota := exch2
  else if cexch2 = 'NAME' then
    sname := exch2
  else if cexch2 = 'QTH' then
    qth := exch2
  else if cexch2 = 'STATE' then
    state := exch2;

  trQc.StartTransaction;
  qsodate := (FormatDateTime('YYYY-MM-DD',date));
  //date : TDateTime;time_on,call,rst_s,nr_s,rst_r,nr_r,exch1,exch2,freq,band,mode,waz,itu
  Qc.SQL.Text := 'insert into cqrtest (qsodate,time_on,call,rst_s,rst_r,exch1,exch2,'+
                 'freq,band,mode,waz,itu,dxcc_ref,qso_nr,name,qth,iota,state) values (' + QuotedStr(qsodate) +
                 ',' + QuotedStr(time_on) + ',' + QuotedStr(call) +
                 ',' + QuotedStr(rst_s)+ ',' + QuotedStr(rst_r) +
                 ',' + QuotedStr(exch1) + ',' + QuotedStr(exch2) +
                 ',' + freq + ',' + QuotedStr(band) + ',' + QuotedStr(mode) +
                 ',' + waz + ',' + itu + ',' + QuotedStr(dxcc_ref) + ',' + IntToStr(nr) +
                 ','+QuotedStr(sName) + ','+QuotedStr(qth)+','+QuotedStr(iota)+','+QuotedStr(state)+')';
  if fDebugLevel >=1 then Writeln(Qc.SQL.Text);
  Qc.ExecSQL;
  trQc.Commit
end;

procedure TdmData.EditTestQSO(qsodate,time_on,call,freq,mode,rst_s,rst_r,exch1,exch2,sname,qth,power,
                      waz,itu,wpx,state,iota : String;points : Integer;mult1,mult2 : Boolean;
                      id : LongInt);
var
  m1 : String = '';
  m2 : String = '';
begin
  if mult1 then
    m1 := 'X';
  if mult2 then
    m2 := 'X';
  Qc.Close;
  Qc.SQL.Text := 'update cqrtest set qsodate='+QuotedStr(qsodate)+',time_on='+QuotedStr(time_on)+
                 ',call='+QuotedStr(call)+',freq='+freq+',mode='+QuotedStr(mode)+',rst_s='+QuotedStr(rst_s)+
                 ',rst_r='+QuotedStr(rst_r)+',exch1='+QuotedStr(exch1)+',exch2='+QuotedStr(exch2)+',name='+QuotedStr(sname)+
                 ',qth='+QuotedStr(qth)+',power='+QuotedStr(power)+',waz='+QuotedStr(waz)+',itu='+QuotedStr(itu)+
                 ',wpx='+QuotedStr(wpx)+',state='+QuotedStr(state)+',iota='+QuotedStr(iota)+',points='+IntToStr(points)+
                 ',mult1='+QuotedStr(m1)+',mult2='+QuotedStr(m2) + ' where id_cqrtest = '+IntToStr(id);
  if fDebugLevel>=1 then Writeln(Qc.SQL.Text);
  trQc.StartTransaction;
  Qc.ExecSQL;
  trQc.Commit;
  Qc.Close()
end;

procedure TdmData.GetLastExchange(call : String; var exch : String; var CurPos : TCurPos);
var
  ex1 : Boolean;
  ex2 : Boolean;
  e1 : String = '';
  e2 : String = '';
begin
  exch   := '';
  CurPos := cpEnd;

  e1 := UpperCase(trim(tstini.ReadString('Details','Exch1','None')));
  e2 := UpperCase(trim(tstini.ReadString('Details','Exch2','None')));
  ex1 := (e1 <> 'NONE') and (e1 <> 'QSO NUMBER');
  ex2 := (e2 <> 'NONE') and (e2 <> 'QSO NUMBER');

  if not (ex1 or ex2) then
    exit;
  Qc.Close;
  Qc.SQL.Text := 'select exch1,exch2 from cqrtest where call = '+QuotedStr(call);
  if fDebugLevel>=1 then Writeln(Qc.SQL.Text);
  trQc.StartTransaction;
  Qc.Open();
  if Qc.Fields.AsString[0] <> '' then
  begin
    if ex1 and ex2 then
      exch := Qc.Fields.AsString[0] + ' ' + Qc.Fields.AsString[1]
    else begin
      if ex1 then
        exch := Qc.Fields.AsString[0];
      if ex2 then
      begin
        exch   := ' ' + Qc.Fields.AsString[1];
        CurPos := cpBegin
      end
    end
  end;
  Qc.Close(etmRollback)
end;
{$ENDIF}
procedure TdmData.LoadLoTWCalls;
var
  i : Integer;
  f : TextFile;
  a : String;
begin
  for i:=0 to MaxCall-1 do
    CallArray[i] := '';
  if FileExists(fHomeDir+'lotw1.txt') then
  begin
    AssignFile(f,fHomeDir+'lotw1.txt');
    Reset(f);
    i := 0;
    while not Eof(f) do
    begin
      Readln(f,a);
      CallArray[i] := a;
      inc(i)
    end;
    if fDebugLevel>=1 then Writeln('Loaded ',i,' LoTW users');
    CloseFile(f)
  end;
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
  for i:=0 to MaxCall-1 do
  begin
    if CallArray[i] = '' then
      Break;
    h := Ord(CallArray[i][1]);
    if h = Ord(Call[1]) then
    begin
      if CallArray[i] = call then
      begin
        if fDebugLevel>=1 then Writeln('Nalezeno - '+CallArray[i]);
        Result := True;
        Break
      end
    end
    else begin
      if h > Ord(Call[1]) then
      begin
        if fDebugLevel>=1 then Writeln('NEnalezeno - '+CallArray[i]);
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

function TdmData.GetQSOCount : Integer;
begin
  Result := 0;
  if IsFilter then
    Result := qCQRLOG.RecordCount
  else begin
    Q.Close;
    try
      Q.SQL.Text := 'SELECT COUNT(*) FROM cqrlog_main';
      if trQ.Active then trQ.RollBack;
      trQ.StartTransaction;
      dmData.Q.Open;
      Result := dmData.Q.Fields[0].AsInteger
    finally
      dmData.Q.Close;
      dmData.trQ.RollBack
    end
  end
end;

procedure TdmData.TruncateTables(nr : Word);
var
  db : String;
begin
  db := GetProperDBName(nr);
  Q.Close;
  try
    if trQ.Active then trQ.RollBack;
    trQ.StartTransaction;
    Q.SQL.Text := 'TRUNCATE '+db+'.club1;';
    Q.ExecSQL;
    Q.SQL.Text := 'TRUNCATE '+db+'.club2;';
    Q.ExecSQL;
    Q.SQL.Text := 'TRUNCATE '+db+'.club3;';
    Q.ExecSQL;
    Q.SQL.Text := 'TRUNCATE '+db+'.club4;';
    Q.ExecSQL;
    Q.SQL.Text := 'TRUNCATE '+db+'.club5;';
    Q.ExecSQL;
    Q.SQL.Text := 'TRUNCATE '+db+'.cqrlog_config;';
    Q.ExecSQL;
    Q.SQL.Text := 'TRUNCATE '+db+'.cqrlog_main;';
    Q.ExecSQL;
    Q.SQL.Text := 'TRUNCATE '+db+'.dxcc_id;';
    Q.ExecSQL;
    Q.SQL.Text := 'TRUNCATE '+db+'.long_note;';
    Q.ExecSQL;
    Q.SQL.Text := 'TRUNCATE '+db+'.notes;';
    Q.ExecSQL;
    Q.SQL.Text := 'TRUNCATE '+db+'.profiles;';
    Q.ExecSQL;
    Q.SQL.Text := 'TRUNCATE '+db+'.version;';
    Q.ExecSQL;
    Q.SQL.Text := 'TRUNCATE '+db+'.zipcode1;';
    Q.ExecSQL;
    Q.SQL.Text := 'TRUNCATE '+db+'.zipcode2;';
    Q.ExecSQL;
    Q.SQL.Text := 'TRUNCATE '+db+'.zipcode3;';
    Q.ExecSQL;
    trQ.Commit
  finally
    dmData.Q.Close
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


procedure TdmData.UpdateDatabase(old_version : Integer);
var
  err : Boolean = False;
begin
  if old_version < cDB_MAIN_VER then
  begin
    if trQ1.Active then trQ1.Rollback;
    trQ1.StartTransaction;
    try try
      if old_version < 2 then
      begin
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
        Q1.ExecSQL
      end;

      if old_version < 4 then
      begin
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
        Q1.ExecSQL
      end;

      Q1.SQL.Text := 'drop view view_cqrlog_main_by_callsign';
      if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
      Q1.ExecSQL;
      Q1.SQL.Text := 'drop view view_cqrlog_main_by_qsodate';
      if fDebugLevel>=1 then Writeln(Q1.SQL.Text);
      Q1.ExecSQL;

      CreateViews;

      Q1.SQL.Text := 'update db_version set nr='+IntToStr(cDB_MAIN_VER);
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
  mQ.Close;
  trmQ.StartTransaction;
  mQ.SQL.Text := '';
  for i:=0 to scQSLExport.Script.Count-1 do
  begin
    if Pos(';',scQSLExport.Script.Strings[i]) = 0 then
      mQ.SQL.Add(scQSLExport.Script.Strings[i])
    else begin
      mQ.SQL.Add(scQSLExport.Script.Strings[i]);
      if fDebugLevel>=1 then Writeln(mQ.SQL.Text);
      mQ.ExecSQL;
      mQ.SQL.Text := ''
    end
  end;
  trmQ.Commit
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

initialization
  {$I dData.lrs}

end.

