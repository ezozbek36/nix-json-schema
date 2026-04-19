{
  lib,
  pkgs,
  config,
  jsonSchemaToOptions,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkIf
    ;

  cfg = config.programs.fastfetchCustom;
in
{
  options = {
    programs.fastfetchCustom = {
      enable = mkEnableOption "Fastfetch";

      package = mkPackageOption pkgs "fastfetch" { nullable = true; };

      settings = jsonSchemaToOptions (
        builtins.fromJSON (builtins.readFile "${pkgs.fastfetch.src}/doc/json_schema.json")
      );
      # settings = jsonSchemaToOptions (builtins.fromJSON (builtins.readFile ./example-schema.json));
    };
  };

  config = mkIf cfg.enable {
    #
  };
}
