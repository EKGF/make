ifndef _MK_OS_TOOLS_LINUX_APT_MK_
_MK_OS_TOOLS_LINUX_APT_MK_ := 1
ifeq ($(IS_LINUX_WITH_APT),1)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

ifeq ($(UNAME_O),Cygwin)
#$(info We're running under Cygwin)
APT_GET := /usr/bin/apt-cyg
else
APT_GET := sudo apt-get
endif
APT_INSTALL := $(APT_GET) install -y -qq

SED_BIN := /usr/bin/sed

.PHONY: apt-update
ifeq ($(RUNNING_IN_DOCKER),1)
apt-update:
	@echo "apt-update: Skipping apt-get update in Docker"
else
apt-update:
	@$(APT_GET) update -y -qq
endif

.PHONY: _linux-tool-musl
ifeq ($(RUNNING_IN_DOCKER),1)
_linux-tool-musl:
	@echo "_linux-tool-musl: Skipping installation of musl tools in Docker"
else
_linux-tool-musl: apt-update
	@echo "Installing musl tools:"
	@dpkg -s musl >/dev/null 2>&1 || \
	$(APT_INSTALL) musl
	@dpkg -s musl-dev >/dev/null 2>&1 || \
	$(APT_INSTALL) musl-dev
	@dpkg -s musl-tools >/dev/null 2>&1 || \
	$(APT_INSTALL) musl-tools
	# set -x ; which musl-gcc || true
	# set -x ; musl-gcc --version 2>/dev/null || true
	# set -x ; x86_64-linux-musl-gcc --version 2>/dev/null || true
	# set -x ; /usr/local/bin/x86_64-linux-musl-gcc --version 2>/dev/null || true
	# set -x ; find / -name x86_64-linux-musl-gcc 2>/dev/null || true
	# set -x ; ln -fvs "/usr/bin/g++" "/usr/bin/musl-g++" || true
	# set -x ; ln -fvs "/usr/local/bin/g++" "/usr/local/bin/musl-g++" || true
endif

.PHONY: _linux-tool-pkg-config
_linux-tool-pkg-config: apt-update
	@dpkg -s pkg-config >/dev/null 2>&1 || \
	$(APT_INSTALL) pkg-config

.PHONY: _linux-tool-pango
_linux-tool-pango: apt-update
	@dpkg -s libsdl-pango-dev >/dev/null 2>&1 || \
	$(APT_INSTALL) libsdl-pango-dev

.PHONY: _linux-tool-gtk
_linux-tool-gtk: apt-update
	@dpkg -s libgtk-3-dev >/dev/null 2>&1 || \
	$(APT_INSTALL) libgtk-3-dev
	@dpkg -s webkit2gtk-4.0 >/dev/null 2>&1 || \
	$(APT_INSTALL) webkit2gtk-4.0

.PHONY: _linux-tool-atk
_linux-tool-atk: apt-update
	@dpkg -s librust-atk-dev >/dev/null 2>&1 || \
	$(APT_INSTALL) librust-atk-dev
	@dpkg -s librust-atk-sys-dev >/dev/null 2>&1 || \
	$(APT_INSTALL) librust-atk-sys-dev

.PHONY: _linux-tool-ayatana
_linux-tool-ayatana: apt-update
	@dpkg -s libayatana-appindicator3-dev >/dev/null 2>&1 || \
	$(APT_INSTALL) libayatana-appindicator3-dev

.PHONY: _linux-tool-svg
_linux-tool-svg: apt-update
	@dpkg -s librsvg2-dev >/dev/null 2>&1 || \
	$(APT_INSTALL) librsvg2-dev

.PHONY: _linux-tool-elf
_linux-tool-elf: apt-update
	@dpkg -s patchelf >/dev/null 2>&1 || \
	$(APT_INSTALL) patchelf

.PHONY: _linux-tool-ssl
_linux-tool-ssl: apt-update
	@dpkg -s libssl-dev >/dev/null 2>&1 || \
	$(APT_INSTALL) libssl-dev

.PHONY: _linux-tool-appstream
_linux-tool-appstream: apt-update
	@dpkg -s appstream >/dev/null 2>&1 || \
	$(APT_INSTALL) appstream

.PHONY: _linux-tool-bsdtar
_linux-tool-bsdtar: apt-update
	@dpkg -s libarchive-tools >/dev/null 2>&1 || \
	$(APT_INSTALL) libarchive-tools

.PHONY: _linux-tools-install-info
_linux-tools-install-info:
	@echo "Installing linux tools (primarily via apt)"

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

endif # ifeq ($(IS_LINUX_WITH_APT),1)
endif # _MK_OS_TOOLS_LINUX_APT_MK_
