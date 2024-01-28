ifndef _MK_BREW_MK_
_MK_BREW_MK_ := 1

#$(info ---> .make/brew.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk
include $(MK_DIR)/curl.mk

export HOMEBREW_AUTO_UPDATE_SECS := 86400

BREW_BIN := $(call where-is-binary,brew)
ifndef BREW_BIN
ifeq (,$(filter brew-install,$(MAKECMDGOALS)))
$(error Homebrew not found, run "$(MAKE) brew-install" to install)
else
# I know, the lines below are even uglier than everything else in this file :-)
skip_rustup_check := 1
skip_cargo_check := 1
skip_llvm_check := 1
skip_sops_check := 1
endif
endif

ifdef BREW_BIN
HOMEBREW_PREFIX := $(shell $(BREW_BIN) --prefix 2>/dev/null)
HOMEBREW_CELLAR := $(shell $(BREW_BIN) --cellar 2>/dev/null)
else
$(info Homebrew needs to be installed)
endif

BREW_PACKAGES := $(TMP_DIR)/brew-installed-packages.txt

# Store the list of installed packages in a file so we can check if they are
# already installed without having to run other brew commands which takes
# a long time.
#.INTERMEDIATE: $(BREW_PACKAGES)
ifdef BREW_BIN
$(BREW_PACKAGES): brew-check
	@printf "Updating brew package list\n"
	@HOMEBREW_NO_AUTO_UPDATE=1 $(BREW_BIN) list --versions > $@
	ls -al $@
else
$(BREW_PACKAGES): brew-install
endif

.PHONY: brew-install-linux
ifdef BREW_BIN
brew-install-linux:
	@echo "HomeBrew is already installed"
else
.INTERMEDIATE: $(TMP_DIR)/brew-install-script.sh
$(TMP_DIR)/brew-install-script.sh: curl-check
	@printf "$(bold)brew-install-script: downloading script$(normal)\n"
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh > $@
	chmod u+x $@
	@printf "$(bold)brew-install-script: script can now be run$(normal)\n"

brew-install-linux: $(TMP_DIR)/brew-install-script.sh
	@printf "$(bold)brew-install-linux: running install script $^$(normal)\n"
	@# see https://brew.sh/
	$(TMP_DIR)/brew-install-script.sh
	@echo "HomeBrew install script finished"
endif

#
# not sure if HomeBrew can be installed on Windows, this part has not been tested yet!
#
.PHONY: brew-install-windows
brew-install-windows:
	@echo "brew-install-windows"
	@echo "homebrew for windows does not exist unless you run in WSL which we are not doing"
	@echo "because we need to be able to run 'cargo tauri --bundles updater' which relies"
	@echo "on WixTools which only runs in native Windows"

.PHONY: brew-install-darwin
brew-install-darwin:
	@echo "brew-install-darwin"
	@if ! command -v brew >/dev/null 2>&1 ; then echo "Install HomeBrew" ; exit 1 ; fi
	$(BREW_BIN) --version

.PHONY: brew-check
ifdef BREW_BIN
brew-check:
else
brew-check: brew-install
#   $(BREW_BIN) update takes too long: TODO: make this run once a day
#	$(BREW_BIN) update
    @echo "brew-check: $(BREW_BIN) is installed, now running update"
	$(BREW_BIN) update
endif

.PHONY: brew-update
brew-update: brew-check
	$(BREW_BIN) update

.PHONY: brew-upgrade
brew-upgrade: brew-update
	$(BREW_BIN) upgrade

brew-install: brew-install-$(UNAME_S_lc)

#$(info <--- .make/brew.mk)

endif # _MK_BREW_MK_
