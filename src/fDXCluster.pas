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
  ExtCtrls, ComCtrls, StdCtrls, Buttons, httpsend, uColorMemo,
  db, lcltype, Menus, ActnList, Spin, dynlibs, lNetComponents, lnet;

type
  { TfrmDXCluster }

  TfrmDXCluster = class(TForm)
    acPreferences : TActionList;
    acFont : TAction;
    acCallAlert : TAction;
    acProgPref : TAction;
    acChatSize: TAction;
    btnClear: TButton;
    btnFont: TButton;
    btnHelp: TButton;
    btnSelect: TButton;
    btnTelConnect: TButton;
    btnWebConnect: TButton;
    Button1: TButton;
    Button2: TButton;
    btnPreferences : TButton;
    dlgDXfnt: TFontDialog;
    edtCommand: TEdit;
    edtTelAddress: TEdit;
    Label1: TLabel;
    lblInfo: TLabel;
    MenuItem1 : TMenuItem;
    MenuItem2 : TMenuItem;
    MenuItem3 : TMenuItem;
    MenuItem4 : TMenuItem;
    MenuItem5 : TMenuItem;
    MenuItem6: TMenuItem;
    mnuCallalert : TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    pnlChat: TPanel;
    Panel4: TPanel;
    pgDXCluster: TPageControl;
    pnlTelnet: TPanel;
    pnlWeb: TPanel;
    popPreferences : TPopupMenu;
    tabTelnet: TTabSheet;
    tabWeb: TTabSheet;
    tmrAutoConnect: TTimer;
    tmrSpots: TTimer;
    trChatSize: TTrackBar;
    procedure acCallAlertExecute(Sender : TObject);
    procedure acChatSizeExecute(Sender: TObject);
    procedure acFontExecute(Sender : TObject);
    procedure acProgPrefExecute(Sender : TObject);
    procedure Button2Click(Sender: TObject);
    procedure btnPreferencesClick(Sender : TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnSelectClick(Sender: TObject);
    procedure btnTelConnectClick(Sender: TObject);
    procedure btnWebConnectClick(Sender: TObject);
    procedure edtCommandKeyPress(Sender: TObject; var Key: char);
    procedure mnuCallalertClick(Sender : TObject);
   procedure tmrAutoConnectTimer(Sender: TObject);
    procedure tmrSpotsTimer(Sender: TObject);
    procedure trChatSizeChange(Sender: TObject);
    procedure trChatSizeClick(Sender: TObject);
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
    csDXCPref  : TRTLCriticalSection;
    ReloadDXCPref : Boolean;
    FirstWebGet : Boolean;

    gcfgUseBackColor : Boolean;
    gcfgBckColor : TColor;
    gcfgeUseBackColor : Boolean;
    gcfgeBckColor : TColor;
    gcfgiDXCC : String;
    gcfgwIOTA : Boolean;
    gcfgNewCountryColor : TColor;
    gcfgNewBandColor : TColor;
    gcfgNewModeColor : TColor;
    gcfgNeedQSLColor : TColor;
    gcfgShowFrom : Integer;
    gcfgLastSpots : String;
    gcfgIgnoreBandFreq : Boolean;
    gcfgUseDXCColors : Boolean;
    gcfgClusterColor : TColor;
    gcfgNotShow : String;
    gcfgCW : Boolean;
    gcfgSSB : Boolean;
    gcfgEU  : Boolean;
    gcfgAS  : Boolean;
    gcfgAF  : Boolean;
    gcfgNA  : Boolean;
    gcfgSA  : Boolean;
    gcfgAN  : Boolean;
    gcfgOC  : Boolean;
    gwDXCC    : String;
    gwWAZ     : String;
    gwITU     : String;
    giDXCC    : String;
    giWAZ     : String;
    giITU     : String;

    HistCmd      : array [0..4] of string;
    HistPtr      : integer;

    procedure WebDbClick(where:longint;mb:TmouseButton;ms:TShiftState);
    procedure TelDbClick(where:longint;mb:TmouseButton;ms:TShiftState);
    procedure ConnectToWeb;
    procedure ConnectToTelnet;
    procedure SynWeb;
    procedure SynTelnet;
    procedure SynChat;
    procedure lConnect(aSocket: TLSocket);
    procedure lDisconnect(aSocket: TLSocket);
    procedure lReceive(aSocket: TLSocket);
    procedure ChangeCallAlertCaption;

    function  ShowSpot(spot : String; var sColor : Integer; var Country : String; FromTelnet : Boolean = True) : Boolean;
    function  GetFreq(spot : String) : String;
    function  GetCall(spot : String; web : Boolean = False) : String;
    function  GetSplit(spot : String) :String;
    procedure StoreLastCmd(LastCmd:string);
    function  GetHistCmd:string;
  public
    ConWeb    : Boolean;
    ConTelnet : Boolean;
    csTelnet  : TRTLCriticalSection;

    procedure SendCommand(cmd : String);
    procedure StopAllConnections;
    procedure ReloadSettings;
  end;

  type
    TWebThread = class(TThread)
    protected
      BiggerFetch : Boolean;
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
  Chats        : TStringList;
  WebSpots     : TColorMemo;
  TelSpots     : TColorMemo;
  ChatSpots    : TColorMemo;
  mindex       : Integer;
  ThInfo       : String;
  ThSpot       : String;
  ThColor      : Integer;
  ThBckColor   : Integer;
  ThChat       : String;
  ChBckColor   : Integer;
  TelThread    : TTelThread;

implementation
{$R *.lfm}
{ TfrmDXCluster }

uses dUtils, fDXClusterList, dData, dDXCluster, fMain, fTRXControl, fNewQSO, fBandMap,
     uMyIni, fPreferences;

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
    begin
      WebThread := TWebThread.Create(True);
      WebThread.FreeOnTerminate := True
    end;
    WebThread.BiggerFetch := FirstWebGet;
    WebThread.Start;
    FirstWebGet := False
  end
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
  tmrSpots.Enabled := False;
end;
procedure TfrmDXCluster.StoreLastCmd(LastCmd:string);  //scroll &store last typed line

begin
  HistPtr:=4;
  Repeat
        Begin
         HistCmd[HistPtr] := HistCmd[HistPtr-1];
          if dmData.DebugLevel>=1 then writeln('[',HistPtr,']' ,HistCmd[HistPtr]);
         dec(HistPtr);
        end;
  until HistPtr = 0;
  HistCmd[HistPtr] := LastCmd;

  if dmData.DebugLevel>=1 then  writeln('[',HistPtr,']' ,HistCmd[HistPtr]);

end;
function TfrmDXCluster.GetHistCmd:string;  //return line that ptr points & inc ptr(go round if not empty);
begin
  Result:= HistCmd[HistPtr];
  if (HistPtr < 4) and ( HistCmd[HistPtr+1]<>'') then
     inc (HistPtr)
    else
     HistPtr:=0;
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
  Spots.Add('DX de AK7V-#:     7025.30  AC2K           CW    28 dB  27 WPM  CQ      0425Z');
  {
  if not Running then
  begin
    Writeln('aa');
    if TelThread = nil then
    begin
      Writeln('ab');
      TelThread := TTelThread.Create(True);
    end;
    Writeln('bb');
    TelThread.Start;
    Writeln('cc');
  end;
  }
end;

procedure TfrmDXCluster.btnPreferencesClick(Sender : TObject);
var
  p : TPoint;
begin
  mnuCallalert.Checked := cqrini.ReadBool('DXCluster', 'AlertEnabled', False);
  ChangeCallAlertCaption;

  p.x := 10;
  p.y := 10;
  p := btnPreferences.ClientToScreen(p);
  popPreferences.PopUp(p.x, p.y)
end;

procedure TfrmDXCluster.acProgPrefExecute(Sender : TObject);
begin
  frmNewQSO.acPreferences.Execute
end;

procedure TfrmDXCluster.acFontExecute(Sender : TObject);
begin
  dlgDXfnt.Font.Name := cqrini.ReadString('DXCluster','Font','DejaVu Sans Mono');
  dlgDXfnt.Font.Size := cqrini.ReadInteger('DXCluster','FontSize',12);
  if dlgDXfnt.Execute then
  begin
    cqrini.WriteString('DXCluster','Font',dlgDXfnt.Font.Name);
    cqrini.WriteInteger('DXCluster','FontSize',dlgDXfnt.Font.Size);
    WebSpots.SetFont(dlgDXfnt.Font);
    TelSpots.SetFont(dlgDXfnt.Font);
    ChatSpots.SetFont(dlgDXfnt.Font)
  end
end;

procedure TfrmDXCluster.acCallAlertExecute(Sender : TObject);
begin
  frmPreferences.btnAlertCallsignsClick(nil)
end;

procedure TfrmDXCluster.acChatSizeExecute(Sender: TObject);
begin
       trChatSize.Max :=   pnlTelnet.Height -20;
       trChatSize.Position := pnlChat.Height;
       trChatSize.Visible :=true;
       trChatSize.Cursor := crSizeWE;
       edtCommand.Visible := false;
       label1.Caption := 'ChatSize';
       if dmData.DebugLevel >=1 then Writeln('Chat sizing AC');
end;

procedure TfrmDXCluster.FormCreate(Sender: TObject);
begin
  InitCriticalSection(csTelnet);
  InitCriticalSection(csDXCPref);
  FirstShow := True;
  ConOnShow := False;
  FirstWebGet := True;
  lTelnet := TLTelnetClientComponent.Create(nil);
  ReloadDXCPref := True;

  lTelnet.OnConnect    := @lConnect;
  lTelnet.OnDisconnect := @lDisconnect;
  lTelnet.OnReceive    := @lReceive;

  WebSpots             := TColorMemo.Create(pnlWeb);
  WebSpots.parent      := pnlWeb;
  WebSpots.AutoScroll  := True;
  WebSpots.oncDblClick := @WebDbClick;
  WebSpots.Align       := alClient;
  WebSpots.setLanguage(1);


  TelSpots             := TColorMemo.Create(pnlTelnet);
  TelSpots.parent      := pnlTelnet;
  TelSpots.AutoScroll  := True;
  TelSpots.oncDblClick := @TelDbClick;
  TelSpots.Align       := alClient;
  TelSpots.setLanguage(1);

  ChBckColor  := $00D3F3F8;
  pnlChat.Color := ChBckColor;
  ChatSpots             := TColorMemo.Create(pnlChat);
  ChatSpots.parent      := pnlChat;
  ChatSpots.autoscroll  := True;
  ChatSpots.Align       := alClient;
  ChatSpots.setLanguage(1);

  Spots := TStringList.Create;
  Spots.Clear;
  Chats := TStringList.Create;
  Chats.Clear;

  Running := False;
  mindex  := 1;

  TelThread := TTelThread.Create(True);
  TelThread.FreeOnTerminate := True;
  TelThread.Start;
  HistPtr:=5;               //initialize command history to be clean
  repeat
        Begin
          dec(HistPtr);
          HistCmd[HistPtr]:=''
        end;
  until HistPtr =0;
end;

procedure TfrmDXCluster.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key= VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0
  end
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
  WebSpots.ReadLine(spot,tmp,tmp,tmp,where);
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
  if (not dmData.BandModFromFreq(freq,mode,stmp)) or (mode='') then
    exit;

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
  TelSpots.ReadLine(spot,tmp,tmp,tmp,where);
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
  if (not dmData.BandModFromFreq(freq,mode,stmp)) or (mode='') then
    exit;
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
    WebSpots.SetFont(f);
    TelSpots.SetFont(f) ;
    ChatSpots.SetFont(f)
  finally
    f.Free
  end;
  dmUtils.LoadFontSettings(frmDXCluster);
  dmUtils.LoadWindowPos(frmDXCluster);
  ReloadSettings;
  pgDXCluster.ActivePageIndex :=  cqrini.ReadInteger('DXCluster','Tab',1);;
  telDesc := cqrini.ReadString('DXCluster','Desc','');
  telAddr := cqrini.ReadString('DXCluster','Addr','');
  telPort := cqrini.ReadString('DXCluster','Port','');
  telUser := cqrini.ReadString('DXCluster','User','');
  telPass := cqrini.ReadString('DXCluster','Pass','');
  edtTelAddress.Text := telDesc;

  mnuCallalert.Checked := cqrini.ReadBool('DXCluster', 'AlertEnabled', False);
  ChangeCallAlertCaption;

  if cqrini.ReadBool('DXCluster', 'ConAfterRun', False) then
    tmrAutoConnect.Enabled := True;
  pnlChat.Height := cqrini.ReadInteger('DXCluster','ChatSize',2);  //default now 2 = invisible
end;

procedure TfrmDXCluster.btnClearClick(Sender: TObject);
begin
  WebSpots.RemoveAllLines
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
      edtTelAddress.Text := telDesc
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
    if (Sender <> nil) then
      edtCommand.SetFocus
  end
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
  if key=#26 then
  Begin
    key := #0;
    edtCommand.Clear;
    edtCommand.Text := GetHistCmd;
    edtCommand.SelStart := Length(edtCommand.Text);
  end;
  if key=#13 then
  begin
    StoreLastCmd(edtCommand.Text);
    key := #0;
   SendCommand(edtCommand.Text);
   edtCommand.Clear
  end;
end;

procedure TfrmDXCluster.mnuCallalertClick(Sender : TObject);
begin
  mnuCallalert.Checked := not mnuCallalert.Checked;
  cqrini.WriteBool('DXCluster', 'AlertEnabled', mnuCallalert.Checked);
  ChangeCallAlertCaption
end;

procedure TfrmDXCluster.tmrAutoConnectTimer(Sender: TObject);
begin
  tmrAutoConnect.Enabled := False;
  if pgDXCluster.ActivePageIndex = 0 then
  begin
    if not ConWeb then
      btnWebConnectClick(nil)
  end
  else begin
    if not ConTelnet then
      btnTelConnectClick(nil)
  end;
  frmNewQSO.ReturnToNewQSO
end;

procedure TfrmDXCluster.lConnect(aSocket: TLSocket);
begin
  btnTelConnect.Caption := 'Disconnect';
  ConTelnet := True
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
  tmp, Chline: String;
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

    if Pos(UpperCase(telUser) + ' DE', UpperCase(tmp)) > 0 then
      Begin
        ChLine := tmp;
        if dmData.DebugLevel>=1 then Writeln('pos: ', pos('>',Chline) ,' len:', length(Chline));
        if pos('>',Chline) < length(Chline) then //if not dxcluster prompt
         Begin //remove "mycall de" add local timestamp from PC
           itmp := length(telUser)+4; //4 = ' DE '
           ChLine := FormatDateTime('hh:nn',Now)+'_'+copy(Chline,itmp+1,length(Chline)-itmp);
           if dmData.DebugLevel>=1 then Writeln('Chat :',ChLine);
           EnterCriticalsection(frmDXCluster.csTelnet);
           if dmData.DebugLevel>=1 then Writeln('Enter critical section On Receive Chat');
           try
            Chats.Add(Chline);
           finally
            LeaveCriticalsection(csTelnet);
            if dmData.DebugLevel>=1 then Writeln('Leave critical section On Receive Chat')
           end
         end
        else
        Begin
          Chline := '';
          if dmData.DebugLevel>=1 then Writeln('Chat : line is cluster prompt!');
        end;
      end;

    itmp := Pos('DX DE',UpperCase(tmp));
    if (itmp > 0) or TryStrToFloat(copy(tmp,1,Pos(' ',tmp)-1),f)  then
    begin
      EnterCriticalsection(frmDXCluster.csTelnet);
      if dmData.DebugLevel>=1 then Writeln('Enter critical section On Receive');
      try
        Spots.Add(tmp);
        if Chline <> '' then Chats.Add(Chline);
      finally
        LeaveCriticalsection(csTelnet);
        if dmData.DebugLevel>=1 then Writeln('Leave critical section On Receive')
      end
    end
    else begin
      if (Pos('LOGIN',UpperCase(tmp)) > 0) and (telUser <> '') then
        lTelnet.SendMessage(telUser+#13+#10);
      if (Pos('please enter your call',LowerCase(tmp)) > 0) and (telUser <> '') then
        lTelnet.SendMessage(telUser+#13+#10);
      if (Pos('PASSWORD',UpperCase(tmp)) > 0) and (telPass <> '') then
        lTelnet.SendMessage(telPass+#13+#10);
      TelSpots.AddLine(tmp,clBlack,clWhite,0)
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
    TelSpots.AddLine(cmd,clBlack,clWhite,0)
  end
end;

procedure TfrmDXCluster.tmrSpotsTimer(Sender: TObject);
begin
  if pgDXCluster.ActivePageIndex = 0 then
    ConnectToWeb;
end;

procedure TfrmDXCluster.trChatSizeChange(Sender: TObject);
begin
     pnlChat.Height := trChatSize.Position;
end;

procedure TfrmDXCluster.trChatSizeClick(Sender: TObject);
begin
      trChatSize.Visible := false;
      trChatSize.Cursor :=  crDefault;
      edtCommand.Visible := true;
      label1.Caption := 'Command:';
      cqrini.WriteInteger('DXCluster','ChatSize',trChatSize.Position);
      pnlChat.Height := trChatSize.Position;
      if dmData.DebugLevel >=1 then Writeln('Chat sizing Click');
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
    tmp    := copy(spot,Pos('.',spot)+3,Length(spot)-Pos('.',spot)-1);
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

function TfrmDXCluster.ShowSpot(spot : String; var sColor : Integer; var Country : String; FromTelnet : Boolean = True) : Boolean;
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
  cLat, cLng : Currency;
  isLoTW : Boolean;
  isEQSL : Boolean;

  cfgUseBackColor : Boolean = True;
  cfgBckColor : TColor;
  cfgeUseBackColor : Boolean = True;
  cfgeBckColor : TColor;
  cfgiDXCC : String;
  cfgwIOTA : Boolean;
  cfgNewCountryColor : TColor;
  cfgNewBandColor : TColor;
  cfgNewModeColor : TColor;
  cfgNeedQSLColor : TColor;
  cfgShowFrom : Integer;
  cfgLastSpots : String;
  cfgIgnoreBandFreq : Boolean;
  cfgUseDXCColors : Boolean;
  cfgClusterColor : TColor;
  cfgNotShow : String;

  cfgCW : Boolean;
  cfgSSB : Boolean;
  cfgEU  : Boolean;
  cfgAS  : Boolean;
  cfgAF  : Boolean;
  cfgNA  : Boolean;
  cfgSA  : Boolean;
  cfgAN  : Boolean;
  cfgOC  : Boolean;
begin
  sColor  := 0; //cerna

  EnterCriticalSection(csDXCPref);
  try
    cfgUseBackColor  := gcfgUseBackColor;
    cfgBckColor      := gcfgBckColor;
    cfgeUseBackColor := gcfgeUseBackColor;
    cfgeBckColor     := gcfgeBckColor;
    wDXCC  := gwDXCC;
    iDXCC  := giDXCC;
    wWAZ   := gwWAZ;
    iWAZ   := giWAZ;
    wITU   := gwITU;
    iITU   := giITU;
    cfgCW  := gcfgCW;
    cfgSSB := gcfgSSB;
    cfgEU  := gcfgEU;
    cfgAS  := gcfgAS;
    cfgNA  := gcfgNA;
    cfgSA  := gcfgSA;
    cfgAF  := gcfgAF;
    cfgAN  := gcfgAN;
    cfgOC  := gcfgOC;
    cfgiDXCC := gcfgiDXCC;
    cfgwIOTA := gcfgwIOTA;
    cfgNewCountryColor := gcfgNewCountryColor;
    cfgNewBandColor := gcfgNewBandColor;
    cfgNewModeColor := gcfgNewModeColor;
    cfgNeedQSLColor := gcfgNeedQSLColor;
    cfgShowFrom     := gcfgShowFrom;
    cfgLastSpots    := gcfgLastSpots;
    cfgIgnoreBandFreq := gcfgIgnoreBandFreq;
    cfgUseDXCColors := gcfgUseDXCColors;
    cfgClusterColor := gcfgClusterColor;
    cfgNotShow := gcfgNotShow
  finally
    LeaveCriticalSection(csDXCPref)
  end;

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

  tmp := Pos('.',freq);
  if tmp > 0 then
    freq[tmp] := FormatSettings.DecimalSeparator;
  tmp := Pos(',',freq);
  if tmp > 0 then
    freq[tmp] := FormatSettings.DecimalSeparator;

  isLoTW := dmData.UsesLotw(call);
  isEQSL := dmDXCluster.UseseQSL(call);

  if cfgUseBackColor then
  begin
    if isLoTW then
      ThBckColor := cfgBckColor
    else
      ThBckColor := clWhite
  end;

  if ThBckColor = clWhite then
  begin
    if cfgeUseBackColor then
      if isEQSL then
        ThBckColor := cfgeBckColor
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
    Writeln('Call:     ',call)
  end;
  if dmData.DebugLevel >=2 then
  begin
    Writeln('Prefix: ',prefix);
    WriteLn('index_: ',index)
  end;
  if dmData.DebugLevel >=1 then
  begin
    Writeln('Color: ',ColorToString(sColor));
    Writeln('Index_: ',index)
  end;

  cont := UpperCase(cont);
  Result := True;

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

  if not cfgCW then
  begin
    if (mode='CW') then
      Result := False
  end;

  if not cfgSSB  then
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
  if (cont='EU') and cfgEU then
    ToBandMap := True
  else  begin
    if (cont='AS') and cfgAS then
      ToBandMap := True
    else begin
      if (cont='NA') and cfgNA then
        ToBandMap := True
      else begin
        if (cont='SA') and cfgSA then
          ToBandMap := True
        else begin
          if (cont='AF') and cfgAF then
            ToBandMap := True
          else begin
            if (cont='OC') and cfgOC then
              ToBandMap := True
            else begin
              if (cont='AN') and cfgAN then
                ToBandMap := True
              else
                ToBandMap := False
            end
          end
        end
      end
    end
  end;

  if Pos(prefix+';',cfgiDXCC+';') > 0 then
    ToBandMap := False;
  if not ToBandMap then
  begin
    if cfgwIOTA then
    begin
      if dmUtils.IsItIOTA(spot) then
       ToBandMap := True
    end
  end;
  if index = 0 then
    sColor := 0;
  if index = 1 then
    sColor := cfgNewCountryColor;
  if index = 2 then
    sColor := cfgNewBandColor;
  if index = 3 then
    sColor := cfgNewModeColor;
  if index = 4 then
    sColor := cfgNeedQSLColor;

  if (cont='') or (prefix='') then
    ToBandMap := True; //for MM stations etc.

  if cfgShowFrom = 0 then
  begin
    dmDXCluster.AddToMarkFile(prefix,call,sColor,cfgLastSpots,lat,long)
  end;

  if dmUtils.IgnoreFreq(kHz) and cfgIgnoreBandFreq then
  begin
    if dmData.DebugLevel >=1 then Writeln('This freq: ',freq,' is ignored');
    ToBandMap := False
  end;

  if index > 0 then
  begin
    seznam := TStringList.Create;
    try
      seznam.Clear;
      seznam.Delimiter     := ';';
      seznam.DelimitedText := cfgNotShow;
      for i:=0 to seznam.Count-1 do
      begin
        if (prefix=seznam.Strings[i]) then
        begin
         Result:= False;
         if dmData.DebugLevel >=1 then
            Writeln('Cannot show this sport because of prefix  ...');
         Break
        end
      end
    finally
      seznam.Free
    end
  end;

  if Result then
  begin
    if ToBandMap and frmBandMap.Showing then
    begin
      dmDXCluster.GetRealCoordinate(lat,long,cLat,cLng);

      if cfgUseDXCColors then
        frmBandMap.AddToBandMap(kmitocet,call,mode,band,splitstr,cLat,cLng,sColor,ThBckColor, False, isLoTW, isEQSL)
      else
        frmBandMap.AddToBandMap(kmitocet,call,mode,band,splitstr,cLat,cLng,
                                cfgClusterColor,ThBckColor, False, isLoTW, isEQSL)
    end
  end;

  if  mnuCallalert.Checked then // do not run IsAlertCall unless alert is selected
    if (dmDXCluster.IsAlertCall(call,band,mode,cqrini.ReadBool('DxCluster', 'AlertRegExp', False))) then
        dmDXCluster.RunCallAlertCmd(call,band,mode,freq);

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

    while Chats.Count > 0 do
    begin
      if dmData.DebugLevel>=2 then Writeln('TelThread.Execute - enter critical section Chat ');
      EnterCriticalsection(frmDXCluster.csTelnet);
      try
        ThChat := Trim(Chats.Strings[0]);
        Chats.Delete(0)
      finally
        LeaveCriticalsection(frmDXCluster.csTelnet);
        if dmData.DebugLevel>=2 then Writeln('TelThread.Execute - leave critical section Chat ');
      end;
      if dmData.DebugLevel >= 2 then Writeln('Chat: ',ThChat);
      if dmData.DebugLevel>=1 then Writeln('TelThread.Execute - before Synchronize(@frmDXCluster.SynChat)');
      Synchronize(@frmDXCluster.SynChat);
      if dmData.DebugLevel>=1 then Writeln('TelThread.Execute - after Synchronize(@frmDXCluster.SynChat)')
    end;

    sleep(500)
  end
end;

procedure TWebThread.Execute;

  function SpacesFromLeft(What : String; TargetLen : Integer) : String;
  var
    n : Integer;
    i : Integer;
  begin
    Result := What;
    n := TargetLen - Length(what);
    if n < 0 then
      Result := copy(What,1,abs(n))
    else begin
      for i:=Length(What) to TargetLen do
      begin
        Result := ' '+Result;
        //Writeln(Result)
      end
    end
  end;

  function SpacesFromRight(What : String; TargetLen : Integer) : String;
  var
    n : Integer;
    i : Integer;
  begin
    Result := What;
    n := TargetLen - Length(what);
    if n < 0 then
      Result := copy(What,1,abs(n))
    else begin
      for i:=Length(What) to TargetLen do
      begin
        Result := Result+' ';
        //Writeln(Result+'*')
      end
    end
  end;

  function  Explode(const cSeparator, vString: String): TExplodeArray;
  var
    i: integer;
    S: string;
  begin
    S := vString;
    SetLength(Result, 0);
    i := 0;
    while Pos(cSeparator, S) > 0 do
    begin
      SetLength(Result, Length(Result) + 1);
      Result[i] := Copy(S, 1, Pos(cSeparator, S) - 1);
      Inc(i);
      S := Copy(S, Pos(cSeparator, S) + Length(cSeparator), Length(S))
    end;
    SetLength(Result, Length(Result) + 1);
    Result[i] := Copy(S, 1, Length(S))
  end;

var
  i,tmp   : Integer;
  HTTP    : THTTPSend;
  sp      : TStringList;
  spot    : String;
  a       : TExplodeArray;
  sColor  : TColor;
  Country : String;
  x       : String;
  limit   : String;
begin
  if dmData.DebugLevel>=1 then
    Writeln('In TWebThread.Execute');
  FreeOnTerminate      := True;
  frmDXCluster.Running := True;
  HTTP   := THTTPSend.Create;
  sp     := TStringList.Create;
  try
    if BiggerFetch then
      limit := '60'
    else
      limit := '20';
    sp.Clear;
    ThInfo := 'Connecting ...';
    Synchronize(@frmDXCluster.SynWeb);
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');
    if not HTTP.HTTPMethod('GET','http://www.hamqth.com/dxc_csv.php?limit='+limit) then
    begin
      frmDXCluster.StopAllConnections;
      frmDXCluster.btnWebConnect.Click;
      exit
    end;
    ThInfo := 'Downloading spots ...';
    Synchronize(@frmDXCluster.SynWeb);
    sp.LoadFromStream(HTTP.Document);
    for i:=0 to sp.Count-1 do
    begin
      EnterCriticalsection(frmDXCluster.csTelnet);
      if dmData.DebugLevel>=1 then Writeln('Enter critical section TWebThread.Execute');
      try
        a := Explode('^',sp.Strings[i]);
        if Length(a) < 3 then
          Continue;
        spot :=  SpacesFromRight('DX de '+a[0]+':',13)+ //spotter
                 SpacesFromLeft(a[1],8)+ ' '+  //freq
                 SpacesFromRight(a[2],12)+ ' ' + //dxcall
                 SpacesFromRight(a[3],28)+ ' ' + //comment
                 copy(a[4],1,4)+'Z';
        {
        Writeln(SpacesFromRight('DX de '+a[0]+':',14),'|',Length(SpacesFromRight('DX de '+a[0]+':',14)));
        Writeln(SpacesFromLeft(a[1],9),'|',Length(SpacesFromLeft(a[1],9)));
        Writeln(SpacesFromRight(a[2],13),'|',Length(SpacesFromRight(a[2],13)));
        Writeln(SpacesFromRight(a[3],29),'|',Length(SpacesFromRight(a[3],29)));
        Writeln(copy(a[4],1,4)+'Z','|',Length(copy(a[4],1,4)+'Z'));
        }
        if dmData.DebugLevel>=1 then Writeln('Adding from web:',spot);
        if frmDXCluster.ShowSpot(spot,sColor, Country) then
        begin
          if cqrini.ReadBool('DXCluster','ShowDxcCountry',False) then
            ThSpot := spot + ' ' + Country
          else
            ThSpot := spot;
          ThColor   := sColor;
          ThInfo    := '';
          Synchronize(@frmDXCluster.SynWeb)
        end
      finally
        LeaveCriticalsection(frmDXCluster.csTelnet);
        if dmData.DebugLevel>=1 then Writeln('Leave critical section TWebThread.Execute')
      end
    end
  finally
    ThInfo := '';
    HTTP.Free;
    sp.Free;
    frmDXCluster.Running := False
  end
end;

procedure TfrmDXCluster.SynWeb;
begin
  lblInfo.Caption := ThInfo;
  if WebSpots.Search(ThSpot,0,True,True) = -1 then
  begin
    WebSpots.DisableAutoRepaint(true);
    WebSpots.AddLine(ThSpot,ThColor,ThBckColor,0);
    WebSpots.DisableAutoRepaint(false)
  end
  {
  if ThSpot = '' then
    exit;
  Writeln('******************* Hledam:',ThSpot,'********');
  if WebSpots.Search(ThSpot,1,True,True) = -1 then
  begin
    Writeln('*****************Nenasel:',ThSpot,'********');
    WebSpots.DisableAutoRepaint(true);
    WebSpots.vloz_vetu(ThSpot,ThColor,clWhite,0,0);
    WebSpots.DisableAutoRepaint(false);
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
    TelSpots.DisableAutoRepaint(true);
    TelSpots.AddLine(ThSpot,ThColor,ThBckColor,0);
    TelSpots.DisableAutoRepaint(false)
  end
  else begin
    {
    if WebSpots.Search(ThSpot,0,True,True) = -1 then
    begin
      WebSpots.DisableAutoRepaint(true);
      WebSpots.vloz_vetu(ThSpot,ThColor,ThBckColor,0,0);
      WebSpots.DisableAutoRepaint(false);
    end
    }
  end;
  //if dmData.DebugLevel>=1 then Writeln('TfrmDXCluster.SynTelnet - before PridejVetu ');
  //if dmData.DebugLevel>=1 then Writeln('TfrmDXCluster.SynTelnet - after zakaz_kresleni');
  //Sleep(200)
end;
procedure TfrmDXCluster.SynChat;
begin

  if ThChat = '' then
    exit;

  if ConTelnet then
  begin
    ChatSpots.DisableAutoRepaint(true);
    ChatSpots.AddLine(ThChat,clBlack,ChBckColor,0);
    ChatSpots.DisableAutoRepaint(false)
  end;
end;

procedure TfrmDXCluster.ReloadSettings;
begin
  EnterCriticalSection(csDXCPref);
  try
    gcfgUseBackColor  := cqrini.ReadBool('LoTW','UseBackColor',True);
    gcfgBckColor      := cqrini.ReadInteger('LoTW','BckColor',clMoneyGreen);
    gcfgeUseBackColor := cqrini.ReadBool('LoTW','eUseBackColor',True);
    gcfgeBckColor     := cqrini.ReadInteger('LoTW','eBckColor',clSkyBlue);
    gwDXCC  := cqrini.ReadString('BandMap','wDXCC','*');
    giDXCC  := cqrini.ReadString('BandMap','iDXCC','');
    gwWAZ   := cqrini.ReadString('BandMap','wWAZ','*');
    giWAZ   := cqrini.ReadString('BandMap','iWAZ','');
    gwITU   := cqrini.ReadString('BandMap','wITU','*');
    giITU   := cqrini.ReadString('BandMap','iITU','');
    gcfgCW  := cqrini.ReadBool('DXCluster','CW',true);
    gcfgSSB := cqrini.ReadBool('DXCluster','SSB',True);
    gcfgEU  := cqrini.ReadBool('BandMap','wEU',True);
    gcfgAS  := cqrini.ReadBool('BandMap','wAS',True);
    gcfgNA  := cqrini.ReadBool('BandMap','wNA',True);
    gcfgSA  := cqrini.ReadBool('BandMap','wSA',True);
    gcfgAF  := cqrini.ReadBool('BandMap','wAF',True);
    gcfgAN  := cqrini.ReadBool('BandMap','wAN',True);
    gcfgOC  := cqrini.ReadBool('BandMap','wOC',True);
    gcfgiDXCC := cqrini.ReadString('BandMap','iDXCC','');
    gcfgwIOTA := cqrini.ReadBool('BandMap','wIOTA', True);
    gcfgNewCountryColor := cqrini.ReadInteger('DXCluster','NewCountry',0);
    gcfgNewBandColor := cqrini.ReadInteger('DXCluster','NewBand',0);
    gcfgNewModeColor := cqrini.ReadInteger('DXCluster','NewMode',0);
    gcfgNeedQSLColor := cqrini.ReadInteger('DXCluster','NeedQSL',0);
    gcfgShowFrom     := cqrini.ReadInteger('xplanet','ShowFrom',0);
    gcfgLastSpots    := cqrini.ReadString('xplanet','LastSpots','20');
    gcfgIgnoreBandFreq := cqrini.ReadBool('BandMap','IgnoreBandFreq',True);
    gcfgUseDXCColors := cqrini.ReadBool('BandMap','UseDXCColors',False);
    gcfgClusterColor := cqrini.ReadInteger('BandMap','ClusterColor',clBlack);
    gcfgNotShow := cqrini.ReadString('DXCluster','NotShow','')
  finally
    LeaveCriticalSection(csDXCPref)
  end
end;

procedure TfrmDXCluster.ChangeCallAlertCaption;
begin
  if mnuCallalert.Checked then
    mnuCallalert.Caption := 'Callsign alert enabled'
  else
    mnuCallalert.Caption := 'Enable callsign alert'
end;

end.

                                 
