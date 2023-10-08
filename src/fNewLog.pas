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
    btnCancel: TButton;
    edtLogName: TEdit;
    edtLogNR: TEdit;
    edtLogCpyNR: TEdit;
    lblLogCpyNR: TLabel;
    lblLogNr: TLabel;
    lblLogName: TLabel;
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
  nr,cnr : integer;
begin
  if edtLogNR.Enabled then
  begin
    if not TryStrToInt(edtLogNR.Text,nr) then
    begin
      Application.MessageBox('Please enter correct log number!','Info ...', mb_ok + mb_IconInformation);
      exit
    end;
    if edtLogCpyNR.Text<>'' then
      Begin
       if not TryStrToInt(edtLogCpyNR.Text,cnr) then
       begin
         Application.MessageBox('Please enter correct log number to copy from!','Info ...', mb_ok + mb_IconInformation);
         exit
       end;
      end;
    if dmData.LogExists(nr) then
    begin
      Application.MessageBox(PChar(Ansistring('Log number '+ inttostr(nr)+' already exists!')),'Info ...', mb_ok + mb_IconInformation);
      exit
    end;
    if (edtLogCpyNR.Text<>'') then
     if not dmData.LogExists(cnr) then
        begin
          Application.MessageBox(PChar(Ansistring('Log '+inttostr(cnr)+' does not exist for copy config from!')),'Info ...', mb_ok + mb_IconInformation);
          exit
        end
  end;
  ModalResult := mrOK
end;

end.

