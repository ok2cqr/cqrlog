unit uMyIni;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, iniFiles, dynlibs;

type
  TMyIni = class
    ini  : TMemIniFile;
    crit : TRTLCriticalSection;
  private
    fIniFileName : String;
  public
    property IniFileName : String read fIniFileName;

    constructor Create(IniFile : String);
    destructor  Destroy; override;

    function  ReadString(const Section, Ident, Default: string): string;
    function  ReadInteger(const Section, Ident: string; Default: Longint): Longint;
    function  ReadBool(const Section, Ident: string; Default: Boolean): Boolean;
    function  ReadFloat(const Section, Ident: string; Default: Double): Double;
    function  SectionExists(Section : String) : Boolean;

    procedure WriteString(const Section, Ident, Value: String);
    procedure WriteInteger(const Section, Ident: string; Value: Longint);
    procedure WriteBool(const Section, Ident: string; Value: Boolean);
    procedure WriteFloat(const Section, Ident: string; Value: Double);
    procedure SaveToDisk;
    procedure DeleteKey(const Section, Ident: String);
    procedure ReadSection(const Section: string; Strings: TStrings);
    procedure ReadSectionRaw(const Section: string; Strings: TStrings);
end;

var
  cqrini : TMyIni;

implementation

constructor TMyIni.Create(IniFile : String);
begin
  InitCriticalSection(crit);
  fIniFileName := IniFile;
  ini := TMemIniFile.Create(IniFile)
end;

function TMyIni.ReadString(const Section, Ident, Default: string): string;
begin
  EnterCriticalsection(crit);
  try
    Result := ini.ReadString(Section, Ident, Default)
  finally
    LeaveCriticalsection(crit)
  end
end;

function TMyIni.ReadInteger(const Section, Ident: string; Default: Longint): Longint;
begin
  EnterCriticalsection(crit);
  try
    Result := ini.ReadInteger(Section, Ident, Default)
  finally
    LeaveCriticalsection(crit)
  end
end;

function TMyIni.ReadBool(const Section, Ident: string; Default: Boolean): Boolean;
begin
  EnterCriticalsection(crit);
  try
    Result := ini.ReadBool(Section, Ident, Default)
  finally
    LeaveCriticalsection(crit)
  end
end;

function TMyIni.ReadFloat(const Section, Ident: string; Default: Double): Double;
begin
  EnterCriticalsection(crit);
  try
    Result := ini.ReadFloat(Section, Ident, Default)
  finally
    LeaveCriticalsection(crit)
  end
end;


procedure TMyIni.WriteString(const Section, Ident, Value: String);
begin
  EnterCriticalsection(crit);
  try
    ini.WriteString(Section, Ident, Value)
  finally
    LeaveCriticalsection(crit)
  end
end;

procedure TMyIni.WriteInteger(const Section, Ident: string; Value: Longint);
begin
  EnterCriticalsection(crit);
  try
    ini.WriteInteger(Section, Ident, Value)
  finally
    LeaveCriticalsection(crit)
  end
end;

procedure TMyIni.WriteBool(const Section, Ident: string; Value: Boolean);
begin
  EnterCriticalsection(crit);
  try
    ini.WriteBool(Section, Ident, Value)
  finally
    LeaveCriticalsection(crit)
  end
end;

procedure TMyIni.WriteFloat(const Section, Ident: string; Value: Double);
begin
  EnterCriticalsection(crit);
  try
    ini.WriteFloat(Section, Ident, Value)
  finally
    LeaveCriticalsection(crit)
  end
end;

procedure TMyIni.SaveToDisk;
begin
  EnterCriticalsection(crit);
  try
    ini.UpdateFile
  finally
    LeaveCriticalsection(crit)
  end
end;

procedure TMyIni.DeleteKey(const Section, Ident: String);
begin
  EnterCriticalsection(crit);
  try
    ini.DeleteKey(Section,Ident)
  finally
    LeaveCriticalsection(crit)
  end
end;

procedure TMyIni.ReadSection(const Section: string; Strings: TStrings);
begin
  EnterCriticalsection(crit);
  try
    ini.ReadSection(Section,Strings)
  finally
    LeaveCriticalsection(crit)
  end
end;

procedure TMyIni.ReadSectionRaw(const Section: string; Strings: TStrings);
begin
  EnterCriticalsection(crit);
  try
    ini.ReadSectionRaw(Section,Strings)
  finally
    LeaveCriticalsection(crit)
  end
end;


function TMyIni.SectionExists(Section : String) : Boolean;
begin
  EnterCriticalsection(crit);
  try
    Result := ini.SectionExists(Section);
  finally
    LeaveCriticalsection(crit)
  end
end;

destructor TMyIni.Destroy;
begin
  inherited;
  ini.UpdateFile;
  ini.Free;
  DoneCriticalsection(crit)
end;

initialization

finalization
  cqrini.Free;
  Writeln('Closing ini file ...')
end.

