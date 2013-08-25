# COPYRIGHT
package App::DancePage::Schema::Result::UserRole;
use strict;
use warnings FATAL => 'all';
use utf8;

# Import other modules.
use DBIx::Class::Candy;

############################################################################
# Table definitions:
table 'User_Roles';

############################################################################
# Column definitions:
primary_column user_id => {
  data_type         => 'integer',
  is_auto_increment => 1,
  is_nullable       => 0,
  extra             => { unsigned => 1 },
  is_foreign_key    => 1,
};

primary_column role_id => {
  data_type         => 'integer',
  is_auto_increment => 1,
  is_nullable       => 0,
  extra             => { unsigned => 1 },
  is_foreign_key    => 1,
};

############################################################################
# Index definitions:
sub sqlt_deploy_hook {
  my ( $self, $sqlt_table ) = @_;

  $sqlt_table->add_index( name => 'User_Roles_role_id', fields => [qw( role_id )] );

  return;
}

############################################################################
# Relationship definitions:
belongs_to user => 'App::DancePage::Schema::Result::User', 'user_id',
  { is_deferrable => 1, on_delete => 'RESTRICT', on_update => 'CASCADE' };
belongs_to role => 'App::DancePage::Schema::Result::Role', 'role_id',
  { is_deferrable => 1, on_delete => 'RESTRICT', on_update => 'CASCADE' };

############################################################################
# Don't forget to return a true value from the file.
1;
