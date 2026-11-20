(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ One ADI data specifier (<TAG:len>data or <TAG>) from a piece of text.

  Moved here from TfrmAdifImport.getNextAdifTag to be testable without LCL and
  MySQL; ADIF import, LoTW download and New QSO all call it through that
  method.  No LCL, no globals; see tests/tAdifTag.pas. }

unit uAdifTag;

{$mode objfpc}{$H+}

interface

//Finds the next tag in Rest. Tag gets its name (without a trailing _INTL),
//Data its trimmed value, Rest what follows the value, '' when no other tag
//follows. False when Rest has no complete tag, Rest is then left as it was.
//The length is in bytes, for *_INTL tags in UTF-8 characters.
function NextAdifTag(var Rest, Tag, Data : String) : Boolean;

implementation

uses
  SysUtils;

//the first Count UTF-8 characters of S; LazUTF8.UTF8Copy without LazUtils
function Utf8Head(const S : String; Count : Integer) : String;
var
  i, n : Integer;
begin
  i := 1;
  n := 0;
  while (i <= Length(S)) and (n < Count) do
  begin
    Inc(i);
    //continuation bytes 10xxxxxx belong to the character just started
    while (i <= Length(S)) and ((Ord(S[i]) and $C0) = $80) do
      Inc(i);
    Inc(n)
  end;
  Result := Copy(S, 1, i-1)
end;

function NextAdifTag(var Rest, Tag, Data : String) : Boolean;
var
  z, x    : Integer;
  aaa     : String;
  i       : Integer;
  slen    : String = '';
  DataLen : Integer = 0;
  Intl    : Integer;
begin
  Result := False;
  z := Pos('<', Rest);
  if z = 0 then exit; //no other tag

  aaa := Copy(Rest, z+1, Length(Rest));
  x := Pos('>', aaa);
  if x = 0 then exit; //the tag is not terminated

  //a tag without a length (<EOR>, <EOH>) has no colon of its own; the colon of
  //the next tag on the same line must not count (#509: <EOR><CALL:4>... made
  //'EOR><CALL' and the records ran into one)
  z := Pos(':', aaa);
  if z > x then
    z := 0;

  //length of the data, the digits between the colon and '>'
  //(the type of <FREQ:6:N> is a letter)
  if z > 0 then
    for i := z+1 to x-1 do
      if aaa[i] in ['0'..'9'] then
        slen := slen + aaa[i];
  if slen <> '' then
    DataLen := StrToIntDef(slen, 0);

  if z > 0 then
    Tag := Trim(Copy(aaa, 1, z-1))
  else
    Tag := Trim(Copy(aaa, 1, x-1));

  aaa := Copy(aaa, x+1, Length(aaa));

  Intl := Pos('_INTL', UpperCase(Tag));
  if Intl > 0 then //tags with _INTL carry UTF-8, the length counts characters
  begin
    Tag  := Copy(Tag, 1, Intl-1);
    Data := Utf8Head(aaa, DataLen)
  end
  else
    Data := Copy(aaa, 1, DataLen);

  //the next tag is the next '<', so a wrong length in the file loses one
  //value, not the tags after it
  z := Pos('<', aaa);
  if z = 0 then
    Rest := ''
  else
    Rest := Copy(aaa, z, Length(aaa));

  Data := Trim(Data);
  Result := True
end;

end.
