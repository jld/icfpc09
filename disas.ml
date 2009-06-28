type cmp = LT | LE | EQ | GE | GT
type binop = Add | Sub | Mult | Div

type insn = 
    Noop  
  | Cmpz of cmp * int
  | Sqrt of int
  | Copy of int
  | Input of int
  | Binop of binop * int * int
  | Output of int * int
  | Phi of int * int

let noopp = function
    Noop -> true
  | Cmpz (_,_) -> true
  | Output (_,_) -> true
  | _ -> false

let bitfield b l i =
  let i' = Int32.shift_right_logical i b 
  and m = Int32.pred (Int32.shift_left Int32.one l) in
  Int32.to_int (Int32.logand i' m)

let disas i =
  let d_op = bitfield 28 4 i
  and d_r1 = bitfield 14 14 i
  and d_r2 = bitfield 0 14 i
  and s_op = bitfield 24 4 i
  and s_imm = bitfield 21 3 i
  and s_r1 = bitfield 0 14 i in
  match d_op with
    0 -> begin match s_op with
      0 -> Noop
    | 1 -> Cmpz ((match s_imm with
	0 -> LT | 1 -> LE | 2 -> EQ | 3 -> GE | 4 -> GT), s_r1)
    | 2 -> Sqrt s_r1
    | 3 -> Copy s_r1
    | 4 -> Input s_r1
    end
  | 1 -> Binop (Add,d_r1,d_r2)
  | 2 -> Binop (Sub,d_r1,d_r2)
  | 3 -> Binop (Mult,d_r1,d_r2)
  | 4 -> Binop (Div,d_r1,d_r2)
  | 5 -> Output (d_r1,d_r2)
  | 6 -> Phi (d_r1,d_r2)
  
let disas_insns ia =
  Array.init (Orbit.A.dim ia) (fun i -> disas (Orbit.A.get ia i))

let disas_prog (i,d) =
  (disas_insns i),(Array.init (Orbit.A.dim d) (Orbit.A.get d))
