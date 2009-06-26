#include <stdio.h>
#include "orbio.h"

int main(void)
{
	iss_t insns;
	dss_t data;
	int ilim;

	ilim = orb_read_prog(stdin, insns, data);
	orb_write_prog(stdout, insns, data, ilim);
	return 0;
}
