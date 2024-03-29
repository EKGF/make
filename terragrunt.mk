ifndef _MK_TERRAGRUNT_MK_
_MK_TERRAGRUNT_MK_ := 1

#$(info ---> .make/terragrunt.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/git.mk
include $(MK_DIR)/sops.mk
include $(MK_DIR)/terraform.mk
include $(MK_DIR)/terragrunt-install.mk

ifndef SOPS_BIN
$(warning SOPS_BIN is not set)
endif
ifndef SOPS_KEYS_FILE
$(warning SOPS_KEYS_FILE is not set)
endif

.PHONY: terragrunt-init
terragrunt-init: $(TF_DIR) terragrunt-check $(TF_STATE_DIR) $(SOPS_EXEC)
	@printf "$(bold)Terragrunt $(blue)init$(black) on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	@# sops is still necessary here to be able to create the S3 backend for terraform state
	set -x ; cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive init $(TF_STATE_ARGS)

.PHONY: terragrunt-init-upgrade
terragrunt-init-upgrade: $(TF_DIR) terragrunt-check $(TF_STATE_DIR)
	@printf "$(bold)Terragrunt $(blue)init -upgrade$(black) on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	@# sops is still necessary here to be able to create the S3 backend for terraform state
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive --terragrunt-log-level=debug init -upgrade $(TF_STATE_ARGS)

.PHONY: terragrunt-init-migrate
terragrunt-init-migrate: $(TF_DIR) terragrunt-check $(TF_STATE_DIR)
	@printf "$(bold)Terragrunt $(blue)init -migrate-state$(black) on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	@# sops is still necessary here to be able to create the S3 backend for terraform state
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive --terragrunt-log-level=debug init -migrate-state $(TF_STATE_ARGS)

.PHONY: terragrunt-init-reconfigure
terragrunt-init-reconfigure: $(TF_DIR) terragrunt-check $(TF_STATE_DIR)
	@printf "$(bold)Terragrunt $(blue)init -reconfigure$(black) on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	@# sops is still necessary here to be able to create the S3 backend for terraform state
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive --terragrunt-log-level=debug init -reconfigure $(TF_STATE_ARGS)

.PHONY: terragrunt-get
terragrunt-get: $(TF_DIR) terragrunt-check $(TF_STATE_DIR)
	@printf "$(bold)Terragrunt $(blue)get$(black) on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	@# sops is still necessary here in order to be able to create the S3 backend for terraform state
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive get $(TF_STATE_ARGS)

.PHONY: terragrunt-state-list
terragrunt-state-list: $(TF_DIR) terragrunt-check $(TF_STATE_DIR)
	@printf "$(bold)Terragrunt $(blue)state-list$(black) on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	@# sops is still necessary here in order to be able to create the S3 backend for terraform state
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive state list $(TF_STATE_ARGS)

ifdef GREP_RESOURCE
.PHONY: terragrunt-state-rm
terragrunt-state-rm: $(TF_DIR) terragrunt-check $(TF_STATE_DIR)
	@printf "$(bold)Terragrunt $(blue)state rm$(black) on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	@# sops is still necessary here to be able to create the S3 backend for terraform state
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive state list $(TF_STATE_ARGS) | grep $(GREP_RESOURCE) | \
		while read resource ; do $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive state rm $(TF_STATE_ARGS) $$resource ; done
endif

.PHONY: terragrunt-apply
terragrunt-apply: $(TF_DIR) terragrunt-check sops-check $(TF_STATE_DIR)
	@printf "$(bold)Terragrunt $(blue)apply$(black) on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && $(SOPS_EXEC) export
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive --terragrunt-log-level=debug apply -auto-approve $(TF_STATE_ARGS)

.PHONY: terragrunt-apply-debug
terragrunt-apply-debug: $(TF_DIR) terragrunt-check sops-check $(TF_STATE_DIR)
	@printf "$(bold)Terragrunt $(blue)apply$(black) on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && TF_LOG=DEBUG $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive apply -auto-approve $(TF_STATE_ARGS)

.PHONY: terragrunt-refresh
terragrunt-refresh: $(TF_DIR) terragrunt-check sops-check $(TF_STATE_DIR)
	@printf "$(bold)Terragrunt refresh on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive refresh $(TF_STATE_ARGS)

.PHONY: terragrunt-plan
terragrunt-plan: $(TF_DIR) terragrunt-check sops-check $(TF_STATE_DIR)
	@printf "$(bold)Terragrunt plan on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive plan $(TF_STATE_ARGS)

.PHONY: terragrunt-destroy
terragrunt-destroy: $(TF_DIR) terragrunt-check sops-check $(TF_STATE_DIR)
	@printf "$(bold)Terragrunt destroy on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive apply -auto-approve -destroy $(TF_STATE_ARGS)

.PHONY: terragrunt-destroy-hard
terragrunt-destroy-hard: $(TF_DIR) terragrunt-check sops-check $(TF_STATE_DIR)
	@printf "$(bold)Terragrunt destroy on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive destroy $(TF_STATE_ARGS)

.PHONY: terragrunt-import-resources
ifdef TF_IMPORT_RESOURCES
export TF_IMPORT_RESOURCES
terragrunt-import-resources: $(TF_DIR) terragrunt-check sops-check $(TF_STATE_DIR)
	@printf "$(bold)Terragrunt import resources $(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && while read address id ; do \
		printf "$(bold)%-90s $(green)%s$(normal)\n" "$$address" "$$id"; \
	done < <(echo "$${TF_IMPORT_RESOURCES}")
	cd $(TF_DIR) && while read address id ; do \
		printf "\n\nImport $(bold)$$address $(green)$$id$(normal):\n"; \
		if $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive $(TF_STATE_ARGS) import -input=false $${address//\"/\\\"} $$id | \
			grep -v "Read complete" | \
			grep -v "Still reading" | \
			grep -v "Reading..."; \
		then \
		  printf "$(bold)$$address $(green)$$id$(normal) imported\n"; \
		else \
		  printf "$(bold)$$address $(red)$$id$(normal) import failed\n"; \
		fi; \
	done < <(echo "$${TF_IMPORT_RESOURCES}")
else
ifdef TF_VAR_org_short
# If TF_VAR_org_short exists and TF_IMPORT_RESOURCES doesn't we
# can assume that you're running in a SOPS shell and that there's
# nothing to import.
terragrunt-import-resources:
	@printf "$(bold)No resources to import$(normal)\n"
else
# If even TF_VAR_org_short doesn't exist we can assume that you're
# not running in a SOPS shell and that you want to import resources
# that depend on secret values, so restart the make process in a
# SOPS shell.
terragrunt-import-resources:
	@printf "$(bold)Restarting make in a SOPS shell$(normal)\n"
	$(SOPS_EXEC) $(MAKE) --no-print-directory $(MAKECMDGOALS)
endif
endif

.PHONY: terragrunt-taint
ifdef TF_TAINT_RESOURCES
terragrunt-taint: $(TF_DIR) terragrunt-check sops-check $(TF_STATE_DIR)
	@printf "$(bold)Terragrunt taint on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAGRUNT_BIN) --terragrunt-non-interactive taint $(TF_STATE_ARGS) $(TF_TAINT_RESOURCES)
else
terragrunt-taint:
	@printf "$(bold)No resources to taint$(normal)\n"
endif
#$(info <--- .make/terragrunt.mk)

endif # _MK_TERRAGRUNT_MK_
