(*
  This unit sets LIBOVERLAY_SCROLLBAR=0 variable which disables new Ubuntu scrollbars
  for this application. Unit has to be as first (or second after cthreads) before
  the widgetset is inicialized.
*)

unit uScrollBars;

{$mode objfpc}

interface

uses
  Classes, SysUtils; 

implementation

function setenv(_para1:Pchar; _para2:Pchar; _para3:longint):longint;cdecl;external 'libc' name 'setenv';

initialization
  setenv(PChar('LIBOVERLAY_SCROLLBAR'),PChar('0'),1);
end.


