unit fLogList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, FileCtrl, ShellCtrls, lcltype;

type

  { TfrmLogList }

  TfrmLogList = class(TForm)
    btnNew: TButton;
    btnDeleteLog: TButton;
    btnEditLog: TButton;
    btnOpen: TButton;
    btnCancel: TButton;
    lbFiles: TListBox;
    Panel1: TPanel;
    pnlPath: TPanel;
    procedure btnCancelClick(Sender: TObject);
    procedure btnDeleteLogClick(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure lbFilesDblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lbFilesKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmLogList: TfrmLogList;

implementation

{ TfrmLogList }
uses dData, fTestMain, fNewTestLog, dUtils, uMyIni;

{ TfrmLogList }

procedure TfrmLogList.FormShow(Sender: TObject);
begin
  dmUtils.GetFileList(lbFiles);
  lbFiles.Selected[0] := True;
  pnlPath.Caption := dmData.ContestDataDir
end;

procedure TfrmLogList.lbFilesKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = VK_RETURN then
    lbFilesDblClick(nil)
end;

procedure TfrmLogList.btnCancelClick(Sender: TObject);
begin
  if dmData.ContestDataFile = '' then
    frmTestMain.DisableAll;
  ModalResult := mrCancel
end;

procedure TfrmLogList.btnDeleteLogClick(Sender: TObject);
begin
  if lbFiles.Count = 0 then
    exit;
end;

procedure TfrmLogList.btnNewClick(Sender: TObject);
//var
//  contest : String;
begin
 {$IFDEF CONTEST}
  with TfrmNewLog.Create(self) do
  try
    ShowModal;
    if ModalResult = mrOK then
    begin
      contest := StringReplace(edtLogName.Text,' ','_',[rfReplaceAll, rfIgnoreCase]);
      dmData.ContestDataDir := dmData.ContestDataDir+contest+'/';
      if not CreateDirUTF8(dmData.ContestDataDir) then
      begin
        Application.MessageBox(PChar('Could not create directory '+dmData.ContestDataDir),'Error ...',mb_ok+mb_IconError);
        exit
      end;
      if dmData.tstini <> nil then
        FreeAndNil(dmData.tstini);
      dmData.tstini := TMyIni.Create(dmData.ContestDataDir+contest+'.cqr');
      dmData.CreateContestDatabase(dmData.ContestDataDir+contest);
      dmData.tstini.WriteString('Contest','LogName',edtLogName.Text);
      dmData.tstini.WriteString('Contest','Name',cmbContest.Text);
      dmData.tstini.WriteString('Basic','Call',edtCall.Text);
      dmData.tstini.WriteString('Basic','Country',edtCountry.Text);
      dmData.tstini.WriteString('Basic','Gird',edtGrid.Text);
      dmData.tstini.WriteString('Basic','Name',edtName.Text);
      dmData.tstini.WriteString('Basic','QTH',edtQTH.Text);
      dmData.tstini.WriteString('Basic','Section',edtSection.Text);
      dmData.tstini.WriteString('Basic','State',edtState.Text);
      dmData.tstini.WriteString('Basic','Zone',edtZone.Text);
      dmData.tstini.WriteString('Basic','IOTA',edtIOTA.Text);
      dmData.tstini.WriteString('Details','Exch1',cmbExch1.Text);
      dmData.tstini.WriteString('Details','Exch2',cmbExch2.Text);
      dmData.tstini.WriteString('Details','Mult1',cmbMult1.Text);
      dmData.tstini.WriteString('Details','Mult2',cmbMult1.Text);
      dmData.tstini.WriteBool('Details','WARC',chkWARC.Checked);

      dmData.tstini.WriteBool('Columns','Date',chkDate.Checked);
      dmData.tstini.WriteBool('Columns','time_on',chkTimeOn.Checked);
      dmData.tstini.WriteBool('Columns','CallSign',chkCallSign.Checked);
      dmData.tstini.WriteBool('Columns','Mode',chkMode.Checked);
      dmData.tstini.WriteBool('Columns','Freq',chkFreq.Checked);
      dmData.tstini.WriteBool('Columns','RST_S',chkRST_S.Checked);
      dmData.tstini.WriteBool('Columns','RST_R',chkRST_R.Checked);
      dmData.tstini.WriteBool('Columns','Name',chkName.Checked);
      dmData.tstini.WriteBool('Columns','QTH',chkQTH.Checked);
      dmData.tstini.WriteBool('Columns','IOTA',chkIOTA.Checked);
      dmData.tstini.WriteBool('Columns','DXCC',chkDXCC.Checked);
      dmData.tstini.WriteBool('Columns','WAZ',chkWAZ.Checked);
      dmData.tstini.WriteBool('Columns','ITU',chkITU.Checked);
      dmData.tstini.WriteBool('Columns','State',chkState.Checked);
      dmData.tstini.WriteBool('Columns','Cont',chkCont.Checked);
      dmData.tstini.WriteBool('Columns','QSONR',chkQSONR.Checked);
      dmData.tstini.WriteBool('Columns','Exch1',chkExch1.Checked);
      dmData.tstini.WriteBool('Columns','Exch2',chkExch2.Checked);
      dmData.tstini.WriteBool('Columns','Mult1',chkMult1.Checked);
      dmData.tstini.WriteBool('Columns','Mult2',chkMult2.Checked); //points,band, prefix
      dmData.tstini.WriteBool('Columns','Points',chkPoints.Checked);
      dmData.tstini.WriteBool('Columns','Band',chkBand.Checked);
      dmData.tstini.WriteBool('Columns','Prefix',chkWPX.Checked);
      dmData.tstini.WriteBool('Columns','Power',chkPower.Checked);

      dmData.tstini.WriteString('CW','F1','CQ ++TEST-- %mc %mc ++TEST--');
      dmData.tstini.WriteString('CW','CapF1','F1 - CQ CQ');
      dmData.tstini.WriteString('CW','F2','DE %mc');
      dmData.tstini.WriteString('CW','CapF2','F2 - DE');
      dmData.tstini.WriteString('CW','F3','++5NN-- %nr');
      dmData.tstini.WriteString('CW','CapF3','F3 - 5NN NR');
      dmData.tstini.WriteString('CW','F4','--%nr %nr++');
      dmData.tstini.WriteString('CW','CapF4','F4 - NR NR');
      dmData.tstini.WriteString('CW','F5','%c');
      dmData.tstini.WriteString('CW','CapF5','F5 - His call');
      dmData.tstini.WriteString('CW','F6','%c ++5NN-- %nr');
      dmData.tstini.WriteString('CW','CapF6','F6 - Call+RST+NR');
      dmData.tstini.WriteString('CW','F7','SRI QSO B4');
      dmData.tstini.WriteString('CW','CapF7','F7 - QSO B4');
      dmData.tstini.WriteString('CW','F8','AGN');
      dmData.tstini.WriteString('CW','CapF8','F8 - AGN');
      dmData.tstini.WriteString('CW','F9','?');
      dmData.tstini.WriteString('CW','CapF9','F9 - ?');
      dmData.tstini.WriteString('CW','F10','TU');
      dmData.tstini.WriteString('CW','CapF10','F10 - TU');

      dmData.tstini.WriteString('CW','SPF1','%mc');
      dmData.tstini.WriteString('CW','SPCapF1','F1 - My call');
      dmData.tstini.WriteString('CW','SPF2','5NN %nr');
      dmData.tstini.WriteString('CW','SPCapF2','F2 5NN NR');
      dmData.tstini.WriteString('CW','SPF3','5NN');
      dmData.tstini.WriteString('CW','SPCapF3','F3 - 5NN');
      dmData.tstini.WriteString('CW','SPF4','--%nr++');
      dmData.tstini.WriteString('CW','SPCapF4','F4 - NR');
      dmData.tstini.WriteString('CW','SPF5','DE %mc 5NN %nr');
      dmData.tstini.WriteString('CW','SPCapF5','DE my call 5NN NRl');

      dmData.tstini.WriteString('CW','SPF7','TU 5NN --%nr++');
      dmData.tstini.WriteString('CW','SPCapF7','TU 5NN NR');
      dmData.tstini.WriteString('CW','SPF8','E E');
      dmData.tstini.WriteString('CW','SPCapF8','F8 - E E');
      dmData.tstini.WriteString('CW','SPF9','?');
      dmData.tstini.WriteString('CW','SPCapF9','F9 - ?');

      dmData.tstini.WriteString('CW','SPF6','');
      dmData.tstini.WriteString('CW','SPCapF6','');
      dmData.tstini.WriteString('CW','SPF10','');
      dmData.tstini.WriteString('CW','SPCapF10','');

      dmData.tstini.SaveToDisk
    end;
    dmUtils.GetFileList(lbFiles);
    lbFiles.Selected[0] := True;
    pnlPath.Caption := dmData.ContestDataDir
  finally
    dmData.tstini.Free;
    Free
  end
  {$ENDIF}
end;

procedure TfrmLogList.btnOpenClick(Sender: TObject);
//var
//  Filename : String = '';
begin
  {$IFDEF CONTEST}
  if (lbFiles.Count = 0)  then
    exit;
  FileName := lbFiles.Items.Strings[lbFiles.ItemIndex];
  if not FileExistsUTF8(dmData.ContestDataDir + FileName) then
    exit;// we dont have cqr configuration file in this directory

  // we have cqr file but not database, so we must create it
  if not FileExistsUTF8(dmData.ContestDataDir + ExtractFileNameWithoutExt(FileName)+'.fdb') then
    dmData.CreateContestDatabase(dmData.ContestDataDir+ExtractFileNameWithoutExt(FileName));
  //just open existing database
  if dmData.OpenContestDatabase(ExtractFileNameWithoutExt(FileName)+'.fdb') then
  begin
    dmData.tstini := TMyIni.Create(dmData.ContestDataDir+Filename);
    ModalResult := mrOK
  end
  {$ENDIF}
end;

procedure TfrmLogList.lbFilesDblClick(Sender: TObject);
var
  dir : String = '';
begin
  dir := lbFiles.Items.Strings[lbFiles.ItemIndex];
  Writeln(lbFiles.Items.Strings[lbFiles.ItemIndex]);
  if Pos('[',dir) > 0 then
  begin
    dir := copy(dir,2,Length(dir)-2);
    dir := dmData.ContestDataDir+dir;
    Writeln('dir:',dir);
    dir := ExpandFileNameUTF8(dir)+'/';
    Writeln('dir:',dir);
    if DirectoryExistsUTF8(dir) then
     dmData.ContestDataDir := dir;
    dmUtils.GetFileList(lbFiles);
    lbFiles.Selected[0] := True;
    pnlPath.Caption := dmData.ContestDataDir
  end;
  if dir <> '' then
  begin //opening CQR file with double click
    btnOpen.Click
  end;
end;

initialization
  {$I fLogList.lrs}

end.

