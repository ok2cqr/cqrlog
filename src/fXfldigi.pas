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
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lbHeader: TLabel;
    lbTrx: TLabel;
    lbComm: TLabel;
    lbCoun: TLabel;
    lbQth: TLabel;
    lbGrid: TLabel;
    lbStat: TLabel;
    lbName: TLabel;
    lbCall: TLabel;
    lbFreq: TLabel;
    lbMode: TLabel;
    lbRstS: TLabel;
    lbRstR: TLabel;
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

//should this be thread? There should not be network problems this kind of case


uses  fTRXControl, dData, dUtils, uMyIni, fNewQSO;


procedure Tfrmxfldigi.SetMyFields(d:integer);
Begin
   with fLog[d] do
    Begin
     lbFreq.Caption := frequency;
     lbMode.Caption := mode;
     lbCall.Caption := call;
     lbName.Caption := name;
     lbRstR.Caption := rst_in;
     lbRstS.Caption := rst_out;
     lbStat.Caption := state;
     lbCoun.Caption := county;
     lbQth.Caption  := qth;
     lbComm.Caption := notes;
     lbGrid.Caption := locator;
     lbTrx.Caption  := trx_state;
    end;
end;
procedure Tfrmxfldigi.SetCqrFields(d:integer);

Begin
 with fLog[d] do
   Begin
     if (frequency <> '' ) then frmNewQSO.cmbFreq.text := frequency;
     if (mode <>'') then frmNewQSO.cmbMode.Text := mode;
     if (time_on <>'') then frmNewQSO.edtStartTime.Text := time_on[1]+time_on[2]+':'+time_on[3]+time_on[4];
     if (time_off <>'') then frmNewQSO.edtEndTime.Text   := time_off[1]+time_off[2]+':'+time_off[3]+time_off[4];
     frmNewQSO.edtCall.Text      := call;
     if (name <>'') then frmNewQSO.edtName.Text      := name;
     if (rst_in <>'') then frmNewQSO.edtMyRST.Text     := rst_in;
     if (rst_out <>'') then frmNewQSO.edtHisRST.Text    := rst_out;
     if (state <>'') then frmNewQSO.edtState.Text     := state;
     if (county <>'') then frmNewQSO.edtCounty.Text    := county;
     if (qth <>'') then frmNewQSO.edtQTH.Text       := qth;
     if (notes <>'') then frmNewQSO.edtRemQSO.Text    := notes;
     if (locator <>'') then frmNewQSO.edtGrid.Text      := locator;
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

begin
    xmlsock := TTCPBlockSocket.Create;
    xmlsock.Connect(cqrini.ReadString('fldigi','ip','127.0.0.1'),cqrini.ReadString('fldigi','port','7362'));

    if xmlsock.LastError = 0 then
    begin
         data := xmlstart + LogItemCmd + xmlend;
         cl   := length(data);
         data := header + IntToStr(cl) + #13#10#13#10 + data;
         MResp  := '';
         buffer := '';
         Tout := 1000;  // timeout

         xmlsock.SendString(data);
          //if dmData.DebugLevel>=1 then Writeln('Sent: ',LogItemCmd );

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

        if  ( (length(MResp) > 0) and (pos('fault',MResp) = 0 ) )  then   //response does not incl word "fault"
         Begin
          Rres:='';
          Rstart :=0;
          Rend :=0;
          Rstart := pos('<value>',MResp);          // parse actual value from xml headers
          Rend   := pos('</value>',MResp);
          //if dmData.DebugLevel>=1 then writeln ('RS:',Rstart,' RE:',Rend,' XR:', Mresp[Rstart]);
          if (Rstart > 0 ) and (Rend > 0) then
             Begin
                 Rstart:=rstart+7; //actual start of reponse value
                 while Rstart < Rend do
                       Begin
                        Rres :=Rres + MResp[Rstart];
                        inc(Rstart);
                       end;
             end;

         end
       else
         if dmData.DebugLevel>=1 then writeln ('Fldigi XMLerr: ',MResp);
     end

    else
      if dmData.DebugLevel>=1 then writeln ('Socket error. Status: ',xmlsock.LastError);

    Result := (xmlsock.LastError = 0);
end;

procedure Tfrmxfldigi.TimTime;

var
   mhz,
   Fdes,
   opmode :string;
   SockOK :Boolean;
   Drop   :integer;

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
                  mhz := copy(mhz,1,pos('.',mhz)-1);   //here kHz no decimals
                  Fdes := copy(mhz,length(mhz)-2,3); //decimal part of MHz
                  mhz := copy(mhz,1,length(mhz)-3); //integer part here
                  mhz := trim(mhz+'.'+Fdes);
                  if dmUtils.GetBandFromFreq(mhz) <> '' then
                    frequency := mhz
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
                  if SockOK then SockOK := PollFldigi('modem.get_name',mode);
                end;
            2 : begin
                  mode := cqrini.ReadString('fldigi','defmode','RTTY');
                end;
           end;
     if dmData.DebugLevel>=1 then Writeln('Mode :', mode);

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
  frmNewQSO.btnSave.Click;
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
{
fldigi xmlrpc log (get)commands:
log.get_frequency	s:n	Returns the Frequency field contents
log.get_time_on	        s:n	Returns the Time-On field contents
log.get_time_off	s:n	Returns the Time-Off field contents
log.get_call	        s:n	Returns the Call field contents
log.get_name	        s:n	Returns the Name field contents
log.get_rst_in	        s:n	Returns the RST(r) field contents
log.get_rst_out	        s:n	Returns the RST(s) field contents
log.get_serial_number	s:n	Returns the serial number field contents
log.get_serial_number_sent
                        s:n	Returns the serial number (sent) field contents
log.get_exchange	s:n	Returns the contest exchange field contents
log.set_exchange	n:s	Sets the contest exchange field contents
log.get_state	        s:n	Returns the State field contents
log.get_province	s:n	Returns the Province field contents
log.get_country	        s:n	Returns the Country field contents
log.get_qth	        s:n	Returns the QTH field contents
log.get_band	        s:n	Returns the current band name
log.get_notes	        s:n	Returns the Notes field contents
log.get_locator	        s:n	Returns the Locator field contents
log.get_az	        s:n	Returns the AZ field contents

modem.get_name	        s:n	Returns the name of the current modem
main.get_trx_state      s:n     Returns T/R state
log.clear	        n:n	Clears the contents of the log fields
}
