#include <stdint.h>

typedef double *restrict ds_t;
typedef uint32_t *restrict is_t;

#define SSIZE 16384
typedef double dss_t[SSIZE];
typedef uint32_t iss_t[SSIZE];

typedef struct itrace {
	uint32_t team, scenario;
	struct trframe *frames;
} *itrace_t;

struct trframe {
	uint32_t time, count;
	struct valmap *maps;
	struct trframe *cdr;
};

struct valmap {
	uint32_t addr;
	double value;
};

typedef void(*orbout_t)(void*, int, double);


void orb_free_trace(itrace_t);

/* insns n_insn data input status output/rc => status */
int orb_step(is_t, int, ds_t, ds_t, int, orbout_t, void*);

/* progfile tracefile humanp => | stdout */
void orb_run(FILE *, FILE *, int);

/* trf_iter time input => */
struct trframe *orb_apply_trace(struct trframe *, uint32_t, ds_t);
