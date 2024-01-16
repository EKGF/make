ifndef _MK_OS_TOOLS_LINUX_YUM_MK_
_MK_OS_TOOLS_LINUX_YUM_MK_ := 1
ifeq ($(IS_LINUX_WITH_YUM),1)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

SED_BIN := /usr/bin/sed

YUM_CMD 	:= sudo yum-get
YUM_INSTALL := $(YUM_CMD) install -y
YUM_UPDATE 	:= $(YUM_CMD) update -y

.PHONY: yum-update
ifeq ($(RUNNING_IN_DOCKER),1)
yum-update:
	@echo "yum-update: Skipping yum update in Docker"
else
yum-update:
	@$(YUM_UPDATE)
endif

.PHONY: _linux-tool-pkg-config
_linux-tool-pkg-config: yum-update
	$(YUM_INSTALL) pkg-config

.PHONY: _linux-tool-pango
_linux-tool-pango: yum-update
	$(YUM_INSTALL) libsdl-pango-dev

.PHONY: _linux-tool-gtk
_linux-tool-gtk: yum-update
	$(YUM_INSTALL) libgtk-3-dev
	$(YUM_INSTALL) webkit2gtk-4.0

.PHONY: _linux-tool-atk
_linux-tool-atk: yum-update
	$(YUM_INSTALL) librust-atk-dev
	$(YUM_INSTALL) librust-atk-sys-dev

.PHONY: _linux-tool-ayatana
_linux-tool-ayatana: yum-update
	$(YUM_INSTALL) libayatana-appindicator3-dev

.PHONY: _linux-tool-svg
_linux-tool-svg: yum-update
	$(YUM_INSTALL) librsvg2-dev

.PHONY: _linux-tool-elf
_linux-tool-elf: yum-update
	$(YUM_INSTALL) patchelf

.PHONY: _linux-tool-ssl
_linux-tool-ssl: yum-update
	$(YUM_INSTALL) libssl-dev

.PHONY: _linux-tool-appstream
_linux-tool-appstream: yum-update
	$(YUM_INSTALL) appstream

.PHONY: _linux-tool-bsdtar
_linux-tool-bsdtar: yum-update
	$(YUM_INSTALL) libarchive-tools

.PHONY: _linux-tools-install-info
_linux-tools-install-info:
	@echo "Installing linux tools (primarily via yum)"

.PHONY: linux-tools-install
ifeq ($(RUNNING_IN_DOCKER),1)
linux-tools-install:
	@echo "linux-tools-install: Skipping installation of linux tools in Docker"
else
linux-tools-install: _linux-tools-install-info \
	gcc-install \
	llvm-install-with-brew \
	_linux-tool-musl \
	_linux-tool-pkg-config \
	_linux-tool-pango \
	_linux-tool-gtk \
	_linux-tool-atk \
	_linux-tool-ayatana \
	_linux-tool-svg \
	_linux-tool-elf \
	_linux-tool-ssl \
	_linux-tool-appstream \
	_linux-tool-bsdtar \
	sops-check
	@echo "Linux tools have been installed"
endif

endif # ifeq ($(IS_LINUX_WITH_YUM),1)
endif # _MK_OS_TOOLS_LINUX_YUM_MK_
