unit fFreq;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, ExtCtrls, DBGrids, db;

type

  { TfrmFreq }

  TfrmFreq = class(TForm)
    btnChange: TButton;
    btnCancel: TButton;
    dbgrdFreq: TDBGrid;
    dsrFreq: TDatasource;
    lblFreqNote1: TLabel;
    lblFreqNote2: TLabel;
    lblFreqNote3: TLabel;
    lblFreqNote4: TLabel;
    pnlFreq2: TPanel;
    procedure dbgrdFreqColumnSized(Sender : TObject);
    procedure dbgrdFreqDblClick(Sender : TObject);
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnChangeClick(Sender: TObject);
  private
    procedure RefreshData(band : String = '');
  public
    { public declarations }
  end; 

var
  frmFreq: TfrmFreq;

implementation
{$R *.lfm}

{ TfrmFreq }
uses dData, fChangeFreq, dUtils;

procedure TfrmFreq.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmFreq);
  RefreshData()
end;

procedure TfrmFreq.FormClose(Sender : TObject; var CloseAction : TCloseAction);
begin
  dmUtils.SaveWindowPos(frmFreq);
  if dmData.trFreqs.Active then
    dmData.trFreqs.Rollback
end;

procedure TfrmFreq.dbgrdFreqColumnSized(Sender : TObject);
begin
  dmUtils.SaveForm(frmFreq)
end;

procedure TfrmFreq.dbgrdFreqDblClick(Sender : TObject);
begin
  btnChange.Click
end;

procedure TfrmFreq.btnChangeClick(Sender: TObject);
var
  band : String;
begin
  with TfrmChangeFreq.Create(frmFreq) do
  try
    band             := dmData.qFreqs.Fields[1].AsString;
    edtBegin.Text    := FloatToStr(dmData.qFreqs.Fields[2].AsFloat);
    edtEnd.Text      := FloatToStr(dmData.qFreqs.Fields[3].AsFloat);
    edtCW.Text       := FloatToStr(dmData.qFreqs.Fields[4].AsFloat);
    edtData.Text     := FloatToStr(dmData.qFreqs.Fields[5].AsFloat);
    edtSSB.Text      := FloatToStr(dmData.qFreqs.Fields[6].AsFloat);
    edtRXOffset.Text := FloatToStr(dmData.qFreqs.Fields[7].AsFloat);
    edtTXOffset.Text := FloatToStr(dmData.qFreqs.Fields[8].AsFloat);
    ShowModal;

    if ModalResult = mrOK then
    begin
      dmData.SaveBandChanges(
                             band,
                             StrToFloat(edtBegin.Text),
                             StrToFloat(edtEnd.Text),
                             StrToFloat(edtCW.Text),
                             StrToFloat(edtData.Text),
                             StrToFloat(edtSSB.Text),
                             StrToFloat(edtRXOffset.Text),
                             StrToFloat(edtTXOffset.Text)
      );
      RefreshData(band)
    end
  finally
    Free
  end
end;

procedure TfrmFreq.RefreshData(band : String = '');
const
  C_SEL = 'SELECT * FROM cqrlog_common.bands ORDER BY b_begin';
var
  i : Integer;
begin
  if dmData.trFreqs.Active then
    dmData.trFreqs.Rollback;

  dmData.qFreqs.SQL.Text := C_SEL;
  dmData.trFreqs.StartTransaction;
  dmData.qFreqs.Open;

  dbgrdFreq.Columns[0].Visible := False;

  if (band<>'') then
  begin
    dmData.qFreqs.DisableControls;
    try
      dmData.qFreqs.First;
      while not dmData.qFreqs.Eof do
      begin
        if (dmData.qFreqs.Fields[1].AsString=band) then
          break
        else
          dmData.qFreqs.Next
      end
    finally
      dmData.qFreqs.EnableControls
    end
  end;

  dmUtils.LoadForm(frmFreq);
  dbgrdFreq.Columns[1].Title.Caption := 'Band';
  dbgrdFreq.Columns[2].Title.Caption := 'Begin';
  dbgrdFreq.Columns[3].Title.Caption := 'End';
  dbgrdFreq.Columns[4].Title.Caption := 'CW';
  dbgrdFreq.Columns[5].Title.Caption := 'Data';
  dbgrdFreq.Columns[6].Title.Caption := 'SSB';
  dbgrdFreq.Columns[7].Title.Caption := 'RX offset';
  dbgrdFreq.Columns[8].Title.Caption := 'TX offset';

  for i:=2 to dbgrdFreq.Columns.Count-1 do
    dbgrdFreq.Columns[i].DisplayFormat   := '####0.000;;'
end;

end.

