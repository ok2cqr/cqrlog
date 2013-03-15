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

{ TfrmKeyTexts }
uses dData, dUtils, uMyIni;

procedure TfrmKeyTexts.FormShow(Sender: TObject);
var
  section : String = '';
begin
  dmUtils.LoadWindowPos(frmKeyTexts);
  section := 'CW';
  {$IFDEF CONTEST}
  if dmData.ContestMode and dmData.ContestDatabase.Connected then
  begin
    edtF1.text     := dmData.tstini.ReadString(section,'F1','cq cq de %mc %mc pse K');
    edtF2.text     := dmData.tstini.ReadString(section,'F2','');
    edtF3.text     := dmData.tstini.ReadString(section,'F3','');
    edtF4.text     := dmData.tstini.ReadString(section,'F4','');
    edtF5.text     := dmData.tstini.ReadString(section,'F5','');
    edtF6.text     := dmData.tstini.ReadString(section,'F6','');
    edtF7.text     := dmData.tstini.ReadString(section,'F7','');
    edtF8.text     := dmData.tstini.ReadString(section,'F8','');
    edtF9.text     := dmData.tstini.ReadString(section,'F9','');
    edtF10.text    := dmData.tstini.ReadString(section,'F10','');
    edtCapF1.text  := dmData.tstini.ReadString(section,'CapF1','F1 - CQ');
    edtCapF2.text  := dmData.tstini.ReadString(section,'CapF2','F2');
    edtCapF3.text  := dmData.tstini.ReadString(section,'CapF3','F3');
    edtCapF4.text  := dmData.tstini.ReadString(section,'CapF4','F4');
    edtCapF5.text  := dmData.tstini.ReadString(section,'CapF5','F5');
    edtCapF6.text  := dmData.tstini.ReadString(section,'CapF6','F6');
    edtCapF7.text  := dmData.tstini.ReadString(section,'CapF7','F7');
    edtCapF8.text  := dmData.tstini.ReadString(section,'CapF8','F8');
    edtCapF9.text  := dmData.tstini.ReadString(section,'CapF9','F9');
    edtCapF10.text  := dmData.tstini.ReadString(section,'CapF10','F10');

    edtSPF1.text     := dmData.tstini.ReadString(section,'SPF1','cq cq de %mc %mc pse K');
    edtSPF2.text     := dmData.tstini.ReadString(section,'SPF2','');
    edtSPF3.text     := dmData.tstini.ReadString(section,'SPF3','');
    edtSPF4.text     := dmData.tstini.ReadString(section,'SPF4','');
    edtSPF5.text     := dmData.tstini.ReadString(section,'SPF5','');
    edtSPF6.text     := dmData.tstini.ReadString(section,'SPF6','');
    edtSPF7.text     := dmData.tstini.ReadString(section,'SPF7','');
    edtSPF8.text     := dmData.tstini.ReadString(section,'SPF8','');
    edtSPF9.text     := dmData.tstini.ReadString(section,'SPF9','');
    edtSPF10.text     := dmData.tstini.ReadString(section,'SPF10','');
    edtSPCapF1.text  := dmData.tstini.ReadString(section,'SPCapF1','DE CALL');
    edtSPCapF2.text  := dmData.tstini.ReadString(section,'SPCapF2','F2');
    edtSPCapF3.text  := dmData.tstini.ReadString(section,'SPCapF3','F3');
    edtSPCapF4.text  := dmData.tstini.ReadString(section,'SPCapF4','F4');
    edtSPCapF5.text  := dmData.tstini.ReadString(section,'SPCapF5','F5');
    edtSPCapF6.text  := dmData.tstini.ReadString(section,'SPCapF6','F6');
    edtSPCapF7.text  := dmData.tstini.ReadString(section,'SPCapF7','F7');
    edtSPCapF8.text  := dmData.tstini.ReadString(section,'SPCapF8','F8');
    edtSPCapF9.text  := dmData.tstini.ReadString(section,'SPCapF9','F9');
    edtSPCapF10.text := dmData.tstini.ReadString(section,'SPCapF10','F10')
  end
  else begin
  {$ENDIF}
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
  {$IFDEF CONTEST}
  end
  {$ENDIF}
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
  {$IFDEF CONTEST}
  if dmData.ContestMode and dmData.ContestDatabase.Connected then
  begin
    dmData.tstini.WriteString(section,'F1',edtF1.Text);
    dmData.tstini.WriteString(section,'F2',edtF2.Text);
    dmData.tstini.WriteString(section,'F3',edtF3.Text);
    dmData.tstini.WriteString(section,'F4',edtF4.Text);
    dmData.tstini.WriteString(section,'F5',edtF5.Text);
    dmData.tstini.WriteString(section,'F6',edtF6.Text);
    dmData.tstini.WriteString(section,'F7',edtF7.Text);
    dmData.tstini.WriteString(section,'F8',edtF8.Text);
    dmData.tstini.WriteString(section,'F9',edtF9.Text);
    dmData.tstini.WriteString(section,'F10',edtF10.Text);
    dmData.tstini.WriteString(section,'CapF1',edtCapF1.Text);
    dmData.tstini.WriteString(section,'CapF2',edtCapF2.Text);
    dmData.tstini.WriteString(section,'CapF3',edtCapF3.Text);
    dmData.tstini.WriteString(section,'CapF4',edtCapF4.Text);
    dmData.tstini.WriteString(section,'CapF5',edtCapF5.Text);
    dmData.tstini.WriteString(section,'CapF6',edtCapF6.Text);
    dmData.tstini.WriteString(section,'CapF7',edtCapF7.Text);
    dmData.tstini.WriteString(section,'CapF8',edtCapF8.Text);
    dmData.tstini.WriteString(section,'CapF9',edtCapF9.Text);
    dmData.tstini.WriteString(section,'CapF10',edtCapF10.Text);

    dmData.tstini.WriteString(section,'SPF1',edtSPF1.Text);
    dmData.tstini.WriteString(section,'SPF2',edtSPF2.Text);
    dmData.tstini.WriteString(section,'SPF3',edtSPF3.Text);
    dmData.tstini.WriteString(section,'SPF4',edtSPF4.Text);
    dmData.tstini.WriteString(section,'SPF5',edtSPF5.Text);
    dmData.tstini.WriteString(section,'SPF6',edtSPF6.Text);
    dmData.tstini.WriteString(section,'SPF7',edtSPF7.Text);
    dmData.tstini.WriteString(section,'SPF8',edtSPF8.Text);
    dmData.tstini.WriteString(section,'SPF9',edtSPF9.Text);
    dmData.tstini.WriteString(section,'SPF10',edtSPF10.Text);
    dmData.tstini.WriteString(section,'SPCapF1',edtSPCapF1.Text);
    dmData.tstini.WriteString(section,'SPCapF2',edtSPCapF2.Text);
    dmData.tstini.WriteString(section,'SPCapF3',edtSPCapF3.Text);
    dmData.tstini.WriteString(section,'SPCapF4',edtSPCapF4.Text);
    dmData.tstini.WriteString(section,'SPCapF5',edtSPCapF5.Text);
    dmData.tstini.WriteString(section,'SPCapF6',edtSPCapF6.Text);
    dmData.tstini.WriteString(section,'SPCapF7',edtSPCapF7.Text);
    dmData.tstini.WriteString(section,'SPCapF8',edtSPCapF8.Text);
    dmData.tstini.WriteString(section,'SPCapF9',edtSPCapF9.Text);
    dmData.tstini.WriteString(section,'SPCapF10',edtSPCapF10.Text);
    dmData.tstini.SaveToDisk
  end
  else begin
  {$ENDIF}
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
  {$IFDEF CONTEST}
  end;
  {$ENDIF}
  ModalResult := mrOK
end;

initialization
  {$I fKeyTexts.lrs}

end.

