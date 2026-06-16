(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fImportProgress;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls,lcltype, synachar, ExtCtrls, httpsend, blcksock, iniFiles, FileUtil,
  LazFileUtils;

const
  C_EErrorFile ='errors_eQSL.adi';
  C_LErrorFile ='errors_LoTW.adi';

type
  TImportProgressType = (imptRegenerateDXCC, imptImportDXCCTables, imptDownloadDXCCData, imptImportLoTWAdif,
                         imptImportQSLMgrs, imptDownloadQSLData, imptInsertQSLManagers, imptImporteQSLAdif,
                         imptRemoveDupes, imptUpdateMembershipFiles, imptDownloadDOKData);

type

  { TfrmImportProgress }

  TfrmImportProgress = class(TForm)
    lblCount: TLabel;
    lblErrors: TLabel;
    lblComment: TLabel;
    pBarProg: TProgressBar;
    tmrImport: TTimer;
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrImportTimer(Sender: TObject);
  private
    running,
    LocalDbg : Boolean;
    FileSize : Int64;
    procedure ImportDXCCTables;
    procedure RegenerateDXCCStat;
    procedure DownloadDXCCData;
    procedure DownloadDOKData;
    procedure CommonImport(var PosEOR:word;var f:TextFile;var call,band,modeorig,mode,submodeorig,submode,qsodate,time_on,qslr,
                                                      qslrdate,cqz,ituz,iota,grid,state,county,qsorecord:String);
    procedure WriteErrorRecord(f:char;call,band,modeorig,submodeorig,qsodate,time_on,qslr,qslrdate,
                                              cqz,ituz,iota,grid,state,county,qsorecord:string;var s:Tstringlist);
    procedure ImportQSLMgrs;
    procedure DownloadQSLData;
    procedure InsertQSLManagers;
    procedure RemoveDupes;
    procedure UpdateMembershipFiles;

    procedure SockCallBack (Sender: TObject; Reason:  THookSocketReason; const  Value: string);

  public
    ImportType : TImportProgressType;
    FileName   : String;

    Directory  : String;
    CloseAfImport : Boolean;
    LoTWShowNew : Boolean;
    //LoTWUrl - when set, the worker thread downloads the report into FileName first;
    //when empty, FileName is expected to already contain a downloaded report.
    LoTWUrl    : String;
    LoTWSuccess : Boolean;
    LoTWErrMsg : String;
    LoTWQSOList : TStringList;
    eQSLShowNew : Boolean;
    eQSLQSOList : TStringList;
    //eQSLUrl - when set, the worker thread downloads the eQSL inbox into FileName first;
    //when empty, FileName is expected to already contain a downloaded report.
    eQSLUrl    : String;
    eQSLSuccess : Boolean;
    eQSLErrMsg : String;

  end;

var
  frmImportProgress: TfrmImportProgress; 

implementation
{$R *.lfm}
{ TfrmImportProgress }

uses dData, dUtils, fImportTest, dDXCC, uMyini, dLogUpload, dMembership, dSatellite, fAdifImport,
     uInternalConnection, uDbUtils;

type
  //One parsed LoTW QSO record, buffered so a whole batch can be matched against the log
  //with a single SQL query instead of one query per record (critical for a remote DB).
  //lo/hi is the accepted log-time window in minutes-of-day (+-5 min, with the same
  //00:xx / 23:5x edge handling the original per-QSO code used).
  TLotwRec = record
    call, band, mode, modeorig, submodeorig, qsodate, time_on, qslr, qslrdate,
    cqz, ituz, iota, grid, state, county, qsorecord : String;
    lo, hi : Integer;
  end;
  TLotwRecArray = array of TLotwRec;

  //Background worker thread for downloading the LoTW report and importing/matching it
  //against the log. Declared in the same unit as TfrmImportProgress so it can reach the
  //form's private parsing helpers (CommonImport/WriteErrorRecord) - in FPC objfpc mode
  //"private" visibility is per-unit. All GUI access goes through Synchronize.
  TLoTWImportThread = class(TThread)
  private
    FForm        : TfrmImportProgress;
    FConn        : TInternalConnection;
    FSyncStr     : String;
    FErrorCount  : Integer;
    FImportExtra : Boolean;
    FDownloadBytes : Int64;
    FLastShownBytes : Int64;
    procedure SyncComment;
    procedure SyncCount;
    procedure SyncCloseForm;
    procedure SyncErrorsDlg;
    procedure SyncBadHeaderDlg;
    procedure SyncDisableOnlineLog;
    procedure SyncEnableOnlineLog;
    procedure NetStatus(Sender: TObject; Reason: THookSocketReason; const Value: string);
    function  DownloadReport : Boolean;
    procedure RunImport;
    procedure ProcessBatch(var recs: TLotwRecArray; cnt: Integer; var confirmed, errors: Integer; el: TStringList);
  protected
    procedure Execute; override;
  public
    constructor Create(AForm: TfrmImportProgress);
  end;

  //Background worker thread for downloading the eQSL inbox and importing/matching it
  //against the log. Mirrors TLoTWImportThread (see notes above) but with eQSL semantics:
  //two-step download (HTML page -> parse .adi filename -> download ADIF), a +-60 min match
  //window, and the eqsl_qsl_rcvd/eqsl_qslrdate columns. All GUI access goes through Synchronize.
  TeQSLImportThread = class(TThread)
  private
    FForm        : TfrmImportProgress;
    FConn        : TInternalConnection;
    FSyncStr     : String;
    FErrorCount  : Integer;
    FDownloadBytes : Int64;
    FLastShownBytes : Int64;
    procedure SyncComment;
    procedure SyncCount;
    procedure SyncCloseForm;
    procedure SyncErrorsDlg;
    procedure SyncDisableOnlineLog;
    procedure SyncEnableOnlineLog;
    procedure NetStatus(Sender: TObject; Reason: THookSocketReason; const Value: string);
    function  DownloadReport : Boolean;
    procedure RunImport;
    procedure ProcessBatch(var recs: TLotwRecArray; cnt: Integer; var confirmed, errors: Integer; el: TStringList);
  protected
    procedure Execute; override;
  public
    constructor Create(AForm: TfrmImportProgress);
  end;

procedure TfrmImportProgress.FormActivate(Sender: TObject);
begin
  //re-activation while a worker thread runs must not touch the pump timer (see below)
  if running and ((ImportType = imptImportLoTWAdif) or (ImportType = imptImporteQSLAdif)) then
    Exit;
  tmrImport.Enabled := False;
  if not running then
  begin
    running := True;
    case ImportType of
      imptRegenerateDXCC : RegenerateDXCCStat;
      imptImportDXCCTables : ImportDXCCTables;
      imptDownloadDXCCData : DownloadDXCCData;
      imptDownloadDOKData : DownloadDOKData;
      imptImportLoTWAdif : begin
                             TLoTWImportThread.Create(Self).Start;
                             //Keep an NSTimer ticking while the worker runs. On Cocoa the
                             //ShowModal loop otherwise parks in nextEventMatchingMask and is
                             //not reliably woken by the worker's Synchronize, which makes the
                             //UI feel frozen. The timer wakes the run loop ~10x/s so events
                             //and queued Synchronize calls are pumped promptly.
                             tmrImport.Interval := 100;
                             tmrImport.Enabled  := True;
                             Exit
                           end;
      imptImportQSLMgrs : ImportQSLMgrs;
      imptDownloadQSLData  : DownloadQSLData;
      imptInsertQSLManagers : InsertQSLManagers;
      imptImporteQSLAdif : begin
                             //Download and import run in a background thread, same as LoTW.
                             TeQSLImportThread.Create(Self).Start;
                             //Keep an NSTimer ticking while the worker runs so Cocoa's modal
                             //run loop is woken and queued Synchronize calls are pumped.
                             tmrImport.Interval := 100;
                             tmrImport.Enabled  := True;
                             Exit
                           end;
      imptRemoveDupes : RemoveDupes;
      imptUpdateMembershipFiles : UpdateMembershipFiles
    end // case
  end
end;

procedure TfrmImportProgress.FormCreate(Sender: TObject);
begin
  CloseAfImport := False;
  FileSize      := 0;
  LoTWQSOList := TStringList.Create;
  LoTWQSOList.Clear;
  eQSLQSOList := TStringList.Create;
  eQSLQSOList.Clear;
   //set debug rules for this form
  // bit 1, %1,  ---> -2 for routines in this form
  LocalDbg := dmData.DebugLevel >= 1 ;
  if dmData.DebugLevel < 0 then
      LocalDbg :=  LocalDbg or ((abs(dmData.DebugLevel) and 2) = 2 );
end;

procedure TfrmImportProgress.FormDestroy(Sender: TObject);
begin
  LoTWQSOList.Free;
  eQSLQSOList.Free
end;

procedure TfrmImportProgress.FormShow(Sender: TObject);
begin
  running := False;
  dmUtils.LoadFontSettings(self);
  tmrImport.Enabled := True
end;

procedure TfrmImportProgress.tmrImportTimer(Sender: TObject);
begin
  //During a threaded import the timer is left running on purpose: each tick just wakes
  //the Cocoa run loop so events/Synchronize are pumped. Nothing else to do.
  if running and ((ImportType = imptImportLoTWAdif) or (ImportType = imptImporteQSLAdif)) then
    Exit;
  FormActivate(nil)
end;

procedure TfrmImportProgress.ImportDXCCTables;
var
  f        : TStringList;
  i,z,y,c  : Integer;
  Result   : TExplodeArray;
  Prefixes : TExplodeArray;
  ADIF     : Integer;
  List     : TStringList;
  tmp      : String;
begin
  SetLength(Prefixes,0);
  SetLength(Result,0);
  f       := TStringList.Create;
  List    := TStringList.Create;
  List.Clear;
  dmDXCC.qDXCCRef.Close;
  if dmDXCC.trDXCCRef.Active then
    dmDXCC.trDXCCRef.Rollback;

  dmDXCC.trDXCCRef.StartTransaction;
  dmDXCC.qDXCCRef.SQL.Text := 'DELETE FROM cqrlog_common.dxcc_ref';
  dmDXCC.qDXCCRef.ExecSQL;
  dmDXCC.trDXCCRef.Commit;
  c := 0;
  try
    /////////////////////////////////////////////////////////////////////////// country.tab
    dmDXCC.trDXCCRef.StartTransaction;
    f.Clear;
    lblComment.Caption := 'Importing file country.tab ...';
    Application.ProcessMessages;
    f.LoadFromFile(Directory+'Country.tab');

    for z:=0 to f.Count-1 do
    begin
      inc(c);
      Result := dmUtils.Explode('|',f.Strings[z]);
      Prefixes  := dmUtils.Explode(' ',Result[0]);
      ADIF := StrToInt(Result[8]);
      if ADIF > 0 then
      begin
        dmDXCC.qDXCCRef.SQL.Text := 'INSERT INTO cqrlog_common.dxcc_ref (pref,name,cont,utc,lat,'+
                                    'longit,itu,waz,adif,deleted) VALUES ('+
                                    QuotedStr(Prefixes[0])+','+ QuotedStr(Result[1])+','+
                                    QuotedStr(Result[2])+','+QuotedStr(Result[3])+','+
                                    QuotedStr(Result[4])+','+QuotedStr(Result[5])+','+
                                    QuotedStr(Result[6])+','+QuotedStr(Result[7])+','+
                                    IntToStr(ADIF)+',0)';
        if LocalDbg then Writeln(dmDXCC.qDXCCRef.SQL.Text);
        dmDXCC.qDXCCRef.ExecSQL;
      end;
    end;
    List.AddStrings(f);
    dmDXCC.trDXCCRef.Commit;
    ////////////////////////////////////////////////////////////// countrydel.tab
    dmDXCC.trDXCCRef.StartTransaction;
    f.Clear;
    lblComment.Caption := 'Importing file countrydel.tab ...';
    Application.ProcessMessages;
    f.LoadFromFile(Directory+'CountryDel.tab');
    for z:=0 to f.Count-1 do
    begin
      Result := dmUtils.Explode('|',f.Strings[z]);
      Prefixes  := dmUtils.Explode(' ',Result[0]);
      ADIF := StrToInt(Result[8]);
      if ADIF > 0 then
      begin
        dmDXCC.qDXCCRef.SQL.Text := 'INSERT INTO cqrlog_common.dxcc_ref (pref,name,cont,utc,lat,'+
                                    'longit,itu,waz,adif,deleted) VALUES ('+
                                    QuotedStr(Prefixes[0]+'*')+','+ QuotedStr(Result[1])+','+
                                    QuotedStr(Result[2])+','+QuotedStr(Result[3])+','+
                                    QuotedStr(Result[4])+','+QuotedStr(Result[5])+','+
                                    QuotedStr(Result[6])+','+QuotedStr(Result[7])+','+
                                    IntToStr(ADIF)+','+'1'+')';
        if LocalDbg  then
          Writeln(dmDXCC.qDXCCRef.SQL.Text);
        dmDXCC.qDXCCRef.ExecSQL;
      end;
    end;
    dmDXCC.trDXCCRef.Commit;
    f.SaveToFile(dmData.HomeDir+'dxcc_data'+PathDelim+'country_del.tab');

    /////////////////////////////////////////////////////////////////// exceptions.tab
    CopyFile(Directory+'Exceptions.tab',dmData.HomeDir+'dxcc_data'+PathDelim+'exceptions.tab');

    ////////////////////////////////////////////////////////////////// callresolution.tbl
    f.Clear;
    lblComment.Caption := 'Importing file Callresolution.tbl ...';
    Application.ProcessMessages;
    f.LoadFromFile(Directory+'CallResolution.tbl');
    List.AddStrings(f);
    ////////////////////////////////////////////////////////////////// AreaOK1RR.tab

    f.Clear;
    f.LoadFromFile(Directory+'AreaOK1RR.tbl');
    List.AddStrings(f);

    for y:=0 to List.Count-1 do
    begin
      if List.Strings[y][1] = '%' then
      begin
        for i:=65 to 90 do
          list.Add(chr(i)+copy(list.Strings[y],2,Length(list.Strings[y])-1));
      end;
    end;

    List.SaveToFile(dmData.HomeDir+'dxcc_data'+PathDelim+'country.tab');

    //////////////////////////////////////////////////////////// ambigous.tbl;
    CopyFile(Directory+'Ambiguous.tbl',dmData.HomeDir+'dxcc_data'+PathDelim+'ambiguous.tab');

    lblComment.Caption := 'Importing LoTW and eQSL users ...';
    Application.ProcessMessages;

    if FileExistsUTF8(Directory+'lotw1.txt') then
    begin
      DeleteFileUTF8(dmData.HomeDir+'lotw1.txt');
      CopyFile(Directory+'lotw1.txt',dmData.HomeDir+'lotw1.txt');
      dmData.LoadLoTWCalls
    end;

    if FileExistsUTF8(Directory+'eqsl.txt') then
    begin
      DeleteFileUTF8(dmData.HomeDir+'eqsl.txt');
      CopyFile(Directory+'eqsl.txt',dmData.HomeDir+'eqsl.txt');
      dmData.LoadeQSLCalls
    end;

    lblComment.Caption := 'Loading MASTER.SCP ...';
    Application.ProcessMessages;
    if FileExistsUTF8(Directory+'MASTER.SCP') then
    begin
      DeleteFileUTF8(dmData.HomeDir+'MASTER.SCP');
      CopyFile(Directory+'MASTER.SCP',dmData.HomeDir+'MASTER.SCP');
      dmData.LoadMasterSCP
    end;

    if FileExistsUTF8(Directory+'us_states.tab') then
    begin
      DeleteFileUTF8(dmData.HomeDir+'dxcc_data'+PathDelim+'us_states.tab');
      CopyFile(Directory+'us_states.tab',dmData.HomeDir+'dxcc_data'+PathDelim+'us_states.tab')
      //reloading is in dmDXCC.ReloadDXCCTables
    end;

    if FileExistsUTF8(Directory + C_SATELLITE_LIST) then
    begin
      DeleteFileUTF8(dmData.HomeDir + C_SATELLITE_LIST);
      CopyFile(Directory + C_SATELLITE_LIST, dmData.HomeDir + C_SATELLITE_LIST);
      dmSatellite.LoadSatellitesFromFile
    end;

    if FileExistsUTF8(Directory + C_PROP_MODE_LIST) then
    begin
      DeleteFileUTF8(dmData.HomeDir + C_PROP_MODE_LIST);
      CopyFile(Directory + C_PROP_MODE_LIST, dmData.HomeDir + C_PROP_MODE_LIST);
      dmSatellite.LoadPropModesFromFile
    end;

    if FileExistsUTF8(Directory + 'ContestName.tab') then
    begin
      DeleteFileUTF8(dmData.HomeDir + 'ContestName.tab');
      CopyFile(Directory + 'ContestName.tab', dmData.HomeDir + 'ContestName.tab');
    end;

    lblComment.Caption := 'Importing IOTA table ...';
    Application.ProcessMessages;
    dmData.qIOTAList.Close();
    dmData.qIOTAList.SQL.Text := 'DELETE FROM cqrlog_common.iota_list';
    dmData.trIOTAList.StartTransaction;
    dmData.qIOTAList.ExecSQL;
    dmData.trIOTAList.Commit;

    f.Clear;
    f.LoadFromFile(Directory + 'iota.tbl');
    dmData.trIOTAList.StartTransaction;
    for i:= 0 to f.Count-1 do
    begin
      Result := dmUtils.Explode('|',f.Strings[i]);
      if Length(Result) = 3 then
        dmData.qIOTAList.SQL.Text := 'INSERT INTO cqrlog_common.iota_list (iota_nr,island_name,dxcc_ref)'+
                                     ' VALUES ('+QuotedStr(Result[0]) + ',' +
                                     QuotedStr(Result[1]) + ',' + QuotedStr(Result[2]) + ')'
      else begin
        tmp := Result[3];
        if pos('/',tmp) > 0 then
          tmp := Copy(tmp,1,pos('/',tmp)-1)+ '.*' + Copy(tmp,pos('/',tmp),Length(tmp)-pos('/',tmp)+1);
        dmData.qIOTAList.SQL.Text := 'INSERT INTO cqrlog_common.iota_list (iota_nr,island_name,dxcc_ref,pref)'+
                                     ' VALUES ('+QuotedStr(Result[0]) + ',' +
                                     QuotedStr(Result[1]) + ',' + QuotedStr(Result[2])
                                     + ',' + QuotedStr(tmp) + ')';
      end;
      if LocalDbg then
        Writeln(dmData.qIOTAList.SQL.Text);

      if length(Result[1]) > 250 then ShowMessage(Result[0]);
      if length(Result[2]) > 15 then ShowMessage(Result[0]);
      if length(Result) > 3 then
        if length(Result[3]) > 15 then ShowMessage(Result[0]);
      dmData.qIOTAList.ExecSQL;
    end;
    dmData.trIOTAList.Commit;

  finally
    //dmDXCC.trDXCCRef.StartTransaction;
    dmDXCC.qDXCCRef.SQL.Text := 'SELECT * FROM cqrlog_common.dxcc_ref ORDER BY adif';
    dmDXCC.qDXCCRef.Open;
    f.Free;
    List.Free;
    Close
  end
end;

procedure TfrmImportProgress.RegenerateDXCCStat;
var
  i        : Integer;
  adif     : Word;
  old_adif : Word;
  id       : Integer;
  waz      : String;
  itu      : String;
  cont     : String;
  tmp      : String;
begin
  lblComment.Caption := 'Rebuilding DXCC statistics ...';
  Caption := lblComment.Caption;
  waz := '';
  itu := '';
  i   := 0;
  lblCount.Caption := '0';
  dmData.qCQRLOG.DisableControls;
  try try
    lblComment.Caption := 'Rebuilding DXCC statistics ...';
    Repaint;

    if dmData.trQ.Active then dmData.trQ.RollBack;
    dmData.Q.SQL.Text := 'SELECT COUNT(*) FROM cqrlog_main';
    dmData.trQ.StartTransaction;
    dmData.Q.Open;
    pBarProg.Max := dmData.Q.Fields[0].AsInteger;
    dmData.Q.Close;
    dmData.trQ.Rollback;

    dmData.Q1.Close;
    if dmData.trQ1.Active then dmData.trQ1.Rollback;
    dmData.Q1.SQL.Text := 'select id_cqrlog_main,qsodate,callsign,adif,qso_dxcc from cqrlog_main';
    dmData.trQ1.StartTransaction;
    dmData.Q1.Open;
    dmData.Q1.First;

    dmData.trQ.StartTransaction;
    while not dmData.Q1.Eof do
    begin
      inc(i);
      if dmData.Q1.Fields[4].AsInteger > 0 then
      begin
        dmData.Q1.Next;
        pBarProg.StepIt;
        Continue
      end
      else begin
        old_adif := dmData.Q1.Fields[3].AsInteger;
        id       := dmData.qCQRLOG.Fields[0].AsInteger;
        adif     := dmDXCC.id_country(dmData.Q1.Fields[2].AsString, dmUtils.StrToDateFormat(
                                      dmData.Q1.Fields[1].AsString),
                                      tmp, cont, tmp, waz, tmp, itu, tmp, tmp);
        if adif<>old_adif then
        begin
          cont := copy(cont,1,2);
          dmUtils.ModifyWAZITU(waz,itu);
          if adif =  0 then
            dmData.Q.SQL.Text := 'UPDATE cqrlog_main SET adif=0,waz=null,itu=null,cont=null WHERE id_cqrlog_main='+IntToStr(id)
          else
            dmData.Q.SQL.Text := 'UPDATE cqrlog_main SET adif='+IntToStr(adif)+',waz ='+waz+',itu ='+itu+',cont='+QuotedStr(cont)+' WHERE id_cqrlog_main='+IntToStr(id);
          dmData.Q.ExecSQL
        end
      end;
      dmData.Q1.Next;
      pBarProg.StepIt;
      lblCount.Caption := IntToStr(i);
      if (i mod 100 = 0) then
      begin
        Repaint;
        Application.ProcessMessages
      end
    end
  except
    on E : Exception do
    begin
      Writeln('Exception: ',E.Message);
      dmData.trQ.RollBack
    end
  end;
  dmData.trQ.Commit
  finally
    dmData.Q1.Close;
    dmData.trQ1.Rollback;
    dmData.qCQRLOG.Close;
    dmData.qCQRLOG.Open;
    dmData.qCQRLOG.EnableControls
  end;
  Close
end;

procedure TfrmImportProgress.DownloadDXCCData;
var
  HTTP   : THTTPSend;
  m      : TFileStream;
begin
  FileName := dmData.HomeDir+'ctyfiles/cqrlog-cty.tar.gz';
  if FileExists(FileName) then
    DeleteFile(FileName);
  http   := THTTPSend.Create;
  m      := TFileStream.Create(FileName,fmCreate);
  try
    HTTP.Sock.OnStatus := @SockCallBack;
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');

    if HTTP.HTTPMethod('GET', 'http://www.ok2cqr.com/linux/cqrlog/ctyfiles/cqrlog-cty.tar.gz') then
    begin
      http.Document.Seek(0,soBeginning);
      m.CopyFrom(http.Document,HTTP.Document.Size);
      if dmUtils.UnTarFiles(FileName,ExtractFilePath(FileName)) then
      begin
        Directory := ExtractFilePath(FileName);
        ImportDXCCTables
      end;
    end;
  finally
    http.Free;
    m.Free;
  end
end;

procedure TfrmImportProgress.DownloadDOKData;
var
  HTTP   : THTTPSend;
  m      : TFileStream;
begin
  FileName := dmData.HomeDir+'dok_data/doks.tar.gz';
  if FileExists(FileName) then
    DeleteFile(FileName);
  http   := THTTPSend.Create;
  m      := TFileStream.Create(FileName,fmCreate);
  try
    HTTP.Sock.OnStatus := @SockCallBack;
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');

    if HTTP.HTTPMethod('GET', 'https://www.df2et.de/cqrlog/doks.tar.gz') then
    begin
      http.Document.Seek(0,soBeginning);
      m.CopyFrom(http.Document,HTTP.Document.Size);
      if dmUtils.UnTarFiles(FileName,ExtractFilePath(FileName)) then
      begin
        Directory := ExtractFilePath(FileName);
      end;
    end;
  finally
    http.Free;
    m.Free;
    Close;
  end
end;

procedure TfrmImportProgress.DownloadQSLData;
var
  HTTP   : THTTPSend;
  m      : TFileStream;
begin
  FileName := dmData.HomeDir+'ctyfiles'+PathDelim+'qslmgr.tar.gz';
  if FileExists(FileName) then
    DeleteFile(FileName);
  http   := THTTPSend.Create;
  m      := TFileStream.Create(FileName,fmCreate);
  try
    HTTP.Sock.OnStatus := @SockCallBack;
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');
    if HTTP.HTTPMethod('GET', 'http://www.ok2cqr.com/linux/cqrlog/qslmgr/qslmgr.tar.gz') then
    begin
      http.Document.Seek(0,soBeginning);
      m.CopyFrom(http.Document,HTTP.Document.Size);
      if dmUtils.UnTarFiles(FileName,ExtractFilePath(FileName)) then
      begin
        Directory := ExtractFilePath(FileName);
        FileName  := Directory + 'qslmgr.csv';
        ImportQSLMgrs
      end;
    end;
  finally
    http.Free;
    m.Free;
  end
end;

procedure TfrmImportProgress.SockCallBack (Sender: TObject; Reason:   THookSocketReason; const  Value: string);
begin
  if Reason = HR_ReadCount then
  begin
    FileSize := FileSize + StrToInt(Value);
    lblCount.Caption := IntToStr(FileSize);
    Repaint;
    Application.ProcessMessages;
  end;
end;
procedure TfrmImportProgress.CommonImport(var PosEOR:word;var f:TextFile;var call,band,modeorig,mode,submodeorig,submode,qsodate,time_on,qslr,
                                                      qslrdate,cqz,ituz,iota,grid,state,county,qsorecord:String);
var
  a,
  prik,
  data,
  Cstamp,
  Dstamp,
  Buf  :string;

Begin
  Buf:='';
  Dstamp:=FormatDateTime('YYYYMMDD',Now);
  while not ((PosEOR > 0) or eof(f)) do //combine one record. LoTW adif has one tag per line
    Begin
     Readln(f, a);
     a      := Trim(a);
     PosEOR := Pos('<EOR>',UpperCase(a));
     Buf    := Buf+a;
    end;
  if Pos('<EOR>',UpperCase(Buf))=0 then
     Buf:=buf+'<EOR>'; //in case we have broken record in broken file (hit eof before it is time)
  if LocalDbg then
                  Writeln('one record read: ',Buf);

//here we add some stuff to every record received. It does not mess up "qso in log" checking
//but makes record to be ready for write to error log if qso was not found in log
//=====================================
  //check SWL and is so change contest_id to find those easier
  //if there is tag QSLMSG move data of it to (comment to qso).
  if pos('APP_EQSL_SWL:1>Y',uppercase(buf))>0 then
              Begin
               Cstamp:= '<CONTEST_ID:25>SWL_was_not_found_in_log!';
               Buf:=StringReplace(buf,'<QSLMSG:','<COMMENT:',[rfIgnoreCase]); //SWL should inform "qso with", put it to Comment field
               Buf:=StringReplace(buf,'<RST_RCVD:0>','<RST_SENT+:3>SWL',[rfIgnoreCase]); //we need this for temp use
               Buf:=StringReplace(buf,'<RST_SENT:','<RST_RCVD:',[rfIgnoreCase]); //generate RST_s as "SWL" for own log (upload to eQSL)
               Buf:=StringReplace(buf,'<RST_SENT+:','<RST_SENT:',[rfIgnoreCase]);
              end
              else
              Begin
               Cstamp:= '<CONTEST_ID:25>Qso_was_not_found_in_log!';
               if pos('APP_LOTW',uppercase(buf))=0 then  //it is eQSL
                 begin
                     Cstamp:= Cstamp+LineEnding+'<APP_CQRLOG_NOTE:61>RST sent/rcvd are swapped to be ready for import to your log!'
                     +LineEnding+'<APP_CQRLOG_NOTE:43>You have to fix your RST_SENT after import!';
                     Buf:=StringReplace(buf,'<RST_RCVD:','<RST_SENT+:',[rfIgnoreCase]); //swap sent/rcvd for own log import
                     Buf:=StringReplace(buf,'<RST_SENT:','<RST_RCVD:',[rfIgnoreCase]);
                     Buf:=StringReplace(buf,'<RST_SENT+:','<RST_SENT:',[rfIgnoreCase]);
                 end;

              end;

  //Here we create a qso record that has comment and lotw+eqsl sent set.
  //user can add this record to log to get rid of lotw/eqsl error "Not found in log"
  //in case this qso is really wanted to be confirmed (maybe is SWL report) user can wipe out
  //the first 1-3 lines (lotw,eqsl sent, comment) and import only the last line to log and so
  //it will be added to log and sent to lotw/eqsl during next upload
  qsorecord:= '<LOTW_QSL_SENT:1>Y<LOTW_QSLSDATE:8>'+Dstamp+'<APP_CQRLOG_NOTE:36>This line prevents reupload to LoTW'
              +LineEnding+'<EQSL_QSL_SENT:1>Y<EQSL_QSLSDATE:8>'+Dstamp+'<APP_CQRLOG_NOTE:36>This line prevents reupload to eQSL'
              +LineEnding+Cstamp
              +LineEnding+Buf;
//=====================================

mode := ''; //be sure there is no mode at this point
  repeat
   begin
     if frmAdifImport.getNextAdifTag(Buf,prik,data) then
       if LocalDbg then
         Begin
          write(prik,'->');
          writeln(data);
         end;
          case uppercase(prik) of
           'CALL'       : call    := uppercase(data);
           'GRIDSQUARE' : if dmUtils.IsLocOK(data) then
                             grid := dmUtils.StdFormatLocator(data);
                        //if not mode set by submode then set mode
           'MODE'       : mode    := uppercase(data);
           'SUBMODE'    : submode := uppercase(data);
           'BAND'       : band    := uppercase(data);
           'QSO_DATE'   : qsodate := data;
           'TIME_ON'    : time_on := data;
           'IOTA'       : iota    := data;
           'STATE'      : state   := data;
           'CQZ'        : cqz     := data;
           'ITUZ'       : ituz    := data;
           'CNTY'       : county  := data;
           'QSL_RCVD'   : qslr    :=uppercase(data);
           'QSLRDATE'   : qslrdate:= data;
          end; //case
       end;  //repeat
  until (pos('<EOR>',uppercase(Buf))=1) or (prik='EOR');
  //store original modes
  modeorig:=uppercase(mode);
  submodeorig:=uppercase(submode);
  //after this line mode will be changed to Cqrmode. submodeorig & modeorig has orignal ones stored for possible error reports
  mode :=dmUtils.ModeToCqr(mode,submode,LocalDbg);
end;
procedure TfrmImportProgress.WriteErrorRecord(f:char;call,band,modeorig,submodeorig,qsodate,time_on,qslr,qslrdate,
                                              cqz,ituz,iota,grid,state,county,qsorecord:string;var s:Tstringlist);
var
  l,
  tmp:String;


Begin
             tmp:=LineEnding
                  +'------------------------------------------------'+LineEnding
                  +'QSO NOT FOUND in log'+LineEnding
                  +'Call:     '+call+LineEnding
                  +'Band:     '+band+LineEnding
                  +'Mode:     '+modeorig+LineEnding
                  +'Submode:  '+submodeorig+lineEnding
                  +'QSO_date: '+qsodate+LineEnding
                  +'Time_on:  '+time_on+LineEnding;
             if f='L' then
               begin
                 tmp:=tmp
                 +'QSLR:     '+qslr+LineEnding
                 +'QSLRDate: '+qslrdate+LineEnding
                 +'CQZ:      '+cqz+LineEnding
                 +'ITUZ:     '+ituz+LineEnding
                 +'IOTA:     '+iota+LineEnding
                 +'Grid:     '+grid+LineEnding
                 +'State:    '+state+LineEnding
                 +'County:   '+county+LineEnding;
               end;
             tmp:=tmp+'------------------------------------------------'+LineEnding;
             l:=IntToStr(length(tmp));
             //end of APP_CQRLOG_ERROR tag
             tmp:=tmp
             +qsorecord+LineEnding
             +LineEnding;

             s.Add('<APP_CQRLOG_ERROR:'+l+'>'+tmp);

end;
constructor TLoTWImportThread.Create(AForm: TfrmImportProgress);
begin
  inherited Create(True);
  FForm := AForm;
  FreeOnTerminate := True
end;

procedure TLoTWImportThread.SyncComment;
begin
  FForm.pBarProg.Visible   := False;
  FForm.lblComment.Caption := FSyncStr;
  FForm.Repaint
end;

procedure TLoTWImportThread.SyncCount;
begin
  FForm.lblCount.Caption := FSyncStr;
  FForm.Repaint
end;

procedure TLoTWImportThread.SyncCloseForm;
begin
  FForm.tmrImport.Enabled := False;
  FForm.ModalResult := mrOk
end;

procedure TLoTWImportThread.SyncErrorsDlg;
begin
  if Application.MessageBox(PChar(IntToStr(FErrorCount)+' QSO(s) were not found in your log.'+LineEnding+
                           'QSO(s) are stored to '+dmData.UsrHomeDir + C_LErrorFile +
                           LineEnding+LineEnding+'Do you want to show the file?'),
                           'Question ....',mb_YesNo+mb_IconQuestion)=idYes then
    frmAdifImport.OpenInTextEditor(dmData.UsrHomeDir + C_LErrorFile)
end;

procedure TLoTWImportThread.SyncBadHeaderDlg;
begin
  if Application.MessageBox('Something is wrong because LoTW server returned invalid adif file header.'+LineEnding+
                           'Your LoTW username/password could be wrong or LoTW server is down.'+LineEnding+LineEnding+
                           'Do you want to show the file?',
                           'Error ...',mb_YesNo+mb_IconQuestion) = idYes then
    frmAdifImport.OpenInTextEditor(FForm.FileName)
end;

procedure TLoTWImportThread.SyncDisableOnlineLog;
begin
  dmLogUpload.DisableOnlineLogSupport
end;

procedure TLoTWImportThread.SyncEnableOnlineLog;
begin
  dmLogUpload.EnableOnlineLogSupport(False)
end;

procedure TLoTWImportThread.NetStatus(Sender: TObject; Reason: THookSocketReason; const Value: string);
begin
  if Reason = HR_ReadCount then
  begin
    FDownloadBytes := FDownloadBytes + StrToInt(Value);
    //throttle GUI updates - refresh at most every 64 kB instead of on every socket read
    if FDownloadBytes - FLastShownBytes >= 65536 then
    begin
      FLastShownBytes := FDownloadBytes;
      FSyncStr := 'Downloading from LoTW ... ' + IntToStr(FDownloadBytes) + ' bytes';
      Synchronize(@SyncComment)
    end
  end
end;

function TLoTWImportThread.DownloadReport : Boolean;
var
  http : THTTPSend;
  m    : TFileStream;
begin
  Result := False;
  if FForm.LoTWUrl = '' then //nothing to download, file is expected to be present already
  begin
    Result := FileExists(FForm.FileName);
    if not Result then
      FForm.LoTWErrMsg := 'File does not exist: ' + FForm.FileName;
    Exit
  end;

  FSyncStr := 'Connecting to LoTW server ...';
  Synchronize(@SyncComment);
  FDownloadBytes := 0;
  FLastShownBytes := 0;
  http := THTTPSend.Create;
  m    := TFileStream.Create(FForm.FileName, fmCreate);
  try
    http.Sock.OnStatus := @NetStatus;
    http.ProxyHost := cqrini.ReadString('Program','Proxy','');
    http.ProxyPort := cqrini.ReadString('Program','Port','');
    http.UserName  := cqrini.ReadString('Program','User','');
    http.Password  := cqrini.ReadString('Program','Passwd','');
    http.MimeType  := 'text/xml';
    http.Protocol  := '1.1';
    if http.HTTPMethod('GET', FForm.LoTWUrl) then
    begin
      http.Document.Seek(0, soBeginning);
      m.CopyFrom(http.Document, http.Document.Size);
      Result := True
    end
    else begin
      FForm.LoTWErrMsg := 'Download failed (' + IntToStr(http.Sock.LastError) + '): ' + http.Sock.LastErrorDesc;
      Result := False
    end
  finally
    http.Free;
    m.Free
  end
end;

procedure TLoTWImportThread.Execute;
begin
  try
    if DownloadReport then
      RunImport
  finally
    Synchronize(@SyncCloseForm)
  end
end;

//Match one batch of LoTW records against the log with a SINGLE query.
//Instead of one SELECT per QSO (tens of thousands of round-trips to a remote DB), we fetch
//the candidate log rows for the whole batch at once with a (callsign,qsodate,band) IN (...)
//tuple list. Backed by the composite (callsign,qsodate,band) index that is part of the log
//schema (db version 20), the server does one indexed lookup per tuple and returns only the
//exact call+date+band matches (0-1 rows each, never the
//hundreds of QSOs a single callsign may have). The remaining mode/time (+-5 min) matching is
//done in memory. The per-row UPDATE is unchanged from the previous version.
procedure TLoTWImportThread.ProcessBatch(var recs: TLotwRecArray; cnt: Integer; var confirmed, errors: Integer; el: TStringList);
type
  TCandRow = record
    callsign, qsodate, band, time_on, mode, lotw_qslr, loc, state, county, id : String;
  end;
var
  i, j, nc, logMin : Integer;
  sql : String;
  cand : array of TCandRow;
  found : Boolean;
  mId, mQslr, mLoc, mState, mCounty : String;
begin
  if cnt = 0 then Exit;

  sql := 'select callsign,qsodate,band,time_on,mode,lotw_qslr,loc,state,county,id_cqrlog_main '+
         'from cqrlog_main where (callsign,qsodate,band) in (';
  for i := 0 to cnt-1 do
  begin
    if i > 0 then sql := sql + ',';
    sql := sql + '(' + QuotedStr(recs[i].call) + ',' + QuotedStr(recs[i].qsodate) + ',' + QuotedStr(recs[i].band) + ')'
  end;
  sql := sql + ')';

  FConn.Q.Close;
  FConn.Q.SQL.Text := sql;
  FConn.Q.Open;
  nc := 0;
  SetLength(cand, 256);
  while not FConn.Q.Eof do
  begin
    if nc >= Length(cand) then
      SetLength(cand, Length(cand)*2);
    cand[nc].callsign  := FConn.Q.Fields[0].AsString;
    cand[nc].qsodate   := FConn.Q.Fields[1].AsString;
    cand[nc].band      := FConn.Q.Fields[2].AsString;
    cand[nc].time_on   := FConn.Q.Fields[3].AsString;
    cand[nc].mode      := FConn.Q.Fields[4].AsString;
    cand[nc].lotw_qslr := FConn.Q.Fields[5].AsString;
    cand[nc].loc       := FConn.Q.Fields[6].AsString;
    cand[nc].state     := FConn.Q.Fields[7].AsString;
    cand[nc].county    := FConn.Q.Fields[8].AsString;
    cand[nc].id        := FConn.Q.Fields[9].AsString;
    inc(nc);
    FConn.Q.Next
  end;
  FConn.Q.Close;

  for i := 0 to cnt-1 do
  begin
    found := False;
    mId := ''; mQslr := ''; mLoc := ''; mState := ''; mCounty := '';
    for j := 0 to nc-1 do
    begin
      if (cand[j].callsign = recs[i].call) and
         (cand[j].qsodate  = recs[i].qsodate) and
         (cand[j].band     = recs[i].band) and
         ((cand[j].mode = recs[i].mode) or (cand[j].mode = recs[i].modeorig) or (cand[j].mode = recs[i].submodeorig)) then
      begin
        if Length(cand[j].time_on) >= 5 then
          logMin := StrToIntDef(copy(cand[j].time_on,1,2),-1)*60 + StrToIntDef(copy(cand[j].time_on,4,2),0)
        else
          logMin := -1;
        if (logMin >= recs[i].lo) and (logMin <= recs[i].hi) then
        begin
          found  := True;
          mQslr  := cand[j].lotw_qslr;
          mLoc   := cand[j].loc;
          mState := cand[j].state;
          mCounty:= cand[j].county;
          mId    := cand[j].id;
          cand[j].lotw_qslr := 'L'; //mark used so a duplicate LoTW record in this batch won't re-confirm it
          Break
        end
      end
    end;

    if found and (mQslr <> 'L') then
    begin
      if FForm.LoTWShowNew then
        FForm.LoTWQSOList.Add(recs[i].qsodate + ' ' + recs[i].call + ' ' + recs[i].band + ' ' + recs[i].mode);
      FConn.Q2.Close;
      FConn.Q2.SQL.Clear;
      FConn.Q2.SQL.Add('update cqrlog_main set lotw_qslr = ' + QuotedStr('L'));
      FConn.Q2.SQL.Add(',lotw_qslrdate = ' + QuotedStr(recs[i].qslrdate));
      if FImportExtra then
      begin
        if recs[i].cqz  <> '' then FConn.Q2.SQL.Add(',waz = ' + QuotedStr(recs[i].cqz));
        if recs[i].ituz <> '' then FConn.Q2.SQL.Add(',itu = ' + QuotedStr(recs[i].ituz));
        if recs[i].iota <> '' then FConn.Q2.SQL.Add(',iota = ' + QuotedStr(recs[i].iota));
        if (recs[i].grid   <> '') and (mLoc = '')    then FConn.Q2.SQL.Add(',loc = ' + QuotedStr(recs[i].grid));
        if (recs[i].state  <> '') and (mState = '')  then FConn.Q2.SQL.Add(',state = ' + QuotedStr(recs[i].state));
        if (recs[i].county <> '') and (mCounty = '') then FConn.Q2.SQL.Add(',county = ' + QuotedStr(recs[i].county))
      end;
      FConn.Q2.SQL.Add(' where id_cqrlog_main = ' + mId);
      FConn.Q2.ExecSQL;
      inc(confirmed)
    end;

    if not found then
    begin
      FForm.WriteErrorRecord('L',recs[i].call,recs[i].band,recs[i].modeorig,recs[i].submodeorig,recs[i].qsodate,
                             recs[i].time_on,recs[i].qslr,recs[i].qslrdate,recs[i].cqz,recs[i].ituz,recs[i].iota,
                             recs[i].grid,recs[i].state,recs[i].county,recs[i].qsorecord,el);
      inc(errors)
    end
  end
end;

procedure TLoTWImportThread.RunImport;
const
  BATCH = 500;
var
  num      : Integer = 0;
  qsln     : Integer = 0;
  a        : String;
  f        : TextFile;
  PosEOH   : Word;
  PosEOR   : Word;
  qsorecord,call,band,mode,modeorig,submode,submodeorig,qsodate,time_on,
  qslr,qslrdate,cqz,ituz,iota,grid,state,county : String;
  ErrorCount  : Integer = 0;
  l           : TStringList;
  ignoreOnline: Boolean;
  recs        : TLotwRecArray;
  rc          : Integer;
  lotwMin     : Integer;
begin
  //config read once before the loop (was read per-QSO before)
  FImportExtra := cqrini.ReadBool('LoTWImp','Import',True);
  ignoreOnline := cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) and dmLogUpload.LogUploadEnabled;

  FConn := GetNewInternalConnection();

  l := TStringList.Create;
  l.Add('<ADIF_VER:5>3.1.0');
  l.Add('<CREATED_TIMESTAMP:15>'+FormatDateTime('YYYYMMDD hhmmss',dmUtils.GetDateTime(0)));
  l.Add('LoTW import errors from CQRLOG for Linux version '+dmData.VersionString);
  l.Add('Copyright (C) '+FormatDateTime('YYYY',now)+' by Petr, OK2CQR and Martin, OK1RR');
  l.Add('');
  l.Add('Internet: http://www.cqrlog.com');
  l.Add('');
  l.Add('<EOH>');
  l.Add('');
  AssignFile(f,FForm.FileName);
  SetLength(recs,BATCH);

  try
    if ignoreOnline then
      Synchronize(@SyncDisableOnlineLog);

    FConn.T.StartTransaction;
    Reset(f);
    FSyncStr := 'Importing LoTW Adif file ...';
    Synchronize(@SyncComment);
    PosEOH := 0;
    PosEOR := 0;
    while (PosEOH = 0) and (not eof(f)) do //Skip header
    begin
      Readln(f, a);
      a      := UpperCase(a);
      PosEOH := Pos('<EOH>', a)
    end;
    if PosEOH > 0 then //we have valid lotw adif output
    begin
      rc := 0;
      while not eof(f) do
      begin
        call:=''; band:=''; mode:=''; modeorig:=''; submode:=''; submodeorig:='';
        qsodate:=''; time_on:=''; qslr:=''; qslrdate:=''; cqz:=''; ituz:='';
        iota:=''; grid:=''; state:=''; county:='';
        PosEOR := 0;
        while not ((PosEOR > 0) or eof(f)) do //read all records
        begin
          FForm.CommonImport(PosEOR,f,call,band,modeorig,mode,submodeorig,submode,qsodate,time_on,qslr,
                        qslrdate,cqz,ituz,iota,grid,state,county,qsorecord);
          //from now on the mode is converted to Cqrmode
          if PosEOR > 0 then
          begin
            band     := dmUtils.GetBandFromFreq(dmUtils.FreqFromBand(band,'CW'));
            qsodate  := dmUtils.ADIFDateToDate(qsodate);
            qslrdate := dmUtils.ADIFDateToDate(qslrdate);
            lotwMin  := StrToIntDef(copy(time_on,1,2),0)*60 + StrToIntDef(copy(time_on,3,2),0);

            recs[rc].call        := call;
            recs[rc].band        := band;
            recs[rc].mode        := mode;
            recs[rc].modeorig    := modeorig;
            recs[rc].submodeorig := submodeorig;
            recs[rc].qsodate     := qsodate;
            recs[rc].time_on     := time_on;
            recs[rc].qslr        := qslr;
            recs[rc].qslrdate    := qslrdate;
            recs[rc].cqz         := cqz;
            recs[rc].ituz        := ituz;
            recs[rc].iota        := iota;
            recs[rc].grid        := grid;
            recs[rc].state       := state;
            recs[rc].county      := county;
            recs[rc].qsorecord   := qsorecord;
            //accepted log-time window in minutes-of-day (same edge handling as the original)
            if copy(time_on,1,2)='00' then
              recs[rc].lo := 0
            else
              recs[rc].lo := lotwMin - 5;
            if lotwMin > (23*60+54) then
              recs[rc].hi := 23*60+59
            else
              recs[rc].hi := lotwMin + 5;

            inc(rc);
            inc(num);
            if rc = BATCH then
            begin
              ProcessBatch(recs,rc,qsln,ErrorCount,l);
              rc := 0;
              //commit periodically so row locks on cqrlog_main are released frequently and
              //the main thread / bandmap / RBN threads don't block on a long-held transaction
              FConn.T.CommitRetaining;
              FSyncStr := IntToStr(num);
              Synchronize(@SyncCount)
            end
          end
        end
      end;
      if rc > 0 then
        ProcessBatch(recs,rc,qsln,ErrorCount,l);
      FConn.T.Commit;
      FForm.LoTWSuccess := True;
      FSyncStr := IntToStr(num);
      Synchronize(@SyncCount);
      if ErrorCount > 0 then
      begin
        l.SaveToFile(dmData.UsrHomeDir + C_LErrorFile);
        FErrorCount := ErrorCount;
        Synchronize(@SyncErrorsDlg)
      end
    end
    else
      Synchronize(@SyncBadHeaderDlg)
  finally
    if FConn.T.Active then
      FConn.T.Rollback;
    l.Free;
    CloseFile(f);
    FreeAndNil(FConn);
    if ignoreOnline then
      Synchronize(@SyncEnableOnlineLog)
  end
end;

procedure TfrmImportProgress.ImportQSLMgrs;
const
  C_INS = 'INSERT INTO cqrlog_common.qslmgr (callsign,qsl_via,fromdate) VALUES (:callsign,:qsl_via, :fromdate)';
var
  sF : TextFile;
  a  : TExplodeArray;
  call     : String = '';
  qsl_via  : String = '';
  fromDate : String = '';
  line     : String = '';
  num      : Word = 1;
  e        : Boolean = False;
begin
  lblComment.Caption := 'Importing QSL managers ...';
  AssignFile(sF,FileName);
  FileMode := 0;
  {$I-}
  Reset(sF);
  {$I+}
  if IOResult <> 0 then
  begin
    Application.MessageBox(PChar('Can not open source file ' + FileName + ' for reading!'),'Error ...',mb_ok+
                           mb_IconError);
    exit
  end;
  Application.ProcessMessages;
  Repaint;
  try try
    dmData.qQSLMgr.Close;
    if dmData.trQSLMgr.Active then dmData.trQSLMgr.Rollback;
    dmData.trQSLMgr.StartTransaction;
    dmData.qQSLMgr.SQL.Text := 'delete from cqrlog_common.qslmgr';
    dmData.qQSLMgr.ExecSQL;
    dmData.qQSLMgr.SQL.Text := C_INS;
    while not Eof(sF) do
    begin
      readln(sF,line);
      Writeln('Line: ',line);
      a := dmUtils.Explode(';',line);
      call     := a[0];
      qsl_via  := a[1];
      fromDate := a[2]+'-01';


      dmData.qQSLMgr.Prepare;
      dmData.qQSLMgr.Params[0].AsString := call;
      dmData.qQSLMgr.Params[1].AsString := qsl_via;
      dmData.qQSLMgr.Params[2].AsString := fromDate;
      dmData.qQSLMgr.ExecSQL;

      inc(num);
      lblCount.Caption := IntToStr(num);
      if num mod 100 = 0 then
        Repaint
    end
  except
    on Ex : Exception do
    begin
      dmData.trQSLMgr.Rollback;
      e := True;
      Writeln(Ex.Message)
    end
  end
  finally
    CloseFile(sF);
    if not e then
      dmData.trQSLMgr.Commit
  end;
  Close
end;

procedure TfrmImportProgress.InsertQSLManagers;
var
  qsl_via : String = '';
  i : Integer = 0;
begin
  dmData.qCQRLOG.Last; //to get proper count
  lblComment.Caption := 'Inserting QSL managers ...';
  pBarProg.Max := dmData.qCQRLOG.RecordCount;
  Application.ProcessMessages;
  dmData.qCQRLOG.DisableControls;
  try
    dmData.qCQRLOG.First;
    while not dmData.qCQRLOG.Eof do
    begin
      if (dmData.qCQRLOG.FieldByName('qsl_via').AsString = '') and
         dmData.QSLMgrFound(dmData.qCQRLOG.Fields[4].AsString,dmData.qCQRLOG.Fields[1].AsString,qsl_via) then
      begin
        dmData.trQ.StartTransaction;
        dmData.Q.SQL.Text := 'update cqrlog_main set qsl_via = ' + QuotedStr(qsl_via) +
                             ' where id_cqrlog_main = '+ IntToStr(dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger);
        if LocalDbg then Writeln(dmData.Q.SQL.Text);
        dmData.Q.ExecSQL;
        dmData.trQ.Commit
      end;
      dmData.qCQRLOG.Next;
      pBarProg.StepIt;
      inc(i);
      if i mod 100 = 0 then
        Application.ProcessMessages
    end
  finally
    dmData.qCQRLOG.EnableControls
  end;
  Close
end;

constructor TeQSLImportThread.Create(AForm: TfrmImportProgress);
begin
  inherited Create(True);
  FForm := AForm;
  FreeOnTerminate := True
end;

procedure TeQSLImportThread.SyncComment;
begin
  FForm.pBarProg.Visible   := False;
  FForm.lblComment.Caption := FSyncStr;
  FForm.Repaint
end;

procedure TeQSLImportThread.SyncCount;
begin
  FForm.lblCount.Caption := FSyncStr;
  FForm.Repaint
end;

procedure TeQSLImportThread.SyncCloseForm;
begin
  FForm.tmrImport.Enabled := False;
  FForm.ModalResult := mrOk
end;

procedure TeQSLImportThread.SyncErrorsDlg;
begin
  if Application.MessageBox(PChar(IntToStr(FErrorCount)+' QSO(s) were not found in your log.'+LineEnding+
                           'QSO(s) are stored to '+dmData.UsrHomeDir + C_EErrorFile +
                           LineEnding+LineEnding+'Do you want to show the file?'),
                           'Question ....',mb_YesNo+mb_IconQuestion)=idYes then
    frmAdifImport.OpenInTextEditor(dmData.UsrHomeDir + C_EErrorFile)
end;

procedure TeQSLImportThread.SyncDisableOnlineLog;
begin
  dmLogUpload.DisableOnlineLogSupport
end;

procedure TeQSLImportThread.SyncEnableOnlineLog;
begin
  dmLogUpload.EnableOnlineLogSupport(False)
end;

procedure TeQSLImportThread.NetStatus(Sender: TObject; Reason: THookSocketReason; const Value: string);
begin
  if Reason = HR_ReadCount then
  begin
    FDownloadBytes := FDownloadBytes + StrToInt(Value);
    //throttle GUI updates - refresh at most every 64 kB instead of on every socket read
    if FDownloadBytes - FLastShownBytes >= 65536 then
    begin
      FLastShownBytes := FDownloadBytes;
      FSyncStr := 'Downloading from eQSL ... ' + IntToStr(FDownloadBytes) + ' bytes';
      Synchronize(@SyncComment)
    end
  end
end;

//Two-step eQSL inbox download: GET the DownloadInBox.cfm page, parse the .adi filename out
//of the returned HTML, then GET the actual ADIF file. Mirrors the old main-thread code from
//feQSLDownload.btnDownloadClick, moved here so the UI stays responsive.
function TeQSLImportThread.DownloadReport : Boolean;
const
  //it is better to seek the file suffix than the old way
  CDWNLD = '.adi">';
var
  http : THTTPSend;
  m    : TFileStream;
  l    : TStringList;
  url, tmp : String;
  i    : Integer;
begin
  Result := False;
  if FForm.eQSLUrl = '' then //nothing to download, file is expected to be present already
  begin
    Result := FileExists(FForm.FileName);
    if not Result then
      FForm.eQSLErrMsg := 'File does not exist: ' + FForm.FileName;
    Exit
  end;

  FSyncStr := 'Connecting to eQSL server ...';
  Synchronize(@SyncComment);
  FDownloadBytes := 0;
  FLastShownBytes := 0;
  http := THTTPSend.Create;
  m    := TFileStream.Create(FForm.FileName, fmCreate);
  l    := TStringList.Create;
  try
    http.Sock.OnStatus := @NetStatus;
    http.ProxyHost := cqrini.ReadString('Program','Proxy','');
    http.ProxyPort := cqrini.ReadString('Program','Port','');
    http.UserName  := cqrini.ReadString('Program','User','');
    http.Password  := cqrini.ReadString('Program','Passwd','');
    http.MimeType  := 'text/xml';
    http.Protocol  := '1.1';
    if not http.HTTPMethod('GET', FForm.eQSLUrl) then
    begin
      FForm.eQSLErrMsg := 'Download failed (' + IntToStr(http.Sock.LastError) + '): ' + http.Sock.LastErrorDesc;
      Exit
    end;
    http.Document.Seek(0, soBeginning);
    l.LoadFromStream(http.Document);
    http.Clear;
    if pos('Error: No such Username/Password found', l.Text) > 0 then
    begin
      FForm.eQSLErrMsg := 'Error: No such Username/Password found';
      Exit
    end;
    if pos(CDWNLD, l.Text) <= 0 then
    begin
      FForm.eQSLErrMsg := 'eQSL page was probably changed, cannot find the link to ADIF file';
      Exit
    end;
    //find the line that holds the link and parse the .adi filename out of it
    tmp := '';
    for i := 0 to pred(l.Count) do
      if pos(CDWNLD, l[i]) > 0 then
      begin
        tmp := copy(l[i], pos('HREF="', l[i])+6, length(l[i])); //start point
        tmp := copy(l[i], 1, pos('.adi"', l[i])+3);             //endpoint
        tmp := ExtractFileNameOnly(tmp) + ExtractFileExt(tmp)
      end;
    url := cqrini.ReadString('LoTW', 'eQSLDnlAddr', 'https://www.eqsl.cc/downloadedfiles/') + tmp;
    if dmData.DebugLevel > 0 then Writeln('url: ', url);
    FDownloadBytes := 0;
    FLastShownBytes := 0;
    if http.HTTPMethod('GET', url) then
    begin
      http.Document.Seek(0, soBeginning);
      m.CopyFrom(http.Document, http.Document.Size);
      Result := True
    end
    else
      FForm.eQSLErrMsg := 'File was NOT downloaded! Error: ' +
                          IntToStr(http.Sock.LastError) + ' ' + http.Sock.LastErrorDesc
  finally
    http.Free;
    m.Free;
    l.Free
  end
end;

procedure TeQSLImportThread.Execute;
begin
  try
    if DownloadReport then
      RunImport
  finally
    Synchronize(@SyncCloseForm)
  end
end;

//Match one batch of eQSL records against the log with a SINGLE query, the same way
//TLoTWImportThread.ProcessBatch does (see its note). eQSL differences: matches/updates the
//eqsl_qsl_rcvd / eqsl_qslrdate columns, a record already marked 'E' counts as found but is not
//re-confirmed, the match time window is +-60 min, and no extra fields are imported.
procedure TeQSLImportThread.ProcessBatch(var recs: TLotwRecArray; cnt: Integer; var confirmed, errors: Integer; el: TStringList);
type
  TCandRow = record
    callsign, qsodate, band, time_on, mode, eqsl_qslr, id : String;
  end;
var
  i, j, nc, logMin : Integer;
  sql, nowStr : String;
  cand : array of TCandRow;
  found : Boolean;
  mId, mRcvd : String;
begin
  if cnt = 0 then Exit;

  sql := 'select callsign,qsodate,band,time_on,mode,eqsl_qsl_rcvd,id_cqrlog_main '+
         'from cqrlog_main where (callsign,qsodate,band) in (';
  for i := 0 to cnt-1 do
  begin
    if i > 0 then sql := sql + ',';
    sql := sql + '(' + QuotedStr(recs[i].call) + ',' + QuotedStr(recs[i].qsodate) + ',' + QuotedStr(recs[i].band) + ')'
  end;
  sql := sql + ')';

  FConn.Q.Close;
  FConn.Q.SQL.Text := sql;
  FConn.Q.Open;
  nc := 0;
  SetLength(cand, 256);
  while not FConn.Q.Eof do
  begin
    if nc >= Length(cand) then
      SetLength(cand, Length(cand)*2);
    cand[nc].callsign  := FConn.Q.Fields[0].AsString;
    cand[nc].qsodate   := FConn.Q.Fields[1].AsString;
    cand[nc].band      := FConn.Q.Fields[2].AsString;
    cand[nc].time_on   := FConn.Q.Fields[3].AsString;
    cand[nc].mode      := FConn.Q.Fields[4].AsString;
    cand[nc].eqsl_qslr := FConn.Q.Fields[5].AsString;
    cand[nc].id        := FConn.Q.Fields[6].AsString;
    inc(nc);
    FConn.Q.Next
  end;
  FConn.Q.Close;

  nowStr := dmUtils.DateInRightFormat(now);

  for i := 0 to cnt-1 do
  begin
    found := False;
    mId := ''; mRcvd := '';
    for j := 0 to nc-1 do
    begin
      if (cand[j].callsign = recs[i].call) and
         (cand[j].qsodate  = recs[i].qsodate) and
         (cand[j].band     = recs[i].band) and
         ((cand[j].mode = recs[i].mode) or (cand[j].mode = recs[i].modeorig) or (cand[j].mode = recs[i].submodeorig)) then
      begin
        if Length(cand[j].time_on) >= 5 then
          logMin := StrToIntDef(copy(cand[j].time_on,1,2),-1)*60 + StrToIntDef(copy(cand[j].time_on,4,2),0)
        else
          logMin := -1;
        if (logMin >= recs[i].lo) and (logMin <= recs[i].hi) then
        begin
          found := True;
          mRcvd := cand[j].eqsl_qslr;
          mId   := cand[j].id;
          cand[j].eqsl_qslr := 'E'; //mark used so a duplicate eQSL record in this batch won't re-confirm it
          Break
        end
      end
    end;

    if found and (mRcvd <> 'E') then
    begin
      if FForm.eQSLShowNew then
        FForm.eQSLQSOList.Add(recs[i].qsodate + ' ' + recs[i].call + ' ' + recs[i].band + ' ' + recs[i].mode);
      FConn.Q2.Close;
      FConn.Q2.SQL.Clear;
      FConn.Q2.SQL.Add('update cqrlog_main set eqsl_qsl_rcvd = ' + QuotedStr('E'));
      FConn.Q2.SQL.Add(',eqsl_qslrdate = ' + QuotedStr(nowStr));
      FConn.Q2.SQL.Add(' where id_cqrlog_main = ' + mId);
      FConn.Q2.ExecSQL;
      inc(confirmed)
    end;

    if not found then
    begin
      FForm.WriteErrorRecord('E',recs[i].call,recs[i].band,recs[i].modeorig,recs[i].submodeorig,recs[i].qsodate,
                             recs[i].time_on,recs[i].qslr,recs[i].qslrdate,recs[i].cqz,recs[i].ituz,recs[i].iota,
                             recs[i].grid,recs[i].state,recs[i].county,recs[i].qsorecord,el);
      inc(errors)
    end
  end
end;

procedure TeQSLImportThread.RunImport;
const
  BATCH = 500;
var
  num      : Integer = 0;
  qsln     : Integer = 0;
  f        : TextFile;
  PosEOH   : Word;
  PosEOR   : Word;
  qsorecord,call,band,mode,modeorig,submode,submodeorig,qsodate,time_on,
  qslr,qslrdate,cqz,ituz,iota,grid,state,county : String;
  ErrorCount  : Integer = 0;
  l           : TStringList;
  ignoreOnline: Boolean;
  recs        : TLotwRecArray;
  rc          : Integer;
  eqslMin     : Integer;
begin
  ignoreOnline := cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) and dmLogUpload.LogUploadEnabled;

  FConn := GetNewInternalConnection();

  l := TStringList.Create;
  l.Add('<ADIF_VER:5>3.1.0');
  l.Add('<CREATED_TIMESTAMP:15>'+FormatDateTime('YYYYMMDD hhmmss',dmUtils.GetDateTime(0)));
  l.Add('eQSL import errors from CQRLOG for Linux version '+dmData.VersionString);
  l.Add('Copyright (C) '+FormatDateTime('YYYY',now)+' by Petr, OK2CQR and Martin, OK1RR');
  l.Add('');
  l.Add('Internet: http://www.cqrlog.com');
  l.Add('');
  l.Add('<EOH>');
  l.Add('');
  AssignFile(f,FForm.FileName);
  SetLength(recs,BATCH);

  try
    if ignoreOnline then
      Synchronize(@SyncDisableOnlineLog);

    FConn.T.StartTransaction;
    Reset(f);
    FSyncStr := 'Importing eQSL Adif file ...';
    Synchronize(@SyncComment);
    PosEOH := 0;
    PosEOR := 0;
    while (PosEOH = 0) and (not eof(f)) do //Skip header
    begin
      Readln(f, qsorecord);
      qsorecord := UpperCase(qsorecord);
      PosEOH    := Pos('<EOH>', qsorecord)
    end;
    if PosEOH > 0 then //we have a valid adif header
    begin
      rc := 0;
      while not eof(f) do
      begin
        call:=''; band:=''; mode:=''; modeorig:=''; submode:=''; submodeorig:='';
        qsodate:=''; time_on:=''; qslr:=''; qslrdate:=''; cqz:=''; ituz:='';
        iota:=''; grid:=''; state:=''; county:='';
        PosEOR := 0;
        while not ((PosEOR > 0) or eof(f)) do //read all records
        begin
          FForm.CommonImport(PosEOR,f,call,band,modeorig,mode,submodeorig,submode,qsodate,time_on,qslr,
                        qslrdate,cqz,ituz,iota,grid,state,county,qsorecord);
          //from now on the mode is converted to Cqrmode
          if PosEOR > 0 then
          begin
            qsodate := dmUtils.ADIFDateToDate(qsodate);
            eqslMin := StrToIntDef(copy(time_on,1,2),0)*60 + StrToIntDef(copy(time_on,3,2),0);

            recs[rc].call        := call;
            recs[rc].band        := band;
            recs[rc].mode        := mode;
            recs[rc].modeorig    := modeorig;
            recs[rc].submodeorig := submodeorig;
            recs[rc].qsodate     := qsodate;
            recs[rc].time_on     := time_on;
            recs[rc].qslr        := qslr;
            recs[rc].qslrdate    := qslrdate;
            recs[rc].cqz         := cqz;
            recs[rc].ituz        := ituz;
            recs[rc].iota        := iota;
            recs[rc].grid        := grid;
            recs[rc].state       := state;
            recs[rc].county      := county;
            //accepted log-time window in minutes-of-day (+-60 min, with the same 00:xx / 23:xx
            //edge handling the original per-QSO code used - the SQL pins the date so we can not
            //cross midnight in either direction)
            if copy(time_on,1,2)='00' then
              recs[rc].lo := 0
            else
              recs[rc].lo := eqslMin - 60;
            if copy(time_on,1,2)='23' then
              recs[rc].hi := 23*60+59
            else
              recs[rc].hi := eqslMin + 60;

            inc(rc);
            inc(num);
            if rc = BATCH then
            begin
              ProcessBatch(recs,rc,qsln,ErrorCount,l);
              rc := 0;
              //commit periodically so row locks on cqrlog_main are released frequently
              FConn.T.CommitRetaining;
              FSyncStr := IntToStr(num);
              Synchronize(@SyncCount)
            end
          end
        end
      end;
      if rc > 0 then
        ProcessBatch(recs,rc,qsln,ErrorCount,l);
      FConn.T.Commit;
      FForm.eQSLSuccess := True;
      FSyncStr := IntToStr(num);
      Synchronize(@SyncCount);
      if ErrorCount > 0 then
      begin
        l.SaveToFile(dmData.UsrHomeDir + C_EErrorFile);
        FErrorCount := ErrorCount;
        Synchronize(@SyncErrorsDlg)
      end
    end
    else
      FForm.eQSLErrMsg := 'Invalid adif file header - the downloaded file does not look like an eQSL report.'
  finally
    if FConn.T.Active then
      FConn.T.Rollback;
    l.Free;
    CloseFile(f);
    FreeAndNil(FConn);
    if ignoreOnline then
      Synchronize(@SyncEnableOnlineLog)
  end
end;

procedure TfrmImportProgress.RemoveDupes;
var
  err : Boolean = False;
begin
  Caption := 'Remove dupes from the log';
  lblComment.Caption := 'Creating temporary table';
  Application.ProcessMessages;
  try try
    dmData.trQ.StartTransaction;
    dmData.Q.SQL.Text := 'create table tempdupes like cqrlog_main';
    if LocalDbg then Writeln(dmData.Q.SQL.Text);
    dmData.Q.ExecSQL;
    dmData.trQ.Commit;

    lblComment.Caption := 'Checking for dupe QSOs';
    Application.ProcessMessages;
    sleep(200);

    dmData.trQ.StartTransaction;
    dmData.Q.SQL.Text := 'insert into tempdupes ' +
                         '  select * from cqrlog_main group by qsodate,time_on,callsign,mode,band';
    if LocalDbg then Writeln(dmData.Q.SQL.Text);
    dmData.Q.ExecSQL;

    dmData.Q.SQL.Text := 'delete from cqrlog_main';
    if LocalDbg then Writeln(dmData.Q.SQL.Text);
    dmData.Q.ExecSQL;

    dmData.Q.SQL.Text := 'insert into cqrlog_main select * from tempdupes';
    if LocalDbg then Writeln(dmData.Q.SQL.Text);
    dmData.Q.ExecSQL
  except
    on E : Exception do
    begin
      Application.MessageBox(PChar('ERROR:'+E.Message+LineEnding),'Error ..',mb_OK+mb_IconError);
      err := True
    end
  end
  finally
    if err then
      dmData.trQ.Rollback
    else
      dmData.trQ.Commit;

    lblComment.Caption := 'Done ...';
    Application.ProcessMessages;
    Sleep(500);

    dmData.trQ.StartTransaction;
    dmData.Q.SQL.Text := 'drop table tempdupes';
    dmData.Q.ExecSQL;
    dmData.trQ.Commit;
    Close
  end
end;

procedure TfrmImportProgress.UpdateMembershipFiles;

  procedure SaveMembershipFile(l : TStringList; ClubFileName : String);
  begin
    if not DirectoryExistsUTF8(dmData.HomeDir + 'members') then
      CreateDirUTF8(dmData.HomeDir + 'members');
    l.SaveToFile(dmData.HomeDir + 'members' + DirectorySeparator + ClubFileName)
  end;

  procedure ImportMembeshipFileToDatabase(l : TStringList; ClubFileName : String);
  const
    C_INS = 'insert into %s (club_nr,clubcall,fromdate,todate) values (:club_nr, :clubcall, :fromdate, :todate)';
  var
    ClubTableName : String;
    i : Integer;
    y : Integer;
    ClubLine : TMembershipLine;
  begin
    ClubTableName := dmMembership.GetClubTableName(ClubFileName);
    pBarProg.Position := 0;
    pBarProg.Max := l.Count-1;

    dmData.q.Close;
    try try
      dmData.trQ.StartTransaction;
      dmData.Q.SQL.Text := 'TRUNCATE TABLE ' + ClubTableName;
      dmData.Q.ExecSQL;
      for i:=0 to l.Count-1 do
      begin
        //ship file header
        if (i < 2) then
          Continue;

        ClubLine := dmMembership.GetMembershipStructure(l.Strings[i]);

        dmData.Q.SQL.Text := Format(C_INS, [ClubTableName]);
        dmData.Q.Prepare;
        dmData.Q.Params[0].AsString := ClubLine.club_nr;
        dmData.Q.Params[1].AsString := ClubLine.club_call;
        dmData.Q.Params[2].AsString := ClubLine.fromdate;
        dmData.Q.Params[3].AsString := ClubLine.todate;
        dmData.Q.ExecSQL;
        pBarProg.StepIt;
        Application.ProcessMessages
      end
    except
      on E : Exception do
      begin
        Application.MessageBox(PChar('ERROR:' + LineEnding + LineEnding + E.ToString), 'Error', mb_OK + mb_IconError);
        dmData.trQ.Rollback
      end
    end
    finally
      dmData.Q.Close;
      if dmData.trQ.Active then
        dmData.trQ.Commit
    end
  end;

var
  i : Integer;
  ClubFileNameWithPath : String;
  ClubFileName : String;
  data : String;
  l : TStringList;
begin
  Application.ProcessMessages;
  l := TStringList.Create;
  try try
    for i:=0 to dmMembership.ListOfMembershipFilesForUpdate.Count-1 do
    begin
      if (dmMembership.ListOfMembershipFilesForUpdate.Strings[i] = '') then
        Continue;

      l.Clear;
      ClubFileNameWithPath := dmMembership.ListOfMembershipFilesForUpdate.Strings[i];
      ClubFileName := ExtractFileName(ClubFileNameWithPath);

      lblComment.Caption := 'Downloading ' + ClubFileName;
      Application.ProcessMessages;

      if dmUtils.GetDataFromHttp(Format(C_MEMBERSHIP_DOWNLOAD_URL,[ClubFileName]), data) then
      begin
        l.Add(data);

        lblComment.Caption := 'Importing ' + ClubFileName;
        Application.ProcessMessages;

        SaveMembershipFile(l, ClubFileName);
        //without loading again whole data was in one line only
        l.Clear;
        l.LoadFromFile(dmData.HomeDir + 'members' + DirectorySeparator + ClubFileName);

        ImportMembeshipFileToDatabase(l, ClubFileName);

        dmMembership.SaveLastMembershipUpdateDate(ClubFileName, now());
      end
    end
  except
    on E : Exception do
      Application.MessageBox(PChar('ERROR:' + LineEnding + LineEnding + E.ToString), 'Error', mb_OK + mb_IconError)
  end
  finally
    FreeAndNil(l)
  end;
  Close
end;

end.

