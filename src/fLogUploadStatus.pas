unit fLogUploadStatus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  Menus, ActnList, ExtCtrls, jakozememo, lcltype,  dLogUpload, lclintf, lmessages;

type

  { TfrmLogUploadStatus }

  TfrmLogUploadStatus = class(TForm)
    acLogUploadStatus: TActionList;
    acClearMessages: TAction;
    acFontSettings: TAction;
    dlgFont: TFontDialog;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    mnuStatus: TMenuItem;
    pnlLogStatus: TPanel;
    procedure acClearMessagesExecute(Sender: TObject);
    procedure acFontSettingsExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    mFont     : TFont;
    mStatus   : TJakoMemo;
    procedure LoadFonts;
    procedure UploadDataToOnlineLogs(where : TWhereToUpload);
  public
    SyncMsg    : String;
    SyncColor  : TColor;
    SyncUpdate : String;
    thRunning  : Boolean;

    procedure UploadDataToHamQTH;
    procedure UploadDataToClubLog;
    procedure UploadDataToHrdLog;
    procedure UploadDataToAll;
    procedure SyncUploadInformation;
  end; 

type
  TUploadThread = class(TThread)
  private
    function CheckEnabledOnlineLogs : Boolean;
    function GetLogName : String;

    procedure ToMainThread(Message,Update : String);
  protected
    procedure Execute; override;
  public
    WhereToUpload : TWhereToUpload;
  end;



var
  frmLogUploadStatus: TfrmLogUploadStatus;

implementation

uses dData, dUtils, uMyIni, fNewQSO;

function TUploadThread.CheckEnabledOnlineLogs : Boolean;
const
  C_IS_NOT_ENABLED = 'Upload to %s is not enabled! Go to Preferences and change settings.';
begin
  Result := True;
  case WhereToUpload of
    upHamQTH :  begin
                  if not cqrini.ReadBool('OnlineLog','HaUP',False) then
                  begin
                    frmLogUploadStatus.SyncMsg := Format(C_IS_NOT_ENABLED,['HamQTH']);
                    Synchronize(@frmLogUploadStatus.SyncUploadInformation);
                    Result := False
                  end
                end;
    upClubLog : begin
                  if not cqrini.ReadBool('OnlineLog','ClUP',False) then
                  begin
                    frmLogUploadStatus.SyncMsg := Format(C_IS_NOT_ENABLED,['ClubLog']);
                    Synchronize(@frmLogUploadStatus.SyncUploadInformation);
                    Result := False
                  end
                end;
    upHrdLog : begin
                  if not cqrini.ReadBool('OnlineLog','HrUP',False) then
                  begin
                    frmLogUploadStatus.SyncMsg := Format(C_IS_NOT_ENABLED,['HRDLog']);
                    Synchronize(@frmLogUploadStatus.SyncUploadInformation);
                    Result := False
                  end
                end
  end //case
end;

procedure TUploadThread.Execute;
const
  C_SEL_UPLOAD_STATUS = 'select * from upload_status where logname=%s';
  C_SEL_LOG_CHANGES   = 'select * from log_changes where id > %d order by id';
var
  data       : TStringList;
  err        : String = '';
  LastId     : Integer = 0;
  Response   : String;
  ResultCode : Integer;
  Command    : String;
  UpSuccess  : Boolean = False;
  FatalError : Boolean = False;
begin
  data := TStringList.Create;
  try
    frmLogUploadStatus.thRunning := True;
    FreeOnTerminate := True;
    frmLogUploadStatus.SyncMsg    := '';
    frmLogUploadStatus.SyncUpdate := '';
    frmLogUploadStatus.SyncColor  := dmLogUpload.GetLogUploadColor(WhereToUpload);

    if not CheckEnabledOnlineLogs then
      exit;

    err :=  dmLogUpload.CheckUserUploadSettings(WhereToUpload);
    if (err<>'') then
    begin
      frmLogUploadStatus.SyncMsg := err;
      Synchronize(@frmLogUploadStatus.SyncUploadInformation);
      exit
    end;

    if dmLogUpload.trQ.Active then dmLogUpload.trQ.RollBack;
    dmLogUpload.trQ.StartTransaction;
    try try
      dmLogUpload.Q.Close;
      dmLogUpload.Q.SQL.Text := Format(C_SEL_UPLOAD_STATUS,[QuotedStr(GetLogName)]);
      dmLogUpload.Q.Open;
      LastId := dmLogUpload.Q.FieldByName('id_log_changes').AsInteger;

      dmLogUpload.Q.Close;
      dmLogUpload.Q.SQL.Text := Format(C_SEL_LOG_CHANGES,[LastId]);
      dmLogUpload.Q.Open;
      if dmLogUpload.Q.Fields[0].IsNull then
      begin
        ToMainThread('All QSO already uploaded','');
        exit
      end;
      while not dmLogUpload.Q.Eof do
      begin
        Command := dmLogUpload.Q.FieldByName('cmd').AsString;
        if (Command<>'INSERT') and (Command<>'UPDATE') and (Command<>'DELETE') then
        begin
          Writeln('Uknown command:',Command);
          dmLogUpload.Q.Next;
          Continue
        end;
        data.Clear;
        dmLogUpload.PrepareUserInfoHeader(WhereToUpload,data);

        if (Command = 'INSERT') then
        begin
          ToMainThread('Uploading '+dmLogUpload.Q.FieldByName('callsign').AsString,'');
          dmLogUpload.PrepareInsertHeader(WhereToUpload,dmLogUpload.Q.Fields[0].AsInteger,dmLogUpload.Q.FieldByName('id_cqrlog_main').AsInteger,data);
          UpSuccess := dmLogUpload.UploadLogData(dmLogUpload.GetUploadUrl(WhereToUpload,Command),data,Response,ResultCode)
        end


        else if (Command = 'UPDATE') then
        begin
          ToMainThread('Deleting original '+dmLogUpload.Q.FieldByName('old_callsign').AsString,'');
          dmLogUpload.PrepareDeleteHeader(WhereToUpload,dmLogUpload.Q.Fields[0].AsInteger,data);

          if dmData.DebugLevel >= 1 then
          begin
            Writeln('data.Text:');
            Writeln(data.Text)
          end;

          UpSuccess := dmLogUpload.UploadLogData(dmLogUpload.GetUploadUrl(WhereToUpload,'DELETE'),data,Response,ResultCode);

          if dmData.DebugLevel >= 1 then
          begin
            Writeln('Response  :',Response);
            Writeln('ResultCode:',ResultCode)
          end;

          if UpSuccess then
          begin
            Response := dmLogUpload.GetResultMessage(WhereToUpload,Response,ResultCode,FatalError);
            if FatalError then
            begin
              ToMainThread('Could not delete original QSO data!','');
              Break
            end
            else
              ToMainThread('','OK');

            data.Clear;
            dmLogUpload.PrepareUserInfoHeader(WhereToUpload,data);
            ToMainThread('Uploading updated '+dmLogUpload.Q.FieldByName('callsign').AsString,'');
            dmLogUpload.PrepareInsertHeader(WhereToUpload,dmLogUpload.Q.Fields[0].AsInteger,dmLogUpload.Q.FieldByName('id_cqrlog_main').AsInteger,data);
            UpSuccess := dmLogUpload.UploadLogData(dmLogUpload.GetUploadUrl(WhereToUpload,Command),data,Response,ResultCode)
          end
          else
            ToMainThread('Update failed! Check Internet connection','')
        end


        else if (Command = 'DELETE') then
        begin
          ToMainThread('Deleting '+dmLogUpload.Q.FieldByName('old_callsign').AsString,'');
          dmLogUpload.PrepareDeleteHeader(WhereToUpload,dmLogUpload.Q.Fields[0].AsInteger,data);
          UpSuccess := dmLogUpload.UploadLogData(dmLogUpload.GetUploadUrl(WhereToUpload,Command),data,Response,ResultCode)
        end;

        if dmData.DebugLevel >= 1 then
        begin
          Writeln('data.Text:');
          Writeln(data.Text);
          Writeln('-----------');
          Writeln('Response  :',Response);
          Writeln('ResultCode:',ResultCode);
          Writeln('-----------')
        end;

        if UpSuccess then
        begin
          Response := dmLogUpload.GetResultMessage(WhereToUpload,Response,ResultCode,FatalError);
          if (Response='OK') then
            ToMainThread('','OK')
          else
            ToMainThread(Response,'');

          if FatalError then
            Break //cannot continue when fatal error
          else
            dmLogUpload.MarkAsUploaded(GetLogName,dmLogUpload.Q.FieldByName('id').AsInteger)
        end
        else begin
          ToMainThread('Upload failed! Check Internet connection','');
          FatalError := True;
          Break
        end;
        Sleep(2000); //we don't want to make small DDOS attack to server
        dmLogUpload.Q.Next
      end;
      if not FatalError then
        ToMainThread('Done ...','')
    finally
      dmLogUpload.Q.Close;
      dmLogUpload.trQ.RollBack
    end;
    Sleep(500)
  except
    on E : Exception do
      Writeln(E.Message)
  end
  finally
    FreeAndNil(data);
    frmLogUploadStatus.thRunning := False
  end
end;

function TUploadThread.GetLogName : String;
begin
  Result := '';
  case WhereToUpload of
    upHamQTH  : Result := C_HAMQTH;
    upClubLog : Result := C_CLUBLOG;
    upHrdlog  : Result := C_HRDLOG
  end //case
end;

procedure TUploadThread.ToMainThread(Message,Update : String);
begin
  frmLogUploadStatus.SyncUpdate := Update;
  frmLogUploadStatus.SyncMsg    := GetLogName + ': ' + Message;
  Synchronize(@frmLogUploadStatus.SyncUploadInformation);
  frmLogUploadStatus.SyncUpdate := '';
  frmLogUploadStatus.SyncMsg    := ''
end;

procedure TfrmLogUploadStatus.SyncUploadInformation;
var
  item : String;
  tmp  : LongInt;
  c    : TColor;
begin
  Writeln('SyncUpdate:',SyncUpdate);
  Writeln('SyncMsg   :',SyncMsg);
  if (SyncUpdate<>'') then
  begin
    //cti_vetu(var te:string;var bpi,bpo:Tcolor;var pom:longint;kam:longint):boolean;
    mStatus.cti_vetu(item,c,c,tmp,mStatus.posledniveta);
    item := item + ' ... ' + SyncUpdate;
    Writeln('Item:',item);
    //prepis_vetu(te:string;bpi,bpo:Tcolor;pom:longint;kam:longint;msk:longint):boolean;
    mStatus.prepis_vetu(item,SyncColor,clWhite,0,mStatus.posledniveta,0)
  end
  else
    mStatus.pridej_vetu(SyncMsg,SyncColor,clWhite,0)
end;

procedure TfrmLogUploadStatus.acClearMessagesExecute(Sender: TObject);
begin
  mStatus.smaz_vse
end;

procedure TfrmLogUploadStatus.acFontSettingsExecute(Sender: TObject);
begin
  dlgFont.Font.Name := cqrini.ReadString('LogUploadStatus','FontName','Monospace');
  dlgFont.Font.Size := cqrini.ReadInteger('LogUploadStatus','FontSize',8);
  if dlgFont.Execute then
  begin
    cqrini.WriteString('LogUploadStatus','FontName',dlgFont.Font.Name);
    cqrini.WriteInteger('LogUploadStatus','FontSize',dlgFont.Font.Size);
    LoadFonts
  end
end;

procedure TfrmLogUploadStatus.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmLogUploadStatus);
end;

procedure TfrmLogUploadStatus.FormCloseQuery(Sender: TObject;
  var CanClose: boolean);
begin
  Writeln('Posralo se to ...');
  FreeAndNil(mStatus);
  FreeAndNil(mFont)
end;

procedure TfrmLogUploadStatus.FormCreate(Sender: TObject);
begin
  thRunning := False
end;

procedure TfrmLogUploadStatus.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key= VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0
  end
end;

procedure TfrmLogUploadStatus.FormShow(Sender: TObject);
begin
  mFont              := TFont.Create;
  mStatus            := Tjakomemo.Create(pnlLogStatus);
  mStatus.parent     := pnlLogStatus;
  mStatus.autoscroll := True;
  mStatus.Align      := alClient;
  dmUtils.LoadWindowPos(frmLogUploadStatus);
  LoadFonts
end;

procedure TfrmLogUploadStatus.LoadFonts;
begin
  dmUtils.LoadFontSettings(self);
  mFont.Name := cqrini.ReadString('LogUploadStatus','FontName','Monospace');
  mFont.Size := cqrini.ReadInteger('LogUploadStatus','FontSize',8);
  mStatus.nastav_font(mFont)
end;

procedure TfrmLogUploadStatus.UploadDataToOnlineLogs(where : TWhereToUpload);
var
  UploadThread : TUploadThread;
begin
  if thRunning then
  begin
    Application.MessageBox('Previous job is sill running, please try again later.','Info ...',mb_OK+mb_IconInformation)
  end
  else begin
    if not Showing then  //status window has to be visible when working
      Show;
    UploadThread := TUploadThread.Create(True);
    UploadThread.WhereToUpload := where;
    UploadThread.Start
  end
end;

procedure TfrmLogUploadStatus.UploadDataToHamQTH;
begin
  UploadDataToOnlineLogs(upHamQTH)
end;

procedure TfrmLogUploadStatus.UploadDataToClubLog;
begin
  UploadDataToOnlineLogs(upClubLog)
end;

procedure TfrmLogUploadStatus.UploadDataToHrdLog;
begin
  UploadDataToOnlineLogs(upHrdLog)
end;

procedure TfrmLogUploadStatus.UploadDataToAll;
begin
  UploadDataToOnlineLogs(upHamQTH);
  UploadDataToOnlineLogs(upClubLog);
  UploadDataToOnlineLogs(upHrdLog)
end;

initialization
  {$I fLogUploadStatus.lrs}

end.

