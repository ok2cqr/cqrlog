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
  db, DBGrids, Buttons, Strings, lcltype, StdCtrls, iniFiles;

type

  { TfrmQTHProfiles }

  TfrmQTHProfiles = class(TForm)
    btnNew: TButton;
    btnEdit: TButton;
    btnDelete: TButton;
    btnClose: TButton;
    btnApply: TButton;
    dbgrdProfiles: TDBGrid;
    Panel1: TPanel;
    procedure dbgrdProfilesCellClick(Column: TColumn);
    procedure dbgrdProfilesColumnSized(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
  private
    procedure RefreshGrid;
    { private declarations }
  public
    procedure SelectingProfiles;
  end; 

var
  frmQTHProfiles: TfrmQTHProfiles;

implementation
{$R *.lfm}

{ TfrmQTHProfiles }
uses dData, fNewQTHProfile, dUtils;

procedure TfrmQTHProfiles.RefreshGrid;
begin
  dmData.qProfiles.Close;
  dbgrdProfiles.DataSource  := dmData.dsrProfiles;
  dmData.qProfiles.SQL.Text := 'SELECT * FROM profiles ORDER BY nr';
  if dmData.trProfiles.Active then
    dmData.trProfiles.Rollback;
  dmData.trProfiles.StartTransaction;
  dmData.qProfiles.Open;
  dmUtils.LoadForm(self);
  dbgrdProfiles.Columns[0].Visible := False;
  dbgrdProfiles.Columns[6].Visible := False
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

procedure TfrmQTHProfiles.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(self)
end;


procedure TfrmQTHProfiles.dbgrdProfilesCellClick(Column: TColumn);
begin
  dmUtils.SaveForm(self)
end;

procedure TfrmQTHProfiles.btnDeleteClick(Sender: TObject);
begin
  if dmData.ProfileInUse(dmData.qProfiles.Fields[0].AsString) then
    Application.MessageBox('This profiles is used by QSOs and cannot be deleted.','Information ...',
                           mb_OK + mb_IconInformation)
  else begin
    if Application.MessageBox('Do you realy want to delete this profile?','Question ...', mb_YesNo +
                              mb_IconQuestion) = idYes then
    begin
      dmData.Q.Close();
      dmData.Q.SQL.Text := 'delete from profiles where nr='+dmData.qProfiles.Fields[0].AsString;
      if dmData.DebugLevel >= 1 then Writeln(dmData.Q.SQL.Text);
      if dmData.trQ.Active then
        dmData.trQ.RollBack;
      dmData.trQ.StartTransaction;
      dmData.Q.ExecSQL();
      dmData.trQ.Commit;
      dmData.Q.Close()
    end
  end
end;

procedure TfrmQTHProfiles.btnEditClick(Sender: TObject);
var
  old_nr : String = '';
  tm : Integer;
  rem : String = '';
  equ : String = '';
  qth : String = '';
begin
  with TfrmNewQTHProfile.Create(self) do
  try
    edtProfNr.Text        := dmData.qProfiles.Fields[1].AsString;
    edtLocator.Text       := dmData.qProfiles.Fields[2].AsString;
    mQTH.Lines.Text       := Trim(dmData.qProfiles.Fields[3].AsString);
    mEquipment.Lines.Text := Trim(dmData.qProfiles.Fields[4].AsString);
    mRemarks.Lines.Text   := Trim(dmData.qProfiles.Fields[5].AsString);
    chkVisible.Checked    := dmData.qProfiles.Fields[6].AsInteger > 0;
    old_nr                := edtProfNr.Text;
    Editing               := True;
    Caption               := 'Edit current QTH profile';
    ShowModal;
    if ModalResult = mrOK then
    begin
      if chkVisible.Checked then
        tm := 1
      else
        tm := 0;

      qth := dmUtils.ReplaceEnter(mQTH.Lines.Text);
      rem := dmUtils.ReplaceEnter(mRemarks.Lines.Text);
      equ := dmUtils.ReplaceEnter(mEquipment.Lines.Text);

      dmData.Q.Close;
      dmData.Q.SQL.Text := 'UPDATE profiles SET  locator =' + QuotedStr(edtLocator.Text) +
                           ',qth=' + QuotedStr(qth) + ', rig=' + QuotedStr(equ) +
                           ',remarks='+QuotedStr(rem)+',visible='+IntToStr(tm) +
                           ',nr='+edtProfNr.Text + ' WHERE nr = ' + old_nr;
      if dmData.DebugLevel >=1 then Writeln(dmData.Q.SQL.Text);
      dmData.trQ.StartTransaction;
      dmData.Q.ExecSQL;
      if edtProfNr.Text <> old_nr then
      begin
        dmData.Q.SQL.Text := 'update cqrlog_main set profile='+edtProfNr.Text+' where profile='+old_nr;
        if dmData.DebugLevel >=1 then Writeln(dmData.Q.SQL.Text);
        dmData.Q.ExecSQL
      end;
      dmData.trQ.Commit
    end
  finally
    Free;
    RefreshGrid
  end
end;

procedure TfrmQTHProfiles.btnNewClick(Sender: TObject);
var
  tm : Integer;
begin
  with TfrmNewQTHProfile.Create(self) do
  try
    Caption               := 'New QTH profile';
    ShowModal;
    if ModalResult = mrOK then
    begin
      if chkVisible.Checked then
        tm := 1
      else
        tm := 0;
      dmData.Q.Close;
      dmData.Q.SQL.Text := 'INSERT INTO profiles (nr,locator,qth,rig,remarks,visible) VALUES (' +
                           edtProfNr.Text + ',' + QuotedStr(edtLocator.Text) + ',' +
                           QuotedStr(trim(mQTH.Lines.Text)) + ',' + QuotedStr(trim(mEquipment.Lines.Text)) +
                           ','+QuotedStr(trim(mRemarks.Lines.Text))+','+IntToStr(tm)+')';
      if dmData.DebugLevel >=1 then
        Writeln(dmData.Q.SQL.Text);
      dmData.trQ.StartTransaction;
      dmData.Q.ExecSQL;
      dmData.trQ.Commit
    end
  finally
    Free;
    RefreshGrid
  end
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

