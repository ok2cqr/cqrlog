unit jakozememo;


// verze
// 1 ... zacalo cislovani ...
// 2 ... zjistovani vysky pisma , hledani
// 3 ... pridan "jazyk" :-P
// 4 ... moznost zvolit jiny jazyk za behu....
//       moznost vlastnich polozek v popupu a reakce na ne.
// 5 ... mazani vety a celeho seznamu...
// 6 ... pokus o opravu refreshe (scrollbar-scroll - prekresloval pozde) pod GTK2
//       setrnejsi clipboard...
// 7 ... hm... oznacovani bloku bylo taky spetne - chybel refresh..

{$mode objfpc}{$H+}

interface


uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls,menus,Clipbrd;


const jazyk=1; // 0 cz , 1 en (nic vic zatim..., netreba menit tu, objekt "umi" zmenu za provozu)

const mpv=100000; // max pocet polozek... je to malo?

const text_Vybrat_vse:string='Vybrat vse|Select all';
const text_Zrusit_vyber:string='Zrusit vyber|Select none';
const text_Zacatek_bloku:string='Zacatek bloku|Start of selection';
const text_Konec_bloku:string='Konec bloku|End of selection';
const text_Kopirovat:string='Kopirovat|Copy';


Type Tveta=record
       te:string;  // kus textu
       bpi:TColor; // barva pisma
       bpo:Tcolor; // barva podkladu
       pom:longint;
     end;

  Pveta=^Tveta;
  Tvety=array[0..mpv] of Pveta;

type
   Tjakomemo = class(TPanel)
    public
       // vlastnosti "bezneho" panelu sem neprepsal... co s tim udedelate je vas risk :-)

       oncclick:procedure(kam:longint;mb:TmouseButton;ms:TShiftState) of object;
       oncdblclick:procedure(kam:longint;mb:TmouseButton;ms:TShiftState) of object;

       on_vlastni_popup:procedure(kam:longint;bs:boolean;b1,b2:longint;c_tag:longint) of object;
        {obsluha vlastnich radku v popup menu}

       barva_bloku_pod:Tcolor;  // default clHighlight
       barva_bloku_pis:Tcolor;  // default clHighlightText

       autoscroll:boolean; // default false
        {pokud true, bude se automaticky scrollovat na pozici , kam bylo vlozeno}

       constructor Create(TheOwner: TComponent); override;
       destructor Destroy; override;


       function  pridej_vetu(te:string;bpi,bpo:Tcolor;pom:longint):boolean;
         { vrazi text na konec seznamu , v pripade neuspechu vraci false
           bpi - barva pisma , bpo - barva podkladu ; pom - pomocne cifro - na libovolne pouziti }
         
       function  vloz_vetu(te:string;bpi,bpo:Tcolor;pom:longint;kam:longint):boolean;
         { kam - pozice kam vlozit radek textu; zacatek je 0,
           jinak totez co pridej_vetu
           ... pridat na konec je posledniveta+1
         }

       function  prepis_vetu(te:string;bpi,bpo:Tcolor;pom:longint;kam:longint;msk:longint):boolean;
         {zmeni (prepise) EXISTUJICI vetu
          bity v msk: 0 - te , 1 bpi , 2 bpo ....
          kde je 0, tak zustane nezmeneno
         }


       function smaz_vetu(kam:longint):boolean;
         { ... ehm ... smaze vetu. He? (kam - kterou) , vraci false, pokud selze }

       procedure smaz_vse;
         { ... vsechny vety ... }

         
       function  cti_vetu(var te:string;var bpi,bpo:Tcolor;var pom:longint;kam:longint):boolean;
         {protikus k prepis_vetu}


       function posledniveta:longint;
         {cislo posledni PLATNE vety. prvni je na pozici 0, pocet vet je (posledniveta+1) }

       procedure zakaz_kresleni(st:boolean);
         {st=true - zakaze kresleni, false povoli. Pouzivat pri velkych zmenach v seznamech
          mohlo (bud tam mam nekde chybu nebo to nema vliv.(!)) by urychlit pridavani velkeho
          mnozstvi polozek najednou tim, ze si zakazete prekreslovani polozek a povolite
          ho az na konci.
          uvnitr zakazu je integer, takze pokud neco 2x zakazete, musite to zase 2x povolit.
          po povoleni kresleni je prekresleno zrovna.
         }


       function jevbloku(num:longint):boolean;
         { vraci true, pokud je polozka cislo "num" ve vybranem bloku }


       procedure nastav_font(f:TFont);
         { pokusi se nastavit font... hm}


       function hledej(co:string;odkud:longint;smer_dolu:boolean;cely_radek:boolean):longint;
         { vrati -1, pokud nenajde, he? :-) }

       procedure poskroluj(kam:longint);
         { naskroluje na radek... priblizne }


       procedure nastav_jazyk(j:longint);
         { pouzitelne i jako "reset" popupu - promaze obsah menu a pak teprve nahraje nove polozky
           mel-li tam nekdo vlastni, musi si je nasledne zase pridat
         }
       
       procedure prikrm_popup(c_text:string;c_tag:longint);
         { prida polozku na KONEC popup menu (za standardni veci),
           v pripade, ze je uzivatel zvoli, dostanete vedet pomoci "on_vlastni_popup"
           tag pod 10 budu mazat, aby se nekdo necpal do standardnich...

           separator je '-' (jeden znak minus) v c_text, ale kto to dnes potrebuje vedet?
         }
     private
       sbs,sbv:Tscrollbar; {scrollbar svisly/vodorovny}
       pab:Tpaintbox;
       pop:TPopupMenu;
       uzmam_pop:boolean;
       jazy_int:longint;

       bl1,bl2:longint; {zacatek,konec bloku}
       bls:boolean;     {je neco vybrane...?}
       
       refr_en:longint; {pokud 0, tak je kresleni povoleno, je li vetsi, tak se neprekresluje paintbox}

       mx,my:longint; {posledni znama pozice mysi}
       mx1,my1:longint; { zalozni pozce mysi - pri mouse down }
       mb:TMouseButton;
       ms:TShiftState;
       
       

       vety:Tvety;
       vetp:longint; {posledni pouzita veta}
       vyska_radku:longint;

       procedure jmonpaint(sender:Tobject);

       procedure aktualizujpozici(sender:Tobject);
       property OnResize;

       procedure sbscrll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer); // scrollbarsvislyscroll....

       procedure mys_pohyb(Sender: TObject;Shift: TShiftState; X,Y: Integer);
       procedure mys_zmack(Sender: TObject;Button: TMouseButton;Shift: TShiftState; X,Y: Integer);
       procedure mys_zmack1(Sender: TObject;Button: TMouseButton;Shift: TShiftState; X,Y: Integer);
       procedure mys_WheelUp(Sender: TObject; Shift: TShiftState;  MousePos: TPoint; var Handled: Boolean);
       procedure mys_WheelDown(Sender: TObject; Shift: TShiftState;  MousePos: TPoint; var Handled: Boolean);


       function my_2_index(z:longint):longint;
       procedure generuj_klik(Sender: TObject; X,Y: Integer;Button: TMouseButton;Shift: TShiftState);

       procedure priselpopup(sender:Tobject);
       procedure nactiblok(var b1,b2:longint);

//       procedure mys_click(sender:Tobject);
       procedure mys_dclick_in(sender:Tobject);

       procedure postav_obsah_popupa(p:Tpopupmenu);
         { [je-li co, tak prvni vse smaze a znovu] nakrmi popup menu polozkama dle akt. jazyka. }
       function dt(celytext:string):string;
   end;


implementation


constructor Tjakomemo.Create(TheOwner: TComponent);
  begin
    inherited create(theowner);

    oncclick:=nil;
    oncdblclick:=nil;
    on_vlastni_popup:=nil;
    uzmam_pop:=false;
    jazy_int:=jazyk;

    autoscroll:=false;
    refr_en:=0;

    DoubleBuffered:=true;
    caption:='';
    
    pab:=Tpaintbox.Create(self);
    pab.parent:=self;

    barva_bloku_pod:=clHighlight;
    barva_bloku_pis:=clHighlightText;



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

destructor Tjakomemo.Destroy;
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




function Tjakomemo.dt(celytext:string):string;
var aaa:string;
    ja:longint;
  begin
    ja:=jazy_int;
    if ja<0 then ja:=0;
    aaa:=celytext;
    while ja>0 do
      begin aaa:=copy(aaa,pos('|',aaa)+1,length(aaa));ja:=ja-1;end;
    if length(aaa)=0 then aaa:=celytext; { pokud by byl zvoleny jazyk ZA poctem prelozenych..., vratim prvni mozny}
    if pos('|',aaa)<>0 then aaa:=copy(aaa,1,pos('|',aaa)-1);
    dt:=aaa;
  end;


procedure Tjakomemo.prikrm_popup(c_text:string;c_tag:longint);
var mi:Tmenuitem;
  begin
    if c_tag<10 then c_tag:=0;
    mi:=Tmenuitem.create(pop);
    mi.Caption:=c_text;
    mi.OnClick:=@priselpopup;
    mi.tag:=c_tag;
    pop.Items.Add(mi);
  end;



procedure Tjakomemo.postav_obsah_popupa(p:Tpopupmenu);
var mi:Tmenuitem;
  begin
    if uzmam_pop then
      while pop.Items.Count>0 do pop.Items.Delete(0);

    uzmam_pop:=true;
    mi:=Tmenuitem.create(pop);
    mi.Caption:=dt(text_Vybrat_vse);
    mi.OnClick:=@priselpopup;
    mi.tag:=1;
    pop.Items.Add(mi);

    mi:=Tmenuitem.create(pop);
    mi.Caption:=dt(text_Zrusit_vyber);
    mi.OnClick:=@priselpopup;
    mi.tag:=2;
    pop.Items.Add(mi);

    mi:=Tmenuitem.create(pop);
    mi.Caption:=dt(text_Zacatek_bloku);
    mi.OnClick:=@priselpopup;
    mi.tag:=3;
    pop.Items.Add(mi);

    mi:=Tmenuitem.create(pop);
    mi.Caption:=dt(text_Konec_bloku);
    mi.OnClick:=@priselpopup;
    mi.tag:=4;
    pop.Items.Add(mi);

    mi:=Tmenuitem.create(pop);
    mi.Caption:='-';
    mi.OnClick:=nil;
    mi.tag:=0;
    pop.Items.Add(mi);

    mi:=Tmenuitem.create(pop);
    mi.Caption:=dt(text_Kopirovat);
    mi.OnClick:=@priselpopup;
    mi.tag:=5;
    pop.Items.Add(mi);


  end;


procedure Tjakomemo.nastav_jazyk(j:longint);
  begin
    jazy_int:=j;
    postav_obsah_popupa(pop);
  end;




procedure Tjakomemo.priselpopup(sender:Tobject);
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
        if (z>=10) and (on_vlastni_popup<>nil) then
          on_vlastni_popup(my_2_index(my),bls,bl1,bl2,z);
    end;
  end;


procedure Tjakomemo.nactiblok(var b1,b2:longint);
  begin
    if bl1>bl2 then begin b1:=bl2;b2:=bl1 end
      else begin b1:=bl1;b2:=bl2 end;
  end;

function Tjakomemo.pridej_vetu(te:string;bpi,bpo:Tcolor;pom:longint):boolean;
var z:longint;
  begin
    result:=true;
    if vetp>=mpv then begin Result:=false; exit end; {!!!}
    inc(vetp);
    new(vety[vetp]);
    vety[vetp]^.te:=te;
    vety[vetp]^.bpi:=bpi;
    vety[vetp]^.bpo:=bpo;
    vety[vetp]^.pom:=pom;

    aktualizujpozici(self);
    if autoscroll then
      begin
        z:=sbs.Max;
        sbs.Position:=z;
      end;
    if refr_en=0 then pab.Refresh;
  end;


function Tjakomemo.smaz_vetu(kam:longint):boolean;
var z:longint;
   begin
    result:=true;
    if (kam<0) or (kam>vetp) or (vety[kam]=nil) then begin Result:=false; exit end; {!!!}
    dispose(vety[kam]);
    for z:=kam to vetp-1 do vety[z]:=vety[z+1];
    vety[vetp]:=nil;
    dec(vetp);
    if bl1>=kam then dec(bl1);if bl1<0 then bl1:=0;
    if bl2>=kam then dec(bl2);if bl2<0 then bl2:=0;
    aktualizujpozici(self);
    if refr_en=0 then pab.Refresh;
   end;

procedure Tjakomemo.smaz_vse;
var z:longint;
  begin
    bls:=false;bl1:=0;bl2:=0;
    for z:=0 to vetp do begin dispose(vety[z]);vety[z]:=nil; end;
    vetp:=-1;
    aktualizujpozici(self);
    if refr_en=0 then pab.Refresh;
  end;

function  Tjakomemo.vloz_vetu(te:string;bpi,bpo:Tcolor;pom:longint;kam:longint):boolean;
var z:longint;
  begin
    result:=true;
    if kam<0 then begin result:=false;exit;end;
    if kam>vetp+1 then begin result:=false;exit;end;
    if vetp>=mpv then begin Result:=false;exit end; {!!!}
    
    inc(vetp);
    for z:=vetp downto kam+1 do vety[z]:=vety[z-1];
    new(vety[kam]);
    vety[kam]^.te:=te;
    vety[kam]^.bpi:=bpi;
    vety[kam]^.bpo:=bpo;
    vety[kam]^.pom:=pom;
    
    aktualizujpozici(self);
    if autoscroll then
      begin
        poskroluj(kam);
      end;
    if refr_en=0 then pab.Refresh;
  end;


function  Tjakomemo.prepis_vetu(te:string;bpi,bpo:Tcolor;pom:longint;kam:longint;msk:longint):boolean;
var z:longint;
  begin
    result:=true;
    if kam<0 then begin result:=false;exit;end;
    if kam>vetp then begin result:=false;exit;end;

    if msk and 1=1 then vety[kam]^.te:=te;
    if msk and 2=2 then vety[kam]^.bpi:=bpi;
    if msk and 4=4 then vety[kam]^.bpo:=bpo;
    if msk and 8=8 then vety[kam]^.pom:=pom;

//    aktualizujpozici(self);
    if autoscroll then
      begin
        z:=kam;
        if z>sbs.Max then z:=sbs.Max else z:=kam;
        sbs.Position:=z;
      end;
    if refr_en=0 then pab.Refresh;
  end;



function  Tjakomemo.cti_vetu(var te:string;var bpi,bpo:Tcolor;var pom:longint;kam:longint):boolean;
  begin
    result:=true;
    if kam<0 then begin result:=false;exit;end;
    if kam>vetp then begin result:=false;exit;end;

    te:=vety[kam]^.te;
    bpi:=vety[kam]^.bpi;
    bpo:=vety[kam]^.bpo;
    pom:=vety[kam]^.pom;
end;



function Tjakomemo.posledniveta:longint;
  begin
    posledniveta:=vetp;
  end;


procedure Tjakomemo.aktualizujpozici(sender:Tobject);
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


procedure Tjakomemo.jmonpaint(sender:Tobject);
var z,x:longint;
    b1,b2:TColor;
  begin
   if refr_en<>0 then exit;
    x:=sbs.Position;
    for z:=0 to pab.height div vyska_radku do
      begin
        if x+z<=vetp then
          begin
            if jevbloku(z+x) then
              begin b1:=barva_bloku_pis;b2:=barva_bloku_pod;end
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


procedure Tjakomemo.sbscrll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
  begin
//    jmonpaint(sender);
    if refr_en=0 then pab.Invalidate;
  end;

procedure Tjakomemo.zakaz_kresleni(st:boolean);
  begin
    if st then
      inc(refr_en)
    else
      if refr_en>0 then
        dec(refr_en)
        else
        refr_en:=0;
    if refr_en=0 then pab.Refresh;
  end;



procedure Tjakomemo.mys_pohyb(Sender: TObject; Shift: TShiftState; X,Y: Integer);
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
  
procedure Tjakomemo.mys_zmack(Sender: TObject;Button: TMouseButton;Shift: TShiftState; X,Y: Integer);
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

procedure Tjakomemo.mys_zmack1(Sender: TObject;Button: TMouseButton;Shift: TShiftState;X,Y: Integer );
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


procedure Tjakomemo.generuj_klik(Sender: TObject; X,Y: Integer;Button: TMouseButton;Shift: TShiftState);
var z:longint;
  begin
    z:=my_2_index(my);
    if oncclick<>nil then oncclick(z,mb,ms);
  end;


function Tjakomemo.my_2_index(z:longint):longint;
  begin
    z:=(z-2) div vyska_radku+sbs.position;

    if z>vetp then z:=vetp;
    if z<0 then z:=0;
    result:=z;
  end;

function Tjakomemo.jevbloku(num:longint):boolean;
var z,x,c:longint;
  begin
    z:=bl1;
    x:=bl2;
    if z>x then begin c:=z;z:=x;x:=c end;
    result:=bls and (num>=0) and (num<=vetp) and (num>=z) and (num<=x);
  end;



procedure Tjakomemo.mys_dclick_in(sender:Tobject);
var z:longint;
  begin
    z:=my_2_index(my);
    if oncdblclick<>nil then oncdblclick(z,mb,ms);
  end;
  

procedure Tjakomemo.nastav_font(f:Tfont);
  begin
    pab.font:=f;
    pab.canvas.Font:=f;
    vyska_radku:=pab.canvas.TextHeight('WTIjpyg')+4;
     // nebo si tu pridejte dalsi pismenka, ktere jsou nejak moc nad/pod prumer normalni vysky

    aktualizujpozici(nil);
    if refr_en=0 then pab.Refresh;
  end;

procedure Tjakomemo.poskroluj(kam:longint);
var z:longint;
  begin
        if kam<0 then kam:=0;
        if kam>vetp then kam:=vetp;
        z:=kam;
        if z>sbs.Max then z:=sbs.Max else z:=kam;
        sbs.Position:=z;
        if refr_en=0 then pab.Refresh;
  end;

procedure Tjakomemo.mys_WheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
   sbs.position:=sbs.position+1;
   pab.refresh;
end;
procedure Tjakomemo.mys_Wheelup(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
   sbs.position:=sbs.position-1;
   pab.refresh;
end;



function Tjakomemo.hledej(co:string;odkud:longint;smer_dolu:boolean;cely_radek:boolean):longint;
var z,v:longint;

    function je_to_tento(kery:longint):boolean;
      begin
        if (kery>=0) and (kery<=vetp) then
          begin
            if cely_radek then
                je_to_tento:=co=vety[kery]^.te
              else
                je_to_tento:=pos(co,vety[kery]^.te)<>0;
          end
          else je_to_tento:=false;
      end;
  begin
    z:=odkud;
    if smer_dolu then v:=1 else v:=-1;
    while (z>=0) and (z<=vetp) and (not je_to_tento(z)) do z:=z+v;
    if je_to_tento(z) then hledej:=z else hledej:=-1;
  end;




end.

