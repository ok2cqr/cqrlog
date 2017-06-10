unit fMonWsjtx;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, maskedit, RichMemo, strutils,  process;

type

  { TfrmMonWsjtx }

  TfrmMonWsjtx = class(TForm)
    chkHistory: TCheckBox;
    chkmyAlert: TCheckBox;
    chkLocAlert: TCheckBox;
    EditAlert: TEdit;
    lblAlert1: TLabel;
    lblAlert2: TLabel;
    lblBand: TLabel;
    lblMode: TLabel;
    WsjtxMemo: TRichMemo;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure WsjtxMemoChange(Sender: TObject);
    procedure WsjtxMemoDblClick(Sender: TObject);
  private
    procedure FocusLastLine;
    procedure AddColorStr(s: string; const col: TColor = clBlack);
    procedure RunVA(Afile: String);
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

     with WsjtxMemo do
     begin
       //if dmData.DebugLevel>=1 then Writeln('LineCount-start:',Lines.Count,' String:',s);

       if s <> '' then
       begin
         SelStart  := Length(Text);
         SelText   := s;
         SelLength := Length(s);
         SetRangeColor(SelStart, SelLength, col);
         // deselect inserted string and position cursor at the end of the text
         SelStart  := Length(Text);
         SelText   := '';
       end;

       FocusLastLine;
       //if dmData.DebugLevel>=1 then Writeln('LineCount-end :',Lines.Count,' String:',s);

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

procedure TfrmMonWsjtx.WsjtxMemoChange(Sender: TObject);
var i: integer;
begin
  //scroll buffer
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
begin
   cqrini.WriteBool('MonWsjtx','NoHistory',chkHistory.Checked);
   cqrini.WriteBool('MonWsjtx','MyAlert',chkmyAlert.Checked);
   cqrini.WriteBool('MonWsjtx','LocAlert',chkLocAlert.Checked);
   cqrini.WriteString('MonWsjtx','TextAlert',EditAlert.Text);
   dmUtils.SaveWindowPos(frmMonWsjtx);
   frmNewQSO.DisableRemoteMode;
end;

procedure TfrmMonWsjtx.FormCreate(Sender: TObject);
begin
  EditAlert.Text := '';
  LastWsjtLineTime:='';
  dmUtils.LoadWindowPos(frmMonWsjtx);
end;

procedure TfrmMonWsjtx.FormHide(Sender: TObject);
begin
   dmUtils.SaveWindowPos(frmMonWsjtx);
   frmMonWsjtx.hide;
end;

procedure TfrmMonWsjtx.FormShow(Sender: TObject);
begin
   chkHistory.Checked := cqrini.ReadBool('MonWsjtx','NoHistory',False);
   chkmyAlert.Checked := cqrini.ReadBool('MonWsjtx','MyAlert',False);
   chkLocAlert.Checked:= cqrini.ReadBool('MonWsjtx','LocAlert',False);
   EditAlert.Text := cqrini.ReadString('MonWsjtx','TextAlert','');
   dmUtils.LoadWindowPos(frmMonWsjtx);
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
var
  msgTime,
  msgMode,
  msgCQ1,
  msgCQ2,
  msgCall,
  msgLoc,
  msgRes,
  mode,
  freq: string;
  i,
  index      :integer;
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

       Fixed stupid cq handling "CQ 000 PA7ZZ JO22 !where?" decodes now ok.
      }

      myAlert:='';
      MonitorLine :='';
      CallCqDir:=false;

      if dmData.DebugLevel>=1 then Writeln('Memo Lines count is now:',WsjtxMemo.lines.count);
      index := 1;

      if dmData.DebugLevel>=1 then Write('Time-');
      msgTime := NextElement(Message,index);

      if dmData.DebugLevel>=1 then Write('Mode-');
      msgMode := NextElement(Message,index);

      case msgMode of
      '#'  : mode := 'JT65';
      '@'  : mode := 'JT9';
      '&'  : mode := 'MSK144';
      else mode :='';
      end;

      if mode <>'' then //mode is clear; we can continue
        Begin
         if dmData.DebugLevel>=1 then Write('Cq1-'); //this is checked by newQSO to be MYCall or CQ
         msgCQ1 := NextElement(Message,index);
         isMyCall :=  msgCQ1 = UpperCase(cqrini.ReadString('Station', 'Call', ''));
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

         if msgLoc = 'DX' then CallCqDir:=true; //old std. way to call DX
         if dmData.DebugLevel>=1 then Writeln('DIR-CQ-call after old std DX',CallCqDir);

         if length(msgLoc)<4 then   //no locator if less than 4,  may be "DX" or something
               msgLoc:='----';
         if length(msgLoc)=4 then
            if (not frmWorkedGrids.GridOK(msgLoc)) or (msgLoc = 'RR73') then //disble false used "RR73" being a loc
               msgLoc:='----';

         if not ( (msgLoc='----') and isMyCall ) then //if mycall: line must have locator to print(I.E. Answer to my CQ)
         Begin                                        //and other combinations (CQs) will print, too
           if chkHistory.Checked and (msgTime <> LastWsjtLineTime) then CleanWsjtxMemo;
           LastWsjtLineTime := msgTime;
           RepArr[WsjtxMemo.lines.count] := Reply;  //corresponding reply string to array
           //start printing
           AddColorStr(msgTime,clDefault); //time
           if mode='JT65' then
               AddColorStr('  '+msgMode+' ',clOlive) //mode
            else
               AddColorStr('  '+msgMode+' ',clPurple);
           if isMyCall then AddColorStr('=',clGreen) else AddColorStr(' ',clGreen);  //answer to me
           if frmWorkedGrids.WkdCall(msgCall,band,mode) then
                   AddColorStr(PadRight(LowerCase(msgCall),9)+' ',clRed)
               else
                   AddColorStr(PadRight(UpperCase(msgCall),9)+' ',clGreen);
           if msgLoc='----' then
                  AddColorStr(msgLoc,clDefault) //no loc
              else
               Begin
                  i:= frmWorkedGrids.WkdGrid(msgLoc,band,mode);
                  case i of
                   0  : Begin
                             AddColorStr(UpperCase(msgLoc),clGreen); //not wkd
                             if chkLocAlert.Checked and (timeToAlert<>msgTime) then myAlert := 'loc';    //locator alert

                        end;
                   1  : Begin
                         AddColorStr(lowerCase(copy(msgLoc,1,2)),clRed); //maingrid wkd
                         AddColorStr(lowerCase(copy(msgLoc,3,2)),clGreen);
                        end;
                   2  : AddColorStr(lowerCase(msgLoc),clRed); //grid wkd
                   end;
               end;


           msgRes := dmDXCC.id_country(msgCall,now());    //country prefix
           if CallCqDir then
                 AddColorStr(' '+PadRight('*'+msgRes,7)+' ',clFuchsia)    //to warn directed call
             else
                 AddColorStr(' '+PadRight(msgRes,7)+' ',clBlack);


           adif :=  dmDXCC.AdifFromPfx(msgRes);
           freq := dmUtils.FreqFromBand(band, mode);
           msgRes:= dmDXCC.DXCCInfo(adif,freq,mode,i);    //wkd info

           if dmData.DebugLevel>=1 then Writeln('Looking this>',msgRes[1],'< from:',msgRes);
           case msgRes[1] of
             'U'  :  AddColorStr(msgRes,clRed);        //Unknown
             'C'  :  AddColorStr(msgRes,clFuchsia);    //Confirmed
             'Q'  :  AddColorStr(msgRes,clTeal);       //Qsl needed
             'N'  :  AddColorStr(msgRes,clGreen);      //New something

            else    AddColorStr(msgRes,clDefault);     //something else...can't be
           end;

           AddColorStr(#13#10,clDefault);  //make new line

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

