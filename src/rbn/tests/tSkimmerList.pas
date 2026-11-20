(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Skimmer locators from the HamQTH list.  The fixture is a real answer of
  GET /api/v2/rbn/skimmers (2026-11-20) trimmed to ten nodes; the spotters
  below are as RBN telnet sends them (tools/rbn-capture). }

unit tSkimmerList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uSkimmerLocations, uRbnFixture;

type
  TSkimmerLocationsTest = class(TTestCase)
  private
    L : TSkimmerLocations;
    function GridOf(const Spotter : String) : String;
    function Row(const Node, Grid : String) : String;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure FixtureLoads;
    procedure TelnetSpotterMatchesItsNode;
    procedure NumberedNodesStandApart;
    procedure SlashNodeIsAWholeNode;
    procedure LetterSuffixIsANode;
    procedure HomeCallsignIsNeverUsed;
    procedure UnknownNodeIsNotFound;
    procedure InvalidRowsAreLeftOut;
    procedure BadAnswerKeepsTheOldList;
    procedure LoadFromFile;
    procedure SkimmerNodeCutsTheSuffix;
    procedure GridValidation;
    procedure StaleFile;
  end;

implementation

procedure TSkimmerLocationsTest.SetUp;
begin
  L := TSkimmerLocations.Create;
  AssertTrue('fixture', L.LoadFromFile(FixturePath('hamqth-skimmers.json')))
end;

procedure TSkimmerLocationsTest.TearDown;
begin
  L.Free
end;

function TSkimmerLocationsTest.GridOf(const Spotter : String) : String;
begin
  if not L.Lookup(Spotter, Result) then
    Result := '-'
end;

function TSkimmerLocationsTest.Row(const Node, Grid : String) : String;
begin
  Result := '{"node":"' + Node + '","call":"X","grid":"' + Grid + '","lastSeen":"2026-11-20T04:30:12Z"}'
end;

procedure TSkimmerLocationsTest.FixtureLoads;
begin
  AssertEquals(10, L.Count);
  AssertEquals('2026-11-20T17:43:25Z', L.Updated)
end;

procedure TSkimmerLocationsTest.TelnetSpotterMatchesItsNode;
begin
  AssertEquals('FN42ET', GridOf('KM3T-5-#'));
  AssertEquals('the node itself', 'FN42ET', GridOf('KM3T-5'));
  AssertEquals('lower case', 'JN48FX', GridOf('dk9ip-#'));
  AssertEquals('spaces', 'JN48FX', GridOf(' DK9IP-# '));
  AssertEquals('US skimmer by locator, not by call area', 'FM17DT', GridOf('WB6BEE-#'))
end;

procedure TSkimmerLocationsTest.NumberedNodesStandApart;
begin
  AssertEquals('EM12UB', GridOf('WX7V-1-#'));
  AssertEquals('EM12OU', GridOf('WX7V-5-#'))
end;

procedure TSkimmerLocationsTest.SlashNodeIsAWholeNode;
begin
  AssertEquals('EM12UB', GridOf('WX7V/5-#'));
  AssertEquals('Canaries', 'IL38BP', GridOf('EA8/DF4UE-#'))
end;

procedure TSkimmerLocationsTest.LetterSuffixIsANode;
begin
  AssertEquals('Germany', 'JN48RR', GridOf('DF4UE-RP-#'));
  AssertEquals('KN05NR', GridOf('YO5LD-U-#'))
end;

procedure TSkimmerLocationsTest.HomeCallsignIsNeverUsed;
begin
  AssertEquals('DF4UE is not EA8/DF4UE nor DF4UE-RP', '-', GridOf('DF4UE-#'));
  AssertEquals('KM3T-2 is not KM3T', '-', GridOf('KM3T-2-#'));
  AssertEquals('WX7V is not WX7V-1', '-', GridOf('WX7V-#'))
end;

procedure TSkimmerLocationsTest.UnknownNodeIsNotFound;
var
  Grid : String;
begin
  Grid := 'x';
  AssertFalse(L.Lookup('DE1LON-#', Grid));
  AssertEquals('', Grid);
  AssertFalse(L.Lookup('', Grid));
  AssertFalse(L.Lookup('-#', Grid))
end;

procedure TSkimmerLocationsTest.InvalidRowsAreLeftOut;
begin
  AssertTrue(L.LoadFromJson('{"updated":"u","skimmers":[' +
    Row('OK1AA', 'jo70gg') + ',' +       //lower case grid
    Row('OK1BB', 'JO70') + ',' +         //4 characters
    Row('OK1CC', 'VJ91LL') + ',' +       //not a locator
    Row('OK1DD', 'JO70G') + ',' +        //5 characters
    Row('', 'JO70GG') + ',' +            //no node
    Row('OK1 EE', 'JO70GG') + ',' +      //not a callsign
    Row('OK1AA', 'JN89AA') + ',' +       //twice: the first
    '{"grid":"JO70GG"},' +               //no node at all
    '"OK1FF",' +                         //not an object
    Row('OK1GG', 'JO70GG') + ']}'));
  AssertEquals(3, L.Count);
  AssertEquals('JO70GG', GridOf('OK1AA'));
  AssertEquals('JO70', GridOf('OK1BB'));
  AssertEquals('JO70GG', GridOf('OK1GG'));
  AssertEquals('-', GridOf('OK1CC'));
  AssertEquals('-', GridOf('OK1DD'));
  AssertEquals('the old list is gone', '-', GridOf('KM3T-5'))
end;

procedure TSkimmerLocationsTest.BadAnswerKeepsTheOldList;
begin
  AssertFalse('HTML', L.LoadFromJson('<html>maintenance</html>'));
  AssertFalse('cut', L.LoadFromJson('{"updated":"x","skimmers":[{"node":"OK1AA"'));
  AssertFalse('empty', L.LoadFromJson(''));
  AssertFalse('no skimmers', L.LoadFromJson('{"updated":"x"}'));
  AssertFalse('empty list', L.LoadFromJson('{"updated":"x","skimmers":[]}'));
  AssertFalse('nothing usable', L.LoadFromJson('{"skimmers":[' + Row('OK1CC', 'VJ91LL') + ']}'));
  AssertFalse('skimmers not a list', L.LoadFromJson('{"skimmers":"OK1AA"}'));
  AssertFalse('array', L.LoadFromJson('[1,2]'));
  AssertFalse('problem response', L.LoadFromJson('{"type":"about:blank","title":"Service Unavailable","status":503}'));
  AssertEquals(10, L.Count);
  AssertEquals('2026-11-20T17:43:25Z', L.Updated);
  AssertEquals('FN42ET', GridOf('KM3T-5-#'))
end;

procedure TSkimmerLocationsTest.LoadFromFile;
begin
  AssertFalse(L.LoadFromFile(FixturePath('no-such-file.json')));
  AssertEquals('a missing file keeps the list', 10, L.Count);
  L.Clear;
  AssertEquals(0, L.Count);
  AssertEquals('', L.Updated)
end;

procedure TSkimmerLocationsTest.SkimmerNodeCutsTheSuffix;
begin
  AssertEquals('KM3T-5', SkimmerNode('KM3T-5-#'));
  AssertEquals('KM3T-5', SkimmerNode('KM3T-5'));
  AssertEquals('EA8/DF4UE', SkimmerNode('ea8/df4ue-#'));
  AssertEquals('DF4UE-RP', SkimmerNode('DF4UE-RP-#'));
  AssertEquals('', SkimmerNode('-#'));
  AssertEquals('', SkimmerNode(''))
end;

procedure TSkimmerLocationsTest.GridValidation;
begin
  AssertTrue(IsSkimmerGrid('JO70GG'));
  AssertTrue(IsSkimmerGrid('jo70gg'));
  AssertTrue(IsSkimmerGrid('JO70'));
  AssertTrue(IsSkimmerGrid('RR99XX'));
  AssertFalse(IsSkimmerGrid('SA00AA'));
  AssertFalse(IsSkimmerGrid('JO70GY'));
  AssertFalse(IsSkimmerGrid('JO7'));
  AssertFalse(IsSkimmerGrid('JO70G'));
  AssertFalse(IsSkimmerGrid('JO70GG00'));
  AssertFalse(IsSkimmerGrid(''))
end;

procedure TSkimmerLocationsTest.StaleFile;
var
  FileName : String;
  s        : TStringList;
begin
  AssertTrue('missing', SkimmerListIsStale(FixturePath('no-such-file.json'), 1));
  FileName := GetTempFileName;
  s := TStringList.Create;
  try
    s.Text := '{}';
    s.SaveToFile(FileName)
  finally
    s.Free
  end;
  try
    AssertFalse('just written', SkimmerListIsStale(FileName, 1));
    FileSetDate(FileName, DateTimeToFileDate(Now - 2));
    AssertTrue('two days old', SkimmerListIsStale(FileName, 1))
  finally
    DeleteFile(FileName)
  end
end;

initialization
  RegisterTest(TSkimmerLocationsTest);

end.
