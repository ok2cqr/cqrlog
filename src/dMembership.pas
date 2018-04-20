unit dMembership;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, LazFileUtils, Forms, LCLType, dateutils, StdCtrls, Graphics;

const
  C_CLUB_COUNT = 5;
  C_CLUB_UPDATE_SECTION = 'ClubUpdates';
  C_LIST_OF_CLUBS : array[1..C_CLUB_COUNT] of string = ('First', 'Second', 'Third', 'Fourth', 'Fifth');
  C_MEMBERSHIP_VERSION_CHECK_URL = 'https://cqrlog.com/members/script/mtime.php?file=%s';
  C_MEMBERSHIP_DOWNLOAD_URL = 'https://cqrlog.com/members/%s';
  C_FROM_DATE = '1945-01-01';
  C_TO_DATE   = '2050-12-31';
  C_CLUB_MSG_NEW = 'New %s member! (%c #%n)';
  C_CLUB_MSG_BAND = 'New band %s member! (%c #%n)';
  C_CLUB_MSG_MODE = 'New mode %s member! (%c #%n)';
  C_CLUB_MSG_QSL = 'QSL needed for %s member! (%c #%n)';
  C_CLUB_MSG_CFM = 'Already confirmed %s member! (%c #%n)';
  C_CLUB_COLOR_NEW = clRed;
  C_CLUB_COLOR_BAND = clBlue;
  C_CLUB_COLOR_MODE = clLime;
  C_CLUB_COLOR_QSL = clFuchsia;
  C_CLUB_COLOR_CFM = clBlack;
  C_CLUB_DEFAULT_CLUB_FIELD = 'clubcall';
  C_CLUB_DEFAULT_MAIN_FIELD = 'call';
  C_CLUB_DEFAULT_DATE_FROM = '1945-01-01';
  C_CLUB_DEFAULT_DATE_TO = '2050-12-31';
type
  TClub = record
    Name           : String;
    LongName       : String;
    NewInfo        : String;
    NewBandInfo    : String;
    NewModeInfo    : String;
    QSLNeededInfo  : String;
    AlreadyCfmInfo : String;
    ClubField      : String;
    MainFieled     : String;
    StoreField     : String;
    StoreText      : String;
    NewColor       : Integer;
    BandColor      : Integer;
    ModeColor      : Integer;
    QSLColor       : Integer;
    AlreadyColor   : Integer;
    DateFrom       : String;
  end;


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
    function GetComboClubNameFromFile(ClubFile : String) : String;
  public
    ListOfMembershipFilesForUpdate : TStringList;
    Club1     : TClub;
    Club2     : TClub;
    Club3     : TClub;
    Club4     : TClub;
    Club5     : TClub;

    procedure CheckForMembershipUpdate(Force : Boolean = False);
    procedure SaveLastMembershipUpdateDate(FileName : String; LastUpdateDate : TDateTime);
    procedure SynMembeshipUpdates;
    procedure ReadMemberList(cmbMemebers: TComboBox);
    procedure LoadClubSettings(ClubNr : Integer; var Club : TClub);

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
        if dmUtils.GetDataFromHttp(Format(C_MEMBERSHIP_VERSION_CHECK_URL, [ClubFileName]), data) then
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
begin
  Result := '';

  if (Club='') then
    exit;

  ClubFileName := GetClubFileName(Club);

  if FileExistsUTF8(dmData.MembersDir + ClubFileName) then
  begin
    Result := dmData.MembersDir + ClubFileName;
    exit
  end;

  if FileExistsUTF8(dmData.GlobalMembersDir + ClubFileName) then
    Result := dmData.GlobalMembersDir + ClubFileName
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

function TdmMembership.GetComboClubNameFromFile(ClubFile : String) : String;
var
  f : TextFile;
  ShortName : String;
  LongName  : String;
begin
  AssignFile(f, ClubFile);
  try
    Reset(f);
    ReadLn(f, ShortName);
    ReadLn(f, LongName);

    Result := ShortName + ';' + LongName
  finally
    CloseFile(f)
  end
end;

procedure TdmMembership.ReadMemberList(cmbMemebers: TComboBox);
var
  l: TStringList;
  i: integer = 0;
  ClubName : String;
begin
  cmbMemebers.Clear;
  cmbMemebers.Items.Add('');
  l := TStringList.Create;
  try
    dmUtils.LoadListOfFiles(dmData.MembersDir, '*.txt', l);
    if l.Count > 0 then
    begin
      cmbMemebers.Items.Add('--- Local files ---');
      for i:=0 to l.Count-1 do
        cmbMemebers.Items.Add(GetComboClubNameFromFile(l.Strings[i]))
    end;

    dmUtils.LoadListOfFiles(dmData.GlobalMembersDir, '*.txt', l);
    if l.Count > 0 then
    begin
      cmbMemebers.Items.Add('--- Global files ---');
      for i:=0 to l.Count-1 do
      begin
        ClubName := GetComboClubNameFromFile(l.Strings[i]);
        if (cmbMemebers.Items.IndexOf(ClubName) = -1) then
          cmbMemebers.Items.Add(ClubName)
      end
    end
  finally
    l.Free
  end
end;

procedure TdmMembership.LoadClubSettings(ClubNr : Integer; var Club : TClub);
var
  Section , ClubText: String;
begin
  ClubText := cqrini.ReadString('Clubs', C_LIST_OF_CLUBS[ClubNr], '');

  Section := C_LIST_OF_CLUBS[ClubNr] + 'Club';
  Club.Name           := copy(ClubText, 1, Pos(';', ClubText)-1);
  Club.LongName       := copy(ClubText, Pos(';', ClubText)+1, Length(ClubText) - Pos(';', ClubText)+1);
  Club.NewInfo        := cqrini.ReadString(Section, 'NewInfo', C_CLUB_MSG_NEW);
  Club.NewBandInfo    := cqrini.ReadString(Section , 'NewBandInfo', C_CLUB_MSG_BAND);
  Club.NewModeInfo    := cqrini.ReadString(Section , 'NewModeInfo', C_CLUB_MSG_MODE);
  Club.QSLNeededInfo  := cqrini.ReadString(Section , 'QSLNeededInfo', C_CLUB_MSG_QSL);
  Club.AlreadyCfmInfo := cqrini.ReadString(Section , 'AlreadyConfirmedInfo', C_CLUB_MSG_CFM);
  Club.ClubField      := cqrini.ReadString(Section , 'ClubFields', C_CLUB_DEFAULT_CLUB_FIELD);
  Club.MainFieled     := cqrini.ReadString(Section , 'MainFields', C_CLUB_DEFAULT_MAIN_FIELD);
  Club.StoreField     := cqrini.ReadString(Section , 'StoreFields', '');
  Club.StoreText      := cqrini.ReadString(Section , 'StoreText', '');
  Club.NewColor       := cqrini.ReadInteger(Section, 'NewColor', C_CLUB_COLOR_NEW);
  Club.BandColor      := cqrini.ReadInteger(Section, 'BandColor', C_CLUB_COLOR_BAND);
  Club.ModeColor      := cqrini.ReadInteger(Section, 'ModeColor', C_CLUB_COLOR_MODE);
  Club.QSLColor       := cqrini.ReadInteger(Section, 'QSLColor', C_CLUB_COLOR_QSL);
  Club.AlreadyColor   := cqrini.ReadInteger(Section, 'AlreadyColor', C_CLUB_COLOR_QSL);
  Club.DateFrom       := cqrini.ReadString(Section, 'DateFrom', C_CLUB_DEFAULT_DATE_FROM)
end;

end.

