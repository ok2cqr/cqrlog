(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

// The databases themselves: the log list and version rows in
// cqrlog_common, creating, opening, renaming, clearing and dropping a log
// database, the config blob each log keeps, the information_schema
// probes, and the version-by-version migrations of UpgradeMainDatabase and
// UpgradeCommonDatabase.
//
// Builders only, one per call site (see dSqlStat for why).  The DDL that
// creates a fresh database still lives in dData.lfm (scCommon, scLog,
// scViews) and the CREATE TABLE blocks the upgrades add line by line stay
// as they are -- both are the plan's step 2.  The database name comes in
// as a parameter wherever a statement carries it.

unit dSqlSchema;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources;

type
  TdmSqlSchema = class(TDataModule)
  public
    // cqrlog_common and the log list
    function SqlCommonDbExists : String;
    function SqlInsertCommonVersion(const Nr : Integer) : String;
    function SqlCommonVersion : String;
    function SqlSetCommonVersion(const Nr : Integer) : String;
    function SqlLogList : String;
    function SqlLogListRefresh : String;
    function SqlLogNumbers : String;
    function SqlLogExists(const Nr : Integer) : String;
    function SqlInsertLog(const Nr : Integer; const LogName : String) : String;
    function SqlRenameLog(const LogName : String; const Nr : Integer) : String;
    function SqlDeleteLog(const Nr : Integer) : String;

    // one log database
    function SqlCreateLogDatabase(const Db : String) : String;
    function SqlDropLogDatabase(const Db : String) : String;
    function SqlUseDbSemi(const Db : String) : String;
    function SqlUseDb(const Db : String) : String;
    function SqlUseDbForCluster(const Db : String) : String;
    function SqlUseDbForUpload(const Db : String) : String;
    function SqlUseDbForBandMap(const Db : String) : String;
    function SqlUseDbForRbn(const Db : String) : String;
    function SqlUseDbForTruncate(const Db : String) : String;
    function SqlInsertLogVersion(const Nr : Integer) : String;
    function SqlLogVersion : String;
    function SqlSetLogVersion(const Nr : Integer) : String;

    // the config blob
    function SqlConfig : String;
    function SqlConfigCount(const Db : String) : String;
    function SqlInsertConfig(const Db : String) : String;
    function SqlUpdateConfig(const Db : String) : String;
    function SqlConfigFile(const Db : String) : String;
    function SqlConfigFileForExport(const Db : String) : String;
    function SqlSetConfigFile(const Db : String) : String;
    function SqlSetConfigFileFromImport(const Db : String) : String;

    // clearing a log (TruncateTables)
    function SqlTruncateClub1 : String;
    function SqlTruncateClub2 : String;
    function SqlTruncateClub3 : String;
    function SqlTruncateClub4 : String;
    function SqlTruncateClub5 : String;
    function SqlTruncateConfig : String;
    function SqlDeleteAllQsosForTruncate : String;
    function SqlDeleteUploadStatus : String;
    function SqlDeleteLogChanges : String;
    function SqlTruncateDxccId : String;
    function SqlTruncateLongNote : String;
    function SqlTruncateNotes : String;
    function SqlTruncateProfiles : String;
    function SqlTruncateVersion : String;
    function SqlTruncateZipcode1 : String;
    function SqlTruncateZipcode2 : String;
    function SqlTruncateZipcode3 : String;

    // information_schema and repair
    function SqlTableExists(const Db, TableName : String) : String;
    function SqlFieldExists(const Db, TableName, FieldName : String) : String;
    function SqlConstraintExists(const Db, TableName, ConstraintName : String) : String;
    function SqlShowTriggers(const Db : String) : String;
    function SqlBaseTables(const Db : String) : String;
    function SqlRepairTable(const Db, TableName : String) : String;
    // UpgradeCommonDatabase
    function SqlAddBandRxOffset : String;
    function SqlAddBandTxOffset : String;

    // UpgradeMainDatabase, in the order the versions introduced them
    function SqlAddEqslQslSent : String;
    function SqlAddEqslQslsDate : String;
    function SqlAddEqslQslRcvd : String;
    function SqlAddEqslQslrDate : String;
    function SqlFixNullEqslQslSent : String;
    function SqlFixNullEqslQslRcvd : String;
    function SqlFixNullQslS : String;
    function SqlFixNullQslR : String;
    function SqlFixNullLotwQsls : String;
    function SqlFixNullLotwQslr : String;
    function SqlQslSNotNull : String;
    function SqlQslRNotNull : String;
    function SqlLotwQslsNotNull : String;
    function SqlLotwQslrNotNull : String;
    function SqlEqslQslSentNotNull : String;
    function SqlEqslQslRcvdNotNull : String;
    function SqlQslSWiden : String;
    function SqlModeNotNull : String;
    function SqlAddUpdDeleted : String;
    function SqlIndexCallAlertId : String;
    function SqlIndexCallAlertCallsign : String;
    function SqlLocDefault : String;
    function SqlMyLocDefault : String;
    function SqlModeWiden : String;
    function SqlLogChangesModeWiden : String;
    function SqlLogChangesOldModeWiden : String;
    function SqlCallAlertModeWiden : String;
    function SqlFreqMemModeWiden : String;
    function SqlAddRxFreq : String;
    function SqlAddSatellite : String;
    function SqlAddPropMode : String;
    function SqlAddStx : String;
    function SqlAddSrx : String;
    function SqlAddStxString : String;
    function SqlAddSrxString : String;
    function SqlAddContestName : String;
    function SqlLogChangesCmdWiden : String;
    function SqlAddFreqMemInfo : String;
    function SqlAddDok : String;
    function SqlAddOperator : String;
    function SqlDropLogChangesFk : String;
    function SqlLastLogChangeIdForUpgrade : String;
    function SqlSeedUdpLogStatus(const Max : Integer) : String;
    function SqlCallDateBandIndexExists : String;
    function SqlCreateCallDateBandIndex : String;
    function SqlDropViewByCallsign : String;
    function SqlDropViewByQsodate : String;
    function SqlDropViewByQsodateAsc : String;
  end;

var
  dmSqlSchema : TdmSqlSchema;

implementation

{$R *.lfm}

uses dLogUpload;

{ cqrlog_common and the log list }

// mQ sits on information_schema, hence the bare "tables".
function TdmSqlSchema.SqlCommonDbExists : String;
begin
  Result := 'select * from tables where table_schema = '+
            QuotedStr('cqrlog_common')
end;

function TdmSqlSchema.SqlInsertCommonVersion(const Nr : Integer) : String;
begin
  Result := 'insert into db_version (nr) values('+IntToStr(Nr)+')'
end;

function TdmSqlSchema.SqlCommonVersion : String;
begin
  Result := 'select * from cqrlog_common.db_version'
end;

function TdmSqlSchema.SqlSetCommonVersion(const Nr : Integer) : String;
begin
  Result := 'update cqrlog_common.db_version set nr='+IntToStr(Nr)
end;

function TdmSqlSchema.SqlLogList : String;
begin
  Result := 'SELECT log_nr,log_name FROM cqrlog_common.log_list order by log_nr'
end;

// Same statement as SqlLogList, opened again by RefreshLogList.  Kept
// separate so this extraction leaves the SQL inventory (tools/sql-inventory)
// untouched; the merge pass collapses them.
function TdmSqlSchema.SqlLogListRefresh : String;
begin
  Result := 'SELECT log_nr,log_name FROM cqrlog_common.log_list order by log_nr'
end;

function TdmSqlSchema.SqlLogNumbers : String;
const
  C_SEL = 'select log_nr from cqrlog_common.log_list order by log_nr';
begin
  Result := C_SEL
end;

function TdmSqlSchema.SqlLogExists(const Nr : Integer) : String;
begin
  Result := 'select log_nr from cqrlog_common.log_list where log_nr = '+
            IntToStr(Nr)
end;

function TdmSqlSchema.SqlInsertLog(const Nr : Integer; const LogName : String) : String;
begin
  Result := 'insert into cqrlog_common.log_list (log_nr,log_name) values '+
            '('+IntToStr(Nr)+','+QuotedStr(LogName)+')'
end;

function TdmSqlSchema.SqlRenameLog(const LogName : String; const Nr : Integer) : String;
begin
  Result := 'UPDATE cqrlog_common.log_list SET log_name = '+
            QuotedStr(LogName) + ' where log_nr = '+IntToStr(Nr)
end;

function TdmSqlSchema.SqlDeleteLog(const Nr : Integer) : String;
begin
  Result := 'DELETE FROM cqrlog_common.log_list WHERE log_nr = '+IntToStr(Nr)
end;

{ one log database }

function TdmSqlSchema.SqlCreateLogDatabase(const Db : String) : String;
begin
  Result := 'CREATE DATABASE IF NOT EXISTS '+Db+' DEFAULT CHARACTER SET = '+
            'utf8 DEFAULT COLLATE = utf8_bin;'
end;

function TdmSqlSchema.SqlDropLogDatabase(const Db : String) : String;
begin
  Result := 'DROP DATABASE '+Db
end;

// "use" is issued once per cursor that has its own connection state:
// OpenDatabase switches five of them, TruncateTables its local one.  Six
// copies of one statement, kept separate -- see the note on SqlLogListRefresh.
function TdmSqlSchema.SqlUseDbSemi(const Db : String) : String;
begin
  Result := 'use '+Db+';'
end;

function TdmSqlSchema.SqlUseDb(const Db : String) : String;
begin
  Result := 'use ' + Db
end;

function TdmSqlSchema.SqlUseDbForCluster(const Db : String) : String;
begin
  Result := 'use ' + Db
end;

function TdmSqlSchema.SqlUseDbForUpload(const Db : String) : String;
begin
  Result := 'use ' + Db
end;

function TdmSqlSchema.SqlUseDbForBandMap(const Db : String) : String;
begin
  Result := 'use ' + Db
end;

function TdmSqlSchema.SqlUseDbForRbn(const Db : String) : String;
begin
  Result := 'use ' + Db
end;

function TdmSqlSchema.SqlUseDbForTruncate(const Db : String) : String;
begin
  Result := 'use '+ Db
end;

// Same statement as SqlInsertCommonVersion, run on the log's own db_version.
// Kept separate -- see the note on SqlLogListRefresh.
function TdmSqlSchema.SqlInsertLogVersion(const Nr : Integer) : String;
begin
  Result := 'insert into db_version (nr) values('+IntToStr(Nr)+')'
end;

function TdmSqlSchema.SqlLogVersion : String;
begin
  Result := 'select * from db_version'
end;

function TdmSqlSchema.SqlSetLogVersion(const Nr : Integer) : String;
begin
  Result := 'update db_version set nr='+IntToStr(Nr)
end;

{ the config blob }

function TdmSqlSchema.SqlConfig : String;
begin
  Result := 'SELECT * FROM cqrlog_config'
end;

function TdmSqlSchema.SqlConfigCount(const Db : String) : String;
begin
  Result := 'select count(*) from '+Db+'.cqrlog_config'
end;

function TdmSqlSchema.SqlInsertConfig(const Db : String) : String;
begin
  Result := 'insert into '+Db+'.cqrlog_config (config_file) values(:cnf)'
end;

function TdmSqlSchema.SqlUpdateConfig(const Db : String) : String;
begin
  Result := 'update '+Db+'.cqrlog_config set config_file = :cnf'
end;

// fDBConnect copies a config between logs and exports/imports it as a
// file; the read and the write each appear twice there.
function TdmSqlSchema.SqlConfigFile(const Db : String) : String;
begin
  Result := 'select config_file from '+Db+'.cqrlog_config'
end;

function TdmSqlSchema.SqlConfigFileForExport(const Db : String) : String;
begin
  Result := 'select config_file from '+Db+'.cqrlog_config'
end;

function TdmSqlSchema.SqlSetConfigFile(const Db : String) : String;
begin
  Result := 'update '+Db+'.cqrlog_config set config_file =:config_file'
end;

function TdmSqlSchema.SqlSetConfigFileFromImport(const Db : String) : String;
begin
  Result := 'update '+Db+'.cqrlog_config set config_file =:config_file'
end;

{ clearing a log }

function TdmSqlSchema.SqlTruncateClub1 : String;
begin
  Result := 'TRUNCATE club1;'
end;

function TdmSqlSchema.SqlTruncateClub2 : String;
begin
  Result := 'TRUNCATE club2;'
end;

function TdmSqlSchema.SqlTruncateClub3 : String;
begin
  Result := 'TRUNCATE club3;'
end;

function TdmSqlSchema.SqlTruncateClub4 : String;
begin
  Result := 'TRUNCATE club4;'
end;

function TdmSqlSchema.SqlTruncateClub5 : String;
begin
  Result := 'TRUNCATE club5;'
end;

function TdmSqlSchema.SqlTruncateConfig : String;
begin
  Result := 'TRUNCATE cqrlog_config;'
end;

function TdmSqlSchema.SqlDeleteAllQsosForTruncate : String;
begin
  Result := 'delete from cqrlog_main;'
end;

function TdmSqlSchema.SqlDeleteUploadStatus : String;
begin
  Result := 'delete from upload_status'
end;

function TdmSqlSchema.SqlDeleteLogChanges : String;
begin
  Result := 'delete from log_changes'
end;

function TdmSqlSchema.SqlTruncateDxccId : String;
begin
  Result := 'TRUNCATE dxcc_id;'
end;

function TdmSqlSchema.SqlTruncateLongNote : String;
begin
  Result := 'TRUNCATE long_note;'
end;

function TdmSqlSchema.SqlTruncateNotes : String;
begin
  Result := 'TRUNCATE notes;'
end;

function TdmSqlSchema.SqlTruncateProfiles : String;
begin
  Result := 'TRUNCATE profiles;'
end;

function TdmSqlSchema.SqlTruncateVersion : String;
begin
  Result := 'TRUNCATE version;'
end;

function TdmSqlSchema.SqlTruncateZipcode1 : String;
begin
  Result := 'TRUNCATE zipcode1;'
end;

function TdmSqlSchema.SqlTruncateZipcode2 : String;
begin
  Result := 'TRUNCATE zipcode2;'
end;

function TdmSqlSchema.SqlTruncateZipcode3 : String;
begin
  Result := 'TRUNCATE zipcode3;'
end;

{ information_schema and repair }

function TdmSqlSchema.SqlTableExists(const Db, TableName : String) : String;
const
  C_SEL = 'select table_name from information_schema.tables where table_schema=%s and table_name=%s';
begin
  Result := Format(C_SEL,[QuotedStr(Db),QuotedStr(TableName)])
end;

function TdmSqlSchema.SqlFieldExists(const Db, TableName, FieldName : String) : String;
const
  C_SEL = 'select column_name from information_schema.columns where table_schema=%s and table_name=%s and column_name=%s';
begin
  Result := Format(C_SEL,[QuotedStr(Db),QuotedStr(TableName), QuotedStr(FieldName)])
end;

function TdmSqlSchema.SqlConstraintExists(const Db, TableName, ConstraintName : String) : String;
const
  C_SEL = 'select constraint_name from information_schema.table_constraints where table_schema=%s and table_name=%s and constraint_name=%s';
begin
  Result := Format(C_SEL,[QuotedStr(Db),QuotedStr(TableName), QuotedStr(ConstraintName)])
end;

function TdmSqlSchema.SqlShowTriggers(const Db : String) : String;
const
  C_SEL = 'show triggers from %s';
begin
  Result := Format(C_SEL,[Db])
end;

function TdmSqlSchema.SqlBaseTables(const Db : String) : String;
begin
  Result := 'select table_name from information_schema.tables where  table_schema='+QuotedStr(Db)+' and table_type ='+ QuotedStr('BASE TABLE')
end;

function TdmSqlSchema.SqlRepairTable(const Db, TableName : String) : String;
begin
  Result := 'REPAIR TABLE '+Db+'.'+TableName
end;

{ UpgradeCommonDatabase }

function TdmSqlSchema.SqlAddBandRxOffset : String;
begin
  Result := 'alter table cqrlog_common.bands add rx_offset numeric(10,4) default 0'
end;

function TdmSqlSchema.SqlAddBandTxOffset : String;
begin
  Result := 'alter table cqrlog_common.bands add tx_offset numeric(10,4) default 0'
end;

{ UpgradeMainDatabase }

// version 2: eQSL columns
function TdmSqlSchema.SqlAddEqslQslSent : String;
begin
  Result := 'alter table cqrlog_main add eqsl_qsl_sent varchar(1) null'
end;

function TdmSqlSchema.SqlAddEqslQslsDate : String;
begin
  Result := 'alter table cqrlog_main add eqsl_qslsdate date null'
end;

function TdmSqlSchema.SqlAddEqslQslRcvd : String;
begin
  Result := 'alter table cqrlog_main add eqsl_qsl_rcvd varchar(1) null'
end;

function TdmSqlSchema.SqlAddEqslQslrDate : String;
begin
  Result := 'alter table cqrlog_main add eqsl_qslrdate date null'
end;

// version 4: QSL flags become NOT NULL, after NULLs are turned into ''
function TdmSqlSchema.SqlFixNullEqslQslSent : String;
begin
  Result := 'update cqrlog_main set eqsl_qsl_sent = '+QuotedStr('')+' where eqsl_qsl_sent is null'
end;

function TdmSqlSchema.SqlFixNullEqslQslRcvd : String;
begin
  Result := 'update cqrlog_main set eqsl_qsl_rcvd = '+QuotedStr('')+' where eqsl_qsl_rcvd is null'
end;

function TdmSqlSchema.SqlFixNullQslS : String;
begin
  Result := 'update cqrlog_main set qsl_s = '+QuotedStr('')+' where qsl_s is null'
end;

function TdmSqlSchema.SqlFixNullQslR : String;
begin
  Result := 'update cqrlog_main set qsl_r = '+QuotedStr('')+' where qsl_r is null'
end;

function TdmSqlSchema.SqlFixNullLotwQsls : String;
begin
  Result := 'update cqrlog_main set lotw_qsls = '+QuotedStr('')+' where lotw_qsls is null'
end;

function TdmSqlSchema.SqlFixNullLotwQslr : String;
begin
  Result := 'update cqrlog_main set lotw_qslr = '+QuotedStr('')+' where lotw_qslr is null'
end;

function TdmSqlSchema.SqlQslSNotNull : String;
begin
  Result := 'alter table cqrlog_main change qsl_s qsl_s varchar(3) default '+QuotedStr('')+ 'not null'
end;

function TdmSqlSchema.SqlQslRNotNull : String;
begin
  Result := 'alter table cqrlog_main change qsl_r qsl_r varchar(3) default '+QuotedStr('')+ 'not null'
end;

function TdmSqlSchema.SqlLotwQslsNotNull : String;
begin
  Result := 'alter table cqrlog_main change lotw_qsls lotw_qsls varchar(1) default '+QuotedStr('')+ 'not null'
end;

function TdmSqlSchema.SqlLotwQslrNotNull : String;
begin
  Result := 'alter table cqrlog_main change lotw_qslr lotw_qslr varchar(1) default '+QuotedStr('')+ 'not null'
end;

function TdmSqlSchema.SqlEqslQslSentNotNull : String;
begin
  Result := 'alter table cqrlog_main change eqsl_qsl_sent eqsl_qsl_sent varchar(1) default '+QuotedStr('')+ 'not null'
end;

function TdmSqlSchema.SqlEqslQslRcvdNotNull : String;
begin
  Result := 'alter table cqrlog_main change eqsl_qsl_rcvd eqsl_qsl_rcvd varchar(1) default '+QuotedStr('')+ 'not null'
end;

// version 5
function TdmSqlSchema.SqlQslSWiden : String;
begin
  Result := 'alter table cqrlog_main change qsl_s qsl_s varchar(4) default '+QuotedStr('')+ ' not null'
end;

// version 6
function TdmSqlSchema.SqlModeNotNull : String;
begin
  Result := 'alter table cqrlog_main change mode mode varchar(10) not null'
end;

// version 9
function TdmSqlSchema.SqlAddUpdDeleted : String;
begin
  Result := 'alter table log_changes add upddeleted int(1) default 0'
end;

// version 10
function TdmSqlSchema.SqlIndexCallAlertId : String;
begin
  Result := 'ALTER TABLE call_alert ADD INDEX (id);'
end;

function TdmSqlSchema.SqlIndexCallAlertCallsign : String;
begin
  Result := 'ALTER TABLE call_alert ADD INDEX (callsign);'
end;

// version 12
function TdmSqlSchema.SqlLocDefault : String;
begin
  Result := 'alter table cqrlog_main change loc loc varchar(10) default ' + QuotedStr('')
end;

function TdmSqlSchema.SqlMyLocDefault : String;
begin
  Result := 'alter table cqrlog_main change my_loc my_loc varchar(10) default ' + QuotedStr('')
end;

// version 14: mode columns widen to 12
function TdmSqlSchema.SqlModeWiden : String;
begin
  Result := 'alter table cqrlog_main change mode mode varchar(12) not null'
end;

function TdmSqlSchema.SqlLogChangesModeWiden : String;
begin
  Result := 'alter table log_changes change mode mode varchar(12) null'
end;

function TdmSqlSchema.SqlLogChangesOldModeWiden : String;
begin
  Result := 'alter table log_changes change old_mode old_mode varchar(12) null'
end;

function TdmSqlSchema.SqlCallAlertModeWiden : String;
begin
  Result := 'alter table call_alert change mode mode varchar(12) null'
end;

function TdmSqlSchema.SqlFreqMemModeWiden : String;
begin
  Result := 'alter table freqmem change mode mode varchar(12) null'
end;

// version 15
function TdmSqlSchema.SqlAddRxFreq : String;
begin
  Result := 'alter table cqrlog_main add rxfreq numeric(10,4) null'
end;

function TdmSqlSchema.SqlAddSatellite : String;
begin
  Result := 'alter table cqrlog_main add satellite varchar(30) default '+QuotedStr('')
end;

function TdmSqlSchema.SqlAddPropMode : String;
begin
  Result := 'alter table cqrlog_main add prop_mode varchar(30) default '+QuotedStr('')
end;

// version 16
function TdmSqlSchema.SqlAddStx : String;
begin
  Result := 'alter table cqrlog_main add stx varchar(6) null'
end;

function TdmSqlSchema.SqlAddSrx : String;
begin
  Result := 'alter table cqrlog_main add srx varchar(6) null'
end;

function TdmSqlSchema.SqlAddStxString : String;
begin
  Result := 'alter table cqrlog_main add stx_string varchar(50) null'
end;

function TdmSqlSchema.SqlAddSrxString : String;
begin
  Result := 'alter table cqrlog_main add srx_string varchar(50) null'
end;

function TdmSqlSchema.SqlAddContestName : String;
begin
  Result := 'alter table cqrlog_main add contestname varchar(40) null'
end;

function TdmSqlSchema.SqlLogChangesCmdWiden : String;
begin
  Result := 'alter table log_changes modify cmd varchar(20)'
end;

function TdmSqlSchema.SqlAddFreqMemInfo : String;
begin
  Result := 'alter table freqmem add info varchar(25) null'
end;

// version 17
function TdmSqlSchema.SqlAddDok : String;
begin
  Result := 'alter table cqrlog_main add dok varchar(12) null'
end;

// version 18
function TdmSqlSchema.SqlAddOperator : String;
begin
  Result := 'alter table cqrlog_main add operator varchar(20) null'
end;

// version 19
function TdmSqlSchema.SqlDropLogChangesFk : String;
begin
  Result := 'ALTER TABLE log_changes DROP FOREIGN KEY log_changes_ibfk_1'
end;

// Same statement as dSqlUpload.SqlLastLogChangeId.  Kept separate -- see
// the note on SqlLogListRefresh.
function TdmSqlSchema.SqlLastLogChangeIdForUpgrade : String;
begin
  Result := 'select max(id) from log_changes'
end;

function TdmSqlSchema.SqlSeedUdpLogStatus(const Max : Integer) : String;
begin
  Result := 'insert into upload_status (logname, id_log_changes) values ('+QuotedStr(C_UDPLOG)+','+IntToStr(Max)+')'
end;

// version 20
function TdmSqlSchema.SqlCallDateBandIndexExists : String;
begin
  Result := 'select count(*) from information_schema.statistics where table_schema = database() '+
            'and table_name = ''cqrlog_main'' and index_name = ''callsign_qsodate_band'''
end;

function TdmSqlSchema.SqlCreateCallDateBandIndex : String;
begin
  Result := 'create index callsign_qsodate_band on cqrlog_main (callsign, qsodate, band)'
end;

// every upgrade: the views are dropped and re-created from scViews
function TdmSqlSchema.SqlDropViewByCallsign : String;
begin
  Result := 'drop view view_cqrlog_main_by_callsign'
end;

function TdmSqlSchema.SqlDropViewByQsodate : String;
begin
  Result := 'drop view view_cqrlog_main_by_qsodate'
end;

function TdmSqlSchema.SqlDropViewByQsodateAsc : String;
begin
  Result := 'drop view view_cqrlog_main_by_qsodate_asc'
end;

end.
