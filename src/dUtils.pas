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
  DBGrids, aziloc, azidis3, process, db, sqldb, grids, buttons, spin, colorbox,
  menus, Graphics, math, LazHelpHTML, lNet, DateUtils, fileutil, httpsend,
  XMLRead, DOM, sqlscript, BaseUnix, Unix;

type
  TExplodeArray = Array of String;

const
  MyWhiteSpace = [#0..#31];
  AllowedCallChars = ['A'..'Z','0'..'9','/'];
  AllowedChars = ['A'..'Z','a'..'z','0'..'9','/',',','.','?','!',' ',':','|','-','=','+','@','#','*',
                  '%','_','(',')','$'];
  empty_freq = '0.00000';
  empty_azimuth = '0.0';
  cMaxModes = 38;
  cModes: array [0..cMaxModes] of string = ('CW','SSB','AM','FM','RTTY','SSTV','PACTOR','PSK','ATV','CLOVER','GTOR','MTOR',
                                            'PSK31','HELL','MT63','QRSS','CWQ','BPSK31','MFSK','JT44','FSK44','WSJT','AMTOR',
                                            'THROB','BPSK63','PACKET','OLIVIA','MFSK16','JT6M','JT65','JT65A','JT65B','JT65C',
                                            'FSK441','PSK125','PSK63','WSPR','PSK250','ROS');
  cMaxBandsCount = 26; //26 bands
  cDefaultFreq = '0.136|1.800|3.500|3.700|7.000|10.100|14.000|14.200|18.100|21.000|21.200|24.890|28.000|28.500|50.000|70.0875|'+
                 '70.0500|144.000|145.275|430.000|902.0|1250.0|2400.0|3450.0|5670.0|10250.0|24100.0|47100.0|78000.0|';

  cMaxIgnoreFreq = 6;
  cIngnoreFreq: array [0..cMaxIgnoreFreq] of string = ('1800.0','3500.0','7000.0','10100.0','14000.0','21000.0','28000.0');

type

  { TdmUtils }

  TdmUtils = class(TDataModule)
    Datasource1: TDatasource;
    HelpViewer: THTMLBrowserHelpViewer;
    HelpDatabase: THTMLHelpDatabase;
    procedure DataModuleCreate(Sender: TObject);
  private
    fTimeOffset     : Currency;
    fGrayLineOffset : Currency;
    fQRZSession     : String;
    fHamQTHSession  : String;
    fSysUTC         : Boolean;

    function  nr(ch : Char) : Integer;
    function  GetTagValue(data,tg : String) : String;
    function  GetQRZSession(var ErrMsg :String) : Boolean;
    function  GetHamQTHSession(var ErrMsg : String) : Boolean;
    function  GetQRZInfo(call : String; var nick,qth,address,zip,grid,state,county,qsl,iota,ErrMsg : String) : Boolean;
    function  GetHamQTHInfo(call : String; var nick,qth,address,zip,grid,state,county,qsl,iota,ErrMsg : String) : Boolean;
  public
    s136  : String;
    s160  : String;
    s80   : String;
    s60   : String;
    s40   : String;
    s30   : String;
    s20   : String;
    s17   : String;
    s15   : String;
    s12   : String;
    s10   : String;
    s6    : String;
    s4    : String;
    s220  : String;
    s2    : String;
    s70   : String;
    s900  : String;
    s1260 : String;
    s2300 : String;
    s3400 : String;
    s5850 : String;
    s10G  : String;
    s24G  : String;
    s47G  : String;
    s76G  : String;
    USstates : Array [1..50] of String;
    MyBands  : Array [0..cMaxBandsCount-1,0..1] of String[6]; //list of bands, band labels

    property TimeOffset : Currency read fTimeOffset write fTimeOffset;
    property GrayLineOffset : Currency read fGraylineOffset write fGrayLineOffset;
    property SysUTC : Boolean read fSysUTC write fSysUTC;

    procedure InsertModes(cmbMode : TComboBox);
    procedure InsertQSL_S(QSL_S : TComboBox);
    procedure InsertQSL_R(QSL_R : TcomboBox);
    procedure InsertFreq(cmbFreq  : TComboBox);
    procedure DateInRightFormat(date : TDateTime; var Mask,sDate : String);
    procedure FileCopy(const FileFrom, FileTo: string) ;
    procedure CopyData(Source,Destination : String);
    procedure DeleteData(Directory : String);
    procedure SaveForm(aForm: TForm);
    procedure LoadForm(aForm: TForm);
    procedure SaveLog(Text : String);
    procedure GetCoordinate(pfx: string; var latitude, longitude: Currency);
    procedure GetRealCoordinate(lat,long : String; var latitude, longitude: Currency);
    procedure DistanceFromCoordinate(my_loc:String;latitude, longitude : Real; var qra, azim: String);
    procedure DistanceFromLocator(my_loc,his_loc:String; var qra, azim: String);
    procedure DistanceFromPrefixMyLoc(my_loc,pfx : String; var qra, azim: String);
    procedure ModifyWAZITU(var waz,itu : String);
    procedure CoordinateFromLocator(loc : String; var latitude,longitude : Currency);
    procedure EnterFreq;
    procedure LoadFontSettings(aForm : TForm);
    procedure LoadBandLabelSettins;
    procedure ReadMemberList(cmbMemebers : TComboBox);
    procedure SortList(l : TStringList);
    procedure RunXplanet;
    procedure CloseXplanet;
    procedure ModifyXplanetConf;
    procedure DeleteMarkerFile;
    procedure ReadZipList(cmbZip : TComboBox);
    procedure CalcSunRiseSunSet(Lat,Long : Double; var SunRise,SunSet : TDateTime);
    procedure ExecuteCommand(cmd : String);
    procedure RunOnBackgroud(path : String);
    procedure SaveWindowPos(a : TForm);
    procedure LoadWindowPos(a : TForm);
    procedure ShowQSLWithExtViewer(Call : String);
    procedure GetFileList(l : TListBox);
    procedure GetDirectoryList(l : TListBox);
    procedure InsertContestFreq(cmbFreq : TcomboBox;warc : Boolean);
    procedure ShowQRZInBrowser(call : String);
    procedure LoadBandsSettings;
    procedure FillBandCombo(cmb : TComboBox);
    procedure ShowHamQTHInBrowser(call : String);
    procedure SortArray(l,r : Integer);
    procedure OpenInApp(what : String);

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
    function  StringToADIF(text : String) : String;
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
    function  GetCWMessage(Key,call,rst_s,HisName,text : String; QSONR : String = '') : String;
    function  RigGetcmd(r : String): String;
    function  GetLastQSLUpgradeDate : TDateTime;
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
    function  GetCallBookData(call : String; var nick,qth,address,zip,grid,state,county,qsl,iota,ErrMsg : String) : Boolean;
    function  DateInSOTAFormat(date : TDateTime) : String;
    function  GetLocalUTCDelta : Double;
    function  GetRadioRigCtldCommandLine(radio : Word) : String;
    function  GetRotorRotCtldCommandLine(rotor : Word) : String;
    function  IgnoreFreq(kHz : String) : Boolean;
    function  HTMLEncode(const Data: string): string;
end;

var
  dmUtils: TdmUtils;

implementation

{ TdmUtils }
uses dData, dDXCC, fEnterFreq, fTRXControl, uMyini;

function TdmUtils.LetterFromMode(mode : String) : String;
begin
  if (mode = 'CW') or (mode = 'CWQ') then
    result := 'C'
  else begin
    if (mode = 'FM') or (mode = 'SSB') or (mode = 'AM') then
      result := 'F'
    else
      result := 'D';
  end;
end;


function TdmUtils.GetBandFromFreq(MHz : string): String;
var
  x: Integer;
  tmp : Currency;
  band : String;
begin
  Result := '';
  band := '';
  if Pos('.',MHz) > 0 then
    MHz[Pos('.',MHz)] := DecimalSeparator;

  if pos(',',MHz) > 0 then
    MHz[pos(',',MHz)] := DecimalSeparator;

  if not TryStrToCurr(MHz,tmp) then
    exit;
  x := trunc(tmp);
  case x of
    0 : Band := '2190M';
    1 : Band := '160M';
    3 : band := '80M';
    5 : band := '60M';
    7 : band := '40M';
    10 : band := '30M';
    14 : band := '20M';
    18 : Band := '17M';
    21 : Band := '15M';
    24 : Band := '12M';
    28..30 : Band := '10M';
    50..53 : Band := '6M';
    70..72 : Band := '4M';
    144..149 : Band := '2M';
    219..225 : Band := '1.25M';
    430..440 : band := '70CM';
    900..929 : band := '33CM';
    1240..1300 : Band := '23CM';
    2300..2450 : Band := '13CM';  //12 cm
    3400..3475 : band := '9CM';
    5650..5850 : Band := '6CM';

    10000..10500 : band := '3CM';
    24000..24250 : band := '1.25CM';
    47000..47200 : band := '6MM';
    76000..84000 : band := '4MM';
  end;
  Result := band
end;

function TdmUtils.GetAdifBandFromFreq(MHz : string): String;
var
  x: Integer;
  tmp : Currency;
  dec  : Currency;
  band : String;
begin
  Result := '';
  band := '';
  if Pos('.',MHz) > 0 then
    MHz[Pos('.',MHz)] := DecimalSeparator;

  if pos(',',MHz) > 0 then
    MHz[pos(',',MHz)] := DecimalSeparator;

  if not TextToFloat(PChar(MHZ),tmp, fvCurrency) then
    exit;

  if tmp < 1 then
  begin
    dec := Int(frac(tmp) * 1000);
    if ((dec >= 133) and (dec <= 139))  then
    begin
      Result := '2190M';
      exit
    end;
  end;
  x := trunc(tmp);
  case x of
    1 : Band := '160M';
    3 : band := '80M';
    5 : band := '60M';
    7 : band := '40M';
    10 : band := '30M';
    14 : band := '20M';
    18 : Band := '17M';
    21 : Band := '15M';
    24 : Band := '12M';
    28..29 : Band := '10M';
    50..53 : Band := '6M';
    70..72 : Band := '4M';
    144..149 : Band := '2M';
    219..225 : band := '1.25M';
    430..440 : band := '70CM';
    900..929 : band := '33CM';
    1240..1300 : Band := '23CM';
    2300..2450 : Band := '13CM';
    3400..3475 : band := '9CM';
    5650..5850 : Band := '6CM';

    10000..10500 : band := '3CM';
    24000..24250 : band := '1.25CM';
    47000..47200 : band := '6MM';
    76000..84000 : band := '4MM';
  end;
  Result := band
end;

procedure TdmUtils.SaveForm(aForm: TForm);
var
  Grid : TDBGrid;
  Section, Ident: string;
  i,j,y : Integer;
  l : TStringList;
begin
  if dmData.DBName = '' then
    exit;
  if dmData.DebugLevel>=1 then Writeln('SaveForm: ',aForm.Name);
  l   := TStringList.Create;
  try
    for i:= 0 to aForm.ComponentCount - 1 do
    begin
      if aForm.Components[i] is TDBGrid then
      begin
        Grid:= aForm.Components[i] as TDBGrid;
        Section:= aForm.Name+'_'+Grid.Name;
        l.Clear;
        cqrini.ReadSection(Section,l);
        l.Text := Trim(l.Text);
        if l.Text<>'' then
        begin //delete old settings
          for y:=0 to l.Count-1 do
            cqrini.DeleteKey(Section,l[y])
        end;
        for j:= 0 to Grid.Columns.Count - 1 do
        begin
          Ident:= TColumn(Grid.Columns[j]).FieldName;
          cqrini.WriteString(Section, Ident, IntToStr(Grid.Columns[j].Width));
          //Writeln('Saving:  Section: ',Section,' Ident: ',Ident,' Width: ',Grid.Columns[j].Width)
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
  i : Integer;
  l : TStringList;
  y : Integer;
  D : TDataSource;
begin
  if dmData.DebugLevel>=1 then Writeln('LoadForm: ',aForm.Name);
  l    := TStringList.Create;
  try
    for i := 0 to aForm.ComponentCount - 1 do
    begin
      if (aForm.Components[i] is TDBGrid) then
      begin
        Grid := (aForm.Components[i] as TDBGrid);
        Section := aForm.Name+'_'+Grid.Name;
        l.Clear;
        cqrini.ReadSection(Section,l);
        l.Text := Trim(l.Text);
        if l.Text='' then
          exit;
        D := Grid.DataSource;
        Grid.DataSource := nil;
        Grid.BeginUpdate;
        try
          Grid.Columns.Clear;
          for y := 0 to l.Count-1 do
          begin
            Ident := l[y];
            Grid.Columns.Add.DisplayName       := Ident;
            TColumn(Grid.Columns[y]).FieldName := Ident;
            Grid.Columns[y].Width := cqrini.ReadInteger(section,Ident,100);
            //Writeln('Loading:  Section: ',Section,' Ident: ',Ident,' Width: ',Grid.Columns[y].Width)
          end
        finally
          Grid.DataSource := D;
          Grid.EndUpdate()
        end
      end
    end
  finally
    cqrini.SaveToDisk;
    l.Free
  end
end;


procedure TdmUtils.DataModuleCreate(Sender: TObject);
begin
  fQRZSession := '';
  HelpDatabase.BaseURL:= 'file://'+dmData.HelpDir;
  USstates[1]  := 'AK, Alaska';
  USstates[2]  := 'AL, Alabama';
  USstates[3]  := 'AR, Arkansas';
  USstates[4]  := 'AZ, Arizona';
  USstates[5]  := 'CA, California';
  USstates[6]  := 'CO, Colorado';
  USstates[7]  := 'CT, Connecticut';
  USstates[8]  := 'DE, Delaware';
  USstates[9]  := 'FL, Florida';
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
  USstates[50] := 'WY, Wyoming'
end;

procedure TdmUtils.InsertModes(cmbMode : TComboBox);
var
  i : Integer;
  a : TExplodeArray;
begin
  cmbMode.Clear;
  for i := 0 to cMaxModes do
    cmbMode.Items.Add(cModes[i]);
  if cqrini.ReadString('Modes','Digi','') <> '' then
  begin
    SetLength(a,0);
    a := Explode(',',cqrini.ReadString('Modes','Digi',''));
    for i:=0 to Length(a)-1 do
      cmbMode.Items.Add(a[i])
  end
end;

procedure TdmUtils.InsertQSL_S(QSL_S : TComboBox);
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
  QSL_S.Items.Add('OR')
end;

procedure TdmUtils.InsertQSL_R(QSL_R : TComboBox);
begin
  QSL_R.Clear;
  QSL_R.Items.Add('');
  QSL_R.Items.Add('Q');
  QSL_R.Items.Add('!');
end;


procedure TdmUtils.InsertFreq(cmbFreq : TcomboBox);
var
  a : TExplodeArray;
  i : Integer;
begin
  cmbFreq.Clear;
  a := Explode('|',cqrini.ReadString('NewQSO','FreqList',cDefaultFreq));
  for i:=0 to Length(a)-1 do
    if a[i] <> '' then
      cmbFreq.Items.Add(a[i])
  {
  cmbFreq.Items.Add('1.800');
  cmbFreq.Items.Add('3.500');
  cmbFreq.Items.Add('3.700');
  cmbFreq.Items.Add('7.000');
  cmbFreq.Items.Add('10.100');
  cmbFreq.Items.Add('14.000');
  cmbFreq.Items.Add('14.200');
  cmbFreq.Items.Add('18.100');
  cmbFreq.Items.Add('21.000');
  cmbFreq.Items.Add('21.200');
  cmbFreq.Items.Add('24.890');
  cmbFreq.Items.Add('28.000');
  cmbFreq.Items.Add('28.500');
  cmbFreq.Items.Add('50.000');
  cmbFreq.Items.Add('70.0875');
  cmbFreq.Items.Add('70.0500');
  cmbFreq.Items.Add('144.000');
  cmbFreq.Items.Add('145.275');
  cmbFreq.Items.Add('430.000');
  cmbFreq.Items.Add('902.0');
  cmbFreq.Items.Add('1250.0');
  cmbFreq.Items.Add('2400.0');
  cmbFreq.Items.Add('3450.0');
  cmbFreq.Items.Add('5670.0');
  cmbFreq.Items.Add('10250.0');
  cmbFreq.Items.Add('24100.0');
  cmbFreq.Items.Add('47100.0');
  cmbFreq.Items.Add('78000.0');
  }
end;

function TdmUtils.DateInRightFormat(date : TDateTime) : String;
var
  tmp   : String;
  rDate : String;
begin
  DateInRightFormat(date,tmp,rDate);
  Result := rDate
end;


procedure TdmUtils.DateInRightFormat(date : TDateTime; var Mask,sDate : String);
var
  Sep    : Char;
begin
  sep := DateSeparator;
  try
    Mask  := '9999-99-99';
    DateSeparator := '-';
    sDate := FormatDateTime('YYYY-MM-DD', date);
  finally
    DateSeparator := sep;
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

function TdmUtils.StrToDateFormat(sDate : String) : TDateTime;
var
  sdf    : String;
  Sep    : Char;
begin
  sdf := ShortDateFormat;
  sep := DateSeparator;
  try
    ShortDateFormat := 'YYYY-MM-DD';
    DateSeparator   := '-';
    Result := StrToDateTime(sDate);
  finally
    ShortDateFormat := sdf;
    DateSeparator   := sep;
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


function TdmUtils.DateToSQLIteDate(date : TDateTime) : String;
var
  ds : Char;
begin
  ds := DateSeparator;
  DateSeparator := '-';
  Result := FormatDateTime('YYY-MM-DD',date);
  DateSeparator := ds;
end;

procedure TdmUtils.FileCopy(const FileFrom, FileTo: string) ;
var
  FromF, ToF: file;
  NumRead, NumWritten: Word;
  Buffer: array[1..2048] of Byte;
begin
  AssignFile(FromF, FileFrom) ;
  Reset(FromF, 1) ;
  AssignFile(ToF, FileTo) ;
  Rewrite(ToF, 1) ;
  repeat
   BlockRead(FromF, Buffer, SizeOf(Buffer), NumRead) ;
   BlockWrite(ToF, Buffer, NumRead, NumWritten) ;
  until (NumRead = 0) or (NumWritten <> NumRead) ;
  CloseFile(FromF) ;
  CloseFile(ToF) ;
end;


procedure TdmUtils.CopyData(Source,Destination : String);
var
  res          : Byte;
  SearchRec    : TSearchRec;
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
  while Res = 0 do begin
    if (Pos('.',SearchRec.Name) > 1) then
      FileCopy(Source + SearchRec.Name,Destination + SearchRec.Name);
    Res := FindNext(SearchRec);
    //Application.ProcessMessages;
  end;
  FindClose(SearchRec);
end;

procedure TdmUtils.DeleteData(Directory : String);
var
  res          : Byte;
  SearchRec    : TSearchRec;
begin
  if (Length(Directory) = 0) then
    exit;
  if Directory[Length(Directory)] <> '/' then
    Directory := Directory + '/';

  res := FindFirst(Directory + '*.*', faAnyFile, SearchRec);
  while Res = 0 do begin
    if FileExists(Directory + SearchRec.Name) then
      DeleteFile(Directory + SearchRec.Name);
    Res := FindNext(SearchRec);
    //Application.ProcessMessages;
  end;
  FindClose(SearchRec);
end;

function TdmUtils.DateToFilterDate(date : TDateTime) : String;
var
  d,m,y    : Word;
  sd,sm,sy : String;
begin
  DecodeDate(Date,y,m,d);
  sy := IntToStr(y);
  if Length(sy) = 1 then
    sy := '0'+sy;
  sm := IntToStr(m);
  if Length(sm) = 1 then
    sm := '0'+sm;
  sd := IntToStr(d);
  if Length(sd) = 1 then
    sd := '0'+sd;

  Result := sy+sm+sd;
end;

function TdmUtils.ADIFDateToDate(date : String) : String;
var
  d,m,y : String;
begin
  if (date = '') then
    Result := ''
  else begin
    y := Date[1]+Date[2]+Date[3]+Date[4];
    m := Date[5]+Date[6];
    d := Date[7]+Date[8];
    Result := y + '-' + m + '-' + d;
  end;
end;


function TdmUtils.IsModeOK(mode : String) : Boolean;
var
  i : Integer;
begin
  Result := False;
  for i:= 0 to cMaxModes do
  begin
      if mode = cModes[i] then
    begin
      Result := True;
      Break
    end
  end;
  if Pos(mode+',',cqrini.ReadString('Modes','Digi','')+',') > 0 then
    Result := True
end;

function TdmUtils.IsTimeOK(time : String) : Boolean;
var
  imin, ihour: Integer;
begin
  imin := 0; ihour := 0;
  result := True;
  if length(time) <> 5 then
    result := False
  else
  begin
    if not ((TryStrToInt(time[1] + time[2],ihour)) and TryStrToInt(time[4] + time[5],imin)) then
      Result := False
    else begin
      if ihour > 24 then result := False;
      if imin > 59  then result := False
    end
  end
end;

procedure TdmUtils.SaveLog(text : String);
var
  f : TextFile;
begin

  AssignFile(f,dmData.DataDir + 'log.dat');
  if not FileExists(dmData.DataDir + 'log.dat') then
    Rewrite(f)
  else
    Append(f);
  text := DateTimeToStr(now)+ ' ' + TimeToStr(now) + ' ' + text;
  Writeln(f,text);
  CloseFile(f);
end;

function TdmUtils.Explode(const cSeparator, vString: String): TExplodeArray;
var
  i: Integer;
  S: String;
begin
  S := vString;
  SetLength(Result, 0);
  i := 0;
  while Pos(cSeparator, S) > 0 do begin
    SetLength(Result, Length(Result) +1);
    Result[i] := Copy(S, 1, Pos(cSeparator, S) -1);
    Inc(i);
    S := Copy(S, Pos(cSeparator, S) + Length(cSeparator), Length(S));
  end;
  SetLength(Result, Length(Result) +1);
  Result[i] := Copy(S, 1, Length(S))
end;

function TdmUtils.MyDateToStr(Date : TDateTime) : String;
begin
  Result  := FormatDateTime('yyyy-mm-dd',Date)
end;

function TdmUtils.MyStrToDate(date : String) : TDateTime;
var
  tmp : String;
begin
  tmp := ShortDateFormat;
  ShortDateFormat := 'YYYY-MM-DD';
  try
    try
      Result := StrToDate(date);
    except
      Result := StrToDate('1980-01-01');
    end
  finally
    ShortDateFormat := tmp;
  end;
end;

function TdmUtils.GetDateTime(delta : Currency) : TDateTime;
var
  tv: ttimeval;
  res: longint;
begin
  if dmUtils.SysUTC then
  begin
    fpgettimeofday(@tv,nil);
    res    := tv.tv_sec;
    Result := (res / 86400) + 25569.0;  // Same line as used in Unixtodatetime
    if delta <> 0 then
      Result :=  Result - (delta/24)
  end
  else begin
    Result := now;
    delta := delta + fTimeOffset;
    if delta <> 0 then
      Result :=  Result - (delta/24)
  end
end;

function TdmUtils.CompleteLoc(loc : String) : String;
begin
  if Length(loc) = 4 then
    result := loc + 'LL'
  else
    Result := loc;
end;

function TdmUtils.IsLocOK(Loc : String) : Boolean;
var
  i : Integer;
begin
  result := True;
  loc := CompleteLoc(loc);
  if Length(Loc) = 6 then
  begin
    for i := 1 to 6 do
    begin
      Loc[i] := UpCase(Loc[i]);
      case i of
        1, 2, 5, 6: case Loc[i] of
            'A'..'X':
              begin
              end
            else
              Result := False;
          end;
        3, 4: case Loc[i] of
            '0'..'9':
              begin
              end
            else
              Result := False;
          end;
      end;
    end;
  end
  else
    Result := False;
end;

procedure TdmUtils.GetCoordinate(pfx: string; var latitude, longitude: Currency);
var
  s,d : String;
begin
  //dmDXCC.trDXCCRef.StartTransaction;
  dmDXCC.qDXCCRef.SQL.Text := 'SELECT * FROM cqrlog_common.dxcc_ref WHERE pref=' + QuotedStr(pfx);
  dmDXCC.qDXCCRef.Open;
  s := dmDXCC.qDXCCRef.Fields[4].AsString;
  d := dmDXCC.qDXCCRef.Fields[5].AsString;

  if ((Length(s)=0) or (Length(d)=0)) then
  begin
    longitude := 0;
    latitude  := 0;
    exit
  end;
  GetRealCoordinate(s,d,latitude,longitude);
end;

procedure TdmUtils.DistanceFromCoordinate(my_loc:String;latitude, longitude : Real; var qra, azim: String);
var
  loc  : String;
  qra1 : String;
  azim1 : String;
begin
  my_loc := CompleteLoc(my_loc);

  if not IsLocOK(my_loc) then
    exit;

  loc := VratLokator(latitude,longitude);
  if not IsLocOK(loc) then
    exit;

  VzdalenostAAzimut(my_loc,loc,azim1,qra1);
  qra := qra1;
  azim := azim1
end;

procedure TdmUtils.DistanceFromLocator(my_loc,his_loc:String; var qra, azim: String);
var
  qra1 : String;
  azim1 : String;
begin
  if NOT IsLocOK(my_loc) then
    exit;
  if NOT IsLocOK(his_loc) then
    exit;
  VzdalenostAAzimut(my_loc,his_loc,azim1,qra1);
  qra := qra1;
  azim := azim1
end;

procedure TdmUtils.DistanceFromPrefixMyLoc(my_loc,pfx : String; var qra, azim: String);
var
  latitude, longitude: Currency;
begin
  latitude  := 0;
  longitude := 0;
  if (pfx = '') then
    exit;
  GetCoordinate(pfx,latitude, longitude);
  DistanceFromCoordinate(my_loc, latitude, longitude, qra, azim);
end;

function TdmUtils.HisDateTime(pfx : String) : String;
var
  delta  : String;
  fdelta : Currency;
  date   : TDateTime;
  sDate  : String;
  tmp    : String;
begin
  sDate  := '';
  fDelta := 0;
  result := '';
  tmp    := '';
  dmDXCC.qDXCCRef.Close;
  dmDXCC.qDXCCRef.SQL.Text := 'SELECT utc FROM cqrlog_common.dxcc_ref WHERE pref = ' + QuotedStr(pfx);
  dmDXCC.qDXCCRef.Open;
  if dmDXCC.qDXCCRef.RecordCount > 0 then
  begin
    delta := dmDXCC.qDXCCRef.Fields[0].AsString;
    if not TryStrToCurr(delta,fdelta) then
      delta := '0';
    Date := dmUtils.GetDateTime(StrToCurr(delta));
    dmUtils.DateInRightFormat(date,tmp,sDate);
    Result := sDate + '  ' + TimeToStr(Date) + '     '
  end
end;

procedure TdmUtils.ModifyWAZITU(var waz,itu : String);
begin
  if Pos('-',itu) > 0 then
    itu := copy(itu,1,Pos('-',itu)-1);
  if Length(itu) = 1 then
    itu := '0' + itu;
  if Pos('-',waz) > 0 then
    waz := copy(waz,1,Pos('-',waz)-1);
  if Length(waz) = 1 then
    waz := '0' + waz;
  waz := copy(waz,1,2);
  itu := Copy(itu,1,2);
end;

function TdmUtils.IsDateOK(date : String) : Boolean;
var
  tmp : String;
begin
  if date = '' then
  begin
    Result := False;
    exit
  end;
  Result := True;
  tmp := ShortDateFormat;
  ShortDateFormat := 'YYYY-MM-DD';
  try
    try
      StrToDate(date)
    except
      Result := False
    end
  finally
    ShortDateFormat := tmp
  end
end;

function TdmUtils.IsFreqOK(freq : String) : boolean;
begin
  if GetBandFromFreq(freq) <> '' then
    result := True
  else
    result := False
end;

function TdmUtils.FreqFromBand(band,mode : String) : String;
begin
  Result := '';
  mode   := UpperCase(mode);
  band   := UpperCase(band);
  if band = '2190M' then
  begin
    Result := '0.139';
    exit
  end;
  if band = '160M' then
  begin
    if (mode = 'CW')  then
      Result := '1.800'
    else
      Result := '1.850';
    exit
  end;
  if band = '80M' then
  begin
    if (mode = 'CW') then
      Result := '3.520'
    else
      Result := '3.770';
    exit
  end;
  if band = '60M' then
  begin
    Result := '5.2585';
    exit
  end;
  if band = '40M' then
  begin
    if (mode ='CW') then
      Result := '7.020'
    else
      Result := '7.055';
    exit
  end;
  if band = '30M' then
  begin
    Result := '10.1';
    exit
  end;
  if band = '20M' then
  begin
    if (mode = 'CW') then
      result := '14.025'
    else begin
      if (Pos('PSK',mode) > 0) then
        result := '14.075'
      else begin
        if (mode = 'RTTY') then
          Result := '14.085'
        else
          Result := '14.200'
      end;
    end;
  end;
  if band = '17M' then
  begin
    if (mode='CW') then
      result := '18.070'
    else
      result := '18.100';
    exit;
  end;
  if band = '15M' then
  begin
    if (mode='CW') then
      Result := '21.050'
    else begin
      if (Pos('PSK',mode) > 0) then
        result := '21.075'
      else begin
        if mode = 'RTTY' then
          Result := '21.085'
        else
          Result := '21.200'
      end;
    end;
    exit
  end;
  if band = '12M' then
  begin
    if (mode='CW') then
      result := '24.916'
    else begin
      if LetterFromMode(mode) = 'D' then
        Result := '24.917'
      else
        Result := '24.932'
    end;
    exit
  end;
  if band = '10M' then
  begin
    if (mode='CW') then
      result := '28.050'
    else begin
      if LetterFromMode(mode) = 'D' then
        Result := '28.100'
      else
        Result := '28.200'
    end;
    exit
  end;
  if band = '6M' then
  begin
    Result := '50.100';
    exit
  end;
  if band = '4M' then
  begin
    if mode = 'CW' then
      Result := ' 70.0500'
    else
      Result := '70.0875';
    exit
  end;
  if band = '1.25M' then
  begin
    Result := '222.010';
    exit
  end;
  if band = '2M' then
  begin
    if (mode='CW') then
      Result := '144.050'
    else
      Result := '144.280';
    exit
  end;
  if band = '70CM' then
  begin
    if mode = 'CW' then
      Result := '432.100'
    else
      Result := '432.200';
    exit
  end;
  if band = '33CM' then
  begin
    Result := '902.000';
    exit
  end;
  if band = '23CM' then
  begin
    Result := '1295.150';
    exit
  end;
  if band = '13CM' then
  begin
    Result := '2300.000';
    exit
  end;
  if band = '9CM' then
  begin
    Result := '3500.000';
    exit
  end;
  if band = '6CM' then
  begin
    Result := '5650.000';
    exit
  end;
  if band = '3CM' then
  begin
    Result := '10100.00';
    exit
  end;
  if band = '1.25CM' then
  begin
    Result := '24000.00';
    exit
  end;
  if band = '6MM' then
  begin
    Result := '47000';
    exit
  end;
  if band = '4MM' then
    Result := '75000'
end;


function TdmUtils.IsAdifOK(qsodate,time_on,time_off,call,freq,mode,rst_s,rst_r,iota,
                           itu,waz,loc,my_loc,band : String; var error : String) : Boolean;
var
  w : Integer;
begin
  w := 0;
  Result := True;
  error := '';
  if NOT IsDateOK(qsodate) then
  begin
    Result := False;
    error  := 'Wrong QSO date: '+qsodate;
    exit
  end;

  if (GetBandFromFreq(freq) = '') then
  begin
    Result := False;
    error  := 'Wrong frequency:'+freq;
    exit
  end;

  if call = '' then
  begin
    Result := False;
    error  := 'Wrong QSO call: '+call;
    exit
  end;

  if Pos('/',mode) = 0 then
  begin
    if NOT IsModeOK(mode) then
    begin
      Result := False;
      error  := 'Wrong QSO mode: '+mode;
      exit
    end
  end;

  if waz <> '' then
  begin
    if NOT TryStrToInt(waz,w) then
    begin
      error  := 'Wrong QSO waz zone: '+waz;
      Result := False;
      exit
    end
  end;

  if itu <> '' then
  begin
    if NOT TryStrToInt(itu,w) then
    begin
      Result := False;
      error  := 'Wrong QSO itu: '+itu;
      exit
    end
  end;

  if loc <> '' then
  begin
    loc := CompleteLoc(loc);
    if NOT IsLocOK(loc) then
    begin
      Result := False;
      error  := 'Wrong QSO loc: '+loc;
      exit
    end
  end;

  if my_loc <> '' then
  begin
    my_loc := CompleteLoc(my_loc);
    if NOT IsLocOK(my_loc) then
    begin
      Result := False;
      error  := 'Wrong QSO my loc: '+my_loc;
      exit
    end
  end;

  if (iota <> '') then
  begin
    if not dmUtils.IsIOTAOK(iota) then
    begin
      Result := False;
      error  := 'Wrong QSO IOTA: '+iota;
      exit
    end
  end

end;

function TdmUtils.nr(ch : Char) : Integer;
var
  letters : String;
begin
  letters := 'ABCDEFGHIJKLMNOPQRSTUVWX';
  Result  := Pos(ch,letters)
end;

procedure TdmUtils.CoordinateFromLocator(loc : String; var latitude,longitude : Currency);
var
  a,b,c,d,e,f : Integer;
begin
  if NOT IsLocOK(loc) then
    exit;

  a := nr(loc[1]);
  b := nr(loc[2]);
  c := StrToInt(loc[3]);
  d := StrToInt(loc[4]);
  e := nr(loc[5]);
  f := nr(loc[6]);
  
  longitude := (a-10)*20+c*2+(e-1)*0.083333333333333333330+0.08333333333333333333/2;
  latitude  := (b-10)*10+d*1+(f-1)*0.04166666666666666667+0.04166666666666666667/2;
end;

function TdmUtils.RemoveSpaces(S : String) : String;
var
  i : Integer;
begin
  Result := '';
  for i := 1 to Length(s) do
    if S[i] <> #10 then
      Result := Result + S[i];
end;

function TdmUtils.StripHTML(S: string): string;
var
  TagBegin, TagEnd, TagLength: integer;
  TagNum : Integer = 0;
begin
  if dmData.DebugLevel>=1 then Writeln('In StripHTML ...');
  TagBegin := Pos( '<', S);      // search position of first <
  while (TagBegin > 0) do begin  // while there is a < in S
    inc(TagNum);
    TagEnd := Pos('>', S);              // find the matching >
    TagLength := TagEnd - TagBegin + 1;
    Delete(S, TagBegin, TagLength);     // delete the tag
    TagBegin:= Pos( '<', S);            // search for next <
    if (TagBegin > 0) and (Pos('>', S) = 0) then
      TagBegin := 0;
    if TagNum > 100 then
      Break
  end;
  Result := S                   // give the result
end;

function TdmUtils.ExtractQTH(qth : String) : String;
var
  i : Integer;
  a : TExplodeArray;
begin
  qth := Trim(qth);
  if Pos(' ',qth) < 1 then
  begin
    Result := QTH;
    exit
  end;
  a := Explode(' ',qth);
  if (IncludesNum(a[0])) then
  begin
    for i:=1 to Length(a)-1 do
      Result := Result + ' ' + a[i]
  end
  else begin
    if IncludesNum(a[Length(a)-1]) then
    begin
      for i:=0 to Length(a)-2 do
        Result := Result + ' ' + a[i]
    end
    else
      Result := qth
  end;
  Result := Trim(Result)
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

function TdmUtils.GetModeFromFreq(freq : String) : String; //freq in MHz
var
  Band : String;
  tmp   : Extended;
begin
  Result := '';
  band := GetBandFromFreq(freq);
  dmData.qBands.Close;
  dmData.qBands.SQL.Text := 'SELECT * FROM cqrlog_common.bands WHERE band = ' + QuotedStr(band);
  if dmData.trBands.Active then  dmData.trBands.Rollback;
  dmData.trBands.StartTransaction;
  try
    dmData.qBands.Open;
    tmp := StrToFloat(freq);
    if dmData.qBands.RecordCount > 0 then
    begin
      if ((tmp >= dmData.qBands.FieldByName('B_BEGIN').AsCurrency) and
         (tmp <= dmData.qBands.FieldByName('CW').AsCurrency)) then
        Result := 'CW'
      else begin
        if ((tmp > dmData.qBands.FieldByName('RTTY').AsCurrency) and
           ( tmp <= dmData.qBands.FieldByName('SSB').AsCurrency)) then
          Result := 'RTTY'
        else begin
          if tmp > 10 then
            Result := 'USB'
          else
            Result := 'LSB'
        end
      end
    end
  finally
    dmData.qBands.Close;
    dmData.trBands.Rollback
  end
end;

function TdmUtils.StringToADIF(text : String) : String;
begin
  result := ':'+ IntToStr(Length(text)) + '>'+ text;
end;

function TdmUtils.MyTrim(text : String) : String;
var
  i : Integer;
begin
  text := Trim(text);
  Result := '';
  for i:=1 to Length(text) do
  begin
    //if NOT (text[i] in MyWhiteSpace) then
    if (text[i] in AllowedChars) then
     Result := Result + text[i]
  end
end;

function  TdmUtils.ReplaceSpace(txt : String) : String;
var
  i   : integer;
begin
  Result := '';
  for i := 1 to length(txt) do
  begin
    if txt[i] = ' ' then
      Result := Result + '&nbsp;'
    else
      Result := Result + txt[i]
  end;
end;

function  TdmUtils.ReplaceEnter(txt : String) : String;
var
  i   : integer;
begin
  Result := '';
  for i := 1 to length(txt) do
  begin
    if txt[i] = #10 then
      txt[i] := ' '
  end;
  Result := trim(txt);
end;

function TdmUtils.MyStrToFloat(num : String) : Extended;
begin
  if Pos('.',num) > 0 then
    num[Pos('.',num)] := DecimalSeparator;
  Result := StrToFloat(num);
end;

function TdmUtils.ExtractQSLMgr(text : String) : String;
begin
  text := UpperCase(text);
  if pos('QSL VIA',text) > 0 then
  begin
    text := copy(text,pos('QSL VIA',text)+8,Length(text)-pos('QSL VIA',text)+1);
    text := Trim(text);
    if Pos(' ',text) > 0 then
       text := copy(text,1,Pos(' ',text)-1);
    Result := text;
  end
  else
    Result := '';
end;

function  TdmUtils.ExtractPower(power : String) : String;
var
  i : Integer;
begin
  Result := '';
  for i:= 1 to Length(power) do
  begin
    if (power[i] in ['0'..'9',DecimalSeparator]) then
      Result := Result + power[i];
  end;
end;

procedure TdmUtils.LoadFontSettings(aForm : TForm);
var
  i : Integer;
  fEdits : String;
  feSize : Integer;
  fButtons : String;
  fbSize   : Integer;
  fGrids : String;
  fgSize : Integer;
  fQsoGr : String;
  fqSize : Integer;
begin
  if dmData.DBName = '' then
    exit;
  if cqrini.ReadBool('Fonts','UseDefault',True) then
  begin
    fEdits   := 'default';
    feSize   := 0;
    fButtons := 'default';
    fbSize   := 0;
    fGrids   := 'default';
    fgSize   := 0;
    fQsoGr   := 'default';
    fqSize   := 0;
  end
  else begin
    fEdits := cqrini.ReadString('Fonts','Edits','Sans 10');
    feSize := cqrini.ReadInteger('Fonts','eSize',10);

    fButtons := cqrini.ReadString('Fonts','Buttons','Sans 10');
    fbSize   := cqrini.ReadInteger('Fonts','bSize',10);

    fGrids := cqrini.ReadString('Fonts','Grids','Monospace 8');
    fgSize := cqrini.ReadInteger('Fonts','gSize',8);

    fQsoGr := cqrini.ReadString('Fonts','QGrids','Sans 10');
    fqSize := cqrini.ReadInteger('Fonts','qSize',10)
  end;

  for i := 0 to aForm.ComponentCount-1 do
  begin
    //edits, memo combo, spinedit ...
    if (aForm.Components[i] is TEdit) then
    begin
      (aForm.Components[i] as TEdit).Font.Name := fEdits;
      (aForm.Components[i] as TEdit).Font.Size := feSize;
    end;

    if (aForm.Components[i] is TMemo) then
    begin
      (aForm.Components[i] as TMemo).Font.Name := fEdits;
      (aForm.Components[i] as TMemo).Font.Size := feSize;
    end;

    if (aForm.Components[i] is TMemo) then
    begin
      (aForm.Components[i] as TMemo).Font.Name := fEdits;
      (aForm.Components[i] as TMemo).Font.Size := feSize;
    end;

    if (aForm.Components[i] is TSpinEdit) then
    begin
      (aForm.Components[i] as TSpinEdit).Font.Name := fEdits;
      (aForm.Components[i] as TSpinEdit).Font.Size := feSize;
    end;

    if (aForm.Components[i] is TComboBox) then
    begin
      (aForm.Components[i] as TComboBox).Font.Name := fEdits;
      (aForm.Components[i] as TComboBox).Font.Size := feSize;
    end;

    if (aForm.Components[i] is TColorBox) then
    begin
      (aForm.Components[i] as TColorBox).Font.Name := fEdits;
      (aForm.Components[i] as TColorBox).Font.Size := feSize;
    end;

    ///////////////////////////////////////////////////////////
    //labels, buttons, radio,checkbox ....
    if (aForm.Components[i] is TLabel) then
    begin
      if not (((aForm.Components[i] as TLabel).Name  = 'lblFreq')
           or ((aForm.Components[i] as TLabel).Name  = 'lblAzimuth')) then //frequecy/Azimuth label font is set
      begin
        (aForm.Components[i] as TLabel).Font.Name := fButtons;
        (aForm.Components[i] as TLabel).Font.Style := [];
      end;
    end;

    if (aForm.Components[i] is TGroupBox) then
    begin
      (aForm.Components[i] as TGroupBox).Font.Name := fButtons;
      (aForm.Components[i] as TGroupBox).Font.Size := fbSize;
    end;

    if (aForm.Components[i] is TButton) then
    begin
      (aForm.Components[i] as TButton).Font.Name := fButtons;
      (aForm.Components[i] as TButton).Font.Size := fbSize;
    end;
      
    if (aForm.Components[i] is TCheckBox) then
    begin
      (aForm.Components[i] as TCheckBox).Font.Name := fButtons;
      (aForm.Components[i] as TCheckBox).Font.Size := fbSize;
    end;
       
    if (aForm.Components[i] is TRadioButton) then
    begin
      (aForm.Components[i] as TRadioButton).Font.Name := fButtons;
      (aForm.Components[i] as TRadioButton).Font.Size := fbSize;
    end;

    if (aForm.Components[i] is TBitBtn) then
    begin
      (aForm.Components[i] as TBitBtn).Font.Name := fButtons;
      (aForm.Components[i] as TBitBtn).Font.Size := fbSize;
    end;

    /////////////////////////////////////////////////////////
    //dbgrids
    if (aForm.Components[i] is TDBGrid) then
    begin
      (aForm.Components[i] as TDBGrid).Font.Name := fQsoGr;
      (aForm.Components[i] as TDBGrid).Font.Size := fqSize;
    end;
    
    ////////////////////////////////////////////////////////
    //statistics
    if (aForm.Components[i] is TStringGrid) then
    begin
      (aForm.Components[i] as TStringGrid).Font.Name := fGrids;
      (aForm.Components[i] as TStringGrid).Font.Size := fgSize;
    end;
  end;
end;

function TdmUtils.ExtractFontSize(sFont : String) : Integer;
var
  i : Integer=0;
  s : String='';
begin
  for i:=Length(sFont) downto 1 do
  begin
    if sFont[i] = ' ' then
      break
    else
      s := sFont[i] + s;
  end;
  if not TryStrToInt(s,Result) then
    Result := 10;
end;

function TdmUtils.ExtractCallsign(call : String) : String;
var
  Before  : String = '';
  After   : String = '';
  Middle  : String = '';
  ar      : TExplodeArray;
  num     : Integer = 0;
begin
  result := call;
  if Pos('/',call) = 0 then
    exit;

  SetLength(ar,0);
  ar  := Explode('/',call);
  num := Length(ar)-1;

  if num = 2 then
  begin
    Before := ar[0];
    Middle := ar[1];

    if Length(Before) > Length(middle) then
      Result := Before // RA1AA/1/M
    else
      Result := Middle //KH6/OK2CQR/P
  end
  else begin
    Before := ar[0];
    After  := ar[1];
  
    if Length(Before) <=3 then
    begin
      Result := After;
      exit
    end;
    
    if Length(After) <= 3 then
    begin
      Result := Before;
      exit
    end;
    
    if dmDXCC.IsException(After) then
      Result := Before
    else
      Result := After
  end;
end;

function TdmUtils.GetGreetings(time : String) : String;
var
  h : Integer;
begin
  Result := '';
  time := copy(time,Pos(' ',time)+2,2);
  if TryStrToInt(time,h) then
  begin
    if h < 3 then
      Result := 'GE/GM'
    else begin
      if (h > 3) and (h < 12) then
        Result := 'GM'
      else begin
        if (h >= 12) and (h < 16) then
          Result := 'GA'
        else
          Result := 'GE'
      end;
    end;
  end;
end;

procedure TdmUtils.LoadBandLabelSettins;
begin
  if cqrini.ReadBool('Program','BandStatMHz',True) then
  begin
    s136  := '136k';
    s160  := '1.8';
    s80   := '3.5';
    s60   := '5';
    s40   := '7';
    s30   := '10.1';
    s20   := '14';
    s17   := '18';
    s15   := '21';
    s12   := '24';
    s10   :=  '28';
    s6    := '50';
    s4    := '70';
    s2    := '144';
    s220  := '220';
    s70   := '430';
    s900  := '902';
    s1260 := '1260';
    s2300 := '2300';
    s3400 := '3400';
    s5850 := '5650';
    s10G  := '10G';
    s24G  := '24G';
    s47G  := '47G';
    s76G  := '76G';
  end
  else begin
    s136  := '2.2k';
    s160  := '160';
    s80   := '80';
    s60   := '60';
    s40   := '40';
    s30   := '30';
    s20   := '20';
    s17   := '17';
    s15   := '15';
    s12   := '12';
    s10   := '10';
    s6    := '6m';
    s4    := '4m';
    s2    := '2m';
    s220  := '1.25m';
    s70   := '70c';
    s900  := '33c';
    s1260 := '23c';
    s2300 := '13c';
    s3400 := '8cm';
    s5850 := '5cm';
    s10G  := '3cm';
    s24G  := '1cm';
    s47G  := '6mm';
    s76G  := '4mm';
  end
end;

function TdmUtils.IsIOTAOK(iota : String) : Boolean;
var
  c,snr : String;
  i     : Integer;
begin
  Result := False;
  if Length(iota) <> 6 then
    exit;
  c := copy(iota,1,2); //AS,EU,OC,NA,SA,AF
  if (c <> 'AS') and (c <> 'EU') and (c <> 'OC') and (c <> 'NA') and
     (c <> 'SA') and (c <> 'AN') and (c <> 'AF') then
     exit;
  snr := copy(iota,4,3);
  for i:=1 to 3 do
    if not (snr[i] in ['0'..'9']) then
    begin
      exit
    end;
  Result := True;
end;

procedure TdmUtils.GetRealCoordinate(lat,long : String; var latitude, longitude: Currency);
var
  s,d : String;
begin
  s := lat;
  d := long;
  if ((Length(s)=0) or (Length(d)=0)) then
  begin
    longitude := 0;
    latitude  := 0;
    exit
  end;

  if s[Length(s)] = 'S' then
    s := '-' +s ;
  s := copy(s,1,Length(s)-1);
  if pos('.',s) > 0 then
    s[pos('.',s)] := DecimalSeparator;
  if not TryStrToCurr(s,latitude) then
    latitude := 0;

  if d[Length(d)] = 'W' then
    d := '-' + d ;
  d := copy(d,1,Length(d)-1);
  if pos('.',d) > 0 then
    d[pos('.',d)] := DecimalSeparator;
  if not TryStrToCurr(d,longitude) then
    longitude := 0;
  if dmData.DebugLevel>=4 then
  begin
    //Writeln('Lat:  ',latitude);
    //Writeln('Long: ',longitude);
  end;
end;

procedure TdmUtils.ReadMemberList(cmbMemebers : TComboBox);
var
  res        : Byte;
  SearchRec  : TSearchRec;
  f          : TextFile;
  ShortName  : String = '';
  LongName   : String = '';
  Ts         : TStringList;
  i          : Integer=0;
begin
  cmbMemebers.Clear;
  cmbMemebers.Items.Add('');
  Ts := TStringList.Create;
  try
    res := FindFirst(dmData.MembersDir + '*.txt', faAnyFile, SearchRec);
    while Res = 0 do
    begin
      if FileExists(dmData.MembersDir + SearchRec.Name) then
      begin
        AssignFile(f,dmData.MembersDir+SearchRec.Name);
        Reset(f);
        ReadLn(f,ShortName);
        ReadLn(f,LongName);
        Ts.Add(ShortName + ';' + LongName);
        CloseFile(f);
      end;
      Res := FindNext(SearchRec);
    end;
    Ts.Sort;
    for i:=0 to Ts.Count-1 do
      cmbMemebers.Items.Add(Ts.Strings[i])
  finally
    FindClose(SearchRec);
    Ts.Free
  end
end;

function TdmUtils.SetSize(text : String;Len : Integer) : String;
var
  i : Integer;
begin
  Result := text;
  for i:=Length(text) to Len-1 do
    Result := Result + ' ';
end;

function TdmUtils.SetSizeLeft(text : String;Len : Integer) : String;
var
  i : Integer;
begin
  Result := text;
  for i:=Length(text) to Len-1 do
    Result := ' ' + Result;
end;

function TdmUtils.MonthToStr(mon : Integer) : String;
begin
  Result := 'JAN';
  case mon of
    1 : Result := 'JAN';
    2 : Result := 'FEB';
    3 : Result := 'MAR';
    4 : Result := 'APR';
    5 : Result := 'MAY';
    6 : Result := 'JUN';
    7 : Result := 'JUL';
    8 : Result := 'AUG';
    9 : Result := 'SEP';
   10 : Result := 'OCT';
   11 : Result := 'NOV';
   12 : Result := 'DEC';
  end; //case
end;

function TdmUtils.GetIDCall(callsign : String) : String;
var
  Pole  : TExplodeArray;
begin
  Result := callsign;
  if Pos('/',callsign) = 0 then
    exit;
  SetLength(pole,0);
  pole  := Explode('/',callsign);
  if dmDXCC.IsException(pole[1]) then
    Result := pole[0]
  else begin
    if Length(pole[0]) > Length(pole[1]) then  //FJ/G3TXF, RA1AA/1/M etc
      Result := pole[0]
    else
      Result := pole[1]
  end
end;

function TdmUtils.ExtractIOTAPrefix(call : String; date : TDateTime) : String;
var
  before,after, between : String;
  p : Integer;
begin
  Result := '';
  p := Pos('/',call);
  if p > 0 then
  begin
     before := copy(call,1,p);
     after  := copy(call,p+1,Length(call)-p);
     if Pos('/',after) > 0 then
     begin
       between := copy(after,1,Pos('/',after)-1);
       after   := copy(after,Pos('/',after)+1,Length(after)-Pos('/',after));
       if (between[1] in ['0'..'9']) and (Length(before) >=3) and (Length(between)=1) then
         before[3] := between[1];
       Result := before
     end
     else begin
       if (Length(after) = 1) and (after[1] in ['0'..'9']) then
       begin
         before[3] := after[1];
         result := copy(before,1,3)
       end
       else begin
         if dmDXCC.IsPrefix(before,date) then
           Result := Before
         else begin
           if dmDXCC.IsPrefix(After,date) then
             Result := After;
         end;
       end
     end;
  end
  else
    result := copy(before,1,3)
end;

function TdmUtils.IncludesNum(text : String) : Boolean;
var
  i : Integer;
begin
  Result := False;
  for i:=1 to Length(text)-1 do
  begin
    if text[i] in ['0'..'9'] then
    begin
      Result := True;
      exit
    end;
  end;
end;

procedure TdmUtils.SortList(l : TStringList);
var
  i   : Integer;
  min : Integer;
  y   : Integer;
  a,b : double;
  tmp : String;
begin
  for i:=0 to l.Count-1 do  //projdeme prvky pole
  begin
    min := i;
    for y:=i to l.Count-1 do
    begin
      tmp := copy(l.Strings[min],1,Pos(';',l.Strings[min])-1);
      if not TryStrToFloat(tmp,a) then
        exit;
      tmp := copy(l.Strings[y],1,Pos(';',l.Strings[y])-1);
      if not TryStrToFloat(tmp,b) then
        exit;
      if a > b then
        min := y;
    end;
    tmp := l.Strings[i];
    l.Strings[i]   := l.Strings[min];
    l.Strings[min] := tmp;
  end;
  {
  for i:=0 to l.Count-1 do
    WriteLn(l.Strings[i]);
  }
end;

function TdmUtils.GetRigError(err : Integer) : String;
begin
  Result := '';
  case err of
    1 : Result := 'RIG_EINVAL: Invalid parameter';
    2 : Result := 'RIG_ECONF: Invalid configuration (serial,..)';
    3 : Result := 'RIG_ENOMEM: Memory shortage';
    4 : Result := 'RIG_ENIMPL: Function not implemented, but will be';
    5 : Result := 'RIG_ETIMEOUT: Communication timed out';
    6 : Result := 'RIG_EIO: IO error, including open failed';
    7 : Result := 'RIG_EINTERNAL: Internal Hamlib error, huh!';
    8 : Result := 'RIG_EPROTO: Protocol error';
    9 : Result := 'RIG_ERJCTED: Command rejected by the rig';
   10 : Result := 'RIG_ETRUNC: Command performed, but arg truncated';
   11 : Result := 'RIG_ENAVAIL: Function not available';
   12 : Result := 'RIG_ENTARGET: VFO not targetable';
  end; //case
end;

function TdmUtils.IncColor(AColor: TColor; AQuantity: Byte) : TColor;
var
  R, G, B : Byte;
begin
  RedGreenBlue(ColorToRGB(AColor), R, G, B);
  R := Max(0, Integer(R) + AQuantity);
  G := Max(0, Integer(G) + AQuantity);
  B := Max(0, Integer(B) + AQuantity);
  Result := RGBToColor(R, G, B);
end;

function TdmUtils.IsItIOTA(spot : String) : Boolean;
var
  p   : Integer;
begin
  spot   := UpperCase(spot);
  Result := False;

  p := Pos('EU',spot);
  if p > 0 then
  begin
    if spot[p+1] = '-' then
    begin
      Result := IsIOTAOK(copy(spot,p,6));
    end
    else begin
      Result := IsIOTAOK('EU-'+copy(spot,p+3,3));
    end;
  end;
  if Result then
    exit;

  p := Pos('AS',spot);
  if p > 0 then
  begin
    if spot[p+1] = '-' then
    begin
      Result := IsIOTAOK(copy(spot,p,6));
    end
    else begin
      Result := IsIOTAOK('AS-'+copy(spot,p+3,3));
    end;
  end;
  if Result then
    exit;

  p := Pos('NA',spot);
  if p > 0 then
  begin
    if spot[p+1] = '-' then
    begin
      Result := IsIOTAOK(copy(spot,p,6));
    end
    else begin
      Result := IsIOTAOK('NA-'+copy(spot,p+3,3));
    end;
  end;
  if Result then
    exit;

  p := Pos('SA',spot);
  if p > 0 then
  begin
    if spot[p+1] = '-' then
    begin
      Result := IsIOTAOK(copy(spot,p,6));
    end
    else begin
      Result := IsIOTAOK('SA-'+copy(spot,p+3,3));
    end;
  end;
  if Result then
    exit;

  p := Pos('AF',spot);
  if p > 0 then
  begin
    if spot[p+1] = '-' then
    begin
      Result := IsIOTAOK(copy(spot,p,6));
    end
    else begin
      Result := IsIOTAOK('AF-'+copy(spot,p+3,3));
    end;
  end;
  if Result then
    exit;

  p := Pos('OC',spot);
  if p > 0 then
  begin
    if spot[p+1] = '-' then
    begin
      Result := IsIOTAOK(copy(spot,p,6));
    end
    else begin
      Result := IsIOTAOK('OC-'+copy(spot,p+3,3));
    end;
  end;
  if Result then
    exit;

  p := Pos('AN',spot);
  if p > 0 then
  begin
    if spot[p+1] = '-' then
    begin
      Result := IsIOTAOK(copy(spot,p,6));
    end
    else begin
      Result := IsIOTAOK('AN-'+copy(spot,p+3,3));
    end;
  end;
end;

function TdmUtils.GetXplanetCommand : String;
var
  myloc  : String = '';
  lat, long : Currency;
  wait   : String;
  geom   : String;
  proj   : String = '';
begin
  Result := '';
  Result := cqrini.ReadString('xplanet','path','/usr/bin/xplanet');
  myloc  := cqrini.ReadString('Station','LOC','');
  if not FileExists(Result) then
  begin
    Result := '';
    exit
  end;
  geom := ' -geometry '+cqrini.ReadString('xplanet','width','100')+'x'+
          cqrini.ReadString('xplanet','height','100') + '+'+ cqrini.ReadString('xplanet','left','10')+
          '+'+cqrini.ReadString('xplanet','top','10');
  if IsLocOK(myloc) then
  begin
    CoordinateFromLocator(CompleteLoc(myloc),lat,long);
    myloc := ' -longitude ' + CurrToStr(long) + ' -latitude ' + CurrToStr(lat);
  end;
  case cqrini.ReadInteger('xplanet','project',0) of
    0 : proj := '';
    1 : proj := ' -projection azimuthal -background '+dmData.HomeDir+'xplanet'+PathDelim+'bck.png';
    2 : proj := ' -projection azimuthal';
  end; //case
  wait := '-wait ' + cqrini.ReadString('xplanet','refresh','5');
  Result :=  Result + ' -config ' + dmData.HomeDir + 'xplanet'+PathDelim+'geoconfig -window ' +
             myloc + ' -glare 28 -light_time -range 2.5 ' + wait + ' ' + geom + ' -window_title "CQRLOG - xplanet"'+
             proj;
end;

procedure TdmUtils.RunXplanet;
var
  AProcess : TProcess;
begin
  AProcess := TProcess.Create(nil);
  try
    AProcess.CommandLine := GetXplanetCommand;
    if dmData.DebugLevel>=1 then Writeln('Command line: ',AProcess.CommandLine);
    if (AProcess.CommandLine = '') then
      exit;
    AProcess.Execute;
  finally
    AProcess.Free;
  end
end;

procedure TdmUtils.CloseXplanet;
var
  AProcess : TProcess;
begin
  AProcess := TProcess.Create(nil);
  try
    AProcess.CommandLine := 'killall xplanet';
    AProcess.Options := [poNoConsole,poNewProcessGroup];
    if dmData.DebugLevel>=1 then Writeln('Command line: ',AProcess.CommandLine);
    AProcess.Execute;
  finally
    AProcess.Free
  end
end;

procedure TdmUtils.ModifyXplanetConf;
var
  l : TStringList;
  i : Integer;
begin
  l := TStringList.Create;
  try
    l.LoadFromFile(dmData.HomeDir + 'xplanet'+PathDelim+'geoconfig');
    for i:=0 to l.Count-1 do
    begin
      if Pos('marker_file=',l.Strings[i]) > 0 then
      begin
        l.Strings[i] := 'marker_file='+dmData.HomeDir + 'xplanet'+PathDelim+'marker';
        break
      end
    end;
    l.SaveToFile(dmData.HomeDir + 'xplanet'+PathDelim+'geoconfig')
  finally
    l.Free
  end
end;

procedure TdmUtils.DeleteMarkerFile;
begin
  DeleteFile(dmData.HomeDir + 'xplanet'+PathDelim+'marker')
end;

function TdmUtils.GetLastUpgradeDate : TDateTime;
var
  older    : LongInt = 0;
  dir      : String;
begin
  dir := dmData.HomeDir + 'ctyfiles' + PathDelim;
  if FileAge(dir + 'AreaOK1RR.tbl') > FileAge(dir + 'CallResolution.tbl') then
    older := FileAge(dir + 'AreaOK1RR.tbl')
  else
    older := FileAge(dir + 'CallResolution.tbl');
  if older < FileAge(dir + 'Country.tab')  then
    older := FileAge(dir + 'Country.tab');
  Result := FileDateToDateTime(older)+1
end;

function TdmUtils.GetLastQSLUpgradeDate : TDateTime;
var
  dir      : String;
begin
  dir := dmData.HomeDir + 'ctyfiles' + PathDelim;
  if FileExists(dir + 'qslmgr.csv') then
    Result := FileDateToDateTime(FileAge(dir + 'qslmgr.csv'))+1
  else
    Result := EncodeDate(2000,01,01)
end;


function TdmUtils.UnTarFiles(FileName,TargetDir : String) : Boolean;
var
  AProcess : TProcess;
  dir      : String;
begin
  Result := True;
  dir := GetCurrentDir;
  SetCurrentDir(TargetDir);
  AProcess := TProcess.Create(nil);
  try
    AProcess.CommandLine := 'tar -xvzf '+FileName;
    AProcess.Options := [poNoConsole,poNewProcessGroup,poWaitOnExit];
    if dmData.DebugLevel>=1 then Writeln('Command line: ',AProcess.CommandLine);
    try
      AProcess.Execute;
    except
      Result := False
    end;
  finally
    SetCurrentDir(dir);
    AProcess.Free;
  end
end;

procedure TdmUtils.ReadZipList(cmbZip : TComboBox);
var
  res       : Byte;
  SearchRec : TSearchRec;
  f         : TextFile;
  ShortName : String = '';
  LongName  : String = '';
  Ts        : TStringList;
  i         : Integer=0;
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
        AssignFile(f,dmData.ZipCodeDir+SearchRec.Name);
        Reset(f);
        ReadLn(f,ShortName);
        ReadLn(f,LongName);
        Ts.Add(ShortName + ';' + LongName);
        CloseFile(f);
      end;
      Res := FindNext(SearchRec);
    end;
    Ts.Sort;
    for i:=0 to Ts.Count-1 do
      cmbZip.Items.Add(Ts.Strings[i])
  finally
    FindClose(SearchRec);
    Ts.Free
  end
end;

function TdmUtils.ExtractZipCode(qth : String; Position : Integer) : String;
var
  i : Integer;
begin
  if dmData.DebugLevel>=1 then Writeln('Position: ',Position);
  Result := '';
  if Position = 0 then
    Result := copy(qth,1,Pos(' ',qth)-1)
  else begin
    for i:=Length(qth) downto 1 do
    begin
      if qth[i] <> ' ' then
        Result := qth[i] + Result
      else
        break
    end;
  end;
  Result := Trim(Result);
  if Pos('-',Result) > 0 then
    Result := Copy(Result,1,Pos('-',Result)-1);
end;

function TdmUtils.GetLabelBand(freq : String) : String;
begin
  Result := LowerCase(GetBandFromFreq(freq))
end;

function TdmUtils.GetCWMessage(Key,call,rst_s,HisName,text : String; QSONR : String = '') : String;
{
 %mc - my callsign
 %mn - my name
 %mq - my qth
 %nr - qso number
 
 %r  - rst send
 %n  - name
 %c  - callsign

if text is not empty and we didn't send any key (F1 etc.) we can
use this function to prepare every text wee need to send
}

var
  mycall : String = '';
  myname : String = '';
  myqth  : String = '';
begin
  {$IFDEF CONTEST}
  if dmData.ContestMode and dmData.ContestDatabase.Connected then
  begin
    if dmData.ProgramMode = tmSP then
      mode := 'SP';
    if key <> '' then
      Result := dmData.tstini.ReadString('CW',mode+key,'')
    else
      Result := text;
    mycall := dmData.tstini.ReadString('Basic','Call','');
    myname := dmData.tstini.ReadString('Basic','Name','');
    myqth  := dmData.tstini.ReadString('Basic','QTH','')
  end
  else begin
  {$ENDIF}
    mycall := cqrini.ReadString('Station','Call','');
    myname := cqrini.ReadString('Station','Name','');
    myqth  := cqrini.ReadString('Station','QTH','');
    if key <> '' then
      Result := LowerCase(cqrini.ReadString('CW',key,''))
    else
      Result := text;
  {$IFDEF CONTEST}
  end;
  {$ENDIF}
  Result := StringReplace(Result,'%mc',mycall,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%mn',myname,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%mq',myqth,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%nr',QSONR,[rfReplaceAll, rfIgnoreCase]);

  Result := StringReplace(Result,'%r',rst_s,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%n',HisName,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%c',call,[rfReplaceAll, rfIgnoreCase]);
  if dmData.DebugLevel>=1 then Writeln('Sending:',Result)
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

  cmd := cqrini.ReadString('TRX','Path','/usr/bin/rigctld');
  if not FileExists(cmd) then
    exit;
  cmd := cmd+' --model='+rigid;
  cmd := cmd + ' --rig-file='+Device;
  if Port <> '' then
    cmd := cmd+' --port='+port;
  if Speed <> '' then
    cmd := cmd+' --serial-speed='+ Speed;
  case parity of
    0  : cmd := cmd+' --set-conf=serial_parity=None';
    1  : cmd := cmd+' --set-conf=serial_parity=Odd';
    2  : cmd := cmd+' --set-conf=serial_parity=Even'
  end; //case
  if (DataBits < 9) and (DataBits > 4) then
    cmd := cmd+' --set-conf=data_bits='+IntToStr(DataBits);
  if (StopBits > 0) and (StopBits < 4) then
    cmd := cmd+' --set-conf=stop_bits='+IntToStr(StopBits);
  case HandShake of
    0 : cmd := cmd+' --set-conf=serial_handshake=None';
    1 : cmd := cmd+' --set-conf=serial_handshake=XONXOFF';
    2 : cmd := cmd+' --set-conf=serial_handshake=Hardware'
  end;
  if RTS then
    cmd := cmd+' --set-conf=rts_state=ON'
  else
    cmd := cmd+' --set-conf=rts_state=OFF';
  if DTR then
    cmd := cmd+' --set-conf=dtr_state=ON'
  else
    cmd := cmd+' --set-conf=dtr_state=OFF';
  if civadr <> '' then
    cmd := cmd+'--civaddr='+civadr;
  Result := cmd + ' >> /dev/null &'
end;

procedure TdmUtils.CalcSunRiseSunSet(Lat,Long : Double; var SunRise,SunSet : TDateTime);

  function DateTimeToJulianDate(const AValue: TDateTime): Double;
  var
    LYear, LMonth, LDay: Word;
  begin
    DecodeDate(AValue, LYear, LMonth, LDay);
    Result := (1461 * (LYear + 4800 + (LMonth - 14) div 12)) div 4 +
              (367 * (LMonth - 2 - 12 * ((LMonth - 14) div 12))) div 12 -
              (3 * ((LYear + 4900 + (LMonth - 14) div 12) div 100)) div 4 +
              LDay - 32075.5 + Frac(AValue);
  end;

  function JulianDateToDateTime(const AValue: Double) : TDateTime;
  var
    L, N, LYear, LMonth, LDay: Integer;
    ADateTime : TDateTime;
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
    Result := ADateTime
  end;

  function put_in_360(x:extended):extended;
  begin
    result:=x-round(x/360)*360;
    while result<0 do
    result:=result+360;
  end;

  function deg2rad(x:extended):extended;
  begin
    result:=x/180*pi;
  end;

  function rad2deg(x:extended):extended;
  begin
    result:=x*180/pi;
  end;

  function sin_d(x:extended):extended;
  begin
    sin_d:=sin(deg2rad(put_in_360(x)));
  end;

  function cos_d(x:extended):extended;
  begin
    cos_d:=cos(deg2rad(put_in_360(x)));
  end;

  function arcsin_d(x:extended):extended;
  begin
    result:=rad2deg(arcsin(x));
  end;

  function arcsin(x:extended):extended;
  begin
    if x<1 then
      if x>-1 then
         result:=arctan(x/sqrt(1-x*x))
        else
       result:=-90
        else
          result:=90;
  end;

  function arccos(x:extended):extended;
  begin
    result:=pi/2-arcsin(x);
  end;

  function arccos_d(x:extended):extended;
  begin
    result:=rad2deg(arccos(x))
  end;


var
  n     : Double; //Julian cycle since Jan 1, 2000
  jDate : Double; //Julian date
  tmp   : Double;

  lw     : Double; // West Longitude (75W = 75, 45E = -45)
  ln     : Double; // North Latitude (35N = 35, 25S = -25)
  M      : Double; // Mean Solar Anomaly
  C      : Double; // Equation of center
  lambda : Double; // Ecliptical longitude of the sun
  delta  : Double; // Declination of the sun
  H      : Double; // Hour Angle (half the arc length of the sun)
  Jtran  : Double; //Julian date of solar noon on cycle n

  M1 : Integer;

begin
  jDate := DateTimeToJulianDate(now);
  //Writeln('jDate:',FloatToStr(jDate));
  ln  := lat;
  lw  := Long*-1; //we need west longitude

  //First, start by calculating the number of days since January 1, 2000.
  //Add that number to 2451545 (the Julian day of January 1, 2000).
  //This will be variable Jdate.

  //The next step is to calculate the Julian cycle. This is not equal to
  //the days since Jan 1, 2000. Depending on your longitude, this
  //may be a different number.
  n := (jDate - 2451545 - 0.0009) - (lw/360);
  n := round(n);

  //Now, it is time to approximate the Julian date of solar noon.
  //This is just an approximation so that we can make some intermediate
  //calculations before we calculate the actual Julian date of solar noon.
  jDate := 2451545 + 0.0009 + (lw/360) + n;

  //Using the approximate value, calculate the mean solar anomaly. This will
  //get a very close value to the actual mean solar anomaly.
  //M = [357.5291 + 0.98560028 * (J* - 2451545)] mod 360
  M   := (357.5291 + 0.98560028 * (jDate - 2451545));
  M1  := Trunc(M);
  tmp := M - M1;
  M1  := M1 div 360;
  M   := M - (M1*360) + tmp;

  //Calculate the equation of center
  C := (1.9148 * sin_d(M)) + (0.0200 * sin_d(2 * M)) + (0.0003 * sin_d(3 * M));

  //Now, using C and M, calculate the ecliptical longitude of the sun.
  //lambda := (M + 102.9372 + C + 180) mod 360;
  lambda := (M + 102.9372 + C + 180);
  M1  := Trunc(lambda);
  tmp := lambda - M1;
  M1  := M1 div 360;
  lambda := lambda - (M1*360) + tmp;
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
  jDate := 2451545 + 0.0009 + ((H + lw)/360) + n;
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
  SunSet  := JulianDateToDateTime(SunSet);
end;

procedure TdmUtils.ExecuteCommand(cmd : String);
var
   AProcess: TProcess;
begin
  AProcess := TProcess.Create(nil);
  try
    AProcess.CommandLine := cmd;
    if dmData.DebugLevel >=1 then Writeln('Command line: ',AProcess.CommandLine);
    AProcess.Options     := AProcess.Options + [poWaitOnExit];
    AProcess.Execute
  finally
    AProcess.Free
  end
end;

function TdmUtils.CallTrim(call : String) : String;
var
  i : Integer;
begin
  Result := '';
  for i:=1 to Length(call) do
  begin
    if (call[i] in AllowedCallChars) then
      Result := Result + call[i]
  end
end;

function TdmUtils.GetQSLVia(text : String) : String;
begin
  text := UpperCase(text);
  Result := text;
  if text = 'BURO OR DIRECT' then
    Result := '';
  if text = 'BURO' then
    Result := '';
  if text = 'VIA BURO' then
    Result := '';
  if Pos('QSL VIA',text) = 1 then
    Result := copy(text,8,Length(text)-7);
  if Pos('VIA',text) = 1 then
    Result := copy(text,5,Length(text)-4)
  //Writeln('GetQSLVia:',text);
  //Writeln('GetQSLVia:',Result);
end;

function TdmUtils.IsQSLViaValid(text : String) : Boolean;
begin
  reg.InputString := text;
  reg.Expression  := '\A\w{1,2}\d[A-Z]{1,3}\Z';
  Result := reg.ExecPos(1)
end;

function TdmUtils.GetShortState(state : String) : String;
var
  i : Integer;
begin
  Result := '';
  for i:=1 to 50 do
  begin
    if Pos(state,USstates[i]) > 0 then
    begin
      Result := copy(USstates[i],1,2);
      Break
    end
  end
end;

procedure TdmUtils.RunOnBackgroud(path : String);
var
  AProcess : TProcess;
begin
  AProcess := TProcess.Create(nil);
  try
    AProcess.CommandLine := path;
    if dmData.DebugLevel>=1 then Writeln('Command line: ',AProcess.CommandLine);
    if (AProcess.CommandLine = '') then
      exit;
    AProcess.Execute
  finally
    AProcess.Free
  end
end;

function TdmUtils.GetQRZInfo(call : String; var nick,qth,address,zip,grid,state,county,qsl,iota,ErrMsg : String) : Boolean;
var
  http : THTTPSend;
  req  : String = '';
  m    : TStringList;
begin
  Result  := False;
  address := '';
  grid    := '';
  state   := '';
  county  := '';
  qsl     := '';
  ErrMsg  := '';
  if fQRZSession='' then
  begin
    if not GetQRZSession(ErrMsg) then
      exit
  end;
  http := THTTPSend.Create;
  m    := TStringList.Create;
  try
    http.ProxyHost := cqrini.ReadString('Program','Proxy','');
    http.ProxyPort := cqrini.ReadString('Program','Port','');
    http.UserName  := cqrini.ReadString('Program','User','');
    http.Password  := cqrini.ReadString('Program','Passwd','');
    if (call='') then
    begin
      ErrMsg := 'Callsign field empty!';
      exit
    end;
    req := 'http://xml.qrz.com/xml?s='+fQRZSession+';callsign='+GetIDCall(call);
    if not HTTP.HTTPMethod('GET', req) then
      ErrMsg := '('+IntToStr(http.ResultCode)+'):'+http.ResultString
    else begin
      m.LoadFromStream(http.Document);
      if Pos('<Error>Session Timeout</Error>',m.Text) > 0 then
      begin
        fQRZSession := '';
        Result := GetQRZInfo(call,nick,qth,address,zip,grid,state,county,qsl,iota,ErrMsg)
      end
      else begin
        if Pos('<Error>Not found:',m.Text) > 0 then
          exit;
        nick := GetTagValue(m.Text,'<fname>');
        if Pos(' ',nick) > 0 then
            nick := copy(nick,1,Pos(' ',nick)-1);
        if Length(nick) > 0 then
        begin
          nick    := LowerCase(nick);
          nick[1] := upCase(nick[1])
        end;
        qth     := GetTagValue(m.Text,'<addr2>');
        state   := GetTagValue(m.Text,'<state>');
        zip     := GetTagValue(m.Text,'<zip>');
        address := GetTagValue(m.Text,'<fname>')+' '+GetTagValue(m.Text,'<name>') + LineEnding+
                   GetTagValue(m.Text,'<addr1>')+LineEnding+GetTagValue(m.Text,'<addr2>')+' '+
                   zip+' ' + state;
        county  := GetTagValue(m.Text,'<county>');
        grid    := UpperCase(GetTagValue(m.Text,'<grid>'));
        qsl     := GetTagValue(m.Text,'<qslmgr>');
        iota    := GetTagValue(m.Text,'<iota>')
      end
    end
  finally
    m.Free;
    HTTP.Free
  end
end;

procedure TdmUtils.SaveWindowPos(a : TForm);
var
  section : String = '';
begin
  if dmData.DBName = '' then
    exit;
  if dmData.ContestMode then
    section := 'C_'+a.Name
  else
    section := a.Name;
  if a.WindowState = wsMaximized then
    cqrini.WriteBool(section,'Max',True)
  else begin
    cqrini.WriteInteger(section,'Height',a.Height);
    cqrini.WriteInteger(section,'Width',a.Width);
    cqrini.WriteInteger(section,'Top',a.Top);
    cqrini.WriteInteger(section,'Left',a.Left);
    cqrini.WriteBool(section,'Max',False)
  end;
  if dmData.DebugLevel >=1 then
  begin
    //Writeln('Section:',section);
    //Writeln('Saving window size a position (',a.Name,') (height|width|top|left):',
    //        a.height,'|',a.Width,'|',a.top,'|',a.left)
  end
end;

procedure TdmUtils.LoadWindowPos(a : TForm);
var
  section : String = '';
begin
  if dmData.ContestMode then
    section := 'C_'+a.Name
  else
    section := a.Name;
  LoadFontSettings(a);
  if cqrini.ReadBool(section,'Max',False) then
    a.WindowState := wsMaximized
  else begin
    if (a.BorderStyle <> bsDialog) then
    begin
      a.Height := cqrini.ReadInteger(section,'Height',a.Height);
      a.Width  := cqrini.ReadInteger(section,'Width',a.Width);
    end;
    a.Top    := cqrini.ReadInteger(section,'Top',20);
    a.Left   := cqrini.ReadInteger(section,'Left',20)
  end;
  if dmData.DebugLevel >=1 then
  begin
    //Writeln('Section:',section);
    //Writeln('Loading window size a position (',a.Name,') (height|width|top|left):',
    //        a.height,'|',a.Width,'|',a.top,'|',a.left)
  end
end;

function TdmUtils.GetCallForAttach(call : String) : String;
begin
  Result := LowerCase(StringReplace(call,'/','_',[rfReplaceAll, rfIgnoreCase]))
end;

function TdmUtils.GetCallAttachDir(call : String) : String;
begin
  call := GetCallForAttach(call);
  Result := dmData.HomeDir + 'call_data'+PathDelim+call
end;

function TdmUtils.GetHomeDirectory : String;
begin
  Result := GetAppConfigFile(False);
  Result := Copy(Result,1,Pos('/.',Result)-1);
  Result := AppendPathDelim(Result)
end;


function TdmUtils.FindInMailCap(mime : String) : String;
const
  READ_ONLY = 0;
  WRITE_ONLY = 1;
  READ_WRITE = 2;

var
  f  : Text;
  fm : Byte;
  tmp : String = '';
begin
  Result := '';
  if Length(mime)=0 then
    exit;
  fm := Filemode;
  try
    Filemode := READ_ONLY;
    if FileExists(GetHomeDirectory+'.mailcap') then
    begin
      AssignFile(f,GetHomeDirectory+'.mailcap');
      Reset(f);
      while not Eof(f) do
      begin
        ReadLn(f, tmp);
        if Pos(mime+';',tmp) = 1 then
        begin
          tmp := copy(tmp,Pos(';',tmp)+1,100);
          tmp := copy(tmp,1,Pos(#39,tmp)-1);
          Result := tmp;
          break
        end
      end;
      CloseFile(f)
    end;
    if Result <> '' then  //we find right application for our file
      exit;

    AssignFile(f,'/etc/mailcap');
    Reset(f);
    while not Eof(f) do
    begin
      ReadLn(f, tmp);
      if Pos(mime+';',tmp) = 1 then
      begin
        tmp := copy(tmp,Pos(';',tmp)+1,100);
        tmp := copy(tmp,1,Pos(#39,tmp)-1);
        Result := tmp;
        //break
        // we can't stop looking for rigth application. When user install e.g. abiword
        // it also takes palain/text mime type. So last installed app with this mime type
        // must be find. (The first one is console less command.
      end
    end;
    CloseFile(f)
  finally
    Filemode := fm
  end
end;


function TdmUtils.GetApplicationName(FileExt : String) : String;
const
  READ_ONLY = 0;
  WRITE_ONLY = 1;
  READ_WRITE = 2;

var
  f  : Text;
  fm : Byte;
  tmp : String = '';
  p  : Word;
begin
  Result := '';
  if Length(FileExt)=0 then
    exit;
  if FileExt[1] = '.' then
    FileExt := Copy(FileExt,2,Length(FileExt)-1);
  fm := Filemode;
  try
    Filemode := READ_ONLY;
    AssignFile(f,'/etc/mime.types');
    Reset(f);
    while not Eof(f) do
    begin
      ReadLn(f, tmp);
      p := Pos(#9,tmp);
      if p = 0 then
        p := Pos(' ',tmp);
      if p = 0 then
        Continue;
      if Pos(FileExt,trim(copy(tmp,p,100))) > 0 then
      begin //find file extension
        Result := copy(tmp,1,p-1);  //copying mime type of a file
        Break
      end
      else
        Continue  //we must process next line from file
    end;
    if Result = '' then
      exit;  //we couldn't find mime type of that file
    Result := trim(FindInMailCap(Result));
    //Writeln('Result: ',Result)
  finally
    CloseFile(f);
    Filemode := fm
  end
end;

function TdmUtils.QSLFrontImageExists(fCall : String) : String;
var
  s : String;
begin
  Result := '';
  s := GetCallAttachDir(fCall)+PathDelim+'qsl_'+fCall+'_front';
  if FileExists(s+'.png') then
    Result := s+'.png'
  else begin
    if FileExists(s+'.jpg') then
      Result := s+'.jpg'
  end
end;

function TdmUtils.QSLBackImageExists(fCall : String) : String;
var
  s : String;
begin
  Result := '';
  s := GetCallAttachDir(fCall)+PathDelim+'qsl_'+fCall+'_back';
  if FileExists(s+'.png') then
    Result := s+'.png'
  else begin
    if FileExists(s+'.jpg') then
      Result := s+'.jpg'
  end
end;

procedure TdmUtils.ShowQSLWithExtViewer(Call : String);
var
  dir : String;
  prg : String;
  qsl : String;
begin
  call := GetCallForAttach(call);
  qsl  := QSLFrontImageExists(call);
  if qsl = '' then
    exit;
  dir := GetCurrentDir;
  try
    SetCurrentDir(dmData.HomeDir + 'call_data'+PathDelim+call+PathDelim);
    prg := cqrini.ReadString('ExtView','img','eog');
    if prg = '' then
      dmUtils.RunOnBackgroud(cqrini.ReadString('Program', 'WebBrowser', 'firefox') +
                             ' ' + qsl)
    else
      dmUtils.RunOnBackgroud(prg + ' ' + qsl)
  finally
    SetCurrentDir(dir)
  end
end;

function TdmUtils.IsValidFileName(const fileName : string) : boolean;
const
  InvalidCharacters : set of char = ['\', '/', ':', '*', '?', '"', '<', '>', '|'];
var
  cnt : integer;
begin
  result := fileName <> '';
  if result then
  begin
    for cnt := 1 to Length(fileName) do
    begin
      result := not (fileName[cnt] in InvalidCharacters);
      if not result then
        break
    end
  end
end;

procedure TdmUtils.GetFileList(l : TListBox);
var
  res          : Byte;
  SearchRec    : TSearchRec;
begin
  l.Clear;
  l.Items.Add('[..]');
  //Writeln('GetFileList:',dmData.ContestDataDir);
  res := FindFirst(dmData.ContestDataDir+'*', faDirectory, SearchRec);
  while Res = 0 do
  begin
    //Writeln('SearchRec.Name:',SearchRec.Name);
    if (SearchRec.Name <> '.')  and (SearchRec.Name <> '') and (SearchRec.Name <> '..')
       and (DirectoryExistsUTF8(dmData.ContestDataDir+SearchRec.Name)) then
      l.Items.Add('['+SearchRec.Name+']');
    Res := FindNext(SearchRec)
  end;
  FindClose(SearchRec);
  res := FindFirst(dmData.ContestDataDir + '*.cqr', faAnyFile, SearchRec);
  while Res = 0 do
  begin
    l.Items.Add(SearchRec.Name);
    Res := FindNext(SearchRec)
  end;
  FindClose(SearchRec)
end;

procedure TdmUtils.GetDirectoryList(l : TListBox);
var
  res          : Byte;
  SearchRec    : TSearchRec;
begin
  l.Clear;
  res := FindFirst(dmData.ContestDataDir + '*', faDirectory, SearchRec);
  while Res = 0 do
  begin
    l.Items.Add(ExtractFileNameWithoutExt(SearchRec.Name));
    Res := FindNext(SearchRec)
  end;
  FindClose(SearchRec)
end;

procedure TdmUtils.InsertContestFreq(cmbFreq : TcomboBox;warc : Boolean);
begin
  cmbFreq.Clear;
  cmbFreq.Items.Add('1.800');
  cmbFreq.Items.Add('3.500');
  cmbFreq.Items.Add('7.000');
  if warc then
    cmbFreq.Items.Add('10.100');
  cmbFreq.Items.Add('14.000');
  if warc then
    cmbFreq.Items.Add('18.068');
  cmbFreq.Items.Add('21.000');
  if warc then
    cmbFreq.Items.Add('24.890');
  cmbFreq.Items.Add('28.000');
  cmbFreq.ItemIndex := 0
end;

procedure TdmUtils.ShowQRZInBrowser(call : String);
var
  AProcess: TProcess;
begin
  AProcess := TProcess.Create(nil);
  try
    AProcess.CommandLine := cqrini.ReadString('Program', 'WebBrowser', 'firefox') +
      ' http://www.qrz.com/db/' + GetIDCall(call);
    if dmData.DebugLevel>=1 then Writeln('Command line: ', AProcess.CommandLine);
    AProcess.Execute
  finally
    AProcess.Free
  end
end;

procedure TdmUtils.LoadBandsSettings;
var
  i : Integer;
begin
  LoadBandLabelSettins;
  for i:=0 to cMaxBandsCount-1 do
  begin
    MyBands[i][0] := '';
    MyBands[i][1] := ''
  end;

  i := 0;
  if cqrini.ReadBool('Bands','137kHz',false) then
  begin
    MyBands[i][0] := '2190M';
    MyBands[i][1] := s136;
    inc(i)
  end;
  if cqrini.ReadBool('Bands','160m',true) then
  begin
    MyBands[i][0] := '160M';
    MyBands[i][1] := s160;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','80m',true) then
  begin
    MyBands[i][0] := '80M';
    MyBands[i][1] := s80;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','60m',False) then
  begin
    MyBands[i][0] := '60M';
    MyBands[i][1] := s60;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','40m',true) then
  begin
    MyBands[i][0] := '40M';
    MyBands[i][1] := s40;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','30m',true) then
  begin
    MyBands[i][0] := '30M';
    MyBands[i][1] := s30;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','20m',true) then
  begin
    MyBands[i][0] := '20M';
    MyBands[i][1] := s20;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','17m',true) then
  begin
    MyBands[i][0] := '17M';
    MyBands[i][1] := s17;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','15m',true) then
  begin
    MyBands[i][0] := '15M';
    MyBands[i][1] := s15;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','12m',true) then
  begin
    MyBands[i][0] := '12M';
    MyBands[i][1] := s12;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','10m',true) then
  begin
    MyBands[i][0] := '10M';
    MyBands[i][1] := s10;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','6m',true) then
  begin
    MyBands[i][0] := '6M';
    MyBands[i][1] := s6;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','4m',False) then
  begin
    MyBands[i][0] := '4M';
    MyBands[i][1] := s4;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','1.25m',False) then
  begin
    MyBands[i][0] := '1.25M';
    MyBands[i][1] := s220;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','2m',true) then
  begin
    MyBands[i][0] := '2M';
    MyBands[i][1] := s2;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','70cm',true) then
  begin
    MyBands[i][0] := '70CM';
    MyBands[i][1] := s70;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','33cm',False) then
  begin
    MyBands[i][0] := '33CM';
    MyBands[i][1] := s900;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','23cm',false) then
  begin
    MyBands[i][0] := '23CM';
    MyBands[i][1] := s1260;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','13cm',false) then
  begin
    MyBands[i][0] := '13CM';
    MyBands[i][1] := s2300;
    inc(i)
  end;
  if cqrini.ReadBool('Bands','8cm',false) then
  begin
    MyBands[i][0] := '9CM';
    MyBands[i][1] := s3400;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','5cm',false) then
  begin
    MyBands[i][0] := '6CM';
    MyBands[i][1] := s5850;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','3cm',false) then
  begin
    MyBands[i][0] := '3CM';
    MyBands[i][1] := s10G;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','1cm',false) then
  begin
    MyBands[i][0] := '1.25CM';
    MyBands[i][1] := s24G;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','47GHz',false) then
  begin
    MyBands[i][0] := '6MM';
    MyBands[i][1] := s47G;
    inc(i)
  end;

  if cqrini.ReadBool('Bands','76GHz',false) then
  begin
    MyBands[i][0] := '4MM';
    MyBands[i][1] := s76G;
    inc(i)
  end
end;

function TdmUtils.GetBandPos(band : String) : Integer;
var
  i : Integer;
begin
  Result := -1;
  if band='' then
    exit;
  for i:=0 to cMaxBandsCount-1 do
  begin
    if band = MyBands[i][0] then
    begin
      Result := i;
      Break
    end
  end
end;

function TdmUtils.GetNewQSOCaption(capt : String) : String;
begin
  Result := capt + ' ... (CQRLOG for Linux)';
  if dmData.LogName <> '' then
    Result := Result + ', database: '+dmData.LogName
end;

procedure TdmUtils.FillBandCombo(cmb : TComboBox);
var
  i : Integer;
begin
  cmb.Clear;
  for i:=0 to Length(MyBands)-1 do
  begin
    if MyBands[i][0]='' then
      break;
    cmb.Items.Add(MyBands[i][0])
  end
end;

function TdmUtils.GetCallBookData(call : String; var nick,qth,address,zip,grid,state,county,qsl,iota,ErrMsg : String) : Boolean;
begin
  if cqrini.ReadBool('Callbook','QRZ',False) then
    Result := GetQRZInfo(call,nick,qth,address,zip,grid,state,county,qsl,iota,ErrMsg)
  else
    Result := GetHamQTHInfo(call,nick,qth,address,zip,grid,state,county,qsl,iota,ErrMsg)
end;

function TdmUtils.GetTagValue(data,tg : String) : String;
var
  EndTag : String;
  p      : Word;
begin
  Result := '';
  EndTag := '</'+copy(tg,2, Length(tg)-1);
  p := Pos(tg,data);
  if p > 0 then
  begin
    Result := copy(data,p+Length(tg),Pos(EndTag,data)-p-Length(tg));
    Result := Trim(Result);
    if dmData.DebugLevel >=1 then
    begin
      Writeln('Tag: ',tg,'    Value: ',Result)
    end
  end
end;


function TdmUtils.GetQRZSession(var ErrMsg : String) : Boolean;
var
  http     : THTTPSend;
  req      : String = '';
  m        : TStringList;
  epos     : Word;
  kpos     : Word;
begin
  Result := False;
  if (cqrini.ReadString('CallBook','CBUser','')='') or
     (cqrini.ReadString('CallBook','CBPass','')='') then
  begin
    ErrMsg := 'Empty password or user name';
    exit
  end;
  http := THTTPSend.Create;
  m    := TStringList.Create;
  try
    http.ProxyHost := cqrini.ReadString('Program','Proxy','');
    http.ProxyPort := cqrini.ReadString('Program','Port','');
    http.UserName  := cqrini.ReadString('Program','User','');
    http.Password  := cqrini.ReadString('Program','Passwd','');
    req := 'http://xmldata.qrz.com/xml/?username='+cqrini.ReadString('CallBook','CBUser','')+
           ';password='+cqrini.ReadString('CallBook','CBPass','')+';agent=cqrlog';
    if not HTTP.HTTPMethod('GET', req) then
      ErrMsg := '('+IntToStr(http.ResultCode)+'):'+http.ResultString
    else begin
      m.LoadFromStream(http.Document);
      if dmData.DebugLevel>=1 then Writeln(m.Text);
      //I'd like to parse it as normal XML but it seems XML support in Freepascal
      //2.4.0 is broken :-(
      epos := Pos('<Error>',m.Text);
      if epos > 0 then
        ErrMsg := copy(m.Text,epos+7,Pos('</Error>',m.Text)-epos-7)
      else begin
        kpos :=  Pos('<Key>',m.Text);
        if kpos > 0 then
        begin
          fQRZSession := copy(m.Text,kpos+5,Pos('</Key>',m.Text)-kpos-5);
          Result      := True
        end
        else
          ErrMsg := 'Tag "<Key>" not found!'
      end
    end
  finally
    m.Free;
    HTTP.Free
  end
end;

function TdmUtils.GetHamQTHSession(var ErrMsg : String) : Boolean;
var
  http     : THTTPSend;
  req      : String = '';
  m        : TStringList;
  epos     : Word;
  kpos     : Word;
begin
  Result := False;
  if (cqrini.ReadString('CallBook','CBUser','')='') or
     (cqrini.ReadString('CallBook','CBPass','')='') then
  begin
    ErrMsg := 'Empty password or user name';
    exit
  end;
  http := THTTPSend.Create;
  m    := TStringList.Create;
  try
    http.ProxyHost := cqrini.ReadString('Program','Proxy','');
    http.ProxyPort := cqrini.ReadString('Program','Port','');
    http.UserName  := cqrini.ReadString('Program','User','');
    http.Password  := cqrini.ReadString('Program','Passwd','');
    req := 'http://www.hamqth.com/xml.php?u='+cqrini.ReadString('CallBook','CBUser','')+
           '&p='+cqrini.ReadString('CallBook','CBPass','')+'&prg=cqrlog';
    //Writeln(req);
    if not HTTP.HTTPMethod('GET', req) then
      ErrMsg := '('+IntToStr(http.ResultCode)+'):'+http.ResultString
    else begin
      m.LoadFromStream(http.Document);
      if dmData.DebugLevel>=1 then Writeln(m.Text);
      //I'd like to parse it as normal XML but it seems XML support in Freepascal
      //2.4.0 is broken :-(
      ErrMsg := GetTagValue(m.Text,'<Error>');
      if (ErrMsg = '') then
      begin
        fHamQTHSession := GetTagValue(m.Text,'<session_id>');
        if fHamQTHSession = '' then
          ErrMsg := 'Tag "<session_id>" not found!'
        else
          Result := True
      end
    end
  finally
    m.Free;
    HTTP.Free
  end
end;

function TdmUtils.GetHamQTHInfo(call : String; var nick,qth,address,zip,grid,state,county,qsl,iota,ErrMsg : String) : Boolean;
var
  http : THTTPSend;
  req  : String = '';
  m    : TStringList;
  tmp  : String;
begin
  Result  := False;
  address := '';
  grid    := '';
  state   := '';
  county  := '';
  qsl     := '';
  ErrMsg  := '';
  if fHamQTHSession='' then
  begin
    if not GetHamQTHSession(ErrMsg) then
      exit
  end;
  http := THTTPSend.Create;
  m    := TStringList.Create;
  try
    http.ProxyHost := cqrini.ReadString('Program','Proxy','');
    http.ProxyPort := cqrini.ReadString('Program','Port','');
    http.UserName  := cqrini.ReadString('Program','User','');
    http.Password  := cqrini.ReadString('Program','Passwd','');
    if (call='') then
    begin
      ErrMsg := 'Callsign field empty!';
      exit
    end;
    req := 'http://www.hamqth.com/xml.php?id='+fHamQTHSession+'&callsign='+GetIDCall(call)+
           '&prg=CQRLOG';
    if not HTTP.HTTPMethod('GET', req) then
      ErrMsg := '('+IntToStr(http.ResultCode)+'):'+http.ResultString
    else begin
      m.LoadFromStream(http.Document);
      if dmData.DebugLevel>=1 then Writeln(m.Text);
      if Pos('<error>Session does not exist or expired</error>',m.Text) > 0 then
      begin
        fHamQTHSession := '';
        Result := GetHamQTHInfo(call,nick,qth,address,zip,grid,state,county,qsl,iota,ErrMsg)
      end
      else begin
        if Pos('<error>Callsign not found',m.Text) > 0 then
        begin
          ErrMsg := 'Callsign not found';
          exit
        end;
        nick := GetTagValue(m.Text,'<nick>');
        if Pos(' ',nick) > 0 then
            nick := copy(nick,1,Pos(' ',nick)-1);
        if Length(nick) > 0 then
        begin
          nick    := LowerCase(nick);
          nick[1] := upCase(nick[1])
        end;
        qth     := GetTagValue(m.Text,'<qth>');
        state   := GetTagValue(m.Text,'<us_state>');
        zip     := GetTagValue(m.Text,'<adr_zip>');
        address := GetTagValue(m.Text,'<adr_name>')+LineEnding+
                   GetTagValue(m.Text,'<adr_street1>')+LineEnding;
        tmp := GetTagValue(m.Text,'<adr_street2>');
        if tmp <> '' then
          address := address+tmp+LineEnding;
        tmp := GetTagValue(m.Text,'<adr_street3>');
        if tmp <> '' then
          address := address+tmp+LineEnding;
        address := address + GetTagValue(m.Text,'<adr_city>') + ' ' + zip + ' ' + state;
        county  := GetTagValue(m.Text,'<us_county>');
        grid    := UpperCase(GetTagValue(m.Text,'<grid>'));
        qsl     := GetTagValue(m.Text,'<qsl_via>');
        iota    := GetTagValue(m.Text,'<iota>')
      end
    end
  finally
    m.Free;
    HTTP.Free
  end
end;

procedure TdmUtils.ShowHamQTHInBrowser(call : String);
var
  AProcess: TProcess;
begin
  AProcess := TProcess.Create(nil);
  try
    AProcess.CommandLine := cqrini.ReadString('Program', 'WebBrowser', 'firefox') +
      ' http://www.hamqth.com/' + GetIDCall(call);
    if dmData.DebugLevel>=1 then Writeln('Command line: ', AProcess.CommandLine);
    AProcess.Execute
  finally
    AProcess.Free
  end
end;

function TdmUtils.DateInSOTAFormat(date : TDateTime) : String;
var
  Sep    : Char;
begin
  sep := DateSeparator;
  try
    DateSeparator := '/';
    Result := FormatDateTime('DD/MM/YY', date)
  finally
    DateSeparator := sep
  end
end;

function TdmUtils.GetLocalUTCDelta : Double;
begin
  Result := (now - GetDateTime(0))*24 //in hours
end;

procedure TdmUtils.SortArray(l,r : Integer);
var
  i,j : integer;
  x : String;
  w : String;
begin
  i := l;
  j := r;
  x := dmData.eQSLUsers[(l+r) div 2];
  repeat
    while dmData.eQSLUsers[i] < x do i := i+1;
    while x < dmData.eQSLUsers[j] do j := j-1;

    if i <= j then
    begin
      w    := dmData.eQSLUsers[i];
      dmData.eQSLUsers[i] := dmData.eQSLUsers[j];
      dmData.eQSLUsers[j] := w;
      i := i+1;
      j := j-1
    end
  until i > j;
  if l < j then SortArray(l,j);
  if i < r then SortArray(i,r)
end;


function TdmUtils.GetRadioRigCtldCommandLine(radio : Word) : String;
var
  section  : ShortString='';
  arg      : String='';
  set_conf : String = '';
begin
  section := 'TRX'+IntToStr(radio);

  if cqrini.ReadString(section,'model','') = '' then
  begin
    Result := '';
    exit
  end;

  Result := '-m '+ cqrini.ReadString(section,'model','') + ' ' +
            '-r '+ cqrini.ReadString(section,'device','') + ' ' +
            '-t '+ cqrini.ReadString(section,'RigCtldPort','4532') + ' ';
  Result := Result + cqrini.ReadString(section,'ExtraRigCtldArgs','') + ' ';

  case cqrini.ReadInteger(section,'SerialSpeed',0) of
    0 : arg := '';
    1 : arg := '-s 1200 ';
    2 : arg := '-s 2400 ';
    3 : arg := '-s 4800 ';
    4 : arg := '-s 9600 ';
    5 : arg := '-s 144000 ';
    6 : arg := '-s 19200 ';
    7 : arg := '-s 38400 ';
    8 : arg := '-s 57600 ';
    9 : arg := '-s 115200 '
    else
      arg := ''
  end; //case
  Result := Result + arg;

  case cqrini.ReadInteger(section,'DataBits',0) of
    0 : arg := '';
    1 : arg := 'data_bits=5';
    2 : arg := 'data_bits=6';
    3 : arg := 'data_bits=7';
    4 : arg := 'data_bits=8';
    5 : arg := 'data_bits=9'
    else
      arg := ''
  end; //case
  if arg<>'' then
    set_conf := set_conf+arg+',';

  if cqrini.ReadInteger(section,'StopBits',0) > 0 then
    set_conf := set_conf+'stop_bits='+IntToStr(cqrini.ReadInteger(section,'StopBits',0)-1)+',';

  case cqrini.ReadInteger(section,'Parity',0) of
    0 : arg := '';
    1 : arg := 'parity=None';
    2 : arg := 'parity=Odd';
    3 : arg := 'parity=Even';
    4 : arg := 'parity=Mark';
    5 : arg := 'parity=Space'
    else
      arg := ''
  end; //case
  if arg<>'' then
    set_conf := set_conf+arg+',';

  case cqrini.ReadInteger(section,'HandShake',0) of
    0 : arg := '';
    1 : arg := 'serial_handshake=None';
    2 : arg := 'serial_handshake=XONXOFF';
    3 : arg := 'serial_handshake=Hardware';
    else
      arg := ''
  end; //case
  if arg<>'' then
    set_conf := set_conf+arg+',';

  case cqrini.ReadInteger(section,'DTR',0) of
    0 : arg := '';
    1 : arg := 'dtr_state=Unset';
    2 : arg := 'dtr_state=ON';
    3 : arg := 'dtr_state=OFF';
    else
      arg := ''
  end; //case
  if arg<>'' then
    set_conf := set_conf+arg+',';

  case cqrini.ReadInteger(section,'RTS',0) of
    0 : arg := '';
    1 : arg := 'rts_state=Unset';
    2 : arg := 'rts_state=ON';
    3 : arg := 'rts_state=OFF';
    else
      arg := ''
  end; //case
  if arg<>'' then
    set_conf := set_conf+arg+',';

  if (set_conf<>'') then
  begin
    set_conf := copy(set_conf,1,Length(set_conf)-1);
    Result   := Result + ' --set-conf='+set_conf
  end
end;

function TdmUtils.GetRotorRotCtldCommandLine(rotor : Word) : String;
var
  section  : ShortString='';
  arg      : String='';
  set_conf : String = '';
begin
  section := 'ROT'+IntToStr(rotor);

  if cqrini.ReadString(section,'model','') = '' then
  begin
    Result := '';
    exit
  end;

  Result := '-m '+ cqrini.ReadString(section,'model','') + ' ' +
            '-r '+ cqrini.ReadString(section,'device','') + ' ' +
            '-t '+ cqrini.ReadString(section,'RotCtldPort','4533') + ' ';
  Result := Result + cqrini.ReadString(section,'ExtraRotCtldArgs','') + ' ';

  case cqrini.ReadInteger(section,'SerialSpeed',0) of
    0 : arg := '';
    1 : arg := '-s 1200 ';
    2 : arg := '-s 2400 ';
    3 : arg := '-s 4800 ';
    4 : arg := '-s 9600 ';
    5 : arg := '-s 144000 ';
    6 : arg := '-s 19200 ';
    7 : arg := '-s 38400 ';
    8 : arg := '-s 57600 ';
    9 : arg := '-s 115200 '
    else
      arg := ''
  end; //case
  Result := Result + arg;

  case cqrini.ReadInteger(section,'DataBits',0) of
    0 : arg := '';
    1 : arg := 'data_bits=5';
    2 : arg := 'data_bits=6';
    3 : arg := 'data_bits=7';
    4 : arg := 'data_bits=8';
    5 : arg := 'data_bits=9'
    else
      arg := ''
  end; //case
  if arg<>'' then
    set_conf := set_conf+arg+',';

  if cqrini.ReadInteger(section,'StopBits',0) > 0 then
    set_conf := set_conf+'stop_bits='+IntToStr(cqrini.ReadInteger(section,'StopBits',0)-1)+',';

  case cqrini.ReadInteger(section,'Parity',0) of
    0 : arg := '';
    1 : arg := 'parity=None';
    2 : arg := 'parity=Odd';
    3 : arg := 'parity=Even';
    4 : arg := 'parity=Mark';
    5 : arg := 'parity=Space'
    else
      arg := ''
  end; //case
  if arg<>'' then
    set_conf := set_conf+arg+',';

  case cqrini.ReadInteger(section,'HandShake',0) of
    0 : arg := '';
    1 : arg := 'serial_handshake=None';
    2 : arg := 'serial_handshake=XONXOFF';
    3 : arg := 'serial_handshake=Hardware';
    else
      arg := ''
  end; //case
  if arg<>'' then
    set_conf := set_conf+arg+',';

  case cqrini.ReadInteger(section,'DTR',0) of
    0 : arg := '';
    1 : arg := 'dtr_state=Unset';
    2 : arg := 'dtr_state=ON';
    3 : arg := 'dtr_state=OFF';
    else
      arg := ''
  end; //case
  if arg<>'' then
    set_conf := set_conf+arg+',';

  case cqrini.ReadInteger(section,'RTS',0) of
    0 : arg := '';
    1 : arg := 'rts_state=Unset';
    2 : arg := 'rts_state=ON';
    3 : arg := 'rts_state=OFF';
    else
      arg := ''
  end; //case
  if arg<>'' then
    set_conf := set_conf+arg+',';

  if (set_conf<>'') then
  begin
    set_conf := copy(set_conf,1,Length(set_conf)-1);
    Result   := Result + ' --set-conf='+set_conf
  end
end;

function TdmUtils.IgnoreFreq(kHz : String) : Boolean;
var
  i : Integer;
begin
  kHz := trim(kHz);
  Result := False;
  for i:=0 to cMaxIgnoreFreq do
  begin
    if (kHz = cIngnoreFreq[i]) then
    begin
      Result := True;
      break
    end
  end
end;

function TdmUtils.HTMLEncode(const Data: string): string;
var
  i: Integer;
begin
  result := '';
  for i := 1 to length(Data) do
  begin
    case Data[i] of
      '<': result := result + '&lt;';
      '>': result := result + '&gt;';
      '&': result := result + '&amp;';
      '"': result := result + '&quot;'
    else
      result := result + Data[i]
    end
  end
end;


procedure TdmUtils.OpenInApp(what : String);
begin
  RunOnBackgroud('xdg-open '+what)
end;

initialization
  {$I dUtils.lrs}


end.

