(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fClubSettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, inifiles, ColorBox, lcltype;

type

  { TfrmClubSettings }

  TfrmClubSettings = class(TForm)
    btnOK: TButton;
    btnHelp: TButton;
    Button2: TButton;
    cmbClubFields: TComboBox;
    cmbMainFields: TComboBox;
    cmbStoreFileds: TComboBox;
    cmbNewColor: TColorBox;
    cmbBandColor: TColorBox;
    cmbModeColor: TColorBox;
    cmbQSLColor: TColorBox;
    cmbAlreadyColor: TColorBox;
    edtStoreText: TEdit;
    edtNewModeInfo: TEdit;
    edtQSLNeededInfo: TEdit;
    edtAlreadyCmfInfo: TEdit;
    edtNewInfo: TEdit;
    edtNewBandInfo: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    GroupBox6: TGroupBox;
    GroupBox7: TGroupBox;
    GroupBox8: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    procedure btnHelpClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    ClubStr : String;
    { public declarations }
  end; 

var
  frmClubSettings: TfrmClubSettings;

implementation
{$R *.lfm}

uses dUtils, dData, uMyini;
{ TfrmClubSettings }

procedure TfrmClubSettings.btnOKClick(Sender: TObject);
begin
  cqrini.WriteString(ClubStr+'Club','NewInfo',edtNewInfo.Text);
  cqrini.WriteString(ClubStr+'Club','NewBandInfo',edtNewBandInfo.Text);
  cqrini.WriteString(ClubStr+'Club','NewModeInfo',edtNewModeInfo.Text);
  cqrini.WriteString(ClubStr+'Club','QSLNeededInfo',edtQSLNeededInfo.Text);
  cqrini.WriteString(ClubStr+'Club','AlreadyConfirmedInfo',edtAlreadyCmfInfo.Text);
  cqrini.WriteString(Clubstr+'Club','ClubFields',cmbClubFields.Text);
  cqrini.WriteString(Clubstr+'Club','MainFields',cmbMainFields.Text);
  cqrini.WriteString(Clubstr+'Club','StoreFields',cmbStoreFileds.Text);
  cqrini.WriteString(Clubstr+'Club','StoreText',edtStoreText.Text);
  cqrini.WriteInteger(Clubstr+'Club','NewColor',cmbNewColor.Selected);
  cqrini.WriteInteger(Clubstr+'Club','BandColor',cmbBandColor.Selected);
  cqrini.WriteInteger(Clubstr+'Club','ModeColor',cmbModeColor.Selected);
  cqrini.WriteInteger(Clubstr+'Club','QSLColor',cmbQSLColor.Selected);
  cqrini.WriteInteger(Clubstr+'Club','AlreadyColor',cmbAlreadyColor.Selected)
end;

procedure TfrmClubSettings.btnHelpClick(Sender: TObject);
begin
  ShowHelp;
end;

procedure TfrmClubSettings.FormShow(Sender: TObject);
begin
  edtNewInfo.Text           := cqrini.ReadString(ClubStr+'Club','NewInfo',
                               'New %s member! (%c #%n)');
  edtNewBandInfo.Text       := cqrini.ReadString(ClubStr+'Club','NewBandInfo',
                               'New band %s member! (%c #%n)');
  edtNewModeInfo.Text       := cqrini.ReadString(ClubStr+'Club','NewModeInfo',
                               'New mode %s member! (%c #%n)');
  edtQSLNeededInfo.Text     := cqrini.ReadString(ClubStr+'Club','QSLNeededInfo',
                               'QSL needed for %s member! (%c #%n)');
  edtAlreadyCmfInfo.Text    := cqrini.ReadString(ClubStr+'Club','AlreadyConfirmedInfo',
                               'Already confirmed %s member! (%c #%n)');
  cmbClubFields.Text        := cqrini.ReadString(Clubstr+'Club','ClubFields','');
  cmbMainFields.Text        := cqrini.ReadString(Clubstr+'Club','MainFields','');
  cmbStoreFileds.Text       := cqrini.ReadString(Clubstr+'Club','StoreFields','');
  edtStoreText.Text         := cqrini.ReadString(Clubstr+'Club','StoreText','');
  cmbNewColor.Selected     := cqrini.ReadInteger(Clubstr+'Club','NewColor',clRed);
  cmbBandColor.Selected    := cqrini.ReadInteger(Clubstr+'Club','BandColor',clBlue);
  cmbModeColor.Selected    := cqrini.ReadInteger(Clubstr+'Club','ModeColor',clLime);
  cmbQSLColor.Selected     := cqrini.ReadInteger(Clubstr+'Club','QSLColor',clFuchsia);
  cmbAlreadyColor.Selected := cqrini.ReadInteger(Clubstr+'Club','AlreadyColor',0);
  dmUtils.LoadFontSettings(self);
  if cmbClubFields.Text = '' then
    cmbClubFields.ItemIndex := 0;
  if cmbMainFields.Text = '' then
    cmbMainFields.ItemIndex := 0;
end;

end.

