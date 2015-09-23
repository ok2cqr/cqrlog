unit fProp2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls,blcksock,synautil,synsock,httpsend;

type

  { TfrmPropagation2 }

  TfrmPropagation2 = class(TForm)
    lblProp2: TLabel;
    PropImage2: TImage;
    tmrProp2: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrProp2Timer(Sender: TObject);
  private
    { private declarations }
    procedure ShowLoaded;
  public
    { public declarations }
    running : Boolean;
    MyStream       :TmemoryStream;
    MyOk           :Boolean;
    gif: TGIFImage;
  end;

  type
    TProp2Thread = class(TThread)
    protected
      procedure Execute; override;
  end;

var
  frmPropagation2: TfrmPropagation2;


implementation

{ TfrmPropagation2 }
uses  dData, dUtils, uMyIni;

procedure TProp2Thread.Execute;
var
 MyUrl: String;
 HTTP : THTTPSend;

begin
  if frmPropagation2.running then
    exit;
  frmPropagation2.running := True;
  FreeOnTerminate := True;
  { Show propagation image from http://www.hamqsl.com/solar.html
    Select desired image from webpage.
    Use address given after "img src"-text of link for MyUrl variable.

    Example given link is:
    <center>
    <a href="http://www.hamqsl.com/solar.html"
    title="Click to add Solar-Terrestrial Data to your website!">
    <img src="http://www.hamqsl.com/solarpic.php"></a>    <===============THIS ONE within " "s
    </center>
   }
  //MyUrl:= 'http://www.hamqsl.com/solarpic.php';
  MyUrl:= cqrini.ReadString('ExtView', 'PUrl', '');
  frmPropagation2.MyOk := false;
  HTTP := THTTPSend.Create;
    if HTTP.HTTPMethod('GET',MyUrl) then
     Begin
      frmPropagation2.MyOk :=true;
      frmPropagation2.MyStream := HTTP.Document;
     end;
  Synchronize(@frmPropagation2.ShowLoaded);
  HTTP.Free;
  frmPropagation2.running := False
end;

procedure TfrmPropagation2.FormShow(Sender: TObject);
begin
   running := False;
   dmUtils.LoadWindowPos(frmPropagation2);
   PropImage2.Visible:=false;
   lblProp2.Visible := True;
   tmrProp2.Enabled    := False;
   tmrProp2.Interval   := 1000 * 60 * 60; //every 60 minutes do refresh
   tmrProp2.Enabled    := True;
   tmrProp2Timer(nil)
end;

procedure TfrmPropagation2.tmrProp2Timer(Sender: TObject);

var
  T : TProp2Thread;
begin
  lblProp2.Caption:='Loading...';
  PropImage2.Visible:=false;
  lblProp2.Visible := True;
  lblProp2.Font.Color := clDefault;
  T := TProp2Thread.Create(True);
  T.Start
end;

procedure TfrmPropagation2.FormHide(Sender: TObject);
begin
   PropImage2.Visible  :=false;
   tmrProp2.Enabled  :=false;
   frmPropagation2.Hide;
end;

procedure TfrmPropagation2.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
   PropImage2.Visible  :=false;
   tmrProp2.Enabled  :=false;
   dmUtils.SaveWindowPos(frmPropagation2);
   frmPropagation2.Hide;
end;
procedure TfrmPropagation2.ShowLoaded;

begin
     if Myok then
      begin
           gif:= TGIFImage.Create;
           try
              gif.LoadFromStream(MyStream);
              PropImage2.Picture.Graphic:= gif;
              PropImage2.Visible:=true;
              tmrProp2.Enabled  :=True;
              lblProp2.Visible := False;
           except
           lblProp2.Font.Color := clRed;
           lblProp2.Caption:='Image loading ERROR!'#13'Check that Url response is a GIF image!';
           end;
           gif.Free;
      end
     else
     Begin
       lblProp2.Font.Color := clRed;
       lblProp2.Caption:='Url loading ERROR!'#13'Check Url!';
     end;
end;

initialization
  {$I fProp2.lrs}

end.

