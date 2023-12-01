ifndef _MK_AWS_IAM_MK_
_MK_AWS_IAM_MK_ := 1

#$(info ---> .make/aws-iam.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/aws.mk
include $(MK_DIR)/jq.mk
include $(MK_DIR)/sops.mk

.INTERMEDIATE: aws-iam-list-policies.sh
./aws-iam-list-policies.sh: aws-cli-check jq-check
	echo "#!/bin/bash" > $@
	printf "echo \"aws iam list-policies:\"\n" >> $@
	#printf "set -x\n" >> $@
	echo "$(AWS_BIN) iam list-policies --scope Local --no-paginate | $(JQ_BIN) -r '.Policies[].PolicyName'" >> $@
	chmod +x $@

.PHONY: iam-list-policies
iam-list-policies: ./aws-iam-list-policies.sh $(SOPS_EXEC)
	$(SOPS_EXEC) ./aws-iam-list-policies.sh

.INTERMEDIATE: ./aws-iam-delete-policies.sh
./aws-iam-delete-policies.sh: aws-cli-check jq-check
	@echo "#!/bin/bash" > $@
	@printf "echo \"aws iam delete policies: start\"\n" >> $@
	@#printf "set -x\n" >> $@
	@echo "for policy_arn in \$$($(AWS_BIN) iam list-policies --scope Local --no-paginate | $(JQ_BIN) -r '.Policies[].Arn'); do" >> $@
	@echo "  echo \"aws iam delete policy \$$policy_arn:\"" >> $@
	@echo "  $(AWS_BIN) iam list-policy-versions --policy-arn \$$policy_arn --no-cli-auto-prompt --no-paginate | jq" >> $@
	@echo "  for version_id in \$$($(AWS_BIN) iam list-policy-versions --policy-arn \$$policy_arn --no-cli-auto-prompt --no-paginate | $(JQ_BIN) -r '.Versions[].VersionId'); do" >> $@
	@echo "    echo \"Delete policy version \$$version_id\"" >> $@
	@echo "    $(AWS_BIN) iam delete-policy-version --policy-arn \$$policy_arn --version-id \$$version_id --no-cli-auto-prompt" >> $@
	@echo "	 done" >> $@
	@echo "  $(AWS_BIN) iam list-entities-for-policy --policy-arn \$$policy_arn --no-cli-auto-prompt" >> $@
	@echo "  $(AWS_BIN) iam delete-policy --policy-arn \$$policy_arn --no-cli-auto-prompt" >> $@
	@echo "done" >> $@
	@printf "echo \"aws iam delete policies: done\"\n" >> $@
	@chmod +x $@

.PHONY: iam-delete-policies
iam-delete-policies: ./aws-iam-delete-policies.sh iam-delete-roles $(SOPS_EXEC)
	$(SOPS_EXEC) ./aws-iam-delete-policies.sh

.INTERMEDIATE: ./aws-iam-list-roles.sh
./aws-iam-list-roles.sh: aws-cli-check jq-check
	@echo "#!/bin/bash" > $@
	@printf "echo \"aws iam list-roles:\"\n" >> $@
	@#printf "set -x\n" >> $@
	@echo "$(AWS_BIN) iam list-roles --no-paginate | $(JQ_BIN) -r '.Roles[].RoleName'" >> $@
	@chmod +x $@

.PHONY: iam-list-roles
iam-list-roles: ./aws-iam-list-roles.sh $(SOPS_EXEC)
	$(SOPS_EXEC) ./aws-iam-list-roles.sh

.INTERMEDIATE: ./aws-iam-delete-roles.sh
./aws-iam-delete-roles.sh: aws-cli-check jq-check
	@echo "#!/bin/bash" > $@
	@printf "echo \"aws iam delete roles: start\"\n" >> $@
	@#printf "set -x\n" >> $@
	@echo "for role_name in \$$($(AWS_BIN) iam list-roles | $(JQ_BIN) -r '.Roles[].RoleName'); do" >> $@
	@echo "  [[ \"\$$role_name\" = AWS* ]] && continue" >> $@
	@echo "  echo \"aws iam delete-role --role-name \$$role_name\"" >> $@
	@echo "  for policy_name in \$$($(AWS_BIN) iam list-role-policies --role-name \$$role_name --no-cli-auto-prompt --no-paginate | $(JQ_BIN) -r '.PolicyNames[]'); do" >> $@
	@echo "    echo \"Detaching from role \$$role_name: Policy [\$$policy_name\"]" >> $@
	@echo "    $(AWS_BIN) iam delete-role-policy --role-name \$$role_name --policy-name \$$policy_name --no-cli-auto-prompt" >> $@
	@echo "	 done" >> $@
	@echo "  for policy_arn in \$$($(AWS_BIN) iam list-attached-role-policies --role-name \$$role_name --no-cli-auto-prompt --no-paginate | $(JQ_BIN) -r '.AttachedPolicies[].PolicyArn'); do" >> $@
	@echo "    echo \"Detaching from role \$$role_name: Policy [\$$policy_arn\"]" >> $@
	@echo "    $(AWS_BIN) iam detach-role-policy --role-name \$$role_name --policy-arn \$$policy_arn --no-cli-auto-prompt" >> $@
	@echo "	 done" >> $@
	@echo "  $(AWS_BIN) iam delete-role --role-name \$$role_name --no-cli-auto-prompt" >> $@
	@echo "done" >> $@
	@echo "echo \"aws iam delete roles: done\"" >> $@
	@chmod +x $@

.PHONY: iam-delete-roles
iam-delete-roles: ./aws-iam-delete-roles.sh $(SOPS_EXEC)
	$(SOPS_EXEC) ./aws-iam-delete-roles.sh

#$(info <--- .make/aws-iam.mk)

endif # _MK_AWS_IAM_MK_
