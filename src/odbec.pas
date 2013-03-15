(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit odbec;

interface


type Tbecc=array[0..255] of char;
     Pbecc=^Tbecc;

procedure pripravbec(abec:Pbecc);
function string2bec(var aaa:shortstring):shortstring;
function chr2bec(c:char):char;


implementation


const abec1:Tbecc=( #0,  #1,   #2,  #3,   #4,   #5,   #6,   #7,  #8,  #9,  #10,  #11,  
                  #12,  #13,  #14, #15,  #16,  #17,  #18,  #19,  #20,  #21,  #22, 
		  #23,  #24,  #25,  #26,  #27,  #28,  #29,  #30,  #31,  ' ',  '!',
		  '"',  '$',  '&',  #39,  '(',  ')',  '*',  '+',  ',',
		  '-', '/',  '0',  '1',  '2',  '3',  '4',  '5',  '6', '7',  '8',  
		  '9',  ':',  ';',  '<',  '=',  '>',  '@',  'A',  'B',  'C',
		  'D',  'E',  'F',  'G',  'H',  'I',  'J',  'K',  'L',  'M',  'N',
		  'O',  'P',  'Q',  'R',  'S',  'T',  'U',  'V',  'W',  'X',  'Y',
		  'Z',  '\',  '^', '_',  '`',  'a',   'b',  'c',  'd', 
		  'e',  'f',  'g',  'h',  'i',  'j',  'k',  'l',  'm',  'n',  'o',
		  'p',  'q',  'r',  's',  't',  'u',  'v',  'w',  'x',  'y',  'z',
		  '{',  '|',  '}',  '~', '.',  
                  '[',  ']',  '%',  '#',  '?',  // specialni reg. znaky. je treba mit pohromade.
                   #127, #128,  #129,  #130,  #131, 
		  #132,  #133,  #134,  #135,  #136,  #137,  #138,  #139,  #140,  
		  #141,  #142,  #143,  #144,  #145,  #146,  #147,  #148,  #149,  
		  #150,  #151,  #152,  #153,  #154,  #155,  #156,  #157,  #158,  
		  #159,  #160,  #161,  #162,  #163,  #164,  #165,  #166,  #167,  
		  #168,  #169,  #170,  #171,  #172,  #173,  #174,  #175,  #176,  
		  #177,  #178,  #179,  #180,  #181,  #182,  #183,  #184,  #185,  
		  #186,  #187,  #188,  #189,  #190, #191,  #192,  #193,  #194,  
		  #195,  #196,  #197,  #198,  #199,  #200,  #201,  #202,  #203,  
		  #204,  #205,  #206,  #207,  #208,  #209,  #210,  #211,  #212,  
		  #213,  #214,  #215,  #216,  #217,  #218,  #219,  #220,  #221,  
		  #222,  #223,  #224,  #225,  #226,  #227,  #228,  #229,  #230,  
		  #231,  #232,  #233,  #234,  #235,  #236,  #237,  #238,  #239,  
		  #240,  #241,  #242,  #243,  #244,  #245,  #246,  #247,  #248,  
		  #249,  #250,  #251,  #252,  #253,  #254,  #255);

var ab:Tbecc;


procedure pripravbec(abec:Pbecc);
var z,x:integer;
  begin
  if abec=nil then 
    abec:=@abec1;
  for z:=0 to 255 do
    begin
      x:=0; 
      while (abec^[x]<>chr(z)) and (x<254) do inc(x);
      ab[z]:=chr(x);
    end;
  end;

function chr2bec(c:char):char;
  begin
     chr2bec:=ab[ord(c)];
  end;

function string2bec(var aaa:shortstring):shortstring;
var z,laa:integer;
    sss:String;
  begin
    laa:=length(aaa);
    if (laa>0) and (aaa[1]='=') then begin sss:=copy(aaa,2,laa);dec(laa) end else sss:=aaa;
{    sss[0]:=aaa[0];}
    for z:=1 to laa do sss[z]:=ab[ord(sss[z])];
    string2bec:=sss;
  end;

begin
pripravbec(@abec1);
end.
