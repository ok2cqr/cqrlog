unit uVersion;

{$mode objfpc}
interface

const
  {$IFDEF LCLGtk2}
    cVERSION    = '2.5.2 (001) Gtk2';
  {$ENDIF}
  {$IFDEF LCLQt5}
    cVERSION    = '2.5.2 (001) QT5';
  {$ENDIF}
  cMAJOR      = 2;
  cMINOR      = 5;
  cRELEAS     = 2;
  cBUILD      = 1;


  cBUILD_DATE = '2022-01-24';


implementation

end.

