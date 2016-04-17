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
    fraExportPref1 : TfraExportPref;
    procedure btnOKClick(Sender : TObject);
    procedure FormShow(Sender : TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmExportPref : TfrmExportPref;

implementation

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

initialization
  {$I fExportPref.lrs}

end.

