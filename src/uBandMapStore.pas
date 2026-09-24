unit uBandMapStore;

{ The graphical band map's view of the shared spot store (uSpotStore).

  The spots themselves live in SpotStore, one for the whole application, fed by
  the DX cluster, the RBN monitor and the operator whether or not any band map
  window is open, and kept for the configured time. This unit turns that into
  what fBandMapGfx draws: Poll rebuilds a sorted list of TGfxSpot for the
  current filters, with the age step of each spot. Filters are applied here, on
  the way OUT, so changing one shows what has already arrived.

  Leaf unit: Classes/SysUtils/uSpotStore only, so the producers (worker threads
  of the cluster and RBN windows) depend on plain Pascal.

  Threading contract:
    AddBandMapSpot / RemoveBandMapSpot - any thread (SpotStore is thread safe)
    TBandMapStore                      - main thread only }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uSpotStore;

const
  //how many candidates the shared store keeps, all bands. Measured ~4000 per
  //12 minutes on an ordinary evening, ~17000 at 24 spots/s
  MAX_SPOT_CANDIDATES = 20000;

type
  //same three states as the text band map's TDateFilterType
  TBmDateFilter = (bmdShowAll, bmdLastHours, bmdSinceDateTime);

  { The QSO rule of the window, supplied by the form: True when the station was
    worked since the given moment, i.e. when the spot is hidden. }
  TWorkedCheckFunc = function(const ACall, ABand, AMode,
                              ALastDate, ALastTime : String) : Boolean of object;

  { All fields are unmanaged (ShortString, Double, LongInt, ...) so the record
    is plain old data and may be copied around freely. }
  TGfxSpot = record
    Freq      : Double;     //kHz, exact - the whole pixel mapping depends on it
    Call      : String[30];
    Mode      : String[10];
    Band      : String[10];
    SplitInfo : String[20];
    BaseColor : LongInt;    //foreground colour as supplied by the producer
    BgColor   : LongInt;
    TimeStamp : TDateTime;  //last live arrival
    Source    : TSpotOrigin;
    AgeStep   : Byte        //0 fresh, 1 past FirstAging, 2 past SecondAging
  end;

  TBandMapStore = class
    private
      FItems     : array of TGfxSpot;    //main thread only, sorted by Freq
      FFirstSec  : Integer;
      FSecondSec : Integer;

      FBand       : String;      //'' = every band (the window follows the radio)
      FDateFilter : TBmDateFilter;
      FLastHours  : Integer;
      FSinceDate  : String;
      FSinceTime  : String;
      FOnlyLoTW   : Boolean;
      FOnlyEQSL   : Boolean;
      FOnWorkedCheck : TWorkedCheckFunc;
      FBoundaryDate  : String;   //of the Poll in progress
      FBoundaryTime  : String;

      function  AgeStepFor(ASeconds : Double) : Byte;
      function  WorkedRule(const Call, Band, Mode : String) : Boolean;
    public
      constructor Create;

      //ANow is local time (spot aging), AUtcNow is the clock QSOs are logged in.
      //True when the display must be redrawn
      function  Poll(ANow, AUtcNow : TDateTime) : Boolean;
      procedure Clear;   //everything, all bands: the user's "remove all spots"
      function  Count : Integer;
      function  Item(AIndex : Integer) : TGfxSpot;

      property FirstAgingSec  : Integer read FFirstSec  write FFirstSec;
      property SecondAgingSec : Integer read FSecondSec write FSecondSec;

      { the window's filters, applied by Poll }
      property Band       : String read FBand write FBand;
      property DateFilter : TBmDateFilter read FDateFilter write FDateFilter;
      property LastHours  : Integer read FLastHours write FLastHours;
      property SinceDate  : String  read FSinceDate write FSinceDate;
      property SinceTime  : String  read FSinceTime write FSinceTime;
      property OnlyLoTW   : Boolean read FOnlyLoTW  write FOnlyLoTW;
      property OnlyEQSL   : Boolean read FOnlyEQSL  write FOnlyEQSL;
      property OnWorkedCheck : TWorkedCheckFunc read FOnWorkedCheck write FOnWorkedCheck;
  end;

var
  SpotStore : TSpotStore;    //the shared candidates, created in initialization

//the producers' way in: the DX cluster, the RBN monitor and the operator
procedure AddBandMapSpot(AFreq : Double; const ACall, AMode, ABand, ASplit : String;
                         AColor, ABgColor : LongInt; AOrigin : TSpotOrigin;
                         AisLoTW : Boolean = False; AisEQSL : Boolean = False;
                         const ASpotter : String = ''; ASourceId : Integer = 0);
procedure RemoveBandMapSpot(const ACall, AMode, ABand : String);

implementation

constructor TBandMapStore.Create;
begin
  inherited Create;
  FFirstSec   := 5*60;
  FSecondSec  := 8*60;
  FDateFilter := bmdShowAll;
  FLastHours  := 48
end;

procedure AddBandMapSpot(AFreq : Double; const ACall, AMode, ABand, ASplit : String;
                         AColor, ABgColor : LongInt; AOrigin : TSpotOrigin;
                         AisLoTW : Boolean; AisEQSL : Boolean;
                         const ASpotter : String; ASourceId : Integer);
var
  C : TSpotCandidate;
begin
  C := Default(TSpotCandidate);
  C.Origin    := AOrigin;
  C.SourceId  := ASourceId;
  C.Spotter   := ASpotter;
  C.Call      := ACall;
  C.Mode      := AMode;
  C.Band      := ABand;
  C.FreqKHz   := AFreq;
  C.SplitInfo := ASplit;
  C.Color     := AColor;
  C.BgColor   := ABgColor;
  C.IsLoTW    := AisLoTW;
  C.IsEQSL    := AisEQSL;
  C.LastSeen  := Now;
  SpotStore.Add(C)
end;

procedure RemoveBandMapSpot(const ACall, AMode, ABand : String);
begin
  SpotStore.Remove(ACall, ABand, AMode)
end;

function TBandMapStore.AgeStepFor(ASeconds : Double) : Byte;
begin
  if ASeconds > FSecondSec then
    Result := 2
  else if ASeconds > FFirstSec then
    Result := 1
  else
    Result := 0
end;

function TBandMapStore.WorkedRule(const Call, Band, Mode : String) : Boolean;
begin
  Result := Assigned(FOnWorkedCheck) and
            FOnWorkedCheck(Call, Band, Mode, FBoundaryDate, FBoundaryTime)
end;

function TBandMapStore.Poll(ANow, AUtcNow : TDateTime) : Boolean;
var
  F    : TSpotFilter;
  V    : TSpotView;
  i    : Integer;
  Rule : TWorkedRule;
  Step : Byte;
begin
  Result := False;
  F := DefaultSpotFilter;
  F.OnlyLoTW := FOnlyLoTW;
  F.OnlyEQSL := FOnlyEQSL;

  Rule := nil;
  case FDateFilter of
    bmdLastHours :
      begin
        FBoundaryDate := FormatDateTime('yyyy-mm-dd', AUtcNow - (FLastHours/24));
        FBoundaryTime := FormatDateTime('hh:nn', AUtcNow - (FLastHours/24));
        Rule := @WorkedRule
      end;
    bmdSinceDateTime :
      begin
        FBoundaryDate := FSinceDate;
        FBoundaryTime := FSinceTime;
        Rule := @WorkedRule
      end
  end;

  V := SpotStore.Select(FBand, ANow, F, Rule);
  if Length(V) <> Length(FItems) then
    Result := True;
  SetLength(FItems, Length(V));
  for i := 0 to High(V) do
  begin
    if (not Result) and ((FItems[i].Call <> V[i].Call) or (FItems[i].Freq <> V[i].FreqKHz) or
                         (FItems[i].Band <> V[i].Band) or (FItems[i].TimeStamp <> V[i].LastSeen)) then
      Result := True;
    FItems[i].Freq      := V[i].FreqKHz;
    FItems[i].Call      := V[i].Call;
    FItems[i].Mode      := V[i].Mode;
    FItems[i].Band      := V[i].Band;
    FItems[i].SplitInfo := V[i].SplitInfo;
    FItems[i].BaseColor := V[i].Color;
    FItems[i].BgColor   := V[i].BgColor;
    FItems[i].TimeStamp := V[i].LastSeen;
    FItems[i].Source    := V[i].Origin;
    Step := AgeStepFor((ANow - V[i].LastSeen) * 86400);
    if FItems[i].AgeStep <> Step then
      Result := True;
    FItems[i].AgeStep := Step
  end;
  //the store keeps what any window may still want; expiry is one sweep
  SpotStore.Expire(ANow)
end;

procedure TBandMapStore.Clear;
begin
  SpotStore.Clear;
  FItems := nil
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
  SpotStore := TSpotStore.Create(MAX_SPOT_CANDIDATES);

finalization
  FreeAndNil(SpotStore);

end.
