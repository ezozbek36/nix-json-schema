{ lib, ... }:
let
  stripMeta =
    schema:
    removeAttrs schema [
      "$defs"
      "$schema"
      "$id"
      "$comment"
      "title"
      "description"
      "examples"
      "default"
    ];

  mkResolveFn =
    rootSchema: ref:
    if !(lib.strings.hasPrefix "#" ref) then
      throw "External $ref '${ref}' not supported"
    else
      let
        path = lib.strings.splitString "/" (lib.strings.removePrefix "#/" ref);
      in
      lib.attrsets.getAttrFromPath path rootSchema;

  partitionNullable =
    schemas:
    let
      isNullable = s: (s ? type) && s.type == "null";
      nonNulls = lib.filter (s: !(isNullable s)) schemas;
      hasNull = lib.length nonNulls < lib.length schemas;
    in
    {
      inherit hasNull nonNulls;
    };

  typeFor =
    resolveRef: schema:
    let
      s = stripMeta schema;
    in
    if s ? "$ref" then
      typeFor resolveRef (resolveRef s."$ref")

    else if s ? "oneOf" then
      let
        p = partitionNullable s.oneOf;
        t = lib.types.oneOf (map (typeFor resolveRef) p.nonNulls);
      in
      if p.hasNull then lib.types.nullOr t else t

    else if s ? "anyOf" then
      let
        p = partitionNullable s.anyOf;
        t = lib.types.oneOf (map (typeFor resolveRef) p.nonNulls);
      in
      if p.hasNull then lib.types.nullOr t else t

    else if s ? "enum" then
      lib.types.enum s.enum

    else if s ? "type" then
      if s.type == "string" then
        lib.types.str
      # TODO: research diffs with nix/json numeric types
      else if s.type == "integer" || s.type == "number" then
        lib.types.int
      else if s.type == "boolean" then
        lib.types.bool
      else if s.type == "null" then
        # TODO: research
        lib.types.nullOr lib.types.anything
      else if s.type == "array" then
        lib.types.listOf (if s ? items then typeFor resolveRef s.items else lib.types.anything)
      else if s.type == "object" then
        lib.types.submodule { options = propsFor resolveRef s; }
      else if s == { } then
        lib.types.anything
      else
        throw "Unknown type '${s.type}'"

    else
      throw "Cannot derive type from: ${lib.concatStringsSep ", " (lib.attrNames s)}";

  optionFor =
    resolveRef: schema:
    let
      resolved = if schema ? "$ref" then resolveRef schema."$ref" else schema;
    in
    lib.mkOption (
      {
        type = typeFor resolveRef resolved;
      }
      // lib.optionalAttrs (resolved ? description) { description = resolved.description; }
      // lib.optionalAttrs (resolved ? default) { default = resolved.default; }
      # TODO: improve examples parsing
      // lib.optionalAttrs (resolved ? examples) { example = lib.head resolved.examples; }
    );

  propsFor =
    resolveRef: schema:
    builtins.mapAttrs (key: propSchema: optionFor resolveRef propSchema) schema.properties;

  jsonSchemaToOptions =
    jsonSchema:
    if !(lib.isAttrs jsonSchema) then
      throw "jsonSchemaToOptions expects an attrset"
    else
      let
        resolveRef = mkResolveFn jsonSchema;
      in
      propsFor resolveRef jsonSchema;

in
{
  inherit jsonSchemaToOptions;
}
