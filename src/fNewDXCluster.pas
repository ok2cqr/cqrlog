unit fNewDXCluster;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons;

type

  { TfrmNewDXCluster }

  TfrmNewDXCluster = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    edtPassword: TEdit;
    edtUserName: TEdit;
    edtPort: TEdit;
    edtAddress: TEdit;
    edtDescription: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmNewDXCluster: TfrmNewDXCluster;

implementation
{$R *.lfm}

{ TfrmNewDXCluster }
uses dUtils;

procedure TfrmNewDXCluster.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(self);
end;

end.

