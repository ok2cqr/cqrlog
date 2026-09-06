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
// Builders only, and one builder per call site.  The statistics compose
// their WHERE clauses from window state (confirmation type, mode, band,
// deleted entities), and that composition stays in the forms; a builder
// takes the composed condition as a string and wraps the statement around
// it.  Several builders therefore share a body -- one per site keeps the
// SQL inventory (tools/sql-inventory) unchanged; the merge pass collapses
// them.

unit dSqlStat;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources;

type
  TdmSqlStat = class(TDataModule)
  public
    // DXCC counts and probes (dDXCC)
    function SqlDxccCount : String;
    function SqlDxccCountExcluding(const DeletedList : String) : String;
    function SqlDxccCountNoDeletedList : String;
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
    function SqlDropSquareStatView(const TableName : String) : String;
    function SqlCreateSquareStatView(const TableName, FilterSql : String) : String;
    function SqlBigSquaresWorked(const TableName : String) : String;
    function SqlSquaresWorked(const TableName : String) : String;
    function SqlBigSquaresOnBand(const TableName, BandCond : String) : String;
    function SqlSquaresInBigSquare(const TableName, BigSquare, BandCond : String) : String;
    function SqlSquaresInBigSquareCfm(const TableName, BigSquare, BandCond, CfmCond : String) : String;
    function SqlDropSquareStatViewAfter(const TableName : String) : String;

    // county window (fCountyStat)
    function SqlDropCountyStatView(const TableName : String) : String;
    function SqlCreateCountyStatView(const TableName, FilterSql : String) : String;
    function SqlCountiesWorked(const TableName : String) : String;
    function SqlCountiesOnBand(const TableName, BandCond : String) : String;
    function SqlCountyQsoCount(const TableName, County, BandCond : String) : String;
    function SqlCountyQsoCountCfm(const TableName, County, BandCond, CfmCond : String) : String;
    function SqlDropCountyStatViewAfter(const TableName : String) : String;

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
    // dData.RbnMonDXCCInfo; the same ladder as SqlQsoCfmOnBandModeIncLotw
    // above, with the database name spelled out and one copy per window)
    function SqlSpotQsoCfmOnBandModeIncLotw(const DbName, Adif, Band, Mode : String) : String;
    function SqlSpotQsoCfmOnBandMode(const DbName, Adif, Band, Mode : String) : String;
    function SqlSpotQsoOnBandMode(const DbName, Adif, Band, Mode : String) : String;
    function SqlSpotQsoOnBand(const DbName, Adif, Band : String) : String;
    function SqlSpotQsoWithDxcc(const DbName, Adif : String) : String;
    function SqlRbnQsoCfmOnBandModeIncLotw(const DbName, Adif, Band, Mode : String) : String;
    function SqlRbnQsoCfmOnBandMode(const DbName, Adif, Band, Mode : String) : String;
    function SqlRbnQsoOnBandMode(const DbName, Adif, Band, Mode : String) : String;
    function SqlRbnQsoOnBand(const DbName, Adif, Band : String) : String;
    function SqlRbnQsoWithDxcc(const DbName, Adif : String) : String;
  end;

var
  dmSqlStat : TdmSqlStat;

implementation

{$R *.lfm}

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

// Same statement as SqlDxccCount, taken when there is no deleted-entity
// list to exclude.  Kept separate so this extraction leaves the SQL
// inventory untouched; the merge pass collapses them.
function TdmSqlStat.SqlDxccCountNoDeletedList : String;
begin
  Result := 'select count(*) from (select distinct adif from cqrlog_main where adif <> 0) as foo '
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
  Result := 'SET CHARACTER SET "utf8"'
end;

function TdmSqlStat.SqlWorkedContests : String;
const
  C_SEL = 'SELECT DISTINCT `contestname` FROM `cqrlog_main` WHERE `contestname` IS NOT NULL and `contestname` != "" ORDER BY `contestname` ASC';
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

function TdmSqlStat.SqlDropSquareStatView(const TableName : String) : String;
begin
  Result := 'DROP VIEW IF EXISTS '+TableName
end;

function TdmSqlStat.SqlCreateSquareStatView(const TableName, FilterSql : String) : String;
begin
  Result := 'CREATE VIEW '+TableName+' AS '+FilterSql
end;

function TdmSqlStat.SqlBigSquaresWorked(const TableName : String) : String;
begin
  Result := 'select left(loc,2) as ll FROM '+TableName+' where loc <> '+QuotedStr('')+' group by ll'
end;

function TdmSqlStat.SqlSquaresWorked(const TableName : String) : String;
begin
  Result := 'select left(loc,4) as ll FROM '+TableName+' where loc <> '+QuotedStr('')+' group by ll'
end;

function TdmSqlStat.SqlBigSquaresOnBand(const TableName, BandCond : String) : String;
begin
  Result := 'select upper(left(loc,2)) as ll FROM '+TableName+' where loc <> '+QuotedStr('')+
            BandCond+' group by ll'
end;

function TdmSqlStat.SqlSquaresInBigSquare(const TableName, BigSquare, BandCond : String) : String;
begin
  Result := 'select upper(left(loc,4)) as lll FROM '+TableName+' where loc like '+
            QuotedStr(BigSquare+'%')+BandCond+' group by lll order by loc'
end;

function TdmSqlStat.SqlSquaresInBigSquareCfm(const TableName, BigSquare, BandCond, CfmCond : String) : String;
begin
  Result := 'select upper(left(loc,4)) as lll FROM '+TableName+' where loc like '+
            QuotedStr(BigSquare+'%')+BandCond+'and ('+CfmCond+') group by lll order by loc'
end;

// Same statement as SqlDropSquareStatView, run once more when the window
// is done.  Kept separate -- see the note on SqlDxccCountNoDeletedList.
function TdmSqlStat.SqlDropSquareStatViewAfter(const TableName : String) : String;
begin
  Result := 'DROP VIEW IF EXISTS '+TableName
end;

{ county window }

// Same shape as the locator window above, including the view; the four
// DROP/CREATE builders are copies kept separate for the inventory.

function TdmSqlStat.SqlDropCountyStatView(const TableName : String) : String;
begin
  Result := 'DROP VIEW IF EXISTS '+TableName
end;

function TdmSqlStat.SqlCreateCountyStatView(const TableName, FilterSql : String) : String;
begin
  Result := 'CREATE VIEW '+TableName+' AS '+FilterSql
end;

function TdmSqlStat.SqlCountiesWorked(const TableName : String) : String;
begin
  Result := 'select upper(county) as ll FROM '+TableName+' where county <> '+QuotedStr('')+' group by ll'
end;

function TdmSqlStat.SqlCountiesOnBand(const TableName, BandCond : String) : String;
begin
  Result := 'select upper(county) as ll FROM '+TableName+' where county <> '+QuotedStr('')+
            BandCond+' group by ll'
end;

function TdmSqlStat.SqlCountyQsoCount(const TableName, County, BandCond : String) : String;
begin
  Result := 'select count(id_cqrlog_main) FROM '+TableName+' where upper(county)='+
            QuotedStr(County)+BandCond
end;

function TdmSqlStat.SqlCountyQsoCountCfm(const TableName, County, BandCond, CfmCond : String) : String;
begin
  Result := 'select count(id_cqrlog_main) FROM '+TableName+' where upper(county)='+
            QuotedStr(County)+BandCond+
            'and ('+CfmCond+')'
end;

function TdmSqlStat.SqlDropCountyStatViewAfter(const TableName : String) : String;
begin
  Result := 'DROP VIEW IF EXISTS '+TableName
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
  Result := 'select upper(left(loc,4)) as lo from ' + LogTable +
            ' where band=' + #39 + Band +
            #39 + 'and loc<>' + #39 + #39 + ModeTail
end;

function TdmSqlStat.SqlWkdSquares(const LogTable, ModeTail : String) : String;
begin
  Result := 'select upper(left(loc,4)) as lo from ' + LogTable +
            ' where loc<>' + #39 + #39 + ModeTail
end;

// FromClause is the " from .. where .." tail the window cuts out of its
// square query, so both counts see the same rows.
function TdmSqlStat.SqlWkdSquareCounts(const FromClause, DayLimit : String) : String;
begin
  Result := 'select count(distinct upper(left(loc,2))) as main,count(distinct upper(left(loc,4))) as sub'+
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

function TdmSqlStat.SqlRbnQsoCfmOnBandMode(const DbName, Adif, Band, Mode : String) : String;
begin
  Result := 'SELECT id_cqrlog_main FROM '+DbName+'.cqrlog_main WHERE adif='+
            Adif+' AND band='+QuotedStr(Band)+' AND qsl_r='+
            QuotedStr('Q')+ ' AND mode='+QuotedStr(Mode)+' LIMIT 1'
end;

function TdmSqlStat.SqlRbnQsoOnBandMode(const DbName, Adif, Band, Mode : String) : String;
begin
  Result := 'SELECT id_cqrlog_main FROM '+DbName+'.cqrlog_main WHERE adif='+
            Adif+' AND band='+QuotedStr(Band)+' AND mode='+
            QuotedStr(Mode)+' LIMIT 1'
end;

function TdmSqlStat.SqlRbnQsoOnBand(const DbName, Adif, Band : String) : String;
begin
  Result := 'SELECT id_cqrlog_main FROM '+DbName+'.cqrlog_main WHERE adif='+
            Adif+' AND band='+QuotedStr(Band)+' LIMIT 1'
end;

function TdmSqlStat.SqlRbnQsoWithDxcc(const DbName, Adif : String) : String;
begin
  Result := 'SELECT id_cqrlog_main FROM '+DbName+'.cqrlog_main WHERE adif='+
            Adif+' LIMIT 1'
end;

end.
