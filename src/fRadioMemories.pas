unit fRadioMemories;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  Grids, ExtCtrls, StdCtrls, ActnList, Menus, LCLType;

type

  { TfrmRadioMemories }

  TfrmRadioMemories = class(TForm)
    acAdd: TAction;
    acEdit: TAction;
    acDelete: TAction;
    acDown: TAction;
    acImport: TAction;
    acExport: TAction;
    acSortByFreq: TAction;
    acUp: TAction;
    acMem: TActionList;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    btnFunction: TButton;
    btnOK: TButton;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    dlgOpen: TOpenDialog;
    Panel1: TPanel;
    popMem: TPopupMenu;
    dlgSave: TSaveDialog;
    sgrdMem: TStringGrid;
    procedure acAddExecute(Sender: TObject);
    procedure acDeleteExecute(Sender: TObject);
    procedure acEditExecute(Sender: TObject);
    procedure acExportExecute(Sender: TObject);
    procedure acImportExecute(Sender: TObject);
    procedure acSortByFreqExecute(Sender: TObject);
    procedure btnFunctionClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure sgrdMemCompareCells(Sender: TObject; ACol, ARow, BCol,
      BRow: Integer; var Result: integer);
  private
    procedure AddToGrid(freq,mode,bandwidth : String);
  public
    { public declarations }
  end;

var
  frmRadioMemories: TfrmRadioMemories;

implementation

{ TfrmRadioMemories }

uses dUtils, fAddRadioMemory;

procedure TfrmRadioMemories.AddToGrid(freq,mode,bandwidth : String);
begin
  sgrdMem.RowCount := sgrdMem.RowCount + 1;
  sgrdMem.Cells[0,sgrdMem.RowCount-1] := FloatToStrF(StrToFloat(freq),ffFixed,15,3);
  sgrdMem.Cells[1,sgrdMem.RowCount-1] := mode;
  sgrdMem.Cells[2,sgrdMem.RowCount-1] := bandwidth
end;

procedure TfrmRadioMemories.acAddExecute(Sender: TObject);
begin
  frmAddRadioMemory := TfrmAddRadioMemory.Create(frmRadioMemories);
  try
    if frmAddRadioMemory.ShowModal = mrOK then
    begin
      AddToGrid(frmAddRadioMemory.edtFreq.Text,frmAddRadioMemory.cmbMode.Text,frmAddRadioMemory.edtWidth.Text)
    end
  finally
    FreeAndNil(frmAddRadioMemory)
  end
end;

procedure TfrmRadioMemories.acDeleteExecute(Sender: TObject);
begin
  if (sgrdMem.RowCount < 2) then
    Application.MessageBox('There is nothing to delete','Info...',mb_ok+mb_IconInformation)
  else
    sgrdMem.DeleteRow(sgrdMem.Row)
end;

procedure TfrmRadioMemories.acEditExecute(Sender: TObject);
begin
  frmAddRadioMemory := TfrmAddRadioMemory.Create(frmRadioMemories);
  try
    frmAddRadioMemory.edtFreq.Text  := sgrdMem.Cells[0,sgrdMem.Row];
    frmAddRadioMemory.cmbMode.Text  := sgrdMem.Cells[1,sgrdMem.Row];
    frmAddRadioMemory.edtWidth.Text := sgrdMem.Cells[2,sgrdMem.Row];
    if frmAddRadioMemory.ShowModal = mrOK then
    begin
      sgrdMem.Cells[0,sgrdMem.Row] := FloatToStrF(StrToFloat(frmAddRadioMemory.edtFreq.Text),ffFixed,15,6);
      sgrdMem.Cells[1,sgrdMem.Row] := frmAddRadioMemory.cmbMode.Text;
      sgrdMem.Cells[2,sgrdMem.Row] := frmAddRadioMemory.edtWidth.Text
    end
  finally
    FreeAndNil(frmAddRadioMemory)
  end
end;

procedure TfrmRadioMemories.acExportExecute(Sender: TObject);
var
  l : TStringList;
  i : Integer;
begin
  if dlgSave.Execute then
  begin
    l := TStringList.Create;
    try
      for i:=1 to sgrdMem.RowCount-1 do
        l.Add(sgrdMem.Cells[0,i]+';'+sgrdMem.Cells[1,i]+';'+sgrdMem.Cells[2,i]);

      l.SaveToFile(dlgSave.FileName);
      ShowMessage('File saved to '+dlgSave.FileName)
    finally
      FreeAndNil(l)
    end
  end
end;

procedure TfrmRadioMemories.acImportExecute(Sender: TObject);
const
  C_ERR = 'File has wrong format at line %d'+LineEnding+LineEnding+
          'Right format is freq(in kHz);mode;bandwidth' +LineEnding+LineEnding+ 'e.g.'+LineEnding+LineEnding+
          '10120.0;CW;300';

type TFreq = record
  freq  : String[20];
  mode  : String[10];
  width : String[8];
end;

var
  f : TextFile;
  l : String;
  a : TExplodeArray;
  i : Integer=0;
  d : Array of TFreq;
  n : Double;
  b : Integer;
begin
  if dlgOpen.Execute then
  begin
    try
      SetLength(d,0);
      AssignFile(f,dlgOpen.FileName);
      Reset(f);
      while not Eof(f) do
      begin
        ReadLn(f,l);
        inc(i);
        a := dmUtils.Explode(';',l);

        if (Length(a)<>3) then
        begin
          Application.MessageBox(PChar(Format(C_ERR,[i])),'Error...',mb_OK+mb_IconError);
          exit
        end;

        if not TryStrToFloat(a[0],n) then
        begin
          Application.MessageBox(PChar(Format(C_ERR,[i])),'Error...',mb_OK+mb_IconError);
          exit
        end;

        if a[1]='' then
        begin
          Application.MessageBox(PChar(Format(C_ERR,[i])),'Error...',mb_OK+mb_IconError);
          exit
        end;

        if not TryStrToInt(a[2],b) then
        begin
          Application.MessageBox(PChar(Format(C_ERR,[i])),'Error...',mb_OK+mb_IconError);
          exit
        end;

        SetLength(d,i);
        d[i-1].freq  := a[0];
        d[i-1].mode  := a[1];
        d[i-1].width := a[2]
      end;

      for i:= 0 to Length(d)-1 do
      begin
        AddToGrid(d[i].freq, d[i].mode, d[i].width)
      end;

      ShowMessage('File has been imported')
    finally
      CloseFile(f)
    end
  end
end;

procedure TfrmRadioMemories.acSortByFreqExecute(Sender: TObject);
begin
  sgrdMem.SortColRow(true, 0, sgrdMem.FixedRows, sgrdMem.RowCount-1)
end;

procedure TfrmRadioMemories.btnFunctionClick(Sender: TObject);
var
  p : TPoint;
begin
  p.x := 10;
  p.y := 10;
  p := btnFunction.ClientToScreen(p);
  popMem.PopUp(p.x, p.y)
end;

procedure TfrmRadioMemories.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  dmUtils.SaveWindowPos(frmRadioMemories)
end;

procedure TfrmRadioMemories.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmRadioMemories)
end;

procedure TfrmRadioMemories.sgrdMemCompareCells(Sender: TObject; ACol, ARow,
  BCol, BRow: Integer; var Result: integer);
begin
  result := round(StrToFloat(sgrdMem.Cells[ACol,ARow])*1000-StrToFloat(sgrdMem.Cells[BCol,BRow])*1000);
  if sgrdMem.SortOrder = soDescending then
    result := -result
end;

initialization
  {$I fRadioMemories.lrs}

end.

