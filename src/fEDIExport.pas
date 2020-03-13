unit fEDIExport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, LCLType, LazFileUtils;

type

  { TfrmEDIExport }

  TfrmEDIExport = class(TForm)
    btnClose: TButton;
    btnExport: TButton;
    Button1: TButton;
    dlgSave: TSaveDialog;
    edtAntennaHeightSeaLevel: TEdit;
    edtContestName: TEdit;
    edtTxEquipment: TEdit;
    edtFileName: TEdit;
    edtRxEquipment: TEdit;
    edtAntenna: TEdit;
    edtAntennaHeightGroundLevel: TEdit;
    edtTxPower: TEdit;
    Label1: TLabel;
    lblAntennaHeight: TLabel;
    lblAntennaHeightSeaLevel: TLabel;
    lblAntennaHeightGroundLevel: TLabel;
    lblContestName: TLabel;
    lblAntenna: TLabel;
    lblTxEquipment: TLabel;
    lblDone: TLabel;
    lblRxEquipment: TLabel;
    lblTxPower: TLabel;
    pbExport: TProgressBar;
    procedure btnExportClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure FormShow(Sender : TObject);
  private
    procedure SaveSettings;

    function EdiMode(mode : String) : String;
    function EdiBand(band : String) : String;
  public
    { public declarations }
  end;

var
  frmEDIExport : TfrmEDIExport;

implementation
{$R *.lfm}

uses dData,dUtils,dDXCC, uMyIni;

{ TfrmEDIExport }

procedure TfrmEDIExport.FormShow(Sender : TObject);
begin
  dmUtils.LoadWindowPos(self);
  edtFileName.Text  := cqrini.ReadString('EdiExport','FileName','');
  if edtFileName.Text='' then
    dlgSave.InitialDir := dmData.UsrHomeDir
  else
    dlgSave.InitialDir := ExtractFilePath(edtFileName.Text);
  edtContestName.Text := cqrini.ReadString('EdiExport','ContestName','');
  edtTxEquipment.Text := cqrini.ReadString('EdiExport','TxEquipment','');
  edtTxPower.Text := cqrini.ReadString('EdiExport','TxPower','');
  edtRxEquipment.Text := cqrini.ReadString('EdiExport','RxEquipment','');
  edtAntenna.Text := cqrini.ReadString('EdiExport','Antenna','');
  edtAntennaHeightGroundLevel.Text := cqrini.ReadString('EdiExport','AntennaHeightGroundLevel','');
  edtAntennaHeightSeaLevel.Text := cqrini.ReadString('EdiExport','AntennaHeightSeaLevel','');

end;

procedure TfrmEDIExport.SaveSettings;
begin
  cqrini.WriteString('EdiExport','FileName',edtFileName.Text);
  cqrini.WriteString('EdiExport','ContestName',edtContestName.Text);
  cqrini.WriteString('EdiExport','TxEquipment',edtTxEquipment.Text);
  cqrini.WriteString('EdiExport','TxPower',edtTxPower.Text);
  cqrini.WriteString('EdiExport','RxEquipment',edtRxEquipment.Text);
  cqrini.WriteString('EdiExport','Antenna',edtAntenna.Text);
  cqrini.WriteString('EdiExport','AntennaHeightGroundLevel',edtAntennaHeightGroundLevel.Text);
  cqrini.WriteString('EdiExport','AntennaHeightSeaLevel',edtAntennaHeightSeaLevel.Text);
end;

function TfrmEDIExport.EdiMode(mode: string): String;
begin
  Result := '0';
  case mode of
    'SSB':  Result := '1';
    'CW':   Result := '2';
    'AM':   Result := '5';
    'FM':   Result := '6';
    'RTTY': Result := '7';
    'SSTV': Result := '8';
    'ATV':  Result := '9';
  end; //case
end;

function TfrmEDIExport.EdiBand(band: string): String;
begin
  Result := '';
  case band of
    '6M':       Result := '50 MHz';
    '4M':       Result := '70 MHz';
    '2M':       Result := '144 MHz';
    '70CM':     Result := '432 MHz';
    '23CM':     Result := '1,3 GHz';
    '13CM':     Result := '2,3 GHz';
    '9CM':      Result := '3,4 GHz';
    '6CM':      Result := '5,7 GHz';
    '3CM':      Result := '10 GHz';
    '1.25CM':   Result := '24 GHz';
  end; //case
end;

procedure TfrmEDIExport.FormClose(Sender : TObject;
  var CloseAction : TCloseAction);
begin
  SaveSettings;
  dmUtils.SaveWindowPos(self)
end;

procedure TfrmEDIExport.Button1Click(Sender : TObject);
begin
  if dlgSave.Execute then
    edtFileName.Text := dlgSave.FileName
end;

procedure TfrmEDIExport.btnExportClick(Sender: TObject);
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
  qrb, qrc   : String;
  odx        : Integer = 0;
  odx_call, odx_wwl : String;
  i          : Integer = 0;
  j          : Integer = 0;
  startdate, enddate: String;
  s          : TStringList;
  sum        : Integer = 0;
  Date       : TDateTime;
  wwls       : TStringList;
  new_wwl    : String;
  prefix     : String;
  dxccs      : TStringList;
  new_dxcc   : String;
  callsign_list : TStringList;
  dupe       : String;
  cont, WAZ, posun, ITU, lat, long, pfx, country: string;
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
  email := cqrini.ReadString('Station','Email','');
  club := cqrini.ReadString('Station','Club','');

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
  s := TStringList.Create;
  wwls := TStringList.Create;
  new_wwl := '';
  dxccs := TStringList.Create;
  new_dxcc := '';
  callsign_list := TStringList.Create;
  try try
    dmData.trQ.StartTransaction;
    dmData.Q.Open;
    pbExport.Max := dmData.Q.RecordCount;
    while not dmData.Q.Eof do
    begin
      i := i+1;
      if (i = 1)
      then
         startdate := StringReplace(dmData.Q.FieldByName('qsodate').AsString,'-','',[rfReplaceAll, rfIgnoreCase]);
      if (i = dmData.Q.RecordCount)
      then
         enddate := StringReplace(dmData.Q.FieldByName('qsodate').AsString,'-','',[rfReplaceAll, rfIgnoreCase]);
      loc := UpperCase(dmData.Q.FieldByName('srx_string').AsString);
      if (loc = '') then
      begin
        Application.MessageBox('Invalid grid locator in record!','Error ...',mb_OK+mb_IconError);
        exit
      end;
      if length(loc) = 4 then loc := loc +'LL';
      qrb:='';
      dmUtils.DistanceFromLocator(myloc,loc, qrb, qrc);
      sum := sum + StrToInt(qrb);
      if StrToInt(qrb) > odx then
      begin
         odx := StrToInt(qrb);
         odx_call := dmData.Q.FieldByName('callsign').AsString;
         odx_wwl  := loc;
      end;
      if (wwls.IndexOf(LeftStr(loc,4)) < 0) then
      begin
            wwls.Add(LeftStr(loc,4));
            new_wwl := 'N';
      end;
      prefix := dmDXCC.id_country(mycall,date);
      if (dxccs.IndexOf(prefix) < 0) then
      begin
             dxccs.Add(prefix);
             new_dxcc := 'N';
      end;
      if (callsign_list.IndexOf(dmData.Q.FieldByName('callsign').AsString) >= 0)
      then
              dupe := 'D'
      else
              callsign_list.Add(dmData.Q.FieldByName('callsign').AsString);

      // Check for missing mandatory fields
      if (dmData.Q.FieldByName('rst_s').AsString = '') then
      begin
        Application.MessageBox('Invalid sent RST in record!','Error ...',mb_OK+mb_IconError);
        exit
      end;
      if (dmData.Q.FieldByName('rst_r').AsString = '') then
      begin
        Application.MessageBox('Invalid received RST in record!','Error ...',mb_OK+mb_IconError);
        exit
      end;
      if (dmData.Q.FieldByName('stx').AsString = '') then
      begin
        Application.MessageBox('Invalid sent exchange in record!','Error ...',mb_OK+mb_IconError);
        exit
      end;
      if (dmData.Q.FieldByName('srx').AsString = '') then
      begin
        Application.MessageBox('Invalid received exchange in record!','Error ...',mb_OK+mb_IconError);
        exit
      end;

      s.Add(RightStr(StringReplace(dmData.Q.FieldByName('qsodate').AsString,'-','',[rfReplaceAll, rfIgnoreCase]),6)+';'+
            StringReplace(dmData.Q.FieldByName('time_on').AsString,':','',[rfReplaceAll, rfIgnoreCase])+';'+
            dmData.Q.FieldByName('callsign').AsString+';'+
            EdiMode(dmData.Q.FieldByName('mode').AsString)+';'+
            dmData.Q.FieldByName('rst_s').AsString+';'+
            dmData.Q.FieldByName('stx').AsString+';'+
            dmData.Q.FieldByName('rst_r').AsString+';'+
            dmData.Q.FieldByName('srx').AsString+';'+
            ';'+                                                   //Received Exchange empty for now ...
            loc+';'+
            qrb+';'+
            ';'+  // New exchange
            new_wwl+';'+   // New WWL
            new_dxcc+';'+  // New DXCCL
            dupe+''    // Duplicate
      );
      new_wwl := '';
      new_dxcc := '';
      dupe := '';
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
    Writeln(f,'[REG1TEST;1]');
    Writeln(f,'TName='+edtContestName.Text);
    Writeln(f,'TDate='+startdate+';'+enddate);
    Writeln(f,'PCall='+mycall);
    Writeln(f,'PWWLo='+UpperCase(myloc));
    Writeln(f,'PExch='+UpperCase(myloc));
    Writeln(f,'PAdr1='+mailingaddress);
    Writeln(f,'PAdr2='+zipcity);
    Writeln(f,'PSect=Single');  // Only single op supported currently
    Writeln(f,'PBand='+EdiBand(dmData.qCQRLOG.FieldByName('band').AsString));
    Writeln(f,'PClub='+club);
    Writeln(f,'RName='+myname);
    Writeln(f,'RCall='+mycall);
    Writeln(f,'RAdr1='+mailingaddress);
    Writeln(f,'RAdr2='+zipcity);
    Writeln(f,'RPoCo=');
    Writeln(f,'RCity=');
    Writeln(f,'RCoun='+country);
    Writeln(f,'RPhon=');
    Writeln(f,'RHBBS='+email);
    Writeln(f,'MOpe1=');
    Writeln(f,'MOpe2=');
    Writeln(f,'STXEq='+edtTxEquipment.Text);
    Writeln(f,'SPowe='+edtTxPower.Text);
    Writeln(f,'SRXEq='+edtRxEquipment.Text);
    Writeln(f,'SAnte='+edtAntenna.Text);
    Writeln(f,'SAntH='+edtAntennaHeightGroundLevel.Text+';'+edtAntennaHeightSeaLevel.Text);
    Writeln(f,'CQSOs='+IntToStr(i)+';1');
    Writeln(f,'CQSOP='+IntToStr(sum));
    Writeln(f,'CWWLs='+IntToStr(wwls.Count)+';0;1');
    Writeln(f,'CWWLB=0');
    Writeln(f,'CExcs=0;0;1');  // not regarded atm
    Writeln(f,'CExcB=0');
    Writeln(f,'CDXCs='+IntToStr(dxccs.Count)+';0;1');
    Writeln(f,'CDXCB=0');
    Writeln(f,'CToSc='+IntToStr(sum));
    Writeln(f,'CODXC='+odx_call+';'+odx_wwl+';'+IntToStr(odx));

    Writeln(f,'[Remarks]');
    Writeln(f,'[QSORecords;'+IntToStr(i)+']');

    for j:=0 to pred(s.Count) do
      Writeln(f,s[j]);

    Writeln(f,'[END; CQRLOG '+dmData.VersionString+']');
    CloseFile(f);
  except
      on E : Exception do
      begin
        Application.MessageBox(Pchar('An error occurred during export:'+LineEnding+E.Message),'Error ...',
                               mb_OK+mb_IconError)
      end
  end
end;

end.
