ifndef _MK_JQ_MK_
_MK_JQ_MK_ := 1

#$(info ---> .make/jq.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/brew.mk

JQ_BIN := $(call where-is-binary,jq)
ifdef JQ_BIN
JQ_VERSION := $(shell jq --version 2>/dev/null | head -n1 | cut -d\  -f3)
else
$(info jq was not installed)
endif

#$(info JQ_VERSION=$(JQ_VERSION))

.PHONY: jq-check
ifeq ($(JQ_VERSION),)
jq-check: brew-check
	@echo "Install JQ"
	$(BREW_BIN) install jq
	jq --version
else
jq-check:
	@#echo "Using jq: $(JQ_VERSION)"
endif

.PHONY: jq-install-via-brew
jq-install-via-brew: brew-check
	@echo "Install JQ"
	$(BREW_BIN) install jq
	jq --version

#$(info <--- .make/jq.mk)

endif # _MK_JQ_MK_
