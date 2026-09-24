(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ A managed RBN telnet connection.

  The connection is an object of its own, independent of any window; windows
  are subscribers and come and go without touching the socket. It owns the
  socket, the line framer, the login and the reconnect policy (all in src/rbn,
  tested there); it parses every line once and hands the result to everybody who
  asked for it.

  Main thread only: lNet delivers its events through the LCL event loop, and the
  subscribers are forms. A subscriber that needs a worker thread queues the spot
  itself (see TfrmRbnMonitor). }

unit uRbnConnection;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, lNet, lNetComponents,
  uRbnLineFramer, uRbnSpotParser, uRbnLogin, uRbnReconnect;

const
  RBN_RATE_MINUTES = 10;
  //RBN sends spots without a pause; a session that is Connected and has been
  //silent this long is dead (half-open TCP after a network drop, or a login
  //the server never got) and is reconnected by the watchdog
  RBN_SILENCE_SEC  = 180;

type
  TRbnConnState = (rcsDisconnected,  //by the user, or never connected
                   rcsConnecting,
                   rcsConnected,
                   rcsWaiting);      //lost or failed, the next attempt is scheduled

  //Line is the spot as it came, Spot the same thing parsed
  TRbnSpotEvent  = procedure(const Line : String; const Spot : TRbnSpotLine) of object;
  TRbnStateEvent = procedure(Sender : TObject) of object;

  TRbnConnection = class(TComponent)
  private
    FTelnet    : TLTelnetClientComponent;
    FTimer     : TTimer;
    FWatchdog  : TTimer;
    FLastRx    : TDateTime;   //last byte from the server
    FFramer    : TRbnLineFramer;
    FLogin     : TRbnLogin;
    FReconnect : TRbnReconnect;
    FState     : TRbnConnState;
    FStatus    : String;
    FHost      : String;
    FPort      : Integer;
    FUserName  : String;
    FSpotSubs  : array of TRbnSpotEvent;
    FStateSubs : array of TRbnStateEvent;
    //spots received per minute, a ring of the last RBN_RATE_MINUTES minutes
    FRate      : array[0..RBN_RATE_MINUTES-1] of Integer;
    FRateMin   : Int64;   //the minute the ring was last advanced to
    FTotal     : Int64;

    procedure CountSpot;
    procedure AdvanceRate(ToMinute : Int64);

    procedure SetState(AState : TRbnConnState; const AStatus : String);
    procedure OpenSocket;
    procedure ScheduleReconnect(const Why : String);
    procedure AnswerLogin(const Text : String);
    procedure TimerTick(Sender : TObject);
    procedure WatchdogTick(Sender : TObject);
    procedure SockConnect(aSocket : TLSocket);
    procedure SockDisconnect(aSocket : TLSocket);
    procedure SockError(const msg : string; aSocket : TLSocket);
    procedure SockReceive(aSocket : TLSocket);
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;

    //what the user does. Connect takes the target, so a changed server or user
    //name is picked up on the next manual Connect and not in the middle of retries
    procedure Connect(const AHost : String; APort : Integer; const AUserName : String);
    procedure Disconnect;

    procedure SubscribeSpots(Handler : TRbnSpotEvent);
    procedure UnsubscribeSpots(Handler : TRbnSpotEvent);
    procedure SubscribeState(Handler : TRbnStateEvent);
    procedure UnsubscribeState(Handler : TRbnStateEvent);

    property State  : TRbnConnState read FState;
    property Status : String read FStatus;  //for a status bar
    //spots received from the server in the last RBN_RATE_MINUTES minutes,
    //before any filter; and since the connection object exists
    function  SpotsLastMinutes : Integer;
    property SpotsTotal : Int64 read FTotal;
  end;

//the main RBN source, created on the first call and owned by Application
function RbnMainConnection : TRbnConnection;

implementation

uses
  Forms, uDebugLog;

var
  MainConnection : TRbnConnection = nil;

function RbnMainConnection : TRbnConnection;
begin
  if MainConnection = nil then
    MainConnection := TRbnConnection.Create(Application);
  Result := MainConnection
end;

function SameMethod(const A, B : TMethod) : Boolean;
begin
  Result := (A.Code = B.Code) and (A.Data = B.Data)
end;

{ TRbnConnection }

constructor TRbnConnection.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);
  FFramer := TRbnLineFramer.Create;
  FReconnect.Init;
  FState  := rcsDisconnected;
  FStatus := 'Disconnected';

  FTimer := TTimer.Create(self);
  FTimer.Enabled := False;
  FTimer.OnTimer := @TimerTick;

  FWatchdog := TTimer.Create(self);
  FWatchdog.Enabled  := False;
  FWatchdog.Interval := 30000;
  FWatchdog.OnTimer  := @WatchdogTick;

  FTelnet := TLTelnetClientComponent.Create(self);
  FTelnet.OnConnect    := @SockConnect;
  FTelnet.OnDisconnect := @SockDisconnect;
  FTelnet.OnReceive    := @SockReceive;
  FTelnet.OnError      := @SockError
end;

destructor TRbnConnection.Destroy;
begin
  FTimer.Enabled := False;
  FWatchdog.Enabled := False;
  SetLength(FSpotSubs, 0);
  SetLength(FStateSubs, 0);
  if FTelnet.Connected then
    FTelnet.Disconnect;
  FreeAndNil(FFramer);
  if MainConnection = self then
    MainConnection := nil;
  inherited Destroy
end;

procedure TRbnConnection.SetState(AState : TRbnConnState; const AStatus : String);
var
  i    : Integer;
  Subs : array of TRbnStateEvent;
begin
  FState  := AState;
  FStatus := AStatus;
  DbgLog('RBN', 'connection: ' + AStatus);
  //a handler may unsubscribe while it is being called
  Subs := Copy(FStateSubs);
  for i := 0 to High(Subs) do
    Subs[i](self)
end;

procedure TRbnConnection.Connect(const AHost : String; APort : Integer; const AUserName : String);
begin
  FHost     := AHost;
  FPort     := APort;
  FUserName := AUserName;
  FReconnect.UserConnect;
  FTimer.Enabled := False;
  if FTelnet.Connected then
    FTelnet.Disconnect;
  OpenSocket
end;

procedure TRbnConnection.Disconnect;
begin
  //first, so that the socket's own OnDisconnect does not schedule a reconnect
  FReconnect.UserDisconnect;
  FTimer.Enabled := False;
  FWatchdog.Enabled := False;
  FTelnet.Disconnect;
  SetState(rcsDisconnected, 'Disconnected')
end;

procedure TRbnConnection.OpenSocket;
begin
  SetState(rcsConnecting, 'Connecting to ' + FHost + ':' + IntToStr(FPort) + ' ...');
  FTelnet.Host := FHost;
  FTelnet.Port := FPort;
  //lNet resolves the host name here, synchronously
  FTelnet.Connect
end;

//Lost or could not be made. Tries again with a growing delay for as long as the
//user wants to be connected; never after Disconnect, never to another server
procedure TRbnConnection.ScheduleReconnect(const Why : String);
begin
  if not FReconnect.ShouldReconnect then
  begin
    SetState(rcsDisconnected, Why);
    exit
  end;
  //TimerTick arms the timer before its attempt, then only the status changes
  if not FTimer.Enabled then
  begin
    FTimer.Interval := FReconnect.NextDelaySec * 1000;
    FTimer.Enabled  := True
  end;
  SetState(rcsWaiting, Why + ', next try in ' + IntToStr(FTimer.Interval div 1000) + ' s')
end;

procedure TRbnConnection.TimerTick(Sender : TObject);
begin
  FTimer.Enabled := False;
  if (not FReconnect.ShouldReconnect) or FTelnet.Connected then
    exit;
  //armed again before the attempt: a Connect that fails without any event must
  //not end the retries. SockConnect switches the timer off
  FTimer.Interval := FReconnect.NextDelaySec * 1000;
  FTimer.Enabled  := True;
  OpenSocket
end;

procedure TRbnConnection.SockConnect(aSocket : TLSocket);
begin
  FFramer.Reset;
  FLogin.Reset;
  FReconnect.Connected;
  FTimer.Enabled := False;
  FLastRx := Now;
  FWatchdog.Enabled := True;
  SetState(rcsConnected, 'Connected to RBN')
end;

//Seen 2026-09-22: after "Connection reset by peer" the socket reconnected in
//250 ms, reported Connected, and then nothing arrived for the rest of the
//evening -- no error, no disconnect, no spots. The socket cannot tell a dead
//session from a quiet one; the spot rate can
procedure TRbnConnection.WatchdogTick(Sender : TObject);
begin
  if FState <> rcsConnected then
    exit;
  if (Now - FLastRx) * SecsPerDay < RBN_SILENCE_SEC then
    exit;
  FWatchdog.Enabled := False;
  DbgLog('RBN', 'connection: no data for ' + IntToStr(RBN_SILENCE_SEC) +
                ' s while connected, login answered=' + BoolToStr(FLogin.Answered, True) +
                ', reconnecting');
  //our own Disconnect raises no OnDisconnect, so schedule the retry here
  FTelnet.Disconnect;
  ScheduleReconnect('Silent connection dropped')
end;

procedure TRbnConnection.SockDisconnect(aSocket : TLSocket);
begin
  FWatchdog.Enabled := False;
  ScheduleReconnect('Disconnected')
end;

procedure TRbnConnection.SockError(const msg : string; aSocket : TLSocket);
begin
  FWatchdog.Enabled := False;
  ScheduleReconnect('Error: ' + msg)
end;

procedure TRbnConnection.AnswerLogin(const Text : String);
begin
  if (FUserName <> '') and FLogin.ShouldAnswer(Text) then
  begin
    DbgLog('RBN', 'connection: login prompt "' + Trim(Text) + '", sending ' + FUserName);
    FTelnet.SendMessage(FUserName + #13#10)
  end
end;

procedure TRbnConnection.SockReceive(aSocket : TLSocket);
var
  Buffer : String;
  Line   : String;
  Spot   : TRbnSpotLine;
  Subs   : array of TRbnSpotEvent;
  i      : Integer;
begin
  if FTelnet.GetMessage(Buffer) = 0 then
    exit;
  FLastRx := Now;
  //GetMessage returns what has arrived so far, not lines
  FFramer.Feed(Buffer);
  while FFramer.NextLine(Line) do
  begin
    if ParseRbnSpot(Line, Spot) then
    begin
      CountSpot;
      Subs := Copy(FSpotSubs);
      for i := 0 to High(Subs) do
        Subs[i](Line, Spot)
    end
    else begin
      //banner, prompt, server messages: a few lines per session, and the only
      //trace of what the server said when no spots follow
      if Trim(Line) <> '' then
        DbgLog('RBN', 'connection: server: ' + Copy(Trim(Line), 1, 120));
      AnswerLogin(Line)
    end
  end;
  //the prompt comes without a line end
  AnswerLogin(FFramer.Pending);
  FTelnet.CallAction
end;

//minutes that passed without a spot are zeroed as the ring moves on
procedure TRbnConnection.AdvanceRate(ToMinute : Int64);
var
  i : Integer;
begin
  if (FRateMin = 0) or (ToMinute - FRateMin >= RBN_RATE_MINUTES) then
  begin
    for i := 0 to High(FRate) do
      FRate[i] := 0;
    FRateMin := ToMinute
  end;
  while FRateMin < ToMinute do
  begin
    Inc(FRateMin);
    FRate[FRateMin mod RBN_RATE_MINUTES] := 0
  end
end;

procedure TRbnConnection.CountSpot;
var
  m : Int64;
begin
  m := Trunc(Now * 1440);
  AdvanceRate(m);
  Inc(FRate[m mod RBN_RATE_MINUTES]);
  Inc(FTotal)
end;

function TRbnConnection.SpotsLastMinutes : Integer;
var
  i : Integer;
begin
  AdvanceRate(Trunc(Now * 1440));
  Result := 0;
  for i := 0 to High(FRate) do
    Result := Result + FRate[i]
end;

procedure TRbnConnection.SubscribeSpots(Handler : TRbnSpotEvent);
begin
  UnsubscribeSpots(Handler);
  SetLength(FSpotSubs, Length(FSpotSubs) + 1);
  FSpotSubs[High(FSpotSubs)] := Handler
end;

procedure TRbnConnection.UnsubscribeSpots(Handler : TRbnSpotEvent);
var
  i, j : Integer;
begin
  for i := High(FSpotSubs) downto 0 do
    if SameMethod(TMethod(FSpotSubs[i]), TMethod(Handler)) then
    begin
      for j := i to High(FSpotSubs) - 1 do
        FSpotSubs[j] := FSpotSubs[j+1];
      SetLength(FSpotSubs, Length(FSpotSubs) - 1)
    end
end;

procedure TRbnConnection.SubscribeState(Handler : TRbnStateEvent);
begin
  UnsubscribeState(Handler);
  SetLength(FStateSubs, Length(FStateSubs) + 1);
  FStateSubs[High(FStateSubs)] := Handler
end;

procedure TRbnConnection.UnsubscribeState(Handler : TRbnStateEvent);
var
  i, j : Integer;
begin
  for i := High(FStateSubs) downto 0 do
    if SameMethod(TMethod(FStateSubs[i]), TMethod(Handler)) then
    begin
      for j := i to High(FStateSubs) - 1 do
        FStateSubs[j] := FStateSubs[j+1];
      SetLength(FStateSubs, Length(FStateSubs) - 1)
    end
end;

end.
