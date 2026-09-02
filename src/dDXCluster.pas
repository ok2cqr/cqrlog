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
  mysql56dyn, mysql57dyn, mysql57conn,strutils, uDxccService;

{ TExplodeArray, TDXCCRef and NotExactly/Exactly/ExNoEquals come from
  uDxccService now -- see the note above TdmDXCluster.id_country. }

type
  { TdmDXCluster }
  TdmDXCluster = class(TDataModule)
    qBands: TSQLQuery;
    Q1: TSQLQuery;
    Q: TSQLQuery;
    qCallAlert: TSQLQuery;
    trCallAlert: TSQLTransaction;
    trQ: TSQLTransaction;
    trQ1: TSQLTransaction;
    trBands: TSQLTransaction;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure Q1BeforeOpen(DataSet: TDataSet);
    procedure qBandsBeforeOpen(DataSet: TDataSet);
    procedure QBeforeOpen(DataSet: TDataSet);
  private
    csDX : TRTLCriticalSection;

  public
    function  LetterFromMode(mode : String) : String;
    function  DXCCInfo(adif : Word;freq,mode : String; var index : integer) : String;
    function  BandModFromFreq(freq : String;var mode,band : String) : Boolean;
    function  UseseQSL(call : String) : Boolean;
    function  id_country(callsign: string;QsoDate : TDateTime; var pfx, cont, country, WAZ,
                               UtcOffset, ITU, lat, long: string) : Word; overload;
    function  id_country(callsign : String; QsoDate : TDateTime; var pfx,country,waz,itu,cont : String) : Word; overload;
    function  id_country(callsign : String; QsoDate : TDateTime; var pfx,country,waz,itu,cont,lat,long : String): Word; overload;
    function  id_country(callsign : String;var lat,long : String): Word; overload;
    function  PfxFromADIF(adif : Word) : String;
    function  CountryFromADIF(adif : Word) : String;
    function  GetBandFromFreq(freq : string; kHz : Boolean=false): String;
    function  IsAlertCall(const call,band,mode : String;RegExp :Boolean) : Boolean;

    procedure AddToMarkFile(prefix,call : String;sColor : Integer;Max,lat,long : String);
    procedure GetRealCoordinate(lat,long : String; var latitude, longitude: Currency);
    procedure RunCallAlertCmd(call,band,mode,freq,freeText : String);
    procedure GetSplitSpot(Spot:String;var call,freq,info:String);


  end;

var
  dmDXCluster: TdmDXCluster;

implementation
  {$R *.lfm}

{ TdmDXCluster }
uses dUtils, dData, dSqlUserData, dSqlRef, uMyini, fTRXControl;

{ The DXCC engine used to be duplicated here in full -- its own TDxccTable
  pair built from the same two files, its own DXCCRefArray filled by the same
  SELECT, its own copy of every resolution routine.  It now lives once in
  uDxccService and this module only delegates.

  csDX stays: it guards Q/trQ/qBands/qCallAlert on dmData.dbDXC, which three
  worker threads (TTelThread and TWebThread in fDXCluster, TRbnThread in
  fRbnMonitor) share.  That was always the real reason for the separate data
  module, and it has not changed.  The delegating lookups below do NOT take it
  -- the service has a lock of its own, and holding csDX across them would make
  RBN lookups block cluster database work for no reason. }
//no csDX: pure string work on its arguments, touches no shared state
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
    qBands.SQL.Text := dmSqlRef.SqlBandByFreqForCluster(freq);
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

function TdmDXCluster.id_country(callsign : String; QsoDate : TDateTime; var pfx,country,waz,itu,cont : String) : Word;
var
  UtcOffset, lat, long: string;
begin
  cont := '';WAZ := '';UtcOffset := '';ITU := '';lat := '';long := '';
  //declared order: the master takes (WAZ, UtcOffset, ITU).  These three used to
  //be passed rotated, so waz came back holding the UTC offset, itu holding the
  //WAZ zone, and the real ITU zone was discarded into the local.
  Result := id_country(callsign,QsoDate,pfx,cont,country,waz,UtcOffset,itu,lat,long)
end;

function TdmDXCluster.id_country(callsign : String; QsoDate : TDateTime; var pfx,country,waz,itu,cont,lat,long : String) : Word;
var
  UtcOffset : string;
begin
  cont := '';WAZ := '';UtcOffset := '';ITU := '';lat := '';long := '';
  Result := id_country(callsign,QsoDate,pfx,cont,country,waz,UtcOffset,itu,lat,long)
end;

function TdmDXCluster.id_country(callsign : String;var lat,long : String): Word;
var
  UtcOffset : String;
  cont  : String;
  WAZ   : String;
  ITU   : String;
  pfx   : String;
  country : String;
begin
  cont := '';WAZ := '';UtcOffset := '';ITU := '';lat := '';long := '';
  Result := id_country(callsign,now,pfx,cont,country,waz,UtcOffset,itu,lat,long)
end;

function TdmDXCluster.id_country(callsign: string;QsoDate : TDateTime; var pfx, cont, country, WAZ,
  UtcOffset, ITU, lat, long: string) : Word;
begin
  //the cluster never has a US state to offer, so it passes an empty one; that
  //is the only thing this overload ever did differently from dDXCC's.
  Result := DxccService.IdCountry(callsign,'',QsoDate,pfx,cont,country,WAZ,UtcOffset,ITU,lat,long)
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

  //the shared engine is loaded by dmDXCC, which cqrlog.lpr creates first
  qBands.SQL.Text := dmSqlRef.SqlBandsOnClusterDb;
end;

procedure TdmDXCluster.DataModuleDestroy(Sender: TObject);
begin
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

function TdmDXCluster.PfxFromADIF(adif : Word) : String;
begin
  Result := DxccService.PfxFromAdif(adif)
end;

function TdmDXCluster.CountryFromADIF(adif : Word) : String;
begin
  Result := DxccService.CountryFromAdif(adif)
end;

//no csDX: pure arithmetic on its arguments, touches nothing shared.
//Kept only so cluster callers do not have to reach for dmUtils; the body was a
//verbatim third copy of TdmUtils.GetRealCoordinate, which AddToMarkFile above
//was already calling.
procedure TdmDXCluster.GetRealCoordinate(lat,long : String; var latitude, longitude: Currency);
begin
  dmUtils.GetRealCoordinate(lat,long,latitude,longitude)
end;

//deliberately no csDX: this spawns an external program, and holding the lock
//across it would stall every spot on whatever the user configured
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
      try
        paramList.Delimiter := ' ';
        paramList.DelimitedText := cmd;
        //a command of nothing but separators splits into no words at all, and
        //this runs on a cluster worker -- paramList[0] would take the thread down
        if paramList.Count = 0 then
        begin
          if dmData.DebugLevel>=1 then
            Writeln('AProcess.Executable: alert command is empty after splitting');
          exit
        end;
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
      finally
        paramList.Free
      end;
      if dmData.DebugLevel>=1 then Writeln('AProcess.Executable: ',AProcess.Executable,' Parameters: ',AProcess.Parameters.Text);
      AProcess.Execute
    finally
      AProcess.Free
    end
  end
end;

function TdmDXCluster.IsAlertCall(const call,band,mode : String;RegExp :Boolean) : Boolean;
begin
  Result := False;
  //qCallAlert/trCallAlert live on dbDXC, and this is reached from TTelThread
  //and TWebThread while TRbnThread may be issuing its own queries on the same
  //connection.  It never took the lock; that was a live race on one MySQL handle.
  EnterCriticalsection(csDX);
  try
    if RegExp then
       qCallAlert.SQL.Text := dmSqlUserData.SqlCallAlertRegExp(call)
    else
      qCallAlert.SQL.Text := dmSqlUserData.SqlCallAlert(call);
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
    LeaveCriticalsection(csDX)
  end
end;


end.

