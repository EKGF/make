ifndef _MK_AZURE_AXCOPY_MK_
_MK_AZURE_AXCOPY_MK_ := 1

#$(info ---> .make/azure-azcopy.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

AZURE_AZCOPY_BIN := $(call where-is-binary,azcopy)

ifndef AZURE_AZCOPY_BIN
ifeq ($(UNAME_S),Windows)
$(error Install Azure azcopy utility)
endif
ifdef BREW_BIN
AZURE_AZCOPY_BIN := $(shell $(BREW_BIN) list azcopy 2>/dev/null)
endif
endif
ifdef AZURE_AZCOPY_BIN
AZURE_AZCOPY_VERSION := $(shell "$(AZURE_AZCOPY_BIN)" --version 2>/dev/null | cut -d\  -f3)
endif
ifdef AZURE_AZCOPY_VERSION
#$(info Using azcopy $(AZURE_AZCOPY_VERSION))
endif

.PHONY: azure-azcopy-check
ifeq ($(AZURE_AZCOPY_VERSION),)
ifeq ($(UNAME_S),Windows)
azure-azcopy-check:
	@echo "Install Azure azcopy yourself"
	exit 1
else
azure-azcopy-check: brew-check
	@echo Install Azure AzCopy
	$(BREW_BIN) install azcopy
	azcopy --version
endif
else
azure-azcopy-check:
	@#echo "Using azure azcopy $(AZURE_AZCOPY_VERSION)"
endif

#$(info <--- .make/azure-azcopy.mk)

endif # _MK_AZURE_AXCOPY_MK_
