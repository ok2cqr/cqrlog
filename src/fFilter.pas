(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fFilter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, MaskEdit, lcltype, ExtDlgs, EditBtn, inifiles, strutils;

type

  { TfrmFilter }

  TfrmFilter = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    btnSave: TButton;
    btnLoad: TButton;
    btnSelectDXCC: TButton;
    btnHelp: TButton;
    btClear: TButton;
    cbIncConName: TCheckBox;
    chkRemember: TCheckBox;
    chkNot: TCheckBox;
    chkIOTAOnly: TCheckBox;
    cmbContestName: TComboBox;
    cmbLoTW_qslr: TComboBox;
    cmbeQSL_qslr : TComboBox;
    cmbeQSL_qsls : TComboBox;
    cmbMode: TComboBox;
    cmbQSL_S: TComboBox;
    cmbQSL_R: TComboBox;
    cmbProfile: TComboBox;
    cmbMembers: TComboBox;
    cmbGroupBy: TComboBox;
    cmbLoTW_qsls: TComboBox;
    cmbSort: TComboBox;
    cmbBandSelector: TComboBox;
    edtSTX: TEdit;
    edtSRX: TEdit;
    edtSTXstr: TEdit;
    edtSRXstr: TEdit;
    edtDateFrom: TDateEdit;
    edtCont: TEdit;
    edtDateTo: TDateEdit;
    edtPwrFrom : TEdit;
    edtPwrTo : TEdit;
    edtState: TEdit;
    edtCounty: TEdit;
    edtIOTA: TEdit;
    edtRemarks: TEdit;
    edtDiplom: TEdit;
    edtMyLoc: TEdit;
    edtWAZ: TEdit;
    edtQSLVia: TEdit;
    edtLocator: TEdit;
    edtFreqFrom: TEdit;
    edtDXCC: TEdit;
    edtCallSign: TEdit;
    edtFreqTo: TEdit;
    edtQTH: TEdit;
    edtITU: TEdit;
    gbCallsign: TGroupBox;
    gbIota: TGroupBox;
    gbRemarks: TGroupBox;
    gbAward: TGroupBox;
    gbMyLoc: TGroupBox;
    gbZones: TGroupBox;
    gbCounty: TGroupBox;
    gbState: TGroupBox;
    gbContestEx: TGroupBox;
    gbContName: TGroupBox;
    gbPower : TGroupBox;
    gbBand: TGroupBox;
    gbDxcc: TGroupBox;
    gbFreq: TGroupBox;
    gbMode: TGroupBox;
    gbDate: TGroupBox;
    gbLoc: TGroupBox;
    gbQth: TGroupBox;
    gbQsl: TGroupBox;
    gbContinent: TGroupBox;
    Label1: TLabel;
    lblContExS: TLabel;
    lblContNR: TLabel;
    lblContMsg: TLabel;
    lblContxR: TLabel;
    lblProf: TLabel;
    lblMember: TLabel;
    lblGrpBy: TLabel;
    lblLoTW: TLabel;
    lblRcvdE: TLabel;
    lblRcvdL: TLabel;
    lblSentC: TLabel;
    lblSentE: TLabel;
    lblSentL: TLabel;
    lblSortBy: TLabel;
    lblEqsl : TLabel;
    Label18 : TLabel;
    Label19 : TLabel;
    Label2: TLabel;
    Label20: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    lblVia: TLabel;
    lblRcvdC: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    dlgOpen: TOpenDialog;
    rbExactlyCounty: TRadioButton;
    rbExactlyMyLoc: TRadioButton;
    rbExactlyRem: TRadioButton;
    rbExactlyLoc: TRadioButton;
    rbExactlyQth: TRadioButton;
    rbExactlyIOTA: TRadioButton;
    rbExactlyDiplom: TRadioButton;
    rbIncludeCall: TRadioButton;
    rbExactlyCall: TRadioButton;
    rbIncludeCounty: TRadioButton;
    rbIncludeMyLoc: TRadioButton;
    rbIncludeRem: TRadioButton;
    rbIncludeLoc: TRadioButton;
    rbIncludeQth: TRadioButton;
    rbIncludeIOTA: TRadioButton;
    rbIncludeDiplom: TRadioButton;
    dlgSave: TSaveDialog;
    procedure btClearClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnSelectDXCCClick(Sender: TObject);
    procedure chkRememberChange(Sender: TObject);
    procedure cmbBandSelectorChange(Sender: TObject);
    procedure edtLocatorChange(Sender: TObject);
    procedure edtMyLocChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    procedure saveFilter(filename:String);
    procedure loadFilter(filename:string);
  public
    tmp : String;
  end;
const
  C_CONTEST_LIST_FILE_NAME = 'ContestName.tab';
  C_FILTER_LAST_SETTINGS_FILE_NAME = 'FilterSettings.fil';
var
  frmFilter: TfrmFilter;

implementation
{$R *.lfm}

{ TfrmFilter }
uses dData, dUtils,fSelectDXCC, dMembership, uMyini;

procedure TfrmFilter.btnOKClick(Sender: TObject);
var
  OrderBy   : String = '';
  grb_by    : String = '';
  p         : TExplodeArray;
  i         : Integer = 0;
  Mask      : String = '';
  sDate     : String = '';
begin
  if chkRemember.Checked then saveFilter(dmData.HomeDir + C_FILTER_LAST_SETTINGS_FILE_NAME);
  //if empty date-to make it as today. NOTE that empty calendar.Text is not empty string, but Date is =0!
  if edtDateTo.Date = 0 then edtDateTo.Date := now;

  tmp := '';
  if (edtCallSign.Text <> '') then
                                begin
                                  if rbExactlyCall.Checked then   tmp := ' (callsign = ' + QuotedStr(edtCallSign.Text)+') AND'
                                  else
                                    tmp := ' (callsign LIKE ''%' + edtCallSign.Text + '%'') AND';
                                end;

  if (edtDXCC.Text <> '') then tmp := tmp + ' (dxcc_ref = '+ QuotedStr(edtDXCC.Text)+') AND';

  if   ((edtFreqFrom.Text <> '')
   and (edtFreqTo.Text <> ''))     then tmp := tmp + ' (freq >= ' + edtFreqFrom.Text + ') AND '+
                                                     ' (freq <= ' + edtFreqTo.Text + ') AND';

  if (cmbMode.Text <> '') then   tmp := tmp + ' (mode = ' + QuotedStr(cmbMode.Text)+') AND';

  if ( cmbContestName.Text <> '') then
                                      begin
                                        if cbIncConName.Checked then
                                           tmp := tmp + ' (UPPER(contestname) LIKE ''%' +
                                                         upcase(cmbContestName.Text) + '%'') AND'
                                          else
                                           tmp := tmp + ' (UPPER(contestname) = ' +
                                                        QuotedStr(upcase(cmbContestName.Text))+') AND';
                                        end;

  if (edtSTX.Text <> '') then tmp := tmp + ' (stx = ' + QuotedStr(edtSTX.Text)+') AND';

  if (edtSRX.Text <> '') then  tmp := tmp + ' (srx = ' + QuotedStr(edtSRX.Text)+') AND';

  if (edtSTXstr.Text <> '') then  tmp := tmp + ' (UPPER(stx_string) = ' + QuotedStr(upcase(edtSTXstr.Text))+') AND';

  if (edtSRXstr.Text <> '') then  tmp := tmp + ' (UPPER(srx_string) = ' + QuotedStr(upcase(edtSRXstr.Text))+') AND';

  //NOTE that empty calendar.Text is not empty string, but Date is =0!
  if edtDateFrom.Date <> 0 then tmp := tmp + ' (qsodate >= ' + QuotedStr(dmUtils.MyDateToStr(edtDateFrom.Date)) +
                                             ') AND (qsodate <= ' + QuotedStr(dmUtils.MyDateToStr(edtDateTo.Date)) +
                                             ') AND';

  if (edtLocator.Text <> '') then
                                  begin
                                    if rbExactlyLoc.Checked then
                                      tmp := tmp + ' (loc = ' + QuotedStr(edtLocator.Text)+') AND'
                                    else
                                      tmp := tmp + ' (loc LIKE ''%' + edtLocator.Text + '%'') AND';
                                  end;
  if (edtQTH.Text <> '') then
                                  begin
                                    if rbExactlyQth.Checked then
                                      tmp := tmp + ' (qth = ' + QuotedStr(edtQTH.Text)+') AND'
                                    else
                                      tmp := tmp + ' (qth LIKE ''%' + edtQTH.Text + '%'') AND';
                                  end;

  if (edtQSLVia.Text <> '') then  tmp := tmp + ' (qsl_via = ' + QuotedStr(edtQSLVia.Text)+') AND';

  if (cmbQSL_S.Text <> '') then
                                  begin
                                    if cmbQSL_S.Text = 'S' then
                                      tmp := tmp + ' (qsl_s LIKE ''%' + cmbQSL_S.Text + '%'') AND'
                                    else
                                     begin
                                      if cmbQSL_S.Text = 'Empty' then
                                        tmp := tmp + '((qsl_s = ' + QuotedStr('')+') or (qsl_s is null)) AND'
                                      else
                                        tmp := tmp + '(qsl_s = ' + QuotedStr(cmbQSL_S.Text)+') AND'
                                     end;
                                  end;
  if (cmbQSL_R.Text <> '') then
                                  begin
                                    if cmbQSL_R.Text = 'Empty' then
                                      tmp := tmp + '((qsl_r = ' + QuotedStr('')+') or (qsl_r is null)) AND'
                                    else
                                      tmp := tmp + '(qsl_r = ' + QuotedStr(cmbQSL_R.Text)+') AND';
                                  end;
  if (edtIOTA.Text <> '') then
                                  begin
                                    if rbExactlyIOTA.Checked then
                                      tmp := tmp + ' (iota = ' + QuotedStr(edtIOTA.Text)+') AND'
                                     else
                                      tmp := tmp + ' (iota LIKE ''%' + edtIOTA.Text + '%'') AND';
                                  end;

  if chkIOTAOnly.Checked then tmp := tmp + ' (iota IS NOT NULL) AND';

  if (edtReMarks.Text <> '') then
                                  begin
                                    if rbExactlyRem.Checked then
                                      tmp := tmp + ' (remarks = ' + QuotedStr(edtRemarks.Text)+') AND'
                                     else
                                      tmp := tmp + ' (remarks LIKE ''%' + edtRemarks.Text + '%'') AND';
                                  end;
  if (edtDiplom.Text <> '') then
                                  begin
                                    if rbExactlyDiplom.Checked then
                                      tmp := tmp + ' (award = ' + QuotedStr(edtDiplom.Text)+') AND'
                                     else
                                      tmp := tmp + ' (award LIKE ''%' + edtDiplom.Text + '%'') AND';
                                  end;
  if (edtMyLoc.Text <> '') then
                                  begin
                                    if rbExactlyMyLoc.Checked then
                                      tmp := tmp + ' (my_loc = ' + QuotedStr(edtMyLoc.Text)+') AND'
                                     else
                                      tmp := tmp + ' (my_loc LIKE ''%' + edtMyLoc.Text + '%'') AND';
                                  end;

  if (edtWAZ.Text <> '') then  tmp := tmp + ' (waz = ' + edtWAZ.Text + ') AND';

  if (edtITU.Text <> '') then tmp := tmp + ' (itu = ' + edtITU.Text + ') AND';

  if (edtCounty.Text <> '') then
                                  begin
                                    if rbExactlyCounty.Checked then
                                      tmp := tmp + ' (county = ' + QuotedStr(edtCounty.Text)+') AND'
                                     else
                                      tmp := tmp + ' (county LIKE ''%' + edtCounty.Text + '%'') AND';
                                  end;

  if edtState.Text <> '' then tmp := tmp + ' (state = ' + QuotedStr(edtState.Text)+') AND';

  if cmbProfile.ItemIndex > 0 then tmp := tmp + '(profile = ' + IntToStr(dmData.GetNRFromProfile(cmbProfile.Text)) +
                                                ') AND';

  if cmbLoTW_qsls.ItemIndex > 0 then
                                  begin
                                    if cmbLoTW_qsls.ItemIndex = 1 then
                                      tmp := tmp + ' (lotw_qsls='+QuotedStr('Y')+') AND'
                                     else
                                      tmp := tmp +  '(lotw_qsls <> '+QuotedStr('Y')+') AND'
                                  end;
  
  if cmbLoTW_qslr.ItemIndex > 0 then
                                  begin
                                    if cmbLoTW_qslr.ItemIndex = 1 then
                                      tmp := tmp + ' (lotw_qslr='+QuotedStr('L')+') AND'
                                     else
                                      tmp := tmp + ' (lotw_qslr <> '+QuotedStr('L')+') AND'
                                  end;

  if edtCont.Text <> '' then
                                  begin
                                    if pos(';',edtCont.Text) > 0 then
                                    begin
                                      SetLength(p,0);
                                      p := dmUtils.Explode(';',edtCont.Text);
                                      for i:=0 to Length(p)-1 do
                                        tmp := tmp + ' (cont = '+QuotedStr(p[i])+') OR'
                                    end
                                    else
                                      tmp := tmp + ' (cont = '+QuotedStr(edtCont.Text)+') AND'
                                  end;

  if cmbeQSL_qsls.ItemIndex > 0 then
                                  begin
                                    if cmbeQSL_qsls.ItemIndex = 1 then
                                      tmp := tmp + ' (eqsl_qsl_sent = '+QuotedStr('Y')+') AND'
                                     else
                                      tmp := tmp +  '(eqsl_qsl_sent <> '+QuotedStr('Y')+') AND'
                                  end;

  if cmbeQSL_qslr.ItemIndex > 0 then
                                  begin
                                    if cmbeQSL_qslr.ItemIndex = 1 then
                                      tmp := tmp + ' (eqsl_qsl_rcvd = '+QuotedStr('E')+') AND'
                                     else
                                      tmp := tmp + ' (eqsl_qsl_rcvd <> '+QuotedStr('E')+') AND'
                                  end;

  if ((edtPwrFrom.Text <> '') and (edtPwrTo.Text <> '')) then  tmp := tmp + ' (pwr >= ' + edtPwrFrom.Text + ') AND '+
                                                                            ' (pwr <= ' + edtPwrTo.Text + ') AND';


  if cmbMembers.ItemIndex >0 then tmp := tmp + ' (club_nr'+IntToStr(cmbMembers.ItemIndex)+' <> '+
                                               QuotedStr('')+') AND';

  if (tmp <> '') then
                      begin
                        tmp := Trim(tmp);
                        tmp := copy(tmp,1,Length(tmp)-3);

                        case cmbSort.ItemIndex of
                          0 : OrderBy := '';  //Already set in view   OrderBy := ' ORDER BY qsodate,time_on';
                          1 : OrderBy := ' ORDER BY callsign';
                          2 : OrderBy := ' ORDER BY mode';
                          3 : OrderBy := ' ORDER BY freq';
                          4 : OrderBy := ' ORDER BY name';
                          5 : OrderBy := ' ORDER BY qth';
                          6 : OrderBy := ' ORDER BY dxcc_ref';
                          7 : OrderBy := ' ORDER BY award';
                          8 : OrderBy := ' ORDER BY state';
                          9 : OrderBy := ' ORDER BY county';
                         10 : OrderBy := ' ORDER BY dxcc_ref';
                         11 : OrderBy := ' ORDER BY dxcc_ref,callsign';
                         12 : OrderBy := ' ORDER By qsl_via,callsign,dxcc_ref';
                         13 : OrderBy := ' ORDER By callsign,dxcc_ref';
                         14 : OrderBy := ' ORDER BY waz';
                         15 : OrderBy := ' ORDER BY itu';
                         16 : OrderBy := ' ORDER BY loc'
                        end;//case

                        case cmbGroupBy.ItemIndex of
                          1  : grb_by := 'GROUP BY dxcc_ref';
                          2  : grb_by := 'GROUP BY remarks';
                          3  : grb_by := 'GROUP BY award';
                          4  : grb_by := 'GROUP BY callsign';
                          5  : grb_by := 'GROUP BY idcall';
                          6  : grb_by := 'GROUP BY loc';
                          7  : grb_by := 'GROUP BY iota';
                          8  : grb_by := 'GROUP BY waz';
                          9  : grb_by := 'GROUP BY itu';
                          10 : grb_by := 'GROUP BY state';
                          11 : grb_by := 'GROUP BY county';
                          12 : grb_by := 'GROUP BY club_nr1';
                          13 : grb_by := 'GROUP BY club_nr2';
                          14 : grb_by := 'GROUP BY club_nr3';
                          15 : grb_by := 'GROUP BY club_nr4';
                          16 : grb_by := 'GROUP BY club_nr5'
                        end; //case

                        if chkNot.Checked then tmp:= 'NOT( '+tmp+' )';
                        tmp := 'SELECT * FROM view_cqrlog_main_by_qsodate WHERE ' + tmp + ' ' + grb_by +' ' + OrderBy;

                        dmData.qCQRLOG.Close;
                        dmData.qCQRLOG.SQL.Text := tmp;
                        if dmData.DebugLevel >=1 then
                          Writeln(tmp);
                        if dmData.trCQRLOG.Active then
                          dmData.trCQRLOG.Rollback;
                        dmData.trCQRLOG.StartTransaction;
                        dmData.qCQRLOG.Open;
                        dmData.qCQRLOG.Last
                      end;
  ModalResult := mrOK;
end;

procedure TfrmFilter.btnCancelClick(Sender: TObject);
begin
  Close
end;

procedure TfrmFilter.FormCreate(Sender: TObject);
var
   ListOfContests : TStringList;
   i : integer;
   s: string;
   Contestfile :TextFile;
begin
  dmUtils.InsertBands(cmbBandSelector);
  cmbBandSelector.Items.Insert(0, ''); //to be sure
  // loading the contest list from ../ContestNames.tab
  // Format of File   CONTEST_ID|CONTEST_DESCRIPTION
  // see ADIF 3.0.9 http://www.adif.org/309/ADIF_309.htm#Contest_ID
  ListOfContests:= TStringList.Create;
  ListOfContests.Clear;
  ListOfContests.Sorted:=false;
  if FileExists(dmData.HomeDir + C_CONTEST_LIST_FILE_NAME) then
     Begin
       AssignFile(Contestfile, dmData.HomeDir + C_CONTEST_LIST_FILE_NAME);
       try
        reset(Contestfile);
       while not eof(Contestfile) do
       begin
        readln(Contestfile, s);
        ListOfContests.Add(ExtractDelimited(1,s,['|']));
       end;
       CloseFile(Contestfile);
        except
          on E: EInOutError do
           writeln('Contestfile reading error. Details: ', E.Message);
       end;
     end;
  //Add strings that wsjt-x may use at contest_name column
  ListOfContests.Add('NA VHF');
  ListOfContests.Add('EU VHF');
  ListOfContests.Add('FIELD DAY');
  ListOfContests.Add('RTTY RU');
  ListOfContests.Add('FOX-QSO');
  ListOfContests.Add('HOUND-QSO');
  ListOfContests.Sort;
  cmbContestName.Clear;
  cmbContestName.Items := ListOfContests;
  cmbContestName.Items.Insert(0,''); //to be sure there is empty line at start
  ListOfContests.Free;
end;
//actually form create and show are common procedure as filter is opened in showModal and it always
//creates and shows itself in every opening

procedure TfrmFilter.FormShow(Sender: TObject);

begin
  dmUtils.LoadFontSettings(self);
  dmUtils.InsertQSL_S(cmbQSL_S);
  cmbQSL_S.Items.Insert(9,'S');
  cmbQSL_S.Items.Add('Empty');
  dmUtils.InsertQSL_R(cmbQSL_R);
  cmbQSL_R.Items.Add('Empty');
  dmUtils.InsertModes(cmbMode);
  cmbMode.Items.Insert(0,'');

  dmData.InsertProfiles(cmbProfile,True);
  cmbProfile.Text := dmData.GetDefaultProfileText;
  cmbProfile.Items.Insert(0,'Any profile');
  cmbProfile.ItemIndex := 0;
  cmbMembers.Items.Add('');
  if dmMembership.Club1.Name <> '' then
    cmbMembers.Items.Add('1;'+dmMembership.Club1.Name+';'+dmMembership.Club1.LongName);
  if dmMembership.Club2.Name <> '' then
    cmbMembers.Items.Add('2;'+dmMembership.Club2.Name+';'+dmMembership.Club2.LongName);
  if dmMembership.Club3.Name <> '' then
    cmbMembers.Items.Add('3;'+dmMembership.Club3.Name+';'+dmMembership.Club3.LongName);
  if dmMembership.Club4.Name <> '' then
    cmbMembers.Items.Add('4;'+dmMembership.Club4.Name+';'+dmMembership.Club4.LongName);
  if dmMembership.Club5.Name <> '' then
    cmbMembers.Items.Add('5;'+dmMembership.Club5.Name+';'+dmMembership.Club5.LongName);
  cmbMembers.ItemIndex := 0;
  cmbSort.ItemIndex := 0;

  chkRemember.Checked:= cqrini.ReadBool('frmFilter','Remember',false);
  if chkRemember.Checked then loadFilter(dmData.HomeDir + C_FILTER_LAST_SETTINGS_FILE_NAME);
end;

procedure TfrmFilter.btnSelectDXCCClick(Sender: TObject);
begin
  frmSelectDXCC := TfrmSelectDXCC.Create(self);
  try
    frmSelectDXCC.edtPrefix.Text := edtDXCC.Text;
    frmSelectDXCC.pgDXCC.PageIndex := 0;
    frmSelectDXCC.ShowModal;
    if frmSelectDXCC.ModalResult = mrOK then
      edtDXCC.Text := frmSelectDXCC.edtPrefix.Text
  finally
    frmSelectDXCC.Free
  end
end;

procedure TfrmFilter.chkRememberChange(Sender: TObject);
begin
     cqrini.WriteBool('frmFilter','Remember',chkRemember.Checked);
     if not chkRemember.Checked then
       Begin
        if FileExists(dmData.HomeDir + C_FILTER_LAST_SETTINGS_FILE_NAME) then
          DeleteFile( dmData.HomeDir + C_FILTER_LAST_SETTINGS_FILE_NAME);
       end;
end;

procedure TfrmFilter.cmbBandSelectorChange(Sender: TObject);
var
  Band :String;
begin
  if (cmbBandSelector.ItemIndex < 1 ) then
   Begin
     edtFreqFrom.Text:='';
     edtFreqTo.Text := edtFreqFrom.Text;
   end
   else
   Begin
     Band:= cmbBandSelector.items[cmbBandSelector.ItemIndex];
     if (band<>'') then
      begin
           dmData.qBands.Close;
           dmData.qBands.SQL.Text := 'select band,b_begin,b_end from cqrlog_common.bands where band="'+Band+'"';
           dmData.qBands.Open;

           if (dmData.qBands.RecordCount > 0) then
            begin
              if (dmData.qBands.FieldByName('band').AsString = Band) then
               Begin
                 edtFreqFrom.Text:=dmData.qBands.FieldByName('b_begin').AsString;
                 edtFreqTo.Text := dmData.qBands.FieldByName('b_end').AsString;
               end;
            end;
           dmData.qBands.Close;
      end;
    end;

end;


procedure TfrmFilter.edtLocatorChange(Sender: TObject);
begin
   if rbExactlyLoc.Checked then
   Begin
     edtLocator.Text:=dmUtils.StdFormatLocator(edtLocator.Text);
     edtLocator.SelStart := Length(edtLocator.Text);
   end;
end;

procedure TfrmFilter.edtMyLocChange(Sender: TObject);
begin
  if rbExactlyMyLoc.Checked then
   Begin
     edtMyLoc.Text:=dmUtils.StdFormatLocator(edtMyLoc.Text);
     edtMyLoc.SelStart := Length(edtMyLoc.Text);
   end;
end;

procedure TfrmFilter.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = VK_RETURN then
  begin
    btnOK.Click;
    Key := 0
  end
end;

procedure TfrmFilter.btnHelpClick(Sender: TObject);
begin
  ShowHelp
end;

procedure TfrmFilter.btClearClick(Sender: TObject);
var
   i: integer;
begin
      FormShow(nil);
      edtCallSign.Text         := '';

      edtDXCC.Text             := '';
      edtFreqFrom.Text         := '';
      edtFreqTo.Text           := '';
      cmbMode.Text             := '';
      edtDateFrom.Text         := '';    //
      edtDateFrom.Date         := 0;     //I think one (date or Text) is enough, but for sure ...
      edtDateTo.Text           := '';    //
      edtDateTo.Date           := 0;     //
      edtLocator.Text          := '';
      edtQTH.Text              := '';
      cmbQSL_S.Text            := '';
      cmbQSL_R.Text            := '';
      edtQSLVia.Text           := '';
      edtIOTA.Text             := '';
      edtRemarks.Text          := '';
      edtDiplom.Text           := '';
      edtMyLoc.Text            := '';
      edtWAZ.Text              := '';
      edtITU.Text              := '';
      edtCounty.Text           := '';
      edtState.Text            := '';
      cmbLoTW_qsls.Text        := '';
      cmbLoTW_qslr.Text        := '';
      edtCont.Text             := '';
      cmbeQSL_qsls.Text        := '';
      cmbeQSL_qslr.Text        := '';
      edtPwrFrom.Text          := '';
      edtPwrTo.Text            := '';
      edtSTX.Text              := '';
      edtSRX.Text              := '';
      edtSTXstr.Text           := '';
      edtSRXstr.Text           := '';
      rbExactlyIOTA.Checked    := True;
      rbExactlyRem.Checked     := True;
      rbExactlyDiplom.Checked  := True;
      rbExactlyMyLoc.Checked   := True;
      rbExactlyCounty.Checked  := True;
      rbExactlyLoc.Checked     := True;
      rbExactlyCall.Checked    := True;
      rbExactlyQth.Checked     := True;
      chkIOTAOnly.Checked      := False;
      cbIncConName.Checked     := False;
      chkNot.Checked           := False;
      cmbContestName.ItemIndex := 0;
      cmbGroupBy.ItemIndex     := 0;
      cmbProfile.ItemIndex     := 0;
      cmbMembers.ItemIndex     := 0;
      cmbBandSelector.ItemIndex:= 0;
end;

procedure TfrmFilter.btnLoadClick(Sender: TObject);
begin
  dlgOpen.InitialDir := dmData.HomeDir;
  if dlgOpen.Execute then loadFilter(dlgOpen.FileName);
end;

procedure TfrmFilter.btnSaveClick(Sender: TObject);
begin
  dlgSave.InitialDir := dmData.HomeDir;
  if dlgSave.Execute then saveFilter(dlgSave.FileName);
end;

procedure TfrmFilter.saveFilter(filename:String);
var
  filini : TIniFile;
begin
    filini := TIniFile.Create(fileName);
    try
      filini.WriteString('call','call',edtCallSign.Text);
      filini.WriteBool('call','exactly',rbExactlyCall.Checked);
      filini.WriteString('dxcc','dxcc',edtDXCC.Text);
      filini.WriteString('freq','freq_from',edtFreqFrom.Text);
      filini.WriteString('freq','freq_to',edtFreqTo.Text);
      filini.WriteString('mode','mode',cmbMode.Text);
      //NOTE that empty calendar is not empty string, but date is 0!
      if edtDateFrom.Date = 0 then filini.WriteString('date','date_from','')
       else filini.WriteString('date','date_from',dmUtils.MyDateToStr(edtDateFrom.Date));
      if edtDateTo.Date = 0 then  filini.WriteString('date','date_to','')
       else filini.WriteString('date','date_to',dmUtils.MyDateToStr(edtDateTo.Date));
      filini.WriteString('locator','locator',edtLocator.Text);
      filini.WriteBool('locator','exactly',rbExactlyLoc.Checked);
      filini.WriteString('qth','qth',edtQTH.Text);
      filini.WriteBool('qth','exactly',rbExactlyQth.Checked);
      filini.WriteString('qsl','qsl_s',cmbQSL_S.Text);
      filini.WriteString('qsl','qsl_r',cmbQSL_R.Text);
      filini.WriteString('qsl','qsl_via',edtQSLVia.Text);
      filini.WriteString('sort','sort',cmbSort.Text);
      filini.WriteString('iota','iota',edtIOTA.Text);
      filini.WriteBool('iota','exactly',rbExactlyIOTA.Checked);
      filini.WriteBool('iota','iota_only',chkIOTAOnly.Checked);
      filini.WriteString('remarks','remarks',edtRemarks.Text);
      filini.WriteBool('remarks','exactly',rbExactlyRem.Checked);
      filini.WriteString('award','award',edtDiplom.Text);
      filini.Writebool('award','exactly',rbExactlyDiplom.Checked);
      filini.WriteString('myloc','myloc',edtMyLoc.Text);
      filini.WriteBool('myloc','exactly',rbExactlyMyLoc.Checked);
      filini.WriteString('waz','waz',edtWAZ.Text);
      filini.WriteString('itu','itu',edtITU.Text);
      filini.WriteString('county','county',edtCounty.Text);
      filini.WriteBool('county','exactly',rbExactlyCounty.Checked);
      filini.WriteString('state','state',edtState.Text);
      filini.WriteInteger('groupby','groupby',cmbGroupBy.ItemIndex);
      filini.WriteInteger('profile','profile',cmbProfile.ItemIndex);
      filini.WriteInteger('membership','membership',cmbMembers.ItemIndex);
      filini.WriteString('lotw_qsls','lotw_qsls',cmbLoTW_qsls.Text);
      filini.WriteString('lotw_qsls','lotw_qslr',cmbLoTW_qslr.Text);
      filini.WriteString('cont','cont',edtCont.Text);
      filini.WriteString('eQSL','eqsl_qsl_sent',cmbeQSL_qsls.Text);
      filini.WriteString('eQSL','eqsl_qsl_rcvd',cmbeQSL_qslr.Text) ;
      filini.WriteString('Power','power_from',edtPwrFrom.Text);
      filini.WriteString('Power','power_to',edtPwrTo.Text);
      filini.WriteBool('not','not',chkNot.Checked);
      filini.WriteInteger('contestname','contestname',cmbContestName.ItemIndex);
      filini.Writebool('contestname','include',cbIncConName.Checked);
      filini.WriteString('contestexchange','stx', edtSTX.Text);
      filini.WriteString('contestexchange','srx', edtSRX.Text);
      filini.WriteString('contestexchange','stxstr', edtSTXstr.Text);
      filini.WriteString('contestexchange','srxstr', edtSRXstr.Text);
    finally
      filini.Free
    end;
end;
Procedure TfrmFilter.loadFilter(filename:string);
var
  filini : TIniFile;
  begin
    filini := TIniFile.Create(fileName);
    try
      edtCallSign.Text        := filini.ReadString('call','call','');
      rbIncludeCall.Checked   := not filini.ReadBool('call','exactly',True);
      edtDXCC.Text            := filini.ReadString('dxcc','dxcc','');
      edtFreqFrom.Text        := filini.ReadString('freq','freq_from','');
      edtFreqTo.Text          := filini.ReadString('freq','freq_to','');
      cmbMode.Text            := filini.ReadString('mode','mode','');
      //I think setting just .Text sets also .Date in case of empty
      edtDateFrom.Text        := filini.ReadString('date','date_from','');
      edtDateTo.Text          := filini.ReadString('date','date_to','');
      edtLocator.Text         := filini.ReadString('locator','locator','');
      rbIncludeLoc.Checked    := not filini.ReadBool('locator','exactly',True);
      edtQTH.Text             := filini.ReadString('qth','qth','');
      rbIncludeQth.Checked    := not filini.ReadBool('qth','exactly',True);
      cmbQSL_S.Text           := filini.ReadString('qsl','qsl_s','');
      cmbQSL_R.Text           := filini.ReadString('qsl','qsl_r','');
      edtQSLVia.Text          := filini.ReadString('qsl','qsl_via','');
      cmbSort.Text            := filini.ReadString('sort','sort','');
      edtIOTA.Text            := filini.ReadString('iota','iota','');
      rbIncludeIOTA.Checked   := not filini.ReadBool('iota','exactly',True);
      chkIOTAOnly.Checked     := filini.ReadBool('iota','iota_only',False);
      edtRemarks.Text         := filini.ReadString('remarks','remarks','');
      rbIncludeRem.Checked    := not filini.ReadBool('remarks','exactly',True);
      edtDiplom.Text          := filini.ReadString('award','award','');
      rbIncludeDiplom.Checked := not filini.Readbool('award','exactly',True);
      edtMyLoc.Text           := filini.ReadString('myloc','myloc','');
      rbIncludeMyLoc.Checked  := not filini.ReadBool('myloc','exactly',True);
      edtWAZ.Text             := filini.ReadString('waz','waz','');
      edtITU.Text             := filini.ReadString('itu','itu','');
      edtCounty.Text          := filini.ReadString('county','county','');
      rbIncludeCounty.Checked := not filini.ReadBool('county','exactly',True);
      edtState.Text           := filini.ReadString('state','state','');
      if filini.ReadInteger('groupby','groupby',0) < cmbGroupBy.Items.Count then
        cmbGroupBy.ItemIndex := filini.ReadInteger('groupby','groupby',0);
      if filini.ReadInteger('profile','profile',0) < cmbProfile.Items.Count then
        cmbProfile.ItemIndex := filini.ReadInteger('profile','profile',0);
      if filini.ReadInteger('membership','membership',0) < cmbMembers.Items.Count then
        cmbMembers.ItemIndex := filini.ReadInteger('membership','membership',0);
      cmbLoTW_qsls.Text := filini.ReadString('lotw_qsls','lotw_qsls','');
      cmbLoTW_qslr.Text := filini.ReadString('lotw_qsls','lotw_qslr','');
      edtCont.Text      := filini.ReadString('cont','cont','');
      cmbeQSL_qsls.Text := filini.ReadString('eQSL','eqsl_qsl_sent','');
      cmbeQSL_qslr.Text := filini.ReadString('eQSL','eqsl_qsl_rcvd','');
      edtPwrFrom.Text   := filini.ReadString('Power','power_from','');
      edtPwrTo.Text     := filini.ReadString('Power','power_to','');
      chkNot.Checked    := filini.ReadBool('not','not',False);
      if  filini.ReadInteger('contestname','contestname',0) < cmbContestName.Items.Count then
        cmbContestName.ItemIndex := filini.ReadInteger('contestname','contestname',0);
      cbIncConName.Checked     := filini.Readbool('contestname','include',False);
      edtSTX.Text              := filini.ReadString('contestexchange','stx', '');
      edtSRX.Text              := filini.ReadString('contestexchange','srx','');
      edtSTXstr.Text           := filini.ReadString('contestexchange','stxstr','');
      edtSRXstr.Text           := filini.ReadString('contestexchange','srxstr','');
    finally
      filini.Free
    end
end;

end.

