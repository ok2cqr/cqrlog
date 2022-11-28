unit fKeyTexts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, iniFiles;

const
  C_INI_FILE_SECTION = 'CW';

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
    edtF1: TEdit;
    edtF10: TEdit;
    edtF2: TEdit;
    edtF3: TEdit;
    edtF4: TEdit;
    edtF5: TEdit;
    edtF6: TEdit;
    edtF7: TEdit;
    edtF8: TEdit;
    edtF9: TEdit;
    GroupBox1: TGroupBox;
    GroupBox10: TGroupBox;
    GroupBox11: TGroupBox;
    GroupBox2: TGroupBox;
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
    Label2: TLabel;
    Label3: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label35: TLabel;
    Label36: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    LoadMsg: TButton;
    OpenDialog1: TOpenDialog;
    pnlMain: TPanel;
    rgEnter: TRadioGroup;
    pnlControl: TPanel;
    SaveDialog1: TSaveDialog;
    SaveMsg: TButton;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure LoadMsgClick(Sender: TObject);
    procedure SaveMsgClick(Sender: TObject);
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
begin
  dmUtils.LoadWindowPos(frmKeyTexts);
  edtF1.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F1','cq cq de %mc %mc pse K');
  edtF2.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F2','');
  edtF3.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F3','');
  edtF4.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F4','');
  edtF5.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F5','');
  edtF6.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F6','');
  edtF7.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F7','');
  edtF8.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F8','');
  edtF9.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F9','');
  edtF10.text    := cqrini.ReadString(C_INI_FILE_SECTION,'F10','');
  edtCapF1.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF1','F1 - CQ');
  edtCapF2.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF2','F2');
  edtCapF3.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF3','F3');
  edtCapF4.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF4','F4');
  edtCapF5.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF5','F5');
  edtCapF6.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF6','F6');
  edtCapF7.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF7','F7');
  edtCapF8.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF8','F8');
  edtCapF9.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF9','F9');
  edtCapF10.text := cqrini.ReadString(C_INI_FILE_SECTION,'CapF10','F10');
  rgEnter.ItemIndex := cqrini.ReadInteger(C_INI_FILE_SECTION,'EnterFunction',1);
end;

procedure TfrmKeyTexts.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmKeyTexts);
end;

procedure TfrmKeyTexts.btnHelpClick(Sender: TObject);
begin
   ShowHelp
end;

procedure TfrmKeyTexts.btnOKClick(Sender: TObject);
begin
  cqrini.SectionErase(C_INI_FILE_SECTION); //this cleans section to keep only memory keys, other settings in CWnr sections
  cqrini.WriteString(C_INI_FILE_SECTION,'F1',edtF1.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F2',edtF2.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F3',edtF3.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F4',edtF4.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F5',edtF5.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F6',edtF6.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F7',edtF7.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F8',edtF8.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F9',edtF9.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F10',edtF10.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF1',edtCapF1.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF2',edtCapF2.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF3',edtCapF3.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF4',edtCapF4.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF5',edtCapF5.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF6',edtCapF6.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF7',edtCapF7.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF8',edtCapF8.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF9',edtCapF9.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF10',edtCapF10.Text);
  cqrini.WriteInteger(C_INI_FILE_SECTION,'EnterFunction',rgEnter.ItemIndex);
  cqrini.SaveToDisk;
  ModalResult := mrOK
end;
procedure TfrmKeyTexts.LoadMsgClick(Sender: TObject);
var
  CwM : TIniFile;
begin
 OpenDialog1.InitialDir := dmData.HomeDir;
 if OpenDialog1.Execute then
 begin
   CWM := TIniFile.Create(OpenDialog1.FileName);
   try
     edtF1.text     := CWM.ReadString(C_INI_FILE_SECTION,'F1','cq cq de %mc %mc pse K');
     edtF2.text     := CWM.ReadString(C_INI_FILE_SECTION,'F2','');
     edtF3.text     := CWM.ReadString(C_INI_FILE_SECTION,'F3','');
     edtF4.text     := CWM.ReadString(C_INI_FILE_SECTION,'F4','');
     edtF5.text     := CWM.ReadString(C_INI_FILE_SECTION,'F5','');
     edtF6.text     := CWM.ReadString(C_INI_FILE_SECTION,'F6','');
     edtF7.text     := CWM.ReadString(C_INI_FILE_SECTION,'F7','');
     edtF8.text     := CWM.ReadString(C_INI_FILE_SECTION,'F8','');
     edtF9.text     := CWM.ReadString(C_INI_FILE_SECTION,'F9','');
     edtF10.text    := CWM.ReadString(C_INI_FILE_SECTION,'F10','');
     edtCapF1.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF1','F1 - CQ');
     edtCapF2.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF2','F2');
     edtCapF3.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF3','F3');
     edtCapF4.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF4','F4');
     edtCapF5.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF5','F5');
     edtCapF6.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF6','F6');
     edtCapF7.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF7','F7');
     edtCapF8.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF8','F8');
     edtCapF9.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF9','F9');
     edtCapF10.text := CWM.ReadString(C_INI_FILE_SECTION,'CapF10','F10');
     rgEnter.ItemIndex := CWM.ReadInteger(C_INI_FILE_SECTION,'EnterFunction',1);
   finally
     FreeAndNil(CWM);
   end;
 end;
end;

procedure TfrmKeyTexts.SaveMsgClick(Sender: TObject);
var
  CwM : TIniFile;
begin
  SaveDialog1.InitialDir := dmData.HomeDir;
  if SaveDialog1.Execute then
  begin
    CWM := TIniFile.Create(SaveDialog1.FileName);
    try
      CWM.WriteString(C_INI_FILE_SECTION,'F1',edtF1.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F2',edtF2.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F3',edtF3.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F4',edtF4.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F5',edtF5.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F6',edtF6.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F7',edtF7.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F8',edtF8.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F9',edtF9.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F10',edtF10.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF1',edtCapF1.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF2',edtCapF2.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF3',edtCapF3.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF4',edtCapF4.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF5',edtCapF5.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF6',edtCapF6.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF7',edtCapF7.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF8',edtCapF8.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF9',edtCapF9.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF10',edtCapF10.Text);
      CWM.WriteInteger(C_INI_FILE_SECTION,'EnterFunction',rgEnter.ItemIndex);
      CWM.UpdateFile;
    finally
      FreeAndNil(CwM);
    end;
  end;
end;

end.

