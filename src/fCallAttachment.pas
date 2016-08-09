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
  ext : String = '';
  prg : String = '';
  dir : String = '';
begin
  if flAttach.FileName = '' then exit;
  dir := GetCurrentDir;
  try
    SetCurrentDir(flAttach.Directory);
    ext := LowerCase(ExtractFileExt(flAttach.FileName));
    if ext = '.pdf' then
      prg := cqrini.ReadString('ExtView','pdf','evince')
    else if ext = '.txt' then
      prg := cqrini.ReadString('ExtView','txt','gedit')
    else if ((ext = '.html') or (ext = '.htm')) then
      prg := cqrini.ReadString('ExtView','html','firefox')
    else
      prg := cqrini.ReadString('ExtView','img','eog');
    if prg = '' then
      dmUtils.RunOnBackgroud(cqrini.ReadString('Program', 'WebBrowser', 'firefox') +
                             ' ' + flAttach.FileName)
    else
      dmUtils.RunOnBackgroud(prg + ' ' + flAttach.FileName)
  finally
    SetCurrentDir(dir)
  end
end;

procedure TfrmCallAttachment.flAttachDblClick(Sender: TObject);
begin
  btnView.Click
end;

end.

