module Database = Hermes_database
module SQL = Hermes_sql.Sql

let health_check_handler _ = Dream.empty `OK

let ( let* ) = Lwt.Syntax.( let* )

let subscribe_handler request =
  let open SQL in
  let query =
    [%rapper
      execute
        {sql|
     INSERT INTO subscriptions (id, email, name, subscribed_at)
      VALUES (%Uuid{id}::uuid, %string{email}, %string{name}, %ptime{subscribed_at})
    |sql}]
  in

  let id = Uuidm.create `V4 in
  let subscribed_at = Ptime.of_float_s (Unix.gettimeofday ()) |> Option.get in

  match%lwt Dream.form ~csrf:false request with
  | `Ok [ ("email", email); ("name", name) ] -> (
      let* result = Dream.sql request (query ~id ~name ~email ~subscribed_at) in
      match result with
      | Ok _ ->
          Dream.respond ~status:`OK
            (Format.sprintf "Email is: %s, name is: %s" email name)
      | Error e -> failwith (Caqti_error.show e) )
  | _ -> Dream.respond ~code:400 "Something went wrong"

let server ~stop =
  Dream.serve ~stop @@ Dream.logger
  @@ Dream.sql_pool "postgres://postgres:postgres@localhost:5432"
  @@ Dream.router
       [
         Dream.get "/health_check" health_check_handler;
         Dream.post "/subscriptions" subscribe_handler;
       ]
  @@ Dream.not_found
