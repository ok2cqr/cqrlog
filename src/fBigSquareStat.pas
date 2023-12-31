unit fBigSquareStat;

{$mode objfpc}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Grids, ComCtrls, IpHtml, Ipfilebroker, db, BufDataset,
  LazFileUtils, dateutils;

type

  { TfrmBigSquareStat }

  TfrmBigSquareStat = class(TForm)
    btnSaveTo: TButton;
    btnRefresh: TButton;
    btnClose: TButton;
    chkQSL: TCheckBox;
    chkLoTW: TCheckBox;
    chkeQSL: TCheckBox;
    cmbBands: TComboBox;
    GroupBox1: TGroupBox;
    IpFileDataProvider1: TIpFileDataProvider;
    IpHtmlPanel1: TIpHtmlPanel;
    Label1: TLabel;
    lblFIlterActive: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    dlgSave: TSaveDialog;
    pbTot: TProgressBar;
    tmrBlink: TTimer;
    procedure btnRefreshClick(Sender: TObject);
    procedure btnSaveToClick(Sender: TObject);
    procedure cmbBandsChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure tmrBlinkStartTimer(Sender: TObject);
    procedure tmrBlinkStopTimer(Sender: TObject);
    procedure tmrBlinkTimer(Sender: TObject);
  private
    TmpFile : String;
    f  : TextFile;
    procedure WriteHMTLHeader;
  public

  end; 

var
  frmBigSquareStat: TfrmBigSquareStat;

implementation
{$R *.lfm}

{ TfrmBigSquareStat }
uses dUtils,dData, uMyIni, uVersion;

procedure TfrmBigSquareStat.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveForm(frmBigSquareStat);
  cqrini.WriteInteger('SquareStat','Band',cmbBands.ItemIndex);
  cqrini.WriteBool('SquareStat','QSL',chkQSL.Checked);
  cqrini.WriteBool('SquareStat','LoTW',chkLoTW.Checked);
  cqrini.WriteBool('SquareStat','eQSL',chkeQSL.Checked);
  DeleteFileUTF8(TmpFile);
  DeleteFileUTF8(ExtractFileNameWithoutExt(TmpFile)+'.html')
end;

procedure TfrmBigSquareStat.btnRefreshClick(Sender: TObject);
var
  tmp : String = '';
  bnd : String = '';
  grb : String = '';
  allwkd : longint = 0;
  thiswkd : longint =0;
  allwkdBig : longint = 0;
  TotPos : longint = 0;
  wkd : integer = 0;
  cfm : integer = 0;
  ll  : String = '';
  sum_wkd : integer = 0;
  sum_cfm : integer = 0;
  db : TBufDataset;
  TableName : String;
begin
  tmrBlink.Enabled:=False;
  TableName:='cqrlog_main';
  try
    dmData.Q.Close;
    dmData.Q1.Close;
    if dmData.trQ.Active then dmData.trQ.Rollback;
    if dmData.trQ1.Active then dmData.trQ1.Rollback;
    if chkQSL.Checked then
    begin
      tmp := '(qsl_r = '+QuotedStr('Q')+') or';
      grb := ',qsl_r';
    end;
    if chkLoTW.Checked then
    begin
      tmp := tmp + ' (lotw_qslr = '+QuotedStr('L')+') or';
      grb := grb + ',lotw_qslr'
    end;
    if chkeQSL.Checked then
    begin
      tmp := tmp + ' (eqsl_qsl_rcvd = '+QuotedStr('E')+') or';
      grb := grb + ',eqsl_qsl_rcvd'
    end;
    tmp := copy(tmp,1,Length(tmp)-2); //remove "or"

     if cmbBands.Text='ALL' then
       bnd:=' '
     else
      bnd:= ' and band='+QuotedStr(cmbBands.Text);

    dmData.trQ.StartTransaction;
    dmData.trQ1.StartTransaction;
    try
      if dmData.IsFilter then
         begin
          try
            TableName:='statistic_filter';
            dmData.Q.Close;
            dmData.Q.SQL.Text:='DROP VIEW IF EXISTS '+TableName;
            dmData.Q.ExecSQL;
            dmData.trQ.Commit;
            dmData.Q.Close;
            dmData.Q.SQL.Text:='CREATE VIEW '+TableName+' AS '+dmData.IsFilterSQL;
            dmData.Q.ExecSQL;
            dmData.trQ.Commit;
            dmData.Q.Close;
          except
           on E : EDatabaseError do
            Begin
              ShowMessage('Can not create filter view!');
              Exit;
            end;
          end;
         end;
      dmData.Q.SQL.Text := 'select left(loc,2) as ll FROM '+TableName+' where loc <> '+QuotedStr('')+' group by ll';
      dmData.Q.Open;
      dmData.Q.Last;
      allwkdBig:=dmData.Q.RecordCount;
      dmData.Q.Close;

      dmData.Q.SQL.Text := 'select left(loc,4) as ll FROM '+TableName+' where loc <> '+QuotedStr('')+' group by ll';
      dmData.Q.Open;
      dmData.Q.Last;
      allwkd:=dmData.Q.RecordCount;
      dmData.Q.Close;

      dmData.Q.SQL.Text := 'select upper(left(loc,2)) as ll FROM '+TableName+' where loc <> '+QuotedStr('')+
                           bnd+' group by ll';
      dmData.Q.Open;
      dmData.Q.Last;
      WriteHMTLHeader;
      writeln(f,'<table>');
      pbTot.Max:=dmData.Q.RecordCount;
      thiswkd:= dmData.Q.RecordCount;
      dmData.Q.First;
      while not dmData.Q.Eof do
      begin
        inc(TotPos);
        pbTot.Position:=TotPos;
        Application.ProcessMessages;
        ll := dmData.Q.Fields[0].AsString;
        writeln(f,'<tr>'+LineEnding+'<td valign="middle">'+LineEnding+'<font color="black"><b>'+ll+'</b></font>'+LineEnding+'</td>');
        writeln(f,'<td align="left">');
        writeln(f,'<font color="black">');
        dmData.Q1.Close;
        dmData.Q1.SQL.Text := 'select upper(left(loc,4)) as lll FROM '+TableName+' where loc like '+
                              QuotedStr(ll+'%')+bnd+' group by lll order by loc';
        dmData.Q1.Open;

        db := TBufDataset.Create(nil); //I was not able to clear all records from TBufDataset without this workaround
        try
          db.FieldDefs.Clear;
          db.FieldDefs.Add('loc', ftString, 4);
          db.IndexDefs.Add('loc','loc',[ixPrimary]);
          db.FieldDefs.Add('cfm',ftBoolean);
          db.CreateDataset;

          db.Open;
          wkd := 0;
          while not dmData.Q1.Eof do
          begin
            db.Append;
            db.Fields[0].AsString  := dmData.Q1.Fields[0].AsString;
            db.Fields[1].AsBoolean := False;
            db.Post;
            inc(wkd);
            dmData.Q1.Next
          end;
          sum_wkd := sum_wkd + wkd;
          if tmp <> '' then
          begin
            dmData.Q1.Close;
            dmData.Q1.SQL.Text := 'select upper(left(loc,4)) as lll FROM '+TableName+' where loc like '+
                                  QuotedStr(ll+'%')+bnd+'and ('+tmp+') group by lll order by loc';
            dmData.Q1.Open;
            cfm := 0;
            while not dmData.Q1.Eof do
            begin
              if db.Locate('LOC',dmData.Q1.Fields[0].AsString,[]) then
              begin
                db.Edit;
                db.Fields[1].AsBoolean := True;
                db.Post
              end;
              inc(cfm);
              dmData.Q1.Next
            end;
            sum_cfm := sum_cfm + cfm
          end;
          dmData.Q1.Close;

          db.IndexFieldNames := 'loc';
          db.First;
          while not db.Eof do
          begin
            if db.Bof then
            begin
              if db.Fields[1].AsBoolean then
                Write(f,'<font color="black">',db.Fields[0].AsString,'</font>')
              else
                Write(f,'<font color="gray">',db.Fields[0].AsString,'</font>')
            end
            else begin
              if db.Fields[1].AsBoolean then
                Write(f,', <font color="black">',db.Fields[0].AsString,'</font>')
              else
                Write(f,', <font color="gray">',db.Fields[0].AsString,'</font>')
            end;
            db.Next;
          end;
          Writeln(f,'</font>');
          Writeln(f,'</td>');
          Writeln(f,'<td valign="middle" align="left">');
          Writeln(f,'<font color="black">');
          Writeln(f,'<b>WKD: ',wkd,'</b><br>');
          if tmp<>'' then
            Writeln(f,'<font color="black"><b>CFM: ',cfm,'</font></b>');
          Writeln(f,'</font>');
          Writeln(f,'</td>');
          Writeln(f,'</tr>');
          dmData.Q.Next
        finally
          FreeAndNil(db)
        end;
      end;
      Writeln(f,'</table>');
      Writeln(f,'<hr>');
      Writeln(f,'<font color="black">'+LineEnding+'<b>Total:</b><br>');
      Writeln(f,'Worked:',sum_wkd,'<br>');
      Writeln(f,'Confirmed:',sum_cfm,'<br>');
      Writeln(f,'<b>Different squares:</b><br>');
      if cmbBands.Text<>'ALL' then  Writeln(f,'On this band:',thiswkd,'<br>');
      Writeln(f,'On all bands:',allwkdBig,'/',allwkd);
      Writeln(f,'</font>');
      Writeln(f,'</body>');
      Writeln(f,'</html>');
      CloseFile(f);

      if dmData.IsFilter then
         begin
          try
            dmData.Q.Close;
            dmData.Q.SQL.Text:='DROP VIEW IF EXISTS '+TableName;
            dmData.Q.ExecSQL;
            dmData.trQ.Commit;
          Finally
          end;
         end;

    finally
      dmData.trQ.Rollback;
      dmData.trQ1.Rollback
    end;
    CopyFile(TmpFile,ExtractFileNameWithoutExt(TmpFile)+'.html');
    IpHtmlPanel1.OpenURL(expandLocalHtmlFileName(ExtractFileNameWithoutExt(TmpFile)+'.html'))
  finally
    //db.Close;
    //FreeAndNil(db)
  end
end;

procedure TfrmBigSquareStat.btnSaveToClick(Sender: TObject);
begin
  if dlgSave.Execute then
  begin
    cqrini.WriteString('SquareStat','Directory',ExtractFilePath(dlgSave.FileName));
    CopyFile(TmpFile,dlgSave.FileName)
  end
end;

procedure TfrmBigSquareStat.cmbBandsChange(Sender: TObject);
begin
  tmrBlink.Enabled:=True;
  pbTot.Position:=0;
end;

procedure TfrmBigSquareStat.WriteHMTLHeader;
begin
  AssignFile(f,TmpFile);
  Rewrite(f);
  writeln(f,'<html>');
  Writeln(f,'<head>');
  writeln(f,'<meta http-equiv="content-type" content="text/html; charset=utf-8">');
  writeln(f,'<meta name="generator" content="CQRLOG '+cVERSION+', www.cqrlog.com">');
  writeln(f,'<title>Big square statistic ('+cqrini.ReadString('Station','Call','')+')</title>');
  writeln(f,'</head>');
  writeln(f,'<body>');
  Writeln(f,'<font color="black">');
  Writeln(f,'<h1>Big square statistic</h1><br>');
  Writeln(f,'Station:'+cqrini.ReadString('Station','Call','')+'; Band: '+cmbBands.Text);
  Writeln(f,'</font>');
  Writeln(f,'<br>')
end;

procedure TfrmBigSquareStat.FormShow(Sender: TObject);
begin
  TmpFile := GetTempFileNameUTF8(dmData.HomeDir,'square');
  dmUtils.LoadForm(frmBigSquareStat);
  dmUtils.FillBandCombo(cmbBands);
  cmbBands.Items.Insert(0,'ALL');
  if cqrini.ReadInteger('SquareStat','Band',0) > cmbBands.Items.Count-1 then
    cmbBands.ItemIndex := 0
  else
    cmbBands.ItemIndex := cqrini.ReadInteger('SquareStat','Band',0);

  chkQSL.Checked          := cqrini.ReadBool('SquareStat','QSL',False);
  chkLoTW.Checked         := cqrini.ReadBool('SquareStat','LoTW',False);
  chkeQSL.Checked         := cqrini.ReadBool('SquareStat','eQSL',False);
  dlgSave.InitialDir      := cqrini.ReadString('SquareStat','Directory',dmData.UsrHomeDir);

  IpHtmlPanel1.Font.Color := clBlack;
  pbTot.Min:=0;
  pbTot.Max:=1;
  pbTot.Smooth:=True;
  pbTot.Step:=1;
  pbTot.Enabled:=True;
  pbTot.Position:=0;
  tmrBlink.Enabled:=False;
  lblFilterActive.Visible:=  dmData.IsFilter;
  cmbBandsChange(nil);
end;

procedure TfrmBigSquareStat.tmrBlinkStartTimer(Sender: TObject);
begin
  btnRefresh.Caption:='Press to';
  btnRefresh.Font.Color:=clGreen;
  btnRefresh.Repaint;
end;

procedure TfrmBigSquareStat.tmrBlinkStopTimer(Sender: TObject);
begin
  btnRefresh.Caption:='Refresh statistic';
  btnRefresh.Font.Color:=clDefault;
  btnRefresh.Repaint;
end;

procedure TfrmBigSquareStat.tmrBlinkTimer(Sender: TObject);
var
  C :Tcolor;
  t:String;
begin
  case odd(SecondOf(Now)) of
    True:  Begin
            C := clGreen;
            T :='run statistic'
           end;
    False: Begin
            C := clGreen;
            T :='Press to'
    end;
  end;
  btnRefresh.Caption:= T;
  btnRefresh.Font.Color:=C;
  btnRefresh.Repaint;
end;

end.

