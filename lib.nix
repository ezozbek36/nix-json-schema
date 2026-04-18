{lib, ...}: let
  mapPrimitveType = type:
    if type == "string"
    then lib.types.str
    else if type == "integer" || type == "number"
    then lib.types.int
    else if type == "boolean"
    then lib.types.bool
    else abort "Converting '${type}' into a nix type failed. No convertion for this type was specified.";

  mapByType = jsonSchema:
    if jsonSchema.type == "object"
    then builtins.mapAttrs (key: value: mapObjectDefinition value) jsonSchema.properties
    else if jsonSchema.type == "array"
    then
      lib.mkOptions {
        type = lib.types.listOf (
          if lib.attrsets.hasAttrByPath ["items"] jsonSchema
          then mapObjectDefinition jsonSchema.items
          else lib.types.anything
        );
      }
    else if jsonSchema.type == "string" || jsonSchema.type == "integer" || jsonSchema.type == "number" || jsonSchema.type == "boolean"
    then
      lib.mkOption {
        description = jsonSchema.description;
        type = mapPrimitveType jsonSchema.type;
      }
    else throw "unknow type condition for: ${builtins.toJSON jsonSchema}";

  mapObjectDefinition = jsonSchema:
    if lib.attrsets.hasAttrByPath ["$defs"] jsonSchema
    then builtins.mapAttrs (key: value: mapObjectDefinition value) jsonSchema."$defs"
    else if lib.attrsets.hasAttrByPath ["oneOf"] jsonSchema
    then
      lib.mkOption {
        type = let
          isNullable = lib.lists.any (item: (lib.attrsets.hasAttrByPath ["type"] item) && item.type == "null") jsonSchema.oneOf;
          definition = lib.types.oneOf (map (item: mapObjectDefinition item) jsonSchema.oneOf);
        in
          if isNullable
          then lib.types.nullOr definition
          else definition;
      }
    else if lib.attrsets.hasAttrByPath ["enum"] jsonSchema
    then
      lib.mkOption {
        type = lib.types.enum jsonSchema.enum;
      }
    else if lib.attrsets.hasAttrByPath ["type"] jsonSchema
    then mapByType jsonSchema
    else throw "unknow condition for: ${lib.attrsets.attrNames jsonSchema}";

  jsonSchemaToOptions = jsonSchema:
    if lib.isAttrs jsonSchema
    then mapObjectDefinition jsonSchema
    else throw "unknow condition in jsonSchemaToOptions";
in {
  inherit jsonSchemaToOptions;
}
