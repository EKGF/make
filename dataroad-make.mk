#
# This file is a copy of https://github.com/dataroadinc/make/blob/main/dataroad-make.mk.
# It handles the installation and updating of the .make directory in the root
# of your own git repository.
#
ifndef _MK_DATAROAD_MAKE_MK_
_MK_DATAROAD_MAKE_MK_ := 1

#$(info ---> .make/dataroad-make.mk)

_MK_ENABLE_DOWNLOAD_ := 1

MK_TAR_DIR := $(HOME)/.tmp
MK_TAR := $(MK_TAR_DIR)/make.tar.gz
ifdef GIT_ROOT
ifneq ("$(wildcard $(GIT_ROOT)/../make)","")
# If the DataRoad make repository is cloned in sibling directory of the current repo, and that sibling directory is
# simply called "make" then we assume its a clone of the DataRoad make repo.
MK_DIR := $(shell cd $(GIT_ROOT)/../make && pwd -P)
_MK_ENABLE_DOWNLOAD_ := 0
$(info Found DataRoad make repo in $(MK_DIR) so we are using those make files then)
else
MK_DIR := $(GIT_ROOT)/.make
$(info Did not find DataRoad make repo clone in $(GIT_ROOT)/../make, assuming we need to download the make files into $(MK_DIR))
endif
else
$(warning GIT_ROOT is not defined)
MK_DIR := .make
endif

MK_URL := https://github.com/dataroadinc/make/archive/refs/heads/main.tar.gz
MK_FLAG_FILE := $(MK_DIR)/os.mk
.PRECIOUS: $(MK_FLAG_FILE)

CURL_BIN := $(shell command -v curl 2>/dev/null)
ifndef CURL_BIN
$(error curl not installed)
endif

# === Auto-update configuration ===
# How often to check for make file updates, in minutes (default: 1440 = 24 hours).
# Set MK_AUTO_UPDATE=0 to disable automatic checks entirely.
MK_UPDATE_INTERVAL ?= 1440
MK_AUTO_UPDATE ?= 1
MK_UPDATE_STAMP := $(MK_TAR_DIR)/.mk-update-stamp

# === Auto-update check at parse time ===
# Runs before includes so that updated files are picked up immediately.
# For local clone mode: performs a fast-forward git pull (fast and safe).
# For download mode: re-downloads the tarball from GitHub.
ifeq ($(MK_AUTO_UPDATE),1)
# Skip auto-update when explicitly running mk-update or mk-clean
ifeq ($(filter mk-update mk-clean,$(MAKECMDGOALS)),)
_MK_IS_STALE := $(shell \
  stamp="$(MK_UPDATE_STAMP)"; \
  if [ ! -f "$$stamp" ]; then \
    echo 1; \
  elif [ -n "$$(find "$$stamp" -mmin +$(MK_UPDATE_INTERVAL) 2>/dev/null)" ]; then \
    echo 1; \
  fi)
ifeq ($(_MK_IS_STALE),1)
ifeq ($(_MK_ENABLE_DOWNLOAD_),0)
# Local clone mode: fast-forward pull
_MK_PULL_RESULT := $(shell git -C "$(MK_DIR)" pull --ff-only --quiet 2>/dev/null && echo ok || echo fail)
$(shell mkdir -p "$(MK_TAR_DIR)" && touch "$(MK_UPDATE_STAMP)")
ifeq ($(_MK_PULL_RESULT),ok)
$(info Auto-updated make files from local clone at $(MK_DIR))
else
$(info Note: auto-update of $(MK_DIR) skipped (not on default branch, local changes, or offline). Run 'make mk-update' to retry.)
endif
else
# Download mode: re-download from GitHub
_MK_DL_RESULT := $(shell \
  mkdir -p "$(MK_TAR_DIR)" && \
  $(CURL_BIN) -L -s -S -f -o "$(MK_TAR)" --url "$(MK_URL)" && \
  mkdir -p "$(MK_DIR)" && \
  tar -xzf "$(MK_TAR)" -C "$(MK_DIR)" --strip-components=1 && \
  rm -rf "$(MK_DIR)/.idea" && \
  touch -mc "$(MK_DIR)"/* && \
  touch "$(MK_UPDATE_STAMP)" && \
  echo ok 2>/dev/null || echo fail)
ifeq ($(_MK_DL_RESULT),ok)
$(info Auto-updated make files from GitHub)
else
$(info Note: auto-download of make files failed (offline?). Run 'make mk-update' to retry.)
$(shell mkdir -p "$(MK_TAR_DIR)" && touch "$(MK_UPDATE_STAMP)")
endif
endif
endif # _MK_IS_STALE
endif # filter
endif # MK_AUTO_UPDATE

include $(MK_FLAG_FILE)
-include $(MK_DIR)/*.mk

ifeq ($(_MK_ENABLE_DOWNLOAD_),1)
$(MK_DIR):
	@echo "Creating the $(MK_DIR) directory"
	@mkdir -p $(MK_DIR) >/dev/null 2>&1

$(MK_TAR_DIR):
	@echo "Creating the $(MK_TAR_DIR) directory"
	@mkdir -p $(MK_TAR_DIR) >/dev/null 2>&1

$(MK_TAR): $(MK_TAR_DIR)
	@echo "Downloading $@"
	@$(CURL_BIN) -L -s -S -f -o $@ --url $(MK_URL)

$(MK_FLAG_FILE): $(MK_DIR) $(MK_TAR)
	@echo "Extracting the DataRoad Make files into the $(MK_DIR) directory"
	@tar -xzf $(MK_TAR) -C $(MK_DIR) --strip-components=1
	@rm -rf $(MK_DIR)/.idea
	@grep -q "dataroadinc/make.git" .git/config 2>/dev/null || (cd $(MK_DIR) && mv -f dataroad-make.mk ..)
	@touch -mc $(MK_DIR)/*
	-@$(MAKE) --no-print-directory $(MAKECMDGOALS)

else
$(MK_DIR):

$(MK_TAR_DIR):

$(MK_TAR):

$(MK_FLAG_FILE):

endif

# === Manual update target ===
.PHONY: mk-update
ifeq ($(_MK_ENABLE_DOWNLOAD_),1)
mk-update:
	@echo "Downloading latest make files from GitHub..."
	@mkdir -p $(MK_TAR_DIR)
	@$(CURL_BIN) -L -s -S -f -o $(MK_TAR) --url $(MK_URL)
	@mkdir -p $(MK_DIR)
	@echo "Extracting into $(MK_DIR)..."
	@tar -xzf $(MK_TAR) -C $(MK_DIR) --strip-components=1
	@rm -rf $(MK_DIR)/.idea
	@grep -q "dataroadinc/make.git" .git/config 2>/dev/null || (cd $(MK_DIR) && mv -f dataroad-make.mk ..)
	@touch -mc $(MK_DIR)/*
	@mkdir -p $(MK_TAR_DIR) && touch $(MK_UPDATE_STAMP)
	@echo "Make files updated from GitHub"
else
mk-update:
	@echo "Updating make files from local clone at $(MK_DIR)..."
	@git -C $(MK_DIR) pull --ff-only 2>&1 \
		&& echo "Make files updated from local clone" \
		|| echo "Warning: fast-forward pull failed in $(MK_DIR). You may have local changes or are on a non-default branch."
	@mkdir -p $(MK_TAR_DIR) && touch $(MK_UPDATE_STAMP)
endif

# === Info target ===
.PHONY: mk-info
mk-info:
ifeq ($(_MK_ENABLE_DOWNLOAD_),0)
	@echo "Mode:            local clone"
	@echo "Location:        $(MK_DIR)"
	@echo "Branch:          $$(git -C $(MK_DIR) rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
	@echo "Latest commit:   $$(git -C $(MK_DIR) log -1 --format='%h %s (%cr)' 2>/dev/null || echo unknown)"
else
	@echo "Mode:            downloaded"
	@echo "Location:        $(MK_DIR)"
	@echo "Source URL:      $(MK_URL)"
endif
	@echo "Auto-update:     $(MK_AUTO_UPDATE)"
	@echo "Update interval: $(MK_UPDATE_INTERVAL) minutes"
	@if [ -f "$(MK_UPDATE_STAMP)" ]; then \
		echo "Last check:      $$(stat -c '%y' "$(MK_UPDATE_STAMP)" 2>/dev/null || stat -f '%Sm' "$(MK_UPDATE_STAMP)" 2>/dev/null || echo unknown)"; \
	else \
		echo "Last check:      never"; \
	fi

.PHONY: mk-clean
mk-clean:
	@echo "mk-clean"
	@rm -f $(MK_TAR)
	@rm -f $(MK_UPDATE_STAMP)
	@rm -rf $(MK_DIR)

#$(info <--- .make/dataroad-make.mk)

endif # _MK_DATAROAD_MAKE_MK_
