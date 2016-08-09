(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fWAZITUStat;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, inifiles,
  ExtCtrls, Grids, Buttons, StdCtrls;

type
  TStatType = (tsWAZ,tsITU,tsWAC,tsWAS);
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

  { TfrmWAZITUStat }

  TfrmWAZITUStat = class(TForm)
    btnClose: TButton;
    btnHTMLExport: TButton;
    btnRefresh : TButton;
    btnSelectProfile : TButton;
    btnShowSationList: TButton;
    cmbCfmType : TComboBox;
    cmbMode : TComboBox;
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
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnHTMLExportClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnShowSationListClick(Sender: TObject);
  private
    gmode : String;
    aStates : Array [1..50] of String;
    procedure CreateWAZStat;
    procedure CreateITUStat;
    procedure CreateWACStat;
    procedure CreateWASStat;
    procedure LoadBandsSettings;
    procedure CreateSummary;
    procedure ShowBandChar(band : String;y : Integer;bchar : Char);
    procedure ShowCharInGrid(QSL_R,LoTW,eQSL : String;BandPos,y : Integer);

    function  GetStatTypeWhere(st : TStat) : String;
  public
    StatType : TStatType;
    CfmType  : TStat;
    procedure ExportToHTML(htmlfile : String);
  end; 

var
  frmWAZITUStat: TfrmWAZITUStat;

implementation
{$R *.lfm}

{ TfrmWAZITUStat }
uses dUtils,dData, fQTHProfiles, fShowStations, uMyIni;

procedure TfrmWAZITUStat.ShowBandChar(band : String;y : Integer;bchar : Char);
var
  p : Integer;
begin
  if (y > grdStat.RowCount) or (y < 1) then
  begin
    Writeln('bChar: ',bchar);
    Writeln('band:  ',band);
    Writeln('y:     ',y);
    exit;
  end;
  p := dmUtils.GetBandPos(band);
  if p > -1 then
    grdStat.Cells[p+1,y] := bchar
end;

procedure TfrmWAZITUStat.ShowCharInGrid(QSL_R,LoTW,eQSL : String;BandPos,y : Integer);
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

procedure TfrmWAZITUStat.CreateWAZStat;
const
  C_SEL = 'select waz,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main '+
          '%s '+
          'group by waz,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd '+
          'having (waz > 0) and (waz < 41) '+
          'order by waz';
var
  zone     : Integer;
  i        : Integer = 1;
  y        : Integer;
  BandPos  : Integer;
  QSL_R    : String;
  LoTW     : String;
  eQSL     : String;
begin
  for i:=0 to grdStat.RowCount-1 do
    for y:=0 to grdStat.ColCount-1 do
      grdStat.Cells[y,i] := '';

  LoadBandsSettings;
  Caption := 'WAZ statistic';
  grdStat.Cells[0,0] := 'WAZ';
  grdStat.RowCount := 41;
  for i:=1 to 40 do
  grdStat.Cells[0,i] := IntToStr(i);

  dmData.Q.Close;
  if gmode <> '' then
    dmData.Q.SQL.Text := Format(C_SEL,['where '+gmode])
  else
    dmData.Q.SQL.Text := Format(C_SEL,['']);
  if dmData.trQ.Active then dmData.trQ.Rollback;
  dmData.trQ.StartTransaction;
  dmData.Q.Open();
  dmData.Q.First;
  while not dmData.Q.Eof do
  begin
    zone := dmData.Q.Fields[0].AsInteger;
    BandPos := dmUtils.GetBandPos(dmData.Q.Fields[1].AsString);
    if BandPos = -1 then
    begin
      dmData.Q.Next;
      Continue
    end;
    BandPos := BandPos+1;
    QSL_R   := dmData.Q.Fields[2].AsString;
    LoTW    := dmData.Q.Fields[3].AsString;
    eQSL    := dmData.Q.Fields[4].AsString;

    ShowCharInGrid(QSL_R,LoTW,eQSL,BandPos,zone);

    dmData.Q.Next
  end;
  dmData.Q.Close;
  dmData.trQ.Rollback;
  CreateSummary
end;

procedure TfrmWAZITUStat.CreateITUStat;
const
  C_SEL = 'select itu,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main '+
          '%s '+
          'group by itu,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd '+
          'having (itu > 0) and (itu < 91) '+
          'order by itu';
var
  zone     : Integer;
  i        : Integer = 1;
  y        : Integer;
  BandPos  : Integer;
  QSL_R    : String;
  LoTW     : String;
  eQSL     : String;
begin
  for i:=0 to grdStat.RowCount-1 do
    for y:=0 to grdStat.ColCount-1 do
      grdStat.Cells[y,i] := '';

  LoadBandsSettings;
  Caption := 'ITU statistic';
  grdStat.Cells[0,0] := 'ITU';
  grdStat.RowCount := 78;
  for i:=1 to 75 do
    grdStat.Cells[0,i] := IntToStr(i);
  grdStat.Cells[0,76] := '78';
  grdStat.Cells[0,77] := '90';

  dmData.Q.Close;
  if gmode <> '' then
    dmData.Q.SQL.Text := Format(C_SEL,['where '+gmode])
  else
    dmData.Q.SQL.Text := Format(C_SEL,['']);
  if dmData.trQ.Active then dmData.trQ.Rollback;
  dmData.trQ.StartTransaction;
  dmData.Q.Open();
  dmData.Q.First;
  while not dmData.Q.Eof do
  begin
    zone := dmData.Q.Fields[0].AsInteger;
    BandPos := dmUtils.GetBandPos(dmData.Q.Fields[1].AsString);
    if BandPos = -1 then
    begin
      dmData.Q.Next;
      Continue
    end;
    BandPos := BandPos+1;
    QSL_R   := dmData.Q.Fields[2].AsString;
    LoTW    := dmData.Q.Fields[3].AsString;
    eQSL    := dmData.Q.Fields[4].AsString;

    if (zone=78) then zone:=76; //line 76 in the gird
    if (zone=90) then zone:=77;

    ShowCharInGrid(QSL_R,LoTW,eQSL,BandPos,zone);
    dmData.Q.Next
  end;
  dmData.Q.Close;
  dmData.trQ.Rollback;
  CreateSummary
end;

procedure TfrmWAZITUStat.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  dmUtils.SaveForm(self);
  cqrini.WriteString('WAZITUStat','profiles'+IntToStr(ord(StatType)),edtProfiles.Text);
  cqrini.WriteInteger('WAZITUStat','mode'+IntToStr(ord(StatType)),cmbMode.ItemIndex);
  cqrini.WriteInteger('WAZITUStat','width'+IntToStr(ord(StatType)),grdStat.ColWidths[0])
end;

procedure TfrmWAZITUStat.btnSelectProfileClick(Sender: TObject);
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

procedure TfrmWAZITUStat.FormClose(Sender : TObject;
  var CloseAction : TCloseAction);
begin
  dmUtils.SaveWindowPos(self)
end;

procedure TfrmWAZITUStat.FormCreate(Sender: TObject);
begin
  dmUtils.LoadWindowPos(self);
  dmUtils.LoadFontSettings(self)
end;

procedure TfrmWAZITUStat.FormShow(Sender: TObject);
var
  w : Integer = 0;
begin
  dmUtils.LoadWindowPos(self);
  gmode := '';
  dmUtils.InsertModes(cmbMode);
  cmbMode.Items.Insert(0,'ALL');
  cmbMode.Items.Insert(1,'SSB+CW');
  edtProfiles.Text  := cqrini.ReadString('WAZITUStat','profiles'+IntToStr(ord(StatType)),'');
  cmbMode.ItemIndex := cqrini.ReadInteger('WAZITUStat','mode'+IntToStr(ord(StatType)),0);
  w                 := cqrini.ReadInteger('WAZITUStat','width'+IntToStr(ord(StatType)),0);
  cmbCfmType.ItemIndex := cqrini.ReadInteger('WAZITU','LastStat',6);
  if w = 0 then
  begin
    if StatType = tsWAS then
      grdStat.ColWidths[0] := 140
    else
      grdStat.ColWidths[0] := 40
  end
  else
    grdStat.ColWidths[0] := w;

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
  btnRefresh.Click
end;

procedure TfrmWAZITUStat.btnHTMLExportClick(Sender: TObject);
begin
  dlgSave.DefaultExt := '.html';
  dlgSave.Filter := 'html|*.html;*.HTML';
  if dlgSave.Execute then
  begin
    ExportToHTML(dlgSave.FileName)
  end
end;

procedure TfrmWAZITUStat.btnRefreshClick(Sender: TObject);
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
  cqrini.WriteInteger('WAZITU','LastStat',cmbCfmType.ItemIndex); ;
  CfmType := TStat(cmbCfmType.ItemIndex);
  case StatType of
    tsWAZ   : CreateWAZStat;
    tsITU   : CreateITUStat;
    tsWAC   : CreateWACStat;
    tsWAS   : CreateWASStat
  end
end;

procedure TfrmWAZITUStat.btnShowSationListClick(Sender: TObject);
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
      tsWAZ   : begin
              if gmode = '' then
                sql := 'select main.callsign, main.freq,main.mode,main.waz from ( '+
                       'select waz,band,qsl_r,max(a.id_cqrlog_main) as id_cqrlog_main from cqrlog_main a where '+
                       '(waz <> 0) and '+ qslr +
                       'group by waz,band,qsl_r order by waz,band)'+
                       'subsel join cqrlog_main main on subsel.id_cqrlog_main = main.id_cqrlog_main  order by convert(freq,signed),waz'
              else
                sql := 'select main.callsign,main.freq,main.mode,main.waz from ( '+
                       'select waz,band,qsl_r,max(a.id_cqrlog_main) as id_cqrlog_main from cqrlog_main a where '+
                       '(waz <> 0) and '+ qslr + ' and ' + gmode +' '+
                       'group by waz,band,qsl_r order by waz,band)'+
                       'subsel join cqrlog_main main on subsel.id_cqrlog_main = main.id_cqrlog_main  order by convert(freq,signed),waz';
              l.Add('WAZ')
            end;//waz
      tsITU   : begin
              if gmode = '' then
                sql := 'select main.callsign, main.freq,main.mode,main.itu from ( '+
                       'select itu,band,qsl_r,max(a.id_cqrlog_main) as id_cqrlog_main from cqrlog_main a where '+
                       '(itu <> 0) and '+ qslr +
                       'group by itu,band,qsl_r order by itu,band)'+
                       'subsel join cqrlog_main main on subsel.id_cqrlog_main = main.id_cqrlog_main  order by convert(freq,signed),itu'
              else
                sql := 'select main.callsign,main.freq,main.mode,main.itu from ( '+
                       'select itu,band,qsl_r,max(a.id_cqrlog_main) as id_cqrlog_main from cqrlog_main a where '+
                       '(itu <> 0) and '+ qslr + ' and ' + gmode +' '+
                       'group by itu,band,qsl_r order by itu,band)'+
                       'subsel join cqrlog_main main on subsel.id_cqrlog_main = main.id_cqrlog_main  order by convert(freq,signed),itu';
              l.Add('ITU')
            end;//itu
      tsWAC  : begin
              if gmode = '' then
                sql := 'select main.callsign, main.freq,main.mode,main.cont from ( '+
                       'select cont,band,qsl_r,max(a.id_cqrlog_main) as id_cqrlog_main from cqrlog_main a where '+
                       '(cont <> '+QuotedStr('')+') and '+ qslr +
                       'group by cont,band,qsl_r order by cont,band)'+
                       'subsel join cqrlog_main main on subsel.id_cqrlog_main = main.id_cqrlog_main  order by convert(freq,signed),cont'
              else
                sql := 'select main.callsign, main.freq,main.mode,main.cont from ( '+
                       'select cont,band,qsl_r,max(a.id_cqrlog_main) as id_cqrlog_main from cqrlog_main a where '+
                       '(cont <> '+QuotedStr('')+') and '+ qslr + ' and ' + gmode +' '+
                       'group by cont,band,qsl_r order by cont,band)'+
                       'subsel join cqrlog_main main on subsel.id_cqrlog_main = main.id_cqrlog_main  order by convert(freq,signed),cont';
              l.Add('WAC')
            end;//wac
      tsWAS   : begin
              if gmode = '' then
                sql := 'select callsign,freq,mode,state from cqrlog_main '+
                        ' where (state <> '+QuotedStr('')+') and ((adif=291) or (adif=6) or (adif=110)) and '+ qslr +' order by convert(freq,signed),state'
              else
                sql := 'select callsign,freq,mode,state from cqrlog_main'+
                        ' where (state <> '+QuotedStr('')+') and ((adif=291) or (adif=6) or (adif=110)) and '+ qslr +' AND '+gmode+
                        'order by convert(freq,signed),state';
              {if gmode = '' then
                sql := 'select subsel.id_cqrlog_main, main.callsign, main.freq,main.mode,main.state from ( '+
                       'select state,band,qsl_r,max(a.id_cqrlog_main) as id_cqrlog_main from cqrlog_main a where '+
                       '(state <> '+QuotedStr('')+') and ((dxcc_ref = '+QuotedStr('W(USA)')+') or (dxcc_ref='+
                       QuotedStr('KL')+') or (dxcc_ref='+QuotedStr('KH6')+')) and '+ qslr +
                       'group by state,band,qsl_r order by state,band)'+
                       'subsel join cqrlog_main main on subsel.id_cqrlog_main = main.id_cqrlog_main  order by freq,state'
              else
                sql := 'select subsel.id_cqrlog_main, main.callsign, main.freq,main.mode,main.state from ( '+
                       'select state,band,qsl_r,max(a.id_cqrlog_main) as id_cqrlog_main from cqrlog_main a where '+
                       '(state <> '+QuotedStr('')+') and ((dxcc_ref = '+QuotedStr('W(USA)')+') or (dxcc_ref='+
                       QuotedStr('KL')+') or (dxcc_ref='+QuotedStr('KH6')+')) and '+qslr+
                       ' and ' + gmode +' group by state,band,qsl_r order by state,band)'+
                       'subsel join cqrlog_main main on subsel.id_cqrlog_main = main.id_cqrlog_main  order by freq,state';
                }
                l.Add('USA states')
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
              dmUtils.SetSize(dmData.Q.Fields[2].AsString,5)+
              dmUtils.SetSize(dmData.Q.Fields[3].AsString,5);
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

procedure TfrmWAZITUStat.ExportToHTML(htmlfile : String);
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
    tsWAZ,tsITU : Writeln(f,'<P><div align="center" class="popis">Zone</div></P>');
    tsWAC   : Writeln(f,'<P><div align="center" class="popis">Cont</div></P>');
    tsWAS   : Writeln(f,'<P><div align="center" class="popis">State</div></P>')
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

procedure TfrmWAZITUStat.LoadBandsSettings;
var
  i : Integer = 0;
begin
  grdStat.ColCount  := cMaxBandsCount;
  for i:=0 to cMaxBandsCount-1 do
  begin
    if dmUtils.MyBands[i][0]='' then
    begin
      grdStat.ColCount    := i+1;
      grdSumStat.ColCount := i+1;
      break
    end;
    grdStat.Cells[i+1,0] := dmUtils.MyBands[i][1];
    grdSumStat.Cells[i+1,0] := dmUtils.MyBands[i][1];
  end;
  grdStat.ColWidths[grdStat.ColCount-1] := 50;
  grdSumStat.ColWidths[grdSumStat.ColCount-1] := 50
end;

procedure TfrmWAZITUStat.CreateSummary;
var
  wkd : Word = 0;
  cfm : Word = 0;
  i,y : Integer;
begin
  grdSumStat.Cells[0,1] := 'WKD';
  grdSumStat.Cells[0,2] := 'CFM';

  for y := 1 to grdStat.ColCount-1 do
  begin
    wkd := 0;
    cfm := 0;
    for i := 1 to grdStat.RowCount-1 do
    begin
      if grdStat.Cells[y,i] <> '' then
        inc(wkd);
      if (grdStat.Cells[y,i]='Q') or (grdStat.Cells[y,i]='L') or (grdStat.Cells[y,i]='E') then
        inc(cfm);
{
        case CfmType of
        tcQSL : begin
              if grdStat.Cells[y,i] = 'Q' then
                inc(cfm)
            end;
        tcQSLLoTW : begin
              if (grdStat.Cells[y,i] = 'Q') or (grdStat.Cells[y,i] = 'L') then
                inc(cfm)
            end;
        tcLoTW : begin
              if grdStat.Cells[y,i] = 'L' then
                inc(cfm)
            end
       end; //case}
    end;
    grdSumStat.Cells[y,1] := IntToStr(wkd);
    grdSumStat.Cells[y,2] := IntToStr(cfm);
  end;
  grdStat.ColCount := grdStat.ColCount+1;
  grdStat.Cells[grdStat.ColCount-1,0]:= 'TOTAL';
  wkd := 0;
  cfm := 0;
  for y:=1 to grdStat.RowCount-1 do  //lines
  begin
    for i:=1 to grdStat.ColCount-1 do
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
  grdSumStat.ColCount := grdSumStat.ColCount+1;
  grdSumStat.Cells[grdSumStat.ColCount-1,0] := 'TOTAL';
  grdSumStat.Cells[grdSumStat.ColCount-1,1] := IntToStr(wkd);
  grdSumStat.Cells[grdSumStat.ColCount-1,2] := IntToStr(cfm)
end;

procedure TfrmWAZITUStat.CreateWACStat;
const
  pAF = 1;
  pAN = 2;
  pAS = 3;
  pEU = 4;
  pNA = 5;
  pOC = 6;
  pSA = 7;

  function ContPos(cont : String) : Integer;
  begin
    if cont = 'AF' then
      Result := pAF
    else if cont = 'AN' then
      Result := pAN
    else if cont = 'AS' then
      Result := pAS
    else if cont = 'EU' then
      Result := pEU
    else if cont = 'NA' then
      Result := pNA
    else if cont = 'OC' then
      Result := pOC
    else if cont = 'SA' then
      Result := pSA
  end;

const
  C_SEL = 'select cont,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main '+
          '%s '+
          'group by cont,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd '+
          'having (cont <> '''') '+
          'order by cont';


var
  i       : Integer = 1;
  y       : Integer;
  BandPos : Integer;
  QSL_R   : String;
  LoTW    : String;
  eQSL    : String;
begin

  for i:=0 to grdStat.RowCount-1 do
    for y:=0 to grdStat.ColCount-1 do
      grdStat.Cells[y,i] := '';

  LoadBandsSettings;
  Caption := 'WAC statistic';
  grdStat.Cells[0,0]:= 'Cont';

  grdStat.RowCount := 8;
  grdStat.Cells[0,pAF] := 'AF';
  grdStat.Cells[0,pAN] := 'AN';
  grdStat.Cells[0,pAS] := 'AS';
  grdStat.Cells[0,pEU] := 'EU';
  grdStat.Cells[0,pNA] := 'NA';
  grdStat.Cells[0,pOC] := 'OC';
  grdStat.Cells[0,pSA] := 'SA';

  dmData.Q.Close;
  if gmode <> '' then
    dmData.Q.SQL.Text := Format(C_SEL,['where '+gmode])
  else
    dmData.Q.SQL.Text := Format(C_SEL,['']);

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
    BandPos := BandPos+1;
    QSL_R   := dmData.Q.Fields[2].AsString;
    LoTW    := dmData.Q.Fields[3].AsString;
    eQSL    := dmData.Q.Fields[4].AsString;

    ShowCharInGrid(QSL_R,LoTW,eQSL,BandPos,ContPos(dmData.Q.Fields[0].AsString));

    dmData.Q.Next
  end;
  dmData.Q.Close;
  dmData.trQ.Rollback;
  CreateSummary
end;

procedure TfrmWAZITUStat.CreateWASStat;
  function StatePos(state : String) : Integer;
  var
    i : Integer;
  begin
    Result := -1;
    for i:=1 to 50 do
      if aStates[i] = state then
      begin
        Result := i;
        break
      end
  end;

const
  C_SEL = 'select state,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd from cqrlog_main '+
          '%s '+
          'group by state,band,qsl_r,lotw_qslr,eqsl_qsl_rcvd '+
          'having (state <> '''') '+
          'order by state';
var
  i,y : Integer;
  BandPos : Integer;
  QSL_R   : String;
  LoTW    : String;
  eQSL    : String;
  where   : String;
begin
  aStates[1]  := 'AK';
  aStates[2]  := 'AL';
  aStates[3]  := 'AR';
  aStates[4]  := 'AZ';
  aStates[5]  := 'CA';
  aStates[6]  := 'CO';
  aStates[7]  := 'CT';
  aStates[8]  := 'DE';
  aStates[9]  := 'FL';
  aStates[10] := 'GA';
  aStates[11] := 'HI';
  aStates[12] := 'IA';
  aStates[13] := 'ID';
  aStates[14] := 'IL';
  aStates[15] := 'IN';
  aStates[16] := 'KS';
  aStates[17] := 'KY';
  aStates[18] := 'LA';
  aStates[19] := 'MA';
  aStates[20] := 'MD';
  aStates[21] := 'ME';
  aStates[22] := 'MI';
  aStates[23] := 'MN';
  aStates[24] := 'MO';
  aStates[25] := 'MS';
  aStates[26] := 'MT';
  aStates[27] := 'NC';
  aStates[28] := 'ND';
  aStates[29] := 'NE';
  aStates[30] := 'NH';
  aStates[31] := 'NJ';
  aStates[32] := 'NM';
  aStates[33] := 'NV';
  aStates[34] := 'NY';
  aStates[35] := 'OH';
  aStates[36] := 'OK';
  aStates[37] := 'OR';
  aStates[38] := 'PA';
  aStates[39] := 'RI';
  aStates[40] := 'SC';
  aStates[41] := 'SD';
  aStates[42] := 'TN';
  aStates[43] := 'TX';
  aStates[44] := 'UT';
  aStates[45] := 'VA';
  aStates[46] := 'VT';
  aStates[47] := 'WA';
  aStates[48] := 'WI';
  aStates[49] := 'WV';
  aStates[50] := 'WY';

  for i:=0 to grdStat.RowCount-1 do
    for y:=0 to grdStat.ColCount-1 do
      grdStat.Cells[y,i] := '';

  grdStat.RowCount := 51;

  grdStat.Cells[0,0]  := 'State';

  for i:=1 to 50 do
    grdStat.Cells[0,i] := dmUtils.USstates[i];

  LoadBandsSettings;
  Caption := 'WAS statistic';

  dmData.Q.Close;
  where := '((adif=291) or (adif=6) or (adif=110))';
  if gmode <> '' then
    where := where + ' and '+ gmode;

  dmData.Q.SQL.Text := Format(C_SEL,['where '+where]);

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
    BandPos := BandPos+1;
    QSL_R   := dmData.Q.Fields[2].AsString;
    LoTW    := dmData.Q.Fields[3].AsString;
    eQSL    := dmData.Q.Fields[4].AsString;

    ShowCharInGrid(QSL_R,LoTW,eQSL,BandPos,StatePos(dmData.Q.Fields[0].AsString));

    dmData.Q.Next
  end;
  dmData.Q.Close;
  dmData.trQ.Rollback;
  CreateSummary
{
AK  	Alaska
AL 	Alabama
AR 	Arkansas
AZ 	Arizona
CA 	California
CO 	Colorado
CT 	Connecticut
DC 	Dist Of Col
DE 	Delaware
FL 	Florida
GA 	Georgia
HI 	Hawaii
IA 	Iowa
ID 	Idaho
IL 	Illinois
IN 	Indiana
KS 	Kansas
KY 	Kentucky
LA 	Louisiana
MA 	Massachusetts
MD 	Maryland
ME 	Maine
MI 	Michigan
MN 	Minnesota
MO 	Missouri
MS 	Mississippi
MT 	Montana
NC 	North Carolina
ND 	North Dakota
NE 	Nebraska
NH 	New Hampshire
NJ 	New Jersey
NM 	New Mexico
NV 	Nevada
NY 	New York
OH 	Ohio
OK 	Oklahoma
OR 	Oregon
PA 	Pennsylvania
RI 	Rhode Island
SC 	South Carolina
SD 	South Dakota
TN 	Tennessee
TX 	Texas
UT 	Utah
VA 	Virginia
VT 	Vermont
WA 	Washington
WI 	Wisconsin
WV 	West Virginia
WY 	Wyoming

}
end;

function TfrmWAZITUStat.GetStatTypeWhere(st : TStat) : String;
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

