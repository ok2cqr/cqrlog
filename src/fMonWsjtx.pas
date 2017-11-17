unit fMonWsjtx;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, maskedit, ColorBox, Menus, ExtCtrls, RichMemo, strutils, process;

type

  { TfrmMonWsjtx }

  TfrmMonWsjtx = class(TForm)
    cbflw: TCheckBox;
    EditAlert: TEdit;
    edtFollow: TEdit;
    edtFollowCall: TEdit;
    pnlFollow: TPanel;
    pnlAlert: TPanel;
    tbAlert: TToggleBox;
    noTxt: TCheckBox;
    chkHistory: TCheckBox;
    cmCqDx: TMenuItem;
    cmFont: TMenuItem;
    popFontDlg: TFontDialog;
    popColorDlg: TColorDialog;
    lblBand: TLabel;
    lblMode: TLabel;
    cmHead: TMenuItem;
    cmNever: TMenuItem;
    cmBand: TMenuItem;
    cmAny: TMenuItem;
    cmHere: TMenuItem;
    popColors: TPopupMenu;
    tbLocAlert: TToggleBox;
    tbmyAll: TToggleBox;
    tbmyAlrt: TToggleBox;
    tbFollow: TToggleBox;
    tbTCAlert: TToggleBox;
    tmrFollow: TTimer;
    WsjtxMemo: TRichMemo;
    procedure cbflwChange(Sender: TObject);
    procedure chkHistoryChange(Sender: TObject);
    procedure cmAnyClick(Sender: TObject);
    procedure cmBandClick(Sender: TObject);
    procedure cmCqDxClick(Sender: TObject);
    procedure cmFontClick(Sender: TObject);
    procedure cmHereClick(Sender: TObject);
    procedure cmNeverClick(Sender: TObject);
    procedure EditAlertEnter(Sender: TObject);
    procedure EditAlertExit(Sender: TObject);
    procedure edtFollowCallEnter(Sender: TObject);
    procedure edtFollowCallExit(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure noTxtChange(Sender: TObject);
    procedure tbAlertChange(Sender: TObject);
    procedure tbFollowChange(Sender: TObject);
    procedure tbLocAlertChange(Sender: TObject);
    procedure tbmyAllChange(Sender: TObject);
    procedure tbmyAlrtChange(Sender: TObject);
    procedure tbTCAlertChange(Sender: TObject);
    procedure tmrFollowTimer(Sender: TObject);
    procedure WsjtxMemoChange(Sender: TObject);
    procedure WsjtxMemoDblClick(Sender: TObject);
  private
    procedure FocusLastLine;
    procedure AddColorStr(s: string; const col: TColor = clBlack);
    procedure RunVA(Afile: String);
    procedure WsjtxMemoScroll;
    procedure decodetest(i:boolean);
   { private declarations }
  public
    procedure CleanWsjtxMemo;
    function NextElement(Message:string;var index:integer):String;
    procedure AddDecodedMessage(Message,Band,Reply:string);
    procedure AddFollowedMessage(Message,Reply:string);
    procedure NewBandMode(Band,Mode:string);
    { public declarations }
  end;
Const
MaxLines :integer = 21;        //Max monitor lines text will show MaxLines-1 lines
type
  TReplyArray     = array of string [255];

var
  frmMonWsjtx: TfrmMonWsjtx;
  RepArr     : TReplyArray;  //static array for reply strings: set max same as MaxLines
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
  EditedText         : string;                  //holds editAlert after finished (loose focus)
  Ssearch,Sfull      : String;
  Spos               : integer;
  Sdelim             : char = ',';

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
     for l:=0 to Maxlines-1 do RepArr[l]:='';
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
 with WsjtxMemo do
 begin
  //scroll buffer if needed
  if lines.count >= MaxLines then
         Begin
          repeat
            lines.delete(0);
            for i:=0 to MaxLines-2 do RepArr[i] := RepArr[i+1];
          until lines.count <= Maxlines;
          RepArr[MaxLines-1] := '';
          FocusLastLine;
         end;
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
begin
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

procedure TfrmMonWsjtx.EditAlertEnter(Sender: TObject);
begin
  tbAlert.Checked := false;
end;

procedure TfrmMonWsjtx.EditAlertExit(Sender: TObject);
begin
      cqrini.WriteString('MonWsjtx','TextAlert',EditAlert.Text);
      cqrini.WriteBool('MonWsjtx','Follow',tbFollow.Checked);
      EditAlert.Text := trim(EditAlert.Text);
      EditedText := EditAlert.Text;
end;

procedure TfrmMonWsjtx.edtFollowCallEnter(Sender: TObject);
begin
  tbFollow.Checked := false;
end;

procedure TfrmMonWsjtx.edtFollowCallExit(Sender: TObject);
begin
  edtFollowCall.Text := trim(UpperCase(edtFollowCall.Text));   //sure upcase-trimmed
  cqrini.WriteString('MonWsjtx','FollowCall',edtFollowCall.Text);
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

procedure TfrmMonWsjtx.cbflwChange(Sender: TObject);
begin
  cqrini.WriteBool('MonWsjtx','FollowShow',cbflw.Checked);
  if cbflw.Checked then
  begin
     WsjtxMemo.BorderSpacing.Bottom:=96;
     pnlFollow.Visible:=true;
     edtFollow.Text :='';;
  end
  else
  begin
     tbFollow.Checked:=false;
     WsjtxMemo.BorderSpacing.Bottom:=51;
     pnlFollow.Visible:=false;
  end;
end;

procedure TfrmMonWsjtx.noTxtChange(Sender: TObject);
begin
   cqrini.WriteBool('MonWsjtx','NoTxt',noTxt.Checked);
end;

procedure TfrmMonWsjtx.tbAlertChange(Sender: TObject);
begin
  cqrini.WriteBool('MonWsjtx','TextAlertSet',tbAlert.Checked);
  if tbAlert.Checked then
   Begin
     tbAlert.Font.Color := clGreen;
     tbAlert.Font.Style := [fsBold];
     if tbTCAlert.Checked then
        Begin
          EditAlert.Text := trim(UpperCase(EditAlert.Text));
          EditedText := EditAlert.Text;
        end
   end
    else
     begin
       tbAlert.Font.Color := clRed;
       tbAlert.Font.Style := [];
     end;
end;

procedure TfrmMonWsjtx.tbFollowChange(Sender: TObject);
begin
  cqrini.WriteBool('MonWsjtx','Follow',tbFollow.Checked);
  if tbFollow.Checked then
  begin
      tbFollow.Font.Color := clGreen;
      tbFollow.Font.Style := [fsBold];
      end
   else
    begin
      tbFollow.Font.Color := clRed;
      tbFollow.Font.Style := [];
      edtFollow.Text :='';
    end;
end;

procedure TfrmMonWsjtx.tbLocAlertChange(Sender: TObject);
begin
   cqrini.WriteBool('MonWsjtx','LocAlert',tbLocAlert.Checked);
   if tbLocAlert.Checked then
    begin
      tbLocAlert.Font.Color := clGreen;
      tbLocAlert.Font.Style := [fsBold];
      end
   else
    begin
      tbLocAlert.Font.Color := clRed;
      tbLocAlert.Font.Style := [];
    end;
end;

procedure TfrmMonWsjtx.tbmyAllChange(Sender: TObject);
begin
  cqrini.WriteBool('MonWsjtx','MyAll',tbmyAll.Checked);
  if tbmyAll.Checked then
  begin
      tbmyAll.Font.Color := clGreen;
      tbmyAll.Font.Style := [fsBold];
      end
   else
    begin
      tbmyAll.Font.Color := clRed;
      tbmyAll.Font.Style := [];
    end;
end;

procedure TfrmMonWsjtx.tbmyAlrtChange(Sender: TObject);
begin
     cqrini.WriteBool('MonWsjtx','MyAlert',tbmyAlrt.Checked);
  if tbmyAlrt.Checked then
  begin
      tbmyAlrt.Font.Color := clGreen;
      tbmyAlrt.Font.Style := [fsBold];
      end
   else
    begin
      tbmyAlrt.Font.Color := clRed;
      tbmyAlrt.Font.Style := [];
    end;
end;

procedure TfrmMonWsjtx.tbTCAlertChange(Sender: TObject);
begin
  cqrini.WriteBool('MonWsjtx','TextAlertCall',tbTCAlert.Checked);
  tbAlert.Checked :=false;   //drop alert off if text/call change
   if tbTCAlert.Checked then
   Begin
     tbTCAlert.SetTextBuf('Call');
     EditAlert.Text := trim(UpperCase(EditAlert.Text));   //sure upcase-trimmed
     EditedText := EditAlert.Text;
   end  else
    begin
      tbTCAlert.SetTextBuf('Text');
    end;
end;

procedure TfrmMonWsjtx.tmrFollowTimer(Sender: TObject);
begin
   tmrFollow.Enabled := false;
   edtFollow.Font.Color := clRed;
end;

procedure TfrmMonWsjtx.WsjtxMemoChange(Sender: TObject);
begin

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
      edtFollow.Font.Name :=popFontDlg.Font.Name;
      edtFollow.Font.Size :=popFontDlg.Font.Size;
      CleanWsjtxMemo;
      edtFollow.Text:='';
    end
end;

procedure TfrmMonWsjtx.FormCreate(Sender: TObject);
begin
  SetLength(RepArr, MaxLines); //set reply buffer to maxlines
  EditAlert.Text := '';
  EditedText := '';
  LastWsjtLineTime:='';
  end;

procedure TfrmMonWsjtx.FormHide(Sender: TObject);
begin
   //decodetest(true);  //release these for decode tests
   //decodetest(false);
   dmUtils.SaveWindowPos(frmMonWsjtx);
   frmMonWsjtx.hide;
  end;

procedure TfrmMonWsjtx.FormShow(Sender: TObject);
begin
   chkHistory.Checked := cqrini.ReadBool('MonWsjtx','NoHistory',False);
   noTxt.Checked := cqrini.ReadBool('MonWsjtx','NoTxt',False);
   tbmyAlrt.Checked := cqrini.ReadBool('MonWsjtx','MyAlert',False);
   tbmyAll.Checked := cqrini.ReadBool('MonWsjtx','MyAll',False);
   tbLocAlert.Checked:= cqrini.ReadBool('MonWsjtx','LocAlert',False);
   EditAlert.Text := cqrini.ReadString('MonWsjtx','TextAlert','');
   EditedText :=  EditAlert.Text;
   tbAlert.Checked := cqrini.ReadBool('MonWsjtx','TextAlertSet',False);
   tbTCAlert.Checked := cqrini.ReadBool('MonWsjtx','TextAlertCall',False);
   dmUtils.LoadWindowPos(frmMonWsjtx);
   dmUtils.LoadFontSettings(frmMonWsjtx);
   WsjtxMemo.Font.Name := cqrini.ReadString('MonWsjtx','Font','Monospace');
   WsjtxMemo.Font.Size := cqrini.ReadInteger('MonWsjtx','FontSize',10);
   wkdhere := StringToColor(cqrini.ReadString('MonWsjtx','wkdhere','clRed'));
   wkdband := StringToColor(cqrini.ReadString('MonWsjtx','wkdband','clFuchsia'));
   wkdany := StringToColor(cqrini.ReadString('MonWsjtx','wkdany','clMaroon'));
   wkdnever := StringToColor(cqrini.ReadString('MonWsjtx','wkdnever','clGreen'));
   extCqCall := StringToColor(cqrini.ReadString('MonWsjtx','extCqCall','$000055FF'));
   edtFollow.Font.Name :=WsjtxMemo.Font.Name ;
   edtFollow.Font.Size :=WsjtxMemo.Font.Size;
   cbflw.Checked := cqrini.ReadBool('MonWsjtx','FollowShow',False);
   tbFollow.Checked := cqrini.ReadBool('MonWsjtx','Follow',False);
   edtFollowCall.Text := uppercase( cqrini.ReadString('MonWsjtx','FollowCall',''));

   CleanWsjtxMemo;
   if ((trim(edtFollowCall.Text) = '') and tbFollow.Checked ) then tbFollow.Checked := false; //should not happen, chk it here

end;

procedure TfrmMonWsjtx.NewBandMode(Band,Mode:string);

Begin
     lblBand.Caption := Band;
     lblMode.Caption := Mode;
     CleanWsjtxMemo;
     edtFollow.Text := '';
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
//-----------------------------------------------------------------------------------------
procedure TfrmMonWsjtx.decodetest(i:boolean);           // run execptions for debug
Begin
       //split message it can be: (note: when testing remember continent compare set calls to be non dx]
    if (i) then
     Begin
       AddDecodedMessage('175200 # CQ OH1LL KP11','20M','reply');      //normal cq
       AddDecodedMessage('175200 @ CQ DX OH1DX KP11','20M','reply');   //directed cq
       AddDecodedMessage('175200 @ CQ NA RV3NA','20M','reply');      //call and continents/prefixes  no loc
       AddDecodedMessage('175200 @ CQ USA RV3USA','20M','reply');      //call and continents/prefixes
       AddDecodedMessage('175200 @ CQ USA RV3USL KO30','20M','reply');      //call and continents/prefixes
       AddDecodedMessage('175200 @ CQ OH1LL DX','20M','reply');         //old official cq dx
       AddDecodedMessage('175200 # OF1KH CA1LL AA11','20M','reply');     //set first you log call
       AddDecodedMessage('175200 # CQ 000 PA7ZZ JO22','20M','reply'); //!where?" decodes now ok.
       AddDecodedMessage('175200 ~ CQ NO EU RZ3DX','20M','reply');  // for dbg
       AddDecodedMessage('201045 ~ CQ KAZAKHSTAN','20M','reply'); // yet another bright cq idea of users
       AddDecodedMessage('201045 ~ CQ WHO EVER' ,'20M','reply'); // a guess for next idea
     end
    else
      Begin
       ShowMessage('Test with CQ extensions:'+sLineBreak+
       '175200 # CQ OH1LL KP11'+sLineBreak+
       '175200 @ CQ DX OH1DX KP11'+sLineBreak+
       '175200 @ CQ NA RV3NA'+sLineBreak+
       '175200 @ CQ USA RV3USA'+sLineBreak+
       '175200 @ CQ USA RV3USL KO30'+sLineBreak+
       '175200 @ CQ OH1LL DX'+sLineBreak+
       '175200 # OF1KH CA1LL AA11'+sLineBreak+
       '175200 # CQ 000 PA7ZZ JO22'+sLineBreak+
       '175200 ~ CQ NO EU RZ3DX'+sLineBreak+
       '201045 ~ CQ KAZAKHSTAN'+sLineBreak+
       '201045 ~ CQ WHO EVER');  // for dbg
     end;
end;
procedure TfrmMonWsjtx.AddFollowedMessage(Message,Reply:string);
Begin
  if dmData.DebugLevel>=1 then Writeln('Follow line:',Message);
  tmrFollow.Enabled:=false;
  edtFollow.Font.Color := clDefault;
  edtFollow.Text := Message;
  if ((lblMode.Caption ='FT8') or (lblMode.Caption ='MSK144')) then
    tmrFollow.Interval:= 15000
   else
    tmrFollow.Interval:= 60000;
  tmrFollow.Enabled:=true;
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

  i,index   :integer;
  adif       :Word;

  CallCqDir,            //CQ caller calling directed call
  isMyCall    :Boolean;
  HasNum,
  HasChr     :Boolean;


//-----------------------------------------------------------------------------------------
function OkCall(Call:String):boolean ;        //this is used 2 times below
var
  HasNum,
  HasChr     :Boolean;
Begin
            i:=0;
            HasNum:=false;
            HasChr:=false;
            if (Call<>'') then
            begin
             repeat
              begin
               inc(i);
               if ((Call[i]>='0') and (Call[i]<='9')) then HasNum:=true;
               if ((Call[i]>='A') and (Call[i]<='Z')) then HasChr:=true;
               if dmData.DebugLevel>=1 then Writeln('CHR Count now:', i,' len,num,chr:',length(Call),',',HasNum,',',HasChr);
              end;
             until (i >= length(Call));
            end;
     OkCall :=  HasNum and HasChr and (i > 2);
     if dmData.DebugLevel>=1 then Writeln('Call ',call,' valid: ',OkCall);
end;
//-----------------------------------------------------------------------------------------
procedure extcqprint;  //this is used 3 times below
begin
 AddColorStr(' '+copy(PadRight(msgRes,CountryLen),1,CountryLen-6),extCqCall);
 AddColorStr(' CQ:',clBlack);
 AddColorStr(CqDir+' ',extCqCall);
end;

//-----------------------------------------------------------------------------------------
procedure TryCallAlert(S:string);      //this is used 2 times below

Begin
  //if no asterisk, compare as is
   if ( (pos('*',S) = 0 ) and (pos(S,msgCALL) > 0 ) )then
     Begin
      if dmData.DebugLevel>=1 then Write('Text-',S,'-');
      myAlert := 'call'; // overrides locator
     end
   else
   Begin     //has asterisk
  //if starts with asterisk remove it and compare right side
   if (LeftStr(S,1)  = '*') then
    Begin
      if dmData.DebugLevel>=1 then Write('Right-',S,'-');
      S := copy(S,2,length(S)-1);         //asterisk removed, then compare
      if  (S = RightStr(msgCall,(length(S)))) then myAlert := 'call'; // overrides locator
    end
    else
     Begin
     //if ends with asterisk remove it and compare left side
      if (RightStr(S,1) = '*' ) then
      S:= copy(S,1, length(S)-1);  //asterisk removed, then compare
      if (S = LeftStr(msgCall,length(S))) then myAlert := 'call'; // overrides locator
      if dmData.DebugLevel>=1 then Write('Left-',S,'-');
     end;
    end;
   if dmData.DebugLevel>=1 then Writeln('compare with:',S,':results:',myAlert);
end;

//-----------------------------------------------------------------------------------------
Begin   //TfrmMonWsjtx.AddDecodedMessage


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
         isMyCall := pos(msgCQ1,UpperCase(cqrini.ReadString('Station', 'Call', ''))) > 0 ;
         if dmData.DebugLevel>=1 then Write('Cq2-');
         msgCQ2 := NextElement(Message,index);
         if length(msgCQ2)>2 then   // if longer than 2 may be call, otherwise is addition DX AS EU etc.
          Begin
          if (OkCall(msgCQ2))  then
               Begin // it may be real call
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
                //!! if sill no call
                if  not (OkCall(msgCall)) then  msgCall := NextElement(Message,index);
                end;
          end
         else   //length(msgCQ2)<2
          Begin
            CallCqDir:=true;
            CqDir := msgCQ2;
            if dmData.DebugLevel>=1 then  Begin
                                               Writeln('CQ2 length=<2.');
                                               Write('Call-');
                                          end;
            msgCall := NextElement(Message,index); //was shortie, so next must be call
            //!! if sill no call
            if  not (OkCall(msgCall)) then  msgCall := NextElement(Message,index);
          end;

         //how ever if we do not have callsign because some crazy cq calling way
         if (msgCall='') then msgCall:='NOCALL';

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

         if ((length(msgLoc)<4) or (length(msgLoc)>4)) then   //no locator; different than 4,  may be "DX" or something
               msgLoc:='----';
         if length(msgLoc)=4 then
            if (not frmWorkedGrids.GridOK(msgLoc)) or (msgLoc = 'RR73') then //disble false used "RR73" being a loc
               msgLoc:='----';

         if dmData.DebugLevel>=1 then Writeln('LOCATOR IS:',msgLoc);
         if ( isMyCall and tbmyAlrt.Checked and tbmyAll.Checked and (msgLoc='----') ) then msgLoc:='<!!>';//locator for "ALL-MY"

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
                         if tbLocAlert.Checked and (timeToAlert<>msgTime) then myAlert := 'loc';    //locator alert
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
                     begin
                       //I'm not DX for caller: color to warn directed call
                        extcqprint;
                     end
                    else  //calling specified continent
                     if ((CqDir <> 'DX') and (CqDir <> mycont)) then
                      begin
                        //CQ NOT directed to my continent: color to warn directed call
                        extcqprint;
                        end
                      else  // should be ok to answer this directed cq
                       AddColorStr(' '+copy(PadRight(msgRes,CountryLen),1,CountryLen)+' ',clBlack)
              end
             else
                begin
                  // we can not compare continents, but it is directed cq. Best to warn with color anyway
                  extcqprint;
                end
           else
              // should be ok to answer this is not directed cq
              AddColorStr(' '+copy(PadRight(msgRes,CountryLen),1,CountryLen)+' ',clBlack);

           freq := dmUtils.FreqFromBand(band, mode);
           msgRes:= dmDXCC.DXCCInfo(adif,freq,mode,i);    //wkd info

           if dmData.DebugLevel>=1 then Writeln('Looking this>',msgRes[1],'< from:',msgRes);
           case msgRes[1] of
             'U'  :  AddColorStr(cont+':'+msgRes,wkdhere);       //Unknown
             'C'  :  AddColorStr(cont+':'+msgRes,wkdAny);        //Confirmed
             'Q'  :  AddColorStr(cont+':'+msgRes,clTeal);        //Qsl needed
             'N'  :  AddColorStr(cont+':'+msgRes,wkdnever);      //New something

            else    AddColorStr(msgRes,clDefault);     //something else...can't be
           end;

           AddColorStr(#13#10,clDefault);  //make new line
           WsjtxMemoScroll; // if neeeded

           if tbAlert.Checked then
           begin
           if tbTCAlert.Checked then
              begin
                if (EditedText <>'') then
                 begin
                     Sfull := EditedText;
                     Spos := pos(Sdelim,Sfull);       //delimiter for several search variants
                     if (Spos > 0) then //many variants
                      repeat
                        begin
                          if (Spos > 0 ) then Ssearch := copy(Sfull,1,Spos-1) else Ssearch := Sfull;
                          Ssearch := trim(Ssearch);
                          if dmData.DebugLevel>=1 then Writeln('Split text search >',Sfull,'[',Spos,']=',Ssearch);
                          TryCallAlert(Ssearch);
                          if (Spos > 0 ) then Sfull := copy(Sfull,Spos+1,length(Sfull)-1) else Sfull:='';
                          Spos := pos(Sdelim,Sfull);
                         end
                       until  ((Spos = 0 ) and (Sfull = ''))
                     else  TryCallAlert(EditedText);
                end;
              end
             else if ( (EditedText <>'') and (pos(EditedText,MonitorLine) > 0 )) then  myAlert := 'text'; // overrides locator
           end; // tbAlert
           if ( tbmyAlrt.Checked and isMyCall ) then myAlert :='my'; //overrides anything else

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

