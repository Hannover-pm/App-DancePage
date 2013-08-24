# COPYRIGHT
package App::DancePage;
use strict;
use warnings FATAL => 'all';
use utf8;

# Define package version. I don't use `pacakge XXXX N.NNN` syntax because
# Dist::Zilla and other modules doesn't support it yet.
BEGIN {
  our $VERSION = 0.001;
}

# Import only the Dancer module.
use Dancer ':syntax';

# Plugin configuration that can't be setup via config.yml.
BEGIN {

  # Unit Test fixes.
  if ( $ENV{TAP_VERSION} ) {
    debug 'Apply fixes: Unit Test';

    require YAML;
    my $config_hash = YAML::LoadFile('config.yml');

    $config_hash->{environment} = 'development';  # Force development environment.
    $config_hash->{session}     = 'Simple';       # Force in-memory session management.

    # Remove unwanted settings.
    delete $config_hash->{server};
    delete $config_hash->{port};
    delete $config_hash->{daemon};
    delete $config_hash->{behind_proxy};

    foreach my $setting ( keys %{$config_hash} ) {
      set $setting => $config_hash->{$setting};
    }
  }

  # Configuration fixes for development environment.
  if ( setting('environment') eq 'development' ) {
    debug 'Apply fixes: development';

    # Text::Xslate.
    {
      my $engines = setting 'engines';
      $engines->{xslate}->{cache}   = 0;  # Don't do template caching.
      $engines->{xslate}->{verbose} = 2;  # Complain about everything.
      set engines => $engines;
    }
  }

}

# Import other modules.
use DateTime;

# Define lexical constants.
use Const::Fast ('const');
const my $HTTP_STATUS_NOT_FOUND => 404;
const my $SECURITY_CSRF         => 'csrf';
const my $SECURITY_SESSION_UA   => '_security_ua';
const my $SECURITY_SESSION_IP   => '_security_ip';

############################################################################
# Announce own application tokens when server_tokens is enabled.
hook before => sub {
  if ( setting 'server_tokens' ) {
    header 'X-Powered-By2' => sprintf '%s %s', __PACKAGE__, __PACKAGE__->VERSION;
  }
  return;
};

############################################################################
# Security checks to prevent attacks for every route handler.
sub security_hook {

  # Session stealing attacks.
  if ( setting 'session' ) {
    my $request_ua = request->agent   || 'N/A';
    my $request_ip = request->address || 'N/A';
    my $session_ua = session $SECURITY_SESSION_UA;
    my $session_ip = session $SECURITY_SESSION_IP;

    # Lexical routine to void the current session.
    my $void_session = sub {
      my ($reason) = @_;
      my $old_sid = session->id;
      session->destroy;
      session $SECURITY_SESSION_UA => $request_ua;
      session $SECURITY_SESSION_IP => $request_ip;
      info sprintf 'Session %s voided: %s', $old_sid, $reason;
      return;
    };

    # Check user agent.
    if ( !$session_ua ) {
      session $SECURITY_SESSION_UA => $request_ua;
    }
    elsif ( $request_ua ne $session_ua ) {
      $void_session->('user agent does not match');
    }

    # Check remote address.
    if ( !$session_ip ) {
      session $SECURITY_SESSION_IP => $request_ip;
    }
    elsif ( $request_ip ne $session_ip ) {
      $void_session->('remote address does not match');
    }
  }

  # Cross-Site-Request-Fogerty attack detection.
  set $SECURITY_CSRF => 0;
  if ( my $referer = request->referer ) {
    my $uri_base = request->uri_base;
    set $SECURITY_CSRF => 1 if $referer !~ m/^\Q$uri_base\E/;
  }

  return;
}
hook before => \&security_hook;

############################################################################
# Register default template tokens.
sub token_hook {
  my ($tokens) = @_;

  # Register generic content description.
  $tokens->{content_type} ||= content_type() || setting('content_type');
  $tokens->{content_charset}  ||= setting 'charset';
  $tokens->{content_language} ||= setting 'language';

  # Register session id.
  $tokens->{session_id} ||= setting('session') ? session->id : '';

  # Register current timestamp object.
  $tokens->{now} ||= DateTime->now;

  # Register application's version.
  $tokens->{appversion} ||= __PACKAGE__->VERSION;

  return;
}
hook before_template_render => \&token_hook;

############################################################################
# Route handler: GET /
sub get_index_route {
  return template 'index';
}
get q{/} => \&get_index_route;

############################################################################
# Not Found route handler.
sub not_found_route {
  status $HTTP_STATUS_NOT_FOUND;
  return template 'not_found', {
    pagetitle => 'Error 404',
    };
}
any qr{.*} => \&not_found_route;

############################################################################
# Don't forget to return a true value from the file.
1;
## no critic (RequirePod)
__END__
=pod

=encoding utf8

=cut
