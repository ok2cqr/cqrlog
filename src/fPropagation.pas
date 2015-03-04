unit fPropagation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls,ComCtrls,Buttons, httpsend, LCLType, ftpsend;

type

  { TfrmPropagation }

  TfrmPropagation = class(TForm)
    Label1: TLabel;
    lblK3hour: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lblAbIndex: TLabel;
    lblAuIndex: TLabel;
    lblInfo: TLabel;
    lblGF: TLabel;
    lblSSN: TLabel;
    lblSFI: TLabel;
    lblSA: TLabel;
    lblKIndex: TLabel;
    lblAIndex: TLabel;
    sbtnRefresh : TSpeedButton;
    tmrProp: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormDblClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure sbtnRefreshClick(Sender : TObject);
    procedure tmrPropTimer(Sender: TObject);
  private
    { private declarations }
  public
    a    : String;
    ab   : String;
    k    : String;
    k3h  : String;
    sfi  : String;
    ssn  : String;
    sa   : String;
    gf   : String;
    time : String;
    au   : String;
    running : Boolean;

    procedure SyncProp;
  end; 

  type
    TPropThread = class(TThread)
    protected
      procedure Execute; override;
  end;


var
  frmPropagation: TfrmPropagation;

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
  frmPropagation.a    := '';
  frmPropagation.ab   := '';
  frmPropagation.k    := '';
  frmPropagation.sfi  := '';
  frmPropagation.ssn  := '';
  frmPropagation.sa   := '';
  frmPropagation.gf   := '';
  frmPropagation.au   := '';
  frmPropagation.time := '';
  frmPropagation.k3h  := '';

  FreeOnTerminate := True;
  http   := THTTPSend.Create;
  m      := TStringList.Create;
  try
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');
    if HTTP.HTTPMethod('GET', 'http://dk0wcy.de/magnetogram/' ) then
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
      frmPropagation.time   := frmPropagation.time + ' ' + TimeToStr(Time);

      p   := Pos('>Boulder A',tmp);
      frmPropagation.ab   := trim(copy(tmp,p+44,18));
      frmPropagation.ab   := copy(frmPropagation.ab,1,Pos('</b>',frmPropagation.ab)-1);

      p  := Pos('>Solar Activity',tmp);
      frmPropagation.sa   := trim(copy(tmp,p+44,18));
      frmPropagation.sa   := copy(frmPropagation.sa,1,Pos('</b>',frmPropagation.sa)-1);

      p   := Pos('>Kiel A',tmp);
      frmPropagation.a   := trim(copy(tmp,p+44,18));
      frmPropagation.a   := copy(frmPropagation.a,1,Pos('</b>',frmPropagation.a)-1);

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
      Writeln('Boulder A:',frmPropagation.ab);
      Writeln('Solar Act:',frmPropagation.sa);
      Writeln('Kiel    A:',frmPropagation.a);
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
  lblAIndex.Caption  := C_LOADING;
  lblAbIndex.Caption := C_LOADING;
  lblKIndex.Caption  := C_LOADING;
  lblK3hour.Caption  := C_LOADING;
  lblAuIndex.Caption := C_LOADING;
  lblSFI.Caption     := C_LOADING;
  lblSSN.Caption     := C_LOADING;
  lblSA.Caption      := C_LOADING;
  lblGF.Caption      := C_LOADING;
  lblInfo.Caption    := '';
  tmrProp.Enabled    := False;
  tmrProp.Interval   := 1000 * 60 * 5; //every 5 minutes do refresh
  tmrProp.Enabled    := True;
  tmrPropTimer(nil)
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

procedure TfrmPropagation.SyncProp;

  function getKindexColor(kIndex : Double) : TColor;
  begin
    if (kIndex<=3) then
      Result := clGreen
    else if (kIndex>3) and (kIndex<5) then
      Result := TColor($0000A2FF)
    else if (kIndex>=5) and (kIndex<6) then
      Result := TColor($00006CFF)
    else
      Result := clRed
  end;

var
  dk : Double;
begin
  lblInfo.Caption    := time;
  lblAbIndex.Caption := ab;
  lblSA.Caption      := sa;
  lblAIndex.Caption  := a;
  lblKIndex.Caption  := k;
  lblGF.Caption      := gf;
  lblSSN.Caption     := ssn;
  lblAuIndex.Caption := au;
  lblSFI.Caption     := sfi;
  lblK3hour.Caption  := k3h;

  if TryStrToFloat(k,dk) then
    lblKIndex.Font.Color := getKindexColor(dk)
  else
    lblKIndex.Font.Color := clBlack;

  if TryStrToFloat(k3h,dk) then
    lblK3hour.Font.Color := getKindexColor(dk)
  else
    lblK3hour.Font.Color := clBlack
end;

initialization
  {$I fPropagation.lrs}

end.

