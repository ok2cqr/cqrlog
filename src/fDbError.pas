unit fDbError;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons;

type

  { TfrmDbError }

  TfrmDbError = class(TForm)
    btnVisitFAQ : TBitBtn;
    btnOpenErrFile : TButton;
    Button2 : TButton;
    Label1 : TLabel;
    procedure btnOpenErrFileClick(Sender : TObject);
    procedure btnVisitFAQClick(Sender : TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmDbError : TfrmDbError;

implementation
  {$R *.lfm}

uses dUtils, dData;

{ TfrmDbError }

procedure TfrmDbError.btnOpenErrFileClick(Sender : TObject);
begin
  dmUtils.RunOnBackgroud('xdg-open ' + dmData.DataDir + 'mysql.err')
end;

procedure TfrmDbError.btnVisitFAQClick(Sender : TObject);
begin
  dmUtils.RunOnBackgroud('xdg-open https://www.cqrlog.com/faq')
end;

end.

