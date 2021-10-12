let health_check_handler = fun _ -> Dream.respond ~code: 200 ""

let server =
  Dream.run
  @@ Dream.router [
       Dream.get "/healthcheck" health_check_handler
     ]
  @@ Dream.not_found
