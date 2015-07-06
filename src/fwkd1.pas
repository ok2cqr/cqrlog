unit fWkd1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,FileUtil,
  Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, LResources, IniFiles;


type

  { TfrmWorked_grids }

    TfrmWorked_grids = class(TForm)
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
    procedure LocMapMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer );
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
    procedure DrawBase(BCanvas : TCanvas; SubBase : boolean);
    procedure MarkGrid(LocGrid : String; Cfmd:boolean; MCanvas : TCanvas; SubBase : boolean);
  public
    { public declarations }
    Procedure ToRigMode(mode:string);
    Procedure ToRigBand(band:string);
    function RecordCount:String;
    function WkdGrid(loc,band,mode:string):integer;  //returns 0=not wkd, 1=main grid wkd, 2=wkd
    function WkdCall(call,band,mode:string):boolean;  //returns wkd=true
    function GridOK(Loc: string): boolean;
    procedure UpdateMap;
  end;

var
  frmWorked_grids: TfrmWorked_grids; //Main form
  MaxRowId,                    //rows in table (Number of qsos in log database)
  BandQsoCount,                //Number of qsos on selected band
  LogTable,                    //Table name found from database file (own call ad locator)
  LogBand,                     //Band that is selected for worked locators
  LogSave,                     //Default File name for saving image
  LogMainGrid     : String;    //first 2 letters of locator grid clicked from map
  MouseX, MouseY,              //Mouse position on loc map rounded to grids up/right corner
  MainGridCount,               //Number of Maingrids (achrs) from query result
  GridCount       :integer;    //Number of subgrids (4chrs) from query result
  Changes         : Boolean;   //changes in rig mode/band


implementation

{$R *.lfm}
Uses fNewQSO,fTRXControl,dData,dUtils;

{ TfrmWorked_grids }


function TfrmWorked_grids.GridOK(Loc: string): boolean;
var
  i: integer;
begin
  Result := True;
  Loc := trim(UpCase(Loc));
 if Length(Loc) mod 2 = 0 then
    Begin
    for i:=1 to length(loc) do
        Begin
          case i of
          1, 2, 5, 6: case Loc[i] of
                           'A'..'R':Begin {OK!} end;
                           else
                           Result := False;
                           end;
          3, 4, 7, 8: case Loc[i] of
                           '0'..'9':Begin {OK!} end;
                           else
                           Result := False;
                           end;
          end;
        end;
    end
   else
    Begin
     Result:=false;
    end;
end;
Procedure TfrmWorked_grids.ToRigMode(mode:string);
var
 i        : integer;
Begin
  if dmData.DebugLevel>=1 then Writeln('ToRigMode ',WsMode.Itemindex);
   i:=0;
   Changes := True;
   repeat
    begin
     if WsMode.Items[i] = mode then
      Begin
       WsMode.Itemindex := i;
       i := WsMode.Items.Count;
      end;
     inc(i);
     end;
    until (i > WsMode.Items.Count);
   if dmData.DebugLevel>=1 then Writeln(i,'  ',WsMode.Items[WsMode.Itemindex]);
end;
procedure TfrmWorked_grids.UpdateMap;
Begin
 BandSelectorChange(AutoUpdate);   //update map(s)
end;

procedure TfrmWorked_grids.ToRigBand(band:string);
var
 i        : integer;
Begin
  if dmData.DebugLevel>=1 then Writeln('ToRigBand ',BandSelector.Itemindex);
  i:=0;
  Changes := True;
  repeat
   begin
    if BandSelector.Items[i] = band then
     Begin
      BandSelector.Itemindex := i;
      i := BandSelector.Items.Count;
     end;
     inc(i);
    end;
   until (i > BandSelector.Items.Count);
  if dmData.DebugLevel>=1 then Writeln(i,'  ',BandSelector.Items[BandSelector.Itemindex]);
end;

function TfrmWorked_grids.RecordCount:String;
 Begin


       dmData.Q1.Close;
       if dmData.trQ1.Active then dmData.trQ1.Rollback;
       dmData.Q1.SQL.Text := 'select count(callsign) from '+LogTable;
       dmData.trQ1.StartTransaction;
       try
        dmData.Q1.Open;
        RecordCount := dmData.Q1.Fields[0].AsString;
        if (RecordCount = '') then
               RecordCount := '0';
        dmData.Q1.Close;

       finally
        dmData.trQ1.Rollback;
       end;
end;
function TfrmWorked_grids.WkdGrid(loc,band,mode:string):integer;
Begin
     WkdGrid:= 0;
     dmData.Q.Close;
     if dmData.trQ.Active then dmData.trQ.Rollback;

     dmData.Q.SQL.Text:='select loc from '+LogTable+' where band='+chr(39)+band+chr(39)+
                         ' and mode='+chr(39)+mode+chr(39)+' and loc like '+chr(39)+loc+'%'+chr(39);
     if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
     dmData.trQ.StartTransaction;
     try
       dmData.Q.Open;
       if dmData.Q.Fields[0].AsString <> '' then
               WkdGrid:= 2;
       dmData.Q.Close;
       if WkdGrid = 0 then
        Begin
         dmData.Q.SQL.Text:='select loc from '+LogTable+' where band='+chr(39)+band+chr(39)+
                         ' and mode='+chr(39)+mode+chr(39)+' and loc like '+chr(39)+copy(loc,1,2)+'%'+chr(39);
         if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
        dmData.Q.Open;
        if dmData.Q.Fields[0].AsString <> '' then
                                        WkdGrid:= 1;
       dmData.Q.Close;
       end;
       finally
        dmData.trQ.Rollback;
       end;
     if dmData.DebugLevel>=1 then Writeln('WkdGrid is:',WkdGrid);
end;
function TfrmWorked_grids.WkdCall(call,band,mode:string):boolean;
Begin
     WkdCall:=False;
     dmData.Q.Close;
     if dmData.trQ.Active then dmData.trQ.Rollback;
     dmData.Q.SQL.Text:='select callsign from '+LogTable+' where band='+chr(39)+band+chr(39)+
                         ' and mode='+chr(39)+mode+chr(39)+' and callsign='+chr(39)+call+chr(39);
     if dmData.DebugLevel>=1 then Writeln(dmData.Q.SQL.Text);
     try
       dmData.Q.Open;
       if dmData.Q.Fields[0].AsString <> '' then
               WkdCall:= True;
       dmData.Q.Close;
     finally
      dmData.trQ.Rollback;
     end;
     if dmData.DebugLevel>=1 then Writeln('WkdCall is:',WkdCall);
end;

procedure TfrmWorked_grids.MarkGrid(LocGrid : String; Cfmd:boolean ;MCanvas : TCanvas; SubBase : boolean);

  var v,vs,h,hs,
      Mheight,ltrbase,
      Pwidth,Pcolor,
      Grid1,Grid2       :integer;


begin
  LocGrid:=UpperCase(LocGrid);//to be sure ;)
  Pwidth := 2;
  if Cfmd then Pcolor := clGreen else Pcolor := clMaroon;
  Mheight := 360;
  ltrbase := 65;
  Grid1 := 1;
  Grid2 := 2;

  if not GridOK(LocGrid) then exit;  // all (4chr) must be valid

  if SubBase then
   Begin
        Pwidth := 4;
        if Cfmd then Pcolor := clLime else Pcolor := clred;
        Mheight := 200;
        ltrbase := 48;
        Grid1 := 3;
        Grid2 := 4;
   end;

  with MCanvas do
    begin
      //draw main grids
      v:=(ord(LocGrid[Grid1])- ltrbase)*40;
      h:=Mheight - (ord(LocGrid[Grid2])-(ltrbase-1))*20;

      brush.style := bsClear;
      pen.Color := Pcolor;
      pen.width := Pwidth;
      if subBase then
        Begin
          brush.Color := Pcolor;
          FillRect(v+3, h+3, v+38, h+18)
        end
       else
        Begin
         Rectangle(v+2, h+2, v+39, h+19);
        end;

      //name grids
      font.Size := 7;
      font.Color := clBlack;
      Font.Style := [fsBold];
      TextOut(v+15,h+5, LocGrid[Grid1]+LocGrid[Grid2]);
      Font.Style := [];

      //draw sub grids
      if not SubBase then
      Begin
           hs:= h + 20 - ((ord(LocGrid[4])-47)*2);
           vs:= v + (ord(LocGrid[3])-48)*4;
           if Cfmd then Pcolor := clLime else Pcolor := clred;
           pen.Color := Pcolor;
           Rectangle(vs, hs, vs+4, hs+2);
      end;
    end;
end;


procedure TfrmWorked_grids.DrawBase(BCanvas : TCanvas; SubBase : boolean);

var v,vc,h,hc,Bwidth,Bheight,ltrbase:integer;

begin

  Bwidth := 720;
  Bheight := 360;
  ltrbase := 65;

  if SubBase then
   Begin
        Bwidth := 400;
        Bheight := 200;
        ltrbase := 48;
   end;

  with BCanvas do
    begin
      v:=0;
      repeat
        Begin
         pen.Color := clGray;
         pen.width := 1;
         line(0,v,Bwidth,v);
         line(v*2,0,v*2,Bheight);
         v:=v+20;
        end;
      until v>Bheight;
      v:=  15;
      vc:= ltrbase;
      repeat
        begin
             h:= Bheight -15; ;
             hc:= ltrbase;
             repeat
               Begin
                    Brush.Style:=bsClear;
                    font.Size := 7;
                    font.Color := clGray;
                    TextOut(v,h, chr(vc)+chr(hc));
                    h:=h-20;
                    hc:=hc+1;
               end;
             until h< 0;
        end;
        v:=v+40;
        vc:=vc+1;
      until v>Bwidth;

    end;
end;

procedure TfrmWorked_grids.FormCreate(Sender: TObject);

begin
  AutoUpdate.enabled := False;
  AutoUpdate.Interval := 5000;
  WsMode.Itemindex := -1;
  BandSelector.Itemindex := -1;
  LogSave := 'Wkd_locs_empty';
  LogBand := ' ';
  LogTable := 'cqrlog_main';  //assume table name is this always

  //load map base image
  LocMapBase.Picture.LoadFromLazarusResource('borders');
  frmWorked_grids.Caption := frmWorked_grids.Caption+' '+dmData.LogName+' '+LogBand;

  LocMap.Canvas.CopyRect(Rect(0,0,Width,Height),
  LocMapBase.Picture.Bitmap.Canvas,Rect(0,0,Width,Height));

  DrawBase(LocMap.canvas, False);
end;

procedure TfrmWorked_grids.SaveMapImageClose(Sender: TObject);

var Bmp   :TBitmap;
 AddSize,
 aWidth,
 aHeight  :integer;
 AddText,
 AddText1 : String;

begin
   AddText       :='';
   AddText1      :='';

   try
      if LocMap.Visible Then
        begin
        AddSize  := 20;
        aWidth   :=LocMap.Picture.Bitmap.Width;
        aHeight  :=LocMap.Picture.Bitmap.Height + AddSize;
        AddText  :=dmData.LogName+' '+LogBand+' '+WsMode.items[WsMode.Itemindex]+'  '+
                              intToStr(MainGridCount)+'main/'+intToStr(GridCount)+'sub grids     '+
                              dmData.DBName+'     '+BandQsoCount+'/'+MaxRowId+'qsos';
        end
      else
       begin
        AddSize  := 40;
        aWidth   := ZooMap.Picture.Bitmap.Width;
        aHeight  := ZooMap.Picture.Bitmap.Height + AddSize;
        AddText  := dmData.LogName+'     '+LogBand+' '+WsMode.items[WsMode.Itemindex]+'    '+
                    LogMainGrid+' -> '+intToStr(GridCount)+'subgrids';
        AddText1 := dmData.DBName+'    '+BandQsoCount+'/'+MaxRowId+'qsos';
       end;

      Bmp        :=TBitmap.Create;
      Bmp.Width  :=aWidth;
      Bmp.Height :=aHeight;
      Bmp.Canvas.Rectangle(0, 0,aWidth,aHeight);

      if LocMap.Visible Then
        begin
          Bmp.Canvas.CopyRect(Rect(0,AddSize,aWidth,aHeight),
                      LocMap.Picture.Bitmap.Canvas,
                      Rect(0,0,aWidth,aHeight-AddSize));
        end
      else
       begin
         Bmp.Canvas.CopyRect(Rect(0,AddSize,aWidth,aHeight),
                      ZooMap.Picture.Bitmap.Canvas,
                      Rect(0,0,aWidth,aHeight-AddSize));
       end;
      Bmp.Canvas.Brush.Style:=bsClear;
      Bmp.Canvas.font.Size := 10;
      Bmp.Canvas.font.Color := clBlack;
      Bmp.Canvas.TextOut(5,3, AddText);
      if AddText1 <> '' then
        Bmp.Canvas.TextOut(5,23, AddText1);

      Bmp.SaveToFile(SaveMapImage.FileName);
  except
    on E: Exception do
      ShowMessage('Error: ' + E.Message);
  end;
  Bmp.free;
end;

procedure TfrmWorked_grids.SaveMapClick(Sender: TObject);
begin
  if LocMap.Visible Then
       SaveMapImage.FileName := LogSave+'.bmp'
      else
       SaveMapImage.FileName := LogSave+'_'+LogMainGrid+'.bmp';

  SaveMapImage.Execute;
end;

procedure TfrmWorked_grids.AutoUpdateTimer(Sender: TObject);
var
      mode,
      band: String;


begin
   if dmData.DebugLevel>=1 then Writeln('WkdGrids-TimerTick. FlwRig stage0 is:',FollowRig.Checked );
   AutoUpdate.enabled := False;

   if FollowRig.Checked then
      Begin
       if dmData.DebugLevel>=1 then Writeln(' FlwRig stage 1 is:',FollowRig.Checked );
       if dmData.DebugLevel>=1 then Writeln(' FlwRig getmode returns(st-m-b):',frmTRXControl.GetModeBand(mode,band),' ',mode,' ',band );
       if (frmTRXControl.GetModeBand(mode,band)) and (band<>'') then //if off from ham freq gives True, but empty band !!!
        Begin
          //here wsjt-x makes exeption as mode is JT9 , JT65 or combination JT9+JT65 not what RigCtl says
          //maybe same is needed from fldigi, too. It just does not update it before qso is logged!
          //perhaps could use preference's option: (rigctl, from program or fixed "RTTY")

          //empty frmNewQSO.WsjtxMode causes crash. Happens if "follow rig" checked before wsjtx starts.
          if frmNewQSO.mnuRemoteModeWsjtx.Checked and (frmNewQSO.WsjtxMode<>'')then
                              mode := frmNewQSO.WsjtxMode;
          if dmData.DebugLevel>=1 then Writeln('Follow rig mode: ',mode,' Band: ',band);
          if WsMode.Itemindex < 0 then
             ToRigMode(mode)
            else
             if WsMode.Items[WsMode.Itemindex] <> mode then
                ToRigMode(mode);

          if BandSelector.Itemindex < 0 then
             ToRigBand(band)
            else
             if BandSelector.Items[BandSelector.Itemindex] <> band then
                ToRigBand(band);
        end;
      end;

   if (BandSelector.itemIndex >= 0) and (WsMode.Itemindex >= 0) and Changes then    //both must be set
      begin
        BandSelectorChange(AutoUpdate);   //update map(s)
      end;
  AutoUpdate.enabled := True;
end;

procedure TfrmWorked_grids.WsModeChange(Sender: TObject);

begin
  if (BandSelector.itemIndex >= 0)  then
                            BandSelectorChange(WsMode);
end;


procedure TfrmWorked_grids.ZooMapClick(Sender: TObject);
begin
    ZooMap.Visible := False;
    ZooILbl.Visible := False;
    ShoWkdOnlyClick(ZooMap);
    LocMap.Visible := True;
end;

procedure TfrmWorked_grids.BandSelectorChange(Sender: TObject);   //update map(s)
var
      MainGridStream,
      SQLExtension,
      Grid           : String;
      qsocount,
      c              : integer;
      SQLCfm         : array [0 .. 2] of string;
Begin
  //no updates if band and mode are not set
 if (BandSelector.itemIndex >= 0) and (WsMode.itemindex >= 0) then
  Begin
    AutoUpdate.enabled := False;
    Changes := False;
    //clean map if caller is not zoomed grid(=visible)
    if ZooMap.Visible then
       Begin
        LocMapClick(BandSelector);
       end
    else
       Begin
            LocMap.Canvas.CopyRect(Rect(0,0,Width,Height),
                  LocMapBase.Picture.Bitmap.Canvas,Rect(0,0,Width,Height));
            if not ShoWkdOnly.Checked  then
                   DrawBase(LocMap.canvas,False);
       end;

      case WsMode.itemindex of
           //any
      0    : SQLExtension := '';
           //JT9+JT65
      16    : SQLExtension := ' and ((mode='+chr(39)+'JT9'+chr(39)+') or ( mode='+chr(39)+'JT65'+chr(39)+'))';

        else  // all others
          SQLExtension := ' and mode='+chr(39)+WsMode.items[WsMode.Itemindex]+chr(39);
      end;


      //1:not (at all) confirmed grids
      SQLCfm[1] :=' and eqsl_qsl_rcvd<>'+chr(39)+'E'+chr(39)+' and lotw_qslr<>'+chr(39)+'L'+chr(39)+' and qsl_r<>'+chr(39)+'Q'+chr(39);
      //2:some way confirmed grids
      SQLCfm[2] :=' and (eqsl_qsl_rcvd='+chr(39)+'E'+chr(39)+' or lotw_qslr='+chr(39)+'L'+chr(39)+' or qsl_r='+chr(39)+'Q'+chr(39)+')';

      dmData.Q.Close;
       if dmData.trQ.Active then dmData.trQ.Rollback;

       if BandSelector.itemIndex > 0 then //band selected
          Begin
          //0:the base query string
          SQLCfm[0] := 'select upper(left(loc,4)) as lo from '+LogTable+' where band='+chr(39)+
                       BandSelector.items[BandSelector.itemIndex]+chr(39)+
                       'and loc<>'+chr(39)+chr(39)+SQLExtension;
          end
       else     //band "all"
          Begin
            SQLCfm[0] := 'select upper(left(loc,4)) lo from '+LogTable+' where loc<>'+chr(39)+chr(39)+SQLExtension;
          end;
       if ZooMap.Visible then  //coming from zoomed grid
           Begin
            SQLCfm[0] := SQLCfm[0]  + ' and loc like '+chr(39)+LogMainGrid+'%'+chr(39);
           end;

       GridCount:= 0;
       MainGridCount:= 0;
       MainGridStream := '';
       dmData.trQ.StartTransaction;
       try
       for c:=1 to 2 do
        Begin
          dmData.Q.SQL.Text:= SQLCfm[0] + SQLCfm[c];
         dmData.Q.Open;
         while not dmData.Q.Eof do
           begin
             Grid := dmData.Q.FieldByName('lo').AsString;

             if ZooMap.Visible then  //coming from zoomed grid
                Begin
                   MarkGrid(Grid, c=2 ,ZooMap.canvas,True);
                end
                  else
                Begin
                   MarkGrid(Grid, c=2 ,LocMap.canvas,False);
                end;

            If (GridOK(Grid)) and (pos(copy(Grid ,1,2),MainGridStream) = 0) then
               Begin
                inc(MainGridCount);
                MainGridStream := MainGridStream +','+ copy(Grid ,1,2);
               end;


            dmData.Q.Next;
           end;
         dmData.Q.Close;
        end;

      //distinct sub grid count
      dmData.Q.SQL.Text:= 'select distinct' + copy(SQLCfm[0],7,length(SQLCfm[0]));
      dmData.Q.Open;
      while not dmData.Q.Eof do
              Begin
                 inc(GridCount);
                 dmData.Q.Next;
             end;
      dmData.Q.Close;

      MaxRowId := RecordCount;
      if (BandSelector.itemIndex > 0) then
         Begin
          qsocount:=0;
          dmData.Q.SQL.Text:= 'select loc from '+LogTable+' where band='+chr(39)+
                                 BandSelector.items[BandSelector.itemIndex]+chr(39)+
                                 SQLExtension;

           if dmData.DebugLevel>=1 then Write(dmData.Q.SQL.Text);

           dmData.Q.Open;
           while not dmData.Q.Eof do
              Begin
                 inc(qsocount);
                 dmData.Q.Next;
             end;
           dmData.Q.Close;
           BandQsoCount := IntToStr(qsocount);
         end
      else
         Begin
           BandQsoCount := MaxRowId;
         end;
      finally
      dmData.trQ.Rollback;
      end;
      if (BandSelector.itemIndex >= 0) and (WsMode.Itemindex >= 0) then    //both must be set
         Begin
          LogSave := 'Wkd_locs_'+dmData.LogName+'_'+BandSelector.items[BandSelector.itemIndex];
          LogBand := BandSelector.items[BandSelector.itemIndex];
          frmWorked_grids.Caption := 'Worked locator grids '+dmData.LogName+' '+LogBand+' '+WsMode.items[WsMode.Itemindex];
          end;

      Nrgrids.Caption  := intToStr(MainGridCount)+'main/'+intToStr(GridCount)+'sub grids';
      Nrstatus.Caption := dmData.LogName;
      Nrqsos.Caption   := BandQsoCount+'/'+MaxRowId+'qsos';
      Nrgrids.Visible := True;
      Nrstatus.Visible := True;
      Nrqsos.Visible := True;

      AutoUpdate.enabled := True;
  end;
end;

procedure TfrmWorked_grids.FormShow(Sender: TObject);
begin
  dmUtils.LoadWindowPos(frmWorked_grids);
  AutoUpdate.enabled := True;
end;

procedure TfrmWorked_grids.LocMapClick(Sender: TObject);

var Bmp   :TBitmap;
 aWidth,
 aHeight,
 ww,hh          :integer;

Begin

if (BandSelector.itemIndex >= 0) and (WsMode.Itemindex >= 0) then  //both must be set
 begin
  aWidth:=40;
  aHeight:=20;
  Bmp:=TBitmap.Create;
  Bmp.Width:=aWidth;
  Bmp.Height:=aHeight;
  Bmp.Canvas.CopyRect(Rect(0,0,aWidth,aHeight),
                      LocMapBase.Picture.Bitmap.Canvas,
                      Rect(MouseX,MouseY,MouseX+aWidth+1, MouseY+aHeight+1));
  ZooMap.Picture.Bitmap.SetSize(ZooMap.Width,ZooMap.Height);
  ZooMap.Picture.Bitmap.Canvas.StretchDraw(Rect(0,0,ZooMap.Picture.Bitmap.Width,ZooMap.Picture.Bitmap.Height),Bmp);
  Bmp.free;
  DrawBase(ZooMap.Canvas,True);

  if Sender <> BandSelector then //to avoid BandSelector looping when ZooMap active
     Begin
      LogMainGrid := chr((MouseX)div 40+65)+chr((340-MouseY)div 20+65);
      LocMap.Visible := False;
      ZooMap.Visible := True;
      ZooILbl.Visible := True;
      with ZooIlbl.Canvas do  //had to make this grapic as cqrlog controls font size of window after wkd-map
        Begin                 //position saved/loaded as other forms and I'm too lazy to dig out how to avoid it
          Clear;
          Brush.Color:=clBackground;
          FillRect(0,0,width,height);
          Brush.style:=bsClear;
          font.Color := clBlack;
          Font.Style := [fsBold];
          font.Size := 54;
          repeat            //fit the text to canvas
            Begin
             font.Size := font.Size -1;
             GetTextSize(LogMainGrid, ww, hh);
             if dmData.DebugLevel>=1 then Writeln('Font size:', font.Size);
             end;
          until (ww<=width) and (hh<=height);
           TextOut(1,1 , LogMainGrid);
        end;

      BandSelectorChange(LocMap);
     end;

 end;

end;

procedure TfrmWorked_grids.LocMapMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
     MouseX := (X div 40) * 40;
     MouseY := (Y div 20) * 20;
end;

procedure TfrmWorked_grids.ShoWkdOnlyClick(Sender: TObject);
begin
    if (BandSelector.itemIndex >= 0) and (WsMode.Itemindex >= 0) then   //both must be set
      Begin
         BandSelectorChange(BandSelector);
      end
    else
      Begin
        LocMap.Canvas.CopyRect(Rect(0,0,Width,Height),
               LocMapBase.Picture.Bitmap.Canvas,Rect(0,0,Width,Height));
        if not ShoWkdOnly.Checked  then
           DrawBase(LocMap.canvas,False);
      end;
end;

procedure TfrmWorked_grids.FormClose(Sender: TObject);
begin
  AutoUpdate.enabled := False;
  dmUtils.SaveWindowPos(frmWorked_grids);
  frmWorked_grids.hide;
end;



Initialization
{$i fwkd.lrs}




end.

