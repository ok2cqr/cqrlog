unit fBandMap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  jakozememo,lclproc, Math;

type
  TBandMapClick = procedure(Sender:TObject;Call,Mode : String; Freq : Currency) of object;

const
  MAX_ITEMS = 200;
  DELTA_FREQ = 0.3; //freq (kHz) tolerance between radio freq and freq in bandmap
  CURRENT_STATION_CHAR = '|'; //this character will be placed before the bandmap item when the radio freq is close enough
  ITEM_SEP = '|'; //separator used with bandmap items stored in a file

type
  TBandMapItem =  record
    Freq      : Double;
    Call      : String[30];
    Mode      : String[10];
    Band      : String[10];
    SplitInfo : String[20];
    Lat       : Double;
    Long      : Double;
    Color     : LongInt;
    BgColor   : LongInt;
    TimeStamp : TDateTime;
    Flag      : String[1];
    TextValue : String[80];
    FrmNewQSO : Boolean;
    Position  : Word;
  end;

type
  TBandMapThread = class(TThread)
  protected
    function  IncColor(AColor: TColor; AQuantity: Byte) : TColor;
    procedure Execute; override;
end;

type

  { TfrmBandMap }

  TfrmBandMap = class(TForm)
    Panel1: TPanel;
    pnlBandMap: TPanel;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    BandMap  : TJakoMemo;
    BandMapItemsCount : Word;
    BandMapCrit : TRTLCriticalSection;
    RunXplanetExport : Integer;

    FFirstInterval  : Word;
    FSecondInterval : Word;
    FDeleteAfter    : Word;
    FBandFilter     : String;
    FModeFilter     : String;
    FCurrentFreq    : Currency;
    FCurrentMode    : String;
    FCurrentBand    : String;
    FBandMapClick   : TBandMapClick;
    FOnlyCurrMode   : Boolean;
    FOnlyCurrBand   : Boolean;
    FxplanetFile    : String;
    FxplanetExport  : Boolean;
    NewAdded        : Boolean;

    procedure SortBandMapArray(l,r : Integer);
    procedure BandMapDbClick(where:longint;mb:TmouseButton;ms:TShiftState);
    procedure EmitBandMapClick(Sender:TObject;Call,Mode : String; Freq : Currency);
    procedure ClearAll;
    procedure xplanetExport;
    procedure DeleteFromArray(index : Integer);

    function FindFirstEmptyPos : Word;
    function FormatItem(freq : Double; Call, SplitInfo : String; fromNewQSO : Boolean) : String;
    function SetSizeLeft(Value : String;Len : Integer) : String;
    function GetIndexFromPosition(ItemPos : Word) : Integer;
    function ItemExists(call,band,mode: String) : Integer;
  public
    BandMapItems  : Array [1..MAX_ITEMS] of TBandMapItem;
    BandMapThread : TBandMapThread;

    //after XX seconds items get older
    property FirstInterval  : Word write FFirstInterval;
    property SecondInterval : Word Write FSecondInterval;
    property DeleteAfter    : Word write FDeleteAfter;
    property BandFilter     : String write FBandFilter;
    property ModeFilter     : String write FModeFilter;
    property CurrentFreq    : Currency write FCurrentFreq;
    property CurrentBand    : String write FCurrentBand;
    property CurrentMode    : String write FCurrentMode;
    property OnlyCurrMode   : Boolean write FOnlyCurrMode;
    property OnlyCurrBand   : Boolean write FOnlyCurrBand;
    property xplanetFile    : String write FxplanetFile;
    property DoXplanetExport: Boolean write FxplanetExport;
    property OnBandMapClick : TBandMapClick read FBandMapClick write FBandMapClick;
                            //Freq in kHz
    procedure AddToBandMap(Freq : Double; Call, Mode, Band, SplitInfo : String; Lat,Long : Double; ItemColor, BgColor : LongInt;
                           fromNewQSO : Boolean=False);
    procedure DeleteFromBandMap(call, mode, band : String);
    procedure SyncBandMap;
    procedure LoadFonts;
    procedure SaveBandMapItemsToFile(FileName : String);
    procedure LoadBandMapItemsFromFile(FileName : String);
  end; 

var
  frmBandMap: TfrmBandMap;

implementation

uses dUtils, uMyIni, dData;

{ TfrmBandMap }

procedure TfrmBandMap.AddToBandMap(Freq : Double; Call, Mode, Band, SplitInfo : String; Lat,Long : Double; ItemColor, BgColor : LongInt;
                                   fromNewQSO : Boolean=False);
var
  i : Integer;
  p : Integer;
begin
  EnterCriticalSection(BandMapCrit);
  try
    if dmData.DebugLevel>=1 then Writeln('Search for:',call,',',band,',',mode);
    p := ItemExists(call,band,mode);
    if dmData.DebugLevel>=1 then Writeln('Deleted data on position:',p);
    if p>0 then
    begin
      if dmData.DebugLevel>=1 then
      begin
        Writeln('BandMapItems[p].Freq:',BandMapItems[p].Freq);
        Writeln('BandMapItems[p].Call:',BandMapItems[p].Call);
        Writeln('BandMapItems[p].Band:',BandMapItems[p].Band);
        Writeln('BandMapItems[p].Mode:',BandMapItems[p].Mode)
      end;
      DeleteFromArray(p)
    end;
    i := FindFirstemptyPos;
    if (i=0) then
    begin
      Writeln('CRITICAL ERROR: BANDMAP IS FULL');
      exit
    end;
    BandMapItems[i].frmNewQSO := fromNewQSO;
    BandMapItems[i].Freq      := Freq+Random(100)*0.000000001;
    BandMapItems[i].Call      := Call;
    BandMapItems[i].Mode      := Mode;
    BandMapItems[i].Band      := Band;
    BandMapItems[i].SplitInfo := SplitInfo;
    BandMapItems[i].Lat       := Lat;
    BandMapItems[i].Long      := Long;
    BandMapItems[i].Color     := ItemColor;
    BandMapItems[i].BgColor   := BgColor;
    BandMapItems[i].TimeStamp := now;
    BandMapItems[i].TextValue := FormatItem(Freq, Call, SplitInfo,fromNewQSO);
    BandMapItems[i].Position  := i;
    if dmData.DebugLevel>=1 then Writeln('Added to position:',i);
    frmBandMap.NewAdded := True
  finally
    LeaveCriticalSection(BandMapCrit)
  end;
  if dmData.DebugLevel>=1 then
  begin
    for i:=1 to MAX_ITEMS do
    begin
      if BandMapItems[i].Freq > 0 then
      begin
        Writeln('add:BandMapItems[',i,'].Freq:',BandMapItems[i].Freq,'*');
        Writeln('add:BandMapItems[',i,'].call:',BandMapItems[i].call,'*');
        Writeln('add:BandMapItems[',i,'].band:',BandMapItems[i].band,'*');
        Writeln('add:BandMapItems[',i,'].mode:',BandMapItems[i].mode,'*')
      end
    end
  end
end;

function TfrmBandMap.ItemExists(call,band,mode: String) : Integer;
var
  i : Integer;
begin
  Result := 0;
  for i:=1 to MAX_ITEMS do
  begin
    if (BandMapItems[i].call=call) and (BandMapItems[i].band=band) and (BandMapItems[i].mode=mode) then
    begin
      if dmData.DebugLevel>=1 then
      begin
        Writeln('Ex:BandMapItems[',i,'].Freq:',BandMapItems[i].Freq);
        Writeln('Ex:BandMapItems[',i,'].Call:',BandMapItems[i].Call);
        Writeln('Ex:BandMapItems[',i,'].Position:',BandMapItems[i].Position)
      end;
      Result := i;
      Break
    end
  end
end;

procedure TfrmBandMap.DeleteFromBandMap(call, mode, band : String);
var
  i : integer;
begin
  EnterCriticalSection(BandMapCrit);
  try
    for i:=1 to MAX_ITEMS do
    begin
      if (BandMapItems[i].Call=call) and  (BandMapItems[i].Band=band) and
         (BandMapItems[i].Mode=mode) then
        DeleteFromArray(i)
    end;
    NewAdded := True
  finally
    LeaveCriticalSection(BandMapCrit)
  end
end;

procedure TfrmBandMap.ClearAll;
begin
  BandMap.smaz_vse
end;

function TfrmBandMap.FormatItem(freq : Double; Call, SplitInfo : String; fromNewQSO : Boolean) : String;
begin
  if fromNewQSO then
    call := '*'+call;
  Result := SetSizeLeft(FloatToStrF(freq,ffFixed,8,3),12)+SetSizeLeft(call,12)+' '+ SplitInfo
end;

procedure TfrmBandMap.DeleteFromArray(index : Integer);
begin
  EnterCriticalSection(BandMapCrit);
  try
    BandMapItems[index].Freq := 0;
    BandMapItems[index].Call := '';
    BandMapItems[index].Mode := '';
    BandMapItems[index].Band := '';
    BandMapItems[index].Flag := ''
  finally
    LeaveCriticalSection(BandMapCrit)
  end
end;

procedure TfrmBandMap.SyncBandMap;
var
  i : Integer;
  s : String;
begin
  if Active then exit; //do not refresh the window when is activated (user is scrolling)
  ClearAll;
  FBandFilter := UpperCase(FBandFilter);
  FModeFilter := UpperCase(FModeFilter);
  BandMap.zakaz_kresleni(True);
  //EnterCriticalSection(BandMapCrit);
  try
    for i:=1 to MAX_ITEMS do
    begin
      if (BandMapItems[i].Freq = 0) then
        Continue;

      if (FOnlyCurrBand) and (FCurrentBand<>'') then
      begin
        if BandMapItems[i].Band<>FCurrentBand then
          Continue
      end;

      if (FOnlyCurrMode) and (FCurrentMode<>'') then
      begin
        if BandMapItems[i].Mode<>FCurrentMode then
          Continue
      end;

      if abs(FCurrentFreq-BandMapItems[i].Freq)<=DELTA_FREQ then
        s := CURRENT_STATION_CHAR + BandMapItems[i].TextValue
      else
        s := ' ' + BandMapItems[i].TextValue;
      BandMap.pridej_vetu(s,BandMapItems[i].Color,BandMapItems[i].BgColor,BandMapItems[i].Position)
    end;

    if  RunXplanetExport > 10 then //data for xplanet couln't be exported on every bandmap reload
    begin
      if FxplanetExport then //data from band map to xplanet
        xplanetExport;
      RunXplanetExport := 0
    end;
    inc(RunXplanetExport)
  finally
    //LeaveCriticalSection(BandMapCrit);
    BandMap.zakaz_kresleni(False)
  end
end;


procedure TfrmBandMap.EmitBandMapClick(Sender:TObject;Call,Mode : String; Freq : Currency);
begin
  if Assigned(FBandMapClick) then
    FBandMapClick(Self,Call,Mode,Freq)
end;

procedure TfrmBandMap.BandMapDbClick(where:longint;mb:TmouseButton;ms:TShiftState);
var
  i : Integer=0;
begin
  if (where>=0) and (where <= MAX_ITEMS-1) then
  begin
    if dmData.DebugLevel>=1 then Writeln('Clicked to:',where);
    i := GetIndexFromPosition(where);
      if dmData.DebugLevel>=1 then Writeln('Array pos: ',i);
    if i=0 then exit;
    EmitBandMapClick(Self,BandMapItems[i].Call,BandMapItems[i].Mode,BandMapItems[i].Freq)
  end;
  if dmData.DebugLevel>=1 then
  begin
    for i:=1 to MAX_ITEMS do
    begin
      if BandMapItems[i].Freq<>0 then
      begin
        Writeln('BandMapItems[',i,'].Freq:',BandMapItems[i].Freq);
        Writeln('BandMapItems[',i,'].Call:',BandMapItems[i].Call);
        Writeln('BandMapItems[',i,'].Position:',BandMapItems[i].Position)
      end
    end
  end
end;

procedure TfrmBandMap.SortBandMapArray(l,r : integer);
var
  i,j : Integer;
  w : TbandMapItem;
  x : Double;
begin
  i:=l; j:=r;
  x:=BandMapItems[(l+r) div 2].Freq;
  repeat
    while BandMapItems[i].Freq < x do i:=i+1;
    while x < BandMapItems[j].Freq do j:=j-1;
    if i <= j then
    begin
      w := BandMapItems[i];
      BandMapItems[i] := BandMapItems[j];
      BandMapItems[j] := w;
      i:=i+1; j:=j-1
    end
  until i > j;
  if l < j then SortBandMapArray(l,j);
  if i < r then SortBandMapArray(i,r)
end;

function TfrmBandMap.GetIndexFromPosition(ItemPos : Word) : Integer;
var
  i : Integer;
  s : String;
  c : TColor;
begin
  if BandMap.cti_vetu(s,c,c,i,ItemPos) then
  begin
    s := copy(s,2,Length(s)-1);
    if dmData.DebugLevel>=1 then Writeln('GetIndexFromPosition, looking for:',s);
    for i:=1 to MAX_ITEMS do
    begin
      if BandMapItems[i].TextValue=s then
      begin
        Result := i;
        break
      end
    end
  end
  else
    Result := 0
end;

function TfrmBandMap.FindFirstEmptyPos : Word;
var
  i : Integer;
begin
  Result := 0;
  for i:=MAX_ITEMS downto 1 do
  begin
    if BandMapItems[i].Freq = 0 then
    begin
      Result := i;
      Break
    end
  end
end;

procedure TBandMapThread.Execute;
var
  i : Integer;
  Changed : Boolean = False;
  When : TDateTime;
begin
  while not Terminated do
  begin
    try
      When := now;
      EnterCriticalSection(frmBandMap.BandMapCrit);
      for i:=1 to MAX_ITEMS do
      begin
        if frmBandMap.BandMapItems[i].Freq = 0 then
          Continue;

        //Writeln('Now:      ',DateTimeToStr(When));
        //Writeln('TimeStamp:',DateTimeToStr(frmBandMap.BandMapItems[i].TimeStamp));
        {Writeln('Delete:   ',DateTimeToStr(frmBandMap.BandMapItems[i].TimeStamp + (frmBandMap.FDeleteAfter/86400)));
        Writeln('Second:   ',DateTimeToStr(frmBandMap.BandMapItems[i].TimeStamp + (frmBandMap.FSecondInterval/86400)));
        Writeln('First:    ',DateTimeToStr(frmBandMap.BandMapItems[i].TimeStamp + (frmBandMap.FFirstInterval/86400)));
        Writeln('Call:     ',frmBandMap.BandMapItems[i].Call);
        Writeln('Freq:     ',FloatToStr(frmBandMap.BandMapItems[i].Freq));
        }

        //Writeln('Now:      ',DateTimeToStr(When));
        //Writeln('Delete:   ',DateTimeToStr(frmBandMap.BandMapItems[i].TimeStamp + (frmBandMap.FDeleteAfter/86400)));
        sleep(0);

        if When>(frmBandMap.BandMapItems[i].TimeStamp + (frmBandMap.FDeleteAfter/86400)) then
        begin
          //Writeln('1');
          //Writeln('Call:     ',frmBandMap.BandMapItems[i].Call);
          //Writeln('Freq:     ',FloatToStr(frmBandMap.BandMapItems[i].Freq));
          frmBandMap.DeleteFromArray(i);
          Changed := True
        end
        else if (When>(frmBandMap.BandMapItems[i].TimeStamp + (frmBandMap.FSecondInterval/86400))) and (frmBandMap.BandMapItems[i].Flag='S') then
        begin
          frmBandMap.BandMapItems[i].Color := IncColor(frmBandMap.BandMapItems[i].Color,40);
          frmBandMap.BandMapItems[i].Flag  := 'X';
          //Writeln('2');
          Changed := True
        end
        else if (When>(frmBandMap.BandMapItems[i].TimeStamp + (frmBandMap.FFirstInterval/86400))) and (frmBandMap.BandMapItems[i].Flag='') then
        begin
          frmBandMap.BandMapItems[i].Color := IncColor(frmBandMap.BandMapItems[i].Color,60);
          frmBandMap.BandMapItems[i].Flag  := 'S';
          //Writeln('3');
          Changed := True
        end
      end;
      if frmbandMap.NewAdded then
      begin
        frmBandMap.SortBandMapArray(1,MAX_ITEMS);
        frmBandMap.NewAdded := False;
        //Writeln('4');
        Changed := True
      end
    finally
      LeaveCriticalSection(frmBandMap.BandMapCrit)
    end;
    if Changed then
    begin
      Synchronize(@frmBandMap.SyncBandMap);
      Changed := False;
      //Writeln('Something has changed .... ');
    end;
    Sleep(700)
  end
end;


function TBandMapThread.IncColor(AColor: TColor; AQuantity: Byte) : TColor;
var
  R, G, B : Byte;
begin
  RedGreenBlue(ColorToRGB(AColor), R, G, B);
  R := Max(0, Integer(R) + AQuantity);
  G := Max(0, Integer(G) + AQuantity);
  B := Max(0, Integer(B) + AQuantity);
  Result := RGBToColor(R, G, B);
end;

function TfrmBandMap.SetSizeLeft(Value : String;Len : Integer) : String;
var
  i : Integer;
begin
  Result := Value;
  for i:=Length(Value) to Len-1 do
    Result := ' ' + Result
end;

procedure TfrmBandMap.FormCreate(Sender: TObject);
var
  i : Integer;
begin
  InitCriticalSection(BandMapCrit);
  RunXplanetExport    := 1;
  BandMap             := Tjakomemo.Create(pnlBandMap);
  BandMap.parent      := pnlBandMap;
  BandMap.autoscroll  := True;
  BandMap.Align       := alClient;
  BandMap.oncdblclick := @BandMapDbClick;
  BandMap.nastav_jazyk(1);
  for i:=1 to MAX_ITEMS do
      BandMapItems[i].Freq:=0;
  BandMapItemsCount := 0;
  Randomize;
  ClearAll;
  NewAdded := False;
  BandMapThread := TBandMapThread.Create(True);
  BandMapThread.Resume
end;

procedure TfrmBandMap.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmBandMap);
  if cqrini.ReadBool('BandMap', 'Save', False) then
     frmBandMap.SaveBandMapItemsToFile(dmData.HomeDir+'bandmap.csv')
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
    BandMap.nastav_font(f)
  finally
    f.Free
  end
end;

procedure TfrmBandMap.FormDestroy(Sender: TObject);
begin
  DoneCriticalsection(BandMapCrit)
end;

procedure TfrmBandMap.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmBandMap)
end;

procedure TfrmBandMap.SaveBandMapItemsToFile(FileName : String);
var
  f : TextFile;
  i : Integer;
begin
  AssignFile(f,FileName);
  try
    Rewrite(f);
    for i:=1 to MAX_ITEMS do
      Writeln(f,
        BandMapItems[i].frmNewQSO,ITEM_SEP,
        BandMapItems[i].Freq,ITEM_SEP,
        BandMapItems[i].Call,ITEM_SEP,
        BandMapItems[i].Mode,ITEM_SEP,
        BandMapItems[i].Band,ITEM_SEP,
        BandMapItems[i].SplitInfo,ITEM_SEP,
        BandMapItems[i].Lat,ITEM_SEP,
        BandMapItems[i].Long,ITEM_SEP,
        BandMapItems[i].Color,ITEM_SEP,
        BandMapItems[i].BgColor,ITEM_SEP,
        BandMapItems[i].TimeStamp,ITEM_SEP,
        BandMapItems[i].TextValue,ITEM_SEP,
        BandMapItems[i].Position,ITEM_SEP
      )
  finally
    CloseFile(f)
  end
end;

procedure TfrmBandMap.LoadBandMapItemsFromFile(FileName : String);
var
  f : TextFile;
  i : Integer=1;
  a : TExplodeArray;
  s : String;
begin
  if not FileExists(FileName) then exit;

  ClearAll;
  AssignFile(f,FileName);
  EnterCriticalSection(BandMapCrit);
  try
    Reset(f);
    while not Eof(f) do
    begin
      ReadLn(f,s);
      a := dmUtils.Explode(ITEM_SEP,s);
      if Length(a)<13 then Continue; //probably corrupted line
      i := StrToInt(a[12]);
      if (i<=0) or (i>MAX_ITEMS) then Continue;
      BandMapItems[i].frmNewQSO := StrToBool(a[0]);
      BandMapItems[i].Freq      := StrToFloat(a[1]);
      BandMapItems[i].Call      := a[2];
      BandMapItems[i].Mode      := a[3];
      BandMapItems[i].Band      := a[4];
      BandMapItems[i].SplitInfo := a[5];
      BandMapItems[i].Lat       := StrToFloat(a[6]);
      BandMapItems[i].Long      := StrToFloat(a[7]);
      BandMapItems[i].Color     := StrToInt(a[8]);
      BandMapItems[i].BgColor   := StrToInt(a[9]);
      BandMapItems[i].TimeStamp := StrToFloat(a[10]);
      BandMapItems[i].TextValue := a[11];
      BandMapItems[i].Position  := i;
      NewAdded := True
    end
  finally
    CloseFile(f);
    LeaveCriticalSection(BandMapCrit)
  end
end;

procedure TfrmBandMAp.xplanetExport;
var
  i : Integer;
  s : String;
  l : TStringList;
  xColor : String;
  UseDefaultColor : Boolean;
  DefaultColor    : Integer;
  MaxXplanetSpots : Integer;
begin
  UseDefaultColor := cqrini.ReadBool('xplanet','UseDefColor',True);
  DefaultColor    := cqrini.ReadInteger('xplanet','color',clWhite);
  MaxXplanetSpots := cqrini.ReadInteger('xplanet','LastSpots',20);

  DeleteFile(FxplanetFile);

  l := TStringList.Create;
  try
    for i:=1 to MAX_ITEMS do
    begin
      if (BandMapItems[i].Freq = 0) or (MaxXplanetSpots=0) then
        Continue;

      if (FOnlyCurrBand) and (FCurrentBand<>'') then
      begin
        if BandMapItems[i].Band<>FCurrentBand then
          Continue
      end;

      if (FOnlyCurrMode) and (FCurrentMode<>'') then
      begin
        if BandMapItems[i].Mode<>FCurrentMode then
          Continue
      end;

      if UseDefaultColor then
        xColor := IntToHex(DefaultColor,8)
      else
        xColor := IntToHex(BandMapItems[i].Color,8);
      xColor := '0x'+Copy(xColor,3,Length(xColor)-2);

      l.Add(CurrToStr(BandMapItems[i].Lat)+' '+CurrToStr(BandMapItems[i].Long)+' "'+BandMapItems[i].Call+
                      '" color='+xColor);
      dec(MaxXplanetSpots)
    end;
    l.SaveToFile(FxplanetFile)
  finally
    FreeAndNil(l)
  end
end;

{$R *.lfm}

end.

