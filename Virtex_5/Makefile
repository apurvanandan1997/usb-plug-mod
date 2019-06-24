TOP := top
SRC := src
TEMPLATES := cfg

TARGETS = all synth xst map par timing netgen fuse sim report ise

BUILDDIR := build/$(TOP)
MAKEFILE := $(BUILDDIR)/Makefile
MAKEARGS := TOP=$(TOP) SRC=../../$(SRC) TEMPLATES=../../$(TEMPLATES)

$(TARGETS): $(MAKEFILE)
	$(MAKE) $@ -C $(BUILDDIR) $(MAKEARGS)

$(MAKEFILE): cfg/Makefile
	mkdir -p build/$(TOP)
	cp $< $@

clean:
	rm -rf build

.PHONY := $(TARGETS) clean
