(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

// QSL bookkeeping: the paper, LoTW and eQSL state columns of cqrlog_main,
// the qslexport table the label export stages rows in, and the QSL manager
// list in cqrlog_common.
//
// Builders only.  Every caller still runs these on the cursor it always
// used; this unit says what is asked, not who asks.

unit dSqlQsl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources;

type
  TdmSqlQsl = class(TDataModule)
  private
    function SqlEarlierQsoBase(const FilterWhere : String) : String;
  public
    // paper QSL -- marking (fMarkQSL, fMain, fExLabelPrint)
    function SqlEarlierQsoByDxccBandModeQslQ(const FilterWhere : String; const Adif : Integer; const Mode, Band : String) : String;
    function SqlEarlierQsoByCallBandMode(const FilterWhere, Call, Mode, Band : String) : String;
    function SqlEarlierQsoByDxccBandMode(const FilterWhere : String; const Adif : Integer; const Mode, Band : String) : String;
    function SqlEarlierQsoByCallBand(const FilterWhere, Call, Band : String) : String;
    function SqlEarlierQsoByDxccBand(const FilterWhere : String; const Adif : Integer; const Band : String) : String;
    function SqlEarlierQsoByCall(const FilterWhere, Call : String) : String;
    function SqlEarlierQsoByDxcc(const FilterWhere : String; const Adif : Integer) : String;
    function SqlSetQslS(const QslS : String; const Id : Integer) : String;
    function SqlSetQslS2(const QslS : String; const Id : Integer) : String;
    function SqlSetQslS3(const QslS : String; const Id : Integer) : String;
    function SqlSetQslS4(const QslS : String; const Id : Integer) : String;
    function SqlMarkQslSent(const QslS, Date : String; const Id : Integer) : String;
    function SqlMarkQslReceived(const Date : String; const Id : Integer) : String;
    function SqlMarkQslSentFromLabels(const QslS, Date : String; const Id : Integer) : String;

    // LoTW
    function SqlQsosForLotwAll : String;
    function SqlQsosForLotwNotExported : String;
    function SqlMarkLotwSent(const Date, Id : String) : String;
    function SqlMarkLotwSentAfterExport(const Date, Id : String) : String;
    function SqlMarkAllLotwSent(const Date : String) : String;
    function SqlClearLotwSent(const Id : Integer) : String;

    // eQSL
    function SqlQsosForEqslNotExported : String;
    function SqlQsosForEqslAll : String;
    function SqlMarkEqslSent(const Date, Id : String) : String;
    function SqlMarkAllEqslSent(const Date : String) : String;
    function SqlClearEqslSent(const Id : Integer) : String;

    // qslexport
    function SqlInsertQslExport : String;
    function SqlQslExportRows : String;
    function SqlDropQslExport : String;

    // qslmgr
    function SqlQslManager(const Call, Date : String) : String;
    function SqlQslManagerList : String;
    function SqlQslManagerListForNewQso : String;
  end;

var
  dmSqlQsl : TdmSqlQsl;

implementation

{$R *.lfm}

{ paper QSL }

// fMarkQSL walks the filtered grid and asks, per QSO, whether an earlier QSO
// outside the filter already covers the same call/DXCC (and band, mode).
// FilterWhere is the WHERE clause of the grid's own query.
function TdmSqlQsl.SqlEarlierQsoBase(const FilterWhere : String) : String;
begin
  Result := 'select max(id_cqrlog_main) from  cqrlog_main where (not (' + FilterWhere + ') '
end;

function TdmSqlQsl.SqlEarlierQsoByDxccBandModeQslQ(const FilterWhere : String; const Adif : Integer; const Mode, Band : String) : String;
begin
  Result := SqlEarlierQsoBase(FilterWhere) + ' and adif=' + IntToStr(Adif) + ' and mode = '+QuotedStr(Mode)+
            ' and band='+QuotedStr(Band)+' and qsl_r='+QuotedStr('Q')+')'
end;

function TdmSqlQsl.SqlEarlierQsoByCallBandMode(const FilterWhere, Call, Mode, Band : String) : String;
begin
  Result := SqlEarlierQsoBase(FilterWhere) + ' and callsign=' + QuotedStr(Call) + ' and mode = '+QuotedStr(Mode)+
            ' and band='+QuotedStr(Band)+')'
end;

function TdmSqlQsl.SqlEarlierQsoByDxccBandMode(const FilterWhere : String; const Adif : Integer; const Mode, Band : String) : String;
begin
  Result := SqlEarlierQsoBase(FilterWhere) + ' and adif=' + IntToStr(Adif) + ' and mode = '+QuotedStr(Mode)+
            ' and band='+QuotedStr(Band)+')'
end;

function TdmSqlQsl.SqlEarlierQsoByCallBand(const FilterWhere, Call, Band : String) : String;
begin
  Result := SqlEarlierQsoBase(FilterWhere) + ' and callsign=' + QuotedStr(Call) + ' and band='+QuotedStr(Band)+')'
end;

function TdmSqlQsl.SqlEarlierQsoByDxccBand(const FilterWhere : String; const Adif : Integer; const Band : String) : String;
begin
  Result := SqlEarlierQsoBase(FilterWhere) + ' and adif=' + IntToStr(Adif) + ' and band='+QuotedStr(Band)+')'
end;

function TdmSqlQsl.SqlEarlierQsoByCall(const FilterWhere, Call : String) : String;
begin
  Result := SqlEarlierQsoBase(FilterWhere) + ' and callsign=' + QuotedStr(Call)+')'
end;

function TdmSqlQsl.SqlEarlierQsoByDxcc(const FilterWhere : String; const Adif : Integer) : String;
begin
  Result := SqlEarlierQsoBase(FilterWhere) + ' and adif=' + IntToStr(Adif)+')'
end;

// One statement, four copies -- one per branch of TfrmMarkQSL.btnOKClick
// (first QSO, first band, first band/mode, first band/mode with QSL
// received).  Kept separate so this extraction leaves the SQL inventory
// (tools/sql-inventory) untouched; the merge pass collapses them.
function TdmSqlQsl.SqlSetQslS(const QslS : String; const Id : Integer) : String;
begin
  Result := 'update cqrlog_main set qsl_s=' + QuotedStr(QslS) + ' where id_cqrlog_main = ' + IntToStr(Id)
end;

function TdmSqlQsl.SqlSetQslS2(const QslS : String; const Id : Integer) : String;
begin
  Result := 'update cqrlog_main set qsl_s=' + QuotedStr(QslS) + ' where id_cqrlog_main = ' + IntToStr(Id)
end;

function TdmSqlQsl.SqlSetQslS3(const QslS : String; const Id : Integer) : String;
begin
  Result := 'update cqrlog_main set qsl_s=' + QuotedStr(QslS) + ' where id_cqrlog_main = ' + IntToStr(Id)
end;

function TdmSqlQsl.SqlSetQslS4(const QslS : String; const Id : Integer) : String;
begin
  Result := 'update cqrlog_main set qsl_s=' + QuotedStr(QslS) + ' where id_cqrlog_main = ' + IntToStr(Id)
end;

function TdmSqlQsl.SqlMarkQslSent(const QslS, Date : String; const Id : Integer) : String;
begin
  Result := 'UPDATE cqrlog_main SET qsl_s = ' + QuotedStr(QslS) +
            ', qsls_date = '+ QuotedStr(Date) +
            ' WHERE id_cqrlog_main = ' + IntToStr(Id)
end;

function TdmSqlQsl.SqlMarkQslReceived(const Date : String; const Id : Integer) : String;
begin
  Result := 'UPDATE cqrlog_main SET qsl_r = ' + QuotedStr('Q') +
            ', qslr_date = '+ QuotedStr(Date) +
            ' WHERE id_cqrlog_main = ' + IntToStr(Id)
end;

function TdmSqlQsl.SqlMarkQslSentFromLabels(const QslS, Date : String; const Id : Integer) : String;
begin
  Result := 'update cqrlog_main set qsl_s ='+QuotedStr(QslS)  +
            ', qsls_date = '+ QuotedStr(Date) +
            ' where id_cqrlog_main='+IntToStr(Id)
end;

{ LoTW }

function TdmSqlQsl.SqlQsosForLotwAll : String;
begin
  Result := 'select * from cqrlog_main'
end;

function TdmSqlQsl.SqlQsosForLotwNotExported : String;
begin
  Result := 'select * from cqrlog_main where lotw_qslsdate is null'
end;

function TdmSqlQsl.SqlMarkLotwSent(const Date, Id : String) : String;
begin
  Result := 'update cqrlog_main set lotw_qsls = ' + QuotedStr('Y') +
            ',lotw_qslsdate = ' + QuotedStr(Date) + 'where id_cqrlog_main = '+ Id
end;

// Same update as SqlMarkLotwSent; the tail differs by one space, which the
// inventory does not see.  Kept separate -- see the note on SqlSetQslS.
function TdmSqlQsl.SqlMarkLotwSentAfterExport(const Date, Id : String) : String;
begin
  Result := 'update cqrlog_main set lotw_qsls = ' + QuotedStr('Y') +
            ',lotw_qslsdate = ' + QuotedStr(Date) + ' where id_cqrlog_main = '+ Id
end;

function TdmSqlQsl.SqlMarkAllLotwSent(const Date : String) : String;
const
  C_UPD = 'update cqrlog_main set lotw_qsls = %s, lotw_qslsdate = %s where (lotw_qsls="" and lotw_qslsdate is NULL)';
begin
  Result := Format(C_UPD,[QuotedStr('Y'),QuotedStr(Date)])
end;

function TdmSqlQsl.SqlClearLotwSent(const Id : Integer) : String;
const
  C_UPD = 'update cqrlog_main set lotw_qsls=%s,lotw_qslsdate=NULL where id_cqrlog_main=%d';
begin
  Result := Format(C_UPD,[QuotedStr(''),Id])
end;

{ eQSL }

function TdmSqlQsl.SqlQsosForEqslNotExported : String;
begin
  Result := 'select id_cqrlog_main,qsodate,time_on,callsign,mode,band,freq,rst_s,rst_r,remarks, satellite, prop_mode, rxfreq '+
            'from cqrlog_main where eqsl_qslsdate is null'
end;

function TdmSqlQsl.SqlQsosForEqslAll : String;
begin
  Result := 'select id_cqrlog_main,qsodate,time_on,callsign,mode,band,freq,rst_s,rst_r,remarks, satellite, prop_mode, rxfreq '+
            'from cqrlog_main'
end;

function TdmSqlQsl.SqlMarkEqslSent(const Date, Id : String) : String;
begin
  Result := 'update cqrlog_main set eqsl_qsl_sent = ' + QuotedStr('Y') +
            ',eqsl_qslsdate = ' + QuotedStr(Date) + 'where id_cqrlog_main = '+ Id
end;

function TdmSqlQsl.SqlMarkAllEqslSent(const Date : String) : String;
const
  C_UPD = 'update cqrlog_main set eqsl_qsl_sent = %s,eqsl_qslsdate=%s where (eqsl_qsl_sent="" and eqsl_qslsdate is NULL)';
begin
  Result := Format(C_UPD,[QuotedStr('Y'),QuotedStr(Date)])
end;

function TdmSqlQsl.SqlClearEqslSent(const Id : Integer) : String;
const
  C_UPD = 'update cqrlog_main set eqsl_qsl_sent=%s,eqsl_qslsdate=NULL where id_cqrlog_main=%d';
begin
  Result := Format(C_UPD,[QuotedStr(''),Id])
end;

{ qslexport }

function TdmSqlQsl.SqlInsertQslExport : String;
begin
  Result := 'insert into qslexport (idcall,id_cqrlog_main,dxcc,qsodate,time_on,time_off,callsign,freq,mode,rst_s,rst_r, '+
            'name,qth,qsl_s,qsl_r,qsl_via,iota,pwr,loc,my_loc,award,remarks,band,qslmsg,prop_mode,satellite,'+
            'contestname,stx,stx_string,srx,srx_string) values('+
            ':idcall,:id_cqrlog_main,:dxcc,:qsodate,:time_on,:time_off,:callsign,:freq,:mode,:rst_s,:rst_r,:name,'+
            ':qth,:qsl_s,:qsl_r,:qsl_via,:iota,:pwr,:loc,:my_loc,:award,:remarks,:band,:qslmsg,:prop_mode,:satellite,'+
            ':contestname,:stx,:stx_string,:srx,:srx_string)'
end;

function TdmSqlQsl.SqlQslExportRows : String;
begin
  Result := 'select * from qslexport order by dxcc,idcall'
end;

function TdmSqlQsl.SqlDropQslExport : String;
const
  C_SQL = 'DROP TABLE qslexport';
begin
  Result := C_SQL
end;

{ qslmgr }

function TdmSqlQsl.SqlQslManager(const Call, Date : String) : String;
begin
  Result := 'select * from cqrlog_common.qslmgr where (callsign = '+QuotedStr(Call)+
            ') and (fromDate <= '+QuotedStr(Date)+') order by fromDate'
end;

function TdmSqlQsl.SqlQslManagerList : String;
begin
  Result := 'select callsign,qsl_via,fromdate from cqrlog_common.qslmgr order by callsign,fromDate'
end;

// Same statement as SqlQslManagerList (fMain opens the list from the menu,
// fNewQSO from its button).  Kept separate -- see the note on SqlSetQslS.
function TdmSqlQsl.SqlQslManagerListForNewQso : String;
begin
  Result := 'select callsign,qsl_via,fromdate from cqrlog_common.qslmgr order by callsign,fromDate'
end;

end.
