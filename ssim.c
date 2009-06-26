#include <stdlib.h>
#include <string.h>
#include "orbit.h"

int main(int argc, char **argv)
{
	dss_t input0, inputn;

	memset(input0, 0, sizeof(input0));
	memset(inputn, 0, sizeof(inputn));
	input0[0x3E80] = atof(argv[3]);
//	input[2] = 10;
	orb_simplesim(argv[1], input0, inputn, atoi(argv[2]));
	return 0;
}
