(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Reconnect policy of a managed RBN connection.

  Tries again after a lost connection with a growing delay (5, 10, 20 ... capped
  at 300 s), never switches to another server, and never reconnects after the
  user has disconnected by hand -- the application must not fight the user.

  Only the decisions live here; the timer and the socket belong to the caller.
  No LCL; see tests/tReconnect.pas. }

unit uRbnReconnect;

{$mode objfpc}{$H+}{$modeswitch advancedrecords}

interface

const
  RBN_RECONNECT_FIRST_SEC = 5;
  RBN_RECONNECT_MAX_SEC   = 300;

type
  TRbnReconnect = record
  private
    FWanted : Boolean;  //the user asked for a connection and has not taken it back
    FDelay  : Integer;  //what NextDelaySec returns next
  public
    procedure Init;
    procedure UserConnect;
    procedure UserDisconnect;
    procedure Connected;   //the socket is up, the next loss starts from 5 s again
    function  ShouldReconnect : Boolean;
    function  NextDelaySec : Integer;  //every call is one failed attempt
  end;

implementation

procedure TRbnReconnect.Init;
begin
  FWanted := False;
  FDelay  := RBN_RECONNECT_FIRST_SEC
end;

procedure TRbnReconnect.UserConnect;
begin
  FWanted := True;
  FDelay  := RBN_RECONNECT_FIRST_SEC
end;

procedure TRbnReconnect.UserDisconnect;
begin
  FWanted := False
end;

procedure TRbnReconnect.Connected;
begin
  FDelay := RBN_RECONNECT_FIRST_SEC
end;

function TRbnReconnect.ShouldReconnect : Boolean;
begin
  Result := FWanted
end;

function TRbnReconnect.NextDelaySec : Integer;
begin
  Result := FDelay;
  FDelay := FDelay * 2;
  if FDelay > RBN_RECONNECT_MAX_SEC then
    FDelay := RBN_RECONNECT_MAX_SEC
end;

end.
