unit fRebuildMembStat;

{$mode objfpc}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, LCLType;

type

  { TfrmRebuildMembStat }

  TfrmRebuildMembStat = class(TForm)
    Bevel1: TBevel;
    btnStart: TButton;
    btnCancel: TButton;
    chkIgnoreChanges : TCheckBox;
    chkRebClub1: TCheckBox;
    chkRebClub2: TCheckBox;
    chkRebClub3: TCheckBox;
    chkRebClub4: TCheckBox;
    chkRebClub5: TCheckBox;
    edtSince1: TEdit;
    edtSince2: TEdit;
    edtSince3: TEdit;
    edtSince4: TEdit;
    edtSince5: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    lblInfo: TLabel;
    lblDone1: TLabel;
    lblDone2: TLabel;
    lblDone3: TLabel;
    lblDone4: TLabel;
    lblDone5: TLabel;
    procedure btnStartClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmRebuildMembStat: TfrmRebuildMembStat;

implementation
{$R *.lfm}

{ TfrmRebuildMembStat }
uses dUtils, dData, uMyIni, dLogUpload, dMembership;


procedure TfrmRebuildMembStat.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmRebuildMembStat);
  chkRebClub1.Caption := dmMembership.Club1.LongName;
  chkRebClub2.Caption := dmMembership.Club2.LongName;
  chkRebClub3.Caption := dmMembership.Club3.LongName;
  chkRebClub4.Caption := dmMembership.Club4.LongName;
  chkRebClub5.Caption := dmMembership.Club5.LongName;

  edtSince1.Text := dmMembership.Club1.DateFrom;
  edtSince2.Text := dmMembership.Club2.DateFrom;
  edtSince3.Text := dmMembership.Club3.DateFrom;
  edtSince4.Text := dmMembership.Club4.DateFrom;
  edtSince5.Text := dmMembership.Club5.DateFrom;

  chkRebClub1.Enabled := chkRebClub1.Caption<>'';
  edtSince1.Enabled   := chkRebClub1.Caption<>'';

  chkRebClub2.Enabled := chkRebClub2.Caption<>'';
  edtSince2.Enabled   := chkRebClub2.Caption<>'';

  chkRebClub3.Enabled := chkRebClub3.Caption<>'';
  edtSince3.Enabled   := chkRebClub3.Caption<>'';

  chkRebClub4.Enabled := chkRebClub4.Caption<>'';
  edtSince4.Enabled   := chkRebClub4.Caption<>'';

  chkRebClub5.Enabled := chkRebClub5.Caption<>'';
  edtSince5.Enabled   := chkRebClub5.Caption<>'';

  chkIgnoreChanges.Checked := cqrini.ReadBool('Clubs','NotUpload',True)
end;

procedure TfrmRebuildMembStat.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmRebuildMembStat)
end;

procedure TfrmRebuildMembStat.btnStartClick(Sender: TObject);
{
 %l - long club name
 %s - short club name
 %n - club number
 %c - callsign
}
  function StoreText(cl : TClub) : String;
  begin
    Result := QuotedStr(cl.StoreText);
    Result := StringReplace(Result,'%l',cl.LongName,[rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result,'%s',cl.Name,[rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result,'%n',QuotedStr(',c.club_nr,'),[rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result,'%c',QuotedStr(',q.callsign,'),[rfReplaceAll, rfIgnoreCase]);
    if (Pos(',c.club_nr,',Result) > 0) or (Pos(',q.callsign,',Result) > 0) then
      Result := 'CONCAT('+Result+')'
  end;

  procedure UpdateClub(club : TClub;nr,FromDate : String);
  begin
    dmData.Q.SQL.Text := 'update cqrlog_main set club_nr'+nr+' = '+QuotedStr('');
    dmData.Q.ExecSQL;
    dmData.Q.SQL.Clear;
    dmData.Q.SQL.Add('update cqrlog_main q left join club'+nr+' c on q.'+Club.MainFieled+
                     '= c.'+Club.ClubField);
    dmData.Q.SQL.Add(' and c.fromdate <= q.qsodate and c.todate >= q.qsodate');
    dmData.Q.SQL.Add('set q.club_nr'+nr+' = c.club_nr');
    dmData.Q.SQL.Add('where qsodate >= '+QuotedStr(FromDate));
    if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
    dmData.Q.ExecSQL;

    dmData.Q.SQL.Clear;
    if (Club.StoreField <> '') and (Club.StoreText <> '') then
    begin
      dmData.Q.SQL.Add('update cqrlog_main q left join club'+nr+' c on q.'+Club.MainFieled+
                       '= c.'+Club.ClubField);
      dmData.Q.SQL.Add(' and c.fromdate <= q.qsodate and c.todate >= q.qsodate');
      dmData.Q.SQL.Add(' set '+Club.StoreField+'='+StoreText(Club));
      dmData.Q.SQL.Add('where qsodate >= '+QuotedStr(FromDate));
      dmData.Q.SQL.Add(' and '+Club.StoreField+'='+QuotedStr(''));
      if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
      dmData.Q.ExecSQL
    end
  end;

var
  e : Boolean = False;
begin
  cqrini.WriteBool('Clubs','NotUpload',chkIgnoreChanges.Checked);

  if dmData.trQ.Active then
    dmData.trQ.Rollback;
  dmData.Q.SQL.Clear;
  lblDone1.Visible := False;
  lblDone2.Visible := False;
  lblDone3.Visible := False;
  lblDone4.Visible := False;
  lblDone5.Visible := False;

  Cursor := crHourGlass;
  dmData.trQ.StartTransaction;
  lblInfo.Caption := 'Working ...';
  Application.ProcessMessages;
  try try
    if chkIgnoreChanges.Checked and dmLogUpload.LogUploadEnabled then
      dmLogUpload.DisableOnlineLogSupport;

    if chkRebClub1.Checked then
    begin
      UpdateClub(dmMembership.Club1,'1',edtSince1.Text);
      lblDone1.Visible := True;
      Application.ProcessMessages
    end;

    if chkRebClub2.Checked then
    begin
      UpdateClub(dmMembership.Club2,'2',edtSince2.Text);
      lblDone2.Visible := True;
      Application.ProcessMessages
    end;

    if chkRebClub3.Checked then
    begin
      UpdateClub(dmMembership.Club3,'3',edtSince3.Text);
      lblDone3.Visible := True;
      Application.ProcessMessages
    end;

    if chkRebClub4.Checked then
    begin
      UpdateClub(dmMembership.Club4,'4',edtSince4.Text);
      lblDone4.Visible := True;
      Application.ProcessMessages
    end;

    if chkRebClub5.Checked then
    begin
      UpdateClub(dmMembership.Club5,'5',edtSince5.Text);
      lblDone5.Visible := True;
      Application.ProcessMessages
    end
  except
    on ex : Exception do
    begin
      Cursor := crDefault;
      Application.MessageBox(PChar(ex.Message),'Error...', mb_OK + mb_IconError);
      dmData.trQ.Rollback;
      e := True;
      lblDone1.Visible := False;
      lblDone2.Visible := False;
      lblDone3.Visible := False;
      lblDone4.Visible := False;
      lblDone5.Visible := False
     end
  end
  finally
    Cursor := crDefault;
    if not e then
      dmData.trQ.Commit;

    if chkIgnoreChanges.Checked and dmLogUpload.LogUploadEnabled then
      dmLogUpload.EnableOnlineLogSupport(False);
    lblInfo.Caption := 'Done ...'
  end
end;


end.

