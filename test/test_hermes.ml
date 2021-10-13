let test_health_check () =
    let handler = Hermes.health_check_handler in
    let request = Dream.request ~method_: `GET "" in
    let response = Dream.test handler request in
    Alcotest.(check int) "return status code 200" 200 (Dream.status response |> Dream.status_to_int)

let () =
    let open Alcotest in
    run "Endpoints" [
      "/healthcheck", [
        test_case "Status code 200" `Quick test_health_check
    ]
]
