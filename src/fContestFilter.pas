(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fContestFilter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, MaskEdit, lcltype, ExtDlgs, EditBtn, inifiles, strutils;

type

  { TfrmContestFilter }

  TfrmContestFilter = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    btnHelp: TButton;
    cmbContestName: TComboBox;
    gbContName: TGroupBox;
    Label1: TLabel;
    procedure btClearClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  public
    tmp : String;
  end;
var
  frmContestFilter: TfrmContestFilter;

implementation
{$R *.lfm}

{ TfrmContestFilter }
uses dData, dUtils, fContest;

procedure TfrmContestFilter.btnOKClick(Sender: TObject);
begin
  tmp := 'SELECT * FROM view_cqrlog_main_by_qsodate WHERE `contestname` = "' + cmbContestName.Text + '"';
  if (tmp <> '') then
  begin
    dmData.qCQRLOG.Close;
    dmData.qCQRLOG.SQL.Text := tmp;
    if dmData.DebugLevel >=1 then
      Writeln(tmp);
    if dmData.trCQRLOG.Active then
      dmData.trCQRLOG.Rollback;
    dmData.trCQRLOG.StartTransaction;
    dmData.qCQRLOG.Open;
    dmData.qCQRLOG.Last
  end;
  ModalResult := mrOK;
end;

procedure TfrmContestFilter.btnCancelClick(Sender: TObject);
begin
  Close
end;

procedure TfrmContestFilter.FormCreate(Sender: TObject);
begin
  cmbContestName.Clear;
  dmUtils.InsertWorkedContests(cmbContestName);
  cmbContestName.Items.Insert(0,''); //to be sure there is empty line at start
end;

procedure TfrmContestFilter.FormShow(Sender: TObject);

begin
  dmUtils.LoadFontSettings(self);
   if frmContest.Showing and (frmContest.cmbContestName.Text<>'') then
    cmbContestName.Text:=frmContest.cmbContestName.Text;
end;

procedure TfrmContestFilter.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = VK_RETURN then
  begin
    btnOK.Click;
    Key := 0
  end
end;

procedure TfrmContestFilter.btnHelpClick(Sender: TObject);
begin
  ShowHelp
end;

procedure TfrmContestFilter.btClearClick(Sender: TObject);
begin
      FormShow(nil);
end;

end.

