let test_health_check () =
  let handler = Hermes.health_check_handler in
  let request = Dream.request ~method_:`GET "" in
  let response = Dream.test handler request in
  Alcotest.(check int)
    "return status code 200" 200
    (Dream.status response |> Dream.status_to_int)

let test_subscribe_with_valid_data () =
  let handler = Hermes.subscribe_handler in
  let body = "name=le%20guin&email=ursula_le_guin%40gmail.com" in
  let headers = [ ("Content-Type", "application/x-www-form-urlencoded") ] in
  let request = Dream.request ~headers ~method_:`POST body in
  let response = Dream.test ( (Dream.sql_pool "postgres://") @@ handler) request in
  Alcotest.(check int)
    "return status code 200" 200
    (Dream.status response |> Dream.status_to_int)

let test_subscribe_with_invalid_data () =
  let check case =
    let body, error = case in
    let headers = [ ("Content-Type", "application/x-www-form-urlencoded") ] in
    let handler = Hermes.subscribe_handler in
    let request = Dream.request ~headers ~method_:`POST body in
    let response = Dream.test handler request in
    let response_error =
      Format.sprintf
        " The API failed with 400 Bad Request when the payload was %s" error
    in
    Alcotest.(check int)
      response_error 400
      (Dream.status response |> Dream.status_to_int)
  in

  let test_cases =
    [
      ("name=le%20guin", "missing the email");
      ("email=ursula_le_guin%40gmail.com", "missing the name");
      ("", "missing both name and email");
    ]
  in
  List.iter check test_cases

let () =
  let open Alcotest in
  run "Endpoints"
    [
      ("/health_check", [ test_case "Status code 200" `Quick test_health_check ]);
      ( "/subscriptions",
        [
          test_case "Returns status code 200 for valid form data" `Quick
            test_subscribe_with_valid_data;
          test_case "Returns status code 400 for invalid form data" `Quick
            test_subscribe_with_invalid_data;
        ] );
    ]
