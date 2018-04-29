#!/usr/bin/perl
# This is a test procedure for Irssi::Script::Twitch::Archon addon.
# It can be used inside irssi or with t/Irssi.pm.
# Tests with t/Irssi.pm are invoked with: prove -l -v.
# 
# The commands to load and start the addon in irssi are:
# /connect
# /join #archonthewizard
# /script load Twitch
# /twitch start -channel Archon
#
# A test can be executed after loading the module.
# The test script starts the process for the channel
# and sends test messages to the channel.
# Load addon and run test script as ttdbot:
# /connect
# /join #archonthewizard
# /script load Twitch
# /nick ttdbot
# /twitch debug do $ENV{PWD}.'/test.pl'
# /twitch debug print %{$_{'Irssi::Script::Twitch::Archon'}}
#

use warnings;
# Test mockup t/Irssi.pm is only used for prove
# It is not used from inside irssi
use lib 't';
use Irssi;
use Test::More;

BEGIN {
    our $_;
    $_ = <<"EOT";
WAVE 36 SENT. Next: SPIDERS (HORDE). Weak against: Firemages
WAVE 37 SENT. Next: SPIDERS (HORDE). Weak against: Firemages
WAVE 38 SENT. Next: SPIDERS (HORDE). Weak against: Firemages
Challenge Wave Soon!
WAVE 39 SENT. Next: BOSS WAVE NEXT! (Rock Golem (Boss)) Move to the towers!
BOSS INCOMING! Type !fill to move to the closest tower!
WAVE 40 SENT. Next: SHROOMS (BURROWING). Weak against: Alchemists (CHALLENGE: Elite)
QUESTIONABLE__ upgraded rogue to Rank 11
Arid Junction now in the lead! 60 sec to vote
45 seconds until first wave: TROLLS (UNSTOPPABLE). Weak against: Archers
WAVE 1 SENT. Next: TROLLS (UNSTOPPABLE). Weak against: Archers
WAVE 2 SENT. Next: TROLLS (UNSTOPPABLE). Weak against: Archers
Mox1991 Has Started the Challenge!
WAVE 3 SENT. Next: ORCS (ARMORED). Weak against: Rogues
WAVE 4 SENT. Next: ORCS (ARMORED). Weak against: Rogues
WAVE 5 SENT. Next: ORCS (ARMORED). Weak against: Rogues
WAVE 6 SENT. Next: SPIDERS (HORDE). Weak against: Firemages
Challenge Wave Soon!
Berserker6996 switched to Onyx
WAVE 7 SENT. Next: SPIDERS (HORDE). Weak against: Firemages (CHALLENGE: Cloaked)
WAVE 8 SENT. Next: SPIDERS (HORDE). Weak against: Firemages
WAVE 9 SENT. Next: BOSS WAVE NEXT! (Armor-Skele (Boss)) Move to the towers!
BOSS INCOMING! Type !fill to move to the closest tower!
WAVE 10 SENT. Next: GOBLINS (FAST). Weak against: FrostMages
JENNER247450 upgraded to gem Rank 7
JENNER247450 upgraded archer to Rank 13
WAVE 11 SENT. Next: GOBLINS (FAST). Weak against: FrostMages
WAVE 12 SENT. Next: GOBLINS (FAST). Weak against: FrostMages
WAVE 13 SENT. Next: SHROOMS (BURROWING). Weak against: Alchemists
Challenge Wave Soon!
WAVE 14 SENT. Next: SHROOMS (BURROWING). Weak against: Alchemists (CHALLENGE: Fast)
WAVE 15 SENT. Next: SHROOMS (BURROWING). Weak against: Alchemists
WAVE 16 SENT. Next: TROLLS (UNSTOPPABLE). Weak against: Archers
WAVE 17 SENT. Next: TROLLS (UNSTOPPABLE). Weak against: Archers
WAVE 18 SENT. Next: TROLLS (UNSTOPPABLE). Weak against: Archers
WAVE 19 SENT. Next: BOSS WAVE NEXT! (Rock Golem (Boss)) Move to the towers!
Challenge Wave Soon!
BOSS INCOMING! Type !fill to move to the closest tower!
WAVE 20 SENT. Next: ORCS (ARMORED). Weak against: Rogues (CHALLENGE: Elite)
POWERHAKIM upgraded firemage to Rank 17
[mistacat Gold: 90028, Rank 23 Ruby, Shards: 1003/9300]
Arid Junction now in the lead! 60 sec to vote
45 seconds until first wave: SPIDERS (HORDE). Weak against: Firemages
WAVE 0 SENT. Next: GIANT ANTS (ARMORED). Weak against: Rogues & Firemages
Challenge Wave Soon!
WAVE 1 SENT. Next: GIANT ANTS (ARMORED). Weak against: Rogues & Firemages (CHALLENGE: Elite)
WAVE 2 SENT. Next: GIANT ANTS (ARMORED). Weak against: Rogues & Firemages
WAVE 3 SENT. Next: ORCS (ARMORED). Weak against: Rogues
EOT

}
our $win = Irssi::active_win();
our $server = $win->{active_server};
die unless $win;
die unless $server;

$server->command('clear');
$server->command('nick ttdbot');
$server->command('join #archonthewizard');
$server->command('twitch start -channel Archon');
# timeout is 1 sec if not in irssi
local @_ = Irssi::in_irssi() ?  reverse split '\n': split '\n';
while ( my $line = shift @_ ) {
    Irssi::timeout_add_once (
        1000 + 10000 * int @_,
        sub {
            # "PRIVMSG #ttdbot :/w ttdbot !specs"
            local $_ = $line;
            note '*'.$_ unless Irssi::in_irssi();
            die unless $win;
            die unless $win->{active_server};
            die unless $win->{active_server}->{nick};
            $server->command('twitch emit event privmsg'.'@'. $_);
            return;
        },
        undef
    )
}

die if int @_;

1;
