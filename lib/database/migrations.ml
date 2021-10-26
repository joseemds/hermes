(* Adapted from https://gist.github.com/anmonteiro/f2e15d60843ef86178ae864608f8f5b6 *)

open Lwt.Infix

let ( let+ ) = Lwt.Syntax.( let+ )

let ( let* ) = Lwt.Syntax.( let* )

let ( let**! ) = Lwt_result.Syntax.( let* )

let ( let++! ) = Lwt_result.Syntax.( let+ )

module Transaction = struct
  let tx ~f connection =
    let (module C : Caqti_lwt.CONNECTION) = connection in
    let**! () = C.start () in
    let* migration_result = f connection in
    match migration_result with
    | Ok result ->
        let++! () = C.commit () in
        result
    | Error error -> (
        match error with
        | #Caqti_error.transact ->
            let**! () = C.rollback () in
            Lwt_result.fail error
        | #Caqti_error.connect -> Lwt_result.fail error)
end

let schema_migrations_table = "schema_migrations"

let migration_filenames =
  let migration_dir =
    Filename.concat (Sys.getcwd ()) "resources/schema-migrations"
  in
  Sys.readdir migration_dir |> Array.to_list
  |> List.filter_map (fun filename ->
         if Filename.extension filename = ".sql" then
           Some (Filename.concat migration_dir filename)
         else None)

module Queries = struct
  let make_migration_query sql =
    Caqti_request.exec
      ~env:
        (fun _driver_info -> function
          | "schema_migrations_table" -> Caqti_query.L schema_migrations_table
          | _ -> raise Not_found)
      ~oneshot:true Caqti_type.unit sql

  let migrate_schema_query =
    make_migration_query
      {| CREATE TABLE IF NOT EXISTS $(schema_migrations_table) (
          id VARCHAR NOT NULL PRIMARY KEY,
          version SERIAl NOT NULL,
          created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
       )
    |}

  let register_migration =
    Caqti_request.exec
      ~env:
        (fun _driver_info -> function
          | "schema_migrations_table" -> Caqti_query.L schema_migrations_table
          | _ -> raise Not_found)
      ~oneshot:true Caqti_type.string
      "INSERT INTO $(schema_migrations_table) (id) VALUES (?)"
end

let load_sql (module C : Caqti_lwt.CONNECTION) filename =
  let rec loop ic =
    let* sql = Caqti_lwt_sql_io.read_sql_statement Lwt_io.read_char_opt ic in
    match sql with
    | None -> Lwt.return_ok ()
    | Some stmt ->
        let**! () = C.exec (Queries.make_migration_query stmt) () in
        loop ic
  in
  Lwt_io.with_file ~flags:[ O_RDONLY ] ~mode:Lwt_io.input filename loop

module StringSet = Set.Make (String)

let get_pending_migrations (module C : Caqti_lwt.CONNECTION) =
  let++! current_migrations =
    C.collect_list
      (Caqti_request.collect ~oneshot:true Caqti_type.unit Caqti_type.string
         (Format.asprintf "SELECT id FROM %s" schema_migrations_table))
      ()
  in
  let current_migrations = StringSet.of_list current_migrations in
  List.filter_map
    (fun filename ->
      let id = Filename.(chop_extension (basename filename)) in
      if StringSet.mem id current_migrations then None else Some (id, filename))
    migration_filenames

let rec migrate connection = function
  | [] -> Lwt_result.return ()
  | (id, filename) :: rest ->
      let f (module C : Caqti_lwt.CONNECTION) =
        let**! () = load_sql (module C) filename in
        C.exec Queries.register_migration id
      in
      let**! () = Transaction.tx ~f connection in
      migrate connection rest

let ensure_schema_and_migrate connection =
  let**! () =
    Transaction.tx connection ~f:(fun (module C : Caqti_lwt.CONNECTION) ->
        (* Transact the schema migration meta-schema. *)
        C.exec Queries.migrate_schema_query ())
  in
  (* Now transact all the migrations to ensure that the schema the
   * application expects exists. *)
  let**! migrations = get_pending_migrations connection in
  Logs.info (fun m ->
      let len = List.length migrations in
      let msg =
        if len = 0 then "No migrations to run"
        else
          Format.asprintf "Running %d migrations: %s" len
            (String.concat "; " (List.map fst migrations))
      in
      m "%s" msg);
  (* TODO: log the latest applied migration in case of error *)
  migrate connection migrations

let migrate connection =
  connection >>= ensure_schema_and_migrate >>= function
  | Ok x -> Lwt.return x
  | _ -> Lwt.return (failwith "Something went wrong during migrations")
