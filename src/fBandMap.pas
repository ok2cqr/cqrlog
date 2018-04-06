unit fBandMap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  uColorMemo,lclproc, Math, lcltype, ComCtrls, ActnList;

type
  TBandMapClick = procedure(Sender:TObject;Call,Mode : String; Freq : Currency) of object;

type
  TDateFilterType = (dftShowAll, dftShowLastHours, dftShowLastDateTime);

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
    isLoTW    : Boolean;
    isEQSL    : Boolean;
  end;

type
  TBandMapThread = class(TThread)
  private
    DelArray : Array of TBandMapItem;
    AddArray : Array of TBandMapItem;
    NewAdded : Boolean;

    procedure DeleteFromArray(index : Integer);

    function ItemExists(call,band,mode: String) : Integer;
    function FindFirstEmptyPos : Word;
  protected
    function  IncColor(AColor: TColor; AQuantity: Byte) : TColor;
    procedure Execute; override;
end;

type

  { TfrmBandMap }

  TfrmBandMap = class(TForm)
    acBandMap: TActionList;
    acFilter: TAction;
    acFilterSettings: TAction;
    imglBandMap: TImageList;
    Panel1: TPanel;
    pnlBandMap: TPanel;
    toolBandMap: TToolBar;
    tbtnFilter: TToolButton;
    ToolButton1: TToolButton;
    procedure acFilterExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    BandMap  : TColorMemo;
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
    FDateFilterType : TDateFilterType;
    FLastHours      : Word;
    FSinceDate      : String;
    FSinceTime      : String;
    FOnlyLoTW       : Boolean;
    FOnlyEQSL       : Boolean;

    procedure SortBandMapArray(l,r : Integer);
    procedure BandMapDbClick(where:longint;mb:TmouseButton;ms:TShiftState);
    procedure EmitBandMapClick(Sender:TObject;Call,Mode : String; Freq : Currency);
    procedure ClearAll;
    procedure xplanetExport;


    function FormatItem(freq : Double; Call, SplitInfo : String; fromNewQSO : Boolean) : String;
    function SetSizeLeft(Value : String;Len : Integer) : String;
    function GetIndexFromPosition(ItemPos : Word) : Integer;
  public
    BandMapItems  : Array [1..MAX_ITEMS] of TBandMapItem;
    BandMapThread : TBandMapThread;

    AddToBandMapArr      : Array of TBandMapItem;
    DeleteFromBandMapArr : Array of TBandMapItem;

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
    property DateFilterType : TDateFilterType write FDateFilterType;
    property LastHours      : Word write FLastHours;
    property SinceDate      : String write FSinceDate;
    property SinceTime      : String write FSinceTime;
    property OnlyLoTW       : Boolean write FOnlyLoTW;
    property OnlyEQSL       : Boolean write FOnlyEQSL;
    property OnBandMapClick : TBandMapClick read FBandMapClick write FBandMapClick;
                            //Freq in kHz
    procedure AddToBandMap(Freq : Double; Call, Mode, Band, SplitInfo : String; Lat,Long : Double; ItemColor, BgColor : LongInt;
                           fromNewQSO : Boolean=False;isLoTW : Boolean=False;isEQSL : Boolean = False);
    procedure DeleteFromBandMap(call, mode, band : String);
    procedure SyncBandMap;
    procedure LoadFonts;
    procedure LoadSettings;
    procedure SaveBandMapItemsToFile(FileName : String);
    procedure LoadBandMapItemsFromFile(FileName : String);
  end; 

var
  frmBandMap: TfrmBandMap;

implementation
{$R *.lfm}

uses dUtils, uMyIni, dData, fNewQSO, fBandMapFilter;

{ TfrmBandMap }

procedure TfrmBandMap.AddToBandMap(Freq : Double; Call, Mode, Band, SplitInfo : String; Lat,Long : Double; ItemColor, BgColor : LongInt;
                                   fromNewQSO : Boolean=False;isLoTW : Boolean=False;isEQSL : Boolean = False);
var
  i : Integer;
begin
  EnterCriticalSection(BandMapCrit);
  try
    i := Length(AddToBandMapArr);
    SetLength(AddToBandMapArr,i+1);
    AddToBandMapArr[i].frmNewQSO := fromNewQSO;
    AddToBandMapArr[i].Freq      := Freq+Random(100)*0.000000001;
    AddToBandMapArr[i].Call      := Call;
    AddToBandMapArr[i].Mode      := Mode;
    AddToBandMapArr[i].Band      := Band;
    AddToBandMapArr[i].SplitInfo := SplitInfo;
    AddToBandMapArr[i].Lat       := Lat;
    AddToBandMapArr[i].Long      := Long;
    AddToBandMapArr[i].Color     := ItemColor;
    AddToBandMapArr[i].BgColor   := BgColor;
    AddToBandMapArr[i].TimeStamp := now;
    AddToBandMapArr[i].TextValue := FormatItem(Freq, Call, SplitInfo,fromNewQSO);
    AddToBandMapArr[i].isLoTW    := isLoTW;
    AddToBandMapArr[i].isEQSL    := isEQSL;

    if dmData.DebugLevel>=1 then
      Writeln(DateTimeToStr(now), ' add to bandmap ', AddToBandMapArr[i].Call)
  finally
    LeaveCriticalSection(BandMapCrit)
  end
end;

procedure TfrmBandMap.DeleteFromBandMap(call, mode, band : String);
var
  i : integer;
begin
  EnterCriticalSection(BandMapCrit);
  try
    i := Length(DeleteFromBandMapArr);
    SetLength(DeleteFromBandMapArr,i+1);
    DeleteFromBandMapArr[i].Call := call;
    DeleteFromBandMapArr[i].Band := band;
    DeleteFromBandMapArr[i].Mode := mode
  finally
    LeaveCriticalSection(BandMapCrit)
  end
end;

procedure TfrmBandMap.ClearAll;
begin
  BandMap.RemoveAllLines
end;

function TfrmBandMap.FormatItem(freq : Double; Call, SplitInfo : String; fromNewQSO : Boolean) : String;
begin
  if fromNewQSO then
    call := '*'+call;
  Result := SetSizeLeft(FloatToStrF(freq,ffFixed,8,3),12)+SetSizeLeft(call,12)+' '+ SplitInfo
end;


procedure TfrmBandMap.SyncBandMap;
var
  i : Integer;
  s : String;
begin
  if Active then exit; //do not refresh the window when is activated (user is scrolling)
  FBandFilter := UpperCase(FBandFilter);
  FModeFilter := UpperCase(FModeFilter);
  BandMap.DisableAutoRepaint(True);
  ClearAll;
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
        if ((FCurrentMode='LSB') or (FCurrentMode='USB')) then
        begin
          if BandMapItems[i].Mode<>'SSB' then
            Continue
        end
        else begin
          if ((FCurrentMode='CW') or (FCurrentMode='CWR')) then
          begin
            if (BandMapItems[i].Mode<>'CW') and (BandMapItems[i].Mode<>'CWR') then
              Continue
          end
          else begin
            if BandMapItems[i].Mode<>FCurrentMode then
              Continue
          end
        end
      end;

      if abs(FCurrentFreq-BandMapItems[i].Freq)<=DELTA_FREQ then
        s := CURRENT_STATION_CHAR + BandMapItems[i].TextValue
      else
        s := ' ' + BandMapItems[i].TextValue;
      BandMap.AddLine(s,BandMapItems[i].Color,BandMapItems[i].BgColor,BandMapItems[i].Position)
    end;

    if  RunXplanetExport > 10 then //data for xplanet couln't be exported on every bandmap reload
    begin
      if FxplanetExport then //data from band map to xplanet
        xplanetExport;
      RunXplanetExport := 0
    end;
    inc(RunXplanetExport)
  finally
    BandMap.DisableAutoRepaint(False)
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
  Result := 0;
  if BandMap.ReadLine(s,c,c,i,ItemPos) then
  begin
    s := copy(s,2,Length(s)-1);
    if dmData.DebugLevel>=1 then Writeln('GetIndexFromPosition, looking for:',s);
    for i:= MAX_ITEMS downto 1 do
    begin
      if BandMapItems[i].TextValue=s then
      begin
        Result := i;
        break
      end
    end
  end
end;

function TBandMapThread.ItemExists(call,band,mode: String) : Integer;
var
  i : Integer;
begin
  Result := 0;
  for i:=1 to MAX_ITEMS do
  begin
    if (frmBandMap.BandMapItems[i].call=call) and (frmBandMap.BandMapItems[i].band=band) and (frmBandMap.BandMapItems[i].mode=mode) then
    begin
      if dmData.DebugLevel>=1 then
      begin
        Writeln('Ex:BandMapItems[',i,'].Freq:',frmBandMap.BandMapItems[i].Freq);
        Writeln('Ex:BandMapItems[',i,'].Call:',frmBandMap.BandMapItems[i].Call);
        Writeln('Ex:BandMapItems[',i,'].Position:',frmBandMap.BandMapItems[i].Position)
      end;
      Result := i;
      Break
    end
  end
end;

procedure TBandMapThread.DeleteFromArray(index : Integer);
begin
  frmBandMap.BandMapItems[index].Freq := 0;
  frmBandMap.BandMapItems[index].Call := '';
  frmBandMap.BandMapItems[index].Mode := '';
  frmBandMap.BandMapItems[index].Band := '';
  frmBandMap.BandMapItems[index].Flag := ''
end;

function TBandMapThread.FindFirstEmptyPos : Word;
var
  i : Integer;
begin
  Result := 0;
  for i:=MAX_ITEMS downto 1 do
  begin
    if frmBandMap.BandMapItems[i].Freq = 0 then
    begin
      Result := i;
      Break
    end
  end
end;


procedure TBandMapThread.Execute;
var
  i : Integer;
  y : Integer;
  p : Integer;
  Changed : Boolean = False;
  When : TDateTime;
  iter : Word;
  skip : Boolean = False;
  LastDate : String;
  LastTime : String;
begin
  try
    SetLength(DelArray,0);
    SetLength(AddArray,0);
    iter := 1;
    while not Terminated do
    begin
      try
        When := now;
        EnterCriticalSection(frmBandMap.BandMapCrit);
        AddArray := frmBandMap.AddToBandMapArr;
        DelArray := frmBandMap.DeleteFromBandMapArr;

        SetLength(frmBandMap.AddToBandMapArr,0);
        SetLength(frmBandMap.DeleteFromBandMapArr,0)
      finally
        LeaveCriticalSection(frmBandMap.BandMapCrit)
      end;

      if (frmBandMap.FDateFilterType = dftShowLastHours) then
      begin
        LastDate := FormatDateTime('YYY-MM-DD',when - (frmBandMap.FLastHours/24));
        LastTime := FormatDateTime('HH:NN',when - (frmBandMap.FLastHours/24))
      end
      else begin
        if (frmBandMap.FDateFilterType = dftShowLastDateTime) then
        begin
          LastDate := frmBandMap.FSinceDate;
          LastTime := frmBandMap.FSinceTime
        end
      end;

      for y:=0 to Length(AddArray)-1 do
      begin
        p := ItemExists(AddArray[y].call,AddArray[y].band,AddArray[y].mode);
        if dmData.DebugLevel>=1 then Writeln('Deleted data on position:',p);
        if p>0 then
        begin
          DeleteFromArray(p)
        end;

        skip := False;

        if not (frmBandMap.FDateFilterType = dftShowAll) then
          skip := dmData.CallExistsInLog(AddArray[y].Call,AddArray[y].Band,AddArray[y].Mode,LastDate,LastTime);

        if frmBandMap.FOnlyLoTW and frmBandMap.FOnlyEQSL then
        begin
           if not (AddArray[y].isLoTW or AddArray[y].isEQSL) then
             skip := True
        end
        else begin
          if ((not AddArray[y].isLoTW) and frmBandMap.FOnlyLoTW) then
            skip := True
          else begin
           if ((not AddArray[y].isEQSL) and frmBandMap.FOnlyEQSL) then
            skip := True
          end
        end;

        if skip then
          Continue;


        i := FindFirstemptyPos;
        if (i>0) then
        begin
          frmBandMap.BandMapItems[i].frmNewQSO := AddArray[y].frmNewQSO;
          frmBandMap.BandMapItems[i].Freq      := AddArray[y].Freq+Random(100)*0.000000001;
          frmBandMap.BandMapItems[i].Call      := AddArray[y].Call;
          frmBandMap.BandMapItems[i].Mode      := AddArray[y].Mode;
          frmBandMap.BandMapItems[i].Band      := AddArray[y].Band;
          frmBandMap.BandMapItems[i].SplitInfo := AddArray[y].SplitInfo;
          frmBandMap.BandMapItems[i].Lat       := AddArray[y].Lat;
          frmBandMap.BandMapItems[i].Long      := AddArray[y].Long;
          frmBandMap.BandMapItems[i].Color     := AddArray[y].Color;
          frmBandMap.BandMapItems[i].BgColor   := AddArray[y].BgColor;
          frmBandMap.BandMapItems[i].TimeStamp := AddArray[y].TimeStamp;
          frmBandMap.BandMapItems[i].TextValue := AddArray[y].TextValue;
          frmBandMap.BandMapItems[i].isLoTW    := AddArray[y].isLoTW;
          frmBandMap.BandMapItems[i].isEQSL    := AddArray[y].isEQSL;
          frmBandMap.BandMapItems[i].Position  := i
        end;
        NewAdded := True
      end;

      for i:=1 to MAX_ITEMS do
      begin
        for y:=0 to Length(DelArray)-1 do
        begin
          if (frmBandMap.BandMapItems[i].Call=DelArray[y].call) and  (frmBandMap.BandMapItems[i].Band=DelArray[y].band) and
             (frmBandMap.BandMapItems[i].Mode=DelArray[y].mode) then
          begin
            DeleteFromArray(i);
            NewAdded := True
          end
        end;

        if frmBandMap.BandMapItems[i].Freq = 0 then
          Continue;

        if When>(frmBandMap.BandMapItems[i].TimeStamp + (frmBandMap.FDeleteAfter/86400)) then
        begin
          DeleteFromArray(i);
          Changed := True
        end
        else if (When>(frmBandMap.BandMapItems[i].TimeStamp + (frmBandMap.FSecondInterval/86400))) and (frmBandMap.BandMapItems[i].Flag='S') then
        begin
          frmBandMap.BandMapItems[i].Color := IncColor(frmBandMap.BandMapItems[i].Color,40);
          frmBandMap.BandMapItems[i].Flag  := 'X';
          Changed := True
        end
        else if (When>(frmBandMap.BandMapItems[i].TimeStamp + (frmBandMap.FFirstInterval/86400))) and (frmBandMap.BandMapItems[i].Flag='') then
        begin
          frmBandMap.BandMapItems[i].Color := IncColor(frmBandMap.BandMapItems[i].Color,60);
          frmBandMap.BandMapItems[i].Flag  := 'S';
          Changed := True
        end
      end;
      if NewAdded then
      begin
        frmBandMap.SortBandMapArray(1,MAX_ITEMS);
        NewAdded := False;
        Changed  := True
      end;
      if Changed or (iter>3) then
      begin
        Synchronize(@frmBandMap.SyncBandMap);
        Changed := False;
        iter    := 1
      end;
      inc(iter);
      Sleep(500)
    end
  except
     on E : Exception do Writeln(E.Message)
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
  BandMap             := TColorMemo.Create(pnlBandMap);
  BandMap.parent      := pnlBandMap;
  BandMap.AutoScroll  := True;
  BandMap.Align       := alClient;
  BandMap.oncDblClick := @BandMapDbClick;
  BandMap.setLanguage(1);
  for i:=1 to MAX_ITEMS do
      BandMapItems[i].Freq:=0;
  BandMapItemsCount := 0;
  Randomize;
  ClearAll;
  BandMapThread := TBandMapThread.Create(True);
  BandMapThread.FreeOnTerminate := True;
  BandMapThread.Start
end;

procedure TfrmBandMap.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmBandMap);
  if cqrini.ReadBool('BandMap', 'Save', False) then
     frmBandMap.SaveBandMapItemsToFile(dmData.HomeDir+'bandmap.csv');
  BandMapThread.Terminate
end;

procedure TfrmBandMap.acFilterExecute(Sender: TObject);
var
  f : TfrmBandMapFilter;
begin
  f := TfrmBandMapFilter.Create(nil);
  try
    if f.ShowModal = mrOK then
      LoadSettings
  finally
    FreeAndNil(f)
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
    BandMap.SetFont(f)
  finally
    f.Free
  end
end;

procedure TfrmBandMap.FormDestroy(Sender: TObject);
begin
  DoneCriticalsection(BandMapCrit)
end;

procedure TfrmBandMap.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key= VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0
  end
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
        BandMapItems[i].Position,ITEM_SEP,
        BandMapItems[i].isLoTW,ITEM_SEP,
        BandMapItems[i].isEQSL,ITEM_SEP
      )
  finally
    CloseFile(f)
  end
end;

procedure TfrmBandMap.LoadBandMapItemsFromFile(FileName : String);
var
  f : TextFile;
  i : Integer=0;
  a : TExplodeArray;
  s : String;
begin
  if not FileExists(FileName) then exit;
  BandMap.DisableAutoRepaint(True);
  AssignFile(f,FileName);
  EnterCriticalSection(BandMapCrit);
  try
    ClearAll;
    Reset(f);
    while not Eof(f) do
    begin
      ReadLn(f,s);
      a := dmUtils.Explode(ITEM_SEP,s);
      if Length(a)<12 then Continue; //probably corrupted line
      if (i>MAX_ITEMS-1) then Continue;
      SetLength(AddToBandMapArr,i+1);
      AddToBandMapArr[i].frmNewQSO := StrToBool(a[0]);
      AddToBandMapArr[i].Freq      := StrToFloat(a[1]);
      AddToBandMapArr[i].Call      := a[2];
      AddToBandMapArr[i].Mode      := a[3];
      AddToBandMapArr[i].Band      := a[4];
      AddToBandMapArr[i].SplitInfo := a[5];
      AddToBandMapArr[i].Lat       := StrToFloat(a[6]);
      AddToBandMapArr[i].Long      := StrToFloat(a[7]);
      AddToBandMapArr[i].Color     := StrToInt(a[8]);
      AddToBandMapArr[i].BgColor   := StrToInt(a[9]);
      AddToBandMapArr[i].TimeStamp := StrToFloat(a[10]);
      AddToBandMapArr[i].TextValue := a[11];
      AddToBandMapArr[i].Position  := i;
      if i<14 then
      begin
        AddToBandMapArr[i].isLoTW := False;
        AddToBandMapArr[i].isEQSL := False
      end
      else begin
        AddToBandMapArr[i].isLoTW := StrToBool(a[12]);
        AddToBandMapArr[i].isEQSL := StrToBool(a[13])
      end;
      inc(i)
    end
  finally
    CloseFile(f);
    BandMap.DisableAutoRepaint(False);
    LeaveCriticalSection(BandMapCrit)
  end
end;

procedure TfrmBandMAp.xplanetExport;
var
  i : Integer;
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
        if ((FCurrentMode='LSB') or (FCurrentMode='USB')) then
        begin
          if BandMapItems[i].Mode<>'SSB' then
            Continue
        end
        else begin
          if ((FCurrentMode='CW') and (FCurrentMode='CWR')) then
          begin
            if (BandMapItems[i].Mode<>'CW') or (BandMapItems[i].Mode<>'CWR') then
              Continue
          end
          else begin
            if BandMapItems[i].Mode<>FCurrentMode then
              Continue
          end
        end
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

procedure TfrmBandMap.LoadSettings;
begin
  frmBandMap.FirstInterval   := cqrini.ReadInteger('BandMap', 'FirstAging', 5)*60;
  frmBandMap.SecondInterval  := cqrini.ReadInteger('BandMap', 'SecondAging', 8)*60;
  frmBandMap.DeleteAfter     := cqrini.ReadInteger('BandMap', 'Disep', 12)*60;
  frmBandMap.xplanetFile     := dmData.HomeDir+'xplanet/marker';
  frmBandMap.OnlyCurrBand    := cqrini.ReadBool('BandMap', 'OnlyActiveBand', False);
  frmBandMap.OnlyCurrMode    := cqrini.ReadBool('BandMap', 'OnlyActiveMode', False);
  frmBandMap.DoXplanetExport := (cqrini.ReadInteger('xplanet','ShowFrom',0) = 1); //dxclust =0, wsjt=2

  if cqrini.ReadBool('BandMapFilter','ShowAll',True) then
    frmBandMap.DateFilterType := dftShowAll;
  if cqrini.ReadBool('BandMapFilter','NoWkdHour',False) then
    frmBandMap.DateFilterType := dftShowLastHours;
  if cqrini.ReadBool('BandMapFilter','NoWkdDate',False) then
    frmBandMap.DateFilterType := dftShowLastDateTime;

  frmBandMap.LastHours := cqrini.ReadInteger('BandMapFilter','LastHours',48);
  frmBandMap.SinceDate := cqrini.ReadString('BandMapFilter','LastDate','');
  frmBandMap.SinceTime := cqrini.ReadString('BandMapFilter','LastTime','');

  frmBandMap.OnlyLoTW := cqrini.ReadBool('BandMapFilter','OnlyLoTW',False);
  frmBandMap.OnlyEQSL := cqrini.ReadBool('BandMapFilter','OnlyeQSL',False)
end;

end.

