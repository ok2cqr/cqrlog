unit fIOTAStat;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Buttons, StdCtrls, Grids, inifiles;

type
  TStat = (
    stCfmOnly, //paper only
    stCfmLoTW, //paper + LoTW
    stLoTWOnly,//LoTW only
    stCfmeQSL, //paper + eQSL
    stLoTWeQSL, //LoTW + eQSL
    steQSLOnly,     //eQSL only
    stAll       //paper + LoTW + eQSL
    );


type

  { TfrmIOTAStat }

  TfrmIOTAStat = class(TForm)
    Button1: TButton;
    btnSave: TButton;
    chkOnlyCFM: TCheckBox;
    cmbCfmType : TComboBox;
    mIOTA: TMemo;
    Panel1: TPanel;
    dlgSave: TSaveDialog;
    procedure cmbCfmTypeChange(Sender : TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure chkOnlyCFMChange(Sender: TObject);
  private
    aIOTA : Array[0..6] of String;
    procedure CreateStat;

    function  GetStatTypeWhere(st : TStat) : String;
  public
    { public declarations }
  end; 

var
  frmIOTAStat: TfrmIOTAStat;

implementation
{$R *.lfm}

{ TfrmIOTAStat }
uses dData,dUtils, uMyIni;

function TfrmIOTAStat.GetStatTypeWhere(st : TStat) : String;
begin
  case st of
    stCfmOnly :  begin //only cfm
                   Result := 'qsl_r = '+QuotedStr('Q')
                 end;
    stCfmLoTW :  begin //cfm + LoTW
                   Result := '((qsl_r = '+QuotedStr('Q')+') or (lotw_qslr = '+QuotedStr('L')+'))'
                 end;
    stLoTWOnly : begin //LoTW only
                   Result := 'lotw_qslr = '+QuotedStr('L')
                 end;
    stCfmeQSL  : begin
                   Result := '((qsl_r = '+QuotedStr('Q')+') or (eqsl_qsl_rcvd = '+QuotedStr('E')+'))'
                 end;
    stLoTWeQSL : begin
                   Result := '((eqsl_qsl_rcvd = '+QuotedStr('E')+') or (lotw_qslr = '+QuotedStr('L')+'))'
                 end;
    steQSLOnly : begin
                   Result := '(eqsl_qsl_rcvd = '+QuotedStr('E')+')'
                 end;
    stAll      : begin
                   Result := '((eqsl_qsl_rcvd = '+QuotedStr('E')+') or (lotw_qslr = '+QuotedStr('L')+') or '+
                             '(qsl_r='+QuotedStr('Q')+'))'
                 end
    end; //case
end;


procedure TfrmIOTAStat.FormShow(Sender: TObject);
begin
  cmbCfmType.ItemIndex := cqrini.ReadInteger('IOTA','LastStat',6);
  CreateStat
end;

procedure TfrmIOTAStat.FormCreate(Sender: TObject);
begin
  aIOTA[0] := 'EU';
  aIOTA[1] := 'AF';
  aIOTA[2] := 'AN';
  aIOTA[3] := 'AS';
  aIOTA[4] := 'NA';
  aIOTA[5] := 'OC';
  aIOTA[6] := 'SA';
  dmUtils.LoadWindowPos(self)
end;

procedure TfrmIOTAStat.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  dmUtils.SaveWindowPos(self)
end;

procedure TfrmIOTAStat.cmbCfmTypeChange(Sender : TObject);
begin
  if chkOnlyCFM.Checked then
    CreateStat
end;

procedure TfrmIOTAStat.btnSaveClick(Sender: TObject);
begin
  dlgSave.DefaultExt := '.txt';
  dlgSave.Filter := 'Text files|*.txt;';
  if dlgSave.Execute then
    mIOTA.Lines.SaveToFile(dlgSave.FileName);
end;

procedure TfrmIOTAStat.chkOnlyCFMChange(Sender: TObject);
begin
  CreateStat
end;

procedure TfrmIOTAStat.CreateStat;
const
  C_SEL = 'select distinct iota,callsign from cqrlog_main %s group by iota order by iota';
  C_SUM = 'select count(*) from (select count(iota) from cqrlog_main %s group by iota) as aa';
var
  i       : Integer = 0;
  where   : String = '';
  sumiota : Integer = 0;
begin
  mIOTA.Clear;
  cqrini.WriteInteger('IOTA','LastStat',cmbCfmType.ItemIndex);
  dmData.Q.Close;
  dmData.trQ.StartTransaction;
  for i:=0 to 6 do
  begin
    if chkOnlyCFM.Checked then
      where := ' where ' + GetStatTypeWhere(TStat(cmbCfmType.ItemIndex)) +
               ' and (iota like '+QuotedStr(aIOTA[i]+'-%') + ')'
    else
      where := ' where (iota like '+QuotedStr(aIOTA[i]+'-%') + ')';

    dmData.Q.SQL.Text := Format(C_SEL,[where]);
    dmData.Q.Open();
    while not dmData.Q.Eof do
    begin
      mIOTA.Lines.Add(dmData.Q.Fields[0].AsString + #9 + dmData.Q.Fields[1].AsString);
      dmData.Q.Next
    end;
    dmData.Q.Close();
    mIOTA.Lines.Add('')
  end;
  dmData.trQ.Rollback;

  dmData.trQ.StartTransaction;
  try
    mIOTA.Lines.Add('------------------');
    for i:=0 to 6 do
    begin
      if chkOnlyCFM.Checked then
        where := ' where ' + GetStatTypeWhere(TStat(cmbCfmType.ItemIndex)) +
                 ' and (iota like '+QuotedStr(aIOTA[i]+'-%') + ')'
      else
        where := ' where (iota like '+QuotedStr(aIOTA[i]+'-%') + ')';
      dmData.Q.SQL.Text := Format(C_SUM,[where]);
      dmData.Q.Open;
      mIOTA.Lines.Add(aIOTA[i]+' islands: '+IntToStr(dmData.Q.Fields[0].AsInteger));
      sumiota := sumiota + dmData.Q.Fields[0].AsInteger;
      dmData.Q.Close
    end;
    mIOTA.Lines.Add('-------------------');
    mIOTA.Lines.Add('Total: ' + IntToStr(sumiota))
  finally
    dmData.Q.Close;
    dmData.trQ.Rollback
  end
end;

end.

