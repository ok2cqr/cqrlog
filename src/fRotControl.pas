unit fRotControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, uMyIni, uRotControl, fNewQSO, LCLType, ComCtrls, Menus,
  EditBtn;

type

  { TfrmRotControl }

  TfrmRotControl = class(TForm)
    btnLeft: TButton;
    btnLongP: TButton;
    btnRight: TButton;
    btnShortP: TButton;
    btnStop: TButton;
    edtBAzimuth: TEditButton;
    gbAzimuth: TGroupBox;
    lblAzimuth: TLabel;
    lblAzmax: TLabel;
    lblAzmin: TLabel;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    mnuMinMax: TMenuItem;
    mnuDirbtns: TMenuItem;
    mnuStopbtn: TMenuItem;
    mnuPreferences: TMenuItem;
    pbAz: TProgressBar;
    pnlMinMax: TPanel;
    pnlBtns: TPanel;
    rbRotor1: TRadioButton;
    rbRotor2: TRadioButton;
    tmrStopRot: TTimer;
    tmrRotor: TTimer;
    procedure btnLeftClick(Sender: TObject);
    procedure btnRightClick(Sender: TObject);
    procedure btnShortPClick(Sender: TObject);
    procedure btnLongPClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure edtBAzimuthButtonClick(Sender: TObject);
    procedure edtBAzimuthClick(Sender: TObject);
    procedure edtBAzimuthKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure lblAzimuthClick(Sender: TObject);
    procedure mnuDirbtnsClick(Sender: TObject);
    procedure mnuMinMaxClick(Sender: TObject);
    procedure mnuPreferencesClick(Sender: TObject);
    procedure mnuStopbtnClick(Sender: TObject);
    procedure rbRotor1Click(Sender: TObject);
    procedure rbRotor2Click(Sender: TObject);
    procedure tmrRotorTimer(Sender: TObject);
    procedure tmrStopRotTimer(Sender: TObject);
  private
    { private declarations }
    rotor : TRotControl;
  public
    { public declarations }
    procedure SynROT;
    function  InicializeRot : Boolean;
    procedure UpdateAZdisp(Az,AzMin,AzMax:Double;UseState:Boolean);
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
  rbRotor2.Caption := cqrini.ReadString('ROT2','Desc','Rotor 2');
  btnLeft.Visible:=cqrini.ReadBool('ROT','DirBtns',False);
  btnRight.Visible:=cqrini.ReadBool('ROT','DirBtns',False);
  mnuDirBtns.Checked:=cqrini.ReadBool('ROT','DirBtns',False);;
  pnlMinMax.Visible:=cqrini.ReadBool('ROT','MinMax',False);
  mnuMinMax.Checked:=cqrini.ReadBool('ROT','MinMax',False);;
  btnStop.Visible:=cqrini.ReadBool('ROT','Stopbtn',False);
  mnuStopbtn.Checked:=cqrini.ReadBool('ROT','Stopbtn',False);
  if pnlMinMax.Visible then gbAzimuth.Height:=70;
end;

procedure TfrmRotControl.lblAzimuthClick(Sender: TObject);

begin
  lblAzimuth.Visible:=false;
  edtBAzimuth.Visible:=true;
end;

procedure TfrmRotControl.edtBAzimuthButtonClick(Sender: TObject);
var
   Az    :integer=-999;
begin
   Try
        Az:= StrToInt(edtBAzimuth.Text);
   except
        On E : EConvertError do
          Az:=-999;
   end;
     if ((Az>=0) and (Az<=360)) then
        rotor.SetAzimuth(edtBAzimuth.Text);

   lblAzimuth.Visible:=true;
   edtBAzimuth.Visible:=false;
   edtBAzimuth.MaxLength:=0;
   edtBAzimuth.Text:='Az? (0-360)';
end;

procedure TfrmRotControl.edtBAzimuthClick(Sender: TObject);
begin
   edtBAzimuth.SetFocus;
   edtBAzimuth.text:='';
   edtBAzimuth.NumbersOnly:=True;
   edtBAzimuth.MaxLength:=3;
end;

procedure TfrmRotControl.edtBAzimuthKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key=VK_Return then edtBAzimuthButtonClick(nil);
end;

procedure TfrmRotControl.mnuDirbtnsClick(Sender: TObject);
begin
   mnuDirbtns.Checked:= not mnuDirbtns.Checked;
   btnLeft.Visible:=mnuDirbtns.Checked;
   btnRight.Visible:=mnuDirbtns.Checked;
   cqrini.WriteBool('ROT','DirBtns',mnuDirbtns.Visible);
end;

procedure TfrmRotControl.mnuMinMaxClick(Sender: TObject);
begin
  mnuMinMax.Checked:= not mnuMinMax.Checked;
  if mnuMinMax.Checked then gbAzimuth.Height:=70 else gbAzimuth.Height:=50;
  pnlMinMax.Visible:=mnuMinMax.Checked;
  cqrini.WriteBool('ROT','MinMax',pnlMinMax.Visible);
end;

procedure TfrmRotControl.mnuPreferencesClick(Sender: TObject);
begin
  cqrini.WriteInteger('Pref', 'ActPageIdx', 6);  //set RotConrol tab active. Number may change if preferences page change
  frmNewQSO.acPreferences.Execute
end;

procedure TfrmRotControl.mnuStopbtnClick(Sender: TObject);
begin
  mnuStopbtn.Checked:= not  mnuStopbtn.Checked;
  btnStop.Visible:=mnuStopbtn.Checked;
  cqrini.WriteBool('ROT','Stopbtn',btnStop.Visible);
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
   if fNewQSO.Azimuth<>'' then
      rotor.SetAzimuth(fNewQSO.Azimuth)
end;
procedure TfrmRotControl.btnLongPClick(Sender: TObject);
var
    LAzimuth : String = '';
    SAz : Double = 0 ;
    LAz : Double = 0 ;
begin
   if fNewQSO.Azimuth<>'' then
   begin
     SAz := StrToFloat(fNewQSO.Azimuth);
     if SAz >180 then
        LAz := SAz - 180
     else
        LAz := SAz + 180;
     Lazimuth := FloatToStr(LAz);
     rotor.SetAzimuth(LAzimuth)
   end;
end;
procedure TfrmRotControl.btnLeftClick(Sender: TObject);
begin
   rotor.StopRot;
   tmrStopRot.Enabled:=False;
   sleep(100);
   Application.ProcessMessages;
   rotor.LeftRot;
   tmrStopRot.Enabled:=True;
   btnLeft.Font.Color:=clGreen;
   btnLeft.Font.Style:=btnLeft.Font.Style+[fsBold];
   btnLeft.Repaint;
   btnRight.Font.Color:=clDefault;
   btnRight.Font.Style:=btnRight.Font.Style-[fsBold];
   btnRight.Repaint;
end;

procedure TfrmRotControl.btnRightClick(Sender: TObject);
begin
   rotor.StopRot;
   tmrStopRot.Enabled:=False;
   sleep(100);
   Application.ProcessMessages;
   rotor.RightRot;
   tmrStopRot.Enabled:=True;
   btnRight.Font.Color:=clGreen;
   btnRight.Font.Style:=btnRight.Font.Style+[fsBold];
   btnRight.Repaint;
   btnLeft.Font.Color:=clDefault;
   btnLeft.Font.Style:=btnLeft.Font.Style-[fsBold];
   btnLeft.Repaint;
end;

procedure TfrmRotControl.btnStopClick(Sender: TObject);
begin
  btnStop.Font.Color:=clRed;
  btnStop.Font.Style:=btnStop.Font.Style+[fsBold];
  btnStop.Repaint;

  tmrStopRot.Enabled:=False;
  rotor.StopRot;
  btnLeft.Font.Color:=clDefault;
  btnLeft.Font.Style:=btnLeft.Font.Style-[fsBold];
  btnLeft.Repaint;
  btnRight.Font.Color:=clDefault;
  btnRight.Font.Style:=btnRight.Font.Style-[fsBold];
  btnRight.Repaint;
  Application.ProcessMessages;
  sleep(300);
  Application.ProcessMessages;
  btnStop.Font.Color:=clDefault;
  btnStop.Font.Style:=btnStop.Font.Style-[fsBold];
  btnStop.Repaint;
end;

procedure TfrmRotControl.tmrStopRotTimer(Sender: TObject);
begin
  btnStopClick(nil);
end;
procedure TfrmRotControl.UpdateAZdisp(Az,AzMin,AzMax:Double;UseState:boolean);
Begin
  lblAzMin.Caption:=FloatToStrF(AzMin, fffixed, 3, 0);
  lblAzMax.Caption:=FloatToStrF(AzMax, fffixed, 3, 0);
  pbAz.Min:=round(AzMin);
  pbAz.Max:=round(AzMax);
  pbAz.Smooth:=True;
  pbAz.Step:=1;
  pbAz.Enabled:=True;
  if (UseState and (AzMin<0 ) and (az>180)) then az := az-360;

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

