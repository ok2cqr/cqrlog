unit fDefaultFreq;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, inifiles;

type

  { TfrmDefaultFreq }

  TfrmDefaultFreq = class(TForm)
    Bevel1: TBevel;
    Bevel2: TBevel;
    btnOK: TButton;
    btnCancel: TButton;
    edt10btn : TEdit;
    edt2btn : TEdit;
    edt70btn : TEdit;
    edt6btn : TEdit;
    edt160btn : TEdit;
    edt15am: TEdit;
    edt80btn : TEdit;
    edt160cw: TEdit;
    edt15cw: TEdit;
    edt15fm: TEdit;
    edt15rtty: TEdit;
    edt160ssb: TEdit;
    edt160rtty: TEdit;
    edt160am: TEdit;
    edt160fm: TEdit;
    edt15ssb: TEdit;
    edt70am: TEdit;
    edt70cw: TEdit;
    edt70fm: TEdit;
    edt70rtty: TEdit;
    edt70ssb: TEdit;
    edt20am: TEdit;
    edt17am: TEdit;
    edt2am: TEdit;
    edt20cw: TEdit;
    edt17cw: TEdit;
    edt2cw: TEdit;
    edt20fm: TEdit;
    edt17fm: TEdit;
    edt2fm: TEdit;
    edt20rtty: TEdit;
    edt17rtty: TEdit;
    edt2rtty: TEdit;
    edt20ssb: TEdit;
    edt17ssb: TEdit;
    edt2ssb: TEdit;
    edt6am: TEdit;
    edt6cw: TEdit;
    edt6fm: TEdit;
    edt6rtty: TEdit;
    edt6ssb: TEdit;
    edt40am: TEdit;
    edt30am: TEdit;
    edt30cw: TEdit;
    edt30fm: TEdit;
    edt30rtty: TEdit;
    edt30ssb: TEdit;
    edt10am: TEdit;
    edt10cw: TEdit;
    edt10fm: TEdit;
    edt10rtty: TEdit;
    edt10ssb: TEdit;
    edt12am: TEdit;
    edt40btn : TEdit;
    edt30btn : TEdit;
    edt20btn : TEdit;
    edt17btn : TEdit;
    edt15btn : TEdit;
    edt12btn : TEdit;
    edt80cw: TEdit;
    edt40cw: TEdit;
    edt40fm: TEdit;
    edt40rtty: TEdit;
    edt12cw: TEdit;
    edt12fm: TEdit;
    edt12rtty: TEdit;
    edt80ssb: TEdit;
    edt80rtty: TEdit;
    edt80am: TEdit;
    edt80fm: TEdit;
    edt40ssb: TEdit;
    edt12ssb: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmDefaultFreq: TfrmDefaultFreq;

implementation
{$R *.lfm}

uses dData, uMyIni;

procedure TfrmDefaultFreq.FormShow(Sender: TObject);
begin
  edt160btn.Text  := cqrini.ReadString('DefFreq','160btn','160m');
  edt160cw.Text   := cqrini.ReadString('DefFreq','160cw','1830');
  edt160ssb.Text  := cqrini.ReadString('DefFreq','160ssb','1845');
  edt160rtty.Text := cqrini.ReadString('DefFreq','160rtty','1845');
  edt160am.Text   := cqrini.ReadString('DefFreq','160am','1845');
  edt160fm.Text   := cqrini.ReadString('DefFreq','160fm','1845');

  edt80btn.Text  := cqrini.ReadString('DefFreq','80btn','80m');
  edt80cw.Text   := cqrini.ReadString('DefFreq','80cw','3525');
  edt80ssb.Text  := cqrini.ReadString('DefFreq','80ssb','3750');
  edt80rtty.Text := cqrini.ReadString('DefFreq','80rtty','3590');
  edt80am.Text   := cqrini.ReadString('DefFreq','80am','3750');
  edt80fm.Text   := cqrini.ReadString('DefFreq','80fm','3750');

  edt40btn.Text  := cqrini.ReadString('DefFreq','40btn','40m');
  edt40cw.Text   := cqrini.ReadString('DefFreq','40cw','7015');
  edt40ssb.Text  := cqrini.ReadString('DefFreq','40ssb','7080');
  edt40rtty.Text := cqrini.ReadString('DefFreq','40rtty','7040');
  edt40am.Text   := cqrini.ReadString('DefFreq','40am','7080');
  edt40fm.Text   := cqrini.ReadString('DefFreq','40fm','7080');

  edt30btn.Text  := cqrini.ReadString('DefFreq','30btn','30m');
  edt30cw.Text   := cqrini.ReadString('DefFreq','30cw','10110');
  edt30ssb.Text  := cqrini.ReadString('DefFreq','30ssb','10130');
  edt30rtty.Text := cqrini.ReadString('DefFreq','30rtty','10130');
  edt30am.Text   := cqrini.ReadString('DefFreq','30am','10130');
  edt30fm.Text   := cqrini.ReadString('DefFreq','30fm','10130');

  edt20btn.Text  := cqrini.ReadString('DefFreq','20btn','20m');
  edt20cw.Text   := cqrini.ReadString('DefFreq','20cw','14025');
  edt20ssb.Text  := cqrini.ReadString('DefFreq','20ssb','14195');
  edt20rtty.Text := cqrini.ReadString('DefFreq','20rtty','14090');
  edt20am.Text   := cqrini.ReadString('DefFreq','20am','14195');
  edt20fm.Text   := cqrini.ReadString('DefFreq','20fm','14195');

  edt17btn.Text  := cqrini.ReadString('DefFreq','17btn','17m');
  edt17cw.Text   := cqrini.ReadString('DefFreq','17cw','18080');
  edt17ssb.Text  := cqrini.ReadString('DefFreq','17ssb','18140');
  edt17rtty.Text := cqrini.ReadString('DefFreq','17rtty','18110');
  edt17am.Text   := cqrini.ReadString('DefFreq','17am','18140');
  edt17fm.Text   := cqrini.ReadString('DefFreq','17fm','18140');

  edt15btn.Text  := cqrini.ReadString('DefFreq','15btn','15m');
  edt15cw.Text   := cqrini.ReadString('DefFreq','15cw','21025');
  edt15ssb.Text  := cqrini.ReadString('DefFreq','15ssb','21255');
  edt15rtty.Text := cqrini.ReadString('DefFreq','15rtty','21090');
  edt15am.Text   := cqrini.ReadString('DefFreq','15am','21255');
  edt15fm.Text   := cqrini.ReadString('DefFreq','15fm','21255');

  edt12btn.Text  := cqrini.ReadString('DefFreq','12btn','12m');
  edt12cw.Text   := cqrini.ReadString('DefFreq','12cw','24895');
  edt12ssb.Text  := cqrini.ReadString('DefFreq','12ssb','24925');
  edt12rtty.Text := cqrini.ReadString('DefFreq','12rtty','24910');
  edt12am.Text   := cqrini.ReadString('DefFreq','12am','24925');
  edt12fm.Text   := cqrini.ReadString('DefFreq','12fm','24925');

  edt10btn.Text  := cqrini.ReadString('DefFreq','10btn','10m');
  edt10cw.Text   := cqrini.ReadString('DefFreq','10cw','28025');
  edt10ssb.Text  := cqrini.ReadString('DefFreq','10ssb','28550');
  edt10rtty.Text := cqrini.ReadString('DefFreq','10rtty','28090');
  edt10am.Text   := cqrini.ReadString('DefFreq','10am','28550');
  edt10fm.Text   := cqrini.ReadString('DefFreq','10fm','28550');

  edt6btn.Text  := cqrini.ReadString('DefFreq','6btn','6m');
  edt6cw.Text   := cqrini.ReadString('DefFreq','6cw','50090');
  edt6ssb.Text  := cqrini.ReadString('DefFreq','6ssb','51300');
  edt6rtty.Text := cqrini.ReadString('DefFreq','6rtty','51300');
  edt6am.Text   := cqrini.ReadString('DefFreq','6am','51300');
  edt6fm.Text   := cqrini.ReadString('DefFreq','6fm','51300');

  edt2btn.Text  := cqrini.ReadString('DefFreq','2btn','2m');
  edt2cw.Text   := cqrini.ReadString('DefFreq','2cw','144050');
  edt2ssb.Text  := cqrini.ReadString('DefFreq','2ssb','144300');
  edt2rtty.Text := cqrini.ReadString('DefFreq','2rtty','144300');
  edt2am.Text   := cqrini.ReadString('DefFreq','2am','145300');
  edt2fm.Text   := cqrini.ReadString('DefFreq','2fm','145300');

  edt70btn.Text  := cqrini.ReadString('DefFreq','70btn','70cm');
  edt70cw.Text   := cqrini.ReadString('DefFreq','70cw','430000');
  edt70ssb.Text  := cqrini.ReadString('DefFreq','70ssb','430000');
  edt70rtty.Text := cqrini.ReadString('DefFreq','70rtty','430000');
  edt70am.Text   := cqrini.ReadString('DefFreq','70am','430000');
  edt70fm.Text   := cqrini.ReadString('DefFreq','70fm','430000')
end;

procedure TfrmDefaultFreq.btnOKClick(Sender: TObject);
begin
  cqrini.WriteString('DefFreq','160btn',edt160btn.Text);
  cqrini.WriteString('DefFreq','160cw',edt160cw.Text);
  cqrini.WriteString('DefFreq','160ssb',edt160ssb.Text);
  cqrini.WriteString('DefFreq','160rtty',edt160rtty.Text);
  cqrini.WriteString('DefFreq','160am',edt160am.Text);
  cqrini.WriteString('DefFreq','160fm',edt160fm.Text);

  cqrini.WriteString('DefFreq','80btn',edt80btn.Text);
  cqrini.WriteString('DefFreq','80cw',edt80cw.Text);
  cqrini.WriteString('DefFreq','80ssb',edt80ssb.Text);
  cqrini.WriteString('DefFreq','80rtty',edt80rtty.Text);
  cqrini.WriteString('DefFreq','80am',edt80am.Text);
  cqrini.WriteString('DefFreq','80fm',edt80fm.Text);

  cqrini.WriteString('DefFreq','40btn',edt40btn.Text);
  cqrini.WriteString('DefFreq','40cw',edt40cw.Text);
  cqrini.WriteString('DefFreq','40ssb',edt40ssb.Text);
  cqrini.WriteString('DefFreq','40rtty',edt40rtty.Text);
  cqrini.WriteString('DefFreq','40am',edt40am.Text);
  cqrini.WriteString('DefFreq','40fm',edt40fm.Text);

  cqrini.WriteString('DefFreq','30btn',edt30btn.Text);
  cqrini.WriteString('DefFreq','30cw',edt30cw.Text);
  cqrini.WriteString('DefFreq','30ssb',edt30ssb.Text);
  cqrini.WriteString('DefFreq','30rtty',edt30rtty.Text);
  cqrini.WriteString('DefFreq','30am',edt30am.Text);
  cqrini.WriteString('DefFreq','30fm',edt30fm.Text);

  cqrini.WriteString('DefFreq','20btn',edt20btn.Text);
  cqrini.WriteString('DefFreq','20cw',edt20cw.Text);
  cqrini.WriteString('DefFreq','20ssb',edt20ssb.Text);
  cqrini.WriteString('DefFreq','20rtty',edt20rtty.Text);
  cqrini.WriteString('DefFreq','20am',edt20am.Text);
  cqrini.WriteString('DefFreq','20fm',edt20fm.Text);

  cqrini.WriteString('DefFreq','17btn',edt17btn.Text);
  cqrini.WriteString('DefFreq','17cw',edt17cw.Text);
  cqrini.WriteString('DefFreq','17ssb',edt17ssb.Text);
  cqrini.WriteString('DefFreq','17rtty',edt17rtty.Text);
  cqrini.WriteString('DefFreq','17am',edt17am.Text);
  cqrini.WriteString('DefFreq','17fm',edt17fm.Text);

  cqrini.WriteString('DefFreq','15btn',edt15btn.Text);
  cqrini.WriteString('DefFreq','15cw',edt15cw.Text);
  cqrini.WriteString('DefFreq','15ssb',edt15ssb.Text);
  cqrini.WriteString('DefFreq','15rtty',edt15rtty.Text);
  cqrini.WriteString('DefFreq','15am',edt15am.Text);
  cqrini.WriteString('DefFreq','15fm',edt15fm.Text);

  cqrini.WriteString('DefFreq','12btn',edt12btn.Text);
  cqrini.WriteString('DefFreq','12cw',edt12cw.Text);
  cqrini.WriteString('DefFreq','12ssb',edt12ssb.Text);
  cqrini.WriteString('DefFreq','12rtty',edt12rtty.Text);
  cqrini.WriteString('DefFreq','12am',edt12am.Text);
  cqrini.WriteString('DefFreq','12fm',edt12fm.Text);

  cqrini.WriteString('DefFreq','10btn',edt10btn.Text);
  cqrini.WriteString('DefFreq','10cw',edt10cw.Text);
  cqrini.WriteString('DefFreq','10ssb',edt10ssb.Text);
  cqrini.WriteString('DefFreq','10rtty',edt10rtty.Text);
  cqrini.WriteString('DefFreq','10am',edt10am.Text);
  cqrini.WriteString('DefFreq','10fm',edt10fm.Text);

  cqrini.WriteString('DefFreq','6btn',edt6btn.Text);
  cqrini.WriteString('DefFreq','6cw',edt6cw.Text);
  cqrini.WriteString('DefFreq','6ssb',edt6ssb.Text);
  cqrini.WriteString('DefFreq','6rtty',edt6rtty.Text);
  cqrini.WriteString('DefFreq','6am',edt6am.Text);
  cqrini.WriteString('DefFreq','6fm',edt6fm.Text);

  cqrini.WriteString('DefFreq','2btn',edt2btn.Text);
  cqrini.WriteString('DefFreq','2cw',edt2cw.Text);
  cqrini.WriteString('DefFreq','2ssb',edt2ssb.Text);
  cqrini.WriteString('DefFreq','2rtty',edt2rtty.Text);
  cqrini.WriteString('DefFreq','2am',edt2am.Text);
  cqrini.WriteString('DefFreq','2fm',edt2fm.Text);

  cqrini.WriteString('DefFreq','70btn',edt70btn.Text);
  cqrini.WriteString('DefFreq','70cw',edt70cw.Text);
  cqrini.WriteString('DefFreq','70ssb',edt70ssb.Text);
  cqrini.WriteString('DefFreq','70rtty',edt70rtty.Text);
  cqrini.WriteString('DefFreq','70am',edt70am.Text);
  cqrini.WriteString('DefFreq','70fm',edt70fm.Text);
  ModalResult := mrOK
end;

end.

