unit fWorkedGrids;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil,
  Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, LResources, IniFiles;

type

  { TfrmWorkedGrids }

  TfrmWorkedGrids = class(TForm)
    ZooIlbl: TImage;
    modeLabel: TLabel;
    FollowRig: TCheckBox;
    WsMode: TComboBox;
    Nrstatus: TLabel;
    BandSelector: TComboBox;
    AutoUpdate: TTimer;
    Nrgrids: TLabel;
    Nrqsos: TLabel;
    LocMapBase: TImage;
    ZooMap: TImage;
    ShoWkdOnly: TCheckBox;
    SaveMapImage: TSaveDialog;
    SaveMap: TButton;
    LocMap: TImage;
    BandLabel: TLabel;
    procedure BandSelectorChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LocMapClick(Sender: TObject);
    procedure LocMapMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure ShoWkdOnlyClick(Sender: TObject);
    procedure FormClose(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SaveMapImageClose(Sender: TObject);
    procedure SaveMapClick(Sender: TObject);
    procedure AutoUpdateTimer(Sender: TObject);
    procedure WsModeChange(Sender: TObject);
    procedure ZooMapClick(Sender: TObject);
  private
    { private declarations }
    procedure DrawBase(BCanvas: TCanvas; SubBase: boolean);
    procedure MarkGrid(LocGrid: string; Cfmd: boolean; MCanvas: TCanvas;
      SubBase: boolean);
  public
    { public declarations }
    procedure ToRigMode(mode: string);
    procedure ToRigBand(band: string);
    function RecordCount: string;
    function WkdGrid(loc, band, mode: string): integer; //returns (0=not wkd, 1=main grid wkd, 2=wkd ) this band and mode
                                                        //        (3=main grid wkd, 4=wkd ) this band but NOT this mode
                                                        //        (5=main grid wkd, 6=wkd ) any other band or mode
    function WkdCall(call, band, mode: string): integer;  //returns wkd this b+m=1, this b=2, any b+m=3
    function GridOK(Loc: string): boolean;
    procedure UpdateMap;
  end;

var
  frmWorkedGrids: TfrmWorkedGrids; //Main form
  MaxRowId,                    //rows in table (Number of qsos in log database)
  BandQsoCount,                //Number of qsos on selected band
  FullQsoCount,                  //Number of all qsos
  LogTable,                    //Table name found from database file (own call ad locator)
  LogBand,                     //Band that is selected for worked locators
  LogSave,                     //Default File name for saving image
  LogMainGrid: string;    //first 2 letters of locator grid clicked from map
  MouseX, MouseY,              //Mouse position on loc map rounded to grids up/right corner
  MainGridCount,               //Number of Maingrids (achrs) from query result
  GridCount: integer;    //Number of subgrids (4chrs) from query result
  Changes: boolean;   //changes in rig mode/band


implementation

{$R *.lfm}
uses fNewQSO, fTRXControl, dData, dUtils, uMyIni;

{ TfrmWorkedGrids }


function TfrmWorkedGrids.GridOK(Loc: string): boolean;
var
  i: integer;
begin
  Result := True;
  Loc := trim(UpCase(Loc));
  if Length(Loc) mod 2 = 0 then
  begin
    for i := 1 to length(loc) do
    begin
      case i of
        1, 2, 5, 6: case Loc[i] of
            'A'..'R':
            begin {OK!}
            end;
            else
              Result := False;
          end;
        3, 4, 7, 8: case Loc[i] of
            '0'..'9':
            begin {OK!}
            end;
            else
              Result := False;
          end;
      end;
    end;
  end
  else begin
    Result := False;
  end;
end;

procedure TfrmWorkedGrids.ToRigMode(mode: string);
var
  i: integer;
begin
  if dmData.DebugLevel >= 1 then
    Writeln('ToRigMode was index:', WsMode.ItemIndex);
  i := WsMode.Items.Count;
  Changes := True;
  repeat
    begin
      Dec(i);
      if dmData.DebugLevel >= 1 then
        Writeln('looping now:', i);
    end;
  until (WsMode.Items[i] = mode) or (i = 0);
  WsMode.ItemIndex := i;
  if dmData.DebugLevel >= 1 then
    Writeln('Result:', i, '  ', WsMode.Items[WsMode.ItemIndex]);
end;

procedure TfrmWorkedGrids.ToRigBand(band: string);
var
  i: integer;
begin
  if dmData.DebugLevel >= 1 then
    Writeln('ToRigBand was index:', WsMode.ItemIndex);
  i := BandSelector.Items.Count;
  Changes := True;
  repeat
    begin
      Dec(i);
      if dmData.DebugLevel >= 1 then
        Writeln('looping now:', i);
    end;
  until (BandSelector.Items[i] = band) or (i = 0);
  BandSelector.ItemIndex := i;
  if dmData.DebugLevel >= 1 then
    Writeln('Result:', i, '  ', BandSelector.Items[BandSelector.ItemIndex]);
end;

procedure TfrmWorkedGrids.UpdateMap;

begin
  BandSelectorChange(AutoUpdate);   //update map(s)
end;

function TfrmWorkedGrids.RecordCount: string;
begin

  dmData.W1.Close;
  if dmData.trW1.Active then
    dmData.trW1.Rollback;
  dmData.W1.SQL.Text := 'select count(callsign) from ' + LogTable;
  dmData.trW1.StartTransaction;
  try
    dmData.W1.Open;
    RecordCount := dmData.W1.Fields[0].AsString;
    if (RecordCount = '') then
      RecordCount := '0';
    dmData.W1.Close;

  finally
    dmData.trW1.Rollback;
  end;
end;

function TfrmWorkedGrids.WkdGrid(loc, band, mode: String): integer;

//returns 0=not wkd
//        1=full grid this band and mode
//        2=full grid this band but NOT this mode
//        3=full grid any other band/mode
//        4=main grid this band and mode
//        5=main grid this band but NOT this mode
//        6=main grid any other band/mode

var
  i : integer;

begin
  if dmData.DebugLevel >= 1 then Writeln('Start WkdGrid');
  WkdGrid := 0;
  dmData.W.Close;
  if dmData.trW.Active then dmData.trW.Rollback;

  try
    dmData.W.SQL.Text := 'select count(loc) as '+#39+'sum'+#39+' from '+LogTable+
                          ' where loc like '+#39+copy(loc, 1, 4)+ '%'+#39+
                          ' and band='+#39+band+#39+' and mode='+#39+mode+#39+
                          'union all '+
                          'select count(loc) from '+LogTable+
                          ' where loc like '+#39+copy(loc, 1, 4)+ '%'+#39+
                          ' and band='+#39+band+#39+
                          'union all '+
                          'select count(loc) from '+LogTable+
                          ' where loc like '+#39+copy(loc, 1, 4)+ '%'+#39+
                          'union all '+
                          'select count(loc) from '+LogTable+
                          ' where loc like '+#39+copy(loc, 1, 2)+ '%'+#39+
                          ' and band='+#39+band+#39+' and mode='+#39+mode+#39+
                          'union all '+
                          'select count(loc) from '+LogTable+
                          ' where loc like '+#39+copy(loc, 1, 2)+ '%'+#39+
                          ' and band='+#39+band+#39+
                          'union all '+
                          'select count(loc) from '+LogTable+
                          ' where loc like '+#39+copy(loc, 1, 2)+ '%'+#39;

    if dmData.DebugLevel >= 1 then Write('loc query: ');
    dmData.W.Open;
    i := 1;
    while not dmData.W.Eof do
              begin
               if dmData.DebugLevel >= 1 then writeln(dmData.W.FieldByName('sum').AsInteger);
               if (dmData.W.FieldByName('sum').AsInteger > 0 ) and (WkdGrid = 0) then WkdGrid := i;
               inc(i);
               dmData.W.Next;
              end;
     dmData.W.Close;
  finally
    dmData.trW.Rollback;
  end;
   if dmData.DebugLevel >= 1 then  Writeln('WkdGrid is:', WkdGrid);
end;

function TfrmWorkedGrids.WkdCall(call, band, mode: string): integer;
//returns 0=not wkd
//        1= this band and mode
//        2=this band but NOT this mode
//        3=any other band or mode

var
  i : integer;
begin
  if dmData.DebugLevel >= 1 then Writeln('Start WkdCall');
  WkdCall := 0;
  dmData.W.Close;
  if dmData.trW.Active then dmData.trW.Rollback;
  try
     dmData.W.SQL.Text := 'select count(callsign) as '+#39+'sum'+#39+' from '+LogTable+
                          ' where callsign='+#39+call+#39+
                          ' and band='+#39+band+#39+' and mode='+#39+mode+#39+
                          'union all '+
                          'select count(callsign) from '+LogTable+
                          ' where callsign='+#39+call+#39+
                          ' and band='+#39+band+#39+
                          'union all '+
                          'select count(callsign) from '+LogTable+
                          ' where callsign='+#39+call+#39;

    if dmData.DebugLevel >= 1 then Write('call query: ');
    dmData.W.Open;
    i := 1;
    while not dmData.W.Eof do
              begin
               if dmData.DebugLevel >= 1 then writeln(dmData.W.FieldByName('sum').AsInteger);
               if (dmData.W.FieldByName('sum').AsInteger > 0 ) and (WkdCall = 0) then WkdCall := i;
               inc(i);
               dmData.W.Next;
              end;
    dmData.W.Close;
    finally
      dmData.trW.Rollback;
    end;
  if dmData.DebugLevel >= 1 then  Writeln('WkdCall is:', WkdCall);
end;

procedure TfrmWorkedGrids.MarkGrid(LocGrid: string; Cfmd: boolean; MCanvas: TCanvas;
  SubBase: boolean);

var
  v, vs, h, hs, Mheight, ltrbase, Pwidth, Pcolor, Grid1, Grid2: integer;

begin
  LocGrid := UpperCase(LocGrid);//to be sure ;)
  Pwidth := 2;
  if Cfmd then
    Pcolor := clGreen
  else
    Pcolor := clMaroon;
  Mheight := 360;
  ltrbase := 65;
  Grid1 := 1;
  Grid2 := 2;

  if not GridOK(LocGrid) then
    exit;  // all (4chr) must be valid

  if SubBase then
  begin
    Pwidth := 4;
    if Cfmd then
      Pcolor := clLime
    else
      Pcolor := clred;
    Mheight := 200;
    ltrbase := 48;
    Grid1 := 3;
    Grid2 := 4;
  end;

  with MCanvas do
  begin
    //draw main grids
    v := (Ord(LocGrid[Grid1]) - ltrbase) * 40;
    h := Mheight - (Ord(LocGrid[Grid2]) - (ltrbase - 1)) * 20;

    brush.style := bsClear;
    pen.Color := Pcolor;
    pen.Width := Pwidth;
    if subBase then
    begin
      brush.Color := Pcolor;
      FillRect(v + 3, h + 3, v + 38, h + 18);
    end
    else begin
      Rectangle(v + 2, h + 2, v + 39, h + 19);
    end;

    //name grids
    font.Size := 7;
    font.Color := clBlack;
    Font.Style := [fsBold];
    TextOut(v + 15, h + 5, LocGrid[Grid1] + LocGrid[Grid2]);
    Font.Style := [];

    //draw sub grids
    if not SubBase then
    begin
      hs := h + 20 - ((Ord(LocGrid[4]) - 47) * 2);
      vs := v + (Ord(LocGrid[3]) - 48) * 4;
      if Cfmd then
        Pcolor := clLime
      else
        Pcolor := clred;
      pen.Color := Pcolor;
      Rectangle(vs, hs, vs + 4, hs + 2);
    end;
  end;
end;


procedure TfrmWorkedGrids.DrawBase(BCanvas: TCanvas; SubBase: boolean);

var
  v, vc, h, hc, Bwidth, Bheight, ltrbase: integer;

begin

  Bwidth := 720;
  Bheight := 360;
  ltrbase := 65;

  if SubBase then
  begin
    Bwidth := 400;
    Bheight := 200;
    ltrbase := 48;
  end;

  with BCanvas do
  begin
    v := 0;
    repeat
      begin
        pen.Color := clGray;
        pen.Width := 1;
        line(0, v, Bwidth, v);
        line(v * 2, 0, v * 2, Bheight);
        v := v + 20;
      end;
    until v > Bheight;
    v := 15;
    vc := ltrbase;
    repeat
      begin
        h := Bheight - 15;
        ;
        hc := ltrbase;
        repeat
          begin
            Brush.Style := bsClear;
            font.Size := 7;
            font.Color := clGray;
            TextOut(v, h, chr(vc) + chr(hc));
            h := h - 20;
            hc := hc + 1;
          end;
        until h < 0;
      end;
      v := v + 40;
      vc := vc + 1;
    until v > Bwidth;

  end;
end;

procedure TfrmWorkedGrids.FormCreate(Sender: TObject);
var
  ImgStream : TResourceStream;
begin
  ImgStream := TResourceStream.Create(HINSTANCE,'WORLD_BORDERS',RT_RCDATA);
  try
    LocMapBase.Picture.LoadFromStream(ImgStream)
  finally
    ImgStream.Free
  end;

  AutoUpdate.Enabled := False;
  AutoUpdate.Interval := 5000;
  WsMode.ItemIndex := -1;
  BandSelector.ItemIndex := -1;
  LogSave := 'wkd_locs_empty';
  LogBand := ' ';
  LogTable := 'cqrlog_main';  //assume table name is this always

  //mode selector updates now @ FormShow

  dmUtils.InsertBands(BandSelector);
  BandSelector.Items.Insert(0, 'all');
  BandSelector.ItemIndex := 0;

  frmWorkedGrids.Caption := Caption + ' ' + dmData.LogName + ' ' + LogBand;

  LocMap.Canvas.CopyRect(Rect(0, 0, Width, Height),
  LocMapBase.Picture.Bitmap.Canvas, Rect(0, 0, Width, Height));

  DrawBase(LocMap.canvas, False)
end;

procedure TfrmWorkedGrids.SaveMapImageClose(Sender: TObject);

var
  Bmp: TBitmap;
  AddSize, aWidth, aHeight: integer;
  AddText, AddText1: string;

begin
  AddText := '';
  AddText1 := '';
  if LocMap.Visible then
  begin
    AddSize := 20;
    aWidth := LocMap.Picture.Bitmap.Width;
    aHeight := LocMap.Picture.Bitmap.Height + AddSize;
    AddText := 'Log:'+dmData.LogName + ' Band:' + LogBand + ' Mode:' + WsMode.items[WsMode.ItemIndex] + '  ' +
      IntToStr(MainGridCount) + 'main/' + IntToStr(
      GridCount) + 'sub grids  Db:' + dmData.DBName +
      '     ' + BandQsoCount + '/' + FullQsoCount + 'qsos';
  end
  else begin
    AddSize := 40;
    aWidth := ZooMap.Picture.Bitmap.Width;
    aHeight := ZooMap.Picture.Bitmap.Height + AddSize;
    AddText := 'Log:'+dmData.LogName + ' Band:' + LogBand + ' Mode:' + WsMode.items[WsMode.ItemIndex] + ' Main Grid:' +
                LogMainGrid + ' ' + IntToStr(GridCount) + 'sub grids';
    AddText1 := 'Db:'+dmData.DBName + '  ' + BandQsoCount + '/' + FullQsoCount + 'qsos';
  end;



  Bmp := TBitmap.Create;
  try try
    Bmp.Width := aWidth;
    Bmp.Height := aHeight;
    Bmp.Canvas.Rectangle(0, 0, aWidth, aHeight);

    if LocMap.Visible then
    begin
      Bmp.Canvas.CopyRect(Rect(0, AddSize, aWidth, aHeight), LocMap.Picture.Bitmap.Canvas, Rect(0, 0, aWidth, aHeight - AddSize));
    end
    else begin
      Bmp.Canvas.CopyRect(Rect(0, AddSize, aWidth, aHeight), ZooMap.Picture.Bitmap.Canvas, Rect(0, 0, aWidth, aHeight - AddSize));
    end;
    Bmp.Canvas.Brush.Style := bsClear;
    Bmp.Canvas.font.Size := 10;
    Bmp.Canvas.font.Color := clBlack;
    Bmp.Canvas.TextOut(5, 3, AddText);
    if AddText1 <> '' then
      Bmp.Canvas.TextOut(5, 23, AddText1);

    Bmp.SaveToFile(SaveMapImage.FileName);
  except
    on E: Exception do
      ShowMessage('Error: ' + E.Message)
  end
  finally
    Bmp.Free
  end
end;

procedure TfrmWorkedGrids.SaveMapClick(Sender: TObject);
begin
  if LocMap.Visible then
    SaveMapImage.FileName := LogSave + '.jpg'
  else
    SaveMapImage.FileName := LogSave + '_' + LogMainGrid + '.jpg';
  SaveMapImage.Execute
end;

procedure TfrmWorkedGrids.AutoUpdateTimer(Sender: TObject);
var
  mode, band: string;
begin
  if dmData.DebugLevel >= 1 then
    Writeln('WkdGrids-TimerTick. FlwRig stage0 is:', FollowRig.Checked);
  AutoUpdate.Enabled := False;

  if FollowRig.Checked then
  begin
    if dmData.DebugLevel >= 1 then
      Writeln(' FlwRig stage 1 is:', FollowRig.Checked);
    if dmData.DebugLevel >= 1 then
      Writeln(' FlwRig getmode returns(st-m-b):', frmTRXControl.GetModeBand(
        mode, band), ' ', mode, ' ', band);
    if (frmTRXControl.GetModeBand(mode, band)) and (band <> '') then
      //if off from ham freq gives True, but empty band !!!
    begin
      //here wsjt-x makes exeption as mode is JT9 , JT65 or combination JT9+JT65 not what RigCtl says
      //maybe same is needed from fldigi, too. It just does not update it before qso is logged!
      //perhaps could use preference's option: (rigctl, from program or fixed "RTTY")

      //empty frmNewQSO.WsjtxMode causes crash. Happens if "follow rig" checked before wsjtx starts.
      if frmNewQSO.mnuRemoteModeWsjt.Checked and (frmNewQSO.WsjtxMode <> '') then
        mode := frmNewQSO.WsjtxMode;
      if dmData.DebugLevel >= 1 then
        Writeln('Follow rig mode: ', mode, ' Band: ', band);
      if WsMode.ItemIndex < 0 then
        ToRigMode(mode)
      else
        if WsMode.Items[WsMode.ItemIndex] <> mode then
          ToRigMode(mode);

      if BandSelector.ItemIndex < 0 then
        ToRigBand(band)
      else
        if BandSelector.Items[BandSelector.ItemIndex] <> band then
          ToRigBand(band);
    end;
  end;

  if (BandSelector.ItemIndex >= 0) and (WsMode.ItemIndex >= 0) and Changes then
    //both must be set
  begin
    BandSelectorChange(AutoUpdate);   //update map(s)
  end;
  AutoUpdate.Enabled := True;
end;

procedure TfrmWorkedGrids.WsModeChange(Sender: TObject);
begin
  if (BandSelector.ItemIndex >= 0) then
    BandSelectorChange(WsMode);
end;


procedure TfrmWorkedGrids.ZooMapClick(Sender: TObject);
begin
  ZooMap.Visible := False;
  ZooILbl.Visible := False;
  ShoWkdOnlyClick(ZooMap);
  LocMap.Visible := True;
end;

procedure TfrmWorkedGrids.BandSelectorChange(Sender: TObject);   //update map(s)
var
  SQLModeTail,
  SQLBand,
  Grid: string;
  c: integer;
  SQLCfm: array [0 .. 2] of string;
begin
  //no updates if band and mode are not set
  if (BandSelector.ItemIndex >= 0) and (WsMode.ItemIndex >= 0) then
  begin
    AutoUpdate.Enabled := False;
    Changes := False;
    //clean map if caller is not zoomed grid(=visible)
    if ZooMap.Visible then
    begin
      LocMapClick(BandSelector);
    end
    else begin
      LocMap.Canvas.CopyRect(Rect(0, 0, Width, Height),
        LocMapBase.Picture.Bitmap.Canvas, Rect(0, 0, Width, Height));
      if not ShoWkdOnly.Checked then
        DrawBase(LocMap.canvas, False);
    end;

    case WsMode.ItemIndex of
      //any
      0: SQLModeTail := '';
      //JT9+JT65
      1: SQLModeTail := ' and ((mode=' + #39 + 'JT9' + #39 +
          ') or ( mode=' + #39 + 'JT65' + #39 + '))';
      else  // all others
        SQLModeTail := ' and mode=' + #39 + WsMode.items[WsMode.ItemIndex] + #39;
    end;


    //1:not (at all) confirmed grids
    SQLCfm[1] := ' and eqsl_qsl_rcvd<>' + #39 + 'E' + #39 +
      ' and lotw_qslr<>' + #39 + 'L' + #39 + ' and qsl_r<>' + #39 + 'Q' + #39;
    //2:some way confirmed grids
    SQLCfm[2] := ' and (eqsl_qsl_rcvd=' + #39 + 'E' + #39 +
      ' or lotw_qslr=' + #39 + 'L' + #39 + ' or qsl_r=' + #39 + 'Q' + #39 + ')';

    dmData.W.Close;
    if dmData.trW.Active then
      dmData.trW.Rollback;

    if BandSelector.ItemIndex > 0 then //band selected
    begin
      //0:the base query string
      SQLCfm[0] := 'select upper(left(loc,4)) as lo from ' + LogTable +
        ' where band=' + #39 + BandSelector.items[BandSelector.ItemIndex] +
        #39 + 'and loc<>' + #39 + #39 + SQLModeTail;
    end
    else begin //band "all"                 //as
      SQLCfm[0] := 'select upper(left(loc,4)) as lo from ' + LogTable +
        ' where loc<>' + #39 + #39 + SQLModeTail;
    end;
    if ZooMap.Visible then  //coming from zoomed grid
    begin
      SQLCfm[0] := SQLCfm[0] + ' and loc like ' + #39 + LogMainGrid + '%' + #39;
    end;

    dmData.trW.StartTransaction;
    try
      for c := 1 to 2 do
      begin
        dmData.W.SQL.Text := SQLCfm[0] + SQLCfm[c];
        dmData.W.Open;
        while not dmData.W.EOF do
        begin
          Grid := dmData.W.FieldByName('lo').AsString;

          if ZooMap.Visible then  //coming from zoomed grid
          begin
            MarkGrid(Grid, c = 2, ZooMap.canvas, True);
          end
          else begin
            MarkGrid(Grid, c = 2, LocMap.canvas, False);
          end;

          dmData.W.Next;
        end;
        dmData.W.Close;
      end;

      //locator counts
      dmData.W.SQL.Text := 'select count(distinct upper(left(loc,2))) as main,count(distinct upper(left(loc,4))) as sub'+
                           copy(SQLCfm[0],pos('from', SQLCfm[0])-1,length(SQLCfm[0]));
      dmData.W.Open;
      if not dmData.W.EOF then
       Begin
         GridCount := dmData.W.FieldByName('sub').AsInteger;
         MainGridCount := dmData.W.FieldByName('main').AsInteger;
         Nrgrids.Caption := IntToStr(MainGridCount) + 'main/' + IntToStr(GridCount) + 'sub grids';
       end;
      dmData.W.Close;

      //qso counts;
      if BandSelector.ItemIndex > 0 then   //some of bands
        SQLBand := ' and band=' + #39 + BandSelector.items[BandSelector.ItemIndex] + #39 + SQLModeTail
        else   //can be else than 0, means all bands
        SQLBand := SQLModeTail;

      dmData.W.SQL.Text := 'select count(callsign) as qso from cqrlog_main where callsign<>'+#39+#39+
                            'union all select count(callsign) from cqrlog_main where callsign<>'+#39+#39 + SQLBand ;
      dmData.W.Open;
      if not dmData.W.EOF then FullQsoCount := dmData.W.FieldByName('qso').AsString;
      dmData.W.Next;
      if not dmData.W.EOF then BandQsoCount := dmData.W.FieldByName('qso').AsString;
      Nrqsos.Caption := BandQsoCount + '/' + FullQsoCount + 'qsos';
      dmData.W.Close;

    finally
      dmData.trW.Rollback;
    end;
    if (BandSelector.ItemIndex >= 0) and (WsMode.ItemIndex >= 0) then
      //both must be set
    begin
      LogSave := 'Wkd_locs_' + dmData.LogName + '_' +
        BandSelector.items[BandSelector.ItemIndex] + '_' + WsMode.items[WsMode.ItemIndex];
      LogBand := BandSelector.items[BandSelector.ItemIndex];
      frmWorkedGrids.Caption :=
        'Worked locator grids ' + dmData.LogName + ' ' + LogBand + ' ' + WsMode.items[WsMode.ItemIndex];
    end;

    Nrstatus.Caption := dmData.LogName;
    Nrgrids.Visible := True;
    Nrstatus.Visible := True;
    Nrqsos.Visible := True;

    AutoUpdate.Enabled := True;
  end;
end;

procedure TfrmWorkedGrids.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmWorkedGrids);
  FollowRig.Checked := cqrini.ReadBool('Worked_grids', 'FollowRig', False);
  ShoWkdOnly.Checked := cqrini.ReadBool('Worked_grids', 'ShowWkdOnly', False);
  AutoUpdate.Enabled := True;
  //we need this here. Otherwise user digital modes are not shown
  dmUtils.InsertModes(WsMode);
  WsMode.Items.Insert(0, 'any');
  WsMode.Items.Insert(1, 'JT9+JT65');
  WsMode.ItemIndex := 0;
  BandSelectorChange(nil);
end;

procedure TfrmWorkedGrids.LocMapClick(Sender: TObject);

var
  Bmp: TBitmap;
  aWidth, aHeight, ww, hh: integer;

begin

  if (BandSelector.ItemIndex >= 0) and (WsMode.ItemIndex >= 0) then  //both must be set
  begin
    ww := 0;
    hh := 0;
    aWidth := 40;
    aHeight := 20;
    Bmp := TBitmap.Create;
    Bmp.Width := aWidth;
    Bmp.Height := aHeight;
    Bmp.Canvas.CopyRect(Rect(0, 0, aWidth, aHeight),
      LocMapBase.Picture.Bitmap.Canvas,
      Rect(MouseX, MouseY, MouseX + aWidth + 1, MouseY + aHeight + 1));
    ZooMap.Picture.Bitmap.SetSize(ZooMap.Width, ZooMap.Height);
    ZooMap.Picture.Bitmap.Canvas.StretchDraw(
      Rect(0, 0, ZooMap.Picture.Bitmap.Width, ZooMap.Picture.Bitmap.Height), Bmp);
    Bmp.Free;
    DrawBase(ZooMap.Canvas, True);

    if Sender <> BandSelector then //to avoid BandSelector looping when ZooMap active
    begin
      LogMainGrid := chr((MouseX) div 40 + 65) + chr((340 - MouseY) div 20 + 65);
      LocMap.Visible := False;
      ZooMap.Visible := True;
      ZooILbl.Visible := True;
      with ZooIlbl.Canvas do
        //had to make this grapic as cqrlog controls font size of window after wkd-map
      begin
        //position saved/loaded as other forms and I'm too lazy to dig out how to avoid it
        Clear;
        Brush.Color := clBackground;
        FillRect(0, 0, Width, Height);
        Brush.style := bsClear;
        font.Color := clBlack;
        Font.Style := [fsBold];
        font.Size := 54;
        repeat            //fit the text to canvas
          begin
            font.Size := font.Size - 1;
            GetTextSize(LogMainGrid, ww, hh);
            if dmData.DebugLevel >= 1 then
              Writeln('Font size:', font.Size);
          end;
        until (ww <= Width) and (hh <= Height);
        TextOut(1, 1, LogMainGrid);
      end;

      BandSelectorChange(LocMap);
    end;

  end;

end;

procedure TfrmWorkedGrids.LocMapMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: integer);
begin
  MouseX := (X div 40) * 40;
  MouseY := (Y div 20) * 20;
end;

procedure TfrmWorkedGrids.ShoWkdOnlyClick(Sender: TObject);
begin
  if (BandSelector.ItemIndex >= 0) and (WsMode.ItemIndex >= 0) then
    //both must be set
  begin
    BandSelectorChange(BandSelector);
  end
  else begin
    LocMap.Canvas.CopyRect(Rect(0, 0, Width, Height),
      LocMapBase.Picture.Bitmap.Canvas, Rect(0, 0, Width, Height));
    if not ShoWkdOnly.Checked then
      DrawBase(LocMap.canvas, False);
  end;
end;

procedure TfrmWorkedGrids.FormClose(Sender: TObject);
begin
  AutoUpdate.Enabled := False;
  cqrini.WriteBool('Worked_grids', 'FollowRig', FollowRig.Checked);
  cqrini.WriteBool('Worked_grids', 'ShowWkdOnly', ShoWkdOnly.Checked);
  dmUtils.SaveWindowPos(frmWorkedGrids);
  frmWorkedGrids.hide;
end;

initialization

end.
