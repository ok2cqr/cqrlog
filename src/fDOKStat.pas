(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fDOKStat;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, inifiles,
  ExtCtrls, Grids, Buttons, StdCtrls, FileUtil, LazFileUtils;

type
  TStatType = (tsDOK);
  TCfmType  = (tcQSL,tcQSLLoTW,tcLoTW);

type
  TStat = (
    stCfmOnly, //paper only
    stCfmLoTW, //paper + LoTW
    stLoTWOnly,//LoTW only
    stCfmeQSL, //paper + eQSL
    stLoTWeQSL, //LoTW + eQSL
    steQSLOnly,     //eQSL only
    stAll       //paper + LoTW + eQSL
    );

type
  TDok = record
    DokType : String[4];   // can be DOK or SDOK
    Dok     : String[12];  // H16
    Longname : String[50]; // Ortsverband Holzminden
    District : String[50]; // Niedersachsen
  end;

type

  { TfrmDOKStat }

  TfrmDOKStat = class(TForm)
    btnClose: TButton;
    btnHTMLExport: TButton;
    btnRefresh : TButton;
    btnSelectProfile : TButton;
    btnShowStationList: TButton;
    cbHideEmpty: TCheckBox;
    cmbCfmType : TComboBox;
    cmbMode : TComboBox;
    cbChoosingDokType: TComboBox;
    dlgSave: TSaveDialog;
    edtProfiles : TEdit;
    grdStat: TStringGrid;
    grdSumStat: TStringGrid;
    Label1 : TLabel;
    Label2 : TLabel;
    Label3 : TLabel;
    Panel1: TPanel;
    Panel2 : TPanel;
    procedure btnSelectProfileClick(Sender: TObject);
    procedure cbChoosingDokTypeChange(Sender: TObject);
    procedure cbHideEmptyChange(Sender: TObject);
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnHTMLExportClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnShowStationListClick(Sender: TObject);
  private
    gmode : String;
    DOKsArray : Array of TDok;

    procedure CreateDOKStat;
    procedure LoadBandsSettings;
    procedure CreateSummary;
    procedure ShowCharInGrid(QSL_R,LoTW,eQSL : String;BandPos,y : Integer);

    function  GetStatTypeWhere(st : TStat) : String;
    function LoadDOKs : Boolean;
  public
    StatType : TStatType;
    CfmType  : TStat;
    procedure ExportToHTML(htmlfile : String);
  end; 

var
  frmDOKStat: TfrmDOKStat;

implementation
{$R *.lfm}

{ TfrmDOKStat }
uses dUtils, dData, fQTHProfiles, fShowStations, uMyIni;

procedure TfrmDOKStat.ShowCharInGrid(QSL_R,LoTW,eQSL : String;BandPos,y : Integer);
begin
  if y<1 then exit; //wrong state name

  case CfmType of
    stCfmOnly : begin
                  if QSL_R = 'Q'then
                    grdStat.Cells[BandPos,y] := 'Q'
                  else begin
                    if grdStat.Cells[BandPos,y] = '' then
                      grdStat.Cells[BandPos,y] := 'X'
                  end
                end;
    stCfmLoTW : begin
                  if QSL_R = 'Q' then
                    grdStat.Cells[BandPos,y] := 'Q'
                  else if (LoTW='L') then
                    grdStat.Cells[BandPos,y] := 'L'
                  else if grdStat.Cells[BandPos,y] = '' then
                    grdStat.Cells[BandPos,y] := 'X'
                 end;
    stLoTWOnly : begin
                   if LoTW = 'L'then
                     grdStat.Cells[BandPos,y] := 'L'
                   else begin
                     if grdStat.Cells[BandPos,y] = '' then
                       grdStat.Cells[BandPos,y] := 'X'
                   end
                 end;
    stCfmeQSL  : begin
                  if QSL_R = 'Q' then
                    grdStat.Cells[BandPos,y] := 'Q'
                  else if (eQSL='E') then
                    grdStat.Cells[BandPos,y] := 'E'
                  else if grdStat.Cells[BandPos,y] = '' then
                    grdStat.Cells[BandPos,y] := 'X'
                 end;
    stLoTWeQSL : begin
                   if LoTW = 'L' then
                     grdStat.Cells[BandPos,y] := 'L'
                   else if (eQSL='E') then
                     grdStat.Cells[BandPos,y] := 'E'
                   else if grdStat.Cells[BandPos,y] = '' then
                     grdStat.Cells[BandPos,y] := 'X'
                  end;
    steQSLOnly : begin
                   if eQSL = 'E'then
                     grdStat.Cells[BandPos,y] := 'E'
                   else begin
                     if grdStat.Cells[BandPos,y] = '' then
                       grdStat.Cells[BandPos,y] := 'X'
                   end
                 end;
    stAll      : begin
                   if QSL_R = 'Q' then
                      grdStat.Cells[BandPos,y] := 'Q'
                   else if (LoTW = 'L') then
                     grdStat.Cells[BandPos,y] := 'L'
                   else if (eQSL = 'E') then
                     grdStat.Cells[BandPos,y] := 'E'
                   else if (grdStat.Cells[BandPos,y] = '') then
                     grdStat.Cells[BandPos,y] := 'X'
                 end
  end //case
end;

procedure TfrmDOKStat.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  dmUtils.SaveForm(self);
  cqrini.WriteBool('DOKStat','hideEmpty',cbHideEmpty.Checked);
  cqrini.WriteInteger('DOKStat','whichDOKs',cbChoosingDokType.ItemIndex);
  cqrini.WriteString('DOKStat','profiles'+IntToStr(ord(StatType)),edtProfiles.Text);
  cqrini.WriteInteger('DOKStat','mode'+IntToStr(ord(StatType)),cmbMode.ItemIndex);
  cqrini.WriteInteger('DOKStat','width'+IntToStr(ord(StatType)),grdStat.ColWidths[0])
end;

procedure TfrmDOKStat.btnSelectProfileClick(Sender: TObject);
begin
  with TfrmQTHProfiles.Create(self) do
  try
    SelectingProfiles;
    ShowModal;
    if ModalResult = mrOK then
    begin
      if edtProfiles.Text = '' then
        edtProfiles.Text := dmData.qProfiles.Fields[1].AsString
      else begin
        if edtProfiles.Text[Length(edtProfiles.Text)] <> ';' then
          edtProfiles.Text := edtProfiles.Text + ';'+dmData.qProfiles.Fields[1].AsString
        else
          edtProfiles.Text := edtProfiles.Text + dmData.qProfiles.Fields[1].AsString
      end
    end
  finally
    Free
  end
end;

procedure TfrmDOKStat.cbChoosingDokTypeChange(Sender: TObject);
begin
  btnRefresh.Click
end;

procedure TfrmDOKStat.cbHideEmptyChange(Sender: TObject);
begin
  btnRefresh.Click
end;

procedure TfrmDOKStat.FormClose(Sender : TObject;
  var CloseAction : TCloseAction);
begin
  dmUtils.SaveWindowPos(self)
end;

procedure TfrmDOKStat.FormCreate(Sender: TObject);
begin
  dmUtils.LoadWindowPos(self);
  dmUtils.LoadFontSettings(self)
end;

procedure TfrmDOKStat.FormShow(Sender: TObject);
var
  w : Integer = 0;
begin
  dmUtils.LoadWindowPos(self);
  gmode := '';
  dmUtils.InsertModes(cmbMode);
  cmbMode.Items.Insert(0,'ALL');
  cmbMode.Items.Insert(1,'SSB+CW');
  cbChoosingDokType.ItemIndex := cqrini.ReadInteger('DOKStat','whichDOKs',0);
  cbHideEmpty.Checked := cqrini.ReadBool('DOKStat','hideEmpty',false);
  edtProfiles.Text  := cqrini.ReadString('DOKStat','profiles'+IntToStr(ord(StatType)),'');
  cmbMode.ItemIndex := cqrini.ReadInteger('DOKStat','mode'+IntToStr(ord(StatType)),0);
  w                 := cqrini.ReadInteger('DOKStat','width'+IntToStr(ord(StatType)),0);
  cmbCfmType.ItemIndex := cqrini.ReadInteger('DOKStat','LastStat',6);
  grdStat.ColWidths[0] := 110;
  grdStat.ColWidths[1] := 200;

  // Another grid style tom@dl7bj.de, 2014-06-20
  if cqrini.ReadBool('Fonts','GridGreenBar',False) = True then
  begin
    grdSumStat.AlternateColor:=$00E7FFEB;
    grdStat.AlternateColor:=$00E7FFEB;
    grdSumStat.Options:=[goRowSelect,goRangeSelect,goSmoothScroll,goVertLine,goFixedVertLine];
    grdStat.Options:=[goRowSelect,goRangeSelect,goSmoothScroll,goVertLine,goFixedVertLine];
  end else begin
    grdSumStat.AlternateColor:=clWindow;
    grdStat.AlternateColor:=clWindow;
    grdSumStat.Options:=[goRangeSelect,goSmoothScroll,goVertLine,goFixedVertLine,goFixedHorzLine,goHorzline];
    grdStat.Options:=[goRangeSelect,goSmoothScroll,goVertLine,goFixedVertLine,goFixedHorzLine,goHorzline];
  end;
  if cqrini.ReadBool('Fonts','GridSmallRows',false) = True then
  begin
    grdSumStat.DefaultRowHeight:=grdSumStat.Canvas.Font.Size+8;
    grdStat.DefaultRowHeight:=grdStat.Canvas.Font.Size+8;
  end else begin
    grdSumStat.DefaultRowHeight:=25;
    grdStat.DefaultRowHeight:=25;
  end;
  if cqrini.ReadBool('Fonts','GridBoldTitle',false) = True then
  begin
    grdSumStat.TitleFont.Style:=[fsBold];
    grdStat.TitleFont.Style:=[fsBold];
  end else begin
    grdSumStat.TitleFont.Style:=[];
    grdStat.TitleFont.Style:=[];
  end;
  If not LoadDOKs then
  begin
    Application.MessageBox('DOK table is empty. Please make sure that the content of dok.csv and sdok.csv is valid.','Problem');
    exit
  end;
  btnRefresh.Click
end;

procedure TfrmDOKStat.btnHTMLExportClick(Sender: TObject);
begin
  dlgSave.DefaultExt := '.html';
  dlgSave.Filter := 'html|*.html;*.HTML';
  if dlgSave.Execute then
  begin
    ExportToHTML(dlgSave.FileName)
  end
end;

procedure TfrmDOKStat.btnRefreshClick(Sender: TObject);
var
  tmp : String = '';
  a   : TExplodeArray;
  i   : Integer = 0;
begin
  CfmType := TStat(cmbCfmType.ItemIndex);
  case cmbMode.ItemIndex of
    0 : gmode := '';
    1 : gmode := ' ((mode = '+QuotedStr('CW')+') or (mode = '+QuotedStr('SSB')+')) '
   else
     gmode := ' (mode = '+QuotedStr(cmbMode.Text)+') '
  end;
  if edtProfiles.Text <> '' then
  begin
    tmp := '';
    SetLength(a,0);
    if Pos(';',edtProfiles.Text) > 0 then
    begin
      a := dmUtils.Explode(';',edtProfiles.Text);
      for i:=0 to Length(a)-1 do
        tmp := tmp + ' (profile = '+a[i]+') OR';
      tmp := '('+copy(tmp,1,Length(tmp)-2)+')'
    end
    else
      tmp := ' (profile = '+edtProfiles.Text+') ';
    if gmode = '' then
      gmode := tmp
    else
      gmode := gmode + ' AND ' + tmp
  end;
  cqrini.WriteInteger('DOKStat','LastStat',cmbCfmType.ItemIndex);
  cqrini.WriteInteger('DOKStat','whichDOKs',cbChoosingDokType.ItemIndex);
  CfmType := TStat(cmbCfmType.ItemIndex);
  case StatType of
    tsDOK   : CreateDOKStat
  end
end;

procedure TfrmDOKStat.btnShowStationListClick(Sender: TObject);
var
  sql : String;
  l   : TStringList;
  b   : String = '';
  oldb : String = '';
  tmp  : String;
  qslr : String = '';
begin
  l := TStringList.Create;
  try
    qslr := GetStatTypeWhere(CfmType);
    case StatType of
      tsDOK   : begin
              if gmode = '' then
                sql := 'select callsign,freq,mode,dok from cqrlog_main '+
                        ' where (dok <> '+QuotedStr('')+') and (adif=230) and '+ qslr +' order by convert(freq,signed),dok'
              else
                sql := 'select callsign,freq,mode,dok from cqrlog_main'+
                        ' where (dok <> '+QuotedStr('')+') and (adif=230) and '+ qslr +' AND '+gmode+
                        'order by convert(freq,signed),dok';
            end
    end;
    dmData.trQ.StartTransaction;
    dmData.Q.SQL.Text := sql;
    if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
    dmData.Q.Open();
    dmData.Q.First;

    while not dmData.Q.Eof do
    begin
      b := dmUtils.GetBandFromFreq(dmData.Q.Fields[1].AsString);
      if (oldb <> b) then
      begin
        l.Add('');
        oldb := dmUtils.GetBandFromFreq(dmData.Q.Fields[1].AsString)
      end;


      tmp  := dmUtils.SetSize(dmData.Q.Fields[0].AsString,20) +
              dmUtils.SetSize(dmUtils.GetLabelBand(dmData.Q.Fields[1].AsString),8)+
              dmUtils.SetSize(dmData.Q.Fields[2].AsString,7)+
              dmUtils.SetSize(dmData.Q.Fields[3].AsString,12);
      l.Add(tmp);
      dmData.Q.Next
    end;
    with TfrmShowStations.Create(self) do
    try
      m.Lines.Text:= l.Text;
      ShowModal
    finally
      Free
    end
  finally
    dmData.Q.Close;
    dmData.trQ.Rollback;
    l.Free
  end
end;

procedure TfrmDOKStat.ExportToHTML(htmlfile : String);
var
  f      : TextFile;
  MyCall : String ='';
  i      : Integer = 0;
  y      : integer = 0;
  tmp    : String = '';
begin
  MyCall := cqrini.ReadString('Station','Call','');

  AssignFile(f,htmlfile);
  Rewrite(f);
  Writeln(f,'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">');
  WriteLn(f,'<HTML>');
  Writeln(f,'<HEAD>');
  Writeln(f,'<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=utf8">');
  Writeln(f,'<TITLE> '+ Caption +' of '+MyCall+' </TITLE>');
  Writeln(f,'<META NAME="GENERATOR" CONTENT="CQRLOG ver. '+ dmData.VersionString +'">');
  Writeln(f,'<style type="text/css">');
  Writeln(f,'<!--');
  Writeln(f,'.popis {color: #FFFFFF}');
  Writeln(f,'.hlava {');
  Writeln(f,'	color: #333366;');
  Writeln(f,'	font-family: Verdana, Arial, Helvetica, sans-serif;');
  Writeln(f,'	font-size: 12px;');
  Writeln(f,'	font-weight: bold;');
  Writeln(f,'}');
  Writeln(f,'-->');
  Writeln(f,'</style>');
  Writeln(f,'</HEAD>');
  Writeln(f,'<BODY>');
  Writeln(f,'<BR>');
  Writeln(f,'<H1 ALIGN=CENTER> '+Caption+' of '+ MyCall + '</H1>');
  Writeln(f,'<BR>');
  Writeln(f,'<CENTER>');
  Writeln(f,'');

  Writeln(f,'<TABLE WIDTH="'+ IntToStr(30 + 50*(grdStat.ColCount -1)) + '" BORDER=1 CELLPADDING=2 CELLSPACING=0>');
  Writeln(f,'<COL WIDTH=30>');

  Writeln(f,'<TR VALIGN=TOP>');

  Writeln(f,'<TD WIDTH=20  bgcolor="#333366" class="hlava">');
  case StatType of
    tsDOK   : Writeln(f,'<P><div align="center" class="popis">DOK</div></P>')
  end;
  Writeln(f,'</P>');
  Writeln(f,'</TD>');

  for i:=1 to grdStat.ColCount-1  do
  begin
    Writeln(f,'<TD WIDTH=20  bgcolor="#333366" class="hlava">');
    tmp := grdStat.Cells[i,0];
    Writeln(f,'<P><div align="center" class="popis">' + tmp +  '</div></P>');
    Writeln(f,'</TD>');
  end;  //^^ table header
  Writeln(f,'</TR>');


  for y := 1 to grdStat.RowCount-1 do
  begin
    Writeln(f,'<TR VALIGN=TOP>');
    Writeln(f,'<TD WIDTH=50  bgcolor="#333366" class="hlava">');
    Writeln(f,'<P><div align="center" class="popis">'+grdStat.Cells[0,y]);
    Writeln(f,'</div></P>');
    Writeln(f,'</TD>');
    for i := 1 to grdStat.ColCount-1 do
    begin
      Writeln(f,'<TD WIDTH=20>');
      if grdStat.Cells[i,y] = '' then
        tmp := '&nbsp;'
      else
        tmp := grdStat.Cells[i,y];
      Writeln(f,'<P ALIGN="CENTER">');
      Writeln(f,tmp);
      Writeln(f,'</P>');
      Writeln(f,'</TD>');
    end;
  end;

  Writeln(f,'</TR>');
  Writeln(f,'</TABLE>');
  Writeln(f,'</CENTER>');
  Writeln(f,'<BR>');
  Writeln(f,'<BR>');

  Writeln(f,'<!-- Hmm ... -->');

  Writeln(f,'<CENTER>');
  Writeln(f,'<TABLE WIDTH="'+ IntToStr(20 + 50*(grdSumStat.ColCount -1)) + '" BORDER=1 CELLPADDING=2 CELLSPACING=0>');
  Writeln(f,'<COL WIDTH=20>');

  Writeln(f,'<TR>');
  for i:=0 to grdSumStat.ColCount -1 do
  begin
    Writeln(f,'<TD WIDTH=20 bgcolor="#333366" class="hlava">');
    tmp := grdSumStat.Cells[i,0];
    if tmp = '' then
      tmp := '&nbsp;';
    Writeln(f,'<P><div align="center" class="popis">' + tmp +  '</div></P>');
    Writeln(f,'</TD>');
  end;  //^^ table header
  Writeln(f,'</TR>');

  Writeln(f,'<TR>');
  Writeln(f,'<TD WIDTH=20 bgcolor="#333366" class="hlava">');
  Writeln(f,'<P><div align="center" class="popis">WKD</div></P>');
  Writeln(f,'</TD>');
  for i:=1 to grdSumStat.ColCount -1 do
  begin
    Writeln(f,'<TD WIDTH=60>');
    tmp := grdSumStat.Cells[i,1];
    Writeln(f,'<P ALIGN=CENTER><FONT SIZE=2>' + tmp +  '</FONT></P>');
    Writeln(f,'</TD>');
  end;
  Writeln(f,'</TR>');

  Writeln(f,'<TR>');
  Writeln(f,'<TD WIDTH=20 bgcolor="#333366" class="hlava">');
  Writeln(f,'<P><div align="center" class="popis">CFM</div></P>');
  Writeln(f,'</TD>');
  for i:=1 to grdSumStat.ColCount -1 do
  begin
    Writeln(f,'<TD WIDTH=60>');
    tmp := grdSumStat.Cells[i,2];
    Writeln(f,'<P ALIGN=CENTER><FONT SIZE=2>' + tmp +  '</FONT></P>');
    Writeln(f,'</TD>');
  end;
  Writeln(f,'</TR>');

  Writeln(f,'</TABLE>');
  Writeln(f,'</CENTER>');
  Writeln(f,'<BR> <BR>');
  Writeln(f,'<H5 ALIGN=CENTER> <A HREF="http://www.cqrlog.com">CQRLOG ver. ' + dmData.VersionString  + ' </A></H5>');
  Writeln(f,'</BODY>');
  Writeln(f,'</HTML>');
  CloseFile(f);
end;

procedure TfrmDOKStat.LoadBandsSettings;
var
  i : Integer = 0;
begin
  grdStat.ColCount  := cMaxBandsCount;
  for i:=0 to cMaxBandsCount-1 do
  begin
    if dmUtils.MyBands[i][0]='' then
    begin
      grdStat.ColCount    := i+2;
      grdSumStat.ColCount := i+1;
      break
    end;
    grdStat.Cells[i+2,0] := dmUtils.MyBands[i][1];
    grdSumStat.Cells[i+1,0] := dmUtils.MyBands[i][1];
  end;
  grdStat.ColWidths[grdStat.ColCount-1] := 50;
  grdSumStat.ColWidths[grdSumStat.ColCount-1] := 50
end;

procedure TfrmDOKStat.CreateSummary;
var
  wkd : Word = 0;
  cfm : Word = 0;
  i,y : Integer;
begin
  grdSumStat.Cells[0,1] := 'WKD';
  grdSumStat.Cells[0,2] := 'CFM';

  for y := 2 to grdStat.ColCount-1 do
  begin
    wkd := 0;
    cfm := 0;
    for i := 1 to grdStat.RowCount-1 do
    begin
      if grdStat.Cells[y,i] <> '' then
        inc(wkd);
      if (grdStat.Cells[y,i]='Q') or (grdStat.Cells[y,i]='L') or (grdStat.Cells[y,i]='E') then
        inc(cfm);
    end;
    grdSumStat.Cells[y-1,1] := IntToStr(wkd);
    grdSumStat.Cells[y-1,2] := IntToStr(cfm);
  end;
  grdStat.ColCount := grdStat.ColCount+1;
  grdStat.ColWidths[grdStat.ColCount-1]:= 100;
  grdStat.Cells[grdStat.ColCount-1,0]:= 'TOTAL';
  wkd := 0;
  cfm := 0;
  for y:=1 to grdStat.RowCount-1 do  //lines
  begin
    for i:=2 to grdStat.ColCount-1 do
    begin
      if (grdStat.Cells[i,y] = 'Q') or (grdStat.Cells[i,y] = 'L') or (grdStat.Cells[i,y] = 'E')  then
        grdStat.Cells[grdStat.ColCount-1,y] := 'Q'
      else begin
        if (grdStat.Cells[grdStat.ColCount-1,y] <> 'Q') and (grdStat.Cells[i,y] = 'X') then
          grdStat.Cells[grdStat.ColCount-1,y] := 'X'
      end
    end;
    if grdStat.Cells[grdStat.ColCount-1,y] = 'Q' then
    begin
      inc(cfm);
      inc(wkd)
    end
    else begin
      if grdStat.Cells[grdStat.ColCount-1,y] = 'X' then
        inc(wkd)
    end
  end;
end;

function TfrmDOKStat.LoadDOKs : Boolean;
var
  f : TextFile;
  a : TExplodeArray;
  i : Integer = 0;
  r : String;
  last : String;
begin
  last := '';
  if FileExistsUTF8(dmData.HomeDir+'dok_data'+PathDelim+'dok.csv') then
  begin
    try
      AssignFile(f,dmData.HomeDir+'dok_data'+PathDelim+'dok.csv');
      Reset(f);
      while not eof(f) do
      begin
        readln(f);
        inc(i);
      end;
      SetLength(DOKsArray, (i+1));
      Reset(f);
      i := 1;
      while not Eof(f) do
      begin
        Readln(f,r);
        a := dmUtils.Explode(';',r);
        if dmData.DebugLevel>=1 then Writeln(Format('%04d: %s -> %s', [i, a[0], a[2]]));

        DOKsArray[i].DokType := 'DOK'; // Type (DOK, SDOK)
        DOKsArray[i].Dok := a[0];  // DOK
        DOKsArray[i].Longname := a[2];  // Name
        DOKsArray[i].District := a[1];  // District

        inc(i)
      end
    finally
      CloseFile(f);
      if dmData.DebugLevel>=1 then Writeln(i-1,' German DOKs loaded')
    end
  end;

  if FileExistsUTF8(dmData.HomeDir+'dok_data'+PathDelim+'sdok.csv') then
  begin
    try
      AssignFile(f,dmData.HomeDir+'dok_data'+PathDelim+'sdok.csv');
      Reset(f);

      while not Eof(f) do
      begin
        Readln(f,r);
        a := dmUtils.Explode(';',r);
        if (a[0] = last) then Continue
        else
          begin
            if dmData.DebugLevel>=1 then Writeln(Format('%04d: %s -> %s', [i, a[0], a[1]]));
            SetLength(DOKsArray, (Length(DOKsArray)+1));
            DOKsArray[i].DokType := 'SDOK'; // Type (DOK, SDOK)
            DOKsArray[i].Dok := a[0];       // SDOK
            DOKsArray[i].Longname := a[1];
            DOKsArray[i].District := '';
            last := a[0];
          end;
       inc(i)
       end
    finally
      CloseFile(f);
      if dmData.DebugLevel>=1 then Writeln(i-1,' German SDOKs loaded')
    end
  end;
  if (length(DOKsArray) = 0) then Result:= False
  else Result:= True
end;

procedure TfrmDOKStat.CreateDOKStat;

  function DOKPos(dok : String) : Integer;
  var
    i : Integer;
  begin
    Result := -1;
    for i:=0 to grdStat.RowCount-1 do
      if (grdStat.Cells[0,i] = dok) then
      begin
        Result := i;
        if dmData.DebugLevel>=1 then Writeln(dok,' pos: ',i);
        break;
       end;
  end;

  function FindDOKName(dok: String) : String;
  var
    i : Integer;
  begin
    Result := '';
    for i:=1 to length(DOKsArray)-1 do
      if DOKsArray[i].Dok = dok then
      begin
        Result := DOKsArray[i].Longname;
        break
      end;
  end;

  function FindDOKType(dok: String) : String;
  var
    i : Integer;
  begin
    Result := '';
    for i:=1 to length(DOKsArray)-1 do
      if DOKsArray[i].Dok = dok then
      begin
        Result := DOKsArray[i].DokType;
        break
      end;  ;
  end;

var
  i, y : Integer;
  row : Integer;
  BandPos : Integer;
  QSL_R   : String;
  LoTW    : String;
  eQSL    : String;
  where   : String;
  sql     : String;
begin

  // initialize grid and writing header
  for i:=0 to grdStat.RowCount-1 do
    for y:=0 to grdStat.ColCount-1 do
      grdStat.Cells[y,i] := '';
  grdStat.Cells[0,0]  := 'DOK';
  grdStat.Cells[1,0]  := 'Name';
  Caption := 'DOK Statistic';

  // filling column DOK and Name
  if (not cbHideEmpty.Checked) then
  begin
    row := 0;
    for i:=1 to length(DOKsArray)-1 do
    begin
      if (cbChoosingDokType.ItemIndex = 1) and (DOKsArray[i].DokType <> 'DOK') then
        continue;
      if (cbChoosingDokType.ItemIndex = 2) and (DOKsArray[i].DokType <> 'SDOK') then
        continue;

      inc(row);
      grdStat.RowCount := row + 1;
      grdStat.Cells[0,row] := DOKsArray[i].Dok;
      grdStat.Cells[1,row] := DOKsArray[i].Longname;
    end;
  end
  else begin
      grdStat.RowCount := 1;
      dmData.Q.Close;
      dmData.Q.SQL.Text := 'select distinct dok from cqrlog_main '+
                           'where (adif=230) '+
                           'having (dok <> '''') '+
                           'order by dok';
      if dmData.trQ.Active then dmData.trQ.Rollback;
      dmData.trQ.StartTransaction;
      dmData.Q.Open();
      dmData.Q.First;
      row := 0;
      while not dmData.Q.Eof do
      begin
        if (cbChoosingDokType.ItemIndex = 1) and (FindDOKType(dmData.Q.Fields[0].AsString) <> 'DOK') then
        begin
          dmData.Q.Next;
          continue;
        end;
        if (cbChoosingDokType.ItemIndex = 2) and (FindDOKType(dmData.Q.Fields[0].AsString) <> 'SDOK') then
        begin
          dmData.Q.Next;
          continue;
        end;

        inc(row);
        grdStat.RowCount := row + 1;
        grdStat.Cells[0,row] := dmData.Q.Fields[0].AsString;
        grdStat.Cells[1,row] := FindDOKName(dmData.Q.Fields[0].AsString);
        dmData.Q.Next;
      end;
  end;

  LoadBandsSettings;

  // now filling with the data
  sql := 'select dok,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main '+
         '%s '+
         'group by dok,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd '+
         'having (dok <> '''') '+
         'order by dok';
  where := '(adif=230)';
  if gmode <> '' then
    where := where + ' and '+ gmode;

  dmData.Q.Close;
  dmData.Q.SQL.Text := Format(sql,['where '+where]);

  if dmData.trQ.Active then dmData.trQ.Rollback;
  dmData.trQ.StartTransaction;
  dmData.Q.Open();
  dmData.Q.First;

  while not dmData.Q.Eof do
  begin
    BandPos := dmUtils.GetBandPos(dmData.Q.Fields[1].AsString);
    if BandPos = -1 then
    begin
      dmData.Q.Next;
      Continue
    end;
    BandPos := BandPos+2;
    QSL_R   := dmData.Q.Fields[2].AsString;
    LoTW    := dmData.Q.Fields[3].AsString;
    eQSL    := dmData.Q.Fields[4].AsString;

    ShowCharInGrid(QSL_R,LoTW,eQSL,BandPos,DOKPos(dmData.Q.Fields[0].AsString));
    dmData.Q.Next
  end;
  dmData.Q.Close;
  dmData.trQ.Rollback;

  CreateSummary;
end;

function TfrmDOKStat.GetStatTypeWhere(st : TStat) : String;
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
    steQSLOnly : begin
                   Result := '(eqsl_qsl_rcvd = '+QuotedStr('E')+')'
                 end;
    stAll      : begin
                   Result := '((eqsl_qsl_rcvd = '+QuotedStr('E')+') or (lotw_qslr = '+QuotedStr('L')+') or '+
                             '(qsl_r='+QuotedStr('Q')+'))'
                 end
    end; //case
end;

end.

