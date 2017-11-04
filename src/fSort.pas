(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fSort;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, Buttons,
  StdCtrls;

type

  { TfrmSort }

  TfrmSort = class(TForm)
    btnDateTime: TButton;
    btnCall: TButton;
    btnClose: TButton;
    procedure FormShow(Sender: TObject);
    procedure btnCallClick(Sender: TObject);
    procedure btnDateTimeClick(Sender: TObject);
    procedure btnDateTimeClickAsc(Sender: TObject);
  private
    procedure DisableFilter;
  public
    { public declarations }
  end; 

var
  frmSort: TfrmSort;

implementation
{$R *.lfm}

{ TfrmSort }

uses dData, dUtils, fMain;

procedure TfrmSort.DisableFilter;
begin
  dmData.IsFilter  := False;
  dmData.IsSFilter := False;
  frmMain.sbMain.Panels[2].Text := ''
end;

procedure TfrmSort.btnDateTimeClick(Sender: TObject);
begin
  DisableFilter;
  dmData.SortType := stDate;
  dmData.qCQRLOG.Close;
  dmData.qCQRLOG.SQL.Text := 'select * from view_cqrlog_main_by_qsodate LIMIT '+IntToStr(cDB_LIMIT);
  dmData.RefreshMainDatabase()
end;

procedure TfrmSort.btnDateTimeClickAsc(Sender: TObject);
begin
  DisableFilter;
  dmData.SortType := stDate;
  dmData.qCQRLOG.Close;
  dmData.qCQRLOG.SQL.Text := 'select * from view_cqrlog_main_by_qsodate_asc LIMIT '+IntToStr(cDB_LIMIT);
  dmData.RefreshMainDatabase()
end;

procedure TfrmSort.btnCallClick(Sender: TObject);
begin
  DisableFilter;
  dmData.SortType := stCall;
  dmData.qCQRLOG.Close;
  dmData.qCQRLOG.SQL.Text := 'select * from view_cqrlog_main_by_callsign LIMIT '+IntToStr(cDB_LIMIT);
  dmData.RefreshMainDatabase()
end;

procedure TfrmSort.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(self)
end;

end.

