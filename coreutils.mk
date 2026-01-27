ifndef _MK_COREUTILS_MK_
_MK_COREUTILS_MK_ := 1

#$(info ---> .make/coreutils.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

# GNU coreutils provides grealpath, greadlink, etc.
# Required on macOS where BSD versions differ from GNU
GREALPATH_BIN := $(shell command -v grealpath 2>/dev/null)

.PHONY: coreutils-check
ifdef GREALPATH_BIN
coreutils-check:
	@echo "GNU coreutils is installed (grealpath at $(GREALPATH_BIN))"
else
ifeq ($(UNAME_S_lc),darwin)
coreutils-check: coreutils-install
else
coreutils-check:
	@echo "GNU coreutils not needed on Linux (using native realpath)"
endif
endif

.PHONY: coreutils-install
coreutils-install:
ifeq ($(UNAME_S_lc),darwin)
	@echo "Installing GNU coreutils via Homebrew..."
	@brew install coreutils
else
	@echo "GNU coreutils install not needed on $(UNAME_S_lc)"
endif

#$(info <--- .make/coreutils.mk)

endif # _MK_COREUTILS_MK_
