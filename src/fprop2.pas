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
  public
    { public declarations }
    running : Boolean;
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
 gif: TGIFImage;
 MyUrl: String;

begin
  if frmPropagation2.running then
    exit;
  frmPropagation2.running := True;
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
  if dmData.DebugLevel>=1 then writeln('MyUrl ',MyUrl);
  with THTTPSend.Create do
  begin
    if HTTPMethod('GET',MyUrl) then
     Begin
     gif:= TGIFImage.Create;
     try
      if dmData.DebugLevel>=1 then writeln('Url found, loading');
      gif.LoadFromStream(Document);
      frmPropagation2.PropImage2.Picture.Graphic:= gif;
      frmPropagation2.PropImage2.Visible:=true;
      frmPropagation2.tmrProp2.Enabled  :=True;
      frmPropagation2.lblProp2.Visible := False;
     except
      frmPropagation2.lblProp2.Caption:='Url ERROR!';
     end;
     gif.Free;
     if dmData.DebugLevel>=1 then writeln('loading done');
    end;
    Free;
  end;

  frmPropagation2.running := False
end;

procedure TfrmPropagation2.FormShow(Sender: TObject);
begin
   running := False;
   dmUtils.LoadWindowPos(frmPropagation2);
   PropImage2.Visible:=false;
   lblProp2.Visible := True;
   tmrProp2.Enabled    := False;
   tmrProp2.Interval   := 5000;//1000 * 60 * 60; //every 60 minutes do refresh
   tmrProp2.Enabled    := True;
   tmrProp2Timer(nil)
end;

procedure TfrmPropagation2.tmrProp2Timer(Sender: TObject);

var
  T : TProp2Thread;
begin
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



initialization
  {$I fProp2.lrs}

end.

