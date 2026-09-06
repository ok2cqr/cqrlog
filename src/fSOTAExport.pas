unit fSOTAExport; 

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,FileUtil,LResources,Forms,Controls,Graphics,Dialogs,StdCtrls,
  ComCtrls,ExtCtrls, LCLType, LazFileUtils, db;

type

  { TfrmSOTAExport }

  TfrmSOTAExport = class(TForm)
    Button1 : TButton;
    btnClose : TButton;
    btnExport : TButton;
    chkHisSota : TCheckBox;
    cmbSota : TComboBox;
    cmbHisSota : TComboBox;
    edtNotes : TEdit;
    edtCallsign : TEdit;
    edtFileName : TEdit;
    edtSota : TEdit;
    GroupBox1 : TGroupBox;
    GroupBox2 : TGroupBox;
    GroupBox3 : TGroupBox;
    Label1 : TLabel;
    Label2 : TLabel;
    Label3 : TLabel;
    Label4 : TLabel;
    Label6 : TLabel;
    lblDone : TLabel;
    pbExport : TProgressBar;
    dlgSave : TSaveDialog;
    rbAddLogNote : TRadioButton;
    rbAddEdtNote : TRadioButton;
    rbSotaEdt : TRadioButton;
    rbSotaLog : TRadioButton;
    procedure btnExportClick(Sender : TObject);
    procedure Button1Click(Sender : TObject);
    procedure cmbSotaSelect(Sender : TObject);
    procedure edtSotaEnter(Sender : TObject);
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure FormShow(Sender : TObject);
  private
    procedure SaveSettings;
  public
    { public declarations }
  end; 

var
  frmSOTAExport : TfrmSOTAExport;

implementation
{$R *.lfm}

uses dData,dUtils, uMyIni, dSqlImpExp;

{ TfrmSOTAExport }

procedure TfrmSOTAExport.FormShow(Sender : TObject);
begin
  dmUtils.LoadWindowPos(self);
  edtFileName.Text  := cqrini.ReadString('SotaExport','FileName','');
  edtSota.Text      := cqrini.ReadString('SotaExport','Sota','');
  if cqrini.ReadBool('SotaExport','FromLog',True) then
  begin
    rbSotaLog.Checked := cqrini.ReadBool('SotaExport','FromLog',True);
    rbSotaEdt.Checked := not cqrini.ReadBool('SotaExport','FromLog',True)
  end;
  cmbSota.ItemIndex := cqrini.ReadInteger('SotaExport','cmbSota',0);
  edtCallsign.Text  := cqrini.ReadString('SotaExport','Callsign',
                       cqrini.ReadString('Station','Call',''));
  if edtFileName.Text='' then
    dlgSave.InitialDir := dmData.UsrHomeDir
  else
    dlgSave.InitialDir := ExtractFilePath(edtFileName.Text);
  rbAddLogNote.Checked := cqrini.ReadBool('SotaExport','Note',True);
  rbAddEdtNote.Checked := not rbAddEdtNote.Checked;
  edtNotes.Text        := cqrini.ReadString('SotaExport','NoteText','');

  chkHisSota.Checked   := cqrini.ReadBool('SotaExport','ExportHisSummit',False);
  cmbHisSota.ItemIndex := cqrini.ReadInteger('SotaExport','cmbHisSota',0)
end;

procedure TfrmSOTAExport.SaveSettings;
begin
  cqrini.WriteString('SotaExport','FileName',edtFileName.Text);
  cqrini.WriteBool('SotaExport','FromLog',rbSotaLog.Checked);
  cqrini.WriteString('SotaExport','Sota',edtSota.Text);
  cqrini.WriteInteger('SotaExport','cmbSota',cmbSota.ItemIndex);
  cqrini.WriteString('SotaExport','Callsign',edtCallsign.Text);
  cqrini.WriteBool('SotaExport','Note',rbAddLogNote.Checked);
  cqrini.WriteString('SotaExport','NoteText',edtNotes.Text);

  cqrini.WriteBool('SotaExport','ExportHisSummit',chkHisSota.Checked);
  cqrini.WriteInteger('SotaExport','cmbHisSota',cmbHisSota.ItemIndex)
end;

procedure TfrmSOTAExport.FormClose(Sender : TObject;
  var CloseAction : TCloseAction);
begin
  SaveSettings;
  dmUtils.SaveWindowPos(self)
end;

procedure TfrmSOTAExport.btnExportClick(Sender : TObject);
var
  AllQSO  : Boolean=False;
  f       : TextFile;
  rows    : TDataSet;
  sota    : String;
  note    : String;
  HisSota : String='';
begin
  SaveSettings;
  if not dmData.IsFilter then
  begin
    if Application.MessageBox('You didn''t set any filter. Do you want to export all QSO?','Question ...',
                              mb_YesNo+mb_IconQuestion) = mrYes then
      AllQSO := True
    else
      exit
  end;
  if FileExistsUTF8(edtFileName.Text) then
  begin
    if Application.MessageBox('File already exists,overwrite it?','Question ...',mb_YesNo
                              +mb_IconQuestion)=mrYes then
      DeleteFileUTF8(edtFileName.Text)
    else
      exit
  end;
  if (trim(edtFileName.Text)='') then
  begin
    Application.MessageBox('You must choose file to export!','Error ...',mb_OK+mb_IconError);
    exit
  end;
  if (Trim(edtCallsign.Text)='') then
  begin
    Application.MessageBox('Callsign can NOT be empty!','Error ...',mb_OK+mb_IconError);
    edtCallsign.SetFocus;
    exit
  end;
  pbExport.Position := 0;
  lblDone.Visible   := False;
  pbExport.Visible  := True;
  try try
    AssignFile(f,edtFileName.Text);
    Rewrite(f);
    if AllQSO then
      rows := dmSqlImpExp.OpenQsosByDateRows
    else
      rows := dmSqlImpExp.OpenFilteredQsosByDateRows(dmData.qCQRLOG.SQL.Text);
    rows.Last; //to get proper count
    pbExport.Max := rows.RecordCount;
    rows.First;
    while not rows.Eof do
    begin
      if rbSotaLog.Checked then
      begin
        sota := '';
        case cmbSota.ItemIndex of
          0 : sota := rows.FieldByName('award').AsString;
          1 : sota := rows.FieldByName('remarks').AsString;
          2 : sota := rows.FieldByName('qth').AsString
        end //case
      end
      else
        sota := edtSota.Text;
      if rbAddLogNote.Checked then
        note := rows.FieldByName('remarks').AsString
      else
        note := edtNotes.Text;
      note := StringReplace(note,',',' ',[rfReplaceAll, rfIgnoreCase]);

      if chkHisSota.Checked then
      begin
        case cmbHisSota.ItemIndex of
           0 : HisSota := rows.FieldByName('award').AsString;
           1 : HisSota := rows.FieldByName('remarks').AsString;
           2 : HisSota := rows.FieldByName('qth').AsString
         end //case
      end;

      Writeln(f,
              'V2,',
              edtCallsign.Text+',',  //callsign
              sota+',',              //sota
              dmUtils.DateInSOTAFormat(rows.FieldByName('qsodate').AsDateTime)+',',
              StringReplace(rows.FieldByName('time_on').AsString,':','',[rfReplaceAll, rfIgnoreCase])+',',
              FormatFloat('0.00;;',rows.FieldByName('freq').AsFloat),'MHz,',
              //2022-05-05 OH1KH It seems that SOTA mode can be CqrMode (mainly CW,SSB,FM,AM)(I.E. no mode+submode pairs needed)
              //otherwise use dmUtils.ModeFromCqr to get mode and submode at this point
              rows.FieldByName('mode').AsString,',',

              rows.FieldByName('callsign').AsString,',',  //his callsign
              HisSota+',', //his summit
              note  //comments
      );

      {
      Writeln(f,edtCallsign.Text,',',
              dmUtils.DateInSOTAFormat(rows.FieldByName('qsodate').AsDateTime),',',
              StringReplace(rows.FieldByName('time_on').AsString,':','',[rfReplaceAll, rfIgnoreCase]),',',
              sota,',',
              FormatFloat('0.00;;',rows.FieldByName('freq').AsFloat),'MHz,',
              rows.FieldByName('mode').AsString,',',
              rows.FieldByName('callsign').AsString,',',
              note
              );
      }
      pbExport.StepIt;
      rows.Next
    end;
    CloseFile(f)
  except
    on E : Exception do
    begin
      Application.MessageBox(Pchar('An error occurred during export:'+LineEnding+E.Message),'Error ...',
                             mb_OK+mb_IconError)
    end
  end
  finally
    lblDone.Visible := True;
    dmSqlImpExp.CloseRows
  end
end;

procedure TfrmSOTAExport.Button1Click(Sender : TObject);
begin
  if dlgSave.Execute then
    edtFileName.Text := dlgSave.FileName
end;

procedure TfrmSOTAExport.cmbSotaSelect(Sender : TObject);
begin
  rbSotaLog.Checked := True
end;

procedure TfrmSOTAExport.edtSotaEnter(Sender : TObject);
begin
  rbSotaEdt.Checked := True
end;

end.

