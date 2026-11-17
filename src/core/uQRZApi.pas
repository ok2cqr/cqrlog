(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ QRZ.com XML Logbook Data interface, version 1.34
  (https://www.qrz.com/docs/xml/current_spec.html): request URLs and
  response parsing for the login and the callsign lookup.

  The HTTP calls, the cached session key and logging in again are kept by
  TdmUtils (GetQRZSession, GetQRZInfo), this unit only builds the URLs and
  turns the XML into the strings CQRLOG has always used.
  No LCL, no globals; see tests/tQRZApi.pas. }

unit uQRZApi;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DOM, XMLRead;

const
  //versioned end point, the trailing slash is "highly recommended"
  C_QRZ_API = 'https://xmldata.qrz.com/xml/1.34/';
  //service refused for the user, a login will not succeed for at least 24 hours
  C_QRZ_REFUSED = 'Connection refused';

type
  //<Session> node; no Key = no valid session, log in again
  TQRZSession = record
    Key, Error, Message, SubExp : String;
  end;

  TQRZCallbook = record
    Found : Boolean; //the response had a <Callsign> node
    nick, qth, address, zip, grid, state, county, qsl, iota, waz, itu : String;
  end;

function QRZLoginUrl(const UserName, Password, Agent : String) : String;
function QRZLookupUrl(const SessionKey, Callsign : String) : String;
//False when the response is not QRZ XML at all (HTML error page of a proxy, ...)
function ParseQRZResponse(const Xml : String; out Session : TQRZSession;
  out Info : TQRZCallbook) : Boolean;
//"Not found: OK2XYZ"
function IsQRZNotFound(const Error : String) : Boolean;

implementation

function UrlEncode(const s : String) : String;
var
  c : Char;
begin
  Result := '';
  for c in s do
    if c in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~'] then
      Result := Result + c
    else
      Result := Result + '%' + IntToHex(Ord(c), 2)
end;

function QRZLoginUrl(const UserName, Password, Agent : String) : String;
begin
  Result := C_QRZ_API + '?username=' + UrlEncode(UserName) + '&password=' +
    UrlEncode(Password) + '&agent=' + UrlEncode(Agent)
end;

function QRZLookupUrl(const SessionKey, Callsign : String) : String;
begin
  Result := C_QRZ_API + '?s=' + UrlEncode(SessionKey) + '&callsign=' + UrlEncode(Callsign)
end;

function IsQRZNotFound(const Error : String) : Boolean;
begin
  Result := Pos('not found', LowerCase(Error)) = 1
end;

//first child element called Name, nodes QRZ may add later are ignored
function FindChild(Parent : TDOMNode; const Name : String) : TDOMNode;
begin
  Result := nil;
  if Parent = nil then exit;
  Result := Parent.FirstChild;
  while (Result <> nil) and not ((Result.NodeType = ELEMENT_NODE) and
    (UTF8Encode(Result.NodeName) = Name)) do
    Result := Result.NextSibling
end;

function ChildText(Parent : TDOMNode; const Name : String) : String;
var
  n : TDOMNode;
begin
  n := FindChild(Parent, Name);
  if n = nil then
    Result := ''
  else
    Result := Trim(UTF8Encode(n.TextContent))
end;

//"FRED L" -> "Fred"
function FirstName(const FName : String) : String;
begin
  Result := Trim(FName);
  if Pos(' ', Result) > 0 then
    Result := Copy(Result, 1, Pos(' ', Result) - 1);
  if Result <> '' then
  begin
    Result := LowerCase(Result);
    Result[1] := UpCase(Result[1])
  end
end;

procedure ParseCallsign(Node : TDOMNode; out Info : TQRZCallbook);
var
  attn, addr1 : String;
begin
  Info := Default(TQRZCallbook);
  Info.Found := True;
  //nickname (1.34) is the name used on the air, the first name otherwise
  Info.nick := ChildText(Node, 'nickname');
  if Info.nick = '' then
    Info.nick := FirstName(ChildText(Node, 'fname'));
  Info.qth    := ChildText(Node, 'addr2');
  Info.state  := ChildText(Node, 'state');
  Info.zip    := ChildText(Node, 'zip');
  Info.county := ChildText(Node, 'county');
  Info.grid   := UpperCase(ChildText(Node, 'grid'));
  Info.qsl    := ChildText(Node, 'qslmgr');
  Info.iota   := ChildText(Node, 'iota');
  Info.waz    := ChildText(Node, 'cqzone');
  Info.itu    := ChildText(Node, 'ituzone');

  //name, attention line (1.34, "should be prepended to the address"),
  //street, city, state and zip
  Info.address := Trim(ChildText(Node, 'fname') + ' ' + ChildText(Node, 'name')) + LineEnding;
  attn := ChildText(Node, 'attn');
  if attn <> '' then
    Info.address := Info.address + attn + LineEnding;
  addr1 := ChildText(Node, 'addr1');
  Info.address := Info.address + addr1 + LineEnding + Info.qth;
  if Info.state <> '' then
    Info.address := Info.address + ', ' + Info.state;
  Info.address := Info.address + ' ' + Info.zip
end;

function ParseQRZResponse(const Xml : String; out Session : TQRZSession;
  out Info : TQRZCallbook) : Boolean;
var
  doc  : TXMLDocument;
  ms   : TMemoryStream;
  root, n : TDOMNode;
begin
  Session := Default(TQRZSession);
  Info := Default(TQRZCallbook);
  Result := False;
  if Xml = '' then exit;
  doc := nil;
  ms := TMemoryStream.Create;
  try
    ms.WriteBuffer(Pointer(Xml)^, Length(Xml));
    ms.Position := 0;
    try
      ReadXMLFile(doc, ms)
    except
      exit
    end;
    root := doc.DocumentElement;
    if (root = nil) or (UTF8Encode(root.NodeName) <> 'QRZDatabase') then
      exit;
    Result := True;

    n := FindChild(root, 'Session');
    Session.Key     := ChildText(n, 'Key');
    Session.Error   := ChildText(n, 'Error');
    Session.Message := ChildText(n, 'Message');
    Session.SubExp  := ChildText(n, 'SubExp');

    n := FindChild(root, 'Callsign');
    if n <> nil then
      ParseCallsign(n, Info)
  finally
    doc.Free;
    ms.Free
  end
end;

end.
