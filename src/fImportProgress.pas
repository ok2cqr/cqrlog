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

type
  TImportProgressType = (imptRegenerateDXCC, imptImportDXCCTables, imptDownloadDXCCData, imptImportLoTWAdif,
                         imptImportQSLMgrs, imptDownloadQSLData, imptInsertQSLManagers, imptImporteQSLAdif,
                         imptRemoveDupes, imptUpdateMembershipFiles);

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
    running : Boolean;
    FileSize : Int64;
    procedure ImportDXCCTables;
    procedure RegenerateDXCCStat;
    procedure DownloadDXCCData;
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

uses dData, dUtils, fImportTest, dDXCC, uMyini, dLogUpload, dMembership, dSatellite;

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
  eQSLQSOList.Clear
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
        if dmData.DebugLevel >=1 then Writeln(dmDXCC.qDXCCRef.SQL.Text);
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
        if dmData.DebugLevel >=1 then
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
      if dmData.DebugLevel>=1 then
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
  call     : String;
  band     : String;
  mode     : String;
  qsodate  : String;
  time_on  : String;
  qslr     : String;
  qslrdate : String;
  cqz      : String;
  ituz     : String;
  iota     : String;
  grid     : String;
  state    : String;
  county   : String;
  PosCall     : Word;
  PosBand     : Word;
  PosMode     : Word;
  PosQsoDate  : Word;
  PosTime_on  : Word;
  PosQslr     : Word;
  PosQslrDate : Word;
  PosCqz      : Word;
  PosItuz     : Word;
  PosIota     : Word;
  PosGrid     : Word;
  PosState    : Word;
  PosCounty   : Word;

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
        while not ((PosEOR > 0) or eof(f)) do
        begin
          qso_in_log := False;
          Readln(f, a);
          a    := Trim(a);
          orig := a;
          a    := UpperCase(a);

          PosCall     := Pos('<CALL:',a);
          PosBand     := Pos('<BAND:',a);
          PosMode     := Pos('<MODE:',a);
          PosQsoDate  := Pos('<QSO_DATE:',a);
          PosTime_on  := Pos('<TIME_ON:',a);
          PosQslr     := Pos('<QSL_RCVD:',a);
          PosQslrDate := Pos('<QSLRDATE:',a);
          PosCqz      := Pos('<CQZ:',a);
          PosItuz     := Pos('<ITUZ:',a);
          PosIota     := Pos('<IOTA:',a);
          PosGrid     := Pos('<GRIDSQUARE:',a);
          PosState    := Pos('<STATE:',a);
          PosCounty   := Pos('<CNTY:',a);
          PosEOR      := Pos('<EOR>',a);

          if PosCall > 0 then
          begin
            sSize   := '';
            PosCall := PosCall + 6;
            while not (a[PosCall] = '>') do
            begin
              sSize := sSize + a[PosCall];
              inc(PosCall)
            end;
            Size := StrToInt(sSize);
            call := copy(orig,PosCall+1,Size)
          end;

          if PosBand > 0 then
          begin
            sSize   := '';
            PosBand := PosBand + 6;
            while not (a[PosBand] = '>') do
            begin
              sSize := sSize + a[PosBand];
              inc(PosBand)
            end;
            Size := StrToInt(sSize);
            band := copy(orig,PosBand+1,Size)
          end;

          if PosMode > 0 then
          begin
            sSize   := '';
            PosMode := PosMode + 6;
            while not (a[PosMode] = '>') do
            begin
              sSize := sSize + a[PosMode];
              inc(PosMode)
            end;
            Size := StrToInt(sSize);
            mode := copy(orig,PosMode+1,Size)
          end;

          if PosQsoDate > 0 then
          begin
            sSize      := '';
            PosQsoDate := PosQsoDate + 10;
            while not (a[PosQsoDate] = '>') do
            begin
              sSize := sSize + a[PosQsoDate];
              inc(PosQsoDate)
            end;
            Size    := StrToInt(sSize);
            qsodate := copy(orig,PosQsoDate+1,Size)
          end;

          if PosTime_on > 0 then
          begin
            sSize      := '';
            PosTime_on := PosTime_on + 9;
            while not (a[PosTime_on] = '>') do
            begin
              sSize := sSize + a[PosTime_on];
              inc(PosTime_on)
            end;
            Size    := StrToInt(sSize);
            time_on := copy(orig,PosTime_on+1,Size)
          end;


          if PosQslr > 0 then
          begin
            sSize   := '';
            PosQslr := PosQslr + 10;
            while not (a[PosQslr] = '>') do
            begin
              sSize := sSize + a[PosQslr];
              inc(PosQslr)
            end;
            Size := StrToInt(sSize);
            qslr := copy(orig,PosQslr+1,Size)
          end;

          if PosQslrDate > 0 then
          begin
            sSize      := '';
            PosQslrDate := PosQslrDate + 10;
            while not (a[PosQslrDate] = '>') do
            begin
              sSize := sSize + a[PosQslrDate];
              inc(PosQslrDate)
            end;
            Size     := StrToInt(sSize);
            qslrdate := copy(orig,PosQslrDate+1,Size)
          end;

          if PosCqz > 0 then
          begin
            sSize  := '';
            PosCqz := PosCqz + 5;
            while not (a[PosCqz] = '>') do
            begin
              sSize := sSize + a[PosCqz];
              inc(PosCqz)
            end;
            Size := StrToInt(sSize);
            cqz  := copy(orig,PosCqz+1,Size)
          end;

          if PosItuz > 0 then
          begin
            sSize   := '';
            PosItuz := PosItuz + 6;
            while not (a[PosItuz] = '>') do
            begin
              sSize := sSize + a[PosItuz];
              inc(PosItuz)
            end;
            Size  := StrToInt(sSize);
            ituz  := copy(orig,PosItuz+1,Size)
          end;

          if PosIota > 0 then
          begin
            sSize   := '';
            PosIota := PosIota + 6;
            while not (a[PosIota] = '>') do
            begin
              sSize := sSize + a[PosIota];
              inc(PosIota)
            end;
            Size  := StrToInt(sSize);
            iota  := copy(orig,PosIota+1,Size)
          end;

          if PosGrid > 0 then
          begin
            sSize   := '';
            PosGrid := PosGrid + 12;
            while not (a[PosGrid] = '>') do
            begin
              sSize := sSize + a[PosGrid];
              inc(PosGrid)
            end;
            Size  := StrToInt(sSize);
            grid  := copy(orig,PosGrid+1,Size)
          end;

          if PosState > 0 then
          begin
            sSize    := '';
            PosState := PosState + 7;
            while not (a[PosState] = '>') do
            begin
              sSize := sSize + a[PosState];
              inc(PosState)
            end;
            Size  := StrToInt(sSize);
            state := copy(orig,PosState+1,Size)
          end;

          if PosCounty > 0 then
          begin
            sSize     := '';
            PosCounty := PosCounty + 6;
            while not (a[PosCounty] = '>') do
            begin
              sSize := sSize + a[PosCounty];
              inc(PosCounty)
            end;
            Size   := StrToInt(sSize);
            county := copy(orig,PosCounty+1,Size)
          end;

          if PosEOR > 0 then
          begin
            //inc(qsln);
            if dmData.DebugLevel >= 1 then
            begin
             // Writeln('Number:   ',IntToStr(qsln));
              Writeln('Call:     ',call);
              Writeln('Band:     ',band);
              Writeln('Mode:     ',mode);
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

            mode := UpperCase(mode);
            if mode='JT65' then
              mode := 'JT65A';

            dmData.Q.Close;
            dmData.Q.SQL.Text := 'select time_on,lotw_qslr,waz,itu,iota,loc,state,county,id_cqrlog_main from cqrlog_main ' +
                                 'where (qsodate ='+QuotedStr(qsodate)+') '+
                                 'and (band = ' + QuotedStr(band) + ')'+
//                                 'and (mode = ' + QuotedStr(mode) + ') and (band = ' + QuotedStr(band) + ')'+
                                 'and (callsign = ' + QuotedStr(call) + ')';
            if dmData.DebugLevel >=1 then Writeln(dmData.Q.SQL.Text);
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

              t_lotw_min := t_lotw-5/1440;
              t_lotw_max := t_lotw+5/1440;

              if dmData.DebugLevel >=1 then Writeln(call,'|',TimeToStr(t_log),' | ',TimeToStr(t_lotw_min),'|',TimeToStr(t_lotw_max));

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
                  dmData.Q1.SQL.Add(' where id_cqrlog_main = ' + dmData.Q.Fields[8].AsString);
                  inc(qsln);
                  if dmData.DebugLevel>=1 then Writeln(dmData.Q1.SQL.Text+ '  qsl number:'+ IntToStr(qsln));
                  dmData.Q1.ExecSQL
                end;
                qso_in_log := True;
                Break
              end;
              dmData.Q.Next
            end;
            if not qso_in_log then
            begin
              l.Add('QSO NOT FOUND in log');
              l.Add('Call:     '+call);
              l.Add('Band:     '+band);
              l.Add('Mode:     '+mode);
              l.Add('QSO_date: '+qsodate);
              l.Add('Time_on:  '+time_on);
              l.Add('QSLR:     '+qslr);
              l.Add('QSLRDate: '+qslrdate);
              l.Add('CQZ:      '+cqz);
              l.Add('ITUZ:     '+ituz);
              l.Add('IOTA:     '+iota);
              l.Add('Grid:     '+grid);
              l.Add('State:    '+state);
              l.Add('County:   '+county);
              l.Add('------------------------------------------------');
              l.Add('');
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
        l.SaveToFile(dmData.HomeDir + 'lotw_error.txt');
        if Application.MessageBox(PChar(IntToStr(ErrorCount)+' QSO(s) were not found in your log. '#13' QSO(s) are stored to '+dmData.HomeDir + 'lotw_error.txt'+
                                  LineEnding+LineEnding+'Do you want to show the file?'),'Question ....',mb_YesNo+mb_IconQuestion)=idYes then
           dmUtils.OpenInApp(dmData.HomeDir + 'lotw_error.txt')
        //ShowMessage(IntToStr(ErrorCount)+' QSO(s) were not found in your log. '#13' QSO(s) are stored to '+dmData.HomeDir + 'lotw_error.txt')
      end
    end
    else begin
      if Application.MessageBox('Something is wrong because LoTW server returned invalid adif file header.'+LineEnding+
                                'Your LoTW username/password could be wrong or LoTW server is down.'+LineEnding+LineEnding+'Do you want to show the file?',
                                'Error ...',mb_YesNo+mb_IconQuestion) = idYes then
        dmUtils.OpenInApp(FileName)
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
        if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
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
  num      : Word = 1;
  size     : Word;
  sSize    : String;
  a        : String;
  orig     : String;
  f        : TextFile;
  PosEOH   : Word;
  PosEOR   : Word;
  call     : String;
  band     : String;
  mode     : String;
  submode  : String;
  qsodate  : String;
  time_on  : String;
  qslr     : String;
  PosCall     : Word;
  PosBand     : Word;
  PosMode     : Word;
  PosSubmode  : Word;
  PosQsoDate  : Word;
  PosTime_on  : Word;
  PosQslr     : Word;

  qso_in_log  : Boolean = False;
  ErrorCount  : Word = 0;
  l           : TStringList;
  t_eQSL      : TDateTime;
  t_eQSL_min  : TDateTime;
  t_eQSL_max  : TDateTime;
  t_log       : TDateTime;

begin
  l := TStringList.Create;
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
      mode     := '';
      submode  := '';
      qsodate  := '';
      time_on  := '';
      qslr     := '';
      PosEOR   := 0;
      while not ((PosEOR > 0) or eof(f)) do
      begin
        Readln(f, a);
        a    := Trim(a);
        orig := a;
        a    := UpperCase(a);

        PosCall     := Pos('<CALL:',a);
        PosBand     := Pos('<BAND:',a);
        PosMode     := Pos('<MODE:',a);
        PosSubmode  := Pos('<SUBMODE:',a);
        PosQsoDate  := Pos('<QSO_DATE:8:D',a);
        PosTime_on  := Pos('<TIME_ON:',a);
        PosQslr     := Pos('<QSL_RCVD:',a);
        PosEOR      := Pos('<EOR>',a);

        if PosCall > 0 then
        begin
          sSize   := '';
          PosCall := PosCall + 6;
          while not (a[PosCall] = '>') do
          begin
            sSize := sSize + a[PosCall];
            inc(PosCall)
          end;
          Size := StrToInt(sSize);
          call := copy(orig,PosCall+1,Size)
        end;

        if PosBand > 0 then
        begin
          sSize   := '';
          PosBand := PosBand + 6;
          while not (a[PosBand] = '>') do
          begin
            sSize := sSize + a[PosBand];
            inc(PosBand)
          end;
          Size := StrToInt(sSize);
          band := copy(orig,PosBand+1,Size)
        end;

        if PosMode > 0 then
        begin
          sSize   := '';
          PosMode := PosMode + 6;
          while not (a[PosMode] = '>') do
          begin
            sSize := sSize + a[PosMode];
            inc(PosMode)
          end;
          Size := StrToInt(sSize);
          mode := copy(orig,PosMode+1,Size)
        end;

        if PosSubmode > 0 then
        begin
          sSize   := '';
          PosSubmode := PosSubmode + 9;
          while not (a[PosSubmode] = '>') do
          begin
            sSize := sSize + a[PosSubmode];
            inc(PosSubmode)
          end;
          Size := StrToInt(sSize);
          submode := copy(orig,PosSubmode+1,Size)
        end;

        if PosQsoDate > 0 then
        begin
          qsodate :=copy(orig,PosQsoDate+14,8);
          {
          sSize      := '';
          PosQsoDate := PosQsoDate + 13;
          while not (a[PosQsoDate] = '>') do
          begin
            sSize := sSize + a[PosQsoDate];
            inc(PosQsoDate)
          end;
          Size    := StrToInt(sSize);
          qsodate := copy(orig,PosQsoDate+1,Size)
          }
        end;

        if PosTime_on > 0 then
        begin
          sSize      := '';
          PosTime_on := PosTime_on + 9;
          while not (a[PosTime_on] = '>') do
          begin
            sSize := sSize + a[PosTime_on];
            inc(PosTime_on)
          end;
          Size    := StrToInt(sSize);
          time_on := copy(orig,PosTime_on+1,Size)
        end;

        if PosQslr > 0 then
        begin
          sSize   := '';
          PosQslr := PosQslr + 10;
          while not (a[PosQslr] = '>') do
          begin
            sSize := sSize + a[PosQslr];
            inc(PosQslr)
          end;
          Size := StrToInt(sSize);
          qslr := copy(orig,PosQslr+1,Size)
        end;

        if PosEOR > 0 then
        begin
          band    := UpperCase(band);
          mode    := UpperCase(mode);
          submode := UpperCase(submode);
          qslr    := UpperCase(qslr);
          call    := UpperCase(call);
          if dmData.DebugLevel >= 1 then
          begin
            Writeln('Call:     ',call);
            Writeln('Band:     ',band);
            Writeln('Mode:     ',mode);
            Writeln('Submode:  ',submode);
            Writeln('QSO_date: ',qsodate);
            Writeln('Time_on:  ',time_on);
            Writeln('QSLR:     ',qslr);
            Writeln('------------------------------------------------')
          end;
          qsodate  := dmUtils.ADIFDateToDate(qsodate);
          mode     := UpperCase(mode);


          dmData.Q.Close;

          if (mode='JT65') then  //since implementing submodes below, this can most probably be removed
          begin
            dmData.Q.SQL.Text := 'select id_cqrlog_main,eqsl_qsl_rcvd,time_on from cqrlog_main ' +
                                 'where (qsodate ='+QuotedStr(qsodate)+') '+
                                 'and ((mode = ' + QuotedStr('JT65') + ') or (mode='+QuotedStr('JT65A')+') '+
                                 'or (mode='+QuotedStr('JT65B')+') or (mode='+QuotedStr('JT65C')+')) '+
                                 'and (band = ' + QuotedStr(band) + ') '+
                                 'and (callsign = ' + QuotedStr(call) + ')'
          end
          else begin
            dmData.Q.SQL.Text := 'select id_cqrlog_main,eqsl_qsl_rcvd,time_on from cqrlog_main ' +
                                 'where (qsodate ='+QuotedStr(qsodate)+') '+
                                 'and ((mode = ' + QuotedStr(mode) + ') or (mode = ' + QuotedStr(submode) + ')) '+
                                 'and (band = ' + QuotedStr(band) + ') '+
                                 'and (callsign = ' + QuotedStr(call) + ')'
          end;
          if dmData.DebugLevel >=1 then Writeln(dmData.Q.SQL.Text);
          //if dmData.trQ.Active then dmData.trQ.Rollback;
          //dmData.trQ.StartTransaction;
          dmData.Q.Open();
          while not dmData.Q.Eof do
          begin
            qso_in_log := False;

            t_eQSL := EncodeTime(StrToInt(copy(time_on,1,2)),
                      StrToInt(copy(time_on,3,2)),0,0);

            t_log  := EncodeTime(StrToInt(copy(dmData.Q.Fields[2].AsString,1,2)),
                      StrToInt(copy(dmData.Q.Fields[2].AsString,4,2)),0,0);

            t_eQSL_min := t_eQSL-60/1440;
            t_eQSL_max := t_eQSL+60/1440;

            if dmData.DebugLevel >=1 then Writeln(call,'|',TimeToStr(t_log),' | ',TimeToStr(t_eQSL_min),'|',TimeToStr(t_eQSL_max));

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
                if dmData.DebugLevel>=1 then Writeln(dmData.Q1.SQL.Text);
                dmData.Q1.ExecSQL
              end;
              qso_in_log := True;
              Break //should only be one qso confirmed, if we have several answers we stop looping those if found one match
            end;
            dmData.Q.Next
          end;
          if not qso_in_log then
          begin
            l.Add('QSO NOT FOUND in log');
            l.Add('Call:     '+call);
            l.Add('Band:     '+band);
            l.Add('Mode:     '+mode);
            l.Add('Mode:     '+submode);
            l.Add('QSO_date: '+qsodate);
            l.Add('Time_on:  '+time_on);
            l.Add('------------------------------------------------');
            l.Add('');
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
      l.SaveToFile(dmData.UsrHomeDir + 'eQSL_error.txt');
      ShowMessage('Some QSO(s) were not found in your log. '#13' QSO(s) are stored to '+dmData.UsrHomeDir + 'eQSL_error.txt')
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
    if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
    dmData.Q.ExecSQL;
    dmData.trQ.Commit;

    lblComment.Caption := 'Checking for dupe QSOs';
    Application.ProcessMessages;
    sleep(200);

    dmData.trQ.StartTransaction;
    dmData.Q.SQL.Text := 'insert into tempdupes ' +
                         '  select * from cqrlog_main group by qsodate,time_on,callsign,mode,band';
    if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
    dmData.Q.ExecSQL;

    dmData.Q.SQL.Text := 'delete from cqrlog_main';
    if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
    dmData.Q.ExecSQL;

    dmData.Q.SQL.Text := 'insert into cqrlog_main select * from tempdupes';
    if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
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

