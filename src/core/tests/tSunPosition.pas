(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Position of the Sun for the grayline map.  Reference values are the worked
  examples in Meeus, Astronomical Algorithms (2nd ed.), and the 2026
  equinox, solstice and equation of time extremes. }

unit tSunPosition;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, fpcunit, testregistry, uSunPosition;

type
  TSunPositionTest = class(TTestCase)
  published
    procedure JulianDateOfJ2000;
    procedure SiderealTimeMeeus12a;
    procedure SunMeeus25b;
    procedure DeclinationAtEquinox;
    procedure DeclinationAtSolstice;
    procedure NoonInFebruaryIsLate;
    procedure NoonInNovemberIsEarly;
    procedure SunNearGreenwichAtNoonAllYear;
    procedure SunMovesWestByHour;
  end;

implementation

function Utc(y, mo, d, h, mi : Word) : TDateTime;
begin
  Result := EncodeDateTime(y, mo, d, h, mi, 0, 0)
end;

procedure TSunPositionTest.JulianDateOfJ2000;
begin
  AssertEquals(2451545.0, JulianDate(Utc(2000, 1, 1, 12, 0)), 1e-9)
end;

//1987 April 10, 0h UT: apparent sidereal time 13h10m46.1351s
procedure TSunPositionTest.SiderealTimeMeeus12a;
begin
  AssertEquals(197.692230, SiderealTime(Utc(1987, 4, 10, 0, 0)), 0.0001)
end;

//1992 October 13.0: RA 198.378178, declination -7.783871 (example 25.b, TD;
//using it as UT moves the Sun by under 0.001 deg)
procedure TSunPositionTest.SunMeeus25b;
var
  ra, dec : Extended;
begin
  SunEquatorial(Utc(1992, 10, 13, 0, 0), ra, dec);
  AssertEquals('right ascension', 198.378178, ra, 0.002);
  AssertEquals('declination', -7.783871, dec, 0.002)
end;

//March equinox 2026-03-20 14:46 UTC
procedure TSunPositionTest.DeclinationAtEquinox;
var
  lat, lon : Extended;
begin
  SubsolarPoint(Utc(2026, 3, 20, 14, 46), lat, lon);
  AssertEquals(0.0, lat, 0.01)
end;

//June solstice 2026-06-21 08:24 UTC, obliquity 23.436 deg
procedure TSunPositionTest.DeclinationAtSolstice;
var
  lat, lon : Extended;
begin
  SubsolarPoint(Utc(2026, 6, 21, 8, 24), lat, lon);
  AssertEquals(23.436, lat, 0.01)
end;

//equation of time -14m13s: the Sun crosses Greenwich at 12:14 UTC, so at
//12:00 it is 3.55 deg east
procedure TSunPositionTest.NoonInFebruaryIsLate;
var
  lat, lon : Extended;
begin
  SubsolarPoint(Utc(2026, 2, 11, 12, 0), lat, lon);
  AssertEquals(3.55, lon, 0.1)
end;

//equation of time +16m26s
procedure TSunPositionTest.NoonInNovemberIsEarly;
var
  lat, lon : Extended;
begin
  SubsolarPoint(Utc(2026, 11, 3, 12, 0), lat, lon);
  AssertEquals(-4.11, lon, 0.1)
end;

//the old gline2 code was 11 to 26 deg off here, depending on the season
procedure TSunPositionTest.SunNearGreenwichAtNoonAllYear;
var
  lat, lon : Extended;
  d : Integer;
begin
  for d := 0 to 364 do
  begin
    SubsolarPoint(IncDay(Utc(2026, 1, 1, 12, 0), d), lat, lon);
    AssertTrue(Format('day %d: longitude %.2f', [d, lon]), Abs(lon) < 4.2)
  end
end;

procedure TSunPositionTest.SunMovesWestByHour;
var
  lat, lon1, lon2 : Extended;
begin
  SubsolarPoint(Utc(2026, 10, 21, 12, 0), lat, lon1);
  SubsolarPoint(Utc(2026, 10, 21, 13, 0), lat, lon2);
  AssertEquals(-15.0, lon2-lon1, 0.01)
end;

initialization
  RegisterTest(TSunPositionTest)
end.
