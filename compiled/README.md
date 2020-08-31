Latest cqrlog alpha test binaries can be found from this folder.
This folder holds ready compiled binary files of source "loc_testing" that is the version of cqrlog that I am using myself daily.
They contain all accepted pull requests from official source (that may not be released offically yet) plus some test code that is not pull requested yet (and may not be pull requested ever)

## ABOUT THIS ALPHA TEST VERSION:

 These alpha test binaries also include latest official source updates up to commit:
 
   #321
 
 To see what are the latest official updates look at <https://github.com/ok2cqr/cqrlog/commits/master>

 To see updates in this alpha version look at <https://github.com/OH1KH/cqrlog/commits/loc_testing>

LAST UPDATES
  - ver 2.4.0(125)
  - added new commits
  - compiled with Lazarus 2.0.8/fpc3.0.4 instead of Laz2.0.10/fpc3.2.0 that were used with (124) and caused several problems
  - ver 2.4.0(124)
  - check official updates link above.
  - removed database ping that caused unstability. 
  
BINARIES:
---------

  - **cqr5.zip  holds binary for  64bit systems compiled for QT5 widgets (you may need to install libqt5pas )**
  - **cqr3.zip  holds binary for  32bit systems compiled for GTK2 widgets (like official release of cqrlog, poorly tested)**
  - **cqr2.zip  holds binary for  64bit systems compiled for GTK2 widgets (like official release of cqrlog)**
  - **help.tgz  holds latest help files**
  - **updateCqrlog.sh.zip holds the updateCqrlog.sh script that you can see also as plain text file updateCqrlog.sh (zip is easier to download from GitHub)**

**All binaries must be copied over complete, working, official installation. These do not work alone.**
========================================================================================================
     


------------------WARNINGS-----------------
===========================================
   
**This is NOT official release !**

   **ALWAYS !!  FIRST DO BACKUP OF YOUR LOGS AND SETTINGS !!**
   
   If you use script-install (see below) it makes backups for you.
   Otherwise see "manual-install (below).
   
-----------YOU HAVE BEEN WARNED!------------
============================================


## -------------------SCRIPT-INSTALL--------------------
You will find a bash script updateCqrlog.sh from this GitHub folder. 

Script will check that you have downloaded all 3 files to /tmp folder, then it checks that you have cqrlog and cqrlog help in usual places (/usr/bin and /usr/share/cqrlog/).
If all is ok it will make datestamped backups from cqrlog binary, cqrlog help and your logs and settings (~/.config/cqrlog). 
After that it will replace cqrlog and cqrlog help with new files.

Use it this way:

Download cqrX.zip (X= 2 ,3 or 5) of your choice:
   - click blue link of that file. New page opens. You see that there is a button "Download" click it.
     Your browser downloads the zip. If it asks where to save, select folder /tmp
   - Do the same with file help.tgz
   - Do the same with file updateCqrlog.sh.zip

   - If your browser downloaded cqrX.zip and help.tgz without asking a save folder you find them from your download
     folder. You must move them now to /tmp folder.

Now you should have all 3 files (cqrX.zip, help.tgz and updateCqrlog.sh.zip) in /tmp folder.

Open command console. Go to /tmp directory.

    cd /tmp

Unzip updateCqrlog.sh.zip to find the updating script.

    unzip updateCqrlog.sh.zip

Then start updateCqrlog.sh script with command:

    /tmp/updateCqrlog.sh
    
	If you can not start script then check that you can execute updateCqrlog.sh by giving a command:
	    chmod a+x /tmp/updateCqrlog.sh
	Then try again to start script.

Script stops every now and then to let you read what has been done and what to do next. You must press ENTER to continue running. 

I have tested this script many times while writing it. How ever it may fail with your setup.

So you USE IT ON YOUR OWN RISK !

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

 ## What is not included (as pull requests) into official cqrlog GitHub source is listed below.

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

     
