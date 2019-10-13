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
    chkContestname: TCheckBox;
    chkPropagation: TCheckBox;
    chkContestNrS: TCheckBox;
    chkContestMsgS: TCheckBox;
    chkContestNrR: TCheckBox;
    chkContestMsgR: TCheckBox;
    chkSatellite: TCheckBox;
    chkDistance: TCheckBox;
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
    cbxDateFormat: TComboBox;
    GroupBox1 : TGroupBox;
    lblDateFormat: TLabel;
    tgSplitRST_S: TToggleBox;
    tgSplitRST_R: TToggleBox;
    procedure btnOKClick(Sender : TObject);
    procedure FormShow(Sender : TObject);
    procedure tgSplit_Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmQSLExpPref : TfrmQSLExpPref;

implementation
{$R *.lfm}

uses uMyIni;

{ TfrmQSLExpPref }

procedure TfrmQSLExpPref.FormShow(Sender : TObject);
begin
  chkDate.Checked     := cqrini.ReadBool('QSLExport', 'Date', True);
  cbxDateFormat.ItemIndex:=cqrini.ReadInteger('QSLExport','DateFormat', 0);
  chkTimeOn.Checked   := cqrini.ReadBool('QSLExport', 'time_on', True);
  chkTimeOff.Checked  := cqrini.ReadBool('QSLExport', 'time_off', False);
  chkCallSign.Checked := cqrini.ReadBool('QSLExport', 'CallSign', True);
  chkMode.Checked     := cqrini.ReadBool('QSLExport', 'Mode', True);
  chkFreq.Checked     := cqrini.ReadBool('QSLExport', 'Freq', False);
  chkRST_S.Checked    := cqrini.ReadBool('QSLExport', 'RST_S', True);
  tgSplitRST_S.Checked:= cqrini.ReadBool('QSLExport', 'SplitRST_S', False);
  chkRST_R.Checked    := cqrini.ReadBool('QSLExport', 'RST_R', False);
  tgSplitRST_R.Checked:= cqrini.ReadBool('QSLExport', 'SplitRST_R', False);
  chkName.Checked     := cqrini.ReadBool('QSLExport', 'Name', False);
  chkQTH.Checked      := cqrini.ReadBool('QSLExport', 'QTH', False);
  chkBand.Checked     := cqrini.ReadBool('QSLExport', 'Band', True);
  chkPropagation.Checked := cqrini.ReadBool('QSLExport', 'Propagation', False);
  chkSatellite.Checked := cqrini.ReadBool('QSLExport', 'Satellite', False);
  chkContestname.Checked := cqrini.ReadBool('QSLExport', 'ContestName', False);
  chkQSL_S.Checked    := cqrini.ReadBool('QSLExport', 'QSL_S', False);
  chkQSL_R.Checked    := cqrini.ReadBool('QSLExport', 'QSL_R', False);
  chkQSL_VIA.Checked  := cqrini.ReadBool('QSLExport', 'QSL_VIA', True);
  chkLoc.Checked      := cqrini.ReadBool('QSLExport', 'Locator', False);
  chkMyLoc.Checked    := cqrini.ReadBool('QSLExport', 'MyLoc', False);
  chkDistance.Checked := cqrini.ReadBool('QSLExport', 'Distance', False);
  chkIOTA.Checked     := cqrini.ReadBool('QSLExport', 'IOTA', False);
  chkAward.Checked    := cqrini.ReadBool('QSLExport', 'Award', False);
  chkPower.Checked    := cqrini.ReadBool('QSLExport', 'Power', False);
  chkRemarks.Checked  := cqrini.ReadBool('QSLExport', 'Remarks', True);
  chkQSLMsg.Checked   := cqrini.ReadBool('QSLExport', 'QSLMsg', True);
  chkContestNrS.Checked := cqrini.ReadBool('QSLExport', 'ContestNrS',False );
  chkContestMsgS.Checked := cqrini.ReadBool('QSLExport', 'ContestMsgS',False );
  chkContestNrR.Checked := cqrini.ReadBool('QSLExport', 'ContestNrR', False);
  chkContestMsgR.Checked := cqrini.ReadBool('QSLExport', 'ContestMsgR', False);
  tgSplit_Click(Sender);
end;

procedure TfrmQSLExpPref.tgSplit_Click(Sender: TObject);
begin
  if tgSplitRST_S.Checked = True then
    begin
      tgSplitRST_S.Font.Color := clGreen;
      tgSplitRST_S.Font.Style :=[fsBold];
    end
  else
   begin
      tgSplitRST_S.Font.Color := clDefault;
      tgSplitRST_S.Font.Style :=[];
    end;
  if tgSplitRST_R.Checked = True then
    begin
      tgSplitRST_R.Font.Color := clGreen;
      tgSplitRST_R.Font.Style :=[fsBold];
    end
  else
   begin
      tgSplitRST_R.Font.Color := clDefault;
      tgSplitRST_R.Font.Style :=[];
    end;
end;

procedure TfrmQSLExpPref.btnOKClick(Sender : TObject);
begin
  cqrini.WriteBool('QSLExport', 'Date', chkDate.Checked);
  cqrini.WriteInteger('QSLExport','DateFormat', cbxDateFormat.ItemIndex);
  cqrini.WriteBool('QSLExport', 'time_on', chkTimeOn.Checked);
  cqrini.WriteBool('QSLExport', 'time_off', chkTimeOff.Checked);
  cqrini.WriteBool('QSLExport', 'CallSign', chkCallSign.Checked);
  cqrini.WriteBool('QSLExport', 'Mode', chkMode.Checked);
  cqrini.WriteBool('QSLExport', 'Freq', chkFreq.Checked);
  cqrini.WriteBool('QSLExport', 'RST_S', chkRST_S.Checked);
  cqrini.WriteBool('QSLExport', 'SplitRST_S',tgSplitRST_S.Checked);
  cqrini.WriteBool('QSLExport', 'RST_R', chkRST_R.Checked);
  cqrini.WriteBool('QSLExport', 'SplitRST_R',tgSplitRST_R.Checked);
  cqrini.WriteBool('QSLExport', 'Name', chkName.Checked);
  cqrini.WriteBool('QSLExport', 'QTH', chkQTH.Checked);
  cqrini.WriteBool('QSLExport', 'Band', chkBand.Checked);
  cqrini.WriteBool('QSLExport', 'Propagation', chkPropagation.Checked);
  cqrini.WriteBool('QSLExport', 'Satellite', chkSatellite.Checked);
  cqrini.WriteBool('QSLExport', 'ContestName', chkContestname.Checked);
  cqrini.WriteBool('QSLExport', 'QSL_S', chkQSL_S.Checked);
  cqrini.WriteBool('QSLExport', 'QSL_R', chkQSL_R.Checked);
  cqrini.WriteBool('QSLExport', 'QSL_VIA', chkQSL_VIA.Checked);
  cqrini.WriteBool('QSLExport', 'Locator', chkLoc.Checked);
  cqrini.WriteBool('QSLExport', 'MyLoc', chkMyLoc.Checked);
  cqrini.WriteBool('QSLExport', 'Distance', chkDistance.Checked);
  cqrini.WriteBool('QSLExport', 'IOTA', chkIOTA.Checked);
  cqrini.WriteBool('QSLExport', 'Award', chkAward.Checked);
  cqrini.WriteBool('QSLExport', 'Power', chkPower.Checked);
  cqrini.WriteBool('QSLExport', 'Remarks', chkRemarks.Checked);
  cqrini.WriteBool('QSLExport', 'QSLMsg', chkQSLMsg.Checked);
  cqrini.WriteBool('QSLExport', 'ContestNrS', chkContestNrS.Checked);
  cqrini.WriteBool('QSLExport', 'ContestMsgS', chkContestMsgS.Checked);
  cqrini.WriteBool('QSLExport', 'ContestNrR', chkContestNrR.Checked);
  cqrini.WriteBool('QSLExport', 'ContestMsgR', chkContestMsgR.Checked);
  cqrini.SaveToDisk;
  ModalResult := mrOK
end;

end.

