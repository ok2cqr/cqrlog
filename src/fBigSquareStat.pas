unit fBigSquareStat;

{$mode objfpc}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, StdCtrls, Grids, IpHtml, Ipfilebroker, db, BufDataset,
  LazFileUtils;

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
    Panel1: TPanel;
    Panel2: TPanel;
    dlgSave: TSaveDialog;
    procedure btnRefreshClick(Sender: TObject);
    procedure btnSaveToClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
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

{  dbfBand.FilePathFull := fHomeDir;
  dbfBand.TableName  := 'bandmap.dat';
  if not FileExists(fHomeDir+'bandmap.dat') then
  begin
    dbfBand.TableLevel := 7;
    dbfBand.Exclusive  := True;
    dbfBand.FieldDefs.Clear;
    With dbfBand.FieldDefs do begin
      Add('vfo_a', ftFloat);
      Add('Call', ftString, 20);
      Add('vfo_b', ftFloat);
      Add('split',ftBoolean);
      Add('color',ftLargeint);
      Add('mode',ftString,8);
      Add('band',ftString,6);
      Add('time',ftDateTime);
      Add('age', ftString,1);
      Add('pfx',ftString,10);
      Add('lat',ftString,10);
      Add('long',ftString,10);
      Add('id', ftAutoInc)
    end;
    dbfBand.CreateTable;
    dbfBand.Open;
    dbfBand.AddIndex('id','id', [ixPrimary, ixUnique]);
    dbfBand.AddIndex('vfo_a','vfo_a', []);
    dbfBand.Close;
    dbfBand.Exclusive := false;
    dbfBand.Open
}

procedure TfrmBigSquareStat.btnRefreshClick(Sender: TObject);
var
  tmp : String = '';
  grb : String = '';
  wkd : Word = 0;
  cfm : Word = 0;
  ll  : String = '';
  sum_wkd : Word = 0;
  sum_cfm : Word = 0;
  db : TBufDataset;
begin
  //db := TBufDataset.Create(nil);
  try
    //db.Fields.Clear;
    //with db.FieldDefs do
    //begin
    //  Add('loc', ftString, 4);
    //  Add('cfm',ftBoolean)
    //end;
    //db.CreateDataset;
    //db.IndexDefs.Add('loc','loc',[ixPrimary]);
    //db.Open;

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

    dmData.trQ.StartTransaction;
    dmData.trQ1.StartTransaction;
    try
      dmData.Q.SQL.Text := 'select upper(left(loc,2)) as ll FROM cqrlog_main where loc <> '+QuotedStr('')+
                           ' and band='+QuotedStr(cmbBands.Text)+' group by ll';
      dmData.Q.Open;
      WriteHMTLHeader;
      writeln(f,'<table>');
      while not dmData.Q.Eof do
      begin
        ll := dmData.Q.Fields[0].AsString;
        writeln(f,'<tr>'+LineEnding+'<td valign="middle">'+LineEnding+'<font color="black"><b>'+ll+'</b></font>'+LineEnding+'</td>');
        writeln(f,'<td align="left">');
        writeln(f,'<font color="black">');
        dmData.Q1.Close;
        dmData.Q1.SQL.Text := 'select upper(left(loc,4)) as lll FROM cqrlog_main where loc like '+
                              QuotedStr(ll+'%')+' and band = '+QuotedStr(cmbBands.Text)+
                              ' group by lll order by loc';
        dmData.Q1.Open;

        db := TBufDataset.Create(nil); //I was not able to clear all records from TBufDataset without this workaround
        try
          db.FieldDefs.Clear;
          with db.FieldDefs do
          begin
            Add('loc', ftString, 4);
            Add('cfm',ftBoolean)
          end;
          db.CreateDataset;
          db.IndexDefs.Add('loc','loc',[ixPrimary]);

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
            dmData.Q1.SQL.Text := 'select upper(left(loc,4)) as lll FROM cqrlog_main where loc like '+
                                  QuotedStr(ll+'%')+' and band = '+QuotedStr(cmbBands.Text)+
                                  'and ('+tmp+') group by lll order by loc';
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
      Writeln(f,'Confirmed:',sum_cfm);
      Writeln(f,'</font>');
      Writeln(f,'</body>');
      Writeln(f,'</html>');
      CloseFile(f)
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
  if cqrini.ReadInteger('SquareStat','Band',0) > cmbBands.Items.Count-1 then
    cmbBands.ItemIndex := 0
  else
    cmbBands.ItemIndex := cqrini.ReadInteger('SquareStat','Band',0);

  chkQSL.Checked          := cqrini.ReadBool('SquareStat','QSL',False);
  chkLoTW.Checked         := cqrini.ReadBool('SquareStat','LoTW',False);
  chkeQSL.Checked         := cqrini.ReadBool('SquareStat','eQSL',False);
  dlgSave.InitialDir      := cqrini.ReadString('SquareStat','Directory',dmData.UsrHomeDir);

  IpHtmlPanel1.Font.Color := clBlack;
  btnRefresh.Click
end;

end.

