What is CQRLOG?
---------------

CQRLOG is an advanced ham radio logger based on MySQL database. Provides radio control 
based on hamlib libraries (currently support of 140+ radio types and models), DX cluster 
connection, online callbook, a grayliner, internal QSL manager database support and a most 
accurate country resolution algorithm based on country tables developed by OK1RR. CQRLOG is 
intended for daily general logging of HF, CW & SSB contacts and strongly focused on easy 
operation and maintenance. More at http://cqrlog.com/

How to contribute?
-------------------

You have to have Lazarus 0.9.30.2-2, fpc 2.4.4 compiler, MySQL server  and clinet installed. 
Both shipped with Ubuntu 12.04 LTS. 
Compile with make and install with make DESTDIR=/home/yourusername/where_you_want_to_have_it. If you are 
going to change the source code, fork the repo, do the changes, commit them and use Pull request.

Dependencies
-------------
libmysql-dev, libhamlib-dev
