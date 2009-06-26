#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "orbio.h"

int orb_step(is_t insns, ds_t data, ds_t input, ds_t output, int stat, int ilim)
{
	int i;

	for (i = 0; i < ilim; ++i) {
		uint32_t insn = insns[i];
		int imm, r1, r2, op;

		// fprintf(stderr, "insns[%d] = 0x%08x\n", i, insn);
		op = insn >> 28;
		r1 = (insn >> 14) & 16383;
		r2 = insn & 16383;
		switch (op) {
		case 0:
			op = (insn >> 24) & 15;
			r1 = insn & 16383;
			switch (op) {
			case 0: /* Noop */
				break;
			case 1: /* Cmpz */
				imm = (insn >> 21) & 7;
				switch (imm) {
#define CMPZ(cop,rel) case cop: stat = (data[r1] rel 0.0); break;
					CMPZ(0, <);
					CMPZ(1, <=);
					CMPZ(2, ==);
					CMPZ(3, >=);
					CMPZ(4, >);
#undef CMPZ
				default:
					fprintf(stderr, "Bad IMM at %d: %d\n",
					    i, imm);
				}
				break;
			case 2: /* Sqrt */
				data[i] = sqrt(data[r1]);
				break;
			case 3: /* Copy */
				data[i] = data[r1];
				break;
			case 4: /* Input */
				data[i] = input[r1];
				break;
			default:
				fprintf(stderr, "Bad S-Type OP at %d: %d\n",
				    i, op);
			}
			break;
		case 1: /* Add */
			data[i] = data[r1] + data[r2];
			break;
		case 2: /* Sub */
			data[i] = data[r1] - data[r2];
			break;
		case 3: /* Mult */
			data[i] = data[r1] * data[r2];
			break;
		case 4: /* Div */
			if (data[r2] == 0.0)
				data[i] = 0.0;
			else
				data[i] = data[r1] / data[r2];
			break;
		case 5: /* Output */
			output[r1] = data[r2];
			break;
		case 6: /* Phi */
			data[i] = data[stat ? r1 : r2];
			break;
		default:
			fprintf(stderr, "Bad D-Type OP at %d: %d\n", i, op);
		}
	}
	return stat;
}


void orb_simplesim(const char *prog, ds_t input0, ds_t inputn, int nstep)
{
	FILE *pf;
	iss_t insns;
	dss_t data, output, oldout;
//	dss_t olddat;
	int t, i, ilim, stat;

	memset(output, 0, sizeof(output));
	memset(oldout, 0, sizeof(oldout));

	pf = fopen(prog, "r");
	if (!pf) {
		perror(prog);
		exit(1);
	}
	ilim = orb_read_prog(pf, insns, data);
	fclose(pf);
	
	stat = 0;
	for (t = 0; t < nstep; ++t) {
//		memcpy(olddat, data, sizeof(olddat));
		stat = orb_step(insns, data, input0, output, stat, ilim);
		for (i = 0; i < SSIZE; ++i) { /* XXX inefficient but general */
			if (output[i] != oldout[i])
				printf("%7ds port[0x%04x] = %.11g\n",
				    t, i, output[i]);
//			if (data[i] != olddat[i])
//				printf("%7ds data[0x%04x] = %.11g\n",
//				    t, i, data[i]);
			oldout[i] = output[i];
		}
	}
}
