(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

// The user's own data: QTH profiles, per-callsign notes, callsign alerts and
// frequency memories.
//
// Two layers live here.  The Sql* builders return statement text and nothing
// else.  Above them sit the operations, which run that text on this module's
// own cursor -- a TSQLQuery and TSQLTransaction nobody outside can reach.
// That is the point: a note being saved no longer rolls back whatever
// transaction the caller had open on a shared cursor, and no longer closes a
// dataset some grid is showing.

unit dSqlUserData;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, sqldb, contnrs;

type
  TdmSqlUserData = class(TDataModule)
    procedure DataModuleCreate(Sender : TObject);
  private
    FQ : TSQLQuery;
    FT : TSQLTransaction;
  public
    // Wired from TdmData once MainCon exists -- this module is not one of
    // dData's components, so its bulk DataBase assignment does not reach it.
    procedure AttachTo(Connection : TSQLConnection);

    // notes
    function  GetComment(const Callsign : String) : String;
    procedure SaveComment(const Callsign, Note : String);
    procedure LoadCommentCache(Cache : TFPStringHashTable);
    procedure DeleteComment(const Id : Integer);
    function  CallNoteExists(const Callsign : String) : Boolean;

    // profiles
    function SqlAllProfiles : String;
    function SqlProfileGrid : String;
    function SqlVisibleProfiles : String;
    function SqlProfile(const Nr : Integer) : String;
    function SqlCompleteProfile(const Nr : Integer) : String;
    function SqlProfileLocator(const Nr : Integer) : String;
    function SqlProfilesForExport : String;
    function SqlNewProfileNumber : String;
    function SqlInsertProfile : String;
    function SqlUpdateProfile : String;
    function SqlUpdateQsoProfile : String;
    function SqlProfileExists : String;
    function SqlProfileInUse : String;
    function SqlDeleteProfile : String;
    function SqlUpdateProfileVisibility : String;
    function SqlProfileByFields(const Locator, Qth, Equipment, Remarks : String) : String;
    function SqlProfileNumberExists(const ProfileNumber : String) : String;
    function SqlMaxProfileNumber : String;
    function SqlInsertImportedProfile : String;

    // notes
    function SqlNoteId(const Callsign : String) : String;
    function SqlDeleteNoteByCallsign(const Callsign : String) : String;
    function SqlInsertNote(const Callsign, Note : String) : String;
    function SqlUpdateNote(const Callsign, Note : String) : String;
    function SqlNoteText(const Callsign : String) : String;
    function SqlAllNotes : String;
    function SqlDeleteNote(const Id : Integer) : String;
    function SqlCallNoteExists(const Callsign : String) : String;
    function SqlNotesByCallsign : String;

    // long_note
    function SqlLongNote : String;
    function SqlInsertLongNote : String;
    function SqlUpdateLongNote : String;

    // call_alert
    function SqlCallAlertsByCallsign : String;
    function SqlDeleteCallAlert(const Id : Integer) : String;
    function SqlInsertCallAlert : String;
    function SqlUpdateCallAlert : String;
    function SqlLastCallAlertId(const Callsign, Band, Mode : String) : String;
    function SqlCallAlert(const Callsign : String) : String;
    function SqlCallAlertRegExp(const Callsign : String) : String;

    // freqmem
    function SqlInsertFreqMemory : String;
    function SqlDeleteFreqMemories : String;
    function SqlFreqMemoriesForGrid : String;
    function SqlFreqMemoriesForMode(const Mode : String) : String;
  end;

var
  dmSqlUserData : TdmSqlUserData;

implementation

{$R *.lfm}

uses Dialogs, dData;

procedure TdmSqlUserData.DataModuleCreate(Sender : TObject);
begin
  FT := TSQLTransaction.Create(Self);
  FT.Action := caNone;
  FQ := TSQLQuery.Create(Self);
  FQ.Transaction := FT
end;

procedure TdmSqlUserData.AttachTo(Connection : TSQLConnection);
begin
  FT.DataBase := Connection;
  FQ.DataBase := Connection
end;

{ note operations }

function TdmSqlUserData.GetComment(const Callsign : String) : String;
begin
  FQ.Close;
  if FT.Active then FT.Rollback;
  FT.StartTransaction;
  try
    FQ.SQL.Text := SqlNoteText(Callsign);
    FQ.Open;
    Result := FQ.Fields[0].AsString
  finally
    FQ.Close;
    FT.Rollback
  end
end;

procedure TdmSqlUserData.SaveComment(const Callsign, Note : String);
var
  Text : String;
begin
  Text := Trim(Note);
  if dmData.DebugLevel >= 1 then Writeln('Note:',Text);
  FQ.Close;
  if FT.Active then FT.Rollback;

  try try
    FT.StartTransaction;
    FQ.SQL.Text := SqlNoteId(Callsign);
    FQ.Open;

    if (Text = '') and (FQ.Fields[0].IsNull) then
      exit; //nothing to save

    if (Text = '') and (not FQ.Fields[0].IsNull) then
    begin                //user deleted the note
      FQ.Close;
      FQ.SQL.Text := SqlDeleteNoteByCallsign(Callsign);
      FQ.ExecSQL;
      exit
    end;

    if FQ.Fields[0].IsNull then
    begin
      FQ.Close;
      FQ.SQL.Text := SqlInsertNote(Callsign, Text);
      FQ.ExecSQL
    end
    else begin
      FQ.Close;
      FQ.SQL.Text := SqlUpdateNote(Callsign, Text);
      FQ.ExecSQL
    end
  except
    on E : Exception do
    begin
      ShowMessage('Error saving comment to QSO.'+LineEnding+E.Message);
      FT.Rollback
    end
  end
  finally
    if FT.Active then
      FT.Commit;
    FQ.Close
  end
end;

// Load all notes in a single query into an in-memory map (callsign -> longremarks).
// Used by ADIF export to avoid one DB round-trip per QSO (see fExportProgress).
procedure TdmSqlUserData.LoadCommentCache(Cache : TFPStringHashTable);
begin
  FQ.Close;
  if FT.Active then FT.Rollback;
  FT.StartTransaction;
  try
    FQ.SQL.Text := SqlAllNotes;
    FQ.Open;
    while not FQ.Eof do
    begin
      if FQ.Fields[1].AsString <> '' then
        Cache[FQ.Fields[0].AsString] := FQ.Fields[1].AsString;
      FQ.Next
    end
  finally
    FQ.Close;
    FT.Rollback
  end
end;

procedure TdmSqlUserData.DeleteComment(const Id : Integer);
begin
  FQ.Close;
  if FT.Active then FT.Rollback;

  FT.StartTransaction;
  try try
    FQ.SQL.Text := SqlDeleteNote(Id);
    FQ.ExecSQL
  except
    on E : Exception do
    begin
      Writeln(E.Message);
      FT.Rollback
    end
  end
  finally
    if FT.Active then
      FT.Commit
  end
end;

function TdmSqlUserData.CallNoteExists(const Callsign : String) : Boolean;
begin
  Result := False;
  FQ.Close;
  if FT.Active then FT.Rollback;
  FT.StartTransaction;
  try
    FQ.SQL.Text := SqlCallNoteExists(Callsign);
    FQ.Open;
    Result := FQ.RecordCount > 0
  finally
    FQ.Close;
    FT.Rollback
  end
end;

{ profiles }

function TdmSqlUserData.SqlAllProfiles : String;
begin
  Result := 'SELECT * FROM profiles ORDER BY nr'
end;

// Same statement as SqlAllProfiles.  Kept separate so this extraction leaves
// the SQL inventory (tools/sql-inventory) untouched; merging the two is a
// follow-up commit of its own.
function TdmSqlUserData.SqlProfileGrid : String;
begin
  Result := 'SELECT * FROM profiles ORDER BY nr'
end;

function TdmSqlUserData.SqlVisibleProfiles : String;
begin
  Result := 'SELECT * FROM profiles WHERE visible > 0 ORDER BY nr'
end;

function TdmSqlUserData.SqlProfile(const Nr : Integer) : String;
begin
  Result := 'SELECT * FROM profiles WHERE nr = '+IntToStr(Nr)
end;

// Same statement as SqlProfile -- see the note on SqlProfileGrid.
function TdmSqlUserData.SqlCompleteProfile(const Nr : Integer) : String;
begin
  Result := 'SELECT * FROM profiles WHERE nr = '+IntToStr(Nr)
end;

function TdmSqlUserData.SqlProfileLocator(const Nr : Integer) : String;
begin
  Result := 'select locator from profiles where nr = '+IntToStr(Nr)
end;

function TdmSqlUserData.SqlProfilesForExport : String;
begin
  Result := 'select * from profiles order by nr'
end;

function TdmSqlUserData.SqlNewProfileNumber : String;
begin
  Result := 'select max(nr) as nr from profiles'
end;

function TdmSqlUserData.SqlInsertProfile : String;
begin
  Result := 'INSERT INTO profiles (nr, locator, qth, rig, remarks, visible) VALUES (:nr, :locator, :qth, :rig, :remarks, :visible)'
end;

function TdmSqlUserData.SqlUpdateProfile : String;
begin
  Result := 'update profiles set locator = :locator, qth = :qth, rig = :rig, remarks = :remarks, visible = :visible, nr = :nr where nr = :old_nr'
end;

function TdmSqlUserData.SqlUpdateQsoProfile : String;
begin
  Result := 'update cqrlog_main set profile = :new_profile  where profile = :old_profile'
end;

function TdmSqlUserData.SqlProfileExists : String;
begin
  Result := 'select nr from profiles where nr = :profile_number'
end;

function TdmSqlUserData.SqlProfileInUse : String;
begin
  Result := 'select id_cqrlog_main from cqrlog_main where (profile = :profile_number) limit 1'
end;

function TdmSqlUserData.SqlDeleteProfile : String;
begin
  Result := 'delete from profiles where nr = :profile_number limit 1'
end;

function TdmSqlUserData.SqlUpdateProfileVisibility : String;
begin
  Result := 'update profiles set visible = :visible where nr = :profile_number limit 1'
end;

function TdmSqlUserData.SqlProfileByFields(const Locator, Qth, Equipment, Remarks : String) : String;
begin
  Result := 'SELECT nr FROM profiles WHERE locator='+QuotedStr(Locator) +
            ' and qth='+QuotedStr(Qth)+' and rig='+QuotedStr(Equipment) +
            ' and remarks='+QuotedStr(Remarks)
end;

function TdmSqlUserData.SqlProfileNumberExists(const ProfileNumber : String) : String;
begin
  Result := 'select nr from profiles where nr = '+ProfileNumber
end;

function TdmSqlUserData.SqlMaxProfileNumber : String;
begin
  Result := 'select max(nr) from profiles'
end;

function TdmSqlUserData.SqlInsertImportedProfile : String;
begin
  Result := 'insert into profiles (nr,locator,qth,rig,remarks,visible) values ('+
            ':nr,:locator,:qth,:rig,:remarks,:visible)'
end;

{ notes }

function TdmSqlUserData.SqlNoteId(const Callsign : String) : String;
const
  C_SEL = 'select id_notes from notes where callsign = %s limit 1';
begin
  Result := Format(C_SEL, [QuotedStr(Callsign)])
end;

function TdmSqlUserData.SqlDeleteNoteByCallsign(const Callsign : String) : String;
const
  C_DEL = 'delete from notes where callsign = %s';
begin
  Result := Format(C_DEL, [QuotedStr(Callsign)])
end;

function TdmSqlUserData.SqlInsertNote(const Callsign, Note : String) : String;
const
  C_INS = 'insert into notes (callsign, longremarks) values (%s, %s)';
begin
  Result := Format(C_INS, [QuotedStr(Callsign), QuotedStr(Note)])
end;

function TdmSqlUserData.SqlUpdateNote(const Callsign, Note : String) : String;
const
  C_UPD = 'update notes set longremarks = %s where callsign = %s';
begin
  Result := Format(C_UPD, [QuotedStr(Note), QuotedStr(Callsign)])
end;

function TdmSqlUserData.SqlNoteText(const Callsign : String) : String;
begin
  Result := 'SELECT longremarks FROM notes WHERE callsign = ' + QuotedStr(Callsign)
end;

function TdmSqlUserData.SqlAllNotes : String;
begin
  Result := 'SELECT callsign, longremarks FROM notes'
end;

function TdmSqlUserData.SqlDeleteNote(const Id : Integer) : String;
const
  C_DEL = 'delete from notes where id_notes = %d';
begin
  Result := Format(C_DEL, [Id])
end;

function TdmSqlUserData.SqlCallNoteExists(const Callsign : String) : String;
const
  C_SEL = 'select id_notes from notes where callsign=%s';
begin
  Result := Format(C_SEL, [QuotedStr(Callsign)])
end;

function TdmSqlUserData.SqlNotesByCallsign : String;
begin
  Result := 'select * from notes order by callsign'
end;

{ long_note }

function TdmSqlUserData.SqlLongNote : String;
begin
  Result := 'SELECT id_long_note, note FROM long_note'
end;

function TdmSqlUserData.SqlInsertLongNote : String;
begin
  Result := 'insert into long_note(id_long_note,note) values (1,:note)'
end;

function TdmSqlUserData.SqlUpdateLongNote : String;
begin
  Result := 'UPDATE long_note set note = :note where id_long_note = 1'
end;

{ call_alert }

function TdmSqlUserData.SqlCallAlertsByCallsign : String;
begin
  Result := 'select * from call_alert order by callsign'
end;

function TdmSqlUserData.SqlDeleteCallAlert(const Id : Integer) : String;
const
  C_DEL = 'delete from call_alert where id = %d';
begin
  Result := Format(C_DEL, [Id])
end;

function TdmSqlUserData.SqlInsertCallAlert : String;
begin
  Result := 'insert into call_alert(callsign,mode,band) values (:callsign,:mode,:band)'
end;

function TdmSqlUserData.SqlUpdateCallAlert : String;
begin
  Result := 'update call_alert set callsign=:callsing,band =:band,mode =:mode where id=:id'
end;

function TdmSqlUserData.SqlLastCallAlertId(const Callsign, Band, Mode : String) : String;
const
  C_SEL = 'select max(id) from call_alert where (callsign=%s) and (band=%s) and (mode=%s)';
begin
  Result := Format(C_SEL, [QuotedStr(Callsign), QuotedStr(Band), QuotedStr(Mode)])
end;

// With a complete callsign it makes no difference whether %s or the
// call_alert/callsign column is the target.
function TdmSqlUserData.SqlCallAlert(const Callsign : String) : String;
const
  C_SEL = 'select * from call_alert where callsign = %s';
begin
  Result := Format(C_SEL, [QuotedStr(Callsign)])
end;

// With partial callsigns %s is the target and the call_alert/callsign column
// holds the regexp condition.
function TdmSqlUserData.SqlCallAlertRegExp(const Callsign : String) : String;
const
  C_RGX_SEL = 'select * from call_alert where %s regexp callsign';
begin
  Result := Format(C_RGX_SEL, [QuotedStr(Callsign)])
end;

{ freqmem }

function TdmSqlUserData.SqlInsertFreqMemory : String;
begin
  Result := 'insert into freqmem (freq,mode,bandwidth,info) values (:freq,:mode,:bandwidth,:info)'
end;

function TdmSqlUserData.SqlDeleteFreqMemories : String;
begin
  Result := 'delete from freqmem'
end;

function TdmSqlUserData.SqlFreqMemoriesForGrid : String;
begin
  Result := 'select freq,mode,bandwidth,info from freqmem order by freq'
end;

function TdmSqlUserData.SqlFreqMemoriesForMode(const Mode : String) : String;
const
  C_SEL = 'select id,freq,mode,bandwidth,info from freqmem';
begin
  if (Mode='') then Result := C_SEL + ' order by id'
  else
   begin
    case Mode of
         'LSB','USB','FM','AM'     :Result := C_SEL + ' where (mode = ' + QuotedStr('LSB') +') or ' +
                                                           '(mode = ' + QuotedStr('USB') + ') or (mode = ' + QuotedStr('FM') + ') or ' +
                                                           '(mode = ' + QuotedStr('AM')+ ') order by id';
         'RTTY','PKTLSB','PKTUSB',
         'PKTFM','DATA'            :Result := C_SEL + ' where (mode = ' + QuotedStr('RTTY') +') or ' +
                                                           '(mode = ' + QuotedStr('PKTLSB') + ') or (mode = ' + QuotedStr('PKTUSB') + ') or ' +
                                                           '(mode = ' + QuotedStr('PKTFM') + ') or (mode = ' + QuotedStr('DATA')+ ') order by id';
     else
      Result := C_SEL + ' where (mode = ' + QuotedStr(Mode) +') order by id'
    end;
   end;
end;

end.
