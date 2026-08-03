
# anakins-dtls - Anakin's Devicetree Language Server

A Devicetree language server written in Lua using Agentic TDD.

## usage

Configure your editor to launch the language server with the following command:
```sh
anakins-dtls
```

## configuration

Since a Devicetree can be in a Yocto or Buildroot project which is outside the
Linux kernel source tree, `anakins-dtls` has a config file that connects out of
tree devicetrees to the kernel source tree.

For Yocto you can generate a config file like so:
```sh
bitbake-getvar S -r virtual/kernel > .anakins-dtls
```

For Buildroot you can generate a config file like so:
```sh
make -s --no-print-directory printvars VARS=LINUX_DIR > .anakins-dtls
```

## tests

This application was written using test driven development. This repo uses a
Nix flake, `./flake.nix`, to define the development environment so the `nix`
package manager is the only requirement for running the tests.

To run the tests simply run:
```sh
make
```

## documentation

One of the benefits of test driven development is that the tests document the
behaviour of the software under test. Therefore the tests are the
documentation.

Run the following command to get an overview of all the features of the
language server:
```sh
make
```

## installation

This application is managed by a Nix flake, `./flake.nix`, so installation can
be done via the `nix` package manager or through the inputs of other flakes.

To install the language server and its dependencies run:
```sh
nix profile add github:anakin4747/anakins-dtls
```

Or after cloning this repo:
```sh
make install
```

Or as the input of another Nix flake:
```nix
{
  description = "Example Nix Flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    dtls = {
      url = "github:anakin4747/anakins-dtls";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }:
  # ...
}
```

Or if you do not want to use `nix` you can manually install after cloning with:
```sh
make manual-install
```
But you will have to install `lua` and `ripgrep` as well.

### uninstallation

If installed with `nix`:
```sh
nix profile remove anakins-dtls
```

If installed with `nix` by the Makefile:
```sh
make uninstall
```

If manually installed without `nix` through the Makefile:
```sh
make manual-uninstall
```

## features

### hover

All nodes and properties defined in the Devicetree Specification have hover
documentation from the specification.

### goto definition

Goto definition for node labels.

Goto definition for CPP macros.

### goto implementation

Goto driver implementation when the cursor is on a compatible value that maps
to a driver in the kernel source tree.

### diagnostics

Minimal diagnostics for missing semicolons or closing braces. More diagnostics
will be added in the future as needed.

Note that diagnostics only update on saving to disk.

### document symbols

Providing documents symbols.

## future features

See `./TODO.md` has my notes on what I want to implement in the future.
