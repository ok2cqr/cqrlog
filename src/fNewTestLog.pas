unit fNewTestLog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, lcltype, ExtCtrls, ComCtrls;

type TNewContestDialog = (ctNewConstet,ctChangeContest,ctModifyRules);

type

  { TfrmNewTestLog }

  TfrmNewTestLog = class(TForm)
    btnCancel: TButton;
    btnOK: TButton;
    chkPower: TCheckBox;
    chkWPX: TCheckBox;
    chkBand: TCheckBox;
    chkPoints: TCheckBox;
    chkExch1: TCheckBox;
    chkExch2: TCheckBox;
    chkMult1: TCheckBox;
    chkMult2: TCheckBox;
    chkQSONR: TCheckBox;
    chkCallSign: TCheckBox;
    chkCont: TCheckBox;
    chkDate: TCheckBox;
    chkDXCC: TCheckBox;
    chkFreq: TCheckBox;
    chkIOTA: TCheckBox;
    chkITU: TCheckBox;
    chkMode: TCheckBox;
    chkName: TCheckBox;
    chkQTH: TCheckBox;
    chkRST_R: TCheckBox;
    chkRST_S: TCheckBox;
    chkState: TCheckBox;
    chkTimeOn: TCheckBox;
    chkWARC: TCheckBox;
    chkWAZ: TCheckBox;
    cmbContest: TComboBox;
    cmbCategory: TComboBox;
    cmbExch1: TComboBox;
    cmbExch2: TComboBox;
    cmbMult1: TComboBox;
    cmbMult2: TComboBox;
    edtPower: TEdit;
    edtZone: TEdit;
    edtState: TEdit;
    edtSection: TEdit;
    edtGrid: TEdit;
    edtCall: TEdit;
    edtCountry: TEdit;
    edtName: TEdit;
    edtLogName: TEdit;
    edtQTH: TEdit;
    edtIOTA: TEdit;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    PageControl1: TPageControl;
    Panel2: TPanel;
    tabBasic: TTabSheet;
    tabDetails: TTabSheet;
    tabColumns: TTabSheet;
    procedure btnOKClick(Sender: TObject);
    procedure edtLogNameKeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public
    DlgType : TNewContestDialog;
  end; 

var
  frmNewTestLog: TfrmNewTestLog;

implementation
{$R *.lfm}

{ TfrmNewTestLog }
uses dData, dUtils;

{ TfrmNewTestLog }

procedure TfrmNewTestLog.btnOKClick(Sender: TObject);
var
  f : String;
begin
  if DlgType = ctNewConstet then
  begin
    f := edtLogName.Text+'.fdb';
    if FileExists(dmData.ContestDataDir+f) then
    begin
      Application.MessageBox('This file with the same name already exists!','Error...',mb_ok + mb_IconError);
      edtLogName.SetFocus;
      edtLogName.SelectAll;
      exit
    end;
    if not dmUtils.IsValidFileName(f) then
    begin
      Application.MessageBox('This is not valid name for a file!','Error...',mb_ok + mb_IconError);
      edtLogName.SetFocus;
      edtLogName.SelectAll;
      exit
    end
  end;
  ModalResult := mrOK
end;

procedure TfrmNewTestLog.edtLogNameKeyPress(Sender: TObject; var Key: char);
begin
  if key = #13 then
  begin
    key := #0;
    btnOK.Click
  end
end;

procedure TfrmNewTestLog.FormCreate(Sender: TObject);
begin
  DlgType := ctNewConstet
end;

procedure TfrmNewTestLog.FormShow(Sender: TObject);
begin
  edtLogName.SetFocus;
  if DlgType <> ctNewConstet then
  begin
    edtLogName.Enabled  := False;
    cmbContest.Enabled  := False;
    cmbCategory.Enabled := False
  end
end;

end.

