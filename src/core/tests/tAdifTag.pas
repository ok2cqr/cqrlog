(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ ADI tag tokenizer (uAdifTag.NextAdifTag), the part of ADIF import that splits
  a line into tags.  The import calls it in a loop until it returns False and
  saves the record on EOR. }

unit tAdifTag;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uAdifTag;

type
  TAdifTagTest = class(TTestCase)
  private
    //all tags of S as TAG=data, one per line
    function Tags(const S : String) : String;
  published
    procedure OneTag;
    procedure TagNamesAreTrimmed;
    procedure DataIsTrimmed;
    procedure TypeIndicator;
    procedure EorAtEndOfLine;
    procedure RecordsOnOneLine;
    procedure EohFollowedByRecord;
    procedure TextBetweenTagsIgnored;
    procedure LengthLongerThanData;
    procedure ZeroLength;
    procedure UnterminatedTag;
    procedure NoTag;
    procedure IntlCountsCharacters;
    procedure PlainTagCountsBytes;
  end;

implementation

function TAdifTagTest.Tags(const S : String) : String;
var
  Rest, Tag, Data : String;
begin
  Result := '';
  Rest := S;
  while NextAdifTag(Rest, Tag, Data) do
    Result := Result + Tag + '=' + Data + LineEnding
end;

procedure TAdifTagTest.OneTag;
var
  Rest, Tag, Data : String;
begin
  Rest := '<CALL:5>OK2CQR';
  AssertTrue(NextAdifTag(Rest, Tag, Data));
  AssertEquals('CALL', Tag);
  AssertEquals('OK2CQ', Data);
  AssertEquals('', Rest)
end;

procedure TAdifTagTest.TagNamesAreTrimmed;
begin
  AssertEquals('CALL=OK2CQR' + LineEnding, Tags('< CALL :6>OK2CQR'))
end;

procedure TAdifTagTest.DataIsTrimmed;
begin
  AssertEquals('NAME=Petr' + LineEnding, Tags('<NAME:6> Petr '))
end;

procedure TAdifTagTest.TypeIndicator;
begin
  AssertEquals('FREQ=14.025' + LineEnding, Tags('<FREQ:6:N>14.025'))
end;

procedure TAdifTagTest.EorAtEndOfLine;
begin
  AssertEquals('CALL=OK2CQR' + LineEnding + 'EOR=' + LineEnding,
               Tags('<CALL:6>OK2CQR <EOR>'))
end;

//#509: <EOR> followed by the next record on the same line
procedure TAdifTagTest.RecordsOnOneLine;
begin
  AssertEquals('CALL=OK2CQR' + LineEnding + 'MODE=CW' + LineEnding + 'EOR=' + LineEnding +
               'CALL=OH1KH' + LineEnding + 'MODE=SSB' + LineEnding + 'eor=' + LineEnding,
               Tags('<CALL:6>OK2CQR<MODE:2>CW<EOR><CALL:5>OH1KH<MODE:3>SSB<eor>'))
end;

procedure TAdifTagTest.EohFollowedByRecord;
begin
  AssertEquals('ADIF_VER=3.1.4' + LineEnding + 'EOH=' + LineEnding + 'CALL=OK2CQR' + LineEnding,
               Tags('Export<ADIF_VER:5>3.1.4 <EOH> <CALL:6>OK2CQR'))
end;

procedure TAdifTagTest.TextBetweenTagsIgnored;
begin
  AssertEquals('CALL=OK2CQR' + LineEnding + 'BAND=20M' + LineEnding,
               Tags('<CALL:6>OK2CQR comment here <BAND:3>20M'))
end;

//a length too long for the data must not swallow the next tag
procedure TAdifTagTest.LengthLongerThanData;
begin
  AssertEquals('CALL=OK2CQR <BA' + LineEnding + 'BAND=20M' + LineEnding,
               Tags('<CALL:10>OK2CQR <BAND:3>20M'))
end;

procedure TAdifTagTest.ZeroLength;
begin
  AssertEquals('COMMENT=' + LineEnding + 'CALL=OK2CQR' + LineEnding,
               Tags('<COMMENT:0><CALL:6>OK2CQR'))
end;

procedure TAdifTagTest.UnterminatedTag;
var
  Rest, Tag, Data : String;
begin
  Rest := '<CALL:6';
  AssertFalse(NextAdifTag(Rest, Tag, Data));
  AssertEquals('<CALL:6', Rest)
end;

procedure TAdifTagTest.NoTag;
var
  Rest, Tag, Data : String;
begin
  Rest := 'just text';
  AssertFalse(NextAdifTag(Rest, Tag, Data))
end;

procedure TAdifTagTest.IntlCountsCharacters;
begin
  //Němec is 5 characters, 6 bytes
  AssertEquals('NAME=Němec' + LineEnding + 'CALL=OK1RR' + LineEnding,
               Tags('<NAME_INTL:5>Němec<CALL:5>OK1RR'))
end;

procedure TAdifTagTest.PlainTagCountsBytes;
begin
  AssertEquals('NAME=Něm' + LineEnding, Tags('<NAME:4>Němec'))
end;

initialization
  RegisterTest(TAdifTagTest);
end.
