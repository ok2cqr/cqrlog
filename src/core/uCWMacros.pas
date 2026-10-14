(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ CW message macros.

 %mc - my callsign
 %mn - my name
 %mq - my qth
 %ml - my locator
 %r  - rst send
 %rs - rst send sends N instead of 9 (sends also 0 as T, but does not exist in normal report)

 %n  - name
 %c  - callsign
 %h - greeting GM/GA/GE calculated from the %c station location time

 %xn  - contest exchange serial number
 %xnr - contest exchange seral number received
 %xm  - contest exchange message
 %xmr - contest exchange message received
 %xns - contest exchenge serial number sends 9->N and 0->T
 %xnrs- contest exchange message received sends 9->N and 0->T
 %xrs - full contest exchange RST+SerialNR+Message sends 9->N and 0->T.
        Can be used "always" as if serNR and/or Message are empty just sends plain report.

  The macros are case insensitive and replaced one after another, longer
  ones first, so a value that contains a macro replaced later gets expanded
  too.

  Moved here from TdmUtils.GetCWMessage to be testable without LCL and the
  settings; the caller passes the station data.  No LCL, no globals; see
  tests/tCWMacroExpansion.pas. }

unit uCWMacros;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  TCWMacroStation = record
    MyCall : String;
    MyLoc  : String;
    MyName : String;
    MyQth  : String;
  end;

  TCWMacroQso = record
    Call    : String;
    RstS    : String; //rst sent
    Stx     : String; //serial number sent
    StxStr  : String; //exchange message sent
    Srx     : String; //serial number received
    SrxStr  : String; //exchange message received
    HisName : String;
    Hello   : String; //GM/GA/GE
  end;

function ExpandCWMacros(const Text : String; const Station : TCWMacroStation; const Qso : TCWMacroQso) : String;
//9 -> N, 0 -> T
function CWShortNumbers(const s : String) : String;

implementation

function CWShortNumbers(const s : String) : String;
begin
  Result := StringReplace(s,'9','N',[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'0','T',[rfReplaceAll, rfIgnoreCase]) //replace zeros, too
end;

function ExpandCWMacros(const Text : String; const Station : TCWMacroStation; const Qso : TCWMacroQso) : String;
var
  rst_sh : String = '';
  stx_sh : String = '';
  srx_sh : String = '';
  con_ex : String = '';
begin
  Result := Text;

  rst_sh := CWShortNumbers(Qso.RstS);
  stx_sh := CWShortNumbers(Qso.Stx);
  srx_sh := CWShortNumbers(Qso.Srx);

  con_ex := rst_sh;
  if stx_sh <>'' then con_ex:=con_ex+' '+stx_sh;
  if Qso.StxStr <>'' then con_ex:=con_ex+' '+Qso.StxStr;

  Result := StringReplace(Result,'%xnrs',srx_sh,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%xnr',Qso.Srx,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%xns',stx_sh,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%xn',Qso.Stx,[rfReplaceAll, rfIgnoreCase]);

  Result := StringReplace(Result,'%xmr',Qso.SrxStr,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%xm',Qso.StxStr,[rfReplaceAll, rfIgnoreCase]);

  Result := StringReplace(Result,'%xrs',con_ex,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%rs',rst_sh,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%r',Qso.RstS,[rfReplaceAll, rfIgnoreCase]);

  Result := StringReplace(Result,'%n',Qso.HisName,[rfReplaceAll, rfIgnoreCase]);

  Result := StringReplace(Result,'%mc',Station.MyCall,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%ml',Station.MyLoc,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%mn',Station.MyName,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%mq',Station.MyQth,[rfReplaceAll, rfIgnoreCase]);

  Result := StringReplace(Result,'%h',Qso.Hello,[rfReplaceAll, rfIgnoreCase]);

  Result := StringReplace(Result,'%c',Qso.Call,[rfReplaceAll, rfIgnoreCase])
end;

end.
