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
use Dancer (':syntax');

# Plugin configuration that can't be setup via config.yml.
BEGIN {

  # Unit Test fixes.
  if ( $ENV{TAP_VERSION} ) {
    debug 'Apply fixes: Unit Test';

    require YAML;
    my $config_hash = YAML::LoadFile('config.yml');

    $config_hash->{environment} = 'development';  # Force development environment.
    $config_hash->{session}     = 'Simple';       # Force in-memory session management.

    # Use Unit Test database.
    $config_hash->{plugins}->{DBIC}->{default} = $config_hash->{plugins}->{DBIC}->{unittest};

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

    # Use development database.
    {
      my $plugins = setting 'plugins';
      $plugins->{DBIC}->{default} = $plugins->{DBIC}->{development};
    }

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
use Dancer::Plugin::DBIC qw( schema rset );
use Dancer::Plugin::Auth::Extensible;
use DateTime;

# Define lexical constants.
use Const::Fast ('const');
const my $HTTP_STATUS_NOT_FOUND       => 404;
const my $HTTP_STATUS_FORBIDDEN       => 403;
const my $SECURITY_CSRF               => 'csrf';
const my $SECURITY_SESSION_UA         => '_security_ua';
const my $SECURITY_SESSION_IP         => '_security_ip';
const my $SECURITY_MAX_FAILED_SESSION => 3;
const my $SECURITY_MAX_FAILED_USER    => 5;
const my $GENERIC_PAGE_CATEGORY_ID    => 1;
const my $BLOG_CATEGORY_ID            => 2;

############################################################################
sub setup {

  # Setup database.
  {
    my $db_version =
      eval { int rset('DbInfo')->search( { property => 'schema_version' } )->first->value };
    my $schema_version = App::DancePage::Schema->VERSION;
    if ( !$db_version ) {
      info sprintf 'Deploying schema version %d...', $schema_version;
      schema->deploy;

      # Register schema version.
      rset('DbInfo')->create( { property => 'schema_version', value => $schema_version } );

      # Register default roles.
      rset('Role')->create( { role => $_ } )
        for (qw( admin pages_create pages_edit pages_publish pages_delete pages_comment ));

      # Register default administrative user.
      my $root_user = rset('User')->create( {
        username  => 'root',
        email     => 'root@localhost',
        password  => '!',
        signup_on => DateTime->now,
        userroles => [ { role => { role => 'admin' } } ],
      } );

      # Register default categories.
      my $generic_page_category = rset('Category')->create( {
        category_id  => $GENERIC_PAGE_CATEGORY_ID,
        category     => 'Special Pages',
        abstract     => 'Special pages which doesn\'t belong to categories.',
        category_uri => '',
      } );
      my $blog_category = rset('Category')->create( {
        category_id  => $BLOG_CATEGORY_ID,
        category     => 'Blog',
        abstract     => 'My web diary',
        category_uri => 'blog',
      } );

      # Register default pages.
      $generic_page_category->create_related(
        'pages', {
          author         => $root_user,
          subject        => 'About me',
          abstract       => 'Some information about me',
          message        => 'Here are some information about me for you.',
          publication_on => DateTime->now,
          page_uri       => 'about-me',
        } );
      $generic_page_category->create_related(
        'pages', {
          author         => $root_user,
          subject        => 'Contact',
          abstract       => 'Some contact information about me',
          message        => 'Here are some contact information about me for you.',
          publication_on => DateTime->now,
          page_uri       => 'contact',
        } );
      $blog_category->create_related(
        'pages', {
          author         => $root_user,
          subject        => 'Hello world',
          abstract       => 'This is my first post',
          message        => 'I just have installed App::DancePage and this is my first post.',
          publication_on => DateTime->now,
          page_uri       => 'hello-world',
          pagetags       => [ { tag => { tag => 'Hello World', tag_uri => 'hello-world' } } ],
          comments       => [ {
              author       => $root_user,
              displayname  => 'root',
              message      => 'This post rocks :)',
              commented_on => DateTime->now,
            },
          ],
        } );

      # Refresh tag has_entries counter.
      foreach my $tag ( rset('Tag')->all ) {
        $tag->update( { has_entries => scalar $tag->pages->all } );
      }

    }
    elsif ( $db_version != $schema_version ) {
      die sprintf 'Schema version %d found but %d is required', $db_version, $schema_version;
    }
  }

  return;
}
setup;

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

    # Check user agent.
    if ( !$session_ua ) {
      session $SECURITY_SESSION_UA => $request_ua;
    }
    elsif ( $request_ua ne $session_ua ) {
      _void_session('user agent does not match');
    }

    # Check remote address.
    if ( !$session_ip ) {
      session $SECURITY_SESSION_IP => $request_ip;
    }
    elsif ( $request_ip ne $session_ip ) {
      _void_session('remote address does not match');
    }
  }

  # Cross-Site-Request-Fogerty attack detection.
  set $SECURITY_CSRF => 0;
  if ( my $referer = request->referer ) {
    my $uri_base = request->uri_base;
    set $SECURITY_CSRF => 1 if $referer !~ m/^\Q$uri_base\E/;
  }

  # Don't return to other sites.
  if ( my $return_url = params->{return_url} ) {
    my $uri_base = request->uri_base;
    if ( $return_url !~ m{^\Q$uri_base\E|^/} ) {
      delete params->{return_url};
      info 'return_url voided';
    }
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

  # Register Dancer::Plugin::Auth::Extensible keywords.
  $tokens->{logged_in_user} = logged_in_user;
  $tokens->{user_has_role}  = sub {
    my ($role) = @_;
    return 0 unless logged_in_user;
    return user_has_role($role) ? 1 : 0;
  };

  return;
}
hook before_template_render => \&token_hook;

############################################################################
# Route handler: GET /acp
sub any_acp_route {
  content_type 'text/plain';
  return 'TODO';
}
any q{/acp}      => require_role admin => \&any_acp_route;
any qr{^/acp/.*} => require_role admin => \&any_acp_route;

############################################################################
# Route handler: GET /-\d+
sub get_permalink_route {
  my ($page_id) = splat;
  my $page = rset('Page')->search( { page_id => $page_id } )->first;
  return not_found_route() if !$page;
  return redirect sprintf '/%s', $page->page_uri if !$page->category->category_uri;
  return redirect sprintf '/%s/%s', $page->category->category_uri, $page->page_uri;
}
get qr{^/-(\d+)$} => \&get_permalink_route;

############################################################################
# Route handler: GET /robots.txt
sub get_robots_route {
  content_type 'text/plain';
  return <<'_ROBOTS_TXT_';
User-agent: *
Disallow: /acp
Disallow: /acp/*
Disallow: /login
Disallow: /login2
Disallow: /logout
Disallow: /logout2
_ROBOTS_TXT_
}
get q{/robots.txt} => \&get_robots_route;

############################################################################
# Route handler: GET /
sub get_index_route {
  return template 'index';
}
get q{/} => \&get_index_route;

############################################################################
# Route handler: GET /login
sub get_login_route {
  return redirect params->{return_url} || q{/} if logged_in_user;
  return redirect '/access-denied'
    if ( session('login_failed') || 0 ) >= $SECURITY_MAX_FAILED_SESSION;
  return template 'login', {
    pagetitle    => 'Login',
    login_failed => session('login_failed'),
    return_url   => params->{return_url},
    pagerobots   => 'noindex,nofollow,noarchive',
    };
}
get q{/login}  => \&get_login_route;
get q{/login2} => \&get_login_route;

############################################################################
# Route handler: POST /login
sub post_login_route {
  return redirect params->{return_url} || q{/} if logged_in_user;

  debug params->{return_url};

  my $has_failed_user_logins =
    int( eval { rset('User')->search( { username => params->{username} } )->first->has_failed_logins }
      || 0 );
  my $has_failed_logins = int( session('login_failed') || 0 );
  return forward q{/login}, {}, { method => 'GET' }
    if $has_failed_user_logins >= $SECURITY_MAX_FAILED_USER;
  return redirect '/access-denied' if $has_failed_logins >= $SECURITY_MAX_FAILED_SESSION;

  my ( $success, $realm ) = authenticate_user( params->{username}, params->{password} );
  if ($success) {
    _void_session('login');
    session logged_in_user       => params->{username};
    session logged_in_user_realm => $realm;
    rset('User')->search( { username => params->{username} } )->update( { has_failed_logins => 0 } );
    session login_failed => 0;
    return redirect params->{return_url} || q{/};
  }
  else {
    eval {
      rset('User')->search( { username => params->{username} } )
        ->update( { has_failed_logins => \'has_failed_logins + 1' } );
    };
    session login_failed => ++$has_failed_logins;
    return forward q{/login}, {}, { method => 'GET' };
  }

}
post q{/login}  => \&post_login_route;
post q{/login2} => \&post_login_route;

############################################################################
# Route handler: GET /access-denied
sub get_access_denied_route {
  status $HTTP_STATUS_FORBIDDEN;
  return template 'access_denied', {
    pagetitle  => 'Access Denied',
    pagerobots => 'noindex,nofollow,noarchive',
    };
}
get q{/access-denied} => \&get_access_denied_route;

############################################################################
# Route handler: GET /logout
sub get_logout_route {
  return redirect params->{return_url} || q{/} if !logged_in_user;
  _void_session('logout');
  return redirect params->{return_url} || q{/};
}
get q{/logout}  => \&get_logout_route;
get q{/logout2} => \&get_logout_route;

############################################################################
# Dynamic generic page route handler.
sub get_generic_page_route {
  my $generic_page =
    rset('Category')->search( { 'me.category_id' => $GENERIC_PAGE_CATEGORY_ID } )->search_related(
    'pages', {
      page_uri => params->{page_uri},
    } )->first;
  return get_category_route( params->{page_uri} ) if !$generic_page;
  return template 'page', {
    pagetitle    => $generic_page->subject,
    pageabstract => $generic_page->abstract,
    pagekeywords => [ map { $_->tag } $generic_page->tags->all ],
    pagecategory => $generic_page->category->category,
    pageauthor   => $generic_page->author->username,
    page         => $generic_page,
    };
}
get q{/:page_uri} => \&get_generic_page_route;

############################################################################
# Dynamic category route handler. Invoker: get_generic_page_route
sub get_category_route {
  my ($category_uri) = @_;
  my $category = rset('Category')->search( { 'me.category_uri' => $category_uri } )->first;
  my $pages = $category->pages->search(
    undef, {
      order_by => { -desc => [qw( publication_on page_id )] },
    } );
  return not_found_route() if !$category;
  return template 'category', {
    pageabstract => $category->abstract,
    pagecategory => $category->category,
    category     => $category,
    pages        => [ $pages->all ],
    };
}

############################################################################
# Dynamic category page route handler.
sub get_category_page_route {
  my $page =
    rset('Category')->search( { 'me.category_uri' => params->{category_uri} } )->search_related(
    'pages', {
      page_uri => params->{page_uri},
    } )->first;
  return not_found_route() if !$page;
  return template 'page', {
    pagetitle    => $page->subject,
    pageabstract => $page->abstract,
    pagekeywords => [ map { $_->tag } $page->tags->all ],
    pagecategory => $page->category->category,
    pageauthor   => $page->author->username,
    page         => $page,
    };
}
get q{/:category_uri/:page_uri} => \&get_category_page_route;

############################################################################
# *** LAST ROUTE HANDLER *** LAST ROUTE HANDLER *** LAST ROUTE HANDLER ***
# Not Found route handler.
sub not_found_route {
  status $HTTP_STATUS_NOT_FOUND;
  return template 'not_found', {
    pagetitle  => 'Error 404',
    pagerobots => 'noindex,nofollow,noarchive',
    };
}
any qr{.*} => \&not_found_route;

############################################################################
# Lexical routine to void the current session.
sub _void_session {
  my ($reason) = @_;
  my $old_sid = session->id;
  session->destroy;
  session $SECURITY_SESSION_UA => request->agent;
  session $SECURITY_SESSION_IP => request->address;
  info sprintf 'Session %s voided: %s', $old_sid, $reason;
  return;
}

############################################################################
# Don't forget to return a true value from the file.
1;
## no critic (RequirePod)
__END__
=pod

=encoding utf8

=cut
