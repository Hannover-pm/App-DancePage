# COPYRIGHT
package App::DancePage::Schema::Result::Role;
use strict;
use warnings FATAL => 'all';
use utf8;

# Import other modules.
use DBIx::Class::Candy (
  -components => [qw( InflateColumn::DateTime )],
);

############################################################################
# Table definitions:
table 'Roles';

############################################################################
# Column definitions:
primary_column role_id => {
  data_type         => 'integer',
  is_auto_increment => 1,
  is_nullable       => 0,
  extra             => { unsigned => 1 },
};

column role => {
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 0,
};

############################################################################
# Index definitions:
unique_constraint Roles_role => [qw( role )];

sub sqlt_deploy_hook {
  my ( $self, $sqlt_table ) = @_;
  return;
}

############################################################################
# Relationship definitions:
has_many roleusers => 'App::DancePage::Schema::Result::UserRole', {
  'foreign.role_id' => 'self.role_id',
  },
  { cascade_copy => 0, cascade_delete => 0 };
many_to_many users => 'roleusers', 'roleusers', { cascade_copy => 0, cascade_delete => 0 };

############################################################################
# Don't forget to return a true value from the file.
1;
