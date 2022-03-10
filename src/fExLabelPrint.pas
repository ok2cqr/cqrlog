unit fExLabelPrint;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, iniFiles, lcltype;


const
  C_SEP = ',';
  C_REP = ';';

type

  { TfrmExLabelPrint }

  TfrmExLabelPrint = class(TForm)
    btnExport: TButton;
    btnHelp: TButton;
    btnExportFieldsPref : TButton;
    Cancel: TButton;
    chkKeepCsvStructure: TCheckBox;
    chkRemoveSep: TCheckBox;
    chkAllQSOs: TCheckBox;
    chkMarkSent: TCheckBox;
    edtRemarks: TEdit;
    edtQSOsToLabel: TEdit;
    edtBrowse: TButton;
    edtFile: TEdit;
    gchkExport: TCheckGroup;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    lblProgress: TLabel;
    rbQSORemarks: TRadioButton;
    rbOwnRemarks: TRadioButton;
    dlgSave: TSaveDialog;
    procedure btnExportFieldsPrefClick(Sender : TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure chkAllQSOsChange(Sender: TObject);
    procedure edtBrowseClick(Sender: TObject);
    procedure edtQSOsToLabelExit(Sender: TObject);
    procedure edtRemarksEnter(Sender: TObject);
  private
    procedure LoadDataToTempDB;

    function  GetExpFieldCount : Word;
    function  Rep(what : String) : String;
  public
    { public declarations }
  end; 

var
  frmExLabelPrint: TfrmExLabelPrint;

implementation
{$R *.lfm}

uses dUtils, dData, uMyIni, fQSLExpPref, dDXCC,fMain, dLOgUpload;
{ TfrmExLabelPrint }

procedure TfrmExLabelPrint.edtQSOsToLabelExit(Sender: TObject);
var
  nr : Integer;
begin
  if not TryStrToInt(edtQSOsToLabel.Text, nr) then
    edtQSOsToLabel.Text := '100'
  else begin
    if not ((nr > 0) and (nr<100)) then
      edtQSOsToLabel.Text := '100'
  end
end;

procedure TfrmExLabelPrint.FormShow(Sender: TObject);
begin
  edtFile.Text := cqrini.ReadString('QslExport','Path',dmData.DataDir+'qsl.csv');
  dlgSave.InitialDir := ExtractFilePath(edtFile.Text);
  gchkExport.Checked[0] := True;
  gchkExport.Checked[2] := True;
  gchkExport.Checked[4] := True;
  edtQSOsToLabel.Text   := cqrini.ReadString('QslExport','QSOs','6');
  edtRemarks.Text       := cqrini.ReadString('QslExport','Remarks','');
  chkRemoveSep.Checked  := cqrini.ReadBool('QslExport','RemoveSep',True);
  chkKeepCsvStructure.Checked := cqrini.ReadBool('QSLExport', 'KeepCsvStructure', False);

  if edtRemarks.Text <> '' then
    rbOwnRemarks.Checked
end;


function TfrmExLabelPrint.GetExpFieldCount : Word;
begin
  Result := 0;
  if cqrini.ReadBool('QSLExport', 'Date', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'time_on', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'time_off', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'CallSign', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'Mode', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'Freq', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'RST_S', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'RST_R', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'Name', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'QTH', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'band', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'Propagation', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'Satellite',  True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'ContestName',  True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'QSL_S', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'QSL_R', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'QSL_VIA', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'locator', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'MyLoc', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'IOTA', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'award', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'power', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'Remarks', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'QSLMsg', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'ContestNrS', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'ContestMsgS', True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'ContestNrR',  True) then
    inc(Result);
  if cqrini.ReadBool('QSLExport', 'ContestMsgR',  True) then
    inc(Result);
end;

function TfrmExLabelPrint.Rep(what : String) : String;
begin
  Result := StringReplace(what,C_SEP, C_REP,[rfReplaceAll])
end;

procedure TfrmExLabelPrint.LoadDataToTempDB;
var
  DoExp   : Boolean;
  qsl_msg : String;
  qsl_via : String;
begin
  dmData.qCQRLOG.DisableControls;
  try
    if dmData.trQ.Active then dmData.trQ.Rollback;
    dmData.trQ.StartTransaction;
    dmData.Q.Close;
    dmData.Q.SQL.Text := 'insert into qslexport (idcall,id_cqrlog_main,dxcc,qsodate,time_on,time_off,callsign,freq,mode,rst_s,rst_r, '+
                         'name,qth,qsl_s,qsl_r,qsl_via,iota,pwr,loc,my_loc,award,remarks,band,qslmsg,prop_mode,satellite,'+
                         'contestname,stx,stx_string,srx,srx_string) values('+
                         ':idcall,:id_cqrlog_main,:dxcc,:qsodate,:time_on,:time_off,:callsign,:freq,:mode,:rst_s,:rst_r,:name,'+
                         ':qth,:qsl_s,:qsl_r,:qsl_via,:iota,:pwr,:loc,:my_loc,:award,:remarks,:band,:qslmsg,:prop_mode,:satellite,'+
                         ':contestname,:stx,:stx_string,:srx,:srx_string)';
    if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
    dmData.qCQRLOG.First;
    while not dmData.qCQRLOG.Eof do
    begin

      DoExp := False;
      if chkAllQSOs.Checked then
        DoExp := True
      else begin
        if (dmData.qCQRLOG.Fields[11].AsString = 'SB')  and (gchkExport.Checked[0]) then
          DoExp := True;
        if (dmData.qCQRLOG.Fields[11].AsString = 'SD')  and (gchkExport.Checked[1]) then
          DoExp := True;
        if (dmData.qCQRLOG.Fields[11].AsString = 'SM')  and (gchkExport.Checked[2]) then
          DoExp := True;
        if (dmData.qCQRLOG.Fields[11].AsString = 'SMD') and (gchkExport.Checked[3]) then
          DoExp := True;
        if (dmData.qCQRLOG.Fields[11].AsString = 'SMB') and (gchkExport.Checked[4]) then
          DoExp := True
      end;

      if (not DoExp) or (dmData.qCQRLOG.FieldByName('band').AsString='') then
      begin
        dmData.qCQRLOG.Next;
        Continue
      end;

      dmData.Q.Prepare;

      dmData.Q.ParamByName('id_cqrlog_main').AsInteger := dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger;

      //if QSOs are imported from other source they may not have QSLmgr set even it exists
      //then we look from cqrlog's manager database before making label
      if dmData.qCQRLOG.FieldByName('qsl_via').AsString='' then
         dmData.QSLMgrFound(dmData.qCQRLOG.FieldByName('callsign').AsString,
                            dmData.qCQRLOG.FieldByName('qsodate').AsString,
                            qsl_via)
       else
         qsl_via := dmData.qCQRLOG.FieldByName('qsl_via').AsString;

      if dmUtils.IsQSLViaValid(qsl_via) then
      begin
        dmData.Q.ParamByName('idcall').AsString  := dmUtils.GetIDCall(qsl_via);
        dmData.Q.ParamByName('dxcc').AsString    := dmDXCC.id_country(dmData.Q.ParamByName('idcall').AsString,
                                                                     dmData.qCQRLOG.FieldByName('qsodate').AsDateTime);
        dmData.Q.ParamByName('qsl_via').AsString := qsl_via
      end
      else begin
        qsl_via := '';
        dmData.Q.ParamByName('idcall').AsString  := dmUtils.GetIDCall(dmData.qCQRLOG.FieldByName('callsign').AsString);
        dmData.Q.ParamByName('dxcc').AsString    := dmDXCC.id_country(dmData.Q.ParamByName('idcall').AsString,
                                                                     dmData.qCQRLOG.FieldByName('qsodate').AsDateTime);
        dmData.Q.ParamByName('qsl_via').AsString := qsl_via
      end;
      //if dmData.Q.ParamByName('idcall').AsString = dmData.Q.ParamByName('qsl_via').AsString;


      if (dmData.qCQRLOG.FieldByName('qsl_r').AsString='Q') then
        qsl_msg := 'TNX'
      else
        qsl_msg := 'PSE';

      if rbQSORemarks.Checked then
      begin
        if chkRemoveSep.Checked then
          dmData.Q.ParamByName('remarks').AsString  := Rep(dmData.qCQRLOG.FieldByName('remarks').AsString)
        else
          dmData.Q.ParamByName('remarks').AsString  := dmData.qCQRLOG.FieldByName('remarks').AsString
      end
      else
        dmData.Q.ParamByName('remarks').AsString  := edtRemarks.Text;

      dmData.Q.ParamByName('qsodate').AsDateTime  := dmData.qCQRLOG.FieldByName('qsodate').AsDateTime;
      dmData.Q.ParamByName('time_on').AsString    := dmData.qCQRLOG.FieldByName('time_on').AsString;
      dmData.Q.ParamByName('time_off').AsString   := dmData.qCQRLOG.FieldByName('time_off').AsString;
      dmData.Q.ParamByName('callsign').AsString   := dmData.qCQRLOG.FieldByName('callsign').AsString;
      dmData.Q.ParamByName('freq').AsFloat        := dmData.qCQRLOG.FieldByName('freq').AsFloat;
      dmData.Q.ParamByName('mode').AsString       := dmData.qCQRLOG.FieldByName('mode').AsString;
      dmData.Q.ParamByName('rst_s').AsString      := dmData.qCQRLOG.FieldByName('rst_s').AsString;
      dmData.Q.ParamByName('rst_r').AsString      := dmData.qCQRLOG.FieldByName('rst_r').AsString;
      dmData.Q.ParamByName('name').AsString       := Rep(dmData.qCQRLOG.FieldByName('name').AsString);
      dmData.Q.ParamByName('qth').AsString        := Rep(dmData.qCQRLOG.FieldByName('qth').AsString);
      dmData.Q.ParamByName('qsl_s').AsString      := dmData.qCQRLOG.FieldByName('qsl_s').AsString;
      dmData.Q.ParamByName('qsl_r').AsString      := dmData.qCQRLOG.FieldByName('qsl_r').AsString;
      dmData.Q.ParamByName('iota').AsString       := dmData.qCQRLOG.FieldByName('iota').AsString;
      dmData.Q.ParamByName('pwr').AsString        := dmData.qCQRLOG.FieldByName('pwr').AsString;
      dmData.Q.ParamByName('loc').AsString        := Copy(dmData.qCQRLOG.FieldByName('loc').AsString, 1, 6);
      dmData.Q.ParamByName('my_loc').AsString     := dmData.qCQRLOG.FieldByName('my_loc').AsString;
      dmData.Q.ParamByName('award').AsString      := Rep(dmData.qCQRLOG.FieldByName('award').AsString);
      dmData.Q.ParamByName('band').AsString       := dmData.qCQRLOG.FieldByName('band').AsString;
      dmData.Q.ParamByName('qslmsg').AsString     := Rep(qsl_msg);
      dmData.Q.ParamByName('prop_mode').AsString  := dmData.qCQRLOG.FieldByName('prop_mode').AsString;
      dmData.Q.ParamByName('satellite').AsString  := dmData.qCQRLOG.FieldByName('satellite').AsString;
      dmData.Q.ParamByName('contestname').AsString := dmData.qCQRLOG.FieldByName('contestname').AsString;
      dmData.Q.ParamByName('stx').AsString        := dmData.qCQRLOG.FieldByName('stx').AsString;
      dmData.Q.ParamByName('stx_string').AsString := dmData.qCQRLOG.FieldByName('stx_string').AsString;
      dmData.Q.ParamByName('srx').AsString        := dmData.qCQRLOG.FieldByName('srx').AsString;
      dmData.Q.ParamByName('srx_string').AsString := dmData.qCQRLOG.FieldByName('srx_string').AsString;
      dmData.Q.ExecSQL;
      dmData.qCQRLOG.Next
    end
  finally
    dmData.trQ.Commit;
    dmData.qCQRLOG.EnableControls
  end;

end;

procedure TfrmExLabelPrint.btnExportClick(Sender: TObject);
var
  f      : TextFile;
  mycall : String = '';
  old    : String = '';
  lNr    : Integer = 0;
  MaxQ   : Integer;
  i      : Integer;
  qsl_s  : String = '';
  qso_nr : Int64 = 0;
  FieldCount : Integer;
  y          : Integer;
  sep     : Char;
  rst_tmp : String;

  procedure WriteDataToFile;
  begin
    /// Use selected date format in frmQSLExpPref
    /// tom@dl7bj.de, 2014-06-09
    if cqrini.ReadBool('QSLExport', 'Date', True) then
    begin
      if cqrini.ReadInteger('QSLExport', 'DateFormat',0) = 0 then
        Write(f,dmUtils.MyDateToStr(dmData.Q.FieldByName('qsodate').AsDateTime),C_SEP);
      if cqrini.ReadInteger('QSLExport', 'DateFormat',0) = 1 then
        Write(f,FormatDateTime('yyyy-mmm-dd',dmData.Q.FieldByName('qsodate').AsDateTime),C_SEP);
      if cqrini.ReadInteger('QSLExport', 'DateFormat',0) = 2 then
        Write(f,FormatDateTime('dd.mm.yyyy',dmData.Q.FieldByName('qsodate').AsDateTime),C_SEP);
      if cqrini.ReadInteger('QSLExport', 'DateFormat',0) = 3 then
        Write(f,FormatDateTime('dd mmm yyyy',dmData.Q.FieldByName('qsodate').AsDateTime),C_SEP);
      if cqrini.ReadInteger('QSLExport', 'DateFormat',0) = 4 then
        Write(f,FormatDateTime('dd-mmm-yyyy',dmData.Q.FieldByName('qsodate').AsDateTime),C_SEP);
      if cqrini.ReadInteger('QSLExport', 'DateFormat',0) = 5 then
      begin
        sep := FormatSettings.DateSeparator;
        FormatSettings.DateSeparator:='/';
        Write(f,FormatDateTime('yyyy/mm/dd',dmData.Q.FieldByName('qsodate').AsDateTime),C_SEP);
        FormatSettings.DateSeparator:=sep;
      end;
      if cqrini.ReadInteger('QSLExport', 'DateFormat',0) = 6 then
      begin
        sep := FormatSettings.DateSeparator;
        FormatSettings.DateSeparator:='/';
        Write(f,FormatDateTime('yyyy/mmm/dd',dmData.Q.FieldByName('qsodate').AsDateTime),C_SEP);
        FormatSettings.DateSeparator:=sep;
      end;
      if cqrini.ReadInteger('QSLExport', 'DateFormat',0) = 7 then
      begin
        sep := FormatSettings.DateSeparator;
        FormatSettings.DateSeparator:='/';
        Write(f,FormatDateTime('mm/dd/yyyy',dmData.Q.FieldByName('qsodate').AsDateTime),C_SEP);
        FormatSettings.DateSeparator:=sep;
      end;
    end
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'time_on', True) then
      Write(f,dmData.Q.FieldByName('time_on').AsString,C_SEP)
    else
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    if cqrini.ReadBool('QSLExport', 'time_off', True) then
      Write(f,dmData.Q.FieldByName('time_off').AsString,C_SEP)
    else
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    if cqrini.ReadBool('QSLExport', 'CallSign', True) then
      Write(f,dmData.Q.FieldByName('callsign').AsString,C_SEP)
    else
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    if cqrini.ReadBool('QSLExport', 'Mode', True) then
      Write(f,dmData.Q.FieldByName('mode').AsString,C_SEP)
    else
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    if cqrini.ReadBool('QSLExport', 'Freq', True) then
      Write(f,FormatFloat('0.0000;;',dmData.Q.FieldByName('freq').AsFloat),C_SEP)
    else
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);

    if cqrini.ReadBool('QSLExport', 'RST_S', True) then
    begin
      if not cqrini.ReadBool('QSLExport','SplitRST_S',False) then
      begin
        Write(f,dmData.Q.FieldByName('rst_s').AsString,C_SEP)
      end
      else begin
        rst_tmp := dmData.Q.FieldByName('rst_s').AsString + '   ';
        Write(f,rst_tmp[1],C_SEP);
        Write(f,rst_tmp[2],C_SEP);
        Write(f,rst_tmp[3],C_SEP);
      end;
    end
    else begin
        if chkKeepCsvStructure.Checked then
	begin
           if not cqrini.ReadBool('QSLExport','SplitRST_R',False) then
	      Write(f,C_SEP)
           else
	      Write(f,C_SEP,C_SEP,C_SEP);
        end;
    end;
    if cqrini.ReadBool('QSLExport', 'RST_R', True) then
    begin
      if not cqrini.ReadBool('QSLExport','SplitRST_R',False) then
      begin
        Write(f,dmData.Q.FieldByName('rst_r').AsString,C_SEP);
      end
      else begin
        rst_tmp := dmData.Q.FieldByName('rst_r').AsString + '   ';
        Write(f,rst_tmp[1],C_SEP);
        Write(f,rst_tmp[2],C_SEP);
        Write(f,rst_tmp[3],C_SEP);
      end;
    end
    else begin
        if chkKeepCsvStructure.Checked then
	begin
           if not cqrini.ReadBool('QSLExport','SplitRST_R',False) then
	      Write(f,C_SEP)
           else
	      Write(f,C_SEP,C_SEP,C_SEP);
        end;
    end;
    if cqrini.ReadBool('QSLExport', 'Name', True) then
      Write(f,dmData.Q.FieldByName('name').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'QTH', True) then
      Write(f,dmData.Q.FieldByName('qth').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'band', True) then
      Write(f,dmData.Q.FieldByName('band').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'Propagation', True) then
      Write(f,dmData.Q.FieldByName('prop_mode').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'Satellite',  True) then
      Write(f,dmData.Q.FieldByName('satellite').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'ContestName',  True) then
      Write(f, dmData.Q.FieldByName('contestname').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'QSL_S', True) then
      Write(f,dmData.Q.FieldByName('qsl_s').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'QSL_R', True) then
      Write(f,dmData.Q.FieldByName('qsl_r').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'QSL_VIA', True) then
      Write(f,dmData.Q.FieldByName('qsl_via').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'locator', True) then
      Write(f,dmData.Q.FieldByName('loc').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'MyLoc', True) then
      Write(f,dmData.Q.FieldByName('my_loc').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'Distance', True) then
      Write(f,frmMain.CalcQrb(dmData.Q.FieldByName('my_loc').AsString,dmData.Q.FieldByName('loc').AsString,False),C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'IOTA', True) then
      Write(f,dmData.Q.FieldByName('iota').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'award', True) then
      Write(f,dmData.Q.FieldByName('award').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'power', True) then
      Write(f,dmData.Q.FieldByName('pwr').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'Remarks', True) then
      Write(f,dmData.Q.FieldByName('remarks').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'QSLMsg', True) then
      Write(f,dmData.Q.FieldByName('qslmsg').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'ContestNrS', True) then
      Write(f,dmData.Q.FieldByName('stx').AsString ,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'ContestMsgS', True) then
      Write(f,dmData.Q.FieldByName('stx_string').AsString,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'ContestNrR',  True) then
      Write(f,dmData.Q.FieldByName('srx').AsString ,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;
    if cqrini.ReadBool('QSLExport', 'ContestMsgR',  True) then
      Write(f,dmData.Q.FieldByName('srx_string').AsString ,C_SEP)
    else begin
        if chkKeepCsvStructure.Checked then
	    Write(f,C_SEP);
    end;

  end;

begin
  mycall := cqrini.ReadString('Station','Call','');
  if (mycall='') then
  begin
    Application.MessageBox('Your callsign is not set! Please set it in Preferences.','Info ...',mb_OK + mb_IconInformation);
    exit
  end;

  if FileExists(edtFile.Text) then
  begin
    if Application.MessageBox('File already exists! Do you want to overvrite it?',
                              'Question',mb_YesNo + mb_IconQuestion) = idYes then
      DeleteFile(edtFile.Text)
    else
      exit
  end;

  if cqrini.ReadBool('OnlineLog','IgnoreQSL',False) then
           dmLogUpload.DisableOnlineLogSupport;

  FieldCount := GetExpFieldCount;
  if dmData.DebugLevel >= 1 then Writeln('Field count: ', FieldCount);
  dmData.CreateQSLTmpTable;
  LoadDataToTempDB;
//  FieldCount := GetExpFieldCount;

  MaxQ := StrToInt(edtQSOsToLabel.Text);
  AssignFile(f,edtFile.Text);
  try  try
    Rewrite(f);
    dmData.trQ.StartTransaction;
    dmData.trQ1.StartTransaction;
    dmData.Q.SQL.Text := 'select * from qslexport order by dxcc,idcall';
    dmData.Q.Open;

    while not dmData.Q.Eof do
    begin
      if chkMarkSent.Checked then
      begin
        qsl_s := dmData.Q.FieldByName('qsl_s').AsString;
        if Pos('S',qsl_s) = 1 then
          qsl_s := copy(qsl_s,2,Length(qsl_s)-1)
        else begin
          if qsl_s = '' then
          begin
            if dmData.Q.FieldByName('qsl_s').AsString <> '' then
              qsl_s := 'MB'
            else
              qsl_s := 'B'
          end
        end;

        dmData.Q1.SQL.Text := 'update cqrlog_main set qsl_s ='+QuotedStr(qsl_s)  +
                              ', qsls_date = '+ QuotedStr(dmUtils.DateInRightFormat(dmUtils.GetDateTime(0))) +
                              ' where id_cqrlog_main='+IntToStr(dmData.Q.Fields[2].AsInteger);
        if dmData.DebugLevel >= 1 then Writeln(dmData.Q1.SQL.Text);
        dmData.Q1.ExecSQL
      end;

      if old <> dmData.Q.FieldByName('callsign').AsString then
      begin
        if (old <> '') then
        begin
          for i:=lNr+1 to MaxQ do
          begin
            for y:=0 to FieldCount-1 do
              Write(f,C_SEP)
          end;
          Writeln(f);
          lNr := 0;
          old := 'aaa'
        end;
        WriteDataToFile;
        lNr := 1
      end
      else begin
        WriteDataToFile;
        inc(lNr)
      end;
      if lNr+1 > MaxQ then
        old := 'aaa'
      else
        old := dmData.Q.FieldByName('callsign').AsString;

      lblProgress.Caption := 'Exporting QSO nr. ' + IntToStr(qso_nr);
      lblProgress.Repaint;
      dmData.Q.Next
    end
  except
    on E : Exception do
    begin
      Application.MessageBox(PChar('QSL export error: '+E.Message),'Error ...', mb_OK+mb_IconError);
      dmData.trQ1.Rollback
    end
  end
  finally
    dmData.Q.Close;
    dmData.Q1.Close;
    if dmData.trQ1.Active then
      dmData.trQ1.Commit;
    dmData.trQ.Rollback;
    dmData.DropQSLTmpTable;
    lblProgress.Caption := 'Complete!';
    CloseFile(f);
    dmData.RefreshMainDatabase();

    if cqrini.ReadBool('OnlineLog','IgnoreQSL',False) then
     dmLogUpload.EnableOnlineLogSupport;
  end
end;

procedure TfrmExLabelPrint.btnHelpClick(Sender: TObject);
begin
  ShowHelp
end;

procedure TfrmExLabelPrint.chkAllQSOsChange(Sender: TObject);
begin
  if chkAllQSOs.Checked then
    gchkExport.Enabled := False
  else
    gchkExport.Enabled := True
end;

procedure TfrmExLabelPrint.edtBrowseClick(Sender: TObject);
begin
  if dlgSave.Execute then
    edtFile.Text := dlgSave.FileName
end;

procedure TfrmExLabelPrint.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  cqrini.WriteString('QslExport','Path',edtFile.Text);
  cqrini.WriteString('QslExport','QSOs',edtQSOsToLabel.Text);
  cqrini.WriteString('QslExport','Remarks',edtRemarks.Text);
  cqrini.WriteBool('QSLExport', 'KeepCsvStructure', chkKeepCsvStructure.Checked);
  cqrini.WriteBool('QslExport','RemoveSep',chkRemoveSep.Checked)
end;

procedure TfrmExLabelPrint.btnExportFieldsPrefClick(Sender : TObject);
begin
  with TfrmQSLExpPref.Create(nil) do
  try
    ShowModal
  finally
    Free
  end
end;

procedure TfrmExLabelPrint.edtRemarksEnter(Sender: TObject);
begin
  rbOwnRemarks.Checked := True
end;

end.

