unit fCWType;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Spin, inifiles, lcltype,ActnList,frCWKeys, Types;

type

  { TfrmCWType }

  TfrmCWType = class(TForm)
    btnClose: TButton;
    btnClear: TButton;
    edtSpeed: TSpinEdit;
    fraCWKeys1: TfraCWKeys;
    lblSpeed: TLabel;
    lblToShowMouseOverText: TLabel;
    lblWpm: TLabel;
    m: TMemo;
    pnlBottom: TPanel;
    pnlTop: TPanel;
    rgMode: TRadioGroup;
    procedure btnF10Click(Sender: TObject);
    procedure btnF10MouseEnter(Sender: TObject);
    procedure btnF10MouseLeave(Sender: TObject);
    procedure btnF1Click(Sender: TObject);
    procedure btnF1MouseEnter(Sender: TObject);
    procedure btnF1MouseLeave(Sender: TObject);
    procedure btnF2Click(Sender: TObject);
    procedure btnF2MouseEnter(Sender: TObject);
    procedure btnF2MouseLeave(Sender: TObject);
    procedure btnF3Click(Sender: TObject);
    procedure btnF3MouseEnter(Sender: TObject);
    procedure btnF3MouseLeave(Sender: TObject);
    procedure btnF4Click(Sender: TObject);
    procedure btnF4MouseEnter(Sender: TObject);
    procedure btnF4MouseLeave(Sender: TObject);
    procedure btnF5Click(Sender: TObject);
    procedure btnF5MouseEnter(Sender: TObject);
    procedure btnF5MouseLeave(Sender: TObject);
    procedure btnF6Click(Sender: TObject);
    procedure btnF6MouseEnter(Sender: TObject);
    procedure btnF6MouseLeave(Sender: TObject);
    procedure btnF7Click(Sender: TObject);
    procedure btnF7MouseEnter(Sender: TObject);
    procedure btnF7MouseLeave(Sender: TObject);
    procedure btnF8Click(Sender: TObject);
    procedure btnF8MouseEnter(Sender: TObject);
    procedure btnF8MouseLeave(Sender: TObject);
    procedure btnF9Click(Sender: TObject);
    procedure btnF9MouseEnter(Sender: TObject);
    procedure btnF9MouseLeave(Sender: TObject);
    procedure btnPgDnClick(Sender: TObject);
    procedure btnPgDnMouseEnter(Sender: TObject);
    procedure btnPgDnMouseLeave(Sender: TObject);
    procedure btnPgUpClick(Sender: TObject);
    procedure btnPgUpMouseEnter(Sender: TObject);
    procedure btnPgUpMouseLeave(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure edtSpeedChange(Sender: TObject);
    procedure fraCWKeys1Resize(Sender: TObject);
    procedure mChange(Sender: TObject);
    procedure mKeyPress(Sender: TObject; var Key: char);
    procedure mKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure rgModeClick(Sender: TObject);
  private
    { private declarations }
    LocalDbg : boolean; // bit 4, %01000, -8 for cw routines including this form
    Switch2Word   : boolean;
    WasMemoLen : integer;
    function PassedKey(key:char):boolean;
    procedure blocksend;
    procedure SetSpeed(change:integer);
  public
    { public declarations }
  end; 

var
  frmCWType: TfrmCWType;

implementation
{$R *.lfm}

{ TfrmCWType }
uses fNewQSO,dUtils,dData, uMyIni;

function TfrmCWType.PassedKey(key:char):boolean;
Begin
   PassedKey := (
     (key in ['A'..'Z']) or (key in ['0'..'9']) or (key = '=') or
     (key = '?') or (key = ',') or (key='.') or (key='/') or (key = ' ') or
     (key = '<') or (key = '>') or (key = ':') or (key = ')') or (key = '(') or
     (key = ';') or (key = '@') or (key = 'ß') or (key ='Ü') or (key ='Ö') or
     (key = 'Ä') or (key ='^')
     );
end;

procedure TfrmCWType.btnClearClick(Sender: TObject);
begin
  m.Clear;
  WasMemoLen := length(m.lines.text);
  Switch2Word := false;
  m.SetFocus;
end;

procedure TfrmCWType.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = 27 then
    frmNewQSO.CWint.StopSending
end;

procedure TfrmCWType.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  cqrini.WriteInteger('CW','Mode',rgMode.ItemIndex);
  dmUtils.SaveWindowPos(frmCWType)
end;

procedure TfrmCWType.btnF1MouseEnter(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:=dmUtils.GetCWMessage('F1',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfrmCWType.btnF1MouseLeave(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:='';
end;

procedure TfrmCWType.btnF2Click(Sender: TObject);
begin
  frmNewQSO.CWint.SendText(dmUtils.GetCWMessage('F2',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''));
end;

procedure TfrmCWType.btnF10MouseEnter(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:=dmUtils.GetCWMessage('F10',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfrmCWType.btnF10Click(Sender: TObject);
begin
  frmNewQSO.CWint.SendText(dmUtils.GetCWMessage('F10',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''));
end;

procedure TfrmCWType.btnF10MouseLeave(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:='';
end;

procedure TfrmCWType.btnF1Click(Sender: TObject);
begin
  frmNewQSO.CWint.SendText(dmUtils.GetCWMessage('F1',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''));
end;

procedure TfrmCWType.btnF2MouseEnter(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:=dmUtils.GetCWMessage('F2',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfrmCWType.btnF2MouseLeave(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:='';
end;

procedure TfrmCWType.btnF3Click(Sender: TObject);
begin
  frmNewQSO.CWint.SendText(dmUtils.GetCWMessage('F3',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''));
end;

procedure TfrmCWType.btnF3MouseEnter(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:=dmUtils.GetCWMessage('F3',frmNewQSO.edtCall.Text,
       frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfrmCWType.btnF3MouseLeave(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:='';
end;

procedure TfrmCWType.btnF4Click(Sender: TObject);
begin
  frmNewQSO.CWint.SendText(dmUtils.GetCWMessage('F4',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''));
end;

procedure TfrmCWType.btnF4MouseEnter(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:=dmUtils.GetCWMessage('F4',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfrmCWType.btnF4MouseLeave(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:='';
end;

procedure TfrmCWType.btnF5Click(Sender: TObject);
begin
  frmNewQSO.CWint.SendText(dmUtils.GetCWMessage('F5',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''));
end;

procedure TfrmCWType.btnF5MouseEnter(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:=dmUtils.GetCWMessage('F5',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfrmCWType.btnF5MouseLeave(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:='';
end;

procedure TfrmCWType.btnF6Click(Sender: TObject);
begin
  frmNewQSO.CWint.SendText(dmUtils.GetCWMessage('F6',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''));
end;

procedure TfrmCWType.btnF6MouseEnter(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:=dmUtils.GetCWMessage('F6',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfrmCWType.btnF6MouseLeave(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:='';
end;

procedure TfrmCWType.btnF7Click(Sender: TObject);
begin
  frmNewQSO.CWint.SendText(dmUtils.GetCWMessage('F7',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''));
end;

procedure TfrmCWType.btnF7MouseEnter(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:=dmUtils.GetCWMessage('F7',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfrmCWType.btnF7MouseLeave(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:='';
end;

procedure TfrmCWType.btnF8Click(Sender: TObject);
begin
  frmNewQSO.CWint.SendText(dmUtils.GetCWMessage('F8',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''));
end;

procedure TfrmCWType.btnF8MouseEnter(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:=dmUtils.GetCWMessage('F8',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfrmCWType.btnF8MouseLeave(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:='';
end;

procedure TfrmCWType.btnF9Click(Sender: TObject);
begin
  frmNewQSO.CWint.SendText(dmUtils.GetCWMessage('F9',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''));
end;

procedure TfrmCWType.btnF9MouseEnter(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:=dmUtils.GetCWMessage('F9',frmNewQSO.edtCall.Text,
      frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,'');
end;

procedure TfrmCWType.btnF9MouseLeave(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:='';
end;

procedure TfrmCWType.btnPgDnClick(Sender: TObject);
begin
  SetSpeed(-2);
end;

procedure TfrmCWType.btnPgDnMouseEnter(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:='cw keyspeed -2 wpm';
end;

procedure TfrmCWType.btnPgDnMouseLeave(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:='';
end;

procedure TfrmCWType.btnPgUpClick(Sender: TObject);
begin
  SetSpeed(2);
end;

procedure TfrmCWType.btnPgUpMouseEnter(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:='cw keyspeed +2 wpm';
end;

procedure TfrmCWType.btnPgUpMouseLeave(Sender: TObject);
begin
  frmCWType.lblToShowMouseOverText.Caption:='';
end;


procedure TfrmCWType.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmCWType);
  rgMode.ItemIndex := cqrini.ReadInteger('CW','Mode',1);
  fraCWKeys1.UpdateFKeyLabels;
  m.SetFocus;
  m.Clear;
  Switch2Word :=false;
  WasMemoLen := length(m.lines.text);
   //set debug rules for this form
  LocalDbg := dmData.DebugLevel >= 1 ;
  if dmData.DebugLevel < 0 then
        LocalDbg :=  LocalDbg or ((abs(dmData.DebugLevel) and 8) = 8 );
end;

procedure TfrmCWType.btnCloseClick(Sender: TObject);
begin
  Close
end;

procedure TfrmCWType.edtSpeedChange(Sender: TObject);
begin
  frmNewQSO.CWint.SetSpeed(edtSpeed.Value);
  frmNewQSO.sbNewQSO.Panels[2].Text := IntToStr(edtSpeed.Value)+'WPM';

end;
procedure TfrmCWType.fraCWKeys1Resize(Sender: TObject);
 var
  w, h, l, t: word;
  i: integer;
  c: word;
begin
  with fraCWKeys1 do
  Begin
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
     end
   end
  end;
end;

procedure TfrmCWType.blocksend;
var
  msg :string ;
  l   : char;
  i   : integer;
Begin
  if LocalDbg then Writeln();
  if LocalDbg then Writeln('In blocksend-Len:',  length(m.lines.text),' Was:',WasMemoLen);
   msg := '';
   for i:= WasMemoLen+1 to length(m.lines.text) do
     begin
         l := Upcase( m.Lines.Text[i]);
         if (l = #$0A) then l := ' '; //convert newline to space before send
         if PassedKey(l) then  msg := msg + l;
     end;
   if msg<>'' then
    Begin
     if LocalDbg then Writeln('Blocksend out:'+msg);
     frmNewQSO.CWint.SendText(msg);
    end;
   WasMemoLen :=length(m.lines.text);
end;

procedure TfrmCWType.mChange(Sender: TObject);
var
  l   : char ;

begin
  if  ((length(m.lines.text)-WasMemoLen) < 1 ) then
        Begin
         if LocalDbg then Writeln('Change without lenght grow. DEL?');
         if LocalDbg then Writeln('Len:',  length(m.lines.text),' Was:',WasMemoLen);
         WasMemoLen :=length(m.lines.text);
        end
  else
  Begin
  if LocalDbg then Writeln('Len:',  length(m.lines.text),' Was:',WasMemoLen);
  if ( ((length(m.lines.text)-WasMemoLen) > 1 )
       and not(Switch2Word)
       and not(rgMode.ItemIndex=2)
     ) then
     Begin
       if LocalDbg then Writeln('Pasted text, more than 1chr at same go');
       blocksend;
     end
    else  //only 1 char added
     Begin
        l := Upcase( m.Lines.Text[length(m.lines.text)]);
         if PassedKey(l) then
           begin
            if LocalDbg then Write(ord(l),'_');
            case rgMode.ItemIndex of

                 0:               Begin
                                       frmNewQSO.CWint.SendText(l); //letter mode
                                       WasMemoLen :=length(m.lines.text);
                                  end;
                 1:               Begin  //word mode , first word is send character by character
                                   if (not Switch2Word) and (l = ' ') then
                                         Begin
                                            if LocalDbg then Writeln(' 1st word passed');
                                            Switch2Word := true;
                                         end;
                                   if Switch2Word then
                                      Begin
                                       if (l = ' ') then blocksend;
                                      end
                                    else
                                      Begin
                                      frmNewQSO.CWint.SendText(l);
                                      WasMemoLen :=length(m.lines.text);
                                      end;
                                  end;

                 2:               if (l = ' ') then blocksend; //word mode

              end; //case
           end;  //valid key
     end; //only 1 char added
 end;
  l:=#0;
end;

procedure TfrmCWType.mKeyPress(Sender: TObject; var Key: char);
begin
  if key  = #$0D then
   Begin
    blocksend;
    Switch2Word := false;
   end;
end;

procedure TfrmCWType.mKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);

begin
  if key = 33 then//pgup
  begin
    SetSpeed(2);
    key := 0
  end;

  if key = 34 then//pgup
  begin
    SetSpeed(-2);
    key := 0
  end;

  if (key >= VK_F1) and (key <= VK_F10) then
  begin
    frmNewQSO.CWint.SendText(dmUtils.GetCWMessage(dmUtils.GetDescKeyFromCode(key),frmNewQSO.edtCall.Text,
       frmNewQSO.edtHisRST.Text, frmNewQSO.edtContestSerialSent.Text,frmNewQSO.edtContestExchangeMessageSent.Text,
       frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''));
  end;

  if Key = VK_ESCAPE then
    frmNewQSO.CWint.StopSending
end;

procedure TfrmCWType.rgModeClick(Sender: TObject);
begin
  m.SetFocus; //after mode change focus back to memo
end;

procedure TfrmCWType.SetSpeed(change:integer);
var
  speed : Integer = 0;
Begin
    speed := frmNewQSO.CWint.GetSpeed+change;
    frmNewQSO.CWint.SetSpeed(speed);
    frmNewQSO.sbNewQSO.Panels[2].Text := IntToStr(speed)+'WPM';
    edtSpeed.Value := speed;
end;

end.

