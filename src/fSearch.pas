(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fSearch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, ExtCtrls;

type

  { TfrmSearch }

  TfrmSearch = class(TForm)
    btnCancel: TButton;
    btnSearch: TButton;
    chkInclude: TCheckBox;
    cmbSearch: TComboBox;
    edtText: TEdit;
    GroupBox1: TGroupBox;
    grbOptions: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    mHelp: TMemo;
    Panel1: TPanel;
    procedure FormShow(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure cmbSearchChange(Sender: TObject);
    procedure edtTextKeyPress(Sender: TObject; var Key: char);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmSearch: TfrmSearch;

implementation

{ TfrmSearch }
uses dData, fMain, dUtils;
procedure TfrmSearch.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(self);
  cmbSearch.Items.Add('QSO Date');
  cmbSearch.Items.Add('Callsign');
  cmbSearch.Items.Add('Name');
  cmbSearch.Items.Add('QTH');
  cmbSearch.ItemIndex := 1;
  edtText.SetFocus;
  cmbSearchChange(nil);
  if dmData.IsFilter and (not dmData.IsSFilter) then
  begin
    mHelp.Visible := False;
    Height := Height-90;
    grbOptions.Enabled := False
  end
end;

procedure TfrmSearch.btnSearchClick(Sender: TObject);
var
  sql : String = '';
begin
  if edtText.Text = '' then
    exit;
  if dmData.SortType = stDate then
    sql := 'select * from view_cqrlog_main_by_qsodate '
  else
    sql := 'select * from view_cqrlog_main_by_callsign ';

  case cmbSearch.ItemIndex of
    0 : begin
          if dmData.IsFilter and (not dmData.IsSFilter) then
          begin
            if  dmData.QueryLocate(dmData.qCQRLOG,'qsodate',edtText.Text,True) then
              Close
            else
              ShowMessage(edtText.Text + ' not found')
          end
          else begin
            dmData.Q.Close;
            if dmData.trQ.Active then dmData.trQ.Rollback;
            sql := sql + ' where qsodate = '+ QuotedStr(edtText.Text);
            dmData.Q.SQL.Text := sql + ' LIMIT 1';
            dmData.trQ.StartTransaction;
            dmData.Q.Open;
            Writeln('cnt:',dmData.Q.Fields[0].AsInteger);
            if dmData.Q.Fields[0].AsInteger = 0 then
              ShowMessage(edtText.Text + ' not found')
            else begin
              dmData.qCQRLOG.DisableControls;
              try
                dmData.qCQRLOG.Close;
                dmData.trCQRLOG.Rollback;
                dmData.qCQRLOG.SQL.Text := sql;
                dmData.trCQRLOG.StartTransaction;
                dmData.qCQRLOG.Open;
                Close
              finally
                dmData.IsFilter  := True;
                dmData.IsSFilter := True;
                frmMain.RefreshQSODXCCCount;
                dmData.qCQRLOG.EnableControls
              end
            end
          end
        end;
    1 : begin
          if dmData.IsFilter and (not dmData.IsSFilter) then
          begin
            if dmData.QueryLocate(dmData.qCQRLOG,'callsign',edtText.Text,False) then
              Close
            else
              ShowMessage(edtText.Text + ' not found')
          end
          else begin
            dmData.Q.Close;
            if dmData.trQ.Active then dmData.trQ.Rollback;
            if chkInclude.Checked then
              sql := sql + ' where (callsign like ''%' + edtText.Text + '%'')'
            else
              sql := sql + ' where callsign = '+ QuotedStr(edtText.Text);
            dmData.Q.SQL.Text := sql + ' LIMIT 1';
            dmData.trQ.StartTransaction;
            dmData.Q.Open;
            if dmData.Q.Fields[0].AsInteger = 0 then
              ShowMessage(edtText.Text + ' not found')
            else begin
              dmData.qCQRLOG.DisableControls;
              try
                dmData.qCQRLOG.Close;
                dmData.trCQRLOG.Rollback;
                dmData.qCQRLOG.SQL.Text := sql;
                dmData.trCQRLOG.StartTransaction;
                dmData.qCQRLOG.Open;
                Close
              finally
                dmData.IsFilter  := True;
                dmData.IsSFilter := True;
                frmMain.RefreshQSODXCCCount;
                dmData.qCQRLOG.EnableControls
              end
            end
          end
        end;
    2 : begin
          if dmData.IsFilter and (not dmData.IsSFilter) then
          begin
            if dmData.QueryLocate(dmData.qCQRLOG,'name',edtText.Text,False) then
              Close
            else
              ShowMessage(edtText.Text + ' not found')
          end
          else begin
            dmData.Q.Close;
            if dmData.trQ.Active then dmData.trQ.Rollback;
            if chkInclude.Checked then
              sql := sql + ' where (name like ''%' + edtText.Text + '%'')'
            else
              sql := sql + ' where name = '+ QuotedStr(edtText.Text);
            dmData.Q.SQL.Text := sql + ' LIMIT 1';
            dmData.trQ.StartTransaction;
            dmData.Q.Open;
            if dmData.Q.Fields[0].AsInteger = 0 then
              ShowMessage(edtText.Text + ' not found')
            else begin
              dmData.qCQRLOG.DisableControls;
              try
                dmData.qCQRLOG.Close;
                dmData.trCQRLOG.Rollback;
                dmData.qCQRLOG.SQL.Text := sql;
                dmData.trCQRLOG.StartTransaction;
                dmData.qCQRLOG.Open;
                Close
              finally
                dmData.IsFilter  := True;
                dmData.IsSFilter := True;
                frmMain.RefreshQSODXCCCount;
                dmData.qCQRLOG.EnableControls
              end
            end
          end
        end;
    3 : begin
          if dmData.IsFilter and (not dmData.IsSFilter) then
          begin
            if dmData.QueryLocate(dmData.qCQRLOG,'qth',edtText.Text,False) then
              Close
            else
              ShowMessage(edtText.Text + ' not found')
          end
          else begin
            dmData.Q.Close;
            if dmData.trQ.Active then dmData.trQ.Rollback;
            if chkInclude.Checked then
              sql := sql + ' where qth (like ''%' + edtText.Text + '%'')'
            else
              sql := sql + ' where qth = '+ QuotedStr(edtText.Text);
            dmData.Q.SQL.Text := sql + ' LIMIT 1';
            dmData.trQ.StartTransaction;
            dmData.Q.Open;
            if dmData.Q.Fields[0].AsInteger = 0 then
              ShowMessage(edtText.Text + ' not found')
            else begin
              dmData.qCQRLOG.DisableControls;
              try
                dmData.qCQRLOG.Close;
                dmData.trCQRLOG.Rollback;
                dmData.qCQRLOG.SQL.Text := sql;
                dmData.trCQRLOG.StartTransaction;
                dmData.qCQRLOG.Open;
                Close
              finally
                dmData.IsFilter  := True;
                dmData.IsSFilter := True;
                frmMain.RefreshQSODXCCCount;
                dmData.qCQRLOG.EnableControls
              end
            end
          end
        end
  end;
  frmMain.CheckAttachment
end;

procedure TfrmSearch.cmbSearchChange(Sender: TObject);
begin
  if cmbSearch.ItemIndex = 1 then
    edtText.CharCase := ecUppercase
  else
    edtText.CharCase := ecNormal;
  if cmbSearch.ItemIndex = 0 then
    grbOptions.Enabled := False
  else
    grbOptions.Enabled := True
end;

procedure TfrmSearch.edtTextKeyPress(Sender: TObject; var Key: char);
begin
  if key = #13 then
  begin
    btnSearch.Click;
    key := #0
  end
end;

initialization
  {$I fSearch.lrs}

end.

