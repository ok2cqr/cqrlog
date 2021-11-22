unit fContest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, LCLType, Buttons, ComCtrls, uMyIni;

type

  { TfrmContest }

  TfrmContest = class(TForm)
    btClearAll: TButton;
    btSave: TButton;
    btClearQso : TButton;
    chkTabAll: TCheckBox;
    chkQsp: TCheckBox;
    chkTrueRST: TCheckBox;
    chkNoNr: TCheckBox;
    chkSpace: TCheckBox;
    chkLoc: TCheckBox;
    chkNRInc: TCheckBox;
    cmbContestName: TComboBox;
    edtCall: TEdit;
    edtRSTs: TEdit;
    edtSTX: TEdit;
    edtSTXStr: TEdit;
    edtRSTr: TEdit;
    edtSRX: TEdit;
    edtSRXStr: TEdit;
    lblSpeed: TLabel;
    lblContestName: TLabel;
    lblCall: TLabel;
    lblRSTs: TLabel;
    lblMSGs: TLabel;
    lblRSTr: TLabel;
    lblNRr: TLabel;
    lblMSGr: TLabel;
    lblNRs: TLabel;
    btnHelp : TSpeedButton;
    rbDupeCheck: TRadioButton;
    rbNoMode4Dupe: TRadioButton;
    rbIgnoreDupes: TRadioButton;
    sbContest: TStatusBar;
    tmrESC2: TTimer;
    procedure btClearAllClick(Sender: TObject);
    procedure btSaveClick(Sender: TObject);
    procedure btClearQsoClick(Sender : TObject);
    procedure chkNoNrChange(Sender: TObject);
    procedure chkNRIncChange(Sender: TObject);
    procedure chkNRIncClick(Sender : TObject);
    procedure chkQspChange(Sender: TObject);
    procedure chkTrueRSTChange(Sender: TObject);
    procedure chkTabAllChange(Sender: TObject);
    procedure edtCallChange(Sender: TObject);
    procedure edtCallExit(Sender: TObject);
    procedure edtCallKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure edtCallKeyPress(Sender: TObject; var Key: char);
    procedure edtSRXStrChange(Sender: TObject);
    procedure edtSRXExit(Sender: TObject);
    procedure edtSTXStrEnter(Sender: TObject);
    procedure edtSTXStrExit(Sender: TObject);
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
    procedure SetTabOrders;
    procedure TabStopAllOn;
    procedure QspMsg;
    procedure ClearStatusBar;
    procedure ShowStatusBarInfo;
    procedure SaveSettings;
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

uses dData, dUtils, fNewQSO, fWorkedGrids, strutils, fscp, fTRXControl;

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
         edtCall.SelStart:=length(edtCall.Text);
         edtCall.SelLength:=0;
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
        dmUtils.GetDescKeyFromCode(Key),edtCall.Text,
      edtRSTs.Text, edtSTX.Text,edtSTXStr.Text,
      frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''));
    key := 0;
  end;

  if (key = 33) then//pgup
  begin
    if Assigned(frmNewQSO.CWint) then
    begin
      speed := frmNewQSO.CWint.GetSpeed + 2;
      frmNewQSO.CWint.SetSpeed(speed);
      frmNewQSO.sbNewQSO.Panels[4].Text := IntToStr(speed) + 'WPM';
      lblSpeed.Caption:= frmNewQSO.sbNewQSO.Panels[4].Text;
    end;
    key := 0;
  end;

  if (key = 34) then//pgup
  begin
    if Assigned(frmNewQSO.CWint) then
    begin
      speed := frmNewQSO.CWint.GetSpeed - 2;
      frmNewQSO.CWint.SetSpeed(speed);
      frmNewQSO.sbNewQSO.Panels[4].Text := IntToStr(speed) + 'WPM';
      lblSpeed.Caption:= frmNewQSO.sbNewQSO.Panels[4].Text;
    end;
    key := 0;
  end;

  if ((Shift = [ssCtrl]) and (key = VK_A)) then
  begin
    frmNewQSO.acAddToBandMap.Execute;
    key := 0
  end;

  //split keys
   if (Shift = [ssCTRL]) then
    if key in [VK_1..VK_9] then frmNewQSO.SetSplit(chr(key));
  if ((Shift = [ssCTRL]) and (key = VK_0)) then
    frmTRXControl.DisableSplit;
end;


procedure TfrmContest.edtCallExit(Sender: TObject);
var
  dupe : Integer;
begin
  // if frmNewQSO is in viewmode or editmode it overwrites old data or will not save
  // because saving is disabled in view mode. this if statement starts a fresh newqso form
  if frmNewQSO.ViewQSO or frmNewQSO.EditQSO then
  begin
    frmNewQSO.Caption := dmUtils.GetNewQSOCaption('New QSO');
    frmNewQSO.UnsetEditLabel;
    frmNewQSO.BringToFront;
    frmNewQSO.ClearAll;
    edtCallExit(nil);
  end;

  frmNewQSO.edtCall.Text := edtCall.Text;

  if not (rbIgnoreDupes.Checked) then
  begin
    //dupe check
    dupe := frmWorkedGrids.WkdCall(edtCall.Text, dmUtils.GetBandFromFreq(frmNewQSO.cmbFreq.Text) ,frmNewQSO.cmbMode.Text);
    // 1= wkd this band and mode
    // 2= wkd this band but NOT this mode
    if  ( (rbNoMode4Dupe.Checked) and (dupe = 1) )
     or ( (not rbNoMode4Dupe.Checked) and ((dupe = 1) or (dupe=2)) )then
       Begin
         edtCall.Font.Color:=clRed;
         edtCall.Font.Style:= [fsBold];
         frmNewQSO.edtRemQSO.Caption:='Dupe';
       end
    else
        Begin
         edtCall.Font.Color:=clDefault;
         edtCall.Font.Style:= [];
         frmNewQSO.edtRemQSO.Caption:='';
        end;
   end;
  //report in NEwQSO changes to 59 to late (after passing cmbMode)
  //NOTE! if mode is not in list program dies! In that case skip next
  if frmNewQSO.cmbMode.ItemIndex >=0 then
   begin
     case frmNewQSO.cmbMode.Items[frmNewQSO.cmbMode.ItemIndex] of
       'SSB',
       'AM',
       'FM' :
         begin
           edtRSTs.Text := copy(edtRSTs.Text,0,2);
           edtRSTr.Text := copy(edtRSTr.Text,0,2);
         end;
     end;
   end;

  frmNewQSO.edtHisRST.Text := edtRSTs.Text;
  frmNewQSO.edtContestSerialSent.Text := edtSTX.Text;
  frmNewQSO.edtContestExchangeMessageSent.Text := edtSTXStr.Text;
  //so that CW macros work
  frmNewQSO.edtCallExit(nil);
  frmContest.ShowOnTop;
  frmContest.SetFocus;

  ShowStatusBarInfo();
end;

procedure TfrmContest.btSaveClick(Sender: TObject);
begin
  if chkLoc.Checked then
    frmNewQSO.edtGrid.Text := edtSRXStr.Text;

  frmNewQSO.edtHisRST.Text := edtRSTs.Text;
  frmNewQSO.edtMyRST.Text := edtRSTr.Text;
  frmNewQSO.edtContestSerialReceived.Text := edtSRX.Text;
  frmNewQSO.edtContestSerialSent.Text := edtSTX.Text;
  frmNewQSO.edtContestExchangeMessageReceived.Text := edtSRXStr.Text;
  frmNewQSO.edtContestExchangeMessageSent.Text := edtSTXStr.Text;
  frmNewQSO.edtContestName.Text := ExtractWord(1,cmbContestName.Text,['|']);

  frmNewQSO.btnSave.Click;
  if dmData.DebugLevel >= 1 then
    Writeln('input finale');
  ChkSerialNrUpd(chkNRInc.Checked);
  initInput;
  SaveSettings;   //we have to do this here,
                  //otherwise saved serial number fails if cqrlog is closed without first closing contest form
end;

procedure TfrmContest.btClearAllClick(Sender: TObject);
begin
  rbDupeCheck.Checked := True;
  rbNoMode4Dupe.Checked := False;
  rbIgnoreDupes.Checked := False;

  chkSpace.Checked :=  False;
  chkTrueRST.Checked := False;
  chkNRInc.Checked := False;
  chkQsp.Checked := False;
  chkNoNr.Checked := False;
  chkLoc.Checked := False;

  edtSTX.Text := '';
  edtSTXStr.Text := '';
  cmbContestName.Text:= '';
end;

procedure TfrmContest.btClearQsoClick(Sender : TObject);
begin
  frmNewQSO.ClearAll;
  initInput
end;

procedure TfrmContest.chkNoNrChange(Sender: TObject);
Begin
  SetTabOrders;
end;

procedure TfrmContest.chkNRIncChange(Sender: TObject);
begin
  SetTabOrders;
end;

procedure TfrmContest.chkNRIncClick(Sender : TObject);
begin
  if chkNRInc.Checked and (edtSTX.Text = '') then
  begin
    edtSTX.Text := '001';
    edtCall.SetFocus
  end
end;

procedure TfrmContest.chkQspChange(Sender: TObject);
begin
  SetTabOrders;
end;

procedure TfrmContest.chkTrueRSTChange(Sender: TObject);
begin
  SetTabOrders;
end;

procedure TfrmContest.chkTabAllChange(Sender: TObject);
begin
  SetTabOrders;
end;

procedure TfrmContest.edtCallChange(Sender: TObject);
begin
  if frmSCP.Showing and (Length(edtCall.Text)>2) then
    frmSCP.mSCP.Text := dmData.GetSCPCalls(edtCall.Text)
  else
    frmSCP.mSCP.Clear
end;

procedure TfrmContest.edtCallKeyDown(Sender: TObject; var Key: word;
  Shift: TShiftState);
begin
  if ((Key = VK_SPACE) and (chkSpace.Checked)) then
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

procedure TfrmContest.edtSRXStrChange(Sender: TObject);
begin
  if chkLoc.Checked then
  begin
   edtSRXStr.Text := dmUtils.StdFormatLocator(edtSRXStr.Text);
   edtSRXStr.SelStart := Length(edtSRXStr.Text);
  end;
end;
procedure TfrmContest.edtSRXExit(Sender: TObject);
begin
  ChkSerialNrUpd(False); //just save it
end;

procedure TfrmContest.edtSTXStrEnter(Sender: TObject);
begin
  if chkQsp.Checked then
   QspMsg;
end;

procedure TfrmContest.edtSTXStrExit(Sender: TObject);
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
  dmUtils.InsertContests(cmbContestName);
end;
procedure TfrmContest.SaveSettings;
begin
  dmUtils.SaveWindowPos(frmContest);

  cqrini.WriteBool('frmContest', 'DupeCheck', rbDupeCheck.Checked);
  cqrini.WriteBool('frmContest', 'NoMode4Dupe', rbNoMode4Dupe.Checked);
  cqrini.WriteBool('frmContest', 'IgnoreDupes', rbIgnoreDupes.Checked);

  cqrini.WriteBool('frmContest', 'SpaceIsTab', chkSpace.Checked);
  cqrini.WriteBool('frmContest', 'TrueRST', chkTrueRST.Checked);
  cqrini.WriteBool('frmContest', 'NRInc', chkNRInc.Checked);
  cqrini.WriteBool('frmContest', 'QSP', chkQsp.Checked);
  cqrini.WriteBool('frmContest', 'NoNR', chkNoNr.Checked);
  cqrini.WriteBool('frmContest', 'Loc', chkLoc.Checked);

  cqrini.WriteString('frmContest', 'STX', edtSTX.Text);
  cqrini.WriteString('frmContest', 'STXStr', edtSTXStr.Text);
  cqrini.WriteString('frmContest', 'ContestName', cmbContestName.Text);
end;
procedure TfrmContest.FormClose(Sender: TObject; var CloseAction: TCloseAction);
Begin
  SaveSettings;
end;

procedure TfrmContest.FormHide(Sender: TObject);
begin
  frmNewQSO.gbContest.Visible := false;
  dmUtils.SaveWindowPos(frmContest);
  frmContest.Hide;
end;

procedure TfrmContest.FormShow(Sender: TObject);
begin
  frmNewQSO.gbContest.Visible := true;
  dmUtils.LoadWindowPos(frmContest);

  rbDupeCheck.Checked := cqrini.ReadBool('frmContest', 'DupeCheck', True);
  rbNoMode4Dupe.Checked := cqrini.ReadBool('frmContest', 'NoMode4Dupe', False);
  rbIgnoreDupes.Checked := cqrini.ReadBool('frmContest', 'IgnoreDupes', False);

  chkSpace.Checked := cqrini.ReadBool('frmContest', 'SpaceIsTab', False);
  chkTrueRST.Checked := cqrini.ReadBool('frmContest', 'TrueRST', False);
  chkNRInc.Checked := cqrini.ReadBool('frmContest', 'NRInc', False);
  chkQsp.Checked := cqrini.ReadBool('frmContest', 'QSP', False);
  chkNoNr.Checked := cqrini.ReadBool('frmContest', 'NoNR', False);
  chkLoc.Checked := cqrini.ReadBool('frmContest', 'Loc', False);

  edtSTX.Text := cqrini.ReadString('frmContest', 'STX', '');
  edtSTXStr.Text := cqrini.ReadString('frmContest', 'STXStr', '');

  InitInput;

  sbContest.Panels[0].Width := 450;
  sbContest.Panels[1].Width := 65;
  sbContest.Panels[2].Width := 65;
  sbContest.Panels[3].Width := 65;
  sbContest.Panels[4].Width := 20;
  lblSpeed.Caption:= frmNewQSO.sbNewQSO.Panels[4].Text;
  cmbContestName.Text := cqrini.ReadString('frmContest', 'ContestName','');
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

  edtSTXStr.Text := RSTstxAdd;
  edtSRX.Text := '';
  edtSRXStr.Text := '';
  edtCall.Font.Color:=clDefault;
  edtCall.Font.Style:= [];
  edtCall.Clear;
  EscFirstTime := True;

  SetTabOrders;
  frmContest.ShowOnTop;
  frmContest.SetFocus;
  edtCall.SetFocus;

  ClearStatusBar;
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
    if chkNRInc.Checked then //inc of number requested
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
  RSTstxAdd := edtSTXStr.Text;

  if dmData.DebugLevel >= 1 then
    Writeln(' Inc number is: ', IncNr);
end;
procedure  TfrmContest.SetTabOrders;
begin
  TabStopAllOn;
  if not chkTabAll.Checked then
    begin
      //NRs no need to touch
      edtSTX.TabStop      := False;
      //"Qsp" adds MSGs, else drops
      edtSTXStr.TabStop:= chkQsp.Checked;
      //"No" drops NRr
      edtSRX.TabStop   := not chkNoNr.Checked;
      //"Tru" checked adds RST fields, else drops
      edtRSTs.TabStop  := chkTrueRST.Checked;
      edtRSTr.TabStop  := chkTrueRST.Checked;
    end;
end;

procedure  TfrmContest.TabStopAllOn;
//set all tabstops
Begin
    edtCall.TabStop     := True;
    edtCall.TabOrder    := 0;
    edtRSTs.TabStop     := True;
    edtRSTs.TabOrder    := 1;
    edtSTX.TabStop      := True;
    edtSTX.TabOrder     := 2;
    edtSTXStr.TabStop   := True;
    edtSTXStr.TabOrder  := 3;

    edtRSTr.TabStop     := True;
    edtRSTr.TabOrder    := 4;
    edtSRX.TabStop      := True;
    edtSRX.TabOrder     := 5;
    edtSRXStr.TabStop   := True;
    edtSRXStr.TabOrder  := 6;

    btSave.TabStop      := True;
    btSave.TabOrder     := 7;
    btClearQso.TabStop  := True;
    btClearQso.TabOrder := 8;

    rbDupeCheck.TabStop:=false;
    rbNoMode4Dupe.TabStop:=false;
    rbIgnoreDupes.TabStop:=false;
    btClearAll.TabStop:=false;
    chkTabAll.TabStop:=false;
    cmbContestName.TabStop:=false;
end;
procedure TfrmContest.QspMsg;
Begin
   try
    dmData.Q.Close;
    if dmData.trQ.Active then dmData.trQ.Rollback;
    dmData.Q.SQL.Text := 'SELECT srx_string FROM cqrlog_main ORDER BY qsodate DESC, time_on DESC LIMIT 1';
    dmData.trQ.StartTransaction;
    if dmData.DebugLevel >=1 then
      Writeln(dmData.Q.SQL.Text);
    dmData.Q.Open();
    edtSTXStr.Text := dmData.Q.Fields[0].AsString;
    dmData.Q.Close();
    dmData.trQ.Rollback;
   finally
     edtSTXStr.SetFocus;
     edtSTXStr.SelStart:=length(edtSTXStr.Text);
     edtSTXStr.SelLength:=0;
   end;
end;

procedure TfrmContest.ClearStatusBar;
var
  i : Integer;
begin
  for i:=0 to sbContest.Panels.Count-1 do
    sbContest.Panels.Items[i].Text := '';
end;

procedure TfrmContest.ShowStatusBarInfo;
begin
  sbContest.Panels.Items[0].Text := StringReplace(Trim(frmNewQSO.mCountry.Text),#$0A,'|',[rfReplaceAll]);
  sbContest.Panels.Items[1].Text := 'WAZ: ' + frmNewQSO.lblWAZ.Caption;
  sbContest.Panels.Items[2].Text := 'ITU: ' + frmNewQSO.lblITU.Caption;
  sbContest.Panels.Items[3].Text := 'AZ: ' + frmNewQSO.lblAzi.Caption;
  sbContest.Panels.Items[4].Text := frmNewQSO.lblCont.Caption;
end;

initialization


end.
