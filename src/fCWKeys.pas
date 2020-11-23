unit fCWKeys;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls,frCWKeys,LCLType;

type

  { TfrmCWKeys }

  TfrmCWKeys = class(TForm)
    fraCWKeys : TfraCWKeys;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender : TObject; var Key : Word; Shift : TShiftState);
    procedure FormShow(Sender: TObject);
  private

  public
    { public declarations }
  end; 

var
  frmCWKeys: TfrmCWKeys;

implementation
  {$R *.lfm}

uses dUtils,fNewQSO, uMyIni;

{ TfrmCWKeys }

procedure TfrmCWKeys.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmCWKeys)
end;

procedure TfrmCWKeys.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
   mykey :char = #13;

begin
   case Key of
   VK_F1 .. VK_F10,
   33,
   34              : frmNewQSO.FormKeyDown(Sender,Key,Shift);
   VK_ESCAPE       : frmNewQSO.CWint.StopSending;
   13              : if (cqrini.ReadInteger('CW','EnterFunction',1)=2) then frmNewQSO.FormKeyPress(Sender,mykey);
   end;
end;

procedure TfrmCWKeys.FormKeyUp(Sender : TObject; var Key : Word;
  Shift : TShiftState);
begin
  if (Key >= VK_F1) and (Key <= VK_F10) and (Shift = []) then
                      frmNewQSO.FormKeyUp(Sender,Key,Shift);

  if (key= VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0
  end
end;

procedure TfrmCWKeys.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmCWKeys)
end;

end.

