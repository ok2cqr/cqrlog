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
// Builders only.  Every caller still runs these on the cursor it always
// used; this unit says what is asked, not who asks.

unit dSqlImpExp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources;

type
  TdmSqlImpExp = class(TDataModule)
  public
    // DXCC and IOTA tables (fImportProgress.ImportDXCCTables)
    function SqlClearDxccRef : String;
    function SqlInsertDxccRef(const Pref, CountryName, Cont, Utc, Lat, Longit, Itu, Waz : String; const Adif : Integer) : String;
    function SqlInsertDeletedDxccRef(const Pref, CountryName, Cont, Utc, Lat, Longit, Itu, Waz : String; const Adif : Integer) : String;
    function SqlClearIotaList : String;
    function SqlInsertIota(const IotaNr, IslandName, DxccRef : String) : String;
    function SqlInsertIotaWithPrefix(const IotaNr, IslandName, DxccRef, Pref : String) : String;
    function SqlDxccRefAfterImport : String;

    // DXCC rebuild over the whole log
    function SqlQsoCount : String;
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
    function SqlQsosForAdifExportAsc : String;
    function SqlQsosForAdifExport : String;
    function SqlQsosForHtmlExportAsc : String;
    function SqlQsosForHtmlExport : String;
    function SqlQsosForEdiExport : String;
  end;

var
  dmSqlImpExp : TdmSqlImpExp;

implementation

{$R *.lfm}

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

// Same statement as dSqlRef.SqlDxccRefByAdifOrder; fImportProgress reopens
// dDXCC's cursor with it once the tables are reloaded.  Kept separate so
// this extraction leaves the SQL inventory (tools/sql-inventory) untouched;
// the merge pass collapses them.
function TdmSqlImpExp.SqlDxccRefAfterImport : String;
begin
  Result := 'SELECT * FROM cqrlog_common.dxcc_ref ORDER BY adif'
end;

{ DXCC rebuild }

function TdmSqlImpExp.SqlQsoCount : String;
begin
  Result := 'SELECT COUNT(*) FROM cqrlog_main'
end;

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

function TdmSqlImpExp.SqlQsosForAdifExportAsc : String;
begin
  Result := 'SELECT * FROM view_cqrlog_main_by_qsodate_asc'
end;

function TdmSqlImpExp.SqlQsosForAdifExport : String;
begin
  Result := 'SELECT * FROM view_cqrlog_main_by_qsodate'
end;

// Same two statements as the ADIF pair, opened by ExportHTML.  Kept
// separate -- see the note on SqlDxccRefAfterImport.
function TdmSqlImpExp.SqlQsosForHtmlExportAsc : String;
begin
  Result := 'SELECT * FROM view_cqrlog_main_by_qsodate_asc'
end;

function TdmSqlImpExp.SqlQsosForHtmlExport : String;
begin
  Result := 'SELECT * FROM view_cqrlog_main_by_qsodate'
end;

function TdmSqlImpExp.SqlQsosForEdiExport : String;
begin
  Result := 'select qsodate,time_on,callsign,freq,mode,award,qth,remarks '+
            'from view_cqrlog_main_by_qsodate order by qsodate,time_on'
end;

end.
