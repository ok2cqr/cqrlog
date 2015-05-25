unit fPropagation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls,ComCtrls,Buttons, httpsend, LCLType, ftpsend,
  lazutf8sysutils, lclintf;

type

  { TfrmPropagation }

  TfrmPropagation = class(TForm)
    ImageKidx: TImage;
    lblInfoDate: TLabel;
    lblBoulAidx: TLabel;
    lblKidxG: TLabel;
    lblInfoFrom: TLabel;
    lblInfoUTC: TLabel;
    DKiel3K: TLabel;
    lblCurKidx: TLabel;
    lblSolarFlx: TLabel;
    lblSunSNr: TLabel;
    lblGeomFi: TLabel;
    lblSolAct: TLabel;
    lblKielAidx: TLabel;
    lblAurora: TLabel;
    lblKiel3K: TLabel;
    DKielAidx: TLabel;
    DAurora: TLabel;
    lblInfo: TLabel;
    DGeomFi: TLabel;
    DSunSNr: TLabel;
    DSolarFlx: TLabel;
    DSolAct: TLabel;
    DCurKidx: TLabel;
    DBoulAidx: TLabel;
    Panel1: TPanel;
    sbtnRefresh : TSpeedButton;
    tmrProp: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDblClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure lblBoulAidxClick(Sender: TObject);
    procedure lblInfoFromMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure lblInfoFromMouseEnter(Sender: TObject);
    procedure lblInfoFromMouseLeave(Sender: TObject);
    procedure sbtnRefreshClick(Sender : TObject);
    procedure tmrPropTimer(Sender: TObject);

  private
    { private declarations }
  public
    ak   : String;
    ab   : String;
    k    : String;
    k3h  : String;
    sfi  : String;
    ssn  : String;
    sa   : String;
    gf   : String;
    au   : String;
    time : String;
    date : String;
    UTC  : String;
    HttpFrm: String;
    running : Boolean;

    dbc : integer; // debug colors

    procedure SyncProp;
    procedure KidxGraph;
    function getKindexColor(kIndex : integer) : TColor;
  end; 

  type
    KData = array [0..35] of integer;   //stores 3h K-idx data
    TPropThread = class(TThread)
    protected
      procedure Execute; override;
  end;


var
  frmPropagation  : TfrmPropagation;
  KValues         : KData;
  BkColor         : TColor = clGray; //background and borderline in KidxGraph
  FrColor         : TColor = clBlack;

  tstcolor        : integer;    // for color testing

implementation

{ TfrmPropagation }
uses dData, dUtils, uMyIni, fNewQSO;

procedure TPropThread.Execute;
var
  HTTP   : THTTPSend;
  tmp    : String;
  m      : TStringList;
  p      : Integer;
  ki     : Integer;
  t      : String;

begin
  if frmPropagation.running then
    exit;
  frmPropagation.running := True;
  frmPropagation.ak   := '';
  frmPropagation.ab   := '';
  frmPropagation.k    := '';
  frmPropagation.sfi  := '';
  frmPropagation.ssn  := '';
  frmPropagation.sa   := '';
  frmPropagation.gf   := '';
  frmPropagation.au   := '';
  frmPropagation.time := '';
  frmPropagation.date := '';
  frmPropagation.UTC  := '';
  frmPropagation.HttpFrm  := '';
  frmPropagation.k3h  := '';

  FreeOnTerminate := True;
  http   := THTTPSend.Create;
  m      := TStringList.Create;
  try
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');
    frmPropagation.HttpFrm  := 'http://dk0wcy.de/magnetogram/';                //fetch address
    if HTTP.HTTPMethod('GET', frmPropagation.HttpFrm ) then
    begin
      m.LoadFromStream(HTTP.Document);
      tmp := m.Text;

    if dmData.DebugLevel >=1 then
      begin
       Writeln('TMP:      ',tmp)
      end;

       p   := Pos('>Indices of',tmp);
      frmPropagation.time   := trim(copy(tmp,p+1,30));
      frmPropagation.time   := copy(frmPropagation.time,1,Pos('</th>',frmPropagation.time)-1);
      frmPropagation.time   := frmPropagation.time;
      frmPropagation.UTC    := TimeToStr(nowUTC());
      frmPropagation.date   := DateToStr(nowUTC());

      p   := Pos('>Boulder A',tmp);
      frmPropagation.ab   := trim(copy(tmp,p+44,18));
      frmPropagation.ab   := copy(frmPropagation.ab,1,Pos('</b>',frmPropagation.ab)-1);

      p  := Pos('>Solar Activity',tmp);
      frmPropagation.sa   := trim(copy(tmp,p+44,18));
      frmPropagation.sa   := copy(frmPropagation.sa,1,Pos('</b>',frmPropagation.sa)-1);

      p   := Pos('>Kiel A',tmp);
      frmPropagation.ak  := trim(copy(tmp,p+44,18));
      frmPropagation.ak  := copy(frmPropagation.ak,1,Pos('</b>',frmPropagation.ak)-1);

      p   := Pos('>Kiel current k',tmp);
      frmPropagation.k   := trim(copy(tmp,p+44,18));
      frmPropagation.k   := copy(frmPropagation.k,1,Pos('</b>',frmPropagation.k)-1);

      p   := Pos('>Geomagnetic Field',tmp);
      frmPropagation.gf   := trim(copy(tmp,p+44,18));
      frmPropagation.gf   := copy(frmPropagation.gf,1,Pos('</b>',frmPropagation.gf)-1);

      p   := Pos('>Sunspot Number',tmp);
      frmPropagation.ssn   := trim(copy(tmp,p+44,18));
      frmPropagation.ssn   := copy(frmPropagation.ssn,1,Pos('</b>',frmPropagation.ssn)-1);

      p   := Pos('>Aurora',tmp);
      frmPropagation.au   := trim(copy(tmp,p+44,18));
      frmPropagation.au   := copy(frmPropagation.au,1,Pos('</b>',frmPropagation.au)-1);

      p   := Pos('>Solar Flux',tmp);
      frmPropagation.sfi := trim(copy(tmp,p+30,18));
      frmPropagation.sfi := copy(frmPropagation.sfi,1,Pos('</b>',frmPropagation.sfi)-1);

      p := Pos('>Kiel 3-hour k',tmp);
      frmPropagation.k3h := trim(copy(tmp,p+44,18));
      frmPropagation.k3h := copy(frmPropagation.k3h,1,Pos('</b>',frmPropagation.k3h)-1)
     end;

    if dmData.DebugLevel >=1 then
    begin
      Writeln('Time:     ',frmPropagation.time);
      Writeln('UTC:     ',frmPropagation.UTC);
      Writeln('Boulder A:',frmPropagation.ab);
      Writeln('Solar Act:',frmPropagation.sa);
      Writeln('Kiel    A:',frmPropagation.ak);
      Writeln('Kiel K:   ',frmPropagation.k);
      Writeln('Kiel 3h   ',frmPropagation.k3h);
      Writeln('GF:       ',frmPropagation.gf);
      Writeln('SSN:      ',frmPropagation.ssn);
      Writeln('Aurora:   ',frmPropagation.au);
      Writeln('SFI:      ',frmPropagation.sfi)
    end;

    Synchronize(@frmPropagation.SyncProp);
  finally
    http.Free;
    m.Free;
    frmPropagation.running := False
  end
end;


procedure TfrmPropagation.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  tmrProp.Enabled := False;
  dmUtils.SaveWindowPos(frmPropagation)
end;

procedure TfrmPropagation.FormCreate(Sender: TObject);
var kloop : integer;

Begin
  //clear K-idx image and data
  ImageKidx.Canvas.brush.style := bsSolid;
  ImageKidx.Canvas.brush.Color := BkColor;
  ImageKidx.Canvas.pen.Color   := BkColor;
  ImageKidx.Canvas.Rectangle(0,0,ImageKidx.Width,ImageKidx.Height);
  ImageKidx.Canvas.pen.Width   := 1;
  for kloop := 0 to 35 do
   begin
     KValues[kloop] :=-1;
   end;
  if dmData.DebugLevel >=1 then
      begin
       tstcolor :=0;
      end;
end;

procedure TfrmPropagation.FormDblClick(Sender: TObject);
begin
  tmrPropTimer(nil)
end;

procedure TfrmPropagation.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key= VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0
  end
end;

procedure TfrmPropagation.FormShow(Sender: TObject);
const
  C_LOADING = 'Loading...';
begin
  running := False;
  dmUtils.LoadWindowPos(frmPropagation);
  DBoulAidx.Caption  := C_LOADING;
  DKielAidx.Caption := C_LOADING;
  DCurKidx.Caption  := C_LOADING;
  DKiel3K.Caption  := C_LOADING;
  DAurora.Caption := C_LOADING;
  DSolarFlx.Caption     := C_LOADING;
  DSunSNr.Caption     := C_LOADING;
  DSolAct.Caption      := C_LOADING;
  DGeomFi.Caption      := C_LOADING;
  lblInfo.Caption    := '';
  lblInfoUTC.Caption := '';
  lblInfoDate.Caption := '';
  lblInfoFrom.Caption:= frmPropagation.HttpFrm;
  tmrProp.Enabled    := False;
  tmrProp.Interval   := 1000 * 60 * 5; //every 5 minutes do refresh
  tmrProp.Enabled    := True;
  tmrPropTimer(nil)
end;

procedure TfrmPropagation.lblBoulAidxClick(Sender: TObject);
begin

end;

procedure TfrmPropagation.lblInfoFromMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  OpenURL(frmPropagation.HttpFrm);
end;

procedure TfrmPropagation.lblInfoFromMouseEnter(Sender: TObject);
begin
  TLabel(Sender).Font.Style := [fsUnderLine];
  TLabel(Sender).Font.Color := clBlue;
  TLabel(Sender).Cursor := crHandPoint;
end;

procedure TfrmPropagation.lblInfoFromMouseLeave(Sender: TObject);
begin
   TLabel(Sender).Font.Style := [];
  TLabel(Sender).Font.Color := clDefault;
  TLabel(Sender).Cursor := crDefault;
end;

procedure TfrmPropagation.sbtnRefreshClick(Sender : TObject);
begin
  tmrPropTimer(nil)
end;

procedure TfrmPropagation.tmrPropTimer(Sender: TObject);
var
  T : TPropThread;
begin
  T := TPropThread.Create(True);
  T.Start
end;

function TfrmPropagation.getKindexColor(kIndex : integer) : TColor;
begin

  if dmData.DebugLevel >=1 then
      begin
       kIndex := tstcolor;
       Writeln('Color selection by:      ',kIndex)
      end;

  case kIndex of
    0 .. 133      : Result :=RGBToColor(  0,180,  0); //Green
  134 .. 266      : Result :=RGBToColor(  0,222,  0); //lGreen
  267 .. 399      : Result :=RGBToColor( 96,240, 96); //llGreen
  400 .. 499      : Result :=RGBToColor(244,244,  0); //Yellow
  500 .. 599      : Result :=RGBToColor(255,130,  0); //Orange
  600 .. 699      : Result :=RGBToColor(245, 40, 65); //lred
  700 .. 799      : Result :=RGBToColor(215, 25, 30); //red
  800 .. 900      : Result :=RGBToColor(222, 48,222); //violet
  else
    Result := clDefault;
  end;

end;


procedure TfrmPropagation.SyncProp;

var
  dk : Double;
begin
  lblInfo.Caption    := time;
  lblInfoUTC.Caption := UTC;
  lblInfoDate.Caption := Date;
  lblInfoFrom.Caption:= HttpFrm;
  DBoulAidx.Caption  := ab;
  DKielAidx.Caption := ak;
  DKiel3K.Caption  := k3h;
  DCurKidx.Caption  := k;
  DSolarFlx.Caption     := sfi;
  DSunSNr.Caption     := ssn;
  DSolAct.Caption      := sa;
  DGeomFi.Caption      := gf;
  DAurora.Caption := au;

  if TryStrToFloat(k,dk) then
   begin
     DCurKidx.Color := getKindexColor(round(dk*100));
     DCurKidx.Font.Style := [fsBold];
   end
  else
   begin
    DCurKidx.Color := clBtnFace;
    DCurKidx.Font.Style := [];
   end;

  if TryStrToFloat(k3h,dk) then
   begin
    DKiel3K.Color := getKindexColor(round(dk*100));
    DKiel3K.Font.Style := [fsBold];
   end
  else
   begin
    DKiel3K.Color := clBtnFace;
    DKiel3K.Font.Style := [];
   end;

  frmPropagation.KidxGraph;

if dmData.DebugLevel >=1 then
 begin
  if tstcolor < 950 then
    tstcolor := tstcolor +50
    else
    tstcolor := 0;
  end;

end;
procedure TfrmPropagation.KidxGraph;
var
  kloop,kv : integer;
  dk       : double;
  AllKdata : boolean;


begin

if not TryStrToFloat(k,dk) then
          begin
            dk := 0;
            ImageKidx.Canvas.pen.Color := FrColor;
          end;

if dmData.DebugLevel >=1 then
      begin
       Writeln('Rounded Kidx for Graph:      ',round(dk*100))
      end;


AllKdata := True;
kloop := 0;
repeat
 begin
   if KValues[kloop]=-1 then  //all data is not yet filled
      begin
       KValues[kloop] := round(dk*100);      //place new value  to first free
       if dmData.DebugLevel >=1 then
        begin
         Writeln('There are :   ',kloop +1,' Kdata entries');
        end;
       kloop:=35;
       AllKdata :=False;
      end;
   inc(kloop);
 end;
until kloop>35;

kloop := 0;
repeat
 begin
  if AllKdata then
   begin
    if kloop<35  then
      KValues[kloop]:=KValues[kloop+1] //scroll data
    else
      begin
       if dmData.DebugLevel >=1 then
        begin
         Writeln('All Kdata entries filled; scroll and place new to end');
        end;
       KValues[kloop] := round(dk*100);      //place new value to end
      end;

   end;

  kv:=0;
  if  KValues[kloop]>-1 then
    begin
     kv := KValues[kloop];
     ImageKidx.Canvas.pen.Color := getKindexColor(kv);
    end
   else
    ImageKidx.Canvas.pen.Color := FrColor;

  //double lines pen width 1 are better than one with pen width 2 (why?)
  ImageKidx.Canvas.line(kloop*2,20 - 20*kv div 1000,kloop*2,20);    //Kidx value
  ImageKidx.Canvas.line(kloop*2+1,20 - 20*kv div 1000,kloop*2+1,20);
  ImageKidx.Canvas.pen.Color := BkColor;
  ImageKidx.Canvas.line(kloop*2,0,kloop*2,20 - 20*kv div 1000);     //the rest of bar
  ImageKidx.Canvas.line(kloop*2+1,0,kloop*2+1,20 - 20*kv div 1000);

  if (kloop mod 12) = 0 then
    begin
       ImageKidx.Canvas.pen.Color := FrColor;   //Hour lines if fetch is every 5min
       ImageKidx.Canvas.pen.style := psDot;
       ImageKidx.Canvas.line(kloop*2,0,kloop*2,20 - 20*kv div 1000);
       ImageKidx.Canvas.pen.style := psSolid;
    end;

  inc(kloop);
 end;
 until kloop>35;

 ImageKidx.Canvas.pen.Color := FrColor;
 ImageKidx.Canvas.pen.style := psDot;
 ImageKidx.Canvas.line(0,19,72,19); // bottom line
 ImageKidx.Canvas.pen.style := psSolid;
end;

initialization
  {$I fPropagation.lrs}

end.

