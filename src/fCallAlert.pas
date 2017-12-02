unit fCallAlert;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, DBGrids, ExtCtrls, StdCtrls, ActnList, LCLType, uMyIni;

type

  { TfrmCallAlert }

  TfrmCallAlert = class(TForm)
    acNew: TAction;
    acEdit: TAction;
    acDelete: TAction;
    acClose: TAction;
    ActionList1: TActionList;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    chkAllowRegExp: TCheckBox;
    dsrCallAlert: TDataSource;
    dbgrdCallAlert: TDBGrid;
    Panel1: TPanel;
    procedure acCloseExecute(Sender: TObject);
    procedure acDeleteExecute(Sender: TObject);
    procedure acEditExecute(Sender: TObject);
    procedure acNewExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    procedure RefreshCallsignList(const id : Integer=0);
  public
    { public declarations }
  end;

var
  frmCallAlert: TfrmCallAlert;

implementation
{$R *.lfm}

uses dUtils, dData, fNewCallAlert;

{ TfrmCallAlert }

procedure TfrmCallAlert.FormShow(Sender: TObject);
begin
  dmUtils.LoadForm(self);
  dsrCallAlert.DataSet := dmData.Q2;
  RefreshCallsignList();

  chkAllowRegExp.Checked := cqrini.ReadBool('DxCluster', 'AlertRegExp', False)
end;

procedure TfrmCallAlert.acNewExecute(Sender: TObject);
var
  F : TfrmNewCallAlert;
  band : String;
  mode : String;
begin
  F := TfrmNewCallAlert.Create(frmCallAlert);
  try
    F.cmbMode.ItemIndex := 0;
    F.cmbBand.ItemIndex := 0;
    if F.ShowModal = mrOK then
    begin
      if F.cmbMode.ItemIndex=0 then
        mode := ''
      else
        mode := F.cmbMode.Text;
      if F.cmbBand.ItemIndex=0 then
        band := ''
      else
        band := F.cmbBand.Text;
      dmData.AddCallAlert(F.edtCall.Text,band,mode);
      RefreshCallsignList(dmData.GetLastAllertCallId(F.edtCall.Text,band,mode))
    end
  finally
    FreeAndNil(F)
  end;
  dbgrdCallAlert.SetFocus
end;

procedure TfrmCallAlert.acEditExecute(Sender: TObject);
var
  F : TfrmNewCallAlert;
  band : String;
  mode : String;
begin
  F := TfrmNewCallAlert.Create(frmCallAlert);
  try
    F.Caption := 'Edit callsign alert';
    F.edtCall.Text := dmData.Q2.Fields[1].AsString;
    if dmData.Q2.Fields[2].AsString = '' then
      F.cmbBand.ItemIndex := 0
    else
      F.cmbBand.Text := dmData.Q2.Fields[2].AsString;

    if dmData.Q2.Fields[3].AsString = '' then
      F.cmbMode.ItemIndex := 0
    else
      F.cmbMode.Text := dmData.Q2.Fields[3].AsString;

    if F.ShowModal = mrOK then
    begin
      if F.cmbMode.ItemIndex=0 then
        mode := ''
      else
        mode := F.cmbMode.Text;
      if F.cmbBand.ItemIndex=0 then
        band := ''
      else
        band := F.cmbBand.Text;

      dmData.EditCallAlert(dmData.Q2.Fields[0].AsInteger,F.edtCall.Text,band,mode);
      RefreshCallsignList(dmData.Q2.Fields[0].AsInteger)
    end
  finally
    FreeAndNil(F)
  end;
  dbgrdCallAlert.SetFocus
end;

procedure TfrmCallAlert.acDeleteExecute(Sender: TObject);
begin
  if Application.MessageBox('Do you really want to delete this callsign?','Question',mb_YesNo + mb_IconQuestion) = idYes then
  begin
    dmData.DeleteCallAlert(dmData.Q2.Fields[0].AsInteger);
    RefreshCallsignList();
    dbgrdCallAlert.SetFocus
  end
end;

procedure TfrmCallAlert.acCloseExecute(Sender: TObject);
begin
  Close
end;

procedure TfrmCallAlert.RefreshCallsignList(const id : Integer=0);
begin
  dmData.Q2.Close;
  if dmData.trQ2.Active then dmData.trQ2.Rollback;
  dmData.trQ2.StartTransaction;
  dmData.Q2.SQL.Text := 'select * from call_alert order by callsign';
  dmData.Q2.Open;
  dbgrdCallAlert.Columns[0].Visible := False;
  dbgrdCallAlert.Columns[1].Width   := 100;
  dbgrdCallAlert.Columns[2].Width   := 100;
  dbgrdCallAlert.Columns[3].Width   := 100;

  if id>0 then
  begin
    dmData.Q2.DisableControls;
    try
      dmData.Q2.Locate('id',id,[])
    finally
      dmData.Q2.EnableControls
    end
  end;
end;

procedure TfrmCallAlert.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  dmUtils.SaveForm(self);
  dmData.Q2.Close;

  cqrini.WriteBool('DxCluster', 'AlertRegExp', chkAllowRegExp.Checked);

  if dmData.trQ2.Active then
    dmData.trQ2.Rollback
end;

end.

