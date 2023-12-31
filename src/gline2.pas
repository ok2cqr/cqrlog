unit gline2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, GraphType,LCLType, IntfGraphics, FPimage;
  

const obsimax=2048;
      obvymax=obsimax shr 1;

const obsi:longint=400;
      obvy:longint=200;

var
      obsi2,obvy2:extended;

type  Tplac=array[0..obsimax*obvymax-1] of byte;

var    sintab:array[0..1023] of extended;
       costab:array[0..1023] of extended;

       sqtab1:array[-1000 .. 0] of byte;
       sqtab2:array[0 .. 1000] of byte;
       asintab:array[-10010..10010] of longint;



type
  t_coord = record
    longitude, latitude, radius: extended; (* lambda, beta, R *)
    rektaszension, declination: extended;  (* alpha, delta *)
    parallax: extended;
    elevation, azimuth: extended;          (* h, A *)
    end;

const body_popis_max=30;
type Tcarobod=record
       typ:byte; // 0 - nothing, 1 square, 2 square points, 3 cross points
       x1,y1,x2,y2:extended;
       popis:string[body_popis_max];    //bodu_popis = points_list
       barva:Tcolor;                    //barva = color
       vel_bodu:longint;                //vel_bodu ??  bodu = point
     end;
const body_max=128;

type TGC_point=record
       La1,Lo1,La2,Lo2 : double;
     end;
var star_time_u:extended;

type
  Tgrayline=object
      GC_LWidth : integer;  //plot line wdth;
      GB_LWidth : integer;
      GC_SP_Color : TColor;
      GC_LP_Color : TColor;
      GC_BE_Color : TColor;
      const GC_Points_Max = 5000;
      constructor init(naz_sou:string);
      destructor done;
      procedure VypocitejSunClock(cas:Tdatetime);
      procedure kresli(r:Trect;can:Tcanvas); {kresli = line  draw in the required dimensions }
      procedure kresli1(x1,y1:longint;can:Tcanvas); {draw 1: 1, the input is "only" the upper left corner}
      
      procedure jachcucaru(en:boolean;x1,y1,x2,y2:extended);

      procedure body_add(typ:byte;x1,y1,x2,y2:extended;popis:string;barva:tcolor;vel_bodu:longint);
      procedure body_smaz;

  //    procedure GC_line_width(LWidth:Integer);      //set plot line width
      procedure GC_line_part(x1,y1,x2,y2:double);   //add ShortPath point
      procedure GC_Lline_part(x1,y1,x2,y2:double);  //add LongPath point
      procedure GC_Bline_part(x1,y1,x2,y2:double);  //add Beam point
      procedure GC_line_clear(what:integer=-1);      //clear S&L and Beam Path points

    private
      nrd:boolean; //needs to redraw (a new calculation has been made)

      chcipni:boolean;
      ziju:boolean;
      poslednicas:Tdatetime;

      q:Tplac;
      declin:longint;
      sideclin,codeclin:extended;
      harr:array[0..obsimax] of longint;
      rold:Trect;
      
      carax1,carax2,caray1,caray2:extended;
      caraen:boolean;
      
      obrp:TLazIntfImage; //  template ... 1-of-disk template ... 1-of-disk
      obrA,obrT:TLazIntfImage;   //picture - draw everything here

      obmap: TBitmap;
      body:array[0..body_max] of Tcarobod;
      body_poc:longint;

      GC_point:array[0..GC_points_Max] of TGC_point;  //ShortPath array
      GCpointer:longint;
      GC_Lpoint:array[0..GC_points_Max] of TGC_point; //LongPath array
      GCLpointer:longint;
      GC_Bpoint:array[0..GC_points_Max] of TGC_point; //LongPath array
      GCBpointer:longint;

      LP        : integer;

      function calc_horizontalx(var coord:t_coord; date:TDateTime; z:longint;latitude: extended):longint;
  end;
  Pgrayline=^Tgrayline;


implementation


uses ah_math,vsop;

{ Tfgline }

const
  julian_offset: extended = 0;
  AU=149597869;             (* astronomical unit in km *)
  mean_lunation=29.530589;  (* Mean length of a month *)
  tropic_year=365.242190;   (* Tropic year length *)
  earth_radius=6378.15;     (* Radius of the earth *)






function put_in_360(x:extended):extended;
begin
  result:=x-round(x/360)*360;
  while result<0 do result:=result+360;
  end;

function julian_date(date:TDateTime):extended;
begin
  julian_date:=julian_offset+date
  end;

procedure calc_epsilon_phi(date:TDateTime; var delta_phi,epsilon:extended);
(*$ifndef low_accuracy *)
const
  (*@/// arg_mul:array[0..30,0..4] of shortint = (..); *)
  arg_mul:array[0..30,0..4] of shortint = (
     ( 0, 0, 0, 0, 1),
     (-2, 0, 0, 2, 2),
     ( 0, 0, 0, 2, 2),
     ( 0, 0, 0, 0, 2),
     ( 0, 1, 0, 0, 0),
     ( 0, 0, 1, 0, 0),
     (-2, 1, 0, 2, 2),
     ( 0, 0, 0, 2, 1),
     ( 0, 0, 1, 2, 2),
     (-2,-1, 0, 2, 2),
     (-2, 0, 1, 0, 0),
     (-2, 0, 0, 2, 1),
     ( 0, 0,-1, 2, 2),
     ( 2, 0, 0, 0, 0),
     ( 0, 0, 1, 0, 1),
     ( 2, 0,-1, 2, 2),
     ( 0, 0,-1, 0, 1),
     ( 0, 0, 1, 2, 1),
     (-2, 0, 2, 0, 0),
     ( 0, 0,-2, 2, 1),
     ( 2, 0, 0, 2, 2),
     ( 0, 0, 2, 2, 2),
     ( 0, 0, 2, 0, 0),
     (-2, 0, 1, 2, 2),
     ( 0, 0, 0, 2, 0),
     (-2, 0, 0, 2, 0),
     ( 0, 0,-1, 2, 1),
     ( 0, 2, 0, 0, 0),
     ( 2, 0,-1, 0, 1),
     (-2, 2, 0, 2, 2),
     ( 0, 1, 0, 0, 1)
                   );
  (*@\\\*)
  (*@/// arg_phi:array[0..30,0..1] of longint = (); *)
  arg_phi:array[0..30,0..1] of longint = (
     (-171996,-1742),
     ( -13187,  -16),
     (  -2274,   -2),
     (   2062,    2),
     (   1426,  -34),
     (    712,    1),
     (   -517,   12),
     (   -386,   -4),
     (   -301,    0),
     (    217,   -5),
     (   -158,    0),
     (    129,    1),
     (    123,    0),
     (     63,    0),
     (     63,    1),
     (    -59,    0),
     (    -58,   -1),
     (    -51,    0),
     (     48,    0),
     (     46,    0),
     (    -38,    0),
     (    -31,    0),
     (     29,    0),
     (     29,    0),
     (     26,    0),
     (    -22,    0),
     (     21,    0),
     (     17,   -1),
     (     16,    0),
     (    -16,    1),
     (    -15,    0)
    );
  (*@\\\*)
  (*@/// arg_eps:array[0..30,0..1] of longint = (); *)
  arg_eps:array[0..30,0..1] of longint = (
     ( 92025,   89),
     (  5736,  -31),
     (   977,   -5),
     (  -895,    5),
     (    54,   -1),
     (    -7,    0),
     (   224,   -6),
     (   200,    0),
     (   129,   -1),
     (   -95,    3),
     (     0,    0),
     (   -70,    0),
     (   -53,    0),
     (     0,    0),
     (   -33,    0),
     (    26,    0),
     (    32,    0),
     (    27,    0),
     (     0,    0),
     (   -24,    0),
     (    16,    0),
     (    13,    0),
     (     0,    0),
     (   -12,    0),
     (     0,    0),
     (     0,    0),
     (   -10,    0),
     (     0,    0),
     (    -8,    0),
     (     7,    0),
     (     9,    0)
    );
  (*@\\\*)
(*$endif *)
var
  t,omega: extended;
(*$ifdef low_accuracy *)
  l,ls: extended;
(*$else *)
  d,m,ms,f,s: extended;
  i: longint;
(*$endif *)
  epsilon_0,delta_epsilon: extended;
begin
  t:=(julian_date(date)-2451545.0)/36525;

  (* longitude of rising knot *)
  omega:=put_in_360(125.04452+(-1934.136261+(0.0020708+1/450000*t)*t)*t);

(*$ifdef low_accuracy *)
  (*@/// delta_phi and delta_epsilon - low accuracy *)
  (* mean longitude of sun (l) and moon (ls) *)
  l:=280.4665+36000.7698*t;
  ls:=218.3165+481267.8813*t;

  (* correction due to nutation *)
  delta_epsilon:=9.20*cos_d(omega)+0.57*cos_d(2*l)+0.10*cos_d(2*ls)-0.09*cos_d(2*omega);

  (* longitude correction due to nutation *)
  delta_phi:=(-17.20*sin_d(omega)-1.32*sin_d(2*l)-0.23*sin_d(2*ls)+0.21*sin_d(2*omega))/3600;
  (*@\\\*)
(*$else *)
  (*@/// delta_phi and delta_epsilon - higher accuracy *)
  (* mean elongation of moon to sun *)
  d:=put_in_360(297.85036+(445267.111480+(-0.0019142+t/189474)*t)*t);

  (* mean anomaly of the sun *)
  m:=put_in_360(357.52772+(35999.050340+(-0.0001603-t/300000)*t)*t);

  (* mean anomly of the moon *)
  ms:=put_in_360(134.96298+(477198.867398+(0.0086972+t/56250)*t)*t);

  (* argument of the latitude of the moon *)
  f:=put_in_360(93.27191+(483202.017538+(-0.0036825+t/327270)*t)*t);

  delta_phi:=0;
  delta_epsilon:=0;

  for i:=0 to 30 do begin
    s:= arg_mul[i,0]*d
       +arg_mul[i,1]*m
       +arg_mul[i,2]*ms
       +arg_mul[i,3]*f
       +arg_mul[i,4]*omega;
    delta_phi:=delta_phi+(arg_phi[i,0]+arg_phi[i,1]*t*0.1)*sin_d(s);
    delta_epsilon:=delta_epsilon+(arg_eps[i,0]+arg_eps[i,1]*t*0.1)*cos_d(s);
    end;

  delta_phi:=delta_phi*0.0001/3600;
  delta_epsilon:=delta_epsilon*0.0001/3600;
  (*@\\\*)
(*$endif *)

  (* angle of ecliptic *)
  epsilon_0:=84381.448+(-46.8150+(-0.00059+0.001813*t)*t)*t;

  epsilon:=(epsilon_0+delta_epsilon)/3600;
end;


function delphi_date(juldat:extended):TDateTime;
begin
  delphi_date:=juldat-julian_offset;
  end;

(*@/// function star_time(date:TDateTime):extended;            // degrees *)
function star_time(date:TDateTime):extended;
var
  jd, t: extended;
  delta_phi, epsilon: extended;
begin
  jd:=julian_date(date);
  t:=(jd-2451545.0)/36525;
  epsilon:=0;   delta_phi:=0;
  calc_epsilon_phi(date,delta_phi,epsilon);
  result:=put_in_360(280.46061837+360.98564736629*(jd-2451545.0)+
                     t*t*(0.000387933-t/38710000)+
                     delta_phi*cos_d(epsilon) );
end;


procedure calc_geocentric(var coord:t_coord; date:TDateTime);
var
  epsilon: extended;
  delta_phi: extended;
  alpha,delta: extended;
begin
  calc_epsilon_phi(date,delta_phi,epsilon);
  coord.longitude:=put_in_360(coord.longitude+delta_phi);

  (* geocentric coordinates *)
{   alpha:=arctan2_d(cos_d(epsilon)*sin_d(o),cos_d(o)); }
{   delta:=arcsin_d(sin_d(epsilon)*sin_d(o)); }
  alpha:=arctan2_d( sin_d(coord.longitude)*cos_d(epsilon)
                   -tan_d(coord.latitude)*sin_d(epsilon)
                  ,cos_d(coord.longitude));
  delta:=arcsin_d( sin_d(coord.latitude)*cos_d(epsilon)
                  +cos_d(coord.latitude)*sin_d(epsilon)*sin_d(coord.longitude));

  coord.rektaszension:=alpha;
  coord.declination:=delta;
  end;

procedure calc_coord(date: TDateTime; obj_class: TCVSOP; var l,b,r: extended);
var
  obj: TVSOP;
begin
  obj:=NIL;
  try
    obj:=obj_class.Create;
    obj.date:=date;
    r:=obj.radius;
    l:=obj.longitude;
    b:=obj.latitude;
    obj.DynamicToFK5(l,b);
  finally
    obj.free;
    end;
  l:=put_in_360(rad2deg(l));  (* rad -> degree *)
  b:=rad2deg(b);
  end;


procedure earth_coord(date:TdateTime; var l,b,r: extended);
begin
  calc_coord(date,TVSOPEarth,l,b,r);
  end;


function sun_coordinate(date:TDateTime):t_coord;
var
  l,b,r: extended;
  lambda,t: extended;
begin
  earth_coord(date,l,b,r);
  (* convert earth coordinate to sun coordinate *)
  l:=l+180;
  b:=-b;
  (* conversion to FK5 *)
  t:=(julian_date(date)-2451545.0)/365250.0*10;
  lambda:=l+(-1.397-0.00031*t)*t;
  l:=l-0.09033/3600;
  b:=b+0.03916/3600*(cos_d(lambda)-sin_d(lambda));
  (* aberration *)
  l:=l-20.4898/3600/r;
  (* correction of nutation - is done inside calc_geocentric *)
{   calc_epsilon_phi(date,delta_phi,epsilon); }
{   l:=l+delta_phi; }
  (* fill result and convert to geocentric *)
  result.longitude:=put_in_360(l);
  result.latitude:=b;
  result.radius:=r*AU;
  calc_geocentric(result,date);
  end;




function Tgrayline.calc_horizontalx(var coord:t_coord; date:TDateTime; z:longint;latitude: extended):longint;
var
  h: longint;
  la:longint;

begin


  h:=harr[z];
(*
  coord.azimuth:=0;{arctan2_d(sin_d(h),
                           cos_d(h)*sin_d(latitude)-
                           tan_d(coord.declination)*cos_d(latitude) );{}
*)

//la:=round(latitude*512) div 180 and 1023;

  //workaround because of bug in fpc 3.0.0 and above
  la:=round(latitude*512) div 180;
  while(la<0) do la:=la+1024;
  while(la>1023) do la:=la-1024;

  calc_horizontalx:= asintab[round((sintab[la]*sideclin+costab[la]*codeclin*costab[h])*999)];

end;

constructor Tgrayline.init(naz_sou:string);
var e,z:longint;
    a:extended;
    co : Integer;
    //xptr:^byte;
    
    ImgFormatDescription: TRawImageDescription;
    obrtmp:TLazIntfImage;
  begin
  chcipni:=false;
  caraen:=false;



  obrtmp:=TLazIntfImage.Create(0,0);
  obrtmp.LoadFromFile(naz_sou);

  obsi:=obrtmp.Width;
  obvy:=obrtmp.Height;

  obrtmp.free;

  obmap:=TBitmap.Create;

  
 // obrp1:=
  obrp:=TLazIntfImage.Create(0,0);
  ImgFormatDescription.Init_BPP32_B8G8R8_BIO_TTB(obsi,obvy);
  obrp.DataDescription:=ImgFormatDescription;
  obrp.LoadFromFile(naz_sou);


  obra:=TLazIntfImage.Create(0,0);
  ImgFormatDescription.Init_BPP32_B8G8R8_BIO_TTB(obsi,obvy);
  obrA.DataDescription:=ImgFormatDescription;

  obrA.CopyPixels(obrP);
  //xptr:=obrA.GetDataLineStart(0);


  obmap.Width:=obrp.Width;
  obmap.Height:=obrp.Height;

  obrT:=obmap.CreateIntfImage;
  // convert the content from the very specific to the current format
  obrT.CopyPixels(obrA);
  obmap.LoadFromIntfImage(obrT);


  obsi2:=360/obsi;
  obvy2:=180/obvy;


  if obsi>obsimax then begin chcipni:=true;end;
  if obvy>obvymax then begin chcipni:=true;end;

 for z:=0 to 1023 do
   begin
     a:=sin(z*pi/512);
     sintab[z]:=a;
     //costab[(z-256) and 1023]:=a;
     //workaround because of bug in fpc 3.0.0 and above
     co:=z-256;if co<0 then co:=co+1024;
     costab[co]:=a
   end;

{ fillchar(sqtab1[-901],100,20);}

 for z:=0 to 901 do
   begin
     e:=-round(sqrt(z)*2.84604989415154)+100+10;
     if e<2 then sqtab1[-z]:=2 else sqtab1[-z]:=e;
   end;

 fillchar(sqtab2[50],855,199);
 for z:=0 to 50 do
     sqtab2[z]:= round(sqrt(sqrt(z))*56.2341325190)+100;

//for c:=0 to 100 do
 for z:=0 to 10010 do
   begin
     asintab[z]:=round(arcsin(z/1000)*1800/pi);
     asintab[-z]:=-asintab[z];
   end;

  body_poc:=0;
  GCpointer:=0;
  GCLpointer:=0;

  poslednicas:=now-1000000;
  nrd:=false;
end;

destructor Tgrayline.done;
  begin
    obra.Free;
    obrp.Free;
    obrt.Free;
    obmap.Free;

  end;

procedure tgrayline.VypocitejSunClock(cas:Tdatetime);
const ko=10;
var z,c:longint;
    ce:extended;
    datum : TDateTime;
    datum2:extended;
    pos1: T_Coord;
    vere,vere1:longint;

           function vr1(z,x:longint):longint;
             begin
              vr1:=calc_horizontalx(pos1,datum,z,(x-obvy shr 1)*obvy2);
//              if vr1>100 then vr1:=200;
//              if vr1<80 then vr1:=80;
//              vr1:=random(1000)-500;
             end;


            procedure put(x1,y1:longint;b:byte);
              begin
                q[x1+y1*obsi]:=b;
              end;

            function get(x1,y1:longint):byte;
            var e2:longint;
                //e,
                o,g:longint;
              begin
                o:=x1+y1*obsi;
                if q[o]=0 then
                begin
                  e2 :=vr1(x1,y1);
                ///if e2<0 then e:=-1 else e:=1;
                  if e2=0 then g:=100
                    else
                      if e2<0 then
                        g:=sqtab1[e2]
                          else
                            g:=sqtab2[e2];
                  if g>199 then g:=199;
                  if g<=0 then g:=1;
                  q[o]:=g and 254;
                  get:=g and 254;
                end
                 else get:=q[o];
            end;


            procedure prolez(x1,y1,x2,y2,u:longint);
            var c,v,z,x:longint;
                px,py:longint;

              begin
                if chcipni then exit;
                if u<0 then exit;
                //if u>7 then Application.ProcessMessages;
                v:=get(x1,y1);
                if (v=get(x1,y2)) and (v=get(x2,y1)) and (v=get(x2,y1)) and (u<3) then

                for x:=y1 to y2 do
                  begin
                    c:=x*obsi+x1;
                    for z:=x1 to x2 do
                      begin
                        {put(z,x,v);}
                        q[c]:=v;
                        inc(c);
                      end
                    end
                  else
                    begin
                      if x2-x1>2 then px:=(x2+x1) div 2
                        else if x2-x1=2 then px:=x1+1 else px:=x1;
                      if y2-y1>2 then py:=(y2+y1) div 2
                        else if y2-y1=2 then py:=y1+1 else py:=y1;

            {          py:=(y2+y1) div 2;}
                      if (x2-x1>2) and (y2-y1>2) then
                         begin
                           prolez(x1,y1,px,py,u-1);
                           prolez(x1,py+1,px,y2,u-1);
                           prolez(px+1,y1,x2,py,u-1);
                           prolez(px+1,py+1,x2,y2,u-1);
                         end
                           else
                             if y2-y1>2 then
                               begin
                                 prolez(x1,y1,x2,py,u-1);
                                 prolez(x1,py+1,x2,y2,u-1);
                               end
                                 else
                                   if x2-x1>2 then
                                     begin
                                       prolez(x1,y1,px,y2,u-1);
                                       prolez(px+1,y1,x2,y2,u-1);
                                     end
                                   else
                                     begin
                                       for z:=x1 to x2 do
                                         for x:=y1 to y2 do get(z,x);
                                     end;
                    end;

              end;


            procedure prolez1(x1,y1,x2,y2,u:longint);
            //var z,x,c:integer;
                //dx,dy:longint;
              begin
                //dx:=x2-x1;
//                for z:=0 to dx
              end;
begin
  if chcipni then exit;
  if round(poslednicas*24*60)=round(cas*24*60) then exit;
  poslednicas:=cas;
 // datum := now+strtofloat(edit1.Text)/24-3.5/24;
    datum := cas -3.5/24;
 {  for c:=0 to 23 do}
  c:=0;
  ce:=(datum-trunc(datum))*24+c;
  datum2:=(datum-trunc(datum)+ce/24)*360;
  begin
     fillchar(q,obvy*obsi,0);
     pos1:=sun_coordinate(trunc(datum));
     //declin:=round(pos1.declination*512) div 180 and 1023;
     //workaround because of bug in fpc 3.0.0 and above
     declin:=round(pos1.declination*512) div 180;
     while(declin<0) do declin:=declin+1024;
     while(declin>1023) do declin:=declin-1024;

     sideclin:=sintab[declin];
     codeclin:=costab[declin];
     star_time_u:=star_time(datum);
     ziju:=true;
     for z:=0 to obsi-1 do
     begin
       //harr[z]:=(round(star_time_u-pos1.rektaszension-(datum2+z*obsi2)) shl 9 div 180) and 1023;
       //workaround because of bug in fpc 3.0.0 and above
       harr[z]:=(round(star_time_u-pos1.rektaszension-(datum2+z*obsi2)) *512 div 180);
       while(harr[z]<0) do harr[z]:=harr[z]+1024;
       while(harr[z]>1023) do harr[z]:=harr[z]-1024
     end;
//(round(star_time_u-coord.rektaszension-(datum2+z*obsi2)) shl 9 div 180) and 1023;
     
     vere:=0;
     vere1:=obsi;
     while vere1>2 do
       begin
         vere1:=vere1 shr 1;
         inc(vere);
       end;
     prolez(0,0,obsi-1,obvy-1,vere);
     ziju:=false;
   end; { for c ?}
   nrd:=true;
end;


procedure Tgrayline.kresli(r:Trect;can:Tcanvas);      //kresli =draw
var z,x,c:longint;
    ze,zez,ze2,zez2,ze2s,zez2s:extended;
    LWidht:integer;
var

    xptr:^byte;

//-----------------------------------------------------------
    procedure cmarniu(x1,y1,x2,y2:longint);
      begin
          {  can.pen.color:=clblack;
            can.pen.Width:=5;
            can.moveto(x1,y1);
            can.lineto(x2,y2); }
            can.pen.Width:=GC_LWidth;
            Case LP of
                  0: can.pen.color:=GC_SP_Color;
                  1: can.pen.color:=GC_LP_Color;
                  2: Begin
                      can.pen.color:=GC_BE_Color;
                      can.pen.Width:=GB_LWidth;;
                     end;
            end;

            can.moveto(x1,y1);
            can.lineto(x2,y2);
      end;

//-----------------------------------------------------------
    procedure cmarni(x1,y1,x2,y2:extended;roh:boolean);
    var dx,dy,ax,ay:extended;
      begin
        if (abs(x1-x2)>180) and (roh) then
          begin
            can.pen.Style:=psdash;
            cmarni(x1+360,y1,x2,y2,false);
            cmarni(x1,y1,x2-360,y2,false);
            can.pen.Style:=pssolid;
            cmarni(x1,y1,x2,y2,false);
          end
          else
          begin
            dx:=r.right-r.left+1;
            dy:=r.bottom-r.top+1;

            ax:=(r.left+r.right)/2;
            ay:=(r.top+r.bottom)/2;

            cmarniu(round(ax+round(x1*dx/360)),round(ay+round(y1*dy/180)),
                    round(ax+round(x2*dx/360)),round(ay+round(y2*dy/180)));
          end;
      end;

//-----------------------------------------------------------
    procedure bod_cmarniu(x1,y1,x2,y2:longint;b:Tcarobod);
    var vb:longint;
      begin
        vb:=b.vel_bodu;
        if b.typ=3 then
        begin
          can.pen.color:=clblack;
          can.pen.Width:=5;
          can.moveto(x1-vb,y1-vb);
          can.lineto(x1+vb,y1+vb);
          can.moveto(x1-vb,y1+vb);
          can.lineto(x1+vb,y1-vb);
          can.pen.color:=b.barva;
          can.pen.Width:=2;
          can.moveto(x1-vb,y1-vb);
          can.lineto(x1+vb,y1+vb);
          can.moveto(x1-vb,y1+vb);
          can.lineto(x1+vb,y1-vb);
        end;
        if b.typ=2 then
        begin
          can.pen.color:=clblack;
          can.pen.Width:=5;
          can.moveto(x1-vb,y1-vb);
          can.lineto(x1-vb,y1+vb);
          can.lineto(x1+vb,y1+vb);
          can.lineto(x1+vb,y1-vb);
          can.lineto(x1-vb,y1-vb);
          can.pen.color:=b.barva;
          can.pen.Width:=2;
          can.moveto(x1-vb,y1-vb);
          can.lineto(x1-vb,y1+vb);
          can.lineto(x1+vb,y1+vb);
          can.lineto(x1+vb,y1-vb);
          can.lineto(x1-vb,y1-vb);
        end;
        if b.typ=1 then
        begin
          can.pen.color:=clblack;
          can.pen.Width:=5;
          can.moveto(x1,y1);
          can.lineto(x2,y2);
          can.pen.color:=b.barva;
          can.pen.Width:=2;
          can.moveto(x1,y1);
          can.lineto(x2,y2);
        end;
      end;

//-----------------------------------------------------------
    procedure bod_cmarni(b:Tcarobod);
    var dx,dy,ax,ay:extended;
      begin
            dx:=r.right-r.left+1;
            dy:=r.bottom-r.top+1;

            ax:=(r.left+r.right)/2;
            ay:=(r.top+r.bottom)/2;

            bod_cmarniu(round(ax+round(b.x1*dx/360)),round(ay+round(b.y1*dy/180)),
                    round(ax+round(b.x2*dx/360)),round(ay+round(b.y2*dy/180)),b);
      end;

//-----------------------------------------------------------

begin
  if chcipni then exit;

  if ((r.left-r.right<>rold.left-rold.right) or (r.top-r.bottom<>rold.top-rold.bottom))
     and (r.right-r.left+1>obsi) then nrd:=true;

  if nrd then
    begin

       obrA.CopyPixels(obrP);
       //ze2:=0.79;   // specify how the dark image will be - R and G
       //zez2:=0.90;   // specify how the dark image will be - blue channel

       ze2  := 1.7;
       zez2 := 1.0;

       if ze2<=0 then ze2:=0.0000001;
       if zez2<=0 then zez2:=0.0000001;
       ze2s:=100/ze2*2-200;
       zez2s:=100/zez2*2-200;
        for x:=0 to obvy-1 do
          begin
            c:=(obvy-1-x)*obsi;
            xptr:=obrA.GetDataLineStart(x);
            for z:=0 to obsi-1 do
              begin
               if q[c]<100 then
                 begin
    //               ze:=((q[c]-ze2s)+100+(100-ze2s))/200;
    //               zez:=((q[c]-zez2s)+100+(100-zez2s))/200;
                   ze:= (q[c]-ze2s)/200;
                   zez:=(q[c]-zez2s)/200;
                   if ze<=0 then ze:=0;

                   xptr^:=round(longint(xptr^)*(zez));
                   inc(xptr);
                   xptr^:=round(longint(xptr^)*ze);
                   inc(xptr);
                   xptr^:=round(longint(xptr^)*ze);
                   inc(xptr);
                   //xptr^:=round(longint(xptr^)*ze); // alfa
                   inc(xptr);
{
                   ba:=imcache.colors[z,x];
                   ba.red:=round(longint(ba.red)*ze);
                   ba.green:=round(longint(ba.green)*ze);
                   ba.blue:=round(longint(ba.blue)*(zez));
                   imcache.colors[z,x]:=ba;
}
                 end
                  else inc(xptr,4);
                inc(c);
              end;
          end;
     obrT.CopyPixels(obrA);
     obmap.LoadFromIntfImage(obrT);

   end;

//r.right:=r.left;
  if r.left=r.right then
    begin
      r.Right:=r.left+obsi-1;
      r.bottom:=r.top+obvy-1;
      Can.Draw(r.left,r.top,obmap);
    end
    else
      Can.StretchDraw(r,obmap);

  if caraen then     //caraen = do
    begin
      LP:=0;
      cmarni(carax1,caray1,carax2,caray2,true);
//    can.Font.Color:=clBlack;
//    can.TextOut(10,10,' '+inttostr(round(carax1))+':'+inttostr(round(caray1))+' ');
//    can.TextOut(10,30,' '+inttostr(round(carax2))+':'+inttostr(round(caray2))+' ');
    end;
 if GCLpointer > 0 then
    begin
     LP:=1; //LongPath color plotting
     for z:=0 to GCLpointer-1 do
          cmarni(GC_Lpoint[z].La1, GC_Lpoint[z].Lo1, GC_Lpoint[z].La2, GC_Lpoint[z].Lo2, false);
    end;
 if GCpointer > 0 then
    begin
     LP:=0; //ShortPath color plotting
     for z:=0 to GCpointer-1 do
          cmarni(GC_point[z].La1, GC_point[z].Lo1, GC_point[z].La2, GC_point[z].Lo2, false);
    end;

 if GCBpointer > 0 then
  Begin
     LP:=2; //Beam color plotting
     for z:=0 to GCBpointer-1 do
            cmarni(GC_Bpoint[z].La1, GC_Bpoint[z].Lo1, GC_Bpoint[z].La2, GC_Bpoint[z].Lo2, false);
  end;

  for z:=0 to body_poc-1 do
    begin
       bod_cmarni(body[z]);
    end;
    nrd:=false;
end;

procedure Tgrayline.kresli1(x1,y1:longint;can:Tcanvas);   //kresli =draw
var r:Trect;
  begin
  if chcipni then exit;
    r.left:=x1;
    r.right:=x1;
    r.top:=y1;
    r.bottom:=y1;
    kresli(r,can);
  end;

procedure Tgrayline.jachcucaru(en:boolean;x1,y1,x2,y2:extended);     //jachcucaru = ?????
  begin
  if chcipni then exit;    //chcipni = "die"
    caraen:=en;           //cara = "line"
    if  (abs(y1)>90) or (abs(y2)>90) then
      begin
        caraen:=false;exit;
      end;
    while x1>180 do x1:=x1-360;
    while x1<-180 do x1:=x1+360;
    while x2>180 do x2:=x2-360;
    while x2<-180 do x2:=x2+360;
    
    if x1>x2 then
      begin
        carax1:=x2;
        carax2:=x1;
        caray1:=y2;
        caray2:=y1;
      end
      else
      begin
        carax1:=x1;
        carax2:=x2;
        caray1:=y1;
        caray2:=y2;
      end;
  end;

procedure Tgrayline.body_add(typ:byte;x1,y1,x2,y2:extended;popis:string;barva:tcolor;vel_bodu:longint);  //barva = color
  begin
    if chcipni then exit;
    if body_poc<body_max-1 then
      begin
        body[body_poc].typ:=typ;
        body[body_poc].x1:=x1;
        body[body_poc].y1:=y1;
        body[body_poc].x2:=x2;
        body[body_poc].y2:=y2;
        body[body_poc].popis:=copy(popis,1,body_popis_max);
        body[body_poc].barva:=barva;
        body[body_poc].vel_bodu:=vel_bodu;
        inc(body_poc);
      end;
  end;

procedure Tgrayline.body_smaz;   //smaz = delete
  begin
    body_poc:=0;
  end;

procedure Tgrayline.GC_line_part(x1,y1,x2,y2:double);

Begin
    if chcipni then exit;    //chcipni = "die"
    if GCpointer < GC_Points_max then
     begin
      GC_point[GCpointer].La1:=x1;
      GC_point[GCpointer].Lo1:=y1;
      GC_point[GCpointer].La2:=x2;
      GC_point[GCpointer].Lo2:=y2;
      inc(GCpointer);
     end;
end;
procedure Tgrayline.GC_Lline_part(x1,y1,x2,y2:double);

Begin
    if chcipni then exit;    //chcipni = "die"
    if GCLpointer < GC_Points_max then
     begin
      GC_Lpoint[GCLpointer].La1:=x1;
      GC_Lpoint[GCLpointer].Lo1:=y1;
      GC_Lpoint[GCLpointer].La2:=x2;
      GC_Lpoint[GCLpointer].Lo2:=y2;
      inc(GCLpointer);
     end;
end;
procedure Tgrayline.GC_Bline_part(x1,y1,x2,y2:double);

Begin
    if chcipni then exit;    //chcipni = "die"
    if GCBpointer < GC_Points_max then
     begin
      GC_Bpoint[GCBpointer].La1:=x1;
      GC_Bpoint[GCBpointer].Lo1:=y1;
      GC_Bpoint[GCBpointer].La2:=x2;
      GC_Bpoint[GCBpointer].Lo2:=y2;
      inc(GCBpointer);
     end;
end;

procedure Tgrayline.GC_line_clear(what:integer=-1);

begin
  case what of
       -1: Begin            //all
            GCpointer:=0;
            GCLpointer:=0;
            GCBpointer:=0;
          end;
       0: GCpointer:=0;    //short path
       1: GCLpointer:=0;   //long path
       2: GCBpointer:=0;   //beam path
       3: Begin            //short and long path
            GCpointer:=0;
            GCLpointer:=0;
          end;
  end;
end;
{
procedure GC_line_width(LWidth:Integer);
Begin
   GC_LWidth:=LWidth;
end;
 }
end.
