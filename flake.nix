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

        tryoutInitLua = ./scripts/tryout-init.lua;

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

            exec ${pkgs.neovim}/bin/nvim -u ${tryoutInitLua} $dts_files
          '';
        };

        tryout-kernel-binding = pkgs.writeShellApplication {
          name = "tryout-kernel-binding";
          runtimeInputs = [ pkgs.neovim pkgs.coreutils anakins-dtls ];
          checkPhase = "";
          text = ''
            set +e +u +o pipefail
            context="''${1:-}"
            if [[ "$context" != "in-tree" && "$context" != "out-of-tree" ]]; then
              echo "usage: tryout-kernel-binding <in-tree|out-of-tree>" >&2
              exit 1
            fi

            workspace_root="$(pwd)"
            fixture_root="$workspace_root/tests/fixtures/kernel_binding"
            if [[ ! -f "$fixture_root/example.dts" ]]; then
              echo "tryout-kernel-binding: no kernel_binding fixtures found under $fixture_root" >&2
              echo "Run this from the root of the anakins-dtls repo." >&2
              exit 1
            fi

            scratch="$(mktemp -d)"
            binding_relpath="Documentation/devicetree/bindings/testclass/vendor,widget-a.yaml"

            if [[ "$context" == "in-tree" ]]; then
              root="$scratch/checkout"
              mkdir -p "$root/$(dirname "$binding_relpath")"
              cp "$fixture_root/bindings/vendor,widget-a.yaml" "$root/$binding_relpath"
            else
              root="$scratch/project"
              kernel_source="$scratch/kernel_source"
              mkdir -p "$root" "$kernel_source/$(dirname "$binding_relpath")"
              cp "$fixture_root/bindings/vendor,widget-a.yaml" "$kernel_source/$binding_relpath"
              printf 'S=../kernel_source\n' > "$root/.anakins-dtls"
            fi

            mkdir -p "$root"
            cp "$fixture_root/example.dts" "$root/example.dts"

            echo "tryout-kernel-binding ($context): root at $root" >&2

            cd "$root"
            exec ${pkgs.neovim}/bin/nvim -u ${tryoutInitLua} example.dts
          '';
        };

        tryout-in-tree = pkgs.writeShellScript "tryout-in-tree" ''
          exec ${tryout-kernel-binding}/bin/tryout-kernel-binding in-tree
        '';

        tryout-out-of-tree = pkgs.writeShellScript "tryout-out-of-tree" ''
          exec ${tryout-kernel-binding}/bin/tryout-kernel-binding out-of-tree
        '';
      in
      {
        packages.default = anakins-dtls;
        packages.tryout = tryout;
        packages.tryout-kernel-binding = tryout-kernel-binding;
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
          program = "${tryout-in-tree}";
        };

        apps.tryout-out-of-tree = {
          type = "app";
          program = "${tryout-out-of-tree}";
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
