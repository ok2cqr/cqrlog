#!/bin/bash
if ! ps aux | grep -q '[m]pg123'
then
  rs232 -d /dev/ttyS0 --dtr --rts
  mpg123 ~/.config/cqrlog/voice_keyer/$1.mp3
  rs232 -d /dev/ttyS0 --dtr
fi
