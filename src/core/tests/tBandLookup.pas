(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Band from frequency.  The expected results follow what
  TdmUtils.BandFromArray returned before the lookup moved to uBandPlan:
  first matching row wins, both edges inclusive. }

unit tBandLookup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uBandPlan;

type
  TBandLookupTest = class(TTestCase)
  private
    Edges : array of TBandEdge;
    procedure Add(const Band : String; BBegin, BEnd : Currency);
  protected
    procedure SetUp; override;
  published
    procedure InsideBand;
    procedure EdgesAreInclusive;
    procedure JustOutsideBand;
    procedure BetweenBands;
    procedure FirstMatchWins;
    procedure EmptyTable;
    procedure UnusedSlotsAreZero;
    procedure IndexOfBand;
  end;

implementation

procedure TBandLookupTest.Add(const Band : String; BBegin, BEnd : Currency);
begin
  SetLength(Edges, Length(Edges)+1);
  Edges[High(Edges)].band    := Band;
  Edges[High(Edges)].b_begin := BBegin;
  Edges[High(Edges)].b_end   := BEnd
end;

procedure TBandLookupTest.SetUp;
begin
  SetLength(Edges, 0);
  Add('160M', 1.8, 2.0);
  Add('80M', 3.5, 3.8);
  Add('40M', 7.0, 7.2);
  Add('20M', 14.0, 14.35);
  Add('2M', 144.0, 146.0)
end;

procedure TBandLookupTest.InsideBand;
begin
  AssertEquals('80M', BandFromFreq(3.55, Edges));
  AssertEquals('20M', BandFromFreq(14.0251, Edges));
  AssertEquals('2M', BandFromFreq(144.3, Edges))
end;

procedure TBandLookupTest.EdgesAreInclusive;
begin
  AssertEquals('40M', BandFromFreq(7.0, Edges));
  AssertEquals('40M', BandFromFreq(7.2, Edges))
end;

procedure TBandLookupTest.JustOutsideBand;
begin
  AssertEquals('', BandFromFreq(6.9999, Edges));
  AssertEquals('', BandFromFreq(7.2001, Edges))
end;

procedure TBandLookupTest.BetweenBands;
begin
  AssertEquals('', BandFromFreq(10.1, Edges));
  AssertEquals(-1, BandIndexFromFreq(10.1, Edges))
end;

procedure TBandLookupTest.FirstMatchWins;
begin
  Add('40M-EXT', 7.0, 7.3);
  AssertEquals('40M', BandFromFreq(7.1, Edges));
  AssertEquals('40M-EXT', BandFromFreq(7.25, Edges))
end;

procedure TBandLookupTest.EmptyTable;
begin
  SetLength(Edges, 0);
  AssertEquals('', BandFromFreq(14.0, Edges));
  AssertEquals(-1, BandIndexFromFreq(14.0, Edges))
end;

procedure TBandLookupTest.UnusedSlotsAreZero;
begin
  //CQRLOG's table has fixed size and the rows past the last band stay zero,
  //so 0 MHz "matches" an empty row: the name is '' either way
  Add('', 0, 0);
  Add('', 0, 0);
  AssertEquals('', BandFromFreq(0, Edges));
  AssertEquals(5, BandIndexFromFreq(0, Edges));
  AssertEquals('20M', BandFromFreq(14.1, Edges))
end;

procedure TBandLookupTest.IndexOfBand;
begin
  AssertEquals(0, BandIndexFromFreq(1.85, Edges));
  AssertEquals(3, BandIndexFromFreq(14.2, Edges))
end;

initialization
  RegisterTest(TBandLookupTest)
end.
