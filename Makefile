CC=lazbuild
ST=strip
datadir  = $(DESTDIR)/usr/share/cqrlog
bindir   = $(DESTDIR)/usr/bin
sharedir = $(DESTDIR)/usr/share
tmpdir   = /tmp
PWD = $(shell pwd)

.DEFAULT_GOAL := cqrlog

.PHONY : help dockerbuild clean install deb deb_src debug

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

cqrlog: dependencies src/cqrlog.lpi ## Normal build (Default target)
	$(CC) --ws=gtk2 --pcp=$(tmpdir)/.lazarus src/cqrlog.lpi
	$(ST) src/cqrlog
	gzip tools/cqrlog.1 -c > tools/cqrlog.1.gz

cqrlog_qt5: dependencies src/cqrlog.lpi ## Build it with qt5
	$(CC) --ws=qt5 --pcp=$(tmpdir)/.lazarus src/cqrlog.lpi
	$(ST) src/cqrlog
	gzip tools/cqrlog.1 -c > tools/cqrlog.1.gz

cqrlog_qt5_debug: dependencies src/cqrlog.lpi ## Build it with qt5 debug
	$(CC) --ws=qt5 --pcp=$(tmpdir)/.lazarus src/cqrlog.lpi
	gzip tools/cqrlog.1 -c > tools/cqrlog.1.gz

clean: ## Clean the environment to have a fresh start
	rm -f -v src/*.o src/*.ppu src/*.bak src/lnet/lib/*.ppu src/lnet/lib/*.o src/lnet/lib/*.bak src/cqrlog src/cqrlog.compiled src/ipc/*.o src/ipc/*.ppu src/cqrlog.or
	rm -f -v src/*.lrs src/*.ps src/*.lrt src/*.rsh  src/*.rst src/*.a src/synapse/*.a src/synapse/*.o src/synapse/*.ppu
	rm -f -v src/mysql/*.ppu src/mysq/*.bak src/mysql/*.o
	rm -f -v tools/cqrlog.1.gz
	rm -rf src/backup
	rm -f -v src/richmemo/*.o src/richmemo/*.ppu src/richmemo/gtk2/*.ppu src/richmemo/gtk2/*.o
	rm -f -v tools/adif_hash_generator tools/adif_hash_generator.lpi tools/adif_hash_generator.lps
	rm -rf /tmp/.lazarus
	
install: ## Install everything to the system
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
#	install    -v -m 0644 -t images/*   $(datadir)/images/
#	install    -v -m 0644 images/icon/32x32/*   $(datadir)/images/icon/32x32/
#	install    -v -m 0644 images/icon/64x64/*   $(datadir)/images/icon/64x64/
#	install    -v -m 0644 images/icon/128x128/*   $(datadir)/images/icon/128x128/
#	install    -v -m 0644 images/icon/256x256/*   $(datadir)/images/icon/256x256/
#	install    -v -m 0644 images/*   $(datadir)/images/
	cp -v -R images/* $(datadir)/images
	cp -v -R images/icon/* $(sharedir)/icons/cqrlog
	cp -v -R images/icon/* $(sharedir)/pixmaps/cqrlog
	install    -v -m 0644 tools/cqrlog.desktop $(sharedir)/applications/cqrlog.desktop
	install    -v -m 0644 tools/cqrlog.appdata.xml $(sharedir)/appdata/cqrlog.appdata.xml
	install    -v -m 0644 images/icon/32x32/cqrlog.png $(sharedir)/pixmaps/cqrlog/cqrlog.png
	install    -v -m 0644 images/icon/128x128/cqrlog.png $(sharedir)/icons/cqrlog.png
	install    -v -m 0644 src/changelog.html $(datadir)/changelog.html
	install    -v -m 0644 tools/cqrlog.1.gz $(sharedir)/man/man1/cqrlog.1.gz

deb: dependencies ## Build a deb package
	./tools/makedeb.sh

deb_src: ## Build a deb package with source
	dpkg-buildpackage -rfakeroot -i -I -S

debug: ## debug build
	$(CC) --ws=gtk2 --pcp=$(tmpdir)/.lazarus src/cqrlog.lpi
	gzip tools/cqrlog.1 -c > tools/cqrlog.1.gz

appimage: clean cqrlog hamlib ## Build an appimage (overwrite the actual one if there is one) using GTK
	./tools/appimage.sh

appimage-qt5: clean cqrlog_qt5 hamlib ## Build an appimage (overwrite the actual one if there is one) using QT5
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
	-v /usr/local/cqrlog-alpha:/usr/local/cqrlog-alpha \
	--device /dev/fuse \
	--cap-add SYS_ADMIN \
	--security-opt apparmor:unconfined \
	pavelmc/cqrlog-build \
	make cqrlog

docker-install: docker-build ## Install the files to the system using the binaries from the docker build 
	docker run --rm -ti -u root \
	-v $(PWD):/cqrlog \
	-v /usr/local/cqrlog-alpha:/usr/local/cqrlog-alpha \
	--device /dev/fuse \
	--cap-add SYS_ADMIN \
	--security-opt apparmor:unconfined \
	pavelmc/cqrlog-build \
	make install

docker-appimage: docker-build ## Build an appimage using the binaries from the docker build, GTK2
	docker run --rm -ti -u root \
	-v $(PWD):/cqrlog \
	-v /usr/local/cqrlog-alpha:/usr/local/cqrlog-alpha \
	--device /dev/fuse \
	--cap-add SYS_ADMIN \
	--security-opt apparmor:unconfined \
	pavelmc/cqrlog-build \
	make appimage

docker-appimage-qt5: docker-build ## Build an appimage using the binaries from the docker build, QT5
	docker run --rm -ti -u root \
	-v $(PWD):/cqrlog \
	-v /usr/local/cqrlog-alpha:/usr/local/cqrlog-alpha \
	--device /dev/fuse \
	--cap-add SYS_ADMIN \
	--security-opt apparmor:unconfined \
	pavelmc/cqrlog-build \
	make appimage-qt5

docker-deb: docker ## Build a deb package using the binaries from the docker build
	docker run --rm -ti -u root \
	-v $(PWD):/cqrlog \
	-v /usr/local/cqrlog-alpha:/usr/local/cqrlog-alpha \
	--device /dev/fuse \
	--cap-add SYS_ADMIN \
	--security-opt apparmor:unconfined \
	pavelmc/cqrlog-build \
	make deb

docker-deb-src: docker-build ## Build a deb-src package using the binaries from the docker build 
	docker run --rm -ti -u root \
	-v $(PWD):/cqrlog \
	-v /usr/local/cqrlog-alpha:/usr/local/cqrlog-alpha \
	--device /dev/fuse \
	--cap-add SYS_ADMIN \
	--security-opt apparmor:unconfined \
	pavelmc/cqrlog-build \
	make deb_src

help: ## List the make options available
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
