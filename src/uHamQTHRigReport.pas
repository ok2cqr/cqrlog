(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Reports where the rig is tuned to HamQTH (POST /api/v2/rig), so the station
  shows as on the air on its profile and in the "On the air" list.

  TfrmTRXControl.SynTRX calls HamQTHRigUpdate on every rig poll when
  Preferences -> Online log upload -> HamQTH -> chkHaRigReport is on.  When to
  send is decided by THamQTHRigSchedule (uHamQTHApi), the request runs in its
  own thread so a slow server does not stop the rig polling.  At most one
  request runs at a time; the token belongs to it, the main thread touches it
  only between requests.

  After an error the reports pause (see HamQTHRigResult).  A changed login
  or station callsign ends the pause and drops the token, a rejected
  frequency or mode waits only until it changes.

  The login is the one of the log upload (OnlineLog/HaUserName, HaPasswd).
  Failures go to cqrlog-debug.log, there is no other place a user would see
  them. }

unit uHamQTHRigReport;

{$mode objfpc}{$H+}

interface

//FreqKHz = where the rig transmits (TX LO included), Mode as it is logged
procedure HamQTHRigUpdate(FreqKHz : Double; const Mode : String);

implementation

uses
  Classes, SysUtils, dUtils, dData, uMyIni, uHamQTHApi, uDebugLog;

type
  TRigReportThread = class(TThread)
  private
    fBody     : String;
    fUser     : String;
    fPassword : String;
  protected
    procedure Execute; override;
  public
    constructor Create(const Body, User, Password : String);
  end;

var
  Schedule         : THamQTHRigSchedule = nil;
  Token            : String = '';  //used by the running thread, cleared by HamQTHRigUpdate only when Busy = 0
  Busy             : LongInt = 0;  //1 while a thread runs
  //set by the thread before Busy goes 0, applied by HamQTHRigUpdate
  PauseMs          : LongInt = 0;
  PauseUntilChange : LongInt = 0;
  LastSettings     : String = '';  //login and station callsign of the last report
  NoLoginLogged    : Boolean = False;

constructor TRigReportThread.Create(const Body, User, Password : String);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  fBody     := Body;
  fUser     := User;
  fPassword := Password;
  Start
end;

procedure TRigReportThread.Execute;
var
  i          : Integer;
  ResultCode : Integer = 0;
  Response   : String = '';
  Reached    : Boolean = False;
  Msg        : String;
  Pause      : Cardinal = 0;
  UntilChange: Boolean = False;
begin
  try
    for i := 1 to 2 do
    begin
      if Token = '' then
      begin
        Reached := dmUtils.HamQTHRequest('POST', C_HAMQTH_API + 'login', '',
          HamQTHLoginRequest(fUser, fPassword), ResultCode, Response);
        if (not Reached) or (ResultCode <> 200) then
          Break;
        if not ParseHamQTHLogin(Response, Token) then
        begin
          ResultCode := 0;
          Break
        end
      end;
      Reached := dmUtils.HamQTHRequest('POST', C_HAMQTH_API + 'rig', Token, fBody, ResultCode, Response);
      if not (Reached and (ResultCode = 401)) then
        Break;
      Token := '' //expired, log in again once
    end;
    if not Reached then
      ResultCode := 0;
    Msg := HamQTHRigResult(ResultCode, Response, Pause, UntilChange);
    if Msg <> '' then
      DbgLog('HamQTH', 'rig status report: ' + Msg);
    InterLockedExchange(PauseUntilChange, Ord(UntilChange));
    InterLockedExchange(PauseMs, LongInt(Pause))
  except
    on E : Exception do
    begin
      DbgLogException('HamQTH', 'rig status report ' + fBody, E);
      InterLockedExchange(PauseUntilChange, 0);
      InterLockedExchange(PauseMs, C_RIG_SHORT_PAUSE)
    end
  end;
  InterLockedExchange(Busy, 0)
end;

procedure HamQTHRigUpdate(FreqKHz : Double; const Mode : String);
var
  Now      : QWord;
  p        : LongInt;
  User     : String;
  Password : String;
  Call     : String;
begin
  //Busy first: once it is 0, PauseMs of the last thread is already there
  if Busy <> 0 then
    exit;
  User     := cqrini.ReadString('OnlineLog', 'HaUserName', '');
  Password := cqrini.ReadString('OnlineLog', 'HaPasswd', '');
  if (User = '') or (Password = '') then
  begin
    if not NoLoginLogged then
      DbgLog('HamQTH', 'rig status report: user name or password is empty ' +
        '(Preferences -> Online log upload -> HamQTH)');
    NoLoginLogged := True;
    exit
  end;
  NoLoginLogged := False;
  Call := cqrini.ReadString('Station', 'Call', '');
  if Schedule = nil then
    Schedule := THamQTHRigSchedule.Create;
  Now := GetTickCount64;
  p := InterLockedExchange(PauseMs, 0);
  if p > 0 then
    Schedule.Pause(Now, p, InterLockedExchange(PauseUntilChange, 0) = 1);
  //after the pause of the last report, so a new password ends it
  if (User + #0 + Password + #0 + Call <> LastSettings) then
  begin
    LastSettings := User + #0 + Password + #0 + Call;
    Token := ''; //may belong to the previous account
    Schedule.Resume
  end;
  if not Schedule.Due(FreqKHz, Mode, Now) then
    exit;
  Schedule.Sent(FreqKHz, Mode, Now);
  if dmData.DebugLevel >= 1 then
    Writeln('HamQTH rig status report: ', HamQTHRigRequest(FreqKHz, Mode, Call));
  InterLockedExchange(Busy, 1);
  TRigReportThread.Create(HamQTHRigRequest(FreqKHz, Mode, Call), User, Password)
end;

finalization
  FreeAndNil(Schedule)
end.
