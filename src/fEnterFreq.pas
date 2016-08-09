(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fEnterFreq;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Buttons, StdCtrls;

type

  { TfrmEnterFreq }

  TfrmEnterFreq = class(TForm)
    btnCancel: TButton;
    btnOK: TButton;
    cmbMode: TComboBox;
    edtFreq: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure cmbModeChange(Sender: TObject);
    procedure edtFreqKeyPress(Sender: TObject; var Key: char);
  private
    ModeChanged : Boolean;
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmEnterFreq: TfrmEnterFreq;

implementation
{$R *.lfm}

{ TfrmEnterFreq }
uses dUtils, fTRXControl, dData;

procedure TfrmEnterFreq.FormShow(Sender: TObject);
var
  mode : String;
  freq : String;
begin
  ModeChanged := False;
  dmUtils.InsertModes(cmbMode);
  frmTRXControl.GetModeFreqNewQSO(mode,freq);
  cmbMode.Text := mode;
  edtFreq.Clear;
  edtFreq.SetFocus
end;

procedure TfrmEnterFreq.btnOKClick(Sender: TObject);
var
  tmp  : Extended;
  freq : String;
  mode : String;
begin
  if TryStrToFloat(edtFreq.Text,tmp) then
  begin
    mode := cmbMode.Text;
    if not ModeChanged then
      mode := dmUtils.GetModeFromFreq(FloatToStr(tmp/1000));
    freq := FloatToStr(tmp);
    frmTRXControl.SetModeFreq(mode,freq);
  end;
  ModalResult := mrOK;
end;

procedure TfrmEnterFreq.cmbModeChange(Sender: TObject);
begin
  ModeChanged := True;
end;

procedure TfrmEnterFreq.edtFreqKeyPress(Sender: TObject; var Key: char);
begin
  if key = #13 then
  begin
    btnOK.Click;
    key := #0;
  end;
end;

end.

