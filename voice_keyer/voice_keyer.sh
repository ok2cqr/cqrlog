#!/bin/bash

FILE="$1.mp3"
if [ -e $FILE ]
then
 echo "Found "$FILE
 if  ! ps aux | grep -q '[m]pg123'
  then
   echo "Found mpg123"
   echo "PTT on"
   echo -e '\033a1' | nc -q 1 -u localhost 6789 &
   echo "Play"
   mpg123 $FILE
   echo "PTT off"
   echo -e '\033a0' | nc -q 1 -u localhost 6789 &
  fi
fi
