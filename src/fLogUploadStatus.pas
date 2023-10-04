unit fLogUploadStatus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  Menus, ActnList, ExtCtrls, uColorMemo, lcltype,  dLogUpload, lclintf, lmessages;

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
    mStatus   : TColorMemo;
    procedure LoadFonts;
    procedure UploadDataToOnlineLogs(where : TWhereToUpload; ToAll : Boolean = False);
  public
    SyncMsg    : String;
    SyncColor  : TColor;
    SyncUpdate : String;
    thRunning  : Boolean;

    procedure UploadDataToHamQTH(ToAll : Boolean = False);
    procedure UploadDataToClubLog(ToAll : Boolean = False);
    procedure UploadDataToHrdLog(ToAll : Boolean = False);
    procedure UploadDataToUDPLog(ToAll : Boolean = False);
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
    ToAll         : Boolean;
  end;



var
  frmLogUploadStatus: TfrmLogUploadStatus;

implementation
{$R *.lfm}

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
                    if (not ToAll) then
                    begin
                      frmLogUploadStatus.SyncMsg := Format(C_IS_NOT_ENABLED,['HamQTH']);
                      Synchronize(@frmLogUploadStatus.SyncUploadInformation)
                    end;
                    Result := False
                  end
                end;
    upClubLog : begin
                  if not cqrini.ReadBool('OnlineLog','ClUP',False) then
                  begin
                    if (not ToAll) then
                    begin
                      frmLogUploadStatus.SyncMsg := Format(C_IS_NOT_ENABLED,['ClubLog']);
                      Synchronize(@frmLogUploadStatus.SyncUploadInformation)
                    end;
                    Result := False
                  end
                end;
    upHrdLog : begin
                  if not cqrini.ReadBool('OnlineLog','HrUP',False) then
                  begin
                    if (not ToAll) then
                    begin
                      frmLogUploadStatus.SyncMsg := Format(C_IS_NOT_ENABLED,['HRDLog']);
                      Synchronize(@frmLogUploadStatus.SyncUploadInformation)
                    end;
                    Result := False
                  end
                end;
    upUDPLog : begin
                  if not cqrini.ReadBool('OnlineLog','UdUP',False) then
                  begin
                    if (not ToAll) then
                    begin
                      frmLogUploadStatus.SyncMsg := Format(C_IS_NOT_ENABLED,['UDPLog']);
                      Synchronize(@frmLogUploadStatus.SyncUploadInformation)
                    end;
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
  ErrorCode  : Integer = 0;
  AlreadyDel : Boolean = False;
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
        AlreadyDel := False;
        Command := dmLogUpload.Q.FieldByName('cmd').AsString;
        if (Command<>'INSERT') and (Command<>'UPDATE') and (Command<>'DELETE') then
        begin
          Writeln('Unknown command:',Command);
          dmLogUpload.Q.Next;
          Continue
        end;
        data.Clear;
        dmLogUpload.PrepareUserInfoHeader(WhereToUpload,data);

        if (Command = 'INSERT') then
        begin
          ToMainThread('Uploading '+dmLogUpload.Q.FieldByName('callsign').AsString,'');
          dmLogUpload.PrepareInsertHeader(WhereToUpload,dmLogUpload.Q.Fields[0].AsInteger,dmLogUpload.Q.FieldByName('id_cqrlog_main').AsInteger,data);
          UpSuccess := dmLogUpload.UploadLogData(WhereToUpload,Command,data,Response,ResultCode)
        end


        else if (Command = 'UPDATE') then
        begin
          if (WhereToUpload=upUDPLog) then
          begin
            UpSuccess  := True;
            Response   := '';
            ResultCode := 200
          end
          else if dmLogUpload.Q.FieldByName('upddeleted').asInteger = 1 then
          begin
            ToMainThread('Deleting original '+dmLogUpload.Q.FieldByName('old_callsign').AsString,'');
            dmLogUpload.PrepareDeleteHeader(WhereToUpload,dmLogUpload.Q.Fields[0].AsInteger,dmLogUpload.Q.FieldByName('id_cqrlog_main').AsInteger,data);

            if dmData.DebugLevel >= 1 then
            begin
              Writeln('data.Text:');
              Writeln(data.Text)
            end;

            UpSuccess := dmLogUpload.UploadLogData(WhereToUpload,'DELETE',data,Response,ResultCode);

            if dmData.DebugLevel >= 1 then
            begin
              Writeln('Response  : ',Response);
              Writeln('ResultCode: ',ResultCode)
            end
          end
          else begin
            ToMainThread('Already deleted '+dmLogUpload.Q.FieldByName('old_callsign').AsString,'');
            UpSuccess  := True;
            Response   := '';
            ResultCode := 200
          end;

          if UpSuccess then
          begin
            Response := dmLogUpload.GetResultMessage(WhereToUpload,Response,ResultCode,ErrorCode);
            if (ErrorCode = 1) then
            begin
              ToMainThread('Could not delete original QSO data!','');
              Break
            end
            else if (ErrorCode = 2) then
            begin
              ToMainThread('Could not delete original QSO data. Reason: ' + Response,'');
            end
            else if (WhereToUpload<>upUDPLog) then
              ToMainThread('','OK');
            AlreadyDel := True;
            data.Clear;
            dmLogUpload.PrepareUserInfoHeader(WhereToUpload,data);
            ToMainThread('Uploading updated '+dmLogUpload.Q.FieldByName('callsign').AsString,'');
            dmLogUpload.PrepareInsertHeader(WhereToUpload,dmLogUpload.Q.Fields[0].AsInteger,dmLogUpload.Q.FieldByName('id_cqrlog_main').AsInteger,data);
            UpSuccess := dmLogUpload.UploadLogData(WhereToUpload,Command,data,Response,ResultCode)
          end
          else
            ToMainThread('Update failed! Check Internet connection','')
        end
        else if (Command = 'DELETE') then
        begin
          ToMainThread('Deleting '+dmLogUpload.Q.FieldByName('old_callsign').AsString,'');
          dmLogUpload.PrepareDeleteHeader(WhereToUpload,dmLogUpload.Q.Fields[0].AsInteger,dmLogUpload.Q.FieldByName('id_cqrlog_main').AsInteger,data);
          UpSuccess := dmLogUpload.UploadLogData(WhereToUpload,Command,data,Response,ResultCode)
        end;

        if dmData.DebugLevel >= 1 then
        begin
          Writeln('data.Text:');
          Writeln(data.Text);
          Writeln('-----------');
          Writeln('Response  : ',Response);
          Writeln('ResultCode: ',ResultCode);
          Writeln('-----------')
        end;

        if UpSuccess then
        begin
          Response := dmLogUpload.GetResultMessage(WhereToUpload,Response,ResultCode,ErrorCode);
          if (Response='OK') then
            ToMainThread('','OK')
          else
            ToMainThread(Response,'');

          if (ErrorCode = 1) then
          begin
            if AlreadyDel then  //if cmd was update, delete was successful but new insert was not
            begin
              dmLogUpload.MarkAsUpDeleted(dmLogUpload.Q.Fields[0].AsInteger)
            end;
            Break //cannot continue when fatal error
          end
          else
            dmLogUpload.MarkAsUploaded(GetLogName,dmLogUpload.Q.FieldByName('id').AsInteger)
        end
        else begin
          if AlreadyDel then  //if cmd was update, delete was successful but new insert was not
          begin
            dmLogUpload.MarkAsUpDeleted(dmLogUpload.Q.Fields[0].AsInteger)
          end;
          ToMainThread('Upload failed! Check Internet connection','');
          ErrorCode := 1;
          Break
        end;
        Sleep(2000); //we don't want to make small DDOS attack to server
        dmLogUpload.Q.Next
      end; //while not dmLogUpload.Q.Eof do

      if not (ErrorCode = 1) then
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
    upHrdlog  : Result := C_HRDLOG;
    upUDPLog  : Result := C_UDPLOG
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
    mStatus.ReadLine(item,c,c,tmp,mStatus.LastLineNumber);
    item := item + ' ... ' + SyncUpdate;
    Writeln('Item:',item);
    //prepis_vetu(te:string;bpi,bpo:Tcolor;pom:longint;kam:longint;msk:longint):boolean;
    mStatus.ReplaceLine(item,SyncColor,clWhite,0,mStatus.LastLineNumber,0)
  end
  else
    mStatus.AddLine(SyncMsg,SyncColor,clWhite,0);

  if (Pos('Done ...',SyncMsg)>0) or (Pos('All QSO already uploaded',SyncMsg)>0) then
  begin
    if cqrini.ReadBool('OnlineLog','CloseAfterUpload',False) then
      Close
  end
end;

procedure TfrmLogUploadStatus.acClearMessagesExecute(Sender: TObject);
begin
  mStatus.RemoveAllLines
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
  mStatus            := TColorMemo.Create(pnlLogStatus);
  mStatus.parent     := pnlLogStatus;
  mStatus.AutoScroll := True;
  mStatus.Align      := alClient;
  dmUtils.LoadWindowPos(frmLogUploadStatus);
  LoadFonts
end;

procedure TfrmLogUploadStatus.LoadFonts;
begin
  dmUtils.LoadFontSettings(self);
  mFont.Name := cqrini.ReadString('LogUploadStatus','FontName','Monospace');
  mFont.Size := cqrini.ReadInteger('LogUploadStatus','FontSize',8);
  mStatus.SetFont(mFont)
end;

procedure TfrmLogUploadStatus.UploadDataToOnlineLogs(where : TWhereToUpload; ToAll : Boolean = False);
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
    UploadThread.ToAll         := ToAll;
    UploadThread.Start
  end
end;

procedure TfrmLogUploadStatus.UploadDataToHamQTH(ToAll : Boolean = False);
begin
  UploadDataToOnlineLogs(upHamQTH, ToAll)
end;

procedure TfrmLogUploadStatus.UploadDataToClubLog(ToAll : Boolean = False);
begin
  UploadDataToOnlineLogs(upClubLog, ToAll)
end;

procedure TfrmLogUploadStatus.UploadDataToHrdLog(ToAll : Boolean = False);
begin
  UploadDataToOnlineLogs(upHrdLog, ToAll)
end;

procedure TfrmLogUploadStatus.UploadDataToUDPLog(ToAll : Boolean = False);
begin
  UploadDataToOnlineLogs(upUDPLog, ToAll)
end;

procedure TfrmLogUploadStatus.UploadDataToAll;
begin
  UploadDataToOnlineLogs(upHamQTH, True);
  UploadDataToOnlineLogs(upClubLog, True);
  UploadDataToOnlineLogs(upHrdLog, True);
  UploadDataToOnlineLogs(upUDPLog, True)
end;

end.

