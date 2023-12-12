ifndef _MK_OS_TOOLS_MK_
_MK_OS_TOOLS_MK_ := 1

#$(info ---> .make/os-tools.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/os.mk
include $(MK_DIR)/git.mk
include $(MK_DIR)/os-tools-*.mk
include $(MK_DIR)/rustup.mk
include $(MK_DIR)/brew.mk
include $(MK_DIR)/sops.mk
include $(MK_DIR)/llvm.mk

# TODO: support tectonic by installing with brew: icu4c pkg-config graphite2 freetype2

GCC_VERSION := $(shell gcc --version 2>/dev/null | head -n 1 2>/dev/null)

ifdef CC
CC_CLANG_VERSION := $(shell $(CC) --version | head -n1 | cut -d\  -f4)
#$(info CC version is $(CC_CLANG_VERSION))
endif

#$(info GCC_VERSION=$(GCC_VERSION))

.PHONY: gcc-install
gcc-install: brew-check
	@if command -v gcc >/dev/null 2>&1 ; then \
  		echo "gcc $(GCC_VERSION) is already installed" ; \
  	else \
		gcc --version 2>/dev/null || true ; \
		if [ ! -d $(HOMEBREW_PREFIX)/Cellar/gcc/11* ] ; then $(BREW_BIN) install gcc ; fi ; \
		gcc --version 32|| true ; \
	fi

.PHONY: os-tools-install
ifeq ($(UNAME_S),Windows)
os-tools-install: rustup-check-components windows-tools-install rustup-add-targets
endif
ifeq ($(UNAME_S),Linux)
os-tools-install: rustup-check-components linux-tools-install rustup-add-targets
endif
ifeq ($(UNAME_S),Darwin)
os-tools-install: rustup-check-components darwin-tools-install rustup-add-targets
endif

.PHONY: os-tools-check
os-tools-check: os-tools-install
# TODO: os-tools-check should try to avoid calls to package installers of packages that are already installed

#$(info <--- .make/os-tools.mk)

endif # _MK_OS_TOOLS_MK_
