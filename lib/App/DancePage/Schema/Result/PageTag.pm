# COPYRIGHT
package App::DancePage::Schema::Result::PageTag;
use strict;
use warnings FATAL => 'all';
use utf8;

# Import other modules.
use DBIx::Class::Candy;

############################################################################
# Table definitions:
table 'Page_Tags';

############################################################################
# Column definitions:
primary_column page_id => {
  data_type         => 'integer',
  is_auto_increment => 1,
  is_nullable       => 0,
  extra             => { unsigned => 1 },
  is_foreign_key    => 1,
};

primary_column tag_id => {
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

  $sqlt_table->add_index( name => 'Page_Tags_tag_id', fields => [qw( tag_id )] );

  return;
}

############################################################################
# Relationship definitions:
belongs_to page => 'App::DancePage::Schema::Result::Page', 'page_id',
  { is_deferrable => 1, on_delete => 'RESTRICT', on_update => 'CASCADE' };
belongs_to tag => 'App::DancePage::Schema::Result::Tag', 'tag_id',
  { is_deferrable => 1, on_delete => 'RESTRICT', on_update => 'CASCADE' };

############################################################################
# Don't forget to return a true value from the file.
1;
