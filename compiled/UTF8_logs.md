#  READ AND UNDERSTAND THIS!
 From version 2.5.2(102) on *and also official version compiled from source after 2021-02-15*
 Database opening has fixed so that special charcters like ÜéÄ etc. work properly with latest Freepascal version.
 This means that your earlier made loggings that have special charcters in qth, name, remarks etc.
 will show up as garbage. While your new loggings will show special charcters fine.
 
 If you like them all show out ok you have to do full adif export/import from your log(s)
 *before you upgrade cqrlog*.  Do it this way:
 1) Open cqrlog that is not updated yet.
 2) When in "Database Connection" window select your log to be exported.
    (if your cqrlog opens directly to NewQSO select File/Open or create new log 
    to get "Database Connection" window. There uncheck "Open recent log after
    program start" and close cqrlog. Open cqrlog again and you are in "Database Connection" window )
 3) press "Utils" select "configuration/export" and give filename for example. "log"
 4) When done that open log and then open QSO list and /File/Export/Adif give filename
    and then check all checkboxes to make full ADIF export.
 5) Close cqrlog and make cqrlog update to new version
 6) Open new cqrlog and your log and confirm that special charcters are garbage. 
 7) Close cqrlog. Open it again to get "Database Connection" window 
 8) Press button "new log" Give log number and name. See that new log gets selected. Not open it yet.
 9) Press "utils" select "configuration/import" and find your newly created file example "log.ini"
 10) press on and after succesfull import open that log.
 11) Open QSO list File/import/ADIF and find and load your newly created full adif export file.
 12) Once loaded confirm that you can again see special characters properly and also new qso entries
     will have them properly.
     
## Do not try to be smart and try invent a shortcut for this 12 line guide
  
 Update scirpt will do backups from old /usr/bin/cqrlog programs, so
 do not worry if you missed this and regret. Look at /usr/bin to find old cqrlog backups.
 copy one of them to name /usr/bin/cqrlog (you need sudo) and you can start guide above.
