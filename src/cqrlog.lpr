program cqrlog;

{$mode objfpc}{$H+}
uses
  cmem,cthreads,uScrollBars,
  Interfaces, // this includes the LCL widgetset
  Forms, sysutils, Classes, fMain, fPreferences, dUtils, fNewQSO, dialogs,
  fChangeLocator, fChangeOperator, dData, dDXCC, fMarkQSL, fDXCCStat, fSort,
  fFilter, fImportProgress, fImportTest,
  fSelectDXCC, fGrayline, fCallbook, fTRXControl,
  fFreq, fChangeFreq, fAdifImport, fSplash, fSearch, fQTHProfiles,
  fNewQTHProfile, fEnterFreq, fExportProgress, fNewDXCluster, fDXCluster,
  fDXClusterList, dDXCluster, fWorking, fSerialPort, fQSLMgr, fSendSpot,
  fQSODetails, fUpgrade, fWAZITUStat, fIOTAStat, fClubSettings, fLoadClub,
  fRefCall, fGraphStat, fBandMap, fBandMapWatch, fLongNote, fDatabaseUpdate,
  fExLabelPrint, fImportLoTWWeb, fLoTWExport, fGroupEdit, fDefaultFreq,
  fCustomStat, fKeyTexts, fCWType, fSplitSettings, MemDSLaz, SDFLaz,
  turbopoweripro, fShowStations, uMyIni, fPropagation, fSQLConsole,
  fCallAttachment, fEditDetails, fQSLViewer, fCWKeys, fSCP, fDBConnect, fNewLog,
  fRebuildMembStat, uVersion, fAbout, fChangelog, fBigSquareStat, feQSLDownload,
  feQSLUpload, fSOTAExport, fEDIExport, fNewQSODefValues, fQSLExpPref,
  fRotControl, dLogUpload, fLogUploadStatus, frCWKeys, fCallAlert,
  fNewCallAlert, fConfigStorage, fRbnFilter, fRbnMonitor, fRbnServer,
  fRadioMemories, fAddRadioMemory, fException, fCommentToCall,
  fNewCommentToCall, fFindCommentToCall, frExportPref, fExportPref,
  fWorkedGrids, fPropDK0WCY, fRemind, fContest, fMonWsjtx, fXfldigi,
  dMembership, dSatellite, uRigControl, uRotControl, azidis3, aziloc, fDOKStat,
  fCabrilloExport, uDbUtils, dQTHProfile, uConnectionInfo, znacmech, gline2,
  fDbSqlSel, fProgress, fDbError, fCountyStat;
var
  Splash : TfrmSplash;

{$IFDEF WINDOWS}{$R cqrlog.rc}{$ENDIF}

{$R *.res}

begin
  // Fix default BidiMode
  // see http://bugs.freepascal.org/view.php?id=22044
  Application.BidiMode:= bdLeftToRight;

  Application.CaseSensitiveOptions:=False;
  if ((Application.HasOption('v','version')) or (Application.HasOption('h','help'))) then
     Begin
        Writeln('Cqrlog Ver:',cVERSION,' Date:',cBUILD_DATE);
        if Application.HasOption('v','version') then exit;
        Writeln;
        Writeln('-h     --help           Print this help and exit');
        Writeln('-r KEY --remote=KEY     Start with remote mode KEY= one of J,M,K');
        Writeln('                        (for KEY see: NewQSO shortcut keys)');
        Writeln('-v     --version        Print version and exit');
        Writeln('       --debug=NR       Set debug level to NR');
        Writeln;
        Writeln('Debug level NRs:');
        Writeln('     0  No debug meesages');
        Writeln('     1  All debug messages');
        Writeln('     2  All debug messages + some additional RBNmonitor & DXCluster debugs');
        Writeln('Negative values can be combined (binary bitwise OR)');
        Writeln('    -2  AdifImport & ImportProgress debug messages');
        Writeln('    -4  Wsjtx remote & Worked grids debug messages');
        Writeln('    -8  CW keying & TRXControl debug messages');
        Writeln('   -16  Grayline map RBN debug messages');
        Writeln;
        Exit;
     end;

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
  Application.CreateForm(TfrmCWType, frmCWType);
  Application.CreateForm(TfrmRbnMonitor, frmRbnMonitor);
  Application.CreateForm(TfrmWorkedGrids, frmWorkedGrids);
  Application.CreateForm(TfrmPropDK0WCY, frmPropDK0WCY);
  Application.CreateForm(TfrmReminder, frmReminder);
  Application.CreateForm(TfrmContest, frmContest);
  Application.CreateForm(Tfrmxfldigi, frmxfldigi);
  Application.CreateForm(TdmMembership, dmMembership);
  Application.CreateForm(TdmSatellite, dmSatellite);
  Application.CreateForm(TfrmProgress, frmProgress);

  Splash.Update;
  application.ProcessMessages;
  sleep(800);
  Splash.close;
  Splash.Release;
  Application.Run;
end.

