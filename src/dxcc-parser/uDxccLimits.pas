(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Size limits of the table file format.

  In the legacy engine these are shortstring type widths (znacmech.pas:41-43),
  so exceeding one truncates silently.  They are named here because the
  truncation is observable behaviour that the tests pin down, not an
  implementation detail that can be quietly dropped.

  Measured against the current country files:

    marks        longest 42  -> exceeds MaxMarkLength, gets truncated
    description  longest 226 -> fits
    entries      21560       -> fits
    descriptions 9056 unique -> 90.6% of the legacy popisu_max of 10000

  The new implementation keeps the length limits, because they change results,
  but drops the capacity ceilings, because hitting one disables the whole table
  (znacmech.pas:376-381 sets ziju:=false and every later lookup returns -1). }

unit uDxccLimits;

{$mode objfpc}{$H+}

interface

const
  { znacmech.max_delka_znacky }
  MaxMarkLength = 40;
  { znacmech.max_delka_popisu }
  MaxDescriptionLength = 250;
  { znacmech.max_delka_data }
  MaxDateLength = 15;

implementation

end.
