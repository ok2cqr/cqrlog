unit uGnuPG;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, Forms;

type
  TGnuPGVerifyResult = (vgValid, vgInvalidSignature, vgKeyNotFound, vgError);

function GnuPGSign(const AData: string; const AKeyFingerprint: string;
  out ASignature: string): Boolean;

function GnuPGVerify(const AData: string; const ASignature: string;
  out ACallsign: string; out AFingerprint: string): TGnuPGVerifyResult;

function GnuPGLookupKey(const ACallsign: string;
  out AFingerprint: string): Boolean;

function GnuPGFetchKeyFromServer(const ACallsign: string;
  const AKeyserver: string; out AFingerprint: string): Boolean;

function GnuPGGetLocalKeyFingerprint(out AFingerprint: string): Boolean;

function GnuPGKeyExistsInKeyring(const AFingerprint: string): Boolean;

function GnuPGIconFile(const ABaseName: string): string;

procedure GnuPGLog(const AText: string);

function GnuPGVerifyWithKeyLookup(const AData: string; const ASignature: string;
  const ARemoteCallsign: string; out ACallsign: string; out AFingerprint: string;
  AKeyFetchSync: TThreadMethod = nil): TGnuPGVerifyResult; { GNUPG_AUTH: AKeyFetchSync via Synchronize }

implementation

uses
  StrUtils, dUtils, dData, uMyIni, uGnuPGKeyCache, LazFileUtils;

function CountLines(const AText: string): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(AText) do
    if AText[i] = #10 then
      Inc(Result);
  if (Length(AText) > 0) and (AText[Length(AText)] <> #10) then
    Inc(Result);
end;

function GetLine(const AText: string; ANumber: Integer): string;
var
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    sl.Text := AText;
    if (ANumber >= 1) and (ANumber <= sl.Count) then
      Result := sl.Strings[ANumber - 1]
    else
      Result := '';
  finally
    sl.Free;
  end;
end;

function GetField(const ALine: string; AIndex: Integer): string;
var
  Parts: TStringArray;
begin
  Parts := ALine.Split([' '], 0);
  if (AIndex >= 0) and (AIndex < Length(Parts)) then
    Result := Parts[AIndex]
  else
    Result := '';
end;

function GnuPGIconFile(const ABaseName: string): string;
begin
  Result := dmData.ShareDir + 'icon' + PathDelim + ABaseName;
  if not FileExistsUTF8(Result) then
    Result := ExpandFileNameUTF8(ExtractFilePath(ParamStr(0)) + '..' + PathDelim +
      'images' + PathDelim + 'icon' + PathDelim + ABaseName);
end;

procedure GnuPGLog(const AText: string);
begin
  dmUtils.SaveLog('GnuPG: ' + AText);
  if dmData.DebugLevel >= 1 then
    Writeln('GnuPG: ', AText);
end;

const
  cGnuPGTimeoutMs = 30000;

type
  TGnuPGKeyFetchThread = class(TThread) { GNUPG_AUTH }
  private
    FCallsign: string;
    FKeyserver: string;
    FSuccess: Boolean;
    FFingerprint: string;
    FSyncProc: TThreadMethod;
  protected
    procedure Execute; override;
    procedure DoSync;
  public
    constructor Create(const ACallsign, AKeyserver: string;
      ASyncProc: TThreadMethod);
    property Success: Boolean read FSuccess;
    property Fingerprint: string read FFingerprint;
  end;

function RunGpg(const AArgs: TStringList; out AOutput: string;
  out AExitCode: LongInt; AProcessMessages: Boolean = True): Boolean;
var
  AProcess: TProcess;
  OutList: TStringList;
  StartTick: QWord;
begin
  Result := False;
  AOutput := '';
  AExitCode := -1;
  if not FileExistsUTF8('/usr/bin/gpg') then
  begin
    GnuPGLog('gpg not found at /usr/bin/gpg');
    Exit;
  end;
  AProcess := TProcess.Create(nil);
  OutList := TStringList.Create;
  try
    AProcess.Executable := '/usr/bin/gpg';
    AProcess.Parameters.Assign(AArgs);
    AProcess.Options := [poUsePipes, poStderrToOutPut, poNoConsole];
    AProcess.ShowWindow := swoHide;
    AProcess.Execute;
    StartTick := GetTickCount64;
    while AProcess.Running do
    begin
      if (GetTickCount64 - StartTick) > cGnuPGTimeoutMs then
      begin
        GnuPGLog('gpg timed out: ' + AArgs.Text);
        AProcess.Terminate(0);
        Break;
      end;
      Sleep(50);
      if AProcessMessages and Assigned(Application) then
        Application.ProcessMessages;
    end;
    OutList.LoadFromStream(AProcess.Output);
    AOutput := OutList.Text;
    AExitCode := AProcess.ExitStatus;
    Result := True;
  finally
    OutList.Free;
    AProcess.Free;
  end;
end;

constructor TGnuPGKeyFetchThread.Create(const ACallsign, AKeyserver: string;
  ASyncProc: TThreadMethod);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FCallsign := ACallsign;
  FKeyserver := AKeyserver;
  FSyncProc := ASyncProc;
  FSuccess := False;
  FFingerprint := '';
end;

procedure TGnuPGKeyFetchThread.DoSync;
begin
  if Assigned(FSyncProc) then
    FSyncProc();
end;

procedure TGnuPGKeyFetchThread.Execute;
begin
  FSuccess := GnuPGFetchKeyFromServer(FCallsign, FKeyserver, FFingerprint);
  Synchronize(@DoSync);
end;

function GnuPGFetchKeyFromServerInThread(const ACallsign, AKeyserver: string;
  out AFingerprint: string; AKeyFetchSync: TThreadMethod): Boolean;
var
  FetchThread: TGnuPGKeyFetchThread;
begin
  Result := False;
  AFingerprint := '';
  FetchThread := TGnuPGKeyFetchThread.Create(ACallsign, AKeyserver, AKeyFetchSync);
  try
    FetchThread.Start;
    while not FetchThread.Finished do
    begin
      if Assigned(Application) then
        Application.ProcessMessages;
      Sleep(10);
    end;
    FetchThread.WaitFor;
    Result := FetchThread.Success;
    AFingerprint := FetchThread.Fingerprint;
  finally
    FetchThread.Free;
  end;
end;

function ExtractFingerprintFromColonLine(const ALine: string): string;
var
  Parts: TStringArray;
begin
  Result := '';
  if not StartsStr('fpr:', ALine) then
    Exit;
  Parts := ALine.Split(':');
  if Length(Parts) >= 10 then
    Result := Parts[9];
end;

function GnuPGGetLocalKeyFingerprint(out AFingerprint: string): Boolean;
var
  Args: TStringList;
  Output: string;
  ExitCode: LongInt;
  i: Integer;
  Line: string;
begin
  Result := False;
  AFingerprint := '';
  Args := TStringList.Create;
  try
    Args.Add('--batch');
    Args.Add('--with-colons');
    Args.Add('--list-secret-keys');
    if not RunGpg(Args, Output, ExitCode) then
      Exit;
    for i := 1 to CountLines(Output) do
    begin
      Line := GetLine(Output, i);
      if StartsStr('fpr:', Line) then
      begin
        AFingerprint := ExtractFingerprintFromColonLine(Line);
        if AFingerprint <> '' then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
  finally
    Args.Free;
  end;
end;

function GnuPGKeyExistsInKeyring(const AFingerprint: string): Boolean;
var
  Args: TStringList;
  Output: string;
  ExitCode: LongInt;
begin
  Result := False;
  if Trim(AFingerprint) = '' then
    Exit;
  Args := TStringList.Create;
  try
    Args.Add('--batch');
    Args.Add('--with-colons');
    Args.Add('--fingerprint');
    Args.Add('--list-keys');
    Args.Add(AFingerprint);
    if RunGpg(Args, Output, ExitCode) then
      Result := (ExitCode = 0) and (Pos('fpr:', Output) > 0);
  finally
    Args.Free;
  end;
end;

function GnuPGSign(const AData: string; const AKeyFingerprint: string;
  out ASignature: string): Boolean;
var
  Args: TStringList;
  DataFile, SigFile: string;
  Output: string;
  ExitCode: LongInt;
  sl: TStringList;
begin
  Result := False;
  ASignature := '';
  if (Trim(AKeyFingerprint) = '') or (AData = '') then
    Exit;
  DataFile := GetTempDir(false) + 'cqrlog_gnupg_' + IntToStr(GetProcessID) + '.dat';
  SigFile := ChangeFileExt(DataFile, '.asc');
  sl := TStringList.Create;
  Args := TStringList.Create;
  try
    sl.Text := AData;
    sl.SaveToFile(DataFile);
    Args.Add('--batch');
    Args.Add('--yes');
    Args.Add('--armor');
    Args.Add('--detach-sign');
    Args.Add('--local-user');
    Args.Add(AKeyFingerprint);
    Args.Add('--output');
    Args.Add(SigFile);
    Args.Add(DataFile);
    if not RunGpg(Args, Output, ExitCode) then
      Exit;
    if (ExitCode <> 0) or (not FileExistsUTF8(SigFile)) then
    begin
      GnuPGLog('sign failed: ' + Output);
      Exit;
    end;
    sl.LoadFromFile(SigFile);
    ASignature := Trim(sl.Text);
    Result := ASignature <> '';
  finally
    Args.Free;
    sl.Free;
    if FileExistsUTF8(DataFile) then
      DeleteFileUTF8(DataFile);
    if FileExistsUTF8(SigFile) then
      DeleteFileUTF8(SigFile);
  end;
end;

function GnuPGVerify(const AData: string; const ASignature: string;
  out ACallsign: string; out AFingerprint: string): TGnuPGVerifyResult;
var
  Args: TStringList;
  DataFile, SigFile: string;
  Output: string;
  ExitCode: LongInt;
  sl: TStringList;
  i: Integer;
  Line: string;
begin
  Result := vgError;
  ACallsign := '';
  AFingerprint := '';
  if (Trim(ASignature) = '') or (AData = '') then
    Exit;
  DataFile := GetTempDir(false) + 'cqrlog_gnupg_v_' + IntToStr(GetProcessID) + '.dat';
  SigFile := ChangeFileExt(DataFile, '.asc');
  sl := TStringList.Create;
  Args := TStringList.Create;
  try
    sl.Text := AData;
    sl.SaveToFile(DataFile);
    sl.Text := ASignature;
    sl.SaveToFile(SigFile);
    Args.Add('--batch');
    Args.Add('--status-fd');
    Args.Add('1');
    Args.Add('--verify');
    Args.Add(SigFile);
    Args.Add(DataFile);
    if not RunGpg(Args, Output, ExitCode) then
      Exit;
    if Pos('[GNUPG:] GOODSIG', Output) > 0 then
      Result := vgValid
    else if Pos('[GNUPG:] NO_PUBKEY', Output) > 0 then
      Result := vgKeyNotFound
    else if Pos('[GNUPG:] BADSIG', Output) > 0 then
      Result := vgInvalidSignature
    else if ExitCode = 0 then
      Result := vgValid
    else
      Result := vgInvalidSignature;
    for i := 1 to CountLines(Output) do
    begin
      Line := GetLine(Output, i);
      if StartsStr('[GNUPG:] VALIDSIG', Line) then
      begin
        AFingerprint := Trim(GetField(Line, 3));
        if AFingerprint = '' then
          AFingerprint := Trim(GetField(Line, 2));
      end;
      if StartsStr('[GNUPG:] GOODSIG', Line) then
        ACallsign := Trim(GetField(Line, 4));
    end;
    if Result = vgValid then
      GnuPGLog('Verified signature from ' + ACallsign + ' fp=' + AFingerprint)
    else if Result = vgKeyNotFound then
      GnuPGLog('Key not found during verify')
    else if Result = vgInvalidSignature then
      GnuPGLog('Invalid signature');
  finally
    Args.Free;
    sl.Free;
    if FileExistsUTF8(DataFile) then
      DeleteFileUTF8(DataFile);
    if FileExistsUTF8(SigFile) then
      DeleteFileUTF8(SigFile);
  end;
end;

function GnuPGLookupKey(const ACallsign: string;
  out AFingerprint: string): Boolean;
var
  Args: TStringList;
  Output: string;
  ExitCode: LongInt;
  i: Integer;
  Line: string;
  SearchCall: string;
begin
  Result := False;
  AFingerprint := '';
  SearchCall := UpperCase(Trim(ACallsign));
  if SearchCall = '' then
    Exit;
  Args := TStringList.Create;
  try
    Args.Add('--batch');
    Args.Add('--with-colons');
    Args.Add('--list-keys');
    Args.Add(SearchCall);
    if not RunGpg(Args, Output, ExitCode) then
      Exit;
    for i := 1 to CountLines(Output) do
    begin
      Line := GetLine(Output, i);
      if StartsStr('fpr:', Line) then
      begin
        AFingerprint := ExtractFingerprintFromColonLine(Line);
        if AFingerprint <> '' then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
  finally
    Args.Free;
  end;
end;

function ParseSearchKeyId(const AOutput: string): string;
var
  i: Integer;
  Line: string;
  Parts: TStringArray;
begin
  Result := '';
  for i := 1 to CountLines(AOutput) do
  begin
    Line := GetLine(AOutput, i);
    if StartsStr('pub:', Line) then
    begin
      Parts := Line.Split(':');
      if Length(Parts) >= 5 then
        Result := Parts[4];
    end;
    if (Result <> '') and StartsStr('fpr:', Line) then
      Break;
  end;
end;

function GnuPGFetchKeyFromServer(const ACallsign: string;
  const AKeyserver: string; out AFingerprint: string): Boolean;
var
  Args: TStringList;
  Output: string;
  ExitCode: LongInt;
  KeyId: string;
  Server: string;
  InThread: Boolean;
begin
  Result := False;
  AFingerprint := '';
  if Trim(ACallsign) = '' then
    Exit;
  InThread := (GetCurrentThreadId <> MainThreadID);
  Server := Trim(AKeyserver);
  if Server = '' then
    Server := 'hkps://keys.openpgp.org';
  Args := TStringList.Create;
  try
    Args.Add('--batch');
    Args.Add('--keyserver');
    Args.Add(Server);
    Args.Add('--search-keys');
    Args.Add(UpperCase(Trim(ACallsign)));
    if not RunGpg(Args, Output, ExitCode, not InThread) then
      Exit;
    KeyId := ParseSearchKeyId(Output);
    if KeyId = '' then
    begin
      GnuPGLog('Key not found on keyserver for callsign ' + ACallsign);
      Exit;
    end;
    Args.Clear;
    Args.Add('--batch');
    Args.Add('--keyserver');
    Args.Add(Server);
    Args.Add('--recv-keys');
    Args.Add(KeyId);
    if not RunGpg(Args, Output, ExitCode, not InThread) then
      Exit;
    if ExitCode <> 0 then
    begin
      GnuPGLog('recv-keys failed for ' + ACallsign + ': ' + Output);
      Exit;
    end;
    Result := GnuPGLookupKey(ACallsign, AFingerprint);
    if Result then
      GnuPGLog('Fetched key for ' + ACallsign + ' fp=' + AFingerprint);
  finally
    Args.Free;
  end;
end;

function GnuPGVerifyWithKeyLookup(const AData: string; const ASignature: string;
  const ARemoteCallsign: string; out ACallsign: string; out AFingerprint: string;
  AKeyFetchSync: TThreadMethod): TGnuPGVerifyResult;
var
  Callsign: string;
  Keyserver: string;
  CachedFp: string;
begin
  Callsign := UpperCase(Trim(ARemoteCallsign));
  Result := GnuPGVerify(AData, ASignature, ACallsign, AFingerprint);
  if Result <> vgKeyNotFound then
    Exit;
  if GnuPGKeyCacheLookup(Callsign, CachedFp) then
  begin
    if not GnuPGLookupKey(CachedFp, AFingerprint) then
      GnuPGLookupKey(Callsign, AFingerprint);
  end
  else if not GnuPGLookupKey(Callsign, AFingerprint) then
  begin
    Keyserver := cqrini.ReadString('Signing', 'Keyserver', 'hkps://keys.openpgp.org');
    if GnuPGFetchKeyFromServerInThread(Callsign, Keyserver, AFingerprint, AKeyFetchSync) then
      GnuPGKeyCacheStore(Callsign, AFingerprint, 'gpg')
    else
    begin
      GnuPGLog('Key not found for callsign ' + Callsign);
      Exit(vgKeyNotFound);
    end;
  end
  else
    GnuPGKeyCacheStore(Callsign, AFingerprint, 'gpg');
  Result := GnuPGVerify(AData, ASignature, ACallsign, AFingerprint);
end;

end.
