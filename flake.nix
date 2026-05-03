{
  description = "anakins-dtls";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        anakins-dtls = pkgs.writeShellApplication {
          name = "anakins-dtls";
          runtimeInputs = with pkgs; [ bash coreutils jq ripgrep gnused gnugrep gawk ];
          checkPhase = "";
          text = builtins.readFile ./anakins-dtls;
        };

        tryout = pkgs.writeShellScriptBin "anakins-dtls-tryout" ''
          set -e
          if [ -z "$1" ]; then
            echo "Usage: nix run github:anakin4747r2d2/anakins-dtls#tryout -- /path/to/linux"
            echo ""
            echo "Opens neovim with anakins-dtls configured, rooted at the given Linux source tree."
            exit 1
          fi
          LINUX_DIR="$(realpath "$1")"
          if [ ! -d "$LINUX_DIR" ]; then
            echo "Error: '$LINUX_DIR' is not a directory" >&2
            exit 1
          fi
          dts_file="$(find "$LINUX_DIR/arch" -name '*.dts' -print -quit 2>/dev/null)"
          if [ -z "$dts_file" ]; then
            echo "tryout: no .dts files found under $LINUX_DIR/arch" >&2
            echo "Is this a Linux kernel source tree?" >&2
            exit 1
          fi
          INIT_LUA="$(mktemp --suffix=.lua)"
          trap 'rm -f "$INIT_LUA"' EXIT
          cat > "$INIT_LUA" << 'EOF'
          vim.opt.swapfile = false
          vim.lsp.config("anakins-dtls", {
            cmd = { "${pkgs.lib.getExe anakins-dtls}" },
            filetypes = { "dts", "dtsi" },
            root_markers = { ".git", "Makefile", "Kconfig" },
          })
          vim.lsp.enable("anakins-dtls")
          vim.keymap.set("n", "gd", vim.lsp.buf.definition,       { desc = "Go to definition" })
          vim.keymap.set("n", "gr", vim.lsp.buf.references,       { desc = "Find references" })
          vim.keymap.set("n", "K",  vim.lsp.buf.hover,            { desc = "Hover docs" })
          vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename,    { desc = "Rename symbol" })
          vim.keymap.set("n", "<leader>s", vim.lsp.buf.document_symbol, { desc = "Document symbols" })
          print("anakins-dtls ready — gd=definition  gr=references  K=hover  <leader>r=rename")
          EOF
          cd "$LINUX_DIR"
          exec ${pkgs.lib.getExe pkgs.neovim} -u "$INIT_LUA" "$dts_file"
        '';
      in
      {
        packages.default = anakins-dtls;
        packages.tryout = tryout;

        apps.tryout = {
          type = "app";
          program = "${tryout}/bin/anakins-dtls-tryout";
        };

        devShells.default = pkgs.mkShell {
          name = "anakins-dtls";

          packages = with pkgs; [
            bash
            bats
            jq
            ripgrep
            shellcheck
            anakins-dtls
          ];
        };
      });
}
