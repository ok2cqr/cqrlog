{$mode delphi}
{***************************************************************************************************

Copyright (C) <2008,2009> <Jeff K. Steinkamp>
<2009> <Petr Hlozek,OK7AN petr@ok7an.com>
A few bugfixes and changes.

This program is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program;
if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
**********************************************************************************************************}
unit rig;

interface

uses classes, sysutils,ExtCtrls, Dialogs; {ThdTimer}

const HAMLIBDLL = 'libhamlib.so';
const ports: array[0..14] of string = ('COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9', 'COM10', 'COM11', 'COM12', 'COM13', 'COM14', 'COM15');
const Baudrates: array[0..6] of string = ('300', '1200', '2400', '4800', '9600', '19200', '38400');
const Handshakes: array[0..2] of string = ('None', 'XONXOFF', 'Hardware');
const Databits: array[0..3] of string = ('5', '6', '7', '8');
const Parity: array[0..2] of string = ('None', 'Odd', 'Even');
const StopBits: array[0..3] of string = ('0', '1', '2', '3');
const RTSDTR: array[0..2] of string = ('Unset', 'ON', 'OFF');
const Bools: array[0..1] of Boolean = (FALSE, TRUE);
CONST
  RIG_VFO_CURR  =  (1 shl 29);     {* current "tunable channel"/VFO *}

// **
// * brief Hamlib error codes
// * Error codes that can be returned by the Hamlib functions
// **

type rig_errcode_e = (
    RIG_OK = 0, //< No error, operation completed sucessfully */
    RIG_EINVAL , //< invalid parameter */
    RIG_ECONF , //< invalid configuration (serial,..) */
    RIG_ENOMEM , //< memory shortage */
    RIG_ENIMPL , //< function not implemented, but will be */
    RIG_ETIMEOUT , //< communication timed out */
    RIG_EIO , //< IO error, including open failed */
    RIG_EINTERNAL, //< Internal Hamlib error, huh! */
    RIG_EPROTO, //< Protocol error */
    RIG_ERJCTED, //< Command rejected by the rig */
    RIG_ETRUNC, //< Command performed, but arg truncated */
    RIG_ENAVAIL, //< function not available */
    RIG_ENTARGET, //< VFO not targetable */
    RIG_BUSERROR, //< Error talking on the bus */
    RIG_BUSBUSY, //< Collision on the bus */
    RIG_EARG, //< NULL RIG handle or any invalid pointer parameter in get arg */
    RIG_EVFO, //< Invalid VFO */
    RIG_EDOM //< Argument out of domain of func */
    );


// **
// * brief Hamlib debug levels
// *
// * REM: Numeric order matters for debug level
// *
// * sa rig_set_debug
// **

type rig_debug_level_e = (
    RIG_DEBUG_NONE = 0, //*!< no bug reporting */
    RIG_DEBUG_BUG, //*!< serious bug */
    RIG_DEBUG_ERR, //*!< error case (e.g. protocol, memory allocation) */
    RIG_DEBUG_WARN, //*!< warning */
    RIG_DEBUG_VERBOSE, //*!< verbose */
    RIG_DEBUG_TRACE //*!< tracing */
    );

type rmode_t = (
    RIG_MODE_NONE = 0, ///*!< '' -- None */
    RIG_MODE_AM = (1 shl 0), ///*!< \c AM -- Amplitude Modulation */
    RIG_MODE_CW = (1 shl 1), ///*!< \c CW -- CW "normal" sideband */
    RIG_MODE_USB = (1 shl 2), ///*!< \c USB -- Upper Side Band */
    RIG_MODE_LSB = (1 shl 3), ///*!< \c LSB -- Lower Side Band */

    RIG_MODE_FM = (1 shl 5), //*!< \c FM -- "narrow" band FM */
    RIG_MODE_WFM = (1 shl 6), //*!< \c WFM -- broadcast wide FM */
    RIG_MODE_CWR = (1 shl 7), //*!< \c CWR -- CW "reverse" sideband */
    RIG_MODE_RTTYR = (1 shl 8), //*!< \c RTTYR -- RTTY "reverse" sideband */
    RIG_MODE_AMS = (1 shl 9), //*!< \c AMS -- Amplitude Modulation Synchronous */
    RIG_MODE_PKTLSB = (1 shl 10), //*!< \c PKTLSB -- Packet/Digital LSB mode (dedicated port) */
    RIG_MODE_PKTUSB = (1 shl 11), //*!< \c PKTUSB -- Packet/Digital USB mode (dedicated port) */
    RIG_MODE_PKTFM = (1 shl 12), //*!< \c PKTFM -- Packet/Digital FM mode (dedicated port) */
    RIG_MODE_ECSSUSB = (1 shl 13), //*!< \c ECSSUSB -- Exalted Carrier Single Sideband USB */
    RIG_MODE_ECSSLSB = (1 shl 14), //*!< \c ECSSLSB -- Exalted Carrier Single Sideband LSB */
    RIG_MODE_RTTY = (1 shl 4), //*!< \c RTTY -- Radio Teletype */
    RIG_MODE_FAX = (1 shl 15), //*!< \c FAX -- Facsimile Mode */
    RIG_MODE_SAM = (1 shl 16), //*!< \c SAM -- Synchronous AM double sideband */
    RIG_MODE_SAL = (1 shl 17), //*!< \c SAL -- Synchronous AM lower sideband */
    RIG_MODE_SAH = (1 shl 18), //*!< \c SAH -- Synchronous AM upper (higher) sideband */
    RIG_MODE_DSB = (1 shl 19) //*!< \c DSB -- Double sideband suppressed carrier */
    );

type freq_range_list = record
    fstart: double; //*!< Start frequency */
    fend: double; //*!< End frequency */
    modes: rmode_t; //*!< Bit field of RIG_MODE's */
    low_power: integer; //*!< Lower RF power in mW, -1 for no power (ie. rx list) */
    high_power: integer; //*!< Higher RF power in mW, -1 for no power (ie. rx list) */
    vfo: integer; //*!< VFO list equipped with this range */
    ant: integer; //*!< Antenna list equipped with this range, 0 means all */
  end;



var freq_range_t: freq_range_list;

procedure rig_set_debug (debug_level  : rig_debug_level_e); cdecl; external HAMLIBDLL;

function rig_init(rig_model: integer): integer; cdecl; external HAMLIBDLL;
function rig_open(MyMYRIG: integer): rig_errcode_e; cdecl; external HAMLIBDLL;

function rig_close(MyMYRIG: integer): rig_errcode_e; cdecl; external HAMLIBDLL;
function rig_cleanup(MyMYRIG: integer): rig_errcode_e; cdecl; external HAMLIBDLL;

function rig_set_freq(MYRIG: integer; vfo: integer; freq: double): rig_errcode_e; cdecl; external HAMLIBDLL;
function rig_get_freq(MYRIG: integer; vfo: integer; var freq: double): rig_errcode_e; cdecl; external HAMLIBDLL;

function rig_set_mode(MYRIG: Integer; vfo: integer; mode: rmode_t; width: integer): rig_errcode_e; cdecl; external HAMLIBDLL;
function rig_get_mode(MYRIG: Integer; vfo: integer; var mode: rmode_t; var width: integer): rig_errcode_e; cdecl; external HAMLIBDLL;

function rig_set_vfo(MYRIG: integer; vfo: integer): rig_errcode_e; cdecl; external HAMLIBDLL;
function rig_get_vfo(MYRIG: integer; var vfo: integer): rig_errcode_e; cdecl; external HAMLIBDLL;

function rig_set_ptt(MYRIG: integer; vfo: integer; ptt: integer): rig_errcode_e; cdecl; external HAMLIBDLL;
function rig_get_ptt(MYRIG: integer; vfo: integer; var ptt: integer): rig_errcode_e; cdecl; external HAMLIBDLL;

function rig_set_conf(MyMYRIG: integer; token: integer; const val: string): rig_errcode_e; cdecl; external HAMLIBDLL;
function rig_get_conf(MyMYRIG: integer; token: integer; var val: string): rig_errcode_e; cdecl; external HAMLIBDLL;
function rig_token_lookup(MYRIG: Integer; const name: string): integer; cdecl; external HAMLIBDLL;

function rig_set_split_vfo(MyMYRIG: integer; rx_vfo, split, tx_vfo: integer): rig_errcode_e; cdecl; external HAMLIBDLL;
function rig_get_split_vfo(MyMYRIG: integer; rx_vfo: integer; var split, tx_vfo: integer): rig_errcode_e; cdecl; external HAMLIBDLL;
Function rigerror (errnum : integer) : String ; cdecl; external HAMLIBDLL;

type tRig = class(tobject)
  private
    RIG_P: integer;
    RIG_RESULT: rig_errcode_e;
    frigpoll: integer;
    fRigTimeOut: string;
    fRigStopBits: string;
    fRigSerialSpeed: string;
    fRigDataBits: string;
    fRigHandshake: string;
    fRigRTSState: string;
    fRigSerialParity: string;
    fRigDTRState: string;
    fstate: boolean;
    fRigFrequency: double;
    fRigMode: rmode_t;
    fRigPort: string;
    fRigModel: integer;
    fvfo: integer;
    fbw: integer;
    ftx: boolean;
    fsplit: Boolean;
    fmodelist: string;
    fhas50: boolean;
    fhas144: boolean;
    fhas432: boolean;
    fpacing: string;
    fretry: string;
    fdelay : string;
    ftimeout: string;
    fSendCWR : Boolean;

    procedure SetRigDataBits(const Value: string);
    procedure SetRigDTRState(const Value: string);
    procedure SetRigHandshake(const Value: string);
    procedure SetRigPoll(const Value: integer);
    procedure SetRigRTSState(const Value: string);
    procedure SetRigSerialParity(const Value: string);
    procedure SetRigSerialSpeed(const Value: string);
    procedure SetRigStopBits(const Value: string);
    procedure SetRigTimeout(const Value: string);

    procedure SetRigFrequency(const Value: double);
    procedure SetRigPort(const Value: string);
    procedure SetRigModel(const value: integer);
    procedure setvfo(const Value: integer);
    procedure settx(const Value: boolean);
    procedure SetSplit(const Value: Boolean);
    procedure GetModes;
    procedure WriteErroCode(e : rig_errcode_e);
    
    function rig_strrmode(mode: rmode_t): string;
    function rig_rmodestr(mode: string): rmode_t;

  public
    property Rig_SerialSpeed: string read fRigSerialSpeed write SetRigSerialSpeed;
    property Rig_Port: string read fRigPort write SetRigPort;
    property Rig_DataBits: string read fRigDataBits write SetRigDataBits;
    property Rig_Stopbits: string read fRigStopBits write SetRigStopBits;
    property Rig_Parity: string read fRigSerialParity write SetRigSerialParity;
    property Rig_Handshake: string read fRigHandshake write SetRigHandshake;
    property Rig_RTSState: string read fRigRTSState write SetRigRTSState;
    property Rig_DTRState: string read fRigDTRState write SetRigDTRState;
    property Rig_PollInterval: integer read frigpoll write SetRigPoll default 500;
    property Rig_Frequency: double read fRigFrequency write SetRigFrequency;
    property Rig_Mode: rmode_t read fRigMode;// write SetRigMode;
    property Rig_Model: integer read fRigModel write SetRigModel;
    property Rig_State: boolean read fstate;
    property Rig_ModeList: string read fmodelist;
    property Rig_VFO: integer read fvfo write setvfo;
    property Rig_TX: boolean read ftx write settx;
    property Rig_Split: Boolean read fsplit write SetSplit;
    property Rig_Has50: boolean read fhas50;
    property Rig_Has144: boolean read fhas144;
    property Rig_Has432: boolean read fhas432;
    property Rig_Pacing : string read fpacing write fpacing;
    property rig_delay : string read fdelay write fdelay;
    property rig_retry : string read fretry write fretry;
    property rig_timeout : string read ftimeout write ftimeout;
    property Rig_SendCWR : Boolean read fSendCWR write fSendCWR;


    Function  Open : rig_errcode_e;
    procedure Close;
    procedure Pollradio;
    function ModeToString(mode: rmode_t): string;
    function StringToMode(mode: string): rmode_t;
    constructor Create;
    destructor Destroy; override;
    procedure SetRigMode(mode : String; width : Integer);
  end;

implementation

{ tRig }

procedure tRig.Close;
begin
  Writeln('in tRig.Close');
  if RIG_P <> -99 then
  begin
    rig_close(RIG_P);
    rig_cleanup(RIG_p)
  end;
  fstate := false
end;

constructor tRig.Create;
begin
  fRigSerialParity := 'None';
  fRigHandShake := 'None';
  frigRTSState := 'NO';
  fRigDTRState := 'NO';
  frigport := 'None';
  frigserialspeed := '4800';
  frigdatabits := '8';
  fRigSerialParity := 'None';
  fRigStopBits := '1';
  fvfo := 1;
  fstate := false;
  fsplit := false;
  rig_set_debug(RIG_DEBUG_BUG);
  rig_p := -999;
  fSendCWR := False
end;

destructor tRig.Destroy;
begin
  Close
end;

function tRig.Open : rig_errcode_e;
var token: longword;
begin
  result := RIG_BUSBUSY;
  RIG_P := rig_init(fRigModel);
   //set the rig comport
  token := rig_token_lookup(RIG_P, 'rig_pathname');
  //RIG_RESULT := rig_get_conf(RIG_P,token,conf);
  RIG_RESULT := rig_set_conf(RIG_P, token, frigport);
  if rig_result <> RIG_OK then
  begin
    Writeln('An error has occurred setting the rig pathname:',fRigPort);
    result := RIG_RESULT;
    exit;
  end;
   //set the rigs serial speed
  if (fRigModel <> 2) and (fRigModel<>1901) then
  begin
    token :=  rig_token_lookup(RIG_P, 'serial_speed');
    RIG_RESULT := rig_set_conf(RIG_P, token , fRigSerialSpeed);
    if rig_result <> RIG_OK then
    begin
       Writeln('An error has occurred setting the serial speed:',fRigSerialSpeed);
       result := RIG_RESULT;
       exit;
    end;
     //set the rigs data bits
    token := rig_token_lookup(RIG_P, 'data_bits');
    RIG_RESULT := rig_set_conf(RIG_P, token, fRigDataBits);
    if rig_result <> RIG_OK then
    begin
         Writeln('An error has occurred setting the serial data bits:',fRigDataBits);
         result := RIG_RESULT;
         exit;
    end;
     //set the rigs stop bits
    token := rig_token_lookup(RIG_P, 'stop_bits');
    RIG_RESULT := rig_set_conf(RIG_P,token , fRigStopBits);
    if rig_result <> RIG_OK then
    begin
       Writeln('An error has occurred setting the stop bits',fRigStopBits);
       result := RIG_RESULT;
       exit;
    end;
     //set the rigs parity
    token := rig_token_lookup(RIG_P, 'serial_parity');
    RIG_RESULT := rig_set_conf(RIG_P,token , fRigSerialParity);
    if rig_result <> RIG_OK then
    begin
       Writeln('An error has occurred setting the Serial Parity:',fRigSerialParity);
       result := RIG_RESULT;
       exit;
    end;
     //set rig DTR state
    token := rig_token_lookup(RIG_P, 'dtr_state');
    RIG_RESULT := rig_set_conf(RIG_P,token , fRigDTRState);
    if rig_result <> RIG_OK then
    begin
       Writeln('An error has occurred seting the DTR state:',fRigDTRState);
       result := RIG_RESULT;
       exit;
    end;

    //I haven't perused your code, but if there's a
    //set_conf("serial_handshake", "Hardware")
    //you cannot do a set_conf("rts_state", "ON"/"OFF") at the same time.
    //You need some logic to prevent that. The other way around is to only
    //allow rts_state to be set to RIG_SIGNAL_UNSET (ie. tri-state) when
    //serial handshake is Hardware (CTS/RTS).
    //Stephane - F8CFE
    token := rig_token_lookup(RIG_P, 'rts_state');
    if (fRigHandshake = Handshakes[2]) then
      fRigRTSState := 'Unset';
    RIG_RESULT := rig_set_conf(RIG_P, token, fRigRTSState);
    if rig_result <> RIG_OK then
    begin
       Writeln('An error has occurred setting the RTS state:',fRigRTSState);
       result := RIG_RESULT;
       exit
    end;

    {
    //set timeout
    token := rig_token_lookup(RIG_P, 'timeout');
    RIG_RESULT := rig_set_conf(RIG_P, token, ftimeout);
    if rig_result <> RIG_OK then
    begin
       showmessage('An error has occurred setting the timeout');
       result := RIG_RESULT;
       exit;
    end;

     //set retries
    token := rig_token_lookup(RIG_P, 'retry');
    RIG_RESULT := rig_set_conf(RIG_P, token, fretry);
    if rig_result <> RIG_OK then
    begin
       showmessage('An error has occurred setting the retries');
       result := RIG_RESULT;
       exit;
    end;

     //set pacing
    token := rig_token_lookup(RIG_P, 'write_delay');
    RIG_RESULT := rig_set_conf(RIG_P, token, fpacing);
    if rig_result <> RIG_OK then
    begin
       showmessage('An error has occurred setting the pacing');
       result := RIG_RESULT;
       exit;
    end;

     //set write delay
    token := rig_token_lookup(RIG_P, 'post_write_delay');
    RIG_RESULT := rig_set_conf(RIG_P, token, fdelay);
    if rig_result <> RIG_OK then
    begin
       showmessage('An error has occurred setting the write delay');
       result := RIG_RESULT;
       exit;
    end;
    }
  end;
  RIG_RESULT := rig_open(RIG_P);
  //result := RIG_RESULT;
  Writeln('RIG_RESULT1: ',RIG_RESULT);
  if RIG_RESULT = RIG_OK then
  begin
    RIG_RESULT := rig_get_freq(RIG_P, RIG_VFO_CURR, fRigFrequency);
    Writeln('RIG_RESULT2: ',RIG_RESULT);
    if rig_Result = RIG_OK then
      fstate := true
    else begin
      Writeln('Rig is not OK');
      rig_close(rig_P);
      rig_cleanup(rig_p);
      fstate := false
    end
  end
  else begin
    Writeln('rig_open: error =  ' + rigerror(ord(RIG_RESULT)));
    Writeln('rig_open: error = ',ord(RIG_RESULT));
    fstate := false
  end;
  result := RIG_RESULT
end;


procedure tRig.SetRigDataBits(const Value: string);
begin
  fRigDataBits := Value;
end;

procedure tRig.SetRigPort(const value: string);
begin
  fRigPort := value;
end;

procedure tRig.SetRigDTRState(const Value: string);
begin
  fRigDTRState := Value;
end;

procedure tRig.SetRigFrequency(const Value: double);
begin
  fRigFrequency := Value;
  rig_set_freq(RIG_P, RIG_VFO_CURR, fRigFrequency);
end;

procedure tRig.SetRigHandshake(const Value: string);
begin
  fRigHandshake := Value;
end;

procedure tRig.SetRigMode(mode : String; width : Integer);//const Value: rmode_t);
begin
  if fSendCWR and (mode = 'CW') then
    mode := 'CWR';
  fRigMode := StringToMode(mode);
  RIG_RESULT := rig_set_mode(RIG_P, RIG_VFO_CURR, fRigMode,width);
  if RIG_RESULT <> RIG_OK then
  begin
    Writeln('This is an invalid mode:',mode);
    WriteErroCode(RIG_RESULT)
  end
end;

procedure tRig.SetRigModel(const Value: integer);
begin
  fRigModel := Value;
end;

procedure tRig.SetRigPoll(const Value: integer);
begin
  frigpoll := Value;
end;

procedure tRig.SetRigRTSState(const Value: string);
begin
  fRigRTSState := Value;
end;

procedure tRig.SetRigSerialParity(const Value: string);
begin
  fRigSerialParity := Value;
end;

procedure tRig.SetRigSerialSpeed(const Value: string);
begin
  fRigSerialSpeed := Value;
end;

procedure tRig.SetRigStopBits(const Value: string);
begin
  fRigStopBits := Value;
end;

procedure tRig.SetRigTimeout(const Value: string);
begin
  fRigTimeOut := Value;
end;

procedure tRig.setvfo(const Value: integer);
begin
  fvfo := Value;
  rig_set_vfo(rig_p,fvfo)
end;


procedure tRig.settx(const Value: boolean);
begin
  ftx := value;
  if ftx = true then
    rig_set_ptt(RIG_P, RIG_VFO_CURR, 1)
  else
    rig_set_ptt(RIG_P, RIG_VFO_CURR, 0);
end;

function tRig.ModeToString(mode: rmode_t): string;
begin
  result := rig_strrmode(mode);
end;

procedure tRig.SetSplit(const Value: Boolean);
begin
  fsplit := Value;

  if fsplit = true then
    rig_set_split_vfo(RIG_P, 1, 1, 2)
  else
    rig_set_split_vfo(RIG_P, 1, 0, 2)

end;

procedure tRig.GetModes;
var mode_e, pmode: rmode_t;
  x: integer;
begin
  rig_get_mode(Rig_P, RIG_VFO_CURR, pmode, x);
  fmodelist := '';
  for x := 0 to 19 do
  begin
    mode_e := rmode_t(1 shl x);
    RIG_RESULT := rig_set_mode(RIG_P, RIG_VFO_CURR, mode_e, 0);
    if RIG_Result = RIG_OK then
      fmodelist := fmodelist + ',' + rig_strrmode(mode_e);
  end;
  RIG_RESULT := rig_set_mode(RIG_P, RIG_VFO_CURR, pmode, 0)
end;

function tRig.rig_strrmode(mode: rmode_t): string;
begin
  case mode of
    RIG_MODE_NONE: result := 'NONE';
    RIG_MODE_RTTY: result := 'RTTY';
    RIG_MODE_AM: result := 'AM';
    RIG_MODE_CW: result := 'CW';
    RIG_MODE_USB: result := 'SSB';
    RIG_MODE_LSB: result := 'SSB';
    RIG_MODE_FM: result := 'FM';
    RIG_MODE_WFM: result := 'WFM';
    RIG_MODE_CWR: result := 'CW';
    RIG_MODE_RTTYR: result := 'RTTY';
    RIG_MODE_AMS: result := 'AMS';
    RIG_MODE_PKTLSB: result := 'DATA-LSB';
    RIG_MODE_PKTUSB: result := 'DATA-USB';
    RIG_MODE_PKTFM: result := 'DATA-FM';
    RIG_MODE_ECSSUSB: result := 'ECSSUSB';
    RIG_MODE_ECSSLSB: result := 'ECSSLSB';
    RIG_MODE_FAX: result := 'FAX';
    RIG_MODE_SAM: result := 'SAM';
    RIG_MODE_SAL: result := 'SAL';
    RIG_MODE_SAH: result := 'SAH';
    RIG_MODE_DSB: result := 'DSB'
  end
end;


function trig.rig_rmodestr(mode: string): rmode_t;
begin
  if mode = 'AM' then result := RIG_MODE_AM
  else if mode = 'CW' then result := RIG_MODE_CW
  else if mode = 'USB' then result := RIG_MODE_USB
  else if mode = 'LSB' then result := RIG_MODE_LSB
  else if mode = 'RTTY' then result := RIG_MODE_RTTY
  else if mode = 'FM' then result := RIG_MODE_FM
  else if mode = 'WFM' then result := RIG_MODE_WFM
  else if mode = 'CWR' then result := RIG_MODE_CWR
  else if mode = 'RTTYR' then result := RIG_MODE_RTTYR
  else if mode = 'AMS' then result := RIG_MODE_AMS
  else if mode = 'DATA-LSB' then result := RIG_MODE_PKTLSB
  else if mode = 'DATA-USB' then result := RIG_MODE_PKTUSB
  else if mode = 'DATA-FM' then result := RIG_MODE_PKTFM
  else if mode = 'ECSSUSB' then result := RIG_MODE_ECSSUSB
  else if mode = 'ECSSLSB' then result := RIG_MODE_ECSSLSB
  else if mode = 'FAX' then result := RIG_MODE_FAX
  else if mode = 'SAM' then result := RIG_MODE_SAM
  else if mode = 'SAL' then result := RIG_MODE_SAL
  else if mode = 'SAH' then result := RIG_MODE_SAH
  else if mode = 'DSB' then result := RIG_MODE_DSB
  else result := RIG_MODE_NONE;
end;


function tRig.StringToMode(mode: string): rmode_t;
begin
  result := rig_rmodestr(mode);
end;

procedure trig.Pollradio;
var
  vf : integer;
begin
  if fstate = false then exit;
  Writeln('PollRadio');
  RIG_RESULT := rig_get_vfo(RIG_P,vf);
  RIG_RESULT := rig_get_freq(RIG_P, RIG_VFO_CURR, fRigFrequency);
  RIG_RESULT := rig_get_Mode(RIG_P, RIG_VFO_CURR, fRigMode,fbw );
  //if RIG_RESULT <> RIG_OK then
  //  fRigFrequency := 0;
  Writeln('fRigMode:',fRigMode);
  Writeln('fRigFrequency:',fRigFrequency);
end;

procedure Trig.WriteErroCode(e : rig_errcode_e);
begin
  case e of
    RIG_OK : Writeln('RIG_OK'); //< No error, operation completed sucessfully */
    RIG_EINVAL : Writeln('invalid parameter'); //< invalid parameter */
    RIG_ECONF : Writeln('invalid configuration (serial,..)'); //< */
    RIG_ENOMEM : Writeln('memory shortage'); //< memory shortage */
    RIG_ENIMPL : Writeln('function not implemented, but will be'); //<  */
    RIG_ETIMEOUT : Writeln('communication timed out'); //<  */
    RIG_EIO : Writeln('IO error, including open failed'); //<  */
    RIG_EINTERNAL : Writeln('Internal Hamlib error, huh!'); //<  */
    RIG_EPROTO : Writeln('Protocol error'); //<  */
    RIG_ERJCTED : Writeln('Command rejected by the rig'); //<  */
    RIG_ETRUNC: Writeln('Command performed, but arg truncated'); //<  */
    RIG_ENAVAIL: Writeln('function not available'); //<  */
    RIG_ENTARGET: Writeln('VFO not targetable'); //<  */
    RIG_BUSERROR: Writeln('Error talking on the bus'); //<  */
    RIG_BUSBUSY: Writeln('Collision on the bus'); //<  */
    RIG_EARG: Writeln('NULL RIG handle or any invalid pointer parameter in get arg'); //<  */
    RIG_EVFO: Writeln('Invalid VFO'); //<  */
    RIG_EDOM: Writeln('Argument out of domain of func'); //<  */
  end
end;
end.

