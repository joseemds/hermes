{ release-mode ? false }:

let
  pkgs = import ./sources.nix { };
  inherit (pkgs) lib;
  hermesPkgs =
    pkgs.recurseIntoAttrs (import ./sources.nix { inherit pkgs; }).native;
  hermesDrvs = lib.filterAttrs (_: value: lib.isDerivation value) hermesPkgs;

in with pkgs;
(mkShell {
  buildInputs = (with ocamlPackages; [

    # Development packages
    git
    ocaml-lsp
    findlib
    dune
    utop

    # Dependencies
    ocaml
    dream
    alcotest
  ]);

})
