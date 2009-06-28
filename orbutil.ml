open Orbit

let earthbase = 2
let emu = 400456.8e9
let mmu = 0.0 (* 4903.593516e9 *)
let moonrad = 1738000.0

let grav mu x y =
  let r2 = (x *. x) +. (y *. y) in
  let ga = mu /. r2
  and r = sqrt r2 in
  let gx = -. ga *. (x /. r)
  and gy = -. ga *. (y /. r) in
  (gx, gy)

let vextr x0 y0 x1 y1 =
  let (gx, gy) = grav emu x0 y0 in
  let vx = x1 -. x0 -. (gx /. 2.)
  and vy = y1 -. y0 -. (gy /. 2.)
  in (vx, vy)

let tstep (sx0, sy0) (vx0, vy0) =
  let (gx0, gy0) = grav emu sx0 sy0 in
  let sx1 = sx0 +. vx0 +. (gx0 /. 2.)
  and sy1 = sy0 +. vy0 +. (gy0 /. 2.) in
  let (gx1, gy1) = grav emu sx1 sy1 in
  let vx1 = vx0 +. ((gx0 +. gx1) /. 2.)
  and vy1 = vy0 +. ((gy0 +. gy1) /. 2.)
  in ((sx1, sy1), (vx1, vy1))

let ttstep (s,v) = tstep s v

(*****)

let gravm (mx,my) x y =
  let (gxe,gye) = grav emu x y
  and (gxm,gym) = grav mmu (x -. mx) (y -. my) in
  ((gxe +. gxm), (gye +. gym))

let vextrm m x0 y0 x1 y1 =
  let (gx, gy) = gravm m x0 y0 in
  let vx = x1 -. x0 -. (gx /. 2.)
  and vy = y1 -. y0 -. (gy /. 2.)
  in (vx, vy)

let tstepm sm0 sm1 (sx0, sy0) (vx0, vy0) =
  let (gx0, gy0) = gravm sm0 sx0 sy0 in
  let sx1 = sx0 +. vx0 +. (gx0 /. 2.)
  and sy1 = sy0 +. vy0 +. (gy0 /. 2.) in
  let (gx1, gy1) = gravm sm1 sx1 sy1 in
  let vx1 = vx0 +. ((gx0 +. gx1) /. 2.)
  and vy1 = vy0 +. ((gy0 +. gy1) /. 2.)
  in ((sx1, sy1), (vx1, vy1))  

(*****)

let beginning sim scene =
  let (insns,data) = read_prog sim 
  and input = in_scene scene
  and rstat = ref false in
  let a0 = orb_step_array insns data input rstat in
  let a1 = orb_step_array insns data input rstat in
  (a0, a1)

let here arr = (-.arr.(earthbase), -.arr.(succ earthbase))
let there arr base = (arr.(base) -. arr.(earthbase),
		      arr.(succ base) -. arr.(succ earthbase))

let initcond (a0,a1) base =
  let (sx0, sy0) = if base < 0 then here a0 else there a0 base
  and (sx1, sy1) = if base < 0 then here a1 else there a1 base in
  ((sx0, sy0), vextr sx0 sy0 sx1 sy1)

let initcondm (a0,a1) base =
  let (sx0, sy0) = if base < 0 then here a0 else there a0 base
  and (sx1, sy1) = if base < 0 then here a1 else there a1 base
  and moon = there a0 100 in
  ((sx0, sy0), vextrm moon sx0 sy0 sx1 sy1)

let sram ((sx,sy),(vx,vy)) =
  sx *. vy -. sy *. vx

let mag (x,y) =
  sqrt (x *. x +. y *. y)

let norm (x,y) =
  let r = sqrt (x *. x +. y *. y) in
  ((x /. r), (y /. r))

let ecc ((s,(vx,vy)) as sv)  =
  let h = sram sv
  and (nx,ny) = norm s in
  ((vy *. h /. emu -. nx),
   (-. vx *. h /. emu -. ny))

let ainv (s,(vx,vy)) = 
  (2. /. mag s) -. ((vx *. vx +. vy *. vy) /. emu)

let pi = atan2 0. (-1.)

let period x = sqrt (4. *. pi *. pi *. (ainv x) ** -3. /. emu);;

