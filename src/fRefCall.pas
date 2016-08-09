(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fRefCall;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, lcltype;

type

  { TfrmRefCall }

  TfrmRefCall = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    edtIdCall: TEdit;
    Label1: TLabel;
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure edtIdCallKeyPress(Sender: TObject; var Key: char);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmRefCall: TfrmRefCall;

implementation
{$R *.lfm}

{ TfrmRefCall }
uses dUtils;

procedure TfrmRefCall.btnOKClick(Sender: TObject);
begin
  if edtIdCall.Text = '' then
  begin
    Application.MessageBox('You must enter callsign!','Info ...',mb_ok + mb_IconInformation);
    edtIdCall.SetFocus;
    exit
  end
  else
    ModalResult := mrOK;
end;

procedure TfrmRefCall.edtIdCallKeyPress(Sender: TObject; var Key: char);
begin
  if key = #13 then
  begin
    key := #0;
    btnOK.Click
  end;
end;

procedure TfrmRefCall.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(self);
end;

end.

