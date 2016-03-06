(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit dDXCC;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Dialogs, sqldb,
  mysql50conn, db, iniFiles, dateutils, FileUtil;



type
  TExplodeArray = Array of String;

type
  TDXCCRef = record
    adif    : Word;
    pref    : String[20];
    name    : String[100];
    cont    : String[6];
    utc     : String[12];
    lat     : String[10];
    longit  : String[10];
    itu     : String[20];
    waz     : String[20];
    deleted : Word
  end;

const
   NotExactly = 0; 
   Exactly    = 1; 
   ExNoEquals = 2; 


{                presne: c_pres_dlouhe=0;   co muze byt delsi nez nalezena znacka.
                         c_pres_kratke=1;   tak musi mit nalezena znacka stejnou delku jak "co".
                         c_pres_strikt=2;   jako kratke, ale BEZ = na zacatku.
}

type
  TUSStates = record
    prefix : String[10];
    name   : String[30];
    state  : String[3];
    offset : String[5];
    itu    : String[2];
    waz    : String[2];
    cont   : String[2];
    lat    : String[10];
    long   : String[10];
    adif   : Integer;
  end;

const
  MAX_STATES = 60;

type

  { TdmDXCC }

  TdmDXCC = class(TDataModule)
    dsrDeleted: TDatasource;
    dsrValid: TDatasource;


    Q: TSQLQuery;
    Q1: TSQLQuery;
    qDXCCRef: TSQLQuery;
    qValid: TSQLQuery;
    qDeleted: TSQLQuery;
    trDeleted: TSQLTransaction;
    trValid: TSQLTransaction;
    trDXCCRef: TSQLTransaction;
    trQ1: TSQLTransaction;
    trQ: TSQLTransaction;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure QBeforeOpen(DataSet: TDataSet);
    procedure trQStartTransaction(Sender: TObject);
  private
    DXCCRefArray   : Array of TDXCCRef;
    DXCCDelArray   : Array of Integer;
    AmbiguousArray : Array of String;
    ExceptionArray : Array of String;
    USStatesArray  : Array of TUSStates;

    function  CoVyhodnocovat(znacka : String; datum : TDateTime; var UzNasel : Boolean;var ADIF : Integer) : String;
    function  NaselCountry(znacka : String; datum : TDateTime; var ADIF : Integer;presne : Integer = NotExactly) : Boolean; overload;
    function  NaselCountry(znacka : String; datum : TDateTime; var pfx, country,
              cont, ITU, WAZ, posun, lat, long : String; var ADIF : Integer; presne : Integer = NotExactly) : Boolean;
    function  Explode(const cSeparator, vString: String): TExplodeArray;
    function  DateToDDXCCDate(date : TDateTime) : String;
    function  MyTryStrToInt(s : String; var i : Integer) : Boolean;
    function  GetStateInfo(state : String; var country,lat,long,waz,itu,offset,cont : String) : Integer;

  public
    function  IsException(call : String) : Boolean;
    function  DXCCInfo(adif : Word;freq,mode : String; var index : integer) : String;
    function  DXCCCount : Integer;
    function  DXCCCmfCount : Integer;
    function  IsAmbiguous(call : String) : Boolean;
    function  IsPrefix(pref : String; Date : TDateTime) : Boolean;
    function  GetCont(call : String; Date : TDateTime) : String;
    function  id_country(znacka: string; us_state : String; datum : TDateTime; var pfx, cont, country, WAZ,
                           posun, ITU, lat, long: string) : Word; overload;
    function  id_country(znacka: string;datum : TDateTime; var pfx, cont, country, WAZ,
                               posun, ITU, lat, long: string) : Word; overload;
    function  id_country(znacka : String; Datum : TDateTime; var pfx,country : String) : Word; overload;
    function  id_country(callsign : String;QsoDate : TDateTime) : String; overload;
    function  AdifFromPfx(pfx : String) : Word;
    function  PfxFromADIF(adif : Word) : String;
    function  GetDelDXCCAdifList : String;

    procedure ReloadDXCCTables;
    procedure LoadDXCCRefArray;
    procedure LoadAmbiguousArray;
    procedure LoadExceptionArray;
    procedure LoadUSStates;
  end;

var
  dmDXCC: TdmDXCC;

implementation

{ TdmDXCC }

uses dUtils, dData, znacmech, uMyIni;

type Tchyb1 = object(Tchyby) // podedim objekt a prepisu "hlaseni"
       //procedure hlaseni(vzkaz,kdo:string);virtual;
     end;
     Pchyb1=^Tchyb1;

var
  uhej   : Pseznam;
  sez1   : Pseznam;
  chy1   : Pchyb1;
  sez2   : Pseznam;
{
procedure Tchyb1.hlaseni(vzkaz,kdo:string);
begin
  if dmData.DebugLevel >=2 then
    Writeln(vzkaz);
end;
}

function TdmDXCC.MyTryStrToInt(s : String; var i : Integer) : Boolean;
begin
  i := 0;
  s := UpperCase(s);
  if (length(s) > 0) and (s[1] = 'X') then
  begin // when the string starts with X, trystrtoint expecs it's number in hexa, that is wrong e.g. XE1 is not valid integer
    result := false;
    exit
  end
  else begin
    result := TryStrToInt(s,i)
  end
end;

function TdmDXCC.DXCCCount : Integer;
var
  ShowDel : Boolean = False;
  tmp : String;
begin
  ShowDel := cqrini.ReadBool('Program','ShowDeleted',False);
  dmData.Q.Close;
  if dmData.trQ.Active then
    dmData.trQ.Rollback;
  if ShowDel then
    Q.SQL.Text := 'select count(*) from (select distinct adif from cqrlog_main where adif <> 0) as foo '
  else begin
    tmp := GetDelDXCCAdifList;
    if tmp <> '' then
      Q.SQL.Text := 'select count(*) from (select distinct adif from cqrlog_main'+
                    ' where adif <> 0 and '+tmp+') as foo '
    else
      Q.SQL.Text := 'select count(*) from (select distinct adif from cqrlog_main where adif <> 0) as foo '
  end;


  //Q.SQL.Text := 'select count(*) from (select distinct dxcc_id.dxcc_ref from dxcc_id left join cqrlog_main on '+
    //              'dxcc_id.adif = cqrlog_main.adif WHERE dxcc_ref not like '+QuotedStr('%*')+') as foo';
    //              ^^ much faster
    //Q.SQL.Text := 'SELECT COUNT(DISTINCT dxcc_ref) FROM view_cqrlog_main_by_qsodate WHERE dxcc_ref not like ' +
    //               QuotedStr('%*');
  trQ.StartTransaction;
  Q.Open;
  Result := Q.Fields[0].AsInteger;
  Q.Close;
  trQ.Rollback
end;

function TdmDXCC.DXCCCmfCount : Integer;
var
  ShowDel  : Boolean = False;
  ShowLoTw : Boolean = False;
  where    : String = '';
begin
  ShowDel  := cqrini.ReadBool('Program','ShowDeleted',False);
  ShowLoTW := cqrini.ReadBool('LoTW','IncLoTWDXCC',False);

  if not ShowDel then
    where := '(dxcc_ref NOT LIKE '+QuotedStr('%*')+') AND ';

  if ShowLoTw then
    where := where + '((qsl_r = '+QuotedStr('Q')+') OR '+
             '(lotw_qslr = '+QuotedStr('L')+') OR (eqsl_qsl_rcvd='+QuotedStr('E')+'))'
  else
    where := where + '(qsl_r = '+QuotedStr('Q')+')';

  dmData.Q.Close;
  if dmData.trQ.Active then
    dmData.trQ.Rollback;
  Q.SQL.Text := 'select count(*) from (select distinct dxcc_id.dxcc_ref from dxcc_id left join cqrlog_main on '+
                'dxcc_id.adif = cqrlog_main.adif WHERE cqrlog_main.adif<>0 and '+where+') as foo';

  //Q.SQL.Text := 'SELECT COUNT(DISTINCT dxcc_ref) FROM view_cqrlog_main_by_qsodate WHERE '+where;
  trQ.StartTransaction;
  Q.Open;
  Result := Q.Fields[0].AsInteger;
  Q.Close;
  trQ.Rollback
end;

function TdmDXCC.DXCCInfo(adif : Word;freq,mode : String; var index : integer) : String; // zjisti jestli je o nova zeme, nova zeme
var               // index : 0 - Nepotrebujes QSL (neznama zeme, potvrzena)
                 // index : 1 - Potrebujes QSL (nova zeme, nova na pasmu, modu)
  band : String;
  lotw   : Boolean = False;
  sAdif : String = '';
begin
  lotw := cqrini.ReadBool('LoTW','NewQSOLoTW',False);
  if (adif = 0) then
  begin
    Result := 'Unknown country';
    index  := 0;
    exit
  end;
  index := 1;
  sAdif := IntToStr(adif);

  band := dmUtils.GetBandFromFreq(freq);
  if trQ.Active then
    trQ.Rollback;

  try
    if lotw then
      Q.SQL.Text := 'SELECT id_cqrlog_main FROM cqrlog_main WHERE adif='+
                    sAdif+' AND band='+QuotedStr(band)+' AND ((qsl_r='+
                    QuotedStr('Q')+') OR (lotw_qslr='+QuotedStr('L')+')) AND mode='+
                    QuotedStr(mode)+' LIMIT 1'
    else
      Q.SQL.Text := 'SELECT id_cqrlog_main FROM cqrlog_main WHERE adif='+
                     sAdif+' AND band='+QuotedStr(band)+' AND qsl_r='+
                     QuotedStr('Q')+ ' AND mode='+QuotedStr(mode)+' LIMIT 1';
    trQ.StartTransaction;
    Q.Open;
    if Q.Fields[0].AsInteger > 0 then
    begin
      Result := 'Confirmed country!!';
      index  := 0
    end
    else begin
      Q.Close;
      Q.SQL.Text := 'SELECT id_cqrlog_main FROM cqrlog_main WHERE adif='+
                     sAdif+' AND band='+QuotedStr(band)+' AND mode='+
                     QuotedStr(mode)+' LIMIT 1';
      Q.Open;
      if Q.Fields[0].AsInteger > 0 then
      begin
        Result := 'QSL needed !!';
        index := 1
      end
      else begin
        Q.Close;
        Q.SQL.Text := 'SELECT id_cqrlog_main FROM cqrlog_main WHERE adif='+
                       sAdif+' AND band='+QuotedStr(band)+' LIMIT 1';
        Q.Open;
        if Q.Fields[0].AsInteger > 0 then
        begin
          Result := 'New mode country!!';
          index  := 1
        end
        else begin
          Q.Close;
          Q.SQL.Text := 'SELECT id_cqrlog_main FROM cqrlog_main WHERE adif='+
                         sAdif+' LIMIT 1';
          Q.Open;
          if Q.Fields[0].AsInteger>0 then
          begin
            Result := 'New band country!!';
            index  := 1
          end
          else begin
            Result := 'New country!!';
            index  := 1
          end
        end
      end
    end
  finally
    Q.Close;
    trQ.Rollback
  end
end;

function TdmDXCC.IsException(call : String) : Boolean;

  function IsString(call : String) : Boolean;
  var
    i : Integer;
  begin
    Result := True;
    for i:=1 to Length(call) do
    begin
      if (call[i] in ['0'..'9']) then
      begin
        Result := False;
        break
      end
    end;
  end;

var
  y : Integer;
begin
  Result := False;
  for y:=0 to Length(ExceptionArray)-1 do
  begin
    if ExceptionArray[y] = call then
    begin
      Result := True;
      Break
    end
  end;
  if (call = 'QRP') or (call='QRPP') or (call='P') then
    Result := True;
  if (IsString(call) and (Length(call) > 3)) then
    Result := True
end;

function TdmDXCC.Explode(const cSeparator, vString: String): TExplodeArray;
var
  i: Integer;
  S: String;
begin
  S := vString;
  SetLength(Result, 0);
  i := 0;
  while Pos(cSeparator, S) > 0 do begin
    SetLength(Result, Length(Result) +1);
    Result[i] := Copy(S, 1, Pos(cSeparator, S) -1);
    Inc(i);
    S := Copy(S, Pos(cSeparator, S) + Length(cSeparator), Length(S));
  end;
  SetLength(Result, Length(Result) +1);
  Result[i] := Copy(S, 1, Length(S));
end;


function TdmDXCC.NaselCountry(znacka : String; datum : TDateTime; var pfx, country,
   cont, ITU, WAZ, posun, lat, long : String; var ADIF : Integer; presne : Integer = NotExactly) : Boolean;

   function Datumek(sdatum : String) : TDateTime;
   var
     tmp : TExplodeArray;
   begin
     tmp    := Explode('.',sdatum);
     Result := EncodeDate(StrToInt(tmp[2]),StrToInt(tmp[1]),strToInt(tmp[0]));
   end;

var
  sZnac  : string_mdz;
  sADIF  : String;
  sdatum : String;
  x      : LongInt;
begin
  Result := False;
  sZnac  := znacka;
  sDatum  := DateToDDXCCDate(Datum);
  x := sez2^.najdis_s2(sZnac,sDatum,presne);
  if x <>-1 then
  begin
    country  := sez2^.znacka_popis_ex(x,0);
    ITU      := sez2^.znacka_popis_ex(x,5);
    WAZ      := sez2^.znacka_popis_ex(x,6);
    posun    := sez2^.znacka_popis_ex(x,2);
    lat      := sez2^.znacka_popis_ex(x,3);
    long     := sez2^.znacka_popis_ex(x,4);
    sADIF    := sez2^.znacka_popis_ex(x,11);
    cont     := UpperCase(sez2^.znacka_popis_ex(x,1));
    Result   := True;
    if not TryStrToInt(sAdif,ADIF) then
      ADIF := 0;
    exit
  end
  else begin
    pfx := '!'
  end;

  x := uhej^.najdis_s2(sZnac,sDatum,presne);
  if x <>-1 then
  begin
    country  := uhej^.znacka_popis_ex(x,0);
    ITU      := uhej^.znacka_popis_ex(x,5);
    WAZ      := uhej^.znacka_popis_ex(x,6);
    posun    := uhej^.znacka_popis_ex(x,2);
    lat      := uhej^.znacka_popis_ex(x,3);
    long     := uhej^.znacka_popis_ex(x,4);
    sADIF    := uhej^.znacka_popis_ex(x,11);
    cont     := UpperCase(uhej^.znacka_popis_ex(x,1));
    Result   := True;
    if not TryStrToInt(sAdif,ADIF) then
      ADIF := 0
  end
  else begin
    pfx := '!'
  end
end;

function TdmDXCC.NaselCountry(znacka : String; datum : TDateTime; var ADIF : Integer;presne : Integer = NotExactly) : Boolean;
var
  pfx,cont,country,itu,waz,posun,lat,long : String;
begin
  cont := '';WAZ := '';posun := '';ITU := '';lat := '';long := '';pfx := '';
  Country := '';
  Result := NaselCountry(znacka,datum,pfx,cont,country,itu,waz,
            posun,lat,long,adif,presne);
end;



function TdmDXCC.CoVyhodnocovat(znacka : String; datum : TDateTime; var UzNasel : Boolean;var ADIF : Integer) : String;
var
  Pole  : TExplodeArray;
  pocet : Integer;
  pred_lomitkem : String;
  za_lomitkem   : String;
  mezi_lomitky  : String;
  tmp : Integer;
  Error : Integer;
begin
  tmp := 0;
  Result := znacka;
  if pos('/',znacka) > 0 then
  begin
    if NaselCountry(znacka,datum,adif,Exactly) then
    begin
      Result  := znacka;
      UzNasel := True;
      exit
    end;

    SetLength(pole,0);
    pole  := Explode('/',znacka);
    pocet := Length(pole)-1;
    case pocet of
      1: begin
           pred_lomitkem := pole[0];
           za_lomitkem   := pole[1];
           if ((MyTryStrToInt(za_lomitkem,tmp)) and (Length(za_lomitkem)>1)) then
           begin
             Result := pred_lomitkem;
             exit
           end;

           if (Length(pred_lomitkem) = 0) then
           begin
             Result := za_lomitkem;
             exit
           end;
           if (Length(za_lomitkem) = 0) then
           begin
             Result := pred_lomitkem;
             exit
           end;
           //if (((za_lomitkem[1]='M') and (za_lomitkem[2]='M')) or (za_lomitkem='AM')) then //nevim kde je
           if (za_lomitkem='MM') or (za_lomitkem='MM1')  or (za_lomitkem='MM2') or (za_lomitkem='MM3') or (za_lomitkem='AM') then
           begin
             Result := '?';
             exit
           end;
           if (length(za_lomitkem) = 1) then
           begin
             if (((za_lomitkem[1] = 'M') or (za_lomitkem[1] = 'P')) and (Pos('LU',pred_lomitkem) <> 1)) then
             begin
               Result := pred_lomitkem;
               exit
             end;
             if (za_lomitkem[1] in ['0'..'9']) then   //SP2AD/1
             begin
               if (((pred_lomitkem[1] = 'A') and (pred_lomitkem[2] in ['A'..'L']))  or
                  (pred_lomitkem[1] = 'K') or (pred_lomitkem[1] = 'W') or  (pred_lomitkem[1] = 'N'))   then  //KL7AA/1 = W1
                 Result := 'W'+za_lomitkem
               else begin
                 pred_lomitkem[3] := za_lomitkem[1];
                 Result := pred_lomitkem;//Result := copy(pred_lomitkem,1,3);
               end;
             end
             else begin
               if ((za_lomitkem[1] in ['A'..'D','E','H','J','L'..'V','X'..'Z'])) then //pokud je za lomitkem jen pismeno,
               begin                                    //nesmime zapomenout na chudaky Argentince
                 if (Pos('LU',pred_lomitkem) = 1) or (Pos('LW',pred_lomitkem) = 1) or
                 (Pos('AY',pred_lomitkem) = 1) or (Pos('AZ',pred_lomitkem) = 1) or
                 (Pos('LO',pred_lomitkem) = 1) or (Pos('LP',pred_lomitkem) = 1) or
                 (Pos('LQ',pred_lomitkem) = 1) or (Pos('LR',pred_lomitkem) = 1) or
                 (Pos('LS',pred_lomitkem) = 1) or (Pos('LT',pred_lomitkem) = 1) or
                 (Pos('LV',pred_lomitkem) = 1) then
                 begin
                   pred_lomitkem[4] := za_lomitkem[1];
                   Result := pred_lomitkem;
                   exit
                 end
                 else                 //pokud to neni chudak Argentinec, nechame znacku napokoji
                   Result := znacka;
               end
               else begin
                 UzNasel := True;
                 Result  := za_lomitkem;
               end;
               if NaselCountry(copy(pred_lomitkem,1,2)+'/'+za_lomitkem,datum,ADIF) then
               begin
                 UzNasel := True;
                 Result  := copy(pred_lomitkem,1,2)+'/'+za_lomitkem;
                 exit;
               end;
             end;
           end
           else begin //za lomitkem je vic jak jedno pismenko
            if IsException(za_lomitkem) then
               Result := pred_lomitkem
             else begin
               if Length(za_lomitkem) >= Length(pred_lomitkem) then
               begin
                 if not NaselCountry(pred_lomitkem,datum,ADIF,ExNoEquals) then
                 begin
                   Result  := za_lomitkem;
                   UzNasel := True;
                   exit;
                 end
                 else begin
                   Result  := pred_lomitkem;
                   exit
                 end;
               end
               else begin  //pred lomitkem je to delsi nebo rovno
                 if not NaselCountry(za_lomitkem,datum,ADIF,ExNoEquals) then
                 begin
                   Result  := pred_lomitkem;
                   UzNasel := True;
                   exit;
                 end
                 else begin
                   Result  := za_lomitkem;
                   UzNasel := True;
                   exit
                 end;
               end;
             end;
           end;

         end; // 1 lomitko

      2: begin
           pred_lomitkem := pole[0];
           mezi_lomitky  := pole[1];
           za_lomitkem   := pole[2];
           if Length(za_lomitkem) = 0 then
           begin
             Result := pred_lomitkem;
             exit
           end;
           if (((za_lomitkem[1]='M') and (za_lomitkem[2]='M')) or (za_lomitkem='AM')) then //nevim kde je
           begin
             Result := '?';
             exit
           end;

           if Length(mezi_lomitky) > 0 then
           begin
             if (mezi_lomitky[1] in ['0'..'9']) then
             begin
               if (((pred_lomitkem[1] = 'A') and (pred_lomitkem[2] in ['A'..'L']))  or
                  (pred_lomitkem[1] = 'K') or (pred_lomitkem[1] = 'W'))   then  //KL7AA/1 = W1
                   Result := 'W'+mezi_lomitky
               else begin
                 if pred_lomitkem[2] in ['0'..'9'] then //RA1AAA/2/M
                   pred_lomitkem[2] := mezi_lomitky[1]
                 else
                   pred_lomitkem[3] := mezi_lomitky[1];
                   Result := pred_lomitkem;
                 exit;
               end;
             end;
           end;
           
           if ((length(za_lomitkem) = 1) and (za_lomitkem[1] in ['A'..'Z'])) then
           begin
             if NaselCountry(pred_lomitkem + '/'+za_lomitkem,datum,ADIF) then
             begin
               Result  := pred_lomitkem + '/'+za_lomitkem;
               UzNasel := True;
             end
             else begin
               Result := pred_lomitkem
             end;
           end
           else begin
             if ((length(za_lomitkem) = 1) and (za_lomitkem[1] in ['0'..'9'])) then
             begin
               if NaselCountry(pred_lomitkem[1]+pred_lomitkem[2]+za_lomitkem,datum, ADIF) then //ZL1AMO/C
               begin
                 Result  := pred_lomitkem[1]+pred_lomitkem[2]+za_lomitkem;
                 UzNasel := True;
               end
               else
                 Result := pred_lomitkem
             end
             else
               Result := pred_lomitkem
           end;
         end; // 2 lomitka
    end; //case
  end;
end;

function TdmDXCC.id_country(callsign : String;QsoDate : TDateTime) : String;
var
  cont, WAZ, posun, ITU, lat, long, pfx, country: string;
begin
  cont := '';WAZ := '';posun := '';ITU := '';lat := '';long := '';
  Result := DXCCRefArray[id_country(callsign,qsodate,pfx,country,cont,itu,waz,posun,lat,long)].pref
end;

function TdmDXCC.id_country(znacka : String; Datum : TDateTime; var pfx,country : String) : Word;
var
  cont, WAZ, posun, ITU, lat, long: string;
begin
  cont := '';WAZ := '';posun := '';ITU := '';lat := '';long := '';
  Result := id_country(znacka,datum,pfx,country,cont,itu,waz,posun,lat,long)
end;

function TdmDXCC.GetCont(call : String; Date : TDateTime) : String;
var
  cont, WAZ, posun, ITU, lat, long, country, pfx: string;
begin
  cont := '';WAZ := '';posun := '';ITU := '';lat := '';long := '';
  country := ''; pfx := '';
  id_country(call,date,pfx,country,cont,itu,waz,posun,lat,long);
  Result := Cont
end;


function TdmDXCC.id_country(znacka: string;datum : TDateTime; var pfx, cont, country, WAZ,
  posun, ITU, lat, long: string) : Word;
begin
  Result := id_country(znacka, '', datum, pfx, cont, country, WAZ, posun, ITU, lat, long)
end;

function TdmDXCC.id_country(znacka: string; us_state : String; datum : TDateTime; var pfx, cont, country, WAZ,
                       posun, ITU, lat, long: string) : Word;
var
  ADIF   : Integer;
  UzNasel : Boolean;
  sdatum : String;
  NoDXCC : Boolean;
  x :longint;
  sZnac : string_mdz;
  sADIF : String;
  us_adif : Integer;
begin
  if (length(znacka)=0) then
  begin
    exit;
  end;
  UzNasel := False;
  ADIF := 0;

  sZnac := znacka;
  sZnac := CoVyhodnocovat(znacka,datum,UzNasel,ADIF);
  sDatum  := DateToDDXCCDate(Datum);// DateToStr(Datum);
  x := sez2^.najdis_s2(sZnac,sDatum,NotExactly);
  if x <>-1 then
  begin
    country  := sez2^.znacka_popis_ex(x,0);
    ITU      := sez2^.znacka_popis_ex(x,5);
    WAZ      := sez2^.znacka_popis_ex(x,6);
    posun    := sez2^.znacka_popis_ex(x,2);
    lat      := sez2^.znacka_popis_ex(x,3);
    long     := sez2^.znacka_popis_ex(x,4);
    sADIF    := sez2^.znacka_popis_ex(x,11);
    cont     := UpperCase(sez2^.znacka_popis_ex(x,1));
    NoDXCC   := Pos('no DXCC',country) > 0;
    if TryStrToInt(sAdif,ADIF) then
    begin
      if ADIF > 0 then
      begin
        if ((adif = 6) or (adif = 9) or (adif = 103) or (adif = 110) or (adif = 166) or (adif = 202) or (adif = 285) or (adif = 291))
           and (us_state<>'') then
        begin
          us_adif := GetStateInfo(us_state,country,lat,long,waz,itu,posun,cont);
          if us_adif > 0 then
            ADIF := us_adif
        end;
        pfx := DXCCRefArray[adif].pref;
        Result := ADIF
      end
      else begin
        if NoDXCC then
          pfx := '#'
        else
          pfx := '!';
        Result := 0
      end
    end
    else
      Result := 0;
    exit
  end
  else begin
    pfx := '!';
    Result := 0
  end;

  x := uhej^.najdis_s2(sZnac,sDatum,NotExactly);
  if x <>-1 then
  begin
    country  := uhej^.znacka_popis_ex(x,0);
    ITU      := uhej^.znacka_popis_ex(x,5);
    WAZ      := uhej^.znacka_popis_ex(x,6);
    posun    := uhej^.znacka_popis_ex(x,2);
    lat      := uhej^.znacka_popis_ex(x,3);
    long     := uhej^.znacka_popis_ex(x,4);
    sADIF    := uhej^.znacka_popis_ex(x,11);
    cont     := UpperCase(uhej^.znacka_popis_ex(x,1));
    NoDXCC   := Pos('no DXCC',country) > 0;
    if TryStrToInt(sAdif,ADIF) then
    begin
      if ADIF > 0 then
      begin
        if ((adif = 6) or (adif = 9) or (adif = 103) or (adif = 110) or (adif = 166) or (adif = 202) or (adif = 285) or (adif = 291))
           and (us_state<>'') then
        begin
          us_adif := GetStateInfo(us_state,country,lat,long,waz,itu,posun,cont);
          if us_adif > 0 then
            ADIF := us_adif
        end;
        pfx    := DXCCRefArray[adif].pref;
        Result := ADIF
      end
      else begin
        if NoDXCC then
          pfx := '#'
        else
          pfx := '!';
        Result := 0
      end;
      exit
    end
  end
  else begin
    pfx := '!';
    Result := 0
  end
end;

procedure TdmDXCC.DataModuleCreate(Sender: TObject);
begin
  trDXCCRef.DataBase := dmData.MainCon;
  qDXCCRef.Database  := dmData.MainCon;
  qDXCCRef.SQL.Text  := 'SELECT * FROM cqrlog_common.dxcc_ref ORDER BY adif';

  trQ.DataBase := dmData.MainCon;
  Q.DataBase   := dmData.MainCon;

  trQ1.DataBase := dmData.MainCon;
  Q1.DataBase   := dmData.MainCon;

  trValid.DataBase := dmData.MainCon;
  qValid.DataBase  := dmData.MainCon;

  trDeleted.DataBase := dmData.MainCon;
  qDeleted.DataBase  := dmData.MainCon;

  chy1 := new(Pchyb1,init);
  sez1 := new(Pseznam,init(dmData.HomeDir + 'dxcc_data/country.tab',chy1));
  uhej := sez1;
  sez2 := new(Pseznam,init(dmData.HomeDir + 'dxcc_data/country_del.tab',chy1));

  //after upgrade from version 1.9.1 and older, this file won't exist
  //but we need it
  if not FileExistsUTF8(dmData.HomeDir + 'dxcc_data/us_states.tab') then
    CopyFile(dmData.HomeDir+'ctyfiles/us_states.tab',dmData.HomeDir + 'dxcc_data/us_states.tab');

  LoadUSStates
end;

procedure TdmDXCC.DataModuleDestroy(Sender: TObject);
begin
  if dmData.DebugLevel >=2 then
    Writeln('End dmDXCC');

  if dmData.DebugLevel >=2 then
    Writeln('Complete end dmDXCC');
  if dmData.DebugLevel>=1 then Writeln('Closing dDXCC');
  dispose(sez1,done);
  dispose(sez2,done)
end;

procedure TdmDXCC.QBeforeOpen(DataSet: TDataSet);
begin
  if dmData.DebugLevel>=1 then WriteLn(Q.SQL.Text)
end;


procedure TdmDXCC.trQStartTransaction(Sender: TObject);
begin
  if dmData.DebugLevel >=2 then
  begin
    Write('Start Q:');
    Writeln(Q.SQL.Text);
  end;
end;


function TdmDXCC.IsAmbiguous(call : String) : Boolean;
var
  i : Integer;
begin
  Result := False;
  if Pos('/',call) < 1 then
  begin
    for i:=0 to Length(AmbiguousArray)-1 do
    begin
      if Pos(AmbiguousArray[i],call) = 1 then
      begin
        Result := True;
        Break
      end
    end
  end
  else begin
    if Length(call) < 4 then
      exit;
    call := call[1] + call[2] + '/' + copy(call,pos('/',call)+1,1);
    for i:=0 to Length(AmbiguousArray)-1 do
    begin
      if AmbiguousArray[i] = call then
      begin
        Result := True;
        Break
      end
    end
  end
end;

function TdmDXCC.IsPrefix(pref : String; Date : TDateTime) : Boolean;
var
  adif : Integer;
begin
  if NaselCountry(pref,Date,adif,Exactly) then
    Result := True
  else
    Result := False;
end;

function TdmDXCC.DateToDDXCCDate(date : TDateTime) : String;
var
  d,m,y : Word;
  sd,sm : String;
begin
  DecodeDate(date,y,m,d);
  if d < 10 then
    sd := '0'+IntToStr(d)
  else
    sd := IntToStr(d);
  if m < 10 then
    sm := '0'+IntToStr(m)
  else
    sm := IntToStr(m);
  Result := IntToStr(y) + '/' + sm + '/' + sd
end;

procedure TdmDXCC.ReloadDXCCTables;
begin
  dispose(sez1,done);
  dispose(sez2,done);

  chy1 := new(Pchyb1,init);
  sez1 := new(Pseznam,init(dmData.HomeDir + 'dxcc_data/country.tab',chy1));
  uhej := sez1;
  sez2 := new(Pseznam,init(dmData.HomeDir + 'dxcc_data/country_del.tab',chy1));
  LoadDXCCRefArray;
  LoadUSStates
end;

procedure TdmDXCC.LoadDXCCRefArray;
var
  adif : Integer;
begin
  if trQ.Active then
    trQ.Rollback;
  Q.SQL.Text := 'SELECT * FROM cqrlog_common.dxcc_ref ORDER BY ADIF';
  try
    trQ.StartTransaction;
    Q.Open;
    Q.Last;
    SetLength(DXCCRefArray,StrToInt(Q.FieldByName('adif').AsString)+1);
    SetLength(DXCCDelArray,0);
    DXCCRefArray[0].adif := 0;
    DXCCRefArray[0].pref := '';
    Q.First;
    while not Q.Eof do
    begin
      adif := StrToInt(Q.FieldByName('adif').AsString);
      DXCCRefArray[adif].adif    := adif;
      DXCCRefArray[adif].pref    := Q.FieldByName('pref').AsString;
      DXCCRefArray[adif].name    := Q.FieldByName('name').AsString;
      DXCCRefArray[adif].cont    := Q.FieldByName('cont').AsString;
      DXCCRefArray[adif].utc     := Q.FieldByName('utc').AsString;
      DXCCRefArray[adif].lat     := Q.FieldByName('lat').AsString;
      DXCCRefArray[adif].longit  := Q.FieldByName('longit').AsString;
      DXCCRefArray[adif].itu     := Q.FieldByName('itu').AsString;
      DXCCRefArray[adif].waz     := Q.FieldByName('waz').AsString;
      DXCCRefArray[adif].deleted := Q.FieldByName('deleted').AsInteger;
      if DXCCRefArray[adif].deleted > 0 then
      begin
        SetLength(DXCCDelArray,Length(DXCCDelArray)+1);
        DXCCDelArray[Length(DXCCDelArray)-1] := adif
      end;
      Q.Next
    end;
  finally
    Q.Close;
    trQ.Rollback
  end
end;

function TdmDXCC.AdifFromPfx(pfx : String) : Word;
var
  i : Integer;
begin
  Result := 0;
  for i:=0 to Length(DXCCRefArray)-1 do
  begin
    if DXCCRefArray[i].pref = pfx then
    begin
      Result := DXCCRefArray[i].adif;
      exit
    end
  end
end;

function TdmDXCC.PfxFromADIF(adif : Word) : String;
begin
  Result := DXCCRefArray[adif].pref
end;

function TdmDXCC.GetDelDXCCAdifList : String;
var
  i : Integer;
begin
  Result := '(adif not in (';
  for i:=0 to Length(DXCCDelArray)-1 do
  begin
    if i > 0 then
      Result := Result + ','+ IntToStr(DXCCDelArray[i])
    else
      Result := Result + IntToStr(DXCCDelArray[i])
  end;
  Result := Result + '))'
  //this ^^ is much faster
  {
  for i:=0 to Length(DXCCDelArray)-1 do
    Result := Result + '(adif <> ' + IntToStr(DXCCDelArray[i])+') AND ';

  if Result <> '' then
  begin
    Result := copy(Result,1, Length(Result)-5);
    Result := '('+Result+')'
  end
  }
end;

procedure TdmDXCC.LoadAmbiguousArray;
var
  f    : TextFile;
  s    : String;
begin
  SetLength(AmbiguousArray,0);
  AssignFile(f,dmData.HomeDir+'dxcc_data'+PathDelim+'ambiguous.tab');
  Reset(f);
  while not Eof(f) do
  begin
    ReadLn(f,s);
    //file has only a few lines so there is no need to SetLength in higher blocks
    SetLength(AmbiguousArray,Length(AmbiguousArray)+1);
    AmbiguousArray[Length(AmbiguousArray)-1]:=s
  end;
  CloseFile(f)
end;

procedure TdmDXCC.LoadExceptionArray;
var
  f    : TextFile;
  s    : String;
begin
  SetLength(ExceptionArray,0);
  AssignFile(f,dmData.HomeDir+'dxcc_data'+PathDelim+'exceptions.tab');
  Reset(f);
  while not Eof(f) do
  begin
    ReadLn(f,s);
    //file has only a few lines so there is no need to SetLength in higher blocks
    SetLength(ExceptionArray,Length(ExceptionArray)+1);
    ExceptionArray[Length(ExceptionArray)-1]:=s
  end;
  CloseFile(f)
end;

procedure TdmDXCC.LoadUSStates;
var
  f : TextFile;
  a : TExplodeArray;
  i : Integer = 0;
  r : String;
begin
  if FileExistsUTF8(dmData.HomeDir+'dxcc_data'+PathDelim+'us_states.tab') then
  begin
    try
      AssignFile(f,dmData.HomeDir+'dxcc_data'+PathDelim+'us_states.tab');
      Reset(f);

      SetLength(USStatesArray,MAX_STATES);

      while not Eof(f) do
      begin
        Readln(f,r);
        a := Explode('|',r);

        USStatesArray[i].prefix := a[0];
        USStatesArray[i].name   := a[1];
        USStatesArray[i].state  := a[2];
        USStatesArray[i].cont   := a[3];

        if (pos('+',a[4])>0) then
          USStatesArray[i].offset := copy(a[4],2,10)
        else
          USStatesArray[i].offset := a[4];

        USStatesArray[i].itu  := a[5];
        USStatesArray[i].waz  := a[6];
        USStatesArray[i].lat  := a[7];
        USStatesArray[i].long := a[8];
        USStatesArray[i].adif := StrToInt(a[9]);

        inc(i)
      end
    finally
      CloseFile(f);
      if dmData.DebugLevel>=1 then Writeln(i,' us states loaded')
    end
  end
end;

function TdmDXCC.GetStateInfo(state : String; var country,lat,long,waz,itu,offset,cont : String) : Integer;
var
  i : Integer;
begin
  Result := 0;

  for i:=0 to Length(USStatesArray)-1 do
  begin
    if (state = USStatesArray[i].state) then
    begin
      country := USStatesArray[i].name;
      lat     := USStatesArray[i].lat;
      long    := USStatesArray[i].long;
      waz     := USStatesArray[i].waz;
      itu     := USStatesArray[i].itu;
      offset  := USStatesArray[i].offset;
      cont    := USStatesArray[i].cont;
      Result  := USStatesArray[i].adif;
      break
    end
  end
end;

initialization
  {$I dDXCC.lrs}

end.

