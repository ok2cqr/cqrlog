unit fDatabaseUpdate;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ExtCtrls, StdCtrls, httpsend, inifiles, process, lcltype, uInternalConnection;

type

  { TfrmDatabaseUpdate }

  TfrmDatabaseUpdate = class(TForm)
    btnCancel        : TButton;
    pnlQRZ           : TPanel;
    tmrQRZ           : TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure tmrQRZTimer(Sender: TObject);
  private
    found             : boolean; //found interrupted previous update's last id
    procedure QRZupdate;
  public
    id_cqrlog_main    : LongInt;
    Selected          : boolean;
    NameFromLog       : Boolean;
    procedure SynCallBook;
  end;

type
  // Runs on a connection of its own (like the LoTW and eQSL import
  // threads): the main thread keeps its message loop going while this
  // runs, so nothing here may touch dmData's cursors or the dSql* modules'
  // ones.  The rows to update are read once into a list of ids, each QSO
  // is then reread, looked up on the web and updated on that connection.
  TQRZThread = class(TThread)
  private
    FConn : TInternalConnection;
  protected
    procedure Execute; override;
  end;


var
  frmDatabaseUpdate: TfrmDatabaseUpdate;

implementation
{$R *.lfm}

{ TfrmDatabaseUpdate }
uses dUtils, dData, uMyIni, fMain, dSqlQso, uDbUtils;

var
  CanCancelAtStart  : boolean;
  CancelUpdate: boolean;
  CloseW:  boolean;

  c_callsign  : String;
  c_nick      : String;
  c_qth       : String;
  c_address   : String;
  c_zip       : String;
  c_grid      : String;
  c_state     : String;
  c_county    : String;
  c_qsl       : String;
  c_iota      : String;
  c_ErrMsg    : String;
  c_SyncText  : String;
  c_waz       : String;
  c_itu       : String;
  c_dok       : String;
  c_running   : Boolean = False;

procedure TQRZThread.Execute;
var
  dbCall    : string = '';
  dbName    : string = '';
  dbQTH     : string = '';
  dbQSLVia  : string = '';
  dbCounty  : string = '';
  dbAward   : string = '';
  dbDXCC    : string = '';
  dbGrid    : string = '';
  dbId      : int64 = 0;
  dbState   : string = '';
  StoreTo   : string = '';
  dbRemQSO  : string = '';
  dbIota    : String = '';
  dbWAZ     : String = '';
  dbITU     : String = '';
  IgnoreQRZ : boolean = False;
  MvToRem   : boolean = True;
  County    : String;
  Ids       : array of LongInt;
  Count     : Integer = 0;
  i         : Integer;

  //The QSOs the main window picked, by id, on this thread's connection; when
  //a cancelled update is resumed, from the QSO it stopped at (QRZupdate has
  //checked that id is in the selection).
  procedure CollectIds;
  var
    StartId : LongInt;
    Skip    : Boolean;
  begin
    StartId := frmDatabaseUpdate.id_cqrlog_main;
    Skip    := StartId > -1;
    FConn.Q.Close;
    FConn.Q.SQL.Text := dmData.qCallBook.SQL.Text;
    FConn.Q.Open;
    try
      while not FConn.Q.Eof do
      begin
        if Skip and (FConn.Q.FieldByName('id_cqrlog_main').AsInteger = StartId) then
          Skip := False;
        if not Skip then
        begin
          if Count = Length(Ids) then
            SetLength(Ids, Count + 1024);
          Ids[Count] := FConn.Q.FieldByName('id_cqrlog_main').AsInteger;
          inc(Count)
        end;
        FConn.Q.Next
      end
    finally
      FConn.Q.Close
    end
  end;

  procedure DoUpgrade(const Id : LongInt);
  begin
    FConn.Q.Close;
    FConn.Q.SQL.Text := dmSqlQso.SqlQsosByIds(IntToStr(Id));
    FConn.Q.Open;
    if FConn.Q.Eof then //deleted meanwhile
    begin
      FConn.Q.Close;
      exit
    end;
    dbCall   := FConn.Q.FieldByName('callsign').AsString;
    dbName   := FConn.Q.FieldByName('name').AsString;
    dbQTH    := FConn.Q.FieldByName('qth').AsString;
    dbQSLVia := FConn.Q.FieldByName('qsl_via').AsString;
    dbCounty := FConn.Q.FieldByName('county').AsString;
    dbAward  := FConn.Q.FieldByName('award').AsString;
    dbId     := FConn.Q.FieldByName('id_cqrlog_main').AsInteger;
    dbState  := FConn.Q.FieldByName('state').AsString;
    dbRemQSO := FConn.Q.FieldByName('remarks').AsString;
    dbGrid   := FConn.Q.FieldByName('loc').AsString;
    dbIota   := FConn.Q.FieldByName('iota').AsString;
    dbWAZ    := FConn.Q.FieldByName('waz').AsString;
    dbITU    := FConn.Q.FieldByName('itu').AsString;
    FConn.Q.Close;

    c_nick    := '';
    c_qth     := '';
    c_address := '';
    c_zip     := '';
    c_grid    := '';
    c_state   := '';
    c_county  := '';
    c_qsl     := '';
    c_waz     := '';
    c_itu     := '';
    c_dok     := '';
    c_ErrMsg  := '';

    if frmDatabaseUpdate.NameFromLog then
    begin
      FConn.Q.SQL.Text := dmSqlQso.SqlLastNameForCall(dbCall);
      if dmData.DebugLevel>=1 then Writeln(FConn.Q.SQL.Text);
      FConn.Q.Open;
      dbName := FConn.Q.Fields[2].AsString;
      FConn.Q.Close
    end;

    if dmData.DebugLevel >= 1 then
    begin
      Writeln('----');
      Writeln('dbCall:   ', dbCall);
      Writeln('dbName:   ', dbName);
      Writeln('dbQTH:    ', dbQTH);
      Writeln('dbQSLVIA: ', dbQSLVia);
      Writeln('dbAward:  ', trim(dbAward));
      Writeln('County:   ', c_county);
      Writeln('dbCounty: ', dbCounty);
      Writeln('dbState:  ', dbState);
      Writeln('dbRemQSO: ', dbRemQSO);
      Writeln('dbGrid:   ', dbGrid);
      Writeln('dbIota:   ', dbIota);
      Writeln('----');
    end;

    if CancelUpdate then
    begin
      //remember where to resume; this QSO is not touched
      cqrini.WriteInteger('CallBook', 'LastId', dbId);
      exit
    end;

    c_ErrMsg   := '';
    c_SyncText := dbCall;
    Synchronize(@frmDatabaseUpdate.SynCallBook);
    c_callsign := dmUtils.GetIDCall(dbCall);
    dmUtils.GetCallBookData(c_callsign,c_nick,c_qth,c_address,c_zip,c_grid,c_state,c_county,c_qsl,c_iota,c_waz,c_itu,c_dok,c_ErrMsg);

    if c_ErrMsg <> '' then
    begin
      Writeln(c_ErrMsg)
    end;

    if (dbQTH = '') then
      dbQTH := c_qth;

    if (dbState = '') and (c_state <> '') then
    begin
      dbState := dmUtils.GetShortState(c_state);
      if (dbCounty = '') and (c_county <> '') then
        dbCounty := dbState + ',' + c_county;
    end;
    //After ARRL DX we have dbState field filled but not county
    if (dbState <> '') and (dbCounty = '') and (c_state <> '') then
      dbCounty := dmUtils.GetShortState(c_state)+','+c_county;

    if (dbGrid = '') and dmUtils.IsLocOK(c_grid) then
      dbGrid := c_grid;

    if (dbIota = '') and dmUtils.IsIOTAOK(c_iota) then
      dbIota := c_iota;

    if c_zip <> '' then
    begin
      County := dmData.FindCounty1(c_zip, dbDXCC, StoreTo, FConn.Q);
      if County <> '' then
      begin
        if (StoreTo = 'county') and (dbCounty = '') then
          dbCounty := County
        else if (StoreTo = 'QTH') and (dbQTH = '') then
          dbQTH := County
        else if (StoreTo = 'award') and (dbAward = '') then
          dbAward := County
        else if (StoreTo = 'state') and (dbState = '') then
          dbState := County;
      end;

      County := dmData.FindCounty2(c_zip, dbDXCC, StoreTo, FConn.Q);
      if County <> '' then
      begin
        if (StoreTo = 'county') and (dbCounty = '') then
          dbCounty := County
        else if (StoreTo = 'QTH') and (dbQTH = '') then
          dbQTH := County
        else if (StoreTo = 'award') and (dbAward = '') then
          dbAward := County
        else if (StoreTo = 'state') and (dbState = '') then
          dbState := County;
      end;

      County := dmData.FindCounty3(c_zip, dbDXCC, StoreTo, FConn.Q);
      if County <> '' then
      begin
        if (StoreTo = 'county') and (dbCounty = '') then
          dbCounty := County
        else if (StoreTo = 'QTH') and (dbQTH = '') then
          dbQTH := County
        else if (StoreTo = 'award') and (dbAward = '') then
          dbAward := County
        else if (StoreTo = 'state') and (dbState = '') then
          dbState := County;
      end;
    end;
    if dbName = '' then
      dbName := c_nick;

    if (dbQSLVia = '') and (not IgnoreQRZ) then
    begin
      dbRemQSO := Trim(dbRemQSO);
      c_qsl    := dmUtils.GetQSLVia(c_qsl);
      c_qsl    := Trim(c_qsl);
      if dmUtils.IsQSLViaValid(c_qsl) then
        dbQSLVia := dmUtils.CallTrim(c_qsl)
      else
      begin
        if c_qsl <> '' then
        begin
          if MvToRem then
            if dbRemQSO = '' then
              dbRemQSO := c_qsl
            else
              dbRemQSO := dbRemQSO + ', ' + c_qsl
        end
      end
    end;

    dbName   := copy(dbName, 1, 40);
    dbQTH    := copy(dbQTH, 1, 60);
    dbQSLVia := copy(dbQSLVia, 1, 30);
    dbAward  := copy(dbAward, 1, 50);
    dbCounty := copy(dbCounty, 1, 30);
    dbState  := copy(dbState, 1, 4);
    dbRemQSO := copy(dbRemQSO, 1, 200);

    if (c_waz<>'') then
      dbWAZ := c_waz;

    if (c_itu<>'') then
      dbITU := c_itu;

    FConn.Q.SQL.Text := dmSqlQso.SqlUpdateQsoFromCallbook(dbName, dbQTH, dbQSLVia, dbCounty, dbAward, dbState,
                                                          dbRemQSO, dbIota, dbWAZ, dbITU, dbId);
    if dmData.DebugLevel >= 1 then
      Writeln(FConn.Q.SQL.Text);
    FConn.Q.ExecSQL;
    FConn.T.CommitRetaining
  end;

begin
  FreeOnTerminate:= True;
  c_running := True;
  FConn := nil;
  try try
    FConn := GetNewInternalConnection();
    c_nick     := '';
    c_qth      := '';
    c_address  := '';
    c_zip      := '';
    c_grid     := '';
    c_state    := '';
    c_county   := '';
    c_qsl      := '';
    c_ErrMsg   := '';
    IgnoreQRZ  := cqrini.ReadBool('NewQSO', 'IgnoreQRZ', False);
    MvToRem    := cqrini.ReadBool('NewQSO', 'MvToRem', True);
    c_SyncText := 'Working ...';
    Synchronize(@frmDatabaseUpdate.SynCallBook);
    CollectIds;
    i := 0;
    while (i < Count) and not CancelUpdate do
    begin
      DoUpgrade(Ids[i]);
      Sleep(1000);
      inc(i)
    end;
    FConn.T.Commit
  except
    on E : Exception do
      Writeln('Callbook update: ', E.Message)
  end
  finally
    if (FConn <> nil) and FConn.T.Active then
      FConn.T.Rollback;
    FreeAndNil(FConn);
    CloseW := True;
    Synchronize(@frmDatabaseUpdate.SynCallBook);
    c_running := False
  end
end;

procedure TfrmDatabaseUpdate.FormCreate(Sender: TObject);
begin
  c_running := False;
  found:=false;
end;

procedure TfrmDatabaseUpdate.FormDestroy(Sender: TObject);
begin
  dmData.qCallBook.Close;
  dmData.qCallBook.SQL.Clear;
end;

procedure TfrmDatabaseUpdate.FormShow(Sender: TObject);
begin
  CloseW := False;
  CancelUpdate := False;
  CanCancelAtStart:=false;
  dmUtils.LoadFontSettings(self);
  // I have to do this horrible workaround because sometimes window after show
  // doesn't get focus. Why??
  if cqrini.ReadBool('Callbook','HamQTH',True) then
    Caption := 'Updating data from HamQTH.com'
  else
    Caption := 'Updating data from qrz.com';

   if Selected then
       pnlQRZ.Caption := 'Updating selected QSOs'
      else
        if dmData.IsFilter then
          pnlQRZ.Caption := 'Updating filtered QSOs'
         else
             Begin
              pnlQRZ.Caption := 'Really update ALL '+IntToStr(dmData.GetQSOCount)+' QSOs?';
              tmrQRZ.Interval:=5000;
              CanCancelAtStart:=True;
             end;
  pnlQRZ.Repaint;
  tmrQRZ.Enabled := True;
end;

procedure TfrmDatabaseUpdate.btnCancelClick(Sender: TObject);
begin
  if CanCancelAtStart then
   Begin
      c_running := False;
      frmDatabaseUpdate.Close;
      dmData.RefreshMainDatabase();
   end
  else
   CancelUpdate := True;
end;

procedure TfrmDatabaseUpdate.tmrQRZTimer(Sender: TObject);
begin
  tmrQRZ.Enabled := False;
  CanCancelAtStart:=false;
  QRZupdate;
  if not found then    //this should close cancelled update
   Begin
      btnCancel.Click;
      frmDatabaseUpdate.Close;
      c_running := False;
      dmData.RefreshMainDatabase();
   end;
end;

procedure TfrmDatabaseUpdate.SynCallBook;
begin
  try
    pnlQRZ.Caption := 'Updating QSO with ' + c_SyncText;
    pnlQRZ.Repaint;
    if CloseW then
    begin
      btnCancel.Click;
      frmDatabaseUpdate.Close;
      c_running := False;
      dmData.RefreshMainDatabase();
    end
  except
    on E: Exception do
      Writeln(E.Message)
  end
end;

procedure TfrmDatabaseUpdate.QRZupdate;
var
  QRZ     :   TQRZThread;
  i       :   integer;
begin
  if not c_running then
  begin
    c_running := True;
    CloseW  := False;
    CancelUpdate := False;

    //without this update happens only to 500 QSOs loaded in QSO list view
    i:= pos('LIMIT',uppercase (dmData.qCallBook.SQL.Text));
    if i>0 then  dmData.qCallBook.SQL.Text:=copy(dmData.qCallBook.SQL.Text,1,i-1);

    if dmData.DebugLevel >= 1 then
      Writeln(dmData.qCallBook.SQL.Text);
    if not Selected then dmData.qCallBook.Open();
    dmData.qCallBook.First;

    if (id_cqrlog_main > -1) then
    begin
      while not dmData.qCallBook.EOF do
      begin
        if id_cqrlog_main = dmData.qCallBook.FieldByName('id_cqrlog_main').AsInteger then
        begin
          found := True;
          break
        end;
        dmData.qCallBook.Next
      end;

      if not found then
      Begin
        pnlQRZ.Caption := 'Previously canceled update breakpoint not found!';
        pnlQRZ.Repaint;
        Application.ProcessMessages;
        sleep(5000);
        exit  //here returns from QTZupdate, does not return from database update.Goes back to ONtmrQRZ
      end;
    end;

    found:=true;      //if id_cqrlog_main has been -1 make here true
    QRZ := TQRZThread.Create(True);
    QRZ.Start
  end
end;

end.

