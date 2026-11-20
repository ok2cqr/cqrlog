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
    lblServer : TLabel;
    procedure btnOpenErrFileClick(Sender : TObject);
    procedure btnVisitFAQClick(Sender : TObject);
    procedure FormShow(Sender : TObject);
  private
    { private declarations }
  public
    //the binary CQRLOG ran, a bare name when none was found and it went to $PATH
    ServerPath    : String;
    //exception message when the binary could not be run at all
    StartError    : String;
    //the server wrote to mysql.err after it was started
    ErrLogWritten : Boolean;
  end;

var
  frmDbError : TfrmDbError;

implementation
  {$R *.lfm}

uses dUtils, dData;

{ TfrmDbError }

procedure TfrmDbError.btnOpenErrFileClick(Sender : TObject);
begin
  dmUtils.OpenWithDesktop(AnsiQuotedStr(dmData.DataDir + 'mysql.err', '"'))
end;

//Without this the user does not know which binary was run. When it did not run
//or ended before writing anything, mysql.err is missing or only holds an older
//start, and the dialog would send them to a file that does not explain it.
procedure TfrmDbError.FormShow(Sender : TObject);
var
  s : String;
begin
  if Pos(PathDelim, ServerPath) = 0 then
    s := 'No MariaDB/MySQL server was found in the usual places, CQRLOG tried "' +
         ServerPath + '" from PATH.'
  else
    s := 'Database server: ' + ServerPath;

  if StartError <> '' then
    s := s + LineEnding + 'It could not be run: ' + StartError
  else if not ErrLogWritten then
    s := s + LineEnding + 'It wrote nothing to mysql.err, so it probably ended right ' +
         'after the start, e.g. because of missing permissions (AppArmor, SELinux).';

  lblServer.Caption := s;
  //the label wraps and grows, the buttons follow it through their anchors
  ClientHeight := Button2.Top + Button2.Height + Button2.BorderSpacing.Bottom;
  btnOpenErrFile.Enabled := FileExists(dmData.DataDir + 'mysql.err')
end;

procedure TfrmDbError.btnVisitFAQClick(Sender : TObject);
begin
  dmUtils.OpenWithDesktop('https://cqrlog.ok2cqr.com/#faq')
end;

end.

