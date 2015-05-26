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
       if dmData.DebugLevel>=1 then Writeln('LineCount-start:',Lines.Count,' String:',s);

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
       if dmData.DebugLevel>=1 then Writeln('LineCount-end :',Lines.Count,' String:',s);

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
begin
  //scroll buffer
  if WsjtxMemo.lines.count > 15 then
         Begin
          repeat
            WsjtxMemo.lines.delete(0);
          until WsjtxMemo.lines.count < 15;
          FocusLastLine;
         end;
end;

procedure TfrmMonWsjtx.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
    frmMonWsjtx.hide;
end;
procedure TfrmMonWsjtx.NewBandMode(Band,Mode:string);
Begin
     lblBand.Caption := Band;
     lblMode.Caption := Mode;
     WsjtxMemo.lines.Clear;
end;

procedure TfrmMonWsjtx.AddDecodedMessage(Message,band:string);
var
  msgHead,
  msgCall,
  msgLoc,
  msgRes,
  mode,
  freq :string;
  i          :integer;
  adif       :Word;

Begin
      {split message
       it can be:
       12:34 # CQ CA1LL AA11
       12:34 @ CQ DX CA1LL AA11
       12:34 @ CQ CA1LL DX
      actual mode from decoded message. Can be jt9 or jt65, nothing else(at this point)
      }

      if dmData.DebugLevel>=1 then Writeln('Header is:',copy(Message,1,8),'<eoh> Mode is:',Message[7]);
      case Message[7] of
      '#'  : mode := 'JT65';
      '@'  : mode := 'JT9';
      else mode :='';
      end;
      if dmData.DebugLevel>=1 then Writeln('Mode is: ',mode);

      if mode <>'' then //we can continue
        Begin
         AddColorStr(copy(Message,1,5),clDefault); //time
         if Message[7]='#' then
             AddColorStr('  '+Message[7]+'  ',clOlive) //mode
          else
             AddColorStr('  '+Message[7]+'  ',clPurple);
         //remove CQ DX or CQ
         if pos('CQ DX ', Message) > 0 then
           Message := copy(Message,pos('CQ DX ', Message)+6,length(Message)-pos('CQ DX ', Message)+6)
          else
         if pos('CQ ', Message) > 0 then
           Message := copy(Message,pos('CQ ', Message)+3,length(Message)-pos('CQ ', Message)+3);

         if dmData.DebugLevel>=1 then Writeln('Header stripped msg is:',Message);

         // next is call
         msgCall:='';
         i:=1;
         while (Message[i]<>' ') and (i <= length(Message)) do
          Begin
            msgCall:=msgCall + Message[i];
            inc(i);
          end;
         if dmData.DebugLevel>=1 then Writeln('Call is:',msgCall);

         //skip space done
         if dmData.DebugLevel>=1 then Writeln('Skipped:',Message[i],'<');
         inc(i);

         //get loc grid
         msgLoc:='';
         while (Message[i]<>' ') and (i <= length(Message)) do
          Begin
            msgLoc:=msgLoc + Message[i];
            inc(i);
          end;
         if dmData.DebugLevel>=1 then Writeln('Loc is:',msgLoc);
         if length(msgLoc)<4 then   //no locator  may be "DX"
               msgLoc:='';
         if length(msgLoc)=4 then
            if not dmUtils.IsLocOK(msgLoc+'AA') then //to fool dmUtils.IsLocOK; wsjtx locators are all 4chrs
               msgLoc:='';

         if frmWorked_grids.WkdCall(msgCall,band,mode) then
                 AddColorStr(PadRight(LowerCase(msgCall),9)+' ',clRed)
                 //AddColorStr(' Qso -B4- '+PadRight(LowerCase(msgCall),9)+' ',clRed)
             else
                 AddColorStr(PadRight(UpperCase(msgCall),9)+' ',clGreen);
                 //AddColorStr(' New call '+PadRight(UpperCase(msgCall),9)+' ',clGreen);

         i:=frmWorked_grids.WkdGrid(msgLoc,band,mode);

         case i of
           0  : AddColorStr(UpperCase(msgLoc),clGreen); //not wkd
                //AddColorStr('New main '+UpperCase(msgLoc),clGreen); //not wkd
           1  : Begin
                     //AddColorStr('New sub  ',clGreen);
                     AddColorStr(lowerCase(copy(msgLoc,1,2)),clRed); //maingrid wkd
                     AddColorStr(lowerCase(copy(msgLoc,3,2)),clGreen);
                end;
           2  : AddColorStr(lowerCase(msgLoc),clRed); //grid wkd
                //AddColorStr('Wkd -B4- '+ lowerCase(msgLoc),clRed); //grid wkd
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

