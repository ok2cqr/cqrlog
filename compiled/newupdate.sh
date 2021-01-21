#!/bin/bash
mydate=$(date +"-"%Y%m%d"-"%H%M%S)
clear
#-----------
function MyOut (){
      echo -e $1
      echo -e $1 >> /tmp/newupdate.txt 
 }
 
#-----------
function FindCmd (){
if  command -v $1 &> /dev/null
 then 
    MyOut "Found command: $1   OK!"
 else 
    MyOut "Command $1 is needed!"
    MyOut "Please install it from your linux package manager."
    MyOut "Then try again."
    exit
fi
}
#-----------
MyOut "==================================================="
MyOut "This command will update your existing and working Cqrlog."
MyOut "It can not install Cqrlog to PC where it does not exist."
MyOut "For that use your packet manager. After that you can run this update."
MyOut "==================================================="
MyOut "Looking for installed cqrlog."

if [ -r /usr/bin/cqrlog ] ;then
        MyOut "Found file \x2Fusr\x2Fbin\x2Fcqrlog   OK!";
  else
        MyOut "File \x2Fusr\x2Fbin\x2Fcqrlog Not Found !"
        MyOut "If you have working cqrlog it is installed to unknown location!"
        MyOut "Or file may be deleted by previous failed install script."
        MyOut "You have to upgrade manually!";
        exit
fi
if [ -d /usr/share/cqrlog/help ] ;then
        MyOut "Found folder \x2Fusr\x2Fshare\x2Fcqrlog   OK!";
  else
        MyOut "Folder \x2Fusr\x2Fshare\x2Fcqrlog Not Found !"
        MyOut "If you have working cqrlog it is installed to unknown location!"
        MyOut "Or file may be deleted by previous failed install script."
        MyOut "You have to upgrade manually!";
        exit
fi
MyOut "==================================================="
FindCmd "wget"
FindCmd "unzip"
FindCmd "sudo"
MyOut "==================================================="
arc=$((hostnamectl | grep Arc | tr -d " ") 2>&1)
cd /tmp
rm -f cqr*.zip
rm -f help.tgz
MyOut "Cleanup for old downloads in /tmp directory"
MyOut "==================================================="
MyOut "Your linux "$arc
MyOut "==================================================="
MyOut "Select Cqrlog version you want to use for update:"
options=(
"64bit Cqrlog for x86_64 with Gtk2 widgets (this is the most commonly used version)"
"64bit Cqrlog for x86_64 with QT5 widgets (you need libqt5pas installed to run this)"
"32bit Cqrlog for x86 with Gtk2 widgets (for old PCs)"
"Quit")
select opt in "${options[@]}"
do
    case $opt in
        "64bit Cqrlog for x86_64 with Gtk2 widgets (this is the most commonly used version)")
            MyOut "Downloading Cqrlog binary file"
            wget -q --show-progress https://github.com/OH1KH/cqrlog/raw/loc_testing/compiled/cqr2.zip
            MyOut "Downloading Cqrlog Help files"
            wget -q --show-progress https://github.com/OH1KH/cqrlog/raw/loc_testing/compiled/help.tgz
            cqr=2
            break
            ;;
        "64bit Cqrlog for x86_64 with QT5 widgets (you need libqt5pas installed to run this)")
            MyOut "Downloading Cqrlog binary file"
            wget -q --show-progress https://github.com/OH1KH/cqrlog/raw/loc_testing/compiled/cqr5.zip
            MyOut "Downloading Cqrlog Help files"
            wget -q --show-progress https://github.com/OH1KH/cqrlog/raw/loc_testing/compiled/help.tgz
            cqr=5
            break
            ;;
        "32bit Cqrlog for x86 with Gtk2 widgets (for old PCs)")
            MyOut "Downloading Cqrlog binary file"
            wget -q --show-progress https://github.com/OH1KH/cqrlog/raw/loc_testing/compiled/cqr3.zip
            MyOut "Downloading Cqrlog Help files"
            wget -q --show-progress https://github.com/OH1KH/cqrlog/raw/loc_testing/compiled/help.tgz
            cqr=3
            break
            ;;
        "Quit")
            exit
            break
            ;;
        *) echo "invalid option $REPLY";;
    
    esac
done


MyOut "==================================================="
MyOut "Until now we have not touched your filesystem, execpt downloading install files."
MyOut "Now this script will write and delete some files."
MyOut "If you are unsure you can stop this script now  pressing Ctrl+C instead of ENTER"
MyOut "Press ENTER to continue... "
read input
MyOut "==================================================="
MyOut "Doing backups:\n"
MyOut "File: \x2Fusr\x2Fbin\x2Fcqrlog is copied to  \x2Fusr\x2Fbin\x2Fcqrlog$mydate"
MyOut "Folder: \x2Fusr\x2Fshare\x2Fcqrlog\x2Fhelp is copied to  \x2Fusr\x2Fshare\x2Fcqrlog\x2Fhelp$mydate"
MyOut "Your settings and log folder:\n \x7E\x2F.config\x2Fcqrlog is copied to \x7e\x2F.config\x2Fcqrlog$mydate\n"
MyOut "Some of next operations need root privileges.\nCommand sudo may now ask password for your username.\n"
sudo cp /usr/bin/cqrlog /usr/bin/cqrlog$mydate 
if [ $? -eq 0 ]; then
    MyOut "Copy of \x2Fusr\x2Fbin\x2Fcqrlog$mydate OK !"
    MyOut "If you need to restore old cqrlog back give command:"
    MyOut "\x20\x20 sudo mv \x2Fusr\x2Fbin\x2Fcqrlog$mydate \x2Fusr\x2Fbin\x2Fcqrlog"
else
    MyOut  "Copy FAILED!"
    MyOut  "You have to upgrade manually!";
    exit
fi
MyOut "==================================================="
sudo cp -a /usr/share/cqrlog/help /usr/share/cqrlog/help$mydate 
if [ $? -eq 0 ]; then
    MyOut "Copy of \x2Fusr\x2Fshare\x2Fcqrlog\x2Fhelp$mydate OK!"
    MyOut "If you need to restore old cqrlog back give command:"
    MyOut "\x20\x20 sudo mv \x2Fusr\x2Fbin\x2Fcqrlog$mydate \x2Fusr\x2Fbin\x2Fcqrlog"
else
    MyOut  "Copy FAILED!"
    MyOut  "You have to upgrade manually!";
    exit
fi
MyOut "==================================================="
sudo cp -a /usr/share/cqrlog/help /usr/share/cqrlog/help$mydate 
if [ $? -eq 0 ]; then
    MyOut  "Copy of \x2Fusr\x2Fshare\x2Fcqrlog\x2Fhelp$mydate OK!"
    MyOut  "If you need to restore help back give commands:"
    MyOut  "\x20\x20 sudo rm -rf \x2Fusr\x2Fshare\x2Fcqrlog\x2Fhelp"
    MyOut  "\x20\x20 sudo mv \x2Fusr\x2Fshare\x2Fcqrlog\x2Fhelp$mydate \x2Fusr\x2Fshare\x2Fcqrlog\x2Fhelp"
else
    MyOut  "Copy FAILED!"
    MyOut  "You have to upgrade manually!";
    exit
fi
MyOut  "========="
MyOut  "= WAIT! ="
MyOut  "========="
MyOut  "Copying log and settings. This might take a while if you have large logs"
cp -a ~/.config/cqrlog ~/.config/cqrlog$mydate
if [ $? -eq 0 ]; then
    MyOut   "Copy of ~\x2F.config\x2Fcqrlog$mydate OK!"
    MyOut  "If you need to restore your logs and settings give commands:"
    MyOut  "\x20\x20 sudo rm -rf ~\x2F.config\x2Fcqrlog\nsudo mv ~\x2F.config\x2Fcqrlog$mydate ~\x2F.config\x2Fcqrlog"
else
    MyOut  Copy FAILED!
    MyOut  "You have to upgrade manually!";
    exit
fi    
MyOut "==================================================="
MyOut  "Backups are now done OK !"
du -hcs /usr/bin/cqrlo*
du -hcs /usr/share/cqrlog/hel*
du -hcs ~/.config/cqrlo*
MyOut  "You can now compare that backup sizes are same as origins"
MyOut "Press ENTER to continue... "
read input
MyOut "==================================================="
MyOut "Install new  cqrlog to \x2Fusr\x2Fbin\n"
sudo unzip  -o /tmp/cqr$cqr.zip -d /usr/bin
if [ $? -eq 0 ]; then
  MyOut "Installing new cqrlog DONE !"
  sudo chmod a+x /usr/bin/cqrlog
 else
    MyOut "Install of new cqrlog FAILED!"
    MyOut "You have to upgrade manually!";
    exit
fi
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
cd /tmp

MyOut "==================================================="
MyOut "   ALL DONE ! You may now start cqrlog !\n"
MyOut "\nIf you want to delete all backups that were made by this script give commands:"
MyOut "\x20\x20 rm -rf ~\x2F.config\x2Fcqrlog-20*"
MyOut "\x20\x20 sudo rm -rf \x2Fusr\x2Fshare\x2Fcqrlog\x2Fhelp-20*"
MyOut "\x20\x20 sudo rm \x2Fusr\x2Fbin\x2Fcqrlog-20*"
MyOut "\n BUT ! Only after you have tested that everything works!\n"
MyOut "Install log is in file /tmp/newupdate.txt"
