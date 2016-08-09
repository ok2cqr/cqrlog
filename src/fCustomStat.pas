unit fCustomStat;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Grids, StdCtrls, PairSplitter, iniFiles;

type

  { TfrmCustomStat }

  TfrmCustomStat = class(TForm)
    btnCancel: TButton;
    btnExport: TButton;
    btnShow: TButton;
    btnPref: TButton;
    btnHelp: TButton;
    chkBand: TCheckBox;
    chkMode: TCheckBox;
    cmbMode: TComboBox;
    cmbField: TComboBox;
    cmbQSLR: TComboBox;
    edtPfx: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Panel1: TPanel;
    pnlsettings: TPanel;
    Panel2: TPanel;
    Splitter1: TSplitter;
    grdStat: TStringGrid;
    grdSumStat: TStringGrid;
    procedure FormShow(Sender: TObject);
    procedure btnPrefClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnShowClick(Sender: TObject);
  private
    procedure GetVisibleBands;
    procedure PrepareGrids;
  public
    { public declarations }
  end; 

var
  frmCustomStat: TfrmCustomStat;
  p160,p80,p40,p30,p20,p17,p15,p12 : Integer;
  p10,p6,p2,p70,p23,p13,p8,p3,p1   : Integer;
  p47,p76,p137,tmp,p5,p4           : Integer;

implementation
{$R *.lfm}

uses dUtils, fSelectDXCC, dData, uMyIni, dDXCC;
{ TfrmCustomStat }
procedure TfrmCustomStat.GetVisibleBands;
begin
  grdStat.ColCount    := 30;
  grdSumStat.ColCount := 30;
  p137 := 0;
  p160 := 0;
  p80  := 0;
  p40  := 0;
  p30  := 0;
  p20  := 0;
  p17  := 0;
  p15  := 0;
  p12  := 0;
  p10  := 0;
  p6   := 0;
  p4   := 0;
  p2   := 0;
  p70  := 0;
  tmp  := 0;
  if cqrini.ReadBool('Bands','137kHz',false) then
  begin
    inc(tmp);
    p137 := tmp;
    grdStat.Cells[p137,0]    := dmUtils.s136;
    grdSumStat.Cells[p137,0] := dmUtils.s136;
    if cmbMode.Text <> '' then
    begin
      if cmbMode.ItemIndex = 1 then
        grdStat.Cells[p137,1]    := 'F  C  D'
      else
        grdStat.Cells[p137,1]    := cmbMode.Text
    end
  end;

  if cqrini.ReadBool('Bands','160m',true) then
  begin
    inc(tmp);
    p160 := tmp;
    grdStat.Cells[p160,0]    := dmUtils.s160;
    grdSumStat.Cells[p160,0] := dmUtils.s160;
  end;

  if cqrini.ReadBool('Bands','80m',true) then
  begin
    inc(tmp);
    p80 := tmp;
    grdStat.Cells[p80,0]    := dmUtils.s80;
    grdSumStat.Cells[p80,0] := dmUtils.s80;
  end;

  if cqrini.ReadBool('Bands','40m',true) then
  begin
    inc(tmp);
    p40 := tmp;
    grdStat.Cells[p40,0]    := dmUtils.s40;
    grdSumStat.Cells[p40,0] := dmUtils.s40;
  end;

  if cqrini.ReadBool('Bands','30m',true) then
  begin
    inc(tmp);
    p30 := tmp;
    grdStat.Cells[p30,0]    := dmUtils.s30;
    grdSumStat.Cells[p30,0] := dmUtils.s30;
  end;

  if cqrini.ReadBool('Bands','20m',true) then
  begin
    inc(tmp);
    p20 := tmp;
    grdStat.Cells[p20,0]    := dmUtils.s20;
    grdSumStat.Cells[p20,0] := dmUtils.s20;
  end;

  if cqrini.ReadBool('Bands','17m',true) then
  begin
    inc(tmp);
    p17 := tmp;
    grdStat.Cells[p17,0]    := dmUtils.s17;
    grdSumStat.Cells[p17,0] := dmUtils.s17;
  end;

  if cqrini.ReadBool('Bands','15m',true) then
  begin
    inc(tmp);
    p15 := tmp;
    grdStat.Cells[p15,0]    := dmUtils.s15;
    grdSumStat.Cells[p15,0] := dmUtils.s15;
  end;

  if cqrini.ReadBool('Bands','12m',true) then
  begin
    inc(tmp);
    p12 := tmp;
    grdStat.Cells[p12,0]    := dmUtils.s12;
    grdSumStat.Cells[p12,0] := dmUtils.s12;
  end;

  if cqrini.ReadBool('Bands','10m',true) then
  begin
    inc(tmp);
    p10 := tmp;
    grdStat.Cells[p10,0]    := dmUtils.s10;
    grdSumStat.Cells[p10,0] := dmUtils.s10;
  end;

  if cqrini.ReadBool('Bands','6m',true) then
  begin
    inc(tmp);
    p6 := tmp;
    grdStat.Cells[p6,0]    := dmUtils.s6;
    grdSumStat.Cells[p6,0] := dmUtils.s6;
  end;

  if cqrini.ReadBool('Bands','4m',False) then
  begin
    inc(tmp);
    p4 := tmp;
    grdStat.Cells[p4,0]    := dmUtils.s4;
    grdSumStat.Cells[p4,0] := dmUtils.s4;
  end;

  if cqrini.ReadBool('Bands','2m',true) then
  begin
    inc(tmp);
    p2 := tmp;
    grdStat.Cells[p2,0]    := dmUtils.s2;
    grdSumStat.Cells[p2,0] := dmUtils.s2;
  end;

  if cqrini.ReadBool('Bands','70cm',true) then
  begin
    inc(tmp);
    p70 := tmp;
    grdStat.Cells[p70,0]    := dmUtils.s70;
    grdSumStat.Cells[p70,0] := dmUtils.s70;
  end;
  grdStat.ColCount    := tmp+1;
  grdSumStat.ColCount := tmp+1
end;

procedure TfrmCustomStat.FormCreate(Sender: TObject);
begin
  dmUtils.InsertModes(cmbMode);
  cmbMode.Items.Insert(1,'PHONE+CW+DIGI');
end;

procedure TfrmCustomStat.PrepareGrids;
begin
  if p80 > 0 then
    grdStat.Cells[p80,1] := 'A B C';
end;


procedure TfrmCustomStat.btnShowClick(Sender: TObject);
var
  where : String = '';
  dxcc  : TExplodeArray;
  i     : Integer;
  dx    : String = '';
begin
  GetVisibleBands;
  PrepareGrids;
  SetLength(dxcc,0);
  dmData.Q.Close;
  if dmData.trQ.Active then
    dmData.trQ.RollBack;
  dmData.trQ.StartTransaction;
  if cmbMode.Text <> '' then
    where := 'mode = ' + QuotedStr(cmbMode.Text) + 'AND ';
  if (edtPfx.Text <> '') then
  begin
    dxcc := dmUtils.Explode(';',edtPfx.Text);
    for i:=0 to Length(dxcc)-1 do
      dx := dx + 'dxcc_ref=' + QuotedStr(dxcc[i]) + ' OR';
    dx := '('+copy(dx,1,Length(dx)-3)+') ';
    where := where + dx + 'AND '
  end;
  where := Trim(where);
  where := copy(where,1,Length(where)-3);
  dmData.Q.SQL.Text := 'select ' + cmbField.Text + ' from cqrlog_main ' +
                        where + 'order by ' + cmbField.Text;
  if dmData.DebugLevel >=1 then Writeln(dmData.Q.SQL.Text)
end;

procedure TfrmCustomStat.btnPrefClick(Sender: TObject);
begin
  frmSelectDXCC := TfrmSelectDXCC.Create(self);
  try
    frmSelectDXCC.pgDXCC.PageIndex := 0;
    frmSelectDXCC.ShowModal;
    if frmSelectDXCC.ModalResult = mrOK then
    begin
      if Pos('*',frmSelectDXCC.edtPrefix.Text) = 0 then
        edtPfx.Text := edtPfx.Text + dmDXCC.qValid.Fields[1].AsString +';'
      else
        edtPfx.Text := edtPfx.Text + dmDXCC.qDeleted.Fields[1].AsString +';'
    end;
  finally
    frmSelectDXCC.Free
  end;
end;

procedure TfrmCustomStat.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(self)
end;

end.

