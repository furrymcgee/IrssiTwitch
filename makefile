# This is a makefile for building a distribution package

.DEFAULT_GOAL := all

# Redirct to sudirectory
%: Irssi-Script-Twitch/Makefile.PL
	make -C $(shell dirname $<) $@

# Directory is always up to date
Irssi-Script-Twitch/Makefile.PL:
	quilt push
	find Irssi-Script-Twitch/ -type f | xargs quilt add
	modulemaker -Icn Irssi::Script::Twitch
	quilt diff | patch --reverse --strip=1
	quilt files | xargs quilt remove
	quilt refresh
	quilt pop

dpkg: Irssi-Script-Twitch
	make -C $< dist $@

check: Irssi-Script-Twitch
	PERLLIB=lib make -C $< $@

run: Irssi-Script-Twitch/startup
	PERLLIB=$(shell dirname $<)/lib exec irssi --home=$(shell dirname $<)

distclean:: 
	make distclean -C Irssi-Script-Twitch
	rm -rf \
		.pc \
		Irssi-Script-Twitch/debian \
		libirssi-script-twitch-perl_* 
