unit fNewLog;

{$mode objfpc}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, LCLType;

type

  { TfrmNewLog }

  TfrmNewLog = class(TForm)
    btnOK: TButton;
    Button2: TButton;
    edtLogName: TEdit;
    edtLogNR: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure btnOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmNewLog: TfrmNewLog;

implementation
{$R *.lfm}

uses dUtils, dData;

{ TfrmNewLog }

procedure TfrmNewLog.FormShow(Sender: TObject);
begin
  //dmUtils.LoadWindowPos(self);
  if edtLogNR.Enabled then
    edtLogNR.Text := IntToStr(dmData.GetNewLogNumber);

  edtLogName.SetFocus
end;

procedure TfrmNewLog.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  //dmUtils.SaveWindowPos(self)
end;

procedure TfrmNewLog.btnOKClick(Sender: TObject);
var
  nr : Integer;
begin
  if edtLogNR.Enabled then
  begin
    if not TryStrToInt(edtLogNR.Text,nr) then
    begin
      Application.MessageBox('Please enter correct log number!','Info ...', mb_ok + mb_IconInformation);
      exit
    end;
    if dmData.LogExists(nr) then
    begin
      Application.MessageBox('Log with this number already exists!','Info ...', mb_ok + mb_IconInformation);
      exit
    end
  end;
  ModalResult := mrOK
end;

end.

