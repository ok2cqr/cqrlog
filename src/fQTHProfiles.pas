(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

unit fQTHProfiles;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  db, DBGrids, Buttons, Strings, lcltype, StdCtrls, iniFiles, Grids;

type

  { TfrmQTHProfiles }

  TfrmQTHProfiles = class(TForm)
    btnNew: TButton;
    btnEdit: TButton;
    btnDelete: TButton;
    btnClose: TButton;
    btnApply: TButton;
    btnHideShowProfile: TButton;
    dbgrdProfiles: TDBGrid;
    Panel1: TPanel;
    procedure btnHideShowProfileClick(Sender: TObject);
    procedure dbgrdProfilesCellClick(Column: TColumn);
    procedure dbgrdProfilesColumnSized(Sender: TObject);
    procedure dbgrdProfilesDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
  private
    procedure RefreshGrid(profile : String = '');
    procedure LocateProfile(profile : String);
    { private declarations }
  public
    procedure SelectingProfiles;
  end; 

var
  frmQTHProfiles: TfrmQTHProfiles;

implementation
{$R *.lfm}

{ TfrmQTHProfiles }
uses dData, fNewQTHProfile, dUtils, dQTHProfile;

procedure TfrmQTHProfiles.RefreshGrid(profile : String = '');
const
    C_SEL = 'SELECT * FROM profiles ORDER BY nr';
begin
  dmData.qProfiles.Close;

  dbgrdProfiles.DataSource  := dmData.dsrProfiles;
  dmData.qProfiles.SQL.Text := C_SEL;
  if dmData.trProfiles.Active then
    dmData.trProfiles.Rollback;
  dmData.trProfiles.StartTransaction;
  dmData.qProfiles.Open;
  dmUtils.LoadForm(self);

  LocateProfile(profile);

  dbgrdProfiles.Columns[0].Visible := False;
  //dbgrdProfiles.Columns[6].Visible := False
  btnEdit.Enabled:=(dmData.qProfiles.RecordCount <> 0);
end;

procedure TfrmQTHProfiles.LocateProfile(profile : String);
begin
  dmData.QueryLocate(dmData.qProfiles, 'nr', profile, true, true);
end;

procedure TfrmQTHProfiles.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(self);
  RefreshGrid
end;

procedure TfrmQTHProfiles.dbgrdProfilesColumnSized(Sender: TObject);
begin
  dmUtils.SaveForm(self)
end;

procedure TfrmQTHProfiles.dbgrdProfilesDblClick(Sender: TObject);
begin
  if dmData.qProfiles.RecordCount = 0 then
    exit;

  btnEditClick(nil);
end;

procedure TfrmQTHProfiles.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(self)
end;


procedure TfrmQTHProfiles.dbgrdProfilesCellClick(Column: TColumn);
begin
  dmUtils.SaveForm(self)
end;

procedure TfrmQTHProfiles.btnHideShowProfileClick(Sender: TObject);
begin
  if (dmData.qProfiles.FieldByName('visible').AsInteger = 1) then
  begin
    dmQTHProfile.UpdateVisibility(dmData.qProfiles.Fields[1].AsString, False);
  end
  else begin
    dmQTHProfile.UpdateVisibility(dmData.qProfiles.Fields[1].AsString, True);
  end;

  RefreshGrid(dmData.qProfiles.Fields[1].AsString);
  dbgrdProfiles.SetFocus;
end;

procedure TfrmQTHProfiles.btnDeleteClick(Sender: TObject);
begin
  if dmQTHProfile.ProfileInUse(dmData.qProfiles.Fields[1].AsString) then
  begin
    Application.MessageBox('This profile is used by QSOs and can not be deleted.','Information ...', mb_OK + mb_IconInformation);
    exit;
  end;

  if Application.MessageBox('Do you really want to delete this profile?','Question ...', mb_YesNo + mb_IconQuestion + mb_DefButton2) in [idNo, idCancel] then
  begin
    exit;
  end;

  dmQTHProfile.DeleteProfile(dmData.qProfiles.Fields[1].AsString);
  RefreshGrid();
end;

procedure TfrmQTHProfiles.btnEditClick(Sender: TObject);
const
  UPD_PROF = 'update profiles set locator = :locator, qth = :qth, rig = :rig, remarks = :remarks, visible = :visible, nr = :nr where nr = :old_nr';
  UPD_MAIN = 'update cqrlog_main set profile = %s  where profile = %s';
var
  OldProfileNumber : String = '';
  ProfileVisible : Integer;
  Remarks : String = '';
  Equipment : String = '';
  Qth : String = '';
  Profile : String;
begin
  with TfrmNewQTHProfile.Create(self) do
  try
    edtProfNr.Text        := dmData.qProfiles.Fields[1].AsString;
    edtLocator.Text       := dmData.qProfiles.Fields[2].AsString;
    mQTH.Lines.Text       := Trim(dmData.qProfiles.Fields[3].AsString);
    mEquipment.Lines.Text := Trim(dmData.qProfiles.Fields[4].AsString);
    mRemarks.Lines.Text   := Trim(dmData.qProfiles.Fields[5].AsString);
    chkVisible.Checked    := dmData.qProfiles.Fields[6].AsInteger > 0;
    OldProfileNumber      := edtProfNr.Text;
    Editing               := True;
    Caption               := 'Edit current QTH profile';
    ShowModal;
    if ModalResult = mrOK then
    begin
      if chkVisible.Checked then
        ProfileVisible := 1
      else
        ProfileVisible := 0;

      Qth := dmUtils.ReplaceEnter(mQTH.Lines.Text);
      Remarks := dmUtils.ReplaceEnter(mRemarks.Lines.Text);
      Equipment := dmUtils.ReplaceEnter(mEquipment.Lines.Text);

      dmQTHProfile.UpdateNewProfile(
        OldProfileNumber,
        edtProfNr.Text,
        edtLocator.Text,
        Qth,
        Equipment,
        Remarks,
        ProfileVisible
      );

      Profile := edtProfNr.Text
    end
  finally
    Free;
    RefreshGrid(Profile)
  end
end;

procedure TfrmQTHProfiles.btnNewClick(Sender: TObject);
var
  ProfileVisible : Integer;
  ProfileName : String;
  Remarks : String = '';
  Equipment : String = '';
  Qth : String = '';
begin
  with TfrmNewQTHProfile.Create(self) do
  try
    edtProfNr.Text := IntToStr(dmQTHProfile.getNewProfileNumber());
    Caption := 'New QTH profile';
    ShowModal;
    if ModalResult = mrOK then
    begin
      if chkVisible.Checked then
        ProfileVisible := 1
      else
        ProfileVisible := 0;

      Qth := dmUtils.ReplaceEnter(mQTH.Lines.Text);
      Remarks := dmUtils.ReplaceEnter(mRemarks.Lines.Text);
      Equipment := dmUtils.ReplaceEnter(mEquipment.Lines.Text);

      dmQTHProfile.AddNewProfile(
        edtProfNr.Text,
        edtLocator.Text,
        Qth,
        Equipment,
        Remarks,
        ProfileVisible
      );

      ProfileName := edtProfNr.Text
    end;
  finally
    Free;
    RefreshGrid(ProfileName);
  end;
end;

procedure TfrmQTHProfiles.SelectingProfiles;
begin
  btnNew.Visible    := False;
  btnEdit.Visible   := False;
  btnDelete.Visible := False;
  btnApply.Visible  := True;
  btnClose.Caption  := 'Cancel'
end;

end.

