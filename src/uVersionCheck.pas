(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

// Check for a newer CQRLOG release on GitHub.
//
// No LCL here: this unit fetches and parses the "latest release" record and
// compares it with the running version.  The dialog and the worker thread
// live in fNewVersion; the startup gate ([Program] VersionCheck) is read by
// fNewQSO.  Everything here may be called from a worker thread: cqrini is
// critical-section wrapped and nothing else is shared.

unit uVersionCheck;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  cLatestReleaseUrl      = 'https://api.github.com/repos/ok2cqr/cqrlog/releases/latest';
  cVersionCheckTimeoutMs = 10000;

type
  TReleaseInfo = record
    Tag         : String;   // 'v3.0.1'
    Name        : String;   // 'CQRLOG v3.0.1'
    HtmlUrl     : String;
    PublishedAt : String;   // 'YYYY-MM-DD'
    Body        : String;   // plain-text release notes, platform line endings
    Major       : Integer;
    Minor       : Integer;
    Release     : Integer;
  end;

// Downloads and parses the latest published release (drafts and
// prereleases are not returned by that endpoint).  False with ErrMsg on a
// network, HTTP or JSON failure; never raises.
function  FetchLatestRelease(out Info: TReleaseInfo; out ErrMsg: String): Boolean;

// 'v3.0.1', '3.0.1', 'v3.1.0-rc1' -> (3,0,1) / (3,1,0).  Missing parts are 0.
// False when no leading number is found at all.
function  ParseVersionTag(const Tag: String; out Major, Minor, Release: Integer): Boolean;

// Compares with cMAJOR/cMINOR/cRELEAS from uVersion.
function  IsNewerThanRunning(Major, Minor, Release: Integer): Boolean;

// '3.0.0' - the running version without the widget set suffix.
function  RunningVersionString: String;

// Tag the user asked not to be reminded about ([Program] VersionCheckSkipped).
function  SkippedVersionTag: String;
procedure SetSkippedVersionTag(const Tag: String);   // '' removes the key

implementation

uses
  httpsend, ssl_openssl, fpjson, jsonparser, uMyIni, uVersion;

function HttpGet(const Url: String; out Data, ErrMsg: String): Boolean;
var
  HTTP : THTTPSend;
  m    : TStringList;
begin
  Result := False;
  Data   := '';
  ErrMsg := '';
  HTTP := THTTPSend.Create;
  m    := TStringList.Create;
  try
    if Assigned(cqrini) then   // nil in a standalone test program
    begin
      HTTP.ProxyHost := cqrini.ReadString('Program', 'Proxy', '');
      HTTP.ProxyPort := cqrini.ReadString('Program', 'Port', '');
      HTTP.UserName  := cqrini.ReadString('Program', 'User', '');
      HTTP.Password  := cqrini.ReadString('Program', 'Passwd', '')
    end;
    HTTP.UserAgent := 'CQRLOG/' + cVERSION;   // GitHub answers 403 without one
    HTTP.Headers.Add('Accept: application/vnd.github+json');
    HTTP.Timeout := cVersionCheckTimeoutMs;                 // send/receive
    HTTP.Sock.ConnectionTimeout := cVersionCheckTimeoutMs;  // connect
    if not HTTP.HTTPMethod('GET', Url) then
    begin
      ErrMsg := 'Could not connect to api.github.com';
      if HTTP.Sock.LastErrorDesc <> '' then
        ErrMsg := ErrMsg + ' (' + HTTP.Sock.LastErrorDesc + ')';
      exit
    end;
    if HTTP.ResultCode <> 200 then
    begin
      ErrMsg := 'GitHub returned HTTP ' + IntToStr(HTTP.ResultCode) + ' ' + HTTP.ResultString;
      exit
    end;
    m.LoadFromStream(HTTP.Document);
    Data   := Trim(m.Text);
    Result := True
  finally
    HTTP.Free;
    m.Free
  end
end;

function JsonString(Root: TJSONData; const Path: String): String;
var
  Node : TJSONData;
begin
  Node := Root.FindPath(Path);   // nil when the key is missing
  if (Node = nil) or Node.IsNull then
    Result := ''
  else
    Result := Node.AsString
end;

function ParseReleaseJson(const Data: String; out Info: TReleaseInfo; out ErrMsg: String): Boolean;
var
  Root : TJSONData;
begin
  Result := False;
  ErrMsg := '';
  Info   := Default(TReleaseInfo);
  try
    Root := GetJSON(Data)   // raises on HTML from a captive portal and the like
  except
    on E: Exception do
    begin
      ErrMsg := 'Cannot parse the GitHub response: ' + E.Message;
      exit
    end
  end;
  try
    Info.Tag         := JsonString(Root, 'tag_name');
    Info.Name        := JsonString(Root, 'name');
    Info.HtmlUrl     := JsonString(Root, 'html_url');
    Info.PublishedAt := Copy(JsonString(Root, 'published_at'), 1, 10);  // '2026-08-15T12:21:52Z'
    Info.Body        := AdjustLineBreaks(JsonString(Root, 'body'));      // GitHub sends CRLF
    if Info.Tag = '' then
    begin
      ErrMsg := 'The GitHub response has no tag_name';
      exit
    end;
    if not ParseVersionTag(Info.Tag, Info.Major, Info.Minor, Info.Release) then
    begin
      ErrMsg := 'Cannot understand the release tag "' + Info.Tag + '"';
      exit
    end;
    Result := True
  finally
    Root.Free
  end
end;

function FetchLatestRelease(out Info: TReleaseInfo; out ErrMsg: String): Boolean;
var
  Data : String;
begin
  Info   := Default(TReleaseInfo);
  Result := HttpGet(cLatestReleaseUrl, Data, ErrMsg) and
            ParseReleaseJson(Data, Info, ErrMsg)
end;

function ParseVersionTag(const Tag: String; out Major, Minor, Release: Integer): Boolean;
var
  s    : String;
  i    : Integer;
  Part : Integer;
  Cur  : String;
  Num  : array[0..2] of Integer;

  procedure Flush;
  begin
    if Cur = '' then
      exit;
    if Part <= 2 then
      Num[Part] := StrToIntDef(Cur, 0);
    inc(Part);
    Cur := ''
  end;

begin
  Num[0] := 0;
  Num[1] := 0;
  Num[2] := 0;
  Part := 0;
  Cur  := '';
  s := Trim(Tag);
  if (s <> '') and (UpCase(s[1]) = 'V') then
    Delete(s, 1, 1);
  for i := 1 to Length(s) do
  begin
    if s[i] in ['0'..'9'] then
      Cur := Cur + s[i]
    else if s[i] = '.' then
      Flush
    else
      break   // '-rc1', '_x' and the like end the number
  end;
  Flush;
  Major   := Num[0];
  Minor   := Num[1];
  Release := Num[2];
  Result  := Part >= 1
end;

function IsNewerThanRunning(Major, Minor, Release: Integer): Boolean;
begin
  if Major <> cMAJOR then
    Exit(Major > cMAJOR);
  if Minor <> cMINOR then
    Exit(Minor > cMINOR);
  Result := Release > cRELEAS
end;

function RunningVersionString: String;
begin
  Result := IntToStr(cMAJOR) + '.' + IntToStr(cMINOR) + '.' + IntToStr(cRELEAS)
end;

function SkippedVersionTag: String;
begin
  if Assigned(cqrini) then
    Result := cqrini.ReadString('Program', 'VersionCheckSkipped', '')
  else
    Result := ''
end;

procedure SetSkippedVersionTag(const Tag: String);
begin
  if not Assigned(cqrini) then
    exit;
  if Tag = '' then
    cqrini.DeleteKey('Program', 'VersionCheckSkipped')
  else
    cqrini.WriteString('Program', 'VersionCheckSkipped', Tag);
  cqrini.SaveToDisk
end;

end.
