unit fCWType;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Spin, inifiles, lcltype,ActnList,frCWKeys;

type

  { TfrmCWType }

  TfrmCWType = class(TForm)
    btnClose: TButton;
    btnClear: TButton;
    edtSpeed: TSpinEdit;
    fraCWKeys1 : TfraCWKeys;
    Label1: TLabel;
    Label85: TLabel;
    m: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    rgMode: TRadioGroup;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure edtSpeedChange(Sender: TObject);
    procedure mKeyPress(Sender: TObject; var Key: char);
    procedure mKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmCWType: TfrmCWType;

implementation
{$R *.lfm}

{ TfrmCWType }
uses fNewQSO,dUtils,dData, uMyIni;

procedure TfrmCWType.btnClearClick(Sender: TObject);
begin
  m.Clear
end;

procedure TfrmCWType.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = 27 then
    frmNewQSO.CWint.StopSending
end;

procedure TfrmCWType.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  cqrini.WriteInteger('CW','Mode',rgMode.ItemIndex);
  dmUtils.SaveWindowPos(frmCWType)
end;

procedure TfrmCWType.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmCWType);
  rgMode.ItemIndex := cqrini.ReadInteger('CW','Mode',1);
  fraCWKeys1.UpdateFKeyLabels;
  m.SetFocus;
  m.Clear
end;

procedure TfrmCWType.btnCloseClick(Sender: TObject);
begin
  Close
end;

procedure TfrmCWType.edtSpeedChange(Sender: TObject);
begin
  frmNewQSO.CWint.SetSpeed(edtSpeed.Value)
end;

procedure TfrmCWType.mKeyPress(Sender: TObject; var Key: char);
var
  tmp   : String = '';
  i     : Integer = 0;
  mess  : String = '';
  CWkey : char;
begin
  CWkey :=key;
  if CWkey <> '' then
    CWkey := UpperCase(CWkey)[1];
  if (CWkey in ['A'..'Z']) or (CWkey in ['0'..'9']) or (CWkey = '=') or
   (CWkey = '?') or (CWkey = ',') or (CWkey='.') or (CWkey='/') or (CWkey = ' ') or
   (CWkey = '<') or (CWkey = '>') or (CWkey = ':') or (CWkey = ')') or (CWkey = '(') or
   (CWkey = ';') or (CWkey = '@') or (CWkey = 'ß') or (CWkey ='Ü') or (CWkey ='Ö') or
   (CWkey = 'Ä') then
  begin
    if rgMode.ItemIndex = 0 then //letter mode
      frmNewQSO.CWint.SendText(CWkey)
    else begin                   //word mode
      if (Pos(' ',m.Text) = 0) and (rgMode.ItemIndex=1) then  //fist word is send character by character
        frmNewQSO.CWint.SendText(CWkey)
      else begin
        if (CWkey = ' ') then
        begin
          tmp := '';
          mess := m.Text;
          if Pos(' ',mess) > 0 then
          begin
            if dmData.DebugLevel >=1 then
              Writeln('Text:',mess,':');
            for i:= Length(mess) downto 1 do
            begin
              if mess[i] = ' ' then
                Break
              else
                tmp := mess[i] + tmp
            end;
            frmNewQSO.CWint.SendText(tmp)
          end
        end
      end
    end
  end
end;

procedure TfrmCWType.mKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  speed : Integer = 0;
begin

  if (key = VK_BACK) and (rgMode.ItemIndex=0) then
  begin
    frmNewQSO.CWint.DelLastChar
  end;
  
  if key = 33 then//pgup
  begin
    speed := frmNewQSO.CWint.GetSpeed+2;
    frmNewQSO.CWint.SetSpeed(speed);
    edtSpeed.Value := speed;
    key := 0
  end;

  if key = 34 then//pgup
  begin
    speed := frmNewQSO.CWint.GetSpeed-2;
    frmNewQSO.CWint.SetSpeed(speed);
    edtSpeed.Value := speed;
    key := 0
  end;

  if (key >= VK_F1) and (key <= VK_F10) then
  begin
    frmNewQSO.CWint.SendText(dmUtils.GetCWMessage(dmUtils.GetDescKeyFromCode(key),frmNewQSO.edtCall.Text,
                             frmNewQSO.edtHisRST.Text,frmNewQSO.edtName.Text,frmNewQSO.lblGreeting.Caption,''))
  end;

  if Key = VK_ESCAPE then
    frmNewQSO.CWint.StopSending
end;

end.

