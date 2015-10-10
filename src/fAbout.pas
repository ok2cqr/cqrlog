unit fAbout;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, lclintf;

type

  { TfrmAbout }

  TfrmAbout = class(TForm)
    Bevel1: TBevel;
    btnChangelog: TButton;
    btnClose: TButton;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    lblLink: TLabel;
    lblVerze: TLabel;
    procedure btnChangelogClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lblLinkClick(Sender: TObject);
    procedure lblLinkMouseEnter(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmAbout: TfrmAbout;

implementation

{$R *.lfm}

{ TfrmAbout }
uses fChangelog, uVersion,vinfo,versiontypes;

procedure TfrmAbout.lblLinkMouseEnter(Sender: TObject);
begin
  lblLink.Cursor := crHandPoint
end;

procedure TfrmAbout.lblLinkClick(Sender: TObject);
begin
  openURl(lblLink.Caption)
end;

procedure TfrmAbout.btnChangelogClick(Sender: TObject);
begin
  with TfrmChangelog.Create(Application) do
  try
    ShowModal
  finally
    Free
  end
end;

procedure TfrmAbout.FormShow(Sender: TObject);
function ProductVersionToString(PV: TFileProductVersion): String;
   begin
     Result := Format('%d.%d.%d.%d', [PV[0],PV[1],PV[2],PV[3]])
   end;
var
  Info: TVersionInfo;
begin
  Info := TVersionInfo.Create;
  Info.Load(HINSTANCE);
  //lblVerze.Caption:= cVERSION
  //ProductVersionToString(Info.FixedInfo.ProductVersion)
   lblVerze.Caption:=ProductVersionToString(Info.FixedInfo.FileVersion);
  Info.Free;
end;

end.

