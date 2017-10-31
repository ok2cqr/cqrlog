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
    fraExportPref1 : TfraExportPref;
    procedure btnOKClick(Sender : TObject);
    procedure btnReSetClick(Sender: TObject);
    procedure FormShow(Sender : TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmExportPref : TfrmExportPref;
  AllChk        : Boolean = False;

implementation
{$R *.lfm}

uses dUtils;

{ TfrmExportPref }

procedure TfrmExportPref.FormShow(Sender : TObject);
begin
  dmUtils.LoadFontSettings(frmExportPref);
  fraExportPref1.LoadExportPref
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

end.

