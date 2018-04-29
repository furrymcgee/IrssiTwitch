use strict;
use warnings;

use Test::More tests => 3;

use lib "t";
use Irssi::Script::Twitch::Archon;

ok(Irssi::Script::Twitch::Archon->new(\%_));
isa_ok( \%_, 'Irssi::Script::Twitch');
isa_ok( \%_, 'Irssi::Script::Twitch::Archon');
done_testing();
