let health_check_handler _ = Dream.respond ~code:200 ""

let server () =
  Dream.run
  @@ Dream.router
       [
         Dream.get "/health_check" health_check_handler;
         Dream.post "/subscribe" health_check_handler;
       ]
  @@ Dream.not_found
