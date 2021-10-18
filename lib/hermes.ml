let health_check_handler _ = Dream.empty `OK

let subscribe_handler request =
  match%lwt Dream.form ~csrf:false request with
  | `Ok [ ("email", email); ("name", name) ] ->
      Dream.respond ~status:`OK
        (Format.sprintf "Email is: %s, name is: %s" email name)
  | _ -> Dream.respond ~code:400 "Something went wrong"

let server () =
  Dream.run @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/health_check" health_check_handler;
         Dream.post "/subscriptions" subscribe_handler;
       ]
  @@ Dream.not_found
