let
  flake = builtins.getFlake (builtins.toString ./.);
  pkgs = import flake.inputs.nixpkgs {};
  lib = import ./lib.nix {lib = pkgs.lib;};
in
  flake.inputs.nixpkgs.lib.evalModules {
    modules = [
      ({config, ...}: {
        config._module.args = {
          inherit pkgs;
          inherit (lib) jsonSchemaToOptions;
        };
      })
      ./default.nix
    ];
  }
