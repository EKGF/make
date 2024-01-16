#
# Deal with the Azure Functions Core Tools
#
# https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=v4%2Cmacos%2Ccsharp%2Cportal%2Cbash#v2
#
ifndef _MK_AZURE_FUNC_MK_
_MK_AZURE_FUNC_MK_ := 1

#$(info ---> .make/azure-func.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

AZURE_FUNC_VERSION_MAJOR := 4
AZURE_FUNC_VERSION := $(shell func --version 2>/dev/null)
AZURE_FUNC_EXPECTED_VERSION := 4.0.4544

ifndef AZURE_FUNC_VERSION
AZURE_FUNC_NEEDS_TO_BE_INSTALLED := 1
endif
ifneq ($(AZURE_FUNC_VERSION),$(AZURE_FUNC_EXPECTED_VERSION))
AZURE_FUNC_NEEDS_TO_BE_INSTALLED := 1
endif

.PHONY: azure-func-check
ifeq ($(AZURE_FUNC_NEEDS_TO_BE_INSTALLED),1)
azure-func-check: azure-functions-install
else
azure-func-check:
endif

.PHONY: azure-functions-install
azure-functions-install: azure-functions-core-tools-install azure-functions-musl-tools-install

.PHONY: azure-functions-core-tools-install
azure-functions-core-tools-install: brew-check
	$(BREW_BIN) tap azure/functions
	$(BREW_BIN) install azure-functions-core-tools@4

.PHONY: azure-functions-musl-tools-install
azure-functions-musl-tools-install: brew-check musl-cross-install
	$(BREW_BIN) install mingw-w64

.PHONY: azure-list-included-files
azure-list-included-files: azure-func-check
	func azure functionapp publish $(AZURE_FUNCTION_APP_NAME) --list-included-files

.PHONY: azure-list-ignored-files
azure-list-ignored-files: azure-func-check
	func azure functionapp publish $(AZURE_FUNCTION_APP_NAME) --list-ignored-files

.PHONY: wait15
wait15:
	sleep 15

.PHONY: azure-deploy
azure-deploy: azure-func-check azure-build azure-functionapp-create wait15 azure-publish
	@echo "Wait 15s"
	@sleep 15

.PHONY: azure-publish
azure-publish: azure-func-check azure-build
	@echo "Publish FunctionApp $(AZURE_FUNCTION_APP_NAME)"
	CLI_DEBUG=1 func azure functionapp publish $(AZURE_FUNCTION_APP_NAME) --publish-local-settings --overwrite-settings --force --verbose

#$(info <--- .make/azure-func.mk)

endif # _MK_AZURE_FUNC_MK_
