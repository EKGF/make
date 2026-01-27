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

.PHONY: mk-clean
mk-clean:
	@echo "mk-clean"
	@rm -f $(MK_TAR)
	@rm -rf $(MK_DIR)

#$(info <--- .make/dataroad-make.mk)

endif # _MK_DATAROAD_MAKE_MK_
