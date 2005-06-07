####################################################################
# The Harmony Project                                              #
# harmony@lists.seas.upenn.edu                                     #
####################################################################

LIB_DIRS = -I $(SRCDIR) -I $(SRCDIR)/ubase
CMX_FILES = info.cmx error.cmx safelist.cmx uprintf.cmx util.cmx uarg.cmx \
	   prefs.cmx trace.cmx misc.cmx mapplus.cmx \
           name.cmx surveyor.cmx v.cmx syntax.cmx metal.cmx metay.cmx

FAVDIR = ./IE6BMSample
MOVEDDIR = ./IE6BMNew

VIEW_FILE = dumped-bkmark.meta

ie6util: ie6util.ml
	ocamlopt -o ie6util $(LIB_DIRS) str.cmxa unix.cmxa $(CMX_FILES) ie6util.ml

testieget: ie6util
	./ie6util get $(FAVDIR) $(VIEW_FILE) && echo && cat $(VIEW_FILE)

testieput: testieget
	./ie6util put $(VIEW_FILE) $(MOVEDDIR)

cleanIE:
	rm -rf $(MOVEDDIR)
	rm -rf *~ *.o *.cm* ie6util $(VIEW_FILE)
