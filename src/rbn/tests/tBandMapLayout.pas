(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The per-window model of the graphical band map: which band a window shows
  (Auto or a fixed band), its own filter and viewport, how that is written to
  the config and how the single old window is carried over. }

unit tBandMapLayout;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uBandMapLayout;

type
  { in-memory stand-in for cqrini: "section|key" -> value, local keys apart }
  TMemStore = class(TBandMapSettingsStore)
    Main, Local : TStringList;
    constructor Create;
    destructor Destroy; override;
    function  ReadString(const Section, Key, Default : String; ALocal : Boolean = False) : String; override;
    procedure WriteString(const Section, Key, Value : String; ALocal : Boolean = False); override;
  end;

  TBandMapLayoutTest = class(TTestCase)
  private
    S : TMemStore;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure AutoAndFixedKeysRoundTrip;
    procedure UnknownKeyIsRejected;
    procedure BandLabelIsLowerCaseWithSpace;
    procedure TitleNamesTheBandAndTheMode;
    procedure OpenListRoundTripSkipsBlanks;
    procedure DisabledBandFallsBackToAuto;
    procedure NewInstanceUsesGlobalQsoRuleAndDefaultSpan;
    procedure InstanceSettingsRoundTrip;
    procedure LegacyWindowFlagBecomesAnAutoInstance;
    procedure LegacyGeometryIsCopiedToTheAutoSection;
    procedure LegacyHourFilterBecomesCustomRule;
    procedure LegacyShowAllBecomesNoRule;
    procedure LegacyClosedWindowMigratesToEmptyList;
    procedure MigrationRunsOnlyOnce;
  end;

implementation

constructor TMemStore.Create;
begin
  inherited Create;
  Main  := TStringList.Create;
  Local := TStringList.Create
end;

destructor TMemStore.Destroy;
begin
  Main.Free;
  Local.Free;
  inherited
end;

function TMemStore.ReadString(const Section, Key, Default : String; ALocal : Boolean) : String;
var
  L : TStringList;
begin
  if ALocal then L := Local else L := Main;
  if L.IndexOfName(Section+'|'+Key) < 0 then
    Result := Default
  else
    Result := L.Values[Section+'|'+Key]
end;

procedure TMemStore.WriteString(const Section, Key, Value : String; ALocal : Boolean);
begin
  if ALocal then
    Local.Values[Section+'|'+Key] := Value
  else
    Main.Values[Section+'|'+Key] := Value
end;

procedure TBandMapLayoutTest.SetUp;
begin
  S := TMemStore.Create
end;

procedure TBandMapLayoutTest.TearDown;
begin
  S.Free
end;

procedure TBandMapLayoutTest.AutoAndFixedKeysRoundTrip;
var
  C : TBandMapChoice;
begin
  AssertEquals('auto', ChoiceKey(AutoChoice));
  AssertEquals('20M', ChoiceKey(FixedChoice('20M')));
  AssertTrue(ParseChoiceKey('auto', C));
  AssertTrue(C.IsAuto);
  AssertTrue(ParseChoiceKey('40M', C));
  AssertFalse(C.IsAuto);
  AssertEquals('40M', C.Band);
  AssertTrue(SameChoice(FixedChoice('40M'), C));
  AssertFalse(SameChoice(AutoChoice, C))
end;

procedure TBandMapLayoutTest.UnknownKeyIsRejected;
var
  C : TBandMapChoice;
begin
  AssertFalse(ParseChoiceKey('', C));
  AssertFalse(ParseChoiceKey('bogus', C));
  AssertFalse(ParseChoiceKey('20 m', C))
end;

procedure TBandMapLayoutTest.BandLabelIsLowerCaseWithSpace;
begin
  AssertEquals('20 m', BandLabel('20M'));
  AssertEquals('70 cm', BandLabel('70CM'));
  AssertEquals('2190 m', BandLabel('2190M'));
  AssertEquals('23 cm', BandLabel('23CM'))
end;

procedure TBandMapLayoutTest.TitleNamesTheBandAndTheMode;
begin
  AssertEquals('Band map - 20 m', ChoiceTitle(FixedChoice('20M'), ''));
  AssertEquals('Band map - 20 m', ChoiceTitle(FixedChoice('20M'), '40M'));
  AssertEquals('Band map - Auto (40 m)', ChoiceTitle(AutoChoice, '40M'));
  AssertEquals('Band map - Auto', ChoiceTitle(AutoChoice, ''))
end;

procedure TBandMapLayoutTest.OpenListRoundTripSkipsBlanks;
var
  L : TStringArray;
begin
  L := SplitOpenList(' auto, 20M,,40M ');
  AssertEquals(3, Length(L));
  AssertEquals('auto', L[0]);
  AssertEquals('20M', L[1]);
  AssertEquals('40M', L[2]);
  AssertEquals('auto,20M,40M', JoinOpenList(L));
  AssertEquals(0, Length(SplitOpenList('')))
end;

procedure TBandMapLayoutTest.DisabledBandFallsBackToAuto;
var
  E : TBandMapChoice;
begin
  AssertTrue(ResolveChoice(FixedChoice('20M'), ['160M','20M'], E));
  AssertEquals('20M', E.Band);
  AssertFalse(ResolveChoice(FixedChoice('60M'), ['160M','20M'], E));
  AssertTrue(E.IsAuto);
  AssertTrue(ResolveChoice(AutoChoice, [], E));
  AssertTrue(E.IsAuto)
end;

procedure TBandMapLayoutTest.NewInstanceUsesGlobalQsoRuleAndDefaultSpan;
var
  I : TBandMapInstance;
begin
  I := LoadInstance(S, FixedChoice('20M'), 20);
  AssertEquals('20M', I.Choice.Band);
  AssertTrue(I.QsoRule = qrGlobal);
  AssertEquals(20, I.SpanKHz);
  AssertEquals(0.0, I.CenterKHz, 0.001);
  AssertFalse(I.OnlyLoTW);
  AssertFalse(I.OnlyEQSL);
  AssertFalse(I.OnlyCurrMode);
  AssertEquals(48, I.LastHours)
end;

procedure TBandMapLayoutTest.InstanceSettingsRoundTrip;
var
  I, J : TBandMapInstance;
begin
  I := LoadInstance(S, FixedChoice('40M'), 20);
  I.SpanKHz      := 50;
  I.CenterKHz    := 7030.5;
  I.QsoRule      := qrCustom;
  I.UseLastHours := False;
  I.LastHours    := 12;
  I.SinceDate    := '2026-09-01';
  I.SinceTime    := '10:00';
  I.OnlyLoTW     := True;
  I.OnlyEQSL     := False;
  I.OnlyCurrMode := True;
  SaveInstance(S, I);
  J := LoadInstance(S, FixedChoice('40M'), 20);
  AssertEquals(50, J.SpanKHz);
  AssertEquals(7030.5, J.CenterKHz, 0.001);
  AssertTrue(J.QsoRule = qrCustom);
  AssertFalse(J.UseLastHours);
  AssertEquals(12, J.LastHours);
  AssertEquals('2026-09-01', J.SinceDate);
  AssertEquals('10:00', J.SinceTime);
  AssertTrue(J.OnlyLoTW);
  AssertFalse(J.OnlyEQSL);
  AssertTrue(J.OnlyCurrMode);
  //the section name is the contract with the config storage list
  AssertEquals('50', S.ReadString('BandMapGfx.40M', 'SpanKHz', ''))
end;

procedure TBandMapLayoutTest.LegacyWindowFlagBecomesAnAutoInstance;
var
  L : TStringArray;
  I : TBandMapInstance;
begin
  S.WriteString('Window', 'BandMapGfx', '1');
  S.WriteString('BandMapGfx', 'SpanKHz', '40');
  AssertTrue(MigrateLegacyLayout(S, False));
  L := ReadOpenList(S);
  AssertEquals(1, Length(L));
  AssertEquals('auto', L[0]);
  I := LoadInstance(S, AutoChoice, 20);
  AssertEquals(40, I.SpanKHz)
end;

procedure TBandMapLayoutTest.LegacyGeometryIsCopiedToTheAutoSection;
begin
  S.WriteString('Window', 'BandMapGfx', '1');
  S.WriteString('frmBandMapGfx', 'Top', '11', True);
  S.WriteString('frmBandMapGfx', 'Left', '22', True);
  S.WriteString('frmBandMapGfx', 'Width', '333', True);
  S.WriteString('frmBandMapGfx', 'Height', '444', True);
  S.WriteString('frmBandMapGfx', 'Max', '0', True);
  MigrateLegacyLayout(S, True);
  AssertEquals('11', S.ReadString('BandMapGfx.auto', 'Top', '', True));
  AssertEquals('22', S.ReadString('BandMapGfx.auto', 'Left', '', True));
  AssertEquals('333', S.ReadString('BandMapGfx.auto', 'Width', '', True));
  AssertEquals('444', S.ReadString('BandMapGfx.auto', 'Height', '', True));
  AssertEquals('0', S.ReadString('BandMapGfx.auto', 'Max', '', True));
  //nothing lands in the other file
  AssertEquals('', S.ReadString('BandMapGfx.auto', 'Top', '', False))
end;

procedure TBandMapLayoutTest.LegacyHourFilterBecomesCustomRule;
var
  I : TBandMapInstance;
begin
  S.WriteString('Window', 'BandMapGfx', '1');
  S.WriteString('BandMapFilter', 'NoWkdHour', '1');
  S.WriteString('BandMapFilter', 'LastHours', '6');
  S.WriteString('BandMapFilter', 'OnlyLoTW', '1');
  MigrateLegacyLayout(S, False);
  I := LoadInstance(S, AutoChoice, 20);
  AssertTrue(I.QsoRule = qrCustom);
  AssertTrue(I.UseLastHours);
  AssertEquals(6, I.LastHours);
  AssertTrue(I.OnlyLoTW)
end;

procedure TBandMapLayoutTest.LegacyShowAllBecomesNoRule;
var
  I : TBandMapInstance;
begin
  S.WriteString('Window', 'BandMapGfx', '1');
  S.WriteString('BandMapFilter', 'ShowAll', '1');
  MigrateLegacyLayout(S, False);
  I := LoadInstance(S, AutoChoice, 20);
  AssertTrue(I.QsoRule = qrNone)
end;

procedure TBandMapLayoutTest.LegacyClosedWindowMigratesToEmptyList;
begin
  S.WriteString('Window', 'BandMapGfx', '0');
  AssertTrue(MigrateLegacyLayout(S, False));
  AssertEquals(0, Length(ReadOpenList(S)));
  //a later restart must not re-run it and reopen a window the user closed
  AssertFalse(MigrateLegacyLayout(S, False))
end;

procedure TBandMapLayoutTest.MigrationRunsOnlyOnce;
begin
  S.WriteString('Window', 'BandMapGfx', '1');
  AssertTrue(MigrateLegacyLayout(S, False));
  WriteOpenList(S, ['20M']);
  AssertFalse(MigrateLegacyLayout(S, False));
  AssertEquals('20M', JoinOpenList(ReadOpenList(S)))
end;

initialization
  RegisterTest(TBandMapLayoutTest);

end.
