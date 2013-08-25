# COPYRIGHT
package App::DancePage::Schema::Result::Category;
use strict;
use warnings FATAL => 'all';
use utf8;

# Import other modules.
use DBIx::Class::Candy (
  -components => [qw( InflateColumn::DateTime )],
);

############################################################################
# Table definitions:
table 'Categories';

############################################################################
# Column definitions:
primary_column category_id => {
  data_type         => 'integer',
  is_auto_increment => 1,
  is_nullable       => 0,
  extra             => { unsigned => 1 },
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

column category_uri => {
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 0,
};

############################################################################
# Index definitions:
unique_constraint Categories_category     => [qw( category )];
unique_constraint Categories_category_uri => [qw( category_uri )];

sub sqlt_deploy_hook {
  my ( $self, $sqlt_table ) = @_;
  return;
}

############################################################################
# Relationship definitions:
has_many pages => 'App::DancePage::Schema::Result::Page', {
  'foreign.category_id' => 'self.category_id',
  },
  { cascade_copy => 0, cascade_delete => 0 };

############################################################################
# Don't forget to return a true value from the file.
1;
