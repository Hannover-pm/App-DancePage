# COPYRIGHT
package App::DancePage;
use 5.010;
use strict;
use warnings FATAL => 'all';
use utf8;

use English qw( -no_match_vars );

BEGIN {
  our $VERSION = 0.001;
}

# Use only Dancer at this time.
use Dancer qw( :syntax );

# Configuration fixes for Dancer plugins.
BEGIN {

  # Unit Test.
  if ( exists $INC{'Test/More.pm'} || exists $INC{'Dancer/Test.pm'} ) {
    debug 'Apply fixes: Unit Test';
    require YAML;
    my $config_hash = YAML::LoadFile('config.yml');

    $config_hash->{environment} = 'development';  # Force development environment.
    $config_hash->{session}     = 'Simple';       # Force in-memory session management.

    # Use Unit Test SQLite database.
    $config_hash->{plugins}->{DBIC}->{default}->{dsn} = 'dbi:SQLite:dbname=dancepage-test.db';

    # Remove unwanted settings.
    delete $config_hash->{server};
    delete $config_hash->{port};
    delete $config_hash->{daemon};
    delete $config_hash->{behind_proxy};

    foreach my $setting ( keys %{$config_hash} ) {
      set $setting => $config_hash->{$setting};
    }
  }

  # Configuration tunings that can't provided via environment configuration.
  if ( setting('environment') eq 'development' ) {

    # Use development database.
    {
      my $plugins = setting 'plugins';
      $plugins->{DBIC}->{default}->{dsn} = 'dbi:SQLite:dbname=dancepage-development.db';
      set plugins => $plugins;
    }

    # Template engines.
    if ( my $engines = setting 'engines' ) {

      # Dancer::Template::Xslate.
      if ( exists $engines->{xslate} ) {
        $engines->{xslate}->{cache}   = 0;  # Don't cache anything.
        $engines->{xslate}->{verbose} = 2;  # Complain about everthing.
      }

      # Activate new configuration.
      set engines => $engines;
    }

  }

}

# Use other module.
use Dancer::Plugin::DBIC qw( schema rset );
use Dancer::Plugin::Auth::Extensible qw(
  logged_in_user authenticate_user user_has_role require_role
);
use Dancer::Plugin::Browser::Detect qw( browser_detect );
use DateTime qw();
use Const::Fast qw( const );

# Define lexical constants.
const my $SECHK_KEY_UA          => '_sechk_ua';
const my $SECHK_KEY_IP          => '_sechk_ip';
const my $SECHK_KEY_CSRF        => 'csrf';
const my $SECHK_UNDEF           => 'N/A';
const my $DB_TIMEZONE           => DateTime->now->time_zone;
const my $GENERIC_CATID         => 1;
const my $BLOG_CATID            => 2;
const my $METTINGS_CATID        => 3;
const my $HTTP_STATUS_NOT_FOUND => 404;
const my $SESS_KEY_LAYOUT       => 'layout';

############################################################################
# Initial environment setup.
sub setup {

  # Setup database.
  {
    my $db_version =
      int( eval { rset('DbInfo')->search( { property => 'schema_version' } )->single->value } || 0 );
    my $schema_version = int( eval { App::DancePage::Schema->VERSION } || 0 );
    die "Can't detect current schema version" if !$schema_version;
    if ( !$db_version ) {
      info sprintf 'Deploying schema version %d...', $schema_version;
      eval { schema->deploy; 1 }
        or die sprintf "Can't deploy schema version %d: %s",
        $schema_version, $EVAL_ERROR;

      my $now = DateTime->now;

      # Register deployed schema version.
      rset('DbInfo')->create( { property => 'schema_version', value => $schema_version } );

      # Register default roles.
      rset('Role')->create( { role => $_ } ) for (qw( admin ));

      # Register default users.
      my $admin_user =
        rset('User')->create( { username => 'admin', password => 'admin', signup_on => $now } );

      # Register default user roles.
      rset('User')->search( { username => 'admin' } )->single->set_roles( [ { role => 'admin' } ] );

      # Register default categories.
      my $generic_category = rset('Category')->create( {
        category_id  => $GENERIC_CATID,
        category     => 'generic',
        abstract     => '',
        category_uri => '',
      } );
      my $blog_category = rset('Category')->create( {
        category_id  => $BLOG_CATID,
        category     => 'Blog',
        abstract     => 'Neues rund um Hannover.pm',
        category_uri => 'blog',
      } );
      my $mettings_category = rset('Category')->create( {
        category_id  => $METTINGS_CATID,
        category     => 'Treffen',
        abstract     => 'Alle Treffen (inkl. Hackathon) von Hannover.pm',
        category_uri => 'treffen',
      } );

      # Register default pages.
      $generic_category->create_related(
        'pages', {
          subject        => 'Über uns',
          abstract       => 'Die Perl Mongers Hannover stellen sich vor',
          page_uri       => 'ueber-uns',
          message        => 'Hallo Welt!',
          author         => $admin_user,
          created_on     => $now,
          publication_on => $now,
        } );
      $generic_category->create_related(
        'pages', {
          subject        => 'Kontakt',
          abstract       => 'Alle Kontaktinformationen über Hannover.pm',
          message        => 'Hallo Welt!',
          page_uri       => 'kontakt',
          author         => $admin_user,
          created_on     => $now,
          publication_on => $now,
        } );
      $blog_category->create_related(
        'pages', {
          subject        => 'Hannover.pm Homepage ist fertig',
          abstract       => 'Lange hat es gedauert, nun ist sie da. Die Hannover.pm Homepage ist fertig',
          message        => 'Hallo Welt!',
          page_uri       => 'hannover-pm-homepage-ist-fertig',
          author         => $admin_user,
          created_on     => $now,
          publication_on => $now,
        } );
      foreach (
        reverse(
          [ 21, 2013, 9, 10 ], [ 20, 2013, 8, 27 ], [ 19, 2013, 8, 13 ], [ 18, 2013, 7, 30 ],
          [ 17, 2013, 7, 16 ], [ 16, 2013, 7, 2 ],  [ 15, 2013, 6, 18 ], [ 14, 2013, 6, 4 ],
          [ 13, 2013, 5, 21 ], [ 12, 2013, 5, 7 ],  [ 11, 2013, 4, 23 ], [ 10, 2013, 4, 9 ],
          [ 9, 2013, 3, 26 ], [ 8, 2013, 2, 28 ], [ 7, 2013, 2, 13 ], [ 6, 2013, 1, 29 ], [ 5, 2012, 12, 4 ],
          [ 4, 2012, 11, 20 ], [ 3, 2012, 10, 30 ], [ 2, 2012, 10, 16 ], [ 1, 2012, 9, 5 ] ) )
      {
        my $title = sprintf 'Hannover.pm Treffen v%1$d - %4$02d.%3$02d.%2$04d', @$_;
        my $abstract =
          sprintf 'Ankündigung und Bericht zum %1$d. Hannover.pm Treffen am %4$02d.%3$02d.%2$04d', @$_;
        my $dt = DateTime->new(
          year   => $_->[1], month     => $_->[2], day => $_->[3], hour => 18, minute => 0,
          second => 0,       time_zone => 'Europe/Berlin'
        );
        $mettings_category->create_related(
          'pages', {
            subject        => $title,
            abstract       => $abstract,
            message        => 'Hallo Welt!',
            page_uri       => uri_part($title),
            author         => $admin_user,
            created_on     => $now,
            publication_on => $dt->clone->set_time_zone($DB_TIMEZONE),
          } );
      }
    }
    elsif ( $db_version != $schema_version ) {
      die sprintf 'Schema version %d required but database version %d found', $schema_version,
        $db_version;
    }
  }

  return;
}
setup;

############################################################################
# Helper routine to void the current request session with supplied reason.
sub void_session {
  my ($reason) = @_;
  return unless setting 'session';
  my $old_sid    = session->id;
  my $old_layout = session $SESS_KEY_LAYOUT;
  session->destroy;
  session $SECHK_KEY_UA => request->user_agent || $SECHK_UNDEF;
  session $SECHK_KEY_IP => request->address    || $SECHK_UNDEF;
  session $SESS_KEY_LAYOUT => $old_layout if $old_layout;
  info sprintf 'Session %d voided: %s', $old_sid, $reason;
  return;
}

############################################################################
# Helper routine to generate an uri part out of a supplied string (title).
sub uri_part {
  my ($title) = @_;
  return if !$title;
  my $uri_part = lc $title;
  $uri_part =~ s/[äÄ]/ae/g;
  $uri_part =~ s/[öÖ]/oe/g;
  $uri_part =~ s/[üÜ]/ue/g;
  $uri_part =~ s/ß/ss/g;
  $uri_part =~ s/\s+/-/g;
  $uri_part =~ s/[^a-z0-9\-\_]+/-/g;
  $uri_part =~ s/^-+|-+$//g;
  $uri_part =~ s/-+/-/g;
  return $uri_part;
}

############################################################################
hook before => sub {
  var now => DateTime->now;
  var layout => session($SESS_KEY_LAYOUT) || ( browser_detect->mobile ? 'mobile' : 'main' );
  session $SESS_KEY_LAYOUT => var 'layout';
};

############################################################################
# Security checks (mostly session related) to detect/prevent attacks.
sub security_check_hook {

  # Session stealing prevention.
  if ( setting 'session' ) {

    my $request_agent   = request->user_agent || $SECHK_UNDEF;
    my $request_address = request->address    || $SECHK_UNDEF;
    my $session_agent   = session $SECHK_KEY_UA;
    my $session_address = session $SECHK_KEY_IP;

    # User agent switching.
    if ( !$session_agent ) {
      session $SECHK_KEY_UA => $request_agent;
    }
    elsif ( $request_agent ne $session_agent ) {
      void_session('security check user agent failed');
    }

    # IP address switching.
    if ( !$session_address ) {
      session $SECHK_KEY_IP => $request_address;
    }
    elsif ( $request_address ne $session_address ) {
      void_session('security check remote address failed');
    }

  }

  # Detect possible Cross-Site-Request-Forgery (CSRF) attacks.
  var $SECHK_KEY_CSRF => 0;
  if ( my $request_referer = request->referer ) {
    my $uri_base_http  = request->uri_base =~ s{^https?://}{http://}r;
    my $uri_base_https = $uri_base_http =~ s{^http}{https}r;

    # It's a possible CSRF when request referer is not us.
    if ( $request_referer !~ m/^(?:\Q$uri_base_http\E|\Q$uri_base_https\E)/ ) {
      var $SECHK_KEY_CSRF => 1;
      info 'Possible CSRF attack detected';
    }
  }

  # Don't allow to "return" to others via login etc..
  if ( my $return_url = params->{return_url} ) {
    my $uri_base_http  = request->uri_base =~ s{^https?://}{http://}r;
    my $uri_base_https = $uri_base_http =~ s{^http}{https}r;
    if ( $return_url !~ m{^/} && $return_url !~ m/^(?:\Q$uri_base_http\E|\Q$uri_base_https\E)/ ) {
      delete params->{return_url};
    }
  }

  return;
}
hook before => \&security_check_hook if !setting 'security_checks_disabled';

############################################################################
# Supply default template tokens. Don't override anything!
sub default_token_hook {
  my ($tokens) = @_;

  $tokens->{content_type} ||= content_type || setting 'content_type';
  $tokens->{content_charset} ||= setting 'charset';

  $tokens->{now}      = var 'now';
  $tokens->{timezone} = 'Europe/Berlin';
  $tokens->{locale}   = 'de_DE';

  $tokens->{logged_in_user} = logged_in_user;
  $tokens->{user_has_role}  = sub {
    my ( $user, $role ) = @_;
    $role = $user and $user = undef if !$role;
    $user = logged_in_user->username if !$user && logged_in_user;
    return 0 if !$user;
    return user_has_role( $user, $role ) ? 1 : 0;
  };

  $tokens->{robots} = 'index,follow,archive';

  return;
}
hook before_template_render => \&default_token_hook;

############################################################################
# Route handler: index page/homepage.
sub get_index_route {

  my $meetings_category = rset('Category')->search( { 'me.category_id' => $METTINGS_CATID } )->single;
  my $current_meetings = $meetings_category->search_related(
    'pages', {
      publication_on => { not => undef },
    }, {
      order_by => [ { -desc => [qw( publication_on page_id )] } ],
      rows     => 5,
    } );

  my $blog_category = rset('Category')->search( { 'me.category_id' => $BLOG_CATID } )->single;
  my $latest_blogposts = $blog_category->search_related(
    'pages', {
      publication_on => { not => undef },
    }, {
      order_by => [ { -desc => [qw( publication_on page_id )] } ],
      rows     => 3,
    } );

  return template 'index', {
    meetings_category => $meetings_category,
    current_meetings  => [ $current_meetings->all ],
    blog_category     => $blog_category,
    latest_blogposts  => [ $latest_blogposts->all ],
    }, {
    layout => var('layout'),
    };
}
get q{/} => \&get_index_route;

############################################################################
# Route handler: login.
sub get_login_route {
  return redirect q{/} if logged_in_user;

  return template 'login', {
    pagesubject  => 'Login',
    pageabstract => 'Hier können Sie sich in Ihr Benutzerkonto einloggen',
    ( request->referer ? ( return_url => request->referer ) : () ),
    login_failed => ( var('login_failed') ? 1 : 0 ),
    robots => 'noindex,nofollow,noarchive',
    }, {
    layout => var('layout'),
    };
}
get q{/login} => \&get_login_route;
get q{/login2} => \&get_login_route if setting 'auth_route_fix';

############################################################################
# Route handler: login processing.
sub post_login_route {
  return redirect q{/} if logged_in_user;

  my $login_route = setting('auth_route_fix') ? '/login2' : '/login';

  my $user = rset('User')->search( { username => params->{username} } )->single;
  if ( !$user ) {
    var login_failed => 1;
    return forward $login_route, { return_url => params->{return_url} }, { method => 'get' };
  }

  my ( $success, $realm ) = authenticate_user( params->{username}, params->{password} );
  if ($success) {
    void_session('login');
    session logged_in_user       => params->{username};
    session logged_in_user_realm => $realm;
    $user->update( { has_failed_logins => 0, last_login_on => var('now') } );
    return redirect params->{return_url} || q{/};
  }
  else {
    $user->update( { has_failed_logins => \'has_failed_logins + 1' } );
    var login_failed => 1;
    return forward $login_route, { return_url => params->{return_url} }, { method => 'get' };
  }

  return 'TODO';
}
post q{/login} => \&post_login_route;
post q{/login2} => \&post_login_route if setting 'auth_route_fix';


############################################################################
# Route handler: login denied.
sub get_login_denied_route {
  return template 'login_denied', {
    pagesubject  => 'Zugang verweigert',
    pageabstract => 'Sie besitzen für die gewünschte Seite keine ausreichenden Rechte',
    robots       => 'noindex,nofollow,noarchive',
    }, {
    layout => var('layout'),
    };
}
get q{/login/denied} => \&get_login_route;

############################################################################
# Route handler: logout.
sub get_logout_route {
  return redirect q{/} if !logged_in_user;

  void_session('logout');
  return redirect params->{return_url} || request->referer || '/';
}
get q{/logout} => \&get_logout_route;
get q{/logout2} => \&get_logout_route if setting 'auth_route_fix';

############################################################################
# Route handler: register.
sub get_register_route {
  return redirect q{/} if logged_in_user;

  return not_found_page() if setting 'disable_register';
  return template 'register', {
    pagesubject  => 'Registrierung',
    pageabstract => 'Hier können Sie ihr Benutzerkonto erstellen.',
    robots       => 'noindex,nofollow,noarchive',
    }, {
    layout => var('layout'),
    };
}
get q{/register} => \&get_register_route;

############################################################################
# Route handler: register processing.
sub post_register_route {
  return redirect q{/} if logged_in_user;
  return not_found_page() if setting 'disable_register';
  return 'TODO';
}
post q{/register} => \&post_register_route;

############################################################################
# Route handler: register account.
sub get_register_confirmation_route {
  return not_found_page() if setting 'disable_register';
  return template 'register_confirmation', {
    pagesubject  => 'Registrierung',
    pageabstract => 'Hier können Sie ihr Benutzerkonto erstellen.',
    robots       => 'noindex,nofollow,noarchive',
    }, {
    layout => var('layout'),
    };
}
get q{/register/confirmation} => \&get_register_confirmation_route;

############################################################################
# Route handler: acp index page.
sub get_acp_route {

  my $toppages = rset('Page')->search( {
      publication_on => { not => undef },
    }, {
      order_by => [ { -desc => [qw( has_views publication_on page_id )] } ],
      rows     => 3,
    } );

  my $pendingpages = rset('Page')->search( {
      publication_on => undef,
    }, {
      order_by => [ { -desc => [qw( created_on page_id )] } ],
    } );

  my $newusers = rset('User')->search(
    undef, {
      order_by => [ { -desc => [qw( signup_on user_id )] } ],
      rows     => 3,
    } );

  return template 'acp_index', {
    category     => { category => 'ACP', category_uri => 'acp' },
    pagecategory => 'ACP',
    pageabstract =>
      'Über das Admin Control Panel (ACP) können Sie den gesamten Internetauftritt verwalten',
    robots       => 'noindex,nofollow,noarchive',
    toppages     => [ $toppages->all ],
    pendingpages => [ $pendingpages->all ],
    newusers     => [ $newusers->all ],
    }, {
    layout => var('layout'),
    };
}
get q{/acp} => require_role admin => \&get_acp_route;

############################################################################
# Route handler: generic page.
sub get_layout_route {
  return not_found_page() if !params->{layout};
  if ( params->{layout} =~ m/^(?:main|mobile)$/ ) {
    session layout => params->{layout};
    return redirect request->referer || q{/};
  }
  return not_found_page();
}
get q{/-layout-:layout} => \&get_layout_route;

############################################################################
# Route handler: generic page.
sub get_generic_page_route {

  my $generic_category = rset('Category')->search( { category_id => $GENERIC_CATID } )->single;
  my $generic_page = $generic_category->search_related(
    'pages', {
      page_uri => params->{page_uri},
    } )->single;
  return get_category_route( params->{page_uri} ) if !$generic_page;
  $generic_page->update( { has_views => \'has_views + 1' } ) if !browser_detect->robot;
  return template 'page', {
    page         => $generic_page,
    pagesubject  => $generic_page->subject,
    pageabstract => $generic_page->abstract,
    }, {
    layout => var('layout'),
    };
}
get q{/:page_uri} => \&get_generic_page_route;

############################################################################
# Route handler: category index.
sub get_category_route {
  my ($category_uri) = @_;
  my $category = rset('Category')->search( { category_uri => $category_uri } )->single;
  return any_not_found_route() if !$category;
  my $pages = $category->search_related(
    'pages', undef, {
      order_by => [ { -desc => [qw( publication_on page_id )] } ],
    } );
  return template 'category', {
    category       => $category,
    category_pages => [ $pages->all ],
    pagecategory   => $category->category,
    }, {
    layout => var('layout'),
    };
}

############################################################################
# Route handler: category page.
sub get_category_page_route {
  my $category = rset('Category')->search( { category_uri => params->{category_uri} } )->single;
  return any_not_found_route() if !$category;
  my $page = $category->search_related( 'pages', { page_uri => params->{page_uri} } )->single;
  return any_not_found_route() if !$page;
  $page->update( { has_views => \'has_views + 1' } ) if !browser_detect->robot;
  return template 'page', {
    page         => $page,
    pagecategory => $category->category,
    pagesubject  => $page->subject,
    pageabstract => $page->abstract,
    pageauthor   => $page->author->username,
    }, {
    layout => var('layout'),
    };
}
get q{/:category_uri/:page_uri} => \&get_category_page_route;

############################################################################
# Route handler: category page.
sub any_not_found_route {
  status $HTTP_STATUS_NOT_FOUND;
  return template 'not_found', {
    pagesubject  => 'Error 404',
    pageabstract => 'Die gewünschte Seite konnte nicht gefunden werden',
    }, {
    layout => var('layout'),
    };
}
any qr{.*} => \&any_not_found_route;

############################################################################
1;
## no critic ( RequirePod )
__END__
=pod

=encoding utf8

=head1 NAME

App::DancePage - App::DancePage route handlers

=head1 VERSION

This documentation describes App::DancePage within version 0.001.

=head1 DESCRIPTION

App::DancePage is a L<Perl Dancer|Dancer> powered personal homepage system
written in the Perl programming language.

This module contains the main web application route handlers. It represent
the main module of App::DancePage.

=head1 SUBROUTINES

=head2 setup

    setup;

C<setup> performs initial configuration fixes which can't realised with
environment configuration files and prepares other data if needed.

=head2 void_session

    void_session("I don't like you!");

C<void_session> takes a scalar reason as parameter and voids the current
request user session. It also creates a new session with security check
data (user agent, remote address). The reason will be printed via the
C<info> log channel.

=head1 ROUTE HANDLERS

=head2 get_index_route

    GET /

Returns the HTML content of the index page (homepage).

B<Request parameters>: No request parameters are required or used.

=head1 DIAGNOSTICS

Set Dancer's C<log> setting to C<core> to enable more detailed logging.

=head1 AUTHOR

This module has been written by BURNERSK <burnersk@cpan.org> and other
contributors.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by BURNERSK.
 
All rights reserved.

=cut
