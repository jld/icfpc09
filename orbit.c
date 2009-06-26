#include <stdio.h>
#include <math.h>
#include "orbit.h"

int orb_step(is_t insns, ds_t data, ds_t input, ds_t output, int stat, int ilim)
{
	int i;

	for (i = 0; i < ilim; ++i) {
		uint32_t insn = insns[i];
		int imm, r1, r2, op;

		op = insn >> 28;
		r1 = (insn >> 14) & 4095;
		r2 = insn & 4095;
		switch (op) {
		case 0:
			op = (insn >> 24) & 15;
			r1 = insn & 4095;
			switch (op) {
			case 0: /* Noop */
				break;
			case 1: /* Cmpz */
				imm = (insn >> 14) & 1023;
				switch (imm) {
#define CMPZ(op,rel) case op: stat = data[r1] rel 0.0; break;
					CMPZ(0, <);
					CMPZ(1, <=);
					CMPZ(2, ==);
					CMPZ(3, >=);
					CMPZ(4, >);
#undef CMPZ
				default:
					fprintf(stderr, "Bad IMM at %d: %d",
					    i, imm);
				}
				break;
			case 2: /* Sqrt */
				data[i] = sqrt(fabs(data[r1]));
				break;
			case 3: /* Copy */
				data[i] = data[r1];
				break;
			case 4: /* Input */
				data[i] = input[r1];
				break;
			default:
				fprintf(stderr, "Bad S-Type OP at %d: %d",
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
			fprintf(stderr, "Bad D-Type OP at %d: %d", i, op);
		}
	}
	return stat;
}


/*
void orb_simplesim(const char *prog, const char *trace)
{
	FILE *pf, *tf;

	
}
*/
