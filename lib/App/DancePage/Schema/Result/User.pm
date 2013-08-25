# COPYRIGHT
package App::DancePage::Schema::Result::User;
use strict;
use warnings FATAL => 'all';
use utf8;

# Import other modules.
use DBIx::Class::Candy (
  -components => [qw( EncodedColumn InflateColumn::DateTime )],
);

############################################################################
# Table definitions:
table 'Users';

############################################################################
# Column definitions:
primary_column user_id => {
  data_type         => 'integer',
  is_auto_increment => 1,
  is_nullable       => 0,
  extra             => { unsigned => 1 },
};

column username => {
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 0,
};

column email => {
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 0,
};

column password => {
  data_type           => 'varchar',
  size                => 255,
  is_nullable         => 0,
  encode_column       => 1,
  encode_class        => 'Digest',
  encode_args         => { algorithm => 'SHA-256', format => 'hex', salt_length => 10 },
  encode_check_method => 'check_password',
};

column signup_on => {
  data_type   => 'datetime',
  is_nullable => 0,
};

column last_login_on => {
  data_type   => 'datetime',
  is_nullable => 1,
};

column has_failed_logins => {
  data_type     => 'integer',
  is_nullable   => 0,
  default_value => 0,
};

############################################################################
# Index definitions:
unique_constraint Users_username => [qw( username )];
unique_constraint Users_email    => [qw( email )];

sub sqlt_deploy_hook {
  my ( $self, $sqlt_table ) = @_;
  return;
}

############################################################################
# Relationship definitions:
has_many userroles => 'App::DancePage::Schema::Result::UserRole', {
  'foreign.user_id' => 'self.user_id',
  },
  { cascade_copy => 0, cascade_delete => 0 };
many_to_many roles => 'userroles', 'userroles', { cascade_copy => 0, cascade_delete => 0 };

has_many pages => 'App::DancePage::Schema::Result::Page', {
  'foreign.author_id' => 'self.user_id',
  },
  { cascade_copy => 0, cascade_delete => 0 };

has_many comments => 'App::DancePage::Schema::Result::Comment', {
  'foreign.commentator_id' => 'self.user_id',
  },
  { cascade_copy => 0, cascade_delete => 0 };

############################################################################
# Don't forget to return a true value from the file.
1;
