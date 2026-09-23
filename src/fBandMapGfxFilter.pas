(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Filter of one graphical band map window (fBandMapGfx).

  Edits a TBandMapInstance (uBandMapLayout): one of three QSO rules - the
  shared [BandMapFilter] rule of the text band map, this window's own hours or
  date/time, or none - plus LoTW/eQSL and "current mode only". The caller
  passes the instance in, reads it back on mrOK and saves it; nothing is
  written to the ini here. }

unit fBandMapGfxFilter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  LCLType, uBandMapLayout;

type

  { TfrmBandMapGfxFilter }

  TfrmBandMapGfxFilter = class(TForm)
    btnCancel: TButton;
    btnOK: TButton;
    chkOnlyCurrMode: TCheckBox;
    chkOnlyeQSL: TCheckBox;
    chkOnlyLoTW: TCheckBox;
    edtDate: TEdit;
    edtLastHours: TEdit;
    edtTime: TEdit;
    gbQso: TGroupBox;
    gbOther: TGroupBox;
    lblGlobal: TLabel;
    lblHours: TLabel;
    lblRbn: TLabel;
    lblScope: TLabel;
    rbCustomDate: TRadioButton;
    rbCustomHours: TRadioButton;
    rbGlobal: TRadioButton;
    rbNone: TRadioButton;
    procedure btnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FInst : TBandMapInstance;
  public
    //what the shared [BandMapFilter] rule is right now, for the label
    GlobalRuleText : String;
    //RBN source continent filter, '' when off; shown read-only
    RbnContinents  : String;
    property Instance : TBandMapInstance read FInst write FInst;
  end;

implementation
{$R *.lfm}

uses dUtils;

procedure TfrmBandMapGfxFilter.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(Self);
  lblGlobal.Caption := 'Currently: ' + GlobalRuleText;
  case FInst.QsoRule of
    qrGlobal : rbGlobal.Checked := True;
    qrNone   : rbNone.Checked := True;
    else
      if FInst.UseLastHours then
        rbCustomHours.Checked := True
      else
        rbCustomDate.Checked := True
  end;
  edtLastHours.Text := IntToStr(FInst.LastHours);
  edtDate.Text      := FInst.SinceDate;
  edtTime.Text      := FInst.SinceTime;
  chkOnlyLoTW.Checked     := FInst.OnlyLoTW;
  chkOnlyeQSL.Checked     := FInst.OnlyEQSL;
  chkOnlyCurrMode.Checked := FInst.OnlyCurrMode;
  if RbnContinents <> '' then
    lblRbn.Caption := 'RBN spots are already limited to spotters in ' + RbnContinents +
                      ' (RBN control window > Filter); this map cannot bring the others back.'
  else
    lblRbn.Caption := ''
end;

procedure TfrmBandMapGfxFilter.btnOKClick(Sender: TObject);
var
  h : Integer;
begin
  if rbCustomHours.Checked and not TryStrToInt(Trim(edtLastHours.Text), h) then
  begin
    Application.MessageBox('Please enter correct number of hours','Info...',mb_OK+mb_IconInformation);
    edtLastHours.SetFocus;
    exit
  end;
  if rbCustomDate.Checked then
  begin
    if not dmUtils.isDateOK(edtDate.Text) then
    begin
      Application.MessageBox('Please enter correct date (yyyy-mm-dd)','Info...',mb_OK+mb_IconInformation);
      edtDate.SetFocus;
      exit
    end;
    if not dmUtils.isTimeOK(edtTime.Text) then
    begin
      Application.MessageBox('Please enter correct time (HH:MM)','Info...',mb_OK+mb_IconInformation);
      edtTime.SetFocus;
      exit
    end
  end;

  if rbGlobal.Checked then
    FInst.QsoRule := qrGlobal
  else if rbNone.Checked then
    FInst.QsoRule := qrNone
  else begin
    FInst.QsoRule      := qrCustom;
    FInst.UseLastHours := rbCustomHours.Checked
  end;
  if TryStrToInt(Trim(edtLastHours.Text), h) then
    FInst.LastHours := h;
  FInst.SinceDate    := Trim(edtDate.Text);
  FInst.SinceTime    := Trim(edtTime.Text);
  FInst.OnlyLoTW     := chkOnlyLoTW.Checked;
  FInst.OnlyEQSL     := chkOnlyeQSL.Checked;
  FInst.OnlyCurrMode := chkOnlyCurrMode.Checked;
  ModalResult := mrOK
end;

end.
