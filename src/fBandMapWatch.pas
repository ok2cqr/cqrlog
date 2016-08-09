unit fBandMapWatch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TfrmBandMapWatch }

  TfrmBandMapWatch = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    chkIOTA: TCheckBox;
    chkAN: TCheckBox;
    chkOC: TCheckBox;
    chkAF: TCheckBox;
    chkSA: TCheckBox;
    chkNA: TCheckBox;
    chkAS: TCheckBox;
    chkEU: TCheckBox;
    edtDXCC: TEdit;
    edtITU: TEdit;
    edtWAZ: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmBandMapWatch: TfrmBandMapWatch;

implementation
{$R *.lfm}

{ TfrmBandMapWatch }

end.

