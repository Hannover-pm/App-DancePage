# COPYRIGHT
use strict;
use warnings FATAL => 'all';
use utf8;

# Use Test modules.
use Test::More tests => 1 + 1;
use Test::NoWarnings;

############################################################################

BEGIN {
  use_ok('App::DancePage');
}

############################################################################
1;
