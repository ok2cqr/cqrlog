unit fMonWsjtx;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, maskedit, ColorBox, Menus, RichMemo, strutils,  process;

type

  { TfrmMonWsjtx }

  TfrmMonWsjtx = class(TForm)
    noTxt: TCheckBox;
    chkmyAll: TCheckBox;
    chkHistory: TCheckBox;
    chkmyAlert: TCheckBox;
    chkLocAlert: TCheckBox;
    cmCqDx: TMenuItem;
    cmFont: TMenuItem;
    popFontDlg: TFontDialog;
    popColorDlg: TColorDialog;
    EditAlert: TEdit;
    lblAlert1: TLabel;
    lblAlert2: TLabel;
    lblBand: TLabel;
    lblMode: TLabel;
    cmHead: TMenuItem;
    cmNever: TMenuItem;
    cmBand: TMenuItem;
    cmAny: TMenuItem;
    cmHere: TMenuItem;
    popColors: TPopupMenu;
    WsjtxMemo: TRichMemo;
    procedure chkHistoryChange(Sender: TObject);
    procedure chkLocAlertChange(Sender: TObject);
    procedure chkmyAlertChange(Sender: TObject);
    procedure chkmyAllChange(Sender: TObject);
    procedure cmAnyClick(Sender: TObject);
    procedure cmBandClick(Sender: TObject);
    procedure cmCqDxClick(Sender: TObject);
    procedure cmFontClick(Sender: TObject);
    procedure cmHereClick(Sender: TObject);
    procedure cmNeverClick(Sender: TObject);
    procedure EditAlertExit(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure noTxtChange(Sender: TObject);
    procedure WsjtxMemoDblClick(Sender: TObject);
  private
    procedure FocusLastLine;
    procedure AddColorStr(s: string; const col: TColor = clBlack);
    procedure RunVA(Afile: String);
    procedure WsjtxMemoScroll;
   { private declarations }
  public
    procedure CleanWsjtxMemo;
    function NextElement(Message:string;var index:integer):String;
    procedure AddDecodedMessage(Message,Band,Reply:string);
    procedure NewBandMode(Band,Mode:string);
    { public declarations }
  end;
Const
MaxLines :integer = 16;        //Max monitor lines

var
  frmMonWsjtx: TfrmMonWsjtx;
  RepArr     : array [0 .. 16] of string[255];  //static array for reply strings: set max same as MaxLines
  LastWsjtLineTime   : string;                  //time of last printed line
  myAlert            : string;                  //alert name moved to script as 1st parameter
                                                //can be:'my'= ansver to my cq,
                                                //       'loc'=new main grid,
                                                //       'text'= text given is found from new monitor line
  timeToAlert        : string;                  //only once per event per minute
  MonitorLine        : string;                  // complete line as printed to monitor

  extCqCall          : Tcolor =  $000055FF ;    // extended cq (cq dx, cq na etc.) color
  wkdhere            : Tcolor;
  wkdband            : Tcolor;
  wkdany             : Tcolor;
  wkdnever           : Tcolor;

implementation
{$R *.lfm}

{ TfrmMonWsjtx }

Uses fNewQSO,dData,dUtils,dDXCC,fWorkedGrids,uMyini;



procedure TfrmMonWsjtx.RunVA(Afile: String);
const
  cAlert = 'voice_keyer/voice_alert.sh';
var
   AProcess: TProcess;
begin
  if not FileExists(dmData.HomeDir + cAlert) then
  exit;

  AProcess := TProcess.Create(nil);
  try
    AProcess.CommandLine := 'bash ' + dmData.HomeDir + cAlert  +' '+ Afile;
    if dmData.DebugLevel>=1 then Writeln('Command line: ',AProcess.CommandLine);
    AProcess.Execute
  finally
    AProcess.Free
  end
end;
procedure TfrmMonWsjtx.AddColorStr(s: string; const col: TColor = clBlack);
var i : integer;
begin
     for i:= 1 to length(s) do
       Begin
         if ((ord(s[i]) >= 32) and (ord(s[i]) <= 122)) then   //from space to z accepted
                                              MonitorLine := MonitorLine + s[i];
       end;
     if not frmMonWsjtx.noTxt.Checked then
     with WsjtxMemo do
     begin
       if s <> '' then
       begin
         SelStart  := Length(Text);
         SelText   := s;
         SelLength := Length(s);
         if col = wkdnever then
            SetRangeParams (SelStart, SelLength, [tmm_Styles, tmm_Color], '', 0,  col, [fsBold],[] )
          else
            SetRangeColor(SelStart, SelLength, col);
         // deselect inserted string and position cursor at the end of the text
         SelStart  := Length(Text);
         SelText   := '';
       end;
       //FocusLastLine;
     end;

   end;
procedure TfrmMonWsjtx.CleanWsjtxMemo;

var l : integer;
Begin
     WsjtxMemo.lines.Clear;
     for l:=0 to Maxlines do RepArr[l]:='';
end;

procedure TfrmMonWsjtx.FocusLastLine;
begin
   with WsjtxMemo do
     begin
      SelStart := GetTextLen;
      SelLength := 0;
      ScrollBy(0, Lines.Count);
      Refresh;
     end;
end;

procedure TfrmMonWsjtx.WsjtxMemoScroll;
var i: integer;
begin
  //scroll buffer if needed
  if WsjtxMemo.lines.count >= MaxLines then
         Begin
          repeat
            WsjtxMemo.lines.delete(0);
            for i:=0 to MaxLines-2 do
                RepArr[i] := RepArr[i+1];
          until WsjtxMemo.lines.count <= Maxlines;
          FocusLastLine;
         end;
end;

procedure TfrmMonWsjtx.WsjtxMemoDblClick(Sender: TObject);
var
   reply : string;
begin
  if dmData.DebugLevel>=1 then Writeln('Clicked line no:',WsjtxMemo.Caretpos.Y,' Array gives:',RepArr[WsjtxMemo.Caretpos.Y]);
  reply := RepArr[WsjtxMemo.Caretpos.Y];

  if (length(reply) > 11 ) and (reply[12] = #$02) then //we should have proper reply
               Begin
                reply[12] := #$04;    //quick hack: change message type from 2 to 4
                if dmData.DebugLevel>=1 then Writeln('Changed message type from 2 to 4. Sending...');
                frmNewQSO.Wsjtxsock.SendString(reply);
               end;
end;

procedure TfrmMonWsjtx.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin   // these should not be needed any more
   cqrini.WriteBool('MonWsjtx','NoHistory',chkHistory.Checked);
   cqrini.WriteBool('MonWsjtx','NoTxt',noTxt.Checked);
   cqrini.WriteBool('MonWsjtx','MyAlert',chkmyAlert.Checked);
   cqrini.WriteBool('MonWsjtx','MyAll',chkmyAll.Checked);
   cqrini.WriteBool('MonWsjtx','LocAlert',chkLocAlert.Checked);
   cqrini.WriteString('MonWsjtx','TextAlert',EditAlert.Text);
   cqrini.WriteString('MonWsjtx','wkdnever',ColorToString(wkdnever));
   cqrini.WriteString('MonWsjtx','wkdband',ColorToString(wkdband));
   cqrini.WriteString('MonWsjtx','wkdany',ColorToString(wkdany));
   cqrini.WriteString('MonWsjtx','wkdhere',ColorToString(wkdhere));
   dmUtils.SaveWindowPos(frmMonWsjtx);
end;

procedure TfrmMonWsjtx.cmNeverClick(Sender: TObject);
begin
       popColorDlg.Color:=wkdNever;
       popColorDlg.Title := 'Qso never before - color';
       if  popColorDlg.Execute then
           Begin
             wkdNever := ( popColorDlg.Color );
             cqrini.WriteString('MonWsjtx','wkdnever',ColorToString(wkdnever));
           end;
end;

procedure TfrmMonWsjtx.EditAlertExit(Sender: TObject);
begin
      cqrini.WriteString('MonWsjtx','TextAlert',EditAlert.Text);
end;

procedure TfrmMonWsjtx.cmBandClick(Sender: TObject);
begin
       popColorDlg.Color:=wkdBand;
       popColorDlg.Title := 'Qso on this band, but not this mode - color';
       if  popColorDlg.Execute then
          Begin
           wkdBand := ( popColorDlg.Color );
           cqrini.WriteString('MonWsjtx','wkdband',ColorToString(wkdband));
          end;

end;
procedure TfrmMonWsjtx.cmAnyClick(Sender: TObject);
begin
       popColorDlg.Color:=wkdAny;
       popColorDlg.Title := 'Qso on some other band/mode - color';
       if  popColorDlg.Execute then
          Begin
           wkdAny := ( popColorDlg.Color );
           cqrini.WriteString('MonWsjtx','wkdany',ColorToString(wkdany));
          end;

end;

procedure TfrmMonWsjtx.cmHereClick(Sender: TObject);
begin
       popColorDlg.Color:=wkdHere;
       popColorDlg.Title := 'Qso on this band and mode - color';
       if  popColorDlg.Execute then
          Begin
           wkdHere := ( popColorDlg.Color );
           cqrini.WriteString('MonWsjtx','wkdhere',ColorToString(wkdhere));
          end;

end;
procedure TfrmMonWsjtx.chkHistoryChange(Sender: TObject);
begin
  cqrini.WriteBool('MonWsjtx','NoHistory',chkHistory.Checked);
end;

procedure TfrmMonWsjtx.noTxtChange(Sender: TObject);
begin
   cqrini.WriteBool('MonWsjtx','NoTxt',noTxt.Checked);
end;
procedure TfrmMonWsjtx.chkLocAlertChange(Sender: TObject);
begin
     cqrini.WriteBool('MonWsjtx','LocAlert',chkLocAlert.Checked);
end;

procedure TfrmMonWsjtx.chkmyAlertChange(Sender: TObject);
begin
     cqrini.WriteBool('MonWsjtx','MyAlert',chkmyAlert.Checked);
end;

procedure TfrmMonWsjtx.chkmyAllChange(Sender: TObject);
begin
     cqrini.WriteBool('MonWsjtx','MyAll',chkmyAll.Checked);
end;

procedure TfrmMonWsjtx.cmCqDxClick(Sender: TObject);
begin
       popColorDlg.Color:=extCqCall;
       popColorDlg.Title := 'Extended CQ (DX, NA, SA ...) - color';
       if  popColorDlg.Execute then
           extCqCall := ( popColorDlg.Color );
       cqrini.WriteString('MonWsjtx','extCqCall',ColorToString(extCqCall));
end;

procedure TfrmMonWsjtx.cmFontClick(Sender: TObject);
begin
    popFontDlg.Font.Name    := cqrini.ReadString('MonWsjtx','Font','Monospace');
    popFontDlg.Font.Size    := cqrini.ReadInteger('MonWsjtx','FontSize',10);
    popFontDlg.Title := 'Use monospace fonts, style is ignored';
    if popFontDlg.Execute then
    begin
      cqrini.WriteString('MonWsjtx','Font',popFontDlg.Font.Name);
      cqrini.WriteInteger('MonWsjtx','FontSize',popFontDlg.Font.Size);
      WsjtxMemo.Font.Name :=popFontDlg.Font.Name;
      WsjtxMemo.Font.Size :=popFontDlg.Font.Size;
      CleanWsjtxMemo;
    end
end;

procedure TfrmMonWsjtx.FormCreate(Sender: TObject);
begin
  EditAlert.Text := '';
  LastWsjtLineTime:='';
  end;

procedure TfrmMonWsjtx.FormHide(Sender: TObject);
begin
   dmUtils.SaveWindowPos(frmMonWsjtx);
   frmMonWsjtx.hide;
  end;

procedure TfrmMonWsjtx.FormShow(Sender: TObject);
begin
   chkHistory.Checked := cqrini.ReadBool('MonWsjtx','NoHistory',False);
   noTxt.Checked := cqrini.ReadBool('MonWsjtx','NoTxt',False);
   chkmyAlert.Checked := cqrini.ReadBool('MonWsjtx','MyAlert',False);
   chkmyAll.Checked := cqrini.ReadBool('MonWsjtx','MyAll',False);
   chkLocAlert.Checked:= cqrini.ReadBool('MonWsjtx','LocAlert',False);
   EditAlert.Text := cqrini.ReadString('MonWsjtx','TextAlert','');
   dmUtils.LoadWindowPos(frmMonWsjtx);
   dmUtils.LoadFontSettings(frmMonWsjtx);
   WsjtxMemo.Font.Name := cqrini.ReadString('MonWsjtx','Font','Monospace');
   WsjtxMemo.Font.Size := cqrini.ReadInteger('MonWsjtx','FontSize',10);
   wkdhere := StringToColor(cqrini.ReadString('MonWsjtx','wkdhere','clRed'));
   wkdband := StringToColor(cqrini.ReadString('MonWsjtx','wkdband','clFuchsia'));
   wkdany := StringToColor(cqrini.ReadString('MonWsjtx','wkdany','clMaroon'));
   wkdnever := StringToColor(cqrini.ReadString('MonWsjtx','wkdnever','clGreen'));
   extCqCall := StringToColor(cqrini.ReadString('MonWsjtx','extCqCall','$000055FF'));
   CleanWsjtxMemo;
end;

procedure TfrmMonWsjtx.NewBandMode(Band,Mode:string);

Begin
     lblBand.Caption := Band;
     lblMode.Caption := Mode;
     CleanWsjtxMemo;
end;
function TfrmMonWsjtx.NextElement(Message:string;var index:integer):String;
//detach next element from Message. Move index pointer, do not touch message string itself

begin
   Result:='';
    if Message<>'' then
           begin
            while (Message[index]=' ') and (index <= length(Message)) do inc(index);
               while (Message[index]<>' ') and (index <= length(Message)) do
               Begin
                 Result:=Result + Message[index];
                 inc(index);
               end;
             UpperCase(trim(Result));  //to be surely fixed
           end;

    if dmData.DebugLevel>=1 then Writeln('Result:',Result,' index of msg:',index);
end;

procedure TfrmMonWsjtx.AddDecodedMessage(Message,band,Reply:string);
const
  CountryLen = 15;     //length of printed country name in monitor
var
  msgTime,
  msgMode,
  msgCQ1,
  msgCQ2,
  msgCall,
  msgLoc,
  msgRes,
  mode,
  freq,
  CqDir: string;

  mycont, cont, country, waz, posun, itu, pfx,lat,long  : string;

  i, index   :integer;
  adif       :Word;

  CallCqDir,            //CQ caller calling directed call
  isMyCall,
  HasNum,
  HasChr     :Boolean;


Begin   //TfrmMonWsjtx.AddDecodedMessage

      {split message
       it can be:
       12:34 # CQ CA1LL AA11
       12:34 @ CQ DX CA1LL AA11
       1536  @ CQ NA RV3AMV      //or other continents/prefixes
       12:34 @ CQ CA1LL DX
      actual mode from decoded message. Can be jt9 or jt65, nothing else(at this point)

       Added.. may be also "mycall" something, but we count just those with proper locator.
       12:34 # MYCALL CA1LL AA11
       If "MyAlert"+"All" selected alerts/prints all lines beginning with mycall

       Fixed stupid cq handling "CQ 000 PA7ZZ JO22 !where?" decodes now ok.
      }
      mycont  := '';
      cont    := '';
      country := '';
      waz     := '';
      posun   := '';
      itu     := '';
      lat     := '';
      long    := '';

      myAlert:='';
      MonitorLine :='';
      CallCqDir:=false;
      CqDir := '';

      adif := dmDXCC.id_country( UpperCase(cqrini.ReadString('Station', 'Call', '')),'',Now(),pfx, mycont, country, WAZ, posun, ITU, lat, long);
      if dmData.DebugLevel>=1 then Writeln('Memo Lines count is now:',WsjtxMemo.lines.count);
      index := 1;

      if dmData.DebugLevel>=1 then Write('Time-');
      msgTime := NextElement(Message,index);

      if dmData.DebugLevel>=1 then Write('Mode-');
      msgMode := NextElement(Message,index);

      case msgMode of
      chr(36) : mode := 'JT4';
      '#'  : mode := 'JT65';
      '@'  : mode := 'JT9';
      '&'  : mode := 'MSK144';
      ':'  : mode := 'QRA64';
      chr(126): mode := 'FT8';

      else mode :='';
      end;

      if mode <>'' then //mode is clear; we can continue
        Begin
         if dmData.DebugLevel>=1 then Write('Cq1-'); //this is checked by newQSO to be MYCall or CQ
         msgCQ1 := NextElement(Message,index);
         //isMyCall :=  msgCQ1 = UpperCase(cqrini.ReadString('Station', 'Call', ''));
         isMyCall := pos(msgCQ1,UpperCase(cqrini.ReadString('Station', 'Call', ''))) > 0 ;
         if dmData.DebugLevel>=1 then Write('Cq2-');
         msgCQ2 := NextElement(Message,index);
         if length(msgCQ2)>2 then   // if longer than 2 may be call, otherwise is addition DX AS EU etc.
          Begin
            i:=0;
            HasNum:=false;
            HasChr:=false;
            repeat
            //while not ((msgCQ2[i]>='0') and (msgCQ2[i]<='9')) and (i <= length(msgCQ2)) do inc(i);
             begin
             inc(i);
             if ((msgCQ2[i]>='0') and (msgCQ2[i]<='9')) then HasNum:=true;
             if ((msgCQ2[i]>='A') and (msgCQ2[i]<='Z')) then HasChr:=true;
              if dmData.DebugLevel>=1 then Writeln('Count now:', i,' lenght is:',length(msgCQ2));
             end;
            until (i > length(msgCQ2)) or ( HasNum and HasChr );
          if (length(msgCQ2)> i)  then
               Begin //dropped before end  (has number+char) it may be real call
                msgCall := msgCQ2;
                if dmData.DebugLevel>=1 then Writeln('msgCQ2>2(lrs+num) is Call-','Result:',msgCall,' index of msg:',index);
               end
              else
               Begin //was shortie, so next must be call
                CallCqDir:=true;
                CqDir := msgCQ2;
                if dmData.DebugLevel>=1 then  Begin
                                               Writeln('CQ2 had no number+char.');
                                               Write('Call-');
                                              end;
                msgCall := NextElement(Message,index);
                end;
          end
         else   //length(msgCQ2)>2
          Begin
            CallCqDir:=true;
            CqDir := msgCQ2;
            if dmData.DebugLevel>=1 then  Begin
                                               Writeln('CQ2 length=<2.');
                                               Write('Call-');
                                          end;
            msgCall := NextElement(Message,index); //was shortie, so next must be call
          end;

         if dmData.DebugLevel>=1 then Writeln('DIR-CQ-call after CQ2:',CallCqDir);
         //so we should have time, mode and call by now. That reamains locator, if exists
         if dmData.DebugLevel>=1 then Write('Loc-');
         msgLoc := NextElement(Message,index);

         if msgLoc = 'DX' then
            Begin
              CallCqDir:=true; //old std. way to call DX
              CqDir := msgLoc;
            end;
         if dmData.DebugLevel>=1 then Writeln('DIR-CQ-call after old std DX:',CallCqDir);

         if length(msgLoc)<4 then   //no locator if less than 4,  may be "DX" or something
               msgLoc:='----';
         if length(msgLoc)=4 then
            if (not frmWorkedGrids.GridOK(msgLoc)) or (msgLoc = 'RR73') then //disble false used "RR73" being a loc
               msgLoc:='----';

         if dmData.DebugLevel>=1 then Writeln('LOCATOR IS:',msgLoc);
         if ( isMyCall and chkMyAlert.Checked and chkmyAll.Checked and (msgLoc='----') ) then msgLoc:='<!!>';//locator for "ALL-MY"

         if not ( (msgLoc='----') and isMyCall ) then //if mycall: line must have locator to print(I.E. Answer to my CQ)
         Begin                                        //and other combinations (CQs) will print, too

           if chkHistory.Checked and (msgTime <> LastWsjtLineTime) then CleanWsjtxMemo;
           LastWsjtLineTime := msgTime;
           RepArr[WsjtxMemo.lines.count] := Reply;  //corresponding reply string to array
           //start printing
           if dmData.DebugLevel>=1 then Writeln('Start adding richmemo lines');
           AddColorStr(msgTime,clDefault); //time
           AddColorStr('  '+msgMode+' ',clDefault); //mode

           if isMyCall then AddColorStr('=',wkdnever) else AddColorStr(' ',wkdnever);  //answer to me

                  case frmWorkedGrids.WkdCall(msgCall,band,mode) of
                   0  :  AddColorStr(PadRight(UpperCase(msgCall),9)+' ',wkdnever);
                   1  :  AddColorStr(PadRight(LowerCase(msgCall),9)+' ',wkdhere);
                   2  :  AddColorStr(PadRight(UpperCase(msgCall),9)+' ',wkdband);
                   3  :  AddColorStr(PadRight(UpperCase(msgCall),9)+' ',wkdany);
                   else
                     AddColorStr(PadRight(LowerCase(msgCall),9)+' ',clDefault);  //should not happen
                  end;

           if msgLoc='----' then
                  AddColorStr(msgLoc,clDefault) //no loc
              else
               Begin
                  case frmWorkedGrids.WkdGrid(msgLoc,band,mode)  of
                  //returns 0=not wkd
                  //        1=full grid this band and mode
                  //        2=full grid this band but NOT this mode
                  //        3=full grid any other band/mode
                  //        4=main grid this band and mode
                  //        5=main grid this band but NOT this mode
                  //        6=main grid any other band/mode
                   0  : Begin
                         AddColorStr(UpperCase(msgLoc),wkdnever); //not wkd
                         if chkLocAlert.Checked and (timeToAlert<>msgTime) then myAlert := 'loc';    //locator alert
                        end;
                   1  : AddColorStr(lowerCase(msgLoc),wkdhere); //grid wkd
                   2  : AddColorStr(UpperCase(msgLoc),wkdband); //grid wkd band
                   3  : AddColorStr(UpperCase(msgLoc),wkdany); //grid wkd any
                   4  : Begin
                         AddColorStr(lowerCase(copy(msgLoc,1,2)),wkdhere); //maingrid wkd
                         AddColorStr(copy(msgLoc,3,2),wkdnever);
                        end;
                   5  : Begin
                         AddColorStr(UpperCase(copy(msgLoc,1,2)),wkdband); //maingrid wkd band
                         AddColorStr(copy(msgLoc,3,2),wkdnever);
                        end;
                   6  : Begin
                         AddColorStr(UpperCase(copy(msgLoc,1,2)),wkdany); //maingrid wkd any
                         AddColorStr(copy(msgLoc,3,2),wkdnever);
                        end;
                   else
                     AddColorStr(lowerCase(msgLoc),clDefault); //should not happen
                  end;
               end;

           adif := dmDXCC.id_country(msgCall,'',Now(),pfx, cont, msgRes, WAZ, posun, ITU, lat, long);
           if (pos(',',msgRes)) > 0 then msgRes := copy (msgRes,1,pos(',',msgRes)-1);

           if dmData.DebugLevel>=1 then Writeln('My continent is:',mycont,'  His continent is:',cont);
           if CallCqDir then
             if ((mycont <>'') and (cont <> '')) then //we can do some comparisons of continents
              Begin
                   if ((CqDir = 'DX') and (mycont = cont)) then
                       //I'm not DX for caller: color to warn directed call
                      AddColorStr(' '+copy(PadRight('*'+msgRes,CountryLen),1,CountryLen)+' ',extCqCall)
                    else  //calling specified continent
                     if ((CqDir <> 'DX') and (CqDir <> mycont)) then
                      //CQ NOT directed to my continent: color to warn directed call
                      AddColorStr(' '+copy(PadRight('*'+msgRes,CountryLen),1,CountryLen)+' ',extCqCall)
                      else  // should be ok to answer this directed cq
                       AddColorStr(' '+copy(PadRight(msgRes,CountryLen),1,CountryLen)+' ',clBlack)
              end
             else
                // we can not compare continents, but it is directed cq. Best to warn with color anyway
                AddColorStr(' '+copy(PadRight('*'+msgRes,CountryLen),1,CountryLen)+' ',extCqCall)
           else
              // should be ok to answer this is not directed cq
              AddColorStr(' '+copy(PadRight(msgRes,CountryLen),1,CountryLen)+' ',clBlack);

           freq := dmUtils.FreqFromBand(band, mode);
           msgRes:= dmDXCC.DXCCInfo(adif,freq,mode,i);    //wkd info

           if dmData.DebugLevel>=1 then Writeln('Looking this>',msgRes[1],'< from:',msgRes);
           case msgRes[1] of
             'U'  :  AddColorStr(msgRes,wkdhere);       //Unknown
             'C'  :  AddColorStr(msgRes,wkdAny);        //Confirmed
             'Q'  :  AddColorStr(msgRes,clTeal);        //Qsl needed
             'N'  :  AddColorStr(msgRes,wkdnever);      //New something

            else    AddColorStr(msgRes,clDefault);     //something else...can't be
           end;

           AddColorStr(#13#10,clDefault);  //make new line
           WsjtxMemoScroll; // if neeeded

           if ((trim(EditAlert.Text) <>'') and (pos(trim(EditAlert.Text),MonitorLine) > 0 )) then  myAlert := 'text'; // overrides locator
           if ( chkMyAlert.Checked and isMyCall ) then myAlert :='my'; //overrides anything else

           if (myAlert <>'') and (timeToAlert<>msgTime) then
              Begin
                timeToAlert := msgTime;
                RunVA(myAlert); //play bash script
              end;

         end;//printing out  line
        end;  //continued
end;



initialization

end.

