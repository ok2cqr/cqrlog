unit frCWKeys;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls,ActnList;

type

  { TfraCWKeys }

  TfraCWKeys = class(TFrame)
    acSend : TAction;
    btnF1: TButton;
    btnF10 : TButton;
    btnF2: TButton;
    btnF3: TButton;
    btnF4: TButton;
    btnF5: TButton;
    btnF6: TButton;
    btnF7 : TButton;
    btnF8 : TButton;
    btnF9 : TButton;
    procedure FrameResize(Sender: TObject);
    procedure btnClicked(Sender: TObject);
  private
    { private declarations }
  public
    procedure UpdateFKeyLabels;
  end;

implementation

uses dUtils,fNewQSO, uMyIni;

{$R *.lfm}

{ TfraCWKeys }

procedure TfraCWKeys.FrameResize(Sender: TObject);
var
  w, h, l, t: word;
  i: integer;
  c: word;
begin
  h := Round(Height / 2) - 2;
  w := Round(Width / 5) - 2;
  t := Round(Height / 2);
  c := 0;

  for i := 0 to ComponentCount - 1 do
  begin
    if (Components[i] is TButton) then
    begin
      (Components[i] as TButton).Height := h;
      (Components[i] as TButton).Width := w;

      (Components[i] as TButton).Left := c * w + 5;
      Inc(c);
      if (Components[i] as TButton).TabOrder = 4 then
        c := 0;

      if (Components[i] as TButton).TabOrder > 4 then
        (Components[i] as TButton).Top := t
    end
  end
end;

procedure TfraCWKeys.btnClicked(Sender : TObject);
var
  cwkey : String;
begin
  if Sender is TButton then
  begin
    cwkey := copy((Sender as TButton).Name,4,3);
    frmNewQSO.CWint.SendText(dmUtils.GetCWMessage(cwkey,frmNewQSO.edtCall.Text,frmNewQSO.edtHisRST.Text,frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''))
  end
end;

procedure TfraCWKeys.UpdateFKeyLabels;
begin
  btnF1.Caption  := cqrini.ReadString('CW','CapF1','CQ');
  btnF2.Caption  := cqrini.ReadString('CW','CapF2','F2');
  btnF3.Caption  := cqrini.ReadString('CW','CapF3','F3');
  btnF4.Caption  := cqrini.ReadString('CW','CapF4','F4');
  btnF5.Caption  := cqrini.ReadString('CW','CapF5','F5');
  btnF6.Caption  := cqrini.ReadString('CW','CapF6','F6');
  btnF7.Caption  := cqrini.ReadString('CW','CapF7','F7');
  btnF8.Caption  := cqrini.ReadString('CW','CapF8','F8');
  btnF9.Caption  := cqrini.ReadString('CW','CapF9','F9');
  btnF10.Caption  := cqrini.ReadString('CW','CapF10','F10')
end;

end.

