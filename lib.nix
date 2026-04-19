{lib, ...}: let
  resolveRef = rootSchema: ref: let
    isInternal = lib.hasPrefix "#" ref;
    pointer = lib.strings.removePrefix "#/" ref;
    path = lib.strings.splitString "/" pointer;
  in
    if !isInternal
    then throw "$ref '${ref}' is external — only internal refs are supported"
    else lib.attrsets.getAttrFromPath path rootSchema;

  mapPrimitveType = type:
    if type == "string"
    then lib.types.str
    else if type == "integer"
    then lib.types.int
    else if type == "number"
    then lib.types.number
    else if type == "boolean"
    then lib.types.bool
    else abort "No conversion for type '${type}'";

  mapByType = rootSchema: jsonSchema:
    if jsonSchema.type == "object"
    then builtins.mapAttrs (key: value: mapObjectDefinition rootSchema value) jsonSchema.properties
    else if jsonSchema.type == "array"
    then
      lib.mkOptions {
        type = lib.types.listOf (
          if jsonSchema ? items
          then (mapObjectDefinition rootSchema jsonSchema.items).type
          else lib.types.anything
        );
      }
    else if lib.elem jsonSchema.type ["string" "integer" "number" "boolean"]
    then
      lib.mkOption {
        type = mapPrimitveType jsonSchema.type;
        description = jsonSchema.description or "";
      }
    else throw "unknow type condition for: ${lib.typeOf jsonSchema}";

  mapObjectDefinition = rootSchema: jsonSchema:
    if jsonSchema ? "$ref"
    then let
      resolved = resolveRef rootSchema jsonSchema."$ref";
    in
      mapObjectDefinition rootSchema resolved
    else if jsonSchema ? "$defs"
    then builtins.mapAttrs (key: value: mapObjectDefinition rootSchema value) jsonSchema."$defs"
    else if jsonSchema ? oneOf
    then
      lib.mkOption {
        type = let
          variants = map (item: item.type) (map (mapObjectDefinition rootSchema) jsonSchema.oneOf);
          isNullable = lib.lists.any (item: (item ? type) && item.type == "null") jsonSchema.oneOf;
          combined =
            if isNullable && 2 == lib.lists.length variants
            then lib.head variants # TODO: remove actual null definition
            else lib.types.oneOf variants;
        in
          if isNullable
          then lib.types.nullOr combined
          else combined;
      }
    else if jsonSchema ? enum
    then
      lib.mkOption {
        type = lib.types.enum jsonSchema.enum;
      }
    else if jsonSchema ? type
    then mapByType rootSchema jsonSchema
    else if jsonSchema ? const
    then
      # TODO: research value assertion
      lib.mkOption {
        example = jsonSchema.const;
        type = lib.typeOf jsonSchema.const;
      }
    else throw "Unknown schema shape: ${lib.typeOf jsonSchema}";

  jsonSchemaToOptions = jsonSchema:
    if lib.isAttrs jsonSchema
    then mapObjectDefinition jsonSchema jsonSchema
    else throw "jsonSchemaToOptions expects an attrset";
in {
  inherit jsonSchemaToOptions;
}
