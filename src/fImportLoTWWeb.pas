unit fImportLoTWWeb;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
  httpsend, blcksock, StdCtrls, ExtCtrls, inifiles, ssl_openssl, ssl_openssl_lib,
  synacode;

type

  { TfrmImportLoTWWeb }

  TfrmImportLoTWWeb = class(TForm)
    btnDownload: TButton;
    btnClose: TButton;
    btnPreferences: TButton;
    chkShowNew: TCheckBox;
    edtCall: TEdit;
    edtDateFrom: TEdit;
    GroupBox1: TGroupBox;
    GroupBox5: TGroupBox;
    Label1: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    mStat: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormShow(Sender: TObject);
    procedure btnDownloadClick(Sender: TObject);
    procedure btnPreferencesClick(Sender: TObject);
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
  mStat.Clear;
  Application.ProcessMessages;
  if not dmUtils.IsDateOK(edtDateFrom.Text) then
  begin
    mStat.Lines.Add('Please insert correct date (YYYY-MM-DD)!');
    edtDateFrom.SetFocus;
    exit
  end;
  //DLLSSLName  := dmData.cDLLSSLName;
  //DLLUtilName := dmData.cDLLUtilName;

  cqrini.WriteString('LoTWImp','Call',edtCall.Text);
  AdifFile := dmData.HomeDir + 'lotw/'+FormatDateTime('yyyy-mm-dd_hh-mm-ss',now)+'.adi';
  QSOList  := TStringList.Create;
  http     := THTTPSend.Create;
{
  SSLLibFile  := dmData.DLLSSLName;
  SSLUtilFile := dmData.DLLUtilName;
  }
  Writeln('DLLSSLName:',DLLSSLName);
  Writeln('DLLUtilName:',DLLUtilName);
  Writeln('SSLLibFile:',SSLLibFile);
  Writeln('SSLUtilFile:',SSLLibFile);

  m        := TFileStream.Create(AdifFile,fmCreate);
  try
    btnClose.Enabled       := False;
    btnDownload.Enabled    := False;
    btnPreferences.Enabled := False;
    edtDateFrom.Enabled    := False;
    edtCall.Enabled        := False;

    user := cqrini.ReadString('LoTW','LoTWName','');
    pass := EncodeURL(cqrini.ReadString('LoTW','LoTWPass',''));
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
      Writeln('SSLLibfile:',SSLLibFile);
      mStat.Lines.Add('Connected to LoTW server');
      http.Document.Seek(0,soBeginning);
      m.CopyFrom(http.Document,HTTP.Document.Size);
      http.Clear;
      mStat.Lines.Add('File downloaded successfully');
      mStat.Lines.Add('File:');
      mStat.Lines.Add(AdifFile);
      Done := True;
      Repaint;
      Application.ProcessMessages;
      mStat.Lines.Add('Preparing import ....');
      if not FileExists(AdifFile) then
      begin
        mStat.Lines.Add('File: ');
        mStat.Lines.Add(AdifFile);
        mStat.Lines.Add('DOES NOT exist!');
        exit
      end;
      with TfrmImportProgress.Create(self) do
      try
        FileName    := AdifFile;
        ImportType  := 4;
        LoTWShowNew := chkShowNew.Checked;
        ShowModal;
        QSOList.Text := LoTWQSOList.Text;
        Count        := LoTWQSOList.Count
      finally
        Free
      end;
      mStat.Lines.Add('Import complete ...');
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
        Writeln('SSLLibfile:',SSLLibFile);
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
  if not cqrini.ReadBool('LoTWImp','Max',False) then
  begin
    Height           := cqrini.ReadInteger('LoTWImp','Height',Height);
    Width            := cqrini.ReadInteger('LoTWImp','Width',Width);
    Top              := cqrini.ReadInteger('LoTWImp','Top',top);
    Left             := cqrini.ReadInteger('LoTWImp','Left',left)
  end
  else begin
    WindowState := wsMaximized
  end;
  chkShowNew.Checked := cqrini.ReadBool('LoTWImp','ShowNewQSOs',True);
  edtDateFrom.Text   := cqrini.ReadString('LoTWImp','DateFrom','1990-01-01');
  edtCall.Text       := cqrini.ReadString('LoTWImp','Call',
                        cqrini.ReadString('Station','Call',''));
  Done := False
end;

procedure TfrmImportLoTWWeb.FormCloseQuery(Sender: TObject;
  var CanClose: boolean);
begin
  if not (WindowState = wsMaximized) then
  begin
    cqrini.WriteInteger('LoTWImp','Height',Height);
    cqrini.WriteInteger('LoTWImp','Width',Width);
    cqrini.WriteInteger('LoTWImp','Top',Top);
    cqrini.WriteInteger('LoTWImp','Left',Left);
    cqrini.WriteBool('LoTWImp','Max', False);
    cqrini.WriteString('LoTWImp','DateFrom',edtDateFrom.Text)
  end
  else begin
    cqrini.WriteBool('LoTWImp','Max', True)
  end;
  cqrini.WriteBool('LoTWImp','ShowNewQSOs',chkShowNew.Checked)
end;

procedure TfrmImportLoTWWeb.SockCallBack (Sender: TObject; Reason:  THookSocketReason; const  Value: string);
begin
  if Reason = HR_ReadCount then
  begin
    FileSize := FileSize + StrToInt(Value);
    if not Done then
      mStat.Lines.Strings[mStat.Lines.Count-1] := 'Size: '+ IntToStr(FileSize);
    Repaint;
    Application.ProcessMessages
  end;
  Writeln(Value);
end;

initialization
  {$I fImportLoTWWeb.lrs}

end.

