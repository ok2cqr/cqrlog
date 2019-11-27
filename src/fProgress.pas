unit fProgress;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, Types;

type

  { TfrmProgress }

  TfrmProgress = class(TForm)
    lblInfo: TLabel;
    p: TProgressBar;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private

  public
   procedure DoStep(info:string = '');
   procedure DoInit(max,step:integer);
  end;

var
  frmProgress: TfrmProgress;
  i:integer;

implementation
{$R *.lfm}
{ TfrmProgress }

procedure TfrmProgress.FormShow(Sender: TObject);
begin
  frmProgress.ShowOnTop;
end;

procedure TfrmProgress.FormCreate(Sender: TObject);
begin
  frmProgress.Hide;
end;

procedure TfrmProgress.DoStep(info:string = '');
begin
  lblInfo.Caption:=info;
  p.StepIt;
  repaint;
  Application.ProcessMessages;
end;
procedure TfrmProgress.DoInit(max,step:integer);
begin
  p.position:=0;
  p.max:=max;
  p.step:=step;
end;
end.

