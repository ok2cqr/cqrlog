unit fCabrilloExport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, LCLType, LazFileUtils;

type

  { TfrmCabrilloExport }

  TfrmCabrilloExport = class(TForm)
    btnClose: TButton;
    btnExport: TButton;
    Button1: TButton;
    cbPower: TComboBox;
    cbContestRules: TComboBox;
    dlgSave: TSaveDialog;
    edtContestName: TEdit;
    edtFileName: TEdit;
    Label1: TLabel;
    lblStatsSum: TLabel;
    lblStatsContent: TLabel;
    lblStats: TLabel;
    lblContestRules: TLabel;
    lblPower: TLabel;
    lblError: TLabel;
    lblContestName: TLabel;
    lblDone: TLabel;
    pbExport: TProgressBar;
    multipliers: TStringList;
    procedure btnExportClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure FormShow(Sender : TObject);
  private
    procedure SaveSettings;
    procedure CabrilloMultipliersListCreate(contesttype: Integer);

    function CabrilloMode(mode : String) : String;
    function CabrilloBand(band : String) : String;
    function CabrilloPower(power: integer): String;
    function CabrilloQSOPoints(mode: String): Integer;
  public
    { public declarations }
  end;

var
  frmCabrilloExport : TfrmCabrilloExport;

implementation
{$R *.lfm}

uses dData,dUtils,dDXCC,fWorkedGrids, uMyIni;

{ TfrmCabrilloExport }

procedure TfrmCabrilloExport.FormShow(Sender : TObject);
begin
  dmUtils.LoadWindowPos(self);
  lblError.Visible := False;
  edtFileName.Text  := cqrini.ReadString('CabrilloExport','FileName','');
  if edtFileName.Text='' then
    dlgSave.InitialDir := dmData.UsrHomeDir
  else
    dlgSave.InitialDir := ExtractFilePath(edtFileName.Text);
  edtContestName.Text := cqrini.ReadString('CabrilloExport','ContestName','');
  cbPower.ItemIndex := 0;
  lblStats.Visible := False;
  lblStatsContent.Visible := False;
  lblStatsSum.Visible := False;
  multipliers := TStringList.Create;

end;

procedure TfrmCabrilloExport.SaveSettings;
begin
  cqrini.WriteString('CabrilloExport','FileName',edtFileName.Text);
  cqrini.WriteString('CabrilloExport','ContestName',edtContestName.Text);
end;

function TfrmCabrilloExport.CabrilloMode(mode: string): String;
begin
  Result := '';
  case mode of
    'SSB':  Result := 'PH';
    'CW':   Result := 'CW';
    'AM':   Result := 'PH';
    'FM':   Result := 'PH';
    'RTTY': Result := 'RY';
    'SSTV': Result := 'DG';
  end; //case
end;

function TfrmCabrilloExport.CabrilloBand(band: string): String;
begin
  Result := '';
  case band of
    '6M':       Result := '50';
    '4M':       Result := '70';
    '2M':       Result := '144';
    '70CM':     Result := '432';
    '23CM':     Result := '1.2G';
    '13CM':     Result := '2.3G';
    '9CM':      Result := '3.4G';
    '6CM':      Result := '5.7G';
    '3CM':      Result := '10G';
    '1.25CM':   Result := '24G';
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

function TfrmCabrilloExport.CabrilloQSOPoints(mode: String): Integer;
begin
  Result := 0;
  // Westphalia North and South Activities count QSO points based on mode
  if (cbContestRules.ItemIndex = 0) or (cbContestRules.ItemIndex = 1) then
  begin
    case mode of
      'FM':  Result := 2;
      'SSB': Result := 4;
      'CW':  Result := 6;
    end;
  end;
end;

procedure TfrmCabrilloExport.CabrilloMultipliersListCreate(contesttype: Integer);
begin
  case contesttype of
    0: begin
      multipliers.Delimiter := ';';
      multipliers.DelimitedText := 'N01;N02;N03;N04;N05;N06;N07;N08;N09;N10;N11;N12;N13;N14;N15;N16;N17;N18;N19;N20;N21;N22;N23;N24;N25;N26;N28;N29;N30;N31;N32;N33;N34;N35;N36;N37;N38;N39;N40;N41;N42;N43;N44;N45;N46;N47;N48;N49;N50;N51;N52;N53;N54;N55;N56;N57;N58;N59;N60;N61;N62;WN;DVN;YLN;Z14;Z34;Z41;Z60';
    end;
    1: begin
      multipliers.Delimiter := ';';
      multipliers.DelimitedText := 'O01;O02;O03;O04;O05;O06;O07;O08;O09;O10;O11;O12;O13;O14;O15;O16;O17;O18;O19;O20;O21;O22;O23;O24;O25;O26;O27;O28;O29;O30;O31;O32;O33;O34;O35;O36;O37;O38;O39;O40;O41;O42;O43;O44;O45;O46;O47;O48;O49;O51;O52;O53;O54;O55;DVO;DWS;YLO;Z03;Z38;Z92;Z93';
    end;
  end;
end;

procedure TfrmCabrilloExport.FormClose(Sender : TObject;
  var CloseAction : TCloseAction);
begin
  SaveSettings;
  dmUtils.SaveWindowPos(self)
end;

procedure TfrmCabrilloExport.Button1Click(Sender : TObject);
begin
  if dlgSave.Execute then
    edtFileName.Text := dlgSave.FileName
end;

procedure TfrmCabrilloExport.btnExportClick(Sender: TObject);
var
  AllQSO     : Boolean=False;
  f          : TextFile;
  q          : String;
  mycall     : String;
  myloc, loc : String;
  myname     : String;
  mailingaddress, zipcity : String;
  email      : String;
  club       : String;
  adif       : Word;
  i          : Integer = 0;
  j          : Integer = 0;
  s          : TStringList;
  Date       : TDateTime;
  callsign_list : TStringList;
  dupe       : String;
  cont, WAZ, posun, ITU, lat, long, pfx, country: string;
  message : String;
  category_band: String;
  address: TStringArray;
  qsopoints  : Integer = 0;
  multiplierpoints : Integer = 0;
  worked_multipliers : TStringList;
begin
  SaveSettings;
  date := dmUtils.GetDateTime(0);
  mycall := cqrini.ReadString('Station','Call','');
  cont := '';WAZ := '';posun := '';ITU := '';lat := '';long := '';
  adif := dmDXCC.id_country(mycall,date,pfx,country,cont,itu,waz,posun,lat,long);
  dmDXCC.qDXCCRef.Close;
  dmDXCC.qDXCCRef.SQL.Text := 'SELECT * FROM cqrlog_common.dxcc_ref WHERE adif = ' + IntToStr(adif);
  dmDXCC.qDXCCRef.Open;
  if dmDXCC.qDXCCRef.RecordCount > 0 then
  begin
    country := dmDXCC.qDXCCRef.FieldByName('name').AsString;
  end;
  myloc  := cqrini.ReadString('Station','LOC','');
  if length(myloc) = 4 then myloc := myloc +'LL';
  myname := cqrini.ReadString('Station','Name','');
  mailingaddress := cqrini.ReadString('Station','MailingAddress','');
  zipcity := cqrini.ReadString('Station','ZipCity','');
  address := zipcity.Split(' ');
  email := cqrini.ReadString('Station','Email','');
  club := cqrini.ReadString('Station','Club','');

  CabrilloMultipliersListCreate(cbContestRules.ItemIndex);
  worked_multipliers := TStringList.Create;

  if not dmData.IsFilter then
  begin
      Application.MessageBox('You must filter a single band to export!','Error ...',mb_OK+mb_IconError);
      exit
  end;
  if (dmData.qCQRLOG.FieldByName('band').AsString = '') then
  begin
      Application.MessageBox('You must filter a single band to export!','Error ...',mb_OK+mb_IconError);
      exit
  end;
  if FileExistsUTF8(edtFileName.Text) then
  begin
    if Application.MessageBox('File already exists,overwrite it?','Question ...',mb_YesNo
                              +mb_IconQuestion)=mrYes then
      DeleteFileUTF8(edtFileName.Text)
    else
      exit
  end;
  if (trim(edtFileName.Text)='') then
  begin
    Application.MessageBox('You must choose file to export!','Error ...',mb_OK+mb_IconError);
    exit
  end;
  pbExport.Position := 0;
  lblDone.Visible   := False;
  pbExport.Visible  := True;
  if dmData.trQ.Active then dmData.trQ.Rollback;
    dmData.Q.Close;
  if AllQSO then
    dmData.Q.SQL.Text := 'select qsodate,time_on,callsign,freq,mode,award,qth,remarks '+
                         'from view_cqrlog_main_by_qsodate order by qsodate,time_on'
  else begin
    q := dmData.qCQRLOG.SQL.Text;
    if Pos('order by',LowerCase(q)) > 0 then
      q := copy(q,1,Pos('order by',LowerCase(q))-1);
    q := q + ' order by qsodate,time_on';
    dmData.Q.SQL.Text := q;
  end;
  if dmData.DebugLevel >=1 then
    Writeln(dmData.Q.SQL.Text);
  s := TStringList.Create;
  callsign_list := TStringList.Create;
  category_band := 'ALL';
  try try
    dmData.trQ.StartTransaction;
    dmData.Q.Open;
    pbExport.Max := dmData.Q.RecordCount;
    while not dmData.Q.Eof do
    begin
      // Check for missing mandatory fields
      if (dmData.Q.FieldByName('rst_s').AsString = '') then
      begin
        pbExport.StepIt;
        dmData.Q.Next;
        Continue;
      end;
      if (dmData.Q.FieldByName('rst_r').AsString = '') then
      begin
        pbExport.StepIt;
        dmData.Q.Next;
        Continue;
      end;
      // Check for single or ALL band
      if (CabrilloBand(dmData.Q.FieldByName('band').AsString) <> category_band) then
      begin
           if (category_band = 'ALL') then
              category_band := CabrilloBand(dmData.Q.FieldByName('band').AsString)
           else
               category_band := 'ALL';
      end;
      i := i+1;
      s.Add('QSO: '+
            Format('%5S', [CabrilloBand(dmData.Q.FieldByName('band').AsString)])+' '+
            CabrilloMode(dmData.Q.FieldByName('mode').AsString)+' '+
            dmData.Q.FieldByName('qsodate').AsString+' '+
            StringReplace(dmData.Q.FieldByName('time_on').AsString,':','',[rfReplaceAll, rfIgnoreCase])+' '+
            Format('%-13S', [mycall])+' '+
            Format('%3S', [dmData.Q.FieldByName('rst_s').AsString])+' '+
            Format('%-6S', [dmData.Q.FieldByName('stx_string').AsString])+' '+
            // UpperCase(myloc)+' '+  // My locator is not needed here
            Format('%-13S', [dmData.Q.FieldByName('callsign').AsString])+' '+
            Format('%3S', [dmData.Q.FieldByName('rst_r').AsString])+' '+
            Format('%-6S', [dmData.Q.FieldByName('srx_string').AsString])+' '+
            '0' // Only single Ops supported currently so put transmitter ID to 0
      );
      qsopoints += CabrilloQSOPoints(dmData.Q.FieldByName('mode').AsString);
      if (multipliers.IndexOf(dmData.Q.FieldByName('srx_string').AsString) >= 0) and
         (worked_multipliers.IndexOf(dmData.Q.FieldByName('srx_string').AsString) < 0) then
      begin
            worked_multipliers.Add(dmData.Q.FieldByName('srx_string').AsString);
            multiplierpoints += 1;
      end;
      pbExport.StepIt;
      dmData.Q.Next
    end;
  except
    on E : Exception do
    begin
      Application.MessageBox(Pchar('An error occurred during export:'+LineEnding+E.Message),'Error ...',
                             mb_OK+mb_IconError)
    end
  end
  finally
    lblDone.Visible := True;
    dmData.trQ.Rollback;
    dmData.Q.Close
  end;
  try
    AssignFile(f,edtFileName.Text);
    Rewrite(f);
    // This is Cabrillo format v3.0
    Writeln(f,'START-OF-LOG: 3.0');
    Writeln(f,'CREATED-BY: CQRLOG '+dmData.VersionString);
    Writeln(f,'CONTEST: '+edtContestName.Text);
    Writeln(f,'CALLSIGN: '+mycall);
    Writeln(f,'CATEGORY-OPERATOR: SINGLE-OP');  // Only single op supported currently
    Writeln(f,'CATEGORY-BAND: '+category_band);
    Writeln(f,'CATEGORY-POWER: '+CabrilloPower(cbPower.ItemIndex));
    Writeln(f,'CATEGORY-ASSISTED: NON-ASSISTED'); //  Only non-assisted currently
    Writeln(f,'CATEGORY-TRANSMITTER: ONE');  // Only one transmitter for now
    Writeln(f,'LOCATION: ');
    Writeln(f,'CLAIMED-SCORE: '+IntToStr(qsopoints*multiplierpoints));
    Writeln(f,'SPECIFIC: ');
    Writeln(f,'CLUB: '+club);
    Writeln(f,'NAME: '+myname);
    Writeln(f,'ADDRESS: '+mailingaddress);
    Writeln(f,'ADDRESS-CITY: '+address[1]);
    Writeln(f,'ADDRESS-STATE: '+country);
    Writeln(f,'ADDRESS-STATE-PROVINCE: ');
    Writeln(f,'ADDRESS-POSTAL-CODE: '+address[0]);
    Writeln(f,'EMAIL: '+email);
    Writeln(f,'SOAPBOX:');

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
  if ((pbExport.Max - i) > 0) then
  begin
    lblError.Caption := IntToStr(pbExport.Max - i)+' of '+IntToStr(pbExport.Max)+' entries were ignored! Please check log entries.';
    lblError.Font.Color := clRed;
  end
  else
  begin
    lblError.Caption := IntToStr(s.Count)+' entries were exported.';
    lblStats.Visible := True;
    lblStatsContent.Caption := 'Valid QSOs: '+IntToStr(s.Count)+LineEnding+
                        'QSO Points: '+IntToStr(qsopoints)+LineEnding+
                        'Multipliers: '+IntToStr(multiplierpoints)+LineEnding;
    lblStatsContent.Visible := True;
    lblStatsSum.Caption := 'Total Sum: '+IntToStr(qsopoints*multiplierpoints);
    lblStatsSum.Visible := True;
  end;
  lblError.Visible := True;
end;

end.

