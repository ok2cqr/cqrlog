unit fPropagation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls,ComCtrls,Buttons, httpsend, LCLType, Menus, ftpsend,
  DOM, XMLRead;

type
  TDayNight = record
    day   : String;
    night : String
end;

type

  { TfrmPropagation }

  TfrmPropagation = class(TForm)
    imgProp: TImage;
    Label1 : TLabel;
    Label10 : TLabel;
    Label11 : TLabel;
    Label12 : TLabel;
    Label13 : TLabel;
    Label14 : TLabel;
    Label15 : TLabel;
    Label16 : TLabel;
    Label17 : TLabel;
    Label18 : TLabel;
    Label19 : TLabel;
    lblDegree: TLabel;
    lbl2mEsEu : TLabel;
    lbl2mEsNa : TLabel;
    lbl6mEsEu : TLabel;
    Label8 : TLabel;
    lbl12d : TLabel;
    lbl12n : TLabel;
    lbl17d : TLabel;
    lbl17n : TLabel;
    lbl30d : TLabel;
    lbl30n : TLabel;
    lbl4mEsEu : TLabel;
    lbl80d : TLabel;
    Label5 : TLabel;
    Label6 : TLabel;
    Label9 : TLabel;
    lbl80n : TLabel;
    lblAu : TLabel;
    lblMag : TLabel;
    lblSigs : TLabel;
    Label2 : TLabel;
    Label3 : TLabel;
    Label4 : TLabel;
    Label7 : TLabel;
    lblAIndex : TLabel;
    lblGF : TLabel;
    lblKIndex : TLabel;
    lblSFI : TLabel;
    lblSSN : TLabel;
    mnuRefresh: TMenuItem;
    pnlVhfCondx : TPanel;
    pnlHfCondx : TPanel;
    pnlCondxValues : TPanel;
    popPropagation: TPopupMenu;
    sbInfo : TStatusBar;
    tmrProp: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormDblClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure mnuRefreshClick(Sender: TObject);
    procedure tmrPropTimer(Sender: TObject);
  private
    procedure SetHfCondxColorAndCaption(lbl : TLabel;desc : String);
  public
    LastUpdate : String;

    sfi   : String;
    a     : String;
    k     : String;
    ssn   : String;
    aur   : String;
    lat   : String;
    mag   : String;
    geo   : String;
    sigs  : String;
    fof2  : String;
    b8040 : TDayNight;
    b3020 : TDayNight;
    b1715 : TDayNight;
    b1210 : TDayNight;

    vhf_aur : String;
    skip_eu : String;
    skip_na : String;
    skip_eu_6m : String;
    skip_eu_4m : String;

    running : Boolean;

    procedure SyncProp;
    procedure SyncPropImage;

    procedure RefreshPropagation;
  end; 

  type
    TPropThread = class(TThread)
    private
      procedure LoadXMLFile;
    protected
      procedure Execute; override;
  end;


var
  frmPropagation: TfrmPropagation;

implementation
{$R *.lfm}

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
      if HTTP.HTTPMethod('GET',cqrini.ReadString('prop','Url','https://www.hamqsl.com/solarbrief.php')) then
      begin
        HTTP.Document.SaveToFile(dmData.HomeDir + 'propagation.gif');
        Synchronize(@frmPropagation.SyncPropImage)
      end
    end
    else begin
      if HTTP.HTTPMethod('GET', cqrini.ReadString('prop','UrlTxt','https://www.hamqsl.com/solarxml.php' )) then
      begin
        m.LoadFromStream(HTTP.Document);
        m.SaveToFile(dmData.HomeDir+'solar.xml');
        LoadXMLFile;
        Synchronize(@frmPropagation.SyncProp)
      end
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

procedure TPropThread.LoadXMLFile;
var
  Doc: TXMLDocument;
  Child: TDOMNode;
  j: Integer;
  data : TDOMNode;
begin
  try
    ReadXMLFile(Doc,dmData.HomeDir+'solar.xml');

    Child := Doc.DocumentElement.FirstChild;

    data := Child.FindNode('updated');
    if Assigned(data) and (data.ChildNodes.Count>0) then
      frmPropagation.LastUpdate := String(data.FirstChild.NodeValue);

    data := Child.FindNode('solarflux');
    if Assigned(data) and (data.ChildNodes.Count>0) then
      frmPropagation.sfi := String(data.FirstChild.NodeValue);

    data := Child.FindNode('aindex');
    if Assigned(data) and (data.ChildNodes.Count>0) then
      frmPropagation.a := String(data.FirstChild.NodeValue);

    data := Child.FindNode('kindex');
    if Assigned(data) and (data.ChildNodes.Count>0) then
      frmPropagation.k := String(data.FirstChild.NodeValue);

    data := Child.FindNode('sunspots');
    if Assigned(data) and (data.ChildNodes.Count>0) then
      frmPropagation.ssn := String(data.FirstChild.NodeValue);

    data := Child.FindNode('aurora');
    if Assigned(data) and (data.ChildNodes.Count>0) then
    begin
      if Assigned(data.FirstChild) then
        frmPropagation.aur := String(data.FirstChild.NodeValue)
    end;

    data := Child.FindNode('latdegree');
    if Assigned(data) and (data.ChildNodes.Count>0) then
      frmPropagation.lat := String(data.FirstChild.NodeValue);

    data := Child.FindNode('magneticfield');
    if Assigned(data) and (data.ChildNodes.Count>0) then
      frmPropagation.mag := String(data.FirstChild.NodeValue);

    data := Child.FindNode('geomagfield');
    if Assigned(data) and (data.ChildNodes.Count>0) then
      frmPropagation.geo := String(data.FirstChild.NodeValue);

    data := Child.FindNode('signalnoise');
    if Assigned(data) and (data.ChildNodes.Count>0) then
      frmPropagation.sigs := String(data.FirstChild.NodeValue);

    data := Child.FindNode('fof2');
    if Assigned(data) and (data.ChildNodes.Count>0) then
      frmPropagation.fof2 := String(data.FirstChild.NodeValue);

    data := Child.FindNode('calculatedconditions');
    if Assigned(data) and (data.ChildNodes.Count>0) then
    begin
      for j:=0 to data.ChildNodes.Count-1 do
      begin                                              //80-40m                                       daynight                                                         poor
        if (data.ChildNodes.Item[j].Attributes.Item[0].NodeValue = '80m-40m') then
        begin
          if (data.ChildNodes.Item[j].Attributes.Item[1].NodeValue = 'day') then
            frmPropagation.b8040.day := String(data.ChildNodes.Item[j].FirstChild.NodeValue)
          else
            frmPropagation.b8040.night := String(data.ChildNodes.Item[j].FirstChild.NodeValue)
        end;
        if (data.ChildNodes.Item[j].Attributes.Item[0].NodeValue = '30m-20m') then
        begin
          if (data.ChildNodes.Item[j].Attributes.Item[1].NodeValue = 'day') then
            frmPropagation.b3020.day := String(data.ChildNodes.Item[j].FirstChild.NodeValue)
          else
            frmPropagation.b3020.night := String(data.ChildNodes.Item[j].FirstChild.NodeValue)
        end;
        if (data.ChildNodes.Item[j].Attributes.Item[0].NodeValue = '17m-15m') then
        begin
          if (data.ChildNodes.Item[j].Attributes.Item[1].NodeValue = 'day') then
            frmPropagation.b1715.day := String(data.ChildNodes.Item[j].FirstChild.NodeValue)
          else
            frmPropagation.b1715.night := String(data.ChildNodes.Item[j].FirstChild.NodeValue)
        end;
        if (data.ChildNodes.Item[j].Attributes.Item[0].NodeValue = '12m-10m') then
        begin
          if (data.ChildNodes.Item[j].Attributes.Item[1].NodeValue = 'day') then
            frmPropagation.b1210.day := String(data.ChildNodes.Item[j].FirstChild.NodeValue)
          else
            frmPropagation.b1210.night := String(data.ChildNodes.Item[j].FirstChild.NodeValue)
        end
      end
    end;
    data := Child.FindNode('calculatedvhfconditions');
    if Assigned(data) then
    begin
      for j:=0 to data.ChildNodes.Count-1 do
      begin
        if (data.ChildNodes.Item[j].Attributes.Item[0].NodeValue = 'vhf-aurora') then
           frmPropagation.vhf_aur := String(data.ChildNodes.Item[j].FirstChild.NodeValue);
        if (data.ChildNodes.Item[j].Attributes.Item[0].NodeValue = 'E-Skip') then
        begin
          if (data.ChildNodes.Item[j].Attributes.Item[1].NodeValue = 'europe') then
            frmPropagation.skip_eu := String(data.ChildNodes.Item[j].FirstChild.NodeValue)
          else if (data.ChildNodes.Item[j].Attributes.Item[1].NodeValue = 'north_america') then
            frmPropagation.skip_na := String(data.ChildNodes.Item[j].FirstChild.NodeValue)
          else if (data.ChildNodes.Item[j].Attributes.Item[1].NodeValue = 'europe_6m') then
            frmPropagation.skip_eu_6m := String(data.ChildNodes.Item[j].FirstChild.NodeValue)
          else if (data.ChildNodes.Item[j].Attributes.Item[1].NodeValue = 'europe_4m') then
            frmPropagation.skip_eu_4m := String(data.ChildNodes.Item[j].FirstChild.NodeValue)
        end
      end
    end
  finally
    FreeAndNil(Doc)
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
  lblAIndex.Caption  := '';
  lblKIndex.Caption  := '';
  lblSFI.Caption     := '';
  lblSSN.Caption     := '';
  lblGF.Caption      := '';
  sbInfo.SimpleText  := '';
  lblAu.Caption      := '';
  lblMag.Caption     := '';
  lblSigs.Caption    := '';
  lblDegree.Caption  := '';
  tmrProp.Enabled    := False;
  tmrProp.Interval   := 1000 * 60 * 3; //every 3 minutes do refresh
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

  pnlCondxValues.Visible := cqrini.ReadBool('prop','Values',True);
  pnlHfCondx.Visible     := cqrini.ReadBool('prop','CalcHF',True);
  pnlVhfCondx.Visible    := cqrini.ReadBool('prop','CalcVHF',True);
  sbInfo.Visible         := True;

  pnlHfCondx.Left  := 168;
  pnlVhfCondx.Left := 368;

  if (not pnlCondxValues.Visible) and (not pnlHfCondx.Visible) and (not pnlVhfCondx.Visible) then
    pnlCondxValues.Visible := True;

  if (not pnlCondxValues.Visible) then
  begin
    if (not pnlHfCondx.Visible) then
      pnlVhfCondx.Left := 0
    else begin
      pnlHfCondx.Left := 0;
      if (pnlVhfCondx.Visible) then
      begin
        pnlVhfCondx.Left := pnlHfCondx.Width
      end
    end
  end
  else begin
    if (not pnlHfCondx.Visible) then
      pnlVhfCondx.Left := 168
  end;

  sbInfo.SimpleText := LastUpdate + ' data courtesy of Paul, N0NBH';
  lblAIndex.Caption := a;
  lblKIndex.Caption := k;
  lblGF.Caption     := geo;
  lblSSN.Caption    := ssn;
  lblSFI.Caption    := sfi;
  lblMag.Caption    := mag;
  lblSigs.Caption   := sigs;
  lblDegree.Caption := lat;

  SetHfCondxColorAndCaption(lbl80d,b8040.day);
  SetHfCondxColorAndCaption(lbl80n,b8040.night);

  SetHfCondxColorAndCaption(lbl30d,b3020.day);
  SetHfCondxColorAndCaption(lbl30n,b3020.night);

  SetHfCondxColorAndCaption(lbl17d,b1715.day);
  SetHfCondxColorAndCaption(lbl17n,b1715.night);

  SetHfCondxColorAndCaption(lbl12d,b1210.day);
  SetHfCondxColorAndCaption(lbl12n,b1210.night);

  lblAu.Caption := aur;
  if (aur='Band Closed') then
    lblAu.Font.Color := clRed
  else
    lblAu.Font.Color := clGreen;


  //I'm not sure if the HIGH MUF and other information
  //are common to all VHF bands
  lbl6mEsEu.Caption := skip_eu_6m;
  if (skip_eu_6m='Band Closed') then
    lbl6mEsEu.Font.Color := clRed
  else if (skip_eu_6m='High MUF') then
    lbl6mEsEu.Font.Color := TColor($000075FF)
  else
    lbl6mEsEu.Font.Color := clGreen;

  lbl4mEsEu.Caption := skip_eu_4m;
  if (skip_eu_4m='Band Closed') then
    lbl4mEsEu.Font.Color := clRed
  else if (skip_eu_4m='High MUF') then
    lbl4mEsEu.Font.Color := TColor($000075FF)
  else
    lbl4mEsEu.Font.Color := clGreen;

  lbl2mEsEu.Caption := skip_eu;
  if (skip_eu='Band Closed') then
    lbl2mEsEu.Font.Color := clRed
  else if (skip_eu='High MUF') then
    lbl2mEsEu.Font.Color := TColor($000075FF)
  else
    lbl2mEsEu.Font.Color := clGreen;

  lbl2mEsNa.Caption := skip_na;
  if (skip_na='Band Closed') then
    lbl2mEsNa.Font.Color := clRed
  else if (skip_na='High MUF') then
    lbl2mEsNa.Font.Color := TColor($000075FF)
  else
    lbl2mEsNa.Font.Color := clGreen;

  lblKIndex.Font.Color := getKindexColor(StrToFloat(k))
end;

procedure TfrmPropagation.SetHfCondxColorAndCaption(lbl : TLabel;desc : String);
begin
  lbl.Caption := desc;
  desc := LowerCase(desc);
  if (desc='poor') then
    lbl.Font.Color := clRed
  else if (desc='fair') then
    lbl.Font.Color := TColor($000075FF)
  else
    lbl.Font.Color := clGreen
end;

procedure TfrmPropagation.SyncPropImage;
begin
  try try
    imgProp.Visible := True;

    pnlCondxValues.Visible := False;
    pnlHfCondx.Visible     := False;
    pnlVhfCondx.Visible    := False;
    sbInfo.Visible         := False;

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
  tmrPropTimer(nil)
end;

end.

