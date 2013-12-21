unit dLogUpload;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, FileUtil, LResources,
  dynlibs, lcltype, ExtCtrls, sqlscript, process, mysql51dyn, ssl_openssl_lib,
  mysql55dyn, mysql55conn, mysql51conn, db;

type

  { TdmLogUpload }

  TdmLogUpload = class(TDataModule)
    Q: TSQLQuery;
    trQ: TSQLTransaction;
    procedure DataModuleCreate(Sender: TObject);
  private

  public
    LogUploadCon : TSQLConnection;
  end; 

var
  dmLogUpload: TdmLogUpload;

implementation

uses dData;

procedure TdmLogUpload.DataModuleCreate(Sender: TObject);
var
  i : Integer;
begin
  if dmData.MySQLVersion < 5.5 then
    LogUploadCon := TMySQL51Connection.Create(self)
  else
    LogUploadCon := TMySQL55Connection.Create(self);

  LogUploadCon.KeepConnection := True;
  for i:=0 to ComponentCount-1 do
  begin
    if Components[i] is TSQLQuery then
      (Components[i] as TSQLQuery).DataBase := LogUploadCon;
    if Components[i] is TSQLTransaction then
      (Components[i] as TSQLTransaction).DataBase := LogUploadCon
  end
end;

initialization
  {$I dLogUpload.lrs}

end.

