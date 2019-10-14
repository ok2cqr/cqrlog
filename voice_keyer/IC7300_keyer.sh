#!/bin/bash
#
#Voice keyer for Icom rigs with internal voice recorder (address set & tested with IC7300)  OH1KH-2019
#IC7300 has 8 voice memories so 8 function keys of cqrlog can be used
#Cqrlog, when in fone mode, uses CW macro F-keys for calling script at ~/.config/cqrlog/voice_keyer/voice_keyer.sh
#
#
#FOR USING THIS SCRIPT RENAME IT AS ~/.config/cqrlog/voice_keyer/voice_keyer.sh
#
#
#The F-key number is placed as first parameter for script by cqrlog.
#
#~/.config/cqrlog/voice_keyer/voice_keyer.sh F1
#~/.config/cqrlog/voice_keyer/voice_keyer.sh F2
#  etc.
#
#This script reads 1st parameter and sends corresponding raw CI-V command to rig using rigctld's command 'w'
#
#linux netcat (nc) progam must be installed for communication to rigctld via TCP/IP
#echo -n -e [rigctld command] | nc localhost 4532
#
#Script does not use return value that rig sends after getting voice initiate CI-V command.
#8th hex byte cancels (if 0x00) running voice sending or initiates it (0x01 - 0x08)
#
#FE FE FE 94 E0 28 00 00 FD #cancel playback
#FE FE FE 94 E0 28 00 01 FD #send mem1
#FE FE FE 94 E0 28 00 02 FD #send mem2
#         . . .
#FE FE FE 94 E0 28 00 08 FD #send mem8
#
#Command sent via netcat and rigctld
#echo -n -e 'w\\0xFE\\0xFE\\0xFE\\0x94\\0xE0\\0x28\\0x00\\0x01\\0xFD' | nc localhost 4532
#
# script begins here:
M=0
case $1 in
	F1)
		M=1
		;;
	F2)
		M=2
		;;
	F3)
		M=3
		;;
	F4)
		M=4
		;;
	F5)
		M=5
		;;
	F6)
		M=6
		;;
	F7)
		M=7
		;;
	F8)
		M=8
		;;
esac
echo -n -e 'w\\0xFE\\0xFE\\0xFE\\0x94\\0xE0\\0x28\\0x00\\0x0'$M'\\0xFD'| nc localhost 4532
