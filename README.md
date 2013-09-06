App::DancePage
==============

App::DancePage is a [Perl Dancer](http://perldancer.org/) powered personal
homepage system written in the
[Perl programming language](http://www.perl.org/).

Requirements
------------

A Perl version of 5.10 (5.010) or above is required to run App::DancePage.

The following Perl modules are required:

* [Const::Fast](http://p3rl.org/Const::Fast)
* [Dancer](http://p3rl.org/Dancer)
* [Dancer::Template::Xslate](http://p3rl.org/Dancer::Template::Xslate)
* [Dancer::Plugin::Auth::Extensible](http://p3rl.org/Dancer::Plugin::Auth::Extensible)
* [Dancer::Plugin::Auth::Extensible::Provider::DBIC](http://p3rl.org/Dancer::Plugin::Auth::Extensible)
* [Dancer::Plugin::Browser::Detect](http://p3rl.org/Dancer::Plugin::Browser::Detect)
* [Dancer::Plugin::DBIC](http://p3rl.org/Dancer::Plugin::DBIC)
* [DBIx::Class::Candy](http://p3rl.org/DBIx::Class::Candy)
* [DBIx::Class::InflateColumn::DateTime](http://p3rl.org/DBIx::Class::InflateColumn::DateTime)
* [DBIx::Class::EncodedColumn](http://p3rl.org/DBIx::Class::EncodedColumn)
* [DBIx::Class::InflateColumn::Markup::Unified](http://p3rl.org/DBIx::Class::InflateColumn::Markup::Unified)
* [DateTime](http://p3rl.org/DateTime)
* [DateTime::Duration](http://p3rl.org/DateTime::Duration)
* [DateTime::Format::SQLite](http://p3rl.org/DateTime::Format::SQLite)
* [Text::Xslate::Bridge::MultiMarkdown](http://p3rl.org/Text::Xslate::Bridge::MultiMarkdown)
* [YAML](http://p3rl.org/YAML)
* [XML::Simple](http://p3rl.org/XML::Simple)
* [GD](http://p3rl.org/GD)
* [JavaScript::Value::Escape](http://p3rl.org/JavaScript::Value::Escape)
* [Net::Twitter](http://p3rl.org/Net::Twitter)
* [LWP::Protocol::https](http://p3rl.org/LWP::Protocol::https)
* [Net::SSLeay](http://p3rl.org/Net::SSLeay)

For testing purposes additionally:

* [Test::More](http://p3rl.org/Test::More)
* [Test::NoWarnings](http://p3rl.org/Test::NoWarnings)

The following software have to be installed:

* [OpenSSL](http://www.openssl.org/)

Security checks performed for every route request
-------------------------------------------------

There are currently 3 checks to prevent session stealing and CSRF:

* void session when user agent is switching
* void session when remove address is switching
* flag request when possible CSRF attack was detected

Copyright and license
---------------------

This software is copyright (c) 2013 by BURNERSK.
 
All rights reserved.
