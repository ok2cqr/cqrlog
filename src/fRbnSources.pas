(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The list of RBN source presets (cqrlog_common.rbn_sources): add, edit, delete.
  Which preset the main connection uses is chosen in the RBN control window. }

unit fRbnSources;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs, LCLType, dSqlRef;

type
  TfrmRbnSources = class(TForm)
    btnAdd: TButton;
    btnClose: TButton;
    btnDelete: TButton;
    btnEdit: TButton;
    lbSources: TListBox;
    procedure btnAddClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FList : TRbnSourceList;
    procedure Reload(SelectId : Integer = 0);
    function  Selected(out Source : TRbnSource) : Boolean;
  public
    //the id of the row the user selected last, for the caller's combo box
    SelectedId : Integer;
  end;

//"OK1RR (telnet.reversebeacon.net:7000)"
function RbnSourceCaption(const Source : TRbnSource) : String;

implementation

{$R *.lfm}

uses
  fRbnSourceEdit;

function RbnSourceCaption(const Source : TRbnSource) : String;
begin
  Result := Source.Description + ' (' + Source.Address + ':' + IntToStr(Source.Port) + ')'
end;

procedure TfrmRbnSources.FormShow(Sender: TObject);
begin
  Reload(SelectedId)
end;

procedure TfrmRbnSources.Reload(SelectId : Integer);
var
  i : Integer;
begin
  FList := dmSqlRef.LoadRbnSources;
  lbSources.Items.BeginUpdate;
  try
    lbSources.Clear;
    for i := 0 to High(FList) do
    begin
      lbSources.Items.Add(RbnSourceCaption(FList[i]));
      if FList[i].Id = SelectId then
        lbSources.ItemIndex := i
    end;
    if (lbSources.ItemIndex < 0) and (lbSources.Count > 0) then
      lbSources.ItemIndex := 0
  finally
    lbSources.Items.EndUpdate
  end;
  if lbSources.ItemIndex >= 0 then
    SelectedId := FList[lbSources.ItemIndex].Id
end;

function TfrmRbnSources.Selected(out Source : TRbnSource) : Boolean;
begin
  Result := (lbSources.ItemIndex >= 0) and (lbSources.ItemIndex <= High(FList));
  if Result then
    Source := FList[lbSources.ItemIndex]
  else
    Source := Default(TRbnSource)
end;

procedure TfrmRbnSources.btnAddClick(Sender: TObject);
var
  Id : Integer;
begin
  with TfrmRbnSourceEdit.Create(self) do
  try
    Source := Default(TRbnSource);
    Source.Port := 7000;
    if Edit then
    begin
      Id := dmSqlRef.InsertRbnSource(Source);
      Reload(Id)
    end
  finally
    Free
  end
end;

procedure TfrmRbnSources.btnEditClick(Sender: TObject);
var
  Src : TRbnSource;
begin
  if not Selected(Src) then
    exit;
  with TfrmRbnSourceEdit.Create(self) do
  try
    Source := Src;
    if Edit then
    begin
      dmSqlRef.UpdateRbnSource(Source);
      Reload(Source.Id)
    end
  finally
    Free
  end
end;

procedure TfrmRbnSources.btnDeleteClick(Sender: TObject);
var
  Src : TRbnSource;
begin
  if not Selected(Src) then
    exit;
  if Application.MessageBox(PChar('Delete "' + Src.Description + '"?'), 'Question ...',
                            mb_YesNo + mb_IconQuestion) <> idYes then
    exit;
  dmSqlRef.DeleteRbnSource(Src.Id);
  Reload
end;

end.
