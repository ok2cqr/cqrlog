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
                              ExQSLVIA,ExIOTA,ExAward,ExLoc,ExMyLoc,ExPower,
                              ExCounty,ExDXCC,ExRemarks,ExWAZ, ExITU,ExNote,ExState,ExProfile,
                              ExLQslS,ExLQslSDate,ExLQslR,ExLQslRDate,ExCont,ExQSLSDate,ExQSLRDate,
                              ExeQslS,ExeQslSDate,ExeQslR,ExeQslRDate,exAscTime: Boolean);
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
uses dUtils, dData, uMyIni, dDXCC, uVersion;

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
                             ExQSLVIA,ExIOTA,ExAward,ExLoc,ExMyLoc,ExPower,
                             ExCounty,ExDXCC,ExRemarks,ExWAZ, ExITU,ExNote,ExState,ExProfile,
                             ExLQslS,ExLQslSDate,ExLQslR,ExLQslRDate,ExCont,ExQSLSDate,ExQSLRDate,
                             ExeQslS,ExeQslSDate,ExeQslR,ExeQslRDate,exAscTime: Boolean);
begin
  exDate    := cqrini.ReadBool('Export','Date',True);
  exTimeOn  := cqrini.ReadBool('Export','time_on',True);
  exTimeOff := cqrini.ReadBool('Export','time_off',False);
  exCall    := cqrini.ReadBool('Export','CallSign',True);
  exMode    := cqrini.ReadBool('Export','Mode',True);
  exFreq    := cqrini.ReadBool('Export','Freq',True);
  exRSTS    := cqrini.ReadBool('Export','RST_S',True);
  exRSTR    := cqrini.ReadBool('Export','RST_R',True);
  exName    := cqrini.ReadBool('Export','Name',True);
  exQTH     := cqrini.ReadBool('Export','QTH',True);
  exQSLS    := cqrini.ReadBool('Export','QSL_S',True);
  exQSLR    := cqrini.ReadBool('Export','QSL_R',True);
  exQSLVIA  := cqrini.ReadBool('Export','QSL_VIA',True);
  exLoc     := cqrini.ReadBool('Export','Locator',False);
  exMyLoc   := cqrini.ReadBool('Export','MyLoc',False);
  exIOTA    := cqrini.ReadBool('Export','IOTA',False);
  exAward   := cqrini.ReadBool('Export','Award',False);
  exCounty  := cqrini.ReadBool('Export','County',False);
  exPower   := cqrini.ReadBool('Export','Power',False);
  exDXCC    := cqrini.ReadBool('Export','DXCC',False);
  exRemarks := cqrini.ReadBool('Export','Remarks',False);
  exWAZ     := cqrini.ReadBool('Export','WAZ',False);
  exITU     := cqrini.ReadBool('Export','ITU',False);
  exNote    := cqrini.ReadBool('Export','Note',False);
  ExProfile := cqrini.ReadBool('Export','Profile',False);
  exState   := cqrini.ReadBool('Export','State',False);
  ExLQslS     := cqrini.ReadBool('Export','LQSLS',False);
  ExLQslSDate := cqrini.ReadBool('Export','LQSLSDate',False);
  ExLQslR     := cqrini.ReadBool('Export','LQSLR',False);
  ExLQslRDate := cqrini.ReadBool('Export','LQSLRDate',False);
  ExCont      := cqrini.ReadBool('Export','Cont',False);
  ExQSLSDate  := cqrini.ReadBool('Export','QSLSDate',False);
  ExQSLRDate  := cqrini.ReadBool('Export','QSLRDate',False);
  ExeQslS     := cqrini.ReadBool('Export','eQSLS',False);
  ExeQslSDate := cqrini.ReadBool('Export','eQSLSDate',False);
  ExeQslR     := cqrini.ReadBool('Export','eQSLR',False);
  ExeQslRDate := cqrini.ReadBool('Export','eQSLRDate',False);
  exAscTime   := cqrini.ReadBool('Export','AscTime',False);
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
  ExDate,ExTimeOn,ExTimeOff,ExCall,ExMode,
  ExFreq,ExRSTS,ExRSTR,ExName,ExQTH,ExQSLS,ExQSLR,
  ExQSLVIA,ExIOTA,ExAward,ExLoc,ExMyLoc,ExPower,
  ExCounty,ExDXCC,ExRemarks,ExWAZ, ExITU,ExNote,ExState, ExProfile : Boolean;
  ExLQslS,ExLQslSDate,ExLQslR,ExLQslRDate,ExCont,ExQSLSDate,ExQSLRDate : Boolean;
  ExeQslS,ExeQslSDate,ExeQslR,ExeQslRDate,exAscTime : Boolean;
  Source : TDataSet;
  FirstBackupPath : String;

  procedure SaveData(qsodate,TimeOn,TimeOff,Call,Freq,Mode,RSTS,RSTR,sName,
                     QTH,QSLS,QSLR,QSLVIA,IOTA,Power,Itu,waz,loc,Myloc,County,
                     Award,Remarks,dxcc,state,band,profile,LQslS,LQslSDate,LQslR,LQslRDate,cont,
                     QSLSDate,QSLRDate,eQslS,eQslSDate,eQslR,eQslRDate  : String);

  begin
    leng := 0;
    if ExDate then
    begin
      tmp := copy(qsodate,1,4) + copy(qsodate,6,2) + copy(qsodate,9,2);
      tmp := '<QSO_DATE'+ dmUtils.StringToADIF(tmp);
      Write(f, tmp);
      leng := leng + Length(tmp)
    end;
    if ExTimeOn then
    begin
      tmp := copy(TimeOn,1,2) + copy(TimeOn,4,2);
      tmp := '<TIME_ON'+ dmUtils.StringToADIF(tmp);
      Write(f, tmp);
      leng := leng + Length(tmp)
    end;
    if ExTimeOff then
    begin
      if dmUtils.IsTimeOK(TimeOff) then
      begin
        tmp := copy(TimeOff,1,2) + copy(TimeOff,4,2);
        tmp := '<TIME_OFF'+ dmUtils.StringToADIF(tmp);
        Write(f, tmp);
        leng := leng + Length(tmp)
      end;
    end;
    if ExCall then
    begin
      tmp := '<CALL' + dmUtils.StringToADIF(dmUtils.RemoveSpaces(call));
      Write(f,tmp);
      leng := leng + Length(tmp)
    end;
    if exMode then
    begin
      tmp := '<MODE' + dmUtils.StringToADIF(Mode);
      Write(f,tmp);
      leng := leng + Length(tmp)
    end;
    if exFreq then
    begin
      if pos(',',freq) > 0 then
        freq[pos(',',freq)] := '.';
      tmp := '<FREQ' + dmUtils.StringToADIF(Freq);
      Write(f,tmp);
      leng := leng + Length(tmp);
      tmp := '<BAND' + dmUtils.StringToADIF(dmUtils.GetAdifBandFromFreq(Freq));
      Write(f,tmp);
      leng := leng + Length(tmp)
    end;
    if leng>200 then
    begin
      Writeln(f);
      leng := 0
    end;
    if leng>200 then
    begin
      Writeln(f);
      leng := 0
    end;
    if exRSTS then
    begin
      tmp := '<RST_SENT' + dmUtils.StringToADIF(ExtractWord(1,RSTS,[' ']));
      Write(f,tmp);
      leng := leng + Length(tmp);
      if leng>200 then
       begin
         Writeln(f);
         leng := 0
       end;
      if length(RSTS)>3 then // there is something else
      Begin
          tmp:=ExtractWord(2,RSTS,[' ']);  //contest NR
          if (tmp <>'') then
            Begin
               tmp := '<STX' + dmUtils.StringToADIF(tmp);
               Write(f,tmp);
               leng := leng + Length(tmp);
               if leng>200 then
               begin
                 Writeln(f);
                 leng := 0
               end;
            end;
          tmp:=ExtractWord(3,RSTS,[' ']);   //Contest MSG
          if (tmp <>'') then
            Begin
               tmp := '<STX_STRING' + dmUtils.StringToADIF(tmp);
               Write(f,tmp);
               leng := leng + Length(tmp);
               if leng>200 then
               begin
                 Writeln(f);
                 leng := 0
               end;
            end;
      end;
    end;

    if exRSTR then
      begin
        tmp := '<RST_RCVD' + dmUtils.StringToADIF(ExtractWord(1,RSTR,[' ']));
        Write(f,tmp);
        leng := leng + Length(tmp);
        if leng>200 then
         begin
           Writeln(f);
           leng := 0
         end;
        if length(RSTR)>3 then // there is something else
        Begin
            tmp:=ExtractWord(2,RSTR,[' ']);  //contest NR
            if (tmp <>'') then
              Begin
                 tmp := '<SRX' + dmUtils.StringToADIF(tmp);
                 Write(f,tmp);
                 leng := leng + Length(tmp);
                 if leng>200 then
                 begin
                   Writeln(f);
                   leng := 0
                 end;
              end;
            tmp:=ExtractWord(3,RSTR,[' ']);   //Contest MSG
            if (tmp <>'') then
              Begin
                 tmp := '<SRX_STRING' + dmUtils.StringToADIF(tmp);
                 Write(f,tmp);
                 leng := leng + Length(tmp);
                 if leng>200 then
                 begin
                   Writeln(f);
                   leng := 0
                 end;
              end;
        end;
      end;

    if exName then
    begin
      if Length(sName) > 0 then
      begin
        tmp := '<NAME' + dmUtils.StringToADIF(sName);
        Write(f,tmp);
        leng := leng + Length(tmp)
      end;
    end;
    if leng>200 then
    begin
      Writeln(f);
      leng := 0
    end;
    if exQTH then
    begin
      if Length(QTH) > 0 then
      begin
        tmp := '<QTH' + dmUtils.StringToADIF(QTH);
        Write(f,tmp);
        leng := leng + Length(tmp)
      end;
    end;
    if leng>200 then
    begin
      Writeln(f);
      leng := 0
    end;
    if exQSLS then
    begin
      if Length(QSLS) > 0 then
      begin
        if Pos('S',QSLS) > 0 then
          tmp := '<QSL_SENT' + dmUtils.StringToADIF('R')
        else
        begin
          if Pos('N',QSLS)=1 then
            tmp := '<QSL_SENT' + dmUtils.StringToADIF('I')
          else
          tmp := '<QSL_SENT' + dmUtils.StringToADIF('Y')
        end
      end
      else
        tmp := '<QSL_SENT' + dmUtils.StringToADIF('N');
      Write(f,tmp);
      leng := leng + Length(tmp)
    end;
    if leng>200 then
    begin
      Writeln(f);
      leng := 0
    end;
    if exQSLR then
    begin
      if Length(QSLR) > 0 then
        tmp := '<QSL_RCVD' + dmUtils.StringToADIF('Y')
      else
        tmp := '<QSL_RCVD' + dmUtils.StringToADIF('N');
      Write(f,tmp);
      leng := leng + Length(tmp)
    end;
    if leng>200 then
    begin
      Writeln(f);
      leng := 0
    end;
    if ExQSLVIA and (Length(QSLVIA) > 0) then
    begin
      tmp := '<QSL_VIA' + dmUtils.StringToADIF(QSLVIA);
      Write(f,tmp);
      leng := leng + Length(tmp)
    end;
    if exIOTA then
    begin
      if Length(IOTA) > 0 then
      begin
        tmp := '<IOTA' + dmUtils.StringToADIF(IOTA);
        Write(f,tmp);
        leng := leng + Length(tmp)
      end
    end;
    if leng>200 then
    begin
      Writeln(f);
      leng := 0
    end;
    if exLoc then
    begin
      if dmUtils.IsLocOK(Loc) then
      begin
        tmp := '<GRIDSQUARE' + dmUtils.StringToADIF(Loc);
        Write(f,tmp);
        leng := leng + Length(tmp)
      end
    end;
    if leng>200 then
    begin
      Writeln(f);
      leng := 0
    end;
    if exMyLoc then
    begin
      if dmUtils.IsLocOK(MyLoc) then
      begin
        tmp := '<MY_GRIDSQUARE' + dmUtils.StringToADIF(MyLoc);
        Write(f,tmp);
        leng := leng + Length(tmp)
      end
    end;
    if leng>200 then
    begin
      Writeln(f);
      leng := 0
    end;
    if exAward then
    begin
      if Length(Award) > 0  then
      begin
        tmp := '<AWARD' + dmUtils.StringToADIF(Award);
        Write(f,tmp);
        leng := leng + Length(tmp)
      end
    end;
    if leng>200 then
    begin
      Writeln(f);
      leng := 0
    end;
    if exPower then
    begin
      Power := dmUtils.ExtractPower(Power);
      if Length(Power) > 0  then
      begin
        tmp := '<TX_PWR' + dmUtils.StringToADIF(Power);
        Write(f,tmp);
        leng := leng + Length(tmp)
      end
    end;
    if leng>200 then
    begin
      Writeln(f);
      leng := 0
    end;
    if exDXCC then
    begin
      if Length(DXCC) > 0  then
      begin
        tmp := '<APP_CQRLOG_DXCC' + dmUtils.StringToADIF(dxcc);
        Write(f,tmp);
        tmp := '<DXCC'+dmUtils.StringToADIF(IntToStr(dmDXCC.AdifFromPfx(dxcc)));
        Write(f,tmp);
        leng := leng + Length(tmp)
      end
    end;
    if leng>200 then
    begin
      Writeln(f);
      leng := 0
    end;

    if ExRemarks then
    begin
      if Length(Remarks) > 0  then
      begin
        tmp := '<COMMENT' + dmUtils.StringToADIF(Trim(Remarks));
        Write(f,tmp);
        leng := leng + Length(tmp)
      end;

      if leng>200 then
      begin
        Writeln(f);
        leng := 0
      end;

      Note := dmData.GetComment(call);
      if Length(note) > 0 then
      begin
        tmp := '<NOTES' + dmUtils.StringToADIF(Trim(note));
        Write(f,tmp);
        leng := leng + Length(tmp)
      end;
    end;

    if leng>150 then
    begin
      Writeln(f);
      leng := 0
    end;

    if ExITU and (Length(ITU) > 0) then
    begin
      tmp := '<ITUZ'+ dmUtils.StringToADIF(ITU);
      Write(f,tmp);
      leng := leng + Length(tmp)
    end;

    if ExWAZ and (Length(WAZ) > 0) then
    begin
      tmp := '<CQZ'+ dmUtils.StringToADIF(WAZ);
      Write(f,tmp);
      leng := leng + Length(tmp)
    end;

    if ExState and (Length(State) > 0) then
    begin
      tmp:= '<STATE'+ dmUtils.StringToADIF(State);
      Write(f,tmp);
      leng := leng + Length(tmp)
    end;
      
    if ExCounty and (Length(County) > 0) then
    begin
      tmp := '<CNTY'+ dmUtils.StringToADIF(County);
      Write(f,tmp);
      leng := leng + Length(tmp)
    end;

    if exQSLS then
    begin
      if Length(QSLS) > 0 then
      begin
        tmp := '<APP_CQRLOG_QSLS' + dmUtils.StringToADIF(QSLS);
        Write(f,tmp);
        leng := leng + Length(tmp)
      end;
    end;

    if leng>200 then
    begin
      tmp := '';
      Writeln(f);
      leng := 0
    end;

    if exQSLR then
    begin
      if Length(QSLR) > 0 then
      begin
        tmp := '<APP_CQRLOG_QSLR' + dmUtils.StringToADIF(QSLR);
        Write(f,tmp);
        leng := leng + Length(tmp)
      end;
    end;
    if ExProfile and (profile<>'0') and (profile<>'-1') then
    begin
      Writeln(f);
      leng := 0;
      tmp := dmData.GetExportProfileText(StrToInt(profile));
      tmp := Trim(tmp);
      tmp := '<APP_CQRLOG_PROFILE' + dmUtils.StringToADIF(tmp);
      Write(f,tmp);
      leng := leng + Length(tmp)
    end;
    Writeln(f);
    if ExLQslS and (Length(LQslS) > 0) then
      Writeln(f,'<LOTW_QSL_SENT'+dmUtils.StringToADIF(LQslS));
    if ExLQslSDate and (LQslSDate <> '') then
    begin
      tmp := copy(LQslSDate,1,4) + copy(LQslSDate,6,2) + copy(LQslSDate,9,2);
      Writeln(f,'<LOTW_QSLSDATE'+dmUtils.StringToADIF(tmp))
    end;
    if ExLQslR and (LQslR = 'L') then
      Writeln(f,'<LOTW_QSL_RCVD'+dmUtils.StringToADIF('Y'));
    if ExLQslRDate and (LQslRDate <> '') then
    begin
      tmp := copy(LQslRDate,1,4) + copy(LQslRDate,6,2) + copy(LQslRDate,9,2);
      Writeln(f,'<LOTW_QSLRDATE'+dmUtils.StringToADIF(tmp))
    end;
    if ExCont and (cont <> '') then
      Writeln(f,'<CONT:2>'+cont);
    if ExQSLSDate and (QSLSDate<>'') then
    begin
      tmp := copy(QSLSDate,1,4) + copy(QSLSDate,6,2) + copy(QSLSDate,9,2);
      Write(f,'<QSLSDATE'+dmUtils.StringToADIF(tmp))
    end;
    if ExQSLRDate and (QSLRDate<>'') then
    begin
      tmp := copy(QSLRDate,1,4) + copy(QSLRDate,6,2) + copy(QSLRDate,9,2);
      Write(f,'<QSLRDATE'+dmUtils.StringToADIF(tmp))
    end;
    if ExeQslS and (Length(eQslS) > 0) then
      Writeln(f,'<EQSL_QSL_SENT'+dmUtils.StringToADIF(eQslS));
    if ExeQslSDate and (eQslSDate <> '') then
    begin
      tmp := copy(eQslSDate,1,4) + copy(eQslSDate,6,2) + copy(eQslSDate,9,2);
      Writeln(f,'<EQSL_QSLSDATE'+dmUtils.StringToADIF(tmp))
    end;
    if ExeQslR and (eQslR = 'E') then
      Writeln(f,'<EQSL_QSL_RCVD'+dmUtils.StringToADIF('Y'));
    if ExeQslRDate and (eQslRDate <> '') then
    begin
      tmp := copy(eQslRDate,1,4) + copy(eQslRDate,6,2) + copy(eQslRDate,9,2);
      Writeln(f,'<EQSL_QSLRDATE'+dmUtils.StringToADIF(tmp))
    end;

    Writeln(f);
    Write(f,'<EOR>');
    Writeln(f)
  end;
begin
  if ExportType <> 2 then
    FieldsForExport(ExDate,ExTimeOn,ExTimeOff,ExCall,ExMode,
                    ExFreq,ExRSTS,ExRSTR,ExName,ExQTH,ExQSLS,ExQSLR,
                    ExQSLVIA,ExIOTA,ExAward,ExLoc,ExMyLoc,ExPower,
                    ExCounty,ExDXCC,ExRemarks,ExWAZ,ExITU,ExNote,ExState,ExProfile,
                    ExLQslS,ExLQslSDate,ExLQslR,ExLQslRDate,ExCont,ExQSLSDate,ExQSLRDate,
                    ExeQslS,ExeQslSDate,ExeQslR,ExeQslRDate,ExAscTime)
  else begin
    ExDate := True;ExTimeOn := True;ExTimeOff := True;ExCall := True;ExMode := True;
    ExFreq := True;ExRSTS := True;ExRSTR := True;ExName := True;ExQTH := True;ExQSLS := True;ExQSLR := True;
    ExQSLVIA := True;ExIOTA := True;ExAward := True;ExLoc := True;ExMyLoc := True;ExPower := True;
    ExCounty := True;ExDXCC := True;ExRemarks := True;ExWAZ := True;ExITU := True;ExNote := True;ExState := True;ExProfile := True;
    ExLQslS := True;ExLQslSDate := True;ExLQslR := True;ExLQslRDate := True; ExCont := True;
    ExeQslS := True;ExeQslSDate := True;ExeQslR := True;ExeQslRDate := True; exAscTime := False;

    if not DirectoryExistsUTF8(dmData.HomeDir + 'tmp') then
      CreateDirUTF8(dmData.HomeDir + 'tmp');
    FirstBackupPath := ExtractFilePath(FileName);
    FileName        := dmData.HomeDir + 'tmp' + DirectorySeparator + ExtractFileName(FileName)
  end;

  AssignFile(f, FileName);
  Rewrite(f);
  Writeln(f, 'ADIF export from CQRLOG for Linux version '+dmData.VersionString);
  Writeln(f, 'Copyright (C) ',YearOf(now),' by Petr, OK7AN and Martin, OK1RR');
  Writeln(f);
  Writeln(f, 'Internet: http://www.cqrlog.com');
  Writeln(f);
  Writeln(f, '<ADIF_VER:5>2.2.1');
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
      if exAscTime then
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
        SaveData(dmUtils.DateInRightFormat(Source.Fields[1].AsDateTime),//qsodate
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
                 eqsl_qslrdate
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
  tmp    : String;
   i      : Integer;
  note   : String;
  Mycall : String;
  Source : TDataSet;
  QSOcnt : Integer;
  lotw_qslsdate : String;
  lotw_qslrdate : String;
  qsls_date     : String;
  qslr_date     : String;
  eqsl_qslsdate : String;
  eqsl_qslrdate : String;

  ExDate,ExTimeOn,ExTimeOff,ExCall,ExMode,
  ExFreq,ExRSTS,ExRSTR,ExName,ExQTH,ExQSLS,ExQSLR,
  ExQSLVIA,ExIOTA,ExAward,ExLoc,ExMyLoc,ExPower,
  ExCounty,ExDXCC,ExRemarks,ExWAZ, ExITU,ExNote, exState, ExProfile : Boolean;
  ExLQslS,ExLQslSDate,ExLQslR,ExLQslRDate,ExCont,ExQSLSDate, ExQSLRDate : Boolean;
  ExeQslS,ExeQslSDate,ExeQslR,ExeQslRDate,exAscTime : Boolean;

  procedure SaveData(qsodate,TimeOn,TimeOff,Call,Freq,Mode,RSTS,RSTR,sName,
                     QTH,QSLS,QSLR,QSLVIA,IOTA,Power,Itu,waz,loc,Myloc,County,
                     Award,Remarks,dxcc,state,band,profile,LQslS,LQslSDate,LQslR,LQslRDate,cont,
                     QSLSDate,QSLRDate,eQslS,eQslSDate,eQslR,eQslRDate: String);

  begin
    Writeln(f,'<tr>');
    if ExDate then
      Write(f,'<td>'+qsodate+'</td>');

    if ExTimeOn then
      Write(f,'<td>'+TimeOn+'</td>');

    if ExTimeOff then
    begin
      if TimeOff = '' then
        TimeOff := '&nbsp;';
      Write(f,'<td>'+TimeOff+'</td>');
    end;

    if ExCall then
      Write(f,'<td>'+Call+'</td>');

    if ExFreq then
      Write(f,'<td>'+Freq+'</td>');

    if ExMode then
      Write(f,'<td>'+Mode+'</td>');

    if ExRSTS then
      Write(f,'<td>'+RSTS+'</td>');

    if ExRSTR then
      Write(f,'<td>'+RSTR+'</td>');

    if ExName then
    begin
      if sName = '' then
        sName:= '&nbsp;';
      Write(f,'<td>'+sName+'</td>');
    end;

    if ExQTH then
    begin
      if qth = '' then
        qth := '&nbsp;';
      Write(f,'<td>'+QTH+'</td>');
    end;

    if ExQSLS then
    begin
      if QSLS = '' then
        qsls := '&nbsp;';
      Write(f,'<td>'+qsls+'</td>');
    end;

    if ExQSLR then
    begin
      if qslr = '' then
        qslr := '&nbsp;';
      Write(f,'<td>'+QSLR+'</td>');
    end;

    if ExQSLVIA then
    begin
      if QSLVIA = '' then
        qslvia := '&nbsp;';
      Write(f,'<td>'+QSLVIA+'</td>');
    end;

    if exIOTA then
    begin
      if IOTA = '' then
        iota:= '&nbsp;';
      Write(f,'<td>'+IOTA+'</td>');
    end;

    if ExAward then
    begin
      if Award = '' then
        Award := '&nbsp;';
      Write(f,'<td>'+Award+'</td>');
    end;

    if ExLoc then
    begin
      if loc = '' then
        loc := '&nbsp;';
      Write(f,'<td>'+loc+'</td>');
    end;

    if exMyLoc then
    begin
      if Myloc = '' then
        Myloc := '&nbsp;';
      Write(f,'<td>'+MyLOC+'</td>');
    end;

    if ExPower then
    begin
      if Power = '' then
        Power := '&nbsp;';
      Write(f,'<td>'+Power+'</td>');
    end;

    if ExCounty then
    begin
      if County = '' then
        County := '&nbsp;';
      Write(f,'<td>'+County+'</td>');
    end;

    if ExDXCC then
    begin
      Write(f,'<td>'+DXCC+'</td>');
    end;

    if ExRemarks then
    begin
      if Remarks = '' then
        Remarks := '&nbsp;';
      Write(f,'<td>'+Remarks+'</td>');
    end;

    if ExWAZ then
    begin
      if waz = '' then
       waz := '&nbsp;';
      Write(f,'<td>'+WAZ+'</td>');
    end;

    if ExITU then
    begin
      if Itu = '' then
        itu := '&nbsp;';
      Write(f,'<td>'+ITU+'</td>');
    end;

    if exState then
    begin
      if state = '' then
        state := '&nbsp;';
      Write(f,'<td>'+state+'</td>');
    end;

    if ExNote then
    begin
      if note = '' then
        note := '&nbsp;';
      Write(f,'<td>'+Note+'</td>');
    end;

    if ExLQslS then
    begin
      if LQslS = '' then
        LQslS := '&nbsp;';
      Write(f,'<td>'+LQslS+'</td>')
    end;

    if ExLQslSDate then
    begin
      if LQslSDate = '' then
        LQslSDate := '&nbsp;';
      Write(f,'<td>'+LQslSDate+'</td>')
    end;

    if ExLQslR then
    begin
      if LQslR = '' then
        LQslR := '&nbsp;';
      Write(f,'<td>'+LQslR+'</td>')
    end;

    if ExLQslRDate then
    begin
      if LQslRDate = '' then
        LQslRDate := '&nbsp;';
      Write(f,'<td>'+LQslRDate+'</td>')
    end;

    if ExCont then
    begin
      if Cont = '' then
        Cont := '&nbsp;';
      Write(f,'<td>'+cont+'</td>')
    end;

    if ExQSLSDate then
    begin
      if qslsdate = '' then
        qslsdate := '&nbsp;';
      Write(f,'<td>'+qslsdate+'</td>')
    end;
    if ExQSLRDate then
    begin
      if qslrdate = '' then
        qslrdate := '&nbsp';
      Write(f,'<td>'+qslrdate+'</td>')
    end;

    if ExeQslS then
    begin
      if eQslS = '' then
        eQslS := '&nbsp;';
      Write(f,'<td>'+eQslS+'</td>')
    end;

    if ExeQslSDate then
    begin
      if eQslSDate = '' then
        eQslSDate := '&nbsp;';
      Write(f,'<td>'+eQslSDate+'</td>')
    end;

    if ExeQslR then
    begin
      if eQslR = '' then
        eQslR := '&nbsp;';
      Write(f,'<td>'+eQslR+'</td>')
    end;

    if ExeQslRDate then
    begin
      if eQslRDate = '' then
        eQslRDate := '&nbsp;';
      Write(f,'<td>'+eQslRDate+'</td>')
    end;

    Writeln(f,'</tr>')
  end;
begin
  MyCall := cqrini.ReadString('Station','Call','');
  QSOcnt := dmData.GetQSOCount;
  FieldsForExport(ExDate,ExTimeOn,ExTimeOff,ExCall,ExMode,
                  ExFreq,ExRSTS,ExRSTR,ExName,ExQTH,ExQSLS,ExQSLR,
                  ExQSLVIA,ExIOTA,ExAward,ExLoc,ExMyLoc,ExPower,
                  ExCounty,ExDXCC,ExRemarks,ExWAZ, ExITU,ExNote, ExState,
                  ExProfile,ExLQslS,ExLQslSDate,ExLQslR,ExLQslRDate,ExCont,ExQSLSDate,ExQSLRDate,
                  ExeQslS,ExeQslSDate,ExeQslR,ExeQslRDate,exAscTime);

  AssignFile(f, FileName);
  Rewrite(f);
  Writeln(f, '<html>');
  Writeln(f, '<head>');
  Writeln(f, '<meta http-equiv="Content-Language" content="en">');
  Writeln(f, '<META NAME="GENERATOR" CONTENT="CQRLOG ver. ' + dmData.VersionString + '>');
  Writeln(f, '<meta http-equiv="Content-Type" content="text/html; charset=utf8">');
  Writeln(f, '<title>List of QSO from CQRLOG - ' + Mycall + '</title>');
  Writeln(f,'<style type="text/css">');
  Writeln(f,'<!--');
  Writeln(f,'.popis {color: #FFFFFF}');
  Writeln(f,'.hlava {');
  Writeln(f,'	color: #333366;');
  Writeln(f,'	font-family: Verdana, Arial, Helvetica, sans-serif;');
  Writeln(f,'	font-size: 16px;');
  Writeln(f,'	font-weight: bold;');
  Writeln(f,'}');
  Writeln(f,'-->');
  Writeln(f,'</style>');
  Writeln(f, '</head>');
  Writeln(f);
  Writeln(f, '<body>');
  Writeln(f, '<center><h1>QSO from station log of ' + Mycall +' </h1></center>');
  Writeln(f, '<br/>');

  tmp := 'QSO: ' + IntToStr(QSOCnt);
  Writeln(f, '<p>');
  Writeln(f, '<font size="1">');
  Writeln(f, tmp);
  Writeln(f, '</font>');
  Writeln(f, '</p>');
  Writeln(f, '<br/><br/>');
  Writeln(f, '<center>');
  Writeln(f, '<table border="5" cellspacing="1" width="95%">');
  Writeln(f, '<tr>');
  
  if ExDate then
    Write(f,'<td width="'+cqrini.ReadString('Export','WDate','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">Date</div></td>');

  if ExTimeOn then
    Write(f,'<td width="'+cqrini.ReadString('Export','Wtime_off','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">&nbsp;TimeOn&nbsp;</div></td>');

  if ExTimeOff then
    Write(f,'<td width="'+cqrini.ReadString('Export','Wtime_off','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">&nbsp;TimeOff&nbsp;</div></td>');

  if ExCall then
    Write(f,'<td width="'+cqrini.ReadString('Export','WCallSign','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">Call</div></td>');

  if ExFreq then
    Write(f,'<td width="'+cqrini.ReadString('Export','WFreq','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">Freq</div></td>');

  if ExMode then
    Write(f,'<td width="'+cqrini.ReadString('Export','WMode','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">Mode</div></td>');

  if ExRSTS then
    Write(f,'<td width="'+cqrini.ReadString('Export','WRST_S','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">RST_S</div></td>');

  if ExRSTR then
    Write(f,'<td width="'+cqrini.ReadString('Export','WRST_R','30')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">RSTR</div></td>');

  if ExName then
      Write(f,'<td width="'+cqrini.ReadString('Export','WName','50')+
           '" bgcolor="#333366" class="hlava"><div align="center" class="popis">Name</div></td>');

  if ExQTH then
    Write(f,'<td width="'+cqrini.ReadString('Export','WQTH','80')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">QTH</div></td>');

  if ExQSLS then
    Write(f,'<td width="'+cqrini.ReadString('Export','WQSL_S','10')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">QS</div></td>');

  if ExQSLR then
    Write(f,'<td width="'+cqrini.ReadString('Export','WQSL_R','10')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">QR</div></td>');

  if ExQSLVIA then
    Write(f,'<td width="'+cqrini.ReadString('Export','WQSL_VIA','20')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">QSL_VIA</div></td>');

  if exIOTA then
    Write(f,'<td width="'+cqrini.ReadString('Export','WIOTA','40')+
         '" bgcolor="#333366" class="hlava"><div align="center" class="popis">IOTA</div></td>');

  if ExAward then
    Write(f,'<td width="'+cqrini.ReadString('Export','WAward','40')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">Award</div></td>');
    
  if ExLoc then
    Write(f,'<td width="'+cqrini.ReadString('Export','WLocator','30')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">LOC</div></td>');

  if exMyLoc then
    Write(f,'<td width="'+cqrini.ReadString('Export','WMyLoc','30')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">MyLOC</div></td>');

  if ExPower then
    Write(f,'<td width="'+cqrini.ReadString('Export','WPower','40')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">Power</div></td>');

  if ExCounty then
    Write(f,'<td width="'+cqrini.ReadString('Export','WCounty','40')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">County</div></td>');

  if ExDXCC then
    Write(f,'<td width="'+cqrini.ReadString('Export','WDXCC','40')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">DXCC</div></td>');

  if ExRemarks then
    Write(f,'<td width="'+cqrini.ReadString('Export','WRemarks','100')+
         '" bgcolor="#333366" class="hlava"><div align="center" class="popis">Remarks</div></td>');

  if ExWAZ then
    Write(f,'<td width="'+cqrini.ReadString('Export','WWAZ','20')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">WAZ</div></td>');

  if ExITU then
    Write(f,'<td width="'+cqrini.ReadString('Export','WITU','20')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">ITU</div></td>');

  if exState then
    Write(f,'<td width="'+cqrini.ReadString('Export','WState','20')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">State</div></td>');

  if ExNote then
    Write(f,'<td width="'+cqrini.ReadString('Export','WNote','40')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">Note</div></td>');

  if ExLQslS then
    Write(f,'<td width="'+cqrini.ReadString('Export','WLQslS','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">LOTW_QSLS</div></td>');

  if ExLQslSDate then
    Write(f,'<td width="'+cqrini.ReadString('Export','WLQslSDate','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">LOTW_QSLS date</div></td>');

  if ExLQslR then
    Write(f,'<td width="'+cqrini.ReadString('Export','WLQslR','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">LOTW_QSLR</div></td>');

  if ExLQslRDate then
    Write(f,'<td width="'+cqrini.ReadString('Export','WLQslRDate','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">LOTW_QSLR date</div></td>');
  if ExCont then
    Write(f,'<td width="50"'+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">CONT</div></td>');

  if ExQSLSDate then
    Write(f,'<td width="'+cqrini.ReadString('Export','WQSLSDate','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">QSLS date</div></td>');

  if ExQSLRDate then
    Write(f,'<td width="'+cqrini.ReadString('Export','WQSLRDate','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">QSLR date</div></td>');

  if ExeQslS then
    Write(f,'<td width="'+cqrini.ReadString('Export','WeQslS','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">eQSL_QSLS</div></td>');

  if ExeQslSDate then
    Write(f,'<td width="'+cqrini.ReadString('Export','WeQslSDate','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">eQSL_QSLS date</div></td>');

  if ExeQslR then
    Write(f,'<td width="'+cqrini.ReadString('Export','WeQslR','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">eQSL_QSLR</div></td>');

  if ExeQslRDate then
    Write(f,'<td width="'+cqrini.ReadString('Export','WeQslRDate','50')+
          '" bgcolor="#333366" class="hlava"><div align="center" class="popis">eQSL_QSLR date</div></td>');


  Writeln(f,'</tr>');
                
  i := 0;

  pBarProg.Max := QSOcnt;

  if not dmData.IsFilter then
  begin
    dmData.Q.Close;
    if exAscTime then
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


      SaveData(dmUtils.DateInRightFormat(Source.Fields[1].AsDateTime),//qsodate
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
               eqsl_qslrdate
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
    Writeln(f,'</center>');
    Writeln(f,'<br> <br>');
    Writeln(f,'<h5 align=center> <a href="http://www.cqrlog.com">CQRLOG ver. ' + dmData.VersionString  + ' </a></h5>');
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

