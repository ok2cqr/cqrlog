#!/bin/bash
if ! ps aux | grep -q '[m]pg123'
then
  echo -e '\033a1' | nc -q 1 -u localhost 6789 &
  mpg123 ~/.config/cqrlog/voice_keyer/$1.mp3
  echo -e '\033a0' | nc -q 1 -u localhost 6789 &
fi
