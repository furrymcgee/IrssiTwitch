package Irssi::Script::Twitch;
use strict;
use warnings;
use Irssi;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


#################### main pod documentation begin ###################

=head1 NAME

  Twitch - Module for Twitch addons in irssi

=head1 DESCRIPTION

  This packages is a base for Twitch IRC addons in irssi.
  It implements a /twitch command that loads twitch addons via submodules.
  The submodule Irssi::Script::Twitch::Archon is included as example.

=head1 SYNOPSIS

  The irssi interface requires that the package file is loaded.
    /script load Twitch
  
  Start activates addon for the current window.
    /twitch start -channel Archon
  
   Run stop before starting a new addon
    /twitch stop -channel Archon
  
  Change to .irssi directory and run test with
    /twitch debug do $ENV{PWD}.'/test.pl'

  Emit a signal from script
    /twitch emit

=head1 USAGE

  The package Irssi::Script::Twitch is a parent for twitch addons.
  It delegates messages between irssi and perl scripts.
  
  Variables are stored in the global hash %_.
  As convention global storage is ordered by package names $_{__PACKAGE__}.
  There may be additional entries for other packages.
  This package uses multiple other hashes in $_{'Irssi::Script::Twitch'}.
  The keys are object and the channel name.
  
  Structure of the gloobal hash tree:
  %_ = (
      'Irssi::Script::Twitch' => { # Irssi::Script::Twitch
          channels => { }, # map object => channel
          windows => { }, # map channel => windows
          signals => { }, # map channel => events
      },
  
      'Irssi::Script::Twitch::Archon' => {}, # Addon Irssi::Script::Twitch::Archon
  )
  
  The global reference %_ is also blessed in the start method.
  This might change for multiple inheritace in the future.

  # parent package
  use parent Irssi::Script::Twitch;

  # constructor
  sub new {
    local $_ = shift;
    bless $_, __PACKAGE;
    
    # signal handler
    $_->SUPER::signal_add(
        'event privmsg' => sub { 
            # ...
            }
    )
    return $_;
  }

=head1 BUGS
=head1 SUPPORT
=head1 AUTHOR

    A. U. Thor
    CPAN ID: MODAUTHOR
    XYZ Corp.
    a.u.thor@a.galaxy.far.far.away
    http://a.galaxy.far.far.away/modules

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################

#################### subroutine header begin ####################

=head2 new

 Usage     : Constructor method called from child package
           : __PACKAGE__->SUPER::new(%_)
 Purpose   : Redirects signals between addons and irssi
 Returns   : Returns the object referencce
 Argument  : Argument is the object reference.
 Throws    : Exceptions and other anomolies
 Comment   : This uses the signal_add function of irssi
           : # Code snippet of Archon example
           : package Irssi::Script::Twitch::Archon;
           : use parent 'Irssi::Script::Twitch';
           : sub new {
           :   local $_ = pop;
           :   __PACKAGE__->SUPER::new($_);
           :   bless $_, __PACKAGE__;
           :   $_->SUPER::signal_add( 'event privmsg' => sub {
           :        Irssi::print ($channel, $nick, $msg) = @_;
           :     }
           :    )
           :   return $self;
           : }

=cut
sub new {
    local $_ = pop; 
    bless $_, __PACKAGE__;
    die unless $_;
    die unless $_ eq \%_;

    local $_ = 
    $_->{(__PACKAGE__)} = {
        windows => {}, # channel => irssi windows
        signals => {}, # channel => events
        channels => {}, # object => channel
    };

    # signal handler executes $self->{signals}->{'event privmsg'}
    my $self = $_{(__PACKAGE__)};
    Irssi::signal_add( 
        {
            'event privmsg' => sub { 
                # $VAR1 = 'Irssi::Irc::Server=HASH(0x55b3e0ddede8)'
                # $VAR2 = '#archonthewizard :!p';
                # $VAR3 = 'funcards46';
                # $VAR4 = 'funcards46@funcards46.tmi.twitch.tv';
                die caller unless (\%_)->{'Irssi::Script::Twitch'}->{windows};
                die caller unless (\%_)->{'Irssi::Script::Twitch'}->{channels};
                die caller unless (\%_)->{'Irssi::Script::Twitch'}->{signals};
                die caller unless (\%_)->{'Irssi::Script::Twitch'}->{channels}->{(\%_)->{'Irssi::Script::Twitch'}};

                my ($server, $data, $nick, $address) = @_;
                my ($channel, $msg) = split(/ :/, $data, 2);
                local $_ = $channel;
                die unless $_;
                do {warn, print $_, return} unless $self->{windows}->{$_};
                die $_ unless /$self->{windows}->{$_}->{active}->{name}/;
                die $_ unless $self->{signals};
                die $_ unless $self->{signals}->{$_}->{'event privmsg'};

                $self->{signals}->{$_}->{'event privmsg'}->($channel, $nick, $msg);
            },
            'send command' => sub {
            },
        }
    );
};
=head2 signal_add

 Usage     : Register a callback for a channel.
           : The object is used as key for channel.
           : The method must be used after
           : object is completely blessed!
 Purpose   : Register a callback for irssi signals
 Returns   : Channel nick where the signal is added
 Argument  : Hash with signal and subroutine
 Throws    : Exceptions and other anomolies
 Comment   : Example:
           : $self->SUPER::signal_add(
           : 'event privmsg' => sub {
           :    print ($msg, $nick, $address) = @_;
           :    }
           : );
 Comment   : Method registers subroutine as callbacks
=cut
sub signal_add {
    warn unless $_[0] eq \%_;
    warn, return unless $_[0]->isa(__PACKAGE__);
    
    # channel name is used as a key for the hash
    # because event privmsg gets the channel name as argument
    die if $_[0]->{(__PACKAGE__)}->{channels}->{$_[0]->{(__PACKAGE__)}};
    local $_ = Irssi::active_win();
	defined $_->{active}->{name} or warn "Irssi::active_win failed" and return;
    $_[0]->{(__PACKAGE__)}->{channels}->{$_[0]->{(__PACKAGE__)}} = $_->{active}->{name};
    $_[0]->{(__PACKAGE__)}->{windows}->{$_[0]->{(__PACKAGE__)}->{channels}->{$_[0]->{(__PACKAGE__)}}} = $_;
    
    local $_ = $_[0]->{(__PACKAGE__)};
    $_->{signals}->{$_->{channels}->{$_}}->{$_[1]} = $_[2];

    die unless $_->{channels}->{$_} eq 
    $_{'Irssi::Script::Twitch'}->{channels}->{$_{'Irssi::Script::Twitch'}} ;

    local $_ = $_->{windows}->{$_->{channels}->{$_}}->{active_server}->{nick};
    die unless $_;
    return $_;
}

=head2 signal_emit

 Usage     : Method called with /twitch emit 'event privmsg@!join'
 Purpose   : Informs irssi about internal events and sends it to server
 Returns   : Result of Irssi::signal_emit
 Argument  : Name of the signal
           : $_->signal_emit(
           :     'event privmsg',
           :     'Arid Junction now in the lead! 60 sec to vote'
           : )
 Throws    : Exceptions and other anomolies
 Comment   : Calls signal handlers of the addon then
           : sends the message to the server.

=cut
sub signal_emit {
    local $_ = shift;
    #do {use Data::Dumper; print Dumper @_, caller;};

    die unless $_ eq \%_;
    warn, return unless $_;
    warn, return unless $_->isa(__PACKAGE__);
    die unless $_->{(__PACKAGE__)}->{windows};
    die unless %{$_->{(__PACKAGE__)}->{windows}};
    die unless $_->{(__PACKAGE__)}->{windows};

    # Emit internal events and sends it to server
    do {
        local $_ = $_->{(__PACKAGE__)}->{windows}->{$_->{(__PACKAGE__)}->{channels}->{$_->{(__PACKAGE__)}}};
        die caller unless $_;
        die unless $_->{active_server};
        die unless $_->{active_server}->{nick};
        die unless $_->{active}->{name};
        
        die caller unless $_[0];
        die caller unless 2 eq int @_;

        # signal to irssi
        Irssi::signal_emit(
            shift,
            $_->{active_server}, 
            $_->{active}->{name}.' :'.$_[0],
            $_->{active_server}->{nick}, 
            $_->{active_server}->{userhost}, 
        );
    };

    #< PRIVMSG #<channel> :This is a sample message
    #> :<user>!<user>@<user>.tmi.twitch.tv PRIVMSG #<channel> :This is a sample message
    #Irssi::active_server()->send_message("#channel", "/w user message", 0);
    #Irssi::active_server()->send_raw("PRIVMSG #channel :/w user text");
    do {
        die unless $_ eq \%_;
        die unless $_->isa(__PACKAGE__);
        die unless $_->{(__PACKAGE__)};
        die unless $_->{(__PACKAGE__)}->{windows};
        die unless $_->{(__PACKAGE__)}->{channels}->{$_->{(__PACKAGE__)}};
        die unless $_->{(__PACKAGE__)}->{windows}->{$_->{(__PACKAGE__)}->{channels}->{$_->{(__PACKAGE__)}}};

        local $_ = $_->{(__PACKAGE__)}->{windows}->{$_->{(__PACKAGE__)}->{channels}->{$_->{(__PACKAGE__)}}};
        die unless $_;
        return unless $_->{active_server};
        return unless $_->{active};
        return unless $_->{active}->{name};

        die unless int @_ eq 1;
        # send_message $target, $msg, $target_type
        $_->{active_server}->send_message(
            $_->{active}->{name}, $_[0], 0
        ) if 1; # if false do not send message to server
    };
};

=head2 timeout_add_once
 Usage     : How to use this function/method
 Purpose   : What it does
 Returns   : What it returns
 Argument  : What it wants to know
 Throws    : Exceptions and other anomolies
 Comment   : This is a sample subroutine header.
           : It is polite to include more pod and fewer comments.
=cut
sub timeout_add_once {
    shift;
    Irssi::timeout_add_once(shift,shift,shift);
}

=head2 DESTROY

 Usage     : How to use this function/method
 Purpose   : What it does
 Returns   : What it returns
 Argument  : What it wants to know
 Throws    : Exceptions and other anomolies
 Comment   : This method only deletes the channel.
           : Signal handlers can not be removed.
           : Thats why this our %_ object is reused.
=cut
sub DESTROY {
    print __PACKAGE__;
    local $_ = shift;
    die unless $_;
    die unless $_->{(__PACKAGE__)};
    die unless $_->{(__PACKAGE__)}->{channels};
    die unless $_->{(__PACKAGE__)}->{channels}->{$_->{(__PACKAGE__)}};
    die unless $_->{(__PACKAGE__)}->{signals};
    die unless $_->{(__PACKAGE__)}->{signals}->{ 
    $_->{(__PACKAGE__)}->{channels}->{$_->{(__PACKAGE__)}}
    };

    die unless $_->{(__PACKAGE__)}->{signals}->{
    $_->{(__PACKAGE__)}->{channels}->{$_->{(__PACKAGE__)}}
    }->{'event privmsg'};
    do {
        delete $_->{(__PACKAGE__)}->{windows};
        delete $_->{(__PACKAGE__)}->{channels};
        delete $_->{(__PACKAGE__)}->{signals};
    } if 0;
}

# custom irssi commands
# command options as hash and string from command_parse_options()
for my $cmd ( [
        'twitch',
        sub { 
            Irssi::command_runsub(
                'twitch', shift, shift, shift
            )
        },
        'Twitch',
        undef,
        <<EOF
Manage twitch addons with subcommands.

Example for #archonthewizard:
Join a channel and start the script.
/join #archonthewizard
/twitch start -channel Archon
/twitch emit -channel Archon !join
EOF
        ,
    ], [ 
        'twitch debug',
        sub { 
            eval shift 
        },
        'Twitch',
        undef,
        <<'EOF'
Executes perl debug command. Command '/twitch debug print %{$_{"Irssi::Script::Twitch"}}' prints the package state.
EOF
    ], [ 
        #/twitch emit event privmsg@!p
        'twitch emit', sub {
            warn, return unless $_[0];
            warn, return unless $_[1];
            shift;
            warn, return unless (\%_)->isa(__PACKAGE__);
            local @_ = split('@', shift);
            (\%_)->signal_emit( @_ );
        },
        "Twitch",
        '+channel -option',
        <<EOF
Sends a signal after calling signal handlers of the script.
Example: /twitch emit 'event privmsg\@text'
EOF
        ,
    ], [ 
        'twitch start',
        # command loads addon
        # run only one instance
        # signals dont send caller information
        # arguments from option parser
        sub {
            Irssi::print('Starting Twitch addon '.$_[0]->{channel} .'.');
            Irssi::print('Emit messages with /twitch emit event privmsg@...');
            warn, return unless defined $_[0];
            warn, return unless eval 'require '.__PACKAGE__.'::'.$_[0]->{channel};
            die $@ if $@;

            # unique value reference for subroutines
            local $_ = eval __PACKAGE__.'::'.$_[0]->{channel}.'->new(\\%_)' or warn, return;
            die unless $_ eq \%_;
            die $@ if $@;
            die unless $_;
            die unless $_->isa(__PACKAGE__);
            die $_ unless $_->isa(__PACKAGE__.'::'.$_[0]->{channel});

            Irssi::print('Twitch '.$_[0]->{channel}.' started');
        },
        'Twitch',
        '+channel -option',
        <<EOF
Activate twitch addon. Currently only one single instance is supported.
EOF
        ,
    ], [
        'twitch stop',
        sub {
            (\%_)->DESTROY();
        },
        'Twitch',
        '+channel -option',
        <<EOF
Deactivate twitch addon.
EOF
        ,
    ],
) {
    if (@$cmd[3]) {
        Irssi::command_bind( @$cmd[0], sub { 
                local @_ = Irssi::command_parse_options(@$cmd[0], shift);
                @$cmd[1]->( @_ )
            }, @$cmd[2]
        );
        Irssi::command_set_options(@$cmd[0], @$cmd[3]);
    } else {
        Irssi::command_bind( @$cmd[0], @$cmd[1], @$cmd[2]);
    }

    # https://github.com/shabble/irssi-docs/wiki/Guide#Provide-Help
    Irssi::command_bind( 'help', sub {
            if ($_[0] eq @$cmd[0]) {
                Irssi::print(
                    @$cmd[3] ?
                    join ('Options: ', @$cmd[4], @$cmd[3]) :
                    @$cmd[4],
                    MSGLEVEL_CLIENTCRAP
                );
                Irssi::signal_stop();
            }
        }
    )
}

#################### subroutine header end ####################

__PACKAGE__;

# The preceding line will help the module return a true value

