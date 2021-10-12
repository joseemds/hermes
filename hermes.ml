let () =
  Dream.run
  @@ Dream.router [
       Dream.get "/healthcheck" (fun _ -> Dream.respond ~code: 200 "")
     ]
  @@ Dream.not_found
