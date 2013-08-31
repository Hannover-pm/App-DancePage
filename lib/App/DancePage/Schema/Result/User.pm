# COPYRIGHT
package App::DancePage::Schema::Result::User;
use strict;
use warnings FATAL => 'all';
use utf8;

use DBIx::Class::Candy (
  -components => [qw( EncodedColumn InflateColumn::DateTime Core )],
);

############################################################################
# Table definition.

table 'users';

############################################################################
# Field definition.

primary_column user_id => {
  data_type         => 'integer',
  is_nullable       => 0,
  is_auto_increment => 1,
  is_numeric        => 1,
  extra             => { unsigned => 1 },
};

column username => {
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
  encode_args         => { algorithm => 'SHA-512', format => 'hex', salt_length => 10 },
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
  is_nullable   => 0,
  is_numeric    => 1,
  extra         => { unsigned => 1 },
  default_value => 0,
};

#########################################################################
# Index definition.

unique_constraint users_idx_username => [qw( username )];

sub sqlt_deploy_hook {
  my ( $self, $sqlt_table ) = @_;
  return $sqlt_table;
}

#########################################################################
# Relation definition.

has_many userroles => 'App::DancePage::Schema::Result::UserRole', 'user_id',
  { cascade_copy => 0, cascade_delete => 0 };
many_to_many roles => 'userroles', 'role', { cascade_copy => 0, cascade_delete => 0 };

has_many pages => 'App::DancePage::Schema::Result::Page', {
  'foreign.author_id' => 'self.user_id',
  },
  { cascade_copy => 0, cascade_delete => 0 };

#########################################################################
1;
