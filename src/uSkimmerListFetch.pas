(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The RBN skimmer locators of rbn/uSkimmerLocations, kept in
  <home dir>/rbn_skimmers.json and refreshed from HamQTH at most once a day in
  a worker thread.  A failed download keeps the old file; without any file the
  skimmers stay where their prefix puts them.  Main thread only, except the
  worker, which touches nothing but its own fields and the file. }

unit uSkimmerListFetch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uSkimmerLocations;

//the list, loaded from the file on first use; never nil
function  SkimmerList : TSkimmerLocations;
//loads the file on the first call and starts a download when the file is older
//than a day; a new list is used from the next spot on
procedure RefreshSkimmerList(const HomeDir : String);

implementation

uses
  httpsend, ssl_openssl, synautil, uMyIni, uVersion;

const
  SKIMMER_FILE      = 'rbn_skimmers.json';
  MAX_AGE_DAYS      = 1;
  TIMEOUT_MS        = 15000;
  //HamQTH keeps the last good list itself (about 370 nodes); far fewer means a
  //broken answer, not that the skimmers went away
  MIN_SKIMMERS      = 50;
  //a failed download is tried again after an hour, not on every window open
  RETRY_DAYS        = 1/24;

type
  TSkimmerListThread = class(TThread)
  private
    FFileName : String;
    FProxyHost, FProxyPort, FProxyUser, FProxyPass : String;
    FLoaded   : Boolean;  //a new file was written
  protected
    procedure Execute; override;
  end;

var
  List      : TSkimmerLocations = nil;
  ListFile  : String = '';
  Running   : Boolean = False;
  LastTry   : TDateTime = 0;

type
  TThreadDone = class
    class procedure Done(Sender : TObject);
  end;

function SkimmerList : TSkimmerLocations;
begin
  if List = nil then
    List := TSkimmerLocations.Create;
  Result := List
end;

procedure TSkimmerListThread.Execute;
var
  HTTP  : THTTPSend;
  Data  : TStringList;
  Check : TSkimmerLocations;
  Tmp   : String;
begin
  HTTP  := THTTPSend.Create;
  Data  := TStringList.Create;
  Check := TSkimmerLocations.Create;
  try
    HTTP.ProxyHost := FProxyHost;
    HTTP.ProxyPort := FProxyPort;
    HTTP.UserName  := FProxyUser;
    HTTP.Password  := FProxyPass;
    HTTP.UserAgent := 'CQRLOG/' + cVERSION;
    HTTP.Timeout   := TIMEOUT_MS;
    HTTP.Sock.ConnectionTimeout := TIMEOUT_MS;
    if FileExists(FFileName) then
      HTTP.Headers.Add('If-Modified-Since: ' + Rfc822DateTime(FileDateToDateTime(FileAge(FFileName))));
    if not HTTP.HTTPMethod('GET', SKIMMER_LIST_URL) then
      exit;
    if HTTP.ResultCode = 304 then
    begin
      FileSetDate(FFileName, DateTimeToFileDate(Now));  //still current, ask again tomorrow
      exit
    end;
    if HTTP.ResultCode <> 200 then
      exit;
    Data.LoadFromStream(HTTP.Document);
    if (not Check.LoadFromJson(Data.Text)) or (Check.Count < MIN_SKIMMERS) then
      exit;
    Tmp := FFileName + '.tmp';
    Data.SaveToFile(Tmp);
    FLoaded := RenameFile(Tmp, FFileName)
  finally
    Check.Free;
    Data.Free;
    HTTP.Free
  end
end;

class procedure TThreadDone.Done(Sender : TObject);
begin
  Running := False;
  if TSkimmerListThread(Sender).FLoaded then
    SkimmerList.LoadFromFile(ListFile)
end;

procedure RefreshSkimmerList(const HomeDir : String);
var
  T : TSkimmerListThread;
begin
  ListFile := IncludeTrailingPathDelimiter(HomeDir) + SKIMMER_FILE;
  if SkimmerList.Count = 0 then
    SkimmerList.LoadFromFile(ListFile);
  if Running or (Now - LastTry < RETRY_DAYS) or (not SkimmerListIsStale(ListFile, MAX_AGE_DAYS)) then
    exit;
  Running := True;
  LastTry := Now;
  T := TSkimmerListThread.Create(True);
  T.FFileName  := ListFile;
  T.FProxyHost := cqrini.ReadString('Program', 'Proxy', '');
  T.FProxyPort := cqrini.ReadString('Program', 'Port', '');
  T.FProxyUser := cqrini.ReadString('Program', 'User', '');
  T.FProxyPass := cqrini.ReadString('Program', 'Passwd', '');
  T.OnTerminate := @TThreadDone.Done;
  T.FreeOnTerminate := True;
  T.Start
end;

finalization
  FreeAndNil(List);

end.
