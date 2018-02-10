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

You have to have Lazarus 1.8, fpc 3.0.4 compiler, MySQL server and clinet installed.
CQRLOG is developed on Ubuntu 16.04, Lazarus and FreePascal are available in my pesronal repo  https://launchpad.net/~ok2cqr/+archive/lazarus

Compile with make and install with make DESTDIR=/home/yourusername/where_you_want_to_have_it install. If you are 
going to change the source code, fork the repo, do the changes, commit them and use Pull request.

Dependencies
-------------

Build-Depends: lazarus, lcl, fp-utils, fp-units-misc, fp-units-gfx, fp-units-gtk2, fp-units-db, fp-units-math, fp-units-net

Depends: libssl-dev, mysql-server | mariadb-server, mysql-client | mariadb-client, libhamlib2 (>= 1.2.10), libhamlib-utils (>= 1.2.10)
