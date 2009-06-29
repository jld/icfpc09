external scattertrace : ((float * float) * int) list ->
  int -> (float * float) array -> (float * int) array
    = "caml_scattertrace"
external vsize : unit -> int 
    = "caml_st_vsize"

let pi = 3.14159265358979312

let rpo (cx,cy) mr = 
  let r = (Random.float (mr ** 0.5)) ** 2.0
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
(* If I were awake I'd factor out all the retry/xtra stuff into 
   a separate thing that would eat all the bees. *)
let semiauto ?(valid=true) ?(pl=[]) ?(xtra=(0,1.0,0)) ?(brake=1e-7) time nthr dvlim step =
  let (xtra,rstep,tstep) = xtra in
  let rec loop time xtra cen dvlim util =
    if util < 1e-3 && dvlim < 1e-3 (* XXX this won't go now *) then
      raise Bees;
    Printf.printf "scbe %d %d (%g,%g) %g \\ %g\n%!" 
      time nthr (fst cen) (snd cen) dvlim util;
    let ((util',st),cen') as sret = scbe pl time nthr cen dvlim in
    if util = 0. && util' < brake then begin
      if xtra == 0 then raise Bees;
      loop (time + tstep) (pred xtra) cen (dvlim *. rstep) util
    end else if st <= 0 then
      let dvlim' = dvlim /. step in
      if util' > util then
	loop time xtra cen' dvlim' util'
      else
	loop time xtra cen dvlim' util
    else if valid then
      validate pl cen'
    else
      sret
  in
  loop time xtra (0.,0.) dvlim 0.

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

(* 4004: 12 50000 96 1500. 5.  but that was an older version *)
(* 4003: ~xtra:(12,1.1,0) 12 100000 96 1000. 5. *)
(* 4002: ~xtra:(12,1.1,10000) 12 50000 96 1000. 5. *)
(* 4002: that with ~brake:1e-6 *)
let moreauto ?(xtra=(0,1.0,0)) ?(brake=1e-7) nhop time nthr dvlim step =
  let finish rpl =
    let (lcen,ld)::rpl' = rpl in
    let (_,lcen') = validate rpl' lcen in
    abstrace (List.rev ((lcen',ld)::rpl')) in
  let rec loop rpl nhop =
    if nhop > 0 then
      match begin try 
	Some (semiauto ~valid:false ~pl:(List.rev rpl) ~xtra ~brake
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
