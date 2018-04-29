# Packages must be loaded in irssi to use the irssi interface.
# It is important package and file names are Irssi::Script::Twitch and Twitch.pm.
# All addons inherit the Irssi::Script::Twitch package and 
# use the base classe as interface to Irssi.
# See Archon.pm for example.
#
# This module manages all twitch addons
# see /help twitch

use Irssi::Script::Twitch 

Irssi::print('Loaded Irssi::Script::Twitch.');
Irssi::print('Use command /twitch for help.');
