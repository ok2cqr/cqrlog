unit fFindCommentToCall;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls;

type

  { TfrmFindCommentToCall }

  TfrmFindCommentToCall = class(TForm)
    btnSearch : TButton;
    btnCancel : TButton;
    edtCallsign : TEdit;
    Label1 : TLabel;
    procedure edtCallsignKeyPress(Sender : TObject; var Key : char);
    procedure FormShow(Sender : TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmFindCommentToCall : TfrmFindCommentToCall;

implementation
{$R *.lfm}

uses dUtils;

{ TfrmFindCommentToCall }

procedure TfrmFindCommentToCall.edtCallsignKeyPress(Sender : TObject;
  var Key : char);
begin
  if key = #13 then
  begin
    key := #0;
    btnSearch.Click
  end
end;

procedure TfrmFindCommentToCall.FormShow(Sender : TObject);
begin
  dmUtils.LoadFontSettings(frmFindCommentToCall)
end;

end.

