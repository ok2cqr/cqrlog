unit aziloc;

interface

function VratLokator(pozx,pozy : Currency) : String;
function PrevedNaStupne(cislo : Currency) : String;

implementation

uses Math,SysUtils;
var //s:string;
    x,y:string;
    //f1:text;

function getloc(xs,ys:string):string;
var p1,p2,p3,p4,p5,p6:integer;
    s:string;
    x,y:real;
 function sttor(s:string):real;
 var uk,i,ko:integer;
     j:array[1..3] of integer;
     s1:string;
 begin
  s1:=s;
  for uk:=1 to 3 do
  begin
   i:=pos('''',s1);
   if i=0 then i:=length(s1)+1;
   val(copy(s1,1,i-1),j[uk],ko);
   s1:=copy(s1,i+1,Length(s1)-i);
  end;{for uk}
  sttor:=j[1]+j[2]/60+j[3]/3600;
 end;{sttor}

begin
 x:=sttor(xs)+90;
 y:=sttor(ys)+180;
 p1:=trunc(y/20);
 p2:=trunc(x/10);
 p3:=trunc((y-p1*20)/2);
 p4:=trunc(x-p2*10);
 p5:=trunc((y-p1*20-p3*2)*12);
 p6:=trunc((x-p2*10-p4)*24);
 s:=chr(p1+65)+chr(p2+65)+chr(p3+48);
 s:=s+chr(p4+48)+chr(p5+65)+chr(p6+65);
 getloc:=s;
end;{getloc}

function s15(s:string):string;
var s2:string;
    ko:integer;
begin
 s2:=s;
 for ko:=Length(s) to 15 do s2:=s2+' ';
 s15:=s2;
end;{s15}

function PrevedNaStupne(cislo : Currency) : String;
var
  stupne,minuty,vteriny : Integer;
begin
  stupne  := Floor(Cislo);
  minuty  := Floor((cislo-stupne)*60);
  vteriny := Round((((cislo-stupne)*60)-minuty)*100);
  Result  := IntToStr(stupne)+''''+IntToStr(minuty)+''''+IntToStr(vteriny);
end;


function VratLokator(pozx,pozy : Currency) : String;
begin
  x := PrevedNaStupne(pozx);
  y := PrevedNaStupne(pozy);
  Result := getloc(x,y)
end;
{
label wend;
begin
 clrscr;
 writeln('Prepocet souradnic na WWL    (konec = Enter)      Soubor: LOC.TXT');
 assign(f1,'LOC.TXT');
 rewrite(f1);
 if ioresult<>0 then halt;
 repeat
   window(1,3,80,5);
   clreol;
   write(#13,'Ronobezka (ss''mm''ss) :');
   readln(x);
   if x='' then goto wend;
   clreol;
   write(#13,'Polednik  (ss''mm''ss) :');
   readln(y);
   if y='' then goto wend;
   window(1,6,80,25);
   gotoxy(1,20);
   writeln(s15(x),s15(y),getloc(x,y));
   writeln(f1,getloc(x,y));
 until false;
wend:
 close(f1);}
end.
