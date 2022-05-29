CC=lazbuild
ST=strip
datadir  = $(DESTDIR)/usr/share/cqrlog
bindir   = $(DESTDIR)/usr/bin
sharedir = $(DESTDIR)/usr/share
tmpdir   = /tmp

cqrlog: src/cqrlog.lpi
	$(CC) --ws=gtk2 src/cqrlog.lpi
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
	install -d -v         $(datadir)/images/icon/32x32 
	install -d -v         $(datadir)/images/icon/64x64
	install -d -v         $(datadir)/images/icon/128x128 
	install -d -v         $(datadir)/images/icon/256x256 
	install -d -v         $(sharedir)/pixmaps/cqrlog
	install -d -v         $(sharedir)/icons/cqrlog
	install -d -v         $(sharedir)/applications
	install -d -v         $(sharedir)/appdata
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
#	install -v -m 0644 -t images/*   $(datadir)/images/
	cp -v -R images/* $(datadir)/images
	cp -v -R images/icon/* $(sharedir)/icons/cqrlog
	cp -v -R images/icon/* $(sharedir)/pixmaps/cqrlog
#	install    -v -m 0644 images/icon/32x32/*   $(datadir)/images/icon/32x32/
#	install    -v -m 0644 images/icon/64x64/*   $(datadir)/images/icon/64x64/
#	install    -v -m 0644 images/icon/128x128/*   $(datadir)/images/icon/128x128/
#	install    -v -m 0644 images/icon/256x256/*   $(datadir)/images/icon/256x256/
#	install    -v -m 0644 images/*   $(datadir)/images/
	install    -v -m 0644 tools/cqrlog.desktop $(sharedir)/applications/cqrlog.desktop
	install    -v -m 0644 tools/cqrlog.appdata.xml $(sharedir)/appdata/cqrlog.appdata.xml
	install    -v -m 0644 images/icon/32x32/cqrlog.png $(sharedir)/pixmaps/cqrlog/cqrlog.png
	install    -v -m 0644 images/icon/128x128/cqrlog.png $(sharedir)/icons/cqrlog.png
	install    -v -m 0644 src/changelog.html $(datadir)/changelog.html
	install    -v -m 0644 tools/cqrlog.1.gz $(sharedir)/man/man1/cqrlog.1.gz
deb:
	dpkg-buildpackage -rfakeroot -i -I
deb_src:
	dpkg-buildpackage -rfakeroot -i -I -S
debug:
	$(CC) --ws=gtk2 --pcp=$(tmpdir)/.lazarus src/cqrlog.lpi
	gzip tools/cqrlog.1 -c > tools/cqrlog.1.gz

cqrlog_qt5: src/cqrlog.lpi
	$(CC) --ws=qt5 --pcp=$(tmpdir)/.lazarus src/cqrlog.lpi
	$(ST) src/cqrlog
	gzip tools/cqrlog.1 -c > tools/cqrlog.1.gz

cqrlog_qt5_debug: src/cqrlog.lpi
	$(CC) --ws=qt5 --pcp=$(tmpdir)/.lazarus src/cqrlog.lpi
	gzip tools/cqrlog.1 -c > tools/cqrlog.1.gz
	
