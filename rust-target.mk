ifndef _MK_RUST_TARGET_MK_
_MK_RUST_TARGET_MK_ := 1

#$(info ---> .make/rust-target.mk)

ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

ifndef RUST_TARGET
ifeq ($(UNAME_S),Windows)
RUST_TARGET := $(UNAME_M_rust)-pc-windows-msvc
RUST_TARGET_OS := windows
else
ifeq ($(UNAME_S),Linux)
RUST_TARGET := $(UNAME_M_rust)-unknown-linux-gnu
RUST_TARGET_OS := linux
else
ifeq ($(UNAME_S),Darwin)
RUST_TARGET := $(UNAME_M_rust)-apple-darwin
RUST_TARGET_OS := darwin
else
$(error Unknown operating system $(UNAME_S))
endif
endif
endif
endif

ifdef windows
RUST_TARGET := $(UNAME_M)-pc-windows-msvc
RUST_TARGET_OS := windows
endif

#RUST_BACKTRACE := full
RUST_BACKTRACE := 0
RUST_LIB_BACKTRACE := 0
#RUST_LOG := debug
RUST_LOG := info
#RUST_LOG := warn,test::foo=info,test::foo::bar=debug

#$(info <--- .make/rust-target.mk)

endif # _MK_RUST_TARGET_MK_
