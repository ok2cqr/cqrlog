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
    dsrFreq: TDatasource;
    dbgrdFreq: TDBGrid;
    Panel1: TPanel;
    procedure FormShow(Sender: TObject);
    procedure btnChangeClick(Sender: TObject);
  private
    procedure SetColumns;
  public
    { public declarations }
  end; 

var
  frmFreq: TfrmFreq;

implementation

{ TfrmFreq }
uses dData, fChangeFreq;

procedure TfrmFreq.FormShow(Sender: TObject);
begin
  dmData.qBands.Close;
  dmData.qBands.SQL.Text := 'SELECT * FROM cqrlog_common.bands ORDER BY b_begin';
  if dmData.DebugLevel >=1 then
     Writeln(dmData.qBands.SQL.Text);
  if dmData.trBands.Active then
    dmData.trBands.Rollback;
  dmData.trBands.StartTransaction;
  dmData.qBands.Open;
  SetColumns
end;

procedure TfrmFreq.btnChangeClick(Sender: TObject);
var
  band : String;
begin
  with TfrmChangeFreq.Create(self) do
  try
    band          := dmData.qBands.Fields[1].AsString;
    edtBegin.Text := FloatToStr(dmData.qBands.Fields[2].AsFloat);
    edtEnd.Text   := FloatToStr(dmData.qBands.Fields[3].AsFloat);
    edtCW.Text    := FloatToStr(dmData.qBands.Fields[4].AsFloat);
    edtRTTY.Text  := FloatToStr(dmData.qBands.Fields[5].AsFloat);
    edtSSB.Text   := FloatToStr(dmData.qBands.Fields[6].AsFloat);
    ShowModal;
    if ModalResult = mrOK then
    begin
      if dmData.trBands.Active then
        dmData.trBands.Rollback;
      dmData.trBands.StartTransaction;
      dmData.qBands.Close;
      dmData.qBands.SQL.Clear;
      dmData.qBands.SQL.Add('UPDATE cqrlog_common.bands SET b_begin = ' + edtBegin.Text+',');
      dmData.qBands.SQL.Add('b_end = ' + edtEnd.Text+', cw = ' + edtCW.Text+',');
      dmData.qBands.SQL.Add('rtty = ' + edtRTTY.Text+', ssb =' + edtSSB.Text);
      dmData.qBands.SQL.Add(' WHERE band = ' + QuotedStr(band));
      if dmData.DebugLevel >=1 then Writeln(dmData.qBands.SQL.Text);
      dmData.qBands.ExecSQL;
      dmData.trBands.Commit;
      
      dmData.qBands.SQL.Text := 'SELECT * FROM cqrlog_common.bands ORDER BY b_begin';
      if dmData.DebugLevel >=1 then Writeln(dmData.qBands.SQL.Text);
      dmData.trBands.StartTransaction;
      dmData.qBands.Open;
      SetColumns
    end
  finally
    Free
  end
end;

procedure TfrmFreq.SetColumns;
var i : Integer;
begin
  dsrFreq.DataSet := dmData.qBands;
  dbgrdFreq.Columns[0].Visible := False;
  //dbgrdFreq.Columns[dbgrdFreq.Columns.Count-1].Visible := False;
  for i:=1 to 5 do
    dbgrdFreq.Columns[i].Width := 70;
end;

initialization
  {$I fFreq.lrs}

end.

