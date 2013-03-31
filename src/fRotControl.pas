unit fRotControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, uMyIni, uRotControl, fNewQSO;

type

  { TfrmRotControl }

  TfrmRotControl = class(TForm)
    ButtonShortP: TButton;
    GroupBox2: TGroupBox;
    lblAzimuth: TLabel;
    rbRotor1: TRadioButton;
    rbRotor2: TRadioButton;
    tmrRotor: TTimer;
    procedure ButtonShortPClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure rbRotor1Change(Sender: TObject);
    procedure rbRotor1Click(Sender: TObject);
    procedure rbRotor2Change(Sender: TObject);
    procedure rbRotor2Click(Sender: TObject);
    procedure tmrRotorTimer(Sender: TObject);
  private
    { private declarations }
    rotor : TRotControl;
  public
    { public declarations }
    procedure SynROT;
    function  InicializeRot : Boolean;
  end;

var
  frmRotControl: TfrmRotControl;

implementation

{ TfrmRotControl }

uses dUtils;

procedure TfrmRotControl.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmRotControl);
  rbRotor1.Caption := cqrini.ReadString('ROT1','Desc','Rotor 1');
  rbRotor2.Caption := cqrini.ReadString('ROT2','Desc','Rotor 2')
end;

procedure TfrmRotControl.rbRotor1Change(Sender: TObject);
begin

end;

procedure TfrmRotControl.rbRotor1Click(Sender: TObject);
begin
  InicializeRot
end;

procedure TfrmRotControl.rbRotor2Change(Sender: TObject);
begin

end;

procedure TfrmRotControl.rbRotor2Click(Sender: TObject);
begin
  InicializeRot
end;

procedure TfrmRotControl.tmrRotorTimer(Sender: TObject);
begin
  SynROT
end;

procedure TfrmRotControl.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
   dmUtils.SaveWindowPos(frmRotControl);
end;

procedure TfrmRotControl.ButtonShortPClick(Sender: TObject);
begin
   rotor.SetAzimuth(fNewQSO.Azimuth)
end;

function TfrmRotControl.InicializeRot : Boolean;
var
  n      : String = '';
  id     : Integer = 0;
  Resume : Boolean = False;
begin
  if Assigned(rotor) then
  begin
    FreeAndNil(rotor);
  end;
  Application.ProcessMessages;
  Sleep(500);

  tmrRotor.Enabled := False;

  if rbRotor1.Checked then
    n := '1'
  else
    n := '2';

  rotor := TRotControl.Create;

  rotor.DebugMode := True;
  if not TryStrToInt(cqrini.ReadString('ROT'+n,'model',''),id) then
    rotor.RotId := 1
  else
    rotor.RotId := id;
  rotor.RotCtldPath := cqrini.ReadString('ROT','RigCtldPath','/usr/bin/rotctld');
  rotor.RotCtldArgs := dmUtils.GetRotorRotCtldCommandLine(StrToInt(n));
  rotor.RunRotCtld  := cqrini.ReadBool('ROT'+n,'RunRotCtld',False);
  rotor.RotDevice   := cqrini.ReadString('ROT'+n,'device','');
  rotor.RotCtldPort := StrToInt(cqrini.ReadString('ROT'+n,'RotCtldPort','4533'));
  rotor.RotCtldHost := cqrini.ReadString('ROT'+n,'host','localhost');
  rotor.RotPoll     := StrToInt(cqrini.ReadString('ROT'+n,'poll','500'));

  tmrRotor.Interval := rotor.RotPoll;
  tmrRotor.Enabled  := True;
  if not rotor.Connected then
  begin
    FreeAndNil(rotor);
  end;
end;

procedure TfrmRotControl.SynROT;
var
  Az : Double ;
begin
  if Assigned(rotor) then
    Az := rotor.GetAzimut
  else
    Az := 0;
  lblAzimuth.Caption := FormatFloat(empty_azimuth+';;',Az);
{  UpdateModeButtons(m);
  ClearButtonsColor;
  if f = 0 then
    exit;
  b := dmUtils.GetBandFromFreq(lblAzimuth.Caption);
  if b = '160M' then
    btn160m.Font.Color := clRed
  else if b = '80M' then
    btn80m.Font.Color  := clRed
  else if b = '40M' then
    btn40m.Font.Color  := clRed
  else if b = '30M' then
    btn30m.Font.Color  := clRed
  else if b = '20M' then
    btn20m.Font.Color  := clRed
  else if b = '17M' then
    btn17m.Font.Color  := clRed
  else if b = '15M' then
    btn15m.Font.Color  := clRed
  else if b = '12M' then
    btn12m.Font.Color  := clRed
  else if b = '10M' then
    btn10m.Font.Color  := clRed
  else if b = '6M' then
    btn6m.Font.Color   := clRed
  else if b = '2M' then
    btn2m.Font.Color   := clRed
  else if b = '70CM' then
    btn70cm.Font.Color := clRed }
end;

initialization
  {$I fRotControl.lrs}

end.

