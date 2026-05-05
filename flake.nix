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
          runtimeInputs = with pkgs; [ bash coreutils jq ripgrep gnused gnugrep gawk ];
          checkPhase = "";
          text = builtins.readFile ./anakins-dtls;
        };

        vscode-extension = pkgs.stdenv.mkDerivation {
          pname = "anakins-dtls-vscode";
          version = "0.0.1";
          src = ./vscode-extension;
          nativeBuildInputs = [ pkgs.zip ];
          installPhase = ''
            mkdir -p vsix/extension/out
            cp out/extension.js vsix/extension/out/
            cp package.json vsix/extension/
            cat > vsix/[Content_Types].xml << 'XMLEOF'
<?xml version="1.0" encoding="utf-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="json" ContentType="application/json"/><Default Extension="js" ContentType="application/javascript"/><Default Extension="vsixmanifest" ContentType="text/xml"/></Types>
XMLEOF
            cat > vsix/extension.vsixmanifest << 'MEOF'
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="anakins-dtls" Version="0.0.1" Publisher="anakin4747"/>
    <DisplayName>anakins-dtls</DisplayName>
    <Description>Device Tree Language Server</Description>
    <Tags>dts,device-tree,lsp</Tags>
  </Metadata>
  <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation>
  <Assets><Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/></Assets>
</PackageManifest>
MEOF
            mkdir -p $out
            (cd vsix && zip -r $out/anakins-dtls.vsix .)
          '';
        };

        tryout-vscode = pkgs.writeShellApplication {
          name = "tryout-vscode";
          runtimeInputs = with pkgs; [ vscodium anakins-dtls ];
          checkPhase = "";
          text = ''
            set +e +u +o pipefail
            kernel_root="$(pwd)"

            dts_file="$(find "$kernel_root/arch" \( -name '*.dts' -o -name '*.dtsi' \) 2>/dev/null | shuf -n 1 || true)"
            if [[ -z "$dts_file" ]]; then
              echo "tryout-vscode: no .dts files found under $kernel_root/arch" >&2
              echo "Run this from the root of a Linux kernel source tree." >&2
              exit 1
            fi

            ext_vsix="${vscode-extension}/anakins-dtls.vsix"
            profile_dir="$(mktemp -d)"

            codium \
              --extensions-dir "$profile_dir/extensions" \
              --install-extension "$ext_vsix" \
              --wait \
              "$dts_file" || true
          '';
        };

        tryout = pkgs.writeShellApplication {
          name = "tryout";
          runtimeInputs = with pkgs; [ nvim coreutils gnused gnugrep anakins-dtls ];
          checkPhase = "";
          text = ''
            set +e +u +o pipefail
            kernel_root="$(pwd)"

            dts_file="$(find "$kernel_root/arch" \( -name '*.dts' -o -name '*.dtsi' \) 2>/dev/null | shuf -n 1 || true)"
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

            exec nvim -u "$nvim_config/init.lua" "$dts_file"
          '';
        };
      in
      {
        packages.default = anakins-dtls;
        packages.tryout = tryout;
        packages.vscode-extension = vscode-extension;
        packages.tryout-vscode = tryout-vscode;

        apps.tryout = {
          type = "app";
          program = "${tryout}/bin/tryout";
        };

        apps.tryout-vscode = {
          type = "app";
          program = "${tryout-vscode}/bin/tryout-vscode";
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
