# anakins-dtls

A Device Tree Language Server

> **NOTE:**
> - v0.2.0 complete re-write with BDD and TDD in python
> - v0.1.0 written with TDD in bash

# features

Since this codebase follows Behaviour Driven Development, all the features are
described in feature files found in the `./features/` directory

## hover

Hover for nodes and properties defined in the Devicetree Specification

## goto definition

Goto defintion for devicetree labels

## goto implementation

Goto implementation for compatible strings to bring the user to the matching
driver in the linux source code

Uses ripgrep for searching your Linux's source code but still a little slow
currently

# usage

Configure your editor to run the language server as such:

```sh
anakins-dtls
```

At some point I will get around to cleaning up the vscode extension for it but
it's not a high priority. VSCode requires language servers to be configured
through extensions instead of just through configuration like other editors.

For a recent build of Neovim, something like this should be enough:

```lua
vim.lsp.config('dts', {
    root_markers = { '.git' },
    filetypes = { 'dts' },
    cmd = { 'anakins-dtls' },
})
vim.lsp.enable('dts')
```

# installation

This project can be installed via Nix like so:

```sh
nix profile add github:anakin4747/anakins-dtls
```

Or can be installed via flake inputs

In the future I will provide other means of installation but since I manage by
Neovim and NixOS configs with Nix this is the main method I need
