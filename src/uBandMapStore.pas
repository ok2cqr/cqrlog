unit uBandMapStore;

{ Spot store for the graphical band map (fBandMapGfx).

  Deliberately a leaf unit - it uses nothing but Classes/SysUtils. It is called
  from the DX cluster and RBN worker threads, so keeping it free of LCL, dData
  and cqrini means those units gain a dependency on plain Pascal only, never on
  another form.

  It is completely independent of fBandMap: the text band map keeps its own
  array, its own thread and its own settings, and nothing here touches it.

  Threading contract:
    Add / Remove   - callable from ANY thread (queues guarded by FCrit)
    everything else - MAIN THREAD ONLY

  There is no worker thread. The only expensive thing the text band map's
  thread does is the dmData.CallExistsInLog "not worked since" filter; that
  filter is not implemented here, so draining, dedup, aging and expiry are
  pure in-memory work and run straight off the form's 500 ms timer. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  MAX_GFX_SPOTS = 1000; //hard cap; the oldest spot is evicted to make room
  MAX_GFX_QUEUE = 2000; //burst guard; further adds are dropped until Poll drains

  //Poll runs on the GUI thread, so the "not worked since" filter - the only
  //part that costs a database query - is rationed. A cluster dumping its spot
  //history on connect then spreads over a few ticks instead of freezing the
  //window. Nothing is lost, the rest waits in FPending.
  MAX_CHECKS_PER_POLL = 25;

type
  TGfxSpotSource = (gssCluster, gssRbn, gssManual);

  //same three states as the text band map's TDateFilterType
  TBmDateFilter = (bmdShowAll, bmdLastHours, bmdSinceDateTime);

  { Supplied by the form so this unit does not have to know about dData.
    Returns True when the station has already been worked since the given
    date/time, i.e. when the spot should be dropped. }
  TWorkedCheckFunc = function(const ACall, ABand, AMode,
                              ALastDate, ALastTime : String) : Boolean of object;

  { All fields are unmanaged (ShortString, Double, LongInt, ...) so the record
    is plain old data and may be copied around freely. Do NOT change Call/Mode/
    Band/SplitInfo to AnsiString without revisiting the array shuffling below. }
  TGfxSpot = record
    Freq      : Double;     //kHz, exact - the whole pixel mapping depends on it
    Call      : String[30];
    Mode      : String[10];
    Band      : String[10];
    SplitInfo : String[20];
    BaseColor : LongInt;    //foreground colour as supplied by the producer
    BgColor   : LongInt;
    TimeStamp : TDateTime;
    Source    : TGfxSpotSource;
    AgeStep   : Byte;       //0 fresh, 1 past FirstAging, 2 past SecondAging
    isLoTW    : Boolean;
    isEQSL    : Boolean
  end;

  TGfxSpotKey = record
    Call : String[30];
    Mode : String[10];
    Band : String[10]
  end;

  TBandMapStore = class
    private
      FCrit      : TRTLCriticalSection;
      FAddQ      : array of TGfxSpot;    //guarded by FCrit
      FDelQ      : array of TGfxSpotKey; //guarded by FCrit
      FItems     : array of TGfxSpot;    //main thread only, always sorted by Freq
      FPending   : array of TGfxSpot;    //main thread only, waiting for a log check
      FEnabled   : Boolean;
      FFirstSec  : Integer;
      FSecondSec : Integer;
      FDeleteSec : Integer;

      FDateFilter : TBmDateFilter;
      FLastHours  : Integer;
      FSinceDate  : String;
      FSinceTime  : String;
      FOnlyLoTW   : Boolean;
      FOnlyEQSL   : Boolean;
      FOnWorkedCheck : TWorkedCheckFunc;

      function  IndexOf(const ACall, AMode, ABand : String) : Integer;
      function  InsertPos(AFreq : Double) : Integer;
      procedure InsertItem(const ASpot : TGfxSpot);
      procedure DeleteItem(AIndex : Integer);
      procedure DropPending(ACount : Integer);
      function  OldestIndex : Integer;
      function  AgeStepFor(ASeconds : Double) : Byte;
      function  RejectedByQslFilter(const ASpot : TGfxSpot) : Boolean;
    public
      constructor Create;
      destructor  Destroy; override;

      { any thread }
      procedure Add(AFreq : Double; const ACall, AMode, ABand, ASplit : String;
                    AColor, ABgColor : LongInt; ASource : TGfxSpotSource;
                    AisLoTW : Boolean = False; AisEQSL : Boolean = False);
      procedure Remove(const ACall, AMode, ABand : String);

      { main thread only }
      function  Poll(ANow : TDateTime) : Boolean; //True when the display must be redrawn
      procedure Clear;
      function  Count : Integer;
      function  Item(AIndex : Integer) : TGfxSpot;

      property Enabled : Boolean read FEnabled write FEnabled;
      property FirstAgingSec  : Integer read FFirstSec  write FFirstSec;
      property SecondAgingSec : Integer read FSecondSec write FSecondSec;
      property DeleteAfterSec : Integer read FDeleteSec write FDeleteSec;

      { filters, all applied when a spot enters the store - exactly like the
        text band map, so changing them does not retroactively drop what is
        already displayed }
      property DateFilter : TBmDateFilter read FDateFilter write FDateFilter;
      property LastHours  : Integer read FLastHours write FLastHours;
      property SinceDate  : String  read FSinceDate write FSinceDate;
      property SinceTime  : String  read FSinceTime write FSinceTime;
      property OnlyLoTW   : Boolean read FOnlyLoTW  write FOnlyLoTW;
      property OnlyEQSL   : Boolean read FOnlyEQSL  write FOnlyEQSL;
      property OnWorkedCheck : TWorkedCheckFunc read FOnWorkedCheck write FOnWorkedCheck;
  end;

var
  BandMapStore : TBandMapStore; //created in initialization, never nil
  BandMapStoreDebug : Boolean = False;

implementation

constructor TBandMapStore.Create;
begin
  inherited Create;
  InitCriticalSection(FCrit);
  FEnabled    := False;
  FFirstSec   := 5*60;
  FSecondSec  := 8*60;
  FDeleteSec  := 12*60;
  FDateFilter := bmdShowAll;
  FLastHours  := 48;
  FOnlyLoTW   := False;
  FOnlyEQSL   := False
end;

destructor TBandMapStore.Destroy;
begin
  DoneCriticalsection(FCrit);
  inherited Destroy
end;

procedure TBandMapStore.Add(AFreq : Double; const ACall, AMode, ABand, ASplit : String;
                            AColor, ABgColor : LongInt; ASource : TGfxSpotSource;
                            AisLoTW : Boolean = False; AisEQSL : Boolean = False);
var
  s : TGfxSpot;
  l : Integer;
begin
  if (AFreq <= 0) or (ACall = '') then
    exit;

  s.Freq      := AFreq;
  s.Call      := ACall;
  s.Mode      := AMode;
  s.Band      := ABand;
  s.SplitInfo := ASplit;
  s.BaseColor := AColor;
  s.BgColor   := ABgColor;
  s.TimeStamp := Now;
  s.Source    := ASource;
  s.AgeStep   := 0;
  s.isLoTW    := AisLoTW;
  s.isEQSL    := AisEQSL;

  EnterCriticalSection(FCrit);
  try
    if not FEnabled then
      exit;
    l := Length(FAddQ);
    if l >= MAX_GFX_QUEUE then //main thread is stalled, drop rather than grow
      exit;
    SetLength(FAddQ,l+1);
    FAddQ[l] := s
  finally
    LeaveCriticalSection(FCrit)
  end;

  if BandMapStoreDebug then
    Writeln('BandMapGfx: add ',ACall,' ',FormatFloat('0.00',AFreq),' kHz')
end;

procedure TBandMapStore.Remove(const ACall, AMode, ABand : String);
var
  k : TGfxSpotKey;
  l : Integer;
begin
  k.Call := ACall;
  k.Mode := AMode;
  k.Band := ABand;

  EnterCriticalSection(FCrit);
  try
    l := Length(FDelQ);
    if l >= MAX_GFX_QUEUE then
      exit;
    SetLength(FDelQ,l+1);
    FDelQ[l] := k
  finally
    LeaveCriticalSection(FCrit)
  end
end;

function TBandMapStore.IndexOf(const ACall, AMode, ABand : String) : Integer;
var
  i : Integer;
begin
  Result := -1;
  //same identity as the text band map's ItemExists: call + band + mode
  for i:=0 to Length(FItems)-1 do
  begin
    if (FItems[i].Call = ACall) and (FItems[i].Mode = AMode) and (FItems[i].Band = ABand) then
      exit(i)
  end
end;

function TBandMapStore.InsertPos(AFreq : Double) : Integer;
var
  i : Integer;
begin
  Result := Length(FItems);
  for i:=0 to Length(FItems)-1 do
  begin
    if FItems[i].Freq > AFreq then
      exit(i)
  end
end;

procedure TBandMapStore.InsertItem(const ASpot : TGfxSpot);
var
  p,i : Integer;
begin
  p := InsertPos(ASpot.Freq);
  SetLength(FItems,Length(FItems)+1);
  for i:=Length(FItems)-1 downto p+1 do
    FItems[i] := FItems[i-1];
  FItems[p] := ASpot
end;

procedure TBandMapStore.DeleteItem(AIndex : Integer);
var
  i : Integer;
begin
  if (AIndex < 0) or (AIndex > Length(FItems)-1) then
    exit;
  for i:=AIndex to Length(FItems)-2 do
    FItems[i] := FItems[i+1];
  SetLength(FItems,Length(FItems)-1)
end;

procedure TBandMapStore.DropPending(ACount : Integer);
var
  i : Integer;
begin
  if ACount <= 0 then
    exit;
  if ACount >= Length(FPending) then
  begin
    FPending := nil;
    exit
  end;
  for i:=0 to Length(FPending)-ACount-1 do
    FPending[i] := FPending[i+ACount];
  SetLength(FPending,Length(FPending)-ACount)
end;

{ same precedence as the text band map: with both boxes ticked either
  confirmation is enough, with one ticked that one is required }
function TBandMapStore.RejectedByQslFilter(const ASpot : TGfxSpot) : Boolean;
begin
  Result := False;
  if FOnlyLoTW and FOnlyEQSL then
  begin
    if not (ASpot.isLoTW or ASpot.isEQSL) then
      Result := True
  end
  else begin
    if FOnlyLoTW and (not ASpot.isLoTW) then
      Result := True
    else begin
      if FOnlyEQSL and (not ASpot.isEQSL) then
        Result := True
    end
  end
end;

function TBandMapStore.OldestIndex : Integer;
var
  i : Integer;
begin
  Result := -1;
  for i:=0 to Length(FItems)-1 do
  begin
    if (Result < 0) or (FItems[i].TimeStamp < FItems[Result].TimeStamp) then
      Result := i
  end
end;

function TBandMapStore.AgeStepFor(ASeconds : Double) : Byte;
begin
  if ASeconds > FSecondSec then
    Result := 2
  else begin
    if ASeconds > FFirstSec then
      Result := 1
    else
      Result := 0
  end
end;

function TBandMapStore.Poll(ANow : TDateTime) : Boolean;
var
  AddArr   : array of TGfxSpot;
  DelArr   : array of TGfxSpotKey;
  i,j,p,n  : Integer;
  age      : Double;
  st       : Byte;
  skip     : Boolean;
  LastDate : String = '';
  LastTime : String = '';
begin
  Result := False;

  EnterCriticalSection(FCrit);
  try
    AddArr := FAddQ;
    DelArr := FDelQ;
    FAddQ  := nil;
    FDelQ  := nil
  finally
    LeaveCriticalSection(FCrit)
  end;

  //new arrivals join whatever is still waiting for a log check
  j := Length(FPending);
  SetLength(FPending,j+Length(AddArr));
  for i:=0 to Length(AddArr)-1 do
    FPending[j+i] := AddArr[i];
  if Length(FPending) > MAX_GFX_QUEUE then
    DropPending(Length(FPending)-MAX_GFX_QUEUE);

  for i:=0 to Length(DelArr)-1 do
  begin
    p := IndexOf(DelArr[i].Call,DelArr[i].Mode,DelArr[i].Band);
    if p >= 0 then
    begin
      DeleteItem(p);
      Result := True
    end;
    //a station logged while its spot was still queued must not slip through
    for j:=Length(FPending)-1 downto 0 do
    begin
      if (FPending[j].Call = DelArr[i].Call) and (FPending[j].Mode = DelArr[i].Mode)
         and (FPending[j].Band = DelArr[i].Band) then
        FPending[j].Freq := 0 //marked, dropped in the loop below
    end
  end;

  if FDateFilter = bmdLastHours then
  begin
    LastDate := FormatDateTime('yyyy-mm-dd',ANow-(FLastHours/24));
    LastTime := FormatDateTime('hh:nn',ANow-(FLastHours/24))
  end
  else begin
    if FDateFilter = bmdSinceDateTime then
    begin
      LastDate := FSinceDate;
      LastTime := FSinceTime
    end
  end;

  n := 0;
  i := 0;
  while i <= Length(FPending)-1 do
  begin
    //only the log check costs anything, so only it is rationed
    if (FDateFilter <> bmdShowAll) and (n >= MAX_CHECKS_PER_POLL) then
      Break;

    if FPending[i].Freq = 0 then //deleted while queued
    begin
      Inc(i);
      Continue
    end;

    //a re-spot MOVES the station, it never duplicates it. Done before the
    //filters, so a re-spot of a now worked station removes the old entry.
    p := IndexOf(FPending[i].Call,FPending[i].Mode,FPending[i].Band);
    if p >= 0 then
    begin
      DeleteItem(p);
      Result := True
    end;

    skip := RejectedByQslFilter(FPending[i]);

    if (not skip) and (FDateFilter <> bmdShowAll) and Assigned(FOnWorkedCheck) then
    begin
      skip := FOnWorkedCheck(FPending[i].Call,FPending[i].Band,FPending[i].Mode,
                             LastDate,LastTime);
      Inc(n)
    end;

    if not skip then
    begin
      if Length(FItems) >= MAX_GFX_SPOTS then
        DeleteItem(OldestIndex);
      InsertItem(FPending[i]);
      Result := True
    end;
    Inc(i)
  end;
  DropPending(i);

  i := 0;
  while i <= Length(FItems)-1 do
  begin
    age := (ANow - FItems[i].TimeStamp)*86400;
    if age > FDeleteSec then
    begin
      DeleteItem(i);
      Result := True;
      Continue //DeleteItem shifted the tail down, so do not advance i
    end;
    st := AgeStepFor(age);
    if st <> FItems[i].AgeStep then
    begin
      FItems[i].AgeStep := st;
      Result := True
    end;
    Inc(i)
  end
end;

procedure TBandMapStore.Clear;
begin
  FItems   := nil;
  FPending := nil;
  EnterCriticalSection(FCrit);
  try
    FAddQ := nil;
    FDelQ := nil
  finally
    LeaveCriticalSection(FCrit)
  end
end;

function TBandMapStore.Count : Integer;
begin
  Result := Length(FItems)
end;

function TBandMapStore.Item(AIndex : Integer) : TGfxSpot;
begin
  Result := FItems[AIndex]
end;

initialization
  BandMapStore := TBandMapStore.Create;

finalization
  FreeAndNil(BandMapStore);

end.
