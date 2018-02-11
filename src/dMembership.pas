unit dMembership;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, LazFileUtils, Forms, LCLType, dateutils;

const
  C_CLUB_COUNT = 5;
  C_CLUB_UPDATE_SECTION = 'ClubUpdates';
  C_LIST_OF_CLUBS : array[1..C_CLUB_COUNT] of string = ('First', 'Second', 'Third', 'Fourth', 'Fifth');
  C_MEMBERSHIP_VERSION_CHECK_URL = 'https://cqrlog.com/members/script/mtime.php?file=';
  C_MEMBERSHIP_DOWNLOAD_URL = 'https://cqrlog.com/members/%s';
  C_FROM_DATE = '1945-01-01';
  C_TO_DATE   = '2050-12-31';

type TMembershipLine = record
    club_nr : String[20];
    club_call : String[50];
    fromdate : String[10];
    todate : String[10]
end;

type

  { TdmMembership }

  TdmMembership = class(TDataModule)
    procedure DataModuleCreate(Sender : TObject);
    procedure DataModuleDestroy(Sender : TObject);
  private
    procedure PrepareListOfMembershipFilesForUpdate;

    function  GetMessageWithListOfUpdatedFiles : String;
  public
    ListOfMembershipFilesForUpdate : TStringList;

    procedure CheckForMembershipUpdate(Force : Boolean = False);
    procedure SaveLastMembershipUpdateDate(FileName : String; LastUpdateDate : TDateTime);
    procedure SynMembeshipUpdates;

    function  GetLastMembershipUpdateDate(FileName : String) : TDateTime;
    function  GetClubFileName(Club : String) : String;
    function  GetClubSourceFileNameWithPath(Club : String) : String;
    function  GetMembershipStructure(line : String) : TMembershipLine;
    function  GetClubTableName(ClubFileName : String) : String;
  end;

type
  TMembersipThread = class(TThread)
  public
    ClubFileNames : TStringList;
  protected
    procedure Execute; override;
  end;


var
  dmMembership : TdmMembership;

implementation
  {$R *.lfm}
uses uMyIni, dUtils, dData, fImportProgress;

  procedure TMembersipThread.Execute;
  var
    data   : string;
    FileDate : TDateTime;
    i : Integer;
    l : TStringList;
    ClubFileName : String;
  begin
    FreeOnTerminate := True;
    l := TStringList.Create;
    try try
      l.Clear;
      for i:=0 to ClubFileNames.Count-1 do
      begin
        ClubFileName := ExtractFileName(ClubFileNames.Strings[i]);
        if dmUtils.GetDataFromHttp(C_MEMBERSHIP_VERSION_CHECK_URL+ClubFileName, data) then
        begin
          FileDate := dmUtils.MyStrToDateTime(data);
          if FileDate > dmMembership.GetLastMembershipUpdateDate(ClubFileName) then
            l.Add(ClubFileNames.Strings[i])
        end
      end;

      dmMembership.ListOfMembershipFilesForUpdate.Clear;
      for i:=0 to l.Count-1 do
        dmMembership.ListOfMembershipFilesForUpdate.Add(l.Strings[i]);

      Synchronize(@dmMembership.SynMembeshipUpdates)
    except
      on E : Exception do
        Writeln('Membership check: '+E.ToString)
    end
    finally
      FreeAndNil(l)
    end
  end;

procedure TdmMembership.SynMembeshipUpdates;
var
  msg : String;
begin
  if (ListOfMembershipFilesForUpdate.Count > 0) then
  begin
    msg := GetMessageWithListOfUpdatedFiles;
    if Application.MessageBox(Pchar(msg+LineEnding+LineEnding+'Do you want do continue?'), PChar('Question'), mb_YesNo + mb_IconQuestion) = idYes then
    begin
      with TfrmImportProgress.Create(self) do
      try
        Caption            := 'Updating membership files ...';
        lblComment.Caption := 'Updating membership files ...';
        ImportType := imptUpdateMembershipFiles;
        ShowModal
      finally
        Free
      end
    end
  end
end;

procedure TdmMembership.CheckForMembershipUpdate(Force : Boolean = False);
var
  thMembership : TMembersipThread;
begin
  PrepareListOfMembershipFilesForUpdate;
  if Force then
    SynMembeshipUpdates
  else begin
    thMembership := TMembersipThread.Create(True);
    thMembership.FreeOnTerminate := True;
    thMembership.ClubFileNames := ListOfMembershipFilesForUpdate;
    thMembership.Start
  end
end;

function TdmMembership.GetLastMembershipUpdateDate(FileName : String) : TDateTime;
begin
  if (cqrini.ReadString(C_CLUB_UPDATE_SECTION, FileName, '') <> '') then
    Result := dmUtils.MyStrToDateTime(cqrini.ReadString(C_CLUB_UPDATE_SECTION, FileName, ''))
  else
    Result := dmUtils.MyStrToDateTime('2000-01-01 00:00:01')
end;

procedure TdmMembership.SaveLastMembershipUpdateDate(FileName : String; LastUpdateDate : TDateTime);
begin
  cqrini.WriteString(C_CLUB_UPDATE_SECTION, FileName, dmUtils.MyDateTimeToStr(LastUpdateDate))
end;

procedure TdmMembership.PrepareListOfMembershipFilesForUpdate;
var
  ClubFileName : String = '';
  i : Integer;
begin
  ListOfMembershipFilesForUpdate.Clear;

  for i:=1 to C_CLUB_COUNT do
  begin
    ClubFileName := GetClubSourceFileNameWithPath(cqrini.ReadString('Clubs', C_LIST_OF_CLUBS[i], ''));
    if (ClubFileName <> '') then
      ListOfMembershipFilesForUpdate.Add(ClubFileName)
  end
end;

procedure TdmMembership.DataModuleCreate(Sender : TObject);
begin
  ListOfMembershipFilesForUpdate := TStringList.Create
end;

procedure TdmMembership.DataModuleDestroy(Sender : TObject);
begin
  FreeAndNil(ListOfMembershipFilesForUpdate)
end;

function TdmMembership.GetClubSourceFileNameWithPath(Club : String) : String;
var
  ClubFileName : String;
  MemDir : String;
begin
  Result := '';

  if (Club='') then
    exit;

  ClubFileName := GetClubFileName(Club);

  MemDir := dmData.HomeDir+'members'+PathDelim;
  if FileExistsUTF8(MemDir + ClubFileName) then
  begin
    Result := MemDir + ClubFileName;
    exit
  end;

  MemDir := ExpandFileNameUTF8('..'+PathDelim+'share'+PathDelim+'cqrlog'+PathDelim+'members'+PathDelim);
  if FileExistsUTF8(MemDir + ClubFileName) then
    Result := MemDir + ClubFileName
end;

function TdmMembership.GetClubFileName(Club : String) : String;
begin
  Result := LowerCase(copy(Club, 1, Pos(';', Club) - 1)) + '.txt'
end;

function TdmMembership.GetMessageWithListOfUpdatedFiles : String;
var
  msg : String;
  i : Integer;
begin
  Result := '';
  if (ListOfMembershipFilesForUpdate.Count > 0) then
  begin
    if (ListOfMembershipFilesForUpdate.Count = 1) then
      msg := 'There is one membership file waiting for update:' + LineEnding + LineEnding +
             ExtractFileName(ListOfMembershipFilesForUpdate.Text)
    else begin
      msg := 'There are ' + IntToStr(ListOfMembershipFilesForUpdate.Count) + ' membership files waiting for update: '+
             LineEnding + LineEnding;
      for i:=0 to ListOfMembershipFilesForUpdate.Count-1 do
        msg := msg + ExtractFileName(ListOfMembershipFilesForUpdate.Strings[i]) + LineEnding
    end;

    Result := msg
  end
end;

function TdmMembership.GetMembershipStructure(line : String) : TMembershipLine;
var
  call     : String;
  clubnr   : String;
  fromDate : String;
  toDate   : String;
  tmp      : String;
  month    : String;
  year     : String;
  imonth   : Integer;
  iyear    : Integer;
  data     : TExplodeArray;
  num      : Integer = 0;
  day      : String;
  iday     : Integer;
begin
  Result.club_call := '';
  Result.club_nr   := '';
  Result.fromdate  := '';
  Result.todate    := '';

  data   := dmUtils.Explode(';', line);
  call   := data[0];
  if Length(data) > 1 then
    clubnr := data[1];
  if Length(data) > 2 then
  begin
    if Length(data) > 3 then
      toDate := data[3]
    else
      toDate := '';

    fromDate := data[2];
    month    := copy(fromDate,6,2);
    year     := copy(fromDate,1,4);
    if Length(fromDate)>7 then
      day := copy(fromDate,9,2)
    else
      day := '01';

    if not (TryStrToInt(month,imonth) and TryStrToInt(year,iyear) and TryStrToInt(day,iday)) then
    begin
      Writeln('Wrong date to encode!');
      Writeln('Call: '+call);
      Writeln('Club nr: '+clubnr);
      Writeln('From date: '+fromDate);
      exit
    end;

    if (imonth = 0) then
      month := '01';

    fromDate := year + '-' + month + '-' + day;

    if toDate='-' then
      toDate := '';
    if toDate <> '' then
    begin
      month := copy(toDate,6,2);
      year  := copy(toDate,1,4);
      if Length(toDate)>7 then
        day := copy(toDate,9,2)
      else
        day := '0';

      if not (TryStrToInt(month,imonth) and TryStrToInt(year,iyear) and TryStrToInt(day,iday)) then
      begin
        Writeln('Wrong date to encode!');
        Writeln('Call: '+call);
        Writeln('Club nr: '+clubnr);
        Writeln('To date: '+toDate);
        exit
      end;

      if (imonth = 0) then
      begin
        month  := '12';
        imonth := 12;
      end;

      if (iDay = 0) then
        day := Format('%.*d', [2,DaysInAMonth(iYear,iMonth)]);

      toDate := year + '-' + month + '-' + day
    end
    else
      toDate := C_TO_DATE;
  end
  else begin
    fromDate := C_FROM_DATE;
    toDate   := C_TO_DATE
  end;
  if clubnr='' then
    clubnr := call;

  Result.club_call := call;
  Result.club_nr   := clubnr;
  Result.fromdate  := fromDate;
  Result.todate    := toDate
end;

function TdmMembership.GetClubTableName(ClubFileName : String) : String;
var
  i : Integer;
begin
  Result := '';
  for i:=1 to C_CLUB_COUNT do
  begin
    if (ClubFileName = GetClubFileName(cqrini.ReadString('Clubs', C_LIST_OF_CLUBS[i], ''))) then
    begin
      Result := 'club' + IntToStr(i);
      break
    end
  end
end;

end.

