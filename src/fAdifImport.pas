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
  Buttons, lcltype, ComCtrls, iniFiles, sqldb, dateutils;

{$include uADIFhash.pas}

type Tnejakyzaznam=record
      st:longint; // pocet pridanych polozek;
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
      MODE:string[10];
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
     end;
type

  { TfrmAdifImport }

  TfrmAdifImport = class(TForm)
    btnImport: TButton;
    btnClose: TButton;
    chkLotOfQSO: TCheckBox;
    cmbProfiles: TComboBox;
    edtRemarks: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    lblErrorLog: TLabel;
    lblComplete: TLabel;
    lblCount: TLabel;
    lblErrors: TLabel;
    lblFileName: TLabel;
    Q1: TSQLQuery;
    Q2: TSQLQuery;
    Q3: TSQLQuery;
    Q4: TSQLQuery;
    sb: TStatusBar;
    tr: TSQLTransaction;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnImportClick(Sender: TObject);
  private
    ERR_FILE : String;
    WrongRecNr : Integer;
    RecNR      : Integer;
    GlobalProfile : Integer;
    NowDate : String;
    procedure WriteWrongADIF(lines : Array of String; error : String);

    function pochash(aaa:String):longint;
    function vratzaznam(var vstup,prik,data:string):boolean;
    function zpracuj(h:longint;var data:string;var D:Tnejakyzaznam):boolean;
    procedure smazzaznam(var d:Tnejakyzaznam);
    function novyzaznam(var d:Tnejakyzaznam; var err : String) : Boolean;

    { private declarations }
  public
    { public declarations }
  end; 

var
  frmAdifImport: TfrmAdifImport;

implementation

uses dData, dUtils, dDXCC, fMain, uMyIni, uVersion;

function TfrmAdifImport.pochash(aaa:String):longint;
var z,x:longint;
begin
  x:=0;
  for z:=1 to length(aaa) do
  begin
    x:=(x shl 3) + ord(upcase(aaa[z]));
    x:=x xor (x shr 16);
    x:=x and $FFFF;
  end;
  pochash:=x;
end;

function TfrmAdifImport.vratzaznam(var vstup,prik,data:string):boolean;
var z,x:longint;
    aaa:string;
    i : Integer;
    slen : String = '';
    DataLen : Word = 0;
  begin
    vratzaznam:=false;
    z:=pos('<',vstup);
    if z=0 then exit;// neni dalsi zaznam - mizim.

    aaa:=copy(vstup,z+1,length(vstup));
    z:=pos(':',aaa);
    x:=pos('>',aaa);
    if (x=0) then exit; // zaznam nebyl ukoncen ... mizim

    for i:=z+1 to x do
    begin
      if (aaa[i] in ['0'..'9']) then
        slen := slen + aaa[i]
    end;
    if slen = '' then
      DataLen := 0
    else
      DataLen := StrToInt(slen);

    if z<>0 then
      prik:=copy(aaa,1,z-1)
    else
      prik:=copy(aaa,1,x-1);

    aaa:=copy(aaa,x+1,length(aaa));

    z:=pos('<',aaa);
    if z=0 then
    begin
      data:=copy(aaa,1,DataLen);
      vstup:=''
    end
    else begin
        data:=copy(aaa,1,DataLen);
        vstup:=copy(aaa,z,length(aaa))
    end;
    vratzaznam:=true
  end;

function TfrmAdifImport.zpracuj(h:longint;var data:string;var D:Tnejakyzaznam):boolean;
  begin
    if (h=h_EOH) or (h=h_EOR) then begin zpracuj:=false;exit;end;
    zpracuj:=true;
    data := trim(data);
    case h of
      h_BAND:d.BAND:=data;
      h_CALL:d.CALL:=data;
      h_CNTY:d.CNTY:=data;
      h_COMMENT:d.COMMENT:=data;
      h_CONT:d.CONT:=data;
      h_DXCC:d.DXCC:=data;
      h_EQSL_QSLRDATE:d.EQSL_QSLRDATE:=data;
      h_EQSL_QSLSDATE:d.EQSL_QSLSDATE:=data;
      h_EQSL_QSL_RCVD:d.EQSL_QSL_RCVD:=data;
      h_EQSL_QSL_SENT:d.EQSL_QSL_SENT:=data;
      h_FREQ:d.FREQ:=data;
      h_GRIDSQUARE:d.GRIDSQUARE:=data;
      h_IOTA:d.IOTA:=data;
      h_ITUZ:d.ITUZ:=data;
      h_LOTW_QSLRDATE:d.LOTW_QSLRDATE:=data;
      h_LOTW_QSLSDATE:d.LOTW_QSLSDATE:=data;
      h_LOTW_QSL_RCVD:d.LOTW_QSL_RCVD:=data;
      h_LOTW_QSL_SENT:d.LOTW_QSL_SENT:=data;
      h_MODE:d.MODE:=data;
      h_MY_GRIDSQUARE:d.MY_GRIDSQUARE:=data;
      h_NAME:d.NAME:=data;
      h_NOTES:d.NOTES:=data;
      h_PFX:d.PFX:=data;
      h_QSLMSG:d.QSLMSG:=data;
      h_QSLRDATE:d.QSLRDATE:=data;
      h_QSLSDATE:d.QSLSDATE:=data;
      h_QSL_RCVD:d.QSL_RCVD:=data;
      h_QSL_SENT:d.QSL_SENT:=data;
      h_QSL_VIA:d.QSL_VIA:=data;
      h_QSO_DATE:d.QSO_DATE:=data;
      h_QTH:d.QTH:=data;
      h_RST_RCVD:d.RST_RCVD:=data;
      h_RST_SENT:d.RST_SENT:=data;
      h_SRX:d.SRX:=data;
      h_SRX_STRING:d.SRX_STRING:=data;
      h_STX:d.STX:=data;
      h_STX_STRING:d.STX_STRING:=data;
      h_TIME_OFF:d.TIME_OFF:=data;
      h_TIME_ON:d.TIME_ON:=data;
      h_TX_PWR:d.TX_PWR:=data;
      h_APP_CQRLOG_DXCC:d.APP_CQRLOG_DXCC:=data;
      h_APP_CQRLOG_QSLS:d.APP_CQRLOG_QSLS:=data;
      h_APP_CQRLOG_PROFILE:d.APP_CQRLOG_PROFILE:=data;
      h_APP_CQRLOG_QSLR:d.APP_CQRLOG_QSLR:=data;
      h_APP_CQRLOG_COUNTY:d.APP_CQRLOG_COUNTY:=data;
      h_CQZ:d.CQZ:=data;
      h_STATE:d.STATE:=data;
      h_AWARD:d.AWARD:=data
      else
        begin{ writeln('Neznam...>',pom,'<');zpracuj:=false;exit;}end;
    end;//case
    d.st:=d.st+1;
  end;


procedure TfrmAdifImport.smazzaznam(var d:Tnejakyzaznam);
  begin
    fillchar(d,sizeof(d),0);
  end;

function TfrmAdifImport.novyzaznam(var d:Tnejakyzaznam; var err : String) : Boolean;
var
  MyPower : String;
  MyLoc   : String;
  Lines   : Array of String;
  pAr : TExplodeArray;
  pProf : String;
  pLoc : String;
  pQTH : String;
  pEq  : String;
  pNote : String;
  First : Boolean = False;
  freq  : String = '';
  Band  : String;
  dxcc,id_waz,id_itu : String;
  tmp,mycont : String;
  profile    : String;
  dxcc_adif  : Integer;
  len        : Integer=0;
begin
  Result := True;
  if (d.st>0) and (d.CALL <> '') and (d.QSO_DATE <> '') then
  begin
    MyPower := cqrini.ReadString('NewQSO','PWR','5 W');
    MyLoc   := cqrini.ReadString('Station','LOC','');

    if not dmUtils.IsLocOK(d.MY_GRIDSQUARE) then
      d.MY_GRIDSQUARE := MyLoc;
    d.CALL := UpperCase(d.CALL);
    if (d.MODE = 'USB') or (d.MODE ='LSB') then
      d.MODE := 'SSB';
    if (d.FREQ  = '') or (d.FREQ = '0') then
      d.FREQ := dmUtils.FreqFromBand(d.BAND,d.MODE);

    d.QSO_DATE      := dmUtils.ADIFDateToDate(d.QSO_DATE);
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

    d.QSL_VIA := UpperCase(d.QSL_VIA);
    if Pos('QSL VIA',d.QSL_VIA) > 0 then
      d.QSL_VIA := copy(d.QSL_VIA,9,Length(d.QSL_VIA)-1);
    d.QSL_VIA := trim(d.QSL_VIA);
    if edtRemarks.Text <> '' then
      d.COMMENT := edtRemarks.Text + ' ' + d.COMMENT;
    if d.TX_PWR = '' then
      d.TX_PWR := MyPower;

    Writeln('d.TX_PWR:',d.TX_PWR);
    Writeln('MyPower: ',MyPower);

    d.MODE := UpperCase(d.MODE);

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
      smazzaznam(d);
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
    if First then
    begin
      First := False;
      dmData.Q.Close;
      dmData.Q.SQL.Text := 'SELECT COUNT(*) FROM cqrlog_main WHERE qsodate = ' + QuotedStr(d.QSO_DATE) +
                           ' AND time_on = ' + QuotedStr(d.TIME_ON) + ' AND callsign = '+QuotedStr(d.CALL);
      if dmData.DebugLevel >=1 then
      begin
        Writeln(dmData.Q.SQL.Text)
      end;
      if dmData.trQ.Active then
        dmData.trQ.Rollback;
      dmData.trQ.StartTransaction;
      dmData.Q.Open;
      if dmData.Q.Fields[0].AsInteger > 0 then
      begin
        if Application.MessageBox('It looks like this QSOs are in the log.'#13'Do you really want to inport it again?',
                                  'Question',MB_ICONQUESTION + MB_YESNO) = idNo then
        begin
          btnImport.Enabled := True;
          dmData.Q.Close();
          dmData.trQ.Rollback;
          exit
        end
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
                   'eqsl_qslrdate,eqsl_qsl_rcvd) values('+
                   ':qsodate,:time_on,:time_off,:callsign,:freq,:mode,:rst_s,:rst_r,:name,:qth,'+
                   ':qsl_s,:qsl_r,:qsl_via,:iota,:pwr,:itu,:waz,:loc,:my_loc,:remarks,:county,:adif,'+
                   ':idcall,:award,:band,:state,:cont,:profile,:lotw_qslsdate,:lotw_qsls,:lotw_qslrdate,'+
                   ':lotw_qslr,:qsls_date,:qslr_date,:eqsl_qslsdate,:eqsl_qsl_sent,:eqsl_qslrdate,'+
                   ':eqsl_qsl_rcvd)';
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
    Q1.Params[15].AsString  := d.ITUZ;
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
    Writeln(1);
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
    Writeln(2);
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
    Writeln(3);
    if dmUtils.IsDateOK(d.QSLSDATE) then
      Q1.Params[32].AsString  := d.QSLSDATE
    else
      Q1.Params[32].Clear;
    if dmUtils.IsDateOK(d.QSLRDATE) then
      Q1.Params[33].AsString  := d.QSLRDATE
    else
      Q1.Params[33].Clear;
    Writeln(4);
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
        Writeln(5);
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
    if dmData.DebugLevel >=1 then Writeln(Q1.SQL.Text);
    Q1.ExecSQL;
    inc(RecNR);
    lblCount.Caption := IntToStr(RecNR);
    if (RecNR mod 100 = 0) then
    begin
      Repaint;
      Application.ProcessMessages
    end
  end;
  smazzaznam(d)
end;

procedure TfrmAdifImport.btnImportClick(Sender: TObject);
var
  sou:textfile;
  aaa,prik,data:String;
  h:longint;
  D:Tnejakyzaznam;
  err : Boolean = False;
  dt : TDateTime;
  hh,m,s,ms : Word;
  ErrText : String = '';
  tmp : String='';
begin
  lblComplete.Visible := False;
  GlobalProfile := dmData.GetNRFromProfile(cmbProfiles.Text);
  RecNR := 0;
  WrongRecNr := 0;
  try try
    system.assign(sou,lblFileName.Caption);
    system.reset(sou);
    smazzaznam(d);
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
    while not eof(sou) do
    begin
      readln(sou,aaa);
      if Pos('<EOH>',UpperCase(aaa)) > 0 then
        tmp := ''
      else
        tmp := tmp + aaa;
      while vratzaznam(aaa,prik,data) do
      begin
        h:=pochash(prik);
        if (h=h_EOH) or (h=h_EOR) then
        begin
          if not novyzaznam(d,ErrText) then
            WriteWrongADIF(tmp,ErrText);
          tmp:=''
        end;
        zpracuj(h,data,d)
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
    closeFile(sou);
    if not err then
      tr.Commit;
    dt := dt - now;
    DecodeTime(dt,hh,m,s,ms);
    WriteLn('It takes about ',m,' minutes and ',s,' seconds ',ms,' milliseconds');
    if chkLotOfQSO.Checked then
    begin
      sb.Panels[0].Text := 'Recreating indexes ...';
      Application.ProcessMessages;
      Repaint;
      dmData.DoAfterImport
    end;
    sb.Panels[0].Text := 'Done ...';
    lblComplete.Visible := True
  end
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

procedure TfrmAdifImport.FormShow(Sender: TObject);
begin
  lblComplete.Visible := False;
  dmUtils.LoadFontSettings(self)
end;

procedure TfrmAdifImport.WriteWrongADIF(lines : Array of String; error : String);
var
  f : TextFile;
  i : Integer;
begin
    for i:= 0 to Length(lines)-1 do
      WriteLn(lines[i]);

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
    Writeln(f,'<ADIF_VER:5>2.2.1');
    Writeln(f,'ADIF export from CQRLOG for Linux version ' + dmData.VersionString);
    Writeln(f,'Copyright (C) ',YearOf(now),' by Petr, OK2CQR and Martin, OK1RR');
    Writeln(f,'Internet: http://www.cqrlog.com');
    Writeln(f,'');
    Writeln(f,'ERROR QSOs FROM ADIF IMPORT');
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


initialization
{$I fAdifImport.lrs}

end.

