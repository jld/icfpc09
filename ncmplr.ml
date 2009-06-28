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
  let ocont = Array.create 16384 false
  and dcont = Array.create ilim false
  and scont = ref false 
  and progp = ref true in
  let ds i b = if b then (dcont.(i) <- b; progp := b) in
  let os p b = if b then ocont.(p) <- b in
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
  (toil ocont, dcont)

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
    | Output (_,r) -> used.(i) <- true; used.(r) <- true
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

let to_c ?(vsize = "VSIZE") ?(ivec = []) ?(ovec = [])
    ?(imap = (fun p -> "in"^(string_of_int p)))
    ?(omap = (fun p -> Some ("out"^(string_of_int p))))
    insns data =
  let (ovec',dvec) = contam insns ivec in
  (* If the outputs that have to be vectorized aren't expected to be...*)
  List.iter (fun p -> if not (List.memq p ovec) && (omap p) != None then
    failwith (Printf.sprintf
		"ncmplr: output %d must be vectorized or ignored" p)) ovec';
  let ilim = Array.length insns 
  and bst = Buffer.create 1024
  and sta = states insns
  and forloop b s = Printf.bprintf b "for(_i = 0; _i < %s; ++_i) {\n\t%s;\n}\n"
      vsize s in

  if ivec != [] && ovec != [] then
    Buffer.add_string bst "int _i;\n";
  for i = 0 to pred ilim do
    if sta.(i) then begin
      if dvec.(i) then
	if data.(i) = 0.0 then
	  Printf.bprintf bst "double _sv%d[%s] = { 0 };\n" i vsize
	else begin
	  Printf.bprintf bst "double _sv%d[%s];\n" i vsize;
	  forloop bst (Printf.sprintf "_sv%d[_i] = %.18g" i data.(i))
	end
      else
	Printf.bprintf bst "double _sv%d = %.18g;\n" i data.(i)
    end
  done;

  let bac = Buffer.create 2048 in
  Buffer.add_string bac "{\n";
  let lastcmp = ref (fun () -> "0" (* XXX *)) in
  for i = 0 to pred ilim do
    let vecp = ref false in
    let deco b v =
      if b then (vecp := true; v^"[_i]") else v in
    let vref n =
      deco dvec.(n)
	((if sta.(n) && n >= i then "_sv" else "_v")^(string_of_int n))
    and iref p =
      deco (List.memq p ivec) (imap p)
    and oref p =
      match (omap p) with
	Some olv -> Some (deco (List.memq p ovec) olv)
      | None -> None
    in

    let init = begin match insns.(i) with
      Noop -> vref i
    | Cmpz (op,r) ->
	lastcmp := (fun () -> Printf.sprintf "%s %s 0" (vref r)
	    (match op with
	      LT -> "<" | LE -> "<=" | EQ -> "==" | GE -> ">=" | GT -> ">"));
	vref i
    | Sqrt r -> "sqrt("^(vref r)^")"
    | Copy r -> vref r
    | Input p -> iref p
    | Binop (op,r1,r2) -> 
	Printf.sprintf "%s %s %s" (vref r1)
	  (match op with Add -> "+" | Sub -> "-" | Mult -> "*" | Div -> "/")
	  (vref r2)
    | Output (p,r) ->
	begin match oref p with
	  Some olv ->
	    Printf.sprintf "((%s = %s), %s)" olv (vref r) (vref i)
	| None -> vref i
	end
    | Phi (r1,r2) -> 
	Printf.sprintf "%s ? %s : %s" (!lastcmp ()) (vref r1) (vref r2)
    end in
    if !vecp then
      if dvec.(i) then begin
	Printf.bprintf bac "\tdouble _v%d[%s];\n" i vsize;
	forloop bac (Printf.sprintf "_v%d[_i] = %s" i init)
      end else begin
	Printf.bprintf bac "\tdouble _v%d;\n" i;
	forloop bac (Printf.sprintf "_v%d = %s" i init)
      end
    else
      Printf.bprintf bac "\tconst double _v%d = %s;\n" i init
  done;
  for i = 0 to pred ilim do
    if sta.(i) then 
      if dvec.(i) then
	forloop bac (Printf.sprintf "_sv%d[_i] = _v%d[_i]" i i)
      else
	Printf.bprintf bac "\t_sv%d = _v%d;\n" i i
  done;
  Buffer.add_string bac "}\n";
  (Buffer.contents bst, Buffer.contents bac)


let ionly l p = if List.memq p l then "in"^(string_of_int p) else "0"
let oonly l p = if List.memq p l then Some ("out"^(string_of_int p)) else None

let stoc = to_c
    ~imap:(fun p -> "in"^(string_of_int p))
    ~omap:(fun p -> Some ("out"^(string_of_int p)))

let ctofi base (decls,stmt) =
  let fd = open_out (base^"_decl.i") in
  output_string fd decls;
  close_out fd;
  let fs = open_out (base^"_stmt.i") in
  output_string fs stmt;
  close_out fs
