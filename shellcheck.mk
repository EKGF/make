ifndef _MK_SHELLCHECK_MK_
_MK_SHELLCHECK_MK_ := 1

#$(info ---> .make/shellcheck.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk
include $(MK_DIR)/brew.mk

SHELLCHECK_BIN := $(call where-is-binary,shellcheck)

ifdef SHELLCHECK_BIN
SHELLCHECK_VERSION := $(shell $(SHELLCHECK_BIN) --version 2>/dev/null | grep '^version:' | cut -d\  -f2)
endif
# keep the line below in sync with version published at https://formulae.brew.sh/formula/shellcheck
SHELLCHECK_VERSION_EXPECTED := 0.10.0

ifeq ($(SHELLCHECK_VERSION),$(SHELLCHECK_VERSION_EXPECTED))
SHELLCHECK_CHECKED := 1
else
SHELLCHECK_CHECKED := 0
ifdef SHELLCHECK_BIN
$(info ShellCheck version $(SHELLCHECK_VERSION) does not match expected version $(SHELLCHECK_VERSION_EXPECTED))
else
$(info ShellCheck $(SHELLCHECK_VERSION_EXPECTED) has not been installed)
endif
endif

.PHONY: shellcheck-check
ifdef SHELLCHECK_BIN
ifeq ($(SHELLCHECK_CHECKED),1)
shellcheck-check:
	@echo "Using ShellCheck $(SHELLCHECK_VERSION)"
else
shellcheck-check: shellcheck-install
endif
else
shellcheck-check: shellcheck-install
endif

.PHONY: shellcheck-install
ifeq ($(UNAME_S),Darwin)
shellcheck-install: brew-check
	@printf "$(bold)Installing ShellCheck via brew$(normal)\n"
	$(BREW_BIN) install shellcheck
else ifeq ($(IS_LINUX_WITH_APT),1)
shellcheck-install:
	@printf "$(bold)Installing ShellCheck via apt$(normal)\n"
	@dpkg -s shellcheck >/dev/null 2>&1 || sudo apt-get install -y shellcheck
else ifeq ($(IS_LINUX_WITH_YUM),1)
shellcheck-install:
	@printf "$(bold)Installing ShellCheck via yum$(normal)\n"
	sudo yum install -y ShellCheck
else
shellcheck-install: brew-check
	@printf "$(bold)Installing ShellCheck via brew$(normal)\n"
	$(BREW_BIN) install shellcheck
endif

# Run shellcheck against all shell scripts found in the repository
.PHONY: shellcheck-run
shellcheck-run: shellcheck-check
	@printf "$(bold)Running ShellCheck on shell scripts$(normal)\n"
	$(SHELLCHECK_BIN) $(SHELLCHECK_FLAGS) $$(find $(GIT_ROOT) -name '*.sh' -not -path '*/node_modules/*' -not -path '*/.tmp/*' -not -path '*/.git/*')

#$(info <--- .make/shellcheck.mk)

endif # _MK_SHELLCHECK_MK_
