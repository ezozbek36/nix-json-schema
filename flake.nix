{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }: let
    pkgs = import nixpkgs {system = "x86_64-linux";};
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      flake = rec {
        lib = import ./lib.nix {lib = pkgs.lib;};
        homeModules.default = import ./. {
          inherit pkgs;
          inherit (pkgs) lib config;
          inherit (lib) jsonSchemaToOptions;
        };
      };
      perSystem = {pkgs, ...}: {
        devShells.default = pkgs.mkShellNoCC {
          nativeBuildInputs = with pkgs; [nixd alejandra];
        };
      };
    };
}
