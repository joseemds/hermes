open Lwt.Infix
open Archi_lwt

module Connection = struct
  let start () =
    Format.eprintf "Created database connection @.";
    Lwt_result.return Hermes.Database.Connection.connect

  let stop connection =
    connection >>= fun (module Conn : Caqti_lwt.CONNECTION) ->
    Conn.disconnect ()

  let component = Component.make ~start ~stop
end

module Migrations = struct
  let start () connection =
    Format.eprintf "Running migrations@.";
    Lwt_result.return (Hermes.Database.Migrations.migrate connection)

  let stop _migrations = Lwt.return ()

  let component =
    Component.using ~start ~stop ~dependencies:[ Connection.component ]
end

module WebServer = struct
  type server = { promise_to_stop : unit Lwt.u; server_promise : unit Lwt.t }

  let start () _ =
    Format.eprintf "Running webserver@.";
    let waiter, wakener = Lwt.wait () in
    let server = Hermes.server ~stop:waiter in
    Lwt_result.return { promise_to_stop = wakener; server_promise = server }

  let stop server = Lwt.return (Lwt.wakeup_later server.promise_to_stop ())

  let component = Component.using ~start ~stop ~dependencies: [Migrations.component]
end

let system =
  System.make
    [
      ("connection", Connection.component);
      ("migrations", Migrations.component);
      ("server", WebServer.component);
    ]

let main () =
  System.start () system >>= fun system ->
  match system with
  | Ok system ->
      let forever, waiter = Lwt.wait () in
      Sys.(
        set_signal sigint
          (Signal_handle
             (fun _ ->
               Format.eprintf "SIGINT received, tearing down.@.";
               Lwt.async (fun () ->
                   System.stop system >|= fun _stopped_system ->
                   Lwt.wakeup_later waiter ()))));
      forever
  | Error error -> (
      match error with
      | `Cycle_found -> failwith "Cycle_found"
      | `Msg msg -> failwith msg)

let () = Lwt_main.run (main ())
