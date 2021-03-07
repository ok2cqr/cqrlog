Latest cqrlog alpha test binaries can be found from this folder.
This folder holds ready compiled binary files of source "loc_testing" that is the version of cqrlog that I am using myself daily.
They contain all accepted pull requests from official source (that may not be released offically yet) plus some test code that is not pull requested yet (and may not be pull requested ever)

## ABOUT THIS ALPHA TEST VERSION:
 These alpha test binaries also include latest official source updates up to commit:
 
    Commits on Mar 6, 2021 Merge pull request #408 from OH1KH/label_print
 
 To see what are the latest official updates look at <https://github.com/ok2cqr/cqrlog/commits/master>
 To see updates in this alpha version look at <https://github.com/OH1KH/cqrlog/commits/loc_testing>

# WARNING FOR THIS NEW VERSION !!!  READ AND UNDERSTAND THIS!
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
 
LAST UPDATE
  - ver 2.5.2(104)
  - official version with alpha additions (see below) 
  - ver 2.5.2(103)
  - official version with alpha additions (see below) 
  - Help files have additions remember to update also HELP
  - ver 2.5.2(102)
  - official version with alpha additions (see below) 
  - ver 2.5.2(101)
  - official version with alpha additions (see below) 
  - ver 2.5.1(106)
  - official version with alpha additions (see below) 
  - Help files have additions remember to update also HELP
  - ver 2.5.1(105)
  - official version with alpha additions (see below) 
  - Help files have additions remember to update also HELP
  - ver 2.5.1(103)
  - official version with alpha additions (see below)
  - ver 2.5.1(102)
  - official version with alpha additions (see below)
  - ver 2.5.1(101)
  - official version with alpha additions (see below)
  - ver 2.5.0(101)
  - official version with alpha additions (see below)
  
BINARIES:
---------

  - **cqr0.zip  holds binary for  64bit systems compiled for GTK2 widgets from latest official source (without additions) using linux Mint20**
  - **cqr1.zip  holds binary for  32bit systems compiled for GTK2 widgets from latest official source (without additions) using Ubuntu 18 LTS**
  - **cqr2.zip  holds binary for  64bit systems compiled for GTK2 widgets (official release of cqrlog with additions)**
  - **cqr3.zip  holds binary for  32bit systems compiled for GTK2 widgets (official release of cqrlogwith additions, poorly tested)**
  - **cqr4.zip  holds binary for  Arm systems (RPi) compiled for GTK2 widgets (official release of cqrlogwith additions, poorly tested)**
  - **cqr5.zip  holds binary for  64bit systems compiled for QT5 widgets (you may need to install libqt5pas to run this)**
  - **help.tgz  holds latest help files**
  - **newupdate.zip holds the newupdate.sh script for easy update**

**All binaries must be copied over complete, working, official installation. These do not work alone.**
========================================================================================================
     


------------------WARNINGS-----------------
===========================================
   
**This is NOT official release !**

   **ALWAYS !!  FIRST DO BACKUP OF YOUR LOGS AND SETTINGS !!**
   
   If you use script-install (see below) it makes backups for you.
   Otherwise see "manual-install (below).
   
   In some cases it has happen that alpha binary compiled using Fedora linux may not run flawlessly with Ubuntu derivates.
   if you start to get mysterious errors it might be the reason.
   I have now added version that has no special additions from me. It is compiled with Mint20 from up to date official source.
   You could try that or otherwise consider to compile cqrlog either from official or from my alpha source.
   I have written few messages to Cqrlog forum how to make the compile.
   
-----------YOU HAVE BEEN WARNED!------------
============================================


## -------------------SCRIPT-INSTALL--------------------

**There is now new script for update. You need to download only the script and start it.**
**It will do rest of downloads for you and then install updates.**


Use it this way:

Download newupdate.zip from GitHub page.
   - click blue link of newupdate.zip file. New page opens. You see that there is a button "Download" click it.
     Your browser downloads the zip. If it asks where to save, select folder from where you can find the zip.

Open command console. Go to your download directory.

    cd [your download directory path]

Unzip newupdate.zip to find the newupdate.sh script:

    unzip newupdate.zip

Then start newupdate.sh script with command:

    ./newupdate.sh
    
	If you can not start script then check that you can execute newupdate.sh by giving a command:
	    chmod a+x newupdate.sh
	Then try again to start script.

	There has been one case where starting newupdate.sh it complains error at line 5 (arch bracket).
	In that case solution was to start newupdate.sh as:

    bash newupdate.sh

	That (Ubuntu 20) linux obviously did not had bash as default shell.
	
Script checks frist that you have cqrlog installed and that you have some other needed programs.
If they are not found it will stop and tell what you should do before new try.

I have tested this script many times while writing it. How ever it may fail with your setup.

So you USE IT ON YOUR OWN RISK !

Here is a video showing update in use: https://www.youtube.com/watch?v=Jt_D5sICJVo

Other way to update is to do it manually as follows:

## -------------------MANUAL-INSTALL--------------------
  
  Simplest way to backup everything is to copy whole folder with console command
   
     cp -a ~/.config/cqrlog ~/.config/cqrlog_save

   After doing this, if you ever need to restore old settings and logs, just give console commands
   
     rm -rf ~/.config/cqrlog
     cp -a ~/.config/cqrlog_save  ~/.config/cqrlog
   
  
(you need to become root (sudo) using sudo to do following):

#### -------------INSTALL NEW HELP FILES----------------

Your /usr/share should usually contain folder cqrlog, if so, do install help files.

    cd /usr/share/cqrlog
    sudo tar vxf /your/download/folder/help.tgz


#### ------------THEN INSTALL THE CQRLOG ITSELF---------

    cd /tmp
    unzip /your/download/folder/cqr5.zip  (cqr3.zip or cqr2.zip)


Then just copy '/tmp/cqrlog'  over your existing 'cqrlog' (usually in /usr/bin folder)
when first saving the old one to cqrlog_old that you can copy back if new one does not work.
Then check execution rights.

    sudo cp /usr/bin/cqrlog /usr/bin/cqrlog_old
    sudo cp /tmp/cqrlog /usr/bin/
    sudo chmod a+x /usr/bin/cqrlog  

 ## A list what is not included into official cqrlog GitHub source and exist only in Test versions is listed below.
 
RESET/IGNORE ONLINE LOG UPLOAD MARKERS

    Pteferences/Online log has now new two checkboxes to prevent some reloading to online logs:
    Ignore changes caused by QSL sent/received (marked by hand or label printing) 
    Ignore changes caused by QSO edit
    And QSO list/Online log-menu has new selection: Remove all upload markers to flush pending uploads.


QT5 VERSION

If you like to test QT5 version you need to install libqt5pas.
libqt5pas is a library that bridges between Qt5 and your Lazarus application. 
Newer distros have working versions available in their repositories.

Using your distros repository:
   - Fedora, Mageia - sudo dnf install qt5pas<enter>
   - Ubuntu, Debian - sudo apt install libqt5pas1 <enter>

Note that some long term release distributions, ie Ubuntu 18.04 have an incompatible version of libqt5pas 
(even though it appears to have the same version number as later distros!). 
You will see an error message and a crash if your app uses TMemo. 
You should install the downloaded packages mentioned below or build your own new version of the library.

  - When running that version please note if you find clipping or wrong positions at windows.
    Check also how GTK2 version shows up, they are little bit different. GTK may show up ok, but QT5 has
    clipping (usually in that way).    
   
CQ MONITOR USA STATES

  - separate source for this can be found from branch "states"
  - CQ-monitor checbox "USt" that allows USA states to monitored wsjt-CQs
  - when you check it at first time it suggests loading from fcc.gov it should suggest same after 90 days of usage to update data.
   - US callsign=state (fcc_states.tab) file is over 10Mb and ist is loaded to RAM for runtime.
    Seeking a callsingn from there takes some time.

   How the update works? 
   
   You can make it happen again if you delete files
   "EN.dat" and "fcc_states.tab" from folder ~/.config/cqrlog/ctyfiles.
   If you delete just file "fcc_states.tab" you can make only the rebuld part to run again.

   How it works when there are many USA stations on band at every decode?

   Conditions here are so poor that I can hear only few USA stations for every now and then (but lot of europeans)
   There is another runtime list that grows up from decoded callsigns=states. The idea is that there are just
   several stations on band at same time and so seeking from runtimelist first may give faster response times.
   The runtime list is cleared when you close wsjt-remote (and reopen it). 
   So that is the way to find out has it any speed improvement for CQ decodes.

   If you want debug dump start with:

    cqrlog debug=-4

   That gives a bit less debug text. Just CQ-monitor related debugs. Note that value is "minus 4"!

RTTY MODE IS DATA

   - separate source for this can be found from branch "rtty_data"
   - At preferences/Modes you will see a new "DATA" that replaces the old "RTTY". Defaults for that are
    rig cmd:RTTY data mode:RTTY that acts like pervious cqrlogs.

   You can state your own "data mode" and command that is used with rig when that mode is in use.
   They can be different now. The "thing" is that your data mode is now used with DXCluster spots
   like RTTY was used before.
   I have now settings (for IC7300) DATA bandwidth: 0 Hz, Rig cmd:PKTUSB and data mode: FT8
   So I will get DXCluster FT8 spots colored now against my log.

   There is one known problem: 
   When you push "DATA" (former RTTY) button at TRXControl the "Rig cmd" will be sent to your rig.
   That is ok, but when your rig sends back them mode (that is same as "Rig cmd") it is converted
   back to "Data mode" at NeWQSO.
   Imagine you set data mode to SSTV and rig cmd to USB. Sending that to rig is ok, but when rig
   returns mode also all your USB fone qsos will be set as SSTV.
   That's why it only works properly with rigs that have separate data mode to use.

   Same way "preferences/TRXcontrol/Change defaut frequencies" now points to "DATA" instead of "RTTY",
   and you have to set "preferences/bands/frequencies" "DATA" column to correspond your data mode.
   By defaut it points to RTTY frequencies.

LOG OR DATABASE SERVER CHANGE

  - separate source for this can be found from branch "remote_local_db_switch"
  - prevent to kill open log (NewQSO/File/Open or create new log/Delete log)
  - prevent to load settings to open log (NewQSO/File/Open or create new log/Utils/Configuration/Import)
  - log change should work now better (NewQSO/File/Open or create new log/Open)
  - database server change works better, but still have bugs. (NewQSO/File/Open or create new log/save data to local machine/external server)

  
Some cqrlog related videos can be found from  <https://www.youtube.com/channel/UC3yPCVYmfeBzDSwTosOe2fQ>

All kind of reports are welcome. You can send them them to mycallsign at sral dot fi

     
