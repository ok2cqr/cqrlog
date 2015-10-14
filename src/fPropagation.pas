unit fPropagation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls,ComCtrls,Buttons, httpsend, LCLType, Menus, ftpsend;

type

  { TfrmPropagation }

  TfrmPropagation = class(TForm)
    imgProp: TImage;
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
    mnuRefresh: TMenuItem;
    popPropagation: TPopupMenu;
    tmrProp: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormDblClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure mnuRefreshClick(Sender: TObject);
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
    procedure SyncPropImage;

    procedure RefreshPropagation;
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
  http := THTTPSend.Create;
  m    := TStringList.Create;
  try try
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');

    if cqrini.ReadBool('prop','AsImage',True) then
    begin
      if HTTP.HTTPMethod('GET',cqrini.ReadString('prop','Url','http://www.hamqsl.com/solarbrief.php')) then
      begin
        HTTP.Document.SaveToFile(dmData.HomeDir + 'propagation.gif');
        Synchronize(@frmPropagation.SyncPropImage)
      end
    end
    else begin

      if HTTP.HTTPMethod('GET', 'http://www.hamqsl.com/solarxml.php' ) then
      begin
        m.LoadFromStream(HTTP.Document);
        tmp := m.Text;
        Writeln(tmp);
        if dmData.DebugLevel >=1 then
        begin
         Writeln('TMP:      ',tmp)
        end
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

      Synchronize(@frmPropagation.SyncProp)
    end
  except
    on E : Exception do
      Writeln(E.Message)
  end
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
  tmrProp.Interval   := 1000 * 60 * 1; //every 5 minutes do refresh
  tmrProp.Enabled    := True;
  tmrPropTimer(nil)
end;

procedure TfrmPropagation.mnuRefreshClick(Sender: TObject);
begin
  RefreshPropagation
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
  imgProp.Visible := False;

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

procedure TfrmPropagation.SyncPropImage;
begin
  try try
    imgProp.Visible := True;
    imgProp.Picture.LoadFromFile(dmData.HomeDir + 'propagation.gif');
    Height := imgProp.Picture.Height;
    Width  := imgProp.Picture.Width;
    imgProp.Align := alClient
  except
    on E : Exception do
      Writeln(E.Message)
  end
  finally
  end
end;

procedure TfrmPropagation.RefreshPropagation;
begin
  Writeln('Refresing');
  tmrPropTimer(nil)
end;

initialization
  {$I fPropagation.lrs}

end.

