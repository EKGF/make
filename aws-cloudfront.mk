ifndef _MK_AWS_CLOUDFRONT_MK_
_MK_AWS_CLOUDFRONT_MK_ := 1

#$(info ---> .make/aws-cloudfront.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

include $(MK_DIR)/aws.mk
include $(MK_DIR)/jq.mk
include $(MK_DIR)/sops.mk

.INTERMEDIATE: ./aws-cloudfront-list-distributions.sh
./aws-cloudfront-list-distributions.sh: aws-cli-check jq-check
	@echo "#!/bin/bash" > $@
	@printf "echo \"aws cloudfront list-distributions:\"\n" >> $@
	@#printf "set -x\n" >> $@
	@echo "$(AWS_BIN) cloudfront list-distributions --no-paginate | $(JQ_BIN) -r '.DistributionList.Items[].Id'" >> $@
	@chmod +x $@

.PHONY: cloudfront-list-distributions
cloudfront-list-distributions: ./aws-cloudfront-list-distributions.sh $(SOPS_EXEC)
	$(SOPS_EXEC) ./aws-cloudfront-list-distributions.sh

.INTERMEDIATE: ./aws-cloudfront-delete-distributions.sh
./aws-cloudfront-delete-distributions.sh: aws-cli-check jq-check
	@echo "#!/bin/bash" > $@
	@printf "echo \"aws cloudfront delete distributions: start\"\n" >> $@
	@#printf "set -x\n" >> $@
	@echo "for distribution_id in \$$($(AWS_BIN) cloudfront list-distributions --no-paginate | $(JQ_BIN) -r '.DistributionList?.Items[]?.Id'); do" >> $@
	@echo "  etag=\$$($(AWS_BIN) cloudfront get-distribution-config --id \$$distribution_id --no-cli-auto-prompt | $(JQ_BIN) -r '.ETag')" >> $@
	@echo "  echo \"aws cloudfront delete distribution \$$distribution_id with Etag \$$etag:\"" >> $@
	@echo "  $(AWS_BIN) cloudfront delete-distribution --id \$$distribution_id --if-match \$$etag --no-cli-auto-prompt" >> $@
	@echo "done" >> $@
	@printf "echo \"aws cloudfront delete distributions: done\"\n" >> $@
	@chmod +x $@

.PHONY: cloudfront-delete-distributions
cloudfront-delete-distributions: ./aws-cloudfront-delete-distributions.sh $(SOPS_EXEC)
	$(SOPS_EXEC) ./aws-cloudfront-delete-distributions.sh

.INTERMEDIATE: ./aws-cloudfront-list-functions.sh
./aws-cloudfront-list-functions.sh: aws-cli-check jq-check
	@echo "#!/bin/bash" > $@
	@printf "echo \"aws cloudfront functions:\"\n" >> $@
	@#printf "set -x\n" >> $@
	@echo "$(AWS_BIN) cloudfront list-functions --no-paginate | $(JQ_BIN) -r '.FunctionList?.Items[]?.Name' | sort -u" >> $@
	@chmod +x $@

.PHONY: cloudfront-list-functions
cloudfront-list-functions: ./aws-cloudfront-list-functions.sh $(SOPS_EXEC)
	$(SOPS_EXEC) ./aws-cloudfront-list-functions.sh

.INTERMEDIATE: ./aws-cloudfront-delete-functions.sh
./aws-cloudfront-delete-functions.sh: aws-cli-check jq-check
	@echo "#!/bin/bash" > $@
	@printf "echo \"aws cloudfront delete functions: start\"\n" >> $@
	@#printf "set -x\n" >> $@
	@echo "for function_name in \$$($(AWS_BIN) cloudfront list-functions --no-paginate | $(JQ_BIN) -r '.FunctionList?.Items[]?.Name'); do" >> $@
	@echo "  echo \"aws cloudfront delete function \$$function_name\"" >> $@
	@echo "  etag=\$$($(AWS_BIN) cloudfront describe-function --name \$$function_name --no-cli-auto-prompt | $(JQ_BIN) -r '.ETag')" >> $@
	@echo "  echo \"aws cloudfront delete function \$$function_name with Etag \$$etag:\"" >> $@
	@echo "  $(AWS_BIN) cloudfront delete-function --name \$$function_name --if-match \$$etag --no-cli-auto-prompt" >> $@
	@echo "done" >> $@
	@printf "echo \"aws cloudfront delete functions: done\"\n" >> $@
	@chmod +x $@

.PHONY: cloudfront-delete-functions
cloudfront-delete-functions: ./aws-cloudfront-delete-functions.sh $(SOPS_EXEC)
	$(SOPS_EXEC) ./aws-cloudfront-delete-functions.sh

#$(info <--- .make/aws-cloudfront.mk)

endif # _MK_AWS_CLOUDFRONT_MK_
