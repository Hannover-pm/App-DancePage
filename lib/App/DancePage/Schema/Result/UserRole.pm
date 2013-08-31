# COPYRIGHT
package App::DancePage::Schema::Result::UserRole;
use strict;
use warnings FATAL => 'all';
use utf8;

use DBIx::Class::Candy (
  -components => [qw( Core )],
);

############################################################################
# Table definition.

table 'user_roles';

############################################################################
# Field definition.

primary_column user_id => {
  data_type         => 'integer',
  is_nullable       => 0,
  is_auto_increment => 1,
  is_numeric        => 1,
  is_foreign_key    => 1,
  extra             => { unsigned => 1 },
};

primary_column role_id => {
  data_type         => 'integer',
  is_nullable       => 0,
  is_auto_increment => 1,
  is_numeric        => 1,
  is_foreign_key    => 1,
  extra             => { unsigned => 1 },
};

#########################################################################
# Index definition.

sub sqlt_deploy_hook {
  my ( $self, $sqlt_table ) = @_;
  return $sqlt_table;
}

#########################################################################
# Relation definition.

belongs_to user => 'App::DancePage::Schema::Result::User', 'user_id',
  { is_deferrable => 1, on_delete => 'RESTRICT', on_update => 'CASCADE' };
belongs_to role => 'App::DancePage::Schema::Result::Role', 'role_id',
  { is_deferrable => 1, on_delete => 'RESTRICT', on_update => 'CASCADE' };

#########################################################################
1;
