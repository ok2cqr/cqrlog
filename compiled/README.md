
 #### NOTE: Upgrading to 2.6.0.(115) ,or higer, will change database table "cqrlog_common" to version 6.
 If you return back to previous cqrlog version you need to restore the database.
( if you used newupdate.sh it is to copy backup foder  ~/.config/cqrlog-YYYYMMDD-HHMMSS to name ~/.config/cqrlog )
 
 #### NOTE: For now on alpha test binaries beginning from 2.6.0.(107) are compiled using system that has GLIBC version 2.35.
If you can not start Cqrlog after update check your GLIBC version with command console: ***ldd --version***
Update GLIBC if it is below 2.3.5.
If you do not want to do that you can compile this source (see 1 folder up) with your current OS version and get it running.
Note that the source version is usually one step higher than ready compiled versions.
 
 #### NOTE: At the moment there is no new official version source release. That is why Alpha (119) is ***VERY far ahead*** from official.
From [Changelog](https://htmlpreview.github.io/?https://github.com/OH1KH/cqrlog/blob/loc_testing/src/changelog.html) 
you can see all changes. It appears also at first start of (119), and can be accessed via "Help" when Cqrlog is running.


Latest cqrlog alpha test binaries can be found from this folder.
This folder holds ready compiled binary files of source "loc_testing" that is the version of cqrlog that I am using myself daily.
They contain all accepted pull requests from official source (that may not be released offically yet) plus some test code that is not pull requested yet (and may not be pull requested ever)

## ABOUT THESE BINARIES:
 These binaries (cqr0,cqr1,cqr4 zips) include latest official source having updates up to commit:

    Commits on Jul 24, 2022 Merge pull request #529 from OH1KH/direct_load_filter 

 Binaries (cqr2,cqr3,cqr5,cqr6 zips) include latest official source ***WITH alpha additions and Pull Requests that have not yet applied***.
 
 To see what are the latest official updates look at <https://github.com/ok2cqr/cqrlog/commits/master>
 To see updates in this alpha version look at <https://github.com/OH1KH/cqrlog/commits/loc_testing>

 To read about UTF8 special charcters in logs read file UTF8_logs.md
 
 
BINARIES:
---------
  - **cqr0.zip  holds binary for  64bit systems compiled for GTK2 widgets (official release )**
  - **cqr1.zip  holds binary for  32bit systems compiled for GTK2 widgets (official release )**
  - **cqr2.zip  holds binary for  64bit systems compiled for GTK2 widgets (official release of cqrlog with alpha additions)**
  - **cqr3.zip  holds binary for  32bit systems compiled for GTK2 widgets (official release of cqrlog with alpha additions)**
  - **cqr4.zip  holds binary for  64bit Arm (Rpi4) compiled for GTK2 widgets (official release )**
  - **cqr5.zip  holds binary for  64bit systems compiled for QT5 widgets (official release of cqrlog with alpha additions,you may need to install libqt5pas to run this)**
  - **cqr6.zip  holds binary for  64bit Arm (Rpi4) compiled for GTK2 widgets (official release of cqrlog with alpha additions)**
  - **help.tgz  holds latest help files**
  - **newupdate.zip holds the newupdate.sh script for easy update**

**All binaries must be copied over complete, working, official installation. These do not work alone.**
========================================================================================================
     


------------------WARNINGS-----------------
===========================================
   
**This is NOT official release !**

   ***ALWAYS !!  FIRST DO BACKUP OF YOUR LOGS AND SETTINGS !!***
   
   If you use script-install (see below) it makes backups for you.
   Otherwise see "manual-install (below).
   
   In some cases it has happen that alpha binary compiled using Fedora linux may not run flawlessly with Ubuntu derivates.
   if you start to get mysterious errors it might be the reason.
   I have now added version that has no special additions from me. It is compiled with Mint20 from up to date official source.
   You could try that or otherwise consider to compile cqrlog either from official or from my alpha source.
   I have written few messages to Cqrlog forum how to make the compile.
   
-----------YOU HAVE BEEN WARNED!------------
============================================


### -------------------SCRIPT-INSTALL--------------------

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

Here is a video showing update in use https://www.youtube.com/watch?v=H_QLQhQyFVg&t

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
    

## -------------------MANUAL-COMPILE--------------------


Once you have a running Cqrlog installed you can do update also by making the compile from source code.
For getting source code there are two ways:

clone my whole Git reporsitory using command terminal:

	git clone https://github.com/OH1KH/cqrlog.git

This will make folder "cqrlog" to your home directory if cloning is issued on that directory.
After that, to get into Alpha branch, give command:

	git checkout loc_testing

Now you have the Alpha source in hand.
Good side with "git clone" is that on next time you like to upgrade you just open command console and change directory to "cqrlog" ("cd cqrlog") and issue command "git pull" and new updates are applied and you are ready to compile and install again.

Other way is to download just the current version's source with web browser from https://github.com/OH1KH/cqrlog/tree/loc_testing At that page you see green button "Code". By pressing that you find "Download.zip" that allows to download the source code as zip file.
Once downloaded and extracted you are at same point as after "git checkout loc_testing" above.
How ever you can not do new uptates later with "git pull". You have to download the zip file again.

Once you have source you need tools to compile. Using command termnal install them.

	sudo apt install lazarus

That will install FreePascal compiler and Lazarus GUI. Issuing that line results a long list of dependencies to install, just say Y (yes) to install them all.

If your Lazarus is very old from package you find latest version from https://www.lazarus-ide.org It is always recommended to use latest version as package versions can be very old, as seen with Cqrlog packages. At the moment lazarus-ide version is 2.2.6

When lazarus-ide is installed you need to change to source directory, either git cloned or extracted from zip. ("cd cqrlog")
After that start the compile process, issue:

	make

When compile has finished install the new Cqrlog with command

	sudo make install

That is all!



With some OS "make" result errors. Then usually using the lazarus-ide works.
Start lazarus-ide typing that to command terminal, or start from startup menu icon "lazarus".
At first start it goes through some settings. If all Tabs show OK you are ready to continue.

Lazarus starts first to empty form. Use top menu "Project/Open Project" and navigate to your "cqrlog" source folder. There you see subfolder "src". Navigate to that folder and you see "cqrlog.lpi".  Open that.

Once opened select top menu "View/Messages" to see compiler messages. Then select top menu "Run/Compile".
Wait and finally you should see a green line on Messages window. It means that compile is over.

You find new cqrlog from folder "src" as file "cqrlog"
You can now try command terminal:

	cd cqrlog  (this is the source root folder, as before)
	sudo make install

If succeeded you have new version with new help installed. If not, you can just copy file "cqrlog" from folder "src" to "/usr/bin"
There already exists a file named "cqrlog" (that is the old version) you can first copy it somewhere, if you like, before
coping over the new one.
You need "sudo" for this copy.

	sudo cp src/cqrlog /usr/bin




### A list what is not included into official cqrlog GitHub source and exist only in Alpha test versions can be found from [Changelog](https://htmlpreview.github.io/?https://github.com/OH1KH/cqrlog/blob/loc_testing/src/changelog.html) 
 
### Some Cqrlog related videos can be found from  <https://www.youtube.com/channel/UC3yPCVYmfeBzDSwTosOe2fQ>

All kind of reports are welcome. You can find my address from callbooks.

     
