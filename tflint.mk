ifndef _MK_TFLINT_MK_
_MK_TFLINT_MK_ := 1

#$(info ---> .make/tflint.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/os.mk
include $(MK_DIR)/brew.mk

TFLINT_BIN := $(call where-is-binary,tflint)
ifndef TFLINT_BIN
$(info TFLINT_BIN not found)
endif

ifdef TFLINT_BIN
TFLINT_VERSION := $(shell $(TFLINT_BIN) --version 2>/dev/null | head -n1 | cut -d\  -f3)
endif
TFLINT_VERSION_EXPECTED := 0.49.0
ifeq ($(TFLINT_VERSION),$(TFLINT_VERSION_EXPECTED))
TFLINT_CHECKED := 1
else
TFLINT_CHECKED := 0
undefine TFLINT_BIN
$(info terraform lint, version $(TFLINT_VERSION), does not match expected version $(TFLINT_VERSION_EXPECTED))
endif

.PHONY: tflint-check
ifdef TFLINT_BIN
tflint-check:
else
tflint-check: tflint-install
endif

.PHONY: tflint-install
tflint-install: brew-check
	@printf "Installing $(bold)tflint $(TFLINT_VERSION_EXPECTED)$(normal) via brew:\n"
	@$(BREW_BIN) install --force tflint
	@$(BREW_BIN) unlink tflint
	-@$(BREW_BIN) link --force tflint

#$(info <--- .make/tflint.mk)

endif # _MK_TFLINT_MK_
