(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Edit one RBN source preset (cqrlog_common.rbn_sources). }

unit fRbnSourceEdit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs, dSqlRef;

type
  TfrmRbnSourceEdit = class(TForm)
    btnCancel: TButton;
    btnOK: TButton;
    edtAddress: TEdit;
    edtDescription: TEdit;
    edtPort: TEdit;
    edtUserName: TEdit;
    lblAddress: TLabel;
    lblDescription: TLabel;
    lblHint: TLabel;
    lblPort: TLabel;
    lblUserName: TLabel;
    procedure btnOKClick(Sender: TObject);
  public
    Source : TRbnSource;
    //True with Source filled in when the user pressed OK
    function Edit : Boolean;
  end;

implementation

{$R *.lfm}

function TfrmRbnSourceEdit.Edit : Boolean;
begin
  edtDescription.Text := Source.Description;
  edtAddress.Text     := Source.Address;
  edtPort.Text        := IntToStr(Source.Port);
  edtUserName.Text    := Source.UserName;
  Result := ShowModal = mrOK
end;

procedure TfrmRbnSourceEdit.btnOKClick(Sender: TObject);
var
  Port : Integer;
begin
  if (Trim(edtDescription.Text) = '') or (Trim(edtAddress.Text) = '') then
  begin
    ShowMessage('Name and server must be filled in.');
    exit
  end;
  if (not TryStrToInt(Trim(edtPort.Text), Port)) or (Port < 1) or (Port > 65535) then
  begin
    ShowMessage('Port must be a number between 1 and 65535.');
    exit
  end;
  Source.Description := Trim(edtDescription.Text);
  Source.Address     := Trim(edtAddress.Text);
  Source.Port        := Port;
  Source.UserName    := Trim(UpperCase(edtUserName.Text));
  ModalResult := mrOK
end;

end.
