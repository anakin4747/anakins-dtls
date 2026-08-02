{
  description = "anakins-dtls, packaged, plus dtls-fixtures for trying it out in Neovim";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        version = "0.1.0";
        revision = self.rev or (self.dirtyRev or "unknown");
      in
      with pkgs; {
        packages.default = stdenvNoCC.mkDerivation {
          pname = "anakins-dtls";
          inherit version;

          src = ./.;
          dontBuild = true;

          nativeBuildInputs = [ lua makeWrapper ];

          installPhase = ''
            runHook preInstall
            patchShebangs lua/anakins-dtls.lua
            install -Dm755 lua/anakins-dtls.lua $out/bin/anakins-dtls
            wrapProgram $out/bin/anakins-dtls \
              --prefix PATH : ${lib.makeBinPath [ lua ripgrep ]} \
              --set ANAKINS_DTLS_VERSION ${lib.escapeShellArg version} \
              --set ANAKINS_DTLS_REVISION ${lib.escapeShellArg revision}
            runHook postInstall
          '';
        };

        checks.default = runCommand "lua-hello-world-check" {
          nativeBuildInputs = [ gnumake lua luaPackages.busted luaPackages.luacheck cocogitto stylua ripgrep ];
          src = ./.;
          IN_NIX_SHELL = 1;
        } ''
          cd "$src"
          make
          touch "$out"
        '';

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/anakins-dtls";
        };

        packages.tryout = writeShellApplication {
          name = "tryout";
          runtimeInputs = [ neovim lua self.packages.${system}.default ];
          checkPhase = "";
          text = ''
            set +e +u +o pipefail
            context="''${1:-in-tree}"
            if [[ "$context" != "in-tree" && "$context" != "out-of-tree" ]]; then
              echo "usage: tryout [in-tree|out-of-tree]" >&2
              exit 1
            fi

            repo_root="$(pwd)"

            if [[ "$context" == "in-tree" ]]; then
              workspace_root="$repo_root/tests/in-tree"
              relative_dts="arch/arm64/boot/dts/freescale/custom.dts"
            else
              workspace_root="$repo_root/tests/out-of-tree"
              relative_dts="custom.dts"
            fi

            if [[ ! -e "$workspace_root/$relative_dts" ]]; then
              echo "tryout: fixture not found at $workspace_root/$relative_dts" >&2
              echo "Run this from the root of the dtls-fixtures repo." >&2
              exit 1
            fi

            cd "$workspace_root"
            exec ${neovim}/bin/nvim -u ${./scripts/tryout-init.lua} "$relative_dts"
          '';
        };

        apps.tryout = {
          type = "app";
          program = "${self.packages.${system}.tryout}/bin/tryout";
        };

        apps.tryout-in-tree = {
          type = "app";
          program = "${writeShellScript "tryout-in-tree" ''
            exec ${self.packages.${system}.tryout}/bin/tryout in-tree
          ''}";
        };

        apps.tryout-out-of-tree = {
          type = "app";
          program = "${writeShellScript "tryout-out-of-tree" ''
            exec ${self.packages.${system}.tryout}/bin/tryout out-of-tree
          ''}";
        };

        devShells.default = mkShell {
          packages = [
            lua
            luaPackages.busted
            luaPackages.luacheck
            stylua
            cocogitto
            gnumake
            ripgrep
          ];
        };
      });
}
