What is CQRLOG?
---------------

CQRLOG is an advanced ham radio logger based on MySQL database. Provides radio control 
based on hamlib libraries (currently support of 140+ radio types and models), DX cluster 
connection, online callbook, a grayliner, internal QSL manager database support and a most 
accurate country resolution algorithm based on country tables developed by OK1RR. CQRLOG is 
intended for daily general logging of HF, CW & SSB contacts and strongly focused on easy 
operation and maintenance. More at https://www.cqrlog.com/

![Image of CQRLOG](https://cqrlog.com/images/users/ok2cqr.png)

How to contribute?
-------------------

You have to have Lazarus 2.0.6, fpc 3.0.4 compiler, MySQL server and clinet installed.
CQRLOG is developed on Ubuntu 20.04, Lazarus and FreePascal are available in my pesronal repo  https://launchpad.net/~ok2cqr/+archive/lazarus

Compile with make and install with make DESTDIR=/home/yourusername/where_you_want_to_have_it install. If you are 
going to change the source code, fork the repo, do the changes, commit them and use Pull request.

Dependencies
-------------

Build-Depends: lazarus, lcl, fp-utils, fp-units-misc, fp-units-gfx, fp-units-gtk2, fp-units-db, fp-units-math, fp-units-net

Depends: libssl-dev, mysql-server | mariadb-server, mysql-client | mariadb-client, libhamlib2 (>= 1.2.10), libhamlib-utils (>= 1.2.10)

Running build with Docker
-------------------------

If you do not want to install the dependencies into your main machine, you can do the build
in a Docker container.  You need to mount into that Docker container this directory and
also the target directory where you want to put the alpha version of `cqrlog` you are
building.

This also helps if you want to build, e.g., on a Debian Stretch machine.  Attempts at
native builds on that platform have failed.  Using a reasonably recent Ubuntu inside our
Docker-based build environment, makes the build work even on Debian Stretch.

That bad news is, you have to [install Docker](https://docs.docker.com/install/linux/docker-ce/ubuntu/) (CE is fine).

That done, you can prepare an Ubuntu Docker image with the build tools as follows:

    (cd docker-build && docker build -t this.registry.is.invalid/cqrlog-build .)

(In case you wonder: There is no need to use a Docker registry, so we provide a registry
host that is guaranteed to not exist.)

Then, run the build itself with

    sudo mkdir -p /usr/local/cqrlog-alpha && sudo chown $SUDO_USER /usr/local/cqrlog-alpha &&
    docker run -ti -u root -v $(pwd):/home/cqrlog/build \
      -v /usr/local/cqrlog-alpha:/usr/local/cqrlog-alpha this.registry.is.invalid/cqrlog-build

To use your build, make sure that you have no instance of `cqrlog` running, backup
`$HOME/.config/cqrlog` (if you ever used `cqrlog` before), add
`/usr/local/cqrlog-alpha/usr/bin` to your `$PATH` and start `cqrlog` from there.
