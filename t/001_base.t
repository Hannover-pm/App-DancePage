# COPYRIGHT
use strict;
use warnings FATAL => 'all';
use utf8;

# Import Unit Test modules.
use Test::More tests => 1 + 1;
use Test::NoWarnings;

BEGIN {
  use_ok('App::DancePage');
}

############################################################################
# Don't forget to return a true value from the file.
1;
