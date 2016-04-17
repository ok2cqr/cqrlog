unit frExportPref;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, StdCtrls;

type

  { TfraExportPref }

  TfraExportPref = class(TFrame)
    chkexAward : TCheckBox;
    chkexCall : TCheckBox;
    chkExCont : TCheckBox;
    chkexCounty : TCheckBox;
    chkexDate : TCheckBox;
    chkexDXCC : TCheckBox;
    chkexeQSLR : TCheckBox;
    chkexeQSLRDate : TCheckBox;
    chkexeQSLS : TCheckBox;
    chkexeQSLSDate : TCheckBox;
    chkexFreq : TCheckBox;
    chkexIOTA : TCheckBox;
    chkexITU : TCheckBox;
    chkexLoc : TCheckBox;
    chkexLQSLR : TCheckBox;
    chkexLQSLRDate : TCheckBox;
    chkexLQSLS : TCheckBox;
    chkexLQSLSDate : TCheckBox;
    chkexMode : TCheckBox;
    chkexMyLoc : TCheckBox;
    chkexName : TCheckBox;
    chkexNote : TCheckBox;
    chkexPower : TCheckBox;
    chkexQSLR : TCheckBox;
    chkexQSLRDate : TCheckBox;
    chkexQSLS : TCheckBox;
    chkexQSLSDate : TCheckBox;
    chkexQSLVIA : TCheckBox;
    chkexQTH : TCheckBox;
    chkexRemarks : TCheckBox;
    chkexRSTR : TCheckBox;
    chkexRSTS : TCheckBox;
    chkexState : TCheckBox;
    chkexTimeoff : TCheckBox;
    chkexTimeon : TCheckBox;
    chkexWAZ : TCheckBox;
    chkProfile : TCheckBox;
    edtWAward : TEdit;
    edtWCall : TEdit;
    edtWCounty : TEdit;
    edtWDate : TEdit;
    edtWDXCC : TEdit;
    edtWeQSLR : TEdit;
    edtWeQSLRDate : TEdit;
    edtWeQSLS : TEdit;
    edtWeQSLSDate : TEdit;
    edtWFreq : TEdit;
    edtWIOTA : TEdit;
    edtWITU : TEdit;
    edtWLoc : TEdit;
    edtWLQSLR : TEdit;
    edtWLQSLRDate : TEdit;
    edtWLQSLS : TEdit;
    edtWLQSLSDate : TEdit;
    edtWMode : TEdit;
    edtWMyLoc : TEdit;
    edtWName : TEdit;
    edtWNote : TEdit;
    edtWPower : TEdit;
    edtWQSLR : TEdit;
    edtWQSLRDate : TEdit;
    edtWQSLS : TEdit;
    edtWQSLSDate : TEdit;
    edtWQSLVIA : TEdit;
    edtWQTH : TEdit;
    edtWRemarks : TEdit;
    edtWRstR : TEdit;
    edtWRstS : TEdit;
    edtWState : TEdit;
    edtWTimeOff : TEdit;
    edtWTimeOn : TEdit;
    edtWWAZ : TEdit;
    Label46 : TLabel;
    Label47 : TLabel;
    Label48 : TLabel;
    Label49 : TLabel;
    Label50 : TLabel;
    Label51 : TLabel;
  private
    { private declarations }
  public
    procedure SaveExportPref;
    procedure LoadExportPref;
  end;

implementation

uses uMyIni;

procedure TfraExportPref.SaveExportPref;
begin
  cqrini.WriteBool('Export', 'Date', chkexDate.Checked);
  cqrini.WriteBool('Export', 'time_on', chkexTimeOn.Checked);
  cqrini.WriteBool('Export', 'time_off', chkexTimeOff.Checked);
  cqrini.WriteBool('Export', 'CallSign', chkexCall.Checked);
  cqrini.WriteBool('Export', 'Mode', chkexMode.Checked);
  cqrini.WriteBool('Export', 'Freq', chkexFreq.Checked);
  cqrini.WriteBool('Export', 'RST_S', chkexRSTS.Checked);
  cqrini.WriteBool('Export', 'RST_R', chkexRSTR.Checked);
  cqrini.WriteBool('Export', 'Name', chkexName.Checked);
  cqrini.WriteBool('Export', 'QTH', chkexQTH.Checked);
  cqrini.WriteBool('Export', 'QSL_S', chkexQSLS.Checked);
  cqrini.WriteBool('Export', 'QSL_R', chkexQSLR.Checked);
  cqrini.WriteBool('Export', 'QSL_VIA', chkexQSLVIA.Checked);
  cqrini.WriteBool('Export', 'Locator', chkexLoc.Checked);
  cqrini.WriteBool('Export', 'MyLoc', chkexMyLoc.Checked);
  cqrini.WriteBool('Export', 'IOTA', chkexIOTA.Checked);
  cqrini.WriteBool('Export', 'Award', chkexAward.Checked);
  cqrini.WriteBool('Export', 'County', chkexCounty.Checked);
  cqrini.WriteBool('Export', 'Power', chkexPower.Checked);
  cqrini.WriteBool('Export', 'DXCC', chkexDXCC.Checked);
  cqrini.WriteBool('Export', 'Remarks', chkexRemarks.Checked);
  cqrini.WriteBool('Export', 'WAZ', chkexWAZ.Checked);
  cqrini.WriteBool('Export', 'ITU', chkexITU.Checked);
  cqrini.WriteBool('Export', 'Note', chkexNote.Checked);
  cqrini.WriteBool('Export', 'Profile', chkProfile.Checked);
  cqrini.WriteBool('Export', 'State', chkexState.Checked);
  cqrini.WriteBool('Export', 'LQSLS', chkexLQSLS.Checked);
  cqrini.WriteBool('Export', 'LQSLSDate', chkexLQSLSDate.Checked);
  cqrini.WriteBool('Export', 'LQSLR', chkexLQSLR.Checked);
  cqrini.WriteBool('Export', 'LQSLRDate', chkexLQSLRDate.Checked);
  cqrini.WriteBool('Export', 'Cont', chkExCont.Checked);
  cqrini.WriteBool('Export', 'QSLSDate', chkexQSLSDate.Checked);
  cqrini.WriteBool('Export', 'QSLRDate', chkexQSLRDate.Checked);
  cqrini.WriteBool('Export', 'eQSLS', chkexeQSLS.Checked);
  cqrini.WriteBool('Export', 'eQSLSDate', chkexeQSLSDate.Checked);
  cqrini.WriteBool('Export', 'eQSLR', chkexeQSLR.Checked);
  cqrini.WriteBool('Export', 'eQSLRDate', chkexeQSLRDate.Checked);

  cqrini.WriteString('Export', 'WDate', edtWDate.Text);
  cqrini.WriteString('Export', 'Wtime_on', edtWTimeOn.Text);
  cqrini.WriteString('Export', 'Wtime_off', edtWTimeOff.Text);
  cqrini.WriteString('Export', 'WCallSign', edtWCall.Text);
  cqrini.WriteString('Export', 'WMode', edtWMode.Text);
  cqrini.WriteString('Export', 'WFreq', edtWFreq.Text);
  cqrini.WriteString('Export', 'WRST_S', edtWRstS.Text);
  cqrini.WriteString('Export', 'WRST_R', edtWRstR.Text);
  cqrini.WriteString('Export', 'WName', edtWName.Text);
  cqrini.WriteString('Export', 'WQTH', edtWQTH.Text);
  cqrini.WriteString('Export', 'WQSL_S', edtWQSLS.Text);
  cqrini.WriteString('Export', 'WQSL_R', edtWQSLR.Text);
  cqrini.WriteString('Export', 'WQSL_VIA', edtWQSLVIA.Text);
  cqrini.WriteString('Export', 'WLocator', edtWLoc.Text);
  cqrini.WriteString('Export', 'WMyLoc', edtWMyLoc.Text);
  cqrini.WriteString('Export', 'WIOTA', edtWIOTA.Text);
  cqrini.WriteString('Export', 'WAward', edtWAward.Text);
  cqrini.WriteString('Export', 'WCounty', edtWCounty.Text);
  cqrini.WriteString('Export', 'WPower', edtWPower.Text);
  cqrini.WriteString('Export', 'WDXCC', edtWDXCC.Text);
  cqrini.WriteString('Export', 'WRemarks', edtWRemarks.Text);
  cqrini.WriteString('Export', 'WWAZ', edtWWAZ.Text);
  cqrini.WriteString('Export', 'WITU', edtWITU.Text);
  cqrini.WriteString('Export', 'WNote', edtWNote.Text);
  cqrini.WriteString('Export', 'WState', edtWState.Text);
  cqrini.WriteString('Export', 'WLQSLS', edtWLQSLS.Text);
  cqrini.WriteString('Export', 'WLQSLSDate', edtWLQSLSDate.Text);
  cqrini.WriteString('Export', 'WLQSLR', edtWLQSLR.Text);
  cqrini.WriteString('Export', 'WLQSLRDate', edtWLQSLRDate.Text);
  cqrini.WriteString('Export', 'WQSLSDate', edtWQSLSDate.Text);
  cqrini.WriteString('Export', 'WQSLRDate', edtWQSLRDate.Text);
  cqrini.WriteString('Export', 'WeQSLS', edtWeQSLS.Text);
  cqrini.WriteString('Export', 'WeQSLSDate', edtWeQSLSDate.Text);
  cqrini.WriteString('Export', 'WeQSLR', edtWeQSLR.Text);
  cqrini.WriteString('Export', 'WeQSLRDate', edtWeQSLRDate.Text)
end;

procedure TfraExportPref.LoadExportPref;
begin
  chkexDate.Checked := cqrini.ReadBool('Export', 'Date', True);
  chkexTimeOn.Checked := cqrini.ReadBool('Export', 'time_on', True);
  chkexTimeOff.Checked := cqrini.ReadBool('Export', 'time_off', False);
  chkexCall.Checked := cqrini.ReadBool('Export', 'CallSign', True);
  chkexMode.Checked := cqrini.ReadBool('Export', 'Mode', True);
  chkexFreq.Checked := cqrini.ReadBool('Export', 'Freq', True);
  chkexRSTS.Checked := cqrini.ReadBool('Export', 'RST_S', True);
  chkexRSTR.Checked := cqrini.ReadBool('Export', 'RST_R', True);
  chkexName.Checked := cqrini.ReadBool('Export', 'Name', True);
  chkexQTH.Checked := cqrini.ReadBool('Export', 'QTH', True);
  chkexQSLS.Checked := cqrini.ReadBool('Export', 'QSL_S', True);
  chkexQSLR.Checked := cqrini.ReadBool('Export', 'QSL_R', True);
  chkexQSLVIA.Checked := cqrini.ReadBool('Export', 'QSL_VIA', True);
  chkexLoc.Checked := cqrini.ReadBool('Export', 'Locator', False);
  chkexMyLoc.Checked := cqrini.ReadBool('Export', 'MyLoc', False);
  chkexIOTA.Checked := cqrini.ReadBool('Export', 'IOTA', False);
  chkexAward.Checked := cqrini.ReadBool('Export', 'Award', False);
  chkexCounty.Checked := cqrini.ReadBool('Export', 'County', False);
  chkexPower.Checked := cqrini.ReadBool('Export', 'Power', False);
  chkexDXCC.Checked := cqrini.ReadBool('Export', 'DXCC', False);
  chkexRemarks.Checked := cqrini.ReadBool('Export', 'Remarks', False);
  chkexWAZ.Checked := cqrini.ReadBool('Export', 'WAZ', False);
  chkexITU.Checked := cqrini.ReadBool('Export', 'ITU', False);
  chkexNote.Checked := cqrini.ReadBool('Export', 'Note', False);
  chkProfile.Checked := cqrini.ReadBool('Export', 'Profile', False);
  chkexState.Checked := cqrini.ReadBool('Export', 'State', False);
  chkexLQSLS.Checked := cqrini.ReadBool('Export', 'LQSLS', False);
  chkexLQSLSDate.Checked := cqrini.ReadBool('Export', 'LQSLSDate', False);
  chkexLQSLR.Checked := cqrini.ReadBool('Export', 'LQSLR', False);
  chkexLQSLRDate.Checked := cqrini.ReadBool('Export', 'LQSLRDate', False);
  chkExCont.Checked := cqrini.ReadBool('Export', 'Cont', False);
  chkexQSLSDate.Checked := cqrini.ReadBool('Export', 'QSLSDate', False);
  chkexQSLRDate.Checked := cqrini.ReadBool('Export', 'QSLRDate', False);
  chkexeQSLS.Checked := cqrini.ReadBool('Export', 'eQSLS', False);
  chkexeQSLSDate.Checked := cqrini.ReadBool('Export', 'eQSLSDate', False);
  chkexeQSLR.Checked := cqrini.ReadBool('Export', 'eQSLR', False);
  chkexeQSLRDate.Checked := cqrini.ReadBool('Export', 'eQSLRDate', False);

  edtWDate.Text := cqrini.ReadString('Export', 'WDate', '50');
  edtWTimeOn.Text := cqrini.ReadString('Export', 'Wtime_on', '50');
  edtWTimeOff.Text := cqrini.ReadString('Export', 'Wtime_off', '50');
  edtWCall.Text := cqrini.ReadString('Export', 'WCallSign', '50');
  edtWMode.Text := cqrini.ReadString('Export', 'WMode', '50');
  edtWFreq.Text := cqrini.ReadString('Export', 'WFreq', '50');
  edtWRstS.Text := cqrini.ReadString('Export', 'WRST_S', '50');
  edtWRstR.Text := cqrini.ReadString('Export', 'WRST_R', '30');
  edtWName.Text := cqrini.ReadString('Export', 'WName', '50');
  edtWQTH.Text := cqrini.ReadString('Export', 'WQTH', '80');
  edtWQSLS.Text := cqrini.ReadString('Export', 'WQSL_S', '10');
  edtWQSLR.Text := cqrini.ReadString('Export', 'WQSL_R', '10');
  edtWQSLVIA.Text := cqrini.ReadString('Export', 'WQSL_VIA', '20');
  edtWLoc.Text := cqrini.ReadString('Export', 'WLocator', '30');
  edtWMyLoc.Text := cqrini.ReadString('Export', 'WMyLoc', '30');
  edtWIOTA.Text := cqrini.ReadString('Export', 'WIOTA', '40');
  edtWAward.Text := cqrini.ReadString('Export', 'WAward', '40');
  edtWCounty.Text := cqrini.ReadString('Export', 'WCounty', '40');
  edtWPower.Text := cqrini.ReadString('Export', 'WPower', '40');
  edtWDXCC.Text := cqrini.ReadString('Export', 'WDXCC', '40');
  edtWRemarks.Text := cqrini.ReadString('Export', 'WRemarks', '100');
  edtWWAZ.Text := cqrini.ReadString('Export', 'WWAZ', '20');
  edtWITU.Text := cqrini.ReadString('Export', 'WITU', '20');
  edtWNote.Text := cqrini.ReadString('Export', 'WNote', '40');
  edtWState.Text := cqrini.ReadString('Export', 'WState', '40');
  edtWLQSLS.Text := cqrini.ReadString('Export', 'WLQSLS', '50');
  edtWLQSLSDate.Text := cqrini.ReadString('Export', 'WLQSLSDate', '50');
  edtWLQSLR.Text := cqrini.ReadString('Export', 'WLQSLR', '50');
  edtWLQSLRDate.Text := cqrini.ReadString('Export', 'WLQSLRDate', '50');
  edtWQSLSDate.Text := cqrini.ReadString('Export', 'WQSLSDate', '50');
  edtWQSLRDate.Text := cqrini.ReadString('Export', 'WQSLRDate', '50');
  edtWeQSLS.Text := cqrini.ReadString('Export', 'WeQSLS', '50');
  edtWeQSLSDate.Text := cqrini.ReadString('Export', 'WeQSLSDate', '50');
  edtWeQSLR.Text := cqrini.ReadString('Export', 'WeQSLR', '50');
  edtWeQSLRDate.Text := cqrini.ReadString('Export', 'WeQSLRDate', '50')
end;

initialization
  {$I frExportPref.lrs}

end.

