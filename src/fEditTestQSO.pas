unit fEditTestQSO;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls;

type

  { TfrmEditTestQSO }

  TfrmEditTestQSO = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    chkMult1: TCheckBox;
    chkMult2: TCheckBox;
    edtIOTA: TEdit;
    edtWPX: TEdit;
    edtITU: TEdit;
    edtPoints: TEdit;
    edtPower: TEdit;
    edtQTH: TEdit;
    edtName: TEdit;
    edtEXCH1: TEdit;
    edtEXCH2: TEdit;
    edtRSTS: TEdit;
    edtMode: TEdit;
    edtFreq: TEdit;
    edtCall: TEdit;
    edtDate: TEdit;
    edtRSTR: TEdit;
    edtState: TEdit;
    edtTime: TEdit;
    edtWAZ: TEdit;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    lblIOTA: TLabel;
    Label2: TLabel;
    Label22: TLabel;
    Label25: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmEditTestQSO: TfrmEditTestQSO;

implementation

{ TfrmEditTestQSO }
uses dUtils;

procedure TfrmEditTestQSO.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmEditTestQSO)
end;

procedure TfrmEditTestQSO.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmEditTestQSO)
end;

initialization
  {$I fEditTestQSO.lrs}

end.

