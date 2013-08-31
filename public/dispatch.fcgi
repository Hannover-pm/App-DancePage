#!/usr/bin/env perl
# COPYRIGHT
use strict;
use warnings FATAL => 'all';
use utf8;

use English qw( -no_match_vars );

# Use other modules.
use Dancer qw( :syntax );
use FindBin qw( $RealBin );
use Plack::Handler::FCGI qw( path );

############################################################################
# For some reason Apache SetEnv directives dont propagate correctly to the
# dispatchers, so forcing PSGI and env here is safer.
set apphandler  => 'PSGI';
set environment => 'production';

############################################################################
# Find and prepare bootstrapper.
my $psgi = path( $RealBin, '..', 'bin', 'app.pl' );
die "Unable to read startup script '$psgi': file is not readable by effective uid/gid"
  unless -r $psgi;
my $app = do($psgi);
die "Unable to read startup script '$psgi': $EVAL_ERROR" if $EVAL_ERROR;
my $server = Plack::Handler::FCGI->new( nproc => 5, detach => 1 );

# Launch App::DancePage. NO FURTHER CODE THAN `run;`!
$server->run($app);
