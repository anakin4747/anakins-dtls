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
          runtimeInputs = with pkgs; [ bash jq ripgrep ];
          checkPhase = "";
          text = builtins.readFile ./anakins-dtls;
        };

        tryout = pkgs.writeShellApplication {
          name = "tryout";
          runtimeInputs = [ pkgs.neovim anakins-dtls ];
          checkPhase = "";
          text = ''
            kernel_root="$(pwd)"

            dts_file="$(find "$kernel_root/arch" -name '*.dts' 2>/dev/null | head -1)"
            if [[ -z "$dts_file" ]]; then
              echo "tryout: no .dts files found under $kernel_root/arch" >&2
              echo "Run this from the root of a Linux kernel source tree." >&2
              exit 1
            fi

            nvim_config=$(mktemp -d)
            cat > "$nvim_config/init.lua" << EOF
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*.dts", "*.dtsi" },
    callback = function()
        vim.lsp.start({
            name = "anakins-dtls",
            cmd = { "anakins-dtls" },
            root_dir = "$kernel_root",
            filetypes = { "dts" },
        })
    end,
})
EOF
            exec nvim -u "$nvim_config/init.lua" "$dts_file"
          '';
        };
      in
      {
        packages.default = anakins-dtls;
        packages.tryout = tryout;

        apps.tryout = {
          type = "app";
          program = "${tryout}/bin/tryout";
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
