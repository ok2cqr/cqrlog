unit fDbSqlSel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Buttons, LazFileUtils;

type

  { TfrmDbSqlSel }

  TfrmDbSqlSel = class(TForm)
    btnHelp: TSpeedButton;
    btnOK: TButton;
    edtPort: TEdit;
    edtIP: TEdit;
    edtUserName: TEdit;
    edtPassword: TEdit;
    gbLocalUser: TGroupBox;
    imLogo: TImage;
    lblError: TLabel;
    lblIp: TLabel;
    lblPort: TLabel;
    lblInfo: TLabel;
    lblUsername: TLabel;
    lblPass: TLabel;
    lblQuestion: TLabel;
    lblWelcome: TLabel;
    pnlWelcome: TPanel;
    pnlInfo: TPanel;
    rbFolder: TRadioButton;
    rbLocal: TRadioButton;
    rbExternal: TRadioButton;
    procedure btnHelpClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure edtIPExit(Sender: TObject);
    procedure edtPasswordExit(Sender: TObject);
    procedure edtPortExit(Sender: TObject);
    procedure edtUserNameExit(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure rbExternalChange(Sender: TObject);
    procedure rbFolderClick(Sender: TObject);
    procedure rbLocalChange(Sender: TObject);
  private
    procedure ChkValues;
    procedure MakeScript1;
    procedure MakeScript2;
    procedure ExecuteScript;

  public
    ip, port, user, pass: string;
    loc, rdy, Acon, Rmbr: boolean;
  end;

const
  C_PATH = '/bin:/usr/bin/:/usr/local/bin/:~/.local/bin:/sbin:/usr/sbin:/usr/local/sbin';
  C_HEIGHT = 230;

var
  frmDbSqlSel: TfrmDbSqlSel;

implementation

{ TfrmDbSqlSel }

uses fDBConnect, dUtils;

procedure TfrmDbSqlSel.rbLocalChange(Sender: TObject);
begin
  if rbLocal.Checked then
  begin
    btnOK.Enabled := True;
    lblError.Caption := '';
    lblError.Visible := False;
    gbLocalUser.Visible := True;
    frmDbSqlSel.Height := C_HEIGHT + gbLocalUser.Height + btnOK.Height;
    edtIp.ReadOnly := True;
    edtIp.Font.Color := clGray;
    edtport.ReadOnly := True;
    edtport.Font.Color := clGray;
    edtIP.Text := 'localhost';
    edtPort.Text := '3306';
    repaint;
    edtUsername.SetFocus;
    edtUsername.SelectAll;
  end
  else
    frmDbSqlSel.Height := C_HEIGHT;
end;

procedure TfrmDbSqlSel.rbExternalChange(Sender: TObject);
begin
  if rbExternal.Checked then
  begin
    btnOK.Enabled := True;
    lblError.Caption := '';
    lblError.Visible := False;
    gbLocalUser.Visible := True;
    frmDbSqlSel.Height := C_HEIGHT + gbLocalUser.Height + btnOK.Height;
    edtIp.ReadOnly := False;
    edtIp.Font.Color := clDefault;
    edtport.ReadOnly := False;
    edtport.Font.Color := clDefault;
    edtIP.Text := '';
    edtPort.Text := '3306';
    repaint;
    edtIP.SetFocus;
    edtIP.SelectAll;
  end
  else
    frmDbSqlSel.Height := C_HEIGHT;
end;

procedure TfrmDbSqlSel.rbFolderClick(Sender: TObject);
begin
  rbFolder.SetFocus;
  lblError.Caption := '';
  lblError.Visible := False;
  gbLocalUser.Visible := False;
  btnOK.Enabled := True;
end;

procedure TfrmDbSqlSel.MakeScript1;   //"create_cqr_user.sh"
var
  UsrHome: string;
  f: TextFile;
begin
  UsrHome := dmUtils.GetHomeDirectory;

  AssignFile(f, UsrHome + 'create_cqr_user.sh');
  rewrite(f);
  Writeln(f, '#!/bin/bash');
  Writeln(f);
  Writeln(f, 'echo -e "\nCreating user ' + user + '@localhost for CQRLOG use\n"');
  Writeln(f, 'sudo -p "Give user %u password for sudo: " mysql<<EOFSQL');
  Writeln(f);
  Writeln(f, 'CREATE USER IF NOT EXISTS ' + #$27 + user + #$27 + '@' + #$27 +
    'localhost' + #$27 + ' IDENTIFIED BY ' + #$27 + pass + #$27 + ';');
  Writeln(f, 'GRANT ALL PRIVILEGES ON *.* TO ' + #$27 + user + #$27 + '@' +
    #$27 + 'localhost' + #$27 + ';');
  Writeln(f, 'FLUSH PRIVILEGES;');
  Writeln(f, 'EOFSQL');
  Writeln(f);
  Writeln(f, 'status=$?');
  Writeln(f, '[ $status -eq 0 ] && echo -e "\nUser creation SUCCESS !"');
  Writeln(f, '[ $status -eq 0 ] && echo $status > /tmp/cqrSQLUsrCreate');
  Writeln(f, '[ $status -ne 0 ] && echo -e "\nUser creation FAILED !\n\nCheck error !"');
  Writeln(f, 'read -p "Press enter to continue"');
  Writeln(f, 'echo Done! > /tmp/cqrBashDone');
  Writeln(f, 'exit $status');
  closeFile(f);
  dmUtils.ExecuteCommand('chmod a+rwx ' + UsrHome + 'create_cqr_user.sh');
end;

procedure TfrmDbSqlSel.MakeScript2;   //"backup_all_cqr.sh"
var
  UsrHome: string;
  f: TextFile;
begin
  UsrHome := dmUtils.GetHomeDirectory;

  AssignFile(f, UsrHome + 'backup_all_cqr.sh');
  rewrite(f);
  Writeln(f, '#!/bin/bash');
  Writeln(f);
  Writeln(f, 'stamp=$(date +_%Y%m%d-%H%M)');
  Writeln(f, 'echo -e "\nStarted$stamp"');
  Writeln(f, 'echo -e "Creating common backup of all CQRLOG logs in database to /tmp/allcqrlogs$stamp.sql"');
  Writeln(f, '$(mysql -u' + user + ' -p' + pass + ' -B -N -h' + ip + ' -P' + port +
             ' -e " show databases like ' + #$27 + 'cqr%' + #$27 + '" |\');
  Writeln(f, 'xargs  echo -n mysqldump -q -h' + ip + ' -P' + port + ' -u' +
              user + ' -p' + pass + ' --databases) > /tmp/allcqrlogs$stamp.sql');

  Writeln(f, 'echo -e "Creating separate backups of each CQRLOG logXXX in database to /tmp/cqrlogXXX$stamp.sql(s)\n"');
  Writeln(f, 'mysql -u' + user + ' -p' + pass + ' -B -N -h' + ip + ' -P' + port +
             ' -e " show databases like ' + #$27 + 'cqr%' + #$27 + '" |\');
  Writeln(f, 'xargs -d\ | while read line; do if [[ $line != "" ]];then\');
  Writeln(f, ' echo "mysqldump -q -h' + ip + ' -P' + port + ' -u' +
              user + ' -p' + pass + ' $line > /tmp/$line$stamp.sql";fi;done > /tmp/sepsql.sh');
  Writeln(f, 'chmod a+x /tmp/sepsql.sh');
  Writeln(f, '/tmp/sepsql.sh');
  Writeln(f, 'rm /tmp/sepsql.sh');


  Writeln(f, 'echo -e "\nDone!\nCopy backup files to your safe place.\n'+
             'They will be erased from /tmp at next Linux start\n\n"');
  Writeln(f, 'echo "To restore all CQRLOG logs use command:"');
  Writeln(f, 'echo -e "mysql -h' + ip + ' -P' + port + ' -u' + user + ' -p' + pass +
             ' < /tmp/allcqrlogs$stamp.sql\n\n"');
  Writeln(f, 'echo "To restore single a log use command:"');
  Writeln(f, 'echo "mysql -h' + ip + ' -P' + port + ' -u' + user + ' -p' + pass +
             ' cqrlog001 < /tmp/cqrlog001$stamp.sql"');
  Writeln(f, 'echo -e "\nBe sure that both log numbers used in line are equal"');
  closeFile(f);
  dmUtils.ExecuteCommand('chmod a+rwx ' + UsrHome + 'backup_all_cqr.sh');
end;

procedure TfrmDbSqlSel.ExecuteScript;
var
  UsrHome, Terminal, msg: string;
  c: integer;
begin
  UsrHome := dmUtils.GetHomeDirectory;
  //try to find three well-known terminals
  Terminal := FileSearch('xterm', C_PATH, True);
  if Terminal = '' then
    Terminal := FileSearch('gnome-terminal', C_PATH, True);
  if Terminal = '' then
    Terminal := FileSearch('lxterminal', C_PATH, True);
  if Terminal = '' then
    ShowMessage('CQRLOG did not find command-line terminal from your system!')
  else
    dmUtils.ExecuteCommand(Terminal + ' -e ' + UsrHome + 'create_cqr_user.sh');

  c := 60;   //max timeout in seconds
  repeat   //we need this stupid wait because [poWaitOnExit] did not work with Mint 20 !
    begin
      sleep(1000);
      Application.ProcessMessages;
      Dec(c);
    end;
  until ((Terminal = '') or (c < 1) or (FileExists('/tmp/cqrBashDone')));

  if FileExists('/tmp/cqrSQLUsrCreate') then
  begin
    msg := 'It looks like SQL user addition went ok.' +
      LineEnding + 'You can press OK now.' + LineEnding + LineEnding;
  end
  else begin
    msg := 'If you did not see terminal and enter your password there'
      + LineEnding + 'then do this:' + LineEnding +
      'Open linux command-line terminal and type:' + LineEnding + UsrHome +
      'create_cqr_user.sh (and press enter)' + LineEnding +
      LineEnding + 'After that is done without errors close terminal and press OK here'
      + LineEnding + LineEnding;
  end;


  msg := msg + 'Backup of all CQRLOG SQL databases can be done at any '
    + LineEnding + 'time from command-line terminal by typing:'
    + LineEnding + UsrHome + 'backup_all_cqr.sh (and pressing enter)';

  ShowMessage(msg);
  Application.ProcessMessages;
end;

procedure TfrmDbSqlSel.btnOKClick(Sender: TObject);

begin
  btnOK.SetFocus;
  gbLocalUser.Visible := True;
  //these lines are needed for RPi graphics
  frmDbSqlSel.Height := C_HEIGHT + gbLocalUser.Height + btnOK.Height;
  //to show lblInfo ok in default selection !?!?!
  gbLocalUser.SendToBack;
  gbLocalUser.Visible := False;
  frmDbSqlSel.Height := C_HEIGHT + pnlInfo.Height;

  if rbExternal.Checked then
  begin
    //set info text and return value
    lblInfo.Caption := 'CQRLOG is connecting to SQL server and ' +
      LineEnding + 'creating a new log if needed. Please be patient!';
    pnlInfo.Visible := True;
    pnlInfo.BringToFront;
    pnlInfo.Repaint;
    ip := edtIp.Text;
    port := edtPort.Text;
    user := edtUsername.Text;
    pass := edtPassword.Text;
    loc := False;
    Acon := True;
    Rmbr := True;
    MakeScript2;
  end;
  if rbLocal.Checked then
  begin
    lblInfo.Caption := 'CQRLOG is connecting to SQL server and ' +
      LineEnding + 'creating a new log if needed. Please be patient!';
    pnlInfo.Visible := True;
    pnlInfo.BringToFront;
    pnlInfo.Repaint;
    ip := edtIp.Text;
    port := edtPort.Text;
    user := edtUsername.Text;
    pass := edtPassword.Text;
    loc := False;
    Acon := True;
    Rmbr := True;
    //create script for making sql user, save it and then exceute it
    //set values to database connect and exit
    MakeScript1;
    MakeScript2;
    ExecuteScript;
  end;

  btnOK.Visible := False;
  btnHelp.Visible := False;
  pnlInfo.Visible := True;
  pnlInfo.BringToFront;
  pnlInfo.Repaint;
  rdy := True;
  Application.ProcessMessages;
  sleep(4000);

  Close;
end;

procedure TfrmDbSqlSel.btnHelpClick(Sender: TObject);
var
  xdg: string;
  pathToHelp : string;
begin
  xdg := FileSearch('xdg-open', C_PATH, True);
  if xdg <> '' then
  begin
    pathToHelp := ExpandFileNameUTF8('..' + DirectorySeparator + 'share' + DirectorySeparator + 'cqrlog' + DirectorySeparator +
                                     'help' + DirectorySeparator + 'firsttime.html');

    dmUtils.RunOnBackground(xdg + ' ' + pathToHelp);
  end;
end;

procedure TfrmDbSqlSel.ChkValues;
begin
  btnOK.Enabled := True;
  lblError.Caption := '';
  lblError.Visible := False;
  if edtIP.Text = '' then
  begin
    btnOK.Enabled := False;
    lblError.Caption := 'IP address can not be empty !';
    lblError.Visible := True;
    exit;
  end;
  if edtPort.Text = '' then
  begin
    btnOK.Enabled := False;
    lblError.Caption := 'Port can not be empty !';
    lblError.Visible := True;
    exit;
  end;
  if length(edtUsername.Text) < 4 then
  begin
    btnOK.Enabled := False;
    lblError.Caption := 'Username must be at least 4 characters long !';
    lblError.Visible := True;
    exit;
  end;
  if edtPassword.Text = '' then
  begin
    btnOK.Enabled := False;
    lblError.Caption := 'Password can not be empty !';
    lblError.Visible := True;
    exit;
  end;
end;

procedure TfrmDbSqlSel.edtIPExit(Sender: TObject);
begin
  ChkValues;
end;

procedure TfrmDbSqlSel.edtPasswordExit(Sender: TObject);
begin
  ChkValues;
end;

procedure TfrmDbSqlSel.edtPortExit(Sender: TObject);
begin
  ChkValues;
end;

procedure TfrmDbSqlSel.edtUserNameExit(Sender: TObject);
begin
  ChkValues;
end;

procedure TfrmDbSqlSel.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  rdy := True;
end;

procedure TfrmDbSqlSel.FormCreate(Sender: TObject);
begin
  ip := 'localhost';
  port := '64000';
  user := 'cqrlog';
  pass := 'cqrlog';
  loc := True;
  rdy := False;
  Acon := False;
  Rmbr := False;
  frmDbSqlSel.Height := C_HEIGHT;
  lblError.Caption := '';
  lblError.Visible := False;
  DeleteFile('/tmp/cqrSQLUsrCreate');
  DeleteFile('/tmp/cqrBashDone');
end;




initialization
  {$I fDbSqlSel.lrs}

end.
