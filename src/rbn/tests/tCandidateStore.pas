(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The shared store of spot candidates: every spot from RBN, the DX cluster and
  the operator, kept for a while, filtered only when a window looks at it.
  The band maps used to filter on the way in and only while their window was
  open, so a changed filter or a newly opened window never saw what had already
  arrived. }

unit tCandidateStore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uSpotStore;

type
  TSpotStoreTest = class(TTestCase)
  private
    Store : TSpotStore;
    function MakeSpot(const Call, Band : String; Freq : Double; Origin : TSpotOrigin = soRbn;
                  const Spotter : String = 'OK1RBN'; const Mode : String = 'CW') : TSpotCandidate;
    function NeverWorked(const Call, Band, Mode : String) : Boolean;
    function WorkedOk1aa(const Call, Band, Mode : String) : Boolean;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure AddedSpotIsSelectedOnItsBand;
    procedure OtherBandIsNotSelected;
    procedure SelectAllBandsWithEmptyBand;
    procedure SameKeyUpdatesLastSeenNotCount;
    procedure DifferentSpottersAreSeparateCandidates;
    procedure SelectionIsSortedByFrequency;
    procedure ExpiredSpotIsGone;
    procedure RestoredSpotKeepsItsTimeAndExpiresOnIt;
    procedure QsoRuleHidesWorkedStation;
    procedure QsoRuleOffShowsIt;
    procedure ModeFilterInSelect;
    procedure LotwOnlyInSelect;
    procedure RemoveByCallBandMode;
    procedure RbnOfOtherSourceIsDropped;
    procedure StoreIsBoundedAndKeepsRoomForCluster;
    procedure SnapshotRoundTrip;
    procedure SnapshotSkipsGarbageLines;
    procedure OneStationOncePerBandAtItsLatestFrequency;
    procedure SimilarCallOnSameFrequencyIsHidden;
    procedure SimilarCallFurtherAwayIsAnotherStation;
    procedure DifferentCallsOnSameFrequencyBothStay;
    procedure MostOftenSpottedVariantWins;
    procedure PortableSuffixDoesNotCountAsDifference;
    procedure HitsCountArrivalsAndSurviveSnapshot;
  end;

implementation

function TSpotStoreTest.MakeSpot(const Call, Band : String; Freq : Double; Origin : TSpotOrigin;
                             const Spotter, Mode : String) : TSpotCandidate;
begin
  Result := Default(TSpotCandidate);
  Result.Origin   := Origin;
  Result.SourceId := 1;
  Result.Spotter  := Spotter;
  Result.Call     := Call;
  Result.Band     := Band;
  Result.Mode     := Mode;
  Result.FreqKHz  := Freq;
  Result.LastSeen := Now
end;

function TSpotStoreTest.NeverWorked(const Call, Band, Mode : String) : Boolean;
begin
  Result := False
end;

function TSpotStoreTest.WorkedOk1aa(const Call, Band, Mode : String) : Boolean;
begin
  Result := Call = 'OK1AA'
end;

procedure TSpotStoreTest.SetUp;
begin
  Store := TSpotStore.Create(100);
  Store.DeleteAfterSec := 720
end;

procedure TSpotStoreTest.TearDown;
begin
  FreeAndNil(Store)
end;

procedure TSpotStoreTest.AddedSpotIsSelectedOnItsBand;
var
  V : TSpotView;
begin
  Store.Add(MakeSpot('OK1AA', '20M', 14020));
  V := Store.Select('20M', Now, DefaultSpotFilter, @NeverWorked);
  AssertEquals(1, Length(V));
  AssertEquals('OK1AA', V[0].Call)
end;

procedure TSpotStoreTest.OtherBandIsNotSelected;
begin
  Store.Add(MakeSpot('OK1AA', '20M', 14020));
  AssertEquals(0, Length(Store.Select('40M', Now, DefaultSpotFilter, @NeverWorked)))
end;

procedure TSpotStoreTest.SelectAllBandsWithEmptyBand;
begin
  Store.Add(MakeSpot('OK1AA', '20M', 14020));
  Store.Add(MakeSpot('OK2BB', '40M', 7020));
  AssertEquals(2, Length(Store.Select('', Now, DefaultSpotFilter, @NeverWorked)))
end;

procedure TSpotStoreTest.SameKeyUpdatesLastSeenNotCount;
var
  A : TSpotCandidate;
  V : TSpotView;
begin
  A := MakeSpot('OK1AA', '20M', 14020);
  A.LastSeen := Now - 1/1440;
  Store.Add(A);
  A.LastSeen := Now;
  A.FreqKHz  := 14021;
  Store.Add(A);
  V := Store.Select('20M', Now, DefaultSpotFilter, @NeverWorked);
  AssertEquals(1, Length(V));
  AssertEquals(14021.0, V[0].FreqKHz, 0.001);
  AssertTrue('LastSeen must follow the live arrival', V[0].LastSeen > Now - 0.5/1440)
end;

procedure TSpotStoreTest.DifferentSpottersAreSeparateCandidates;
begin
  //they can be on different continents; the source filter needs them apart
  Store.Add(MakeSpot('OK1AA', '20M', 14020, soRbn, 'DL1RBN'));
  Store.Add(MakeSpot('OK1AA', '20M', 14020, soRbn, 'W3RBN'));
  AssertEquals(2, Store.Count)
end;

procedure TSpotStoreTest.SelectionIsSortedByFrequency;
var
  V : TSpotView;
begin
  Store.Add(MakeSpot('OK3CC', '20M', 14030));
  Store.Add(MakeSpot('OK1AA', '20M', 14010));
  Store.Add(MakeSpot('OK2BB', '20M', 14020));
  V := Store.Select('20M', Now, DefaultSpotFilter, @NeverWorked);
  AssertEquals('OK1AA', V[0].Call);
  AssertEquals('OK2BB', V[1].Call);
  AssertEquals('OK3CC', V[2].Call)
end;

procedure TSpotStoreTest.ExpiredSpotIsGone;
var
  A : TSpotCandidate;
begin
  A := MakeSpot('OK1AA', '20M', 14020);
  A.LastSeen := Now - 13/1440;
  Store.Add(A);
  AssertEquals(0, Length(Store.Select('20M', Now, DefaultSpotFilter, @NeverWorked)));
  Store.Expire(Now);
  AssertEquals(0, Store.Count)
end;

procedure TSpotStoreTest.RestoredSpotKeepsItsTimeAndExpiresOnIt;
var
  A : TSpotCandidate;
  V : TSpotView;
begin
  //after a restart the spot must not get a new lease of life
  A := MakeSpot('OK1AA', '20M', 14020);
  A.LastSeen := Now - 10/1440;
  Store.Add(A);
  V := Store.Select('20M', Now, DefaultSpotFilter, @NeverWorked);
  AssertEquals(1, Length(V));
  AssertTrue(Abs((Now - V[0].LastSeen) * 1440 - 10) < 0.1);
  AssertEquals(0, Length(Store.Select('20M', Now + 3/1440, DefaultSpotFilter, @NeverWorked)))
end;

procedure TSpotStoreTest.QsoRuleHidesWorkedStation;
var
  V : TSpotView;
begin
  Store.Add(MakeSpot('OK1AA', '20M', 14020));
  Store.Add(MakeSpot('OK2BB', '20M', 14025, soCluster));
  V := Store.Select('20M', Now, DefaultSpotFilter, @WorkedOk1aa);
  AssertEquals(1, Length(V));
  AssertEquals('OK2BB', V[0].Call)
end;

procedure TSpotStoreTest.QsoRuleOffShowsIt;
begin
  Store.Add(MakeSpot('OK1AA', '20M', 14020));
  AssertEquals(1, Length(Store.Select('20M', Now, DefaultSpotFilter, nil)))
end;

procedure TSpotStoreTest.ModeFilterInSelect;
var
  F : TSpotFilter;
begin
  Store.Add(MakeSpot('OK1AA', '20M', 14020, soRbn, 'OK1RBN', 'CW'));
  Store.Add(MakeSpot('OK2BB', '20M', 14200, soCluster, 'OK1RBN', 'SSB'));
  F := DefaultSpotFilter;
  F.Mode := 'SSB';
  AssertEquals(1, Length(Store.Select('20M', Now, F, @NeverWorked)))
end;

procedure TSpotStoreTest.LotwOnlyInSelect;
var
  A : TSpotCandidate;
  F : TSpotFilter;
begin
  A := MakeSpot('OK1AA', '20M', 14020); A.IsLoTW := True; Store.Add(A);
  Store.Add(MakeSpot('OK2BB', '20M', 14025));
  F := DefaultSpotFilter;
  F.OnlyLoTW := True;
  AssertEquals(1, Length(Store.Select('20M', Now, F, @NeverWorked)))
end;

procedure TSpotStoreTest.RemoveByCallBandMode;
begin
  Store.Add(MakeSpot('OK1AA', '20M', 14020, soRbn, 'DL1RBN'));
  Store.Add(MakeSpot('OK1AA', '20M', 14020, soRbn, 'W3RBN'));
  Store.Add(MakeSpot('OK1AA', '40M', 7020));
  Store.Remove('OK1AA', '20M', 'CW');   //DeleteAfterQSO, whoever spotted it
  AssertEquals(0, Length(Store.Select('20M', Now, DefaultSpotFilter, @NeverWorked)));
  AssertEquals(1, Length(Store.Select('40M', Now, DefaultSpotFilter, @NeverWorked)))
end;

procedure TSpotStoreTest.RbnOfOtherSourceIsDropped;
var
  A : TSpotCandidate;
begin
  A := MakeSpot('OK1AA', '20M', 14020); A.SourceId := 1; Store.Add(A);
  A := MakeSpot('OK2BB', '20M', 14025); A.SourceId := 2; Store.Add(A);
  Store.Add(MakeSpot('OK3CC', '20M', 14030, soCluster));
  Store.DropRbnSource(1);   //the main source was switched away from preset 1
  AssertEquals(2, Length(Store.Select('20M', Now, DefaultSpotFilter, @NeverWorked)))
end;

procedure TSpotStoreTest.StoreIsBoundedAndKeepsRoomForCluster;
var
  i : Integer;
begin
  //an RBN flood must not push a still valid SSB cluster spot out
  Store.Add(MakeSpot('OK9SSB', '20M', 14200, soCluster));
  for i := 1 to 500 do
    Store.Add(MakeSpot('R' + IntToStr(i), '20M', 14000 + i / 10));
  AssertTrue('count=' + IntToStr(Store.Count), Store.Count <= 100);
  AssertEquals(1, Length(Store.Select('20M', Now, SpotFilterOrigin(soCluster), @NeverWorked)))
end;

procedure TSpotStoreTest.SnapshotRoundTrip;
var
  A    : TSpotCandidate;
  L    : TStringList;
  T    : TSpotStore;
  V    : TSpotView;
begin
  A := MakeSpot('OK1AA', '20M', 14020.5); A.LastSeen := Now - 5/1440; A.IsLoTW := True; Store.Add(A);
  Store.Add(MakeSpot('OK2BB', '40M', 7020, soCluster, 'OK1XYZ', 'SSB'));
  L := TStringList.Create;
  T := TSpotStore.Create(100);
  try
    Store.SaveSnapshot(L);
    T.DeleteAfterSec := 720;
    T.LoadSnapshot(L, Now);
    AssertEquals(2, T.Count);
    V := T.Select('20M', Now, DefaultSpotFilter, @NeverWorked);
    AssertEquals(1, Length(V));
    AssertEquals(14020.5, V[0].FreqKHz, 0.001);
    AssertTrue(V[0].IsLoTW);
    AssertTrue('age kept', Abs((Now - V[0].LastSeen) * 1440 - 5) < 0.1)
  finally
    T.Free;
    L.Free
  end
end;

procedure TSpotStoreTest.SnapshotSkipsGarbageLines;
var
  L : TStringList;
begin
  L := TStringList.Create;
  try
    Store.SaveSnapshot(L);      //header only
    L.Add('this is not a spot');
    L.Add('1;1;OK1RBN;OK1AA;20M;CW;notanumber;0;0;0;0;' + FloatToStr(Now));
    Store.LoadSnapshot(L, Now);
    AssertEquals(0, Store.Count)
  finally
    L.Free
  end
end;

procedure TSpotStoreTest.OneStationOncePerBandAtItsLatestFrequency;
var
  A : TSpotCandidate;
  V : TSpotView;
begin
  //the station QSYed; one skimmer heard it on the new frequency, another still
  //holds the old one. The view shows it once, where it was heard last
  A := MakeSpot('OK1AA', '20M', 14020, soRbn, 'DL1RBN'); A.LastSeen := Now - 3/1440; Store.Add(A);
  A := MakeSpot('OK1AA', '20M', 14035, soRbn, 'W3RBN');  A.LastSeen := Now;          Store.Add(A);
  V := Store.Select('20M', Now, DefaultSpotFilter, @NeverWorked);
  AssertEquals(1, Length(V));
  AssertEquals(14035.0, V[0].FreqKHz, 0.001);
  //both candidates stay in the store, the source filter needs them apart
  AssertEquals(2, Store.Count)
end;

procedure TSpotStoreTest.SimilarCallOnSameFrequencyIsHidden;
var
  V : TSpotView;
begin
  //a skimmer garbles a letter or two; on the same frequency it is the same
  //station, and the call reported most often is the one to trust. Missing,
  //extra and wrong characters alike
  Store.Add(MakeSpot('OK2CQ',   '20M', 14020.0, soRbn, 'DL1RBN'));
  Store.Add(MakeSpot('OK2CQA',  '20M', 14020.1, soRbn, 'W3RBN'));
  Store.Add(MakeSpot('OK2CQR',  '20M', 14020.0, soRbn, 'G4RBN'));
  Store.Add(MakeSpot('OK2CQR',  '20M', 14020.0, soRbn, 'G4RBN'));
  Store.Add(MakeSpot('K1ABC',   '20M', 14030.0, soRbn, 'DL1RBN'));
  Store.Add(MakeSpot('WK1ABC',  '20M', 14029.9, soRbn, 'W3RBN'));
  Store.Add(MakeSpot('WK1ABC',  '20M', 14029.9, soRbn, 'W3RBN'));
  V := Store.Select('20M', Now, DefaultSpotFilter, @NeverWorked);
  AssertEquals(2, Length(V));
  AssertEquals('OK2CQR', V[0].Call);
  AssertEquals('WK1ABC', V[1].Call)
end;

procedure TSpotStoreTest.SimilarCallFurtherAwayIsAnotherStation;
var
  V : TSpotView;
begin
  //more than 100 Hz apart: two stations that happen to have similar calls
  Store.Add(MakeSpot('OK2CQ',  '20M', 14020.0, soRbn, 'DL1RBN'));
  Store.Add(MakeSpot('OK2CQR', '20M', 14020.2, soRbn, 'W3RBN'));
  V := Store.Select('20M', Now, DefaultSpotFilter, @NeverWorked);
  AssertEquals(2, Length(V))
end;

procedure TSpotStoreTest.DifferentCallsOnSameFrequencyBothStay;
var
  V : TSpotView;
begin
  //not alike: two stations on one frequency that do not hear each other
  Store.Add(MakeSpot('OK1AA', '20M', 14020.0, soRbn, 'DL1RBN'));
  Store.Add(MakeSpot('W3ABC', '20M', 14020.0, soRbn, 'W3RBN'));
  V := Store.Select('20M', Now, DefaultSpotFilter, @NeverWorked);
  AssertEquals(2, Length(V))
end;

procedure TSpotStoreTest.MostOftenSpottedVariantWins;
var
  A : TSpotView;
  V : TSpotView;
begin
  //the garbled variant came last, the real call three times over two skimmers
  Store.Add(MakeSpot('OK2CQR', '20M', 14020.0, soRbn, 'DL1RBN'));
  Store.Add(MakeSpot('OK2CQR', '20M', 14020.0, soRbn, 'DL1RBN'));
  Store.Add(MakeSpot('OK2CQR', '20M', 14020.0, soRbn, 'W3RBN'));
  Store.Add(MakeSpot('OK2CQA', '20M', 14020.05, soRbn, 'G4RBN'));
  V := Store.Select('20M', Now, DefaultSpotFilter, @NeverWorked);
  AssertEquals(1, Length(V));
  AssertEquals('OK2CQR', V[0].Call);
  AssertEquals(14020.0, V[0].FreqKHz, 0.001);
  //and the other way round: the variant heard most often wins even if shorter
  Store.Clear;
  Store.Add(MakeSpot('OK2CQR', '20M', 14020.0, soRbn, 'DL1RBN'));
  Store.Add(MakeSpot('OK2CQ',  '20M', 14020.0, soRbn, 'W3RBN'));
  Store.Add(MakeSpot('OK2CQ',  '20M', 14020.0, soRbn, 'W3RBN'));
  A := Store.Select('20M', Now, DefaultSpotFilter, @NeverWorked);
  AssertEquals(1, Length(A));
  AssertEquals('OK2CQ', A[0].Call)
end;

procedure TSpotStoreTest.HitsCountArrivalsAndSurviveSnapshot;
var
  L : TStringList;
  T : TSpotStore;
  V : TSpotView;
begin
  Store.Add(MakeSpot('OK1AA', '20M', 14020, soRbn, 'DL1RBN'));
  Store.Add(MakeSpot('OK1AA', '20M', 14020, soRbn, 'DL1RBN'));
  Store.Add(MakeSpot('OK1AA', '20M', 14020, soRbn, 'DL1RBN'));
  V := Store.Select('20M', Now, DefaultSpotFilter, @NeverWorked);
  AssertEquals(3, V[0].Hits);
  L := TStringList.Create;
  T := TSpotStore.Create(100);
  try
    Store.SaveSnapshot(L);
    T.LoadSnapshot(L, Now);
    V := T.Select('20M', Now, DefaultSpotFilter, @NeverWorked);
    AssertEquals(1, Length(V));
    AssertEquals(3, V[0].Hits)
  finally
    T.Free;
    L.Free
  end
end;

procedure TSpotStoreTest.PortableSuffixDoesNotCountAsDifference;
var
  V : TSpotView;
begin
  //HB9BHW/P heard as HB9BH: the /P is not a garbled character, the base call
  //is compared. The same for a prefix, DL/OK2CQR is OK2CQR
  Store.Add(MakeSpot('HB9BHW/P', '20M', 14020.0, soRbn, 'DL1RBN'));
  Store.Add(MakeSpot('HB9BHW/P', '20M', 14020.0, soRbn, 'DL1RBN'));
  Store.Add(MakeSpot('HB9BH',    '20M', 14020.1, soRbn, 'W3RBN'));
  Store.Add(MakeSpot('DL/OK2CQR','20M', 14030.0, soRbn, 'DL1RBN'));
  Store.Add(MakeSpot('DL/OK2CQR','20M', 14030.0, soRbn, 'DL1RBN'));
  Store.Add(MakeSpot('OK2CQ',    '20M', 14030.0, soRbn, 'W3RBN'));
  V := Store.Select('20M', Now, DefaultSpotFilter, @NeverWorked);
  AssertEquals(2, Length(V));
  AssertEquals('HB9BHW/P', V[0].Call);
  AssertEquals('DL/OK2CQR', V[1].Call)
end;

initialization
  RegisterTest(TSpotStoreTest);
end.
