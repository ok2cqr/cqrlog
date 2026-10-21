(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Position of the Sun for the grayline map: the point where the Sun is in
  the zenith at a given UTC.

  The Sun comes from VSOP87 (vsop.pas), nutation and sidereal time follow
  Meeus, Astronomical Algorithms, chapters 12 and 22.  UT is used in place of
  TT; the difference (about a minute) moves the Sun by less than 0.001 deg.

  Moved here from gline2, where the Julian date offset was left at zero and
  the hour angle was put together wrongly, so the shadow was 45 to 105
  minutes off depending on the season.  No LCL; see tests/tSunPosition.pas. }

unit uSunPosition;

{$mode objfpc}{$H+}

interface

//Julian day of a TDateTime (UTC)
function JulianDate(const UTC : TDateTime) : Extended;

//apparent Greenwich sidereal time, degrees 0..360
function SiderealTime(const UTC : TDateTime) : Extended;

//apparent geocentric right ascension (0..360) and declination of the Sun, degrees
procedure SunEquatorial(const UTC : TDateTime; out RightAscension, Declination : Extended);

//where the Sun is in the zenith; latitude -90..90, longitude -180..180 (east positive)
procedure SubsolarPoint(const UTC : TDateTime; out Latitude, Longitude : Extended);

implementation

uses
  SysUtils, ah_math, vsop;

const
  //Julian day of TDateTime 0 (1899-12-30 00:00)
  JULIAN_OFFSET = 2415018.5;
  J2000 = 2451545.0;

function JulianDate(const UTC : TDateTime) : Extended;
begin
  Result := JULIAN_OFFSET + UTC
end;

//nutation in longitude and true obliquity of the ecliptic, both in degrees
procedure Nutation(const UTC : TDateTime; out DeltaPhi, Epsilon : Extended);
const
  arg_mul:array[0..30,0..4] of shortint = (
     ( 0, 0, 0, 0, 1),
     (-2, 0, 0, 2, 2),
     ( 0, 0, 0, 2, 2),
     ( 0, 0, 0, 0, 2),
     ( 0, 1, 0, 0, 0),
     ( 0, 0, 1, 0, 0),
     (-2, 1, 0, 2, 2),
     ( 0, 0, 0, 2, 1),
     ( 0, 0, 1, 2, 2),
     (-2,-1, 0, 2, 2),
     (-2, 0, 1, 0, 0),
     (-2, 0, 0, 2, 1),
     ( 0, 0,-1, 2, 2),
     ( 2, 0, 0, 0, 0),
     ( 0, 0, 1, 0, 1),
     ( 2, 0,-1, 2, 2),
     ( 0, 0,-1, 0, 1),
     ( 0, 0, 1, 2, 1),
     (-2, 0, 2, 0, 0),
     ( 0, 0,-2, 2, 1),
     ( 2, 0, 0, 2, 2),
     ( 0, 0, 2, 2, 2),
     ( 0, 0, 2, 0, 0),
     (-2, 0, 1, 2, 2),
     ( 0, 0, 0, 2, 0),
     (-2, 0, 0, 2, 0),
     ( 0, 0,-1, 2, 1),
     ( 0, 2, 0, 0, 0),
     ( 2, 0,-1, 0, 1),
     (-2, 2, 0, 2, 2),
     ( 0, 1, 0, 0, 1)
                   );
  arg_phi:array[0..30,0..1] of longint = (
     (-171996,-1742),
     ( -13187,  -16),
     (  -2274,   -2),
     (   2062,    2),
     (   1426,  -34),
     (    712,    1),
     (   -517,   12),
     (   -386,   -4),
     (   -301,    0),
     (    217,   -5),
     (   -158,    0),
     (    129,    1),
     (    123,    0),
     (     63,    0),
     (     63,    1),
     (    -59,    0),
     (    -58,   -1),
     (    -51,    0),
     (     48,    0),
     (     46,    0),
     (    -38,    0),
     (    -31,    0),
     (     29,    0),
     (     29,    0),
     (     26,    0),
     (    -22,    0),
     (     21,    0),
     (     17,   -1),
     (     16,    0),
     (    -16,    1),
     (    -15,    0)
    );
  arg_eps:array[0..30,0..1] of longint = (
     ( 92025,   89),
     (  5736,  -31),
     (   977,   -5),
     (  -895,    5),
     (    54,   -1),
     (    -7,    0),
     (   224,   -6),
     (   200,    0),
     (   129,   -1),
     (   -95,    3),
     (     0,    0),
     (   -70,    0),
     (   -53,    0),
     (     0,    0),
     (   -33,    0),
     (    26,    0),
     (    32,    0),
     (    27,    0),
     (     0,    0),
     (   -24,    0),
     (    16,    0),
     (    13,    0),
     (     0,    0),
     (   -12,    0),
     (     0,    0),
     (     0,    0),
     (   -10,    0),
     (     0,    0),
     (    -8,    0),
     (     7,    0),
     (     9,    0)
    );
var
  t, omega, d, m, ms, f, s, DeltaEpsilon, Epsilon0 : Extended;
  i : Integer;
begin
  t := (JulianDate(UTC)-J2000)/36525;

  //longitude of the ascending node of the Moon
  omega := put_in_360(125.04452+(-1934.136261+(0.0020708+1/450000*t)*t)*t);
  //mean elongation of the Moon from the Sun
  d  := put_in_360(297.85036+(445267.111480+(-0.0019142+t/189474)*t)*t);
  //mean anomaly of the Sun
  m  := put_in_360(357.52772+(35999.050340+(-0.0001603-t/300000)*t)*t);
  //mean anomaly of the Moon
  ms := put_in_360(134.96298+(477198.867398+(0.0086972+t/56250)*t)*t);
  //argument of latitude of the Moon
  f  := put_in_360(93.27191+(483202.017538+(-0.0036825+t/327270)*t)*t);

  DeltaPhi     := 0;
  DeltaEpsilon := 0;
  for i := 0 to 30 do
  begin
    s := arg_mul[i,0]*d+arg_mul[i,1]*m+arg_mul[i,2]*ms+arg_mul[i,3]*f+arg_mul[i,4]*omega;
    DeltaPhi     := DeltaPhi+(arg_phi[i,0]+arg_phi[i,1]*t*0.1)*sin_d(s);
    DeltaEpsilon := DeltaEpsilon+(arg_eps[i,0]+arg_eps[i,1]*t*0.1)*cos_d(s)
  end;
  DeltaPhi     := DeltaPhi*0.0001/3600;
  DeltaEpsilon := DeltaEpsilon*0.0001/3600;

  //mean obliquity of the ecliptic, arc seconds
  Epsilon0 := 84381.448+(-46.8150+(-0.00059+0.001813*t)*t)*t;
  Epsilon  := (Epsilon0+DeltaEpsilon*3600)/3600
end;

function SiderealTime(const UTC : TDateTime) : Extended;
var
  jd, t, DeltaPhi, Epsilon : Extended;
begin
  jd := JulianDate(UTC);
  t  := (jd-J2000)/36525;
  Nutation(UTC, DeltaPhi, Epsilon);
  Result := put_in_360(280.46061837+360.98564736629*(jd-J2000)+
                       t*t*(0.000387933-t/38710000)+
                       DeltaPhi*cos_d(Epsilon))
end;

procedure SunEquatorial(const UTC : TDateTime; out RightAscension, Declination : Extended);
var
  Earth : TVSOPEarth;
  l, b, r, t, lambda, DeltaPhi, Epsilon : Extended;
begin
  Earth := TVSOPEarth.Create;
  try
    Earth.Date := UTC;
    r := Earth.Radius;
    l := Earth.Longitude;
    b := Earth.Latitude;
    Earth.DynamicToFK5(l, b)
  finally
    Earth.Free
  end;
  //heliocentric Earth -> geocentric Sun
  l := put_in_360(rad2deg(l)+180);
  b := -rad2deg(b);
  //conversion to FK5
  t := (JulianDate(UTC)-J2000)/36525;
  lambda := l+(-1.397-0.00031*t)*t;
  l := l-0.09033/3600;
  b := b+0.03916/3600*(cos_d(lambda)-sin_d(lambda));
  //aberration
  l := l-20.4898/3600/r;
  //nutation
  Nutation(UTC, DeltaPhi, Epsilon);
  l := put_in_360(l+DeltaPhi);

  RightAscension := put_in_360(arctan2_d(sin_d(l)*cos_d(Epsilon)-tan_d(b)*sin_d(Epsilon), cos_d(l)));
  Declination    := arcsin_d(sin_d(b)*cos_d(Epsilon)+cos_d(b)*sin_d(Epsilon)*sin_d(l))
end;

procedure SubsolarPoint(const UTC : TDateTime; out Latitude, Longitude : Extended);
var
  RightAscension : Extended;
begin
  SunEquatorial(UTC, RightAscension, Latitude);
  //the local hour angle GST + lon - RA is zero there
  Longitude := put_in_360(RightAscension-SiderealTime(UTC));
  if Longitude > 180 then
    Longitude := Longitude-360
end;

end.
