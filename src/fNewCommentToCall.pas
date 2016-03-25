unit fNewCommentToCall;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, LCLType;

type

  { TfrmNewCommentToCall }

  TfrmNewCommentToCall = class(TForm)
    btnOK : TButton;
    btnCancel : TButton;
    edtCallsign : TEdit;
    Label1 : TLabel;
    Label2 : TLabel;
    mNote : TMemo;
    procedure btnOKClick(Sender : TObject);
    procedure FormShow(Sender : TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmNewCommentToCall : TfrmNewCommentToCall;

implementation

uses dData, dUtils;

{ TfrmNewCommentToCall }

procedure TfrmNewCommentToCall.btnOKClick(Sender : TObject);
begin
  if (edtCallsign.Text = '') then
  begin
    Application.MessageBox('Please enter a callsign','Error',mb_OK+mb_IconError);
    edtCallsign.SetFocus;
    exit
  end;

  if edtCallsign.Enabled then
  begin
    if dmData.CallNoteExists(edtCallsign.Text) then
    begin
      Application.MessageBox('Note to this callsign already exists','Error',mb_OK+mb_IconError);
      edtCallsign.SetFocus;
      exit
    end
  end;

  if (mNote.Lines.Text = '') then
  begin
    Application.MessageBox('Please enter a note','Error',mb_OK+mb_IconError);
    mNote.SetFocus;
    exit
  end;

  ModalResult := mrOK
end;

procedure TfrmNewCommentToCall.FormShow(Sender : TObject);
begin
  dmUtils.LoadFontSettings(frmNewCommentToCall)
end;

initialization
  {$I fNewCommentToCall.lrs}

end.

