unit fExportProgress;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, iniFiles, ExtCtrls, db, dateutils, FileUtil, LazFileUtils,strutils;

type

  { TfrmExportProgress }

  TfrmExportProgress = class(TForm)
    lblComment: TLabel;
    pBarProg: TProgressBar;
    tmrExport: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrExportTimer(Sender: TObject);
  private
    procedure FieldsForExport(var ExDate,ExTimeOn,ExTimeOff,ExCall,ExMode,
                              ExFreq,ExRSTS,ExRSTR,ExName,ExQTH,ExQSLS,ExQSLR,
                              ExQSLVIA,ExIOTA,ExAward,ExLoc,ExMyLoc,ExOperator,ExDistance,ExPower,
                              ExCounty,ExDXCC,ExRemarks,ExWAZ, ExITU,ExNote,ExState,ExProfile,
                              ExLQslS,ExLQslSDate,ExLQslR,ExLQslRDate,ExQSLSDate,ExQSLRDate,
                              ExeQslS,ExeQslSDate,ExeQslR,ExeQslRDate,ExAscTime,ExProp, ExRxFreq,
                              ExSatName, ExSatMode, ExContinent, ExContestName, ExContestNr,
                              ExContesMsg, ExDarcDok: Boolean);
    procedure ExportADIF;
    procedure ExportHTML;

    { private declarations }
  public
    SecondBackupPath : String;
    ExportType : Integer; // 0 - ADIF, 1 - HTML, 2 - ADIF for backup
    FileName   : String;
    AutoBackup : Boolean;
    { public declarations }
  end; 

var
  frmExportProgress: TfrmExportProgress;
  running : Boolean = False;
  
implementation
{$R *.lfm}

{ TfrmExportProgress }
uses dUtils, dData, uMyIni, dDXCC, uVersion, dSatellite;

procedure TfrmExportProgress.FormCreate(Sender: TObject);
begin
  running := False;
  tmrExport.Enabled := True; // I have to do this horrible workaround because sometimes window after show
                             // dont get focus. Why??
  AutoBackup := False;
end;

procedure TfrmExportProgress.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(self);
end;

procedure TfrmExportProgress.tmrExportTimer(Sender: TObject);
begin
  tmrExport.Enabled := False;
  if not running then
  begin
    running := True;
    case ExportType of
    0,2 : begin
            lblComment.Caption := 'Exporting to ADIF file ...';
            ExportADIF;
          end;
      1 : begin
            lblComment.Caption := 'Exporting to HTML file ...';
            ExportHTML;
          end
    end // case
  end
end;

procedure TfrmExportProgress.FieldsForExport(var ExDate,ExTimeOn,ExTimeOff,ExCall,ExMode,
                              ExFreq,ExRSTS,ExRSTR,ExName,ExQTH,ExQSLS,ExQSLR,
                              ExQSLVIA,ExIOTA,ExAward,ExLoc,ExMyLoc,ExOperator,ExDistance,ExPower,
                              ExCounty,ExDXCC,ExRemarks,ExWAZ, ExITU,ExNote,ExState,ExProfile,
                              ExLQslS,ExLQslSDate,ExLQslR,ExLQslRDate,ExQSLSDate,ExQSLRDate,
                              ExeQslS,ExeQslSDate,ExeQslR,ExeQslRDate,ExAscTime,ExProp, ExRxFreq,
                              ExSatName, ExSatMode, ExContinent, ExContestName, ExContestNr,
                              ExContesMsg, ExDarcDok: Boolean);
begin
  ExDate    := cqrini.ReadBool('Export','Date',True);
  ExTimeOn  := cqrini.ReadBool('Export','time_on',True);
  ExTimeOff := cqrini.ReadBool('Export','time_off',False);
  ExCall    := cqrini.ReadBool('Export','CallSign',True);
  ExMode    := cqrini.ReadBool('Export','Mode',True);
  ExFreq    := cqrini.ReadBool('Export','Freq',True);
  ExRSTS    := cqrini.ReadBool('Export','RST_S',True);
  ExRSTR    := cqrini.ReadBool('Export','RST_R',True);
  ExName    := cqrini.ReadBool('Export','Name',True);
  ExQTH     := cqrini.ReadBool('Export','QTH',True);
  ExQSLS    := cqrini.ReadBool('Export','QSL_S',True);
  ExQSLR    := cqrini.ReadBool('Export','QSL_R',True);
  ExQSLVIA  := cqrini.ReadBool('Export','QSL_VIA',True);
  ExLoc     := cqrini.ReadBool('Export','Locator',False);
  ExMyLoc   := cqrini.ReadBool('Export','MyLoc',False);
  ExOperator:= cqrini.ReadBool('Export','Operator',False);
  ExDistance:= cqrini.ReadBool('Export','Distance',False);
  ExIOTA    := cqrini.ReadBool('Export','IOTA',False);
  ExAward   := cqrini.ReadBool('Export','Award',False);
  ExCounty  := cqrini.ReadBool('Export','County',False);
  ExPower   := cqrini.ReadBool('Export','Power',False);
  ExDXCC    := cqrini.ReadBool('Export','DXCC',False);
  ExRemarks := cqrini.ReadBool('Export','Remarks',False);
  ExWAZ     := cqrini.ReadBool('Export','WAZ',False);
  ExITU     := cqrini.ReadBool('Export','ITU',False);
  ExNote    := cqrini.ReadBool('Export','Note',False);
  ExState   := cqrini.ReadBool('Export','State',False);
  ExLQslS     := cqrini.ReadBool('Export','LQSLS',False);
  ExLQslSDate := cqrini.ReadBool('Export','LQSLSDate',False);
  ExLQslR     := cqrini.ReadBool('Export','LQSLR',False);
  ExLQslRDate := cqrini.ReadBool('Export','LQSLRDate',False);
  ExQSLSDate  := cqrini.ReadBool('Export','QSLSDate',False);
  ExQSLRDate  := cqrini.ReadBool('Export','QSLRDate',False);
  ExeQslS     := cqrini.ReadBool('Export','eQSLS',False);
  ExeQslSDate := cqrini.ReadBool('Export','eQSLSDate',False);
  ExeQslR     := cqrini.ReadBool('Export','eQSLR',False);
  ExeQslRDate := cqrini.ReadBool('Export','eQSLRDate',False);
  ExAscTime   := cqrini.ReadBool('Export','AscTime',False);
  ExProp      := cqrini.ReadBool('Export', 'Prop', False);
  ExRxFreq    := cqrini.ReadBool('Export', 'RxFreq', False);
  ExSatName   := cqrini.ReadBool('Export', 'SatName', False);
  ExSatMode   := cqrini.ReadBool('Export', 'SatMode', False);
  ExContinent := cqrini.ReadBool('Export', 'Continent', False);
  ExProfile   := cqrini.ReadBool('Export', 'Profile', False);
  ExContestName := cqrini.ReadBool('Export', 'Contestname', False);
  ExContestNr   := cqrini.ReadBool('Export', 'ContestNr',False);
  ExContesMsg   := cqrini.ReadBool('Export', 'ContestMsg', False);
  ExDarcDok := cqrini.ReadBool('Export', 'DarcDok', False);

end;

procedure TfrmExportProgress.ExportADIF;
var
  f      : TextFile;
  tmp    : String;
  i      : LongInt;
  note   : String;
  dir    : String;
  leng   : Word;
  lotw_qslsdate : String;
  lotw_qslrdate : String;
  eQSL_qslsdate : String;
  eQSL_qslrdate : String;
  qsls_date     : String;
  qslr_date     : String;
  ExDate,ExTimeOn,ExTimeOff,ExCall,ExMode : Boolean;
  ExFreq,ExRSTS,ExRSTR,ExName,ExQTH,ExQSLS,ExQSLR : Boolean;
  ExQSLVIA,ExIOTA,ExAward,ExLoc,ExMyLoc,ExOperator,ExDistance,ExPower : Boolean;
  ExCounty,ExDXCC,ExRemarks,ExWAZ, ExITU,ExNote,ExState, ExProfile : Boolean;
  ExLQslS,ExLQslSDate,ExLQslR,ExLQslRDate,ExQSLSDate,ExQSLRDate : Boolean;
  ExeQslS,ExeQslSDate,ExeQslR,ExeQslRDate,ExAscTime,ExProp, ExRxFreq, ExSatName, ExSatMode : Boolean;
  ExContinent, ExContestName, ExContestNr, ExContestMsg, ExDarcDok : Boolean;
  Source : TDataSet;
  FirstBackupPath : String;
  qrb,             //distance
  qrc :String;     //azimuth

  //------------------------------------------------------
  procedure SaveTag(TagData:String; var leng:word);
   begin
    Write(f, TagData);
    leng := leng + Length(TagData);
    if leng>200 then
      begin
        Writeln(f);
        leng := 0
      end;
   end;

  //------------------------------------------------------
  procedure SaveDataA(qsodate,TimeOn,TimeOff,Call,Freq,Mode,RSTS,RSTR,sName,
                     QTH,QSLS,QSLR,QSLVIA,IOTA,Power,Itu,waz,loc,Myloc,Op,County,
                     Award,Remarks,dxcc,state,band,profile,LQslS,LQslSDate,LQslR,LQslRDate,continent,
                     QSLSDate,QSLRDate,eQslS,eQslSDate,eQslR,eQslRDate,PropMode, Satellite, RxFreq, stx,
                     srx, stx_string, srx_string, contestname, Darc_Dok : String);

  var
     station_callsign : String;
  begin
    station_callsign := cqrini.ReadString('Station', 'Call', '');
    leng := 0;
    if ExDate then
    begin
      tmp := copy(qsodate,1,4) + copy(qsodate,6,2) + copy(qsodate,9,2);
      tmp := dmUtils.StringToADIF('<QSO_DATE',tmp);
      SaveTag(tmp,leng);
    end;
    if ExTimeOn then
    begin
      tmp := copy(TimeOn,1,2) + copy(TimeOn,4,2);
      tmp := dmUtils.StringToADIF('<TIME_ON',tmp);
      SaveTag(tmp,leng);
    end;
    if ExTimeOff then
    begin
      if dmUtils.IsTimeOK(TimeOff) then
      begin
        tmp := copy(TimeOff,1,2) + copy(TimeOff,4,2);
        tmp := dmUtils.StringToADIF('<TIME_OFF',tmp);
        SaveTag(tmp,leng);
      end;
    end;

    SaveTag(dmUtils.StringToADIF('<STATION_CALLSIGN', station_callsign), leng);

    if ExCall then
      SaveTag(dmUtils.StringToADIF('<CALL',dmUtils.RemoveSpaces(call)),leng);
    if ExMode then
    begin
      case Mode of
        'JS8'     : begin
                      tmp := '<MODE:4>MFSK<SUBMODE:3>JS8';
                      SaveTag(tmp,leng);
                    end;
        'FT4'     : begin
                      tmp := '<MODE:4>MFSK<SUBMODE:3>FT4';
                      SaveTag(tmp,leng);
                    end;
        'FST4'    : begin
                      tmp := '<MODE:4>MFSK<SUBMODE:4>FST4';
                      SaveTag(tmp,leng);
                    end;
        'PACKET'  :  begin
                        tmp := '<MODE:3>PKT';
                        SaveTag(tmp,leng);
                     end;
      else           begin
                        tmp := '<MODE';
                        SaveTag(dmUtils.StringToADIF(tmp,Mode),leng);
                     end;
      end;
    end;
    if ExFreq then
    begin
      if pos(',',freq) > 0 then
        freq[pos(',',freq)] := '.';
      SaveTag(dmUtils.StringToADIF('<FREQ',Freq),leng);
      SaveTag(dmUtils.StringToADIF('<BAND',dmUtils.GetAdifBandFromFreq(Freq)),leng);
    end;
    if ExRSTS then
      SaveTag(dmUtils.StringToADIF('<RST_SENT',ExtractWord(1,RSTS,[' '])),leng);
    if ExRSTR then
        SaveTag(dmUtils.StringToADIF('<RST_RCVD',ExtractWord(1,RSTR,[' '])),leng);
    if ExContestname then
    begin
       if Length(contestname) > 0 then
        SaveTag(dmUtils.StringToADIF('<CONTEST_ID',contestname),leng);
    end;
    if ExContestNr then
    begin
     if Length(stx) > 0 then
       SaveTag(dmUtils.StringToADIF('<STX',stx),leng);
     if Length(srx) > 0 then
        SaveTag(dmUtils.StringToADIF('<SRX',srx),leng);
    end;
    if ExContestMsg then
    begin
      if Length(stx_string) > 0 then
        SaveTag(dmUtils.StringToADIF('<STX_STRING',stx_string),leng);
       if Length(srx_string) > 0 then
        SaveTag(dmUtils.StringToADIF('<SRX_STRING',srx_string),leng);
    end;
    if ExName then
      if Length(sName) > 0 then
        SaveTag(dmUtils.StringToADIF('<NAME',sName),leng);
    if ExQTH then
      if Length(QTH) > 0 then
        SaveTag(dmUtils.StringToADIF('<QTH',QTH),leng);
    if ExQSLS then
    begin
      if Length(QSLS) > 0 then
      begin
        if Pos('S',QSLS) > 0 then
          SaveTag(dmUtils.StringToADIF('<QSL_SENT','R'),leng)
        else
        begin
          if Pos('N',QSLS)=1 then
            SaveTag(dmUtils.StringToADIF('<QSL_SENT','I'),leng)
          else
          SaveTag(dmUtils.StringToADIF('<QSL_SENT','Y'),leng)
        end
      end
      else
        SaveTag(dmUtils.StringToADIF('<QSL_SENT','N'),leng);
    end;
    if ExQSLR then
    begin
      if Length(QSLR) > 0 then
        SaveTag(dmUtils.StringToADIF('<QSL_RCVD','Y'),leng)
      else
        SaveTag(dmUtils.StringToADIF('<QSL_RCVD','N'),leng);
    end;
    if ExQSLVIA and (Length(QSLVIA) > 0) then
        SaveTag(dmUtils.StringToADIF('<QSL_VIA',QSLVIA),leng);
    if ExIOTA and (Length(IOTA) > 0 )then
        SaveTag(dmUtils.StringToADIF('<IOTA',IOTA),leng);
    if ExLoc then
       if dmUtils.IsLocOK(Loc) then
        SaveTag(dmUtils.StringToADIF('<GRIDSQUARE',dmUtils.StdFormatLocator(Loc)),leng);
   if ExMyLoc then
      if dmUtils.IsLocOK(MyLoc) then
        SaveTag(dmUtils.StringToADIF('<MY_GRIDSQUARE',dmUtils.StdFormatLocator(MyLoc)),leng);
   if ExOperator then
   begin
      if (Op <> '') and (Op <> station_callsign) then
         SaveTag(dmUtils.StringToADIF('<OPERATOR', Op) ,leng);
   end;
   if ExDistance then
    begin
      dmUtils.DistanceFromLocator(dmUtils.CompleteLoc(MyLoc),Loc,qrb,qrc);
      if qrb <> '' then
        SaveTag(dmUtils.StringToADIF('<DISTANCE',qrb),leng);
    end;
    if ExAward and (Length(Award) > 0)  then
        SaveTag(dmUtils.StringToADIF('<AWARD',Award),leng);
    if ExPower then
    begin
      Power := dmUtils.ExtractPower(Power);
      if Length(Power) > 0  then
        SaveTag(dmUtils.StringToADIF('<TX_PWR',Power),leng);
    end;
    if ExDXCC and (Length(DXCC) > 0 ) then
      begin
        SaveTag(dmUtils.StringToADIF('<APP_CQRLOG_DXCC',dxcc),leng);
        SaveTag(dmUtils.StringToADIF('<DXCC',IntToStr(dmDXCC.AdifFromPfx(dxcc))),leng);
      end;
    if ExRemarks and (Length(Remarks) > 0)  then
        SaveTag(dmUtils.StringToADIF('<COMMENT',Trim(Remarks)),leng);
    if ExNote then
     Begin
      Note := dmData.GetComment(call);
      if (Length(note) > 0) then
        SaveTag(dmUtils.StringToADIF('<NOTES',Trim(note)),leng);
     end;
    if ExITU and (Length(ITU) > 0) then
     SaveTag(dmUtils.StringToADIF('<ITUZ',ITU),leng);
    if ExWAZ and (Length(WAZ) > 0) then
     SaveTag(dmUtils.StringToADIF('<CQZ',WAZ),leng);
    if ExState and (Length(State) > 0) then
      SaveTag(dmUtils.StringToADIF('<STATE',State),leng);
    if ExCounty and (Length(County) > 0) then
      SaveTag(dmUtils.StringToADIF('<CNTY',County),leng);
    if ExQSLS and ( Length(QSLS) > 0 ) then
      SaveTag(dmUtils.StringToADIF('<APP_CQRLOG_QSLS',QSLS),leng);
    if ExQSLR and ( Length(QSLR) > 0 ) then
      SaveTag(dmUtils.StringToADIF('<APP_CQRLOG_QSLR',QSLR),leng);
    if ExProfile and (profile<>'0') and (profile<>'-1') then
    begin
      Writeln(f);
      leng := 0;
      tmp := dmData.GetExportProfileText(StrToInt(profile));
      tmp := Trim(tmp);
      SaveTag(dmUtils.StringToADIF('<APP_CQRLOG_PROFILE',tmp),leng);
    end;
    if ExLQslS and (Length(LQslS) > 0) then
      SaveTag(dmUtils.StringToADIF('<LOTW_QSL_SENT',LQslS),leng);
    if ExLQslSDate and (LQslSDate <> '') then
    begin
      tmp := copy(LQslSDate,1,4) + copy(LQslSDate,6,2) + copy(LQslSDate,9,2);
      SaveTag(dmUtils.StringToADIF('<LOTW_QSLSDATE',tmp),leng);
    end;
    if ExLQslR and (LQslR = 'L') then
     SaveTag(dmUtils.StringToADIF('<LOTW_QSL_RCVD','Y'),leng);
    if ExLQslRDate and (LQslRDate <> '') then
    begin
      tmp := copy(LQslRDate,1,4) + copy(LQslRDate,6,2) + copy(LQslRDate,9,2);
      SaveTag(dmUtils.StringToADIF('<LOTW_QSLRDATE',tmp),leng);
    end;
    if ExContinent and (continent <> '') then
      SaveTag('<CONT:2>'+continent,leng);
    if ExQSLSDate and (QSLSDate<>'') then
    begin
      tmp := copy(QSLSDate,1,4) + copy(QSLSDate,6,2) + copy(QSLSDate,9,2);
      SaveTag(dmUtils.StringToADIF('<QSLSDATE',tmp),leng);
    end;
    if ExQSLRDate and (QSLRDate<>'') then
    begin
      tmp := copy(QSLRDate,1,4) + copy(QSLRDate,6,2) + copy(QSLRDate,9,2);
      SaveTag(dmUtils.StringToADIF('<QSLRDATE',tmp),leng);
    end;
    if ExeQslS and (Length(eQslS) > 0) then
      SaveTag(dmUtils.StringToADIF('<EQSL_QSL_SENT',eQslS),leng);
    if ExeQslSDate and (eQslSDate <> '') then
    begin
      tmp := copy(eQslSDate,1,4) + copy(eQslSDate,6,2) + copy(eQslSDate,9,2);
      SaveTag(dmUtils.StringToADIF('<EQSL_QSLSDATE',tmp),leng);
    end;
    if ExeQslR and (eQslR = 'E') then
     SaveTag(dmUtils.StringToADIF('<EQSL_QSL_RCVD','Y'),leng);
    if ExeQslRDate and (eQslRDate <> '') then
    begin
      tmp := copy(eQslRDate,1,4) + copy(eQslRDate,6,2) + copy(eQslRDate,9,2);
      SaveTag(dmUtils.StringToADIF('<EQSL_QSLRDATE',tmp),leng);
    end;
    if (ExProp and (PropMode <> '')) then
       SaveTag(dmUtils.StringToADIF('<PROP_MODE',PropMode),leng);
    if (ExSatName and (Satellite<>'')) then
       SaveTag(dmUtils.StringToADIF('<SAT_NAME',Satellite),leng);
    if (ExSatMode and (PropMode = 'SAT')) then
       begin
          if (dmSatellite.GetSatMode(Freq, RxFreq) <> '') then
             SaveTag(dmUtils.StringToADIF('<SAT_MODE', dmSatellite.GetSatMode(Freq, RxFreq)),leng);
       end;
    if (ExRxFreq and ((RxFreq <> '0') and (RxFreq <> ''))) then
       begin
         SaveTag(dmUtils.StringToADIF('<FREQ_RX',RxFreq),leng);
         SaveTag(dmUtils.StringToADIF('<BAND_RX',dmUtils.GetAdifBandFromFreq(RxFreq)),leng);
       end;
    if (ExDarcDok and (Darc_Dok <> '')) then
       SaveTag(dmUtils.StringToADIF('<DARC_DOK',Darc_Dok),leng);

    Writeln(f);
    Write(f,'<EOR>');
    Writeln(f)
  end;
  //------------------------------------------------------

begin   //TfrmExportProgress
  if ExportType <> 2 then
               FieldsForExport(ExDate,ExTimeOn,ExTimeOff,ExCall,ExMode,
                              ExFreq,ExRSTS,ExRSTR,ExName,ExQTH,ExQSLS,ExQSLR,
                              ExQSLVIA,ExIOTA,ExAward,ExLoc,ExMyLoc,ExOperator,ExDistance,ExPower,
                              ExCounty,ExDXCC,ExRemarks,ExWAZ, ExITU,ExNote,ExState,ExProfile,
                              ExLQslS,ExLQslSDate,ExLQslR,ExLQslRDate,ExQSLSDate,ExQSLRDate,
                              ExeQslS,ExeQslSDate,ExeQslR,ExeQslRDate,ExAscTime,ExProp, ExRxFreq,
                              ExSatName, ExSatMode, ExContinent, ExContestName, ExContestNr,
                              ExContestMsg, ExDarcDok)
 else begin    //adif backup
    ExDate := True;ExTimeOn := True;ExTimeOff := True;ExCall := True;ExMode := True;
    ExFreq := True;ExRSTS := True;ExRSTR := True;ExName := True;ExQTH := True;ExQSLS := True;ExQSLR := True;
    ExQSLVIA := True;ExIOTA := True;ExAward := True;ExLoc := True;ExMyLoc := True;ExOperator := True;ExDistance := False;ExPower := True;
    ExCounty := True;ExDXCC := True;ExRemarks := True;ExWAZ := True;ExITU := True;ExNote := True;ExState := True;ExProfile := True;
    ExLQslS := True;ExLQslSDate := True;ExLQslR := True;ExLQslRDate := True; ExContinent := True;
    ExeQslS := True;ExeQslSDate := True;ExeQslR := True;ExeQslRDate := True; ExAscTime := False;
    ExProp := True; ExRxFreq := True; ExSatName := True; ExSatMode := True; ExContestname := True; ExContestnr := True; ExContestmsg := True;
    ExDarcDok := True;

    if not DirectoryExistsUTF8(dmData.HomeDir + 'tmp') then
      CreateDirUTF8(dmData.HomeDir + 'tmp');
    FirstBackupPath := ExtractFilePath(FileName);
    FileName        := dmData.HomeDir + 'tmp' + DirectorySeparator + ExtractFileName(FileName)
  end;

  AssignFile(f, FileName);
  Rewrite(f);
  Writeln(f, 'ADIF export from CQRLOG for Linux version '+dmData.VersionString);
  Writeln(f, 'Copyright (C) ',YearOf(now),' by Petr, OK2CQR and Martin, OK1RR');
  Writeln(f);
  Writeln(f, 'Internet: http://www.cqrlog.com');
  Writeln(f);
  Writeln(f, '<ADIF_VER:5>3.1.0');
  Writeln(f,'<CREATED_TIMESTAMP:15>',FormatDateTime('YYYYMMDD hhmmss',dmUtils.GetDateTime(0)));
  Writeln(f, '<PROGRAMID:6>CQRLOG');
  Writeln(f, '<PROGRAMVERSION:',Length(cVERSION),'>',cVERSION);
  Writeln(f, '<EOH>');

  i := 0;
  try
    pBarProg.Max := dmData.GetQSOCount;
    dmData.PrepareProfileExport;

    if AutoBackup or (not dmData.IsFilter) then
    begin
      dmData.Q.Close;
      if ExAscTime then
        dmData.Q.SQL.Text := 'SELECT * FROM view_cqrlog_main_by_qsodate_asc'
      else
        dmData.Q.SQL.Text := 'SELECT * FROM view_cqrlog_main_by_qsodate';
      dmData.trQ.StartTransaction;
      dmData.Q.Open;
      Source := dmData.Q
    end
    else
      Source := dmData.qCQRLOG;

    Source.DisableControls;
    try
      Source.First;
      while not Source.Eof do
      begin
        if not dmUtils.IsDateOK(Source.Fields[30].AsString) then
          lotw_qslrdate := ''
        else
          lotw_qslrdate := dmUtils.DateInRightFormat(Source.Fields[30].AsDateTime);

        if not dmUtils.IsDateOK(Source.Fields[29].AsString) then
          lotw_qslsdate := ''
        else
          lotw_qslsdate := dmUtils.DateInRightFormat(Source.Fields[29].AsDateTime);

        if not dmUtils.IsDateOK(Source.Fields[34].AsString) then
          qsls_date := ''
        else
          qsls_date := dmUtils.DateInRightFormat(Source.Fields[34].AsDateTime);

        if not dmUtils.IsDateOK(Source.Fields[35].AsString) then
          qslr_date := ''
        else
          qslr_date := dmUtils.DateInRightFormat(Source.Fields[35].AsDateTime);
        if Source.Fields[42].AsString = '' then
          eqsl_qslsdate := ''
        else
          eqsl_qslsdate := dmUtils.DateInRightFormat(Source.Fields[42].AsDateTime);
        if Source.Fields[44].AsString = '' then
          eqsl_qslrdate := ''
        else
          eqsl_qslrdate := dmUtils.DateInRightFormat(Source.Fields[44].AsDateTime);
        SaveDataA(dmUtils.DateInRightFormat(Source.Fields[1].AsDateTime),//qsodate
                 Source.Fields[2].AsString,//time_on
                 Source.Fields[3].AsString,//time_off
                 Source.Fields[4].AsString,//call
                 FloatToStr(Source.Fields[5].AsFloat),//freq
                 Source.Fields[6].AsString, //mode
                 Source.Fields[7].AsString,  //rsts
                 Source.Fields[8].AsString, //rstr
                 Source.Fields[9].AsString,  //name
                 Source.Fields[10].AsString, //qth
                 Source.Fields[11].AsString,  //qsls
                 Source.Fields[12].AsString, //qslr
                 Source.Fields[13].AsString, //qslvia
                 Source.Fields[14].AsString, //iota
                 Source.Fields[15].AsString, //power
                 Source.Fields[16].AsString, //itu
                 Source.Fields[17].AsString,  //waz
                 Source.Fields[18].AsString, //loc
                 Source.Fields[19].AsString, //myloc
                 Source.FieldByName('operator').AsString, //operator
                 Source.Fields[20].AsString, //county
                 Source.Fields[21].AsString, //award
                 Source.Fields[22].AsString, //remarks
                 Source.Fields[24].AsString, //dxcc
                 Source.Fields[28].AsString, //state
                 Source.Fields[23].AsString, //band
                 IntToStr(Source.Fields[26].AsInteger), //profile
                 Source.Fields[31].AsString, //lotw_qsls
                 lotw_qslsdate, //lotw_qslsdate
                 Source.Fields[32].AsString, //lotw_qslr
                 lotw_qslrdate,  //lotw_qslrdate
                 Source.Fields[33].AsString,  //cont
                 qsls_date, //qslsdate
                 qslr_date,  //qslrdate
                 Source.Fields[41].AsString,
                 eqsl_qslsdate,
                 Source.Fields[43].AsString,
                 eqsl_qslrdate,
                 Source.FieldByName('prop_mode').AsString,
                 Source.FieldByName('satellite').AsString,
                 FloatToStr(Source.FieldByName('RxFreq').AsFloat),
                 Source.FieldByName('stx').AsString,
                 Source.FieldByName('srx').AsString,
                 Source.FieldByName('stx_string').AsString,
                 Source.FieldByName('srx_string').AsString,
                 Source.FieldByName('contestname').AsString,
                 Source.FieldByName('dok').AsString
                  );
          pBarProg.StepIt;
          if (i mod 100 = 0) then
          begin
            Repaint;
            Application.ProcessMessages
          end;
          inc(i);
          Source.Next
      end
     finally
       Source.EnableControls;
       dmData.Q.Close;
       if dmData.trQ.Active then
         dmData.trQ.Rollback
     end;
  finally
    CloseFile(f);
    if ExportType <> 2 then
      ShowMessage('Export complete.'#13'File: ' + FileName)
    else begin
      dir      := ExtractFilePath(FileName);
      FileName := ExtractFileName(FileName);

      if cqrini.ReadBool('Backup','Compress',True) then
      begin
        chdir(dir);
        dmUtils.ExecuteCommand('tar -cvzf ' + ChangeFileExt(FileName,'.tar.gz') + ' ' +
                               FileName);
        tmp := ChangeFileExt(FileName,'.tar.gz');

        CopyFile(Dir + tmp,FirstBackupPath+tmp);

        if (SecondBackupPath<>'') then
        begin
          SecondBackupPath := IncludeTrailingBackslash(SecondBackupPath);
          CopyFile(Dir + tmp,SecondBackupPath+tmp)
        end;
        DeleteFileUTF8(Dir + tmp)
      end
      else begin
        CopyFile(Dir + FileName,FirstBackupPath+FileName);
        if (SecondBackupPath<>'') then
        begin
          SecondBackupPath := IncludeTrailingBackslash(SecondBackupPath);
          CopyFile(Dir+FileName,SecondBackupPath+FileName)
        end
      end;
      DeleteFileUTF8(Dir + FileName)
    end;
    dmData.CloseProfileExport;
    Close
  end
end;

procedure TfrmExportProgress.ExportHTML;
var
  f      : TextFile;
  tmp    : UTF8String;
   i      : Integer;
  note   : UTF8String;
  Mycall : String;
  Source : TDataSet;
  QSOcnt : Integer;
  QSODistSum: int64;
  LongestQSO,
  MainLocSum : Integer;
  lotw_qslsdate : String;
  lotw_qslrdate : String;
  qsls_date     : String;
  qslr_date     : String;
  eqsl_qslsdate : String;
  eqsl_qslrdate : String;
  qrb,             //distance
  qrc :String;     //azimuth
  lang:String;

  ExDate,ExTimeOn,ExTimeOff,ExCall,ExMode  : Boolean;
  ExFreq,ExRSTS,ExRSTR,ExName,ExQTH,ExQSLS,ExQSLR  : Boolean;
  ExQSLVIA,ExIOTA,ExAward,ExLoc,ExMyLoc,ExOperator,ExDistance,ExPower  : Boolean;
  ExCounty,ExDXCC,ExRemarks,ExWAZ, ExITU,ExNote, ExState, ExProfile : Boolean;
  ExLQslS,ExLQslSDate,ExLQslR,ExLQslRDate,ExQSLSDate, ExQSLRDate : Boolean;
  ExeQslS,ExeQslSDate,ExeQslR,ExeQslRDate,ExAscTime,ExProp, ExRxFreq, ExSatName, ExSatMode : Boolean;
  ExContinent, ExContestName, ExContestNr, ExContestMsg, ExDarcDok : Boolean;
  //-----------------------------------------------------------
  function ColumnWidth(ItemWidth:UTF8String):UTF8String;
  var i : integer;
  Begin
      i := StrToIntDef(ItemWidth,1); //if conversion fails set 1chr
      // 9.5 is average width in px for 16px Arial font
      Result:= IntToStr(95 * i div 10);
  end;
//-----------------------------------------------------------
 function SetWidth(item,Defw:UTF8String): UTF8String;

 Begin
 if cqrini.ReadBool('Export', 'HTMLAutoColumn', False) then
     Result := ''
    else
     Result := ' style="width: '+ColumnWidth(cqrini.ReadString('Export',item,defw))+'px" ';
 end;
 //-----------------------------------------------------------
 function SetData(item,Defw,Dat:UTF8String):UTF8String;
 begin
  Result := '<td><div '+SetWidth(item,Defw)+' class="norm">'+Dat+'</div></td><!-- '+item+' -->';
 end;
 //-----------------------------------------------------------
 function SetTHWidth(item,Defw,item1,Defw1:UTF8String): UTF8String;

 Begin
 if cqrini.ReadBool('Export', 'HTMLAutoColumn', False) then
     Result := '<th class="hlava"><div class="popis">'+cqrini.ReadString('Export', item1, Defw1)+
               '</div></th>'
    else
     Result := '<th style="width: '+ColumnWidth(cqrini.ReadString('Export',item,Defw))+
               'px" class="hlava"><div style="width: '+ColumnWidth(cqrini.ReadString('Export',item,Defw))+
               'px" class="popis">'+cqrini.ReadString('Export', item1, Defw1)+
               '</div></th>';
 end;
 //-----------------------------------------------------------

  procedure SaveDataH(qsodate,TimeOn,TimeOff,Call,Freq,Mode,RSTS,RSTR,sName,
                     QTH,QSLS,QSLR,QSLVIA,IOTA,Power,Itu,waz,loc,Myloc,Op,County,
                     Award,Remarks,dxcc,state,band,profile,LQslS,LQslSDate,LQslR,LQslRDate,continent,
                     QSLSDate,QSLRDate,eQslS,eQslSDate,eQslR,eQslRDate,PropMode, Satellite, RxFreq, stx,
                     srx, stx_string, srx_string, contestname, dok  : UTF8String);

  var
     SatMode : String = '';
  begin
    Writeln(f,'<tr>');
    if ExDate then
      Writeln(f,SetData('WDate','10',qsodate));

    if ExTimeOn then
      Writeln(f,SetData( 'Wtime_on', '5',TimeOn));

    if ExTimeOff then
    begin
      if TimeOff = '' then
        TimeOff := '&nbsp;';
      Writeln(f,SetData( 'Wtime_off', '5',TimeOff));
    end;

    if ExCall then
      Writeln(f,SetData( 'WCallSign', '10',Call));

    if ExFreq then
      Writeln(f,SetData( 'WFreq', '10',Freq));

    if ExMode then
      Writeln(f,SetData('WMode', '6' ,Mode));

    if ExRSTS then
      Writeln(f,SetData( 'WRST_S', '4',RSTS));

    if ExRSTR then
      Writeln(f,SetData('WRST_R', '4' ,RSTR));

    if ExName then
    begin
      if sName = '' then
        sName:= '&nbsp;';
      Writeln(f,SetData( 'WName', '20',sName));
    end;

    if ExQTH then
    begin
      if qth = '' then
        qth := '&nbsp;';
      Writeln(f,SetData('WQTH', '20' ,QTH));
    end;

    if ExQSLS then
    begin
      if QSLS = '' then
        qsls := '&nbsp;';
      Writeln(f,SetData( 'WQSL_S', '2',qsls));
    end;

    if ExQSLR then
    begin
      if qslr = '' then
        qslr := '&nbsp;';
      Writeln(f,SetData( 'WQSL_R', '2',QSLR));
    end;

    if ExQSLVIA then
    begin
      if QSLVIA = '' then
        qslvia := '&nbsp;';
      Writeln(f,SetData('WQSL_VIA', '10' ,QSLVIA));
    end;

    if ExIOTA then
    begin
      if IOTA = '' then
        iota:= '&nbsp;';
      Writeln(f,SetData('WIOTA', '7' ,IOTA));
    end;

    if ExAward then
    begin
      if Award = '' then
        Award := '&nbsp;';
      Writeln(f,SetData('WAward', '10' ,Award));
    end;

    if ExLoc then
    begin
      if loc = '' then
        loc := '&nbsp;';
      Writeln(f,SetData('WLocator', '6' ,loc));
    end;

    if ExMyLoc then
    begin
      if Myloc = '' then
        Myloc := '&nbsp;';
      Writeln(f,SetData('WMyLoc', '6' ,MyLOC));
    end;

    if ExOperator then
    begin
      if (Op = '') then
         Op := '&nbsp;';
      Writeln(f,SetData( 'WOperator', '10',Op));
    end;

    if ExDistance then
    begin
      qrb:='';
      dmUtils.DistanceFromLocator(dmUtils.CompleteLoc(Myloc),loc,qrb,qrc);
      if cqrini.ReadBool('Program','ShowMiles',False) then
        if qrb <> '' then
                qrb :=  FloatToStr(dmUtils.KmToMiles(StrToInt(qrb)));
      if  qrb = '' then
           qrb := '&nbsp;';
      Writeln(f,SetData('WDistance', '5' ,qrb));
    end;

    if ExPower then
    begin
      if Power = '' then
        Power := '&nbsp;';
      Writeln(f,SetData('WPower', '4' ,Power));
    end;

    if ExCounty then
    begin
      if County = '' then
        County := '&nbsp;';
      Writeln(f,SetData( 'WCounty', '10',County));
    end;

    if ExDXCC then
    begin
      Writeln(f,SetData( 'WDXCC', '4' ,DXCC));
    end;

    if ExRemarks then
    begin
      if Remarks = '' then
        Remarks := '&nbsp;';
      Writeln(f,SetData( 'WRemarks', '100',Remarks));
    end;

    if ExWAZ then
    begin
      if waz = '' then
       waz := '&nbsp;';
      Writeln(f,SetData( 'WWAZ', '3',WAZ));
    end;

    if ExITU then
    begin
      if Itu = '' then
        itu := '&nbsp;';
      Writeln(f,SetData('WITU', '3' ,ITU));
    end;

    if ExState then
    begin
      if state = '' then
        state := '&nbsp;';
      Writeln(f,SetData('WState', '10' ,state));
    end;

    if ExNote then
    begin
      if note = '' then
        note := '&nbsp;';
      Writeln(f,SetData( 'WNote', '50',Note));
    end;

    if ExLQslS then
    begin
      if LQslS = '' then
        LQslS := '&nbsp;';
      Writeln(f,SetData( 'WLQSLS', '2',LQslS));
    end;

    if ExLQslSDate then
    begin
      if LQslSDate = '' then
        LQslSDate := '&nbsp;';
      Writeln(f,SetData('WLQSLSDate', '10' ,LQslSDate));
    end;

    if ExLQslR then
    begin
      if LQslR = '' then
        LQslR := '&nbsp;';
      Writeln(f,SetData( 'WLQSLR', '2',LQslR));
    end;

    if ExLQslRDate then
    begin
      if LQslRDate = '' then
        LQslRDate := '&nbsp;';
      Writeln(f,SetData('WLQSLRDate', '10' ,LQslRDate));
    end;

    if ExContinent then
    begin
      if Continent = '' then
        Continent := '&nbsp;';
      Writeln(f,SetData( 'WContinent', '2',continent));
    end;

    if ExQSLSDate then
    begin
      if qslsdate = '' then
        qslsdate := '&nbsp;';
      Writeln(f,SetData( 'WQSLSDate', '10',qslsdate));
    end;
    if ExQSLRDate then
    begin
      if qslrdate = '' then
        qslrdate := '&nbsp;';
      Writeln(f,SetData( 'WQSLRDate', '10',qslrdate));
    end;

    if ExeQslS then
    begin
      if eQslS = '' then
        eQslS := '&nbsp;';
      Writeln(f,SetData('WeQSLS', '2' ,eQslS));
    end;

    if ExeQslSDate then
    begin
      if eQslSDate = '' then
        eQslSDate := '&nbsp;';
      Writeln(f,SetData( 'WeQSLSDate', '10',eQslSDate));
    end;

    if ExeQslR then
    begin
      if eQslR = '' then
        eQslR := '&nbsp;';
      Writeln(f,SetData('WeQSLR', '2' ,eQslR));
    end;

    if ExeQslRDate then
    begin
      if eQslRDate = '' then
        eQslRDate := '&nbsp;';
      Writeln(f,SetData( 'WeQSLRDate', '10',eQslRDate));
    end;

    if ExProp then
    begin
      if (PropMode = '') then
        PropMode := '&nbsp;';
      Writeln(f, SetData( 'WProp', '6',PropMode));
    end;

    if ExRxFreq then
    begin
      if ((RxFreq = '') or (RxFreq = '0')) then
        RxFreq := '&nbsp;';
      Writeln(f, SetData( 'WRxFreq', '10',RxFreq));
    end;

    if ExSatName  then
    begin
      if (Satellite = '') then
        Satellite := '&nbsp;';
      Writeln(f, SetData( 'WSatName', '10',Satellite));
    end;

    if ExSatMode then
    begin
      if (PropMode = 'SAT') then
        SatMode := dmSatellite.GetSatMode(Freq, RxFreq);
      Writeln(f, SetData( 'WSatMode', '10', SatMode));
    end;

    if ExProfile then
    begin
      writeln('prof');
      tmp := '&nbsp;';
      if (profile<>'0') and (profile<>'-1') then
          begin
            tmp := dmData.GetExportProfileText(StrToInt(profile));
            writeln('here ',tmp);
            trim(tmp);
          end;
      Writeln(f, SetData( 'WProfile', '20',tmp));
    end;

    if ExContestname then
    begin
      if (contestname='') then
         contestname:='&nbsp;';
      Writeln(f, SetData('WContestName', '20' ,contestname));
    end;

    if ExContestnr then
    begin
      if (srx='') then
         srx:='&nbsp;';
      Writeln(f, SetData('WContestNr', '4' ,srx));
    end;

    if ExContestmsg then
    begin
      if (srx_string='') then
               srx_string:='&nbsp;';
      Writeln(f, SetData('WContestMsg', '10' ,srx_string));
    end;

    if ExContestnr then
    begin
      if (stx='') then
         stx:='&nbsp;';
      Writeln(f, SetData('WContestNr', '4' ,stx));
    end;

    if ExContestmsg then
    begin
      if (stx_string='') then
         stx_string:='&nbsp;';
      Writeln(f, SetData('WContestMsg', '10' ,stx_string));
    end;

    if ExDarcDok then
    begin
      if (stx_string='') then
         stx_string:='&nbsp;';
      Writeln(f, SetData('Darc_Dok', '10' ,dok));
    end;

    Writeln(f,'</tr>')
  end;

 //-----------------------------------------------------------
begin
  MyCall := cqrini.ReadString('Station','Call','');
  QSOcnt := dmData.GetQSOCount;
  dmData.GetQSODistanceSum(QSODistSum,LongestQSO,MainLocSum);
  FieldsForExport(ExDate,ExTimeOn,ExTimeOff,ExCall,ExMode,
                  ExFreq,ExRSTS,ExRSTR,ExName,ExQTH,ExQSLS,ExQSLR,
                  ExQSLVIA,ExIOTA,ExAward,ExLoc,ExMyLoc,ExOperator,ExDistance,ExPower,
                  ExCounty,ExDXCC,ExRemarks,ExWAZ, ExITU,ExNote, ExState,
                  ExProfile,ExLQslS,ExLQslSDate,ExLQslR,ExLQslRDate,ExQSLSDate,ExQSLRDate,
                  ExeQslS,ExeQslSDate,ExeQslR,ExeQslRDate,ExAscTime, ExProp, ExRxFreq, ExSatName,
                  ExSatMode, ExContinent, ExContestname, ExContestnr, ExContestmsg, ExDarcDok);

  lang:= ExtractWord(1,GetEnvironmentVariable('LANG'),['.']);
  if (lang='') or (pos('_',lang)=0) then lang:='en-EN'
    else lang[pos('_',lang)]:='-'; //html equv
  AssignFile(f, FileName);
  SetTextCodePage(f,CP_UTF8);
  Rewrite(f);
  Writeln(f,'<!DOCTYPE HTML>');
  Writeln(f, '<html lang="',lang,'">');
  Writeln(f, '<head>');
  Writeln(f, '<META NAME="GENERATOR" CONTENT="CQRLOG ver. ' + dmData.VersionString + '">');
  Writeln(f, '<META charset="UTF-8">');
  Writeln(f, '<META NAME="viewport" content="width=device-width, initial-scale=1.0">');
  Writeln(f, '<title>List of QSO from CQRLOG - ' + Mycall + '</title>');


  Writeln(f,'<style>');
  Writeln(f,'.cntr {');
  Writeln(f,'	text-align:center;');
  Writeln(f,'}');
  Writeln(f,'.norm {');
  Writeln(f,'	color: #000000;');
  Writeln(f,'	font-family: Verdana, Arial, Helvetica, sans-serif;');
  Writeln(f,'	font-size: 16px;');
  Writeln(f,'   white-space: nowrap;');
  if not cqrini.ReadBool('Export', 'HTMLAutoColumn', False) then
    begin
      Writeln(f,'   overflow: hidden;');
      Writeln(f,'   text-overflow: clip;');
    end;
  Writeln(f,'}');
  Writeln(f,'.popis {');
  Writeln(f,'	color: #FFFFFF;');
  Writeln(f,'	font-family: Verdana, Arial, Helvetica, sans-serif;');
  Writeln(f,'	font-size: 16px;');
  Writeln(f,'   white-space: nowrap;');
  if not cqrini.ReadBool('Export', 'HTMLAutoColumn', False) then
      begin
        Writeln(f,'   overflow: hidden;');
        Writeln(f,'   text-overflow: clip;');
      end;
  Writeln(f,'}');
  Writeln(f,'.hlava {');
  Writeln(f,'	background-color: #333366;');
  Writeln(f,'	font-family: Verdana, Arial, Helvetica, sans-serif;');
  Writeln(f,'	font-size: 16px;');
  Writeln(f,'   white-space: nowrap;');
  if not cqrini.ReadBool('Export', 'HTMLAutoColumn', False) then
      begin
        Writeln(f,'   overflow: hidden;');
        Writeln(f,'   text-overflow: clip;');
      end;
   Writeln(f,'} ');
  Writeln(f,'table.a { ');
  Writeln(f,'   border-style: none;');
  Writeln(f,'   table-layout: auto;');
  Writeln(f,'} ');
  Writeln(f,'table.b { ');
  Writeln(f,'	margin-left: auto;');
  Writeln(f,'	margin-right: auto;');
  Writeln(f,'   border-width: 5px;');
  Writeln(f,'   border-spacing: 1px;');
  Writeln(f,'   border-style: solid;');
  Writeln(f,'   white-space: nowrap;');
  Write(f,'    table-layout: ');
  if cqrini.ReadBool('Export', 'HTMLAutoColumn', False) then
      Writeln(f,'auto;')
     else
      begin
       Writeln(f,'fixed;');
       Writeln(f,'   overflow: hidden;');
       Writeln(f,'   text-overflow: clip;');
      end;
  Writeln(f,'} ');
  Writeln(f,'td.a {');
  Writeln(f,'   border: none;');
  Writeln(f,'	font-family: Verdana, Arial, Helvetica, sans-serif;');
  Writeln(f,'	font-size: 16px;');
  Writeln(f,'}');
  Writeln(f,'th {');
  Writeln(f,'   border: 1px solid #333366;');
  Writeln(f,'}');
  Writeln(f,'td {');
  Writeln(f,'   border: 1px solid black;');
  Writeln(f,'}');
  Writeln(f,'</style>');

  Writeln(f,'</head>');
  Writeln(f);
  Writeln(f, '<body>');

  Writeln(f, '<h1 class="cntr">QSO from station log of ' + Mycall +' </h1>');
  Writeln(f, '<br/>');

  Writeln(f, '<table class="a">');
  Writeln(f, '<tr><td class="a">QSO count:</td><td class="a">' + IntToStr(QSOCnt) + '</td></tr>');
  Writeln(f, '<tr><td class="a">Main grid count:</td><td class="a">' + IntToStr(MainLocSum) + '</td></tr>');
  Write(f, '<tr><td class="a">QSO total distance:</td><td class="a">');
  if cqrini.ReadBool('Program','ShowMiles',False) then
      Writeln(f, FloatToStr(dmUtils.KmToMiles(QSODistSum)) + ' mi</td></tr>')
     else
      Writeln(f, IntToStr(QSODistSum) + ' km</td></tr>');

  Write(f, '<tr><td class="a">Longest QSO:</td><td class="a">');
    if cqrini.ReadBool('Program','ShowMiles',False) then
      Writeln(f, FloatToStr(dmUtils.KmToMiles(LongestQSO)) + ' mi</td></tr>')
     else
       Writeln(f, IntToStr(LongestQSO) + ' km</td></tr>');
  Writeln(f, '</table>');

  Writeln(f, '<br/><br/>');

  Writeln(f, '<table class="b">');
  Writeln(f, '<tr>');

  if ExDate then
    Writeln(f,SetTHWidth('WDate','10','WDate1', 'Date'));
  if ExTimeOn then
    Writeln(f,SetTHWidth('Wtime_on','5', 'Wtime_on1', 'Time on'));
  if ExTimeOff then
    Writeln(f,SetTHWidth('Wtime_off','5', 'Wtime_off1', 'Time off'));
  if ExCall then
    Writeln(f,SetTHWidth('WCallSign','10', 'WCallSign1', 'Call'));
  if ExFreq then
    Writeln(f,SetTHWidth('WFreq','10', 'WFreq1', 'Freq'));
  if ExMode then
    Writeln(f,SetTHWidth('WMode','6', 'WMode1', 'Mode'));
  if ExRSTS then
    Writeln(f,SetTHWidth('WRST_S','2', 'WRST_S1', 'RSTs'));
  if ExRSTR then
    Writeln(f,SetTHWidth('WRST_R','2', 'WRST_R1', 'RSTr'));
  if ExName then
      Writeln(f,SetTHWidth('WName','20', 'WName1', 'Name'));
  if ExQTH then
    Writeln(f,SetTHWidth('WQTH','20', 'WQTH1', 'QTH'));
  if ExQSLS then
    Writeln(f,SetTHWidth('WQSL_S','2', 'WQSL_S1', 'QSLs'));
  if ExQSLR then
    Writeln(f,SetTHWidth('WQSL_R','2', 'WQSL_R1', 'QSLr'));
  if ExQSLVIA then
    Writeln(f,SetTHWidth('WQSL_VIA','10', 'WQSL_VIA1', 'QSL via'));
  if ExIOTA then
    Writeln(f,SetTHWidth('WIOTA','7', 'WIOTA1', 'IOTA'));
  if ExAward then
    Writeln(f,SetTHWidth('WAward','10', 'WAward1', 'Award'));
  if ExLoc then
    Writeln(f,SetTHWidth('WLocator','6', 'WLocator1', 'Loc'));
  if ExMyLoc then
    Writeln(f,SetTHWidth('WMyLoc','6', 'WMyLoc1', 'MyLoc'));
  if ExOperator then
    Writeln(f,SetTHWidth('WOperator','10', 'WOperator1', 'Operator'));
  if ExDistance then
    Writeln(f,SetTHWidth('WDistance','5', 'WDistance1', 'QRB'));
  if ExPower then
    Writeln(f,SetTHWidth('WPower','4', 'WPower1', 'Pwr'));
  if ExCounty then
    Writeln(f,SetTHWidth('WCounty','10', 'WCounty1', 'County'));
  if ExDXCC then
    Writeln(f,SetTHWidth('WDXCC','4', 'WDXCC1', 'DXCC'));
  if ExRemarks then
    Writeln(f,SetTHWidth('WRemarks','100', 'WRemarks1', 'Cmnt'));
  if ExWAZ then
    Writeln(f,SetTHWidth('WWAZ','3', 'WWAZ1', 'WAZ'));
  if ExITU then
    Writeln(f,SetTHWidth('WITU','3', 'WITU1', 'ITU'));
  if ExState then
    Writeln(f,SetTHWidth('WState','10', 'WState1', 'State'));
  if ExNote then
    Writeln(f,SetTHWidth('WNote','50', 'WNote1', 'Note'));
  if ExLQslS then
    Writeln(f,SetTHWidth('WLQslS','2', 'WLQSLS1', 'LQSLs'));
  if ExLQslSDate then
    Writeln(f,SetTHWidth('WLQslSDate','10', 'WLQSLSDate1', 'LQSLSdat'));
  if ExLQslR then
    Writeln(f,SetTHWidth('WLQslR','2', 'WLQSLR1', 'LQSLr'));
  if ExLQslRDate then
    Writeln(f,SetTHWidth('WLQslRDate','10', 'WLQSLRDate1', 'LQSLRdat'));
  if ExContinent then
    Writeln(f,SetTHWidth('WContinent','2', 'WContinent1', 'Contin'));
  if ExQSLSDate then
    Writeln(f,SetTHWidth('WQSLSDate','10', 'WQSLSDate1', 'QSLSdat'));
  if ExQSLRDate then
    Writeln(f,SetTHWidth('WQSLRDate','10', 'WQSLRDate1', 'QSLRdat'));
  if ExeQslS then
    Writeln(f,SetTHWidth('WeQslS','2', 'WeQSLS1', 'eQSLs'));
  if ExeQslSDate then
    Writeln(f,SetTHWidth('WeQslSDate','10', 'WeQSLSDate1', 'eQSLSdat'));
  if ExeQslR then
    Writeln(f,SetTHWidth('WeQslR','2', 'WeQSLR1', 'eQSLr'));
  if ExeQslRDate then
    Writeln(f,SetTHWidth('WeQslRDate','10', 'WeQSLRDate1', 'eQSLRdat'));
  if ExProp then
    Writeln(f,SetTHWidth('WProp','6', 'WProp1', 'Propag'));
  if ExRxFreq then
    Writeln(f,SetTHWidth('WRxFreq','10', 'WRxFreq1', 'RX Freq'));
  if ExSatName  then
    Writeln(f,SetTHWidth('WSatName','10', 'WSatName1', 'Satellite'));
  if ExSatMode  then
    Writeln(f,SetTHWidth('WSatMode','10', 'WSatMode1', 'SAT Mode'));
  if ExProfile  then
    Writeln(f,SetTHWidth( 'WProfile', '10', 'WProfile1', 'Profile'));
  if ExContestname  then
    Writeln(f,SetTHWidth( 'WContestName', '10', 'WContestName1', ''));
  if ExContestnr  then
    Writeln(f,SetTHWidth( 'WContestNr', '10' , 'WContestNr1'+'R', 'Cont Nr'+'R'));
  if ExContestmsg  then
    Writeln(f,SetTHWidth( 'WContestMsg', '10', 'WContestMsg1'+'R', 'Cont Msg'+'R'));
  if ExContestnr  then
     Writeln(f,SetTHWidth( 'WContestNr', '10' , 'WContestNr1'+'S', 'Cont Nr'+'S'));
  if ExContestmsg  then
     Writeln(f,SetTHWidth( 'WContestMsg', '10', 'WContestMsg1'+'S', 'Cont Msg'+'S'));
  if ExDarcDok  then
     Writeln(f,SetTHWidth( 'Darc_Dok', '10', 'DARC DOK', 'DARC DOK'));


  Writeln(f,'</tr>');
                
  i := 0;

  pBarProg.Max := QSOcnt;
  dmData.PrepareProfileExport;

  if not dmData.IsFilter then
  begin
    dmData.Q.Close;
    if ExAscTime then
      dmData.Q.SQL.Text := 'SELECT * FROM view_cqrlog_main_by_qsodate_asc'
    else
      dmData.Q.SQL.Text := 'SELECT * FROM view_cqrlog_main_by_qsodate';
    dmData.trQ.StartTransaction;
    dmData.Q.Open;
    Source := dmData.Q
  end
  else
    Source := dmData.qCQRLOG;

  Source.DisableControls;
  try
    Source.First;
    while not Source.Eof do
    begin
        if Source.Fields[30].AsString = '' then
          lotw_qslrdate := ''
        else
          lotw_qslrdate := dmUtils.DateInRightFormat(Source.Fields[30].AsDateTime);

        if Source.Fields[29].AsString = '' then
          lotw_qslsdate := ''
        else
          lotw_qslsdate := dmUtils.DateInRightFormat(Source.Fields[29].AsDateTime);

        if Source.Fields[34].AsString = '' then
          qsls_date := ''
        else
          qsls_date := dmUtils.DateInRightFormat(Source.Fields[34].AsDateTime);

        if Source.Fields[35].AsString = '' then
          qslr_date := ''
        else
          qslr_date := dmUtils.DateInRightFormat(Source.Fields[35].AsDateTime);
        if Source.Fields[42].AsString = '' then
          eqsl_qslsdate := ''
        else
          eqsl_qslsdate := dmUtils.DateInRightFormat(Source.Fields[42].AsDateTime);
        if Source.Fields[44].AsString = '' then
          eqsl_qslrdate := ''
        else
          eqsl_qslrdate := dmUtils.DateInRightFormat(Source.Fields[44].AsDateTime);


      SaveDataH(dmUtils.DateInRightFormat(Source.Fields[1].AsDateTime),//qsodate
               Source.Fields[2].AsString,//time_on
               Source.Fields[3].AsString,//time_off
               Source.Fields[4].AsString,//call
               FloatToStr(Source.Fields[5].AsFloat),//freq
               Source.Fields[6].AsString, //mode
               Source.Fields[7].AsString,  //rsts
               Source.Fields[8].AsString, //rstr
               Source.Fields[9].AsString,  //name
               Source.Fields[10].AsString, //qth
               Source.Fields[11].AsString,  //qsls
               Source.Fields[12].AsString, //qslr
               Source.Fields[13].AsString, //qslvia
               Source.Fields[14].AsString, //iota
               Source.Fields[15].AsString, //power
               Source.Fields[16].AsString, //itu
               Source.Fields[17].AsString,  //waz
               Source.Fields[18].AsString, //loc
               Source.Fields[19].AsString, //myloc
               Source.FieldByName('operator').AsString, //operator
               Source.Fields[20].AsString, //county
               Source.Fields[21].AsString, //award
               Source.Fields[22].AsString, //remarks
               Source.Fields[24].AsString, //dxcc
               Source.Fields[28].AsString, //state
               Source.Fields[23].AsString, //band
               IntToStr(Source.Fields[26].AsInteger), //profile
               Source.Fields[31].AsString, //lotw_qsls
               lotw_qslsdate, //lotw_qslsdate
               Source.Fields[32].AsString, //lotw_qslr
               lotw_qslrdate,  //lotw_qslrdate
               Source.Fields[33].AsString,  //cont
               qsls_date, //qslsdate
               qslr_date,  //qslrdate
               Source.Fields[41].AsString,
               eqsl_qslsdate,
               Source.Fields[43].AsString,
               eqsl_qslrdate,
               Source.FieldByName('prop_mode').AsString,
               Source.FieldByName('satellite').AsString,
               FloatToStr(Source.FieldByName('RxFreq').AsFloat),
               Source.FieldByName('stx').AsString,
               Source.FieldByName('srx').AsString,
               Source.FieldByName('stx_string').AsString,
               Source.FieldByName('srx_string').AsString,
               Source.FieldByName('contestname').AsString,
               Source.FieldByName('dok').AsString
             );
      pBarProg.StepIt;
      if (i mod 100 = 0) then
      begin
        Repaint;
        Application.ProcessMessages
      end;
      inc(i);
      Source.Next
    end;
    Writeln(f,'</table>');
    Writeln(f,'<br> <br>');
    Writeln(f,'<h5 class="cntr"> <a href="http://www.cqrlog.com">CQRLOG ver. ' + dmData.VersionString  + ' </a></h5>');
    Writeln(f,'</body>');
    Writeln(f,'</html>')
  finally
    CloseFile(f);
    Source.EnableControls;
    dmData.Q.Close;
    if dmData.trQ.Active then
      dmData.trQ.Rollback;
    ShowMessage('Export complete.'#13'File: ' + FileName);
    Close
  end
end;

end.

