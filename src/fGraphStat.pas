unit fGraphStat;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, TAGraph, TASeries;

type

  { TfrmGraphStat }

  TfrmGraphStat = class(TForm)
    Button1: TButton;
    Button2: TButton;
    chrtStat: TChart;
    Panel1: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
     {FBar : TBarSeries;
     FPie : TPieSeries;}
  public
    procedure QSOperMode;
  end;

var
  frmGraphStat: TfrmGraphStat;

implementation
  {$R *.lfm}

uses dData;

procedure TfrmGraphStat.FormShow(Sender: TObject);
begin

end;

procedure TfrmGraphStat.Button1Click(Sender: TObject);
begin
end;

procedure TfrmGraphStat.QSOperMode;
{var
  i : Integer = 1;}
begin
  {FBar := TBarSeries.Create(chrtStat);
  chrtStat.AddSerie(FBar);
  FBar.Title := 'QSO per mode';
  FBar.MarksStyle  := smsLabelValue;
  chrtStat.AutoUpdateYMax :=  True;
  chrtStat.SetAutoYMax(False);
  chrtStat.YGraphMax := 10000;


  FPie := TPieSeries.Create(chrtStat);
  chrtStat.AddSerie(FPie);
  FPie.Title := 'QSO per mode';
  FPie.SeriesColor := clRed;
  FPie.MarksStyle := smsLabelPercent;


  dmData.Q.Close();
  dmData.Q.SQL.Text := 'select count(mode) as cnt,mode from cqrlog_main group by mode order by cnt';
  if dmData.DebugLevel >=1 then Writeln(dmData.Q.SQL.Text);
  dmData.Q.Open;
  dmData.Q.First;
  while not dmData.Q.Eof do
  begin
    //FPie.AddPie(dmData.Q.Fields.AsInteger[0], dmData.Q.Fields.AsString[1],Random(clWhite));
    FBar.AddXY(i,dmData.Q.Fields.AsInteger[0], dmData.Q.Fields.AsString[1], clBlue);
    inc(i);
    dmData.Q.Next
  end;
  chrtStat.BottomAxis.Visible := True;
  chrtStat.LeftAxis.Visible   := True;
  chrtStat.Title.Visible := True;
  chrtStat.Foot.Visible := True;
  chrtStat.Legend.Visible := True;}
end;

end.

