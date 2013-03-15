unit fCWKeys;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls;

type

  { TfrmCWKeys }

  TfrmCWKeys = class(TForm)
    btnF1: TButton;
    btnF10: TButton;
    btnF2: TButton;
    btnF3: TButton;
    btnF4: TButton;
    btnF5: TButton;
    btnF6: TButton;
    btnF7: TButton;
    btnF8: TButton;
    btnF9: TButton;
    procedure btnF10Click(Sender : TObject);
    procedure btnF1Click(Sender : TObject);
    procedure btnF2Click(Sender : TObject);
    procedure btnF3Click(Sender : TObject);
    procedure btnF4Click(Sender : TObject);
    procedure btnF5Click(Sender : TObject);
    procedure btnF6Click(Sender : TObject);
    procedure btnF7Click(Sender : TObject);
    procedure btnF8Click(Sender : TObject);
    procedure btnF9Click(Sender : TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    procedure SendCWMessage(cwkey : String);
  public
    { public declarations }
  end; 

var
  frmCWKeys: TfrmCWKeys;

implementation

uses dUtils,fNewQSO;

{ TfrmCWKeys }

procedure TfrmCWKeys.SendCWMessage(cwkey : String);
begin
  frmNewQSO.CWint.SendText(dmUtils.GetCWMessage(cwkey,frmNewQSO.edtCall.Text,frmNewQSO.edtHisRST.Text,frmNewQSO.edtName.Text,''))
end;

procedure TfrmCWKeys.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmCWKeys)
end;

procedure TfrmCWKeys.btnF1Click(Sender : TObject);
begin
  SendCWMessage('F1')
end;

procedure TfrmCWKeys.btnF10Click(Sender : TObject);
begin
  SendCWMessage('F10')
end;

procedure TfrmCWKeys.btnF2Click(Sender : TObject);
begin
  SendCWMessage('F2')
end;

procedure TfrmCWKeys.btnF3Click(Sender : TObject);
begin
  SendCWMessage('F3')
end;

procedure TfrmCWKeys.btnF4Click(Sender : TObject);
begin
    SendCWMessage('F4')
end;

procedure TfrmCWKeys.btnF5Click(Sender : TObject);
begin
  SendCWMessage('F5')
end;

procedure TfrmCWKeys.btnF6Click(Sender : TObject);
begin
  SendCWMessage('F6')
end;

procedure TfrmCWKeys.btnF7Click(Sender : TObject);
begin
  SendCWMessage('F7')
end;

procedure TfrmCWKeys.btnF8Click(Sender : TObject);
begin
  SendCWMessage('F8')
end;

procedure TfrmCWKeys.btnF9Click(Sender : TObject);
begin
  SendCWMessage('F9')
end;

procedure TfrmCWKeys.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmCWKeys)
end;

initialization
  {$I fCWKeys.lrs}

end.

