unit fXfldigi;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, blcksock;

const
     old    :integer = 0;
     new    :integer = 1;
type

  { Tfrmxfldigi }

  Tfrmxfldigi = class(TForm)
    btSaveQSO: TButton;
    edtDate: TLabel;
    edtTimeOn: TLabel;
    edtTimeOff: TLabel;
    lblTimeOff: TLabel;
    lblTimeOn: TLabel;
    lblDate: TLabel;
    lblComment: TLabel;
    lblMode: TLabel;
    lblRstS: TLabel;
    lblRstR: TLabel;
    lblCounty: TLabel;
    lblRig: TLabel;
    lblName: TLabel;
    lblQth: TLabel;
    lblGrid: TLabel;
    lblState: TLabel;
    lblCall: TLabel;
    lblFreq: TLabel;
    lbHeader: TLabel;
    edtRig: TLabel;
    edtComment: TLabel;
    edtCounty: TLabel;
    edtQth: TLabel;
    edtGrid: TLabel;
    edtState: TLabel;
    edtName: TLabel;
    edtCall: TLabel;
    edtFreq: TLabel;
    edtMode: TLabel;
    edtRstS: TLabel;
    edtRstR: TLabel;
    procedure btSaveQSOClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);

    { private declarations }
  private
    procedure SetMyFields(d:integer);
    procedure SetCqrFields(d :integer);

  public
    procedure TimTime;
    function PollFldigi(LogItemCmd:String; out Rres:String):boolean;
    { public declarations }

  end;

type
    fLogEntry = record
     frequency  ,
     startdate       ,
     time_on    ,
     time_off   ,
     call       ,
     name       ,
     rst_in     ,
     rst_out    ,
     state      ,
     county     ,
     qth        ,
     mode       ,
     submode    ,
     notes      ,
     locator    ,
     trx_state  : String;
     end;

var
  frmxfldigi    : Tfrmxfldigi;
  xmlsock       : TTCPBlockSocket;
  fLog          : array [0 .. 1] of fLogEntry;
  SyncErrCnt    : integer = 0;

implementation
{ Tfrmxfldigi }

uses  fTRXControl, dData, dUtils, uMyIni, fNewQSO, dDXCluster;


procedure Tfrmxfldigi.SetMyFields(d:integer);
Begin
   with fLog[d] do
    Begin
     edtDate.Caption    := copy(startdate,1,4)+'-'+copy(startdate,5,2)+'-'+copy(startdate,7,2);
     if time_on<>'' then
         edtTimeOn.Caption  := time_on[1]+time_on[2]+':'+time_on[3]+time_on[4]
        else  edtTimeOn.Caption  := time_on;
     if time_off<>'' then
         edtTimeOff.Caption := time_off[1]+time_off[2]+':'+time_off[3]+time_off[4]
        else edtTimeOff.Caption := time_off;
     edtCall.Caption    := call;
     edtFreq.Caption    := frequency;
     edtMode.Caption    := mode;
     edtRstR.Caption    := rst_in;
     edtRstS.Caption    := rst_out;
     edtName.Caption    := name;
     edtQth.Caption     := qth;
     edtGrid.Caption    := locator;
     edtState.Caption   := state;
     edtComment.Caption := notes;
     edtCounty.Caption  := county;
     edtRig.Caption     := trx_state;
    end;
end;
procedure Tfrmxfldigi.SetCqrFields(d:integer);

Begin
 with fLog[d] do
   Begin
     if (startdate<>'')    then frmNewQSO.edtdate.Text      := copy(startdate,1,4)+'-'+copy(startdate,5,2)+'-'+copy(startdate,7,2);
     if (time_on <>'')     then frmNewQSO.edtStartTime.Text := time_on[1]+time_on[2]+':'+time_on[3]+time_on[4];
     if (time_off <>'')    then frmNewQSO.edtEndTime.Text   := time_off[1]+time_off[2]+':'+time_off[3]+time_off[4];
     if (call <>'')        then frmNewQSO.edtCall.Text      := call;
     if (frequency <> '')  then frmNewQSO.cmbFreq.text      := frequency;
     if (mode <>'')        then frmNewQSO.cmbMode.Text      := mode;
     if (rst_in <>'')      then frmNewQSO.edtMyRST.Text     := rst_in;
     if (rst_out <>'')     then frmNewQSO.edtHisRST.Text    := rst_out;
     if (name <>'')        then frmNewQSO.edtName.Text      := name;
     if (qth <>'')         then frmNewQSO.edtQTH.Text       := qth;
     if (locator <>'')     then frmNewQSO.edtGrid.Text      := locator;
     if (state <>'')       then frmNewQSO.edtState.Text     := state;
     if (county <>'')      then frmNewQSO.edtCounty.Text    := county;
     if (notes <>'')       then frmNewQSO.edtRemQSO.Text    := notes;
   end;
end;

function Tfrmxfldigi.PollFldigi(LogItemCmd:String; out Rres:String):boolean;
const
  header   ='POST /RPC2 HTTP/1.0'#13#10'Host: localhost:7362'#13#10'Content-Type: text/xml'#13#10'Content-Length: ';
  xmlstart ='<?xml version="1.0"?>'#13#10'<methodCall>'#13#10'<methodName>';
  xmlend   ='</methodName>'#13#10'<params>'#13#10'</params>'#13#10'</methodCall>'#13#10;

var
     Rstart,
     Rend,
     Tout,
     cl        : integer;
     data,
//     Rres,
     buffer,
     MResp    : String;
     xmlok    : boolean;

begin
    xmlok   := false;
    xmlsock := TTCPBlockSocket.Create;
    xmlsock.Connect(cqrini.ReadString('fldigi','ip','127.0.0.1'),cqrini.ReadString('fldigi','port','7362'));

    if xmlsock.LastError = 0 then
    begin
         xmlok   := true;
         if dmData.DebugLevel>=1 then Writeln('Connected to fldigi');
         data := xmlstart + LogItemCmd + xmlend;
         cl   := length(data);
         data := header + IntToStr(cl) + #13#10#13#10 + data;
         MResp  := '';
         buffer := '';
         Tout := 1500;  // timeout

         xmlsock.SendString(data);
          if dmData.DebugLevel>=1 then Writeln('Sent: ',LogItemCmd );

          // Keep looping...
         repeat
              Begin
               buffer := xmlsock.RecvPacket(2000);
               MResp := MResp + buffer;
               // ...until there's no more data.
               dec(Tout);
               sleep(1);
               // or timeout.
              end;
         until ((buffer = '') or (Tout < 1 ));
        xmlsock.free;
        if dmData.DebugLevel>=1 then Writeln('Disconnected  fldigi');

        if  ( (length(MResp) > 0) and (pos('fault',MResp) = 0 ) )  then   //response does not incl word "fault"
         Begin
          Rres:='';
          Rstart :=0;
          Rend :=0;
          Rstart := pos('<value>',MResp);          // parse actual value from xml headers
          Rend   := pos('</value>',MResp);
          if dmData.DebugLevel>=1 then writeln ('RS:',Rstart,' RE:',Rend,' XR:', Mresp[Rstart]);
          if (Rstart > 0 ) and (Rend > 0) then
             Begin
                 Rstart:=rstart+7; //actual start of reponse value
                 while Rstart < Rend do
                       Begin
                        Rres :=Rres + MResp[Rstart];
                        inc(Rstart);
                       end;
             end;
          if dmData.DebugLevel>=1 then writeln ('Rcvd: ',Rres);
         end
       else
        Begin
         if dmData.DebugLevel>=1 then writeln ('Fldigi XMLerr: ',MResp);
        end;
    end  //xmlsock.LastError = 0
    else
     Begin
      if dmData.DebugLevel>=1 then writeln ('Socket error. Status: ',xmlsock.LastError);
     end;

    Result := xmlok;
end;

procedure Tfrmxfldigi.TimTime;

var
   mhz,
   Fdes,
   opmode :string;
   SockOK :Boolean;
   Drop   :integer;
   tmp    :extended;


begin
  frmNewQSO.tmrFldigi.Enabled := false;
  SockOK := true;
  with fLog[new] do
   Begin

     case cqrini.ReadInteger('fldigi','freq',0) of
            0 : begin
                  if  frmTRXControl.GetModeFreqNewQSO(opmode,mhz) then
                    frequency := mhz
                end;
            1 : begin
                  if SockOK then SockOK := PollFldigi('log.get_frequency',mhz);//here kHz
                  mhz := Trim(mhz);
                  if Pos('.', mhz) > 0 then mhz[Pos('.', mhz)] := FormatSettings.DecimalSeparator;
                  if pos(',', mhz) > 0 then mhz[pos(',', mhz)] := FormatSettings.DecimalSeparator;
                  if dmDXCluster.GetBandFromFreq(mhz,True) <> '' then
                    Begin
                      if TryStrToFloat(mhz,tmp) then
                        begin
                         tmp := tmp/1000;
                         frequency :=FloatToStrF(tmp,ffFixed,8,5);
                          if (dmUtils.GetBandFromFreq(frequency) <> frmNewQSO.old_t_band) then
                             Begin
                              frmNewQSO.old_t_band := dmUtils.GetBandFromFreq(frequency);
                              frmNewQSO.btnClearSatelliteClick(nil); //if band changes sat and prop cleared
                             end;
                        end;
                    end;
                  end;
            2 : frequency := cqrini.ReadString('fldigi','deffreq','3.600')
     end;
     if dmData.DebugLevel>=1 then Writeln('Qrg :', frequency);


     case cqrini.ReadInteger('fldigi','mode',1) of
            0 : begin
                  if frmTRXControl.GetModeFreqNewQSO(opmode,mhz) then
                    mode := opmode
                end;
            1 : begin
                  mode:='';submode:='';
                  if SockOK then SockOK := PollFldigi('modem.get_mode',mode);
                  if SockOK then SockOK := PollFldigi('modem.get_submode',submode);
                  if mode='' then  //old version of fldigi get_mode not supported, make different query
                     Begin
                      if SockOK then SockOK := PollFldigi('modem.get_name',mode);
                     end
                    else
                      mode:=dmUtils.ModeToCqr(mode,submode,dmData.DebugLevel>=1 );
                end;
            2 : begin
                  mode := cqrini.ReadString('fldigi','defmode','RTTY');
                end;
           end;
     if dmData.DebugLevel>=1 then Writeln('Mode :', mode);
     if SockOK then SockOK := PollFldigi('log.get_date_on',startdate);
     if SockOK then SockOK := PollFldigi('log.get_time_on',time_on);
     if SockOK then SockOK := PollFldigi('log.get_time_off',time_off);
     if SockOK then SockOK := PollFldigi('log.get_call',call);
     if SockOK then SockOK := PollFldigi('log.get_name',name);

    case cqrini.ReadInteger('fldigi','rst',0) of
      0 : begin
            if SockOK then SockOK := PollFldigi('log.get_rst_in',rst_in);
            if SockOK then SockOK := PollFldigi('log.get_rst_out',rst_out);
          end;
      1 : begin
            rst_out := cqrini.ReadString('fldigi','defrst','599');
            rst_in  := cqrini.ReadString('fldigi','defrst','599')
          end
    end;

     if SockOK then SockOK := PollFldigi('log.get_state',state);
     if SockOK then SockOK := PollFldigi('log.get_province',county);
     if SockOK then SockOK := PollFldigi('log.get_qth',qth);
     if SockOK then SockOK := PollFldigi('log.get_notes',notes);
     if SockOK then SockOK := PollFldigi('log.get_locator',locator);
     if SockOK then SockOK := PollFldigi('main.get_trx_state',trx_state);
     if not SockOK then notes := 'Socket error, check fldigi!';
   end;

     //reset AskSave if both calls empty
      if (fLog[old].call = fLog[new].call)
       and ( fLog[new].call = '') then
         Begin
            btSaveQSO.Visible := false;
         end;


     // it might be real qso going on
     if (   (fLog[old].call <> '')
        and (fLog[old].time_on <> '')
        and (fLog[old].rst_in <> '')
        and (fLog[old].rst_out <> '')
        and (fLog[old].trx_state ='TX') ) then
            Begin
                btSaveQSO.Visible := true;
            end;

     // set own form display
     SetMyFields(new);


     if (fLog[old].call <> fLog[new].call) then
                            frmNewQSO.ClearAll;
     //transfer to NewQso
     SetCqrFields(new);
      //log & qrz seek
     if (fLog[old].call <> fLog[new].call) then
                            frmNewQSO.edtCallExit(nil);

     fLog[old] := fLog[new];
     frmNewQSO.tmrFldigi.Enabled := true;

     Drop := cqrini.ReadInteger('fldigi', 'dropSyErr', 3);
     if (not SockOK) and (Drop >0) then
            Begin                        //remote mode will be disabled if >5 timer rounds with sync error
              inc(SyncErrCnt);           //fldigi may then be closed by operator.
              if SyncErrCnt > Drop then  //Leaves "Socket error, check fldigi!" to NewQSO's "Comment QSO" field
                     Begin
                      SyncErrCnt := 0;
                      frmNewQSO.DisableRemoteMode;
                     end;
            end
        else
            SyncErrCnt := 0;
end;

procedure Tfrmxfldigi.FormCreate(Sender: TObject);
begin
  with fLog[new] do          //init records at least once
   Begin
     frequency :='';
     time_on   :='';
     time_off  :='';
     call      :='';
     name      :='';
     rst_in    :='';
     rst_out   :='';
     state     :='';
     county    :='';
     qth       :='';
     mode      :='';
     notes     :='';
     locator   :='';
     trx_state :='RX';
   end;
  fLog[old] := fLog[new];
  SetMyFields(new);
end;

procedure Tfrmxfldigi.FormHide(Sender: TObject);
begin
  dmUtils.SaveWindowPos(frmxfldigi);
  frmxfldigi.hide;
end;

procedure Tfrmxfldigi.FormShow(Sender: TObject);
begin
   dmUtils.LoadWindowPos(frmxfldigi);
end;

procedure Tfrmxfldigi.btSaveQSOClick(Sender: TObject);
var s :string;
begin
  frmNewQSO.SaveRemote;
  PollFldigi('log.clear',s);
end;

procedure Tfrmxfldigi.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
   dmUtils.SaveWindowPos(frmxfldigi);
   frmNewQSO.DisableRemoteMode;
end;



initialization
  {$I fXfldigi.lrs}

end.
{ at  2022-03-31 test version of fldigi:
[saku@hamtpad ~]$ fldigi --xmlrpc-list
fldigi.list                     A:n     Returns the list of methods.
fldigi.name                     s:n     Returns the program name.
fldigi.version_struct           S:n     Returns the program version as a struct.
fldigi.version                  s:n     Returns the program version as a string.
fldigi.name_version             s:n     Returns the program name and version.
fldigi.config_dir               s:n     Returns the name of the configuration directory.
fldigi.terminate                n:i     Terminates fldigi. ``i'' is bitmask specifying data to save: 0=options; 1=log; 2=macros.
modem.get_mode                  s:n     Returns the ADIF mode for the current modem.
modem.get_submode               s:n     Returns the ADIF submode for the current modem.
modem.get_name                  s:n     Returns the name of the current modem.
modem.get_names                 A:n     Returns all modem names.
modem.get_id                    i:n     Returns the ID of the current modem.
modem.get_max_id                i:n     Returns the maximum modem ID number.
modem.set_by_name               s:s     Sets the current modem. Returns old name.
modem.set_by_id                 i:i     Sets the current modem. Returns old ID.
modem.set_carrier               i:i     Sets modem carrier. Returns old carrier.
modem.inc_carrier               i:i     Increments the modem carrier frequency. Returns the new carrier.
modem.get_carrier               i:n     Returns the modem carrier frequency.
modem.get_afc_search_range      i:n     Returns the modem AFC search range.
modem.set_afc_search_range      i:i     Sets the modem AFC search range. Returns the old value.
modem.inc_afc_search_range      i:i     Increments the modem AFC search range. Returns the new value.
modem.get_bandwidth             i:n     Returns the modem bandwidth.
modem.set_bandwidth             i:i     Sets the modem bandwidth. Returns the old value.
modem.inc_bandwidth             i:i     Increments the modem bandwidth. Returns the new value.
modem.get_quality               d:n     Returns the modem signal quality in the range [0:100].
modem.search_up                 n:n     Searches upward in frequency.
modem.search_down               n:n     Searches downward in frequency.
modem.olivia.set_bandwidth      n:i     Sets the Olivia bandwidth.
modem.olivia.get_bandwidth      i:n     Returns the Olivia bandwidth.
modem.olivia.set_tones          n:i     Sets the Olivia tones.
modem.olivia.get_tones          i:n     Returns the Olivia tones.
main.get_status1                s:n     Returns the contents of the first status field (typically s/n).
main.get_status2                s:n     Returns the contents of the second status field.
main.get_sideband               s:n     [DEPRECATED; use main.get_wf_sideband and/or rig.get_mode]
main.set_sideband               n:s     [DEPRECATED; use main.set_wf_sideband and/or rig.set_mode]
main.get_wf_sideband            s:n     Returns the current waterfall sideband.
main.set_wf_sideband            n:s     Sets the waterfall sideband to USB or LSB.
main.get_frequency              d:n     [DEPRECATED; use rig.get_frequency
main.set_frequency              d:d     Sets the RF carrier frequency. Returns the old value.
main.inc_frequency              d:d     Increments the RF carrier frequency. Returns the new value.
main.get_afc                    b:n     Returns the AFC state.
main.set_afc                    b:b     Sets the AFC state. Returns the old state.
main.toggle_afc                 b:n     Toggles the AFC state. Returns the new state.
main.get_squelch                b:n     Returns the squelch state.
main.set_squelch                b:b     Sets the squelch state. Returns the old state.
main.toggle_squelch             b:n     Toggles the squelch state. Returns the new state.
main.get_squelch_level          d:n     Returns the squelch level.
main.set_squelch_level          d:d     Sets the squelch level. Returns the old level.
main.inc_squelch_level          d:d     Increments the squelch level. Returns the new level.
main.get_reverse                b:n     Returns the Reverse Sideband state.
main.set_reverse                b:b     Sets the Reverse Sideband state. Returns the old state.
main.toggle_reverse             b:n     Toggles the Reverse Sideband state. Returns the new state.
main.get_lock                   b:n     Returns the Transmit Lock state.
main.set_lock                   b:b     Sets the Transmit Lock state. Returns the old state.
main.toggle_lock                b:n     Toggles the Transmit Lock state. Returns the new state.
main.get_txid                   b:n     Returns the TXID state.
main.set_txid                   b:b     Sets the TXID state. Returns the old state.
main.toggle_txid                b:n     Toggles the TXID state. Returns the new state.
main.get_rsid                   b:n     Returns the RSID state.
main.set_rsid                   b:b     Sets the RSID state. Returns the old state.
main.toggle_rsid                b:n     Toggles the RSID state. Returns the new state.
main.get_trx_status             s:n     Returns transmit/tune/receive status.
main.tx                         n:n     Transmits.
main.tune                       n:n     Tunes.
main.rsid                       n:n     [DEPRECATED; use main.{get,set,toggle}_rsid]
main.rx                         n:n     Receives.
main.rx_tx                      n:n     Sets normal Rx/Tx switching.
main.rx_only                    n:n     Disables Tx.
main.abort                      n:n     Aborts a transmit or tune.
main.get_trx_state              s:n     Returns T/R state.
main.get_tx_timing              n:s     Returns transmit duration for test string (samples:sample rate:secs).
main.get_char_rates             s:n     Returns table of char rates.
main.get_char_timing            n:i     Input: value of character. Returns transmit duration for specified character (samples:sample rate).
main.set_rig_name               n:s     [DEPRECATED; use rig.set_name]
main.set_rig_frequency          d:d     [DEPRECATED; use rig.set_frequency]
main.set_rig_modes              n:A     [DEPRECATED; use rig.set_modes
main.set_rig_mode               n:s     [DEPRECATED; use rig.set_mode
main.get_rig_modes              A:n     [DEPRECATED; use rig.get_modes]
main.get_rig_mode               s:n     [DEPRECATED; use rig.get_mode]
main.set_rig_bandwidths         n:A     [DEPRECATED; use rig.set_bandwidths]
main.set_rig_bandwidth          n:s     [DEPRECATED; use rig.set_bandwidth]
main.get_rig_bandwidth          s:n     [DEPRECATED; use rig.get_bandwidth]
main.get_rig_bandwidths         n:A     [DEPRECATED; use rig.get_bandwidths]
main.run_macro                  n:i     Runs a macro.
main.get_max_macro_id           i:n     Returns the maximum macro ID number.
rig.set_name                    n:s     Sets the rig name for xmlrpc rig
rig.get_name                    s:n     Returns the rig name previously set via rig.set_name
rig.set_frequency               d:d     Sets the RF carrier frequency. Returns the old value.
rig.set_smeter                  n:i     Sets the smeter returns null.
rig.set_pwrmeter                n:i     Sets the power meter returns null.
rig.set_modes                   n:A     Sets the list of available rig modes
rig.set_mode                    n:s     Selects a mode previously added by rig.set_modes
rig.get_modes                   A:n     Returns the list of available rig modes
rig.get_mode                    s:n     Returns the name of the current transceiver mode
rig.set_bandwidths              n:A     Sets the list of available rig bandwidths
rig.set_bandwidth               n:s     Selects a bandwidth previously added by rig.set_bandwidths
rig.get_frequency               d:n     Returns the RF carrier frequency.
rig.get_bandwidth               s:n     Returns the name of the current transceiver bandwidth
rig.get_bandwidths              A:n     Returns the list of available rig bandwidths
rig.get_notch                   s:n     Reports a notch filter frequency based on WF action
rig.set_notch                   n:i     Sets the notch filter position on WF
rig.enable_qsy                  n:i     Enable/disable (1/0) QSY for xmlrpc transceiver control
log.get_frequency               s:n     Returns the Frequency field contents.
log.get_time_on                 s:n     Returns the Time-On field contents.
log.get_time_off                s:n     Returns the Time-Off field contents.
log.get_date_on                 s:n     Returns the date associated with time_on field contents.
log.get_date_off                s:n     Returns the date associated with time_off field contents.
log.get_call                    s:n     Returns the Call field contents.
log.get_name                    s:n     Returns the Name field contents.
log.get_rst_in                  s:n     Returns the RST(r) field contents.
log.get_rst_out                 s:n     Returns the RST(s) field contents.
log.set_rst_in                  n:s     Sets the RST(r) field contents.
log.set_rst_out                 n:s     Sets the RST(s) field contents.
log.get_serial_number           s:n     Returns the serial number field contents.
log.set_serial_number           n:s     Sets the serial number field contents.
log.get_serial_number_sent      s:n     Returns the serial number (sent) field contents.
log.get_exchange                s:n     Returns the contest exchange field contents.
log.set_exchange                n:s     Sets the contest exchange field contents.
log.get_state                   s:n     Returns the State field contents.
log.get_province                s:n     Returns the Province field contents.
log.get_country                 s:n     Returns the Country field contents.
log.get_qth                     s:n     Returns the QTH field contents.
log.get_band                    s:n     Returns the current band name.
log.get_sideband                s:n     [DEPRECATED; use main.get_wf_sideband]
log.get_notes                   s:n     Returns the Notes field contents.
log.get_locator                 s:n     Returns the Locator field contents.
log.get_az                      s:n     Returns the AZ field contents.
log.clear                       n:n     Clears the contents of the log fields.
log.set_call                    n:s     Sets the Call field contents.
log.set_name                    n:s     Sets the Name field contents.
log.set_qth                     n:s     Sets the QTH field contents.
log.set_locator                 n:s     Sets the Locator field contents.
log.set_rst_in                  n:s     Sets the RST(r) field contents.
log.set_rst_out                 n:s     Sets the RST(s) field contents.
logbook.last_record             s:n     Returns the ADIF record of the last logbook record.
logbook.all_records             s:n     Returns the entire ADIF logbook currently opened.
main.flmsg_online               n:n     flmsg online indication
main.flmsg_available            n:n     flmsg data available
main.flmsg_transfer             n:n     data transfer to flmsg
main.flmsg_squelch              b:n     Returns the squelch state.
flmsg.online                    n:n     flmsg online indication
flmsg.available                 n:n     flmsg data available
flmsg.transfer                  n:n     data transfer to flmsg
flmsg.squelch                   b:n     Returns the squelch state.
flmsg.get_data                  6:n     Returns all RX data received since last query.
io.in_use                       s:n     Returns the IO port in use (ARQ/KISS).
io.enable_kiss                  n:n     Switch to KISS I/O
io.enable_arq                   n:n     Switch to ARQ I/O
text.get_rx_length              i:n     Returns the number of characters in the RX widget.
text.get_rx                     6:ii    Returns a range of characters (start, length) from the RX text widget.
text.clear_rx                   n:n     Clears the RX text widget.
text.add_tx                     n:s     Adds a string to the TX text widget.
text.add_tx_queu                n:s     Adds a string to the TX transmit queu.
text.add_tx_bytes               n:6     Adds a byte string to the TX text widget.
text.clear_tx                   n:n     Clears the TX text widget.
rxtx.get_data                   6:n     Returns all RXTX combined data since last query.
rx.get_data                     6:n     Returns all RX data received since last query.
tx.get_data                     6:n     Returns all TX data transmitted since last query.
spot.get_auto                   b:n     Returns the autospotter state.
spot.set_auto                   b:b     Sets the autospotter state. Returns the old state.
spot.toggle_auto                b:n     Toggles the autospotter state. Returns the new state.
spot.pskrep.get_count           i:n     Returns the number of callsigns spotted in the current session.
wefax.state_string              s:n     Returns Wefax engine state (tx and rx) for information.
wefax.skip_apt                  s:n     Skip APT during Wefax reception
wefax.skip_phasing              s:n     Skip phasing during Wefax reception
wefax.set_tx_abort_flag         s:n     Cancels Wefax image transmission
wefax.end_reception             s:n     End Wefax image reception
wefax.start_manual_reception    s:n     Starts fax image reception in manual mode
wefax.set_adif_log              s:b     Set/reset logging to received/transmit images to ADIF log file
wefax.set_max_lines             s:i     Set maximum lines for fax image reception
wefax.get_received_file         s:i     Waits for next received fax file, returns its name with a delay. Empty string if timeout.
wefax.send_file                 s:si    Send file. returns an empty string if OK otherwise an error message.
navtex.get_message              s:i     Returns next Navtex/SitorB message with a max delay in seconds.. Empty string if timeout.
navtex.send_message             s:s     Send a Navtex/SitorB message. Returns an empty string if OK otherwise an error message.

}
