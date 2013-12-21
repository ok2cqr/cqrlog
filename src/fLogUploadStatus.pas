unit fLogUploadStatus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  Menus, ActnList, ExtCtrls, jakozememo;

type

  { TfrmLogUploadStatus }

  TfrmLogUploadStatus = class(TForm)
    acLogUploadStatus: TActionList;
    acClearMessages: TAction;
    acFontSettings: TAction;
    dlgFont: TFontDialog;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    mnuStatus: TMenuItem;
    pnlLogStatus: TPanel;
    procedure acClearMessagesExecute(Sender: TObject);
    procedure acFontSettingsExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    mStatus : TJakoMemo;
    procedure LoadFonts;
  public
    { public declarations }
  end; 

var
  frmLogUploadStatus: TfrmLogUploadStatus;

implementation

uses dData, dUtils, dLogUpload, uMyIni;

procedure TfrmLogUploadStatus.acClearMessagesExecute(Sender: TObject);
begin
  mStatus.smaz_vse
end;

procedure TfrmLogUploadStatus.acFontSettingsExecute(Sender: TObject);
begin
  dlgFont.Font.Name := cqrini.ReadString('LogUploadStatus','FontName','Monospace');
  dlgFont.Font.Size := cqrini.ReadInteger('LogUploadStatus','FontSize',8);
  if dlgFont.Execute then
  begin
    cqrini.WriteString('LogUploadStatus','FontName',dlgFont.Font.Name);
    cqrini.WriteInteger('LogUploadStatus','FontSize',dlgFont.Font.Size)
  end
end;

procedure TfrmLogUploadStatus.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmLogUploadStatus);
end;

procedure TfrmLogUploadStatus.FormCloseQuery(Sender: TObject;
  var CanClose: boolean);
begin
  FreeAndNil(mStatus)
end;

procedure TfrmLogUploadStatus.FormCreate(Sender: TObject);
begin
  mStatus            := Tjakomemo.Create(pnlLogStatus);
  mStatus.parent     := pnlLogStatus;
  mStatus.autoscroll := True;
  mStatus.Align      := alClient
end;

procedure TfrmLogUploadStatus.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmLogUploadStatus);
  LoadFonts
end;

procedure TfrmLogUploadStatus.LoadFonts;
var
  f : TFont;
begin
  dmUtils.LoadFontSettings(self);
  f := TFont.Create;
  try
    f.Name := cqrini.ReadString('LogUploadStatus','FontName','Monospace');
    f.Size := cqrini.ReadInteger('LogUploadStatus','FontSize',8);
    mStatus.nastav_font(f)
  finally
    f.Free
  end
end;


initialization
  {$I fLogUploadStatus.lrs}

end.

