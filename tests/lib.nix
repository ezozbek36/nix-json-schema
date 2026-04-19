{
  pkgs ? import <nixpkgs> { },
}:
let
  lib = import ../lib.nix { inherit (pkgs) lib; };
  inherit (pkgs.lib) runTests;

  # Helper to extract type description for comparison
  getType = opt: opt.type.description;
in
runTests {
  testString = {
    expr = getType (lib.jsonSchemaToOptions { type = "string"; });
    expected = "string";
  };

  testInteger = {
    expr = getType (lib.jsonSchemaToOptions { type = "integer"; });
    expected = "signed integer";
  };

  testNumber = {
    expr = getType (lib.jsonSchemaToOptions { type = "number"; });
    expected = "signed integer or floating point number";
  };

  testBoolean = {
    expr = getType (lib.jsonSchemaToOptions { type = "boolean"; });
    expected = "boolean";
  };

  testArrayAnything = {
    expr = getType (lib.jsonSchemaToOptions { type = "array"; });
    expected = "list of anything";
  };

  testArrayString = {
    expr = getType (
      lib.jsonSchemaToOptions {
        type = "array";
        items = {
          type = "string";
        };
      }
    );
    expected = "list of string";
  };

  testObject = {
    expr =
      let
        res = lib.jsonSchemaToOptions {
          type = "object";
          properties = {
            foo = {
              type = "string";
            };
          };
        };
      in
      getType res.foo;
    expected = "string";
  };

  testEnum = {
    expr = getType (
      lib.jsonSchemaToOptions {
        enum = [
          "a"
          "b"
          "c"
        ];
      }
    );
    expected = "one of \"a\", \"b\", \"c\"";
  };

  testConst = {
    expr =
      let
        res = lib.jsonSchemaToOptions { const = "foo"; };
      in
      {
        type = res.type.description;
        example = res.example;
      };
    expected = {
      type = "string";
      example = "foo";
    };
  };

  testOneOf = {
    expr = getType (
      lib.jsonSchemaToOptions {
        oneOf = [
          { type = "string"; }
          { type = "integer"; }
        ];
      }
    );
    expected = "string or signed integer";
  };

  testNullable = {
    expr = getType (
      lib.jsonSchemaToOptions {
        oneOf = [
          { type = "string"; }
          { type = "null"; }
        ];
      }
    );
    expected = "null or string";
  };

  testRef = {
    expr =
      let
        schema = {
          "$defs" = {
            myString = {
              type = "string";
            };
          };
          properties = {
            foo = {
              "$ref" = "#/$defs/myString";
            };
          };
        };
        res = lib.jsonSchemaToOptions schema;
      in
      getType res.foo;
    expected = "string";
  };
}
