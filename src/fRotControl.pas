unit fRotControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, uMyIni, uRotControl, fNewQSO, LCLType, ComCtrls;

type

  { TfrmRotControl }

  TfrmRotControl = class(TForm)
    btnLongP: TButton;
    btnShortP: TButton;
    btnStop: TButton;
    GroupBox2: TGroupBox;
    lblAzmin: TLabel;
    lblAzimuth: TLabel;
    lblAzmax: TLabel;
    pnlBtns: TPanel;
    pbAz: TProgressBar;
    rbRotor1: TRadioButton;
    rbRotor2: TRadioButton;
    tmrRotor: TTimer;
    procedure btnShortPClick(Sender: TObject);
    procedure btnLongPClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure rbRotor1Click(Sender: TObject);
    procedure rbRotor2Click(Sender: TObject);
    procedure tmrRotorTimer(Sender: TObject);
  private
    { private declarations }
    rotor : TRotControl;
  public
    { public declarations }
    procedure SynROT;
    function  InicializeRot : Boolean;
    procedure UpdateAZdisp(Az,AzMin,AzMax:Double);
  end;

var
  frmRotControl: TfrmRotControl;

implementation
{$R *.lfm}

{ TfrmRotControl }

uses dUtils, dData;

procedure TfrmRotControl.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmRotControl);
  rbRotor1.Caption := cqrini.ReadString('ROT1','Desc','Rotor 1');
  rbRotor2.Caption := cqrini.ReadString('ROT2','Desc','Rotor 2')
end;

procedure TfrmRotControl.rbRotor1Click(Sender: TObject);
begin
  InicializeRot
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

procedure TfrmRotControl.FormDestroy(Sender: TObject);
begin
  if Assigned(rotor) then
    FreeAndNil(rotor)
end;

procedure TfrmRotControl.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key= VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0
  end
end;

procedure TfrmRotControl.btnShortPClick(Sender: TObject);
begin
   rotor.SetAzimuth(fNewQSO.Azimuth)
end;

procedure TfrmRotControl.btnLongPClick(Sender: TObject);
var
    LAzimuth : String = '';
    SAz : Double = 0 ;
    LAz : Double = 0 ;
begin
   SAz := StrToFloat(fNewQSO.Azimuth);
   if SAz >180 then
      LAz := SAz - 180
   else
      LAz := SAz + 180;
   Lazimuth := FloatToStr(LAz);
   rotor.SetAzimuth(LAzimuth)
end;

procedure TfrmRotControl.btnStopClick(Sender: TObject);
begin
  rotor.StopRot;
end;
procedure TfrmRotControl.UpdateAZdisp(Az,AzMin,AzMax:Double);
Begin
  lblAzMin.Caption:=FloatToStrF(AzMin, fffixed, 3, 0);
  lblAzMax.Caption:=FloatToStrF(AzMax, fffixed, 3, 0);
  pbAz.Min:=round(AzMin);
  pbAz.Max:=round(AzMax);
  pbAz.Smooth:=True;
  pbAz.Step:=1;
  pbAz.Enabled:=True;
  pbAz.Position:=round(Az);
end;

function TfrmRotControl.InicializeRot : Boolean;
var
  n      : String = '';
  id     : Integer = 0;
  port   : Integer;
  poll   : Integer;
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
  if dmData.DebugLevel>0 then
    rotor.DebugMode := True;
  if not TryStrToInt(cqrini.ReadString('ROT'+n,'model',''),id) then
    rotor.RotId := 1
  else
    rotor.RotId := id;

  //broken configuration caused crash because RotCtldPort was empty
  //probably late to change it to Integer, I have no idea if the current
  //setting would be converted automatically or user has to do it again :(
  if not TryStrToInt(cqrini.ReadString('ROT'+n,'RotCtldPort','4533'),port) then
    port := 4533;

  if not TryStrToInt(cqrini.ReadString('ROT'+n,'poll','500'),poll) then
    poll := 500;

  rotor.RotCtldPath := cqrini.ReadString('ROT','RotCtldPath','/usr/bin/rotctld');
  rotor.RotCtldArgs := dmUtils.GetRotorRotCtldCommandLine(StrToInt(n));
  rotor.RunRotCtld  := cqrini.ReadBool('ROT'+n,'RunRotCtld',False);
  rotor.RotDevice   := cqrini.ReadString('ROT'+n,'device','');
  rotor.RotCtldPort := port;
  rotor.RotCtldHost := cqrini.ReadString('ROT'+n,'host','localhost');
  rotor.RotPoll     := poll;

  tmrRotor.Interval := rotor.RotPoll;
  tmrRotor.Enabled  := True;
  Result := True;
  if not rotor.Connected then
  begin
    FreeAndNil(rotor)
  end
end;

procedure TfrmRotControl.SynROT;
var
  Az : Double ;
begin
  if Assigned(rotor) then
    Az := rotor.GetAzimut
  else
    Az := 0;
  lblAzimuth.Caption := FormatFloat(empty_azimuth+';;',Az)
end;

end.

