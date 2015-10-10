(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fSplash;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  buttons, ExtCtrls;

type

  { TfrmSplash }

  TfrmSplash = class(TForm)
    Button1: TButton;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure Image1Paint(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 


var
  frmSplash: TfrmSplash;

implementation

uses uVersion,vinfo,versiontypes;

{ TfrmSplash }

procedure TfrmSplash.FormCreate(Sender: TObject);
begin
  Width  := Image1.Picture.Width;
  Height := Image1.Picture.Height;
  Repaint
end;

procedure TfrmSplash.Image1Paint(Sender: TObject);
function ProductVersionToString(PV: TFileProductVersion): String;
   begin
     Result := Format('%d.%d.%d.%d', [PV[0],PV[1],PV[2],PV[3]])
   end;
const
  VersionPos: TPoint = (X:310; Y:250);
  VersionStyle: TTextStyle =
   (
     Alignment  : taCenter;
     Layout     : tlCenter;
     SingleLine : True;
     Clipping   : True;
     ExpandTabs : False;
     ShowPrefix : False;
     Wordbreak  : False;
     Opaque     : False;
     SystemFont : False;
     RightToLeft: False
   );
var
  ATextRect: TRect;
  Info: TVersionInfo;
begin
  Info := TVersionInfo.Create;
  Info.Load(HINSTANCE);
  ATextRect.TopLeft := VersionPos;
  ATextRect.BottomRight := Point(Image1.Picture.Width, Image1.Picture.Height);
  Image1.Canvas.Font.Style := [fsBold];
  Image1.Canvas.Font.Size:=8;
  Image1.Canvas.Font.Color := clRed;
  //Image1.Canvas.TextRect(ATextRect, VersionPos.X, VersionPos.Y, cVERSION, VersionStyle)
  //ProductVersionToString(Info.FixedInfo.ProductVersion)
  Image1.Canvas.TextRect(ATextRect, VersionPos.X, VersionPos.Y,ProductVersionToString(Info.FixedInfo.FileVersion), VersionStyle);
  Info.Free;
end;

initialization
  {$I fSplash.lrs}

end.

