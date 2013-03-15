unit fQSLExpPref;

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,FileUtil,LResources,Forms,Controls,Graphics,Dialogs,StdCtrls;

type

  { TfrmQSLExpPref }

  TfrmQSLExpPref = class(TForm)
    btnOK : TButton;
    btnCancel : TButton;
    chkQSLMsg : TCheckBox;
    chkBand : TCheckBox;
    chkAward : TCheckBox;
    chkCallSign : TCheckBox;
    chkDate : TCheckBox;
    chkFreq : TCheckBox;
    chkIOTA : TCheckBox;
    chkLoc : TCheckBox;
    chkMode : TCheckBox;
    chkMyLoc : TCheckBox;
    chkName : TCheckBox;
    chkPower : TCheckBox;
    chkQSL_R : TCheckBox;
    chkQSL_S : TCheckBox;
    chkQSL_VIA : TCheckBox;
    chkQTH : TCheckBox;
    chkRemarks : TCheckBox;
    chkRST_R : TCheckBox;
    chkRST_S : TCheckBox;
    chkTimeOff : TCheckBox;
    chkTimeOn : TCheckBox;
    GroupBox1 : TGroupBox;
    procedure btnOKClick(Sender : TObject);
    procedure FormShow(Sender : TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmQSLExpPref : TfrmQSLExpPref;

implementation

uses uMyIni;

{ TfrmQSLExpPref }

procedure TfrmQSLExpPref.FormShow(Sender : TObject);
begin
  chkDate.Checked     := cqrini.ReadBool('QSLExport', 'Date', True);
  chkTimeOn.Checked   := cqrini.ReadBool('QSLExport', 'time_on', True);
  chkTimeOff.Checked  := cqrini.ReadBool('QSLExport', 'time_off', False);
  chkCallSign.Checked := cqrini.ReadBool('QSLExport', 'CallSign', True);
  chkMode.Checked     := cqrini.ReadBool('QSLExport', 'Mode', True);
  chkFreq.Checked     := cqrini.ReadBool('QSLExport', 'Freq', False);
  chkRST_S.Checked    := cqrini.ReadBool('QSLExport', 'RST_S', True);
  chkRST_R.Checked    := cqrini.ReadBool('QSLExport', 'RST_R', False);
  chkName.Checked     := cqrini.ReadBool('QSLExport', 'Name', False);
  chkQTH.Checked      := cqrini.ReadBool('QSLExport', 'QTH', False);
  chkBand.Checked     := cqrini.ReadBool('QSLExport', 'Band', True);
  chkQSL_S.Checked    := cqrini.ReadBool('QSLExport', 'QSL_S', False);
  chkQSL_R.Checked    := cqrini.ReadBool('QSLExport', 'QSL_R', False);
  chkQSL_VIA.Checked  := cqrini.ReadBool('QSLExport', 'QSL_VIA', True);
  chkLoc.Checked      := cqrini.ReadBool('QSLExport', 'Locator', False);
  chkMyLoc.Checked    := cqrini.ReadBool('QSLExport', 'MyLoc', False);
  chkIOTA.Checked     := cqrini.ReadBool('QSLExport', 'IOTA', False);
  chkAward.Checked    := cqrini.ReadBool('QSLExport', 'Award', False);
  chkPower.Checked    := cqrini.ReadBool('QSLExport', 'Power', False);
  chkRemarks.Checked  := cqrini.ReadBool('QSLExport', 'Remarks', True);
  chkQSLMsg.Checked   := cqrini.ReadBool('QSLExport', 'QSLMsg', True);
end;

procedure TfrmQSLExpPref.btnOKClick(Sender : TObject);
begin
  cqrini.WriteBool('QSLExport', 'Date', chkDate.Checked);
  cqrini.WriteBool('QSLExport', 'time_on', chkTimeOn.Checked);
  cqrini.WriteBool('QSLExport', 'time_off', chkTimeOff.Checked);
  cqrini.WriteBool('QSLExport', 'CallSign', chkCallSign.Checked);
  cqrini.WriteBool('QSLExport', 'Mode', chkMode.Checked);
  cqrini.WriteBool('QSLExport', 'Freq', chkFreq.Checked);
  cqrini.WriteBool('QSLExport', 'RST_S', chkRST_S.Checked);
  cqrini.WriteBool('QSLExport', 'RST_R', chkRST_R.Checked);
  cqrini.WriteBool('QSLExport', 'Name', chkName.Checked);
  cqrini.WriteBool('QSLExport', 'QTH', chkQTH.Checked);
  cqrini.WriteBool('QSLExport', 'Band', chkBand.Checked);
  cqrini.WriteBool('QSLExport', 'QSL_S', chkQSL_S.Checked);
  cqrini.WriteBool('QSLExport', 'QSL_R', chkQSL_R.Checked);
  cqrini.WriteBool('QSLExport', 'QSL_VIA', chkQSL_VIA.Checked);
  cqrini.WriteBool('QSLExport', 'Locator', chkLoc.Checked);
  cqrini.WriteBool('QSLExport', 'MyLoc', chkMyLoc.Checked);
  cqrini.WriteBool('QSLExport', 'IOTA', chkIOTA.Checked);
  cqrini.WriteBool('QSLExport', 'Award', chkAward.Checked);
  cqrini.WriteBool('QSLExport', 'Power', chkPower.Checked);
  cqrini.WriteBool('QSLExport', 'Remarks', chkRemarks.Checked);
  cqrini.WriteBool('QSLExport', 'QSLMsg', chkQSLMsg.Checked);
  ModalResult := mrOK
end;


initialization
  {$I fQSLExpPref.lrs}

end.

