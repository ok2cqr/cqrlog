unit fWkd1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqlite3conn, sqldb, mysql56conn, mysql55conn, db, FileUtil,
  Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, LResources, IniFiles;


type

  { TfrmWorked_grids }

    TfrmWorked_grids = class(TForm)
    modeLabel: TLabel;
    DBConnection: TMySQL55Connection;
    FollowRig: TCheckBox;
    WsMode: TComboBox;
    Nrstatus: TLabel;
    BandSelector: TComboBox;
    AutoUpdate: TTimer;
    Nrgrids: TLabel;
    Nrqsos: TLabel;
    ZooLbl: TLabel;
    LocMapBase: TImage;
    ZooMap: TImage;
    Logo: TLabel;
    ShoWkdOnly: TCheckBox;
    SaveMapImage: TSaveDialog;
    SaveMap: TButton;
    DataSource1: TDataSource;
    LocMap: TImage;
    BandLabel: TLabel;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
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
  public
    { public declarations }
    function RecordCount(SwConTrans:boolean) :String;
    procedure ConnectionInfo;
    function WkdGrid(loc,band,mode:string):integer;  //returns 0=not wkd, 1=main grid wkd, 2=wkd
    function WkdCall(call,band,mode:string):boolean;  //returns wkd=true
  end;

var
  frmWorked_grids: TfrmWorked_grids; //Main form
  MaxRowId,                    //rows in table (Number of qsos in log database)
  BandQsoCount,                //Number of qsos on selected band
  LogDatabase,                 //Log database file name (+path)
  LogTable,                    //Table name found from database file (own call ad locator)
  LogUsername,
  LogPassword,
  LogHostname,
  LogPort,
  LogBand,                     //Band that is selected for worked locators
  LogSave,                     //Default File name for saving image
  LogMainGrid     : String;    //first 2 letters ov locator grid clicked from map
  MouseX, MouseY,              //Mouse position on loc map rounded to grids up/right corner
  MainGridCount,               //Number of Maingrids (achrs) from query result
  GridCount       :integer;    //Number of subgrids (4chrs) from query result



implementation

{$R *.lfm}
Uses fNewQSO,fTRXControl,dData;

{ TfrmWorked_grids }


procedure TfrmWorked_grids.ConnectionInfo;
Var
    ini : TIniFile;
    s   :longint;
    ao  :string;
begin
{         //Mysql/MariaDB usage is a hack from original version's SQlite DB usage (actually queries are almost same format)
         // these values work only @OH1KH !!!!
         //we need to get these from cqrlog main code (dData ???) after used log is selected !
         LogDatabase := 'cqrlog001';
         LogTable := 'cqrlog_main';
         LogUsername := 'cqrlog';
         LogPassword := 'oh1kh';
         LogHostname := '127.0.0.1';

         //OK. we can do it like this, but does it work with internal DB? Not tested!
         }
         ini := TIniFile.Create(GetAppConfigDir(False)+'cqrlog_login.cfg');
         try
         LogHostname := ini.ReadString('Login','Server','');
         LogPort     := ini.ReadString('Login','Port','');
         LogPassword := ini.ReadString('Login','Pass','');
         ao          := ini.ReadString('Login','AutoOpen','');
         if ao = '1' then
              TryStrToInt(ini.ReadString('Login','LastLog',''),s)
          else
              TryStrToInt(ini.ReadString('Login','LastOpenedLog',''),s);
         LogUsername := ini.ReadString('Logini','User','');
         finally
          ini.Free
         end;

         LogDatabase := dmData.GetProperDBName(s);
         LogTable := 'cqrlog_main';  //assume table name is this always
         DBConnection.DataBaseName:=LogDatabase;
         DBConnection.HostName:=LogHostname;
         if TryStrToInt(LogPort,s) then DBConnection.Port := s;
         DBConnection.UserName:=LogUsername;
         DBConnection.Password:=LogPassword;
end;

function TfrmWorked_grids.RecordCount(SwConTrans:boolean) :String;
 Begin


       SQLQuery1.Close;
      // SQLQuery1.SQL.Text:= 'select max(rowid) from '+LogTable;     sqlite's
       SQLQuery1.SQL.Text:= 'select count(callsign) from '+LogTable;
       ConnectionInfo;
       if SwConTrans then
         Begin
          DBConnection.Connected:= True;
          SQLTransaction1.Active:= True;
         end;
       SQLQuery1.Open;
       RecordCount := SQLQuery1.fields[0].AsString;
       if (RecordCount = '') then
               RecordCount := '0';
       SQLQuery1.Close;
       if SwConTrans then
         Begin
          SQLTransaction1.Active:= False;
          DBConnection.Connected:= False;
         end;
end;
function TfrmWorked_grids.WkdGrid(loc,band,mode:string):integer;
Begin
     WkdGrid:= 0;
     SQLQuery1.Close;
     SQLQuery1.SQL.Text:='select loc from '+LogTable+' where band='+chr(39)+band+chr(39)+
                         ' and mode='+chr(39)+mode+chr(39)+' and loc like '+chr(39)+loc+'%'+chr(39);
     if dmData.DebugLevel>=1 then Writeln(SQLQuery1.SQL.Text);
     ConnectionInfo;
     DBConnection.Connected:= True;
     SQLTransaction1.Active:= True;
     SQLQuery1.Open;
     if SQLQuery1.fields[0].AsString <> '' then
               WkdGrid:= 2;
     SQLQuery1.Close;
     if WkdGrid = 0 then
       Begin
        SQLQuery1.SQL.Text:='select loc from '+LogTable+' where band='+chr(39)+band+chr(39)+
                         ' and mode='+chr(39)+mode+chr(39)+' and loc like '+chr(39)+copy(loc,1,2)+'%'+chr(39);
        if dmData.DebugLevel>=1 then Writeln(SQLQuery1.SQL.Text);
        SQLQuery1.Open;
        if SQLQuery1.fields[0].AsString <> '' then
                                        WkdGrid:= 1;
        SQLQuery1.Close;
       end;
     SQLTransaction1.Active:= False;
     DBConnection.Connected:= False;
     if dmData.DebugLevel>=1 then Writeln('WkdGrid is:',WkdGrid);
end;
function TfrmWorked_grids.WkdCall(call,band,mode:string):boolean;
Begin
     WkdCall:=False;
     SQLQuery1.Close;
     SQLQuery1.SQL.Text:='select callsign from '+LogTable+' where band='+chr(39)+band+chr(39)+
                         ' and mode='+chr(39)+mode+chr(39)+' and callsign='+chr(39)+call+chr(39);
     if dmData.DebugLevel>=1 then Writeln(SQLQuery1.SQL.Text);
     ConnectionInfo;
     DBConnection.Connected:= True;
     SQLTransaction1.Active:= True;
     SQLQuery1.Open;
     if SQLQuery1.fields[0].AsString <> '' then
               WkdCall:= True;
     SQLQuery1.Close;
     SQLTransaction1.Active:= False;
     DBConnection.Connected:= False;
     if dmData.DebugLevel>=1 then Writeln('WkdCall is:',WkdCall);
end;

procedure MarkGrid(LocGrid : String;Canvas : TCanvas; SubBase : boolean);

  var v,vs,h,hs,Mheight,ltrbase,Pwidth,Pcolor,Grid1,Grid2:integer;

begin
  LocGrid:=UpperCase(LocGrid);//to be sure ;)
  Pwidth := 2;
  Pcolor := clMaroon;
  Mheight := 360;
  ltrbase := 65;
  Grid1 := 1;
  Grid2 := 2;

  if SubBase then
   Begin
        Pwidth := 4;
        Pcolor := clred;
        Mheight := 200;
        ltrbase := 48;
        Grid1 := 3;
        Grid2 := 4;
   end;
  with Canvas do
    begin
      //draw main grids
      v:=(ord(LocGrid[Grid1])- ltrbase)*40;
      h:=Mheight - (ord(LocGrid[Grid2])-(ltrbase-1))*20;

      brush.style := bsClear;
      pen.Color := Pcolor;
      pen.width := Pwidth;
      Rectangle(v, h, v+41, h+21);

      //name grids
      font.Size := 7;
      font.Color := Pcolor;
      Font.Style := [fsBold];
      TextOut(v+15,h+5, LocGrid[Grid1]+LocGrid[Grid2]);
      Font.Style := [];

      //draw sub grids
      if not SubBase then
      Begin
           hs:= h + 20 - ((ord(LocGrid[4])-47)*2);
           vs:= v + (ord(LocGrid[3])-48)*4;
           pen.Color := clred;
           Rectangle(vs, hs, vs+4, hs+2);
      end;
    end;
end;


procedure DrawBase(Canvas : TCanvas; SubBase : boolean);

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

  with Canvas do
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

var ErrorMsg,
    ParOption: String;

begin
     AutoUpdate.enabled := False;
     AutoUpdate.Interval := 5000;
     WsMode.Itemindex := -1;
     BandSelector.Itemindex := -1;
     LogSave := 'Wkd_locs_empty';
     LogBand := ' ';
     Logo.Caption := 'V1.0cqr @OH1KH-2015';

     //load map base image
     LocMapBase.Picture.LoadFromLazarusResource('borders');

     ConnectionInfo;

     frmWorked_grids.Caption := frmWorked_grids.Caption+' '+LogDatabase+' '+LogBand;

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
        AddText  :=LogTable+' '+LogBand+' '+WsMode.items[WsMode.Itemindex]+'  '+
                              intToStr(MainGridCount)+'main/'+intToStr(GridCount)+'sub grids     '+
                              ExtractFileName(LogDatabase)+'     '+BandQsoCount+'/'+MaxRowId+'qsos';
        end
      else
       begin
        AddSize  := 40;
        aWidth   := ZooMap.Picture.Bitmap.Width;
        aHeight  := ZooMap.Picture.Bitmap.Height + AddSize;
        AddText  := LogTable+'     '+LogBand+' '+WsMode.items[WsMode.Itemindex]+'    '+
                    LogMainGrid+' -> '+intToStr(GridCount)+'subgrids';
        AddText1 := ExtractFileName(LogDatabase)+'    '+BandQsoCount+'/'+MaxRowId+'qsos';
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
      band,
      GotRows: String;
      i        : integer;
      Changes  : Boolean;

Procedure ToRigMode;
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

procedure ToRigBand;
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

begin
   AutoUpdate.enabled := False;
   Changes := False;
   if FollowRig.Checked then
      Begin
       if frmTRXControl.GetModeBand(mode,band) then
        Begin
          //here wsjt-x makes exeption as mode is JT9 , JT65 or combination JT9+JT65 not what RigCtl says
          //maybe same is needed from fldigi, too. It just does not update it before qso is logged!
          //perhaps could use preference's option: (rigctl, from program or fixed "RTTY")

          //empty frmNewQSO.WsjtxMode causes crash. Happens if "follow rig" checked before wsjtx starts.
          if frmNewQSO.mnuRemoteModeWsjtx.Checked and (frmNewQSO.WsjtxMode<>'')then
                              mode := frmNewQSO.WsjtxMode;
          if dmData.DebugLevel>=1 then Writeln('Follow rig mode: ',mode,' Band: ',band);
          if WsMode.Itemindex < 0 then
             ToRigMode
            else
             if WsMode.Items[WsMode.Itemindex] <> mode then
                ToRigMode;

          if BandSelector.Itemindex < 0 then
             ToRigBand
            else
             if BandSelector.Items[BandSelector.Itemindex] <> band then
                ToRigBand;
        end;
      end;

   if (BandSelector.itemIndex >= 0) and (WsMode.Itemindex >= 0) then    //both must be set
      begin
        GotRows := RecordCount(True);
        if (MaxRowId <> GotRows) or Changes then
          Begin
           BandSelectorChange(AutoUpdate);   //update map(s)
          end;

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
    ZooLbl.Visible := False;
    ShoWkdOnlyClick(ZooMap);
    LocMap.Visible := True;
end;

procedure TfrmWorked_grids.BandSelectorChange(Sender: TObject);   //update map(s)
var
      MainGridStream,
      SQLExtension,
      Grid           : String;
      qsocount       : integer;
Begin
    AutoUpdate.enabled := False;
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
           // not set
     -1    : if BandSelector.itemIndex > 0 then //band selected
                Begin
                 SQLExtension := '';
                 WsMode.itemindex := 0; //any
                end;
           //any
      0    : SQLExtension := '';
           //JT9+JT65
      16    : SQLExtension := ' and ((mode='+chr(39)+'JT9'+chr(39)+') or ( mode='+chr(39)+'JT65'+chr(39)+'))';

        else  // all others
          SQLExtension := ' and mode='+chr(39)+WsMode.items[WsMode.Itemindex]+chr(39);
      end;

       SQLQuery1.Close;

       if BandSelector.itemIndex > 0 then //band selected
          Begin
           SQLQuery1.SQL.Text:= 'select distinct upper(left(loc,4)) as lo from '+LogTable+' where band='+chr(39)+
                                 BandSelector.items[BandSelector.itemIndex]+chr(39)+
                                 'and loc<>'+chr(39)+chr(39)+SQLExtension;
          end
       else     //band "all"
          Begin
            SQLQuery1.SQL.Text:= 'select distinct upper(left(loc,4)) lo from '+LogTable+' where loc<>'+chr(39)+chr(39)+SQLExtension;
          end;

       if ZooMap.Visible then  //coming from zoomed grid
           Begin
            SQLQuery1.SQL.Text:= SQLQuery1.SQL.Text + ' and loc like '+chr(39)+LogMainGrid+'%'+chr(39);
           end;


       if dmData.DebugLevel>=1 then Write( SQLQuery1.SQL.Text );
       ConnectionInfo;
       DBConnection.Connected:= True;
       SQLTransaction1.Active:= True;
       SQLQuery1.Open;
       GridCount:= 0;
       MainGridCount:= 0;
       MainGridStream := '';
       while not SQLQuery1.Eof do
         begin
           Grid := SQLQuery1.FieldByName('lo').AsString;
           if ZooMap.Visible then  //coming from zoomed grid
              Begin
                 MarkGrid(Grid ,ZooMap.canvas,True);
              end
                else
              Begin
                 MarkGrid(Grid ,LocMap.canvas,False);
              end;
          If pos(copy(Grid ,1,2),MainGridStream) = 0 then
             Begin
              inc(MainGridCount);
              MainGridStream := MainGridStream +','+ copy(Grid ,1,2);
             end;
          inc(GridCount);
          SQLQuery1.Next;
         end;

      MaxRowId := RecordCount(False);
      if (BandSelector.itemIndex > 0) then
         Begin
           qsocount:=0;
           SQLQuery1.SQL.Text:= 'select loc from '+LogTable+' where band='+chr(39)+
                                 BandSelector.items[BandSelector.itemIndex]+chr(39)+
                                 SQLExtension;

           if dmData.DebugLevel>=1 then Write( SQLQuery1.SQL.Text );

           SQLQuery1.Open;
           while not SQLQuery1.Eof do
             Begin
                 inc(qsocount);
                 SQLQuery1.Next;
             end;
           SQLQuery1.Close;
           BandQsoCount := IntToStr(qsocount);
         end
      else
         Begin
           BandQsoCount := MaxRowId;
         end;

      SQLTransaction1.Active:= False;
      DBConnection.Connected:= False;

      if (BandSelector.itemIndex >= 0) and (WsMode.Itemindex >= 0) then    //both must be set
         Begin
          LogSave := 'Wkd_locs_'+LogTable+'_'+BandSelector.items[BandSelector.itemIndex];
          LogBand := BandSelector.items[BandSelector.itemIndex];
          frmWorked_grids.Caption := 'Worked locator grids '+LogDatabase+' '+LogBand+' '+WsMode.items[WsMode.Itemindex];
          end;

      Nrgrids.Caption  := intToStr(MainGridCount)+'main/'+intToStr(GridCount)+'sub grids';
      Nrstatus.Caption := ExtractFileName(LogDatabase);
      Nrqsos.Caption   := BandQsoCount+'/'+MaxRowId+'qsos';
      Nrgrids.Visible := True;
      Nrstatus.Visible := True;
      Nrqsos.Visible := True;

      AutoUpdate.enabled := True;
end;

procedure TfrmWorked_grids.FormShow(Sender: TObject);
begin
  AutoUpdate.enabled := True;
end;

procedure TfrmWorked_grids.LocMapClick(Sender: TObject);

var Bmp:TBitmap;
 aWidth,aHeight:integer;

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
      ZooLbl.Caption := LogMainGrid;
      ZooMap.Visible := True;
      ZooLbl.Visible := True;
      LocMap.Visible := False;
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
  frmWorked_grids.hide;
end;



Initialization
{$i fwkd.lrs}




end.

