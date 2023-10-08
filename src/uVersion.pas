unit uVersion;

{$mode objfpc}
interface

const
  cVersionBase     = '2.6.0_(119)_';

  {$IFDEF LCLGtk2}
  cVERSION    = cVersionBase+'Gtk2';
  {$ENDIF}
   {$IFDEF LCLGtk3}
  cVERSION    = cVersionBase+'Gtk3';
  {$ENDIF}
  {$IFDEF LCLQt5}
  cVERSION    = cVersionBase+'QT5';
  {$ENDIF}

  cMAJOR      = 2;
  cMINOR      = 6;
  cRELEAS     = 0;
  cBUILD      = 1;

  cBUILD_DATE = '2023-10-03';

implementation

end.

