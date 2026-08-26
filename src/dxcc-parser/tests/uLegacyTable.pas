(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Adapter that wraps the legacy znacmech.Tseznam object behind IDxccTable.

  This exists so the characterisation tests can be written once and then run
  unchanged against both the legacy engine and the new one.  It is test-only
  scaffolding: nothing in src/ knows about it, and it disappears once the new
  implementation has replaced the old one. }

unit uLegacyTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uDxccTableIntf, znacmech;

type
  TLegacyTable = class(TInterfacedObject, IDxccTable)
  private
    FList: Pseznam;
    FErrors: Pchyby;
  public
    constructor Create(const FileName: string);
    destructor Destroy; override;

    function Count: Integer;
    function Find(const Callsign, ADate: string; Mode: TMatchMode): Integer;
    function Pattern(Index: Integer): string;
    function Field(Index, FieldNo: Integer): string;
    function IsValidOn(Index: Integer; const ADate: string): Boolean;
  end;

implementation

const
  { znacmech.c_pres_dlouhe / c_pres_kratke / c_pres_strikt }
  ModeToPresne: array[TMatchMode] of Integer =
    (c_pres_dlouhe, c_pres_kratke, c_pres_strikt);

constructor TLegacyTable.Create(const FileName: string);
begin
  inherited Create;
  FErrors := New(Pchyby, Init);
  FList   := New(Pseznam, Init(FileName, FErrors));
end;

destructor TLegacyTable.Destroy;
begin
  if FList <> nil then
    Dispose(FList, Done);
  if FErrors <> nil then
    Dispose(FErrors, Done);
  inherited Destroy;
end;

function TLegacyTable.Count: Integer;
begin
  { znacky_posledni is the index of the last entry, not a count. }
  Result := FList^.znacky_posledni + 1;
end;

function TLegacyTable.Find(const Callsign, ADate: string; Mode: TMatchMode): Integer;
var
  Call: string_mdz;
  Date: string_mdd;
begin
  { najdis_s2 takes a var parameter of exactly string[40], so the value has to
    be copied into a local of that type first.  The shortstring assignment is
    what performs the historical silent truncation. }
  Call := Callsign;
  Date := ADate;
  Result := FList^.najdis_s2(Call, Date, ModeToPresne[Mode]);
end;

function TLegacyTable.Pattern(Index: Integer): string;
begin
  Result := FList^.znacka_text(Index);
end;

function TLegacyTable.Field(Index, FieldNo: Integer): string;
begin
  Result := FList^.znacka_popis_ex(Index, FieldNo);
end;

function TLegacyTable.IsValidOn(Index: Integer; const ADate: string): Boolean;
var
  Date: string_mdd;
begin
  Date := ADate;
  Result := FList^.znacka_sedidatum(Index, Date);
end;

end.
