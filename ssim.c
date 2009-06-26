#include <stdlib.h>
#include <string.h>
#include "orbit.h"

int main(int argc, char **argv)
{
	dss_t input;

	memset(input, 0, sizeof(input));
	input[0x3E80] = atof(argv[3]);
//	input[2] = 10;
	orb_simplesim(argv[1], input, atoi(argv[2]));
	return 0;
}
