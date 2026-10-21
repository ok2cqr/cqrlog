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

      function calc_horizontalx(z:longint;latitude: extended):longint;
  end;
  Pgrayline=^Tgrayline;


implementation


uses ah_math, uSunPosition;

{ Tfgline }

function Tgrayline.calc_horizontalx(z:longint;latitude: extended):longint;
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
var z:longint;
    SunLat,SunLon:extended;
    vere,vere1:longint;

           function vr1(z,x:longint):longint;
             begin
              vr1:=calc_horizontalx(z,(x-obvy shr 1)*obvy2);
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
  begin
     fillchar(q,obvy*obsi,0);
     SubsolarPoint(cas,SunLat,SunLon);
     //workaround because of bug in fpc 3.0.0 and above
     declin:=round(SunLat*512) div 180;
     while(declin<0) do declin:=declin+1024;
     while(declin>1023) do declin:=declin-1024;

     sideclin:=sintab[declin];
     codeclin:=costab[declin];
     ziju:=true;
     for z:=0 to obsi-1 do
     begin
       //hour angle of the Sun in the middle of column z, 1024 steps per circle
       harr[z]:=round(((z+0.5)*obsi2-180-SunLon)*512/180);
       while(harr[z]<0) do harr[z]:=harr[z]+1024;
       while(harr[z]>1023) do harr[z]:=harr[z]-1024
     end;

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
