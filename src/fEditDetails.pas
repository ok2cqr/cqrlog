unit fEditDetails;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, LCLType;

type

  { TfrmEditDetails }

  TfrmEditDetails = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    edtLoTWQSLRDate: TEdit;
    edteQSLRDate : TEdit;
    edteQSLSDate : TEdit;
    edtQSLSDate: TEdit;
    edtQSLRDate: TEdit;
    edtLoTWQSLSDate: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5 : TLabel;
    Label6 : TLabel;
    procedure btnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmEditDetails: TfrmEditDetails;

implementation
{$R *.lfm}

uses dData, dUtils, dDXCC;

{ TfrmEditDetails }

procedure TfrmEditDetails.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(frmEditDetails);
  edtQSLSDate.Text     := dmData.qCQRLOG.FieldByName('qsls_date').AsString;
  edtQSLRDate.Text     := dmData.qCQRLOG.FieldByName('qslr_date').AsString;
  edtLoTWQSLSDate.Text := dmData.qCQRLOG.FieldByName('lotw_qslsdate').AsString;
  edtLoTWQSLRDate.Text := dmData.qCQRLOG.FieldByName('lotw_qslrdate').AsString;
  edteQSLSDate.Text    := dmData.qCQRLOG.FieldByName('eqsl_qslsdate').AsString;
  edteQSLRDate.Text    := dmData.qCQRLOG.FieldByName('eqsl_qslrdate').AsString;
  edtQSLSDate.SetFocus
end;

procedure TfrmEditDetails.btnOKClick(Sender: TObject);
var
  sql1, sql2, sql3, sql4, sql5, sql6 : String;
begin
  if (edtQSLSDate.Text <> '') and (not dmUtils.IsDateOK(edtQSLSDate.Text)) then
  begin
    Application.MessageBox('Please enter correct date!','Error ...', mb_OK+mb_IconError);
    edtQSLSDate.SetFocus;
    exit
  end;
  if edtQSLSDate.Text = '' then
    sql1 := 'qsls_date=NULL'
  else
    sql1 := 'qsls_date='+QuotedStr(edtQSLSDate.Text);

  if (edtQSLRDate.Text <> '') and (not dmUtils.IsDateOK(edtQSLRDate.Text)) then
  begin
    Application.MessageBox('Please enter correct date!','Error ...', mb_OK+mb_IconError);
    edtQSLRDate.SetFocus;
    exit
  end;
  if edtQSLRDate.Text = '' then
    sql2 := 'qslr_date=NULL'
  else
    sql2 := 'qslr_date='+QuotedStr(edtQSLRDate.Text);

  if (edtLoTWQSLSDate.Text <> '') and (not dmUtils.IsDateOK(edtLoTWQSLSDate.Text)) then
  begin
    Application.MessageBox('Please enter correct date!','Error ...', mb_OK+mb_IconError);
    edtLoTWQSLSDate.SetFocus;
    exit
  end;
  if edtLoTWQSLSDate.Text = '' then
    sql3 := 'lotw_qslsdate= NULL,lotw_qsls='+QuotedStr('')
  else
    sql3 := 'lotw_qslsdate='+QuotedStr(edtLoTWQSLSDate.Text)+',lotw_qsls='+QuotedStr('Y');

  if (edtLoTWQSLRDate.Text <> '') and (not dmUtils.IsDateOK(edtLoTWQSLRDate.Text)) then
  begin
    Application.MessageBox('Please enter correct date!','Error ...', mb_OK+mb_IconError);
    edtLoTWQSLRDate.SetFocus;
    exit
  end;
  if edtLoTWQSLRDate.Text = '' then
    sql4          := 'lotw_qslrdate=NULL,lotw_qslr='+QuotedStr('')
  else
    sql4          := 'lotw_qslrdate='+QuotedStr(edtLoTWQSLRDate.Text)+',lotw_qslr='+QuotedStr('L');

  if (edteQSLSDate.Text <> '') and (not dmUtils.IsDateOK(edteQSLSDate.Text)) then
  begin
    Application.MessageBox('Please enter correct date!','Error ...', mb_OK+mb_IconError);
    edteQSLSDate.SetFocus;
    exit
  end;
  if edteQSLSDate.Text = '' then
    sql5          := 'eqsl_qslsdate=NULL,eqsl_qsl_sent='+QuotedStr('')
  else
    sql5          := 'eqsl_qslsdate='+QuotedStr(edteQSLSDate.Text)+',eqsl_qsl_sent='+QuotedStr('Y');

  if (edteQSLRDate.Text <> '') and (not dmUtils.IsDateOK(edteQSLRDate.Text)) then
  begin
    Application.MessageBox('Please enter correct date!','Error ...', mb_OK+mb_IconError);
    edteQSLRDate.SetFocus;
    exit
  end;
  if edteQSLRDate.Text = '' then
    sql6          := 'eqsl_qslrdate=NULL,eqsl_qsl_rcvd='+QuotedStr('')
  else
    sql6          := 'eqsl_qslrdate='+QuotedStr(edteQSLRDate.Text)+',eqsl_qsl_rcvd='+QuotedStr('E');

  dmData.Q.Close;
  dmData.Q.SQL.Text := 'update cqrlog_main set '+sql1+','+sql2+','+sql3+','+sql4+','+sql5+','+sql6+
                       ' where id_cqrlog_main='+
                       IntToStr(dmData.qCQRLOG.FieldByName('id_cqrlog_main').AsLongint);
  if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
  dmData.trQ.StartTransaction;
  dmData.Q.ExecSQL;
  dmData.trQ.Commit;
  ModalResult := mrOK
end;


end.

