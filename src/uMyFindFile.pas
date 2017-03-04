unit uMyFindFile;

{$mode objfpc}
interface

uses Classes, FileUtil;

function MyFindFile(FileName : String; Paths : TStringList) : String;

implementation

function MyFindFile(FileName : String; Paths : TStringList) : String;
var
  l : TStringList;
  i : Integer;
begin
  Result := '';
  for i:=0 to Paths.Count-1 do
  begin
    l:= FindAllFiles(Paths.Strings[i], FileName, False);
    if (l.Count>0) then
    begin
      Result := l.Strings[0];
      break
    end
  end
end;

end.
