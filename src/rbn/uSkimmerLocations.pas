(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Where the RBN skimmers stand: the locator of every skimmer node, from the
  HamQTH list (GET https://www.hamqth.com/api/v2/rbn/skimmers, HamQTH's copy of
  the reversebeacon.net node list, refreshed daily).  Without it a skimmer is
  placed by its callsign prefix, which puts many US skimmers in the wrong call
  area (WB6BEE in FM17, Virginia, drawn in California).

  Matched by node only, never by the home callsign: EA8/DF4UE stands on the
  Canaries and DF4UE-RP in Germany.  A node not in the list stays with the
  prefix.  No LCL, no network: the caller downloads the answer and keeps it in
  a file (docs/proposals/rbn-skimmer-locations.md). }

unit uSkimmerLocations;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  SKIMMER_LIST_URL = 'https://www.hamqth.com/api/v2/rbn/skimmers';

type
  TSkimmerLocations = class
  private
    FNodes   : TStringList;  //sorted nodes, Objects = index into FGrids
    FGrids   : TStringList;  //grids in the order the nodes came
    FUpdated : String;
    function GetCount : Integer;
  public
    constructor Create;
    destructor  Destroy; override;

    //replaces the list with the skimmers of a HamQTH answer; an answer that is
    //not JSON or has no usable skimmer leaves the list as it was
    function  LoadFromJson(const Json : String) : Boolean;
    function  LoadFromFile(const FileName : String) : Boolean;
    procedure Clear;

    //Spotter as RBN telnet sends it (KM3T-5-#) or the node itself (KM3T-5);
    //Grid is upper case, 4 or 6 characters
    function  Lookup(const Spotter : String; out Grid : String) : Boolean;

    property Count   : Integer read GetCount;
    property Updated : String  read FUpdated;  //'2026-11-20T04:30:12Z' as HamQTH sent it
  end;

//KM3T-5-# -> KM3T-5, ea8/df4ue-# -> EA8/DF4UE; a node stays as it is
function SkimmerNode(const Spotter : String) : String;
//AA00 or AA00AA, any case
function IsSkimmerGrid(const Grid : String) : Boolean;
//the file is missing or older than MaxAgeDays
function SkimmerListIsStale(const FileName : String; MaxAgeDays : Double) : Boolean;

implementation

uses
  fpjson, jsonparser;

function SkimmerNode(const Spotter : String) : String;
begin
  Result := UpperCase(Trim(Spotter));
  if (Length(Result) >= 2) and (Copy(Result, Length(Result)-1, 2) = '-#') then
    SetLength(Result, Length(Result)-2)
end;

function IsSkimmerGrid(const Grid : String) : Boolean;
var
  g : String;
begin
  g := UpperCase(Grid);
  Result := (Length(g) in [4, 6]) and
            (g[1] in ['A'..'R']) and (g[2] in ['A'..'R']) and
            (g[3] in ['0'..'9']) and (g[4] in ['0'..'9']);
  if Result and (Length(g) = 6) then
    Result := (g[5] in ['A'..'X']) and (g[6] in ['A'..'X'])
end;

function SkimmerListIsStale(const FileName : String; MaxAgeDays : Double) : Boolean;
var
  Age : LongInt;
begin
  Age := FileAge(FileName);
  Result := (Age = -1) or (Now - FileDateToDateTime(Age) > MaxAgeDays)
end;

constructor TSkimmerLocations.Create;
begin
  inherited Create;
  FNodes := TStringList.Create;
  FNodes.Sorted := True;
  FNodes.Duplicates := dupIgnore;
  FNodes.CaseSensitive := True;  //upper case already
  FGrids := TStringList.Create
end;

destructor TSkimmerLocations.Destroy;
begin
  FNodes.Free;
  FGrids.Free;
  inherited Destroy
end;

function TSkimmerLocations.GetCount : Integer;
begin
  Result := FNodes.Count
end;

procedure TSkimmerLocations.Clear;
begin
  FNodes.Clear;
  FGrids.Clear;
  FUpdated := ''
end;

function TSkimmerLocations.LoadFromJson(const Json : String) : Boolean;
var
  Data    : TJSONData = nil;
  List    : TJSONArray;
  Item    : TJSONObject;
  Nodes   : TStringList;
  Grids   : TStringList;
  Node    : String;
  Grid    : String;
  i       : Integer;
begin
  Result := False;
  try
    Data := GetJSON(Json)
  except
    on Exception do
      exit;  //not JSON (an error page, a cut download): EScannerError, EJSONParser
  end;
  Nodes := TStringList.Create;
  Grids := TStringList.Create;
  try
    Nodes.Sorted := True;
    Nodes.CaseSensitive := True;
    if not (Data is TJSONObject) then
      exit;
    if not (TJSONObject(Data).Find('skimmers', List)) then
      exit;
    for i := 0 to List.Count-1 do
    begin
      if not (List.Items[i] is TJSONObject) then
        Continue;
      Item := TJSONObject(List.Items[i]);
      Node := UpperCase(Trim(Item.Get('node', '')));
      Grid := UpperCase(Trim(Item.Get('grid', '')));
      if (Node = '') or (Pos(' ', Node) > 0) or (not IsSkimmerGrid(Grid)) or
         (Nodes.IndexOf(Node) >= 0) then  //a node twice: the first
        Continue;
      Nodes.AddObject(Node, TObject(PtrInt(Grids.Add(Grid))))
    end;
    if Nodes.Count = 0 then
      exit;
    FNodes.Assign(Nodes);
    FGrids.Assign(Grids);
    FUpdated := TJSONObject(Data).Get('updated', '');
    Result := True
  finally
    Nodes.Free;
    Grids.Free;
    Data.Free
  end
end;

function TSkimmerLocations.LoadFromFile(const FileName : String) : Boolean;
var
  s : TStringList;
begin
  Result := False;
  if not FileExists(FileName) then
    exit;
  s := TStringList.Create;
  try
    try
      s.LoadFromFile(FileName)
    except
      on EStreamError do
        exit;
    end;
    Result := LoadFromJson(s.Text)
  finally
    s.Free
  end
end;

function TSkimmerLocations.Lookup(const Spotter : String; out Grid : String) : Boolean;
var
  i : Integer;
begin
  Grid := '';
  Result := FNodes.Find(SkimmerNode(Spotter), i);
  if Result then
    Grid := FGrids[PtrInt(FNodes.Objects[i])]
end;

end.
