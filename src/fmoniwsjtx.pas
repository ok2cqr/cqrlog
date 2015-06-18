unit fMoniWsjtx;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, RichMemo, strutils;

type

  { TfrmMonWsjtx }

  TfrmMonWsjtx = class(TForm)
    chkHistory: TCheckBox;
    lblBand: TLabel;
    lblMode: TLabel;
    WsjtxMemo: TRichMemo;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure WsjtxMemoChange(Sender: TObject);
    procedure WsjtxMemoDblClick(Sender: TObject);
  private
    procedure FocusLastLine;
    procedure AddColorStr(s: string; const col: TColor = clBlack);
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

implementation

{ TfrmMonWsjtx }

Uses fNewQSO,dData,dUtils,dDXCC,fWkd1,uMyini;


procedure TfrmMonWsjtx.AddColorStr(s: string; const col: TColor = clBlack);
   begin
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
   dmUtils.SaveWindowPos(frmMonWsjtx);
   frmMonWsjtx.hide;
end;

procedure TfrmMonWsjtx.FormCreate(Sender: TObject);
begin
  //SetLength(RepArr,MaxLines);
  LastWsjtLineTime:='';
end;

procedure TfrmMonWsjtx.FormShow(Sender: TObject);
begin
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
  freq :string;
  i,
  index      :integer;
  adif       :Word;
  isMyCall   :Boolean;


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
      }
      if dmData.DebugLevel>=1 then Writeln('Memo Lines count is now:',WsjtxMemo.lines.count); index := 1;

      if dmData.DebugLevel>=1 then Write('Time-');
      msgTime := NextElement(Message,index);

      if dmData.DebugLevel>=1 then Write('Mode-');
      msgMode := NextElement(Message,index);

      case msgMode of
      '#'  : mode := 'JT65';
      '@'  : mode := 'JT9';
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
            i:=1;
            while not ((msgCQ2[i]>='0') and (msgCQ2[i]<='9')) and (i <= length(msgCQ2)) do inc(i);
            if (length(msgCQ2)> i)  then
               Begin //while dropped before end  (has number) may be real call
                msgCall := msgCQ2;
                if dmData.DebugLevel>=1 then Writeln('msgCQ2>2(lrs+num) is Call-','Result:',msgCall,' index of msg:',index);
               end;
          end
         else
          Begin //was shortie, so next must be call
            if dmData.DebugLevel>=1 then Write('CQ2 was letters=<2. Call-');
                msgCall := NextElement(Message,index);
          end;
         //so we should have time, mode and call by now. That reamains locator, if exists
         if dmData.DebugLevel>=1 then Write('Loc-');
         msgLoc := NextElement(Message,index);
         if length(msgLoc)<4 then   //no locator if less than 4,  may be "DX" or something
               msgLoc:='----';
         if length(msgLoc)=4 then
            if not frmWorked_grids.GridOK(msgLoc) then
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
           if isMyCall then AddColorStr('=',clGreen) else AddColorStr(' ',clGreen);
           if frmWorked_grids.WkdCall(msgCall,band,mode) then
                   AddColorStr(PadRight(LowerCase(msgCall),9)+' ',clRed)
               else
                   AddColorStr(PadRight(UpperCase(msgCall),9)+' ',clGreen);
           if msgLoc='----' then
                  AddColorStr(msgLoc,clDefault) //no loc
              else
               Begin
                  i:=frmWorked_grids.WkdGrid(msgLoc,band,mode);
                  case i of
                   0  : AddColorStr(UpperCase(msgLoc),clGreen); //not wkd
                   1  : Begin
                         AddColorStr(lowerCase(copy(msgLoc,1,2)),clRed); //maingrid wkd
                         AddColorStr(lowerCase(copy(msgLoc,3,2)),clGreen);
                        end;
                   2  : AddColorStr(lowerCase(msgLoc),clRed); //grid wkd
                   end;
               end;
           msgRes := dmDXCC.id_country(msgCall,now());    //country prefix
           AddColorStr(' '+PadRight(msgRes,7)+' ',clDefault);
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
           end;//printing out  line
        end;  //continued
end;



initialization
  {$I fMoniWsjtx.lrs}

end.

