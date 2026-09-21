(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Turns the byte stream of a telnet connection into lines.

  TLTelnetClient.GetMessage returns whatever has arrived so far: a spot can be
  cut anywhere, CR and LF can come in two reads, one read can carry a dozen
  spots.  The old lReceive handlers parsed every read on its own and threw the
  unfinished tail away.

  No LCL, no threads, no I/O -- see tests/tLineFramer.pas.  Not thread safe; it
  belongs to whoever owns the socket. }

unit uRbnLineFramer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  //a spot is about 80 characters.  Anything this long without a line end is not
  //an RBN server, and the buffer must not grow with it
  MAX_RBN_LINE_LENGTH = 1024;

type
  TRbnLineFramer = class
  private
    FBuf      : String;
    FDropping : Boolean; //inside an overlong line, skipping up to its end
  public
    procedure Feed(const Chunk : String);
    //complete lines in the order they came, without CR/LF; blank ones are skipped
    function  NextLine(out Line : String) : Boolean;
    //the unfinished tail.  The login prompt comes without a line end
    function  Pending : String;
    procedure Reset;
  end;

implementation

uses
  StrUtils;

const
  LF = #10;
  CR = #13;

procedure TRbnLineFramer.Feed(const Chunk : String);
var
  p    : Integer;
  Tail : Integer;
begin
  if FDropping then
  begin
    p := Pos(LF, Chunk);
    if p = 0 then
      exit;
    FDropping := False;
    FBuf := Copy(Chunk, p+1, Length(Chunk))
  end
  else
    FBuf := FBuf + Chunk;

  Tail := Length(FBuf) - RPos(LF, FBuf);
  if Tail > MAX_RBN_LINE_LENGTH then
  begin
    SetLength(FBuf, Length(FBuf) - Tail);
    FDropping := True
  end
end;

function TRbnLineFramer.NextLine(out Line : String) : Boolean;
var
  p : Integer;
begin
  Result := False;
  Line := '';
  repeat
    p := Pos(LF, FBuf);
    if p = 0 then
      exit;
    Line := Copy(FBuf, 1, p-1);
    Delete(FBuf, 1, p);
    if (Line <> '') and (Line[Length(Line)] = CR) then
      SetLength(Line, Length(Line)-1)
  until Trim(Line) <> '';
  Result := True
end;

function TRbnLineFramer.Pending : String;
begin
  Result := FBuf
end;

procedure TRbnLineFramer.Reset;
begin
  FBuf := '';
  FDropping := False
end;

end.
