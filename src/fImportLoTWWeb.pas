unit fImportLoTWWeb;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
  httpsend, blcksock, StdCtrls, ExtCtrls, inifiles, ssl_openssl, ssl_openssl_lib,
  synacode, DateUtils;

type

  { TfrmImportLoTWWeb }

  TfrmImportLoTWWeb = class(TForm)
    btnClose: TButton;
    btnDownload: TButton;
    btnPreferences: TButton;
    cbImports: TCheckBox;
    chkChangeDate: TCheckBox;
    chkShowNew: TCheckBox;
    edtCall: TEdit;
    edtDateFrom: TEdit;
    gbProgress: TGroupBox;
    gbSettings: TGroupBox;
    lblForCall: TLabel;
    lblReturnQsl: TLabel;
    Label4: TLabel;
    mStat: TMemo;
    pnlSettings: TPanel;
    pnlButtons: TPanel;
    procedure cbImportsChange(Sender: TObject);
    procedure chkChangeDateChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormShow(Sender: TObject);
    procedure btnDownloadClick(Sender: TObject);
    procedure btnPreferencesClick(Sender: TObject);
    procedure mStatChange(Sender: TObject);
  private
    Done : Boolean;
    FileSize : Int64;
    procedure SockCallBack (Sender: TObject; Reason:  THookSocketReason; const  Value: string);
  public
    { public declarations }
  end; 

var
  frmImportLoTWWeb: TfrmImportLoTWWeb;

implementation
{$R *.lfm}

uses fPreferences, dUtils, dData, fImportProgress, uMyini;

procedure TfrmImportLoTWWeb.btnPreferencesClick(Sender: TObject);
begin
  with TfrmPreferences.Create(self) do
  try
    pgPreferences.ActivePage := tabLoTW;
    ShowModal
  finally
    Free
  end
end;

procedure TfrmImportLoTWWeb.mStatChange(Sender: TObject);
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

procedure TfrmImportLoTWWeb.btnDownloadClick(Sender: TObject);
var
  user : String = '';
  pass : String = '';
  http : THTTPSend;
  m    : TFileStream;
  url  : String = '';
  AdifFile : String = '';
  QSOList : TStringList;
  Count : Word = 0;
begin
  Done := False;
  FileSize := 0;
  mStat.Clear;
  Application.ProcessMessages;
  if not dmUtils.IsDateOK(edtDateFrom.Text) then
  begin
    mStat.Lines.Add('Please insert correct date (YYYY-MM-DD)!');
    edtDateFrom.SetFocus;
    exit
  end;

  cqrini.WriteString('LoTWImp','Call',edtCall.Text);
  AdifFile := dmData.HomeDir + 'lotw/'+FormatDateTime('yyyy-mm-dd_hh-mm-ss',now)+'.adi';
  QSOList  := TStringList.Create;
  http     := THTTPSend.Create;

  if dmData.DebugLevel>=1 then
  begin
    Writeln('DLLSSLName:',DLLSSLName);
    Writeln('DLLUtilName:',DLLUtilName)
  end;

  m        := TFileStream.Create(AdifFile,fmCreate);
  try
    btnClose.Enabled       := False;
    btnDownload.Enabled    := False;
    btnPreferences.Enabled := False;
    edtDateFrom.Enabled    := False;
    edtCall.Enabled        := False;

    user := cqrini.ReadString('LoTW','LoTWName','');
    pass :=dmUtils.EncodeURLData(cqrini.ReadString('LoTW','LoTWPass',''));
    http.Sock.OnStatus := @SockCallBack;
    HTTP.ProxyHost := cqrini.ReadString('Program','Proxy','');
    HTTP.ProxyPort := cqrini.ReadString('Program','Port','');
    HTTP.UserName  := cqrini.ReadString('Program','User','');
    HTTP.Password  := cqrini.ReadString('Program','Passwd','');

    if (user = '') or (pass='') then
    begin
      mStat.Lines.Add('User name or password is not set!');
      exit
    end;
    cqrini.WriteString('LoTWImp','DateFrom',edtDateFrom.Text);

    url := 'https://LoTW.arrl.org/lotwuser/lotwreport.adi?login='+user+'&password='+pass+'&qso_query=1&qso_qsldetail="yes"'+
           '&qso_qslsince='+edtDateFrom.Text;

    if edtCall.Text <> '' then
      url := url+'&qso_owncall='+edtCall.Text;
    if dmData.DebugLevel>=1 then Writeln(url);
    http.MimeType := 'text/xml';
    http.Protocol := '1.1';
    if http.HTTPMethod('GET',url) then
    begin
      http.Document.Seek(0,soBeginning);
      m.CopyFrom(http.Document,HTTP.Document.Size);
      http.Clear;
      mStat.Lines.Add('File downloaded successfully');
      mStat.Lines.Add('File: '+ AdifFile);
      Done := True;
      Repaint;
      Application.ProcessMessages;
      mStat.Lines.Add('Preparing import ....');
      if not FileExists(AdifFile) then
      begin
        mStat.Lines.Add('File: '+ AdifFile);
        mStat.Lines.Add('DOES NOT exist!');
        exit
      end;
      with TfrmImportProgress.Create(self) do
      try
        FileName    := AdifFile;
        ImportType  := imptImportLoTWAdif;
        LoTWShowNew := chkShowNew.Checked;
        ShowModal;
        QSOList.Text := LoTWQSOList.Text;
        Count        := LoTWQSOList.Count
      finally
        Free
      end;
      mStat.Lines.Add('Import complete ...');
      if chkChangeDate.Checked then
        Begin
         edtDateFrom.Caption:= FormatDateTime('YYYY-MM-DD', IncDay(Today, -1));
         cqrini.WriteString('LoTWImp','DateFrom',FormatDateTime('YYYY-MM-DD', IncDay(Today, -1)));
        end;
      if chkShowNew.Checked then
      begin
        mStat.Lines.Add('');
        mStat.Lines.Add('New QSOs confirmed by LoTW:');
        mStat.Lines.AddStrings(QSOList);
        mStat.Lines.Add('-----------------------------');
        mStat.Lines.Add('Total: ' + IntToStr(Count) + ' new QSOs');
      end;
    end
    else begin
      if dmData.DebugLevel >= 1 then
      begin
        http.Document.Seek(0,soBeginning);
        m.CopyFrom(http.Document,HTTP.Document.Size);
        mStat.Lines.LoadFromStream(m)
      end;
      mStat.Lines.Add('NOT logged');
      mStat.Lines.Add('Error: '+IntToStr(http.Sock.LastError));
      mStat.Lines.Add('Error: '+http.Sock.LastErrorDesc);
      mStat.Lines.Add('Error: '+http.Sock.SSL.LibName)
    end
  finally
    http.Free;
    m.Free;
    QSOList.Free;
    btnClose.Enabled       := True;
    btnDownload.Enabled    := True;
    btnPreferences.Enabled := True;
    edtDateFrom.Enabled    := True;
    edtCall.Enabled        := True
  end
end;

procedure TfrmImportLoTWWeb.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(self);
  chkShowNew.Checked := cqrini.ReadBool('LoTWImp','ShowNewQSOs',True);
  chkChangeDate.Checked:=cqrini.ReadBool('LoTWImp','ChangeDate',False);
  edtDateFrom.Text   := cqrini.ReadString('LoTWImp','DateFrom','1990-01-01');
  edtCall.Text       := cqrini.ReadString('LoTWImp','Call',
                        cqrini.ReadString('Station','Call',''));
  cbImports.Checked  := cqrini.ReadBool('LoTWImp','Import',True);
  Done := False
end;

procedure TfrmImportLoTWWeb.FormCloseQuery(Sender: TObject;
  var CanClose: boolean);
begin
  dmUtils.SaveWindowPos(self)
end;

procedure TfrmImportLoTWWeb.cbImportsChange(Sender: TObject);
begin
  cqrini.WriteBool('LoTWImp','Import',cbImports.Checked);
end;

procedure TfrmImportLoTWWeb.chkChangeDateChange(Sender: TObject);
begin
  cqrini.WriteBool('LoTWImp','ChangeDate',chkChangeDate.Checked);
end;

procedure TfrmImportLoTWWeb.SockCallBack (Sender: TObject; Reason:  THookSocketReason; const  Value: string);
begin
  case Reason of
      HR_Connect :  Begin
                     if dmData.DebugLevel>=1 then Writeln( 'Connected to LoTW server');
                     mStat.Lines.Add('Connected to LoTW server');
                     mStat.Lines.Add('Downloading...');
                     Repaint;
                     Application.ProcessMessages
                    end;

      HR_ReadCount: begin
                      FileSize := FileSize + StrToInt(Value);
                      if not Done then
                        mStat.Lines.Strings[mStat.Lines.Count-1] := 'Downloading size: '+ IntToStr(FileSize);
                      Repaint;
                      Application.ProcessMessages
                    end;

  end;
end;

end.

