unit fNewQTHProfile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, lcltype;

type

  { TfrmNewQTHProfile }

  TfrmNewQTHProfile = class(TForm)
    btnSave: TButton;
    btnCancel: TButton;
    chkVisible: TCheckBox;
    edtProfNr: TEdit;
    edtLocator: TEdit;
    lblLocator: TLabel;
    lblQTH: TLabel;
    lblEquipment: TLabel;
    lblRemarks: TLabel;
    lblProfileNumber: TLabel;
    mRemarks: TMemo;
    mEquipment: TMemo;
    mQTH: TMemo;
    procedure edtLocatorChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure edtProfNrKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    OldProf : String;
    { private declarations }
  public
    Editing : Boolean;
    { public declarations }
  end; 

var
  frmNewQTHProfile: TfrmNewQTHProfile;

implementation
{$R *.lfm}

{ TfrmNewQTHProfile }
uses dUtils, dData;

procedure TfrmNewQTHProfile.btnSaveClick(Sender: TObject);
begin
  if NOT dmUtils.IsLocOK(edtLocator.Text) then
  begin
    Application.MessageBox('You must enter correct locator','Error!',mb_ok + mb_IconError);
    edtLocator.SetFocus;
    exit
  end;
  if (Editing) then
  begin
    if (OldProf <> edtProfNr.Text) then
    begin
      if dmData.ProfileExists(edtProfNr.Text) then
      begin
         Application.MessageBox('Profile already exists!','Warning ...',mb_ok + mb_IconWarning);
        edtProfNr.SetFocus;
        exit
      end
    end
  end
  else begin
    if dmData.ProfileExists(edtProfNr.Text) then
    begin
      Application.MessageBox('Profile already exists!','Warning ...',mb_ok + mb_IconWarning);
      edtProfNr.SetFocus;
      exit
    end
  end;
  ModalResult := mrOK
end;

procedure TfrmNewQTHProfile.edtProfNrKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ((key >= 65) and (key <=90)) or (key = 61) or
     (key = 63) or (key = 44) or (key = 46) or (key = 47) or (key = 32) then
    key := 0
end;

procedure TfrmNewQTHProfile.FormShow(Sender: TObject);
begin
  if Editing then
    OldProf := edtProfNr.Text;
  edtProfNr.SetFocus
end;

procedure TfrmNewQTHProfile.FormCreate(Sender: TObject);
begin
  Editing := False
end;

procedure TfrmNewQTHProfile.edtLocatorChange(Sender: TObject);
begin
  edtLocator.Text := dmUtils.StdFormatLocator(edtLocator.Text);
  edtLocator.SelStart := Length(edtLocator.Text);
end;

end.

