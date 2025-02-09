#
# All the python pipx related stuff
#
ifndef _MK_PIPX_MK_
_MK_PIPX_MK_ := 1

#$(info ---> .make/pipx.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk
include $(MK_DIR)/python.mk
include $(MK_DIR)/brew.mk

PIPX_BIN := $(call where-is-binary,pipx)

ifdef PIPX_BIN
PIPX_VERSION := $(shell $(PIPX_BIN) --version 2>/dev/null | cut -d\  -f2)
endif
PIPX_VERSION_EXPECTED := 1.6.0
ifeq ($(PIPX_VERSION),$(PIPX_VERSION_EXPECTED))
PIPX_CHECKED := 1
else
PIPX_CHECKED := 0
$(info pipx version $(PIPX_VERSION) does not match expected version $(PIPX_VERSION_EXPECTED))
endif

.PHONY: pipx-check
ifdef PIPX_BIN
ifeq ($(PIPX_CHECKED),1)
pipx-check:
	@#echo "Using pipx $(PIPX_VERSION)"
else
pipx-check: python-check
endif
else
pipx-check: python-check
endif

.PHONY: pipx-install
pipx-install: brew-check
	@printf "Installing $(bold)pipx $(PIPX_VERSION_EXPECTED)$(normal) via brew:\n"
	$(BREW_BIN) install pipx
	pipx ensurepath

#$(info <--- .make/pipx.mk)

endif # _MK_PIPX_MK_
