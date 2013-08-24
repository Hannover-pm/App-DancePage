App::DancePage
==============

App::DancePage is a [Perl Dancer](http://perldancer.org/) powered personal
homepage system written in the [Perl programming language](http://perl.org/).

Who uses App::DancePage?
------------------------

* [Sören Kornetzki](http://soeren-kornetzki.de/), personal homepage
* [Hannover.pm](http://hannover.pm/), Perl Monger group Hanover, Germany

How to use it?
--------------

* Download the [App::DancePage distibution](http://p3rl.org/App::DancePage)
  from [meta::cpan](http://metacpan.org/), [CPAN](http://search.cpan.org/)
  or right out of the [App::DancePage GitHub repository](https://github.com/burnersk/App-DancePage)
  into the target homepage directory
* Execute the following command on your command line:
  * `perl Makefile.PL`
  * `make`
  * `make test`
* If `make test` passes without any warning or error:
  * update the `sitename` property within `config.yml`. It will represent
    the first part of the title
  * Execute `bin/app.pl` on your command line

TODO before first release
-------------------------

* Database design
* DBIx::Class connectors
* Dynamic route handlers based on the database design
* Administrative interface
