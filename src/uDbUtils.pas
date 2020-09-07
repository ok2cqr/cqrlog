(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

unit uDbUtils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, strutils, uConnectionInfo, uInternalConnection;

  (*
  * Returns connection to CQRLOG database. Usfull for one-time methods eg. modify something
  * getting some value from a table etc.
  *)
  function  GetNewInternalConnection(): TInternalConnection;
  function  GetConnectionInfo() : TConnectionInfo;

  procedure UpdateConnectionInfoRecord(Host, Port, UserName, Password : String; DatabaseName : String = '');
  procedure UpdateConnectionInfoDatabaseName(DatabaseNumber : Integer);

implementation

var
  ConnectionInfo : TConnectionInfo;

procedure UpdateConnectionInfoRecord(Host, Port, UserName, Password : String; DatabaseName : String = '');
begin
  ConnectionInfo.HostName := Host;
  ConnectionInfo.Port := Port;
  ConnectionInfo.UserName := UserName;
  ConnectionInfo.Password := Password;
  ConnectionInfo.DatabaseName := DatabaseName;
end;

procedure UpdateConnectionInfoDatabaseName(DatabaseNumber : Integer);
begin
  ConnectionInfo.DatabaseName := 'cqrlog' + AddChar('0',IntToStr(DatabaseNumber), 3);
end;

function GetNewInternalConnection(): TInternalConnection;
begin
  Result := TinternalConnection.Create(ConnectionInfo);
end;

function GetConnectionInfo() : TConnectionInfo;
begin
  Result := ConnectionInfo;
end;


end.

