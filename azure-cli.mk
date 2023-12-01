ifndef _MK_AZURE_CLI_MK_
_MK_AZURE_CLI_MK_ := 1

##$(info ---> .make/azure-cli.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/brew.mk

AZ_BIN := $(call where-is-binary,az)
ifdef AZ_BIN
AZURE_CLI_VERSION := $(shell "$(AZ_BIN)" version 2>/dev/null -o yaml | head -n 1 | cut -d\  -f2)
#$(info Using Azure CLI $(AZURE_CLI_VERSION))
else
ifeq ($(UNAME_S),Windows)
$(error Install Azure CLI manually)
endif
endif

.PHONY: azure-cli-check
ifeq ($(AZURE_CLI_VERSION),)
ifeq ($(UNAME_S),Windows)
azure-cli-check:
	@echo Install Azure CLI manually
	exit 1
else
azure-cli-check: azure-cli-install
	@#echo "Using Azure CLI $(AZURE_CLI_VERSION)"
endif
else
azure-cli-check:
	@#echo "Using Azure CLI $(AZURE_CLI_VERSION)"
endif

.PHONY: azure-cli-install
azure-cli-install: brew-check
	@echo Install Azure CLI
	$(BREW_BIN) install azure-cli
	@"$(AZ_BIN)" --version
	@"$(AZ_BIN)" upgrade --all --yes || true
	@"$(AZ_BIN)" extension add --name azure-devops --upgrade
	@"$(AZ_BIN)" extension add --name storage-blob-preview --upgrade
	@"$(AZ_BIN)" extension add --name containerapp --upgrade
	@"$(AZ_BIN)" provider register --namespace Microsoft.App
	@"$(AZ_BIN)" provider register --namespace Microsoft.OperationalInsights

ifeq ($(UNAME_S),Windows)
TODAY_STAMP := yy-mm-dd
else
TODAY_STAMP := $(shell date +%Y%m%d)
endif

AZURE_VERSION_SENTINEL_PREFIX  = $(HOME)/.digital-twin/azure-version-sentinel.stamp
AZURE_VERSION_SENTINEL         = $(AZURE_VERSION_SENTINEL_PREFIX).$(TODAY_STAMP)

.SILENT: $(HOME)/.digital-twin/
$(HOME)/.digital-twin/:
	@mkdir -p $(HOME)/.digital-twin

.SILENT: $(HOME)/.digital-twin/azure-version
$(HOME)/.digital-twin/azure-version: $(HOME)/.digital-twin/ $(AZURE_VERSION_SENTINEL)
	"$(AZ_BIN)" version 2>/dev/null -o yaml | head -n 1 | cut -d\  -f2 > $@

.SILENT: $(AZURE_VERSION_SENTINEL)
$(AZURE_VERSION_SENTINEL): $(HOME)/.digital-twin/
	@rm $(AZURE_VERSION_SENTINEL_PREFIX).* 2>/dev/null || true
	@touch $@

.PHONY: azure-version-check
azure-version-check: $(HOME)/.digital-twin/azure-version
	@#echo "Azure version: $(shell cat $(HOME)/.digital-twin/azure-version)"
	@cat $(HOME)/.digital-twin/azure-version

##$(info <--- .make/azure-cli.mk)

endif # _MK_AZURE_CLI_MK_
