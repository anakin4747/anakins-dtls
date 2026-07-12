{
  description = "anakins-dtls";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devicetree-specification = {
      url = "github:devicetree-org/devicetree-specification";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, devicetree-specification }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        anakins-dtls = pkgs.python3Packages.buildPythonApplication {
          pname = "anakins-dtls";
          version = "0.1.0";
          src = ./.;
          pyproject = true;
          nativeBuildInputs = [ pkgs.python3Packages.setuptools ];

          preBuild = ''
            ln -s ${devicetree-specification} devicetree-specification
            PYTHONPATH=tools python -c "from generate_docs import write_hover_docs; write_hover_docs()"
          '';
        };

        vscode-extension = pkgs.buildNpmPackage {
          pname = "anakins-dtls-vscode";
          version = "0.0.1";
          src = ./vscode-extension;
          npmDepsHash = "sha256-9FgxK8O2ZTDCtk/f3iKgg9g0Z9k1yhguDTgqKNh4MYU=";
          dontNpmBuild = true;
          nativeBuildInputs = [ pkgs.zip ];
          buildPhase = ''
            node_modules/.bin/esbuild src/extension.ts \
              --bundle \
              --outfile=out/extension.js \
              --external:vscode \
              --format=cjs \
              --platform=node
          '';
          installPhase = ''
            mkdir -p vsix/extension/out
            cp out/extension.js vsix/extension/out/
            cp package.json vsix/extension/
            cat > 'vsix/[Content_Types].xml' << 'XMLEOF'
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
          runtimeInputs = [ pkgs.neovim pkgs.coreutils pkgs.gnused pkgs.gnugrep anakins-dtls ];
          checkPhase = "";
          text = ''
            set +e +u +o pipefail
            kernel_root="$(pwd)"

            dts_files="$(find "$kernel_root/arch" \( -name '*.dts' -o -name '*.dtsi' \) 2>/dev/null | head -n 10 || true)"
            if [[ -z "$dts_files" ]]; then
              echo "tryout-vscode: no .dts files found under $kernel_root/arch" >&2
              echo "Run this from the root of a Linux kernel source tree." >&2
              exit 1
            fi

            ext_vsix="${vscode-extension}/anakins-dtls.vsix"
            profile_dir="$(mktemp -d)"
            mkdir -p "$profile_dir/data/User"
            printf '{"security.workspace.trust.enabled":false}' > "$profile_dir/data/User/settings.json"

            codium \
              --extensions-dir "$profile_dir/extensions" \
              --install-extension "$ext_vsix"

            ANAKINS_DTLS_BIN="$(command -v anakins-dtls)" codium \
              --extensions-dir "$profile_dir/extensions" \
              --user-data-dir "$profile_dir/data" \
              --disable-workspace-trust \
              --wait \
              "$kernel_root" \
              $dts_files || true
          '';
        };

        tryout = pkgs.writeShellApplication {
          name = "tryout";
          runtimeInputs = [ pkgs.neovim pkgs.coreutils pkgs.gnused pkgs.gnugrep anakins-dtls ];
          checkPhase = "";
          text = ''
            set +e +u +o pipefail
            workspace_root="$(pwd)"
            repo_fixture="$workspace_root/tests/fixtures/hover.dts"

            if [[ -f "$repo_fixture" ]]; then
              dts_files="$repo_fixture"
            else
              dts_files="$(find "$workspace_root/arch" \( -name '*.dts' -o -name '*.dtsi' \) 2>/dev/null | shuf -n 10 || true)"
              if [[ -z "$dts_files" ]]; then
                echo "tryout: no local fixture or .dts files found under $workspace_root/arch" >&2
                echo "Run this from the anakins-dtls repo or the root of a Linux kernel source tree." >&2
                exit 1
              fi
            fi

            nvim_config=$(mktemp -d)
            printf 'vim.lsp.set_log_level("debug")\n' > "$nvim_config/init.lua"
            printf 'vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {\n' >> "$nvim_config/init.lua"
            printf '    pattern = { "*.dts", "*.dtsi" },\n' >> "$nvim_config/init.lua"
            printf '    callback = function()\n' >> "$nvim_config/init.lua"
            printf '        vim.lsp.start({\n' >> "$nvim_config/init.lua"
            printf '            name = "anakins-dtls",\n' >> "$nvim_config/init.lua"
            printf '            cmd = { "anakins-dtls" },\n' >> "$nvim_config/init.lua"
            printf '            root_dir = "%s",\n' "$workspace_root" >> "$nvim_config/init.lua"
            printf '            filetypes = { "dts" },\n' >> "$nvim_config/init.lua"
            printf '        })\n' >> "$nvim_config/init.lua"
            printf '    end,\n' >> "$nvim_config/init.lua"
            printf '})\n' >> "$nvim_config/init.lua"

            exec ${pkgs.neovim}/bin/nvim -u "$nvim_config/init.lua" $dts_files
          '';
        };

        tryout-in-tree = pkgs.writeShellApplication {
          name = "tryout-in-tree";
          runtimeInputs = [ pkgs.neovim pkgs.coreutils pkgs.gnused pkgs.gnugrep anakins-dtls ];
          checkPhase = "";
          text = ''
            set +e +u +o pipefail
            workspace_root="$(pwd)"
            fixture_root="$workspace_root/tests/fixtures/kernel_binding"

            if [[ ! -f "$fixture_root/example.dts" ]]; then
              echo "tryout-in-tree: no kernel_binding fixtures found under $fixture_root" >&2
              echo "Run this from the root of the anakins-dtls repo." >&2
              exit 1
            fi

            scratch="$(mktemp -d)"
            checkout_root="$scratch/checkout"
            bindings_dir="$checkout_root/Documentation/devicetree/bindings/testclass"
            mkdir -p "$bindings_dir"
            cp "$fixture_root/example.dts" "$checkout_root/example.dts"
            cp "$fixture_root/bindings/vendor,widget-a.yaml" "$bindings_dir/vendor,widget-a.yaml"

            echo "tryout-in-tree: kernel checkout at $checkout_root" >&2

            nvim_config=$(mktemp -d)
            printf 'vim.lsp.set_log_level("debug")\n' > "$nvim_config/init.lua"
            printf 'vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {\n' >> "$nvim_config/init.lua"
            printf '    pattern = { "*.dts", "*.dtsi" },\n' >> "$nvim_config/init.lua"
            printf '    callback = function()\n' >> "$nvim_config/init.lua"
            printf '        vim.lsp.start({\n' >> "$nvim_config/init.lua"
            printf '            name = "anakins-dtls",\n' >> "$nvim_config/init.lua"
            printf '            cmd = { "anakins-dtls" },\n' >> "$nvim_config/init.lua"
            printf '            root_dir = "%s",\n' "$checkout_root" >> "$nvim_config/init.lua"
            printf '            filetypes = { "dts" },\n' >> "$nvim_config/init.lua"
            printf '        })\n' >> "$nvim_config/init.lua"
            printf '    end,\n' >> "$nvim_config/init.lua"
            printf '})\n' >> "$nvim_config/init.lua"

            exec ${pkgs.neovim}/bin/nvim -u "$nvim_config/init.lua" "$checkout_root/example.dts"
          '';
        };

        tryout-out-of-tree = pkgs.writeShellApplication {
          name = "tryout-out-of-tree";
          runtimeInputs = [ pkgs.neovim pkgs.coreutils pkgs.gnused pkgs.gnugrep anakins-dtls ];
          checkPhase = "";
          text = ''
            set +e +u +o pipefail
            workspace_root="$(pwd)"
            fixture_root="$workspace_root/tests/fixtures/kernel_binding"

            if [[ ! -f "$fixture_root/example.dts" ]]; then
              echo "tryout-out-of-tree: no kernel_binding fixtures found under $fixture_root" >&2
              echo "Run this from the root of the anakins-dtls repo." >&2
              exit 1
            fi

            scratch="$(mktemp -d)"
            project_root="$scratch/project"
            kernel_source_root="$scratch/kernel_source"
            bindings_dir="$kernel_source_root/Documentation/devicetree/bindings/testclass"
            mkdir -p "$project_root" "$bindings_dir"
            cp "$fixture_root/example.dts" "$project_root/example.dts"
            cp "$fixture_root/bindings/vendor,widget-a.yaml" "$bindings_dir/vendor,widget-a.yaml"
            printf 'S=../kernel_source\n' > "$project_root/.anakins-dtls"

            echo "tryout-out-of-tree: project at $project_root" >&2
            echo "tryout-out-of-tree: kernel sources at $kernel_source_root" >&2

            nvim_config=$(mktemp -d)
            printf 'vim.lsp.set_log_level("debug")\n' > "$nvim_config/init.lua"
            printf 'vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {\n' >> "$nvim_config/init.lua"
            printf '    pattern = { "*.dts", "*.dtsi" },\n' >> "$nvim_config/init.lua"
            printf '    callback = function()\n' >> "$nvim_config/init.lua"
            printf '        vim.lsp.start({\n' >> "$nvim_config/init.lua"
            printf '            name = "anakins-dtls",\n' >> "$nvim_config/init.lua"
            printf '            cmd = { "anakins-dtls" },\n' >> "$nvim_config/init.lua"
            printf '            root_dir = "%s",\n' "$project_root" >> "$nvim_config/init.lua"
            printf '            filetypes = { "dts" },\n' >> "$nvim_config/init.lua"
            printf '        })\n' >> "$nvim_config/init.lua"
            printf '    end,\n' >> "$nvim_config/init.lua"
            printf '})\n' >> "$nvim_config/init.lua"

            exec ${pkgs.neovim}/bin/nvim -u "$nvim_config/init.lua" "$project_root/example.dts"
          '';
        };
      in
      {
        packages.default = anakins-dtls;
        packages.tryout = tryout;
        packages.tryout-in-tree = tryout-in-tree;
        packages.tryout-out-of-tree = tryout-out-of-tree;
        packages.tryout-vscode = tryout-vscode;
        packages.vscode-extension = vscode-extension;

        apps.tryout = {
          type = "app";
          program = "${tryout}/bin/tryout";
        };

        apps.tryout-in-tree = {
          type = "app";
          program = "${tryout-in-tree}/bin/tryout-in-tree";
        };

        apps.tryout-out-of-tree = {
          type = "app";
          program = "${tryout-out-of-tree}/bin/tryout-out-of-tree";
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
            cocogitto
            jq
            ripgrep
            python3
            python3Packages.pytest
            python3Packages.pytest-bdd
            python3Packages.pytest-xdist
            python3Packages.setuptools
          ];
        };
      });
}
