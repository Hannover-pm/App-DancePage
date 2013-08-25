# COPYRIGHT
package App::DancePage::Schema::Result::Comment;
use strict;
use warnings FATAL => 'all';
use utf8;

# Import other modules.
use DBIx::Class::Candy (
  -components => [qw( InflateColumn::DateTime )],
);

############################################################################
# Table definitions:
table 'Comments';

############################################################################
# Column definitions:
primary_column comment_id => {
  data_type         => 'integer',
  is_auto_increment => 1,
  is_nullable       => 0,
  extra             => { unsigned => 1 },
};

column page_id => {
  data_type      => 'integer',
  is_nullable    => 0,
  extra          => { unsigned => 1 },
  is_foreign_key => 1,
};

column commentator_id => {
  data_type      => 'integer',
  is_nullable    => 0,
  extra          => { unsigned => 1 },
  is_foreign_key => 1,
};

column displayname => {
  data_type   => 'varchar',
  size        => 255,
  is_nullable => 0,
};

column message => {
  data_type   => 'text',
  is_nullable => 0,
};

column commented_on => {
  data_type   => 'datetime',
  is_nullable => 1,
};

############################################################################
# Index definitions:
sub sqlt_deploy_hook {
  my ( $self, $sqlt_table ) = @_;

  $sqlt_table->add_index( name => 'Comments_commented_on', fields => [qw( commented_on )] );

  return;
}

############################################################################
# Relationship definitions:
belongs_to author => 'App::DancePage::Schema::Result::User', {
  'foreign.user_id' => 'self.commentator_id',
  },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" };
belongs_to page => 'App::DancePage::Schema::Result::Page', {
  'foreign.page_id' => 'self.page_id',
  },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" };

############################################################################
# Don't forget to return a true value from the file.
1;
