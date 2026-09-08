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
// Two layers.  The Sql* builders return statement text and nothing else;
// the grid datasets (DX cluster list, band edges in the frequency window,
// valid and deleted entities), the RBN monitor, the DX cluster thread and
// the seed and migration statements in dData keep the cursors they had.
// Above the builders sit the operations for what used to run on dmData.Q,
// on dmData.qBands (three files shared that one) and on dmDXCC.qDXCCRef
// (four files): lookups as values or records, the band rows lent as a
// one-row dataset so the callers read the columns with the types they
// always did, the club import as a batch.
//
// Three cursors.  FRows is the one lent out (OpenXxxRows ... CloseRows);
// FQ serves scalars and writes that commit on their own; FBatch holds a
// batch -- several writes in one transaction the caller ends with
// CommitBatch or RollbackBatch.

unit dSqlRef;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, sqldb, db, uSqlCursor;

type
  // One dxcc_ref row, the columns NewQSO shows for an entity.
  TDxccRefRow = record
    Pref, Cont, Lat, Long, Country, Waz, Itu, Utc : String
  end;

  // One club membership row.
  TClubMember = record
    Nr, Call, FromDate, ToDate : String
  end;

  TdmSqlRef = class(TDataModule)
    procedure DataModuleCreate(Sender : TObject);
  private
    FQ     : TSqlCursor;   // scalars and writes that commit on their own
    FRows  : TSqlCursor;   // lent out by the Open...Rows operations
    FBatch : TSqlCursor;   // several writes in one transaction the caller ends
    function OpenRows(const Sql : String) : TDataSet;
    procedure ExecInBatch(const Sql : String);
    function SqlCountyByZipTable(const Table : Integer; const Zip : String) : String;
  public
    // Wired from TdmData once MainCon exists -- this module is not one of
    // dData's components, so its bulk DataBase assignment does not reach it.
    procedure AttachTo(Connection : TSQLConnection);

    // dxcc_ref lookups (fNewQSO, fEDIExport, dUtils); GetDxccLatLong
    // answers empty strings for an unknown prefix, as the cursor did
    function  GetDxccRefByAdif(const Adif : Integer; out Row : TDxccRefRow) : Boolean;
    procedure GetDxccLatLong(const Pfx : String; out Lat, Long : String);
    function  GetDxccUtc(const Pfx : String; out Utc : String) : Boolean;
    // the whole table for the parser (dDXCC.LoadDXCCRefArray)
    function  OpenDxccRefForParserRows : TDataSet;

    // dxcc_id, the per-log copy rebuilt when a log opens (dData): three
    // statements in one transaction
    procedure RebuildDxccId(const DbName : String);

    // bands (dData, dUtils, fFilter): the row or rows are lent
    function  OpenAllBandsRows : TDataSet;
    function  OpenBandRows(const Band : String) : TDataSet;
    function  OpenBandRangeRows(const Band : String) : TDataSet;
    function  OpenBandModeSegmentRows(const Mode, Band : String) : TDataSet;
    function  OpenBandByFreqRows(const Freq : String) : TDataSet;
    // the two that carry parameters; both report a failure on the console
    // and carry on, as dData did
    procedure SaveBand(const Band : String; const BBegin, BEnd, Cw, Rtty, Ssb, RxOffset, TxOffset : Currency);
    procedure GetBandOffsets(const Freq : Currency; out RxOffset, TxOffset : Currency);

    // iota_list (dData)
    function  GetIotaName(const Iota : String) : String;
    function  OpenIotaForDxccRows(const Pref : String) : TDataSet;

    // zipcode1..3 (dData): Table is 1, 2 or 3.  The ...On form runs the
    // same lookup on a query the caller owns -- the callbook update thread
    // works on a connection of its own and must not touch this module's.
    function  GetCountyByZip(const Table : Integer; const Zip : String) : String;
    function  GetCountyByZipOn(Q : TSQLQuery; const Table : Integer; const Zip : String) : String;

    // club1..5: the import (fLoadClub) clears and refills as one batch,
    // the lookup (fQSODetails) is a record
    procedure ClearClub(const DbNum : String);
    procedure InsertClubMember(const DbNum, ClubNr, Call, FromDate, ToDate : String);
    function  GetClubMember(const ClubTable, ClubField, Value, Date : String; out Member : TClubMember) : Boolean;

    // The batch is the writes marked so above, in one transaction; the
    // caller ends it with one of these.
    procedure CommitBatch;
    procedure RollbackBatch;
    // Every Open...Rows above lends the same cursor; give it back before
    // the next row pass.
    procedure CloseRows;

    // dxcc_ref
    function SqlDxccRefByAdif(const Adif : Integer) : String;
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
    function SqlBandModeSegment(const Mode, Band : String) : String;
    function SqlBandByFreq(const Freq : String) : String;
    function SqlBandsByBegin : String;
    function SqlBandsOnClusterDb : String;
    function SqlBandRange(const Band : String) : String;
    function SqlUpdateBand : String;
    function SqlBandOffsets : String;
    function SqlInsertBand(const Band, BBegin, BEnd, Cw, Rtty, Ssb : String) : String;

    // dxclusters
    function SqlDxClusters : String;
    function SqlDeleteDxCluster(const Id : Integer) : String;
    function SqlUpdateDxCluster(const Description, Address, Port, User, Password : String; const Id : Integer) : String;
    function SqlInsertDxCluster(const Description, Address, Port, User, Password : String) : String;
    function SqlInsertDefaultDxCluster(const Description, Address, Port : String) : String;

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

procedure TdmSqlRef.DataModuleCreate(Sender : TObject);
begin
  FQ     := TSqlCursor.Create(Self);
  FRows  := TSqlCursor.Create(Self);
  FBatch := TSqlCursor.Create(Self)
end;

procedure TdmSqlRef.AttachTo(Connection : TSQLConnection);
begin
  FQ.AttachTo(Connection);
  FRows.AttachTo(Connection);
  FBatch.AttachTo(Connection)
end;

function TdmSqlRef.OpenRows(const Sql : String) : TDataSet;
begin
  FRows.Prepare(Sql);
  FRows.Open;
  Result := FRows.Query
end;

procedure TdmSqlRef.CloseRows;
begin
  FRows.Release
end;

procedure TdmSqlRef.ExecInBatch(const Sql : String);
begin
  FBatch.PrepareNext(Sql);
  FBatch.Exec
end;

procedure TdmSqlRef.CommitBatch;
begin
  FBatch.Commit;
  FBatch.Release
end;

procedure TdmSqlRef.RollbackBatch;
begin
  FBatch.Release
end;

{ dxcc_ref lookups }

function TdmSqlRef.GetDxccRefByAdif(const Adif : Integer; out Row : TDxccRefRow) : Boolean;
begin
  FQ.Prepare(SqlDxccRefByAdif(Adif));
  try
    FQ.Open;
    Result := FQ.Query.RecordCount > 0;
    if Result then
      with FQ.Query do
      begin
        Row.Pref    := FieldByName('pref').AsString;
        Row.Cont    := FieldByName('cont').AsString;
        Row.Lat     := FieldByName('lat').AsString;
        Row.Long    := FieldByName('longit').AsString;
        Row.Country := FieldByName('name').AsString;
        Row.Waz     := FieldByName('waz').AsString;
        Row.Itu     := FieldByName('itu').AsString;
        Row.Utc     := FieldByName('utc').AsString
      end
  finally
    FQ.Release
  end
end;

procedure TdmSqlRef.GetDxccLatLong(const Pfx : String; out Lat, Long : String);
begin
  FQ.Prepare(SqlDxccRefByPrefix(Pfx));
  try
    FQ.Open;
    Lat  := FQ.Query.Fields[4].AsString;
    Long := FQ.Query.Fields[5].AsString
  finally
    FQ.Release
  end
end;

function TdmSqlRef.GetDxccUtc(const Pfx : String; out Utc : String) : Boolean;
begin
  Utc := '';
  FQ.Prepare(SqlDxccUtcOffset(Pfx));
  try
    FQ.Open;
    Result := FQ.Query.RecordCount > 0;
    if Result then
      Utc := FQ.Query.Fields[0].AsString
  finally
    FQ.Release
  end
end;

function TdmSqlRef.OpenDxccRefForParserRows : TDataSet;
begin
  Result := OpenRows(SqlDxccRefForParser)
end;

{ dxcc_id }

procedure TdmSqlRef.RebuildDxccId(const DbName : String);
begin
  FQ.Release;
  try
    FQ.PrepareNext(SqlClearDxccId);
    FQ.Exec;
    FQ.PrepareNext(SqlFillDxccId(DbName));
    FQ.Exec;
    FQ.PrepareNext(SqlUnknownDxccId(DbName));
    FQ.Exec;
    FQ.Commit
  finally
    FQ.Release
  end
end;

{ bands }

function TdmSqlRef.OpenAllBandsRows : TDataSet;
begin
  Result := OpenRows(SqlAllBands)
end;

function TdmSqlRef.OpenBandRows(const Band : String) : TDataSet;
begin
  Result := OpenRows(SqlBand(Band))
end;

function TdmSqlRef.OpenBandRangeRows(const Band : String) : TDataSet;
begin
  Result := OpenRows(SqlBandRange(Band))
end;

function TdmSqlRef.OpenBandModeSegmentRows(const Mode, Band : String) : TDataSet;
begin
  Result := OpenRows(SqlBandModeSegment(Mode, Band))
end;

function TdmSqlRef.OpenBandByFreqRows(const Freq : String) : TDataSet;
begin
  Result := OpenRows(SqlBandByFreq(Freq))
end;

procedure TdmSqlRef.SaveBand(const Band : String; const BBegin, BEnd, Cw, Rtty, Ssb, RxOffset, TxOffset : Currency);
begin
  try
    FQ.Prepare(SqlUpdateBand);
    FQ.Query.Prepare;
    FQ.Query.Params[0].AsCurrency := BBegin;
    FQ.Query.Params[1].AsCurrency := BEnd;
    FQ.Query.Params[2].AsCurrency := Cw;
    FQ.Query.Params[3].AsCurrency := Rtty;
    FQ.Query.Params[4].AsCurrency := Ssb;
    FQ.Query.Params[5].AsCurrency := RxOffset;
    FQ.Query.Params[6].AsCurrency := TxOffset;
    FQ.Query.Params[7].AsString   := Band;
    FQ.ExecAndCommit
  except
    on E : Exception do
      Writeln(E.Message)
  end
end;

procedure TdmSqlRef.GetBandOffsets(const Freq : Currency; out RxOffset, TxOffset : Currency);
begin
  RxOffset := 0;
  TxOffset := 0;
  try try
    FQ.Prepare(SqlBandOffsets);
    FQ.Query.Prepare;
    FQ.Query.Params[0].AsCurrency := Freq;
    FQ.Query.Params[1].AsCurrency := Freq;
    FQ.Open;
    if FQ.Query.RecordCount > 0 then
    begin
      RxOffset := FQ.Query.Fields[0].AsCurrency;
      TxOffset := FQ.Query.Fields[1].AsCurrency
    end
  except
    on E : Exception do
      Writeln(E.Message)
  end
  finally
    FQ.Release
  end
end;

{ iota_list }

function TdmSqlRef.GetIotaName(const Iota : String) : String;
begin
  FQ.Prepare(SqlIotaName(Iota));
  try
    FQ.Open;
    Result := FQ.Query.Fields[0].AsString
  finally
    FQ.Release
  end
end;

function TdmSqlRef.OpenIotaForDxccRows(const Pref : String) : TDataSet;
begin
  Result := OpenRows(SqlIotaForDxcc(Pref))
end;

{ zipcode1..3 }

function TdmSqlRef.SqlCountyByZipTable(const Table : Integer; const Zip : String) : String;
begin
  case Table of
    1 : Result := SqlCountyByZip1(Zip);
    2 : Result := SqlCountyByZip2(Zip);
    else Result := SqlCountyByZip3(Zip)
  end
end;

function TdmSqlRef.GetCountyByZip(const Table : Integer; const Zip : String) : String;
begin
  FQ.Prepare(SqlCountyByZipTable(Table, Zip));
  try
    FQ.Open;
    Result := Trim(FQ.Query.Fields[0].AsString)
  finally
    FQ.Release
  end
end;

function TdmSqlRef.GetCountyByZipOn(Q : TSQLQuery; const Table : Integer; const Zip : String) : String;
begin
  Q.Close;
  Q.SQL.Text := SqlCountyByZipTable(Table, Zip);
  try
    Q.Open;
    Result := Trim(Q.Fields[0].AsString)
  finally
    Q.Close
  end
end;

{ club1..5 }

procedure TdmSqlRef.ClearClub(const DbNum : String);
begin
  ExecInBatch(SqlClearClub(DbNum))
end;

procedure TdmSqlRef.InsertClubMember(const DbNum, ClubNr, Call, FromDate, ToDate : String);
begin
  ExecInBatch(SqlInsertClubMember(DbNum, ClubNr, Call, FromDate, ToDate))
end;

// A row with an empty id and an empty number is "not a member"; the number
// and the callsign come back trimmed, as fQSODetails read them.
function TdmSqlRef.GetClubMember(const ClubTable, ClubField, Value, Date : String; out Member : TClubMember) : Boolean;
begin
  FQ.Prepare(SqlClubMember(ClubTable, ClubField, Value, Date));
  try
    FQ.Open;
    with FQ.Query do
    begin
      Result := not ((Trim(Fields[0].AsString) = '') and (Trim(Fields[1].AsString) = ''));
      Member.Nr       := Trim(Fields[1].AsString);
      Member.Call     := Trim(Fields[2].AsString);
      Member.FromDate := Fields[3].AsString;
      Member.ToDate   := Fields[4].AsString
    end
  finally
    FQ.Release
  end
end;

{ dxcc_ref }

function TdmSqlRef.SqlDxccRefByAdif(const Adif : Integer) : String;
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
  Result := 'select band,b_begin,b_end from cqrlog_common.bands where band='+QuotedStr(Band)
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

// The band edges arrive as SQL number literals in text, the way the band
// table in dData.PrepareBandDatabase spells them.
function TdmSqlRef.SqlInsertBand(const Band, BBegin, BEnd, Cw, Rtty, Ssb : String) : String;
begin
  Result := 'INSERT INTO cqrlog_common.bands (band,b_begin,b_end,cw,rtty,ssb) VALUES (' +
            QuotedStr(Band)+','+BBegin+','+BEnd+','+Cw+','+Rtty+','+Ssb+')'
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

// The three clusters a fresh cqrlog_common starts with; no user/password.
function TdmSqlRef.SqlInsertDefaultDxCluster(const Description, Address, Port : String) : String;
begin
  Result := 'INSERT INTO dxclusters (description,address,port) ' +
            'VALUES ('+QuotedStr(Description) + ',' + QuotedStr(Address) +
            ','+QuotedStr(Port)+')'
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
