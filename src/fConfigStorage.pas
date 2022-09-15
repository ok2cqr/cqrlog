unit fConfigStorage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls;

type

  { TfrmConfigStorage }

  TfrmConfigStorage = class(TForm)
    btnSave: TButton;
    btnCancel: TButton;
    cmbStoreXplanet: TComboBox;
    cmbStoreCWInterface: TComboBox;
    cmbStoreCalbook: TComboBox;
    cmbStoreMembership: TComboBox;
    cmbStoreBandMap: TComboBox;
    cmbStoreOnlineLog: TComboBox;
    cmbStoreFonts: TComboBox;
    cmbStoreWindowSize: TComboBox;
    cmbStoreRbn: TComboBox;
    cmbStoreFldigiInterface: TComboBox;
    cmbStoreAutoBackup: TComboBox;
    cmbStoreExtViewers: TComboBox;
    cmbStoreModes: TComboBox;
    cmbStoreExport: TComboBox;
    cmbStoreCluster: TComboBox;
    cmbStoreRotorControl: TComboBox;
    cmbStoreTRXControl: TComboBox;
    cmbStoreVisColumns: TComboBox;
    cmbStoreProgram: TComboBox;
    cmbStoreColumnSize: TComboBox;
    cmbStoreZipCode: TComboBox;
    cmbStoreNewQSO: TComboBox;
    cmbStoreLoTW: TComboBox;
    Label1: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label2: TLabel;
    Label26: TLabel;
    Label29: TLabel;
    Label3: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label35: TLabel;
    Label36: TLabel;
    Label37: TLabel;
    Label38: TLabel;
    Label39: TLabel;
    Label40: TLabel;
    Label41: TLabel;
    Label42: TLabel;
    Label43: TLabel;
    Label44: TLabel;
    Label45: TLabel;
    Label46: TLabel;
    Label47: TLabel;
    Label48: TLabel;
    Shape1: TShape;
    Shape2: TShape;
    procedure btnSaveClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmConfigStorage: TfrmConfigStorage;

implementation
{$R *.lfm}

{ TfrmConfigStorage }

uses dUtils, uMyIni;

procedure TfrmConfigStorage.FormShow(Sender: TObject);

  function SectionExists(Section,Sections : String) : Integer;
  begin
    if Pos(Section+',',Sections)>0 then
      Result := 1
    else
      Result := 0
  end;

var
  Sections : String;
begin
  dmUtils.LoadFontSettings(self);
  Sections := cqrini.ReadString('ConfigStorage','Items','');
  if (Sections='') then exit;

  cmbStoreProgram.ItemIndex         := SectionExists('Program',Sections);
  cmbStoreNewQSO.ItemIndex          := SectionExists('NewQSO',Sections);
  cmbStoreVisColumns.ItemIndex      := SectionExists('Columns',Sections);
  cmbStoreTRXControl.ItemIndex      := SectionExists('TRX1',Sections);
  cmbStoreRotorControl.ItemIndex    := SectionExists('ROT',Sections);
  cmbStoreModes.ItemIndex           := SectionExists('Band1',Sections);
  cmbStoreExport.ItemIndex          := SectionExists('Export',Sections);
  cmbStoreCluster.ItemIndex         := SectionExists('DXCluster',Sections);
  cmbStoreFonts.ItemIndex           := SectionExists('Fonts',Sections);
  cmbStoreMembership.ItemIndex      := SectionExists('Clubs',Sections);
  cmbStoreBandMap.ItemIndex         := SectionExists('BandMap',Sections);
  cmbStoreXplanet.ItemIndex         := SectionExists('xplanet',Sections);

  cmbStoreZipCode.ItemIndex         := SectionExists('ZipCode',Sections);
  cmbStoreLoTW.ItemIndex            := SectionExists('LoTW',Sections);
  cmbStoreCWInterface.ItemIndex     := SectionExists('CW1',Sections);
  cmbStoreFldigiInterface.ItemIndex := SectionExists('fldigi',Sections);
  cmbStoreAutoBackup.ItemIndex      := SectionExists('Backup',Sections);
  cmbStoreExtViewers.ItemIndex      := SectionExists('ExtView',Sections);
  cmbStoreCalbook.ItemIndex         := SectionExists('CallBook',Sections);
  cmbStoreRbn.ItemIndex             := SectionExists('RBN',Sections);
  cmbStoreOnlineLog.ItemIndex       := SectionExists('OnlineLog',Sections);
  cmbStoreWindowSize.ItemIndex      := SectionExists('WindowSize',Sections);
  cmbStoreColumnSize.ItemIndex      := SectionExists('ColumnSize',Sections)
end;

procedure TfrmConfigStorage.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveForm(self)
end;

procedure TfrmConfigStorage.btnSaveClick(Sender: TObject);
var
  Sections : String = '';
begin
  if cmbStoreProgram.ItemIndex>0 then
    Sections := Sections + 'Program,';
  if cmbStoreNewQSO.ItemIndex>0 then
    Sections := Sections + 'NewQSO,';
  if cmbStoreVisColumns.ItemIndex>0 then
    Sections := Sections + 'Columns,';
  if cmbStoreTRXControl.ItemIndex>0 then
    Sections := Sections + 'TRX,TRX1,TRX2,TRX3,TRX4,TRX5,TRX6,';
  if cmbStoreRotorControl.ItemIndex>0 then
    Sections := Sections + 'ROT,ROT1,ROT2,';
  if cmbStoreModes.ItemIndex>0 then
    Sections := Sections + 'Band1,Band2,Band3,Band4,Band5,Band6,Modes,';
  if cmbStoreExport.ItemIndex>0 then
    Sections := Sections + 'Export,';
  if cmbStoreCluster.ItemIndex>0 then
    Sections := Sections + 'DXCluster,';
  if cmbStoreFonts.ItemIndex>0 then
    Sections := Sections + 'Fonts,';
  if cmbStoreMembership.ItemIndex>0 then
    Sections := Sections + 'Clubs,FirstClub,SecondClub,ThirdClub,FifthClub,FourthClub,';
  if cmbStoreBandMap.ItemIndex>0 then
    Sections := Sections + Sections + 'BandMap,BandMapFilter,';
  if cmbStoreXplanet.ItemIndex>0 then
    Sections := Sections + 'xplanet,';
  if cmbStoreZipCode.ItemIndex>0 then
    Sections := Sections + 'ZipCode,';
  if cmbStoreLoTW.ItemIndex>0 then
    Sections := Sections + 'LoTW,';
  if cmbStoreCWInterface.ItemIndex>0 then
    Sections := Sections + 'CW,CW1,CW2,CW3,CW4,CW5,CW6';
  if cmbStoreFldigiInterface.ItemIndex>0 then
    Sections := Sections + 'fldigi,wsjt,n1mm';
  if cmbStoreAutoBackup.ItemIndex>0 then
    Sections := Sections + 'Backup,';
  if cmbStoreExtViewers.ItemIndex>0 then
    Sections := Sections + 'ExtView,';
  if cmbStoreCalbook.ItemIndex>0 then
    Sections := Sections + 'CallBook,';
  if cmbStoreRbn.ItemIndex>0 then
    Sections := Sections + 'RBN,RBNFilter,';
  if cmbStoreOnlineLog.ItemIndex>0 then
    Sections := Sections + 'OnlineLog,';
  if cmbStoreWindowSize.ItemIndex>0 then
    Sections := Sections + 'WindowSize,Window,Grayline,';
  if cmbStoreColumnSize.ItemIndex>0 then
    Sections := Sections + 'ColumnSize,';
  cqrini.WriteString('ConfigStorage','Items',Sections);
  cqrini.LoadLocalSectionsList;
  ModalResult := mrOK
end;

end.

