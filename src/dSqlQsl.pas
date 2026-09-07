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
// Two layers.  The Sql* builders return statement text and nothing else;
// the QSL manager list keeps running on the grid dataset it always had.
// Above the builders sit the operations for what used to run on dmData.Q
// and Q1: the "is there an earlier QSO" probes of the Mark QSL window as
// values, the LoTW, eQSL and label selections as a lent row cursor, and
// the marks as writes.
//
// Three cursors.  FRows is the one lent out (OpenXxxRows ... CloseRows);
// FQ serves scalars and writes that commit on their own; FBatch holds a
// batch -- several writes in one transaction the caller ends with
// CommitBatch or RollbackBatch -- so that a scalar asked meanwhile cannot
// roll the batch back by preparing on top of it.  Marking the selected
// rows of the main window, marking after a LoTW or eQSL upload and
// filling the label staging table are batches, as they were on trQ.

unit dSqlQsl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, sqldb, db, uSqlCursor;

type
  // What the Mark QSL window looks for before it marks a QSO: the same
  // station or entity worked before at all, on this band, on this band
  // and mode, or on this band and mode with the QSL already received.
  TEarlierQso = (eqAny, eqBand, eqBandMode, eqBandModeQslReceived);

  TdmSqlQsl = class(TDataModule)
    procedure DataModuleCreate(Sender : TObject);
  private
    FQ     : TSqlCursor;   // scalars and writes that commit on their own
    FRows  : TSqlCursor;   // lent out by the Open...Rows operations
    FBatch : TSqlCursor;   // several writes in one transaction the caller ends
    function OpenRows(const Sql : String) : TDataSet;
    procedure ExecAlone(const Sql : String);
    procedure ExecInBatch(const Sql : String);
    function SqlEarlierQsoBase(const FilterWhere : String) : String;
  public
    // Wired from TdmData once MainCon exists -- this module is not one of
    // dData's components, so its bulk DataBase assignment does not reach it.
    procedure AttachTo(Connection : TSQLConnection);

    // Mark QSL window (fMarkQSL): ByCall picks the station over the
    // entity; Mode is read for eqBandMode and eqBandModeQslReceived only,
    // Call or Adif for the side ByCall picks.  Each mark commits on its own.
    function  EarlierQsoExists(const What : TEarlierQso; const ByCall : Boolean;
                               const FilterWhere, Call : String; const Adif : Integer;
                               const Band, Mode : String) : Boolean;
    procedure SetQslS(const QslS : String; const Id : Integer);

    // main window: the selected rows are marked as one batch
    procedure MarkQslSent(const QslS, Date : String; const Id : Integer);
    procedure MarkQslReceived(const Date : String; const Id : Integer);

    // LoTW (fLoTWExport): FilterSql is the grid's statement when the
    // export follows the filter, else empty; the marks after an export
    // or upload are one batch, MarkAllLotwSent commits on its own
    function  OpenQsosForLotwRows(const All : Boolean; const FilterSql : String) : TDataSet;
    procedure MarkLotwSent(const Date, Id : String);
    procedure MarkAllLotwSent(const Date : String);

    // eQSL (feQSLUpload), the same shape
    function  OpenQsosForEqslRows(const NotExported : Boolean; const FilterSql : String) : TDataSet;
    procedure MarkEqslSent(const Date, Id : String);
    procedure MarkAllEqslSent(const Date : String);

    // QSL labels (fExLabelPrint): the staging table is filled as one
    // batch -- PrepareQslExportRow lends the parameter list, the window
    // fills it and calls InsertQslExportRow per QSO -- then walked; the
    // marks are a batch too, the drop commits on its own
    function  PrepareQslExportRow : TParams;
    procedure InsertQslExportRow;
    function  OpenQslExportRows : TDataSet;
    procedure MarkQslSentFromLabels(const QslS, Date : String; const Id : Integer);
    procedure DropQslExportTable;

    // The batch is the writes marked so above, in one transaction; the
    // caller ends it with one of these.
    procedure CommitBatch;
    procedure RollbackBatch;
    // Every Open...Rows above lends the same cursor; give it back before
    // the next row pass.
    procedure CloseRows;

    // paper QSL -- marking (fMarkQSL, fMain, fExLabelPrint)
    function SqlEarlierQsoByDxccBandModeQslQ(const FilterWhere : String; const Adif : Integer; const Mode, Band : String) : String;
    function SqlEarlierQsoByCallBandMode(const FilterWhere, Call, Mode, Band : String) : String;
    function SqlEarlierQsoByDxccBandMode(const FilterWhere : String; const Adif : Integer; const Mode, Band : String) : String;
    function SqlEarlierQsoByCallBand(const FilterWhere, Call, Band : String) : String;
    function SqlEarlierQsoByDxccBand(const FilterWhere : String; const Adif : Integer; const Band : String) : String;
    function SqlEarlierQsoByCall(const FilterWhere, Call : String) : String;
    function SqlEarlierQsoByDxcc(const FilterWhere : String; const Adif : Integer) : String;
    function SqlSetQslS(const QslS : String; const Id : Integer) : String;
    function SqlMarkQslSent(const QslS, Date : String; const Id : Integer) : String;
    function SqlMarkQslReceived(const Date : String; const Id : Integer) : String;
    function SqlMarkQslSentFromLabels(const QslS, Date : String; const Id : Integer) : String;

    // LoTW
    function SqlQsosForLotwAll : String;
    function SqlQsosForLotwNotExported : String;
    function SqlMarkLotwSent(const Date, Id : String) : String;
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
  end;

var
  dmSqlQsl : TdmSqlQsl;

implementation

{$R *.lfm}

uses dData;

procedure TdmSqlQsl.DataModuleCreate(Sender : TObject);
begin
  FQ     := TSqlCursor.Create(Self);
  FRows  := TSqlCursor.Create(Self);
  FBatch := TSqlCursor.Create(Self)
end;

procedure TdmSqlQsl.AttachTo(Connection : TSQLConnection);
begin
  FQ.AttachTo(Connection);
  FRows.AttachTo(Connection);
  FBatch.AttachTo(Connection)
end;

function TdmSqlQsl.OpenRows(const Sql : String) : TDataSet;
begin
  FRows.Prepare(Sql);
  FRows.Open;
  Result := FRows.Query
end;

procedure TdmSqlQsl.CloseRows;
begin
  FRows.Release
end;

procedure TdmSqlQsl.ExecAlone(const Sql : String);
begin
  FQ.Prepare(Sql);
  FQ.ExecAndCommit
end;

procedure TdmSqlQsl.ExecInBatch(const Sql : String);
begin
  FBatch.PrepareNext(Sql);
  FBatch.Exec
end;

procedure TdmSqlQsl.CommitBatch;
begin
  FBatch.Commit;
  FBatch.Release
end;

procedure TdmSqlQsl.RollbackBatch;
begin
  FBatch.Release
end;

{ Mark QSL window }

function TdmSqlQsl.EarlierQsoExists(const What : TEarlierQso; const ByCall : Boolean;
                                    const FilterWhere, Call : String; const Adif : Integer;
                                    const Band, Mode : String) : Boolean;
var
  Sql : String;
begin
  case What of
    eqBandModeQslReceived : Sql := SqlEarlierQsoByDxccBandModeQslQ(FilterWhere, Adif, Mode, Band);
    eqBandMode : if ByCall then
                   Sql := SqlEarlierQsoByCallBandMode(FilterWhere, Call, Mode, Band)
                 else
                   Sql := SqlEarlierQsoByDxccBandMode(FilterWhere, Adif, Mode, Band);
    eqBand     : if ByCall then
                   Sql := SqlEarlierQsoByCallBand(FilterWhere, Call, Band)
                 else
                   Sql := SqlEarlierQsoByDxccBand(FilterWhere, Adif, Band);
    else         if ByCall then
                   Sql := SqlEarlierQsoByCall(FilterWhere, Call)
                 else
                   Sql := SqlEarlierQsoByDxcc(FilterWhere, Adif)
  end;
  FQ.Prepare(Sql);
  try
    FQ.Open;
    //max(id_cqrlog_main) is NULL, and reads as 0, when there is none
    Result := FQ.Query.Fields[0].AsInteger <> 0
  finally
    FQ.Release
  end
end;

procedure TdmSqlQsl.SetQslS(const QslS : String; const Id : Integer);
begin
  ExecAlone(SqlSetQslS(QslS, Id))
end;

{ main window }

procedure TdmSqlQsl.MarkQslSent(const QslS, Date : String; const Id : Integer);
begin
  ExecInBatch(SqlMarkQslSent(QslS, Date, Id))
end;

procedure TdmSqlQsl.MarkQslReceived(const Date : String; const Id : Integer);
begin
  ExecInBatch(SqlMarkQslReceived(Date, Id))
end;

{ LoTW }

function TdmSqlQsl.OpenQsosForLotwRows(const All : Boolean; const FilterSql : String) : TDataSet;
begin
  if FilterSql <> '' then
    Result := OpenRows(FilterSql)
  else if All then
    Result := OpenRows(SqlQsosForLotwAll)
  else
    Result := OpenRows(SqlQsosForLotwNotExported)
end;

procedure TdmSqlQsl.MarkLotwSent(const Date, Id : String);
begin
  ExecInBatch(SqlMarkLotwSent(Date, Id))
end;

// The two MarkAll... used to swallow a failure without a word; they still
// do, apart from the debug log.
procedure TdmSqlQsl.MarkAllLotwSent(const Date : String);
begin
  try
    ExecAlone(SqlMarkAllLotwSent(Date))
  except
    on E : Exception do
      if dmData.DebugLevel >= 1 then Writeln(E.Message)
  end
end;

{ eQSL }

function TdmSqlQsl.OpenQsosForEqslRows(const NotExported : Boolean; const FilterSql : String) : TDataSet;
begin
  if NotExported then
    Result := OpenRows(SqlQsosForEqslNotExported)
  else if FilterSql <> '' then
    Result := OpenRows(FilterSql)
  else
    Result := OpenRows(SqlQsosForEqslAll)
end;

procedure TdmSqlQsl.MarkEqslSent(const Date, Id : String);
begin
  ExecInBatch(SqlMarkEqslSent(Date, Id))
end;

procedure TdmSqlQsl.MarkAllEqslSent(const Date : String);
begin
  try
    ExecAlone(SqlMarkAllEqslSent(Date))
  except
    on E : Exception do
      if dmData.DebugLevel >= 1 then Writeln(E.Message)
  end
end;

{ QSL labels }

function TdmSqlQsl.PrepareQslExportRow : TParams;
begin
  FBatch.PrepareNext(SqlInsertQslExport);
  FBatch.Query.Prepare;
  Result := FBatch.Query.Params
end;

procedure TdmSqlQsl.InsertQslExportRow;
begin
  FBatch.Exec
end;

function TdmSqlQsl.OpenQslExportRows : TDataSet;
begin
  Result := OpenRows(SqlQslExportRows)
end;

procedure TdmSqlQsl.MarkQslSentFromLabels(const QslS, Date : String; const Id : Integer);
begin
  ExecInBatch(SqlMarkQslSentFromLabels(QslS, Date, Id))
end;

procedure TdmSqlQsl.DropQslExportTable;
begin
  ExecAlone(SqlDropQslExport)
end;

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

// The four branches of TfrmMarkQSL.btnOKClick (first QSO, first band,
// first band/mode, first band/mode with QSL received) all mark with this.
function TdmSqlQsl.SqlSetQslS(const QslS : String; const Id : Integer) : String;
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

// Marks one QSO as uploaded to LoTW; fLoTWExport runs it per QSO after a
// file export and after a web upload.
function TdmSqlQsl.SqlMarkLotwSent(const Date, Id : String) : String;
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

end.
