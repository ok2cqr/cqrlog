unit fCountyStat;

{$mode objfpc}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Grids, ComCtrls, IpHtml, Ipfilebroker, db, BufDataset,
  LazFileUtils,Dateutils;

type

  { TfrmCountyStat }

  TfrmCountyStat = class(TForm)
    btnClose: TButton;
    btnRefresh: TButton;
    btnSaveTo: TButton;
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
  frmCountyStat: TfrmCountyStat;

implementation
{$R *.lfm}

{ TfrmCountyStat }
uses dUtils,dData, uMyIni, uVersion;

procedure TfrmCountyStat.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveForm(frmCountyStat);
  cqrini.WriteInteger('CountyStat','Band',cmbBands.ItemIndex);
  cqrini.WriteBool('CountyStat','QSL',chkQSL.Checked);
  cqrini.WriteBool('CountyStat','LoTW',chkLoTW.Checked);
  cqrini.WriteBool('CountyStat','eQSL',chkeQSL.Checked);
  DeleteFileUTF8(TmpFile);
  DeleteFileUTF8(ExtractFileNameWithoutExt(TmpFile)+'.html')
end;

procedure TfrmCountyStat.btnRefreshClick(Sender: TObject);
var
  tmp : String = '';
  bnd : String = '';
  grb : String = '';
  allwkd : longint = 0;
  thiswkd : longint =0;
  TotPos : longint = 0;
  wkd : integer = 0;
  cfm : integer = 0;
  ll  : String = '';
  sum_wkd : integer = 0;
  sum_cfm : integer = 0;
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
      dmData.Q.SQL.Text := 'select upper(county) as ll FROM '+TableName+' where county <> '+QuotedStr('')+' group by ll';
      dmData.Q.Open;
      dmData.Q.Last;  //this is needed to get proper record count
      allwkd:=dmData.Q.RecordCount;
      dmData.Q.Close;

      dmData.Q.SQL.Text := 'select upper(county) as ll FROM '+TableName+' where county <> '+QuotedStr('')+
                           bnd+' group by ll';
      dmData.Q.Open;
      dmData.Q.Last;  //this is needed to get proper record count
      pbTot.Max:=dmData.Q.RecordCount;
      thiswkd:= dmData.Q.RecordCount;
      WriteHMTLHeader;
      writeln(f,'<table>');
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
        dmData.Q1.SQL.Text := 'select count(id_cqrlog_main) FROM '+TableName+' where upper(county)='+
                              QuotedStr(ll)+bnd;
        dmData.Q1.Open;

      wkd := dmData.Q1.Fields[0].AsInteger;
      sum_wkd := sum_wkd + wkd;
      if tmp <> '' then
      begin
        dmData.Q1.Close;
        dmData.Q1.SQL.Text := 'select count(id_cqrlog_main) FROM '+TableName+' where upper(county)='+
                          QuotedStr(ll)+bnd+
                              'and ('+tmp+')';
        dmData.Q1.Open;
        cfm := dmData.Q1.Fields[0].AsInteger;
        sum_cfm := sum_cfm + cfm
      end;
      dmData.Q1.Close;

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
      dmData.Q.Next;
      end;
      Writeln(f,'</table>');
      Writeln(f,'<hr>');
      Writeln(f,'<font color="black">'+LineEnding+'<b>Total:</b><br>');
      Writeln(f,'Worked:',sum_wkd,'<br>');
      Writeln(f,'Confirmed:',sum_cfm,'<br>');
      Writeln(f,'<b>Different counties:</b><br>');
      if cmbBands.Text<>'ALL' then  Writeln(f,'On this band:',thiswkd,'<br>');
      Writeln(f,'On all bands:',allwkd);
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
  end
end;

procedure TfrmCountyStat.btnSaveToClick(Sender: TObject);
begin
  if dlgSave.Execute then
  begin
    cqrini.WriteString('CountyStat','Directory',ExtractFilePath(dlgSave.FileName));
    CopyFile(TmpFile,dlgSave.FileName)
  end
end;

procedure TfrmCountyStat.cmbBandsChange(Sender: TObject);
begin
  tmrBlink.Enabled:=True;
  pbTot.Position:=0;
end;

procedure TfrmCountyStat.WriteHMTLHeader;
begin
  AssignFile(f,TmpFile);
  Rewrite(f);
  writeln(f,'<html>');
  Writeln(f,'<head>');
  writeln(f,'<meta http-equiv="content-type" content="text/html; charset=utf-8">');
  writeln(f,'<meta name="generator" content="CQRLOG '+cVERSION+', www.cqrlog.com">');
  writeln(f,'<title>County statistic ('+cqrini.ReadString('Station','Call','')+')</title>');
  writeln(f,'</head>');
  writeln(f,'<body>');
  Writeln(f,'<font color="black">');
  Writeln(f,'<h1>County statistic</h1><br>');
  Writeln(f,'Station:'+cqrini.ReadString('Station','Call','')+'; Band: '+cmbBands.Text);
  Writeln(f,'</font>');
  Writeln(f,'<br>')
end;

procedure TfrmCountyStat.FormShow(Sender: TObject);
begin
  TmpFile := GetTempFileNameUTF8(dmData.HomeDir,'county');
  dmUtils.LoadForm(frmCountyStat);
  dmUtils.FillBandCombo(cmbBands);
  cmbBands.Items.Insert(0,'ALL');
  if cqrini.ReadInteger('CountyStat','Band',0) > cmbBands.Items.Count-1 then
    cmbBands.ItemIndex := 0
  else
    cmbBands.ItemIndex := cqrini.ReadInteger('CountyStat','Band',0);

  chkQSL.Checked          := cqrini.ReadBool('CountyStat','QSL',False);
  chkLoTW.Checked         := cqrini.ReadBool('CountyStat','LoTW',False);
  chkeQSL.Checked         := cqrini.ReadBool('CountyStat','eQSL',False);
  dlgSave.InitialDir      := cqrini.ReadString('CountyStat','Directory',dmData.UsrHomeDir);

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

procedure TfrmCountyStat.tmrBlinkStartTimer(Sender: TObject);
begin
  btnRefresh.Caption:='Press to';
  btnRefresh.Font.Color:=clGreen;
  btnRefresh.Repaint;
end;

procedure TfrmCountyStat.tmrBlinkStopTimer(Sender: TObject);
begin
  btnRefresh.Caption:='Refresh statistic';
  btnRefresh.Font.Color:=clDefault;
  btnRefresh.Repaint;
end;

procedure TfrmCountyStat.tmrBlinkTimer(Sender: TObject);
var
  C :Tcolor;
  T:String;
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

