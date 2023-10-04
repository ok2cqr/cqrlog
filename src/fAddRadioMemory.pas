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
    edtInfo: TEdit;
    edtFreq: TEdit;
    edtWidth: TEdit;
    lblFreq: TLabel;
    lblMode: TLabel;
    lblWidth: TLabel;
    lblInfo: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure edtFreqKeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender : TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmAddRadioMemory: TfrmAddRadioMemory;

implementation
{$R *.lfm}

{ TfrmAddRadioMemory }

uses dUtils;

procedure TfrmAddRadioMemory.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(frmAddRadioMemory);
  edtFreq.SetFocus;
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

  if cmbMode.ItemIndex < 0 then
  begin
    Application.MessageBox('Please enter correct mode','Error...', mb_OK+mb_IconError);
    cmbMode.SetFocus;
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

procedure TfrmAddRadioMemory.edtFreqKeyPress(Sender: TObject; var Key: char);
begin
  if not (key in ['0'..'9','.']) then key:=#0;
end;

procedure TfrmAddRadioMemory.FormCreate(Sender : TObject);
begin
  dmUtils.InsertModes(cmbMode);
  cmbMode.Items.Delete(cmbMode.Items.IndexOf('SSB'));
  cmbMode.Items.Insert(1,'USB');
  cmbMode.Items.Insert(2,'LSB')
end;

procedure TfrmAddRadioMemory.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = VK_RETURN then  Button1Click(nil);
  if key = VK_ESCAPE then ModalResult:=mrCancel;
end;

initialization
  {$I fAddRadioMemory.lrs}

end.

