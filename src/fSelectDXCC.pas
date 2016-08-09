(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fSelectDXCC;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, DBGrids, Buttons, StdCtrls, db, lcltype;


type

  { TfrmSelectDXCC }

  TfrmSelectDXCC = class(TForm)
    btnApply: TButton;
    btnCancel: TButton;
    dbgrdDeleted: TDBGrid;
    dbgrdValid: TDBGrid;
    edtPrefix: TEdit;
    Label1: TLabel;
    pgDXCC: TPageControl;
    Panel1: TPanel;
    tabValid: TTabSheet;
    tabDeleted: TTabSheet;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure dbgrdDeletedDblClick(Sender: TObject);
    procedure dbgrdValidDblClick(Sender: TObject);
    procedure edtPrefixChange(Sender: TObject);
    procedure edtPrefixKeyPress(Sender: TObject; var Key: char);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmSelectDXCC: TfrmSelectDXCC;

implementation
{$R *.lfm}

uses dData,dUtils, dDXCC;

{ TfrmSelectDXCC }

procedure TfrmSelectDXCC.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(frmSelectDXCC);
  dmUtils.LoadForm(frmSelectDXCC);

  dbgrdDeleted.Columns[0].Visible := False;
  dbgrdValid.Columns[0].Visible   := False;

  btnApply.Caption := 'Apply';
  if edtPrefix.Text <> '' then
  begin
    if (Pos('*',edtPrefix.Text) > 0) then
      pgDXCC.PageIndex := 1
    else
      pgDXCC.PageIndex := 0;
    edtPrefixChange(nil)
  end
end;

procedure TfrmSelectDXCC.btnApplyClick(Sender: TObject);
begin
  if pgDXCC.PageIndex = 0 then
    edtPrefix.Text := dmDXCC.qValid.Fields[1].AsString
  else
    edtPrefix.Text := dmDXCC.qDeleted.Fields[1].AsString;
  ModalResult := mrOK
end;

procedure TfrmSelectDXCC.FormDestroy(Sender: TObject);
begin
  dmDXCC.qValid.Close;
  dmDXCC.qDeleted.Close
end;

procedure TfrmSelectDXCC.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveForm(frmSelectDXCC)
end;

procedure TfrmSelectDXCC.FormCreate(Sender: TObject);
begin
  dbgrdValid.DataSource   := dmDXCC.dsrValid;
  dbgrdDeleted.DataSource := dmDXCC.dsrDeleted;

  dmDXCC.qValid.SQL.Text  := 'SELECT * FROM cqrlog_common.dxcc_ref WHERE deleted = 0 ORDER BY pref';
  if dmData.DebugLevel >=1 then Writeln(dmDXCC.qValid.SQL.Text);
  if dmDXCC.trValid.Active then
    dmDXCC.trValid.Rollback;
  dmDXCC.trValid.StartTransaction;
  dmDXCC.qValid.Open;

  dmDXCC.trDeleted.DataBase := dmData.MainCon;
  dmDXCC.qDeleted.Database := dmData.MainCon;
  dmDXCC.qDeleted.SQL.Text := 'SELECT * FROM cqrlog_common.dxcc_ref WHERE deleted = 1 ORDER BY pref';
  if dmData.DebugLevel >=1 then Writeln(dmDXCC.qDeleted.SQL.Text);
  if dmDXCC.trDeleted.Active then
    dmDXCC.trDeleted.Rollback;
  dmDXCC.trDeleted.StartTransaction;
  dmDXCC.qDeleted.Open
end;

procedure TfrmSelectDXCC.dbgrdDeletedDblClick(Sender: TObject);
begin
  btnApply.Click
end;

procedure TfrmSelectDXCC.dbgrdValidDblClick(Sender: TObject);
begin
  btnApply.Click
end;

procedure TfrmSelectDXCC.edtPrefixChange(Sender: TObject);
begin
  if pgDXCC.PageIndex = 0 then
  begin
    dmDXCC.qValid.DisableControls;
    try
      dmDXCC.qValid.First;
      while not dmDXCC.qValid.EOF do
      begin
        if Pos(edtPrefix.Text,dmDXCC.qValid.Fields[1].AsString) = 1 then
          break
        else
          dmDXCC.qValid.Next
      end
    finally
      dmDXCC.qValid.EnableControls
    end
  end
  else begin
    dmDXCC.qDeleted.DisableControls;
    try
      dmDXCC.qDeleted.First;
      while not dmDXCC.qDeleted.EOF do
      begin
        if Pos(edtPrefix.Text,dmDXCC.qDeleted.Fields[1].AsString) = 1 then
          break
        else
          dmDXCC.qDeleted.Next
      end
    finally
      dmDXCC.qDeleted.EnableControls
    end
  end
end;

procedure TfrmSelectDXCC.edtPrefixKeyPress(Sender: TObject; var Key: char);
begin
  if key = #13 then
    btnApply.Click
end;

end.

