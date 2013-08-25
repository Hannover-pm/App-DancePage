# COPYRIGHT
package App::DancePage::Schema::Result::Tag;
use strict;
use warnings FATAL => 'all';
use utf8;

# Import other modules.
use DBIx::Class::Candy;

############################################################################
# Table definitions:
table 'Tags';

############################################################################
# Column definitions:
primary_column tag_id => {
  data_type         => 'integer',
  is_auto_increment => 1,
  is_nullable       => 0,
  extra             => { unsigned => 1 },
};

column tag => {
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 0,
};

column has_entries => {
  data_type     => 'integer',
  is_nullable   => 0,
  extra         => { unsigned => 1 },
  default_value => 0,
};

column tag_uri => {
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 0,
};

############################################################################
# Index definitions:
unique_constraint Tags_tag     => [qw( tag )];
unique_constraint Tags_tag_uri => [qw( tag_uri )];

sub sqlt_deploy_hook {
  my ( $self, $sqlt_table ) = @_;

  $sqlt_table->add_index( name => 'Tags_has_entries', fields => [qw( has_entries )] );

  return;
}

############################################################################
# Relationship definitions:
has_many tagpages => 'App::DancePage::Schema::Result::PageTag', 'tag_id',
  { cascade_copy => 0, cascade_delete => 0 };
many_to_many pages => 'tagpages', 'page', { cascade_copy => 0, cascade_delete => 0 };

############################################################################
# Don't forget to return a true value from the file.
1;
