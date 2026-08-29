(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The one DXCC engine.

  dDXCC and dDXCluster used to carry a complete copy of this each: two
  TDxccTable pairs built from the same two files, two identical DXCCRefArrays
  filled by the same SELECT, and two copies of every resolution routine.  The
  split was never about the parser -- lookups are reentrant -- it was about the
  MySQL connection: dDXCC binds its queries to dmData.MainCon, dDXCluster to
  dmData.dbDXC because three worker threads reach into it.  That reason still
  holds for the *queries*, so both data modules stay; only the engine moved
  here.

  This unit depends on the RTL and the parser units alone -- no dData, no LCL.
  The data directory is passed in, and DXCCRefArray, the one piece of state
  that comes from the database, is pushed in from outside by whoever owns a
  connection (dmDXCC).  That keeps the unit testable the same way the parser is.

  Threading contract, which the reload depends on:

    * every reader holds FLock for the whole read;
    * ReloadTables builds the replacements OUTSIDE the lock, swaps the
      references INSIDE it, and frees the old objects AFTER leaving it.

  The last step is only safe because of the first: once the swap has been made
  under the lock, any reader still holding an old pointer must already have
  finished, because it could not have entered without the lock.  A TDxccTable
  is immutable once LoadFromFile returns, so this is the whole of it.

  The search key goes through TDxccSearchKey, a String[40].  That truncation is
  not cosmetic: the original engine passed the callsign through znacmech's
  string_mdz on the way to the table lookup, so anything past 40 characters was
  silently dropped before matching, and the tables were built on that
  assumption.  It is declared here rather than imported so this unit does not
  drag in znacmech, whose implementation section pulls in dData.
}

unit uDxccService;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uDxccTable, uDxccEntry, uDxccResolver, uDxccSuffixRules, uDebugLog;

type
  { same width as znacmech.string_mdz -- see the note above }
  TDxccSearchKey = String[40];

  TExplodeArray = Array of String;

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

  TDXCCRefArray = Array of TDXCCRef;
  TDXCCDelArray = Array of Integer;

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
  NotExactly = 0;
  Exactly    = 1;
  ExNoEquals = 2;

{ How strictly a mark has to line up with the callsign being resolved:
    NotExactly  the mark may be longer than the callsign (prefix match)
    Exactly     the mark and the callsign must be the same length
    ExNoEquals  as Exactly, but without a leading '='
}

  MAX_STATES = 60;

type

  { TDxccService }

  TDxccService = class(TObject)
  private
    FValid    : TDxccTable;
    FDeleted  : TDxccTable;
    FRules    : TDxccSuffixRules;
    FResolver : TDxccResolver;

    FRef       : TDXCCRefArray;
    FDel       : TDXCCDelArray;
    FAmbiguous : Array of String;
    FStates    : Array of TUSStates;

    FLock       : TRTLCriticalSection;
    FDebugLevel : Integer;

    { The lookups and the two file loaders below assume FLock is already held.
      BuildRules is the exception: it only constructs a fresh object and is
      called both under the lock (LoadTables) and outside it (ReloadTables). }
    function  EffectiveCall(const Call : String; ADate : TDateTime;
                            var Found : Boolean; var Adif : Integer) : String;
    function  FindCountry(const Call : String; ADate : TDateTime;
                          var Pfx, Country, Cont, Itu, Waz, UtcOffset, Lat, Long : String;
                          var Adif : Integer; Exactness : Integer = NotExactly) : Boolean;
    function  StateInfo(const State : String;
                        var Country, Lat, Long, Waz, Itu, UtcOffset, Cont : String) : Integer;
    function  IdCountryLocked(const Call, UsState : String; ADate : TDateTime;
                              var Pfx, Cont, Country, Waz, UtcOffset, Itu, Lat, Long : String) : Word;
    procedure LoadAmbiguous(const DataDir : String);
    procedure LoadStates(const DataDir : String);
    function  BuildRules(const DataDir : String) : TDxccSuffixRules;
  public
    constructor Create;
    destructor  Destroy; override;

    procedure LoadTables(const DataDir : String);
    procedure ReloadTables(const DataDir : String);
    procedure SetDxccRef(const ARef : TDXCCRefArray; const ADel : TDXCCDelArray);

    function  IdCountry(const Call, UsState : String; ADate : TDateTime;
                        var Pfx, Cont, Country, Waz, UtcOffset, Itu, Lat, Long : String) : Word;
    function  IsException(const Call : String) : Boolean;
    function  IsAmbiguous(const Call : String) : Boolean;
    function  IsPrefix(const Pfx : String; ADate : TDateTime) : Boolean;

    function  PfxFromAdif(Adif : Word) : String;
    function  CountryFromAdif(Adif : Word) : String;
    function  AdifFromPfx(const Pfx : String) : Word;
    function  DeletedAdifList : String;

    property  DebugLevel : Integer read FDebugLevel write FDebugLevel;
  end;

function Explode(const cSeparator, vString : String) : TExplodeArray;
function DateToDDXCCDate(date : TDateTime) : String;

var
  DxccService : TDxccService;

implementation

{ dDXCC's NotExactly/Exactly/ExNoEquals onto the table's match modes. }
function MatchMode(Exactness : Integer) : TDxccMatchMode;
begin
  case Exactness of
    Exactly    : Result := dmExact;
    ExNoEquals : Result := dmExactNoEquals;
  else
    Result := dmPrefix
  end
end;

function Explode(const cSeparator, vString : String) : TExplodeArray;
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

function DateToDDXCCDate(date : TDateTime) : String;
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

{ TDxccService }

constructor TDxccService.Create;
begin
  inherited Create;
  InitCriticalSection(FLock);
  FDebugLevel := 0
end;

destructor TDxccService.Destroy;
begin
  FreeAndNil(FResolver);
  FreeAndNil(FRules);
  FreeAndNil(FValid);
  FreeAndNil(FDeleted);
  DoneCriticalsection(FLock);
  inherited Destroy
end;

function TDxccService.BuildRules(const DataDir : String) : TDxccSuffixRules;
begin
  Result := TDxccSuffixRules.Create;
  Result.LoadExceptions(DataDir + 'exceptions.tab');
  //the resolver does not consume this one, but keep Rules fully populated
  Result.LoadAmbiguous(DataDir + 'ambiguous.tab')
end;

procedure TDxccService.LoadTables(const DataDir : String);
begin
  EnterCriticalsection(FLock);
  try
    FValid := TDxccTable.Create;
    FValid.LoadFromFile(DataDir + 'country.tab');
    FDeleted := TDxccTable.Create;
    FDeleted.LoadFromFile(DataDir + 'country_del.tab');
    FRules := BuildRules(DataDir);
    FResolver := TDxccResolver.Create(FValid,FDeleted,FRules);

    LoadAmbiguous(DataDir);
    LoadStates(DataDir)
  finally
    LeaveCriticalsection(FLock)
  end
end;

procedure TDxccService.ReloadTables(const DataDir : String);
var
  NewValid, NewDeleted : TDxccTable;
  NewRules : TDxccSuffixRules;
  OldValid, OldDeleted : TDxccTable;
  OldRules : TDxccSuffixRules;
  OldResolver : TDxccResolver;
begin
  //a TDxccTable is immutable once loaded, so build the replacements outside the
  //lock and keep the critical section down to the reference swap.  Rules is
  //rebuilt here as well: the old engine reloaded the tables but not the
  //exception list, so a fresh exceptions.tab only took effect after a restart.
  NewValid := TDxccTable.Create;
  NewValid.LoadFromFile(DataDir + 'country.tab');
  NewDeleted := TDxccTable.Create;
  NewDeleted.LoadFromFile(DataDir + 'country_del.tab');
  NewRules := BuildRules(DataDir);

  EnterCriticalsection(FLock);
  try
    OldResolver := FResolver;
    OldValid    := FValid;
    OldDeleted  := FDeleted;
    OldRules    := FRules;

    FValid    := NewValid;
    FDeleted  := NewDeleted;
    FRules    := NewRules;
    FResolver := TDxccResolver.Create(FValid,FDeleted,FRules);

    //IsAmbiguous reads this directly, and the US state table can change too
    LoadAmbiguous(DataDir);
    LoadStates(DataDir)
  finally
    LeaveCriticalsection(FLock)
  end;

  //safe only because every reader holds FLock for the whole read: anyone who
  //could still be looking at the old objects has left by the time we get here
  OldResolver.Free;
  OldValid.Free;
  OldDeleted.Free;
  OldRules.Free
end;

procedure TDxccService.SetDxccRef(const ARef : TDXCCRefArray; const ADel : TDXCCDelArray);
begin
  EnterCriticalsection(FLock);
  try
    FRef := Copy(ARef,0,Length(ARef));
    FDel := Copy(ADel,0,Length(ADel))
  finally
    LeaveCriticalsection(FLock)
  end
end;

procedure TDxccService.LoadAmbiguous(const DataDir : String);
var
  f : TextFile;
  s : String;
begin
  SetLength(FAmbiguous,0);
  //ReloadTables calls this too, and on a fresh profile the file may not be
  //there yet; TDxccSuffixRules is tolerant the same way
  if not FileExists(DataDir + 'ambiguous.tab') then
    exit;
  AssignFile(f,DataDir + 'ambiguous.tab');
  Reset(f);
  try
    while not Eof(f) do
    begin
      ReadLn(f,s);
      //file has only a few lines so there is no need to SetLength in higher blocks
      SetLength(FAmbiguous,Length(FAmbiguous)+1);
      FAmbiguous[Length(FAmbiguous)-1] := s
    end
  finally
    CloseFile(f)
  end
end;

procedure TDxccService.LoadStates(const DataDir : String);
var
  f : TextFile;
  a : TExplodeArray;
  i : Integer = 0;
  r : String;
begin
  SetLength(FStates,0);
  if not FileExists(DataDir + 'us_states.tab') then
    exit;
  AssignFile(f,DataDir + 'us_states.tab');
  Reset(f);
  try
    SetLength(FStates,MAX_STATES);

    while not Eof(f) do
    begin
      Readln(f,r);
      a := Explode('|',r);

      FStates[i].prefix := a[0];
      FStates[i].name   := a[1];
      FStates[i].state  := a[2];
      FStates[i].cont   := a[3];

      if (pos('+',a[4])>0) then
        FStates[i].offset := copy(a[4],2,10)
      else
        FStates[i].offset := a[4];

      FStates[i].itu  := a[5];
      FStates[i].waz  := a[6];
      FStates[i].lat  := a[7];
      FStates[i].long := a[8];
      FStates[i].adif := StrToInt(a[9]);

      inc(i)
    end
  finally
    CloseFile(f);
    if FDebugLevel>=1 then Writeln(i,' us states loaded')
  end
end;

function TDxccService.StateInfo(const State : String;
  var Country, Lat, Long, Waz, Itu, UtcOffset, Cont : String) : Integer;
var
  i : Integer;
begin
  Result := 0;

  for i:=0 to Length(FStates)-1 do
  begin
    if (State = FStates[i].state) then
    begin
      Country   := FStates[i].name;
      Lat       := FStates[i].lat;
      Long      := FStates[i].long;
      Waz       := FStates[i].waz;
      Itu       := FStates[i].itu;
      UtcOffset := FStates[i].offset;
      Cont      := FStates[i].cont;
      Result    := FStates[i].adif;
      break
    end
  end
end;

function TDxccService.EffectiveCall(const Call : String; ADate : TDateTime;
  var Found : Boolean; var Adif : Integer) : String;
begin
  try
    Result := FResolver.EffectiveCallsign(Call,DateToDDXCCDate(ADate),Found,Adif)
  except
    on E: Exception do
    begin
      DbgLogException('DXCC','EffectiveCall call=' + Call +
                             ' date=' + DateToDDXCCDate(ADate), E);
      raise
    end
  end
end;

function TDxccService.FindCountry(const Call : String; ADate : TDateTime;
  var Pfx, Country, Cont, Itu, Waz, UtcOffset, Lat, Long : String;
  var Adif : Integer; Exactness : Integer = NotExactly) : Boolean;
var
  SearchKey  : TDxccSearchKey;
  AdifText   : String;
  SearchDate : String;
  Idx        : LongInt;
  Rec        : TDxccEntry;
begin
  Result     := False;
  SearchKey  := Call;
  SearchDate := DateToDDXCCDate(ADate);
  Idx        := FDeleted.Find(SearchKey,SearchDate,MatchMode(Exactness));
  if Idx <> -1 then
  begin
    Rec       := FDeleted.Entry(Idx);
    Country   := Rec.Country;
    Itu       := Rec.Itu;
    Waz       := Rec.Waz;
    UtcOffset := Rec.UtcOffset;
    Lat       := Rec.Latitude;
    Long      := Rec.Longitude;
    AdifText  := Rec.Adif;
    Cont      := UpperCase(Rec.Continent);
    Result    := True;
    if not TryStrToInt(AdifText,Adif) then
      Adif := 0;
    exit
  end
  else begin
    Pfx := '!'
  end;

  Idx := FValid.Find(SearchKey,SearchDate,MatchMode(Exactness));
  if Idx <> -1 then
  begin
    Rec       := FValid.Entry(Idx);
    Country   := Rec.Country;
    Itu       := Rec.Itu;
    Waz       := Rec.Waz;
    UtcOffset := Rec.UtcOffset;
    Lat       := Rec.Latitude;
    Long      := Rec.Longitude;
    AdifText  := Rec.Adif;
    Cont      := UpperCase(Rec.Continent);
    Result    := True;
    if not TryStrToInt(AdifText,Adif) then
      Adif := 0
  end
  else begin
    Pfx := '!'
  end
end;

function TDxccService.IdCountryLocked(const Call, UsState : String; ADate : TDateTime;
  var Pfx, Cont, Country, Waz, UtcOffset, Itu, Lat, Long : String) : Word;
var
  Adif       : Integer;
  Found      : Boolean;
  SearchDate : String;
  NoDXCC     : Boolean;
  Idx        : longint;
  SearchKey  : TDxccSearchKey;
  AdifText   : String;
  StateAdif  : Integer;
  Rec        : TDxccEntry;
begin
  Result := 0;
  if (Length(Call) = 0) then
    exit;

  Found := False;
  Adif  := 0;

  //EffectiveCall applies the slash rules; its result, not the raw callsign,
  //is what the tables are keyed on
  SearchKey  := EffectiveCall(Call,ADate,Found,Adif);
  SearchDate := DateToDDXCCDate(ADate);
  Idx        := FDeleted.Find(SearchKey,SearchDate,dmPrefix);
  if Idx <> -1 then
  begin
    Rec       := FDeleted.Entry(Idx);
    Country   := Rec.Country;
    Itu       := Rec.Itu;
    Waz       := Rec.Waz;
    UtcOffset := Rec.UtcOffset;
    Lat       := Rec.Latitude;
    Long      := Rec.Longitude;
    AdifText  := Rec.Adif;
    Cont      := UpperCase(Rec.Continent);
    NoDXCC    := Pos('no DXCC',Country) > 0;
    if TryStrToInt(AdifText,Adif) then
    begin
      if Adif > 0 then
      begin
        if ((Adif = 6) or (Adif = 9) or (Adif = 103) or (Adif = 110) or (Adif = 166) or (Adif = 202) or (Adif = 285) or (Adif = 291))
           and (UsState <> '') then
        begin
          StateAdif := StateInfo(UsState,Country,Lat,Long,Waz,Itu,UtcOffset,Cont);
          if StateAdif > 0 then
            Adif := StateAdif
        end;
        //instrumentation: this index has never been bounds-checked
        if (Adif < 0) or (Adif > High(FRef)) then
          DbgLog('DXCC','ADIF outside DXCCRefArray: adif='+IntToStr(Adif)+
                ' high='+IntToStr(High(FRef))+' call='+Call);
        Pfx    := FRef[Adif].pref;
        Result := Adif
      end
      else begin
        if NoDXCC then
          Pfx := '#'
        else
          Pfx  := '!';
        Result := 0
      end
    end
    else
      Result := 0;
    exit
  end
  else begin
    Pfx    := '!';
    Result := 0
  end;

  Idx := FValid.Find(SearchKey,SearchDate,dmPrefix);
  if Idx <> -1 then
  begin
    Rec       := FValid.Entry(Idx);
    Country   := Rec.Country;
    Itu       := Rec.Itu;
    Waz       := Rec.Waz;
    UtcOffset := Rec.UtcOffset;
    Lat       := Rec.Latitude;
    Long      := Rec.Longitude;
    AdifText  := Rec.Adif;
    Cont      := UpperCase(Rec.Continent);
    NoDXCC    := Pos('no DXCC',Country) > 0;
    if TryStrToInt(AdifText,Adif) then
    begin
      if Adif > 0 then
      begin
        if ((Adif = 6) or (Adif = 9) or (Adif = 103) or (Adif = 110) or (Adif = 166) or (Adif = 202) or (Adif = 285) or (Adif = 291))
           and (UsState <> '') then
        begin
          StateAdif := StateInfo(UsState,Country,Lat,Long,Waz,Itu,UtcOffset,Cont);
          if StateAdif > 0 then
            Adif := StateAdif
        end;
        //instrumentation: this index has never been bounds-checked
        if (Adif < 0) or (Adif > High(FRef)) then
          DbgLog('DXCC','ADIF outside DXCCRefArray: adif='+IntToStr(Adif)+
                ' high='+IntToStr(High(FRef))+' call='+Call);
        Pfx    := FRef[Adif].pref;
        Result := Adif
      end
      else begin
        if NoDXCC then
          Pfx := '#'
        else
          Pfx  := '!';
        Result := 0
      end;
      exit
    end
  end
  else begin
    Pfx    := '!';
    Result := 0
  end
end;

function TDxccService.IdCountry(const Call, UsState : String; ADate : TDateTime;
  var Pfx, Cont, Country, Waz, UtcOffset, Itu, Lat, Long : String) : Word;
begin
  EnterCriticalsection(FLock);
  try
    try
      Result := IdCountryLocked(Call,UsState,ADate,Pfx,Cont,Country,Waz,UtcOffset,Itu,Lat,Long)
    except
      on Ex: Exception do
      begin
        DbgLogException('DXCC','IdCountry call=' + Call +
                               ' date=' + DateToDDXCCDate(ADate), Ex);
        raise
      end
    end
  finally
    LeaveCriticalsection(FLock)
  end
end;

function TDxccService.IsException(const Call : String) : Boolean;
begin
  EnterCriticalsection(FLock);
  try
    Result := FRules.IsIgnoredSuffix(Call)
  finally
    LeaveCriticalsection(FLock)
  end
end;

function TDxccService.IsAmbiguous(const Call : String) : Boolean;
var
  i : Integer;
  s : String;
begin
  Result := False;
  EnterCriticalsection(FLock);
  try
    if Pos('/',Call) < 1 then
    begin
      for i:=0 to Length(FAmbiguous)-1 do
      begin
        if Pos(FAmbiguous[i],Call) = 1 then
        begin
          Result := True;
          Break
        end
      end
    end
    else begin
      if Length(Call) < 4 then
        exit;
      s := Call[1] + Call[2] + '/' + copy(Call,pos('/',Call)+1,1);
      for i:=0 to Length(FAmbiguous)-1 do
      begin
        if FAmbiguous[i] = s then
        begin
          Result := True;
          Break
        end
      end
    end
  finally
    LeaveCriticalsection(FLock)
  end
end;

function TDxccService.IsPrefix(const Pfx : String; ADate : TDateTime) : Boolean;
var
  Adif : Integer;
  FoundPfx, Country, Cont, Itu, Waz, UtcOffset, Lat, Long : String;
begin
  Cont := '';Waz := '';UtcOffset := '';Itu := '';Lat := '';Long := '';
  FoundPfx := '';Country := '';
  EnterCriticalsection(FLock);
  try
    //everything but the Boolean is thrown away here; the lookup exists only to
    //answer "is this a mark at all", which is what Exactly asks
    Result := FindCountry(Pfx,ADate,FoundPfx,Country,Cont,Itu,Waz,UtcOffset,Lat,Long,Adif,Exactly)
  finally
    LeaveCriticalsection(FLock)
  end
end;

function TDxccService.PfxFromAdif(Adif : Word) : String;
begin
  EnterCriticalsection(FLock);
  try
    Result := FRef[Adif].pref
  finally
    LeaveCriticalsection(FLock)
  end
end;

function TDxccService.CountryFromAdif(Adif : Word) : String;
begin
  EnterCriticalsection(FLock);
  try
    Result := FRef[Adif].name
  finally
    LeaveCriticalsection(FLock)
  end
end;

function TDxccService.AdifFromPfx(const Pfx : String) : Word;
var
  i : Integer;
begin
  Result := 0;
  EnterCriticalsection(FLock);
  try
    for i:=0 to Length(FRef)-1 do
    begin
      if FRef[i].pref = Pfx then
      begin
        Result := FRef[i].adif;
        exit
      end
    end
  finally
    LeaveCriticalsection(FLock)
  end
end;

function TDxccService.DeletedAdifList : String;
var
  i : Integer;
begin
  EnterCriticalsection(FLock);
  try
    Result := '(adif not in (';
    for i:=0 to Length(FDel)-1 do
    begin
      if i > 0 then
        Result := Result + ','+ IntToStr(FDel[i])
      else
        Result := Result + IntToStr(FDel[i])
    end;
    Result := Result + '))'
    //this ^^ is much faster than a chain of (adif <> n) AND ...
  finally
    LeaveCriticalsection(FLock)
  end
end;

initialization
  DxccService := TDxccService.Create;

finalization
  FreeAndNil(DxccService);

end.
