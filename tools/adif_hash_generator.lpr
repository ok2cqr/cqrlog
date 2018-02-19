program adif_hash_generator;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp
  { you can add units after this };

type

  { TAdifHash }

  TAdifHash = class(TCustomApplication)
  protected
    function  CreateHash(What : String) : longint;
    procedure DoRun; override;
  public
    constructor Create(TheOwner : TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TAdifHash }
function TAdifHash.CreateHash(What : String) : longint;
var
  z : LongInt;
  x : LongInt;
begin
  x := 0;
  for z := 1 to length(What) do
  begin
    x := (x shl 3) + ord(upcase(What[z]));
    x := x xor (x shr 16);
    x := x and $FFFF
  end;
  Result := x
end;

procedure TAdifHash.DoRun;
var
  ErrorMsg : String;
  Hash : LongInt;
begin
  // quick check parameters
  ErrorMsg := CheckOptions('h', 'help');
  if ErrorMsg <> '' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit
  end;

  // parse parameters
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit
  end;

  if (ParamCount = 0) then
  begin
    WriteHelp;
    Terminate;
    Exit
  end;

  Hash := CreateHash(ParamStr(1));
  Writeln('');
  Writeln('Source code to uADIFhash.pas:');
  Writeln('const h_' + upcase(ParamStr(1)), ' = ', Hash, ';');
  Writeln('');

  Terminate
end;

constructor TAdifHash.Create(TheOwner : TComponent);
begin
  inherited Create(TheOwner);
  StopOnException := True;
end;

destructor TAdifHash.Destroy;
begin
  inherited Destroy;
end;

procedure TAdifHash.WriteHelp;
begin
  Writeln('');
  Writeln('');
  Writeln('Usage: adif_hash_generator <adif tag name>');
  Writeln('');
  Writeln('Return hash number used to identify the tag in a ADIF file during the import. ');
  Writeln('This has to be added as a constant to uADIFhash.pas');
  Writeln('');
  Writeln('')
end;

var
  Application : TAdifHash;
begin
  Application := TAdifHash.Create(nil);
  Application.Title := 'Adif hash';
  Application.Run;
  Application.Free;
end.

