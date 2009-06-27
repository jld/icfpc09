#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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

static void orb_run_out(void *, int, double);

struct orb_run_env
{
	dss_t output;
	int time, humanp;
};

void
orb_run(FILE *pfi, FILE *tfi, int humanp)
{
	iss_t insns;
	dss_t data, input;
	struct orb_run_env oe;
	itrace_t it;
	struct trframe *tf;
	int ilim, stat, t;

	memset(oe.output, 0, sizeof(oe.output));
	oe.humanp = humanp;
	
	ilim = orb_read_prog(pfi, insns, data);
	it = orb_read_trace(tfi);
	tf = it->frames;

	stat = 0;
	for (t = 0; tf; ++t) {
		tf = orb_apply_trace(tf, t, input);
		oe.time = t;
		stat = orb_step(insns, ilim, data, input, stat,
		    orb_run_out, &oe);
	}
	orb_free_trace(it);
}

static void
orb_run_out(void *ve, int addr, double val)
{
	struct orb_run_env *pe = ve;

	if (val != pe->output[addr]) {
		printf(pe->humanp ? "%7ds port[0x%04x] = %.17g\n"
		    : "%d %d %.17g\n", pe->time, addr, val);
		pe->output[addr] = val;
	}
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

#if 0
void
orb_simplesim(const char *prog, ds_t input, int nstep)
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
#endif
