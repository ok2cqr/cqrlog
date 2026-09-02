(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

// Online log upload bookkeeping: the log_changes queue the triggers fill,
// the upload_status watermark per online log, and the triggers themselves.
//
// Builders only for now.  The upload runs in TUploadThread on dmLogUpload's
// cursors, and which cursor belongs to whom there is a decision of its own;
// this unit just says what is asked, not who asks.

unit dSqlUpload;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources;

type
  TdmSqlUpload = class(TDataModule)
  public
    // log_changes
    function SqlInsertAllDoneMark : String;
    function SqlInsertLogDoneMark(const LogName : String) : String;
    function SqlLastLogChangeId : String;
    function SqlLastLogChangeIdForLog : String;
    function SqlDeleteLogChangesBefore(const Id : Integer) : String;
    function SqlLogChangeForInsert(const Id : Integer) : String;
    function SqlLogChangeForDelete(const Id : Integer) : String;
    function SqlLogChangesAfter(const Id : Integer) : String;
    function SqlMarkUpDeleted(const Id : Integer) : String;

    // upload_status
    function SqlSetAllUploadStatus(const Id : Integer) : String;
    function SqlSetAllUploadStatusForLog(const Id : Integer) : String;
    function SqlMarkUploaded(const LogName : String; const Id : Integer) : String;
    function SqlUploadStatus(const LogName : String) : String;

    // the QSO a change refers to
    function SqlQsoForAdif(const Id : Integer) : String;
    function SqlQsoForKeyValue(const Id : Integer) : String;

    // triggers
    function SqlDropTrigger(const TriggerName : String) : String;
    function SqlClearTable(const Table : String) : String;
  end;

var
  dmSqlUpload : TdmSqlUpload;

implementation

{$R *.lfm}

uses dLogUpload;

{ log_changes }

function TdmSqlUpload.SqlInsertAllDoneMark : String;
begin
  Result := 'insert into log_changes (cmd) values('+QuotedStr(C_ALLDONE)+')'
end;

function TdmSqlUpload.SqlInsertLogDoneMark(const LogName : String) : String;
begin
  Result := 'insert into log_changes (cmd) values('+QuotedStr(LogName+'DONE')+')'
end;

function TdmSqlUpload.SqlLastLogChangeId : String;
begin
  Result := 'select max(id) from log_changes'
end;

// Same statement as SqlLastLogChangeId.  Kept separate so this extraction
// leaves the SQL inventory (tools/sql-inventory) untouched; merging the two
// is a follow-up commit of its own.
function TdmSqlUpload.SqlLastLogChangeIdForLog : String;
begin
  Result := 'select max(id) from log_changes'
end;

function TdmSqlUpload.SqlDeleteLogChangesBefore(const Id : Integer) : String;
begin
  Result := 'delete from log_changes where id < '+IntToStr(Id)
end;

function TdmSqlUpload.SqlLogChangeForInsert(const Id : Integer) : String;
const
  C_SEL_LOG_CHANGES = 'select * from log_changes where id = %d';
begin
  Result := Format(C_SEL_LOG_CHANGES,[Id])
end;

// Same statement as SqlLogChangeForInsert -- see the note on
// SqlLastLogChangeIdForLog.
function TdmSqlUpload.SqlLogChangeForDelete(const Id : Integer) : String;
const
  C_SEL_LOG_CHANGES = 'select * from log_changes where id = %d';
begin
  Result := Format(C_SEL_LOG_CHANGES,[Id])
end;

function TdmSqlUpload.SqlLogChangesAfter(const Id : Integer) : String;
const
  C_SEL_LOG_CHANGES = 'select * from log_changes where id > %d order by id';
begin
  Result := Format(C_SEL_LOG_CHANGES,[Id])
end;

function TdmSqlUpload.SqlMarkUpDeleted(const Id : Integer) : String;
const
  C_UPD = 'update log_changes set upddeleted=0 where id = %d';
begin
  Result := Format(C_UPD,[Id])
end;

{ upload_status }

function TdmSqlUpload.SqlSetAllUploadStatus(const Id : Integer) : String;
begin
  Result := 'update upload_status set id_log_changes='+IntToStr(Id)
end;

// Same statement as SqlSetAllUploadStatus -- see the note on
// SqlLastLogChangeIdForLog.
function TdmSqlUpload.SqlSetAllUploadStatusForLog(const Id : Integer) : String;
begin
  Result := 'update upload_status set id_log_changes='+IntToStr(Id)
end;

function TdmSqlUpload.SqlMarkUploaded(const LogName : String; const Id : Integer) : String;
const
  C_UPD = 'update upload_status set id_log_changes = %d where logname = %s';
begin
  Result := Format(C_UPD,[Id,QuotedStr(LogName)])
end;

function TdmSqlUpload.SqlUploadStatus(const LogName : String) : String;
const
  C_SEL_UPLOAD_STATUS = 'select * from upload_status where logname=%s';
begin
  Result := Format(C_SEL_UPLOAD_STATUS,[QuotedStr(LogName)])
end;

{ the QSO a change refers to }

function TdmSqlUpload.SqlQsoForAdif(const Id : Integer) : String;
begin
  Result := 'select * from cqrlog_main where id_cqrlog_main = '+IntToStr(Id)
end;

// Same statement as SqlQsoForAdif -- see the note on SqlLastLogChangeIdForLog.
function TdmSqlUpload.SqlQsoForKeyValue(const Id : Integer) : String;
begin
  Result := 'select * from cqrlog_main where id_cqrlog_main = '+IntToStr(Id)
end;

{ triggers }

function TdmSqlUpload.SqlDropTrigger(const TriggerName : String) : String;
const
  C_DROP = 'DROP TRIGGER IF EXISTS %s';
begin
  Result := Format(C_DROP,[TriggerName])
end;

function TdmSqlUpload.SqlClearTable(const Table : String) : String;
const
  C_DEL = 'DELETE FROM %s';
begin
  Result := Format(C_DEL,[Table])
end;

end.
