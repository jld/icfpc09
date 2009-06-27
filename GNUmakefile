CDEFS=
COPT=-std=gnu99 -O3 -g -fstrict-aliasing
CWARN=-Wall -W -Wstrict-prototypes -Wmissing-prototypes
CINC=

CDBG=
CFLAGS=$(COPT) $(CWARN) $(CDBG) $(CDEFS) $(CINC) $(XCF)

PRODUCTS=sim disas icomp ideco
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

DERIVED=*.o
XPRODUCTS=test_rdwr

clean:
	-rm -f $(DERIVED) $(PRODUCTS) $(XPRODUCTS)

.depend: $(wildcard *.c *.h)
	gcc -MM $(CDEFS) $(CINC) $(wildcard *.c) > .depend
-include .depend
