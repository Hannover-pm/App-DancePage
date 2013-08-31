# COPYRIGHT
package App::DancePage::Schema::Result::Category;
use strict;
use warnings FATAL => 'all';
use utf8;

use DBIx::Class::Candy (
  -components => [qw( Core )],
);

############################################################################
# Table definition.

table 'categories';

############################################################################
# Field definition.

primary_column category_id => {
  data_type         => 'integer',
  is_nullable       => 0,
  is_auto_increment => 1,
  is_numeric        => 1,
  extra             => { unsigned => 1 },
};

column category_uri => {
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 0,
};

column category => {
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 0,
};

column abstract => {
  data_type   => 'varchar',
  size        => 150,
  is_nullable => 0,
};

#########################################################################
# Index definition.

unique_constraint categories_idx_category_uri => [qw( category_uri )];

sub sqlt_deploy_hook {
  my ( $self, $sqlt_table ) = @_;
  return $sqlt_table;
}

#########################################################################
# Relation definition.

has_many pages => 'App::DancePage::Schema::Result::Page', 'category_id',
  { cascade_copy => 0, cascade_delete => 0 };

#########################################################################
1;
