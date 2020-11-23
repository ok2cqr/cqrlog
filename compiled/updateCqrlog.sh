#/bin/bash
clear
#-----------
function MyOut (){
      echo -e $1
      echo -e $1 >> /tmp/updateCqrlog.txt 
 }
 
# Check downloaded are files in /tmp
#-----------

mydate=$(date +"-"%Y%m%d"-"%H%M%S)
cqr=0
cqrs=0
MyOut	At$mydate
MyOut "==================================================="
MyOut "Expectations:"
MyOut "\t- you have previously installed a cqrlog and tested that it works"
MyOut "\t- cqrlog is NOT running now"
MyOut "\t- you have downloaded cqrX.zip and help.tgz and this script to \x2Ftmp folder"
MyOut "\t  \x20\x28where X is one of numbers: 2,3 or 5\x29"
MyOut "\t- you have selected 'save log data to local machine' at cqrlog start"
MyOut "\t  \x20This is required to get logs backup with other settings"
MyOut "\t  \x20\x28If you use external database server for logs you\x29"
MyOut "\t  \x20\x28must know also how to backup your logs. Then do it!\x29"
MyOut "\t- If you have selected cqr5.zip \x28QT5 version\x29 you have used it before or"
MyOut "\t  \x20you understand that you may need to install qt5pas library manually"
MyOut "\n\t- THIS SCRIPT MAY NOT BE FOOLPROOF AND YOU USE IT ON YOUR OWN RISK !" 
MyOut "\nUpdate is writing log to: \x2Ftmp\x2FupdateCqrlog.txt"
MyOut "==================================================="
MyOut "\n\n\n\nNext: Looking for downloaded files"
MyOut "\nPress ENTER to continue... "
read input
clear
MyOut "==================================================="
MyOut "Looking for downloaded files \n"

if [ -r /tmp/cqr2.zip ] ;then
	let cqr=2
	let cqrs=$cqr
fi
if [ -r /tmp/cqr3.zip ] ;then
        let cqr=3
	let cqrs=$cqrs+4
fi
if [ -r /tmp/cqr5.zip ] ;then
        let cqr=5
	let cqrs=$cqrs+5
fi

if  [[ $cqrs -lt 2 ]] ;then
	MyOut "None of cqrX.zips \x28X= 2,3 or 5\x29 found!"
	MyOut "Fix this and try again!\n"
	exit
fi
if  [[ $cqrs -gt 5 ]] ;then
        MyOut "Download only one cqrX.zip \x28X= 2,3 or 5\x29 to /tmp folder!"
	MyOut "Fix this and try again!\n"
	exit
fi
if [ -r /tmp/help.tgz ] ;then
       	help=1
   else
	MyOut "File help.tgz NOT found !"
	MyOut "Fix this and try again!\n"
	exit
fi

MyOut "Found /tmp/cqr$cqr.zip and /tmp/help.tgz\nOK!\n"
MyOut "==================================================="
MyOut "\n\n\n\nNext: Looking for installed cqrlog."
MyOut "\nPress ENTER to continue... "
read input
clear
MyOut "==================================================="
MyOut "Looking for installed cqrlog.\nBinary file at \x2Fusr\x2Fbin and Folder at \x2Fusr\x2Fshare\n"

if [ -r /usr/bin/cqrlog ] ;then
       	MyOut "Found file \x2Fusr\x2Fbin\x2Fcqrlog\n OK!";
  else
	MyOut "File \x2Fusr\x2Fbin\x2Fcqrlog Not Found !"
	MyOut "If you have working cqrlog it is installed to unknown location!"
	MyOut "Or file may be deleted by previous failed install script."
	MyOut "You have to upgrade manually!";
	exit
fi
if [ -d /usr/share/cqrlog/help ] ;then
       	MyOut "Found folder \x2Fusr\x2Fshare\x2Fcqrlog\n OK!";
  else
	MyOut "Folder \x2Fusr\x2Fshare\x2Fcqrlog Not Found !"
	MyOut "If you have working cqrlog it is installed to unknown location!"
	MyOut "Or file may be deleted by previous failed install script."
	MyOut "You have to upgrade manually!";
	exit
fi
MyOut "==================================================="
MyOut " \n\n\n\n\n"
MyOut "==================================================="
MyOut "Until now we have not touched your filesystem, execpt writing the install log.\nNow this script will write and delete some files."
MyOut "If you are unsure you can stop this script now  pressing Ctrl+C instead of ENTER"
MyOut "==================================================="
MyOut " \n\n\n\nNext: Do backups\n"
MyOut "Press ENTER to continue... "
read input
clear
MyOut "==================================================="
MyOut "Do backups:\n"
MyOut "File:\n   \x2Fusr\x2Fbin\x2Fcqrlog is copied to  \x2Fusr\x2Fbin\x2Fcqrlog$mydate"
MyOut "\nFolder:\n \x2Fusr\x2Fshare\x2Fcqrlog\x2Fhelp is copied to  \x2Fusr\x2Fshare\x2Fcqrlog\x2Fhelp$mydate"
MyOut "\nYour settings and log folder:\n \x7E\x2F.config\x2Fcqrlog is copied to \x7e\x2F.config\x2Fcqrlog$mydate\n"
MyOut "\nSome of next operations need root privileges.\nCommand sudo may now ask password for your username.\n\n"
sudo cp /usr/bin/cqrlog /usr/bin/cqrlog$mydate 
if [ $? -eq 0 ]; then
    MyOut   "Copy of \x2Fusr\x2Fbin\x2Fcqrlog$mydate OK !"
    MyOut  "\nIf you need to restore old cqrlog back give command:\nsudo mv \x2Fusr\x2Fbin\x2Fcqrlog$mydate \x2Fusr\x2Fbin\x2Fcqrlog\n"
else
    MyOut  "Copy FAILED!"
    MyOut  "You have to upgrade manually!";
    exit
fi
MyOut  "------------"
sudo cp -a /usr/share/cqrlog/help /usr/share/cqrlog/help$mydate 
if [ $? -eq 0 ]; then
    MyOut  "Copy of \x2Fusr\x2Fshare\x2Fcqrlog\x2Fhelp$mydate OK!"
    MyOut  "\nIf you need to restore help back give commands:\nsudo rm -rf \x2Fusr\x2Fshare\x2Fcqrlog\x2Fhelp\nsudo mv \x2Fusr\x2Fshare\x2Fcqrlog\x2Fhelp$mydate \x2Fusr\x2Fshare\x2Fcqrlog\x2Fhelp\n"
else
    MyOut  "Copy FAILED!"
    MyOut  "You have to upgrade manually!";
    exit
fi
MyOut  "============================================"
MyOut  "===================WAIT !==================="
MyOut  "============================================"
MyOut  "Copying log and settings. This might take a while if you have large logs\n"
cp -a ~/.config/cqrlog ~/.config/cqrlog$mydate
if [ $? -eq 0 ]; then
    MyOut   "Copy of ~\x2F.config\x2Fcqrlog$mydate OK!"
    MyOut  "\nIf you need to restore your logs and settings give commands:\nsudo rm -rf ~\x2F.config\x2Fcqrlog\nsudo mv ~\x2F.config\x2Fcqrlog$mydate ~\x2F.config\x2Fcqrlog \n"
else
    MyOut  Copy FAILED!
    MyOut  "You have to upgrade manually!";
    exit
fi
MyOut  "Backups are now done OK !"
du -hcs /usr/bin/cqrlo*
du -hcs /usr/share/cqrlog/hel*
du -hcs ~/.config/cqrlo*
MyOut  "\nYou can now compare that backup sizes are same as origins"
MyOut "==================================================="
MyOut "\n\n\n\nNext: Install new file cqrlog"
MyOut "\nPress ENTER to continue... "
read input
clear
MyOut "==================================================="
MyOut "Install new file cqrlog to \x2Fusr\x2Fbin\n"
cd /usr/bin
sudo rm cqrlog
if [ $? -eq 0 ]; then
  MyOut "Removing old cqrlog DONE !"
 else
    MyOut "Remove of old cqrlog FAILED!"
    MyOut "You have to upgrade manually!";
    exit
fi
sudo unzip /tmp/cqr$cqr.zip
if [ $? -eq 0 ]; then
  MyOut "Installing new cqrlog DONE !"
  sudo chmod a+x /usr/bin/cqrlog
 else
    MyOut "Install of new cqrlog FAILED!"
    MyOut "You have to upgrade manually!";
    exit
fi

MyOut "==================================================="
MyOut "\n\n\n\nNext: Install new help "
MyOut "\nPress ENTER to continue... "
read input
clear
MyOut "==================================================="
MyOut "Install new help to \x2Fusr\x2Fshare\x2Fcqrlog\n"
cd /usr/share/cqrlog
sudo rm -rf help
if [ $? -eq 0 ]; then
  MyOut "Removing old help DONE !"
 else
   MyOut "Remove of old help FAILED!"
    MyOut "You have to upgrade manually!";
    exit
fi
sudo tar xf /tmp/help.tgz
if [ $? -eq 0 ]; then
  MyOut "Installing new help DONE !"
  sudo chmod -R a+r help
 else
   MyOut "install of new help FAILED!"
    MyOut "You have to upgrade manually!";
    exit
fi

MyOut "==================================================="
MyOut " \n\n\n\nNext: The end"
MyOut "\nPress ENTER to continue... "
read input
clear
MyOut "==================================================="
MyOut "\n\n\n\n   ALL DONE ! You may now start cqrlog !\n"
MyOut "\n\nIf you want to delete all backups that were made by this script give commands:\n\nrm -rf ~\x2F.config\x2Fcqrlog-20*\nsudo rm -rf \x2Fusr\x2Fshare\x2Fcqrlog\x2Fhelp-20*\nsudo rm \x2Fusr\x2Fbin\x2Fcqrlog-20*\n\n BUT ! Only after you have tested that everything works!\n"
MyOut "You will find all these output texts from log file: \x2Ftmp\x2FupdateCqrlog.txt "
MyOut "==================================================="

