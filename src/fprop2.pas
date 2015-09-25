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
    MyUrlOk,
    MyGifOk :Boolean;
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
    <img src="http://www.hamqsl.com/solarpic.php"></a>    <===============USE THIS ONE within " "s
    </center>
   }
  //MyUrl:= 'http://www.hamqsl.com/solarpic.php';
  MyUrl:= cqrini.ReadString('ExtView', 'PUrl', '');
  if dmData.DebugLevel >=1 then Writeln('MyURL: ',MyUrl);


  HTTP := THTTPSend.Create;
  frmPropagation2.MyUrlOk :=  HTTP.HTTPMethod('GET',MyUrl);
    if frmPropagation2.MyUrlOk then
     Begin
      if dmData.DebugLevel >=1 then Writeln('Found something ...');
      frmPropagation2.MyUrlOk :=true;
      try
         frmPropagation2.MyGifOk := true;
         frmPropagation2.gif.LoadFromStream(HTTP.Document);
      except
         frmPropagation2.MyGifOk :=false;
         if dmData.DebugLevel >=1 then Writeln('LoadFromStream Failed');
      end;
     end;
  if dmData.DebugLevel >=1 then Writeln('Synchronizing');
  Synchronize(@frmPropagation2.ShowLoaded);
  HTTP.Free;
  frmPropagation2.running := False;
  if dmData.DebugLevel >=1 then Writeln('Stop thread.');

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
  if not running then
   Begin
      if dmData.DebugLevel >=1 then Writeln('Crate gif. Start Thread.');
      gif:= TGIFImage.Create;
      T := TProp2Thread.Create(True);
      T.Start
   end;

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
     if MyUrlok then
      begin
         if MyGifOk then
          Begin
           try
              if dmData.DebugLevel >=1 then Writeln('Try to assign gif');
              PropImage2.Picture.Graphic:= gif;
              PropImage2.Visible:=true;
              tmrProp2.Enabled  :=True;
              lblProp2.Visible := False;
           except
              lblProp2.Font.Color := clRed;
              lblProp2.Caption:='Image loading ERROR!'#13'Check that Url response is a GIF image!';
           end;
          end
         else
          begin
           lblProp2.Font.Color := clRed;
           lblProp2.Caption:='Image loading ERROR!'#13'Check that Url response is a GIF image!';
          end;
      end
     else
     Begin
       lblProp2.Font.Color := clRed;
       lblProp2.Caption:='Url loading ERROR!'#13'Check Url!';
     end;
     if dmData.DebugLevel >=1 then Writeln('Free gif');
     gif.Free;
end;

initialization
  {$I fProp2.lrs}

end.

