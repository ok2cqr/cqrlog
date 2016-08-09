unit fKeyTexts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, iniFiles;

type

  { TfrmKeyTexts }

  TfrmKeyTexts = class(TForm)
    btnCancel: TButton;
    btnHelp: TButton;
    btnOK: TButton;
    edtCapF1: TEdit;
    edtCapF10: TEdit;
    edtCapF2: TEdit;
    edtCapF3: TEdit;
    edtCapF4: TEdit;
    edtCapF5: TEdit;
    edtCapF6: TEdit;
    edtCapF7: TEdit;
    edtCapF8: TEdit;
    edtCapF9: TEdit;
    edtF10: TEdit;
    edtF9: TEdit;
    edtSPCapF1: TEdit;
    edtF1: TEdit;
    edtF2: TEdit;
    edtF3: TEdit;
    edtF4: TEdit;
    edtF5: TEdit;
    edtF6: TEdit;
    edtF7: TEdit;
    edtF8: TEdit;
    edtSPCapF10: TEdit;
    edtSPCapF2: TEdit;
    edtSPCapF3: TEdit;
    edtSPCapF4: TEdit;
    edtSPCapF5: TEdit;
    edtSPCapF6: TEdit;
    edtSPCapF7: TEdit;
    edtSPCapF8: TEdit;
    edtSPCapF9: TEdit;
    edtSPF1: TEdit;
    edtSPF10: TEdit;
    edtSPF2: TEdit;
    edtSPF3: TEdit;
    edtSPF4: TEdit;
    edtSPF5: TEdit;
    edtSPF6: TEdit;
    edtSPF7: TEdit;
    edtSPF8: TEdit;
    edtSPF9: TEdit;
    GroupBox1: TGroupBox;
    GroupBox10: TGroupBox;
    GroupBox11: TGroupBox;
    GroupBox12: TGroupBox;
    GroupBox13: TGroupBox;
    GroupBox14: TGroupBox;
    GroupBox15: TGroupBox;
    GroupBox16: TGroupBox;
    GroupBox17: TGroupBox;
    GroupBox18: TGroupBox;
    GroupBox19: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox20: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    GroupBox6: TGroupBox;
    GroupBox7: TGroupBox;
    GroupBox8: TGroupBox;
    GroupBox9: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label2: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Label3: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label35: TLabel;
    Label36: TLabel;
    Label37: TLabel;
    Label38: TLabel;
    Label39: TLabel;
    Label4: TLabel;
    Label40: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    pgCWTexts: TPageControl;
    Panel1: TPanel;
    tabRunMode: TTabSheet;
    tabSPMode: TTabSheet;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmKeyTexts: TfrmKeyTexts;

implementation
{$R *.lfm}

{ TfrmKeyTexts }
uses dData, dUtils, uMyIni;

procedure TfrmKeyTexts.FormShow(Sender: TObject);
var
  section : String = '';
begin
  dmUtils.LoadWindowPos(frmKeyTexts);
  section := 'CW';
  pgCWTexts.Pages[1].TabVisible := False;
  pgCWTexts.Pages[0].Caption := '';
  edtF1.text     := cqrini.ReadString(section,'F1','cq cq de %mc %mc pse K');
  edtF2.text     := cqrini.ReadString(section,'F2','');
  edtF3.text     := cqrini.ReadString(section,'F3','');
  edtF4.text     := cqrini.ReadString(section,'F4','');
  edtF5.text     := cqrini.ReadString(section,'F5','');
  edtF6.text     := cqrini.ReadString(section,'F6','');
  edtF7.text     := cqrini.ReadString(section,'F7','');
  edtF8.text     := cqrini.ReadString(section,'F8','');
  edtF9.text     := cqrini.ReadString(section,'F9','');
  edtF10.text    := cqrini.ReadString(section,'F10','');
  edtCapF1.text  := cqrini.ReadString(section,'CapF1','F1 - CQ');
  edtCapF2.text  := cqrini.ReadString(section,'CapF2','F2');
  edtCapF3.text  := cqrini.ReadString(section,'CapF3','F3');
  edtCapF4.text  := cqrini.ReadString(section,'CapF4','F4');
  edtCapF5.text  := cqrini.ReadString(section,'CapF5','F5');
  edtCapF6.text  := cqrini.ReadString(section,'CapF6','F6');
  edtCapF7.text  := cqrini.ReadString(section,'CapF7','F7');
  edtCapF8.text  := cqrini.ReadString(section,'CapF8','F8');
  edtCapF9.text  := cqrini.ReadString(section,'CapF9','F9');
  edtCapF10.text  := cqrini.ReadString(section,'CapF10','F10')
end;

procedure TfrmKeyTexts.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  dmUtils.SaveWindowPos(frmKeyTexts)
end;

procedure TfrmKeyTexts.btnHelpClick(Sender: TObject);
begin
   ShowHelp
end;

procedure TfrmKeyTexts.btnOKClick(Sender: TObject);
var
  section : String = '';
begin
  section := 'CW';
  cqrini.WriteString(section,'F1',edtF1.Text);
  cqrini.WriteString(section,'F2',edtF2.Text);
  cqrini.WriteString(section,'F3',edtF3.Text);
  cqrini.WriteString(section,'F4',edtF4.Text);
  cqrini.WriteString(section,'F5',edtF5.Text);
  cqrini.WriteString(section,'F6',edtF6.Text);
  cqrini.WriteString(section,'F7',edtF7.Text);
  cqrini.WriteString(section,'F8',edtF8.Text);
  cqrini.WriteString(section,'F9',edtF9.Text);
  cqrini.WriteString(section,'F10',edtF10.Text);
  cqrini.WriteString(section,'CapF1',edtCapF1.Text);
  cqrini.WriteString(section,'CapF2',edtCapF2.Text);
  cqrini.WriteString(section,'CapF3',edtCapF3.Text);
  cqrini.WriteString(section,'CapF4',edtCapF4.Text);
  cqrini.WriteString(section,'CapF5',edtCapF5.Text);
  cqrini.WriteString(section,'CapF6',edtCapF6.Text);
  cqrini.WriteString(section,'CapF7',edtCapF7.Text);
  cqrini.WriteString(section,'CapF8',edtCapF8.Text);
  cqrini.WriteString(section,'CapF9',edtCapF9.Text);
  cqrini.WriteString(section,'CapF10',edtCapF10.Text);
  cqrini.SaveToDisk;
  ModalResult := mrOK
end;

end.

