# === Configuration ===
V ?= 0
ifeq ($(V),1)
VERBOSE := -v
else
VERBOSE :=
endif

SRCDIR   := programs/src
BUILDDIR := programs/build
OUTDIR   := programs/out

# Auto‑discover all .asm files as possible sources
SOURCES  := $(basename $(notdir $(wildcard $(SRCDIR)/*.asm)))

# Real sentinel files in out/
BUILD_MARKERS := $(SOURCES:%=$(OUTDIR)/%.build)

# === Phony shortcuts (so you can type “make boot.build”) ===
.PHONY: $(SOURCES:%=%.build)

# Shortcut rule: “boot.build” depends on “programs/out/boot.build”
$(SOURCES:%=%.build): %.build: $(OUTDIR)/%.build

# === Default: build all sources ===
.PHONY: all
.PRECIOUS: $(BUILDDIR)/%.mem

all: $(BUILD_MARKERS)

# === Build a specific source and sentinel ===
$(BUILDDIR)/%.mem: $(SRCDIR)/%.asm | $(BUILDDIR)
# 	rm -rf $(OUTDIR)/*
	python compile.py -f $< -o $(BUILDDIR)/$*.mem $(VERBOSE)

$(OUTDIR)/%.build: $(BUILDDIR)/%.mem | $(OUTDIR)
	python py_gen/gen_reg.py --build-dir $(BUILDDIR) --basename $* --outdir $(OUTDIR)
	touch $@


# === Ensure directories exist ===
$(BUILDDIR) $(OUTDIR):
	mkdir -p $@

# === Clean up ===
.PHONY: clean
clean:
	rm -rf $(BUILDDIR) $(OUTDIR)
