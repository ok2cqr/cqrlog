(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

// The log itself: paging the main grid through the view_cqrlog_main_*
// views, saving and editing a QSO, the previous-QSO and "worked before"
// probes NewQSO and the spot windows run, and the contest window's
// scoring queries.
//
// Builders only, one per call site (see dSqlStat for why).  Every caller
// still runs these on the cursor it always used -- qCQRLOG, Q, Q1, CQ,
// qQSOBefore, qBandMapFil, qRbnMon -- and the critical sections around
// qBandMapFil and the DX cluster cursors are untouched.

unit dSqlQso;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources;

type
  TdmSqlQso = class(TDataModule)
  public
    // main grid paging (fMain, fSort, fContestFilter)
    function SqlDeleteQso(const Id : Integer) : String;
    function SqlQsosByIds(const IdList : String) : String;
    function SqlLastPageByDate(const Limit : Integer) : String;
    function SqlLastPageByCall(const Limit : Integer) : String;
    function SqlLastPageByDateAfterDown(const Limit : Integer) : String;
    function SqlLastPageByCallAfterDown(const Limit : Integer) : String;
    function SqlFirstPageByDate(const Limit : Integer) : String;
    function SqlFirstPageByCall(const Limit : Integer) : String;
    function SqlFirstPageByDateAfterUp(const Limit : Integer) : String;
    function SqlFirstPageByCallAfterUp(const Limit : Integer) : String;
    function SqlFirstPageByDateOnRefresh(const Limit : Integer) : String;
    function SqlFirstPageByDateOffset0(const Limit : Integer) : String;
    function SqlFirstPageByDateSorted(const Limit : Integer) : String;
    function SqlFirstPageByDateAsc(const Limit : Integer) : String;
    function SqlFirstPageByCallSorted(const Limit : Integer) : String;
    function SqlFirstQsoIdByDate : String;
    function SqlFirstQsoIdByCall : String;
    function SqlOldestQsoId : String;
    function SqlLastQsoIdByCall : String;
    function SqlCountNewerByDate(const QsoDate, Time : String; const Limit : Integer) : String;
    function SqlCountBeforeByCall(const Call : String; const Limit : Integer) : String;
    function SqlPageNewerByDate(const QsoDate, Time : String; const Limit : Integer) : String;
    function SqlPageBeforeByCall(const Call : String; const Limit : Integer) : String;
    function SqlCountOlderByDate(const QsoDate, Time : String; const Limit : Integer) : String;
    function SqlCountAfterByCall(const Call : String; const Limit : Integer) : String;
    function SqlPageOlderByDate(const QsoDate, Time : String; const Limit : Integer) : String;
    function SqlPageAfterByCall(const Call : String; const Limit : Integer) : String;
    function SqlQsosOfContest(const ContestName : String) : String;
    // contest window (fContest)
    function SqlLastSrxString : String;
    function SqlContestSuffixEnds(const ContestName, Band : String) : String;
    function SqlContestVhfQsoCount(const ContestName : String) : String;
    function SqlContestVhfLocators(const ContestName : String) : String;
    function SqlContestMainLocators(const ContestName : String) : String;
    function SqlContestTotals(const ContestName : String) : String;
    function SqlContestDxQsoCount(const ContestName, MyCont : String) : String;
    function SqlContestDxCountryCount(const ContestName, MyCont : String) : String;
    function SqlContestDxPrefixes(const ContestName, MyCont : String) : String;
    function SqlContestHomeCountryCount(const ContestName, MyCont : String) : String;
    function SqlContestHomePrefixes(const ContestName, MyCont : String) : String;
    function SqlContestMsgCountOnBand(const ContestName, Band : String) : String;
    function SqlContestMsgsOnBand(const ContestName, Band : String) : String;
    function SqlQsoRate10 : String;
    function SqlQsoRate60 : String;
    // saving and editing a QSO (dData)
    function SqlInsertQso(const QsoDate, TimeOn, TimeOff, Call : String; const Freq : Currency;
                          const Mode, RstS, RstR, StnName, Qth, QslS, QslR, QslVia, Iota, Pwr, Itu, Waz,
                          Loc, MyLoc, County, Award, Remarks : String; const Adif : Integer;
                          const IdCall, State : String; const QsoDxcc : Integer; const Band : String;
                          const Profile : Integer; const Cont, Club1, Club2, Club3, Club4, Club5,
                          PropMode, Satellite, RxFreq, Srx, Stx, SrxString, StxString, ContestName,
                          Dok, Op : String) : String;
    function SqlUpdateQso(const QsoDate, TimeOn, TimeOff, Call : String; const Freq : Currency;
                          const Mode, RstS, RstR, QslS, QslR, QslVia, Iota, Pwr, Waz, Itu, Loc, MyLoc,
                          County, Remarks : String; const Adif, QsoDxcc : Integer;
                          const StnName, Qth, Award, Band : String; const Profile : Integer;
                          const IdCall, State, Cont, PropMode, Satellite, RxFreq, Stx, StxString,
                          Srx, SrxString, ContestName, Dok, Op : String; const Id : Integer) : String;
    function SqlQslAlreadySent(const Adif : Integer; const Mode : String; const WithCall : Boolean; const Call : String) : String;
    function SqlQsoLocators : String;
    function SqlSquareCountFiltered(const Where : String) : String;
    function SqlSquareCount : String;
    function SqlQsoCountAll : String;
    function SqlQsoAfter(const Call, Band, Mode, LastDate, LastTime : String) : String;
    function SqlQsoAfterParams : String;

    // WAZ / ITU / IOTA "new one" probes (dData)
    function SqlWazCfmOnBand(const Waz, Band : String) : String;
    function SqlWazOnBand(const Waz, Band : String) : String;
    function SqlWazWorked(const Waz : String) : String;
    function SqlItuCfmOnBand(const Itu, Band : String) : String;
    function SqlItuOnBand(const Itu, Band : String) : String;
    function SqlItuWorked(const Itu : String) : String;
    function SqlIotaCfm(const Iota : String) : String;
    function SqlIotaWorked(const Iota : String) : String;

    // previous QSOs and the spot line (fNewQSO)
    function SqlRecentQsos(const Since : String) : String;
    function SqlQsosWithCall(const Call : String) : String;
    function SqlQsosWithIdCall(const IdCall : String) : String;
    function SqlQsosWithCallForEntry(const Call : String) : String;
    function SqlLastQsoForSpot : String;
    function SqlLastQsoDetailsForSpot : String;

    // club QSL probes (fQSODetails)
    function SqlClubQsoCfm(const Num : Integer; const ClubNr, FromDate, ToDate, Band, Mode : String) : String;
    function SqlClubQsoOnBandMode(const Num : Integer; const ClubNr, FromDate, ToDate, Band, Mode : String) : String;
    function SqlClubQsoOnBand(const Num : Integer; const ClubNr, FromDate, ToDate, Band : String) : String;
    function SqlClubQso(const Num : Integer; const ClubNr, FromDate, ToDate : String) : String;

    // group edit, edit details, callbook update
    function SqlQsoForDxccCheck(const Id : Integer) : String;
    function SqlSetQsoFieldsGroup(const SetList : String; const Id : Integer) : String;
    function SqlSetQsoFields(const SetList : String; const Id : Integer) : String;
    function SqlLastNameForCall(const Call : String) : String;
    function SqlUpdateQsoFromCallbook(const StnName, Qth, QslVia, County, Award, State, Remarks, Iota, Waz, Itu : String; const Id : Integer) : String;
  end;

var
  dmSqlQso : TdmSqlQso;

implementation

{$R *.lfm}

{ main grid paging }

// The grid shows Limit rows at a time (cDB_LIMIT).  "First page" is the
// newest QSOs (the views order by date descending) or the callsigns from
// A; "last page" the oldest / from Z, re-ordered so the grid reads the
// same way.  The same select is opened from several places -- Ctrl+Home,
// scrolling past the first row, a refresh, the sort window -- and each
// keeps its own builder for the SQL inventory; the merge pass collapses
// them.

function TdmSqlQso.SqlDeleteQso(const Id : Integer) : String;
begin
  Result := 'DELETE FROM cqrlog_main WHERE id_cqrlog_main = ' + IntToStr(Id)
end;

// IdList is the comma-separated list of selected ids.
function TdmSqlQso.SqlQsosByIds(const IdList : String) : String;
begin
  Result := 'SELECT * FROM view_cqrlog_main_by_qsodate where id_cqrlog_main in (' + IdList + ')'
end;

function TdmSqlQso.SqlLastPageByDate(const Limit : Integer) : String;
begin
  Result := 'select * from (select * from view_cqrlog_main_by_qsodate order by qsodate, time_on LIMIT '+IntToStr(Limit)+
            ') as foo order by qsodate DESC,time_on DESC'
end;

function TdmSqlQso.SqlLastPageByCall(const Limit : Integer) : String;
begin
  Result := 'select * from (select * from view_cqrlog_main_by_callsign order by callsign DESC LIMIT '+IntToStr(Limit)+') as foo order by callsign'
end;

function TdmSqlQso.SqlLastPageByDateAfterDown(const Limit : Integer) : String;
begin
  Result := 'select * from (select * from view_cqrlog_main_by_qsodate order by qsodate, time_on LIMIT '+
            IntToStr(Limit)+') as foo order by qsodate DESC,time_on DESC'
end;

function TdmSqlQso.SqlLastPageByCallAfterDown(const Limit : Integer) : String;
begin
  Result := 'select * from (select * from view_cqrlog_main_by_callsign order by callsign DESC LIMIT '+
            IntToStr(Limit)+') as foo order by callsign'
end;

function TdmSqlQso.SqlFirstPageByDate(const Limit : Integer) : String;
begin
  Result := 'select * from view_cqrlog_main_by_qsodate LIMIT '+IntToStr(Limit)
end;

function TdmSqlQso.SqlFirstPageByCall(const Limit : Integer) : String;
begin
  Result := 'select * from view_cqrlog_main_by_callsign LIMIT '+IntToStr(Limit)
end;

function TdmSqlQso.SqlFirstPageByDateAfterUp(const Limit : Integer) : String;
begin
  Result := 'select * from view_cqrlog_main_by_qsodate LIMIT '+IntToStr(Limit)
end;

function TdmSqlQso.SqlFirstPageByCallAfterUp(const Limit : Integer) : String;
begin
  Result := 'select * from view_cqrlog_main_by_callsign LIMIT '+IntToStr(Limit)
end;

function TdmSqlQso.SqlFirstPageByDateOnRefresh(const Limit : Integer) : String;
begin
  Result := 'select * from view_cqrlog_main_by_qsodate LIMIT '+IntToStr(Limit)
end;

function TdmSqlQso.SqlFirstPageByDateOffset0(const Limit : Integer) : String;
begin
  Result := 'select * from view_cqrlog_main_by_qsodate LIMIT '+IntToStr(Limit)+' OFFSET 0'
end;

function TdmSqlQso.SqlFirstPageByDateSorted(const Limit : Integer) : String;
begin
  Result := 'select * from view_cqrlog_main_by_qsodate LIMIT '+IntToStr(Limit)
end;

function TdmSqlQso.SqlFirstPageByDateAsc(const Limit : Integer) : String;
begin
  Result := 'select * from view_cqrlog_main_by_qsodate_asc LIMIT '+IntToStr(Limit)
end;

function TdmSqlQso.SqlFirstPageByCallSorted(const Limit : Integer) : String;
begin
  Result := 'select * from view_cqrlog_main_by_callsign LIMIT '+IntToStr(Limit)
end;

function TdmSqlQso.SqlFirstQsoIdByDate : String;
begin
  Result := 'select id_cqrlog_main from view_cqrlog_main_by_qsodate LIMIT 1'
end;

function TdmSqlQso.SqlFirstQsoIdByCall : String;
begin
  Result := 'select id_cqrlog_main from view_cqrlog_main_by_callsign LIMIT 1'
end;

function TdmSqlQso.SqlOldestQsoId : String;
begin
  Result := 'select id_cqrlog_main from cqrlog_main order by qsodate,time_on LIMIT 1'
end;

function TdmSqlQso.SqlLastQsoIdByCall : String;
begin
  Result := 'select id_cqrlog_main from cqrlog_main order by callsign DESC LIMIT 1'
end;

// QsoDate arrives already formatted by the caller (DateToStr), Time as the
// grid shows it.
function TdmSqlQso.SqlCountNewerByDate(const QsoDate, Time : String; const Limit : Integer) : String;
begin
  Result := 'select count(*) from (select * from cqrlog_main where (qsodate = '+QuotedStr(QsoDate)+
            'and time_on >= '+QuotedStr(Time)+') or qsodate > '+QuotedStr(QsoDate)+
            ' order by qsodate, time_on LIMIT '+IntToStr(Limit)+') as foo order by qsodate DESC,time_on DESC'
end;

function TdmSqlQso.SqlCountBeforeByCall(const Call : String; const Limit : Integer) : String;
begin
  Result := 'select count(*) from (select * from cqrlog_main where callsign <= ' +QuotedStr(Call)+
            ' order by callsign DESC LIMIT '+IntToStr(Limit)+') as foo order by callsign'
end;

function TdmSqlQso.SqlPageNewerByDate(const QsoDate, Time : String; const Limit : Integer) : String;
begin
  Result := 'select * from (select * from view_cqrlog_main_by_qsodate where (qsodate = '+QuotedStr(QsoDate)+
            'and time_on >= '+QuotedStr(Time)+') or qsodate > '+QuotedStr(QsoDate)+
            ' order by qsodate, time_on LIMIT '+IntToStr(Limit)+') as foo order by qsodate DESC,time_on DESC'
end;

function TdmSqlQso.SqlPageBeforeByCall(const Call : String; const Limit : Integer) : String;
begin
  Result := 'select * from (select * from view_cqrlog_main_by_callsign where callsign <= '+QuotedStr(Call) +
            ' order by callsign DESC LIMIT ' + IntToStr(Limit) + ') as foo order by callsign'
end;

function TdmSqlQso.SqlCountOlderByDate(const QsoDate, Time : String; const Limit : Integer) : String;
begin
  Result := 'select count(*) from cqrlog_main where (qsodate = '+QuotedStr(QsoDate)+
            'and time_on <= '+QuotedStr(Time)+') or qsodate < '+QuotedStr(QsoDate)+
            ' order by qsodate DESC, time_on DESC LIMIT '+IntToStr(Limit)
end;

function TdmSqlQso.SqlCountAfterByCall(const Call : String; const Limit : Integer) : String;
begin
  Result := 'select count(*) from cqrlog_main where callsign >= '+QuotedStr(Call)+
            ' order by callsign LIMIT '+IntToStr(Limit)
end;

function TdmSqlQso.SqlPageOlderByDate(const QsoDate, Time : String; const Limit : Integer) : String;
begin
  Result := 'select * from view_cqrlog_main_by_qsodate where (qsodate = '+QuotedStr(QsoDate)+
            'and time_on <= '+QuotedStr(Time)+') or qsodate < '+QuotedStr(QsoDate)+
            ' LIMIT '+IntToStr(Limit)
end;

function TdmSqlQso.SqlPageAfterByCall(const Call : String; const Limit : Integer) : String;
begin
  Result := 'select * from view_cqrlog_main_by_callsign where (callsign >= '+QuotedStr(Call)+
            ') LIMIT '+IntToStr(Limit)
end;

// The contest filter: the name goes in between double quotes as it always
// did, unescaped.
function TdmSqlQso.SqlQsosOfContest(const ContestName : String) : String;
begin
  Result := 'SELECT * FROM view_cqrlog_main_by_qsodate WHERE `contestname` = "' + ContestName + '"'
end;

{ contest window }

function TdmSqlQso.SqlLastSrxString : String;
begin
  Result := 'SELECT srx_string FROM cqrlog_main ORDER BY qsodate DESC, time_on DESC LIMIT 1'
end;

function TdmSqlQso.SqlContestSuffixEnds(const ContestName, Band : String) : String;
begin
  Result := 'SELECT ASCII(MID(callsign,LENGTH(callsign),1)) AS SuffixEnd FROM cqrlog_main WHERE contestname='+
            QuotedStr(ContestName)+' AND band='+QuotedStr(Band)+' AND mode='+QuotedStr('CW')
end;

function TdmSqlQso.SqlContestVhfQsoCount(const ContestName : String) : String;
begin
  Result := 'SELECT  COUNT(callsign) AS Qcount FROM cqrlog_main WHERE contestname='+ QuotedStr(ContestName)+
            ' AND freq > 27.99999'
end;

function TdmSqlQso.SqlContestVhfLocators(const ContestName : String) : String;
begin
  Result := 'SELECT  my_loc,loc,band FROM cqrlog_main WHERE contestname='+ QuotedStr(ContestName)+
            ' AND freq > 27.99999'
end;

function TdmSqlQso.SqlContestMainLocators(const ContestName : String) : String;
begin
  Result := 'SELECT DISTINCT(SUBSTRING(UPPER(loc),1,4)) AS MainLoc FROM cqrlog_main WHERE contestname='+
            QuotedStr(ContestName)+' ORDER BY MainLoc ASC'
end;

function TdmSqlQso.SqlContestTotals(const ContestName : String) : String;
begin
  Result := 'SELECT COUNT(callsign) AS QSOs, COUNT(DISTINCT(adif)) AS Countries,'+
            'COUNT(DISTINCT(UPPER(srx_string))) AS Msgs FROM cqrlog_main WHERE contestname='+
            QuotedStr(ContestName)
end;

function TdmSqlQso.SqlContestDxQsoCount(const ContestName, MyCont : String) : String;
begin
  Result := 'SELECT COUNT(callsign) AS DXs  FROM cqrlog_main WHERE contestname='+
            QuotedStr(ContestName)+' AND cont<>'+QuotedStr(MyCont)
end;

function TdmSqlQso.SqlContestDxCountryCount(const ContestName, MyCont : String) : String;
begin
  Result := 'SELECT COUNT(DISTINCT(adif)) AS DXCntrs  FROM cqrlog_main WHERE contestname='+
            QuotedStr(ContestName)+' AND cont<>'+QuotedStr(MyCont)
end;

function TdmSqlQso.SqlContestDxPrefixes(const ContestName, MyCont : String) : String;
begin
  Result := 'SELECT DISTINCT(pref) FROM cqrlog_common.dxcc_ref RIGHT JOIN cqrlog_main ON '+
            'cqrlog_common.dxcc_ref.adif = cqrlog_main.adif WHERE contestname='+
            QuotedStr(ContestName)+' AND cqrlog_main.cont<>'+QuotedStr(MyCont)
            +' ORDER BY cqrlog_common.dxcc_ref.pref ASC'
end;

function TdmSqlQso.SqlContestHomeCountryCount(const ContestName, MyCont : String) : String;
begin
  Result := 'SELECT COUNT(DISTINCT(adif)) AS MYCntrs  FROM cqrlog_main WHERE contestname='+
            QuotedStr(ContestName)+' AND cont='+QuotedStr(MyCont)
end;

function TdmSqlQso.SqlContestHomePrefixes(const ContestName, MyCont : String) : String;
begin
  Result := 'SELECT DISTINCT(pref) FROM cqrlog_common.dxcc_ref RIGHT JOIN cqrlog_main ON '+
            'cqrlog_common.dxcc_ref.adif = cqrlog_main.adif WHERE contestname='+
            QuotedStr(ContestName)+' AND cqrlog_main.cont='+QuotedStr(MyCont)
            +' ORDER BY cqrlog_common.dxcc_ref.pref ASC'
end;

function TdmSqlQso.SqlContestMsgCountOnBand(const ContestName, Band : String) : String;
begin
  Result := 'SELECT COUNT(DISTINCT(UPPER(srx_string))) AS Msgs FROM cqrlog_main WHERE contestname='+
            QuotedStr(ContestName)+ ' AND band='+QuotedStr(Band)+
            ' AND srx_string<>""'
end;

function TdmSqlQso.SqlContestMsgsOnBand(const ContestName, Band : String) : String;
begin
  Result := 'SELECT DISTINCT(UPPER(srx_string)) AS srx_msg FROM cqrlog_main WHERE contestname='+
            QuotedStr(ContestName)+ ' AND band='+QuotedStr(Band)
            +' ORDER BY srx_msg ASC'
end;

function TdmSqlQso.SqlQsoRate10 : String;
begin
  Result := 'select count(callsign) as rate from cqrlog_main where timestampdiff(minute,concat(qsodate," ",time_off),utc_timestamp())<10'
end;

function TdmSqlQso.SqlQsoRate60 : String;
begin
  Result := 'select count(callsign) as rate from cqrlog_main where timestampdiff(minute,concat(qsodate," ",time_off),utc_timestamp())<60'
end;

{ saving and editing a QSO }

// The callers pass the values as SaveQSO / EditQSO prepared them (trimmed,
// locators normalised, ITU/WAZ/rxfreq already as text); the builder only
// quotes and joins, exactly as the statement was assembled before.
function TdmSqlQso.SqlInsertQso(const QsoDate, TimeOn, TimeOff, Call : String; const Freq : Currency;
                          const Mode, RstS, RstR, StnName, Qth, QslS, QslR, QslVia, Iota, Pwr, Itu, Waz,
                          Loc, MyLoc, County, Award, Remarks : String; const Adif : Integer;
                          const IdCall, State : String; const QsoDxcc : Integer; const Band : String;
                          const Profile : Integer; const Cont, Club1, Club2, Club3, Club4, Club5,
                          PropMode, Satellite, RxFreq, Srx, Stx, SrxString, StxString, ContestName,
                          Dok, Op : String) : String;
begin
  Result := 'insert into cqrlog_main (qsodate,time_on,time_off,callsign,freq,mode,'+
            'rst_s,rst_r,name,qth,qsl_s,qsl_r,qsl_via,iota,pwr,itu,waz,loc,my_loc,'+
            'county,award,remarks,adif,idcall,state,qso_dxcc,band,profile,cont,club_nr1,'+
            'club_nr2,club_nr3,club_nr4,club_nr5, prop_mode, satellite, rxfreq, srx, stx,'+
            'srx_string, stx_string, contestname, dok, operator) values('+QuotedStr(QsoDate) +
            ','+QuotedStr(TimeOn)+','+QuotedStr(TimeOff)+
            ','+QuotedStr(Call)+','+FloatToStr(Freq)+
            ','+QuotedStr(Mode)+','+QuotedStr(RstS)+
            ','+QuotedStr(RstR)+','+QuotedStr(StnName)+
            ','+QuotedStr(Qth)+','+QuotedStr(QslS)+
            ','+QuotedStr(QslR)+','+QuotedStr(QslVia)+
            ','+QuotedStr(Iota)+','+QuotedStr(Pwr)+
            ','+Itu+','+Waz+
            ','+QuotedStr(Loc)+','+QuotedStr(MyLoc)+
            ','+QuotedStr(County)+',' + QuotedStr(Award) + ','+QuotedStr(Remarks)+
            ','+IntToStr(Adif)+','+ QuotedStr(IdCall) + ','+ QuotedStr(State) +','+IntToStr(QsoDxcc)+
            ','+QuotedStr(Band)+','+ IntToStr(Profile) +','+QuotedStr(Cont)+
            ','+QuotedStr(Club1)+','+QuotedStr(Club2)+','+QuotedStr(Club3)+
            ','+QuotedStr(Club4)+','+QuotedStr(Club5)+','+QuotedStr(PropMode)+','+QuotedStr(Satellite)+','+RxFreq+
            ','+QuotedStr(Srx)+','+QuotedStr(Stx)+','+QuotedStr(SrxString)+','+QuotedStr(StxString)+','+QuotedStr(ContestName)+
            ','+QuotedStr(Dok);
  if (Op <> '') then
     Result := Result+','+QuotedStr(Op)+')'
  else
     Result := Result+', NULL)'
end;

function TdmSqlQso.SqlUpdateQso(const QsoDate, TimeOn, TimeOff, Call : String; const Freq : Currency;
                          const Mode, RstS, RstR, QslS, QslR, QslVia, Iota, Pwr, Waz, Itu, Loc, MyLoc,
                          County, Remarks : String; const Adif, QsoDxcc : Integer;
                          const StnName, Qth, Award, Band : String; const Profile : Integer;
                          const IdCall, State, Cont, PropMode, Satellite, RxFreq, Stx, StxString,
                          Srx, SrxString, ContestName, Dok, Op : String; const Id : Integer) : String;
begin
  Result := 'UPDATE cqrlog_main set qsodate = '+ QuotedStr(QsoDate) +', time_on = '+QuotedStr(TimeOn) +
            ', time_off = ' + QuotedStr(TimeOff) + ', callsign = '+QuotedStr(Call) +
            ', freq = ' + FloatToStr(Freq) + ', mode = ' + QuotedStr(Mode) +
            ', rst_s = ' + QuotedStr(RstS) + ', rst_r = ' + QuotedStr(RstR)+ ', qsl_s = '+QuotedStr(QslS)+
            ', qsl_r =' + QuotedStr(QslR) + ', qsl_via = ' + QuotedStr(QslVia) + ', iota = ' + QuotedStr(Iota)+
            ', pwr = ' + QuotedStr(Pwr) + ', waz = ' + Waz +
            ', itu = ' + Itu + ', loc = ' + QuotedStr(Loc) +
            ', my_loc = ' + QuotedStr(MyLoc) + ', county = ' + QuotedStr(County) +
            ', remarks = ' + QuotedStr(Remarks) + ', adif = ' + IntToStr(Adif) +
            ', qso_dxcc = '+ IntToStr(QsoDxcc) + ', name = ' +QuotedStr(StnName) +
            ', qth = ' + QuotedStr(Qth) + ', award = ' + QuotedStr(Award) +', band = ' + QuotedStr(Band) +
            ', profile = ' + IntToStr(Profile) + ', idcall = ' + QuotedStr(IdCall) + ', state=' + QuotedStr(State) +
            ', cont = ' + QuotedStr(Cont)+ ', prop_mode = ' + QuotedStr(PropMode) + ', satellite = ' + QuotedStr(Satellite)+
            ', rxfreq = ' + RxFreq + ', stx = ' + QuotedStr(Stx)+ ', stx_string = ' + QuotedStr(StxString) + ', srx = ' + QuotedStr(Srx)+
            ', srx_string = ' + QuotedStr(SrxString) + ', contestname = ' + QuotedStr(ContestName) + ', dok = ' + QuotedStr(Dok);
  if (Op <> '') then
    Result := Result+', operator = ' + QuotedStr(Op)
  else
    Result := Result+', operator = NULL';
  Result := Result+' where id_cqrlog_main = ' + IntToStr(Id)
end;

// WithCall narrows the probe to this callsign (the "auto QSL for this
// call" setting); without it any QSO with the entity and mode counts.
function TdmSqlQso.SqlQslAlreadySent(const Adif : Integer; const Mode : String; const WithCall : Boolean; const Call : String) : String;
begin
  Result := 'select id_cqrlog_main from cqrlog_main where adif = '+
            IntToStr(Adif)+' and mode='+QuotedStr(Mode)+' and qsl_s<>'+QuotedStr('');
  if WithCall then
    Result := Result +  ' and callsign='+QuotedStr(Call);
  Result := Result + ' LIMIT 1'
end;

function TdmSqlQso.SqlQsoLocators : String;
begin
  Result := 'SELECT my_loc,loc FROM cqrlog_main'
end;

// Where is what follows WHERE in the grid's current query.
function TdmSqlQso.SqlSquareCountFiltered(const Where : String) : String;
begin
  Result := 'SELECT COUNT(DISTINCT(LEFT(loc,4))) FROM view_cqrlog_main_by_qsodate WHERE left(loc,4) <> "" AND '
            + Where
end;

function TdmSqlQso.SqlSquareCount : String;
begin
  Result := 'SELECT COUNT(DISTINCT(LEFT(loc,4))) FROM cqrlog_main WHERE left(loc,4) <> "" '
end;

// Same statement as dSqlImpExp.SqlQsoCount.  Kept separate so this
// extraction leaves the SQL inventory untouched; the merge pass collapses
// them.
function TdmSqlQso.SqlQsoCountAll : String;
begin
  Result := 'SELECT COUNT(*) FROM cqrlog_main'
end;

// qsodate and time_on are text columns, hence the str_to_date dance
// (see the note in dData.CallExistsInLog).
function TdmSqlQso.SqlQsoAfter(const Call, Band, Mode, LastDate, LastTime : String) : String;
begin
  Result := 'select id_cqrlog_main from cqrlog_main where (callsign= '+QuotedStr(Call)+') and (band = '+QuotedStr(Band)+') '+
            'and (mode = '+QuotedStr(Mode)+') and (str_to_date(concat(qsodate,'+QuotedStr(' ')+',time_on), '+
            QuotedStr('%Y-%m-%d %H:%i')+')) > str_to_date('+QuotedStr(LastDate+' '+LastTime)+', '+QuotedStr('%Y-%m-%d %H:%i')+')'
end;

function TdmSqlQso.SqlQsoAfterParams : String;
begin
  Result := 'select id_cqrlog_main from cqrlog_main where (callsign= :callsign) and (band = :band) '+
            'and (mode = :mode) and (str_to_date(concat(qsodate, '+QuotedStr(' ')+',time_on), '+
            QuotedStr('%Y-%m-%d %H:%i')+')) > str_to_date(:last_date_time, '+QuotedStr('%Y-%m-%d %H:%i')+')'
end;

{ WAZ / ITU / IOTA probes }

function TdmSqlQso.SqlWazCfmOnBand(const Waz, Band : String) : String;
begin
  Result := 'select id_cqrlog_main FROM cqrlog_main WHERE waz = ' + Waz +
            ' AND band = ' + QuotedStr(Band) +
            ' AND ( QSL_R = ' + QuotedStr('Q')+ ' OR lotw_qslr= ' + QuotedStr('L')+
            ' OR eqsl_qsl_rcvd= ' + QuotedStr('E')+
            ') LIMIT 1'
end;

function TdmSqlQso.SqlWazOnBand(const Waz, Band : String) : String;
begin
  Result := 'select id_cqrlog_main FROM cqrlog_main WHERE waz = ' + Waz +
            ' AND band = ' + QuotedStr(Band) + ' LIMIT 1'
end;

function TdmSqlQso.SqlWazWorked(const Waz : String) : String;
begin
  Result := 'select id_cqrlog_main FROM cqrlog_main WHERE waz = ' + Waz+
            ' LIMIT 1'
end;

function TdmSqlQso.SqlItuCfmOnBand(const Itu, Band : String) : String;
begin
  Result := 'select id_cqrlog_main FROM cqrlog_main WHERE itu = ' + Itu +
            ' AND band = ' + QuotedStr(Band) +
            ' AND ( QSL_R = ' + QuotedStr('Q')+ ' OR lotw_qslr= ' + QuotedStr('L')+
            ' ) LIMIT 1'
end;

function TdmSqlQso.SqlItuOnBand(const Itu, Band : String) : String;
begin
  Result := 'select id_cqrlog_main FROM cqrlog_main WHERE itu = ' + Itu +
            ' AND band = ' + QuotedStr(Band)+' LIMIT 1'
end;

function TdmSqlQso.SqlItuWorked(const Itu : String) : String;
begin
  Result := 'select id_cqrlog_main FROM cqrlog_main WHERE itu = ' + Itu+
            ' LIMIT 1'
end;

function TdmSqlQso.SqlIotaCfm(const Iota : String) : String;
begin
  Result := 'SELECT MAX(id_cqrlog_main) FROM cqrlog_main WHERE iota = ' + QuotedStr(Iota) +
            ' AND QSL_R = ' + QuotedStr('Q')
end;

function TdmSqlQso.SqlIotaWorked(const Iota : String) : String;
begin
  Result := 'SELECT MAX(id_cqrlog_main) FROM cqrlog_main WHERE iota = ' +
            QuotedStr(Iota)
end;

{ previous QSOs and the spot line }

function TdmSqlQso.SqlRecentQsos(const Since : String) : String;
begin
  Result := 'select * from view_cqrlog_main_by_qsodate where qsodate >= '+QuotedStr(Since)+
            ' order by qsodate,time_on'
end;

function TdmSqlQso.SqlQsosWithCall(const Call : String) : String;
begin
  Result := 'SELECT * FROM view_cqrlog_main_by_qsodate WHERE callsign = '+
            QuotedStr(Call)+' ORDER BY qsodate,time_on'
end;

function TdmSqlQso.SqlQsosWithIdCall(const IdCall : String) : String;
begin
  Result := 'SELECT * FROM view_cqrlog_main_by_qsodate WHERE idcall = '+
            QuotedStr(IdCall)+' ORDER BY qsodate,time_on'
end;

// Same statement as SqlQsosWithCall, opened while the callsign is being
// typed.  Kept separate -- see the note on SqlQsoCountAll.
function TdmSqlQso.SqlQsosWithCallForEntry(const Call : String) : String;
begin
  Result := 'SELECT * FROM view_cqrlog_main_by_qsodate WHERE callsign = '+
            QuotedStr(Call)+' ORDER BY qsodate,time_on'
end;

function TdmSqlQso.SqlLastQsoForSpot : String;
begin
  Result := 'SELECT callsign,freq,rxfreq FROM cqrlog_main ORDER BY qsodate DESC, time_on DESC LIMIT 1'
end;

function TdmSqlQso.SqlLastQsoDetailsForSpot : String;
begin
  Result := 'SELECT mode,rst_s,loc,prop_mode,my_loc,stx,stx_string,srx,srx_string,name FROM cqrlog_main ORDER BY qsodate DESC, time_on DESC LIMIT 1'
end;

{ club QSL probes }

// Num picks the club_nr<N> column; the membership dates bound the QSOs.
function TdmSqlQso.SqlClubQsoCfm(const Num : Integer; const ClubNr, FromDate, ToDate, Band, Mode : String) : String;
begin
  Result := 'select id_cqrlog_main from cqrlog_main where club_nr'+ IntToStr(Num) +
            ' = '+QuotedStr(ClubNr) + ' and qsodate >= ' + QuotedStr(FromDate) +
            ' and qsodate <= ' + QuotedStr(ToDate) + ' and band = ' +
            QuotedStr(Band) + ' and mode = ' +
            QuotedStr(Mode) + ' and qsl_r = '+QuotedStr('Q')+' LIMIT 1'
end;

function TdmSqlQso.SqlClubQsoOnBandMode(const Num : Integer; const ClubNr, FromDate, ToDate, Band, Mode : String) : String;
begin
  Result := 'select id_cqrlog_main from cqrlog_main where club_nr'+ IntToStr(Num) +
            ' = '+QuotedStr(ClubNr) + ' and qsodate >= ' + QuotedStr(FromDate) +
            ' and qsodate <= ' + QuotedStr(ToDate) + ' and band = ' +
            QuotedStr(Band) + 'and mode = ' +
            QuotedStr(Mode)+' LIMIT 1'
end;

function TdmSqlQso.SqlClubQsoOnBand(const Num : Integer; const ClubNr, FromDate, ToDate, Band : String) : String;
begin
  Result := 'select id_cqrlog_main from cqrlog_main where club_nr'+ IntToStr(Num) +
            ' = '+QuotedStr(ClubNr) + ' and qsodate >= ' + QuotedStr(FromDate) +
            ' and qsodate <= ' + QuotedStr(ToDate) + ' and band = ' +
            QuotedStr(Band) + ' LIMIT 1'
end;

function TdmSqlQso.SqlClubQso(const Num : Integer; const ClubNr, FromDate, ToDate : String) : String;
begin
  Result := 'select id_cqrlog_main from cqrlog_main where club_nr'+ IntToStr(Num) +
            ' = '+QuotedStr(ClubNr) + ' and qsodate >= ' + QuotedStr(FromDate) +
            ' and qsodate <= ' + QuotedStr(ToDate) +' LIMIT 1'
end;

{ group edit, edit details, callbook update }

function TdmSqlQso.SqlQsoForDxccCheck(const Id : Integer) : String;
begin
  Result := 'select qsodate,freq,mode,qsl_r,lotw_qslr,dxcc_ref from '+
            'cqrlog_main where id_cqrlog_main = ' + IntToStr(Id)
end;

// SetList is the "col = value, .." list the window composes.
function TdmSqlQso.SqlSetQsoFieldsGroup(const SetList : String; const Id : Integer) : String;
begin
  Result := 'update cqrlog_main set '+SetList+' where id_cqrlog_main='+IntToStr(Id)
end;

// Same shape as SqlSetQsoFieldsGroup, from the QSL-dates dialog.  Kept
// separate -- see the note on SqlQsoCountAll.
function TdmSqlQso.SqlSetQsoFields(const SetList : String; const Id : Integer) : String;
begin
  Result := 'update cqrlog_main set '+SetList+
            ' where id_cqrlog_main='+
            IntToStr(Id)
end;

function TdmSqlQso.SqlLastNameForCall(const Call : String) : String;
begin
  Result := 'select max(id_cqrlog_main),callsign,name from cqrlog_main where name <> '+QuotedStr('')+
            ' and callsign = '+QuotedStr(Call)+' group by callsign,name'
end;

function TdmSqlQso.SqlUpdateQsoFromCallbook(const StnName, Qth, QslVia, County, Award, State, Remarks, Iota, Waz, Itu : String; const Id : Integer) : String;
begin
  Result := 'update cqrlog_main set name=' + QuotedStr(
            StnName) + ',qth=' + QuotedStr(Qth) + ',qsl_via=' +
            QuotedStr(QslVia) + ',county=' + QuotedStr(County) +
            ',award=' + QuotedStr(Award) + ',state =' +
            QuotedStr(State) + ',remarks=' + QuotedStr(Remarks) +
            ',iota='+QuotedStr(Iota)+',waz='+QuotedStr(Waz)+',itu='+QuotedStr(Itu)+
            ' where id_cqrlog_main = ' + IntToStr(Id)
end;

end.
