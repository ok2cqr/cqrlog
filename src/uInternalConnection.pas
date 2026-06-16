(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

unit uInternalConnection;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, mysql57dyn, mysql57conn, uConnectionInfo;

type
  TinternalConnection = class
  private
    _ConnectionInfo : TConnectionInfo;
    Connection : TConnectionName;
    TC : TSQLTransaction;

    function  getNewMySQLConnectionObject() : TConnectionName;
    function  getNewMySQLConnection: TConnectionName;

    procedure init();
  public
    Q : TSQLQuery;
    //second query sharing the same connection and transaction T - useful when one
    //prepared query (Q) must stay open/prepared while another statement is executed (Q2)
    Q2 : TSQLQuery;
    T : TSQLTransaction;

    constructor Create(ConnectionInfo : TConnectionInfo);
    destructor  Destroy; override;
  end;

implementation

constructor TInternalConnection.Create(ConnectionInfo : TConnectionInfo);
begin
  _ConnectionInfo := ConnectionInfo;
  Q := TSQLQuery.Create(nil);
  Q2 := TSQLQuery.Create(nil);
  T := TSQLTransaction.Create(nil);
  TC := TSQLTransaction.Create(nil);

  init();
end;

procedure TinternalConnection.init();
begin
  Connection := getNewMySQLConnection();
  T.DataBase := Connection;
  Q.DataBase := Connection;
  Q.Transaction := T;
  Q2.DataBase := Connection;
  Q2.Transaction := T;
  T.Action := caNone;
end;

function TInternalConnection.getNewMySQLConnectionObject() : TConnectionName;
var
  Conn : TMySQL57Connection;
begin
  Conn := TMySQL57Connection.Create(nil);
  Conn.SkipLibraryVersionCheck := True;
  Conn.KeepConnection := True;

  Result := Conn;
end;

function TInternalConnection.getNewMySQLConnection : TConnectionName;
var
  Conn : TConnectionName;
begin
  Conn := getNewMySQLConnectionObject();
  Conn.Transaction := TC;
  Conn.HostName := _ConnectionInfo.HostName;
  Conn.Params.Text  := 'Port=' + _ConnectionInfo.Port;
  Conn.UserName := _ConnectionInfo.UserName;
  Conn.Password := _ConnectionInfo.Password;
  Conn.DatabaseName := 'information_schema';
  Conn.Connected := true;

  Conn.ExecuteDirect(
    'SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'+QuotedStr('ONLY_FULL_GROUP_BY')+','+QuotedStr('')+'));'
  );

  Conn.ExecuteDirect('use ' + _ConnectionInfo.DatabaseName);

  Result := Conn;
end;

destructor TInternalConnection.Destroy;
begin
  inherited;

  Q.Close;
  Q2.Close;
  Connection.Close(True);
  FreeAndNil(Q);
  FreeAndNil(Q2);
  FreeAndNil(T);
  FreeAndNil(Connection);
  FreeAndNil(TC);
end;

end.

