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
  ExtCtrls, inifiles, process, lcltype, buttons, Menus, ActnList, dynlibs,
  uRigControl;



type

  { TfrmTRXControl }

  TfrmTRXControl = class(TForm)
    acMem: TActionList;
    acAddModMem: TAction;
    btn10m: TButton;
    btn12m: TButton;
    btn15m: TButton;
    btn160m: TButton;
    btn17m: TButton;
    btn20m: TButton;
    btn2m: TButton;
    btn30m: TButton;
    btn40m: TButton;
    btn6m: TButton;
    btn70cm: TButton;
    btn80m: TButton;
    btnCW: TButton;
    btnMemUp: TButton;
    btnMemDwn: TButton;
    btnSSB: TButton;
    btnRTTY: TButton;
    btnAM: TButton;
    btnFM: TButton;
    btnVFOA: TButton;
    btnVFOB: TButton;
    gbBand: TGroupBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox4: TGroupBox;
    lblFreq: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    mnuMem: TMainMenu;
    Panel1: TPanel;
    Panel2: TPanel;
    rbRadio1: TRadioButton;
    rbRadio2: TRadioButton;
    tmrRadio : TTimer;
    procedure acAddModMemExecute(Sender: TObject);
    procedure btnMemDwnClick(Sender: TObject);
    procedure btnMemUpClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender : TObject; var CanClose : boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure btn10mClick(Sender: TObject);
    procedure btn12mClick(Sender: TObject);
    procedure btn15mClick(Sender: TObject);
    procedure btn160mClick(Sender: TObject);
    procedure btn17mClick(Sender: TObject);
    procedure btn20mClick(Sender: TObject);
    procedure btn2mClick(Sender: TObject);
    procedure btn30mClick(Sender: TObject);
    procedure btn40mClick(Sender: TObject);
    procedure btn6mClick(Sender: TObject);
    procedure btn70cmClick(Sender: TObject);
    procedure btn80mClick(Sender: TObject);
    procedure btnAMClick(Sender: TObject);
    procedure btnCWClick(Sender: TObject);
    procedure btnFMClick(Sender: TObject);
    procedure btnRTTYClick(Sender: TObject);
    procedure btnSSBClick(Sender: TObject);
    procedure rbRadio1Click(Sender: TObject);
    procedure rbRadio2Click(Sender: TObject);
    procedure tmrRadioTimer(Sender : TObject);
  private
    radio : TRigControl;
    old_mode : String;

    btn160MBand : String;
    btn80MBand  : String;
    btn40MBand  : String;
    btn30MBand  : String;
    btn20MBand  : String;
    btn17MBand  : String;
    btn15MBand  : String;
    btn12MBand  : String;
    btn10MBand  : String;
    btn6MBand   : String;
    btn2MBand   : String;
    btn70CMBand : String;

    function  GetActualMode : String;
    function  GetModeNumber(mode : String) : Cardinal;
    procedure SetMode(mode : String;bandwidth :Integer);
    procedure ClearButtonsColor;
    procedure UpdateModeButtons(mode : String);
  public
    {
    rfreq : Double;
    rmode : String;

    set_freq  : Double;
    set_mode  : String;
    set_width : Integer;
    ReloadCfg : Boolean;
    RigCrit   : TRTLCriticalSection;
    RigRel    : TRTLCriticalSection;
    }
    AutoMode  : Boolean;
    //Running   : Boolean;
    procedure SynTRX;

    function  GetFreqFromModeBand(band : Integer;smode : String) : String;
    function  GetModeFreqNewQSO(var mode,freq : String) : Boolean;
    function  GetBandWidth(mode : String) : Integer;
    function  GetModeBand(var mode,band : String) : Boolean;
    function  InicializeRig : Boolean;
    function  GetFreqHz  : Double;
    function  GetFreqkHz : Double;
    function  GetFreqMHz : Double;
    function  GetDislayFreq : String;
    function  GetRawMode : String;

    procedure SetModeFreq(mode,freq : String);
    procedure SetFreqModeBandWidth(freq : Double; mode : String; BandWidth : Integer);
    procedure SavePosition;
    procedure CloseRigs;
    procedure Split(up : Integer);
    procedure DisableSplit;
    procedure ClearRIT;
    procedure LoadButtonCaptions;
    procedure SetDebugMode(DebugMode : Boolean);
    procedure LoadBandButtons;
  end;

{
property RigCtldPath : String  read fRigCtldPath write fRigCtldPath;
//path to rigctld binary
property RigCtldArgs : String  read fRigCtldArgs write fRigCtldArgs;
//rigctld command line arguments
property RunRigCtld  : Boolean read fRunRigCtld  write fRunRigCtld;
//run rigctld command before connection
property RigId       : Word    read fRigId       write fRigId;
//hamlib rig id
property RigDevice   : String  read fRigDevice   write fRigDevice;
//port where is rig connected
property RigCtldPort : Word    read fRigCtldPort write fRigCtldPort;
// port where rigctld is listening to connecions, default 4532
property RigCtldHost : String  read fRigCtldHost write fRigCtldHost;
//host where is rigctld running
property Connected   : Boolean read RigConnected;
//connect rigctld
property RigPoll     : Word    read fRigPoll     write fRigPoll;
//poll rate in milliseconds
}

 type
    TRigThread = class(TThread)
    protected
      procedure Execute; override;
    public
      Rig_RigCtldPath : String;
      Rig_RigCtldArgs : String;
      Rig_RunRigCtld  : Boolean;
      Rig_RigId       : Word;
      Rig_RigDevice   : String;
      Rig_RigCtldPort : Word;
      Rig_RigCtldHost : String;
      Rig_RigPoll     : Word;
      Rig_RigSendCWR  : Boolean;
      Rig_ClearRit    : Boolean;

      {
      Rig_Model       : Integer;
      Rig_Port        : String;
      Rig_SerialSpeed : String;
      Rig_DataBits    : String;
      Rig_Stopbits    : String;
      Rig_Handshake   : String;
      Rig_Parity      : String;
      Rig_DTRState    : String;
      Rig_RTSState    : String;
      Rig_Poll        : Integer;
      }
  end;

var
  frmTRXControl: TfrmTRXControl;
  thRig : TRigThread;

implementation
{$R *.lfm}

{ TfrmTRXControl }
uses dUtils, dData, fNewQSO, fBandMap, uMyIni, fGrayline, fRadioMemories;

procedure TRigThread.Execute;

var
  mRig : TRigControl;

  procedure ReadSettings;
  begin
    mRig.RigCtldPath := Rig_RigCtldPath;
    mRig.RigCtldArgs := Rig_RigCtldArgs;
    mRig.RunRigCtld  := Rig_RunRigCtld;
    mRig.RigId       := Rig_RigId;
    mRig.RigDevice   := Rig_RigDevice;
    mRig.RigCtldPort := Rig_RigCtldPort;
    mRig.RigCtldHost := Rig_RigCtldHost;
    mRig.RigPoll     := Rig_RigPoll;
    mRig.RigSendCWR  := Rig_RigSendCWR
  end;


begin
  {
  mRig := TRigControl.Create;
  try
    mRig.DebugMode := True;
    Writeln('huh');
    frmTRXControl.Running := True;
    ReadSettings;
    if not mRig.Connected then
    begin
      EnterCriticalsection(frmTRXControl.RigCrit);
      try
        frmTRXControl.rfreq := 0;
      finally
        LeaveCriticalsection(frmTRXControl.RigCrit)
      end;
      Synchronize(@frmTRXControl.SynTRX);
      exit
    end;
    while not Terminated do
    begin
      Writeln('huuuuuh');
      EnterCriticalsection(frmTRXControl.RigCrit);
      try
        if frmTRXControl.set_mode <> '' then
        begin
          mode.mode := frmTRXControl.set_mode;
          mode.pass := frmTRXControl.set_width;
          mRig.SetModePass(mode);
          frmTRXControl.set_mode := ''
        end;
        if frmTRXControl.set_freq <> 0 then
        begin
          mRig.SetFreqKHz(frmTRXControl.set_freq);
          frmTRXControl.set_freq := 0
        end
      finally
        LeaveCriticalsection(frmTRXControl.RigCrit)
      end;
      //if dmData.DebugLevel>=1 then Writeln('Freq2:',mRig.Rig_Frequency, ' Model:',mRig.Rig_Model);
      if Rig_ClearRit then
        mRig.ClearRit;
      EnterCriticalsection(frmTRXControl.RigCrit);
      try
        frmTRXControl.rfreq := mRig.GetFreqKHz;
        frmTRXControl.rmode := mRig.GetModeOnly
      finally
        LeaveCriticalsection(frmTRXControl.RigCrit)
      end;
      Synchronize(@frmTRXControl.SynTRX);
      Sleep(Rig_RigPoll)
    end
  finally
    FreeAndNil(mRig);
    if dmData.DebugLevel>=1 then Writeln('TRX control thread terminated');
    frmTRXControl.Running := False
  end
  }
end;

procedure TfrmTRXControl.SynTRX;
var
  b : String = '';
  f : Double;
  m : String;
begin
  if Assigned(radio) then
  begin
    f := radio.GetFreqMHz;
    m := radio.GetModeOnly
  end
  else
    f := 0;
  lblFreq.Caption := FormatFloat(empty_freq+';;',f);
  UpdateModeButtons(m);
  ClearButtonsColor;
  if (f = 0) then
  begin
    if cqrini.ReadBool('BandMap','UseNewQSOFreqMode',False) then
    begin
      if TryStrToFloat(frmNewQSO.cmbFreq.Text,f) then
      begin
        b := dmUtils.GetBandFromFreq(frmNewQSO.cmbFreq.Text);
        m := frmNewQSO.cmbMode.Text;
        frmGrayline.band := b;
        frmBandMap.CurrentBand := b;
        frmBandMap.CurrentFreq := f*1000;
        frmBandMap.CurrentMode := m
      end
    end
    else begin
      frmGrayline.band := '';
      frmBandMap.CurrentBand := '';
      frmBandMap.CurrentFreq := 0;
      frmBandMap.CurrentMode := ''
    end;
    exit
  end;

  m := radio.GetRawMode;
  if (m<>old_mode) then
  begin
    if not (((old_mode='LSB') or (old_mode='USB')) and ((m='LSB') or (m='USB'))) then
    begin
      old_mode := m;
      dmData.OpenFreqMemories(old_mode)
    end
  end;

  if (b='') then
    b := dmUtils.GetBandFromFreq(lblFreq.Caption);
  if b = btn160MBand then
    btn160m.Font.Color := clRed
  else if b = btn80MBand then
    btn80m.Font.Color  := clRed
  else if b = btn40MBand then
    btn40m.Font.Color  := clRed
  else if b = btn30MBand then
    btn30m.Font.Color  := clRed
  else if b = btn20MBand then
    btn20m.Font.Color  := clRed
  else if b = btn17MBand then
    btn17m.Font.Color  := clRed
  else if b = btn15MBand then
    btn15m.Font.Color  := clRed
  else if b = btn12MBand then
    btn12m.Font.Color  := clRed
  else if b = btn10MBand then
    btn10m.Font.Color  := clRed
  else if b = btn6MBand then
    btn6m.Font.Color   := clRed
  else if b = btn2MBand then
    btn2m.Font.Color   := clRed
  else if b = btn70CMBand then
    btn70cm.Font.Color := clRed;
  frmGrayline.band := b;
  frmBandMap.CurrentBand := b;
  frmBandMap.CurrentFreq := f*1000;
  frmBandMap.CurrentMode := m
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
    Result := 4
end;

function TfrmTRXControl.GetBandWidth(mode : String) : Integer;
var
  section : String;
begin
  if rbRadio1.Checked then
    section := 'Band1'
  else
    section := 'Band2';
  Result := 500;
  if (mode = 'LSB') or (mode='USB') then
    mode := 'SSB';
  if mode = 'CW' then
    Result := (cqrini.ReadInteger(section,'CW',500));
  if mode = 'SSB' then
    Result := (cqrini.ReadInteger(section,'SSB',1800));
  if mode = 'RTTY' then
    Result := (cqrini.ReadInteger(section,'RTTY',500));
  if mode = 'AM' then
    Result := (cqrini.ReadInteger(section,'AM',3000));
  if mode = 'FM' then
    Result := (cqrini.ReadInteger(section,'FM',2500))
end;

procedure TfrmTRXControl.FormShow(Sender: TObject);
begin
  LoadButtonCaptions;
  LoadBandButtons;
  dmUtils.LoadWindowPos(frmTRXControl);
  rbRadio1.Caption := cqrini.ReadString('TRX1','Desc','Radio 1');
  rbRadio2.Caption := cqrini.ReadString('TRX2','Desc','Radio 2');
  old_mode := ''
end;

procedure TfrmTRXControl.btn10mClick(Sender: TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearButtonsColor; 
  mode := GetActualMode; 
  freq := GetFreqFromModeBand(8,mode);
  SetModeFreq(mode,freq);
  btn10m.Font.Color := clRed; 
end;

procedure TfrmTRXControl.btn12mClick(Sender: TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearButtonsColor; 
  mode := GetActualMode; 
  freq := GetFreqFromModeBand(7,mode);
  SetModeFreq(mode,freq);
  btn12m.Font.Color := clRed; 
end;

procedure TfrmTRXControl.btn15mClick(Sender: TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearButtonsColor; 
  mode := GetActualMode; 
  freq := GetFreqFromModeBand(6,mode);
  SetModeFreq(mode,freq);
  btn15m.Font.Color := clRed; 
end;

procedure TfrmTRXControl.btn160mClick(Sender: TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearButtonsColor; 
  mode := GetActualMode; 
  freq := GetFreqFromModeBand(0,mode);
  SetModeFreq(mode,freq);
  btn160m.Font.Color := clRed; 
end;

procedure TfrmTRXControl.btn17mClick(Sender: TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearButtonsColor; 
  mode := GetActualMode; 
  freq := GetFreqFromModeBand(5,mode);
  SetModeFreq(mode,freq);
  btn17m.Font.Color := clRed; 
end;

procedure TfrmTRXControl.btn20mClick(Sender: TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearButtonsColor; 
  mode := GetActualMode; 
  freq := GetFreqFromModeBand(4,mode);
  SetModeFreq(mode,freq);
  btn20m.Font.Color := clRed; 
end;

procedure TfrmTRXControl.btn2mClick(Sender: TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearButtonsColor; 
  mode := GetActualMode; 
  freq := GetFreqFromModeBand(10,mode);
  SetModeFreq(mode,freq);
  btn2m.Font.Color := clRed; 
end;

procedure TfrmTRXControl.btn30mClick(Sender: TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearButtonsColor; 
  mode := GetActualMode; 
  freq := GetFreqFromModeBand(3,mode);
  SetModeFreq(mode,freq);
  btn30m.Font.Color := clRed; 
end;

procedure TfrmTRXControl.btn40mClick(Sender: TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearButtonsColor; 
  mode := GetActualMode; 
  freq := GetFreqFromModeBand(2,mode);
  SetModeFreq(mode,freq);
  btn40m.Font.Color := clRed; 
end;

procedure TfrmTRXControl.btn6mClick(Sender: TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearButtonsColor; 
  mode := GetActualMode; 
  freq := GetFreqFromModeBand(9,mode);
  SetModeFreq(mode,freq);
  btn6m.Font.Color := clRed; 
end;

procedure TfrmTRXControl.btn70cmClick(Sender: TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearButtonsColor; 
  mode := GetActualMode; 
  freq := GetFreqFromModeBand(11,mode);
  SetModeFreq(mode,freq);
  btn70cm.Font.Color := clRed; 
end;

procedure TfrmTRXControl.btn80mClick(Sender: TObject);
var
  freq : String = '';
  mode : String = '';
begin
  ClearButtonsColor; 
  mode := GetActualMode; 
  freq := GetFreqFromModeBand(1,mode);
  SetModeFreq(mode,freq);
  btn80m.Font.Color := clRed; 
end;

procedure TfrmTRXControl.btnAMClick(Sender: TObject);
begin
  SetMode('AM',GetBandWidth('AM'))
end;

procedure TfrmTRXControl.btnCWClick(Sender: TObject);
begin
  SetMode('CW',GetBandWidth('CW'))
end;

procedure TfrmTRXControl.btnFMClick(Sender: TObject);
begin
  SetMode('FM',GetBandWidth('FM'))
end;

procedure TfrmTRXControl.btnRTTYClick(Sender: TObject);
begin
  SetMode('RTTY',GetBandWidth('RTTY'))
end;

procedure TfrmTRXControl.btnSSBClick(Sender: TObject);
var
  tmp : Currency;
begin
  if not TryStrToCurr(lblFreq.Caption,tmp) then
    SetMode('LSB',GetBandWidth('SSB'))
  else begin
    if (tmp > 5) and (tmp < 6) then
      SetMode('USB',GetBandWidth('SSB'))
    else begin
      if tmp > 10 then
        SetMode('USB',GetBandWidth('SSB'))
      else
        SetMode('LSB',GetBandWidth('SSB'))
    end
  end
end;

procedure TfrmTRXControl.rbRadio1Click(Sender: TObject);
begin
  InicializeRig
end;

procedure TfrmTRXControl.rbRadio2Click(Sender: TObject);
begin
  InicializeRig
end;

procedure TfrmTRXControl.tmrRadioTimer(Sender : TObject);
begin
  SynTRX
end;

procedure TfrmTRXControl.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  if Assigned(thRig) then
    thRig.Terminate;
  dmUtils.SaveWindowPos(frmTRXControl);
end;

procedure TfrmTRXControl.acAddModMemExecute(Sender: TObject);
begin
  frmRadioMemories := TfrmRadioMemories.Create(frmTRXControl);
  try
    dmData.LoadFreqMemories(frmRadioMemories.sgrdMem);
    frmRadioMemories.ShowModal;
    if frmRadioMemories.ModalResult = mrOK then
    begin
      dmData.StoreFreqMemories(frmRadioMemories.sgrdMem)
    end
  finally
    FreeAndNil(frmRadioMemories)
  end
end;

procedure TfrmTRXControl.btnMemDwnClick(Sender: TObject);
var
  freq      : Double;
  mode      : String;
  bandwidth : Integer;
begin
  dmData.GetNextFreqFromMem(freq,mode,bandwidth);
  if freq > 0 then
    SetFreqModeBandWidth(freq,mode,bandwidth)
end;

procedure TfrmTRXControl.btnMemUpClick(Sender: TObject);
var
  freq      : Double;
  mode      : String;
  bandwidth : Integer;
begin
  dmData.GetPreviousFreqFromMem(freq,mode,bandwidth);
  if freq > 0 then
    SetFreqModeBandWidth(freq,mode,bandwidth)
end;

procedure TfrmTRXControl.FormCloseQuery(Sender : TObject; var CanClose : boolean
  );
begin
  if Assigned(radio) then
    FreeAndNil(radio)
end;

procedure TfrmTRXControl.FormCreate(Sender: TObject);
begin
  //Running := False;
  //InitCriticalSection(RigCrit);
  //InitCriticalSection(RigRel);
  Radio := nil;
  thRig := nil;
  AutoMode := True
end;

procedure TfrmTRXControl.FormDestroy(Sender: TObject);
begin
  if dmData.DebugLevel>=1 then Writeln('Closing TRXControl window');
  //DoneCriticalsection(RigCrit);
  //DoneCriticalsection(RigRel)
end;

procedure TfrmTRXControl.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Shift = [ssAlt]) and (key = VK_F) then
  begin
    dmUtils.EnterFreq;
    key := 0;
  end
end;

procedure TfrmTRXControl.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key= VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0
  end
end;

function TfrmTRXControl.InicializeRig : Boolean;
var
  n      : String = '';
  id     : Integer = 0;
  port   : Integer;
  poll   : Integer;
begin
  if Assigned(radio) then
  begin
    FreeAndNil(radio);
  end;

  Application.ProcessMessages;
  Sleep(500);

  tmrRadio.Enabled := False;

  if rbRadio1.Checked then
    n := '1'
  else
    n := '2';

  radio := TRigControl.Create;

  if (dmData.DebugLevel>0) or cqrini.ReadBool('TRX','Debug',False) then
    radio.DebugMode := True;

  if not TryStrToInt(cqrini.ReadString('TRX'+n,'model',''),id) then
    radio.RigId := 1
  else
    radio.RigId := id;

  //broken configuration caused crash because RigCtldPort was empty
  //probably late to change it to Integer, I have no idea if the current
  //setting would be converted automatically or user has to do it again :(
  if not TryStrToInt(cqrini.ReadString('TRX'+n,'RigCtldPort','4532'),port) then
    port := 4532;

  if not TryStrToInt(cqrini.ReadString('TRX'+n,'poll','500'),poll) then
    poll := 500;

  radio.RigCtldPath := cqrini.ReadString('TRX','RigCtldPath','/usr/bin/rigctld');
  radio.RigCtldArgs := dmUtils.GetRadioRigCtldCommandLine(StrToInt(n));
  radio.RunRigCtld  := cqrini.ReadBool('TRX'+n,'RunRigCtld',False);
  radio.RigDevice   := cqrini.ReadString('TRX'+n,'device','');
  radio.RigCtldPort := port;
  radio.RigCtldHost := cqrini.ReadString('TRX'+n,'host','localhost');
  radio.RigPoll     := poll;
  radio.RigSendCWR  := cqrini.ReadBool('TRX'+n,'CWR',False);

  tmrRadio.Interval := radio.RigPoll;
  tmrRadio.Enabled  := True;
  Result := True;

  if not radio.Connected then
  begin
    FreeAndNil(radio)
  end
end;

procedure TfrmTRXControl.SetMode(mode : String;bandwidth :Integer);
var
  rmode : TRigMode;
begin
  if Assigned(radio) then
  begin
    rmode.mode := mode;
    rmode.pass := bandwidth;
    radio.SetModePass(rmode)
  end;
  {
  if not Running then
    exit;
  EnterCriticalsection(RigCrit);
  try
    set_width := bandwidth;
    set_mode  := mode
  finally
    LeaveCriticalsection(RigCrit)
  end
  }
end;

function TfrmTRXControl.GetFreqFromModeBand(band : Integer; smode : String) : String;
var
  freq : Currency = 0;
  mode   : Integer = 0;
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
    0 : begin
          case mode of
            0 : freq := cqrini.ReadFloat('DefFreq','160cw',1830);
            1 : freq := cqrini.ReadFloat('DefFreq','160ssb',1830);
            2 : freq := cqrini.ReadFloat('DefFreq','160rtty',1845);
            3 : freq := cqrini.ReadFloat('DefFreq','160am',1845);
            4 : freq := cqrini.ReadFloat('DefFreq','160fm',1845);
          end //case
        end;

    1 : begin
          case mode of
            0 : freq := cqrini.ReadFloat('DefFreq','80cw',3525);
            1 : freq := cqrini.ReadFloat('DefFreq','80ssb',3750);
            2 : freq := cqrini.ReadFloat('DefFreq','80rtty',3590);
            3 : freq := cqrini.ReadFloat('DefFreq','80am',3750);
            4 : freq := cqrini.ReadFloat('DefFreq','80fm',3750);
          end //case
        end;

    2 : begin
          case mode of
            0 : freq := cqrini.ReadFloat('DefFreq','40cw',7015);
            1 : freq := cqrini.ReadFloat('DefFreq','40ssb',7080);
            2 : freq := cqrini.ReadFloat('DefFreq','40rtty',7040);
            3 : freq := cqrini.ReadFloat('DefFreq','40am',7080);
            4 : freq := cqrini.ReadFloat('DefFreq','40fm',7080);
          end //case
        end;

    3 : begin
          case mode of
            0 : freq := cqrini.ReadFloat('DefFreq','30cw',10110);
            1 : freq := cqrini.ReadFloat('DefFreq','30ssb',10130);
            2 : freq := cqrini.ReadFloat('DefFreq','30rtty',10130);
            3 : freq := cqrini.ReadFloat('DefFreq','30am',10130);
            4 : freq := cqrini.ReadFloat('DefFreq','30fm',10130);
          end //case
        end;

    4 : begin
          case mode of
            0 : freq := cqrini.ReadFloat('DefFreq','20cw',14025);
            1 : freq := cqrini.ReadFloat('DefFreq','20ssb',14195);
            2 : freq := cqrini.ReadFloat('DefFreq','20rtty',14090);
            3 : freq := cqrini.ReadFloat('DefFreq','20am',14195);
            4 : freq := cqrini.ReadFloat('DefFreq','20fm',14195);
          end //case
        end;

    5 : begin
          case mode of
            0 : freq := cqrini.ReadFloat('DefFreq','17cw',18080);
            1 : freq := cqrini.ReadFloat('DefFreq','17ssb',18140);
            2 : freq := cqrini.ReadFloat('DefFreq','17rtty',18110);
            3 : freq := cqrini.ReadFloat('DefFreq','17am',18140);
            4 : freq := cqrini.ReadFloat('DefFreq','17fm',18140);
          end //case
        end;

    6 : begin
          case mode of
            0 : freq := cqrini.ReadFloat('DefFreq','15cw',21025);
            1 : freq := cqrini.ReadFloat('DefFreq','15ssb',21255);
            2 : freq := cqrini.ReadFloat('DefFreq','15rtty',21090);
            3 : freq := cqrini.ReadFloat('DefFreq','15am',21255);
            4 : freq := cqrini.ReadFloat('DefFreq','15fm',21255);
          end //case
        end;

    7 : begin
          case mode of
            0 : freq := cqrini.ReadFloat('DefFreq','12cw',24895);
            1 : freq := cqrini.ReadFloat('DefFreq','12ssb',24925);
            2 : freq := cqrini.ReadFloat('DefFreq','12rtty',24910);
            3 : freq := cqrini.ReadFloat('DefFreq','12am',24925);
            4 : freq := cqrini.ReadFloat('DefFreq','12fm',24925);
          end //case
        end;

    8 : begin
          case mode of
            0 : freq := cqrini.ReadFloat('DefFreq','10cw',28025);
            1 : freq := cqrini.ReadFloat('DefFreq','10ssb',28550);
            2 : freq := cqrini.ReadFloat('DefFreq','10rtty',28090);
            3 : freq := cqrini.ReadFloat('DefFreq','10am',28550);
            4 : freq := cqrini.ReadFloat('DefFreq','10fm',28550);
          end //case
        end;

    9 : begin
          case mode of
            0 : freq := cqrini.ReadFloat('DefFreq','6cw',50090);
            1 : freq := cqrini.ReadFloat('DefFreq','6ssb',51300);
            2 : freq := cqrini.ReadFloat('DefFreq','6rtty',51300);
            3 : freq := cqrini.ReadFloat('DefFreq','6am',51300);
            4 : freq := cqrini.ReadFloat('DefFreq','6fm',51300);
          end //case
        end;

   10 : begin
          case mode of
            0 : freq := cqrini.ReadFloat('DefFreq','2cw',144050);
            1 : freq := cqrini.ReadFloat('DefFreq','2ssb',144300);
            2 : freq := cqrini.ReadFloat('DefFreq','2rtty',144300);
            3 : freq := cqrini.ReadFloat('DefFreq','2am',144300);
            4 : freq := cqrini.ReadFloat('DefFreq','2fm',145300);
          end //case
        end;

   11 : begin
          case mode of
            0 : freq := cqrini.ReadFloat('DefFreq','70cw',3525);
            1 : freq := cqrini.ReadFloat('DefFreq','70ssb',3750);
            2 : freq := cqrini.ReadFloat('DefFreq','70rtty',3590);
            3 : freq := cqrini.ReadFloat('DefFreq','70am',3750);
            4 : freq := cqrini.ReadFloat('DefFreq','70fm',3750);
          end //case
        end;

  end; //case
  if dmData.DebugLevel >=3 then
    Writeln(freq);
  Result := FloatToStr(freq);
  if dmData.DebugLevel >=3 then
    Writeln(Result)
end;

function TfrmTRXControl.GetActualMode : String;
begin
  if Assigned(radio) then
  begin
    Result := radio.GetModeOnly
  end
end;

procedure TfrmTRXControl.SetFreqModeBandWidth(freq : Double; mode : String; BandWidth : Integer);
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
        mode := 'LSB'
    end
  end;

  if Assigned(radio) then
  begin
    dmData.GetRXTXOffset(freq/1000,RXOffset,TXOffset);
    radio.RXOffset := RXOffset;
    radio.TXOffset := TXOffset;

    radio.SetFreqKHz(freq);
    if AutoMode then
    begin
      rmode.mode := mode;
      rmode.pass := BandWidth;
      radio.SetModePass(rmode)
    end
  end
end;

procedure TfrmTRXControl.SetModeFreq(mode,freq : String); //freq in kHz
var
  bandwidth : Integer = 0;
  f         : double = 0;
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
        mode := 'LSB'
    end
  end;

  SetFreqModeBandWidth(f,mode,bandwidth)
end;

function TfrmTRXControl.GetModeFreqNewQSO(var mode,freq : String) : Boolean;
begin
  Result := False;
  if not ((lblFreq.Caption = empty_freq) or (lblFreq.Caption = '')) then
    Result := True
  else
    exit;
  freq := lblFreq.Caption;
  mode := GetActualMode
end;

procedure TfrmTRXControl.SavePosition;
begin
  dmUtils.SaveWindowPos(frmTRXControl)
end;

procedure TfrmTRXControl.ClearButtonsColor;
begin 
  btn160m.Font.Color  := COLOR_WINDOWTEXT;
  btn80m.Font.Color   := COLOR_WINDOWTEXT; 
  btn40m.Font.Color   := COLOR_WINDOWTEXT; 
  btn30m.Font.Color   := COLOR_WINDOWTEXT; 
  btn20m.Font.Color   := COLOR_WINDOWTEXT; 
  btn17m.Font.Color   := COLOR_WINDOWTEXT; 
  btn15m.Font.Color   := COLOR_WINDOWTEXT; 
  btn12m.Font.Color   := COLOR_WINDOWTEXT;  
  btn10m.Font.Color   := COLOR_WINDOWTEXT; 
  btn6m.Font.Color    := COLOR_WINDOWTEXT; 
  btn2m.Font.Color    := COLOR_WINDOWTEXT; 
  btn70cm.Font.Color  := COLOR_WINDOWTEXT
end;

function TfrmTRXControl.GetModeBand(var mode,band : String) : Boolean;
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
    band := dmUtils.GetBandFromFreq(freq)
end;

procedure TfrmTRXControl.CloseRigs;
begin
  if dmData.DebugLevel > 0 then
    WriteLn('Closing rigs... ');

  if Assigned(radio) then
    FreeAndNil(radio)
end;

procedure TfrmTRXControl.UpdateModeButtons(mode : String);
begin
  btnCW.Font.Color    := COLOR_WINDOWTEXT;
  btnSSB.Font.Color   := COLOR_WINDOWTEXT;
  btnRTTY.Font.Color  := COLOR_WINDOWTEXT;
  btnAM.Font.Color    := COLOR_WINDOWTEXT;
  btnFM.Font.Color    := COLOR_WINDOWTEXT;
  if mode = 'CW' then
    btnCW.Font.Color := clRed
  else
    if mode = 'SSB' then
      btnSSB.Font.Color := clRed
     else
       if mode = 'RTTY' then
         btnRTTY.Font.Color := clRed
       else
         if mode = 'AM' then
           btnAM.Font.Color := clRed
         else
           if mode = 'FM' then
             btnFM.Font.Color := clRed
end;

procedure TfrmTRXControl.Split(Up : Integer);
{
var
  a : String = '';
  b : String = '';
  f : Double;
  v : String;
  }
begin
{
  f := StrToFloat(lblFreq.Caption)*1000000; //freq to Hz
  f := f + up;
  if mvfo = 'VFOA' then
    v := 'VFOB'
  else
    v := 'VFOB';
  if rbRadio1.Checked then
    TRX1.SetSplit(v,FloatToStr(f))
  else
    TRX2.SetSplit(v,FloatToStr(f))
  }
end;

procedure TfrmTRXControl.DisableSplit;
begin
  //if rbRadio1.Checked then
    //TRX1.DisableSplit
  //else
    //TRX2.DisableSplit
end;

function TfrmTRXControl.GetFreqHz  : Double;
begin
  if Assigned(radio) then
    Result := radio.GetFreqHz
  else
    Result := 0
end;

function TfrmTRXControl.GetFreqkHz : Double;
begin
  if Assigned(radio) then
    Result := radio.GetFreqKHz
  else
    Result := 0
end;

function TfrmTRXControl.GetFreqMHz : Double;
begin
  if Assigned(radio) then
    Result := radio.GetFreqMHz
  else
    Result := 0
end;

function TfrmTRXControl.GetDislayFreq : String;
begin
  if Assigned(radio) then
    Result := FormatFloat(empty_freq+';;',radio.GetFreqMHz)
  else
    Result := FormatFloat(empty_freq+';;',0)
end;

procedure TfrmTRXControl.ClearRIT;
begin
  if (lblFreq.Caption = empty_freq) then
    exit;
  radio.ClearRit
end;

procedure TfrmTRXControl.LoadButtonCaptions;
begin
  btn160m.Caption := cqrini.ReadString('DefFreq','160btn','160m');
  btn80m.Caption  := cqrini.ReadString('DefFreq','80btn','80m');
  btn40m.Caption  := cqrini.ReadString('DefFreq','40btn','40m');
  btn30m.Caption  := cqrini.ReadString('DefFreq','30btn','30m');
  btn20m.Caption  := cqrini.ReadString('DefFreq','20btn','20m');
  btn17m.Caption  := cqrini.ReadString('DefFreq','17btn','17m');
  btn15m.Caption  := cqrini.ReadString('DefFreq','15btn','15m');
  btn12m.Caption  := cqrini.ReadString('DefFreq','12btn','12m');
  btn10m.Caption  := cqrini.ReadString('DefFreq','10btn','10m');
  btn6m.Caption   := cqrini.ReadString('DefFreq','6btn','6m');
  btn2m.Caption   := cqrini.ReadString('DefFreq','2btn','2m');
  btn70cm.Caption := cqrini.ReadString('DefFreq','70btn','70cm')
end;

procedure TfrmTRXControl.SetDebugMode(DebugMode : Boolean);
begin
  if Assigned(radio) then
  begin
    radio.DebugMode := DebugMode
  end
end;

function TfrmTRXControl.GetRawMode : String;
begin
  if Assigned(radio) then
    Result := radio.GetRawMode
  else
    Result := ''
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

end.

