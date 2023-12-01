ifndef _MK_ZIP_MK_
_MK_ZIP_MK_ := 1

#$(info ---> .make/zip.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/os.mk

ZIP_BIN := $(call where-is-binary,zip)

ifdef ZIP_BIN
ZIP_VERSION := $(shell $(ZIP_BIN) --version 2>/dev/null | head -n2 | tail -n1 | cut -d\  -f4)
endif
ZIP_VERSION_EXPECTED := 3.0
ifeq ($(ZIP_VERSION),$(ZIP_VERSION_EXPECTED))
ZIP_CHECKED := 1
else
ZIP_CHECKED := 0
$(info zip version $(ZIP_VERSION) does not match expected version $(ZIP_VERSION_EXPECTED))
endif

.PHONY: zip-check
ifdef ZIP_BIN
ifeq ($(ZIP_CHECKED),1)
zip-check:
	@#echo "Using zip $(ZIP_VERSION)"
else
zip-check: zip-install
endif
else
zip-check: zip-install
endif

.PHONY: zip-install
zip-install: brew-check
	@printf "Installing $(bold)zip $(ZIP_VERSION_EXPECTED)$(normal) via brew:\n"
	$(BREW_BIN) install zip

#$(info <--- .make/zip.mk)

endif # _MK_ZIP_MK_
