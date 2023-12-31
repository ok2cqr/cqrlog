(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fTRXControl;

{$mode objfpc}{$H+}


interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, inifiles, process, lcltype, Buttons, Menus, ActnList, dynlibs,
  uRigControl, Types;

type

  { TfrmTRXControl }

  TfrmTRXControl = class(TForm)
    acMem : TActionList;
    acAddModMem : TAction;
    btn10m : TButton;
    btn12m : TButton;
    btn15m : TButton;
    btn160m : TButton;
    btn17m : TButton;
    btn20m : TButton;
    btn2m : TButton;
    btn30m : TButton;
    btn40m : TButton;
    btn6m : TButton;
    btn70cm : TButton;
    btn80m : TButton;
    btnCW : TButton;
    btnMemDwn : TButton;
    btnMemWri : TButton;
    btnMemUp : TButton;
    btnSSB : TButton;
    btnDATA : TButton;
    btnAM : TButton;
    btnFM : TButton;
    btnVFOA : TButton;
    btnVFOB : TButton;
    btPoff : TButton;
    btnUsr2 : TButton;
    btPon : TButton;
    btnUsr1 : TButton;
    btPstby : TButton;
    btnUsr3 : TButton;
    cmbRig: TComboBox;
    edtFreqInput : TEdit;
    edtMemNr : TEdit;
    gbBand : TGroupBox;
    gbFreq : TGroupBox;
    gbMode : TGroupBox;
    gbInfo : TGroupBox;
    gbVfo : TGroupBox;
    GroupBox4 : TGroupBox;
    lblInitRig: TLabel;
    lblFreq : TLabel;
    mnuShowUsr : TMenuItem;
    mnuShowInfo : TMenuItem;
    mnuShowVfo : TMenuItem;
    mnuOpenMem : TMenuItem;
    mnuPref : TMenuItem;
    mnuAddMod : TMenuItem;
    mnuShowPwr : TMenuItem;
    mnuProgPref : TMenuItem;
    mnuMem : TMainMenu;
    pnlUsr : TPanel;
    pnlRig : TPanel;
    pnlMain : TPanel;
    pnlPower : TPanel;
    tmrSetRigTime: TTimer;
    tmrRadio : TTimer;
    procedure acAddModMemExecute(Sender : TObject);
    procedure btnMemWriClick(Sender : TObject);
    procedure btnMemDwnClick(Sender : TObject);
    procedure btnMemUpClick(Sender : TObject);
    procedure btnVFOAClick(Sender : TObject);
    procedure btnVFOBClick(Sender : TObject);
    procedure btPoffClick(Sender : TObject);
    procedure btPonClick(Sender : TObject);
    procedure btPstbyClick(Sender : TObject);
    procedure btnUsrClick(Sender : TObject);
    procedure cmbRigChange(Sender: TObject);
    procedure cmbRigCloseUp(Sender: TObject);
    procedure cmbRigGetItems(Sender: TObject);
    procedure edtFreqInputKeyPress(Sender : TObject; var Key : Char);
    procedure edtFreqInputKeyUp(Sender : TObject; var Key : Word; Shift : TShiftState);
    procedure edtFreqInputMouseLeave(Sender : TObject);
    procedure edtFreqInputMouseUp(Sender : TObject; Button : TMouseButton;
      Shift : TShiftState; X, Y : Integer);
    procedure edtFreqInputMouseWheel(Sender : TObject; Shift : TShiftState;
      WheelDelta : Integer; MousePos : TPoint; var Handled : Boolean);
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure FormCreate(Sender : TObject);
    procedure FormDestroy(Sender : TObject);
    procedure FormKeyDown(Sender : TObject; var Key : Word; Shift : TShiftState);
    procedure FormKeyUp(Sender : TObject; var Key : Word; Shift : TShiftState);
    procedure FormShow(Sender : TObject);
    procedure btn10mClick(Sender : TObject);
    procedure btn12mClick(Sender : TObject);
    procedure btn15mClick(Sender : TObject);
    procedure btn160mClick(Sender : TObject);
    procedure btn17mClick(Sender : TObject);
    procedure btn20mClick(Sender : TObject);
    procedure btn2mClick(Sender : TObject);
    procedure btn30mClick(Sender : TObject);
    procedure btn40mClick(Sender : TObject);
    procedure btn6mClick(Sender : TObject);
    procedure btn70cmClick(Sender : TObject);
    procedure btn80mClick(Sender : TObject);
    procedure btnAMClick(Sender : TObject);
    procedure btnCWClick(Sender : TObject);
    procedure btnFMClick(Sender : TObject);
    procedure btnDATAClick(Sender : TObject);
    procedure btnSSBClick(Sender : TObject);
    procedure gbFreqClick(Sender : TObject);
    procedure lblFreqClick(Sender : TObject);
    procedure mnuShowInfoClick(Sender : TObject);
    procedure mnuShowPwrClick(Sender : TObject);
    procedure mnuProgPrefClick(Sender : TObject);
    procedure mnuShowUsrClick(Sender : TObject);
    procedure mnuShowVfoClick(Sender : TObject);
    procedure tmrRadioTimer(Sender : TObject);
    procedure tmrSetRigTimeTimer(Sender: TObject);
  private
    MouseWheelUsed : Boolean;
    radio : TRigControl;
    old_mode : String;

    btn160MBand : String;
    btn80MBand : String;
    btn40MBand : String;
    btn30MBand : String;
    btn20MBand : String;
    btn17MBand : String;
    btn15MBand : String;
    btn12MBand : String;
    btn10MBand : String;
    btn6MBand : String;
    btn2MBand : String;
    btn70CMBand : String;

    currMin      :String; //for timing rig command: set_clock

    function GetActualMode : String;
    function GetModeNumber(mode : String) : Cardinal;
    procedure SetMode(mode : String; bandwidth : Integer);
    procedure ClearBandButtonsColor;
    procedure ClearModeButtonsColor;
    procedure UpdateModeButtons(mode : String);

    procedure CheckUserMode(var mode : String);
    procedure UserButton(r, b : Char);
  public
    AutoMode : Boolean;
    infosetstage : Integer;
    infosetfreq : String;
    RigInUse    : String;  //rig in use. Number as string
    IsNewHamlib : Boolean;

    procedure SynTRX;

    function GetFreqFromModeBand(band : Integer; smode : String) : String;
    function GetModeFreqNewQSO(var mode, freq : String) : Boolean;
    function GetBandWidth(mode : String) : Integer;
    function GetModeBand(var mode, band : String) : Boolean;
    function InitializeRig : Boolean;
    function GetFreqHz : Double;
    function GetFreqkHz : Double;
    function GetFreqMHz : Double;
    function GetDislayFreq : String;
    function GetRawMode : String;

    procedure SetModeFreq(mode, freq : String);
    procedure SetFreqModeBandWidth(freq : Double; mode : String; BandWidth : Integer);
    procedure SavePosition;
    procedure CloseRigs;
    procedure Split(up : Integer);
    procedure DisableSplit;
    procedure ClearRIT;
    procedure DisableRitXit;
    procedure LoadUsrButtonCaptions;
    procedure LoadButtonCaptions;
    procedure SetDebugMode(DebugMode : Boolean);
    procedure LoadBandButtons;
    function ListModeClose : Boolean;
    procedure HLTune(start : Boolean);
    procedure SendVoice(mem : String);
    procedure StopVoice;
  end;

var
  frmTRXControl : TfrmTRXControl;
  ModeWas : String;  //store mode while tuning with AM
  BwWas : Integer;
  Tuning : Boolean = False;
  MemRelated : Boolean;

implementation

{$R *.lfm}

{ TfrmTRXControl }
uses dUtils, dData, fNewQSO, fBandMap, uMyIni, fGrayline, fRadioMemories;

procedure TfrmTRXControl.HLTune(start : Boolean);
begin
  if Assigned(radio) then
  begin
    if start then
    begin
      if not Tuning then
      begin
        ModeWas := GetActualMode;
        BwWas := GetBandWidth(ModeWas);
        SetMode('AM', 0);
        radio.PttOn;
        Tuning := True;
      end;
    end
    else begin
      radio.PttOff;
      if Tuning then SetMode(ModeWas, BwWas);
      Tuning := False;
    end;
  end;
end;

procedure TfrmTRXControl.SynTRX;
var
  b : String = '';
  f : Double;
  m : String;
  oldG : Integer;
  mG : Integer;
  txlo : Double = 0.0;
  rxlo : Double = 0.0;
begin
  if Assigned(radio) then
  begin
    f := radio.GetFreqMHz;
    m := radio.GetModeOnly;
    if cqrini.ReadBool('NewQSO', 'UseTXLO', False) then
    begin
      if not TryStrToFloat(cqrini.ReadString('NewQSO', 'TXLO', ''), txlo) then
        txlo := 0;
    end;
    if cqrini.ReadBool('NewQSO', 'UseRXLO', False) then
    begin
      if not TryStrToFloat(cqrini.ReadString('NewQSO', 'RXLO', ''), rxlo) then
        rxlo := 0;
      if (f + rxlo <> 0) then
        if not frmNewQSO.cbOffline.Checked then
          frmNewQSO.edtRXFreq.Text := FloatToStr((f + rxlo));
    end;
  end
  else
    f := 0;

  f := f + txlo;
  lblFreq.Caption := FormatFloat(empty_freq, f);

  UpdateModeButtons(m);
  ClearBandButtonsColor;
  // this waits5 rig polls before lock freq set by memory. After that if freq chanfǵes (by vfo knob) clean info text
  // stupid but works quite well
  case infosetstage of
    4: begin
      infosetfreq := lblFreq.Caption;
      Inc(infosetstage);
    end;
    5: begin
      if (infosetfreq <> lblFreq.Caption) then
      begin
        edtMemNr.Text := '';
        infosetstage := 0;
      end;
    end;
    else
      if ((infosetstage > 0) and (infosetstage < 4)) then Inc(infosetstage);
  end;
  if (f = 0) then
  begin
    if cqrini.ReadBool('BandMap', 'UseNewQSOFreqMode', False) then
    begin
      if TryStrToFloat(frmNewQSO.cmbFreq.Text, f) then
      begin
        b := dmUtils.GetBandFromFreq(frmNewQSO.cmbFreq.Text);
        m := frmNewQSO.cmbMode.Text;
        frmGrayline.band := b;
        frmBandMap.CurrentBand := b;
        frmBandMap.CurrentFreq := f * 1000;
        frmBandMap.CurrentMode := m;
      end;
    end
    else begin
      frmGrayline.band := '';
      frmBandMap.CurrentBand := '';
      frmBandMap.CurrentFreq := 0;
      frmBandMap.CurrentMode := '';
    end;
    exit;
  end;

  m := radio.GetRawMode;

  //user changed settings
  if MemRelated <> cqrini.ReadBool('TRX', 'MemModeRelated', False) then
  begin
    MemRelated := cqrini.ReadBool('TRX', 'MemModeRelated', False);
    dmData.OpenFreqMemories(m);
  end
  else begin
    if MemRelated then   //use related settings;
    begin
      //Group1 'LSB','USB','FM','AM'
      //Group2 'RTTY','PKTLSB','PKTUSB','PKTFM','DATA'
      case old_mode of
        'LSB', 'USB', 'FM', 'AM': oldG := 1;
        'RTTY', 'PKTLSB', 'PKTUSB', 'PKTFM', 'DATA': oldG := 2;
        else
          oldG := 0; //CW  or unlisted
      end;
      case m of
        'LSB', 'USB', 'FM', 'AM': mG := 1;
        'RTTY', 'PKTLSB', 'PKTUSB', 'PKTFM', 'DATA': mG := 2;
        else
          mG := 0; //CW  or unlisted
      end;
      if (oldG <> mG) then
      begin
        old_mode := m;
        dmData.OpenFreqMemories(old_mode);
      end;
    end;
  end;

  if (b = '') then
    b := dmUtils.GetBandFromFreq(lblFreq.Caption);
  if b = btn160MBand then
    btn160m.Font.Color := clRed
  else if b = btn80MBand then
    btn80m.Font.Color := clRed
  else if b = btn40MBand then
    btn40m.Font.Color := clRed
  else if b = btn30MBand then
    btn30m.Font.Color := clRed
  else if b = btn20MBand then
    btn20m.Font.Color := clRed
  else if b = btn17MBand then
    btn17m.Font.Color := clRed
  else if b = btn15MBand then
    btn15m.Font.Color := clRed
  else if b = btn12MBand then
    btn12m.Font.Color := clRed
  else if b = btn10MBand then
    btn10m.Font.Color := clRed
  else if b = btn6MBand then
    btn6m.Font.Color := clRed
  else if b = btn2MBand then
    btn2m.Font.Color := clRed
  else if b = btn70CMBand then
    btn70cm.Font.Color := clRed;
  frmGrayline.band := b;
  frmBandMap.CurrentBand := b;
  frmBandMap.CurrentFreq := f * 1000;
  frmBandMap.CurrentMode := m;
  if Assigned(radio) then
     begin
          btPon.Enabled:=radio.Power;
          btPoff.Enabled:=radio.Power;
          btPstby.Enabled:=radio.Power;
     end;
end;

function TfrmTRXControl.GetModeNumber(mode : String) : Cardinal;
begin
  Result := 0;
  if mode = 'AM' then
    Result := 3;
  if mode = 'CW' then
    Result := 0;
  if mode = 'LSB' then
    Result := 1;
  if mode = 'USB' then
    Result := 1;
  if mode = 'RTTY' then
    Result := 2;
  if mode = 'FM' then
    Result := 4;
  if mode = 'WFM' then
    Result := 4;
end;

function TfrmTRXControl.GetBandWidth(mode : String) : Integer;
var
  section : String;
begin
  section := 'Band'+RigInUse;
  Result := 500;
  if (mode = 'LSB') or (mode = 'USB') then
    mode := 'SSB';
  if mode = 'CW' then
    Result := (cqrini.ReadInteger(section, 'CW', 500));
  if mode = 'SSB' then
    Result := (cqrini.ReadInteger(section, 'SSB', 1800));
  if mode = 'RTTY' then
    Result := (cqrini.ReadInteger(section, 'RTTY', 500)); //note: Data is called rtty for backward compatibility
  if mode = 'AM' then
    Result := (cqrini.ReadInteger(section, 'AM', 3000));
  if mode = 'FM' then
    Result := (cqrini.ReadInteger(section, 'FM', 2500));
end;
procedure TfrmTRXControl.FormShow(Sender : TObject);

begin
  LoadUsrButtonCaptions;
  LoadButtonCaptions;
  LoadBandButtons;
  dmUtils.LoadWindowPos(frmTRXControl);
  cmbRigGetItems(nil);
  //These two are needed here othewise rig selector has "None" even if rig is initialized at startup
  cmbRig.ItemIndex:=cqrini.ReadInteger('TRX', 'RigInUse', 1);
  cmbRigCloseUp(nil); //defaults rig 1 in case of undefined
  old_mode := '';
  MemRelated := cqrini.ReadBool('TRX', 'MemModeRelated', False);
  gbInfo.Visible := cqrini.ReadBool('TRX', 'MemShowInfo', gbInfo.Visible);
  mnuShowInfo.Checked := gbInfo.Visible;
  gbVfo.Visible := cqrini.ReadBool('TRX', 'ShowVfo', gbVfo.Visible);
  pnlUsr.Visible := cqrini.ReadBool('TRX', 'ShowUsr', pnlUsr.Visible);
  mnuShowVfo.Checked := gbVfo.Visible;
  mnuShowUsr.Checked := pnlUsr.Visible;
  MouseWheelUsed := False;
end;

procedure TfrmTRXControl.btn10mClick(Sender : TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearBandButtonsColor;
  mode := GetActualMode;
  freq := GetFreqFromModeBand(8, mode);
  SetModeFreq(mode, freq);
  btn10m.Font.Color := clRed;
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
end;

procedure TfrmTRXControl.btn12mClick(Sender : TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearBandButtonsColor;
  mode := GetActualMode;
  freq := GetFreqFromModeBand(7, mode);
  SetModeFreq(mode, freq);
  btn12m.Font.Color := clRed;
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
end;

procedure TfrmTRXControl.btn15mClick(Sender : TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearBandButtonsColor;
  mode := GetActualMode;
  freq := GetFreqFromModeBand(6, mode);
  SetModeFreq(mode, freq);
  btn15m.Font.Color := clRed;
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
end;

procedure TfrmTRXControl.btn160mClick(Sender : TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearBandButtonsColor;
  mode := GetActualMode;
  freq := GetFreqFromModeBand(0, mode);
  SetModeFreq(mode, freq);
  btn160m.Font.Color := clRed;
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
end;

procedure TfrmTRXControl.btn17mClick(Sender : TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearBandButtonsColor;
  mode := GetActualMode;
  freq := GetFreqFromModeBand(5, mode);
  SetModeFreq(mode, freq);
  btn17m.Font.Color := clRed;
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
end;

procedure TfrmTRXControl.btn20mClick(Sender : TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearBandButtonsColor;
  mode := GetActualMode;
  freq := GetFreqFromModeBand(4, mode);
  SetModeFreq(mode, freq);
  btn20m.Font.Color := clRed;
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
end;

procedure TfrmTRXControl.btn2mClick(Sender : TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearBandButtonsColor;
  mode := GetActualMode;
  freq := GetFreqFromModeBand(10, mode);
  SetModeFreq(mode, freq);
  btn2m.Font.Color := clRed;
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
end;

procedure TfrmTRXControl.btn30mClick(Sender : TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearBandButtonsColor;
  mode := GetActualMode;
  freq := GetFreqFromModeBand(3, mode);
  SetModeFreq(mode, freq);
  btn30m.Font.Color := clRed;
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
end;

procedure TfrmTRXControl.btn40mClick(Sender : TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearBandButtonsColor;
  mode := GetActualMode;
  freq := GetFreqFromModeBand(2, mode);
  SetModeFreq(mode, freq);
  btn40m.Font.Color := clRed;
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
end;

procedure TfrmTRXControl.btn6mClick(Sender : TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearBandButtonsColor;
  mode := GetActualMode;
  freq := GetFreqFromModeBand(9, mode);
  SetModeFreq(mode, freq);
  btn6m.Font.Color := clRed;
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
end;

procedure TfrmTRXControl.btn70cmClick(Sender : TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearBandButtonsColor;
  mode := GetActualMode;
  freq := GetFreqFromModeBand(11, mode);
  SetModeFreq(mode, freq);
  btn70cm.Font.Color := clRed;
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
end;

procedure TfrmTRXControl.btn80mClick(Sender : TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearBandButtonsColor;
  mode := GetActualMode;
  freq := GetFreqFromModeBand(1, mode);
  SetModeFreq(mode, freq);
  btn80m.Font.Color := clRed;
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
end;

procedure TfrmTRXControl.btnVFOAClick(Sender : TObject);
begin
  if Assigned(radio) then radio.SetCurrVfo(VFOA);
end;

procedure TfrmTRXControl.btnVFOBClick(Sender : TObject);
begin
  if Assigned(radio) then radio.SetCurrVfo(VFOB);
end;

procedure TfrmTRXControl.btnCWClick(Sender : TObject);
begin
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
  SetMode('CW', GetBandWidth('CW'));
end;

procedure TfrmTRXControl.btnSSBClick(Sender : TObject);
var
  tmp : Currency;
begin
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
  if not TryStrToCurr(lblFreq.Caption, tmp) then
    SetMode('LSB', GetBandWidth('SSB'))
  else begin
    if (tmp > 5) and (tmp < 6) then
      SetMode('USB', GetBandWidth('SSB'))
    else begin
      if tmp > 10 then
        SetMode('USB', GetBandWidth('SSB'))
      else
        SetMode('LSB', GetBandWidth('SSB'));
    end;
  end;
end;

procedure TfrmTRXControl.gbFreqClick(Sender : TObject);
begin
  edtFreqInput.Text := lblFreq.Caption;
  edtFreqInput.Font := lblFreq.Font;
  edtFreqInput.Color := clYellow;
  edtFreqInput.Visible := True;
  edtFreqInput.SetFocus;
  edtFreqInput.SelStart := Length(edtFreqInput.Text);
end;

procedure TfrmTRXControl.lblFreqClick(Sender : TObject);
begin
  gbFreqClick(Sender);
end;

procedure TfrmTRXControl.mnuShowInfoClick(Sender : TObject);
begin
  gbInfo.Visible := not gbInfo.Visible;
  mnuShowInfo.Checked := gbInfo.Visible;
  cqrini.WriteBool('TRX', 'MemShowInfo', gbInfo.Visible);
end;

procedure TfrmTRXControl.btnDATAClick(Sender : TObject);
begin
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
  //TODO fix mode setting here
  SetMode('RTTY', GetBandWidth('RTTY'));
end;

procedure TfrmTRXControl.btnAMClick(Sender : TObject);
begin
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
  SetMode('AM', GetBandWidth('AM'));
end;

procedure TfrmTRXControl.btnFMClick(Sender : TObject);
begin
  frmTRXControl.edtMemNr.Text := ''; //clear memo nr display if any text from last M push
  SetMode('FM', GetBandWidth('FM'));
end;

procedure TfrmTRXControl.mnuShowPwrClick(Sender : TObject);
begin
  if pnlPower.Visible then
  begin
    pnlPower.Visible := False;
    mnuShowPwr.Checked := False;
  end
  else begin
    pnlPower.Visible := True;
    mnuShowPwr.Checked := True;
  end;
  cqrini.WriteBool('TRX', 'PowerButtons', pnlPower.Visible);
end;

procedure TfrmTRXControl.mnuProgPrefClick(Sender : TObject);
begin
  cqrini.WriteInteger('Pref', 'ActPageIdx', 5);
  //set TRXControl tab active. Number may change if preferences page change
  frmNewQSO.acPreferences.Execute;
end;

procedure TfrmTRXControl.mnuShowUsrClick(Sender : TObject);
begin
  pnlUsr.Visible := not pnlUsr.Visible;
  mnuShowUsr.Checked := pnlUsr.Visible;
  cqrini.WriteBool('TRX', 'ShowUsr', pnlUsr.Visible);
end;

procedure TfrmTRXControl.mnuShowVfoClick(Sender : TObject);
begin
  gbVfo.Visible := not gbVfo.Visible;
  mnuShowVfo.Checked := gbVfo.Visible;
  cqrini.WriteBool('TRX', 'ShowVfo', gbVfo.Visible);
end;

procedure TfrmTRXControl.tmrRadioTimer(Sender : TObject);
begin
  SynTRX;
end;

procedure TfrmTRXControl.tmrSetRigTimeTimer(Sender: TObject);
var
   m  : String;
begin
     tmrSetRigTime.Enabled:=False;
     m:= FormatDateTime('n',Now);
     if currMin='' then currMin:=m;
     if currMin<>m then //minute has changed set rig time
        Begin
            m:='+\set_clock '+FormatDateTime('yyyy-mm-dd"T"hh:mm',dmutils.GetDateTime(0))+'+00';
            if Assigned(radio) then
                          radio.UsrCmd(m);
            if ((dmData.DebugLevel >= 1) or ((abs(dmData.DebugLevel) and 8) = 8)) then
              writeln(m);
        end
      else
       tmrSetRigTime.Enabled:=True; //continue waiting
end;

procedure TfrmTRXControl.FormClose(Sender : TObject; var CloseAction : TCloseAction);
begin
  cqrini.WriteInteger('TRX', 'RigInUse', cmbRig.ItemIndex);
  dmUtils.SaveWindowPos(frmTRXControl);
end;

function TfrmTRXControl.ListModeClose : Boolean;

begin
  Result := False;
  if (frmRadioMemories <> nil) then
    if (frmRadioMemories.ShowMode) then   //is open in show list mode
    begin
      FreeAndNil(frmRadioMemories);
      Result := True;
    end;
end;

procedure TfrmTRXControl.acAddModMemExecute(Sender : TObject);

begin
  ListModeClose;
  frmRadioMemories := TfrmRadioMemories.Create(frmTRXControl);
  if Sender = mnuOpenMem then    //show only
  begin
    frmRadioMemories.Show;
    frmRadioMemories.Panel1.Visible := False;
    frmRadioMemories.ShowMode := True;
    try
      dmData.LoadFreqMemories(frmRadioMemories.sgrdMem);
    except
      on E : Exception do
        ShowMessage('Could not load memories: ' + E.ClassName + #13#10 + E.Message);
    end;
  end
  else begin
    try
      dmData.LoadFreqMemories(frmRadioMemories.sgrdMem);
      frmRadioMemories.ShowModal;
      if frmRadioMemories.ModalResult = mrOk then
      begin
        dmData.StoreFreqMemories(frmRadioMemories.sgrdMem);
      end
    finally
      FreeAndNil(frmRadioMemories);
    end;
  end;

end;

procedure TfrmTRXControl.btnMemWriClick(Sender : TObject);
var
  bandwidth : Word = 0;
  mode : String = '';
  freq : String = '';
  Dfreq : Double;

begin
  Dfreq := 0;
  Dfreq := radio.GetFreqkHz;
  if Dfreq > 0 then
  begin
    ListModeClose;
    frmRadioMemories := TfrmRadioMemories.Create(frmTRXControl);
    try
      dmData.LoadFreqMemories(frmRadioMemories.sgrdMem);
      bandwidth := radio.GetPassOnly;
      mode := radio.GetRawMode;
      freq := FloatToStrF(Dfreq, ffGeneral, 15, 0);
      if (mode <> '') then
      begin
        frmRadioMemories.sgrdMem.RowCount := frmRadioMemories.sgrdMem.RowCount + 1;
        frmRadioMemories.sgrdMem.Cells[0, frmRadioMemories.sgrdMem.RowCount - 1] := freq;
        frmRadioMemories.sgrdMem.Cells[1, frmRadioMemories.sgrdMem.RowCount - 1] := mode;
        frmRadioMemories.sgrdMem.Cells[2, frmRadioMemories.sgrdMem.RowCount - 1] :=
          IntToStr(bandwidth);
        dmData.StoreFreqMemories(frmRadioMemories.sgrdMem);
        edtMemNr.Font.Color := clRed;
        edtMemNr.Text := 'MW ok';
        infosetstage := 1;
      end
    finally
      FreeAndNil(frmRadioMemories);
    end;
  end;
end;

procedure TfrmTRXControl.btnMemDwnClick(Sender : TObject);
var
  freq : Double;
  mode : String;
  bandwidth : Integer;
  info : String;
begin
  dmData.GetNextFreqFromMem(freq, mode, bandwidth, info);
  if dmData.DebugLevel >= 1 then
    writeln('--------------FMWI', freq, ' ', mode, ' ', bandwidth, ' ', info);
  if freq > 0 then
    SetFreqModeBandWidth(freq, mode, bandwidth);
end;

procedure TfrmTRXControl.btnMemUpClick(Sender : TObject);
var
  freq : Double;
  mode : String;
  bandwidth : Integer;
  info : String;
begin
  dmData.GetPreviousFreqFromMem(freq, mode, bandwidth, info);
  if freq > 0 then
    SetFreqModeBandWidth(freq, mode, bandwidth);
end;

procedure TfrmTRXControl.btPoffClick(Sender : TObject);
begin
  if Assigned(radio) then
  begin
    radio.PwrOff;
    btPon.Font.Color := clDefault;
    btPstby.Font.Color := clDefault;
    btPoff.Font.Color := clRed;
  end;
end;

procedure TfrmTRXControl.btPonClick(Sender : TObject);
begin
  if Assigned(radio) then
  begin
    radio.PwrOn;
    btPon.Font.Color := clRed;
    btPstby.Font.Color := clDefault;
    btPoff.Font.Color := clDefault;
  end;
end;

procedure TfrmTRXControl.btPstbyClick(Sender : TObject);
begin
  if Assigned(radio) then
  begin
    radio.PwrStBy;
    btPon.Font.Color := clDefault;
    btPstby.Font.Color := clRed;
    btPoff.Font.Color := clDefault;
  end;
end;

procedure TfrmTRXControl.UserButton(r, b : Char);
var
  c : String;
begin
  c := trim(cqrini.ReadString('TRX' + r, 'usr' + b, ''));
  if pos('RUN', uppercase(c)) = 1 then
  begin
    c := trim(copy(c, 4, length(c)));
    dmutils.RunOnBackground(c);
  end
  else
   if Assigned(radio) then
              radio.UsrCmd(c);
end;
procedure TfrmTRXControl.btnUsrClick(Sender : TObject);
var
  b : Char;
begin
  if Sender = btnUsr1 then b:='1';
  if Sender = btnUsr2 then b:='2';
  if Sender = btnUsr3 then b:='3';
  UserButton(RigInUse[1], b);
end;

procedure TfrmTRXControl.cmbRigChange(Sender: TObject);
begin
  cmbRig.Visible:=False;
  lblInitRig.Visible:=True;
  InitializeRig;
  lblInitRig.Visible:=False;
  cmbRig.Visible:=True;
end;

procedure TfrmTRXControl.cmbRigCloseUp(Sender: TObject);
begin
  if cmbRig.ItemIndex<1 then cmbRig.ItemIndex:=1;
  RigInUse:=IntToStr(cmbRig.ItemIndex);
  cqrini.WriteInteger('TRX', 'RigInUse',cmbRig.ItemIndex);
end;

procedure TfrmTRXControl.cmbRigGetItems(Sender: TObject);
//sets rig names or none to selector list
var
   n:integer;
   s,r:string;
Begin
   cmbRig.Items.Clear;
   cmbRig.Items.add(''); //nr zero is empty
   for n:=1 to cqrini.ReadInteger('TRX', 'RigCount', 2) do
   Begin
       s:=IntToStr(n);
       r:=cqrini.ReadString('TRX'+s, 'Desc', '');
       if r='' then  r:=' None' else r:=' '+r;
       cmbRig.Items.add(s + r);
   end;
   cmbRig.ItemIndex:=cqrini.ReadInteger('TRX', 'RigInUse', 1);
end;

procedure TfrmTRXControl.edtFreqInputKeyPress(Sender : TObject; var Key : Char);
begin
  if key = '.' then
  begin
    if pos('.', edtFreqInput.Text) > 0 then         //only one dot
      Key := #0;
  end
  else
  if (Key <> #127)      //delete and numbers ok
    and ((Key > '9') or ((Key >= #20) and (Key < '0'))) then
    Key := #0;
end;


procedure TfrmTRXControl.edtFreqInputKeyUp(Sender : TObject; var Key : Word;
  Shift : TShiftState);
var
  freq : String = '';
  mode : String = '';
  s : String;
  f : Currency;
begin
  if Key = VK_Return then
  begin
    MouseWheelUsed := False;
    s := edtFreqInput.Text;
    mode := GetActualMode;
    try
      f := StrToFloat(s);
      f := f * 1000;
      freq := FloatToStr(f);
      SetModeFreq(mode, freq);
    except
      On E : Exception do
        edtFreqInput.Text := s;
    end;
    edtFreqInput.Visible := False;
  end;
end;

procedure TfrmTRXControl.edtFreqInputMouseLeave(Sender : TObject);
begin
  if MouseWheelUsed then
    edtFreqInputMouseUp(nil, mbMiddle, [ssCtrl], 0, 0);
end;

procedure TfrmTRXControl.edtFreqInputMouseUp(Sender : TObject;
  Button : TMouseButton; Shift : TShiftState; X, Y : Integer);
var
  Key : Word = VK_Return;
begin
  edtFreqInputKeyUp(nil, Key, Shift);
end;

procedure TfrmTRXControl.edtFreqInputMouseWheel(Sender : TObject;
  Shift : TShiftState; WheelDelta : Integer; MousePos : TPoint; var Handled : Boolean);
var
  s : String;
  f : Currency;
  m : Currency;
begin
  MouseWheelUsed := True;
  m := 0.0001;   //base 10Hz step
  if Shift = [ssShift] then
    m := 0.001;
  if Shift = [ssCtrl] then
    m := 0.01;
  if Shift = [ssShift] + [ssCtrl] then
    m := 1;
  if WheelDelta < 0 then
    m := m * -1;

  s := edtFreqInput.Text;
  try
    f := StrToFloat(s);
    f := f + m;
    if f < 0 then f := 0;
    edtFreqInput.Text := FormatFloat(empty_freq + ';;', f);
    if Assigned(radio) then
      radio.SetFreqKHz(f * 1000);
  except
    On E : Exception do
      edtFreqInput.Text := s;
  end;
end;

procedure TfrmTRXControl.FormCreate(Sender : TObject);
begin
  Radio := nil;
  AutoMode := True;
end;

procedure TfrmTRXControl.FormDestroy(Sender : TObject);
begin
  if dmData.DebugLevel >= 1 then Writeln('Closing TRXControl window');
end;

procedure TfrmTRXControl.FormKeyDown(Sender : TObject; var Key : Word;
  Shift : TShiftState);
begin
  if (Shift = [ssAlt]) and (key = VK_F) then
  begin
    dmUtils.EnterFreq;
    key := 0;
  end;
  if (Shift = [ssCTRL]) then
    if key in [VK_1..VK_9] then frmNewQSO.SetSplit(chr(key));
  if ((Shift = [ssCTRL]) and (key = VK_0)) then
    DisableSplit;
end;

procedure TfrmTRXControl.FormKeyUp(Sender : TObject; var Key : Word;
  Shift : TShiftState);
begin
  if (key = VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0;
  end;
end;

function TfrmTRXControl.InitializeRig : Boolean;
var
  id : Integer = 0;
  port : Integer;
  poll : Integer;
  KeyerType : Integer;
begin
  tmrRadio.Enabled := False;

  if Assigned(radio) then FreeAndNil(radio);

  Application.ProcessMessages;
  Sleep(500);
  Application.ProcessMessages;

  if not TryStrToInt(cqrini.ReadString('TRX' + RigInUse, 'model', ''), id) then
   Begin
    cmbRig.Items[cmbRig.ItemIndex]:= RigInUse + ' Is not Set';
    lblFreq.Caption:='0.0000';
    ClearBandButtonsColor;
    ClearModeButtonsColor;
    exit;
   end
  else
   begin
    radio := TRigControl.Create;
    if (dmData.DebugLevel > 0) or cqrini.ReadBool('TRX', 'Debug', False) then
    radio.DebugMode := True;
    radio.RigId := id;
   end;

  //broken configuration caused crash because RigCtldPort was empty
  //probably late to change it to Integer, I have no idea if the current
  //setting would be converted automatically or user has to do it again :(


  //OH1KH 2022-12-09: cqrini.ReadInteger and  cqrini.ReadString both can be used!
  //Works same way as database ReadAsString or ReadAsInteger; Source is same but resulting read is
  //either String or Integer how programmer wants.
  //cqrini.Write does not make difference in config file if variable is saved as String or Integer
  //both results look same in .cfg file.

    port:= cqrini.ReadInteger('TRX' + RigInUse, 'RigCtldPort', 4532);
    if ((port>65534) or (port<1024)) then port := 4532;  //limit values

    poll:=cqrini.ReadInteger('TRX' + RigInUse, 'poll', 500);
    if ((poll>60000) or (poll<10)) then  poll := 500;  //limit values

  radio.RigCtldPath := cqrini.ReadString('TRX', 'RigCtldPath', '/usr/bin/rigctld');
  radio.RigCtldArgs := dmUtils.GetRadioRigCtldCommandLine(StrToInt(RigInUse));
  radio.RunRigCtld := cqrini.ReadBool('TRX' + RigInUse, 'RunRigCtld', False);
  radio.RigDevice := cqrini.ReadString('TRX' + RigInUse, 'device', '');
  radio.RigCtldPort := port;
  radio.RigCtldHost := cqrini.ReadString('TRX' + RigInUse, 'host', 'localhost');
  radio.RigPoll := poll;
  radio.RigSendCWR := cqrini.ReadBool('TRX' + RigInUse, 'CWR', False);
  radio.RigChkVfo := cqrini.ReadBool('TRX' + RigInUse, 'ChkVfo', True);
  radio.PowerON:=cqrini.ReadBool('TRX'+ RigInUse, 'RigPwrON', True);
  radio.CompoundPoll:=cqrini.ReadBool('TRX'+RigInUse, 'CPollR', True);
  tmrRadio.Interval := radio.RigPoll;
  tmrRadio.Enabled := True;
  Result := True;

  LoadUsrButtonCaptions;

  pnlPower.Visible := cqrini.ReadBool('TRX', 'PowerButtons', False);
  mnuShowPwr.Checked := pnlPower.Visible;


  if not radio.Connected then
      begin
        FreeAndNil(radio);
      end
  else  //radio changed, restart CW interface
    begin
      IsNewHamlib:=radio.IsNewHamlib;
      //we check this again although preferences prevent false setting
      if ( cqrini.ReadBool('CW', 'NoReset', False) //is set: user does not want reset
        and (cqrini.ReadInteger('CW'+RigInUse, 'Type', 0) <> 4)  //type is not HamLib
        ) then //no restart keyer it is same device for both radios.
            begin
              if ((dmData.DebugLevel >= 1) or ((abs(dmData.DebugLevel) and 8) = 8)) then
                Writeln('User want: No reset and keyer not Hamlib: No restart by TRControl radio'
                  + RigInUse + ' change');
            end
      else
        Begin
          frmNewQSO.InitializeCW;
          if ((dmData.DebugLevel >= 1) or ((abs(dmData.DebugLevel) and 8) = 8)) then
            Writeln('CW keyer reloaded by TRControl radio' + RigInUse + ' change');
        end;

      if cqrini.ReadBool('TRX'+RigInUse, 'UTC2Rig', False) then
             Begin
              currMin:='';
              tmrSetRigTime.Enabled:=True; //sets rig time on next minute change
              if ((dmData.DebugLevel >= 1) or ((abs(dmData.DebugLevel) and 8) = 8)) then
                 Writeln('Set UTC to radio' + RigInUse + ' on next full minute');
             end;
    end;
end;

procedure TfrmTRXControl.SetMode(mode : String; bandwidth : Integer);
var
  rmode : TRigMode;
begin

  CheckUserMode(mode);
  if Assigned(radio) then
  begin
    rmode.mode := mode;
    rmode.pass := bandwidth;
    radio.SetModePass(rmode);
  end;
end;

function TfrmTRXControl.GetFreqFromModeBand(band : Integer; smode : String) : String;
var
  freq : Currency = 0;
  mode : Integer = 0;
begin
  if smode = 'CW' then
    mode := 0
  else if smode = 'SSB' then
    mode := 1
  else if smode = 'RTTY' then
    mode := 2
  else if smode = 'AM' then
    mode := 3
  else if smode = 'FM' then
    mode := 4;

  case band of
    0: begin
      case mode of
        0: freq := cqrini.ReadFloat('DefFreq', '160cw', 1830);
        1: freq := cqrini.ReadFloat('DefFreq', '160ssb', 1830);
        2: freq := cqrini.ReadFloat('DefFreq', '160rtty', 1845);
        3: freq := cqrini.ReadFloat('DefFreq', '160am', 1845);
        4: freq := cqrini.ReadFloat('DefFreq', '160fm', 1845);
      end; //case
    end;

    1: begin
      case mode of
        0: freq := cqrini.ReadFloat('DefFreq', '80cw', 3525);
        1: freq := cqrini.ReadFloat('DefFreq', '80ssb', 3750);
        2: freq := cqrini.ReadFloat('DefFreq', '80rtty', 3590);
        3: freq := cqrini.ReadFloat('DefFreq', '80am', 3750);
        4: freq := cqrini.ReadFloat('DefFreq', '80fm', 3750);
      end; //case
    end;

    2: begin
      case mode of
        0: freq := cqrini.ReadFloat('DefFreq', '40cw', 7015);
        1: freq := cqrini.ReadFloat('DefFreq', '40ssb', 7080);
        2: freq := cqrini.ReadFloat('DefFreq', '40rtty', 7040);
        3: freq := cqrini.ReadFloat('DefFreq', '40am', 7080);
        4: freq := cqrini.ReadFloat('DefFreq', '40fm', 7080);
      end; //case
    end;

    3: begin
      case mode of
        0: freq := cqrini.ReadFloat('DefFreq', '30cw', 10110);
        1: freq := cqrini.ReadFloat('DefFreq', '30ssb', 10130);
        2: freq := cqrini.ReadFloat('DefFreq', '30rtty', 10130);
        3: freq := cqrini.ReadFloat('DefFreq', '30am', 10130);
        4: freq := cqrini.ReadFloat('DefFreq', '30fm', 10130);
      end; //case
    end;

    4: begin
      case mode of
        0: freq := cqrini.ReadFloat('DefFreq', '20cw', 14025);
        1: freq := cqrini.ReadFloat('DefFreq', '20ssb', 14195);
        2: freq := cqrini.ReadFloat('DefFreq', '20rtty', 14090);
        3: freq := cqrini.ReadFloat('DefFreq', '20am', 14195);
        4: freq := cqrini.ReadFloat('DefFreq', '20fm', 14195);
      end; //case
    end;

    5: begin
      case mode of
        0: freq := cqrini.ReadFloat('DefFreq', '17cw', 18080);
        1: freq := cqrini.ReadFloat('DefFreq', '17ssb', 18140);
        2: freq := cqrini.ReadFloat('DefFreq', '17rtty', 18110);
        3: freq := cqrini.ReadFloat('DefFreq', '17am', 18140);
        4: freq := cqrini.ReadFloat('DefFreq', '17fm', 18140);
      end; //case
    end;

    6: begin
      case mode of
        0: freq := cqrini.ReadFloat('DefFreq', '15cw', 21025);
        1: freq := cqrini.ReadFloat('DefFreq', '15ssb', 21255);
        2: freq := cqrini.ReadFloat('DefFreq', '15rtty', 21090);
        3: freq := cqrini.ReadFloat('DefFreq', '15am', 21255);
        4: freq := cqrini.ReadFloat('DefFreq', '15fm', 21255);
      end; //case
    end;

    7: begin
      case mode of
        0: freq := cqrini.ReadFloat('DefFreq', '12cw', 24895);
        1: freq := cqrini.ReadFloat('DefFreq', '12ssb', 24925);
        2: freq := cqrini.ReadFloat('DefFreq', '12rtty', 24910);
        3: freq := cqrini.ReadFloat('DefFreq', '12am', 24925);
        4: freq := cqrini.ReadFloat('DefFreq', '12fm', 24925);
      end; //case
    end;

    8: begin
      case mode of
        0: freq := cqrini.ReadFloat('DefFreq', '10cw', 28025);
        1: freq := cqrini.ReadFloat('DefFreq', '10ssb', 28550);
        2: freq := cqrini.ReadFloat('DefFreq', '10rtty', 28090);
        3: freq := cqrini.ReadFloat('DefFreq', '10am', 28550);
        4: freq := cqrini.ReadFloat('DefFreq', '10fm', 28550);
      end; //case
    end;

    9: begin
      case mode of
        0: freq := cqrini.ReadFloat('DefFreq', '6cw', 50090);
        1: freq := cqrini.ReadFloat('DefFreq', '6ssb', 51300);
        2: freq := cqrini.ReadFloat('DefFreq', '6rtty', 51300);
        3: freq := cqrini.ReadFloat('DefFreq', '6am', 51300);
        4: freq := cqrini.ReadFloat('DefFreq', '6fm', 51300);
      end; //case
    end;

    10: begin
      case mode of
        0: freq := cqrini.ReadFloat('DefFreq', '2cw', 144050);
        1: freq := cqrini.ReadFloat('DefFreq', '2ssb', 144300);
        2: freq := cqrini.ReadFloat('DefFreq', '2rtty', 144300);
        3: freq := cqrini.ReadFloat('DefFreq', '2am', 144300);
        4: freq := cqrini.ReadFloat('DefFreq', '2fm', 145300);
      end; //case
    end;

    11: begin
      case mode of
        0: freq := cqrini.ReadFloat('DefFreq', '70cw', 432050);
        1: freq := cqrini.ReadFloat('DefFreq', '70ssb', 432300);
        2: freq := cqrini.ReadFloat('DefFreq', '70rtty', 432100);
        3: freq := cqrini.ReadFloat('DefFreq', '70am', 433600);
        4: freq := cqrini.ReadFloat('DefFreq', '70fm', 433500);
      end; //case
    end;

  end; //case
  if dmData.DebugLevel >= 3 then
    Writeln(freq);
  Result := FloatToStr(freq);
  if dmData.DebugLevel >= 3 then
    Writeln(Result);
end;

function TfrmTRXControl.GetActualMode : String;
begin
  if Assigned(radio) then
  begin
    Result := radio.GetModeOnly;
  end;
end;

procedure TfrmTRXControl.SetFreqModeBandWidth(freq : Double; mode : String;
  BandWidth : Integer);
var
  rmode : TRigMode;
  RXOffset : Currency;
  TXOffset : Currency;
begin
  if mode = 'SSB' then
  begin
    if (freq > 5000) and (freq < 6000) then
      mode := 'USB'
    else begin
      if freq > 10000 then
        mode := 'USB'
      else
        mode := 'LSB';
    end;
  end;
  CheckUserMode(mode);

  if Assigned(radio) then
  begin
    dmData.GetRXTXOffset(freq / 1000, RXOffset, TXOffset);
    radio.RXOffset := RXOffset;
    radio.TXOffset := TXOffset;

    radio.SetFreqKHz(freq);
    if AutoMode then
    begin
      rmode.mode := mode;
      rmode.pass := BandWidth;
      radio.SetModePass(rmode);
    end;
  end;
end;

procedure TfrmTRXControl.SetModeFreq(mode, freq : String); //freq in kHz
var
  bandwidth : Integer = 0;
  f : Double = 0;
begin
  if (lblFreq.Caption = empty_freq) then
    exit;
  bandwidth := GetBandWidth(mode);
  f := StrToFloat(freq);
  if mode = 'SSB' then
  begin
    if (f > 5000) and (f < 6000) then
      mode := 'USB'
    else begin
      if f > 10000 then
        mode := 'USB'
      else
        mode := 'LSB';
    end;
  end;

  SetFreqModeBandWidth(f, mode, bandwidth);
end;

function TfrmTRXControl.GetModeFreqNewQSO(var mode, freq : String) : Boolean;
begin
  Result := False;
  if not Assigned(radio) then exit;
  //without this sets old freq as mode (!) if switched from radio to non existing radio
  if not ((lblFreq.Caption = empty_freq) or (lblFreq.Caption = '')) then
    Result := True
  else
    exit;
  freq := lblFreq.Caption;
  mode := GetActualMode;
end;

procedure TfrmTRXControl.SavePosition;
begin
  dmUtils.SaveWindowPos(frmTRXControl);
end;

procedure TfrmTRXControl.ClearBandButtonsColor;
begin
  btn160m.Font.Color := COLOR_WINDOWTEXT;
  btn80m.Font.Color := COLOR_WINDOWTEXT;
  btn40m.Font.Color := COLOR_WINDOWTEXT;
  btn30m.Font.Color := COLOR_WINDOWTEXT;
  btn20m.Font.Color := COLOR_WINDOWTEXT;
  btn17m.Font.Color := COLOR_WINDOWTEXT;
  btn15m.Font.Color := COLOR_WINDOWTEXT;
  btn12m.Font.Color := COLOR_WINDOWTEXT;
  btn10m.Font.Color := COLOR_WINDOWTEXT;
  btn6m.Font.Color := COLOR_WINDOWTEXT;
  btn2m.Font.Color := COLOR_WINDOWTEXT;
  btn70cm.Font.Color := COLOR_WINDOWTEXT;

end;
procedure TfrmTRXControl.ClearModeButtonsColor;
begin
  btnCW.Font.Color := COLOR_WINDOWTEXT;
  btnSSB.Font.Color := COLOR_WINDOWTEXT;
  btnDATA.Font.Color := COLOR_WINDOWTEXT;
  btnAM.Font.Color := COLOR_WINDOWTEXT;
  btnFM.Font.Color := COLOR_WINDOWTEXT;
end;

function TfrmTRXControl.GetModeBand(var mode, band : String) : Boolean;
var
  freq : String;
begin
  mode := '';
  band := '';
  Result := True;
  freq := lblFreq.Caption;
  mode := GetActualMode;
  if (freq = empty_freq) or (freq = '') then
    Result := False
  else
    band := dmUtils.GetBandFromFreq(freq);
end;

procedure TfrmTRXControl.CloseRigs;
begin
  if dmData.DebugLevel > 0 then
    WriteLn('Closing rigs... ');

  if Assigned(radio) then
    FreeAndNil(radio);
end;

procedure TfrmTRXControl.UpdateModeButtons(mode : String);
var
  usermode :String;
begin
  ClearModeButtonsColor;

  usermode:=cqrini.ReadString('Band'+RigInUse, 'Datacmd', 'RTTY');

  btnCW.Font.Color    := COLOR_WINDOWTEXT;
  btnSSB.Font.Color   := COLOR_WINDOWTEXT;
  btnDATA.Font.Color  := COLOR_WINDOWTEXT;
  btnAM.Font.Color    := COLOR_WINDOWTEXT;
  btnFM.Font.Color    := COLOR_WINDOWTEXT;

  if mode = usermode then btnDATA.Font.Color := clRed
     else
       case mode of
        'CW' : btnCW.Font.Color := clRed;
        'SSB' : btnSSB.Font.Color := clRed;
        'AM' : btnAM.Font.Color := clRed;
        'FM' : btnFM.Font.Color := clRed;
       end;
   //update vfobuttons if vfo is known by radio.vfostr
  if Assigned(radio) then
  begin
     if radio.CanGetVfo then
     begin
      case radio.GetCurrVFO of
      VFOA: begin
              btnVFOA.Font.Color := clRed;
              btnVFOB.Font.Color := clDefault;
            end;
      VFOB: begin
              btnVFOB.Font.Color := clRed;
              btnVFOA.Font.Color := clDefault;
            end;
      end;
     end
    else
     begin
      btnVFOB.Font.Color := clDefault;
      btnVFOA.Font.Color := clDefault;
     end;
  end;
end;

procedure TfrmTRXControl.Split(Up : Integer);
begin
  //we do split with XIT, no need to play with 2 VFOs
  if Assigned(radio) then
  begin
    radio.SetSplit(up);
  end;
end;

procedure TfrmTRXControl.DisableSplit;
begin
  if Assigned(radio) then  radio.DisableSplit;
end;

function TfrmTRXControl.GetFreqHz : Double;
begin
  if Assigned(radio) then
    Result := radio.GetFreqHz
  else
    Result := 0;
end;

function TfrmTRXControl.GetFreqkHz : Double;
begin
  if Assigned(radio) then
    Result := radio.GetFreqKHz
  else
    Result := 0;
end;

function TfrmTRXControl.GetFreqMHz : Double;
begin
  if Assigned(radio) then
    Result := radio.GetFreqMHz
  else
    Result := 0;
end;

function TfrmTRXControl.GetDislayFreq : String;
begin
  if Assigned(radio) then
    Result := FormatFloat(empty_freq + ';;', radio.GetFreqMHz)
  else
    Result := FormatFloat(empty_freq + ';;', 0);
end;

procedure TfrmTRXControl.ClearRIT;
begin
  if (lblFreq.Caption = empty_freq) then
    exit;
  radio.ClearRit;
  radio.ClearXit;   //this clears Xit too
end;

procedure TfrmTRXControl.DisableRitXit;
begin
  if not Assigned(radio) then
    exit;
  radio.DisableRit;
  radio.DisableSplit;   //this disabeles Xit
end;

procedure TfrmTRXControl.LoadUsrButtonCaptions;
begin
  btnUsr1.Caption := cqrini.ReadString('TRX' + RigInUse, 'usr1name', 'Usr1');
  btnUsr2.Caption := cqrini.ReadString('TRX' + RigInUse, 'usr2name', 'Usr2');
  btnUsr3.Caption := cqrini.ReadString('TRX' + RigInUse, 'usr3name', 'Usr3');
end;

procedure TfrmTRXControl.LoadButtonCaptions;
begin
  btn160m.Caption := cqrini.ReadString('DefFreq', '160btn', '160m');
  btn80m.Caption := cqrini.ReadString('DefFreq', '80btn', '80m');
  btn40m.Caption := cqrini.ReadString('DefFreq', '40btn', '40m');
  btn30m.Caption := cqrini.ReadString('DefFreq', '30btn', '30m');
  btn20m.Caption := cqrini.ReadString('DefFreq', '20btn', '20m');
  btn17m.Caption := cqrini.ReadString('DefFreq', '17btn', '17m');
  btn15m.Caption := cqrini.ReadString('DefFreq', '15btn', '15m');
  btn12m.Caption := cqrini.ReadString('DefFreq', '12btn', '12m');
  btn10m.Caption := cqrini.ReadString('DefFreq', '10btn', '10m');
  btn6m.Caption := cqrini.ReadString('DefFreq', '6btn', '6m');
  btn2m.Caption := cqrini.ReadString('DefFreq', '2btn', '2m');
  btn70cm.Caption := cqrini.ReadString('DefFreq', '70btn', '70cm');
end;

procedure TfrmTRXControl.SetDebugMode(DebugMode : Boolean);
begin
  if Assigned(radio) then
  begin
    radio.DebugMode := DebugMode;
  end;
end;

function TfrmTRXControl.GetRawMode : String;
begin
  if Assigned(radio) then
    Result := radio.GetRawMode
  else
    Result := '';
end;

procedure TfrmTRXControl.LoadBandButtons;
begin
  btn160MBand := dmUtils.GetBandFromFreq(FloatToStr(cqrini.ReadFloat('DefFreq','160cw',1830)/1000));
  btn80MBand  := dmUtils.GetBandFromFreq(FloatToStr(cqrini.ReadFloat('DefFreq','80cw',3525)/1000));
  btn40MBand  := dmUtils.GetBandFromFreq(FloatToStr(cqrini.ReadFloat('DefFreq','40cw',7015)/1000));
  btn30MBand  := dmUtils.GetBandFromFreq(FloatToStr(cqrini.ReadFloat('DefFreq','30cw',10110)/1000));
  btn20MBand  := dmUtils.GetBandFromFreq(FloatToStr(cqrini.ReadFloat('DefFreq','20cw',14025)/1000));
  btn17MBand  := dmUtils.GetBandFromFreq(FloatToStr(cqrini.ReadFloat('DefFreq','17cw',18080)/1000));
  btn15MBand  := dmUtils.GetBandFromFreq(FloatToStr(cqrini.ReadFloat('DefFreq','15cw',21025)/1000));
  btn12MBand  := dmUtils.GetBandFromFreq(FloatToStr(cqrini.ReadFloat('DefFreq','12cw',24895)/1000));
  btn10MBand  := dmUtils.GetBandFromFreq(FloatToStr(cqrini.ReadFloat('DefFreq','10cw',28025)/1000));
  btn6MBand   := dmUtils.GetBandFromFreq(FloatToStr(cqrini.ReadFloat('DefFreq','6cw',50090)/1000));
  btn2MBand   := dmUtils.GetBandFromFreq(FloatToStr(cqrini.ReadFloat('DefFreq','2cw',144050)/1000));
  btn70CMBand := dmUtils.GetBandFromFreq(FloatToStr(cqrini.ReadFloat('DefFreq','70cw',430000)/1000))
end;
procedure TfrmTRXControl.CheckUserMode(var mode : String);
var
  usermode,
  usercmd  :String;
begin
  usercmd:=cqrini.ReadString('Band'+RigInUse, 'Datacmd', 'RTTY');
  usermode:=cqrini.ReadString('Band'+RigInUse, 'Datamode', 'RTTY');

  if ((Upcase(mode)='RTTY') or (Upcase(mode)=Upcase(usermode))) then
     mode := usercmd;
end;
procedure TfrmTRXControl.SendVoice(mem : String);

begin
  if Assigned(radio) then
   if radio.Voice then
    radio.SendVoice(mem);
end;
procedure TfrmTRXControl.StopVoice;

begin
  if Assigned(radio) then
   if radio.Voice then
    radio.StopVoice;
end;

end.
