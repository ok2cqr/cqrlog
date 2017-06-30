unit fContest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, LCLType, Buttons;

type

  { TfrmContest }

  TfrmContest = class(TForm)
    btSave: TButton;
    Button1 : TButton;
    chTrueRST: TCheckBox;
    chNoNr: TCheckBox;
    chSpace: TCheckBox;
    chLoc: TCheckBox;
    chNRInc: TCheckBox;
    edtCall: TEdit;
    edtRSTs: TEdit;
    edtSTX: TEdit;
    edtSTX2: TEdit;
    edtRSTr: TEdit;
    edtSRX: TEdit;
    edtSRX2: TEdit;
    lblCall: TLabel;
    lblRSTs: TLabel;
    lblMSGs: TLabel;
    lblRSTr: TLabel;
    lblNRr: TLabel;
    lblMSGr: TLabel;
    lblNRs: TLabel;
    btnHelp : TSpeedButton;
    tmrESC2: TTimer;
    procedure btSaveClick(Sender: TObject);
    procedure Button1Click(Sender : TObject);
    procedure chNoNrChange(Sender: TObject);
    procedure chNRIncClick(Sender : TObject);
    procedure chTrueRSTChange(Sender: TObject);
    procedure edtCallExit(Sender: TObject);
    procedure edtCallKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure edtCallKeyPress(Sender: TObject; var Key: char);
    procedure edtSRXExit(Sender: TObject);
    procedure edtSTX2Exit(Sender: TObject);
    procedure edtSTXExit(Sender: TObject);
    procedure edtSTXKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure btnHelpClick(Sender : TObject);
    procedure tmrESC2Timer(Sender: TObject);
  private
    { private declarations }
    procedure InitInput;
    procedure ChkSerialNrUpd(IncNr: boolean);
  public
    { public declarations }
  end;

var
  frmContest: TfrmContest;
  RSTstx: string = ''; //contest mode serial numbers store
  RSTstxAdd: string = ''; //contest mode additional string store
  //RSTsrx         :string = '';
  EscFirstTime: boolean = False;

implementation

{$R *.lfm}

uses dData, dUtils, fNewQSO;

procedure TfrmContest.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
var
  tmp: string;
  speed: integer = 0;
  i: integer = 0;

begin
  // enter anywhere
  if key = VK_RETURN then
  begin
    if (length(edtCall.Text) > 2) then   //must be some kind of call
      btSave.Click;
    key := 0;
  end;

  //esc and double esc
  if key = VK_ESCAPE then
  begin
    if EscFirstTime then
    begin
      //if edtCall.Text = '' then
         frmNewQSO.old_call:='';             //this is stupid hack but only way to reproduce
         frmNewQSO.edtName.Text :='';        //new seek from log (important to see if wkd before,
         frmNewQSO.edtQth.Text  :='';        //and qrz, if one wants)
         frmNewQSO.edtGrid.Text :='';        //otherwise we do not get cursor at the end of call
         edtCall.SetFocus;
      //else
      if Assigned(frmNewQSO.CWint) then
        frmNewQSO.CWint.StopSending;
      EscFirstTime := False;
      tmrESC2.Enabled := True;
    end
    else begin   // esc second time
      frmNewQSO.ClearAll;
      if dmData.DebugLevel >= 1 then
         writeln('Clear all done next focus');
      initInput;
      tmrESC2Timer(nil);
    end;
    key := 0;
  end;

  //cw memories
  if (Key >= VK_F1) and (Key <= VK_F10) and (Shift = []) then
  begin
    if (frmNewQSO.cmbMode.Text = 'SSB') then
      frmNewQSO.RunVK(dmUtils.GetDescKeyFromCode(Key))
    else
    if Assigned(frmNewQSO.CWint) then
      frmNewQSO.CWint.SendText(dmUtils.GetCWMessage(
        dmUtils.GetDescKeyFromCode(Key), frmNewQSO.edtCall.Text, frmNewQSO.edtHisRST.Text,
        frmNewQSO.edtName.Text, frmNewQSO.lblGreeting.Caption, ''));
    key := 0;
  end;

  if (key = 33) then//pgup
  begin
    if Assigned(frmNewQSO.CWint) then
    begin
      speed := frmNewQSO.CWint.GetSpeed + 2;
      frmNewQSO.CWint.SetSpeed(speed);
      frmNewQSO.sbNewQSO.Panels[2].Text := IntToStr(speed) + 'WPM';
    end;
    key := 0;
  end;

  if (key = 34) then//pgup
  begin
    if Assigned(frmNewQSO.CWint) then
    begin
      speed := frmNewQSO.CWint.GetSpeed - 2;
      frmNewQSO.CWint.SetSpeed(speed);
      frmNewQSO.sbNewQSO.Panels[2].Text := IntToStr(speed) + 'WPM';
    end;
    key := 0;
  end;

end;


procedure TfrmContest.edtCallExit(Sender: TObject);
begin
  frmNewQSO.edtCall.Text := edtCall.Text;

  case frmNewQSO.cmbMode.Items[frmNewQSO.cmbMode.ItemIndex] of            //report in NEwQSO changes to 59 to late (after passing cmbMode)
  'SSB','AM','FM' : Begin
                         edtRSTs.Text := copy(edtRSTs.Text,0,2);
                         edtRSTr.Text := copy(edtRSTr.Text,0,2);
                    end;
  end;

  frmNewQSO.edtHisRST.Text := edtRSTs.Text + ' ' + edtSTX.Text + ' ' + edtSTX2.Text;
  //so that CW macros work
  frmNewQSO.edtCallExit(nil);
  frmContest.ShowOnTop;
  frmContest.SetFocus;
end;

procedure TfrmContest.btSaveClick(Sender: TObject);
begin
  frmNewQSO.edtHisRST.Text := edtRSTs.Text + ' ' + edtSTX.Text + ' ' + edtSTX2.Text;
  //this should be ok before
  if chLoc.Checked then
  begin
    frmNewQSO.edtMyRST.Text := edtRSTr.Text + ' ' + edtSRX.Text;
    frmNewQSO.edtGrid.Text := edtSRX2.Text;
  end
  else
    frmNewQSO.edtMyRST.Text := edtRSTr.Text + ' ' + edtSRX.Text + ' ' + edtSRX2.Text;

  frmNewQSO.btnSave.Click;
  if dmData.DebugLevel >= 1 then
                       writeln('input finale');
  ChkSerialNrUpd(chNRInc.Checked);
  initInput;
end;

procedure TfrmContest.Button1Click(Sender : TObject);
begin
  frmNewQSO.ClearAll;
  initInput
end;

procedure TfrmContest.chNoNrChange(Sender: TObject);
var
  n, m, s, c: integer;

  procedure swapTab;
  begin //swap
    c := n;
    n := m;
    m := c;
    if (m < n) and (s > n) then    //must change n and s
    begin
      c := n;
      n := s;
      s := c;
    end;
    if (n < m) and (s < m) then    //must change m and s
    begin
      c := m;
      m := s;
      s := c;
    end
  end;
begin
  n := edtSRX.TabOrder;
  m := edtSRX2.TabOrder;
  s := btSave.TabOrder;

  if (chNoNr.Checked) and (n < m) then          //msg always gets smaller tab order
    swapTab;

  if (not chNoNr.Checked) and (m < n) then  //msg always gets higher tab order
    swapTab;
  edtSRX.TabOrder := n;
  edtSRX2.TabOrder := m;
  btSave.TabOrder := s
end;

procedure TfrmContest.chNRIncClick(Sender : TObject);
begin
  if chNRInc.Checked and (edtSTX.Text = '') then
  begin
    edtSTX.Text := '001';
    edtCall.SetFocus
  end
end;

procedure TfrmContest.chTrueRSTChange(Sender: TObject);
begin
  if chTrueRST.Checked then
  begin                   //true RST order
    edtRSTs.TabOrder := 1;
    edtRSTr.TabOrder := 2;
    edtSRX.TabOrder := 3;
    edtSRX2.TabOrder := 4;
    btSave.TabOrder := 5;
  end
  else begin                     //contest order
    edtSRX.TabOrder := 1;
    edtSRX2.TabOrder := 2;
    btSave.TabOrder := 3;
    edtRSTr.TabOrder := 4;
    edtRSTs.TabOrder := 5;
  end;
  frmContest.chNoNrChange(nil); //finally check Nr/MSG order
end;

procedure TfrmContest.edtCallKeyDown(Sender: TObject; var Key: word;
  Shift: TShiftState);
begin
  if ((Key = VK_SPACE) and (chSpace.Checked)) then
  begin
    Key := 0;
    SelectNext(Sender as TWinControl, True, True);
  end;
end;

procedure TfrmContest.edtCallKeyPress(Sender: TObject; var Key: char);
begin
  if not (key in ['a'..'z', 'A'..'Z', '0'..'9',
    '/', chr(VK_DELETE), chr(VK_BACK), chr(VK_RIGHT), chr(VK_LEFT)]) then
    key := #0;
end;

procedure TfrmContest.edtSRXExit(Sender: TObject);
begin
  ChkSerialNrUpd(False); //just save it
end;

procedure TfrmContest.edtSTX2Exit(Sender: TObject);
begin
  ChkSerialNrUpd(False); //just save it
end;

procedure TfrmContest.edtSTXExit(Sender: TObject);
begin
  ChkSerialNrUpd(False); //just save it
end;

procedure TfrmContest.edtSTXKeyPress(Sender: TObject; var Key: char);
begin
  if not (key in ['0'..'9', chr(VK_SPACE), chr(VK_DELETE), chr(VK_BACK),
    chr(VK_RIGHT), chr(VK_LEFT)]) then
    key := #0;
end;

procedure TfrmContest.FormCreate(Sender: TObject);
begin
  frmContest.KeyPreview := True;
end;

procedure TfrmContest.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmContest);

end;

procedure TfrmContest.FormHide(Sender: TObject);
begin
  dmUtils.SaveWindowPos(frmContest);
  frmContest.Hide;
end;

procedure TfrmContest.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmContest);
  InitInput;
end;

procedure TfrmContest.btnHelpClick(Sender : TObject);
begin
  ShowHelp
end;

procedure TfrmContest.tmrESC2Timer(Sender: TObject);
begin
  EscFirstTime := True; //time for double esc passed
  tmrESC2.Enabled := False;
end;

procedure TfrmContest.InitInput;

begin
  edtRSTs.Text := trim(copy(frmNewQSO.edtHisRST.Text, 0, 3));
  //just pick  '599' or '59 '  if there happens to be more
  edtRSTr.Text := trim(copy(frmNewQSO.edtMyRST.Text, 0, 3));

  if not ((edtSTX.Text <> '') and (RSTstx = ''))  then
    edtSTX.Text := RSTstx;

  edtSTX2.Text := RSTstxAdd;
  edtSRX.Text := '';
  edtSRX2.Text := '';
  edtCall.Clear;
  EscFirstTime := True;
  {
  Next 3 lines of procedure will cause
  ----
  either (dbg msg:input finale):

  NOTE: Window with stalled focus found!, faking focus-out event
  NOTE: Window with stalled focus found!, faking focus-out event
  NOTE: Window with stalled focus found!, faking focus-out event
  (cqrlog:2643): Pango-CRITICAL **: pango_layout_get_cursor_pos: assertion 'index >= 0 && index <= layout->length' failed
  (cqrlog:2643): Pango-CRITICAL **: pango_layout_get_cursor_pos: assertion 'index >= 0 && index <= layout->length' failed
  (cqrlog:2643): Pango-CRITICAL **: pango_layout_get_cursor_pos: assertion 'index >= 0 && index <= layout->length' failed
  (cqrlog:2643): Pango-CRITICAL **: pango_layout_get_cursor_pos: assertion 'index >= 0 && index <= layout->length' failed
  ----
  or(dbg msg: Clear all done next focus ):

  NOTE: Window with stalled focus found!, faking focus-out event
  NOTE: Window with stalled focus found!, faking focus-out event

  ----
  All works, but this needs attention and I can not resolve this at the moment.

  }

  frmContest.ShowOnTop;
  frmContest.SetFocus;
  edtCall.SetFocus;
end;

procedure TfrmContest.ChkSerialNrUpd(IncNr: boolean);   // do we need serial nr inc
var                                                    //otherwise just update memos
  stxLen, stxInt: integer;
  lZero: boolean;
  stx: string;

begin
  stx := trim(edtSTX.Text);

  if IncNr then
  begin
    stxlen := length(stx);
    if chNRInc.Checked then //inc of number requested
    begin
      lZero := stx[1] = '0'; //do we have leading zero(es)
      if dmData.DebugLevel >= 1 then
        Writeln('Need inc number:', stx, ' Has leading zero:', lZero, ' len:', stxlen);
      if TryStrToInt(stx, stxint) then
      begin
        if dmData.DebugLevel >= 1 then
          Writeln('Integer is:', stxInt);
        Inc(stxInt);
        stx := IntToStr(stxInt);
        if dmData.DebugLevel >= 1 then
          Writeln('New number is:', stx);
        if (length(stx) < stxLen) and lZero then //pad with zero(es)
        begin
          //AddChar('0',stx,stxLen); // why does this NOT work???
          while length(stx) < stxlen do
            stx := '0' + stx;
          if dmData.DebugLevel >= 1 then
            Writeln('After leading zero(es) added:', stx);
        end;
      end;
    end;
  end;

  RSTstx := stx;
  RSTstxAdd := edtSTX2.Text;

  if dmData.DebugLevel >= 1 then
    Writeln(' Inc number is: ', IncNr);
end;

initialization

end.
