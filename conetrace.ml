type i = float * float

let iof x = (x, x)

let ilh xl xh =
  if xl <= xh then (xl, xh) else (xh, xl)    

let ipm x pm = 
  if pm > 0.0
  then ((x -. pm), (x +. pm))
  else ((x +. pm), (x -. pm))

let isc (al, ah) (sl, sh) =
  let ad = ah -. al in
  ((al +. (sl *. ad)), (al +. (sh *. ad)))

let ( +: ) (al, ah) (bl, bh) = ((al +. bl), (ah +. bh))
let ( +:> ) (al, ah) x = ((al +. x), (ah +. x))
let ( +:< ) x b = b +:> x

let ( ~-: ) (l, h) = ((~-. h), (~-. l))
let ( -: ) (al, ah) (bl, bh) = ((al -. bh), (ah -. bl))
let ( -:> ) a x = a +:> (~-. x)
let ( -:< ) x (bl, bh) = ((x -. bh), (x -. bl))

let ( *: ) (al, ah) (bl, bh) =
  let c0 = al *. bl
  and c1 = al *. bh
  and c2 = ah *. bl
  and c3 = ah *. bh in
  (* XXX could hoist comparisons *)
  ((min (min c0 c1) (min c2 c3)), (max (max c0 c1) (max c2 c3)))

let ( ~*: ) (al, ah) =
  if al > 0. then
    ((al *. al), (ah *. ah))
  else if ah < 0. then
    ((ah *. ah), (al *. al))
  else
    (0., min (al *. al) (ah *. ah))

let ( *:> ) (al, ah) b = 
  if b > 0. 
  then ((al *. b), (ah *. b))
  else ((ah *. b), (al *. b))
let ( *:< ) a b = b *:> a

let ( ==:> ) (l, h) x = l <= x && x <= h
let ( ==:< ) x a = a ==:> x

let ( ~/. ) x = 1. /. x
let ( ~/: ) ((l, h) as a) = 
  if a ==:> 0.0 then failwith "Divide by zero"
  else ((~/. h), (~/. l))

let ( /: ) a b = a *: (~/: b)
let ( /:> ) a x = a *:> (~/. x)
let ( /:< ) x b = x *:< (~/: b)

let isqrt (al, ah) = ((sqrt al), (sqrt ah))

(*****)

module U = Orbutil
let emu = U.emu
let mmu = U.mmu

(*****)

type vi = i * i

let viof (x, y) = ((iof x), (iof y))
let vilh (xl, yl) (xh, yh) = ((ilh xl xh), (ilh yl yh))
let vipm (xm, ym) (xd, yd) = ((ipm xm xd), (ipm ym yd))
let visc (xa, ya) (xs, ys) = ((isc xa xs), (isc ya ys))

let ( +% ) (ax, ay) (bx, by) = ((ax +: bx), (ay +: by))
let ( +%^ ) (ax, ay) (x, y) = ((ax +:> x), (ay +:> y))
let ( -% ) (ax, ay) (bx, by) = ((ax -: bx), (ay -: by))
let ( -%^ ) (ax, ay) (x, y) = ((ax -:> x), (ay -:> y))
let ( ~-% ) (ax, ay) = ((~-: ax), (~-: ay))

let ( *%+ ) (ax, ay) (bx, by) = (ax *: bx) +: (ay *: by)
let ( *%- ) (ax, ay) (bx, by) = (ax *: by) -: (ay *: bx)
let ( *%> ) (ax, ay) b = ((ax *: b), (ay *: b))
let ( *%< ) a b = b *%> a
let ( *%>> ) (ax, ay) b = ((ax *:> b), (ay *:> b))
let ( *%<< ) a b = b *%>> a
let ( /%> ) a b = a *%> (~/: b)
let ( /%>> ) a b = a *%>> (~/. b)
    
let ( ~*% ) (ax, ay) = (~*: ax) +: (~*: ay)
let ( ~*%! ) a = isqrt (~*% a)

(*****)

let grav mu s =
  let r2 = ~*% s in
  let ga = mu /:< r2
  and r = isqrt r2 in
  ~-: ga *%< (s /%> r)

let tstep s0 v0 =
  let ga0 = grav emu s0 in
  let s1 = s0 +% v0 +% (ga0 /%>> 2.) in
  let ga1 = grav emu s1 in
  let v1 = v0 +% ((ga0 +% ga1) /%>> 2.) in
  (s1, v1)

let gravm sm s =
  (grav emu s) +% (grav mmu (s -%^ sm))

let tstepm sm0 sm1 s0 v0 = 
  let ga0 = gravm sm0 s0 in
  let s1 = s0 +% v0 +% (ga0 /%>> 2.) in
  let ga1 = gravm sm1 s1 in
  let v1 = v0 +% ((ga0 +% ga1) /%>> 2.) in
  (s1, v1)

(* sat ps/vs, sat enablep; our p/v; moon p/v, moonp *)

type vf = float * float

type conetrace = {
    sat_s: vf array; sat_v: vf array; satp: bool array;
    mutable moon_s: vf; mutable moon_v: vf; moonp: bool;
    mutable our_s: vi; mutable our_v: vi }

let ct0 = {
  sat_s = [||]; sat_v = [||]; satp = [||];
  moon_s = 0.,0.; moon_v = 0.,0.; moonp = false;
  our_s = viof (0.,0.); our_v = viof (0.,0.) }

let ct_copy ct =
  { ct with
    sat_s = Array.copy ct.sat_s;
    sat_v = Array.copy ct.sat_v;
    satp = Array.copy ct.satp }

let ct_step ct =
  if ct.moonp then begin
    let sm0 = ct.moon_s and vm0 = ct.moon_v in
    let (sm1, vm1) = U.tstep sm0 vm0 in
    let (s1, v1) = tstepm sm0 sm1 ct.our_s ct.our_v in
    for i = 0 to pred (Array.length ct.sat_s) do
      let (ss1, vs1) = U.tstepm sm0 sm1 ct.sat_s.(i) ct.sat_v.(i) in
      ct.sat_s.(i) <- ss1; ct.sat_v.(i) <- vs1
    done;
    ct.moon_s <- sm1; ct.moon_v <- vm1;
    ct.our_s <- s1; ct.our_v <- v1
  end else begin
    let (s1, v1) = tstep ct.our_s ct.our_v in
    for i = 0 to pred (Array.length ct.sat_s) do
      let (ss1, vs1) = U.tstep ct.sat_s.(i) ct.sat_v.(i) in
      ct.sat_s.(i) <- ss1; ct.sat_v.(i) <- vs1
    done;
    ct.our_s <- s1; ct.our_v <- v1
  end
