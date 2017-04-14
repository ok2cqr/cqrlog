unit fNewCallAlert;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls,LCLType;

type

  { TfrmNewCallAlert }

  TfrmNewCallAlert = class(TForm)
    Button1: TButton;
    Button2: TButton;
    cmbBand: TComboBox;
    cmbMode: TComboBox;
    edtCall: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Memo1 : TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmNewCallAlert: TfrmNewCallAlert;

implementation
{$R *.lfm}

uses dUtils;

{ TfrmNewCallAlert }

procedure TfrmNewCallAlert.FormCreate(Sender: TObject);
begin
  dmUtils.InsertModes(cmbMode);
  cmbMode.Items.Insert(0,'ALL');
  dmUtils.InsertBands(cmbBand);
  cmbBand.Items.Insert(0,'ALL')
end;

procedure TfrmNewCallAlert.Button1Click(Sender: TObject);
begin
  if (edtCall.Text = '') then
  begin
    Application.MessageBox('You have to insert a callsign, here!','Error ...',mb_OK+mb_IconError);
    edtCall.SetFocus
  end
  else
    ModalResult := mrOK
end;

procedure TfrmNewCallAlert.FormShow(Sender: TObject);
begin
  edtCall.SetFocus
end;

end.

