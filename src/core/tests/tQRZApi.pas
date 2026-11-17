(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ QRZ.com XML interface 1.34.  The responses are the examples of the
  specification (https://www.qrz.com/docs/xml/current_spec.html); the
  expected callbook values are what TdmUtils.GetQRZInfo made of the same
  data before the parsing moved here. }

unit tQRZApi;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, uQRZApi;

type
  TQRZApiTest = class(TTestCase)
  published
    procedure LoginUrlIsEncoded;
    procedure LookupUrl;
    procedure LoginResponse;
    procedure LoginError;
    procedure CallbookRecord;
    procedure NicknameAndAttention;
    procedure EntitiesAndUtf8;
    procedure NotFound;
    procedure SessionTimeout;
    procedure UnknownNodesIgnored;
    procedure NotQrzXml;
  end;

implementation

const
  LOGIN_OK =
    '<?xml version="1.0" ?>' +
    '<QRZDatabase version="1.34" xmlns="http://xmldata.qrz.com">' +
    '<Session>' +
    '<Key>2331uf894c4bd29f3923f3bacf02c532d7bd9</Key>' +
    '<Count>123</Count>' +
    '<SubExp>Wed Jan 1 12:34:03 2013</SubExp>' +
    '<GMTime>Sun Aug 16 03:51:47 2012</GMTime>' +
    '</Session>' +
    '</QRZDatabase>';

  AA7BQ =
    '<?xml version="1.0" ?>' +
    '<QRZDatabase version="1.34">' +
    '<Callsign>' +
    '<call>AA7BQ</call>' +
    '<aliases>N6UFT,KJ6RK,DL/AA7BQ</aliases>' +
    '<dxcc>291</dxcc>' +
    '<fname>FRED L</fname>' +
    '<name>LLOYD</name>' +
    '<addr1>8711 E PINNACLE PEAK RD 193</addr1>' +
    '<addr2>SCOTTSDALE</addr2>' +
    '<state>AZ</state>' +
    '<zip>85255</zip>' +
    '<country>United States</country>' +
    '<ccode>291</ccode>' +
    '<lat>34.23456</lat>' +
    '<lon>-112.34356</lon>' +
    '<grid>DM32af</grid>' +
    '<county>Maricopa</county>' +
    '<qslmgr>NONE</qslmgr>' +
    '<cqzone>3</cqzone>' +
    '<ituzone>2</ituzone>' +
    '<geoloc>user</geoloc>' +
    '%s' +
    '<born>1953</born>' +
    '</Callsign>' +
    '<Session>' +
    '<Key>2331uf894c4bd29f3923f3bacf02c532d7bd9</Key>' +
    '<Count>123</Count>' +
    '<SubExp>Wed Jan 1 12:34:03 2013</SubExp>' +
    '<GMTime>Sun Nov 16 04:13:46 2012</GMTime>' +
    '</Session>' +
    '</QRZDatabase>';

procedure TQRZApiTest.LoginUrlIsEncoded;
begin
  AssertEquals('https://xmldata.qrz.com/xml/1.34/?username=ok2cqr&password=a%26b%3Bc%2B%23%20d&agent=Cqrlog_3.3.0_QT6',
    QRZLoginUrl('ok2cqr', 'a&b;c+# d', 'Cqrlog_3.3.0_QT6'))
end;

procedure TQRZApiTest.LookupUrl;
begin
  AssertEquals('https://xmldata.qrz.com/xml/1.34/?s=f894c4bd&callsign=DL%2FAA7BQ',
    QRZLookupUrl('f894c4bd', 'DL/AA7BQ'))
end;

procedure TQRZApiTest.LoginResponse;
var
  s : TQRZSession;
  i : TQRZCallbook;
begin
  AssertTrue(ParseQRZResponse(LOGIN_OK, s, i));
  AssertEquals('2331uf894c4bd29f3923f3bacf02c532d7bd9', s.Key);
  AssertEquals('', s.Error);
  AssertEquals('Wed Jan 1 12:34:03 2013', s.SubExp);
  AssertFalse(i.Found)
end;

procedure TQRZApiTest.LoginError;
var
  s : TQRZSession;
  i : TQRZCallbook;
begin
  AssertTrue(ParseQRZResponse('<?xml version="1.0" ?><QRZDatabase version="1.34"><Session>' +
    '<Error>Username/password incorrect </Error><GMTime>Sun Nov 16 05:11:58 2003</GMTime>' +
    '</Session></QRZDatabase>', s, i));
  AssertEquals('', s.Key);
  AssertEquals('Username/password incorrect', s.Error)
end;

procedure TQRZApiTest.CallbookRecord;
var
  s : TQRZSession;
  i : TQRZCallbook;
begin
  AssertTrue(ParseQRZResponse(Format(AA7BQ, ['']), s, i));
  AssertTrue(i.Found);
  AssertEquals('2331uf894c4bd29f3923f3bacf02c532d7bd9', s.Key);
  AssertEquals('Fred', i.nick);
  AssertEquals('SCOTTSDALE', i.qth);
  AssertEquals('AZ', i.state);
  AssertEquals('85255', i.zip);
  AssertEquals('Maricopa', i.county);
  AssertEquals('DM32AF', i.grid);
  AssertEquals('NONE', i.qsl);
  AssertEquals('', i.iota);
  AssertEquals('3', i.waz);
  AssertEquals('2', i.itu);
  AssertEquals('FRED L LLOYD' + LineEnding + '8711 E PINNACLE PEAK RD 193' + LineEnding +
    'SCOTTSDALE, AZ 85255', i.address)
end;

procedure TQRZApiTest.NicknameAndAttention;
var
  s : TQRZSession;
  i : TQRZCallbook;
begin
  AssertTrue(ParseQRZResponse(Format(AA7BQ, ['<attn>c/o QRZ LLC</attn><nickname>The Boss</nickname>' +
    '<name_fmt>FRED "The Boss" LLOYD</name_fmt>']), s, i));
  AssertEquals('The Boss', i.nick);
  AssertEquals('FRED L LLOYD' + LineEnding + 'c/o QRZ LLC' + LineEnding +
    '8711 E PINNACLE PEAK RD 193' + LineEnding + 'SCOTTSDALE, AZ 85255', i.address)
end;

procedure TQRZApiTest.EntitiesAndUtf8;
var
  s : TQRZSession;
  i : TQRZCallbook;
begin
  AssertTrue(ParseQRZResponse('<?xml version="1.0" ?><QRZDatabase version="1.34"><Callsign>' +
    '<call>OK2CQR</call><fname>Petr</fname><name>Hlo'#$C5#$BE'ek</name>' +
    '<addr1>Sm&amp;th &lt;1&gt;</addr1><addr2>'#$C4#$8C'esk'#$C3#$A9' Bud'#$C4#$9B'jovice</addr2>' +
    '</Callsign><Session><Key>k</Key></Session></QRZDatabase>', s, i));
  AssertEquals('Petr', i.nick);
  AssertEquals(#$C4#$8C'esk'#$C3#$A9' Bud'#$C4#$9B'jovice', i.qth);
  AssertEquals('Petr Hlo'#$C5#$BE'ek' + LineEnding + 'Sm&th <1>' + LineEnding +
    #$C4#$8C'esk'#$C3#$A9' Bud'#$C4#$9B'jovice ', i.address)
end;

procedure TQRZApiTest.NotFound;
var
  s : TQRZSession;
  i : TQRZCallbook;
begin
  AssertTrue(ParseQRZResponse('<?xml version="1.0" ?><QRZDatabase version="1.34"><Session>' +
    '<Error>Not found: g1srdd</Error><Key>1232u4eaf13b8336d61982c1fd1099c9a38ac</Key>' +
    '<GMTime>Sun Nov 16 05:07:14 2003</GMTime></Session></QRZDatabase>', s, i));
  AssertFalse(i.Found);
  AssertEquals('1232u4eaf13b8336d61982c1fd1099c9a38ac', s.Key);
  AssertTrue(IsQRZNotFound(s.Error));
  AssertFalse(IsQRZNotFound('Session Timeout'))
end;

procedure TQRZApiTest.SessionTimeout;
var
  s : TQRZSession;
  i : TQRZCallbook;
begin
  AssertTrue(ParseQRZResponse('<?xml version="1.0" ?><QRZDatabase version="1.34"><Session>' +
    '<Error>Session Timeout</Error><GMTime>Sun Nov 16 05:11:58 2003</GMTime>' +
    '</Session></QRZDatabase>', s, i));
  AssertEquals('', s.Key);
  AssertEquals('Session Timeout', s.Error)
end;

procedure TQRZApiTest.UnknownNodesIgnored;
var
  s : TQRZSession;
  i : TQRZCallbook;
begin
  //new nodes and attributes may come any time, in any order
  AssertTrue(ParseQRZResponse('<?xml version="1.0" ?><QRZDatabase version="9.99" extra="1">' +
    '<Session><Key>k</Key><Message>A subscription is required to access the complete record.</Message></Session>' +
    '<Future><name>not this</name></Future>' +
    '<Callsign new="x"><grid>jo70</grid><name_fmt>X</name_fmt><fname>JAN</fname><name>NOVAK</name></Callsign>' +
    '</QRZDatabase>', s, i));
  AssertEquals('k', s.Key);
  AssertEquals('A subscription is required to access the complete record.', s.Message);
  AssertEquals('JO70', i.grid);
  AssertEquals('Jan', i.nick);
  AssertEquals('JAN NOVAK' + LineEnding + LineEnding + ' ', i.address)
end;

procedure TQRZApiTest.NotQrzXml;
var
  s : TQRZSession;
  i : TQRZCallbook;
begin
  AssertFalse(ParseQRZResponse('', s, i));
  AssertFalse(ParseQRZResponse('<html><body>502 Bad Gateway</body></html>', s, i));
  AssertFalse(ParseQRZResponse('<html><body>broken', s, i));
  AssertEquals('', s.Key)
end;

initialization
  RegisterTest(TQRZApiTest);

end.
