module B = Bigarray
module A = Bigarray.Array1

type ds = (float, B.float64_elt, B.c_layout) A.t
type is = (int32, B.int32_elt, B.c_layout) A.t

let ssize = 16384
let dss () : ds = A.create B.float64 B.c_layout ssize
let iss () : is = A.create B.int32 B.c_layout ssize

external read_prog : string -> (is * ds) 
    = "orbcaml_read_prog"
external orb_step : is -> ds -> ds -> bool ref -> (int -> float -> unit) -> unit
    = "orbcaml_step"

let copy arr =
  let brr = A.create (A.kind arr) (A.layout arr) (A.dim arr) in
  A.blit arr brr;
  brr

let orb_step_list insns data input rstat =
  let lr = ref [] in
  orb_step insns data input rstat (fun a v -> lr := (a,v)::!lr);
  List.rev !lr

let orb_step_array insns data input rstat =
  let lr = ref [] and mr = ref 0 in
  orb_step insns data input rstat (fun a v -> 
    lr := (a,v)::!lr;
    mr := max !mr (succ a));
  let arr = Array.create !mr 0.0 in
  List.iter (fun (a,v) -> arr.(a) <- v) !lr;
  arr

let in_scene scene =
  let arr = dss() in
  A.fill arr 0.0;
  A.set arr 0x3E80 (float_of_int scene);
  arr
