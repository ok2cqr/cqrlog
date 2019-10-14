unit azidis3;

interface

uses sysutils;

const dz=6365;


procedure VzdalenostAAzimut(loc1,loc2 : String;var azim,qrb : String);
procedure LocToCoordinate(loc : String; var Latitude, Longitude : Real);

implementation

var   dis:real;
      //l1,l2:string;
      c,d,e,f:real;

      
function acs(Arg:real):real;
begin
  if Arg=0 then ACs:=Pi/2
           else if Arg<0 then ACs:=Pi+ArcTan(Sqrt(1-Sqr(Arg))/Arg)
                         else ACs:=ArcTan(Sqrt(1-Sqr(Arg))/Arg);
end;{acs}

function tan(Arg:real):real;
begin
  tan:=sin(arg)/cos(arg);
end;{tan}

function delx(inpt:string):real;
begin
 delx:=(10*ord(inpt[2])+ord(inpt[4])+ord(inpt[6])/24-700.70833)*pi/180;
end;{delx}                                                  {333...}

function dely(inpt:string):real;
begin
 dely:=(20*ord(inpt[1])+ord(inpt[3])*2+ord(inpt[5])/12-1401.4166)*pi/180;
end;{dely}                                                    {666...}

function azimut(s:string):real;
var az,ss,dx:real;
begin
 e:=delx(s);
 f:=dely(s);
 dis:=dz*acs(cos(e)*cos(c)+sin(c)*sin(e)*cos(f-d)); {QRB=dis}
 ss:=d-f;
 dx:=sin(c)*tan(e-pi/2)+cos(c)*cos(ss);
 az:=-180/pi*Arctan(sin(ss)/(dx));
 if dx<0 then az:=az+180;
 if az>360 then az:=az-360;
 if az<0 then az:=360+az;
 azimut:=az;
end;{azimut}

function isloc(var s:string):boolean;
var i:integer;
begin
 isloc:=true;
 if length(s)=6 then
 begin
  for i:=1 to 6 do
  begin
   s[i]:=upcase(s[i]);
   case i of
    1,2,5,6:case s[i] of
               'A'..'X':;
               else isloc:=false;
            end;{case s[i]}
        3,4:case s[i] of
               '0'..'9':;
               else isloc:=false;
            end;{case s[i]}
   end;{case i}
  end;{for}
 end{if}
 else isloc:=false;
end;{isloc}

procedure VzdalenostAAzimut(loc1,loc2 : String;var azim,qrb : String);
begin
  loc1:=Upcase(loc1);
  loc2:=Upcase(loc2);

  if ((not isloc(loc1)) or (not isloc(loc2))) then
  begin
    azim := '';
    qrb :=  '';
    exit  
  end;
  c := delx(loc1);
  d := dely(loc1);
  azim  := IntToStr(round(azimut(loc2)));
  qrb   := IntToStr(round(dis));
end;
procedure LocToCoordinate(loc : String; var Latitude, Longitude : Real);
begin
  loc:=Upcase(loc);
  Latitude  := dely(loc);
  Longitude := delx(loc)
end;
{---main---}
{begin
 repeat write('LOC1: ');readln(l1) until isloc(l1);
 c:=delx(l1);
 d:=dely(l1);
 repeat
  write('LOC2: ');readln(l2);
  if isloc(l2) then writeln('AZI=',azimut(l2):5:1,'ø, QRB=',round(dis),' km');
 until l2=''; }
end.
