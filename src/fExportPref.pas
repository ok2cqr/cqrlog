unit fExportPref;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, frExportPref;

type

  { TfrmExportPref }

  TfrmExportPref = class(TForm)
    btnOK : TButton;
    btnCancel : TButton;
    btnReSet: TButton;
    CheckBox1: TCheckBox;
    fraExportPref1: TfraExportPref;
    procedure btnOKClick(Sender : TObject);
    procedure btnReSetClick(Sender: TObject);
    procedure chkAutoColumnChange(Sender: TObject);
    procedure FormShow(Sender : TObject);
  private
    { private declarations }
  public
    { public declarations }
    Procedure HideWidths(Hid:Boolean);
    Procedure HideAll(Hid:Boolean);
  end;

var
  frmExportPref : TfrmExportPref;
  AllChk        : Boolean = False;

implementation
{$R *.lfm}

uses dUtils,fMain;

{ TfrmExportPref }
Procedure TfrmExportPref.HideAll(Hid:Boolean);
var  i : integer;
Begin
for i := 0 to fraExportPref1.ComponentCount - 1 do
    if fraExportPref1.Components[i] is TEdit then
       tedit(fraExportPref1.Components[i]).Visible := not Hid;
end;
Procedure TfrmExportPref.HideWidths(Hid:Boolean);
var  i : integer;
Begin
   for i := 0 to fraExportPref1.ComponentCount - 1 do
    if fraExportPref1.Components[i] is TEdit then
       if (StrToIntDef(tedit(fraExportPref1.Components[i]).Text,-1) > -1 ) then
          tedit(fraExportPref1.Components[i]).Visible := not Hid;
end;

procedure TfrmExportPref.FormShow(Sender : TObject);
begin
  dmUtils.LoadFontSettings(frmExportPref);
  fraExportPref1.LoadExportPref;
  if  not frmMain.ShowWidths then //this is ADIF export case
     Begin
       HideAll(True);
       fraExportPref1.chkAutoColumn.Visible := False;
     end
   else if fraExportPref1.chkAutoColumn.Checked = True then // HTML export but auto column checked
     HideWidths(true);
end;

procedure TfrmExportPref.btnOKClick(Sender : TObject);
begin
  fraExportPref1.SaveExportPref;
  ModalResult := mrOK
end;

procedure TfrmExportPref.btnReSetClick(Sender: TObject);
var  i : integer;
begin
    for i := 0 to fraExportPref1.ComponentCount - 1 do
      if fraExportPref1.Components[i] is TCheckbox then
         tcheckbox(fraExportPref1.Components[i]).checked := AllChk;
    AllChk := not AllChk;
end;

procedure TfrmExportPref.chkAutoColumnChange(Sender: TObject);
begin
  if frmMain.ShowWidths then // only in HTML export
   Begin
      if fraExportPref1.chkAutoColumn.Checked = True then
         HideWidths(True)
       else
         HideWidths(False);
   end;
end;


end.

