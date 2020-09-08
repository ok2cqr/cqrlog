unit uConnectionInfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TConnectionInfo = record
    HostName: string;
    Port: String;
    UserName: String;
    Password: String;
    DatabaseName: String;
  end;

implementation

end.

