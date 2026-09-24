(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Bounded, thread safe queue of spots between the socket and the worker: each
  line with the spot the connection parsed from it, so the worker does not
  parse it again and still has the line for its diagnostics.

  When it is full the OLDEST line goes: on a live display the spot that has
  waited the longest is worth the least, and dropping the newest would freeze
  the display in the past for as long as the overload lasts.  Every loss is
  counted, so the debug log can tell "overloaded" from "quiet band".

  No LCL; see tests/tSpotQueue.pas. }

unit uRbnSpotQueue;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uRbnSpotParser;

type
  TRbnQueuedSpot = record
    Line : String;
    Spot : TRbnSpotLine;
  end;

  TRbnSpotQueue = class
  private
    FCrit    : TRTLCriticalSection;
    FItems   : array of TRbnQueuedSpot;  //ring buffer
    FHead    : Integer;          //index of the oldest line
    FCount   : Integer;
    FDropped : Int64;
  public
    constructor Create(ACapacity : Integer);
    destructor Destroy; override;
    procedure Push(const Line : String; const Spot : TRbnSpotLine);
    function  Pop(out Line : String; out Spot : TRbnSpotLine) : Boolean;
    procedure Clear;   //a new connection; not counted as a loss
    function  Count : Integer;
    function  Dropped : Int64;  //since the queue was created
  end;

implementation

constructor TRbnSpotQueue.Create(ACapacity : Integer);
begin
  inherited Create;
  if ACapacity < 1 then
    ACapacity := 1;
  SetLength(FItems, ACapacity);
  InitCriticalSection(FCrit)
end;

destructor TRbnSpotQueue.Destroy;
begin
  DoneCriticalsection(FCrit);
  inherited Destroy
end;

procedure TRbnSpotQueue.Push(const Line : String; const Spot : TRbnSpotLine);
var
  i : Integer;
begin
  EnterCriticalsection(FCrit);
  try
    if FCount = Length(FItems) then
    begin
      FHead := (FHead + 1) mod Length(FItems);
      Dec(FCount);
      Inc(FDropped)
    end;
    i := (FHead + FCount) mod Length(FItems);
    FItems[i].Line := Line;
    FItems[i].Spot := Spot;
    Inc(FCount)
  finally
    LeaveCriticalsection(FCrit)
  end
end;

function TRbnSpotQueue.Pop(out Line : String; out Spot : TRbnSpotLine) : Boolean;
begin
  Line := '';
  Spot := Default(TRbnSpotLine);
  EnterCriticalsection(FCrit);
  try
    Result := FCount > 0;
    if Result then
    begin
      Line := FItems[FHead].Line;
      Spot := FItems[FHead].Spot;
      FItems[FHead] := Default(TRbnQueuedSpot);
      FHead := (FHead + 1) mod Length(FItems);
      Dec(FCount)
    end
  finally
    LeaveCriticalsection(FCrit)
  end
end;

procedure TRbnSpotQueue.Clear;
var
  i : Integer;
begin
  EnterCriticalsection(FCrit);
  try
    for i := 0 to High(FItems) do
      FItems[i] := Default(TRbnQueuedSpot);
    FHead  := 0;
    FCount := 0
  finally
    LeaveCriticalsection(FCrit)
  end
end;

function TRbnSpotQueue.Count : Integer;
begin
  EnterCriticalsection(FCrit);
  try
    Result := FCount
  finally
    LeaveCriticalsection(FCrit)
  end
end;

function TRbnSpotQueue.Dropped : Int64;
begin
  EnterCriticalsection(FCrit);
  try
    Result := FDropped
  finally
    LeaveCriticalsection(FCrit)
  end
end;

end.
