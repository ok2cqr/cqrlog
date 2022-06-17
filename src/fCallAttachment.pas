unit fCallAttachment;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  FileCtrl, ExtCtrls, StdCtrls, lclintf;

type

  { TfrmCallAttachment }

  TfrmCallAttachment = class(TForm)
    btnClose1: TButton;
    btnView: TButton;
    flAttach: TFileListBox;
    Panel1: TPanel;
    procedure btnViewClick(Sender: TObject);
    procedure flAttachDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmCallAttachment: TfrmCallAttachment;

implementation
{$R *.lfm}

uses dUtils,dData, uMyini;

{ TfrmCallAttachment }

procedure TfrmCallAttachment.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmCallAttachment);
  flAttach.Mask := '*.pdf;*.jpg;*.png;*.gif;*.txt;*.html'
end;

procedure TfrmCallAttachment.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmCallAttachment)
end;

procedure TfrmCallAttachment.btnViewClick(Sender: TObject);
var
  CurrentDir : String = '';
begin
  if flAttach.FileName = '' then exit;

  CurrentDir := GetCurrentDir;
  try
    SetCurrentDir(flAttach.Directory);
    dmUtils.RunOnBackground('/usr/bin/xdg-open' + ' ' + AnsiQuotedStr(flAttach.FileName, '"'));
  finally
    SetCurrentDir(CurrentDir)
  end;
end;

procedure TfrmCallAttachment.flAttachDblClick(Sender: TObject);
begin
  btnView.Click
end;

end.

