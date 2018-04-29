#!/usr/bin/perl
# vim: sw=4 fdm=indent:
use warnings;
package Irssi::Script::Twitch::Archon;
use parent 'Irssi::Script::Twitch';

#################### main pod documentation begin ###################
## Below is the stub of documentation for your module.
## You better edit it!


=head1 NAME

Archon - Module for Twitch

=head1 SYNOPSIS

  use Archon;
  blah blah blah


=head1 DESCRIPTION

Irssi module for twitch.tv/archonthewizard

=head1 USAGE

/msg #ttdbot /w ttdbot !specs
/script exec Irssi::active_server()->send_raw_now("PRIVMSG #ttdbot :/w ttdbot !specs")


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

 Usage     : Constructor method is called on load
           : After command /twitch start -channel Archon
           : this is called Irssi::Script::Twitch::Archon->new(\%_)
 Purpose   : Bless hash representing our object
 Returns   : New blessed hash of the object
 Argument  : Hash reference for bless
 Throws    : Exceptions and other anomolies
 Comment   : This is executed via Irssi command "/twitch start -channel Archon"

=cut
sub new {
    local $_ = pop;
    die unless $_;
    die unless $_ eq \%_;
    __PACKAGE__->SUPER::new($_);
    die unless $_->{'Irssi::Script::Twitch'};
    die unless $_->{'Irssi::Script::Twitch'}->{windows};
    die unless $_->{'Irssi::Script::Twitch'}->{channels};
    
    bless $_, __PACKAGE__;

    $_->{(__PACKAGE__)} = {
        challenge => undef,
        class => undef,
        command => undef, # last command
        enemy => undef,
        map => undef,
        prefix => undef,
        ttdbot => 'ttdbot',
        tag => undef,
        time => [ time, time ],
        tower => '!1', # first tower
        wave => undef, # set to zero after start
    };

    # bind $base and $self in a closure for privmsg callback
    my $base = $_;
    my $self = $_->{(__PACKAGE__)};
    
    # signal add returns the channel name
    $self->{prefix} 
    = $_->SUPER::signal_add(
        'event privmsg' => sub {
            die unless $self;
            die unless $base;
            die unless $base eq \%_;
            die caller unless $base->isa(__PACKAGE__);
            do {print "Waiting for timeout ...", return} if $self->{tag} and not $self->{command};

            local $_ = undef;

            $self->{tower} = "!" . (
                int rand 5 ?
                (6 + int rand 7) :
                (1 + int rand 7)
            ) if 
            not $self->{tower} or 
            not int rand 14 or 
            $self->{command} && 
            $self->{command} =~ /!p/;

            my ($channel, $nick, $msg) = @_;

            die if defined $_ and not $_;
            # check if actions required
            $_ //= 
            do {
                die if $_;
                shift, $_ = shift;
                die unless $_;
                die unless $self->{ttdbot};
                die unless $self->{prefix};

                die unless $base->{'Irssi::Script::Twitch'}->{windows}->{$base->{'Irssi::Script::Twitch'}->{channels}->{$base->{'Irssi::Script::Twitch'}}};
                die unless $base->{'Irssi::Script::Twitch'}->{windows}->{$base->{'Irssi::Script::Twitch'}->{channels}->{$base->{'Irssi::Script::Twitch'}}}->{active_server}->{nick};
                 
                /$self->{ttdbot}/ ? 
                do {
                    die unless %_;
                    #print join ':::::', $_, @_, join '',caller;
                    
                    # ignore my own commands
                    local $_ = shift;
                    return if /^!/;
                    # return if $base->{'Irssi::Script::Twitch'}->{windows}->{$base->{'Irssi::Script::Twitch'}->{channels}->{$base->{'Irssi::Script::Twitch'}}}->{active_server}->{nick} =~ /ttdbot/;

                    local @_ = split /[#: ()!-.]/;
                    die $_ unless int @_;

                    return if grep /Challenge|Rank/, map { $_ if defined $_} @_;

                    local $_ = shift;
                    die unless defined $_;

                    # Set enemy and time but not wave because boss waves have no number
                    #WAVE 8 SENT. Next: SKELETONS (NORMAL). Weak against: None
                    #WAVE 9 SENT. BOSS WAVE NEXT! (Minotaur (Boss)) Move to the towers!
                    #BOSS INCOMING! Type !fill to move to the closest tower!
                    $_ = /WAVE|BOSS/ ?
                    do {
                        die unless $self->{tower};
                        shift @{$self->{time}}, push @{$self->{time}}, time;
                        do {
                            Irssi::print( 'Waiting for a new game ...' );
                            return;
                        } unless $self->{class};

                        die unless $self->{tower};
                        
                        do {
                            shift @{$self->{time}}, push @{$self->{time}}, time;
                        } unless /WAVE/ and $self->{wave} % 10 eq 9;

                        @_ = reverse @_;
                        $self->{challenge} = $_[2] =~ /CHALLENGE/ ? shift : undef;
                        @_ = reverse @_;
                        $self->{enemy} = $_[5] =~ /BOSS/ ? $_[10] : $_[5] unless /BOSS/;

                        $_ = /WAVE/ ? 
                        do {
                            local $_ = int shift;

                            do {
                                warn 'GAME OVER', return, die;
                            } if ( defined $self->{map} and $self->{wave} > $_ );
                            
							$self->{wave} = $_, undef;
                        } : 
                        /BOSS/ ? 
                        do { 
                            shift @{$self->{time}}, push @{$self->{time}}, time;
                            warn unless $self->{command};
                            warn unless $self->{tower};
                            defined $self->{command} ? do {
                                Irssi::timeout_remove($self->{tag}) if $self->{tag};
                                $self->{tag} = undef;
                                $self->{tower};
                            } : undef;
                        } : die;
                        $_;
                    } : 
                    /Arid/ ?
                    do {
                        local $_ = (
                            $self->{map} and $self->{class}
                        ) ?
                        do {
                            warn "GAME OVER!!";
                            return $base->DESTROY();
                        } :
                        do {
                            pop, pop, pop, local $_ = pop;
                            $_ eq 60 ?
                            do {
                                $self->{map} = shift;
                                $_ = '!map' . int 1 + rand 9;
                            } :
                            do { warn, undef }
                        }
                    } : 
                    /BONUS/ ?
                    do {
                        undef
                    } : 
                    do {
                        local $_ = shift;
                        /seconds/ ?
                        do {
                            warn unless $self->{map};
                            warn, return if $self->{tag};
                            warn "GAME OVER!", return $base->DESTROY() if $self->{wave};
                            warn, return if $self->{class};

                            $self->{wave} = 0;
                            $self->{time} = [ time, time ];

                            local @_ = ('alchemist', 'frostmage', 'firemage', 'rogue', 'bard'); 
                            local $_ = '!'.$_[int rand int @_];

                            $self->{class} = 
                            /alchemist/ ? 
                            sub {
                                (
                                    $_[0] && $_[0] =~ join ('|',
                                        'GIANT',
                                        'ORCS',
                                        'SHROOMS',
                                        'SKELETONS',
                                        'TROLLS',
                                    ) ? 1<<0 : 0
                                ) | (
                                    $_[1] && $_[1] =~ join ('|',
                                        'Armored',
                                        'Cloaked',
                                        'Elite',
                                        'Horde',
                                    ) ? 1<<1 : 0
                                ) | (
                                    $_[0] && $_[0] =~ join ('|',
                                        'Armor',
                                        'Dragon',
                                        'Minotaur',
                                        'Rock',
                                    ) ? 1<<2 : 0
                                )
                            } : 
                            /archer/ ? 
                            sub {
                                (
                                    $_[0] && $_[0] =~ join ('|',
                                        'GOBLINS',
                                        'ORCS',
                                        'SHROOMS',
                                        'SKELETONS',
                                        'TROLLS',
                                    ) ? 1<<0 : 0
                                ) | (
                                    $_[1] && $_[1] =~ join ('|',
                                        'Armored',
                                        'Cloaked',
                                        'Elite',
                                        'Fast',
                                    ) ? 1<<1 : 0
                                ) | (
                                    $_[0] && $_[0] =~ join ('|',
                                        'Armor',
                                        'Dragon',
                                        'Minotaur',
                                        'Rock',
                                    ) ? 1<<2 : 0
                                ) 
                            } : 
                            /bard/ ? 
                            sub {
                                (
                                    $_[0] && $_[0] =~ join ('|',
                                        'GIANT',
                                        'GOBLINS',
                                        'ORCS',
                                        'SKELETONS',
                                        'SPIDERS',
                                        'SHROOMS',
                                        'TROLLS',
                                    ) ? 1<<0 : 0
                                ) | (
                                    $_[1] && $_[1] =~ join ('|',
                                        'Armored',
                                        'Elite',
                                        'Fast',
                                        'Horde',
                                    ) ? 1<<1 : 0
                                ) | (
                                    $_[0] && $_[0] =~ join ('|',
                                        'Armor',
                                        'Dragon',
                                        'Minotaur',
                                        'Rock',
                                    ) ? 1<<2 : 0
                                )
                            } : 
                            /firemage/ ? 
                            sub {
                                (
                                    $_[0] && $_[0] =~ join ('|',
                                        'GIANT',
                                        'GOBLINS',
                                        'SHROOMS',
                                        'SKELETONS',
                                        'SPIDERS',
                                    ) ? 1<<0 : 0
                                ) | (
                                    $_[1] && $_[1] =~ join ('|',
                                        'Armored',
                                        'Cloaked',
                                        'Fast',
                                        'Horde',
                                    ) ? 1<<1 : 0
                                ) | (
                                    $_[0] && $_[0] =~ join ('|',
                                        'Armor',
                                        'Dragon',
                                        'Minotaur',
                                        'Rock',
                                    ) ? 1<<2 : 0
                                )
                            } : 
                            /frostmage/ ? 
                            sub {
                                (
                                    $_[0] && $_[0] =~ join ('|',
                                        'GIANT',
                                        'GOBLINS',
                                        'ORCS',
                                        'SKELETONS',
                                    ) ? 1<<0 : 0
                                ) | (
                                    $_[1] && $_[1] =~ join ('|',
                                        'Armored',
                                        'Elite',
                                        'Fast',
                                        'Horde',
                                        'Cloaked',
                                    ) ? 1<<1 : 0
                                ) | (
                                    $_[0] && $_[0] =~ join ('|',
                                        'Armor',
                                        'Dragon',
                                        'Minotaur',
                                        'Rock',
                                    ) ? 1<<2 : 0
                                )
                            } : 
                            /highpriest/ ? 
                            undef :
                            /rogue/ ?
                            sub {
                                (
                                    $_[0] && $_[0] =~ join ('|',
                                        'GIANT',
                                        'GOBLINS',
                                        'ORCS',
                                        'SHROOMS',
                                        'SKELETONS',
                                        'TROLLS',
                                    ) ? 1<<0 : 0
                                ) | (
                                    $_[1] && $_[1] =~ join ('|',
                                        'Armored',
                                        'Cloaked',
                                        'Elite',
                                        'Fast',
                                        'Horde',
                                    ) ? 1<<1 : 0
                                ) | (
                                    $_[0] && $_[0] =~ join ('|',
                                        'Armor',
                                        'Dragon',
                                        'Minotaur',
                                        'Rock',
                                    ) ? 1<<2 : 0
                                )
                            } : 
                            /trapper/ ?
                            undef : undef, $_
                        } : 
                        do {
                            local $_ = /merc/i ? shift : $_;

                            $_ =
                            /Gold/ ?
                            do {
                                undef
                            } : 
                            do {
                                local $_ = pop;
                                $_ =
                                /LUCK/ ?
                                do { 
                                    undef
                                } :
                                /assassin|bard|bombermage|bowman|deathdealer|falconeer|icemage|knifethrower|lightningmage|minstrel|necromancer|ninja|plaguedoctor|potionmaster|pyromancer|scout|sniper|stormmage|trickster|shockmage/ ?
                                do { 
                                    undef
                                } :
                                /Onyx|Ruby|Citrine|Emerald/ ?
                                do { 
                                    undef
                                } :
                                /power|allies|elemental|golem/ ?
                                do { 
                                    undef
                                } :
                                /Towers/ ?
                                do { 
                                    undef
                                } :
                                /Prime/ ?
                                do { 
                                    undef
                                } :
                                /vote/ ?
                                do {
                                    warn "GAME OVER!!";
                                    return $base->DESTROY();
                                } :
                                /Archers/ ?
                                do { 
                                    warn and return
                                } :
                                do {
                                    local $_ = pop;
                                    /Orcs|Trolls|Goblins|Spiders|Shrooms|Ants|Skeletons/ ?
                                    do { 
                                        warn, undef
                                    } :
                                    do {
                                        warn, return
                                    }
                                }
                            }
                        }
                    };

                    warn $_ if defined $_ and not $_;
                    warn $_,@_ if defined $_ and /^[[:digit:]]/;

                    $_ //= 
                    $self->{class} ? 
                    do {
                        # if enemy go to tower else train
                        $_ = $self->{class}->($self->{enemy}, $self->{challenge});
                       
                        $_ = $_ ? 
                        do {
                            die unless $self->{tower};
                            local $_ = (not $self->{tag} and int rand (
                                    ( $self->{wave} % 10 < 6) ?
                                    10 * $_ : 
                                    1 * $_ * ( 1 +  not int $self->{wave} % 10 % 3 )
                                )) ?
                            $self->{tower} : 
                            undef;
                        } : 
                        ( not $self->{tag} ) ? 
                        do {
                            # train or power up
                            local $_ = $self->{command};
                            local $_ = (
                                $_ and $self->{wave} % 10 and
                                not int 0.01 * rand ($self->{wave} ) and
                                not /!p/ and 
                                $self->{command} =~ /!t|![[:digit:]]+/
                            ) ? /!t/ ? '!p' : '!t' : undef;
                        } :
                        do {
                            ! $self->{tag} ? 
                            do {
                                # train or power up
                                local $_ = $self->{command};
                                local $_ = (
                                    $_ and $self->{wave} % 10 and
                                    not int 0.01 * rand ($self->{wave} ) and
                                    not /!p/ and 
                                    $self->{command} =~ /!t|![[:digit:]]+/
                                ) ? /!t/ ? '!p' : '!t' : undef;

								warn;
                                $_ = (defined $_ and /!t/ and $self->{command} and $self->{wave} > (60 + rand 60) ) ?
                                '!leave' :
                                $_;
                            } : do {
                                $self->{command} ? undef : undef;
                            };
                        };
                    } :
					do { 
						undef
					};

                    warn if defined $_ and not $_;

                    $_;
                } :
                /$self->{prefix}.'!'/ ? 
                do {
                    #print join '!!!!', @_;
                    warn;
                    return;
                } : 
                do {
                    die if /$self->{ttdbot}/;
                    local $_ = shift;

                    die unless $_;
                    m/(?<=^$self->{prefix})![[:alnum:]]+/ ? 
                    do {
                        $self->{tower} = undef;
                        $_ = $&; 
                        $_ = /join/ ? undef
                        : /leave/ ? undef
                        : /spec/ ? undef
                        : /fill/ ? undef
                        : /train/ ? undef
                        : /challenge/ ? undef
                        : do {
                            print join " ! ", __LINE__, $_;
                            return
                        };
                    }
                    : m/^!commands/
                    ?  do {
						warn
						#$_->SUPER::signal_emit 
						(
							'event privmsg', 
							join ('!',
                                $self->{windows}->{scalar $self}->{active_server}->{nick},
                                '<command>'
                            )
						);
						return;
                    } 
                    : do {
                        return unless defined $self->{wave};

                        /![[:digit:]]+/
                        ?  do {
                            $self->{tower} = (int rand 20) ? return : $&
                        } 
                        : /(?<=^!hpstr)[[:digit:]]+/
                        ?  do {
                            $self->{tower} = (int rand 20) ? return : '!'.$&
                        } 
                        : return
                    }
                }
            };

            die if defined $_ and not $_;

            # ignore message
            return unless $_;
            die %_ if $self->{command} and not defined $self->{wave} and defined $self->{class};
            return if $self->{command} and $self->{command} eq $_;
            return unless defined $self->{time};

            die if ( $self->{time}->[1] - $self->{time}->[0] ) < 0 ;

            Irssi::print join " + ", map { $_ || '-' } (
                $self->{tag} ,
                $self->{wave} ,
                $self->{enemy} ,
                $self->{challenge} ,
                ($self->{class} and $self->{enemy}) ?
                $self->{class}->($self->{enemy}, $self->{challenge}) : undef,
                $self->{tower},
                $self->{time}->[1]-$self->{time}->[0],
                $self->{command},
                $_
            );

            #Irssi::print '> '. $_;
            $self->{command} = $_;
            $self->{tag} //=
            $base->SUPER::timeout_add_once(
                1000 * int ( 3 + rand 6 + $self->{time}->[1] - $self->{time}->[0] ),
                sub {
                    local $_ = $self->{command};
                    die unless $_;
                    #print $self->{tag}.' '.__LINE__;
                    $base->SUPER::signal_emit('event privmsg', $_);
                    $self->{tag} = undef;
                    /!leave/ ?
                    do {
                        $base->DESTROY();
                    } : undef;
                },
                undef
            )
        }
    );
    die unless $self->{prefix};

    Irssi::print( 'Archon script is initialized.' );
    Irssi::print( 'Vote a map with /twitch emit event privmsg@!map1.' );
    Irssi::print( 'Waiting to join a game with Archon script ...' );
    return $_;
}

=head2 DESTROY

 Usage     : Method call with $_->DESTROY()
 Purpose   : Reset data and restart
 Returns   : The argument
 Argument  : Object to be deleted
 Throws    : Exceptions and other anomolies
 Comment   : This is executed manually after leave
           : or irssi command "/twitch stop Archon"

=cut
sub DESTROY {
    local $_ = shift;
    die caller unless $_->isa(__PACKAGE__);
    my $base = $_;
    my $self = $_->{(__PACKAGE__)};

    do {warn, Irssi::timeout_remove($self->{tag})} if $self->{tag};

    $self->{map} = undef; # last map
    $self->{challenge} = undef;
    $self->{class} = undef;
    $self->{enemy} = undef;
    $self->{prefix} = 'fmg';
    $self->{ttdbot} = 'ttdbot';
    $self->{time} = [ time, time ];
    $self->{tower} = '!1'; # first tower
    $self->{wave} = undef;
    $self->{command} = undef; # last command
    
    Irssi::print("Game finished waiting for 180 min timeout ...");

    $self->{tag} = $base->SUPER::timeout_add_once(
        1000 * 10800,
        sub { 
            Irssi::print("Timeout over ready for next game!");
            # DESTROY created new reference to dead object
            # $base->SUPER::DESTROY();
            $self->{tag} = undef;
        },
        undef
    );
}

#################### subroutine header end ####################

__PACKAGE__;
# The preceding line will help the module return a true value

