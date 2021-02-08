(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


(*

  v.02 ... zvyseno max_delka_popisu=250
           zmenen typ v najdis_s2 - parametr presne slysi na 3 hodnoty.
  v.02 ... increased max_description_length = 250
            changed type in najdis_s2 - the parameter hears exactly 3 values.

  v.01 ... zacalo cislovani (po incidentu s verzemi :-) )
           najdis_s2 z nastavenym presne=true nema hledat znacky zacinajici na '='
  v.01 ... numbering started (after the version incident :-))
            najdis_s2 with set exactly = true does not search for tags starting with '='
*)

unit znacmech;

// zakomentuj nasledujici radek, bude Ti fungovat "debug" :-P  Mti.
//// comment next line, "debug" will work for you :-P Mti.
//{$define nuse_ddata}


interface
uses odbec;




const cplac=1000000;
const popisu_max=10000;
      znacek_max=100000;
      max_delka_znacky=40;
      max_delka_popisu=250;
      max_delka_data=15;

type
	string_mdd=string[max_delka_data];
	string_mdp=string[max_delka_popisu];
	string_mdz=string[max_delka_znacky];

const
      datum_od_default:string_mdd='1945/01/01';
      datum_do_default:string_mdd='2050/01/01';
      //debouk=0;

Type Tplac=array[0..Cplac] of byte;
     Pplac=^Tplac;


const kjpvp=12; // pocet polozek v popisku  number of items in the label
      c_pop_misto=0;
      c_pop_zkrat=1;
      c_pop_neco1=2;
      c_pop_neco2=3;
      c_pop_neco3=4;
      c_pop_neco4=5;
      c_pop_neco5=6;
      c_pop_neco6=7;
      c_pop_neco7=8;
      c_pop_datod=9;
      c_pop_datdo=10;
      c_pop_necoA=11;


const c_pres_dlouhe=0;
      c_pres_kratke=1;
      c_pres_strikt=2;


Type Tpopis=record
       text:string_mdp;
       ha:byte;
       jpo:array[0..kjpvp] of byte;
     end; 
     Ppopis=^Tpopis;

     Tpopisy=array[0..popisu_max] of Ppopis;
     Ppopisy=^Tpopisy;



Type Tpohash=record { protoze mi Hlozek nedal nerozbalene data, musim si popisy tridit sam ... uz sice neni pravda (predelaval jsem vstupy :-/ ), ale nicemu to tam nevadi
                    because Hlozek didn't give me unpacked data, I have to sort the descriptions myself ... it's no longer true (I remade the entries: - /), but nothing matters there }
       po:Ppopis;
       da:pointer; 
     end;
const kolikhasulog=8;  { kolik bitu budeou mit hashe .. male cislo udela maly pocet ruznych 
			vysledku a zdrzovat budou dlouhe retezce , velke cislo zase zpusobi 
                        prilis velke pametove naroky. Kolem 8-10 ocekavam rozumny prumer

                        how many bits will they have hashes .. the small number will make a small number
                        of different ones result and will delay long chains, will cause a large number again
                        too large memory requirements. Around 8-10 I expect a reasonable average }
      kolikhasu=(1 shl kolikhasulog)-1;

Type Ppohash=^Tpohash;
     Tpohase=array[0..kolikhasu] of Ppohash;


     Tznac=record
       text:string_mdz;
       texb:string_mdz; // pro trideni  for sorting
       popi:Ppopis;
     end;
     Pznac=^Tznac;

     Tznacky=array[0..znacek_max] of Pznac;
     Pznacky=^Tznacky;


type Tchyby=object	{ udelej si potomka, ktery prepise "hlaseni" a tam si delej co chces
			 tento objekt je uplne prazdny , urceny jen k podedeni

                        make a child who will rewrite "report" and do what you want there
                        this object is completely empty, intended only for feeding }

       constructor	init;
       destructor	done;virtual;
       procedure	hlaseni(vzkaz,kdo:string);virtual;
     end;    
     Pchyby=^Tchyby;


type Tseznam=object 
     
	  procedure dump(pref:string); {pref - prefix nazvu souboruu. file name }

	  constructor init(naz:string;de:Pchyby); {naz - soubor k nacteni ; de - debouk - pokud chces dostavat hlaseni o chybach/debug, udelej si potomka Tchyby, jinak tu predavej nil
          naz - file to                            load; de - debouk - if you want to get a bug / debug report, make a descendant of Tchyba, otherwise sell nil here }
	  destructor  done;


          function znacky_posledni:longint; // posledni znacka. last brand

          function znacka_text(zn:longint):string_mdz; // vraci znack dle indexu. returns tags by index
          function znacka_popis(zn:longint):string_mdp; // vraci popis znacky dle indexu. returns a description of the brand according to the index

          function znacka_popis_ex(zn,i:longint):string_mdp;

	  function znacka_sedidatum(i:longint;var datum:string_mdd):boolean; 
          // je znacka platna pro tento datum? 
          // (YYYY/MM/DD - musi sedet presne znaky, nebo se s tim nedomluvite)
          // * - plati vzdy , ! neplati nikdy
          // samotny rok je mensi jak cele datum. (2006 < 2006/01/01)

          // is the tag valid for this date?
           // (YYYY / MM / DD - must fit exact characters or don't talk to it)
           // * - always applies,! never pays
           // the year itself is smaller than the whole date. (2006 <2006/01/01)

      function najdis_s2(var co:string_mdz;datum:string_mdd;presne:integer):longint; 
              { co - hledana znacka ; datum, kdy ma platit; 

                presne: c_pres_dlouhe=0;   co muze byt delsi nez nalezena znacka.
                        c_pres_kratke=1;   tak musi mit nalezena znacka stejnou delku jak "co".
                        c_pres_strikt=2;  jako kratke, ale BEZ = na zacatku.

                co - the mark sought; the date when I should be paid;

                 exactly: c_pres_dlouhe = 0; which can be longer than the brand found.
                         c_pres_kratke = 1; so the mark found must be the same length as "what".
                         c_pres_strikt = 2; as short, but WITHOUT = at the beginning.
              }


	private // a sem ani necum :-) ... jen pro silne povahy. and I'm not even here :-) ... only for strong characters

	  popisy:Ppopisy;
	  popisy_posl:longint; // posledni pouzity;  last used;
	  znacky:Pznacky;
	  znacky_posl:longint;

	  nazev_souboru:string;
	  debouk2:Pchyby;
	  ziju:boolean;
          hase:Tpohase;

          nejdelsi_popis:longint;
          nejdelsi_znacka:longint;


	  procedure debouk(aaa:String);
	  function pridej_popis(po:shortstring):Ppopis;
	  function pridej_znacku(zn:shortstring;po:Ppopis):Pznac;
	  procedure pridej_znacku_ex(zn:shortstring;po:Ppopis);
	  procedure odesli(zco,co:string);
          procedure odesli2(zco,co:string);
	  procedure setrid_znacky;
	
	  function najdihas(var s:string):Ppopis;
	  function pridejhapopis(s:string):Ppopis;

	  {nasledujici funkce vraci v "po" stejnou hodnotu jako samy
          hledani nebere ohledy na "po", pouze jej nastavi ; "dalsi" pouzivaji po jako aktualni pozici
	  vsechny ... pokud nenajdou pozadovane, vraci -1

          the following functions return in "after" the same value as themselves
           the search does not take into account "after", it only sets it; "Next" is used after as the current position
          all ... if not found required, returns -1 }
	  function znacka_najdikam_s(var cc1:string_mdz;var po:longint):longint; {a zjisti, kam patri "cc". and find out where "cc" belongs }
 		// string musi byt KRATSI nebo alespon stejny jak polozka v tabulce ... :-(
                // string must be KRATSI or at least the same as the item in the table ... :-(
	  function znacka_dalsi_s(var cc1:string_mdz;var po:longint):longint;

          function uznejregex2(var zn:string_mdz;izn:longint;co:char):boolean;
          function pasuje(var zn,co:string_mdz):boolean;
          function presnejsivyznam(var novy,stary:string_mdz):boolean;
          function delkaznacky(izn:longint):longint;




     end;
    Pseznam=^Tseznam;


implementation

{$ifndef nuse_ddata}
uses dData;
{$endif}


function nehash(var aaa:string):longint;
var z,x:longint;
  begin
    z:=1;
    x:=0;
    while z<=length(aaa) do
      begin
        x:=(x shl 1)+37;
        x:=x+ord(aaa[z]);
        x:=x+(x shr kolikhasulog);
        x:=x and (kolikhasu);
        inc(z);
      end;
    nehash:=x;
  end;

  
procedure Tseznam.debouk(aaa:string);
  begin
    if debouk2<>nil then debouk2^.hlaseni(aaa,'Tseznam - '+nazev_souboru);
  end;


function Tseznam.znacky_posledni:longint; // posledni znacka  last brand
  begin
    if not ziju then begin debouk('E02: Neziju  - last marks ');znacky_posledni:=-1;exit;end
    else
     znacky_posledni:=znacky_posl;
  end;

function Tseznam.znacka_text(zn:longint):string_mdz; // vraci znack dle indexu returns tags by index
  begin                                              // returns a description of the brand according to the index
    if not ziju then begin debouk('E03: Neziju - mark text ');znacka_text:='';exit;end;
    if (zn>=0) and (zn<=znacky_posl) then znacka_text:=znacky^[zn]^.text
    else begin debouk('E04: znacka_text - out of range');znacka_text:='XXXXXXXX';end;

  end;
function Tseznam.znacka_popis(zn:longint):string_mdp; // vraci popis znacky dle indexu
  begin                                               //returns a description of the brand according to the index
    if not ziju then begin debouk('E05: Neziju - out of range');znacka_popis:='';exit;end;
    if (zn>=0) and (zn<=znacky_posl) then znacka_popis:=znacky^[zn]^.popi^.text
    else begin debouk('E06: znacka_popis - out of range');znacka_popis:='XXXXXXXX';end;
  end;

function Tseznam.znacka_popis_ex(zn,i:longint):string_mdp;
var z,x:longint;
  begin
    if not ziju then begin debouk('E05: Neziju - mark_description_ex ');znacka_popis_ex:='';exit;end;
    if (zn>=0) and (zn<=znacky_posl) and (i>=0) and (i<kjpvp) then 
      begin
        z:= znacky^[zn]^.popi^.jpo[i];if z<>1 then inc(z);
        x:= znacky^[zn]^.popi^.jpo[i+1];

        if (z>=x) then 
            begin
              if i=c_pop_datod then znacka_popis_ex:=datum_od_default
              else
              if i=c_pop_datdo then znacka_popis_ex:=datum_do_default
              else
              znacka_popis_ex:='';
            end
          else znacka_popis_ex:=copy(znacky^[zn]^.popi^.text,z,znacky^[zn]^.popi^.jpo[i+1]-z)
      end
    else begin debouk('E06: znacka_popis_ex - out of range');znacka_popis_ex:='XXXXXXXX';end;
  end;




function Tseznam.znacka_sedidatum(i:longint;var datum:string_mdd):boolean; 
{datum muze byt jeden znak * nebo ! a nebo CELE datum ve tvaru YYYY/MM/DD 
 * zajisti, ze funkce vrati VZDY true.
 ! zajisti, ze funkce vrati VZDY false.

 Pokud zadate jen rok, tak tento je vzdy mensi nez stejny rok s mesicem/dnem
 ... kdyby ste to chteli orypavat... taky.

 the date can be one character * or! and or FULL date in the form YYYY / MM / DD
  * ensure that the function returns ALWAYS true.
  ! ensure that the function always returns false.

  If you enter only a year, this is always less than the same year with month / day
  ... if you want to crack it ... too.
}
  begin
    if not ziju then begin debouk('E07: Neziju - sedidatum');znacka_sedidatum:=false;exit;end;

    if (i>=0) and (i<=znacky_posl) then
      begin
        if datum='*' then znacka_sedidatum:=true 
        else   
        if datum='!' then znacka_sedidatum:=false 
        else   
          znacka_sedidatum:=(znacka_popis_ex(i,c_pop_datod)<=datum) and (znacka_popis_ex(i,c_pop_datdo)>=datum);
      end
    else begin debouk('E08: sedidatum - out of range');znacka_sedidatum:=false; end;
  end;
    
function Tseznam.najdihas(var s:string):Ppopis;
var c:longint;
    hus:Ppohash;
  begin
    c:=nehash(s);
    hus:=hase[c];
    while (hus<>nil) and (hus^.po^.text<>s) do hus:=hus^.da;
    if hus<>nil then najdihas:=hus^.po else najdihas:=nil;
  end;

function Tseznam.pridejhapopis(s:string):Ppopis;
var c:longint;
    p:Ppopis;
    h,j:Ppohash;

  begin
    p:=najdihas(s);
    if p=nil then
      begin
        c:=nehash(s);
        h:=hase[c];
        if h<>nil then 
          while h^.da<>nil do h:=h^.da;
        p:=pridej_popis(s);
	if p<>nil then
          begin
            new(j);
	    j^.po:=p;
            j^.da:=nil;
	    if h<>nil then 
              h^.da:=j
              else
              hase[c]:=j;
          end;
      end;
    pridejhapopis:=p;
  end;

function Tseznam.pridej_popis(po:shortstring):Ppopis;
var z,x,c,v:longint;
  begin
    pridej_popis:=nil;
    if not ziju then begin pridej_popis:=nil;exit;end;

    inc(popisy_posl);
    if popisy_posl>popisu_max then 
      begin 
        debouk('E09: PLACE!!! - descriptions');
	dec(popisy_posl);
	ziju:=false;
      end
    else
    begin
      if nejdelsi_popis<length(po) then 
        begin
          nejdelsi_popis:=length(po);
          if nejdelsi_popis>max_delka_popisu-2 then debouk('E13 - recalculated length of the description : '+po);
        end;
      new(popisy^[popisy_posl]);
     
      z:=1;x:=0;popisy^[popisy_posl]^.jpo[x]:=0;
      while (z<=length(po)) and (x<kjpvp) do 
      begin
        if po[z]='|' then begin inc(x);popisy^[popisy_posl]^.jpo[x]:=z;end;
        inc(z);
      end;
      z:=popisy^[popisy_posl]^.jpo[x]; // ukazuju na posledni '|'   indicate the last '|'
      c:=z;
      while (c<length(po)) and (po[c]<>'=') do inc(c);
      // c ukazuje na rovnitko (nebo na konec textu)  c points to an equal sign (or to the end of the text)
      if po[c]<>'=' then 
         begin 
           c:=length(po)+1;
           v:=popisy^[popisy_posl]^.jpo[c_pop_neco6];
           po:=po+'='+copy(po,v+1,popisy^[popisy_posl]^.jpo[c_pop_neco6+1]-v-1);
         end;
      v:=z;
      while (v<c) and (po[v]<>'-') do inc(v);
      // v ukazuje na '-' nebo na '='.   v points to '-' or '='.
      popisy^[popisy_posl]^.jpo[x+1]:=v;
      popisy^[popisy_posl]^.jpo[x+2]:=c;
      popisy^[popisy_posl]^.jpo[x+3]:=length(po)+1;


      popisy^[popisy_posl]^.text:=po;
      pridej_popis:=popisy^[popisy_posl];


    end;
  end;

function Tseznam.pridej_znacku(zn:shortstring;po:Ppopis):Pznac;
  begin
    if not ziju then begin pridej_znacku:=nil;exit;end;
    inc(znacky_posl);
    if znacky_posl>znacek_max then 
      begin 
        debouk('E10:PLACE!!! - brands');
        pridej_znacku:=nil;
      end
    else
      begin
        if length(zn)>nejdelsi_znacka then 
          begin  
            nejdelsi_znacka:=length(zn);
            if length(zn)>max_delka_znacky-2 then debouk('E14 -brand length exceeded: '+zn);
          end;
	new(znacky^[znacky_posl]);
        znacky^[znacky_posl]^.text:=zn;
	znacky^[znacky_posl]^.texb:=string2bec(zn);
        znacky^[znacky_posl]^.popi:=po;
    
        pridej_znacku:=znacky^[znacky_posl];
      end;
  end;

procedure Tseznam.pridej_znacku_ex(zn:shortstring;po:Ppopis); 
  begin
    while (length(zn)>0) and (zn[1]=' ') do zn:=copy(zn,2,length(zn));
    while (length(zn)>0) and (zn[length(zn)]=' ') do zn:=copy(zn,1,length(zn)-1);
    if length(zn)=0 then exit;
    
    if (pos(' ',zn)=0) then pridej_znacku(zn,po)
      else
        begin
	    pridej_znacku(copy(zn,1,pos(' ',zn)-1),po);
	    pridej_znacku_ex(copy(zn,pos(' ',zn)+1,length(zn)),po);
	end;
  end;

procedure Tseznam.odesli2(zco,co:string);
var 
    pr,za:string;
    po:Ppopis;
  begin
    if not ziju then exit;
    if pos('|',co)>0 then 
      begin
        pr:=zco;
        za:=copy(co,pos('|',co)+1,length(co));
	po:=pridejhapopis(za);
	pridej_znacku_ex(pr,po);
      end;
  end;


procedure Tseznam.odesli(zco,co:string);
var z,x,c:integer;
    aaa,sss,ddd,fff:shortstring;
  begin
    if not ziju then exit;
    z:=length(co);
    while(z>1) and (co[z]<>'|') do dec(z); {z bude ukazovat na posledni '|'z will point to the last '|'}

    aaa:=copy(co,z+1,length(co));
    c:=pos(' ',aaa);
    if c<>0 then
      begin
        sss:=copy(co,1,z);
        x:=pos('=',aaa);if x<>0 then ddd:=copy(aaa,x,length(aaa)) else begin ddd:='';x:=length(aaa)+1;end;
        fff:=copy(aaa,1,c-1);
	odesli2(zco,sss+fff+ddd);
        fff:=copy(aaa,c+1,x-c-1);
	odesli2(zco,sss+fff+ddd);
      end
      else odesli2(zco,co);
  end;


procedure Tseznam.dump(pref:string);
var z:longint;
    sou:textfile;
  begin
    if not ziju then begin debouk('E11: Neziju - dump');exit;end;
    system.assign(sou,pref+'zn.txt');
    system.rewrite(sou);
    for z:=0 to znacky_posl do writeln(sou,z,'  ',znacky^[z]^.text);
    system.close(sou);
    system.assign(sou,pref+'po.txt');
    system.rewrite(sou);
    for z:=0 to popisy_posl do writeln(sou,z,'  ',popisy^[z]^.text);
    system.close(sou);

    system.assign(sou,pref+'zn-komp.txt');
    system.rewrite(sou);
    for z:=0 to znacky_posl do
      begin
        writeln(sou,z,'  ',znacky^[z]^.text);
        writeln(sou,'       ',znacky^[z]^.texb);
        if znacky^[z]^.popi<>nil then 
          writeln(sou,'       ',znacky^[z]^.popi^.text);
      end; 
    system.close(sou);

  end;



function Tseznam.znacka_najdikam_s(var cc1:string_mdz;var po:longint):longint; {a zjisti, kam patri "vec"and find out where the "thing" belongs }
var z,x,c:longint;
    cc:string_mdz;
  begin
    po:=-1;
    znacka_najdikam_s:=-1;
    if not ziju then exit;
    cc:=string2bec(cc1);    
    z:=0;
    x:=znacky_posl;
    repeat
    c:=(z+x) div 2;
    if (znacky^[c]^.texb>cc) then
        x:=c
      else
        z:=c;
    until z>=x-1;
    inc(z);
    while (z>0) and (znacky^[z-1]^.texb>=cc) do 
     begin  
       dec(z);
     end;
    if znacky^[z]^.texb<cc then po:=-1
      else po:=z;
    znacka_najdikam_s:=po;
  end;


function Tseznam.znacka_dalsi_s(var cc1:string_mdz;var po:longint):longint;
var lcc:longint;
    cc:string_mdz;
  begin
    if (po<0) or (po>znacky_posl) then 
      begin
        po:=-1;
        //znacka_dalsi_s:=po;  mark_next_s: = po;
      end;
    inc(po);
    cc:=string2bec(cc1);
    lcc:=length(cc);
    if lcc>0 then inc(cc[lcc]);
    if (po<=znacky_posl) and (znacky^[po]^.texb<=cc) then znacka_dalsi_s:=po
      else
        begin
          po:=-1;
          znacka_dalsi_s:=po;
        end;
  end;



constructor Tseznam.init(naz:string;de:Pchyby);
var z,x:longint;
    sou:file;
    q:Pplac;
    vq:longint;
    aaa,sss:string;
  begin
    nejdelsi_znacka:=0;
    nejdelsi_popis:=0;
    debouk('M1: init zac');
    ziju:=true;
    debouk2:=de;
    fillchar(hase,sizeof(hase),0);
    new(popisy);fillchar(popisy^,sizeof(popisy^),0);
    popisy_posl:=-1;
    new(znacky);fillchar(znacky^,sizeof(znacky^),0);
    znacky_posl:=-1; 
    nazev_souboru:=naz;
    system.assign(sou,nazev_souboru);
    {$I-}system.reset(sou,1);{$I+}
    if ioresult<>0 then 
      begin ziju:=false;debouk('E01: File not found :-( '+nazev_souboru);end
    else
    begin
    vq:=filesize(sou);
    getmem(q,vq); 
    blockread(sou,q^,vq); 
    sss:='';x:=0;aaa:='';
    for z:= 0 to vq-1 do
      begin
        if q^[z]=10 then begin odesli(aaa,sss);x:=0;aaa:='';sss:='' end
        else
        if (q^[z]=ord('|')) and (x=0) then 
            begin
              x:=1;
              aaa:=sss;sss:='|';
            end
        else
        if q^[z]>31 then sss:=sss+chr(q^[z]);

        if length(sss)>250 then 
          begin
            writeln(length(aaa),'  ',length(sss));
            writeln(aaa,'  ',sss);
          end;
      end;
    if length(sss)>0 then begin odesli(aaa,sss);sss:='' end;
    freemem(q,vq); 
    
    system.close(sou);

    debouk('M1: init trid');


    setrid_znacky;


    debouk('M1: init kon');
    end;{if ioresult ... else }
  end;

destructor Tseznam.done;
var z:longint;
    h,h1:Ppohash;
  begin
    debouk('M2: done zac');
//    writeln('NDZ: ',nejdelsi_znacka);
//    writeln('NDP: ',nejdelsi_popis);
// writeln ('NDZ:', longest_tag);
// writeln ('NDP:', longest_description);
    for z:=0 to znacky_posl-1 do if znacky^[z]<>nil then dispose(znacky^[z]); 
    for z:=0 to popisy_posl-1 do if popisy^[z]<>nil then dispose(popisy^[z]);  

    for z:=0 to kolikhasu do
      begin
        h:=hase[z];
        while h<>nil do
          begin
            h1:=h^.da;
            dispose(h);
            h:=h1;
          end;
      end;

    dispose(znacky);
    dispose(popisy);
    debouk('M2: done kon');
  end;






procedure Tseznam.setrid_znacky;
var z,x:longint;
    ve,ve2,ve3:Pznacky;

      function znacky_jevet(z1,z2:Pznac):boolean;
        begin
          if (z1=nil) or (z2=nil) then debouk('nil -brands jevet ');
          znacky_jevet:=z1^.texb>z2^.texb;
	end;

      procedure presunmaly(pozice,krok:longint);
      var p1,p2,p3:longint;
          k1,k2:longint;
        begin
          p1:=pozice;
          k1:=p1+krok;
          p2:=pozice+krok;
          k2:=p2+krok;
          p3:=pozice;
          if k2>znacky_posl then
            k2:=znacky_posl+1;
          if p2>znacky_posl then
            while p3<=znacky_posl do begin ve2^[p3]:=ve^[p1];inc(p1);inc(p3) end
          else
          while (p1<k1) or (p2<k2) do
            begin
              if (p1>=k1) then
                 begin ve2^[p3]:=ve^[p2]; inc(p2);inc(p3) end
              else
              if (p2>=k2) then
                 begin ve2^[p3]:=ve^[p1]; inc(p1);inc(p3) end
              else
              if (ve^[p1]<>nil) and (ve^[p2]<>nil) then
                  if (znacky_jevet(ve^[p1],ve^[p2])) then
                    begin ve2^[p3]:=ve^[p2]; inc(p2);inc(p3) end
                  else
                    begin ve2^[p3]:=ve^[p1]; inc(p1);inc(p3) end
                else
                  begin
                    ve2^[p3]:=nil;
                  end;
            end;
        end;
  begin
    ve:=znacky;
    new(ve2); fillchar(ve2^,sizeof(ve2^),0);
    z:=1;
    while z<=znacky_posl do
      begin
        if ve^[znacky_posl]=nil then
          ve^[znacky_posl]:=nil;
        x:=0;
        while x<=znacky_posl do
          begin
            presunmaly(x,z);
            x:=x+z*2;
          end;
            ve3:=ve2;
            ve2:=ve;
            ve:=ve3;
        z:=z*2;
      end;
    dispose(ve2);
    znacky:=ve;
  end;







function Tseznam.uznejregex2(var zn:string_mdz;izn:longint;co:char):boolean;
var z:longint;
    aa:char;
    ven:boolean;
  begin
//    z:=izn;while (z<length(zn)) and (zn[z]<>']') do inc(z);
//    aaa:=copy(zn,izn+1,z-1);
    ven:=false;
    z:=izn+1; // kde sme ve znacce (+1 -> zavorky nezeru)   where we are in the sign (+1 -> I don't eat zavorky)
    aa:=#255; // posledni porovnany znak ... jen aby tam neco bylo. last character compared ... just to have something there.

    while (ven=false) and (zn[z]<>']') and (z<=length(zn)) do
      begin
        if zn[z]='-' then 
	    begin
	      inc(z); // minus necteme...
	      if (co>=aa) and (co<=zn[z]) then ven:=true;
  	    end
	  else
   	   if (co=zn[z]) then ven:=true;
	  aa:=zn[z]; // ulozim si posledni znak :-)  I put my last sign :-)   I put my last sign :-) And put my last sign :-)
	inc(z);
      end;
    uznejregex2:=ven;
  end;



function Tseznam.pasuje(var zn,co:string_mdz):boolean;
var z,x:longint;
    vr:boolean;
    lzn,lco:longint;
  begin
    
    z:=1;x:=1; // pozice v zn,co  position in zn, co
    lzn:=length(zn);
    lco:=length(co);
    // zacina to rovnitkem - zbytek musi byt stejny.
    // starts with an equation - the rest must be the same.
    if zn[1]='=' then 
      begin pasuje:=copy(zn,2,lzn)=co;exit; end; 


    vr:=true; // presumpce neviny :-) Dokud to nevyvratim, musim tvrdit, ze pasuje...
              // obcac,pokud to prestane pasovat to shazuju exitem zrovna... tak bacha :-(
              // presumption of innocence :-) Until I refute it, I must say that it fits ...
               // obcac, if it stops to fit, I'm crashing the exit just ... so watch out :-(

   while (vr) and (z<=lzn) do
     begin
       // zacka skoncila- nasleduji libovolne znaky - tomu vyhovi cokoliv :-)
       // the end is over - I follow any characters - anything will do it :-)
       if z>lzn then begin {writeln('pres-z ',zn);}pasuje:=true;exit;end;  { ale asi to tu nedojde :-) - while to chyti. but it probably won't happen here :-) - while it catches }

       // hledany text kratsi jak znacka? - tato to nebude. - exit
       // searched text shorter as a brand? - It won't be this one. - exit
       if (x>lco) and (lzn>0) then 
         begin {writeln('pres-x ',zn);} pasuje:=false;exit; end;

       // ok ... tak testujeme prvni znak  // ok ... so we test the first character
       case zn[z] of
         '#': if not( co[x] in ['0'..'9']) then begin pasuje:=false;exit;end; // cislo, ze? number, right?:-) Exit!
         '%','?': ; // libovolny znak... hm  // any character ... hm
         '[': if not uznejregex2(zn,z,co[x]) then begin pasuje:=false;exit end // exit!
               else while (z<lzn) and (zn[z]<>']') do inc(z);
         else if zn[z]<>co[x] then begin pasuje:=false;exit end;
       end; {case}
       inc(z);inc(x);
     end;{while}	      
    pasuje:=vr;
  end;{func.pasuje}


function Tseznam.delkaznacky(izn:longint):longint;
var z,x:integer;
    pa:string_mdz;
    lpa:longint;
  begin
    z:=1;x:=0;
    pa:=znacky^[izn]^.text;
    lpa:=length(pa);
    if (lpa>0) and (pa[1]='=') then inc(z);
    while (z<=lpa) do
      begin
        if pa[z]='[' then while (z<=lpa) and (pa[z]<>']') do inc(z);
        inc(z);inc(x);
      end;
    delkaznacky:=x;
  end;

function Tseznam.presnejsivyznam(var novy,stary:string_mdz):boolean;

  function porovnejznak(aa,ss:char):longint;
  var b:longint;
      a1,s1:boolean;
    begin
      a1:=(aa in ['[',']','#','%','?']);
      s1:=(ss in ['[',']','#','%','?']);
      if (a1) and (not (s1)) then b:=-1
      else
      if (not (a1)) and (s1) then b:=1
      else
        b:=0;
      porovnejznak:=b;
    end;

var z,x,v:longint;
    lno,lst:longint;
  begin
    if (novy[1]='=') and (stary[1]<>'=') then begin presnejsivyznam:=true;exit;end;
    v:=0;z:=0;x:=0;
    lno:=length(novy);
    lst:=length(stary);
    while (v=0) and (z<lno) and (x<lst) do
      begin
        v:=porovnejznak(novy[z],stary[x]);
        if novy[z]='[' then while (z<lno) and (novy[z]<>']') do inc(z);
        if stary[x]='[' then while (x<lst) and (stary[x]<>']') do inc(x);
        inc(z);inc(x);
      end;
    presnejsivyznam:=v=1;
  end;



function Tseznam.najdis_s2(var co:string_mdz;datum:string_mdd;presne:integer):longint; 
              { co - hledana znacka ; datum, kdy ma platit; 

                presne: c_pres_dlouhe=0;   co muze byt delsi nez nalezena znacka.
                        c_pres_kratke=1;   tak musi mit nalezena znacka stejnou delku jak "co".
                        c_pres_strikt=2;  jako kratke, ale BEZ = na zacatku.

               co - the mark sought; the date when I should be paid;

                 exactly: c_pres_dlouhe = 0; which can be longer than the brand found.
                         c_pres_kratke = 1; so the mark found must be the same length as "what".
                         c_pres_strikt = 2; as short, but WITHOUT = at the beginning.
              }
var nas1:longint;
    exa:boolean;

     procedure zizz(var co1,co2:string_mdz);
     var z:longint;
         te:string_mdz;
         dz,dzn:longint;
       begin
       if (znacka_najdikam_s(co1,z)<>-1) then
         repeat
           {$ifndef nuse_ddata}
           if dmData.DebugLevel >=3 then
           begin
             Write(znacky^[z]^.text,'  ,');
             //Writeln(znacky^[z]^.popi.Text);
           end;
           {$endif}
           if pasuje(znacky^[z]^.text,co) and (znacka_sedidatum(z,datum)) then
             begin
                te:=znacky^[z]^.text;
                dz:=delkaznacky(z);

                if (presne<>c_pres_strikt) or (te[1]<>'=') then
                begin
                  if (presne=c_pres_dlouhe) or (dz=length(co)) then
                    if  (te[1]='=') then begin exa:=true;nas1:=z; end
                       else
                    if nas1=-1 then nas1:=z
                       else
                       begin
                         dzn:=delkaznacky(nas1);
                         if dz>dzn then nas1:=z
                           else
                         if (dz=dzn) 
                           and (presnejsivyznam(te,znacky^[nas1]^.text)) then nas1:=z;
                       end;                  
                 end; // if (not presne) or (te[1]<>'=')
             end;
  
         until not ((znacka_dalsi_s(co2,z)<>-1) and not exa)
         else{ writeln('He didnt find it ')};
       end;

var 
    aaa,sss:string_mdz;
    lco:longint;
  begin
    if not ziju then begin debouk('E12: Neziju - Im not looking ');najdis_s2:=-1;exit;end;

    {$ifndef nuse_ddata}
    if dmData.DebugLevel >=3 then
      Writeln('in znacmech');
    {$endif}
    nas1:=-1;
    exa:=false;

    lco:=length(co);
   if lco>=2 then 
     begin
       aaa:=copy(co,1,2);
       sss:=aaa;
       zizz(aaa,sss);

       aaa:=copy(co,1,1);
       sss:=aaa+'?';
       aaa:=aaa+'[';
       zizz(aaa,sss);
     end;

   if (lco=1) or (nas1=-1) then 
     begin
      aaa:=copy(co,1,1);
      sss:=aaa;
      zizz(aaa,sss);
     end;

{ nezkousej udelat totez pro delku 3 ... :-) ... uz to tu bylo.
don't try to do the same for length 3 ... :-) ... it was already here }
    najdis_s2:=nas1;  
    {$ifndef nuse_ddata}
    if dmData.DebugLevel >=3 then
      Writeln('znacmech - end');
    {$endif}
  end;

constructor	Tchyby.init;
  begin
    { }
  end;
destructor	Tchyby.done;
  begin
    { }
  end;
procedure	Tchyby.hlaseni(vzkaz,kdo:string);
  begin
    { }
  end;

end.
