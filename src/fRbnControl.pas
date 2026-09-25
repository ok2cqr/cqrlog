(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ The small RBN control window: state dot, source preset, connect/disconnect,
  global filter. It is the one place that decides which preset the main
  connection uses ([RBN] MainSourceId) and the one that connects it; the RBN
  monitor, the band maps and the Grayline only read from that connection.

  Closing the window hides it. The connection lives on; only Disconnect ends it. }

unit fRbnControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Buttons, Graphics,
  Dialogs, LCLType, ComCtrls, dSqlRef, uRbnConnection;

type

  { TfrmRbnControl }

  TfrmRbnControl = class(TForm)
    btnConnect: TSpeedButton;
    btnFilter: TSpeedButton;
    btnSources: TSpeedButton;
    btnStatusBar: TSpeedButton;
    chkToBandMap: TCheckBox;
    cmbSource: TComboBox;
    imgRbnControl: TImageList;
    shpState: TShape;
    sbStatus: TStatusBar;
    tmrStatus: TTimer;
    procedure btnStatusBarClick(Sender: TObject);
    procedure chkToBandMapChange(Sender: TObject);
    procedure tmrStatusTimer(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnFilterClick(Sender: TObject);
    procedure btnSourcesClick(Sender: TObject);
    procedure cmbSourceChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    FConn    : TRbnConnection;
    FSources : TRbnSourceList;
    procedure LoadSources;
    procedure OnRbnState(Sender : TObject);
    function  SelectedSource(out Source : TRbnSource) : Boolean;
  public
    //the preset the main connection uses, 0 = none chosen yet
    function  MainSourceId : Integer;
    //connect the main connection to the chosen preset; False and a message
    //when there is nothing to connect to. Used by the Monitor and by autostart
    function  ConnectMain : Boolean;
    procedure DisconnectMain;
    //one line for a menu item or a status bar, readable without the colour
    function  StateText : String;
  end;

var
  frmRbnControl : TfrmRbnControl;

implementation

{$R *.lfm}

uses
  dUtils, uMyIni, fRbnSources, fRbnFilter, fRbnMonitor, fNewQSO, uBandMapStore;

procedure TfrmRbnControl.FormCreate(Sender: TObject);
begin
  FConn := RbnMainConnection;
  FConn.SubscribeState(@OnRbnState)
end;

procedure TfrmRbnControl.FormDestroy(Sender: TObject);
begin
  FConn.UnsubscribeState(@OnRbnState)
end;

procedure TfrmRbnControl.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(self);
  LoadSources;
  chkToBandMap.Checked := cqrini.ReadBool('RBNMonitor','ToBandMap',False);
  //the status bar is the only place to see that spots arrive at all when the
  //monitor is closed and the band is quiet
  tmrStatusTimer(nil);
  OnRbnState(FConn)
end;

procedure TfrmRbnControl.tmrStatusTimer(Sender: TObject);
begin
  if FConn.State = rcsConnected then
    sbStatus.SimpleText := IntToStr(FConn.SpotsLastMinutes) + ' spots in the last ' +
                           IntToStr(RBN_RATE_MINUTES) + ' min, ' + IntToStr(FConn.SpotsTotal) + ' total'
  else
    sbStatus.SimpleText := FConn.Status
end;

procedure TfrmRbnControl.btnStatusBarClick(Sender: TObject);
begin
  if sbStatus.Visible then
    sbStatus.Visible := False
  else
    sbStatus.Visible := True
end;

procedure TfrmRbnControl.chkToBandMapChange(Sender: TObject);
begin
  //the switch lives with the monitor's worker, which feeds the band maps
  //whether the monitor window is open or not. Setting the same value back
  //from SetSendToBandMap fires no second change
  if Assigned(frmRbnMonitor) and (frmRbnMonitor.acLinkToBandMap.Checked <> chkToBandMap.Checked) then
    frmRbnMonitor.SetSendToBandMap(chkToBandMap.Checked)
end;

procedure TfrmRbnControl.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  //hide only; the connection is not the window's
  dmUtils.SaveWindowPos(self);
  CloseAction := caHide
end;

procedure TfrmRbnControl.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    frmNewQSO.ReturnToNewQSO;
    Key := 0
  end
end;

function TfrmRbnControl.MainSourceId : Integer;
begin
  Result := cqrini.ReadInteger('RBN', 'MainSourceId', 0)
end;

procedure TfrmRbnControl.LoadSources;
var
  i, Id : Integer;
begin
  FSources := dmSqlRef.LoadRbnSources;
  Id := MainSourceId;
  cmbSource.Items.BeginUpdate;
  try
    cmbSource.Clear;
    for i := 0 to High(FSources) do
    begin
      cmbSource.Items.Add(RbnSourceCaption(FSources[i]));
      if FSources[i].Id = Id then
        cmbSource.ItemIndex := i
    end;
    //a deleted preset must not leave the combo pointing at nothing; prefer
    //the public RBN server over whatever sorts first (the Grayline's own
    //cluster address, for one)
    if (cmbSource.ItemIndex < 0) and (cmbSource.Items.Count > 0) then
    begin
      cmbSource.ItemIndex := 0;
      for i := 0 to High(FSources) do
        if Pos('reversebeacon', LowerCase(FSources[i].Address)) > 0 then
        begin
          cmbSource.ItemIndex := i;
          Break
        end;
      cqrini.WriteInteger('RBN', 'MainSourceId', FSources[cmbSource.ItemIndex].Id)
    end
  finally
    cmbSource.Items.EndUpdate
  end
end;

function TfrmRbnControl.SelectedSource(out Source : TRbnSource) : Boolean;
begin
  Result := (cmbSource.ItemIndex >= 0) and (cmbSource.ItemIndex <= High(FSources));
  if Result then
    Source := FSources[cmbSource.ItemIndex]
  else
    Source := Default(TRbnSource)
end;

procedure TfrmRbnControl.cmbSourceChange(Sender: TObject);
var
  Src : TRbnSource;
begin
  if not SelectedSource(Src) then
    exit;
  //candidates of the old source must not pass for the new one's
  if Src.Id <> MainSourceId then
    SpotStore.DropRbnSource(MainSourceId);
  cqrini.WriteInteger('RBN', 'MainSourceId', Src.Id);
  if Assigned(frmRbnMonitor) then
    frmRbnMonitor.LoadConfigToThread;
  //a live connection follows the choice, a disconnected one just remembers it
  if FConn.State <> rcsDisconnected then
    ConnectMain
end;

procedure TfrmRbnControl.btnSourcesClick(Sender: TObject);
begin
  with TfrmRbnSources.Create(self) do
  try
    SelectedId := MainSourceId;
    ShowModal
  finally
    Free
  end;
  LoadSources
end;

function TfrmRbnControl.ConnectMain : Boolean;
var
  Src : TRbnSource;
begin
  if cmbSource.Items.Count = 0 then
    LoadSources;
  Result := SelectedSource(Src) and (Src.Address <> '');
  if not Result then
  begin
    Application.MessageBox('No RBN source is defined. Add one with the button next to the list.',
                           'Warning ...', mb_ok + mb_IconWarning);
    exit
  end;
  if Src.UserName = '' then
    Src.UserName := cqrini.ReadString('Station', 'Call', '');
  FConn.Connect(Src.Address, Src.Port, Src.UserName)
end;

procedure TfrmRbnControl.DisconnectMain;
begin
  FConn.Disconnect
end;

procedure TfrmRbnControl.btnConnectClick(Sender: TObject);
begin
  if FConn.State = rcsDisconnected then
    ConnectMain
  else
    DisconnectMain
end;

procedure TfrmRbnControl.btnFilterClick(Sender: TObject);
begin
  //the same filter the RBN monitor uses; the monitor picks the change up
  with TfrmRbnFilter.Create(self) do
  try
    if ShowModal = mrOK then
      frmRbnMonitor.LoadConfigToThread
  finally
    Free
  end
end;

function TfrmRbnControl.StateText : String;
begin
  case FConn.State of
    rcsConnected    : Result := 'connected';
    rcsConnecting   : Result := 'connecting';
    rcsWaiting      : Result := 'problem, retrying';
    else              Result := 'disconnected'
  end
end;

procedure TfrmRbnControl.OnRbnState(Sender : TObject);
begin
  case FConn.State of
    rcsConnected  : shpState.Brush.Color := clBlue;
    rcsConnecting,
    rcsWaiting    : shpState.Brush.Color := clRed;
    else            shpState.Brush.Color := clSilver
  end;
  shpState.Hint := FConn.Status;
  tmrStatusTimer(nil);
  if FConn.State = rcsDisconnected then
  begin
    btnConnect.ImageIndex := 1;
    btnConnect.Hint := 'Connect to RBN'
  end
  else begin
    btnConnect.ImageIndex := 0;
    btnConnect.Hint := 'Disconnect RBN'
  end;
  Caption := 'RBN control - ' + StateText
end;

end.
