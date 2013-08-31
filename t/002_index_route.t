# COPYRIGHT
use strict;
use warnings FATAL => 'all';
use utf8;

# Use Test modules.
use Test::More tests => 1 + 2;
use Test::NoWarnings;

# The order is important.
use App::DancePage;
use Dancer::Test;

# Use other modules.
use Const::Fast qw( const );

# Define lexical constants.
const my $HTTP_STATUS_OK => 200;
const my $ROUTE_PATH     => q{/};

############################################################################

route_exists(
  [ GET => $ROUTE_PATH ],
  qq{route exists for GET $ROUTE_PATH},
);
response_status_is(
  [ GET => $ROUTE_PATH ],
  $HTTP_STATUS_OK,
  qq{response ok for GET $ROUTE_PATH},
);

############################################################################
1;
