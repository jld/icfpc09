#include "orbio.h"
#include <stdlib.h>
#include <string.h>

typedef struct twoframe
{
	double d0;
	uint32_t i0;
	uint32_t i1;
	double d1;
} tf_t;

int orb_read_prog(FILE *fp, is_t insns, ds_t data)
{
	tf_t ibuf[SSIZE / 2];
	int ilim, i;
	
	memset(ibuf, 0, sizeof(ibuf));
	ilim = fread(ibuf, 12, SSIZE, fp);
	if (ferror(fp)) {
		perror("orb_read_prog");
		exit(1);
	}
	
	for (i = 0; i < (SSIZE / 2); ++i) {
		insns[2 * i] = ibuf[i].i0;
		insns[2 * i + 1] = ibuf[i].i1;
		data[2 * i] = ibuf[i].d0;
		data[2 * i + 1] = ibuf[i].d1;
	}
	return ilim;
}

void orb_write_prog(FILE *fp, is_t insns, ds_t data, int ilim)
{
	tf_t obuf[SSIZE / 2];
	int i, olim;

	for (i = 0; i < ilim; ++i) {
		if (i % 2 == 0) {
			obuf[i / 2].i0 = insns[i];
			obuf[i / 2].d0 = data[i];
		} else {
			obuf[i / 2].i1 = insns[i];
			obuf[i / 2].d1 = data[i];
		}
	}
	olim = fwrite(obuf, 12, ilim, fp);
	if (olim != ilim)
		perror("orb_write_prog");
}

