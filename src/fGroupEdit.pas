(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fGroupEdit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, lcltype, strutils;

type

  { TfrmGroupEdit }

  TfrmGroupEdit = class(TForm)
    btnApply: TButton;
    btnCancel: TButton;
    cmbField: TComboBox;
    cmbValue: TComboBox;
    GroupBox1: TGroupBox;
    lblField: TLabel;
    lblValue: TLabel;
    lblInfo: TLabel;
    Panel1: TPanel;
    pnlGrpEdt: TPanel;
    procedure btnApplyClick(Sender: TObject);
    procedure cmbFieldChange(Sender: TObject);
    procedure cmbValueChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    WhereTo: String;
  public
    Selected : Boolean;
    { public declarations }
  end; 

var
  frmGroupEdit: TfrmGroupEdit;

implementation
{$R *.lfm}

{ TfrmGroupEdit }
uses dUtils, dData, dDXCC, fMain,dSatellite;

procedure TfrmGroupEdit.cmbFieldChange(Sender: TObject);
begin
  cmbValue.Clear;
  cmbValue.Style:= csDropDown;
  case cmbField.ItemIndex of
     5 : begin
           dmUtils.InsertModes(cmbValue);
           cmbValue.Style:=csDropDownList;
         end;
    22 : begin
           dmUtils.InsertQSL_S(cmbValue);
           cmbValue.ItemIndex := 0;
           cmbValue.Style:=csDropDownList;
         end;
    24 : begin
           dmUtils.InsertQSL_R(cmbValue);
           cmbValue.ItemIndex := 0;
           cmbValue.Style:=csDropDownList;
         end;
 26,30 : begin
           cmbValue.Items.Add('Y');
           cmbValue.Items.Add('N');
           cmbValue.ItemIndex := 0;
           cmbValue.Style:=csDropDownList;
         end;
    28 : begin
           cmbValue.Items.Add('L');
           cmbValue.Items.Add('N');
           cmbValue.ItemIndex := 0;
           cmbValue.Style:=csDropDownList;
         end;
    20 : begin
           dmData.InsertProfiles(cmbValue,False);
           cmbValue.ItemIndex := 0;
           cmbValue.Style:=csDropDownList;
         end;
    32 : begin
           cmbValue.Items.Add('E');
           cmbValue.Items.Add('N');
           cmbValue.ItemIndex := 0;
           cmbValue.Style:=csDropDownList;
         end;
    34 : begin
           dmUtils.InsertContests(cmbValue);
           cmbValue.Style:=csDropDown;
         end;
    35 : begin
           dmSatellite.SetListOfPropModes(cmbValue);
           cmbValue.Style:=csDropDown;
         end;
    36 : begin
           dmSatellite.SetListOfSatellites(cmbValue);
           cmbValue.Style:=csDropDown;
         end;
   end;
   pnlGrpEdt.Color:=$005C5CFF;
   lblInfo.Caption := 'Backup your log! Operations can not be undone!';
   btnCancel.Caption:='Cancel';
   pnlGrpEdt.Repaint;
   lblInfo.Repaint;
end;

procedure TfrmGroupEdit.cmbValueChange(Sender: TObject);
begin
  pnlGrpEdt.Color:=$005C5CFF;
  lblInfo.Caption := 'Backup your log! Operations can not be undone!';
  btnCancel.Caption:='Cancel';
  pnlGrpEdt.Repaint;
  lblInfo.Repaint;

  if (cmbField.ItemIndex=23) or (cmbField.ItemIndex=24) then
  begin
    cmbValue.Text :=dmUtils.StdFormatLocator(cmbValue.Text);
    cmbValue.SelStart := Length(cmbValue.Text);
  end;
end;

procedure TfrmGroupEdit.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(self);
  pnlGrpEdt.Color:=clDefault;
  if Selected then
     WhereTo := 'to selected qsos'
    else
     if dmData.IsFilter then
       WhereTo := 'to filtered qsos'
      else
       WhereTo := 'to whole log';
  lblInfo.Caption := 'Apply will afftect '+WhereTo;
  pnlGrpEdt.Repaint;
  lblInfo.Repaint;
end;

procedure TfrmGroupEdit.btnApplyClick(Sender: TObject);
var
  sql           : String = '';
  update_dxcc   : Boolean = False;
  zone          : Integer = 0;
  nr            : Integer = 0;
  i             : Integer = 0;
  aid           : Array of LongInt;


//------------------------------------------------------------------------------------------------------
  procedure ChangeQSO(idx : LongInt);
  begin
    if update_dxcc then
    begin
      dmData.Q.Close;
      if dmData.trQ.Active then
        dmData.trQ.RollBack;
      dmData.Q.SQL.Text := 'select qsodate,freq,mode,qsl_r,lotw_qslr,dxcc_ref from '+
                           'cqrlog_main where id_cqrlog_main = ' + IntToStr(idx);
      if dmData.DebugLevel >=1 then Writeln(dmData.Q.SQL.Text);
      dmData.trQ.StartTransaction;
      dmData.Q.Open();

      dmData.Q.Close();
      dmData.trQ.Rollback;
      dmData.trQ.StartTransaction;
{      if new_pfx <> pfx then
        dmData.Q.SQL.Text := 'update cqrlog_main set '+sql+',dxcc_ref='+ QuotedStr(new_pfx)+
                             ' where id_cqrlog_main='+IntToStr(idx)
      else
        dmData.Q.SQL.Text := 'update cqrlog_main set '+sql+' where id_cqrlog_main='+IntToStr(idx);
 }
      if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
      dmData.Q.ExecSQL;
      dmData.trQ.Commit
    end
    else begin
      dmData.Q.SQL.Text := 'update cqrlog_main set '+sql+' where id_cqrlog_main='+IntToStr(idx);
      if dmData.DebugLevel>=1 then
                       Writeln(dmData.Q.SQL.Text);
      dmData.trQ.StartTransaction;
      dmData.Q.ExecSQL;
      dmData.trQ.Commit
    end;

    inc(nr);
    pnlGrpEdt.Color:=clYellow;
    lblInfo.Caption := 'Working .... QSO nr. ' + IntToStr(nr);
    pnlGrpEdt.Repaint;
    lblInfo.Repaint
  end;

//------------------------------------------------------------------------------------------------------
 procedure DateErrSplash;
  Begin
   Application.MessageBox('Please enter correct date'+LineEnding+'as YYYY-MM-DD !','Error ...', mb_OK+mb_IconError);
  end;

//------------------------------------------------------------------------------------------------------
 function ClearDate:Boolean;
  Begin
   Result:=False;
   if Application.MessageBox('Do you really want to clear DATE?',
             'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) = idYes then
                                                                    Result:=True;
  end;
//------------------------------------------------------------------------------------------------------


begin
  case cmbField.ItemIndex of
     0 : begin
           if not dmUtils.IsDateOK(cmbValue.Text) then
           begin
             DateErrSplash;
             cmbValue.SetFocus;
             exit
           end;
           sql := 'qsodate='+QuotedStr(cmbValue.Text)
         end;
     1 : begin
           if not dmUtils.IsTimeOK(cmbValue.Text) then
           begin
             Application.MessageBox('Please enter correct time!','Error ...', mb_OK+mb_IconError);
             cmbValue.SetFocus;
             exit
           end;
           sql := 'time_on='+QuotedStr(cmbValue.Text)
         end;
     2 : begin
           if not dmUtils.IsTimeOK(cmbValue.Text) then
           begin
             Application.MessageBox('Please enter correct time!','Error ...', mb_OK+mb_IconError);
             cmbValue.SetFocus;
             exit
           end;
           sql := 'time_off='+QuotedStr(cmbValue.Text)
         end;
     3 : begin
           if cmbValue.Text <> '' then
           begin
             sql := 'callsign='+QuotedStr(UpperCase(cmbValue.text))
           end
         end;
     4 : begin
           if not dmUtils.IsFreqOK(cmbValue.Text) then
           begin
             Application.MessageBox('Please enter correct frequency!','Error ...', mb_OK+mb_IconError);
             cmbValue.SetFocus;
             exit
           end;
           sql := 'freq='+cmbValue.Text+', band='+QuotedStr(dmUtils.GetBandFromFreq(cmbValue.Text))
         end;
     5 : begin
           if not dmUtils.IsModeOK(cmbValue.Text) then
           begin
             Application.MessageBox('Please enter correct mode!','Error ...', mb_OK+mb_IconError);
             cmbValue.SetFocus;
             exit
           end;
           sql := 'mode='+QuotedStr(cmbValue.Text)
         end;
     6 : begin
           if (cmbValue.Text='') then
           begin
             Application.MessageBox('Please enter correct report!','Error ...', mb_OK+mb_IconError);
             cmbValue.SetFocus;
             exit
           end;
           sql := 'rst_s='+QuotedStr(cmbValue.Text)
         end;
     7 : begin
           if (cmbValue.Text='') then
           begin
             Application.MessageBox('Please enter correct report!','Error ...', mb_OK+mb_IconError);
             cmbValue.SetFocus;
             exit
           end;
           sql := 'rst_r='+QuotedStr(cmbValue.Text)
         end;
     8 : begin
           if (cmbValue.Text='') and (Application.MessageBox('Do you really want to clear name field?',
              'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
             exit;
           sql := 'name='+QuotedStr(cmbValue.Text)
         end;
     9 : begin
           if (cmbValue.Text='') and (Application.MessageBox('Do you really want to clear QTH field?',
              'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
           begin
             cmbValue.SetFocus;
             exit
           end;
           sql := 'qth='+QuotedStr(cmbValue.Text)
         end;
    10 : begin
           if (cmbValue.Text<>'') then
             sql := 'pwr='+QuotedStr(UpperCase(cmbValue.Text))
         end;
    11 : begin
           if not (TryStrToInt(cmbValue.Text,zone) and (zone > 0) and (zone < 76)) then
           begin
             Application.MessageBox('Please enter correct ITU zone!','Error ...', mb_OK+mb_IconError);
             cmbValue.SetFocus;
             exit
           end;
           sql := 'itu='+cmbValue.Text
         end;
    12 : begin
           if not (TryStrToInt(cmbValue.Text,zone) and (zone > 0) and (zone < 41)) then
           begin
             Application.MessageBox('Please enter correct WAZ zone!','Error ...', mb_OK+mb_IconError);
             cmbValue.SetFocus;
             exit
           end;
           sql := 'waz='+cmbValue.Text
         end;
    13 : begin
           if (cmbValue.Text='') and (Application.MessageBox('Do you really want to clear County field?',
              'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
           begin
             cmbValue.SetFocus;
             exit
           end;
           sql := 'county='+QuotedStr(cmbValue.Text)
         end;
    14 : begin
           if (cmbValue.Text='') and (Application.MessageBox('Do you really want to clear State field?',
              'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
           begin
             cmbValue.SetFocus;
             exit
           end;
           sql := 'state='+QuotedStr(UpperCase(cmbValue.Text))
         end;

    15 : begin
           if (cmbValue.Text='') and (Application.MessageBox('Do you really want to clear Award field?',
              'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
           begin
             cmbValue.SetFocus;
             exit
           end;
           sql := 'award='+QuotedStr(cmbValue.Text)
         end;
    16 : begin
           if not ((cmbValue.Text <> '') and dmUtils.IsIOTAOK(cmbValue.Text)) then
           begin
             Application.MessageBox('Please enter correct IOTA!','Error ...', mb_OK+mb_IconError);
             cmbValue.SetFocus;
             exit
           end;
           sql := 'iota='+QuotedStr(UpperCase(cmbValue.Text))
         end;
    17 : begin
           if (cmbValue.Text='') and (Application.MessageBox('Do you really want to clear Comment to QSO field?',
              'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
           begin
             cmbValue.SetFocus;
             exit
           end;
           sql := 'remarks='+QuotedStr(cmbValue.Text)
          end;
     18 : begin
          if (cmbValue.Text <> '') then
           begin
             if not dmUtils.IsLocOK(cmbValue.Text) then
              begin
               Application.MessageBox('Please enter correct locator!','Error ...', mb_OK+mb_IconError);
               cmbValue.SetFocus;
               exit
              end
            end
           else begin
             if (Application.MessageBox('Do you really want to clear My locator field?',
              'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
            begin
              cmbValue.SetFocus;
              exit
            end
           end;
            sql := 'my_loc='+QuotedStr(cmbValue.Text)
          end;
   19 : begin
          if (cmbValue.Text <> '') then
          begin
            if not dmUtils.IsLocOK(cmbValue.Text) then
            begin
              Application.MessageBox('Please enter correct locator!','Error ...', mb_OK+mb_IconError);
              cmbValue.SetFocus;
              exit
            end
          end
          else begin
            if (Application.MessageBox('Do you really want to clear Locator field?',
               'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
            begin
              cmbValue.SetFocus;
              exit
            end
          end;
          sql := 'loc='+QuotedStr(cmbValue.Text)
        end;
   20 : begin
          sql := 'profile=' + IntToStr(dmData.GetNRFromProfile(cmbValue.Text))
        end;
   21 : begin
          if (cmbValue.Text='') and (Application.MessageBox('Do you really want to clear QSL via field?',
             'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
          begin
            cmbValue.SetFocus;
            exit
          end;
          sql := 'qsl_via='+QuotedStr(UpperCase(cmbValue.Text))
        end;
   22 : begin
          if (cmbValue.ItemIndex=0) and (Application.MessageBox('Do you really want to clear QSL_S field?'
             +#10+'It also clears QSLS_DATE.',
             'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
          begin
            cmbValue.SetFocus;
            exit
          end;
          if (cmbValue.Text <> '') then
           begin
           sql := 'qsl_s='+QuotedStr(cmbValue.Text);
           if Application.MessageBox('Do you also want to set QSLS_DATE to current date?',
             'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) = idYes then
               sql:=sql+',qsls_date='+ QuotedStr(dmUtils.MyDateToStr(now));
           end
          else
           sql := 'qsl_s="",qsls_date=null'
        end;
   23 : begin
          if (cmbValue.Text<>'') and (not dmUtils.IsDateOK(cmbValue.Text))then
          begin
            DateErrSplash;
            cmbValue.SetFocus;
            exit
          end;
          if (cmbValue.Text<>'') then
            sql := 'qsls_date='+QuotedStr(cmbValue.Text)
           else
            if ClearDate then
                         sql := 'qsls_date=null';
        end;
   24 : begin
          if (cmbValue.ItemIndex=0) and (Application.MessageBox('Do you really want to clear QSL_R field?'
              +#10+'It also clears QSLR_DATE.',
             'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
          begin
            cmbValue.SetFocus;
            exit
          end;
          if (cmbValue.Text <> '') then
           begin
           sql := 'qsl_r='+QuotedStr(cmbValue.Text);
           if Application.MessageBox('Do you also want to set QSLR_DATE to current date?',
             'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) = idYes then
               sql:=sql+',qslr_date='+ QuotedStr(dmUtils.MyDateToStr(now));
           end
          else
           sql := 'qsl_r="",qslr_date=null'
        end;
   25 : begin
          if (cmbValue.Text<>'') and (not dmUtils.IsDateOK(cmbValue.Text))then
          begin
            DateErrSplash;
            cmbValue.SetFocus;
            exit
          end;
          if (cmbValue.Text<>'') then
            sql := 'qslr_date='+QuotedStr(cmbValue.Text)
           else
            if ClearDate then
                         sql := 'qslr_date=null'
        end;
   26 : begin
          if cmbValue.Text = 'Y' then
            sql := 'lotw_qsls='+QuotedStr(cmbValue.Text)+',lotw_qslsdate='+
                   QuotedStr(dmUtils.MyDateToStr(now))
          else
            sql := 'lotw_qsls="",lotw_qslsdate=null'
        end;
   27 : begin
          if (not dmUtils.IsDateOK(cmbValue.Text))then
          begin
            DateErrSplash;
            cmbValue.SetFocus;
            exit
          end
          else
            sql := 'lotw_qsls='+QuotedStr('Y')+',lotw_qslsdate='+
                   QuotedStr(cmbValue.Text)
        end;
   28 : begin
          if cmbValue.Text = 'L' then
            sql := 'lotw_qslr='+QuotedStr(cmbValue.Text)+',lotw_qslrdate='+
                   QuotedStr(dmUtils.MyDateToStr(now))
          else
            sql := 'lotw_qslr="",lotw_qslrdate=null'
        end;

   29 : begin
          if (not dmUtils.IsDateOK(cmbValue.Text))then
          begin
            DateErrSplash;
            cmbValue.SetFocus;
            exit
          end
          else
            sql := 'lotw_qslr='+QuotedStr('L')+',lotw_qslrdate='+
                   QuotedStr(cmbValue.Text)
        end;
   30 : begin
          if cmbValue.Text = 'Y' then
            sql := 'eqsl_qsl_sent='+QuotedStr(cmbValue.Text)+',eqsl_qslsdate='+
                   QuotedStr(dmUtils.MyDateToStr(now))
          else
            sql := 'eqsl_qsl_sent="",eqsl_qslsdate=null'
        end;
   31 : begin
          if (not dmUtils.IsDateOK(cmbValue.Text))then
          begin
            DateErrSplash;
            cmbValue.SetFocus;
            exit
          end
          else
            sql := 'eqsl_qsl_sent='+QuotedStr('Y')+',eqsl_qslsdate='+
                   QuotedStr(cmbValue.Text)
        end;
   32 : begin
          if cmbValue.Text = 'E' then
            sql := 'eqsl_qsl_rcvd='+QuotedStr(cmbValue.Text)+',eqsl_qslrdate='+
                   QuotedStr(dmUtils.MyDateToStr(now))
          else
            sql := 'eqsl_qsl_rcvd="",eqsl_qslrdate=null'
        end;
   33 : begin
          if (not dmUtils.IsDateOK(cmbValue.Text))then
          begin
            DateErrSplash;
            cmbValue.SetFocus;
            exit
          end
          else
            sql := 'eqsl_qsl_rcvd='+QuotedStr('E')+',eqsl_qslrdate='+
                   QuotedStr(cmbValue.Text)
        end;
   34 : begin
           if (cmbValue.Text='') and (Application.MessageBox('Do you really want to clear Contest name field?',
              'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
             exit;
           sql := 'contestname='+QuotedStr(ExtractWord(1,cmbValue.Text,['|']));
         end;
   35 : begin
           if (cmbValue.Text='') and (Application.MessageBox('Do you really want to clear Propagation mode field?',
              'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
             exit;
           sql := 'prop_mode='+QuotedStr(ExtractWord(1,cmbValue.Text,['|']));
         end;
   36 : begin
           if (cmbValue.Text='') and (Application.MessageBox('Do you really want to clear Satellite field?',
              'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
             exit;
           sql := 'satellite='+QuotedStr(ExtractWord(1,cmbValue.Text,['|']));
         end;
   37 : begin
           if (cmbValue.Text='') and (Application.MessageBox('Do you really want to clear Operator field?',
              'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
             exit;
           sql := 'operator='+QuotedStr(cmbValue.Text)
         end;
   38 : begin
           if (cmbValue.Text='') and (Application.MessageBox('Do you really want to clear DOK field?',
              'Question ...',mb_YesNo+mb_IconQuestion+mb_DefButton2) in [idNo, idCancel]) then
             exit;
           sql := 'dok='+QuotedStr(cmbValue.Text)
         end;

  end;
  if sql = '' then exit;
  try
    if Selected then
    begin
      SetLength(aid,frmMain.dbgrdMain.SelectedRows.Count);
      for i := 0 to frmMain.dbgrdMain.SelectedRows.Count-1 do
      begin
        dmData.qCQRLOG.GotoBookmark(Pointer(frmMain.dbgrdMain.SelectedRows.Items[i]));
        aid[i] := dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger;
        Writeln('id: ',dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsInteger)
      end;
      for i:=0 to Length(aid)-1 do
        ChangeQSO(aid[i])
    end
    else begin
      dmData.qCQRLOG.DisableControls;
      dmData.qCQRLOG.First;
      while not dmData.qCQRLOG.EOF do
      begin
        ChangeQSO(dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsLongint);
        dmData.qCQRLOG.Next
      end
    end
  finally
    dmData.qCQRLOG.EnableControls;
    frmMain.acRefresh.Execute
  end;
  lblInfo.Caption := 'Group edit done '+WhereTo;
  btnCancel.Caption:= 'Close';
  btnApply.Enabled:=False;
  pnlGrpEdt.Color:= clLime;
  pnlGrpEdt.Repaint;
  lblInfo.Repaint;
end;

end.

