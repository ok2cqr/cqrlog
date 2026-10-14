(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Super Check Partial: callsigns from MASTER.SCP that contain what has been
  typed so far.

  The calls are kept in one flat string: #10 CALL1 #10 CALL2 #10 ... CALLn #10.
  Find then does one Pos() per hit over the whole buffer instead of one Pos()
  per callsign.  Loading assigns a new string, so a reload after a country
  files update is a safe swap.

  Moved here from TdmData (LoadMasterSCP, GetSCPCalls) to be testable without
  LCL and MySQL.
  No LCL, no globals; see tests/tScpLookup.pas. }

unit uScpIndex;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TScpIndex = class
  private
    fData  : AnsiString;
    fCount : Integer;
  public
    //Lines in MASTER.SCP format: one call per line, '#' comments and the
    //'!!Order' header are skipped
    procedure LoadFromStrings(Lines : TStrings);
    procedure LoadFromFile(const FileName : String);
    //Clears Hits and fills it with every call containing Partial, in file
    //order, one hit per call.  Case sensitive.
    procedure Find(const Partial : String; Hits : TStrings);
    property Count : Integer read fCount;
  end;

implementation

procedure TScpIndex.LoadFromStrings(Lines : TStrings);
var
  Calls : TStringList;
  i   : Integer;
  tmp : String;
begin
  Calls := TStringList.Create;
  try
    Calls.Capacity := Lines.Count;
    for i:=0 to Lines.Count-1 do
    begin
      tmp := trim(Lines[i]);
      if tmp = '' then
        Continue;
      if (tmp[1]='#') or (tmp[1]='!') then //skip comments and the !!Order header
        Continue;
      Calls.Add(tmp)
    end;
    Calls.LineBreak := #10;
    fData  := #10 + Calls.Text; //Text ends with LineBreak
    fCount := Calls.Count
  finally
    Calls.Free
  end
end;

procedure TScpIndex.LoadFromFile(const FileName : String);
var
  Lines : TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FileName);
    LoadFromStrings(Lines)
  finally
    Lines.Free
  end
end;

procedure TScpIndex.Find(const Partial : String; Hits : TStrings);
var
  p, TokenStart, TokenEnd : SizeInt;
  Data : AnsiString;
begin
  Hits.Clear;
  Data := fData; //local reference, a reload in between doesn't pull the buffer away
  if (Partial = '') or (Data = '') or (Pos(#10,Partial) > 0) then
    exit;
  p := Pos(Partial,Data);
  while p > 0 do
  begin
    TokenStart := p;
    while (TokenStart > 1) and (Data[TokenStart-1] <> #10) do
      Dec(TokenStart);
    TokenEnd := p + Length(Partial);
    while (TokenEnd <= Length(Data)) and (Data[TokenEnd] <> #10) do
      Inc(TokenEnd);
    Hits.Add(Copy(Data,TokenStart,TokenEnd-TokenStart));
    p := Pos(Partial,Data,TokenEnd+1)
  end
end;

end.
