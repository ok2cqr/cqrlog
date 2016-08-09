unit fDXClusterList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, DBGrids,
  ExtCtrls, Buttons, StdCtrls, inifiles, lcltype, db;

type

  { TfrmDXClusterList }

  TfrmDXClusterList = class(TForm)
    btnNew: TButton;
    btnEdit: TButton;
    btnDelete: TButton;
    btnCancel: TButton;
    btnApply: TButton;
    dbgrdDXClusterList: TDBGrid;
    Panel1: TPanel;
    procedure dbgrdDXClusterListDblClick(Sender : TObject);
    procedure FormShow(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
  private
    procedure ShowFields;
    procedure RefreshData(const id:Integer=0);
  public
    OldDesc : String;
  end; 

var
  frmDXClusterList: TfrmDXClusterList;

implementation
{$R *.lfm}

{ TfrmDXClusterList }
uses dData, dUtils, fNewDXCluster;

procedure TfrmDXClusterList.RefreshData(const id:Integer=0);
begin
  dmData.qDXClusters.DisableControls;
  try
    dmData.qDXClusters.Close;
    if dmData.trDXClusters.Active then dmData.trDXClusters.Rollback;
    dmData.trDXClusters.StartTransaction;
    dmData.qDXClusters.SQL.Text := 'select * from cqrlog_common.dxclusters order by description';
    dmData.qDXClusters.Open;
    if id > 0 then
      dmData.QueryLocate(dmData.qDXClusters,'id_dxclusters',id,False)
  finally
    dmData.qDXClusters.EnableControls;
    ShowFields
  end
end;

procedure TfrmDXClusterList.ShowFields;
begin
  dbgrdDXClusterList.Columns[dbgrdDXClusterList.Columns.Count-1].Visible := False;
  dbgrdDXClusterList.Columns[dbgrdDXClusterList.Columns.Count-2].Visible := False;
  dbgrdDXClusterList.Columns[0].Visible := False;
  dbgrdDXClusterList.Columns[1].Width   := 100;
  dbgrdDXClusterList.Columns[2].Width   := 150;
  dbgrdDXClusterList.Columns[3].Width   := 50
end;

procedure TfrmDXClusterList.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(frmDXClusterList);
  dbgrdDXClusterList.DataSource := dmData.dsrDXCluster;
  RefreshData();
  if OldDesc <> '' then
    dmData.QueryLocate(dmData.qDXClusters,'DESCRIPTION',OldDesc,True)
end;

procedure TfrmDXClusterList.dbgrdDXClusterListDblClick(Sender : TObject);
begin
  if dmData.qDXClusters.RecordCount > 0 then
    btnEdit.Click
end;

procedure TfrmDXClusterList.btnDeleteClick(Sender: TObject);
var
  id : Integer;
begin
  if Application.MessageBox('Do you realy want to delete this dxcluster?',
                            'Question ...', MB_ICONQUESTION + MB_YESNO) = idNo then
    exit;

  id := dmData.qDXClusters.FieldByName('id_dxclusters').AsInteger;
  dmData.qDXClusters.Close;
  if dmData.trDXClusters.Active then dmData.trDXClusters.Rollback;
  dmData.qDXClusters.SQL.Text := 'delete from cqrlog_common.dxclusters where id_dxclusters = ' + IntToStr(id);
  if dmData.DebugLevel >=1 then Writeln(dmData.qDXClusters.SQL.Text);
  dmData.trDXClusters.StartTransaction;
  dmData.qDXClusters.ExecSQL;
  dmData.trDXClusters.Commit;
  RefreshData()
end;

procedure TfrmDXClusterList.btnEditClick(Sender: TObject);
var
  id : Integer=0;
begin
  with TfrmNewDXCluster.Create(self) do
  try
    id                  := dmData.qDXClusters.Fields[0].AsInteger;
    edtDescription.Text := dmData.qDXClusters.Fields[1].AsString;
    edtAddress.Text     := dmData.qDXClusters.Fields[2].AsString;
    edtPort.Text        := dmData.qDXClusters.Fields[3].AsString;
    edtUserName.Text    := dmData.qDXClusters.Fields[4].AsString;
    edtPassword.Text    := dmData.qDXClusters.Fields[5].AsString;
    ShowModal;
    if ModalResult = mrOK then
    begin
      dmData.qDXClusters.Close;
      dmData.qDXClusters.SQL.Text := 'UPDATE cqrlog_common.dxclusters SET description='+QuotedStr(edtDescription.Text)+
                                      ',address='+QuotedStr(edtAddress.Text)+
                                      ',port='+QuotedStr(edtPort.Text)+
                                      ',dxcuser='+QuotedStr(edtUserName.Text)+
                                      ',dxcpass='+QuotedStr(edtPassword.Text)+
                                      ' WHERE id_dxclusters = '+IntToStr(id);
      if dmData.DebugLevel >=1 then Writeln(dmData.qDXClusters.SQL.Text);
      dmData.trDXClusters.Rollback;
      dmData.trDXClusters.StartTransaction;
      dmData.qDXClusters.ExecSQL;
      dmData.trDXClusters.Commit
    end
  finally
    Free;
    RefreshData(id)
  end
end;

procedure TfrmDXClusterList.btnNewClick(Sender: TObject);
begin
  with TfrmNewDXCluster.Create(self) do
  try
    ShowModal;
    if ModalResult = mrOK then
    begin
      dmData.qDXClusters.Close;
      dmData.qDXClusters.SQL.Text := 'INSERT INTO cqrlog_common.dxclusters (description,address,port,dxcuser,dxcpass) ' +
                'values ('+QuotedStr(edtDescription.Text) + ',' + QuotedStr(edtAddress.Text) +
                ','+QuotedStr(edtPort.Text)+','+QuotedStr(edtUserName.Text)+
                ','+QuotedStr(edtPassword.Text)+')';
      if dmData.DebugLevel >=1 then Writeln(dmData.qDXClusters.SQL.Text);
      dmData.trDXClusters.Rollback;
      dmData.trDXClusters.StartTransaction;
      dmData.qDXClusters.ExecSQL;
      dmData.trDXClusters.Commit;
      RefreshData()
    end
  finally
    Free
  end
end;

end.

