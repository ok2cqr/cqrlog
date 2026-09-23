(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The model of one graphical band map window (fBandMapGfx) and of the set of
  windows that reopen after a restart.

  A window is identified by its choice: Auto (follow the VFO) or one fixed
  band. There is at most one window per choice, so the choice key ('auto',
  '20M') is the window's stable ID and names its config section
  BandMapGfx.<key>. The list of windows to reopen is [BandMapGfx] Open.

  Each window owns its viewport (span, centre) and its filter. The QSO part of
  the filter is one of three rules, never two stacked: qrGlobal reads the
  shared [BandMapFilter] keys, qrCustom has its own copy here, qrNone hides
  nothing because of the log.

  The config is reached through TBandMapSettingsStore so this unit has no
  cqrini, no LCL and no database: the tests use an in-memory store, the
  application wraps cqrini. Window geometry is Local when the user keeps
  window sizes in local.cfg (cqrini.LocalOnly('WindowSize')). }

unit uBandMapLayout;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  AUTO_KEY        = 'auto';
  OPEN_SECTION    = 'BandMapGfx';
  OPEN_KEY        = 'Open';
  SECTION_PREFIX  = 'BandMapGfx.';
  LEGACY_FORM     = 'frmBandMapGfx';   //window pos section of the single old window

type
  TQsoRule = (qrGlobal, qrCustom, qrNone);

  TBandMapChoice = record
    IsAuto : Boolean;
    Band   : String;   //band code as in dmUtils.MyBands, e.g. '20M'; '' for Auto
  end;

  TBandMapInstance = record
    Choice       : TBandMapChoice;
    SpanKHz      : Integer;
    CenterKHz    : Double;    //0 = never saved
    QsoRule      : TQsoRule;
    UseLastHours : Boolean;   //custom rule: last N hours, else since date/time
    LastHours    : Integer;
    SinceDate    : String;
    SinceTime    : String;
    OnlyLoTW     : Boolean;
    OnlyEQSL     : Boolean;
    OnlyCurrMode : Boolean;
  end;

  { the slice of cqrini this unit needs }
  TBandMapSettingsStore = class
    function  ReadString(const Section, Key, Default : String; ALocal : Boolean = False) : String; virtual; abstract;
    procedure WriteString(const Section, Key, Value : String; ALocal : Boolean = False); virtual; abstract;
    function  ReadInteger(const Section, Key : String; Default : Integer; ALocal : Boolean = False) : Integer;
    function  ReadBool(const Section, Key : String; Default : Boolean; ALocal : Boolean = False) : Boolean;
    procedure WriteInteger(const Section, Key : String; Value : Integer; ALocal : Boolean = False);
    procedure WriteBool(const Section, Key : String; Value : Boolean; ALocal : Boolean = False);
  end;

function AutoChoice : TBandMapChoice;
function FixedChoice(const ABand : String) : TBandMapChoice;
function SameChoice(const A, B : TBandMapChoice) : Boolean;
function ChoiceKey(const C : TBandMapChoice) : String;
function ParseChoiceKey(const AKey : String; out C : TBandMapChoice) : Boolean;
function InstanceSection(const C : TBandMapChoice) : String;

//'20M' -> '20 m', '70CM' -> '70 cm'
function BandLabel(const ABand : String) : String;
//window caption; AShownBand is what an Auto window currently follows
function ChoiceTitle(const C : TBandMapChoice; const AShownBand : String) : String;

function SplitOpenList(const S : String) : TStringArray;
function JoinOpenList(const L : array of String) : String;
function ReadOpenList(Store : TBandMapSettingsStore) : TStringArray;
procedure WriteOpenList(Store : TBandMapSettingsStore; const L : array of String);

{ True when the choice can be used as it is. False when its band is no longer
  enabled in Preferences > Bands: Effective is then Auto, the saved choice is
  left alone for the caller to keep. }
function ResolveChoice(const C : TBandMapChoice; const EnabledBands : array of String;
                       out Effective : TBandMapChoice) : Boolean;

function  LoadInstance(Store : TBandMapSettingsStore; const C : TBandMapChoice;
                       ADefaultSpanKHz : Integer) : TBandMapInstance;
procedure SaveInstance(Store : TBandMapSettingsStore; const I : TBandMapInstance);

{ One-off carry-over of the single old window: [Window] BandMapGfx decides
  whether an Auto window reopens, [BandMapGfx] SpanKHz, the frmBandMapGfx
  geometry (AGeometryLocal = where SaveWindowPos put it) and the shared
  [BandMapFilter] become the Auto window's own settings. Runs only while
  [BandMapGfx] Open does not exist; returns True when it did something. }
function MigrateLegacyLayout(Store : TBandMapSettingsStore; AGeometryLocal : Boolean) : Boolean;

implementation

function TBandMapSettingsStore.ReadInteger(const Section, Key : String; Default : Integer; ALocal : Boolean) : Integer;
begin
  Result := StrToIntDef(Trim(ReadString(Section, Key, '', ALocal)), Default)
end;

function TBandMapSettingsStore.ReadBool(const Section, Key : String; Default : Boolean; ALocal : Boolean) : Boolean;
var
  s : String;
begin
  s := Trim(ReadString(Section, Key, '', ALocal));
  if s = '' then
    Result := Default
  else
    Result := (s = '1') or (LowerCase(s) = 'true')
end;

procedure TBandMapSettingsStore.WriteInteger(const Section, Key : String; Value : Integer; ALocal : Boolean);
begin
  WriteString(Section, Key, IntToStr(Value), ALocal)
end;

procedure TBandMapSettingsStore.WriteBool(const Section, Key : String; Value : Boolean; ALocal : Boolean);
begin
  if Value then
    WriteString(Section, Key, '1', ALocal)
  else
    WriteString(Section, Key, '0', ALocal)
end;

function AutoChoice : TBandMapChoice;
begin
  Result.IsAuto := True;
  Result.Band   := ''
end;

function FixedChoice(const ABand : String) : TBandMapChoice;
begin
  Result.IsAuto := False;
  Result.Band   := UpperCase(Trim(ABand))
end;

function SameChoice(const A, B : TBandMapChoice) : Boolean;
begin
  if A.IsAuto or B.IsAuto then
    Result := A.IsAuto and B.IsAuto
  else
    Result := A.Band = B.Band
end;

function ChoiceKey(const C : TBandMapChoice) : String;
begin
  if C.IsAuto then
    Result := AUTO_KEY
  else
    Result := C.Band
end;

function ParseChoiceKey(const AKey : String; out C : TBandMapChoice) : Boolean;
var
  s : String;
  i : Integer;
begin
  s := Trim(AKey);
  C := AutoChoice;
  if LowerCase(s) = AUTO_KEY then
    exit(True);
  //a band code: digits then M or CM, nothing else
  if (Length(s) < 2) or not (s[1] in ['0'..'9']) then
    exit(False);
  i := 1;
  while (i <= Length(s)) and (s[i] in ['0'..'9']) do
    Inc(i);
  s := UpperCase(s);
  if not ((Copy(s, i, MaxInt) = 'M') or (Copy(s, i, MaxInt) = 'CM') or (Copy(s, i, MaxInt) = 'MM')) then
    exit(False);
  C := FixedChoice(s);
  Result := True
end;

function InstanceSection(const C : TBandMapChoice) : String;
begin
  Result := SECTION_PREFIX + ChoiceKey(C)
end;

function BandLabel(const ABand : String) : String;
var
  i : Integer;
  s : String;
begin
  s := UpperCase(Trim(ABand));
  i := 1;
  while (i <= Length(s)) and (s[i] in ['0'..'9', '.']) do
    Inc(i);
  Result := Copy(s, 1, i-1) + ' ' + LowerCase(Copy(s, i, MaxInt))
end;

function ChoiceTitle(const C : TBandMapChoice; const AShownBand : String) : String;
begin
  if not C.IsAuto then
    Result := 'Band map - ' + BandLabel(C.Band)
  else if AShownBand <> '' then
    Result := 'Band map - Auto (' + BandLabel(AShownBand) + ')'
  else
    Result := 'Band map - Auto'
end;

function SplitOpenList(const S : String) : TStringArray;
var
  parts : TStringArray;
  p     : String;
begin
  Result := nil;
  parts  := S.Split(',');
  for p in parts do
    if Trim(p) <> '' then
    begin
      SetLength(Result, Length(Result)+1);
      Result[High(Result)] := Trim(p)
    end
end;

function JoinOpenList(const L : array of String) : String;
var
  i : Integer;
begin
  Result := '';
  for i := 0 to High(L) do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + L[i]
  end
end;

function ReadOpenList(Store : TBandMapSettingsStore) : TStringArray;
begin
  Result := SplitOpenList(Store.ReadString(OPEN_SECTION, OPEN_KEY, ''))
end;

procedure WriteOpenList(Store : TBandMapSettingsStore; const L : array of String);
begin
  Store.WriteString(OPEN_SECTION, OPEN_KEY, JoinOpenList(L))
end;

function ResolveChoice(const C : TBandMapChoice; const EnabledBands : array of String;
                       out Effective : TBandMapChoice) : Boolean;
var
  b : String;
begin
  Effective := C;
  if C.IsAuto then
    exit(True);
  for b in EnabledBands do
    if UpperCase(b) = C.Band then
      exit(True);
  Effective := AutoChoice;
  Result := False
end;

function LoadInstance(Store : TBandMapSettingsStore; const C : TBandMapChoice;
                      ADefaultSpanKHz : Integer) : TBandMapInstance;
var
  sec : String;
begin
  sec := InstanceSection(C);
  Result := Default(TBandMapInstance);
  Result.Choice       := C;
  Result.SpanKHz      := Store.ReadInteger(sec, 'SpanKHz', ADefaultSpanKHz);
  Result.CenterKHz    := StrToFloatDef(Store.ReadString(sec, 'CenterKHz', '0'), 0, DefaultFormatSettings);
  Result.QsoRule      := TQsoRule(Store.ReadInteger(sec, 'QsoRule', Ord(qrGlobal)) mod 3);
  Result.UseLastHours := Store.ReadBool(sec, 'UseLastHours', True);
  Result.LastHours    := Store.ReadInteger(sec, 'LastHours', 48);
  Result.SinceDate    := Store.ReadString(sec, 'SinceDate', '');
  Result.SinceTime    := Store.ReadString(sec, 'SinceTime', '');
  Result.OnlyLoTW     := Store.ReadBool(sec, 'OnlyLoTW', False);
  Result.OnlyEQSL     := Store.ReadBool(sec, 'OnlyEQSL', False);
  Result.OnlyCurrMode := Store.ReadBool(sec, 'OnlyCurrMode', False)
end;

procedure SaveInstance(Store : TBandMapSettingsStore; const I : TBandMapInstance);
var
  sec : String;
begin
  sec := InstanceSection(I.Choice);
  Store.WriteInteger(sec, 'SpanKHz', I.SpanKHz);
  Store.WriteString(sec, 'CenterKHz', FloatToStr(I.CenterKHz, DefaultFormatSettings));
  Store.WriteInteger(sec, 'QsoRule', Ord(I.QsoRule));
  Store.WriteBool(sec, 'UseLastHours', I.UseLastHours);
  Store.WriteInteger(sec, 'LastHours', I.LastHours);
  Store.WriteString(sec, 'SinceDate', I.SinceDate);
  Store.WriteString(sec, 'SinceTime', I.SinceTime);
  Store.WriteBool(sec, 'OnlyLoTW', I.OnlyLoTW);
  Store.WriteBool(sec, 'OnlyEQSL', I.OnlyEQSL);
  Store.WriteBool(sec, 'OnlyCurrMode', I.OnlyCurrMode)
end;

function MigrateLegacyLayout(Store : TBandMapSettingsStore; AGeometryLocal : Boolean) : Boolean;
const
  GEOM : array[0..4] of String = ('Top', 'Left', 'Width', 'Height', 'Max');
var
  I   : TBandMapInstance;
  k,v : String;
  sec : String;
begin
  //the marker is the key itself: once written (even empty) there is nothing
  //left to carry over
  if Store.ReadString(OPEN_SECTION, OPEN_KEY, #0) <> #0 then
    exit(False);

  if Store.ReadBool('Window', 'BandMapGfx', False) then
    WriteOpenList(Store, [AUTO_KEY])
  else
    WriteOpenList(Store, []);

  I := LoadInstance(Store, AutoChoice, Store.ReadInteger(OPEN_SECTION, 'SpanKHz', 20));
  I.OnlyLoTW  := Store.ReadBool('BandMapFilter', 'OnlyLoTW', False);
  I.OnlyEQSL  := Store.ReadBool('BandMapFilter', 'OnlyeQSL', False);
  I.LastHours := Store.ReadInteger('BandMapFilter', 'LastHours', 48);
  I.SinceDate := Store.ReadString('BandMapFilter', 'LastDate', '');
  I.SinceTime := Store.ReadString('BandMapFilter', 'LastTime', '');
  if Store.ReadBool('BandMapFilter', 'NoWkdDate', False) then
  begin
    I.QsoRule := qrCustom;
    I.UseLastHours := False
  end
  else if Store.ReadBool('BandMapFilter', 'NoWkdHour', False) then
  begin
    I.QsoRule := qrCustom;
    I.UseLastHours := True
  end
  else
    //the old window never hid worked stations unless asked, keep that
    I.QsoRule := qrNone;
  SaveInstance(Store, I);

  sec := InstanceSection(AutoChoice);
  for k in GEOM do
  begin
    v := Store.ReadString(LEGACY_FORM, k, #0, AGeometryLocal);
    if v <> #0 then
      Store.WriteString(sec, k, v, AGeometryLocal)
  end;
  Result := True
end;

end.
