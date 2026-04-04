{$ifdef WINDOWS}
  Winsock2,
{$endif}

{$ifdef UNIX}
  BaseUnix, NetDB,
  {$IF FPC_FULLVERSION > 30202}
    Unix,
  {$ENDIF}
{$endif}

{$ifdef NETWARE}
  WinSock,
{$endif}

{$ifdef OS2}
  WinSock,
{$endif}

  SysUtils, Sockets;

