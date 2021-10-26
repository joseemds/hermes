{ pkgs ? import ./sources.nix { inherit ocamlVersion; }, ocamlVersion ? "4_12"
, doCheck ? true }:

let
  inherit (pkgs) lib stdenv ocamlPackages;
  inherit (lib) filterGitSource;

in with ocamlPackages;

let
  genSrc = { dirs, files }:
    filterGitSource {
      src = ./..;
      inherit dirs;
      files = files ++ [ "dune-project" ];
    };
  buildHermes = args:
    buildDunePackage ({
      version = "0.0.1";
      useDune2 = true;
      doCheck = doCheck;
    } // args);
in buildHermes {
  pname = "hermes";
  src = genSrc {
    dirs = [ "lib" "test" ];
    files = [ "hermes.opam" ];
  };

  propagatedBuildInputs = [ dream alcotest ppx_rapper caqti-lwt caqti-driver-postgresql archi-lwt ];
}
