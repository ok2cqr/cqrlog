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
  mysql50conn, db, iniFiles, dateutils, FileUtil, LazFileUtils,
  uDxccService;



{ TExplodeArray, TDXCCRef, TUSStates, NotExactly/Exactly/ExNoEquals and
  MAX_STATES now live in uDxccService, which owns the engine they describe. }

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

  public
    function  IsException(call : String) : Boolean;
    function  DXCCInfo(adif : Word;freq,mode : String; var index : integer) : String;
    function  DXCCCount : Integer;
    function  DXCCCmfCount : Integer;
    function  IsAmbiguous(call : String) : Boolean;
    function  IsPrefix(pref : String; QsoDate : TDateTime) : Boolean;
    function  GetCont(call : String; QsoDate : TDateTime) : String;
    function  GetCountry(callsign : String; QsoDate : TDateTime) : String;
    function  id_country(callsign: string; us_state : String; QsoDate : TDateTime; var pfx, cont, country, WAZ,
                           UtcOffset, ITU, lat, long: string) : Word; overload;
    function  id_country(callsign: string;QsoDate : TDateTime; var pfx, cont, country, WAZ,
                               UtcOffset, ITU, lat, long: string) : Word; overload;
    function  id_country(callsign : String; QsoDate : TDateTime; var pfx,country : String) : Word; overload;
    function  id_country(callsign : String;QsoDate : TDateTime) : String; overload;
    function  AdifFromPfx(pfx : String) : Word;
    function  PfxFromADIF(adif : Word) : String;
    function  GetDelDXCCAdifList : String;

    procedure ReloadDXCCTables;
    procedure LoadDXCCRefArray;
  end;

var
  dmDXCC: TdmDXCC;

implementation
  {$R *.lfm}

{ TdmDXCC }

uses dUtils, dData, uMyIni, dSqlRef;

{ The DXCC engine itself lives in uDxccService, shared with dDXCluster.  This
  module keeps only what is bound to dmData.MainCon -- the queries, the two
  grid datasets and the log-side DXCCInfo -- and delegates every lookup.

  MyTryStrToInt used to sit here; it had no callers in either data module and
  went with the move. }


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

function TdmDXCC.DXCCInfo(adif : Word;freq,mode : String; var index : integer) : String;
//Answers whether this entity still needs a QSL.  Note the vocabulary is NOT the
//one TdmDXCluster.DXCCInfo uses -- that one grades 0..4, this one only 0 or 1.
var               // index : 0 - no QSL needed (unknown country, or confirmed)
                  // index : 1 - QSL needed (new country, or new on this band or mode)
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
  Result := DxccService.IsException(call)
end;

function TdmDXCC.id_country(callsign : String;QsoDate : TDateTime) : String;
var
  cont, WAZ, UtcOffset, ITU, lat, long, pfx, country: string;
begin
  cont := '';WAZ := '';UtcOffset := '';ITU := '';lat := '';long := '';
  Result := DxccService.PfxFromAdif(
              id_country(callsign,qsodate,pfx,cont,country,waz,UtcOffset,itu,lat,long))
end;

function TdmDXCC.id_country(callsign : String; QsoDate : TDateTime; var pfx,country : String) : Word;
var
  cont, WAZ, UtcOffset, ITU, lat, long: string;
begin
  cont := '';WAZ := '';UtcOffset := '';ITU := '';lat := '';long := '';
  Result := id_country(callsign,QsoDate,pfx,cont,country,waz,UtcOffset,itu,lat,long)
end;

function TdmDXCC.GetCountry(callsign : String; QsoDate : TDateTime) : String;
var
  cont, WAZ, UtcOffset, ITU, lat, long, pfx, country: string;
begin
  cont := '';WAZ := '';UtcOffset := '';ITU := '';lat := '';long := '';
  Result := DxccService.CountryFromAdif(
              id_country(callsign,qsodate,pfx,cont,country,waz,UtcOffset,itu,lat,long))
end;

function TdmDXCC.GetCont(call : String; QsoDate : TDateTime) : String;
//Used to return the country, not the continent, as OH1KH noted on 21-02-24.
//The cause was the argument order: id_country's 2nd and 3rd var parameters are
//(cont, country), and this passed (country, cont), so the local `cont` came
//back holding the country name.  Fixed; it returns a continent now.
var
  cont, WAZ, UtcOffset, ITU, lat, long, country, pfx: string;
begin
  cont := '';WAZ := '';UtcOffset := '';ITU := '';lat := '';long := '';
  country := ''; pfx := '';
  id_country(call,QsoDate,pfx,cont,country,waz,UtcOffset,itu,lat,long);
  Result := cont
end;


function TdmDXCC.id_country(callsign: string;QsoDate : TDateTime; var pfx, cont, country, WAZ,
  UtcOffset, ITU, lat, long: string) : Word;
begin
  Result := id_country(callsign, '', QsoDate, pfx, cont, country, WAZ, UtcOffset, ITU, lat, long)
end;

function TdmDXCC.id_country(callsign: string; us_state : String; QsoDate : TDateTime; var pfx, cont, country, WAZ,
                       UtcOffset, ITU, lat, long: string) : Word;
begin
  Result := DxccService.IdCountry(callsign,us_state,QsoDate,pfx,cont,country,WAZ,UtcOffset,ITU,lat,long)
end;

procedure TdmDXCC.DataModuleCreate(Sender: TObject);
begin
  trDXCCRef.DataBase := dmData.MainCon;
  qDXCCRef.Database  := dmData.MainCon;
  qDXCCRef.SQL.Text  := dmSqlRef.SqlDxccRefByAdifOrder;

  trQ.DataBase := dmData.MainCon;
  Q.DataBase   := dmData.MainCon;

  trQ1.DataBase := dmData.MainCon;
  Q1.DataBase   := dmData.MainCon;

  trValid.DataBase := dmData.MainCon;
  qValid.DataBase  := dmData.MainCon;

  trDeleted.DataBase := dmData.MainCon;
  qDeleted.DataBase  := dmData.MainCon;

  //after upgrade from version 1.9.1 and older, this file won't exist
  //but we need it.  Has to happen before the service reads us_states.tab.
  if not FileExistsUTF8(dmData.HomeDir + 'dxcc_data/us_states.tab') then
    CopyFile(dmData.HomeDir+'ctyfiles/us_states.tab',dmData.HomeDir + 'dxcc_data/us_states.tab');

  //dmData.DataModuleCreate has already run PrepareDXCCData, so dxcc_data/ is
  //populated by now.  dmDXCC is created before dmDXCluster (cqrlog.lpr), which
  //is why this module is the one that loads the shared engine.
  DxccService.DebugLevel := dmData.DebugLevel;
  DxccService.LoadTables(dmData.HomeDir + 'dxcc_data' + PathDelim)
end;

procedure TdmDXCC.DataModuleDestroy(Sender: TObject);
begin
  if dmData.DebugLevel >=2 then
    Writeln('End dmDXCC');

  if dmData.DebugLevel >=2 then
    Writeln('Complete end dmDXCC');
  if dmData.DebugLevel>=1 then Writeln('Closing dDXCC');
  //the engine is a unit singleton in uDxccService and frees itself
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
begin
  Result := DxccService.IsAmbiguous(call)
end;

function TdmDXCC.IsPrefix(pref : String; QsoDate : TDateTime) : Boolean;
begin
  Result := DxccService.IsPrefix(pref,QsoDate)
end;

procedure TdmDXCC.ReloadDXCCTables;
begin
  //one reload for the whole application: dDXCluster reads the same instance,
  //so it no longer has a ReloadDXCCTables of its own to keep in step
  DxccService.ReloadTables(dmData.HomeDir + 'dxcc_data' + PathDelim);
  LoadDXCCRefArray
end;

procedure TdmDXCC.LoadDXCCRefArray;
//the only piece of the engine's state that comes from the database, so this
//module reads it -- it owns a MainCon -- and pushes it into the shared service.
//dDXCluster used to run the identical SELECT on dbDXC a second time.
var
  adif : Integer;
  Ref  : TDXCCRefArray;
  Del  : TDXCCDelArray;
begin
  if trQ.Active then
    trQ.Rollback;
  Q.SQL.Text := dmSqlRef.SqlDxccRefForParser;
  try
    trQ.StartTransaction;
    Q.Open;
    Q.Last;
    SetLength(Ref,StrToInt(Q.FieldByName('adif').AsString)+1);
    SetLength(Del,0);
    Ref[0].adif := 0;
    Ref[0].pref := '';
    Q.First;
    while not Q.Eof do
    begin
      adif := StrToInt(Q.FieldByName('adif').AsString);
      Ref[adif].adif    := adif;
      Ref[adif].pref    := Q.FieldByName('pref').AsString;
      Ref[adif].name    := Q.FieldByName('name').AsString;
      Ref[adif].cont    := Q.FieldByName('cont').AsString;
      Ref[adif].utc     := Q.FieldByName('utc').AsString;
      Ref[adif].lat     := Q.FieldByName('lat').AsString;
      Ref[adif].longit  := Q.FieldByName('longit').AsString;
      Ref[adif].itu     := Q.FieldByName('itu').AsString;
      Ref[adif].waz     := Q.FieldByName('waz').AsString;
      Ref[adif].deleted := Q.FieldByName('deleted').AsInteger;
      if Ref[adif].deleted > 0 then
      begin
        SetLength(Del,Length(Del)+1);
        Del[Length(Del)-1] := adif
      end;
      Q.Next
    end;
  finally
    Q.Close;
    trQ.Rollback
  end;
  DxccService.SetDxccRef(Ref,Del)
end;

function TdmDXCC.AdifFromPfx(pfx : String) : Word;
begin
  Result := DxccService.AdifFromPfx(pfx)
end;

function TdmDXCC.PfxFromADIF(adif : Word) : String;
begin
  Result := DxccService.PfxFromAdif(adif)
end;

function TdmDXCC.GetDelDXCCAdifList : String;
begin
  Result := DxccService.DeletedAdifList
end;

end.

