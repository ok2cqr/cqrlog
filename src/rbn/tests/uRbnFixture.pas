(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Reads a tools/rbn-capture recording: one JSON object per line, one line per
  TCP read, {"t": seconds, "data": "bytes of that read"}.  Test-only. }

unit uRbnFixture;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

function FixturePath(const Name : String) : String;
//the reads of a recording, in order, one per item
function LoadReads(const Name : String) : TStringList;

implementation

uses
  fpjson, jsonparser;

function FixturePath(const Name : String) : String;
begin
  //make test runs from src/rbn, the binary sits in src/rbn/tests
  Result := ExtractFilePath(ParamStr(0)) + 'data' + PathDelim + Name
end;

function LoadReads(const Name : String) : TStringList;
var
  Raw  : TStringList;
  i    : Integer;
  Data : TJSONData;
begin
  Result := TStringList.Create;
  Raw := TStringList.Create;
  try
    Raw.LoadFromFile(FixturePath(Name));
    for i := 0 to Raw.Count-1 do
    begin
      if Trim(Raw[i]) = '' then
        Continue;
      Data := GetJSON(Raw[i]);
      try
        Result.Add(TJSONObject(Data).Strings['data'])
      finally
        Data.Free
      end
    end
  finally
    Raw.Free
  end
end;

end.
