(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fBandMap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, inifiles, process, lcltype, buttons, dynlibs, jakozememo, dbf,
  memds, SdfData, ComCtrls, ActnList, SyncObjs, lclproc;

  type
    TBandThread = class(TThread)
    protected
      procedure Execute; override;
  end;

type
  { TfrmBandMap }
  TfrmBandMap = class(TForm)
    MemDataset1: TMemDataset;
    pnlBandMap: TPanel;
    tmrClick: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure acPreferencesExecute(Sender: TObject);
    procedure tmrClickTimer(Sender: TObject);
  private
    BandMap  : TJakoMemo;
    AddList  : TStringList;
    ShowList : TStringList;
    db       : Tdbf;
    dbClick  : Boolean;
    procedure SavePositions;
    procedure ClearAll;
    procedure BandMapDbClick(where:longint;mb:TmouseButton;ms:TShiftState);
  public
    AddCrit  : TRTLCriticalSection;
    ShowCrit : TRTLCriticalSection;
    BandThRun : Boolean;
    pBand : String;
    pMode : String;
    pOnlyActiveBand : Boolean;
    pOnlyActiveMode : Boolean;
    SyncList : TStringList;
    BandThread : TBandThread;

    procedure AddFromNewQSO(pfx, call : String; vfoa : Double; band, mode,lat,long : String);
    procedure AddFromDXCluster(call, mode, pfx,band, lat, long : String;vfo_a : double; colo,BckColor : LongInt; splitstr : String);
    procedure DeleteFromBandMap(call,band,mode : String);
    procedure LoadFonts;
    procedure SynBandMap;
  end;



var
  frmBandMap: TfrmBandMap;

implementation

{ TfrmBandMap }

uses dUtils, dData, fPreferences, fNewQSO, dDXCluster, fTRXControl, fTestMain,
     uMyIni;

procedure TBandThread.Execute;
type
  TExplodeArray = Array of String;

  function Explode(const cSeparator, vString: String): TExplodeArray;
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

  procedure GetRealCoordinate(lat,long : String; var latitude, longitude: Currency);
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
      s[pos('.',s)] := DecimalSeparator;
    if not TryStrToCurr(s,latitude) then
      latitude := 0;

    if d[Length(d)] = 'W' then
      d := '-' + d ;
    d := copy(d,1,Length(d)-1);
    if pos('.',d) > 0 then
      d[pos('.',d)] := DecimalSeparator;
    if not TryStrToCurr(d,longitude) then
      longitude := 0
  end;


var
  dbf : Tdbf;
  First  : TDateTime;
  Second : TDateTime;
  disep  : TDateTime;
  go     : Boolean = False;
  old_band : String = '';
  old_mode : String = '';
  p        : TExplodeArray;
  tmp      : String = '';
  dbtime   : TDateTime;
  l        : TStringList;
  iMax     : Integer;
  i        : Integer;
  clat,clong : Currency;
  stColor  : String = '';
  ToBandMap : Boolean = False;
  sColor : Integer = 0;
begin
  dbf           := TDbf.Create(nil);
  dbf.FilePath  := dmData.HomeDir;
  dbf.TableName := 'bandmap.dat';
  dbf.Open;
  dbf.IndexName := 'vfo_a';
  SetLength(p,0);
  dbf.First;
  l := TStringList.Create;
  while (not Terminated) do
  begin
    First  := cqrini.ReadInteger('BandMap','FirstAging',5)/1440;
    Second := cqrini.ReadInteger('BandMap','SecondAging',8)/1440;
    Disep  := cqrini.ReadInteger('BandMap','Disep',12)/1440;
    if  cqrini.ReadBool('xplanet','UseDefColor',True) then
      sColor := cqrini.ReadInteger('xplanet','color',clWhite);
    ToBandMap := cqrini.ReadInteger('xplanet','ShowFrom',0) > 0;
    iMax      := cqrini.ReadInteger('xplanet','LastSpots',20);

    EnterCriticalSection(frmBandMap.AddCrit);
    try
      while (frmBandMap.AddList.Count <> 0) do
      begin
        frmBandMap.ShowList.Add(frmBandMap.AddList.Strings[0]);
        if dmData.DebugLevel>=2 then
          Writeln('ShowList.Add:',frmBandMap.AddList.Strings[0]);
        frmBandMap.AddList.Delete(0);
      end
    finally
      LeaveCriticalSection(frmBandMap.AddCrit)
    end;
{
      0  Add('vfo_a', ftFloat);
      1  Add('Call', ftString, 20);
      2  Add('vfo_b', ftFloat);
      3  Add('split',ftBoolean);
      4  Add('color',ftLargeint);
      5  Add('mode',ftString,8);
      6  Add('band',ftString,6);
      7  Add('time',ftDateTime);
      8  Add('age', ftString,1);
      9  Add('pfx',ftString,10);
      10 Add('lat',ftString,10);
      11 Add('long',ftString,10);
      12 Add('id', ftAutoInc);
      13 Add('bckColor',ftLargeInt);

    //vfoa+'|'+call+'|'+mode+'|'+pfx+'|'+lat+'|'+long+'|'+IntToStr(iColor)+'|'+band

}
    Go := False;
    while frmBandMap.ShowList.Count <> 0 do
    begin
      Go := False;
      p := Explode('|',frmBandMap.ShowList.Strings[0]);
      dbf.First;
      while not dbf.Eof do
      begin             //call                          //band
        if ((dbf.Fields[1].AsString = p[1]) and (dbf.Fields[6].AsString = p[7]) and
           (dbf.Fields[5].AsString  = p[2])) then   //mode
        begin
          dbf.Edit;
          dbf.Fields[0].AsFloat    := StrToFloat(p[0]); //freq
          dbf.Fields[7].AsDateTime := now;
          dbf.Fields[4].AsInteger  := StrToInt(p[6]);
          dbf.Fields[8].AsString   := 'F';
          dbf.Fields[6].AsString   := p[7];
          dbf.Fields[14].AsString  := p[9];
          dbf.Post;
          frmBandMap.ShowList.Delete(0);
          Go := True;
          Break
        end;
        dbf.Next
      end;
      if Go then
        Continue;
      dbf.Append;
      dbf.Fields[0].AsFloat    := StrToFloat(p[0]); //freq
      dbf.Fields[1].AsString   := p[1];             //call
      dbf.Fields[4].AsInteger  := StrToInt(p[6]);   //color
      dbf.Fields[9].AsString   := p[3];             //pfx
      dbf.Fields[5].AsString   := p[2];             //mode
      dbf.Fields[10].AsString  := p[4];             //lat
      dbf.Fields[11].AsString  := p[5];             //long
      dbf.Fields[7].AsDateTime := now;              //time
      dbf.Fields[8].AsString   := 'F';
      dbf.Fields[6].AsString   := p[7];             //band
      dbf.Fields[13].AsInteger := StrToInt(p[8]);   //background color
      dbf.Fields[14].AsString  := p[9];             //split
      dbf.Post;
      frmBandMap.ShowList.Delete(0)
    end;
    dbf.Filtered := False;
    dbf.First;
    while not dbf.Eof do
    begin
      dbtime := dbf.Fields[7].AsDateTime;
      if now > dbtime+disep then
      begin
        dbf.Delete;
        Continue
      end
      else begin
        if (now >= Second+dbtime) and (dbf.Fields[8].AsString='S')  then
        begin
          dbf.Edit;
          dbf.Fields[4].AsLongInt := dmUtils.IncColor(dbf.Fields[4].AsLongint,60);
          dbf.Fields[8].AsString  :='X';
          dbf.Post
        end
        else begin
          if (now >= First+dbtime) and (dbf.Fields[8].AsString='F') then
          begin
            dbf.Edit;
            dbf.Fields[4].AsLongInt := dmUtils.IncColor(dbf.Fields[4].AsLongint,40);
            dbf.Fields[8].AsString  := 'S';
            dbf.Post
          end
        end
      end;
      dbf.Next
    end;
    if frmTRXControl.GetModeBand(old_mode,old_band) then
    begin
      dbf.Filter := '';
      tmp := '';
      if frmBandMap.pOnlyActiveMode then
        tmp := 'mode = ' + QuotedStr(old_mode);
      if frmBandMap.pOnlyActiveBand then
      begin
        if tmp = '' then
          tmp := 'band = ' + QuotedStr(old_band)
        else
          tmp := tmp + ' and band = ' + QuotedStr(old_band);
      end;
      if tmp <> '' then
      begin
        dbf.Filter   := tmp;
        dbf.Filtered := True
      end
    end;
    dbf.First;
    l.Clear;
    i := 0;
    frmBandMap.SyncList.Clear;
    while not dbf.Eof do
    begin
      tmp   := dmUtils.SetSizeLeft(FloatToStrF(dbf.Fields[0].AsFloat,ffFixed,8,3),8) +
               dmUtils.SetSizeLeft(dbf.Fields[1].AsString,14) + ' ' + dbf.Fields[14].AsString;
      frmBandMap.SyncList.Add(tmp+'|'+IntToStr(dbf.Fields[4].AsLongint)+'|'+IntToStr(dbf.Fields[13].AsLongint));
      if ToBandMap and (i <= iMax) then
      begin
        GetRealCoordinate(dbf.Fields[10].AsString,dbf.Fields[11].AsString,clat,clong);
        stColor := IntToHex(sColor,8);
        stColor := '0x'+Copy(stColor,3,Length(stColor)-2);
       // if l.Count <= iMax then
        l.Add(CurrToStr(clat)+' '+CurrToStr(clong)+' "'+dbf.Fields[1].AsString+'" color='+stColor);
        inc(i)
      end;
      dbf.Next
    end;
    if ToBandMap then
    begin
      try
        l.SaveToFile(dmData.HomeDir + 'xplanet/marker');
      except
        on e : Exception do
          if dmData.DebugLevel >=1 then Writeln('Savig maker file failed with this message: ',e.Message)
      end
    end;
    dbf.Filtered := False;
    Synchronize(@frmBandMap.SynBandMap);
    Sleep(500)
  end
end;

procedure TfrmBandMap.SynBandMap;
var
  tmp     : String;
  colo    : String;
  p       : TExplodeArray;
begin
  if not Active then
  begin
    BandMap.zakaz_kresleni(true);
    BandMap.smaz_vse;
    try
      while SyncList.Count <> 0 do
      begin
        tmp := SyncList.Strings[0];
        SyncList.Delete(0);
        p    := dmUtils.Explode('|',tmp);
        BandMap.pridej_vetu(p[0],StrToInt(p[1]),StrToInt(p[2]),0)
      end
    finally
      BandMap.zakaz_kresleni(False)
    end
  end
end;

procedure TfrmBandMap.LoadFonts;
var
  f      : TFont;
begin
  dmUtils.LoadFontSettings(self);
  f := TFont.Create;
  try
    f.Name := cqrini.ReadString('BandMap','BandFont','Monospace');
    f.Size := cqrini.ReadInteger('BandMap','FontSize',8);
    BandMap.nastav_font(f);
  finally
    f.Free
  end
end;

procedure TfrmBandMap.SavePositions;
begin
end;

procedure TfrmBandMap.FormCreate(Sender: TObject);
begin
  InitCriticalSection(AddCrit);
  InitCriticalSection(ShowCrit);
  AddList  := TStringList.Create;
  ShowList := TStringList.Create;
  SyncList := TStringList.Create;
  db       := TDbf.Create(nil);
  db.TableName := 'bandmap.dat';
  db.FilePath  := dmData.HomeDir;
  BandMap             := Tjakomemo.Create(pnlBandMap);
  BandMap.parent      := pnlBandMap;
  BandMap.autoscroll  := True;
  BandMap.Align       := alClient;
  BandMap.oncdblclick := @BandMapDbClick;
  BandMap.nastav_jazyk(1);
  ClearAll;
  BandThread := TBandThread.Create(True);
end;

procedure TfrmBandMap.FormDestroy(Sender: TObject);
begin
  if dmData.DebugLevel>=1 then Writeln('Closing BandMap window');
  BandThread.Terminate;
  ShowList.Free;
  AddList.Free;
  SyncList.Free;
  DoneCriticalsection(AddCrit);
  DoneCriticalsection(ShowCrit)
end;

procedure TfrmBandMap.FormShow(Sender: TObject);
begin
  LoadFonts;
  dmUtils.LoadWindowPos(frmBandMap);
  pOnlyActiveBand := cqrini.ReadBool('BnadMap','OnlyActiveBand', False);
  pOnlyActiveMode := cqrini.ReadBool('BandMap','OnlyActiveMode', True);
  dbClick := False;
  if BandThread.Suspended  then
    BandThread.Resume
end;


procedure TfrmBandMap.acPreferencesExecute(Sender: TObject);
begin
  with TfrmPreferences.Create(self) do
  try
    pgPreferences.ActivePage := tabBandMap;
    ShowModal
  finally
    Free
  end
end;

procedure TfrmBandMap.tmrClickTimer(Sender: TObject);
begin
  dbClick := False
end;

procedure TfrmBandMap.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmBandMap)
end;

procedure TfrmBandMap.ClearAll;
begin
  BandMap.smaz_vse;
end;

procedure TfrmBandMap.AddFromNewQSO(pfx, call : String; vfoa : Double; band, mode,lat,long : String);
var
  fra       : double;
  iColor    : Integer;
  bckColor  : Integer;
begin
  if call = '' then
    exit;
  EnterCriticalSection(AddCrit);
  try
    iColor    := cqrini.ReadInteger('BandMap','NewQSOColor',clBlack);
    if (mode = 'SSB') or (mode = 'AM') or (mode = 'FM') then
      mode := 'SSB';
    fra := vfoa*1000;

    bckColor := clWhite;

    if cqrini.ReadBool('LoTW','UseBackColor',True) then
    begin
      if dmData.UsesLotw(copy(call,2,Length(call)-1)) then
        bckColor := cqrini.ReadInteger('LoTW','BckColor',clMoneyGreen)
      else
        bckColor := clWhite
    end;

    if bckColor = clWhite then
    begin
      if cqrini.ReadBool('LoTW','eUseBackColor',True) then
        if dmData.UseseQSL(copy(call,2,Length(call)-1)) then
          bckColor := cqrini.ReadInteger('LoTW','eBckColor',clSkyBlue)
    end;

    AddList.Add(FloatToStr(fra)+'|'+call+'|'+mode+'|'+pfx+'|'+lat+'|'+long+'|'+IntToStr(iColor)+'|'+band+'|'+
                IntToStr(bckColor)+'| |');
    if dmData.DebugLevel >=2 then
       Writeln('AddList.Add:'+FloatToStr(fra)+'|'+call+'|'+mode+'|'+pfx+'|'+lat+'|'+long+'|'+IntToStr(iColor)+'|'+band+'|'+
               IntToStr(bckColor))
  finally
    LeaveCriticalSection(AddCrit)
  end
end;

procedure TfrmBandMap.AddFromDXCluster(call, mode, pfx,band, lat, long : String;vfo_a : double;Colo,BckColor : LongInt; splitstr : String);
begin

  Writeln('AddFromCluster *****');
  Writeln('Call:',call);
  Writeln('Band:',band);
  Writeln('Mode:',mode);
  Writeln('Split:',splitstr);
  Writeln('********************');

  EnterCriticalSection(AddCrit);
  try
    if (mode = 'SSB') or (mode = 'AM') or (mode = 'FM') then
      mode := 'SSB';
    AddList.Add(FloatToStr(vfo_a)+'|'+call+'|'+mode+'|'+pfx+'|'+lat+'|'+long+'|'+IntToStr(colo)+'|'+band+'|'+
                IntToStr(BckColor)+'|'+splitstr+'|' );
    if dmData.DebugLevel >=2 then
      Writeln('AddList.Add:'+FloatToStr(vfo_a)+'|'+call+'|'+mode+'|'+pfx+'|'+lat+'|'+long+'|'+IntToStr(Colo)+'|'+band+'|'+
              IntToStr(BckColor))
  finally
    LeaveCriticalSection(AddCrit)
  end
end;

procedure TfrmBandMap.BandMapDbClick(where:longint;mb:TmouseButton;ms:TShiftState);
var
  spot : String;
  tmp  : Integer;
  dbf  : TDbf;
  freq : String;
  call : String;
  f    : double;
begin
  if dbClick then
    exit;
  dbClick := True;
  BandMap.cti_vetu(spot,tmp,tmp,tmp,where);
  freq := copy(spot,1,12);
  freq := trim(freq);
  call := copy(spot,13,12);
  call := trim(call);
  if dmData.DebugLevel >= 1 then
  begin
    Writeln('Bandmap spot:',spot);
    Writeln('Bandmap freq:',freq);
    Writeln('Bandmap call:',call)
  end;
  if not TryStrToFloat(freq,f) then
    exit;
  if dmData.DebugLevel >= 1 then
  begin
    Writeln('Bandmap spot:',spot);
    Writeln('Bandmap freq:',freq);
    Writeln('Bandmap call:',call)
  end;
  dbf := TDbf.Create(nil);
  try
    f := StrToFloat(freq);
    dbf.FilePath  := dmData.HomeDir;
    dbf.TableName := 'bandmap.dat';
    dbf.Open;
    dbf.IndexName := 'vfo_a';
    dbf.Refresh;
    dbf.First;
    while not dbf.EOF do
    begin
      if dmData.DebugLevel >= 1 then
      begin
        Writeln('dbf.FieldByName(vfo_a).AsFloat:',dbf.FieldByName('vfo_a').AsFloat);
        Writeln('dbf.Fields[1].AsString:',dbf.Fields[1].AsString);
      end;
      if (dbf.FieldByName('vfo_a').AsFloat = f) and (dbf.Fields[1].AsString = call) then
      begin
        if Pos('*',call)=1 then
          call := copy(call,2,Length(call)-1);
        if dmData.ContestMode then
          frmTestMain.NewQSOFromSpot(call,freq,dbf.Fields[5].AsString)
        else
          frmNewQSO.NewQSOFromSpot(call,freq,dbf.Fields[5].AsString);
        break
      end;
      dbf.Next
    end
  finally
    dbf.Free
  end
end;

procedure TfrmBandMap.DeleteFromBandMap(call,band,mode : String);
var
  dbf : TDbf;
begin
  if not frmBandMap.Showing then
    exit;
  dbf := TDbf.Create(nil);
  try
    dbf.FilePath  := dmData.HomeDir;
    dbf.TableName := 'bandmap.dat';
    dbf.Open;
    dbf.IndexName := 'vfo_a';
    dbf.Refresh;
    dbf.First;
    while not dbf.Eof do
    begin
      if (dbf.Fields[1].AsString = call) and
         (dbf.Fields[6].AsString = band) then
        dbf.Delete
      else
       dbf.Next
    end;
    dbf.Close
  finally
    dbf.Free
  end
end;

initialization
  {$I fBandMap.lrs}

end.
