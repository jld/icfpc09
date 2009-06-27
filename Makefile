### AUTOGENERATED; DO NOT EDIT ###
# -*- Makefile -*- 
.POSIX:
CDEFS=
COPT=-std=gnu99 -O3 -g -fstrict-aliasing
CWARN=-Wall -W -Wstrict-prototypes -Wmissing-prototypes
CINC=

CDBG=
CFLAGS=$(COPT) $(CWARN) $(CDBG) $(CDEFS) $(CINC) $(XCF)

OO=orbit.o orbio.o
OBJS=test_rdwr.o ssim.o $(OO)

all: ssim disas icomp ideco

icomp: icomp.o $(OO)
	$(CC) $(CFLAGS) $(LFLAGS) $(OO) icomp.o -o icomp -lm

ideco: ideco.o $(OO)
	$(CC) $(CFLAGS) $(LFLAGS) $(OO) ideco.o -o ideco -lm

disas: disas.o $(OO)
	$(CC) $(CFLAGS) $(LFLAGS) $(OO) disas.o -o disas -lm

test_rdwr: test_rdwr.o $(OO)
	$(CC) $(CFLAGS) $(LFLAGS) $(OO) test_rdwr.o -o test_rdwr -lm

ssim: ssim.o $(OO)
	$(CC) $(CFLAGS) $(LFLAGS) $(OO) ssim.o -o ssim -lm

clean:
	-rm -f $(OBJS) ssim test_rdwr disas icomp ideco

CS=$(OBJS:.o=.c)
Makefile: Makefile.tmpl $(CS)
	@echo '### AUTOGENERATED; DO NOT EDIT ###' > $@
	cat Makefile.tmpl >> $@
	$(MAKE) -f Makefile.tmpl _depend
_depend:
	@gcc -MM $(CDEFS) $(CINC) $(CS) >> Makefile
###END###
test_rdwr.o: test_rdwr.c orbio.h orbit.h
ssim.o: ssim.c orbit.h
orbit.o: orbit.c orbio.h orbit.h
orbio.o: orbio.c orbio.h orbit.h
