# COPYRIGHT
package App::DancePage::Schema::Result::DbInfo;
use strict;
use warnings FATAL => 'all';
use utf8;

use DBIx::Class::Candy (
  -components => [qw( Core )],
);

############################################################################
# Table definition.

table 'dbinfo';

############################################################################
# Field definition.

primary_column property => {
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 0,
};

column value => {
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 1,
};

#########################################################################
# Index definition.

sub sqlt_deploy_hook {
  my ( $self, $sqlt_table ) = @_;
  return $sqlt_table;
}

#########################################################################
1;
