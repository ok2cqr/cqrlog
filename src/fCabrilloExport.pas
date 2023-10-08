
unit fCabrilloExport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, LCLType, Buttons, LazFileUtils, StrUtils, inifiles;


const
  cMaxExch = 32;  //cExhanges array Max size
  cExhanges: array[0..32] of string[11] =
    ('',
    'stx', 'srx', 'stx_string', 'srx_string', 'itu', 'waz', 'loc', 'my_loc', 'iota', 'state',
    'dok', 'county', 'name', 'my_name','qth', 'remarks', 'cont', 'pwr', 'freq', 'band',
    'mode', 'prop_mode', 'satellite', 'qsodate', 'time_on', 'time_off', 'award', 'qso_dxcc', 'profile', 'idcall',
    'rxfreq', 'contestname');

type

  { TfrmCabrilloExport }

  TfrmCabrilloExport = class(TForm)
    btnCabFrmFlt: TButton;
    btnCabClose: TButton;
    btnCabExport: TButton;
    btnCabHelp: TSpeedButton;
    btnCabBrowse: TButton;
    btCabSave: TButton;
    btCabLoad: TButton;
    btnResultFile: TButton;
    chkUpCase: TCheckBox;
    chkCabInfoSrst: TCheckBox;
    chkCabInfoRrst: TCheckBox;
    cmbCabInfoREx1: TComboBox;
    cmbCabInfoREx2: TComboBox;
    cmbCabPower: TComboBox;
    cmbCabContestName: TComboBox;
    cmbCabInfoSEx1: TComboBox;
    cmbCabInfoSEx2: TComboBox;
    cmbCabTailTxCount: TComboBox;
    dlgCabSave: TSaveDialog;
    edtCabCountC: TEdit;
    edtCabCallWdt: TEdit;
    edtCabInfoREx1Wdt: TEdit;
    edtCabInfoRrstWdt: TEdit;
    edtCabInfoSrstWdt: TEdit;
    edtCabLocation: TEdit;
    edtCabInfoREx2Wdt: TEdit;
    edtCabInfoSEx1Wdt: TEdit;
    edtCabInfoSEx2Wdt: TEdit;
    edtCabFileName: TEdit;
    edtCabSoapBox: TEdit;
    gbCabInfoRcvd: TGroupBox;
    gbCabInfoSent: TGroupBox;
    gbCabQsoHeader: TGroupBox;
    gbCabQsoTail: TGroupBox;
    gbCabLayout: TGroupBox;
    gbCabCoCount: TGroupBox;
    lblCabInfoRrst: TLabel;
    lblCabInfoSrst: TLabel;
    lblCabQsoHeader1: TLabel;
    lblCabSoapBox: TLabel;
    lblCabQsoHeader: TLabel;
    lblCabQsoTail: TLabel;
    lblCabSEx1Cmb: TLabel;
    lblCabSrxCmb: TLabel;
    lblCabSEx2Cmb: TLabel;
    lblCabfileName: TLabel;
    lblCabStats: TLabel;
    lblCabLocation: TLabel;
    lblCabPower: TLabel;
    lblCabError: TLabel;
    lblCabContestName: TLabel;
    lblCabDone: TLabel;
    lblCabSrxStCmb: TLabel;
    dlgCabOpen: TOpenDialog;
    mCabStatistics: TMemo;
    pbCabExport: TProgressBar;
    procedure btCabLoadClick(Sender: TObject);
    procedure btCabSaveClick(Sender: TObject);
    procedure btnCabExportClick(Sender: TObject);
    procedure btnCabBrowseClick(Sender: TObject);
    procedure btnCabFrmFltClick(Sender: TObject);
    procedure btnCabHelpClick(Sender: TObject);
    procedure btnResultFileClick(Sender: TObject);
    procedure cmbCabContestNameChange(Sender: TObject);
    procedure cmbCabContestNameExit(Sender: TObject);
    procedure edtCabCallWdtExit(Sender: TObject);
    procedure edtCabInfoREx2WdtExit(Sender: TObject);
    procedure edtCabInfoREx1WdtExit(Sender: TObject);
    procedure edtCabInfoRrstWdtExit(Sender: TObject);
    procedure edtCabInfoSEx2WdtExit(Sender: TObject);
    procedure edtCabInfoSEx1WdtExit(Sender: TObject);
    procedure edtCabCountCExit(Sender: TObject);
    procedure edtCabInfoSrstWdtExit(Sender: TObject);
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender : TObject);
    procedure lblCabErrorClick(Sender: TObject);
  private
    procedure SaveSettings;
    function NonZero(s:String):String;
    function CabrilloMode(mode : String) : String;
    function CabrilloBandToFreq(band : String) : String;
    function CabrilloPower(power: integer): String;
    procedure saveCabLay(filename:string);
    procedure loadCabLay(filename:string);
    procedure ViewFile(f:string);
  public
    { public declarations }
  end;

var
  frmCabrilloExport : TfrmCabrilloExport;
  CountryToCount    : integer = 0;

implementation
{$R *.lfm}

uses dData,dUtils,dDXCC,fWorkedGrids, uMyIni;

{ TfrmCabrilloExport }

procedure TfrmCabrilloExport.FormShow(Sender : TObject);
begin
  dmUtils.LoadWindowPos(self);
  lblCabError.Visible := False;
  edtCabFileName.Text  := cqrini.ReadString('CabrilloExport','FileName','');
  if edtCabFileName.Text='' then
    dlgCabSave.InitialDir := dmData.UsrHomeDir
  else
    dlgCabSave.InitialDir := ExtractFilePath(edtCabFileName.Text);
  cmbCabContestName.Text := cqrini.ReadString('CabrilloExport','ContestName','');

  cmbCabPower.ItemIndex:= cqrini.ReadInteger('CabrilloExport','Power',0);
  edtCabLocation.Text:= cqrini.ReadString('CabrilloExport','Location','');
  edtCabSoapBox.Text:= cqrini.ReadString('CabrilloExport','SoapBox','');
  edtCabCallWdt.Text:= cqrini.ReadString('CabrilloExport','CallsWidth', '13');

  chkCabInfoSrst.Checked:= cqrini.ReadBool('CabrilloExport','incRSTs',True);
  edtCabInfoSrstWdt.Text := cqrini.ReadString('CabrilloExport','SRSTWidth', '3');
  cmbCabInfoSEx1.ItemIndex:= cqrini.ReadInteger('CabrilloExport','StxOrder',0);
  edtCabInfoSEx1Wdt.Text:= cqrini.ReadString('CabrilloExport','StxWidth','6');
  cmbCabInfoSEx2.ItemIndex := cqrini.ReadInteger('CabrilloExport','StxStringOrder',0);
  edtCabInfoSEx2Wdt.Text := cqrini.ReadString('CabrilloExport','StxStringWidth', '6');

  chkCabInfoRrst.Checked:= cqrini.ReadBool('CabrilloExport','incRSTr',True);
  edtCabInfoRrstWdt.Text := cqrini.ReadString('CabrilloExport','RRSTWidth', '3');
  cmbCabInfoREx1.ItemIndex:= cqrini.ReadInteger('CabrilloExport','SrxOrder',0);
  edtCabInfoREx1Wdt.Text:= cqrini.ReadString('CabrilloExport','SrxWidth','6');
  cmbCabInfoREx2.ItemIndex := cqrini.ReadInteger('CabrilloExport','SrxStringOrder',0);
  edtCabInfoREx2Wdt.Text := cqrini.ReadString('CabrilloExport','SrxStringWidth', '6');
  cmbCabTailTxCount.ItemIndex := cqrini.ReadInteger('CabrilloExport','TxCount',0);

  CountryToCount:= cqrini.ReadInteger('CabrilloExport','CountryToCount',0);
  if ( CountryToCount > 0) then  edtCabCountC.Text:= dmDXCC.PfxFromADIF(CountryToCount);

  lblCabStats.Visible := False;
  mCabStatistics.Visible:=False;
  btnResultFile.Visible:=False;
end;

procedure TfrmCabrilloExport.ViewFile(f:string);
var
  prg: string;
begin
  try
    prg := cqrini.ReadString('ExtView', 'txt', '');
    if prg<>'' then
      dmUtils.RunOnBackground(prg + ' ' + AnsiQuotedStr(f, '"'))
     else ShowMessage('No external text viewer defined!'+#10+'See: prefrences/External viewers');
  finally
   //done
  end;

end;

procedure TfrmCabrilloExport.lblCabErrorClick(Sender: TObject);
begin
  if  lblCabError.Font.Color = clRed then
    Begin
      ViewFile('/tmp/CabrilloReject.log');
    end;
end;

procedure TfrmCabrilloExport.SaveSettings;
begin
  cqrini.WriteString('CabrilloExport','FileName',edtCabFileName.Text);
  cqrini.WriteString('CabrilloExport','ContestName',cmbCabContestName.Text);
  cqrini.WriteInteger('CabrilloExport','Power',cmbCabPower.ItemIndex);
  cqrini.WriteString('CabrilloExport','Location',edtCabLocation.Text);
  cqrini.WriteString('CabrilloExport','SoapBox',edtCabSoapBox.Text);
  cqrini.WriteString('CabrilloExport','CallsWidth', edtCabCallWdt.Text);

  cqrini.WriteBool('CabrilloExport','incRSTs',chkCabInfoSrst.Checked);
  cqrini.WriteString('CabrilloExport','SRSTWidth', edtCabInfoSrstWdt.Text);
  cqrini.WriteInteger('CabrilloExport','StxOrder',cmbCabInfoSEx1.ItemIndex);
  cqrini.WriteString('CabrilloExport','StxWidth', edtCabInfoSEx1Wdt.Text);
  cqrini.WriteInteger('CabrilloExport','StxStringOrder',cmbCabInfoSEx2.ItemIndex);
  cqrini.WriteString('CabrilloExport','StxStringWidth', edtCabInfoSEx2Wdt.Text);

  cqrini.WriteBool('CabrilloExport','incRSTr',chkCabInfoRrst.Checked);
  cqrini.WriteString('CabrilloExport','RRSTWidth', edtCabInfoRrstWdt.Text);
  cqrini.WriteInteger('CabrilloExport','SrxOrder',cmbCabInfoREx1.ItemIndex);
  cqrini.WriteString('CabrilloExport','SrxWidth', edtCabInfoREx1Wdt.Text);
  cqrini.WriteInteger('CabrilloExport','SrxStringOrder',cmbCabInfoREx2.ItemIndex);
  cqrini.WriteString('CabrilloExport','SrxStringWidth', edtCabInfoREx2Wdt.Text);

  cqrini.WriteInteger('CabrilloExport','TxCount',cmbCabTailTxCount.ItemIndex);
  cqrini.WriteInteger('CabrilloExport','CountryToCount',CountryToCount);

  lblCabStats.Visible := False;
  mCabStatistics.Visible:=False;
end;

function TfrmCabrilloExport.CabrilloMode(mode: string): String;
//2022-05-05 OH1KH It seems that Cabrilllo mode can be CqrMode (mainly CW,SSB,AM,FM,RTTY)(I.E. no mode+submode pairs needed)
//otherwise use dmUtils.ModeFromCqr to get mode and submode at this function
begin
  Result := '';
  case mode of
    'SSB':  Result := 'PH';
    'CW':   Result := 'CW';
    'AM':   Result := 'PH';
    'FM':   Result := 'PH';
    'RTTY': Result := 'RY';
    else                     //remaining modes are digital (mostly)
      Result := 'DG';
  end;
end;

function TfrmCabrilloExport.CabrilloBandToFreq(band: string): String;
begin
  case band of
    '160M':     Result := '1800';
     '80M':     Result := '3500';
     '40M':     Result := '7000';
     '20M':     Result := '14000';
     '15M':     Result := '21000';
     '10M':     Result := '28000';
      '6M':     Result := '50';
      '4M':     Result := '70';
      '2M':     Result := '144';
    '70CM':     Result := '432';
    '23CM':     Result := '1.2G';
    '13CM':     Result := '2.3G';
     '9CM':     Result := '3.4G';
     '6CM':     Result := '5.7G';
     '3CM':     Result := '10G';
  '1.25CM':     Result := '24G';
     '6MM':     Result := '47G';
     '4MM':     Result := '75G';
     '2.5MM':   Result := '122G';
     '2MM':     Result := '134G';
     '1MM':     Result := '241G';
    else
     Result := '';
  end; //case
end;

function TfrmCabrilloExport.CabrilloPower(power: integer): String;
begin
  Result := 'HIGH';
  case power of
    0: Result := 'HIGH';
    1: Result := 'LOW';
    2: Result := 'QRP';
  end;
end;

procedure TfrmCabrilloExport.FormClose(Sender : TObject;
  var CloseAction : TCloseAction);
begin
  SaveSettings;
  dmUtils.SaveWindowPos(self)
end;

procedure TfrmCabrilloExport.FormCreate(Sender: TObject);
var i:integer;
begin
  dmUtils.LoadWindowPos(self);
  dmUtils.LoadFontSettings(self);
  dmUtils.InsertContests(cmbCabContestName);
  cmbCabInfoSEx1.Items.Clear;
  cmbCabInfoSEx2.Items.Clear;
  cmbCabInfoREx1.Items.Clear;
  cmbCabInfoREx2.Items.Clear;
  for i:=0 to cMaxExch do //cExhanges array Max size
    Begin
      cmbCabInfoSEx1.Items.Add(cExhanges[i]);
      cmbCabInfoSEx2.Items.Add(cExhanges[i]);
      cmbCabInfoREx1.Items.Add(cExhanges[i]);
      cmbCabInfoREx2.Items.Add(cExhanges[i]);
    end;
end;

procedure TfrmCabrilloExport.btnCabBrowseClick(Sender : TObject);
begin
  dlgCabSave.InitialDir:=dmData.UsrHomeDir;
  dlgCabSave.DefaultExt:='.cbr';
  if dlgCabSave.Execute then
    edtCabFileName.Text := dlgCabSave.FileName
end;

procedure TfrmCabrilloExport.btnCabFrmFltClick(Sender: TObject);
begin
if not dmData.IsFilter then
  begin
      Application.MessageBox('You must first use Contest Filter for qsos to export!','Error ...',mb_OK+mb_IconError);
      exit
  end;
  cmbCabContestName.Text:='';
  dmData.qCQRLOG.First;
    while not dmData.qCQRLOG.eof do
    begin
      if (cmbCabContestName.Text='') then //set contest name from filtered qosos
       Begin
         if (dmData.qCQRLOG.FieldByName('contestname').AsString <> '') then
          cmbCabContestName.Text:=dmData.qCQRLOG.FieldByName('contestname').AsString;
       end
      else
       Begin  //if there are different contest names in filtered qsos put "?" instead
         if ((cmbCabContestName.Text<>dmData.qCQRLOG.FieldByName('contestname').AsString)
          and (dmData.qCQRLOG.FieldByName('contestname').AsString <> '')) then
             cmbCabContestName.Text:='eh? Check filter results!';
       end;
     dmData.qCQRLOG.Next;
    end;
end;

procedure TfrmCabrilloExport.btnCabHelpClick(Sender: TObject);
begin
  ShowHelp;
end;

procedure TfrmCabrilloExport.btnResultFileClick(Sender: TObject);
Begin
  ViewFile(edtCabFileName.Text);
end;

procedure TfrmCabrilloExport.cmbCabContestNameChange(Sender: TObject);
  var i:    integer;
    s:    string;
begin
  if cmbCabContestName.Text<>'' then
   begin
     if pos('|', cmbCabContestName.Text)>1 then   //list selected item
     cmbCabContestName.Text := ExtractWord(1,cmbCabContestName.Text,['|']);
     s:= '';
     for i:=1 to length(cmbCabContestName.Text) do
       begin
         case cmbCabContestName.Text[i] of
           'A'..'Z' : s:=s+ cmbCabContestName.Text[i];
           '0'..'9' : s:=s+ cmbCabContestName.Text[i];
                '-' : s:=s+ cmbCabContestName.Text[i];
        end;
       end;
     cmbCabContestName.Text:=s;
     cmbCabContestName.SelStart := Length(cmbCabContestName.Text);
   end;
end;

procedure TfrmCabrilloExport.cmbCabContestNameExit(Sender: TObject);
begin
  if pos('|', cmbCabContestName.Text)>1 then   //list selected item
     cmbCabContestName.Text := ExtractWord(1,cmbCabContestName.Text,['|']);
end;

procedure TfrmCabrilloExport.edtCabCallWdtExit(Sender: TObject);
begin
  edtCabCallWdt.Text:=NonZero(edtCabCallWdt.Text);
end;


procedure TfrmCabrilloExport.edtCabInfoSEx1WdtExit(Sender: TObject);
begin
    edtCabInfoSEx1Wdt.Text :=NonZero( edtCabInfoSEx1Wdt.Text);
end;

procedure TfrmCabrilloExport.edtCabCountCExit(Sender: TObject);
var
  adif       : Word;
  date       : TDateTime;
  cont, WAZ, posun, ITU, lat, long, pfx, country: string;
Begin
  date := dmUtils.GetDateTime(0);
  if dmDXCC.IsPrefix(edtCabCountC.Text,Date) then
   Begin
      cont := '';WAZ := '';posun := '';ITU := '';lat := '';long := '';
      adif:=dmDXCC.id_country(edtCabCountC.Text,date,pfx,country,cont,itu,waz,posun,lat,long);
      edtCabCountC.Text:= dmDXCC.PfxFromADIF(adif);
      CountryToCount:= adif;
   end
   else
    begin
      edtCabCountC.Text:='';
      CountryToCount:= 0;
     end
end;

procedure TfrmCabrilloExport.edtCabInfoSrstWdtExit(Sender: TObject);
begin
  edtCabInfoSrstWdt.Text:=NonZero(edtCabInfoSrstWdt.Text);
end;

procedure TfrmCabrilloExport.edtCabInfoSEx2WdtExit(Sender: TObject);
begin
  edtCabInfoSEx2Wdt.Text:=NonZero(edtCabInfoSEx2Wdt.Text);
end;

procedure TfrmCabrilloExport.edtCabInfoREx1WdtExit(Sender: TObject);
begin
 edtCabInfoREx1Wdt.Text:=NonZero(edtCabInfoREx1Wdt.Text);
end;

procedure TfrmCabrilloExport.edtCabInfoRrstWdtExit(Sender: TObject);
begin
  edtCabInfoRrstWdt.Text:=NonZero(edtCabInfoRrstWdt.Text);
end;

procedure TfrmCabrilloExport.edtCabInfoREx2WdtExit(Sender: TObject);
begin
 edtCabInfoREx2Wdt.Text:=NonZero(edtCabInfoREx2Wdt.Text);
end;

function TfrmCabrilloExport.NonZero(s:String):String;
var i:integer;
begin
    TryStrToInt(s,i);
    if (i=0) then s:='1';
    Result:=s;
end;

procedure TfrmCabrilloExport.btnCabExportClick(Sender: TObject);
type
   EachContinent=Record
        Name, WkdPfxs: String;
        QsoCount: Integer;
 end;
var
  f,r        : TextFile;
  RejectQso  : boolean;
  tmp        : String;
  mycall,call,
  myloc, loc,
  mycountry  : String;
  myname     : String;
  mailingaddress, zipcity : String;
  email      : String;
  club       : String;
  adif       : Word;
  i          : Integer = 0;
  j          : Integer = 0;
  s          : TStringList;
  Date       : TDateTime;
  cont, WAZ, posun, ITU, lat, long, pfx, country: string;
  category_band: String;
  category_mode: String;
  address: String;
  Operators : TStringList;
  OpString : String;

  UsrCountryCount       : integer = 0;
  TotalCountryList      : TStringList;

  Continents: array[ 0 .. 6 ] of EachContinent = (
              (name: 'NA'; WkdPfxs: ''; QsoCount: 0),
              (name: 'SA'; WkdPfxs: ''; QsoCount: 0),
              (name: 'OC'; WkdPfxs: ''; QsoCount: 0),
              (name: 'AS'; WkdPfxs: ''; QsoCount: 0),
              (name: 'EU'; WkdPfxs: ''; QsoCount: 0),
              (name: 'AF'; WkdPfxs: ''; QsoCount: 0),
              (name: 'Locator'; WkdPfxs: ''; QsoCount: 0) //nice place for this :-)
              );


begin
  lblCabError.Visible := False;
  btnResultFile.Visible:=False;
  SaveSettings;
  date := dmUtils.GetDateTime(0);
  mycall := cqrini.ReadString('Station','Call','');
  cont := '';WAZ := '';posun := '';ITU := '';lat := '';long := '';
  mycountry := dmDXCC.GetCountry(mycall, date);
  myloc  := cqrini.ReadString('Station','LOC','');
  if length(myloc) = 4 then myloc := myloc +'ll';
  myname := cqrini.ReadString('Station','Name','');
  mailingaddress := cqrini.ReadString('Station','MailingAddress','');

  address :=  cqrini.ReadString('Station','ZipCity','');
  zipcity := trim(ExtractDelimited(1,address,[' ']));
  address := trim(copy(address,length(zipcity)+1,length(address)));

  email := cqrini.ReadString('Station','Email','');
  club := cqrini.ReadString('Station','Club','');
  Operators := TStringList.Create;
  OpString := '';

  if (( mailingaddress ='') or (zipcity='') or (email='')) then
   begin
      Application.MessageBox('You should fill Preferences/Station/Contest info.'+LineEnding+
                             'MailAddr,Zip and eMail should have content!'+LineEnding+
                             '(at least "-")','Error ...',mb_OK+mb_IconError);
      exit
   end;
  if not dmData.IsFilter then
  begin
      Application.MessageBox('You must first use filter for qsos to export!','Error ...',mb_OK+mb_IconError);
      exit
  end;

  if FileExistsUTF8(edtCabFileName.Text) then
  begin
    if Application.MessageBox('File already exists,overwrite it?','Question ...',mb_YesNo
                              +mb_IconQuestion)=mrYes then
      DeleteFileUTF8(edtCabFileName.Text)
    else
      exit;
    Application.ProcessMessages;   //closes hanging message box with QT5
    sleep(10);                     //sleep and
    Application.ProcessMessages;   //second time is needed for GTK2 to work same way
  end;
  if (trim(edtCabFileName.Text)='') then
  begin
    Application.MessageBox('You must choose file to export!','Error ...',mb_OK+mb_IconError);
    exit
  end;
  pbCabExport.Position := 0;
  lblCabDone.Visible   := False;
  pbCabExport.Visible  := True;

  TotalCountryList := TStringList.Create;
  TotalCountryList.Sorted:=True;
  TotalCountryList.Duplicates:=dupIgnore;
  s := TStringList.Create;
  category_band := '';
  category_mode := '';
  try try
    AssignFile(r,'/tmp/CabrilloReject.log');
    Rewrite(r);
    dmData.qCQRLOG.Last;
    pbCabExport.Max := dmData.qCQRLOG.RecordCount;

    while not dmData.qCQRLOG.bof do
    begin
      tmp:='';
      // Check for missing mandatory fields
      if (dmData.qCQRLOG.FieldByName('qsodate').AsString  = '') then
                                                           tmp:=tmp+'Missing qsodate, ';
      if (dmData.qCQRLOG.FieldByName('time_off').AsString  = '') then
                                                           tmp:=tmp+'Missing time_off, ';
      if (dmData.qCQRLOG.FieldByName('callsign').AsString = '') then
                                                           tmp:=tmp+'Missing callsign, ';
      if (CabrilloBandToFreq(dmData.qCQRLOG.FieldByName('band').AsString) = '') then
                                                           tmp:=tmp+'Missing or WARC band, ';
      if (dmData.qCQRLOG.FieldByName('mode').AsString  = '') then
                                                           tmp:=tmp+'Missing mode, ';

      RejectQso := (tmp <> '');

      if not RejectQso then
       Begin
              // Check for single or ALL band
              if ( category_band='') then
                  category_band:= dmData.qCQRLOG.FieldByName('band').AsString //initial band
                else
               begin
                  if (dmData.qCQRLOG.FieldByName('band').AsString <> category_band) then  //if other bands found then ALL
                    category_band := 'ALL';
               end;
                // Check for single or MIXED mode
              if ( category_mode='') then
                  category_mode:= dmData.qCQRLOG.FieldByName('mode').AsString //initial mode
                else
               begin
                  if (dmData.qCQRLOG.FieldByName('mode').AsString <> category_mode) then  //if other modes found then MIXED
                    category_mode := 'MIXED';
               end;

              loc  := copy(dmData.qCQRLOG.FieldByName('loc').AsString,1,4);
              call := Format('%-'+edtCabCallWdt.Text+'.'+edtCabCallWdt.Text+'s', [dmData.qCQRLOG.FieldByName('callsign').AsString]);
              adif := dmDXCC.id_country(call,date,pfx,cont,country,itu,waz,posun,lat,long);
              TotalCountryList.Add(pfx);

              if ((CountryToCount<>0) and (adif = CountryToCount)) then inc(UsrCountryCount);
              case cont of
                     'NA':       Begin
                                   inc(Continents[0].QsoCount);
                                   if (pos(pfx,Continents[0].WkdPfxs)=0 )then
                                      Continents[0].WkdPfxs:= Continents[0].WkdPfxs+pfx+' ';
                                 end;
                     'SA':       Begin
                                   inc(Continents[1].QsoCount);
                                   if (pos(pfx,Continents[1].WkdPfxs)=0 )then
                                      Continents[1].WkdPfxs:= Continents[1].WkdPfxs+pfx+' ';
                                 end;
                     'OC':       Begin
                                   inc(Continents[2].QsoCount);
                                   if (pos(pfx,Continents[2].WkdPfxs)=0 )then
                                      Continents[2].WkdPfxs:= Continents[2].WkdPfxs+pfx+' ';
                                 end;
                     'AS':       Begin
                                   inc(Continents[3].QsoCount);
                                   if (pos(pfx,Continents[3].WkdPfxs)=0 )then
                                      Continents[3].WkdPfxs:= Continents[3].WkdPfxs+pfx+' ';
                                 end;
                     'EU':       Begin
                                   inc(Continents[4].QsoCount);
                                   if (pos(pfx,Continents[4].WkdPfxs)=0 )then
                                      Continents[4].WkdPfxs:= Continents[4].WkdPfxs+pfx+' ';
                                 end;
                     'AF':       Begin
                                   inc(Continents[5].QsoCount);
                                   if (pos(pfx,Continents[5].WkdPfxs)=0 )then
                                      Continents[5].WkdPfxs:= Continents[5].WkdPfxs+pfx+' ';
                                 end;
               end; //case

               if (length(loc)=4) then
                                 Begin
                                   if (pos(loc,Continents[6].WkdPfxs)=0 )then
                                    begin
                                      Continents[6].WkdPfxs:= Continents[6].WkdPfxs+loc+' ';
                                      inc(Continents[6].QsoCount);  //here not total, but different count
                                    end;
                                 end;
              if (dmData.qCQRLOG.FieldByName('operator').AsString <> '') and (Operators.IndexOf(dmData.qCQRLOG.FieldByName('operator').AsString) < 0) then
                 Operators.Add(dmData.qCQRLOG.FieldByName('operator').AsString);
       end;   //skip with rejected ends

         if ( dmData.qCQRLOG.FieldByName('freq').AsFloat < 50 ) then
                tmp:=tmp +  'QSO: '+Format('%5s',[FloatToStrF(dmData.qCQRLOG.FieldByName('freq').AsFloat*1000,ffFixed,0,0)])+' '
               else
                tmp:=tmp +  'QSO: '+Format('%5s',[CabrilloBandToFreq(dmData.qCQRLOG.FieldByName('band').AsString)])+' ';

         tmp:=tmp +
            CabrilloMode(dmData.qCQRLOG.FieldByName('mode').AsString)+' '+
            dmData.qCQRLOG.FieldByName('qsodate').AsString+' '+
            StringReplace(dmData.qCQRLOG.FieldByName('time_off').AsString,':','',[rfReplaceAll, rfIgnoreCase])+' '+
            Format('%0:-'+edtCabCallWdt.Text+'s', [mycall]);
            //end of common header

            if chkCabInfoSrst.Checked then tmp:=tmp+' '+ Format('%0:-'+edtCabInfoSrstWdt.Text+'s', [dmData.qCQRLOG.FieldByName('rst_s').AsString]);

            if (cmbCabInfoSEx1.ItemIndex > 0) then
             Begin
                 if (cmbCabInfoSEx1.Text = 'my_name') then
                   tmp:=tmp+' '+Format('%0:-'+edtCabInfoSEx1Wdt.Text+'s', [myname])
                  else
                   tmp:=tmp+' '+Format('%0:-'+edtCabInfoSEx1Wdt.Text+'s',[dmData.qCQRLOG.FieldByName(
                     cmbCabInfoSEx1.Text).AsString]) ;
             end;
             if (cmbCabInfoSEx2.ItemIndex > 0) then
             Begin
                 if (cmbCabInfoSEx2.Text = 'my_name') then
                   tmp:=tmp+' '+Format('%0:-'+edtCabInfoSEx2Wdt.Text+'s', [myname])
                  else
                   tmp:=tmp+' '+Format('%0:-'+edtCabInfoSEx2Wdt.Text+'s',[dmData.qCQRLOG.FieldByName(
                     cmbCabInfoSEx2.Text).AsString]) ;
             end;
             //end of info sent

             tmp:=tmp+' '+ call;
             if chkCabInfoRrst.Checked then tmp:=tmp+' '+ Format('%0:-'+edtCabInfoRrstWdt.Text+'s', [dmData.qCQRLOG.FieldByName('rst_r').AsString]);

             if (cmbCabInfoREx1.ItemIndex > 0) then
             Begin
                   tmp:=tmp+' '+Format('%0:-'+edtCabInfoREx1Wdt.Text+'s',[dmData.qCQRLOG.FieldByName(
                     cmbCabInfoREx1.Text).AsString]) ;
             end;
             if (cmbCabInfoREx2.ItemIndex > 0) then
             Begin
                   tmp:=tmp+' '+Format('%0:-'+edtCabInfoREx2Wdt.Text+'s',[dmData.qCQRLOG.FieldByName(
                     cmbCabInfoREx2.Text).AsString]) ;
             end;
            //end of info rcvd

             if (cmbCabTailTxCount.Text<>'') then tmp:=tmp+' '+Format('%0:1s',[ cmbCabTailTxCount.Text]);

      if chkUpCase.Checked then tmp:=UpperCase(tmp);

      if not RejectQso then
         Begin
             s.Add(tmp);      //add to cabrillo export
             inc(i);
         end
       else
             writeln(r,tmp); //add to rejected file

      pbCabExport.StepIt;
      pbCabExport.Update;  //GTK2 needs this to show progress, QT5 works even without

      dmData.qCQRLOG.Prior
    end;
  except
    on E : Exception do
    begin
      Application.MessageBox(Pchar('An error occurred during export:'+LineEnding+E.Message),'Error ...',
                             mb_OK+mb_IconError)
    end
  end
  finally
    lblCabDone.Visible := True;
    btnResultFile.Visible:=True;
    CloseFile(r);
  end;

  for j:=0 to pred(Operators.Count) do
  begin
     OpString := OpString+Operators[j];
     if (j >= 0) then
        OpString:=OpString+', '
  end;
  OpString := OpString + '@' + UpperCase(cqrini.ReadString('Station', 'Call', ''));

  //Check mode result before writing header
  case category_mode of
         'CW',
         'FM',
         'RTTY',
         'SSB',
         'MIXED'  : Begin //all is ok
                       if dmData.DebugLevel >=1 then  writeln('CATEGORY-MODE:', category_mode);
                    end;
         else category_mode:='DIGI';
  end;


  try
    AssignFile(f,edtCabFileName.Text);
    Rewrite(f);
    // This is Cabrillo format v3.0
    Writeln(f,'START-OF-LOG: 3.0');
    Writeln(f,'CREATED-BY: CQRLOG '+dmData.VersionString);
    Writeln(f,'CONTEST: '+cmbCabContestName.Text);
    Writeln(f,'CALLSIGN: '+mycall);
    if (Operators.Count > 0) then
       Writeln(f,'CATEGORY-OPERATOR: MULTI-OP')
    else
       Writeln(f,'CATEGORY-OPERATOR: SINGLE-OP');
    Writeln(f,'CATEGORY-BAND: '+category_band);
    Writeln(f,'CATEGORY-MODE: '+category_mode);
    Writeln(f,'CATEGORY-POWER: '+CabrilloPower(cmbCabPower.ItemIndex));
    Writeln(f,'CATEGORY-ASSISTED: NON-ASSISTED'); //  Only non-assisted currently
    Writeln(f,'CATEGORY-TRANSMITTER: ONE');  // Only one transmitter for now
    Writeln(f,'GRID-LOCATOR: '+UPcase(myloc)); //non standard upcase required
    Writeln(f,'LOCATION: '+edtCabLocation.Text);
    Writeln(f,'CLAIMED-SCORE: ');
    // Writeln(f,'SPECIFIC: ');   // Unknown Cabrillo Tag (DF2ET 26.10.2020)
    Writeln(f,'CLUB: '+club);
    if (Operators.Count > 0) then
       Writeln(f,'OPERATORS: '+OpString);
    Writeln(f,'NAME: '+myname);
    Writeln(f,'ADDRESS: '+mailingaddress);
    Writeln(f,'ADDRESS-CITY: '+address);
    Writeln(f,'ADDRESS-COUNTRY: '+mycountry);
    Writeln(f,'ADDRESS-STATE-PROVINCE: ');
    Writeln(f,'ADDRESS-POSTALCODE: '+zipcity);
    Writeln(f,'EMAIL: '+email);
    Writeln(f,'SOAPBOX:'+edtCabSoapBox.Text);

    for j:=0 to pred(s.Count) do
      Writeln(f,s[j]);

    Writeln(f,'END-OF-LOG:');
    CloseFile(f);
  except
      on E : Exception do
      begin
        Application.MessageBox(Pchar('An error occurred during export:'+LineEnding+E.Message),'Error ...',
                               mb_OK+mb_IconError)
      end
  end;
  lblCabError.Visible := True;
  if ((pbCabExport.Max - i) > 0) then
  begin
    lblCabError.Caption := IntToStr(pbCabExport.Max - i)+' of '+IntToStr(pbCabExport.Max)+' qsos were ignored! Please check: /tmp/CabrilloReject.log';
    lblCabError.Font.Color := clRed;
  end
  else
    lblCabError.Caption := IntToStr(s.Count)+' entries were exported.';

    lblCabStats.Visible := True;
    lblCabStats.Font.Style:=[fsBold]; //Bold disappears when visible false->true (why?)
    mCabStatistics.Clear;
    mCabStatistics.Lines.Add( 'Valid QSOs: '+IntToStr(s.Count));
    mCabStatistics.Lines.Add('Total country count: '+IntToStr(TotalCountryList.Count));
    if (CountryToCount<>0) then
       mCabStatistics.Lines.Add('User def pfx count: '+IntToStr(UsrCountryCount));
    if (( cmbCabInfoREx1.Text='loc') or (cmbCabInfoREx2.Text='loc')) then
       mCabStatistics.Lines.Add(Continents[6].Name+' Count: '+IntToStr(Continents[6].QsoCount)+'   '+Continents[6].WkdPfxs);

    for j:=0 to 5 do
      Begin
          mCabStatistics.Lines.Add(Continents[j].Name+' Qsos:'+Format('%4s',[IntToStr(Continents[j].QsoCount)])+' Pfx: '+Continents[j].WkdPfxs);
      end;
    mCabStatistics.Visible:=true;
end;

procedure TfrmCabrilloExport.btCabSaveClick(Sender: TObject);
var
  f : string ;
begin
  if (cmbCabContestName.Text<>'') then
   begin
    f:= dlgCabSave.FileName;
    dlgCabSave.FileName:= cmbCabContestName.Text;
   end;
  dlgCabSave.DefaultExt:='.templ';
  dlgCabSave.Filter:='Cabrillo template|*.templ';
  dlgCabSave.InitialDir := dmData.HomeDir;
  if dlgCabSave.Execute then saveCabLay(dlgCabSave.FileName);
  //return export file settings
  dlgCabSave.DefaultExt:='.cbr';
  dlgCabSave.Filter:='Cabrillo file|*.cbr';
  dlgCabSave.FileName:= f;
end;

procedure TfrmCabrilloExport.btCabLoadClick(Sender: TObject);
begin
  dlgCabOpen.InitialDir := dmData.HomeDir;
  if dlgCabOpen.Execute then
     if FileExists(dlgCabOpen.FileName) then  //with QT5 opendialog user can enter filename that may not exist
         loadCabLay(dlgCabOpen.FileName)
     else
        ShowMessage('File not found!');
end;
procedure TfrmCabrilloExport.saveCabLay(filename:String);
var
  filini : TIniFile;
begin
    filini := TIniFile.Create(fileName);
    try
      filini.WriteString('CabrilloExport','FileName',edtCabFileName.Text);
      filini.WriteString('CabrilloExport','ContestName',cmbCabContestName.Text);
      filini.WriteInteger('CabrilloExport','Power',cmbCabPower.ItemIndex);
      filini.WriteString('CabrilloExport','Location',edtCabLocation.Text);
      filini.WriteString('CabrilloExport','SoapBox',edtCabSoapBox.Text);
      filini.WriteString('CabrilloExport','CallsWidth', edtCabCallWdt.Text);

      filini.WriteBool('CabrilloExport','incRSTs',chkCabInfoSrst.Checked);
      filini.WriteString('CabrilloExport','SRSTWidth', edtCabInfoSrstWdt.Text);
      filini.WriteInteger('CabrilloExport','StxOrder',cmbCabInfoSEx1.ItemIndex);
      filini.WriteString('CabrilloExport','StxWidth', edtCabInfoSEx1Wdt.Text);
      filini.WriteInteger('CabrilloExport','StxStringOrder',cmbCabInfoSEx2.ItemIndex);
      filini.WriteString('CabrilloExport','StxStringWidth', edtCabInfoSEx2Wdt.Text);

      filini.WriteBool('CabrilloExport','incRSTr',chkCabInfoRrst.Checked);
      filini.WriteString('CabrilloExport','RRSTWidth', edtCabInfoRrstWdt.Text);
      filini.WriteInteger('CabrilloExport','SrxOrder',cmbCabInfoREx1.ItemIndex);
      filini.WriteString('CabrilloExport','SrxWidth', edtCabInfoREx1Wdt.Text);
      filini.WriteInteger('CabrilloExport','SrxStringOrder',cmbCabInfoREx2.ItemIndex);
      filini.WriteString('CabrilloExport','SrxStringWidth', edtCabInfoREx2Wdt.Text);

      filini.WriteInteger('CabrilloExport','TxCount',cmbCabTailTxCount.ItemIndex);
      filini.WriteInteger('CabrilloExport','CountryToCount',CountryToCount);

      filini.WriteBool('CabrilloExport','UseUpCase',chkUpCase.Checked);
    finally
      filini.Free
    end;
end;
Procedure TfrmCabrilloExport.loadCabLay(filename:string);
var
  filini : TIniFile;
  begin
    filini := TIniFile.Create(fileName);
    try
        edtCabFileName.Text  := filini.ReadString('CabrilloExport','FileName','');
        if edtCabFileName.Text='' then
          dlgCabSave.InitialDir := dmData.UsrHomeDir
        else
          dlgCabSave.InitialDir := ExtractFilePath(edtCabFileName.Text);
        cmbCabContestName.Text := filini.ReadString('CabrilloExport','ContestName','');

        cmbCabPower.ItemIndex:= filini.ReadInteger('CabrilloExport','Power',0);
        edtCabLocation.Text:= filini.ReadString('CabrilloExport','Location','');
        edtCabSoapBox.Text:= filini.ReadString('CabrilloExport','SoapBox','');
        edtCabCallWdt.Text:= filini.ReadString('CabrilloExport','CallsWidth', '13');

        chkCabInfoSrst.Checked:= filini.ReadBool('CabrilloExport','incRSTs',True);
        edtCabInfoSrstWdt.Text := filini.ReadString('CabrilloExport','SRSTWidth', '3');
        cmbCabInfoSEx1.ItemIndex:= filini.ReadInteger('CabrilloExport','StxOrder',0);
        edtCabInfoSEx1Wdt.Text:= filini.ReadString('CabrilloExport','StxWidth','6');
        cmbCabInfoSEx2.ItemIndex := filini.ReadInteger('CabrilloExport','StxStringOrder',0);
        edtCabInfoSEx2Wdt.Text := filini.ReadString('CabrilloExport','StxStringWidth', '6');

        chkCabInfoRrst.Checked:= filini.ReadBool('CabrilloExport','incRSTr',True);
        edtCabInfoRrstWdt.Text := filini.ReadString('CabrilloExport','RRSTWidth', '3');
        cmbCabInfoREx1.ItemIndex:= filini.ReadInteger('CabrilloExport','SrxOrder',0);
        edtCabInfoREx1Wdt.Text:= filini.ReadString('CabrilloExport','SrxWidth','6');
        cmbCabInfoREx2.ItemIndex := filini.ReadInteger('CabrilloExport','SrxStringOrder',0);
        edtCabInfoREx2Wdt.Text := filini.ReadString('CabrilloExport','SrxStringWidth', '6');
        cmbCabTailTxCount.ItemIndex := filini.ReadInteger('CabrilloExport','TxCount',0);

        CountryToCount:= filini.ReadInteger('CabrilloExport','CountryToCount',0);
        if ( CountryToCount > 0) then  edtCabCountC.Text:= dmDXCC.PfxFromADIF(CountryToCount);

        chkUpCase.Checked:=filini.ReadBool('CabrilloExport','UseUpCase',true);
    finally
      filini.Free
    end
end;


end.

