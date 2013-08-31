# COPYRIGHT
package App::DancePage::Schema::Result::Role;
use strict;
use warnings FATAL => 'all';
use utf8;

use DBIx::Class::Candy (
  -components => [qw( Core )],
);

############################################################################
# Table definition.

table 'roles';

############################################################################
# Field definition.

primary_column role_id => {
  data_type         => 'integer',
  is_nullable       => 0,
  is_auto_increment => 1,
  is_numeric        => 1,
  extra             => { unsigned => 1 },
};

column role => {
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 0,
};

#########################################################################
# Index definition.

unique_constraint roles_idx_role => [qw( role )];

sub sqlt_deploy_hook {
  my ( $self, $sqlt_table ) = @_;
  return $sqlt_table;
}

#########################################################################
# Relation definition.

has_many roleusers => 'App::DancePage::Schema::Result::UserRole', 'role_id',
  { cascade_copy => 0, cascade_delete => 0 };
many_to_many users => 'roleusers', 'role', { cascade_copy => 0, cascade_delete => 0 };

#########################################################################
1;
