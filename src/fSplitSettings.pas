unit fSplitSettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Spin, inifiles;

type

  { TfrmSplitSettings }

  TfrmSplitSettings = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    cmbSplit1: TComboBox;
    cmbSplit2: TComboBox;
    cmbSplit3: TComboBox;
    cmbSplit4: TComboBox;
    cmbSplit5: TComboBox;
    cmbSplit6: TComboBox;
    cmbSplit7: TComboBox;
    cmbSplit8: TComboBox;
    cmbSplit9: TComboBox;
    edtSplit2: TSpinEdit;
    edtSplit3: TSpinEdit;
    edtSplit4: TSpinEdit;
    edtSplit5: TSpinEdit;
    edtSplit6: TSpinEdit;
    edtSplit7: TSpinEdit;
    edtSplit8: TSpinEdit;
    edtSplit9: TSpinEdit;
    lbl1: TLabel;
    edtSplit1: TSpinEdit;
    lblH4: TLabel;
    lblH5: TLabel;
    lblH6: TLabel;
    lbl7: TLabel;
    lblH7: TLabel;
    lbl8: TLabel;
    lblH8: TLabel;
    lbl9: TLabel;
    lblH9: TLabel;
    lbl2: TLabel;
    lbl3: TLabel;
    lbl4: TLabel;
    lbl5: TLabel;
    lbl6: TLabel;
    lblH1: TLabel;
    lblH2: TLabel;
    lblH3: TLabel;
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmSplitSettings: TfrmSplitSettings;

implementation
{$R *.lfm}

uses dData, uMyIni;

{ TfrmSplitSettings }

procedure TfrmSplitSettings.btnOKClick(Sender: TObject);
begin
  if cmbSplit1.ItemIndex = 0 then
    cqrini.WriteInteger('Split','1',edtSplit1.Value)
  else
    cqrini.WriteInteger('Split','1',edtSplit1.Value*-1);
  if cmbSplit2.ItemIndex = 0 then
    cqrini.WriteInteger('Split','2',edtSplit2.Value)
  else
    cqrini.WriteInteger('Split','2',edtSplit2.Value*-1);
  if cmbSplit3.ItemIndex = 0 then
    cqrini.WriteInteger('Split','3',edtSplit3.Value)
  else
    cqrini.WriteInteger('Split','3',edtSplit3.Value*-1);
  if cmbSplit4.ItemIndex = 0 then
    cqrini.WriteInteger('Split','4',edtSplit4.Value)
  else
    cqrini.WriteInteger('Split','4',edtSplit4.Value*-1);
  if cmbSplit5.ItemIndex = 0 then
    cqrini.WriteInteger('Split','5',edtSplit5.Value)
  else
    cqrini.WriteInteger('Split','5',edtSplit5.Value*-1);
  if cmbSplit6.ItemIndex = 0 then
    cqrini.WriteInteger('Split','6',edtSplit6.Value)
  else
    cqrini.WriteInteger('Split','6',edtSplit6.Value*-1);
  if cmbSplit7.ItemIndex = 0 then
    cqrini.WriteInteger('Split','7',edtSplit7.Value)
  else
    cqrini.WriteInteger('Split','7',edtSplit7.Value*-1);
  if cmbSplit8.ItemIndex = 0 then
    cqrini.WriteInteger('Split','8',edtSplit8.Value)
  else
    cqrini.WriteInteger('Split','8',edtSplit8.Value*-1);
   if cmbSplit9.ItemIndex = 0 then
    cqrini.WriteInteger('Split','9',edtSplit9.Value)
  else
    cqrini.WriteInteger('Split','9',edtSplit9.Value*-1);
   Close;
end;

procedure TfrmSplitSettings.FormShow(Sender: TObject);
begin
  if cqrini.ReadInteger('Split','1',0) >= 0 then
    edtSplit1.Value := cqrini.ReadInteger('Split','1',0)
  else begin
    edtSplit1.Value     := cqrini.ReadInteger('Split','1',0)*-1;
    cmbSplit1.ItemIndex := 1
  end;
  if cqrini.ReadInteger('Split','2',0) >= 0 then
    edtSplit2.Value := cqrini.ReadInteger('Split','2',0)
  else begin
    edtSplit2.Value     := cqrini.ReadInteger('Split','2',0)*-1;
    cmbSplit2.ItemIndex := 1
  end;
  if cqrini.ReadInteger('Split','3',0) >= 0 then
    edtSplit3.Value := cqrini.ReadInteger('Split','3',0)
  else begin
    edtSplit3.Value     := cqrini.ReadInteger('Split','3',0)*-1;
    cmbSplit3.ItemIndex := 1
  end;
  if cqrini.ReadInteger('Split','4',0) >= 0 then
    edtSplit4.Value := cqrini.ReadInteger('Split','4',0)
  else begin
    edtSplit4.Value     := cqrini.ReadInteger('Split','4',0)*-1;
    cmbSplit4.ItemIndex := 1
  end;
  if cqrini.ReadInteger('Split','5',0) >= 0 then
    edtSplit5.Value := cqrini.ReadInteger('Split','5',0)
  else begin
    edtSplit5.Value     := cqrini.ReadInteger('Split','5',0)*-1;
    cmbSplit5.ItemIndex := 1
  end;
  if cqrini.ReadInteger('Split','6',0) >= 0 then
    edtSplit6.Value := cqrini.ReadInteger('Split','6',0)
  else begin
    edtSplit6.Value     := cqrini.ReadInteger('Split','6',0)*-1;
    cmbSplit6.ItemIndex := 1
  end;
  if cqrini.ReadInteger('Split','7',0) >= 0 then
    edtSplit7.Value := cqrini.ReadInteger('Split','7',0)
  else begin
    edtSplit7.Value     := cqrini.ReadInteger('Split','7',0)*-1;
    cmbSplit7.ItemIndex := 1
  end;
  if cqrini.ReadInteger('Split','8',0) >= 0 then
    edtSplit8.Value := cqrini.ReadInteger('Split','8',0)
  else begin
    edtSplit8.Value     := cqrini.ReadInteger('Split','8',0)*-1;
    cmbSplit8.ItemIndex := 1
  end;
  if cqrini.ReadInteger('Split','9',0) >= 0 then
    edtSplit9.Value := cqrini.ReadInteger('Split','9',0)
  else begin
    edtSplit9.Value     := cqrini.ReadInteger('Split','9',0)*-1;
    cmbSplit9.ItemIndex := 1
  end
end;


end.

