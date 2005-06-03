####################################################################
# The Harmony Project                                              #
# harmony@lists.seas.upenn.edu                                     #
#                                                                  #
# Common Makefile infrastructure			           #
####################################################################

# $Id: Common.Makefile 121 2005-05-05 00:19:32Z bcpierce $

default: all

####################################################################
# Navigation

LENSESDIR = $(TOP)/lenses
TOOLSDIR = $(TOP)/tools
SRCDIR = $(TOP)/src

SRC2F = $(TOOLSDIR)/src2f
SRC2TEX = $(TOOLSDIR)/src2tex

####################################################################
# Setup for running harmony 

LENSPATH = -I $(LENSESDIR) -I .
HARMONYBIN = $(SRCDIR)/harmony 
HARMONY = $(HARMONYBIN) $(HARMONYFLAGS) $(LENSPATH)

HARMONYBIN = $(SRCDIR)/harmony 

$(HARMONYBIN):
	$(MAKE) -C $(SRCDIR)

SRCFILES = prelude.src
GENERATEDFCLFILES = $(subst .src,.fcl, $(SRCFILES:%=$(LENSESDIR)/%))

%.fcl : %.src $(SRC2F)
	$(SRC2F) $< $@

$(SRC2F):
	$(MAKE) -C $(TOOLSDIR)

####################################################################
# Common targets

clean::
	rm -rf *.tmp *.aux *.bbl *.blg *.log *.dvi *.bak *~ temp.* TAGS *.cmo *.cmi *.cmx *.o *.annot 
	for i in $(SUBDIRS); do $(MAKE) -C $$i clean; done

test:: $(HARMONYBIN) $(GENERATEDFCLFILES) 
	for i in $(SUBDIRS); do $(MAKE) -C $$i test; done

