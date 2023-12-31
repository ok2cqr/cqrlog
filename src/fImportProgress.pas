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
    procedure ImportLoTWAdif;
    procedure ImportQSLMgrs;
    procedure DownloadQSLData;
    procedure InsertQSLManagers;
    procedure ImporteQSLAdif;
    procedure RemoveDupes;
    procedure UpdateMembershipFiles;

    procedure SockCallBack (Sender: TObject; Reason:  THookSocketReason; const  Value: string);

  public
    ImportType : TImportProgressType;
    FileName   : String;

    Directory  : String;
    CloseAfImport : Boolean;
    LoTWShowNew : Boolean;
    LoTWQSOList : TStringList;
    eQSLShowNew : Boolean;
    eQSLQSOList : TStringList;

  end;

var
  frmImportProgress: TfrmImportProgress; 

implementation
{$R *.lfm}
{ TfrmImportProgress }

uses dData, dUtils, fImportTest, dDXCC, uMyini, dLogUpload, dMembership, dSatellite, fAdifImport;

procedure TfrmImportProgress.FormActivate(Sender: TObject);
begin
  tmrImport.Enabled := False;
  if not running then
  begin
    running := True;
    case ImportType of
      imptRegenerateDXCC : RegenerateDXCCStat;
      imptImportDXCCTables : ImportDXCCTables;
      imptDownloadDXCCData : DownloadDXCCData;
      imptDownloadDOKData : DownloadDOKData;
      imptImportLoTWAdif : ImportLoTWAdif;
      imptImportQSLMgrs : ImportQSLMgrs;
      imptDownloadQSLData  : DownloadQSLData;
      imptInsertQSLManagers : InsertQSLManagers;
      imptImporteQSLAdif : ImporteQSLAdif;
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
procedure TfrmImportProgress.ImportLoTWAdif;
var
  num      : Word = 1;
  qsln     : Word = 0;
  size     : Word;
  sSize    : String;
  a        : String;
  orig     : String;
  f        : TextFile;
  PosEOH   : Word;
  PosEOR   : Word;
  qsorecord,
  call,
  band,
  mode,
  modeorig,
  submode,
  submodeorig,
  qsodate,
  time_on,
  qslr,
  qslrdate,
  cqz,
  ituz,
  iota,
  grid,
  state,
  county   : String;

  qso_in_log  : Boolean = False;
  ErrorCount  : Word = 0;
  l           : TStringList;
  t_lotw : TDateTime;
  t_lotw_min,t_lotw_max  : TDateTime;
  t_log : TDateTime;

begin
  if dmData.trQ.Active then
    dmData.trQ.RollBack;
  if dmData.trQ1.Active then
    dmData.trQ1.RollBack;


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
  AssignFile(f,FileName);

  try
    if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) and dmLogUpload.LogUploadEnabled then
      dmLogUpload.DisableOnlineLogSupport;

    dmData.trQ1.StartTransaction;
    dmData.trQ.StartTransaction;
    Reset(f);
    lblComment.Caption := 'Importing LoTW Adif file ...';
    pBarProg.Visible   := False;
    Repaint;
    PosEOH := 0;
    PosEOR := 0;
    while (PosEOH = 0) and (not eof(f)) do //Skip header
    begin
      Readln(f, a);
      a      := UpperCase(a);
      PosEOH := Pos('<EOH>', a);
    end;
    if PosEOH > 0 then //we have valid lotw adif output
    begin
      while not eof(f) do
      begin
        call     := '';
        band     := '';
        mode     := '';
        modeorig := '';
        submode  := '';
        submodeorig := '';
        qsodate  := '';
        time_on  := '';
        qslr     := '';
        qslrdate := '';
        cqz      := '';
        ituz     := '';
        iota     := '';
        grid     := '';
        state    := '';
        county   := '';
        PosEOR   := 0;
        while not ((PosEOR > 0) or eof(f)) do //read all records
        begin
          qso_in_log := False;
          CommonImport(PosEOR,f,call,band,modeorig,mode,submodeorig,submode,qsodate,time_on,qslr,
                        qslrdate,cqz,ituz,iota,grid,state,county,qsorecord);
          //for now on the mode is converted Cqrmode
          if PosEOR > 0 then
          begin
            if LocalDbg  then
            begin
              Writeln('------------------------------------------------');
              Writeln('Record Number:   ',IntToStr(qsln));
              Writeln('Call:     ',call);
              Writeln('Band:     ',band);
              Writeln('Mode:     ',modeorig);
              Writeln('Submode:  ',submodeorig);
              Writeln('Cqrmode:  ',mode);
              Writeln('QSO_date: ',qsodate);
              Writeln('Time_on:  ',time_on);
              Writeln('QSLR:     ',qslr);
              Writeln('QSLRDate: ',qslrdate);
              Writeln('CQZ:      ',cqz);
              Writeln('ITUZ:     ',ituz);
              Writeln('IOTA:     ',iota);
              Writeln('Grid:     ',grid);
              Writeln('State:    ',state);
              Writeln('County:   ',county);
              Writeln('------------------------------------------------')
            end;
            band  := dmUtils.GetBandFromFreq(dmUtils.FreqFromBand(band,'CW'));
            qsodate  := dmUtils.ADIFDateToDate(qsodate);
            qslrdate := dmUtils.ADIFDateToDate(qslrdate);

            dmData.Q.Close;
            //we compare Cqrmode in log to mode and submode received and Cqrmode created.
            //If any of these is ok, qso is ok by mode.
            //this makes backward compatible to old cqrlog loggings.
            //Actually qso is ok even without mode check if other items fit!
            dmData.Q.SQL.Text := 'select time_on,lotw_qslr,waz,itu,iota,loc,state,county,id_cqrlog_main from cqrlog_main ' +
                                 'where (qsodate ='+QuotedStr(qsodate)+') '+
                                 'and (band = ' + QuotedStr(band) + ')'+
                                 'and ('+
                                      '(mode = ' + QuotedStr(mode) +') or '+
                                      '(mode = ' + QuotedStr(modeorig)+') or '+
                                      '(mode = ' + QuotedStr(submodeorig)+') '+
                                      ')' +
                                 'and (callsign = ' + QuotedStr(call) + ')';
            if LocalDbg then Writeln(dmData.Q.SQL.Text);
            //if dmData.trQ.Active then dmData.trQ.Rollback;
            //dmData.trQ.StartTransaction;
            dmData.Q.Open();
            dmData.Q.First;
            if dmData.Q.Eof then  qso_in_log := False;
            while not dmData.Q.Eof do
            begin
              qso_in_log := False;

              t_lotw := EncodeTime(StrToInt(copy(time_on,1,2)),
                        StrToInt(copy(time_on,3,2)),0,0);

              t_log := EncodeTime(StrToInt(copy(dmData.Q.Fields[0].AsString,1,2)),
                        StrToInt(copy(dmData.Q.Fields[0].AsString,4,2)),0,0);

             if copy(time_on,1,2)='00' then
                t_lotw_min := 0      //if lotw time is from 1st hour 00:00-00:59 low limit must be set to 00:00
              else                   //as day is set at sql query and we can not go backwards to yesterday
                t_lotw_min := t_lotw-5/1440;

             if t_lotw > EncodeTime(23,54,0,0) then
                t_lotw_max :=EncodeTime(23,59,0,0)
                                     //this fails too in qsos past 23:54 as we can not set high limit to next day
              else                   //as day is set at sql query and we can not go forward to tomorrow
                t_lotw_max := t_lotw+5/1440;

              if LocalDbg  then Writeln(call,'|',TimeToStr(t_log),' | ',TimeToStr(t_lotw_min),'|',TimeToStr(t_lotw_max));

              if (t_log >=t_lotw_min) and (t_log<=t_lotw_max)  then
              begin
                if (dmData.Q.Fields[1].AsString <> 'L') then
                begin
                  if LoTWShowNew then  //this qso is already confirmed
                    LoTWQSOList.Add(qsodate+ ' ' + call + ' ' + band + ' ' + mode);
                  dmData.Q1.Close;
                  dmData.Q1.SQL.Clear;
                  dmData.Q1.SQL.Add('update cqrlog_main set lotw_qslr = ' + QuotedStr('L'));
                  dmData.Q1.SQL.Add(',lotw_qslrdate = ' + QuotedStr(qslrdate));
                  if cqrini.ReadBool('LoTWImp','Import',True) then
                    Begin
                      if cqz<>'' then
                        dmData.Q1.SQL.Add(',waz = ' + QuotedStr(cqz));
                      if ituz<>'' then
                        dmData.Q1.SQL.Add(',itu = ' + QuotedStr(ituz));
                      if iota<>'' then
                        dmData.Q1.SQL.Add(',iota = ' + QuotedStr(iota));
                      if (grid <> '') and (dmData.Q.Fields[5].AsString='') then
                        dmData.Q1.SQL.Add(',loc = ' + QuotedStr(grid));
                      if (state<>'') and (dmData.Q.Fields[6].AsString='') then
                        dmData.Q1.SQL.Add(',state = ' + QuotedStr(state));
                      if (county<>'') and (dmData.Q.Fields[7].AsString='') then
                        dmData.Q1.SQL.Add(',county = ' + QuotedStr(county));
                    end;
                  dmData.Q1.SQL.Add(' where id_cqrlog_main = ' + dmData.Q.Fields[8].AsString);
                  inc(qsln);
                  if LocalDbg then Writeln(dmData.Q1.SQL.Text+ '  qsl number:'+ IntToStr(qsln));
                  dmData.Q1.ExecSQL
                end;
                qso_in_log := True;
                Break
              end;
              dmData.Q.Next
            end;
            if not qso_in_log then
            begin
              WriteErrorRecord('L',call,band,modeorig,submodeorig,qsodate,time_on,qslr,qslrdate,cqz,ituz,iota,grid,state,county,qsorecord,l);
              inc(ErrorCount)
            end
          end
        end;
        inc(num);
        lblCount.Caption:= IntToStr(num);
        if num mod 100 = 0 then
          Repaint
      end;
      dmData.trQ1.Commit;
      if ErrorCount > 0 then
      begin
        l.SaveToFile(dmData.UsrHomeDir + C_LErrorFile);
        if Application.MessageBox(PChar(IntToStr(ErrorCount)+' QSO(s) were not found in your log.'+LineEnding+'QSO(s) are stored to '+dmData.UsrHomeDir + C_LErrorFile +
                                  LineEnding+LineEnding+'Do you want to show the file?'),'Question ....',mb_YesNo+mb_IconQuestion)=idYes then
          frmAdifImport.OpenInTextEditor(dmData.UsrHomeDir + C_LErrorFile)
      end
    end
    else begin
      if Application.MessageBox('Something is wrong because LoTW server returned invalid adif file header.'+LineEnding+
                                'Your LoTW username/password could be wrong or LoTW server is down.'+LineEnding+LineEnding+'Do you want to show the file?',
                                'Error ...',mb_YesNo+mb_IconQuestion) = idYes then
        frmAdifImport.OpenInTextEditor(FileName)
    end
  finally
    dmData.Q.Close();
    if dmData.trQ.Active then
      dmData.trQ.Rollback;
    if dmData.trQ1.Active then
      dmData.trQ1.Rollback;
    l.Free;
    CloseFile(f);
    if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) and dmLogUpload.LogUploadEnabled then
      dmLogUpload.EnableOnlineLogSupport(False)
  end;
  Close
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

procedure TfrmImportProgress.ImporteQSLAdif;
var
  f        : TextFile;
  num      : Word = 1;
  size,
  PosEOH,
  PosEOR   : Word;
  sSize,
  a,
  orig,
  qsorecord,
  call,
  band,
  mode,
  modeorig,
  submode,
  submodeorig,
  qsodate,
  time_on,
  qslr,
  qslrdate,
  cqz,
  ituz,
  iota,
  grid,
  state,
  county,
  Buf         : String;

  PosCall,
  PosBand,
  PosMode,
  PosSubmode,
  PosQsoDate,
  PosTime_on,
  PosQslr     : Word;

  qso_in_log  : Boolean = False;
  ErrorCount  : Word = 0;
  l           : TStringList;
  t_eQSL,
  t_eQSL_min,
  t_eQSL_max,
  t_log       : TDateTime;

begin
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
  if dmData.trQ.Active then
    dmData.trQ.RollBack;
  if dmData.trQ1.Active then
    dmData.trQ1.RollBack;

  if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) then
    dmLogUpload.DisableOnlineLogSupport;

  dmData.trQ1.StartTransaction;
  dmData.trQ.StartTransaction;
  try
    AssignFile(f,FileName);
    Reset(f);
    lblComment.Caption := 'Importing eQSL Adif file ...';
    pBarProg.Visible   := False;
    Repaint;
    PosEOH := 0;
    PosEOR := 0;
    while not (PosEOH > 0) do //Skip header
    begin
      Readln(f, a);
      a      := UpperCase(a);
      PosEOH := Pos('<EOH>', a);
    end;
    while not eof(f) do
    begin
      call     := '';
      band     := '';
      modeorig := '';
      mode     := '';
      submodeorig
               := '';
      submode  := '';
      qsodate  := '';
      time_on  := '';
      qslr     := '';
      //these are not needed with eQSL
      qslrdate := '';
      cqz      := '';
      ituz     := '';
      iota     := '';
      grid     := '';
      state    := '';
      county   := '';

      PosEOR   := 0;


      while not ((PosEOR > 0) or eof(f)) do
      begin
        qso_in_log := False;
        CommonImport(PosEOR,f,call,band,modeorig,mode,submodeorig,submode,qsodate,time_on,qslr,
                        qslrdate,cqz,ituz,iota,grid,state,county,qsorecord);
        //for now on the mode is converted Cqrmode
        if PosEOR > 0 then
        begin
          if LocalDbg then
          begin
            Writeln('------------------------------------------------');
            Writeln('Call:     ',call);
            Writeln('Band:     ',band);
            Writeln('Mode:     ',modeorig);
            Writeln('Submode:  ',submodeorig);
            Writeln('CqrMode:  ',mode);
            Writeln('QSO_date: ',qsodate);
            Writeln('Time_on:  ',time_on);
            Writeln('QSLR:     ',qslr);
            Writeln('------------------------------------------------');
          end;
          qsodate  := dmUtils.ADIFDateToDate(qsodate);

          dmData.Q.Close;

          //we compare Cqrmode in log to mode and submode received and Cqrmode created.
          //If any of these is ok, qso is ok by mode.
          //this makes backward compatible to old cqrlog loggings.
          //Actually qso is ok even without mode check if other items fit!
          dmData.Q.SQL.Text := 'select id_cqrlog_main,eqsl_qsl_rcvd,time_on from cqrlog_main ' +
                                 'where (qsodate ='+QuotedStr(qsodate)+') '+
                                 'and ('+
                                      '(mode = ' + QuotedStr(mode) +') or '+
                                      '(mode = ' + QuotedStr(modeorig)+') or '+
                                      '(mode = ' + QuotedStr(submodeorig)+') '+
                                      ')' +
                                 'and (band = ' + QuotedStr(band) + ') '+
                                 'and (callsign = ' + QuotedStr(call) + ')';

          if LocalDbg  then Writeln(dmData.Q.SQL.Text);
          //if dmData.trQ.Active then dmData.trQ.Rollback;
          //dmData.trQ.StartTransaction;
          dmData.Q.Open();
          dmData.Q.First;
          if dmData.Q.Eof then  qso_in_log := False;
          while not dmData.Q.Eof do
          begin
            qso_in_log := False;

            t_eQSL := EncodeTime(StrToInt(copy(time_on,1,2)),
                      StrToInt(copy(time_on,3,2)),0,0);

            t_log  := EncodeTime(StrToInt(copy(dmData.Q.Fields[2].AsString,1,2)),
                      StrToInt(copy(dmData.Q.Fields[2].AsString,4,2)),0,0);

             if copy(time_on,1,2)='00' then
                t_eQSL_min := 0      //if eqsl time is from 1st hour 00:00-00:59 low limit must be set to 00:00
              else                   //as day is set at sql query and we can not go backwards to yesterday
                t_eQSL_min := t_eQSL-60/1440;

            if copy(time_on,1,2)='23' then
                t_eQSL_max :=EncodeTime(23,59,0,0)
                                     //this fails too in qsos past 23:xx as we can not set high limit to next day
              else                   //as day is set at sql query and we can not go forward to tomorrow
                t_eQSL_max := t_eQSL+60/1440;

            if LocalDbg  then Writeln(call,'|',TimeToStr(t_log),' | ',TimeToStr(t_eQSL_min),'|',TimeToStr(t_eQSL_max));

            if (t_log >=t_eQSL_min) and (t_log<=t_eQSL_max)  then
            begin
              if eQSLShowNew and (dmData.Q.Fields[1].AsString <> 'E') then
                eQSLQSOList.Add(qsodate+ ' ' + call + ' ' + band + ' ' + mode);
              if (dmData.Q.Fields[1].AsString <> 'E') then
              begin
                dmData.Q1.Close;
                dmData.Q1.SQL.Clear;
                dmData.Q1.SQL.Add('update cqrlog_main set eqsl_qsl_rcvd = ' + QuotedStr('E'));
                dmData.Q1.SQL.Add(',eqsl_qslrdate = ' + QuotedStr(dmUtils.DateInRightFormat(now)));
                dmData.Q1.SQL.Add(' where id_cqrlog_main = ' + dmData.Q.Fields[0].AsString);
                if LocalDbg then Writeln(dmData.Q1.SQL.Text);
                dmData.Q1.ExecSQL
              end;
              qso_in_log := True;
              Break //should only be one qso confirmed, if we have several answers we stop looping those if found one match
            end;
            dmData.Q.Next
          end;
          if not qso_in_log then
          begin
            WriteErrorRecord('E',call,band,modeorig,submodeorig,qsodate,time_on,qslr,qslrdate,cqz,ituz,iota,grid,state,county,qsorecord,l);
            inc(ErrorCount)
          end
        end
      end;
      inc(num);
      lblCount.Caption:= IntToStr(num);
      if num mod 100 = 0 then
        Repaint
    end;
    dmData.trQ1.Commit;
    CloseFile(f);
    if ErrorCount > 0 then
    begin
      l.SaveToFile(dmData.UsrHomeDir + C_EErrorFile);
      if Application.MessageBox(PChar(IntToStr(ErrorCount)+' QSO(s) were not found in your log.'+LineEnding+'QSO(s) are stored to '+dmData.UsrHomeDir + C_EErrorFile +
                                LineEnding+LineEnding+'Do you want to show the file?'),'Question ....',mb_YesNo+mb_IconQuestion)=idYes then
      frmAdifImport.OpenInTextEditor(dmData.UsrHomeDir + C_EErrorFile)
    end
  finally
    l.Free;
    if cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False) then
      dmLogUpload.EnableOnlineLogSupport(False);
    Close
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

