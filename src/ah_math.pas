unit ah_math;

{$i ah_def.inc }
(*$define nomath *)
(*$b-*)   { I may make use of the shortcut boolean eval }

(*$ifndef nomath *)
uses
  math;
(*$endif *)

interface
function tan(x:extended):extended;
function arctan2(a,b:extended):extended;
function arcsin(x:extended):extended;
function arccos(x:extended):extended;


function deg2rad(x:extended):extended;
function rad2deg(x:extended):extended;

function sin_d(x:extended):extended;
function cos_d(x:extended):extended;
function tan_d(x:extended):extended;
function arctan2_d(a,b:extended):extended;
function arcsin_d(x:extended):extended;
function arccos_d(x:extended):extended;
function arctan_d(x:extended):extended;

function put_in_360(x:extended):extended;
function adjusted_mod(a,b:integer):integer;

implementation



(*@/// function deg2rad(x:extended):extended; *)
function deg2rad(x:extended):extended;
begin
  result:=x/180*pi;
  end;
(*@\\\*)
(*@/// function rad2deg(x:extended):extended; *)
function rad2deg(x:extended):extended;
begin
  result:=x*180/pi;
  end;
(*@\\\*)

(*$ifdef nomath *)
{ D1 has no unit math, so here are the needed functions }
(*@/// function tan(x:extended):extended; *)
function tan(x:extended):extended;
begin
  result:=sin(x)/cos(x);
  end;
(*@\\\*)
(*@/// function arctan2(a,b:extended):extended; *)
function arctan2(a,b:extended):extended;
begin
  result:=arctan(a/b);
  if b<0 then result:=result+pi;
  end;
(*@\\\*)
(*@/// function arcsin(x:extended):extended; *)
function arcsin(x:extended):extended;
begin
  if x<1 then
    if x>-1 then
       result:=arctan(x/sqrt(1-x*x))
      else
     result:=-90
      else
        result:=90;
  end;
(*@\\\*)
(*@/// function arccos(x:extended):extended; *)
function arccos(x:extended):extended;
begin
  result:=pi/2-arcsin(x);
  end;
(*@\\\*)
(*$else
(*@/// function tan(x:extended):extended; *)
function tan(x:extended):extended;
begin
  result:=math.tan(x);
  end;
(*@\\\*)
(*@/// function arctan2(a,b:extended):extended; *)
function arctan2(a,b:extended):extended;
begin
  result:=math.arctan2(a,b);
  end
(*@\\\*)
(*@/// function arcsin(x:extended):extended; *)
function arcsin(x:extended):extended;
begin
  result:=math.arcsin(x);
  end;
(*@\\\*)
(*@/// function arccos(x:extended):extended; *)
function arccos(x:extended):extended;
begin
  result:=math.arccos(x);
  end;
(*@\\\*)
(*$endif *)

{ Angular functions with degrees }
(*@/// function sin_d(x:extended):extended; *)
function sin_d(x:extended):extended;
begin
  sin_d:=sin(deg2rad(put_in_360(x)));
  end;
(*@\\\000000030E*)
(*@/// function cos_d(x:extended):extended; *)
function cos_d(x:extended):extended;
begin
  cos_d:=cos(deg2rad(put_in_360(x)));
  end;
(*@\\\000000030E*)
(*@/// function tan_d(x:extended):extended; *)
function tan_d(x:extended):extended;
begin
  tan_d:=tan(deg2rad(put_in_360(x)));
  end;
(*@\\\0000000324*)
(*@/// function arctan2_d(a,b:extended):extended; *)
function arctan2_d(a,b:extended):extended;
begin
  result:=rad2deg(arctan2(a,b));
  end;
(*@\\\0000000320*)
(*@/// function arcsin_d(x:extended):extended; *)
function arcsin_d(x:extended):extended;
begin
  result:=rad2deg(arcsin(x));
  end;
(*@\\\000000031D*)
(*@/// function arccos_d(x:extended):extended; *)
function arccos_d(x:extended):extended;
begin
  result:=rad2deg(arccos(x));
  end;
(*@\\\000000031D*)
(*@/// function arctan_d(x:extended):extended; *)
function arctan_d(x:extended):extended;
begin
  result:=rad2deg(arctan(x));
  end;
(*@\\\000000031E*)

(*@/// function put_in_360(x:extended):extended; *)
function put_in_360(x:extended):extended;
begin
  result:=x-round(x/360)*360;
  while result<0 do result:=result+360;
  end;
(*@\\\*)
(*@/// function adjusted_mod(a,b:longint):longint; *)
function adjusted_mod(a,b:longint):longint;
begin
  result:=a mod b;
  while result<1 do
    result:=result+b;
  end;
(*@\\\*)
(*@\\\*)
(*$ifdef delphi_ge_2 *) (*$warnings off *) (*$endif *)
end.
(*@\\\003F000901000901000901000A01000701000011000701*)
