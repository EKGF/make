ifndef _MK_AZURE_MK_
_MK_AZURE_MK_ := 1

##$(info ---> .make/azure.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/azure-*.mk

AZURE_DEVOPS_ORGANIZATION := agnos-ai
AZURE_DEVOPS_ORG_URL := https://dev.azure.com/$(AZURE_DEVOPS_ORGANIZATION)/
AZURE_DEVOPS_FEED := agnos-ai
AZURE_KEY_VAULT_NAME := sops-932428ECDD8642A6
AZURE_KEY_VAULT_URL := https://$(AZURE_KEY_VAULT_NAME).vault.azure.net/
AZURE_KEY_VAULT_KEY := $(AZURE_KEY_VAULT_URL)keys/sops-key/69dfc8480a9342fa854eb6f62bba22bd
AZURE_STORAGE_ACCOUNT := dataroad4dev
AZURE_RESOURCE_GROUP := dataroad-dev-resource-group
AZURE_STORAGE_KEY_NAME := key1
AZURE_STORAGE_KEY := nMRcn5NJNmNeGV2193lhgVxzE4YjMK+saMSNftv+gp0ZaOgG2BWQ1GwW0loI4SZd3JWw9n6quQQe+ASttINcPA==
AZURE_SKU_STORAGE := Standard_LRS
AZURE_LOCATION := UK South
AZURE_TAG := project=dataroad deployed-by="$(GIT_USER_NAME)"
AZURE_PLAN := WestEuropeLinuxDynamicPlan

AZURE_FUNCTION_NAME ?= $(subst azure-function-,,$(BASE_NAME_CURRENT_DIRECTORY))
AZURE_FUNCTION_APP_NAME := $(subst azure-function-,dataroad-dev-,$(BASE_NAME_CURRENT_DIRECTORY))
#$(list AZURE_FUNCTION_APP_NAME=$(AZURE_FUNCTION_APP_NAME))

bin-dir:
	@mkdir bin 2>/dev/null || true

.PHONY: azure-install
azure-install: azure-cli-check

.PHONY: azure-check
azure-check: azure-install
	@"$(AZ_BIN)" extension add --name azure-devops 2>/dev/null || \
	"$(AZ_BIN)" extension update --name azure-devops

#
# This check takes too much time, we should write a flag-file or so
# and check its timestamp, if the login-check has been done in the
# past half hour or so then skip it.
#
AZURE_LOGIN_CHECK_STRING := dataroad-subscriptionAzureCloudEnabled
.PHONY: azure-login
azure-login: azure-check
	@if [ "$(AZURE_LOGIN_CHECK_STRING)" != "$(shell "$(AZ_BIN)" account show -o json 2>/dev/null | jq -r '.name + .environmentName + .state')" ] ; then \
		"$(AZ_BIN)" login --allow-no-subscription ; \
	fi

.PHONY: azure-keyvault-show
azure-keyvault-show: azure-login
	"$(AZ_BIN)" keyvault show --name $(AZURE_KEY_VAULT_NAME)

.PHONY: azure-sops-encrypt-keys
azure-sops-encrypt-keys: $(SOPS_KEYS_FILE) azure-login sops-check
	@echo Encrypting content of $(SOPS_KEYS_FILE)
	@sops \
		--encrypt \
		--azure-kv $(AZURE_KEY_VAULT_KEY) \
		--encrypted-regex '^(.*token|.*password|.*TOKEN|.*CONNECTION_STRING|.*KEY|.*_LICENSE_.*)$$' \
		--in-place \
		$(SOPS_KEYS_FILE)

.PHONY: azure-sops-decrypt-keys
azure-sops-decrypt-keys: $(SOPS_KEYS_FILE) azure-login sops-check
	@echo Decrypting $(SOPS_KEYS_FILE)
	@"$(SOPS_BIN)" \
		--decrypt \
		--azure-kv $(AZURE_KEY_VAULT_KEY) \
		$(SOPS_KEYS_FILE)


# Create a resource group
.PHONY: azure-resource-group-create
azure-resource-group-create: azure-login
	@echo "Creating resource group $(AZURE_RESOURCE_GROUP) in location $(AZURE_LOCATION)..."
	"$(AZ_BIN)" group create \
		--name $(AZURE_RESOURCE_GROUP) \
		--location $(AZURE_LOCATION) \
		--tags $(AZURE_TAG)

# Create an Azure storage account in the resource group.
.PHONY: azure-storage-acount-create
azure-storage-account-create: azure-resource-group-create
	@echo "Creating storage account $(AZURE_STORAGE_ACCOUNT)"
	"$(AZ_BIN)" storage account create \
		--name $(AZURE_STORAGE_ACCOUNT) \
		--location $(AZURE_LOCATION) \
		--resource-group $(AZURE_RESOURCE_GROUP) \
		--sku $(AZURE_SKU_STORAGE) \
		--allow-shared-key-access true \
		--tags $(AZURE_TAG) \
		--verbose

.PHONY: azure-storage-account-keys
azure-storage-account-keys: azure-storage-account-create
	"$(AZ_BIN)" storage account keys list \
  		--resource-group $(AZURE_RESOURCE_GROUP)  \
  		--account-name $(AZURE_STORAGE_ACCOUNT)

# Get the storage account connection string.
.PHONY: azure-storage-account-connection-string
.INTERMEDIATE: azure-storage-account-connection-string.tmp
azure-storage-account-connection-string.tmp: azure-login
	"$(AZ_BIN)" storage account show-connection-string \
		--name $(AZURE_STORAGE_ACCOUNT) \
		--resource-group $(AZURE_RESOURCE_GROUP) \
		--query connectionString \
		--output tsv > $@

# Update function app settings to connect to the storage account.
.PHONY: azure-storage-account-link-to-func
azure-storage-account-link-to-func: azure-storage-account-create azure-storage-account-connection-string.tmp
	@echo conn=$(shell cat azure-storage-account-connection-string.tmp)
	"$(AZ_BIN)" functionapp config appsettings set \
		--name $(AZURE_FUNCTION_APP_NAME) \
		--resource-group $(AZURE_RESOURCE_GROUP) \
		--settings "StorageConStr=$(shell cat azure-storage-account-connection-string.tmp)"

.PHONY: azure-functionapp-delete
azure-functionapp-delete: azure-login
	@echo "Deleting FunctionApp $(AZURE_FUNCTION_APP_NAME) (if it already exists)"
	"$(AZ_BIN)" functionapp delete \
		--name $(AZURE_FUNCTION_APP_NAME) \
		--resource-group $(AZURE_RESOURCE_GROUP) \
		--verbose
	sleep 10

# Create a serverless function app in the resource group.
.PHONY: azure-functionapp-create
azure-functionapp-create: azure-storage-account-create azure-functionapp-delete
	@echo "Creating FunctionApp $(AZURE_FUNCTION_APP_NAME)"
	"$(AZ_BIN)" functionapp create \
		--name $(AZURE_FUNCTION_APP_NAME) \
		--os-type Linux \
		--runtime Custom \
		--runtime-version "" \
		--storage-account $(AZURE_STORAGE_ACCOUNT) \
		--consumption-plan-location $(AZURE_LOCATION) \
		--resource-group $(AZURE_RESOURCE_GROUP) \
		--functions-version $(AZURE_FUNC_VERSION_MAJOR) \
		--tags $(AZURE_TAG) \
		--debug

##$(info <--- .make/azure.mk)

endif # _MK_AZURE_MK_
