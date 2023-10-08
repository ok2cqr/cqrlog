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
  db, lcltype, Menus, ActnList, Spin, Grids, dynlibs, lNetComponents, lnet;

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
    edtF1: TEdit;
    edtF10: TEdit;
    edtF2: TEdit;
    edtF3: TEdit;
    edtF4: TEdit;
    edtF5: TEdit;
    edtF6: TEdit;
    edtF7: TEdit;
    edtF8: TEdit;
    edtF9: TEdit;
    edtTelAddress: TEdit;
    Label1: TLabel;
    lblShift: TLabel;
    lblF1: TLabel;
    lblF10: TLabel;
    lblF2: TLabel;
    lblF3: TLabel;
    lblF4: TLabel;
    lblF5: TLabel;
    lblF6: TLabel;
    lblF7: TLabel;
    lblF8: TLabel;
    lblF9: TLabel;
    lblInfo: TLabel;
    MenuItem1 : TMenuItem;
    mnuSkimQSLCheck: TMenuItem;
    MenuItem2 : TMenuItem;
    MenuItem3 : TMenuItem;
    MenuItem4 : TMenuItem;
    MenuItem5 : TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    mnuSkimAllowFreq: TMenuItem;
    mnuCallalert : TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    pnlChat: TPanel;
    Panel4: TPanel;
    pgDXCluster: TPageControl;
    pnlTelnet: TPanel;
    pnlWeb: TPanel;
    popPreferences : TPopupMenu;
    tabFkeys: TTabSheet;
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
    procedure edtF2Exit(Sender: TObject);
    procedure edtFExit(Sender: TObject);
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
    procedure mnuSkimAllowFreqClick(Sender: TObject);
    procedure mnuSkimQSLCheckClick(Sender: TObject);
    procedure tabFkeysShow(Sender: TObject);
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
    gcfgDATA: Boolean;
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
    procedure SpotDbClick(Spot:String);
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
    function  GetSplit(info : String) :String;
    procedure StoreLastCmd(LastCmd:string);
    function  GetHistCmd:string;
    function  FontStylesToString(Styles: TFontStyles): string;
    function  StringToFontStyles(const Styles: string): TFontStyles;
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
  SentStartCmd : Boolean;

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

procedure TfrmDXCluster.Button2Click(Sender: TObject);  //this is debugger
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
  mnuSkimAllowFreq.Checked := cqrini.ReadBool('Skimmer', 'AllowFreqEnable', False);
  mnuSkimQSLCheck.Checked := cqrini.ReadBool('Skimmer', 'QSLEnable', False);
  ChangeCallAlertCaption;
  p.x := 10;
  p.y := 10;
  p := btnPreferences.ClientToScreen(p);
  popPreferences.PopUp(p.x, p.y)
end;

procedure TfrmDXCluster.edtF2Exit(Sender: TObject);
begin

end;

procedure TfrmDXCluster.edtFExit(Sender: TObject);
begin
   cqrini.WriteString('DXCluster','F1key',edtF1.Text);
   cqrini.WriteString('DXCluster','F2key',edtF2.Text);
   cqrini.WriteString('DXCluster','F3key',edtF3.Text);
   cqrini.WriteString('DXCluster','F4key',edtF4.Text);
   cqrini.WriteString('DXCluster','F5key',edtF5.Text);
   cqrini.WriteString('DXCluster','F6key',edtF6.Text);
   cqrini.WriteString('DXCluster','F7key',edtF7.Text);
   cqrini.WriteString('DXCluster','F8key',edtF8.Text);
   cqrini.WriteString('DXCluster','F9key',edtF9.Text);
   cqrini.WriteString('DXCluster','F10key',edtF10.Text);
end;

procedure TfrmDXCluster.acProgPrefExecute(Sender : TObject);
begin
  cqrini.WriteInteger('Pref', 'ActPageIdx', 10);  //set DXCuster tab active. Number may change if preferences page change
  frmNewQSO.acPreferences.Execute
end;

procedure TfrmDXCluster.acFontExecute(Sender : TObject);
begin
  dlgDXfnt.Font.Name := cqrini.ReadString('DXCluster','Font','DejaVu Sans Mono');
  dlgDXfnt.Font.Style := StringToFontStyles(cqrini.ReadString('DXCluster','FontStyle',''));
  dlgDXfnt.Font.Size := cqrini.ReadInteger('DXCluster','FontSize',12);
  if dlgDXfnt.Execute then
  begin
    cqrini.WriteString('DXCluster','Font',dlgDXfnt.Font.Name);
    cqrini.WriteInteger('DXCluster','FontSize',dlgDXfnt.Font.Size);
    cqrini.WriteString('DXCluster','FontStyle',FontStylesToString(dlgDXfnt.Font.Style));
    WebSpots.SetFont(dlgDXfnt.Font);
    TelSpots.SetFont(dlgDXfnt.Font);
    ChatSpots.SetFont(dlgDXfnt.Font)
  end
end;
function TfrmDXCluster.FontStylesToString(Styles: TFontStyles): string;
begin
  Result := '';
  if fsBold in Styles then
    Result := Result + 'B';
  if fsItalic in Styles then
    Result := Result + 'I';
  if fsUnderline in Styles then
    Result := Result + 'U';
  if fsStrikeOut in Styles then
    Result := Result + 'S';
end;

function TfrmDXCluster.StringToFontStyles(const Styles: string): TFontStyles;
begin
  Result := [];
  if Pos('B', UpperCase(Styles)) > 0 then
    Include(Result, fsBold);
  if Pos('I', UpperCase(Styles)) > 0 then
    Include(Result, fsItalic);
  if Pos('U', UpperCase(Styles)) > 0 then
    Include(Result, fsUnderline);
  if Pos('S', UpperCase(Styles)) > 0 then
    Include(Result, fsStrikeOut);
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
  tabFkeys.TabVisible:=false;

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

  ChBckColor  := clWindow;
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
  SentStartCmd :=false;
end;

procedure TfrmDXCluster.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = VK_ESCAPE then
                  begin
                    frmNewQSO.ReturnToNewQSO;
                    key := 0
                  end;
  if (Key >= VK_F1) and (Key <= VK_F10) and (ConTelnet = True) and (Shift = [ssShift])  then
   begin
      case key of
        VK_F1     :Begin
                    if edtF1.Text<>'' then SendCommand(edtF1.Text);
                      key := 0
                   end;
        VK_F2     :Begin
                    if edtF2.Text<>'' then SendCommand(edtF2.Text);
                      key := 0
                   end;
        VK_F3     :Begin
                    if edtF3.Text<>'' then SendCommand(edtF3.Text);
                      key := 0
                   end;
        VK_F4     :Begin
                    if edtF4.Text<>'' then SendCommand(edtF4.Text);
                      key := 0
                   end;
        VK_F5     :Begin
                    if edtF5.Text<>'' then SendCommand(edtF5.Text);
                      key := 0
                   end;
        VK_F6     :Begin
                    if edtF6.Text<>'' then SendCommand(edtF6.Text);
                      key := 0
                   end;
        VK_F7     :Begin
                    if edtF7.Text<>'' then SendCommand(edtF7.Text);
                      key := 0
                   end;
        VK_F8     :Begin
                    if edtF8.Text<>'' then SendCommand(edtF8.Text);
                      key := 0
                   end;
        VK_F9     :Begin
                    if edtF9.Text<>'' then SendCommand(edtF9.Text);
                      key := 0
                   end;
        VK_F10    :Begin
                    if edtF10.Text<>'' then SendCommand(edtF10.Text);
                      key := 0
                   end;
      end;
  end;
end;
procedure TfrmDXCluster.WebDbClick(where:longint;mb:TmouseButton;ms:TShiftState);
var
  spot : String = '';
  tmp  : Integer = 0;
begin
  WebSpots.ReadLine(spot,tmp,tmp,tmp,where);
  SpotDbClick(spot);
end;

procedure TfrmDXCluster.TelDbClick(where:longint;mb:TmouseButton;ms:TShiftState);
var
  spot : String = '';
  tmp  : Integer = 0;
  begin
  TelSpots.ReadLine(spot,tmp,tmp,tmp,where);
  SpotDbClick(spot);
end;
procedure TfrmDXCluster.SpotDbClick(Spot:String);
var
  freq : String = '';
  mode : String = '';
  call : String = '';
  info : String = '';
  etmp : Extended = 0;
  stmp : String = '';
Begin
  dmDXCluster.GetSplitSpot(spot,call,freq,info);
 {
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
    f.Style   := StringToFontStyles(cqrini.ReadString('DXCluster','FontStyle',''));
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
  mnuSkimAllowFreq.Checked := cqrini.ReadBool('Skimmer', 'AllowFreqEnable', False);
  mnuSkimQSLCheck.Checked := cqrini.ReadBool('Skimmer', 'QSLEnable', False);

  ChangeCallAlertCaption;

  if cqrini.ReadBool('DXCluster', 'ConAfterRun', False) then
    tmrAutoConnect.Enabled := True;
  pnlChat.Height := cqrini.ReadInteger('DXCluster','ChatSize',2);  //default now 2 = invisible

  tabFkeysShow(nil);
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
    tabFkeys.TabVisible:=false;
    ConWeb := False;
  end
  else begin
    ConnectToTelnet;
    btnTelConnect.Caption := 'Disconnect';
    ConTelnet := True;
    tabFkeys.TabVisible:=True;
    pgDXCluster.ActivePage:=tabTelnet;
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
  if key=#19 then
  Begin
    key := #0;
    cqrini.WriteString('DXCluster','StartCmd',edtCommand.Text);
    if dmData.DebugLevel>=1 then  writeln('ClusterStarCommand:_',edtCommand.Text,'_saved');
    edtCommand.Clear;
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

procedure TfrmDXCluster.mnuSkimAllowFreqClick(Sender: TObject);
begin
  mnuSkimAllowFreq.Checked := not mnuSkimAllowFreq.Checked;
  cqrini.WriteBool('Skimmer', 'AllowFreqEnable', mnuSkimAllowFreq.Checked);
end;

procedure TfrmDXCluster.mnuSkimQSLCheckClick(Sender: TObject);
begin
  mnuSkimQSLCheck.Checked := not mnuSkimQSLCheck.Checked;
  cqrini.WriteBool('Skimmer', 'QSLEnable', mnuSkimQSLCheck.Checked);
end;

procedure TfrmDXCluster.tabFkeysShow(Sender: TObject);
begin
        edtF1.Text:=cqrini.ReadString('DXCluster', 'F1key', '');
        edtF2.Text:=cqrini.ReadString('DXCluster', 'F2key', '');
        edtF3.Text:=cqrini.ReadString('DXCluster', 'F3key', '');
        edtF4.Text:=cqrini.ReadString('DXCluster', 'F4key', '');
        edtF5.Text:=cqrini.ReadString('DXCluster', 'F5key', '');
        edtF6.Text:=cqrini.ReadString('DXCluster', 'F6key', '');
        edtF7.Text:=cqrini.ReadString('DXCluster', 'F7key', '');
        edtF8.Text:=cqrini.ReadString('DXCluster', 'F8key', '');
        edtF9.Text:=cqrini.ReadString('DXCluster', 'F9key', '');
        edtF10.Text:=cqrini.ReadString('DXCluster', 'F10key', '');
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
  ConTelnet := True;
end;

procedure TfrmDXCluster.lDisconnect(aSocket: TLSocket);
begin
  btnTelConnect.Caption := 'Connect';
  ConTelnet := False;
end;

procedure TfrmDXCluster.lReceive(aSocket: TLSocket);
const
  CR = #13;
  LF = #10;
var
  sStart, sStop, SkimCallStartPos, SkimCallStopPos, SkimParserAnchor: Integer;
  stmp, tmp, Chline, Skimline, SkimCall, SkimFreq, SkimMode, prefix: String;
  itmp, itmp2, QSLState, SkimCTYid : Integer;
  buffer : String;
  f, etmp : Double;
  cmds    :TStringlist;
  K       :integer;
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
          //send start command at first prompt
          if not SentStartCmd and (cqrini.ReadString('DXCluster','StartCmd','') <> '') then
            begin
               cmds := Tstringlist.create;
                try
                 Assert(Assigned(cmds)) ;
                 cmds.Clear;
                 cmds.StrictDelimiter := true;
                 cmds.Delimiter := ';';
                 cmds.DelimitedText := cqrini.ReadString('DXCluster','StartCmd','') ;
                 for K:=0 to cmds.Count-1 do
                  Begin
                   SendCommand(trim(cmds[K]));
                   if dmData.DebugLevel>=1 then  writeln('Sent DXCluster connect start command:',trim(cmds[K]));
                   sleep(100);
                  end;
                finally
                  FreeAndNil(cmds);
                end;
               SentStartCmd := true;
            end;
        end;
      end;
    if  (mnuSkimAllowFreq.Checked) then
      Begin
      if Pos('TO ALL DE SKIMMER',UpperCase(tmp)) > 0 then
        Begin //Handle Double Click in CwSkimmer via Telnet Commands
          Skimline := tmp;
          SkimCallStartPos := Pos('"',Skimline) + 1;
          SkimCallStopPos := Pos('"',copy(Skimline,SkimCallStartPos,Length(Skimline)-SkimCallStartPos));
          SkimCall := copy(Skimline,SkimCallStartPos,SkimCallStopPos - 1);
          SkimFreq := copy(Skimline,Pos('at ',Skimline) + 3,Length(Skimline)-Pos('at ',Skimline));
          if NOT TryStrToFloat(SkimFreq,etmp) then
             exit;
          if (not dmData.BandModFromFreq(SkimFreq,SkimMode,stmp)) or (SkimMode='') then
             exit;
          if dmData.DebugLevel>=1 then WriteLn('Call: ' + SkimCall + ', Freq: ' + SkimFreq + ', Mode: ' + SkimMode);
          frmNewQSO.NewQSOFromSpot(SkimCall,SkimFreq,SkimMode);
        end;
    end;
    itmp := Pos('DX DE',UpperCase(tmp));
    if (itmp > 0) or (TryStrToFloat(copy(tmp,1,Pos(' ',tmp)-1),f) and (UpperCase(tmp[1])<>'E'))  then
    {
    Chk of tmp[1]<>'E' needed:
    sh/he E6
    E6 Niue-E6: 16 degs - dist: 9440 mi, 15192 km Reciprocal heading: 352 degs
    OH1KH de OH1RCF  1-Apr-2023 1000Z dxspider >

    E[number] at beginning of line passes tryStrToFLoat as scientific number expression
    and we want to catch only numbers of frequencies in 12345.6 format.
    They appear if "sh/dx" command is issued

    sh/dx 1
      28074.0 JA6GXP       1-Apr-2023 1033Z FT8 -22dB from PM52 814Hz     <F4UJU>
    OH1KH de OH1RCF  1-Apr-2023 1033Z dxspider >
    }
    begin
      EnterCriticalsection(frmDXCluster.csTelnet);
      if dmData.DebugLevel>=1 then Writeln('Enter critical section On Receive');
      try
        Spots.Add(tmp);
        if Chline <> '' then Chats.Add(Chline);
      finally
        LeaveCriticalsection(csTelnet);
        if dmData.DebugLevel>=1 then Writeln('Leave critical section On Receive')
      end;
      if  (mnuSkimQSLCheck.Checked) then
      Begin
        if (Pos('-#:',UpperCase(tmp)) > 0) then
        Begin //Handle Spot from Skimmer
          Skimline := tmp;
          SkimParserAnchor := Pos('-#:',UpperCase(Skimline));
          SkimCall := copy(Skimline,SkimParserAnchor + 15 , 16);
          SkimCall := copy(SkimCall,0, Pos(' ',SkimCall) - 1);
          SkimFreq := copy(Skimline,SkimParserAnchor + 6, 7);
          if NOT TryStrToFloat(SkimFreq,etmp) then
             exit;
          if (not dmData.BandModFromFreq(SkimFreq,SkimMode,stmp)) or (SkimMode='') then
             exit;
          if dmData.DebugLevel>=1 then Writeln('CAll: ' + SkimCall + ' Freq: ' + SkimFreq);
          SkimCTYid := dmDXCluster.id_country(SkimCall,now,stmp,stmp,stmp,stmp,stmp,stmp,stmp);
          dmDXCluster.DXCCInfo(SkimCTYid,FloatToStr(etmp/1000),SkimMode,QSLState);
          if dmData.DebugLevel>=1 then Writeln('QSLState: ' + FloatToStr(QSLState));
          case QSLState of
            0:
              begin
                lTelnet.SendMessage('SKIMMER/STATUS ' + SkimCall + ' ' + SkimFreq + ' DUPE' + #13 + #10);
                if dmData.DebugLevel>=1 then Writeln('DUPE');
              end;
            1:
              begin
                lTelnet.SendMessage('SKIMMER/STATUS ' + SkimCall + ' ' + SkimFreq + ' NEWCTY' + #13 + #10);
                if dmData.DebugLevel>=1 then Writeln('NEWCTY');
              end;
            2:
              begin
                lTelnet.SendMessage('SKIMMER/STATUS ' + SkimCall + ' ' + SkimFreq + ' BNDCTY' + #13 + #10);
                if dmData.DebugLevel>=1 then Writeln('BNDCTY');
              end;
            4:
              begin
                lTelnet.SendMessage('SKIMMER/STATUS ' + SkimCall + ' ' + SkimFreq + ' NOTCFM' + #13 + #10);
                if dmData.DebugLevel>=1 then Writeln('NOTCFM');
              end;
            else
          end;
        end;
      end;
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

function TfrmDXCluster.GetSplit(info : String) : String;
var
  spl : String;
  spn : String;
  l : Integer;
begin
  if Pos('UP',info)>0 then
   begin
    spl:= copy(info,Pos('UP',info),13);
    spn:='UP';
    for l:=3 to Length(spl) do
       if Pos(spl[l],' 0123456789.,-+')>0 then
           spn:=spn+spl[l]
        else break;
    end;
  if Pos('DOWN',info)>0 then
   begin
    spl:= copy(info,Pos('DOWN',info),13);
    spn:='DOWN';
    for l:=5 to Length(spl) do
       if Pos(spl[l],' 0123456789.,-+')>0 then
           spn:=spn+spl[l]
        else break;
    end;
  if Pos('QSX',info)>0 then
   begin
    spl:= copy(info,Pos('QSX',info),13);
    spn:='QSX';
    for l:=4 to Length(spl) do
       if Pos(spl[l],' 0123456789.,-+')>0 then
           spn:=spn+spl[l]
        else break;
    end;
  Result := trim(spn)
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
    SentStartCmd := False;
  end;
end;

function TfrmDXCluster.ShowSpot(spot : String; var sColor : Integer; var Country : String; FromTelnet : Boolean = True) : Boolean;
var
  kmitocet : Extended = 0.0;
  call     : String  = '';
  freq     : String  = '';
  info     : String  = '';
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
  cfgDATA: Boolean;
  cfgEU  : Boolean;
  cfgAS  : Boolean;
  cfgAF  : Boolean;
  cfgNA  : Boolean;
  cfgSA  : Boolean;
  cfgAN  : Boolean;
  cfgOC  : Boolean;
begin
  sColor  := clWindowText; //cerna

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
    cfgDATA:= gcfgDATA;
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
  dmDXCluster.GetSplitSpot(Spot,call,freq,info);
  splitstr := GetSplit(info);
  kHz := Freq;
  tmp := Pos('.',freq);
  if tmp > 0 then
    freq[tmp] := FormatSettings.DecimalSeparator;
  tmp := Pos(',',freq);
  if tmp > 0 then
    freq[tmp] := FormatSettings.DecimalSeparator;

  isLoTW := dmData.UsesLotw(call);
  isEQSL := dmDXCluster.UseseQSL(call);

  //DXCluster - default Backgroundcolor
  //case lotw and eqsl is given, lotw will win
  ThBckColor := clWindow;
  if cfgeUseBackColor and isEQSL then
    ThBckColor := cfgeBckColor;
  if cfgUseBackColor and isLoTW then
    ThBckColor := cfgBckColor;

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
      Writeln('Cannot show this spot because of Show only spots (band) settings ...');
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

  if not cfgDATA  then
  begin
    if (mode=cqrini.ReadString('Band'+IntToStr(frmTRXControl.cmbRig.ItemIndex), 'Datamode', 'RTTY')) then
      Result := false
  end;

  if (result = False) then
   Begin
    if dmData.DebugLevel >=1 then
       Writeln('Cannot show this spot because of Show only spots (mode) settings ...');
    exit;
   end;
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
    sColor := clWindowText;
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

  if  ( mnuCallalert.Checked and ConTelnet ) then // do not run IsAlertCall unless alert is selected
                                                   // and connected to telnet cluster
    if (dmDXCluster.IsAlertCall(call,band,mode,cqrini.ReadBool('DxCluster', 'AlertRegExp', False))) then
      Begin
        if dmData.DebugLevel >=1 then
            Writeln('Spot is:',spot,#$0A,'----Call alerting is: ',call,',',band,',',mode,',',freq,',',info,'-----------');
        dmDXCluster.RunCallAlertCmd(call,band,mode,freq,info);
        call :='';
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
    gcfgDATA:= cqrini.ReadBool('DXCluster','DATA',True);
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

                                 
