(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Super Check Partial lookup.  The expected results follow what
  TdmData.GetSCPCalls returned before the search moved here: file order,
  one hit per callsign, case sensitive. }

unit tScpLookup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uScpIndex;

type
  TScpIndexTest = class(TTestCase)
  private
    Scp   : TScpIndex;
    Hits  : TStringList;
    procedure Load(const Lines : array of String);
    function Find(const Partial : String) : String;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure SkipsCommentsHeaderAndBlankLines;
    procedure TrimsLines;
    procedure MatchAnywhereInCall;
    procedure HitsInFileOrder;
    procedure OneHitPerCallEvenIfPartialRepeats;
    procedure FirstAndLastCallInFile;
    procedure WholeCallMatchesItself;
    procedure NoMatch;
    procedure EmptyPartialFindsNothing;
    procedure PartialWithLineBreakFindsNothing;
    procedure EmptyIndexFindsNothing;
    procedure CaseSensitive;
    procedure ReloadReplacesCalls;
    procedure ClearedHitsBeforeSearch;
    procedure LoadFromFile;
  end;

implementation

procedure TScpIndexTest.SetUp;
begin
  Scp  := TScpIndex.Create;
  Hits := TStringList.Create
end;

procedure TScpIndexTest.TearDown;
begin
  Hits.Free;
  Scp.Free
end;

procedure TScpIndexTest.Load(const Lines : array of String);
var
  l : TStringList;
  s : String;
begin
  l := TStringList.Create;
  try
    for s in Lines do
      l.Add(s);
    Scp.LoadFromStrings(l)
  finally
    l.Free
  end
end;

function TScpIndexTest.Find(const Partial : String) : String;
begin
  Scp.Find(Partial, Hits);
  Hits.Delimiter := ' ';
  Hits.StrictDelimiter := True;
  Result := Hits.DelimitedText
end;

procedure TScpIndexTest.SkipsCommentsHeaderAndBlankLines;
begin
  Load(['!!Order!!,Call', '#', '# by OK1RR', '', '   ', 'OK1RR', 'OK2CQR']);
  AssertEquals(2, Scp.Count);
  AssertEquals('OK1RR', Find('OK1'));
  AssertEquals('', Find('#'));
  AssertEquals('', Find('!'))
end;

procedure TScpIndexTest.TrimsLines;
begin
  Load(['  OK1RR  ', #9'OK2CQR']);
  AssertEquals('OK1RR OK2CQR', Find('OK'))
end;

procedure TScpIndexTest.MatchAnywhereInCall;
begin
  Load(['4X4DK', 'OK2CQR', 'W1CQ/P']);
  AssertEquals('OK2CQR W1CQ/P', Find('CQ'));
  AssertEquals('W1CQ/P', Find('/P'))
end;

procedure TScpIndexTest.HitsInFileOrder;
begin
  Load(['ZZ9AB', '4X4DK', 'AB1C', '4X4NJ']);
  AssertEquals('ZZ9AB AB1C', Find('AB'));
  AssertEquals('4X4DK 4X4NJ', Find('4X4'))
end;

procedure TScpIndexTest.OneHitPerCallEvenIfPartialRepeats;
begin
  Load(['4O3AAA', 'AA1AA', 'K1A']);
  AssertEquals('4O3AAA AA1AA', Find('AA'))
end;

procedure TScpIndexTest.FirstAndLastCallInFile;
begin
  Load(['2E0OBO', 'OK2CQR', 'ZL2IFB']);
  AssertEquals('2E0OBO', Find('2E0'));
  AssertEquals('ZL2IFB', Find('IFB'))
end;

procedure TScpIndexTest.WholeCallMatchesItself;
begin
  Load(['OK2CQR', 'OK2CQRA']);
  AssertEquals('OK2CQR OK2CQRA', Find('OK2CQR'))
end;

procedure TScpIndexTest.NoMatch;
begin
  Load(['OK2CQR']);
  AssertEquals('', Find('DL1'))
end;

procedure TScpIndexTest.EmptyPartialFindsNothing;
begin
  Load(['OK2CQR']);
  AssertEquals('', Find(''))
end;

procedure TScpIndexTest.PartialWithLineBreakFindsNothing;
begin
  Load(['OK1RR', 'OK2CQR']);
  AssertEquals('', Find('RR'#10'OK2'))
end;

procedure TScpIndexTest.EmptyIndexFindsNothing;
begin
  AssertEquals(0, Scp.Count);
  AssertEquals('', Find('OK'))
end;

procedure TScpIndexTest.CaseSensitive;
begin
  Load(['OK2CQR']);
  AssertEquals('', Find('ok2'))
end;

procedure TScpIndexTest.ReloadReplacesCalls;
begin
  Load(['OK1RR']);
  Load(['OK2CQR']);
  AssertEquals(1, Scp.Count);
  AssertEquals('', Find('OK1'));
  AssertEquals('OK2CQR', Find('OK2'))
end;

procedure TScpIndexTest.ClearedHitsBeforeSearch;
begin
  Load(['OK2CQR']);
  Hits.Add('stale');
  AssertEquals('', Find('DL1'))
end;

procedure TScpIndexTest.LoadFromFile;
var
  FileName : String;
  l : TStringList;
begin
  FileName := GetTempFileName;
  l := TStringList.Create;
  try
    l.Add('# comment');
    l.Add('OK1RR');
    l.Add('OK2CQR');
    l.SaveToFile(FileName);
    Scp.LoadFromFile(FileName);
    AssertEquals(2, Scp.Count);
    AssertEquals('OK2CQR', Find('CQ'))
  finally
    l.Free;
    DeleteFile(FileName)
  end
end;

initialization
  RegisterTest(TScpIndexTest)
end.
