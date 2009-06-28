type i = float * float

let iof x = (x, x)

let ilh xl xh =
  if xl <= xh then (xl, xh) else (xh, xl)    

let ipm x pm = 
  if pm > 0
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
let ( ~/: ) ((l, h) as i) = 
  if a ==:> 0 then failwith "Divide by zero"
  else ((~/. h), (~/. l))

let ( /: ) a b = a *: (~/: b)
let ( /:> ) a x = a *:> (~/. x)
let ( /:< ) x b = x *:< (~/: b)

let isqrt (al, ah) = ((sqrt al), (sqrt ah))

(*****)

type vi = i * i

let ( +% ) (ax, ay) (bx, by) = ((ax +: bx), (ay +: by))
let ( -% ) (ax, ay) (bx, by) = ((ax -: bx), (ay -: by))
let ( ~-% ) (ax, ay) = ((~-: ax), (~-: ay))

let ( *%+ ) (ax, ay) (bx, by) = (ax *: bx) +: (ay *: by)
let ( *%- ) (ax, ay) (bx, by) = (ax *: by) -: (ay *: bx)
let ( *%> ) (ax, ay) b = ((ax *: b), (ay *: b))
let ( *%>> ) (ax, ay) b = ((ax *:> b), (ay *:> b))
let ( /%> ) a b = a *%> (~/: b)
let ( /%>> ) a b = a *%>> (~/. b)

let ( ~*% ) (ax, ay) = (~*: ax) +: (~*: ay)
let ( ~*%! ) a = sqrt (~*% a)

(*****)

let emu = 400456.8e9
let mmu = 4903.593516e9

let grav mu s =
  let r2 = ~*% s in
  let ga = mu /:< r2
  and r = sqrt r2 in
  ~-% ga *%< (s /%> r)

let tstep (s0, v0) =
  let ga0 = grav emu s0 in
  let s1 = s0 +% v0 +% (ga0 /%>> 2.) in
  let ga1 = grav emu s1 in
  let v1 = v0 +% ((ga0 +% ga1) /%>> 2.) in
  (s1, v1)

let gravm sm s =
  (grav emu s) +% (grav mmu (s -% sm))

let tstepm sm0 sm1 (s0, v0) = 
  let ga0 = gravm sm0 s0 in
  let s1 = s0 +% v0 +% (ga0 /%>> 2.) in
  let ga1 = gravm sm1 s1 in
  let v1 = v0 +% ((ga0 +% ga1) /%>> 2.) in
  (s1, v1)
