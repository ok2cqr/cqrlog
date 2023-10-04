unit fEDIExport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, LCLType, LazFileUtils, StrUtils;

type

  { TfrmEDIExport }

  TfrmEDIExport = class(TForm)
    btnClose: TButton;
    btnExport: TButton;
    btnBrowse: TButton;
    btnResultFile: TButton;
    chcSerialNr: TCheckBox;
    dlgSave: TSaveDialog;
    edtAntennaHeightSeaLevel: TEdit;
    edtContestName: TEdit;
    edtTxEquipment: TEdit;
    edtFileName: TEdit;
    edtRxEquipment: TEdit;
    edtAntenna: TEdit;
    edtAntennaHeightGroundLevel: TEdit;
    edtTxPower: TEdit;
    edtDigitalModes: TEdit;
    lblFilename: TLabel;
    lblError: TLabel;
    lblAntennaHeight: TLabel;
    lblAntennaHeightSeaLevel: TLabel;
    lblAntennaHeightGroundLevel: TLabel;
    lblContestName: TLabel;
    lblAntenna: TLabel;
    lblTxEquipment: TLabel;
    lblDone: TLabel;
    lblRxEquipment: TLabel;
    lblTxPower: TLabel;
    lblDigitalModes: TLabel;
    pbExport: TProgressBar;
    procedure btnExportClick(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure btnResultFileClick(Sender: TObject);
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

uses dData,dUtils,dDXCC,fWorkedGrids, uMyIni;

{ TfrmEDIExport }

procedure TfrmEDIExport.FormShow(Sender : TObject);
begin
  btnResultFile.Visible:=false;
  dmUtils.LoadWindowPos(self);
  lblError.Visible := False;
  edtFileName.Text  := cqrini.ReadString('EdiExport','FileName','');
  if edtFileName.Text='' then
    dlgSave.InitialDir := dmData.UsrHomeDir
  else
    dlgSave.InitialDir := ExtractFilePath(edtFileName.Text);
  edtContestName.Text := cqrini.ReadString('EdiExport','ContestName','');
  edtTxEquipment.Text := cqrini.ReadString('EdiExport','TxEquipment','');
  edtTxPower.Text := cqrini.ReadString('EdiExport','TxPower','');
  edtDigitalModes.Text := cqrini.ReadString('EdiExport','DigitalModes','');
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
  cqrini.WriteString('EdiExport','DigitalModes',edtDigitalModes.Text);
  cqrini.WriteString('EdiExport','RxEquipment',edtRxEquipment.Text);
  cqrini.WriteString('EdiExport','Antenna',edtAntenna.Text);
  cqrini.WriteString('EdiExport','AntennaHeightGroundLevel',edtAntennaHeightGroundLevel.Text);
  cqrini.WriteString('EdiExport','AntennaHeightSeaLevel',edtAntennaHeightSeaLevel.Text);
end;

function TfrmEDIExport.EdiMode(mode: string): String;
//2022-05-05 OH1KH It seems that EDI mode can be CqrMode (I.E. no mode+submode pairs needed)
//otherwise use dmUtils.ModeFromCqr to get mode and submode at this point
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
  if Result = '0' then
  begin
    if PosEx(mode, edtDigitalModes.Text) > 0 then
      Result := '7';
  end; //if
end;

function TfrmEDIExport.EdiBand(band: string): String;
begin
  Result := '';
  case band of
    '6M':       Result := '50 MHz';
    '4M':       Result := '70 MHz';
    '2M':       Result := '145 MHz';
    '70CM':     Result := '435 MHz';
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

procedure TfrmEDIExport.btnBrowseClick(Sender : TObject);
begin
  if dlgSave.Execute then
    edtFileName.Text := dlgSave.FileName
end;

procedure TfrmEDIExport.btnResultFileClick(Sender: TObject);
var
  prg: string;
begin
  try
    prg := cqrini.ReadString('ExtView', 'txt', '');
    if prg<>'' then
      dmUtils.RunOnBackground(prg + ' ' + AnsiQuotedStr(edtFileName.Text, '"'))
     else ShowMessage('No external text viewer defined!'+#10+'See: prefrences/External viewers');
  finally
   //done
  end;
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
  QsoMax     : Integer = 0;
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
  message : String;
  Operators : TStringList;
  OpString : String;
  DBRecordCount : integer =0; //holds max record count;
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
  Operators := TStringList.Create;
  OpString := '';
  try try
    dmData.trQ.StartTransaction;
    dmData.Q.Open;
    dmData.Q.Last; //to get proper count
    pbExport.Max := dmData.Q.RecordCount;
    DBRecordCount :=  dmData.Q.RecordCount;
    dmData.Q.First;
    while not dmData.Q.Eof do
    begin
      inc(QsoMax);
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
      if chcSerialNr.Checked then
      begin;
        if (dmData.Q.FieldByName('stx').AsString = '') then
        begin
          pbExport.StepIt;
          dmData.Q.Next;
          Continue;
        end;
        if (dmData.Q.FieldByName('srx').AsString = '') then
        begin
          pbExport.StepIt;
          dmData.Q.Next;
          Continue;
        end;
      end;
      loc := UpperCase(dmData.Q.FieldByName('srx_string').AsString);
      if (loc = '') then //or not frmWorkedGrids.GridOK(loc) then
      begin
        pbExport.StepIt;
        dmData.Q.Next;
        Continue;
      end;
      i := i+1;
      if (i = 1)
      then
         startdate := StringReplace(dmData.Q.FieldByName('qsodate').AsString,'-','',[rfReplaceAll, rfIgnoreCase]);
      if (i = DBRecordCount)
      then
         enddate := StringReplace(dmData.Q.FieldByName('qsodate').AsString,'-','',[rfReplaceAll, rfIgnoreCase]);
      if length(loc) = 4 then loc := loc +'LL';
      qrb:='';
      dmUtils.DistanceFromLocator(dmUtils.CompleteLoc(myloc),loc, qrb, qrc);
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

      if (dmData.Q.FieldByName('operator').AsString <> '') and (Operators.IndexOf(dmData.Q.FieldByName('operator').AsString) < 0) then
         Operators.Add(dmData.Q.FieldByName('operator').AsString);

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
  for j:=0 to pred(Operators.Count) do
  begin
     OpString := OpString+Operators[j];
     if (j >= 0) and (j < (Operators.Count-1)) then
        OpString:=OpString+';'
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
    if (Operators.Count = 0) then
      Writeln(f,'RCall='+mycall);
    Writeln(f,'RAdr1='+mailingaddress);
    Writeln(f,'RAdr2='+zipcity);
    Writeln(f,'RPoCo=');
    Writeln(f,'RCity=');
    Writeln(f,'RCoun='+country);
    Writeln(f,'RPhon=');
    Writeln(f,'RHBBS='+email);
    if (Operators.Count > 0) then
      Writeln(f,'MOpe1='+OpString)
    else
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
  end;
  if ((QsoMax - i) > 0) then
  begin
    lblError.Caption := IntToStr(QsoMax - i)+' of '+IntToStr(QsoMax)+' entries were ignored! Please check log entries.';
    lblError.Font.Color := clRed;
    lblError.Visible := True;
  end
  else
  begin
    lblError.Caption := IntToStr(QsoMax)+' entries were exported.';
    lblError.Font.Color := clGreen;
    lblError.Visible := True;
  end;
  btnResultFile.Visible:=True;
end;

end.

