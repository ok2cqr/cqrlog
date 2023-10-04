unit fWorkedGrids;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil,
  Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, LResources, IniFiles, LCLType;

type

  { TfrmWorkedGrids }

  TfrmWorkedGrids = class(TForm)
    LocMap: TImage;
    LocMapBase: TImage;
    modeLabel: TLabel;
    FollowRig: TCheckBox;
    WsMode: TComboBox;
    Nrstatus: TLabel;
    BandSelector: TComboBox;
    AutoUpdate: TTimer;
    Nrgrids: TLabel;
    Nrqsos: TLabel;
    ShoWkdOnly: TCheckBox;
    SaveMapImage: TSaveDialog;
    SaveMap: TButton;
    BandLabel: TLabel;
    ZooMap: TImage;
    procedure BandSelectorChange(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure LocMapChangeBounds(Sender: TObject);
    procedure LocMapClick(Sender: TObject);
    procedure LocMapMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure ShoWkdOnlyClick(Sender: TObject);
    procedure FormClose(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SaveMapImageClose(Sender: TObject);
    procedure SaveMapClick(Sender: TObject);
    procedure AutoUpdateTimer(Sender: TObject);
    procedure WsModeChange(Sender: TObject);
    procedure ZooMapChangeBounds(Sender: TObject);
    procedure ZooMapClick(Sender: TObject);
  private
    { private declarations }
    procedure DrawFullMap;
    procedure DrawSubMap;
    procedure DrawGridLines(BCanvas: TCanvas; SubBase: boolean);
    procedure UpdateGridData;
    procedure UpdateGrids;
    procedure MarkGrid(LocGrid: string; Cfmd: boolean; MCanvas: TCanvas;
      SubBase: boolean);
    procedure MapChangeBounds(Map:Timage);
  public
    { public declarations }
    procedure ToRigMode(mode: string);
    procedure ToRigBand(band: string);
    function RecordCount: string;
    function WkdMainGrid(loc, band, mode: string): integer;
    function WkdGrid(loc, band, mode: string): integer;
    function WkdCall(call, band, mode: string): integer;
    function WkdState(state, band, mode: string): integer;
    function GridOK(Loc: string): boolean;
    procedure UpdateMap;
  end;

const
  FullMap : Boolean = false;
  SubMap  : Boolean = true;
var
  frmWorkedGrids: TfrmWorkedGrids; //Main form
  MaxRowId,                    //rows in table (Number of qsos in log database)
  BandQsoCount,                //Number of qsos on selected band
  FullQsoCount,                  //Number of all qsos
  LogTable,                    //Table name found from database file (own call ad locator)
  LogBand,                     //Band that is selected for worked locators
  LogSave,                     //Default File name for saving image
  LockMainGrid: string;    //first 2 letters of locator grid clicked from map
  MouseX, MouseY,              //Mouse position on loc map rounded to grids up/right corner
  MainGridCount,               //Number of Maingrids (achrs) from query result
  GridCount: integer;    //Number of subgrids (4chrs) from query result
  Changes: boolean;   //changes in rig mode/band
  daylimit : String;  //sql extension when log seek wB4 limited from preferences
  wb4c,
  wb4l,
  logname  : string;       //previous states of settings for autoupdate.
  wb4lc,
  wb4cc    : boolean;
  LocalDbg : boolean;
  SubW     : integer;   //subgrid size on map (in pixels)
  SubH     : integer;
  TrueSizeW,            //streched image pointing area
  TrueSizeH:integer ;
  BmpTmp   : TBitmap;

implementation

{$R *.lfm}
uses fNewQSO, fTRXControl, dData, dUtils, uMyIni,fContest;

{ TfrmWorkedGrids }
 //441H      753W

function TfrmWorkedGrids.GridOK(Loc: string): boolean;
//works with 4 or 6 chr locators, but fails with special callsigns that look like locator -> OH60AB
begin
  Result := false;
    if ((Length(Loc) = 4) or (Length(Loc) = 6)) then
        Result := dmUtils.IsLocOK(Loc);
end;

procedure TfrmWorkedGrids.ToRigMode(mode: string);
var
  i: integer;
begin
  if LocalDbg then
    Writeln('ToRigMode was index:', WsMode.ItemIndex);
  i := WsMode.Items.Count;
  Changes := True;
  repeat
    begin
      Dec(i);
      if LocalDbg then
        Writeln('looping now:', i);
    end;
  until (WsMode.Items[i] = mode) or (i = 0);
  WsMode.ItemIndex := i;
  if LocalDbg then
    Writeln('Result:', i, '  ', WsMode.Items[WsMode.ItemIndex]);
end;

procedure TfrmWorkedGrids.ToRigBand(band: string);
var
  i: integer;
begin
  if LocalDbg then
    Writeln('ToRigBand was index:', WsMode.ItemIndex);
  i := BandSelector.Items.Count;
  Changes := True;
  repeat
    begin
      Dec(i);
      if LocalDbg then
        Writeln('looping now:', i);
    end;
  until (BandSelector.Items[i] = band) or (i = 0);
  BandSelector.ItemIndex := i;
  if LocalDbg then
    Writeln('Result:', i, '  ', BandSelector.Items[BandSelector.ItemIndex]);
end;

procedure TfrmWorkedGrids.UpdateMap;
begin
  UpdateGridData;   //update map(s)
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
    dmData.W1.Last;
    RecordCount := dmData.W1.Fields[0].AsString;
    if (RecordCount = '') then
      RecordCount := '0';
    dmData.W1.Close;

  finally
    dmData.trW1.Rollback;
  end;
end;

function TfrmWorkedGrids.WkdMainGrid(loc, band, mode: String): integer;
//returns 0=not wkd
//        1=main grid this band and mode
//        2=main grid this band but NOT this mode
//        3=main grid any other band/mode

var
  i : integer;
  L2,
  L4: String;

  Begin
    if LocalDbg then Writeln('Start WkdMainGrid');
    WkdMainGrid := 0;
    L4:= copy(loc, 1, 4);
    L2:= copy(loc, 1, 2);
    if cqrini.ReadBool('wsjt','wb4CLoc', False) then
              daylimit := ' and qsodate >= '+#39+cqrini.ReadString('wsjt', 'wb4locdate','1900-01-01')+#39 //default date check all qsos
       else
              daylimit :='';

    dmData.W.Close;
    if dmData.trW.Active then dmData.trW.Rollback;

    try
      dmData.W.SQL.Text :='select count(loc) as '+#39+'sum'+#39+' from '+LogTable+
                          ' where loc like '+#39+L2+ '%'+#39+
                          ' and band='+#39+band+#39+' and mode='+#39+mode+#39+daylimit+
                          'union all '+
                          'select count(loc) from '+LogTable+
                          ' where loc like '+#39+L2+ '%'+#39+
                          ' and band='+#39+band+#39+daylimit+
                          'union all '+
                          'select count(loc) from '+LogTable+
                          ' where loc like '+#39+L2+ '%'+#39+daylimit;


      if LocalDbg then Write('Main loc query: ');
      dmData.W.Open;
      i := 1;
      while not dmData.W.Eof do
                begin
                 if LocalDbg then writeln(dmData.W.FieldByName('sum').AsInteger);
                 if (dmData.W.FieldByName('sum').AsInteger > 0 ) and (WkdMainGrid = 0) then WkdMainGrid := i;
                 inc(i);
                 dmData.W.Next;
                end;
       dmData.W.Close;
    finally
      dmData.trW.Rollback;
    end;
     if LocalDbg then  Writeln('WkdMainGrid is:', WkdMainGrid);
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
  L2,
  L4: String;

begin
  if LocalDbg then Writeln('Start WkdGrid');
  WkdGrid := 0;
  L4:= copy(loc, 1, 4);
  L2:= copy(loc, 1, 2);
  if cqrini.ReadBool('wsjt','wb4CLoc', False) then
            daylimit := ' and qsodate >= '+#39+cqrini.ReadString('wsjt', 'wb4locdate','1900-01-01')+#39 //default date check all qsos
     else
            daylimit :='';

  dmData.W.Close;
  if dmData.trW.Active then dmData.trW.Rollback;

  try
    dmData.W.SQL.Text := 'select count(loc) as '+#39+'sum'+#39+' from '+LogTable+
                          ' where loc like '+#39+L4+ '%'+#39+
                          ' and band='+#39+band+#39+' and mode='+#39+mode+#39+daylimit+
                          'union all '+
                          'select count(loc) from '+LogTable+
                          ' where loc like '+#39+L4+ '%'+#39+
                          ' and band='+#39+band+#39+daylimit+
                          'union all '+
                          'select count(loc) from '+LogTable+
                          ' where loc like '+#39+L4+ '%'+#39+daylimit+
                          'union all '+
                          'select count(loc) from '+LogTable+
                          ' where loc like '+#39+L2+ '%'+#39+
                          ' and band='+#39+band+#39+' and mode='+#39+mode+#39+daylimit+
                          'union all '+
                          'select count(loc) from '+LogTable+
                          ' where loc like '+#39+L2+ '%'+#39+
                          ' and band='+#39+band+#39+daylimit+
                          'union all '+
                          'select count(loc) from '+LogTable+
                          ' where loc like '+#39+L2+ '%'+#39+daylimit ;

    if LocalDbg then Write('loc query: ');
    dmData.W.Open;
    i := 1;
    while not dmData.W.Eof do
              begin
               if LocalDbg then writeln(dmData.W.FieldByName('sum').AsInteger);
               if (dmData.W.FieldByName('sum').AsInteger > 0 ) and (WkdGrid = 0) then WkdGrid := i;
               inc(i);
               dmData.W.Next;
              end;
     dmData.W.Close;
  finally
    dmData.trW.Rollback;
  end;
   if LocalDbg then  Writeln('WkdGrid is:', WkdGrid);
end;

function TfrmWorkedGrids.WkdCall(call, band, mode: string): integer;
//returns 0=not wkd
//        1= this band and mode
//        2=this band but NOT this mode
//        3=any other band or mode

var
  i : integer;
  daylimit : String;

begin
  if LocalDbg then Writeln('Start WkdCall');
  //in case we were called from contest form open
  if ((frmContest.Showing) and ((frmContest.rbDupeCheck.Checked) or (frmContest.rbNoMode4Dupe.Checked)))
      then
            daylimit := ' and qsodate >= '+#39+cqrini.ReadString('frmContest', 'DupeFrom', '1900-01-01')+#39 //default date check all qsos
   else
     Begin
        if cqrini.ReadBool('wsjt','wb4CCall', False) then
            daylimit := ' and qsodate >= '+#39+cqrini.ReadString('wsjt', 'wb4Calldate','1900-01-01')+#39
          else
            daylimit :='';
     end;

  WkdCall := 0;
  dmData.W.Close;
  if dmData.trW.Active then dmData.trW.Rollback;
  try
     dmData.W.SQL.Text := 'select count(callsign) as '+#39+'sum'+#39+' from '+LogTable+
                          ' where callsign='+#39+call+#39+
                          ' and band='+#39+band+#39+' and mode='+#39+mode+#39+daylimit+
                          'union all '+
                          'select count(callsign) from '+LogTable+
                          ' where callsign='+#39+call+#39+
                          ' and band='+#39+band+#39+daylimit+
                          'union all '+
                          'select count(callsign) from '+LogTable+
                          ' where callsign='+#39+call+#39+daylimit;

    if LocalDbg then Write('call query: ');
    dmData.W.Open;
    i := 1;
    while not dmData.W.Eof do
              begin
               if LocalDbg then writeln(dmData.W.FieldByName('sum').AsInteger);
               if (dmData.W.FieldByName('sum').AsInteger > 0 ) and (WkdCall = 0) then WkdCall := i;
               inc(i);
               dmData.W.Next;
              end;
    dmData.W.Close;
    finally
      dmData.trW.Rollback;
    end;
  if LocalDbg then  Writeln('WkdCall is:', WkdCall);
end;
function TfrmWorkedGrids.WkdState(state, band, mode: string): integer;
//returns 0=not wkd
//        1= this band and mode
//        2=this band but NOT this mode
//        3=any other band or mode

var
  i : integer;
  daylimit : String;

begin
  if LocalDbg then Writeln('Start WkdState');
  if cqrini.ReadBool('wsjt','wb4CCall', False) then
            daylimit := ' and qsodate >= '+#39+cqrini.ReadString('wsjt', 'wb4Calldate','1900-01-01')+#39 //default date check all qsos
     else
            daylimit :='';

  WkdState := 0;
  dmData.W.Close;
  if dmData.trW.Active then dmData.trW.Rollback;
  try
     dmData.W.SQL.Text := 'select count(state) as '+#39+'sum'+#39+' from '+LogTable+
                          ' where state='+#39+state+#39+
                          ' and band='+#39+band+#39+' and mode='+#39+mode+#39+daylimit+
                          'union all '+
                          'select count(state) from '+LogTable+
                          ' where state='+#39+state+#39+
                          ' and band='+#39+band+#39+daylimit+
                          'union all '+
                          'select count(state) from '+LogTable+
                          ' where state='+#39+state+#39+daylimit;

    if LocalDbg then Write('state query: ');
    dmData.W.Open;
    i := 1;
    while not dmData.W.Eof do
              begin
               if LocalDbg then writeln(dmData.W.FieldByName('sum').AsInteger);
               if (dmData.W.FieldByName('sum').AsInteger > 0 ) and (WkdState = 0) then WkdState := i;
               inc(i);
               dmData.W.Next;
              end;
    dmData.W.Close;
    finally
      dmData.trW.Rollback;
    end;
  if LocalDbg then  Writeln('WkdState is:', WkdState);
end;

//mark grid worked with confirmed status (red/green)
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
    if Cfmd then  Pcolor := clLime else Pcolor := clred;
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
      FillRect(v + 3, h + 3, v + 36, h + 16);
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
procedure TfrmWorkedGrids.DrawFullMap;
begin
   BmpTmp := TBitmap.Create;
   BmpTmp.Width := LocMapBase.Picture.Bitmap.Width;
   BmpTmp.Height := LocMapBase.Picture.Bitmap.Height;
   BmpTmp.Canvas.CopyRect(Rect(0, 0, BmpTmp.Width, BmpTmp.Height), LocMapBase.Picture.Bitmap.Canvas, Rect(0, 0, BmpTmp.Width, BmpTmp.Height));
   UpdateGrids;
   if not ShoWkdOnly.Checked then DrawGridLines(BmpTmp.canvas, FullMap);
   LocMap.Picture.Bitmap.SetSize(TrueSizeW, TrueSizeH); //finally visible streched grid map
   LocMap.Picture.Bitmap.Canvas.StretchDraw(Rect(0, 0, TrueSizeW, TrueSizeH), BmpTmp);
   BmpTmp.Clear;
   BmpTmp.Free;
end;

procedure TfrmWorkedGrids.DrawSubMap;
var
  Bmp : TBitmap;
  ww,
  hh: integer;

begin
  if (BandSelector.ItemIndex >= 0) and (WsMode.ItemIndex >= 0) then  //both must be set
  begin
    ww := 0;
    hh := 0;
    Bmp := TBitmap.Create; //holds copy of one grid from full base map
    Bmp.Width := 40;
    Bmp.Height := 20;
    Bmp.Canvas.CopyRect(Rect(0, 0, 40,20),
      LocMapBase.Picture.Bitmap.Canvas,
      Rect(MouseX*40, MouseY*20, MouseX*40 + 41, MouseY*20 + 21));

    BmpTmp := TBitmap.Create; //holds std size stretched bmp with added subgrid base
    BmpTmp.Width:=401;
    BmpTmp.Height:=201;
    BmpTmp.Canvas.StretchDraw( Rect(0, 0, BmpTmp.Width, BmpTmp.Height), Bmp);
    Bmp.Clear;
    Bmp.Free;

    with BmpTmp.Canvas do   //write main grid letters to submap
     begin
      Brush.style := bsClear;
      font.Color := $00EBFA;
      Font.Style := [fsBold];
      font.Size := 80;
      GetTextSize(LockMainGrid, ww, hh);
      TextOut((Width-ww) div 2, (Height-hh) div 2, LockMainGrid);
    end;

    UpdateGrids;

    DrawGridLines(BmpTmp.Canvas, SubMap);
    ZooMap.Picture.Bitmap.SetSize(TrueSizeW, TrueSizeH); //finally visible streched subgrid map
    ZooMap.Picture.Bitmap.Canvas.StretchDraw(Rect(0, 0, TrueSizeW, TrueSizeH), BmpTmp);
    BmpTmp.Clear;
    BmpTmp.Free;
  end;

end;

//draws grid or subgrid lines over std size map image canvas and mark grids
procedure TfrmWorkedGrids.DrawGridLines(BCanvas: TCanvas; SubBase: boolean);

var
  v, vc, h, hc, Bwidth, Bheight, ltrbase: integer;

begin
  //full size map
  Bwidth := 720;
  Bheight := 360;
  ltrbase := 65; //adds grid letters AA-RR

  //subgrid map
  if SubBase then
              begin
                Bwidth := 400;
                Bheight := 200;
                ltrbase := 48; //adds subgrid numbers 00-99
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
  //set debug rules for this form
  LocalDbg := dmData.DebugLevel >= 1 ;
  if dmData.DebugLevel < 0 then
        LocalDbg :=  LocalDbg or ((abs(dmData.DebugLevel) and 4) = 4 );

  //load map base image
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
     LocMapBase.Picture.Bitmap.Canvas,
     Rect(0, 0, Width, Height));

  DrawGridLines(LocMap.canvas, FullMap);
  if LocalDbg then Writeln ('Grid map created');
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
  UpdateGridData;
end;

procedure TfrmWorkedGrids.FormClose(Sender: TObject);
begin
  AutoUpdate.Enabled := False;
  cqrini.WriteBool('Worked_grids', 'FollowRig', FollowRig.Checked);
  cqrini.WriteBool('Worked_grids', 'ShowWkdOnly', ShoWkdOnly.Checked);
  dmUtils.SaveWindowPos(frmWorkedGrids);
  frmWorkedGrids.hide;
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
                LockMainGrid + ' ' + IntToStr(GridCount) + 'sub grids';
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
    SaveMapImage.FileName := LogSave + '_' + LockMainGrid + '.jpg';
  SaveMapImage.Execute
end;

procedure TfrmWorkedGrids.AutoUpdateTimer(Sender: TObject);
var
  mode, band: string;
begin
  if LocalDbg then
    Writeln('WkdGrids-TimerTick. FlwRig stage0 is:', FollowRig.Checked);
  AutoUpdate.Enabled := False;

  if ((logname <> dmData.LogName)  //need to update map because of changes
    or (wb4c <>  cqrini.ReadString('wsjt', 'wb4calldate','1900-01-01'))
    or (wb4l <>  cqrini.ReadString('wsjt', 'wb4locdate','1900-01-01'))
    or (wb4lc <> cqrini.ReadBool('wsjt','wb4CLoc', False))
    or (wb4cc <> cqrini.ReadBool('wsjt','wb4CCall', False))
    ) then
      Begin
        Changes := true;
        logname := dmData.LogName;
        wb4c:=cqrini.ReadString('wsjt', 'wb4calldate','1900-01-01');
        wb4l:=cqrini.ReadString('wsjt', 'wb4locdate','1900-01-01');
        wb4lc:=cqrini.ReadBool('wsjt','wb4CLoc', False);
        wb4cc:=cqrini.ReadBool('wsjt','wb4CCall', False);
        if LocalDbg then
           Writeln('WkdGrids-changes detected');
      end;

  if FollowRig.Checked then
  begin
    if LocalDbg then
      Writeln(' FlwRig stage 1 is:', FollowRig.Checked);
    if LocalDbg then
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
      if LocalDbg then
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

  if ((BandSelector.ItemIndex >= 0) and (WsMode.ItemIndex >= 0) and Changes) then UpdateGridData;   //update map(s)
  AutoUpdate.Enabled := True;
end;

procedure TfrmWorkedGrids.WsModeChange(Sender: TObject);
begin
  if (BandSelector.ItemIndex >= 0) then UpdateGridData;
end;

procedure TfrmWorkedGrids.BandSelectorChange(Sender: TObject);
Begin
    UpdateGridData;
end;

procedure TfrmWorkedGrids.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key= VK_ESCAPE) then
  begin
    frmNewQSO.ReturnToNewQSO;
    key := 0
  end
end;

procedure TfrmWorkedGrids.UpdateGridData;
begin
    if not ZooMap.Visible then DrawFullMap else DrawSubMap;
end;

procedure TfrmWorkedGrids.UpdateGrids;
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

    if cqrini.ReadBool('wsjt','wb4CLoc', False) then
            daylimit := ' and qsodate >= '+#39+cqrini.ReadString('wsjt', 'wb4locdate','1900-01-01')+#39 //default date check all qsos
     else
            daylimit :='';

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
      SQLCfm[0] := SQLCfm[0] + ' and loc like ' + #39 + LockMainGrid + '%' + #39;
    end;

    dmData.trW.StartTransaction;
    try
      for c := 1 to 2 do
      begin
        dmData.W.SQL.Text := SQLCfm[0] + SQLCfm[c]+daylimit;
        if LocalDbg then writeln(  dmData.W.SQL.Text);
        dmData.W.Open;
        while not dmData.W.EOF do
        begin
          Grid := dmData.W.FieldByName('lo').AsString;
          MarkGrid(Grid, c = 2, BmpTmp.canvas, ZooMap.Visible);
          dmData.W.Next;
        end;
        dmData.W.Close;
      end;

      //locator counts
      dmData.W.SQL.Text := 'select count(distinct upper(left(loc,2))) as main,count(distinct upper(left(loc,4))) as sub'+
                           copy(SQLCfm[0],pos('from', SQLCfm[0])-1,length(SQLCfm[0]))+daylimit;
      dmData.W.Open;
      if not dmData.W.EOF then
       Begin
         GridCount := dmData.W.FieldByName('sub').AsInteger;
         MainGridCount := dmData.W.FieldByName('main').AsInteger;
         Nrgrids.Caption := IntToStr(MainGridCount) + 'main/' + IntToStr(GridCount) + 'sub grids';
       end;
      dmData.W.Close;

      if cqrini.ReadBool('wsjt','wb4CCall', False) then
            daylimit := ' and qsodate >= '+#39+cqrini.ReadString('wsjt', 'wb4calldate','1900-01-01')+#39 //default date check all qsos
         else
            daylimit :='';

      //qso counts;
      if BandSelector.ItemIndex > 0 then   //some of bands
        SQLBand := ' and band=' + #39 + BandSelector.items[BandSelector.ItemIndex] + #39 + SQLModeTail
        else   //can be else than 0, means all bands
        SQLBand := SQLModeTail;

      dmData.W.SQL.Text := 'select count(callsign) as qso from cqrlog_main where callsign<>'+#39+#39+daylimit+
                            'union all select count(callsign) from cqrlog_main where callsign<>'+#39+#39 + SQLBand +daylimit ;
      dmData.W.Open;
      if not dmData.W.EOF then FullQsoCount := dmData.W.FieldByName('qso').AsString;
      dmData.W.Next;
      if not dmData.W.EOF then BandQsoCount := dmData.W.FieldByName('qso').AsString;
      Nrqsos.Caption := BandQsoCount + '/' + FullQsoCount + 'qsos';
      dmData.W.Close;

    finally
      dmData.trW.Rollback;
    end;

    LogSave := 'Wkd_locs_' + dmData.LogName + '_' +
      BandSelector.items[BandSelector.ItemIndex] + '_' + WsMode.items[WsMode.ItemIndex];
    LogBand := BandSelector.items[BandSelector.ItemIndex];
    frmWorkedGrids.Caption :=
      'Worked locator grids ' + dmData.LogName + ' ' + LogBand + ' ' + WsMode.items[WsMode.ItemIndex];
    Nrstatus.Caption := dmData.LogName;
    Nrgrids.Visible := True;
    Nrstatus.Visible := True;
    Nrqsos.Visible := True;

    AutoUpdate.Enabled := True;
  end;
end;
procedure TfrmWorkedGrids.ZooMapChangeBounds(Sender: TObject);
begin
   MapChangeBounds(ZooMap);
   Changes := True;  //updating map may give better sharpness
end;
procedure TfrmWorkedGrids.LocMapChangeBounds(Sender: TObject);
Begin
  MapChangeBounds(LocMap);
  Changes := True;  //updating map may give better sharpness
end;
procedure TfrmWorkedGrids.MapChangeBounds(Map:Timage);
begin
  with Map do
   Begin
     //original size 721x361   2:1  TrueSize is area where mouse postion is valid
     if  Width/Height < 2 then //base ratio to width
        Begin
          TrueSizeW := Width;
          TrueSizeH := TrueSizeW div 2;
        end
     else   //base ratio to height
       Begin
         TrueSizeH := Height;
         TrueSizeW := TrueSizeH * 2;
       end;
     //subgrid size on TrueSize map
     SubW := round (TrueSizeW / 18 );
     SubH := round (TrueSizeH / 18);
   end;
  //if LocalDbg then writeln('MapSz: ', Width,'x',Height,' TrueSz: ',TrueSizeW,'x',TrueSizeH,' SubSz:',SubW,'x',SubH);
end;

procedure TfrmWorkedGrids.LocMapClick(Sender: TObject);

Begin
   LockMainGrid := chr((MouseX) + 65) + chr((17 - MouseY) + 65);
   LocMap.Visible := False;
   ZooMap.Visible := True;
   DrawSubMap;
end;

procedure TfrmWorkedGrids.ZooMapClick(Sender: TObject);
begin
  ZooMap.Visible := False;
  ShoWkdOnlyClick(ZooMap);
  LocMap.Visible := True;
end;

procedure TfrmWorkedGrids.LocMapMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: integer);
begin
  if not ZooMap.Visible then  //position locks to clicked FullMap grid
   Begin
      if X > TrueSizeW-SubW div 2 then X:= TrueSizeW-SubW div 2; //to half way of last grid
      if Y > TrueSizeH-SubH div 2 then Y:= TrueSizeH-SubH div 2;
      MouseX := (X div SubW);
      MouseY := (Y div SubH);
      //if LocalDbg then writeln('Mouse at:', X,'x',Y,' Sub size:',SubW,'x',SubH,' Sub grid:',MouseX,'x',MouseY);
  end;
end;

procedure TfrmWorkedGrids.ShoWkdOnlyClick(Sender: TObject);
begin
  if ((BandSelector.ItemIndex >= 0) and (WsMode.ItemIndex >= 0) and not ZooMap.Visible ) then UpdateGridData
   else DrawFullMap;
end;


initialization

end.
