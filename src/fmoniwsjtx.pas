unit fMoniWsjtx;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, strutils;

type

  { TfrmMonWsjtx }

  TfrmMonWsjtx = class(TForm)
    lblBand: TLabel;
    lblMode: TLabel;
    WsjtxMemo: TMemo;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure WsjtxMemoChange(Sender: TObject);
  private
    procedure AddMonText(s:String; a:integer);
    procedure FocusLastLine;
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

procedure TfrmMonWsjtx.AddMonText(s:String; a:integer);
Begin
   if a=0 then //replace  (all)
    WsjtxMemo.lines.text := s;
   if a=1 then //append with new line
     WsjtxMemo.lines.add (s);
   if a=2 then //append (to same line)
     WsjtxMemo.lines.text := WsjtxMemo.lines.text+s;
    FocusLastLine;
end;
procedure TfrmMonWsjtx.FocusLastLine;
begin
  WsjtxMemo.SelStart := WsjtxMemo.GetTextLen;
  WsjtxMemo.SelLength := 0;
  WsjtxMemo.ScrollBy(0, WsjtxMemo.Lines.Count);
  WsjtxMemo.Refresh;
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
      msgHead := copy(Message,1,8); //includes time and mode with trailing space
      if dmData.DebugLevel>=1 then Writeln('Header is:',msgHead,'<eoh> Mode is:',Message[7]);
      case Message[7] of
      '#'  : mode := 'JT65';
      '@'  : mode := 'JT9';
      else mode :='';
      end;
      if dmData.DebugLevel>=1 then Writeln('Mode is: ',mode);
      if mode <>'' then //we can continue
        Begin //remove CQ DX or CQ
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

         //get loc
         msgLoc:='';
         while (Message[i]<>' ') and (i <= length(Message)) do
          Begin
            msgLoc:=msgLoc + Message[i];
            inc(i);
          end;
         if dmData.DebugLevel>=1 then Writeln('Loc is:',msgLoc);
         if length(msgLoc)<4 then   //no locator
               msgLoc:='';
         if length(msgLoc)=4 then
            if not dmUtils.IsLocOK(msgLoc+'AA') then
               msgLoc:='';

         msgRes:= msgHead;
         if frmWorked_grids.WkdCall(msgCall,band,mode) then
                 msgRes:= msgRes + ' Qso -B4- '+PadRight(LowerCase(msgCall),9)+' '
             else
                 msgRes:= msgRes + ' New call '+PadRight(UpperCase(msgCall),9)+' ';

         i:=frmWorked_grids.WkdGrid(msgLoc,band,mode);

         case i of
           0  : msgRes:= msgRes +  'New main '+UpperCase(msgLoc); //not wkd
           1  : msgRes:= msgRes +  'New sub  '+lowerCase(msgLoc); //maingrid wkd
           2  : msgRes:= msgRes +  'Wkd -B4- '+ lowerCase(msgLoc); //grid wkd
         end;

         msgRes:= msgRes +' ';
         adif :=  dmDXCC.AdifFromPfx(dmDXCC.id_country(msgCall,now()));
         freq := dmUtils.FreqFromBand(band, mode);
         msgRes:= msgRes +dmDXCC.DXCCInfo(adif,freq,mode,i);

         AddMonText(msgRes,1);
        end;

end;



initialization
  {$I fMoniWsjtx.lrs}

end.

