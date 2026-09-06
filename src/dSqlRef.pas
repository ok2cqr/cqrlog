(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

// Reference data, mostly in cqrlog_common: the DXCC list and its per-log
// copy dxcc_id, band edges, DX cluster addresses, the IOTA list, the ZIP
// code tables and the club membership tables.
//
// Builders only.  Every caller still runs these on the cursor it always
// used; this unit says what is asked, not who asks.

unit dSqlRef;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources;

type
  TdmSqlRef = class(TDataModule)
  public
    // dxcc_ref
    function SqlDxccRefByAdif(const Adif : Integer) : String;
    function SqlDxccRefByAdifForEdi(const Adif : Integer) : String;
    function SqlDxccRefByPrefix(const Pfx : String) : String;
    function SqlDxccUtcOffset(const Pfx : String) : String;
    function SqlDxccRefByAdifOrder : String;
    function SqlDxccRefForParser : String;
    function SqlValidDxcc : String;
    function SqlDeletedDxcc : String;

    // dxcc_id -- the per-log copy of dxcc_ref
    function SqlClearDxccId : String;
    function SqlFillDxccId(const DbName : String) : String;
    function SqlUnknownDxccId(const DbName : String) : String;

    // bands
    function SqlAllBands : String;
    function SqlBand(const Band : String) : String;
    function SqlBandForRbn(const Band : String) : String;
    function SqlBandModeSegment(const Mode, Band : String) : String;
    function SqlBandByFreq(const Freq : String) : String;
    function SqlBandByFreqForCluster(const Freq : String) : String;
    function SqlBandsByBegin : String;
    function SqlBandsOnClusterDb : String;
    function SqlBandRange(const Band : String) : String;
    function SqlUpdateBand : String;
    function SqlBandOffsets : String;

    // dxclusters
    function SqlDxClusters : String;
    function SqlDeleteDxCluster(const Id : Integer) : String;
    function SqlUpdateDxCluster(const Description, Address, Port, User, Password : String; const Id : Integer) : String;
    function SqlInsertDxCluster(const Description, Address, Port, User, Password : String) : String;

    // iota_list
    function SqlIotaName(const Iota : String) : String;
    function SqlIotaForDxcc(const Pref : String) : String;

    // zipcode1..3
    function SqlCountyByZip1(const Zip : String) : String;
    function SqlCountyByZip2(const Zip : String) : String;
    function SqlCountyByZip3(const Zip : String) : String;

    // club1..5
    function SqlClearClub(const DbNum : String) : String;
    function SqlInsertClubMember(const DbNum, ClubNr, Call, FromDate, ToDate : String) : String;
    function SqlClubMember(const ClubTable, ClubField, Value, Date : String) : String;
  end;

var
  dmSqlRef : TdmSqlRef;

implementation

{$R *.lfm}

{ dxcc_ref }

function TdmSqlRef.SqlDxccRefByAdif(const Adif : Integer) : String;
begin
  Result := 'SELECT * FROM cqrlog_common.dxcc_ref WHERE adif = ' + IntToStr(Adif)
end;

// Same statement as SqlDxccRefByAdif (fNewQSO fills the QSO, fEDIExport the
// header).  Kept separate so this extraction leaves the SQL inventory
// (tools/sql-inventory) untouched; the merge pass collapses them.
function TdmSqlRef.SqlDxccRefByAdifForEdi(const Adif : Integer) : String;
begin
  Result := 'SELECT * FROM cqrlog_common.dxcc_ref WHERE adif = ' + IntToStr(Adif)
end;

function TdmSqlRef.SqlDxccRefByPrefix(const Pfx : String) : String;
begin
  Result := 'SELECT * FROM cqrlog_common.dxcc_ref WHERE pref=' +
    QuotedStr(Pfx)
end;

function TdmSqlRef.SqlDxccUtcOffset(const Pfx : String) : String;
begin
  Result := 'SELECT utc FROM cqrlog_common.dxcc_ref WHERE pref = ' +
    QuotedStr(Pfx)
end;

function TdmSqlRef.SqlDxccRefByAdifOrder : String;
begin
  Result := 'SELECT * FROM cqrlog_common.dxcc_ref ORDER BY adif'
end;

// Spelled with ORDER BY ADIF in dDXCC.LoadDxccRefTables; the inventory
// keeps case, so this is its own statement there.
function TdmSqlRef.SqlDxccRefForParser : String;
begin
  Result := 'SELECT * FROM cqrlog_common.dxcc_ref ORDER BY ADIF'
end;

function TdmSqlRef.SqlValidDxcc : String;
begin
  Result := 'SELECT * FROM cqrlog_common.dxcc_ref WHERE deleted = 0 ORDER BY pref'
end;

function TdmSqlRef.SqlDeletedDxcc : String;
begin
  Result := 'SELECT * FROM cqrlog_common.dxcc_ref WHERE deleted = 1 ORDER BY pref'
end;

{ dxcc_id }

function TdmSqlRef.SqlClearDxccId : String;
begin
  Result := 'truncate table dxcc_id'
end;

function TdmSqlRef.SqlFillDxccId(const DbName : String) : String;
begin
  Result := 'insert into '+DbName+'.dxcc_id select id_dxcc_ref,adif,pref,name from cqrlog_common.dxcc_ref'
end;

function TdmSqlRef.SqlUnknownDxccId(const DbName : String) : String;
begin
  Result := 'insert into '+DbName+'.dxcc_id (adif,dxcc_ref,country) values (0,'+QuotedStr('!')+','+
            QuotedStr('Unknown country')+')'
end;

{ bands }

function TdmSqlRef.SqlAllBands : String;
begin
  Result := 'SELECT * FROM cqrlog_common.bands '
end;

function TdmSqlRef.SqlBand(const Band : String) : String;
begin
  Result := 'SELECT * FROM cqrlog_common.bands WHERE band = ' +
    QuotedStr(Band)
end;

// Same statement as SqlBand -- see the note on SqlDxccRefByAdifForEdi.
function TdmSqlRef.SqlBandForRbn(const Band : String) : String;
begin
  Result := 'SELECT * FROM cqrlog_common.bands WHERE band = ' + QuotedStr(Band)
end;

// Mode is a column name here: cw, ssb or rtty, the start of that segment.
function TdmSqlRef.SqlBandModeSegment(const Mode, Band : String) : String;
begin
  Result := 'SELECT '+Mode+' FROM cqrlog_common.bands WHERE band = ' + QuotedStr(Band)
end;

function TdmSqlRef.SqlBandByFreq(const Freq : String) : String;
begin
  Result := 'SELECT * FROM cqrlog_common.bands where (b_begin <='+Freq+' AND b_end >='+
            Freq+') ORDER BY b_begin'
end;

// Same statement as SqlBandByFreq, run by dDXCluster on its own connection.
// Kept separate -- see the note on SqlDxccRefByAdifForEdi.
function TdmSqlRef.SqlBandByFreqForCluster(const Freq : String) : String;
begin
  Result := 'SELECT * FROM cqrlog_common.bands where (b_begin <='+Freq+' AND b_end >='+
            Freq+') ORDER BY b_begin'
end;

function TdmSqlRef.SqlBandsByBegin : String;
begin
  Result := 'SELECT * FROM cqrlog_common.bands ORDER BY b_begin'
end;

// dDXCluster's cursors sit on dbDXC, whose default database is
// cqrlog_common, hence the unqualified table.
function TdmSqlRef.SqlBandsOnClusterDb : String;
begin
  Result := 'SELECT * FROM bands ORDER BY b_begin'
end;

function TdmSqlRef.SqlBandRange(const Band : String) : String;
begin
  Result := 'select band,b_begin,b_end from cqrlog_common.bands where band="'+Band+'"'
end;

function TdmSqlRef.SqlUpdateBand : String;
const
  C_UPD = 'update cqrlog_common.bands set b_begin = :b_begin, b_end = :b_end, cw = :cw, rtty = :rtty, '+
          'ssb = :ssb, rx_offset = :rx_offset, tx_offset = :tx_offset where band = :band';
begin
  Result := C_UPD
end;

function TdmSqlRef.SqlBandOffsets : String;
const
  C_SEL = 'select rx_offset, tx_offset from cqrlog_common.bands where b_begin <= :b_begin '+
          'and b_end >= :b_end';
begin
  Result := C_SEL
end;

{ dxclusters }

function TdmSqlRef.SqlDxClusters : String;
begin
  Result := 'select * from cqrlog_common.dxclusters order by description'
end;

function TdmSqlRef.SqlDeleteDxCluster(const Id : Integer) : String;
begin
  Result := 'delete from cqrlog_common.dxclusters where id_dxclusters = ' + IntToStr(Id)
end;

function TdmSqlRef.SqlUpdateDxCluster(const Description, Address, Port, User, Password : String; const Id : Integer) : String;
begin
  Result := 'UPDATE cqrlog_common.dxclusters SET description='+QuotedStr(Description)+
            ',address='+QuotedStr(Address)+
            ',port='+QuotedStr(Port)+
            ',dxcuser='+QuotedStr(User)+
            ',dxcpass='+QuotedStr(Password)+
            ' WHERE id_dxclusters = '+IntToStr(Id)
end;

function TdmSqlRef.SqlInsertDxCluster(const Description, Address, Port, User, Password : String) : String;
begin
  Result := 'INSERT INTO cqrlog_common.dxclusters (description,address,port,dxcuser,dxcpass) ' +
            'values ('+QuotedStr(Description) + ',' + QuotedStr(Address) +
            ','+QuotedStr(Port)+','+QuotedStr(User)+
            ','+QuotedStr(Password)+')'
end;

{ iota_list }

function TdmSqlRef.SqlIotaName(const Iota : String) : String;
begin
  Result := 'SELECT island_name FROM cqrlog_common.iota_list WHERE iota_nr = ' +
            QuotedStr(Iota)
end;

function TdmSqlRef.SqlIotaForDxcc(const Pref : String) : String;
begin
  Result := 'SELECT iota_nr,pref FROM cqrlog_common.iota_list WHERE dxcc_ref = ' + QuotedStr(Pref) +
            ' ORDER BY iota_nr'
end;

{ zipcode1..3 }

function TdmSqlRef.SqlCountyByZip1(const Zip : String) : String;
begin
  Result := 'SELECT county from zipcode1 where zip = '+QuotedStr(Zip)
end;

function TdmSqlRef.SqlCountyByZip2(const Zip : String) : String;
begin
  Result := 'SELECT county from zipcode2 where zip = '+QuotedStr(Zip)
end;

function TdmSqlRef.SqlCountyByZip3(const Zip : String) : String;
begin
  Result := 'SELECT county from zipcode3 where zip = '+QuotedStr(Zip)
end;

{ club1..5 }

function TdmSqlRef.SqlClearClub(const DbNum : String) : String;
begin
  Result := 'TRUNCATE TABLE club'+DbNum
end;

function TdmSqlRef.SqlInsertClubMember(const DbNum, ClubNr, Call, FromDate, ToDate : String) : String;
begin
  Result := 'INSERT INTO club'+DbNum+' (club_nr,clubcall,fromdate,todate) '+
            'VALUES ('+QuotedStr(ClubNr)+','+QuotedStr(Call)+','+QuotedStr(FromDate)+','+
            QuotedStr(ToDate)+')'
end;

// Is Value a member of the club on Date?  ClubField is the column the club
// definition says to match (call or number).
function TdmSqlRef.SqlClubMember(const ClubTable, ClubField, Value, Date : String) : String;
begin
  Result := 'select * from '+ClubTable+ ' where '+ ClubField +
            ' = ' + QuotedStr(Value) + ' and fromdate <= ' + QuotedStr(Date) +
            ' and todate >= '+QuotedStr(Date)
end;

end.
