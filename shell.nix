{ release-mode ? false }:

let
  pkgs = import ./nix/sources.nix { };
  inherit (pkgs) stdenv lib;
  hermesPkgs =
    pkgs.recurseIntoAttrs (import ./nix { inherit pkgs; });
  hermesDrvs = lib.filterAttrs (_: value: lib.isDerivation value) hermesPkgs;

in with pkgs;
(mkShell {
  inputsFrom = lib.attrValues hermesDrvs;
  buildInputs = (with ocamlPackages; [

    # Development packages
    git
    ocaml-lsp
    findlib
    dune
    utop
    ocamlformat
    ocaml
  ]);

})
