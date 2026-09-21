(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ When to try again after the connection is lost, and when not to. }

unit tReconnect;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uRbnReconnect;

type
  TReconnectTest = class(TTestCase)
  published
    procedure NothingToReconnectBeforeTheUserConnects;
    procedure LostConnectionIsReconnected;
    procedure UserDisconnectStopsReconnecting;
    procedure DelayDoublesFromFiveSeconds;
    procedure DelayIsCappedAtFiveMinutes;
    procedure SuccessfulConnectStartsTheDelaysOver;
    procedure UserConnectStartsTheDelaysOver;
  end;

implementation

procedure TReconnectTest.NothingToReconnectBeforeTheUserConnects;
var
  P : TRbnReconnect;
begin
  P.Init;
  AssertFalse(P.ShouldReconnect)
end;

procedure TReconnectTest.LostConnectionIsReconnected;
var
  P : TRbnReconnect;
begin
  P.Init;
  P.UserConnect;
  P.Connected;
  AssertTrue(P.ShouldReconnect)
end;

procedure TReconnectTest.UserDisconnectStopsReconnecting;
var
  P : TRbnReconnect;
begin
  //the application must not fight the user
  P.Init;
  P.UserConnect;
  P.Connected;
  P.UserDisconnect;
  AssertFalse(P.ShouldReconnect)
end;

procedure TReconnectTest.DelayDoublesFromFiveSeconds;
var
  P : TRbnReconnect;
begin
  P.Init;
  P.UserConnect;
  AssertEquals(5, P.NextDelaySec);
  AssertEquals(10, P.NextDelaySec);
  AssertEquals(20, P.NextDelaySec);
  AssertEquals(40, P.NextDelaySec)
end;

procedure TReconnectTest.DelayIsCappedAtFiveMinutes;
var
  P : TRbnReconnect;
  i : Integer;
begin
  P.Init;
  P.UserConnect;
  for i := 1 to 50 do
    AssertTrue(P.NextDelaySec <= 300);
  AssertEquals(300, P.NextDelaySec)
end;

procedure TReconnectTest.SuccessfulConnectStartsTheDelaysOver;
var
  P : TRbnReconnect;
begin
  P.Init;
  P.UserConnect;
  P.NextDelaySec; P.NextDelaySec; P.NextDelaySec;
  P.Connected;
  AssertEquals(5, P.NextDelaySec)
end;

procedure TReconnectTest.UserConnectStartsTheDelaysOver;
var
  P : TRbnReconnect;
begin
  P.Init;
  P.UserConnect;
  P.NextDelaySec; P.NextDelaySec;
  P.UserConnect;
  AssertEquals(5, P.NextDelaySec)
end;

initialization
  RegisterTest(TReconnectTest);
end.
