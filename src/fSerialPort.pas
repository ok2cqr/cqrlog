(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fSerialPort;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, lcltype;

type

  { TfrmSerialPort }

  TfrmSerialPort = class(TForm)
    btnOK: TButton;
    Button2: TButton;
    chkDTR: TCheckBox;
    chkRTS: TCheckBox;
    cmbHanshake: TComboBox;
    cmbParity: TComboBox;
    edtDataBits: TEdit;
    edtStopBits: TEdit;
    edtSpeed: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    procedure btnOKClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmSerialPort: TfrmSerialPort;

implementation
{$R *.lfm}

{ TfrmSerialPort }

procedure TfrmSerialPort.btnOKClick(Sender: TObject);
var
  tmp : Integer;
begin
  if not TryStrToInt(edtSpeed.Text,tmp) then
  begin
    Application.MessageBox('You must set correnct serial speed!','Error', mb_OK + mb_IconError);
    edtSpeed.SetFocus;
    exit
  end;
  if not TryStrToInt(edtDataBits.Text,tmp) then
  begin
    Application.MessageBox('You must set correnct data bits!','Error', mb_OK + mb_IconError);
    edtDataBits.SetFocus;
    exit
  end;
  if not TryStrToInt(edtStopBits.Text,tmp) then
  begin
    Application.MessageBox('You must set correnct stop bits!','Error', mb_OK + mb_IconError);
    edtStopBits.SetFocus;
    exit
  end;
  ModalResult := mrOK;
end;

end.

