(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fMarkQSL;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, ExtCtrls, LCLType;

type

  { TfrmMarkQSL }

  TfrmMarkQSL = class(TForm)
    btnCancel: TButton;
    btnApply: TButton;
    chgQSL: TCheckGroup;
    cmbQSLS: TComboBox;
    cmbType: TComboBox;
    Label1: TLabel;
    lblProg: TLabel;
    procedure FormShow(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure cmbTypeChange(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmMarkQSL: TfrmMarkQSL;

implementation
{$R *.lfm}

uses dUtils, dData, dDXCC, UMyIni, dLogUpload;

procedure TfrmMarkQSL.FormShow(Sender: TObject);
begin
  dmUtils.InsertQSL_S(cmbQSLS);
  cmbQSLS.Text := 'SB';
end;

procedure TfrmMarkQSL.btnApplyClick(Sender: TObject);
var
  tmp   : String = '';
  mode  : String = '';
  band  : String = '';
  Call  : String = '';
  adif  : Integer = 0;
  sql   : String = '';
  id    : Integer = 0;
  nr    : Integer = 0;

  FirstQSO   : String = '';
  FirstBand  : String = '';
  FirstMode  : String = '';
  QSLNeeded  : String = '';
begin
  tmp := UpperCase(dmData.qCQRLOG.SQL.Text);
  if not dmData.IsFilter then
  begin
    Application.MessageBox('First, you must filter QSO which you want to mark!','Info...',mb_ok+mb_IconInformation);
    exit
  end;

  if cqrini.ReadBool('OnlineLog','IgnoreQSL',False) then
     dmLogUpload.DisableOnlineLogSupport;

  if Pos('WHERE',tmp) = 0 then exit;
  tmp := copy(tmp,Pos('WHERE',tmp)+5,Length(tmp) - Pos('WHERE',tmp));
  if pos('ORDER',tmp) > 0 then
    tmp := copy(tmp,1,Pos('ORDER',tmp)-1);
  sql := 'select max(id_cqrlog_main) from  cqrlog_main where (not (' + tmp + ') ';
  dmData.qCQRLOG.First;
  while not dmData.qCQRLOG.EOF do
  begin
    inc(nr);
    lblProg.Caption := 'Working           ' + IntToStr(nr) + '. QSO(s)';
    lblProg.Update;
    mode := dmData.qCQRLOG.FieldByName('mode').AsString;
    band := dmData.qCQRLOG.FieldByName('band').AsString;
    call := dmData.qCQRLOG.FieldByName('callsign').AsString;
    adif := dmDXCC.AdifFromPfx(dmData.qCQRLOG.FieldByName('dxcc_ref').AsString);
    id   := dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger;

    if dmData.qCQRLOG.FieldByName('QSL_S').AsString <> '' then
    begin
      dmData.qCQRLOG.Next;
      Continue
    end;

    if (cmbType.ItemIndex = 1) and (chgQSL.Checked[3]) then //first band/mode
    begin
      tmp := IntToStr(adif)+'|'+band+'|'+mode+'|Q;';
      if Pos(tmp,QSLNeeded) > 0 then
      begin
        dmData.qCQRLOG.Next;
        Continue
      end;
      dmData.Q.Close();
      dmData.Q.SQL.Text := sql + ' and adif=' + IntToStr(adif) + ' and mode = '+QuotedStr(mode)+
                           ' and band='+QuotedStr(band)+' and qsl_r='+QuotedStr('Q')+')';
      if dmData.DebugLevel >= 1 then WriteLn(dmData.Q.SQL.Text);
      dmData.trQ.StartTransaction;
      dmData.Q.Open();
      if (dmData.Q.Fields[0].AsInteger = 0) then
      begin
        dmData.Q.Close;
        dmData.trQ.Rollback;
        dmData.Q.SQL.Text := 'update cqrlog_main set qsl_s=' + QuotedStr(cmbQSLS.Text) + ' where id_cqrlog_main = ' + IntToStr(id);
        if dmData.DebugLevel >= 1 then WriteLn(dmData.Q.SQL.Text);
        dmData.trQ.StartTransaction;
        dmData.Q.ExecSQL;
        dmData.trQ.Commit;
        QSLNeeded := QSLNeeded + tmp;
        dmData.qCQRLOG.Next;
        Continue
      end;
      dmData.Q.Close();
      dmData.trQ.Rollback
    end;

    if chgQSL.Checked[2] then //first band/mode
    begin
      if cmbType.ItemIndex = 0 then
        tmp := call+'|'+band+'|'+mode+';'
      else
        tmp := IntToStr(adif)+'|'+band+'|'+mode+';';
      if Pos(tmp,FirstMode) > 0 then
      begin
        dmData.qCQRLOG.Next;
        Continue
      end;
      dmData.Q.Close();
      if cmbType.ItemIndex = 0 then
        dmData.Q.SQL.Text := sql + ' and callsign=' + QuotedStr(Call) + ' and mode = '+QuotedStr(mode)+
                             ' and band='+QuotedStr(band)+')'
      else
        dmData.Q.SQL.Text := sql + ' and adif=' + IntToStr(adif) + ' and mode = '+QuotedStr(mode)+
                             ' and band='+QuotedStr(band)+')';
      if dmData.DebugLevel >= 1 then WriteLn(dmData.Q.SQL.Text);
      dmData.trQ.StartTransaction;
      dmData.Q.Open();
      if (dmData.Q.Fields[0].AsInteger = 0) then
      begin
        dmData.Q.Close;
        dmData.trQ.Rollback;
        dmData.Q.SQL.Text := 'update cqrlog_main set qsl_s=' + QuotedStr(cmbQSLS.Text) + ' where id_cqrlog_main = ' + IntToStr(id);
        if dmData.DebugLevel >= 1 then WriteLn(dmData.Q.SQL.Text);
        dmData.trQ.StartTransaction;
        dmData.Q.ExecSQL;
        dmData.trQ.Commit;
        FirstMode := FirstMode + tmp;
        dmData.qCQRLOG.Next;
        Continue
      end
      else begin
        dmData.Q.Close();
        dmData.trQ.Rollback
      end
    end;

    if chgQSL.Checked[1] then //first band qso
    begin
      if cmbType.ItemIndex = 0 then
        tmp := call+'|'+band+';'
      else
        tmp := IntToStr(adif)+'|'+band+';';
      if Pos(tmp,FirstBand) > 0 then
      begin
        dmData.qCQRLOG.Next;
        Continue
      end;

      dmData.Q.Close();
      if cmbType.ItemIndex = 0 then
        dmData.Q.SQL.Text := sql + ' and callsign=' + QuotedStr(Call) + ' and band='+QuotedStr(band)+')'
      else
        dmData.Q.SQL.Text := sql + ' and adif=' + IntToStr(adif) + ' and band='+QuotedStr(band)+')';
      if dmData.DebugLevel >= 1 then WriteLn(dmData.Q.SQL.Text);
      dmData.trQ.StartTransaction;
      dmData.Q.Open();
      if (dmData.Q.Fields[0].AsInteger = 0) then
      begin
        dmData.Q.Close;
        dmData.trQ.Rollback;
        dmData.Q.SQL.Text := 'update cqrlog_main set qsl_s=' + QuotedStr(cmbQSLS.Text) + ' where id_cqrlog_main = ' + IntToStr(id);
        if dmData.DebugLevel >= 1 then WriteLn(dmData.Q.SQL.Text);
        dmData.trQ.StartTransaction;
        dmData.Q.ExecSQL;
        dmData.trQ.Commit;
        FirstBand := FirstBand + tmp;
        dmData.qCQRLOG.Next;
        Continue
      end;
      dmData.Q.Close();
      dmData.trQ.Rollback
    end;

    if chgQSL.Checked[0] then //first
    begin
      if cmbType.ItemIndex = 0 then
        tmp := call+';'
      else
        tmp := IntToStr(adif)+';';
      if Pos(tmp,FirstQSO) > 0 then
      begin
        dmData.qCQRLOG.Next;
        Continue
      end;

      dmData.Q.Close();
      if cmbType.ItemIndex = 0 then
        dmData.Q.SQL.Text := sql + ' and callsign=' + QuotedStr(Call)+')'
      else
        dmData.Q.SQL.Text := sql + ' and adif=' + IntToStr(adif)+')';
      if dmData.DebugLevel >= 1 then WriteLn(dmData.Q.SQL.Text);
      dmData.trQ.StartTransaction;
      dmData.Q.Open();
      if (dmData.Q.Fields[0].AsInteger = 0) then
      begin
        dmData.Q.Close;
        dmData.trQ.Rollback;
        dmData.Q.SQL.Text := 'update cqrlog_main set qsl_s=' + QuotedStr(cmbQSLS.Text) + ' where id_cqrlog_main = ' + IntToStr(id);
        if dmData.DebugLevel >= 1 then WriteLn(dmData.Q.SQL.Text);
        dmData.trQ.StartTransaction;
        dmData.Q.ExecSQL;
        dmData.trQ.Commit;
        FirstQSO := FirstQSO + tmp;
        dmData.qCQRLOG.Next;
        Continue
      end;
      dmData.Q.Close();
      dmData.trQ.Rollback
    end;
    dmData.qCQRLOG.Next
  end;
  lblProg.Caption := 'Complete!';

  if cqrini.ReadBool('OnlineLog','IgnoreQSL',False) then
     dmLogUpload.EnableOnlineLogSupport;
end;

procedure TfrmMarkQSL.cmbTypeChange(Sender: TObject);
begin
  chgQSL.Items.Clear;
  if cmbType.ItemIndex = 0 then
  begin
    chgQSL.Items.Add('First QSO');
    chgQSL.Items.Add('First band QSO');
    chgQSL.Items.Add('First band/mode QSO')
  end
  else begin
    chgQSL.Items.Add('New country');
    chgQSL.Items.Add('New band country');
    chgQSL.Items.Add('New mode country QSO');
    chgQSL.Items.Add('QSL needed');
  end;
  chgQSL.Width := chgQSL.Width+2;
  chgQSL.Width := chgQSL.Width-2
end;

end.

