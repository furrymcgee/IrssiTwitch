use strict;
use warnings;

use File::Basename;
use Test::More tests => 1;

use lib 't';

use Irssi;

SKIP:{
    skip ('in irssi', 1) if Irssi::in_irssi();
    ok(do 'scripts/test.pl');
};
