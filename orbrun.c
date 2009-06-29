#include "orbrun.h"
#include "orbio.h"
#include <string.h>

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
		printf(pe->humanp ? "%7ds port[0x%04x] = %.18g\n"
		    : "%d %d %.18g\n", pe->time, addr, val);
		pe->output[addr] = val;
	}
}
