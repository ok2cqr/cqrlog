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
  be asked again (the cache entry may have expired).

  Thread safe, no LCL. }

unit uLogCheckQueue;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TLogCheckRequest = record
    Call, Band, Mode   : String;
    LastDate, LastTime : String;
  end;

  TLogCheckQueue = class
    private
      FCrit  : TRTLCriticalSection;
      FItems : array of TLogCheckRequest;
      FKeys  : TStringList;   //sorted, one per queued (call|band|mode)
      FHead  : Integer;
    public
      constructor Create;
      destructor  Destroy; override;
      procedure Push(const ACall, ABand, AMode, ALastDate, ALastTime : String);
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

procedure TLogCheckQueue.Push(const ACall, ABand, AMode, ALastDate, ALastTime : String);
var
  key : String;
  i   : Integer;
begin
  key := UpperCase(ACall) + '|' + ABand + '|' + AMode;
  EnterCriticalSection(FCrit);
  try
    if FKeys.IndexOf(key) >= 0 then
      exit;
    FKeys.Add(key);
    i := Length(FItems);
    SetLength(FItems, i+1);
    FItems[i].Call     := ACall;
    FItems[i].Band     := ABand;
    FItems[i].Mode     := AMode;
    FItems[i].LastDate := ALastDate;
    FItems[i].LastTime := ALastTime
  finally
    LeaveCriticalSection(FCrit)
  end
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
    i := FKeys.IndexOf(UpperCase(R.Call) + '|' + R.Band + '|' + R.Mode);
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
