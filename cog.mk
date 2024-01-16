#
# All the cog / Cocogitto related stuff
#
# See https://docs.cocogitto.io
#
ifndef _MK_COG_MK_
_MK_COG_MK_ := 1

#$(info ---> .make/cog.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk
include $(MK_DIR)/cargo.mk
include $(MK_DIR)/jq.mk

COG_BIN := $(call where-is-binary,cog)

ifdef COG_BIN
COG_VERSION := $(shell $(COG_BIN) --version 2>/dev/null | cut -d\  -f2)
endif
COG_VERSION_EXPECTED := 5.6.0
ifeq ($(COG_VERSION),$(COG_VERSION_EXPECTED))
COG_CHECKED := 1
else
COG_CHECKED := 0
ifdef COG_VERSION
$(info Cocogitto version $(COG_VERSION) does not match expected version $(COG_VERSION_EXPECTED))
else
$(info Cocogitto is not installed, use $(MAKE) cog-install)
endif
endif

.PHONY: cog-check
ifdef COG_BIN
ifeq ($(COG_CHECKED),1)
cog-check:
	@#echo "Using Cocogitto $(COG_VERSION), with its config file $(GIT_ROOT)/cog.toml"
else
cog-check: cog-install
endif
else
cog-check: cog-install
endif

ifdef CARGO_BIN
cog-install: cargo-check jq-check
	@echo "Installing Cocogitto by building it from source:"
	$(CARGO_BIN) +stable install --locked --version "^$(COG_VERSION_EXPECTED)" cocogitto
else
cog-install:
	set -x ; $(MAKE) cog-install
endif

# Bump the version number of the whole repo
cog-bump: cog-check jq-check
	$(COG_BIN) bump --patch

#$(info <--- .make/cog.mk)

endif # _MK_COG_MK_
