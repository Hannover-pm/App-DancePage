# COPYRIGHT
use strict;
use warnings FATAL => 'all';
use utf8;

# Import Unit Test modules.
use Test::More tests => 1 + 13;
use Test::NoWarnings;

# Import other modules.
use App::DancePage;
use Dancer::Test;
use Data::Dumper ('Dumper');

# Define lexical constants.
use Const::Fast ('const');
const my $HTTP_STATUS_OK        => 200;
const my $HTTP_STATUS_FOUND     => 302;
const my $HTTP_STATUS_FORBIDDEN => 403;
const my $HTTP_STATUS_NOT_FOUND => 404;
const my $SIMPLE_ROUTE_METHODS  => [qw( GET POST )];
const my $SIMPLE_GET_ROUTES     => [qw( / )];
const my $NONEXISTENT_ROUTE     => '/nonexistent';
const my $DEFAULT_USER          => 'root';
const my $DEFAULT_USER_PASSWORD => '!';

############################################################################
# Check simple GET route handlers for existence and returning HTTP status
# code 200 OK.
foreach my $path ( @{$SIMPLE_GET_ROUTES} ) {
  route_exists(
    [ GET => $path ],
    qq{route handler exists: GET $path},
  ) or diag Dumper [read_logs];
  response_status_is(
    [ GET => $path ],
    $HTTP_STATUS_OK,
    qq{route handler HTTP status $HTTP_STATUS_OK: GET $path},
  ) or diag Dumper [read_logs];
}

############################################################################
# Check authentification route handlers.
{
  route_exists(
    [ GET => q{/login2} ],
    qq{route handler exists: GET /login2},
  ) or diag Dumper [read_logs];
  response_status_is(
    [ GET => q{/login2} ],
    $HTTP_STATUS_OK,
    qq{route handler HTTP status $HTTP_STATUS_OK: GET /login2},
  ) or diag Dumper [read_logs];

  route_exists(
    [ POST => q{/login2} ],
    qq{route handler exists: POST /login2},
  ) or diag Dumper [read_logs];

  route_exists(
    [ GET => q{/logout2} ],
    qq{route handler exists: GET /logout2},
  ) or diag Dumper [read_logs];
  response_status_is(
    [ GET => q{/logout2} ],
    $HTTP_STATUS_FOUND,
    qq{route handler HTTP status $HTTP_STATUS_FOUND: GET /logout2},
  ) or diag Dumper [read_logs];

  route_exists(
    [ GET => q{/access-denied} ],
    qq{route handler exists: GET /access-denied},
  ) or diag Dumper [read_logs];
  response_status_is(
    [ GET => q{/access-denied} ],
    $HTTP_STATUS_FORBIDDEN,
    qq{route handler HTTP status $HTTP_STATUS_FORBIDDEN: GET /access-denied},
  ) or diag Dumper [read_logs];

}

############################################################################
# Check non existing route handler not exists and returns HTTP status code
# 404 Not Found.
foreach my $method ( @{$SIMPLE_ROUTE_METHODS} ) {
  route_exists(
    [ $method => $NONEXISTENT_ROUTE ],
    qq{not found route handler exists: $method $NONEXISTENT_ROUTE},
  ) or diag Dumper [read_logs];
  response_status_is(
    [ $method => $NONEXISTENT_ROUTE ],
    $HTTP_STATUS_NOT_FOUND,
    qq{not found route handler HTTP status $HTTP_STATUS_NOT_FOUND: $method $NONEXISTENT_ROUTE},
  ) or diag Dumper [read_logs];
}

############################################################################
# Don't forget to return a true value from the file.
1;
