(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

// "A new version of CQRLOG is available" dialog and the worker thread that
// decides whether to show it.
//
// StartVersionCheck runs the GitHub query on a thread (uVersionCheck does
// the work) and hands the result to the main thread through Synchronize.
// Startup mode (Manual = False) stays silent unless a newer release exists
// and the user has not asked to skip that tag; manual mode (Help menu)
// always answers: the dialog, "you are up to date", or the error.

unit fNewVersion;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  LCLType, LCLIntf, uVersionCheck;

type

  { TfrmNewVersion }

  TfrmNewVersion = class(TForm)
    btnClose       : TButton;
    btnOpenRelease : TButton;
    chkSkipVersion : TCheckBox;
    lblInstalled   : TLabel;
    lblLatest      : TLabel;
    lblTitle       : TLabel;
    mBody          : TMemo;
    pnlBottom      : TPanel;
    pnlTop         : TPanel;
    procedure btnOpenReleaseClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    FInfo : TReleaseInfo;
  public
    procedure ShowRelease(const Info: TReleaseInfo);
  end;

  { TVersionCheckThread }

  TVersionCheckThread = class(TThread)
  private
    FInfo   : TReleaseInfo;
    FErrMsg : String;
    FFound  : Boolean;
    procedure ShowResult;   // main thread, via Synchronize
  protected
    procedure Execute; override;
  public
    Manual : Boolean;       // set before Start
  end;

// Fires a check on a background thread; the outcome is reported on the main
// thread later.  Manual = True is the Help menu, False the startup check.
procedure StartVersionCheck(Manual: Boolean);

implementation

{$R *.lfm}

uses
  dData, dUtils, uMyIni, uVersion;

{ TVersionCheckThread }

procedure TVersionCheckThread.Execute;
begin
  FFound  := False;
  FErrMsg := '';
  try
    FFound := FetchLatestRelease(FInfo, FErrMsg)
  except
    on E: Exception do
    begin
      FFound  := False;
      FErrMsg := E.Message
    end
  end;
  if dmData.DebugLevel >= 1 then
  begin
    if FFound then
      Writeln('Version check: latest ', FInfo.Tag, ' (', FInfo.PublishedAt,
              '), running ', RunningVersionString)
    else
      Writeln('Version check failed: ', FErrMsg)
  end;
  Synchronize(@ShowResult)
end;

procedure TVersionCheckThread.ShowResult;
var
  Frm : TfrmNewVersion;
begin
  if not FFound then
  begin
    if Manual then
      Application.MessageBox(PChar('Could not check for a new version.' + LineEnding +
                                   LineEnding + FErrMsg),
                             'Check for new version', mb_OK + mb_IconError);
    exit
  end;

  if not IsNewerThanRunning(FInfo.Major, FInfo.Minor, FInfo.Release) then
  begin
    if Manual then
      Application.MessageBox(PChar('You are running the latest version of CQRLOG (' +
                                   RunningVersionString + ').'),
                             'Check for new version', mb_OK + mb_IconInformation);
    exit
  end;

  if (not Manual) and (SkippedVersionTag = FInfo.Tag) then
    exit;   // the startup check honours "Don't show this version again"

  // No 'with' here: inside it FInfo would bind to the form's own
  // (empty) FInfo field, not to this thread's.
  Frm := TfrmNewVersion.Create(Application);
  try
    Frm.ShowRelease(FInfo);
    Frm.ShowModal
  finally
    Frm.Free
  end
end;

procedure StartVersionCheck(Manual: Boolean);
var
  Th : TVersionCheckThread;
begin
  Th := TVersionCheckThread.Create(True);
  Th.Manual := Manual;
  Th.FreeOnTerminate := True;
  Th.Start
end;

{ TfrmNewVersion }

procedure TfrmNewVersion.FormCreate(Sender: TObject);
begin
  dmUtils.LoadFontSettings(self);
  lblTitle.Font.Style := [fsBold];   // after LoadFontSettings, which resets child fonts
  Width  := cqrini.ReadInteger('NewVersion', 'Width',  Width);
  Height := cqrini.ReadInteger('NewVersion', 'Height', Height)
end;

procedure TfrmNewVersion.ShowRelease(const Info: TReleaseInfo);
begin
  FInfo := Info;
  lblLatest.Caption    := 'Latest version: ' + Info.Tag + '   (released ' + Info.PublishedAt + ')';
  lblInstalled.Caption := 'Installed version: ' + cVERSION + '   (' + cBUILD_DATE + ')';
  mBody.Text := Info.Body;
  chkSkipVersion.Checked := (SkippedVersionTag = Info.Tag)   // only ever true on a manual check
end;

procedure TfrmNewVersion.btnOpenReleaseClick(Sender: TObject);
begin
  // LCLIntf.OpenURL, not dmUtils.OpenWithDesktop: the latter runs a bare
  // 'open' through RunOnBackground, which only starts executables given
  // with a full path, so on macOS it silently does nothing.
  if FInfo.HtmlUrl <> '' then
    OpenURL(FInfo.HtmlUrl)
end;

procedure TfrmNewVersion.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  Skipped : String;
begin
  Skipped := SkippedVersionTag;
  if chkSkipVersion.Checked then
  begin
    if Skipped <> FInfo.Tag then
      SetSkippedVersionTag(FInfo.Tag)
  end
  else if Skipped = FInfo.Tag then
    SetSkippedVersionTag('');   // unticked on a manual check
  cqrini.WriteInteger('NewVersion', 'Width',  Width);
  cqrini.WriteInteger('NewVersion', 'Height', Height)
end;

end.
