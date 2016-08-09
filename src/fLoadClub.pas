(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fLoadClub;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Buttons, StdCtrls, inifiles, dateutils, lcltype;

type
  TExplodeArray = Array of String;

const
  cFromDate     = '1945-01-01';
  cToDate       = '2050-12-31';

type

  { TfrmLoadClub }

  TfrmLoadClub = class(TForm)
    btnClose: TButton;
    mLoad: TMemo;
    Panel1: TPanel;
    tmrLoad: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure tmrLoadTimer(Sender: TObject);
  private
    Running : Boolean;
    procedure LoadClub;
    procedure LoadZip;
  public
    SourceFile : String;
    TargetFile : String;
    DBnum      : String;
    TypOfLoad  : Integer; //0 : Club; 1 : ZIP code
    ZipNr      : Integer; //number of zip database
  end; 

var
  frmLoadClub: TfrmLoadClub;


implementation
{$R *.lfm}

uses dUtils, dData, uMyIni;

{ TfrmLoadClub }

procedure TfrmLoadClub.FormCreate(Sender: TObject);
begin
  Running := False;
end;

procedure TfrmLoadClub.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(self);
  tmrLoad.Enabled := True
end;

procedure TfrmLoadClub.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmLoadClub.tmrLoadTimer(Sender: TObject);
begin
  tmrLoad.Enabled := False;
  try
    btnClose.Enabled := False;
    Cursor := crHourGlass;
    if TypOfLoad = 0 then
      LoadClub
    else
      LoadZip
  finally
    Cursor := crDefault;
    btnClose.Enabled := True;
  end
end;

procedure TfrmLoadClub.LoadClub;
var
  sF       : TextFile;
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
  e        : Boolean = False;
  day      : String;
  iday     : Integer;
begin
  mLoad.Clear;
  if not FileExists(SourceFile) then
  begin
    mLoad.Lines.Add('Source file ' + SourceFile + ' does not exist!');
    exit
  end;

  AssignFile(sF,SourceFile);
  FileMode := 0;
  {$I-}
  Reset(sF);
  {$I+}
  if IOResult <> 0 then
  begin
    mLoad.Lines.Add('Can not open source file ' + SourceFile + ' for reading!');
    CloseFile(sF);
    exit
  end;

  readln(sF,tmp); //header
  readln(sF,tmp);
  mLoad.Lines.Add('Working ....');
  mLoad.Repaint;
  if dmData.trQ.Active then
  dmData.trQ.Rollback;
  dmData.trQ.StartTransaction;
  try try
    dmData.Q.Close;
    dmData.Q.SQL.Text := 'TRUNCATE TABLE club'+DBnum;
    dmData.Q.ExecSQL;
    while not Eof(sF) do
    begin
      clubnr := '';
      inc(num);
      Readln(sF,tmp);
      data   := dmUtils.Explode(';',tmp);
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
          mLoad.Lines.Add('Wrong date to encode!');
          mLoad.Lines.Add('Call: '+call);
          mLoad.Lines.Add('Club nr: '+clubnr);
          mLoad.Lines.Add('From date: '+fromDate);
          Break
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
            mLoad.Lines.Add('Wrong date to encode!');
            mLoad.Lines.Add('Call: '+call);
            mLoad.Lines.Add('Club nr: '+clubnr);
            mLoad.Lines.Add('To date: '+toDate);
            Break
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
          toDate := cToDate
      end
      else begin
        fromDate := cFromDate;
        toDate   := cToDate
      end;
      if clubnr='' then
        clubnr := call;
      if dmData.DebugLevel >=1 then WriteLn(clubnr,';',call,';',fromdate,';',todate);
      dmData.Q.SQL.Text := 'INSERT INTO club'+DBnum+' (club_nr,clubcall,fromdate,todate) '+
                           'VALUES ('+QuotedStr(clubnr)+','+QuotedStr(call)+','+QuotedStr(fromDate)+','+
                           QuotedStr(toDate)+')';
      dmData.Q.ExecSQL
    end
  except
    on Ex : Exception do
    begin
      dmData.trQ.Rollback;
      mLoad.Lines.Add('EX: '+ Ex.Message);
      e := True
    end
  end
  finally
    if not e then
    begin
      mLoad.Lines.Add(IntToStr(num) + ' records converted');
      dmData.trQ.Commit
    end
    else
        mLoad.Lines.Add('0 records converted');
    dmData.Q.Close;
    CloseFile(sF)
  end
end;

procedure TfrmLoadClub.LoadZIP;
var
  sF       : TextFile;
  data     : TExplodeArray;
  num      : Integer = 0;
  tmp      : String;
  er    : Boolean = False;
begin
  mLoad.Clear;
  if not FileExists(SourceFile) then
  begin
    mLoad.Lines.Add('Source file ' + SourceFile + ' does not exist!');
    exit
  end;
  AssignFile(sF,SourceFile);
  FileMode := 0;
  {$I-}
  Reset(sF);
  {$I+}
  if IOResult <> 0 then
  begin
    mLoad.Lines.Add('Can not open source file ' + SourceFile + ' for reading!');
    CloseFile(sF);
    exit
  end;
  readln(sF,tmp); //head
  readln(sF,tmp);
  readln(sF,tmp); //dxcc
  case ZipNr of
    1 : cqrini.WriteString('ZipCode','FirstDXCC',tmp);
    2 : cqrini.WriteString('ZipCode','SecondDXCC',tmp);
    3 : cqrini.WriteString('ZipCode','ThirdDXCC',tmp)
  end;
  mLoad.Lines.Add('Working ....');
  mLoad.Repaint;
  Application.ProcessMessages;
  try try
    dmData.trQ.StartTransaction;
    dmData.Q.SQL.Text:= 'TRUNCATE zipcode'+IntToStr(ZipNR);
    if dmData.DebugLevel >=1 then Writeln(dmData.Q.SQL.Text);
    dmData.Q.ExecSQL;
    while not Eof(sF) do
    begin
      inc(num);
      Readln(sF,tmp);
      data   := dmUtils.Explode(';',tmp);
      dmData.Q.SQL.Text := 'INSERT INTO zipcode'+IntToStr(ZipNr)+ ' (zip,county) '+
                           'VALUES('+QuotedStr(data[0])+','+QuotedStr(data[1])+')';
      if dmData.DebugLevel >=1 then Writeln(dmData.Q.SQL.Text);
      dmData.Q.ExecSQL;
      Sleep(1)
    end;
    mLoad.Lines.Add(IntToStr(num) + ' records converted');
  except
    on E : Exception do
    begin
      Application.MessageBox(PChar('Can not import file to database!'+#13+E.Message),'Error ...',
                            mb_OK+mb_IconError);
      er := True;
      dmData.trQ.Rollback
    end
  end
  finally
    if not er then
      dmData.trQ.Commit;
    CloseFile(sF)
  end
end;

end.

