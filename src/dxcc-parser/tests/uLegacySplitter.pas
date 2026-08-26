(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ A verbatim transcription of TdmDXCC.CoVyhodnocovat (dDXCC.pas:449-641) and
  its helpers, so the ported version can be differentially tested against it.

  Unlike odbec and znacmech, which legacy/ reaches by symlink, this one has to
  be a copy: the original is a method of a TDataModule in a unit that pulls in
  Forms, Controls and LResources, so it cannot be compiled without the LCL.

  FROZEN.  This is now the only surviving copy of the old splitter.  As of the
  wiring commit, dDXCC.CoVyhodnocovat and dDXCluster.CoVyhodnocovat are one-line
  delegations to TDxccResolver, so there is no original left to track -- this
  file IS the "before" side of the comparison and must not be edited to follow
  dDXCC.pas.  Transcribed from dDXCC.pas at commit 561af345f072 (the last
  revision that still carried the algorithm).

  The earlier rule was the opposite: "if dDXCC.pas changes, re-transcribe".
  That rule is dead.  Changing this file now silently weakens the only evidence
  that the two engines agree.  The transcription is deliberately ugly: same
  structure, same order of tests, same variable roles, no tidying.

  Differences from the original, all forced by the extraction:
    - takes the tables through IDxccTable instead of the sez1/sez2 globals
    - takes the date as a 'YYYY/MM/DD' string, which is what
      DateToDDXCCDate (dDXCC.pas:896) hands the engine anyway
    - exceptions come from a TStringList instead of ExceptionArray
    - the two out-of-range writes the original performs on short callsigns
      (Prefix[3] and Prefix[4]) are guarded, because in Pascal they are
      undefined behaviour rather than behaviour worth reproducing }

unit uLegacySplitter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uDxccTableIntf, uDxccSuffixRules;

type
  TLegacySplitter = class
  private
    FValid: IDxccTable;
    FDeleted: IDxccTable;
    FRules: TDxccSuffixRules;
    function NaselCountry(const znacka, datum: string;
      var ADIF: Integer; presne: TMatchMode = mmPrefix): Boolean;
  public
    constructor Create(AValid, ADeleted: IDxccTable; ARules: TDxccSuffixRules);
    function CoVyhodnocovat(const znacka, datum: string;
      var UzNasel: Boolean; var ADIF: Integer): string;
  end;

implementation

constructor TLegacySplitter.Create(AValid, ADeleted: IDxccTable;
  ARules: TDxccSuffixRules);
begin
  inherited Create;
  FValid   := AValid;
  FDeleted := ADeleted;
  FRules   := ARules;
end;

{ dDXCC.pas:377 -- deleted table first, then the valid one. }
function TLegacySplitter.NaselCountry(const znacka, datum: string;
  var ADIF: Integer; presne: TMatchMode = mmPrefix): Boolean;
var
  x: Integer;
begin
  Result := False;
  x := FDeleted.Find(znacka, datum, presne);
  if x <> -1 then
  begin
    Result := True;
    if not TryStrToInt(FDeleted.Field(x, fldAdif), ADIF) then
      ADIF := 0;
    Exit;
  end;
  x := FValid.Find(znacka, datum, presne);
  if x <> -1 then
  begin
    Result := True;
    if not TryStrToInt(FValid.Field(x, fldAdif), ADIF) then
      ADIF := 0;
  end;
end;

{ dDXCC.pas:358 }
function Explode(const cSeparator, vString: string): TStringArray;
var
  i: Integer;
  S: string;
begin
  S := vString;
  Result := nil;
  i := 0;
  while Pos(cSeparator, S) > 0 do
  begin
    SetLength(Result, Length(Result) + 1);
    Result[i] := Copy(S, 1, Pos(cSeparator, S) - 1);
    Inc(i);
    S := Copy(S, Pos(cSeparator, S) + Length(cSeparator), Length(S));
  end;
  SetLength(Result, Length(Result) + 1);
  Result[i] := Copy(S, 1, Length(S));
end;

{ dDXCC.pas:162 }
function MyTryStrToInt(s: string; var i: Integer): Boolean;
begin
  i := 0;
  s := UpperCase(s);
  if (Length(s) > 0) and (s[1] = 'X') then
    Result := False
  else
    Result := TryStrToInt(s, i);
end;

function At(const S: string; Index: Integer): AnsiChar;
begin
  if (Index >= 1) and (Index <= Length(S)) then
    Result := S[Index]
  else
    Result := #0;
end;

{ dDXCC.pas:449 }
function TLegacySplitter.CoVyhodnocovat(const znacka, datum: string;
  var UzNasel: Boolean; var ADIF: Integer): string;
var
  Pole: TStringArray;
  pocet: Integer;
  pred_lomitkem: string;
  za_lomitkem: string;
  mezi_lomitky: string;
  tmp: Integer;
begin
  tmp := 0;
  Result := znacka;
  if Pos('/', znacka) > 0 then
  begin
    if NaselCountry(znacka, datum, adif, mmExact) then
    begin
      Result := znacka;
      UzNasel := True;
      Exit;
    end;

    SetLength(pole, 0);
    pole := Explode('/', znacka);
    pocet := Length(pole) - 1;
    case pocet of
      1:
        begin
          pred_lomitkem := pole[0];
          za_lomitkem := pole[1];
          if ((MyTryStrToInt(za_lomitkem, tmp)) and (Length(za_lomitkem) > 1)) then
          begin
            Result := pred_lomitkem;
            Exit;
          end;

          if (Length(pred_lomitkem) = 0) then
          begin
            Result := za_lomitkem;
            Exit;
          end;
          if (Length(za_lomitkem) = 0) then
          begin
            Result := pred_lomitkem;
            Exit;
          end;
          if (za_lomitkem = 'MM') or (za_lomitkem = 'MM1') or
             (za_lomitkem = 'MM2') or (za_lomitkem = 'MM3') or
             (za_lomitkem = 'AM') then
          begin
            Result := '?';
            Exit;
          end;
          if (Length(za_lomitkem) = 1) then
          begin
            if (((za_lomitkem[1] = 'M') or (za_lomitkem[1] = 'P')) and
                (Pos('LU', pred_lomitkem) <> 1)) then
            begin
              Result := pred_lomitkem;
              Exit;
            end;
            if (za_lomitkem[1] in ['0'..'9']) then   // SP2AD/1
            begin
              if (((At(pred_lomitkem, 1) = 'A') and (At(pred_lomitkem, 2) in ['A'..'L'])) or
                  (At(pred_lomitkem, 1) = 'K') or (At(pred_lomitkem, 1) = 'W') or
                  (At(pred_lomitkem, 1) = 'N')) then  // KL7AA/1 = W1
                Result := 'W' + za_lomitkem
              else
              begin
                if Length(pred_lomitkem) >= 3 then
                  pred_lomitkem[3] := za_lomitkem[1];
                Result := pred_lomitkem;
              end;
            end
            else
            begin
              // pokud je za lomitkem jen pismeno, nesmime zapomenout na
              // chudaky Argentince
              if ((za_lomitkem[1] in ['A'..'D', 'E', 'H', 'J', 'L'..'V', 'X'..'Z'])) then
              begin
                if (Pos('LU', pred_lomitkem) = 1) or (Pos('LW', pred_lomitkem) = 1) or
                   (Pos('AY', pred_lomitkem) = 1) or (Pos('AZ', pred_lomitkem) = 1) or
                   (Pos('LO', pred_lomitkem) = 1) or (Pos('LP', pred_lomitkem) = 1) or
                   (Pos('LQ', pred_lomitkem) = 1) or (Pos('LR', pred_lomitkem) = 1) or
                   (Pos('LS', pred_lomitkem) = 1) or (Pos('LT', pred_lomitkem) = 1) or
                   (Pos('LV', pred_lomitkem) = 1) then
                begin
                  if Length(pred_lomitkem) >= 4 then
                    pred_lomitkem[4] := za_lomitkem[1];
                  Result := pred_lomitkem;
                  Exit;
                end
                else                 // pokud to neni chudak Argentinec,
                  Result := znacka;  // nechame znacku napokoji
              end
              else
              begin
                UzNasel := True;
                Result := za_lomitkem;
              end;
              if NaselCountry(Copy(pred_lomitkem, 1, 2) + '/' + za_lomitkem, datum, ADIF) then
              begin
                UzNasel := True;
                Result := Copy(pred_lomitkem, 1, 2) + '/' + za_lomitkem;
                Exit;
              end;
            end;
          end
          else
          begin // za lomitkem je vic jak jedno pismenko
            if FRules.IsIgnoredSuffix(za_lomitkem) then
              Result := pred_lomitkem
            else
            begin
              if Length(za_lomitkem) >= Length(pred_lomitkem) then
              begin
                if not NaselCountry(pred_lomitkem, datum, ADIF, mmExactNoEquals) then
                begin
                  Result := za_lomitkem;
                  UzNasel := True;
                  Exit;
                end
                else
                begin
                  Result := pred_lomitkem;
                  Exit;
                end;
              end
              else
              begin // pred lomitkem je to delsi nebo rovno
                if not NaselCountry(za_lomitkem, datum, ADIF, mmExactNoEquals) then
                begin
                  Result := pred_lomitkem;
                  UzNasel := True;
                  Exit;
                end
                else
                begin
                  Result := za_lomitkem;
                  UzNasel := True;
                  Exit;
                end;
              end;
            end;
          end;
        end; // 1 lomitko

      2:
        begin
          pred_lomitkem := pole[0];
          mezi_lomitky := pole[1];
          za_lomitkem := pole[2];
          if Length(za_lomitkem) = 0 then
          begin
            Result := pred_lomitkem;
            Exit;
          end;
          if (((At(za_lomitkem, 1) = 'M') and (At(za_lomitkem, 2) = 'M')) or
              (za_lomitkem = 'AM')) then
          begin
            Result := '?';
            Exit;
          end;

          if Length(mezi_lomitky) > 0 then
          begin
            if (mezi_lomitky[1] in ['0'..'9']) then
            begin
              if (((At(pred_lomitkem, 1) = 'A') and (At(pred_lomitkem, 2) in ['A'..'L'])) or
                  (At(pred_lomitkem, 1) = 'K') or (At(pred_lomitkem, 1) = 'W')) then // KL7AA/1 = W1
                Result := 'W' + mezi_lomitky
              else
              begin
                if At(pred_lomitkem, 2) in ['0'..'9'] then // RA1AAA/2/M
                begin
                  if Length(pred_lomitkem) >= 2 then
                    pred_lomitkem[2] := mezi_lomitky[1];
                end
                else
                begin
                  if Length(pred_lomitkem) >= 3 then
                    pred_lomitkem[3] := mezi_lomitky[1];
                end;
                Result := pred_lomitkem;
                Exit;
              end;
            end;
          end;

          if ((Length(za_lomitkem) = 1) and (za_lomitkem[1] in ['A'..'Z'])) then
          begin
            if NaselCountry(pred_lomitkem + '/' + za_lomitkem, datum, ADIF) then
            begin
              Result := pred_lomitkem + '/' + za_lomitkem;
              UzNasel := True;
            end
            else
            begin
              Result := pred_lomitkem;
            end;
          end
          else
          begin
            if ((Length(za_lomitkem) = 1) and (za_lomitkem[1] in ['0'..'9'])) then
            begin
              if NaselCountry(At(pred_lomitkem, 1) + At(pred_lomitkem, 2) + za_lomitkem,
                              datum, ADIF) then // ZL1AMO/C
              begin
                Result := At(pred_lomitkem, 1) + At(pred_lomitkem, 2) + za_lomitkem;
                UzNasel := True;
              end
              else
                Result := pred_lomitkem;
            end
            else
              Result := pred_lomitkem;
          end;
        end; // 2 lomitka
    end; // case
  end;
end;

end.
