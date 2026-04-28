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
          runtimeInputs = with pkgs; [ bash jq ];
          checkPhase = "";
          text = builtins.readFile ./anakins-dtls;
        };
      in
      {
        packages.default = anakins-dtls;

        devShells.default = pkgs.mkShell {
          name = "anakins-dtls";

          packages = with pkgs; [
            bash
            bats
            jq
            shellcheck
            anakins-dtls
          ];
        };
      });
}
