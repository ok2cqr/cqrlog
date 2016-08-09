(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fWorking;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls;

type

  { TfrmWorking }

  TfrmWorking = class(TForm)
    lblInfo: TLabel;
    tmrWorking: TTimer;
    procedure FormShow(Sender: TObject);
    procedure tmrWorkingTimer(Sender: TObject);
  private
    procedure Reload;
    { private declarations }
  public
    idx : Integer;
    { public declarations }
  end; 

var
  frmWorking: TfrmWorking;
implementation
{$R *.lfm}

{ TfrmWorking }
uses dData, fMain, dUtils;

procedure TfrmWorking.Reload;
begin
  lblInfo.Caption := 'Reloading data ...';
  lblInfo.Repaint;
  Repaint;
  try
    dmData.qCQRLOG.Close;
    if dmData.DebugLevel >=1 then
      Writeln(dmData.qCQRLOG.SQL.Text);
    dmData.qCQRLOG.Open;
    if idx > 0 then
      dmData.QueryLocate(dmData.qCQRLOG,'id_cqrlog_main',idx, True)
    else begin
      if dmData.Ascening then
        dmData.qCQRLOG.Last
    end
  finally
    frmMain.ReloadGrid
  end
end;

procedure TfrmWorking.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(self);
  tmrWorking.Enabled := True // I have to do this horrible workaround because sometimes window after show
                             // doesn't get focus. Why??
end;

procedure TfrmWorking.tmrWorkingTimer(Sender: TObject);
begin
  tmrWorking.Enabled := False;
  Reload;
  Close
end;

end.

