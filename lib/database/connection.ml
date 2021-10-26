let connect =
  Lwt.bind (Caqti_lwt.connect (Uri.of_string "postgresql://")) Caqti_lwt.or_fail
