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
    my ( $user, $role ) = @_;
    $role = $user and $user = undef if !$role;
    return 0 if !$user && !logged_in_user;
    $user = logged_in_user->username if !$user;
    return user_has_role( $user, $role ) ? 1 : 0;
  };

  $tokens->{_rset_all} = sub {
    my ( $rset, $field ) = @_;
    return $field ? [ map { $_->$field } $_[0]->all ] : [ $_[0]->all ];
  };

  return;
}
hook before_template_render => \&token_hook;

############################################################################
# Route handler: GET /acp/user
sub get_acp_user_route {
  return template 'acp_user_index';
}
get q{/acp/user} => require_role admin => \&get_acp_user_route;

############################################################################
# Route handler: GET /acp/user/list
sub get_acp_user_list_route {
  my $users = rset('User');
  return template 'acp_user_list', {
    users => [ $users->all ],
    };
}
get q{/acp/user/list} => require_role admin => \&get_acp_user_list_route;

############################################################################
# Route handler: GET /acp/user/list
sub get_acp_user_create_route {
  my $roles = rset('Role');
  return template 'acp_user_create', {
    roles => [ $roles->all ],
    };
}
get q{/acp/user/create} => require_role admin => \&get_acp_user_create_route;

############################################################################
# Route handler: POST /acp/user/list
sub post_acp_user_create_route {
  my $user = rset('User')->create( {
    username  => params->{username},
    email     => params->{email},
    password  => params->{password},
    signup_on => DateTime->now,
  } );

  my $roles = [];
  foreach my $role ( @{ ref params->{roles} ? params->{roles} : [ params->{roles} ] } ) {
    push @{$roles}, { role => $role };
  }
  $user->set_roles($roles);

  return redirect sprintf '/acp/user/%s', $user->user_id;
}
post q{/acp/user/create} => require_role admin => \&post_acp_user_create_route;

############################################################################
# Route handler: GET /acp/user/list
sub get_acp_user_edit_route {
  my $user = rset('User')->search( { user_id => params->{user_id} } )->first;
  my $roles = rset('Role');
  return not_found_route() if !$user;
  return template 'acp_user_edit', {
    user  => $user,
    roles => [ $roles->all ],
    };
}
get q{/acp/user/:user_id} => require_role admin => \&get_acp_user_edit_route;

############################################################################
# Route handler: POST /acp/user/list
sub post_acp_user_edit_route {
  my $user = rset('User')->search( { user_id => params->{user_id} } )->first;
  return not_found_route() if !$user;

  $user->update( {
    username => params->{username},
    email    => params->{email},
    ( defined params->{has_failed_logins} ? ( has_failed_logins => params->{has_failed_logins} ) : () ),
    ( params->{password}                  ? ( password          => params->{password} )          : () ),
  } );

  my $roles = [];
  foreach my $role ( @{ ref params->{roles} ? params->{roles} : [ params->{roles} ] } ) {
    push @{$roles}, { role => $role };
  }
  $user->set_roles($roles);

  return redirect sprintf '/acp/user/%s', params->{user_id};
}
post q{/acp/user/:user_id} => require_role admin => \&post_acp_user_edit_route;

############################################################################
# Route handler: GET /acp/user/list
sub get_acp_user_delete_route {
  my $user = rset('User')->search( { user_id => params->{user_id} } )->first;
  return not_found_route() if !$user;
  $user->delete;
  return redirect '/acp/user';
}
get q{/acp/user/:user_id/delete} => require_role admin => \&get_acp_user_delete_route;

############################################################################
# Route handler: GET /acp/category
sub get_acp_category_route {
  return template 'acp_category_index';
}
get q{/acp/category} => require_role admin => \&get_acp_category_route;

############################################################################
# Route handler: GET /acp/category/list
sub get_acp_category_list_route {
  my $categories = rset('Category');
  return template 'acp_category_list', {
    categories => [ $categories->all ],
    };
}
get q{/acp/category/list} => require_role admin => \&get_acp_category_list_route;

############################################################################
# Route handler: GET /acp/category/list
sub get_acp_category_create_route {
  return template 'acp_category_create';
}
get q{/acp/category/create} => require_role admin => \&get_acp_category_create_route;

############################################################################
# Route handler: POST /acp/category/list
sub post_acp_category_create_route {
  my $category = rset('Category')->create( {
    category     => params->{category},
    abstract     => params->{abstract},
    category_uri => params->{category_uri},
  } );
  return not_found_route() if !$category;
  return redirect sprintf '/acp/category/%s', $category->category_id;
}
post q{/acp/category/create} => require_role admin => \&post_acp_category_create_route;

############################################################################
# Route handler: GET /acp/category/list
sub get_acp_category_edit_route {
  my $category = rset('Category')->search( { category_id => params->{category_id} } )->first;
  return not_found_route() if !$category;
  return template 'acp_category_edit', {
    category => $category,
    };
}
get q{/acp/category/:category_id} => require_role admin => \&get_acp_category_edit_route;

############################################################################
# Route handler: POST /acp/category/list
sub post_acp_category_edit_route {
  my $category = rset('Category')->search( { category_id => params->{category_id} } )->first;
  return not_found_route() if !$category;
  $category->create( {
    category     => params->{category},
    abstract     => params->{abstract},
    category_uri => params->{category_uri},
  } );
  return redirect sprintf '/acp/category/%s', params->{category_id};
}
post q{/acp/category/:category_id} => require_role admin => \&post_acp_category_edit_route;

############################################################################
# Route handler: GET /acp/category/list
sub get_acp_category_delete_route {
  my $category = rset('Category')->search( { category_id => params->{category_id} } )->first;
  return not_found_route() if !$category;
  $category->delete;
  return redirect '/acp/category';
}
get q{/acp/category/:category_id/delete} => require_role admin => \&get_acp_category_delete_route;

############################################################################
# Route handler: GET /acp/page
sub get_acp_page_route {
  return template 'acp_page_index';
}
get q{/acp/page} => require_role admin => \&get_acp_page_route;

############################################################################
# Route handler: GET /acp/page/list
sub get_acp_page_list_route {
  my $pages = rset('Page');
  return template 'acp_page_list', {
    pages => [ $pages->all ],
    };
}
get q{/acp/page/list} => require_role admin => \&get_acp_page_list_route;

############################################################################
# Route handler: GET /acp/page/list
sub get_acp_page_create_route {
  return template 'acp_page_create';
}
get q{/acp/page/create} => require_role admin => \&get_acp_page_create_route;

############################################################################
# Route handler: POST /acp/page/list
sub post_acp_page_create_route {
  return redirect sprintf '/acp/page/%s', 'TODO';
}
post q{/acp/page/create} => require_role admin => \&post_acp_page_create_route;

############################################################################
# Route handler: GET /acp/page/list
sub get_acp_page_edit_route {
  my $page = rset('Page')->search( { page_id => params->{page_id} } );
  return not_found_route() if !$page;
  return template 'acp_page_edit', {
    page => $page,
    };
}
get q{/acp/page/:page_id} => require_role admin => \&get_acp_page_edit_route;

############################################################################
# Route handler: POST /acp/page/list
sub post_acp_page_edit_route {
  my $page = rset('Page')->search( { page_id => params->{page_id} } );
  return not_found_route() if !$page;
  return redirect sprintf '/acp/page/%s', params->{page_id};
}
post q{/acp/page/:page_id} => require_role admin => \&post_acp_page_edit_route;

############################################################################
# Route handler: GET /acp/page/list
sub get_acp_page_delete_route {
  my $page = rset('Page')->search( { page_id => params->{page_id} } );
  return not_found_route() if !$page;
  $page->delete;
  return redirect '/acp/page';
}
get q{/acp/page/:page_id/delete} => require_role admin => \&get_acp_page_delete_route;

############################################################################
# Route handler: GET /acp/tag
sub get_acp_tag_route {
  return template 'acp_tag_index';
}
get q{/acp/tag} => require_role admin => \&get_acp_tag_route;

############################################################################
# Route handler: GET /acp/tag/list
sub get_acp_tag_list_route {
  my $tags = rset('Tag');
  return template 'acp_tag_list', {
    tags => [ $tags->all ],
    };
}
get q{/acp/tag/list} => require_role admin => \&get_acp_tag_list_route;

############################################################################
# Route handler: GET /acp/tag/list
sub get_acp_tag_create_route {
  return template 'acp_tag_create';
}
get q{/acp/tag/create} => require_role admin => \&get_acp_tag_create_route;

############################################################################
# Route handler: POST /acp/tag/list
sub post_acp_tag_create_route {
  return redirect sprintf '/acp/tag/%s', 'TODO';
}
post q{/acp/tag/create} => require_role admin => \&post_acp_tag_create_route;

############################################################################
# Route handler: GET /acp/tag/list
sub get_acp_tag_edit_route {
  my $tag = rset('Tag')->search( { tag_id => params->{tag_id} } )->first;
  return not_found_route() if !$tag;
  return template 'acp_tag_edit', {
    tag => $tag,
    };
}
get q{/acp/tag/:tag_id} => require_role admin => \&get_acp_tag_edit_route;

############################################################################
# Route handler: POST /acp/tag/list
sub post_acp_tag_edit_route {
  my $tag = rset('Tag')->search( { tag_id => params->{tag_id} } )->first;
  return not_found_route() if !$tag;
  return redirect sprintf '/acp/tag/%s', params->{tag_id};
}
post q{/acp/tag/:tag_id} => require_role admin => \&post_acp_tag_edit_route;

############################################################################
# Route handler: GET /acp/tag/list
sub get_acp_tag_delete_route {
  my $tag = rset('Tag')->search( { tag_id => params->{tag_id} } )->first;
  return not_found_route() if !$tag;
  $tag->delete;
  return redirect '/acp/tag';
}
get q{/acp/tag/:tag_id/delete} => require_role admin => \&get_acp_tag_delete_route;

############################################################################
# Route handler: GET /acp
sub any_acp_route {
  return template 'acp_index';
}
any q{/acp} => require_role admin => \&any_acp_route;

############################################################################
any qr{^/acp/.*} => require_role admin => sub { 'No Way!' };

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
    rset('User')->search( { username => params->{username} } )->update( {
      last_login_on     => DateTime->now,
      has_failed_logins => 0,
    } );
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
  return not_found_route() if !$category;
  my $pages = $category->pages->search(
    undef, {
      order_by => { -desc => [qw( publication_on page_id )] },
    } );
  return template 'category', {
    pageabstract => $category->abstract,
    pagecategory => $category->category,
    category     => $category,
    pages        => [ $pages ? $pages->all : () ],
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
