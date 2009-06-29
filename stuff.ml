let _ =
  let (d,i) = Disas.disas_prog (Orbit.read_prog "specs/bin4.obf") in
  let c = Ncmplr.to_c ~ivec:[2;3] ~ovec:(fun _ -> true)
      ~imap:(function 2 -> "in2" | 3 -> "in3" | 16000 -> "SCENE")
      ~omap:(function
	  0 -> Some "score" |
	  2 -> Some "relx_earth" | 3 -> Some "rely_earth"
	| p when 7 <= p && p < 40 ->
	    Some (Printf.sprintf "%s[%d]"
		    (match (p - 7) mod 3 with
		      0 -> "relx_sat"
		    | 1 -> "rely_sat"
		    | 2 -> "sathit")
		    ((p - 7) / 3))
	| _ -> None)
      d i in
  Ncmplr.ctofi "gridtrace" c
