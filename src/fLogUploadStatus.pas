unit fLogUploadStatus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  Menus, ActnList, ExtCtrls, jakozememo, lcltype,  dLogUpload, lclintf, lmessages;

type
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
    procedure FormShow(Sender: TObject);
  private
    mFont     : TFont;
    thUpload  : TThread;
    mStatus   : TJakoMemo;
    thRunning : Boolean;
    procedure LoadFonts;
    procedure UploadDataToOnlineLogs(where : TWhereToUpload);
  public
    SyncMsg    : String;
    SyncColor  : TColor;
    SyncUpdate : String;

    procedure UploadDataToHamQTH;
    procedure UploadDataToClubLog;
    procedure UploadDataToHrdLog;
    procedure UploadDataToAll;

    procedure SyncUploadInformation;
  end; 

type
  TUploadThread = class(TThread)
  protected
    procedure Execute; override;
  public
    WhereToUpload : TWhereToUpload;
  end;



var
  frmLogUploadStatus: TfrmLogUploadStatus;

implementation

uses dData, dUtils, uMyIni;

procedure TUploadThread.Execute;
const
  C_IS_NOT_ENABLED = 'Upload to %s is not enabled! Go to Preferences and change settings.';
var
  data : TStringList;
  err  : String;
  PError: PChar;
  msg : String;
  i : Integer = 1;
begin
  data := TStringList.Create;
  try
    FreeOnTerminate := True;
    frmLogUploadStatus.SyncMsg    := '';
    frmLogUploadStatus.SyncUpdate := '';
    frmLogUploadStatus.SyncColor  := dmLogUpload.GetLogUploadColor(WhereToUpload);

    case WhereToUpload of
      upHamQTH :  begin
                    if not cqrini.ReadBool('OnlineLog','HaUP',False) then
                    begin
                      frmLogUploadStatus.SyncMsg := Format(C_IS_NOT_ENABLED,['HamQTH']);
                      Synchronize(@frmLogUploadStatus.SyncUploadInformation);
                      exit
                    end
                  end;
      upClubLog : begin
                    if not cqrini.ReadBool('OnlineLog','ClUP',False) then
                    begin
                      frmLogUploadStatus.SyncMsg := Format(C_IS_NOT_ENABLED,['ClubLog']);
                      Synchronize(@frmLogUploadStatus.SyncUploadInformation);
                      exit
                    end
                  end;
      upHrdLog : begin
                    if not cqrini.ReadBool('OnlineLog','HrUP',False) then
                    begin
                      frmLogUploadStatus.SyncMsg := Format(C_IS_NOT_ENABLED,['HRDLog']);
                      Synchronize(@frmLogUploadStatus.SyncUploadInformation);
                      exit
                    end
                  end
    end; //case

    err :=  dmLogUpload.CheckUserUploadSettings(WhereToUpload);
    if (err<>'') then
    begin
      frmLogUploadStatus.SyncMsg := err;
      Synchronize(@frmLogUploadStatus.SyncUploadInformation);
      exit
    end;

    dmLogUpload.PrepareHamQTHUserData(data);
    Synchronize(@frmLogUploadStatus.SyncUploadInformation);
    Sleep(500)
  finally
    FreeAndNil(data);
    frmLogUploadStatus.thRunning := False
  end
end;

procedure TfrmLogUploadStatus.SyncUploadInformation;
var
  item : String;
  tmp  : LongInt;
  c    : TColor;
begin
  if (SyncUpdate<>'') then
  begin
    //cti_vetu(var te:string;var bpi,bpo:Tcolor;var pom:longint;kam:longint):boolean;
    mStatus.cti_vetu(item,c,c,tmp,mStatus.posledniveta);
    item := item + '...' + SyncUpdate;
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

