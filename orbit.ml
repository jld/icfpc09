module B = Bigarray
module A = Bigarray.Array1

type ds = (float, B.float64_elt, B.c_layout) A.t
type is = (int32, B.int32_elt, B.c_layout) A.t

let ssize = 16384
let dss () : ds = A.create B.float64 B.c_layout ssize
let iss () : is = A.create B.int32 B.c_layout ssize

external read_prog : string -> (is * ds) 
    = "orbcaml_read_prog"
external orb_step : is -> ds -> ds -> bool -> (int -> float -> unit) -> bool
    = "orbcaml_step"

let copy arr =
  let brr = A.create (A.kind arr) (A.layout arr) (A.dim arr) in
  A.blit arr brr;
  brr
