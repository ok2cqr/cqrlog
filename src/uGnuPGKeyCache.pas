unit uGnuPGKeyCache;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLDB;

procedure GnuPGKeyCacheInit(AConnection: TSQLConnection);

function GnuPGKeyCacheLookup(const ACallsign: string;
  out AFingerprint: string): Boolean;

procedure GnuPGKeyCacheStore(const ACallsign: string;
  const AFingerprint: string; const AAlgorithm: string);

procedure GnuPGKeyCacheInvalidate(const ACallsign: string);

implementation

uses
  dData, dUtils;

var
  FConnection: TSQLConnection;

procedure GnuPGKeyCacheInit(AConnection: TSQLConnection);
var
  Q: TSQLQuery;
  Tr: TSQLTransaction;
begin
  FConnection := AConnection;
  if FConnection = nil then
    Exit;
  Q := TSQLQuery.Create(nil);
  Tr := TSQLTransaction.Create(nil);
  try
    Q.DataBase := FConnection;
    Tr.DataBase := FConnection;
    Q.Transaction := Tr;
    Tr.StartTransaction;
    Q.SQL.Text :=
      'CREATE TABLE IF NOT EXISTS cqrlog_common.gnupg_key_cache (' +
      'callsign VARCHAR(20) NOT NULL, ' +
      'fingerprint VARCHAR(64) NOT NULL, ' +
      'algorithm VARCHAR(20) NULL, ' +
      'fetched_at DATETIME NULL, ' +
      'PRIMARY KEY (callsign)' +
      ') COLLATE utf8_bin';
    if dmData.DebugLevel >= 1 then
      Writeln(Q.SQL.Text);
    Q.ExecSQL;
    Tr.Commit;
  finally
    Tr.Free;
    Q.Free;
  end;
end;

function GnuPGKeyCacheLookup(const ACallsign: string;
  out AFingerprint: string): Boolean;
var
  Q: TSQLQuery;
  Tr: TSQLTransaction;
begin
  Result := False;
  AFingerprint := '';
  if (FConnection = nil) or (Trim(ACallsign) = '') then
    Exit;
  Q := TSQLQuery.Create(nil);
  Tr := TSQLTransaction.Create(nil);
  try
    Q.DataBase := FConnection;
    Tr.DataBase := FConnection;
    Q.Transaction := Tr;
    Tr.StartTransaction;
    Q.SQL.Text :=
      'SELECT fingerprint FROM cqrlog_common.gnupg_key_cache WHERE callsign = :call';
    Q.ParamByName('call').AsString := UpperCase(Trim(ACallsign));
    Q.Open;
    if not Q.Eof then
    begin
      AFingerprint := Q.Fields[0].AsString;
      Result := AFingerprint <> '';
    end;
    Q.Close;
    Tr.Commit;
  finally
    Tr.Free;
    Q.Free;
  end;
end;

procedure GnuPGKeyCacheStore(const ACallsign: string;
  const AFingerprint: string; const AAlgorithm: string);
var
  Q: TSQLQuery;
  Tr: TSQLTransaction;
begin
  if (FConnection = nil) or (Trim(ACallsign) = '') or (Trim(AFingerprint) = '') then
    Exit;
  Q := TSQLQuery.Create(nil);
  Tr := TSQLTransaction.Create(nil);
  try
    Q.DataBase := FConnection;
    Tr.DataBase := FConnection;
    Q.Transaction := Tr;
    Tr.StartTransaction;
    Q.SQL.Text :=
      'REPLACE INTO cqrlog_common.gnupg_key_cache ' +
      '(callsign, fingerprint, algorithm, fetched_at) ' +
      'VALUES (:call, :fp, :alg, :fetched)';
    Q.ParamByName('call').AsString := UpperCase(Trim(ACallsign));
    Q.ParamByName('fp').AsString := AFingerprint;
    Q.ParamByName('alg').AsString := AAlgorithm;
    Q.ParamByName('fetched').AsDateTime := Now;
    Q.ExecSQL;
    Tr.Commit;
  finally
    Tr.Free;
    Q.Free;
  end;
end;

procedure GnuPGKeyCacheInvalidate(const ACallsign: string);
var
  Q: TSQLQuery;
  Tr: TSQLTransaction;
begin
  if (FConnection = nil) or (Trim(ACallsign) = '') then
    Exit;
  Q := TSQLQuery.Create(nil);
  Tr := TSQLTransaction.Create(nil);
  try
    Q.DataBase := FConnection;
    Tr.DataBase := FConnection;
    Q.Transaction := Tr;
    Tr.StartTransaction;
    Q.SQL.Text :=
      'DELETE FROM cqrlog_common.gnupg_key_cache WHERE callsign = :call';
    Q.ParamByName('call').AsString := UpperCase(Trim(ACallsign));
    Q.ExecSQL;
    Tr.Commit;
  finally
    Tr.Free;
    Q.Free;
  end;
end;

end.
