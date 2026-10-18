(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ HamQTH API v2 responses.  The spot list is a recorded response of
  /api/v2/spots, the callbook record follows the CallbookRecord schema of
  /api/v2/openapi.json.  The expected callbook values are what
  TdmUtils.GetHamQTHInfo made of the same data from the v1 xml.php. }

unit tHamQTHApi;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fpjson, jsonparser, uHamQTHApi;

type
  THamQTHApiTest = class(TTestCase)
  published
    procedure LoginRequestEscapesPassword;
    procedure LoginToken;
    procedure LoginWithoutToken;
    procedure ErrorTextFromProblem;
    procedure ErrorTextWithoutProblem;
    procedure CallbookRecord;
    procedure CallbookUsStation;
    procedure CallbookNullsAreEmpty;
    procedure CallbookInvalidJson;
    procedure SpotList;
    procedure SpotListEmpty;
    procedure SpotListInvalidJson;
    procedure ErrorTextWithViolations;
    procedure QsoRequestFromAdif;
    procedure QsoRequestTypedAndRepeatedFields;
    procedure QsoRequestTruncatedAdif;
    procedure QsoKeyQueryIsEncoded;
    procedure QsoResultStored;
    procedure QsoResultAlreadyInLog;
    procedure QsoResultNotInLog;
    procedure QsoResultRejected;
    procedure QsoResultFatal;
  end;

implementation

const
  C_CALLBOOK =
    '{"callsign":"DL1ABC","nick":"HANS peter","name":"Hans Peter Muller",' +
    '"qth":"Kassel","dxcc":230,"country":"Germany","continent":"EU","cq":14,' +
    '"itu":28,"utcOffset":1,' +
    '"location":{"lat":51.3,"lon":9.5,"grid":"jo41ah"},' +
    '"address":{"name":"Hans Muller","street":["Hauptstr. 1","Hinterhaus",""],' +
    '"city":"Kassel","zip":"34117","country":"Germany","dxcc":230},' +
    '"region":{"district":null,"usState":null,"usCounty":null,"oblast":null,"dok":"f-24"},' +
    '"iota":null,"qsl":{"via":"DL9XYZ","bureau":true,"direct":true,"lotw":true,"eqsl":false},' +
    '"email":null,"birthYear":null,"licensedSince":null,"links":{},"picture":null,' +
    '"profile":"https://www.hamqth.com/dl1abc"}';

  C_CALLBOOK_US =
    '{"callsign":"W1AW","nick":"Hiram","qth":"Newington","cq":5,"itu":8,' +
    '"location":{"grid":"FN31pr"},' +
    '"address":{"name":"ARRL","street":["225 Main St"],"city":"Newington","zip":"06111"},' +
    '"region":{"usState":"CT","usCounty":"Hartford"},"iota":"NA-001",' +
    '"qsl":{"via":null},"links":{}}';

  C_CALLBOOK_NULLS =
    '{"callsign":"OK1XX","nick":null,"qth":null,"cq":null,"itu":null,' +
    '"location":{},"address":{"street":[]},"region":{},"qsl":{},"links":{}}';

  C_SPOTS =
    '{"spots":[{"spotter":"6Y5PW","dxcall":"DD2ML","freq":28429.0,"band":"10M",' +
    '"mode":"SSB","comment":"","time":"2026-10-17T16:35:00Z","dxcc":230,' +
    '"country":"Germany","continent":"EU","lotw":true,"eqsl":true},' +
    '{"spotter":"EC1DJ","dxcall":"EA2EZ","freq":14348.0,"band":"20M","mode":"SSB",' +
    '"comment":"CQ POTA es2355 & es184","time":"2026-10-17T16:34:00Z",' +
    '"dxcc":281,"country":"Spain","continent":"EU","lotw":false,"eqsl":true},' +
    '{"spotter":"K0ZR","dxcall":"DL5JS","freq":21025.5,"band":"15M","mode":null,' +
    '"comment":"","time":"2026-10-17T09:04:00Z","dxcc":230,"country":"Germany",' +
    '"continent":"EU","lotw":true,"eqsl":false}]}';

procedure THamQTHApiTest.LoginRequestEscapesPassword;
var
  d : TJSONData;
begin
  d := GetJSON(HamQTHLoginRequest('OK2CQR', 'pa"ss\word'));
  try
    AssertEquals('OK2CQR', d.FindPath('callsign').AsString);
    AssertEquals('pa"ss\word', d.FindPath('password').AsString)
  finally
    d.Free
  end
end;

procedure THamQTHApiTest.LoginToken;
var
  Token : String;
begin
  AssertTrue(ParseHamQTHLogin('{"token":"4f9c0de21a","expiresIn":3600}', Token));
  AssertEquals('4f9c0de21a', Token)
end;

procedure THamQTHApiTest.LoginWithoutToken;
var
  Token : String;
begin
  AssertFalse(ParseHamQTHLogin('{"expiresIn":3600}', Token));
  AssertFalse(ParseHamQTHLogin('{"token":null}', Token));
  AssertFalse(ParseHamQTHLogin('<html>Bad gateway</html>', Token));
  AssertEquals('', Token)
end;

procedure THamQTHApiTest.ErrorTextFromProblem;
begin
  AssertEquals('Callsign ZZ9ZZZ not found.',
    HamQTHErrorText(404, 'Not Found',
      '{"type":"about:blank","title":"Not Found","status":404,"detail":"Callsign ZZ9ZZZ not found."}'));
  AssertEquals('Unauthorized',
    HamQTHErrorText(401, 'Unauthorized', '{"title":"Unauthorized","status":401}'))
end;

procedure THamQTHApiTest.ErrorTextWithoutProblem;
begin
  AssertEquals('(502):Bad Gateway', HamQTHErrorText(502, 'Bad Gateway', '<html>nginx</html>'));
  AssertEquals('(500):Internal Server Error', HamQTHErrorText(500, 'Internal Server Error', ''))
end;

procedure THamQTHApiTest.CallbookRecord;
var
  Info : THamQTHCallbook;
begin
  AssertTrue(ParseHamQTHCallbook(C_CALLBOOK, Info));
  AssertEquals('Hans', Info.nick);
  AssertEquals('Kassel', Info.qth);
  AssertEquals('Hans Muller' + LineEnding + 'Hauptstr. 1' + LineEnding + 'Hinterhaus' +
    LineEnding + 'Kassel 34117', Info.address);
  AssertEquals('34117', Info.zip);
  AssertEquals('JO41AH', Info.grid);
  AssertEquals('', Info.state);
  AssertEquals('', Info.county);
  AssertEquals('DL9XYZ', Info.qsl);
  AssertEquals('', Info.iota);
  AssertEquals('14', Info.waz);
  AssertEquals('28', Info.itu);
  AssertEquals('F24', Info.dok)
end;

procedure THamQTHApiTest.CallbookUsStation;
var
  Info : THamQTHCallbook;
begin
  AssertTrue(ParseHamQTHCallbook(C_CALLBOOK_US, Info));
  AssertEquals('ARRL' + LineEnding + '225 Main St' + LineEnding + 'Newington, CT 06111',
    Info.address);
  AssertEquals('CT', Info.state);
  AssertEquals('Hartford', Info.county);
  AssertEquals('NA-001', Info.iota);
  AssertEquals('', Info.qsl);
  AssertEquals('FN31PR', Info.grid)
end;

procedure THamQTHApiTest.CallbookNullsAreEmpty;
var
  Info : THamQTHCallbook;
begin
  AssertTrue(ParseHamQTHCallbook(C_CALLBOOK_NULLS, Info));
  AssertEquals('', Info.nick);
  AssertEquals('', Info.qth);
  AssertEquals(LineEnding + LineEnding + ' ', Info.address);
  AssertEquals('', Info.waz);
  AssertEquals('', Info.itu);
  AssertEquals('', Info.grid);
  AssertEquals('', Info.dok)
end;

procedure THamQTHApiTest.CallbookInvalidJson;
var
  Info : THamQTHCallbook;
begin
  AssertFalse(ParseHamQTHCallbook('<HamQTH><session><error>x</error></session></HamQTH>', Info));
  AssertFalse(ParseHamQTHCallbook('[1,2]', Info));
  AssertFalse(ParseHamQTHCallbook('', Info))
end;

procedure THamQTHApiTest.SpotList;
var
  Spots : THamQTHSpots;
begin
  AssertTrue(ParseHamQTHSpots(C_SPOTS, Spots));
  AssertEquals(3, Length(Spots));
  AssertEquals('6Y5PW', Spots[0].spotter);
  AssertEquals('28429.0', Spots[0].freq);
  AssertEquals('DD2ML', Spots[0].dxcall);
  AssertEquals('', Spots[0].comment);
  AssertEquals('1635', Spots[0].time);
  AssertEquals('CQ POTA es2355 & es184', Spots[1].comment);
  AssertEquals('21025.5', Spots[2].freq);
  AssertEquals('0904', Spots[2].time)
end;

procedure THamQTHApiTest.SpotListEmpty;
var
  Spots : THamQTHSpots;
begin
  AssertTrue(ParseHamQTHSpots('{"spots":[]}', Spots));
  AssertEquals(0, Length(Spots))
end;

procedure THamQTHApiTest.SpotListInvalidJson;
var
  Spots : THamQTHSpots;
begin
  AssertFalse(ParseHamQTHSpots('S53M^14235.8^LB6WI^wag^1635 2026-10-17', Spots));
  AssertFalse(ParseHamQTHSpots('{"detail":"Too many requests"}', Spots));
  AssertEquals(0, Length(Spots))
end;

procedure THamQTHApiTest.ErrorTextWithViolations;
begin
  AssertEquals('Invalid field (qso.band: unknown band; qso.time_on: HHMM expected)',
    HamQTHErrorText(422, 'Unprocessable Entity',
      '{"title":"Unprocessable Entity","status":422,"detail":"Invalid field",' +
      '"violations":[{"propertyPath":"qso.band","title":"unknown band"},' +
      '{"propertyPath":"qso.time_on","title":"HHMM expected"}]}'))
end;

//what TdmLogUpload.PrepareInsertHeader sends, lengths in bytes (Jiří = 6)
procedure THamQTHApiTest.QsoRequestFromAdif;
var
  d : TJSONData;
begin
  d := GetJSON(HamQTHQsoRequest('<QSO_DATE:8>20261018<TIME_ON:4>1203<CALL:6>OK1ABC' +
    '<BAND:3>20M<MODE:2>CW<FREQ:6>14.025<TIME_OFF:4>1205<NAME:6>Jiří' +
    '<COMMENT:9>a<b>"c":d<EOR>'));
  try
    AssertEquals(9, TJSONObject(d.FindPath('qso')).Count);
    AssertEquals('20261018', d.FindPath('qso.qso_date').AsString);
    AssertEquals('1203', d.FindPath('qso.time_on').AsString);
    AssertEquals('OK1ABC', d.FindPath('qso.call').AsString);
    AssertEquals('20M', d.FindPath('qso.band').AsString);
    AssertEquals('CW', d.FindPath('qso.mode').AsString);
    AssertEquals('14.025', d.FindPath('qso.freq').AsString);
    AssertEquals('Jiří', d.FindPath('qso.name').AsString);
    AssertEquals('a<b>"c":d', d.FindPath('qso.comment').AsString);
    AssertNull(d.FindPath('qso.eor'));
    AssertNull(d.FindPath('callsign'))
  finally
    d.Free
  end
end;

procedure THamQTHApiTest.QsoRequestTypedAndRepeatedFields;
var
  d : TJSONData;
begin
  d := GetJSON(HamQTHQsoRequest('<qso_date:8:d>20261018<CALL:5>OK1AA<CALL:5>OK1BB<eor>'));
  try
    AssertEquals('20261018', d.FindPath('qso.qso_date').AsString);
    AssertEquals('OK1BB', d.FindPath('qso.call').AsString);
    AssertEquals(2, TJSONObject(d.FindPath('qso')).Count)
  finally
    d.Free
  end
end;

procedure THamQTHApiTest.QsoRequestTruncatedAdif;
var
  d : TJSONData;
begin
  d := GetJSON(HamQTHQsoRequest('<CALL:5>OK1AA<EOH><NAME:x>Petr<QTH:10>Brno'));
  try
    AssertEquals('OK1AA', d.FindPath('qso.call').AsString);
    AssertEquals('Brno', d.FindPath('qso.qth').AsString);
    AssertEquals(2, TJSONObject(d.FindPath('qso')).Count)
  finally
    d.Free
  end
end;

procedure THamQTHApiTest.QsoKeyQueryIsEncoded;
begin
  AssertEquals('call=OK1ABC%2FP&qso_date=20261018&time_on=1203&band=70CM&mode=SSB',
    HamQTHQsoKeyQuery('OK1ABC/P', '20261018', '1203', '70CM', 'SSB'))
end;

procedure THamQTHApiTest.QsoResultStored;
var
  ErrorCode : Integer;
begin
  AssertEquals('OK', HamQTHQsoResult(201, '{"call":"OK1ABC","dxcc":503}', ErrorCode));
  AssertEquals(0, ErrorCode);
  AssertEquals('OK', HamQTHQsoResult(204, '', ErrorCode));
  AssertEquals(0, ErrorCode)
end;

procedure THamQTHApiTest.QsoResultAlreadyInLog;
var
  ErrorCode : Integer;
begin
  AssertEquals('Already exists',
    HamQTHQsoResult(409, '{"status":409,"detail":"The QSO is in the log already."}', ErrorCode));
  AssertEquals(0, ErrorCode)
end;

procedure THamQTHApiTest.QsoResultNotInLog;
var
  ErrorCode : Integer;
begin
  AssertEquals('The QSO is not in the log.',
    HamQTHQsoResult(404, '{"status":404,"detail":"The QSO is not in the log."}', ErrorCode));
  AssertEquals(0, ErrorCode)
end;

procedure THamQTHApiTest.QsoResultRejected;
var
  ErrorCode : Integer;
begin
  AssertEquals('Invalid field (qso.band: unknown band)',
    HamQTHQsoResult(422, '{"status":422,"detail":"Invalid field",' +
      '"violations":[{"propertyPath":"qso.band","title":"unknown band"}]}', ErrorCode));
  AssertEquals(2, ErrorCode)
end;

procedure THamQTHApiTest.QsoResultFatal;
var
  ErrorCode : Integer;
begin
  AssertEquals('Wrong callsign or password.',
    HamQTHQsoResult(401, '{"status":401,"detail":"Wrong callsign or password."}', ErrorCode));
  AssertEquals(1, ErrorCode);
  AssertEquals('The DXCC service is down for a moment.',
    HamQTHQsoResult(503, '{"status":503,"detail":"The DXCC service is down for a moment."}', ErrorCode));
  AssertEquals(1, ErrorCode);
  AssertEquals('(502):Unexpected response from HamQTH',
    HamQTHQsoResult(502, '<html>Bad gateway</html>', ErrorCode));
  AssertEquals(1, ErrorCode)
end;

initialization
  RegisterTest(THamQTHApiTest)
end.
