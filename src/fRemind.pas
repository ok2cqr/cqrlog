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
    chUTRemi: TCheckBox;
    chRemi: TCheckBox;
    lblRemi1: TLabel;
    lblRemi3: TLabel;
    lblRemi2: TLabel;
    RemindUThour: TMaskEdit;
    RemindTimeSet: TMaskEdit;
    RemiMemo: TMemo;
    tmrRemi: TTimer;
    procedure FormShow(Sender: TObject);
    procedure RemiMemoLimit(Sender: TObject; var Key: Char);
    procedure btCloseClick(Sender: TObject);
    procedure chRemiChange(Sender: TObject);
    procedure chUTRemiChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure RemindTimeSetEnter(Sender: TObject);
    procedure RemindTimeSetExit(Sender: TObject);
    procedure RemindUThourChange(Sender: TObject);
    procedure tmrRemiTimer(Sender: TObject);
  private
    procedure ShowReminder;
    { private declarations }
  public
    procedure OpenReminder;
    { public declarations }
  end;

var
  frmReminder: TfrmReminder;
  date : TDateTime;
  TimerValue: string;

implementation
{$R *.lfm}

{ TfrmReminder }

uses dData,dUtils,uMyini;

Procedure TfrmReminder.OpenReminder;

Begin //when not entering from timer
  tmrRemi.Enabled :=false;
  frmReminder.ShowOnTop;
  RemiMemo.SetFocus;
end;

procedure TfrmReminder.RemiMemoLimit(Sender: TObject; var Key: Char);
var
  MAX_LINES              : Integer;
  LINE_LENGTH            : Integer;
begin
  MAX_LINES         := 1;
  LINE_LENGTH       := 255;
  if (RemiMemo.Lines.Count = MAX_LINES) then
    if(Key = #13) or (length(RemiMemo.Lines[MAX_LINES-1]) >= LINE_LENGTH ) then
      begin
        if not((Key = #08) or (Key = #127)) then Key := #0;        //del & BS ok
        Exit;
      end;
  if (RemiMemo.Lines.Count > MAX_LINES) and (Key = #13) then  //no new lines
    begin
      Key := #0;
      Exit;
    end;
end;

procedure TfrmReminder.FormShow(Sender: TObject);
begin
  //dmUtils.LoadWindowPos(frmReminder);    // this breaks big fonts and positions used in this form !!!!
end;


Procedure TfrmReminder.ShowReminder;

var s,i:string;

Begin

   if  chRemi.Checked then
    begin
     TimerValue := IntToStr(tmrRemi.Interval div 60000);
     if dmData.DebugLevel >=1 then writeln('Reminder TimerValue:', tmrRemi.Interval );
     while length(Timervalue)< 3 do TimerValue := '0'+TimerValue;
     RemindTimeSet.EditText:= TimerValue;
     tmrRemi.Enabled := False;
     frmReminder.ShowOnTop;
     RemiMemo.SetFocus;
    end;

    if chUTRemi.checked then
     Begin
       date := dmUtils.GetDateTime(0);
       i:= FormatDateTime('hh:mm',date);
       s:= RemindUThour.EditText;
       if dmData.DebugLevel >=1 then writeln('UT reminder *',s,'* is nw *',i,'*');
       if i = s  then
        Begin
         tmrRemi.Enabled := False;
         frmReminder.ShowOnTop;
         RemiMemo.SetFocus;
        end;
     end;

end;

procedure TfrmReminder.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
   frmReminder.btCloseClick(nil);
end;

procedure TfrmReminder.RemindTimeSetEnter(Sender: TObject);
begin
    RemindTimeSet.SelectAll;
end;

procedure TfrmReminder.RemindTimeSetExit(Sender: TObject);
begin
  if ((RemindTimeSet.EditText = '000') and chRemi.Checked) then
                          RemindTimeSet.EditText := '001';
end;

procedure TfrmReminder.RemindUThourChange(Sender: TObject);
    var s : string;

begin
  s := RemindUThour.EditText;
  case s[1] of                      //hour tens just 0,1,2
    '3' .. '9' : s[1] := '0';
  end;

  if s[1] = '2' then               // hours just up to 23
   case s[2] of
      '4' .. '9' : s[2] := '0';
    end;

  case s[4] of                      //minute tens just 0,1,2,4,5
    '6' .. '9' : s[4] := '0';
  end;

  RemindUThour.EditText := s;

end;

procedure TfrmReminder.btCloseClick(Sender: TObject);
var
   TimerSetting : integer;

begin
  if chRemi.Checked = true then
     Begin
       if TryStrToINt(RemindTimeSet.EditText,TimerSetting) then
        TimerSetting := TimerSetting * 60000 //to milliseconds
       else
        begin
           RemindTimeSet.EditText :='001';
           TimerSetting := 60000; // on error defaults to minute
        end;
       tmrRemi.Interval:= TimerSetting;
       tmrRemi.Enabled := True;
       if dmData.DebugLevel >=1 then Writeln('Remind timer set to :',tmrRemi.Interval,'ms');
     end;

  if chUTRemi.Checked = true then
     Begin
       TimerSetting := 10000; // 10sec  for UT check
       tmrRemi.Interval:= TimerSetting;
       tmrRemi.Enabled := True;
       if dmData.DebugLevel >=1 then Writeln('UT Remind check timer set to :',tmrRemi.Interval,'ms');
     end;

   if (not  chUTRemi.Checked) and (not chRemi.Checked ) then tmrRemi.Enabled := False;

   cqrini.WriteBool('Reminder','chRemi',chRemi.Checked);
   cqrini.WriteBool('Reminder','chUTRemi',chUTRemi.Checked);
   cqrini.WriteString('Reminder','RemindTimeSet',RemindTimeSet.EditText);
   cqrini.WriteString('Reminder','RemindUThour',RemindUThour.EditText);
   cqrini.WriteString('Reminder','RemiMemo',RemiMemo.Lines[0]);
   //dmUtils.SaveWindowPos(frmReminder);

  frmReminder.hide;
end;

procedure TfrmReminder.chRemiChange(Sender: TObject);
begin
  if  chRemi.Checked = true then   chUTRemi.Checked := false;
end;

procedure TfrmReminder.chUTRemiChange(Sender: TObject);
begin
  if  chUTRemi.Checked = true then   chRemi.Checked := false;
end;

procedure TfrmReminder.tmrRemiTimer(Sender: TObject);
begin
  ShowReminder;
end;

initialization

end.

