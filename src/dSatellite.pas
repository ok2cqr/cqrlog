unit dSatellite;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, StdCtrls, LazFileUtils;

const
  C_SATELLITE_LIST = 'sat_name.tab';
  C_PROP_MODE_LIST = 'prop_mode.tab';

type

  { TdmSatellite }

  TdmSatellite = class(TDataModule)
    procedure DataModuleCreate(Sender : TObject);
    procedure DataModuleDestroy(Sender : TObject);
  private
    ListOfSatellites : TStringList;
    ListOfPropModes  : TStringList;

    function  GetShortName(StringItem : String) : String;

  public
    function  GetSatShortName(Satellite : String) : String;
    function  GetPropShortName(Propagation : String) : String;
    function  GetPropLongName(Propagation : String) : String;

    procedure LoadSatellitesFromFile;
    procedure LoadPropModesFromFile;
    procedure SetListOfSatellites(cmbSatellite : TComboBox);
    procedure GetListOfSatellites(cmbSatellite : TComboBox; Selected : String = '');
    procedure SetListOfPropModes(cmbPropMode : TComboBox);
    procedure GetListOfPropModes(cmbPropMode : TComboBox; Selected : String = '');
  end;

var
  dmSatellite : TdmSatellite;

implementation
  {$R *.lfm}

uses dData;

{ TdmSatellite }

procedure TdmSatellite.DataModuleCreate(Sender : TObject);
begin
  ListOfSatellites := TStringList.Create;
  ListOfPropModes  := TStringList.Create;

  LoadSatellitesFromFile;
  LoadPropModesFromFile
end;

procedure TdmSatellite.LoadSatellitesFromFile;
begin
  ListOfSatellites.Clear;
  if FileExists(dmData.HomeDir + C_SATELLITE_LIST) then
    ListOfSatellites.LoadFromFile(dmData.HomeDir + C_SATELLITE_LIST)
end;

procedure TdmSatellite.LoadPropModesFromFile;
begin
  ListOfPropModes.Clear;
  if FileExists(dmData.HomeDir + C_PROP_MODE_LIST) then
    ListOfPropModes.LoadFromFile(dmData.HomeDir + C_PROP_MODE_LIST)
end;
procedure TdmSatellite.SetListOfSatellites(cmbSatellite : TComboBox);
Begin
  cmbSatellite.Clear;
  cmbSatellite.Items.Add('');
  cmbSatellite.ItemIndex := 0;

  cmbSatellite.Items.AddStrings(ListOfSatellites);
end;

procedure TdmSatellite.GetListOfSatellites(cmbSatellite : TComboBox; Selected : String = '');
var
  i : Integer;
begin

  for i:=0 to cmbSatellite.Items.Count -1 do
  begin
    if (GetSatShortName(cmbSatellite.Items.Strings[i]) = Selected) then
    begin
      cmbSatellite.ItemIndex := i;
      break
    end
  end
end;
procedure TdmSatellite.SetListOfPropModes(cmbPropMode : TComboBox);
Begin
 cmbPropMode.Clear;
 cmbPropMode.Items.Add('');
 cmbPropMode.ItemIndex := 0;

 cmbPropMode.Items.AddStrings(ListOfPropModes);
end;

procedure TdmSatellite.GetListOfPropModes(cmbPropMode : TComboBox; Selected : String);
var
  i : Integer;
begin

  for i:=0 to cmbPropMode.Items.Count - 1 do
  begin
    if (GetPropShortName(cmbPropMode.Items.Strings[i]) = Selected) then
    begin
      cmbPropMode.ItemIndex := i;
      break
    end
  end
end;

function TdmSatellite.GetSatShortName(Satellite : String) : String;
begin
  Result := GetShortName(Satellite)
end;

function TdmSatellite.GetPropShortName(Propagation : String) : String;
begin
  Result := GetShortName(Propagation)
end;

function TdmSatellite.GetPropLongName(Propagation : String) : String;
var
  i : integer;
begin
  for i:=0 to ListOfPropModes.Count-1 do
  begin
    if (Pos(Propagation, ListOfPropModes[i]) = 1) then
        break;
  end;
  Result := ListOfPropModes[i];
end;

function TdmSatellite.GetShortName(StringItem : String) : String;
begin
  Result := Copy(StringItem, 1, Pos('|', StringItem) - 1)
end;

procedure TdmSatellite.DataModuleDestroy(Sender : TObject);
begin
  FreeAndNil(ListOfSatellites);
  FreeAndNil(ListOfPropModes)
end;

initialization


end.

