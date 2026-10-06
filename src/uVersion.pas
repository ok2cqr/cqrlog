unit uVersion;

{$mode objfpc}
interface

const
  cVersionBase     = '3.2.1_';

  {$IFDEF LCLGtk2}
  cVERSION    = cVersionBase+'Gtk2';
  {$ENDIF}
   {$IFDEF LCLGtk3}
  cVERSION    = cVersionBase+'Gtk3';
  {$ENDIF}
  {$IFDEF LCLQt5}
  cVERSION    = cVersionBase+'QT5';
  {$ENDIF}
  {$IFDEF LCLQt6}
  cVERSION    = cVersionBase+'QT6';
  {$ENDIF}
  {$IFDEF LCLCocoa}
  cVERSION    = cVersionBase+'Cocoa';
  {$ENDIF}

  cMAJOR      = 3;
  cMINOR      = 2;
  cRELEAS     = 1;
  cBUILD      = 1;

  cBUILD_DATE = '2026-10-06';

implementation

end.

