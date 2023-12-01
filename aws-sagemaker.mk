ifndef _MK_AWS_SAGEMAKER_MK_
_MK_AWS_SAGEMAKER_MK_ := 1

#$(info ---> .make/aws-sagemaker.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/aws.mk
include $(MK_DIR)/jq.mk
include $(MK_DIR)/sops.mk

.INTERMEDIATE: ./aws-sagemaker-list-notebook-instance-lifecycle-configs.sh
./aws-sagemaker-list-notebook-instance-lifecycle-configs.sh: aws-cli-check jq-check
	@echo "#!/bin/bash" > $@
	@printf "echo \"aws sagemaker list-notebook-instance-lifecycle-configs:\"\n" >> $@
	@#printf "set -x\n" >> $@
	@echo "$(AWS_BIN) sagemaker list-notebook-instance-lifecycle-configs --no-paginate | $(JQ_BIN) -r '.NotebookInstanceLifecycleConfigs[]?.NotebookInstanceLifecycleConfigName' | sort -u" >> $@
	@chmod +x $@

.PHONY: sagemaker-list-notebook-instance-lifecycle-configs
sagemaker-list-notebook-instance-lifecycle-configs: ./aws-sagemaker-list-notebook-instance-lifecycle-configs.sh $(SOPS_EXEC)
	$(SOPS_EXEC) ./aws-sagemaker-list-notebook-instance-lifecycle-configs.sh

.INTERMEDIATE: ./aws-sagemaker-delete-notebook-instance-lifecycle-configs.sh
./aws-sagemaker-delete-notebook-instance-lifecycle-configs.sh: aws-cli-check jq-check
	@echo "#!/bin/bash" > $@
	@printf "echo \"aws sagemaker delete notebook-instance-lifecycle-configs: start\"\n" >> $@
	@#printf "set -x\n" >> $@
	@echo "for config_name in \$$($(AWS_BIN) sagemaker list-notebook-instance-lifecycle-configs --no-paginate | $(JQ_BIN) -r '.NotebookInstanceLifecycleConfigs[]?.NotebookInstanceLifecycleConfigName'); do" >> $@
	@echo "  echo \"aws sagemaker delete notebook-instance-lifecycle-config \$$config_name\"" >> $@
	@echo "  $(AWS_BIN) sagemaker delete-notebook-instance-lifecycle-config --notebook-instance-lifecycle-config-name \$$config_name --no-cli-auto-prompt" >> $@
	@echo "done" >> $@
	@printf "echo \"aws sagemaker delete notebook-instance-lifecycle-configs: done\"\n" >> $@
	@chmod +x $@

.PHONY: sagemaker-delete-notebook-instance-lifecycle-configs
sagemaker-delete-notebook-instance-lifecycle-configs: ./aws-sagemaker-delete-notebook-instance-lifecycle-configs.sh $(SOPS_EXEC)
	$(SOPS_EXEC) ./aws-sagemaker-delete-notebook-instance-lifecycle-configs.sh

#$(info <--- .make/aws-sagemaker.mk)

endif # _MK_AWS_SAGEMAKER_MK_
