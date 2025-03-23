#
# All the open-next related stuff
#
ifndef _MK_OPEN_NEXT_MK_
_MK_OPEN_NEXT_MK_ := 1

#$(info ---> .make/open-next.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/pnpm.mk
include $(MK_DIR)/nextjs.mk

OPEN_NEXT_BIN := npx open-next

ifdef OPEN_NEXT_BIN
OPEN_NEXT_VERSION := $(shell $(PNPM_BIN) list --global open-next 2>/dev/null | grep open-next | cut -d\  -f2)
endif
OPEN_NEXT_VERSION_EXPECTED := 3.1.3
OPEN_NEXT_MAIN_VERSION_EXPECTED := $(shell echo $(OPEN_NEXT_VERSION_EXPECTED) | cut -d. -f1)
ifeq ($(OPEN_NEXT_VERSION),$(OPEN_NEXT_VERSION_EXPECTED))
OPEN_NEXT_CHECKED := 1
else
OPEN_NEXT_CHECKED :=
ifdef OPEN_NEXT_VERSION
$(info OpenNext version $(OPEN_NEXT_VERSION) does not match expected version $(OPEN_NEXT_VERSION_EXPECTED))
else
$(info OpenNext version $(OPEN_NEXT_VERSION_EXPECTED) has not been installed)
endif
endif

.PHONY: open-next-check
ifdef NODEJS_BIN
ifeq ($(NODEJS_CHECKED),1)
open-next-check:
	@#echo "Using OpenNext $(OPEN_NEXT_VERSION)"
else
open-next-check: open-next-install
endif
else
open-next-check: open-next-install
endif

.PHONY: open-next-install
open-next-install: pnpm-check
	$(PNPM_BIN) add --global open-next@$(OPEN_NEXT_VERSION_EXPECTED)
	$(PNPM_BIN) add --save-dev open-next@$(OPEN_NEXT_VERSION_EXPECTED)

.PHONY: open-next-clean
open-next-clean: nextjs-clean
	@echo "Cleaning open-next"
	@rm -rf $(GIT_ROOT)/.open-next

.PHONY: _open-next-info
_open-next-info:
	@printf "$(green)$(bold)Building the Open-Next UI$(normal)\n"

.PHONY: open-next-build
open-next-build: pnpm-check _open-next-info open-next-prerequisites
	@printf "$(bold)Building the Open-Next UI:$(normal)\n"
	@cd $(GIT_ROOT) && set -x ; \
	$(PNPM_BIN) dlx open-next@$(OPEN_NEXT_VERSION_EXPECTED) build --minify
	@printf "$(green)$(bold)Finished building the Open-Next UI$(normal)\n"

.PHONY: open-next-build-debug
open-next-build-debug: _open-next-info pnpm-check open-next-prerequisites
	@cd $(GIT_ROOT) && set -x ; \
	OPEN_NEXT_DEBUG=true $(PNPM_BIN) dlx open-next@$(OPEN_NEXT_VERSION_EXPECTED) build
	@printf "$(green)$(bold)Finished building the Open-Next UI$(normal)\n"

.PHONY: open-next-prerequisites
open-next-prerequisites: brew-check $(BREW_PACKAGES)
	@printf "Checking (or installing) open-next prerequisites:\n"
	# The 'sharp' package requires vips, which is not installed by default,
	# if we don't pre-install it, pnpm/npm will try to install it itself
	# and fail due to timeouts.
	grep "^vips " $(BREW_PACKAGES) || $(BREW_BIN) install libvips
	@printf "All open-next prerequisites are installed\n"

#$(info <--- .make/open-next.mk)

endif # _MK_OPEN_NEXT_MK_
