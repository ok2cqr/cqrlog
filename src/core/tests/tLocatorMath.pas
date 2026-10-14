(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Maidenhead locators, coordinates, distance and azimuth.  The expected
  results follow what the TdmUtils methods returned before they moved to
  uLocator. }

unit tLocatorMath;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry, uLocator, aziloc;

type
  TLocatorTest = class(TTestCase)
  published
    procedure CompleteShortLocators;
    procedure CompleteLeavesOddLength;
    procedure ValidLocators;
    procedure InvalidLocators;
    procedure StandardFormat;
    procedure CoordinateOfSquareCentre;
    procedure CoordinateOfInvalidLocatorIsUntouched;
    procedure CoordinateOfLowercaseSubsquare;
    procedure DistanceToItself;
    procedure DistanceBrnoBerlin;
    procedure DistanceAcrossTheWorld;
    procedure DistanceNeedsValidLocators;
    procedure LocatorFromCoordinate;
    procedure DistanceFromCoordinate;
    procedure RealCoordinates;
    procedure RealCoordinatesEmptyOrGarbage;
  end;

implementation

{ independent great circle distance and initial bearing between two locators'
  centres, to check azidis3 against something that is not azidis3 }
procedure GreatCircle(const Loc1, Loc2 : String; out Km, Bearing : Double);
var
  la1, lo1, la2, lo2 : Currency;
  p1, p2, dl : Double;
begin
  CoordinateFromLocator(Loc1, la1, lo1);
  CoordinateFromLocator(Loc2, la2, lo2);
  p1 := DegToRad(la1); p2 := DegToRad(la2); dl := DegToRad(lo2 - lo1);
  Km := 6365 * ArcCos(Sin(p1)*Sin(p2) + Cos(p1)*Cos(p2)*Cos(dl));
  Bearing := RadToDeg(ArcTan2(Sin(dl)*Cos(p2), Cos(p1)*Sin(p2) - Sin(p1)*Cos(p2)*Cos(dl)));
  if Bearing < 0 then Bearing := Bearing + 360
end;

procedure TLocatorTest.CompleteShortLocators;
begin
  AssertEquals('JN44LL', CompleteLoc('JN'));
  AssertEquals('JN89LL', CompleteLoc('JN89'));
  AssertEquals('JN89HE', CompleteLoc('JN89HE'));
  AssertEquals('JN89HE', CompleteLoc('JN89HE16'));
  AssertEquals('JN89LL', CompleteLoc(' JN89 '));
  AssertEquals('', CompleteLoc(''))
end;

procedure TLocatorTest.CompleteLeavesOddLength;
begin
  AssertEquals('JN8', CompleteLoc('JN8'));
  AssertEquals('JN89H', CompleteLoc('JN89H'))
end;

procedure TLocatorTest.ValidLocators;
begin
  AssertTrue(IsLocOK('JN89HE'));
  AssertTrue(IsLocOK('jn89he'));
  AssertTrue(IsLocOK('JN89'));
  AssertTrue(IsLocOK('JN89HE16'));
  AssertTrue(IsLocOK('AA00AA'));
  AssertTrue(IsLocOK('RR99XX'))
end;

procedure TLocatorTest.InvalidLocators;
begin
  AssertFalse(IsLocOK(''));
  AssertFalse(IsLocOK('JN8'));
  AssertFalse(IsLocOK('JS89HE'));   //field letters end at R
  AssertFalse(IsLocOK('JN89HY'));   //subsquare letters end at X
  AssertFalse(IsLocOK('JNA9HE'));
  AssertFalse(IsLocOK('JN89H1'))
end;

procedure TLocatorTest.StandardFormat;
begin
  AssertEquals('JN89he', StdFormatLocator('jn89HE'));
  AssertEquals('JN89he16', StdFormatLocator('JN89HE16'));
  AssertEquals('JN89', StdFormatLocator('jn89'));
  AssertEquals('', StdFormatLocator(''))
end;

procedure TLocatorTest.CoordinateOfSquareCentre;
var
  lat, lon : Currency;
begin
  CoordinateFromLocator('JN89HE', lat, lon);
  AssertEquals(49.1875, Double(lat), 0.0001);
  AssertEquals(16.625, Double(lon), 0.0001);
  CoordinateFromLocator('FN31PR', lat, lon);
  AssertEquals(41.7292, Double(lat), 0.0001);
  AssertEquals(-72.7083, Double(lon), 0.0001)
end;

procedure TLocatorTest.CoordinateOfInvalidLocatorIsUntouched;
var
  lat, lon : Currency;
begin
  lat := 1; lon := 2;
  CoordinateFromLocator('JS89HE', lat, lon);
  AssertEquals(1.0, Double(lat), 0);
  AssertEquals(2.0, Double(lon), 0)
end;

procedure TLocatorTest.CoordinateOfLowercaseSubsquare;
var
  lat, lon : Currency;
begin
  //the letters are looked up as upper case only, so the subsquare of
  //'JN89he' (StdFormatLocator's output) counts as 0.  Kept as it was.
  CoordinateFromLocator('JN89he', lat, lon);
  AssertEquals(48.9792, Double(lat), 0.0001);
  AssertEquals(15.9583, Double(lon), 0.0001)
end;

procedure TLocatorTest.DistanceToItself;
var
  qra, azim : String;
begin
  DistanceFromLocator('JN89HE', 'JN89HE', qra, azim);
  AssertEquals('1', qra)  //REG1 rounding: trunc(km) + 1
end;

procedure TLocatorTest.DistanceBrnoBerlin;
var
  qra, azim : String;
  km, bearing : Double;
begin
  DistanceFromLocator('JN89HE', 'JO62QM', qra, azim);
  GreatCircle('JN89HE', 'JO62QM', km, bearing);
  AssertEquals(km, StrToFloat(qra), 1 + km*0.001); //azidis3 uses rounded constants
  AssertEquals(bearing, StrToFloat(azim), 1)
end;

procedure TLocatorTest.DistanceAcrossTheWorld;
var
  qra, azim : String;
  km, bearing : Double;
begin
  DistanceFromLocator('jn89he', 'FN31PR', qra, azim);
  GreatCircle('JN89HE', 'FN31PR', km, bearing);
  AssertEquals(km, StrToFloat(qra), 1 + km*0.001); //azidis3 uses rounded constants
  AssertEquals(bearing, StrToFloat(azim), 1)
end;

procedure TLocatorTest.DistanceNeedsValidLocators;
var
  qra, azim : String;
begin
  qra := 'x'; azim := 'y';
  DistanceFromLocator('JN89HE', 'JS89HE', qra, azim);
  AssertEquals('x', qra);
  AssertEquals('y', azim);
  DistanceFromLocator('', 'JN89HE', qra, azim);
  AssertEquals('x', qra)
end;

procedure TLocatorTest.LocatorFromCoordinate;
begin
  AssertEquals('JN89HE', VratLokator(49.1875, 16.625));
  AssertEquals('FN31PR', VratLokator(41.7292, -72.7083))
end;

procedure TLocatorTest.DistanceFromCoordinate;
var
  qra, azim : String;
begin
  uLocator.DistanceFromCoordinate('JN89HE', 49.1875, 16.625, qra, azim);
  AssertEquals('1', qra);
  qra := 'x';
  uLocator.DistanceFromCoordinate('JS89HE', 49.1875, 16.625, qra, azim);
  AssertEquals('x', qra)
end;

procedure TLocatorTest.RealCoordinates;
var
  lat, lon : Currency;
begin
  GetRealCoordinate('41.9055N', '12.4808E', lat, lon);
  AssertEquals(41.9055, Double(lat), 0.00001);
  AssertEquals(12.4808, Double(lon), 0.00001);
  GetRealCoordinate('5.21S', '72.28W', lat, lon);
  AssertEquals(-5.21, Double(lat), 0.00001);
  AssertEquals(-72.28, Double(lon), 0.00001)
end;

procedure TLocatorTest.RealCoordinatesEmptyOrGarbage;
var
  lat, lon : Currency;
begin
  lat := 1; lon := 2;
  GetRealCoordinate('', '12.48E', lat, lon);
  AssertEquals(0.0, Double(lat), 0);
  AssertEquals(0.0, Double(lon), 0);
  GetRealCoordinate('abcN', '12.48E', lat, lon);
  AssertEquals(0.0, Double(lat), 0);
  AssertEquals(12.48, Double(lon), 0.00001)
end;

initialization
  RegisterTest(TLocatorTest)
end.
