#!/bin/bash

# A unified script to get the version of the project from the src/uVersion.pas file
#
# If called with no arguments it will out the version, like 2.6.0
# If called with an argument it will out that compilation, like 119
#
# Thiss script must be called from the root of the project
#
# On any troubles invoke stdevPavelmc in github or @pavelmc on Telegram

# variables
VERSION=""
COMPILATION=""
VFILE=src/uVersion.pas

# process
VERSION=$(grep " cVersionBase " $VFILE | awk -F"'" '{print $2}' | awk -F"_" '{print $1}')
COMPILATION=$(grep " cVersionBase " $VFILE | awk -F"'" '{print $2}' | awk -F"_" '{print $2}'  | tr -d "(" | tr -d ")")

# output
if [ -z "$1" ] ; then
    echo $VERSION
else
    echo $COMPILATION
fi
