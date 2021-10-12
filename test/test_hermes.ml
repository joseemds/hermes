let () =
    let handler = Hermes.health_checker_handler  in
    let request = Dream.request ~method_: `GET in
    let response = Dream.test handler request in
    assert response = response
