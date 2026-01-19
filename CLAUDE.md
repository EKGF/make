# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GNU Make files for EKG (Enterprise Knowledge Graph) engineers. A collection of 64 reusable `.mk` modules designed to be included by other projects' Makefiles. Cross-platform support for macOS, Linux, and Windows (via WSL).

## Commands

Use `gmake` on macOS (system `make` is version 3, this requires version 4):

```shell
gmake <target>      # macOS
make <target>       # Linux/Windows
```

Common targets:
- `help` - List all available targets
- `oxigraph-serve` - Start OxiGraph server (http://localhost:7879)
- `oxigraph-load` - Load RDF files into OxiGraph
- `oxigraph-reload` - Clear and reload all RDF files
- `<tool>-check` - Verify tool installation and version
- `<tool>-install` - Install a tool

## Architecture

Each `.mk` file is a self-contained module with:
- **Guard clause**: `ifndef _MK_FILENAME_MK_` prevents double-inclusion
- **Standard variables**: `GIT_ROOT`, `MK_DIR` defined at top
- **Dependencies**: Other `.mk` files included via `include $(MK_DIR)/other.mk`
- **Tool verification**: Binary detection, version checking, conditional install targets

Key patterns:
```makefile
# Guard clause (required)
ifndef _MK_EXAMPLE_MK_
_MK_EXAMPLE_MK_ := 1

# Standard variables
ifndef GIT_ROOT
GIT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)
endif
ifndef MK_DIR
MK_DIR := $(GIT_ROOT)/.make
endif

# Binary detection
TOOL_BIN := $(call where-is-binary,tool-name)

# Version checking with conditional install
ifdef TOOL_BIN
ifeq ($(TOOL_VERSION),$(TOOL_VERSION_EXPECTED))
tool-check:
    @echo "Using Tool $(TOOL_VERSION)"
else
tool-check: tool-install
endif
endif

endif # _MK_EXAMPLE_MK_
```

## Key Variables

- `GIT_ROOT` - Repository root (auto-detected)
- `MK_DIR` - Makefiles directory (default: `$(GIT_ROOT)/.make`)
- `TMP_DIR` - Temporary directory (default: `$(GIT_ROOT)/.tmp`)
- `UNAME_S` - OS name (Darwin, Linux, Windows_NT)
- `UNAME_O` - OS type (Cygwin, GNU/Linux)

## File Categories

- **Core**: `make.mk`, `os.mk`, `os-tools.mk`, `git.mk`
- **Cloud**: `aws*.mk`, `azure*.mk`
- **IaC**: `terraform*.mk`, `terragrunt*.mk`
- **Build tools**: `cargo*.mk`, `nodejs*.mk`, `python*.mk`, `docker.mk`
- **Semantic/RDF**: `oxigraph*.mk`, `rdf-files.mk`, `story-sparql-files.mk`

## Opt-in Tools

Many tools are disabled by default and must be explicitly enabled via `USE_*=1` variables in your project's Makefile:

| Variable | Enables | Dependencies |
|----------|---------|--------------|
| `USE_OXIGRAPH=1` | OxiGraph graph database | - |
| `USE_SOPS=1` | SOPS secrets management | - |
| `USE_TERRAFORM=1` | Terraform, TFLint | - |
| `USE_TERRAGRUNT=1` | Terragrunt | `USE_TERRAFORM=1` |
| `USE_RDFOX=1` | RDFox graph database | - |
| `USE_OPEN_NEXT=1` | OpenNext deployment | - |

Dependencies are enforced with errors (e.g., `USE_TERRAGRUNT=1` without `USE_TERRAFORM=1` will fail).

## Conventions

- SPARQL files use `.rq` extension (not `.sparql`)
- Targets: `<tool>-check`, `<tool>-install`, `<resource>-to-load`
- Debug with `$(info ...)` statements (commented out by default)
- Silent mode enabled via `MAKEFLAGS += --silent`

## Migration Notes

- **SOPS → dotenvage**: Phasing out SOPS dependency. Use dotenvage instead (available as Rust crate via `cargo install`/`cargo binstall` or as npm package).

## Contributing

- SSH-signed commits required
- Use conventional commits via Cocogitto: `cog commit <type> "<message>"`
- Types: feat, fix, style, build, refactor, ci, test, perf, chore, revert, docs
- Breaking changes: `cog commit fix -B "<message>"`
