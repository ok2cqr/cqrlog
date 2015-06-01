unit fMoniWsjtx;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, RichMemo, strutils;

type

  { TfrmMonWsjtx }

  TfrmMonWsjtx = class(TForm)
    lblBand: TLabel;
    lblMode: TLabel;
    WsjtxMemo: TRichMemo;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure WsjtxMemoChange(Sender: TObject);
  private
    procedure FocusLastLine;
    procedure AddColorStr(s: string; const col: TColor = clBlack);
    { private declarations }
  public
    procedure AddDecodedMessage(Message,Band:string);
    procedure NewBandMode(Band,Mode:string);
    { public declarations }
  end;

var
  frmMonWsjtx: TfrmMonWsjtx;

implementation

{ TfrmMonWsjtx }

Uses fNewQSO,dData,dUtils,dDXCC,fWkd1;


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
var
  MaxLines : integer;
begin
  MaxLines := 16;
  //scroll buffer
  if WsjtxMemo.lines.count >= MaxLines then
         Begin
          repeat
            WsjtxMemo.lines.delete(0);
          until WsjtxMemo.lines.count <= Maxlines;
          FocusLastLine;
         end;
end;

procedure TfrmMonWsjtx.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
   dmUtils.SaveWindowPos(frmMonWsjtx);
   frmMonWsjtx.hide;
end;

procedure TfrmMonWsjtx.FormShow(Sender: TObject);
begin
   dmUtils.LoadWindowPos(frmMonWsjtx);
end;

procedure TfrmMonWsjtx.NewBandMode(Band,Mode:string);
Begin
     lblBand.Caption := Band;
     lblMode.Caption := Mode;
     WsjtxMemo.lines.Clear;
end;

procedure TfrmMonWsjtx.AddDecodedMessage(Message,band:string);
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
  i          :integer;
  adif       :Word;

function NextElement:String; //detach next element from Message. Cut Message
begin
   Result:='';
   i:=1;
    trim(Message);
    while (Message[i]<>' ') and (i <= length(Message)) do
     Begin
       Result:=Result + Message[i];
       inc(i);
     end;
    if i <= length(Message) then Message := copy(Message,i+1,length(Message)-i);
    if dmData.DebugLevel>=1 then Writeln('Result:',Result,' rest of msg:',Message);
end;

Begin
      {split message
       it can be:
       12:34 # CQ CA1LL AA11
       12:34 @ CQ DX CA1LL AA11
       1536  @ CQ NA RV3AMV      //or other continents/prefixes
       12:34 @ CQ CA1LL DX
      actual mode from decoded message. Can be jt9 or jt65, nothing else(at this point)
      }

      if dmData.DebugLevel>=1 then Write('Time-');
      msgTime := NextElement;

      if dmData.DebugLevel>=1 then Write('Mode-');
      msgMode := NextElement;

      case msgMode of
      '#'  : mode := 'JT65';
      '@'  : mode := 'JT9';
      else mode :='';
      end;

      if mode <>'' then //we can continue
        Begin
         AddColorStr(msgTime,clDefault); //time
         if mode='JT65' then
             AddColorStr('  '+msgMode+'  ',clOlive) //mode
          else
             AddColorStr('  '+msgMode+'  ',clPurple);

         if dmData.DebugLevel>=1 then Write('Cq1-');
         msgCQ1 := NextElement;

         if dmData.DebugLevel>=1 then Write('Cq2-');
         msgCQ2 := NextElement;

         //CQ exeptions may be anything so we look
         // if no number in string it is addition
          if length(msgCQ2)>2 then   // if longer than 2 may be call, otherwise is addition
             Begin
              i:=1;
              while not ((msgCQ2[i]>='0') and (msgCQ2[i]<='9')) and (i <= length(msgCQ2)) do inc(i);
              if length(msgCQ2)> i then //while dropped before end, may be real call  (has number)
                 Begin
                  msgCall := msgCQ2;
                  if dmData.DebugLevel>=1 then Writeln('msgCQ2 is Call-','Result:',msgCall,' rest of msg:',Message);
                 end
                else
                 Begin  //next is call
                  if dmData.DebugLevel>=1 then Write('Call-');
                  msgCall := NextElement;
                 end;
             end
           else
            Begin  //next is call
                  if dmData.DebugLevel>=1 then Write('Call-');
                  msgCall := NextElement;
            end;

         if dmData.DebugLevel>=1 then Write('Loc-');
         msgLoc := NextElement;

         if length(msgLoc)<4 then   //no locator  may be "DX" or something
               msgLoc:='----';
         if length(msgLoc)=4 then
            if not dmUtils.IsLocOK(msgLoc+'AA') then //to fool dmUtils.IsLocOK; wsjtx locators are all 4chrs
               msgLoc:='----';

         //printing out rest of  line
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
        end;

end;



initialization
  {$I fMoniWsjtx.lrs}

end.

