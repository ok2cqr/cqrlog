unit fBandMapFilter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, lclType;

type

  { TfrmBandMapFilter }

  TfrmBandMapFilter = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    chkOnlyeQSL: TCheckBox;
    chkOnlyLoTW: TCheckBox;
    chkShowActiveBandFil: TCheckBox;
    edtDate: TEdit;
    edtLastHours: TEdit;
    edtTime: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    rbShowAll: TRadioButton;
    rbNoWkdHour: TRadioButton;
    rbNoWkdDate: TRadioButton;
    procedure btnOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmBandMapFilter: TfrmBandMapFilter;

implementation
{$R *.lfm}

uses dUtils, uMyIni;

procedure TfrmBandMapFilter.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(self);
  rbShowAll.Checked   := cqrini.ReadBool('BandMapFilter','ShowAll',True);
  rbNoWkdHour.Checked := cqrini.ReadBool('BandMapFilter','NoWkdHour',False);
  rbNoWkdDate.Checked := cqrini.ReadBool('BandMapFilter','NoWkdDate',False);

  edtLastHours.Text := IntToStr(cqrini.ReadInteger('BandMapFilter','LastHours',48));
  edtDate.Text      := cqrini.ReadString('BandMapFilter','LastDate','');
  edtTime.Text      := cqrini.ReadString('BandMapFilter','LastTime','');

  chkOnlyeQSL.Checked := cqrini.ReadBool('BandMapFilter','OnlyeQSL',False);
  chkOnlyLoTW.Checked := cqrini.ReadBool('BandMapFilter','OnlyLoTW',False) ;

  chkShowActiveBandFil.Checked := cqrini.ReadBool('BandMap', 'OnlyActiveBand', False);
end;

procedure TfrmBandMapFilter.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(self)
end;

procedure TfrmBandMapFilter.btnOKClick(Sender: TObject);
var
  LastHours : Integer;
begin
  if not TryStrToInt(edtLastHours.Text,LastHours) then
  begin
    Application.MessageBox('Please enter correct number of hours','Info...',mb_OK+mb_IconInformation);
    edtLastHours.SetFocus;
    exit
  end;

  if rbNoWkdDate.Checked then
  begin
    if not dmUtils.isDateOK(edtDate.Text) then
    begin
      Application.MessageBox('Please enter correct date (yyyy-mm-dd)','Info...',mb_OK+mb_IconInformation);
      edtDate.SetFocus;
      exit
    end;
    if not dmUtils.isTimeOK(edtTime.Text) then
    begin
      Application.MessageBox('Please enter correct time (HH:MM)','Info...',mb_OK+mb_IconInformation);
      edtTime.SetFocus;
      exit
    end
  end;

  cqrini.WriteBool('BandMapFilter','ShowAll',rbShowAll.Checked);
  cqrini.WriteBool('BandMapFilter','NoWkdHour',rbNoWkdHour.Checked);
  cqrini.WriteBool('BandMapFilter','NoWkdDate',rbNoWkdDate.Checked);

  cqrini.WriteInteger('BandMapFilter','LastHours',LastHours);
  cqrini.WriteString('BandMapFilter','LastDate',edtDate.Text);
  cqrini.WriteString('BandMapFilter','LastTime',edtTime.Text);

  cqrini.WriteBool('BandMapFilter','OnlyeQSL',chkOnlyeQSL.Checked);
  cqrini.WriteBool('BandMapFilter','OnlyLoTW',chkOnlyLoTW.Checked);

  cqrini.WriteBool('BandMap', 'OnlyActiveBand', chkShowActiveBandFil.Checked);

  ModalResult := mrOK
end;

end.

