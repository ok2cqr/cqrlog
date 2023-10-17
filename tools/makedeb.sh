#!/bin/bash

# Fail early and fast
set -o pipefail

# Simple recipe to create a .deb and .deb-src files [for debug and testing, not final]
#
# Requirements:
#   * VERSION as an ENV var, if not detected will use the values declared in
#     /src/uVersion.pas
#
# If no parameter passed it's asumed to build as GTK2, if passed the parameter
# will be set as part of the name, for example QT5/QT6/GTK3, etc
#
# On any troubles invoke stdevPavelmc in github or @pavelmc on Telegram

### variables
# check if version is set, if not scrape it from the code
VFILE=./src/uVersion.pas
VER_STRING=$(grep " cVersionBase " ${VFILE} | cut -d "=" -f 2 | cut -d "'" -f 2)
VERSION=$(echo $VER_STRING | cut -d "(" -f 1 | tr -d " " | tr -d "_")
echo "You are building CQRLOG version: $VERSION"

FINAL=$(pwd)
WDIR=$(mktemp -d)
APPNAME="cqrlog_$VERSION"
APPDIR="$WDIR/$APPNAME"

# Make and clean
mkdir -p $APPDIR
cp -r ./* "$APPDIR/"

# clean non-needed archives
cd $APPDIR/
make clean
rm -rdf AppDir 2>/dev/null
rm -rdf docker-build 2>/dev/null
rm *.adi* 2>/dev/null
rm *.AppImage

# create the orig gzip
cd $WDIR
tar -cvf $APPNAME.orig.tar \
    --exclude='debian' \
    --exclude='.git' \
    $APPNAME
gzip -v9 $APPNAME.orig.tar

# create the deb
cd $APPDIR
debuild -us -uc

# if success move to final
cd $WDIR
if [ "$(ls *.deb)" ] ; then
    ls -lh
    mv -f *.deb $FINAL
    echo "Build is a success"
else
    echo "Build failed, no .deb file present"
fi
