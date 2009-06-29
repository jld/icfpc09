external scattertrace : int -> (float * float) array -> 
  (float * int) array
    = "caml_scattertrace"
external vsize : unit -> int 
    = "caml_st_vsize"

let pi = 3.14159265358979312

let rpo (cx,cy) mr = 
  let r = Random.float mr
  and th = Random.float (2. *. pi) in
  ((cx +. r *. cos th), (cy +. r *. sin th))

let scbe t n c mr =
  let po = Array.init n (fun _ -> rpo c mr) in
  let ra = scattertrace t po in
  let be = ref ((-2., -1),(0.,0.)) in
  for i = 0 to pred n do
    if (fst ra.(i)) > (fst (fst !be)) then
      be := (ra.(i), po.(i))
  done;
  !be

(* 60000 96 3000. 10. *)
let semiauto time nthr dvlim step =
  let rec loop cen dvlim util =
    Printf.printf "scbe %d %d (%g,%g) %g \\ %g\n%!" 
      time nthr (fst cen) (snd cen) dvlim util;
    let ((util',st),cen') = scbe time nthr cen dvlim in
    if st < 0 then
      if util' > util then
	loop cen' (dvlim /. step) util'
      else
	loop cen (dvlim /. step) util
    else begin
      Printf.printf "validating (%.18g,%.18g)...\n%!" (fst cen') (snd cen');
      scbe 2000000 (vsize ()) cen' 0.01
    end in
  loop (0.,0.) dvlim 0.
