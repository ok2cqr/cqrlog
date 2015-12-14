unit fAddRadioMemory;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, LCLType;

type

  { TfrmAddRadioMemory }

  TfrmAddRadioMemory = class(TForm)
    Button1: TButton;
    Button2: TButton;
    cmbMode: TComboBox;
    edtFreq: TEdit;
    edtWidth: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmAddRadioMemory: TfrmAddRadioMemory;

implementation

{ TfrmAddRadioMemory }

uses dUtils;

procedure TfrmAddRadioMemory.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(frmAddRadioMemory);
  dmUtils.InsertModes(cmbMode);
  edtFreq.SetFocus
end;

procedure TfrmAddRadioMemory.Button1Click(Sender: TObject);
var
  f : Double;
begin
  if not TryStrToFloat(edtFreq.Text,f) then
  begin
    Application.MessageBox('Please enter correct frequency','Error...', mb_OK+mb_IconError);
    edtFreq.SetFocus;
    exit
  end;

  if not TryStrToFloat(edtWidth.Text,f) then
  begin
    Application.MessageBox('Please enter correct bandwidth','Error...', mb_OK+mb_IconError);
    edtWidth.SetFocus;
    exit
  end;

  ModalResult := mrOK
end;

initialization
  {$I fAddRadioMemory.lrs}

end.

