unit fLongNote;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, IniFiles;

type

  { TfrmLongNote }

  TfrmLongNote = class(TForm)
    btnCancel: TButton;
    btnSave: TButton;
    mNote: TMemo;
    Panel1: TPanel;
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmLongNote: TfrmLongNote; 

implementation
{$R *.lfm}

{ TfrmLongNote }
uses dData, dUtils, uMyIni;

procedure TfrmLongNote.FormCreate(Sender: TObject);
begin
  Height := cqrini.ReadInteger('LongNote','Height',ClientHeight);
  Width  := cqrini.ReadInteger('LongNote','Width',ClientWidth);
  Top    := cqrini.ReadInteger('LongNote','Top',10);
  Left   := cqrini.ReadInteger('LongNote','Left',10);
  dmUtils.LoadFontSettings(self)
end;

procedure TfrmLongNote.FormShow(Sender: TObject);
begin
  mNote.SetFocus
end;

procedure TfrmLongNote.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  cqrini.WriteInteger('LongNote','Height',ClientHeight);
  cqrini.WriteInteger('LongNote','Width',ClientWidth);
  cqrini.WriteInteger('LongNote','Top',Top);
  cqrini.WriteInteger('LongNote','Left',Left)
end;

end.

