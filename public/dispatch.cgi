#!/usr/bin/env perl
# COPYRIGHT
use strict;
use warnings FATAL => 'all';
use utf8;

# Use other modules.
use Dancer qw( :syntax );
use FindBin qw( $RealBin );
use Plack::Runner qw( path );

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

# Launch App::DancePage. NO FURTHER CODE THAN `run;`!
Plack::Runner->run($psgi);
