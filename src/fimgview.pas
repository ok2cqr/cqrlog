unit fImgView;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls,blcksock,synautil,synsock,httpsend;

type

  { TfrmImgView }

  TfrmImgView = class(TForm)
    lblImgView1: TLabel;
    ImgImage: TImage;
    tmrImgView1: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure tmrImgView1Timer(Sender: TObject);
  private
    { private declarations }
    procedure ShowLoaded;
  public
    { public declarations }
    running : Boolean;
    MyUrlOk,
    MyImgOk :Boolean;
  end;

  type
    TImgViewThread = class(TThread)
    protected
      procedure Execute; override;
  end;

var
  frmImgView: TfrmImgView;


implementation

{ TfrmImgView }
uses  dData, dUtils, uMyIni;

procedure TImgViewThread.Execute;
var
 MyUrl: String;
 HTTP : THTTPSend;
 response :TMemoryStream;

begin
  if frmImgView.running then
                                 exit;
  frmImgView.running := True;
  FreeOnTerminate := True;
  { Show propagation image from http://www.hamqsl.com/solar.html  (or image from any other page or webcam)
    Select desired image from webpage.
    Use address given after "img src"-text of link for MyUrl variable.

    Example given link is:
    <center>
    <a href="http://www.hamqsl.com/solar.html"
    title="Click to add Solar-Terrestrial Data to your website!">
    <img src="http://www.hamqsl.com/solarpic.php"></a>            <=============== USE THIS LINE TEXT within " "s
    </center>
   }
  MyUrl:= cqrini.ReadString('ExtView', 'ImgViewUrl', '');
  if dmData.DebugLevel >=1 then Writeln('MyURL: ',MyUrl);


  HTTP := THTTPSend.Create;
  frmImgView.MyUrlOk :=  HTTP.HTTPMethod('GET',MyUrl);
    if frmImgView.MyUrlOk then
     Begin
       if dmData.DebugLevel >=1 then Writeln('Found Url ...');
       frmImgView.MyUrlOk :=true;

       response := TMemoryStream.Create;
       try
       if HttpGetBinary(MyUrl, response) then
       begin
         frmImgView.MyImgOk := true;
         response.Seek( 0, soFromBeginning );
         frmImgView.ImgImage.Picture.LoadFromStream( response );
       end;
       except
             frmImgView.MyImgOk :=false;
             if dmData.DebugLevel >=1 then Writeln('Image LoadFromStream Failed');
       end;

      if dmData.DebugLevel >=1 then Writeln('Synchronizing');
      Synchronize(@frmImgView.ShowLoaded);
      response.Free;
      frmImgView.running := False;
      if dmData.DebugLevel >=1 then Writeln('Stop thread.');
     end;
end;

procedure TfrmImgView.FormShow(Sender: TObject);
begin
   running := False;
   dmUtils.LoadWindowPos(frmImgView);
   frmImgView.Width:= 120;
   frmImgView.Height := 50;
   with ImgImage.Picture.Bitmap do SetSize(1,1);
   ImgImage.Visible:=false;
   lblImgView1.Visible := True;
   tmrImgView1.Enabled    := False;
   tmrImgView1.Interval   := 1000 * 60 * cqrini.ReadInteger('ExtView', 'ImgViewUrltime',60);
   tmrImgView1.Enabled    := True;
   tmrImgView1Timer(nil)
end;


procedure TfrmImgView.tmrImgView1Timer(Sender: TObject);

var
   T : TImgViewThread;
begin
    with ImgImage.Picture.Bitmap do  SetSize(1,1);

    ImgImage.Visible:=false;
    ImgImage.Center := True;
    ImgImage.AutoSize := True;
    frmImgView.Width:= 120;
    frmImgView.Height := 50;

    lblImgView1.Visible := True;
    lblImgView1.Font.Color := clDefault;
    lblImgView1.Left := 32;
    lblImgView1.Top :=16;
    lblImgView1.Caption:='Loading...';

  if not running then
   Begin
      if dmData.DebugLevel >=1 then
       begin
         Writeln('Start Thread. Timer interval is:',tmrImgView1.Interval );
         Writeln('Image: ',ImgImage.Width,'x',ImgImage.Height,' ',ImgImage.AutoSize,
                 ' Form: ',frmImgView.Width,'x',frmImgView.Height);
       end;
      T := TImgViewThread.Create(True);
      T.Start
   end;

end;

procedure TfrmImgView.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
   tmrImgView1.Enabled  :=false;
   dmUtils.SaveWindowPos(frmImgView);
end;

procedure TfrmImgView.ShowLoaded;

begin
     if MyUrlok then
      begin
         if MyImgOk then
          Begin
              ImgImage.Visible:=true;
              tmrImgView1.Enabled  :=True;
              lblImgView1.Visible := False;
          end
         else
          begin
           lblImgView1.Font.Color := clRed;
           lblImgView1.Caption:='Image loading ERROR!'#13'Check that Url response is an image!';
          end;
      end
     else
      Begin
       lblImgView1.Font.Color := clRed;
       lblImgView1.Caption:='Url loading ERROR!'#13'Check Url!';
      end;

     if dmData.DebugLevel >=1 then
       begin
         Writeln('ShowLoaded before setting Image: ',ImgImage.Width,'x',ImgImage.Height,' ',ImgImage.AutoSize,
                 ' Form: ',frmImgView.Width,'x',frmImgView.Height);
       end;
      //autoresize on form just does not work as expected so:
      frmImgView.Width := ImgImage.Width;
      frmImgView.Height := ImgImage.Height;
      if dmData.DebugLevel >=1 then
       begin
         Writeln('ShowLoaded after setting Image: ',ImgImage.Width,'x',ImgImage.Height,' ',ImgImage.AutoSize,
                 ' Form: ',frmImgView.Width,'x',frmImgView.Height);
       end;
end;

initialization
  {$I fimgview.lrs}

end.

