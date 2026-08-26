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
  inifiles, sqldb, mysql51conn, db, mysql55conn, process, mysql56conn,
  mysql56dyn, mysql57dyn, mysql57conn,strutils;

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

type
  { TdmDXCluster }
  TdmDXCluster = class(TDataModule)
    qBands: TSQLQuery;
    Q1: TSQLQuery;
    Q: TSQLQuery;
    qCallAlert: TSQLQuery;
    qDXCCRef: TSQLQuery;
    trCallAlert: TSQLTransaction;
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
    csDX           : TRTLCriticalSection;

    function  IsException(call : String) : Boolean;
    function  CoVyhodnocovat(znacka : String; datum : TDateTime; var UzNasel : Boolean;var ADIF : Integer) : String;
    function  NaselCountry(znacka : String; datum : TDateTime; var ADIF : Integer;presne : Integer = NotExactly) : Boolean; overload;
    function  NaselCountry(znacka : String; datum : TDateTime; var pfx, country,
              cont, ITU, WAZ, posun, lat, long : String; var ADIF : Integer; presne : Integer = NotExactly) : Boolean;
    function  Explode(const cSeparator, vString: String): TExplodeArray;
    function  DateToDDXCCDate(date : TDateTime) : String;
    function  MyTryStrToInt(s : String; var i : Integer) : Boolean;

    //procedure VyhodnotZnacku(znacka : String; datum : TDateTime; var pfx, country, cont, ITU, WAZ, posun, lat, long : String);
  public
    function  LetterFromMode(mode : String) : String;
    function  DXCCInfo(adif : Word;freq,mode : String; var index : integer) : String;
    function  BandModFromFreq(freq : String;var mode,band : String) : Boolean;
    function  UseseQSL(call : String) : Boolean;
    function  id_country(znacka: string;datum : TDateTime; var pfx, cont, country, WAZ,
                               posun, ITU, lat, long: string) : Word; overload;
    function  id_country(znacka : String; Datum : TDateTime; var pfx,country,waz,itu,cont : String) : Word; overload;
    function  id_country(znacka : String; Datum : TDateTime; var pfx,country,waz,itu,cont,lat,long : String): Word; overload;
    function  id_country(znacka : String;var lat,long : String): Word; overload;
    function  PfxFromADIF(adif : Word) : String;
    function  CountryFromADIF(adif : Word) : String;
    function  GetBandFromFreq(freq : string; kHz : Boolean=false): String;
    function  IsAlertCall(const call,band,mode : String;RegExp :Boolean) : Boolean;

    procedure AddToMarkFile(prefix,call : String;sColor : Integer;Max,lat,long : String);
    procedure GetRealCoordinate(lat,long : String; var latitude, longitude: Currency);
    procedure ReloadDXCCTables;
    procedure LoadDXCCRefArray;
    procedure LoadExceptionArray;
    procedure RunCallAlertCmd(call,band,mode,freq,freeText : String);
    procedure GetSplitSpot(Spot:String;var call,freq,info:String);


  end;

var
  dmDXCluster: TdmDXCluster;

implementation
  {$R *.lfm}

{ TdmDXCluster }
uses dUtils, dData, znacmech, uMyini, fTRXControl,
     uDxccTable, uDxccEntry, uDxccResolver, uDxccSuffixRules, uDebugLog;

{ Second, independent instance of the DXCC engine.  The duplication is driven
  by the separate MySQL connection this module needs for its worker threads,
  not by the parser -- see src/dxcc-parser/README.md, "Threading".

  znacmech stays in uses for string_mdz, which preserves the 40-character
  truncation of the search key. }
var
  TabValid   : TDxccTable;
  TabDeleted : TDxccTable;
  Rules      : TDxccSuffixRules;
  Resolver   : TDxccResolver;

function MatchMode(presne : Integer) : TDxccMatchMode;
begin
  case presne of
    Exactly    : Result := dmExact;
    ExNoEquals : Result := dmExactNoEquals;
  else
    Result := dmPrefix
  end
end;
Procedure TdmDXCluster.GetSplitSpot(Spot:String;var call,freq,info:String);
var
 i,n,r : integer;
 s,t   : String;

Begin
  Spot:=trim(Spot); //to be sure
  //remove extra spaces
  repeat
    Begin
      Spot:=StringReplace(Spot,'  ',' ',[rfReplaceAll],i);
    end;
  until i=0;

  if (pos('DX DE ',UpperCase(Spot))=1) then  //normal cluster spot format
   Begin
     call :=  UpperCase(ExtractDelimited(5,Spot,[' ']));  //to be sure case
     freq :=  ExtractDelimited(4,Spot,[' ']);
     s:=trim(copy(Spot,pos(call,Spot)+length(call),length(Spot)));
     n:=0;
     r:=0;
     for i:=1 to length(s) do //find zulu time  works with telnet and web
      Begin
        if ((n=4) and (s[i]='Z')) then
         Begin
           r:= i-5;
           break;
         end;
        if (s[i] in ['0'..'9']) then
           inc(n)
         else
           n:=0;
      end;
     if (r=0) then r:=i; //r points chars before zulu time, if not found points end of s
     info := trim(copy(s,1,r));
   end
  else     //format from sh/dx command
   Begin
     call :=  UpperCase(ExtractDelimited(2,Spot,[' ']));  //to be sure  case
     freq :=  ExtractDelimited(1,Spot,[' ']);
     t    :=  ExtractDelimited(4,Spot,[' ']);  //zulu time
     s:=trim(copy(Spot,pos(t,Spot)+length(t),length(Spot)));
     i:=Rpos('<',s);
     if (i > 0) then
       info:= copy(s,1,i-1)
      else     //should not happen
       info:=s;
   end;
end;

function TdmDXCluster.MyTryStrToInt(s : String; var i : Integer) : Boolean;
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

function TdmDXCluster.BandModFromFreq(freq : String;var mode,band : String) : Boolean;
//this could be converted to use dmUtils(band vs freq array) with small modification to array, OH1KH
var
  tmp : Extended;
  cw, ssb : Extended;
  n   :String;
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
    //qBands.Last; //to get proper count
    //Writeln('qBands.RecorfdCount: ',qBands.RecordCount);
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
        Begin
          n:=IntToStr(frmTRXControl.cmbRig.ItemIndex);
          mode :=  cqrini.ReadString('Band'+n, 'Datamode', 'RTTY')
        end;
    end;

    //Writeln('TdmDXCluster.BandModFromFreq:',Result,' cw ',FloatToStr(cw),' ssb ',FloatToStr(ssb))
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
                      QuotedStr('Q')+') OR (lotw_qslr='+ QuotedStr('L')+
                      ') OR (eqsl_qsl_rcvd='+ QuotedStr('E')+')) AND mode='+
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
begin
  Result := Rules.IsIgnoredSuffix(call)
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
  E      : TDxccEntry;
begin
  Result := False;
  sZnac  := znacka;
  sDatum  := DateToDDXCCDate(Datum);
  x := TabDeleted.Find(sZnac,sDatum,MatchMode(presne));
  if x <>-1 then
  begin
    //no UpperCase on cont here, unlike dDXCC -- preserved as it was
    E        := TabDeleted.Entry(x);
    country  := E.Country;
    ITU      := E.Itu;
    WAZ      := E.Waz;
    posun    := E.UtcOffset;
    lat      := E.Latitude;
    long     := E.Longitude;
    sADIF    := E.Adif;
    cont     := E.Continent;
    Result   := True;
    if not TryStrToInt(sAdif,ADIF) then
      ADIF := 0;
    exit
  end
  else begin
    pfx := '!';
  end;

  x := TabValid.Find(sZnac,sDatum,MatchMode(presne));
  if x <>-1 then
  begin
    E        := TabValid.Entry(x);
    country  := E.Country;
    ITU      := E.Itu;
    WAZ      := E.Waz;
    posun    := E.UtcOffset;
    lat      := E.Latitude;
    long     := E.Longitude;
    sADIF    := E.Adif;
    cont     := E.Continent;
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
begin
  try
    Result := Resolver.EffectiveCallsign(znacka,DateToDDXCCDate(datum),UzNasel,ADIF)
  except
    on E: Exception do
    begin
      DbgLogException('DXC','CoVyhodnocovat call=' + znacka +
                            ' date=' + DateToDDXCCDate(datum), E);
      raise
    end
  end
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
  E : TDxccEntry;
begin
  EnterCriticalsection(csDX);
  try
   try
    sZnac := '';
    if (length(znacka)=0) then
    begin
      exit;
    end;
    UzNasel := False;
    ADIF := 0;

    sZnac := znacka;
    sZnac := CoVyhodnocovat(znacka,datum,UzNasel,ADIF);
    sDatum  := DateToDDXCCDate(Datum);// DateToStr(Datum);
    x := TabDeleted.Find(sZnac,sDatum,dmPrefix);
    if x <>-1 then
    begin
      E        := TabDeleted.Entry(x);
      country  := E.Country;
      ITU      := E.Itu;
      WAZ      := E.Waz;
      posun    := E.UtcOffset;
      lat      := E.Latitude;
      long     := E.Longitude;
      sADIF    := E.Adif;
      cont     := UpperCase(E.Continent);
      NoDXCC   := Pos('no DXCC',country) > 0;
      if TryStrToInt(sAdif,ADIF) then
      begin
        if ADIF > 0 then
        begin
          //instrumentation: this index has never been bounds-checked
          if (adif < 0) or (adif > High(DXCCRefArray)) then
            DbgLog('DXC','ADIF outside DXCCRefArray: adif='+IntToStr(adif)+
                  ' high='+IntToStr(High(DXCCRefArray))+' call='+znacka);
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

    x := TabValid.Find(sZnac,sDatum,dmPrefix);
    if x <>-1 then
    begin
      E        := TabValid.Entry(x);
      country  := E.Country;
      ITU      := E.Itu;
      WAZ      := E.Waz;
      posun    := E.UtcOffset;
      lat      := E.Latitude;
      long     := E.Longitude;
      sADIF    := E.Adif;
      cont     := UpperCase(E.Continent);
      NoDXCC   := Pos('no DXCC',country) > 0;
      if TryStrToInt(sAdif,ADIF) then
      begin
        if ADIF > 0 then
        begin
          //instrumentation: this index has never been bounds-checked
          if (adif < 0) or (adif > High(DXCCRefArray)) then
            DbgLog('DXC','ADIF outside DXCCRefArray: adif='+IntToStr(adif)+
                  ' high='+IntToStr(High(DXCCRefArray))+' call='+znacka);
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
   except
     on Ex: Exception do
     begin
       //instrumentation: names the input that killed the lookup.  If the log
       //also carries a CoVyhodnocovat line for the same callsign the splitter
       //raised; if not, it came from the table lookup or DXCCRefArray.
       DbgLogException('DXC','id_country call=' + znacka + ' key=' + sZnac +
                             ' date=' + DateToDDXCCDate(datum), Ex);
       raise
     end
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
      freq[Pos('.',freq)] := FormatSettings.DecimalSeparator;

    if pos(',',freq) > 0 then
      freq[pos(',',freq)] := FormatSettings.DecimalSeparator;

    if not TextToFloat(PChar(trim(freq)),tmp, fvCurrency) then
      exit;

    if kHz then
      tmp := tmp/1000;

    Result := dmUtils.BandFromArray(tmp);

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

  dmData.dbDXC.KeepConnection := True;
  for i:=0 to ComponentCount-1 do
  begin
    if Components[i] is TSQLQuery then
      (Components[i] as TSQLQuery).DataBase := dmData.dbDXC;
    if Components[i] is TSQLTransaction then
      (Components[i] as TSQLTransaction).DataBase := dmData.dbDXC
  end;

  TabValid := TDxccTable.Create;
  TabValid.LoadFromFile(dmData.HomeDir + 'dxcc_data' + PathDelim + 'country.tab');
  TabDeleted := TDxccTable.Create;
  TabDeleted.LoadFromFile(dmData.HomeDir + 'dxcc_data' + PathDelim + 'country_del.tab');
  Rules := TDxccSuffixRules.Create;
  Resolver := TDxccResolver.Create(TabValid,TabDeleted,Rules);

  qBands.SQL.Text := 'SELECT * FROM bands ORDER BY b_begin';
  qDXCCRef.SQL.Text  := 'SELECT * FROM dxcc_ref ORDER BY adif';
end;

procedure TdmDXCluster.DataModuleDestroy(Sender: TObject);
begin
  FreeAndNil(Resolver);
  FreeAndNil(Rules);
  FreeAndNil(TabValid);
  FreeAndNil(TabDeleted);
  dmData.dbDXC.Connected := False;
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
  stColor,
  BGRcolor : String;
  tmp      : String;
begin
  EnterCriticalsection(csDX);
  try
    if  cqrini.ReadBool('xplanet','UseDefColor',True) then
      sColor := cqrini.ReadInteger('xplanet','color',clWhite);
    iMax      := cqrini.ReadInteger('xplanet','LastSpots',20);
    //this is not needed here as check of cfgShowFrom is done already in fDXCluster !!
      //if cqrini.ReadInteger('xplanet','ShowFrom',0) > 0 then exit;
    //removing it allows "universal use"
    dmUtils.GetRealCoordinate(lat,long,clat,clong);
    BGRcolor := IntToHex(sColor,8);   //this reverses RGB to BGR !!
    stColor := '0x'
      + copy(BGRcolor,7,2)  //R
      + copy(BGRcolor,5,2)  //G
      + copy(BGRcolor,3,2); //B
    if dmData.DebugLevel >= 1 then
       Writeln('Color for xplanet:',stColor);
    tmp := CurrToStr(clat)+' '+CurrToStr(clong)+' "'+call+'" color='+stColor;
    l := TStringList.Create;
    l.Clear;
    if FileExists(dmData.HomeDir + 'xplanet'+PathDelim+'marker') then
      l.LoadFromFile(dmData.HomeDir + 'xplanet'+PathDelim+'marker');
    try
      for i:= 0 to l.Count-1 do // for loop try to find call and delete old position before adding the new
      begin
        if Pos(call,l.Strings[i]) > 0 then   //we do no need quotation marks: compares without
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
          l.Delete(0) // delete always index 0, this is always the oldest entry
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
var
  NewValid, NewDeleted : TDxccTable;
  NewRules : TDxccSuffixRules;
  OldValid, OldDeleted : TDxccTable;
  OldRules : TDxccSuffixRules;
  OldResolver : TDxccResolver;
begin
  //a TDxccTable is immutable once loaded, so build the replacements outside the
  //lock and keep the critical section down to the reference swap
  NewValid := TDxccTable.Create;
  NewValid.LoadFromFile(dmData.HomeDir + 'dxcc_data'+PathDelim+'country.tab');
  NewDeleted := TDxccTable.Create;
  NewDeleted.LoadFromFile(dmData.HomeDir + 'dxcc_data'+PathDelim+'country_del.tab');
  NewRules := TDxccSuffixRules.Create;
  NewRules.LoadExceptions(dmData.HomeDir+'dxcc_data'+PathDelim+'exceptions.tab');

  EnterCriticalsection(csDX);
  try
    OldResolver := Resolver;
    OldValid    := TabValid;
    OldDeleted  := TabDeleted;
    OldRules    := Rules;

    TabValid   := NewValid;
    TabDeleted := NewDeleted;
    Rules      := NewRules;
    Resolver   := TDxccResolver.Create(TabValid,TabDeleted,Rules);

    LoadDXCCRefArray
  finally
    LeaveCriticalsection(csDX)
  end;

  OldResolver.Free;
  OldValid.Free;
  OldDeleted.Free;
  OldRules.Free
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
begin
  EnterCriticalsection(csDX);
  try
    Rules.LoadExceptions(dmData.HomeDir+'dxcc_data'+PathDelim+'exceptions.tab')
  finally
    LeaveCriticalsection(csDX)
  end
end;

procedure TdmDXCluster.GetRealCoordinate(lat,long : String; var latitude, longitude: Currency);
var
  s,d : String;
begin
  s := lat;
  d := long;
  if ((Length(s)=0) or (Length(d)=0)) then
  begin
    longitude := 0;
    latitude  := 0;
    exit
  end;

  if s[Length(s)] = 'S' then
    s := '-' +s ;
  s := copy(s,1,Length(s)-1);
  if pos('.',s) > 0 then
    s[pos('.',s)] := FormatSettings.DecimalSeparator;
  if not TryStrToCurr(s,latitude) then
    latitude := 0;

  if d[Length(d)] = 'W' then
    d := '-' + d ;
  d := copy(d,1,Length(d)-1);
  if pos('.',d) > 0 then
    d[pos('.',d)] := FormatSettings.DecimalSeparator;
  if not TryStrToCurr(d,longitude) then
    longitude := 0;
  if dmData.DebugLevel>=4 then
  begin
    //Writeln('Lat:  ',latitude);
    //Writeln('Long: ',longitude);
  end;
end;

procedure TdmDXCluster.RunCallAlertCmd(call,band,mode,freq,freeText : String);
var
  AProcess : TProcess;
  paramList :TStringList;
  index     :integer;
  cmd      : String;
begin
  cmd := cqrini.ReadString('DXCluster', dmUtils.PlatformKey('AlertCmd'), '');

  if (cmd<>'') then
  begin
    AProcess := TProcess.Create(nil);
    try
      cmd := StringReplace(cmd,'$CALLSIGN',call,[rfReplaceAll, rfIgnoreCase]);
      cmd := StringReplace(cmd,'$BAND',band,[rfReplaceAll, rfIgnoreCase]);
      cmd := StringReplace(cmd,'$MODE',mode,[rfReplaceAll, rfIgnoreCase]);
      cmd := StringReplace(cmd,'$FREQ',freq,[rfReplaceAll, rfIgnoreCase]);
      cmd := StringReplace(cmd,'$MSG',freeText,[rfReplaceAll, rfIgnoreCase]);
      index:=0;
      paramList := TStringList.Create;
      paramList.Delimiter := ' ';
      paramList.DelimitedText := cmd;
      if not  FileExists(paramList[0]) then
       begin
         if dmData.DebugLevel>=1 then
                         Writeln('AProcess.Executable: ', paramList[0],' Not found!');
         exit;
       end;
      AProcess.Parameters.Clear;
      while index < paramList.Count do
      begin
        if (index = 0) then AProcess.Executable := paramList[index]
          else AProcess.Parameters.Add(paramList[index]);
        inc(index);
      end;
      paramList.Free;
      if dmData.DebugLevel>=1 then Writeln('AProcess.Executable: ',AProcess.Executable,' Parameters: ',AProcess.Parameters.Text);
      AProcess.Execute
    finally
      AProcess.Free
    end
  end
end;

function TdmDXCluster.IsAlertCall(const call,band,mode : String;RegExp :Boolean) : Boolean;
const
   //with complete call search %s or "call_alert/callsign" can be target. No difference.
   C_SEL = 'select * from call_alert where callsign = %s';
   //with "pertial callsigns" %s is target and column "call_alert/callsign" contains regexp condition
   C_RGX_SEL = 'select * from call_alert where %s regexp callsign';
begin
  Result := False;
  try
    if RegExp then
       qCallAlert.SQL.Text := Format(C_RGX_SEL,[QuotedStr(call)])
    else
      qCallAlert.SQL.Text := Format(C_SEL,[QuotedStr(call)]);
    if dmData.DebugLevel>=1 then Writeln('Alert: ',qCallAlert.SQL.Text);
    trCallAlert.StartTransaction;
    qCallAlert.Open;
    if qCallAlert.RecordCount > 0 then
   begin
      qCallAlert.Last; //to get proper count
      if dmData.DebugLevel>=1 then Writeln('Alert: Call hits with ', qCallAlert.RecordCount,' records');
      qCallAlert.First;
      while ( (not qCallAlert.Eof) and (not Result) ) do
      begin
        Result :=(    (qCallAlert.Fields[2].AsString=''   ) and (qCallAlert.Fields[3].AsString='')
                   or (qCallAlert.Fields[2].AsString= band) and (qCallAlert.Fields[3].AsString='')
                   or (qCallAlert.Fields[2].AsString='')    and (qCallAlert.Fields[3].AsString= mode)
                   or (qCallAlert.Fields[2].AsString= band) and (qCallAlert.Fields[3].AsString= mode)
                 );
        qCallAlert.Next
      end;
      if dmData.DebugLevel>=1 then Writeln('Alert: Mode and/or band ',Result,
                            ' Band:',qCallAlert.Fields[2].AsString,' Mode:',qCallAlert.Fields[3].AsString);
    end;
  finally
    qCallAlert.Close;
    trCallAlert.Rollback;
  end
end;


end.

