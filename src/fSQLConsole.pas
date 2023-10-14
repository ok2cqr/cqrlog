unit fSQLConsole;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, memds, db, FileUtil, LResources, Forms, Controls, Graphics,
  Dialogs, DBGrids, ComCtrls, ExtCtrls, StdCtrls, ActnList,
  SynMemo, SynHighlighterSQL, SynCompletion, lcltype;

type

  { TfrmSQLConsole }

  TfrmSQLConsole = class(TForm)
    acSQL: TActionList;
    acExecute: TAction;
    acPrev: TAction;
    acNext: TAction;
    acExport: TAction;
    acSaveSQL: TAction;
    acLoadSQL: TAction;
    acGetSQL: TAction;
    btnClose: TButton;
    btnHelp: TButton;
    dsrSQL: TDatasource;
    dbgrdSQL: TDBGrid;
    imgSQL: TImageList;
    dlgOpen: TOpenDialog;
    lblTime: TLabel;
    Panel1: TPanel;
    mSQL: TSynMemo;
    dlgSave: TSaveDialog;
    SynAutoComplete1: TSynAutoComplete;
    SynSQLSyn1: TSynSQLSyn;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    procedure acExecuteExecute(Sender: TObject);
    procedure acExportExecute(Sender: TObject);
    procedure acGetSQLExecute(Sender: TObject);
    procedure acLoadSQLExecute(Sender: TObject);
    procedure acNextExecute(Sender: TObject);
    procedure acPrevExecute(Sender: TObject);
    procedure acSaveSQLExecute(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    aSQL : Array [1..50] of String;
    aSQLPos : Word;
    procedure LoadSQLCommands;
    procedure SaveSQLCommands;
    procedure AddSQLCommand(cmd : String);
    procedure ExportToCsv(FileName : string);
    procedure ExportToHTML(FileName : string);
    procedure Show_aSQL;
  public
    { public declarations }
  end; 

var
  frmSQLConsole: TfrmSQLConsole;

implementation
{$R *.lfm}

uses dUtils, dData, uMyIni;

{ TfrmSQLConsole }

procedure TfrmSQLConsole.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmSQLConsole);
  mSQL.ClearAll;
  LoadSQLCommands
end;

procedure TfrmSQLConsole.acExecuteExecute(Sender: TObject);
var
  err : Boolean = False;
  t   : TDateTime;
  h,m,s,ms : Word;
begin
  try
    dmData.qSQLConsole.Close;
    mSQL.Text := trim(mSQL.Text);
    if mSQL.Text = '' then
      exit;
    dmData.qSQLConsole.SQL.Text := mSQL.Text;
    if dmData.DebugLevel>=1 then Writeln(dmData.qSQLConsole.SQL.Text);
    AddSQLCommand(mSQL.Text);
    if dmData.trSQLConsole.Active then
      dmData.trSQLConsole.Rollback;
    dmData.trSQLConsole.StartTransaction;
    t := now;
    if (Pos('UPDATE',UpperCase(mSQL.Text)) > 0) or (Pos('DELETE',UpperCase(mSQL.Text)) > 0) or
       (Pos('REPAIR TABLE',UpperCase(mSQL.Text))>0) or (Pos('OPTIMIZE TABLE',UpperCase(mSQL.Text))>0) or
       (Pos('DROP',UpperCase(mSQL.Text))>0) or (Pos('TRUNCATE',UpperCase(mSQL.Text))>0) or
       (Pos('CREATE',UpperCase(mSQL.Text))>0) then
      dmData.qSQLConsole.ExecSQL
    else
      dmData.qSQLConsole.Open
  except
    on E : exception do
    begin
      Application.MessageBox(PChar('SQL error:'+E.Message),'Error ...',mb_ok + mb_IconError);
      dmData.trSQLConsole.Rollback
    end
  end;
  if not err then
    dmData.trSQLConsole.Commit;
  t := t - now;
  DecodeTime(t,h,m,s,ms);
  lblTime.Caption := 'It takes about '+IntToStr(m)+' minutes '+IntToStr(s)+ 'seconds '+
                     IntToStr(ms)+' milliseconds'
end;

procedure TfrmSQLConsole.acExportExecute(Sender: TObject);
begin
  dlgSave.DefaultExt := '.csv';
  dlgSave.Filter := 'CSV|*.csv|HTML|*.html';
  if dlgSave.Execute then
  begin
    if ExtractFileExt(dlgSave.FileName) = '.csv' then
      ExportToCsv(dlgSave.FileName)
    else
      ExportToHTML(dlgSave.FileName)
  end
end;

procedure TfrmSQLConsole.acGetSQLExecute(Sender: TObject);
begin
  mSQL.Text := dmData.qCQRLOG.SQL.Text
end;

procedure TfrmSQLConsole.acLoadSQLExecute(Sender: TObject);
begin
  dlgOpen.Filter := 'SQL|*.sql';
  if dlgOpen.Execute then
    if FileExists(dlgOpen.FileName) then  //with QT5 opendialog user can enter filename that may not exist
      mSQL.Lines.LoadFromFile(dlgOpen.FileName)
    else
        ShowMessage('File not found!');
end;

procedure TfrmSQLConsole.acNextExecute(Sender: TObject);
begin
  Show_aSQL;
  //Writeln('aSQLPos:',aSQLPos);
  if aSQLPos > 1 then
  begin
    if (aSQL[aSQLPos-1] = '') then
      exit;
    dec(aSQLPos);
    mSQL.Text := aSQL[aSQLPos]
  end
end;

procedure TfrmSQLConsole.acPrevExecute(Sender: TObject);
begin
  Show_aSQL;
  //Writeln('aSQLPos:',aSQLPos);
  if aSQLPos < 50 then
  begin
    if (aSQL[aSQLPos+1] = '') then
      exit;
    Inc(aSQLPos);
    mSQL.Text := aSQL[aSQLPos]
  end
end;

procedure TfrmSQLConsole.acSaveSQLExecute(Sender: TObject);
begin
  dlgSave.DefaultExt := '.sql';
  dlgSave.Filter := 'SQL|*.sql';
  if dlgSave.Execute then
    mSQL.Lines.SaveToFile(dlgSave.FileName)
end;

procedure TfrmSQLConsole.btnCloseClick(Sender: TObject);
begin
  Close
end;

procedure TfrmSQLConsole.btnHelpClick(Sender: TObject);
begin
  ShowHelp
end;

procedure TfrmSQLConsole.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmData.qSQLConsole.Close;
  dmUtils.SaveWindowPos(frmSQLConsole);
  SaveSQLCommands
end;

procedure TfrmSQLConsole.ExportToCsv(FileName : string);
var
  f : TextFile;
  i : Integer;
begin
  AssignFile(f, FileName);
  Rewrite(f);
  dmData.qSQLConsole.DisableControls;
  try
    for i:=0 to dmData.qSQLConsole.FieldCount-1 do
      Write(f,dmData.qSQLConsole.Fields[i].DisplayName,';');
    Writeln(f);
    dmData.qSQLConsole.First;
    while not dmData.qSQLConsole.Eof do
    begin
      for i:=0 to dmData.qSQLConsole.FieldCount-1 do
      begin
        if dmData.qSQLConsole.Fields[i].IsNull then
          Write(f,';')
        else
          Write(f,dmData.qSQLConsole.Fields[i].AsVariant,';')
      end;
      Writeln(f);
      dmData.qSQLConsole.Next
    end
  finally
    dmData.qSQLConsole.EnableControls;
    CloseFile(f)
  end
end;

procedure TfrmSQLConsole.ExportToHTML(FileName : string);
var
  f : TextFile;
  i : Integer;
begin
  AssignFile(f, FileName);
  Rewrite(f);
  dmData.qSQLConsole.DisableControls;
  try
    Writeln(f,'<table>');
    Writeln(f,'<tr>');
    for i:=0 to dmData.qSQLConsole.FieldCount-1 do
      Write(f,'<td>',dmData.qSQLConsole.Fields[i].DisplayName,'</td>');
    Writeln(f);
    Writeln(f,'</tr>');
    dmData.qSQLConsole.First;
    while not dmData.qSQLConsole.Eof do
    begin
      Writeln(f,'<tr>');
      for i:=0 to dmData.qSQLConsole.FieldCount-1 do
      begin
        if dmData.qSQLConsole.Fields[i].IsNull then
          Writeln(f,'<td>&nbsp;</td>')
        else
          Write(f,'<td>',dmData.qSQLConsole.Fields[i].AsVariant,'</td>')
      end;
      Writeln(f);
      Writeln(f,'</tr>');
      dmData.qSQLConsole.Next
    end;
    Writeln(f,'</table>')
  finally
    dmData.qSQLConsole.EnableControls;
    CloseFile(f)
  end
end;

procedure TfrmSQLConsole.LoadSQLCommands;
var
  i : Integer = 0;
begin
  for i:=1 to 50 do
    aSQL[i] := trim(cqrini.ReadString('SQLConsole',IntToStr(i),''));
  mSQL.Text := aSQL[1];
  aSQLPos   := 1
end;

procedure TfrmSQLConsole.SaveSQLCommands;
var
  i : Integer = 0;
begin
  for i:=1 to 50 do
    cqrini.WriteString('SQLConsole',IntToStr(i),aSQL[i]);
  cqrini.SaveToDisk
end;

procedure TfrmSQLConsole.AddSQLCommand(cmd : String);
var
  i : Integer = 0;
begin
  Show_aSQL;
  if (cmd = aSQL[1]) then
    exit;
  for i:=49 downto 1 do
    aSQL[i+1] := aSQL[i];
  aSQL[1] := cmd;
  aSQLPos := 1;
  Show_aSQL;
  SaveSQLCommands
end;

procedure TfrmSQLConsole.Show_aSQL;
var
  i : Integer;
begin
  exit;
  Writeln('');
  for i:=1 to 50 do
    Write(aSQL[i],'|');
  Writeln('')
end;

end.

