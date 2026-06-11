unit feQSLDownload;

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,FileUtil,LResources,Forms,Controls,Graphics,Dialogs,StdCtrls,
  ExtCtrls, DateUtils;

type

  { TfrmeQSLDownload }

  TfrmeQSLDownload = class(TForm)
    btnClose : TButton;
    btnDownload: TButton;
    btnPreferences : TButton;
    chkChangeDate: TCheckBox;
    chkShowNew : TCheckBox;
    edtDateFrom : TEdit;
    edtQTH: TEdit;
    GroupBox1 : TGroupBox;
    gbSettings : TGroupBox;
    Label3 : TLabel;
    Label4: TLabel;
    mStat : TMemo;
    Panel1 : TPanel;
    Panel2 : TPanel;
    procedure btnDownloadClick(Sender : TObject);
    procedure btnPreferencesClick(Sender : TObject);
    procedure chkChangeDateChange(Sender: TObject);
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure FormShow(Sender : TObject);
    procedure mStatChange(Sender: TObject);
  private
  public
  end;

var
  frmeQSLDownload : TfrmeQSLDownload;

implementation
{$R *.lfm}

uses dUtils, uMyIni, dData, fImportProgress, fPreferences;

{ TfrmeQSLDownload }

procedure TfrmeQSLDownload.FormShow(Sender : TObject);
begin
  dmUtils.LoadWindowPos(frmeQSLDownload);
  edtDateFrom.Text   := cqrini.ReadString('eQSLImp','DateFrom',edtDateFrom.Text);
  edtQTH.Text        := cqrini.ReadString('eQSL','QTH','');
  chkShowNew.Checked := cqrini.ReadBool('eQSLImp','ShowNewQSOs',True);
  chkChangeDate.Checked:=cqrini.ReadBool('eQSLImp','ChangeDate',False);
end;

procedure TfrmeQSLDownload.mStatChange(Sender: TObject);
begin
  with mStat do
     begin
      //this does not always scroll to end (why?)
      SelStart := GetTextLen;
      SelLength := 0;
      ScrollBy(0, Lines.Count);
      Refresh;
      //added
      VertScrollBar.Position:=100000;
     end;
end;

procedure TfrmeQSLDownload.FormClose(Sender : TObject;
  var CloseAction : TCloseAction);
begin
  cqrini.WriteString('eQSL','QTH',edtQTH.Text);
  dmUtils.SaveWindowPos(frmeQSLDownload)
end;

procedure TfrmeQSLDownload.btnDownloadClick(Sender : TObject);
var
  user : String = '';
  pass : String = '';
  url  : String = '';
  AdifFile : String = '';
  QSOList : TStringList;
  Count : Word = 0;
  Success : Boolean = False;
  ErrMsg  : String = '';
begin
  mStat.Clear;
  Application.ProcessMessages;
  if not dmUtils.IsDateOK(edtDateFrom.Text) then
  begin
    mStat.Lines.Add('Please insert correct date (YYYY-MM-DD)!');
    edtDateFrom.SetFocus;
    exit
  end;

  user := cqrini.ReadString('LoTW','eQSLName','');
  pass := cqrini.ReadString('LoTW','eQSLPass','');
  if (user = '') or (pass='') then
  begin
    mStat.Lines.Add('User name or password is not set!');
    exit
  end;

  cqrini.WriteString('eQSLImp','DateFrom',edtDateFrom.Text);
  cqrini.WriteBool('eQSLImp','ShowNewQSOs',chkShowNew.Checked);

  AdifFile := dmData.HomeDir + 'eQSL/'+FormatDateTime('yyyy-mm-dd_hh-mm-ss',now)+'.adi';
  url := cqrini.ReadString('LoTW', 'eQSLStartAddr','https://www.eqsl.cc/qslcard/DownloadInBox.cfm')+
         '?UserName='+user+
         '&Password='+dmUtils.EncodeURLData(pass)+
         '&QTHNickname='+dmUtils.EncodeURLData(edtQTH.Text)+
         '&RcvdSince='+StringReplace(edtDateFrom.Text,'-','',[rfReplaceAll, rfIgnoreCase]);
  if dmData.DebugLevel>=1 then Writeln(url);

  QSOList := TStringList.Create;
  try
    btnClose.Enabled       := False;
    btnDownload.Enabled    := False;
    btnPreferences.Enabled := False;
    edtDateFrom.Enabled    := False;

    mStat.Lines.Add('Downloading from eQSL and importing ...');
    //Download and import run in a background thread inside the progress window,
    //so this (main) thread - and the whole UI - stays responsive.
    with TfrmImportProgress.Create(self) do
    try
      FileName    := AdifFile;
      eQSLUrl     := url;
      ImportType  := imptImporteQSLAdif;
      eQSLShowNew := chkShowNew.Checked;
      eQSLSuccess := False;
      ShowModal;
      Success := eQSLSuccess;
      ErrMsg  := eQSLErrMsg;
      if Success then
      begin
        QSOList.Text := eQSLQSOList.Text;
        Count        := eQSLQSOList.Count
      end
    finally
      Free
    end;

    if Success then
    begin
      mStat.Lines.Add('Import complete ...');
      if chkChangeDate.Checked then
      begin
        edtDateFrom.Caption := FormatDateTime('YYYY-MM-DD', IncDay(Today, -1));
        cqrini.WriteString('eQSLImp','DateFrom',FormatDateTime('YYYY-MM-DD', IncDay(Today, -1)))
      end;
      if chkShowNew.Checked then
      begin
        mStat.Lines.Add('');
        mStat.Lines.Add('New QSOs confirmed by eQSL:');
        mStat.Lines.AddStrings(QSOList);
        mStat.Lines.Add('-----------------------------');
        mStat.Lines.Add('Total: ' + IntToStr(Count) + ' new QSOs')
      end
    end
    else begin
      mStat.Lines.Add('Download/import was not successful.');
      if ErrMsg <> '' then
        mStat.Lines.Add(ErrMsg)
    end
  finally
    QSOList.Free;
    btnClose.Enabled       := True;
    btnDownload.Enabled    := True;
    btnPreferences.Enabled := True;
    edtDateFrom.Enabled    := True
  end
end;

procedure TfrmeQSLDownload.btnPreferencesClick(Sender : TObject);
begin
  cqrini.WriteInteger('Pref', 'ActPageIdx', 18);  //set lotw tab active. Number may change if preferences page change
  with TfrmPreferences.Create(self) do
  try
    ShowModal
  finally
    Free
  end
end;

procedure TfrmeQSLDownload.chkChangeDateChange(Sender: TObject);
begin
  cqrini.WriteBool('eQSLImp','ChangeDate',chkChangeDate.Checked);
end;

end.

