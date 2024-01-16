#
# Install cog see https://www.cog.info/guide/getting-started.html
#
ifndef _MK_CARGO_COCOGITTO_MK_
_MK_CARGO_COCOGITTO_MK_ := 1

#$(info ---> .make/cargo-cocogitto.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk
include $(MK_DIR)/cargo.mk

COG_BIN := $(call where-is-binary,cog)

.PHONY: cog-check
ifdef COG_BIN
cog-check:
	@#echo "Using cog $(COG_VERSION)"
else
cog-check: cargo-install-cocogitto
endif

#$(info <--- .make/cargo-cocogitto.mk)

endif # _MK_CARGO_COCOGITTO_MK_
