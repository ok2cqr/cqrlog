#!/bin/bash

#Comment lines are starting with #
#this script requires program 'ncat' (also called 'nc') 
# 'pidof' and player you select (defaut 'mpg123') to be installed.


#You can test this script from command line by typing:

#  voice_keyer.sh F10.mp3  (without typing hash (#) at beginning of line)

#It will then play file F10.mp3 if all is ok.


#the script begins:
#Define your sound player's name below (mpg123, aplay, etc..)
#If you do not get any sound out:
#Yor rig may exist as one sound card of Linux. 
#To get your voice message directed to right sound card consult your player's
#man pages how to select right sound output device and add those parameter(s)
#after your player's name (within those parenthesis).
myplayer="mpg123"

#rigctld PTT commands
rigctldPttCmdON="T 1"
rigctldPttCmdOFF="T 0"

   #if Hamlib/rigctld method does not work with you it might be that you have
   #very latest rigctld and/or you use start parameter '--vfo' with it
   #then put hash (#) in front of above two lines and remove hash (#) from
   #start of next two lines

# rigctldPttCmdON="T currVFO 1" 
# rigctldPttCmdOFF="T currVFO 0"


#Search the sound file that was given as first start parameter with script name
FILE="$1.mp3"
if [ ! -e $FILE ]
 then 
 echo "$FILE Not Found!"
 exit 1
fi

 #search audio your player 
 command -v $myplayer >/dev/null 2>&1 
  if [ $? != 0 ]
   then 
    echo "$myplayer is not installed.  Aborting."
    exit 1
   fi

   #check that we are not already playing something
   pidof -q $myplayer
   if [ $? = 0 ]
      then
       echo "$myplayer is already playing, exit!"
       exit 1
      fi

   echo "PTT on"

   #This puts your rig ptt ON if you have 'cwdaemon' program in use.
   #If you want to use this then remove hash (#) from the beginning of next line

#  echo -e '\033a1' | nc -q 1 -u localhost 6789 &

   #This puts your rig ptt ON using hamlib rigctld (same as Cqrlog uses for rig)
   #if you do not want to use this method put hash (#) to beginning of next line.

   echo -e $rigctldPttCmdON |nc localhost 4532

   #the last words in above line (after 'nc') should be same as your 
   #'Host' and 'Port number' in Cqrlpg/preferences/TRXControl

   echo "Play"
   $myplayer $FILE
   echo "PTT off"
   #This puts your rig ptt OFF if you have 'cwdaemon' program in use.
   #then remove hash (#) from the  beginning of next line

#  echo -e '\033a0' | nc -q 1 -u localhost 6789 &

   #This puts your rig ptt OFF using hamlib rigctld (same as Cqrlog uses for rig)
   #if you do not want to use this method put hash (#) to beginning of next line.

   echo -e $rigctldPttCmdOFF |nc localhost 4532

   #the last words in above line (after 'nc') should be same as your 
   #'Host' and 'Port number' in Cqrlpg/preferences/TRXControl


   #If you want to use VOX put hash in start of all four lines 
   #that controls PTT ON and OFF

#script ends
