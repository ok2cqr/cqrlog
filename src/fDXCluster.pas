(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fDXCluster;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, inifiles,
  ExtCtrls, ComCtrls, StdCtrls, Buttons, httpsend,  jakozememo,
  db, lcltype, dynlibs, lNetComponents, lnet;

type
  { TfrmDXCluster }

  TfrmDXCluster = class(TForm)
    btnClear: TButton;
    btnFont: TButton;
    btnFont1: TButton;
    btnHelp: TButton;
    btnSelect: TButton;
    btnTelConnect: TButton;
    btnWebConnect: TButton;
    Button1: TButton;
    Button2: TButton;
    dlgDXfnt: TFontDialog;
    edtCommand: TEdit;
    edtTelAddress: TEdit;
    Label1: TLabel;
    lblInfo: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel4: TPanel;
    pgDXCluster: TPageControl;
    pnlTelnet: TPanel;
    pnlWeb: TPanel;
    tabTelnet: TTabSheet;
    tabWeb: TTabSheet;
    tmrSpots: TTimer;
    procedure Button2Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnFontClick(Sender: TObject);
    procedure btnSelectClick(Sender: TObject);
    procedure btnTelConnectClick(Sender: TObject);
    procedure btnWebConnectClick(Sender: TObject);
    procedure edtCommandKeyPress(Sender: TObject; var Key: char);
    procedure tmrSpotsTimer(Sender: TObject);
  private
    telDesc    : String;
    telAddr    : String;
    telPort    : String;
    telUser    : String;
    telPass    : String;
    Running    : Boolean;
    FirstShow  : Boolean;
    ConOnShow  : Boolean;
    lTelnet    : TLTelnetClientComponent;
    procedure WebDbClick(where:longint;mb:TmouseButton;ms:TShiftState);
    procedure TelDbClick(where:longint;mb:TmouseButton;ms:TShiftState);
    procedure ConnectToWeb;
    procedure ConnectToTelnet;
    procedure SynWeb;
    procedure SynTelnet;
    procedure lConnect(aSocket: TLSocket);
    procedure lDisconnect(aSocket: TLSocket);
    procedure lReceive(aSocket: TLSocket);

    function  ShowSpot(spot : String; var sColor : Integer; var Country : String) : Boolean;
    function  GetFreq(spot : String) : String;
    function  GetCall(spot : String; web : Boolean = False) : String;
    function  GetSplit(spot : String) :String;
  public
    ConWeb    : Boolean;
    ConTelnet : Boolean;
    csTelnet  : TRTLCriticalSection;

    procedure SavePosition;
    procedure SendCommand(cmd : String);
    procedure StopAllConnections;

  end;

  type
    TWebThread = class(TThread)
    protected
      procedure Execute; override;
  end;

  type
    TTelThread = class(TThread)
    protected
      procedure Execute; override;
  end;

var
  frmDXCluster : TfrmDXCluster;
  Spots        : TStringList;
  WebSpots     : Tjakomemo;
  TelSpots     : Tjakomemo;
  mindex       : Integer;
  ThInfo       : String;
  ThSpot       : String;
  ThColor      : Integer;
  ThBckColor   : Integer;
  TelThread    : TTelThread;

implementation

{ TfrmDXCluster }

uses dUtils, fDXClusterList, dData, dDXCluster, fMain, fTRXControl, fNewQSO, fBandMap, fTestMain,
     uMyIni;

procedure TfrmDXCluster.ConnectToWeb;
var
  WebThread : TWebThread = nil;
begin
  tmrSpots.Enabled := True;
  if not Running then
  begin
    Running := True;
    if dmData.DebugLevel>=1 then
      Writeln('In ConnectWeb');
    if WebThread = nil then
      WebThread := TWebThread.Create(True);
    WebThread.Resume;
  end;
end;

procedure TfrmDXCluster.ConnectToTelnet;
begin
  if edtTelAddress.Text='' then
    exit;
  if ConTelnet then
  begin
    btnTelConnect.Caption := 'Connect';
    StopAllConnections;
    ConTelnet := False;
    exit
  end;
  try
    lTelnet.Host    := telAddr;
    lTelnet.Port    := StrToInt(telPort);
    lTelnet.Connect;
    lTelnet.CallAction;
  except
    on E : Exception do
    begin
      Application.MessageBox(Pchar('Cannot connect to telnet!:'+#13+'Error: '+E.Message),'Error!',mb_ok+mb_IconError)
    end
  end;

  if lTelnet.Connected then
  begin
    edtCommand.SetFocus;
    btnTelConnect.Caption := 'Disconnect';
    ConTelnet := True
  end
end;

procedure TfrmDXCluster.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  if not Assigned(cqrini) then
    exit;
  dmUtils.SaveWindowPos(frmDXCluster);
  cqrini.WriteInteger('DXCluster','Tab',pgDXCluster.ActivePageIndex);
  cqrini.WriteString('DXCluster','Desc',telDesc);
  cqrini.WriteString('DXCluster','Addr',telAddr);
  cqrini.WriteString('DXCluster','Port',telPort);
  cqrini.WriteString('DXCluster','User',telUser);
  cqrini.WriteString('DXCluster','Pass',telPass);
  cqrini.SaveToDisk;
  if ConWeb then
    btnWebConnect.Click;
  if ConTelnet then
    btnTelConnect.Click;
  tmrSpots.Enabled := False
end;

procedure TfrmDXCluster.btnHelpClick(Sender: TObject);
begin
  ShowHelp
end;

procedure TfrmDXCluster.FormDestroy(Sender: TObject);
begin
  if dmData.DebugLevel>=1 then Writeln('Closing DXCluster window');
  TelThread.Terminate;
  WebSpots.Free;
  TelSpots.Free
end;

procedure TfrmDXCluster.FormActivate(Sender: TObject);
begin
  if FirstShow and ConOnShow then
  begin
    btnTelConnect.Click;
    FirstShow := False;
  end;
end;

procedure TfrmDXCluster.Button2Click(Sender: TObject);
var
  TelThread : TTelThread = nil;
begin
  //Spots.Add('10368961.9  GB3CCX/B    17-Jan-2009 1905Z  51S IO81XW>IO81JM           <GW3TKH>')
  //Spots.Add('DX de GW3TKH  10368961.9  GB3CCX/B                                    1905Z     ');
  Spots.Add('DX de WT4Y:      14207.0  HI3CCP/MM                                    1905Z EL88');
  if not Running then
  begin
    Writeln('aa');
    if TelThread = nil then
    begin
      Writeln('ab');
      TelThread := TTelThread.Create(True);
    end;
    Writeln('bb');
    TelThread.Resume;
    Writeln('cc');
  end;
end;

procedure TfrmDXCluster.FormCreate(Sender: TObject);
begin
  InitCriticalSection(csTelnet);
  FirstShow := True;
  ConOnShow := False;
  lTelnet := TLTelnetClientComponent.Create(nil);

  lTelnet.OnConnect    := @lConnect;
  lTelnet.OnDisconnect := @lDisconnect;
  lTelnet.OnReceive    := @lReceive;

    WebSpots             := Tjakomemo.Create(pnlWeb);
    WebSpots.parent      := pnlWeb;
    WebSpots.autoscroll  := True;
    WebSpots.oncdblclick := @WebDbClick;
    WebSpots.Align       := alClient;
    WebSpots.nastav_jazyk(1);


    TelSpots             := Tjakomemo.Create(pnlTelnet);
    TelSpots.parent      := pnlTelnet;
    TelSpots.autoscroll  := True;
    TelSpots.oncdblclick := @TelDbClick;
    TelSpots.Align       := alClient;
    TelSpots.nastav_jazyk(1);

    Spots := TStringList.Create;
    Spots.Clear;
    Running := False;
    mindex  := 1;

    TelThread := TTelThread.Create(True);
    TelThread.FreeOnTerminate := True;
    TelThread.Resume
end;

procedure TfrmDXCluster.WebDbClick(where:longint;mb:TmouseButton;ms:TShiftState);
var
  spot : String = '';
  tmp  : Integer = 0;
  freq : String = '';
  mode : String = '';
  call : String = '';
  etmp : Extended = 0;
  stmp : String = '';
  i    : Integer = 0;
begin
  WebSpots.cti_vetu(spot,tmp,tmp,tmp,where);
  spot := copy(spot,i+6,Length(spot)-i-5);
  spot := Trim(spot);
  freq := GetFreq(spot);
  call := GetCall(spot,True);
  {
  Writeln('WebDbClick*****');
  Writeln('Spot:',spot);
  Writeln('Freq:',freq);
  Writeln('Call:',call);
  Writeln('***************');
  }
  if NOT TryStrToFloat(freq,etmp) then
    exit;
  if (not dmDXCluster.BandModFromFreq(freq,mode,stmp)) or (mode='') then
    exit;

  if dmData.ContestMode then
    frmTestMain.NewQSOFromSpot(call,freq,mode)
  else
    frmNewQSO.NewQSOFromSpot(call,freq,mode)
end;

procedure TfrmDXCluster.TelDbClick(where:longint;mb:TmouseButton;ms:TShiftState);
var
  spot : String = '';
  tmp  : Integer = 0;
  freq : String = '';
  mode : String = '';
  call : String = '';
  etmp : Extended = 0;
  stmp : String = '';
  i    : Integer = 0;
  f    : Currency;
begin
  TelSpots.cti_vetu(spot,tmp,tmp,tmp,where);
  if TryStrToCurr(copy(spot,1,Pos(' ',spot)-1),f)  then
  begin
    freq := copy(spot,1,Pos(' ',spot)-1);
    call := trim(copy(spot,Pos('.',spot)+2,14))
  end
  else begin
    spot := copy(spot,i+6,Length(spot)-i-5);
    spot := Trim(spot);
    freq := GetFreq(Spot);
    call := GetCall(Spot, ConWeb)
  end;
  {
  Writeln('TelDbClick*****');
  Writeln('Spot:',spot);
  Writeln('Freq:',freq);
  Writeln('Call:',call);
  Writeln('***************');
  }

  if NOT TryStrToFloat(freq,etmp) then
    exit;
  if (not dmDXCluster.BandModFromFreq(freq,mode,stmp)) or (mode='') then
    exit;
  if dmData.ContestMode then
    frmTestMain.NewQSOFromSpot(call,freq,mode)
  else
    frmNewQSO.NewQSOFromSpot(call,freq,mode)
end;


procedure TfrmDXCluster.FormShow(Sender: TObject);
var
  f : TFont;
begin
  f := TFont.Create;
  try
    f.Name    := cqrini.ReadString('DXCluster','Font','DejaVu Sans Mono');
    f.Size    := cqrini.ReadInteger('DXCluster','FontSize',12);
    ConOnShow := cqrini.ReadBool('DXCluster','ConAfterRun',False);
    WebSpots.nastav_font(f);
    TelSpots.nastav_font(f)
  finally
    f.Free
  end;
  dmUtils.LoadFontSettings(frmDXCluster);
  dmUtils.LoadWindowPos(frmDXCluster);
  pgDXCluster.ActivePageIndex :=  cqrini.ReadInteger('DXCluster','Tab',1);;
  telDesc := cqrini.ReadString('DXCluster','Desc','');
  telAddr := cqrini.ReadString('DXCluster','Addr','');
  telPort := cqrini.ReadString('DXCluster','Port','');
  telUser := cqrini.ReadString('DXCluster','User','');
  telPass := cqrini.ReadString('DXCluster','Pass','');
  edtTelAddress.Text := telDesc
end;

procedure TfrmDXCluster.btnClearClick(Sender: TObject);
begin
  WebSpots.smaz_vse;
end;

procedure TfrmDXCluster.btnFontClick(Sender: TObject);
begin
  dlgDXfnt.Font.Name := cqrini.ReadString('DXCluster','Font','DejaVu Sans Mono');
  dlgDXfnt.Font.Size := cqrini.ReadInteger('DXCluster','FontSize',12);
  if dlgDXfnt.Execute then
  begin
    cqrini.WriteString('DXCluster','Font',dlgDXfnt.Font.Name);
    cqrini.WriteInteger('DXCluster','FontSize',dlgDXfnt.Font.Size);
    WebSpots.nastav_font(dlgDXfnt.Font);
    TelSpots.nastav_font(dlgDXfnt.Font)
  end
end;

procedure TfrmDXCluster.btnSelectClick(Sender: TObject);
begin
  frmDXClusterList := TfrmDXClusterList.Create(self);
  try
    frmDXClusterList.OldDesc := edtTelAddress.Text;
    frmDXClusterList.ShowModal;
    if frmDXClusterList.ModalResult = mrOK then
    begin
      telDesc            := dmData.qDXClusters.Fields[1].AsString;
      telAddr            := dmData.qDXClusters.Fields[2].AsString;
      telPort            := dmData.qDXClusters.Fields[3].AsString;
      telUser            := dmData.qDXClusters.Fields[4].AsString;
      telPass            := dmData.qDXClusters.Fields[5].AsString;
      edtTelAddress.Text := telDesc;
      SavePosition
    end
  finally
    frmDXClusterList.Free
  end
end;

procedure TfrmDXCluster.btnTelConnectClick(Sender: TObject);
begin
  if ConWeb then
  begin
    Application.MessageBox('You are connected to web, you must disconnect it before connect to telnet.',
                            'Info ...',mb_ok + mb_IconInformation);
    exit
  end;

  if ConTelnet then
  begin
    StopAllConnections;
    btnTelConnect.Caption := 'Connect';
    ConWeb := False
  end
  else begin
    ConnectToTelnet;
    btnTelConnect.Caption := 'Disconnect';
    ConTelnet := True;
    edtCommand.SetFocus;
  end;
end;

procedure TfrmDXCluster.btnWebConnectClick(Sender: TObject);
begin
  if ConTelnet then
  begin
    Application.MessageBox('You are connected with telnet, you must disconnect it before connect to web cluster.',
                            'Info ...',mb_ok + mb_IconInformation);
    exit
  end;

  if ConWeb then
  begin
    StopAllConnections;
    btnWebConnect.Caption := 'Connect';
    ConWeb := False
  end
  else begin
    ConnectToWeb;
    btnWebConnect.Caption := 'Disconnect';
    ConWeb := True;
  end;
end;

procedure TfrmDXCluster.edtCommandKeyPress(Sender: TObject; var Key: char);
begin
  if key=#13 then
  begin
    key := #0;
   SendCommand(edtCommand.Text);
   edtCommand.Clear
  end;
end;

procedure TfrmDXCluster.lConnect(aSocket: TLSocket);
begin
  btnTelConnect.Caption := 'Disconnect';
  ConTelnet := True;
  edtCommand.SetFocus
end;

procedure TfrmDXCluster.lDisconnect(aSocket: TLSocket);
begin
  btnTelConnect.Caption := 'Connect';
  ConTelnet := False
end;

procedure TfrmDXCluster.lReceive(aSocket: TLSocket);
const
  CR = #13;
  LF = #10;
var
  sStart, sStop: Integer;
  tmp : String;
  itmp : Integer;
  buffer : String;
  f : Double;
begin
  if lTelnet.GetMessage(buffer) = 0 then
    exit;
  sStart := 1;
  sStop := Pos(CR, Buffer);
  if sStop = 0 then
    sStop := Length(Buffer) + 1;
  while sStart <= Length(Buffer) do
  begin
    tmp  := Copy(Buffer, sStart, sStop - sStart);
    tmp  := trim(tmp);
    if dmData.DebugLevel >=1 then Writeln(tmp);
    itmp := Pos('DX DE',UpperCase(tmp));
    if (itmp > 0) or TryStrToFloat(copy(tmp,1,Pos(' ',tmp)-1),f)  then
    begin
      EnterCriticalsection(frmDXCluster.csTelnet);
      if dmData.DebugLevel>=1 then Writeln('Enter critical section On Receive');
      try
        Spots.Add(tmp)
      finally
        LeaveCriticalsection(csTelnet);
        if dmData.DebugLevel>=1 then Writeln('Leave critical section On Receive')
      end
    end
    else begin
      if (Pos('LOGIN',UpperCase(tmp)) > 0) and (telUser <> '') then
        lTelnet.SendMessage(telUser+#13+#10);
      if (Pos('please enter your call:',LowerCase(tmp)) > 0) and (telUser <> '') then
        lTelnet.SendMessage(telUser+#13+#10);
      if (Pos('PASSWORD',UpperCase(tmp)) > 0) and (telPass <> '') then
        lTelnet.SendMessage(telPass+#13+#10);
      TelSpots.pridej_vetu(tmp,clBlack,clWhite,0)
    end;
    sStart := sStop + 1;
    if sStart > Length(Buffer) then
      Break;
    if Buffer[sStart] = LF then
      sStart := sStart + 1;
    sStop := sStart;
    while (Buffer[sStop] <> CR) and (sStop <= Length(Buffer)) do
      sStop := sStop + 1
  end;
  lTelnet.CallAction
end;

procedure TfrmDXCluster.SendCommand(cmd : String);
begin
  if lTelnet.Connected then
  begin
    lTelnet.SendMessage(cmd + #13#10);
    TelSpots.pridej_vetu(cmd,clBlack,clWhite,0)
  end
end;

procedure TfrmDXCluster.tmrSpotsTimer(Sender: TObject);
begin
  if pgDXCluster.ActivePageIndex = 0 then
    ConnectToWeb;
end;

function TfrmDXCluster.GetFreq(spot : String) : String;
var
  tmp : String;
begin
  tmp    := copy(spot,Pos(' ',spot),Pos('.',spot)+2 - Pos(' ',spot));
  Result := trim(tmp)
end;

function TfrmDXCluster.GetSplit(spot : String) : String;
var
  tmp : String;
  spl : String;
  spn : String;
  l : Integer;
begin
  tmp := copy(spot,34,Length(spot)-34);
  //Writeln('tmp: ',tmp);
  if Pos('UP',tmp)>0 then begin
    spl:= copy(tmp,Pos('UP',tmp),13);
    spn:='UP';
    for l:=3 to Length(spl) do
       if Pos(spl[l],' 0123456789.,-+')>0 then
           spn:=spn+spl[l]
        else break;
    end;
  if Pos('DOWN',tmp)>0 then begin
    spl:= copy(tmp,Pos('DOWN',tmp),13);
    spn:='DOWN';
    for l:=5 to Length(spl) do
       if Pos(spl[l],' 0123456789.,-+')>0 then
           spn:=spn+spl[l]
        else break;
    end;
  if Pos('QSX',tmp)>0 then begin
    spl:= copy(tmp,Pos('QSX',tmp),13);
    spn:='QSX';
    for l:=4 to Length(spl) do
       if Pos(spl[l],' 0123456789.,-+')>0 then
           spn:=spn+spl[l]
        else break;
    end;
  Result := trim(spn)
end;

function TfrmDXCluster.GetCall(spot : String; web : Boolean = False) : String;
var
  tmp : String='';
begin
  //these all horrible lines because of bug in dxsummit.fi cluster
  if web then
  begin
    //Writeln('spot:',spot);
    tmp    := trim(copy(spot,Pos(' ',spot)+1, Length(spot) -(Pos(' ',spot))));
    //Writeln('tmp: ',tmp);
    tmp    := copy(tmp,Pos(' ',tmp)+1, Length(tmp) -(Pos(' ',tmp)));
    //Writeln('tmp: ',tmp);
    if Pos(' ',tmp) > 0 then
      tmp    := trim(copy(tmp,1,Pos(' ',tmp)));
    //Writeln('tmp: ',tmp);
  end
  else begin
    tmp    := copy(spot,Pos('.',spot)+2,Length(spot)-Pos('.',spot)-1);
    tmp    := trim(tmp);
    tmp    := trim(copy(tmp,1,Pos(' ',tmp)))
  end;
  Result := tmp
end;

procedure TfrmDXCluster.StopAllConnections;
begin
  if ConWeb then
    tmrSpots.Enabled := False;
  if ConTelnet then
  begin
    if lTelnet.Connected then
      lTelnet.Disconnect;
    ConTelnet := False;
  end;
end;

function TfrmDXCluster.ShowSpot(spot : String; var sColor : Integer; var Country : String) : Boolean;
var
  kmitocet : Extended = 0.0;
  call     : String  = '';
  freq     : String  = '';
  tmp      : Integer = 0;
  band     : String  = '';
  mode     : String  = '';
  seznam   : TStringList;
  i        : Integer = 0;
  prefix   : String  = '';
  index    : Integer = 0;
  stmp     : String = '';
  waz      : String = '';
  itu      : String = '';
  cont     : String = '';
  ToBandMap : Boolean = False;
  wDXCC    : String = '';
  wWAZ     : String = '';
  wITU     : String = '';
  iDXCC    : String = '';
  iWAZ     : String = '';
  iITU     : String = '';
  lat      : String = '';
  long     : String = '';
  adif     : Word   = 0;
  f        : Currency;
  kHz      : String;
  splitstr : String;
begin
  sColor  := 0; //cerna

  spot := UpperCase(spot);
  i := Pos('DX DE ',spot);
  if i > 0 then
    spot := copy(spot,i+6,Length(spot)-i-5);

  if TryStrToCurr(copy(spot,1,Pos(' ',spot)-1),f)  then
  begin
    freq := copy(spot,1,Pos(' ',spot)-1);
    call := trim(copy(spot,Pos('.',spot)+2,14))
  end
  else begin
    freq     := GetFreq(Spot);
    call     := GetCall(Spot, ConWeb)
  end;

  splitstr := GetSplit(Spot);

  kHz := Freq;

  Writeln('Freq:',freq);
  Writeln('Call:',call);
  Writeln('Split:',splitstr);

  tmp := Pos('.',freq);
  if tmp > 0 then
    freq[tmp] := DecimalSeparator;
  tmp := Pos(',',freq);
  if tmp > 0 then
    freq[tmp] := DecimalSeparator;

  if cqrini.ReadBool('LoTW','UseBackColor',True) then
  begin
    if dmDXCluster.UsesLotw(call) then
      ThBckColor := cqrini.ReadInteger('LoTW','BckColor',clMoneyGreen)
    else
      ThBckColor := clWhite
  end;

  if ThBckColor = clWhite then
  begin
    if cqrini.ReadBool('LoTW','eUseBackColor',True) then
      if dmDXCluster.UseseQSL(call) then
        ThBckColor := cqrini.ReadInteger('LoTW','eBckColor',clSkyBlue)
  end;

  if not TryStrToFloat(freq,kmitocet) then
  begin
    Result := False;
    exit
  end;
  if (not dmDXCluster.BandModFromFreq(freq,mode,band)) or (mode='') then
  begin
    Result := False;
    if dmData.DebugLevel >=1 then
      Writeln('Cannot find out mode from frequency, exiting ...');
    exit
  end;
  if band = '' then
  begin
    Result := False;
    if dmData.DebugLevel >=1 then
      Writeln('Wrong band, exiting ...');
    exit
  end;
  freq    := FloatToStr(kmitocet/1000);
  adif    := dmDXCluster.id_country(call,now,prefix,stmp,waz,itu,cont,lat,long);
  prefix  := dmDXCluster.PfxFromADIF(adif);
  Country := dmDXCluster.CountryFromADIF(adif);
  dmDXCluster.DXCCInfo(adif,freq,mode,index);
  if dmData.DebugLevel>=1 then
  begin
    Writeln('dx_prefix:',prefix);
    Writeln('dx_cont:  ',cont);
    Writeln('Freq:     ',freq);
    Writeln('Call:     ',call);
  end;
  if dmData.DebugLevel >=2 then
  begin
    Writeln('Prefix: ',prefix);
    WriteLn('index_: ',index);
  end;
  if dmData.DebugLevel >=1 then
  begin
    Writeln('Color: ',ColorToString(sColor));
    Writeln('Index_: ',index);
  end;

  if dmData.ContestMode then
  begin
    Result := True;
    sColor := clBlack;
    dmDXCluster.AddToMarkFile(prefix,call,clWhite,cqrini.ReadString('xplanet','LastSpots','20'),lat,long);
    frmBandMap.AddFromDXCluster(call,mode,prefix,band,lat,long,kmitocet, clBlack,clWhite,splitstr);
    exit
  end;
  cont := UpperCase(cont);
  Result := True;
  wDXCC := cqrini.ReadString('BandMap','wDXCC','*');
  iDXCC := cqrini.ReadString('BandMap','iDXCC','');
  wWAZ  := cqrini.ReadString('BandMap','wWAZ','*');
  iWAZ  := cqrini.ReadString('BandMap','iWAZ','');
  wITU  := cqrini.ReadString('BandMap','wITU','*');
  iITU  := cqrini.ReadString('BandMap','iITU','');

  if Pos('.',band) > 0 then
    stmp := StringReplace(band,'.','',[rfReplaceAll, rfIgnoreCase])
  else
    stmp := band;
  if not cqrini.ReadBool('DXCluster','Show'+stmp,True) then
  begin
    Result := false;
    if dmData.DebugLevel >=1 then
      Writeln('Cannot show this sport because of settings ...');
    exit
  end;

  if not (cqrini.ReadBool('DXCluster','CW',true)) then
  begin
    if (mode='CW') then
      Result := False
  end;

  if not (cqrini.ReadBool('DXCluster','SSB',True))  then
  begin
    if (mode='SSB') then
      Result := false
  end;

  if (result = False) then
    exit;

  if wDXCC = '*' then
  begin
    if Pos(prefix+';',iDXCC) = 0 then
      ToBandMap := True
    else
      ToBandMap := False
  end;
  if iDXCC = '*' then
  begin
    if Pos(prefix+';',wDXCC) > 0 then
      ToBandMap := True
    else
      ToBandMap := False
  end;
  if wWAZ = '*' then
  begin
    if Pos(waz+';',iWAZ) = 0 then
      ToBandMap := True
    else
      ToBandMap := False
  end;
  if iWAZ = '*' then
  begin
    if Pos(waz+';',wWAZ) > 0 then
      ToBandMap := True
    else
      ToBandMap := False
  end;
  if wITU = '*' then
  begin
    if Pos(itu+';',iITU) = 0 then
      ToBandMap := True
    else
      ToBandMap := False
  end;
  if iITU = '*' then
  begin
    if Pos(itu+';',wITU) > 0 then
      ToBandMap := True
    else
      ToBandMap := False
  end;
  if (cont='EU') and (cqrini.ReadBool('BandMap','wEU',True)) then
    ToBandMap := True
  else  begin
    if (cont='AS') and (cqrini.ReadBool('BandMap','wAS',True)) then
      ToBandMap := True
    else begin
      if (cont='NA') and (cqrini.ReadBool('BandMap','wNA',True)) then
        ToBandMap := True
      else begin
        if (cont='SA') and (cqrini.ReadBool('BandMap','wSA',True)) then
          ToBandMap := True
        else begin
          if (cont='AF') and (cqrini.ReadBool('BandMap','wAF',True)) then
            ToBandMap := True
          else begin
            if (cont='OC') and (cqrini.ReadBool('BandMap','wOC',True)) then
              ToBandMap := True
            else begin
              if (cont='AN') and (cqrini.ReadBool('BandMap','wAN',True)) then
                ToBandMap := True
              else
                ToBandMap := False
            end;
          end;
        end;
      end;
    end;
  end;

  if Pos(prefix+';',cqrini.ReadString('BandMap','iDXCC','')+';') > 0 then
    ToBandMap := False;
  if not ToBandMap then
  begin
    if cqrini.ReadBool('BandMap','wIOTA', True) then
    begin
      if dmUtils.IsItIOTA(spot) then
       ToBandMap := True
    end
  end;
  if index = 0 then
    sColor := 0;
  if index = 1 then
    sColor := cqrini.ReadInteger('DXCluster','NewCountry',0);
  if index = 2 then
    sColor := cqrini.ReadInteger('DXCluster','NewBand',0);
  if index = 3 then
    sColor := cqrini.ReadInteger('DXCluster','NewMode',0);
  if index = 4 then
    sColor := cqrini.ReadInteger('DXCluster','NeedQSL',0);

  if (cont='') or (prefix='') then
    ToBandMap := True; //for MM stations etc.

  if cqrini.ReadInteger('xplanet','ShowFrom',0) = 0 then
  begin
    dmDXCluster.AddToMarkFile(prefix,call,sColor,cqrini.ReadString('xplanet','LastSpots','20'),lat,long)
  end;

  if dmUtils.IgnoreFreq(kHz) and cqrini.ReadBool('BandMap','IgnoreBandFreq',True) then
  begin
    if dmData.DebugLevel >=1 then Writeln('This freq: ',freq,' is ignored');
    ToBandMap := False
  end;

  if ToBandMap and frmBandMap.Showing then
  begin
    if cqrini.ReadBool('BandMap','UseDXCColors',False) then
      frmBandMap.AddFromDXCluster(call,mode,prefix,band,lat,long,kmitocet, sColor, ThBckColor,splitstr)
    else
      frmBandMap.AddFromDXCluster(call,mode,prefix,band,lat,long,kmitocet,
                                  cqrini.ReadInteger('BandMap','ClusterColor',clBlack),ThBckColor,splitstr)
  end;

  if index > 0 then
  begin
    seznam := TStringList.Create;
    try
      seznam.Clear;
      seznam.Delimiter     := ';';
      seznam.DelimitedText := cqrini.ReadString('DXCluster','NotShow','');
      for i:=0 to seznam.Count-1 do
      begin
        if (prefix=seznam.Strings[i]) then
        begin
         Result:= False;
         if dmData.DebugLevel >=1 then
            Writeln('Cannot show this sport because of prefix  ...');
         Break;
         exit
        end
      end
    finally
      seznam.Free
    end
  end;

  if dmData.DebugLevel >=1 then
  begin
    Writeln('Color: ',ColorToString(sColor));
    Writeln('Index_: ',index)
  end
end;

procedure TTelThread.Execute;
var
  dx      : String;
  sColor  : TColor;
  Country : String;
begin
  while true do
  begin
    while Spots.Count > 0 do
    begin
      if dmData.DebugLevel>=2 then Writeln('TelThread.Execute - enter critical section ');
      EnterCriticalsection(frmDXCluster.csTelnet);
      try
        dx := dmUtils.MyTrim(spots.Strings[0]);
        spots.Delete(0)
      finally
        LeaveCriticalsection(frmDXCluster.csTelnet);
        if dmData.DebugLevel>=2 then Writeln('TelThread.Execute - leave critical section ');
      end;
      if dmData.DebugLevel >= 2 then Writeln('Spot: ',dx);
      if frmDXCluster.ShowSpot(dx,sColor, Country) then
      begin
        if cqrini.ReadBool('DXCluster','ShowDxcCountry',False) then
          ThSpot := dx + ' ' + Country
        else
          ThSpot := dx;
        ThColor   := sColor;
        ThInfo    := '';
        if dmData.DebugLevel>=2 then
        begin
          Writeln('Spot nr. ',mindex);
          WriteLn('ThSpot: ',ThSpot);
          Writeln('ThColor: ',ThColor)
        end;
        if dmData.DebugLevel>=1 then Writeln('TelThread.Execute - before Synchronize(@frmDXCluster.SynTelnet)');
        Synchronize(@frmDXCluster.SynTelnet);
        if dmData.DebugLevel>=1 then Writeln('TelThread.Execute - after Synchronize(@frmDXCluster.SynTelnet)')
      end
    end;
    sleep(500)
  end
end;

procedure TWebThread.Execute;
var
  i,tmp  : Integer;
  HTTP   : THTTPSend;
  sp     : TStringList;
begin
  if dmData.DebugLevel>=1 then
    Writeln('In TWebThread.Execute');
  FreeOnTerminate      := True;
  frmDXCluster.Running := True;
  HTTP   := THTTPSend.Create;
  sp     := TStringList.Create;
  try
    sp.Clear;
    ThInfo := 'Connecting ...';
    Synchronize(@frmDXCluster.SynWeb);
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');
    if not HTTP.HTTPMethod('GET','http://www.dxsummit.fi/text/Default.aspx') then
    begin
      frmDXCluster.StopAllConnections;
      frmDXCluster.btnWebConnect.Click;
      exit
    end;
    ThInfo := 'Downloading spots ...';
    Synchronize(@frmDXCluster.SynWeb);
    sp.LoadFromStream(HTTP.Document);
    tmp := Pos('<pre>',sp.Text);
    sp.Text := copy(sp.Text,tmp+5,Length(sp.Text)-tmp+5);
    tmp := Pos('</pre>',sp.Text);
    sp.Text := copy(sp.Text,1,tmp-1);
    Writeln(sp.Text);
    for i:=0 to sp.Count-1 do
    begin
      EnterCriticalsection(frmDXCluster.csTelnet);
      if dmData.DebugLevel>=1 then Writeln('Enter critical section TWebThread.Execute');
      try
        if dmData.DebugLevel>=1 then Writeln('Adding from web:',dmUtils.MyTrim('DX DE ' + sp.Strings[i]));
        Spots.Add(dmUtils.MyTrim('DX DE ' + sp.Strings[i]));
      finally
        LeaveCriticalsection(frmDXCluster.csTelnet);
        if dmData.DebugLevel>=1 then Writeln('Leave critical section TWebThread.Execute')
      end
    end
  finally
    ThInfo := '';
    Synchronize(@frmDXCluster.SynWeb);
    HTTP.Free;
    sp.Free;
    frmDXCluster.Running := False
  end
end;

procedure TfrmDXCluster.SavePosition;
begin
end;

procedure TfrmDXCluster.SynWeb;
begin
  lblInfo.Caption := ThInfo;
  {
  if ThSpot = '' then
    exit;
  Writeln('******************* Hledam:',ThSpot,'********');
  if WebSpots.hledej(ThSpot,1,True,True) = -1 then
  begin
    Writeln('*****************Nenasel:',ThSpot,'********');
    WebSpots.zakaz_kresleni(true);
    WebSpots.vloz_vetu(ThSpot,ThColor,clWhite,0,0);
    WebSpots.zakaz_kresleni(false);
    Sleep(200)
  end
  else
    Writeln('*****************Nenasel:',ThSpot,'********');
  }
end;

procedure TfrmDXCluster.SynTelnet;
begin
  //if dmData.DebugLevel>=1 then Writeln('TfrmDXCluster.SynTelnet - begin ');
  if ThSpot = '' then
    exit;
  //if dmData.DebugLevel>=1 then Writeln('TfrmDXCluster.SynTelnet - before MapToScreen');
  //frmBandMap.MapToScreen;
  //if dmData.DebugLevel>=1 then Writeln('TfrmDXCluster.SynTelnet - Before ]'yu
  if ConTelnet then
  begin
    TelSpots.zakaz_kresleni(true);
    TelSpots.pridej_vetu(ThSpot,ThColor,ThBckColor,0);
    TelSpots.zakaz_kresleni(false)
  end
  else begin
    if WebSpots.hledej(ThSpot,0,True,True) = -1 then
    begin
      WebSpots.zakaz_kresleni(true);
      WebSpots.vloz_vetu(ThSpot,ThColor,ThBckColor,0,0);
      WebSpots.zakaz_kresleni(false);
    end
  end;
  //if dmData.DebugLevel>=1 then Writeln('TfrmDXCluster.SynTelnet - before PridejVetu ');
  //if dmData.DebugLevel>=1 then Writeln('TfrmDXCluster.SynTelnet - after zakaz_kresleni');
  //Sleep(200)
end;

initialization
  {$I fDXCluster.lrs}

end.

                                 
