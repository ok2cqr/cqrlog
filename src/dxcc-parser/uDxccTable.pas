(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ A DXCC prefix table: the marks from country.tab, indexed for lookup.
  Replaces Tseznam in znacmech.pas.

  Threading: an instance is immutable once Load has returned, so any number of
  threads may call Find on it concurrently.  Reloading is not concurrent-safe
  -- build a new instance and swap the reference instead of reloading in
  place, which is what the legacy ReloadDXCCTables does today without a lock
  while cluster and RBN worker threads are reading.

  Capacity: unlike the legacy engine there is no ceiling on entries or
  descriptions.  That matters -- znacmech.popisu_max is 10000 and the current
  files already need 9056, and overflowing it there does not fail loudly, it
  sets ziju:=false and every subsequent lookup silently returns "no country". }

unit uDxccTable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs, uDxccEntry, uDxccPattern, uDxccCollation, uDxccLimits;

type
  { How closely a pattern has to fit the callsign.  Maps onto dDXCC's
    NotExactly / Exactly / ExNoEquals. }
  TDxccMatchMode = (
    dmPrefix,          { the callsign may be longer than the pattern }
    dmExact,           { pattern and callsign must be the same length }
    dmExactNoEquals    { as dmExact, and '=' entries are skipped }
  );

  TDxccMessageEvent = procedure(const Message: string) of object;

  TDxccTable = class
  private
    type
      TMark = record
        Pattern: string;
        Key: string;      { SortKey(Pattern) -- what the index is ordered by }
        Entry: Integer;   { index into FEntries }
      end;
      TMarkArray = array of TMark;
  private
    FMarks: TMarkArray;
    FCount: Integer;
    FEntries: array of TDxccEntry;
    FEntryCount: Integer;
    FEntryIndex: TFPHashList;   { description text -> entry index, for dedup }
    FLoaded: Boolean;
    FSourceName: string;
    FOnMessage: TDxccMessageEvent;

    procedure Report(const Message: string);
    procedure AddLine(const Line: string);
    procedure AddRecord(const MarkPart, Description: string);
    procedure AddMarks(const MarkPart: string; EntryIndex: Integer);
    function  AddEntry(const Description: string): Integer;
    procedure SortMarks;

    { Lower bound of the scan range: the first mark whose key is >= Key, or
      -1 when every key is smaller. }
    function  LowerBound(const Probe: string): Integer;
    { The next mark still inside the range whose upper bound is Probe, or -1. }
    function  NextInRange(const Probe: string; Position: Integer): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromFile(const FileName: string);
    procedure LoadFromStream(Stream: TStream);
    procedure LoadFromString(const Text: string);

    { The best matching mark for Callsign on ADate, or -1.  ADate is
      'YYYY/MM/DD', or '*' for "ignore dates" / '!' for "match nothing". }
    function Find(const Callsign, ADate: string; Mode: TDxccMatchMode): Integer;

    function Pattern(Index: Integer): string;
    function Entry(Index: Integer): TDxccEntry;
    function IsValidOn(Index: Integer; const ADate: string): Boolean;

    property Count: Integer read FCount;
    property Loaded: Boolean read FLoaded;
    property SourceName: string read FSourceName;
    property OnMessage: TDxccMessageEvent read FOnMessage write FOnMessage;
  end;

implementation

const
  { The legacy loader accumulated each half of a line in a shortstring, so
    anything past these lengths was dropped before it could be stored.  The
    current files stay well inside both (longest description 226), but the
    behaviour is preserved rather than assumed irrelevant. }
  MaxMarkPartLength = 255;

constructor TDxccTable.Create;
begin
  inherited Create;
  FEntryIndex := TFPHashList.Create;
end;

destructor TDxccTable.Destroy;
begin
  FEntryIndex.Free;
  inherited Destroy;
end;

procedure TDxccTable.Report(const Message: string);
begin
  if Assigned(FOnMessage) then
    FOnMessage(Message);
end;

{ --- loading ----------------------------------------------------------- }

function TDxccTable.AddEntry(const Description: string): Integer;
var
  Existing: Pointer;
  Text: string;
begin
  Text := Copy(Description, 1, MaxDescriptionLength);

  { Descriptions repeat heavily -- 21560 marks share 9056 of them -- so they
    are stored once and referenced. }
  Existing := FEntryIndex.Find(Text);
  if Existing <> nil then
    Exit(PtrInt(Existing) - 1);

  if FEntryCount = Length(FEntries) then
    SetLength(FEntries, 256 + Length(FEntries) * 2);
  ParseDescription(Text, FEntries[FEntryCount]);
  Result := FEntryCount;
  Inc(FEntryCount);
  { TFPHashList stores pointers and treats nil as absent, so the index is
    offset by one. }
  FEntryIndex.Add(Text, Pointer(PtrInt(Result + 1)));
end;

procedure TDxccTable.AddMarks(const MarkPart: string; EntryIndex: Integer);
var
  I, Start: Integer;
  Mark: string;

  procedure Emit(const Raw: string);
  var
    Trimmed: string;
  begin
    Trimmed := Trim(Raw);
    if Trimmed = '' then
      Exit;
    if Length(Trimmed) > MaxMarkLength then
    begin
      Report('mark longer than ' + IntToStr(MaxMarkLength) +
             ' characters, truncated: ' + Trimmed);
      Trimmed := Copy(Trimmed, 1, MaxMarkLength);
    end;
    if FCount = Length(FMarks) then
      SetLength(FMarks, 1024 + Length(FMarks) * 2);
    FMarks[FCount].Pattern := Trimmed;
    FMarks[FCount].Key     := SortKey(Trimmed);
    FMarks[FCount].Entry   := EntryIndex;
    Inc(FCount);
  end;

begin
  Start := 1;
  for I := 1 to Length(MarkPart) do
    if MarkPart[I] = ' ' then
    begin
      Emit(Copy(MarkPart, Start, I - Start));
      Start := I + 1;
    end;
  Mark := Copy(MarkPart, Start, Length(MarkPart) - Start + 1);
  Emit(Mark);
end;

procedure TDxccTable.AddRecord(const MarkPart, Description: string);
begin
  if (MarkPart = '') or (Description = '') then
    Exit;
  AddMarks(MarkPart, AddEntry(Description));
end;

procedure TDxccTable.AddLine(const Line: string);
var
  Bar, LastBar, SpacePos, EqPos, I: Integer;
  MarkPart, Description, Window, Head, Tail, Suffix: string;
begin
  Bar := Pos('|', Line);
  if Bar = 0 then
    Exit;                       { no description, nothing to record }

  MarkPart    := Copy(Line, 1, Bar - 1);
  Description := Copy(Line, Bar + 1, Length(Line));
  if Length(MarkPart) > MaxMarkPartLength then
    MarkPart := Copy(MarkPart, 1, MaxMarkPartLength);

  { A validity window holding two space-separated periods describes one
    entity that was active twice, and becomes two records sharing everything
    else.  No line in the current files does this, but the loader has always
    supported it. }
  LastBar := 0;
  for I := Length(Description) downto 1 do
    if Description[I] = '|' then
    begin
      LastBar := I;
      Break;
    end;

  if LastBar > 0 then
  begin
    Window := Copy(Description, LastBar + 1, Length(Description));
    SpacePos := Pos(' ', Window);
    if SpacePos > 0 then
    begin
      Head := Copy(Description, 1, LastBar);
      EqPos := Pos('=', Window);
      if EqPos > 0 then
        Suffix := Copy(Window, EqPos, Length(Window))
      else
      begin
        Suffix := '';
        EqPos  := Length(Window) + 1;
      end;
      Tail := Copy(Window, 1, SpacePos - 1);
      AddRecord(MarkPart, Head + Tail + Suffix);
      Tail := Copy(Window, SpacePos + 1, EqPos - SpacePos - 1);
      AddRecord(MarkPart, Head + Tail + Suffix);
      Exit;
    end;
  end;

  AddRecord(MarkPart, Description);
end;

procedure TDxccTable.LoadFromString(const Text: string);
var
  I: Integer;
  Line: string;
  C: AnsiChar;
begin
  Line := '';
  for I := 1 to Length(Text) do
  begin
    C := Text[I];
    if C = #10 then
    begin
      AddLine(Line);
      Line := '';
    end
    { Everything below 32 is dropped, which is how CRLF files load cleanly. }
    else if C > #31 then
      Line := Line + C;
  end;
  if Line <> '' then
    AddLine(Line);

  SortMarks;
  FLoaded := True;
end;

procedure TDxccTable.LoadFromStream(Stream: TStream);
var
  Text: string;
begin
  SetLength(Text, Stream.Size - Stream.Position);
  if Length(Text) > 0 then
    Stream.ReadBuffer(Text[1], Length(Text));
  LoadFromString(Text);
end;

procedure TDxccTable.LoadFromFile(const FileName: string);
var
  Stream: TFileStream;
begin
  FSourceName := FileName;
  if not FileExists(FileName) then
  begin
    { The legacy constructor reported this and carried on with a dead table
      rather than raising, and callers rely on that. }
    Report('file not found: ' + FileName);
    FLoaded := False;
    Exit;
  end;
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

{ Bottom-up merge sort.  Stability is not optional here: Find scans the index
  in order and keeps the first of two equally good candidates, so the relative
  order of marks with identical keys decides which country a callsign gets. }
procedure TDxccTable.SortMarks;
var
  Buffer: TMarkArray;
  Width, I, Left, Mid, Right, A, B, Target: Integer;
begin
  if FCount < 2 then
    Exit;
  SetLength(Buffer, FCount);
  Width := 1;
  while Width < FCount do
  begin
    I := 0;
    while I < FCount do
    begin
      Left  := I;
      Mid   := I + Width;
      Right := I + Width * 2;
      if Mid > FCount then Mid := FCount;
      if Right > FCount then Right := FCount;
      A := Left;
      B := Mid;
      Target := Left;
      while (A < Mid) or (B < Right) do
      begin
        if A >= Mid then
        begin
          Buffer[Target] := FMarks[B]; Inc(B);
        end
        else if B >= Right then
        begin
          Buffer[Target] := FMarks[A]; Inc(A);
        end
        { Take from the left unless the left is strictly greater -- this is
          what makes the sort stable. }
        else if FMarks[A].Key > FMarks[B].Key then
        begin
          Buffer[Target] := FMarks[B]; Inc(B);
        end
        else
        begin
          Buffer[Target] := FMarks[A]; Inc(A);
        end;
        Inc(Target);
      end;
      Inc(I, Width * 2);
    end;
    for I := 0 to FCount - 1 do
      FMarks[I] := Buffer[I];
    Width := Width * 2;
  end;
end;

{ --- lookup ------------------------------------------------------------ }

function TDxccTable.LowerBound(const Probe: string): Integer;
var
  Key: string;
  Low, High, Mid: Integer;
begin
  Result := -1;
  if FCount = 0 then
    Exit;
  Key := SortKey(Probe);

  Low  := 0;
  High := FCount - 1;
  while Low < High do
  begin
    Mid := (Low + High) div 2;
    if FMarks[Mid].Key >= Key then
      High := Mid
    else
      Low := Mid + 1;
  end;

  { Low is now the first index whose key is >= Key, unless no key is. }
  if FMarks[Low].Key < Key then
    Result := -1
  else
    Result := Low;
end;

function TDxccTable.NextInRange(const Probe: string; Position: Integer): Integer;
var
  Limit: string;
begin
  Result := -1;
  Inc(Position);
  if (Position < 0) or (Position >= FCount) then
    Exit;

  { The range runs up to and including the probe key with its last byte
    incremented, which is how a one-character wildcard span such as
    'O[' .. 'O?' is expressed as a single comparison. }
  Limit := SortKey(Probe);
  if Length(Limit) > 0 then
    Limit[Length(Limit)] := Chr(Ord(Limit[Length(Limit)]) + 1);

  if FMarks[Position].Key <= Limit then
    Result := Position;
end;

function TDxccTable.Find(const Callsign, ADate: string;
  Mode: TDxccMatchMode): Integer;
var
  Best: Integer;
  FoundExact: Boolean;
  CallLength: Integer;

  procedure Scan(const FromProbe, ToProbe: string);
  var
    Position, BestLength, ThisLength: Integer;
    ThisPattern: string;
    IsExactEntry: Boolean;
  begin
    Position := LowerBound(FromProbe);
    if Position < 0 then
      Exit;
    repeat
      if PatternMatches(FMarks[Position].Pattern, Callsign) and
         IsValidOn(Position, ADate) then
      begin
        ThisPattern  := FMarks[Position].Pattern;
        ThisLength   := PatternLength(ThisPattern);
        IsExactEntry := (ThisPattern <> '') and (ThisPattern[1] = ExactMarker);

        if (Mode <> dmExactNoEquals) or (not IsExactEntry) then
          if (Mode = dmPrefix) or (ThisLength = CallLength) then
          begin
            if IsExactEntry then
            begin
              { An explicit callsign beats anything a pattern can offer, and
                ends the search. }
              FoundExact := True;
              Best := Position;
            end
            else if Best = -1 then
              Best := Position
            else
            begin
              BestLength := PatternLength(FMarks[Best].Pattern);
              if ThisLength > BestLength then
                Best := Position
              else if (ThisLength = BestLength) and
                      IsMoreSpecific(ThisPattern, FMarks[Best].Pattern) then
                Best := Position;
            end;
          end;
      end;
      Position := NextInRange(ToProbe, Position);
    until (Position < 0) or FoundExact;
  end;

begin
  Best := -1;
  FoundExact := False;
  CallLength := Length(Callsign);

  if CallLength >= 2 then
  begin
    { Marks whose first two characters are literal. }
    Scan(Copy(Callsign, 1, 2), Copy(Callsign, 1, 2));
    { Marks whose second character is a metacharacter.  One scan covers all
      five of them because the collation keeps them adjacent. }
    Scan(Copy(Callsign, 1, 1) + '[', Copy(Callsign, 1, 1) + '?');
  end;

  if (CallLength = 1) or (Best = -1) then
    Scan(Copy(Callsign, 1, 1), Copy(Callsign, 1, 1));

  Result := Best;
end;

function TDxccTable.Pattern(Index: Integer): string;
begin
  if (Index >= 0) and (Index < FCount) then
    Result := FMarks[Index].Pattern
  else
  begin
    Report('Pattern: index out of range: ' + IntToStr(Index));
    Result := '';
  end;
end;

function TDxccTable.Entry(Index: Integer): TDxccEntry;
begin
  if (Index >= 0) and (Index < FCount) then
    Result := FEntries[FMarks[Index].Entry]
  else
  begin
    Report('Entry: index out of range: ' + IntToStr(Index));
    ClearEntry(Result);
  end;
end;

function TDxccTable.IsValidOn(Index: Integer; const ADate: string): Boolean;
begin
  if (Index >= 0) and (Index < FCount) then
    Result := uDxccEntry.IsValidOn(FEntries[FMarks[Index].Entry], ADate)
  else
  begin
    Report('IsValidOn: index out of range: ' + IntToStr(Index));
    Result := False;
  end;
end;

end.
