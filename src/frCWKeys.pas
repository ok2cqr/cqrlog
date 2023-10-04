unit frCWKeys;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls,ActnList, LCLType;

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
    procedure FrameResize(Sender: TObject);
    procedure btnClicked(Sender: TObject);
  private
    { private declarations }
  public
    procedure UpdateFKeyLabels;
  end;

implementation

uses dUtils, fNewQSO, uMyIni, dData, fCWType, fContest;

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
      frmNewQSO.edtContestSerialReceived.Text,frmNewQSO.edtContestExchangeMessageReceived.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfraCWKeys.btnF10MouseEnter(Sender: TObject);
begin
  self.lblToShowMouseOverTextCwKeys.Caption:=dmUtils.GetCWMessage('F10',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtContestSerialReceived.Text,frmNewQSO.edtContestExchangeMessageReceived.Text,
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
      frmNewQSO.edtContestSerialReceived.Text,frmNewQSO.edtContestExchangeMessageReceived.Text,
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
      frmNewQSO.edtContestSerialReceived.Text,frmNewQSO.edtContestExchangeMessageReceived.Text,
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
     frmNewQSO.edtContestSerialReceived.Text,frmNewQSO.edtContestExchangeMessageReceived.Text,
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
      frmNewQSO.edtContestSerialReceived.Text,frmNewQSO.edtContestExchangeMessageReceived.Text,
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
      frmNewQSO.edtContestSerialReceived.Text,frmNewQSO.edtContestExchangeMessageReceived.Text,
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
      frmNewQSO.edtContestSerialReceived.Text,frmNewQSO.edtContestExchangeMessageReceived.Text,
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
      frmNewQSO.edtContestSerialReceived.Text,frmNewQSO.edtContestExchangeMessageReceived.Text,
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
      frmNewQSO.edtContestSerialReceived.Text,frmNewQSO.edtContestExchangeMessageReceived.Text,
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

procedure TfraCWKeys.btnClicked(Sender : TObject);
var
  cwkey : String;
  Key   : Word;
begin
  if Sender is TButton then
  begin
    cwkey := copy((Sender as TButton).Name,4,4);
    case cwkey of
      'F1'  :    Key := VK_F1;
      'F2'  :    Key := VK_F2;
      'F3'  :    Key := VK_F3;
      'F4'  :    Key := VK_F4;
      'F5'  :    Key := VK_F5;
      'F6'  :    Key := VK_F6;
      'F7'  :    Key := VK_F7;
      'F8'  :    Key := VK_F8;
      'F9'  :    Key := VK_F9;
      'F10' :    Key := VK_F10;
      'PgUp':    Key := 33; //PgUp
      'PgDn':    Key := 34; //PgDn
      else
       Key := 0; // in case of failure. Should not happen...
      end;
    //if dmData.DebugLevel >=1 then Writeln('CW keys button: ',cwkey,' Key: ',Key);
    frmNewQSO.FormKeyDown(nil,Key,[]);
    if (cqrini.ReadInteger('CW','EnterFunction',1)>0) then SetFocus;
  end;

end;

procedure TfraCWKeys.UpdateFKeyLabels;
var n,f:integer;
begin
    if (frmContest.Showing) and ( not (cqrini.ReadBool('CW','S&P',True))) then //if contest and run mode keys are F11-F20
      n:=11
     else
      n:=1;

  btnF1.Caption  := cqrini.ReadString('CW','CapF'+IntToStr(n),'CQ');
  inc(n);
  btnF2.Caption  := cqrini.ReadString('CW','CapF'+IntToStr(n),'F2');
  inc(n);
  btnF3.Caption  := cqrini.ReadString('CW','CapF'+IntToStr(n),'F3');
  inc(n);
  btnF4.Caption  := cqrini.ReadString('CW','CapF'+IntToStr(n),'F4');
  inc(n);
  btnF5.Caption  := cqrini.ReadString('CW','CapF'+IntToStr(n),'F5');
  inc(n);
  btnF6.Caption  := cqrini.ReadString('CW','CapF'+IntToStr(n),'F6');
  inc(n);
  btnF7.Caption  := cqrini.ReadString('CW','CapF'+IntToStr(n),'F7');
  inc(n);
  btnF8.Caption  := cqrini.ReadString('CW','CapF'+IntToStr(n),'F8');
  inc(n);
  btnF9.Caption  := cqrini.ReadString('CW','CapF'+IntToStr(n),'F9');
  inc(n);
  btnF10.Caption  := cqrini.ReadString('CW','CapF'+IntToStr(n),'F10')
end;

end.

