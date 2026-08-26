(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ A small always-on log file, for diagnosing failures that only show up in a
  long-running session.

  CQRLOG's existing debug output is Writeln to stdout, which is invisible when
  the program is started from Finder or a desktop launcher rather than from a
  terminal -- exactly the situation where a background thread dying after half
  an hour has to be diagnosed.  This unit appends to

      <config dir>/cqrlog-debug.log

  which is next to cqrlog.cfg, so a user can find and send it.

  Deliberately depends on nothing but the RTL: no dData, no LCL.  Every unit,
  including the data modules, may use it without creating a circular reference.

  The file is opened and closed around every write.  That is slow, and it does
  not matter: this logs thread lifecycle and exceptions, not spot traffic.  The
  point is that nothing is lost if the process dies immediately afterwards. }

unit uDebugLog;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

{ Appends one line.  Section is a short tag identifying the caller, e.g. 'RBN'
  or 'DXC'.  Never raises: a logger that can take the program down is worse
  than no logger. }
procedure DbgLog(const Section, Message: string);

{ As DbgLog, plus the exception class, its message, and whatever backtrace the
  RTL can still produce.  Call from inside an except block -- it reads
  ExceptAddr/ExceptFrames, which are only valid there.

  Context is whatever input was being processed, and is the most useful part of
  the record: it is what makes the failure reproducible. }
procedure DbgLogException(const Section, Context: string; E: Exception);

{ Full path of the log file, for showing the user where to look. }
function DbgLogFileName: string;

implementation

var
  LogLock  : TRTLCriticalSection;
  LogPath  : string = '';
  Ready    : Boolean = False;

function DbgLogFileName: string;
begin
  if LogPath = '' then
    LogPath := GetAppConfigDir(False) + 'cqrlog-debug.log';
  Result := LogPath;
end;

procedure WriteLine(const Line: string);
var
  F: TextFile;
begin
  AssignFile(F, DbgLogFileName);
  try
    //on a first run the config directory may not exist yet, and a Rewrite into
    //a missing directory would fail silently in the handler below
    if not DirectoryExists(ExtractFilePath(DbgLogFileName)) then
      ForceDirectories(ExtractFilePath(DbgLogFileName));
    if FileExists(DbgLogFileName) then
      Append(F)
    else
      Rewrite(F);
    try
      WriteLn(F, Line);
    finally
      CloseFile(F);
    end;
  except
    { A failed log write must never propagate. }
  end;
end;

procedure Emit(const Section, Body: string);
var
  Line: string;
begin
  Line := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) +
          ' [' + IntToStr(PtrUInt(GetCurrentThreadId)) + '] ' +
          Section + ': ' + Body;
  if not Ready then
    Exit;
  EnterCriticalSection(LogLock);
  try
    WriteLine(Line);
  finally
    LeaveCriticalSection(LogLock);
  end;
end;

procedure DbgLog(const Section, Message: string);
begin
  try
    Emit(Section, Message);
  except
  end;
end;

procedure DbgLogException(const Section, Context: string; E: Exception);
var
  Body: string;
  I: Integer;
  Frames: PPointer;
begin
  try
    if E <> nil then
      Body := 'EXCEPTION ' + E.ClassName + ': ' + E.Message
    else
      Body := 'EXCEPTION (no object)';
    if Context <> '' then
      Body := Body + ' | while: ' + Context;

    { Addresses only symbolise in a binary that still has its debug info --
      build with `make debug`, which skips the strip step. }
    Body := Body + LineEnding + '    at ' + BackTraceStrFunc(ExceptAddr);
    Frames := ExceptFrames;
    for I := 0 to ExceptFrameCount - 1 do
      Body := Body + LineEnding + '    ' + BackTraceStrFunc(Frames[I]);

    Emit(Section, Body);
  except
  end;
end;

initialization
  InitCriticalSection(LogLock);
  Ready := True;

finalization
  Ready := False;
  DoneCriticalSection(LogLock);

end.
