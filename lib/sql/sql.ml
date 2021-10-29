module Uuid : Rapper.CUSTOM with type t = Uuidm.t = struct
  type t = Uuidm.t

  let t =
    let encode uuid = Ok (Uuidm.to_string uuid) in
    let decode s = Option.to_result ~none:"Invalid UUID" (Uuidm.of_string s) in
    Caqti_type.(custom ~encode ~decode string)
end
