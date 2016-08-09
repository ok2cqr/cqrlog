unit fSCP;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, lcltype;

type

  { TfrmSCP }

  TfrmSCP = class(TForm)
    mSCP: TMemo;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmSCP: TfrmSCP;

implementation
{$R *.lfm}

uses dUtils, fNewQSO;

procedure TfrmSCP.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmSCP)
end;

procedure TfrmSCP.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmSCP)
end;

procedure TfrmSCP.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (key= VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0
  end
end;

end.

