# COPYRIGHT
package App::DancePage::Schema;
use strict;
use warnings FATAL => 'all';
use utf8;

BEGIN {
  our $VERSION = 1;
}

use base qw( DBIx::Class::Schema );

# Search and import schema modules.
__PACKAGE__->load_namespaces;

############################################################################
1;
