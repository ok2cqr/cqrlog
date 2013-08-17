(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit dDXCluster;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Dialogs, Graphics,
  inifiles, sqldb, mysql51conn, db, mysql55conn;

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
   MaxCall = 100000;

type
  { TdmDXCluster }
  TdmDXCluster = class(TDataModule)
    qBands: TSQLQuery;
    Q1: TSQLQuery;
    Q: TSQLQuery;
    qDXCCRef: TSQLQuery;
    trDXCCRef: TSQLTransaction;
    trQ: TSQLTransaction;
    trQ1: TSQLTransaction;
    trBands: TSQLTransaction;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure Q1BeforeOpen(DataSet: TDataSet);
    procedure qBandsBeforeOpen(DataSet: TDataSet);
    procedure QBeforeOpen(DataSet: TDataSet);
    procedure qDXCCRefBeforeOpen(DataSet: TDataSet);
  private
    DXCCRefArray   : Array of TDXCCRef;
    DXCCDelArray   : Array of Integer;
    ExceptionArray : Array of String;
    csDX           : TRTLCriticalSection;

    function  IsException(call : String) : Boolean;
    function  CoVyhodnocovat(znacka : String; datum : TDateTime; var UzNasel : Boolean;var ADIF : Integer) : String;
    function  NaselCountry(znacka : String; datum : TDateTime; var ADIF : Integer;presne : Integer = NotExactly) : Boolean; overload;
    function  NaselCountry(znacka : String; datum : TDateTime; var pfx, country,
              cont, ITU, WAZ, posun, lat, long : String; var ADIF : Integer; presne : Integer = NotExactly) : Boolean;
    function  Explode(const cSeparator, vString: String): TExplodeArray;
    function  DateToDDXCCDate(date : TDateTime) : String;

    //procedure VyhodnotZnacku(znacka : String; datum : TDateTime; var pfx, country, cont, ITU, WAZ, posun, lat, long : String);
  public
    dxCallArray : Array [0..MaxCall] of String[20];
    dbDXC       : TSQLConnection;

    function  LetterFromMode(mode : String) : String;
    function  DXCCInfo(adif : Word;freq,mode : String; var index : integer) : String;
    function  BandModFromFreq(freq : String;var mode,band : String) : Boolean;
    function  UsesLotw(call : String) : Boolean;
    function  UseseQSL(call : String) : Boolean;
    function  id_country(znacka: string;datum : TDateTime; var pfx, cont, country, WAZ,
                               posun, ITU, lat, long: string) : Word; overload;
    function  id_country(znacka : String; Datum : TDateTime; var pfx,country,waz,itu,cont : String) : Word; overload;
    function  id_country(znacka : String; Datum : TDateTime; var pfx,country,waz,itu,cont,lat,long : String): Word; overload;
    function  id_country(znacka : String;var lat,long : String): Word; overload;
    function  PfxFromADIF(adif : Word) : String;
    function  CountryFromADIF(adif : Word) : String;
    function  GetBandFromFreq(freq : string; kHz : Boolean=false): String;

    procedure AddToMarkFile(prefix,call : String;sColor : Integer;Max,lat,long : String);
    procedure ReloadDXCCTables;
    procedure LoadDXCCRefArray;
    procedure LoadExceptionArray;
  end;

var
  dmDXCluster: TdmDXCluster;

implementation

{ TdmDXCluster }
uses dUtils, dData, znacmech, uMyini;

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


function TdmDXCluster.BandModFromFreq(freq : String;var mode,band : String) : Boolean;
var
  tmp : Extended;
  cw, ssb : Extended;
begin
  EnterCriticalsection(csDX);
  try
    Result := False;
    if (freq = '') then
      exit;
    if not TryStrToFloat(freq,tmp) then
      exit;
    tmp := tmp/1000;
    freq := FloatToStr(tmp);

    qBands.Close;
    qBands.SQL.Text := 'SELECT * FROM cqrlog_common.bands where (b_begin <='+freq+' AND b_end >='+
                        freq+') ORDER BY b_begin';
    if dmData.DebugLevel >= 1 then
      Writeln(qBands.SQL.Text);
    if trBands.Active then
      trBands.RollBack;
    trBands.StartTransaction;
    qBands.Open;
    Writeln('qBands.RecorfdCount: ',qBands.RecordCount);
    if qBands.RecordCount = 0 then
      exit;
    band := qBands.Fields[1].AsString;
    cw   := qBands.Fields[4].AsFloat;
    ssb  := qBands.Fields[6].AsFloat;

    Result := True;
    if (tmp <= cw) then
      mode := 'CW'
    else begin
      if (tmp >= ssb) then
        mode := 'SSB'
      else
        mode := 'RTTY';
    end;
    Writeln('TdmDXCluster.BandModFromFreq:',Result,' cw ',FloatToStr(cw),' ssb ',FloatToStr(ssb))
  finally
    LeaveCriticalsection(csDX)
  end
end;

function TdmDXCluster.DXCCInfo(adif : Word;freq,mode : String; var index : integer) : String;
var
  band : String;
  lotw   : Boolean = False;
  sAdif : String = '';
begin
  EnterCriticalsection(csDX);
  try
    // index : 0 - unknown country, no qsl needed
    // index : 1 - New country
    // index : 2 - New band country
    // index : 3 - New mode country
    // index : 4 - QSL needed
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

    try try
      if lotw then
        Q.SQL.Text := 'SELECT id_cqrlog_main FROM '+dmData.DBName+'.cqrlog_main WHERE adif='+
                      sAdif+' AND band='+QuotedStr(band)+' AND ((qsl_r='+
                      QuotedStr('Q')+') OR (lotw_qslr='+QuotedStr('L')+')) AND mode='+
                      QuotedStr(mode)+' LIMIT 1'
      else
        Q.SQL.Text := 'SELECT id_cqrlog_main FROM '+dmData.DBName+'.cqrlog_main WHERE adif='+
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
        Q.SQL.Text := 'SELECT id_cqrlog_main FROM '+dmData.DBName+'.cqrlog_main WHERE adif='+
                       sAdif+' AND band='+QuotedStr(band)+' AND mode='+
                       QuotedStr(mode)+' LIMIT 1';
        Q.Open;
        if Q.Fields[0].AsInteger > 0 then
        begin
          Result := 'QSL needed !!';
          index := 4
        end
        else begin
          Q.Close;
          Q.SQL.Text := 'SELECT id_cqrlog_main FROM '+dmData.DBName+'.cqrlog_main WHERE adif='+
                         sAdif+' AND band='+QuotedStr(band)+' LIMIT 1';
          Q.Open;
          if Q.Fields[0].AsInteger > 0 then
          begin
            Result := 'New mode country!!';
            index  := 3
          end
          else begin
            Q.Close;
            Q.SQL.Text := 'SELECT id_cqrlog_main FROM '+dmData.DBName+'.cqrlog_main WHERE adif='+
                           sAdif+' LIMIT 1';
            Q.Open;
            if Q.Fields[0].AsInteger>0 then
            begin
              Result := 'New band country!!';
              index  := 2
            end
            else begin
              Result := 'New country!!';
              index  := 1
            end
          end
        end
      end
    except
      on E : Exception do
        Writeln(E.Message)
    end
    finally
      Q.Close;
      trQ.Rollback
    end
  finally
    LeaveCriticalsection(csDX)
  end
end;

function TdmDXCluster.IsException(call : String) : Boolean;

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


function TdmDXCluster.Explode(const cSeparator, vString: String): TExplodeArray;
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


function TdmDXCluster.NaselCountry(znacka : String; datum : TDateTime; var pfx, country,
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
    cont     := sez2^.znacka_popis_ex(x,1);
    Result   := True;
    if not TryStrToInt(sAdif,ADIF) then
      ADIF := 0;
    exit
  end
  else begin
    pfx := '!';
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
    cont     := uhej^.znacka_popis_ex(x,1);
    Result   := True;
    if not TryStrToInt(sAdif,ADIF) then
      ADIF := 0;
  end
  else begin
    pfx := '!';
  end
end;

function TdmDXCluster.NaselCountry(znacka : String; datum : TDateTime; var ADIF : Integer;presne : Integer = NotExactly) : Boolean;
var
  pfx,cont,country,itu,waz,posun,lat,long : String;
begin
  cont := '';WAZ := '';posun := '';ITU := '';lat := '';long := '';pfx := '';
  Country := '';
  Result := NaselCountry(znacka,datum,pfx,cont,country,itu,waz,
            posun,lat,long,adif,presne);
end;



function TdmDXCluster.CoVyhodnocovat(znacka : String; datum : TDateTime; var UzNasel : Boolean;var ADIF : Integer) : String;
var
  Pole  : TExplodeArray;
  pocet : Integer;
  pred_lomitkem : String;
  za_lomitkem   : String;
  mezi_lomitky  : String;
  tmp : Integer;
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
           if ((TryStrToInt(za_lomitkem,tmp)) and (Length(za_lomitkem)>1)) then
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
           if (((za_lomitkem[1]='M') and (za_lomitkem[2]='M')) or (za_lomitkem='AM')) then //nevim kde je
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
                  (pred_lomitkem[1] = 'K') or (pred_lomitkem[1] = 'W') or (pred_lomitkem[1] = 'N'))   then  //KL7AA/1 = W1
                 Result := 'W'+za_lomitkem
               else begin
                 pred_lomitkem[3] := za_lomitkem[1];
                 Result := pred_lomitkem;
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
                 //exit
               end
               else begin
                 UzNasel := True;
                 Result  := za_lomitkem;
                 exit
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

function TdmDXCluster.id_country(znacka : String; Datum : TDateTime; var pfx,country,waz,itu,cont : String) : Word;
var
  posun, lat, long: string;
begin
  EnterCriticalsection(csDX);
  try
    cont := '';WAZ := '';posun := '';ITU := '';lat := '';long := '';
    Result := id_country(znacka,datum,pfx,cont,country,itu,waz,posun,lat,long)
  finally
    LeaveCriticalsection(csDX)
  end
end;

function TdmDXCluster.id_country(znacka : String; Datum : TDateTime; var pfx,country,waz,itu,cont,lat,long : String) : Word;
var
  posun : string;
begin
  EnterCriticalsection(csDX);
  try
    cont := '';WAZ := '';posun := '';ITU := '';lat := '';long := '';
    Result := id_country(znacka,datum,pfx,cont,country,itu,waz,posun,lat,long)
  finally
    LeaveCriticalsection(csDX)
  end
end;

function TdmDXCluster.id_country(znacka : String;var lat,long : String): Word;
var
  posun : String;
  cont  : String;
  WAZ   : String;
  ITU   : String;
  pfx   : String;
  country : String;
begin
  EnterCriticalsection(csDX);
  try
    cont := '';WAZ := '';posun := '';ITU := '';lat := '';long := '';
    Result := id_country(znacka,now,pfx,cont,country,itu,waz,posun,lat,long)
  finally
    LeaveCriticalsection(csDX)
  end
end;

function TdmDXCluster.id_country(znacka: string;datum : TDateTime; var pfx, cont, country, WAZ,
  posun, ITU, lat, long: string) : Word;
var
  ADIF   : Integer;
  UzNasel : Boolean;
  sdatum : String;
  NoDXCC : Boolean;
  x :longint;
  sZnac : string_mdz;
  sADIF : String;
begin
  EnterCriticalsection(csDX);
  try
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
  finally
    LeaveCriticalsection(csDX)
  end
end;

function TdmDXCluster.GetBandFromFreq(freq : string; kHz : Boolean=false): String;
var
  x: Integer;
  tmp : Currency;
  dec  : Currency;
  band : String;
begin
  EnterCriticalsection(csDX);
  try
    Result := '';
    band := '';
    if Pos('.',freq) > 0 then
      freq[Pos('.',freq)] := DecimalSeparator;

    if pos(',',freq) > 0 then
      freq[pos(',',freq)] := DecimalSeparator;

    if not TextToFloat(PChar(trim(freq)),tmp, fvCurrency) then
      exit;

    if kHz then
      tmp := tmp/1000;

    if tmp < 1 then
    begin
      dec := Int(frac(tmp) * 1000);
      if ((dec >= 133) and (dec <= 139))  then
        Result := '2190M';
      exit
    end;
    x := trunc(tmp);

    case x of
      1 : Band := '160M';
      3 : band := '80M';
      5 : band := '60M';
      7 : band := '40M';
      10 : band := '30M';
      14 : band := '20M';
      18 : Band := '17M';
      21 : Band := '15M';
      24 : Band := '12M';
      28..30 : Band := '10M';
      50..53 : Band := '6M';
      70..72 : Band := '4M';
      144..146 : Band := '2M';
      219..225 : Band := '1.25M';
      430..440 : band := '70CM';
      900..929 : band := '33CM';
      1240..1300 : Band := '23CM';
      2300..2450 : Band := '13CM';  //12 cm
      3400..3475 : band := '9CM';
      5650..5850 : Band := '6CM';

      10000..10500 : band := '3CM';
      24000..24250 : band := '1.25CM';
      47000..47200 : band := '6MM';
      76000..84000 : band := '4MM';
    end;
    Result := band
  finally
    LeaveCriticalsection(csDX)
  end
end;

function TdmDXCluster.LetterFromMode(mode : String) : String;
begin
  EnterCriticalsection(csDX);
  try
    if (mode = 'CW') or (mode = 'CWQ') then
      result := 'C'
    else begin
      if (mode = 'FM') or (mode = 'SSB') or (mode = 'AM') then
        result := 'F'
      else
        result := 'D';
    end;
  finally
    LeaveCriticalsection(csDX)
  end
end;

procedure TdmDXCluster.DataModuleCreate(Sender: TObject);
var
  i : Integer;
begin
  InitCriticalSection(csDX);
  if dmData.MySQLVersion < 5.5 then
    dbDXC := TMySQL51Connection.Create(self)
  else
    dbDXC := TMySQL55Connection.Create(self);

  for i:=0 to ComponentCount-1 do
  begin
    if Components[i] is TSQLQuery then
      (Components[i] as TSQLQuery).DataBase := dbDXC;
    if Components[i] is TSQLTransaction then
      (Components[i] as TSQLTransaction).DataBase := dbDXC
  end;

  chy1 := new(Pchyb1,init);
  sez1 := new(Pseznam,init(dmData.HomeDir + 'dxcc_data/country.tab',chy1));
  uhej := sez1;
  sez2 := new(Pseznam,init(dmData.HomeDir + 'dxcc_data/country_del.tab',chy1));

  qBands.SQL.Text := 'SELECT * FROM bands ORDER BY b_begin';
  qDXCCRef.SQL.Text  := 'SELECT * FROM dxcc_ref ORDER BY adif';

  for i:=0 to MaxCall-1 do
    dxCallArray[i] := dmData.CallArray[i]
end;

procedure TdmDXCluster.DataModuleDestroy(Sender: TObject);
begin
  dispose(sez1,done);
  dispose(sez2,done);
  dbDXC.Connected := False;
  DoneCriticalsection(csDX)
end;

procedure TdmDXCluster.Q1BeforeOpen(DataSet: TDataSet);
begin
  if dmData.DebugLevel>=1 then Writeln(Q1.SQL.Text)
end;

procedure TdmDXCluster.qBandsBeforeOpen(DataSet: TDataSet);
begin
  if dmData.DebugLevel>=1 then Writeln(qBands.SQL.Text)
end;

procedure TdmDXCluster.QBeforeOpen(DataSet: TDataSet);
begin
  if dmData.DebugLevel>=1 then Writeln(Q.SQL.Text)
end;

procedure TdmDXCluster.qDXCCRefBeforeOpen(DataSet: TDataSet);
begin
  if dmData.DebugLevel>=1 then Writeln(qDXCCRef.SQL.Text)
end;

procedure TdmDXCluster.AddToMarkFile(prefix,call : String;sColor : Integer;Max,lat,long : String);
var
  l        : TStringList;
  iMax     : Integer;
  i        : Integer;
  clat,clong : Currency;
  stColor  : String = '';
  tmp      : String;
begin
  EnterCriticalsection(csDX);
  try
    if  cqrini.ReadBool('xplanet','UseDefColor',True) then
      sColor := cqrini.ReadInteger('xplanet','color',clWhite);
    iMax      := cqrini.ReadInteger('xplanet','LastSpots',20);
    if cqrini.ReadInteger('xplanet','ShowFrom',0) > 0 then exit;
    dmUtils.GetRealCoordinate(lat,long,clat,clong);
    stColor := IntToHex(sColor,8);
    stColor := '0x'+Copy(stColor,3,Length(stColor)-2);
    tmp := CurrToStr(clat)+' '+CurrToStr(clong)+' "'+call+'" color='+stColor;
    l := TStringList.Create;
    l.Clear;
    if FileExists(dmData.HomeDir + 'xplanet'+PathDelim+'marker') then
      l.LoadFromFile(dmData.HomeDir + 'xplanet'+PathDelim+'marker');
    try
      for i:= 0 to l.Count-1 do
      begin
        if Pos('"'+call+'"',l.Strings[i]) > 0 then
        begin
          l.Delete(i);
          break
        end
      end;
      l.Add(tmp);
      if l.Count > iMax then
      begin
        iMax := l.Count - iMax; // how many lines to delete?
        for i:= 0 to iMax-1 do
          l.Delete(i)
      end;
      try
        l.SaveToFile(dmData.HomeDir + 'xplanet'+PathDelim+'marker');
      except
        on e : Exception do
          if dmData.DebugLevel >=1 then Writeln('Savig maker file failed with this message: ',e.Message)
      end
    finally
      l.Free
    end
  finally
    LeaveCriticalsection(csDX)
  end
end;

function TdmDXCluster.DateToDDXCCDate(date : TDateTime) : String;
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

procedure TdmDXCluster.ReloadDXCCTables;
begin
  EnterCriticalsection(csDX);
  try
    dispose(sez1,done);
    dispose(sez2,done);

    chy1 := new(Pchyb1,init);
    sez1 := new(Pseznam,init(dmData.HomeDir + 'dxcc_data'+PathDelim+'country.tab',chy1));
    uhej := sez1;
    sez2 := new(Pseznam,init(dmData.HomeDir + 'dxcc_data'+PathDelim+'country_del.tab',chy1));
    LoadDXCCRefArray
  finally
    LeaveCriticalsection(csDX)
  end
end;

function TdmDXCluster.UsesLotw(call : String) : Boolean;
var
  i : Integer;
  h : Integer;
begin
  EnterCriticalsection(csDX);
  try
    Result := False;
    if call = '' then
      exit;
    call := dmUtils.GetIDCall(UpperCase(call));
    for i:=0 to MaxCall-1 do
    begin
      if dxCallArray[i] = '' then
        Break;
      h := Ord(dxCallArray[i][1]);
      if h = Ord(Call[1]) then
      begin
        if dxCallArray[i] = call then
        begin
          if dmData.DebugLevel>=1 then Writeln('Found - '+dxCallArray[i]);
          Result := True;
          Break
        end
      end
      else begin
        if h > Ord(Call[1]) then
        begin
          if dmData.DebugLevel>=1 then Writeln('NOT found - '+dxCallArray[i]);
          Break
        end
      end
    end
  finally
    LeaveCriticalsection(csDX)
  end
end;

function TdmDXCluster.UseseQSL(call : String) : Boolean;
var
  l : Integer;
  r : Integer;
  i : Integer;
begin
  EnterCriticalsection(csDX);
  try
    Result := False;
    l := 0;
    r := Length(dmData.eQSLUsers);
    repeat
      i := (l+r) div 2;
      if call < dmData.eQSLUsers[i] then
        r := i-1
      else
        l := i+1;
    until (call = dmData.eQSLUsers[i]) or (r<l);
    if call = dmData.eQSLUsers[i] then
      Result := True
  finally
    LeaveCriticalsection(csDX)
  end
end;

procedure TdmDXCluster.LoadDXCCRefArray;
var
  adif : Integer;
begin
  EnterCriticalsection(csDX);
  try
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
  finally
    LeaveCriticalsection(csDX)
  end
end;

function TdmDXCluster.PfxFromADIF(adif : Word) : String;
begin
    EnterCriticalsection(csDX);
  try
    Result := DXCCRefArray[adif].pref
  finally
    LeaveCriticalsection(csDX)
  end
end;

function TdmDXCluster.CountryFromADIF(adif : Word) : String;
begin
  EnterCriticalsection(csDX);
  try
    Result := DXCCRefArray[adif].name
  finally
    LeaveCriticalsection(csDX)
  end
end;

procedure TdmDXCluster.LoadExceptionArray;
var
  f    : TextFile;
  s    : String;
begin
  EnterCriticalsection(csDX);
  try
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
  finally
    LeaveCriticalsection(csDX)
  end
end;

initialization
  {$I dDXCluster.lrs}

end.

