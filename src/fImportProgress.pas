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
  ComCtrls,lcltype, synachar, ExtCtrls, httpsend, blcksock, iniFiles, FileUtil;

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
    procedure ImportCQRLOGWin;
    procedure DownloadDXCCData;
    procedure ImportLoTWAdif;
    procedure ImportQSLMgrs;
    procedure DownloadQSLData;
    procedure InsertQSLManagers;
    procedure ImporteQSLAdif;
    procedure RemoveDupes;

    procedure SockCallBack (Sender: TObject; Reason:  THookSocketReason; const  Value: string);

  public
    ImportType : Integer;  // 0 - regenerate dxcc stat; 1 -  dxcc tables import; 2 - cqrlog for win; 3 - dwnload dxcc data
    FileName   : String;   // 4 - import lotw adif file; 5 - import QSLmanagers; 6 - download qsl managers
                           // 7 - insert QSL managers
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

{ TfrmImportProgress }

uses dData, dUtils, fImportTest, dDXCC, uMyini;

procedure TfrmImportProgress.FormActivate(Sender: TObject);
begin
  tmrImport.Enabled := False;
  if not running then
  begin
    running := True;
    case ImportType of
      0 : RegenerateDXCCStat;
      1 : ImportDXCCTables;
      2 : ImportCQRLOGWin;
      3 : DownloadDXCCData;
      4 : ImportLoTWAdif;
      5 : ImportQSLMgrs;
      6 : DownloadQSLData;
      7 : InsertQSLManagers;
      8 : ImporteQSLAdif;
      9 : RemoveDupes
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

    /////////////////////////////////////////////////////////////////// exceptions.tbl
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
    if FileExistsUTF8(Directory+'MASTER.SCP') then
    begin
      DeleteFileUTF8(dmData.HomeDir+'MASTER.SCP');
      CopyFile(Directory+'MASTER.SCP',dmData.HomeDir+'MASTER.SCP');
      dmData.LoadeQSLCalls
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

procedure TfrmImportProgress.ImportCQRLOGWin;
{var
  time_off  : String;
  waz,itu   : String;
  iwaz,iitu : Integer;
  profil    : Integer;
  vis       : Integer;
  iota      : String;
  time_on   : String;
  }
begin
  {
  dmData.tblImport.FilePathFull := Directory;
  dmData.tblImport.TableName    := FileName;
  try
    dmData.tblImport.Open;
    dmData.tblImport.First;
    pBarProg.Max := dmData.tblImport.RecordCount;
    while not dmData.tblImport.EOF do
    begin
      //waz := dmData.tblImport.FieldByName('waz').AsString;
      //itu := dmData.tblImport.FieldByName('itu').AsString;
      if not TryStrToInt(waz,iwaz) then
        iwaz := 0;
      if not TryStrToInt(itu,iitu) then
        iitu := 0;
      if not dmUtils.IsTimeOK(dmData.tblImport.FieldByName('cas').AsString) then
      begin
        time_on  := '12:12';
        time_off := '12:12'
      end
      else begin
        time_on := dmData.tblImport.FieldByName('cas').AsString;
        if dmUtils.IsTimeOK(dmData.tblImport.FieldByName('CAS1').AsString) then
          time_off := dmData.tblImport.FieldByName('CAS1').AsString
        else
          time_off := dmData.tblImport.FieldByName('cas').AsString
      end;
      if dmData.tblImport.FieldByName('profil').AsInteger = -1 then
        profil := 0
      else
        profil := dmData.tblImport.FieldByName('profil').AsInteger;
      iota := dmData.tblImport.FieldByName('iota').AsString;
      if not dmUtils.IsIOTAOK(iota) then
        iota := '';
      dmData.SaveQSO(dmData.tblImport.FieldByName('datum').AsDateTime,
                     time_on,
                     time_off,
                     dmData.tblImport.FieldByName('call').AsString,
                     dmData.tblImport.FieldByName('freq').AsFloat,
                     UpperCase(dmData.tblImport.FieldByName('mode').AsString),
                     dmData.tblImport.FieldByName('rst_s').AsString,
                     dmData.tblImport.FieldByName('rst_r').AsString,
                     dmData.tblImport.FieldByName('name').AsString,
                     dmData.tblImport.FieldByName('qth').AsString,
                     dmData.tblImport.FieldByName('qsl_s').AsString,
                     dmData.tblImport.FieldByName('qsl_r').AsString,
                     dmData.tblImport.FieldByName('qsl_via').AsString,
                     iota,
                     dmData.tblImport.FieldByName('pwr').AsString,
                     iwaz,
                     iitu,
                     dmData.tblImport.FieldByName('loc').AsString,
                     dmData.tblImport.FieldByName('my_loc').AsString,
                     dmData.tblImport.FieldByName('county').AsString,
                     dmData.tblImport.FieldByName('diplom').AsString,
                     dmData.tblImport.FieldByName('rem').AsString,
                     adif,
                     dmUtils.GetIDCall(dmData.tblImport.FieldByName('call').AsString),
                     '',
                     dmDXCC.GetCont(dmData.tblImport.FieldByName('call').AsString,
                                    dmData.tblImport.FieldByName('datum').AsDateTime),
                     dmData.tblImport.FieldByName('podlepfx').AsBoolean,
                     profil
      );
      dmData.tblImport.Next;
      pBarProg.StepIt;
      if (pBarProg.Position mod 100) = 0 then
      begin
        Repaint;
        Application.ProcessMessages;
      end;

        procedure SaveQSO(date : TDateTime; time_on,time_off,call : String; freq : Currency;mode,rst_s,
                     rst_r, stn_name,qth,qsl_s,qsl_r,qsl_via,iota,pwr : String; itu,waz : Integer;
                     loc, my_loc,county,award,remarks,dxcc_ref : String; qso_dxcc : Boolean;
                     profile : Integer);

    end;
    dmData.tblImport.Close;
    dmData.tblImport.TableName    := 'profily.dbf';
    dmData.tblImport.Open;
    dmData.tblImport.First;

    while not dmData.tblImport.EOF do
    begin
      if dmData.tblImport.Fields[6].AsBoolean then
        vis := 1
      else
        vis := 0;
      dmData.Q.SQL.Text := 'INSERT INTO profiles (nr,locator,qth,rig,remarks,visible)'+
                           ' VALUES ('+IntToStr(dmData.tblImport.Fields[0].AsInteger)+
                           ','+QuotedStr(dmData.tblImport.Fields[1].AsString)+
                           ','+QuotedStr(dmData.tblImport.Fields[2].AsString)+
                           ','+QuotedStr(dmData.tblImport.Fields[3].AsString)+
                           ','+QuotedStr(dmData.tblImport.Fields[4].AsString)+
                           ','+IntToStr(vis)+')';
      if dmData.DebugLevel >=1 then
        Writeln(dmData.Q.SQL.Text);
      dmData.trQ.StartTransaction;
      dmData.Q.ExecSQL;
      dmData.trQ.Commit;
      dmData.tblImport.Next
    end;

    pBarProg.Position := 0;
    dmData.tblImport.Close;
    dmData.tblImport.TableName    := 'remarks.dbf';
    dmData.tblImport.Open;
    dmData.tblImport.First;
    pBarProg.Max := dmData.tblImport.RecordCount;
    while not dmData.tblImport.EOF do
    begin
      dmData.SaveComment(dmData.tblImport.Fields[0].AsString,
                         dmData.tblImport.Fields[1].AsString);
      dmData.tblImport.Next;
      pBarProg.StepIt;
      if (pBarProg.Position mod 100) = 0 then
      begin
        Repaint;
        Application.ProcessMessages;
      end;
    end;
  finally
    dmData.tblImport.Close;
    lblCount.Caption := 'Complete';
  end
  }
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
  time_onx : String;
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
begin
  if dmData.trQ.Active then
    dmData.trQ.RollBack;
  if dmData.trQ1.Active then
    dmData.trQ1.RollBack;
  dmData.trQ1.StartTransaction;
  l := TStringList.Create;
  AssignFile(f,FileName);
  try
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

            dmData.Q.Close;
            dmData.Q.SQL.Text := 'select time_on,lotw_qslr,waz,itu,iota,loc,state,county,id_cqrlog_main from cqrlog_main ' +
                                 'where (qsodate ='+QuotedStr(qsodate)+') '+
                                 'and (mode = ' + QuotedStr(mode) + ') and (band = ' + QuotedStr(band) + ')'+
                                 'and (callsign = ' + QuotedStr(call) + ')';
            if dmData.DebugLevel >=1 then Writeln(dmData.Q.SQL.Text);
            if dmData.trQ.Active then dmData.trQ.Rollback;
            dmData.trQ.StartTransaction;
            dmData.Q.Open();
            if dmData.Q.Eof then  qso_in_log := False;
            while not dmData.Q.Eof do
            begin
              qso_in_log := False;
              time_onx:= copy(time_on,1,2)+':'+copy(time_on,3,2);
              if dmData.DebugLevel >=1 then Writeln(dmData.Q.Fields[0].AsString+' | '+ time_onx);
              if copy(dmData.Q.Fields[0].AsString,1,5) = copy(time_onx,1,5) then
              begin
                if LoTWShowNew and (dmData.Q.Fields[1].AsString <> 'L') then  //this qso is already confirmed
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
                dmData.Q1.ExecSQL;
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
        ShowMessage(IntToStr(ErrorCount)+' QSO(s) were not found in your log. '#13' QSO(s) are stored to '+dmData.HomeDir + 'lotw_error.txt')
      end
    end
    else begin
      Application.MessageBox('Something is wrong because LoTW server returned invalid adif file header.'+LineEnding+
                             'Your LoTW username/password could be wrong of LoTW server is closed.','Error ...',
                             mb_ok+mb_IconError)
    end
  finally
    l.Free;
    CloseFile(f)
  end;
  Close
end;

procedure TfrmImportProgress.ImportQSLMgrs;
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
    while not Eof(sF) do
    begin
      readln(sF,line);
      Writeln('Line: ',line);
      a := dmUtils.Explode(';',line);
      call     := a[0];
      qsl_via  := a[1];
      fromDate := a[2]+'-01';

      dmData.qQSLMgr.SQL.Text := 'INSERT INTO cqrlog_common.qslmgr (callsign,qsl_via,fromdate)'+
                                 ' VALUES ('+QuotedStr(call)+','+QuotedStr(qsl_via)+','+
                                 QuotedStr(fromDate)+')';
      if dmData.DebugLevel>=1 then Writeln(dmData.qQSLMgr.SQL.Text);
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
begin
  l := TStringList.Create;
  if dmData.trQ.Active then
    dmData.trQ.RollBack;
  if dmData.trQ1.Active then
    dmData.trQ1.RollBack;
  dmData.trQ1.StartTransaction;
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
      Readln(f, a);
      a    := Trim(a);
      orig := a;
      a    := UpperCase(a);

      PosCall     := Pos('<CALL:',a);
      PosBand     := Pos('<BAND:',a);
      PosMode     := Pos('<MODE:',a);
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

      if PosQsoDate > 0 then
      begin
        qsodate :=copy(orig,PosQsoDate+14,8);
        Writeln(qsodate);
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
        band := UpperCase(band);
        mode := UpperCase(mode);
        qslr := UpperCase(qslr);
        call := UpperCase(call);
        if dmData.DebugLevel >= 1 then
        begin
          Writeln('Call:     ',call);
          Writeln('Band:     ',band);
          Writeln('Mode:     ',mode);
          Writeln('QSO_date: ',qsodate);
          Writeln('Time_on:  ',time_on);
          Writeln('QSLR:     ',qslr);
          Writeln('------------------------------------------------')
        end;
        qsodate  := dmUtils.ADIFDateToDate(qsodate);

        dmData.Q.Close;
        dmData.Q.SQL.Text := 'select id_cqrlog_main,eqsl_qsl_rcvd from cqrlog_main ' +
                             'where (qsodate ='+QuotedStr(qsodate)+') '+
                             'and (mode = ' + QuotedStr(mode) + ') and (band = ' + QuotedStr(band) + ')'+
                             'and (callsign = ' + QuotedStr(call) + ')';
        if dmData.DebugLevel >=1 then Writeln(dmData.Q.SQL.Text);
        if dmData.trQ.Active then dmData.trQ.Rollback;
        dmData.trQ.StartTransaction;
        dmData.Q.Open();
        while not dmData.Q.Eof do
        begin
          qso_in_log := False;
          if eQSLShowNew and (dmData.Q.Fields[1].AsString <> 'E') then  //this qso is already confirmed
            eQSLQSOList.Add(qsodate+ ' ' + call + ' ' + band + ' ' + mode);
          dmData.Q1.Close;
          dmData.Q1.SQL.Clear;
          dmData.Q1.SQL.Add('update cqrlog_main set eqsl_qsl_rcvd = ' + QuotedStr('E'));
          dmData.Q1.SQL.Add(',eqsl_qslrdate = ' + QuotedStr(dmUtils.DateInRightFormat(now)));
          dmData.Q1.SQL.Add(' where id_cqrlog_main = ' + dmData.Q.Fields[0].AsString);
          if dmData.DebugLevel>=1 then Writeln(dmData.Q1.SQL.Text);
          dmData.Q1.ExecSQL;
          qso_in_log := True;
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
  end;
  l.Free;
  Close
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

    dmData.Q.SQL.Text := 'truncate table cqrlog_main';
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

initialization

  {$I fImportProgress.lrs}

end.

