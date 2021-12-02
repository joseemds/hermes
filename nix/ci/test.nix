{ ocamlVersion ? "4_12" }:
let
  pkgs = import ../sources.nix { inherit ocamlVersion; };
  inherit (pkgs) lib stdenv fetchTarball ocamlPackages;

  hermesPkgs = (import ./.. {
    inherit pkgs;
    doCheck = true;
  });
  hermesDrvs = lib.filterAttrs (_: value: lib.isDerivation value) hermesPkgs;

in stdenv.mkDerivation {
  name = "hermes-tests";
  src = lib.filterGitSource {
    src = ../..;
    dirs = [ "lib" "test" ];
    files = [ ".ocamlformat" "hermes.opam" "dune-project" "dune" ];
  };

  inputString = builtins.unsafeDiscardStringContext hermesPkgs.outPath;
  dontBuild = true;
  outputHashMode = "flat";
  outputHashAlgo = "sha256";
  outputHash = builtins.hashString "sha256" inputString;
  installPhase = ''
    touch $out
  '';
  buildInputs = (lib.attrValues hermesDrvs)
    ++ (with ocamlPackages; [ ocaml dune findlib pkgs.ocamlformat ]);
  doCheck = true;
  checkPhase = ''
    # Check if code is formated
    dune build @fmt

    # Run tests
    dune runtest
  '';
}
