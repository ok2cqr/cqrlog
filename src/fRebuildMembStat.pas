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
    lblClub1: TLabel;
    lblClub2: TLabel;
    lblClub3: TLabel;
    lblClub4: TLabel;
    lblClub5: TLabel;
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

{ TfrmRebuildMembStat }
uses dUtils, dData;


procedure TfrmRebuildMembStat.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmRebuildMembStat);
  lblClub1.Caption := dmData.Club1.LongName;
  lblClub2.Caption := dmData.Club2.LongName;
  lblClub3.Caption := dmData.Club3.LongName;
  lblClub4.Caption := dmData.Club4.LongName;
  lblClub5.Caption := dmData.Club5.LongName;

  edtSince1.Text := dmData.Club1.DateFrom;
  edtSince2.Text := dmData.Club2.DateFrom;
  edtSince3.Text := dmData.Club3.DateFrom;
  edtSince4.Text := dmData.Club4.DateFrom;
  edtSince5.Text := dmData.Club5.DateFrom;

  if lblClub1.Caption = '' then
  begin
    chkRebClub1.Enabled := False;
    edtSince1.Enabled   := False
  end;

  if lblClub2.Caption = '' then
  begin
    chkRebClub2.Enabled := False;
    edtSince2.Enabled   := False
  end;

  if lblClub3.Caption = '' then
  begin
    chkRebClub3.Enabled := False;
    edtSince3.Enabled   := False
  end;

  if lblClub4.Caption = '' then
  begin
    chkRebClub4.Enabled := False;
    edtSince4.Enabled   := False
  end;

  if lblClub5.Caption = '' then
  begin
    chkRebClub5.Enabled := False;
    edtSince5.Enabled   := False
  end
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
    if chkRebClub1.Checked then
    begin
      UpdateClub(dmData.Club1,'1',edtSince1.Text);
      lblDone1.Visible := True;
      Application.ProcessMessages
    end;

    if chkRebClub2.Checked then
    begin
      UpdateClub(dmData.Club2,'2',edtSince2.Text);
      lblDone2.Visible := True;
      Application.ProcessMessages
    end;

    if chkRebClub3.Checked then
    begin
      UpdateClub(dmData.Club3,'3',edtSince3.Text);
      lblDone3.Visible := True;
      Application.ProcessMessages
    end;

    if chkRebClub4.Checked then
    begin
      UpdateClub(dmData.Club4,'4',edtSince4.Text);
      lblDone4.Visible := True;
      Application.ProcessMessages
    end;

    if chkRebClub5.Checked then
    begin
      UpdateClub(dmData.Club5,'5',edtSince5.Text);
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
    lblInfo.Caption := 'Done ...'
  end
end;

initialization
  {$I fRebuildMembStat.lrs}

end.

