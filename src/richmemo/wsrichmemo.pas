{
 wsrichmemo.pas 
 
 Author: Dmitry 'skalogryz' Boyarintsev 

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}

unit WSRichMemo; 

{$mode objfpc}{$H+}

interface

uses
  Types, Classes, SysUtils,
  LCLType,
  LazUTF8, // used for GetSubText
  Graphics, Controls, Printers,
  WSStdCtrls, RichMemo;

type
  TIntParaAlignment = RichMemo.TParaAlignment;
  TIntFontParams = RichMemo.TFontParams;

type
  TIntParaMetric = RichMemo.TParaMetric;
  TIntParaNumbering = RichMemo.TParaNumbering;

  TIntSearchOpt = record
    start   : Integer;
    len     : Integer;
    Options : TSearchOptions;
  end;

  { TWSCustomRichMemo }

  TWSCustomRichMemo = class(TWSCustomMemo)
  published
    //Note: RichMemo cannot use LCL TCustomEdit copy/paste/cut operations
    //      because there's no support for (system native) RICHTEXT clipboard format
    //      that's why Clipboard operations are moved to widgetset level
    class procedure CutToClipboard(const AWinControl: TWinControl); virtual;
    class procedure CopyToClipboard(const AWinControl: TWinControl); virtual;
    class procedure PasteFromClipboard(const AWinControl: TWinControl); virtual;
    class function CanPasteFromClipboard(const AWinControl: TWinControl): Boolean; virtual;
    
    class function GetStyleRange(const AWinControl: TWinControl; TextStart: Integer; var RangeStart, RangeLen: Integer): Boolean; virtual;
    class function GetTextAttributes(const AWinControl: TWinControl; TextStart: Integer;
      var Params: TIntFontParams): Boolean; virtual;

    class function isInternalChange(const AWinControl: TWinControl; Params: TTextModifyMask): Boolean; virtual;
    class procedure SetTextAttributesInternal(const AWinControl: TWinControl; TextStart, TextLen: Integer;
      const AModifyMask: TTextModifyMask; const Params: TIntFontParams); virtual;

    class procedure SetTextAttributes(const AWinControl: TWinControl; TextStart, TextLen: Integer; 
      const Params: TIntFontParams); virtual;
    class function GetParaAlignment(const AWinControl: TWinControl; TextStart: Integer;
      var AAlign: TIntParaAlignment): Boolean; virtual;
    class procedure SetParaAlignment(const AWinControl: TWinControl; TextStart, TextLen: Integer;
      const AAlign: TIntParaAlignment); virtual;
    class function GetParaMetric(const AWinControl: TWinControl; TextStart: Integer;
      var AMetric: TIntParaMetric): Boolean; virtual;
    class procedure SetParaMetric(const AWinControl: TWinControl; TextStart, TextLen: Integer;
      const AMetric: TIntParaMetric); virtual;
    class function GetParaNumbering(const AWinControl: TWinControl; TextStart: Integer;
      var ANumber: TIntParaNumbering): Boolean; virtual;
    class function GetParaRange(const AWinControl: TWinControl; TextStart: Integer; var rng: TParaRange): Boolean; virtual;
    class procedure SetParaNumbering(const AWinControl: TWinControl; TextStart, TextLen: Integer;
      const ANumber: TIntParaNumbering); virtual;

    class procedure SetParaTabs(const AWinControl: TWinControl; TextStart, TextLen: Integer;
      const AStopList: TTabStopList); virtual;
    class function GetParaTabs(const AWinControl: TWinControl; TextStart: integer;
      var AStopList: TTabStopList): Boolean; virtual;

    class procedure SetTextUIParams(const AWinControl: TWinControl; TextStart, TextLen: Integer;
      const ui: TTextUIParam); virtual;
    class function GetTextUIParams(const AWinControl: TWinControl; TextStart: Integer;
      var ui: TTextUIParam): Boolean; virtual;

    class procedure InDelText(const AWinControl: TWinControl; const TextUTF8: String; DstStart, DstLen: Integer); virtual;
    class function GetSubText(const AWinControl: TWinControl; TextStart, TextLen: Integer;
      AsUnicode: Boolean; var isUnicode: Boolean; var txt: string; var utxt: UnicodeString): Boolean; virtual;

    class function CharAtPos(const AWinControl: TWinControl; x,y: Integer): Integer; virtual;

    //class procedure SetHideSelection(const ACustomEdit: TCustomEdit; AHideSelection: Boolean); override;
    class function LoadRichText(const AWinControl: TWinControl; Source: TStream): Boolean; virtual;
    class function SaveRichText(const AWinControl: TWinControl; Dest: TStream): Boolean; virtual;

    class function Search(const AWinControl: TWinControl; const ANiddle: string; const SearchOpts: TIntSearchOpt): Integer; virtual;

    class procedure SetZoomFactor(const AWinControl: TWinControl; AZoomFactor: Double); virtual;

    //inline handler
    class function InlineInsert(const AWinControl: TWinControl; ATextStart, ATextLength: Integer;
      const ASize: TSize; AHandler: TRichMemoInline; var wsObj: TRichMemoInlineWSObject): Boolean; virtual;
    class procedure InlineInvalidate(const AWinControl: TWinControl;
       AHandler: TRichMemoInline; wsObj: TRichMemoInlineWSObject); virtual;

    class function Print(const AWinControl: TWinControl; APrinter: TPrinter; const AParams: TPrintParams; DoPrint: Boolean): Integer; virtual;
  end;
  TWSCustomRichMemoClass = class of TWSCustomRichMemo;

  
function WSRegisterCustomRichMemo: Boolean; external name 'WSRegisterCustomRichMemo';

var
  //note: this internal function might go away eventually!
  WSGetFontParams: function (wsfontref: HFONT; var params: TFontParams): Boolean = nil;

implementation

{ TWSCustomRichMemo }

class procedure TWSCustomRichMemo.CutToClipboard(const AWinControl: TWinControl); 
begin

end;

class procedure TWSCustomRichMemo.CopyToClipboard(const AWinControl: TWinControl); 
begin

end;

class procedure TWSCustomRichMemo.PasteFromClipboard(const AWinControl: TWinControl); 
begin

end;

class function TWSCustomRichMemo.CanPasteFromClipboard(
  const AWinControl: TWinControl): Boolean;
begin
  Result := true;
end;

class function TWSCustomRichMemo.GetStyleRange(const AWinControl: TWinControl;
  TextStart: Integer; var RangeStart, RangeLen: Integer): Boolean;
begin
  RangeStart :=-1;
  RangeLen := -1;
  Result := false;
end;

class function TWSCustomRichMemo.GetTextAttributes(const AWinControl: TWinControl; 
  TextStart: Integer; var Params: TIntFontParams): Boolean;
begin
  Result := false;
end;

class function TWSCustomRichMemo.isInternalChange(
  const AWinControl: TWinControl; Params: TTextModifyMask): Boolean;
begin
  Result:=false;
end;

class procedure TWSCustomRichMemo.SetTextAttributesInternal(
  const AWinControl: TWinControl; TextStart, TextLen: Integer;
  const AModifyMask: TTextModifyMask; const Params: TIntFontParams);
begin

end;

class procedure TWSCustomRichMemo.SetTextAttributes(const AWinControl: TWinControl; 
  TextStart, TextLen: Integer;  
  const Params: TIntFontParams);
begin
end;

class function TWSCustomRichMemo.GetParaAlignment(
  const AWinControl: TWinControl; TextStart: Integer;
  var AAlign: TIntParaAlignment): Boolean;
begin
  Result := false;
end;

class procedure TWSCustomRichMemo.SetParaAlignment(
  const AWinControl: TWinControl; TextStart, TextLen: Integer;
  const AAlign: TIntParaAlignment);
begin

end;

class function TWSCustomRichMemo.GetParaMetric(const AWinControl: TWinControl;
  TextStart: Integer; var AMetric: TIntParaMetric): Boolean;
begin
  Result := false;
end;

class procedure TWSCustomRichMemo.SetParaMetric(
  const AWinControl: TWinControl; TextStart, TextLen: Integer;
  const AMetric: TIntParaMetric);
begin

end;

class function TWSCustomRichMemo.GetParaNumbering(
  const AWinControl: TWinControl; TextStart: Integer;
  var ANumber: TIntParaNumbering): Boolean;
begin
  Result := false;
end;

class function TWSCustomRichMemo.GetParaRange(const AWinControl: TWinControl;
  TextStart: Integer; var rng: TParaRange): Boolean;
begin
  Result:=False;
end;

class procedure TWSCustomRichMemo.SetParaNumbering(
  const AWinControl: TWinControl; TextStart, TextLen: Integer;
  const ANumber: TIntParaNumbering);
begin

end;

class procedure TWSCustomRichMemo.SetParaTabs(const AWinControl: TWinControl;
  TextStart, TextLen: Integer; const AStopList: TTabStopList);
begin

end;

class function TWSCustomRichMemo.GetParaTabs(const AWinControl: TWinControl;
  TextStart: integer; var AStopList: TTabStopList): Boolean;
begin
  Result:=False;
end;

class procedure TWSCustomRichMemo.SetTextUIParams(const AWinControl: TWinControl;
  TextStart, TextLen: Integer; const ui: TTextUIParam);
begin

end;

class function TWSCustomRichMemo.GetTextUIParams(const AWinControl: TWinControl;
  TextStart: Integer; var ui: TTextUIParam): Boolean;
begin
  Result:=false;
end;

class procedure TWSCustomRichMemo.InDelText(const AWinControl: TWinControl; const TextUTF8: String; DstStart, DstLen: Integer); 
begin

end;

class function TWSCustomRichMemo.GetSubText(const AWinControl: TWinControl;
  TextStart, TextLen: Integer; AsUnicode: Boolean; var isUnicode: Boolean;
  var txt: string; var utxt: UnicodeString): Boolean;
begin
  // default, ineffecient implementation
  if TextLen<0 then GetTextLen(AWinControl, TextLen);
  Result:=GetText(AWinControl, txt);
  if not Result then Exit;
  if TextStart<0 then TextStart:=0;
  inc(TextStart);
  utxt:='';
  isUnicode:=false;
  txt:=UTF8Copy(txt, TextStart, TextLen);
  Result:=true;
end;

class function TWSCustomRichMemo.CharAtPos(const AWinControl: TWinControl; x,
  y: Integer): Integer;
begin
  Result:=-1;
end;

{class procedure TWSCustomRichMemo.SetHideSelection(const ACustomEdit: TCustomEdit; AHideSelection: Boolean);
begin

end;}

class function TWSCustomRichMemo.LoadRichText(const AWinControl: TWinControl; Source: TStream): Boolean;
begin
  Result := false;
end;

class function TWSCustomRichMemo.SaveRichText(const AWinControl: TWinControl; Dest: TStream): Boolean;
begin
  Result := false;
end;

class function TWSCustomRichMemo.Search(const AWinControl: TWinControl; const ANiddle: string;
  const SearchOpts: TIntSearchOpt): Integer;
begin
  Result:=-1;
end;

class procedure TWSCustomRichMemo.SetZoomFactor(const AWinControl: TWinControl;
  AZoomFactor: Double);
begin

end;

class function TWSCustomRichMemo.InlineInsert(const AWinControl: TWinControl;
  ATextStart, ATextLength: Integer; const ASize: TSize; AHandler: TRichMemoInline;
  var wsObj: TRichMemoInlineWSObject): Boolean;
begin
  wsObj:=nil;
  Result:=false;
end;

class procedure TWSCustomRichMemo.InlineInvalidate(
  const AWinControl: TWinControl; AHandler: TRichMemoInline;
  wsObj: TRichMemoInlineWSObject);
begin

end;

class function TWSCustomRichMemo.Print(const AWinControl: TWinControl;
  APrinter: TPrinter; const AParams: TPrintParams; DoPrint: Boolean): Integer;
begin
  Result:=0;
end;

end.

