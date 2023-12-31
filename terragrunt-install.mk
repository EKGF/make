ifndef _MK_TERRAGRUNT_INSTALL_MK_
_MK_TERRAGRUNT_INSTALL_MK_ := 1

#$(info ---> .make/terragrunt-install.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/os.mk
include $(MK_DIR)/brew.mk
include $(MK_DIR)/terraform.mk

TERRAGRUNT_BIN := $(call where-is-binary,terragrunt)

ifdef TERRAGRUNT_BIN
TERRAGRUNT_VERSION := $(shell $(TERRAGRUNT_BIN) --version 2>/dev/null | cut -d\  -f3)
endif
TERRAGRUNT_VERSION_EXPECTED := 0.54.12
ifeq ($(TERRAGRUNT_VERSION),$(TERRAGRUNT_VERSION_EXPECTED))
TERRAGRUNT_CHECKED := 1
else
TERRAGRUNT_CHECKED := 0
$(info terragrunt version $(TERRAGRUNT_VERSION) does not match expected version $(TERRAGRUNT_VERSION_EXPECTED))
endif

.PHONY: terragrunt-check
ifdef TERRAGRUNT_BIN
ifeq ($(TERRAGRUNT_CHECKED),1)
terragrunt-check: terraform-check tflint-check
	@#echo "Using terragrunt $(TERRAGRUNT_VERSION)"
else
terragrunt-check: terraform-check tflint-check terragrunt-install
endif
else
terragrunt-check: terraform-check tflint-check terragrunt-install
endif

.PHONY: terragrunt-install
terragrunt-install: brew-check
	@printf "Installing $(bold)terragrunt $(TERRAGRUNT_VERSION_EXPECTED)$(normal) via brew:\n"
	$(BREW_BIN) install terragrunt

#$(info <--- .make/terragrunt-install.mk)

endif # _MK_TERRAGRUNT_INSTALL_MK_
