#!/usr/bin/perl
#
# Net::Twitter - OAuth desktop app example
#
use warnings;
use strict;

use Net::Twitter;
use Storable;
use YAML;

my $consumer_credentials = YAML::LoadFile('twitter.yml');
my $datafile             = '.twitter_token';

my $nt = Net::Twitter->new( traits => [qw/API::RESTv1_1/], %$consumer_credentials );
my $access_tokens = eval { retrieve($datafile) } || [];

if ( !@$access_tokens ) {
  my $auth_url = $nt->get_authorization_url;
  print "\n";
  print "1. Authorize the Twitter App at: $auth_url\n";
  print "2. Enter the returned PIN to complete the Twitter App authorization process: ";

  my $pin = <STDIN>;  # wait for input
  chomp $pin;
  print "\n";

  # request_access_token stores the tokens in $nt AND returns them
  my @access_tokens = $nt->request_access_token( verifier => $pin );

  # save the access tokens
  store \@access_tokens, $datafile;
}
else {
  print "\nAlread authorized\n";
}
