# What is CQRLOG?

CQRLOG is an advanced ham radio logger based on MySQL database. Provides radio control based on hamlib libraries (currently support of 140+ radio types and models), DX cluster connection, online callbook, a grayliner, internal QSL manager database support and a most accurate country resolution algorithm based on country tables developed by OK1RR. CQRLOG is intended for daily general logging of HF, CW & SSB contacts and strongly focused on easy operation and maintenance. More at https://www.cqrlog.com/

![Image of CQRLOG](https://cqrlog.com/images/users/ok2cqr.png)

## How to contribute?

You have to have at least Lazarus 2.0.6, fpc 3.0.4 compiler, MySQL (MariaDB) server and clinet installed. CQRLOG is developed on Ubuntu 22.04, Lazarus and FreePascal are available in my pesronal repo  https://launchpad.net/~ok2cqr/+archive/lazarus; but packages on most modern Linux distros should work fine. 

Compile with `make` and install with `make DESTDIR=/home/yourusername/where_you_want_to_have_it install`. If you are going to change the source code, fork the repo, do the changes, commit them and use Pull request.

## Dependencies

Build-Depends: lazarus, lcl, fp-utils, fp-units-misc, fp-units-gfx, fp-units-gtk2, fp-units-db, fp-units-math, fp-units-net

Run depends: libssl-dev, mariadb-server, mariadb-client, libhamlib2 (>= 1.2.10) or libhamlib-utils (>= 1.2.10)

## Running build with Docker

If you do not want to install the dependencies into your main machine, you can do the build in a Docker container. You need to mount into that Docker container this directory and also the target directory where you want to put the alpha version of `cqrlog` you are building.

This way helps having a standarized build environment for all distros, you can develop from a Debian, Fedora, Arch, Armbian, Raspberry Pi OS, or any other disto and using docker for the build will work.

But you have to install Docker first, any up to date docker version will work, you can install the ones on your distro's repository.

To use docker builds just check the `make help` command and you will see the different targets

```sh
user@pc:~$ make help
dependencies     Install all dependencies assuming a Ubuntu 22.04 LTS machine
cqrlog           Normal build (Default target)
clean            Clean the environment to have a fresh start
install          Install everything to the system
deb              Build a deb package
deb_src          Build a deb package with source
debug            debug build
appimage         Build an appimage (overwrite the actual one if there is one) using GTK
docker-image     Build the docker image to allow a docker build
docker           Pull the pre-built docker image from the internet (~2Gb)
docker-build     Build it with a docker image to keep your system clean 
docker-install   Install the files to the system using the binaries from the docker build 
docker-appimage  Build an appimage using the binaries from the docker build, GTK2
docker-deb       Build a deb package using the binaries from the docker build
docker-deb-src   Build a deb-src package using the binaries from the docker build 
help             List the make options available
user@pc:~$
```

The options you need mostly are `docker-build` & `docker-install`.

In case you wonder you don't need to build the docker image (aka the `make docker-image` target) as Pavel, CO7WT maintains a public prebuilt image that docker will pull automatically into your system.

Notice that this docker builds will default to `/usr/local/cqrlog-alpha/` as the target directory, so you can have the one from your distro and the test version at the same time; to run from your build you will need to add `/usr/local/cqrlog-alpha/usr/bin` to your `$PATH` and start `cqrlog` from there.

As usual, to use your build make sure that you have no instance of `cqrlog` running and make a backup of your config in `$HOME/.config/cqrlog` (if you ever used `cqrlog` before) to prevent overwriting or corrupt data.

## AppImage packages

AppImage is a portable & distro agnostic packaging format that allows you to distribute software that can be run on any Linux distro. The AppImage packages can be built with the `make appimage` or `make docker-appimage` targets to build the AppImage packages that will pop up on your working directory.

The only requirement of that format is that you need to have the `libfuse2` package installed _(a simple `apt install libfuse2` in any Debian based ditros will do it.)_. Then just add execution permissions to the .AppImage and doudle click it, it has latest hamlib and mariadb packages included.

Note tha this is not the preferred distribution method, that would be the .deb package, but for non-debian based distros this is the easiest way to run it.
