# COPYRIGHT
package App::DancePage::Schema::Result::DbInfo;
use strict;
use warnings FATAL => 'all';
use utf8;

# Import other modules.
use DBIx::Class::Candy;

############################################################################
# Table definitions:
table 'DbInfo';

############################################################################
# Column definitions:
primary_column property => {
  data_type   => 'integer',
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 0,
};

column value => {
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 1,
};

############################################################################
# Index definitions:
sub sqlt_deploy_hook {
  my ( $self, $sqlt_table ) = @_;
  return;
}

############################################################################
# Relationship definitions:

############################################################################
# Don't forget to return a true value from the file.
1;
