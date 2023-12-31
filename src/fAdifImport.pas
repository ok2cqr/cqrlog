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
  Buttons, lcltype, ComCtrls, ExtCtrls, EditBtn, Menus, iniFiles, sqldb,
  dateutils, strutils, LazUTF8, RegExpr;

{$include uADIFhash.pas}

type
  TDateString = string[10]; //Date in yyyy-mm-dd format

type TnewQSOEntry=record   //represents a new qso entry in the log
      st:longint; // number of items added;
      BAND:string[l_BAND];
      CALL:string[l_CALL];
      CNTY:string[l_CNTY];
      COMMENT:string[l_COMMENT];
      CONT:string[l_CONT];
      DXCC:string[l_DXCC];
      EQSL_QSLRDATE:string[l_EQSL_QSLRDATE];
      EQSL_QSLSDATE:string[l_EQSL_QSLSDATE];
      EQSL_QSL_RCVD:string[l_EQSL_QSL_RCVD];
      EQSL_QSL_SENT:string[l_EQSL_QSL_SENT];
      FREQ:string[l_FREQ];
      GRIDSQUARE:string[l_GRIDSQUARE];
      IOTA:string[l_IOTA];
      ITUZ:string[l_ITUZ];
      LOTW_QSLRDATE:string[l_LOTW_QSLRDATE];
      LOTW_QSLSDATE:string[l_LOTW_QSLSDATE];
      LOTW_QSL_RCVD:string[l_LOTW_QSL_RCVD];
      LOTW_QSL_SENT:string[l_LOTW_QSL_SENT];
      MODE:string[l_MODE];
      SUBMODE:string[l_SUBMODE]; //we need this while processing cqrmode
      MY_GRIDSQUARE:string[l_MY_GRIDSQUARE];
      NAME:string[l_NAME];
      NOTES:string[l_NOTES];
      PFX:string[l_PFX];
      QSLMSG:string[l_QSLMSG];
      QSLRDATE:string[l_QSLRDATE];
      QSLSDATE:string[l_QSLSDATE];
      QSL_RCVD:string[l_QSL_RCVD];
      QSL_SENT:string[l_QSL_SENT];
      QSL_VIA:string[l_QSL_VIA];
      QSO_DATE:string[l_QSO_DATE];
      QTH:string[l_QTH];
      RST_RCVD:string[l_RST_RCVD];
      RST_SENT:string[l_RST_SENT];
      SRX:string[l_SRX];
      SRX_STRING:string[l_SRX_STRING];
      STX:string[l_STX];
      STX_STRING:string[l_STX_STRING];
      CONTEST_ID:string[l_CONTEST_ID];
      DARC_DOK:string[l_DARC_DOK];
      TIME_OFF:string[l_TIME_OFF];
      TIME_ON:string[l_TIME_ON];
      TX_PWR:string[l_TX_PWR];
      EOH:string[l_EOH];
      EOR:string[l_EOR];
      APP_CQRLOG_QSLS:string[l_APP_CQRLOG_QSLS];
      APP_CQRLOG_QSLR:string[l_APP_CQRLOG_QSLR];
      APP_CQRLOG_PROFILE:string[l_APP_CQRLOG_PROFILE];
      APP_CQRLOG_COUNTY:string[l_APP_CQRLOG_COUNTY];
      APP_CQRLOG_DXCC:string[l_APP_CQRLOG_DXCC];
      CQZ:string[l_CQZ];
      STATE:string[l_STATE];
      AWARD:string[l_AWARD];
      POWER:String[l_POWER];
      PROP_MODE : String[l_PROP_MODE];
      SAT_NAME : String[l_SAT_NAME];
      FREQ_RX  : String[l_FREQ_RX];
      OP:String[l_OP];
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
    mnuDelImport: TMenuItem;
    mnuedit: TMenuItem;
    mnuImport: TMenuItem;
    mnuDelete: TMenuItem;
    pnlAll: TPanel;
    pnlFilterDateRange: TPanel;
    popErrFile: TPopupMenu;
    Q1: TSQLQuery;
    Q2: TSQLQuery;
    Q3: TSQLQuery;
    Q4: TSQLQuery;
    sb: TStatusBar;
    tr: TSQLTransaction;
    procedure btnCloseClick(Sender: TObject);
    procedure chkFilterDateRangeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnImportClick(Sender: TObject);
    procedure lblErrorLogClick(Sender: TObject);
    procedure lblErrorLogMouseEnter(Sender: TObject);
    procedure mnuDeleteClick(Sender: TObject);
    procedure mnuDelImportClick(Sender: TObject);
    procedure mnueditClick(Sender: TObject);
    procedure mnuImportClick(Sender: TObject);
  private
    LocalDbg     : Boolean;
    AbortImport : boolean;
    ERR_FILE : String;
    Do_Err_Import : Boolean;
    CutErrText : String;
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
    function fillTypeVariableWithTagData(h:longint;var data:string;var D:TnewQSOEntry;adifTag:String):boolean;
    procedure initializeTypeVariable(var d:TnewQSOEntry);
    function saveNewEntryFromADIFinDatabase(var d:TnewQSOEntry; var err : String) : Boolean;
    function TrimDataLen(adifTag:String;adifdata:String;maxlen:integer): String;
    { private declarations }
  public
    function getNextAdifTag(var vstup,prik,data:string):boolean;
    procedure OpenInTextEditor(OtF:String);
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
    //if LocalDbg then Write('Got length:',DataLen);

    if z<>0 then
      prik:=trim(copy(aaa,1,z-1))
    else
      prik:=trim(copy(aaa,1,x-1));

    aaa:=copy(aaa,x+1,length(aaa));

    z:=pos('<',aaa);
    i:= pos('_INTL',upcase(prik));
    //if LocalDbg then Write(' pos INTL:',i);
    if z=0 then
    begin
      if i>0 then  //tags with '_intl' have UTF8 charactes
       Begin
        prik:= copy(prik,1,i-1); //remove '_INTL'
        data:=UTF8copy(aaa,1,DataLen);
        //if LocalDbg then Write(' as UTF8');
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
        //if LocalDbg then Write(' as UTF8');
       end
      else
        data:=copy(aaa,1,DataLen);
      vstup:=copy(aaa,z,length(aaa))
    end;
    data :=trim(data);
    //if LocalDbg then Writeln(' for tag:',prik,' with data:',data);
    getNextAdifTag:=true
  end;

function TfrmAdifImport.fillTypeVariableWithTagData(h:longint;var data:string;var D:TnewQSOEntry;adifTag:String):boolean;

  begin
    if (h=h_EOH) or (h=h_EOR) then begin
      fillTypeVariableWithTagData:=false;exit;
    end;

    fillTypeVariableWithTagData:=true;
    data := trim(data);

    case h of
    h_BAND                          :d.BAND:=UpperCase(TrimDataLen(adifTag,data,l_BAND));
    h_CALL                          :d.CALL:=UpperCase(TrimDataLen(adifTag,data,l_CALL));
    h_CNTY                          :d.CNTY:=TrimDataLen(adifTag,data,l_CNTY);
    h_COMMENT                       :d.COMMENT:=TrimDataLen(adifTag,data,l_COMMENT);
    h_CONT                          :d.CONT:=UpperCase(TrimDataLen(adifTag,data,l_CONT));
    h_DXCC                          :d.DXCC:=UpperCase(TrimDataLen(adifTag,data,l_DXCC));
    h_EQSL_QSLRDATE                 :d.EQSL_QSLRDATE:=TrimDataLen(adifTag,data,l_EQSL_QSLRDATE);
    h_EQSL_QSLSDATE                 :d.EQSL_QSLSDATE:=TrimDataLen(adifTag,data,l_EQSL_QSLSDATE);
    h_EQSL_QSL_RCVD                 :d.EQSL_QSL_RCVD:=TrimDataLen(adifTag,data,l_EQSL_QSL_RCVD);
    h_EQSL_QSL_SENT                 :d.EQSL_QSL_SENT:=TrimDataLen(adifTag,data,l_EQSL_QSL_SENT);
    h_FREQ                          :d.FREQ:=TrimDataLen(adifTag,data,l_FREQ);
    h_GRIDSQUARE                    :d.GRIDSQUARE:=dmUtils.StdFormatLocator(data);
    h_IOTA                          :d.IOTA:=UpperCase(TrimDataLen(adifTag,data,l_IOTA));
    h_ITUZ                          :d.ITUZ:=TrimDataLen(adifTag,data,l_ITUZ);
    h_LOTW_QSLRDATE                 :d.LOTW_QSLRDATE:=TrimDataLen(adifTag,data,l_LOTW_QSLRDATE);
    h_LOTW_QSLSDATE                 :d.LOTW_QSLSDATE:=TrimDataLen(adifTag,data,l_LOTW_QSLSDATE);
    h_LOTW_QSL_RCVD                 :d.LOTW_QSL_RCVD:=TrimDataLen(adifTag,data,l_LOTW_QSL_RCVD);
    h_LOTW_QSL_SENT                 :d.LOTW_QSL_SENT:=TrimDataLen(adifTag,data,l_LOTW_QSL_SENT);

    h_MODE                          :d.MODE    := UpperCase(TrimDataLen(adifTag,data,l_MODE));
    h_SUBMODE                       :d.SUBMODE := UpperCase(TrimDataLen(adifTag,data,l_SUBMODE));

    h_MY_GRIDSQUARE                 :d.MY_GRIDSQUARE:=dmUtils.StdFormatLocator(data);
    h_NAME                          :d.NAME:=TrimDataLen(adifTag,data,l_NAME);
    h_NOTES                         :d.NOTES:=TrimDataLen(adifTag,data,l_NOTES);
    h_PFX                           :d.PFX:=UpperCase(TrimDataLen(adifTag,data,l_PFX));
    h_QSLMSG                        :d.QSLMSG:=TrimDataLen(adifTag,data,l_QSLMSG);
    h_QSLRDATE                      :d.QSLRDATE:=TrimDataLen(adifTag,data,l_QSLRDATE);
    h_QSLSDATE                      :d.QSLSDATE:=TrimDataLen(adifTag,data,l_QSLSDATE);
    h_QSL_RCVD                      :d.QSL_RCVD:=TrimDataLen(adifTag,data,l_QSL_RCVD);
    h_QSL_SENT                      :d.QSL_SENT:=TrimDataLen(adifTag,data,l_QSL_SENT);
    h_QSL_VIA                       :d.QSL_VIA:=TrimDataLen(adifTag,data,l_QSL_VIA);
    h_QSO_DATE                      :d.QSO_DATE:=TrimDataLen(adifTag,data,l_QSO_DATE);
    h_QTH                           :d.QTH:=TrimDataLen(adifTag,data,l_QTH);
    h_RST_RCVD                      :d.RST_RCVD:=TrimDataLen(adifTag,data,l_RST_RCVD);
    h_RST_SENT                      :d.RST_SENT:=TrimDataLen(adifTag,data,l_RST_SENT);
    h_SRX                           :d.SRX:=TrimDataLen(adifTag,data,l_SRX);
    h_SRX_STRING                    :d.SRX_STRING:=TrimDataLen(adifTag,data,l_SRX_STRING);
    h_STX                           :d.STX:=TrimDataLen(adifTag,data,l_STX);
    h_STX_STRING                    :d.STX_STRING:=TrimDataLen(adifTag,data,l_STX_STRING);
    h_CONTEST_ID                    :d.CONTEST_ID:=TrimDataLen(adifTag,data,l_CONTEST_ID);
    h_DARC_DOK                      :d.DARC_DOK:=TrimDataLen(adifTag,data,l_DARC_DOK);
    h_TIME_OFF                      :d.TIME_OFF:=copy(data,1,4);//can be HHMMSS but cqrlog uses HHMM both
    h_TIME_ON                       :d.TIME_ON:=copy(data,1,4); //are valid adif forms so no Trim/Err here
    h_TX_PWR                        :d.TX_PWR:=TrimDataLen(adifTag,data,l_TX_PWR);
    h_APP_CQRLOG_DXCC               :d.APP_CQRLOG_DXCC:=TrimDataLen(adifTag,data,l_APP_CQRLOG_DXCC);
    h_APP_CQRLOG_QSLS               :d.APP_CQRLOG_QSLS:=TrimDataLen(adifTag,data,l_APP_CQRLOG_QSLS);
    h_APP_CQRLOG_PROFILE            :d.APP_CQRLOG_PROFILE:=TrimDataLen(adifTag,data,l_APP_CQRLOG_PROFILE);
    h_APP_CQRLOG_QSLR               :d.APP_CQRLOG_QSLR:=TrimDataLen(adifTag,data,l_APP_CQRLOG_QSLR);
    h_APP_CQRLOG_COUNTY             :d.APP_CQRLOG_COUNTY:=TrimDataLen(adifTag,data,l_APP_CQRLOG_COUNTY);
    h_CQZ                           :d.CQZ:=TrimDataLen(adifTag,data,l_CQZ);
    h_STATE                         :d.STATE:=UpperCase(TrimDataLen(adifTag,data,l_STATE));
    h_AWARD                         :d.AWARD:=TrimDataLen(adifTag,data,l_AWARD);
    h_PROP_MODE                     :d.PROP_MODE:=TrimDataLen(adifTag,data,l_PROP_MODE);
    h_SAT_NAME                      :d.SAT_NAME:=TrimDataLen(adifTag,data,l_SAT_NAME);
    h_FREQ_RX                       :d.FREQ_RX:=TrimDataLen(adifTag,data,l_FREQ_RX);
    h_OP                            :d.OP:=TrimDataLen(adifTag,data,l_OP);

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

    //convert mode and submode to cqrmode here
    d.MODE:=dmUtils.ModeToCqr(d.MODE,d.SUBMODE,LocalDbg);

         if (d.FREQ  = '') or (d.FREQ = '0') then
      d.FREQ := dmUtils.FreqFromBand(d.BAND,d.MODE);

    d.QSO_DATE      := dmUtils.ADIFDateToDate(d.QSO_DATE);
    if not IsQsoDateInRange then
    begin
      Inc(FFilteredOutRecNr);
      initializeTypeVariable(d);
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

    // d.IOTA  := Trim(d.IOTA); this has been trimmed at  fillTypeVariableWithTagData
    d.IOTA  := UpperCase(d.IOTA);
    //lengths now fixed in  fillTypeVariableWithTagData
    //d.NAME  := Copy(d.NAME, 1 ,40);
    //d.QTH   := Copy(d.QTH, 1, 60);
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

    if (not dmUtils.IsAdifOK(d.QSO_DATE,d.TIME_ON,d.TIME_OFF,d.CALL,d.FREQ,d.MODE,d.RST_SENT,
                            d.RST_RCVD,d.IOTA,d.ITUZ,d.CQZ,d.GRIDSQUARE,d.MY_GRIDSQUARE,
                            d.BAND,err)) then
    begin
      inc(WrongRecNr);
      lblErrors.Caption   := IntToStr(WrongRecNr);
      lblErrorLog.Caption := dmData.UsrHomeDir + ERR_FILE;
      lblErrorLog.Visible:=true;
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
          if LocalDbg then Writeln(Q4.SQL.Text);
          Q4.Open;
          if Q4.Fields[0].AsInteger = 0 then
          begin
            Q4.Close();
            Q4.SQL.Text := 'select nr from profiles where nr = '+pProf;
            if LocalDbg then Writeln(Q4.SQL.Text);
            Q4.Open();
            if (Q4.Fields[0].AsInteger > 0) then //if profile with this number doesnt exists,
            begin                           //we can save the number
              Q4.Close();
              Q4.SQL.Text := 'select max(nr) from profiles';
              if LocalDbg then Writeln(Q4.SQL.Text);
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
            if LocalDbg then Writeln(Q4.SQL.Text);
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

      if LocalDbg then
                  Writeln(dmData.Q.SQL.Text);
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
    if LocalDbg then Writeln(Q1.SQL.Text);
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

    if LocalDbg then Writeln(Q1.SQL.Text);
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
  if lblFileName.Caption='' then exit;
  CutErrText :='';
  AbortImport := false;
  lblComplete.Visible := False;
  GlobalProfile := dmData.GetNRFromProfile(cmbProfiles.Text);
  FMyPower := cqrini.ReadString('NewQSO', 'PWR', '5 W');
  // Read locator from selected profile
  FMyLoc   := dmData.GetMyLocFromProfile(cmbProfiles.Text);
  // If that failed use default configured locator
  if not dmUtils.IsLocOK(FMyLoc) then
     FMyLoc   := cqrini.ReadString('Station', 'LOC', '');
  if LocalDbg then WriteLn('Using '+FMyLoc+' as locator for imports');
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
        if ((h=h_EOH) or (h=h_EOR)) then
        begin
          if not saveNewEntryFromADIFinDatabase(d,ErrText) then
            WriteWrongADIF(tmp,ErrText);
          if (CutErrText<>'') and (h=h_EOR)then
              WriteWrongADIF(tmp,'Imported with shrink(s):'+#10+CutErrText);
          CutErrText:='';
          tmp:='';
        end;
        fillTypeVariableWithTagData(h,data,D,adifTag);
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
    if LocalDbg then WriteLn('It takes about ',m,' minutes and ',s,' seconds ',ms,' milliseconds');
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

procedure TfrmAdifImport.lblErrorLogClick(Sender: TObject);
Begin
   popErrFile.Popup;
end;
procedure TfrmAdifImport.OpenInTextEditor(OtF:String);
//open in text editor
var
  prg: string;
begin
  try
    prg := cqrini.ReadString('ExtView', 'txt', '');
    if prg<>'' then
      dmUtils.RunOnBackground(prg + ' ' + AnsiQuotedStr(OtF, '"'))
     else ShowMessage('No external text viewer defined!'+#10+'See: prefrences/External viewers');
  finally
   //done
  end;
end;

procedure TfrmAdifImport.mnueditClick(Sender: TObject);
begin
  popErrFile.Close;
  OpenInTextEditor(lblErrorLog.Caption);
end;

procedure TfrmAdifImport.mnuImportClick(Sender: TObject);
var
  tmp:Char;
begin
  popErrFile.Close;
  try
    tmp := FormatSettings.TimeSeparator;
    FormatSettings.TimeSeparator := '_';
    ERR_FILE := 'errors_'+TimeToStr(now)+'.adi'
  finally
    FormatSettings.TimeSeparator := tmp
  end;
  lblFileName.Caption:= lblErrorLog.Caption;
  lblErrorLog.Caption:='';
  lblCount.Caption :='';
  lblErrors.Caption := '';
  Do_Err_Import:=true;
  lblComplete.Visible := False;
end;

procedure TfrmAdifImport.mnuDeleteClick(Sender: TObject);
begin
  popErrFile.Close;
  if ( Application.MessageBox(pAnsiChar('Do you want to delete file'+#10+lblErrorLog.Caption) , 'Delete file ?',MB_ICONQUESTION + MB_YESNO) = IDYES) then
    Begin
      DeleteFile( lblErrorLog.Caption );
      lblErrorLog.Caption:=''
    end;
end;

procedure TfrmAdifImport.mnuDelImportClick(Sender: TObject);
begin
    popErrFile.Close;
     if ( Application.MessageBox(pAnsiChar('Do you want to delete file'+#10+lblFileName.Caption) , 'Delete file ?',MB_ICONQUESTION + MB_YESNO) = IDYES) then
    Begin
      DeleteFile(lblFileName.Caption);
      Do_Err_Import:=false;
      lblFileName.Caption:=''
    end;
end;

procedure TfrmAdifImport.lblErrorLogMouseEnter(Sender: TObject);
begin
     mnuDelImport.Visible:=Do_Err_Import;
     popErrFile.Popup;
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
  Do_Err_Import:=false;
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
  end;
  lblErrorLog.Visible:=false;
  //set debug rules for this form
  // bit 1, %1,  ---> -2 for routines in this form
  LocalDbg := dmData.DebugLevel >= 1 ;
  if dmData.DebugLevel < 0 then
      LocalDbg :=  LocalDbg or ((abs(dmData.DebugLevel) and 2) = 2 );
end;

procedure TfrmAdifImport.chkFilterDateRangeChange(Sender: TObject);
begin
  pnlFilterDateRange.Enabled := chkFilterDateRange.Checked;
  lblFilteredOut.Visible := chkFilterDateRange.Checked;
  lblFilteredOutCount.Visible := chkFilterDateRange.Checked;
end;

procedure TfrmAdifImport.btnCloseClick(Sender: TObject);
begin
  AbortImport:=true;
end;

procedure TfrmAdifImport.FormShow(Sender: TObject);
begin
  lblComplete.Visible := False;
  lblFilteredOut.Visible := chkFilterDateRange.Checked;
  lblFilteredOutCount.Visible := chkFilterDateRange.Checked;
  dmUtils.LoadFontSettings(self);
  Qasked:=false;
end;

function TfrmAdifImport.TrimDataLen(adiftag:String;adifdata:String;maxlen:integer):String;
Begin
 if length(adifdata)>maxlen then
     Begin
            CutErrText:=CutErrText + adiftag+' shrink to '+IntToStr(maxlen)+' chrs:'+adifdata+' -> '+copy(adifdata,1,maxlen)+#10;
            Result:= trim(copy(adifdata,1,maxlen)); //trim after cut
     end
   else
            Result:=adifdata; //trimmed before
end;


procedure TfrmAdifImport.WriteWrongADIF(lines : Array of String; error : String);
var
  f : TextFile;
  i : Integer;
begin
    for i:= 0 to Length(lines)-1 do
      if LocalDbg then WriteLn(lines[i]);

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
    Writeln(f);
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


