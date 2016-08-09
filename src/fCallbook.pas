unit fCallbook;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Buttons, httpsend, iniFiles;

type

  { TfrmCallbook }

  TfrmCallbook = class(TForm)
    btnSearch: TButton;
    edtCall: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    lblGrid: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    lblCounty: TLabel;
    lblQSL: TLabel;
    lblState: TLabel;
    mCallbook: TMemo;
    Panel1: TPanel;
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure FormShow(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure edtCallKeyPress(Sender: TObject; var Key: char);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmCallbook: TfrmCallbook;

implementation
{$R *.lfm}

{ TfrmCallbook }

uses dUtils, dData, uMyIni;

procedure TfrmCallbook.edtCallKeyPress(Sender: TObject; var Key: char);
begin
  if key = #13 then
  begin
    btnSearch.Click;
    key := #0
  end
end;

procedure TfrmCallbook.btnSearchClick(Sender: TObject);
var
  c_callsign  : String;
  c_nick      : String;
  c_qth       : String;
  c_address   : String;
  c_zip       : String;
  c_grid      : String;
  c_state     : String;
  c_county    : String;
  c_qsl       : String;
  c_iota      : String;
  c_waz       : String;
  c_itu       : String;
  c_ErrMsg    : String;
begin
  mCallbook.Lines.Clear;
  mCallBook.Lines.Add('Working ...');
  mCallbook.Repaint;
  c_callsign := dmUtils.GetIDCall(edtCall.Text);
  Application.ProcessMessages;
  dmUtils.GetCallBookData(c_callsign,c_nick,c_qth,c_address,c_zip,c_grid,c_state,c_county,c_qsl,c_iota,c_waz,c_itu,c_ErrMsg);
  if c_ErrMsg = '' then
  begin
    mCallbook.Text    := c_address;
    lblGrid.Caption   := c_grid;
    lblState.Caption  := c_state;
    lblCounty.Caption := c_county;
    lblQSL.Caption    := c_qsl
  end
  else
    mCallbook.Text := c_ErrMsg
end;

procedure TfrmCallbook.FormShow(Sender: TObject);
begin
  dmUtils.LoadFontSettings(frmCallbook);
  edtCall.SetFocus;
  edtCall.SelectAll;
  mCallbook.Clear
end;

procedure TfrmCallbook.FormKeyPress(Sender: TObject; var Key: char);
begin
  if key = #27 then
  begin
    key := #0;
    Close
  end;
end;

end.

