unit fChangeFreq;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, lcltype;

type

  { TfrmChangeFreq }

  TfrmChangeFreq = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    edtRXOffset : TEdit;
    edtCW: TEdit;
    edtData: TEdit;
    edtEnd: TEdit;
    edtBegin: TEdit;
    edtTXOffset : TEdit;
    edtSSB: TEdit;
    Label1: TLabel;
    Label10 : TLabel;
    Label11 : TLabel;
    Label12 : TLabel;
    Label13 : TLabel;
    Label14 : TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6 : TLabel;
    Label7 : TLabel;
    Label8 : TLabel;
    Label9 : TLabel;
    procedure btnOKClick(Sender: TObject);
    procedure ChkKeyPress(Sender: TObject; var Key: char);
  private
    { private declarations }

  public
    { public declarations }
  end; 

var
  frmChangeFreq: TfrmChangeFreq;

implementation
{$R *.lfm}

{ TfrmChangeFreq }

procedure TfrmChangeFreq.ChkKeyPress(Sender: TObject; var Key: char);
begin
  if (not (Key in ['0'..'9', '.','-','+', #8, #127])) OR ( (Key = '.') and (pos('.',TEdit(Sender).Text)>0) ) then Key := #0;
end;


procedure TfrmChangeFreq.btnOKClick(Sender: TObject);
var
  f : Currency;
begin
  if NOT TryStrToCurr(edtSSB.Text,f) then
  begin
    Application.MessageBox('You must enter correct frequency!','Error',mb_OK+mb_IconError);
    edtSSB.SetFocus;
    exit
  end;
  
  if NOT TryStrToCurr(edtData.Text,f) then
  begin
    Application.MessageBox('You must enter correct frequency!','Error',mb_OK+mb_IconError);
    edtData.SetFocus;
    exit
  end;

  if NOT TryStrToCurr(edtCW.Text,f) then
  begin
    Application.MessageBox('You must enter correct frequency!','Error',mb_OK+mb_IconError);
    edtCW.SetFocus;
    exit
  end;

  if NOT TryStrToCurr(edtBegin.Text,f) then
  begin
    Application.MessageBox('You must enter correct frequency!','Error',mb_OK+mb_IconError);
    edtBegin.SetFocus;
    exit
  end;

  if NOT TryStrToCurr(edtEnd.Text,f) then
  begin
    Application.MessageBox('You must enter correct frequency!','Error',mb_OK+mb_IconError);
    edtEnd.SetFocus;
    exit
  end;

  if NOT TryStrToCurr(edtRXOffset.Text,f) then
  begin
    Application.MessageBox('You must enter correct frequency!','Error',mb_OK+mb_IconError);
    edtRXOffset.SetFocus;
    exit
  end;

  if NOT TryStrToCurr(edtTXOffset.Text,f) then
  begin
    Application.MessageBox('You must enter correct frequency!','Error',mb_OK+mb_IconError);
    edtTXOffset.SetFocus;
    exit
  end;

  ModalResult := mrOK;
end;


end.

