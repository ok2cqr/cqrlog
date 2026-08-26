(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The two auxiliary lists the callsign splitter consults.  Neither ever
  reaches the table parser.

    exceptions.tab   suffixes that carry no country information and should be
                     thrown away.  DL1ABC/LH is still Germany, not Norway --
                     'LH' here means lighthouse, not the LH prefix.

    ambiguous.tab    prefixes that cannot be resolved from the prefix alone,
                     so the caller has to ask the operator.

  Both are plain one-token-per-line files.  The legacy loaders
  (dDXCC.pas:1014-1048) read them with ReadLn and store the lines verbatim,
  without trimming, so that is what happens here too. }

unit uDxccSuffixRules;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TDxccSuffixRules = class
  private
    FExceptions: TStringList;
    FAmbiguous: TStringList;
    procedure LoadInto(List: TStringList; const FileName: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadExceptions(const FileName: string);
    procedure LoadAmbiguous(const FileName: string);

    { Should this suffix be discarded rather than treated as a location?

      Three rules, all from dDXCC.IsException (dDXCC.pas:323):
        - it is listed in exceptions.tab, or
        - it is one of the hard-coded power markers QRP, QRPP, P, or
        - it is longer than three characters and contains no digit, which is
          how free-text suffixes like /LIGHTHOUSE are caught. }
    function IsIgnoredSuffix(const Suffix: string): Boolean;

    { Is this prefix listed as unresolvable on its own? }
    function IsAmbiguousPrefix(const Prefix: string): Boolean;

    property Exceptions: TStringList read FExceptions;
    property Ambiguous: TStringList read FAmbiguous;
  end;

implementation

constructor TDxccSuffixRules.Create;
begin
  inherited Create;
  FExceptions := TStringList.Create;
  FAmbiguous  := TStringList.Create;
end;

destructor TDxccSuffixRules.Destroy;
begin
  FExceptions.Free;
  FAmbiguous.Free;
  inherited Destroy;
end;

procedure TDxccSuffixRules.LoadInto(List: TStringList; const FileName: string);
begin
  List.Clear;
  if FileExists(FileName) then
    List.LoadFromFile(FileName);
end;

procedure TDxccSuffixRules.LoadExceptions(const FileName: string);
begin
  LoadInto(FExceptions, FileName);
end;

procedure TDxccSuffixRules.LoadAmbiguous(const FileName: string);
begin
  LoadInto(FAmbiguous, FileName);
end;

{ True when the string holds no digit at all. }
function HasNoDigit(const S: string): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 1 to Length(S) do
    if S[I] in ['0'..'9'] then
      Exit(False);
end;

function TDxccSuffixRules.IsIgnoredSuffix(const Suffix: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to FExceptions.Count - 1 do
    if FExceptions[I] = Suffix then
      Exit(True);

  if (Suffix = 'QRP') or (Suffix = 'QRPP') or (Suffix = 'P') then
    Exit(True);

  Result := HasNoDigit(Suffix) and (Length(Suffix) > 3);
end;

function TDxccSuffixRules.IsAmbiguousPrefix(const Prefix: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to FAmbiguous.Count - 1 do
    if FAmbiguous[I] = Prefix then
      Exit(True);
  Result := False;
end;

end.
