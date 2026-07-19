{
  description = "Hello world Lua CLI packaged with Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        with pkgs; {
          default = stdenvNoCC.mkDerivation {
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
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/lua-hello-world";
        };
      });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in with pkgs; {
          default = mkShell {
            packages = [
              lua
              luaPackages.busted
              cocogitto
              gnumake
            ];
          };
        }
      );
    };
}
