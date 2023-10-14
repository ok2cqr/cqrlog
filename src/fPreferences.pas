(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)


unit fPreferences;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ExtCtrls, StdCtrls, Buttons, inifiles, DB, process, Spin, ColorBox, lcltype,
  Calendar, EditBtn, uCWKeying, frExportPref, types, fileutil, LazFileUtils,LCLIntf, Dos;

type

  { TfrmPreferences }

  TfrmPreferences = class(TForm)
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    btnBrowseBackup1: TButton;
    btnDefineProfile1: TButton;
    btnHelp1: TButton;
    btnBPColor: TColorButton;
    btnSPColor: TColorButton;
    btnLPColor: TColorButton;
    btnWsjtPath: TButton;
    btnSecondLoad: TButton;
    btnFrequencies1: TButton;
    btnLoadFifth: TButton;
    btnLoadFourth: TButton;
    btnLoadThird: TButton;
    btnLoadSecond: TButton;
    btnOK: TButton;
    btnCancel: TButton;
    btnFrequencies: TButton;
    btnDefineProfile: TButton;
    btnSplit: TButton;
    btnThirdLoad: TButton;
    btnSelbFont: TButton;
    btnSeleFont: TButton;
    btnSelsFont: TButton;
    btnSelqFont: TButton;
    btnSetFirst: TButton;
    btnSetSecond: TButton;
    btnSetThird: TButton;
    btnSetFourth: TButton;
    btnSetFifth: TButton;
    btnLoadFirst: TButton;
    btnHelp: TButton;
    btnSelectBandFont: TButton;
    Button1: TButton;
    Button2: TButton;
    btnTestXplanet: TButton;
    btnFirstLoad: TButton;
    btnChangeDefaultFreq: TButton;
    btnKeyMacros: TButton;
    btnBrowseBackup: TButton;
    btnFldigiPath: TButton;
    btnChangeDefFreq: TButton;
    btnChangeDefMode: TButton;
    btnAlertCallsigns: TButton;
    btnCfgStorage: TButton;
    btnAddTrxMem : TButton;
    btnForceMembershipUpdate : TButton;
    cb136kHz: TCheckBox;
    cb472kHz: TCheckBox;
    cb160m: TCheckBox;
    cb5m: TCheckBox;
    cb8m: TCheckBox;
    cb122GHz: TCheckBox;
    cb134GHz: TCheckBox;
    cb241GHz: TCheckBox;
    cb80m: TCheckBox;
    cb40m: TCheckBox;
    cb30m: TCheckBox;
    cb20m: TCheckBox;
    cb17m: TCheckBox;
    cb15m: TCheckBox;
    cb12m: TCheckBox;
    cb10m: TCheckBox;
    cb6m: TCheckBox;
    cb2m: TCheckBox;
    cb70cm: TCheckBox;
    cb23cm: TCheckBox;
    cb13cm: TCheckBox;
    cb8cm: TCheckBox;
    cb5cm: TCheckBox;
    cb3cm: TCheckBox;
    cb1cm: TCheckBox;
    cb47GHz: TCheckBox;
    cb76GHz: TCheckBox;
    cb4m: TCheckBox;
    cb125m: TCheckBox;
    cb60m: TCheckBox;
    cb30cm: TCheckBox;
    cgLimit: TCheckGroup;
    cbNoKeyerReset: TCheckBox;
    chkUdUpEnabled: TCheckBox;
    chkUdUpOnline: TCheckBox;
    chkUdIncExch: TCheckBox;
    chkVoiceR: TCheckBox;
    chkUseHLBuffer: TCheckBox;
    chkUTC2R: TCheckBox;
    chkShow5M: TCheckBox;
    chkCPollR: TCheckBox;
    chkwsjtLoeQ: TCheckBox;
    chkModeReverse: TCheckBox;
    chkRPwrOn: TCheckBox;
    chkOperator: TCheckBox;
    chkIgnoreEdit: TCheckBox;
    chkIgnoreQSL: TCheckBox;
    chkDarcDok: TCheckBox;
    chkNewDOKTables: TCheckBox;
    chkRunRigCtld: TCheckBox;
    chkRSendCWR: TCheckBox;
    chkRVfo: TCheckBox;
    chkRBNMAutoConn: TCheckBox;
    chkRBNLink: TCheckBox;
    chkRot1AzMinMax: TCheckBox;
    chkRot2AzMinMax: TCheckBox;
    chkShowOwnPos: TCheckBox;
    chkDistance: TCheckBox;
    chkSTX: TCheckBox;
    chkSRX: TCheckBox;
    chkSTX_str: TCheckBox;
    chkSRX_str: TCheckBox;
    chkContestName: TCheckBox;
    chkShowB4call: TCheckBox;
    chkRXFreq : TCheckBox;
    chkSatellite : TCheckBox;
    chkPropagation : TCheckBox;
    chkSatelliteMode : TCheckBox;
    chkUpdateAMSATstatus : TCheckBox;
    chkCheckMembershipUpdate : TCheckBox;
    chkConToDXC: TCheckBox;
    chkFldXmlRpc: TCheckBox;
    chkQSOColor : TCheckBox;
    chkFillAwardField : TCheckBox;
    chkShowDxcCountry: TCheckBox;
    chkUseCallbookZonesEtc : TCheckBox;
    chkModeRelatedOnly : TCheckBox;
    chkTrxControlDebug : TCheckBox;
    chkShowCondxValues: TCheckBox;
    chkCondxCalcHF: TCheckBox;
    chkCondxCalcVHF: TCheckBox;
    chkCapFirstQTHLetter: TCheckBox;
    chkIgnoreLoTW: TCheckBox;
    chkExpCommet: TCheckBox;
    chkPlusToBandMap: TCheckBox;
    chkgridshowhint: TCheckBox;
    chkgriddotsinsteadspaces: TCheckBox;
    chkgridboldtitle: TCheckBox;
    chkgridsmallrows: TCheckBox;
    chkgridgreenbar: TCheckBox;
    chkCloseAfterUpload : TCheckBox;
    chkRunWsjt: TCheckBox;
    chkUseNewQSOFreqMode: TCheckBox;
    chkUseCallBookData: TCheckBox;
    chkHrUpEnabled: TCheckBox;
    chkHrUpOnline: TCheckBox;
    chkHaUpEnabled: TCheckBox;
    chkClUpEnabled: TCheckBox;
    chkHaupOnline: TCheckBox;
    chkAskBackup : TCheckBox;
    chkClUpOnline: TCheckBox;
    chkShow630M : TCheckBox;
    chkRBNAutoConn : TCheckBox;
    chkShowMiles : TCheckBox;
    chkIgnoreBandFreq : TCheckBox;
    chkRot1RunRotCtld: TCheckBox;
    chkRot2RunRotCtld: TCheckBox;
    chkClearRIT : TCheckBox;
    chkCountry: TCheckBox;
    chkShowBckEQSL: TCheckBox;
    chkSysUTC: TCheckBox;
    chkAllVariants: TCheckBox;
    chkeQSLRcvd: TCheckBox;
    chkeQSLRcvdDate: TCheckBox;
    chkQSLRAll: TCheckBox;
    chkeQSLSentDate: TCheckBox;
    chkeQSLSent: TCheckBox;
    chkShowLoTWInfo: TCheckBox;
    chkShowBckLoTW: TCheckBox;
    chkAutoQSLS: TCheckBox;
    chkAutoDQSLS: TCheckBox;
    chkAutoQQSLS: TCheckBox;
    chkIntQSLViewer: TCheckBox;
    chkQSLSentDate: TCheckBox;
    chkQSLRcvdDate: TCheckBox;
    chkAddAfterSaveQSO: TCheckBox;
    chkRunFldigi: TCheckBox;
    chkIgnoreQRZQSL: TCheckBox;
    chkMvToRem: TCheckBox;
    chkXplanetColor: TCheckBox;
    chkEnableBackup: TCheckBox;
    chkCompressBackup: TCheckBox;
    chkCont: TCheckBox;
    chkNewQSLTables: TCheckBox;
    chkSunUTC: TCheckBox;
    chkShow60M: TCheckBox;
    chkShow125M: TCheckBox;
    chkPotSpeed: TCheckBox;
    chkShowRecentQSOs: TCheckBox;
    chkUseDXCColors: TCheckBox;
    chkNewQSOLoTW: TCheckBox;
    chkIncLoTWDXCC: TCheckBox;
    chkLoTWQSLSDate: TCheckBox;
    chkLoTWQSLRDate: TCheckBox;
    chkLoTWQSLS: TCheckBox;
    chkLoTWQSLR: TCheckBox;
    chkState: TCheckBox;
    chkShowDeleted: TCheckBox;
    chkNewDXCCTables: TCheckBox;
    chkShow4M: TCheckBox;
    chkDeleteAfterQSO: TCheckBox;
    chkAutoSearch: TCheckBox;
    chkShowXplanet: TCheckBox;
    chkCloseXplanet: TCheckBox;
    chkShowActiveBand: TCheckBox;
    chkShowActiveMode: TCheckBox;
    chkSaveBandMap: TCheckBox;
    chkBandMapkHz: TCheckBox;
    chkShowIOTAInfo: TCheckBox;
    chkShowITUInfo: TCheckBox;
    chkShowWAZInfo: TCheckBox;
    chkUseDefaultSEttings: TCheckBox;
    chkAward3: TCheckBox;
    chkAward4: TCheckBox;
    chkAward5: TCheckBox;
    chkCallSign3: TCheckBox;
    chkCallSign4: TCheckBox;
    chkCallSign5: TCheckBox;
    chkCounty3: TCheckBox;
    chkCounty4: TCheckBox;
    chkCounty5: TCheckBox;
    chkDATA: TCheckBox;
    chkDate3: TCheckBox;
    chkDate4: TCheckBox;
    chkDate5: TCheckBox;
    chkDXCC3: TCheckBox;
    chkDXCC4: TCheckBox;
    chkDXCC5: TCheckBox;
    chkexAscTime: TCheckBox;
    chkFreq3: TCheckBox;
    chkFreq4: TCheckBox;
    chkFreq5: TCheckBox;
    chkIOTA3: TCheckBox;
    chkIOTA4: TCheckBox;
    chkIOTA5: TCheckBox;
    chkITU3: TCheckBox;
    chkITU4: TCheckBox;
    chkITU5: TCheckBox;
    chkLoc3: TCheckBox;
    chkLoc4: TCheckBox;
    chkLoc5: TCheckBox;
    chkMode3: TCheckBox;
    chkMode4: TCheckBox;
    chkMode5: TCheckBox;
    chkMyLoc3: TCheckBox;
    chkMyLoc4: TCheckBox;
    chkMyLoc5: TCheckBox;
    chkName3: TCheckBox;
    chkName4: TCheckBox;
    chkName5: TCheckBox;
    chkPower3: TCheckBox;
    chkPower4: TCheckBox;
    chkPower5: TCheckBox;
    chkProfile1: TCheckBox;
    chkQSL_R3: TCheckBox;
    chkQSL_R4: TCheckBox;
    chkQSL_R5: TCheckBox;
    chkQSL_S3: TCheckBox;
    chkQSL_S4: TCheckBox;
    chkQSL_S5: TCheckBox;
    chkQSL_VIA3: TCheckBox;
    chkQSL_VIA4: TCheckBox;
    chkQSL_VIA5: TCheckBox;
    chkQTH3: TCheckBox;
    chkQTH4: TCheckBox;
    chkQTH5: TCheckBox;
    chkRefreshAfterSave1: TCheckBox;
    chkRemarks3: TCheckBox;
    chkRemarks4: TCheckBox;
    chkRemarks5: TCheckBox;
    chkRST_R3: TCheckBox;
    chkRST_R4: TCheckBox;
    chkRST_R5: TCheckBox;
    chkRST_S3: TCheckBox;
    chkRST_S4: TCheckBox;
    chkRST_S5: TCheckBox;
    chkShow8M: TCheckBox;
    chkShow33CM: TCheckBox;
    chkSkipModeFreq: TCheckBox;
    chkRefreshAfterSave: TCheckBox;
    chkCW: TCheckBox;
    chkSSB: TCheckBox;
    chkShow125CM: TCheckBox;
    chkShow23CM: TCheckBox;
    chkShow3CM: TCheckBox;
    chkShow4MM: TCheckBox;
    chkShow70CM: TCheckBox;
    chkShow6CM: TCheckBox;
    chkShow9CM: TCheckBox;
    chkShow6M: TCheckBox;
    chkShow2M: TCheckBox;
    chkShow10M: TCheckBox;
    chkShow30M: TCheckBox;
    chkShow20M: TCheckBox;
    chkShow12M: TCheckBox;
    chkShow40M: TCheckBox;
    chkShow15M: TCheckBox;
    chkShow13CM: TCheckBox;
    chkShow80M: TCheckBox;
    chkShow160M: TCheckBox;
    chkShow2190M: TCheckBox;
    chkProfileRig: TCheckBox;
    chkProfileQTH: TCheckBox;
    chkProfileLocator: TCheckBox;
    chkShow17M: TCheckBox;
    chkShow6MM: TCheckBox;
    chkShow25MM: TCheckBox;
    chkShow2MM: TCheckBox;
    chkShow1MM: TCheckBox;
    chkSSB1: TCheckBox;
    chkTimeOff3: TCheckBox;
    chkTimeOff4: TCheckBox;
    chkTimeOff5: TCheckBox;
    chkTimeOn3: TCheckBox;
    chkTimeOn4: TCheckBox;
    chkTimeOn5: TCheckBox;
    chkUseProfiles: TCheckBox;
    chkUseSpaceBar: TCheckBox;
    chkITU: TCheckBox;
    chkWAZ: TCheckBox;
    chkRemarks: TCheckBox;
    chkDXCC: TCheckBox;
    chkPower: TCheckBox;
    chkCounty: TCheckBox;
    chkAward: TCheckBox;
    chkIOTA: TCheckBox;
    chkMyLoc: TCheckBox;
    chkLoc: TCheckBox;
    chkQSL_VIA: TCheckBox;
    chkQTH: TCheckBox;
    chkName: TCheckBox;
    chkRST_R: TCheckBox;
    chkRST_S: TCheckBox;
    chkQSL_R: TCheckBox;
    chkQSL_S: TCheckBox;
    chkFreq: TCheckBox;
    chkMode: TCheckBox;
    chkCallSign: TCheckBox;
    chkTimeOff: TCheckBox;
    chkTimeOn: TCheckBox;
    chkDate: TCheckBox;
    chkWAZ3: TCheckBox;
    chkWAZ4: TCheckBox;
    chkWAZ5: TCheckBox;
    cmbCl20db : TColorBox;
    cmbCl30db : TColorBox;
    cmbClOver30db : TColorBox;
    clBoxBandITU: TColorBox;
    clboxQSLIOTA: TColorBox;
    clboxNewITU: TColorBox;
    clboxNewIOTA: TColorBox;
    clBoxQSLITU: TColorBox;
    cmbDataBitsR: TComboBox;
    cmbDataBitsRot1: TComboBox;
    cmbDataBitsRot2: TComboBox;
    cmbDTRR: TComboBox;
    cmbHanshakeR: TComboBox;
    cmbUdColor: TColorBox;
    cmbModelRig: TComboBox;
    cmbModelRot1: TComboBox;
    cmbModelRot2: TComboBox;
    cmbParityR: TComboBox;
    cmbRTSR: TComboBox;
    cmbSpeedR: TComboBox;
    cmbStopBitsR: TComboBox;
    cmbWsjtDefaultMode: TComboBox;
    cmbDTRRot1: TComboBox;
    cmbDTRRot2: TComboBox;
    cmbHaColor: TColorBox;
    cmbClColor: TColorBox;
    cmbHrColor: TColorBox;
    cmbHanshakeRot1: TComboBox;
    cmbHanshakeRot2: TComboBox;
    cmbParityRot1: TComboBox;
    cmbParityRot2: TComboBox;
    cmbRTSRot1: TComboBox;
    cmbRTSRot2: TComboBox;
    cmbSpeedRot1: TComboBox;
    cmbSpeedRot2: TComboBox;
    cmbDefaultMode: TComboBox;
    cmbeQSLBckColor: TColorBox;
    cmbQSL_S: TComboBox;
    cmbSecondSaveTo: TComboBox;
    cmbStopBitsRot1: TComboBox;
    cmbStopBitsRot2: TComboBox;
    cmbThirdSaveTo: TComboBox;
    cmbSecondZip: TComboBox;
    cmbSecondClub: TComboBox;
    cmbThirdZip: TComboBox;
    cmbThirdClub: TComboBox;
    cmbFourthClub: TComboBox;
    cmbFifthClub: TComboBox;
    cmbMode: TComboBox;
    cmbNewMode: TColorBox;
    cmbQSLNeeded: TColorBox;
    cmbFreq: TComboBox;
    cmbProfiles: TComboBox;
    cmbNewCountry: TColorBox;
    cmbNewBand: TColorBox;
    clboxNewWaz: TColorBox;
    clBoxBandWAZ: TColorBox;
    clBoxQSLWAZ: TColorBox;
    cmbFirstClub: TComboBox;
    cmbQSOBandColor: TColorBox;
    cmbFrmDXCColor: TColorBox;
    cmbFirstZip: TComboBox;
    cmbFirstSaveTo: TComboBox;
    cmbXplanetColor: TColorBox;
    cmbLoTWBckColor: TColorBox;
    cmbCl10db : TColorBox;
    cmbRadioNr: TComboBox;
    cmbRadioModes: TComboBox;
    cmbCWRadio: TComboBox;
    cmbIfaceType: TComboBox;
    cmbDataMode: TComboBox;
    btnSelectQSOColor: TColorButton;
    DateEditCall: TDateEdit;
    DateEditLoc: TDateEdit;
    dlgColor : TColorDialog;
    edtCbQRZPass: TEdit;
    edtCbQRZCQPass: TEdit;
    edtCbQRZUser: TEdit;
    edtCbQRZCQUser: TEdit;
    edtUdAddress: TEdit;
    edtOperator: TEdit;
    edtCondxTextUrl: TEdit;
    edtDataCmd: TEdit;
    edtGCBeamWidth: TEdit;
    edtGCBeamLength: TEdit;
    edtHrdUrl: TEdit;
    edtClubLogUrl: TEdit;
    edtClubLogUrlDel: TEdit;
    edtHamQTHurl: TEdit;
    edtGCLineWidth: TEdit;
    edtGCStep: TEdit;
    edtGCPolarDivisor: TEdit;
    edtPoll: TEdit;
    edtRDevice: TEdit;
    edtRHost: TEdit;
    edtRRigCtldArgs: TEdit;
    edtRRigCtldPort: TEdit;
    edtRadioName: TEdit;
    edtUsr1R: TEdit;
    edtUsr1RName: TEdit;
    edtUsr2R: TEdit;
    edtUsr2RName: TEdit;
    edtUsr3R: TEdit;
    edtUsr3RName: TEdit;
    edtUsrBtn: TEdit;
    edtClub: TEdit;
    edtDataMode1: TEdit;
    edtCMD1: TEdit;
    edteQSLDnlAddr: TEdit;
    edteQSLStartAddr: TEdit;
    edteQSLViewAddr: TEdit;
    edtRot1Host: TEdit;
    edtRot2Host: TEdit;
    edtRotor2: TEdit;
    edtMailingAddress: TEdit;
    edtZipCity: TEdit;
    edtStartConCmd: TEdit;
    edtDropSyncErr: TSpinEdit;
    edtQSOColorDate : TEdit;
    edtWsjtIp: TEdit;
    edtCondxImageUrl: TEdit;
    edtBackupPath1: TEdit;
    edtWsjtDefaultFreq: TEdit;
    edtK3NGSerSpeed: TEdit;
    edtAlertCmd: TEdit;
    edtHamLibSpeed: TSpinEdit;
    edtRBNServer : TEdit;
    edtClEmail: TEdit;
    edtHrCode: TEdit;
    edtHrUserName: TEdit;
    edtHaPasswd: TEdit;
    edtClPasswd: TEdit;
    edtHaUserName: TEdit;
    edtDelAfter : TEdit;
    edtClUserName: TEdit;
    edtWatchFor : TEdit;
    edtRBNLogin : TEdit;
    edtRot1Poll: TEdit;
    edtRot2Poll: TEdit;
    edtRot1Device: TEdit;
    edtRot1RotCtldArgs: TEdit;
    edtRot1RotCtldPort: TEdit;
    edtRot2Device: TEdit;
    edtRot2RotCtldArgs: TEdit;
    edtRot2RotCtldPort: TEdit;
    edtRotor1: TEdit;
    edtRigCtldPath: TEdit;
    edtAM: TSpinEdit;
    edtClub1Date: TEdit;
    edtClub2Date: TEdit;
    edtClub4Date: TEdit;
    edtClub5Date: TEdit;
    edtClub3Date: TEdit;
    edtCW: TSpinEdit;
    edtFM: TSpinEdit;
    edtImgFiles: TEdit;
    edtHtmlFiles: TEdit;
    edtCbHamQTHPass: TEdit;
    edtCbHamQTHUser: TEdit;
    edteQSLName: TEdit;
    edteQSLPass: TEdit;
    edtRotCtldPath: TEdit;
    edtData: TSpinEdit;
    edtSSB: TSpinEdit;
    edtTxtFiles: TEdit;
    edtDigiModes: TEdit;
    edtFldigiPath: TEdit;
    edtBackupPath: TEdit;
    edtDefaultFreq: TEdit;
    edtDefaultRST: TEdit;
    edtGrayLineOffset: TEdit;
    edtSunOffset: TEdit;
    edtOffset: TEdit;
    edtCWAddress: TEdit;
    edtCWPort: TEdit;
    edtPdfFiles: TEdit;
    edtWinPort: TEdit;
    edtRecetQSOs: TEdit;
    edtLoTWPass: TEdit;
    edtLoTWName: TEdit;
    edtCWSpeed: TSpinEdit;
    edtWinMinSpeed: TSpinEdit;
    edtWinMaxSpeed: TSpinEdit;
    edtK3NGPort: TEdit;
    edtK3NGSpeed: TSpinEdit;
    edtFldigiIp: TEdit;
    edtADIFIp: TEdit;
    edtWsjtPath: TEdit;
    edtWsjtPort: TEdit;
    edtFldigiPort: TEdit;
    edtADIFPort: TEdit;
    edtXRefresh: TEdit;
    edtXLastSpots: TEdit;
    edtXTop: TEdit;
    edtXWidth: TEdit;
    edtXHeight: TEdit;
    edtXplanetLoc: TEdit;
    edtXplanetPath: TEdit;
    edtFirst: TEdit;
    edtSecond: TEdit;
    edtDisep: TEdit;
    edtWebBrowser: TEdit;
    edtDoNotShow1: TEdit;
    edtWAward1: TEdit;
    edtDoNotShow: TEdit;
    edtXLeft: TEdit;
    edtCIV3: TEdit;
    edtPasswd: TEdit;
    edtUser: TEdit;
    edtPort: TEdit;
    edtProxy: TEdit;
    edtComments: TEdit;
    edtPWR: TEdit;
    edtRST_S: TEdit;
    edtLoc: TEdit;
    edtCall: TEdit;
    edtQTH: TEdit;
    edtName: TEdit;
    edtRST_R: TEdit;
    dlgFont: TFontDialog;
    edtEmail: TEdit;
    fraExportPref1: TfraExportPref;
    grbRadio: TGroupBox;
    grbSerialR: TGroupBox;
    grbSerialRot1: TGroupBox;
    grbSerialRot2: TGroupBox;
    GroupBox1: TGroupBox;
    GroupBox10: TGroupBox;
    GroupBox11: TGroupBox;
    GroupBox12: TGroupBox;
    GroupBox13: TGroupBox;
    GroupBox14: TGroupBox;
    GroupBox15: TGroupBox;
    GroupBox16: TGroupBox;
    GroupBox17: TGroupBox;
    GroupBox18: TGroupBox;
    GroupBox19: TGroupBox;
    gbInternet: TGroupBox;
    GroupBox20: TGroupBox;
    GroupBox21: TGroupBox;
    GroupBox22: TGroupBox;
    GroupBox23: TGroupBox;
    GroupBox24: TGroupBox;
    GroupBox25: TGroupBox;
    GroupBox26: TGroupBox;
    GroupBox27: TGroupBox;
    gbLoTW: TGroupBox;
    gbWidths: TGroupBox;
    gbWinkeyer: TGroupBox;
    gbCwkeyer: TGroupBox;
    GroupBox31: TGroupBox;
    GroupBox32: TGroupBox;
    gbOffsets: TGroupBox;
    GroupBox34: TGroupBox;
    GroupBox47: TGroupBox;
    grpUsrDigitalModes: TGroupBox;
    gbeQSL: TGroupBox;
    grbRigBandWidths: TGroupBox;
    GroupBox38: TGroupBox;
    gbProfiles: TGroupBox;
    grbRigctldPath: TGroupBox;
    GroupBox41: TGroupBox;
    gbRot1: TGroupBox;
    gbRot2: TGroupBox;
    GroupBox44: TGroupBox;
    GroupBox45: TGroupBox;
    GroupBox46: TGroupBox;
    gbDXCAlert: TGroupBox;
    GroupBox48: TGroupBox;
    gbK3NGkey: TGroupBox;
    gbDXCColor: TGroupBox;
    GroupBox5: TGroupBox;
    gbHamlib: TGroupBox;
    GroupBox51: TGroupBox;
    GroupBox52: TGroupBox;
    gbDXCConnect: TGroupBox;
    gbDXCSpots: TGroupBox;
    GroupBox53: TGroupBox;
    GroupBox6: TGroupBox;
    GroupBox7: TGroupBox;
    GroupBox8: TGroupBox;
    GroupBox9: TGroupBox;
    grpUsrCmds: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label108: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label193: TLabel;
    Label194: TLabel;
    lblGCBeamWidth: TLabel;
    lblGCBeamLength: TLabel;
    lblGC_BP_Color: TLabel;
    lblRadio: TLabel;
    lblCWRadio: TLabel;
    lblNoRigForCW: TLabel;
    lblNrOfRadios: TLabel;
    lblNoRigForMode: TLabel;
    lblDataMode: TLabel;
    lblDataMode1: TLabel;
    lblLogDataMode: TLabel;
    lblRigDataCmd: TLabel;
    lblRName: TLabel;
    lblDeviceR: TLabel;
    lblExtra: TLabel;
    lblGC_SP_Color: TLabel;
    lblGC_LP_Color: TLabel;
    lblGCwidth: TLabel;
    lblGLOffset: TLabel;
    lblGCStep: TLabel;
    lblGCDivisor: TLabel;
    lblGCHint: TLabel;
    lblHost: TLabel;
    lblModelR: TLabel;
    lblPollR: TLabel;
    lblPortR: TLabel;
    lblserialRDataBits: TLabel;
    lblSerialRDtr: TLabel;
    lblSerialRHand: TLabel;
    lblSerialRParity: TLabel;
    lblSerialRRts: TLabel;
    lblSerialRSpd: TLabel;
    lblSerialRStop: TLabel;
    LblTimes: TLabel;
    Label17: TLabel;
    lblUsr1R: TLabel;
    lblUsr2R: TLabel;
    lblUsr3R: TLabel;
    lblUsrBtn: TLabel;
    Label26: TLabel;
    Label80: TLabel;
    Label81: TLabel;
    lblRbnWindowOpen: TLabel;
    lblHamlib: TLabel;
    lbCallW: TLabel;
    lbFreqW: TLabel;
    lbleQSLDnlAddr: TLabel;
    lbleQSLStartAddr: TLabel;
    lbleQSLViewAddr: TLabel;
    lblLoTWBkg: TLabel;
    Label100: TLabel;
    Label101: TLabel;
    Label102: TLabel;
    Label103: TLabel;
    Label104: TLabel;
    Label105: TLabel;
    Label106: TLabel;
    Label107: TLabel;
    lbleQSLUsr: TLabel;
    lbleQSLPass: TLabel;
    Label11: TLabel;
    Label111: TLabel;
    Label112: TLabel;
    lblintProxy: TLabel;
    Label124: TLabel;
    lblDevice1: TLabel;
    lbleQSLBkg: TLabel;
    lblRotId1: TLabel;
    lblIntPort: TLabel;
    lblIntUser: TLabel;
    lblPoll1: TLabel;
    lblExtaArgs1: TLabel;
    lblPort1: TLabel;
    lblSpeed1: TLabel;
    lblDataBits1: TLabel;
    lblStopBits1: TLabel;
    lblUtc: TLabel;
    lblHandshake1: TLabel;
    lblParity1: TLabel;
    lblDTR1: TLabel;
    lblRTS1: TLabel;
    lblDevice2: TLabel;
    lblRotId2: TLabel;
    lblPoll2: TLabel;
    lblExtaArgs2: TLabel;
    lblPort2: TLabel;
    lblSpeed2: TLabel;
    Label16: TLabel;
    lblDataBits2: TLabel;
    lblStopBits2: TLabel;
    lblHandshake2: TLabel;
    lblParity2: TLabel;
    lblDTR2: TLabel;
    lblRTS2: TLabel;
    lblRbnLogin : TLabel;
    lblRbnWatchFor : TLabel;
    lblRbnLoginHint : TLabel;
    lblRbnWatchForHint : TLabel;
    lblRigctdPath: TLabel;
    lblRbnHeader : TLabel;
    lblRbnSignal : TLabel;
    lblRbnColor : TLabel;
    lblRbnDb1 : TLabel;
    lblRbnDb2 : TLabel;
    lblRbnDb3 : TLabel;
    lblRbnDb4 : TLabel;
    lblRbnDeleteAfterSec : TLabel;
    Label179: TLabel;
    Label180: TLabel;
    Label181: TLabel;
    Label182: TLabel;
    Label183: TLabel;
    Label184: TLabel;
    Label185: TLabel;
    Label186: TLabel;
    Label187: TLabel;
    Label188: TLabel;
    Label189: TLabel;
    lnlRbnServer : TLabel;
    lblRbnAdrFormat : TLabel;
    Label192: TLabel;
    lblK3NGPort: TLabel;
    lblK3NGSpeed: TLabel;
    lblK3NGWPM: TLabel;
    lblK3NGSerSpeed: TLabel;
    lblGraylineHint: TLabel;
    Label198: TLabel;
    lblHamLibSpeed: TLabel;
    lblHamLibWPM: TLabel;
    Label202: TLabel;
    lblRig1DataMode: TLabel;
    lblRig1cmd: TLabel;
    lblADIFport: TLabel;
    lblADIFaddr: TLabel;
    lblwsjtport: TLabel;
    lblDnloadCondxImg: TLabel;
    lblCondxImgexample: TLabel;
    lblDebug : TLabel;
    Label207: TLabel;
    lblwsjtaddr: TLabel;
    lblDiffColor : TLabel;
    lblQsoColorDate : TLabel;
    Label48: TLabel;
    Label49: TLabel;
    Label50: TLabel;
    Label51: TLabel;
    lbl: TLabel;
    lblIntPasswd: TLabel;
    Label2: TLabel;
    Label23: TLabel;
    lblMode: TLabel;
    lblBandWidth: TLabel;
    lblCWbw: TLabel;
    lblSSBBw: TLabel;
    lblDataBw: TLabel;
    lblAMBw: TLabel;
    lblFMBw: TLabel;
    lblCWHz: TLabel;
    lblSSBHz: TLabel;
    lblDataHz: TLabel;
    lblAMHz: TLabel;
    lblFMHz: TLabel;
    Label52: TLabel;
    Label53: TLabel;
    Label54: TLabel;
    Label55: TLabel;
    Label56: TLabel;
    lblGrayline: TLabel;
    Label61: TLabel;
    Label63: TLabel;
    Label91: TLabel;
    Label92: TLabel;
    Label93: TLabel;
    lblSunRiseSet: TLabel;
    Label95: TLabel;
    lbl1: TLabel;
    lblButtons: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label40: TLabel;
    Label41: TLabel;
    Label42: TLabel;
    Label43: TLabel;
    Label44: TLabel;
    Label45: TLabel;
    Label5: TLabel;
    lblbFont: TLabel;
    lblEdits: TLabel;
    lblStatistics: TLabel;
    lblQSOList: TLabel;
    lblLoTWpass: TLabel;
    Label82: TLabel;
    lbIfaceType: TLabel;
    lblWinPort: TLabel;
    lblWinSpeed: TLabel;
    lblWinWPM: TLabel;
    lblCWAddr: TLabel;
    lblCWPort1: TLabel;
    lblCWDefSpeed: TLabel;
    lblCWWPM: TLabel;
    lblWinMinSpeed: TLabel;
    lblWinMaxSpeed: TLabel;
    Label99: TLabel;
    lbleFont: TLabel;
    lblgFont: TLabel;
    lblqFont: TLabel;
    Label57: TLabel;
    Label58: TLabel;
    Label6: TLabel;
    lblWebBrowser: TLabel;
    lblBandMapFont: TLabel;
    Label62: TLabel;
    Label64: TLabel;
    Label65: TLabel;
    Label66: TLabel;
    Label67: TLabel;
    Label68: TLabel;
    Label69: TLabel;
    Label7: TLabel;
    Label70: TLabel;
    Label71: TLabel;
    Label72: TLabel;
    Label73: TLabel;
    Label74: TLabel;
    Label75: TLabel;
    Label76: TLabel;
    Label77: TLabel;
    Label78: TLabel;
    Label79: TLabel;
    Label8: TLabel;
    lblLoUsr: TLabel;
    Label9: TLabel;
    lbleFont1: TLabel;
    lbPreferences: TListBox;
    dlgOpen: TOpenDialog;
    odFindBrowser: TOpenDialog;
    pnl2Host: TPanel;
    pnlHost1: TPanel;
    pgPreferences: TPageControl;
    Panel1: TPanel;
    pgROTControl: TPageControl;
    rbCondxAsText: TRadioButton;
    rbCondxAsImage: TRadioButton;
    rbHamQTH: TRadioButton;
    rbQRZ: TRadioButton;
    rbQRZCQ: TRadioButton;
    rgBackupType: TRadioGroup;
    rgRSTFrom: TRadioGroup;
    RadioGroup2: TRadioGroup;
    rbRSTDefault1: TRadioButton;
    rbRSTFldigi1: TRadioButton;
    rgWsjtFreqFrom: TRadioGroup;
    rgModeFrom: TRadioGroup;
    rgFreqFrom: TRadioGroup;
    rgFirstZipPos: TRadioGroup;
    rgWsjtModeFrom: TRadioGroup;
    rgSecondZipPos: TRadioGroup;
    rgThirdZipPos: TRadioGroup;
    rgShowFrom: TRadioGroup;
    rgProjection: TRadioGroup;
    rgStatistics: TRadioGroup;
    rbShowAll1: TRadioButton;
    rbShowSince1: TRadioButton;
    edtWinSpeed: TSpinEdit;
    edtLoadFromFldigi: TSpinEdit;
    seCallWidth: TSpinEdit;
    seFreqWidth: TSpinEdit;
    edtRigCount: TSpinEdit;
    tabExport: TTabSheet;
    tabExport1: TTabSheet;
    tabFont1: TTabSheet;
    tabModes1: TTabSheet;
    tabQTHProfiles1: TTabSheet;
    tabBandMap: TTabSheet;
    tabLoTW: TTabSheet;
    tabCWInterface: TTabSheet;
    tabFldigi1: TTabSheet;
    tabAutoBackup: TTabSheet;
    tabExtViewers: TTabSheet;
    tabCallbook: TTabSheet;
    TabROTcontrol: TTabSheet;
    tabRBN : TTabSheet;
    tabOnlineLog: TTabSheet;
    tabCondx: TTabSheet;
    tabRot1: TTabSheet;
    tabRot2: TTabSheet;
    tabZipCode: TTabSheet;
    tabXplanet: TTabSheet;
    tabStation: TTabSheet;
    tabFont: TTabSheet;
    tabIOTA: TTabSheet;
    tabMemebership: TTabSheet;
    tabWazItu: TTabSheet;
    TabSheet11: TTabSheet;
    TabSheet12: TTabSheet;
    TabSheet13: TTabSheet;
    TabSheet14: TTabSheet;
    TabSheet15: TTabSheet;
    TabSheet16: TTabSheet;
    TabSheet17: TTabSheet;
    TabSheet18: TTabSheet;
    tabNewQSO: TTabSheet;
    tabProgram: TTabSheet;
    tabVisibleColumns: TTabSheet;
    tabBands: TTabSheet;
    tabTRXcontrol: TTabSheet;
    tabModes: TTabSheet;
    tabQTHProfiles: TTabSheet;
    tabDXCluster: TTabSheet;
    procedure btnAddTrxMemClick(Sender : TObject);
    procedure btnAlertCallsignsClick(Sender: TObject);
    procedure btnBrowseBackup1Click(Sender: TObject);
    procedure btnCfgStorageClick(Sender: TObject);
    procedure btnChangeDefFreqClick(Sender: TObject);
    procedure btnChangeDefModeClick(Sender: TObject);
    procedure btnHelp1Click(Sender: TObject);
    procedure btnWsjtPathClick(Sender: TObject);
    procedure btnFldigiPathClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure btnBrowseBackupClick(Sender: TObject);
    procedure btnChangeDefaultFreqClick(Sender: TObject);
    procedure btnKeyMacrosClick(Sender: TObject);
    procedure btnSplitClick(Sender: TObject);
    procedure btnForceMembershipUpdateClick(Sender : TObject);
    procedure cbNoKeyerResetChange(Sender: TObject);
    procedure chkClUpEnabledChange(Sender: TObject);
    procedure chkHaUpEnabledChange(Sender: TObject);
    procedure chkHrUpEnabledChange(Sender: TObject);
    procedure chkUdUpEnabledChange(Sender: TObject);
    procedure chkIgnoreEditChange(Sender: TObject);
    procedure chkIgnoreLoTWChange(Sender: TObject);
    procedure chkIgnoreQSLChange(Sender: TObject);
    procedure chkPotSpeedChange(Sender: TObject);
    procedure chkProfileLocatorClick(Sender: TObject);
    procedure chkProfileQTHClick(Sender: TObject);
    procedure chkProfileRigClick(Sender: TObject);
    procedure chkRBNLinkChange(Sender: TObject);
    procedure chkSysUTCClick(Sender: TObject);
    procedure chkUseDXCColorsChange(Sender: TObject);
    procedure btnFirstLoadClick(Sender: TObject);
    procedure btnSecondLoadClick(Sender: TObject);
    procedure btnThirdLoadClick(Sender: TObject);
    procedure cmbCWRadioChange(Sender: TObject);
    procedure cmbCWRadioCloseUp(Sender: TObject);
    procedure cmbIfaceTypeChange(Sender: TObject);
    procedure cmbIfaceTypeCloseUp(Sender: TObject);
    procedure cmbModelRigChange(Sender: TObject);
    procedure cmbModelRot1Change(Sender: TObject);
    procedure cmbModelRot2Change(Sender: TObject);
    procedure cmbRadioModesChange(Sender: TObject);
    procedure cmbRadioModesCloseUp(Sender: TObject);
    procedure cmbRadioNrChange(Sender: TObject);
    procedure cmbRadioNrCloseUp(Sender: TObject);
    procedure edtAlertCmdExit(Sender: TObject);
    procedure edtDataCmdChange(Sender: TObject);
    procedure edtDigiModesExit(Sender: TObject);
    procedure edtGCBeamWidthChange(Sender: TObject);
    procedure edtGCLineWidthExit(Sender: TObject);
    procedure edtGCPolarDivisorExit(Sender: TObject);
    procedure edtGCStepExit(Sender: TObject);
    procedure edtHtmlFilesClick(Sender: TObject);
    procedure edtHtmlFilesExit(Sender: TObject);
    procedure edtImgFilesExit(Sender: TObject);
    procedure edtK3NGSerSpeedChange(Sender: TObject);
    procedure edtLocChange(Sender: TObject);
    procedure edtLocExit(Sender: TObject);
    procedure edtOperatorExit(Sender: TObject);
    procedure edtPdfFilesExit(Sender: TObject);
    procedure edtRecetQSOsKeyPress(Sender: TObject; var Key: char);
    procedure edtRigCountChange(Sender: TObject);
    procedure RotorParamsChange(Sender: TObject);
    procedure tabCWInterfaceContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure tabCWInterfaceExit(Sender: TObject);
    procedure tabModesExit(Sender: TObject);
    procedure tabTRXcontrolEnter(Sender: TObject);
    procedure TRXParamsChange(Sender: TObject);
    procedure edtTxtFilesExit(Sender: TObject);
    procedure edtWebBrowserClick(Sender: TObject);
    procedure edtWebBrowserExit(Sender: TObject);
    procedure edtWinSpeedChange(Sender: TObject);
    procedure edtXplanetLocChange(Sender: TObject);
    procedure lbPreferencesClick(Sender: TObject);
    procedure btnDefineProfileClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure btnLoadFifthClick(Sender: TObject);
    procedure btnLoadFirstClick(Sender: TObject);
    procedure btnLoadFourthClick(Sender: TObject);
    procedure btnLoadSecondClick(Sender: TObject);
    procedure btnLoadThirdClick(Sender: TObject);
    procedure btnSelbFontClick(Sender: TObject);
    procedure btnSeleFontClick(Sender: TObject);
    procedure btnSelectBandFontClick(Sender: TObject);
    procedure btnSelqFontClick(Sender: TObject);
    procedure btnSelsFontClick(Sender: TObject);
    procedure btnSetFifthClick(Sender: TObject);
    procedure btnSetFirstClick(Sender: TObject);
    procedure btnSetFourthClick(Sender: TObject);
    procedure btnSetSecondClick(Sender: TObject);
    procedure btnSetThirdClick(Sender: TObject);
    procedure btnTestXplanetClick(Sender: TObject);
    procedure chkUseProfilesChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure btnFrequenciesClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure edtPollExit(Sender: TObject);
    procedure pgPreferencesChange(Sender: TObject);
  private
    wasOnlineLogSupportEnabled : Boolean;
    RadioNrLoaded : integer;
    BandWNrLoaded : integer;
    CWifLoaded    : integer;
    procedure SaveTRX(RigNr:integer);
    procedure LoadTRX(RigNr:integer);
    procedure SaveBandW(RigNr:integer);
    procedure LoadBandW(RigNr:integer);
    procedure SaveCWif(RigNr:integer);
    procedure LoadCWif(RigNr:integer);
    procedure InitRigCmb(SetUsedRig:boolean=false);
    procedure ClearUnUsedRigs;
    procedure SaveClubSection;
    procedure LoadMebershipCombo;
    procedure LoadMembersFromCombo(ClubComboText, ClubNumber : String);
    function SeekExecFile(MyFile,MyExeFor:String): String;
    function DataModeInput(s:string):string;
    function WarnCheck(chk:boolean):boolean;

  public
    { public declarations }
    ActPageIdx : integer;

  end;

var
  frmPreferences: TfrmPreferences;
  feSize: integer;
  fbSize: integer;
  fgSize: integer;
  fqSize: integer;
  fbandSize: integer;
  TRXChanged: boolean;
  RotChanged: boolean;
  ReloadFreq: Boolean = False;
  ReloadModes: Boolean = False;
  CWKeyerChanged : Boolean;

implementation
{$R *.lfm}

{ TfrmPreferences }
uses dUtils, dData, fMain, fFreq, fQTHProfiles, fSerialPort, fClubSettings, fLoadClub,
  fGrayline, fNewQSO, fBandMap, fBandMapWatch, fDefaultFreq, fKeyTexts, fTRXControl,fRotControl,
  fSplitSettings, uMyIni, fNewQSODefValues, fDXCluster, fCallAlert, fConfigStorage, fPropagation,
  fRadioMemories, dMembership, dLogUpload;



function TfrmPreferences.WarnCheck(chk:boolean):boolean;
var
   s:PChar;
Begin
  Result:= chk;
  if chk then
     begin
           s:= 'Using this option MAY GIVE UNEXPECTED RESULTS'+LineEnding+
               'if you use MORE THAN ONE ONLINE LOG'+LineEnding+LineEnding+
               'Are you SURE you want to check this?';
           if Application.MessageBox(s,'Question ...', mb_YesNo + mb_IconQuestion) = idNo then
                                                                                           Result:=False;
     end;
end;

procedure TfrmPreferences.btnOKClick(Sender: TObject);
var
  freq : Currency;
  int  : integer;
  KeyType: TKeyType;
begin
  cqrini.SetCache(True);
  cqrini.WriteString('Station', 'Call', edtCall.Text);
  cqrini.WriteString('Station', 'Name', edtName.Text);
  cqrini.WriteString('Station', 'QTH', edtQTH.Text);
  cqrini.WriteString('Station', 'LOC', edtLoc.Text);
  cqrini.WriteString('Station', 'MailingAddress', edtMailingAddress.Text);
  cqrini.WriteString('Station', 'ZipCity', edtZipCity.Text);
  cqrini.WriteString('Station', 'Email', edtEmail.Text);
  cqrini.WriteString('Station', 'Club', edtClub.Text);

  cqrini.WriteString('NewQSO', 'RST_S', edtRST_S.Text);
  cqrini.WriteString('NewQSO', 'RST_R', edtRST_R.Text);
  cqrini.WriteString('NewQSO', 'PWR', edtPWR.Text);
  cqrini.WriteString('NewQSO', 'FREQ', cmbFreq.Text);
  cqrini.WriteString('NewQSO', 'Mode', cmbMode.Text);
  cqrini.WriteString('NewQSO', 'QSL_S', cmbQSL_S.Text);
  cqrini.WriteString('NewQSO', 'RemQSO', edtComments.Text);
  cqrini.WriteString('NewQSO', 'Op', edtOperator.Text);
  cqrini.WriteString('NewQSO', 'UsrBtn', edtUsrBtn.Text);
  cqrini.WriteBool('NewQSO', 'UseSpaceBar', chkUseSpaceBar.Checked);
  cqrini.WriteBool('NewQSO', 'RefreshAfterSave', chkRefreshAfterSave.Checked);
  cqrini.WriteBool('NewQSO', 'SkipModeFreq', chkSkipModeFreq.Checked);
  cqrini.WriteBool('NewQSO', 'AutoSearch', chkAutoSearch.Checked);
  cqrini.WriteBool('NewQSO', 'ShowRecentQSOs', chkShowRecentQSOs.Checked);
  cqrini.Writebool('NewQSO', 'ShowB4call', chkShowB4call.Checked);
  cqrini.WriteString('NewQSO', 'RecQSOsNum', edtRecetQSOs.Text);
  cqrini.WriteBool('NewQSO', 'IgnoreQRZ', chkIgnoreQRZQSL.Checked);
  cqrini.WriteBool('NewQSO', 'MvToRem', chkMvToRem.Checked);
  cqrini.WriteBool('NewQSO', 'AutoQSLS', chkAutoQSLS.Checked);
  cqrini.WriteBool('NewQSO', 'AutoDQSLS', chkAutoDQSLS.Checked);
  cqrini.WriteBool('NewQSO', 'AutoQQSLS', chkAutoQQSLS.Checked);
  cqrini.WriteBool('NewQSO', 'AllVariants', chkAllVariants.Checked);
  cqrini.WriteBool('NewQSO','ClearRIT',chkClearRIT.Checked);
  cqrini.WriteBool('NewQSO','UseCallBookData',chkUseCallBookData.Checked);
  cqrini.WriteBool('NewQSO','CapFirstQTHLetter',chkCapFirstQTHLetter.Checked);
  cqrini.WriteBool('NewQSO','UseCallbookZonesEtc',chkUseCallbookZonesEtc.Checked);
  cqrini.WriteBool('NewQSO','FillAwardField',chkFillAwardField.Checked);
  cqrini.WriteBool('NewQSO','SatelliteMode', chkSatelliteMode.Checked);
  cqrini.WriteBool('NewQSO','UpdateAMSATstatus', chkUpdateAMSATstatus.Checked);

  cqrini.WriteString('Program', 'Proxy', edtProxy.Text);
  cqrini.WriteString('Program', 'Port', edtPort.Text);
  cqrini.WriteString('Program', 'User', edtUser.Text);
  cqrini.WriteString('Program', 'Passwd', edtPasswd.Text);
  cqrini.WriteFloat('Program', 'offset', StrToCurr(edtOffset.Text));
  cqrini.WriteInteger('Program', 'Options', pgPreferences.ActivePageIndex);
  cqrini.WriteBool('Program', 'BandStatMHz', rgStatistics.ItemIndex = 0);
  cqrini.WriteFloat('Program', 'GraylineOffset', StrToCurr(edtGrayLineOffset.Text));
  cqrini.WriteFloat('Program', 'GraylineGCstep',StrToCurr(edtGCStep.Caption));
  cqrini.WriteInteger('Program', 'GraylineGCPolarDivisor',StrToInt(edtGCPolarDivisor.Caption));
  cqrini.WriteInteger('Program', 'GraylineGCLineWidth',StrToInt(edtGCLineWidth.Caption));
  cqrini.WriteString('Program', 'GraylineGCLineSPColor', ColorToString(btnSPColor.ButtonColor));
  cqrini.WriteString('Program', 'GraylineGCLineLPColor', ColorToString(btnLPColor.ButtonColor));
  cqrini.WriteString('Program', 'GraylineGCLineBEColor', ColorToString(btnBPColor.ButtonColor));
  cqrini.WriteInteger('Program', 'GraylineGBeamLineWidth',StrToInt(edtGCBeamWidth.Caption));
  cqrini.WriteInteger('Program', 'GraylineGBeamLineLength',StrToInt(edtGCBeamLength.Caption));

  if  edtWebBrowser.Text = '' then  edtWebBrowser.Text:= dmUtils.MyDefaultBrowser; //may not be empty string
  cqrini.WriteString('Program', 'WebBrowser', edtWebBrowser.Text);

  cqrini.WriteBool('Program', 'CheckDXCCTabs', chkNewDXCCTables.Checked);
  cqrini.WriteBool('Program', 'ShowDeleted', chkShowDeleted.Checked);
  cqrini.WriteBool('Program', 'SunUTC', chkSunUTC.Checked);
  cqrini.WriteBool('Program', 'CheckQSLTabs', chkNewQSLTables.Checked);
  cqrini.WriteBool('Program', 'CheckDOKTabs', chkNewDOKTables.Checked);
  cqrini.WriteFloat('Program', 'SunOffset', StrToCurr(edtSunOffset.Text));
  cqrini.WriteBool('Program', 'SysUTC', chkSysUTC.Checked);
  cqrini.WriteBool('Program','ShowMiles',chkShowMiles.Checked);
  cqrini.WriteBool('Program', 'QSODiffColor', chkQSOColor.Checked);
  cqrini.WriteInteger('Program', 'QSOColor', btnSelectQSOColor.ButtonColor);
  cqrini.WriteString('Program', 'QSOColorDate', edtQSOColorDate.Text);

  cqrini.WriteBool('Columns', 'Date', chkDate.Checked);
  cqrini.WriteBool('Columns', 'time_on', chkTimeOn.Checked);
  cqrini.WriteBool('Columns', 'time_off', chkTimeOff.Checked);
  cqrini.WriteBool('Columns', 'CallSign', chkCallSign.Checked);
  cqrini.WriteBool('Columns', 'Mode', chkMode.Checked);
  cqrini.WriteBool('Columns', 'Freq', chkFreq.Checked);
  cqrini.WriteBool('Columns', 'RST_S', chkRST_S.Checked);
  cqrini.WriteBool('Columns', 'RST_R', chkRST_R.Checked);
  cqrini.WriteBool('Columns', 'Name', chkName.Checked);
  cqrini.WriteBool('Columns', 'QTH', chkQTH.Checked);
  cqrini.WriteBool('Columns', 'QSL_S', chkQSL_S.Checked);
  cqrini.WriteBool('Columns', 'QSL_R', chkQSL_R.Checked);
  cqrini.WriteBool('Columns', 'QSL_VIA', chkQSL_VIA.Checked);
  cqrini.WriteBool('Columns', 'Locator', chkLoc.Checked);
  cqrini.WriteBool('Columns', 'MyLoc', chkMyLoc.Checked);
  cqrini.WriteBool('Columns', 'Operator', chkOperator.Checked);
  cqrini.WriteBool('Columns', 'Distance', chkDistance.Checked);
  cqrini.WriteBool('Columns', 'IOTA', chkIOTA.Checked);
  cqrini.WriteBool('Columns', 'Award', chkAward.Checked);
  cqrini.WriteBool('Columns', 'Power', chkPower.Checked);
  cqrini.WriteBool('Columns', 'DXCC', chkDXCC.Checked);
  cqrini.WriteBool('Columns', 'Remarks', chkRemarks.Checked);
  cqrini.WriteBool('Columns', 'WAZ', chkWAZ.Checked);
  cqrini.WriteBool('Columns', 'ITU', chkITU.Checked);
  cqrini.WriteBool('Columns', 'County', chkCounty.Checked);
  cqrini.WriteBool('Columns', 'State', chkState.Checked);
  cqrini.WriteBool('Columns', 'LoTWQSLSDate', chkLoTWQSLSDate.Checked);
  cqrini.WriteBool('Columns', 'LoTWQSLRDate', chkLoTWQSLRDate.Checked);
  cqrini.WriteBool('Columns', 'LoTWQSLS', chkLoTWQSLS.Checked);
  cqrini.WriteBool('Columns', 'LOTWQSLR', chkLoTWQSLR.Checked);
  cqrini.WriteBool('Columns', 'Cont', chkCont.Checked);
  cqrini.WriteBool('Columns', 'QSLSDate', chkQSLSentDate.Checked);
  cqrini.WriteBool('Columns', 'QSLRDate', chkQSLRcvdDate.Checked);
  cqrini.WriteBool('Columns', 'eQSLQSLS', chkeQSLSent.Checked);
  cqrini.WriteBool('Columns', 'eQSLQSLSDate', chkeQSLSentDate.Checked);
  cqrini.WriteBool('Columns', 'eQSLQSLR', chkeQSLRcvd.Checked);
  cqrini.WriteBool('Columns', 'eQSLQSLRDate', chkeQSLRcvdDate.Checked);
  cqrini.WriteBool('Columns', 'QSLRAll', chkQSLRAll.Checked);
  cqrini.WriteBool('Columns', 'Country', chkCountry.Checked);
  cqrini.WriteBool('Columns', 'Propagation', chkPropagation.Checked);
  cqrini.WriteBool('Columns', 'SatelliteName', chkSatellite.Checked);
  cqrini.WriteBool('Columns', 'RXFreq', chkRXFreq.Checked);
  cqrini.WriteBool('Columns', 'ContestName', chkContestName.Checked);
  cqrini.WriteBool('Columns', 'STX', chkSTX.Checked);
  cqrini.WriteBool('Columns', 'SRX', chkSRX.Checked);
  cqrini.WriteBool('Columns', 'ContMsgSent', chkSTX_str.Checked);
  cqrini.WriteBool('Columns', 'ContMsgRcvd', chkSRX_str.Checked);
  cqrini.WriteBool('Columns', 'DarcDok', chkDarcDok.Checked);

  cqrini.WriteBool('Bands', '137kHz', cb136kHz.Checked);
  cqrini.WriteBool('Bands', '472kHz', cb472kHz.Checked);
  cqrini.WriteBool('Bands', '160m', cb160m.Checked);
  cqrini.WriteBool('Bands', '80m', cb80m.Checked);
  cqrini.WriteBool('Bands', '60m', cb60m.Checked);
  cqrini.WriteBool('Bands', '40m', cb40m.Checked);
  cqrini.WriteBool('Bands', '30m', cb30m.Checked);
  cqrini.WriteBool('Bands', '20m', cb20m.Checked);
  cqrini.WriteBool('Bands', '17m', cb17m.Checked);
  cqrini.WriteBool('Bands', '15m', cb15m.Checked);
  cqrini.WriteBool('Bands', '12m', cb12m.Checked);
  cqrini.WriteBool('Bands', '10m', cb10m.Checked);

  cqrini.WriteBool('Bands', '8m', cb8m.Checked);
  cqrini.WriteBool('Bands', '6m', cb6m.Checked);
  cqrini.WriteBool('Bands', '5m', cb5m.Checked);
  cqrini.WriteBool('Bands', '4m', cb4m.Checked);
  cqrini.WriteBool('Bands', '2m', cb2m.Checked);
  cqrini.WriteBool('Bands', '1.25m', cb125m.Checked);
  cqrini.WriteBool('Bands', '70cm', cb70cm.Checked);
  cqrini.WriteBool('Bands', '33cm', cb30cm.Checked);

  cqrini.WriteBool('Bands', '23cm', cb23cm.Checked);
  cqrini.WriteBool('Bands', '13cm', cb13cm.Checked);
  cqrini.WriteBool('Bands', '8cm', cb8cm.Checked);
  cqrini.WriteBool('Bands', '5cm', cb5cm.Checked);
  cqrini.WriteBool('Bands', '3cm', cb3cm.Checked);
  cqrini.WriteBool('Bands', '1cm', cb1cm.Checked);
  cqrini.WriteBool('Bands', '47GHz', cb47GHz.Checked);
  cqrini.WriteBool('Bands', '76GHz', cb76GHz.Checked);
  cqrini.WriteBool('Bands', '122GHz', cb122GHz.Checked);
  cqrini.WriteBool('Bands', '134GHz', cb134GHz.Checked);
  cqrini.WriteBool('Bands', '241GHz', cb241GHz.Checked);

  cqrini.WriteString('TRX', 'RigCtldPath', edtRigCtldPath.Text);
  cqrini.WriteBool('TRX','Debug',chkTrxControlDebug.Checked);
  cqrini.WriteBool('TRX','MemModeRelated',chkModeRelatedOnly.Checked);
  cqrini.WriteInteger('TRX', 'RigCount', edtRigCount.Value);

  ClearUnUsedRigs;  //rigs modes and cw are saved when editing. Just delete unused rigs (model=empty)

  cqrini.WriteString('ROT', 'RotCtldPath', edtRotCtldPath.Text);

  cqrini.WriteString('ROT1', 'device', edtRot1Device.Text);
  cqrini.WriteString('ROT1', 'model',  dmUtils.GetRigIdFromComboBoxItem(cmbModelRot1.Text));
  cqrini.WriteString('ROT1', 'poll', edtRot1Poll.Text);
  cqrini.WriteString('ROT1', 'Desc', edtRotor1.Text);
  cqrini.WriteString('ROT1', 'RotCtldPort', edtRot1RotCtldPort.Text);
  cqrini.WriteString('ROT1', 'ExtraRotCtldArgs', edtRot1RotCtldArgs.Text);
  cqrini.WriteBool('ROT1', 'RunRotCtld', chkRot1RunRotCtld.Checked);
  cqrini.WriteBool('ROT1', 'RotAzMinMax', chkRot1AzMinMax.Checked);
  cqrini.WriteString('ROT1', 'host', edtRot1Host.Text);
  cqrini.WriteInteger('ROT1', 'SerialSpeed', cmbSpeedRot1.ItemIndex);
  cqrini.WriteInteger('ROT1', 'DataBits', cmbDataBitsRot1.ItemIndex);
  cqrini.WriteInteger('ROT1', 'StopBits', cmbStopBitsRot1.ItemIndex);
  cqrini.WriteInteger('ROT1', 'Parity', cmbParityRot1.ItemIndex);
  cqrini.WriteInteger('ROT1', 'HandShake', cmbHanshakeRot1.ItemIndex);
  cqrini.WriteInteger('ROT1', 'DTR', cmbDTRRot1.ItemIndex);
  cqrini.WriteInteger('ROT1', 'RTS', cmbRTSRot1.ItemIndex);

  cqrini.WriteString('ROT2', 'device', edtRot2Device.Text);
  cqrini.WriteString('ROT2', 'model', dmUtils.GetRigIdFromComboBoxItem(cmbModelRot2.Text));
  cqrini.WriteString('ROT2', 'poll', edtRot2Poll.Text);
  cqrini.WriteString('ROT2', 'Desc', edtRotor2.Text);
  cqrini.WriteString('ROT2', 'RotCtldPort', edtRot2RotCtldPort.Text);
  cqrini.WriteString('ROT2', 'ExtraRotCtldArgs', edtRot2RotCtldArgs.Text);
  cqrini.WriteBool('ROT2', 'RunRotCtld', chkRot2RunRotCtld.Checked);
  cqrini.WriteBool('ROT2', 'RotAzMinMax', chkRot2AzMinMax.Checked);
  cqrini.WriteString('ROT2', 'host', edtRot2Host.Text);
  cqrini.WriteInteger('ROT2', 'SerialSpeed', cmbSpeedRot2.ItemIndex);
  cqrini.WriteInteger('ROT2', 'DataBits', cmbDataBitsRot2.ItemIndex);
  cqrini.WriteInteger('ROT2', 'StopBits', cmbStopBitsRot2.ItemIndex);
  cqrini.WriteInteger('ROT2', 'Parity', cmbParityRot2.ItemIndex);
  cqrini.WriteInteger('ROT2', 'HandShake', cmbHanshakeRot2.ItemIndex);
  cqrini.WriteInteger('ROT2', 'DTR', cmbDTRRot2.ItemIndex);
  cqrini.WriteInteger('ROT2', 'RTS', cmbRTSRot2.ItemIndex);

  cqrini.WriteBool('Profiles', 'Use', chkUseProfiles.Checked);
  cqrini.WriteInteger('Profiles', 'Selected', dmData.GetNRFromProfile(cmbProfiles.Text));
  cqrini.WriteBool('Profiles', 'Locator', chkProfileLocator.Checked);
  cqrini.WriteBool('Profiles', 'QTH', chkProfileQTH.Checked);
  cqrini.WriteBool('Profiles', 'RIG', chkProfileRig.Checked);

  cqrini.WriteInteger('DXCluster', 'NewCountry', cmbNewCountry.Selected);
  cqrini.WriteInteger('DXCluster', 'NewBand', cmbNewBand.Selected);
  cqrini.WriteInteger('DXCluster', 'NewMode', cmbNewMode.Selected);
  cqrini.WriteInteger('DXCluster', 'NeedQSL', cmbQSLNeeded.Selected);
  cqrini.WriteBool('DXCluster', 'Show2190M', chkShow2190M.Checked);
  cqrini.WriteBool('DXCluster', 'Show630M', chkShow630M.Checked);
  cqrini.WriteBool('DXCluster', 'Show160M', chkShow160M.Checked);
  cqrini.WriteBool('DXCluster', 'Show80M', chkShow80M.Checked);
  cqrini.WriteBool('DXCluster', 'Show60M', chkShow60M.Checked);
  cqrini.WriteBool('DXCluster', 'Show40M', chkShow40M.Checked);
  cqrini.WriteBool('DXCluster', 'Show30M', chkShow30M.Checked);
  cqrini.WriteBool('DXCluster', 'Show20M', chkShow20M.Checked);
  cqrini.WriteBool('DXCluster', 'Show17M', chkShow17M.Checked);
  cqrini.WriteBool('DXCluster', 'Show15M', chkShow15M.Checked);
  cqrini.WriteBool('DXCluster', 'Show12M', chkShow12M.Checked);
  cqrini.WriteBool('DXCluster', 'Show10M', chkShow10M.Checked);
  cqrini.WriteBool('DXCluster', 'Show8M', chkShow8M.Checked);
  cqrini.WriteBool('DXCluster', 'Show6M', chkShow6M.Checked);
  cqrini.WriteBool('DXCluster', 'Show5M', chkShow5M.Checked);
  cqrini.WriteBool('DXCluster', 'Show4M', chkShow4M.Checked);
  cqrini.WriteBool('DXCluster', 'Show2M', chkShow2M.Checked);
  cqrini.WriteBool('DXCluster', 'Show125M', chkShow125M.Checked);
  cqrini.WriteBool('DXCluster', 'Show70CM', chkShow70CM.Checked);
  cqrini.WriteBool('DXCluster', 'Show33CM', chkShow33CM.Checked);
  cqrini.WriteBool('DXCluster', 'Show23CM', chkShow23CM.Checked);
  cqrini.WriteBool('DXCluster', 'Show13CM', chkShow13CM.Checked);
  cqrini.WriteBool('DXCluster', 'Show9CM', chkShow9CM.Checked);
  cqrini.WriteBool('DXCluster', 'Show6CM', chkShow6CM.Checked);
  cqrini.WriteBool('DXCluster', 'Show3CM', chkShow3CM.Checked);
  cqrini.WriteBool('DXCluster', 'Show125CM', chkShow125CM.Checked);
  cqrini.WriteBool('DXCluster', 'Show6MM', chkShow6MM.Checked);
  cqrini.WriteBool('DXCluster', 'Show4MM', chkShow4MM.Checked);
  cqrini.WriteBool('DXCluster', 'Show25MM', chkShow25MM.Checked);
  cqrini.WriteBool('DXCluster', 'Show2MM', chkShow2MM.Checked);
  cqrini.WriteBool('DXCluster', 'Show1MM', chkShow1MM.Checked);
  cqrini.WriteBool('DXCluster', 'CW', chkCW.Checked);
  cqrini.WriteBool('DXCluster', 'SSB', chkSSB.Checked);
  cqrini.WriteBool('DXCluster', 'DATA', chkDATA.Checked);
  cqrini.WriteString('DXCluster', 'NotShow', edtDoNotShow.Text);
  cqrini.WriteBool('DXCluster', 'ConAfterRun', chkConToDXC.Checked);
  cqrini.WriteBool('DXCluster','ShowDxcCountry',chkShowDxcCountry.Checked);
  cqrini.WriteString('DXCluster','AlertCmd', edtAlertCmd.Text);
  cqrini.WriteString('DXCluster','StartCmd', edtStartConCmd.Text);

  cqrini.WriteBool('Fonts', 'UseDefault', chkUseDefaultSEttings.Checked);
  cqrini.WriteString('Fonts', 'Buttons', lblbFont.Caption);
  cqrini.WriteString('Fonts', 'Edits', lbleFont.Caption);
  cqrini.WriteString('Fonts', 'Grids', lblgFont.Caption);
  cqrini.WriteString('Fonts', 'QGrids', lblqFont.Caption);
  cqrini.WriteInteger('Fonts', 'eSize', feSize);
  cqrini.WriteInteger('Fonts', 'bSize', fbSize);
  cqrini.WriteInteger('Fonts', 'gSize', fgSize);
  cqrini.WriteInteger('Fonts', 'qSize', fqSize);

  cqrini.WriteBool('Fonts','GridGreenBar',chkgridgreenbar.Checked);
  cqrini.WriteBool('Fonts','GridBoldTitle',chkgridboldtitle.Checked);
  cqrini.WriteBool('Fonts','GridShowHint',chkgridshowhint.Checked);
  cqrini.WriteBool('Fonts','GridSmallRows',chkgridsmallrows.Checked);
  cqrini.WriteBool('Fonts','GridDotsInsteadSpaces',chkgriddotsinsteadspaces.Checked);

  cqrini.WriteInteger('Zones', 'NewWAZ', clboxNewWaz.Selected);
  cqrini.WriteInteger('Zones', 'NewBandWAZ', clBoxBandWAZ.Selected);
  cqrini.WriteInteger('Zones', 'QSLWAZ', clBoxQSLWAZ.Selected);
  cqrini.WriteInteger('Zones', 'NewITU', clboxNewITU.Selected);
  cqrini.WriteInteger('Zones', 'NewBandITU', clBoxBandITU.Selected);
  cqrini.WriteInteger('Zones', 'QSLITU', clBoxQSLITU.Selected);
  cqrini.WriteBool('Zones', 'ShowWAZInfo', chkShowWAZInfo.Checked);
  cqrini.WriteBool('Zones', 'ShowITUInfo', chkShowITUInfo.Checked);

  cqrini.WriteInteger('IOTA', 'NewIOTA', clboxNewIOTA.Selected);
  cqrini.WriteInteger('IOTA', 'QSLIOTA', clboxQSLIOTA.Selected);
  cqrini.WriteBool('IOTA', 'ShowIOTAInfo', chkShowIOTAInfo.Checked);

  SaveClubSection;

  cqrini.WriteString('BandMap', 'BandFont', lblBandMapFont.Font.Name);
  cqrini.WriteInteger('BandMap', 'FontSize', fbandSize);
  cqrini.WriteInteger('BandMap', 'NewQSOColor', cmbQSOBandColor.Selected);
  cqrini.WriteBool('BandMap', 'in_kHz', chkBandMapkHz.Checked);
  cqrini.WriteBool('BandMap', 'Save', chkSaveBandMap.Checked);
  cqrini.WriteInteger('BandMap', 'FirstAging', StrToInt(edtFirst.Text));
  cqrini.WriteInteger('BandMap', 'SecondAging', StrToInt(edtSecond.Text));
  cqrini.WriteInteger('BandMap', 'Disep', StrToInt(edtDisep.Text));
  cqrini.WriteInteger('BandMap', 'ClusterColor', cmbFrmDXCColor.Selected);
  cqrini.WriteBool('BandMap', 'OnlyActiveBand', chkShowActiveBand.Checked);
  cqrini.WriteBool('BandMap', 'OnlyActiveMode', chkShowActiveMode.Checked);
  cqrini.WriteBool('BandMap', 'DeleteAfterQSO', chkDeleteAfterQSO.Checked);
  cqrini.WriteBool('BandMap', 'UseDXCColors', chkUseDXCColors.Checked);
  cqrini.WriteBool('BandMap', 'AddAfterQSO', chkAddAfterSaveQSO.Checked);
  cqrini.WriteBool('BandMap','IgnoreBandFreq',chkIgnoreBandFreq.Checked);
  cqrini.WriteBool('BandMap','UseNewQSOFreqMode',chkUseNewQSOFreqMode.Checked);
  cqrini.WriteBool('BandMap','PlusToBandMap',chkPlusToBandMap.Checked);
  cqrini.WriteInteger('BandMapFilter','FreqWidth',seFreqWidth.Value);
  cqrini.WriteInteger('BandMapFilter','CallWidth',seCallWidth.Value);

  cqrini.WriteString('xplanet', 'path', edtXplanetPath.Text);
  cqrini.WriteString('xplanet', 'height', edtXHeight.Text);
  cqrini.WriteString('xplanet', 'width', edtXWidth.Text);
  cqrini.WriteString('xplanet', 'top', edtXTop.Text);
  cqrini.WriteString('xplanet', 'left', edtXLeft.Text);
  cqrini.WriteBool('xplanet', 'run', chkShowXplanet.Checked);
  cqrini.WriteBool('xplanet', 'close', chkCloseXplanet.Checked);
  cqrini.WriteString('xplanet', 'refresh', edtXRefresh.Text);
  cqrini.WriteString('xplanet', 'LastSpots', edtXLastSpots.Text);
  cqrini.WriteInteger('xplanet', 'project', rgProjection.ItemIndex);
  cqrini.WriteInteger('xplanet', 'ShowFrom', rgShowFrom.ItemIndex);
  cqrini.WriteInteger('xplanet', 'color', cmbXplanetColor.Selected);
  cqrini.WriteBool('xplanet', 'UseDefColor', chkXplanetColor.Checked);
  cqrini.WriteString('xplanet', 'loc', edtXplanetLoc.Text);
  cqrini.WriteBool('xplanet', 'ShowOwnPos', chkShowOwnPos.Checked);

  cqrini.WriteString('ZipCode', 'First', cmbFirstZip.Text);
  cqrini.WriteString('ZipCode', 'FirstSaveTo', cmbFirstSaveTo.Text);
  cqrini.WriteInteger('ZipCode', 'FirstPos', rgFirstZipPos.ItemIndex);
  cqrini.WriteString('ZipCode', 'Second', cmbSecondZip.Text);
  cqrini.WriteString('ZipCode', 'SecondSaveTo', cmbSecondSaveTo.Text);
  cqrini.WriteInteger('ZipCode', 'SecondPos', rgSecondZipPos.ItemIndex);
  cqrini.WriteString('ZipCode', 'Third', cmbThirdZip.Text);
  cqrini.WriteString('ZipCode', 'ThirdSaveTo', cmbThirdSaveTo.Text);
  cqrini.WriteInteger('ZipCode', 'ThirdPos', rgThirdZipPos.ItemIndex);

  cqrini.WriteBool('LoTW', 'IncLoTWDXCC', chkIncLoTWDXCC.Checked);
  cqrini.WriteBool('LoTW', 'NewQSOLoTW', chkNewQSOLoTW.Checked);
  cqrini.WriteString('LoTW', 'LoTWName', edtLoTWName.Text);
  cqrini.WriteString('LoTW', 'LoTWPass', edtLoTWPass.Text);
  cqrini.WriteBool('LoTW', 'ShowInfo', chkShowLoTWInfo.Checked);
  cqrini.WriteBool('LoTW', 'UseBackColor', chkShowBckLoTW.Checked);
  cqrini.WriteInteger('LoTW', 'BckColor', cmbLoTWBckColor.Selected);
  cqrini.WriteString('LoTW', 'eQSLName', edteQSLName.Text);
  cqrini.WriteString('LoTW', 'eQSLPass', edteQSLPass.Text);
  cqrini.WriteString('LoTW', 'eQSLStartAddr',edteQSLStartAddr.Text);
  cqrini.WriteString('LoTW', 'eQSLDnlAddr',edteQSLDnlAddr.Text);
  cqrini.WriteString('LoTW', 'eQSViewAddr',edteQSLViewAddr.Text);
  cqrini.WriteBool('LoTW', 'eUseBackColor', chkShowBckEQSL.Checked);
  cqrini.WriteInteger('LoTW', 'eBckColor', cmbeQSLBckColor.Selected);
  cqrini.WriteBool('LoTW', 'ExpComment', chkExpCommet.Checked);

  cqrini.WriteInteger('fldigi', 'freq', rgFreqFrom.ItemIndex);
  cqrini.WriteString('fldigi', 'deffreq', edtDefaultFreq.Text);
  cqrini.WriteInteger('fldigi', 'mode', rgModeFrom.ItemIndex);
  cqrini.WriteString('fldigi', 'defmode', cmbDefaultMode.Text);
  cqrini.WriteString('fldigi', 'defrst', edtDefaultRST.Text);
  cqrini.WriteInteger('fldigi', 'rst', rgRSTFrom.ItemIndex);
  cqrini.WriteInteger('fldigi', 'interval', edtLoadFromFldigi.Value);
  cqrini.WriteBool('fldigi', 'run', chkRunFldigi.Checked);
  cqrini.WriteString('fldigi', 'path', edtFldigiPath.Text);
  cqrini.WriteString('fldigi','port',edtFldigiPort.Text);
  cqrini.WriteString('fldigi','ip',edtFldigiIp.Text);
  cqrini.WriteBool('fldigi', 'xmlrpc', chkFldXmlRpc.Checked);
  cqrini.WriteInteger('fldigi', 'dropSyErr', edtDropSyncErr.Value);

  cqrini.WriteString('wsjt','path',edtWsjtPath.Text);
  cqrini.WriteString('wsjt','port',edtWsjtPort.Text);
  cqrini.WriteString('wsjt','ip',edtWsjtIp.Text);
  cqrini.WriteBool('wsjt','run',chkRunWsjt.Checked);
  cqrini.WriteInteger('wsjt', 'freq', rgWsjtFreqFrom.ItemIndex);
  cqrini.WriteString('wsjt', 'deffreq', edtWsjtDefaultFreq.Text);
  cqrini.WriteInteger('wsjt', 'mode', rgWsjtModeFrom.ItemIndex);
  cqrini.WriteString('wsjt', 'defmode', cmbWsjtDefaultMode.Text);
  cqrini.WriteString('wsjt', 'wb4calldate', DateEditCall.Text);
  cqrini.WriteString('wsjt', 'wb4locdate', DateEditLoc.Text);
  cqrini.WriteBool('wsjt','wb4CCall', cgLimit.Checked[0]);
  cqrini.WriteBool('wsjt','wb4CLoc', cgLimit.Checked[1]);
  cqrini.WriteBool('wsjt', 'chkLoTWeQSL', chkwsjtLoeQ.Checked);

  cqrini.WriteString('n1mm','port',edtADIFPort.Text);
  cqrini.WriteString('n1mm','ip',edtADIFIp.Text);

  if edtBackupPath.Text <> '' then
    if edtBackupPath.Text[Length(edtBackupPath.Text)] <> PathDelim then
      edtBackupPath.Text := edtBackupPath.Text + PathDelim;
  cqrini.WriteBool('Backup', 'Enable', chkEnableBackup.Checked);
  cqrini.WriteBool('Backup', 'Compress', chkCompressBackup.Checked);
  cqrini.WriteString('Backup', 'Path', edtBackupPath.Text);
  cqrini.WriteString('Backup', 'Path1', edtBackupPath1.Text);
  cqrini.WriteInteger('Backup', 'BackupType', rgBackupType.ItemIndex);
  cqrini.WriteBool('Backup','AskFirst',chkAskBackup.Checked);

  cqrini.WriteString('ExtView', 'txt', edtTxtFiles.Text);
  cqrini.WriteString('ExtView', 'pdf', edtPdfFiles.Text);
  cqrini.WriteString('ExtView', 'img', edtImgFiles.Text);

  if  edtHtmlFiles.Text = '' then  edtHtmlFiles.Text:= dmUtils.MyDefaultBrowser; //may not be empty string
  cqrini.WriteString('ExtView', 'html', edtHtmlFiles.Text);

  cqrini.WriteBool('ExtView', 'QSL', chkIntQSLViewer.Checked);

  cqrini.WriteString('FirstClub', 'DateFrom', edtClub1Date.Text);
  cqrini.WriteString('SecondClub', 'DateFrom', edtClub2Date.Text);
  cqrini.WriteString('ThirdClub', 'DateFrom', edtClub3Date.Text);
  cqrini.WriteString('FourthClub', 'DateFrom', edtClub4Date.Text);
  cqrini.WriteString('FifthClub', 'DateFrom', edtClub5Date.Text);

  cqrini.WriteBool('CallBook', 'QRZ', rbQRZ.Checked);
  cqrini.WriteBool('CallBook', 'QRZCQ', rbQRZCQ.Checked);
  cqrini.WriteBool('Callbook', 'HamQTH', rbHamQTH.Checked);
  cqrini.WriteString('CallBook', 'CbHamQTHUser', edtCbHamQTHUser.Text);
  cqrini.WriteString('CallBook', 'CbHamQTHPass', edtCbHamQTHPass.Text);
  cqrini.WriteString('CallBook', 'CbQRZUser', edtCbQRZUser.Text);
  cqrini.WriteString('CallBook', 'CbQRZPass', edtCbQRZPass.Text);
  cqrini.WriteString('CallBook', 'CbQRZCQUser', edtCbQRZCQUser.Text);
  cqrini.WriteString('CallBook', 'CbQRZCQPass', edtCbQRZCQPass.Text);

  cqrini.WriteInteger('RBN','10db',cmbCl10db.Selected);
  cqrini.WriteInteger('RBN','20db',cmbCl20db.Selected);
  cqrini.WriteInteger('RBN','30db',cmbCl30db.Selected);
  cqrini.WriteInteger('RBN','over30db',cmbClOver30db.Selected);
  cqrini.WriteString('RBN','login',edtRBNLogin.Text);
  cqrini.WriteString('RBN','watch',edtWatchFor.Text);
  cqrini.WriteBool('RBN','AutoConnect',chkRBNAutoConn.Checked);
  cqrini.WriteBool('RBN','AutoConnectM',chkRBNMAutoConn.Checked);
  cqrini.WriteBool('RBN','AutoLink',chkRBNLink.Checked);
  if TryStrToInt(edtDelAfter.Text,int) then
    cqrini.WriteInteger('RBN','deleteAfter',int)
  else
    cqrini.WriteInteger('RBN','deleteAfter',60);
  cqrini.WriteString('RBN','Server',edtRBNServer.Text);

  cqrini.WriteBool('OnlineLog','HaUP',chkHaUpEnabled.Checked);
  cqrini.WriteBool('OnlineLog','HaUpOnline',chkHaUpOnline.Checked);
  cqrini.WriteString('OnlineLog','HaUserName',edtHaUserName.Text);
  cqrini.WriteString('OnlineLog','HaPasswd',edtHaPasswd.Text);
  cqrini.WriteInteger('OnlineLog','HaColor',cmbHaColor.Selected);
  cqrini.WriteString('OnlineLog','HaUrl',edtHamQthUrl.Text);

  cqrini.WriteBool('OnlineLog','ClUP',chkClUpEnabled.Checked);
  cqrini.WriteBool('OnlineLog','ClUpOnline',chkClUpOnline.Checked);
  cqrini.WriteString('OnlineLog','ClUserName',edtClUserName.Text);
  cqrini.WriteString('OnlineLog','ClPasswd',edtClPasswd.Text);
  cqrini.WriteString('OnlineLog','ClEmail',edtClEmail.Text);
  cqrini.WriteInteger('OnlineLog','ClColor',cmbClColor.Selected);
  cqrini.WriteString('OnlineLog','ClUrl',edtClubLogUrl.Text);
  cqrini.WriteString('OnlineLog','ClUrlDel',edtClubLogUrlDel.Text);

  cqrini.WriteBool('OnlineLog','HrUP',chkHrUpEnabled.Checked);
  cqrini.WriteBool('OnlineLog','HrUpOnline',chkHrUpOnline.Checked);
  cqrini.WriteString('OnlineLog','HrUserName',edtHrUserName.Text);
  cqrini.WriteString('OnlineLog','HrCode',edtHrCode.Text);
  cqrini.WriteInteger('OnlineLog','HrColor',cmbHrColor.Selected);

  cqrini.WriteBool('OnlineLog','UdUP',chkUdUpEnabled.Checked);
  cqrini.WriteBool('OnlineLog','UdUpOnline',chkUdUpOnline.Checked);
  cqrini.WriteString('OnlineLog','UdAddress',edtUdAddress.Text);
  cqrini.WriteBool('OnlineLog','UdIncExch',chkUdIncExch.Checked);
  cqrini.WriteInteger('OnlineLog','UdColor',cmbUdColor.Selected);

  cqrini.WriteBool('OnlineLog','CloseAfterUpload',chkCloseAfterUpload.Checked);
  cqrini.WriteBool('OnlineLog','IgnoreLoTWeQSL',chkIgnoreLoTW.Checked);
  cqrini.WriteBool('OnlineLog','IgnoreQSL',chkIgnoreQSL.Checked);
  cqrini.WriteBool('OnlineLog','IgnoreEdit',chkIgnoreEdit.Checked);
  cqrini.WriteString('OnlineLog','HrUrl',edtHrdUrl.Text);

  cqrini.WriteString('prop','Url',edtCondxImageUrl.Text);
  cqrini.WriteString('prop','UrlTxt',edtCondxTextUrl.Text);
  cqrini.WriteBool('prop','AsImage',rbCondxAsImage.Checked);
  cqrini.WriteBool('prop','AsText',rbCondxAsText.Checked);
  cqrini.WriteBool('prop','Values',chkShowCondxValues.Checked);
  cqrini.WriteBool('prop','CalcHF',chkCondxCalcHF.Checked);
  cqrini.WriteBool('prop','CalcVHF',chkCondxCalcVHF.Checked);

  if CWKeyerChanged then frmNewQSO.InitializeCW;

  fraExportPref1.SaveExportPref;

  dmUtils.TimeOffset := StrToCurr(edtOffset.Text);
  dmUtils.GrayLineOffset := StrToCurr(edtGrayLineOffset.Text);
  dmUtils.SysUTC := chkSysUTC.Checked;

  frmNewQSO.CalculateLocalSunRiseSunSet;

  dmData.InsertProfiles(frmNewQSO.cmbProfiles, False);
  frmNewQSO.cmbProfiles.Text := dmData.GetDefaultProfileText;

  frmBandMap.LoadSettings;

  if frmGrayline.Showing then
    frmGrayline.tmrGrayLineTimer(nil);
  frmNewQSO.UseSpaceBar := chkUseSpaceBar.Checked;
  if frmBandMap.Showing then
    frmBandMap.LoadFonts;
  cqrini.SaveToDisk;
  if TRXChanged then
    frmTRXControl.InitializeRig;
  if RotChanged then
    frmRotControl.InicializeRot;

  frmTRXControl.LoadUsrButtonCaptions;
  frmTRXControl.LoadButtonCaptions;
  frmTRXControl.LoadBandButtons;

  frmNewQSO.ClearAfterFreqChange := False;//cqrini.ReadBool('NewQSO','ClearAfterFreqChange',False);
  frmNewQSO.ChangeFreqLimit      := cqrini.ReadFloat('NewQSO','FreqChange',0.010);

  if not chkSatelliteMode.Checked then
     Begin
      if  (cqrini.ReadInteger('NewQSO','DetailsTabIndex', 0) > 1 ) then
          cqrini.WriteInteger('NewQSO','DetailsTabIndex',1);
      frmNewQSO.btnClearSatelliteClick(nil);
     end;

  frmNewQSO.pgDetails.TabIndex:=  cqrini.ReadInteger('NewQSO','DetailsTabIndex', 0);
  frmNewQSO.pgDetails.Pages[2].TabVisible := chkSatelliteMode.Checked;
  frmNewQSO.pgDetails.Pages[3].TabVisible := chkSatelliteMode.Checked;


  if ReloadFreq then
    dmUtils.InsertFreq(frmNewQSO.cmbFreq);
  if ReloadModes then
    dmUtils.InsertModes(frmNewQSO.cmbMode);
  if frmNewQSO.edtCall.Text = '' then
  begin
    dmUtils.InsertModes(frmNewQSO.cmbMode);
    frmNewQSO.cmbMode.Text := cmbMode.Text;
  end;

  if (not (chkHaUpEnabled.Checked or chkClUpEnabled.Checked or chkHrUpEnabled.Checked or chkUdUpEnabled.Checked)) then
  begin
    if wasOnlineLogSupportEnabled then
      dmLogUpload.DisableOnlineLogSupport
  end
  else begin
    if not wasOnlineLogSupportEnabled then
    begin
      if dmData.TriggersExistsOnCqrlog_main then
        dmLogUpload.DisableOnlineLogSupport;
      dmLogUpload.EnableOnlineLogSupport
    end
  end;

  if frmPropagation.Showing then
    frmPropagation.RefreshPropagation;

  frmNewQSO.Op:=edtOperator.text;
  cqrini.WriteString('TMPQSO','OP',edtOperator.text);
  frmNewQSO.ShowOperator;

  frmTRXControl.SetDebugMode(chkTrxControlDebug.Checked or (dmData.DebugLevel>0));

  if ((frmNewQSO.sbNewQSO.Panels[0].Text = '') or (frmNewQSO.sbNewQSO.Panels[0].Text = cMyLoc)) then
   Begin
    frmNewQSO.sbNewQSO.Panels[0].Text := cMyLoc + edtLoc.Text;
    frmNewQSO.CurrentMyLoc:=edtLoc.Text;
   end;

  if frmMain.Visible then frmMain.ShowFields;

  cqrini.SaveToDisk;
  dmData.SaveConfigFile;
  frmDXCluster.ReloadSettings;
  ModalResult := mrOk;
  dmUtils.LoadBandLabelSettins;
  dmUtils.LoadBandsSettings;
  dmData.LoadClubsSettings;
  dmData.LoadZipSettings;
  dmUtils.UpdateHelpBrowser;
  cqrini.SetCache(False);
end;

procedure TfrmPreferences.FormCreate(Sender: TObject);
begin
  dmUtils.InsertQSL_S(cmbQSL_S);
  dmUtils.InsertFreq(cmbFreq);
  ActPageIdx := 0; //tabProgram
  Label17.Caption:='';
end;


procedure TfrmPreferences.btnFrequenciesClick(Sender: TObject);
begin
  frmFreq := TfrmFreq.Create(frmPreferences);
  try
    frmFreq.ShowModal
  finally
    frmFreq.Free
  end;
  //init user defined bands vs frequencies
  dmUtils.BandFromDbase;
end;

procedure TfrmPreferences.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  dmUtils.SaveWindowPos(self);
  cqrini.WriteInteger('Pref', 'ActPageIdx', pgPreferences.ActivePageIndex);
end;

procedure TfrmPreferences.chkUseProfilesChange(Sender: TObject);
begin
  if chkUseProfiles.Checked then
    gbProfiles.Enabled := True
  else
    gbProfiles.Enabled := False;
end;

procedure TfrmPreferences.btnDefineProfileClick(Sender: TObject);
begin
  frmQTHProfiles := TfrmQTHProfiles.Create(self);
  try
    frmQTHProfiles.ShowModal
  finally
    frmQTHProfiles.Free
  end;
  dmData.InsertProfiles(cmbProfiles, False);
  cmbProfiles.Text := dmData.GetDefaultProfileText;
end;

procedure TfrmPreferences.btnHelpClick(Sender: TObject);

var
    HelpAddr : array [-1 .. 26] of string = (
    'h1.html',      //preferences, none tab selected
    'h1.html#ah2',  //program
    'h1.html#ah3',  //station
    'h1.html#ah4',  //new qso
    'h1.html#ah5',  //visible columns
    'h1.html#ah6',  //bands
    'h1.html#ah7',  //trx control
    'h1.html#ah7b', //rot control
    'h1.html#ah8',  //modes
    'h1.html#ah9',  //qth profiles
    'h1.html#ah10', //export
    'h1.html#ah11', //dx cluster
    'h1.html#ah12', //fonts
    'h1.html#ah13', //waz itu zones
    'h1.html#ah14', //iota
    'h1.html#ah15', //membership
    'h1.html#bh1 ', //bandmap
    'h1.html#bh2',  //xplanet support
    'h1.html#bh3',  //zip code tracking
    'h1.html#bh4',  //lotw support
    'h1.html#ch1',  //cw interface
    'h1.html#ch2',  //fldigi wsjt-x ADIF interface
    'h1.html#ch3',  //autobackup
    'h1.html#ch4',  //external viewers
    'h1.html#ch5',  //callbook support
    'h1.html#ch6',  //rbn support
    'h1.html#ch7',  //online log upload support
    'h1.html#ch9'   //propagation
    );

begin
  dmUtils.OpenInApp('file://' + dmData.HelpDir + HelpAddr[pgPreferences.TabIndex] );
  //ShowHelp;
{
 this feels stupid but I could not find any other way to bind help-button to active tab's help
 Because of:

 procedure TControl.ShowHelp;
  Begin
  ...
  ...
   if Parent <> nil then  <-------------!!!! I THINK: this leads always to show upper level help !!!!
      Parent.ShowHelp;
  end;
 }

end;

procedure TfrmPreferences.btnLoadFifthClick(Sender: TObject);
begin
  LoadMembersFromCombo(cmbFifthClub.Text, '5')
end;

procedure TfrmPreferences.btnLoadFirstClick(Sender: TObject);
begin
  LoadMembersFromCombo(cmbFirstClub.Text, '1')
end;

procedure TfrmPreferences.btnLoadFourthClick(Sender: TObject);
begin
  LoadMembersFromCombo(cmbFourthClub.Text, '4')
end;

procedure TfrmPreferences.btnLoadSecondClick(Sender: TObject);
begin
  LoadMembersFromCombo(cmbSecondClub.Text, '2')
end;

procedure TfrmPreferences.btnLoadThirdClick(Sender: TObject);
begin
  LoadMembersFromCombo(cmbThirdClub.Text, '3')
end;

procedure TfrmPreferences.btnSelbFontClick(Sender: TObject);
begin
  if dlgFont.Execute then
  begin
    fbSize := dlgFont.Font.Size;
    //dmUtils.ExtractFontSize(dlgFont.Font.Name);
    lblbFont.Caption := dlgFont.Font.Name + ' ' + IntToStr(fbSize);
    lblbFont.Font.Name := dlgFont.Font.Name;
    lblbFont.Font.Size := fbSize;
    lblButtons.Font.Name := dlgFont.Font.Name;
    lblButtons.Font.Size := fbSize;
  end;
end;

procedure TfrmPreferences.btnSeleFontClick(Sender: TObject);
begin
  if dlgFont.Execute then
  begin
    feSize := dlgFont.Font.Size;
    lbleFont.Caption := dlgFont.Font.Name + ' ' + IntToStr(feSize);
    lbleFont.Font.Name := dlgFont.Font.Name;
    lbleFont.Font.Size := feSize;
    lblEdits.Font.Name := dlgFont.Font.Name;
    lblEdits.Font.Size := feSize;
  end;
end;

procedure TfrmPreferences.btnSelectBandFontClick(Sender: TObject);
begin
  if dlgFont.Execute then
  begin
    fbandSize := dlgFont.Font.Size;
    lblBandMapFont.Font.Name := dlgFont.Font.Name;
    lblBandMapFont.Font.Size := dlgFont.Font.Size;
    lblBandMapFont.Caption   := dlgFont.Font.Name + ' ' + IntToStr(fbandSize)
  end
end;

procedure TfrmPreferences.btnSelqFontClick(Sender: TObject);
begin
  if dlgFont.Execute then
  begin
    fqSize := dlgFont.Font.Size;
    lblqFont.Caption := dlgFont.Font.Name + ' ' + IntToStr(fqSize);
    lblqFont.Font.Name := dlgFont.Font.Name;
    lblqFont.Font.Size := fqSize;
    lblQSOList.Font.Name := dlgFont.Font.Name;
    lblQSOList.Font.Size := fqSize;
  end;
end;

procedure TfrmPreferences.btnSelsFontClick(Sender: TObject);
begin
  if dlgFont.Execute then
  begin
    fgSize := dlgFont.Font.Size;
    lblgFont.Caption := dlgFont.Font.Name + ' ' + IntToStr(fgSize);
    lblgFont.Font.Name := dlgFont.Font.Name;
    lblgFont.Font.Size := fgSize;
    lblStatistics.Font.Name := dlgFont.Font.Name;
    lblStatistics.Font.Size := fgSize;
  end;
end;

procedure TfrmPreferences.btnSetFifthClick(Sender: TObject);
begin
  with TfrmClubSettings.Create(self) do
    try
      Caption := 'Club settings - ' + cmbFifthClub.Text;
      ClubStr := 'Fifth';
      ShowModal;
    finally
      Free
    end;
end;

procedure TfrmPreferences.btnSetFirstClick(Sender: TObject);
begin
  with TfrmClubSettings.Create(self) do
    try
      Caption := 'Club settings - ' + cmbFirstClub.Text;
      ClubStr := 'First';
      ShowModal;
    finally
      Free
    end;
end;

procedure TfrmPreferences.btnSetFourthClick(Sender: TObject);
begin
  with TfrmClubSettings.Create(self) do
    try
      Caption := 'Club settings - ' + cmbFourthClub.Text;
      ClubStr := 'Fourth';
      ShowModal;
    finally
      Free
    end;
end;

procedure TfrmPreferences.btnSetSecondClick(Sender: TObject);
begin
  with TfrmClubSettings.Create(self) do
    try
      Caption := 'Club settings - ' + cmbSecondClub.Text;
      ClubStr := 'Second';
      ShowModal;
    finally
      Free
    end;
end;

procedure TfrmPreferences.btnSetThirdClick(Sender: TObject);
begin
  with TfrmClubSettings.Create(self) do
    try
      Caption := 'Club settings - ' + cmbThirdClub.Text;
      ClubStr := 'Third';
      ShowModal;
    finally
      Free
    end;
end;

procedure TfrmPreferences.btnTestXplanetClick(Sender: TObject);
var
  geom: string = '';
  myloc: string = '';
  wait: string = '';
  cmd: string = '';
  lat, long: currency;
  AProcess: TProcess;
  proj: string = '';
  index: integer;
  paramList : TStringList;
begin
  if not FileExists(edtXplanetPath.Text) then
  begin
    Application.MessageBox('xplanet not found!', 'Error ...', mb_OK + mb_IconError);
    exit;
  end;


  geom := ' -geometry ' + edtXWidth.Text + 'x' + edtXHeight.Text +
    '+' + edtXLeft.Text + '+' + edtXTop.Text;
  if dmUtils.IsLocOK(edtXplanetLoc.Text) then
  begin
    dmUtils.CoordinateFromLocator(dmUtils.CompleteLoc(edtXplanetLoc.Text), lat, long);
    myloc := ' -longitude ' + CurrToStr(long) + ' -latitude ' + CurrToStr(lat);
  end
  else if dmUtils.IsLocOK(edtLoc.Text) then
  begin
    dmUtils.CoordinateFromLocator(dmUtils.CompleteLoc(edtLoc.Text), lat, long);
    myloc := ' -longitude ' + CurrToStr(long) + ' -latitude ' + CurrToStr(lat);
  end;
  wait := '-wait ' + edtXRefresh.Text;

  case rgProjection.ItemIndex of
    0: proj := '';
    1: proj := ' -projection azimuthal -background ' + dmData.HomeDir +
        'xplanet' + PathDelim + 'bck.png';
    2: proj := ' -projection azimuthal';
    3: proj := ' -projection rectangular';
  end; //case

  cmd :=' -config ' + dmData.HomeDir +
    'xplanet' + PathDelim + 'geoconfig -window ' + myloc +
    ' -glare 28 -light_time -range 2.5 ' + wait + ' ' + geom +
    ' -window_title "CQRLOG - xplanet" ' + proj;
  AProcess := TProcess.Create(nil);
  try
    AProcess.Executable := edtXplanetPath.Text;
    index:=0;
    paramList := TStringList.Create;
    paramList.Delimiter := ' ';
    paramList.DelimitedText := cmd;
    AProcess.Parameters.Clear;
    while index < paramList.Count do
    begin
      AProcess.Parameters.Add(paramList[index]);
      inc(index);
    end;
    paramList.Free;
    if dmData.DebugLevel>=1 then Writeln('AProcess.Executable: ',AProcess.Executable,' Parameters: ',AProcess.Parameters.Text);
    AProcess.Execute;
  finally
    AProcess.Free;
  end;
end;

procedure TfrmPreferences.Button1Click(Sender: TObject);
begin
  with TfrmBandMapWatch.Create(self) do
    try
      Caption := Caption + ' - watch';
      edtDXCC.Text := cqrini.ReadString('BandMap', 'wDXCC', '*');
      edtWAZ.Text := cqrini.ReadString('BandMap', 'wWAZ', '*');
      edtITU.Text := cqrini.ReadString('BandMap', 'wITU', '*');
      chkEU.Checked := cqrini.ReadBool('BandMap', 'wEU', True);
      chkAS.Checked := cqrini.ReadBool('BandMap', 'wAS', True);
      chkNA.Checked := cqrini.ReadBool('BandMap', 'wNA', True);
      chkSA.Checked := cqrini.ReadBool('BandMap', 'wSA', True);
      chkAF.Checked := cqrini.ReadBool('BandMap', 'wAF', True);
      chkOC.Checked := cqrini.ReadBool('BandMap', 'wOC', True);
      chkAN.Checked := cqrini.ReadBool('BandMap', 'wAN', True);
      chkIOTA.Checked := cqrini.ReadBool('BandMap', 'wIOTA', True);

      ShowModal;
      if ModalResult = mrOk then
      begin
        cqrini.WriteString('BandMap', 'wDXCC', edtDXCC.Text);
        cqrini.WriteString('BandMap', 'wWAZ', edtWAZ.Text);
        cqrini.WriteString('BandMap', 'wITU', edtITU.Text);
        cqrini.WriteBool('BandMap', 'wEU', chkEU.Checked);
        cqrini.WriteBool('BandMap', 'wAS', chkAS.Checked);
        cqrini.WriteBool('BandMap', 'wNA', chkNA.Checked);
        cqrini.WriteBool('BandMap', 'wSA', chkSA.Checked);
        cqrini.WriteBool('BandMap', 'wAF', chkAF.Checked);
        cqrini.WriteBool('BandMap', 'wOC', chkOC.Checked);
        cqrini.WriteBool('BandMap', 'wAN', chkAN.Checked);
        cqrini.WriteBool('BandMap', 'wIOTA', chkIOTA.Checked);
      end;
    finally
      Free
    end;
end;

procedure TfrmPreferences.btnFldigiPathClick(Sender: TObject);
begin
  dlgOpen.Title := 'Locate fldigi binary ...';
  if dlgOpen.Execute then
      if FileExists(dlgOpen.FileName) then  //with QT5 opendialog user can enter filename that may not exist
         edtFldigiPath.Text := dlgOpen.FileName
      else
       ShowMessage('File not found!');
end;

procedure TfrmPreferences.btnChangeDefFreqClick(Sender: TObject);
begin
  frmNewQSODefValues := TfrmNewQSODefValues.Create(frmPreferences);
  try
    frmNewQSODefValues.WhatChangeDesc := 'Frequency';
    frmNewQSODefValues.WhatChange :=
      cqrini.ReadString('NewQSO', 'FreqList', cDefaultFreq);
    if frmNewQSODefValues.ShowModal = mrOk then
    begin
      cqrini.WriteString('NewQSO', 'FreqList', frmNewQSODefValues.GetValues);
      dmUtils.InsertFreq(cmbFreq);
      ReloadFreq := True
    end
  finally
    FreeAndNil(frmNewQSODefValues)
  end
end;

procedure TfrmPreferences.btnChangeDefModeClick(Sender: TObject);
var
  cDefaultModes: String;
  i: Integer;
begin
  cDefaultModes := '';
  frmNewQSODefValues := TfrmNewQSODefValues.Create(frmPreferences);
  try
    frmNewQSODefValues.WhatChangeDesc := 'Mode';
    for i := 0 to cMaxModes do
    begin
      cDefaultModes := cDefaultModes + '|' + cModes[i];
    end;
    frmNewQSODefValues.WhatChange :=
      cqrini.ReadString('NewQSO', 'Modes', cDefaultModes);
    if frmNewQSODefValues.ShowModal = mrOK then
    begin
      cqrini.WriteString('NewQSO', 'Modes', frmNewQSODefValues.GetValues);
      dmUtils.InsertModes(cmbMode);
      ReloadModes := True
    end
  finally
    FreeAndNil(frmNewQSODefValues);
  end;
end;

procedure TfrmPreferences.btnHelp1Click(Sender: TObject);
begin
  dmUtils.OpenInApp('file://' + dmData.HelpDir + 'index.html' );
end;


procedure TfrmPreferences.btnWsjtPathClick(Sender: TObject);
begin
  dlgOpen.Title := 'Locate wsjtx binary ...';
  if dlgOpen.Execute then
    if FileExists(dlgOpen.FileName) then  //with QT5 opendialog user can enter filename that may not exist
      edtWsjtPath.Text := dlgOpen.FileName
    else
        ShowMessage('File not found!');
end;

procedure TfrmPreferences.btnAlertCallsignsClick(Sender: TObject);
var
  F : TfrmCallAlert;
begin
  F := TfrmCallAlert.Create(self);
  try
    F.ShowModal
  finally
    FreeAndNil(F)
  end
end;

procedure TfrmPreferences.btnAddTrxMemClick(Sender : TObject);
begin
  frmRadioMemories := TfrmRadioMemories.Create(frmTRXControl);
  try
    dmData.LoadFreqMemories(frmRadioMemories.sgrdMem);
    frmRadioMemories.ShowModal;
    if frmRadioMemories.ModalResult = mrOK then
    begin
      dmData.StoreFreqMemories(frmRadioMemories.sgrdMem)
    end
  finally
    FreeAndNil(frmRadioMemories)
  end
end;

procedure TfrmPreferences.btnBrowseBackup1Click(Sender: TObject);
var
  path : String;
begin
  if SelectDirectory('Select directory for backuping ...', dmData.DataDir, path) then
    edtBackupPath1.Text := path;
end;

procedure TfrmPreferences.btnCfgStorageClick(Sender: TObject);
var
  frmConfigStorage : TfrmConfigStorage;
begin
  frmConfigStorage := TfrmConfigStorage.Create(nil);
  try
    frmConfigStorage.ShowModal
  finally
    FreeAndNil(frmConfigStorage)
  end
end;

procedure TfrmPreferences.Button2Click(Sender: TObject);
begin
  with TfrmBandMapWatch.Create(self) do
    try
      Caption := Caption + ' - ignore';
      chkIOTA.Visible := False;
      edtDXCC.Text := cqrini.ReadString('BandMap', 'iDXCC', '');
      edtWAZ.Text := cqrini.ReadString('BandMap', 'iWAZ', '');
      edtITU.Text := cqrini.ReadString('BandMap', 'iITU', '');
      chkEU.Checked := cqrini.ReadBool('BandMap', 'iEU', False);
      chkAS.Checked := cqrini.ReadBool('BandMap', 'iAS', False);
      chkNA.Checked := cqrini.ReadBool('BandMap', 'iNA', False);
      chkSA.Checked := cqrini.ReadBool('BandMap', 'iSA', False);
      chkAF.Checked := cqrini.ReadBool('BandMap', 'iAF', False);
      chkOC.Checked := cqrini.ReadBool('BandMap', 'iOC', False);
      chkAN.Checked := cqrini.ReadBool('BandMap', 'iAN', False);
      ShowModal;
      if ModalResult = mrOk then
      begin
        cqrini.WriteString('BandMap', 'iDXCC', edtDXCC.Text);
        cqrini.WriteString('BandMap', 'iWAZ', edtWAZ.Text);
        cqrini.WriteString('BandMap', 'iITU', edtITU.Text);
        cqrini.WriteBool('BandMap', 'iEU', chkEU.Checked);
        cqrini.WriteBool('BandMap', 'iAS', chkAS.Checked);
        cqrini.WriteBool('BandMap', 'iNA', chkNA.Checked);
        cqrini.WriteBool('BandMap', 'iSA', chkSA.Checked);
        cqrini.WriteBool('BandMap', 'iAF', chkAF.Checked);
        cqrini.WriteBool('BandMap', 'iOC', chkOC.Checked);
        cqrini.WriteBool('BandMap', 'iAN', chkAN.Checked);
      end;
    finally
      Free
    end;
end;

procedure TfrmPreferences.btnBrowseBackupClick(Sender: TObject);
var
  path: string = '';
begin
  if SelectDirectory('Select directory for backuping ...', dmData.DataDir, path) then
    edtBackupPath.Text := path;
end;


procedure TfrmPreferences.btnChangeDefaultFreqClick(Sender: TObject);
begin
  with TfrmDefaultFreq.Create(self) do
    try
      ShowModal
    finally
      Free
    end;
end;

procedure TfrmPreferences.btnKeyMacrosClick(Sender: TObject);
begin
  frmKeyTexts := TfrmKeyTexts.Create(self);
  try
    frmKeyTexts.ShowModal
  finally
    frmKeyTexts.Free
  end;
end;

procedure TfrmPreferences.btnSplitClick(Sender: TObject);
begin
  with TfrmSplitSettings.Create(self) do
    try
      ShowModal
    finally
      Free
    end;
end;

procedure TfrmPreferences.btnForceMembershipUpdateClick(Sender : TObject);
begin
  SaveClubSection;
  dmMembership.CheckForMembershipUpdate
end;

procedure TfrmPreferences.chkClUpEnabledChange(Sender: TObject);
begin
  edtClUserName.Enabled := chkClUpEnabled.Checked;
  edtClPasswd.Enabled   := chkClUpEnabled.Checked;
  edtClEmail.Enabled    := chkClUpEnabled.Checked;
  chkClupOnline.Enabled := chkClUpEnabled.Checked;
  cmbClColor.Enabled    := chkClUpEnabled.Checked
end;

procedure TfrmPreferences.chkHaUpEnabledChange(Sender: TObject);
begin
  edtHaUserName.Enabled := chkHaUpEnabled.Checked;
  edtHaPasswd.Enabled   := chkHaUpEnabled.Checked;
  chkHaupOnline.Enabled := chkHaUpEnabled.Checked;
  cmbHaColor.Enabled    := chkHaUpEnabled.Checked
end;

procedure TfrmPreferences.chkHrUpEnabledChange(Sender: TObject);
begin
  edtHrUserName.Enabled := chkHrUpEnabled.Checked;
  edtHrCode.Enabled     := chkHrUpEnabled.Checked;
  chkHrUpOnline.Enabled := chkHrUpEnabled.Checked;
  cmbHrColor.Enabled    := chkHrUpEnabled.Checked
end;

procedure TfrmPreferences.chkIgnoreEditChange(Sender: TObject);
begin
  //Warn:
   if not chkIgnoreEdit.Focused then exit; //otherwise triggers on settings load
   chkIgnoreEdit.Checked:=WarnCheck(chkIgnoreEdit.Checked)
end;

procedure TfrmPreferences.chkIgnoreLoTWChange(Sender: TObject);

begin
   //Warn:
   if not chkIgnoreLoTW.Focused then exit; //otherwise triggers on settings load
   chkIgnoreLoTW.Checked:=WarnCheck(chkIgnoreLoTW.Checked)
end;

procedure TfrmPreferences.chkIgnoreQSLChange(Sender: TObject);
begin
  //Warn:
   if not chkIgnoreQSL.Focused then exit;//otherwise triggers on settings load
   chkIgnoreQSL.Checked:=WarnCheck(chkIgnoreQSL.Checked)
end;

procedure TfrmPreferences.chkUdUpEnabledChange(Sender: TObject);
begin
  edtUdAddress.Enabled  := chkUdUpEnabled.Checked;
  chkUdIncExch.Enabled  := chkUdUpEnabled.Checked;
  chkUdUpOnline.Enabled := chkUdUpEnabled.Checked;
  cmbUdColor.Enabled    := chkUdUpEnabled.Checked
end;

procedure TfrmPreferences.chkPotSpeedChange(Sender: TObject);
begin
  if chkPotSpeed.Checked then
    edtWinSpeed.Enabled := False
  else
    edtWinSpeed.Enabled := True;
   CWKeyerChanged := True
end;

procedure TfrmPreferences.chkProfileLocatorClick(Sender: TObject);
var
  i: integer;
begin
  i := cmbProfiles.ItemIndex;
  dmData.InsertProfiles(cmbProfiles, False, chkProfileLocator.Checked,
    chkProfileQTH.Checked, chkProfileRig.Checked);
  cmbProfiles.ItemIndex := i;
end;

procedure TfrmPreferences.chkProfileQTHClick(Sender: TObject);
var
  i: integer;
begin
  i := cmbProfiles.ItemIndex;
  dmData.InsertProfiles(cmbProfiles, False, chkProfileLocator.Checked,
    chkProfileQTH.Checked, chkProfileRig.Checked);
  cmbProfiles.ItemIndex := i;
end;

procedure TfrmPreferences.chkProfileRigClick(Sender: TObject);
var
  i: integer;
begin
  i := cmbProfiles.ItemIndex;
  dmData.InsertProfiles(cmbProfiles, False, chkProfileLocator.Checked,
    chkProfileQTH.Checked, chkProfileRig.Checked);
  cmbProfiles.ItemIndex := i;
end;

procedure TfrmPreferences.chkRBNLinkChange(Sender: TObject);
begin
  if chkRBNLink.Checked then
   Begin
     chkRBNAutoConn.Checked:=false;
     chkRBNAutoConn.Enabled:=false;
   end
  else chkRBNAutoConn.Enabled:=true;
end;

procedure TfrmPreferences.chkSysUTCClick(Sender: TObject);
begin
  edtOffset.Enabled    := not chkSysUTC.Checked;
  edtSunOffset.Enabled := not chkSysUTC.Checked
end;

procedure TfrmPreferences.chkUseDXCColorsChange(Sender: TObject);
begin
  if chkUseDXCColors.Checked then
    cmbFrmDXCColor.Enabled := False
  else
    cmbFrmDXCColor.Enabled := True;
end;

procedure TfrmPreferences.btnFirstLoadClick(Sender: TObject);
begin
  if cmbFirstZip.Text = '' then
    exit;
  with TfrmLoadClub.Create(self) do
    try
      Caption := 'Loading ZIP codes';
      TypOfLoad := 1;
      ZipNr := 1;
      SourceFile := dmData.ZipCodeDir + LowerCase(
        copy(cmbFirstZip.Text, 1, Pos(';', cmbFirstZip.Text) - 1)) + '.txt';
      ShowModal
    finally
      Free
    end;
end;

procedure TfrmPreferences.btnSecondLoadClick(Sender: TObject);
begin
  if cmbSecondZip.Text = '' then
    exit;
  with TfrmLoadClub.Create(self) do
    try
      Caption := 'Loading ZIP codes';
      TypOfLoad := 1;
      ZipNr := 2;
      SourceFile := dmData.ZipCodeDir + LowerCase(
        copy(cmbSecondZip.Text, 1, Pos(';', cmbSecondZip.Text) - 1)) + '.txt';
      ShowModal
    finally
      Free
    end;
end;

procedure TfrmPreferences.btnThirdLoadClick(Sender: TObject);
begin
  if cmbThirdZip.Text = '' then
    exit;
  with TfrmLoadClub.Create(self) do
    try
      Caption := 'Loading ZIP codes';
      TypOfLoad := 1;
      ZipNr := 3;
      SourceFile := dmData.ZipCodeDir + LowerCase(
        copy(cmbThirdZip.Text, 1, Pos(';', cmbThirdZip.Text) - 1)) + '.txt';
      ShowModal
    finally
      Free
    end;
end;

procedure TfrmPreferences.cmbCWRadioChange(Sender: TObject);
begin
  if cmbCWRadio.ItemIndex<1 then cmbCWRadio.ItemIndex:=1;
end;

procedure TfrmPreferences.cmbCWRadioCloseUp(Sender: TObject);
begin
  if cmbCWRadio.ItemIndex<1 then cmbCWRadio.ItemIndex:=1;
  SaveCWif(CWifLoaded);
  LoadCWif(cmbCWRadio.ItemIndex);
end;

procedure TfrmPreferences.cmbIfaceTypeChange(Sender: TObject);
begin
  CWKeyerChanged:=true;
end;

procedure TfrmPreferences.cbNoKeyerResetChange(Sender: TObject);
begin
  if  cbNoKeyerReset.Checked
    and (cmbIfaceType.ItemIndex = 4) //type is HamLib
     then cbNoKeyerReset.Checked := false; //restart is always needed  when radio changes
  CWKeyerChanged := True
end;

procedure TfrmPreferences.cmbIfaceTypeCloseUp(Sender: TObject);
begin
  CWKeyerChanged := True;
   if  cbNoKeyerReset.Checked
    and  (cmbIfaceType.ItemIndex = 4) //type is HamLib
     then cbNoKeyerReset.Checked := false; //restart is always needed  when radio changes
end;

procedure TfrmPreferences.cmbModelRigChange(Sender: TObject);
begin
   chkRunRigCtld.Enabled:=True;

  if cmbModelRig.ItemIndex=1 then  //With Hamlib Net rigctld do not start rigctld (no sense)
    Begin
     chkRunRigCtld.Checked:=False;
     chkRunRigCtld.Enabled:=False;
    end;
   TRXParamsChange(nil);
end;

procedure TfrmPreferences.cmbModelRot1Change(Sender: TObject);
begin
    if cmbModelRot1.ItemIndex=1 then
    Begin
     chkRot1RunRotCtld.Checked:=False;
     chkRot1RunRotCtld.Enabled:=False;
    end
   else
      chkRot1RunRotCtld.Enabled:=True;
   RotorParamsChange(nil);
end;

procedure TfrmPreferences.cmbModelRot2Change(Sender: TObject);
begin
    if cmbModelRot2.ItemIndex=1 then
    Begin
     chkRot2RunRotCtld.Checked:=False;
     chkRot2RunRotCtld.Enabled:=False;
    end
   else
      chkRot2RunRotCtld.Enabled:=True;
   RotorParamsChange(nil);
end;

procedure TfrmPreferences.cmbRadioModesChange(Sender: TObject);
begin
    if  cmbRadioModes.ItemIndex<1 then  cmbRadioModes.ItemIndex:=1;
end;

procedure TfrmPreferences.cmbRadioModesCloseUp(Sender: TObject);

begin
  if  cmbRadioModes.ItemIndex<1 then  cmbRadioModes.ItemIndex:=1;
  SaveBandW(BandWNrLoaded);
  LoadBandW(cmbRadioModes.ItemIndex);
end;

procedure TfrmPreferences.cmbRadioNrChange(Sender: TObject);
begin
   if cmbRadioNr.ItemIndex<1 then  cmbRadioNr.ItemIndex:=1;
end;

procedure TfrmPreferences.cmbRadioNrCloseUp(Sender: TObject);
begin
  if cmbRadioNr.ItemIndex<1 then  cmbRadioNr.ItemIndex:=1;
  SaveTRX(RadioNrLoaded);                                 //save edited rig
  LoadTRX(cmbRadioNr.ItemIndex);                          //load selected rig
  InitRigCmb;                                             //load names and set currently edited rig

  cmbRadioModes.ItemIndex:= cmbRadioNr.ItemIndex;          //select rig in use
  cmbCWRadio.ItemIndex:=cmbRadioNr.ItemIndex;
end;

procedure TfrmPreferences.edtAlertCmdExit(Sender: TObject);
begin
   edtAlertCmd.Text:=StringReplace(edtAlertCmd.Text,'~/',dmData.UsrHomeDir,[rfReplaceAll]);
   // ~ in command causes DXCluster spot flow stop (!?)
end;

procedure TfrmPreferences.edtDataCmdChange(Sender: TObject);
begin
  edtDataCmd.Text:=DataModeInput(edtDataCmd.Text);
  edtDataCmd.SelStart:=length(edtDataCmd.Text);
  edtDataCmd.SelLength:=0;
end;

procedure TfrmPreferences.edtDigiModesExit(Sender: TObject);
var i :integer;
begin
  cqrini.WriteString('Modes', 'Digi', edtDigiModes.Text);
  i:=cmbDataMode.ItemIndex;
  dmUtils.InsertModes(cmbDataMode);
  cmbDataMode.ItemIndex:=i;
end;

procedure TfrmPreferences.edtGCBeamWidthChange(Sender: TObject);
begin

end;

function TfrmPreferences.DataModeInput(s:string):string;
begin
  s:=Upcase(s);
  if (length(s)>0)
    and
       not ( (s[length(s)] in ['A'..'Z'])
             or (s[length(s)] in ['0'..'9']) ) then
                                       s:=copy(s,1,length(s)-1);
  Result:=s;
end;

procedure TfrmPreferences.edtGCLineWidthExit(Sender: TObject);
var v:integer;
begin
   if TryStrToInt(edtGCLineWidth.Caption,v) then
    begin
      if ((v<=0) or (v>5)) then
             edtGCLineWidth.Caption:='2' //replace with default
    end
    else
       edtGCLineWidth.Caption:='2' //replace with default
end;

procedure TfrmPreferences.edtGCPolarDivisorExit(Sender: TObject);
var v:integer;
begin
   if TryStrToInt(edtGCPolarDivisor.Caption,v) then
    begin
      if ((v<=0) or (v>40)) then
             edtGCPolarDivisor.Caption:='10' //replace with default
    end
    else
       edtGCPolarDivisor.Caption:='10' //replace with default
end;

procedure TfrmPreferences.edtGCStepExit(Sender: TObject);
var v:extended;
begin
  if TryStrToFloat(edtGCStep.Caption,v) then
    Begin
      if ((v<=0) or (v>40)) then
        edtGCStep.Caption:='0.1'; //error use default value;
    end
   else
    edtGCStep.Caption:='0.1'; //on convert error use default value;
end;

procedure TfrmPreferences.edtHtmlFilesClick(Sender: TObject);
begin
  if odFindBrowser.Execute then
        edtHtmlFiles.Text := odFindBrowser.Filename;
end;

procedure TfrmPreferences.edtHtmlFilesExit(Sender: TObject);
begin
   if ExtractFilePath(edtHtmlFiles.Text)='' then
   Begin
     edtHtmlFiles.Text:='';
     Label17.Caption:='NOTE: You have to give full path for program file names!'
   end else
     Label17.Caption:='';
end;

procedure TfrmPreferences.edtImgFilesExit(Sender: TObject);
begin
   if ExtractFilePath(edtImgFiles.Text)='' then
        edtImgFiles.Text:=SeekExecFile(edtImgFiles.Text,'Find image viewer');
end;

procedure TfrmPreferences.edtK3NGSerSpeedChange(Sender: TObject);
begin

end;

procedure TfrmPreferences.edtPdfFilesExit(Sender: TObject);
begin
   if ExtractFilePath(edtPdfFiles.Text)='' then
        edtPdfFiles.Text:=SeekExecFile(edtPdfFiles.Text,'Find PDF viewer');
end;

procedure TfrmPreferences.edtTxtFilesExit(Sender: TObject);
begin
  if ExtractFilePath(edtTxtFiles.Text)='' then
        edtTxtFiles.Text:=SeekExecFile(edtTxtFiles.Text,'Find text editor');
end;
function TfrmPreferences.SeekExecFile(MyFile,MyExeFor:string): String;
Begin
     Result :='';
     Label17.Caption:='NOTE: You have to give full path for program file names!';
     odFindBrowser.InitialDir:='/usr/bin';
     odFindBrowser.FileName:=MyFile;
     odFindBrowser.Title:=MyExeFor;
     if odFindBrowser.Execute then
        Result := odFindBrowser.Filename;
end;

procedure TfrmPreferences.edtLocChange(Sender: TObject);
begin
  edtLoc.Text := dmUtils.StdFormatLocator(edtLoc.Text);
  edtLoc.SelStart := Length(edtLoc.Text);
end;

procedure TfrmPreferences.edtLocExit(Sender: TObject);
begin
  edtLoc.Text:=trim(edtLoc.Text);
  if dmUtils.IsLocOK(edtLoc.Text) then   //update
   begin
    frmNewQSO.CurrentMyLoc :=edtLoc.Text;//current my_loc
    frmNewQSO.sbNewQSO.Panels[0].Text := fNewQSO.cMyLoc + frmNewQSO.CurrentMyLoc; //and  NewQSO panel
    frmNewQSO.ClearGrayLineMapLine; //my_loc on map
   end
  else
   begin
    edtLoc.Text:='';
    edtLoc.SetFocus;
   end;
end;

procedure TfrmPreferences.edtOperatorExit(Sender: TObject);
begin
  edtOperator.text:=Trim(Uppercase(edtOperator.text));
end;

procedure TfrmPreferences.edtRecetQSOsKeyPress(Sender: TObject; var Key: char);
begin
  if not (key in ['0'..'9']) then
    key := #0;
end;

procedure TfrmPreferences.edtRigCountChange(Sender: TObject);
begin
  cqrini.WriteInteger('TRX', 'RigCount', edtRigCount.Value);
  InitRigCmb;                                             //load names and set currently edited rig
end;

procedure TfrmPreferences.TRXParamsChange(Sender: TObject);
begin
  TRXChanged := True
end;
procedure TfrmPreferences.RotorParamsChange(Sender: TObject);
begin
  RotChanged := True;
end;

procedure TfrmPreferences.tabCWInterfaceContextPopup(Sender: TObject;
  MousePos: TPoint; var Handled: Boolean);
begin

end;

procedure TfrmPreferences.tabCWInterfaceExit(Sender: TObject);
begin
     SaveCWif(CWifLoaded);  //save currently open CW settings
     cmbRadioNr.ItemIndex:=cmbCWRadio.ItemIndex;
     cmbRadioModes.ItemIndex:= cmbRadioNr.ItemIndex;          //select rig in use
end;

procedure TfrmPreferences.tabModesExit(Sender: TObject);
begin
  SaveBandW(BandWNrLoaded); //save currently loaded modes
  cmbRadioNr.ItemIndex:=cmbRadioModes.ItemIndex;          //select rig in use
  cmbCWRadio.ItemIndex:=cmbRadioNr.ItemIndex;
end;

procedure TfrmPreferences.tabTRXcontrolEnter(Sender: TObject);
begin
  LoadTRX(cmbRadioNr.ItemIndex);
end;

procedure TfrmPreferences.edtWebBrowserClick(Sender: TObject);
Begin
  odFindBrowser.InitialDir:='/usr/bin';
  if odFindBrowser.Execute then
        edtWebBrowser.Text := odFindBrowser.Filename;
end;

procedure TfrmPreferences.edtWebBrowserExit(Sender: TObject);
var
   f,p :string;
begin
  f:= edtWebBrowser.Text;
  if (f = '') or (f[length(f)] = '/') then
      Begin
       edtWebBrowser.Text :='';
       ShowMessage('File:'+f+' is not found!'+LineEnding+'Check file name,'+LineEnding+'or give full path.')
      end
    else
     begin
       p:= GetEnv('PATH');
       edtWebBrowser.Text:=FileSearch (f,p);
       if (edtWebBrowser.Text ='') then
         ShowMessage('File:'+f+' is not found!'+LineEnding+'Check file name,'+LineEnding+'or give full path.');
     end;
end;

procedure TfrmPreferences.edtWinSpeedChange(Sender: TObject);
begin
  CWKeyerChanged := True
end;

procedure TfrmPreferences.edtXplanetLocChange(Sender: TObject);
begin
  edtXplanetLoc.Text := dmUtils.StdFormatLocator(edtXplanetLoc.Text);
  edtXplanetLoc.SelStart := Length(edtXplanetLoc.Text);
end;

procedure TfrmPreferences.lbPreferencesClick(Sender: TObject);
begin
  pgPreferences.ActivePageIndex := lbPreferences.ItemIndex;
end;

procedure TfrmPreferences.FormShow(Sender: TObject);
var
  i: integer;
begin
  dmUtils.LoadFontSettings(self);
  dmUtils.LoadWindowPos(self);

  dmUtils.InsertModes(cmbDefaultMode);
  dmUtils.InsertModes(cmbMode);
  dmUtils.InsertModes(cmbWsjtDefaultMode);
  dmUtils.InsertModes(cmbDataMode);
  cmbDefaultMode.Style := csDropDownList;
  cmbWsjtDefaultMode.Style := csDropDownList;
  cmbDataMode.Style:=csDropDownList;
  LoadMebershipCombo;

  dmUtils.ReadZipList(cmbFirstZip);
  for i := 0 to cmbFirstZip.Items.Count - 1 do
  begin
    cmbSecondZip.Items.Add(cmbFirstZip.Items[i]);
    cmbThirdZip.Items.Add(cmbFirstZip.Items[i]);
  end;
  dmData.InsertProfiles(cmbProfiles, False);
  Top := cqrini.ReadInteger('Pref', 'Top', 20);
  Left := cqrini.ReadInteger('Pref', 'Left', 20);
  ActPageIdx := cqrini.ReadInteger('Pref', 'ActPageIdx', 0);

  edtCall.Text := cqrini.ReadString('Station', 'Call', '');
  edtName.Text := cqrini.ReadString('Station', 'Name', '');
  edtQTH.Text := cqrini.ReadString('Station', 'QTH', '');
  edtLoc.Text := cqrini.ReadString('Station', 'LOC', '');
  edtMailingAddress.Text := cqrini.ReadString('Station', 'MailingAddress', '');
  edtZipCity.Text := cqrini.ReadString('Station', 'ZipCity', '');
  edtEmail.Text := cqrini.ReadString('Station', 'Email', '');
  edtClub.Text := cqrini.ReadString('Station', 'Club', '');

  edtRST_S.Text := cqrini.ReadString('NewQSO', 'RST_S', '599');
  edtRST_R.Text := cqrini.ReadString('NewQSO', 'RST_R', '599');
  edtPWR.Text := cqrini.ReadString('NewQSO', 'PWR', '100');
  cmbFreq.Text := cqrini.ReadString('NewQSO', 'FREQ', '7.025');
  cmbMode.Text := cqrini.ReadString('NewQSO', 'Mode', 'CW');
  cmbQSL_S.Text := cqrini.ReadString('NewQSO', 'QSL_S', '');
  edtComments.Text := cqrini.ReadString('NewQSO', 'RemQSO', '');
  edtOperator.Text := cqrini.ReadString('NewQSO', 'Op', '');
  edtUsrBtn.Text := cqrini.ReadString('NewQSO', 'UsrBtn', 'https://www.qrzcq.com/call/$CALL');
  chkUseSpaceBar.Checked := cqrini.ReadBool('NewQSO', 'UseSpaceBar', False);
  chkRefreshAfterSave.Checked := cqrini.ReadBool('NewQSO', 'RefreshAfterSave', True);
  chkSkipModeFreq.Checked := cqrini.ReadBool('NewQSO', 'SkipModeFreq', True);
  chkAutoSearch.Checked := cqrini.ReadBool('NewQSO', 'AutoSearch', False);
  chkShowRecentQSOs.Checked := cqrini.ReadBool('NewQSO', 'ShowRecentQSOs', False);
  chkShowB4call.Checked := cqrini.ReadBool('NewQSO', 'ShowB4call', False);
  edtRecetQSOs.Text := cqrini.ReadString('NewQSO', 'RecQSOsNum', '5');
  chkIgnoreQRZQSL.Checked := cqrini.ReadBool('NewQSO', 'IgnoreQRZ', False);
  chkMvToRem.Checked := cqrini.ReadBool('NewQSO', 'MvToRem', True);
  chkAutoQSLS.Checked := cqrini.ReadBool('NewQSO', 'AutoQSLS', True);
  chkAutoDQSLS.Checked := cqrini.ReadBool('NewQSO', 'AutoDQSLS', False);
  chkAutoQQSLS.Checked := cqrini.ReadBool('NewQSO', 'AutoQQSLS', False);
  chkAllVariants.Checked := cqrini.ReadBool('NewQSO', 'AllVariants', False);
  chkClearRIT.Checked := cqrini.ReadBool('NewQSO','ClearRIT',False);
  chkUseCallBookData.Checked := cqrini.ReadBool('NewQSO','UseCallBookData',False);
  chkCapFirstQTHLetter.Checked := cqrini.ReadBool('NewQSO','CapFirstQTHLetter',True);
  chkUseCallbookZonesEtc.Checked := cqrini.ReadBool('NewQSO','UseCallbookZonesEtc',True);
  chkFillAwardField.Checked := cqrini.ReadBool('NewQSO','FillAwardField',True);
  chkSatelliteMode.Checked := cqrini.ReadBool('NewQSO','SatelliteMode', False);
  chkUpdateAMSATstatus.Checked := cqrini.ReadBool('NewQSO','UpdateAMSATstatus', False);

  edtProxy.Text := cqrini.ReadString('Program', 'Proxy', '');
  edtPort.Text := cqrini.ReadString('Program', 'Port', '');
  edtUser.Text := cqrini.ReadString('Program', 'User', '');
  edtPasswd.Text := cqrini.ReadString('Program', 'Passwd', '');
  edtOffset.Text := CurrToStr(cqrini.ReadFloat('Program', 'offset', 0));
  pgPreferences.ActivePageIndex := cqrini.ReadInteger('Program', 'Options', 0);
  edtGrayLineOffset.Text := CurrToStr(cqrini.ReadFloat('Program', 'GraylineOffset', 0));
  edtGCStep.Caption :=  CurrToStr(cqrini.ReadFloat('Program', 'GraylineGCstep',0.1));
  edtGCPolarDivisor.Caption := IntToStr(cqrini.ReadInteger('Program', 'GraylineGCPolarDivisor',10));
  edtGCLineWidth.Caption :=  IntToStr(cqrini.ReadInteger('Program', 'GraylineGCLineWidth',2));
  btnSPColor.ButtonColor := StringToColor(cqrini.ReadString('Program', 'GraylineGCLineSPColor','clYellow' ));
  btnLPColor.ButtonColor := StringToColor(cqrini.ReadString('Program', 'GraylineGCLineLPColor','clFuchsia' ));
  btnBPColor.ButtonColor:= StringToColor(cqrini.ReadString('Program', 'GraylineGCLineBEColor','clRed'));
  edtGCBeamWidth.Caption:= IntToStr(cqrini.ReadInteger('Program', 'GraylineGBeamLineWidth',2));
  edtGCBeamLength.Caption:= IntToStr(cqrini.ReadInteger('Program', 'GraylineGBeamLineLength',1500));


  edtWebBrowser.Text := cqrini.ReadString('Program', 'WebBrowser', dmUtils.MyDefaultBrowser);
  chkNewDXCCTables.Checked := cqrini.ReadBool('Program', 'CheckDXCCTabs', True);
  chkShowDeleted.Checked := cqrini.ReadBool('Program', 'ShowDeleted', False);
  chkSunUTC.Checked := cqrini.ReadBool('Program', 'SunUTC', False);
  chkNewQSLTables.Checked := cqrini.ReadBool('Program', 'CheckQSLTabs', True);
  chkNewDOKTables.Checked := cqrini.ReadBool('Program', 'CheckDOKTabs', False);
  edtSunOffset.Text := CurrToStr(cqrini.ReadFloat('Program', 'SunOffset', 0));
  chkSysUTC.Checked := cqrini.ReadBool('Program', 'SysUTC', True);
  chkShowMiles.Checked := cqrini.ReadBool('Program','ShowMiles',False);
  chkQSOColor.Checked := cqrini.ReadBool('Program', 'QSODiffColor', False);
  btnSelectQSOColor.ButtonColor := cqrini.ReadInteger('Program', 'QSOColor', clPurple);
  edtQSOColorDate.Text := cqrini.ReadString('Program', 'QSOColorDate', '');

  if cqrini.ReadBool('Program', 'BandStatMHz', True) then
    rgStatistics.ItemIndex := 0
  else
    rgStatistics.ItemIndex := 1;

  chkDate.Checked := cqrini.ReadBool('Columns', 'Date', True);
  chkTimeOn.Checked := cqrini.ReadBool('Columns', 'time_on', True);
  chkTimeOff.Checked := cqrini.ReadBool('Columns', 'time_off', False);
  chkCallSign.Checked := cqrini.ReadBool('Columns', 'CallSign', True);
  chkMode.Checked := cqrini.ReadBool('Columns', 'Mode', True);
  chkFreq.Checked := cqrini.ReadBool('Columns', 'Freq', True);
  chkRST_S.Checked := cqrini.ReadBool('Columns', 'RST_S', True);
  chkRST_R.Checked := cqrini.ReadBool('Columns', 'RST_R', True);
  chkName.Checked := cqrini.ReadBool('Columns', 'Name', True);
  chkQTH.Checked := cqrini.ReadBool('Columns', 'QTH', True);
  chkQSL_S.Checked := cqrini.ReadBool('Columns', 'QSL_S', True);
  chkQSL_R.Checked := cqrini.ReadBool('Columns', 'QSL_R', True);
  chkQSL_VIA.Checked := cqrini.ReadBool('Columns', 'QSL_VIA', False);
  chkLoc.Checked := cqrini.ReadBool('Columns', 'Locator', False);
  chkMyLoc.Checked := cqrini.ReadBool('Columns', 'MyLoc', False);
  chkOperator.Checked := cqrini.ReadBool('Columns', 'Operator', False);
  chkDistance.Checked := cqrini.ReadBool('Columns', 'Distance', False);
  chkIOTA.Checked := cqrini.ReadBool('Columns', 'IOTA', False);
  chkAward.Checked := cqrini.ReadBool('Columns', 'Award', False);
  chkCounty.Checked := cqrini.ReadBool('Columns', 'County', False);
  chkPower.Checked := cqrini.ReadBool('Columns', 'Power', False);
  chkDXCC.Checked := cqrini.ReadBool('Columns', 'DXCC', False);
  chkRemarks.Checked := cqrini.ReadBool('Columns', 'Remarks', False);
  chkWAZ.Checked := cqrini.ReadBool('Columns', 'WAZ', False);
  chkITU.Checked := cqrini.ReadBool('Columns', 'ITU', False);
  chkState.Checked := cqrini.ReadBool('Columns', 'State', False);
  chkLoTWQSLSDate.Checked := cqrini.ReadBool('Columns', 'LoTWQSLSDate', False);
  chkLoTWQSLRDate.Checked := cqrini.ReadBool('Columns', 'LoTWQSLRDate', False);
  chkLoTWQSLS.Checked := cqrini.ReadBool('Columns', 'LoTWQSLS', False);
  chkLoTWQSLR.Checked := cqrini.ReadBool('Columns', 'LOTWQSLR', False);
  chkCont.Checked := cqrini.ReadBool('Columns', 'Cont', False);
  chkQSLSentDate.Checked := cqrini.ReadBool('Columns', 'QSLSDate', False);
  chkQSLRcvdDate.Checked := cqrini.ReadBool('Columns', 'QSLRDate', False);
  chkeQSLSent.Checked := cqrini.ReadBool('Columns', 'eQSLQSLS', False);
  chkeQSLSentDate.Checked := cqrini.ReadBool('Columns', 'eQSLQSLSDate', False);
  chkeQSLRcvd.Checked := cqrini.ReadBool('Columns', 'eQSLQSLR', False);
  chkeQSLRcvdDate.Checked := cqrini.ReadBool('Columns', 'eQSLQSLRDate', False);
  chkQSLRAll.Checked := cqrini.ReadBool('Columns', 'QSLRAll', False);
  chkCountry.Checked := cqrini.ReadBool('Columns', 'Country', False);
  chkPropagation.Checked := cqrini.ReadBool('Columns', 'Propagation', False);
  chkSatellite.Checked := cqrini.ReadBool('Columns', 'SatelliteName', False);
  chkRXFreq.Checked := cqrini.ReadBool('Columns', 'RXFreq', False);
  chkContestName.Checked := cqrini.ReadBool('Columns', 'ContestName', False);
  chkSTX.Checked := cqrini.ReadBool('Columns', 'STX', False);
  chkSRX.Checked := cqrini.ReadBool('Columns', 'SRX', False);
  chkSTX_str.Checked := cqrini.ReadBool('Columns', 'ContMsgSent', False);
  chkSRX_str.Checked := cqrini.ReadBool('Columns', 'ContMsgRcvd', False);
  chkDarcDok.Checked := cqrini.ReadBool('Columns', 'DarcDok', False);

  cb136kHz.Checked := cqrini.ReadBool('Bands', '137kHz', False);
  cb472kHz.Checked := cqrini.ReadBool('Bands', '472kHz', False);
  cb160m.Checked := cqrini.ReadBool('Bands', '160m', True);
  cb80m.Checked := cqrini.ReadBool('Bands', '80m', True);
  cb60m.Checked := cqrini.ReadBool('Bands', '60m', False);
  cb40m.Checked := cqrini.ReadBool('Bands', '40m', True);
  cb30m.Checked := cqrini.ReadBool('Bands', '30m', True);
  cb20m.Checked := cqrini.ReadBool('Bands', '20m', True);
  cb17m.Checked := cqrini.ReadBool('Bands', '17m', True);
  cb15m.Checked := cqrini.ReadBool('Bands', '15m', True);
  cb12m.Checked := cqrini.ReadBool('Bands', '12m', True);
  cb10m.Checked := cqrini.ReadBool('Bands', '10m', True);
  cb8m.Checked := cqrini.ReadBool('Bands', '8m', True);
  cb6m.Checked := cqrini.ReadBool('Bands', '6m', True);
  cb5m.Checked := cqrini.ReadBool('Bands', '5m', True);
  cb4m.Checked := cqrini.ReadBool('Bands', '4m', False);
  cb2m.Checked := cqrini.ReadBool('Bands', '2m', True);
  cb125m.Checked := cqrini.ReadBool('Bands', '1.25m', False);
  cb70cm.Checked := cqrini.ReadBool('Bands', '70cm', True);
  cb30cm.Checked := cqrini.ReadBool('Bands', '33cm', False);
  cb23cm.Checked := cqrini.ReadBool('Bands', '23cm', False);
  cb13cm.Checked := cqrini.ReadBool('Bands', '13cm', False);
  cb8cm.Checked := cqrini.ReadBool('Bands', '8cm', False);
  cb5cm.Checked := cqrini.ReadBool('Bands', '5cm', False);
  cb3cm.Checked := cqrini.ReadBool('Bands', '3cm', False);
  cb1cm.Checked := cqrini.ReadBool('Bands', '1cm', False);
  cb47GHz.Checked := cqrini.ReadBool('Bands', '47GHz', False);
  cb76GHz.Checked := cqrini.ReadBool('Bands', '76GHz', False);
  cb122GHz.Checked := cqrini.ReadBool('Bands', '122GHz', False);
  cb134GHz.Checked := cqrini.ReadBool('Bands', '134GHz', False);
  cb241GHz.Checked := cqrini.ReadBool('Bands', '241GHz', False);

  edtRigCtldPath.Text := cqrini.ReadString('TRX', 'RigCtldPath', '/usr/bin/rigctld');
  chkTrxControlDebug.Checked := cqrini.ReadBool('TRX','Debug',False);
  chkModeRelatedOnly.Checked := cqrini.ReadBool('TRX','MemModeRelated',False);
  edtRigCount.Value:=cqrini.ReadInteger('TRX', 'RigCount', 2);
  InitRigCmb(true); //define used rig=true
  LoadTRX(cmbRadioNr.ItemIndex);
  LoadBandW(cmbRadioNr.ItemIndex);
  LoadCWif(cmbRadioNr.ItemIndex);

  edtRotCtldPath.Text := cqrini.ReadString('ROT', 'RotCtldPath', '/usr/bin/rotctld');
  if (FileExistsUTF8(edtRotCtldPath.Text)) then
  begin
    dmUtils.LoadRigsToComboBox(cqrini.ReadString('ROT1', 'model', ''),edtRotCtldPath.Text,cmbModelRot1);
    dmUtils.LoadRigsToComboBox(cqrini.ReadString('ROT2', 'model', ''),edtRotCtldPath.Text,cmbModelRot2)
  end
  else begin
    Application.MessageBox('rotctld binary not found, unable to load list of supported rotators!'+LineEnding+LineEnding+
                           'Fix path to rotctld in ROT control tab.', 'Error', mb_OK+ mb_IconError)
  end;


  edtRot1Device.Text := cqrini.ReadString('ROT1', 'device', '');
  edtRot1Poll.Text := cqrini.ReadString('ROT1', 'poll', '500');
  edtRotor1.Text := cqrini.ReadString('ROT1', 'Desc', 'Rotor 1');
  edtRot1RotCtldPort.Text := cqrini.ReadString('ROT1', 'RotCtldPort', '4533');
  edtRot1RotCtldArgs.Text := cqrini.ReadString('ROT1', 'ExtraRotCtldArgs', '');
  chkRot1RunRotCtld.Checked := cqrini.ReadBool('ROT1', 'RunRotCtld', False);
  chkRot1AzMinMax.Checked := cqrini.ReadBool('ROT1', 'RotAzMinMax', False);
  edtRot1Host.Text := cqrini.ReadString('ROT1', 'host', 'localhost');
  cmbSpeedRot1.ItemIndex := cqrini.ReadInteger('ROT1', 'SerialSpeed', 0);
  cmbDataBitsRot1.ItemIndex := cqrini.ReadInteger('ROT1', 'DataBits', 0);
  cmbStopBitsRot1.ItemIndex := cqrini.ReadInteger('ROT1', 'StopBits', 0);
  cmbParityRot1.ItemIndex := cqrini.ReadInteger('ROT1', 'Parity', 0);
  cmbHanshakeRot1.ItemIndex := cqrini.ReadInteger('ROT1', 'HandShake', 0);
  cmbDTRRot1.ItemIndex := cqrini.ReadInteger('ROT1', 'DTR', 0);
  cmbRTSRot1.ItemIndex := cqrini.ReadInteger('ROT1', 'RTS', 0);

  edtRot2Device.Text := cqrini.ReadString('ROT2', 'device', '');
  edtRot2Poll.Text := cqrini.ReadString('ROT2', 'poll', '500');
  edtRotor2.Text := cqrini.ReadString('ROT2', 'Desc', 'Rotor 2');
  edtRot2RotCtldPort.Text := cqrini.ReadString('ROT2', 'RotCtldPort', '4533');
  edtRot2RotCtldArgs.Text := cqrini.ReadString('ROT2', 'ExtraRotCtldArgs', '');
  chkRot2RunRotCtld.Checked := cqrini.ReadBool('ROT2', 'RunRotCtld', False);
  chkRot2AzMinMax.Checked := cqrini.ReadBool('ROT2', 'RotAzMinMax', False);
  edtRot2Host.Text := cqrini.ReadString('ROT2', 'host', 'localhost');
  cmbSpeedRot2.ItemIndex := cqrini.ReadInteger('ROT2', 'SerialSpeed', 0);
  cmbDataBitsRot2.ItemIndex := cqrini.ReadInteger('ROT2', 'DataBits', 0);
  cmbStopBitsRot2.ItemIndex := cqrini.ReadInteger('ROT2', 'StopBits', 0);
  cmbParityRot2.ItemIndex := cqrini.ReadInteger('ROT2', 'Parity', 0);
  cmbHanshakeRot2.ItemIndex := cqrini.ReadInteger('ROT2', 'HandShake', 0);
  cmbDTRRot2.ItemIndex := cqrini.ReadInteger('ROT2', 'DTR', 0);
  cmbRTSRot2.ItemIndex := cqrini.ReadInteger('ROT2', 'RTS', 0);

  cmbModelRigChange(nil);

  cmbModelRot1Change(nil);
  cmbModelRot2Change(nil);

  edtDigiModes.Text := cqrini.ReadString('Modes', 'Digi', '');



  chkUseProfiles.Checked := cqrini.ReadBool('Profiles', 'Use', False);
  cmbProfiles.Text :=
    dmData.GetProfileText(cqrini.ReadInteger('Profiles', 'Selected', 0));
  chkProfileLocator.Checked := cqrini.ReadBool('Profiles', 'Locator', True);
  chkProfileQTH.Checked := cqrini.ReadBool('Profiles', 'QTH', True);
  chkProfileRig.Checked := cqrini.ReadBool('Profiles', 'RIG', False);
  chkUseProfilesChange(nil);

  chkShow2190M.Checked := cqrini.ReadBool('DXCluster', 'Show2190M', True);
  chkShow630M.Checked := cqrini.ReadBool('DXCluster', 'Show630M', True);
  chkShow160M.Checked := cqrini.ReadBool('DXCluster', 'Show160M', True);
  chkShow80M.Checked := cqrini.ReadBool('DXCluster', 'Show80M', True);
  chkShow60M.Checked := cqrini.ReadBool('DXCluster', 'Show60M', True);
  chkShow40M.Checked := cqrini.ReadBool('DXCluster', 'Show40M', True);
  chkShow30M.Checked := cqrini.ReadBool('DXCluster', 'Show30M', True);
  chkShow20M.Checked := cqrini.ReadBool('DXCluster', 'Show20M', True);
  chkShow17M.Checked := cqrini.ReadBool('DXCluster', 'Show17M', True);
  chkShow15M.Checked := cqrini.ReadBool('DXCluster', 'Show15M', True);
  chkShow12M.Checked := cqrini.ReadBool('DXCluster', 'Show12M', True);
  chkShow10M.Checked := cqrini.ReadBool('DXCluster', 'Show10M', True);
  chkShow8M.Checked := cqrini.ReadBool('DXCluster', 'Show8M', True);
  chkShow6M.Checked := cqrini.ReadBool('DXCluster', 'Show6M', True);
  chkShow5M.Checked := cqrini.ReadBool('DXCluster', 'Show5M', True);
  chkShow4M.Checked := cqrini.ReadBool('DXCluster', 'Show4M', True);
  chkShow2M.Checked := cqrini.ReadBool('DXCluster', 'Show2M', True);
  chkShow125M.Checked := cqrini.ReadBool('DXCluster', 'Show125M', True);
  chkShow70CM.Checked := cqrini.ReadBool('DXCluster', 'Show70CM', True);
  chkShow33CM.Checked := cqrini.ReadBool('DXCluster', 'Show33CM', True);
  chkShow23CM.Checked := cqrini.ReadBool('DXCluster', 'Show23CM', True);
  chkShow13CM.Checked := cqrini.ReadBool('DXCluster', 'Show13CM', True);
  chkShow9CM.Checked := cqrini.ReadBool('DXCluster', 'Show9CM', True);
  chkShow6CM.Checked := cqrini.ReadBool('DXCluster', 'Show6CM', True);
  chkShow3CM.Checked := cqrini.ReadBool('DXCluster', 'Show3CM', True);
  chkShow125CM.Checked := cqrini.ReadBool('DXCluster', 'Show125CM', True);
  chkShow6MM.Checked := cqrini.ReadBool('DXCluster', 'Show6MM', True);
  chkShow4MM.Checked := cqrini.ReadBool('DXCluster', 'Show4MM', True);
  chkShow25MM.Checked := cqrini.ReadBool('DXCluster', 'Show25MM', True);
  chkShow2MM.Checked := cqrini.ReadBool('DXCluster', 'Show2MM', True);
  chkShow1MM.Checked := cqrini.ReadBool('DXCluster', 'Show1MM', True);
  chkCW.Checked := cqrini.ReadBool('DXCluster', 'CW', True);
  chkSSB.Checked := cqrini.ReadBool('DXCluster', 'SSB', True);
  chkDATA.Checked := cqrini.ReadBool('DXCluster', 'DATA', True);
  edtDoNotShow.Text := cqrini.ReadString('DXCluster', 'NotShow', '');
  cmbNewCountry.Selected := cqrini.ReadInteger('DXCluster', 'NewCountry', 0);
  cmbNewBand.Selected := cqrini.ReadInteger('DXCluster', 'NewBand', 0);
  cmbNewMode.Selected := cqrini.ReadInteger('DXCluster', 'NewMode', 0);
  cmbQSLNeeded.Selected := cqrini.ReadInteger('DXCluster', 'NeedQSL', 0);
  chkConToDXC.Checked := cqrini.ReadBool('DXCluster', 'ConAfterRun', False);
  chkShowDxcCountry.Checked := cqrini.ReadBool('DXCluster','ShowDxcCountry',False);
  edtAlertCmd.Text := cqrini.ReadString('DXCluster','AlertCmd','');
  edtStartConCmd.Text := cqrini.ReadString('DXCluster','StartCmd','');

  chkUseDefaultSEttings.Checked := cqrini.ReadBool('Fonts', 'UseDefault', True);
  lblbFont.Caption := cqrini.ReadString('Fonts', 'Buttons', 'Sans 10');
  lbleFont.Caption := cqrini.ReadString('Fonts', 'Edits', 'Sans 10');
  lblgFont.Caption := cqrini.ReadString('Fonts', 'Grids', 'Monospace 8');
  lblqFont.Caption := cqrini.ReadString('Fonts', 'QGrids', 'Sans 10');
  feSize := cqrini.ReadInteger('Fonts', 'eSize', 10);
  fbSize := cqrini.ReadInteger('Fonts', 'bSize', 10);
  fgSize := cqrini.ReadInteger('Fonts', 'gSize', 8);
  fqSize := cqrini.ReadInteger('Fonts', 'qSize', 10);

  chkgridgreenbar.Checked := cqrini.ReadBool('Fonts','GridGreenBar',False);
  chkgridboldtitle.Checked := cqrini.ReadBool('Fonts','GridBoldTitle',False);
  chkgridshowhint.Checked := cqrini.ReadBool('Fonts','GridShowHint',False);
  chkgridsmallrows.Checked := cqrini.ReadBool('Fonts','GridSmallRows',False);
  chkgriddotsinsteadspaces.Checked := cqrini.ReadBool('Fonts','GridDotsInsteadSpaces',False);

  clboxNewWaz.Selected := cqrini.ReadInteger('Zones', 'NewWAZ', 0);
  clBoxBandWAZ.Selected := cqrini.ReadInteger('Zones', 'NewBandWAZ', 0);
  clBoxQSLWAZ.Selected := cqrini.ReadInteger('Zones', 'QSLWAZ', 0);
  clboxNewITU.Selected := cqrini.ReadInteger('Zones', 'NewITU', 0);
  clBoxBandITU.Selected := cqrini.ReadInteger('Zones', 'NewBandITU', 0);
  clBoxQSLITU.Selected := cqrini.ReadInteger('Zones', 'QSLITU', 0);
  chkShowWAZInfo.Checked := cqrini.ReadBool('Zones', 'ShowWAZInfo', True);
  chkShowITUInfo.Checked := cqrini.ReadBool('Zones', 'ShowITUInfo', True);

  clboxNewIOTA.Selected := cqrini.ReadInteger('IOTA', 'NewIOTA', 0);
  clboxQSLIOTA.Selected := cqrini.ReadInteger('IOTA', 'QSLIOTA', 0);
  chkShowIOTAInfo.Checked := cqrini.ReadBool('IOTA', 'ShowIOTAInfo', True);

  cmbFirstClub.Text := cqrini.ReadString('Clubs', 'First', '');
  cmbSecondClub.Text := cqrini.ReadString('Clubs', 'Second', '');
  cmbThirdClub.Text := cqrini.ReadString('Clubs', 'Third', '');
  cmbFourthClub.Text := cqrini.ReadString('Clubs', 'Fourth', '');
  cmbFifthClub.Text := cqrini.ReadString('Clubs', 'Fifth', '');
  chkCheckMembershipUpdate.Checked := cqrini.ReadBool('Clubs', 'CheckForUpdate', False);

  lblBandMapFont.Font.Name := cqrini.ReadString('BandMap', 'BandFont', 'Monospace');
  lblBandMapFont.Font.Size := cqrini.ReadInteger('BandMap', 'FontSize', 8);
  fbandSize := cqrini.ReadInteger('BandMap', 'FontSize', 8);
  lblBandMapFont.Caption :=
    cqrini.ReadString('BandMap', 'BandFont', 'Monospace') + ' ' + IntToStr(fbandSize);
  cmbQSOBandColor.Selected := cqrini.ReadInteger('BandMap', 'NewQSOColor', clBlack);
  chkBandMapkHz.Checked := cqrini.ReadBool('BandMap', 'in_kHz', True);
  chkSaveBandMap.Checked := cqrini.ReadBool('BandMap', 'Save', False);
  edtFirst.Text := IntToStr(cqrini.ReadInteger('BandMap', 'FirstAging', 5));
  edtSecond.Text := IntToStr(cqrini.ReadInteger('BandMap', 'SecondAging', 8));
  edtDisep.Text := IntToStr(cqrini.ReadInteger('BandMap', 'Disep', 12));
  cmbFrmDXCColor.Selected := cqrini.ReadInteger('BandMap', 'ClusterColor', clBlack);
  chkShowActiveBand.Checked := cqrini.ReadBool('BandMap', 'OnlyActiveBand', False);
  chkShowActiveMode.Checked := cqrini.ReadBool('BandMap', 'OnlyActiveMode', False);
  chkDeleteAfterQSO.Checked := cqrini.ReadBool('BandMap', 'DeleteAfterQSO', True);
  chkUseDXCColors.Checked := cqrini.ReadBool('BandMap', 'UseDXCColors', False);
  chkAddAfterSaveQSO.Checked := cqrini.ReadBool('BandMap', 'AddAfterQSO', False);
  chkIgnoreBandFreq.Checked := cqrini.ReadBool('BandMap','IgnoreBandFreq',True);
  chkUseNewQSOFreqMode.Checked := cqrini.ReadBool('BandMap','UseNewQSOFreqMode',False);
  chkPlusToBandMap.Checked := cqrini.ReadBool('BandMap','PlusToBandMap',False);
  seFreqWidth.Value := cqrini.ReadInteger('BandMapFilter','FreqWidth',12);
  seCallWidth.Value := cqrini.ReadInteger('BandMapFilter','CallWidth',12);

  edtXplanetPath.Text := cqrini.ReadString('xplanet', 'path', '/usr/bin/xplanet');
  edtXHeight.Text := cqrini.ReadString('xplanet', 'height', '100');
  edtXWidth.Text := cqrini.ReadString('xplanet', 'width', '100');
  edtXTop.Text := cqrini.ReadString('xplanet', 'top', '10');
  edtXLeft.Text := cqrini.ReadString('xplanet', 'left', '10');
  chkShowXplanet.Checked := cqrini.ReadBool('xplanet', 'run', False);
  chkCloseXplanet.Checked := cqrini.ReadBool('xplanet', 'close', False);
  edtXRefresh.Text := cqrini.ReadString('xplanet', 'refresh', '5');
  edtXLastSpots.Text := cqrini.ReadString('xplanet', 'LastSpots', '20');
  rgProjection.ItemIndex := cqrini.ReadInteger('xplanet', 'project', 0);
  rgShowFrom.ItemIndex := cqrini.ReadInteger('xplanet', 'ShowFrom', 0);
  cmbXplanetColor.Selected := cqrini.ReadInteger('xplanet', 'color', clWhite);
  chkXplanetColor.Checked := cqrini.ReadBool('xplanet', 'UseDefColor', True);
  edtXplanetLoc.Text := cqrini.ReadString('xplanet', 'loc', '');
  chkShowOwnPos.Checked := cqrini.ReadBool('xplanet', 'ShowOwnPos', False);

  cmbFirstZip.Text := cqrini.ReadString('ZipCode', 'First', '');
  cmbFirstSaveTo.Text := cqrini.ReadString('ZipCode', 'FirstSaveTo', '');
  rgFirstZipPos.ItemIndex := cqrini.ReadInteger('ZipCode', 'FirstPos', 0);
  cmbSecondZip.Text := cqrini.ReadString('ZipCode', 'Second', '');
  cmbSecondSaveTo.Text := cqrini.ReadString('ZipCode', 'SecondSaveTo', '');
  rgSecondZipPos.ItemIndex := cqrini.ReadInteger('ZipCode', 'SecondPos', 0);
  cmbThirdZip.Text := cqrini.ReadString('ZipCode', 'Third', '');
  cmbThirdSaveTo.Text := cqrini.ReadString('ZipCode', 'ThirdSaveTo', '');
  rgThirdZipPos.ItemIndex := cqrini.ReadInteger('ZipCode', 'ThirdPos', 0);

  chkIncLoTWDXCC.Checked := cqrini.ReadBool('LoTW', 'IncLoTWDXCC', False);
  chkNewQSOLoTW.Checked := cqrini.ReadBool('LoTW', 'NewQSOLoTW', False);
  edtLoTWName.Text := cqrini.ReadString('LoTW', 'LoTWName', '');
  edtLoTWPass.Text := cqrini.ReadString('LoTW', 'LoTWPass', '');
  chkShowLoTWInfo.Checked := cqrini.ReadBool('LoTW', 'ShowInfo', True);
  chkShowBckLoTW.Checked := cqrini.ReadBool('LoTW', 'UseBackColor', True);
  cmbLoTWBckColor.Selected := cqrini.ReadInteger('LoTW', 'BckColor', clMoneyGreen);
  edteQSLName.Text := cqrini.ReadString('LoTW', 'eQSLName', '');
  edteQSLPass.Text := cqrini.ReadString('LoTW', 'eQSLPass', '');
  edteQSLStartAddr.Text := cqrini.ReadString('LoTW', 'eQSLStartAddr','https://www.eqsl.cc/qslcard/DownloadInBox.cfm');
  edteQSLDnlAddr.Text := cqrini.ReadString('LoTW', 'eQSLDnlAddr','https://www.eqsl.cc/downloadedfiles/');
  edteQSLViewAddr.Text := cqrini.ReadString('LoTW', 'eQSViewAddr','https://www.eQSL.cc/qslcard/GeteQSL.cfm');
  chkShowBckEQSL.Checked := cqrini.ReadBool('LoTW', 'eUseBackColor', True);
  cmbeQSLBckColor.Selected := cqrini.ReadInteger('LoTW', 'eBckColor', clSkyBlue);
  chkExpCommet.Checked := cqrini.ReadBool('LoTW', 'ExpComment', True);

  rgFreqFrom.ItemIndex := cqrini.ReadInteger('fldigi', 'freq', 1);       //
  edtDefaultFreq.Text := cqrini.ReadString('fldigi', 'deffreq', '3.600');//
  rgModeFrom.ItemIndex := cqrini.ReadInteger('fldigi', 'mode', 1);       //
  cmbDefaultMode.Text := cqrini.ReadString('fldigi', 'defmode', 'RTTY'); //
  edtDefaultRST.Text := cqrini.ReadString('fldigi', 'defrst', '599');
  rgRSTFrom.ItemIndex := cqrini.ReadInteger('fldigi', 'rst', 0);
  edtLoadFromFldigi.Value := cqrini.ReadInteger('fldigi', 'interval', 2);
  chkRunFldigi.Checked := cqrini.ReadBool('fldigi', 'run', False);
  edtFldigiPath.Text := cqrini.ReadString('fldigi', 'path', '');
  edtFldigiPort.Text := cqrini.ReadString('fldigi','port','7362');
  edtFldigiIp.Text :=  cqrini.ReadString('fldigi','ip','127.0.0.1');
  chkFldXmlRpc.Checked := cqrini.ReadBool('fldigi', 'xmlrpc', False);
  edtDropSyncErr.Value:= cqrini.ReadInteger('fldigi', 'dropSyErr', 3);


  edtWsjtPath.Text         := cqrini.ReadString('wsjt','path','');
  edtWsjtPort.Text         := cqrini.ReadString('wsjt','port','2237');
  edtWsjtIp.Text           := cqrini.ReadString('wsjt','ip','127.0.0.1');
  chkRunWsjt.Checked       := cqrini.ReadBool('wsjt','run',False);
  rgWsjtFreqFrom.ItemIndex := cqrini.ReadInteger('wsjt', 'freq', 1);
  edtWsjtDefaultFreq.Text  := cqrini.ReadString('wsjt', 'deffreq', '3.600');
  rgWsjtModeFrom.ItemIndex := cqrini.ReadInteger('wsjt', 'mode', 1);
  cmbWsjtDefaultMode.Text  := cqrini.ReadString('wsjt', 'defmode', 'FT8');
  chkwsjtLoeQ.Checked      := cqrini.ReadBool('wsjt', 'chkLoTWeQSL', False);
  DateEditCall.Text := cqrini.ReadString('wsjt', 'wb4calldate', '1900-01-01'); //sure all qsos by default :-)
  DateEditLoc.Text := cqrini.ReadString('wsjt', 'wb4locdate','1900-01-01');
  cgLimit.Checked[0] := cqrini.ReadBool('wsjt','wb4CCall', False);
  cgLimit.Checked[1] := cqrini.ReadBool('wsjt','wb4CLoc', False);

  edtADIFPort.Text         := cqrini.ReadString('n1mm','port','2333');
  edtADIFIp.Text           := cqrini.ReadString('n1mm','ip','127.0.0.1');


  chkEnableBackup.Checked := cqrini.ReadBool('Backup', 'Enable', False);
  chkCompressBackup.Checked := cqrini.ReadBool('Backup', 'Compress', True);
  edtBackupPath.Text := cqrini.ReadString('Backup', 'Path', dmData.DataDir);
  edtBackupPath1.Text := cqrini.ReadString('Backup', 'Path1','');
  rgBackupType.ItemIndex := cqrini.ReadInteger('Backup', 'BackupType', 0);
  chkAskBackup.Checked := cqrini.ReadBool('Backup','AskFirst',False);

  edtTxtFiles.Text := cqrini.ReadString('ExtView', 'txt', '');
  edtPdfFiles.Text := cqrini.ReadString('ExtView', 'pdf', '');
  edtImgFiles.Text := cqrini.ReadString('ExtView', 'img', '');
  edtHtmlFiles.Text := cqrini.ReadString('ExtView', 'html', dmUtils.MyDefaultBrowser);
  chkIntQSLViewer.Checked := cqrini.ReadBool('ExtView', 'QSL', True);

  edtClub1Date.Text := cqrini.ReadString('FirstClub', 'DateFrom', C_CLUB_DEFAULT_DATE_FROM);
  edtClub2Date.Text := cqrini.ReadString('SecondClub', 'DateFrom', C_CLUB_DEFAULT_DATE_FROM);
  edtClub3Date.Text := cqrini.ReadString('ThirdClub', 'DateFrom', C_CLUB_DEFAULT_DATE_FROM);
  edtClub4Date.Text := cqrini.ReadString('FourthClub', 'DateFrom', C_CLUB_DEFAULT_DATE_FROM);
  edtClub5Date.Text := cqrini.ReadString('FifthClub', 'DateFrom', C_CLUB_DEFAULT_DATE_FROM);

  edtCbHamQTHUser.Text := cqrini.ReadString('CallBook', 'CbHamQTHUser', '');
  edtCbHamQTHPass.Text := cqrini.ReadString('CallBook', 'CbHamQTHPass', '');
  edtCbQRZUser.Text := cqrini.ReadString('CallBook', 'CbQRZUser', '');
  edtCbQRZPass.Text := cqrini.ReadString('CallBook', 'CbQRZPass', '');
  edtCbQRZCQUser.Text := cqrini.ReadString('CallBook', 'CbQRZCQUser', '');
  edtCbQRZCQPass.Text := cqrini.ReadString('CallBook', 'CbQRZCQPass', '');
  rbHamQTH.Checked := cqrini.ReadBool('Callbook', 'HamQTH', True);
  rbQRZ.Checked := cqrini.ReadBool('Callbook', 'QRZ', False);
  rbQRZCQ.Checked := cqrini.ReadBool('Callbook', 'QRZCQ', False);

  cmbCl10db.Selected        := cqrini.ReadInteger('RBN','10db',clWhite);
  cmbCl20db.Selected        := cqrini.ReadInteger('RBN','20db',clPurple);
  cmbCl30db.Selected        := cqrini.ReadInteger('RBN','30db',clMaroon);
  cmbClOver30db.Selected    := cqrini.ReadInteger('RBN','over30db',clRed);
  edtRBNLogin.Text       := cqrini.ReadString('RBN','login','');
  edtWatchFor.Text       := cqrini.ReadString('RBN','watch','');
  chkRBNAutoConn.Checked := cqrini.ReadBool('RBN','AutoConnect',False);
  chkRBNMAutoConn.Checked := cqrini.ReadBool('RBN','AutoConnectM',false);
  chkRBNLink.Checked     := cqrini.ReadBool('RBN','AutoLink',false);
  edtDelAfter.Text       := cqrini.ReadString('RBN','deleteAfter','60');
  edtRBNServer.Text      := cqrini.ReadString('RBN','Server','telnet.reversebeacon.net:7000');

  chkHaUpEnabled.Checked := cqrini.ReadBool('OnlineLog','HaUP',False);
  chkHaUpOnline.Checked  := cqrini.ReadBool('OnlineLog','HaUpOnline',False);
  edtHaUserName.Text     := cqrini.ReadString('OnlineLog','HaUserName','');
  edtHaPasswd.Text       := cqrini.ReadString('OnlineLog','HaPasswd','');
  cmbHaColor.Selected    := cqrini.ReadInteger('OnlineLog','HaColor',clBlue);
  edtHamQTHurl.Text      := cqrini.ReadString('OnlineLog','HaUrl','http://www.hamqth.com/qso_realtime.php');
  chkHaUpEnabledChange(nil);

  chkClUpEnabled.Checked := cqrini.ReadBool('OnlineLog','ClUP',False);
  chkClUpOnline.Checked  := cqrini.ReadBool('OnlineLog','ClUpOnline',False);
  edtClUserName.Text     := cqrini.ReadString('OnlineLog','ClUserName','');
  edtClPasswd.Text       := cqrini.ReadString('OnlineLog','ClPasswd','');
  edtClEmail.Text        := cqrini.ReadString('OnlineLog','ClEmail','');
  cmbClColor.Selected    := cqrini.ReadInteger('OnlineLog','ClColor',clRed);
  edtClubLogUrl.Text     := cqrini.ReadString('OnlineLog','ClUrl','https://clublog.org/realtime.php');
  edtClubLogUrlDel.Text  := cqrini.ReadString('OnlineLog','ClUrlDel','https://clublog.org/delete.php');
  chkClUpEnabledChange(nil);

  chkHrUpEnabled.Checked := cqrini.ReadBool('OnlineLog','HrUP',False);
  chkHrUpOnline.Checked  := cqrini.ReadBool('OnlineLog','HrUpOnline',False);
  edtHrUserName.Text     := cqrini.ReadString('OnlineLog','HrUserName','');
  edtHrCode.Text         := cqrini.ReadString('OnlineLog','HrCode','');
  cmbHrColor.Selected    := cqrini.ReadInteger('OnlineLog','HrColor',clPurple);
  edtHrdUrl.Text         := cqrini.ReadString('OnlineLog','HrUrl','http://robot.hrdlog.net/NewEntry.aspx');
  chkHrUpEnabledChange(nil);

  chkUdUpEnabled.Checked := cqrini.ReadBool('OnlineLog','UdUP',False);
  chkUdUpOnline.Checked  := cqrini.ReadBool('OnlineLog','UdUpOnline',False);
  edtUdAddress.Text      := cqrini.ReadString('OnlineLog','UdAddress','');
  chkUdIncExch.Checked   := cqrini.ReadBool('OnlineLog','UdIncExch',True);
  cmbUdColor.Selected    := cqrini.ReadInteger('OnlineLog','UdColor',clGreen);
  chkUdUpEnabledChange(nil);

  chkCloseAfterUpload.Checked := cqrini.ReadBool('OnlineLog','CloseAfterUpload',False);
  chkIgnoreLoTW.Checked  := cqrini.ReadBool('OnlineLog','IgnoreLoTWeQSL',False);
  chkIgnoreQSL.Checked   := cqrini.ReadBool('OnlineLog','IgnoreQSL',False);
  chkIgnoreEdit.Checked  := cqrini.ReadBool('OnlineLog','IgnoreEdit',False);

  edtCondxImageUrl.Text      := cqrini.ReadString('prop','Url','http://www.hamqsl.com/solarbrief.php');
  edtCondxTextUrl.Text       := cqrini.ReadString('prop','UrlTxt','https://www.hamqsl.com/solarxml.php' );
  rbCondxAsImage.Checked     := cqrini.ReadBool('prop','AsImage',True);
  rbCondxAsText.Checked      := cqrini.ReadBool('prop','AsText',False);
  chkShowCondxValues.Checked := cqrini.ReadBool('prop','Values',True);
  chkCondxCalcHF.Checked     := cqrini.ReadBool('prop','CalcHF',True);
  chkCondxCalcVHF.Checked    := cqrini.ReadBool('prop','CalcVHF',True);

  wasOnlineLogSupportEnabled := chkHaUpEnabled.Checked or chkClUpEnabled.Checked or chkHrUpEnabled.Checked or chkUdUpEnabled.Checked;

  fraExportPref1.LoadExportPref;

  lbPreferences.Selected[pgPreferences.ActivePageIndex] := True;


  chkSysUTCClick(nil);
  TRXChanged      := False;
  RotChanged      := False;
  CWKeyerChanged := False;

  pgPreferences.ActivePageIndex := ActPageIdx;    //set wanted tab for showing when open. ActTab is public variable.
  lbPreferences.ItemIndex := ActPageIdx;
end;

procedure TfrmPreferences.edtPollExit(Sender: TObject);
var
  tmp: integer = 0;
begin
  if not TryStrToInt(edtPoll.Text, tmp) then
    edtPoll.Text := '500';
end;

procedure TfrmPreferences.pgPreferencesChange(Sender: TObject);
begin
  lbPreferences.Selected[pgPreferences.ActivePageIndex] := True;
end;


procedure TfrmPreferences.SaveClubSection;
begin
  cqrini.WriteString('Clubs', 'First', cmbFirstClub.Text);
  cqrini.WriteString('Clubs', 'Second', cmbSecondClub.Text);
  cqrini.WriteString('Clubs', 'Third', cmbThirdClub.Text);
  cqrini.WriteString('Clubs', 'Fourth', cmbFourthClub.Text);
  cqrini.WriteString('Clubs', 'Fifth', cmbFifthClub.Text);
  cqrini.WriteBool('Clubs', 'CheckForUpdate', chkCheckMembershipUpdate.Checked)
end;

procedure TfrmPreferences.LoadMebershipCombo;
var
  i : Integer;
  Club1 : String;
  Club2 : String;
  Club3 : String;
  Club4 : String;
  Club5 : String;
begin
  Club1 := cmbFirstClub.Text;
  Club2 := cmbSecondClub.Text;
  Club3 := cmbThirdClub.Text;
  Club4 := cmbFourthClub.Text;
  Club5 := cmbFifthClub.Text;

  cmbSecondClub.Items.Clear;
  cmbThirdClub.Items.Clear;
  cmbFourthClub.Items.Clear;
  cmbFifthClub.Items.Clear;

  dmMembership.ReadMemberList(cmbFirstClub);
  for i := 0 to cmbFirstClub.Items.Count - 1 do
  begin
    cmbSecondClub.Items.Add(cmbFirstClub.Items[i]);
    cmbThirdClub.Items.Add(cmbFirstClub.Items[i]);
    cmbFourthClub.Items.Add(cmbFirstClub.Items[i]);
    cmbFifthClub.Items.Add(cmbFirstClub.Items[i]);
  end;

  cmbFirstClub.ItemIndex  := cmbFirstClub.Items.IndexOf(Club1);
  cmbSecondClub.ItemIndex := cmbSecondClub.Items.IndexOf(Club2);
  cmbThirdClub.ItemIndex  := cmbThirdClub.Items.IndexOf(Club3);
  cmbFourthClub.ItemIndex := cmbFourthClub.Items.IndexOf(Club4);
  cmbFifthClub.ItemIndex  := cmbFifthClub.Items.IndexOf(Club5)
end;

procedure TfrmPreferences.LoadMembersFromCombo(ClubComboText, ClubNumber : String);
var
  MemberFileName : String;
begin
  if (ClubComboText = '') or (Pos('---', ClubComboText) > 0) then
    exit;

  MemberFileName := dmMembership.GetClubFileName(ClubComboText);
  with TfrmLoadClub.Create(self) do
  try
    TypOfLoad := 0;
    DBnum := ClubNumber;
    SourceFile := MemberFileName;
    ShowModal
  finally
    Free
  end;

  if not FileExists(dmData.MembersDir + MemberFileName) then
    CopyFile(dmData.GlobalMembersDir + MemberFileName, dmData.MembersDir + MemberFileName);

  LoadMebershipCombo
end;
Procedure TfrmPreferences.LoadTRX(RigNr:integer);
var
   nr,
   rp  :string;
Begin
  nr:=IntToStr(RigNr);
  rp:= cqrini.ReadString('TRX', 'RigCtldPath', '/usr/bin/rigctld');
  if FileExistsUTF8(rp) then
    dmUtils.LoadRigsToComboBox(cqrini.ReadString('TRX'+nr, 'model', ''),rp,cmbModelRig)
  else begin
    Application.MessageBox('rigctld binary not found, unable to load list of supported rigs!'+LineEnding+LineEnding+
                           'Fix path to rigctld in TRX control tab.', 'Error', mb_OK+ mb_IconError)
  end;
  edtRDevice.Text := cqrini.ReadString('TRX'+nr, 'device', '');
  edtPoll.Text := cqrini.ReadString('TRX'+nr, 'poll', '500');
  edtRadioName.Text := cqrini.ReadString('TRX'+nr, 'Desc', '');
  chkRSendCWR.Checked := cqrini.ReadBool('TRX'+nr, 'CWR', False);
  chkRVfo.Checked:=   cqrini.ReadBool('TRX'+nr, 'ChkVfo', True);
  edtRRigCtldPort.Text := cqrini.ReadString('TRX'+nr, 'RigCtldPort', '4532');
  edtRRigCtldArgs.Text := cqrini.ReadString('TRX'+nr, 'ExtraRigCtldArgs', '');
  chkRunRigCtld.Checked := cqrini.ReadBool('TRX'+nr, 'RunRigCtld', False);
  chkRPwrON.Checked := cqrini.ReadBool('TRX'+nr, 'RigPwrON', True);
  chkUTC2R.Checked := cqrini.ReadBool('TRX'+nr, 'UTC2Rig', False);
  chkCPollR.Checked:= cqrini.ReadBool('TRX'+nr, 'CPollR', True);
  chkVoiceR.Checked:= cqrini.ReadBool('TRX'+nr, 'RigVoice', True);
  edtRHost.Text := cqrini.ReadString('TRX'+nr, 'host', 'localhost');
  cmbSpeedR.ItemIndex := cqrini.ReadInteger('TRX'+nr, 'SerialSpeed', 0);
  cmbDataBitsR.ItemIndex := cqrini.ReadInteger('TRX'+nr, 'DataBits', 0);
  cmbStopBitsR.ItemIndex := cqrini.ReadInteger('TRX'+nr, 'StopBits', 0);
  cmbParityR.ItemIndex := cqrini.ReadInteger('TRX'+nr, 'Parity', 0);
  cmbHanshakeR.ItemIndex := cqrini.ReadInteger('TRX'+nr, 'HandShake', 0);
  cmbDTRR.ItemIndex := cqrini.ReadInteger('TRX'+nr, 'DTR', 0);
  cmbRTSR.ItemIndex := cqrini.ReadInteger('TRX'+nr, 'RTS', 0);
  edtUsr1RName.Text:=cqrini.ReadString('TRX'+nr, 'usr1name', 'Usr1');
  edtUsr2RName.Text:=cqrini.ReadString('TRX'+nr, 'usr2name', 'Usr2');
  edtUsr3RName.Text:=cqrini.ReadString('TRX'+nr, 'usr3name', 'Usr3');
  edtUsr1R.Text:=cqrini.ReadString('TRX'+nr, 'usr1', '');
  edtUsr2R.Text:=cqrini.ReadString('TRX'+nr, 'usr2', '');
  edtUsr3R.Text:=cqrini.ReadString('TRX'+nr, 'usr3', '');
  RadioNrLoaded:= RigNr;
end;
Procedure TfrmPreferences.SaveTRX(RigNr:integer);
var
   nr :string;
Begin

  nr:=IntToStr(RigNr);
  if cmbModelRig.Text='' then //empty model will erase whole TRX and corresponding bandwidth section
     Begin
      cqrini.SectionErase('TRX'+nr);
      cqrini.SectionErase('Band'+nr);
      cqrini.SectionErase('CW'+nr);
      exit;
     end;

  cqrini.WriteString('TRX'+nr, 'device', edtRDevice.Text);
  cqrini.WriteString('TRX'+nr, 'model', dmUtils.GetRigIdFromComboBoxItem(cmbModelRig.Text));
  cqrini.WriteString('TRX'+nr, 'poll', edtPoll.Text);
  cqrini.WriteString('TRX'+nr, 'Desc', edtRadioName.Text);
  cqrini.WriteBool('TRX'+nr, 'CWR', chkRSendCWR.Checked);
  cqrini.WriteBool('TRX'+nr, 'ChkVfo',chkRVfo.Checked);
  cqrini.WriteString('TRX'+nr, 'RigCtldPort', edtRRigCtldPort.Text);
  cqrini.WriteString('TRX'+nr, 'ExtraRigCtldArgs', edtRRigCtldArgs.Text);
  cqrini.WriteBool('TRX'+nr, 'RunRigCtld', chkRunRigCtld.Checked);
  cqrini.WriteBool('TRX'+nr, 'RigPwrON', chkRPwrON.Checked);
  cqrini.WriteBool('TRX'+nr, 'UTC2Rig', chkUTC2R.Checked);
  cqrini.WriteBool('TRX'+nr, 'CPollR',chkCPollR.Checked);
  cqrini.WriteBool('TRX'+nr, 'RigVoice', chkVoiceR.Checked);
  cqrini.WriteString('TRX'+nr, 'host', edtRHost.Text);
  cqrini.WriteInteger('TRX'+nr, 'SerialSpeed', cmbSpeedR.ItemIndex);
  cqrini.WriteInteger('TRX'+nr, 'DataBits', cmbDataBitsR.ItemIndex);
  cqrini.WriteInteger('TRX'+nr, 'StopBits', cmbStopBitsR.ItemIndex);
  cqrini.WriteInteger('TRX'+nr, 'Parity', cmbParityR.ItemIndex);
  cqrini.WriteInteger('TRX'+nr, 'HandShake', cmbHanshakeR.ItemIndex);
  cqrini.WriteInteger('TRX'+nr, 'DTR', cmbDTRR.ItemIndex);
  cqrini.WriteInteger('TRX'+nr, 'RTS', cmbRTSR.ItemIndex);
  cqrini.WriteString('TRX'+nr, 'usr1name', edtUsr1RName.Text);
  cqrini.WriteString('TRX'+nr, 'usr2name', edtUsr2RName.Text);
  cqrini.WriteString('TRX'+nr, 'usr3name', edtUsr3RName.Text);
  cqrini.WriteString('TRX'+nr, 'usr1', edtUsr1R.Text);
  cqrini.WriteString('TRX'+nr, 'usr2', edtUsr2R.Text);
  cqrini.WriteString('TRX'+nr, 'usr3', edtUsr3R.Text);
end;
procedure TfrmPreferences.LoadBandW(RigNr:integer);
var
   nr :string;
Begin
  nr:=IntToStr(RigNr);
  edtCW.Value := cqrini.ReadInteger('Band'+nr, 'CW', 500);
  edtSSB.Value := cqrini.ReadInteger('Band'+nr, 'SSB', 1800);
  edtData.Value := cqrini.ReadInteger('Band'+nr, 'RTTY', 500);  //note: Data is called rtty for backward compatibility
  edtAM.Value := cqrini.ReadInteger('Band'+nr, 'AM', 3000);
  edtFM.Value := cqrini.ReadInteger('Band'+nr, 'FM', 2500);
  cmbDataMode.ItemIndex := cmbDataMode.Items.IndexOf(cqrini.ReadString('Band'+nr, 'Datamode', 'RTTY'));
  edtDataCmd.Text:=cqrini.ReadString('Band'+nr, 'Datacmd', 'RTTY');
  chkModeReverse.Checked :=cqrini.ReadBool('Band'+nr, 'UseReverse', False);
  BandWNrLoaded := RigNr;
  if (cqrini.ReadString('TRX'+nr, 'model', '')='') then
    lblNoRigForMode.Visible:=True
   else
    lblNoRigForMode.Visible:=False;
end;
procedure TfrmPreferences.SaveBandW(RigNr:integer);
var
   nr :string;
Begin
  nr:=IntToStr(RigNr);
  if (cqrini.ReadString('TRX'+nr, 'model', '')='') then  exit; //No rig, no save
  cqrini.WriteInteger('Band'+nr, 'CW', edtCW.Value);
  cqrini.WriteInteger('Band'+nr, 'SSB', edtSSB.Value);
  cqrini.WriteInteger('Band'+nr, 'RTTY', edtData.Value);  //note: Data is called rtty for backward compatibility
  cqrini.WriteInteger('Band'+nr, 'AM', edtAM.Value);
  cqrini.WriteInteger('Band'+nr, 'FM', edtFM.Value);
  cqrini.WriteString('Band'+nr, 'Datamode', cmbDataMode.Text);
  cqrini.WriteString('Band'+nr, 'Datacmd', edtDatacmd.Text);
  cqrini.WriteBool('Band'+nr, 'UseReverse', chkModeReverse.Checked);
end;
procedure TfrmPreferences.LoadCWif(RigNr:integer);
var
   nr :string;
Begin
  nr:=IntToStr(RigNr);
  cmbIfaceType.ItemIndex := cqrini.ReadInteger('CW'+nr, 'Type', 0);
  cbNoKeyerReset.Checked := cqrini.ReadBool('CW'+nr, 'NoReset', false);
  edtWinPort.Text        := cqrini.ReadString('CW'+nr, 'wk_port', '');
  chkPotSpeed.Checked    := cqrini.ReadBool('CW'+nr, 'PotSpeed', False);
  edtWinSpeed.Value      := cqrini.ReadInteger('CW'+nr, 'wk_speed', 30);
  edtCWAddress.Text      := cqrini.ReadString('CW'+nr, 'cw_address', 'localhost');
  edtCWPort.Text         := cqrini.ReadString('CW'+nr, 'cw_port', '6789');
  edtCWSpeed.Value       := cqrini.ReadInteger('CW'+nr, 'cw_speed', 30);
  edtWinMinSpeed.Value   := cqrini.ReadInteger('CW'+nr, 'wk_min', 5);
  edtWinMaxSpeed.Value   := cqrini.ReadInteger('CW'+nr, 'wk_max', 60);
  edtK3NGPort.Text       := cqrini.ReadString('CW'+nr,'K3NGPort','');
  edtK3NGSerSpeed.Text   := IntToStr(cqrini.ReadInteger('CW'+nr,'K3NGSerSpeed',115200));
  edtK3NGSpeed.Text      := IntToStr(cqrini.ReadInteger('CW'+nr,'K3NGSpeed',30));
  edtHamLibSpeed.Text    := IntToStr(cqrini.ReadInteger('CW'+nr,'HamLibSpeed',30));
  chkUseHLBuffer.checked := cqrini.ReadBool('CW'+nr, 'UseHamlibBuffer', False);
  CWifLoaded := RigNr;
  if (cqrini.ReadString('TRX'+nr, 'model', '')='') then
    lblNoRigForCW.Visible:=True
   else
    lblNoRigForCW.Visible:=False;
end;
procedure TfrmPreferences.SaveCWif(RigNr:integer);
var
   nr :string;
Begin
  nr:=IntToStr(RigNr);
  if (cqrini.ReadString('TRX'+nr, 'model', '')='') then  exit; //No rig, no save
  cqrini.WriteInteger('CW'+nr, 'Type', cmbIfaceType.ItemIndex);
  cqrini.WriteBool('CW'+nr, 'NoReset', cbNoKeyerReset.Checked);
  cqrini.WriteString('CW'+nr, 'wk_port', edtWinPort.Text);
  cqrini.WriteBool('CW'+nr, 'PotSpeed', chkPotSpeed.Checked);
  cqrini.WriteInteger('CW'+nr, 'wk_speed', edtWinSpeed.Value);
  cqrini.WriteString('CW'+nr, 'cw_address', edtCWAddress.Text);
  cqrini.WriteString('CW'+nr, 'cw_port', edtCWPort.Text);
  cqrini.WriteInteger('CW'+nr, 'cw_speed', edtCWSpeed.Value);
  cqrini.WriteInteger('CW'+nr, 'wk_min', edtWinMinSpeed.Value);
  cqrini.WriteInteger('CW'+nr, 'wk_max', edtWinMaxSpeed.Value);
  cqrini.WriteString('CW'+nr,'K3NGPort',edtK3NGPort.Text);
  cqrini.WriteInteger('CW'+nr,'K3NGSerSpeed',StrToInt(edtK3NGSerSpeed.Text));
  cqrini.WriteInteger('CW'+nr,'K3NGSpeed',StrToInt(edtK3NGSpeed.Text));
  cqrini.WriteInteger('CW'+nr,'HamLibSpeed',StrToInt(edtHamLibSpeed.Text));
  cqrini.WriteBool('CW'+nr, 'UseHamlibBuffer', chkUseHLBuffer.checked);
end;

procedure TfrmPreferences.InitRigCmb(SetUsedRig:boolean=false);    //initialize radio selectors in TRXControl, CW and Modes
var                                      //set itemindexes to used rig
   f,i : integer;
   s,d : string;
Begin
   i:=cmbRadioNr.ItemIndex;
   cmbRadioNr.Items.Clear;
   cmbRadioNr.Items.Add('');
   cmbRadioModes.Items.Clear;               //zero position is empty
   cmbRadioModes.Items.Add('');
   cmbCWRadio.Items.Clear;
   cmbCWRadio.Items.Add('');
   for f:=1 to edtRigCount.Value do
     Begin
      s:=IntToStr(f);
      if (cqrini.ReadString('TRX'+s, 'model', '')='') then
            cmbRadioNr.Items.Add(s+' None')
           else
            cmbRadioNr.Items.Add(s+' '+cqrini.ReadString('TRX'+s, 'Desc', ''));
     end;
   for f:=1 to  cqrini.ReadInteger('TRX', 'RigCount', 2) do   //others just defined rigs
    Begin
      s:=IntToStr(f);
      d:= cqrini.ReadString('TRX'+s, 'Desc', '');
      if (cqrini.ReadString('TRX'+s, 'model', '')='') then
        Begin
             cmbRadioModes.Items.Add(s+' None');
             cmbCWRadio.Items.Add(s+' None');
        end
       else
        begin
             cmbRadioModes.Items.Add(s+' '+d);
             cmbCWRadio.Items.Add(s+' '+d);
        end;
    end;

  cmbRadioNr.ItemIndex:=i;

  if not (cqrini.ReadInteger('TRX', 'RigInUse', 1) in [ 1..edtRigCount.Value] ) then
         begin
          cqrini.WriteInteger('TRX', 'RigInUse', 1);  //used rig was deleted  (rig count changed)
          SetUsedRig:=true;
         end;

  if SetUsedRig then
    begin
     cmbRadioNr.ItemIndex:=cqrini.ReadInteger('TRX', 'RigInUse', 1);
     cmbRadioModes.ItemIndex:=cmbRadioNr.ItemIndex;
     cmbCWRadio.ItemIndex:=cmbRadioNr.ItemIndex;
    end;

  LoadBandW(cmbRadioNr.ItemIndex);
  LoadCWif(cmbRadioNr.ItemIndex);

end;
procedure TfrmPreferences.ClearUnUsedRigs;
var
   f:integer;
Begin
    //remove these just in case (they should not exist)
    for f:=-1 to  0 do
     begin
      cqrini.SectionErase('TRX'+IntToStr(f));
      cqrini.SectionErase('Band'+IntToStr(f));
      cqrini.SectionErase('CW'+IntToStr(f));
     end;
     //remove unused rigs and modes from configuration
    if  edtRigCount.Value< edtRigCount.MaxValue then
      begin
       f:= edtRigCount.MaxValue;
       repeat
         Begin
           cqrini.SectionErase('TRX'+IntToStr(f));
           cqrini.SectionErase('Band'+IntToStr(f));
           cqrini.SectionErase('CW'+IntToStr(f));
           dec(f);
         end;
       until (f=edtRigCount.Value);
      end;

    if not ( cqrini.ReadInteger('TRX', 'RigInUse', 1) in [ 1..edtRigCount.Value] ) then
         cqrini.WriteInteger('TRX', 'RigInUse', 1);  //used rig was deleted

    frmTRXControl.cmbRigGetItems(nil); //update TRXControl rig names before returning

      //6 is max rig count set by edtRigCount:Tspinedit
      //if you change it you must change also fConfigStorage.pas
      //TRX, CW and Band lists

end;


end.

