unit uMyIni;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, iniFiles, dynlibs,strutils;

type
  TMyIni = class
    ini  : TMemIniFile;
    lini : TMemIniFile;
    crit : TRTLCriticalSection;
  private
    LocalSections : String;
    fIniFileName : String;
  public
    property IniFileName : String read fIniFileName;

    constructor Create(IniFile,LocalIniFile : String);
    destructor  Destroy; override;

    function  ReadString(const Section, Ident, Default: string): string;
    function  ReadInteger(const Section, Ident: string; Default: Longint;ToLocal : Boolean=FALSE): Longint;
    function  ReadBool(const Section, Ident: string; Default: Boolean;ToLocal : Boolean=FALSE): Boolean;
    function  ReadFloat(const Section, Ident: string; Default: Double): Double;
    function  SectionExists(Section : String) : Boolean;
    function  SectionErase(Section : String) : Boolean;
    function  LocalOnly(Section : String) : Boolean;

    procedure WriteString(const Section, Ident, Value: String;ToLocal : Boolean=FALSE);
    procedure WriteInteger(const Section, Ident: string; Value: Longint;ToLocal : Boolean=FALSE);
    procedure WriteBool(const Section, Ident: string; Value: Boolean;ToLocal : Boolean=FALSE);
    procedure WriteFloat(const Section, Ident: string; Value: Double);
    procedure SaveToDisk;
    procedure DeleteKey(const Section, Ident: String;ToLocal : Boolean=FALSE);
    procedure ReadSection(const Section: string; Strings: TStrings;ToLocal : Boolean=FALSE);
    procedure ReadSectionRaw(const Section: string; Strings: TStrings);
    procedure LoadLocalSectionsList;
    procedure SetCache(c:boolean=false);
end;

var
  cqrini : TMyIni;

implementation

constructor TMyIni.Create(IniFile,LocalIniFile : String);
begin
  InitCriticalSection(crit);
  fIniFileName := IniFile;
  ini  := TMemIniFile.Create(IniFile);
  lini := TMemIniFile.Create(LocalIniFile);
  ini.CacheUpdates :=false;    //should be as default, but is it?
  lini.CacheUpdates :=false;
end;

procedure TMyIni.SetCache(c:boolean=false);
Begin
  ini.CacheUpdates :=c;
  lini.CacheUpdates :=c;
end;

function TMyIni.ReadString(const Section, Ident, Default: string): string;
begin
  EnterCriticalsection(crit);
  try
    if LocalOnly(Section) then
      Result := lini.ReadString(Section, Ident, Default)
    else
      Result := ini.ReadString(Section, Ident, Default)
  finally
    LeaveCriticalsection(crit)
  end
end;

function TMyIni.ReadInteger(const Section, Ident: string; Default: Longint;ToLocal : Boolean=FALSE): Longint;
begin
  EnterCriticalsection(crit);
  try
    if (LocalOnly(Section) or ToLocal) then
      Result := lini.ReadInteger(Section, Ident, Default)
    else
      Result := ini.ReadInteger(Section, Ident, Default)
  finally
    LeaveCriticalsection(crit)
  end
end;

function TMyIni.ReadBool(const Section, Ident: string; Default: Boolean;ToLocal : Boolean=FALSE): Boolean;
begin
  EnterCriticalsection(crit);
  try
    if (LocalOnly(Section) or ToLocal)  then
      Result := lini.ReadBool(Section, Ident, Default)
    else
      Result := ini.ReadBool(Section, Ident, Default)
  finally
    LeaveCriticalsection(crit)
  end
end;

function TMyIni.ReadFloat(const Section, Ident: string; Default: Double): Double;
begin
  EnterCriticalsection(crit);
  try
    if LocalOnly(Section) then
      Result := lini.ReadFloat(Section, Ident, Default)
    else
      Result := ini.ReadFloat(Section, Ident, Default)
  finally
    LeaveCriticalsection(crit)
  end
end;


procedure TMyIni.WriteString(const Section, Ident, Value: String;ToLocal : Boolean=FALSE);
begin
  EnterCriticalsection(crit);
  try
    if (LocalOnly(Section) or ToLocal) then
      lini.WriteString(Section, Ident, Value)
    else
      ini.WriteString(Section, Ident, Value)
  finally
    LeaveCriticalsection(crit)
  end
end;

procedure TMyIni.WriteInteger(const Section, Ident: string; Value: Longint;ToLocal : Boolean=FALSE);
begin
  EnterCriticalsection(crit);
  try
    if (LocalOnly(Section) or ToLocal) then
      lini.WriteInteger(Section, Ident, Value)
    else
      ini.WriteInteger(Section, Ident, Value)
  finally
    LeaveCriticalsection(crit)
  end
end;

procedure TMyIni.WriteBool(const Section, Ident: string; Value: Boolean;ToLocal : Boolean=FALSE);
begin
  EnterCriticalsection(crit);
  try
    if (LocalOnly(Section) or ToLocal) then
      lini.WriteBool(Section, Ident, Value)
    else
      ini.WriteBool(Section, Ident, Value)
  finally
    LeaveCriticalsection(crit)
  end
end;

procedure TMyIni.WriteFloat(const Section, Ident: string; Value: Double);
begin
  EnterCriticalsection(crit);
  try
    if LocalOnly(Section) then
      lini.WriteFloat(Section, Ident, Value)
    else
      ini.WriteFloat(Section, Ident, Value)
  finally
    LeaveCriticalsection(crit)
  end
end;

procedure TMyIni.SaveToDisk;
begin
  EnterCriticalsection(crit);
  try
    ini.UpdateFile;
    lini.UpdateFile
  finally
    LeaveCriticalsection(crit)
  end
end;

procedure TMyIni.DeleteKey(const Section, Ident: String;ToLocal : Boolean=FALSE);
begin
  EnterCriticalsection(crit);
  try
    if (LocalOnly(Section) or ToLocal) then
      lini.DeleteKey(Section,Ident)
    else
      ini.DeleteKey(Section,Ident)
  finally
    LeaveCriticalsection(crit)
  end
end;

procedure TMyIni.ReadSection(const Section: string; Strings: TStrings;ToLocal : Boolean=FALSE);
begin
  EnterCriticalsection(crit);
  try
    if (LocalOnly(Section) or ToLocal) then
      lini.ReadSection(Section,Strings)
    else
      ini.ReadSection(Section,Strings)
  finally
    LeaveCriticalsection(crit)
  end
end;

procedure TMyIni.ReadSectionRaw(const Section: string; Strings: TStrings);
begin
  EnterCriticalsection(crit);
  try
    if LocalOnly(Section) then
      lini.ReadSectionRaw(Section,Strings)
    else
      ini.ReadSectionRaw(Section,Strings)
  finally
    LeaveCriticalsection(crit)
  end
end;


function TMyIni.SectionExists(Section : String) : Boolean;
begin
  EnterCriticalsection(crit);
  try
    if LocalOnly(Section) then
      Result := lini.SectionExists(Section)
    else
      Result := ini.SectionExists(Section)
  finally
    LeaveCriticalsection(crit)
  end
end;
function TMyIni.SectionErase(Section : String) : Boolean;
begin
  EnterCriticalsection(crit);
  try
    if SectionExists(Section) then
      begin
         if LocalOnly(Section) then
           Begin
             Result := true;
             lini.EraseSection(Section)
           end
       else
           begin
             Result := true;
             ini.EraseSection(Section)
           end;
      end
    else
      Result:=false;
  finally
    LeaveCriticalsection(crit)
  end

end;

function TMyIni.LocalOnly(Section : String) : Boolean;
begin
  Result := IsWordPresent(Section,LocalSections,[',']);
end;

procedure TMyIni.LoadLocalSectionsList;
begin
  LocalSections := cqrini.ReadString('ConfigStorage','Items','')
end;

destructor TMyIni.Destroy;
begin
  inherited;
  ini.UpdateFile;
  FreeAndNil(ini);
  lini.UpdateFile;
  FreeAndNil(lini);
  DoneCriticalsection(crit)
end;

initialization

finalization
// Writeln('Closing ini file ...') // we do not want this with options "version" and "debug", and it is not needed in any way
end.

