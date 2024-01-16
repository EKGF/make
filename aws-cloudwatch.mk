ifndef _MK_AWS_CLOUDWATCH_MK_
_MK_AWS_CLOUDWATCH_MK_ := 1

#$(info ---> .make/aws-cloudwatch.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/aws.mk
include $(MK_DIR)/jq.mk
include $(MK_DIR)/sops.mk

.INTERMEDIATE: ./aws-cloudwatch-log-group-names.sh
./aws-cloudwatch-log-group-names.sh: aws-cli-check jq-check
	@echo "#!/bin/bash" > $@
	@printf "echo \"aws logs describe-log-groups:\"\n" >> $@
	@#printf "set -x\n" >> $@
	@echo "$(AWS_BIN) logs describe-log-groups --no-paginate | $(JQ_BIN) -r '.logGroups[]?.logGroupName'" >> $@
	@chmod +x $@

.PHONY: cloudwatch-log-group-names
cloudwatch-log-group-names: ./aws-cloudwatch-log-group-names.sh $(SOPS_EXEC)
	$(SOPS_EXEC) ./aws-cloudwatch-log-group-names.sh

.INTERMEDIATE: ./aws-cloudwatch-delete-log-groups.sh
./aws-cloudwatch-delete-log-groups.sh: aws-cli-check jq-check
	@echo "#!/bin/bash" > $@
	@printf "echo \"aws logs delete-log-groups: start\"\n" >> $@
	@#printf "set -x\n" >> $@
	@echo "for log_group_name in \$$($(AWS_BIN) logs describe-log-groups --no-paginate | $(JQ_BIN) -r '.logGroups[]?.logGroupName'); do" >> $@
	@echo "  echo \"aws logs delete-log-group --log-group-name 	\$$log_group_name\"" >> $@
	@echo "  $(AWS_BIN) logs delete-log-group --log-group-name \$$log_group_name --no-cli-auto-prompt" >> $@
	@echo "done" >> $@
	@printf "echo \"aws logs delete-log-groups: done\"\n" >> $@
	@chmod +x $@

.PHONY: cloudwatch-delete-log-groups
cloudwatch-delete-log-groups: ./aws-cloudwatch-delete-log-groups.sh $(SOPS_EXEC)
	$(SOPS_EXEC) ./aws-cloudwatch-delete-log-groups.sh

.INTERMEDIATE: ./aws-cloudwatch-list-functions.sh
./aws-cloudwatch-list-functions.sh: aws-cli-check jq-check
	@echo "#!/bin/bash" > $@
	@printf "echo \"aws cloudwatch functions:\"\n" >> $@
	@#printf "set -x\n" >> $@
	@echo "$(AWS_BIN) cloudwatch list-functions --no-paginate | $(JQ_BIN) -r '.FunctionList?.Items[]?.Name' | sort -u" >> $@
	@chmod +x $@

.PHONY: cloudwatch-list-functions
cloudwatch-list-functions: ./aws-cloudwatch-list-functions.sh $(SOPS_EXEC)
	$(SOPS_EXEC) ./aws-cloudwatch-list-functions.sh

.INTERMEDIATE: ./aws-cloudwatch-delete-functions.sh
./aws-cloudwatch-delete-functions.sh: aws-cli-check jq-check
	@echo "#!/bin/bash" > $@
	@printf "echo \"aws cloudwatch delete functions: start\"\n" >> $@
	@#printf "set -x\n" >> $@
	@echo "for function_name in \$$($(AWS_BIN) cloudwatch list-functions --no-paginate | $(JQ_BIN) -r '.FunctionList?.Items[]?.Name'); do" >> $@
	@echo "  echo \"aws cloudwatch delete function \$$function_name\"" >> $@
	@echo "  etag=\$$($(AWS_BIN) cloudwatch describe-function --name \$$function_name --no-cli-auto-prompt | $(JQ_BIN) -r '.ETag')" >> $@
	@echo "  echo \"aws cloudwatch delete function \$$function_name with Etag \$$etag:\"" >> $@
	@echo "  $(AWS_BIN) cloudwatch delete-function --name \$$function_name --if-match \$$etag --no-cli-auto-prompt" >> $@
	@echo "done" >> $@
	@printf "echo \"aws cloudwatch delete functions: done\"\n" >> $@
	@chmod +x $@

.PHONY: cloudwatch-delete-functions
cloudwatch-delete-functions: ./aws-cloudwatch-delete-functions.sh $(SOPS_EXEC)
	$(SOPS_EXEC) ./aws-cloudwatch-delete-functions.sh

#$(info <--- .make/aws-cloudwatch.mk)

endif # _MK_AWS_CLOUDWATCH_MK_
