(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ When to send the callsign.

  The servers ask either "Please enter your call: " (RBN relay) or "login: "
  (cluster software), and neither ends the line.  The old handlers answered every
  piece of text that contained one of the two, so the greeting that completes the
  prompt line -- or any later line mentioning "login" -- sent the call once more,
  as a command.  One answer per connection is enough.

  No LCL, no globals; see tests/tLogin.pas. }

unit uRbnLogin;

{$mode objfpc}{$H+}{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils;

type
  TRbnLogin = record
  private
    FAnswered : Boolean;
  public
    procedure Reset;  //on every connect
    //True once per connection, for the first text that is a prompt
    function  ShouldAnswer(const Text : String) : Boolean;
    property  Answered : Boolean read FAnswered;
  end;

function IsRbnLoginPrompt(const Text : String) : Boolean;

implementation

function IsRbnLoginPrompt(const Text : String) : Boolean;
var
  s : String;
begin
  s := LowerCase(Text);
  Result := (Pos('login', s) > 0) or (Pos('please enter your call', s) > 0)
end;

procedure TRbnLogin.Reset;
begin
  FAnswered := False
end;

function TRbnLogin.ShouldAnswer(const Text : String) : Boolean;
begin
  Result := (not FAnswered) and IsRbnLoginPrompt(Text);
  if Result then
    FAnswered := True
end;

end.
