(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fShowStations;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls;

type

  { TfrmShowStations }

  TfrmShowStations = class(TForm)
    btnClose: TButton;
    btnSave: TButton;
    m: TMemo;
    Panel1: TPanel;
    dlgSave: TSaveDialog;
    procedure btnSaveClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmShowStations: TfrmShowStations;

implementation
{$R *.lfm}

{ TfrmShowStations }

procedure TfrmShowStations.btnSaveClick(Sender: TObject);
begin
  if dlgSave.Execute then
    m.Lines.SaveToFile(dlgSave.FileName);
end;

end.

