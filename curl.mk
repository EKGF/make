ifndef _MK_CURL_MK_
_MK_CURL_MK_ := 1

#$(info ---> .make/curl.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/os.mk

CURL_BIN := $(call where-is-binary,curl)
ifdef CURL_BIN
CURL_VERSION := $(shell curl --version 2>/dev/null | head -n1 | cut -d\  -f3)
endif

.PHONY: curl-check
ifdef CURL_BIN
ifeq ($(UNAME_S),Windows)
curl-check:
	@echo ERROR: TODO, check if curl is installed
	exit 1
endif
ifeq ($(UNAME_S),Linux)
ifeq ($(IS_LINUX_WITH_YUM),1)
curl-check:
	sudo yum install -y curl
else
curl-check:
	@dpkg -s curl >/dev/null 2>&1 || sudo apt install curl
endif
endif
ifeq ($(UNAME_S),Darwin)
curl-check:
	@$(CURL_BIN) --version | grep -q "curl [7|8|9]."
endif
else
curl-check:
	@#echo "Using curl version $(CURL_VERSION)"
endif

#$(info <--- .make/curl.mk)

endif
