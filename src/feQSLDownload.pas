unit feQSLDownload;

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,FileUtil,LResources,Forms,Controls,Graphics,Dialogs,StdCtrls,
  ExtCtrls, blcksock, httpsend, synacode, LazFileUtils, DateUtils;

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
    Done     : Boolean;
    FileSize : Int64;
    procedure SockCallBack (Sender: TObject; Reason: THookSocketReason; const  Value: string);
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
  Done := False;
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

procedure TfrmeQSLDownload.SockCallBack (Sender: TObject; Reason:  THookSocketReason; const  Value: string);
begin
  if Reason = HR_ReadCount then
  begin
    FileSize := FileSize + StrToInt(Value);
    if not Done then
      mStat.Lines.Strings[mStat.Lines.Count-1] := 'Size: '+ IntToStr(FileSize);
    Repaint;
    Application.ProcessMessages
  end
end;

procedure TfrmeQSLDownload.btnDownloadClick(Sender : TObject);
const
  //it is better to seek the file suffix than the old way
  CDWNLD = '.adi">';

var
  user : String = '';
  pass : String = '';
  http : THTTPSend;
  m    : TFileStream;
  url  : String = '';
  AdifFile : String = '';
  QSOList : TStringList;
  Count : Word = 0;
  l     : TStringlist;
  tmp   : String;
  i     : integer;
begin
  Done := False;
  mStat.Clear;
  if not dmUtils.IsDateOK(edtDateFrom.Text) then
  begin
    mStat.Lines.Add('Please insert correct date (YYYY-MM-DD)!');
    edtDateFrom.SetFocus;
    exit
  end;
  btnClose.Enabled       := False;
  btnDownload.Enabled    := False;
  btnPreferences.Enabled := False;
  edtDateFrom.Enabled    := False;

  cqrini.WriteString('eQSLImp','DateFrom',edtDateFrom.Text);
  cqrini.WriteBool('eQSLImp','ShowNewQSOs',chkShowNew.Checked);

  AdifFile := dmData.HomeDir + 'eQSL/'+FormatDateTime('yyyy-mm-dd_hh-mm-ss',now)+'.adi';
  QSOList  := TStringList.Create;
  http     := THTTPSend.Create;
  m        := TFileStream.Create(AdifFile,fmCreate);
  l        := TStringList.Create;
  try
    user := cqrini.ReadString('LoTW','eQSLName','');
    pass := cqrini.ReadString('LoTW','eQSLPass','');
    if (user = '') or (pass='') then
    begin
      mStat.Lines.Add('User name or password is not set!');
      exit
    end;
    url := cqrini.ReadString('LoTW', 'eQSLStartAddr','https://www.eqsl.cc/qslcard/DownloadInBox.cfm')+
           '?UserName='+user+
           '&Password='+dmUtils.EncodeURLData(pass)+
           '&QTHNickname='+dmUtils.EncodeURLData(edtQTH.Text)+
           '&RcvdSince='+StringReplace(edtDateFrom.Text,'-','',[rfReplaceAll, rfIgnoreCase]);
    if dmData.DebugLevel>=1 then Writeln(url);
    http.MimeType := 'text/xml';
    http.Protocol := '1.1';
    http.Sock.OnStatus := @SockCallBack;
    http.ProxyHost := cqrini.ReadString('Program','Proxy','');
    http.ProxyPort := cqrini.ReadString('Program','Port','');
    http.UserName  := cqrini.ReadString('Program','User','');
    http.Password  := cqrini.ReadString('Program','Passwd','');
    mStat.Lines.Add('Size:');
    if http.HTTPMethod('GET',url) then
    begin
      http.Document.Seek(0,soBeginning);
      l.LoadFromStream(http.Document);
      if dmData.DebugLevel>0 then  Writeln(l.Text);
      http.Clear;
      if (pos('Error: No such Username/Password found',l.Text) > 0) then
      begin
        mStat.Lines.Add('Error: No such Username/Password found');
        exit
      end
      else begin
        if Pos(CDWNLD,l.Text) > 0 then
        begin
          //First find the line where link is
          for i:=0 to pred(l.Count) do
           begin
            if Pos(CDWNLD,l[i])>0 then //then parse filename
             Begin
                  tmp := copy(l[i],pos('HREF="',l[i])+6,length(l[i])); //start point
                  tmp := copy(l[i],1,pos('.adi"',l[i])+3); //endpoint
                  tmp := ExtractFileNameOnly(tmp)+ExtractFileExt(tmp);
             end;
           end;
          url := cqrini.ReadString('LoTW', 'eQSLDnlAddr','https://www.eqsl.cc/downloadedfiles/')+tmp;
          if dmData.DebugLevel>0 then  Writeln('url: ',url);
          mStat.Lines.Add('File will be downloaded from:');
          mStat.Lines.Add(url);
          FileSize := 0;
          mStat.Lines.Add('Size:');
          if http.HTTPMethod('GET',url) then
          begin
            http.Document.Seek(0,soBeginning);
            m.CopyFrom(http.Document,http.Document.Size);
            mStat.Lines.Add('File downloaded successfully as local file:');
            mStat.Lines.Add(AdifFile);
            Done := True;
            Repaint;
            Application.ProcessMessages;
            mStat.Lines.Add('Preparing import ....');
            Repaint;
            Application.ProcessMessages;
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
              ImportType  := imptImporteQSLAdif;
              eQSLShowNew := chkShowNew.Checked;
              ShowModal;
              QSOList.Text := eQSLQSOList.Text;
              Count        := eQSLQSOList.Count
            finally
              Free
            end;
            mStat.Lines.Add('Import complete ...');
            if chkChangeDate.Checked then
               Begin
                 edtDateFrom.Caption:= FormatDateTime('YYYY-MM-DD', IncDay(Today, -1));
                 cqrini.WriteString('eQSLImp','DateFrom',FormatDateTime('YYYY-MM-DD', IncDay(Today, -1)));
               end;
            Repaint;
            Application.ProcessMessages;
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
            mStat.Lines.Add('File was NOT downloaded!');
            mStat.Lines.Add('Error: '+IntToStr(http.Sock.LastError) + ' ' +
                            http.Sock.LastErrorDesc)
          end
        end
        else begin
          mStat.Lines.Add('eQSL page was probably changed, cannot find the link to ADIF file');
          mStat.Lines.Add('Server returned this:');
          mStat.Lines.Add(l.Text)
        end
      end
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
      mStat.Lines.Add('Error: '+http.Sock.LastErrorDesc)
    end
  finally
    http.Free;
    m.Free;
    QSOList.Free;
    l.Free;
    btnClose.Enabled    := True;
    btnDownload.Enabled := True;
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

