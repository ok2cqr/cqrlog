#!/bin/bash

# Simple recipe to generate an appimage for this app
#
# Requirements:
#   * VERSION as an ENV var, if not detected will use the values declared in
#     /src/uVersion.pas
#   * This must be run after a successfully docker build, and need to set the
#     APP var below to the path of the executable.
#   * Must be run on a Linux version as old as the far distro you need to
#     support, tested successfully on Ubuntu 20.04 LTS &  23.10
#
# On any troubles invoke stdevPavelmc in github

# Tweak this please: this is the path of the cqrlog executable after a docker
# build in /usr/local/cqrlog-alpha
ROOTFOLDER=/usr/local/cqrlog-alpha
APP="${ROOTFOLDER}/usr/bin/cqrlog"

# No need to tweak below unless you move files on the actual project
DESKTOP="${ROOTFOLDER}/usr/share/applications/cqrlog.desktop"
ICON="${ROOTFOLDER}/usr/share/pixmaps/cqrlog/cqrlog.png"

# clean log space
echo "==================================================================="
echo "                Starting to build the AppImage..."
echo "==================================================================="
echo ""

# check if version is set, if not scrape it from the code
if [ "$VERSION" == "" ] ; then
    echo "WARNING: VERSION is not set, will be scraped from the code"
    VFILE=./src/uVersion.pas
    VER_STRING=$(grep " cVersionBase " ${VFILE} | cut -d "=" -f 2 | cut -d "'" -f 2)
    VER=$(echo $VER_STRING | cut -d "(" -f 1 | tr -d " " | tr -d "_")
    VER_NUMBER=$(echo $VER_STRING | cut -d "(" -f 2 | cut -d ")" -f 1)
    export VERSION="${VER}_(${VER_NUMBER})"
fi

# version notice
echo "You are building CQRLOG version: $VERSION"
echo ""

# basic tests
if [ ! -f "$APP" ] ; then
    echo "Error: the app file is no in the path we need it, update the APP var on this script"
    echo "APP=$APP"
    exit 1
fi

if [ ! -f "$DESKTOP" ] ; then
    echo "Error: can't find the desktop file, please update the DESKTOP var on the scriot"
    echo "DESKTOP=$DESKTOP"
    exit 1
fi

if [ ! -f "$ICON" ] ; then
    echo "Error: can't find the default icon, please update the ICON var in the script"
    echo "ICON=$ICON"
    exit 1
fi

# prepare the ground
rm -rdf AppDir 2>/dev/null
rm -rdf CQRLOG-*.AppImage 2>/dev/null

# download & set all needed tools
wget -c -nv "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
wget -c -nv "https://github.com/linuxdeploy/linuxdeploy-plugin-appimage/releases/download/continuous/linuxdeploy-plugin-appimage-x86_64.AppImage"
chmod a+x *.AppImage

# notice
echo "Starting the build..." 

# Create the AppDir & copy some utils we need
mkdir -p ./AppDir/usr/share/
cp -r ${ROOTFOLDER}/usr/share/cqrlog ./AppDir/usr/share/

# build
./linuxdeploy-x86_64.AppImage -e "$APP" -d "$DESKTOP" -i "$ICON" --output appimage --appdir=./AppDir
RESULT=$?

# check build success
if [ $RESULT -ne 0 ] ; then
    # warning something gone wrong
    echo ""
    echo "ERROR: Aborting as something gone wrong, please check the logs"
    exit 1
else
    # success
    echo ""
    echo "Success build, check your file:"
    ls -lh CQRLOG-*.AppImage
fi
