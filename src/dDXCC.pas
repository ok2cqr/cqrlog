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
  mysql50conn, db, iniFiles, dateutils, FileUtil, LazFileUtils;



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
    function  GetCountry(callsign : String; QsoDate : TDateTime) : String;
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
  {$R *.lfm}

{ TdmDXCC }

uses dUtils, dData, znacmech, uMyIni,
     uDxccTable, uDxccEntry, uDxccResolver, uDxccSuffixRules, uDebugLog;

{ The DXCC engine.  TabValid/TabDeleted replace the Tseznam pair, Resolver
  replaces CoVyhodnocovat and Rules replaces the ExceptionArray scan.  See
  src/dxcc-parser/README.md for what is preserved from the old engine and why.

  znacmech is still in uses: string_mdz is what keeps the 40-character
  truncation of the search key that the old engine performed implicitly. }
var
  TabValid   : TDxccTable;
  TabDeleted : TDxccTable;
  Rules      : TDxccSuffixRules;
  Resolver   : TDxccResolver;

{ dDXCC's NotExactly/Exactly/ExNoEquals onto the table's match modes. }
function MatchMode(presne : Integer) : TDxccMatchMode;
begin
  case presne of
    Exactly    : Result := dmExact;
    ExNoEquals : Result := dmExactNoEquals;
  else
    Result := dmPrefix
  end
end;

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
begin
  Result := Rules.IsIgnoredSuffix(call)
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
  E      : TDxccEntry;
begin
  Result := False;
  sZnac  := znacka;
  sDatum  := DateToDDXCCDate(Datum);
  x := TabDeleted.Find(sZnac,sDatum,MatchMode(presne));
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
    Result   := True;
    if not TryStrToInt(sAdif,ADIF) then
      ADIF := 0;
    exit
  end
  else begin
    pfx := '!'
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
    cont     := UpperCase(E.Continent);
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
begin
  try
    Result := Resolver.EffectiveCallsign(znacka,DateToDDXCCDate(datum),UzNasel,ADIF)
  except
    on E: Exception do
    begin
      DbgLogException('DXCC','CoVyhodnocovat call=' + znacka +
                             ' date=' + DateToDDXCCDate(datum), E);
      raise
    end
  end
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

function TdmDXCC.GetCountry(callsign : String; QsoDate : TDateTime) : String;
var
  cont, WAZ, posun, ITU, lat, long, pfx, country: string;
begin
  cont := '';WAZ := '';posun := '';ITU := '';lat := '';long := '';
  Result := DXCCRefArray[id_country(callsign,qsodate,pfx,country,cont,itu,waz,posun,lat,long)].name
end;

function TdmDXCC.GetCont(call : String; Date : TDateTime) : String;
//NOTE: 21-02-24 OH1KH
//this returns country, not continent as would expect from naming!!
//result is then same as calling TdmDXCC.GetCountry function above !!
//Why?
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
  E : TDxccEntry;
begin
  Result := 0;
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
        if ((adif = 6) or (adif = 9) or (adif = 103) or (adif = 110) or (adif = 166) or (adif = 202) or (adif = 285) or (adif = 291))
           and (us_state<>'') then
        begin
          us_adif := GetStateInfo(us_state,country,lat,long,waz,itu,posun,cont);
          if us_adif > 0 then
            ADIF := us_adif
        end;
        //instrumentation: this index has never been bounds-checked
        if (adif < 0) or (adif > High(DXCCRefArray)) then
          DbgLog('DXCC','ADIF outside DXCCRefArray: adif='+IntToStr(adif)+
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
        if ((adif = 6) or (adif = 9) or (adif = 103) or (adif = 110) or (adif = 166) or (adif = 202) or (adif = 285) or (adif = 291))
           and (us_state<>'') then
        begin
          us_adif := GetStateInfo(us_state,country,lat,long,waz,itu,posun,cont);
          if us_adif > 0 then
            ADIF := us_adif
        end;
        //instrumentation: this index has never been bounds-checked
        if (adif < 0) or (adif > High(DXCCRefArray)) then
          DbgLog('DXCC','ADIF outside DXCCRefArray: adif='+IntToStr(adif)+
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

  TabValid := TDxccTable.Create;
  TabValid.LoadFromFile(dmData.HomeDir + 'dxcc_data' + PathDelim + 'country.tab');
  TabDeleted := TDxccTable.Create;
  TabDeleted.LoadFromFile(dmData.HomeDir + 'dxcc_data' + PathDelim + 'country_del.tab');
  Rules := TDxccSuffixRules.Create;
  Resolver := TDxccResolver.Create(TabValid,TabDeleted,Rules);

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
  FreeAndNil(Resolver);
  FreeAndNil(Rules);
  FreeAndNil(TabValid);
  FreeAndNil(TabDeleted)
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
var
  NewValid, NewDeleted : TDxccTable;
  OldValid, OldDeleted, OldRules, OldResolver : TObject;
begin
  //a TDxccTable is immutable once loaded, so build the replacements first and
  //only then swap the references the resolver reads.  Rules is rebuilt here as
  //well: the old engine reloaded the tables but not ExceptionArray, so a fresh
  //Exceptions.tab only took effect after a restart.
  NewValid := TDxccTable.Create;
  NewValid.LoadFromFile(dmData.HomeDir + 'dxcc_data' + PathDelim + 'country.tab');
  NewDeleted := TDxccTable.Create;
  NewDeleted.LoadFromFile(dmData.HomeDir + 'dxcc_data' + PathDelim + 'country_del.tab');

  OldResolver := Resolver;
  OldValid    := TabValid;
  OldDeleted  := TabDeleted;
  OldRules    := Rules;

  Rules := TDxccSuffixRules.Create;
  Rules.LoadExceptions(dmData.HomeDir + 'dxcc_data' + PathDelim + 'exceptions.tab');
  Rules.LoadAmbiguous(dmData.HomeDir + 'dxcc_data' + PathDelim + 'ambiguous.tab');
  TabValid   := NewValid;
  TabDeleted := NewDeleted;
  Resolver   := TDxccResolver.Create(TabValid,TabDeleted,Rules);

  OldResolver.Free;
  OldValid.Free;
  OldDeleted.Free;
  OldRules.Free;

  //same story for AmbiguousArray, which IsAmbiguous reads directly
  LoadAmbiguousArray;
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
  //ReloadDXCCTables calls this too now, and on a fresh profile the file may
  //not be there yet; TDxccSuffixRules is tolerant the same way
  if not FileExistsUTF8(dmData.HomeDir+'dxcc_data'+PathDelim+'ambiguous.tab') then
    exit;
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
begin
  Rules.LoadExceptions(dmData.HomeDir+'dxcc_data'+PathDelim+'exceptions.tab');
  //the resolver does not consume this one, but keep Rules fully populated
  Rules.LoadAmbiguous(dmData.HomeDir+'dxcc_data'+PathDelim+'ambiguous.tab')
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

end.

