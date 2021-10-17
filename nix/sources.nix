{ ocamlVersion ? "4_12" }:

let
  overlays = builtins.fetchTarball
    "https://github.com/anmonteiro/nix-overlays/archive/4e497d8.tar.gz";

in import "${overlays}/boot.nix" {
  overlays = [
    (import overlays)
    (self: super: {
      ocamlPackages =
        super.ocaml-ng."ocamlPackages_${ocamlVersion}".overrideScope'
        (oself: osuper: {
          dream = osuper.dream.overrideAttrs (o: {
            src = super.fetchFromGitHub {
              owner = "aantron";
              repo = "dream";
              rev = "d54b466b4a4444129883dcec06b6220c9cc60236";
              sha256 = "09xjmrgf9f0j27zccqihima8fbsyns4v2hqadbi3rdim0x8yc4rp";
              fetchSubmodules = true;
            };
            propagatedBuildInputs = o.propagatedBuildInputs
              ++ (with oself; [ mirage-clock ]);
          });
        });
    })
  ];
}
