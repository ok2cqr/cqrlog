unit fRemind;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, maskedit;

type

  { TfrmReminder }

  TfrmReminder = class(TForm)
    btClose: TButton;
    chRemi: TCheckBox;
    lblRemi3: TLabel;
    lblRemi2: TLabel;
    lblRemi1: TLabel;
    RemindTImeSet: TMaskEdit;
    RemiMemo: TMemo;
    tmrRemi: TTimer;
    procedure btCloseClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure tmrRemiTimer(Sender: TObject);
  private
    { private declarations }
  public
    procedure ShowReminder;
    { public declarations }
  end;

var
  frmReminder: TfrmReminder;

implementation

{ TfrmReminder }
Procedure TfrmReminder.ShowReminder;
var TimeValue :string;

Begin
   tmrRemi.Enabled := False;
   TimeValue := IntToStr(tmrRemi.Interval div 60000);
   while length(Timevalue)< 3 do TimeValue := '0'+TimeValue;
   RemindTimeSet.EditText:= TimeValue;
   frmReminder.ShowOnTop;
   RemiMemo.SetFocus;
end;

procedure TfrmReminder.FormCreate(Sender: TObject);
begin
  tmrRemi.Enabled :=true;
end;

procedure TfrmReminder.btCloseClick(Sender: TObject);
var
   TimerSetting : integer;

begin
  if chRemi.Checked = False then
     Begin
       if TryStrToINt(RemindTimeSet.EditText,TimerSetting) then
          Begin
            TimerSetting := TimerSetting * 60000; //to milliseconds
            if TimerSetting > 0 then
               Begin
                 tmrRemi.Interval:= TimerSetting;
                 tmrRemi.Enabled := True;
               end;
          end;
     end
    else
     tmrRemi.Enabled := False;
  frmReminder.hide;
end;

procedure TfrmReminder.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
   frmReminder.btCloseClick(nil);
end;

procedure TfrmReminder.tmrRemiTimer(Sender: TObject);
begin
  ShowReminder;
end;

initialization
 {$I fremind.lrs}

end.

