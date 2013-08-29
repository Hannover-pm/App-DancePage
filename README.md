App::DancePage
==============

App::DancePage is a [Perl Dancer](http://perldancer.org/) powered personal
homepage system written in the [Perl programming language](http://perl.org/).

TODO before first release
-------------------------

* Database design ( *in review* )
* DBIx::Class connectors ( *in review* )
* Dynamic route handlers based on the database design ( *in progress* )
* Administrative interface ( *in progress* )

Dependencies
------------

* Test::NoWarnings
* Dancer::Template::Xslate
* Dancer::Plugin::DBIC
* Dancer::Plugin::Auth::Extensible
* Const::Fast
* DBIx::Class::EncodedColumn
* DBIx::Class::InflateColumn::DateTime
* DBIx::Class::Candy
* Text::Xslate::Bridge::MultiMarkdown
* DBIx::Class::InflateColumn::Markup::Unified

Automated Testing
-----------------

http://ci.dev5media.de/job/App-DancePage/

Sample database entries
-----------------------

By default App::DancePage is setting up the database schema with sample
entries such as users and pages.

Administrative user:
* Username: admin
* Password: admin

Unprivileged user:
* Username: user
* Password: user
