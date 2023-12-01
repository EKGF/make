ifndef _MK_OS_TOOLS_WINDOWS_MK_
_MK_OS_TOOLS_WINDOWS_MK_ := 1

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

SED_BIN := /usr/bin/sed

include $(MK_DIR)/sops.mk

.PHONY: windows-tools-install
windows-tools-install: sops-install-via-choco

endif # _MK_OS_TOOLS_WINDOWS_MK_
