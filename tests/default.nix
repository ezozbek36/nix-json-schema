let
  pkgs = import <nixpkgs> {};
  tests = import ./lib.nix {inherit pkgs;};
in
  if tests == []
  then "All tests passed!"
  else throw "Tests failed: ${builtins.toJSON tests}"
