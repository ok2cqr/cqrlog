(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fAdifImport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, lcltype, ComCtrls, ExtCtrls, EditBtn, iniFiles, sqldb, dateutils,
  strutils, LazUTF8, RegExpr;

{$include uADIFhash.pas}

type
  TDateString = string[10]; //Date in yyyy-mm-dd format

type TnewQSOEntry=record   //represents a new qso entry in the log
      st:longint; // number of items added;
      BAND:string[10];
      CALL:string[30];
      CNTY:string[50];
      COMMENT:string[250];
      CONT:string[2];
      DXCC:string[16];
      EQSL_QSLRDATE:string[10];
      EQSL_QSLSDATE:string[10];
      EQSL_QSL_RCVD:string[2];
      EQSL_QSL_SENT:string[2];
      FREQ:string[12];
      GRIDSQUARE:string[6];
      IOTA:string[6];
      ITUZ:string[2];
      LOTW_QSLRDATE:string[10];
      LOTW_QSLSDATE:string[10];
      LOTW_QSL_RCVD:string[2];
      LOTW_QSL_SENT:string[2];
      MODE:string[12];
      MY_GRIDSQUARE:string[6];
      NAME:string[50];
      NOTES:string[250];
      PFX:string[16];
      QSLMSG:string[250];
      QSLRDATE:string[10];
      QSLSDATE:string[10];
      QSL_RCVD:string[5];
      QSL_SENT:string[5];
      QSL_VIA:string[20];
      QSO_DATE:string[10];
      QTH:string[250];
      RST_RCVD:string[6];
      RST_SENT:string[6];
      SRX:string[6];
      SRX_STRING:string[250];
      STX:string[6];
      STX_STRING:string[250];
      CONTEST_ID:string[250];
      DARC_DOK:string[12];
      TIME_OFF:string[5];
      TIME_ON:string[5];
      TX_PWR:string[5];
      EOH:string[250];
      EOR:string[250];
      APP_CQRLOG_QSLS:string[4];
      APP_CQRLOG_QSLR:string[4];
      APP_CQRLOG_PROFILE:string[250];
      APP_CQRLOG_COUNTY:string[250];
      APP_CQRLOG_DXCC:string[16];
      CQZ:string[3];
      STATE:string[3];
      AWARD:string[250];
      POWER:String[10];
      PROP_MODE : String[30];
      SAT_NAME : String[30];
      FREQ_RX  : String[30];
      OP:String[30];
     end;
type

  { TfrmAdifImport }

  TfrmAdifImport = class(TForm)
    btnClose: TButton;
    btnImport: TButton;
    chkOverrideLocator: TCheckBox;
    chkRemember: TCheckBox;
    chkFilterDateRange: TCheckBox;
    chkLotOfQSO: TCheckBox;
    chkNoCheckOnDuplicates: TCheckBox;
    cmbProfiles: TComboBox;
    edtDateFrom: TDateEdit;
    edtDateTo: TDateEdit;
    edtRemarks: TEdit;
    lbFile: TLabel;
    lblComplete: TLabel;
    lblCount: TLabel;
    lblDateFrom: TLabel;
    lblError: TLabel;
    lblErrorLog: TLabel;
    lblErrors: TLabel;
    lblFileName: TLabel;
    lblFilteredOut: TLabel;
    lblFilteredOutCount: TLabel;
    lblImport: TLabel;
    lblDateTo: TLabel;
    lblQthProfile: TLabel;
    lblRemaks: TLabel;
    pnlAll: TPanel;
    pnlFilterDateRange: TPanel;
    Q1: TSQLQuery;
    Q2: TSQLQuery;
    Q3: TSQLQuery;
    Q4: TSQLQuery;
    sb: TStatusBar;
    tr: TSQLTransaction;
    procedure chkFilterDateRangeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnImportClick(Sender: TObject);
  private
    AbortImport : boolean;
    ERR_FILE : String;
    WrongRecNr : Integer;
    RecNR      : Integer;
    GlobalProfile : Integer;
    FMyPower: String;
    FMyLoc: String;
    NowDate : String;
    FFilteredOutRecNr: integer;
    FFilterByDate: boolean;
    FFilterDateRange: array [0..1] of TDateString;
    function ValidateFilter: boolean;
    procedure WriteWrongADIF(lines : Array of String; error : String);

    function generateAdifTagHash(aaa:String):longint;
    function fillTypeVariableWithTagData(h:longint;var data:string;var D:TnewQSOEntry):boolean;
    procedure initializeTypeVariable(var d:TnewQSOEntry);
    function saveNewEntryFromADIFinDatabase(var d:TnewQSOEntry; var err : String) : Boolean;

    { private declarations }
  public
    function getNextAdifTag(var vstup,prik,data:string):boolean;
    { public declarations }
  end; 

var
  frmAdifImport: TfrmAdifImport;
  Qvalue : integer;
  Qasked : boolean;

implementation
{$R *.lfm}

uses dData, dUtils, dDXCC, fMain, uMyIni, uVersion;

resourcestring
  INVALID_DATE_RANGE_ENTERED = 'Invalid date range is entered';


function TfrmAdifImport.generateAdifTagHash(aaa:String):longint;
var z,x:longint;
begin
  x:=0;
  for z:=1 to length(aaa) do
  begin
    x:=(x shl 3) + ord(upcase(aaa[z]));
    x:=x xor (x shr 16);
    x:=x and $FFFF;
  end;
  generateAdifTagHash:=x;
end;

function TfrmAdifImport.getNextAdifTag(var vstup,prik,data:string):boolean;
// vstup - remaining text have to be searched for next tag
// prik - deliveres back the extracted ADIF tag name
// data - deliveres back the extracted ADIF information of the tag

var z,x:longint;
    aaa:string;
    i : Integer;
    slen : String = '';
    DataLen : Word = 0;
  begin
    getNextAdifTag:=false;
    z:=pos('<',vstup);
    if z=0 then exit;//  there is no other record - disappearing.

    aaa:=copy(vstup,z+1,length(vstup));
    z:=pos(':',aaa);
    x:=pos('>',aaa);
    if (x=0) then exit; //  the record was not terminated ... disappearing

    //detect length of ADIF Data
    for i:=z+1 to x do
    begin
      if (aaa[i] in ['0'..'9']) then
        slen := slen + aaa[i]
    end;
    if slen = '' then
      DataLen := 0
    else
      DataLen := StrToInt(slen);
    //if dmData.DebugLevel >=1 then Write('Got length:',DataLen);

    if z<>0 then
      prik:=trim(copy(aaa,1,z-1))
    else
      prik:=trim(copy(aaa,1,x-1));

    aaa:=copy(aaa,x+1,length(aaa));

    z:=pos('<',aaa);
    i:= pos('_INTL',upcase(prik));
    //if dmData.DebugLevel >=1 then Write(' pos INTL:',i);
    if z=0 then
    begin
      if i>0 then  //tags with '_intl' have UTF8 charactes
       Begin
        prik:= copy(prik,1,i-1); //remove '_INTL'
        data:=UTF8copy(aaa,1,DataLen);
        //if dmData.DebugLevel >=1 then Write(' as UTF8');
       end
      else
        data:=copy(aaa,1,DataLen);
      vstup:=''
    end
    else begin
      if i>0 then  //tags with '_intl' have UTF8 charactes
       Begin
        prik:= copy(prik,1,i-1); //remove '_INTL'
        data:=UTF8copy(aaa,1,DataLen);
        //if dmData.DebugLevel >=1 then Write(' as UTF8');
       end
      else
        data:=copy(aaa,1,DataLen);
      vstup:=copy(aaa,z,length(aaa))
    end;
    data :=trim(data);
    //if dmData.DebugLevel >=1 then Writeln(' for tag:',prik,' with data:',data);
    getNextAdifTag:=true
  end;

function TfrmAdifImport.fillTypeVariableWithTagData(h:longint;var data:string;var D:TnewQSOEntry):boolean;
  begin
    if (h=h_EOH) or (h=h_EOR) then begin
      fillTypeVariableWithTagData:=false;exit;
    end;
    fillTypeVariableWithTagData:=true;
    data := trim(data);
    case h of
      h_BAND                          :d.BAND:=data;
      h_CALL                          :d.CALL:=data;
      h_CNTY                          :d.CNTY:=data;
      h_COMMENT                       :d.COMMENT:=data;
      h_CONT                          :d.CONT:=data;
      h_DXCC                          :d.DXCC:=data;
      h_EQSL_QSLRDATE                 :d.EQSL_QSLRDATE:=data;
      h_EQSL_QSLSDATE                 :d.EQSL_QSLSDATE:=data;
      h_EQSL_QSL_RCVD                 :d.EQSL_QSL_RCVD:=data;
      h_EQSL_QSL_SENT                 :d.EQSL_QSL_SENT:=data;
      h_FREQ                          :d.FREQ:=data;
      h_GRIDSQUARE                    :d.GRIDSQUARE:=dmUtils.StdFormatLocator(data);
      h_IOTA                          :d.IOTA:=data;
      h_ITUZ                          :d.ITUZ:=data;
      h_LOTW_QSLRDATE                 :d.LOTW_QSLRDATE:=data;
      h_LOTW_QSLSDATE                 :d.LOTW_QSLSDATE:=data;
      h_LOTW_QSL_RCVD                 :d.LOTW_QSL_RCVD:=data;
      h_LOTW_QSL_SENT                 :d.LOTW_QSL_SENT:=data;
      // DL7OAP: because MODE-field in cqrlog database does not match completely
      // with MODE field of ADIF specification, we have to transfer the
      // ADIF MODES/SUBMODES (JS8, FT4, FST4,PKT) to MODE-field in cqrlog database
      h_MODE                          : begin
                                          if data = 'PKT' then d.MODE:='PACKET'
                                          else d.MODE:=data
                                        end;
      h_SUBMODE                       : begin
                                          if data = 'FT4' then d.MODE:=data;
                                          if data = 'FST4' then d.MODE:=data;
                                          if data = 'JS8' then d.MODE:=data
                                        end;
      h_MY_GRIDSQUARE                   :d.MY_GRIDSQUARE:=dmUtils.StdFormatLocator(data);
      h_NAME                            :d.NAME:=data;
      h_NOTES                           :d.NOTES:=data;
      h_PFX                             :d.PFX:=data;
      h_QSLMSG                          :d.QSLMSG:=data;
      h_QSLRDATE                        :d.QSLRDATE:=data;
      h_QSLSDATE                        :d.QSLSDATE:=data;
      h_QSL_RCVD                        :d.QSL_RCVD:=data;
      h_QSL_SENT                        :d.QSL_SENT:=data;
      h_QSL_VIA                         :d.QSL_VIA:=data;
      h_QSO_DATE                        :d.QSO_DATE:=data;
      h_QTH                             :d.QTH:=data;
      h_RST_RCVD                        :d.RST_RCVD:=data;
      h_RST_SENT                        :d.RST_SENT:=data;
      h_SRX                             :d.SRX:=data;
      h_SRX_STRING                      :d.SRX_STRING:=data;
      h_STX                             :d.STX:=data;
      h_STX_STRING                      :d.STX_STRING:=data;
      h_CONTEST_ID                      :d.CONTEST_ID:=data;
      h_DARC_DOK                        :d.DARC_DOK:=data;
      h_TIME_OFF                        :d.TIME_OFF:=data;
      h_TIME_ON                         :d.TIME_ON:=data;
      h_TX_PWR                          :d.TX_PWR:=data;
      h_APP_CQRLOG_DXCC                 :d.APP_CQRLOG_DXCC:=data;
      h_APP_CQRLOG_QSLS                 :d.APP_CQRLOG_QSLS:=data;
      h_APP_CQRLOG_PROFILE              :d.APP_CQRLOG_PROFILE:=data;
      h_APP_CQRLOG_QSLR                 :d.APP_CQRLOG_QSLR:=data;
      h_APP_CQRLOG_COUNTY               :d.APP_CQRLOG_COUNTY:=data;
      h_CQZ                             :d.CQZ:=data;
      h_STATE                           :d.STATE:=data;
      h_AWARD                           :d.AWARD:=data;
      h_PROP_MODE                       :d.PROP_MODE:=data;
      h_SAT_NAME                        :d.SAT_NAME:=data;
      h_FREQ_RX                         :d.FREQ_RX:=data;
      h_OP                              :d.OP:=data
    else begin
        { writeln('Unnamed...>',pom,'<');fillTypeVariableWithTagData:=false;exit;}
      end;
    end;//case
    d.st:=d.st+1;
  end;


procedure TfrmAdifImport.initializeTypeVariable(var d:TnewQSOEntry);
// fills the type with 0 values
begin
  fillchar(d,sizeof(d),0);
end;


function TfrmAdifImport.saveNewEntryFromADIFinDatabase(var d:TnewQSOEntry; var err : String) : Boolean;
var
  Lines   : Array of String;
  pAr : TExplodeArray;
  pProf : String;
  pLoc : String;
  pQTH : String;
  pEq  : String;
  pNote : String;
  freq  : String = '';
  Band  : String;
  dxcc,id_waz,id_itu : String;
  tmp,mycont : String;
  profile    : String;
  dxcc_adif  : Integer;
  len        : Integer=0;
  RxFreq : Double = 0;

  function IsQsoDateInRange: boolean;
  begin
    Result := (not FFilterByDate) or
      ((FFilterDateRange[0] <= d.QSO_DATE) and (d.QSO_DATE <= FFilterDateRange[1]));
  end;

begin
  Result := True;
  if (d.st>0) and (d.CALL <> '') and (d.QSO_DATE <> '') then
  begin
    //filling and optimize data in variable d
    if (not dmUtils.IsLocOK(d.MY_GRIDSQUARE)) or chkOverrideLocator.Checked then
      d.MY_GRIDSQUARE := FMyLoc;
    d.CALL := UpperCase(d.CALL);
    if (d.MODE = 'USB') or (d.MODE ='LSB') then
      d.MODE := 'SSB';
    if (d.FREQ  = '') or (d.FREQ = '0') then
      d.FREQ := dmUtils.FreqFromBand(d.BAND,d.MODE);

    d.QSO_DATE      := dmUtils.ADIFDateToDate(d.QSO_DATE);
    if not IsQsoDateInRange then
    begin
      Inc(FFilteredOutRecNr);
      exit;
    end;
    d.LOTW_QSLSDATE := dmUtils.ADIFDateToDate(d.LOTW_QSLSDATE);
    d.LOTW_QSLRDATE := dmUtils.ADIFDateToDate(d.LOTW_QSLRDATE);
    d.QSLSDATE      := dmUtils.ADIFDateToDate(d.QSLSDATE);
    d.QSLRDATE      := dmUtils.ADIFDateToDate(d.QSLRDATE);
    d.EQSL_QSLSDATE := dmUtils.ADIFDateToDate(d.EQSL_QSLSDATE);
    d.EQSL_QSLRDATE := dmUtils.ADIFDateToDate(d.EQSL_QSLRDATE);

    d.TIME_ON := copy(d.TIME_ON,1,2) + ':' + copy(d.TIME_ON,3,2);
    if d.TIME_OFF <> '' then
      d.TIME_OFF := copy(d.TIME_OFF,1,2) + ':' + copy(d.TIME_OFF,3,2)
    else
      d.TIME_OFF := d.TIME_ON;

    if ((d.MODE='CW') and (d.RST_SENT='')) then
      d.RST_SENT := '599';
    if ((d.MODE='CW') and (d.RST_RCVD='')) then
      d.RST_RCVD := '599';

    if d.APP_CQRLOG_QSLS <> '' then
      d.QSL_SENT := d.APP_CQRLOG_QSLS
    else begin
      if d.QSL_SENT = 'Y' then
        d.QSL_SENT := 'B'
      else
        d.QSL_SENT := ''
    end;
    if d.APP_CQRLOG_QSLR <> '' then
      d.QSL_RCVD := d.APP_CQRLOG_QSLR
    else begin
      if d.QSL_RCVD = 'Y' then
        d.QSL_RCVD := 'Q'
      else
        d.QSL_RCVD := ''
    end;

    d.IOTA  := Trim(d.IOTA);
    d.IOTA  := UpperCase(d.IOTA);
    d.NAME  := Copy(d.NAME, 1 ,40);
    d.QTH   := Copy(d.QTH, 1, 60);
    //workaround for 'TRegExpr exec: empty input string' error in fpc compiler
    if (trim(d.DARC_DOK) <> '') then
    begin
      d.DARC_DOK := ReplaceRegExpr('Ø', d.DARC_DOK, '0', True);
      d.DARC_DOK := LeftStr(Uppercase(ReplaceRegExpr('[^a-zA-Z0-9]',d.DARC_DOK, '', True)), 12);
    end;
    d.QSL_VIA := UpperCase(d.QSL_VIA);
    if Pos('QSL VIA',d.QSL_VIA) > 0 then
      d.QSL_VIA := copy(d.QSL_VIA,9,Length(d.QSL_VIA)-1);
    d.QSL_VIA := trim(d.QSL_VIA);
    if edtRemarks.Text <> '' then
      d.COMMENT := edtRemarks.Text + ' ' + d.COMMENT;
    if d.TX_PWR = '' then
      d.TX_PWR := FMyPower;
    d.COMMENT := copy(d.COMMENT, 1, 200);

    d.MODE := UpperCase(d.MODE);

    d.OP := UpperCase(d.OP);

    if not dmUtils.IsAdifOK(d.QSO_DATE,d.TIME_ON,d.TIME_OFF,d.CALL,d.FREQ,d.MODE,d.RST_SENT,
                            d.RST_RCVD,d.IOTA,d.ITUZ,d.CQZ,d.GRIDSQUARE,d.MY_GRIDSQUARE,
                            d.BAND,err) then
    begin
      inc(WrongRecNr);
      lblErrors.Caption   := IntToStr(WrongRecNr);
      lblErrorLog.Caption := dmData.UsrHomeDir + ERR_FILE;
      Repaint;
      Application.ProcessMessages;
      Result := False;
      SetLength(Lines,0);
      initializeTypeVariable(d);
      exit
    end;

    if GlobalProfile > 0 then
    begin
       profile := IntToStr(GlobalProfile)
    end
    else begin
      if d.APP_CQRLOG_PROFILE <> '' then
      begin
        pAr := dmUtils.Explode('|',d.APP_CQRLOG_PROFILE);
        len := Length(pAr);
        if pAr[0] <> '0' then
        begin
          pProf := pAr[0];
          profile := pAr[0];
          if len > 2 then
            pLoc  := pAr[1];
          if Len > 3 then
            pQTH  := pAr[2];
          if len > 4 then
            pEq   := pAr[3];
          if len > 5 then
            pNote := pAr[4];

          Q4.Close;
          Q4.SQL.Text := 'SELECT nr FROM profiles WHERE locator='+QuotedStr(pLoc) +
                         ' and qth='+QuotedStr(pQTH)+' and rig='+QuotedStr(pEq) +
                         ' and remarks='+QuotedStr(pNote);
          if dmData.DebugLevel >=1 then Writeln(Q4.SQL.Text);
          Q4.Open;
          if Q4.Fields[0].AsInteger = 0 then
          begin
            Q4.Close();
            Q4.SQL.Text := 'select nr from profiles where nr = '+pProf;
            if dmData.DebugLevel >=1 then Writeln(Q4.SQL.Text);
            Q4.Open();
            if (Q4.Fields[0].AsInteger > 0) then //if profile with this number doesnt exists,
            begin                           //we can save the number
              Q4.Close();
              Q4.SQL.Text := 'select max(nr) from profiles';
              if dmData.DebugLevel >=1 then Writeln(Q4.SQL.Text);
              Q4.Open();
              pProf := IntToStr(Q4.Fields[0].AsInteger+1)
            end;
            Q4.Close;
            Q4.SQL.Text := 'insert into profiles (nr,locator,qth,rig,remarks,visible) values ('+
                           ':nr,:locator,:qth,:rig,:remarks,:visible)';
            Q4.Prepare;
            Q4.Params[0].AsString  := pProf;
            Q4.Params[1].AsString  := pLoc;
            Q4.Params[2].AsString  := pQTH;
            Q4.Params[3].AsString  := pEq;
            Q4.Params[4].AsString  := pNote;
            Q4.Params[5].AsInteger := 1;

            {
            Q4.SQL.Text := 'insert into profiles (nr,locator,qth,rig,remarks,visible) values (' +
                           pProf+','+QuotedStr(pLoc)+','+QuotedStr(pQTH)+','+QuotedStr(pEq)+','+
                           QuotedStr(pNote)+',1)';
            }
            if dmData.DebugLevel >=1 then Writeln(Q4.SQL.Text);
            Q4.ExecSQL;
            Q4.Close();
          end
        end
        else
          profile := '0'
      end
      else
        profile := '0'
    end;

    // begin proof if qso allready exist in log
    if Not chkNoCheckOnDuplicates.Checked then
    begin
      dmData.Q.Close;
      dmData.Q.SQL.Text := 'SELECT COUNT(*) FROM cqrlog_main WHERE qsodate = ' + QuotedStr(d.QSO_DATE) +
                           ' AND time_on = ' + QuotedStr(d.TIME_ON) + ' AND callsign = '+QuotedStr(d.CALL)+
                           ' AND band = ' + QuotedStr(d.BAND) + ' AND mode = '+QuotedStr(d.MODE);

      if dmData.DebugLevel >=1 then Writeln(dmData.Q.SQL.Text);
      if dmData.trQ.Active then
        dmData.trQ.Rollback;
      dmData.trQ.StartTransaction;
      dmData.Q.Open;
      if dmData.Q.Fields[0].AsInteger > 0 then
      begin
        tmp:= d.QSO_DATE+' '+d.TIME_ON+' '+d.CALL+' '+d.BAND+' '+d.MODE+
              #13'It looks like this QSO is in the log.'#13'Do you really want to import it again?';
        if not chkRemember.Checked then
             Qvalue:= Application.MessageBox(Pchar(tmp),'Question',MB_ICONQUESTION +  MB_YESNOCANCEL)
          else
          if not Qasked then
              begin
                Qvalue:= Application.MessageBox(Pchar(tmp),'Question',MB_ICONQUESTION +  MB_YESNOCANCEL);
                Qasked := true;
              end;

        case Qvalue of
        idNo        :begin
                      btnImport.Enabled := True;
                      dmData.Q.Close();
                      dmData.trQ.Rollback;
                      exit;
                     end;
        idCancel    :begin
                      btnImport.Enabled := True;
                      dmData.Q.Close();
                      dmData.trQ.Rollback;
                      AbortImport :=true;
                      exit;
                     end;
        end;
        tmp:='';
      end;
      dmData.Q.Close();
      dmData.trQ.Rollback
    end;

    if Pos(',',d.FREQ) > 0 then
      d.FREQ[Pos(',',d.FREQ)] := '.';
    freq := FormatFloat('0.0000;;',StrToFloat(d.FREQ));
    band := dmUtils.GetBandFromFreq(d.FREQ);

    dxcc_adif := dmDXCC.id_country(d.CALL,d.STATE,dmUtils.StrToDateFormat(d.QSO_DATE),dxcc,mycont,tmp,id_waz,tmp,id_itu,tmp,tmp);
    if d.CQZ = '' then
      d.CQZ := id_waz;
    if d.ITUZ = '' then
      d.ITUZ := id_itu;
    if (d.CONT = '') or (d.CONT<>'EU') or (d.CONT<>'AS') or (d.CONT<>'AF') or (d.CONT<>'NA') or (d.CONT<>'SA') or
       (d.CONT <> 'OC') or (d.CONT<>'AN') then
       d.CONT := mycont;

    if d.NOTES <> '' then
      dmData.SaveComment(d.CALL,d.NOTES);

    Q1.SQL.Text := 'insert into cqrlog_main (qsodate,time_on,time_off,callsign,freq,mode,'+
                   'rst_s,rst_r,name,qth,qsl_s,qsl_r,qsl_via,iota,pwr,itu,waz,loc,my_loc,'+
                   'remarks,county,adif,idcall,award,band,state,cont,profile,lotw_qslsdate,lotw_qsls,'+
                   'lotw_qslrdate,lotw_qslr,qsls_date,qslr_date,eqsl_qslsdate,eqsl_qsl_sent,'+
                   'eqsl_qslrdate,eqsl_qsl_rcvd, prop_mode, satellite, rxfreq, stx, srx, stx_string,'+
                   'srx_string, contestname, dok, operator) values('+
                   ':qsodate,:time_on,:time_off,:callsign,:freq,:mode,:rst_s,:rst_r,:name,:qth,'+
                   ':qsl_s,:qsl_r,:qsl_via,:iota,:pwr,:itu,:waz,:loc,:my_loc,:remarks,:county,:adif,'+
                   ':idcall,:award,:band,:state,:cont,:profile,:lotw_qslsdate,:lotw_qsls,:lotw_qslrdate,'+
                   ':lotw_qslr,:qsls_date,:qslr_date,:eqsl_qslsdate,:eqsl_qsl_sent,:eqsl_qslrdate,'+
                   ':eqsl_qsl_rcvd, :prop_mode, :satellite, :rxfreq, :stx, :srx, :stx_string, :srx_string,'+
                   ':contestname,:dok,:operator)';
    if dmData.DebugLevel >=1 then Writeln(Q1.SQL.Text);
    Q1.Prepare;
    Q1.Params[0].AsString   := d.QSO_DATE;
    Q1.Params[1].AsString   := d.TIME_ON;
    Q1.Params[2].AsString   := d.TIME_OFF;
    Q1.Params[3].AsString   := d.CALL;
    Q1.Params[4].AsFloat    := StrToFloat(freq);
    Q1.Params[5].AsString   := d.MODE;
    Q1.Params[6].AsString   := d.RST_SENT;
    Q1.Params[7].AsString   := d.RST_RCVD;
    Q1.Params[8].AsString   := d.NAME;
    Q1.Params[9].AsString   := d.QTH;
    Q1.Params[10].AsString  := d.QSL_SENT;
    Q1.Params[11].AsString  := d.QSL_RCVD;
    Q1.Params[12].AsString  := d.QSL_VIA;
    Q1.Params[13].AsString  := d.IOTA;
    Q1.Params[14].AsString  := d.TX_PWR;

    if (d.ITUZ = '') then
      Q1.Params[15].Clear
    else
      Q1.Params[15].AsString  := d.ITUZ;

    if (d.CQZ = '') then
      Q1.Params[16].Clear
    else
      Q1.Params[16].AsString  := d.CQZ;

    Q1.Params[17].AsString  := d.GRIDSQUARE;
    Q1.Params[18].AsString  := d.MY_GRIDSQUARE;
    Q1.Params[19].AsString  := d.COMMENT;
    Q1.Params[20].AsString  := d.CNTY;
    Q1.Params[21].AsInteger := dxcc_adif;
    Q1.Params[22].AsString  := dmUtils.GetIDCall(d.CALL);
    Q1.Params[23].AsString  := d.AWARD;
    Q1.Params[24].AsString  := band;
    Q1.Params[25].AsString  := d.STATE;
    Q1.Params[26].AsString  := UpperCase(d.CONT);
    Q1.Params[27].AsInteger := StrToInt(profile);
    if dmUtils.IsDateOK(d.LOTW_QSLSDATE) then
    begin
      Q1.Params[28].AsString  := d.LOTW_QSLSDATE;
      Q1.Params[29].AsString  := 'Y'
    end
    else begin
      if d.LOTW_QSL_SENT = 'Y' then
      begin
        Q1.Params[28].AsString  := NowDate;
        Q1.Params[29].AsString  := 'Y'
      end
      else begin
        Q1.Params[28].Clear;
        Q1.Params[29].AsString := ''
      end
    end;
    if dmUtils.IsDateOK(d.LOTW_QSLRDATE) then
    begin
      Q1.Params[30].AsString  := d.LOTW_QSLRDATE;
      Q1.Params[31].AsString  := 'L'
    end
    else begin
      if d.LOTW_QSL_RCVD = 'Y' then
      begin
        Q1.Params[30].AsString  := NowDate;
        Q1.Params[31].AsString  := 'L'
      end
      else begin
        Q1.Params[30].Clear;
        Q1.Params[31].AsString  := ''
      end
    end;
    if dmUtils.IsDateOK(d.QSLSDATE) then
      Q1.Params[32].AsString  := d.QSLSDATE
    else
      Q1.Params[32].Clear;
    if dmUtils.IsDateOK(d.QSLRDATE) then
      Q1.Params[33].AsString  := d.QSLRDATE
    else
      Q1.Params[33].Clear;
    if dmUtils.IsDateOK(d.EQSL_QSLSDATE) then
    begin
      Q1.Params[34].AsString  := d.EQSL_QSLSDATE;
      Q1.Params[35].AsString  := 'Y'
    end
    else begin
      if (d.EQSL_QSL_SENT = 'Y') then
      begin
        Q1.Params[34].AsString := NowDate;
        Q1.Params[35].AsString := 'Y';
      end
      else begin
        Q1.Params[34].Clear;
        Q1.Params[35].AsString  := ''
      end
    end;
    if dmUtils.IsDateOK(d.EQSL_QSLRDATE) then
    begin
      Q1.Params[36].AsString  := d.EQSL_QSLRDATE;
      Q1.Params[37].AsString  := 'E'
    end
    else begin
      if (d.EQSL_QSL_RCVD='Y') then
      begin
        Q1.Params[36].AsString := NowDate;
        Q1.Params[37].AsString := 'E';
      end
      else begin
        Q1.Params[36].Clear;
        Q1.Params[37].AsString  := ''
      end
    end;
    Q1.Params[38].AsString := d.PROP_MODE;
    Q1.Params[39].AsString := d.SAT_NAME;
    if TryStrToFloat(d.FREQ_RX, RxFreq) then
      Q1.Params[40].AsFloat := RxFreq
    else
      Q1.Params[40].AsFloat := 0;

    Q1.Params[41].AsString := d.STX;
    Q1.Params[42].AsString := d.SRX;
    Q1.Params[43].AsString := d.STX_STRING;
    Q1.Params[44].AsString := d.SRX_STRING;
    Q1.Params[45].AsString := d.CONTEST_ID;
    Q1.Params[46].AsString := d.DARC_DOK;
    if (d.OP <> '') then
      Q1.Params[47].AsString := d.OP
    else
      Q1.Params[47].Clear;

    if dmData.DebugLevel >=1 then Writeln(Q1.SQL.Text);
    Q1.ExecSQL;
    inc(RecNR);
    if (RecNR mod 100 = 0) then
    begin
      lblCount.Caption := IntToStr(RecNR);
      Repaint;
      Application.ProcessMessages
    end
  end;
  initializeTypeVariable(d)
end;

procedure TfrmAdifImport.btnImportClick(Sender: TObject);
var
  textFileIn:textfile;         //the ADIF file
  oneTextRow,adifTag,data:String;
  h:longint;
  D:TnewQSOEntry;
  err : Boolean = False;
  dt : TDateTime;
  hh,m,s,ms : Word;
  ErrText : String = '';
  tmp : String='';
begin
  AbortImport := false;
  lblComplete.Visible := False;
  GlobalProfile := dmData.GetNRFromProfile(cmbProfiles.Text);
  FMyPower := cqrini.ReadString('NewQSO', 'PWR', '5 W');
  // Read locator from selected profile
  FMyLoc   := dmData.GetMyLocFromProfile(cmbProfiles.Text);
  // If that failed use default configured locator
  if not dmUtils.IsLocOK(FMyLoc) then
     FMyLoc   := cqrini.ReadString('Station', 'LOC', '');
  if dmData.DebugLevel >=1 then WriteLn('Using '+FMyLoc+' as locator for imports');
  RecNR := 0;
  WrongRecNr := 0;
  FFilteredOutRecNr := 0;
  if not ValidateFilter then
    exit;
  try try
    system.assign(textFileIn,lblFileName.Caption);
    system.reset(textFileIn);
    initializeTypeVariable(d);
    if chkLotOfQSO.Checked then
    begin
      sb.Panels[0].Text := 'Deleting indexes ...';
      Application.ProcessMessages;
      Repaint;
      dmData.PrepareImport
    end;
    dt := now;
    tr.StartTransaction;
    sb.Panels[0].Text := 'Importing data ...';
    Application.ProcessMessages;
    Repaint;
    while not eof(textFileIn) and not (AbortImport)do
    begin
      readln(textFileIn,oneTextRow);
      if Pos('<EOH>',UpperCase(oneTextRow)) > 0 then
        tmp := ''
      else
        tmp := tmp + oneTextRow;
      while getNextAdifTag(oneTextRow,adifTag,data) and not (AbortImport) do
      begin
        h:=generateAdifTagHash(adifTag);
        if (h=h_EOH) or (h=h_EOR) then
        begin
          if not saveNewEntryFromADIFinDatabase(d,ErrText) then
            WriteWrongADIF(tmp,ErrText);
          tmp:=''
        end;
        fillTypeVariableWithTagData(h,data,d)
      end;
    end
  except
    on E : Exception do
    begin
      err := True;
      Writeln('Import failed! ',E.Message);
      tr.Rollback;
      exit
    end
  end
  finally
    closeFile(textFileIn);
    if not err then
      tr.Commit;
    dt := dt - now;
    DecodeTime(dt,hh,m,s,ms);
    if dmData.DebugLevel >=1 then WriteLn('It takes about ',m,' minutes and ',s,' seconds ',ms,' milliseconds');
    lblCount.Caption := IntToStr(RecNR);
    lblFilteredOut.Visible := FFilterByDate;
    lblFilteredOutCount.Visible := FFilterByDate;
    lblFilteredOutCount.Caption := IntToStr(FFilteredOutRecNr);
    if chkLotOfQSO.Checked then
    begin
      sb.Panels[0].Text := 'Recreating indexes ...';
      Application.ProcessMessages;
      Repaint;
      dmData.DoAfterImport
    end;
    sb.Panels[0].Text := 'Done ...';
    Qasked:=false;
    lblComplete.Visible := True
  end;
end;


function TfrmAdifImport.ValidateFilter: boolean;
begin
  Result := true;
  FFilterByDate := chkFilterDateRange.Checked;
  if FFilterByDate then
  begin
    FFilterDateRange[0] := IfThen(edtDateFrom.Date <> NullDate, dmUtils.MyDateToStr(edtDateFrom.Date));
    FFilterDateRange[1] := IfThen(edtDateTo.Date <> NullDate, dmUtils.MyDateToStr(edtDateTo.Date));
    if not ((Length(FFilterDateRange[0]) > 0) and (Length(FFilterDateRange[1]) > 0) and
      (FFilterDateRange[0] <= FFilterDateRange[1])) then
    begin
      MessageDlg(Caption, INVALID_DATE_RANGE_ENTERED, mtError, [mbOK], 0);
      Result := false;
    end;
  end;
end;

procedure TfrmAdifImport.FormCreate(Sender: TObject);
var
  tmp : Char;
begin
  NowDate := dmUtils.MyDateToStr(now);

  Q1.DataBase := dmData.MainCon;
  Q2.DataBase := dmData.MainCon;
  Q3.DataBase := dmData.MainCon;
  Q4.DataBase := dmData.MainCon;
  tr.DataBase := dmData.MainCon;

  dmData.InsertProfiles(cmbProfiles,False);
  cmbProfiles.Text := dmData.GetDefaultProfileText;
  try
    tmp := FormatSettings.TimeSeparator;
    FormatSettings.TimeSeparator := '_';
    ERR_FILE := 'errors_'+TimeToStr(now)+'.adi'
  finally
    FormatSettings.TimeSeparator := tmp
  end
end;

procedure TfrmAdifImport.chkFilterDateRangeChange(Sender: TObject);
begin
  pnlFilterDateRange.Enabled := chkFilterDateRange.Checked;
  lblFilteredOut.Visible := chkFilterDateRange.Checked;
  lblFilteredOutCount.Visible := chkFilterDateRange.Checked;
end;

procedure TfrmAdifImport.FormShow(Sender: TObject);
begin
  lblComplete.Visible := False;
  lblFilteredOut.Visible := chkFilterDateRange.Checked;
  lblFilteredOutCount.Visible := chkFilterDateRange.Checked;
  dmUtils.LoadFontSettings(self);
  Qasked:=false;
end;

procedure TfrmAdifImport.WriteWrongADIF(lines : Array of String; error : String);
var
  f : TextFile;
  i : Integer;
begin
    for i:= 0 to Length(lines)-1 do
      if dmData.DebugLevel >=1 then WriteLn(lines[i]);

  if FileExists(dmData.UsrHomeDir + ERR_FILE) then
  begin
    AssignFile(f,dmData.UsrHomeDir + ERR_FILE);
    Append(f);
    for i:= 0 to Length(lines)-1 do
      WriteLn(f,lines[i]);
    Writeln(f,'ERROR: ',error);
    writeln(f);
    CloseFile(f)
  end
  else begin
    AssignFile(f,dmData.UsrHomeDir + ERR_FILE);
    Rewrite(f);
    Writeln(f,'ADIF export from CQRLOG for Linux version ' + dmData.VersionString);
    Writeln(f,'Copyright (C) ',YearOf(now),' by Petr, OK2CQR and Martin, OK1RR');
    Writeln(f,'Internet: http://www.cqrlog.com');
    Writeln(f,'');
    Writeln(f,'ERROR QSOs FROM ADIF IMPORT');
    Writeln(f,'<ADIF_VER:5>3.1.0');
    Writeln(f,'<CREATED_TIMESTAMP:15>',FormatDateTime('YYYYMMDD hhmmss',dmUtils.GetDateTime(0)));
    Writeln(f, '<PROGRAMID:6>CQRLOG');
    Writeln(f, '<PROGRAMVERSION:',Length(cVERSION),'>',cVERSION);
    Writeln(f,'');
    Writeln(f,'<EOH>');

    for i:= 0 to Length(lines)-1 do
      WriteLn(f,lines[i]);
    Writeln(f,'ERROR: ',error);
    writeln(f);
    CloseFile(f)
  end
end;

end.


