CC=lazbuild
ST=strip
datadir  = $(DESTDIR)/usr/share/cqrlog
bindir   = $(DESTDIR)/usr/bin
sharedir = $(DESTDIR)/usr/share

cqrlog: src/cqrlog.lpi
	$(CC) --ws=gtk2 src/cqrlog.lpi
	$(ST) src/cqrlog
	gzip tools/cqrlog.1 -c > tools/cqrlog.1.gz

clean:
	rm -f -v src/*.o src/*.ppu src/*.bak src/lnet/lib/*.ppu src/lnet/lib/*.o src/lnet/lib/*.bak src/cqrlog src/cqrlog.compiled debian/cqrlog.* src/ipc/*.o src/ipc/*.ppu src/cqrlog.or
	rm -rf debian/cqrlog
	rm -f -v src/mysql/*.ppu src/mysq/*.bak src/mysql/*.o
	rm -f -v tools/cqrlog.1.gz
	
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
	install -d -v         $(sharedir)/pixmaps/cqrlog
	install -d -v         $(sharedir)/icons
	install -d -v         $(sharedir)/applications
	install -d -v         $(sharedir)/man/man1
	install    -v -m 0755 src/cqrlog $(bindir)
	install    -v -m 0755 tools/cqrlog-apparmor-fix $(datadir)/cqrlog-apparmor-fix
	install    -v -m 0644 ctyfiles/* $(datadir)/ctyfiles/
	install    -v -m 0644 help/img/* $(datadir)/help/img/
	install    -v -m 0644 help/*.*   $(datadir)/help/
	install    -v -m 0644 members/*  $(datadir)/members/
	install    -v -m 0644 xplanet/*  $(datadir)/xplanet/
	install    -v -m 0755 voice_keyer/*  $(datadir)/voice_keyer/
	install    -v -m 0644 zipcodes/* $(datadir)/zipcodes/
	install    -v -m 0644 images/*   $(datadir)/images/
	install    -v -m 0644 tools/cqrlog.desktop $(sharedir)/applications/cqrlog.desktop
	install    -v -m 0644 images/cqrlog.png $(sharedir)/pixmaps/cqrlog/cqrlog.png
	install    -v -m 0644 images/cqrlog.png $(sharedir)/icons/cqrlog.png  
	install    -v -m 0644 src/changelog.html $(datadir)/changelog.html
	install    -v -m 0644 tools/cqrlog.1.gz $(sharedir)/man/man1/cqrlog.1.gz
deb:
	dpkg-buildpackage -rfakeroot -i -I
deb_src:
	dpkg-buildpackage -rfakeroot -i -I -S
