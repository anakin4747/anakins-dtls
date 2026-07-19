{
  description = "Hello world Lua CLI packaged with Nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      with pkgs; {
        packages.default = stdenvNoCC.mkDerivation {
          pname = "lua-hello-world";
          version = "0.1.0";

          src = ./.;
          dontBuild = true;

          nativeBuildInputs = [ lua ];

          installPhase = ''
            runHook preInstall
            patchShebangs hello.lua
            install -Dm755 hello.lua $out/bin/lua-hello-world
            runHook postInstall
          '';
        };

        checks.default = runCommand "lua-hello-world-check" {
          nativeBuildInputs = [ gnumake lua luaPackages.busted cocogitto ];
          src = ./.;
          IN_NIX_SHELL = 1;
        } ''
          cd "$src"
          make test
          touch "$out"
        '';

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/lua-hello-world";
        };

        devShells.default = mkShell {
          packages = [
            lua
            luaPackages.busted
            cocogitto
            gnumake
          ];
        };
      });
}
