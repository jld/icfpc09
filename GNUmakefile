OCAMLC=ocamlc
OCAMLOPT=ocamlopt
CDEFS=
COPT=-O3 -fstrict-aliasing
CREQ=-std=gnu99 -fPIC
CWARN=-Wall -W -Wstrict-prototypes -Wmissing-prototypes
CINC=

CDBG=
CFLAGS=$(CREQ) $(COPT) $(CWARN) $(CDBG) $(CDEFS) $(CINC) $(XCF)

PRODUCTS=sim disas icomp ideco orbit.cma ncmplr.cma scattertrace.cma
OO=orbit.o orbio.o

all: $(PRODUCTS)

icomp: icomp.o $(OO)
	$(CC) $(CFLAGS) $(LFLAGS) $+ -o $@ -lm

ideco: ideco.o $(OO)
	$(CC) $(CFLAGS) $(LFLAGS) $+ -o $@ -lm

disas: disas.o $(OO)
	$(CC) $(CFLAGS) $(LFLAGS) $+ -o $@ -lm

test_rdwr: test_rdwr.o $(OO)
	$(CC) $(CFLAGS) $(LFLAGS) $+ -o $@ -lm

sim: sim.o orbrun.o $(OO)
	$(CC) $(CFLAGS) $(LFLAGS) $+ -o $@ -lm

orbit.cma: orbit_caml.o orbit.cmo orbutil.cmo $(OO)
	ocamlmklib -o orbit $+

ncmplr.cma: disas.cmo ncmplr.cmo
	ocamlc -a -o ncmplr.cma $+

gridtrace.cma: gridtrace.o gridtrace.cmo
	ocamlmklib -o gridtrace $+

scattertrace.cma: scattertrace.o scattertrace.cmo
	ocamlmklib -o scattertrace $+

II=gridtrace_decl.i gridtrace_stmt.i st_preload_decl.i st_preload_stmt.i scattertrace_decl.i scattertrace_stmt.i
$(II): orbit.cma ncmplr.cma stuff.ml
	ocaml bigarray.cma $+

%.cmi: %.mli
	$(OCAMLC) -c $<

%.cmx %.cmi: %.ml
	$(OCAMLOPT) -c $<

%.cmo %.cmi: %.ml
	$(OCAMLC) -c $<

DERIVED=*.o *.cm[oixa] *.cmxa *.a *.so *.i
XPRODUCTS=test_rdwr

clean:
	-rm -f $(DERIVED) $(PRODUCTS) $(XPRODUCTS)

.depend_c: $(wildcard *.c *.h)
	gcc -MM $(CDEFS) $(CINC) $(wildcard *.c) > $@
-include .depend_c

.depend_ml: $(wildcard *.ml *.mli)
	ocamldep $+ > $@
-include .depend_ml
