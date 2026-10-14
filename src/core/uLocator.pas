(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Maidenhead locators: validation, coordinates, distance and azimuth.

  The distance and azimuth themselves come from azidis3 (locator to locator)
  and aziloc (coordinate to locator).  Neither is reentrant -- both keep their
  intermediate results in unit-level variables -- so call these from one
  thread only.

  Moved here from TdmUtils to be testable without LCL and MySQL; the TdmUtils
  methods of the same names call these.  No LCL; see tests/tLocatorMath.pas. }

unit uLocator;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, azidis3, aziloc;

//pads a 2 or 4 character locator to 6, cuts 8 and more to 6; odd length is
//left as it is so the validation catches it
function  CompleteLoc(loc: string): string;
//6 character Maidenhead locator after CompleteLoc, any case
function  IsLocOK(Loc: string): boolean;
//AA00aa00: upper case square, lower case subsquare
function  StdFormatLocator(loc:string):String;
//centre of the locator's subsquare (any case, completed like IsLocOK);
//untouched if the locator is not valid
procedure CoordinateFromLocator(loc: string; var latitude, longitude: currency);
//qra in km, azim in degrees; untouched if a locator is not valid
procedure DistanceFromLocator(my_loc, his_loc: string; var qra, azim: string);
procedure DistanceFromCoordinate(my_loc: string; latitude, longitude: real;
  var qra, azim: string);
//'41.9055N', '12.4808W' (Country.tab format) -> signed degrees, 0 if not readable
procedure GetRealCoordinate(lat, long: string; var latitude, longitude: currency);

implementation

function CompleteLoc(loc: string): string;
begin
  //we will fix even length locators from length 2 .. X  and return them as length of 6
  //length 8, and up, loc is cutted to length 6
  //Odd length loc is not touched to see error later
  if (loc<>'') then
   begin
     loc := trim(loc);
     if  (Length(loc) mod 2 = 0 ) then
       begin
         case  Length(loc) of
           2:              loc := loc + '44LL';
           4:              loc := loc + 'LL';
           else
             loc := copy(loc,1,6);
         end;
       end;
   end;
  Result := loc;
end;

function IsLocOK(Loc: string): boolean;
var
  i,
  r : integer;
begin
  r:=0;
  loc := CompleteLoc(loc);   //does not fix empty or odd length, otherwise sets length of 6
  if  Length(loc) = 6  then  //length should be now 6 if passed this far
   begin
     Loc := UpCase(Loc);
     for i := 1 to 6 do
        begin
          case i of
            1, 2 : case Loc[i] of
                        'A'..'R':  inc(r);
                   end;
            3, 4 : case Loc[i] of
                        '0'..'9':  inc(r);
                   end;
            5, 6 : case Loc[i] of
                        'A'..'X':  inc(r);
                   end;
          end;
       end;
   end;
  Result := (r = 6);
end;

function StdFormatLocator(loc:string):String;
// Format locator to standard form BL11bh16 See:
// https://en.wikipedia.org/wiki/Maidenhead_Locator_System#Description_of_the_system
// Check TEdit CharCase to be ecNormal, othewise you get runtime error!
var
  s :String;
begin
  Result := loc;
  if loc = '' then exit;
  s :=  Upcase(copy(loc,1,4));
  s:= s + lowercase(copy(loc,5,6));   //max loc length 10 in database
  Result := trim(s);
end;

function nr(ch: char): integer;
var
  letters: string;
begin
  letters := 'ABCDEFGHIJKLMNOPQRSTUVWX';
  Result := Pos(ch, letters);
end;

procedure CoordinateFromLocator(loc: string; var latitude, longitude: currency);
var
  a, b, c, d, e, f: integer;
begin
  if not IsLocOK(loc) then
    exit;
  //compute from what IsLocOK validated: completed, trimmed, upper case
  loc := UpCase(CompleteLoc(loc));

  a := nr(loc[1]);
  b := nr(loc[2]);
  c := StrToInt(loc[3]);
  d := StrToInt(loc[4]);
  e := nr(loc[5]);
  f := nr(loc[6]);

  longitude := (a - 10) * 20 + c * 2 + (e - 1) * 0.083333333333333333330 + 0.08333333333333333333 / 2;
  latitude := (b - 10) * 10 + d * 1 + (f - 1) * 0.04166666666666666667 + 0.04166666666666666667 / 2;
end;

procedure DistanceFromLocator(my_loc, his_loc: string; var qra, azim: string);
var
  qra1: string;
  azim1: string;
begin
  if not IsLocOK(my_loc) then
    exit;
  if not IsLocOK(his_loc) then
    exit;
  VzdalenostAAzimut(my_loc, his_loc, azim1, qra1);
  qra := qra1;
  azim := azim1;
end;

procedure DistanceFromCoordinate(my_loc: string; latitude, longitude: real;
  var qra, azim: string);
var
  loc: string;
  qra1: string;
  azim1: string;
begin
  if not IsLocOK(my_loc) then
    exit;

  loc := VratLokator(latitude, longitude);
  if not IsLocOK(loc) then
    exit;

  VzdalenostAAzimut(my_loc, loc, azim1, qra1);
  qra := qra1;
  azim := azim1;
end;

procedure GetRealCoordinate(lat, long: string; var latitude, longitude: currency);
var
  s, d: string;
begin
  s := lat;
  d := long;
  if ((Length(s) = 0) or (Length(d) = 0)) then
  begin
    longitude := 0;
    latitude := 0;
    exit;
  end;

  if s[Length(s)] = 'S' then
    s := '-' + s;
  s := copy(s, 1, Length(s) - 1);
  if pos('.', s) > 0 then
    s[pos('.', s)] := FormatSettings.DecimalSeparator;
  if not TryStrToCurr(s, latitude) then
    latitude := 0;

  if d[Length(d)] = 'W' then
    d := '-' + d;
  d := copy(d, 1, Length(d) - 1);
  if pos('.', d) > 0 then
    d[pos('.', d)] := FormatSettings.DecimalSeparator;
  if not TryStrToCurr(d, longitude) then
    longitude := 0;
end;

end.
