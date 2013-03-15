unit fPropagation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls,ComCtrls,Buttons, httpsend;

type

  { TfrmPropagation }

  TfrmPropagation = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    lblInfo: TLabel;
    lblGF: TLabel;
    lblSSN: TLabel;
    lblSFI: TLabel;
    lblKIndex: TLabel;
    lblAIndex: TLabel;
    sbtnRefresh : TSpeedButton;
    tmrProp: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormDblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure sbtnRefreshClick(Sender : TObject);
    procedure tmrPropTimer(Sender: TObject);
  private
    { private declarations }
  public
    a : String;
    k : String;
    sfi : String;
    ssn : String;
    gf  : String;
    time : String;
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
uses dData, dUtils, uMyIni;

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
  frmPropagation.k    := '';
  frmPropagation.sfi  := '';
  frmPropagation.ssn  := '';
  frmPropagation.gf   := '';
  frmPropagation.time := '';
  FreeOnTerminate := True;
  http   := THTTPSend.Create;
  m      := TStringList.Create;
  try
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');
    if HTTP.HTTPMethod('GET', 'http://www.swpc.noaa.gov/ftpdir/latest/wwv.txt') then
    begin
      m.LoadFromStream(HTTP.Document);
      tmp := m.Text;
      p   := Pos('Solar flux',tmp);
      frmPropagation.sfi := trim(copy(tmp,p+11,3));

      p   := Pos('A-INDEX',UpperCase(tmp)); //they sometimes have A-Index instead of  A-index
      frmPropagation.a   := trim(copy(tmp,p+8,10));
      frmPropagation.a   := copy(frmPropagation.a,1,Pos('.',frmPropagation.a)-1);

      p   := Pos('K-index',tmp);
      tmp := copy(tmp,p,50);
      p   := Pos('was',tmp);
      tmp := trim(copy(tmp,p+4,Pos('.',tmp)-p-1));
      frmPropagation.k := copy(tmp,1,Length(tmp)-1)
    end;

    HTTP.Clear;
    if HTTP.HTTPMethod('GET', 'http://www.swpc.noaa.gov/ftpdir/indices/DSD.txt') then
    begin
      m.LoadFromStream(HTTP.Document);
      tmp := m.Text;
      t := copy(tmp,Pos(':Issued:',tmp)+9,Pos('#',tmp)-1 - Pos(':Issued:',tmp)-9);
      frmPropagation.time := t;
      tmp := m.Strings[m.Count-1];
      frmPropagation.ssn := trim(copy(tmp,20,5))
    end;
    tmp := frmPropagation.k;
    if Pos('(',tmp) > 0 then
      tmp := trim(copy(tmp,1,Pos('(',tmp)-1));
    if TryStrToInt(tmp,ki) then
    begin
      case ki of
        0,1,2,3 : frmPropagation.gf := 'QUIET';
          4 : frmPropagation.gf := 'UNSET';
        5,6,7,8,9 : frmPropagation.gf := 'STORM'
        else
          frmPropagation.gf := ''
       end
    end;
    if dmData.DebugLevel >=1 then
    begin
      Writeln('SFI:  ',frmPropagation.sfi);
      Writeln('A:    ',frmPropagation.a);
      Writeln('K:    ',frmPropagation.k);
      Writeln('GF:   ',frmPropagation.gf);
      Writeln('SSN:  ',frmPropagation.ssn);
      Writeln('Time: ',frmPropagation.time)
    end;
    Synchronize(@frmPropagation.SyncProp)
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

procedure TfrmPropagation.FormShow(Sender: TObject);
begin
  running := False;
  dmUtils.LoadWindowPos(frmPropagation);
  tmrProp.Enabled  := False;
  tmrProp.Interval := 1000 * 60 * 5; //every 5 minutes do refresh
  tmrProp.Enabled  := True;
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
  T.Resume
end;

procedure TfrmPropagation.SyncProp;
begin
  lblAIndex.Caption := a;
  lblKIndex.Caption := k;
  lblSFI.Caption    := sfi;
  lblSSN.Caption    := ssn;
  lblGF.Caption     := gf;
  lblInfo.Caption   := time
end;

initialization
  {$I fPropagation.lrs}

end.

