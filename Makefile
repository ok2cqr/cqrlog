LAZBUILD ?= $(or $(shell command -v lazbuild 2>/dev/null),$(wildcard $(HOME)/fpcupdeluxe/lazarus/lazbuild),lazbuild)
ST=strip
# Set default path header for installation. Can be changed by
#  environment variable or CLI
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  DESTDIR  = $(HOME)/cqrlog
  WS      ?= cocoa
else
  DESTDIR  = /usr
  WS      ?= gtk2
endif
#
datadir  = $(DESTDIR)/share/cqrlog
bindir   = $(DESTDIR)/bin
sharedir = $(DESTDIR)/share
tmpdir   = /tmp
PWD = $(shell pwd)

.DEFAULT_GOAL := cqrlog

.PHONY : help dependencies hamlib clean install deb deb_src debug \
         appimage appimage-qt5 docker-image docker docker-build docker-install \
         docker-appimage docker-appimage-qt5 docker-deb docker-deb-src \
         install_macos dmg

cqrlog: src/cqrlog.lpi
	$(LAZBUILD) --ws=$(WS) src/cqrlog.lpi
	$(ST) src/cqrlog
	gzip tools/cqrlog.1 -c > tools/cqrlog.1.gz

clean:
	rm -f -v src/*.o src/*.ppu src/*.bak src/lnet/lib/*.ppu src/lnet/lib/*.o src/lnet/lib/*.bak src/cqrlog src/cqrlog.compiled src/ipc/*.o src/ipc/*.ppu src/cqrlog.or
	rm -f -v src/*.lrs src/*.ps src/*.lrt src/*.rsh  src/*.rst src/*.a src/synapse/*.a src/synapse/*.o src/synapse/*.ppu
	rm -f -v src/mysql/*.ppu src/mysq/*.bak src/mysql/*.o
	rm -f -v tools/cqrlog.1.gz
	rm -rf src/backup
	rm -f -v src/richmemo/*.o src/richmemo/*.ppu src/richmemo/gtk2/*.ppu src/richmemo/gtk2/*.o
	rm -f -v tools/adif_hash_generator tools/adif_hash_generator.lpi tools/adif_hash_generator.lps
	rm -rf $(tmpdir)/.lazarus

install:
	install -d -v         $(bindir)
	install -d -v         $(datadir)
	install -d -v         $(datadir)/ctyfiles
	install -d -v         $(datadir)/help
	install -d -v         $(datadir)/help/img
	install -d -v         $(datadir)/members
	install -d -v         $(datadir)/xplanet
	install -d -v         $(datadir)/voice_keyer
	install -d -v         $(datadir)/zipcodes
	install -d -v         $(datadir)/images
#	install -d -v         $(datadir)/images/icon/32x32
#	install -d -v         $(datadir)/images/icon/48x48
#	install -d -v         $(datadir)/images/icon/64x64
#	install -d -v         $(datadir)/images/icon/128x128
#	install -d -v         $(datadir)/images/icon/256x256
#	install -d -v         $(sharedir)/pixmaps
	install -d -v         $(sharedir)/icons
	install -d -v         $(sharedir)/icons/hicolor/32x32/apps
	install -d -v         $(sharedir)/icons/hicolor/48x48/apps
	install -d -v         $(sharedir)/icons/hicolor/64x64/apps
	install -d -v         $(sharedir)/icons/hicolor/128x128/apps
	install -d -v         $(sharedir)/icons/hicolor/256x256/apps
	install -d -v         $(sharedir)/applications
	install -d -v         $(sharedir)/metainfo
	install -d -v         $(sharedir)/man/man1
	install    -v -m 0755 src/cqrlog $(bindir)
	install    -v -m 0755 tools/cqrlog-apparmor-fix $(datadir)/cqrlog-apparmor-fix
	install    -v -m 0644 ctyfiles/* $(datadir)/ctyfiles/
	install    -v -m 0644 help/img/* $(datadir)/help/img/
	install    -v -m 0644 help/*.*   $(datadir)/help/
	install    -v -m 0644 members/*  $(datadir)/members/
	install    -v -m 0644 xplanet/*  $(datadir)/xplanet/
	install    -v -m 0755 voice_keyer/voice_keyer.sh  $(datadir)/voice_keyer/voice_keyer.sh
	install    -v -m 0644 voice_keyer/README $(datadir)/voice_keyer/README
	install    -v -m 0644 voice_keyer/F10.mp3 $(datadir)/voice_keyer/F10.mp3
	install    -v -m 0644 zipcodes/* $(datadir)/zipcodes/
#	install    -v -m 0644 images/*   $(datadir)/images/
	cp -v -R images/* $(datadir)/images/
#	install    -v -m 0644 images/icon/32x32/*   $(datadir)/images/icon/32x32/
#	install    -v -m 0644 images/icon/48x48/*   $(datadir)/images/icon/48x48/
#	install    -v -m 0644 images/icon/64x64/*   $(datadir)/images/icon/64x64/
#	install    -v -m 0644 images/icon/128x128/*   $(datadir)/images/icon/128x128/
#	install    -v -m 0644 images/icon/256x256/*   $(datadir)/images/icon/256x256/
	install    -v -m 0644 tools/cqrlog.desktop $(sharedir)/applications/cqrlog.desktop
	install    -v -m 0644 tools/com.cqrlog.cqrlog.appdata.xml $(sharedir)/metainfo/com.cqrlog.cqrlog.appdata.xml
#	install    -v -m 0644 images/icon/32x32/cqrlog.png $(sharedir)/pixmaps/cqrlog.png
	install    -v -m 0644 images/icon/32x32/cqrlog.png $(sharedir)/icons/hicolor/32x32/apps/cqrlog.png
	install    -v -m 0644 images/icon/48x48/cqrlog.png $(sharedir)/icons/hicolor/48x48/apps/cqrlog.png
	install    -v -m 0644 images/icon/64x64/cqrlog.png $(sharedir)/icons/hicolor/64x64/apps/cqrlog.png
	install    -v -m 0644 images/icon/128x128/cqrlog.png $(sharedir)/icons/hicolor/128x128/apps/cqrlog.png
	install    -v -m 0644 images/icon/256x256/cqrlog.png $(sharedir)/icons/hicolor/256x256/apps/cqrlog.png
	install    -v -m 0644 src/changelog.html $(datadir)/changelog.html
	install    -v -m 0644 tools/cqrlog.1.gz $(sharedir)/man/man1/cqrlog.1.gz
deb: dependencies ## Build a deb package (Linux, via tools/makedeb.sh)
	./tools/makedeb.sh
deb_src: ## Build a deb package with source (Linux)
	dpkg-buildpackage -rfakeroot -i -I -S
debug:
	$(LAZBUILD) --ws=gtk2 --pcp=$(tmpdir)/.lazarus src/cqrlog.lpi
	gzip tools/cqrlog.1 -c > tools/cqrlog.1.gz

cqrlog_qt5: src/cqrlog.lpi
	$(LAZBUILD) --ws=qt5 --pcp=$(tmpdir)/.lazarus src/cqrlog.lpi
	$(ST) src/cqrlog
	gzip tools/cqrlog.1 -c > tools/cqrlog.1.gz

cqrlog_qt5_debug: src/cqrlog.lpi
	$(LAZBUILD) --ws=qt5 --pcp=$(tmpdir)/.lazarus src/cqrlog.lpi
	gzip tools/cqrlog.1 -c > tools/cqrlog.1.gz

# macOS .app bundle
APPBUNDLE   = $(DESTDIR)/CQRLOG.app
APPCONTENTS = $(APPBUNDLE)/Contents
APPMACOSDIR = $(APPCONTENTS)/MacOS
APPFWDIR    = $(APPCONTENTS)/Frameworks
APPRESDIR   = $(APPCONTENTS)/Resources
APPDATADIR  = $(APPCONTENTS)/share/cqrlog
BREW_PREFIX = $(or $(shell brew --prefix 2>/dev/null),/opt/homebrew)

install_macos:
	@echo "Creating macOS application bundle..."
	install -d $(APPMACOSDIR)
	install -d $(APPRESDIR)
	install -d $(APPDATADIR)/ctyfiles
	install -d $(APPDATADIR)/help/img
	install -d $(APPDATADIR)/members
	install -d $(APPDATADIR)/xplanet
	install -d $(APPDATADIR)/voice_keyer
	install -d $(APPDATADIR)/zipcodes
	install -d $(APPDATADIR)/images
	install -m 0755 src/cqrlog $(APPMACOSDIR)/cqrlog
	printf '#!/bin/bash\nDIR="$$(cd "$$(dirname "$$0")" && pwd)"\nexec "$$DIR/cqrlog" "$$@"\n' > $(APPMACOSDIR)/cqrlog-launcher
	chmod 0755 $(APPMACOSDIR)/cqrlog-launcher
	install -m 0644 ctyfiles/* $(APPDATADIR)/ctyfiles/
	install -m 0644 help/img/* $(APPDATADIR)/help/img/
	install -m 0644 help/*.*   $(APPDATADIR)/help/
	install -m 0644 members/*  $(APPDATADIR)/members/
	install -m 0644 xplanet/*  $(APPDATADIR)/xplanet/
	install -m 0755 voice_keyer/voice_keyer.sh $(APPDATADIR)/voice_keyer/voice_keyer.sh
	install -m 0644 voice_keyer/README $(APPDATADIR)/voice_keyer/README
	install -m 0644 voice_keyer/F10.mp3 $(APPDATADIR)/voice_keyer/F10.mp3
	install -m 0644 zipcodes/* $(APPDATADIR)/zipcodes/
	cp -R images/* $(APPDATADIR)/images/
	install -m 0644 src/changelog.html $(APPDATADIR)/changelog.html
	@# Generate .icns icon from PNGs
	rm -rf $(tmpdir)/cqrlog-icon.iconset
	mkdir -p $(tmpdir)/cqrlog-icon.iconset
	sips -z 16 16 images/icon/32x32/cqrlog.png --out $(tmpdir)/cqrlog-icon.iconset/icon_16x16.png > /dev/null 2>&1
	cp images/icon/32x32/cqrlog.png $(tmpdir)/cqrlog-icon.iconset/icon_16x16@2x.png
	cp images/icon/32x32/cqrlog.png $(tmpdir)/cqrlog-icon.iconset/icon_32x32.png
	cp images/icon/64x64/cqrlog.png $(tmpdir)/cqrlog-icon.iconset/icon_32x32@2x.png
	cp images/icon/64x64/cqrlog.png $(tmpdir)/cqrlog-icon.iconset/icon_64x64.png
	cp images/icon/128x128/cqrlog.png $(tmpdir)/cqrlog-icon.iconset/icon_128x128.png
	cp images/icon/256x256/cqrlog.png $(tmpdir)/cqrlog-icon.iconset/icon_128x128@2x.png
	cp images/icon/256x256/cqrlog.png $(tmpdir)/cqrlog-icon.iconset/icon_256x256.png
	iconutil -c icns $(tmpdir)/cqrlog-icon.iconset -o $(APPRESDIR)/cqrlog.icns
	rm -rf $(tmpdir)/cqrlog-icon.iconset
	@# Generate Info.plist
	@printf '<?xml version="1.0" encoding="UTF-8"?>\n\
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n\
	<plist version="1.0">\n\
	<dict>\n\
	  <key>CFBundleExecutable</key>\n\
	  <string>cqrlog-launcher</string>\n\
	  <key>CFBundleIconFile</key>\n\
	  <string>cqrlog</string>\n\
	  <key>CFBundleIdentifier</key>\n\
	  <string>com.ok2cqr.cqrlog</string>\n\
	  <key>CFBundleName</key>\n\
	  <string>CQRLOG</string>\n\
	  <key>CFBundleDisplayName</key>\n\
	  <string>CQRLOG</string>\n\
	  <key>CFBundlePackageType</key>\n\
	  <string>APPL</string>\n\
	  <key>CFBundleShortVersionString</key>\n\
	  <string>2.6.0</string>\n\
	  <key>CFBundleVersion</key>\n\
	  <string>119</string>\n\
	  <key>NSHighResolutionCapable</key>\n\
	  <true/>\n\
	</dict>\n\
	</plist>\n' > $(APPCONTENTS)/Info.plist
	@# Bundle external libraries and tools
	install -d $(APPFWDIR)
	@echo "Bundling libraries from $(BREW_PREFIX)..."
	@# Copy libraries
	cp $(BREW_PREFIX)/opt/openssl@3/lib/libssl.3.dylib $(APPFWDIR)/
	cp $(BREW_PREFIX)/opt/openssl@3/lib/libcrypto.3.dylib $(APPFWDIR)/
	cp $(BREW_PREFIX)/opt/mariadb/lib/libmariadb.3.dylib $(APPFWDIR)/
	cp $(BREW_PREFIX)/opt/hamlib/lib/libhamlib.4.dylib $(APPFWDIR)/
	cp $(BREW_PREFIX)/opt/libusb/lib/libusb-1.0.0.dylib $(APPFWDIR)/
	chmod 755 $(APPFWDIR)/*.dylib
	@# Copy rigctld / rotctld
	cp $(BREW_PREFIX)/opt/hamlib/bin/rigctld $(APPMACOSDIR)/
	cp $(BREW_PREFIX)/opt/hamlib/bin/rotctld $(APPMACOSDIR)/
	chmod 755 $(APPMACOSDIR)/rigctld $(APPMACOSDIR)/rotctld
	@# Fix all install names (extract actual paths from each binary to handle Cellar versioned paths)
	@for lib in libssl.3.dylib libcrypto.3.dylib libmariadb.3.dylib libhamlib.4.dylib libusb-1.0.0.dylib; do \
	  install_name_tool -id @loader_path/$$lib $(APPFWDIR)/$$lib; \
	done
	@for target in $(APPFWDIR)/libssl.3.dylib $(APPFWDIR)/libmariadb.3.dylib $(APPFWDIR)/libhamlib.4.dylib \
	               $(APPMACOSDIR)/rigctld $(APPMACOSDIR)/rotctld; do \
	  for lib in libssl.3.dylib libcrypto.3.dylib libmariadb.3.dylib libhamlib.4.dylib libusb-1.0.0.dylib; do \
	    old=$$(otool -L "$$target" | grep "$$lib" | grep -v '@loader_path\|@executable_path\|@rpath' | awk '{print $$1}'); \
	    if [ -n "$$old" ]; then \
	      case "$$target" in \
	        */Frameworks/*) new="@loader_path/$$lib" ;; \
	        *)              new="@executable_path/../Frameworks/$$lib" ;; \
	      esac; \
	      install_name_tool -change "$$old" "$$new" "$$target"; \
	    fi; \
	  done; \
	done
	@# Re-sign after modification
	codesign --force --sign - --timestamp=none $(APPFWDIR)/*.dylib $(APPMACOSDIR)/rigctld $(APPMACOSDIR)/rotctld
	@echo "Application bundle created at $(APPBUNDLE)"

DMGNAME = CQRLOG-2.6.0-macOS
dmg: install_macos
	@echo "Creating DMG..."
	rm -f $(DESTDIR)/$(DMGNAME).dmg
	rm -rf $(tmpdir)/cqrlog-dmg
	mkdir -p $(tmpdir)/cqrlog-dmg
	cp -R $(APPBUNDLE) $(tmpdir)/cqrlog-dmg/
	ln -s /Applications $(tmpdir)/cqrlog-dmg/Applications
	hdiutil create -volname "CQRLOG" -srcfolder $(tmpdir)/cqrlog-dmg \
	  -ov -format UDZO $(DESTDIR)/$(DMGNAME).dmg
	rm -rf $(tmpdir)/cqrlog-dmg
	@echo "DMG created at $(DESTDIR)/$(DMGNAME).dmg"

# ---------------------------------------------------------------------------
# Linux packaging targets (AppImage / deb / Docker). Imported from PR #564
# (Pavel, CO7WT). These are Linux-only and used mainly by the GitHub Actions
# workflows; they are NOT prerequisites of the cross-platform build targets so
# the macOS build is left untouched.
# ---------------------------------------------------------------------------

dependencies: ## Install all dependencies assuming a Ubuntu 22.04 LTS machine
	if [ -e /usr/bin/fpc ]; then \
		echo "Dependencies already installed" ; \
	else \
		sudo apt-get update && sudo apt-get install -y \
		git lazarus-ide lcl lcl-gtk2 lcl-nogui \
		lcl-units lcl-utils lazarus lazarus-doc \
		lazarus-src fp-units-misc fp-units-rtl \
		fp-utils fpc fpc-source libssl-dev libfl-dev \
		libqt5pas1 libqt5pas-dev libfuse2 libsquashfuse0 \
		wget devscripts qt5-qmake-bin qtchooser \
		mariadb-server mariadb-client ; \
	fi

hamlib: dependencies ## Install latest hamlib 4.5.5 from git.
	if [ -e /lib/libhamlib.so.4 ]; then \
		echo "Hamlib already installed" ; \
	else \
		cd /tmp && \
		git clone https://github.com/Hamlib/Hamlib.git && \
		cd Hamlib && \
		git checkout Hamlib-4.5.5 && \
		./bootstrap && \
		./configure && \
		make -j4 && \
		sudo env DESTDIR= make install && \
		sudo cp /usr/local/lib/libhamlib* /lib/ ; \
	fi

appimage: dependencies clean cqrlog hamlib ## Build an appimage (Linux, GTK2)
	./tools/appimage.sh

appimage-qt5: dependencies clean cqrlog_qt5 hamlib ## Build an appimage (Linux, QT5)
	./tools/appimage.sh QT5

docker-image: ## Build the docker image to allow a docker build
	cd docker-build && docker build -t pavelmc/cqrlog-build:latest .

docker: ## Pull the pre-built docker image from the internet (~2Gb)
	if command -v docker > /dev/null 2>&1 ; then \
		docker pull pavelmc/cqrlog-build ; \
	else \
		echo "Docker is not installed" && exit 1 ; \
	fi

docker-build: docker ## Build it with a docker image to keep your system clean
	docker run --rm -ti -u root \
	-v $(PWD):/cqrlog \
	-v /usr/local/cqrlog:/usr/local/cqrlog \
	--device /dev/fuse \
	--cap-add SYS_ADMIN \
	--security-opt apparmor:unconfined \
	pavelmc/cqrlog-build \
	make cqrlog

docker-install: docker-build ## Install the files to the system using the binaries from the docker build
	docker run --rm -ti -u root \
	-v $(PWD):/cqrlog \
	-v /usr/local/cqrlog:/usr/local/cqrlog \
	--device /dev/fuse \
	--cap-add SYS_ADMIN \
	--security-opt apparmor:unconfined \
	pavelmc/cqrlog-build \
	make install

docker-appimage: docker-build ## Build an appimage using the binaries from the docker build, GTK2
	docker run --rm -ti -u root \
	-v $(PWD):/cqrlog \
	-v /usr/local/cqrlog:/usr/local/cqrlog \
	--device /dev/fuse \
	--cap-add SYS_ADMIN \
	--security-opt apparmor:unconfined \
	pavelmc/cqrlog-build \
	make appimage

docker-appimage-qt5: docker-build ## Build an appimage using the binaries from the docker build, QT5
	docker run --rm -ti -u root \
	-v $(PWD):/cqrlog \
	-v /usr/local/cqrlog:/usr/local/cqrlog \
	--device /dev/fuse \
	--cap-add SYS_ADMIN \
	--security-opt apparmor:unconfined \
	pavelmc/cqrlog-build \
	make appimage-qt5

docker-deb: docker ## Build a deb package using the binaries from the docker build
	docker run --rm -ti -u root \
	-v $(PWD):/cqrlog \
	-v /usr/local/cqrlog:/usr/local/cqrlog \
	--device /dev/fuse \
	--cap-add SYS_ADMIN \
	--security-opt apparmor:unconfined \
	pavelmc/cqrlog-build \
	make deb

docker-deb-src: docker-build ## Build a deb-src package using the binaries from the docker build
	docker run --rm -ti -u root \
	-v $(PWD):/cqrlog \
	-v /usr/local/cqrlog:/usr/local/cqrlog \
	--device /dev/fuse \
	--cap-add SYS_ADMIN \
	--security-opt apparmor:unconfined \
	pavelmc/cqrlog-build \
	make deb_src

help: ## List the make options available
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
