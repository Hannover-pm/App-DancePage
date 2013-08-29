# COPYRIGHT
package App::DancePage::Schema;
use strict;
use warnings FATAL => 'all';
use utf8;

use base 'DBIx::Class::Schema';

# Define package version. I don't use `pacakge XXXX N.NNN` syntax because
# Dist::Zilla and other modules doesn't support it yet.
BEGIN {
  our $VERSION = 2;
}

__PACKAGE__->load_namespaces;

############################################################################
# Don't forget to return a true value from the file.
1;
