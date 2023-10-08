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
    btnUsr: TButton;
    btnOK: TButton;
    btnCancel: TButton;
    btnModRst: TButton;
    btnLoc: TButton;
    edtSpot: TEdit;
    Label1: TLabel;
    procedure btnLocClick(Sender: TObject);
    procedure btnModRstClick(Sender: TObject);
    procedure btnUsrClick(Sender: TObject);
    procedure btnUsrMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormActivate(Sender: TObject);
    procedure edtSpotEnter(Sender: TObject);
    procedure edtSpotKeyPress(Sender: TObject; var Key: char);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    ModeRst,
    HisMyLoc,
    Scall,
    Srst_s,
    Sstx,
    Sstx_str,
    Ssrx,
    Ssrx_str,
    SHisName,
    SHelloMsg  :String;
    { public declarations }
  end; 

var
  frmSendSpot: TfrmSendSpot;
  UsrString    :String;

implementation
{$R *.lfm}

{ TfrmSendSpot }
uses dUtils, uMyIni,fDXCluster;



procedure TfrmSendSpot.edtSpotEnter(Sender: TObject);
begin
  edtSpot.SelStart  := Length(edtSpot.Text);
  edtSpot.SelLength := 1;
end;

procedure TfrmSendSpot.FormActivate(Sender: TObject);
begin
  edtSpot.SetFocus;
end;

procedure TfrmSendSpot.btnModRstClick(Sender: TObject);
begin
  if pos(ModeRst, edtSpot.Text) = 0 then
    edtSpot.Text := edtSpot.Text+ ' '+ModeRst;
end;

procedure TfrmSendSpot.btnUsrClick(Sender: TObject);
begin
  UsrString := cqrini.ReadString('DXCluster', 'UsrMsg', '');
  UsrString:=dmUtils.GetCWMessage('',Scall,Srst_s,Sstx,Sstx_str,Ssrx,Ssrx_str,SHisName,SHelloMsg,UsrString);
  if pos(UsrString, edtSpot.Text) = 0 then
     edtSpot.Text := edtSpot.Text+' '+UsrString;
end;

procedure TfrmSendSpot.btnUsrMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  QueryResult: Boolean;
  UsrString: string;
begin
  If Button = mbRight then
    begin
      UsrString := cqrini.ReadString('DXCluster', 'UsrMsg', '');
      if InputQuery('Question', 'Type in user string', false, UsrString)
        then
            Begin
              btnUsr.Hint:=UsrString;
              cqrini.WriteString('DXCluster', 'UsrMsg', UsrString);
              if length(UsrString)>25 then ShowMessage('Your string might be too long!'+LineEnding+'Length: '+IntToStr(length(UsrString))+'chrs')
            end
    end;
end;

procedure TfrmSendSpot.btnLocClick(Sender: TObject);
begin
  if pos(HisMyLoc,  edtSpot.Text ) = 0 then
    edtSpot.Text := edtSpot.Text+ ' '+HisMyLoc;
end;

procedure TfrmSendSpot.edtSpotKeyPress(Sender: TObject; var Key: char);
begin
  if (key = #13) then
  begin
    if (edtSpot.Text <> '') then
      btnOK.Click;
  end;
end;

procedure TfrmSendSpot.FormShow(Sender: TObject);
begin
  if not (frmDXCluster.ConTelnet) then
   Begin
     ShowMessage('You must connect to telnet DXCluster first!');
     btnCancel.Click;
   end;
  UsrString := cqrini.ReadString('DXCluster', 'UsrMsg', '');
  UsrString:=dmUtils.GetCWMessage('',Scall,Srst_s,Sstx,Sstx_str,Ssrx,Ssrx_str,SHisName,SHelloMsg,UsrString);
  btnUsr.Hint:=UsrString;
  btnLoc.Hint:= HisMyLoc;
  btnModRst.Hint:= ModeRst;
end;

end.

