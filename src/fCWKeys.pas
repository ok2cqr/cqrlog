unit fCWKeys;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls,frCWKeys;

type

  { TfrmCWKeys }

  TfrmCWKeys = class(TForm)
    fraCWKeys : TfraCWKeys;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyUp(Sender : TObject; var Key : Word; Shift : TShiftState);
    procedure FormShow(Sender: TObject);
  private
    procedure SendCWMessage(cwkey : String);
  public
    { public declarations }
  end; 

var
  frmCWKeys: TfrmCWKeys;

implementation
  {$R *.lfm}

uses dUtils,fNewQSO;

{ TfrmCWKeys }

procedure TfrmCWKeys.SendCWMessage(cwkey : String);
begin
  frmNewQSO.CWint.SendText(dmUtils.GetCWMessage(cwkey,frmNewQSO.edtCall.Text,frmNewQSO.edtHisRST.Text,
                           frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''))
end;

procedure TfrmCWKeys.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmCWKeys)
end;

procedure TfrmCWKeys.FormKeyUp(Sender : TObject; var Key : Word;
  Shift : TShiftState);
begin
  if (Sender is TButton) then
    ShowMessage('JO')
end;

procedure TfrmCWKeys.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmCWKeys)
end;

end.

