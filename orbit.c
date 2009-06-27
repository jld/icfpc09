#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "orbio.h"

int
orb_step(is_t insns, int ilim, ds_t data, ds_t input, int stat,
    orbout_t out, void *orc)
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
			out(orc, r1, data[r2]);
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


void
orb_free_trace(itrace_t it)
{
	struct trframe *i, *in;

	for (i = it->frames; i; i = in) {
		in = i->cdr;
		free(i->maps);
		free(i);
	}
	free(it);
}

struct trframe *
orb_apply_trace(struct trframe *tf, uint32_t t, ds_t input)
{
	uint32_t i;

	assert(t <= tf->time);
	if (t == tf->time) {
		for (i = 0; i < tf->count; ++i)
			input[tf->maps[i].addr] = tf->maps[i].value;
		tf = tf->cdr;
	}
	return tf;
}
