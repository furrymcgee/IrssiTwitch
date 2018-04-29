# dummy library for irssi api
package Irssi;

use warnings;
use strict;

use Test::More;
use Data::Dumper;

use feature qw( state);

diag "RANDOM: ".srand $ENV{RANDOM};

$|++;

BEGIN {
  use Exporter qw(import);
  our @EXPORT = qw(
  signal_add_first
  signal_stop
  channel_find
  command_bind
  command_runsub
  servers
  windows
  window_item_find
  timeout_add
  timeout_remove
  active_win
  get_active_name
  MSGLEVEL_CLIENTCRAP
  );
}

sub MSGLEVEL_CLIENTCRAP { __LINE__ };

sub signal_stop { __LINE__ };

sub channel_find {
    state $channel = Irssi::Channel->new;
    return $channel;
}

sub active_win {
    return windows();
}

sub active_server{
    return servers();
}

sub signal_add_first { 
}

sub signal_add {
    local @_ = %{(shift)};
    while ( local $_ = shift ) {
        (\%_)->{(__PACKAGE__)}->{$_} = shift;
    }
}

#see sub command
sub command_parse_options {
    local ($_, @_) = @_;
    return /twitch start/
    ? do {
        ( { channel => 'Archon' }, '' )
    }
    : /twitch emit/ 
    ? do {
        ( {}, $_[0] )
    } : die join '~', caller, $_;
}

sub command_runsub {
    die unless $_{twitch};
    die unless $_[0] eq 'twitch';
    die unless $_{'twitch'};
    die unless $_{$_[0]};
    return unless defined $_[1];
    die unless shift eq 'twitch';
    return if not defined $_{'twitch '.$_[0]};
    $_{'twitch '.$_[0]}->($_[1]);
}
sub command_bind {
    # command is called from Irssi::Script::Twitch
    $_{'Irssi'} //= {};
    die caller unless $_{(__PACKAGE__)};
    die unless __PACKAGE__ eq 'Irssi';
    $_{'Irssi'}->{$_[0]} = $_[1];
}

sub command_set_options {
}

sub in_irssi{
    0;
}

sub servers {
    state $server = Irssi::Server->new;
    return $server;
}

sub windows {
    state $window = Irssi::Window->new;
    return $window;
}

sub window_item_find {
    state $witem=Irssi::WindowItem->new;
    return $witem;
}

sub print {
	# Only print in irssi there was a problem in cleanup
	# at /usr/share/perl5/Test2/API.pm line 220 during global destruction.
}

# emit signal of irssi event
sub signal_emit {
    #note $_[2];
    my ($event, $server, $data, $nick, $address) = (shift, @_);
    my ($channel, $msg) = split(/ :/, $data, 2);
    die unless %{(\%_)->{(__PACKAGE__)}};
    local $_ = (\%_)->{(__PACKAGE__)};
    die caller unless $_;
    die caller unless %{(\%_)->{'Irssi::Script::Twitch'}};
    die caller unless %{(\%_)->{'Irssi::Script::Twitch'}->{windows}->{$channel}};
    die caller unless (\%_)->{'Irssi::Script::Twitch'}->{signals}->{$channel}->{$event};
    die caller unless $_->{$event};
    $_->{$event}->(@_);
}

sub timeout_remove {
    $_[0] = undef;
}

sub timeout_add_once {
    state $i = 1;

    die if $SIG{ALARM};
    state $self = {
        func => undef,
        data => undef,
    };

    $self->{time} = shift;
    $self->{func} = shift;
    $self->{data} = shift;
    if ($i) {
        $i=0;
        $SIG{ALRM} = sub { 
            die if $SIG{ALARM};
            #note $_, %_;
            die unless $self->{func};
            $self->{func}->($self->{data});
            $SIG{ALRM} = undef;
        };
        # wait
        alarm 1;
        while ($SIG{ALRM}) { };
        $i=1;
    } else {
        $self->{func}->($self->{data});
    }

    return undef;
}

package Irssi::Server;
use Test::More;
use Data::Dumper;
use feature 'state';

sub new {
    my $class = shift;
    my $self = {
        nick => 'ttdbot',
        address  => "127.0.0.1",
    };
    bless($self, $class);
    return($self);
}

sub send_message {
    #note join ' >> ', @_;
    local $_ = $_[2];
    return  $_;
}

# see command_bind
sub command{
    die unless require Irssi::Script::Twitch::Archon;
    die unless $_{'Irssi'};
    local $_= pop;
    /(?<=^twitch start).*$/
    ? do {
        $_{'Irssi'}->{'twitch start'}->('-channel Archon xzxz')
    } :
	/(?<=^twitch emit )event privmsg@.*$/ 
    ? do {
        $_{'Irssi'}->{'twitch emit'}->( $& );
    } :
	/clear|nick|join/ 
    ? do {
    } : die $_;
}

sub send_raw_now {
    local $_ = $_[1];
    return  $_;
}

package Irssi::WindowItem;

sub new {
    my $class = shift;
    die unless $Irssi::Script::Twitch::_{'channel'};
    die;
    my $self = {
        name => $Irssi::Script::Twitch::_{'channel'},
        server => Irssi::servers(),
    };
    bless($self, $class);
    return($self);
}

sub window {
    return Irssi::windows();
}

package Irssi::Channel;

sub new {
    my $class = shift;
    my $self = {
        name => '#archonthewizard'
    };
    bless($self, $class);
    return($self);
}

package Irssi::Window;

sub new {
    my $class = shift;
    my $self = {
        active_server => Irssi::servers(),
        active => Irssi::channel_find(),
        name => '#local',
    };
    bless($self, $class);
    return($self);
}

sub command {
    $_{$_[1]}->($_);
}

sub get_active_name {
    return Irssi::window_item_find();
}

1;
