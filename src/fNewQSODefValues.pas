unit fNewQSODefValues;

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,FileUtil,LResources,Forms,Controls,Graphics,Dialogs,ExtCtrls,
  StdCtrls;

type

  { TfrmNewQSODefValues }

  TfrmNewQSODefValues = class(TForm)
    btnMoveDwn : TButton;
    btnCancel : TButton;
    Button1 : TButton;
    btnDelete : TButton;
    btnMoveUp : TButton;
    btnOK : TButton;
    Button2 : TButton;
    Button3: TButton;
    edtValue : TEdit;
    lblDesc : TLabel;
    lbValues : TListBox;
    Panel1 : TPanel;
    Panel2 : TPanel;
    procedure btnDeleteClick(Sender: TObject);
    procedure btnMoveDwnClick(Sender: TObject);
    procedure btnMoveUpClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormClose(Sender : TObject; var CloseAction : TCloseAction);
    procedure FormShow(Sender : TObject);
  private
    procedure LoadValues;
  public
    WhatChangeDesc : String;
    WhatChange     : String;
    function  GetValues : String;
  end; 

var
  frmNewQSODefValues : TfrmNewQSODefValues;

implementation
{$R *.lfm}

{ TfrmNewQSODefValues }

uses dUtils;

procedure TfrmNewQSODefValues.FormClose(Sender : TObject;
  var CloseAction : TCloseAction);
begin
  dmUtils.SaveWindowPos(frmNewQSODefValues)
end;

procedure TfrmNewQSODefValues.Button1Click(Sender: TObject);
begin
  if ((lbValues.ItemIndex) = (lbValues.Items.Count-1)) then
    lbValues.Items.Add(edtValue.Text)
  else
    lbValues.Items.Insert(lbValues.ItemIndex+1,edtValue.Text);
  edtValue.Text := ''
end;

procedure TfrmNewQSODefValues.btnDeleteClick(Sender: TObject);
var
  i : Integer;
begin
  if lbValues.Items.Count > 0 then
  begin
    if lbValues.ItemIndex=0 then
      i := 0
    else
      i := lbValues.ItemIndex-1;
    lbValues.Items.Delete(lbValues.ItemIndex);
    if lbValues.Count > 0 then
      lbValues.ItemIndex := i
  end;
end;

procedure TfrmNewQSODefValues.btnMoveDwnClick(Sender: TObject);
var
  i : Integer;
begin
  if (lbValues.Items.Count > 0) and (lbValues.ItemIndex<lbValues.Count-1) then
  begin
    i := lbValues.ItemIndex+1;
    lbValues.Items.Move(lbValues.ItemIndex,lbValues.ItemIndex+1);
    lbValues.ItemIndex := i
  end;
  lbValues.SetFocus
end;

procedure TfrmNewQSODefValues.btnMoveUpClick(Sender: TObject);
var
  i : Integer;
begin
  if (lbValues.Items.Count > 0) and (lbValues.ItemIndex>0) then
  begin
    i := lbValues.ItemIndex-1;
    lbValues.Items.Move(lbValues.ItemIndex,lbValues.ItemIndex-1);
    lbValues.ItemIndex := i
  end;
  lbValues.SetFocus
end;

procedure TfrmNewQSODefValues.Button2Click(Sender: TObject);
begin
  if lbValues.Items.Count > 0 then
    lbValues.Items.Strings[lbValues.ItemIndex] := edtValue.Text;
  lbValues.SetFocus
end;

procedure TfrmNewQSODefValues.Button3Click(Sender: TObject);
var
  cDefaultModes : String;
  i : Integer;
begin
  cDefaultModes := '';
  if WhatChangeDesc = 'Frequency' then
  begin
    WhatChange := dUtils.cDefaultFreq;
    LoadValues
  end;
  if WhatChangeDesc = 'Mode' then
  begin
    for i := 0 to cMaxModes do
    begin
      cDefaultModes := cDefaultModes + '|' + cModes[i];
    end;
    WhatChange := cDefaultModes;
    LoadValues
  end;
end;

procedure TfrmNewQSODefValues.FormShow(Sender : TObject);
begin
  dmUtils.LoadWindowPos(frmNewQSODefValues);
  Caption         := 'Change new QSO window default values - '+WhatChangeDesc;
  lblDesc.Caption := WhatChangeDesc;
  edtValue.Text   := '';
  LoadValues
end;

procedure TfrmNewQSODefValues.LoadValues;
var
  a : TExplodeArray;
  i : Integer;
begin
  lbValues.Items.Clear;
  a := dmUtils.Explode('|',WhatChange);
  for i:=0 to Length(a)-1 do
    if a[i] <> '' then
      lbValues.Items.Add(a[i]);
end;

function TfrmNewQSODefValues.GetValues : String;
var
  i : Integer;
begin
  Result := '';
  for i:=0 to lbValues.Items.Count-1 do
    if lbValues.Items.Strings[i] <> '' then
      Result := Result + '|' +lbValues.Items.Strings[i]
end;

end.

