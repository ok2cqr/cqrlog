unit fSOTAExport; 

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,FileUtil,LResources,Forms,Controls,Graphics,Dialogs,StdCtrls,
  ComCtrls,ExtCtrls, LCLType, LazFileUtils;

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

uses dData,dUtils, uMyIni;

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
  sota    : String;
  note    : String;
  q       : String;
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
  if dmData.trQ.Active then dmData.trQ.Rollback;
  dmData.Q.Close;
  if AllQSO then
    dmData.Q.SQL.Text := 'select qsodate,time_on,callsign,freq,mode,award,qth,remarks '+
                         'from view_cqrlog_main_by_qsodate order by qsodate,time_on'
  else begin
    q := dmData.qCQRLOG.SQL.Text;
    if Pos('order by',LowerCase(q)) > 0 then
      q := copy(q,1,Pos('order by',LowerCase(q))-1);
    q := q + ' order by qsodate,time_on';
    dmData.Q.SQL.Text := q;
  end;
  try try
    AssignFile(f,edtFileName.Text);
    Rewrite(f);
    dmData.trQ.StartTransaction;
    dmData.Q.Open;
    dmData.Q.Last; //to get proper count
    pbExport.Max := dmData.Q.RecordCount;
    dmData.Q.First;
    while not dmData.Q.Eof do
    begin
      if rbSotaLog.Checked then
      begin
        sota := '';
        case cmbSota.ItemIndex of
          0 : sota := dmData.Q.FieldByName('award').AsString;
          1 : sota := dmData.Q.FieldByName('remarks').AsString;
          2 : sota := dmData.Q.FieldByName('qth').AsString
        end //case
      end
      else
        sota := edtSota.Text;
      if rbAddLogNote.Checked then
        note := dmData.Q.FieldByName('remarks').AsString
      else
        note := edtNotes.Text;
      note := StringReplace(note,',',' ',[rfReplaceAll, rfIgnoreCase]);

      if chkHisSota.Checked then
      begin
        case cmbHisSota.ItemIndex of
           0 : HisSota := dmData.Q.FieldByName('award').AsString;
           1 : HisSota := dmData.Q.FieldByName('remarks').AsString;
           2 : HisSota := dmData.Q.FieldByName('qth').AsString
         end //case
      end;

      Writeln(f,
              'V2,',
              edtCallsign.Text+',',  //callsign
              sota+',',              //sota
              dmUtils.DateInSOTAFormat(dmData.Q.FieldByName('qsodate').AsDateTime)+',',
              StringReplace(dmData.Q.FieldByName('time_on').AsString,':','',[rfReplaceAll, rfIgnoreCase])+',',
              FormatFloat('0.00;;',dmData.Q.FieldByName('freq').AsFloat),'MHz,',
              //2022-05-05 OH1KH It seems that SOTA mode can be CqrMode (mainly CW,SSB,FM,AM)(I.E. no mode+submode pairs needed)
              //otherwise use dmUtils.ModeFromCqr to get mode and submode at this point
              dmData.Q.FieldByName('mode').AsString,',',

              dmData.Q.FieldByName('callsign').AsString,',',  //his callsign
              HisSota+',', //his summit
              note  //comments
      );

      {
      Writeln(f,edtCallsign.Text,',',
              dmUtils.DateInSOTAFormat(dmData.Q.FieldByName('qsodate').AsDateTime),',',
              StringReplace(dmData.Q.FieldByName('time_on').AsString,':','',[rfReplaceAll, rfIgnoreCase]),',',
              sota,',',
              FormatFloat('0.00;;',dmData.Q.FieldByName('freq').AsFloat),'MHz,',
              dmData.Q.FieldByName('mode').AsString,',',
              dmData.Q.FieldByName('callsign').AsString,',',
              note
              );
      }
      pbExport.StepIt;
      dmData.Q.Next
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
    dmData.trQ.Rollback;
    dmData.Q.Close
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

