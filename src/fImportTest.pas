unit fImportTest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  DBGrids, Buttons, StdCtrls, ComCtrls, lcltype;

type

  { TfrmImportTest }

  TfrmImportTest = class(TForm)
    btnClose: TButton;
    btnImport: TButton;
    btnTest: TButton;
    btnEditQSO: TButton;
    btnDeleteQSO: TButton;
    dbgrdImport: TdbGrid;
    edtContestName: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    lblQSOCount: TLabel;
    Panel1: TPanel;
    pBarStat: TProgressBar;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnDeleteQSOClick(Sender: TObject);
    procedure btnEditQSOClick(Sender: TObject);
    procedure btnImportClick(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
  private
    //First : Boolean;
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmImportTest: TfrmImportTest;

implementation
{$R *.lfm}

{ TfrmImportTest }
uses dData, dUtils, dDXCC;

procedure TfrmImportTest.FormShow(Sender: TObject);
begin
  {dmData.qImport.FileName  := dmData.DataDir + 'import.dat';
  dmData.qImport.TableName := 'import';
  dmData.qImport.SQL       := 'SELECT * FROM import ORDER BY qsodate,time_on';
  dmData.qImport.Open;
  
  dbgrdImport.DataSource := dmData.dsrImport;
  dbgrdImport.Columns[dbgrdImport.Columns.Count-1].Visible := False;
  dbgrdImport.Columns[dbgrdImport.Columns.Count-2].Visible := False;
  dmUtils.LoadForm(self);
  dmData.qImport.Last;
  lblQSOCount.Caption := IntToStr(dmData.qImport.RecordCount);
  First := True;
  }
end;

procedure TfrmImportTest.btnDeleteQSOClick(Sender: TObject);
begin

end;

procedure TfrmImportTest.btnEditQSOClick(Sender: TObject);
begin

end;

procedure TfrmImportTest.btnImportClick(Sender: TObject);
{var
  pfx,country : String;
  idx : Integer;
}
begin
  {idx := dmData.GetNewId;

  dmData.qImport.First;
  dmData.qImport.DisableControls;
  pBarStat.Position := 0;
  pBarStat.Max      := dmData.qImport.RecordCount;
  }
  Application.ProcessMessages;
  {dmData.tblCQRLOG.DisableControls;
  try
    while not dmData.tblImport.Eof do
    begin
      dmUtils.SaveLog('Start saving QSO');
      dmData.tblCQRLOG.Append;
      dmData.tblCQRLOG.FieldByName('Datum').AsDateTime  := dmData.tblImport.FieldByName('Datum').AsDateTime;
      dmData.tblCQRLOG.FieldByName('time_on').asString  := dmData.tblImport.FieldByName('time_on').AsString;
      dmData.tblCQRLOG.FieldByName('time_off').asString := dmData.tblImport.FieldByName('time_off').AsString;
      dmData.tblCQRLOG.FieldByName('call').asString     := dmData.tblImport.FieldByName('call').AsString;
      dmData.tblCQRLOG.FieldByName('freq').asString     := dmData.tblImport.FieldByName('freq').AsString;
      dmData.tblCQRLOG.FieldByName('mode').asString     := dmData.tblImport.FieldByName('mode').AsString;
      dmData.tblCQRLOG.FieldByName('rst_s').asString    := dmData.tblImport.FieldByName('rst_s').AsString;
      dmData.tblCQRLOG.FieldByName('rst_r').asString    := dmData.tblImport.FieldByName('rst_r').AsString;
      dmData.tblCQRLOG.FieldByName('name').asString     := dmData.tblImport.FieldByName('name').AsString;
      dmData.tblCQRLOG.FieldByName('qth').asString      := dmData.tblImport.FieldByName('qth').AsString;
      dmData.tblCQRLOG.FieldByName('qsl_s').asString    := dmData.tblImport.FieldByName('qsl_s').AsString;
      dmData.tblCQRLOG.FieldByName('qsl_r').asString    := dmData.tblImport.FieldByName('qsl_r').AsString;
      dmData.tblCQRLOG.FieldByName('qsl_via').asString  := dmData.tblImport.FieldByName('qsl_via').AsString;
      dmData.tblCQRLOG.FieldByName('iota').asString     := dmData.tblImport.FieldByName('iota').AsString;
      dmData.tblCQRLOG.FieldByName('pwr').asString      := dmData.tblImport.FieldByName('pwr').AsString;
      dmData.tblCQRLOG.FieldByName('itu').asString      := dmData.tblImport.FieldByName('itu').AsString;
      dmData.tblCQRLOG.FieldByName('waz').asString      := dmData.tblImport.FieldByName('waz').AsString;
      dmData.tblCQRLOG.FieldByName('loc').asString      := dmData.tblImport.FieldByName('loc').AsString;
      dmData.tblCQRLOG.FieldByName('my_loc').asString   := dmData.tblImport.FieldByName('my_loc').AsString;
      dmData.tblCQRLOG.FieldByName('county').asString   := dmData.tblImport.FieldByName('county').AsString;
      dmData.tblCQRLOG.FieldByName('remarks').asString  := dmData.tblImport.FieldByName('remarks').AsString;
      if dmData.tblImport.FieldByName('dxcc_ref').AsString = '' then
      begin
        dmUtils.SaveLog('Before id_country');
        dmDXCC.id_country(dmData.tblCQRLOG.FieldByName('call').asString, dmData.tblCQRLOG.FieldByName('Datum').AsDateTime,
                          pfx,country);
        dmUtils.SaveLog('After id_country');
      end
      else begin
        pfx := dmData.tblImport.FieldByName('dxcc_ref').AsString;
        dmData.tblCQRLOG.FieldByName('qso_dxcc').asBoolean := True;
      end;
      dmData.tblCQRLOG.FieldByName('dxcc_ref').asString  := pfx;

      dmData.tblCQRLOG.FieldByName('idx').AsInteger := idx;
      dmData.tblCQRLOG.Post;
      dmUtils.SaveLog(dmData.tblCQRLOG.FieldByName('call').asString);
      dmUtils.SaveLog('After SaveQSO');
      
      dmUtils.SaveLog('Before SaveDXCC');
      dmDXCC.SaveDXCC(dmData.tblCQRLOG.FieldByName('Datum').AsDateTime, dmData.tblCQRLOG.FieldByName('call').asString,
                      pfx, dmData.tblCQRLOG.FieldByName('freq').asString, dmData.tblCQRLOG.FieldByName('mode').asString,
                      dmData.tblCQRLOG.FieldByName('qsl_r').asString);
      dmUtils.SaveLog('After SaveDXCC');
      dmData.tblImport.Next;
      pBarStat.StepIt;
      if (pBarStat.Position mod 100 = 0) then
        Application.ProcessMessages;
      inc(idx);
    end;
  finally
    dmData.tblImport.EnableControls;
    dmData.tblCQRLOG.EnableControls;
  end;  }
end;

procedure TfrmImportTest.btnTestClick(Sender: TObject);
begin
  {dmData.qImport.DisableControls;
  try
    if First then
    begin
      dmData.qImport.First;
      pBarStat.Position := 0;
      pBarStat.Max := dmData.qImport.RecordCount;
    end
    else begin
      dmData.qImport.MoveBy(-20);
      if pBarStat.Position >= 2 then
        pBarStat.Position := pBarStat.Position - 2;
      if pBarStat.Position = 1 then
        pBarStat.Position := 0;
    end;
    First := False;
    while not dmData.qImport.Eof do
    begin
      if dmData.qImport.FieldByName('Call').AsString = '' then
      begin
        Application.MessageBox('Call is missing!', 'Error!', MB_ICONERROR + MB_OK);
        exit
      end;
      if dmData.qImport.FieldByName('RST_S').AsString = '' then
      begin
        Application.MessageBox('RST_S is missing!', 'Error!', MB_ICONERROR + MB_OK);
        exit
      end;
      if dmData.qImport.FieldByName('RST_R').AsString = '' then
      begin
        Application.MessageBox('RST_R is missing!', 'Error!', MB_ICONERROR + MB_OK);
        exit
      end;
      if dmData.qImport.FieldByName('FREQ').AsString = '' then
      begin
        Application.MessageBox('Frequency is missing!', 'Error!', MB_ICONERROR + MB_OK);
        exit
      end
      else begin
        if dmUtils.GetBandFromFreq(dmData.qImport.FieldByName('FREQ').AsString) = 0 then
        begin
          Application.MessageBox('Bad frequency!','Error!',MB_ICONERROR + MB_OK);
          exit
        end;
      end;
      if Pos('/',dmData.qImport.FieldByName('MODE').AsString) < 1 then
      begin
        if not dmUtils.IsModeOK(dmData.qImport.FieldByName('MODE').AsString) then
        begin
          Application.MessageBox('Bad mode!', 'Error!', MB_ICONERROR + MB_OK);
          exit
        end;
      end;
      if not dmUtils.IsTimeOK(dmData.qImport.FieldByName('time_on').AsString) then
      begin
        Application.MessageBox('Bad time_on!', 'Error!', MB_ICONERROR + MB_OK);
        exit
      end;
      if not dmUtils.IsTimeOK(dmData.qImport.FieldByName('time_off').AsString) then
      begin
        Application.MessageBox('Bad time_off!', 'Error!', MB_ICONERROR + MB_OK);
        exit
      end;
      pBarStat.StepIt;
      if pBarStat.Position mod 100 = 0 then
        Application.ProcessMessages;
      dmData.qImport.Next;
    end;
    Application.MessageBox('All looks OK. Now, you can import QSO to logbook.','Info ...',
                             MB_ICONINFORMATION + mb_OK);
    btnImport.Enabled := True;
  finally
    dmData.qImport.EnableControls;
  end;
  }
end;

procedure TfrmImportTest.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveForm(self);
  //dmData.qImport.Close;
end;

end.

