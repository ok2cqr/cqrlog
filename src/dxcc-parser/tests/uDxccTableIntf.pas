(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Common interface implemented by both the legacy engine (uLegacyTable) and the
  new one (uModernTable), so a single set of characterisation tests can be run
  against either. }

unit uDxccTableIntf;

{$mode objfpc}{$H+}

interface

type
  { Maps 1:1 onto znacmech's c_pres_* constants and onto dDXCC's
    NotExactly / Exactly / ExNoEquals (dDXCC.pas:41-43).

      mmPrefix         the callsign may be longer than the pattern
      mmExact          pattern and callsign must have the same effective length
      mmExactNoEquals  as mmExact, but '=' exact-match entries are ignored }
  TMatchMode = (mmPrefix, mmExact, mmExactNoEquals);

const
  { Field numbers accepted by IDxccTable.Field.  These are znacmech's c_pop_*
    constants; the names here say what the data actually is. }
  fldCountry   = 0;
  fldContinent = 1;
  fldUtcOffset = 2;
  fldLatitude  = 3;
  fldLongitude = 4;
  fldItu       = 5;
  fldWaz       = 6;
  fldAdifCol   = 7;   { ADIF from the 9th column of the source line }
  fldFlag      = 8;   { 'R', 'D' or empty }
  fldValidFrom = 9;
  fldValidTo   = 10;
  fldAdif      = 11;  { ADIF after '=' -- this is the one dDXCC reads }

  fldFirst = 0;
  fldLast  = 11;

  { znacmech.datum_od_default / datum_do_default }
  DefaultValidFrom = '1945/01/01';
  DefaultValidTo   = '2050/01/01';

  { Returned by the legacy engine for an out-of-range index. }
  OutOfRangeMarker = 'XXXXXXXX';

type
  IDxccTable = interface
    ['{6E1B2A54-0F3C-4B7E-9A21-8D5C4F7E1B03}']
    function Count: Integer;
    function Find(const Callsign, ADate: string; Mode: TMatchMode): Integer;
    function Pattern(Index: Integer): string;
    function Field(Index, FieldNo: Integer): string;
    function IsValidOn(Index: Integer; const ADate: string): Boolean;
  end;

implementation

end.
