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
uses dUtils,dData, uMyIni, uVersion, dSqlStat;

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
  wkd : integer = 0;
  cfm : integer = 0;
  ll  : String = '';
  sum_wkd : integer = 0;
  sum_cfm : integer = 0;
  TableName : String;
  squares    : TSquareStatuses;
  i          : Integer;
begin
  tmrBlink.Enabled:=False;
  TableName:='cqrlog_main';
  Screen.Cursor := crHourGlass;
  try
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

    if dmData.IsFilter then
    begin
      try
        TableName:='statistic_filter';
        dmSqlStat.DropStatView(TableName);
        dmSqlStat.CreateStatView(TableName, dmData.IsFilterSQL)
      except
        on E : EDatabaseError do
        begin
          ShowMessage('Can not create filter view!');
          Exit;
        end;
      end;
    end;
    allwkdBig := dmSqlStat.CountBigSquaresWorked(TableName);
    allwkd    := dmSqlStat.CountSquaresWorked(TableName);

    squares := dmSqlStat.ListSquareStatuses(TableName, bnd, tmp);
    WriteHMTLHeader;
    writeln(f,'<table>');
    i := 0;
    while i <= High(squares) do
    begin
      inc(thiswkd);
      ll := copy(squares[i].Square,1,2);
      writeln(f,'<tr>'+LineEnding+'<td valign="middle">'+LineEnding+'<font color="black"><b>'+ll+'</b></font>'+LineEnding+'</td>');
      writeln(f,'<td align="left">');
      writeln(f,'<font color="black">');
      wkd := 0;
      cfm := 0;
      while (i <= High(squares)) and (copy(squares[i].Square,1,2) = ll) do
      begin
        if wkd > 0 then
          Write(f,', ');
        if squares[i].Cfm then
        begin
          Write(f,'<font color="black">',squares[i].Square,'</font>');
          inc(cfm)
        end
        else
          Write(f,'<font color="gray">',squares[i].Square,'</font>');
        inc(wkd);
        inc(i)
      end;
      sum_wkd := sum_wkd + wkd;
      sum_cfm := sum_cfm + cfm;
      Writeln(f,'</font>');
      Writeln(f,'</td>');
      Writeln(f,'<td valign="middle" align="left">');
      Writeln(f,'<font color="black">');
      Writeln(f,'<b>WKD: ',wkd,'</b><br>');
      if tmp<>'' then
        Writeln(f,'<font color="black"><b>CFM: ',cfm,'</font></b>');
      Writeln(f,'</font>');
      Writeln(f,'</td>');
      Writeln(f,'</tr>')
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
    pbTot.Position:=pbTot.Max;

    if dmData.IsFilter then
      dmSqlStat.DropStatView(TableName);

    CopyFile(TmpFile,ExtractFileNameWithoutExt(TmpFile)+'.html');
    IpHtmlPanel1.OpenURL(expandLocalHtmlFileName(ExtractFileNameWithoutExt(TmpFile)+'.html'))
  finally
    Screen.Cursor := crDefault
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

