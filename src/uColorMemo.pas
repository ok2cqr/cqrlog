unit uColorMemo;
{
(c) Martin Tichacek licence GPL 2.0

other changes by Petr Hlozek, OK2CQR
  - public functions and constants renamed to English

Get info from spot, OH1KH
click on empty memo crashes, fix OH1KH
}

{$mode objfpc}{$H+}

interface


uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls,menus,Clipbrd, strutils;


const LANG=1; // 0 Czech , 1 English

const MAX_LINES=100000;

const text_Select_All:string='Vybrat vse|Select all';
const text_Select_None:string='Zrusit vyber|Select none';
const text_Start_Selection:string='Zacatek bloku|Start of selection';
const text_End_Selection:string='Konec bloku|End of selection';
const text_Copy:string='Kopirovat|Copy';


Type Tveta=record
       te:string;  // text
       bpi:TColor; // text color
       bpo:Tcolor; // background color
       pom:longint;
     end;

  Pveta=^Tveta;
  Tvety=array[0..MAX_LINES] of Pveta;

type
   TcolorMemo = class(TPanel)
    public
       oncClick : procedure(Where:longint;mb:TmouseButton;ms:TShiftState) of object;
       oncDblClick : procedure(Where:longint;mb:TmouseButton;ms:TShiftState) of object;

       onMyPopup : procedure(Where:longint;bs:boolean;b1,b2:longint;c_tag:longint) of object;

       BackgourndColor : Tcolor;  // default clHighlight
       MyTextColor : Tcolor;  // default clHighlightText

       AutoScroll : Boolean; // default false


       constructor Create(TheOwner: TComponent); override;
       destructor Destroy; override;


       function  AddLine(LineText:string;StringColor,BackgroundColor:Tcolor;pom:longint):boolean;

       function  InsertLine(LineText:string;StringColor,BackgroundColor:Tcolor;pom:longint;Position:longint):boolean;

       function  ReplaceLine(LineText:string;StringColor,BackgroundColor:Tcolor;pom:longint;Position:longint;msk:longint):boolean;
       {
          Replaces existing line.
          msk 0 - replace text
          msk 1 - change text color
          msk 2 - change backgound color
       }


       function RemoveLine(Position:longint):boolean;
       {
         Removes line on Position
         returns false when failed
       }

       procedure RemoveAllLines;

       function  ReadLine(var LineText:string; var StringColor,BackgroundColor:Tcolor; var pom:longint; Position:longint):boolean;

       function LastLineNumber:longint;
       {
         number of last line
         lines count = last line + 1
       }

       procedure DisableAutoRepaint(RepaintEnabled:boolean);
       {
         Enabled - True - disable auto repait
         Enable - False - enable auto repaint
       }


       function LineNumberInSelBlock(LineNumber:longint):boolean;
       {
         Returns True when LineNumber exists in selected block
       }


       procedure SetFont(f:TFont);


       function Search(What:string;From:longint;ToLastLine:boolean;WholeLine:boolean):longint;
       {
         Returns -1 when not found
       }

       procedure Scroll(Position:longint);
       {
          Scrolls to Position
       }


       procedure setLanguage(j:longint);


       procedure AddToPopup(c_text:string;c_tag:longint);
       {
         Adds new item to Popup menu after standard items. Seprator is '-'.
         After user click to own popum menu, onMyPopup is called
       }

     private
       sbs,sbv:Tscrollbar;
       pab:Tpaintbox;
       pop:TPopupMenu;
       uzmam_pop:boolean;
       jazy_int:longint;

       bl1,bl2:longint; {begining/end of the block}
       bls:boolean;     {is something selected?}
       
       refr_en:longint; {pif 0, painting is allowed, else painting disabled}

       mx,my:longint; {last mouse position}
       mx1,my1:longint; {mouse position when mouse up}
       mb:TMouseButton;
       ms:TShiftState;
       
       

       vety:Tvety;
       vetp:longint; {Last used line}
       vyska_radku:longint;

       procedure jmonpaint(sender:Tobject);

       procedure aktualizujpozici(sender:Tobject);
       property OnResize;

       procedure sbscrll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);

       procedure mys_pohyb(Sender: TObject;Shift: TShiftState; X,Y: Integer);
       procedure mys_zmack(Sender: TObject;Button: TMouseButton;Shift: TShiftState; X,Y: Integer);
       procedure mys_zmack1(Sender: TObject;Button: TMouseButton;Shift: TShiftState; X,Y: Integer);
       procedure mys_WheelUp(Sender: TObject; Shift: TShiftState;  MousePos: TPoint; var Handled: Boolean);
       procedure mys_WheelDown(Sender: TObject; Shift: TShiftState;  MousePos: TPoint; var Handled: Boolean);


       function my_2_index(z:longint):longint;
       procedure generuj_klik(Sender: TObject; X,Y: Integer;Button: TMouseButton;Shift: TShiftState);

       procedure priselpopup(sender:Tobject);
       procedure nactiblok(var b1,b2:longint);

       procedure mys_dclick_in(sender:Tobject);

       procedure postav_obsah_popupa(p:Tpopupmenu);
       function dt(celytext:string):string;
       procedure GetInfoFromSpot(x:longint);  //sh/dx or normal "DX de" spot found result info part to clipboard

   end;


implementation

uses dDXCluster;

constructor TcolorMemo.Create(TheOwner: TComponent);
  begin
    inherited create(theowner);

    oncClick:=nil;
    oncDblClick:=nil;
    onMyPopup:=nil;
    uzmam_pop:=false;
    jazy_int:=LANG;

    AutoScroll:=false;
    refr_en:=0;

    DoubleBuffered:=true;
    caption:='';
    
    pab:=Tpaintbox.Create(self);
    pab.parent:=self;

    BackgourndColor:=clHighlight;
    MyTextColor:=clHighlightText;



    sbs:=Tscrollbar.create(self);
    sbs.parent:=self;
    sbs.name:='sbs';
    sbs.Kind:=sbVertical;
    sbs.pagesize:=1;

    sbv:=Tscrollbar.create(self);
    sbv.parent:=self;
    sbv.name:='sbv';
    sbv.Kind:=sbHorizontal;
    sbv.pagesize:=1;

    pab.onpaint:=@jmonpaint;
    onresize:=@aktualizujpozici;

    mx:=0;
    my:=0;
    mb:=mbLeft;
    ms:=[];

    pab.OnMouseDown:=@mys_zmack1;
    pab.OnMouseUp:=@mys_zmack;
    pab.OnMouseMove:=@mys_pohyb;
    pab.OnDblClick:=@mys_dclick_in;
    pab.OnMouseWheelUp:= @mys_Wheelup;
    pab.OnMouseWheelDown:= @mys_WheelDown;

//    pab.Font.Pitch:=fpfixed;
//    pab.Canvas.Font.pitch:=fpFixed;


    sbs.OnScroll:=@sbscrll;
    sbv.OnScroll:=@sbscrll;
    vyska_radku:=20;

    fillchar(vety,sizeof(vety),0);
    vetp:=-1;

    pop:=Tpopupmenu.Create(self);
    pop.parent:=self;
    
    postav_obsah_popupa(pop);


    pab.PopupMenu:=pop;

    bls:=false;
    bl1:=4;
    bl2:=10;

    aktualizujpozici(nil);

end;

destructor TcolorMemo.Destroy;
var z:longint;
  begin
    for z:=0 to vetp do
        if vety[z]<>nil then
        begin
          dispose(vety[z]);
          vety[z]:=nil;
        end;
    sbv.destroy;
    sbs.destroy;
    pab.PopupMenu:=nil;
    pop.destroy;
    pab.destroy;
    inherited destroy;
  end;




function TcolorMemo.dt(celytext:string):string;
var aaa:string;
    ja:longint;
  begin
    ja:=jazy_int;
    if ja<0 then ja:=0;
    aaa:=celytext;
    while ja>0 do
      begin aaa:=copy(aaa,pos('|',aaa)+1,length(aaa));ja:=ja-1;end;
    if length(aaa)=0 then aaa:=celytext; { pokud by byl zvoleny LANG ZA poctem prelozenych..., vratim prvni mozny}
    if pos('|',aaa)<>0 then aaa:=copy(aaa,1,pos('|',aaa)-1);
    dt:=aaa;
  end;


procedure TcolorMemo.AddToPopup(c_text:string;c_tag:longint);
var mi:Tmenuitem;
  begin
    if c_tag<10 then c_tag:=0;
    mi:=Tmenuitem.create(pop);
    mi.Caption:=c_text;
    mi.OnClick:=@priselpopup;
    mi.tag:=c_tag;
    pop.Items.Add(mi);
  end;



procedure TcolorMemo.postav_obsah_popupa(p:Tpopupmenu);
var mi:Tmenuitem;
  begin
    if uzmam_pop then
      while pop.Items.Count>0 do pop.Items.Delete(0);

    uzmam_pop:=true;
    mi:=Tmenuitem.create(pop);
    mi.Caption:=dt(text_Select_All);
    mi.OnClick:=@priselpopup;
    mi.tag:=1;
    pop.Items.Add(mi);

    mi:=Tmenuitem.create(pop);
    mi.Caption:=dt(text_Select_None);
    mi.OnClick:=@priselpopup;
    mi.tag:=2;
    pop.Items.Add(mi);

    mi:=Tmenuitem.create(pop);
    mi.Caption:=dt(text_Start_Selection);
    mi.OnClick:=@priselpopup;
    mi.tag:=3;
    pop.Items.Add(mi);

    mi:=Tmenuitem.create(pop);
    mi.Caption:=dt(text_End_Selection);
    mi.OnClick:=@priselpopup;
    mi.tag:=4;
    pop.Items.Add(mi);

    mi:=Tmenuitem.create(pop);
    mi.Caption:='-';
    mi.OnClick:=nil;
    mi.tag:=0;
    pop.Items.Add(mi);

    mi:=Tmenuitem.create(pop);
    mi.Caption:=dt(text_Copy);
    mi.OnClick:=@priselpopup;
    mi.tag:=5;
    pop.Items.Add(mi);


  end;


procedure TcolorMemo.setLanguage(j:longint);
  begin
    jazy_int:=j;
    postav_obsah_popupa(pop);
  end;




procedure TcolorMemo.priselpopup(sender:Tobject);
var z,x,c,v:longint;
    ua:string;
  begin
    z:=Tmenuitem(sender).tag;
    case z of
      1: begin bls:=true;bl1:=0;bl2:=vetp;if refr_en=0 then pab.Refresh;end;
      2: begin bls:=false;if refr_en=0 then pab.Refresh;end;
      3: begin bls:=true;x:=my_2_index(my);bl1:=x;bl2:=x;if refr_en=0 then pab.Refresh; end;
      4: begin
           if bls then
             begin x:=my_2_index(my);bl2:=x; end
           else
             begin bls:=true;x:=my_2_index(my);bl1:=x;bl2:=x; end;
           if refr_en=0 then pab.Refresh;
         end;
      5: begin
           Clipboard.Clear;
           if bls then
             begin
               nactiblok(x,c);
               ua:='';
               for v:=x to c do ua:=ua+vety[v]^.te+#13#10;
               Clipboard.astext:=ua;
             end;
         end
      else
        if (z>=10) and (onMyPopup<>nil) then
          onMyPopup(my_2_index(my),bls,bl1,bl2,z);
    end;
  end;


procedure TcolorMemo.nactiblok(var b1,b2:longint);
  begin
    if bl1>bl2 then begin b1:=bl2;b2:=bl1 end
      else begin b1:=bl1;b2:=bl2 end;
  end;

function TcolorMemo.AddLine(LineText:string;StringColor,BackgroundColor:Tcolor;pom:longint):boolean;
var z:longint;
  begin
    result:=true;
    if vetp>=MAX_LINES then begin Result:=false; exit end; {!!!}
    inc(vetp);
    new(vety[vetp]);
    vety[vetp]^.te:=LineText;
    vety[vetp]^.bpi:=StringColor;
    vety[vetp]^.bpo:=BackgroundColor;
    vety[vetp]^.pom:=pom;

    aktualizujpozici(self);
    if AutoScroll then
      begin
        z:=sbs.Max;
        sbs.Position:=z;
      end;
    if refr_en=0 then pab.Refresh;
  end;


function TcolorMemo.RemoveLine(Position:longint):boolean;
var z:longint;
   begin
    result:=true;
    if (Position<0) or (Position>vetp) or (vety[Position]=nil) then begin Result:=false; exit end; {!!!}
    dispose(vety[Position]);
    for z:=Position to vetp-1 do vety[z]:=vety[z+1];
    vety[vetp]:=nil;
    dec(vetp);
    if bl1>=Position then dec(bl1);if bl1<0 then bl1:=0;
    if bl2>=Position then dec(bl2);if bl2<0 then bl2:=0;
    aktualizujpozici(self);
    if refr_en=0 then pab.Refresh;
   end;

procedure TcolorMemo.RemoveAllLines;
var z:longint;
  begin
    bls:=false;bl1:=0;bl2:=0;
    for z:=0 to vetp do begin dispose(vety[z]);vety[z]:=nil; end;
    vetp:=-1;
    aktualizujpozici(self);
    if refr_en=0 then pab.Refresh;
  end;

function  TcolorMemo.InsertLine(LineText:string;StringColor,BackgroundColor:Tcolor;pom:longint;Position:longint):boolean;
var z:longint;
  begin
    result:=true;
    if Position<0 then begin result:=false;exit;end;
    if Position>vetp+1 then begin result:=false;exit;end;
    if vetp>=MAX_LINES then begin Result:=false;exit end; {!!!}
    
    inc(vetp);
    for z:=vetp downto Position+1 do vety[z]:=vety[z-1];
    new(vety[Position]);
    vety[Position]^.te:=LineText;
    vety[Position]^.bpi:=StringColor;
    vety[Position]^.bpo:=BackgroundColor;
    vety[Position]^.pom:=pom;
    
    aktualizujpozici(self);
    if AutoScroll then
      begin
        Scroll(Position);
      end;
    if refr_en=0 then pab.Refresh;
  end;


function  TcolorMemo.ReplaceLine(LineText:string;StringColor,BackgroundColor:Tcolor;pom:longint;Position:longint;msk:longint):boolean;
var z:longint;
  begin
    result:=true;
    if Position<0 then begin result:=false;exit;end;
    if Position>vetp then begin result:=false;exit;end;

    if msk=0 then vety[Position]^.te:=LineText;
    if msk=1 then vety[Position]^.bpi:=StringColor;
    if msk=2 then vety[Position]^.bpo:=BackgroundColor;
    if msk=3 then vety[Position]^.pom:=pom;

//    aktualizujpozici(self);
    if AutoScroll then
      begin
        z:=Position;
        if z>sbs.Max then z:=sbs.Max else z:=Position;
        sbs.Position:=z;
      end;
    if refr_en=0 then pab.Refresh;
  end;



function  TcolorMemo.ReadLine(var LineText:string;var StringColor,BackgroundColor:Tcolor;var pom:longint;Position:longint):boolean;
  begin
    result:=true;
    if Position<0 then begin result:=false;exit;end;
    if Position>vetp then begin result:=false;exit;end;

    LineText:=vety[Position]^.te;
    StringColor:=vety[Position]^.bpi;
    BackgroundColor:=vety[Position]^.bpo;
    pom:=vety[Position]^.pom;
end;



function TcolorMemo.LastLineNumber:longint;
  begin
    LastLineNumber:=vetp;
  end;


procedure TcolorMemo.aktualizujpozici(sender:Tobject);
var z:longint;
  begin
    sbs.left:=width-sbs.width-2;
    sbs.top:=2;
    sbs.height:=height-sbs.width-4;
    

    sbv.Top:=height-sbv.height-2;
    sbv.Left:=2;
    sbv.Width:=width-sbv.height-4;
    
    pab.left:=2;
    pab.top:=2;
    pab.Width:=sbs.left-4;
    pab.height:=sbs.height-4;
    
    sbs.Min:=0;
    z:=(vetp-(pab.height div vyska_radku)+1);
    if z<0 then z:=0;
    sbs.Max:=z;
    sbs.LargeChange:=pab.height div vyska_radku;

  end;


procedure TcolorMemo.jmonpaint(sender:Tobject);
var z,x:longint;
    b1,b2:TColor;
  begin
   if refr_en<>0 then exit;
    x:=sbs.Position;
    for z:=0 to pab.height div vyska_radku do
      begin
        if x+z<=vetp then
          begin
            if LineNumberInSelBlock(z+x) then
              begin b1:=MyTextColor;b2:=BackgourndColor;end
              else
              begin b2:=vety[z+x]^.bpo;b1:=vety[z+x]^.bpi;end;
            pab.Canvas.Brush.Color:=b2;
            pab.Canvas.FillRect(0,1+z*vyska_radku,width-1,1+(z+1)*vyska_radku-1);
            pab.Canvas.font.Color:=b1;
//            pab.Canvas.font.style:=[fsBold,fsItalic];
//            pab.font.style:=[fsBold,fsItalic];
            pab.Canvas.TextOut(5-sbv.Position*8,5+(z)*vyska_radku,vety[x+z]^.te);
          end;
      end;
  end;


procedure TcolorMemo.sbscrll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
  begin
//    jmonpaint(sender);
    if refr_en=0 then pab.Invalidate;
  end;

procedure TcolorMemo.DisableAutoRepaint(RepaintEnabled:boolean);
  begin
    if RepaintEnabled then
      inc(refr_en)
    else
      if refr_en>0 then
        dec(refr_en)
        else
        refr_en:=0;
    if refr_en=0 then pab.Refresh;
  end;



procedure TcolorMemo.mys_pohyb(Sender: TObject; Shift: TShiftState; X,Y: Integer);
var z:longint;
  begin
    mx:=x;
    my:=y;
//    mb:=button;
    ms:=shift;

    if (ssleft in shift) and (abs(my-my1)>5) then
      begin
        if not bls then
          begin
            bls:=true;
            bl1:=my_2_index(my1);
            bl2:=my_2_index(my);
            if refr_en=0 then pab.Refresh;
          end
          else
          begin
            //bl1:=my_2_index(my1);
            z:=bl2;
            bl2:=my_2_index(my);
            if z<>bl2 then
              if refr_en=0 then pab.Refresh;

          end;
      end;

  end;
  
procedure TcolorMemo.mys_zmack(Sender: TObject;Button: TMouseButton;Shift: TShiftState; X,Y: Integer);
  begin
    mx:=x;
    my:=y;
    mb:=button;
    ms:=shift;

    if (abs(mx-mx1)<2) and (abs(my-my1)<2) then
      begin
        generuj_klik(sender,mx,my,mb,ms);
      end;
    
  end;

procedure TcolorMemo.mys_zmack1(Sender: TObject;Button: TMouseButton;Shift: TShiftState;X,Y: Integer );
  begin
    mx:=x;
    my:=y;
    mx1:=x;
    my1:=y;
    mb:=button;
    ms:=shift;
    if bls  and (ssleft in shift) then
      begin
        bls:=false;
        if refr_en=0 then pab.Refresh;
      end
    else
  end;


procedure TcolorMemo.generuj_klik(Sender: TObject; X,Y: Integer;Button: TMouseButton;Shift: TShiftState);
var z:longint;
  begin
    z:=my_2_index(my);
    if oncClick<>nil then oncClick(z,mb,ms);
  end;


function TcolorMemo.my_2_index(z:longint):longint;
  begin
    z:=(z-2) div vyska_radku+sbs.position;

    if z>vetp then z:=vetp;
    if z<0 then z:=0;
    result:=z;
  end;

function TcolorMemo.LineNumberInSelBlock(LineNumber:longint):boolean;
var z,x,c:longint;
  begin
    z:=bl1;
    x:=bl2;
    if z>x then begin c:=z;z:=x;x:=c end;
    result:=bls and (LineNumber>=0) and (LineNumber<=vetp) and (LineNumber>=z) and (LineNumber<=x);
  end;

procedure TcolorMemo.GetInfoFromSpot(x:longint);
var z,c,v,a:longint;
    ua,uz,
    call,freq,info:string;
    p,l :integer;
  begin
     bl1:=x;bl2:=x; //select line under cursor
     nactiblok(x,c);
     ua:='';
     if vetp < 0 then exit; //otherwise double click on empty memo crashes program (band map, dx cluster)
      for v:=x to c do ua:=ua+vety[v]^.te+#13#10;
     //writeln('Spot line: ',ua);
     dmDXCluster.GetSplitSpot(ua,call,freq,info);
     Clipboard.Clear;
     Clipboard.astext:= info; //info is now in clipboard
     //writeln ('DX de info: ',info);

  end;

procedure TcolorMemo.mys_dclick_in(sender:Tobject);
var z:longint;
  begin
    z:=my_2_index(my);
    GetInfoFromSpot(z);
    if oncDblClick<>nil then oncDblClick(z,mb,ms);
  end;
  

procedure TcolorMemo.SetFont(f:Tfont);
  begin
    pab.font:=f;
    pab.canvas.Font:=f;
    vyska_radku:=pab.canvas.TextHeight('WTIjpyg')+4;
     // nebo si tu pridejte dalsi pismenka, ktere jsou nejak moc nad/pod prumer normalni vysky

    aktualizujpozici(nil);
    if refr_en=0 then pab.Refresh;
  end;

procedure TcolorMemo.Scroll(Position:longint);
var z:longint;
  begin
        if Position<0 then Position:=0;
        if Position>vetp then Position:=vetp;
        z:=Position;
        if z>sbs.Max then z:=sbs.Max else z:=Position;
        sbs.Position:=z;
        if refr_en=0 then pab.Refresh;
  end;

procedure TcolorMemo.mys_WheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
   sbs.position:=sbs.position+1;
   pab.refresh;
end;
procedure TcolorMemo.mys_Wheelup(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
   sbs.position:=sbs.position-1;
   pab.refresh;
end;



function TcolorMemo.Search(What:string;From:longint;ToLastLine:boolean;WholeLine:boolean):longint;
var z,v:longint;

    function je_to_tento(kery:longint):boolean;
      begin
        if (kery>=0) and (kery<=vetp) then
          begin
            if WholeLine then
                je_to_tento:=What=vety[kery]^.te
              else
                je_to_tento:=pos(What,vety[kery]^.te)<>0;
          end
          else je_to_tento:=false;
      end;
  begin
    z:=From;
    if ToLastLine then v:=1 else v:=-1;
    while (z>=0) and (z<=vetp) and (not je_to_tento(z)) do z:=z+v;
    if je_to_tento(z) then Search:=z else Search:=-1;
  end;




end.

