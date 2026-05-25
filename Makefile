LAZBUILD ?= $(or $(shell command -v lazbuild 2>/dev/null),$(wildcard $(HOME)/fpcupdeluxe/lazarus/lazbuild),lazbuild)
ST=strip
# Set default path header for installation. Can be changed by
#  environment variable or CLI
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  DESTDIR  = $(HOME)/cqrlog
else
  DESTDIR  = /usr
endif
#
datadir  = $(DESTDIR)/share/cqrlog
bindir   = $(DESTDIR)/bin
sharedir = $(DESTDIR)/share
tmpdir   = /tmp

cqrlog: src/cqrlog.lpi
	$(LAZBUILD) --ws=cocoa src/cqrlog.lpi
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
deb:
	dpkg-buildpackage -rfakeroot -i -I
deb_src:
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
