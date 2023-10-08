(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit dUtils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Dialogs, StdCtrls, iniFiles,
  DBGrids, aziloc, azidis3, process, DB, sqldb, Grids, Buttons, spin, colorbox,
  Menus, Graphics, Math, LazHelpHTML, lNet, DateUtils, fileutil, httpsend,
  sqlscript, BaseUnix, Unix, LazFileUtils, LazUTF8, RegExpr,
  laz2_XMLRead, laz2_DOM, fpjson,jsonparser,StrUtils;

  //"XMLRead, DOM," replced. These have system encoding. "laz2_" ones have full UTF-8 Unicode support
  //they should be replaceable by Laz-XML-wiki.

type
  TExplodeArray = array of string;

type
  TVisibleColumn = record
    FieldName : String[20];
    Visible   : Boolean;
    Exists    : Boolean;
  end;

  BandVsFreq = record
    band     : string;
    b_begin  : currency;
    b_end    : currency;
  end;

type
  TColumnVisibleArray = array of TVisibleColumn;

const
  MyWhiteSpace = [#0..#31];
  AllowedCallChars = ['A'..'Z', '0'..'9', '/'];
  AllowedChars = ['A'..'Z', 'a'..'z', '0'..'9', '/', ',', '.', '?', '!', ' ',
    ':', '|', '-', '=', '+', '@', '#', '*', '%', '_', '(', ')', '$', '<', '>'];
  empty_freq = '0.00000';
  empty_azimuth = '0.0';

  cMaxModes = 48; //One less than count 49 modes (loops have 0..MaxModes)
  cModes: array [0..cMaxModes] of string =
    ('CW',    'SSB',  'AM',    'FM',    'RTTY',  'SSTV',  'PACTOR','PSK',   'ATV',         'CLOVER',
     'GTOR',  'MTOR', 'PSK31', 'HELL',  'MT63',  'QRSS',  'CWQ',   'BPSK31','MFSK',        'JT44',
     'FSK44', 'WSJT', 'AMTOR', 'THROB', 'BPSK63','PACKET','OLIVIA','MFSK16','JS8',         'JT4',
     'JT6M',  'JT65', 'JT65A', 'JT65B', 'JT65C', 'JT9',   'QRA64', 'ISCAT', 'MSK144',      'FT8',
     'FT4',   'FST4', 'FSK441','PSK125','PSK63', 'WSPR',  'PSK250','ROS',   'DIGITALVOICE');

  cMaxBandsCount = 31; //True count of bands. (loops have 0..MaxBandsCount-1)
  cBands: array[0..30] of string[10] =
    ('2190M', '630M', '160M', '80M'  , '60M','40M'  , '30M', '20M'  , '17M' , '15M' ,
     '12M'  , '10M' , '5M'  , '6M'   , '8M' ,'4M'   , '2M' , '1.25M', '70CM', '33CM',
     '23CM' , '13CM', '9CM' , '6CM'  , '3CM','1.25CM','6MM', '4MM'  , '2.5MM','2MM',
     '1MM');
  cDefaultFreq =
    '0.136|0.472|1.800|3.500|3.700|5.351|7.000|10.100|14.000|14.200|'+
    '18.100|21.000|21.200|24.890|28.000|28.500|40.000|50.000|60.0000|70.0500|'+
    '144.000|145.275|430.000|902.0|1250.0|2400.0|3450.0|5670.0|10250.0|24100.0|'+
    '47100.0|78000.0|122252.0|134930.0|248000.0';


  cMaxIgnoreFreq = 6;
  cIngnoreFreq: array [0..cMaxIgnoreFreq] of string =
    ('1800.0', '3500.0', '7000.0', '10100.0', '14000.0', '21000.0', '28000.0');

  C_RBN_CONT  = 'AF,AN,AS,EU,NA,SA,OC';
  C_RBN_BANDS = '630M,160M,80M,60M,40M,30M,20M,17M,15M,12M,10M,8M,6M,5M,2M';
  C_RBN_MODES = 'CW,RTTY,PSK31';

  C_CONTEST_LIST_FILE_NAME = 'ContestName.tab';

  Adif_intls: array[0 .. 18] of string = (
    'ADDRESS_INTL', 'COUNTRY_INTL',   'COMMENT_INTL',    'MY_ANTENNA_INTL',
    'MY_CITY_INTL', 'MY_COUNTRY_INTL','MY_NAME_INTL',    'MY_POSTAL_CODE_INTL',
    'MY_RIG_INTL',  'MY_SIG_INTL',    'MY_SIG_INFO_INTL','MY_STREET_INTL',
    'NAME_INTL',    'NOTES_INTL',     'QSLMSG_INTL',     'QTH_INTL',
    'RIG_INTL',     'SIG_INTL',       'SIG_INFO_INTL');

   c_MODEFILE_DIR    = ''; //   'ctyfiles/';
   C_SUBMODE_FILE    = 'submode_mode.txt';
   C_IMPORTMODE_FILE = 'import_mode.txt';
   C_EXCEPMODE_FILE  = 'exception_mode.txt';
   C_READMEMODE_FILE = 'README_modefiles';

type

  { TdmUtils }

  TdmUtils = class(TDataModule)
    Datasource1: TDatasource;
    HelpViewer: THTMLBrowserHelpViewer;
    HelpDatabase: THTMLHelpDatabase;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    fTimeOffset: currency;
    fGrayLineOffset: currency;
    fQRZSession: string;
    fHamQTHSession: string;
    fQRZCQSession: string;
    fSysUTC: boolean;
    SubmodeMode: TStringList;
    ImportMode : TStringlist;
    ExceptMode : TStringlist;

    procedure LoadRigList(RigCtlBinaryPath : String;RigList : TStringList);
    procedure LoadRigListCombo(CurrentRigId : String; RigList : TStringList; RigComboBox : TComboBox);
    procedure ModeConvListsCreate(SetUp:boolean);
    procedure MakeMissingModeFile(num:integer);

    function nr(ch: char): integer;
    function GetTagValue(Data, tg: string): string;
    function GetQRZSession(var ErrMsg: string): boolean;
    function GetQRZCQSession(var ErrMsg: string): boolean;
    function GetHamQTHSession(var ErrMsg: string): boolean;
    function GetQRZInfo(call: string;
      var nick, qth, address, zip, grid, state, county, qsl, iota, waz, itu, ErrMsg: string): boolean;
    function GetHamQTHInfo(call: string;
      var nick, qth, address, zip, grid, state, county, qsl, iota, waz, itu, dok, ErrMsg: string): boolean;
    function GetQRZCQInfo(call: string;
      var nick, qth, address, zip, grid, state, county, qsl, iota, waz, itu, dok, ErrMsg: string): boolean;

  public
    s136: string;
    s630: string;
    s160: string;
    s80: string;
    s60: string;
    s40: string;
    s30: string;
    s20: string;
    s17: string;
    s15: string;
    s12: string;
    s10: string;
    s8: string;
    s6: string;
    s5: string;
    s4: string;
    s220: string;
    s2: string;
    s70: string;
    s900: string;
    s1260: string;
    s2300: string;
    s3400: string;
    s5850: string;
    s10G: string;
    s24G: string;
    s47G: string;
    s76G: string;
    s122G: string;
    s134G: string;
    s241G: string;
    USstates: array [1..50] of string;
    DOKs: array [1..52] of string;
    MyBands: array [0..cMaxBandsCount - 1, 0..1] of string[6];
    //list of bands, band labels
    BandFreq  : array [0..cMaxBandsCount - 1]of BandVsFreq;


    property TimeOffset: currency read fTimeOffset write fTimeOffset;
    property GrayLineOffset: currency read fGraylineOffset write fGrayLineOffset;
    property SysUTC: boolean read fSysUTC write fSysUTC;

    procedure InsertContests(cmbContestName: TComboBox);
    procedure InsertModes(cmbMode: TComboBox);
    procedure InsertQSL_S(QSL_S: TComboBox);
    procedure InsertQSL_R(QSL_R: TcomboBox);
    procedure InsertFreq(cmbFreq: TComboBox);
    procedure InsertBands(cmbBand: TComboBox);
    procedure InsertWorkedContests(cmbContest: TComboBox);
    procedure DateInRightFormat(date: TDateTime; var Mask, sDate: string);
    procedure FileCopy(const FileFrom, FileTo: string);
    procedure CopyData(Source, Destination: string);
    procedure DeleteData(Directory: string);
    procedure SaveForm(aForm: TForm);
    procedure LoadForm(aForm: TForm);
    procedure SaveLog(Text: string);
    procedure GetCoordinate(pfx: string; var latitude, longitude: currency);
    procedure GetRealCoordinate(lat, long: string; var latitude, longitude: currency);
    procedure DistanceFromCoordinate(my_loc: string; latitude, longitude: real;
      var qra, azim: string);
    procedure DistanceFromLocator(my_loc, his_loc: string; var qra, azim: string);
    procedure DistanceFromPrefixMyLoc(my_loc, pfx: string; var qra, azim: string);
    procedure ModifyWAZITU(var waz, itu: string);
    procedure CoordinateFromLocator(loc: string; var latitude, longitude: currency);
    procedure EnterFreq;
    procedure LoadFontSettings(aForm: TForm);
    procedure LoadBandLabelSettins;
    procedure SortList(l: TStringList);
    procedure RunXplanet;
    procedure CloseXplanet;
    procedure ModifyXplanetConf;
    procedure DeleteMarkerFile;
    procedure ReadZipList(cmbZip: TComboBox);
    procedure CalcSunRiseSunSet(Lat, Long: double; var SunRise, SunSet: TDateTime);
    procedure ExecuteCommand(cmd: string);
    procedure RunOnBackground(path: string);
    procedure SaveWindowPos(a: TForm);
    procedure LoadWindowPos(a: TForm);
    procedure ShowQSLWithExtViewer(Call: string);
    procedure ShowQRZInBrowser(call: string);
    procedure ShowLocatorMapInBrowser(locator: string);
    procedure LoadBandsSettings;
    procedure FillBandCombo(cmb : TComboBox);
    procedure ShowHamQTHInBrowser(call : String);
    procedure ShowUsrUrl;
    procedure SortArray(l,r : Integer);
    procedure OpenInApp(what : String);
    procedure LoadRigsToComboBox(CurrentRigId : String; RigCtlBinaryPath : String; RigComboBox : TComboBox);
    procedure GetShorterCoordinates(latitude,longitude : Currency; var lat, long : String);
    procedure LoadListOfFiles(Path, Mask : String; ListOfFiles : TStringList);
    procedure BandFromDbase;
    procedure UpdateHelpBrowser;
    procedure ModeFromCqr(CqrMode:String;var OutMode,OutSubmode:String;dbg:Boolean);
    procedure UpdateCallBookcnf;
    procedure ClearStatGrid(g:TStringGrid);
    procedure AddBandsToStatGrid(g:TStringGrid);
    procedure ShowStatistic(ref_adif,old_stat_adif:Word; g:TStringGrid; call:String='');

    function  BandFromArray(tmp:Currency):string;
    function  MyDefaultBrowser:String;
    function  StrToDateFormat(sDate : String) : TDateTime;
    function  DateToSQLIteDate(date : TDateTime) : String;
    function  GetBandFromFreq(MHz : string): String;
    function  LetterFromMode(mode : String) : String;
    function  DateToFilterDate(date : TDateTime) : String;
    function  ADIFDateToDate(date : String) : String;
    function  IsModeOK(mode : String) : Boolean;
    function  IsTimeOK(time : String) : Boolean;
    function  Explode(const cSeparator, vString: String): TExplodeArray;
    function  MyDateToStr(Date : TDateTime) : String;
    function  MyStrToDate(date : String) : TDateTime;
    function  GetDateTime(delta : Currency) : TDateTime;
    function  IsLocOK(loc : String) : Boolean;
    function  CompleteLoc(loc : String) : String;
    function  HisDateTime(pfx : String) : String;
    function  IsDateOK(date : String) : Boolean;
    function  IsAdifOK(qsodate,time_on,time_off,call,freq,mode,rst_s,rst_r,iota,
                       itu,waz,loc,my_loc,band : String; var error : String) : Boolean;
    function  IsFreqOK(freq : String) : boolean;
    function  FreqFromBand(band,mode : String) : String;
    function  RemoveSpaces(S : String) : String;
    function  StripHTML(S: string): string;
    function  ExtractQTH( qth : String) : String;
    function  GetModeFromFreq(freq : String) : String;
    function  FromJS8CALLToAdif(buf:string):string;
    function  FromN1MMToAdif(buf:string):string;
    function  StringToADIF(ATag, Text : String) : String;
    function  MyTrim(text : String) : String;
    function  ReplaceSpace(txt : String) : String;
    function  ReplaceEnter(txt : String) : String;
    function  MyStrToFloat(num : String) : Extended;
    function  ExtractQSLMgr(text : String) : String;
    function  ExtractPower(power : String) : String;
    function  ExtractFontSize(sFont : String) : Integer;
    function  ExtractCallsign(call : String) : String;
    function  GetGreetings(time : String) : String;
    function  IsIOTAOK(iota : String) : Boolean;
    function  SetSize(text : String;Len : Integer) : String;
    function  SetSizeLeft(text : String;Len : Integer) : String;
    function  MonthToStr(mon : Integer) : String;
    function  GetIDCall(callsign : String) : String;
    function  ExtractIOTAPrefix(call : String; date : TDateTime) : String;
    function  IncludesNum(text : String) : Boolean;
    function  GetRigError(err : Integer) : String;
    function  IncColor(AColor: TColor; AQuantity: Byte) : TColor;
    function  IsItIOTA(spot : String) : Boolean;
    function  GetXplanetCommand : String;
    function  GetLastUpgradeDate : TDateTime;
    function  UnTarFiles(FileName,TargetDir : String) : Boolean;
    function  ExtractZipCode(qth : String; Position : Integer) : String;
    function  GetLabelBand(freq : String) : String;
    function  GetAdifBandFromFreq(MHz : string): String;
    function  GetCWMessage(Key,call,rst_s,stx,stx_str,srx,srx_str,HisName,HelloMsg, text: String) : String;
    function  RigGetcmd(r : String): String;
    function  GetLastQSLUpgradeDate : TDateTime;
    function  GetLastDOKUpgradeDate : TDateTime;
    function  CallTrim(call : String) : String;
    function  GetQSLVia(text : String) : String;
    function  IsQSLViaValid(text : String) : Boolean;
    function  GetShortState(state : String) : String;
    function  GetCallAttachDir(call : String) : String;
    function  GetApplicationName(FileExt : String) : String;
    function  FindInMailCap(mime : String) : String;
    function  GetHomeDirectory : String;
    function  DateInRightFormat(date : TDateTime) : String;
    function  QSLFrontImageExists(fCall : String) : String;
    function  QSLBackImageExists(fCall : String) : String;
    function  GetCallForAttach(call : String) : String;
    function  IsValidFileName(const fileName : string) : boolean;
    function  GetBandPos(band : String) : Integer;
    function  GetNewQSOCaption(capt : String) : String;
    function  GetCallBookData(call : String; var nick,qth,address,zip,grid,state,county,qsl,iota,waz,itu,dok,ErrMsg : String) : Boolean;
    function  DateInSOTAFormat(date : TDateTime) : String;
    function  GetLocalUTCDelta : Double;
    function  GetRadioRigCtldCommandLine(radio : Word) : String;
    function  GetRotorRotCtldCommandLine(rotor : Word) : String;
    function  IgnoreFreq(kHz : String) : Boolean;
    function  HTMLEncode(const Data: string): string;
    function  KmToMiles(qra : Double) : Double;
    function  GetDescKeyFromCode(key : Word) : String;
    function  EncodeURLData(data : String) : String;
    function  GetRigIdFromComboBoxItem(ItemText : String) : String;
    function  GetDataFromHttp(Url : String; var data : String) : Boolean;
    function  MyStrToDateTime(DateTime : String) : TDateTime;
    function  MyDateTimeToStr(DateTime : TDateTime) : String;
    function  LoadVisibleColumnsConfiguration :  TColumnVisibleArray;
    function  StdFormatLocator(loc:string):String;
    function  IsHeDx(call:String; CqDir:String = ''):boolean;
    function  ModeToCqr(InMode,InSubmode:String;dbg:boolean=False):String;


end;

var
  dmUtils: TdmUtils;

implementation
  {$R *.lfm}

{ TdmUtils }
uses dData, dDXCC, fEnterFreq, fTRXControl, uMyini, fNewQSO, uVersion, fContest;

function TdmUtils.LetterFromMode(mode: string): string;
begin
  if (mode = 'CW') or (mode = 'CWQ') then
    Result := 'C'
  else
  begin
    if (mode = 'FM') or (mode = 'SSB') or (mode = 'AM') then
      Result := 'F'
    else
      Result := 'D';
  end;
end;
Procedure TdmUtils.BandFromDbase;
var
  BandCount: integer;
Begin
  BandCount := 0;
  dmData.qBands.Close;
  dmData.qBands.SQL.Text := 'SELECT * FROM cqrlog_common.bands ';
  if dmData.trBands.Active then
    dmData.trBands.Rollback;
  dmData.trBands.StartTransaction;
  try
    dmData.qBands.Open;
    while not dmData.qBands.Eof  do
     Begin
       BandFreq[BandCount].band:= dmData.qBands.FieldByName('band').AsString;
       BandFreq[BandCount].b_begin:=dmData.qBands.FieldByName('b_begin').AsCurrency;
       BandFreq[BandCount].b_end:=dmData.qBands.FieldByName('b_end').AsCurrency;
       inc(BandCount);
       dmData.qBands.Next;
     end;
  finally
    dmData.qBands.Close;
    dmData.trBands.Rollback
  end;
end;
function TdmUtils.BandFromArray(tmp:Currency):string;
var
   x:integer;
Begin
  result:='';
   for x:=0 to  (cMaxBandsCount - 1 ) do
      Begin
           if (tmp >= dmUtils.BandFreq[x].b_begin )
             and (tmp <= dmUtils.BandFreq[x].b_end ) then
                Begin
                   Result := dmUtils.BandFreq[x].band;
                   exit;
                end;
      end;
end;

function TdmUtils.GetModeFromFreq(freq: string): string; //freq in MHz
var
  Band: string;
  tmp: extended;
begin
  Result := '';
  band := GetBandFromFreq(freq);
  dmData.qBands.Close;
  dmData.qBands.SQL.Text := 'SELECT * FROM cqrlog_common.bands WHERE band = ' +
    QuotedStr(band);
  if dmData.trBands.Active then
    dmData.trBands.Rollback;
  dmData.trBands.StartTransaction;
  try
    dmData.qBands.Open;
    tmp := StrToFloat(freq);
    if dmData.qBands.RecordCount > 0 then
    begin
      if ((tmp >= dmData.qBands.FieldByName('B_BEGIN').AsCurrency) and
        (tmp <= dmData.qBands.FieldByName('CW').AsCurrency)) then
        Result := 'CW'
      else
      begin
        if ((tmp > dmData.qBands.FieldByName('RTTY').AsCurrency) and
          (tmp <= dmData.qBands.FieldByName('SSB').AsCurrency)) then
          Result := 'RTTY';

        if ((tmp > dmData.qBands.FieldByName('SSB').AsCurrency) and
          (tmp <= dmData.qBands.FieldByName('B_END').AsCurrency)) then
        begin
          if (tmp > 5) and (tmp < 6) then
            Result := 'USB'
          else begin
            if tmp > 10 then
              Result := 'USB'
            else
              Result := 'LSB'
          end
        end
      end
    end
  finally
    dmData.qBands.Close;
    dmData.trBands.Rollback
  end;
end;

function TdmUtils.GetBandFromFreq(MHz: string): string;
var
  x: integer;
  tmp: currency;
  Dec: currency;
  band: string;
begin
  Result := '';
  band := '';
  if Pos('.', MHz) > 0 then
    MHz[Pos('.', MHz)] := FormatSettings.DecimalSeparator;

  if pos(',', MHz) > 0 then
    MHz[pos(',', MHz)] := FormatSettings.DecimalSeparator;

  if not TryStrToCurr(MHz, tmp) then
    exit
   else
    Result := BandFromArray(tmp);
end;

function TdmUtils.GetAdifBandFromFreq(MHz: string): string;
var
  x: integer;
  tmp: currency;
  Dec: currency;
  band: string;
begin
  Result := '';
  band := '';
  if Pos('.', MHz) > 0 then
    MHz[Pos('.', MHz)] := FormatSettings.DecimalSeparator;

  if pos(',', MHz) > 0 then
    MHz[pos(',', MHz)] := FormatSettings.DecimalSeparator;

  if not TextToFloat(PChar(MHZ), tmp, fvCurrency) then
    exit
   else Result := BandFromArray(tmp);
end;

procedure TdmUtils.SaveForm(aForm: TForm);
var
  Grid: TDBGrid;
  Section, Ident: string;
  i, j, y: integer;
  l: TStringList;
begin
  if dmData.DBName = '' then
    exit;
  if dmData.DebugLevel >= 1 then
    Writeln('SaveForm: ', aForm.Name);
  l := TStringList.Create;
  try
    for i := 0 to aForm.ComponentCount - 1 do
    begin
      if aForm.Components[i] is TDBGrid then
      begin
        Grid := aForm.Components[i] as TDBGrid;
        Section := aForm.Name + '_' + Grid.Name;
        l.Clear;
        cqrini.ReadSection(Section, l,cqrini.LocalOnly('WindowSize'));
        l.Text := Trim(l.Text);
        if l.Text <> '' then
        begin //delete old settings
          for y := 0 to l.Count - 1 do
            cqrini.DeleteKey(Section, l[y],cqrini.LocalOnly('WindowSize'))
        end;
        for j := 0 to Grid.Columns.Count - 1 do
        begin
          Ident := TColumn(Grid.Columns[j]).FieldName;
          cqrini.WriteString(Section, Ident, IntToStr(Grid.Columns[j].Width),cqrini.LocalOnly('WindowSize'))
          // Writeln('Saving:  Section: ',Section,' Ident: ',Ident,' Width: ',Grid.Columns[j].Width)
        end
      end
    end
  finally
    l.Free;
    cqrini.SaveToDisk
  end
end;

procedure TdmUtils.LoadForm(aForm: TForm);
var
  Grid: TDBGrid;
  Section, Ident: string;
  i: integer;
  l: TStringList;
  y: integer;
  D: TDataSource;
begin
  if dmData.DebugLevel >= 1 then
    Writeln('LoadForm: ', aForm.Name);
  l := TStringList.Create;
  try
    for i := 0 to aForm.ComponentCount - 1 do
    begin
      if (aForm.Components[i] is TDBGrid) then
      begin
        Grid := (aForm.Components[i] as TDBGrid);
        Section := aForm.Name + '_' + Grid.Name;
        l.Clear;
        cqrini.ReadSection(Section, l, cqrini.LocalOnly('WindowSize'));
        l.Text := Trim(l.Text);
        if l.Text = '' then
          exit;
        D := Grid.DataSource;
        Grid.DataSource := nil;
        Grid.BeginUpdate;
        try
          Grid.Columns.Clear;
          for y := 0 to l.Count - 1 do
          begin
            Ident := l[y];
            Grid.Columns.Add.DisplayName := Ident;
            TColumn(Grid.Columns[y]).FieldName := Ident;
            Grid.Columns[y].Width := cqrini.ReadInteger(section, Ident, 100, cqrini.LocalOnly('WindowSize'))
            // Writeln('Loading:  Section: ',Section,' Ident: ',Ident,' Width: ',Grid.Columns[y].Width)
          end
        finally
          Grid.DataSource := D;
          Grid.EndUpdate()
        end
      end
    end
  finally
    //cqrini.SaveToDisk; WHY we save when load? Is this unchecked direct copy from SaveForm source abowe?
                      // There is no cqrini writing done, so why need to save?
    l.Free
  end
end;


procedure TdmUtils.DataModuleCreate(Sender: TObject);
begin
  fQRZSession := '';
  //this overrides dmUtils.lfm setings
  HelpDatabase.BaseURL := 'file://' + dmData.HelpDir;
  //check of user defined HelpViever (other than xdg-open as default) is done at fNewQSO
  USstates[1] := 'AK, Alaska';
  USstates[2] := 'AL, Alabama';
  USstates[3] := 'AR, Arkansas';
  USstates[4] := 'AZ, Arizona';
  USstates[5] := 'CA, California';
  USstates[6] := 'CO, Colorado';
  USstates[7] := 'CT, Connecticut';
  USstates[8] := 'DE, Delaware';
  USstates[9] := 'FL, Florida';
  USstates[10] := 'GA, Georgia';
  USstates[11] := 'HI, Hawaii';
  USstates[12] := 'IA, Iowa';
  USstates[13] := 'ID, Idaho';
  USstates[14] := 'IL, Illinois';
  USstates[15] := 'IN, Indiana';
  USstates[16] := 'KS, Kansas';
  USstates[17] := 'KY, Kentucky';
  USstates[18] := 'LA, Louisiana';
  USstates[19] := 'MA, Massachusetts';
  USstates[20] := 'MD, Maryland';
  USstates[21] := 'ME, Maine';
  USstates[22] := 'MI, Michigan';
  USstates[23] := 'MN, Minnesota';
  USstates[24] := 'MO, Missouri';
  USstates[25] := 'MS, Mississippi';
  USstates[26] := 'MT, Montana';
  USstates[27] := 'NC, North Carolina';
  USstates[28] := 'ND, North Dakota';
  USstates[29] := 'NE, Nebraska';
  USstates[30] := 'NH, New Hampshire';
  USstates[31] := 'NJ, New Jersey';
  USstates[32] := 'NM, New Mexico';
  USstates[33] := 'NV, Nevada';
  USstates[34] := 'NY, New York';
  USstates[35] := 'OH, Ohio';
  USstates[36] := 'OK, Oklahoma';
  USstates[37] := 'OR, Oregon';
  USstates[38] := 'PA, Pennsylvania';
  USstates[39] := 'RI, Rhode Island';
  USstates[40] := 'SC, South Carolina';
  USstates[41] := 'SD, South Dakota';
  USstates[42] := 'TN, Tennessee';
  USstates[43] := 'TX, Texas';
  USstates[44] := 'UT, Utah';
  USstates[45] := 'VA, Virginia';
  USstates[46] := 'VT, Vermont';
  USstates[47] := 'WA, Washington';
  USstates[48] := 'WI, Wisconsin';
  USstates[49] := 'WV, West Virginia';
  USstates[50] := 'WY, Wyoming';

  ModeConvListsCreate(True);
end;

procedure TdmUtils.DataModuleDestroy(Sender: TObject);
begin
  ModeConvListsCreate(False);
end;

procedure TdmUtils.InsertContests(cmbContestName: TComboBox);
var
    ListOfContests : TStringList;
    s: string;
    Contestfile :TextFile;
begin
  // loading the contest list from ~/.config/cqrlog/ContestNames.tab
  // Format of File   CONTEST_ID|CONTEST_DESCRIPTION
  // see ADIF 3.0.9 http://www.adif.org/309/ADIF_309.htm#Contest_ID
  // File have to be UTF8 without BOM
  ListOfContests:= TStringList.Create;
  ListOfContests.Clear;
  ListOfContests.Sorted:=True;
  if FileExists(dmData.HomeDir + C_CONTEST_LIST_FILE_NAME) then
  begin
       ListOfContests.LoadFromFile(dmData.HomeDir + C_CONTEST_LIST_FILE_NAME);
       cmbContestName.Clear;
       cmbContestName.Items := ListOfContests;
       cmbContestName.Items.Insert(0,'');
  end;
  ListOfContests.Free;
end;
procedure TdmUtils.InsertModes(cmbMode: TComboBox);
var
  i: integer;
  a: TExplodeArray;
begin
  cmbMode.Clear;
  if cqrini.ReadString('NewQSO', 'Modes', '') <> '' then
  begin
    SetLength(a, 0);
    a := Explode('|', cqrini.ReadString('NewQSO','Modes',''));
    for i := 0 to Length(a) - 1 do
      if(a[i] <> '') then
        cmbMode.Items.Add(a[i])
  end
  else begin
    for i := 0 to cMaxModes do
    cmbMode.Items.Add(cModes[i]);
  end;
  if cqrini.ReadString('Modes', 'Digi', '') <> '' then
  begin
    SetLength(a, 0);
    a := Explode(',', cqrini.ReadString('Modes', 'Digi', ''));
    for i := 0 to Length(a) - 1 do
      cmbMode.Items.Add(a[i]);
  end;
end;

procedure TdmUtils.InsertQSL_S(QSL_S: TComboBox);
begin
  QSL_S.Clear;
  QSL_S.Items.Add('');
  QSL_S.Items.Add('B');
  QSL_S.Items.Add('D');
  QSL_S.Items.Add('E');
  QSL_S.Items.Add('M');
  QSL_S.Items.Add('N');
  QSL_S.Items.Add('MD');
  QSL_S.Items.Add('MB');
  QSL_S.Items.Add('PE');
  QSL_S.Items.Add('SB');
  QSL_S.Items.Add('SD');
  QSL_S.Items.Add('SE');
  QSL_S.Items.Add('SM');
  QSL_S.Items.Add('SMD');
  QSL_S.Items.Add('SMB');
  QSL_S.Items.Add('SPE');
  QSL_S.Items.Add('OR');
  QSL_S.Items.Add('OQRS');
end;

procedure TdmUtils.InsertQSL_R(QSL_R: TComboBox);
begin
  QSL_R.Clear;
  QSL_R.Items.Add('');
  QSL_R.Items.Add('Q');
  QSL_R.Items.Add('!');
end;

procedure TdmUtils.InsertFreq(cmbFreq: TcomboBox);
var
  a: TExplodeArray;
  i: integer;
begin
  cmbFreq.Clear;
  a := Explode('|', cqrini.ReadString('NewQSO', 'FreqList', cDefaultFreq));
  for i := 0 to Length(a) - 1 do
    if a[i] <> '' then
      cmbFreq.Items.Add(a[i]);
end;

procedure TdmUtils.InsertBands(cmbBand: TComboBox);
var
  i: integer;
begin
  cmbBand.Clear;
  for i := 0 to cMaxBandsCount - 2 do
    cmbBand.Items.Add(cBands[i]);
end;

procedure TdmUtils.InsertWorkedContests(cmbContest: TComboBox);
var
  i: integer;
const
  C_SEL = 'SELECT DISTINCT `contestname` FROM `cqrlog_main` WHERE `contestname` IS NOT NULL and `contestname` != "" ORDER BY `contestname` ASC';
begin
  cmbContest.Clear;
  dmData.qWorkedContests.Close;
  try
   dmData.qWorkedContests.SQL.Text := 'SET CHARACTER SET "utf8"';
   dmData.qWorkedContests.ExecSQL;
   dmData.qWorkedContests.SQL.Text := C_SEL;
    if dmData.DebugLevel >=1 then
      Writeln(dmData.qWorkedContests.SQL.Text);
    dmData.qWorkedContests.Open;
    while not dmData.qWorkedContests.EOF do
    begin
      if dmData.DebugLevel >= 1 then
        Writeln('Contest: ' + dmData.qWorkedContests.Fields[0].AsString);
      cmbContest.Items.Add(dmData.qWorkedContests.Fields[0].AsString);
    dmData.qWorkedContests.Next
    end;
  finally
    dmData.qWorkedContests.Close;
  end;
end;

function TdmUtils.DateInRightFormat(date: TDateTime): string;
var
  tmp: string;
  rDate: string;
begin
  DateInRightFormat(date, tmp, rDate);
  Result := rDate;
end;


procedure TdmUtils.DateInRightFormat(date: TDateTime; var Mask, sDate: string);
var
  Sep: char;
begin
  sep := FormatSettings.DateSeparator;
  try
    Mask := '9999-99-99';
    FormatSettings.DateSeparator := '-';
    sDate := FormatDateTime('YYYY-MM-DD', date)
  finally
    FormatSettings.DateSeparator := sep
  end;
  {

  case iMask of
    0 : begin
          DateSeparator := '/';
          Mask  := '9999/99/99'; //yyyy/mm/dd
          sDate := FormatDateTime('YYYY/MM/DD',date);
        end;
    1 : begin
          DateSeparator := '.';
          Mask  := '99.99.9999'; //dd.mm.yyyy
          sDate := FormatDateTime('DD.MM.YYYY',date);
        end;
    2 : begin
          DateSeparator := '/';
          Mask  := '99/99/9999'; //dd/mm/yyyy
          sDate := FormatDateTime('DD/MM/YYYY',date);
        end;
  end; //case
  DateSeparator := sep;
  }
end;

function TdmUtils.MyDefaultBrowser:String;
var
  v: THTMLBrowserHelpViewer;
  BrowserPath, BrowserParams: string;
begin
  v:=THTMLBrowserHelpViewer.Create(nil);
  v.FindDefaultBrowser(BrowserPath,BrowserParams);
  result := BrowserPath;
  v.Free;
end;

function TdmUtils.StrToDateFormat(sDate: string): TDateTime;
var
  sdf: string;
  Sep: char;
begin
  sdf := FormatSettings.ShortDateFormat;
  sep := FormatSettings.DateSeparator;
  try
    FormatSettings.ShortDateFormat := 'YYYY-MM-DD';
    FormatSettings.DateSeparator := '-';
    Result := StrToDateTime(sDate)
  finally
    FormatSettings.ShortDateFormat := sdf;
    FormatSettings.DateSeparator := sep
  end;


  {case iMask of
    0 : begin
          DateSeparator := '/';
          ShortDateFormat := 'YYYY/MM/DD';
          Result := StrToDateTime(sDate);
        end;
    1 : begin
          DateSeparator := '.';
          ShortDateFormat := 'DD.MM.YYYY';
          Result := StrToDateTime(sDate);
        end;
    2 : begin
          DateSeparator := '/';
          ShortDateFormat := 'DD/MM/YYYY';
          Result := StrToDateTime(sDate);
        end;
  end; //case
  }
end;


function TdmUtils.DateToSQLIteDate(date: TDateTime): string;
var
  ds: char;
begin
  ds := FormatSettings.DateSeparator;
  try
    FormatSettings.DateSeparator := '-';
    Result := FormatDateTime('YYY-MM-DD', date)
  finally
    FormatSettings.DateSeparator := ds
  end;
end;

procedure TdmUtils.FileCopy(const FileFrom, FileTo: string);
var
  FromF, ToF: file;
  NumRead : Word = 0;
  NumWritten: Word = 0;
  Buffer: array[1..2048] of byte;
begin
  AssignFile(FromF, FileFrom);
  Reset(FromF, 1);
  AssignFile(ToF, FileTo);
  Rewrite(ToF, 1);
  repeat
    BlockRead(FromF, Buffer, SizeOf(Buffer), NumRead);
    BlockWrite(ToF, Buffer, NumRead, NumWritten);
  until (NumRead = 0) or (NumWritten <> NumRead);
  CloseFile(FromF);
  CloseFile(ToF);
end;


procedure TdmUtils.CopyData(Source, Destination: string);
var
  res: byte;
  SearchRec: TSearchRec;
begin
  if (Length(Source) = 0) or (Length(Destination) = 0) then
    exit;
  if Source[Length(Source)] <> '/' then
    Source := Source + '/';
  if Destination[Length(Destination)] <> '/' then
    Destination := Destination + '/';

  if not DirectoryExists(Destination) then
    CreateDir(Destination);
  res := FindFirst(Source + '*.*', faAnyFile, SearchRec);
  while Res = 0 do
  begin
    if (Pos('.', SearchRec.Name) > 1) then
      FileCopy(Source + SearchRec.Name, Destination + SearchRec.Name);
    Res := FindNext(SearchRec);
    //Application.ProcessMessages;
  end;
  FindClose(SearchRec);
end;

procedure TdmUtils.DeleteData(Directory: string);
var
  res: byte;
  SearchRec: TSearchRec;
begin
  if (Length(Directory) = 0) then
    exit;
  if Directory[Length(Directory)] <> '/' then
    Directory := Directory + '/';

  res := FindFirst(Directory + '*.*', faAnyFile, SearchRec);
  while Res = 0 do
  begin
    if FileExists(Directory + SearchRec.Name) then
      DeleteFile(Directory + SearchRec.Name);
    Res := FindNext(SearchRec);
    //Application.ProcessMessages;
  end;
  FindClose(SearchRec);
end;

function TdmUtils.DateToFilterDate(date: TDateTime): string;
var
  d, m, y: word;
  sd, sm, sy: string;
begin
  DecodeDate(Date, y, m, d);
  sy := IntToStr(y);
  if Length(sy) = 1 then
    sy := '0' + sy;
  sm := IntToStr(m);
  if Length(sm) = 1 then
    sm := '0' + sm;
  sd := IntToStr(d);
  if Length(sd) = 1 then
    sd := '0' + sd;

  Result := sy + sm + sd;
end;

function TdmUtils.ADIFDateToDate(date: string): string;
var
  d, m, y: string;
begin
  if (date = '') then
    Result := ''
  else
  begin
    y := Date[1] + Date[2] + Date[3] + Date[4];
    m := Date[5] + Date[6];
    d := Date[7] + Date[8];
    Result := y + '-' + m + '-' + d;
  end;
end;


function TdmUtils.IsModeOK(mode: string): boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to cMaxModes do
  begin
    if mode = cModes[i] then
    begin
      Result := True;
      Break;
    end;
  end;
  if Pos(mode + ',', cqrini.ReadString('Modes', 'Digi', '') + ',') > 0 then
    Result := True;
end;

function TdmUtils.IsTimeOK(time: string): boolean;
var
  imin, ihour: integer;
begin
  imin := 0;
  ihour := 0;
  Result := True;
  if length(time) <> 5 then
    Result := False
  else
  begin
    if not ((TryStrToInt(time[1] + time[2], ihour)) and
      TryStrToInt(time[4] + time[5], imin)) then
      Result := False
    else
    begin
      if ihour > 24 then
        Result := False;
      if imin > 59 then
        Result := False;
    end;
  end;
end;

procedure TdmUtils.SaveLog(Text: string);
var
  f: TextFile;
begin

  AssignFile(f, dmData.DataDir + 'log.dat');
  if not FileExists(dmData.DataDir + 'log.dat') then
    Rewrite(f)
  else
    Append(f);
  Text := DateTimeToStr(now) + ' ' + TimeToStr(now) + ' ' + Text;
  Writeln(f, Text);
  CloseFile(f);
end;

function TdmUtils.Explode(const cSeparator, vString: string): TExplodeArray;
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
    S := Copy(S, Pos(cSeparator, S) + Length(cSeparator), Length(S));
  end;
  SetLength(Result, Length(Result) + 1);
  Result[i] := Copy(S, 1, Length(S));
end;

function TdmUtils.MyDateToStr(Date: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd', Date);
end;

function TdmUtils.MyStrToDate(date: string): TDateTime;
var
  tmp: string;
begin
  tmp := FormatSettings.ShortDateFormat;
  try
    FormatSettings.ShortDateFormat := 'YYYY-MM-DD';
    try
      Result := StrToDate(date)
    except
      Result := StrToDate('1980-01-01')
    end
  finally
    FormatSettings.ShortDateFormat := tmp
  end;
end;

function TdmUtils.GetDateTime(delta: currency): TDateTime;
var
  tv: ttimeval;
  res: longint;
begin
  if dmUtils.SysUTC then
  begin
    fpgettimeofday(@tv, nil);
    res := tv.tv_sec;
    Result := (res / 86400) + 25569.0;  // Same line as used in Unixtodatetime
    if delta <> 0 then
      Result := Result - (delta / 24);
  end
  else
  begin
    Result := now;
    delta := delta + fTimeOffset;
    if delta <> 0 then
      Result := Result - (delta / 24);
  end;
end;

function TdmUtils.CompleteLoc(loc: string): string;
begin
  //we will fix even length locators from length 2 .. X  and return them as length of 6
  //length 8, and up, loc is cutted to length 6
  //Odd length loc is not touched to see error later
  if (loc<>'') then
   begin
     loc := trim(loc);
     if  (Length(loc) mod 2 = 0 ) then
       begin
         case  Length(loc) of
           2:              loc := loc + '44LL';
           4:              loc := loc + 'LL';
           else
             loc := copy(loc,1,6);
         end;
       end;
   end;
  Result := loc;
end;

function TdmUtils.IsLocOK(Loc: string): boolean;
var
  i,
  r : integer;
begin
  r:=0;
  loc := CompleteLoc(loc);   //does not fix empty or odd length, otherwise sets length of 6
  if  Length(loc) = 6  then  //length should be now 6 if passed this far
   begin
     Loc := UpCase(Loc);
     for i := 1 to 6 do
        begin
          case i of
            1, 2 : case Loc[i] of
                        'A'..'R':  inc(r);
                   end;
            3, 4 : case Loc[i] of
                        '0'..'9':  inc(r);
                   end;
            5, 6 : case Loc[i] of
                        'A'..'X':  inc(r);
                   end;
          end;
       end;
   end;
  Result := (r = 6);
end;
function TdmUtils.StdFormatLocator(loc:string):String;
// Format locator to standard form BL11bh16 See:
// https://en.wikipedia.org/wiki/Maidenhead_Locator_System#Description_of_the_system
// Check TEdit CharCase to be ecNormal, othewise you get runtime error!
var
  s :String;
begin
  Result := loc;
  if loc = '' then exit;
  s :=  Upcase(copy(loc,1,4));
  s:= s + lowercase(copy(loc,5,6));   //max loc length 10 in database
  Result := trim(s);
end;

procedure TdmUtils.GetCoordinate(pfx: string; var latitude, longitude: currency);
var
  s, d: string;
begin
  //dmDXCC.trDXCCRef.StartTransaction;
  dmDXCC.qDXCCRef.Close;
  dmDXCC.qDXCCRef.SQL.Text := 'SELECT * FROM cqrlog_common.dxcc_ref WHERE pref=' +
    QuotedStr(pfx);
  dmDXCC.qDXCCRef.Open;
  s := dmDXCC.qDXCCRef.Fields[4].AsString;
  d := dmDXCC.qDXCCRef.Fields[5].AsString;

  if ((Length(s) = 0) or (Length(d) = 0)) then
  begin
    longitude := 0;
    latitude := 0;
    exit;
  end;
  GetRealCoordinate(s, d, latitude, longitude);
end;

procedure TdmUtils.DistanceFromCoordinate(my_loc: string; latitude, longitude: real;
  var qra, azim: string);
var
  loc: string;
  qra1: string;
  azim1: string;
begin
  if not IsLocOK(my_loc) then
    exit;

  loc := VratLokator(latitude, longitude);
  if not IsLocOK(loc) then
    exit;

  VzdalenostAAzimut(my_loc, loc, azim1, qra1);
  qra := qra1;
  azim := azim1;
end;

procedure TdmUtils.DistanceFromLocator(my_loc, his_loc: string; var qra, azim: string);
var
  qra1: string;
  azim1: string;
begin
  if not IsLocOK(my_loc) then
    exit;
  if not IsLocOK(his_loc) then
    exit;
  VzdalenostAAzimut(my_loc, his_loc, azim1, qra1);
  qra := qra1;
  azim := azim1;
end;

procedure TdmUtils.DistanceFromPrefixMyLoc(my_loc, pfx: string; var qra, azim: string);
var
  latitude, longitude: currency;
begin
  latitude := 0;
  longitude := 0;
  if (pfx = '') then
    exit;
  GetCoordinate(pfx, latitude, longitude);
  DistanceFromCoordinate(my_loc, latitude, longitude, qra, azim);
end;

function TdmUtils.HisDateTime(pfx: string): string;
var
  delta: string;
  fdelta: currency;
  date: TDateTime;
  sDate: string;
  tmp: string;
begin
  sDate := '';
  fDelta := 0;
  Result := '';
  tmp := '';
  dmDXCC.qDXCCRef.Close;
  dmDXCC.qDXCCRef.SQL.Text := 'SELECT utc FROM cqrlog_common.dxcc_ref WHERE pref = ' +
    QuotedStr(pfx);
  dmDXCC.qDXCCRef.Open;
  if dmDXCC.qDXCCRef.RecordCount > 0 then
  begin
    delta := dmDXCC.qDXCCRef.Fields[0].AsString;
    if not TryStrToCurr(delta, fdelta) then
      delta := '0';
    Date := dmUtils.GetDateTime(StrToCurr(delta));
    dmUtils.DateInRightFormat(date, tmp, sDate);
    Result := sDate + '  ' + TimeToStr(Date) + '     ';
  end;
end;

procedure TdmUtils.ModifyWAZITU(var waz, itu: string);
begin
  if Pos('-', itu) > 0 then
    itu := copy(itu, 1, Pos('-', itu) - 1);
  if Length(itu) = 1 then
    itu := '0' + itu;
  if Pos('-', waz) > 0 then
    waz := copy(waz, 1, Pos('-', waz) - 1);
  if Length(waz) = 1 then
    waz := '0' + waz;
  waz := copy(waz, 1, 2);
  itu := Copy(itu, 1, 2);
end;

function TdmUtils.IsDateOK(date: string): boolean;
var
  tmp: string;

//OH1KH:  this 230-0010-20 passes as 2023-01-20 !!!   We have to do something for this !!

begin
  if date = '' then
  begin
    Result := False;
    exit;
  end;
  Result := True;

//check separator places first
  if (date[5]<>'-') or (date[8]<>'-') then
                                         Result:=false;

  tmp := FormatSettings.ShortDateFormat;
  try
    FormatSettings.ShortDateFormat := 'YYYY-MM-DD';
    try
      StrToDate(date)
    except
      Result := False
    end
  finally
    FormatSettings.ShortDateFormat := tmp
  end;
end;

function TdmUtils.IsFreqOK(freq: string): boolean;
begin
  if GetBandFromFreq(freq) <> '' then
    Result := True
  else
    Result := False;
end;

function TdmUtils.FreqFromBand(band, mode: string): string;
begin
  Result := '';
  mode := LowerCase(mode);
  band := UpperCase(band);

  if mode='' then
     mode:='b_begin'
   else
    case mode of
     'usb','lsb',
     'fm','am',
     'ssb'       : mode:='ssb';
     'cw'        : mode:='cw';
      else
       mode:='rtty'  //this covers all modes not phone or cw
    end;

  dmData.qBands.Close;
  dmData.qBands.SQL.Text := 'SELECT '+mode+' FROM cqrlog_common.bands WHERE band = ' + QuotedStr(band);
  if dmData.DebugLevel >=1 then
     Writeln(dmData.qBands.SQL.Text);

  if dmData.trBands.Active then
    dmData.trBands.Rollback;
  dmData.trBands.StartTransaction;
  try
    dmData.qBands.Open;
    if dmData.qBands.RecordCount > 0 then
      Result:= dmData.qBands.FieldByName(mode).AsString;
  finally
    if dmData.DebugLevel >=1 then
     Writeln('FreqFromBand('+band+','+mode+')='+Result);
    dmData.qBands.Close;
    dmData.trBands.Rollback
  end;

end;

function TdmUtils.IsAdifOK(qsodate, time_on, time_off, call, freq, mode, rst_s, rst_r, iota,
  itu, waz, loc, my_loc, band: string;
  var error: string): boolean;
var
  w: integer;
begin
  w := 0;
  Result := True;
  error := '';
  if not IsDateOK(qsodate) then
  begin
    Result := False;
    error := 'Wrong QSO date: ' + qsodate;
    exit;
  end;

  if (GetBandFromFreq(freq) = '') then
  begin
    Result := False;
    error := 'Wrong frequency:' + freq;
    exit;
  end;

  if call = '' then
  begin
    Result := False;
    error := 'Wrong QSO call: ' + call;
    exit;
  end;

  if Pos('/', mode) = 0 then
  begin
    if not IsModeOK(mode) then
    begin
      Result := False;
      error := 'Wrong QSO mode: ' + mode;
      exit;
    end;
  end;

  if waz <> '' then
  begin
    if not TryStrToInt(waz, w) then
    begin
      error := 'Wrong QSO waz zone: ' + waz;
      Result := False;
      exit;
    end;
  end;

  if itu <> '' then
  begin
    if not TryStrToInt(itu, w) then
    begin
      Result := False;
      error := 'Wrong QSO itu: ' + itu;
      exit;
    end;
  end;

  if loc <> '' then
  begin
    loc := CompleteLoc(loc);
    if not IsLocOK(loc) then
    begin
      Result := False;
      error := 'Wrong QSO loc: ' + loc;
      exit;
    end;
  end;

  if my_loc <> '' then
  begin
    my_loc := CompleteLoc(my_loc);
    if not IsLocOK(my_loc) then
    begin
      Result := False;
      error := 'Wrong QSO my loc: ' + my_loc;
      exit;
    end;
  end;

  if (iota <> '') then
  begin
    if not dmUtils.IsIOTAOK(iota) then
    begin
      Result := False;
      error := 'Wrong QSO IOTA: ' + iota;
      exit;
    end;
  end;

end;

function TdmUtils.nr(ch: char): integer;
var
  letters: string;
begin
  letters := 'ABCDEFGHIJKLMNOPQRSTUVWX';
  Result := Pos(ch, letters);
end;

procedure TdmUtils.CoordinateFromLocator(loc: string;
  var latitude, longitude: currency);
var
  a, b, c, d, e, f: integer;
begin
  if not IsLocOK(loc) then
    exit;

  a := nr(loc[1]);
  b := nr(loc[2]);
  c := StrToInt(loc[3]);
  d := StrToInt(loc[4]);
  e := nr(loc[5]);
  f := nr(loc[6]);

  longitude := (a - 10) * 20 + c * 2 + (e - 1) * 0.083333333333333333330 + 0.08333333333333333333 / 2;
  latitude := (b - 10) * 10 + d * 1 + (f - 1) * 0.04166666666666666667 + 0.04166666666666666667 / 2;
end;

function TdmUtils.RemoveSpaces(S: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 1 to Length(s) do
    if S[i] <> #10 then
      Result := Result + S[i];
end;

function TdmUtils.StripHTML(S: string): string;
var
  TagBegin, TagEnd, TagLength: integer;
  TagNum: integer = 0;
begin
  if dmData.DebugLevel >= 1 then
    Writeln('In StripHTML ...');
  TagBegin := Pos('<', S);      // search position of first <
  while (TagBegin > 0) do
  begin  // while there is a < in S
    Inc(TagNum);
    TagEnd := Pos('>', S);              // find the matching >
    TagLength := TagEnd - TagBegin + 1;
    Delete(S, TagBegin, TagLength);     // delete the tag
    TagBegin := Pos('<', S);            // search for next <
    if (TagBegin > 0) and (Pos('>', S) = 0) then
      TagBegin := 0;
    if TagNum > 100 then
      Break;
  end;
  Result := S;                   // give the result
end;

function TdmUtils.ExtractQTH(qth: string): string;
var
  i: integer;
  a: TExplodeArray;
begin
  qth := Trim(qth);
  if Pos(' ', qth) < 1 then
  begin
    Result := QTH;
    exit;
  end;
  a := Explode(' ', qth);
  if (IncludesNum(a[0])) then
  begin
    for i := 1 to Length(a) - 1 do
      Result := Result + ' ' + a[i];
  end
  else
  begin
    if IncludesNum(a[Length(a) - 1]) then
    begin
      for i := 0 to Length(a) - 2 do
        Result := Result + ' ' + a[i];
    end
    else
      Result := qth;
  end;
  Result := Trim(Result);
end;

procedure TdmUtils.EnterFreq;
begin
  with TfrmEnterFreq.Create(self) do
    try
      ShowModal;
    finally
      Free
    end;
end;
function TdmUtils.FromJS8CALLToAdif(buf:string):string;
//purpose of this procedure is to convert JS8CALL UDP frame from json
//to ADIF record that then can be used by ADIF remote logging
var
  adi,a   :String;
  Jdata   :TJSONData;
Begin
  Jdata:=GetJSON(Buf);
  adi:= Jdata.FindPath('value').AsString;
  if pos('<CALL',UpperCase(adi))>0 then    //there should be call-tag
       Result:= '<ADIF_VER:5>3.1.0<EOH>'+adi+'<EOR>'
    else
       Result:= '';
end;

function TdmUtils.FromN1MMToAdif(buf:string):string;

//purpose of this procedure is to convert "contanct info" UDP frame from N1MM
//to ADIF record that then can be used by ADIF remote logging
//https://n1mmwp.hamdocs.com/appendices/external-udp-broadcasts/

var
  iDoc       : TXMLDocument;
  Nodelist   : TDOMNodeList;
  Anode      : TDOMNode;
  AStream    : TStringStream;
  i          : integer;
  mhz,Rmhz,
  adi,
  Nname,
  Nval       : String;
  IsOriginal : Boolean;
  Fdes       : Currency;

Begin
 adi:='<ADIF_VER:5>3.1.0<EOH>';
 IsOriginal := false;
 AStream := TStringStream.Create(Buf);
 mhz:='';
 Rmhz:='';
  if dmData.DebugLevel>=1 then
                            Writeln('IN->',buf);
  try
    if Assigned(AStream) then
     begin
      ReadXMLFile(iDoc, AStream);
      NodeList := iDoc.DocumentElement.ChildNodes;

        if Assigned(NodeList) then
        begin
          for i := 0 to NodeList.Count-1 do
          begin
           ANode:= NodeList.Item[i];
           if (ANode <> nil) and (ANode.FirstChild <> nil) then
           begin
               Nname:= UpperCase(Anode.NodeName.Trim);
               Nval:= ANode.FirstChild.NodeValue.Trim;
                case Nname of
                  'CALL'          : adi:=adi+'<'+StringToADIF(Nname,Nval);
                  'TIMESTAMP'     : Begin
                                       adi:=adi+'<'+StringToADIF('QSO_DATE',copy(Nval,1,4)+
                                                                            copy(Nval,6,2)+
                                                                            copy(Nval,9,2));
                                       Nval:= trim(copy(Nval,pos(' ',Nval),length(Nval)));
                                       Nval:= StringReplace(StringReplace(Nval,' ','',[rfReplaceAll]),':','', [rfReplaceAll]);
                                       adi:=adi+'<'+StringToADIF('TIME_ON',Nval);
                                       adi:=adi+'<'+StringToADIF('TIME_OFF',Nval);
                                    end;
                  'CONTESTNAME'   : adi:=adi+'<'+StringToADIF('CONTEST_ID',Nval);
                  'RXFREQ'        : if TryStrToCurr(Nval+'0',Fdes) then //N1MM sends units of 10 Hz!
                                             Begin
                                               Fdes :=Fdes/1000000.0;
                                               Rmhz:=FloatToStrF(Fdes,ffFixed,8,5);
                                             end;
                  'TXFREQ'        : if TryStrToCurr(Nval+'0',Fdes) then //N1MM sends units of 10 Hz!
                                             Begin
                                               Fdes :=Fdes/1000000.0;
                                               mhz:=FloatToStrF(Fdes,ffFixed,8,5);
                                             end;
                  'BAND'          : adi:=adi+'<'+StringToADIF('BAND',GetAdifBandFromFreq(Nval));
                  'OPERATOR'      : adi:=adi+'<'+StringToADIF('OPERATOR',Nval);
                  'MODE'          : adi:=adi+'<'+StringToADIF('MODE',Nval);
                  'SNT'           : adi:=adi+'<'+StringToADIF('RST_SENT',Nval);
                  'SNTNR'         : adi:=adi+'<'+StringToADIF('STX',Nval);
                  'RCV'           : adi:=adi+'<'+StringToADIF('RST_RCVD',Nval);
                  'RCVNR'         : adi:=adi+'<'+StringToADIF('SRX',Nval);
                  'EXCHANGE1'     :                   ; //what is this?   STX_STRING +  SRX_STRING ?
                  'MISCTEXT'      : adi:=adi+'<'+StringToADIF('SRX_STRING',Nval);  //seems to be here, why ?
                  'GRIDSQUARE'    : adi:=adi+'<'+StringToADIF('GRIDSQUARE',Nval);
                  'COMMENT'       : adi:=adi+'<'+StringToADIF('COMMENT',Nval);
                  'NAME'          : adi:=adi+'<'+StringToADIF('NAME',Nval);
                  'POWER'         : adi:=adi+'<'+StringToADIF('TX_PWR',Nval);

                  'ISORIGINAL'    : IsOriginal := ( Uppercase(Nval) = 'TRUE');

                end; //case
            end; //Anode not nil
           end;//nodelist cocunt
          if ((Rmhz='') and (mhz<>'')) or (Rmhz=mhz) then   // no RX_freq or RX=TX then only FREQ tag
            adi:=adi+'<'+StringToADIF('FREQ',mhz)
           else
            begin
              adi:=adi+'<'+StringToADIF('FREQ_RX',Rmhz); //if split then both
              adi:=adi+'<'+StringToADIF('FREQ',mhz);
            end
          end; //assigned nodelist
        end; //assigned Astream
   finally
     AStream.free;
   end;
   adi:=adi+'<EOR>';
   if dmData.DebugLevel>=1 then
                        writeln('OUT->',adi,'   ',IsOriginal);
   if IsOriginal then Result:=adi  else Result :=''; //do not accept relayed connect infos
end;

function TdmUtils.StringToADIF(ATag,Text: string): string;
var
   t:string;
   i:integer;
   b:boolean;
begin

  if UTF8Length(Text) <> Length(Text) then
   Begin
      t:= copy(Atag,2,length(ATag)); // leave '<'
      b :=false;
      for i:=0 to 18 do
        if pos(uppercase(t),adif_intls[i]) > 0 then
          Begin
            b:=true;
            break;
          end;
    if b then // tag in _intl allowed list
      begin
       Result := ATag+'_INTL:' + IntToStr(UTF8Length(Text)) + '>' + Text
      end
     else
      begin
       Result := ATag+':' + IntToStr(Length(Text)) + '>' + Text;
      end;
   end
  else
   begin
    Result := ATag+':' + IntToStr(Length(Text)) + '>' + Text;
   end;

  //if dmData.DebugLevel >=1 then Writeln(Result);
end;

function TdmUtils.MyTrim(Text: string): string;
var
  i: integer;
begin
  Text := Trim(Text);
  Result := '';
  for i := 1 to Length(Text) do
  begin
    //if NOT (text[i] in MyWhiteSpace) then
    if (Text[i] in AllowedChars) then
      Result := Result + Text[i];
  end;
end;

function TdmUtils.ReplaceSpace(txt: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 1 to length(txt) do
  begin
    if txt[i] = ' ' then
      Result := Result + '&nbsp;'
    else
      Result := Result + txt[i];
  end;
end;

function TdmUtils.ReplaceEnter(txt: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 1 to length(txt) do
  begin
    if txt[i] = #10 then
      txt[i] := ' ';
  end;
  Result := trim(txt);
end;

function TdmUtils.MyStrToFloat(num: string): extended;
begin
  if Pos('.', num) > 0 then
    num[Pos('.', num)] := FormatSettings.DecimalSeparator;
  Result := StrToFloat(num);
end;

function TdmUtils.ExtractQSLMgr(Text: string): string;
begin
  Text := UpperCase(Text);
  if pos('QSL VIA', Text) > 0 then
  begin
    Text := copy(Text, pos('QSL VIA', Text) + 8, Length(Text) - pos('QSL VIA', Text) + 1);
    Text := Trim(Text);
    if Pos(' ', Text) > 0 then
      Text := copy(Text, 1, Pos(' ', Text) - 1);
    Result := Text;
  end
  else
    Result := '';
end;

function TdmUtils.ExtractPower(power: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 1 to Length(power) do
  begin
    if (power[i] in ['0'..'9', FormatSettings.DecimalSeparator]) then
      Result := Result + power[i];
  end;
end;

procedure TdmUtils.LoadFontSettings(aForm: TForm);
var
  i: integer;
  fEdits: string;
  feSize: integer;
  fButtons: string;
  fbSize: integer;
  fGrids: string;
  fgSize: integer;
  fQsoGr: string;
  fqSize: integer;
begin
  if dmData.DBName = '' then
    exit;
  if cqrini.ReadBool('Fonts', 'UseDefault', True) then
  begin
    fEdits := 'default';
    feSize := 0;
    fButtons := 'default';
    fbSize := 0;
    fGrids := 'default';
    fgSize := 0;
    fQsoGr := 'default';
    fqSize := 0
  end
  else begin
    fEdits := cqrini.ReadString('Fonts', 'Edits', 'Sans 10');
    feSize := cqrini.ReadInteger('Fonts', 'eSize', 10);

    fButtons := cqrini.ReadString('Fonts', 'Buttons', 'Sans 10');
    fbSize := cqrini.ReadInteger('Fonts', 'bSize', 10);

    fGrids := cqrini.ReadString('Fonts', 'Grids', 'Monospace 8');
    fgSize := cqrini.ReadInteger('Fonts', 'gSize', 8);

    fQsoGr := cqrini.ReadString('Fonts', 'QGrids', 'Sans 10');
    fqSize := cqrini.ReadInteger('Fonts', 'qSize', 10)
  end;

  //otherwise NewQSO buttons do not fit to space
   if ( fbSize > 10 )then
     Begin
          frmNewQSO.btnSave.Caption:='Save QSO';
          frmNewQSO.btnCancel.Caption:= 'Quit';
     end
    else
     Begin
          frmNewQSO.btnSave.Caption:='Save QSO [enter]';
          frmNewQSO.btnCancel.Caption:= 'Quit [CTRL+Q]';
     end;

  for i := 0 to aForm.ComponentCount - 1 do
  begin
    //edits, memo combo, spinedit ...
    if (aForm.Components[i] is TEdit) then
    begin
      (aForm.Components[i] as TEdit).Font.Name := fEdits;
      (aForm.Components[i] as TEdit).Font.Size := feSize
    end;

    if (aForm.Components[i] is TMemo) then
    begin
      (aForm.Components[i] as TMemo).Font.Name := fEdits;
      (aForm.Components[i] as TMemo).Font.Size := feSize
    end;

    if (aForm.Components[i] is TMemo) then
    begin
      (aForm.Components[i] as TMemo).Font.Name := fEdits;
      (aForm.Components[i] as TMemo).Font.Size := feSize
    end;

    if (aForm.Components[i] is TSpinEdit) then
    begin
      (aForm.Components[i] as TSpinEdit).Font.Name := fEdits;
      (aForm.Components[i] as TSpinEdit).Font.Size := feSize
    end;

    if (aForm.Components[i] is TComboBox) then
    begin
      (aForm.Components[i] as TComboBox).Font.Name := fEdits;
      (aForm.Components[i] as TComboBox).Font.Size := feSize
    end;

    if (aForm.Components[i] is TColorBox) then
    begin
      (aForm.Components[i] as TColorBox).Font.Name := fEdits;
      (aForm.Components[i] as TColorBox).Font.Size := feSize
    end;

    ///////////////////////////////////////////////////////////
    //labels, buttons, radio,checkbox ....
    if (aForm.Components[i] is TLabel) then
    begin
      if not (((aForm.Components[i] as TLabel).Name = 'lblFreq') or
        ((aForm.Components[i] as TLabel).Name = 'lblAzimuth')) then
        //frequecy/Azimuth label font is set
      begin
        (aForm.Components[i] as TLabel).Font.Name := fButtons;
        (aForm.Components[i] as TLabel).Font.Style := []
      end
    end;

    if (aForm.Components[i] is TGroupBox) then
    begin
      (aForm.Components[i] as TGroupBox).Font.Name := fButtons;
      (aForm.Components[i] as TGroupBox).Font.Size := fbSize
    end;

    if (aForm.Components[i] is TButton) then
    begin
      (aForm.Components[i] as TButton).Font.Name := fButtons;
      (aForm.Components[i] as TButton).Font.Size := fbSize
    end;

    if (aForm.Components[i] is TCheckBox) then
    begin
      (aForm.Components[i] as TCheckBox).Font.Name := fButtons;
      (aForm.Components[i] as TCheckBox).Font.Size := fbSize
    end;

    if (aForm.Components[i] is TRadioButton) then
    begin
      (aForm.Components[i] as TRadioButton).Font.Name := fButtons;
      (aForm.Components[i] as TRadioButton).Font.Size := fbSize
    end;

    if (aForm.Components[i] is TBitBtn) then
    begin
      (aForm.Components[i] as TBitBtn).Font.Name := fButtons;
      (aForm.Components[i] as TBitBtn).Font.Size := fbSize
    end;

    /////////////////////////////////////////////////////////
    //dbgrids
    if (aForm.Components[i] is TDBGrid) then
    begin
      (aForm.Components[i] as TDBGrid).Font.Name := fQsoGr;
      (aForm.Components[i] as TDBGrid).Font.Size := fqSize;

      if cqrini.ReadBool('Fonts', 'GridGreenBar', False) = True then
      begin
        (aForm.Components[i] as TDBGrid).AlternateColor := $00E7FFEB
      end
      else begin
        (aForm.Components[i] as TDBGrid).AlternateColor := clWindow
      end;

      if cqrini.ReadBool('Fonts', 'GridSmallRows', False) = True then
      begin
        if fqSize > 0 then
          (aForm.Components[i] as TDBGrid).DefaultRowHeight := fqSize + 8
        else
          (aForm.Components[i] as TDBGrid).DefaultRowHeight := 22
      end
      else begin
        (aForm.Components[i] as TDBGrid).DefaultRowHeight := 22
      end;
      if cqrini.ReadBool('Fonts', 'GridBoldTitle', False) = True then
      begin
        (aForm.Components[i] as TDBGrid).TitleFont.Style := [fsBold]
      end
      else begin
        (aForm.Components[i] as TDBGrid).TitleFont.Style := []
      end
    end;
    ////////////////////////////////////////////////////////
    //statistics
    if (aForm.Components[i] is TStringGrid)
      and not ((aForm.Components[i] as TStringGrid).Name = 'sgMonitor') then
    begin
      (aForm.Components[i] as TStringGrid).Font.Name := fGrids;
      (aForm.Components[i] as TStringGrid).Font.Size := fgSize;
      if cqrini.ReadBool('Fonts', 'GridGreenBar', False) = True then
      begin
        (aForm.Components[i] as TStringGrid).AlternateColor := $00E7FFEB;
        (aForm.Components[i] as TStringGrid).Options :=
          [goRowSelect, goRangeSelect, goSmoothScroll, goVertLine, goFixedVertLine]
      end
      else begin
        (aForm.Components[i] as TStringGrid).AlternateColor := clWindow;
        (aForm.Components[i] as TStringGrid).Options :=
          [goRangeSelect, goSmoothScroll, goVertLine, goFixedVertLine, goFixedHorzLine, goHorzline]
      end;
      if cqrini.ReadBool('Fonts', 'GridSmallRows', False) = True then
      begin
        if fgSize > 0 then
          (aForm.Components[i] as TStringGrid).DefaultRowHeight := fgSize + 8
        else
          (aForm.Components[i] as TStringGrid).DefaultRowHeight := 20
      end
      else begin
        (aForm.Components[i] as TStringGrid).DefaultRowHeight := 25
      end;
      if cqrini.ReadBool('Fonts', 'GridBoldTitle', False) = True then
      begin
        (aForm.Components[i] as TStringGrid).TitleFont.Style := [fsBold];
      end
      else begin
        (aForm.Components[i] as TStringGrid).TitleFont.Style := []
      end
    end
  end
end;

function TdmUtils.ExtractFontSize(sFont: string): integer;
var
  i: integer = 0;
  s: string = '';
begin
  for i := Length(sFont) downto 1 do
  begin
    if sFont[i] = ' ' then
      break
    else
      s := sFont[i] + s;
  end;
  if not TryStrToInt(s, Result) then
    Result := 10;
end;

function TdmUtils.ExtractCallsign(call: string): string;
var
  Before: string = '';
  After: string = '';
  Middle: string = '';
  ar: TExplodeArray;
  num: integer = 0;
begin
  Result := call;
  if Pos('/', call) = 0 then
    exit;

  SetLength(ar, 0);
  ar := Explode('/', call);
  num := Length(ar) - 1;

  if num = 2 then
  begin
    Before := ar[0];
    Middle := ar[1];

    if Length(Before) > Length(middle) then
      Result := Before // RA1AA/1/M
    else
      Result := Middle; //KH6/OK2CQR/P
  end
  else
  begin
    Before := ar[0];
    After := ar[1];

    if Length(Before) <= 3 then
    begin
      Result := After;
      exit;
    end;

    if Length(After) <= 3 then
    begin
      Result := Before;
      exit;
    end;

    if dmDXCC.IsException(After) then
      Result := Before
    else
      Result := After;
  end;
end;

function TdmUtils.GetGreetings(time: string): string;
var
  h: integer;
begin
  Result := '';
  time := copy(time, Pos(' ', time) + 2, 2);
  if TryStrToInt(time, h) then
  begin
    if h < 3 then
      Result := 'GE/GM'
    else
    begin
      if (h > 3) and (h < 12) then
        Result := 'GM'
      else
      begin
        if (h >= 12) and (h < 16) then
          Result := 'GA'
        else
          Result := 'GE';
      end;
    end;
  end;
end;

procedure TdmUtils.LoadBandLabelSettins;
begin
  if cqrini.ReadBool('Program', 'BandStatMHz', True) then
  begin
    s136 := '136k';
    s630 := '472k';
    s160 := '1.8';
    s80 := '3.5';
    s60 := '5';
    s40 := '7';
    s30 := '10.1';
    s20 := '14';
    s17 := '18';
    s15 := '21';
    s12 := '24';
    s10 := '28';
    s6 := '50';
    s4 := '70';
    s2 := '144';
    s220 := '220';
    s70 := '430';
    s900 := '902';
    s1260 := '1260';
    s2300 := '2300';
    s3400 := '3400';
    s5850 := '5650';
    s10G := '10G';
    s24G := '24G';
    s47G := '47G';
    s76G := '76G';
    s122G := '122G';
    s134G := '134G';
    s241G := '241G';
  end
  else
  begin
    s136 := '2.2k';
    s630 := '0.5k';
    s160 := '160';
    s80 := '80';
    s60 := '60';
    s40 := '40';
    s30 := '30';
    s20 := '20';
    s17 := '17';
    s15 := '15';
    s12 := '12';
    s10 := '10';
    s6 := '6m';
    s4 := '4m';
    s2 := '2m';
    s220 := '1.25m';
    s70 := '70c';
    s900 := '33c';
    s1260 := '23c';
    s2300 := '13c';
    s3400 := '8cm';
    s5850 := '5cm';
    s10G := '3cm';
    s24G := '1cm';
    s47G := '6mm';
    s76G := '4mm';
    s122G := '2.5mm';
    s134G := '2mm';
    s241G := '1mm';
  end;
end;

function TdmUtils.IsIOTAOK(iota: string): boolean;
var
  c, snr: string;
  i: integer;
begin
  Result := False;
  if Length(iota) <> 6 then
    exit;
  c := copy(iota, 1, 2); //AS,EU,OC,NA,SA,AF
  if (c <> 'AS') and (c <> 'EU') and (c <> 'OC') and (c <> 'NA') and
    (c <> 'SA') and (c <> 'AN') and (c <> 'AF') then
    exit;
  snr := copy(iota, 4, 3);
  for i := 1 to 3 do
    if not (snr[i] in ['0'..'9']) then
    begin
      exit;
    end;
  Result := True;
end;

procedure TdmUtils.GetRealCoordinate(lat, long: string;
  var latitude, longitude: currency);
var
  s, d: string;
begin
  s := lat;
  d := long;
  if ((Length(s) = 0) or (Length(d) = 0)) then
  begin
    longitude := 0;
    latitude := 0;
    exit;
  end;

  if s[Length(s)] = 'S' then
    s := '-' + s;
  s := copy(s, 1, Length(s) - 1);
  if pos('.', s) > 0 then
    s[pos('.', s)] := FormatSettings.DecimalSeparator;
  if not TryStrToCurr(s, latitude) then
    latitude := 0;

  if d[Length(d)] = 'W' then
    d := '-' + d;
  d := copy(d, 1, Length(d) - 1);
  if pos('.', d) > 0 then
    d[pos('.', d)] := FormatSettings.DecimalSeparator;
  if not TryStrToCurr(d, longitude) then
    longitude := 0;
  if dmData.DebugLevel >= 4 then
  begin
    //Writeln('Lat:  ',latitude);
    //Writeln('Long: ',longitude);
  end;
end;

function TdmUtils.SetSize(Text: string; Len: integer): string;
var
  i: integer;
begin
  Result := Text;
  for i := Length(Text) to Len - 1 do
    Result := Result + ' ';
end;

function TdmUtils.SetSizeLeft(Text: string; Len: integer): string;
var
  i: integer;
begin
  Result := Text;
  for i := Length(Text) to Len - 1 do
    Result := ' ' + Result;
end;

function TdmUtils.MonthToStr(mon: integer): string;
begin
  Result := 'JAN';
  case mon of
    1: Result := 'JAN';
    2: Result := 'FEB';
    3: Result := 'MAR';
    4: Result := 'APR';
    5: Result := 'MAY';
    6: Result := 'JUN';
    7: Result := 'JUL';
    8: Result := 'AUG';
    9: Result := 'SEP';
    10: Result := 'OCT';
    11: Result := 'NOV';
    12: Result := 'DEC';
  end; //case
end;

function TdmUtils.GetIDCall(callsign: string): string;
var
  Pole: TExplodeArray;
begin
  Result := callsign;
  if Pos('/', callsign) = 0 then
    exit;
  SetLength(pole, 0);
  pole := Explode('/', callsign);
  if dmDXCC.IsException(pole[1]) then
    Result := pole[0]
  else
  begin
    if Length(pole[0]) > Length(pole[1]) then  //FJ/G3TXF, RA1AA/1/M etc
      Result := pole[0]
    else
      Result := pole[1];
  end;
end;

function TdmUtils.ExtractIOTAPrefix(call: string; date: TDateTime): string;
var
  before, after, between: string;
  p: integer;
begin
  Result := '';
  p := Pos('/', call);
  if p > 0 then
  begin
    before := copy(call, 1, p);
    after := copy(call, p + 1, Length(call) - p);
    if Pos('/', after) > 0 then
    begin
      between := copy(after, 1, Pos('/', after) - 1);
      after := copy(after, Pos('/', after) + 1, Length(after) - Pos('/', after));
      if (between[1] in ['0'..'9']) and (Length(before) >= 3) and
        (Length(between) = 1) then
        before[3] := between[1];
      Result := before;
    end
    else
    begin
      if (Length(after) = 1) and (after[1] in ['0'..'9']) then
      begin
        before[3] := after[1];
        Result := copy(before, 1, 3);
      end
      else
      begin
        if dmDXCC.IsPrefix(before, date) then
          Result := Before
        else
        begin
          if dmDXCC.IsPrefix(After, date) then
            Result := After;
        end;
      end;
    end;
  end
  else
    Result := copy(before, 1, 3);
end;

function TdmUtils.IncludesNum(Text: string): boolean;
var
  i: integer;
begin
  Result := False;
  for i := 1 to Length(Text) - 1 do
  begin
    if Text[i] in ['0'..'9'] then
    begin
      Result := True;
      exit;
    end;
  end;
end;

procedure TdmUtils.SortList(l: TStringList);
var
  i: integer;
  min: integer;
  y: integer;
  a, b: double;
  tmp: string;
begin
  for i := 0 to l.Count - 1 do  //projdeme prvky pole
  begin
    min := i;
    for y := i to l.Count - 1 do
    begin
      tmp := copy(l.Strings[min], 1, Pos(';', l.Strings[min]) - 1);
      if not TryStrToFloat(tmp, a) then
        exit;
      tmp := copy(l.Strings[y], 1, Pos(';', l.Strings[y]) - 1);
      if not TryStrToFloat(tmp, b) then
        exit;
      if a > b then
        min := y;
    end;
    tmp := l.Strings[i];
    l.Strings[i] := l.Strings[min];
    l.Strings[min] := tmp;
  end;
  {
  for i:=0 to l.Count-1 do
    WriteLn(l.Strings[i]);
  }
end;

function TdmUtils.GetRigError(err: integer): string;
begin
  Result := '';
  case err of
    1: Result := 'RIG_EINVAL: Invalid parameter';
    2: Result := 'RIG_ECONF: Invalid configuration (serial,..)';
    3: Result := 'RIG_ENOMEM: Memory shortage';
    4: Result := 'RIG_ENIMPL: Function not implemented, but will be';
    5: Result := 'RIG_ETIMEOUT: Communication timed out';
    6: Result := 'RIG_EIO: IO error, including open failed';
    7: Result := 'RIG_EINTERNAL: Internal Hamlib error, huh!';
    8: Result := 'RIG_EPROTO: Protocol error';
    9: Result := 'RIG_ERJCTED: Command rejected by the rig';
    10: Result := 'RIG_ETRUNC: Command performed, but arg truncated';
    11: Result := 'RIG_ENAVAIL: Function not available';
    12: Result := 'RIG_ENTARGET: VFO not targetable';
  end; //case
end;

function TdmUtils.IncColor(AColor: TColor; AQuantity: byte): TColor;
var
  R, G, B: byte;
begin
  RedGreenBlue(ColorToRGB(AColor), R, G, B);
  R := Max(0, integer(R) + AQuantity);
  G := Max(0, integer(G) + AQuantity);
  B := Max(0, integer(B) + AQuantity);
  Result := RGBToColor(R, G, B);
end;

function TdmUtils.IsItIOTA(spot: string): boolean;
var
  p: integer;
begin
  spot := UpperCase(spot);
  Result := False;

  p := Pos('EU', spot);
  if p > 0 then
  begin
    if spot[p + 1] = '-' then
    begin
      Result := IsIOTAOK(copy(spot, p, 6));
    end
    else
    begin
      Result := IsIOTAOK('EU-' + copy(spot, p + 3, 3));
    end;
  end;
  if Result then
    exit;

  p := Pos('AS', spot);
  if p > 0 then
  begin
    if spot[p + 1] = '-' then
    begin
      Result := IsIOTAOK(copy(spot, p, 6));
    end
    else
    begin
      Result := IsIOTAOK('AS-' + copy(spot, p + 3, 3));
    end;
  end;
  if Result then
    exit;

  p := Pos('NA', spot);
  if p > 0 then
  begin
    if spot[p + 1] = '-' then
    begin
      Result := IsIOTAOK(copy(spot, p, 6));
    end
    else
    begin
      Result := IsIOTAOK('NA-' + copy(spot, p + 3, 3));
    end;
  end;
  if Result then
    exit;

  p := Pos('SA', spot);
  if p > 0 then
  begin
    if spot[p + 1] = '-' then
    begin
      Result := IsIOTAOK(copy(spot, p, 6));
    end
    else
    begin
      Result := IsIOTAOK('SA-' + copy(spot, p + 3, 3));
    end;
  end;
  if Result then
    exit;

  p := Pos('AF', spot);
  if p > 0 then
  begin
    if spot[p + 1] = '-' then
    begin
      Result := IsIOTAOK(copy(spot, p, 6));
    end
    else
    begin
      Result := IsIOTAOK('AF-' + copy(spot, p + 3, 3));
    end;
  end;
  if Result then
    exit;

  p := Pos('OC', spot);
  if p > 0 then
  begin
    if spot[p + 1] = '-' then
    begin
      Result := IsIOTAOK(copy(spot, p, 6));
    end
    else
    begin
      Result := IsIOTAOK('OC-' + copy(spot, p + 3, 3));
    end;
  end;
  if Result then
    exit;

  p := Pos('AN', spot);
  if p > 0 then
  begin
    if spot[p + 1] = '-' then
    begin
      Result := IsIOTAOK(copy(spot, p, 6));
    end
    else
    begin
      Result := IsIOTAOK('AN-' + copy(spot, p + 3, 3));
    end;
  end;
end;

function TdmUtils.GetXplanetCommand: string;
var
  myloc: string = '';
  customloc: string = '';
  lat, long: currency;
  wait: string;
  geom: string;
  proj: string = '';
begin
  Result := '';
  Result := cqrini.ReadString('xplanet', 'path', '/usr/bin/xplanet');
  myloc := cqrini.ReadString('Station', 'LOC', '');
  customloc := cqrini.ReadString('xplanet', 'loc', '');
  if not FileExists(Result) then
  begin
    Result := '';
    exit;
  end;
  geom := ' -geometry ' + cqrini.ReadString('xplanet', 'width', '100') + 'x' +
    cqrini.ReadString('xplanet', 'height', '100') + '+' +
    cqrini.ReadString('xplanet', 'left', '10') +
    '+' + cqrini.ReadString('xplanet', 'top', '10');
  if IsLocOK(customloc) then
  begin
    CoordinateFromLocator(CompleteLoc(customloc), lat, long);
    myloc := ' -longitude ' + CurrToStr(long) + ' -latitude ' + CurrToStr(lat);
  end
  else if IsLocOK(myloc) then
  begin
    CoordinateFromLocator(CompleteLoc(myloc), lat, long);
    myloc := ' -longitude ' + CurrToStr(long) + ' -latitude ' + CurrToStr(lat);
  end;
  case cqrini.ReadInteger('xplanet', 'project', 0) of
    0: proj := '';
    1: proj := ' -projection azimuthal -background ' + dmData.HomeDir +
        'xplanet' + PathDelim + 'bck.png';
    2: proj := ' -projection azimuthal';
    3: proj := ' -projection rectangular';
  end; //case
  wait := '-wait ' + cqrini.ReadString('xplanet', 'refresh', '5');
  Result := Result + ' -config ' + dmData.HomeDir +
    'xplanet' + PathDelim + 'geoconfig  -glare 28 ' + '-light_time -range 2.5 ' +
    wait + ' ' + geom + ' -window_title "CQRLOG - xplanet"' + myloc + proj
end;

procedure TdmUtils.RunXplanet;
var
  AProcess: TProcess;
  index     :integer;
  paramList :TStringList;
begin
  if dmData.DebugLevel>=1 then Writeln('RunXplanet - start');
  if (GetXplanetCommand = '') then exit;
  AProcess := TProcess.Create(nil);
  try
    index:=0;
    paramList := TStringList.Create;
    paramList.Delimiter := ' ';
    paramList.DelimitedText := GetXplanetCommand;
    AProcess.Parameters.Clear;
    while index < paramList.Count do
    begin
      if (index = 0) then AProcess.Executable := paramList[index]
        else AProcess.Parameters.Add(paramList[index]);
      inc(index);
    end;
    paramList.Free;
    if dmData.DebugLevel>=1 then Writeln('AProcess.Executable: ',AProcess.Executable,' Parameters: ',AProcess.Parameters.Text);
    AProcess.Execute;
  finally
    AProcess.Free;
  end;
end;

procedure TdmUtils.CloseXplanet;
var
  AProcess: TProcess;
begin
  AProcess := TProcess.Create(nil);
  try
    AProcess.Executable  := 'killall';
    AProcess.Parameters.Add('xplanet');
    AProcess.Options := [poNoConsole, poNewProcessGroup];
    if dmData.DebugLevel>=1 then Writeln('AProcess.Executable: ',AProcess.Executable,' Parameters: ',AProcess.Parameters.Text);
    AProcess.Execute;
  finally
    AProcess.Free
  end;
end;

procedure TdmUtils.ModifyXplanetConf;
var
  l: TStringList;
  i: integer;
begin
  l := TStringList.Create;
  try
    l.LoadFromFile(dmData.HomeDir + 'xplanet' + PathDelim + 'geoconfig');
    for i := 0 to l.Count - 1 do
    begin
      if Pos('marker_file=', l.Strings[i]) > 0 then
      begin
        l.Strings[i] := 'marker_file=' + dmData.HomeDir + 'xplanet' + PathDelim + 'marker';
        break;
      end;
    end;
    l.SaveToFile(dmData.HomeDir + 'xplanet' + PathDelim + 'geoconfig')
  finally
    l.Free
  end;
end;

procedure TdmUtils.DeleteMarkerFile;
begin
  DeleteFile(dmData.HomeDir + 'xplanet' + PathDelim + 'marker');
end;

function TdmUtils.GetLastUpgradeDate: TDateTime;
var
  older: longint = 0;
  dir: string;
begin
  dir := dmData.HomeDir + 'ctyfiles' + PathDelim;
  if FileAge(dir + 'AreaOK1RR.tbl') > FileAge(dir + 'CallResolution.tbl') then
    older := FileAge(dir + 'AreaOK1RR.tbl')
  else
    older := FileAge(dir + 'CallResolution.tbl');
  if older < FileAge(dir + 'Country.tab') then
    older := FileAge(dir + 'Country.tab');
  if older < FileAge(dir + 'prop_mode.tab') then
    older := FileAge(dir + 'prop_mode.tab');
  if older < FileAge(dir + 'sat_name.tab') then
    older := FileAge(dir + 'sat_name.tab');
  if older < FileAge(dir + 'ContestName.tab') then
    older := FileAge(dir + 'ContestName.tab');
  Result := FileDateToDateTime(older) + 1;
end;

function TdmUtils.GetLastQSLUpgradeDate: TDateTime;
var
  dir: string;
begin
  dir := dmData.HomeDir + 'ctyfiles' + PathDelim;
  if FileExists(dir + 'qslmgr.csv') then
    Result := FileDateToDateTime(FileAge(dir + 'qslmgr.csv')) + 1
  else
    Result := EncodeDate(2000, 01, 01);
end;

function TdmUtils.GetLastDOKUpgradeDate: TDateTime;
var
  dir: string;
begin
  dir := dmData.HomeDir + 'dok_data' + PathDelim;
  if FileExists(dir + 'dok.csv') then
    Result := FileDateToDateTime(FileAge(dir + 'dok.csv')) + 1
  else
    Result := EncodeDate(2000, 01, 01);
end;

function TdmUtils.UnTarFiles(FileName, TargetDir: string): boolean;
var
  AProcess: TProcess;
  dir: string;
begin
  Result := True;
  dir := GetCurrentDir;
  SetCurrentDir(TargetDir);
  AProcess := TProcess.Create(nil);
  try
    AProcess.Parameters.Clear;
    AProcess.Executable := 'tar';
    AProcess.Parameters.Add('-xvzf');
    AProcess.Parameters.Add(FileName);
    AProcess.Options := [poNoConsole, poNewProcessGroup, poWaitOnExit];
    if dmData.DebugLevel>=1 then Writeln('AProcess.Executable: ',AProcess.Executable,' Parameters: ',AProcess.Parameters.Text);
   try
      AProcess.Execute;
    except
      Result := False
    end;
  finally
    SetCurrentDir(dir);
    AProcess.Free;
  end;
end;

procedure TdmUtils.ReadZipList(cmbZip: TComboBox);
var
  res: byte;
  SearchRec: TSearchRec;
  f: TextFile;
  ShortName: string = '';
  LongName: string = '';
  Ts: TStringList;
  i: integer = 0;
begin
  cmbZip.Clear;
  cmbZip.Items.Add('');
  Ts := TStringList.Create;
  try
    res := FindFirst(dmData.ZipCodeDir + '*.txt', faAnyFile, SearchRec);
    while Res = 0 do
    begin
      if FileExists(dmData.ZipCodeDir + SearchRec.Name) then
      begin
        AssignFile(f, dmData.ZipCodeDir + SearchRec.Name);
        Reset(f);
        ReadLn(f, ShortName);
        ReadLn(f, LongName);
        Ts.Add(ShortName + ';' + LongName);
        CloseFile(f);
      end;
      Res := FindNext(SearchRec);
    end;
    Ts.Sort;
    for i := 0 to Ts.Count - 1 do
      cmbZip.Items.Add(Ts.Strings[i])
  finally
    FindClose(SearchRec);
    Ts.Free
  end;
end;

function TdmUtils.ExtractZipCode(qth: string; Position: integer): string;
var
  i: integer;
begin
  if dmData.DebugLevel >= 1 then
    Writeln('Position: ', Position);
  Result := '';
  if Position = 0 then
    Result := copy(qth, 1, Pos(' ', qth) - 1)
  else
  begin
    for i := Length(qth) downto 1 do
    begin
      if qth[i] <> ' ' then
        Result := qth[i] + Result
      else
        break;
    end;
  end;
  Result := Trim(Result);
  if Pos('-', Result) > 0 then
    Result := Copy(Result, 1, Pos('-', Result) - 1);
end;

function TdmUtils.GetLabelBand(freq: string): string;
begin
  Result := LowerCase(GetBandFromFreq(freq));
end;

function TdmUtils.GetCWMessage(Key,call,rst_s,stx,stx_str,srx,srx_str,HisName,HelloMsg, text : String) : String;
{
 %mc - my callsign
 %mn - my name
 %mq - my qth
 %ml - my locator
 %r  - rst send
 %rs - rst send sends N instead of 9 (sends also 0 as T, but does not exist in normal report)

 %n  - name
 %c  - callsign
 %h - greeting GM/GA/GE calculated from the %c station location time

 %xn  - contest exchange serial number
 %xnr - contest exchange seral number received
 %xm  - contest exchange message
 %xmr - contest exchange message received
 %xns - contest exchenge serial number sends 9->N and 0->T
 %xnrs- contest exchange message received sends 9->N and 0->T
 %xrs - full contest exchange RST+SerialNR+Message sends 9->N and 0->T.
        Can be used "always" as if serNR and/or Message are empty just sends plain report.

if text is not empty and we didn't send any key (F1 etc.) we can
use this function to prepare every text wee need to send
}

var
  mycall : String = '';
  myloc  : String = '';
  myname : String = '';
  myqth  : String = '';
  rst_sh : String = '';
  stx_sh : String = '';
  srx_sh : String = '';
  con_ex : String = '';

begin
  mycall := cqrini.ReadString('Station', 'Call', '');
  myloc := cqrini.ReadString('Station', 'LOC', '');
  myname := cqrini.ReadString('Station', 'Name', '');
  myqth := cqrini.ReadString('Station', 'QTH', '');
  if key <> '' then
   Begin
    if (frmContest.Showing) and ( not (cqrini.ReadBool('CW','S&P',True))) then //if contest and run mode keys are F11-F20
     Begin
      if key='F10' then key:='F20'
       else
         key:= key[1]+'1'+key[2];
     end;
    Result := LowerCase(cqrini.ReadString('CW', key, ''))
   end
  else
    Result := text;

    rst_sh := StringReplace(rst_s,'9','N',[rfReplaceAll, rfIgnoreCase]);
    rst_sh := StringReplace(rst_sh,'0','T',[rfReplaceAll, rfIgnoreCase]);//replace zeros, too

    stx_sh := StringReplace(stx,'9','N',[rfReplaceAll, rfIgnoreCase]);
    stx_sh := StringReplace(stx_sh,'0','T',[rfReplaceAll, rfIgnoreCase]);//replace zeros, too

    srx_sh := StringReplace(srx,'9','N',[rfReplaceAll, rfIgnoreCase]);
    srx_sh := StringReplace(srx_sh,'0','T',[rfReplaceAll, rfIgnoreCase]);//replace zeros, too

    con_ex := rst_sh;
    if stx_sh <>'' then con_ex:=con_ex+' '+stx_sh;
    if stx_str <>'' then con_ex:=con_ex+' '+stx_str;

    Result := StringReplace(Result,'%xnrs',srx_sh,[rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result,'%xnr',srx,[rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result,'%xns',stx_sh,[rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result,'%xn',stx,[rfReplaceAll, rfIgnoreCase]);

    Result := StringReplace(Result,'%xmr',srx_str,[rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result,'%xm',stx_str,[rfReplaceAll, rfIgnoreCase]);

    Result := StringReplace(Result,'%xrs',con_ex,[rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result,'%rs',rst_sh,[rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result,'%r',rst_s,[rfReplaceAll, rfIgnoreCase]);

    Result := StringReplace(Result,'%n',HisName,[rfReplaceAll, rfIgnoreCase]);

    Result := StringReplace(Result,'%mc',mycall,[rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result,'%ml',myloc,[rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result,'%mn',myname,[rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result,'%mq',myqth,[rfReplaceAll, rfIgnoreCase]);

    Result := StringReplace(Result,'%h',HelloMsg,[rfReplaceAll, rfIgnoreCase]);

    Result := StringReplace(Result,'%c',call,[rfReplaceAll, rfIgnoreCase]);

    if dmData.DebugLevel>=1 then
                                Writeln('Sending:',Result)
end;

function TdmUtils.RigGetcmd(r : String) : String;
var
  cmd : String = '';
  rigid : String ='';
  device : String = '';
  port : String = '';
  speed : String = '';
  parity : Integer = 0;
  databits : Integer = 0;
  stopbits : Integer = 0;
  handshake : Integer = 0;
  RTS : Boolean = False;
  DTR : Boolean = False;
  civadr : String = '';
begin
  if r = '' then exit;
  result := '';
  civadr    := cqrini.ReadString('TRX'+r,'civ','');
  speed     := cqrini.ReadString('TRX'+r,'Speed','4800');
  DataBits  := cqrini.ReadInteger('TRX'+r,'DataBits',8);
  stopbits  := cqrini.ReadInteger('TRX'+r,'StopBits',1);
  handshake := cqrini.ReadInteger('TRX'+r,'Handshake',0);
  parity    := cqrini.ReadInteger('TRX'+r,'Parity',0);
  DTR       := cqrini.ReadInteger('TRX'+r,'dtr',0) > 0;
  RTS       := cqrini.ReadInteger('TRX'+r,'rts',0) > 0;
  rigid     := cqrini.ReadString('TRX'+r,'model','');
  device    := cqrini.ReadString('TRX'+r,'device','');

  if not cqrini.ReadBool('TRX'+r,'Run',False) then
    exit;

  if rigid = '' then
    exit;
  if Device = '' then
    exit;

  cmd := cqrini.ReadString('TRX', 'Path', '/usr/bin/rigctld');
  if not FileExists(cmd) then
    exit;
  cmd := cmd + ' --model=' + rigid;
  cmd := cmd + ' --rig-file=' + Device;
  if Port <> '' then
    cmd := cmd + ' --port=' + port;
  if Speed <> '' then
    cmd := cmd + ' --serial-speed=' + Speed;
  case parity of
    0: cmd := cmd + ' --set-conf=serial_parity=None';
    1: cmd := cmd + ' --set-conf=serial_parity=Odd';
    2: cmd := cmd + ' --set-conf=serial_parity=Even'
  end; //case
  if (DataBits < 9) and (DataBits > 4) then
    cmd := cmd + ' --set-conf=data_bits=' + IntToStr(DataBits);
  if (StopBits > 0) and (StopBits < 4) then
    cmd := cmd + ' --set-conf=stop_bits=' + IntToStr(StopBits);
  case HandShake of
    0: cmd := cmd + ' --set-conf=serial_handshake=None';
    1: cmd := cmd + ' --set-conf=serial_handshake=XONXOFF';
    2: cmd := cmd + ' --set-conf=serial_handshake=Hardware'
  end;
  if RTS then
    cmd := cmd + ' --set-conf=rts_state=ON'
  else
    cmd := cmd + ' --set-conf=rts_state=OFF';
  if DTR then
    cmd := cmd + ' --set-conf=dtr_state=ON'
  else
    cmd := cmd + ' --set-conf=dtr_state=OFF';
  if civadr <> '' then
    cmd := cmd + '--civaddr=' + civadr;
  Result := cmd + ' >> /dev/null &';
end;

procedure TdmUtils.CalcSunRiseSunSet(Lat, Long: double; var SunRise, SunSet: TDateTime);

  function DateTimeToJulianDate(const AValue: TDateTime): double;
  var
    LYear, LMonth, LDay: word;
  begin
    DecodeDate(AValue, LYear, LMonth, LDay);
    Result := (1461 * (LYear + 4800 + (LMonth - 14) div 12)) div 4 +
      (367 * (LMonth - 2 - 12 * ((LMonth - 14) div 12))) div
      12 - (3 * ((LYear + 4900 + (LMonth - 14) div 12) div 100)) div
      4 + LDay - 32075.5 + Frac(AValue);
  end;

  function JulianDateToDateTime(const AValue: double): TDateTime;
  var
    L, N, LYear, LMonth, LDay: integer;
    ADateTime: TDateTime;
  begin
    L := Trunc(AValue) + 68570;
    N := 4 * L div 146097;
    L := L - (146097 * N + 3) div 4;
    LYear := 4000 * (L + 1) div 1461001;
    L := L - 1461 * LYear div 4 + 31;
    LMonth := 80 * L div 2447;
    LDay := L - 2447 * LMonth div 80;
    L := LMonth div 11;
    LMonth := LMonth + 2 - 12 * L;
    LYear := 100 * (N - 49) + LYear + L;
    ADateTime := EncodeDate(LYear, LMonth, LDay);
    ADateTime := ADateTime + Frac(AValue) - 0.5;
    Result := ADateTime;
  end;

  function put_in_360(x: extended): extended;
  begin
    Result := x - round(x / 360) * 360;
    while Result < 0 do
      Result := Result + 360;
  end;

  function deg2rad(x: extended): extended;
  begin
    Result := x / 180 * pi;
  end;

  function rad2deg(x: extended): extended;
  begin
    Result := x * 180 / pi;
  end;

  function sin_d(x: extended): extended;
  begin
    sin_d := sin(deg2rad(put_in_360(x)));
  end;

  function cos_d(x: extended): extended;
  begin
    cos_d := cos(deg2rad(put_in_360(x)));
  end;

  function arcsin_d(x: extended): extended;
  begin
    Result := rad2deg(arcsin(x));
  end;

  function arcsin(x: extended): extended;
  begin
    if x < 1 then
      if x > -1 then
        Result := arctan(x / sqrt(1 - x * x))
      else
        Result := -90
    else
      Result := 90;
  end;

  function arccos(x: extended): extended;
  begin
    Result := pi / 2 - arcsin(x);
  end;

  function arccos_d(x: extended): extended;
  begin
    Result := rad2deg(arccos(x));
  end;

var
  n: double; //Julian cycle since Jan 1, 2000
  jDate: double; //Julian date
  tmp: double;

  lw: double; // West Longitude (75W = 75, 45E = -45)
  ln: double; // North Latitude (35N = 35, 25S = -25)
  M: double; // Mean Solar Anomaly
  C: double; // Equation of center
  lambda: double; // Ecliptical longitude of the sun
  delta: double; // Declination of the sun
  H: double; // Hour Angle (half the arc length of the sun)
  Jtran: double; //Julian date of solar noon on cycle n

  M1: integer;

begin
  jDate := DateTimeToJulianDate(now);
  //Writeln('jDate:',FloatToStr(jDate));
  ln := lat;
  lw := Long * -1; //we need west longitude

  //First, start by calculating the number of days since January 1, 2000.
  //Add that number to 2451545 (the Julian day of January 1, 2000).
  //This will be variable Jdate.

  //The next step is to calculate the Julian cycle. This is not equal to
  //the days since Jan 1, 2000. Depending on your longitude, this
  //may be a different number.
  n := (jDate - 2451545 - 0.0009) - (lw / 360);
  n := round(n);

  //Now, it is time to approximate the Julian date of solar noon.
  //This is just an approximation so that we can make some intermediate
  //calculations before we calculate the actual Julian date of solar noon.
  jDate := 2451545 + 0.0009 + (lw / 360) + n;

  //Using the approximate value, calculate the mean solar anomaly. This will
  //get a very close value to the actual mean solar anomaly.
  //M = [357.5291 + 0.98560028 * (J* - 2451545)] mod 360
  M := (357.5291 + 0.98560028 * (jDate - 2451545));
  M1 := Trunc(M);
  tmp := M - M1;
  M1 := M1 div 360;
  M := M - (M1 * 360) + tmp;

  //Calculate the equation of center
  C := (1.9148 * sin_d(M)) + (0.0200 * sin_d(2 * M)) + (0.0003 * sin_d(3 * M));

  //Now, using C and M, calculate the ecliptical longitude of the sun.
  //lambda := (M + 102.9372 + C + 180) mod 360;
  lambda := (M + 102.9372 + C + 180);
  M1 := Trunc(lambda);
  tmp := lambda - M1;
  M1 := M1 div 360;
  lambda := lambda - (M1 * 360) + tmp;
  //Writeln('lambda:',FloatToStr(lambda));

  //Now there is enough data to calculate an accurate Julian date for solar noon.
  jDate := jDate + (0.0053 * sin_d(M)) - (0.0069 * sin_d(2 * lambda));
  Jtran := jDate;
  //Writeln('Jtran:',FloatToStr(Jtran));

  //To calculate the hour angle we need to find the declination of the sun
  delta := arcsin_d(sin_d(lambda) * sin_d(23.45));
  //Writeln('Delta:',FloatToStr(delta));

  //Now, calculate the hour angle, which corresponds to half of the arc
  //length of the sun at this latitude at this declination of the sun
  H := arccos_d((sin_d(-0.83) - sin_d(ln) * sin_d(delta)) / (cos_d(ln) * cos_d(delta)));
  //Writeln('H:',FloatToStr(H));
  //Note: If H is undefined, then there is either no sunrise (in winter) or
  //no sunset (in summer) for the supplied latitude.

  //Okay, time to go back through the approximation again, this time we use H
  //in the calculation
  jDate := 2451545 + 0.0009 + ((H + lw) / 360) + n;
  //Writeln('jDate:',FloatToStr(jDate));

  //The values of M and lambda from above don't really change from solar noon to sunset,
  //so there is no need to recalculate them before calculating sunset.
  SunSet := jDate + (0.0053 * sin_d(M)) - (0.0069 * sin_d(2 * lambda));
  //Writeln('SunSet:',FloatToStr(SunSet));

  //Instead of going through that mess again, assume that solar noon
  //is half-way between sunrise and sunset (valid for latitudes < 60) and
  //approximate sunrise.
  SunRise := Jtran - (SunSet - Jtran);
  //Writeln('SunRise:',FloatToStr(SunRise));

  SunRise := JulianDateToDateTime(SunRise);
  SunSet := JulianDateToDateTime(SunSet);
end;

procedure TdmUtils.ExecuteCommand(cmd: string);
var
  AProcess: TProcess;
  index     :integer;
  paramList : TStringList;
begin
  AProcess := TProcess.Create(nil);
  try
    index:=0;
    paramList := TStringList.Create;
    paramList.Delimiter := ' ';
    paramList.DelimitedText := cmd;
    AProcess.Parameters.Clear;
    while index < paramList.Count do
    begin
      if (index = 0) then AProcess.Executable := paramList[index]
        else AProcess.Parameters.Add(paramList[index]);
      inc(index);
    end;
    paramList.Free;
    if dmData.DebugLevel>=1 then Writeln('AProcess.Executable: ',AProcess.Executable,' Parameters: ',AProcess.Parameters.Text);
    AProcess.Options := AProcess.Options + [poWaitOnExit];
    AProcess.Execute
  finally
    AProcess.Free
  end;
end;

function TdmUtils.CallTrim(call: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 1 to Length(call) do
  begin
    if (call[i] in AllowedCallChars) then
      Result := Result + call[i];
  end;
end;

function TdmUtils.GetQSLVia(Text: string): string;
begin
  Text := UpperCase(Text);
  Result := Text;
  if Text = 'BURO OR DIRECT' then
    Result := '';
  if Text = 'BURO' then
    Result := '';
  if Text = 'VIA BURO' then
    Result := '';
  if Pos('QSL VIA', Text) = 1 then
    Result := copy(Text, 8, Length(Text) - 7);
  if Pos('VIA', Text) = 1 then
    Result := copy(Text, 5, Length(Text) - 4);
  //Writeln('GetQSLVia:',text);
  //Writeln('GetQSLVia:',Result);
end;

function TdmUtils.IsQSLViaValid(Text: string): boolean;
begin
  Result :=false;
  if Text='' then exit; //do not allow empty RegExp
  reg.InputString := Text;
  reg.Expression := '\A\w{1,2}\d[A-Z]{1,3}\Z';
  Result := reg.ExecPos(1);
end;

function TdmUtils.GetShortState(state: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 1 to 50 do
  begin
    if Pos(state, USstates[i]) > 0 then
    begin
      Result := copy(USstates[i], 1, 2);
      Break;
    end;
  end;
end;

procedure TdmUtils.RunOnBackground(path: string);
var
  AProcess: TProcess;
  index     :integer;
  paramList : TStringList;
begin
 if dmData.DebugLevel>=1 then Writeln('RunOnBackground start ',path);
  if (path = '') then  exit;
  //following will fail if exec does not have full path or exec is not in current directory!
  //this could be fixed by using getEnv('PATH') for search, but adding "Dos" unit that is then neeed (laz 2.0.12)
  //breaks all FindFIle searches in other procedures (fpc bug or property?)
  //Easy Fix will be to require full path at preferences/External Viewers   (OH1KH 2021.05.21)

  AProcess := TProcess.Create(nil);
  try
      index:=0;
      paramList := TStringList.Create;
      paramList.Delimiter := ' ';
      paramList.DelimitedText := path;
      AProcess.Parameters.Clear;
      while index < paramList.Count do
      begin
        if (index = 0) then AProcess.Executable := paramList[index]
          else AProcess.Parameters.Add(paramList[index]);
        inc(index);
      end;
      paramList.Free;
    if dmData.DebugLevel>=1 then
     Writeln('AProcess.Executable: ',AProcess.Executable,' Parameters: ',AProcess.Parameters.Text);
    if FileExists(AProcess.Executable) then AProcess.Execute
      else if dmData.DebugLevel>=1 then writeln(AProcess.Executable,' not found!');
  finally
    AProcess.Free
  end;
end;

function TdmUtils.GetQRZInfo(call: string;
  var nick, qth, address, zip, grid, state, county, qsl, iota, waz, itu, ErrMsg: string): boolean;
var
  http: THTTPSend;
  req: string = '';
  m: TStringList;
begin
  Result := False;
  address := '';
  grid := '';
  state := '';
  county := '';
  qsl := '';
  ErrMsg := '';
  if fQRZSession = '' then
  begin
    if not GetQRZSession(ErrMsg) then
      exit;
  end;
  http := THTTPSend.Create;
  m := TStringList.Create;
  try
    http.ProxyHost := cqrini.ReadString('Program', 'Proxy', '');
    http.ProxyPort := cqrini.ReadString('Program', 'Port', '');
    http.UserName := cqrini.ReadString('Program', 'User', '');
    http.Password := cqrini.ReadString('Program', 'Passwd', '');
    if (call = '') then
    begin
      ErrMsg := 'Callsign field empty!';
      exit;
    end;
    req := 'https://xml.qrz.com/xml/1.34?s=' + fQRZSession + ';callsign=' + GetIDCall(call);
    if not HTTP.HTTPMethod('GET', req) then
      ErrMsg := '(' + IntToStr(http.ResultCode) + '):' + http.ResultString
    else
    begin
      m.LoadFromStream(http.Document);
      if Pos('<Error>Session Timeout</Error>', m.Text) > 0 then
      begin
        fQRZSession := '';
        Result := GetQRZInfo(call, nick, qth, address, zip, grid, state,
          county, qsl, iota, waz, itu, ErrMsg);
      end
      else
      begin
        if Pos('<Error>Not found:', m.Text) > 0 then
          exit;
        nick := GetTagValue(m.Text, '<fname>');
        if Pos(' ', nick) > 0 then
          nick := copy(nick, 1, Pos(' ', nick) - 1);
        if Length(nick) > 0 then
        begin
          nick := LowerCase(nick);
          nick[1] := upCase(nick[1]);
        end;
        qth := GetTagValue(m.Text, '<addr2>');
        state := GetTagValue(m.Text, '<state>');
        zip := GetTagValue(m.Text, '<zip>');
        address := GetTagValue(m.Text, '<fname>') + ' ' + GetTagValue(m.Text, '<name>') +
          LineEnding + GetTagValue(m.Text, '<addr1>') + LineEnding +
          GetTagValue(m.Text, '<addr2>');
        if (state <> '') then
          address := address + ', ' + state;
        address := address + ' ' + zip;
        county := GetTagValue(m.Text, '<county>');
        grid := UpperCase(GetTagValue(m.Text, '<grid>'));
        qsl := GetTagValue(m.Text, '<qslmgr>');
        iota := GetTagValue(m.Text, '<iota>');
        waz := GetTagValue(m.Text, '<cqzone>');
        itu := GetTagValue(m.Text, '<ituzone>')
      end
    end
  finally
    m.Free;
    HTTP.Free
  end;
end;
function TdmUtils.GetQRZCQInfo(call: string;
  var  nick, qth, address, zip, grid, state, county, qsl, iota, waz, itu, dok, ErrMsg: string): boolean;
var
  http: THTTPSend;
  req: string = '';
  m: TStringList;
  tmp:String;
begin
  Result := False;
  nick := '';
  address := '';
  grid := '';
  state := '';
  county := '';
  qsl := '';
  ErrMsg := '';
  if fQRZCQSession = '' then
  begin
    if not GetQRZCQSession(ErrMsg) then
      exit;
  end;
  http := THTTPSend.Create;
  m := TStringList.Create;
  try
    http.ProxyHost := cqrini.ReadString('Program', 'Proxy', '');
    http.ProxyPort := cqrini.ReadString('Program', 'Port', '');
    http.UserName := cqrini.ReadString('Program', 'User', '');
    http.Password := cqrini.ReadString('Program', 'Passwd', '');
    if (call = '') then
    begin
      ErrMsg := 'Callsign field empty!';
      exit;
    end;
    req := 'https://ssl.qrzcq.com/xml?s=' + fQRZCQSession + '&callsign=' + GetIDCall(call)+'&agent=Cqrlog_'+uVersion.cVERSION;
    if not HTTP.HTTPMethod('GET', req) then
      ErrMsg := '(' + IntToStr(http.ResultCode) + '):' + http.ResultString
    else
    begin
      m.LoadFromStream(http.Document);
      if Pos(UpperCase('<Error>Session Timeout</Error>'), UpperCase(m.Text)) > 0 then
      begin
        fQRZCQSession := '';
        cqrini.WriteString('CallBook', 'CbQRZCQKey', fQRZCQSession);
        Result := GetQRZCQInfo(call, nick, qth, address, zip, grid, state,
          county, qsl, iota, waz, itu, dok, ErrMsg);
      end
      else
      begin
        if Pos('<Error>Not found:', m.Text) > 0 then
          exit;

        nick:= GetTagValue(m.Text, '<name>');
        if WordCount(nick,[' ']) >2 then //There may be nickname after true name
          Begin
            tmp := ExtractWord(2,nick,[' ']);
            nick:= ExtractWord(1,nick,[' ']);
            if ((pos('(',tmp)>0)
             or (pos('"',tmp)>0)
             or (pos(#$27,tmp)>0)  // '
             or (pos('[',tmp)>0)
             or (pos('{',tmp)>0) ) then //There may be nickname after true name
               nick:= nick+' '+tmp;
          end
         else
          nick:= ExtractWord(1,nick,[' ']);
        qth := GetTagValue(m.Text, '<qth>');
        state := GetTagValue(m.Text, '<state>');
        zip := GetTagValue(m.Text, '<zip>');
        address := GetTagValue(m.Text, '<name>') + LineEnding +
          GetTagValue(m.Text, '<address>') + LineEnding;
        if (state <> '') then
          address := address + ', ' + state;
        address := address + ' ' + zip;
        county := GetTagValue(m.Text, '<county>');
        grid := UpperCase(GetTagValue(m.Text, '<locator>'));
        qsl := GetTagValue(m.Text, '<manager>');
        iota := GetTagValue(m.Text, '<iota>');
        waz := GetTagValue(m.Text, '<cq>');
        itu := GetTagValue(m.Text, '<itu>');
        dok := GetTagValue(m.Text, '<dok>')
      end
    end
  finally
    m.Free;
    HTTP.Free
  end;
end;
procedure TdmUtils.SaveWindowPos(a: TForm);
var
  section: string = '';
begin
  if dmData.DBName = '' then
    exit;
  section := a.Name;
  if a.WindowState = wsMaximized then
    cqrini.WriteBool(section, 'Max', True, cqrini.LocalOnly('WindowSize'))
  else
  begin
    cqrini.WriteInteger(section, 'Height', a.Height, cqrini.LocalOnly('WindowSize'));
    cqrini.WriteInteger(section, 'Width', a.Width, cqrini.LocalOnly('WindowSize'));
    cqrini.WriteInteger(section, 'Top', a.Top, cqrini.LocalOnly('WindowSize'));
    cqrini.WriteInteger(section, 'Left', a.Left, cqrini.LocalOnly('WindowSize'));
    cqrini.WriteBool(section, 'Max', False, cqrini.LocalOnly('WindowSize'));
  end;
  if dmData.DebugLevel >= 1 then
  begin
    Writeln('Section:',section);
    Writeln('Saving window size a position (',a.Name,') (height|width|top|left):',
            a.height,'|',a.Width,'|',a.top,'|',a.left)
  end;
end;

procedure TdmUtils.LoadWindowPos(a: TForm);
var
  section: string = '';
begin
  section := a.Name;
  LoadFontSettings(a);
  if cqrini.ReadBool(section, 'Max', False, cqrini.LocalOnly('WindowSize')) then
    a.WindowState := wsMaximized
  else
  begin
    if (a.BorderStyle <> bsDialog) then
    begin
      a.Height := cqrini.ReadInteger(section, 'Height', a.Height, cqrini.LocalOnly('WindowSize'));
      a.Width := cqrini.ReadInteger(section, 'Width', a.Width, cqrini.LocalOnly('WindowSize'));
    end;
    a.Top := cqrini.ReadInteger(section, 'Top', 20, cqrini.LocalOnly('WindowSize'));
    a.Left := cqrini.ReadInteger(section, 'Left', 20, cqrini.LocalOnly('WindowSize'));
  end;
  if dmData.DebugLevel >= 1 then
  begin
    //Writeln('Section:',section);
    //Writeln('Loading window size a position (',a.Name,') (height|width|top|left):',
    //        a.height,'|',a.Width,'|',a.top,'|',a.left)
  end;
end;

function TdmUtils.GetCallForAttach(call: string): string;
begin
  Result := LowerCase(StringReplace(call, '/', '_', [rfReplaceAll, rfIgnoreCase]));
end;

function TdmUtils.GetCallAttachDir(call: string): string;
begin
  call := GetCallForAttach(call);
  Result := dmData.HomeDir + 'call_data' + PathDelim + call;
end;

function TdmUtils.GetHomeDirectory: string;
begin
  Result := GetAppConfigFile(False);
  Result := Copy(Result, 1, Pos('/.', Result) - 1);
  Result := AppendPathDelim(Result);
end;


function TdmUtils.FindInMailCap(mime: string): string;
const
  READ_ONLY = 0;
  WRITE_ONLY = 1;
  READ_WRITE = 2;

var
  f: Text;
  fm: byte;
  tmp: string = '';
begin
  Result := '';
  if Length(mime) = 0 then
    exit;
  fm := Filemode;
  try
    Filemode := READ_ONLY;
    if FileExists(GetHomeDirectory + '.mailcap') then
    begin
      AssignFile(f, GetHomeDirectory + '.mailcap');
      Reset(f);
      while not EOF(f) do
      begin
        ReadLn(f, tmp);
        if Pos(mime + ';', tmp) = 1 then
        begin
          tmp := copy(tmp, Pos(';', tmp) + 1, 100);
          tmp := copy(tmp, 1, Pos(#39, tmp) - 1);
          Result := tmp;
          break;
        end;
      end;
      CloseFile(f);
    end;
    if Result <> '' then  //we find right application for our file
      exit;

    AssignFile(f, '/etc/mailcap');
    Reset(f);
    while not EOF(f) do
    begin
      ReadLn(f, tmp);
      if Pos(mime + ';', tmp) = 1 then
      begin
        tmp := copy(tmp, Pos(';', tmp) + 1, 100);
        tmp := copy(tmp, 1, Pos(#39, tmp) - 1);
        Result := tmp;
        //break
        // we can't stop looking for rigth application. When user install e.g. abiword
        // it also takes palain/text mime type. So last installed app with this mime type
        // must be find. (The first one is console less command.
      end;
    end;
    CloseFile(f)
  finally
    Filemode := fm
  end;
end;


function TdmUtils.GetApplicationName(FileExt: string): string;
const
  READ_ONLY = 0;
  WRITE_ONLY = 1;
  READ_WRITE = 2;

var
  f: Text;
  fm: byte;
  tmp: string = '';
  p: word;
begin
  Result := '';
  if Length(FileExt) = 0 then
    exit;
  if FileExt[1] = '.' then
    FileExt := Copy(FileExt, 2, Length(FileExt) - 1);
  fm := Filemode;
  try
    Filemode := READ_ONLY;
    AssignFile(f, '/etc/mime.types');
    Reset(f);
    while not EOF(f) do
    begin
      ReadLn(f, tmp);
      p := Pos(#9, tmp);
      if p = 0 then
        p := Pos(' ', tmp);
      if p = 0 then
        Continue;
      if Pos(FileExt, trim(copy(tmp, p, 100))) > 0 then
      begin //find file extension
        Result := copy(tmp, 1, p - 1);  //copying mime type of a file
        Break;
      end
      else
        Continue;  //we must process next line from file
    end;
    if Result = '' then
      exit;  //we couldn't find mime type of that file
    Result := trim(FindInMailCap(Result));
    //Writeln('Result: ',Result)
  finally
    CloseFile(f);
    Filemode := fm
  end;
end;

function TdmUtils.QSLFrontImageExists(fCall: string): string;
var
  s: string;
begin
  Result := '';
  s := GetCallAttachDir(fCall) + PathDelim + 'qsl_' + fCall + '_front';
  if FileExists(s + '.png') then
    Result := s + '.png'
  else
  begin
    if FileExists(s + '.jpg') then
      Result := s + '.jpg';
  end;
end;

function TdmUtils.QSLBackImageExists(fCall: string): string;
var
  s: string;
begin
  Result := '';
  s := GetCallAttachDir(fCall) + PathDelim + 'qsl_' + fCall + '_back';
  if FileExists(s + '.png') then
    Result := s + '.png'
  else
  begin
    if FileExists(s + '.jpg') then
      Result := s + '.jpg';
  end;
end;

procedure TdmUtils.ShowQSLWithExtViewer(Call: string);
var
  dir: string;
  prg: string;
  qsl: string;
begin
  call := GetCallForAttach(call);
  qsl := QSLFrontImageExists(call);
  if qsl = '' then
    exit;
  dir := GetCurrentDir;
  try
    SetCurrentDir(dmData.HomeDir + 'call_data' + PathDelim + call + PathDelim);
    prg := cqrini.ReadString('ExtView', 'img', 'eog');
    if prg = '' then
      dmUtils.RunOnBackground(cqrini.ReadString('Program', 'WebBrowser', MyDefaultBrowser) +
        ' ' + qsl)
    else
      dmUtils.RunOnBackground(prg + ' ' + qsl)
  finally
    SetCurrentDir(dir)
  end;
end;

function TdmUtils.IsValidFileName(const fileName: string): boolean;
const
  InvalidCharacters: set of char = ['\', '/', ':', '*', '?', '"', '<', '>', '|'];
var
  cnt: integer;
begin
  Result := fileName <> '';
  if Result then
  begin
    for cnt := 1 to Length(fileName) do
    begin
      Result := not (fileName[cnt] in InvalidCharacters);
      if not Result then
        break;
    end;
  end;
end;

procedure TdmUtils.ShowQRZInBrowser(call: string);
var
  AProcess: TProcess;
begin
  AProcess := TProcess.Create(nil);
  try
    AProcess.Executable := cqrini.ReadString('Program', 'WebBrowser', MyDefaultBrowser);
    AProcess.Parameters.Add('https://www.qrz.com/db/' + GetIDCall(call));
    if dmData.DebugLevel>=1 then Writeln('AProcess.Executable: ',AProcess.Executable,' Parameters: ',AProcess.Parameters.Text);
    AProcess.Execute
  finally
    AProcess.Free
  end;
end;

procedure TdmUtils.ShowLocatorMapInBrowser(locator: string);
var
  AProcess: TProcess;
  myloc: string = '';
begin
  myloc := cqrini.ReadString('Station', 'LOC', '');
  AProcess := TProcess.Create(nil);
  try
    AProcess.Executable := cqrini.ReadString('Program', 'WebBrowser', MyDefaultBrowser);
    AProcess.Parameters.Add('https://www.k7fry.com/grid/?qth=' + locator + '&from=' + myloc);
    if dmData.DebugLevel>=1 then Writeln('AProcess.Executable: ',AProcess.Executable,' Parameters: ',AProcess.Parameters.Text);
    AProcess.Execute
  finally
    AProcess.Free
  end;
end;

procedure TdmUtils.LoadBandsSettings;
var
  i: integer;
begin
  //init user defined bands vs frequencies
  dmUtils.BandFromDbase;

  LoadBandLabelSettins;
  for i := 0 to cMaxBandsCount - 1 do
  begin
    MyBands[i][0] := '';
    MyBands[i][1] := '';
  end;

  i := 0;
  if cqrini.ReadBool('Bands', '137kHz', False) then
  begin
    MyBands[i][0] := '2190M';
    MyBands[i][1] := s136;
    Inc(i);
  end;
  if cqrini.ReadBool('Bands', '472kHz', False) then
  begin
    MyBands[i][0] := '630M';
    MyBands[i][1] := s630;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '160m', True) then
  begin
    MyBands[i][0] := '160M';
    MyBands[i][1] := s160;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '80m', True) then
  begin
    MyBands[i][0] := '80M';
    MyBands[i][1] := s80;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '60m', False) then
  begin
    MyBands[i][0] := '60M';
    MyBands[i][1] := s60;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '40m', True) then
  begin
    MyBands[i][0] := '40M';
    MyBands[i][1] := s40;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '30m', True) then
  begin
    MyBands[i][0] := '30M';
    MyBands[i][1] := s30;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '20m', True) then
  begin
    MyBands[i][0] := '20M';
    MyBands[i][1] := s20;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '17m', True) then
  begin
    MyBands[i][0] := '17M';
    MyBands[i][1] := s17;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '15m', True) then
  begin
    MyBands[i][0] := '15M';
    MyBands[i][1] := s15;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '12m', True) then
  begin
    MyBands[i][0] := '12M';
    MyBands[i][1] := s12;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '10m', True) then
  begin
    MyBands[i][0] := '10M';
    MyBands[i][1] := s10;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '6m', True) then
  begin
    MyBands[i][0] := '6M';
    MyBands[i][1] := s6;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '4m', False) then
  begin
    MyBands[i][0] := '4M';
    MyBands[i][1] := s4;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '1.25m', False) then
  begin
    MyBands[i][0] := '1.25M';
    MyBands[i][1] := s220;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '2m', True) then
  begin
    MyBands[i][0] := '2M';
    MyBands[i][1] := s2;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '70cm', True) then
  begin
    MyBands[i][0] := '70CM';
    MyBands[i][1] := s70;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '33cm', False) then
  begin
    MyBands[i][0] := '33CM';
    MyBands[i][1] := s900;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '23cm', False) then
  begin
    MyBands[i][0] := '23CM';
    MyBands[i][1] := s1260;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '13cm', False) then
  begin
    MyBands[i][0] := '13CM';
    MyBands[i][1] := s2300;
    Inc(i);
  end;
  if cqrini.ReadBool('Bands', '8cm', False) then
  begin
    MyBands[i][0] := '9CM';
    MyBands[i][1] := s3400;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '5cm', False) then
  begin
    MyBands[i][0] := '6CM';
    MyBands[i][1] := s5850;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '3cm', False) then
  begin
    MyBands[i][0] := '3CM';
    MyBands[i][1] := s10G;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '1cm', False) then
  begin
    MyBands[i][0] := '1.25CM';
    MyBands[i][1] := s24G;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '47GHz', False) then
  begin
    MyBands[i][0] := '6MM';
    MyBands[i][1] := s47G;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '76GHz', False) then
  begin
    MyBands[i][0] := '4MM';
    MyBands[i][1] := s76G;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '122GHz', False) then
  begin
    MyBands[i][0] := '2.5MM';
    MyBands[i][1] := s122G;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '134GHz', False) then
  begin
    MyBands[i][0] := '2MM';
    MyBands[i][1] := s134G;
    Inc(i);
  end;

  if cqrini.ReadBool('Bands', '241GHz', False) then
  begin
    MyBands[i][0] := '1MM';
    MyBands[i][1] := s241G;
    Inc(i);
  end;

end;

function TdmUtils.GetBandPos(band: string): integer;
var
  i: integer;
begin
  Result := -1;
  if band = '' then
    exit;
  for i := 0 to cMaxBandsCount - 1 do
  begin
    if band = MyBands[i][0] then
    begin
      Result := i;
      Break;
    end;
  end;
end;

function TdmUtils.GetNewQSOCaption(capt: string): string;
begin
  Result := capt + ' ... (CQRLOG for Linux)';
  if dmData.LogName <> '' then
    Result := Result + ', database: ' + dmData.LogName;
end;

procedure TdmUtils.FillBandCombo(cmb: TComboBox);
var
  i: integer;
begin
  cmb.Clear;
  for i := 0 to Length(MyBands) - 1 do
  begin
    if MyBands[i][0] = '' then
      break;
    cmb.Items.Add(MyBands[i][0]);
  end;
end;

function TdmUtils.GetCallBookData(call: string;
  var nick, qth, address, zip, grid, state, county, qsl, iota, waz, itu, dok,  ErrMsg: string): boolean;
begin
  if cqrini.ReadBool('Callbook', 'QRZ', False) then
    Result := GetQRZInfo(call, nick, qth, address, zip, grid, state, county, qsl, iota, waz, itu, ErrMsg) ;
  if cqrini.ReadBool('Callbook', 'QRZCQ', False) then
    Result := GetQRZCQInfo(call, nick, qth, address, zip, grid, state, county, qsl, iota, waz, itu, dok, ErrMsg) ;
  if cqrini.ReadBool('Callbook', 'HamQTH', False) then
    Result := GetHamQTHInfo(call, nick, qth, address, zip, grid, state, county, qsl, iota, waz, itu, dok, ErrMsg)
end;

function TdmUtils.GetTagValue(Data, tg: string): string;
var
  EndTag: string;
  p: word;
begin
  Result := '';
  EndTag := '</' + copy(tg, 2, Length(tg) - 1);
  p := Pos(tg, Data);
  if p > 0 then
  begin
    Result := copy(Data, p + Length(tg), Pos(EndTag, Data) - p - Length(tg));
    Result := Trim(Result);
    if dmData.DebugLevel >= 1 then
    begin
      Writeln('Tag: ', tg, '    Value: ', Result);
    end;
  end;
end;

function TdmUtils.GetQRZSession(var ErrMsg: string): boolean;
var
  http: THTTPSend;
  req: string = '';
  m: TStringList;
  epos: word;
  kpos: word;
begin
  Result := False;
  if (cqrini.ReadString('CallBook', 'CbQRZUser', '') = '') or
    (cqrini.ReadString('CallBook', 'CbQRZPass', '') = '') then
  begin
    ErrMsg := 'Empty password or user name';
    exit;
  end;
  http := THTTPSend.Create;
  m := TStringList.Create;
  try
    http.ProxyHost := cqrini.ReadString('Program', 'Proxy', '');
    http.ProxyPort := cqrini.ReadString('Program', 'Port', '');
    http.UserName := cqrini.ReadString('Program', 'User', '');
    http.Password := cqrini.ReadString('Program', 'Passwd', '');
    req := 'https://xmldata.qrz.com/xml/1.34?username=' + cqrini.ReadString(
      'CallBook', 'CbQRZUser', '') + ';password=' + cqrini.ReadString(
      'CallBook', 'CbQRZPass', '') + ';agent=Cqrlog_'+uVersion.cVERSION;
    if not HTTP.HTTPMethod('GET', req) then
      ErrMsg := '(' + IntToStr(http.ResultCode) + '):' + http.ResultString
    else
    begin
      m.LoadFromStream(http.Document);
      if dmData.DebugLevel >= 1 then
        Writeln(m.Text);
      //I'd like to parse it as normal XML but it seems XML support in Freepascal
      //2.4.0 is broken :-(
      epos := Pos('<Error>', m.Text);
      if epos > 0 then
        ErrMsg := copy(m.Text, epos + 7, Pos('</Error>', m.Text) - epos - 7)
      else
      begin
        kpos := Pos('<Key>', m.Text);
        if kpos > 0 then
        begin
          fQRZSession := copy(m.Text, kpos + 5, Pos('</Key>', m.Text) - kpos - 5);
          Result := True;
        end
        else
          ErrMsg := 'Tag "<Key>" not found!';
      end;
    end
  finally
    m.Free;
    HTTP.Free
  end;
end;
function TdmUtils.GetQRZCQSession(var ErrMsg: string): boolean;
var
  http: THTTPSend;
  req: string = '';
  m: TStringList;
  epos: word;
  kpos: word;
begin
  fQRZCQSession:= cqrini.ReadString('CallBook', 'CbQRZCQKey','');
  if fQRZCQSession<>'' then
                       Begin
                         Result:=true;
                         exit;
                       end;
  Result := False;
  if (cqrini.ReadString('CallBook', 'CbQRZCQUser', '') = '') or
    (cqrini.ReadString('CallBook', 'CbQRZCQPass', '') = '') then
  begin
    ErrMsg := 'Empty password or user name';
    exit;
  end;
  http := THTTPSend.Create;
  m := TStringList.Create;
  try
    http.ProxyHost := cqrini.ReadString('Program', 'Proxy', '');
    http.ProxyPort := cqrini.ReadString('Program', 'Port', '');
    http.UserName := cqrini.ReadString('Program', 'User', '');
    http.Password := cqrini.ReadString('Program', 'Passwd', '');
    req := 'https://ssl.qrzcq.com/xml?username=' + cqrini.ReadString(
      'CallBook', 'CbQRZCQUser', '') + '&password=' + cqrini.ReadString(
      'CallBook', 'CbQRZCQPass', '') + '&agent=Cqrlog_'+uVersion.cVERSION;
    if not HTTP.HTTPMethod('GET', req) then
      ErrMsg := '(' + IntToStr(http.ResultCode) + '):' + http.ResultString
    else
    begin
      m.LoadFromStream(http.Document);
      if dmData.DebugLevel >= 1 then
        Writeln(m.Text);
      //I'd like to parse it as normal XML but it seems XML support in Freepascal
      //2.4.0 is broken :-(
      epos := Pos('<Error>', m.Text);
      if epos > 0 then
        ErrMsg := copy(m.Text, epos + 7, Pos('</Error>', m.Text) - epos - 7)
      else
      begin
        kpos := Pos('<Key>', m.Text);
        if kpos > 0 then
        begin
          fQRZCQSession := copy(m.Text, kpos + 5, Pos('</Key>', m.Text) - kpos - 5);
          cqrini.WriteString('CallBook', 'CbQRZCQKey', fQRZCQSession);
          Result := True;
        end
        else
          ErrMsg := 'Tag "<Key>" not found!';
      end;
    end
  finally
    m.Free;
    HTTP.Free
  end;
end;

function TdmUtils.GetHamQTHSession(var ErrMsg: string): boolean;
var
  http: THTTPSend;
  req: string = '';
  m: TStringList;
begin
  Result := False;
  if (cqrini.ReadString('CallBook', 'CbHamQTHUser', '') = '') or
    (cqrini.ReadString('CallBook', 'CbHamQTHPass', '') = '') then
  begin
    ErrMsg := 'Empty password or user name';
    exit;
  end;
  http := THTTPSend.Create;
  m := TStringList.Create;
  try
    http.ProxyHost := cqrini.ReadString('Program', 'Proxy', '');
    http.ProxyPort := cqrini.ReadString('Program', 'Port', '');
    http.UserName := cqrini.ReadString('Program', 'User', '');
    http.Password := cqrini.ReadString('Program', 'Passwd', '');
    req := 'http://www.hamqth.com/xml.php?u=' + cqrini.ReadString('CallBook', 'CbHamQTHUser', '') +
      '&p=' + EncodeURLData(cqrini.ReadString('CallBook', 'CbHamQTHPass', '')) + '&prg=Cqrlog_'+uVersion.cVERSION;
    //Writeln(req);
    if not HTTP.HTTPMethod('GET', req) then
      ErrMsg := '(' + IntToStr(http.ResultCode) + '):' + http.ResultString
    else
    begin
      m.LoadFromStream(http.Document);
      if dmData.DebugLevel >= 1 then
        Writeln(m.Text);
      //I'd like to parse it as normal XML but it seems XML support in Freepascal
      //2.4.0 is broken :-(
      ErrMsg := GetTagValue(m.Text, '<Error>');
      if (ErrMsg = '') then
      begin
        fHamQTHSession := GetTagValue(m.Text, '<session_id>');
        if fHamQTHSession = '' then
          ErrMsg := 'Tag "<session_id>" not found!'
        else
          Result := True;
      end;
    end
  finally
    m.Free;
    HTTP.Free
  end;
end;

function TdmUtils.GetHamQTHInfo(call: string;
  var nick, qth, address, zip, grid, state, county, qsl, iota, waz, itu, dok, ErrMsg: string): boolean;
var
  http: THTTPSend;
  req: string = '';
  m: TStringList;
  tmp: string;
begin
  Result := False;
  address := '';
  grid := '';
  state := '';
  county := '';
  qsl := '';
  dok := '';
  ErrMsg := '';
  if fHamQTHSession = '' then
  begin
    if not GetHamQTHSession(ErrMsg) then
      exit;
  end;
  http := THTTPSend.Create;
  m := TStringList.Create;
  try
    http.ProxyHost := cqrini.ReadString('Program', 'Proxy', '');
    http.ProxyPort := cqrini.ReadString('Program', 'Port', '');
    http.UserName := cqrini.ReadString('Program', 'User', '');
    http.Password := cqrini.ReadString('Program', 'Passwd', '');
    if (call = '') then
    begin
      ErrMsg := 'Callsign field empty!';
      exit;
    end;
    req := 'http://www.hamqth.com/xml.php?id=' + fHamQTHSession + '&callsign=' +
      GetIDCall(call) + '&prg=CQRLOG';
    if not HTTP.HTTPMethod('GET', req) then
      ErrMsg := '(' + IntToStr(http.ResultCode) + '):' + http.ResultString
    else
    begin
      m.LoadFromStream(http.Document);
      if dmData.DebugLevel >= 1 then
        Writeln(m.Text);
      if Pos('<error>Session does not exist or expired</error>', m.Text) > 0 then
      begin
        fHamQTHSession := '';
        Result := GetHamQTHInfo(call, nick, qth, address, zip, grid, state,
          county, qsl, iota, waz, itu, dok, ErrMsg)
      end
      else
      begin
        if Pos('<error>Callsign not found', m.Text) > 0 then
        begin
          ErrMsg := 'Callsign not found';
          exit;
        end;
        nick := GetTagValue(m.Text, '<nick>');
        if Pos(' ', nick) > 0 then
          nick := copy(nick, 1, Pos(' ', nick) - 1);
        if Length(nick) > 0 then
        begin
          nick := LowerCase(nick);
          nick[1] := upCase(nick[1]);
        end;
        qth := GetTagValue(m.Text, '<qth>');
        state := GetTagValue(m.Text, '<us_state>');
        zip := GetTagValue(m.Text, '<adr_zip>');
        address := GetTagValue(m.Text, '<adr_name>') + LineEnding +
          GetTagValue(m.Text, '<adr_street1>') + LineEnding;
        tmp := GetTagValue(m.Text, '<adr_street2>');
        if tmp <> '' then
          address := address + tmp + LineEnding;
        tmp := GetTagValue(m.Text, '<adr_street3>');
        if tmp <> '' then
          address := address + tmp + LineEnding;
        address := address + GetTagValue(m.Text, '<adr_city>');
        if (state <> '') then
          address := address + ', ' + state;
        address := address + ' ' + zip;
        county := GetTagValue(m.Text, '<us_county>');
        grid := UpperCase(GetTagValue(m.Text, '<grid>'));
        qsl := GetTagValue(m.Text, '<qsl_via>');
        iota := GetTagValue(m.Text, '<iota>');
        waz := GetTagValue(m.Text, '<cq>');
        itu := GetTagValue(m.Text, '<itu>');
        //DL7OAP: DOK can be 'H24', 'h 24' or 'H-24', etc.
        //thats why we clean it with RegExp so only letters and figures are left
        dok := GetTagValue(m.Text, '<dok>');
        if (trim(dok) <> '') then
           dok := ReplaceRegExpr('[^a-zA-Z0-9]', dok, '', True); //ARegExpr, AInputStr, AReplaceStr
        dok := LeftStr(UpperCase(dok),12); // now all upcase and cut to maximal length of 12 of dok field
      end
    end
  finally
    m.Free;
    HTTP.Free
  end;
end;
procedure TdmUtils.ShowHamQTHInBrowser(call: string);
var
  AProcess: TProcess;
begin
  AProcess := TProcess.Create(nil);
  try
    AProcess.Executable  := cqrini.ReadString('Program', 'WebBrowser', MyDefaultBrowser);
    AProcess.Parameters.Add('http://www.hamqth.com/' + GetIDCall(call));
    if dmData.DebugLevel>=1 then ;
    Writeln('AProcess.Executable: ',AProcess.Executable,' Parameters: ',AProcess.Parameters.Text);
    AProcess.Execute
  finally
    AProcess.Free
  end;
end;
procedure TdmUtils.ShowUsrUrl;
var
  AProcess: TProcess;
  cmd       :String;
begin
  cmd := cqrini.ReadString('NewQSO', 'UsrBtn', 'https://www.qrzcq.com/call/$CALL');
  if (cmd<>'') then
   begin
      AProcess := TProcess.Create(nil);
      try
          cmd := StringReplace(cmd,'$CALL',frmNewQSO.edtCall.Text,[rfReplaceAll]);
          cmd := StringReplace(cmd,'$BAND',dmUtils.GetBandFromFreq(frmNewQSO.cmbFreq.Text),[rfReplaceAll]);
          cmd := StringReplace(cmd,'$MODE',frmNewQSO.cmbFreq.Text,[rfReplaceAll]);
          cmd := StringReplace(cmd,'$FREQ',frmNewQSO.cmbMode.Text,[rfReplaceAll]);
          cmd := StringReplace(cmd,'$LOC',frmNewQSO.edtGrid.Text,[rfReplaceAll]);
          if not(frmNewQSO.fEditQSO or frmNewQSO.fViewQSO) then
             cmd := StringReplace(cmd,'$MYLOC',frmNewQSO.CurrentMyLoc,[rfReplaceAll])
            else  cmd := StringReplace(cmd,'$MYLOC',frmNewQSO.EditViewMyLoc,[rfReplaceAll]);
        AProcess.Executable  := cqrini.ReadString('Program', 'WebBrowser', MyDefaultBrowser);
        AProcess.Parameters.Add(cmd);
        if dmData.DebugLevel>=1 then ;
        Writeln('AProcess.Executable: ',AProcess.Executable,' Parameters: ',AProcess.Parameters.Text);
        AProcess.Execute
      finally
        AProcess.Free
      end;
   end;
end;

function TdmUtils.DateInSOTAFormat(date: TDateTime): string;
var
  Sep: char;
begin
  sep := FormatSettings.DateSeparator;
  try
    FormatSettings.DateSeparator := '/';
    Result := FormatDateTime('DD/MM/YY', date)
  finally
    FormatSettings.DateSeparator := sep
  end;
end;

function TdmUtils.GetLocalUTCDelta: double;
begin
  Result := (now - GetDateTime(0)) * 24; //in hours
end;

procedure TdmUtils.SortArray(l, r: integer);
var
  i, j: integer;
  x: string;
  w: string;
begin
  i := l;
  j := r;
  x := dmData.eQSLUsers[(l + r) div 2];
  repeat
    while dmData.eQSLUsers[i] < x do
      i := i + 1;
    while x < dmData.eQSLUsers[j] do
      j := j - 1;

    if i <= j then
    begin
      w := dmData.eQSLUsers[i];
      dmData.eQSLUsers[i] := dmData.eQSLUsers[j];
      dmData.eQSLUsers[j] := w;
      i := i + 1;
      j := j - 1;
    end
  until i > j;
  if l < j then
    SortArray(l, j);
  if i < r then
    SortArray(i, r);
end;


function TdmUtils.GetRadioRigCtldCommandLine(radio: word): string;
var
  section: ShortString = '';
  arg: string = '';
  set_conf: string = '';
begin
  section := 'TRX' + IntToStr(radio);

  if cqrini.ReadString(section, 'model', '') = '' then
  begin
    Result := '';
    exit;
  end;

  //if parameter data is empty ignore parameter
  Result:='-m ' + cqrini.ReadString(section, 'model', '') + ' ';
  if  (trim(cqrini.ReadString(section, 'device', ''))<>'') then
         Result:=Result+'-r ' + cqrini.ReadString(section, 'device', '') + ' ';
  if  (trim(cqrini.ReadString(section, 'RigCtldPort', ''))<>'') then
         Result:=Result+'-t ' + cqrini.ReadString(section, 'RigCtldPort', '') + ' ';
  Result := Result + cqrini.ReadString(section, 'ExtraRigCtldArgs', '') + ' ';

  case cqrini.ReadInteger(section, 'SerialSpeed', 0) of
    0: arg := '';
    1: arg := '-s 1200 ';
    2: arg := '-s 2400 ';
    3: arg := '-s 4800 ';
    4: arg := '-s 9600 ';
    5: arg := '-s 144000 ';
    6: arg := '-s 19200 ';
    7: arg := '-s 38400 ';
    8: arg := '-s 57600 ';
    9: arg := '-s 115200 '
    else
      arg := ''
  end; //case
  Result := Result + arg;

  case cqrini.ReadInteger(section, 'DataBits', 0) of
    0: arg := '';
    1: arg := 'data_bits=5';
    2: arg := 'data_bits=6';
    3: arg := 'data_bits=7';
    4: arg := 'data_bits=8';
    5: arg := 'data_bits=9'
    else
      arg := ''
  end; //case
  if arg <> '' then
    set_conf := set_conf + arg + ',';

  if cqrini.ReadInteger(section, 'StopBits', 0) > 0 then
    set_conf := set_conf + 'stop_bits=' + IntToStr(cqrini.ReadInteger(
      section, 'StopBits', 0) - 1) + ',';

  case cqrini.ReadInteger(section, 'Parity', 0) of
    0: arg := '';
    1: arg := 'serial_parity=None';
    2: arg := 'serial_parity=Odd';
    3: arg := 'serial_parity=Even';
    4: arg := 'serial_parity=Mark';
    5: arg := 'serial_parity=Space'
    else
      arg := ''
  end; //case
  if arg <> '' then
    set_conf := set_conf + arg + ',';

  case cqrini.ReadInteger(section, 'HandShake', 0) of
    0: arg := '';
    1: arg := 'serial_handshake=None';
    2: arg := 'serial_handshake=XONXOFF';
    3: arg := 'serial_handshake=Hardware';
    else
      arg := ''
  end; //case
  if arg <> '' then
    set_conf := set_conf + arg + ',';

  case cqrini.ReadInteger(section, 'DTR', 0) of
    0: arg := '';
    1: arg := 'dtr_state=Unset';
    2: arg := 'dtr_state=ON';
    3: arg := 'dtr_state=OFF';
    else
      arg := ''
  end; //case
  if arg <> '' then
    set_conf := set_conf + arg + ',';

  case cqrini.ReadInteger(section, 'RTS', 0) of
    0: arg := '';
    1: arg := 'rts_state=Unset';
    2: arg := 'rts_state=ON';
    3: arg := 'rts_state=OFF';
    else
      arg := ''
  end; //case
  if arg <> '' then
    set_conf := set_conf + arg + ',';

  if (set_conf <> '') then
  begin
    set_conf := copy(set_conf, 1, Length(set_conf) - 1);
    Result := Result + ' --set-conf=' + set_conf;
  end;
end;

function TdmUtils.GetRotorRotCtldCommandLine(rotor: word): string;
var
  section: ShortString = '';
  arg: string = '';
  set_conf: string = '';
begin
  section := 'ROT' + IntToStr(rotor);

  if cqrini.ReadString(section, 'model', '') = '' then
  begin
    Result := '';
    exit;
  end;

   //if parameter data is empty ignore parameter
  Result:='-m ' + cqrini.ReadString(section, 'model', '') + ' ';
  if  (trim(cqrini.ReadString(section, 'device', ''))<>'') then
         Result:=Result+'-r ' + cqrini.ReadString(section, 'device', '') + ' ';
  if  (trim(cqrini.ReadString(section, 'RotCtldPort', ''))<>'') then
         Result:=Result+'-t ' + cqrini.ReadString(section, 'RotCtldPort', '') + ' ';
  Result := Result + cqrini.ReadString(section, 'ExtraRotCtldArgs', '') + ' ';

  case cqrini.ReadInteger(section, 'SerialSpeed', 0) of
    0: arg := '';
    1: arg := '-s 1200 ';
    2: arg := '-s 2400 ';
    3: arg := '-s 4800 ';
    4: arg := '-s 9600 ';
    5: arg := '-s 144000 ';
    6: arg := '-s 19200 ';
    7: arg := '-s 38400 ';
    8: arg := '-s 57600 ';
    9: arg := '-s 115200 '
    else
      arg := ''
  end; //case
  Result := Result + arg;

  case cqrini.ReadInteger(section, 'DataBits', 0) of
    0: arg := '';
    1: arg := 'data_bits=5';
    2: arg := 'data_bits=6';
    3: arg := 'data_bits=7';
    4: arg := 'data_bits=8';
    5: arg := 'data_bits=9'
    else
      arg := ''
  end; //case
  if arg <> '' then
    set_conf := set_conf + arg + ',';

  if cqrini.ReadInteger(section, 'StopBits', 0) > 0 then
    set_conf := set_conf + 'stop_bits=' + IntToStr(cqrini.ReadInteger(
      section, 'StopBits', 0) - 1) + ',';

  case cqrini.ReadInteger(section, 'Parity', 0) of
    0: arg := '';
    1: arg := 'serial_parity=None';
    2: arg := 'serial_parity=Odd';
    3: arg := 'serial_parity=Even';
    4: arg := 'serial_parity=Mark';
    5: arg := 'serial_parity=Space'
    else
      arg := ''
  end; //case
  if arg <> '' then
    set_conf := set_conf + arg + ',';

  case cqrini.ReadInteger(section, 'HandShake', 0) of
    0: arg := '';
    1: arg := 'serial_handshake=None';
    2: arg := 'serial_handshake=XONXOFF';
    3: arg := 'serial_handshake=Hardware';
    else
      arg := ''
  end; //case
  if arg <> '' then
    set_conf := set_conf + arg + ',';

  case cqrini.ReadInteger(section, 'DTR', 0) of
    0: arg := '';
    1: arg := 'dtr_state=Unset';
    2: arg := 'dtr_state=ON';
    3: arg := 'dtr_state=OFF';
    else
      arg := ''
  end; //case
  if arg <> '' then
    set_conf := set_conf + arg + ',';

  case cqrini.ReadInteger(section, 'RTS', 0) of
    0: arg := '';
    1: arg := 'rts_state=Unset';
    2: arg := 'rts_state=ON';
    3: arg := 'rts_state=OFF';
    else
      arg := ''
  end; //case
  if arg <> '' then
    set_conf := set_conf + arg + ',';

  if (set_conf <> '') then
  begin
    set_conf := copy(set_conf, 1, Length(set_conf) - 1);
    Result := Result + ' --set-conf=' + set_conf;
  end;
end;

function TdmUtils.IgnoreFreq(kHz: string): boolean;
var
  i: integer;
begin
  kHz := trim(kHz);
  Result := False;
  for i := 0 to cMaxIgnoreFreq do
  begin
    if (kHz = cIngnoreFreq[i]) then
    begin
      Result := True;
      break;
    end;
  end;
end;

function TdmUtils.HTMLEncode(const Data: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 1 to length(Data) do
  begin
    case Data[i] of
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '&': Result := Result + '&amp;';
      '"': Result := Result + '&quot;'
      else
        Result := Result + Data[i]
    end;
  end;
end;

function TdmUtils.KmToMiles(qra: double): double;
begin
  Result := Round(0.621371192 * qra);
end;

procedure TdmUtils.OpenInApp(what: string);
begin
  if ((pos('.HTML',upcase(what))>0) or (pos('.HTM',upcase(what))>0)) //because possible "hashtag in link-problem"
    then
     Begin
      RunOnBackground(cqrini.ReadString('Program', 'WebBrowser', MyDefaultBrowser) + ' ' + what);
     end
   else
    begin
      RunOnBackground('xdg-open ' + what);
    end;
end;

function TdmUtils.GetDescKeyFromCode(key: word): string;
begin
  Result := 'F' + IntToStr(Key - 111); //VK_F1 = 112
end;

function TdmUtils.EncodeURLData(data : String) : String;
var
  x: integer;
  sBuff: string;
const
  SafeMask = ['A'..'Z', '0'..'9', 'a'..'z', '*', '@', '.', '_', '-'];
begin
  sBuff := '';
  for x := 1 to Length(data) do
  begin
    if data[x] in SafeMask then
    begin
      sBuff := sBuff + data[x]
    end
    else begin
      if data[x] = ' ' then
      begin
        sBuff := sBuff + '%20'
      end
      else begin
        sBuff := sBuff + '%' + IntToHex(Ord(data[x]), 2)
      end
    end
  end;
  Result := sBuff
end;

procedure TdmUtils.LoadRigList(RigCtlBinaryPath : String;RigList : TStringList);
var
  p : TProcess;
begin
  p := TProcess.Create(nil);
  try
    p.Executable := RigCtlBinaryPath;
    p.Parameters.add('-l');
    p.Options := p.Options + [poWaitOnExit, poUsePipes];
    p.Execute;

    RigList.LoadFromStream(p.Output);
  finally
    FreeAndNil(p)
  end
end;

procedure TdmUtils.LoadRigListCombo(CurrentRigId : String; RigList : TStringList; RigComboBox : TComboBox);
var
  i       : Integer;
  RigId   : String;
  RigName : String;
  RigType : String;
  CmbText : String = '';
begin
  for i:= 1 to RigList.Count-1 do
  begin
    RigId   := trim(copy(RigList.Strings[i],1,7));
    if RigId<>'' then
    begin
      RigName := trim(copy(RigList.Strings[i],8,24));
      RigType := trim(copy(RigList.Strings[i],32,23));
      RigComboBox.Items.Add(RigId + ' ' + RigName + ' ' + RigType + ' ');
      if (RigId = CurrentRigId) then
      begin
        CmbText := RigId + ' ' + RigName + ' ' + RigType + ' '
      end
    end
  end;
  if (CmbText='') then
    RigComboBox.ItemIndex := -1
  else
    RigComboBox.Text := CmbText
end;

procedure TdmUtils.LoadRigsToComboBox(CurrentRigId : String; RigCtlBinaryPath : String; RigComboBox : TComboBox);
var
  RigList : TStringList;
begin
  RigList := TStringList.Create;
  try
    LoadRigList(RigCtlBinaryPath,RigList);
    LoadRigListCombo(CurrentRigId,RigList,RigComboBox)
  finally
    FreeAndNil(RigList)
  end
end;

function TdmUtils.GetRigIdFromComboBoxItem(ItemText : String) : String;
begin
  Result := Copy(ItemText,1,Pos(' ',ItemText)-1)
end;

procedure TdmUtils.GetShorterCoordinates(latitude,longitude : Currency; var lat, long : String);
begin
  latitude  := RoundTo(Extended(latitude),-2);
  longitude := RoundTo(Extended(longitude),-2);

  if (latitude < 0) then
    lat := FloatToStr(latitude*-1)+'S'
  else
    lat := FloatToStr(latitude);

  if (longitude < 0) then
    long := FloatToStr(longitude*-1)+'W'
  else
    long := FloatToStr(longitude)
end;

function TdmUtils.LoadVisibleColumnsConfiguration : TColumnVisibleArray;
const
  COLUMN_COUNT = 47;
var
  i : Integer;
  aColumns : TColumnVisibleArray;
begin
  SetLength(aColumns, COLUMN_COUNT);

  aColumns[0].FieldName := 'QSODATE';
  aColumns[0].Visible   := cqrini.ReadBool('Columns','qsodate',True);

  aColumns[1].FieldName := 'TIME_ON';
  aColumns[1].Visible   := cqrini.ReadBool('Columns','time_on',True);

  aColumns[2].FieldName := 'TIME_OFF';
  aColumns[2].Visible   := cqrini.ReadBool('Columns','time_off',True);

  aColumns[3].FieldName := 'CALLSIGN';
  aColumns[3].Visible   := cqrini.ReadBool('Columns','CallSign',True);

  aColumns[4].FieldName := 'MODE';
  aColumns[4].Visible   := cqrini.ReadBool('Columns','Mode',True);

  aColumns[5].FieldName := 'FREQ';
  aColumns[5].Visible   := cqrini.ReadBool('Columns','Freq',True);

  aColumns[6].FieldName := 'RST_S';
  aColumns[6].Visible   := cqrini.ReadBool('Columns','RST_S',True);

  aColumns[7].FieldName := 'RST_R';
  aColumns[7].Visible   := cqrini.ReadBool('Columns','RST_R',True);

  aColumns[8].FieldName := 'NAME';
  aColumns[8].Visible   := cqrini.ReadBool('Columns','Name',True);

  aColumns[9].FieldName := 'QTH';
  aColumns[9].Visible   := cqrini.ReadBool('Columns','QTH',True);

  aColumns[10].FieldName := 'QSL_S';
  aColumns[10].Visible   := cqrini.ReadBool('Columns','QSL_S',True);

  aColumns[11].FieldName := 'QSL_R';
  aColumns[11].Visible   := cqrini.ReadBool('Columns','QSL_R',True);

  aColumns[12].FieldName := 'QSL_VIA';
  aColumns[12].Visible   := cqrini.ReadBool('Columns','QSL_VIA',False);

  aColumns[13].FieldName := 'LOC';
  aColumns[13].Visible   := cqrini.ReadBool('Columns','Locator',False);

  aColumns[14].FieldName := 'MY_LOC';
  aColumns[14].Visible   := cqrini.ReadBool('Columns','MyLoc',False);

  aColumns[15].FieldName := 'IOTA';
  aColumns[15].Visible   := cqrini.ReadBool('Columns','IOTA',False);

  aColumns[16].FieldName := 'AWARD';
  aColumns[16].Visible   := cqrini.ReadBool('Columns','Award',False);

  aColumns[17].FieldName := 'COUNTY';
  aColumns[17].Visible   := cqrini.ReadBool('Columns','County',False);

  aColumns[18].FieldName := 'PWR';
  aColumns[18].Visible   := cqrini.ReadBool('Columns','Power',False);

  aColumns[19].FieldName := 'DXCC_REF';
  aColumns[19].Visible   := cqrini.ReadBool('Columns','DXCC',False);

  aColumns[20].FieldName := 'REMARKS';
  aColumns[20].Visible   := cqrini.ReadBool('Columns','Remarks',False);

  aColumns[21].FieldName := 'WAZ';
  aColumns[21].Visible   := cqrini.ReadBool('Columns','WAZ',False);

  aColumns[22].FieldName := 'ITU';
  aColumns[22].Visible   := cqrini.ReadBool('Columns','ITU',False);

  aColumns[23].FieldName := 'STATE';
  aColumns[23].Visible   := cqrini.ReadBool('Columns','State',False);

  aColumns[24].FieldName := 'LOTW_QSLSDATE';
  aColumns[24].Visible   := cqrini.ReadBool('Columns','LoTWQSLSDate',False);

  aColumns[25].FieldName := 'LOTW_QSLRDATE';
  aColumns[25].Visible   := cqrini.ReadBool('Columns','LoTWQSLRDate',False);

  aColumns[26].FieldName := 'LOTW_QSLS';
  aColumns[26].Visible   := cqrini.ReadBool('Columns','LoTWQSLS',False);

  aColumns[27].FieldName := 'LOTW_QSLR';
  aColumns[27].Visible   := cqrini.ReadBool('Columns','LOTWQSLR',False);

  aColumns[28].FieldName := 'CONT';
  aColumns[28].Visible   := cqrini.ReadBool('Columns','Cont',False);

  aColumns[29].FieldName := 'QSLS_DATE';
  aColumns[29].Visible   := cqrini.ReadBool('Columns','QSLSDate',False);

  aColumns[30].FieldName := 'QSLR_DATE';
  aColumns[30].Visible   := cqrini.ReadBool('Columns','QSLRDate',False);

  aColumns[31].FieldName := 'EQSL_QSL_SENT';
  aColumns[31].Visible   := cqrini.ReadBool('Columns','eQSLQSLS',False);

  aColumns[32].FieldName := 'EQSL_QSLSDATE';
  aColumns[32].Visible   := cqrini.ReadBool('Columns','eQSLQSLSDate',False);

  aColumns[33].FieldName := 'EQSL_QSL_RCVD';
  aColumns[33].Visible   := cqrini.ReadBool('Columns','eQSLQSLR',False);

  aColumns[34].FieldName := 'EQSL_QSLRDATE';
  aColumns[34].Visible   := cqrini.ReadBool('Columns','eQSLQSLRDate',False);

  aColumns[35].FieldName := 'QSLR';
  aColumns[35].Visible   := cqrini.ReadBool('Columns','QSLRAll',False);

  aColumns[36].FieldName := 'COUNTRY';
  aColumns[36].Visible   := cqrini.ReadBool('Columns','Country',False);

  aColumns[37].FieldName := 'PROP_MODE';
  aColumns[37].Visible   := cqrini.ReadBool('Columns', 'Propagation', False);

  aColumns[38].FieldName := 'RXFREQ';
  aColumns[38].Visible   := cqrini.ReadBool('Columns', 'RXFreq', False);

  aColumns[39].FieldName := 'SATELLITE';
  aColumns[39].Visible   := cqrini.ReadBool('Columns', 'SatelliteName', False);

  aColumns[40].FieldName := 'SRX';
  aColumns[40].Visible   := cqrini.ReadBool('Columns', 'SRX', False);

  aColumns[41].FieldName := 'STX';
  aColumns[41].Visible   := cqrini.ReadBool('Columns', 'STX', False);

  aColumns[42].FieldName := 'SRX_STRING';
  aColumns[42].Visible   := cqrini.ReadBool('Columns', 'ContMsgRcvd', False);

  aColumns[43].FieldName := 'STX_STRING';
  aColumns[43].Visible   := cqrini.ReadBool('Columns', 'ContMsgSent', False);

  aColumns[44].FieldName := 'CONTESTNAME';
  aColumns[44].Visible   := cqrini.ReadBool('Columns', 'ContestName', False);

  aColumns[45].FieldName := 'DOK';
  aColumns[45].Visible   := cqrini.ReadBool('Columns', 'DarcDok', False);

  aColumns[46].FieldName := 'OPERATOR';
  aColumns[46].Visible   := cqrini.ReadBool('Columns', 'Operator', False);

  for i:=0 to Length(aColumns)-1 do
    aColumns[i].Exists := False;

  Result := aColumns;
end;

function TdmUtils.GetDataFromHttp(Url : String; var data : String) : Boolean;
var
  HTTP   : THTTPSend;
  m      : TStringList;
begin
  Result := False;
  data   := '';
  http   := THTTPSend.Create;
  m      := TStringList.Create;
  try
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');
    if HTTP.HTTPMethod('GET', Url) then
    begin
      m.LoadFromStream(HTTP.Document);
      data   := trim(m.Text);
      Result := True
    end
  finally
    http.Free;
    m.Free
  end
end;

function TdmUtils.MyStrToDateTime(DateTime : String) : TDateTime;
var
  tmp: string;
begin
  tmp := FormatSettings.ShortDateFormat;
  try
    FormatSettings.ShortDateFormat := 'YYYY-MM-DD';
    try
      Result := StrToDateTime(DateTime)
    except
      Result := StrToDate('1980-01-01 00:00:01')
    end
  finally
    FormatSettings.ShortDateFormat := tmp
  end
end;

function TdmUtils.MyDateTimeToStr(DateTime : TDateTime) : String;
var
  tmp: string;
begin
  tmp := FormatSettings.ShortDateFormat;
  try
    FormatSettings.ShortDateFormat := 'YYYY-MM-DD';
    Result := DateTimeToStr(DateTime)
  finally
    FormatSettings.ShortDateFormat := tmp
  end
end;

procedure TdmUtils.LoadListOfFiles(Path, Mask : String; ListOfFiles : TStringList);
var
  res: byte;
  SearchRec: TSearchRec;
begin
  ListOfFiles.Clear;
  try
    res := FindFirst(Path + Mask, faAnyFile, SearchRec);
    while res = 0 do
    begin
      if FileExists(Path + SearchRec.Name) then
        ListOfFiles.Add(Path + SearchRec.Name);

      Res := FindNext(SearchRec)
    end;
    ListOfFiles.Sort;
  finally
    FindClose(SearchRec)
  end
end;
procedure TdmUtils.UpdateHelpBrowser;
var b :string;
Begin
  //here we can read preferences/program/defaut browser as log (and so preferences) are already selected
  //we need this because xdg-open (as default browser) can not work properly in all systems
  //dropping hashtags away from html file:// paths. Then user may define browser path/name that
  //usually works with hashtag html file paths.

  b := cqrini.ReadString('Program', 'WebBrowser', '');
     if (b<>'') then
      try
       Begin
        dmUtils.HelpViewer.BrowserPath:=b;
        dmUtils.HelpViewer.BrowserParams:='%s';
       end;
      finally
      end;
     //else use default browser that is defined at program early start
end;

function  TdmUtils.IsHeDx(call:String; CqDir:String = ''):boolean;
 // Find out is call dx for me.
 // If direction<>'' is directed cq pointed to me
var
  adif   :word;
  pfx    : String = '';
  mycont : String = '';
  cont   : String = '';
  country: String = '';
  waz    : String = '';
  posun  : String = '';
  itu    : String = '';
  lat    : String = '';
  long   : String = '';

begin
    adif:= dmDXCC.id_country(cqrini.ReadString('Station', 'Call', ''), Now(), pfx, mycont,  country, WAZ, posun, ITU, lat, long);
    adif:= dmDXCC.id_country(call, Now(), pfx, cont,  country, WAZ, posun, ITU, lat, long);

    if CqDir <> '' then
      begin
       if ((mycont <> '') and (cont <> '')) then
           //we can do some comparisons of continents and call dirction
           begin
             if ((CqDir = 'DX') and (mycont = cont)) then
             begin
               //I'm not DX for caller:
               Result := false;
               if dmData.DebugLevel >= 1 then
                                    Writeln('My continent is:', mycont, '  His continent is:', cont,' is DX/CQ for me:',Result);
               exit
             end
             else  //calling specified continent
             if ((CqDir <> 'DX') and (CqDir <> mycont)) then
              begin
               //CQ NOT directed to my continent
               Result := false;
               if dmData.DebugLevel >= 1 then
                                    Writeln('My continent is:', mycont, '  His continent is:', cont,' is DX/CQ for me:',Result);
               exit
              end
             else
              Begin
               //CQ directed to my continent
               Result :=true;
               if dmData.DebugLevel >= 1 then
                                    Writeln('My continent is:', mycont, '  His continent is:', cont,' is DX/CQ for me:',Result);
               exit
              end;
           end
      end
     else
      Begin
       //no directed CQ just find out if call is DX for me
       Result := (mycont <> cont);
       if dmData.DebugLevel >= 1 then
                            Writeln('My continent is:', mycont, '  His continent is:', cont,' is DX/CQ for me:',Result);
      end;
end;

procedure TdmUtils.ModeFromCqr(CqrMode:String;var OutMode,OutSubmode:String;dbg:Boolean);
//encodes Cqrlog's mode to mode and submode pair
//returns empty string to submode if not exist
var
   e: integer;

Begin
      if dbg then
                  Writeln('ModeFromCqr: ',CqrMode);
      Cqrmode:=uppercase(CqrMode); //this is for sure
      //cqrmode -> ex_mode
      e:= ExceptMode.IndexOfName(CqrMode);
      if e > -1 then
        Begin
          OutMode := uppercase(ExceptMode.Values[CqrMode]);
          OutSubmode:='';
          if dbg then
                      begin
                        Writeln('ex_mode=cqrlogmode line: ',e+1);
                        Writeln('Cqrlog will export adif as mode: ',OutMode,'  submode: ',OutSubmode);
                      end;
          exit;
        end;
      // cqrmode -> mode+submode
      e:= SubmodeMode.IndexOfName(CqrMode);
      if e > -1 then
         Begin
           OutMode    := uppercase(SubmodeMode.Values[CqrMode]);
           OutSubmode := CqrMode;
           if dbg then
                      Writeln('submode=mode line: ',e+1);

           //is submode import only
           e:=ImportMode.IndexOf(CqrMode);
           if e > -1 then
                           begin
                             if dbg then
                                        Writeln('submode for_import_only line: ',e+1);
                             OutSubmode :='';
                           end;
         end
        else
         //no submodes
         Begin
           OutMode := CqrMode;
           OutSubmode:='';
         end;
     if dbg then
                Writeln('Cqrlog will export adif as mode: ',OutMode,'  submode: ',OutSubmode);
end;
function  TdmUtils.ModeToCqr(InMode,InSubmode:String;dbg:boolean=False):String;
//decodes mode and submode pair to mode used by Cqrlog internally
var
   e: integer;

Begin
     if dbg then
                  Writeln('ModeToCqr mode: ',InMode,' submode: ',InSubmode);
     InMode:=uppercase(InMode);    //this is for sure
     InSubmode:=uppercase(InSubmode);

     Result:=InMode; //defaults to InMode
     if InSubmode='' then
                      Begin
                         if dbg then
                                    writeln('Cqrlog internal mode will be: ',Result);
                         exit;
                      end;

     e:= SubmodeMode.IndexOfName(InSubmode);
     if (e > -1 ) then  //it exist
                        Begin
                           if dbg then
                                      Writeln('submode=mode line: ',e+1);
                           Result:=InSubmode;
                        end;

      e:= ExceptMode.IndexOfName(Result);
      if e > -1  then  //it exist
                       begin
                        if dbg then
                                   Writeln('ex_mode=cqrlogmode line: ',e+1);
                        Result:= ExceptMode.ValueFromIndex[e];
                       end;

    Result:=uppercase(Result); //this is for sure
    if dbg then
               writeln('Cqrlog internal mode will be: ',Result);
end;
procedure TdmUtils.ModeConvListsCreate(SetUp:boolean);

Begin
   if not SetUp then
      Begin
        if assigned(SubmodeMode) then FreeAndNil(SubmodeMode);
        if assigned(ImportMode) then FreeAndNil(ImportMode);
        if assigned(ExceptMode) then FreeAndNil(ExceptMode);
        exit;
      end;

   SubmodeMode:= TStringList.Create;
   ImportMode := TStringlist.Create;
   ExceptMode := TStringlist.Create;

   //if we do not find one of these files we create it
   if FileSearch(C_SUBMODE_FILE,dmData.HomeDir+C_MODEFILE_DIR,[])='' then
                                                                         MakeMissingModeFile(1);
   if FileSearch(C_IMPORTMODE_FILE,dmData.HomeDir+C_MODEFILE_DIR,[])='' then
                                                                         MakeMissingModeFile(2);
   if FileSearch(C_EXCEPMODE_FILE,dmData.HomeDir+C_MODEFILE_DIR,[])='' then
                                                                         MakeMissingModeFile(3);
   if FileSearch(C_READMEMODE_FILE,dmData.HomeDir+C_MODEFILE_DIR,[])='' then
                                                                         MakeMissingModeFile(4);
   try
      SubmodeMode.LoadFromFile(dmData.HomeDir+C_MODEFILE_DIR+C_SUBMODE_FILE);
      ImportMode .LoadFromFile(dmData.HomeDir+C_MODEFILE_DIR+C_IMPORTMODE_FILE);
      ExceptMode.LoadFromFile(dmData.HomeDir+C_MODEFILE_DIR+C_EXCEPMODE_FILE);
   except
      on E : Exception do writeln('Could not load mode conversion files!');
   end;

   if dmData.DebugLevel>=1 then
    Begin
       Writeln('Loaded mode conversion files:');
       Writeln('   ',SubmodeMode.Strings[0]);
       Writeln('   ',ImportMode.Strings[0]);
       Writeln('   ',ExceptMode.Strings[0]);
    end;


end;


procedure TdmUtils.MakeMissingModeFile(num:integer);
//the idea not to use const for conversion is that when they are put in files
//later additions and deletions can be done by user without compile
Const
  S_file: array [1..168] of string = (
  'submode=mode','8PSK125=PSK','8PSK125F=PSK','8PSK125FL=PSK','8PSK250=PSK','8PSK250F=PSK','8PSK250FL=PSK','8PSK500=PSK','8PSK500F=PSK','8PSK1000=PSK',
  '8PSK1000F=PSK','8PSK1200F=PSK','AMTORFEC=TOR','ASCI=RTTY','CHIP64=CHIP','CHIP128=CHIP','DOM-M=DOMINO','DOM4=DOMINO','DOM5=DOMINO','DOM8=DOMINO',
  'DOM11=DOMINO','DOM16=DOMINO','DOM22=DOMINO','DOM44=DOMINO','DOM88=DOMINO','DOMINOEX=DOMINO','DOMINOF=DOMINO','FMHELL=HELL','FSK31=PSK','FSKHELL=HELL',
  'FSQCALL=MFSK','FST4=MFSK','FST4W=MFSK','FT4=MFSK','GTOR=TOR','HELL80=HELL','HELLX5=HELL','HELLX9=HELL','HFSK=HELL','ISCAT-A=ISCAT',
  'ISCAT-B=ISCAT','JS8=MFSK','JT4A=JT4','JT4B=JT4','JT4C=JT4','JT4D=JT4','JT4E=JT4','JT4F=JT4','JT4G=JT4','JT9-1=JT9',
  'JT9-2=JT9','JT9-5=JT9','JT9-10=JT9','JT9-30=JT9','JT9A=JT9','JT9B=JT9','JT9C=JT9','JT9D=JT9','JT9E=JT9','JT9E=FAST',
  'JT9F=JT9','JT9F=FAST','JT9G=JT9','JT9G=FAST','JT9H=JT9','JT9H=FAST','JT65A=JT65','JT65B=JT65','JT65B2=JT65','JT65C=JT65',
  'JT65C2=JT65','JTMS=MFSK','LSB=SSB','MFSK4=MFSK','MFSK8=MFSK','MFSK11=MFSK','MFSK16=MFSK','MFSK22=MFSK','MFSK31=MFSK','MFSK32=MFSK',
  'MFSK64=MFSK','MFSK64L=MFSK','MFSK128=MFSK','MFSK128L=MFSK','NAVTEX=TOR','OLIVIA 4/125=OLIVIA','OLIVIA 4/250=OLIVIA','OLIVIA 8/250=OLIVIA','OLIVIA 8/500=OLIVIA','OLIVIA 16/500=OLIVIA',
  'OLIVIA 16/1000=OLIVIA','OLIVIA 32/1000=OLIVIA','OPERA-BEACON=OPERA','OPERA-QSO=OPERA','PAC2=PAC','PAC3=PAC','PAC4=PAC','PAX2=PAX','PCW=CW','PSK10=PSK',
  'PSK31=PSK','PSK63=PSK','PSK63F=PSK','PSK63RC10=PSK','PSK63RC20=PSK','PSK63RC32=PSK','PSK63RC4=PSK','PSK63RC5=PSK','PSK125=PSK','PSK125RC10=PSK','PSK125RC12=PSK',
  'PSK125RC16=PSK','PSK125RC4=PSK','PSK125RC5=PSK','PSK250=PSK','PSK250RC2=PSK','PSK250RC3=PSK','PSK250RC5=PSK','PSK250RC6=PSK','PSK250RC7=PSK','PSK500=PSK',
  'PSK500RC2=PSK','PSK500RC3=PSK','PSK500RC4=PSK','PSK800RC2=PSK','PSK1000=PSK','PSK1000RC2=PSK','PSKAM10=PSK','PSKAM31=PSK','PSKAM50=PSK','PSKFEC31=PSK',
  'PSKHELL=HELL','QPSK31=PSK','Q65=MFSK','QPSK63=PSK','QPSK125=PSK','QPSK250=PSK','QPSK500=PSK','QRA64A=QRA64','QRA64B=QRA64','QRA64C=QRA64',
  'QRA64D=QRA64','QRA64E=QRA64','ROS-EME=ROS','ROS-HF=ROS','ROS-MF=ROS','SIM31=PSK','SITORB=TOR','SLOWHELL=HELL','THOR-M=THOR','THOR4=THOR',
  'THOR5=THOR','THOR8=THOR','THOR11=THOR','THOR16=THOR','THOR22=THOR','THOR25X4=THOR','THOR50X1=THOR','THOR50X2=THOR','THOR100=THOR','THRBX=THRB',
  'THRBX1=THRB','THRBX2=THRB','THRBX4=THRB','THROB1=THRB','THROB2=THRB','THROB4=THRB','USB=SSB'
  );
  I_file: array [1 .. 41] of string = (
  'for_import_only','AMTORFEC','ASCI','CHIP64','CHIP128','DOMINOF','FMHELL','FSK31','GTOR','HELL80',
  'HFSK','JT4A','JT4B','JT4C','JT4D','JT4E','JT4F','JT4G','JT65A','JT65B',
  'JT65C','MFSK8','MFSK16','PAC2','PAC3','PAX2','PCW','PSK10','PSK31','PSK63',
  'PSK63F','PSK125','PSKAM10','PSKAM31','PSKAM50','PSKFEC31','PSKHELL','QPSK31','QPSK63','QPSK125',
  'THRBX'
  );

  {Exceptions file:
  Cqrlog uses SSB for both USB and LSB
  Cqrlog uses RTTY, some programs may export ASCI even when it is import only!
  'PACKET':
           these modes come from ICOM rig (IC7300) when DATA is selected with USB,LSB,FM or AM
           and checkbox "auto" for mode is selected in NewQSO we put them all to PKT category here
           as it is in ADIF standard
  }
  E_file: array [1 .. 9] of string = (
  'ex_mode=cqrlogmode',
  'USB=SSB',
  'LSB=SSB',
  'ASCI=RTTY',
  'PACKET=PKT',
  'PKTUSB=PKT',
  'PKTLSB=PKT',
  'PKTFM=PKT',
  'PKTAM=PKT'
  );
  R_file: array [1 .. 22] of string = (
  'Files to modify ADIF mode+submode to fit with Cqrlog.',
  'Cqrlog internally uses submodes as mode. (only one database column -> mode)',
  '',
  'These files are manually created and can be changed if needed:',
  'Contents are read to TStringLists at program start.',
  '',
  'submode_mode.txt',
  ' Submode=Mode',
  ' Used en/decoding mode-submode pairs for Cqrlog.',
  '',
  'import_mode.txt',
  ' Submode list for import only',
  ' Used to define deprecated submodes that are used ony for adif input.',
  ' These submodes do not export.',
   '',
   'exception_mode.txt',
   ' mode=cqrlogmode',
   ' Exceptions between "true" (sub)modes and internal cqrlog mode',
   ' Converts also in export "non adif" modes from rigctld like PACKET -> PKT',
   '',
   'Two first files created by https://adif.org/312/ADIF_312_annotated.htm#Mode_Enumeration',
   'informations 2022-04-29,'
  );
  var f:TextFile;


//--------------------------------------------------------
  procedure CreaFile(Fname:string;items:array of string);
  var
     i: integer;
     itemsmax:integer;

   begin
      itemsmax:=length(items);
      AssignFile(f,Fname);
      try
        rewrite(f);
        try
         for i:= 0 to itemsmax-1 do
            Writeln(f, items[i]);
        finally
         CloseFile(f);
        end;
      except
      on E: EInOutError do
         ShowMessage('File handling error occurred. Details: ' +  E.ClassName +  '/' +  E.Message);
      end;
    end;
//--------------------------------------------------------
Begin
   if num=1 then CreaFile(dmData.HomeDir+C_MODEFILE_DIR+C_SUBMODE_FILE,S_file);
   if num=2 then CreaFile(dmData.HomeDir+C_MODEFILE_DIR+C_IMPORTMODE_FILE,I_file);
   if num=3 then CreaFile(dmData.HomeDir+C_MODEFILE_DIR+C_EXCEPMODE_FILE,E_file);
   if num=4 then CreaFile(dmData.HomeDir+C_MODEFILE_DIR+C_READMEMODE_FILE,R_file);
end;

procedure TdmUtils.UpdateCallBookcnf;
var
  c,p:string;

Begin
  c:= cqrini.ReadString('CallBook', 'CBUser', '');
if c <> '' then
  Begin //remove old definition
    p:= cqrini.ReadString('CallBook', 'CBPass', '');
    if cqrini.ReadBool('Callbook', 'HamQTH', True) then
      begin
        cqrini.WriteString('CallBook', 'CbHamQTHUser', c);
        cqrini.WriteString('CallBook', 'CbHamQTHPass', p);
      end
     else
      begin
        cqrini.WriteString('CallBook', 'CbQRZUser', c);
        cqrini.WriteString('CallBook', 'CbQRZPass', p);
      end;
    cqrini.DeleteKey('CallBook', 'CBUser');
    cqrini.DeleteKey('CallBook', 'CBPass');
  end;
end;

procedure TdmUtils.ClearStatGrid(g:TStringGrid);
var
  i,y : Integer;
begin
  for i:= 0 to g.ColCount-1 do
    for y := 0 to g.RowCount-1 do
      g.Cells[i,y] := '   ';
  with g do
  begin
    Cells[0, 1] := 'SSB';
    Cells[0, 2] := 'CW';
    Cells[0, 3] := 'DIGI'
  end;
end;

procedure TdmUtils.AddBandsToStatGrid(g:TStringGrid);
var
  i : Integer;
begin
  g.ColCount  := cMaxBandsCount;

  for i:=0 to cMaxBandsCount-1 do
  begin
    if dmUtils.MyBands[i][0]='' then
    begin
      g.ColCount  := i+1;
      break
    end;
    g.Cells[i+1,0] := dmUtils.MyBands[i][1];
  end;
end;


procedure TdmUtils.ShowStatistic(ref_adif,old_stat_adif:Word; g:TStringGrid; call:String='');
var
  i : Integer;
  ShowLoTW : Boolean = False;
  mode : String;
  QSLR,LoTW,eQSL : String;
  tmps,tmpq : String;
  space: String;

begin
  tmpq:='';
  if call='' then
   Begin
    if old_stat_adif = ref_adif then
      exit;
    old_stat_adif := ref_adif;
   end
  else
   begin
   tmpq:=' and callsign='+QuotedStr(call);
   end;

  g.ColCount  := cMaxBandsCount;

  dmUtils.ClearStatGrid(g);
  dmUtils.AddBandsToStatGrid(g);

  space := ' ';
  if cqrini.ReadBool('Fonts','GridDotsInsteadSpaces',False) = True then
  begin
    space := '.';
  end;

  for i:=0 to cMaxBandsCount-1 do
  begin
    if dmUtils.MyBands[i][0]='' then
    begin
      g.ColCount  := i+1;
      break
    end;

    g.Cells[i+1,1] := space+space+space;
    g.Cells[i+1,2] := space+space+space;
    g.Cells[i+1,3] := space+space+space;
  end;

  if dmData.trQ.Active then
    dmData.trQ.RollBack;
  dmData.Q.Close;

  ShowLoTW := cqrini.ReadBool('LoTW','NewQSOLoTW',False);
  if ShowLoTW then
    dmData.Q.SQL.Text := 'select band,mode,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main where adif='+
                         IntToStr(ref_adif) + tmpq + ' and ((qsl_r='+QuotedStr('Q')+') or '+
                         '(lotw_qslr = '+QuotedStr('L')+') or (eqsl_qsl_rcvd='+QuotedStr('E')+
                         ')) group by band,mode,qsl_r,lotw_qslr,eqsl_qsl_rcvd'
  else
    dmData.Q.SQL.Text := 'select band,mode,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main where adif='+
                         IntToStr(ref_adif) + tmpq + ' and (qsl_r = '+QuotedStr('Q')+') '+
                         'group by band,mode,qsl_r,lotw_qslr,eqsl_qsl_rcvd';
  dmData.trQ.StartTransaction;
  dmData.Q.Open;
  while not dmData.Q.Eof do
  begin
    i    := dmUtils.GetBandPos(dmData.Q.Fields[0].AsString)+1;
    mode := dmData.Q.Fields[1].AsString;
    QSLR := dmData.Q.Fields[2].AsString;
    LoTW := dmData.Q.Fields[3].AsString;
    eQSL := dmData.Q.Fields[4].AsString;
    if i > 0 then
    begin
      if (Mode = 'SSB') or (Mode='FM') or (Mode='AM') then
      begin
        tmps := g.Cells[i,1] ;
        if QSLR = 'Q' then
          tmps[1] := 'Q';
        if (LoTW = 'L') then
          tmps[2] := 'L';
        if (eQSL = 'E') then
          tmps[3] := 'E';
       g.Cells[i,1] := tmps
      end
      else begin
        if (Mode='CW') or (Mode='CWQ') then
        begin
          tmps := g.Cells[i,2] ;
          if QSLR = 'Q' then
            tmps[1] := 'Q';
          if (LoTW = 'L') then
            tmps[2] := 'L';
          if (eQSL = 'E') then
            tmps[3] := 'E';
          g.Cells[i,2] := tmps
        end
        else begin
          tmps := g.Cells[i,3] ;
          if QSLR = 'Q' then
            tmps[1] := 'Q';
          if (LoTW = 'L') then
            tmps[2] := 'L';
          if (eQSL = 'E') then
            tmps[3] := 'E';
          g.Cells[i,3] := tmps
        end
      end;
    end;
    dmData.Q.Next
  end;
  dmData.trQ.Rollback;

  dmData.Q.Close;
  if dmData.trQ.Active then
    dmData.trQ.Rollback;
  dmData.Q.SQL.Text := 'select band,mode from cqrlog_main where adif='+
                       IntToStr(ref_adif) + tmpq +' group by band,mode';
  dmData.trQ.StartTransaction;
  dmData.Q.Open;
  while not dmData.Q.Eof do
  begin
    i    := dmUtils.GetBandPos(dmData.Q.Fields[0].AsString)+1;
    mode := dmData.Q.Fields[1].AsString;
    if i > 0 then
      begin
        if ((mode = 'SSB') or (mode = 'FM') or (mode = 'AM')) then
          if(g.Cells[i,1] = space+space+space) then g.Cells[i,1] := ' X ';
        if ((mode = 'CW') or (mode = 'CWR')) then
          if (g.Cells[i,2] = space+space+space) then g.Cells[i,2] := ' X ';
        if ((mode <> 'SSB') and (mode <>'FM') and (mode <> 'AM') and (mode <> 'CW') and (mode <> 'CWR')) then
          if (g.Cells[i,3] = space+space+space) then g.Cells[i,3] := ' X '
      end;
      dmData.Q.Next;
  end;
  dmData.Q.Close;
  dmData.trQ.Rollback
end;

end.

