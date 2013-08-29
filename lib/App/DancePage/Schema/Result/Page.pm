# COPYRIGHT
package App::DancePage::Schema::Result::Page;
use strict;
use warnings FATAL => 'all';
use utf8;

# Import other modules.
use DBIx::Class::Candy (
  -components => [qw( InflateColumn::DateTime InflateColumn::Markup::Unified )],
);

############################################################################
# Table definitions:
table 'Pages';

############################################################################
# Column definitions:
primary_column page_id => {
  data_type         => 'integer',
  is_auto_increment => 1,
  is_nullable       => 0,
  extra             => { unsigned => 1 },
};

column category_id => {
  data_type      => 'integer',
  is_nullable    => 0,
  extra          => { unsigned => 1 },
  is_foreign_key => 1,
};

column author_id => {
  data_type      => 'integer',
  is_nullable    => 0,
  extra          => { unsigned => 1 },
  is_foreign_key => 1,
};

column subject => {
  data_type   => 'varchar',
  size        => 80,
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

column publication_on => {
  data_type   => 'datetime',
  is_nullable => 1,
};

column has_edits => {
  data_type     => 'integer',
  is_nullable   => 0,
  extra         => { unsigned => 1 },
  default_value => 0,
};

column last_edit_on => {
  data_type   => 'datetime',
  is_nullable => 1,
};

column has_views => {
  data_type     => 'integer',
  is_nullable   => 0,
  extra         => { unsigned => 1 },
  default_value => 0,
};

column page_uri => {
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 0,
};

############################################################################
# Index definitions:
unique_constraint Pages_uri => [qw( page_uri category_id )];

sub sqlt_deploy_hook {
  my ( $self, $sqlt_table ) = @_;

  $sqlt_table->add_index( name => 'Pages_category_id',    fields => [qw( category_id )] );
  $sqlt_table->add_index( name => 'Pages_author_id',      fields => [qw( author_id )] );
  $sqlt_table->add_index( name => 'Pages_has_views',      fields => [qw( has_views )] );
  $sqlt_table->add_index( name => 'Pages_publication_on', fields => [qw( publication_on )] );
  $sqlt_table->add_index( name => 'Pages_last_edit_on',   fields => [qw( last_edit_on )] );

  return;
}

############################################################################
# Relationship definitions:
belongs_to author => 'App::DancePage::Schema::Result::User', {
  'foreign.user_id' => 'self.author_id',
  },
  { is_deferrable => 1, on_delete => 'RESTRICT', on_update => 'CASCADE' };
belongs_to category => 'App::DancePage::Schema::Result::Category', {
  'foreign.category_id' => 'self.category_id',
  },
  { is_deferrable => 1, on_delete => 'RESTRICT', on_update => 'CASCADE' };

has_many pagetags => 'App::DancePage::Schema::Result::PageTag', 'page_id',
  { cascade_copy => 0, cascade_delete => 0 };
many_to_many tags => 'pagetags', 'tag', { cascade_copy => 0, cascade_delete => 0 };

has_many comments => 'App::DancePage::Schema::Result::Comment', {
  'foreign.page_id' => 'self.page_id',
  },
  { cascade_copy => 0, cascade_delete => 0 };

############################################################################
# Don't forget to return a true value from the file.
1;
