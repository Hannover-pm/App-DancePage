#!/usr/bin/env perl
# COPYRIGHT
## no critic (RequireCarp)
use strict;
use warnings FATAL => 'all';
use utf8;

# Import other modules.
use Dancer        (':syntax');
use FindBin       ('$RealBin');  ## no critic (RequireInterpolationOfMetach)
use Plack::Runner ('path');

############################################################################
# For some reason Apache SetEnv directives dont propagate correctly to the
# dispatchers, so forcing PSGI and env here is safer.
set apphandler  => 'PSGI';
set environment => 'production';

############################################################################
my $psgi = path( $RealBin, qw( .. bin app.pl ) );
die "Unable to read startup script '$psgi': File is readable by effective uid/gid"
  unless -r $psgi;

# Execute App::DancePage. NO FURTHER CODE THAN `run`!
Plack::Runner->run($psgi);
