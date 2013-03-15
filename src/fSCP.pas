unit fSCP;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls;

type

  { TfrmSCP }

  TfrmSCP = class(TForm)
    mSCP: TMemo;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmSCP: TfrmSCP;

implementation

uses dUtils;

procedure TfrmSCP.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmSCP)
end;

procedure TfrmSCP.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmSCP)
end;

initialization
  {$I fSCP.lrs}

end.

