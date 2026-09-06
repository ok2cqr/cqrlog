(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

// Import and export: reloading the DXCC, IOTA, QSL manager and club tables
// from files, the DXCC rebuild that follows, matching LoTW and eQSL
// confirmations against the log, ADIF import with its duplicate check,
// removing duplicate QSOs through tempdupes, and the QSO selections the
// ADIF, HTML and EDI exports walk.
//
// Two layers.  The Sql* builders return statement text and nothing else;
// the tables that reload from files (dxcc_ref, iota_list, qslmgr) and the
// LoTW/eQSL matching keep running them on their own cursors and threads.
// Above the builders sit the operations for what used to run on dmData.Q:
// the duplicate check of the ADIF import as a value, the export walks
// and the DXCC rebuild as a lent row cursor, and the writes.
//
// Three cursors.  FRows is the one lent out (OpenXxxRows ... CloseRows);
// FQ serves scalars and writes that commit on their own; FBatch holds a
// batch -- several writes in one transaction the caller ends with
// CommitBatch or RollbackBatch -- so that a scalar asked meanwhile cannot
// roll the batch back by preparing on top of it.  The DXCC rebuild, the
// duplicate removal and the club import are batches, as they were on trQ.

unit dSqlImpExp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, sqldb, db, uSqlCursor;

type
  TdmSqlImpExp = class(TDataModule)
    procedure DataModuleCreate(Sender : TObject);
  private
    FQ     : TSqlCursor;   // scalars and writes that commit on their own
    FRows  : TSqlCursor;   // lent out by the Open...Rows operations
    FBatch : TSqlCursor;   // several writes in one transaction the caller ends
    function OpenRows(const Sql : String) : TDataSet;
  public
    // Wired from TdmData once MainCon exists -- this module is not one of
    // dData's components, so its bulk DataBase assignment does not reach it.
    procedure AttachTo(Connection : TSQLConnection);

    // ADIF import (fAdifImport): is this QSO in the log already
    function ImportedQsoExists(const QsoDate, TimeOn, Call, Band, Mode : String) : Boolean;

    // DXCC rebuild over the whole log (fImportProgress.RegenerateDXCCStat):
    // the rows are lent, the fixes are one batch
    function  OpenQsosForDxccRebuildRows : TDataSet;
    procedure ClearQsoDxcc(const Id : Integer);
    procedure SetQsoDxcc(const Adif : Integer; const Waz, Itu, Cont : String; const Id : Integer);

    // QSL managers: one QSO's qsl_via, committed on its own
    procedure SetQslVia(const QslVia : String; const Id : Integer);

    // duplicate QSOs: the temporary table comes and goes on its own, the
    // three moves between the tables are one batch
    procedure CreateDupesTable;
    procedure CollectUniqueQsos;
    procedure DeleteAllQsos;
    procedure RestoreUniqueQsos;
    procedure DropDupesTable;

    // club membership: the clear and the inserts are one batch
    procedure ClearClubTable(const TableName : String);
    procedure InsertClubMember(const TableName, ClubNr, ClubCall, FromDate, ToDate : String);

    // The batch is the writes marked so above, in one transaction; the
    // caller ends it with one of these.
    procedure CommitBatch;
    procedure RollbackBatch;

    // export walks (fExportProgress, fEDIExport, fSOTAExport)
    function OpenQsosForExportRows(const Ascending : Boolean) : TDataSet;
    function OpenQsosByDateRows : TDataSet;
    function OpenFilteredQsosByDateRows(const GridSql : String) : TDataSet;

    // Every Open...Rows above lends the same cursor; give it back before
    // the next row pass.
    procedure CloseRows;

    // DXCC and IOTA tables (fImportProgress.ImportDXCCTables)
    function SqlClearDxccRef : String;
    function SqlInsertDxccRef(const Pref, CountryName, Cont, Utc, Lat, Longit, Itu, Waz : String; const Adif : Integer) : String;
    function SqlInsertDeletedDxccRef(const Pref, CountryName, Cont, Utc, Lat, Longit, Itu, Waz : String; const Adif : Integer) : String;
    function SqlClearIotaList : String;
    function SqlInsertIota(const IotaNr, IslandName, DxccRef : String) : String;
    function SqlInsertIotaWithPrefix(const IotaNr, IslandName, DxccRef, Pref : String) : String;

    // DXCC rebuild over the whole log
    function SqlQsosForDxccRebuild : String;
    function SqlClearQsoDxcc(const Id : Integer) : String;
    function SqlSetQsoDxcc(const Adif : Integer; const Waz, Itu, Cont : String; const Id : Integer) : String;

    // LoTW and eQSL confirmation import
    function SqlQsoKey(const Call, QsoDate, Band : String) : String;
    function SqlQsosForLotwImport(const Keys : String) : String;
    function SqlQsosForEqslImport(const Keys : String) : String;

    // QSL managers
    function SqlClearQslManagers : String;
    function SqlInsertQslManager : String;
    function SqlSetQslVia(const QslVia : String; const Id : Integer) : String;

    // duplicate QSOs
    function SqlCreateDupesTable : String;
    function SqlCollectUniqueQsos : String;
    function SqlDeleteAllQsos : String;
    function SqlRestoreUniqueQsos : String;
    function SqlDropDupesTable : String;

    // club membership
    function SqlClearClubTable(const TableName : String) : String;
    function SqlInsertClubMemberParams(const TableName : String) : String;

    // ADIF import
    function SqlQsoExists(const QsoDate, TimeOn, Call, Band, Mode : String) : String;
    function SqlInsertImportedQso : String;

    // export
    function SqlQsosForExportAsc : String;
    function SqlQsosForExport : String;
    function SqlQsosByDateForExport : String;
    function SqlFilteredQsosByDate(const GridSql : String) : String;
  end;

var
  dmSqlImpExp : TdmSqlImpExp;

implementation

{$R *.lfm}

procedure TdmSqlImpExp.DataModuleCreate(Sender : TObject);
begin
  FQ     := TSqlCursor.Create(Self);
  FRows  := TSqlCursor.Create(Self);
  FBatch := TSqlCursor.Create(Self)
end;

procedure TdmSqlImpExp.AttachTo(Connection : TSQLConnection);
begin
  FQ.AttachTo(Connection);
  FRows.AttachTo(Connection);
  FBatch.AttachTo(Connection)
end;

function TdmSqlImpExp.OpenRows(const Sql : String) : TDataSet;
begin
  FRows.Prepare(Sql);
  FRows.Open;
  Result := FRows.Query
end;

procedure TdmSqlImpExp.CloseRows;
begin
  FRows.Release
end;

procedure TdmSqlImpExp.CommitBatch;
begin
  FBatch.Commit;
  FBatch.Release
end;

procedure TdmSqlImpExp.RollbackBatch;
begin
  FBatch.Release
end;

{ ADIF import }

function TdmSqlImpExp.ImportedQsoExists(const QsoDate, TimeOn, Call, Band, Mode : String) : Boolean;
begin
  FQ.Prepare(SqlQsoExists(QsoDate, TimeOn, Call, Band, Mode));
  try
    FQ.Open;
    Result := FQ.Query.Fields[0].AsInteger > 0
  finally
    FQ.Release
  end
end;

{ DXCC rebuild }

function TdmSqlImpExp.OpenQsosForDxccRebuildRows : TDataSet;
begin
  Result := OpenRows(SqlQsosForDxccRebuild)
end;

procedure TdmSqlImpExp.ClearQsoDxcc(const Id : Integer);
begin
  FBatch.PrepareNext(SqlClearQsoDxcc(Id));
  FBatch.Exec
end;

procedure TdmSqlImpExp.SetQsoDxcc(const Adif : Integer; const Waz, Itu, Cont : String; const Id : Integer);
begin
  FBatch.PrepareNext(SqlSetQsoDxcc(Adif, Waz, Itu, Cont, Id));
  FBatch.Exec
end;

{ QSL managers }

procedure TdmSqlImpExp.SetQslVia(const QslVia : String; const Id : Integer);
begin
  FQ.Prepare(SqlSetQslVia(QslVia, Id));
  FQ.ExecAndCommit
end;

{ duplicate QSOs }

procedure TdmSqlImpExp.CreateDupesTable;
begin
  FQ.Prepare(SqlCreateDupesTable);
  FQ.ExecAndCommit
end;

procedure TdmSqlImpExp.CollectUniqueQsos;
begin
  FBatch.PrepareNext(SqlCollectUniqueQsos);
  FBatch.Exec
end;

procedure TdmSqlImpExp.DeleteAllQsos;
begin
  FBatch.PrepareNext(SqlDeleteAllQsos);
  FBatch.Exec
end;

procedure TdmSqlImpExp.RestoreUniqueQsos;
begin
  FBatch.PrepareNext(SqlRestoreUniqueQsos);
  FBatch.Exec
end;

procedure TdmSqlImpExp.DropDupesTable;
begin
  FQ.Prepare(SqlDropDupesTable);
  FQ.ExecAndCommit
end;

{ club membership }

procedure TdmSqlImpExp.ClearClubTable(const TableName : String);
begin
  FBatch.PrepareNext(SqlClearClubTable(TableName));
  FBatch.Exec
end;

procedure TdmSqlImpExp.InsertClubMember(const TableName, ClubNr, ClubCall, FromDate, ToDate : String);
begin
  FBatch.PrepareNext(SqlInsertClubMemberParams(TableName));
  FBatch.Query.Prepare;
  FBatch.Query.Params[0].AsString := ClubNr;
  FBatch.Query.Params[1].AsString := ClubCall;
  FBatch.Query.Params[2].AsString := FromDate;
  FBatch.Query.Params[3].AsString := ToDate;
  FBatch.Exec
end;

{ export walks }

function TdmSqlImpExp.OpenQsosForExportRows(const Ascending : Boolean) : TDataSet;
begin
  if Ascending then
    Result := OpenRows(SqlQsosForExportAsc)
  else
    Result := OpenRows(SqlQsosForExport)
end;

function TdmSqlImpExp.OpenQsosByDateRows : TDataSet;
begin
  Result := OpenRows(SqlQsosByDateForExport)
end;

function TdmSqlImpExp.OpenFilteredQsosByDateRows(const GridSql : String) : TDataSet;
begin
  Result := OpenRows(SqlFilteredQsosByDate(GridSql))
end;

{ DXCC and IOTA tables }

function TdmSqlImpExp.SqlClearDxccRef : String;
begin
  Result := 'DELETE FROM cqrlog_common.dxcc_ref'
end;

function TdmSqlImpExp.SqlInsertDxccRef(const Pref, CountryName, Cont, Utc, Lat, Longit, Itu, Waz : String; const Adif : Integer) : String;
begin
  Result := 'INSERT INTO cqrlog_common.dxcc_ref (pref,name,cont,utc,lat,'+
            'longit,itu,waz,adif,deleted) VALUES ('+
            QuotedStr(Pref)+','+ QuotedStr(CountryName)+','+
            QuotedStr(Cont)+','+QuotedStr(Utc)+','+
            QuotedStr(Lat)+','+QuotedStr(Longit)+','+
            QuotedStr(Itu)+','+QuotedStr(Waz)+','+
            IntToStr(Adif)+',0)'
end;

// CountryDel.tab rows: the caller passes the prefix with its '*' suffix,
// deleted = 1.
function TdmSqlImpExp.SqlInsertDeletedDxccRef(const Pref, CountryName, Cont, Utc, Lat, Longit, Itu, Waz : String; const Adif : Integer) : String;
begin
  Result := 'INSERT INTO cqrlog_common.dxcc_ref (pref,name,cont,utc,lat,'+
            'longit,itu,waz,adif,deleted) VALUES ('+
            QuotedStr(Pref)+','+ QuotedStr(CountryName)+','+
            QuotedStr(Cont)+','+QuotedStr(Utc)+','+
            QuotedStr(Lat)+','+QuotedStr(Longit)+','+
            QuotedStr(Itu)+','+QuotedStr(Waz)+','+
            IntToStr(Adif)+','+'1'+')'
end;

function TdmSqlImpExp.SqlClearIotaList : String;
begin
  Result := 'DELETE FROM cqrlog_common.iota_list'
end;

function TdmSqlImpExp.SqlInsertIota(const IotaNr, IslandName, DxccRef : String) : String;
begin
  Result := 'INSERT INTO cqrlog_common.iota_list (iota_nr,island_name,dxcc_ref)'+
            ' VALUES ('+QuotedStr(IotaNr) + ',' +
            QuotedStr(IslandName) + ',' + QuotedStr(DxccRef) + ')'
end;

function TdmSqlImpExp.SqlInsertIotaWithPrefix(const IotaNr, IslandName, DxccRef, Pref : String) : String;
begin
  Result := 'INSERT INTO cqrlog_common.iota_list (iota_nr,island_name,dxcc_ref,pref)'+
            ' VALUES ('+QuotedStr(IotaNr) + ',' +
            QuotedStr(IslandName) + ',' + QuotedStr(DxccRef)
            + ',' + QuotedStr(Pref) + ')'
end;

{ DXCC rebuild }

function TdmSqlImpExp.SqlQsosForDxccRebuild : String;
begin
  Result := 'select id_cqrlog_main,qsodate,callsign,adif,qso_dxcc from cqrlog_main'
end;

function TdmSqlImpExp.SqlClearQsoDxcc(const Id : Integer) : String;
begin
  Result := 'UPDATE cqrlog_main SET adif=0,waz=null,itu=null,cont=null WHERE id_cqrlog_main='+IntToStr(Id)
end;

// Waz and Itu arrive as numbers in text form and go in unquoted, as before.
function TdmSqlImpExp.SqlSetQsoDxcc(const Adif : Integer; const Waz, Itu, Cont : String; const Id : Integer) : String;
begin
  Result := 'UPDATE cqrlog_main SET adif='+IntToStr(Adif)+',waz ='+Waz+',itu ='+Itu+',cont='+QuotedStr(Cont)+' WHERE id_cqrlog_main='+IntToStr(Id)
end;

{ LoTW and eQSL confirmation import }

// One (callsign,qsodate,band) tuple; the caller joins them with commas
// into the IN list of the two selects below.
function TdmSqlImpExp.SqlQsoKey(const Call, QsoDate, Band : String) : String;
begin
  Result := '(' + QuotedStr(Call) + ',' + QuotedStr(QsoDate) + ',' + QuotedStr(Band) + ')'
end;

function TdmSqlImpExp.SqlQsosForLotwImport(const Keys : String) : String;
begin
  Result := 'select callsign,qsodate,band,time_on,mode,lotw_qslr,loc,state,county,id_cqrlog_main '+
            'from cqrlog_main where (callsign,qsodate,band) in (' + Keys + ')'
end;

function TdmSqlImpExp.SqlQsosForEqslImport(const Keys : String) : String;
begin
  Result := 'select callsign,qsodate,band,time_on,mode,eqsl_qsl_rcvd,id_cqrlog_main '+
            'from cqrlog_main where (callsign,qsodate,band) in (' + Keys + ')'
end;

{ QSL managers }

function TdmSqlImpExp.SqlClearQslManagers : String;
begin
  Result := 'delete from cqrlog_common.qslmgr'
end;

function TdmSqlImpExp.SqlInsertQslManager : String;
const
  C_INS = 'INSERT INTO cqrlog_common.qslmgr (callsign,qsl_via,fromdate) VALUES (:callsign,:qsl_via, :fromdate)';
begin
  Result := C_INS
end;

function TdmSqlImpExp.SqlSetQslVia(const QslVia : String; const Id : Integer) : String;
begin
  Result := 'update cqrlog_main set qsl_via = ' + QuotedStr(QslVia) +
            ' where id_cqrlog_main = '+ IntToStr(Id)
end;

{ duplicate QSOs }

function TdmSqlImpExp.SqlCreateDupesTable : String;
begin
  Result := 'create table tempdupes like cqrlog_main'
end;

function TdmSqlImpExp.SqlCollectUniqueQsos : String;
begin
  Result := 'insert into tempdupes ' +
            '  select * from cqrlog_main group by qsodate,time_on,callsign,mode,band'
end;

function TdmSqlImpExp.SqlDeleteAllQsos : String;
begin
  Result := 'delete from cqrlog_main'
end;

function TdmSqlImpExp.SqlRestoreUniqueQsos : String;
begin
  Result := 'insert into cqrlog_main select * from tempdupes'
end;

function TdmSqlImpExp.SqlDropDupesTable : String;
begin
  Result := 'drop table tempdupes'
end;

{ club membership }

function TdmSqlImpExp.SqlClearClubTable(const TableName : String) : String;
begin
  Result := 'TRUNCATE TABLE ' + TableName
end;

function TdmSqlImpExp.SqlInsertClubMemberParams(const TableName : String) : String;
const
  C_INS = 'insert into %s (club_nr,clubcall,fromdate,todate) values (:club_nr, :clubcall, :fromdate, :todate)';
begin
  Result := Format(C_INS, [TableName])
end;

{ ADIF import }

function TdmSqlImpExp.SqlQsoExists(const QsoDate, TimeOn, Call, Band, Mode : String) : String;
begin
  Result := 'SELECT COUNT(*) FROM cqrlog_main WHERE qsodate = ' + QuotedStr(QsoDate) +
            ' AND time_on = ' + QuotedStr(TimeOn) + ' AND callsign = '+QuotedStr(Call)+
            ' AND band = ' + QuotedStr(Band) + ' AND mode = '+QuotedStr(Mode)
end;

function TdmSqlImpExp.SqlInsertImportedQso : String;
begin
  Result := 'insert into cqrlog_main (qsodate,time_on,time_off,callsign,freq,mode,'+
            'rst_s,rst_r,name,qth,qsl_s,qsl_r,qsl_via,iota,pwr,itu,waz,loc,my_loc,'+
            'remarks,county,adif,idcall,award,band,state,cont,profile,lotw_qslsdate,lotw_qsls,'+
            'lotw_qslrdate,lotw_qslr,qsls_date,qslr_date,eqsl_qslsdate,eqsl_qsl_sent,'+
            'eqsl_qslrdate,eqsl_qsl_rcvd, prop_mode, satellite, rxfreq, stx, srx, stx_string,'+
            'srx_string, contestname, dok, operator) values('+
            ':qsodate,:time_on,:time_off,:callsign,:freq,:mode,:rst_s,:rst_r,:name,:qth,'+
            ':qsl_s,:qsl_r,:qsl_via,:iota,:pwr,:itu,:waz,:loc,:my_loc,:remarks,:county,:adif,'+
            ':idcall,:award,:band,:state,:cont,:profile,:lotw_qslsdate,:lotw_qsls,:lotw_qslrdate,'+
            ':lotw_qslr,:qsls_date,:qslr_date,:eqsl_qslsdate,:eqsl_qsl_sent,:eqsl_qslrdate,'+
            ':eqsl_qsl_rcvd, :prop_mode, :satellite, :rxfreq, :stx, :srx, :stx_string, :srx_string,'+
            ':contestname,:dok,:operator)'
end;

{ export }

function TdmSqlImpExp.SqlQsosForExportAsc : String;
begin
  Result := 'SELECT * FROM view_cqrlog_main_by_qsodate_asc'
end;

function TdmSqlImpExp.SqlQsosForExport : String;
begin
  Result := 'SELECT * FROM view_cqrlog_main_by_qsodate'
end;

function TdmSqlImpExp.SqlQsosByDateForExport : String;
begin
  Result := 'select qsodate,time_on,callsign,freq,mode,award,qth,remarks '+
            'from view_cqrlog_main_by_qsodate order by qsodate,time_on'
end;

// The EDI and SOTA exports of a filtered log walk the grid's own statement,
// with whatever ORDER BY it carries replaced by date and time.
function TdmSqlImpExp.SqlFilteredQsosByDate(const GridSql : String) : String;
begin
  Result := GridSql;
  if Pos('order by',LowerCase(Result)) > 0 then
    Result := copy(Result,1,Pos('order by',LowerCase(Result))-1);
  Result := Result + ' order by qsodate,time_on'
end;

end.
