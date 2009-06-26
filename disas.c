#include <stdio.h>
#include "orbio.h"

int main(void)
{
	iss_t insns;
	dss_t data;
	int ilim, i;

	ilim = orb_read_prog(stdin, insns, data);
	for (i = 0; i < ilim; ++i)
		orb_print_insn(i, data[i], insns[i]);
	return 0;
}
