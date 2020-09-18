unit fChangeOperator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons;

type

  { TfrmChangeOperator }

  TfrmChangeOperator = class(TForm)
    btnOK: TButton;
    btnStorno: TButton;
    edtOperator: TEdit;
    lblEnterOperator: TLabel;
    procedure btnOKClick(Sender: TObject);
    procedure edtOperatorChange(Sender: TObject);
    procedure edtOperatorKeyPress(Sender: TObject; var Key: char);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmChangeOperator: TfrmChangeOperator;

implementation
{$R *.lfm}

{ TfrmChangeOperator }
uses dUtils;

procedure TfrmChangeOperator.edtOperatorKeyPress(Sender: TObject; var Key: char);
begin
  if (key = #13) then
  begin
    btnOK.Click;
    Key := #0
  end
end;

procedure TfrmChangeOperator.btnOKClick(Sender: TObject);
begin
  ModalResult := mrOK
end;

procedure TfrmChangeOperator.edtOperatorChange(Sender: TObject);
begin
  edtOperator.SelStart := Length(edtOperator.Text);
end;

end.

