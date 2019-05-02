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
    lblToShowMouseOverTextCwKeys: TLabel;
    procedure btnF10MouseEnter(Sender: TObject);
    procedure btnF10MouseLeave(Sender: TObject);
    procedure btnF1MouseEnter(Sender: TObject);
    procedure btnF1MouseLeave(Sender: TObject);
    procedure btnF2MouseEnter(Sender: TObject);
    procedure btnF2MouseLeave(Sender: TObject);
    procedure btnF3MouseEnter(Sender: TObject);
    procedure btnF3MouseLeave(Sender: TObject);
    procedure btnF4MouseEnter(Sender: TObject);
    procedure btnF4MouseLeave(Sender: TObject);
    procedure btnF5MouseEnter(Sender: TObject);
    procedure btnF5MouseLeave(Sender: TObject);
    procedure btnF6MouseEnter(Sender: TObject);
    procedure btnF6MouseLeave(Sender: TObject);
    procedure btnF7MouseEnter(Sender: TObject);
    procedure btnF7MouseLeave(Sender: TObject);
    procedure btnF8MouseEnter(Sender: TObject);
    procedure btnF8MouseLeave(Sender: TObject);
    procedure btnF9MouseEnter(Sender: TObject);
    procedure btnF9MouseLeave(Sender: TObject);
    procedure btnPgDnMouseEnter(Sender: TObject);
    procedure btnPgDnMouseLeave(Sender: TObject);
    procedure btnPgUpMouseEnter(Sender: TObject);
    procedure btnPgUpMouseLeave(Sender: TObject);
    procedure FrameMouseEnter(Sender: TObject);
    procedure FrameResize(Sender: TObject);
    procedure btnClicked(Sender: TObject);
  private
    { private declarations }
  public
    procedure UpdateFKeyLabels;
  end;

implementation

uses dUtils, fNewQSO, uMyIni, dData, fCWType;

{$R *.lfm}

{ TfraCWKeys }

procedure TfraCWKeys.FrameResize(Sender: TObject);
var
  w, h, l, t: word;
  i: integer;
  c: word;
begin
  h := Round(Height / 2.7 ) - 2;
  w := Round(Width / 6) - 2;
  t := Round(Height / 2.7 );
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
     end;
      if (Components[i] is TLabel) then
       begin
        (Components[i] as TLabel).Height := h;
        (Components[i] as TLabel).Width := w*5;
       end;
   end
end;

procedure TfraCWKeys.btnF1MouseEnter(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:=dmUtils.GetCWMessage('F1',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfraCWKeys.btnF10MouseEnter(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:=dmUtils.GetCWMessage('F10',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfraCWKeys.btnF10MouseLeave(Sender: TObject);
begin
    self.lblToShowMouseOverTextCwKeys.Caption:='';
end;

procedure TfraCWKeys.btnF1MouseLeave(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:='';
end;

procedure TfraCWKeys.btnF2MouseEnter(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:=dmUtils.GetCWMessage('F2',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfraCWKeys.btnF2MouseLeave(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:='';
end;

procedure TfraCWKeys.btnF3MouseEnter(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:=dmUtils.GetCWMessage('F3',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfraCWKeys.btnF3MouseLeave(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:='';
end;

procedure TfraCWKeys.btnF4MouseEnter(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:=dmUtils.GetCWMessage('F4',frmNewQSO.edtCall.Text,
     frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfraCWKeys.btnF4MouseLeave(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:='';
end;

procedure TfraCWKeys.btnF5MouseEnter(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:=dmUtils.GetCWMessage('F5',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfraCWKeys.btnF5MouseLeave(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:='';
end;

procedure TfraCWKeys.btnF6MouseEnter(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:=dmUtils.GetCWMessage('F6',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfraCWKeys.btnF6MouseLeave(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:='';
end;

procedure TfraCWKeys.btnF7MouseEnter(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:=dmUtils.GetCWMessage('F7',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfraCWKeys.btnF7MouseLeave(Sender: TObject);
begin
    self.lblToShowMouseOverTextCwKeys.Caption:='';
end;

procedure TfraCWKeys.btnF8MouseEnter(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:=dmUtils.GetCWMessage('F8',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfraCWKeys.btnF8MouseLeave(Sender: TObject);
begin
    self.lblToShowMouseOverTextCwKeys.Caption:='';
end;

procedure TfraCWKeys.btnF9MouseEnter(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:=dmUtils.GetCWMessage('F9',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfraCWKeys.btnF9MouseLeave(Sender: TObject);
begin
    self.lblToShowMouseOverTextCwKeys.Caption:='';
end;

procedure TfraCWKeys.btnPgDnMouseEnter(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:='cw keyspeed -2 wpm';
end;

procedure TfraCWKeys.btnPgDnMouseLeave(Sender: TObject);
begin
    self.lblToShowMouseOverTextCwKeys.Caption:='';
end;

procedure TfraCWKeys.btnPgUpMouseEnter(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:='cw keyspeed +2 wpm';
end;

procedure TfraCWKeys.btnPgUpMouseLeave(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:='';
end;

procedure TfraCWKeys.FrameMouseEnter(Sender: TObject);
begin

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
                    frmNewQSO.sbNewQSO.Panels[2].Text := IntToStr(speed)+'WPM';
                    if (frmCWType <> nil ) then frmCWType.edtSpeed.Value := speed;
                  end
                end;

    'PgD'       :begin
                    if Assigned(frmNewQSO.CWint) then
                    begin
                      speed := frmNewQSO.CWint.GetSpeed-2;
                      frmNewQSO.CWint.SetSpeed(speed);
                      frmNewQSO.sbNewQSO.Panels[2].Text := IntToStr(speed)+'WPM';
                      if (frmCWType <> nil ) then frmCWType.edtSpeed.Value := speed;
                    end
                  end;
    else
      Begin
        cwkey := copy((Sender as TButton).Name,4,3);
        if ((frmNewQSO.cmbMode.Text='SSB') or (frmNewQSO.cmbMode.Text='FM') or (frmNewQSO.cmbMode.Text='AM')) then
           frmNewQSO.RunVK(cwkey)
        else
        if Assigned(frmNewQSO.CWint) then
         frmNewQSO.CWint.SendText(dmUtils.GetCWMessage(cwkey,frmNewQSO.edtCall.Text,frmNewQSO.edtHisRST.Text,
         frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
         frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''));
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

