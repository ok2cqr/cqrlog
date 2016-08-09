unit fQSLViewer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ComCtrls, ExtCtrls, StdCtrls;

type

  { TfrmQSLViewer }

  TfrmQSLViewer = class(TForm)
    btnCancel: TButton;
    imgBack: TImage;
    imgFront: TImage;
    pgQSL: TPageControl;
    Panel1: TPanel;
    tabFront: TTabSheet;
    tabBack: TTabSheet;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure pgQSLPageChanged(Sender: TObject);
  private
    fCall : String;
  public
    property Call : String write fCall;
    { public declarations }
  end; 

var
  frmQSLViewer: TfrmQSLViewer;

implementation
{$R *.lfm}

uses dData, dUtils;


{ TfrmQSLViewer }

procedure TfrmQSLViewer.FormShow(Sender: TObject);
var
  a : String;
begin
  dmUtils.LoadWindowPos(frmQSLViewer);
  fCall := LowerCase(StringReplace(fCall,'/','_',[rfReplaceAll, rfIgnoreCase]));
  a := dmUtils.QSLFrontImageExists(fCall);
  if a <> '' then
    imgFront.Picture.LoadFromFile(a)
  else
    exit;
  Height := imgFront.Picture.Height+Panel1.Height+35;
  Width  := imgFront.Picture.Width;

  a := dmUtils.QSLBackImageExists(fCall);
  if a <> '' then
    imgBack.Picture.LoadFromFile(a)
end;

procedure TfrmQSLViewer.pgQSLPageChanged(Sender: TObject);
begin
  if pgQSL.ActivePageIndex = 0 then
  begin
    Height := imgFront.Picture.Height+Panel1.Height+35;
    Width  := imgFront.Picture.Width
  end
  else begin
    if dmUtils.QSLBackImageExists(fCall) <> '' then
    begin
      Height := imgBack.Picture.Height+Panel1.Height+35;
      Width  := imgBack.Picture.Width
    end
  end
end;

procedure TfrmQSLViewer.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  dmUtils.SaveWindowPos(frmQSLViewer)
end;

end.

