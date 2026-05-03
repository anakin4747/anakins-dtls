{
  description = "anakins-dtls";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, neovim-nightly }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nvim = neovim-nightly.packages.${system}.default;

        anakins-dtls = pkgs.writeShellApplication {
          name = "anakins-dtls";
          runtimeInputs = with pkgs; [ bash jq ripgrep gnused gnugrep gawk ];
          checkPhase = "";
          text = builtins.readFile ./anakins-dtls;
        };

        tryout = pkgs.writeShellApplication {
          name = "tryout";
          runtimeInputs = with pkgs; [ nvim gnused gnugrep anakins-dtls ];
          checkPhase = "";
          text = ''
            kernel_root="$(pwd)"

            dts_file="$(find "$kernel_root/arch" -name '*.dts' -print -quit 2>/dev/null)"
            if [[ -z "$dts_file" ]]; then
              echo "tryout: no .dts files found under $kernel_root/arch" >&2
              echo "Run this from the root of a Linux kernel source tree." >&2
              exit 1
            fi

            nvim_config=$(mktemp -d)
            printf 'vim.lsp.set_log_level("debug")\n' > "$nvim_config/init.lua"
            printf 'vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {\n' >> "$nvim_config/init.lua"
            printf '    pattern = { "*.dts", "*.dtsi" },\n' >> "$nvim_config/init.lua"
            printf '    callback = function()\n' >> "$nvim_config/init.lua"
            printf '        vim.lsp.start({\n' >> "$nvim_config/init.lua"
            printf '            name = "anakins-dtls",\n' >> "$nvim_config/init.lua"
            printf '            cmd = { "anakins-dtls" },\n' >> "$nvim_config/init.lua"
            printf '            root_dir = "%s",\n' "$kernel_root" >> "$nvim_config/init.lua"
            printf '            filetypes = { "dts" },\n' >> "$nvim_config/init.lua"
            printf '        })\n' >> "$nvim_config/init.lua"
            printf '    end,\n' >> "$nvim_config/init.lua"
            printf '})\n' >> "$nvim_config/init.lua"

            log_path="''${XDG_STATE_HOME:-$HOME/.local/state}/nvim/lsp.log"
            echo "LSP log: $log_path"
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
