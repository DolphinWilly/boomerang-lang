####################################################################
# The Harmony Project                                              #
# harmony@lists.seas.upenn.edu                                     #
####################################################################

# $Id$

SUBDIRS = src lenses examples tools doc
SUBDIRSCLEANONLY = experimental visual papers extern

TOP = .
include $(TOP)/Top.Makefile

all: buildsubdirs

###########################################################################
## Tarball Export

EXPORTNAME=harmony-$(shell date "+20%y%m%d")
TMPDIR=/tmp
TMP=$(TMPDIR)/$(EXPORTNAME)
DOWNLOADDIR=$(TOP)/web/download
HARMONYUSER?=$(USER)

tar: 
	echo \\draftfalse > $(DOCDIR)/temp.tex
	$(MAKE) -C $(DOCDIR) pdf
	rm -rf $(TMPDIR)/$(EXPORTNAME)
	(cd $(TMPDIR); svn export file://mnt/saul/plclub1/svnroot/harmony/trunk $(EXPORTNAME))
	cp $(DOCDIR)/main.pdf $(TMP)/doc/manual.pdf
	(cd $(TMPDIR); tar cvf - $(EXPORTNAME) \
           | gzip --force --best > $(EXPORTNAME).tar.gz)
	mv $(TMPDIR)/$(EXPORTNAME).tar.gz $(DOWNLOADDIR)

###########################################################################
## Web Install

WEBDIR = $(TOP)/web/

install:
	$(MAKE) all
	rm -rf $(WEBDIR)
	mkdir $(WEBDIR)
	cp -r src lenses examples doc extern $(WEBDIR)
	cp -r php $(WEBDIR)/cgi-bin/
	chmod -R 755 $(WEBDIR)
