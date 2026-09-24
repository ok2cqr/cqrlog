(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Questions for the log check thread of the graphical band maps.

  A window that meets a station the log cache does not know yet must not ask
  the database itself: one round trip to a server in the LAN is ~30 ms, and a
  cold cache after start-up means hundreds of them, which froze the GUI thread
  and starved the RBN socket. Instead the window pushes the question here,
  shows the spot for now, and a thread answers into the shared cache. The
  same station is queued once however many windows ask; once answered it can
  be asked again (the cache entry may have expired).  A club membership
  question (call and day) goes through the same queue and thread, so the
  club tables see one round trip per station too.

  Thread safe, no LCL. }

unit uLogCheckQueue;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TLogCheckKind = (lckWorked, lckMembership);

  TLogCheckRequest = record
    Kind             : TLogCheckKind;
    Call, Band, Mode : String;     //Band and Mode for lckWorked
    Date             : String;     //the day asked, for lckMembership
  end;

  TLogCheckQueue = class
    private
      FCrit  : TRTLCriticalSection;
      FItems : array of TLogCheckRequest;
      FKeys  : TStringList;   //sorted, one per queued question
      FHead  : Integer;
      procedure Add(const R : TLogCheckRequest; const AKey : String);
    public
      constructor Create;
      destructor  Destroy; override;
      procedure Push(const ACall, ABand, AMode : String);
      procedure PushMembership(const ACall, ADate : String);
      function  Pop(out R : TLogCheckRequest) : Boolean;
      function  Count : Integer;
      procedure Clear;
  end;

implementation

constructor TLogCheckQueue.Create;
begin
  inherited Create;
  InitCriticalSection(FCrit);
  FKeys := TStringList.Create;
  FKeys.Sorted := True;
  FKeys.Duplicates := dupIgnore
end;

destructor TLogCheckQueue.Destroy;
begin
  FKeys.Free;
  DoneCriticalSection(FCrit);
  inherited Destroy
end;

function KeyOf(const R : TLogCheckRequest) : String;
begin
  if R.Kind = lckMembership then
    Result := 'M|' + UpperCase(R.Call) + '|' + R.Date
  else
    Result := 'W|' + UpperCase(R.Call) + '|' + R.Band + '|' + R.Mode
end;

procedure TLogCheckQueue.Add(const R : TLogCheckRequest; const AKey : String);
var
  i : Integer;
begin
  EnterCriticalSection(FCrit);
  try
    if FKeys.IndexOf(AKey) >= 0 then
      exit;
    FKeys.Add(AKey);
    i := Length(FItems);
    SetLength(FItems, i+1);
    FItems[i] := R
  finally
    LeaveCriticalSection(FCrit)
  end
end;

procedure TLogCheckQueue.Push(const ACall, ABand, AMode : String);
var
  R : TLogCheckRequest;
begin
  R := Default(TLogCheckRequest);
  R.Kind     := lckWorked;
  R.Call     := ACall;
  R.Band     := ABand;
  R.Mode     := AMode;
  Add(R, KeyOf(R))
end;

procedure TLogCheckQueue.PushMembership(const ACall, ADate : String);
var
  R : TLogCheckRequest;
begin
  R := Default(TLogCheckRequest);
  R.Kind     := lckMembership;
  R.Call     := ACall;
  R.Date     := ADate;
  Add(R, KeyOf(R))
end;

function TLogCheckQueue.Pop(out R : TLogCheckRequest) : Boolean;
var
  i : Integer;
begin
  R := Default(TLogCheckRequest);
  EnterCriticalSection(FCrit);
  try
    Result := FHead < Length(FItems);
    if not Result then
      exit;
    R := FItems[FHead];
    Inc(FHead);
    i := FKeys.IndexOf(KeyOf(R));
    if i >= 0 then
      FKeys.Delete(i);
    //the answered part is dropped in one go once it is all gone
    if FHead >= Length(FItems) then
    begin
      FItems := nil;
      FHead  := 0
    end
  finally
    LeaveCriticalSection(FCrit)
  end
end;

function TLogCheckQueue.Count : Integer;
begin
  EnterCriticalSection(FCrit);
  try
    Result := Length(FItems) - FHead
  finally
    LeaveCriticalSection(FCrit)
  end
end;

procedure TLogCheckQueue.Clear;
begin
  EnterCriticalSection(FCrit);
  try
    FItems := nil;
    FHead  := 0;
    FKeys.Clear
  finally
    LeaveCriticalSection(FCrit)
  end
end;

end.
