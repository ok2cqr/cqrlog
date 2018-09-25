unit fChangeLocator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons;

type

  { TfrmChangeLocator }

  TfrmChangeLocator = class(TForm)
    btnOK: TButton;
    btnStorno: TButton;
    edtLocator: TEdit;
    lblEnterLocator: TLabel;
    procedure btnOKClick(Sender: TObject);
    procedure edtLocatorKeyPress(Sender: TObject; var Key: char);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmChangeLocator: TfrmChangeLocator;

implementation
{$R *.lfm}

{ TfrmChangeLocator }

procedure TfrmChangeLocator.edtLocatorKeyPress(Sender: TObject; var Key: char);
begin
  if (key = #13) then
  begin
    btnOK.Click;
    Key := #0
  end
end;

procedure TfrmChangeLocator.btnOKClick(Sender: TObject);
begin
  ModalResult := mrOK
end;

end.

