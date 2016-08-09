(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fUpgrade;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls, lcltype;

type

  { TfrmUpgrade }

  TfrmUpgrade = class(TForm)
    Label1: TLabel;
    pBar: TProgressBar;
    tmrUpgrade: TTimer;
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrUpgradeTimer(Sender: TObject);
  private
    fOldMajor : Integer;
    fOldMinor : Integer;
    fOldRelea : Integer;
    { private declarations }
  public
    property OldMajor : Integer read fOldMajor write fOldMajor;
    property OldMinor : Integer read fOldMinor write fOldMinor;
    property OldRelea : Integer read fOldRelea write fOldRelea;
    { public declarations }
  end; 


var
  frmUpgrade: TfrmUpgrade;
  run : Boolean = False;


implementation
{$R *.lfm}

{ TfrmUpgrade }
uses dUtils,dData, dDXCC;


procedure TfrmUpgrade.FormActivate(Sender: TObject);
begin
  tmrUpgrade.Enabled := False;
  if run then
    exit;
  run := True;
  Close
end;

procedure TfrmUpgrade.FormCreate(Sender: TObject);
begin
  tmrUpgrade.Enabled := True;
end;

procedure TfrmUpgrade.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(self);
end;

procedure TfrmUpgrade.tmrUpgradeTimer(Sender: TObject);
begin
  FormActivate(nil);
  tmrUpgrade.Enabled := False;
end;

end.

