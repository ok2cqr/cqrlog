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
    edtCapF11: TEdit;
    edtCapF12: TEdit;
    edtCapF13: TEdit;
    edtCapF14: TEdit;
    edtCapF15: TEdit;
    edtCapF16: TEdit;
    edtCapF17: TEdit;
    edtCapF18: TEdit;
    edtCapF19: TEdit;
    edtCapF2: TEdit;
    edtCapF20: TEdit;
    edtCapF3: TEdit;
    edtCapF4: TEdit;
    edtCapF5: TEdit;
    edtCapF6: TEdit;
    edtCapF7: TEdit;
    edtCapF8: TEdit;
    edtCapF9: TEdit;
    edtF1: TEdit;
    edtF10: TEdit;
    edtF11: TEdit;
    edtF12: TEdit;
    edtF13: TEdit;
    edtF14: TEdit;
    edtF15: TEdit;
    edtF16: TEdit;
    edtF17: TEdit;
    edtF18: TEdit;
    edtF19: TEdit;
    edtF2: TEdit;
    edtF20: TEdit;
    edtF3: TEdit;
    edtF4: TEdit;
    edtF5: TEdit;
    edtF6: TEdit;
    edtF7: TEdit;
    edtF8: TEdit;
    edtF9: TEdit;
    GroupBox1: TGroupBox;
    GroupBox10: TGroupBox;
    gbSaveLoad: TGroupBox;
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
    LoadMsg: TButton;
    OpenDialog1: TOpenDialog;
    pnlActions: TPanel;
    pgMemories: TPageControl;
    pnlMain: TPanel;
    pnlControl: TPanel;
    rgEnter: TRadioGroup;
    SaveDialog1: TSaveDialog;
    SaveMsg: TButton;
    tabRUN: TTabSheet;
    tabSeP: TTabSheet;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure SaveMsgClick(Sender: TObject);
    procedure LoadMsgClick(Sender: TObject);
  private
    SP   : boolean;
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

  edtF11.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F11','cq cq de %mc %mc pse K');
  edtF12.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F12','');
  edtF13.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F13','');
  edtF14.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F14','');
  edtF15.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F15','');
  edtF16.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F16','');
  edtF17.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F17','');
  edtF18.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F18','');
  edtF19.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F19','');
  edtF20.text     := cqrini.ReadString(C_INI_FILE_SECTION,'F20','');
  edtCapF11.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF11','F1 - CQ');
  edtCapF12.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF12','F2');
  edtCapF13.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF13','F3');
  edtCapF14.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF14','F4');
  edtCapF15.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF15','F5');
  edtCapF16.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF16','F6');
  edtCapF17.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF17','F7');
  edtCapF18.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF18','F8');
  edtCapF19.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF19','F9');
  edtCapF20.text  := cqrini.ReadString(C_INI_FILE_SECTION,'CapF20','F10');

  SP                := cqrini.ReadBool('CW','S&P',True);
  rgEnter.ItemIndex := cqrini.ReadInteger(C_INI_FILE_SECTION,'EnterFunction',1);
  if SP then pgMemories.ActivePageIndex:=0
    else
      pgMemories.ActivePageIndex:=1;
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

  cqrini.WriteString(C_INI_FILE_SECTION,'F11',edtF11.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F12',edtF12.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F13',edtF13.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F14',edtF14.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F15',edtF15.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F16',edtF16.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F17',edtF17.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F18',edtF18.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F19',edtF19.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'F20',edtF20.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF11',edtCapF11.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF12',edtCapF12.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF13',edtCapF13.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF14',edtCapF14.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF15',edtCapF15.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF16',edtCapF16.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF17',edtCapF17.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF18',edtCapF18.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF19',edtCapF19.Text);
  cqrini.WriteString(C_INI_FILE_SECTION,'CapF20',edtCapF20.Text);

  cqrini.WriteBool('CW','S&P',SP);
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

     edtF11.text     := CWM.ReadString(C_INI_FILE_SECTION,'F11','cq cq de %mc %mc pse K');
     edtF12.text     := CWM.ReadString(C_INI_FILE_SECTION,'F12','');
     edtF13.text     := CWM.ReadString(C_INI_FILE_SECTION,'F13','');
     edtF14.text     := CWM.ReadString(C_INI_FILE_SECTION,'F14','');
     edtF15.text     := CWM.ReadString(C_INI_FILE_SECTION,'F15','');
     edtF16.text     := CWM.ReadString(C_INI_FILE_SECTION,'F16','');
     edtF17.text     := CWM.ReadString(C_INI_FILE_SECTION,'F17','');
     edtF18.text     := CWM.ReadString(C_INI_FILE_SECTION,'F18','');
     edtF19.text     := CWM.ReadString(C_INI_FILE_SECTION,'F19','');
     edtF20.text     := CWM.ReadString(C_INI_FILE_SECTION,'F20','');
     edtCapF11.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF11','F1 - CQ');
     edtCapF12.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF12','F2');
     edtCapF13.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF13','F3');
     edtCapF14.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF14','F4');
     edtCapF15.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF15','F5');
     edtCapF16.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF16','F6');
     edtCapF17.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF17','F7');
     edtCapF18.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF18','F8');
     edtCapF19.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF19','F9');
     edtCapF20.text  := CWM.ReadString(C_INI_FILE_SECTION,'CapF20','F10');

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

      CWM.WriteString(C_INI_FILE_SECTION,'F11',edtF11.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F12',edtF12.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F13',edtF13.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F14',edtF14.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F15',edtF15.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F16',edtF16.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F17',edtF17.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F18',edtF18.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F19',edtF19.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'F20',edtF20.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF11',edtCapF11.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF12',edtCapF12.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF13',edtCapF13.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF14',edtCapF14.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF15',edtCapF15.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF16',edtCapF16.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF17',edtCapF17.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF18',edtCapF18.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF19',edtCapF19.Text);
      CWM.WriteString(C_INI_FILE_SECTION,'CapF20',edtCapF20.Text);

      CWM.WriteInteger(C_INI_FILE_SECTION,'EnterFunction',rgEnter.ItemIndex);
      CWM.UpdateFile;
    finally
      FreeAndNil(CwM);
    end;
  end;
end;

end.

