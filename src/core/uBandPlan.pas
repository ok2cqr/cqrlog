(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Band from frequency, over a table of band edges in MHz.

  The lookup takes the table as a parameter: CQRLOG passes the edges it loads
  from the database (dmUtils.BandFreq, editable in the preferences), so the
  same code works without one.  First matching row wins, both edges inclusive.

  Moved here from TdmUtils.BandFromArray to be testable without LCL and MySQL.
  No LCL, no globals; see tests/tBandLookup.pas. }

unit uBandPlan;

{$mode objfpc}{$H+}

interface

type
  TBandEdge = record
    band     : string;
    b_begin  : currency; //MHz
    b_end    : currency; //MHz
  end;

//index of the first row containing MHz, -1 if none
function BandIndexFromFreq(MHz : Currency; const Edges : array of TBandEdge) : Integer;
//band name of that row, '' if none
function BandFromFreq(MHz : Currency; const Edges : array of TBandEdge) : String;

implementation

function BandIndexFromFreq(MHz : Currency; const Edges : array of TBandEdge) : Integer;
var
  x : Integer;
begin
  for x:=0 to High(Edges) do
    if (MHz >= Edges[x].b_begin) and (MHz <= Edges[x].b_end) then
      exit(x);
  Result := -1
end;

function BandFromFreq(MHz : Currency; const Edges : array of TBandEdge) : String;
var
  x : Integer;
begin
  x := BandIndexFromFreq(MHz, Edges);
  if x < 0 then
    Result := ''
  else
    Result := Edges[x].band
end;

end.
