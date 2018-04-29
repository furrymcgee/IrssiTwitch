# This is the makefile for Irssi::Script::Twitch module

include Makefile

# Overriding recipe for target 'Makefile'
Makefile: Makefile.PL
	perl $< INSTALLDIRS=vendor INSTALLVENDORLIB=/usr/share/irssi/scripts
	sed -i $@ \
		-e '/$$(FIRST_MAKEFILE) : Makefile.PL $$(CONFIGDEP)/,+10d' \

Makefile.PL:
	make -C ..

# Run tests
prove:
	$@ -l -v

check:
	perl -l test.pl

# Run dpkg -C Irssi-Script-Twitch-0.01
dpkg: dist
	mv *.tar.gz ../libirssi-script-twitch-perl_0.01.orig.tar.gz
	dh-make-perl
	dpkg-source --auto-commit --build .
	debuild --prepend-path=/usr/lib/ccache -uc -us

.PHONY: check run clean

distclean::
	rm -rf \
		.git \
		.pc \
		Changes \
		Irssi-Script-Twitch-*.tar.gz \
		LICENSE \
		MANIFEST \
		MYMETA.json \
		MYMETA.yml \
		Makefile \
		Makefile.PL \
		Makefile.old \
		README \
		Todo \
		blib \
		pm_to_blib
