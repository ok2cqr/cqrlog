unit fException;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls;

type

  { TfrmException }

  TfrmException = class(TForm)
    Button1: TButton;
    Button2: TButton;
    btnSave: TButton;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    memErrorMessage: TMemo;
    Memo2: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    dlgSave: TSaveDialog;
    procedure btnSaveClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmException: TfrmException;

implementation

{$R *.lfm}

{ TfrmException }

procedure TfrmException.Button2Click(Sender: TObject);
begin
  Application.Terminate
end;

procedure TfrmException.btnSaveClick(Sender: TObject);
begin
  if dlgSave.Execute then
    memErrorMessage.Lines.SaveToFile(dlgSave.FileName)
end;

end.

