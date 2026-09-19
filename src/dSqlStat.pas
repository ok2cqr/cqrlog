(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

// Statistics and awards: the DXCC counts and "is this a new one" probes,
// the per-band grids of the DXCC, WAZ, ITU, WAC, WAS, DOK and IOTA windows,
// the locator, county and worked-grids maps and the custom statistic.
//
// Two layers.  The Sql* builders return statement text and nothing else;
// the statistics compose their WHERE clauses from window state
// (confirmation type, mode, band, deleted entities), that composition
// stays in the forms, and a builder takes the composed condition as a
// string and wraps the statement around it.
//
// Above the builders sit the operations, which run that text on this
// module's own cursors.  A scalar (a count, a "does this QSO exist") comes
// back as a value.  A row pass lends the module's row cursor: OpenXxxRows
// opens the statement and returns the dataset, the window walks it with
// Fields[...] as before, CloseRows gives it back.  The locator and county pages
// get their rows copied into an array instead, one grouped statement for
// the whole page.
//
// The two cursors: FRows is the one lent out, FQ serves scalars, list
// fills and writes.  A scalar called from inside a borrowed row pass must
// not close the dataset the caller is still reading, hence the split; a
// row pass must never be opened while another is borrowed.

unit dSqlStat;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, sqldb, db, uSqlCursor;

type
  // What the log says about an entity on a band and mode, strongest claim
  // first: confirmed there; worked there but not confirmed; worked on the
  // band in another mode; worked on another band; never worked.
  TDxccStatus = (dsConfirmed, dsQslNeeded, dsNewMode, dsNewBand, dsNewCountry);

  // A county row of the county window (fCountyStat).
  TCountyQsoCount = record
    County : String;
    Wkd    : Integer;
    Cfm    : Integer;
  end;
  TCountyQsoCounts = array of TCountyQsoCount;

  // A worked square of the locator window (fBigSquareStat).
  TSquareStatus = record
    Square : String;
    Cfm    : Boolean;
  end;
  TSquareStatuses = array of TSquareStatus;

  TdmSqlStat = class(TDataModule)
    procedure DataModuleCreate(Sender : TObject);
  private
    FQ    : TSqlCursor;   // scalars, list fills, writes
    FRows : TSqlCursor;   // lent out by the Open...Rows operations
    function  OpenRows(const Sql : String) : TDataSet;
    function  GetValue(const Sql : String) : Integer;
    function  GetRowCount(const Sql : String) : Integer;
    function  QsoExists(const Sql : String) : Boolean;
  public
    // Wired from TdmData once MainCon exists -- this module is not one of
    // dData's components, so its bulk DataBase assignment does not reach it.
    procedure AttachTo(Connection : TSQLConnection);

    // DXCC counts and probes (dDXCC)
    // DeletedList is the "(adif<>..) and .." list to leave out, or empty
    // to count deleted entities too.
    function GetDxccCount(const DeletedList : String) : Integer;
    function GetDxccCfmCount(const Where : String) : Integer;
    function GetDxccStatus(const Adif : Word; const Band, Mode : String; const IncLotw : Boolean) : TDxccStatus;

    // worked/confirmed grid in NewQSO (dUtils)
    function OpenCfmBandsModesRows(const Adif : Integer; const CallCond : String; const IncLotw : Boolean) : TDataSet;
    function OpenWorkedBandsModesRows(const Adif : Integer; const CallCond : String) : TDataSet;

    // IOTA window (fIOTAStat)
    function OpenIotaListRows(const Where : String) : TDataSet;
    function GetIotaCount(const Where : String) : Integer;

    // DXCC statistics window (fDXCCStat)
    // ModeCond empty means all modes; DeletedList is read only when
    // ShowDeleted is False.
    function GetDistinctDxccCount(const Where : String) : Integer;
    function OpenDxccPerBandRows(const ShowDeleted : Boolean; const DeletedList, ModeCond : String) : TDataSet;
    function OpenDxccCfmPerBandRows(const CfmCond : String; const ShowDeleted : Boolean; const DeletedList, ModeCond : String) : TDataSet;
    function OpenDxccStatRows(const ShowDeleted : Boolean) : TDataSet;

    // WAZ / ITU / WAC / WAS window (fWAZITUStat); ModeCond empty = all modes
    function OpenWazStatRows(const Where : String) : TDataSet;
    function OpenItuStatRows(const Where : String) : TDataSet;
    function OpenWacStatRows(const Where : String) : TDataSet;
    function OpenWasStatRows(const Where : String) : TDataSet;
    function OpenWazStationsRows(const CfmCond, ModeCond : String) : TDataSet;
    function OpenItuStationsRows(const CfmCond, ModeCond : String) : TDataSet;
    function OpenWacStationsRows(const CfmCond, ModeCond : String) : TDataSet;
    function OpenWasStationsRows(const CfmCond, ModeCond : String) : TDataSet;

    // DOK window (fDOKStat)
    function OpenDokStationsRows(const CfmCond, ModeCond : String) : TDataSet;
    function OpenDoksWorkedRows : TDataSet;
    function OpenDokStatRows(const Where : String) : TDataSet;

    // big square / locator window (fBigSquareStat) and county window
    // (fCountyStat); one grouped statement per page, the rows come back
    // as arrays
    procedure DropStatView(const TableName : String);
    procedure CreateStatView(const TableName, FilterSql : String);
    function  CountBigSquaresWorked(const TableName : String) : Integer;
    function  CountSquaresWorked(const TableName : String) : Integer;
    function  ListSquareStatuses(const TableName, BandCond, CfmCond : String) : TSquareStatuses;
    function  CountCountiesWorked(const TableName : String) : Integer;
    function  ListCountyQsoCounts(const TableName, BandCond, CfmCond : String) : TCountyQsoCounts;

    // Every Open...Rows above lends the same cursor; give it back before
    // the next row pass.
    procedure CloseRows;

    // DXCC counts and probes (dDXCC)
    function SqlDxccCount : String;
    function SqlDxccCountExcluding(const DeletedList : String) : String;
    function SqlDxccCfmCount(const Where : String) : String;
    function SqlQsoCfmOnBandModeIncLotw(const Adif, Band, Mode : String) : String;
    function SqlQsoCfmOnBandMode(const Adif, Band, Mode : String) : String;
    function SqlQsoOnBandMode(const Adif, Band, Mode : String) : String;
    function SqlQsoOnBand(const Adif, Band : String) : String;
    function SqlQsoWithDxcc(const Adif : String) : String;

    // worked/confirmed grid in NewQSO and the contest list (dUtils)
    function SqlCfmBandsModesIncLotw(const Adif : Integer; const CallCond : String) : String;
    function SqlCfmBandsModes(const Adif : Integer; const CallCond : String) : String;
    function SqlWorkedBandsModes(const Adif : Integer; const CallCond : String) : String;
    function SqlSetCharacterSetUtf8 : String;
    function SqlWorkedContests : String;

    // small windows
    function SqlQsoCountPerMode : String;
    function SqlCustomStat(const Field, Where : String) : String;
    function SqlIotaList(const Where : String) : String;
    function SqlIotaCount(const Where : String) : String;
    // DXCC statistics window (fDXCCStat)
    function SqlDistinctDxccCount(const Where : String) : String;
    function SqlDxccPerBand : String;
    function SqlDxccPerBandExcluding(const DeletedList : String) : String;
    function SqlDxccPerBandByMode(const ModeCond : String) : String;
    function SqlDxccPerBandByModeExcluding(const DeletedList, ModeCond : String) : String;
    function SqlDxccCfmPerBand(const CfmCond : String) : String;
    function SqlDxccCfmPerBandExcluding(const CfmCond, DeletedList : String) : String;
    function SqlDxccCfmPerBandByMode(const CfmCond, ModeCond : String) : String;
    function SqlDxccCfmPerBandByModeExcluding(const CfmCond, DeletedList, ModeCond : String) : String;
    function SqlDxccStatRows : String;
    function SqlDxccStatRowsNoDeleted : String;

    // WAZ / ITU / WAC / WAS window (fWAZITUStat)
    function SqlWazStat(const Where : String) : String;
    function SqlItuStat(const Where : String) : String;
    function SqlWacStat(const Where : String) : String;
    function SqlWasStat(const Where : String) : String;
    function SqlWazStations(const CfmCond : String) : String;
    function SqlWazStationsByMode(const CfmCond, ModeCond : String) : String;
    function SqlItuStations(const CfmCond : String) : String;
    function SqlItuStationsByMode(const CfmCond, ModeCond : String) : String;
    function SqlWacStations(const CfmCond : String) : String;
    function SqlWacStationsByMode(const CfmCond, ModeCond : String) : String;
    function SqlWasStations(const CfmCond : String) : String;
    function SqlWasStationsByMode(const CfmCond, ModeCond : String) : String;
    // DOK window (fDOKStat)
    function SqlDokStations(const CfmCond : String) : String;
    function SqlDokStationsByMode(const CfmCond, ModeCond : String) : String;
    function SqlDoksWorked : String;
    function SqlDokStat(const Where : String) : String;

    // big square / locator window (fBigSquareStat)
    function SqlDropStatView(const TableName : String) : String;
    function SqlCreateStatView(const TableName, FilterSql : String) : String;
    function SqlBigSquaresWorked(const TableName : String) : String;
    function SqlSquaresWorked(const TableName : String) : String;
    function SqlSquareStatuses(const TableName, BandCond, CfmCond : String) : String;

    // county window (fCountyStat)
    function SqlCountiesWorked(const TableName : String) : String;
    function SqlCountyQsoCounts(const TableName, BandCond, CfmCond : String) : String;

    // worked grids map (fWorkedGrids)
    function SqlQsoCountIn(const LogTable : String) : String;
    function SqlWkdMainGrid(const LogTable, L2, Band, Mode, DayLimit : String) : String;
    function SqlWkdGrid(const LogTable, L4, L2, Band, Mode, DayLimit : String) : String;
    function SqlWkdCall(const LogTable, Call, Band, Mode, DayLimit : String) : String;
    function SqlWkdState(const LogTable, State, Band, Mode, DayLimit : String) : String;
    function SqlWkdSquaresOnBand(const LogTable, Band, ModeTail : String) : String;
    function SqlWkdSquares(const LogTable, ModeTail : String) : String;
    function SqlWkdSquareCounts(const FromClause, DayLimit : String) : String;
    function SqlWkdQsoCounts(const DayLimit, BandCond : String) : String;

    // "new one" probes for a spot, on the log's own database (dDXCluster and
    // dData.RbnMonDXCCInfo share them; the same ladder as
    // SqlQsoCfmOnBandModeIncLotw above, with the database name spelled out)
    function SqlSpotQsoCfmOnBandModeIncLotw(const DbName, Adif, Band, Mode : String) : String;
    function SqlSpotQsoCfmOnBandMode(const DbName, Adif, Band, Mode : String) : String;
    function SqlSpotQsoOnBandMode(const DbName, Adif, Band, Mode : String) : String;
    function SqlSpotQsoOnBand(const DbName, Adif, Band : String) : String;
    function SqlSpotQsoWithDxcc(const DbName, Adif : String) : String;
    function SqlRbnQsoCfmOnBandModeIncLotw(const DbName, Adif, Band, Mode : String) : String;
  end;

var
  dmSqlStat : TdmSqlStat;

implementation

{$R *.lfm}

procedure TdmSqlStat.DataModuleCreate(Sender : TObject);
begin
  FQ    := TSqlCursor.Create(Self);
  FRows := TSqlCursor.Create(Self)
end;

procedure TdmSqlStat.AttachTo(Connection : TSQLConnection);
begin
  FQ.AttachTo(Connection);
  FRows.AttachTo(Connection)
end;

{ the four shapes every operation below takes }

function TdmSqlStat.OpenRows(const Sql : String) : TDataSet;
begin
  FRows.Prepare(Sql);
  FRows.Open;
  Result := FRows.Query
end;

procedure TdmSqlStat.CloseRows;
begin
  FRows.Release
end;

// The first column of the single row the statement returns.
function TdmSqlStat.GetValue(const Sql : String) : Integer;
begin
  FQ.Prepare(Sql);
  try
    FQ.Open;
    Result := FQ.Query.Fields[0].AsInteger
  finally
    FQ.Release
  end
end;

// How many rows the statement returns; Last, because a TSQLQuery only
// counts what it has fetched.
function TdmSqlStat.GetRowCount(const Sql : String) : Integer;
begin
  FQ.Prepare(Sql);
  try
    FQ.Open;
    FQ.Query.Last;
    Result := FQ.Query.RecordCount
  finally
    FQ.Release
  end
end;

// The "LIMIT 1" probes: a row means yes.  An empty result reads as 0 --
// AsInteger of a field with no current record -- as the callers always
// tested it.
function TdmSqlStat.QsoExists(const Sql : String) : Boolean;
begin
  Result := GetValue(Sql) > 0
end;

{ DXCC counts and probes (dDXCC) }

function TdmSqlStat.GetDxccCount(const DeletedList : String) : Integer;
begin
  if DeletedList = '' then
    Result := GetValue(SqlDxccCount)
  else
    Result := GetValue(SqlDxccCountExcluding(DeletedList))
end;

function TdmSqlStat.GetDxccCfmCount(const Where : String) : Integer;
begin
  Result := GetValue(SqlDxccCfmCount(Where))
end;

function TdmSqlStat.GetDxccStatus(const Adif : Word; const Band, Mode : String; const IncLotw : Boolean) : TDxccStatus;
var
  sAdif : String;
  cfm   : String;
begin
  sAdif := IntToStr(Adif);
  if IncLotw then
    cfm := SqlQsoCfmOnBandModeIncLotw(sAdif, Band, Mode)
  else
    cfm := SqlQsoCfmOnBandMode(sAdif, Band, Mode);
  if QsoExists(cfm) then
    Result := dsConfirmed
  else if QsoExists(SqlQsoOnBandMode(sAdif, Band, Mode)) then
    Result := dsQslNeeded
  else if QsoExists(SqlQsoOnBand(sAdif, Band)) then
    Result := dsNewMode
  else if QsoExists(SqlQsoWithDxcc(sAdif)) then
    Result := dsNewBand
  else
    Result := dsNewCountry
end;

{ worked/confirmed grid in NewQSO (dUtils) }

function TdmSqlStat.OpenCfmBandsModesRows(const Adif : Integer; const CallCond : String; const IncLotw : Boolean) : TDataSet;
begin
  if IncLotw then
    Result := OpenRows(SqlCfmBandsModesIncLotw(Adif, CallCond))
  else
    Result := OpenRows(SqlCfmBandsModes(Adif, CallCond))
end;

function TdmSqlStat.OpenWorkedBandsModesRows(const Adif : Integer; const CallCond : String) : TDataSet;
begin
  Result := OpenRows(SqlWorkedBandsModes(Adif, CallCond))
end;

{ IOTA window }

function TdmSqlStat.OpenIotaListRows(const Where : String) : TDataSet;
begin
  Result := OpenRows(SqlIotaList(Where))
end;

function TdmSqlStat.GetIotaCount(const Where : String) : Integer;
begin
  Result := GetValue(SqlIotaCount(Where))
end;

{ DXCC statistics window }

function TdmSqlStat.GetDistinctDxccCount(const Where : String) : Integer;
begin
  Result := GetValue(SqlDistinctDxccCount(Where))
end;

function TdmSqlStat.OpenDxccPerBandRows(const ShowDeleted : Boolean; const DeletedList, ModeCond : String) : TDataSet;
begin
  if ModeCond = '' then
  begin
    if ShowDeleted then
      Result := OpenRows(SqlDxccPerBand)
    else
      Result := OpenRows(SqlDxccPerBandExcluding(DeletedList))
  end
  else begin
    if ShowDeleted then
      Result := OpenRows(SqlDxccPerBandByMode(ModeCond))
    else
      Result := OpenRows(SqlDxccPerBandByModeExcluding(DeletedList, ModeCond))
  end
end;

function TdmSqlStat.OpenDxccCfmPerBandRows(const CfmCond : String; const ShowDeleted : Boolean; const DeletedList, ModeCond : String) : TDataSet;
begin
  if ModeCond = '' then
  begin
    if ShowDeleted then
      Result := OpenRows(SqlDxccCfmPerBand(CfmCond))
    else
      Result := OpenRows(SqlDxccCfmPerBandExcluding(CfmCond, DeletedList))
  end
  else begin
    if ShowDeleted then
      Result := OpenRows(SqlDxccCfmPerBandByMode(CfmCond, ModeCond))
    else
      Result := OpenRows(SqlDxccCfmPerBandByModeExcluding(CfmCond, DeletedList, ModeCond))
  end
end;

function TdmSqlStat.OpenDxccStatRows(const ShowDeleted : Boolean) : TDataSet;
begin
  if ShowDeleted then
    Result := OpenRows(SqlDxccStatRows)
  else
    Result := OpenRows(SqlDxccStatRowsNoDeleted)
end;

{ WAZ / ITU / WAC / WAS window }

function TdmSqlStat.OpenWazStatRows(const Where : String) : TDataSet;
begin
  Result := OpenRows(SqlWazStat(Where))
end;

function TdmSqlStat.OpenItuStatRows(const Where : String) : TDataSet;
begin
  Result := OpenRows(SqlItuStat(Where))
end;

function TdmSqlStat.OpenWacStatRows(const Where : String) : TDataSet;
begin
  Result := OpenRows(SqlWacStat(Where))
end;

function TdmSqlStat.OpenWasStatRows(const Where : String) : TDataSet;
begin
  Result := OpenRows(SqlWasStat(Where))
end;

function TdmSqlStat.OpenWazStationsRows(const CfmCond, ModeCond : String) : TDataSet;
begin
  if ModeCond = '' then
    Result := OpenRows(SqlWazStations(CfmCond))
  else
    Result := OpenRows(SqlWazStationsByMode(CfmCond, ModeCond))
end;

function TdmSqlStat.OpenItuStationsRows(const CfmCond, ModeCond : String) : TDataSet;
begin
  if ModeCond = '' then
    Result := OpenRows(SqlItuStations(CfmCond))
  else
    Result := OpenRows(SqlItuStationsByMode(CfmCond, ModeCond))
end;

function TdmSqlStat.OpenWacStationsRows(const CfmCond, ModeCond : String) : TDataSet;
begin
  if ModeCond = '' then
    Result := OpenRows(SqlWacStations(CfmCond))
  else
    Result := OpenRows(SqlWacStationsByMode(CfmCond, ModeCond))
end;

function TdmSqlStat.OpenWasStationsRows(const CfmCond, ModeCond : String) : TDataSet;
begin
  if ModeCond = '' then
    Result := OpenRows(SqlWasStations(CfmCond))
  else
    Result := OpenRows(SqlWasStationsByMode(CfmCond, ModeCond))
end;

{ DOK window }

function TdmSqlStat.OpenDokStationsRows(const CfmCond, ModeCond : String) : TDataSet;
begin
  if ModeCond = '' then
    Result := OpenRows(SqlDokStations(CfmCond))
  else
    Result := OpenRows(SqlDokStationsByMode(CfmCond, ModeCond))
end;

function TdmSqlStat.OpenDoksWorkedRows : TDataSet;
begin
  Result := OpenRows(SqlDoksWorked)
end;

function TdmSqlStat.OpenDokStatRows(const Where : String) : TDataSet;
begin
  Result := OpenRows(SqlDokStat(Where))
end;

{ big square / locator and county windows }

procedure TdmSqlStat.DropStatView(const TableName : String);
begin
  FQ.Prepare(SqlDropStatView(TableName));
  FQ.ExecAndCommit
end;

procedure TdmSqlStat.CreateStatView(const TableName, FilterSql : String);
begin
  FQ.Prepare(SqlCreateStatView(TableName, FilterSql));
  FQ.ExecAndCommit
end;

function TdmSqlStat.CountBigSquaresWorked(const TableName : String) : Integer;
begin
  Result := GetRowCount(SqlBigSquaresWorked(TableName))
end;

function TdmSqlStat.CountSquaresWorked(const TableName : String) : Integer;
begin
  Result := GetRowCount(SqlSquaresWorked(TableName))
end;

// One pass for the whole window, sorted, so the squares of a big square
// follow each other; two queries per big square were what made it slow.
function TdmSqlStat.ListSquareStatuses(const TableName, BandCond, CfmCond : String) : TSquareStatuses;
var
  Count : Integer = 0;
begin
  Result := nil;
  FQ.Prepare(SqlSquareStatuses(TableName, BandCond, CfmCond));
  try
    FQ.Open;
    while not FQ.Query.Eof do
    begin
      if Count = Length(Result) then
        SetLength(Result, Count*2 + 64);
      Result[Count].Square := FQ.Query.Fields[0].AsString;
      Result[Count].Cfm    := FQ.Query.Fields[1].AsInteger > 0;
      inc(Count);
      FQ.Query.Next
    end;
    SetLength(Result, Count)
  finally
    FQ.Release
  end
end;

function TdmSqlStat.CountCountiesWorked(const TableName : String) : Integer;
begin
  Result := GetRowCount(SqlCountiesWorked(TableName))
end;

// One pass for the whole window: a count query per county scans the
// log once per county (upper(county) can not use an index).
function TdmSqlStat.ListCountyQsoCounts(const TableName, BandCond, CfmCond : String) : TCountyQsoCounts;
var
  Count : Integer = 0;
begin
  Result := nil;
  FQ.Prepare(SqlCountyQsoCounts(TableName, BandCond, CfmCond));
  try
    FQ.Open;
    while not FQ.Query.Eof do
    begin
      if Count = Length(Result) then
        SetLength(Result, Count*2 + 64);
      Result[Count].County := FQ.Query.Fields[0].AsString;
      Result[Count].Wkd    := FQ.Query.Fields[1].AsInteger;
      Result[Count].Cfm    := FQ.Query.Fields[2].AsInteger;
      inc(Count);
      FQ.Query.Next
    end;
    SetLength(Result, Count)
  finally
    FQ.Release
  end
end;

{ DXCC counts and probes }

function TdmSqlStat.SqlDxccCount : String;
begin
  Result := 'select count(*) from (select distinct adif from cqrlog_main where adif <> 0) as foo '
end;

function TdmSqlStat.SqlDxccCountExcluding(const DeletedList : String) : String;
begin
  Result := 'select count(*) from (select distinct adif from cqrlog_main'+
            ' where adif <> 0 and '+DeletedList+') as foo '
end;

function TdmSqlStat.SqlDxccCfmCount(const Where : String) : String;
begin
  Result := 'select count(*) from (select distinct dxcc_id.dxcc_ref from dxcc_id left join cqrlog_main on '+
            'dxcc_id.adif = cqrlog_main.adif WHERE cqrlog_main.adif<>0 and '+Where+') as foo'
end;

function TdmSqlStat.SqlQsoCfmOnBandModeIncLotw(const Adif, Band, Mode : String) : String;
begin
  Result := 'SELECT id_cqrlog_main FROM cqrlog_main WHERE adif='+
            Adif+' AND band='+QuotedStr(Band)+' AND ((qsl_r='+
            QuotedStr('Q')+') OR (lotw_qslr='+QuotedStr('L')+')) AND mode='+
            QuotedStr(Mode)+' LIMIT 1'
end;

function TdmSqlStat.SqlQsoCfmOnBandMode(const Adif, Band, Mode : String) : String;
begin
  Result := 'SELECT id_cqrlog_main FROM cqrlog_main WHERE adif='+
            Adif+' AND band='+QuotedStr(Band)+' AND qsl_r='+
            QuotedStr('Q')+ ' AND mode='+QuotedStr(Mode)+' LIMIT 1'
end;

function TdmSqlStat.SqlQsoOnBandMode(const Adif, Band, Mode : String) : String;
begin
  Result := 'SELECT id_cqrlog_main FROM cqrlog_main WHERE adif='+
            Adif+' AND band='+QuotedStr(Band)+' AND mode='+
            QuotedStr(Mode)+' LIMIT 1'
end;

function TdmSqlStat.SqlQsoOnBand(const Adif, Band : String) : String;
begin
  Result := 'SELECT id_cqrlog_main FROM cqrlog_main WHERE adif='+
            Adif+' AND band='+QuotedStr(Band)+' LIMIT 1'
end;

function TdmSqlStat.SqlQsoWithDxcc(const Adif : String) : String;
begin
  Result := 'SELECT id_cqrlog_main FROM cqrlog_main WHERE adif='+
            Adif+' LIMIT 1'
end;

{ worked/confirmed grid in NewQSO and the contest list }

// CallCond is empty or " and callsign='...'", built by the caller.
function TdmSqlStat.SqlCfmBandsModesIncLotw(const Adif : Integer; const CallCond : String) : String;
begin
  Result := 'select band,mode,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main where adif='+
            IntToStr(Adif) + CallCond + ' and ((qsl_r='+QuotedStr('Q')+') or '+
            '(lotw_qslr = '+QuotedStr('L')+') or (eqsl_qsl_rcvd='+QuotedStr('E')+
            ')) group by band,mode,qsl_r,lotw_qslr,eqsl_qsl_rcvd'
end;

function TdmSqlStat.SqlCfmBandsModes(const Adif : Integer; const CallCond : String) : String;
begin
  Result := 'select band,mode,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main where adif='+
            IntToStr(Adif) + CallCond + ' and (qsl_r = '+QuotedStr('Q')+') '+
            'group by band,mode,qsl_r,lotw_qslr,eqsl_qsl_rcvd'
end;

function TdmSqlStat.SqlWorkedBandsModes(const Adif : Integer; const CallCond : String) : String;
begin
  Result := 'select band,mode from cqrlog_main where adif='+
            IntToStr(Adif) + CallCond +' group by band,mode'
end;

function TdmSqlStat.SqlSetCharacterSetUtf8 : String;
begin
  Result := 'SET CHARACTER SET '+QuotedStr('utf8')
end;

function TdmSqlStat.SqlWorkedContests : String;
const
  C_SEL = 'SELECT DISTINCT `contestname` FROM `cqrlog_main` WHERE `contestname` IS NOT NULL and `contestname` != '''' ORDER BY `contestname` ASC';
begin
  Result := C_SEL
end;

{ small windows }

function TdmSqlStat.SqlQsoCountPerMode : String;
begin
  Result := 'select count(mode) as cnt,mode from cqrlog_main group by mode order by cnt'
end;

// Field is the column the user picked; Where is the composed condition
// or empty.
function TdmSqlStat.SqlCustomStat(const Field, Where : String) : String;
begin
  Result := 'select ' + Field + ' from cqrlog_main ' +
            Where + 'order by ' + Field
end;

// Where already starts with " where ".
function TdmSqlStat.SqlIotaList(const Where : String) : String;
const
  C_SEL = 'select distinct iota,callsign from cqrlog_main %s group by iota order by iota';
begin
  Result := Format(C_SEL,[Where])
end;

function TdmSqlStat.SqlIotaCount(const Where : String) : String;
const
  C_SUM = 'select count(*) from (select count(iota) from cqrlog_main %s group by iota) as aa';
begin
  Result := Format(C_SUM,[Where])
end;

{ DXCC statistics window }

// The seven Get*Count functions of fDXCCStat: how many entities in the log
// satisfy Where (mode, confirmation, deleted or not).
function TdmSqlStat.SqlDistinctDxccCount(const Where : String) : String;
begin
  Result := 'select count(*) from (select distinct dxcc_id.dxcc_ref from dxcc_id left join cqrlog_main on '+
            'dxcc_id.adif = cqrlog_main.adif WHERE cqrlog_main.adif <> 0 and '+Where+') as foo'
end;

// The two consts below are one statement; fDXCCStat declared it twice.
const
  C_DXCC_CFM_SEL     = 'select band,count(distinct adif) from cqrlog_main where adif <> 0 and ';
  C_DXCC_CFM_DISTSEL = 'select band,count(distinct adif) from cqrlog_main where adif <> 0 and ';

function TdmSqlStat.SqlDxccPerBand : String;
begin
  Result := 'select band,count(distinct adif) from cqrlog_main where adif <> 0'+
            ' group by band'
end;

// DeletedList is the "(adif<>..) and .." list of deleted entities to leave out.
function TdmSqlStat.SqlDxccPerBandExcluding(const DeletedList : String) : String;
begin
  Result := 'select band,count(distinct adif) from cqrlog_main '+
            '  where adif <> 0 and ' + DeletedList +' group by band'
end;

function TdmSqlStat.SqlDxccPerBandByMode(const ModeCond : String) : String;
begin
  Result := 'select band,count(distinct adif) from cqrlog_main '+
            'where adif <> 0 and' + ModeCond + ' group by band'
end;

function TdmSqlStat.SqlDxccPerBandByModeExcluding(const DeletedList, ModeCond : String) : String;
begin
  Result := 'select band,count(distinct adif) from cqrlog_main '+
            '  where adif <> 0 and (' + DeletedList +') and '+ModeCond+' group by band'
end;

function TdmSqlStat.SqlDxccCfmPerBand(const CfmCond : String) : String;
begin
  Result := C_DXCC_CFM_SEL+CfmCond+' group by band'
end;

function TdmSqlStat.SqlDxccCfmPerBandExcluding(const CfmCond, DeletedList : String) : String;
begin
  Result := C_DXCC_CFM_SEL+CfmCond+' and '+DeletedList+' group by band'
end;

function TdmSqlStat.SqlDxccCfmPerBandByMode(const CfmCond, ModeCond : String) : String;
begin
  Result := C_DXCC_CFM_DISTSEL+CfmCond+ ' and '+ ModeCond +' group by band'
end;

function TdmSqlStat.SqlDxccCfmPerBandByModeExcluding(const CfmCond, DeletedList, ModeCond : String) : String;
begin
  Result := C_DXCC_CFM_DISTSEL+CfmCond+ ' and ' +DeletedList+ ' and '+ModeCond+' group by band'
end;

function TdmSqlStat.SqlDxccStatRows : String;
begin
  Result := 'select d.dxcc_ref,d.country, c.band, c.mode, c.qsl_r,c.lotw_qslr,c.eqsl_qsl_rcvd from cqrlog_main c '+
            'left join dxcc_id d on c.adif = d.adif where d.dxcc_ref<>'+QuotedStr('')+' and d.dxcc_ref<>'+QuotedStr('!')+
            ' group by d.dxcc_ref,c.band,c.mode,c.qsl_r,c.lotw_qslr,c.eqsl_qsl_rcvd order by d.dxcc_ref,c.band,c.mode,c.qsl_r,c.lotw_qslr,c.eqsl_qsl_rcvd'
end;

function TdmSqlStat.SqlDxccStatRowsNoDeleted : String;
begin
  Result := 'select d.dxcc_ref,d.country, c.band, c.mode, c.qsl_r,c.lotw_qslr,c.eqsl_qsl_rcvd from cqrlog_main c '+
            'left join dxcc_id d on c.adif = d.adif where (d.dxcc_ref<>'+QuotedStr('')+') and d.dxcc_ref<>'+QuotedStr('!')+
            ' and (d.dxcc_ref not like '+QuotedStr('%*')+') group by d.dxcc_ref,c.band,c.mode,'+
            'c.qsl_r,c.lotw_qslr,c.eqsl_qsl_rcvd order by d.dxcc_ref,c.band,c.mode,c.qsl_r,c.lotw_qslr,c.eqsl_qsl_rcvd'
end;

{ WAZ / ITU / WAC / WAS window }

// Where is empty or "where <mode condition>", as the window composes it.
function TdmSqlStat.SqlWazStat(const Where : String) : String;
const
  C_SEL = 'select waz,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main '+
          '%s '+
          'group by waz,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd '+
          'having (waz > 0) and (waz < 41) '+
          'order by waz';
begin
  Result := Format(C_SEL,[Where])
end;

function TdmSqlStat.SqlItuStat(const Where : String) : String;
const
  C_SEL = 'select itu,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main '+
          '%s '+
          'group by itu,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd '+
          'having (itu > 0) and (itu < 91) '+
          'order by itu';
begin
  Result := Format(C_SEL,[Where])
end;

function TdmSqlStat.SqlWacStat(const Where : String) : String;
const
  C_SEL = 'select cont,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main '+
          '%s '+
          'group by cont,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd '+
          'having (cont <> '''') '+
          'order by cont';
begin
  Result := Format(C_SEL,[Where])
end;

function TdmSqlStat.SqlWasStat(const Where : String) : String;
const
  C_SEL = 'select state,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main '+
          '%s '+
          'group by state,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd '+
          'having (state <> '''') '+
          'order by state';
begin
  Result := Format(C_SEL,[Where])
end;

// Station lists behind the award grids.  CfmCond is the confirmation
// condition without a trailing space, ModeCond the mode condition.
function TdmSqlStat.SqlWazStations(const CfmCond : String) : String;
begin
  Result := 'select main.callsign, main.freq,main.mode,main.waz from ( '+
            'select waz,band,qsl_r,max(a.id_cqrlog_main) as id_cqrlog_main from cqrlog_main a where '+
            '(waz <> 0) and '+ CfmCond +
            'group by waz,band,qsl_r order by waz,band)'+
            'subsel join cqrlog_main main on subsel.id_cqrlog_main = main.id_cqrlog_main  order by convert(freq,signed),waz'
end;

function TdmSqlStat.SqlWazStationsByMode(const CfmCond, ModeCond : String) : String;
begin
  Result := 'select main.callsign,main.freq,main.mode,main.waz from ( '+
            'select waz,band,qsl_r,max(a.id_cqrlog_main) as id_cqrlog_main from cqrlog_main a where '+
            '(waz <> 0) and '+ CfmCond + ' and ' + ModeCond +' '+
            'group by waz,band,qsl_r order by waz,band)'+
            'subsel join cqrlog_main main on subsel.id_cqrlog_main = main.id_cqrlog_main  order by convert(freq,signed),waz'
end;

function TdmSqlStat.SqlItuStations(const CfmCond : String) : String;
begin
  Result := 'select main.callsign, main.freq,main.mode,main.itu from ( '+
            'select itu,band,qsl_r,max(a.id_cqrlog_main) as id_cqrlog_main from cqrlog_main a where '+
            '(itu <> 0) and '+ CfmCond +
            'group by itu,band,qsl_r order by itu,band)'+
            'subsel join cqrlog_main main on subsel.id_cqrlog_main = main.id_cqrlog_main  order by convert(freq,signed),itu'
end;

function TdmSqlStat.SqlItuStationsByMode(const CfmCond, ModeCond : String) : String;
begin
  Result := 'select main.callsign,main.freq,main.mode,main.itu from ( '+
            'select itu,band,qsl_r,max(a.id_cqrlog_main) as id_cqrlog_main from cqrlog_main a where '+
            '(itu <> 0) and '+ CfmCond + ' and ' + ModeCond +' '+
            'group by itu,band,qsl_r order by itu,band)'+
            'subsel join cqrlog_main main on subsel.id_cqrlog_main = main.id_cqrlog_main  order by convert(freq,signed),itu'
end;

function TdmSqlStat.SqlWacStations(const CfmCond : String) : String;
begin
  Result := 'select main.callsign, main.freq,main.mode,main.cont from ( '+
            'select cont,band,qsl_r,max(a.id_cqrlog_main) as id_cqrlog_main from cqrlog_main a where '+
            '(cont <> '+QuotedStr('')+') and '+ CfmCond +
            'group by cont,band,qsl_r order by cont,band)'+
            'subsel join cqrlog_main main on subsel.id_cqrlog_main = main.id_cqrlog_main  order by convert(freq,signed),cont'
end;

function TdmSqlStat.SqlWacStationsByMode(const CfmCond, ModeCond : String) : String;
begin
  Result := 'select main.callsign, main.freq,main.mode,main.cont from ( '+
            'select cont,band,qsl_r,max(a.id_cqrlog_main) as id_cqrlog_main from cqrlog_main a where '+
            '(cont <> '+QuotedStr('')+') and '+ CfmCond + ' and ' + ModeCond +' '+
            'group by cont,band,qsl_r order by cont,band)'+
            'subsel join cqrlog_main main on subsel.id_cqrlog_main = main.id_cqrlog_main  order by convert(freq,signed),cont'
end;

function TdmSqlStat.SqlWasStations(const CfmCond : String) : String;
begin
  Result := 'select callsign,freq,mode,state from cqrlog_main '+
            ' where (state <> '+QuotedStr('')+') and ((adif=291) or (adif=6) or (adif=110)) and '+ CfmCond +' order by convert(freq,signed),state'
end;

function TdmSqlStat.SqlWasStationsByMode(const CfmCond, ModeCond : String) : String;
begin
  Result := 'select callsign,freq,mode,state from cqrlog_main'+
            ' where (state <> '+QuotedStr('')+') and ((adif=291) or (adif=6) or (adif=110)) and '+ CfmCond +' AND '+ModeCond+
            'order by convert(freq,signed),state'
end;

{ DOK window }

function TdmSqlStat.SqlDokStations(const CfmCond : String) : String;
begin
  Result := 'select callsign,freq,mode,dok from cqrlog_main '+
            ' where (dok <> '+QuotedStr('')+') and (adif=230) and '+ CfmCond +' order by convert(freq,signed),dok'
end;

function TdmSqlStat.SqlDokStationsByMode(const CfmCond, ModeCond : String) : String;
begin
  Result := 'select callsign,freq,mode,dok from cqrlog_main'+
            ' where (dok <> '+QuotedStr('')+') and (adif=230) and '+ CfmCond +' AND '+ModeCond+
            'order by convert(freq,signed),dok'
end;

function TdmSqlStat.SqlDoksWorked : String;
begin
  Result := 'select distinct dok from cqrlog_main '+
            'where (adif=230) '+
            'having (dok <> '''') '+
            'order by dok'
end;

function TdmSqlStat.SqlDokStat(const Where : String) : String;
const
  C_SEL = 'select dok,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main '+
          '%s '+
          'group by dok,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd '+
          'having (dok <> '''') '+
          'order by dok';
begin
  Result := Format(C_SEL,[Where])
end;

{ big square / locator window }

// The window reads either cqrlog_main or a view of the current filter it
// creates first; TableName is whichever applies.  BandCond is empty or
// " and band='..'", CfmCond the confirmation condition.

function TdmSqlStat.SqlDropStatView(const TableName : String) : String;
begin
  Result := 'DROP VIEW IF EXISTS '+TableName
end;

function TdmSqlStat.SqlCreateStatView(const TableName, FilterSql : String) : String;
begin
  Result := 'CREATE VIEW '+TableName+' AS '+FilterSql
end;

function TdmSqlStat.SqlBigSquaresWorked(const TableName : String) : String;
begin
  Result := 'select substr(loc,1,2) as ll FROM '+TableName+' where loc <> '+QuotedStr('')+' group by ll'
end;

function TdmSqlStat.SqlSquaresWorked(const TableName : String) : String;
begin
  Result := 'select substr(loc,1,4) as ll FROM '+TableName+' where loc <> '+QuotedStr('')+' group by ll'
end;

// CfmCond may be empty (no confirmation type ticked); cfm is then 0.
function TdmSqlStat.SqlSquareStatuses(const TableName, BandCond, CfmCond : String) : String;
var
  Cfm : String;
begin
  if CfmCond = '' then
    Cfm := '0'
  else
    Cfm := 'max(case when ('+CfmCond+') then 1 else 0 end)';
  Result := 'select upper(substr(loc,1,4)) as lll, '+Cfm+' as cfm FROM '+TableName+
            ' where loc <> '+QuotedStr('')+BandCond+' group by lll order by lll'
end;

{ county window }

// Same shape as the locator window above, including the view.

function TdmSqlStat.SqlCountiesWorked(const TableName : String) : String;
begin
  Result := 'select upper(county) as ll FROM '+TableName+' where county <> '+QuotedStr('')+' group by ll'
end;

// CfmCond may be empty (no confirmation type ticked); cfm is then 0.
function TdmSqlStat.SqlCountyQsoCounts(const TableName, BandCond, CfmCond : String) : String;
var
  Cfm : String;
begin
  if CfmCond = '' then
    Cfm := '0'
  else
    Cfm := 'sum(case when ('+CfmCond+') then 1 else 0 end)';
  Result := 'select upper(county) as ll, count(id_cqrlog_main) as wkd, '+Cfm+' as cfm FROM '+
            TableName+' where county <> '+QuotedStr('')+BandCond+' group by ll order by ll'
end;

{ worked grids map }

// fWorkedGrids quotes with #39 and appends DayLimit, an optional
// " and qsodate >= '..'" the window builds from its settings.

function TdmSqlStat.SqlQsoCountIn(const LogTable : String) : String;
begin
  Result := 'select count(callsign) from ' + LogTable
end;

function TdmSqlStat.SqlWkdMainGrid(const LogTable, L2, Band, Mode, DayLimit : String) : String;
begin
  Result := 'select count(loc) as '+#39+'sum'+#39+' from '+LogTable+
            ' where loc like '+#39+L2+ '%'+#39+
            ' and band='+#39+Band+#39+' and mode='+#39+Mode+#39+DayLimit+
            'union all '+
            'select count(loc) from '+LogTable+
            ' where loc like '+#39+L2+ '%'+#39+
            ' and band='+#39+Band+#39+DayLimit+
            'union all '+
            'select count(loc) from '+LogTable+
            ' where loc like '+#39+L2+ '%'+#39+DayLimit
end;

function TdmSqlStat.SqlWkdGrid(const LogTable, L4, L2, Band, Mode, DayLimit : String) : String;
begin
  Result := 'select count(loc) as '+#39+'sum'+#39+' from '+LogTable+
            ' where loc like '+#39+L4+ '%'+#39+
            ' and band='+#39+Band+#39+' and mode='+#39+Mode+#39+DayLimit+
            'union all '+
            'select count(loc) from '+LogTable+
            ' where loc like '+#39+L4+ '%'+#39+
            ' and band='+#39+Band+#39+DayLimit+
            'union all '+
            'select count(loc) from '+LogTable+
            ' where loc like '+#39+L4+ '%'+#39+DayLimit+
            'union all '+
            'select count(loc) from '+LogTable+
            ' where loc like '+#39+L2+ '%'+#39+
            ' and band='+#39+Band+#39+' and mode='+#39+Mode+#39+DayLimit+
            'union all '+
            'select count(loc) from '+LogTable+
            ' where loc like '+#39+L2+ '%'+#39+
            ' and band='+#39+Band+#39+DayLimit+
            'union all '+
            'select count(loc) from '+LogTable+
            ' where loc like '+#39+L2+ '%'+#39+DayLimit
end;

function TdmSqlStat.SqlWkdCall(const LogTable, Call, Band, Mode, DayLimit : String) : String;
begin
  Result := 'select count(callsign) as '+#39+'sum'+#39+' from '+LogTable+
            ' where callsign='+#39+Call+#39+
            ' and band='+#39+Band+#39+' and mode='+#39+Mode+#39+DayLimit+
            'union all '+
            'select count(callsign) from '+LogTable+
            ' where callsign='+#39+Call+#39+
            ' and band='+#39+Band+#39+DayLimit+
            'union all '+
            'select count(callsign) from '+LogTable+
            ' where callsign='+#39+Call+#39+DayLimit
end;

function TdmSqlStat.SqlWkdState(const LogTable, State, Band, Mode, DayLimit : String) : String;
begin
  Result := 'select count(state) as '+#39+'sum'+#39+' from '+LogTable+
            ' where state='+#39+State+#39+
            ' and band='+#39+Band+#39+' and mode='+#39+Mode+#39+DayLimit+
            'union all '+
            'select count(state) from '+LogTable+
            ' where state='+#39+State+#39+
            ' and band='+#39+Band+#39+DayLimit+
            'union all '+
            'select count(state) from '+LogTable+
            ' where state='+#39+State+#39+DayLimit
end;

function TdmSqlStat.SqlWkdSquaresOnBand(const LogTable, Band, ModeTail : String) : String;
begin
  Result := 'select upper(substr(loc,1,4)) as lo from ' + LogTable +
            ' where band=' + #39 + Band +
            #39 + 'and loc<>' + #39 + #39 + ModeTail
end;

function TdmSqlStat.SqlWkdSquares(const LogTable, ModeTail : String) : String;
begin
  Result := 'select upper(substr(loc,1,4)) as lo from ' + LogTable +
            ' where loc<>' + #39 + #39 + ModeTail
end;

// FromClause is the " from .. where .." tail the window cuts out of its
// square query, so both counts see the same rows.
function TdmSqlStat.SqlWkdSquareCounts(const FromClause, DayLimit : String) : String;
begin
  Result := 'select count(distinct upper(substr(loc,1,2))) as main,count(distinct upper(substr(loc,1,4))) as sub'+
            FromClause+DayLimit
end;

function TdmSqlStat.SqlWkdQsoCounts(const DayLimit, BandCond : String) : String;
begin
  Result := 'select count(callsign) as qso from cqrlog_main where callsign<>'+#39+#39+DayLimit+
            'union all select count(callsign) from cqrlog_main where callsign<>'+#39+#39 + BandCond +DayLimit
end;

{ spot probes }

function TdmSqlStat.SqlSpotQsoCfmOnBandModeIncLotw(const DbName, Adif, Band, Mode : String) : String;
begin
  Result := 'SELECT id_cqrlog_main FROM '+DbName+'.cqrlog_main WHERE adif='+
            Adif+' AND band='+QuotedStr(Band)+' AND ((qsl_r='+
            QuotedStr('Q')+') OR (lotw_qslr='+ QuotedStr('L')+
            ') OR (eqsl_qsl_rcvd='+ QuotedStr('E')+')) AND mode='+
            QuotedStr(Mode)+' LIMIT 1'
end;

function TdmSqlStat.SqlSpotQsoCfmOnBandMode(const DbName, Adif, Band, Mode : String) : String;
begin
  Result := 'SELECT id_cqrlog_main FROM '+DbName+'.cqrlog_main WHERE adif='+
            Adif+' AND band='+QuotedStr(Band)+' AND qsl_r='+
            QuotedStr('Q')+ ' AND mode='+QuotedStr(Mode)+' LIMIT 1'
end;

function TdmSqlStat.SqlSpotQsoOnBandMode(const DbName, Adif, Band, Mode : String) : String;
begin
  Result := 'SELECT id_cqrlog_main FROM '+DbName+'.cqrlog_main WHERE adif='+
            Adif+' AND band='+QuotedStr(Band)+' AND mode='+
            QuotedStr(Mode)+' LIMIT 1'
end;

function TdmSqlStat.SqlSpotQsoOnBand(const DbName, Adif, Band : String) : String;
begin
  Result := 'SELECT id_cqrlog_main FROM '+DbName+'.cqrlog_main WHERE adif='+
            Adif+' AND band='+QuotedStr(Band)+' LIMIT 1'
end;

function TdmSqlStat.SqlSpotQsoWithDxcc(const DbName, Adif : String) : String;
begin
  Result := 'SELECT id_cqrlog_main FROM '+DbName+'.cqrlog_main WHERE adif='+
            Adif+' LIMIT 1'
end;

function TdmSqlStat.SqlRbnQsoCfmOnBandModeIncLotw(const DbName, Adif, Band, Mode : String) : String;
begin
  Result := 'SELECT id_cqrlog_main FROM '+DbName+'.cqrlog_main WHERE adif='+
            Adif+' AND band='+QuotedStr(Band)+' AND ((qsl_r='+
            QuotedStr('Q')+') OR (lotw_qslr='+QuotedStr('L')+')) AND mode='+
            QuotedStr(Mode)+' LIMIT 1'
end;

end.
