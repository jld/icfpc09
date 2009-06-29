external scattertrace : ((float * float) * int) list ->
  int -> (float * float) array -> (float * int) array
    = "caml_scattertrace"
external vsize : unit -> int 
    = "caml_st_vsize"

let pi = 3.14159265358979312

let rpo (cx,cy) mr = 
  let r = Random.float mr
  and th = Random.float (2. *. pi) in
  ((cx +. r *. cos th), (cy +. r *. sin th))

let scbe pl t n c mr =
  let po = Array.init n (fun _ -> rpo c mr) in
  let ra = scattertrace pl t po in
  let be = ref ((-2., -1),(0.,0.)) in
  for i = 0 to pred n do
    if (fst ra.(i)) > (fst (fst !be)) then
      be := (ra.(i), po.(i))
  done;
  !be

let validate pl cen =
  Printf.printf "validating (%.18g,%.18g)...\n%!" (fst cen) (snd cen);
  scbe pl 2000000 (vsize ()) cen 0.01

exception Bees

(* 60000 96 3000. 10. or 1500. 5. *)
let semiauto ?(valid=true) ?(pl=[]) time nthr dvlim step =
  let rec loop cen dvlim util =
    if util < 1e-3 && util > dvlim then
      raise Bees;
    Printf.printf "scbe %d %d (%g,%g) %g \\ %g\n%!" 
      time nthr (fst cen) (snd cen) dvlim util;
    let ((util',st),cen') as sret = scbe pl time nthr cen dvlim in
    if st <= 0 then
      if util' > util then
	loop cen' (dvlim /. step) util'
      else
	loop cen (dvlim /. step) util
    else if valid then
      validate pl cen'
    else
      sret
  in
  loop (0.,0.) dvlim 0.

let abstrace pl =
  List.rev (snd (List.fold_left (fun (t0,stuff) (cen,del) ->
    (t0 + del),((t0,cen)::stuff)) (0,[]) pl))

let printout scen atr =
  let b = Buffer.create 1024 in
  List.iter (fun (t,(x,y)) ->
    if (t == 0) then
      Printf.bprintf b "h 39 %d\nf 0 3\n 16000 %d\n" scen scen
    else
      Printf.bprintf b "f %d 2\n" t;
    Printf.bprintf b " 2 %.18g\n 3 %.18g\n" x y;
    Printf.bprintf b "f %d 2\n 2 0\n 3 0\n" (succ t)) atr;
  Printf.bprintf b "f 2000000 0\n";
  Buffer.contents b

(* 11 50000 96 1500. 5. *)
let moreauto nhop time nthr dvlim step =
  let finish rpl =
    let (lcen,ld)::rpl' = rpl in
    let (_,lcen') = validate rpl' lcen in
    abstrace (List.rev ((lcen',ld)::rpl')) in
  let rec loop rpl nhop =
    if nhop > 0 then
      match begin try 
	Some (semiauto ~valid:false ~pl:(List.rev rpl)
		time nthr dvlim step)
      with
	Bees -> None
      end with
	Some ((_,st),cen) ->
	  loop ((cen,st)::rpl) (pred nhop)
      | None -> finish rpl
    else
      finish rpl
  in 
  loop [] nhop
