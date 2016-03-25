unit fCommentToCall;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, DBGrids, StdCtrls, LCLType, ActnList;

type

  { TfrmCommentToCall }

  TfrmCommentToCall = class(TForm)
    acComment : TActionList;
    acSearch : TAction;
    acNew : TAction;
    acEdit : TAction;
    acDelete : TAction;
    Button1 : TButton;
    btnNew : TButton;
    btnEdit : TButton;
    btnDelete : TButton;
    btnFind : TButton;
    dsrComment : TDataSource;
    dbgrdComment : TDBGrid;
    Panel1 : TPanel;
    procedure acDeleteExecute(Sender : TObject);
    procedure acEditExecute(Sender : TObject);
    procedure acNewExecute(Sender : TObject);
    procedure acSearchExecute(Sender : TObject);
    procedure dbgrdCommentColumnSized(Sender : TObject);
    procedure dbgrdCommentDblClick(Sender : TObject);
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure FormShow(Sender : TObject);
  private
    procedure RefreshData(Callsign : String = '');
  public
    { public declarations }
  end;

var
  frmCommentToCall : TfrmCommentToCall;

implementation

uses dData, dUtils, fNewCommentToCall, fFindCommentToCall;

{ TfrmCommentToCall }

procedure TfrmCommentToCall.FormClose(Sender : TObject; var CloseAction : TCloseAction);
begin
  dmUtils.SaveWindowPos(frmCommentToCall);
  if dmData.trComment.Active then
    dmData.trComment.Rollback
end;

procedure TfrmCommentToCall.dbgrdCommentColumnSized(Sender : TObject);
begin
  dmUtils.SaveForm(frmCommentToCall)
end;

procedure TfrmCommentToCall.dbgrdCommentDblClick(Sender : TObject);
begin
  acEdit.Execute
end;

procedure TfrmCommentToCall.acSearchExecute(Sender : TObject);
begin
  frmFindCommentToCall := TfrmFindCommentToCall.Create(frmCommentToCall);
  try
    if frmFindCommentToCall.ShowModal = mrOK then
    begin
      RefreshData(frmFindCommentToCall.edtCallsign.Text);
      if frmFindCommentToCall.edtCallsign.Text<>dmData.qComment.Fields[1].AsString then
        Application.MessageBox('Callsign not found', 'Info', mb_OK+mb_IconInformation)
    end
  finally
    frmFindCommentToCall.Free
  end
end;

procedure TfrmCommentToCall.acNewExecute(Sender : TObject);
begin
  frmNewCommentToCall := TfrmNewCommentToCall.Create(frmCommentToCall);
  try
    if frmNewCommentToCall.ShowModal = mrOK then
    begin
      dmData.SaveComment(frmNewCommentToCall.edtCallsign.Text,frmNewCommentToCall.mNote.Text);
      RefreshData(frmNewCommentToCall.edtCallsign.Text)
    end
  finally
    frmNewCommentToCall.Free
  end
end;

procedure TfrmCommentToCall.acEditExecute(Sender : TObject);
begin
  if dmData.qComment.RecordCount = 0 then
  begin
    acNew.Execute;
    exit
  end;

  frmNewCommentToCall := TfrmNewCommentToCall.Create(frmCommentToCall);
  try
    frmNewCommentToCall.Caption := 'Change note to ' + dmData.qComment.Fields[1].AsString;
    frmNewCommentToCall.edtCallsign.Enabled := False;
    frmNewCommentToCall.edtCallsign.Text    := dmData.qComment.Fields[1].AsString;
    frmNewCommentToCall.mNote.Lines.Text    := dmData.qComment.Fields[2].AsString;
    if frmNewCommentToCall.ShowModal = mrOK then
    begin
      dmData.SaveComment(frmNewCommentToCall.edtCallsign.Text,frmNewCommentToCall.mNote.Text);
      RefreshData(frmNewCommentToCall.edtCallsign.Text)
    end
  finally
    frmNewCommentToCall.Free
  end
end;

procedure TfrmCommentToCall.acDeleteExecute(Sender : TObject);
begin
  if dmData.qComment.RecordCount = 0 then
    exit;

  if Application.MessageBox('Do you really want to delete this note?','Question',mb_YesNo+mb_IconQuestion) = idYes then
  begin
    dmData.DeleteComment(dmData.qComment.Fields[0].AsInteger);
    RefreshData()
  end
end;

procedure TfrmCommentToCall.FormShow(Sender : TObject);
begin
  dmUtils.LoadWindowPos(frmCommentToCall);
  dmUtils.LoadForm(frmCommentToCall);
  RefreshData()
end;

procedure TfrmCommentToCall.RefreshData(Callsign : String = '');
const
  C_SEL = 'select * from notes order by callsign';
begin
  if dmData.trComment.Active then
    dmData.trComment.Rollback;
  dmData.qComment.SQL.Text := C_SEL;
  dmData.trComment.StartTransaction;
  dmData.qComment.Open;

  dbgrdComment.Columns[0].Visible := False;

  if (Callsign<>'') then
  begin
    dmData.qComment.DisableControls;
    try
      dmData.qComment.First;
      while not dmData.qComment.Eof do
      begin
        if (dmData.qComment.Fields[1].AsString=Callsign) then
          break
        else
          dmData.qComment.Next
      end
    finally
      dmData.qComment.EnableControls
    end
  end;

  dmUtils.LoadForm(frmCommentToCall);
  dbgrdComment.Columns[1].Title.Caption := 'Callsign';
  dbgrdComment.Columns[2].Title.Caption := 'Note'
end;

initialization
  {$I fCommentToCall.lrs}

end.

