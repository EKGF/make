ifndef _MK_SOPS_GENERATE_MK_
_MK_SOPS_GENERATE_MK_ := 1

#$(info ---> .make/sops-generate.mk)

nosops ?=
NO_SOPS ?=
skip_sops_check ?=

ifeq ($(NO_SOPS),1)
nosops := 1
skip_sops_check := 1
endif

ifneq ($(skip_sops_check),1)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

include $(MK_DIR)/git.mk

#
# Generate the SOPS_KEYS_ORG default value, based on the repository
# name or the organization name
#
$(GIT_ROOT)/.sops-variables.mk:
	echo "Generating $(@F)..."
	set -x ; if [[ $$(uname -n) =~ BT-* ]] ; then \
		echo "SOPS_KEYS_ORG := org1" > $@ ; \
	else \
		echo "SOPS_KEYS_ORG := ekgf" > $@ ; \
		echo "export TF_VAR_org_short := ekgf" >> $@ ; \
		echo "export TF_VAR_project_short := dt" >> $@ ; \
		echo "export TF_VAR_project_long := digital-twin" >> $@ ; \
		echo "export TF_VAR_project_label := Digital Twin" >> $@ ; \
	fi

endif # skip_sops_check

#$(info <--- .make/sops-generate.mk)

endif # _MK_SOPS_GENERATE_MK_
