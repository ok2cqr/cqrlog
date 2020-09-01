unit dSatellite;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, StdCtrls, LazFileUtils;

const
  C_SATELLITE_LIST = 'sat_name.tab';
  C_PROP_MODE_LIST = 'prop_mode.tab';

  AMSATStatusUrl = 'https://amsat.org/status/';

type

  { TdmSatellite }

  TdmSatellite = class(TDataModule)
    procedure DataModuleCreate(Sender : TObject);
    procedure DataModuleDestroy(Sender : TObject);
  private
    ListOfSatellites : TStringList;
    ListOfPropModes  : TStringList;

    function  GetShortName(StringItem : String) : String;
    function  GetSatModeDesignator(freq : String) : String;

  public
    function  GetSatShortName(Satellite : String) : String;
    function  GetPropShortName(Propagation : String) : String;
    function  GetPropLongName(Propagation : String) : String;
    function  GetSatMode(freq, rxfreq : String) : String;

    procedure LoadSatellitesFromFile;
    procedure LoadPropModesFromFile;
    procedure SetListOfSatellites(cmbSatellite : TComboBox);
    procedure GetListOfSatellites(cmbSatellite : TComboBox; Selected : String = '');
    procedure SetListOfPropModes(cmbPropMode : TComboBox);
    procedure GetListOfPropModes(cmbPropMode : TComboBox; Selected : String = '');

    procedure UpdateAMSATStatusPage(date,time,sat,uplink,downlink,mode : String);
  end;

var
  dmSatellite : TdmSatellite;

implementation
  {$R *.lfm}

uses dData, dUtils, uMyIni;

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
  Result:='';
  for i:=0 to ListOfPropModes.Count-1 do
  begin
    if (Pos(Propagation, ListOfPropModes[i]) = 1) then
     Begin
       Result := ListOfPropModes[i];
       break;
     end;
  end;

end;

function TdmSatellite.GetShortName(StringItem : String) : String;
begin
  Result := Copy(StringItem, 1, Pos('|', StringItem) - 1)
end;

function  TdmSatellite.GetSatMode(freq, rxfreq : String) : String;
var
   tmp : String = '';
begin
  tmp := GetSatModeDesignator(freq)+GetSatModeDesignator(rxfreq);
  if (length(tmp) = 2) then
     Result := tmp
  else
     Result := '';
end;

function  TdmSatellite.GetSatModeDesignator(freq : String) : String;
begin
   case dmUtils.GetBandFromFreq(freq) of
      '15M'    : Result := 'H';
      '10M'    : Result := 'A';
      '2M'     : Result := 'V';
      '70CM'   : Result := 'U';
      '23CM'   : Result := 'L';
      '13CM'   : Result := 'S';
      '6CM'    : Result := 'C';
      '3CM'    : Result := 'X';
      '1.25CM' : Result := 'K';
      '6MM'    : Result := 'R';
      else       Result := '';
   end;
end;

procedure TdmSatellite.DataModuleDestroy(Sender : TObject);
begin
  FreeAndNil(ListOfSatellites);
  FreeAndNil(ListOfPropModes)
end;

procedure TdmSatellite.UpdateAMSATStatusPage(date, time, sat, uplink, downlink, mode : String);
var
   data : String;
   url  : String;
   mycall    : String;
   myloc     : String;
   SatShort  : String = '';
   DateArray : TExplodeArray;
   TimeArray : TExplodeArray;
   min       : Integer = 0;
   SatPeriod : String = '';
begin
   DateArray := dmUtils.Explode('-',date); 
   TimeArray := dmUtils.Explode(':',time); 
   mycall := cqrini.ReadString('Station', 'Call', '');
   myloc := cqrini.ReadString('Station','LOC','');
   SatShort := GetSatShortName(Sat);
   min := StrToInt(TimeArray[1]);

   if (min >= 0) and (min <= 15) then
      SatPeriod := '0';
   if (min >= 16) and (min <= 30) then
      SatPeriod := '1';
   if (min >= 31) and (min <= 45) then
      SatPeriod := '2';
   if (min >= 46) and (min <= 59) then
      SatPeriod := '3';

   // Set special values for specific modes on sats
   if (SatShort = 'AO-7') then
   begin
      if (dmUtils.GetBandFromFreq(downlink) = '10M') and (dmUtils.GetBandFromFreq(uplink) = '2M') then
               SatShort := '[A]_AO-7';
      if (dmUtils.GetBandFromFreq(downlink) = '2M') and (dmUtils.GetBandFromFreq(uplink) = '70CM') then
               SatShort := '[B]_AO-7';
   end;

   if (SatShort = 'PO-101') then
   begin
      case mode of
         'FM'     : SatShort := 'PO-101[FM]';
         'PACKET' : SatShort := 'PO-101[APRS]';
         else       SatShort := 'PO-101[FM]';
      end;
   end;

   if (SatShort = 'AO-92') then
   begin
      if (dmUtils.GetBandFromFreq(downlink) = '2M') then
      begin
         if (dmUtils.GetBandFromFreq(uplink) = '70CM') then
            SatShort := 'AO-92_U/v';
         if (dmUtils.GetBandFromFreq(uplink) = '23CM') then
            SatShort := 'AO-92_L/v';
      end;
   end;

   if (SatShort = 'AO-95') then
   begin
      if (dmUtils.GetBandFromFreq(downlink) = '2M') then
      begin
         if (dmUtils.GetBandFromFreq(uplink) = '70CM') then
            SatShort := 'AO-95_U/v';
         if (dmUtils.GetBandFromFreq(uplink) = '23CM') then
            SatShort := 'AO-95_L/v';
      end;
   end;

   if (SatShort = 'QO-100') then SatShort := 'QO-100_NB';

   if (SatShort <> '') then
   begin
      url := AMSATStatusUrl + 'submit.php?SatSubmit=yes&Confirm=yes&SatName='+SatShort+'&SatYear='+DateArray[0]+'&SatMonth='+DateArray[1]+'&SatDay='+DateArray[2]+'&SatHour='+TimeArray[0]+'&SatPeriod='+SatPeriod+'&SatCall='+mycall+'&SatReport=Heard&SatGridSquare='+myloc;

      if dmUtils.GetDataFromHttp(url, data) then
      begin
         if dmData.DebugLevel>=1 then Writeln(data);
      end;
   end;
end;

initialization


end.

