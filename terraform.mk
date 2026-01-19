ifndef _MK_TERRAFORM_MK_
_MK_TERRAFORM_MK_ := 1

#$(info ---> .make/terraform.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

#
# Terraform support is disabled by default.
# Set USE_TERRAFORM=1 to enable Terraform functionality.
#
ifeq ($(USE_TERRAFORM),1)

ifndef TF_DIR
TF_DIR := ./terraform
endif

ifndef TF_HAS_LOCAL_STATE
TF_HAS_LOCAL_STATE := 0
endif

ifeq ($(TF_HAS_LOCAL_STATE),1)
ifndef TF_STATE_DIR
TF_STATE_DIR := $(TF_DIR)/.terraform-state/$(TF_VAR_org_short)/$(TF_VAR_environment)
endif
TF_STATE_ARGS := -state=$(TF_STATE_DIR)/terraform.tfstate
else
endif
ifdef TF_STATE_ARGS
$(info TF_STATE_ARGS=$(TF_STATE_ARGS))
endif

include $(MK_DIR)/git.mk
include $(MK_DIR)/sops.mk
include $(MK_DIR)/terraform-install.mk
include $(MK_DIR)/tflint.mk

ifeq ($(USE_SOPS),1)
ifndef SOPS_BIN
$(warning SOPS_BIN is not set)
endif
ifndef SOPS_KEYS_FILE
$(warning SOPS_KEYS_FILE is not set)
endif
endif

$(TF_DIR):
	@echo "ERROR: You're not in a directory with a terraform subdirectory ($(TF_DIR))"
	@echo "       Look under $(GIT_ROOT)/infra"
	@exit 1

ifdef TF_STATE_DIR
$(TF_STATE_DIR):
	@mkdir -p $(TF_STATE_DIR)
endif

.PHONY: terraform-lint
terraform-lint: $(TF_DIR) tflint-check $(SOPS_EXEC)
	@printf "$(bold)Terraform lint on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && $(SOPS_EXEC) $(TFLINT_BIN)

.PHONY: terraform-lint-debug
terraform-lint-debug: $(TF_DIR) tflint-check $(SOPS_EXEC)
	@printf "$(bold)Terraform lint on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && TFLINT_LOG=debug $(SOPS_EXEC) $(TFLINT_BIN)

.PHONY: terraform-init
terraform-init: $(TF_DIR) terraform-check $(TF_STATE_DIR) $(SOPS_EXEC)
	@printf "$(bold)Terraform init on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	@# sops is still necessary here in order to be able to create the S3 backend for terraform state
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAFORM_BIN) init $(TF_STATE_ARGS)

.PHONY: terraform-init-upgrade
terraform-init-upgrade: $(TF_DIR) terraform-check $(TF_STATE_DIR) $(SOPS_EXEC)
	@printf "$(bold)Terraform init on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	@# sops is still necessary here in order to be able to create the S3 backend for terraform state
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAFORM_BIN) init -upgrade $(TF_STATE_ARGS)

.PHONY: terraform-init-migrate
terraform-init-migrate: $(TF_DIR) terraform-check $(TF_STATE_DIR) $(SOPS_EXEC)
	@printf "$(bold)Terraform init on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	@# sops is still necessary here in order to be able to create the S3 backend for terraform state
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAFORM_BIN) init -migrate-state $(TF_STATE_ARGS)

.PHONY: terraform-get
terraform-get: $(TF_DIR) terraform-check $(TF_STATE_DIR) $(SOPS_EXEC)
	@printf "$(bold)Terraform get on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	@# sops is still necessary here in order to be able to create the S3 backend for terraform state
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAFORM_BIN) get $(TF_STATE_ARGS)

.PHONY: terraform-apply
terraform-apply: $(TF_DIR) terraform-check sops-check $(TF_STATE_DIR) $(SOPS_EXEC)
	@printf "$(bold)Terraform apply on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAFORM_BIN) apply -auto-approve $(TF_STATE_ARGS)

.PHONY: terraform-apply-debug
terraform-apply-debug: $(TF_DIR) terraform-check sops-check $(TF_STATE_DIR) $(SOPS_EXEC)
	@printf "$(bold)Terraform apply on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && TF_LOG=DEBUG $(SOPS_EXEC) $(TERRAFORM_BIN) apply -auto-approve $(TF_STATE_ARGS)

.PHONY: terraform-refresh
terraform-refresh: $(TF_DIR) terraform-check sops-check $(TF_STATE_DIR) $(SOPS_EXEC)
	@printf "$(bold)Terraform refresh on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAFORM_BIN) refresh $(TF_STATE_ARGS)

.PHONY: terraform-plan
terraform-plan: $(TF_DIR) terraform-check sops-check $(TF_STATE_DIR) $(SOPS_EXEC)
	@printf "$(bold)Terraform plan on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAFORM_BIN) plan $(TF_STATE_ARGS)

.PHONY: terraform-destroy
terraform-destroy: $(TF_DIR) terraform-check sops-check $(TF_STATE_DIR) $(SOPS_EXEC)
	@printf "$(bold)Terraform destroy on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAFORM_BIN) apply -auto-approve -destroy $(TF_STATE_ARGS)

.PHONY: terraform-destroy-hard
terraform-destroy-hard: $(TF_DIR) terraform-check sops-check $(TF_STATE_DIR) $(SOPS_EXEC)
	@printf "$(bold)Terraform destroy on $(green)$(shell basename $(shell pwd)):$(normal)\n"
	cd $(TF_DIR) && $(SOPS_EXEC) $(TERRAFORM_BIN) destroy $(TF_STATE_ARGS)

endif # USE_TERRAFORM

#$(info <--- .make/terraform.mk)

endif # _MK_TERRAFORM_MK_
