{ Prints odbec's collation table.  Used to pin the ordering down in tests and
  to document it; see tests/tCollation.pas. }
program dumpcollation;
{$mode objfpc}{$H+}
uses SysUtils, odbec;
var
  I: Integer;
  Line: string;
begin
  if (ParamCount > 0) and (ParamStr(1) = '--hex') then
  begin
    Line := '';
    for I := 0 to 255 do
    begin
      Line := Line + IntToHex(Ord(chr2bec(Chr(I))), 2);
      if (I mod 32) = 31 then
      begin
        WriteLn(Line);
        Line := '';
      end;
    end;
    Exit;
  end;
  { printable characters, in collation order }
  WriteLn('rank char');
  for I := 32 to 126 do
    WriteLn(Format('%4d  %s', [Ord(chr2bec(Chr(I))), Chr(I)]));
end.
