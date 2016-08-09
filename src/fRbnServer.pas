unit fRbnServer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, lclType;

type

  { TfrmRbnServer }

  TfrmRbnServer = class(TForm)
    Button1: TButton;
    Button2: TButton;
    edtUserName: TEdit;
    edtServerName: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure Button1Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmRbnServer: TfrmRbnServer;

implementation
{$R *.lfm}

{ TfrmRbnServer }

procedure TfrmRbnServer.Button1Click(Sender: TObject);
begin
  if (edtServerName.Text='') then
  begin
    Application.MessageBox('Enter address to RBN server, please','Warning...', mb_ok+mb_IconWarning);
    edtServerName.SetFocus;
    exit
  end;

  if (Pos(':',edtServerName.Text)=0) then
  begin
    Application.MessageBox('Address does not have PORT specified. The correct value is servername:port','Warning...', mb_ok+mb_IconWarning);
    edtServerName.SetFocus;
    exit
  end;
  ModalResult := mrOK
end;

end.

