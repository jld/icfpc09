#include <stdio.h>
#include <getopt.h>
#include "orbrun.h"

int main(int argc, char **argv)
{
	FILE *pfi, *tfi;
	int opt, humanp;

	humanp = 0;
	while ((opt = getopt(argc, argv, "h")) != -1) {
		switch (opt) {
		case 'h':
			humanp = 1;
			break;
		}
	}

	argv += optind;
	argc -= optind;

	pfi = fopen(argv[0], "r");
	tfi = (argc > 1)
	    ? fopen(argv[1], "r")
	    : stdin;
	orb_run(pfi, tfi, 0);
}
