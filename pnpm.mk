#
# All the npm/pnpm related stuff
#
ifndef _MK_PNPM_MK_
_MK_PNPM_MK_ := 1

#$(info ---> .make/pnpm.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/os.mk
include $(MK_DIR)/curl.mk
include $(MK_DIR)/nodejs.mk

NPM_BIN := $(call where-is-binary,npm)
PNPM_BIN := $(call where-is-binary,pnpm)

ifdef PNPM_BIN
PNPM_VERSION := $(shell $(PNPM_BIN) --version 2>/dev/null | cut -d\  -f2)
endif
PNPM_VERSION_EXPECTED := 8.12.1
ifeq ($(PNPM_VERSION),$(PNPM_VERSION_EXPECTED))
PNPM_CHECKED := 1
else
PNPM_CHECKED := 0
$(info pnpm version $(PNPM_VERSION) does not match expected version $(PNPM_VERSION_EXPECTED))
endif

.PHONY: pnpm-check
ifdef PNPM_BIN
ifeq ($(PNPM_CHECKED),1)
pnpm-check: nodejs-check
	@#echo "Using pnpm $(PNPM_VERSION), with its config file $(GIT_ROOT)/package.json"
else
pnpm-check: pnpm-install-itself-first
endif
else
pnpm-check: nodejs-check
	@echo "pnpm is not installed, can't run this function, run $(MAKE) pnpm-install-itself"
	exit 1
endif

.PHONY: pnpm-install-itself-first
pnpm-install-itself-first: brew-check nodejs-check
	@$(BREW_BIN) install --force pnpm
	@$(BREW_BIN) unlink pnpm
	@$(BREW_BIN) link --force pnpm

.PHONY: pnpm-install-prerequisites
ifdef PNPM_BIN
pnpm-install-prerequisites: brew-check nodejs-check
	$(PNPM_BIN) install -g node-gyp
else
pnpm-install-prerequisites:
	@echo "Cannot install pnpm prerequisites, pnpm is not installed, run $(MAKE) pnpm-install-itself first"
	exit 1
endif

.PHONY: pnpm-install-itself
pnpm-install-itself: pnpm-install-itself-first pnpm-install-prerequisites

.PHONY: pnpm-clean
pnpm-clean:
	@echo "Cleaning pnpm"
	@rm -rf $(GIT_ROOT)/node_modules

.PHONY: pnpm-install
pnpm-install: pnpm-check
	cd $(GIT_ROOT) && $(PNPM_BIN) install

.PHONY: pnpm-upgrade-pnpm
pnpm-upgrade-pnpm: $(PNPM_BIN)
	$(PNPM_BIN) add -g pnpm

.PHONY: pnpm-update
pnpm-update: pnpm-check pnpm-upgrade-pnpm
	cd $(GIT_ROOT) && $(PNPM_BIN) update

.PHONY: pnpm-run-dev
pnpm-run-dev: pnpm-check
	cd $(GIT_ROOT) && $(PNPM_BIN) run dev

#$(info <--- .make/pnpm.mk)

endif # _MK_PNPM_MK_
