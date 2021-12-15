{ release-mode ? false }:

let
  pkgs = import ./nix/sources.nix { };
  inherit (pkgs) stdenv lib;
  hermesPkgs = pkgs.recurseIntoAttrs (import ./nix { inherit pkgs; });
  hermesDrvs = lib.filterAttrs (_: value: lib.isDerivation value) hermesPkgs;

in with pkgs;
(mkShell {
  inputsFrom = lib.attrValues hermesDrvs;
  buildInputs = [
    less
    postgresql
    git
    inotify-tools
    curl
  ] ++  (with ocamlPackages; [

    # Development packages
    ocaml-lsp
    findlib
    dune
    utop
    ocamlformat
    ocaml
  ]);
  shellHook = ''
    export PGDATA=$PWD/postgres_data
    export PGHOST=$PWD/postgres
    export LOG_PATH=$PWD/postgres/LOG
    export PGDATABASE=postgres
    export DATABASE_URL="postgresql:///postgres?host=$PGHOST"
    if [ ! -d $PGHOST ]; then
      mkdir -p $PGHOST
    fi
    if [ ! -d $PGDATA ]; then
      echo 'Initializing postgresql database...'
      initdb $PGDATA --auth=trust >/dev/null
    fi
    pg_ctl start -l $LOG_PATH -o "-c listen_addresses= -c unix_socket_directories=$PGHOST"
  '';

})
