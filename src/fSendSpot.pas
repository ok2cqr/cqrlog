(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fSendSpot;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons;

type

  { TfrmSendSpot }

  TfrmSendSpot = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    edtSpot: TEdit;
    Label1: TLabel;
    procedure FormActivate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure edtSpotEnter(Sender: TObject);
    procedure edtSpotKeyPress(Sender: TObject; var Key: char);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmSendSpot: TfrmSendSpot;

implementation
{$R *.lfm}

{ TfrmSendSpot }

procedure TfrmSendSpot.FormShow(Sender: TObject);
begin
end;

procedure TfrmSendSpot.edtSpotEnter(Sender: TObject);
begin
  edtSpot.SelStart  := Length(edtSpot.Text);
  edtSpot.SelLength := 1;
end;

procedure TfrmSendSpot.FormActivate(Sender: TObject);
begin
  edtSpot.SetFocus;
end;

procedure TfrmSendSpot.edtSpotKeyPress(Sender: TObject; var Key: char);
begin
  if (key = #13) then
  begin
    if (edtSpot.Text <> '') then
      btnOK.Click;
  end;
end;

end.

