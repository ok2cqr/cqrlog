unit fDXCCStat;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, Grids,
  ExtCtrls, Buttons, iniFiles, TAGraph, StdCtrls, memds;

type
  TStat = (
    stCfmOnly, //paper only
    stCfmLoTW, //paper + LoTW
    stLoTWOnly,//LoTW only
    stCfmeQSL, //paper + eQSL
    stLoTWeQSL, //LoTW + eQSL
    steQSL,     //eQSL only
    stAll       //paper + LoTW + eQSL
    );

type

  { TfrmDXCCStat }

  TfrmDXCCStat = class(TForm)
    Button1: TButton;
    btnHTMLExport: TButton;
    btnRefresh : TButton;
    cmbCfmType : TComboBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    Label1 : TLabel;
    lblCfmMix: TLabel;
    lblWkdMix: TLabel;
    lblFoneCmf: TLabel;
    lblCWCmf: TLabel;
    lblDIGICmf: TLabel;
    lblFoneWKD: TLabel;
    lblCWWKD: TLabel;
    lblDIGIWKD: TLabel;
    Panel1: TPanel;
    grdStat: TStringGrid;
    grdDXCCStat: TStringGrid;
    dlgSave: TSaveDialog;
    Panel2 : TPanel;
    procedure btnHTMLExportClick(Sender: TObject);
    procedure btnRefreshClick(Sender : TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    StatType : TStat;

    function  GetStatTypeWhere(st : TStat) : String;
    function  GetFieldText(fone,cw,digi : String) : String;
    function  GetDXCCPhoneCount(deleted : Boolean) : Word;
    function  GetDXCCPhoneCfmCount(deleted : Boolean) : Word;
    function  GetDXCCCWCount(deleted : Boolean) : Word;
    function  GetDXCCCWCfmCount(deleted : Boolean) : Word;
    function  GetDXCCDigiCount(deleted : Boolean) : Word;
    function  GetDXCCDigiCfmCount(deleted : Boolean) : Word;
    function  GetMixCount(deleted : Boolean) : Word;
    function  GetMixCfmCount(deleted : Boolean) : Word;

    procedure LoadBandsSettings;
    procedure CreateStatistic;
    procedure CreateModeStatistic;
    procedure CreateTotalStatistic;
    procedure ChangeCaption;
  public
    procedure ExportToHTML(FileName : String);
  end; 

var
  frmDXCCStat: TfrmDXCCStat;

implementation
{$R *.lfm}

{ TfrmDXCCStat }
uses dData, dUtils, dDXCC, uMyIni;

procedure TfrmDXCCStat.ChangeCaption;
const
  C_CAPTION = 'DXCC statistics - ';
begin
  case StatType of
    stCfmOnly  : Caption := C_CAPTION + 'confirmed only';
    stCfmLoTW  : Caption := C_CAPTION + 'LoTW and confirmed';
    stLoTWOnly : Caption := C_CAPTION + 'LoTW only';
    stCfmeQSL  : Caption := C_CAPTION + 'confirmed and eQSL';
    stLoTWeQSL : Caption := C_CAPTION + 'LoTW and eQSL';
    steQSL     : Caption := C_CAPTION + 'eQSL only';
    stAll      : Caption := C_CAPTION + 'paper, eQSL and LoTW';
  end //case
end;

procedure TfrmDXCCStat.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(self);
  LoadBandsSettings;

  if cqrini.ReadBool('Fonts','GridGreenBar',False) = True then
  begin
    grdDXCCStat.AlternateColor:=$00E7FFEB;
    grdStat.AlternateColor:=$00E7FFEB;
    grdDXCCStat.Options:=[goRowSelect,goRangeSelect,goSmoothScroll,goVertLine,goFixedVertLine];
    grdStat.Options:=[goRowSelect,goRangeSelect,goSmoothScroll,goVertLine,goFixedVertLine];
  end
  else begin
    grdDXCCStat.AlternateColor:=clWindow;
    grdStat.AlternateColor:=clWindow;
    grdDXCCStat.Options:=[goRangeSelect,goSmoothScroll,goVertLine,goFixedVertLine,goFixedHorzLine,goHorzline];
    grdStat.Options:=[goRangeSelect,goSmoothScroll,goVertLine,goFixedVertLine,goFixedHorzLine,goHorzline];
  end;

  grdDXCCStat.Cells[0,0] := 'DXCC';
  grdDXCCStat.Cells[1,0] := 'Country';

  cmbCfmType.ItemIndex := cqrini.ReadInteger('DXCC','LastStat',6);
  StatType := TStat(cmbCfmType.ItemIndex);
  btnRefresh.Click
end;

procedure TfrmDXCCStat.btnHTMLExportClick(Sender: TObject);
begin
  dlgSave.InitialDir := dmData.UsrHomeDir;
  dlgSave.DefaultExt := '.html';
  dlgSave.Filter := 'html|*.html;*.HTML';;
  if dlgSave.Execute then
  begin
    ExportToHTML(dlgSave.FileName)
  end
end;

procedure TfrmDXCCStat.btnRefreshClick(Sender : TObject);
var
  dxcc_fone     : Integer = 0;
  dxcc_fone_cfm : Integer = 0;
  dxcc_cw       : Integer = 0;
  dxcc_cw_cfm   : Integer = 0;
  dxcc_digi     : Integer = 0;
  dxcc_digi_cfm : Integer = 0;
  ShowDel  : Boolean = False;
begin
  Cursor := crSQLWait;
  try
    cqrini.WriteInteger('DXCC','LastStat',cmbCfmType.ItemIndex);
    StatType := TStat(cmbCfmType.ItemIndex);
    ChangeCaption;
    ShowDel  := cqrini.ReadBool('Program','ShowDeleted',False);

    dxcc_fone     := GetDXCCPhoneCount(ShowDel);
    dxcc_fone_cfm := GetDXCCPhoneCfmCount(ShowDel);

    dxcc_cw       := GetDXCCCWCount(ShowDel);
    dxcc_cw_cfm   := GetDXCCCWCfmCount(ShowDel);

    dxcc_digi     := GetDXCCDigiCount(ShowDel);
    dxcc_digi_cfm := GetDXCCDigiCfmCount(ShowDel);

    lblFoneWKD.Caption := 'WKD: ' + IntToStr(dxcc_fone);
    lblFoneCmf.Caption := 'CFM: ' + IntToStr(dxcc_fone_cfm);

    lblCWWKD.Caption   := 'WKD: ' + IntToStr(dxcc_cw);
    lblCWCmf.Caption   := 'CFM: ' + IntToStr(dxcc_cw_cfm);

    lblDIGIWKD.Caption := 'WKD: ' + IntToStr(dxcc_digi);
    lblDIGICmf.Caption := 'CFM: ' + IntToStr(dxcc_digi_cfm);

    lblWkdMix.Caption  := 'WKD: ' + IntToStr(GetMixCount(ShowDel));
    lblCfmMix.Caption  := 'CFM: ' + IntToStr(GetMixCfmCount(ShowDel));

    CreateStatistic
  finally
    Cursor := crDefault
  end
end;

procedure TfrmDXCCStat.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  dmUtils.SaveWindowPos(self)
end;

procedure TfrmDXCCStat.ExportToHTML(FileName : String);
var
  f      : TextFile;
  MyCall : String ='';
  i      : Integer = 0;
  y      : integer = 0;
  tmp    : String = '';
begin
  MyCall := cqrini.ReadString('Station','Call','');

  AssignFile(f,FileName);
  Rewrite(f);
  Writeln(f,'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">');
  WriteLn(f,'<HTML>');
  Writeln(f,'<HEAD>');
  Writeln(f,'<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=utf8">');
  Writeln(f,'<TITLE> DXCC statistics of '+MyCAll+' </TITLE>');
  Writeln(f,'<META NAME="GENERATOR" CONTENT="CQRLOG ver. '+ '0.3' +'">');
  Writeln(f,'<style type="text/css">');
  Writeln(f,'<!--');
  Writeln(f,'.popis {color: #FFFFFF}');
  Writeln(f,'.hlava {');
  Writeln(f,'	color: #333366;');
  Writeln(f,'	font-family: Verdana, AriSBal, Helvetica, sans-serif;');
  Writeln(f,'	font-size: 12px;');
  Writeln(f,'	font-weight: bold;');
  Writeln(f,'}');
  Writeln(f,'-->');
  Writeln(f,'</style>');
  Writeln(f,'</HEAD>');
  Writeln(f,'<BODY>');
  Writeln(f,'<BR>');
  Writeln(f,'<H1 ALIGN=CENTER> DXCC statistics of '+ MyCall + '</H1>');
  Writeln(f,'<BR>');
  Writeln(f,'');
  Writeln(f,'');

  Writeln(f,'<table border="1" cellpading="2" cellspacing="0" style="font-family: Courier;">');
  Writeln(f,'<col width="40">');
  Writeln(f,'<col width="300">');
  for i:= 1 to grdDXCCStat.ColCount -2 do
    Writeln(f,'<col width="60">');

  Writeln(f,'<tr valign="top">');

  Writeln(f,'<td width="40" bgcolor="#333366" class="hlava">');
  Writeln(f,'><div align="center" class="popis">Prefix</div>');
  Writeln(f,'<p align="center"><br>');
  Writeln(f,'</p>');
  Writeln(f,'</td>');

  Writeln(f,'<td width="300" bgcolor="#333366" class="hlava">');
  Writeln(f,'<div align="center" class="popis">Country</div>');
  Writeln(f,'</td>');
  for i:=2 to grdDXCCStat.ColCount -1 do
  begin
    Writeln(f,'<td width="40" bgcolor="#333366" class="hlava">');
    tmp := grdDXCCStat.Cells[i,0];
    tmp := tmp + '<br>F&nbsp;C&nbsp;D';
    Writeln(f,'<div align="center" class="popis">' + tmp +  '</div>');
    Writeln(f,'</td>');
  end;  //^^ table header
  Writeln(f,'</tr>');

  for y := 1 to grdDXCCStat.RowCount-1 do
  begin
    Writeln(f,'<tr valign="top">');
    Writeln(f,'<td width="40" bgcolor="#333366" class="hlava">');
    Writeln(f,'<div align="center" class="popis">'+grdDXCCStat.Cells[0,y]);
    Writeln(f,'</div>');
    Writeln(f,'</td>');

    Writeln(f,'<td width="200" bgcolor="#333366" class="hlava">');
    Writeln(f,'<div align="center" class="popis">'+grdDXCCStat.Cells[1,y]);
    Writeln(f,'</div>');
    Writeln(f,'</td>');

    Writeln(f,'');

    for i := 2 to grdDXCCStat.ColCount-1 do
    begin
      Writeln(f,'<td width="40">');
      tmp := dmUtils.ReplaceSpace(grdDXCCStat.Cells[i,y]);
      Writeln(f,'<p>'+ tmp);
      Writeln(f,'</p>');
      Writeln(f,'</td>');
    end;
    Writeln(f,'</tr>');
  end;
  Writeln(f,'</tr>');
  Writeln(f,'</table>');
  Writeln(f,'<br>');
  Writeln(f,'<br>');

  Writeln(f,'<!-- Hmm ... -->');

  Writeln(f,'<TABLE WIDTH="'+ IntToStr(40 + 200 + 60*(grdDXCCStat.ColCount -1)) + '" BORDER=1 CELLPADDING=2 CELLSPACING=0>');
  Writeln(f,'<COL WIDTH=200>');

  for i:= 1 to grdDXCCStat.ColCount -1 do
    Writeln(f,'<COL WIDTH=40>');

  Writeln(f,'<TR VALIGN=TOP>');

  Writeln(f,'<TD WIDTH=200 bgcolor="#333366" class="hlava">');
  Writeln(f,'<P ALIGN=CENTER><FONT SIZE=2>&nbsp</FONT></P>');
  Writeln(f,'</TD>');
  for i:=1 to grdDXCCStat.ColCount -1 do
  begin
    Writeln(f,'<TD WIDTH=40 bgcolor="#333366" class="hlava">');
    tmp := grdStat.Cells[i,0];
    Writeln(f,'<div align="center" class="popis">' + tmp +  '</div>');
    Writeln(f,'</TD>');
  end;  //^^ table header
  Writeln(f,'</TR>');

  Writeln(f,'<TR>');
  Writeln(f,'<TD WIDTH=200 bgcolor="#333366" class="hlava">');
  Writeln(f,'<div align="center" class="popis">DXCC Count</div>');
  Writeln(f,'</TD>');
  for i:=1 to grdDXCCStat.ColCount -1 do
  begin
    Writeln(f,'<TD WIDTH=60>');
    tmp := grdStat.Cells[i,1];
    Writeln(f,'<P ALIGN=CENTER><FONT SIZE=2>' + tmp +  '</FONT></P>');
    Writeln(f,'</TD>');
  end;
  Writeln(f,'</TR>');

  Writeln(f,'<TR>');
  Writeln(f,'<TD WIDTH=200 bgcolor="#333366" class="hlava">');
  Writeln(f,'<div align="center" class="popis">DXCC CFM</div>');
  Writeln(f,'</TD>');
  for i:=1 to grdDXCCStat.ColCount -1 do
  begin
    Writeln(f,'<TD WIDTH=40>');
    tmp := grdStat.Cells[i,2];
    Writeln(f,'<P ALIGN=CENTER><FONT SIZE=2><B>' + tmp +  '</B></FONT></P>');
    Writeln(f,'</TD>');
  end;
  Writeln(f,'</TR>');

  Writeln(f,'<TR>');
  Writeln(f,'<TD WIDTH=200 bgcolor="#333366" class="hlava">');
  Writeln(f,'<div align="center" class="popis">DXCC PHONE</div>');
  Writeln(f,'</TD>');
  for i:=1 to grdDXCCStat.ColCount -1 do
  begin
    Writeln(f,'<TD WIDTH=40>');
    tmp := grdStat.Cells[i,4];
    Writeln(f,'<P ALIGN=CENTER><FONT SIZE=2>' + tmp +  '</FONT></P>');
    Writeln(f,'</TD>');
  end;
  Writeln(f,'</TR>');

  Writeln(f,'<TR>');
  Writeln(f,'<TD WIDTH=200 bgcolor="#333366" class="hlava">');
  Writeln(f,'<div align="center" class="popis">DXCC CFM PHONE</div>');
  Writeln(f,'</TD>');
  for i:=1 to grdDXCCStat.ColCount -1 do
  begin
    Writeln(f,'<TD WIDTH=40>');
    tmp := grdStat.Cells[i,5];
    Writeln(f,'<P ALIGN=CENTER><FONT SIZE=2><B>' + tmp +  '</B></FONT></P>');
    Writeln(f,'</TD>');
  end;
  Writeln(f,'</TR>');

  Writeln(f,'<TR>');
  Writeln(f,'<TD WIDTH=200 bgcolor="#333366" class="hlava">');
  Writeln(f,'<div align="center" class="popis">DXCC CW</div>');
  Writeln(f,'</TD>');
  for i:=1 to grdDXCCStat.ColCount -1 do
  begin
    Writeln(f,'<TD WIDTH=40>');
    tmp := grdStat.Cells[i,6];
    Writeln(f,'<P ALIGN=CENTER><FONT SIZE=2>' + tmp +  '</FONT></P>');
    Writeln(f,'</TD>');
  end;
  Writeln(f,'</TR>');

  Writeln(f,'<TR>');
  Writeln(f,'<TD WIDTH=200 bgcolor="#333366" class="hlava">');
  Writeln(f,'<div align="center" class="popis">DXCCCFM CW</div>');
  Writeln(f,'</TD>');
  for i:=1 to grdDXCCStat.ColCount -1 do
  begin
    Writeln(f,'<TD WIDTH=40>');
    tmp := grdStat.Cells[i,7];
    Writeln(f,'<P ALIGN=CENTER><FONT SIZE=2><B>' + tmp +  '</B></FONT></P>');
    Writeln(f,'</TD>');
  end;
  Writeln(f,'</TR>');

  Writeln(f,'<TR>');
  Writeln(f,'<TD WIDTH=200 bgcolor="#333366" class="hlava">');
  Writeln(f,'<div align="center" class="popis">DXCC DIGI</div>');
  Writeln(f,'</TD>');
  for i:=1 to grdDXCCStat.ColCount -1 do
  begin
    Writeln(f,'<TD WIDTH=40>');
    tmp := grdStat.Cells[i,8];
    Writeln(f,'<P ALIGN=CENTER><FONT SIZE=2>' + tmp +  '</FONT></P>');
    Writeln(f,'</TD>');
  end;
  Writeln(f,'</TR>');

  Writeln(f,'<TR>');
  Writeln(f,'<TD WIDTH=200 bgcolor="#333366" class="hlava">');
  Writeln(f,'<div align="center" class="popis">DXCC CFM DIGI</div>');
  Writeln(f,'</TD>');
  for i:=1 to grdDXCCStat.ColCount -1 do
  begin
    Writeln(f,'<TD WIDTH=40>');
    tmp := grdStat.Cells[i,9];
    Writeln(f,'<P ALIGN=CENTER><FONT SIZE=2><B>' + tmp +  '</B></FONT></P>');
    Writeln(f,'</TD>');
  end;
  Writeln(f,'</TR>');


  Writeln(f,'</TABLE>');

  Writeln(f,'<br><br>');
  Writeln(f,'<fieldset style="width:100">');
  Writeln(f,'<legend>Phone</legend>');
  //Writeln(f,'<b>Phone:</b>');
  Writeln(f,lblFoneWKD.Caption);
  Writeln(f,'<br>');
  Writeln(f,lblFoneCmf.Caption);
  Writeln(f,'</fieldset>');

  Writeln(f,'<br><br>');
  Writeln(f,'<fieldset style="width:100">');
  Writeln(f,'<legend>CW</legend>');
  Writeln(f,lblCWWKD.Caption);
  Writeln(f,'<br>');
  Writeln(f,lblCWCmf.Caption);
  Writeln(f,'</fieldset>');

  Writeln(f,'<br><br>');
  Writeln(f,'<fieldset style="width:100">');
  Writeln(f,'<legend>DIGI</legend>');
  Writeln(f,lblDIGIWKD.Caption);
  Writeln(f,'<br>');
  Writeln(f,lblDIGICmf.Caption);
  Writeln(f,'</fieldset>');

  Writeln(f,'<br><br>');
  Writeln(f,'<fieldset style="width:100">');
  Writeln(f,'<legend>MIX</legend>');
  Writeln(f,lblWkdMix.Caption);
  Writeln(f,'<br>');
  Writeln(f,lblCfmMix.Caption);
  Writeln(f,'</fieldset>');

  Writeln(f,'<BR> <BR>');
  Writeln(f,'<H5 ALIGN=CENTER> <A HREF="http://www.cqrlog.com">CQRLOG ver. ' + dmData.VersionString  + ' </A></H5>');
  Writeln(f,'</BODY>');
  Writeln(f,'</HTML>');

  CloseFile(f);
end;
procedure TfrmDXCCStat.FormCreate(Sender: TObject);
begin
  dmUtils.LoadWindowPos(self)
end;

function TfrmDXCCStat.GetFieldText(fone,cw,digi : String) : String;
var
  space: String;
begin
  space := ' ';
  // Dots instead spaces, tom@dl7bj.de, 2014-06-24
  if cqrini.ReadBool('Fonts','GridDotsInsteadSpaces',False) = True then
  begin
    space := '.';
  end;

   if (fone = '') then
    fone := space+' '
  else
    fone := fone+' ';

  if (cw = '') then
    cw := space+' '
  else
    cw := cw+' ';

  if (digi='') then
    digi := space+' '
  else
    digi := digi+' ';

  Result :=  fone + cw + digi
end;

procedure TfrmDXCCStat.LoadBandsSettings;
var
  i : Integer = 0;
begin
  grdDXCCStat.ColCount := cMaxBandsCount;
  grdStat.ColCount     := cMaxBandsCount;
  for i:=0 to cMaxBandsCount-1 do
  begin
    if dmUtils.MyBands[i][0]='' then
    begin
      grdDXCCStat.ColCount := i+2;
      grdStat.ColCount     := i+1;
      break
    end;
    grdDXCCStat.Cells[i+2,0] := dmUtils.MyBands[i][1];
    grdStat.Cells[i+1,0]     := dmUtils.MyBands[i][1];
  end;
  grdDXCCStat.ColWidths[grdStat.ColCount-1] := 50;
  grdStat.ColWidths[grdStat.ColCount-1]     := 50
end;

procedure TfrmDXCCStat.CreateModeStatistic;
var
  BandPos : Integer;
  sql2    : String;
  ShowDel : Boolean;

  procedure WriteToGrid(const Row : Integer);
  begin
    dmData.Q.First;
    while not dmData.Q.Eof do
    begin
      BandPos := dmUtils.GetBandPos(dmData.Q.Fields[0].AsString);
      if BandPos = -1 then
      begin
        dmData.Q.Next;
        Continue
      end;
      BandPos := BandPos + 1;
      if dmData.Q.Fields[1].AsString = '' then
        grdStat.Cells[BandPos,Row] := '0'
      else
        grdStat.Cells[BandPos,Row] := dmData.Q.Fields[1].AsString;
      dmData.Q.Next
    end
  end;

  procedure GetSQLMode(const mode : String);
  begin
    if ShowDel then
      dmData.Q.SQL.Text := 'select band,count(distinct adif) from cqrlog_main '+
                           'where adif <> 0 and' + mode + ' group by band'
    else
      dmData.Q.SQL.Text := 'select band,count(distinct adif) from cqrlog_main '+
                           '  where adif <> 0 and (' + sql2 +') and '+mode+' group by band'
  end;

  procedure GetCfmSQLMode(const mode : String);
  const
    C_DISTSEL = 'select band,count(distinct adif) from cqrlog_main where adif <> 0 and ';
  begin
    if ShowDel then
    begin
      dmData.Q.SQL.Text := C_DISTSEL+GetStatTypeWhere(StatType)+ ' and '+ mode +' group by band';
      {
      case StatType of
         stCfmOnly  : dmData.Q.SQL.Text := C_SEL + '(qsl_r = '+QuotedStr('Q')+') and '+mode+' group by band';
         stCfmLoTW  : dmData.Q.SQL.Text := C_SEL + '((qsl_r = '+QuotedStr('Q')+') or (lotw_qslr='+
                                            QuotedStr('L')+')) and ' + mode + ' group by band';
         stLoTWOnly : dmData.Q.SQL.Text := 'select band,count(distinct adif) from cqrlog_main '+
                                           'where adif <> 0 and (lotw_qslr = '+QuotedStr('L')+') and ' + mode +
                                           ' group by band'
      end //case
      }
    end
    else begin
      dmData.Q.SQL.Text := C_DISTSEL+GetStatTypeWhere(StatType)+ ' and ' +sql2+ ' and '+mode+' group by band';
      {

      case StatType of
         stCfmOnly  : dmData.Q.SQL.Text := 'select band,count(distinct adif) from cqrlog_main '+
                                           'where adif <> 0 and (qsl_r = '+QuotedStr('Q')+') and '+ sql2+
                                           ' and '+ mode + ' group by band';
         stCfmLoTW  : dmData.Q.SQL.Text := 'select band,count(distinct adif) from cqrlog_main '+
                                           'where adif <> 0 and ((qsl_r = '+QuotedStr('Q')+') or (lotw_qslr='+
                                            QuotedStr('L')+')) and ' + sql2+ ' and '+ mode +
                                            ' group by band';
         stLoTWOnly : dmData.Q.SQL.Text := 'select band,count(distinct adif) from cqrlog_main '+
                                           'where adif <> 0 and (lotw_qslr = '+QuotedStr('L')+') and '+sql2+
                                           ' and ' + mode + ' group by band'
      end //case
      }
    end;
  end;

const
  C_SEL = 'select band,count(distinct adif) from cqrlog_main where adif <> 0 and ';

begin
  grdStat.ColWidths[0] := 110;
  grdStat.Cells[0,1] := 'DXCC';
  grdStat.Cells[0,2] := 'DXCC CFM';

  grdStat.Cells[0,4] := 'DXCC PHONE';
  grdStat.Cells[0,5] := 'DXCC CFM PHONE';

  grdStat.Cells[0,6] := 'DXCC CW';
  grdStat.Cells[0,7] := 'DXCC CFM CW';

  grdStat.Cells[0,8] := 'DXCC DIGI';
  grdStat.Cells[0,9] := 'DXCC CFM DIGI';

  ShowDel := cqrini.ReadBool('Program','ShowDeleted',False);

  if ShowDel then
    sql2 := ''
  else
    sql2 := dmDXCC.GetDelDXCCAdifList;

  dmData.Q.Close;
  dmData.trQ.Rollback;
  dmData.trQ.StartTransaction;
  try
    if ShowDel then
      dmData.Q.SQL.Text := 'select band,count(distinct adif) from cqrlog_main where adif <> 0'+
                           ' group by band'
    else
      dmData.Q.SQL.Text := 'select band,count(distinct adif) from cqrlog_main '+
                           '  where adif <> 0 and ' + sql2 +' group by band';
    dmData.Q.Open;
    WriteToGrid(1);
    dmData.Q.Close;

    if ShowDel then
    begin
      dmData.Q.SQL.Text := C_SEL+GetStatTypeWhere(StatType)+' group by band'
      {case StatType of

        stCfmOnly  : dmData.Q.SQL.Text := 'select band,count(distinct adif) from cqrlog_main '+
                                           'where adif <> 0 and qsl_r = '+QuotedStr('Q')+' group by band';
         stCfmLoTW  : dmData.Q.SQL.Text := 'select band,count(distinct adif) from cqrlog_main '+
                                            'where adif <> 0 and ((qsl_r = '+QuotedStr('Q')+') or (lotw_qslr='+
                                            QuotedStr('L')+')) group by band';
         stLoTWOnly : dmData.Q.SQL.Text := 'select band,count(distinct adif) from cqrlog_main '+
                                           'where adif <> 0 and lotw_qslr = '+QuotedStr('L')+' group by band';

      end //case}
    end
    else begin
      dmData.Q.SQL.Text := C_SEL+GetStatTypeWhere(StatType)+' and '+sql2+' group by band'
      {case StatType of
         stCfmOnly  : dmData.Q.SQL.Text := 'select band,count(distinct adif) from cqrlog_main '+
                                           'where adif <> 0 and (qsl_r = '+QuotedStr('Q')+') and '+ sql2+
                                           ' group by band';
         stCfmLoTW  : dmData.Q.SQL.Text := 'select band,count(distinct adif) from cqrlog_main '+
                                           'where adif <> 0 and ((qsl_r = '+QuotedStr('Q')+') or (lotw_qslr='+
                                            QuotedStr('L')+')) and ' + sql2+ ' group by band';
         stLoTWOnly : dmData.Q.SQL.Text := 'select band,count(distinct adif) from cqrlog_main '+
                                           'where adif <> 0 and (lotw_qslr = '+QuotedStr('L')+') and '+sql2+
                                           ' group by band';
      end //case}
    end;
    dmData.Q.Open;
    WriteToGrid(2);
    dmData.Q.Close;

    GetSQLMode('((mode='+QuotedStr('SSB')+') or (mode='+QuotedStr('AM')+') '+
               'or (mode ='+QuotedStr('FM')+'))');
    dmData.Q.Open;
    WriteToGrid(4);
    dmData.Q.Close;
    GetCfmSQLMode('((mode='+QuotedStr('SSB')+') or (mode='+QuotedStr('AM')+') '+
               'or (mode ='+QuotedStr('FM')+'))');
    dmData.Q.Open;
    WriteToGrid(5);
    dmData.Q.Close;

    GetSQLMode('((mode='+QuotedStr('CW')+') or (mode='+QuotedStr('CWR')+'))');
    dmData.Q.Open;
    WriteToGrid(6);
    dmData.Q.Close;
    GetCfmSQLMode('((mode='+QuotedStr('CW')+') or (mode='+QuotedStr('CWR')+'))');
    dmData.Q.Open;
    WriteToGrid(7);
    dmData.Q.Close;


    GetSQLMode('((mode<>'+QuotedStr('CW')+') and (mode<>'+QuotedStr('CWR')+') '+
               'and (mode<>'+QuotedStr('SSB')+') and (mode<>'+QuotedStr('FM')+')'+
               'and (mode<>'+QuotedStr('AM')+'))');
    dmData.Q.Open;
    WriteToGrid(8);
    dmData.Q.Close;
    GetCfmSQLMode('((mode<>'+QuotedStr('CW')+') and (mode<>'+QuotedStr('CWR')+') '+
                  'and (mode<>'+QuotedStr('SSB')+') and (mode<>'+QuotedStr('FM')+')'+
                  'and (mode<>'+QuotedStr('AM')+'))');
    dmData.Q.Open;
    WriteToGrid(9);
    dmData.Q.Close
  finally
    dmData.Q.Close;
    dmData.trQ.Rollback
  end
end;

procedure TfrmDXCCStat.CreateStatistic;

type
  TMode = record
    SSB  : String[2];
    CW   : String[2];
    DIGI : String[2]
  end;

var
  Deleted   : Boolean = False;
  Prefix    : String = '';
  OldPrefix : String = '';
  QSLR      : String = '';
  LoTW      : String = '';
  eQSL      : String = '';
  BandMode  : Array of TMode;
  y         : Integer = 1;
  i         : Integer;
  BandPos   : Integer;
  Mode      : String;
  mDXCC     : TMemDataset;
  Country   : String;
  space     : String;
begin
  grdDXCCStat.RowCount := 2;
  LoadBandsSettings;
  Deleted := cqrini.ReadBool('Program','ShowDeleted',False);
  SetLength(BandMode,grdDXCCStat.ColCount-2);
  grdDXCCStat.ColWidths[1] := 160;

  space := '';
  // dots instead spaces, tom@dl7bj.de, 2014-06-24
  if cqrini.ReadBool('Fonts','GridDotsInsteadSpaces', False) then
  begin
    Space := '.';
  end;

  mDXCC := TMemDataset.Create(nil);
  try
    try
      dmData.Q.Close;
      if Deleted then
        dmData.Q.SQL.Text := 'select d.dxcc_ref,d.country, c.band, c.mode, c.qsl_r,c.lotw_qslr,c.eqsl_qsl_rcvd from cqrlog_main c '+
                             'left join dxcc_id d on c.adif = d.adif where d.dxcc_ref<>'+QuotedStr('')+' and d.dxcc_ref<>'+QuotedStr('!')+
                             ' group by d.dxcc_ref,c.band,c.mode,c.qsl_r,c.lotw_qslr,c.eqsl_qsl_rcvd order by d.dxcc_ref,c.band,c.mode,c.qsl_r,c.lotw_qslr,c.eqsl_qsl_rcvd'
      else
        dmData.Q.SQL.Text := 'select d.dxcc_ref,d.country, c.band, c.mode, c.qsl_r,c.lotw_qslr,c.eqsl_qsl_rcvd from cqrlog_main c '+
                             'left join dxcc_id d on c.adif = d.adif where (d.dxcc_ref<>'+QuotedStr('')+') and d.dxcc_ref<>'+QuotedStr('!')+
                             ' and (d.dxcc_ref not like '+QuotedStr('%*')+') group by d.dxcc_ref,c.band,c.mode,'+
                             'c.qsl_r,c.lotw_qslr,c.eqsl_qsl_rcvd order by d.dxcc_ref,c.band,c.mode,c.qsl_r,c.lotw_qslr,c.eqsl_qsl_rcvd';


      dmData.trQ.StartTransaction;
      dmData.Q.Open;

      mDXCC.CopyFromDataset(dmData.Q);
      mDXCC.Open;
      mDXCC.Append;
      mDXCC.Fields[0].AsString := '';
      mDXCC.FieldByName('mode').AsString := '';
      mDXCC.Post;
      mDXCC.First
    finally
      dmData.Q.Close;
      dmData.trQ.Rollback
    end;
    Prefix    := mDXCC.Fields[0].AsString;
    Country   := mDXCC.Fields[1].AsString;
    OldPrefix := Prefix;
    grdDXCCStat.Cells[0,y] := Prefix;
    grdDXCCStat.Cells[1,y] := Country;

    if Space = '.' then
    begin
      for i:=0 to Length(BandMode)-1 do
      begin
        grdDXCCStat.Cells[i+2,y] := GetFieldText(BandMode[i].SSB,BandMode[i].CW,BandMode[i].DIGI);
        BandMode[i].CW   := Space;
        BandMode[i].SSB  := Space;
        BandMode[i].DIGI := Space;
      end;
    end;

    while not mDXCC.Eof do
    begin
      Prefix    := mDXCC.Fields[0].AsString;
      Country   := mDXCC.Fields[1].AsString;
      if Prefix <> OldPrefix then
      begin
        for i:=0 to Length(BandMode)-1 do
        begin
          grdDXCCStat.Cells[i+2,y] := GetFieldText(BandMode[i].SSB,BandMode[i].CW,BandMode[i].DIGI);
          BandMode[i].CW   := space;
          BandMode[i].SSB  := space;
          BandMode[i].DIGI := space;
        end;
        inc(y);
        OldPrefix := Prefix;
        grdDXCCStat.RowCount := y+1;
        grdDXCCStat.Cells[0,y] := Prefix;
        grdDXCCStat.Cells[1,y] := Country
      end;
      if Prefix = '' then
      begin
        mDXCC.Next;
        Continue
      end;
      BandPos := dmUtils.GetBandPos(mDXCC.Fields[2].AsString);
      Mode    := mDXCC.Fields[3].AsString;
      QSLR    := mDXCC.Fields[4].AsString;
      LoTW    := mDXCC.Fields[5].AsString;
      eQSL    := mDXCC.Fields[6].AsString;
      if BandPos = -1 then
      begin
        mDXCC.Next;
        Continue
      end;
      case StatType of
        stCfmOnly  : begin
                       if (Mode = 'SSB') or (Mode='FM') or (Mode='AM') then
                       begin
                         if QSLR = 'Q' then
                           BandMode[BandPos].SSB := 'Q'
                         else if BandMode[BandPos].SSB = space then
                           BandMode[BandPos].SSB := 'X'
                       end
                       else begin
                         if (Mode='CW') or (Mode='CWQ') then
                         begin
                           if QSLR = 'Q' then
                             BandMode[BandPos].CW := 'Q'
                           else if BandMode[BandPos].CW = space then
                             BandMode[BandPos].CW := 'X'
                         end
                         else begin
                           if QSLR = 'Q' then
                             BandMode[BandPos].DIGI := 'Q'
                           else if BandMode[BandPos].DIGI = space then
                             BandMode[BandPos].DIGI := 'X'
                         end
                       end
                     end;
        stCfmLoTW  : begin
                       if (Mode = 'SSB') or (Mode='FM') or (Mode='AM') then
                       begin
                         if QSLR = 'Q' then
                           BandMode[BandPos].SSB := 'Q'
                         else if (LoTW = 'L') then
                           BandMode[BandPos].SSB := 'L'
                         else if (BandMode[BandPos].SSB = space) then
                           BandMode[BandPos].SSB := 'X'
                       end
                       else begin
                         if (Mode='CW') or (Mode='CWQ') then
                         begin
                           if QSLR = 'Q' then
                             BandMode[BandPos].CW := 'Q'
                           else if (LoTW='L') then
                             BandMode[BandPos].CW := 'L'
                           else if BandMode[BandPos].CW = space then
                             BandMode[BandPos].CW := 'X'
                         end
                         else begin
                           if QSLR = 'Q' then
                             BandMode[BandPos].DIGI := 'Q'
                           else if (LoTW='L') then
                             BandMode[BandPos].DIGI := 'L'
                           else if BandMode[BandPos].DIGI = space then
                             BandMode[BandPos].DIGI := 'X'
                         end
                       end
                     end;
        stLoTWOnly : begin
                       if (Mode = 'SSB') or (Mode='FM') or (Mode='AM') then
                       begin
                         if LoTW = 'L' then
                           BandMode[BandPos].SSB := 'L'
                         else if BandMode[BandPos].SSB = space then
                           BandMode[BandPos].SSB := 'X'
                       end
                       else begin
                         if (Mode='CW') or (Mode='CWQ') then
                         begin
                           if LoTW = 'L' then
                             BandMode[BandPos].CW := 'L'
                           else if BandMode[BandPos].CW = space then
                             BandMode[BandPos].CW := 'X'
                         end
                         else begin
                           if LoTW = 'L' then
                             BandMode[BandPos].DIGI := 'L'
                           else if BandMode[BandPos].DIGI = space then
                             BandMode[BandPos].DIGI := 'X'
                         end
                       end
                     end;
        stCfmeQSL  : begin
                       if (Mode = 'SSB') or (Mode='FM') or (Mode='AM') then
                       begin
                         if QSLR = 'Q' then
                           BandMode[BandPos].SSB := 'Q'
                         else if (eQSL = 'E') then
                           BandMode[BandPos].SSB := 'E'
                         else if (BandMode[BandPos].SSB = space) then
                           BandMode[BandPos].SSB := 'X'
                       end
                       else begin
                         if (Mode='CW') or (Mode='CWQ') then
                         begin
                           if QSLR = 'Q' then
                             BandMode[BandPos].CW := 'Q'
                           else if (eQSL='E') then
                             BandMode[BandPos].CW := 'E'
                           else if BandMode[BandPos].CW = space then
                             BandMode[BandPos].CW := 'X'
                         end
                         else begin
                           if QSLR = 'Q' then
                             BandMode[BandPos].DIGI := 'Q'
                           else if (eQSL='E') then
                             BandMode[BandPos].DIGI := 'E'
                           else if BandMode[BandPos].DIGI = space then
                             BandMode[BandPos].DIGI := 'X'
                         end
                       end
                     end;
        stLoTWeQSL : begin
                       if (Mode = 'SSB') or (Mode='FM') or (Mode='AM') then
                       begin
                         if LoTW = 'L' then
                           BandMode[BandPos].SSB := 'L'
                         else if (eQSL = 'E') then
                           BandMode[BandPos].SSB := 'E'
                         else if (BandMode[BandPos].SSB = space) then
                           BandMode[BandPos].SSB := 'X'
                       end
                       else begin
                         if (Mode='CW') or (Mode='CWQ') then
                         begin
                           if LoTW = 'L' then
                             BandMode[BandPos].CW := 'L'
                           else if (eQSL='E') then
                             BandMode[BandPos].CW := 'E'
                           else if BandMode[BandPos].CW = space then
                             BandMode[BandPos].CW := 'X'
                         end
                         else begin
                           if LoTW = 'L' then
                             BandMode[BandPos].DIGI := 'L'
                           else if (eQSL='E') then
                             BandMode[BandPos].DIGI := 'E'
                           else if BandMode[BandPos].DIGI = space then
                             BandMode[BandPos].DIGI := 'X'
                         end
                       end
                     end;
        steQSL     : begin
                       if (Mode = 'SSB') or (Mode='FM') or (Mode='AM') then
                       begin
                         if eQSL = 'E' then
                           BandMode[BandPos].SSB := 'E'
                         else if BandMode[BandPos].SSB = space then
                           BandMode[BandPos].SSB := 'X'
                       end
                       else begin
                         if (Mode='CW') or (Mode='CWQ') then
                         begin
                           if eQSL = 'E' then
                             BandMode[BandPos].CW := 'E'
                           else if BandMode[BandPos].CW = space then
                             BandMode[BandPos].CW := 'X'
                         end
                         else begin
                           if eQSL = 'E' then
                             BandMode[BandPos].DIGI := 'E'
                           else if BandMode[BandPos].DIGI = space then
                             BandMode[BandPos].DIGI := 'X'
                         end
                       end
                     end;
        stAll      : begin
                       if (Mode = 'SSB') or (Mode='FM') or (Mode='AM') then
                       begin
                         if QSLR = 'Q' then
                           BandMode[BandPos].SSB := 'Q'
                         else if (LoTW = 'L') then
                           BandMode[BandPos].SSB := 'L'
                         else if (eQSL = 'E') then
                           BandMode[BandPos].SSB := 'E'
                         else if (BandMode[BandPos].SSB = space) then
                           BandMode[BandPos].SSB := 'X'
                       end
                       else begin
                         if (Mode='CW') or (Mode='CWQ') then
                         begin
                           if QSLR = 'Q' then
                             BandMode[BandPos].CW := 'Q'
                           else if (LoTW='L') then
                             BandMode[BandPos].CW := 'L'
                           else if (eQSL='E') then
                             BandMode[BandPos].CW := 'E'
                           else if BandMode[BandPos].CW = space then
                             BandMode[BandPos].CW := 'X'
                         end
                         else begin
                           if QSLR = 'Q' then
                             BandMode[BandPos].DIGI := 'Q'
                           else if (LoTW='L') then
                             BandMode[BandPos].DIGI := 'L'
                           else if (eQSL='E') then
                             BandMode[BandPos].DIGI := 'E'
                           else if BandMode[BandPos].DIGI = space then
                             BandMode[BandPos].DIGI := 'X'
                         end
                       end
                     end;

      end; //case
      mDXCC.Next
    end;
    grdDXCCStat.RowCount := grdDXCCStat.RowCount -1
  finally
    mDXCC.Close;
    mDXCC.Free
  end;
  CreateModeStatistic;
  CreateTotalStatistic
end;

function TfrmDXCCStat.GetDXCCPhoneCount(deleted : Boolean) : Word;
var
  tmp : String = '';
begin
  Result := 0;
  dmData.Q.Close;
  tmp := '((mode='+QuotedStr('SSB')+') or (mode = '+QuotedStr('AM')+
         ') or (mode='+QuotedStr('FM')+'))';
  if not deleted then
    tmp := tmp + ' and (dxcc_id.dxcc_ref not like '+QuotedStr('%*')+')';
  dmData.Q.SQL.Text := 'select count(*) from (select distinct dxcc_id.dxcc_ref from dxcc_id left join cqrlog_main on '+
                       'dxcc_id.adif = cqrlog_main.adif WHERE cqrlog_main.adif <> 0 and '+tmp+') as foo';
  dmData.trQ.StartTransaction;
  dmData.Q.Open();
  Result := dmData.Q.Fields[0].AsInteger;
  dmData.Q.Close();
  dmData.trQ.Rollback
end;

function TfrmDXCCStat.GetStatTypeWhere(st : TStat) : String;
begin
  case st of
    stCfmOnly :  begin //only cfm
                   Result := 'qsl_r = '+QuotedStr('Q')
                 end;
    stCfmLoTW :  begin //cfm + LoTW
                   Result := '((qsl_r = '+QuotedStr('Q')+') or (lotw_qslr = '+QuotedStr('L')+'))'
                 end;
    stLoTWOnly : begin //LoTW only
                   Result := 'lotw_qslr = '+QuotedStr('L')
                 end;
    stCfmeQSL  : begin
                   Result := '((qsl_r = '+QuotedStr('Q')+') or (eqsl_qsl_rcvd = '+QuotedStr('E')+'))'
                 end;
    stLoTWeQSL : begin
                   Result := '((eqsl_qsl_rcvd = '+QuotedStr('E')+') or (lotw_qslr = '+QuotedStr('L')+'))'
                 end;
    steQSL     : begin
                   Result := '(eqsl_qsl_rcvd = '+QuotedStr('E')+')'
                 end;
    stAll      : begin
                   Result := '((eqsl_qsl_rcvd = '+QuotedStr('E')+') or (lotw_qslr = '+QuotedStr('L')+') or '+
                             '(qsl_r='+QuotedStr('Q')+'))'
                 end
    end; //case
end;

function TfrmDXCCStat.GetDXCCPhoneCfmCount(deleted : Boolean) : Word;
var
  tmp : String = '';
begin
  Result := 0;
  dmData.Q.Close;
  tmp := GetStatTypeWhere(StatType);
  if not deleted then
    tmp := tmp + ' and (dxcc_id.dxcc_ref not like '+QuotedStr('%*')+')';
  tmp := tmp + ' and ((mode='+QuotedStr('SSB')+') or (mode = '+QuotedStr('AM')+
         ') or (mode='+QuotedStr('FM')+'))';
  dmData.Q.SQL.Text := 'select count(*) from (select distinct dxcc_id.dxcc_ref from dxcc_id left join cqrlog_main on '+
                       'dxcc_id.adif = cqrlog_main.adif WHERE  cqrlog_main.adif <> 0 and '+tmp+') as foo';
  dmData.trQ.StartTransaction;
  dmData.Q.Open();
  Result := dmData.Q.Fields[0].AsInteger;
  dmData.Q.Close();
  dmData.trQ.Rollback
end;

function TfrmDXCCStat.GetDXCCCWCount(deleted : Boolean) : Word;
var
  tmp : String = '';
begin
  Result := 0;
  dmData.Q.Close;
  tmp := '((mode='+QuotedStr('CW')+') or (mode = '+QuotedStr('CWR')+'))';
  if not deleted then
    tmp := tmp + ' and (dxcc_id.dxcc_ref not like '+QuotedStr('%*')+')';
  dmData.Q.SQL.Text := 'select count(*) from (select distinct dxcc_id.dxcc_ref from dxcc_id left join cqrlog_main on '+
                       'dxcc_id.adif = cqrlog_main.adif WHERE cqrlog_main.adif <> 0 and  '+tmp+') as foo';
  dmData.trQ.StartTransaction;
  dmData.Q.Open();
  Result := dmData.Q.Fields[0].AsInteger;
  dmData.Q.Close();
  dmData.trQ.Rollback
end;

function TfrmDXCCStat.GetDXCCCWCfmCount(deleted : Boolean) : Word;
var
  tmp : String = '';
begin
  Result := 0;
  dmData.Q.Close;
  tmp := GetStatTypeWhere(StatType);
  if not deleted then
    tmp := tmp + ' and (dxcc_id.dxcc_ref not like '+QuotedStr('%*')+')';
  tmp := tmp + ' and ((mode='+QuotedStr('CW')+') or (mode = '+QuotedStr('CWR')+'))';
  dmData.Q.SQL.Text := 'select count(*) from (select distinct dxcc_id.dxcc_ref from dxcc_id left join cqrlog_main on '+
                       'dxcc_id.adif = cqrlog_main.adif WHERE cqrlog_main.adif <> 0 and  '+tmp+') as foo';
  dmData.trQ.StartTransaction;
  dmData.Q.Open();
  Result := dmData.Q.Fields[0].AsInteger;
  dmData.Q.Close();
  dmData.trQ.Rollback
end;

function TfrmDXCCStat.GetDXCCDigiCount(deleted : Boolean) : Word;
var
  tmp : String = '';
begin
  Result := 0;
  dmData.Q.Close;
  tmp := '(mode<>'+QuotedStr('CW')+') and (mode <> '+QuotedStr('CWR')+')'+
         'and (mode<>'+QuotedStr('SSB')+') and (mode<>'+QuotedStr('FM')+') '+
         'and (mode<>'+QuotedStr('AM')+')';
  if not deleted then
    tmp := tmp + ' and (dxcc_id.dxcc_ref not like '+QuotedStr('%*')+')';
  dmData.Q.SQL.Text := 'select count(*) from (select distinct dxcc_id.dxcc_ref from dxcc_id left join cqrlog_main on '+
                       'dxcc_id.adif = cqrlog_main.adif WHERE cqrlog_main.adif <> 0 and  '+tmp+') as foo';
  dmData.trQ.StartTransaction;
  dmData.Q.Open();
  Result := dmData.Q.Fields[0].AsInteger;
  dmData.Q.Close();
  dmData.trQ.Rollback
end;

function TfrmDXCCStat.GetDXCCDigiCfmCount(deleted : Boolean) : Word;
var
  tmp : String = '';
begin
  Result := 0;
  dmData.Q.Close;
  tmp := GetStatTypeWhere(StatType);
  tmp := tmp +' and (mode<>'+QuotedStr('CW')+') and (mode <> '+QuotedStr('CWR')+')'+
         'and (mode<>'+QuotedStr('SSB')+') and (mode<>'+QuotedStr('FM')+') '+
         'and (mode<>'+QuotedStr('AM')+')';
  if not deleted then
    tmp := tmp + ' and (dxcc_id.dxcc_ref not like '+QuotedStr('%*')+')';
  dmData.Q.SQL.Text := 'select count(*) from (select distinct dxcc_id.dxcc_ref from dxcc_id left join cqrlog_main on '+
                       'dxcc_id.adif = cqrlog_main.adif WHERE cqrlog_main.adif <> 0 and  '+tmp+') as foo';
  dmData.trQ.StartTransaction;
  dmData.Q.Open();
  Result := dmData.Q.Fields[0].AsInteger;
  dmData.Q.Close();
  dmData.trQ.Rollback
end;

function TfrmDXCCStat.GetMixCount(deleted : Boolean) : Word;
begin
  Result := dmDXCC.DXCCCount
end;

function TfrmDXCCStat.GetMixCfmCount(deleted : Boolean) : Word;
var
  tmp : String = '';
begin
  Result := 0;
  dmData.Q.Close;
  tmp := GetStatTypeWhere(StatType);
  if not deleted then
    tmp := tmp + ' and (dxcc_id.dxcc_ref not like '+QuotedStr('%*')+')';
  dmData.Q.SQL.Text := 'select count(*) from (select distinct dxcc_id.dxcc_ref from dxcc_id left join cqrlog_main on '+
                       'dxcc_id.adif = cqrlog_main.adif WHERE cqrlog_main.adif <> 0 and  '+tmp+') as foo';
  dmData.trQ.StartTransaction;
  dmData.Q.Open();
  Result := dmData.Q.Fields[0].AsInteger;
  dmData.Q.Close();
  dmData.trQ.Rollback
end;

procedure TfrmDXCCStat.CreateTotalStatistic;
var
  i   : Integer;
  y   : Integer;
  sum : Word;
begin
  grdStat.ColCount := grdStat.ColCount+1;
  grdStat.Cells[grdStat.ColCount-1,0] := 'Total';

  for y:=1 to grdStat.RowCount-1 do
  begin
    if grdStat.Cells[0,y] = '' then
      Continue;
    sum := 0;
    for i:=1 to grdStat.ColCount -1 do
    begin
      if grdStat.Cells[i,y] <> '' then
        sum := sum + StrToInt(grdStat.Cells[i,y])
      else
        grdStat.Cells[i,y] := '0'
    end;
    grdStat.Cells[grdStat.ColCount-1,y] := IntToStr(sum)
  end
end;

end.

