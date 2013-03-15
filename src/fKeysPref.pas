unit fKeysPref;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls;

type

  { TfrmKeysPref }

  TfrmKeysPref = class(TForm)
    btnCancel: TButton;
    btnOK: TButton;
    cmbSBackSlash: TComboBox;
    cmbREmptyExch: TComboBox;
    cmbSEmptyExch: TComboBox;
    cmbSNoCallChange: TComboBox;
    cmbRNotEmptyExch: TComboBox;
    cmbRCallChange: TComboBox;
    cmbRNoCallChange: TComboBox;
    cmbRBackSlash: TComboBox;
    cmbSNotEmptyExch: TComboBox;
    edtSBackSlash: TEdit;
    edtSEmptyExch: TEdit;
    edtRNoCallChange: TEdit;
    edtRBackSlash: TEdit;
    edtSNoCallChange: TEdit;
    edtRNotEmptyExch: TEdit;
    edtREmptyExch: TEdit;
    edtSNotEmptyExch: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    ntbKeyboard: TNotebook;
    pgSP: TPage;
    pgRun: TPage;
    Panel1: TPanel;
    procedure btnOKClick(Sender: TObject);
    procedure cmbRBackSlashChange(Sender: TObject);
    procedure cmbREmptyExchChange(Sender: TObject);
    procedure cmbRNoCallChangeChange(Sender: TObject);
    procedure cmbRNotEmptyExchChange(Sender: TObject);
    procedure cmbSBackSlashChange(Sender: TObject);
    procedure cmbSEmptyExchChange(Sender: TObject);
    procedure cmbSNoCallChangeChange(Sender: TObject);
    procedure cmbSNotEmptyExchChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmKeysPref: TfrmKeysPref;

implementation

uses dData, uMyini;
{ TfrmKeysPref }

procedure TfrmKeysPref.cmbREmptyExchChange(Sender: TObject);
begin
  if (cmbREmptyExch.ItemIndex = cmbREmptyExch.Items.Count-1) then
    edtREmptyExch.Visible := True
  else
    edtREmptyExch.Visible := False
end;

procedure TfrmKeysPref.cmbRBackSlashChange(Sender: TObject);
begin
  if (cmbRBackSlash.ItemIndex = cmbRBackSlash.Items.Count-1) then
    edtRBackSlash.Visible := True
  else
    edtRBackSlash.Visible := False
end;

procedure TfrmKeysPref.btnOKClick(Sender: TObject);
begin
  cqrini.WriteInteger('KeysPref','REmptyExch',cmbREmptyExch.ItemIndex);
  cqrini.WriteInteger('KeysPref','RNotEmptyExch',cmbRNotEmptyExch.ItemIndex);
  cqrini.WriteString('KeysPref','REmptyExchC',edtREmptyExch.Text);
  cqrini.WriteString('KeysPref','RNotEmptyExchC',edtRNotEmptyExch.Text);
  cqrini.WriteInteger('KeysPref','RNoCallChange',cmbRNoCallChange.ItemIndex);
  cqrini.WriteInteger('KeysPref','RCallChange',cmbRCallChange.ItemIndex);
  cqrini.WriteInteger('KeysPref','RBackSlash',cmbRBackSlash.ItemIndex);
  cqrini.WriteString('KeysPref','RNoCallChangeC',edtRNoCallChange.Text);
  cqrini.WriteString('KeysPref','RBackSlashC',edtRBackSlash.Text);

  cqrini.WriteInteger('KeysPref','SEmptyExch',cmbSEmptyExch.ItemIndex);
  cqrini.WriteInteger('KeysPref','SNotEmptyExch',cmbSNotEmptyExch.ItemIndex);
  cqrini.WriteString('KeysPref','SEmptyExchC',edtSEmptyExch.Text);
  cqrini.WriteString('KeysPref','SNotEmptyExchC',edtSNotEmptyExch.Text);
  cqrini.WriteInteger('KeysPref','SNoCallChange',cmbSNoCallChange.ItemIndex);
  cqrini.WriteInteger('KeysPref','SBackSlash',cmbSBackSlash.ItemIndex);
  cqrini.WriteString('KeysPref','SNoCallChangeC',edtSNoCallChange.Text);
  cqrini.WriteString('KeysPref','SBackSlashC',edtSBackSlash.Text)
end;

procedure TfrmKeysPref.cmbRNoCallChangeChange(Sender: TObject);
begin
  if (cmbRNoCallChange.ItemIndex = cmbRNoCallChange.Items.Count-1) then
    edtRNoCallChange.Visible := True
  else
    edtRNoCallChange.Visible := False
end;

procedure TfrmKeysPref.cmbRNotEmptyExchChange(Sender: TObject);
begin
  if (cmbRNotEmptyExch.ItemIndex = cmbRNotEmptyExch.Items.Count-1) then
    edtRNotEmptyExch.Visible := True
  else
    edtRNotEmptyExch.Visible := False
end;

procedure TfrmKeysPref.cmbSBackSlashChange(Sender: TObject);
begin
  if (cmbSBackSlash.ItemIndex = cmbSBackSlash.Items.Count-1) then
    edtSBackSlash.Visible := True
  else
    edtSBackSlash.Visible := False
end;

procedure TfrmKeysPref.cmbSEmptyExchChange(Sender: TObject);
begin
  if (cmbSEmptyExch.ItemIndex = cmbSEmptyExch.Items.Count-1) then
    edtSEmptyExch.Visible := True
  else
    edtSEmptyExch.Visible := False
end;

procedure TfrmKeysPref.cmbSNoCallChangeChange(Sender: TObject);
begin
  if (cmbSNoCallChange.ItemIndex = cmbSNoCallChange.Items.Count-1) then
    edtSNoCallChange.Visible := True
  else
    edtSNoCallChange.Visible := False
end;

procedure TfrmKeysPref.cmbSNotEmptyExchChange(Sender: TObject);
begin
  if (cmbSNotEmptyExch.ItemIndex = cmbSNotEmptyExch.Items.Count-1) then
    edtSNotEmptyExch.Visible := True
  else
    edtSNotEmptyExch.Visible := False
end;

procedure TfrmKeysPref.FormShow(Sender: TObject);
begin
  cmbREmptyExch.ItemIndex    := cqrini.ReadInteger('KeysPref','REmptyExch',3);
  cmbRNotEmptyExch.ItemIndex := cqrini.ReadInteger('KeysPref','RNotEmptyExch',0);
  edtREmptyExch.Text         := cqrini.ReadString('KeysPref','REmptyExchC','');
  edtRNotEmptyExch.Text      := cqrini.ReadString('KeysPref','RNotEmptyExchC','');
  cmbRNoCallChange.ItemIndex := cqrini.ReadInteger('KeysPref','RNoCallChange',4);
  cmbRCallChange.ItemIndex   := cqrini.ReadInteger('KeysPref','RCallChange',1);
  cmbRBackSlash.ItemIndex    := cqrini.ReadInteger('KeysPref','RBackSlash',9);
  edtRNoCallChange.Text      := cqrini.ReadString('KeysPref','RNoCallChangeC','');
  edtRBackSlash.Text         := cqrini.ReadString('KeysPref','RBackSlashC','TU');

  cmbSEmptyExch.ItemIndex    := cqrini.ReadInteger('KeysPref','SEmptyExch',3);
  cmbSNotEmptyExch.ItemIndex := cqrini.ReadInteger('KeysPref','SNotEmptyExch',0);
  edtSEmptyExch.Text         := cqrini.ReadString('KeysPref','SEmptyExchC','');
  edtSNotEmptyExch.Text      := cqrini.ReadString('KeysPref','SNotEmptyExchC','');
  cmbSNoCallChange.ItemIndex := cqrini.ReadInteger('KeysPref','SNoCallChange',4);
  cmbSBackSlash.ItemIndex    := cqrini.ReadInteger('KeysPref','SBackSlash',9);
  edtSNoCallChange.Text      := cqrini.ReadString('KeysPref','SNoCallChangeC','');
  edtSBackSlash.Text         := cqrini.ReadString('KeysPref','SBackSlashC','TU');

  cmbREmptyExchChange(nil);
  cmbRNotEmptyExchChange(nil);
  cmbRNoCallChangeChange(nil);
  cmbRBackSlashChange(nil);

  cmbSEmptyExchChange(nil);
  cmbSNotEmptyExchChange(nil);
  cmbSNoCallChangeChange(nil);
  cmbSBackSlashChange(nil)
end;

initialization
  {$I fKeysPref.lrs}

end.

