(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fQSODetails;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, inifiles,
  ExtCtrls, lcltype, uColorMemo;

type

  { TfrmQSODetails }

  TfrmQSODetails = class(TForm)
    pnlDetails: TPanel;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    fwaz      : String;
    fitu      : String;
    ffreq     : String;
    fiota     : String;
    fmode     : String;
    fClubData1 : String;
    fClubData2 : String;
    fClubData3 : String;
    fClubData4 : String;
    fClubData5 : String;
    fClubDate  : String;
    fClubNR1   : String;
    fClubNR2   : String;
    fClubNR3   : String;
    fClubNR4   : String;
    fClubNR5   : String;

    procedure SetWAZ(NewWaz : String);
    procedure SetITU(NewITU : String);
    procedure SetIOTA(NewIOTA : String);
    procedure SetClub1(Data1 : String);
    procedure SetClub2(Data2 : String);
    procedure SetClub3(Data3 : String);
    procedure SetClub4(Data4 : String);
    procedure SetClub5(Data5 : String);
    procedure SetClub(data : String;num : Integer);
    procedure ShowWAZInfo;
    procedure ShowITUInfo;
    procedure ShowIOTAInfo;
    procedure ShowClubInfo;

    function SetStoreText(call,clubnr,long,short,StoreInfoText : String) : String;
  public
    property waz  : String read fwaz write SetWAZ;
    property itu  : String read fitu write SetITU;
    property freq : String read ffreq write ffreq;
    property mode : String read fmode write fmode;
    property iota : String read fiota write SetIOTA;
    property ClubData1 : String read fClubData1 write SetClub1;
    property ClubData2 : String read fClubData2 write SetClub2;
    property ClubData3 : String read fClubData3 write SetClub3;
    property ClubData4 : String read fClubData4 write SetClub4;
    property ClubData5 : String read fClubData5 write SetClub5;
    property ClubDate  : String read fClubDate write fClubDate;

    property ClubNR1 : String read fClubNR1;
    property ClubNR2 : String read fClubNR2;
    property ClubNR3 : String read fClubNR3;
    property ClubNR4 : String read fClubNR4;
    property ClubNR5 : String read fClubNR5;


    procedure LoadFonts;
    procedure ClearAll;
    procedure ShowInfo;
    procedure ClearStat;
    procedure ClearWAZ;
    procedure ClearITU;
    procedure ClearIOTA;
    
  end;

type
  Twazitu = Record
    Text  : String;
    Color : Integer;
  end;

type
  Tiota = Record
    Text   : String;
    Color  : Integer;
    island : String;
  end;

type
  TClubInfo = Record
    Text  : String;
    Color : Integer;
  end;
  
  
var
  frmQSODetails: TfrmQSODetails;
  Details : TColorMemo;
  Liota   : Tiota;
  Lwaz    : Twazitu;
  Litu    : Twazitu;
  LClub1  : TClubInfo;
  LClub2  : TClubInfo;
  LClub3  : TClubInfo;
  LClub4  : TClubInfo;
  LClub5  : TClubInfo;

implementation
{$R *.lfm}

{ TfrmQSODetails }
uses dUtils, dData, fNewQSO, uMyIni;

{
 %l - long club name
 %s - short club name
 %n - club number
 %c - callsign
}


procedure TfrmQSODetails.SetWAZ(NewWaz : String);
begin
  fwaz := NewWaz;
  Lwaz.Text := '';
  ShowInfo;
end;

procedure TfrmQSODetails.SetITU(NewITU : String);
begin
  fitu := NewITU;
  Litu.Text := '';
  ShowInfo;
end;

procedure TfrmQSODetails.SetIOTA(NewIOTA : String);
begin
  fiota := NewIOTA;
  Liota.Text := '';
  ShowInfo;
end;

procedure TfrmQSODetails.LoadFonts;
var
  f      : TFont;
begin
  dmUtils.LoadFontSettings(self);
  f := TFont.Create;
  try
    f.Name := cqrini.ReadString('Fonts','Buttons','Sans 10');
    Details.SetFont(f)
  finally
    f.Free
  end
end;

procedure TfrmQSODetails.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  if dmData.DebugLevel>=1 then Writeln('Closing Details window');
end;

procedure TfrmQSODetails.FormDestroy(Sender: TObject);
begin
  Details.Free
end;

procedure TfrmQSODetails.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key= VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0
  end
end;

procedure TfrmQSODetails.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmQSODetails)
end;

procedure TfrmQSODetails.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmQSODetails);
  Details             := TColorMemo.Create(pnlDetails);
  Details.parent      := pnlDetails;
  Details.AutoScroll  := True;
  Details.Align       := alClient;
  Details.setLanguage(1);
  LoadFonts
end;

procedure TfrmQSODetails.ClearAll;
begin
  Details.RemoveAllLines
end;

procedure TfrmQSODetails.ClearStat;
begin
  fwaz        := '';
  fitu        := '';
  ffreq       := '';
  fiota       := '';
  fClubData1  := '';
  fClubData2  := '';
  fClubData3  := '';
  fClubData4  := '';
  fClubData5  := '';
  fClubNR1    := '';
  fClubNR2    := '';
  fClubNR3    := '';
  fClubNR4    := '';
  fClubNR5    := '';
  LClub1.Text := '';
  LClub2.Text := '';
  LClub3.Text := '';
  LClub4.Text := '';
  LClub5.Text := ''
end;

procedure TfrmQSODetails.ShowInfo;
begin
  if (not Showing) or (frmNewQSO.mnuRemoteMode.Checked) then
    exit;
  Details.DisableAutoRepaint(true);
  try
    ClearAll;
    if Lwaz.Text = '' then
      ShowWAZInfo
    else
      Details.AddLine(Lwaz.Text,Lwaz.Color,clWhite,0);
    if Litu.Text = '' then
      ShowITUInfo
    else
      Details.AddLine(Litu.Text,Litu.Color,clWhite,0);
    if Liota.Text = '' then
      ShowIOTAInfo
    else begin
      Details.AddLine(Liota.Text,Liota.Color,clWhite,0);
      Details.AddLine(Liota.island,Liota.color,clWhite,0);
    end;
    ShowClubInfo;
  finally
    Details.DisableAutoRepaint(false)
  end;
end;

procedure TfrmQSODetails.ShowWAZInfo;
var
  index  : Integer;
begin
  if not cqrini.ReadBool('Zones','ShowWAZInfo',True) then
    exit;
  index := dmData.GetWAZInfoIndex(fwaz,ffreq);
  Lwaz.Text := dmData.GetWAZInfoString(index);
  case index of
    1 : Lwaz.Color := cqrini.ReadInteger('Zones','NewWAZ',0);
    2 : Lwaz.Color := cqrini.ReadInteger('Zones','NewBandWAZ',0);
    3 : Lwaz.Color := cqrini.ReadInteger('Zones','QSLWAZ',0);
    4 : Lwaz.Color := clBlack
  end;
  Details.AddLine(Lwaz.Text,Lwaz.Color,clWhite,0)
end;

procedure TfrmQSODetails.ShowITUInfo;
var
  index  : Integer;
begin
  if not cqrini.ReadBool('Zones','ShowITUInfo',True) then
    exit;
  index := dmData.GetITUInfoIndex(fITU,ffreq);
  Litu.Text := dmData.GetITUInfoString(index);
  case index of
    1 : Litu.Color := cqrini.ReadInteger('Zones','NewITU',0);
    2 : Litu.Color := cqrini.ReadInteger('Zones','NewBandITU',0);
    3 : Litu.Color := cqrini.ReadInteger('Zones','QSLITU',0);
    4 : Litu.Color := clBlack
  end;
  Details.AddLine(Litu.Text,Litu.Color,clWhite,0)
end;

procedure TfrmQSODetails.ShowIOTAInfo;
var
  index  : Integer;
begin
  if not dmUtils.IsIOTAOK(fiota) then
    exit;
  index := dmData.GetIOTAInfoIndex(fIOTA);
  Liota.island := dmData.GetIOTAName(fiota);
  Liota.Text   := dmData.GetIOTAInfoString(index);
  case index of
    1 : Liota.Color := cqrini.ReadInteger('IOTA','NewIOTA',0);
    2 : Liota.Color := cqrini.ReadInteger('IOTA','QSLIOTA',0);
    3 : Liota.Color := clBlack
  end; //case
  Details.AddLine(Liota.Text,Liota.color,clWhite,0);
  Details.AddLine(Liota.island,Liota.color,clWhite,0)
end;

procedure TfrmQSODetails.ShowClubInfo;
begin
  Details.DisableAutoRepaint(true);
  try
    if LClub1.Text <> '' then
    begin
      Details.AddLine(LClub1.Text,LClub1.Color,clWhite,0);
    end;
    if LClub2.Text <> '' then
    begin
      Details.AddLine(LClub2.Text,LClub2.Color,clWhite,0);
    end;
    if LClub3.Text <> '' then
    begin
      Details.AddLine(LClub3.Text,LClub3.Color,clWhite,0);
    end;
    if LClub4.Text <> '' then
    begin
      Details.AddLine(LClub4.Text,LClub4.Color,clWhite,0);
    end;
    if LClub5.Text <> '' then
    begin
      Details.AddLine(LClub5.Text,LClub5.Color,clWhite,0);
    end;
  finally
    Details.DisableAutoRepaint(false)
  end
end;


procedure TfrmQSODetails.ClearWAZ;
begin
  Lwaz.Text := '';
end;

procedure TfrmQSODetails.ClearITU;
begin
  Litu.Text := '';
end;

procedure TfrmQSODetails.ClearIOTA;
begin
  Liota.Text := '';
end;

procedure TfrmQSODetails.SetClub1(Data1 : String);
begin
  LClub1.Text := '';
  SetClub(data1,1);
  ShowInfo;
end;
procedure TfrmQSODetails.SetClub2(Data2 : String);
begin
  LClub2.Text := '';
  SetClub(data2,2);
  ShowInfo
end;
procedure TfrmQSODetails.SetClub3(Data3 : String);
begin
  LClub3.Text := '';
  SetClub(data3,3);
  ShowInfo;
end;
procedure TfrmQSODetails.SetClub4(Data4 : String);
begin
  LClub4.Text := '';
  SetClub(data4,4);
  ShowInfo;
end;
procedure TfrmQSODetails.SetClub5(Data5 : String);
begin
  LClub5.Text := '';
  SetClub(data5,5);
  ShowInfo;
end;

procedure TfrmQSODetails.SetClub(data : String;num : Integer);
var
  Club     : TClub;
  ClubInfo : ^TClubInfo;
  ClubTable : String = '';
  frmDate  : String = '';
  toDate   : String = '';
  ClubNR   : String = '';
  ClubCall : String = '';
begin
  if data = '' then
    exit;
  case num of
    1 : begin Club := dmData.Club1; ClubInfo := @LClub1 end;
    2 : begin Club := dmData.Club2; ClubInfo := @LClub2 end;
    3 : begin Club := dmData.Club3; ClubInfo := @LClub3 end;
    4 : begin Club := dmData.Club4; ClubInfo := @LClub4 end;
    5 : begin Club := dmData.Club5; ClubInfo := @LClub5 end
  end;
  if Club.Name = '' then
    exit;
  if Club.ClubField = '' then
    exit;
  ClubInfo^.Text := '';
  ClubTable := 'club'+IntToStr(num);
  dmData.Q.Close;
  if dmData.trQ.Active then
    dmData.trQ.Rollback;
  dmData.Q.SQL.Text := 'select * from '+ClubTable+ ' where '+ Club.ClubField +
                       ' = ' + QuotedStr(data) + ' and fromdate <= ' + QuotedStr(fClubDate) +
                       ' and todate >= '+QuotedStr(fClubDate);
  dmData.trQ.StartTransaction;
  try
    dmData.Q.Open();
    if (Trim(dmData.Q.Fields[0].AsString) = '') and (Trim(dmData.Q.Fields[1].AsString) = '') then  //this data is not in club database
      exit;

    ClubNR   := trim(dmData.Q.Fields[1].AsString);
    ClubCall := trim(dmData.Q.Fields[2].AsString);
    frmDate  := dmData.Q.Fields[3].AsString;
    toDate   := dmData.Q.Fields[4].AsString;

    Writeln('ClubNR:',ClubNR);
    case num of
      1 : fClubNR1 := ClubNR;
      2 : fClubNR2 := ClubNR;
      3 : fClubNR3 := ClubNR;
      4 : fClubNR4 := ClubNR;
      5 : fClubNR5 := ClubNR
    end;

    dmData.Q.Close;
    if (Club.NewInfo <> '') or (Club.StoreField <> '') then
    begin
      dmData.Q.SQL.Text := 'select id_cqrlog_main from cqrlog_main where club_nr'+ IntToStr(num) +
                           ' = '+QuotedStr(ClubNR) + ' and qsodate >= ' + QuotedStr(frmDate) +
                           ' and qsodate <= ' + QuotedStr(toDate) + ' and band = ' +
                           QuotedStr(dmUtils.GetBandFromFreq(ffreq)) + ' and mode = ' +
                           QuotedStr(fmode) + ' and qsl_r = '+QuotedStr('Q')+' LIMIT 1';
      dmData.Q.Open();
      if (dmData.Q.Fields[0].AsInteger > 0) then //already conf
      begin
        ClubInfo^.Text  := SetStoreText(ClubCall,ClubNR,Club.LongName,Club.Name,Club.AlreadyCfmInfo);
        ClubInfo^.Color := Club.AlreadyColor;
        frmNewQSO.StoreClubInfo(
          Club.StoreField,SetStoreText(ClubCall,ClubNR,Club.LongName,Club.Name,Club.StoreText)
        )
      end
      else begin
        dmData.Q.Close();
        dmData.Q.SQL.Text := 'select id_cqrlog_main from cqrlog_main where club_nr'+ IntToStr(num) +
                               ' = '+QuotedStr(ClubNR) + ' and qsodate >= ' + QuotedStr(frmDate) +
                               ' and qsodate <= ' + QuotedStr(toDate) + ' and band = ' +
                               QuotedStr(dmUtils.GetBandFromFreq(ffreq)) + 'and mode = ' +
                               QuotedStr(fmode)+' LIMIT 1';
        dmData.Q.Open();
        if (dmData.Q.Fields[0].AsInteger > 0) then //qsl needed
        begin
          ClubInfo^.Text  := SetStoreText(ClubCall,ClubNR,Club.LongName,Club.Name,Club.QSLNeededInfo);
          ClubInfo^.Color := Club.QSLColor;
          frmNewQSO.StoreClubInfo(
            Club.StoreField,SetStoreText(ClubCall,ClubNR,Club.LongName,Club.Name,Club.StoreText)
          );
          exit
        end
        else begin
          dmData.Q.Close();
          dmData.Q.SQL.Text := 'select id_cqrlog_main from cqrlog_main where club_nr'+ IntToStr(num) +
                               ' = '+QuotedStr(ClubNR) + ' and qsodate >= ' + QuotedStr(frmDate) +
                               ' and qsodate <= ' + QuotedStr(toDate) + ' and band = ' +
                               QuotedStr(dmUtils.GetBandFromFreq(ffreq)) + ' LIMIT 1';
          dmData.Q.Open();
          if (dmData.Q.Fields[0].AsInteger > 0) then //new mode
          begin
            ClubInfo^.Text  := SetStoreText(ClubCall,ClubNR,Club.LongName,Club.Name,Club.NewModeInfo);
            ClubInfo^.Color := Club.ModeColor;
            frmNewQSO.StoreClubInfo(
              Club.StoreField,SetStoreText(ClubCall,ClubNR,Club.LongName,Club.Name,Club.StoreText)
            )
          end
          else begin
            dmData.Q.Close();
            dmData.Q.SQL.Text := 'select id_cqrlog_main from cqrlog_main where club_nr'+ IntToStr(num) +
                                 ' = '+QuotedStr(ClubNR) + ' and qsodate >= ' + QuotedStr(frmDate) +
                                 ' and qsodate <= ' + QuotedStr(toDate) +' LIMIT 1';
            dmData.Q.Open();
            if (dmData.Q.Fields[0].AsInteger > 0) then //new band
            begin
              ClubInfo^.Text  := SetStoreText(ClubCall,ClubNR,Club.LongName,Club.Name,Club.NewBandInfo);
              ClubInfo^.Color := Club.BandColor;
              frmNewQSO.StoreClubInfo(
                Club.StoreField,SetStoreText(ClubCall,ClubNR,Club.LongName,Club.Name,Club.StoreText)
              )
            end
            else begin
              ClubInfo^.Text  := SetStoreText(ClubCall,ClubNR,Club.LongName,Club.Name,Club.NewInfo);
              ClubInfo^.Color := Club.NewColor;
              frmNewQSO.StoreClubInfo(
                Club.StoreField,SetStoreText(ClubCall,ClubNR,Club.LongName,Club.Name,Club.StoreText)
              )
            end
          end
        end
      end
    end
  finally
    dmData.trQ.RollBack
  end
end;

function TfrmQSODetails.SetStoreText(call,clubnr,long,short, StoreInfoText : String) : String;
begin
{
 %l - long club name
 %s - short club name
 %n - club number
 %c - callsign
}
  Result := StringReplace(StoreInfoText,'%l',long,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%s',short,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%n',clubnr,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,'%c',call,[rfReplaceAll, rfIgnoreCase]);
end;

end.

