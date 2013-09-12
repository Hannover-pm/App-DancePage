App::DancePage
==============

App::DancePage is a [Perl Dancer](http://perldancer.org/) powered personal
homepage system written in the
[Perl programming language](http://www.perl.org/).

Requirements
------------

A Perl version of 5.10 (5.010) or above is required to run App::DancePage.

Run the following command to install all required dependencies. You need 
to have [cpanm](http://p3rl.org/App::cpanminus) installed.

    dzil listdeps | cpanm

The following software have to be installed:

* [OpenSSL](http://www.openssl.org/)

Security checks performed for every route request
-------------------------------------------------

There are currently 3 checks to prevent session stealing and CSRF:

* void session when user agent is switching
* void session when remove address is switching
* flag request when possible CSRF attack was detected

Automated testing
-----------------

This repository have automated testing enabled for the master branch. The test reports are available at:

http://ci.dev5media.de/job/Hannover.pm%20Website/

Copyright and license
---------------------

This software is copyright (c) 2013 by BURNERSK.
 
All rights reserved.
