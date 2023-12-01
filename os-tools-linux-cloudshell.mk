ifndef _MK_OS_TOOLS_LINUX_CLOUDSHELL_MK_
_MK_OS_TOOLS_LINUX_CLOUDSHELL_MK_ := 1

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
MK_DIR := $(GIT_ROOT)/.make

.PHONY: cloudshell-install
cloudshell-install: _cloudshell-install-info _cloudshell-install-yum-basics

.PHONY: _cloudshell-install-info
_cloudshell-install-info:
	@echo "Starting the installation of the basics in AWS CloudShell"

.PHONY: _cloudshell-install-yum-basics
_cloudshell-install-yum-basics:
	sudo yum groupinstall -y "Development Tools"
	sudo amazon-linux-extras install epel -y
	sudo yum install -y yum-utils
	sudo yum-config-manager --enable epel
	sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
	sudo yum install -y gmp-devel mpfr-devel libmpc-devel zlib-devel vim git rust
	sudo yum install -y amazon-linux-extras

endif # _MK_OS_TOOLS_LINUX_CLOUDSHELL_MK_
