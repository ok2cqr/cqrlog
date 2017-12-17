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
    btnPgUp: TButton;
    btnPgDn: TButton;
    procedure FrameResize(Sender: TObject);
    procedure btnClicked(Sender: TObject);
  private
    { private declarations }
  public
    procedure UpdateFKeyLabels;
  end;

implementation

uses dUtils,fNewQSO, uMyIni,dData;

{$R *.lfm}

{ TfraCWKeys }

procedure TfraCWKeys.FrameResize(Sender: TObject);  //after adding 2 buttons this did not work! Why?
var
  w, h, l, t: word;
  i: integer;
  c: word;
begin
  h := Round(Height / 2) - 2;
  w := Round(Width / 6) - 2;
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
      if (Components[i] as TButton).TabOrder = 5 then
        c := 0;

      if (Components[i] as TButton).TabOrder > 5 then
        (Components[i] as TButton).Top := t

      //after adding 2 buttons this did not work before stop Lazarus, manual edit fCWKeys.lfm
      //so that 1st new button (pgUp) was in order after btnF5's definition and start Lazarus again.
      //So Tab order itself does not give TButtons their right places after resize if lfm-file
      //component-order is not right!!!
      //For loop picks them up in wrong order (added buttons last, if lfm not edited) and even
      //loop gives all buttons proper Top/Left/Width/Height values according TabOrder they place
      //themselfs wrong places into frame.
      //Why?  Bug in Lazarus 1.2.6 ?

     end
   end
end;

procedure TfraCWKeys.btnClicked(Sender : TObject);
var
  cwkey : String;
  speed : integer;
begin
  if Sender is TButton then
  begin
    cwkey := copy((Sender as TButton).Name,4,3);
    if dmData.DebugLevel >=1 then Writeln('Button: ',cwkey);

    case cwkey of
    'PgU'      :begin
                  if Assigned(frmNewQSO.CWint) then
                  begin
                    speed := frmNewQSO.CWint.GetSpeed+2;
                    frmNewQSO.CWint.SetSpeed(speed);
                    frmNewQSO.sbNewQSO.Panels[2].Text := IntToStr(speed)+'WPM'
                  end
                end;

    'PgD'       :begin
                    if Assigned(frmNewQSO.CWint) then
                    begin
                      speed := frmNewQSO.CWint.GetSpeed-2;
                      frmNewQSO.CWint.SetSpeed(speed);
                      frmNewQSO.sbNewQSO.Panels[2].Text := IntToStr(speed)+'WPM'
                    end
                  end;
    else
      Begin
        cwkey := copy((Sender as TButton).Name,4,3);
        if ((frmNewQSO.cmbMode.Text='SSB') or (frmNewQSO.cmbMode.Text='FM') or (frmNewQSO.cmbMode.Text='AM')) then
           frmNewQSO.RunVK(cwkey)
        else
        if Assigned(frmNewQSO.CWint) then
        // works with contest addition - frmNewQSO.CWint.SendText(dmUtils.GetCWMessage(cwkey,frmNewQSO.edtCall.Text,frmNewQSO.edtHisRST.Text,frmNewQSO.edtHisRSTstx.Text,frmNewQSO.edtHisRSTstxAdd.Text,frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''));
         frmNewQSO.CWint.SendText(dmUtils.GetCWMessage(cwkey,frmNewQSO.edtCall.Text,frmNewQSO.edtHisRST.Text,frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''))
      end;
    end;
  end;
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

