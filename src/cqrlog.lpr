program cqrlog;

{$mode objfpc}{$H+}
uses
  cmem,cthreads,uScrollBars,
  Interfaces, // this includes the LCL widgetset
  Forms,sysutils,fMain,fPreferences,dUtils,fNewQSO,dialogs,fChangeLocator,dData,
  dDXCC,fMarkQSL,fDXCCStat,fSort,fFilter,fImportProgress,fImportTest,
  TAChartLazarusPkg,RunTimeTypeInfoControls,fSelectDXCC,fGrayline,fCallbook,
  fTRXControl,fFreq,fChangeFreq,fAdifImport,fSplash,fSearch,fQTHProfiles,
  fNewQTHProfile,fEnterFreq,fExportProgress,fNewDXCluster,fDXCluster,
  fDXClusterList,dDXCluster,fWorking,fSerialPort,fQSLMgr,fSendSpot,fQSODetails,
  fUpgrade,fWAZITUStat,fIOTAStat,fClubSettings,fLoadClub,fRefCall,fGraphStat,
  fBandMap,fBandMapFilter,fLongNote,fDatabaseUpdate,fExLabelPrint,
  fImportLoTWWeb,fLoTWExport,fGroupEdit,fDefaultFreq,fCustomStat,fKeyTexts,
  fCWType,fSplitSettings,MemDSLaz,SDFLaz,turbopoweripro,fShowStations,uMyIni,
  fPropagation,fSQLConsole,fCallAttachment,fEditDetails,fQSLViewer,fCWKeys,fSCP,fDBConnect,fNewLog,
  fRebuildMembStat,uVersion,fAbout,fChangelog,fBigSquareStat,feQSLDownload,
  feQSLUpload,fSOTAExport, fNewQSODefValues, fQSLExpPref, fRotControl,
dLogUpload, fLogUploadStatus,frCWKeys, fCallAlert, fNewCallAlert;
var
  Splash : TfrmSplash;

{$IFDEF WINDOWS}{$R cqrlog.rc}{$ENDIF}

{$R *.res}

begin
  Application.Initialize;
  Splash := TfrmSplash.create(application);
  Splash.show;
  Splash.Update;
  application.ProcessMessages;
  Splash.Update;
  application.ProcessMessages;
  Sleep(500);
  Application.CreateForm(TfrmNewQSO, frmNewQSO);
  Application.CreateForm(TdmData, dmData);
  Application.CreateForm(TdmLogUpload, dmLogUpload);
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TdmUtils, dmUtils);
  Application.CreateForm(TdmDXCC, dmDXCC);
  Application.CreateForm(TdmDXCluster, dmDXCluster);
  Application.CreateForm(TfrmGrayline, frmGrayline);
  Application.CreateForm(TfrmCallbook, frmCallbook);
  Application.CreateForm(TfrmTRXControl, frmTRXControl);
  Application.CreateForm(TfrmDXCluster, frmDXCluster);
  Application.CreateForm(TfrmQSODetails, frmQSODetails);
  Application.CreateForm(TfrmBandMap, frmBandMap);
  Application.CreateForm(TfrmPropagation, frmPropagation);
  Application.CreateForm(TfrmCWKeys, frmCWKeys);
  Application.CreateForm(TfrmSCP, frmSCP);
  Application.CreateForm(TfrmRotControl, frmRotControl);
  Application.CreateForm(TfrmLogUploadStatus, frmLogUploadStatus);

  Splash.Update;
  application.ProcessMessages;
  sleep(800);
  Splash.close;
  Splash.Release;
  Application.Run;
end.

