# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

use lib 't';

use_ok('Irssi::Script::Twitch');
require_ok('Irssi::Script::Twitch::Archon');

