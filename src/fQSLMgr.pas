(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

unit fQSLMgr;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  DBGrids, inifiles, StdCtrls, Buttons, db;

type

  { TfrmQSLMgr }

  TfrmQSLMgr = class(TForm)
    btnApply: TButton;
    btnFind: TButton;
    btnCancel: TButton;
    dbgrdQSLMgr: TDBGrid;
    edtCallsign: TEdit;
    Panel1: TPanel;
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormShow(Sender: TObject);
    procedure btnFindClick(Sender: TObject);
    procedure edtCallsignKeyPress(Sender: TObject; var Key: char);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmQSLMgr: TfrmQSLMgr;

implementation
{$R *.lfm}

{ TfrmQSLMgr }

uses dUtils, dData, uMyIni;

procedure TfrmQSLMgr.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(frmQSLMgr);
  dbgrdQSLMgr.DataSource := dmData.dsrQSLMgr;
  dmUtils.LoadWindowPos(frmQSLMgr);
  dmUtils.LoadForm(frmQSLMgr);
  edtCallsign.SetFocus
end;

procedure TfrmQSLMgr.btnFindClick(Sender: TObject);
begin
  if edtCallsign.Text <> '' then
  begin
    dmData.qQSLMgr.First;
    dmData.qQSLMgr.DisableControls;
    try
      while not dmData.qQSLMgr.EOF do
      begin
        if Pos(edtCallsign.Text,dmData.qQSLMgr.Fields[0].AsString) = 1 then
          break
        else
          dmData.qQSLMgr.Next
      end;
    finally
      dmData.qQSLMgr.EnableControls
    end
  end
end;

procedure TfrmQSLMgr.edtCallsignKeyPress(Sender: TObject; var Key: char);
begin
  if key = #13 then
  begin
    btnFind.Click;
    key := #0;
  end;
end;

procedure TfrmQSLMgr.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin

  dmUtils.SaveWindowPos(frmQSLMgr);
  dmUtils.SaveForm(frmQSLMgr)
end;

end.

