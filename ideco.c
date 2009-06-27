#include <stdio.h>
#include "orbio.h"

int main(int argc, char **argv)
{
	FILE *fi;
	
	fi = (argc > 1)
	    ? fopen(argv[1], "r")
	    : stdin;
	orb_write_trace_text(stdout, orb_read_trace(fi));
	return 0;
}
