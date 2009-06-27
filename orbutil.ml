open Orbit

let earthbase = 2
let mu = 4004568.0e8
let moonrad = 1738000.0

let grav x y =
  let r2 = (x *. x) +. (y *. y) in
  let ga = mu /. r2
  and r = sqrt r2 in
  let gx = -. ga *. (x /. r)
  and gy = -. ga *. (y /. r) in
  (gx, gy)

let vextr x0 y0 x1 y1 =
  let (gx, gy) = grav x0 y0 in
  let vx = x1 -. x0 -. (gx /. 2.)
  and vy = y1 -. y0 -. (gy /. 2.)
  in (vx, vy)

let tstep ((sx0, sy0), (vx0, vy0)) =
  let (gx0, gy0) = grav sx0 sy0 in
  let sx1 = sx0 +. vx0 +. (gx0 /. 2.)
  and sy1 = sy0 +. vy0 +. (gy0 /. 2.) in
  let (gx1, gy1) = grav sx1 sy1 in
  let vx1 = vx0 +. ((gx0 +. gx1) /. 2.)
  and vy1 = vy0 +. ((gy0 +. gy1) /. 2.)
  in ((sx1, sy1), (vx1, vy1))


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
