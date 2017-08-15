unit fPropDK0WCY;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, Buttons, httpsend, LCLType, ftpsend,
  lazutf8sysutils, lclintf;

type

  { TfrmPropDK0WCY }

  TfrmPropDK0WCY = class(TForm)
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
    sbtnRefresh: TSpeedButton;
    tmrProp: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDblClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure lblInfoFromMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure lblInfoFromMouseEnter(Sender: TObject);
    procedure lblInfoFromMouseLeave(Sender: TObject);
    procedure sbtnRefreshClick(Sender: TObject);
    procedure tmrPropTimer(Sender: TObject);

  private
    { private declarations }
  public
    ak: string;
    ab: string;
    k: string;
    k3h: string;
    sfi: string;
    ssn: string;
    sa: string;
    gf: string;
    au: string;
    time: string;
    date: string;
    UTC: string;
    HttpFrm: string;
    running: boolean;

    dbc: integer; // debug colors

    procedure SyncProp;
    procedure KidxGraph;
    function getKindexColor(kIndex: integer): TColor;
  end;

type
  KData = array [0..35] of integer;   //stores 3h K-idx data

  TPropThread = class(TThread)
  protected
    procedure Execute; override;
  end;


var
  frmPropDK0WCY: TfrmPropDK0WCY;
  KValues: KData;
  BkColor: TColor = clGray; //background and borderline in KidxGraph
  FrColor: TColor = clBlack;

  tstcolor: integer;    // for color testing

implementation
{$R *.lfm}

{ TfrmPropDK0WCY }
uses dData, dUtils, uMyIni, fNewQSO;

procedure TPropThread.Execute;
var
  HTTP: THTTPSend;
  tmp: string;
  m: TStringList;
  p: integer;
  ki: integer;
  t: string;

begin
  if frmPropDK0WCY.running then
    exit;
  frmPropDK0WCY.running := True;
  frmPropDK0WCY.ak := '';
  frmPropDK0WCY.ab := '';
  frmPropDK0WCY.k := '';
  frmPropDK0WCY.sfi := '';
  frmPropDK0WCY.ssn := '';
  frmPropDK0WCY.sa := '';
  frmPropDK0WCY.gf := '';
  frmPropDK0WCY.au := '';
  frmPropDK0WCY.time := '';
  frmPropDK0WCY.date := '';
  frmPropDK0WCY.UTC := '';
  frmPropDK0WCY.HttpFrm := '';
  frmPropDK0WCY.k3h := '';

  FreeOnTerminate := True;
  http := THTTPSend.Create;
  m := TStringList.Create;
  try
    HTTP.ProxyHost := cqrini.ReadString('Program', 'Proxy', '');
    HTTP.ProxyPort := cqrini.ReadString('Program', 'Port', '');
    HTTP.UserName := cqrini.ReadString('Program', 'User', '');
    HTTP.Password := cqrini.ReadString('Program', 'Passwd', '');
    frmPropDK0WCY.HttpFrm := 'http://dk0wcy.de/magnetogram/';
    //fetch address
    if HTTP.HTTPMethod('GET', frmPropDK0WCY.HttpFrm) then
    begin
      m.LoadFromStream(HTTP.Document);
      tmp := m.Text;

      if dmData.DebugLevel >= 1 then
      begin
        Writeln('TMP:      ', tmp);
      end;

      p := Pos('>Indices of', tmp);
      frmPropDK0WCY.time := trim(copy(tmp, p + 1, 30));
      frmPropDK0WCY.time :=
        copy(frmPropDK0WCY.time, 1, Pos('</th>', frmPropDK0WCY.time) - 1);
      frmPropDK0WCY.time := frmPropDK0WCY.time;
      frmPropDK0WCY.UTC := TimeToStr(nowUTC());
      frmPropDK0WCY.date := DateToStr(nowUTC());

      p := Pos('>Boulder A', tmp);
      frmPropDK0WCY.ab := trim(copy(tmp, p + 44, 18));
      frmPropDK0WCY.ab := copy(frmPropDK0WCY.ab, 1, Pos('</b>', frmPropDK0WCY.ab) - 1);

      p := Pos('>Solar Activity', tmp);
      frmPropDK0WCY.sa := trim(copy(tmp, p + 44, 18));
      frmPropDK0WCY.sa := copy(frmPropDK0WCY.sa, 1, Pos('</b>', frmPropDK0WCY.sa) - 1);

      p := Pos('>Kiel A', tmp);
      frmPropDK0WCY.ak := trim(copy(tmp, p + 44, 18));
      frmPropDK0WCY.ak := copy(frmPropDK0WCY.ak, 1, Pos('</b>', frmPropDK0WCY.ak) - 1);

      p := Pos('>Kiel current k', tmp);
      frmPropDK0WCY.k := trim(copy(tmp, p + 44, 18));
      frmPropDK0WCY.k := copy(frmPropDK0WCY.k, 1, Pos('</b>', frmPropDK0WCY.k) - 1);

      p := Pos('>Geomagnetic Field', tmp);
      frmPropDK0WCY.gf := trim(copy(tmp, p + 44, 18));
      frmPropDK0WCY.gf := copy(frmPropDK0WCY.gf, 1, Pos('</b>', frmPropDK0WCY.gf) - 1);

      p := Pos('>Sunspot Number', tmp);
      frmPropDK0WCY.ssn := trim(copy(tmp, p + 44, 18));
      frmPropDK0WCY.ssn := copy(frmPropDK0WCY.ssn, 1, Pos('</b>', frmPropDK0WCY.ssn) - 1);

      p := Pos('>Aurora', tmp);
      frmPropDK0WCY.au := trim(copy(tmp, p + 44, 18));
      frmPropDK0WCY.au := copy(frmPropDK0WCY.au, 1, Pos('</b>', frmPropDK0WCY.au) - 1);

      p := Pos('>Solar Flux', tmp);
      frmPropDK0WCY.sfi := trim(copy(tmp, p + 30, 18));
      frmPropDK0WCY.sfi := copy(frmPropDK0WCY.sfi, 1, Pos('</b>', frmPropDK0WCY.sfi) - 1);

      p := Pos('>Kiel 3-hour k', tmp);
      frmPropDK0WCY.k3h := trim(copy(tmp, p + 44, 18));
      frmPropDK0WCY.k3h := copy(frmPropDK0WCY.k3h, 1, Pos('</b>', frmPropDK0WCY.k3h) - 1);
    end;

    if dmData.DebugLevel >= 1 then
    begin
      Writeln('Time:     ', frmPropDK0WCY.time);
      Writeln('UTC:     ', frmPropDK0WCY.UTC);
      Writeln('Boulder A:', frmPropDK0WCY.ab);
      Writeln('Solar Act:', frmPropDK0WCY.sa);
      Writeln('Kiel    A:', frmPropDK0WCY.ak);
      Writeln('Kiel K:   ', frmPropDK0WCY.k);
      Writeln('Kiel 3h   ', frmPropDK0WCY.k3h);
      Writeln('GF:       ', frmPropDK0WCY.gf);
      Writeln('SSN:      ', frmPropDK0WCY.ssn);
      Writeln('Aurora:   ', frmPropDK0WCY.au);
      Writeln('SFI:      ', frmPropDK0WCY.sfi);
    end;

    Synchronize(@frmPropDK0WCY.SyncProp);
  finally
    http.Free;
    m.Free;
    frmPropDK0WCY.running := False
  end;
end;


procedure TfrmPropDK0WCY.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  tmrProp.Enabled := False;
  dmUtils.SaveWindowPos(frmPropDK0WCY);
end;

procedure TfrmPropDK0WCY.FormCreate(Sender: TObject);
var
  kloop: integer;

begin
  //clear K-idx image and data
  ImageKidx.Canvas.brush.style := bsSolid;
  ImageKidx.Canvas.brush.Color := BkColor;
  ImageKidx.Canvas.pen.Color := BkColor;
  ImageKidx.Canvas.Rectangle(0, 0, ImageKidx.Width, ImageKidx.Height);
  ImageKidx.Canvas.pen.Width := 1;
  for kloop := 0 to 35 do
  begin
    KValues[kloop] := -1;
  end;

 { if dmData.DebugLevel >=1 then
      begin
       tstcolor :=0;
      end; }
end;

procedure TfrmPropDK0WCY.FormDblClick(Sender: TObject);
begin
  tmrPropTimer(nil);
end;

procedure TfrmPropDK0WCY.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if (key = VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0;
  end;
end;

procedure TfrmPropDK0WCY.FormShow(Sender: TObject);
const
  C_LOADING = 'Loading...';
begin
  running := False;
  dmUtils.LoadWindowPos(frmPropDK0WCY);
  dmUtils.LoadFontSettings(frmPropDK0WCY);
  DBoulAidx.Caption := C_LOADING;
  DKielAidx.Caption := C_LOADING;
  DCurKidx.Caption := C_LOADING;
  DKiel3K.Caption := C_LOADING;
  DAurora.Caption := C_LOADING;
  DSolarFlx.Caption := C_LOADING;
  DSunSNr.Caption := C_LOADING;
  DSolAct.Caption := C_LOADING;
  DGeomFi.Caption := C_LOADING;
  lblInfo.Caption := '';
  lblInfoUTC.Caption := '';
  lblInfoDate.Caption := '';
  lblInfoFrom.Caption := frmPropDK0WCY.HttpFrm;
  tmrProp.Enabled := False;
  tmrProp.Interval := 1000 * 60 * 5; //every 5 minutes do refresh
  tmrProp.Enabled := True;
  tmrPropTimer(nil);
end;


procedure TfrmPropDK0WCY.lblInfoFromMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
  OpenURL(frmPropDK0WCY.HttpFrm);
end;

procedure TfrmPropDK0WCY.lblInfoFromMouseEnter(Sender: TObject);
begin
  TLabel(Sender).Font.Style := [fsUnderLine];
  TLabel(Sender).Font.Color := clBlue;
  TLabel(Sender).Cursor := crHandPoint;
end;

procedure TfrmPropDK0WCY.lblInfoFromMouseLeave(Sender: TObject);
begin
  TLabel(Sender).Font.Style := [];
  TLabel(Sender).Font.Color := clDefault;
  TLabel(Sender).Cursor := crDefault;
end;

procedure TfrmPropDK0WCY.sbtnRefreshClick(Sender: TObject);
begin
  tmrPropTimer(nil);
end;

procedure TfrmPropDK0WCY.tmrPropTimer(Sender: TObject);
var
  T: TPropThread;
begin
  T := TPropThread.Create(True);
  T.Start;
end;

function TfrmPropDK0WCY.getKindexColor(kIndex: integer): TColor;
begin

 { if dmData.DebugLevel >=1 then
      begin
       kIndex := tstcolor;
       Writeln('Color selection by:      ',kIndex)
      end;}

  case kIndex of
    0 .. 133: Result := RGBToColor(0, 180, 0); //Green
    134 .. 266: Result := RGBToColor(0, 222, 0); //lGreen
    267 .. 399: Result := RGBToColor(96, 240, 96); //llGreen
    400 .. 499: Result := RGBToColor(244, 244, 0); //Yellow
    500 .. 599: Result := RGBToColor(255, 130, 0); //Orange
    600 .. 699: Result := RGBToColor(245, 40, 65); //lred
    700 .. 799: Result := RGBToColor(215, 25, 30); //red
    800 .. 900: Result := RGBToColor(222, 48, 222); //violet
    else
      Result := clDefault;
  end;

end;


procedure TfrmPropDK0WCY.SyncProp;

var
  dk: double;
begin
  lblInfo.Caption := time;
  lblInfoUTC.Caption := UTC;
  lblInfoDate.Caption := Date;
  lblInfoFrom.Caption := HttpFrm;
  DBoulAidx.Caption := ab;
  DKielAidx.Caption := ak;
  DKiel3K.Caption := k3h;
  DCurKidx.Caption := k;
  DSolarFlx.Caption := sfi;
  DSunSNr.Caption := ssn;
  DSolAct.Caption := sa;
  DGeomFi.Caption := gf;
  DAurora.Caption := au;

  if TryStrToFloat(k, dk) then
  begin
    DCurKidx.Color := getKindexColor(round(dk * 100));
    DCurKidx.Font.Style := [fsBold];
  end
  else
  begin
    DCurKidx.Color := clBtnFace;
    DCurKidx.Font.Style := [];
  end;

  if TryStrToFloat(k3h, dk) then
  begin
    DKiel3K.Color := getKindexColor(round(dk * 100));
    DKiel3K.Font.Style := [fsBold];
  end
  else
  begin
    DKiel3K.Color := clBtnFace;
    DKiel3K.Font.Style := [];
  end;

  frmPropDK0WCY.KidxGraph;

{if dmData.DebugLevel >=1 then
 begin
  if tstcolor < 950 then
    tstcolor := tstcolor +50
    else
    tstcolor := 0;
  end;   }

end;

procedure TfrmPropDK0WCY.KidxGraph;
var
  kloop, kv: integer;
  dk: double;
  AllKdata: boolean;

begin

  if not TryStrToFloat(k, dk) then
  begin
    dk := 0;
    ImageKidx.Canvas.pen.Color := FrColor;
  end;

  if dmData.DebugLevel >= 1 then
  begin
    Writeln('Rounded Kidx for Graph:      ', round(dk * 100));
  end;


  AllKdata := True;
  kloop := 0;
  repeat
    begin
      if KValues[kloop] = -1 then  //all data is not yet filled
      begin
        KValues[kloop] := round(dk * 100);      //place new value  to first free
        if dmData.DebugLevel >= 1 then
        begin
          Writeln('There are :   ', kloop + 1, ' Kdata entries');
        end;
        kloop := 35;
        AllKdata := False;
      end;
      Inc(kloop);
    end;
  until kloop > 35;

  kloop := 0;
  repeat
    begin
      if AllKdata then
      begin
        if kloop < 35 then
          KValues[kloop] := KValues[kloop + 1] //scroll data
        else
        begin
          if dmData.DebugLevel >= 1 then
          begin
            Writeln('All Kdata entries filled; scroll and place new to end');
          end;
          KValues[kloop] := round(dk * 100);      //place new value to end
        end;

      end;

      kv := 0;
      if KValues[kloop] > -1 then
      begin
        kv := KValues[kloop];
        ImageKidx.Canvas.pen.Color := getKindexColor(kv);
      end
      else
        ImageKidx.Canvas.pen.Color := FrColor;

      //double lines pen width 1 are better than one with pen width 2 (why?)
      ImageKidx.Canvas.line(kloop * 2, 20 - 20 * kv div 1000, kloop * 2, 20);    //Kidx value
      ImageKidx.Canvas.line(kloop * 2 + 1, 20 - 20 * kv div 1000, kloop * 2 + 1, 20);
      ImageKidx.Canvas.pen.Color := BkColor;
      ImageKidx.Canvas.line(kloop * 2, 0, kloop * 2, 20 - 20 * kv div 1000);     //the rest of bar
      ImageKidx.Canvas.line(kloop * 2 + 1, 0, kloop * 2 + 1, 20 - 20 * kv div 1000);

      if (kloop mod 12) = 0 then
      begin
        ImageKidx.Canvas.pen.Color := FrColor;   //Hour lines if fetch is every 5min
        ImageKidx.Canvas.pen.style := psDot;
        ImageKidx.Canvas.line(kloop * 2, 0, kloop * 2, 20 - 20 * kv div 1000);
        ImageKidx.Canvas.pen.style := psSolid;
      end;

      Inc(kloop);
    end;
  until kloop > 35;

  ImageKidx.Canvas.pen.Color := FrColor;
  ImageKidx.Canvas.pen.style := psDot;
  ImageKidx.Canvas.line(0, 19, 72, 19); // bottom line
  ImageKidx.Canvas.pen.style := psSolid;
end;

initialization

end.
