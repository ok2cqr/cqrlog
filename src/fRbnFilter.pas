unit fRbnFilter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Buttons, lclType;

type

  { TfrmRbnFilter }

  TfrmRbnFilter = class(TForm)
    Bevel1: TBevel;
    Bevel2: TBevel;
    btnOK: TButton;
    btnCancel: TButton;
    btnDXCCnty: TButton;
    btnDXCNotCnty: TButton;
    chkNewDXConly: TCheckBox;
    chkOnlyeQSL: TCheckBox;
    chkOnlyLoTW: TCheckBox;
    edtDXCnty: TEdit;
    edtDXCNotCnty: TEdit;
    edtDate: TEdit;
    edtDXOnlyCall: TEdit;
    edtDXOnlyExpres: TEdit;
    edtDXBand: TEdit;
    edtDXMode: TEdit;
    edtDXCont: TEdit;
    edtLastHours: TEdit;
    edtSrcCont: TEdit;
    edtTime: TEdit;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    rbAllDx: TRadioButton;
    rbOnlyCall: TRadioButton;
    rbOnlyCallReg: TRadioButton;
    rbIgnWkdDate: TRadioButton;
    rbIgnWkdHour: TRadioButton;
    procedure btnDXCCntyClick(Sender: TObject);
    procedure btnDXCNotCntyClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmRbnFilter: TfrmRbnFilter;

implementation

uses uMyIni, dUtils, dDXCC, fSelectDXCC;

{$R *.lfm}

{ TfrmRbnFilter }

procedure TfrmRbnFilter.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(self);

  edtSrcCont.Text      := cqrini.ReadString('RBNFilter','SrcCont',C_RBN_CONT);

  rbIgnWkdHour.Checked := cqrini.ReadBool('RBNFilter','IgnHour',True);
  edtLastHours.Text    := IntToStr(cqrini.ReadInteger('RBNFilter','IgnHourValue',48));
  rbIgnWkdDate.Checked := cqrini.ReadBool('RBNFilter','IgnDate',False);
  edtDate.Text         := cqrini.ReadString('RBNFilter','IgnDateValue','');
  edtTime.Text         := cqrini.ReadString('RBNFilter','IgnTimeValue','');

  rbAllDx.Checked       := cqrini.ReadBool('RBNFilter','AllowAllCall',True);
  rbOnlyCall.Checked    := cqrini.ReadBool('RBNFilter','AllowOnlyCall',False);
  edtDXOnlyCall.Text    := cqrini.ReadString('RBNFilter','AllowOnlyCallValue','');
  rbOnlyCallReg.Checked := cqrini.ReadBool('RBNFilter','AllowOnlyCallReg',False);
  edtDXOnlyExpres.Text  := cqrini.ReadString('RBNFilter','AllowOnlyCallRegValue','');

  edtDXCont.Text     := cqrini.ReadString('RBNFilter','AllowCont',C_RBN_CONT);
  edtDXBand.Text     := cqrini.ReadString('RBNFilter','AllowBands',C_RBN_BANDS);
  edtDXMode.Text     := cqrini.ReadString('RBNFilter','AllowModes',C_RBN_MODES);
  edtDXCnty.Text     := cqrini.ReadString('RBNFilter','AllowCnty','');
  edtDXCNotCnty.Text := cqrini.ReadString('RBNFilter','NotCnty','');

  chkOnlyLoTW.Checked := cqrini.ReadBool('RBNFilter','LoTWOnly',False);
  chkOnlyeQSL.Checked := cqrini.ReadBool('RBNFilter','eQSLOnly',False);

  chkNewDXConly.Checked := cqrini.ReadBool('RBNFilter','NewDXCOnly',False)
end;

procedure TfrmRbnFilter.btnOKClick(Sender: TObject);
  function RmSp(what : String) : String;
  begin
    Result := StringReplace(what,' ','',[rfReplaceAll, rfIgnoreCase])
  end;

var
  i : Integer;
begin
  if not TryStrToInt(edtLastHours.Text,i) then
  begin
    if rbIgnWkdHour.Checked then
    begin
      Application.MessageBox('Please enter correct number of hours, please','Error...',mb_OK+mb_IconError);
      edtLastHours.SetFocus;
      exit
    end
    else
      edtLastHours.Text := '48'
  end;

  if not dmUtils.IsDateOK(edtDate.Text) then
  begin
    if rbIgnWkdDate.Checked then
    begin
      Application.MessageBox('Enter date in correct format, please','Error...',mb_Ok+mb_IconError);
      edtDate.SetFocus;
      exit
    end
    else
      edtDate.Text := ''
  end;

  if not (dmUtils.IsTimeOK(edtTime.Text)) then
  begin
    if rbIgnWkdDate.Checked then
    begin
      Application.MessageBox('Enter time in correct format, please','Error...',mb_Ok+mb_IconError);
      edtTime.SetFocus;
      exit
    end
    else
      edtTime.Text := ''
  end;

  if (edtSrcCont.Text='') then
    edtSrcCont.Text := C_RBN_CONT;
  if (edtDXCont.Text='') then
    edtDXCont.Text := C_RBN_CONT;
  if (edtDXBand.Text='') then
    edtDXBand.Text := C_RBN_BANDS;
  if (edtDXMode.Text='') then
    edtDXMode.Text := C_RBN_MODES;

  cqrini.WriteString('RBNFilter','SrcCont',RmSp(edtSrcCont.Text));

  cqrini.WriteBool('RBNFilter','IgnHour',rbIgnWkdHour.Checked);
  cqrini.WriteInteger('RBNFilter','IgnHourValue',StrToint(edtLastHours.Text));
  cqrini.WriteBool('RBNFilter','IgnDate',rbIgnWkdDate.Checked);
  cqrini.WriteString('RBNFilter','IgnDateValue',edtDate.Text);
  cqrini.WriteString('RBNFilter','IgnTimeValue',edtTime.Text);

  cqrini.WriteBool('RBNFilter','AllowAllCall',rbAllDx.Checked);
  cqrini.WriteBool('RBNFilter','AllowOnlyCall',rbOnlyCall.Checked);
  cqrini.WriteString('RBNFilter','AllowOnlyCallValue',RmSp(edtDXOnlyCall.Text));
  cqrini.WriteBool('RBNFilter','AllowOnlyCallReg',rbOnlyCallReg.Checked);
  cqrini.WriteString('RBNFilter','AllowOnlyCallRegValue',edtDXOnlyExpres.Text);

  cqrini.WriteString('RBNFilter','AllowCont',RmSp(edtDXCont.Text));
  cqrini.WriteString('RBNFilter','AllowBands',RmSp(edtDXBand.Text));
  cqrini.WriteString('RBNFilter','AllowModes',RmSp(edtDXMode.Text));
  cqrini.WriteString('RBNFilter','AllowCnty',RmSp(edtDXCnty.Text));
  cqrini.WriteString('RBNFilter','NotCnty',RmSp(edtDXCNotCnty.Text));

  cqrini.WriteBool('RBNFilter','LoTWOnly',chkOnlyLoTW.Checked);
  cqrini.WriteBool('RBNFilter','eQSLOnly',chkOnlyeQSL.Checked);

  cqrini.WriteBool('RBNFilter','NewDXCOnly',chkNewDXConly.Checked);

  ModalResult := mrOK
end;

procedure TfrmRbnFilter.btnDXCCntyClick(Sender: TObject);
begin
  frmSelectDXCC := TfrmSelectDXCC.Create(self);
  try
    frmSelectDXCC.pgDXCC.PageIndex := 0;
    if frmSelectDXCC.ShowModal = mrOK then
    begin
      if (edtDXCnty.Text='') then
        edtDXCnty.Text := dmDXCC.qValid.Fields[1].AsString
      else
        edtDXCnty.Text := edtDXCnty.Text + ', '+dmDXCC.qValid.Fields[1].AsString
    end
  finally
    FreeAndNil(frmSelectDXCC)
  end
end;

procedure TfrmRbnFilter.btnDXCNotCntyClick(Sender: TObject);
begin
  frmSelectDXCC := TfrmSelectDXCC.Create(self);
  try
    frmSelectDXCC.pgDXCC.PageIndex := 0;
    if frmSelectDXCC.ShowModal = mrOK then
    begin
      if (edtDXCNotCnty.Text='') then
        edtDXCNotCnty.Text := dmDXCC.qValid.Fields[1].AsString
      else
        edtDXCNotCnty.Text := edtDXCNotCnty.Text + ', '+dmDXCC.qValid.Fields[1].AsString
    end
  finally
    FreeAndNil(frmSelectDXCC)
  end
end;

{ TfrmRbnFilter }

end.

