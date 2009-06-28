open Disas

(*
type prog = {
    insns: insn array; data: float array; ilim: int;
    refs: int list array; state: bool array; noop: bool array }

let prog insns data =
  let ilim = Array.length ilim in
  { insns = insn; data = data; ilim = ilim;
    refs = Array.create ilim []; state = Array.create false }

let refstate p =
  let phiu = ref [] (*XXX*) in
  for i = 0 to pred p.ilim do
    let uses = match p.insns.(i) with
      Noop -> [i]
    | Cmpz (_,r) -> phiu := [r]; [i]
    | Sqrt r -> [r]
    | Copy r -> [r]
    | Input _ -> []
    | Binop (_,r1,r2) -> [r1;r2]
    | Output (_,r) -> [r]
    | 
  done
*)

let toil ba =
  let lr = ref [] in
  Array.iteri (fun i b -> if b then lr := i::!lr) ba;
  List.rev !lr

let contam insns icont =
  let ilim = Array.length insns in
  let ocont = ref []      
  and dcont = Array.create ilim false
  and scont = ref false 
  and progp = ref true in
  let ds i b = if b then (dcont.(i) <- b; progp := b) in
  let os p b = if b then ocont := p::!ocont in
  while !progp do
    progp := false;
    for i = 0 to pred ilim do
      if not dcont.(i) then
	match insns.(i) with
	  Noop -> ()
	| Cmpz (_,r) -> scont := dcont.(r)
	| Sqrt r -> ds i dcont.(r)
	| Copy r -> ds i dcont.(r)
	| Input p -> ds i (List.memq p icont)
	| Binop (_,r1,r2) -> ds i (dcont.(r1) || dcont.(r2))
	| Output (p,r) -> os p dcont.(r)
	| Phi (r1,r2) -> ds i (!scont || dcont.(r1) || dcont.(r2))
    done
  done;
  (!ocont, toil dcont)

let states insns =
  let ilim = Array.length insns in
  let states = Array.create ilim false 
  and used = Array.create ilim false in
  for i = 0 to pred ilim do
    begin match insns.(i) with
      Noop -> used.(i) <- true
    | Cmpz (_,r) -> used.(i) <- true; used.(r) <- true
    | Sqrt r -> used.(r) <- true
    | Copy r -> used.(r) <- true
    | Input _ -> used.(i) <- true
    | Binop (_,r1,r2) -> used.(r1) <- true; used.(r2) <- true
    | Output (_,_) -> used.(i) <- true
    | Phi (r1,r2) -> used.(r1) <- true; used.(r2) <- true
    end;
    if used.(i) then states.(i) <- true
  done;
  states

(* double svN for N in state;
   ...
   double vN = exprN for all N;
   double svN = vN for N in state;   
*)

let to_c imap omap insns data =
  let ilim = Array.length insns 
  and bst = Buffer.create 1024
  and sta = states insns in
  for i = 0 to pred ilim do
      if sta.(i) then begin
	Printf.bprintf bst "double _sv%d = %.18g;\n" i data.(i);
      end
  done;
  let bac = Buffer.create 2048 in
  Buffer.add_string bac "{\n";
  let lastcmp = ref "0" (* XXX *) in
  for i = 0 to pred ilim do
    let vref n =
      (if sta.(n) && n >= i then "_sv" else "_v")^(string_of_int n) in
    Printf.bprintf bac "\tconst double _v%d = %s;\n" i
      begin match insns.(i) with
	Noop -> vref i
      | Cmpz (op,r) ->
	  lastcmp := Printf.sprintf "%s %s 0" (vref r)
	      (match op with
		LT -> "<" | LE -> "<=" | EQ -> "==" | GE -> ">=" | GT -> ">");
	  vref i
      | Sqrt r -> "sqrt("^(vref r)^")"
      | Copy r -> vref r
      | Input p -> imap p
      | Binop (op,r1,r2) -> 
	  Printf.sprintf "(%s %s %s)" (vref r1)
	    (match op with Add -> "+" | Sub -> "-" | Mult -> "*" | Div -> "/")
	    (vref r2)
      | Output (p,r) ->
	  Printf.sprintf "((%s = %s), %s)" (omap p) (vref r) (vref i)
      | Phi (r1,r2) -> 
	  Printf.sprintf "(%s ? %s : %s)" !lastcmp (vref r1) (vref r2)
      end
  done;
  for i = 0 to pred ilim do
    if sta.(i) then 
      Printf.bprintf bac "\t_sv%d = _v%d;\n" i i
  done;
  Buffer.add_string bac "}\n";
  (Buffer.contents bst, Buffer.contents bac)

let stoc = to_c (fun p -> "in"^(string_of_int p)) (fun p -> "out"^(string_of_int p))
