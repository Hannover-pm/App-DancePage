# COPYRIGHT
package App::DancePage::Schema::Result::Page;
use strict;
use warnings FATAL => 'all';
use utf8;

use DBIx::Class::Candy (
  -components => [qw( InflateColumn::DateTime InflateColumn::Markup::Unified Core )],
);

############################################################################
# Table definition.

table 'pages';

############################################################################
# Field definition.

primary_column page_id => {
  data_type         => 'integer',
  is_nullable       => 0,
  is_auto_increment => 1,
  is_numeric        => 1,
  extra             => { unsigned => 1 },
};

column page_uri => {
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 0,
};

column category_id => {
  data_type      => 'integer',
  is_nullable    => 0,
  is_numeric     => 1,
  is_foreign_key => 1,
  extra          => { unsigned => 1 },
};

column subject => {
  data_type   => 'varchar',
  size        => 50,
  is_nullable => 0,
};

column abstract => {
  data_type   => 'varchar',
  size        => 150,
  is_nullable => 0,
};

column message => {
  data_type   => 'text',
  is_nullable => 0,
  is_markup   => 1,
  markup_lang => 'markdown',
};

column author_id => {
  data_type      => 'integer',
  is_nullable    => 1,
  is_numeric     => 1,
  is_foreign_key => 1,
  extra          => { unsigned => 1 },
};

column created_on => {
  data_type   => 'datetime',
  is_nullable => 0,
};

column publication_on => {
  data_type   => 'datetime',
  is_nullable => 1,
};

column has_edits => {
  data_type     => 'integer',
  is_nullable   => 0,
  is_numeric    => 1,
  extra         => { unsigned => 1 },
  default_value => 0,
};

column last_editor_id => {
  data_type      => 'integer',
  is_nullable    => 1,
  is_numeric     => 1,
  is_foreign_key => 1,
  extra          => { unsigned => 1 },
};

column last_edit_on => {
  data_type   => 'datetime',
  is_nullable => 1,
};

column has_views => {
  data_type     => 'integer',
  is_nullable   => 0,
  is_numeric    => 1,
  extra         => { unsigned => 1 },
  default_value => 0,
};

#########################################################################
# Index definition.

unique_constraint pages_idx_page_uri => [qw( page_uri category_id )];

sub sqlt_deploy_hook {
  my ( $self, $sqlt_table ) = @_;

  $sqlt_table->add_index( name => 'pages_idx_publication_on', fields => [qw( publication_on )] );
  $sqlt_table->add_index( name => 'pages_idx_last_edit_on',   fields => [qw( last_edit_on )] );
  $sqlt_table->add_index( name => 'pages_idx_has_views',      fields => [qw( has_views )] );

  return $sqlt_table;
}

#########################################################################
# Relation definition.

belongs_to category => 'App::DancePage::Schema::Result::Category', 'category_id',
  { is_deferrable => 1, on_delete => 'RESTRICT', on_update => 'CASCADE' };

belongs_to author => 'App::DancePage::Schema::Result::User', {
  'foreign.user_id' => 'self.author_id',
  },
  { is_deferrable => 1, on_delete => 'RESTRICT', on_update => 'CASCADE' };

belongs_to last_editor => 'App::DancePage::Schema::Result::User', {
  'foreign.user_id' => 'self.last_editor_id',
  },
  { is_deferrable => 1, on_delete => 'RESTRICT', on_update => 'CASCADE' };

#########################################################################
1;
