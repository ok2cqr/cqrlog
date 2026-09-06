(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

// A private cursor for a dSql* module: one TSQLQuery with its own
// TSQLTransaction, and the transaction rule in one place.
//
// Every operation is the same four lines wherever it is written -- close
// what was open, roll back what was active, run the statement, clean up.
// Spelled out per operation (dSqlUserData did that first) it is twelve
// copies to keep right; this class is the one copy.
//
// Two cursors per module by convention: one lent out for row passes
// (OpenXxxRows / CloseRows), one for scalars, list fills and writes.  A
// scalar called from inside a borrowed row pass must not land on the same
// TSQLQuery, or it closes the dataset the caller is still reading.  A
// module that runs batches -- several writes in one transaction the
// caller ends -- keeps a third one for them, so a scalar cannot roll a
// batch back by preparing on top of it.

unit uSqlCursor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb;

type
  // A TComponent so the owning data module frees it; the query and the
  // transaction are owned by the cursor in turn.
  TSqlCursor = class(TComponent)
  private
    FQ : TSQLQuery;
    FT : TSQLTransaction;
  public
    constructor Create(AOwner : TComponent); override;
    // Wired by TdmData once MainCon exists.
    procedure AttachTo(Connection : TSQLConnection);
    // Close and roll back whatever was left, then set the statement.
    // Prints it at debug level 1, as dData's BeforeOpen handlers do.
    procedure Prepare(const Sql : String);
    // Open the prepared statement in a fresh transaction.
    procedure Open;
    // Run the prepared statement and commit; roll back and re-raise on error.
    procedure ExecAndCommit;
    // Close the dataset and roll back whatever transaction is open.
    procedure Release;
    // A batch: several statements in one transaction the caller ends.
    // PrepareNext sets the next statement and leaves the transaction
    // alone, Exec runs it (starting the transaction if none is open) and
    // does not commit, Commit ends the batch; Release rolls it back.
    procedure PrepareNext(const Sql : String);
    procedure Exec;
    procedure Commit;
    property Query : TSQLQuery read FQ;
  end;

implementation

uses dData;

constructor TSqlCursor.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);
  FT := TSQLTransaction.Create(Self);
  FT.Action := caNone;
  FQ := TSQLQuery.Create(Self);
  //as on dData's Q and Q1: sqldb must not rewrite the statement.
  //ParamCheck stays on, so :name parameters are still extracted.
  FQ.ParseSQL := False;
  FQ.Transaction := FT
end;

procedure TSqlCursor.AttachTo(Connection : TSQLConnection);
begin
  FT.DataBase := Connection;
  FQ.DataBase := Connection
end;

procedure TSqlCursor.Prepare(const Sql : String);
begin
  if FT.Active then
    FT.Rollback;
  PrepareNext(Sql)
end;

procedure TSqlCursor.PrepareNext(const Sql : String);
begin
  FQ.Close;
  FQ.SQL.Text := Sql;
  if dmData.DebugLevel >= 1 then
    Writeln(Sql)
end;

procedure TSqlCursor.Exec;
begin
  if not FT.Active then
    FT.StartTransaction;
  FQ.ExecSQL
end;

procedure TSqlCursor.Commit;
begin
  if FT.Active then
    FT.Commit
end;

procedure TSqlCursor.Open;
begin
  if not FT.Active then
    FT.StartTransaction;
  FQ.Open
end;

procedure TSqlCursor.ExecAndCommit;
begin
  if not FT.Active then
    FT.StartTransaction;
  try
    FQ.ExecSQL;
    FT.Commit
  except
    FT.Rollback;
    raise
  end
end;

procedure TSqlCursor.Release;
begin
  FQ.Close;
  if FT.Active then
    FT.Rollback
end;

end.
