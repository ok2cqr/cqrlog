(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

{ Common interface of the CW keyers (WinKeyer, cwdaemon, K3NG, hamlib).

  Moved here from uCWKeying so keyer drivers can live outside it, without
  LCL.  uCWKeying re-exports the types under the same names. }

unit uCWDevice;

{$mode objfpc}{$H+}

interface

type TKeyType   = (ktCWdaemon, ktWinKeyer);
type TKeyStatus = (ksReady, ksBusy);

type
  TCWDevice = class
    protected
      fPort      : String;
      fLastErrNr : Word;
      fLastErrSt : String;
      fDevice    : String;
      fDebugMode : Boolean;
      fHamlibBuffer : Boolean;
      fIsNewHamlib  : Boolean; //Hamlib version date higer than 2023-06-01
      fMinSpeed  : Word;
      fMaxSpeed  : Word;
      fPortSpeed : dWord;
    public
      property Port      : String read fPort write fPort;
      property Device    : String read fDevice write fDevice;
      property LastErrNr : Word read fLastErrNr;
      property LastErrSt : String read fLastErrSt;
      property DebugMode : Boolean read fDebugMode write fDebugMode;
      property MinSpeed  : Word read fMinSpeed;
      property MaxSpeed  : Word read fMaxSpeed;
      property PortSpeed : dWord read fPortSpeed write fPortSpeed;
      property HamlibBuffer : Boolean read  fHamlibBuffer write fHamlibBuffer;
      property IsNewHamlib : Boolean read  fIsNewHamlib; //used internally, but can give info out

      constructor Create; virtual; abstract;

      function GetSpeed  : Word; virtual; abstract;
      function GetStatus : TKeyStatus; virtual; abstract;

      procedure Open; virtual; abstract;
      procedure Close; virtual; abstract;
      procedure SetSpeed(speed : Word); virtual; abstract;
      procedure SendText(text : String); virtual; abstract;
      procedure SendHex(text:String);  virtual; abstract;
      procedure StopSending; virtual; abstract;
      procedure DelLastChar; virtual; abstract;
      procedure SetMixManSpeed(min,max : Word); virtual; abstract;
      procedure TuneStart; virtual; abstract;
      procedure TuneStop; virtual; abstract;
  end;

implementation

end.
