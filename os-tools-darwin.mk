ifndef _MK_OS_TOOLS_DARWIN_MK_
_MK_OS_TOOLS_DARWIN_MK_ := 1

#$(info ---> .make/os-tools-darwin.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

SED_BIN := gsed

ifdef REQUIRES_TECTONIC
REQUIRES_TECTONIC := $(REQUIRES_TECTONIC)
else
REQUIRES_TECTONIC := 0
endif

include $(MK_DIR)/git.mk
include $(MK_DIR)/sops.mk
include $(MK_DIR)/os-tools.mk

export XCODE_SELECT_BIN := $(call where-is-binary,xcode-select)
# This assumes you have installed icu4c via brew
export PKG_CONFIG_PATH := $(HOMEBREW_CELLAR)/icu4c/73.2/lib/pkgconfig

.PHONY: xcode-os-tools-install
ifdef XCODE_SELECT_BIN
xcode-os-tools-install:
else
xcode-os-tools-install:
	@(xcode-select --install || true) 2>&1 | grep -v "are already installed" || true
endif

.PHONY: darwin-tools-install
darwin-tools-install: gcc-install xcode-os-tools-install llvm-install-with-brew sops-check

.PHONY: _darwin-tools-install-info
_darwin-tools-install-info:
	@printf "$(bold)Installing Darwin tools:$(normal)\n"

.PHONY: darwin-tools-install
ifeq ($(RUNNING_IN_DOCKER),1)
darwin-tools-install:
	@echo "darwin-tools-install: Skipping installation of Darwin tools in Docker"
else
darwin-tools-install: _darwin-tools-install-info \
	_darwin-tool-icu4c \
	_darwin-tool-pkg-config \
	_darwin-tool-meson \
	_darwin-tool-gtk-doc \
	_darwin-tool-graphite2 \
	_darwin-tool-freetype2 \
	_darwin-tool-cairo \
	_darwin-tool-glib \
	_darwin-tool-iconv \
	sops-check
	@echo "Darwin tools have been installed"
endif

.PHONY: _darwin-tool-icu4c
_darwin-tool-icu4c:
	@if [ ! -d $(HOMEBREW_CELLAR)/icu4c/73.2 ] ; then $(BREW_BIN) install icu4c ; else printf "$(green)icu4c 73.2$(normal) is already installed\n" ; fi

.PHONY: _darwin-tool-pkg-config
_darwin-tool-pkg-config:
	@if [ ! -d $(HOMEBREW_CELLAR)/pkg-config/0.29* ] ; then $(BREW_BIN) install pkg-config ; else printf "$(green)pkg-config 0.29*$(normal) is already installed\n" ; fi

.PHONY: _darwin-tool-meson
_darwin-tool-meson:
	@if [ ! -d $(HOMEBREW_CELLAR)/meson/1.3.* ] ; then $(BREW_BIN) install meson ; else printf "$(green)meson 1.3.*$(normal) is already installed\n" ; fi

.PHONY: _darwin-tool-gtk-doc
_darwin-tool-gtk-doc:
	@if [ ! -d $(HOMEBREW_CELLAR)/gtk-doc/1.33.* ] ; then $(BREW_BIN) install gtk-doc ; else printf "$(green)gtk-doc 1.33.*$(normal) is already installed\n" ; fi

.PHONY: _darwin-tool-graphite2
_darwin-tool-graphite2:
	@if [ ! -d $(HOMEBREW_CELLAR)/graphite2/1.3.* ] ; then $(BREW_BIN) install graphite2 ; else printf "$(green)graphite2 1.3.*$(normal) is already installed\n" ; fi

.PHONY: _darwin-tool-freetype2
_darwin-tool-freetype2:
	@if [ ! -d $(HOMEBREW_CELLAR)/freetype/2.13.* ] ; then $(BREW_BIN) install freetype2 ; else printf "$(green)freetype2 2.13.*$(normal) is already installed\n" ; fi

.PHONY: _darwin-tool-cairo
_darwin-tool-cairo:
	@if [ ! -d $(HOMEBREW_CELLAR)/cairo/1.18.* ] ; then $(BREW_BIN) install cairo ; else printf "$(green)cairo 1.18.*$(normal) is already installed\n" ; fi

.PHONY: _darwin-tool-glib
_darwin-tool-glib:
	@if [ ! -d $(HOMEBREW_CELLAR)/glib/2.78.* ] ; then $(BREW_BIN) install glib ; else printf "$(green)glib 2.78.*$(normal) is already installed\n" ; fi

.PHONY: _darwin-tool-iconv
_darwin-tool-iconv:
	@if [ ! -d $(HOMEBREW_CELLAR)/libiconv/1.* ] ; then $(BREW_BIN) install libiconv ; else printf "$(green)libiconv 1.*$(normal) is already installed\n" ; fi

#$(info <--- .make/os-tools-darwin.mk)

endif
