# anakins-dtls

A Device Tree Language Server written in bash.

> **Note:** This project was built entirely by an [OpenClaw](https://openclaw.ai) AI agent, driven through Telegram **from a phone**. The only time the human touched the code was to test it working in Neovim.

## Features

- **Hover documentation** for all standard Device Tree properties, sourced verbatim from the [Device Tree Specification](https://devicetree-specification.readthedocs.io/)
- **Dynamic binding docs** pulled from the Linux kernel's `Documentation/devicetree/bindings/` — works inside the Linux source tree itself
- **CPP macro hover** — resolves `#define` values from `dt-bindings/` headers included in the file
- **Go-to-definition** — jumps to the binding YAML, spec RST, macro header, or label definition for any property, value, or phandle reference
- **Find references** — finds all usages of a label, compatible string, or property across the include graph
- **Completion** — suggests standard DT properties and binding-specific properties based on the current node's `compatible`
- **Document symbols** — outlines all nodes and labels in the file for the editor sidebar
- **Rename** — renames a label and all `&label` references across included files
- **Diagnostics**:
  - Missing semicolons and unbalanced braces
  - Duplicate properties and duplicate node labels
  - Invalid `status` values
  - `reg` cell count mismatch against `#address-cells` + `#size-cells`
  - Node unit-address mismatch against `reg`
  - Deprecated `linux,phandle`
  - Undocumented properties and missing required properties per the binding YAML
  - `compatible` format warnings (suppressed for known bindings)
  - `clock-names` / `clocks` and `gpio-names` / `gpios` count mismatches
  - Missing `/dts-v1/;` declaration
- **Cross-file phandle resolution** — follows `#include` and `/include/` chains with cycle detection
- **Ancestor-aware** — finds compatible strings by walking up nested node scopes
- **`$ref` following** — resolves inherited properties through YAML `$ref` chains

## Installation

```bash
nix profile add github:anakin4747/anakins-dtls
```

Or clone and install locally:

```bash
git clone https://github.com/anakin4747/anakins-dtls
cd anakins-dtls
git submodule update --init
nix profile add .
```

To update after pulling:

```bash
./switch.sh
```


## How it works

`anakins-dtls` is a single bash script implementing the [Language Server Protocol](https://microsoft.github.io/language-server-protocol/) over stdin/stdout. It uses `jq` for JSON and `rg` (ripgrep) for fast searching through the kernel binding YAML files.

Documentation sources, in order:

1. **Device Tree Specification** — verbatim text for standard properties (`compatible`, `reg`, `status`, etc.)
2. **Linux kernel binding YAML** — from the node's `compatible` string, with `$ref` chain following
3. **Global binding search** — searches all `Documentation/devicetree/bindings/*.yaml` for any property
4. **Linux kernel Documentation `.txt`** — older bindings not yet migrated to YAML
5. **CPP macros** — `#define` values from included `dt-bindings/` headers

When working inside the Linux source tree, the server automatically detects the `Documentation/devicetree/bindings/` directory from the `rootUri` — no configuration needed.

## Tests

```bash
make test
```

Tests use [lsts](https://github.com/anakin4747/lsts) — a bats library for end-to-end LSP testing. All tests use real Linux kernel DTS files as fixtures, not fabricated examples.

## Submodules

- `tests/lsts` — LSP test harness
- `tests/linux` — Linux stable kernel (shallow clone, for tests and binding docs)
- `tests/devicetree-specification` — Device Tree Specification source
