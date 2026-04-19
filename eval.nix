let
  pkgs =
    let
    in
    let
      lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
      nixpkgs = fetchTarball {
        url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";
        sha256 = lock.narHash;
      };
    in
    import nixpkgs { };
  lib = import ./lib.nix { lib = pkgs.lib; };
in
pkgs.lib.evalModules {
  modules = [
    (
      { config, ... }:
      {
        config._module.args = {
          inherit pkgs;
          inherit (lib) jsonSchemaToOptions;
        };
      }
    )
    ./default.nix
  ];
}
