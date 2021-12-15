let connect =
  Lwt.bind
    (Caqti_lwt.connect
       (Uri.of_string "postgresql://postgres:postgres@localhost:5432"))
    Caqti_lwt.or_fail
