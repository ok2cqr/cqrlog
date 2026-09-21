(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ What the receive loop answers with the callsign.  The RBN relay asks without
  ending the line, so the text comes from TRbnLineFramer.Pending as often as
  from a complete line. }

unit tLogin;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uRbnLogin;

type
  TLoginTest = class(TTestCase)
  published
    procedure RbnRelayPrompt;
    procedure ClusterLoginPromptAnyCase;
    procedure GreetingIsNotAPrompt;
    procedure EmptyTextIsNotAPrompt;
    procedure AnswersOnlyOncePerConnection;
    procedure AnswersAgainAfterReconnect;
    procedure PromptCompletedByTheGreetingIsNotAnsweredTwice;
  end;

implementation

procedure TLoginTest.RbnRelayPrompt;
begin
  AssertTrue(IsRbnLoginPrompt('Please enter your call: '))
end;

procedure TLoginTest.ClusterLoginPromptAnyCase;
begin
  AssertTrue(IsRbnLoginPrompt('login: '));
  AssertTrue(IsRbnLoginPrompt('LOGIN:'))
end;

procedure TLoginTest.GreetingIsNotAPrompt;
begin
  AssertFalse(IsRbnLoginPrompt('Hello, OK2CQR! Connected.'));
  AssertFalse(IsRbnLoginPrompt('Local users: 759'))
end;

procedure TLoginTest.EmptyTextIsNotAPrompt;
begin
  AssertFalse(IsRbnLoginPrompt(''))
end;

procedure TLoginTest.AnswersOnlyOncePerConnection;
var
  L : TRbnLogin;
begin
  L.Reset;
  AssertTrue(L.ShouldAnswer('Please enter your call: '));
  AssertFalse(L.ShouldAnswer('Please enter your call: '))
end;

procedure TLoginTest.AnswersAgainAfterReconnect;
var
  L : TRbnLogin;
begin
  L.Reset;
  AssertTrue(L.ShouldAnswer('login: '));
  L.Reset;
  AssertTrue(L.ShouldAnswer('login: '))
end;

procedure TLoginTest.PromptCompletedByTheGreetingIsNotAnsweredTwice;
var
  L : TRbnLogin;
begin
  //the prompt has no line end, so the greeting lands on the same line
  L.Reset;
  AssertTrue(L.ShouldAnswer('Please enter your call: '));
  AssertFalse(L.ShouldAnswer('Please enter your call: Hello, OK2CQR! Connected.'))
end;

initialization
  RegisterTest(TLoginTest);
end.
