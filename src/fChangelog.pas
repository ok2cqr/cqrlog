unit fChangelog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, LazHelpHTML, IpHtml, Ipfilebroker;

type

  { TfrmChangelog }

  TfrmChangelog = class(TForm)
    Button1: TButton;
    IpFileDataProvider1: TIpFileDataProvider;
    IpHtmlPanel1: TIpHtmlPanel;
    Panel1: TPanel;
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmChangelog: TfrmChangelog;

implementation

{$R *.lfm}

{ TfrmChangelog }
uses dData;

procedure TfrmChangelog.FormShow(Sender: TObject);
var
  tmp : String;
begin
  tmp := expandLocalHtmlFileName(dmData.ShareDir+'changelog.html');
  IpHtmlPanel1.OpenURL(tmp)
end;

end.

